package HADaemon::Control;

use v5.14;
use strict;
use warnings;

use Fcntl ();
use POSIX ();
use Time::HiRes;
use Cwd qw(abs_path);
use File::Path qw(make_path);
use File::Basename qw(dirname);
use Scalar::Util qw(weaken);
use IPC::ConcurrencyLimit::WithStandby;

our $VERSION = '1.005';

# Accessor building
my @accessors = qw(
    pid_dir quiet color_map name stop_file_kill_timeout signal_kill_timeout kill_timeout
    stop_signals program program_args stdout_file stderr_file umask directory ipc_cl_options
    main_stop_file standby_stop_file uid gid log_file process_name_change close_fds_on_start
    path init_config init_code lsb_start lsb_stop lsb_sdesc lsb_desc reset_close_on_exec_main_lock_fd
    main_upgrade_file upgrade_timeout
);

foreach my $method (@accessors) {
    no strict 'refs';
    *$method = sub {
        my $self = shift;
        $self->{$method} = shift if @_;
        return $self->{$method};
    }
}

sub new {
    my ($class, @in) = @_;
    my $args = ref $in[0] eq 'HASH' ? $in[0] : { @in };

    my $self = bless {
        color_map     => { red => 31, green => 32 },
        quiet         => 0,
    }, $class;

    foreach my $accessor (@accessors) {
        if (exists $args->{$accessor}) {
            $self->{$accessor} = delete $args->{$accessor};
        }
    }

    $self->user(delete $args->{user}) if exists $args->{user};
    $self->group(delete $args->{group}) if exists $args->{group};

    die "Unknown arguments to the constructor: " . join(' ' , keys %$args)
        if keys %$args;

    return $self;
}

sub run {
    my ($self) = @_;
    return $self->run_command(@ARGV);
}

sub run_command {
    my ($self, $arg) = @_;

    # Error Checking.
    $self->program && ref $self->program eq 'CODE'
        or die "Error: program must be defined and must be coderef\n";
    $self->name
        or die "Error: name must be defined\n";
    $self->pid_dir
        or die "Error: pid_dir must be defined\n";
    $self->log_file
        or die "Error: log_file must be defined\n";

    defined($self->kill_timeout)
        or $self->kill_timeout(1);

    defined($self->close_fds_on_start)
        or $self->close_fds_on_start(1);

    $self->standby_stop_file
        or $self->standby_stop_file($self->pid_dir . '/standby-stop-file');

    # ipc_cl_options default settings
    $self->{ipc_cl_options} //= {};
    $self->{ipc_cl_options}->{type}              //= 'Flock';
    $self->{ipc_cl_options}->{max_procs}         //= 1;
    $self->{ipc_cl_options}->{standby_max_procs} //= 1;
    $self->{ipc_cl_options}->{interval}          //= 1;
    $self->{ipc_cl_options}->{retries}           //= sub { 1 };
    $self->{ipc_cl_options}->{path}              //= $self->pid_dir . '/lock/';
    $self->{ipc_cl_options}->{standby_path}      //= $self->pid_dir . '/lock-standby/';

    # ipc_cl_options error checking
    $self->{ipc_cl_options}->{type} ne 'Flock'
        and die "can work only with Flock backend\n";
    $self->{ipc_cl_options}->{max_procs} < 1
        and die "ipc_cl_options: 'max_procs' should be at least 1\n";
    $self->{process_name_change}
        and $self->{ipc_cl_options}->{process_name_change} = 1;

    if ($self->uid) {
        my @uiddata = getpwuid($self->uid);
        @uiddata or die "failed to get info about " . $self->uid . "\n";

        if (!$self->gid) {
            $self->gid($uiddata[3]);
            $self->trace("Implicit GID => " . $uiddata[3]);
        }

        $self->user
            or $self->{user} = $uiddata[0];

        $self->{user_home_dir} = $uiddata[7];
    }

    my $called_with = $arg // '';
    $called_with =~ s/^[-]+//g;

    if (!$called_with) {
        return $self->do_help();
    }

    # $self->can() create new record in class hash
    # so $self->_all_actions includes it as well
    if (not grep { $_ eq $called_with  } $self->_all_actions) {
        warn "Error: unknown action $called_with\n";
        return $self->do_help();
    }

    my $action = "do_$called_with";
    return $self->$action() // 0;
}

#####################################
# commands
#####################################
sub do_start {
    my ($self) = @_;
    $self->info('do_start()');

    my $expected_main = $self->_expected_main_processes();
    my $expected_standby = $self->_expected_standby_processes();
    if (   $self->_main_running() == $expected_main
        && $self->_standby_running() == $expected_standby)
    {
        $self->pretty_print('starting main + standby processes', 'Already Running');
        $self->trace("do_start(): all processes are already running");
        return 0;
    }

    $self->_precreate_directories();
    $self->_unlink_file($self->standby_stop_file);

    if ($self->_fork_mains() && $self->_fork_standbys()) {
        $self->pretty_print('starting main + standby processes', 'OK');
        return 0;
    }

    $self->pretty_print('starting main + standby processes', 'Failed', 'red');
    $self->do_status();
    $self->detect_stolen_lock();
    $self->_print_check_log_file_for_details();

    return 1;
}

sub do_stop {
    my ($self) = @_;
    $self->info('do_stop()');

    if (!$self->_main_running() && !$self->_standby_running()) {
        $self->pretty_print('stopping main + standby processes', 'Not Running', 'red');
        $self->trace("do_stop(): all processes are not running");
        return 0;
    }

    $self->_precreate_directories();
    $self->_write_file($self->standby_stop_file);
    $self->_wait_standbys_to_complete();

    my %mains = map {
        $_ => $self->_pid_of_process_type($_)
    } $self->_expected_main_processes();

    my %running_pids = $self->_kill_pids(values %mains);

    foreach my $type (%mains) {
        my $pid = $mains{$type};
        if ($pid && !exists $running_pids{$pid}) {
            $self->_unlink_file($self->_build_pid_file($type));
        }
    }

    if ($self->_main_running() == 0 && $self->_standby_running() == 0) {
        $self->pretty_print('stopping main + standby processes', 'OK');
        return 0;
    }

    $self->pretty_print('stopping main + standby processes', 'Failed', 'red');
    $self->do_status();
    $self->_print_check_log_file_for_details();
    return 1;
}

sub do_restart {
    my ($self) = @_;
    $self->info('do_restart()');

    # shortcut
    if (!$self->_main_running() && !$self->_standby_running()) {
        return $self->do_start();
    }

    # another shortcut
    if ($self->{ipc_cl_options}->{standby_max_procs} <= 0) {
        return $self->do_hard_restart();
    }

    # stoping standby
    $self->_precreate_directories();
    $self->_write_file($self->standby_stop_file);

    if (not $self->_wait_standbys_to_complete()) {
        $self->pretty_print('stopping standby processes', 'Failed', 'red');
        $self->warn("all standby processes should be stopped at this moment. Can't move forward");
        $self->_print_check_log_file_for_details();
        return 1;
    }

    $self->pretty_print('stopping standby processes', 'OK');

    # starting standby
    $self->_unlink_file($self->standby_stop_file);

    if (!$self->_fork_standbys()) {
        $self->pretty_print('starting standby', 'Failed', 'red');
        $self->warn("all standby processes should be running at this moment. Can't move forward");
        $self->_print_check_log_file_for_details();
        return 1;
    }

    $self->pretty_print('starting standby processes', 'OK');

    my %mains;
    foreach my $type ($self->_expected_main_processes()) {
        if (my $pid = $self->_pid_of_process_type($type)) {
            $mains{$type} = $pid;
        } else {
            $self->trace("Main process $type is not running");
        }
    }

    # killing mains, stanbys should be promoted instantly
    my %running_pids = $self->_kill_pids(values %mains);

    foreach my $type (%mains) {
        my $pid = $mains{$type};
        if ($pid && exists $running_pids{$pid}) {
            # failed to restart process
            $self->pretty_print($type, 'Failed to restart', 'red');
        }
    }

    # starting mains
    if (!$self->_fork_mains() || !$self->_fork_standbys()) {
        $self->pretty_print('restarting main + standby processes', 'Failed', 'red');
        $self->warn("all main + standby processes should be running at this moment");

        $self->do_status();
        $self->detect_stolen_lock();
        $self->_print_check_log_file_for_details();
        return 1;
    }

    $self->pretty_print('restarting main processes', 'OK');
    return 0;
}

sub do_upgrade {
    my ($self) = @_;
    $self->info('do_upgrade()');
    $self->main_upgrade_file or $self->die("upgrade requires 'main_upgrade_file'");

    # shortcut
    if (!$self->_main_running() && !$self->_standby_running()) {
        return $self->do_start();
    }

    # stoping standby
    $self->_precreate_directories();
    $self->_write_file($self->standby_stop_file);

    if (not $self->_wait_standbys_to_complete()) {
        $self->pretty_print('stopping standby processes', 'Failed', 'red');
        $self->warn("all standby processes should be stopped at this moment. Can't move forward");
        $self->_print_check_log_file_for_details();
        return 1;
    }

    $self->pretty_print('stopping standby processes', 'OK');

    # starting standby
    $self->_unlink_file($self->standby_stop_file);

    if (!$self->_fork_standbys()) {
        $self->pretty_print('starting standby', 'Failed', 'red');
        $self->warn("all standby processes should be running at this moment. Can't move forward");
        $self->_print_check_log_file_for_details();
        return 1;
    }

    $self->pretty_print('starting standby processes', 'OK');

    my %mains;
    foreach my $type ($self->_expected_main_processes()) {
        if (my $pid = $self->_pid_of_process_type($type)) {
            $mains{$type} = $pid;
        } else {
            $self->trace("Main process $type is not running");
        }
    }

    # upgrading mains, stanbys should be promoted instantly
    my %failed_to_upgrade_pids = $self->_upgrade_pids(values %mains);
    if (!%failed_to_upgrade_pids) {
        $self->pretty_print('upgrading main processes', 'OK');
        return 0;
    }

    foreach my $type (%mains) {
        my $pid = $mains{$type};
        if ($pid && exists $failed_to_upgrade_pids{$pid}) {
            $self->pretty_print($type, 'Failed to upgrade', 'red');
        }
    }

    return 1;
}

sub do_hard_restart {
    my ($self) = @_;
    $self->info('do_hard_restart()');

    $self->do_stop();
    return $self->do_start();
}

sub do_status {
    my ($self) = @_;
    $self->info('do_status()');

    my $exit_code = 0;
    foreach my $type ($self->_expected_main_processes(), $self->_expected_standby_processes()) {
        if ($self->_pid_of_process_type($type)) {
            $self->pretty_print("$type status", 'Running');
        } else {
            $exit_code = 1;
            $self->pretty_print("$type status", 'Not Running', 'red');
        }
    }

    return $exit_code;
}

sub do_fork {
    my ($self) = @_;
    $self->info('do_fork()');

    return 1 if $self->_check_stop_file();

    $self->_precreate_directories();
    $self->_fork_mains();
    $self->_fork_standbys();

    return 0;
}

sub do_reload {
    my ($self) = @_;
    $self->info('do_reload()');

    foreach my $type ($self->_expected_main_processes()) {
        my $pid = $self->_pid_of_process_type($type);
        if ($pid) {
            $self->_kill_or_die('HUP', $pid);
            $self->pretty_print($type, 'Reloaded');
        } else {
            $self->pretty_print("$type status", 'Not Running', 'red');
        }
    }
}

sub do_get_init_file {
    my ($self) = @_;
    $self->info('do_get_init_file()');
    return $self->_dump_init_script();
}

sub do_foreground {
    my ($self) = @_;
    $self->quiet(1);
    return $self->_launch_program();
}

sub do_help {
    my ($self) = @_;
    my $allowed_actions = join('|', reverse sort $self->_all_actions());
    print "Usage: $0 [$allowed_actions]\n\n";
    return 0;
}

#####################################
# routines to work with processes
#####################################
sub _fork_mains {
    my ($self) = @_;
    my $expected_main = $self->_expected_main_processes();

    for (1..3) {
        my $to_start = $expected_main - $self->_main_running();
        $self->_fork() foreach (1 .. $to_start);

        my $end = Time::HiRes::time + $self->_standby_timeout;
        while (Time::HiRes::time < $end) {
            return 1 if $self->_main_running() == $expected_main;
            Time::HiRes::sleep(0.1);
        }
    }

    return 0;
}

sub _fork_standbys {
    my ($self) = @_;
    my $expected_standby = $self->_expected_standby_processes();

    for (1..3) {
        my $to_start = $expected_standby - $self->_standby_running();
        $self->_fork() foreach (1 .. $to_start);

        my $end = Time::HiRes::time + $self->_standby_timeout;
        while (Time::HiRes::time < $end) {
            return 1 if $self->_standby_running() == $expected_standby;
            Time::HiRes::sleep(0.1);
        }
    }

    return 0;
}

sub _main_running {
    my ($self) = @_;
    my @running = grep { $self->_pid_of_process_type($_) } $self->_expected_main_processes();
    return wantarray ? @running : scalar @running;
}

sub _standby_running {
    my ($self) = @_;
    my @running = grep { $self->_pid_of_process_type($_) } $self->_expected_standby_processes();
    return wantarray ? @running : scalar @running;
}

sub _pid_running {
    my ($self, $pid) = @_;

    if (not $pid) {
        $self->trace("_pid_running: invalid pid"),
        return 0;
    }

    my $res = $self->_check_pid_via_kill($pid);
    $self->trace("pid $pid is " . ($res ? 'running' : 'not running'));
    return $res;
}

sub _pid_of_process_type {
    my ($self, $type) = @_;
    my $pidfile = $self->_build_pid_file($type);
    my $pid = $self->_read_file($pidfile);
    return $pid && $self->_pid_running($pid) ? $pid : undef;
}

sub _upgrade_pids {
    my ($self, @p) = @_;
    $self->trace("_upgrade_pids(): @p");

    $self->main_upgrade_file or $self->die("upgrade requires 'main_upgrade_file'");
    my $upgrade_timeout = $self->upgrade_timeout // $self->kill_timeout;

    my %pids = map {
        my $pid_and_maybe_cmd = $_;
        if ($ENV{HADC_TRACE} && open(my $fh, '<', "/proc/$_/cmdline")) {
            my $cmd = <$fh>;
            close $fh;
            $pid_and_maybe_cmd .= " ($cmd)" if $cmd;
        }

        $_ => $pid_and_maybe_cmd
    } grep { $_ } @p;

    my %upgrade_files;
    foreach my $pid (keys %pids) {
        my $file = $self->_build_main_upgrade_file($pid);
        $upgrade_files{$pid} = $file;
        $self->_write_file($file);
    }

    my $end = Time::HiRes::time + $upgrade_timeout;
    while (%pids && Time::HiRes::time < $end) {
        foreach my $pid (keys %pids) {
            if (not -f $upgrade_files{$pid}) {
                $self->trace("Successfully upgraded $pids{$pid} via upgrade file");
                delete $pids{$pid}
            }
        }

        Time::HiRes::sleep(0.1);
    }

    foreach my $pid (keys %pids) {
        $self->info("Failed to upgrade process $pids{$pid} via upgrade file (will drop the file)");
        $self->_unlink_file($upgrade_files{$pid});
    }

    return %pids;
}

sub _kill_pids {
    my ($self, @p) = @_;
    $self->trace("_kill_pids(): @p");

    my %pids = map {
        my $pid_and_maybe_cmd = $_;
        if ($ENV{HADC_TRACE} && open(my $fh, '<', "/proc/$_/cmdline")) {
            my $cmd = <$fh>;
            close $fh;
            $pid_and_maybe_cmd .= " ($cmd)" if $cmd;
        }

        $_ => $pid_and_maybe_cmd
    } grep { $_ } @p;

    # first create all stopfiles if necessary
    if ($self->main_stop_file) {
        foreach my $pid (keys %pids) {
            $self->_write_file($self->_build_main_stop_file($pid));
        }

        my $stop_file_timeout = $self->stop_file_kill_timeout // $self->kill_timeout;
        my $end = Time::HiRes::time + $stop_file_timeout;

        while (%pids && Time::HiRes::time < $end) {
            foreach my $pid (keys %pids) {
                if (not $self->_pid_running($pid)) {
                    $self->trace("Successfully killed $pids{$pid} via stop file");
                    $self->_unlink_file($self->_build_main_stop_file($pid));
                    delete $pids{$pid}
                }

            }

            Time::HiRes::sleep(0.1);
        }

        foreach my $pid (keys %pids) {
            $self->info("Failed to kill process $pids{$pid} via stop file");
            $self->_unlink_file($self->_build_main_stop_file($pid));
        }
    }

    my @stop_signals = @{ $self->stop_signals // [qw(TERM TERM INT KILL)] };
    my $signal_timeout = $self->signal_kill_timeout // $self->kill_timeout;

    foreach my $signal (@stop_signals) {
        foreach my $pid (keys %pids) {
            $self->trace("Sending $signal signal to pid $pids{$pid}...");
            $self->_kill_or_die($signal, $pid);
        }

        my $end = Time::HiRes::time + $signal_timeout;
        while (%pids && Time::HiRes::time < $end) {
            foreach my $pid (keys %pids) {
                if (not $self->_pid_running($pid)) {
                    $self->trace("Successfully killed $pids{$pid}");
                    delete $pids{$pid}
                }

                Time::HiRes::sleep(0.1);
            }
        }
    }

    foreach my $pid (keys %pids) {
        $self->trace("Failed to kill $pids{$pid}");
    }

    return %pids;
}

sub _kill_or_die {
    my ($self, $signal, $pid) = @_;

    my $res = kill($signal, $pid);
    if (!$res && $! != POSIX::ESRCH) {
        # don't want to die if proccess simply doesn't exists
        my $msg = "failed to send signal to pid $pid: $!" . ($! == POSIX::EPERM ? ' (not enough permissions, probably should run as root)' : '');
        $self->die($msg);
    }

    return $res;
}

sub _check_pid_via_kill {
    my ($self, $pid) = @_;

    my $kill_result = kill 0 => $pid;
    my $os_error = $!;

    if (!$kill_result and $os_error == POSIX::EINVAL) {
        $self->die("_check_pid_via_kill: kill returned EINVAL, this is very weird");
    }
    elsif (!$kill_result and $os_error == POSIX::EPERM) {
        # process exists but might belong to a different UID, that's fine
        $kill_result = 1;
    }
    elsif (!$kill_result and $os_error == POSIX::ESRCH) {
        # process not found, that's fine
    }

    return $kill_result;
}

sub _wait_standbys_to_complete {
    my ($self) = @_;
    $self->trace('_wait_all_standbys_to_complete()');

    my $end = Time::HiRes::time + $self->_standby_timeout;
    while (Time::HiRes::time < $end) {
        return 1 if $self->_standby_running() == 0;
        Time::HiRes::sleep(0.1);
    }

    return 0;
}

sub _fork {
    my ($self) = @_;
    $self->trace("_double_fork()");
    my $parent_pid = $$;

    my $pid = fork();
    $pid and $self->trace("forked $pid");

    if ($pid == 0) { # Child, launch the process here
        # Become session leader
        POSIX::setsid() or $self->die("failed to setsid: $!");

        my $pid2 = fork();
        $pid2 and $self->trace("forked $pid2");

        if ($pid2 == 0) { # Our double fork.
            if ($self->close_fds_on_start) {
                # close all file handlers but logging one
                my $log_fd = fileno($self->{log_fh});
                my $max_fd = POSIX::sysconf( &POSIX::_SC_OPEN_MAX );
                $max_fd = 64 if !defined $max_fd or $max_fd < 0;
                $log_fd != $_ and POSIX::close($_) foreach (3 .. $max_fd);
            }

            # reopening STDIN, STDOUT, STDERR and redirect them to log_file
            # I need to redirect them because otherwise standbys will keep
            # handles inherited from parent opened for unpredictable amount of time.
            # When a standby become main, it redirect its STDOUT STDERR to
            # $self->stdout_file and $self->stderr_file respectively
            $self->trace("redirect std file handles to " . $self->log_file);
            open(STDIN, '<', '/dev/null')       or $self->die("Failed to open STDIN: $!");
            open(STDOUT, '>>', $self->log_file) or $self->die("Failed to open STDOUT to " . $self->log_file . ": $!");
            open(STDERR, '>>', $self->log_file) or $self->die("Failed to open STDERR to " . $self->log_file . ": $!");

            if ($self->gid) {
                $self->trace("setgid(" . $self->gid . ")");
                POSIX::setgid($self->gid) or $self->die("failed to setgid: $!");
            }

            if ($self->uid) {
                $self->trace("setuid(" . $self->uid . ")");
                POSIX::setuid($self->uid) or $self->die("failed to setuid: $!");

                $ENV{USER} = $self->{user};
                $ENV{HOME} = $self->{user_home_dir};
                $self->trace("\$ENV{USER} => " . $ENV{USER});
                $self->trace("\$ENV{HOME} => " . $ENV{HOME});
            }

            if ($self->umask) {
                umask($self->umask) or $self->warn("failed to umask: $!");
                $self->trace("umask(" . $self->umask . ")");
            }

            if ($self->directory) {
                chdir($self->directory) or $self->die("failed to chdir to " . $self->directory . ": $!");
                $self->trace("chdir(" . $self->directory . ")");
            }

            $self->process_name_change
                and $0 = $self->name;

            exit($self->_acquire_lock_and_launch_program() // 0);
        } elsif (not defined $pid2) {
            $self->warn("cannot fork: $!");
            POSIX::_exit(1);
        } else {
            $self->info("parent process ($parent_pid) forked child ($pid2)");
            POSIX::_exit(0);
        }
    } elsif (not defined $pid) { # We couldn't fork =(
        $self->die("cannot fork: $!");
    } else {
        # Wait until first kid terminates
        $self->trace("waitpid()");
        waitpid($pid, 0);
    }
}

sub _redirect_std_filehandles {
    my ($self) = @_;

    my $stdout = $self->stdout_file;
    if ($stdout && $stdout ne $self->log_file) {
        open(STDOUT, '>>', $stdout) or $self->die("Failed to open STDOUT to $stdout: $!");
        $self->trace("STDOUT redirected to $stdout");
    }

    my $stderr = $self->stderr_file;
    if ($stderr && $stderr ne $self->log_file) {
        open(STDERR, '>>', $stderr) or $self->die("Failed to open STDERR to $stderr: $!");
        $self->trace("STDERR redirected to $stderr");
    }
}

sub _acquire_lock_and_launch_program {
    my ($self) = @_;
    $self->trace("_acquire_lock_and_launch_program()");
    return if $self->_check_stop_file();

    my $pid_file = $self->_build_pid_file("unknown-$$");
    $self->_write_file($pid_file, $$);
    $self->{pid_file} = $pid_file;

    my $ipc = IPC::ConcurrencyLimit::WithStandby->new(%{ $self->ipc_cl_options });

    # have to duplicate this logic from IPC::CL:WS
    my $retries_classback = $ipc->{retries};
    if (ref $retries_classback ne 'CODE') {
        my $max_retries = $retries_classback;
        $retries_classback = sub { return $_[0] != $max_retries + 1 };
    }

    my $ipc_weak = $ipc;
    weaken($ipc_weak);

    $ipc->{retries} = sub {
        if ($_[0] == 1) { # run code on first attempt
            my $id = $ipc_weak->{standby_lock}->lock_id();
            $self->info("acquired standby lock $id");

            # adjusting name of pidfile
            my $pid_file = $self->_build_pid_file("standby-$id");
            $self->_rename_file($self->{pid_file}, $pid_file);
            $self->{pid_file} = $pid_file;
        }

        return 0 if $self->_check_stop_file();
        return $retries_classback->(@_);
    };

    my $id = $ipc->get_lock();
    if (not $id) {
        $self->_unlink_file($self->{pid_file});
        $self->info('failed to acquire both locks, exiting...');
        return 1;
    }

    $self->info("acquired main lock id: " . $ipc->lock_id());

    $self->{ipc_cl_lock_id} = $ipc->lock_id;
    
    # now pid file should be 'main-$id'
    $pid_file = $self->_build_pid_file("main-$id");
    $self->_rename_file($self->{pid_file}, $pid_file);
    $self->{pid_file} = $pid_file;

    my $res = 0;
    if (not $self->_check_stop_file()) {
        # redirect stdou stderr if needed
        $self->_redirect_std_filehandles();

        # let client be aware of lock fd
        my $lock_fd = $self->_main_lock_fd($ipc);
        $lock_fd and $ENV{HADC_lock_fd} = $lock_fd;

        # reset close-on-exec flag is required
        $self->reset_close_on_exec_main_lock_fd
          and $self->_reset_close_on_exec_main_lock_fd($ipc);

        # about to start the app, log_fh is not needed anymore
        close($self->{log_fh});

        # start the app
        $res = $self->_launch_program();
    }

    $self->_unlink_file($self->{pid_file});
    return $res // 0;
}

sub _launch_program {
    my ($self) = @_;
    $self->trace("_launch_program()");
    my @args = @{ $self->program_args // [] };
    return $self->program->($self, @args);
}

sub _expected_main_processes {
    my ($self) = @_;
    my $num = $self->{ipc_cl_options}->{max_procs} // 0;
    my @expected = map { "main-$_" } ( 1 .. $num );
    return wantarray ? @expected : scalar @expected;
}

sub _expected_standby_processes {
    my ($self) = @_;
    my $num = $self->{ipc_cl_options}->{standby_max_procs} // 0;
    my @expected = map { "standby-$_" } ( 1 .. $num );
    return wantarray ? @expected : scalar @expected;
}

#####################################
# file routines
#####################################
sub _build_pid_file {
    my ($self, $type) = @_;
    return $self->pid_dir . "/$type.pid";
}

sub _build_main_stop_file {
    my ($self, $pid) = @_;
    return ($self->main_stop_file =~ s/%p/$pid/gr);
}

sub _build_main_upgrade_file {
    my ($self, $pid) = @_;
    return ($self->main_upgrade_file =~ s/%p/$pid/gr);
}

sub _read_file {
    my ($self, $file) = @_;
    return undef unless -f $file;

    open(my $fh, '<', $file) or $self->die("failed to read $file: $!");
    my $content = do { local $/; <$fh> };
    close($fh);

    $self->trace("read '$content' from file ($file)");
    return $content;
}

sub _write_file {
    my ($self, $file, $content) = @_;
    $content //= '';

    open(my $fh, '>', $file) or $self->die("failed to write $file: $!");
    print $fh $content;
    close($fh);

    $self->trace("wrote '$content' to file ($file)");
}

sub _rename_file {
    my ($self, $old_file, $new_file) = @_;
    rename($old_file, $new_file) or $self->die("failed to rename '$old_file' to '$new_file': $!");
    $self->trace("rename pid file ($old_file) to ($new_file)");
}

sub _unlink_file {
    my ($self, $file) = @_;
    return unless -f $file;
    unlink($file) or $self->die("failed to unlink file '$file': $!");
    $self->trace("unlink file ($file)");
}

sub _create_dir {
    my ($self, $dir) = @_;
    if (-d $dir) {
        $self->trace("Dir exists ($dir) - no need to create");
    } else {
        my $make_path_args = { mode => 0755, error => \my $errors };
        if ($self->uid) {
            $make_path_args->{user} = $self->uid;
        }
        if ($self->gid) {
            $make_path_args->{group} = $self->gid;
        }

        make_path($dir, $make_path_args);
        @$errors and $self->die("failed make_path: " . join(' ', map { keys %$_, values %$_ } @$errors));
        $self->trace("Created dir ($dir)");
    }
}

sub _precreate_directories {
    my ($self) = @_;
    $self->_create_dir($self->pid_dir);
    $self->_create_dir($self->{ipc_cl_options}->{path});
    $self->_create_dir($self->{ipc_cl_options}->{standby_path});

    if ($self->{main_stop_file}) {
        $self->_create_dir(dirname($self->{main_stop_file}));
    }
    if ($self->{standby_stop_file}) {
        $self->_create_dir(dirname($self->{standby_stop_file}));
    }
    if ($self->{main_upgrade_file}) {
        $self->_create_dir(dirname($self->{main_upgrade_file}));
    }
}

sub _check_stop_file {
    my $self = shift;
    if (-f $self->standby_stop_file()) {
        $self->info('standby stop file detected');
        return 1;
    } else {
        return 0;
    }
}

#####################################
# uid/gid routines
#####################################
sub user {
    my ($self, $user) = @_;

    if ($user) {
        my $uid = getpwnam($user)
          or die "Error: Couldn't get uid for non-existent user $user";

        $self->{uid} = $uid;
        $self->{user} = $user;
        $self->trace("Set UID => $uid");
    }

    return $self->{user};
}

sub group {
    my ($self, $group) = @_;

    if ($group) {
        my $gid = getgrnam($group)
          or die "Error: Couldn't get gid for non-existent group $group";

        $self->{gid} = $gid;
        $self->{group} = $group;
        $self->trace("Set GID => $gid");
    }

    return $self->{group};
}

#####################################
# lock detection logic
#####################################
sub detect_stolen_lock {
    my ($self) = @_;
    $self->_main_running() != $self->_expected_main_processes() && $self->_standby_running() == $self->_expected_standby_processes()
        and $self->warn("one of main processes failed to acquire main lock, something is possibly holding it!!!");
}

sub _main_lock_fd {
    my ($self, $ipc) = @_;
    if (   exists $ipc->{main_lock}
        && exists $ipc->{main_lock}->{lock_obj}
        && exists $ipc->{main_lock}->{lock_obj}->{lock_fh})
    {
        my $fd = fileno($ipc->{main_lock}->{lock_obj}->{lock_fh});
        $self->trace("detected lock fd: $fd");
        return $fd;
    }

    $self->warn("failed to detect lock fd");
    return undef;
}

sub _reset_close_on_exec_main_lock_fd {
    my ($self, $ipc) = @_;
    if (   exists $ipc->{main_lock}
        && exists $ipc->{main_lock}->{lock_obj}
        && exists $ipc->{main_lock}->{lock_obj}->{lock_fh})
    {
        $self->info("reset close-on-exec main lock fd");
        my $fh = $ipc->{main_lock}->{lock_obj}->{lock_fh};
        my $flags = fcntl($fh, Fcntl::F_GETFD, 0) or $self->die("fcntl F_GETFD: $!");
        fcntl($fh, Fcntl::F_SETFD, $flags & ~Fcntl::FD_CLOEXEC) or $self->die("fcntl F_SETFD: $!");
    }
}

#####################################
# misc
#####################################
sub pretty_print {
    my ($self, $process_type, $message, $color) = @_;
    return if $self->quiet;

    $color //= "green"; # Green is no color.
    my $code = $self->color_map->{$color} //= 32; # Green is invalid.

    local $| = 1;
    $process_type =~ s/-/ #/;

    if ($ENV{HADC_NO_COLORS}) {
        printf("%-40s: %-40s %40s\n", $self->name, $process_type, "[$message]");
    } else {
        printf("%-40s: %-40s %40s\n", $self->name, $process_type, "\033[$code" ."m[$message]\033[0m");
    }
}

sub _log {
    my ($self, $level, $message) = @_;

    # some commands, such as help|foregournd, don't need loggin
    # so do lazy initialization
    if (not exists $self->{log_fh}) {
        open(my $fh, '>>', $self->log_file) or die "failed to open logfile '" . $self->log_file . "': $!\n";
        chown(($self->uid // -1), ($self->gid // -1), $fh) if $self->uid || $self->gid;
        $self->{log_fh} = $fh;
    }

    if ($self->{log_fh} && defined fileno($self->{log_fh})) {
        my $now = Time::HiRes::time();
        my ($sec, $ms) = split(/[.]/, $now);
        my $date = POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime($now)) . sprintf('.%05d', $ms // 0);
        printf { $self->{log_fh} } "[%s][%d][%s] %s\n", $date, $$, $level, $message;
        $self->{log_fh}->flush();
    }
}

sub _print_check_log_file_for_details {
    my ($self) = @_;
    printf("check %s for details\n", $self->log_file);
}

sub _all_actions {
    my ($self) = @_; 
    no strict 'refs';
    return map { m/^do_(.+)/ ? $1 : () } keys %{ ref($self) . '::' };
}

sub _standby_timeout {
    my $timeout = int(shift->{ipc_cl_options}->{interval} // 0) * 3;
    return $timeout < 1 ? 1 : $timeout;
}

sub info { $_[0]->_log('INFO', $_[1]); }
sub trace { $ENV{HADC_TRACE} and $_[0]->_log('TRACE', $_[1]); }
sub warn { $_[0]->_log('WARN', $_[1]); warn $_[1] . "\n"; }
sub die  { $_[0]->_log('CRIT', $_[1]); die $_[1] . "\n"; }

#####################################
# init script logic
#####################################
sub _dump_init_script {
    my ( $self ) = @_;

    my $data;
    while ( my $line = <DATA> ) {
        last if $line =~ /^__END__$/;
        $data .= $line;
    }

    # So, instead of expanding run_template to use a real DSL
    # or making TT a dependancy, I'm just going to fake template
    # IF logic.
    my $init_source_file = $self->init_config
        ? $self->run_template(
            '[ -r [% FILE %] ] && . [% FILE %]',
            { FILE => $self->init_config } )
        : "";

    print $self->_run_template(
        $data,
        {
            HEADER            => 'Generated at ' . scalar(localtime) . ' with HADaemon::Control ' . ($self->VERSION // 'DEV'),
            NAME              => $self->name      // '',
            REQUIRED_START    => $self->lsb_start // '',
            REQUIRED_STOP     => $self->lsb_stop  // '',
            SHORT_DESCRIPTION => $self->lsb_sdesc // '',
            DESCRIPTION       => $self->lsb_desc  // '',
            SCRIPT            => $self->path      // abs_path($0),
            INIT_SOURCE_FILE  => $init_source_file,
            INIT_CODE_BLOCK   => $self->init_code // '',
        }
    );

    return 0;
}

sub _run_template {
    my ($self, $content, $config) = @_;
    $content =~ s/\[% (.*?) %\]/$config->{$1}/g;
    return $content;
}

1;

__DATA__
#!/bin/sh

# [% HEADER %]

### BEGIN INIT INFO
# Provides:          [% NAME %]
# Required-Start:    [% REQUIRED_START %]
# Required-Stop:     [% REQUIRED_STOP %]
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: [% SHORT_DESCRIPTION %]
# Description:       [% DESCRIPTION %]
### END INIT INFO

[% INIT_SOURCE_FILE %]

[% INIT_CODE_BLOCK %]

if [ -x [% SCRIPT %] ];
then
    [% SCRIPT %] $1
else
    echo "Required program [% SCRIPT %] not found!"
    exit 1;
fi

__END__

=encoding utf8

=head1 NAME

HADaemon::Control - Create init scripts for Perl high-available (HA) daemons

=head1 DESCRIPTION

HADaemon::Control provides a library for creating init scripts for HA daemons in perl.
It allows you to run one or more main processes accompanied by a set of standby processes.
Standby processes constantly check presence of main ones and if later exits or dies
promote themselves and replace gone main processes. By doing so, HADaemon::Control
achieves high-availability and fault tolerance for a service provided by the deamon.
Your perl script just needs to set the accessors for what and how you
want something to run and the library takes care of the rest.

The library takes idea and interface from L<Daemon::Control> and combine them
with facilities of L<IPC::ConcurrencyLimit::WithStandby>. L<IPC::ConcurrencyLimit::WithStandby>
implements a mechanism to limit the number of concurrent processes in a cooperative
multiprocessing environment. For more information refer to the documentation
of L<IPC::ConcurrencyLimit> and L<IPC::ConcurrencyLimit::WithStandby>

=head1 SYNOPSIS

    #!/usr/bin/env perl

    use strict;
    use warnings;
    use HADaemon::Control;

    my $dc = HADaemon::Control->new({
        name => 'test.pl',
        user => 'nobody',
        pid_dir => '/tmp/test',
        log_file => '/tmp/test.log',
        program => sub { sleep 10; },
    });

    exit $dc->run();

You can then call the program:

    /usr/bin/my_program_launcher.pl start

By default C<run> will use @ARGV for the action, and exit with an LSB compatible
exit code. For finer control, you can use C<run_command>, which will return
the exit code, and accepts the action as an argument.  This enables more programatic
control, as well as running multiple instances of L<HADaemon::Control> from one script.

    my $dc = HADaemon::Control->new({
        ...
    });

    my $exit = $daemon->run_command(“start”);

=head1 CONSTRUCTOR

The constructor takes the following arguments.

=head2 name

The name of the program the daemon is controlling. This will be used in status messages.
See also C<process_name_change>.

=head2 program

This should be a coderef of actual programm to run.

    $daemon->program( sub { ... } );

=head2 program_args

This is an array ref of the arguments for the program. Args will be given to the program
coderef as @_, the HADaemon::Control instance that called the coderef will be passed
as the first arguments.  Your arguments start at $_[1].

    $daemon->program_args( [ 'foo', 'bar' ] );

=head2 pid_dir

This option defines directory where all pidfile will be created

    $daemon->pid_dir('/var/run/my_program_launcher');

=head2 ipc_cl_options

This option gives ability to tune settings of underlying L<IPC::ConcurrencyLimit::WithStandby> object.
By default HADaemon::Control sets following settings:

    ipc_cl_options => {
        type              => 'Flock',                             # the only supported type
        max_procs         => 1,                                   # one main process
        standby_max_procs => 1,                                   # one standby process
        interval          => 1,                                   # stanby tries to acquire main lock every second
        retries           => sub { 1 },                           # keep retrying forever
        path              => $daemon->pid_dir . '/lock/',         # path for main locks
        standby_path      => $daemon->pid_dir . '/lock-standby/', # path for standby locks
    },

=head2 main_stop_file

This option provides an alternative way of stopping main processes apart of sending a signal (ex. TERM). If specified,
HADaemon::Control touch this file and wait L<stop_file_kill_timeout> or L<kill_timeout> seconds hoping that main processes will respect the file
and exit. If not, normal termination loop is entered (i.e. sending sequence of signals TERM TERM INT KILL).
The filename can include %p which is replaced by PID of a process. Default value is undef.

=head2 standby_stop_file

The path to stop file for standby process. See C<do_start>, C<do_stop>, C<do_restart> for details. By default is set to:

    $daemon->standby_stop_file($daemon->pid_dir . '/standby-stop-file');

=head2 stop_signals

An array ref of signals that should be tried (in order) when stopping the daemon. Default signals are C<TERM>, C<TERM>, C<INT> and C<KILL> (yes, C<TERM> is tried twice).

=head2 log_file

HADaemon::Control uses C<log_file> for two purposes:

=over 4

=item * HADaemon::Control redirects STDOUT and STDERR for forked processes to given file

=item * HADaemon::Control prints its own log to given file

=back

If you don't want to mix logs of the application and init script consider using C<stdout_file> and C<stderr_file>.
Verbosity of logs of HADaemon::Control can be controled by C<HADC_TRACE> environment variable.

=head2 process_name_change

If set, HADaemon::Control will set name of the process to C<name>. Also, it adds process_name_change option into C<ipc_cl_options>.
As result, C<process_name_change> makes nice names for both main and standby processes. For example:

    my $dc = HADaemon::Control->new({
        name => 'My test daemon',
        pid_dir => '/tmp/test',
        log_file => '/tmp/test.log',
        program => sub { sleep 10; },
        process_name_change => 1,
    });

leads to:

    My test daemon              # name of main process
    My test daemon - standby    # name of standby process

=head2 user

When set, the username supplied to this accessor will be used to set
the UID attribute. When this is used, C<uid> will be changed from
its initial settings if you set it (which you shouldn't, since you're
using usernames instead of UIDs). See L</uid> for setting numerical
user ids.

    $daemon->user('www-data');

=head2 group

When set, the groupname supplied to this accessor will be used to set
the GID attribute. When this is used, C<gid> will be changed from
its initial settings if you set it (which you shouldn't, since you're
using groupnames instead of GIDs). See L</gid> for setting numerical
group ids.

    $daemon->group('www-data');

=head2 uid

If provided, the UID that the program will drop to when forked. This will
only work if you are running as root. Accepts numeric UID. For usernames
please see L</user>.

    $daemon->uid( 1001 );

=head2 gid

If provided, the GID that the program will drop to when forked. This will
only work if you are running as root. Accepts numeric GID, for groupnames
please see L</group>.

    $daemon->gid( 1001 );

=head2 umask

If provided, the umask of the daemon will be set to the umask provided,
note that the umask must be in oct. By default the umask will not be
changed.

    $daemon->umask( 022 );

    Or:

    $daemon->umask( oct("022") );

=head2 directory

If provided, chdir to this directory before execution.

=head2 stdout_file

If provided stdout of main process will be redirected to the given file.

    $daemon->stdout_file( "/tmp/mydaemon.stdout" );

=head2 stderr_file

If provided stderr of main process will be redirected to the given file.

    $daemon->stderr_file( "/tmp/mydaemon.stderr" );

=head2 kill_timeout

This provides an amount of time in seconds between trying different means
of terminating the daemon. This value should be increased if your daemon has
a longer shutdown period. By default 1 second is used.

    $daemon->kill_timeout( 7 );

This value is used both for stop files and signals.

=head2 stop_file_kill_timeout

This is a more specific variant of L<kill_timeout>. It provides the amount of seconds
we allow the daemon to terminate itself once a stop file has been created.

If provided, this value has priority over L<kill_timeout>.

    $daemon->stop_file_kill_timeout( 42 );

=head2 signal_kill_timeout

This is a more specific variant of L<kill_timeout>. It provides the amount of seconds
between firing different signals to terminate the daemon.

If provided, this value has priority over L<kill_timeout>.

    $daemon->signal_kill_timeout( 42 );

=head2 quiet

If this boolean flag is set to a true value all output from the init script
(NOT your daemon) to STDOUT will be suppressed.

    $daemon->quiet( 1 );

=head2 close_fds_on_start

By default HADC closes all file descriptors apart of STDIN, STDOUT, STDERR
and lock fd (see HADC_lock_fd) when it starts main process.
This is done to make sure that main and standby processes are really
independent of each other.

If this behaivor is not desirable, one can set close_fds_on_start to 0.
But it should be understood that if parent process open any file descriptor
(i.e. establish any connection, open file, create pipe, etc) those FDs will
be available in *both* main and standby processes. Such case can be dangerous. Consider this:
- parent processes (i.e. processes which run HADC) connect to DB
- HADC starts main processes which uses that DB connection
- HADC starts standby process
- after a while main processes crashes and leave connectiong to DB in unpredicted state
- standby processes promotes to main one and try to use *same* connection to DB.
  Since connection is in unpredicted state, it failes to use connection and crashes too.

=head2 reset_close_on_exec_main_lock_fd

By default perl sets close-on-exec flag for all opened file descriptors. If this flag is not
desirable for lock fd one can set this option to true. This option should be set if client
code do exec(). For details about close-on-exec check 'man fcntl'.

=head1 INIT FILE CONSTRUCTOR OPTIONS

The constructor also takes the following arguments to generate init file. See L</do_get_init_file>.

=head2 path

The path of the script you are using HADaemon::Control in. This will be used in
the LSB file generation to point it to the location of the script. If this is
not provided, the absolute path of $0 will be used.

=head2 init_config

The name of the init config file to load. When provided your init script will
source this file to include the environment variables. This is useful for setting
a C<PERL5LIB> and such things.

    $daemon->init_config( "/etc/default/my_program" );

    If you are using perlbrew, you probably want to set your init_config to
    C<$ENV{PERLBREW_ROOT} . '/etc/bashrc'>.

=head2 init_code

When given, whatever text is in this field will be dumped directly into
the generated init file.

    $daemon->init_code( "Arbitrary code goes here." )

=head2 lsb_start

The value of this string is used for the 'Required-Start' value of
the generated LSB init script. See L<http://wiki.debian.org/LSBInitScripts>
for more information.

    $daemon->lsb_start( '$remote_fs $syslog' );

=head2 lsb_stop

The value of this string is used for the 'Required-Stop' value of
the generated LSB init script. See L<http://wiki.debian.org/LSBInitScripts>
for more information.

    $daemon->lsb_stop( '$remote_fs $syslog' );

=head2 lsb_sdesc

The value of this string is used for the 'Short-Description' value of
the generated LSB init script. See L<http://wiki.debian.org/LSBInitScripts>
for more information.

    $daemon->lsb_sdesc( 'My program...' );

=head2 lsb_desc

The value of this string is used for the 'Description' value of
the generated LSB init script. See L<http://wiki.debian.org/LSBInitScripts>
for more information.

    $daemon->lsb_desc( 'My program controls a thing that does a thing.' );

=head1 METHODS

=head2 run_command

This function will process an action on the HADaemon::Control instance.
Valid arguments are those which a C<do_> method exists for, such as 
B<start>, B<stop>, B<restart>. Returns the LSB exit code for the
action processed.

=head2 run

This will make your program act as an init file, accepting input from
the command line. Run will exit with 0 for success and uses LSB exit
codes. As such no code should be used after ->run is called. Any code
in your file should be before this. This is a shortcut for 

    exit HADaemon::Control->new(...)->run_command( @ARGV );

=head2 do_start

Is called when start is given as an argument. Starts the forking and
exits. The forking includes starting C<ipc_cl_options->{max_procs}> main and
C<ipc_cl_options->{standby_max_procs}> standby processes. Exit with success
only if all processes were spawned. Called by:

    /usr/bin/my_program_launcher.pl start

=head2 do_stop

Is called when stop is given as an argument. Stops the all running proceses
which belongs to the daemon if it can. Stopping is done via:

=over 4

=item * touching C<standby_stop_file> file to stop standby processes and prevent
new proceses to be started via C<do_fork> command.

=item * if C<main_stop_file> specified, touch it to stop main processes. See L<main_stop_file>.

=item * send "TERM TERM INT KILL" sequence of signals to kill main processes

=back

Called by:

    /usr/bin/my_program_launcher.pl stop

=head2 do_restart

Is called when restart is given as an argument. This command triggers restart cycle which
includes several steps:

=over 4

=item * stop all standby daemons by touching C<standby_stop_file>

=item * start new instances of standby processes

=item * kill main processes one by one. Once a main processes is dead, running standby immediately
become main one hence minimize downtime to C<ipc_cl_options->{interval}> seconds (or miliseconds).

=item * again start standby processes to compensate the lost of standby processes

=back

Called by:

    /usr/bin/my_program_launcher.pl restart

=head2 do_hard_restart

Is called when hard_restart is given as an argument. Calls C<do_stop> and C<do_start>.
Called by:

    /usr/bin/my_program_launcher.pl hard_restart

=head2 do_fork

Is called when fork is given as an argument. This command is almost equal to L<do_start>,
but is design for periodical run in a cronjob. Called by:

    /usr/bin/my_program_launcher.pl fork

=head2 do_reload

Is called when reload is given as an argument. Sends a HUP signal to the
main processes.

    /usr/bin/my_program_launcher.pl reload

=head2 do_status

Is called when status is given as an argument. Displays the statuses of the
program (i.e. all running processes), basic on the PID files. Called by:

    /usr/bin/my_program_launcher.pl status

=head2 do_foreground

Is called when B<foreground> is given as an argument. Starts the
program or code reference and stays in the foreground -- no forking
and locking is done, regardless of the compile-time arguments.
Additionally, turns C<quiet> on to avoid showing L<HADaemon::Control> output.

    /usr/bin/my_program_launcher.pl foreground

=head2 do_get_init_file

Is called when get_init_file is given as an argument. Dumps an LSB
compatible init file, for use in /etc/init.d/. Called by:

    /usr/bin/my_program_launcher.pl get_init_file

=head2 pretty_print

This is used to display status to the user. It accepts a message and a color.
It will default to green text, if no color is explicitly given. Only supports
red and green. If C<HADC_NO_COLORS> environment variable is set no colors are used.

    $daemon->pretty_print( "My Status", "red" );

=head1 KNOWN ISSUES

HADaemon::Control uses C<flock> based locks. This type of locks have property of getting
inherited accross C<fork> system call. This behavior is not desirable and actually
destructible for HADaemon::Control. Once the locked is inherited, two processes
(parent and child) will own the same lock. Only releasing the lock from both processes
allows another one to acuire the lock. To prevent such behivour HADaemon::Control exposes
lock's file descriptor via HADC_lock_fd environment variable.

If an application forks, a child process should close lock's file descriptor right after
exiting from C<fork> syscal. One of the possible ways is to run:

    $ENV{HADC_lock_fd} and POSIX::close($ENV{HADC_lock_fd});

Another source of troubles could be the fact that HADC closes all file descriptors apart
of STDIN, STDOUT, STDERR and lock fd upon starting main processes (tunable via C<close_fds_on_start>).
This's done for a reason. See C<close_fds_on_start> for details.

=head1 AUTHOR

Ivan Kruglov, C<ivan.kruglov@yahoo.com>

=head1 CONTRIBUTORS

Alexey Surikov C<alexey.surikov@booking.com>

=head1 ACKNOWLEDGMENT

This module was inspired by module L<Daemon::Control|https://github.com/symkat/Daemon-Control>.

This module was originally developed for Booking.com.
With approval from Booking.com, this module was generalized
and put on CPAN, for which the authors would like to express
their gratitude.

=head1 COPYRIGHT AND LICENSE

(C) 2013, 2014 Ivan Kruglov. All rights reserved.

This code is available under the same license as Perl version
5.8.1 or higher.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head2 AVAILABILITY

The most current version of HADaemon::Control can be found at L<https://github.com/ikruglov/HADaemon-Control>
