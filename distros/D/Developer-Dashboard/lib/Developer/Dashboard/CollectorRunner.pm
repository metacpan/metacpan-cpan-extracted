package Developer::Dashboard::CollectorRunner;

use strict;
use warnings;

our $VERSION = '2.17';

use Capture::Tiny qw(capture);
use Cwd qw(cwd);
use File::Spec;
use POSIX qw(setsid strftime);
use Time::HiRes qw(sleep time);

use Developer::Dashboard::JSON qw(json_encode json_decode);
use Developer::Dashboard::Platform qw(shell_command_argv);

our $SIGNAL_RUNNER;
our $SIGNAL_LOOP_NAME;

# new(%args)
# Constructs the collector execution runtime.
# Input: collectors, files, paths, and optional indicators objects.
# Output: Developer::Dashboard::CollectorRunner object.
sub new {
    my ( $class, %args ) = @_;
    my $collectors = $args{collectors} || die 'Missing collector store';
    my $files      = $args{files}      || die 'Missing file registry';
    my $paths      = $args{paths}      || die 'Missing path registry';

    return bless {
        collectors => $collectors,
        files      => $files,
        indicators => $args{indicators},
        paths      => $paths,
    }, $class;
}

# run_once($job)
# Executes a collector job a single time with cwd/env/timeout handling.
# Input: collector job hash reference.
# Output: result hash reference with stdout, stderr, exit_code, and timed_out.
sub run_once {
    my ( $self, $job ) = @_;
    die 'Collector job must be a hash' if ref($job) ne 'HASH';
    my $name = $job->{name} || die 'Collector job missing name';
    my ( $mode, $source ) = $self->_collector_source($job);

    my $cwd = $job->{cwd} || cwd();
    if ( !File::Spec->file_name_is_absolute($cwd) && $self->{paths}->can($cwd) ) {
        $cwd = $self->{paths}->$cwd();
    }

    die "Collector cwd '$cwd' does not exist" if !-d $cwd;

    my $started_at = _now_iso8601();
    $self->{collectors}->write_job(
        $name,
        {
            name       => $name,
            command    => $job->{command},
            code       => $job->{code},
            mode       => $mode,
            cwd        => $cwd,
            interval   => $job->{interval},
            cron       => $job->{cron},
            schedule   => $job->{schedule},
            timeout    => $job->{timeout} || $job->{timeout_ms},
            env        => $job->{env},
            output_format => $job->{output_format},
            updated_at => $started_at,
        }
    );
    $self->{collectors}->write_status(
        $name,
        {
            enabled         => 1,
            running         => 1,
            last_started_at => $started_at,
            schedule        => $job->{schedule} || ( $job->{cron} ? 'cron' : $job->{interval} ? 'interval' : 'manual' ),
        }
    );

    my ( $stdout, $stderr, $exit_code, $timed_out ) = $self->_run_job(
        mode       => $mode,
        source     => $source,
        cwd        => $cwd,
        env        => $job->{env},
        timeout_ms => $job->{timeout_ms} || ( $job->{timeout} ? $job->{timeout} * 1000 : undef ),
    );

    $self->{collectors}->write_result(
        $name,
        exit_code => $exit_code,
        stdout    => $stdout,
        stderr    => $stderr,
        started_at => $started_at,
        running    => 0,
        output_format => $job->{output_format},
        timed_out  => $timed_out,
    );
    if ( $self->{indicators} && ref( $job->{indicator} ) eq 'HASH' ) {
        my $indicator_name = $job->{indicator}{name} || $name;
        my $indicator_label = defined $job->{indicator}{label} && $job->{indicator}{label} ne ''
          ? $job->{indicator}{label}
          : $indicator_name;
        $self->{indicators}->set_indicator(
            $indicator_name,
            %{ $job->{indicator} },
            name => $indicator_name,
            label => $indicator_label,
            collector_name => $name,
            managed_by_collector => 1,
            status => $exit_code ? 'error' : 'ok',
            prompt_visible => exists $job->{indicator}{prompt_visible} ? $job->{indicator}{prompt_visible} : 1,
        );
    }

    return {
        name      => $name,
        exit_code => $exit_code,
        stdout    => $stdout,
        stderr    => $stderr,
        timed_out => $timed_out ? 1 : 0,
    };
}

# _collector_source($job)
# Resolves whether a collector should execute shell command text or Perl code.
# Input: collector job hash reference.
# Output: list of execution mode string and source text string.
sub _collector_source {
    my ( $self, $job ) = @_;
    return ( 'command', $job->{command} ) if defined $job->{command} && $job->{command} ne '';
    return ( 'code', $job->{code} ) if defined $job->{code} && $job->{code} ne '';
    my $name = ref($job) eq 'HASH' ? ( $job->{name} || '(unnamed)' ) : '(unnamed)';
    die "Collector '$name' missing command or code";
}

# _run_job(%args)
# Dispatches collector execution to shell-command or Perl-code mode.
# Input: mode string, source text, cwd path, env hash, and timeout_ms.
# Output: list of stdout, stderr, exit_code, and timed_out flag.
sub _run_job {
    my ( $self, %args ) = @_;
    my $mode = $args{mode} || die 'Missing collector mode';
    return $self->_run_command(%args) if $mode eq 'command';
    return $self->_run_code(%args) if $mode eq 'code';
    die "Unknown collector mode '$mode'";
}

# start_loop($job)
# Starts a managed collector loop for interval or cron schedules.
# Input: collector job hash reference.
# Output: existing or newly forked collector pid integer.
sub start_loop {
    my ( $self, $job ) = @_;
    my $interval = $job->{interval} || 30;
    my $name = $job->{name} || die 'Collector job missing name';
    my $schedule_mode = $job->{schedule} || ( $job->{cron} ? 'cron' : $job->{interval} ? 'interval' : 'manual' );
    die "Collector '$name' uses manual schedule and should be run on demand" if $schedule_mode eq 'manual';
    my $pidfile = $self->_pidfile($name);
    my $title   = $self->_process_title($name);

    if ( -f $pidfile ) {
        my $pid = _slurp($pidfile);
        chomp $pid;
        if ( $pid && $self->_is_managed_loop( $pid, $name ) ) {
            $self->_write_loop_state(
                $name,
                {
                    pid          => $pid,
                    name         => $name,
                    process_name => $title,
                    interval     => $interval,
                    schedule     => $schedule_mode,
                    status       => 'running',
                    heartbeat_at => _now_iso8601(),
                }
            );
            return $pid;
        }
        $self->_cleanup_loop_files($name);
    }

    my $pid = $self->_fork_process();
    die "Unable to fork collector '$name': $!" if !defined $pid;

    if ($pid) {
        open my $fh, '>', $pidfile or die "Unable to write $pidfile: $!";
        print {$fh} $pid;
        close $fh;
        $self->{paths}->secure_file_permissions($pidfile);
        $self->_write_loop_state(
            $name,
            {
                pid          => $pid,
                name         => $name,
                process_name => $title,
                command      => $job->{command},
                cwd          => $job->{cwd},
                interval     => $interval,
                schedule     => $schedule_mode,
                status       => 'starting',
                started_at   => _now_iso8601(),
                heartbeat_at => _now_iso8601(),
            }
        );
        return $pid;
    }

    return $self->_run_loop_child(
        interval      => $interval,
        job           => $job,
        name          => $name,
        schedule_mode => $schedule_mode,
        title         => $title,
    );
}

# _fork_process()
# Wraps Perl fork so tests can override collector loop spawning.
# Input: none.
# Output: child pid in parent, zero in child, or undef on failure.
sub _fork_process {
    return fork();
}

# _run_loop_child(%args)
# Runs the managed collector child loop, including daemon setup and loop work.
# Input: collector job, name, process title, interval, schedule mode, and optional daemonize/single_tick flags.
# Output: true value for test mode or never returns in normal daemon mode.
sub _run_loop_child {
    my ( $self, %args ) = @_;
    my $job           = $args{job}           || die 'Missing collector job';
    my $name          = $args{name}          || die 'Missing collector name';
    my $title         = $args{title}         || $self->_process_title($name);
    my $interval      = defined $args{interval} ? $args{interval} : 30;
    my $schedule_mode = $args{schedule_mode} || 'interval';
    my $daemonize     = exists $args{daemonize} ? $args{daemonize} : 1;
    my $single_tick   = $args{single_tick} ? 1 : 0;

    if ($daemonize) {
        setsid();
        open STDIN, '<', File::Spec->devnull() or die $!;
        open STDOUT, '>>', $self->{files}->collector_log or die $!;
        open STDERR, '>>', $self->{files}->collector_log or die $!;
    }

    $ENV{DEVELOPER_DASHBOARD_LOOP_NAME}   = $name;
    $ENV{DEVELOPER_DASHBOARD_LOOP_STATUS} = 'running';
    $0 = $title;
    local $SIGNAL_RUNNER    = $self;
    local $SIGNAL_LOOP_NAME = $name;
    local $SIG{TERM} = \&_signal_stop;
    local $SIG{INT}  = \&_signal_stop;
    local $SIG{HUP}  = \&_signal_stop;

    while (1) {
        $self->_write_loop_state(
            $name,
            {
                pid          => $$,
                name         => $name,
                process_name => $title,
                command      => $job->{command},
                cwd          => $job->{cwd},
                interval     => $interval,
                schedule     => $schedule_mode,
                status       => 'running',
                heartbeat_at => _now_iso8601(),
            }
        );
        my $due = $self->_job_is_due( $job, $name );
        eval { $self->run_once($job) } if $due;
        if ($@) {
            my $error = "$@";
            my $message = sprintf "[%s][%s] %s\n", _now_iso8601(), $name, $error;
            $self->{files}->append( 'collector_log', $message );
            $self->_write_loop_state(
                $name,
                {
                    pid          => $$,
                    name         => $name,
                    process_name => $title,
                    command      => $job->{command},
                    cwd          => $job->{cwd},
                    interval     => $interval,
                    schedule     => $schedule_mode,
                    status       => 'error',
                    heartbeat_at => _now_iso8601(),
                    error        => $error,
                }
            );
        }
        sleep( $schedule_mode eq 'cron' ? 1 : $interval );
        return 1 if $single_tick;
    }
}

# stop_loop($name)
# Stops a managed collector loop by collector name.
# Input: collector name string.
# Output: stopped pid integer or undef when missing.
sub stop_loop {
    my ( $self, $name ) = @_;
    my $pidfile = $self->_pidfile($name);
    return if !-f $pidfile;
    my $pid = _slurp($pidfile);
    chomp $pid;
    if ( $pid && $self->_is_managed_loop( $pid, $name ) ) {
        kill 'TERM', $pid;
        for ( 1 .. 20 ) {
            last if !kill 0, $pid;
            sleep 0.1;
        }
        kill 'KILL', $pid if kill 0, $pid;
    }
    $self->_cleanup_loop_files($name);
    return $pid;
}

# running_loops()
# Lists managed collector loops that are still running.
# Input: none.
# Output: sorted list of loop hash references.
sub running_loops {
    my ($self) = @_;
    my $root = $self->{paths}->collectors_root;
    opendir my $dh, $root or return;

    my @running;
    while ( my $entry = readdir $dh ) {
        next if $entry eq '.' || $entry eq '..';
        next if $entry !~ /^(.*)\.pid$/;
        my $name = $1;
        my $pid  = eval { _slurp( File::Spec->catfile( $root, $entry ) ) };
        next if !$pid;
        chomp $pid;
        if ( $pid && $self->_is_managed_loop( $pid, $name ) ) {
            push @running, { name => $name, pid => $pid, state => scalar $self->loop_state($name) };
            next;
        }
        $self->_cleanup_loop_files($name);
    }
    closedir $dh;

    my @sorted = @running;
    @sorted = sort _sort_loop_names @sorted;
    return @sorted;
}

# _sort_loop_names()
# Sort callback for managed loop metadata rows by collector name.
# Input: package globals $a and $b containing loop hash references.
# Output: string comparison integer suitable for Perl sort.
sub _sort_loop_names {
    return $a->{name} cmp $b->{name};
}

# loop_state($name)
# Loads persisted loop state metadata for a collector.
# Input: collector name string.
# Output: state hash reference or undef.
sub loop_state {
    my ( $self, $name ) = @_;
    my $file = $self->_statefile($name);
    return if !-f $file;
    open my $fh, '<', $file or die "Unable to read $file: $!";
    local $/;
    return json_decode( scalar <$fh> );
}

# _pidfile($name)
# Returns the pidfile path for a collector loop.
# Input: collector name string.
# Output: file path string.
sub _pidfile {
    my ( $self, $name ) = @_;
    return File::Spec->catfile( $self->{paths}->collectors_root, "$name.pid" );
}

# _statefile($name)
# Returns the loop state file path for a collector loop.
# Input: collector name string.
# Output: file path string.
sub _statefile {
    my ( $self, $name ) = @_;
    return File::Spec->catfile( $self->{paths}->collector_dir($name), 'loop.json' );
}

# _process_title($name)
# Builds the managed process title string for a collector loop.
# Input: collector name string.
# Output: process title string.
sub _process_title {
    my ( $self, $name ) = @_;
    return "dashboard collector: $name";
}

# _is_managed_loop($pid, $name)
# Checks whether a pid belongs to a managed collector loop.
# Input: process id integer and collector name string.
# Output: boolean managed flag.
sub _is_managed_loop {
    my ( $self, $pid, $name ) = @_;
    return 0 if !$pid || !kill 0, $pid;
    my $marker = $self->_read_process_env_marker( $pid, 'DEVELOPER_DASHBOARD_LOOP_NAME' );
    return 1 if defined $marker && $marker eq $name;
    my $title = $self->_read_process_title($pid);
    return 0 if !defined $title || $title eq '';
    return $title eq $self->_process_title($name) ? 1 : 0;
}

# _read_process_env_marker($pid, $key)
# Reads a named environment variable from a process when available.
# Input: process id integer and env key string.
# Output: env value string or undef.
sub _read_process_env_marker {
    my ( $self, $pid, $key ) = @_;
    my $proc = "/proc/$pid/environ";
    return if !-r $proc;
    open my $fh, '<', $proc or return;
    local $/;
    my $env = scalar <$fh>;
    return if !defined $env || $env eq '';
    for my $pair ( split /\0/, $env ) {
        next if $pair !~ /^([^=]+)=(.*)$/s;
        return $2 if $1 eq $key;
    }
    return;
}

# _read_process_title($pid)
# Reads the command line title for a process.
# Input: process id integer.
# Output: process title string or undef.
sub _read_process_title {
    my ( $self, $pid ) = @_;
    my $proc = "/proc/$pid/cmdline";
    my $cmdline = $self->_read_proc_file($proc);
    if ( defined $cmdline && $cmdline ne '' ) {
        $cmdline =~ s/\0/ /g if defined $cmdline;
        $cmdline =~ s/\s+$// if defined $cmdline;
        return $cmdline;
    }

    my ( $title, undef, $exit_code ) = capture {
        system 'ps', '-o', 'args=', '-p', $pid;
        return $? >> 8;
    };
    return if defined $exit_code && $exit_code != 0;
    $title =~ s/\s+$// if defined $title;
    return $title;
}

# _read_proc_file($file)
# Reads a procfs file when it is available.
# Input: file path string.
# Output: file content string or undef.
sub _read_proc_file {
    my ( $self, $file ) = @_;
    return if !-r $file;
    open my $fh, '<', $file or return;
    local $/;
    return scalar <$fh>;
}

# _write_loop_state($name, $data)
# Atomically writes loop lifecycle metadata for a collector.
# Input: collector name string and partial state hash reference.
# Output: merged state hash reference.
sub _write_loop_state {
    my ( $self, $name, $data ) = @_;
    my $file = $self->_statefile($name);
    my $existing = eval { $self->loop_state($name) } || {};
    my %state = (
        %$existing,
        %{ $data || {} },
        name => $name,
    );
    my $tmp = sprintf '%s.%s.%s.pending', $file, $$, time;
    open my $fh, '>', $tmp or die "Unable to write $tmp: $!";
    print {$fh} json_encode( \%state );
    close $fh;
    $self->{paths}->secure_file_permissions($tmp);
    rename $tmp, $file or die "Unable to rename $tmp to $file: $!";
    $self->{paths}->secure_file_permissions($file);
    return \%state;
}

# _cleanup_loop_files($name)
# Removes persisted loop pid and state files for a collector.
# Input: collector name string.
# Output: true value.
sub _cleanup_loop_files {
    my ( $self, $name ) = @_;
    unlink $self->_pidfile($name) if -f $self->_pidfile($name);
    unlink $self->_statefile($name) if -f $self->_statefile($name);
    return 1;
}

# _job_is_due($job, $name)
# Decides whether the current loop tick should execute the collector job.
# Input: collector job hash reference and collector name string.
# Output: boolean due flag.
sub _job_is_due {
    my ( $self, $job, $name ) = @_;
    my $mode = $job->{schedule} || ( $job->{cron} ? 'cron' : $job->{interval} ? 'interval' : 'manual' );
    return 0 if $mode eq 'manual';
    return 1 if $mode eq 'interval';
    return $self->_cron_due( $job->{cron}, $name );
}

# _cron_due($expr, $name)
# Checks cron timing and de-duplicates within a single cron slot.
# Input: cron expression string and collector name string.
# Output: boolean due flag.
sub _cron_due {
    my ( $self, $expr, $name ) = @_;
    return 1 if !defined $expr || $expr eq '' || $expr eq '* * * * *';
    my @now = localtime();
    my @parts = split /\s+/, $expr;
    return 0 if @parts < 5;
    my ( $min, $hour, $mday, $mon, $wday ) = @parts[ 0 .. 4 ];
    return 0 if !_cron_match( $min,  $now[1] );
    return 0 if !_cron_match( $hour, $now[2] );
    return 0 if !_cron_match( $mday, $now[3] );
    return 0 if !_cron_match( $mon,  $now[4] + 1 );
    return 0 if !_cron_match( $wday, $now[6] );

    my $state = $self->loop_state($name) || {};
    my $stamp = sprintf '%04d-%02d-%02dT%02d:%02d', $now[5] + 1900, $now[4] + 1, $now[3], $now[2], $now[1];
    return 0 if ( $state->{last_cron_slot} || '' ) eq $stamp;
    $self->_write_loop_state( $name, { last_cron_slot => $stamp } );
    return 1;
}

# _cron_match($spec, $value)
# Matches one cron field spec against a numeric value.
# Input: cron field string and numeric value.
# Output: boolean match flag.
sub _cron_match {
    my ( $spec, $value ) = @_;
    return 1 if !defined $spec || $spec eq '*' || $spec eq '';
    for my $part ( split /,/, $spec ) {
        return 1 if $part =~ /^\d+$/ && $part == $value;
        if ( $part =~ m{^\*/(\d+)$} ) {
            return 1 if $1 && $value % $1 == 0;
        }
        if ( $part =~ /^(\d+)-(\d+)$/ ) {
            return 1 if $value >= $1 && $value <= $2;
        }
    }
    return 0;
}

# _run_command(%args)
# Executes a collector command with captured stdout/stderr and timeout handling.
# Input: command string, cwd path, env hash, and timeout_ms.
# Output: list of stdout, stderr, exit_code, and timed_out flag.
sub _run_command {
    my ( $self, %args ) = @_;
    my $cmd        = $args{source};
    my $cwd        = $args{cwd};
    my $env        = ref( $args{env} ) eq 'HASH' ? $args{env} : {};
    my $timeout_ms = $args{timeout_ms} || 30_000;

    my $old = cwd();
    chdir $cwd or die "Unable to chdir to $cwd: $!";
    local @ENV{ keys %$env } = values %$env if %$env;
    my $timed_out = 0;
    my ( $stdout, $stderr, $exit_code ) = capture {
        local $SIG{ALRM} = sub { die "__COLLECTOR_TIMEOUT__\n" };
        alarm( int( ( $timeout_ms + 999 ) / 1000 ) );
        my $ok = eval {
            system shell_command_argv($cmd);
            return $? >> 8;
        };
        if ($@) {
            die $@ if $@ !~ /__COLLECTOR_TIMEOUT__/;
            $timed_out = 1;
            return 124;
        }
        alarm(0);
        return $ok;
    };
    alarm(0);
    chdir $old or die "Unable to restore cwd to $old: $!";
    return ( $stdout, $stderr, $exit_code, $timed_out );
}

# _run_code(%args)
# Executes Perl collector code with captured stdout/stderr and timeout handling.
# Input: source code string, cwd path, env hash, and timeout_ms.
# Output: list of stdout, stderr, exit_code, and timed_out flag.
sub _run_code {
    my ( $self, %args ) = @_;
    my $code       = $args{source};
    my $cwd        = $args{cwd};
    my $env        = ref( $args{env} ) eq 'HASH' ? $args{env} : {};
    my $timeout_ms = $args{timeout_ms} || 30_000;

    my $old = cwd();
    chdir $cwd or die "Unable to chdir to $cwd: $!";
    local @ENV{ keys %$env } = values %$env if %$env;
    my $timed_out = 0;
    my ( $stdout, $stderr, $exit_code ) = capture {
        local $SIG{ALRM} = sub { die "__COLLECTOR_TIMEOUT__\n" };
        alarm( int( ( $timeout_ms + 999 ) / 1000 ) );
        my $result = eval $code;
        if ($@) {
            if ( $@ =~ /__COLLECTOR_TIMEOUT__/ ) {
                $timed_out = 1;
                alarm(0);
                return 124;
            }
            my $error = $@;
            print STDERR $error;
            alarm(0);
            return 255;
        }
        alarm(0);
        return ( defined $result && $result =~ /\A-?\d+\z/ ) ? $result : 0;
    };
    alarm(0);
    chdir $old or die "Unable to restore cwd to $old: $!";
    return ( $stdout, $stderr, $exit_code, $timed_out );
}

# _shutdown_loop($name)
# Persists shutdown state and exits a managed collector child.
# Input: collector name string.
# Output: never returns.
sub _shutdown_loop {
    my ( $self, $name, $status ) = @_;
    $self->_write_loop_state(
        $name,
        {
            pid          => $$,
            process_name => $self->_process_title($name),
            status       => $status || 'stopped',
            heartbeat_at => _now_iso8601(),
            stopped_at   => _now_iso8601(),
        }
    );
    $self->_cleanup_loop_files($name);
    exit 0;
}

# _signal_stop()
# Signal handler entrypoint for managed collector children.
# Input: none.
# Output: never returns when a managed runner is active.
sub _signal_stop {
    $SIGNAL_RUNNER->_shutdown_loop( $SIGNAL_LOOP_NAME, 'stopped' );
}

# _slurp($file)
# Reads the full contents of a file.
# Input: file path string.
# Output: file content string.
sub _slurp {
    my ($file) = @_;
    open my $fh, '<', $file or die "Unable to read $file: $!";
    local $/;
    return <$fh>;
}

# _now_iso8601()
# Returns the current UTC timestamp in ISO-8601 form.
# Input: none.
# Output: timestamp string.
sub _now_iso8601 {
    my @t = gmtime();
    return strftime( '%Y-%m-%dT%H:%M:%SZ', @t );
}

1;

__END__

=head1 NAME

Developer::Dashboard::CollectorRunner - collector execution and loop management

=head1 SYNOPSIS

  my $runner = Developer::Dashboard::CollectorRunner->new(...);
  my $result = $runner->run_once($job);

=head1 DESCRIPTION

This module runs collector jobs on demand and as managed background loops. It
handles scheduling, timeout enforcement, process naming, persisted loop
state, shell-command collectors, and Perl-code collectors.

=head1 METHODS

=head2 new, run_once, start_loop, stop_loop, running_loops, loop_state

Construct and manage collector execution.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module manages live collector execution. It turns stored collector jobs into processes, captures their output, updates collector state files, tracks pid ownership, and exposes the start/stop/restart/run/status lifecycle used by the CLI and web-facing status features.

=head1 WHY IT EXISTS

It exists because collector process control is more than a single C<system()> call. The dashboard needs a single owner for pid validation, output capture, environment preparation, enabled/disabled state, and restart behavior so the prompt and browser status strip can trust the result.

=head1 WHEN TO USE

Use this file when changing collector process spawning, pid validation, restart semantics, background job cleanup, or the contract between collector execution and the persisted collector state.

=head1 HOW TO USE

Construct it with the path registry and collector store, then call the lifecycle methods for one collector name. Keep process-management behavior here; the CLI wrappers should only parse arguments and print the returned state.

=head1 WHAT USES IT

It is used by the C<dashboard collector ...> command family, by runtime restart/stop flows that manage collectors together with the web process, and by collector/runtimemanager regression tests.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::CollectorRunner -e 1

Do a direct compile-and-load check against the module from a source checkout.

Example 2:

  prove -lv t/02-indicator-collector.t

Run the focused regression tests that most directly exercise this module's behavior.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite before release.


=for comment FULL-POD-DOC END

=cut
