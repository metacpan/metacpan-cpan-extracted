package Developer::Dashboard::RuntimeManager;

use strict;
use warnings;

our $VERSION = '4.16';

use Capture::Tiny qw(capture);
use File::Spec;
use IO::Socket::INET;
use POSIX qw(close setsid strftime);
use Time::HiRes qw(sleep time);

use Developer::Dashboard::Collector;
use Developer::Dashboard::CollectorRunner ();
use Developer::Dashboard::InternalCLI ();
use Developer::Dashboard::JSON qw(json_encode json_decode);
use Developer::Dashboard::Platform qw(command_in_path is_windows);

our $SIGNAL_MANAGER;
our $COLLECTOR_SUPERVISOR_MANAGER;

# new(%args)
# Constructs the runtime lifecycle manager.
# Input: config, files, paths, runner, and app_builder objects/callbacks.
# Output: Developer::Dashboard::RuntimeManager object.
sub new {
    my ( $class, %args ) = @_;
    my $config      = $args{config}      || die 'Missing config';
    my $files       = $args{files}       || die 'Missing file registry';
    my $paths       = $args{paths}       || die 'Missing path registry';
    my $runner      = $args{runner}      || die 'Missing collector runner';
    my $app_builder = $args{app_builder} || die 'Missing app builder';

    return bless {
        app_builder => $app_builder,
        collectors  => $args{collectors} || Developer::Dashboard::Collector->new( paths => $paths ),
        config      => $config,
        files       => $files,
        paths       => $paths,
        runner      => $runner,
    }, $class;
}

# start_web(%args)
# Starts the dashboard web service in foreground or background mode.
# Input: host, port, worker count, ssl flag, and foreground options.
# Output: server return value in foreground mode or child pid in background mode.
sub start_web {
    my ( $self, %args ) = @_;
    my $host = '0.0.0.0';
    if ( defined $args{host} ) {
        $host = $args{host};
    }
    my $port = 7890;
    if ( defined $args{port} ) {
        $port = $args{port};
    }
    my $workers = 1;
    if ( defined $args{workers} ) {
        $workers = $args{workers};
    }
    my $ssl = $args{ssl} ? 1 : 0;
    die 'Worker count must be a positive integer' if $workers !~ /^\d+$/ || $workers < 1;
    my $foreground = $args{foreground} ? 1 : 0;

    if ($foreground) {
        $self->_close_inherited_fds( preserve_harness => 1 );
        my $server = $self->{app_builder}->( host => $host, port => $port, workers => $workers, ssl => $ssl );
        return $server->run;
    }

    my $running = $self->running_web;
    return $running->{pid}
      if $running
      && $running->{host} eq $host
      && $running->{port} == $port
      && ( ( $running->{workers} || 1 ) == $workers )
      && ( ( $running->{ssl} || 0 ) == $ssl );

    if (is_windows()) {
        return $self->_start_web_windows_background(
            host    => $host,
            port    => $port,
            workers => $workers,
            ssl     => $ssl,
        );
    }

    $self->_cleanup_web_files;

    pipe my $reader, my $writer or die "Unable to create startup pipe: $!";
    my $pid = $self->_fork_process();
    die "Unable to fork dashboard web service: $!" if !defined $pid;

    if ($pid) {
        close $writer;
        my $line = <$reader>;
        close $reader;
        $self->_reap_child_process($pid);
        die "Unable to start dashboard web service\n" if !defined $line;
        chomp $line;
        die "$line\n" if $line =~ /^err:/;
        my ( undef, $started_pid, $bound_host, $bound_port ) = split /\|/, $line, 4;
        $started_pid = $self->_normalized_process_id($started_pid);
        my $state = {
            host         => $host,
            pid          => $started_pid,
            port         => $bound_port + 0,
            process_name => $self->_web_process_title( $host, $port ),
            started_at   => _now_iso8601(),
            status       => 'running',
            bound_host   => $bound_host,
            workers      => $workers + 0,
            ssl          => $ssl + 0,
        };
        $self->{files}->write( 'web_pid', "$started_pid\n" );
        $self->_write_web_state($state);
        return $started_pid;
    }

    close $reader;
    POSIX::_exit( $self->_run_web_child( $writer, $host, $port, workers => $workers, ssl => $ssl ) );
}

# _start_web_windows_background(%args)
# Launches the Windows web listener in a fresh detached serve process instead
# of pseudo-forking the active lifecycle helper.
# Input: host, port, worker count, and ssl flag.
# Output: detached serve pid integer after the listener is confirmed ready.
sub _start_web_windows_background {
    my ( $self, %args ) = @_;
    my $host = defined $args{host} ? $args{host} : '0.0.0.0';
    my $port = defined $args{port} ? $args{port} : 7890;
    my $workers = defined $args{workers} ? $args{workers} : 1;
    my $ssl = $args{ssl} ? 1 : 0;

    $self->_cleanup_web_files;

    my @command = $self->_windows_background_web_command(
        host    => $host,
        port    => $port,
        workers => $workers,
        ssl     => $ssl,
    );
    my $pid = $self->_spawn_windows_background_command(@command);
    die "Unable to start dashboard web service on Windows\n" if !$pid;

    my $running;
    for ( 1 .. $self->_runtime_stability_polls ) {
        my @listener_pids = $self->_listener_pids_for_port($port);
        if (@listener_pids) {
            my $listener_pid = $listener_pids[0];
            $running = {
                host         => $host,
                pid          => $listener_pid,
                port         => $port + 0,
                process_name => $self->_web_process_title( $host, $port ),
                started_at   => _now_iso8601(),
                status       => 'running',
                workers      => $workers + 0,
                ssl          => $ssl + 0,
            };
            last if $self->_port_accepting_connections($port);
        }
        sleep $self->_runtime_poll_interval;
    }

    if ($running) {
        my $state = {
            %{$running},
            host         => $host,
            pid          => $running->{pid} || $pid,
            port         => $port + 0,
            process_name => $running->{process_name} || $running->{args} || $self->_web_process_title( $host, $port ),
            started_at   => $running->{started_at} || _now_iso8601(),
            status       => 'running',
            workers      => $workers + 0,
            ssl          => $ssl + 0,
        };
        $self->{files}->write( 'web_pid', "$state->{pid}\n" );
        $self->_write_web_state($state);
        return $state->{pid};
    }

    return $pid;
}

# running_web()
# Discovers the currently running managed web service if present.
# Input: none.
# Output: web state hash reference or undef.
sub running_web {
    my ($self) = @_;

    my $state = $self->web_state || {};
    if ( my $pid = $self->{files}->read('web_pid') ) {
        chomp $pid;
        $pid = $self->_normalized_process_id($pid);
        if ( $pid && $self->_pid_is_running($pid) && $self->_same_pid_namespace($pid) ) {
            if ( $self->_is_managed_web($pid) || ( $state->{status} || '' ) eq 'running' ) {
                return {
                    %$state,
                    pid => $pid + 0,
                };
            }
        }
    }

    for my $proc ( $self->_find_web_processes ) {
        if ( $proc->{args} =~ /^dashboard web:\s+(\S+):(\d+)$/ ) {
            return {
                %$state,
                pid          => $proc->{pid},
                host         => $1,
                port         => $2 + 0,
                process_name => $proc->{args},
                status       => 'running',
            };
        }

        return {
            %$state,
            pid          => $proc->{pid},
            host         => $state->{host} || '0.0.0.0',
            port         => $state->{port} || 7890,
            process_name => $proc->{args},
            status       => 'running',
        };
    }

    if ( ( $state->{status} || '' ) eq 'running' ) {
        my @listener_pids = $self->_listener_pids_from_state($state);
        if (@listener_pids) {
            return {
                %$state,
                pid          => $listener_pids[0],
                process_name => $self->_read_process_title( $listener_pids[0] ) || ( $state->{process_name} || '' ),
                status       => 'running',
            };
        }
    }

    $self->_cleanup_web_files;
    return;
}

# stop_web()
# Stops the managed web service, including older compatible process shapes.
# Input: none.
# Output: stopped pid or undef.
sub stop_web {
    my ( $self, %args ) = @_;
    my $progress = $args{progress};
    $self->_progress_emit(
        $progress,
        {
            task_id => 'stop_web',
            status  => 'running',
            label   => 'Stop dashboard web service',
        }
    );
    my $saved_state = $self->web_state || {};
    my $running = $self->running_web;
    my $state = $running ? { %{$saved_state}, %{$running} } : $saved_state;
    my $pid = $saved_state->{pid};
    $pid = $running->{pid} if !defined $pid && $running;
    my $port = $state->{port};
    my @listener_pids = $self->_listener_pids_from_state($state);
    if ( !$pid && @listener_pids == 1 ) {
        $pid = $listener_pids[0];
    }

    if (is_windows()) {
        $self->_send_signal( 'TERM', $pid ) if $pid;
        $self->_send_signal( 'TERM', @listener_pids );
        for ( 1 .. 30 ) {
            last if !$self->_wait_for_windows_web_shutdown( $pid, $port, \@listener_pids );
            sleep 0.1;
        }
        my @still_listening = grep { kill 0, $_ } @listener_pids;
        $self->_send_signal( 'KILL', $pid ) if $pid && kill 0, $pid;
        $self->_send_signal( 'KILL', @still_listening );
        if ( $port && !$self->_wait_for_port_release($port) ) {
            my @late_listeners = grep { kill 0, $_ } $self->_listener_pids_for_port($port);
            $self->_send_signal( 'KILL', @late_listeners );
            $self->_wait_for_port_release($port);
        }
        $self->_cleanup_web_files;
        $self->_progress_emit(
            $progress,
            {
                task_id => 'stop_web',
                status  => 'done',
                label   => 'Stop dashboard web service',
            }
        );
        return _numeric_pid($pid);
    }

    $self->_send_signal( 'TERM', $pid ) if $pid;
    $self->_send_signal( 'TERM', @listener_pids );
    $self->_pkill_perl('^dashboard web:');
    my @ajax_workers = $self->_managed_ajax_processes;
    my @ajax_worker_pids = map { $_->{pid} } @ajax_workers;
    $self->_send_signal( 'TERM', @ajax_worker_pids );
    my @legacy_web_pids = map { $_->{pid} } $self->_find_legacy_web_processes;
    $self->_send_signal( 'TERM', @legacy_web_pids );
    my $watch_ajax_workers = @ajax_worker_pids ? 1 : 0;
    for ( 1 .. 5 ) {
        if ($watch_ajax_workers) {
            @ajax_workers = $self->_managed_ajax_processes;
            @ajax_worker_pids = map { $_->{pid} } @ajax_workers;
        }
        last if !$self->_wait_for_unix_web_shutdown(
            pid           => $pid,
            listener_pids => \@listener_pids,
            ajax_pids     => \@ajax_worker_pids,
            legacy_pids   => \@legacy_web_pids,
        );
        sleep $self->_runtime_poll_interval;
    }

    if ( $pid && $self->_pid_is_running($pid) ) {
        $self->_send_signal( 'KILL', $pid );
    }
    $self->_send_signal( 'KILL', @ajax_worker_pids );
    my @still_listening = grep { kill 0, $_ } @listener_pids;
    $self->_send_signal( 'KILL', @still_listening );
    $self->_send_signal( 'KILL', grep { $self->_pid_is_running($_) } @legacy_web_pids );
    sleep $self->_runtime_poll_interval;
    my $released = $self->_wait_for_port_release($port);
    if ( !$released && $port ) {
        my @late_listeners = grep { kill 0, $_ } $self->_listener_pids_for_port($port);
        $self->_send_signal( 'KILL', @late_listeners );
        $self->_reap_child_processes(@late_listeners);
        $self->_wait_for_port_release($port);
    }
    $self->_reap_child_processes( $pid, @listener_pids, @legacy_web_pids, @ajax_worker_pids );

    $self->_cleanup_web_files;
    $self->_progress_emit(
        $progress,
        {
            task_id => 'stop_web',
            status  => 'done',
            label   => 'Stop dashboard web service',
        }
    );
    return _numeric_pid($pid);
}

# _wait_for_unix_web_shutdown(%args)
# Checks whether Unix web shutdown still has managed web, ajax worker, legacy
# serve, or listener processes alive before escalation to KILL.
# Input: optional pid integer plus array references for listener_pids,
# ajax_pids, and legacy_pids.
# Output: boolean true when shutdown work is still pending.
sub _wait_for_unix_web_shutdown {
    my ( $self, %args ) = @_;
    my $pid = $args{pid};
    my @listener_pids = @{ $args{listener_pids} || [] };
    my @ajax_pids     = @{ $args{ajax_pids}     || [] };
    my @legacy_pids   = @{ $args{legacy_pids}   || [] };

    return 1 if defined $pid && $pid =~ /^\d+$/ && $pid > 0 && $self->_pid_is_running($pid);
    return 1 if grep { defined $_ && $self->_pid_is_running($_) } @ajax_pids;
    return 1 if grep { defined $_ && $self->_pid_is_running($_) } @legacy_pids;
    return 1 if grep { defined $_ && /^\d+$/ && kill 0, $_ } @listener_pids;
    return 0;
}

# _managed_ajax_processes()
# Returns dashboard Ajax singleton workers that belong to the current runtime so
# web stop and restart actions do not interfere with unrelated dashboard Ajax
# processes owned by the same user.
# Input: none.
# Output: list of ajax process hash references for the active runtime root.
sub _managed_ajax_processes {
    my ($self) = @_;
    my $runtime_root = $self->{paths} ? $self->{paths}->state_root : '';
    my @matches;
    for my $proc ( $self->_find_processes_by_prefix('dashboard ajax:') ) {
        my $marker = $self->_read_process_env_marker( $proc->{pid}, 'DEVELOPER_DASHBOARD_RUNTIME_ROOT' );
        next if defined $marker && $marker ne '' && $marker ne $runtime_root;
        next if defined $marker && $marker eq '' && $runtime_root ne '';
        next if !defined $marker && $self->_procfs_available && $runtime_root ne '';
        push @matches, $proc;
    }
    return @matches;
}

# _numeric_pid($pid)
# Normalizes persisted pid values back to numeric scalars for lifecycle JSON
# output while preserving undef when no process id is available.
# Input: optional pid scalar.
# Output: numeric pid scalar or undef.
sub _numeric_pid {
    my ($pid) = @_;
    return undef if !defined $pid || $pid eq '';
    return $pid =~ /^\d+$/ ? $pid + 0 : $pid;
}

# _reap_child_process($pid)
# Reaps one direct runtime child when it has already exited so background
# lifecycle helpers do not accumulate zombie processes.
# Input: process id integer.
# Output: boolean true when waitpid reaped the child.
sub _reap_child_process {
    my ( $self, $pid ) = @_;
    return 0 if !defined $pid || $pid !~ /^\d+$/ || $pid < 1;
    my $waited = waitpid( $pid, 1 );
    return $waited == $pid ? 1 : 0;
}

# _pid_is_running($pid)
# Determines whether one runtime-managed pid is still alive after opportunistic
# child reaping.
# Input: process id integer.
# Output: boolean true when the process is still running.
sub _pid_is_running {
    my ( $self, $pid ) = @_;
    return 0 if !defined $pid || $pid !~ /^\d+$/ || $pid < 1;
    return 0 if $self->_reap_child_process($pid);
    return 0 if ( $self->_read_process_state($pid) || '' ) eq 'Z';
    return $self->_process_exists($pid) ? 1 : 0;
}

# _reap_child_processes(@pids)
# Reaps every direct child in one pid list when those children have already
# exited.
# Input: list of process id integers.
# Output: number of child processes reaped.
sub _reap_child_processes {
    my ( $self, @pids ) = @_;
    my $count = 0;
    for my $pid (@pids) {
        $count++ if $self->_reap_child_process($pid);
    }
    return $count;
}

# _wait_for_any_child_process($flags)
# Wraps waitpid for any direct child so the watchdog supervisor can reap exited
# adopted children without depending on implicit process cleanup.
# Input: waitpid flag integer such as WNOHANG.
# Output: reaped pid integer, zero when nothing is ready, or -1 when no child
# remains.
sub _wait_for_any_child_process {
    my ( $self, $flags ) = @_;
    return waitpid( -1, $flags );
}

# _reap_any_child_processes()
# Reaps every direct child that has already exited so long-lived runtime helper
# processes such as the collector watchdog do not accumulate zombies when they
# become the parent of dashboard-managed subprocesses.
# Input: none.
# Output: number of child processes reaped.
sub _reap_any_child_processes {
    my ($self) = @_;
    my $count = 0;
    while (1) {
        my $reaped = $self->_wait_for_any_child_process(1);
        last if !defined $reaped || $reaped <= 0;
        $count++;
    }
    return $count;
}

# _wait_for_windows_web_shutdown($pid, $port, $listener_pids)
# Checks whether the Windows-managed web process and its listener port have
# both gone away after shutdown signals were sent.
# Input: optional saved pid, optional listen port, and array reference of
# listener pids discovered from persisted state.
# Output: boolean true while the web runtime still appears alive.
sub _wait_for_windows_web_shutdown {
    my ( $self, $pid, $port, $listener_pids ) = @_;
    my @listener_pids = ref($listener_pids) eq 'ARRAY' ? @{$listener_pids} : ();
    return 1 if $pid && kill 0, $pid;
    return 1 if grep { kill 0, $_ } @listener_pids;
    return 1 if $port && scalar $self->_listener_pids_for_port($port);
    return 0;
}

# start_collectors()
# Starts configured non-manual collectors in the background.
# Input: none.
# Output: list of started collector hashes.
sub start_collectors {
    my ( $self, %args ) = @_;
    my $progress = $args{progress};
    my %wanted = map { $_ => 1 } @{ $args{names} || [] };
    my @jobs = @{ $self->{config}->collectors };
    $self->_stop_disabled_collectors( jobs => \@jobs, progress => $progress, wanted => \%wanted );
    my @started;
    for my $job (@jobs) {
        next if ref($job) ne 'HASH';
        my $schedule = $job->{schedule} || ( $job->{cron} ? 'cron' : $job->{interval} ? 'interval' : 'manual' );
        my $name = $job->{name} || '(unnamed)';
        if (%wanted) {
            next if !$wanted{$name};
        }
        else {
            next if $schedule eq 'manual';
        }
        next if $self->_collector_disabled($job);
        $self->_progress_emit(
            $progress,
            {
                task_id => "start_collector:$name",
                status  => 'running',
                label   => "Start collector $name",
            }
        );
        my $pid = eval { $self->{runner}->start_loop($job) };
        if ($@) {
            my $error = $@;
            chomp $error;
            for my $started (@started) {
                eval { $self->{runner}->stop_loop( $started->{name} ) };
            }
            $self->_progress_emit(
                $progress,
                {
                    task_id => "start_collector:$name",
                    status  => 'failed',
                    label   => "Start collector $name",
                }
            );
            die "Failed to start collector '$name': $error\n";
        }
        if ( defined $pid && !$self->_collector_runtime_ready( $job->{name}, $pid ) ) {
            for my $started (@started) {
                eval { $self->{runner}->stop_loop( $started->{name} ) };
            }
            eval { $self->{runner}->stop_loop( $job->{name} ) };
            $self->_progress_emit(
                $progress,
                {
                    task_id => "start_collector:$name",
                    status  => 'failed',
                    label   => "Start collector $name",
                }
            );
            die "Failed to keep collector '$name' running after startup\n";
        }
        $self->_progress_emit(
            $progress,
            {
                task_id => "start_collector:$name",
                status  => 'done',
                label   => "Start collector $name",
            }
        );
        push @started, { name => $job->{name}, pid => $pid } if defined $pid;
    }
    $self->_merge_collector_supervisor_targets( [ map { $_->{name} } @started ] ) if @started;
    return @started;
}

# start_named_collector(%args)
# Starts one named collector loop, including on-demand manual collectors.
# Input: collector name string and optional progress callback.
# Output: hash reference with collector name and started pid.
sub start_named_collector {
    my ( $self, %args ) = @_;
    my $name = $args{name} || die "Missing collector name\n";
    my $job = $self->_collector_job_by_name($name);
    if ( $self->_collector_disabled($job) ) {
        $self->stop_collectors(
            names    => [$name],
            progress => $args{progress},
        );
        die "Collector '$name' is disabled\n";
    }
    my $loop_job = $self->_loop_job_for_named_start($job);
    my $progress = $args{progress};
    $self->_progress_emit(
        $progress,
        {
            task_id => "start_collector:$name",
            status  => 'running',
            label   => "Start collector $name",
        }
    );
    my $pid = eval { $self->{runner}->start_loop($loop_job) };
    if ($@) {
        my $error = $@;
        chomp $error;
        $self->_progress_emit(
            $progress,
            {
                task_id => "start_collector:$name",
                status  => 'failed',
                label   => "Start collector $name",
            }
        );
        die "Failed to start collector '$name': $error\n";
    }
    if ( defined $pid && !$self->_collector_runtime_ready( $name, $pid ) ) {
        eval { $self->{runner}->stop_loop($name) };
        $self->_progress_emit(
            $progress,
            {
                task_id => "start_collector:$name",
                status  => 'failed',
                label   => "Start collector $name",
            }
        );
        die "Failed to keep collector '$name' running after startup\n";
    }
    $self->_progress_emit(
        $progress,
        {
            task_id => "start_collector:$name",
            status  => 'done',
            label   => "Start collector $name",
        }
    );
    $self->_merge_collector_supervisor_targets( [$name] );
    return {
        name => $name,
        pid  => $pid,
    };
}

# serve_all(%args)
# Starts the web service and ensures configured collector loops follow the same
# lifecycle action.
# Input: host, port, worker count, ssl flag, and foreground options.
# Output: hash reference describing the started web pid/result and collector actions.
sub serve_all {
    my ( $self, %args ) = @_;
    my $host = '0.0.0.0';
    $host = $args{host} if defined $args{host};
    my $port = 7890;
    $port = $args{port} if defined $args{port};
    my $workers = 1;
    $workers = $args{workers} if defined $args{workers};
    my $ssl = $args{ssl} ? 1 : 0;
    my $foreground = $args{foreground} ? 1 : 0;

    if ($foreground) {
        my @collectors = $self->start_collectors( progress => $args{progress} );
        my $result = eval {
            $self->start_web(
                foreground => 1,
                host       => $host,
                port       => $port,
                workers    => $workers,
                ssl        => $ssl,
            );
        };
        my $error = $@;
        my @stopped_collectors = $self->stop_collectors;
        die $error if $error;
        return {
            foreground         => 1,
            host               => $host,
            port               => $port,
            workers            => $workers,
            ssl                => $ssl,
            collectors         => \@collectors,
            stopped_collectors => \@stopped_collectors,
            result             => $result,
        };
    }

    my $pid = $self->_restart_web_with_retry(
        host     => $host,
        port     => $port,
        workers  => $workers,
        ssl      => $ssl,
    );
    my @collectors = $self->start_collectors;
    return {
        host       => $host,
        port       => $port,
        workers    => $workers,
        ssl        => $ssl,
        pid        => $pid,
        collectors => \@collectors,
    };
}

# stop_collectors()
# Stops all managed collector loops.
# Input: none.
# Output: list of stopped collector name strings.
sub stop_collectors {
    my ( $self, %args ) = @_;
    my $progress = $args{progress};
    my %wanted = map { $_ => 1 } @{ $args{names} || [] };
    my @targets = $self->_collector_stop_targets( \%wanted );
    my @names = map { $_->{name} } @targets;
    if (%wanted) {
        $self->_remove_collector_supervisor_targets( \@names );
    }
    else {
        $self->_stop_collector_supervisor;
    }
    my @stopped;
    for my $loop (@targets) {
        my $name = $loop->{name};
        $self->_progress_emit(
            $progress,
            {
                task_id => "stop_collector:$name",
                status  => 'running',
                label   => "Stop collector $name",
            }
        );
        my $pid = eval { $self->{runner}->stop_loop($name) };
        if ($@) {
            my $error = $@;
            chomp $error;
            $self->_progress_emit(
                $progress,
                {
                    task_id => "stop_collector:$name",
                    status  => 'failed',
                    label   => "Stop collector $name",
                }
            );
            die "Failed to stop collector '$name': $error\n";
        }
        $self->_ensure_collector_pid_stopped( $name, $loop->{pid} );
        $self->_progress_emit(
            $progress,
            {
                task_id => "stop_collector:$name",
                status  => 'done',
                label   => "Stop collector $name",
            }
        );
        push @stopped, {
            name   => $name,
            pid    => $pid,
            status => 'stopped',
        };
    }
    return @stopped if $args{structured};
    return @names;
}

# _ensure_collector_pid_stopped($name, $pid)
# Forces one targeted collector pid fully down after the runner has performed its
# own stop work so restart flows cannot get stuck behind a loop that survived
# state cleanup.
# Input: collector name string and optional collector pid integer.
# Output: true when no live collector pid remains for that target.
sub _ensure_collector_pid_stopped {
    my ( $self, $name, $pid ) = @_;
    return 1 if !defined $pid || $pid !~ /^\d+$/ || $pid < 1;
    return 1 if !$self->_same_pid_namespace($pid);
    return 1 if !$self->_pid_is_running($pid);

    $self->_send_signal( 'TERM', $pid );
    for ( 1 .. 20 ) {
        last if !$self->_pid_is_running($pid);
        sleep 0.1;
    }

    if ( $self->_pid_is_running($pid) ) {
        $self->_send_signal( 'KILL', $pid );
        for ( 1 .. 20 ) {
            last if !$self->_pid_is_running($pid);
            sleep 0.1;
        }
    }

    $self->_reap_child_process($pid);
    die "Collector '$name' did not stop after TERM and KILL\n" if $self->_pid_is_running($pid);
    return 1;
}

# _collector_supervisor_targets_without($names)
# Returns the current watchdog target set after removing one explicit list of
# collector names so targeted lifecycle commands can pause supervision without
# losing the remaining watched fleet.
# Input: array reference of collector names to remove.
# Output: ordered list of remaining watched collector names.
sub _collector_supervisor_targets_without {
    my ( $self, $names ) = @_;
    my %remove = map { $_ => 1 } $self->_normalized_collector_watch_names($names);
    my $state = $self->_collector_supervisor_state || {};
    return grep { !$remove{$_} } @{ $state->{watched_names} || [] };
}

# _collector_stop_targets($wanted)
# Resolves the collector loops that a stop request should target, including
# state-backed fallbacks when process-title discovery has not caught up yet.
# Input: hash reference of wanted collector names, or an empty hash for "all".
# Output: ordered list of collector loop hash references.
sub _collector_stop_targets {
    my ( $self, $wanted ) = @_;
    $wanted ||= {};
    my %wanted = %{$wanted};
    my @running = $self->{runner}->running_loops;
    my @targets = grep {
        my $name = $_->{name};
        $name && ( !%wanted || $wanted{$name} );
    } @running;
    my %present = map { $_->{name} => 1 } @targets;

    for my $name ( $self->_collector_stop_fallback_names( \%wanted ) ) {
        next if $present{$name}++;
        next if !$self->{runner}->can('loop_state');
        my $state = eval { $self->{runner}->loop_state($name) };
        $state = {} if !$state || ref($state) ne 'HASH';
        my $pidfile = File::Spec->catfile( $self->{paths}->collectors_root, "$name.pid" );
        my $pid = $state->{pid};
        if ( -f $pidfile ) {
            open my $fh, '<', $pidfile or die "Unable to read $pidfile: $!";
            my $pid_text = <$fh>;
            close $fh;
            chomp $pid_text if defined $pid_text;
            $pid = $pid_text if defined $pid_text && $pid_text =~ /^\d+$/;
            push @targets, {
                name  => $name,
                pid   => $pid,
                state => $state,
            };
            next;
        }
        next if !defined $pid || $pid !~ /^\d+$/ || $pid < 1 || !kill 0, $pid;
        next if ( $state->{name} || '' ) ne $name;
        next if ( $state->{status} || '' ) !~ /^(?:starting|running|error)$/;
        push @targets, {
            name  => $name,
            pid   => $pid,
            state => $state,
        };
    }

    @targets = sort { ( $a->{name} || '' ) cmp ( $b->{name} || '' ) } @targets;
    return @targets;
}

# _collector_stop_fallback_names($wanted)
# Enumerates collector names whose persisted loop state should be checked when
# process-title discovery misses a live collector loop.
# Input: hash reference of wanted collector names, or an empty hash for "all".
# Output: ordered list of collector name strings.
sub _collector_stop_fallback_names {
    my ( $self, $wanted ) = @_;
    $wanted ||= {};
    return sort keys %{$wanted} if %{$wanted};
    return () if !$self->{runner}->can('loop_state');

    my %seen;
    my @names;
    for my $job ( @{ $self->{config}->collectors || [] } ) {
        my $name = ref($job) eq 'HASH' ? ( $job->{name} || '' ) : '';
        next if $name eq '' || $seen{$name}++;
        push @names, $name;
    }

    my $collectors_root = eval { $self->{paths}->collectors_root };
    if ( defined $collectors_root && $collectors_root ne '' && -d $collectors_root ) {
        opendir( my $dh, $collectors_root ) or die "Unable to read $collectors_root: $!";
        for my $entry ( sort grep { $_ ne '.' && $_ ne '..' && /\.pid\z/ } readdir($dh) ) {
            my ($name) = $entry =~ /\A(.*)\.pid\z/;
            next if !defined $name || $name eq '' || $seen{$name}++;
            push @names, $name;
        }
        closedir($dh);
    }

    return @names;
}

# stop_all()
# Stops the web service and all managed collectors.
# Input: none.
# Output: hash reference describing stopped processes.
sub stop_all {
    my ( $self, %args ) = @_;
    return {
        web_pid   => $self->stop_web( progress => $args{progress} ),
        collectors => [ $self->stop_collectors( progress => $args{progress} ) ],
    };
}

# restart_all(%args)
# Restarts collectors and the web service together.
# Input: host, port, worker-count, and ssl options.
# Output: hash reference describing stopped and restarted processes.
sub restart_all {
    my ( $self, %args ) = @_;
    my $host = '0.0.0.0';
    if ( defined $args{host} ) {
        $host = $args{host};
    }
    my $port = 7890;
    if ( defined $args{port} ) {
        $port = $args{port};
    }
    my $workers = 1;
    if ( defined $args{workers} ) {
        $workers = $args{workers};
    }
    my $ssl = $args{ssl} ? 1 : 0;
    my %progress_args = defined $args{progress} ? ( progress => $args{progress} ) : ();
    my $stopped = $self->stop_all(%progress_args);
    my @collectors = $self->start_collectors(%progress_args);
    my $web_pid = $self->_restart_web_with_retry(
        host     => $host,
        port     => $port,
        workers  => $workers,
        ssl      => $ssl,
        %progress_args,
    );
    return {
        stopped   => $stopped,
        collectors => \@collectors,
        web_pid   => $web_pid,
    };
}

# stop_target(%args)
# Stops the requested runtime scope: all, web, all collectors, or one named collector.
# Input: scope string, optional collector name, and optional progress callback.
# Output: hash reference describing the stopped runtime entities.
sub stop_target {
    my ( $self, %args ) = @_;
    my $scope = $args{scope} || 'all';
    my %result = (
        action     => 'stop',
        scope      => $scope,
        target     => defined $args{name} && $args{name} ne '' ? $args{name} : ( $scope eq 'collector' ? 'all' : 'dashboard' ),
        collectors => [],
    );

    if ( $scope eq 'web' ) {
        my $pid = $self->stop_web( progress => $args{progress} );
        $result{web_pid} = $pid;
        $result{web} = {
            pid     => $pid,
            status  => 'stopped',
            details => 'dashboard web service',
        };
        return \%result;
    }

    if ( $scope eq 'collector' ) {
        my @names = defined $args{name} && $args{name} ne '' ? ( $args{name} ) : ();
        my @collectors = $self->stop_collectors(
            progress   => $args{progress},
            ( @names ? ( names => \@names ) : () ),
            structured => 1,
        );
        if ( !@collectors ) {
            @collectors = (
                {
                    name    => @names ? $names[0] : 'all',
                    status  => 'not running',
                    details => 'no running collectors',
                }
            );
        }
        $result{collectors} = \@collectors;
        return \%result;
    }

    my $stopped = $self->stop_all( progress => $args{progress} );
    $result{web_pid} = $stopped->{web_pid};
    $result{web} = {
        pid     => $stopped->{web_pid},
        status  => 'stopped',
        details => 'dashboard web service',
    };
    $result{collectors} = [
        map {
            {
                name   => $_,
                status => 'stopped',
            }
        } @{ $stopped->{collectors} || [] }
      ];
    return \%result;
}

# restart_target(%args)
# Restarts the requested runtime scope: all, web, all collectors, or one named collector.
# Input: scope string, optional collector name, host, port, workers, ssl, and optional progress callback.
# Output: hash reference describing the restarted runtime entities.
sub restart_target {
    my ( $self, %args ) = @_;
    my $scope = $args{scope} || 'all';
    my $host = defined $args{host} ? $args{host} : '0.0.0.0';
    my $port = defined $args{port} ? $args{port} : 7890;
    my $workers = defined $args{workers} ? $args{workers} : 1;
    my $ssl = $args{ssl} ? 1 : 0;

    my %result = (
        action     => 'restart',
        scope      => $scope,
        target     => defined $args{name} && $args{name} ne '' ? $args{name} : ( $scope eq 'collector' ? 'all' : 'dashboard' ),
        collectors => [],
    );

    if ( $scope eq 'web' ) {
        my $pid = $self->stop_web( progress => $args{progress} );
        my $web_pid = $self->_restart_web_with_retry(
            host     => $host,
            port     => $port,
            workers  => $workers,
            ssl      => $ssl,
            progress => $args{progress},
        );
        $result{stopped_web_pid} = $pid;
        $result{web_pid} = $web_pid;
        $result{web} = {
            pid     => $web_pid,
            status  => 'restarted',
            details => "$host:$port workers=$workers ssl=$ssl",
        };
        return \%result;
    }

    if ( $scope eq 'collector' ) {
        my @names = defined $args{name} && $args{name} ne '' ? ( $args{name} ) : ();
        my @stopped = $self->stop_collectors(
            progress   => $args{progress},
            ( @names ? ( names => \@names ) : () ),
            structured => 1,
        );
        my @started = @names
          ? ( $self->start_named_collector( name => $names[0], progress => $args{progress} ) )
          : $self->start_collectors(
            progress => $args{progress},
            ( @names ? ( names => \@names ) : () ),
          );
        my %stopped = map { $_->{name} => $_ } @stopped;
        $result{collectors} = [
            map {
                {
                    name   => $_->{name},
                    pid    => $_->{pid},
                    status => 'restarted',
                    details => defined $stopped{ $_->{name} } ? 'stopped then started' : 'started',
                }
            } @started
        ];
        return \%result;
    }

    my $restarted = $self->restart_all(
        host     => $host,
        port     => $port,
        workers  => $workers,
        ssl      => $ssl,
        progress => $args{progress},
    );
    $result{stopped} = $restarted->{stopped};
    $result{web_pid} = $restarted->{web_pid};
    $result{web} = {
        pid     => $restarted->{web_pid},
        status  => 'restarted',
        details => "$host:$port workers=$workers ssl=$ssl",
    };
    $result{collectors} = [
        map {
            {
                name   => $_->{name},
                pid    => $_->{pid},
                status => 'restarted',
                details => 'stopped then started',
            }
        } @{ $restarted->{collectors} || [] }
      ];
    return \%result;
}

# _collector_job_by_name($name)
# Finds one configured collector job by name.
# Input: collector name string.
# Output: collector job hash reference or dies when it is unknown.
sub _collector_job_by_name {
    my ( $self, $name ) = @_;
    die "Missing collector name\n" if !defined $name || $name eq '';
    for my $job ( @{ $self->{config}->collectors } ) {
        next if ref($job) ne 'HASH';
        next if ( $job->{name} || '' ) ne $name;
        return $job;
    }
    die "Unknown collector '$name'\n";
}

# _collector_disabled($job)
# Returns whether one collector job is explicitly disabled in config.
# Input: collector job hash reference.
# Output: boolean true when the collector should not be started.
sub _collector_disabled {
    my ( $self, $job ) = @_;
    return 0 if ref($job) ne 'HASH';
    return $job->{disable} ? 1 : 0;
}

# _stop_disabled_collectors(%args)
# Stops running collectors that are explicitly disabled in config before the
# startup loop continues with enabled jobs.
# Input: collector jobs array reference, optional progress callback, and
# optional wanted-name hash reference for scoped starts.
# Output: ordered list of disabled collector names that were targeted for stop.
sub _stop_disabled_collectors {
    my ( $self, %args ) = @_;
    my $jobs = $args{jobs};
    return () if ref($jobs) ne 'ARRAY';
    my $wanted = ref( $args{wanted} ) eq 'HASH' ? $args{wanted} : {};
    my %disabled;
    for my $job ( @{$jobs} ) {
        next if !$self->_collector_disabled($job);
        my $name = ref($job) eq 'HASH' ? ( $job->{name} || '' ) : '';
        next if $name eq '';
        next if %{$wanted} && !$wanted->{$name};
        $disabled{$name} = 1;
    }
    my @names = sort keys %disabled;
    return () if !@names;
    $self->stop_collectors(
        names    => \@names,
        progress => $args{progress},
    );
    return @names;
}

# _loop_job_for_named_start($job)
# Normalizes one collector job into a loopable schedule for explicit named starts.
# Input: collector job hash reference.
# Output: collector job hash reference ready for CollectorRunner::start_loop.
sub _loop_job_for_named_start {
    my ( $self, $job ) = @_;
    my %loop_job = %{$job || {}};
    my $schedule = $loop_job{schedule}
      || ( $loop_job{cron} ? 'cron' : $loop_job{interval} ? 'interval' : 'manual' );
    if ( $schedule eq 'manual' ) {
        $loop_job{interval} = 30 if !defined $loop_job{interval} || $loop_job{interval} !~ /^\d+$/ || $loop_job{interval} < 1;
        $loop_job{schedule} = 'interval';
    }
    return \%loop_job;
}

# _supervise_collectors_once(%args)
# Runs one watchdog pass across the requested collector names, restarting
# unexpectedly-dead loops until the restart threshold is exceeded.
# Input: names array reference.
# Output: hash reference with restarted and attention arrays.
sub _supervise_collectors_once {
    my ( $self, %args ) = @_;
    my @names = $self->_normalized_collector_watch_names( $args{names} );
    my %running = map { $_->{name} => $_ } $self->{runner}->running_loops;
    my %result = (
        restarted => [],
        attention => [],
    );

    for my $name (@names) {
        my $job = eval { $self->_collector_job_by_name($name) };
        if ( !$job ) {
            my $error = $@ || "Unknown collector '$name'\n";
            $self->_mark_collector_watchdog_attention(
                $name,
                $error,
                restart_count => 0,
            );
            push @{ $result{attention} }, { name => $name, reason => $error };
            next;
        }

        my $status = $self->{collectors}->read_status($name) || {};
        my $stalled = $running{$name}
          ? $self->_collector_stalled_for_watchdog( $job, $status )
          : 0;
        next if $running{$name} && !$stalled;

        my $stopped_stalled = 0;
        if ( $running{$name} ) {
            my $ok = eval { $self->{runner}->stop_loop($name); 1 };
            if ( !$ok ) {
                my $error = $@ || "Unable to stop stale collector '$name'\n";
                chomp $error;
                $self->_mark_collector_watchdog_attention(
                    $name,
                    $error,
                    restart_count => 0,
                );
                push @{ $result{attention} }, { name => $name, reason => $error };
                next;
            }
            $stopped_stalled = 1;
        }

        my ( $restart_count, $window_started_at, $window_started_epoch ) =
          $self->_collector_watchdog_window($status);
        my $observed_at_epoch = time;
        my $observed_at = _now_iso8601();
        $restart_count++;

        if ( $restart_count > $self->_collector_restart_limit ) {
            my $message = sprintf
              "Collector '%s' stopped unexpectedly too many times within %s seconds; manual investigation is required",
              $name, $self->_collector_restart_window_seconds;
            $self->_mark_collector_watchdog_attention(
                $name,
                $message,
                observed_at            => $observed_at,
                observed_at_epoch      => $observed_at_epoch,
                restart_count          => $restart_count,
                window_started_at      => $window_started_at,
                window_started_epoch   => $window_started_epoch,
            );
            push @{ $result{attention} }, { name => $name, reason => $message };
            next;
        }

        my $loop_job = $self->_loop_job_for_named_start($job);
        my $pid = eval { $self->{runner}->start_loop($loop_job) };
        my $start_error = $@;
        if ( !$start_error && defined $pid && !$self->_collector_runtime_ready( $name, $pid ) ) {
            eval { $self->{runner}->stop_loop($name) };
            $start_error = "Failed to keep collector '$name' running after watchdog restart\n";
        }

        if ($start_error) {
            chomp $start_error;
            $self->{collectors}->write_status(
                $name,
                {
                    running                              => 0,
                    watchdog_attention_required          => 0,
                    watchdog_last_error                  => $start_error,
                    watchdog_last_unexpected_stop_at     => $observed_at,
                    watchdog_last_unexpected_stop_at_epoch => $observed_at_epoch,
                    watchdog_restart_count               => $restart_count,
                    watchdog_restart_window_started_at   => $window_started_at,
                    watchdog_restart_window_started_at_epoch => $window_started_epoch,
                    watchdog_status                      => 'restart_failed',
                }
            );
            $self->_log_collector_watchdog_event( $name, $start_error );
            next;
        }

        $self->{collectors}->write_status(
            $name,
            {
                running                              => 1,
                watchdog_attention_required          => 0,
                watchdog_last_error                  => $stopped_stalled
                  ? sprintf(
                    "Collector '%s' stopped making progress and was restarted by the watchdog",
                    $name
                  )
                  : undef,
                watchdog_last_restart_at             => $observed_at,
                watchdog_last_restart_at_epoch       => $observed_at_epoch,
                watchdog_last_unexpected_stop_at     => $observed_at,
                watchdog_last_unexpected_stop_at_epoch => $observed_at_epoch,
                watchdog_restart_count               => $restart_count,
                watchdog_restart_window_started_at   => $window_started_at,
                watchdog_restart_window_started_at_epoch => $window_started_epoch,
                watchdog_status                      => 'running',
            }
        );
        $self->_log_collector_watchdog_event( $name, "Watchdog restarted collector '$name' (attempt $restart_count)" );
        push @{ $result{restarted} }, { name => $name, pid => $pid };
    }

    return \%result;
}

# _collector_stalled_for_watchdog($job, $status)
# Detects when a managed scheduled collector loop is alive but has stopped
# making progress long enough that the watchdog should recycle it.
# Input: collector job hash reference and collector status hash reference.
# Output: boolean true when the collector is stalled.
sub _collector_stalled_for_watchdog {
    my ( $self, $job, $status ) = @_;
    return 0 if ref($job) ne 'HASH';
    return 0 if ref($status) ne 'HASH';
    my $latest_epoch = $self->_collector_watchdog_last_progress_epoch($status);
    return 0 if !$latest_epoch;
    my $stale_after = $self->_collector_watchdog_stale_seconds($job);
    return 0 if $stale_after < 1;
    return time - $latest_epoch > $stale_after ? 1 : 0;
}

# _collector_watchdog_last_progress_epoch($status)
# Extracts the latest meaningful collector progress timestamp from persisted
# status fields so the watchdog can detect live-but-stalled collector loops.
# Input: collector status hash reference.
# Output: latest progress epoch integer or zero when no usable timestamp exists.
sub _collector_watchdog_last_progress_epoch {
    my ( $self, $status ) = @_;
    return 0 if ref($status) ne 'HASH';
    my @epochs;
    for my $field (qw(last_completed_at last_started_at last_run)) {
        my $timestamp = $status->{$field};
        next if !defined $timestamp || $timestamp eq '';
        my $epoch = eval { $self->{collectors}->_iso8601_to_epoch($timestamp) };
        next if !$epoch;
        push @epochs, $epoch;
    }
    return 0 if !@epochs;
    return ( sort { $b <=> $a } @epochs )[0];
}

# _collector_watchdog_stale_seconds($job)
# Builds the maximum no-progress window for a collector from its configured
# interval and timeout plus a small watchdog grace period.
# Input: collector job hash reference.
# Output: positive integer number of seconds.
sub _collector_watchdog_stale_seconds {
    my ( $self, $job ) = @_;
    $job ||= {};
    my $interval = Developer::Dashboard::CollectorRunner::_effective_interval_seconds(
        bless( {}, 'Developer::Dashboard::CollectorRunner' ),
        $job,
    );
    my $timeout = defined $job->{timeout_ms} && $job->{timeout_ms} =~ /^\d+$/ && $job->{timeout_ms} > 0
      ? ( $job->{timeout_ms} / 1000 )
      : defined $job->{timeout} && $job->{timeout} =~ /^(?:\d+|\d*\.\d+)$/ && $job->{timeout} > 0
      ? $job->{timeout}
      : 30;
    return int( $interval + $timeout + $self->_collector_stall_grace_seconds + 0.999999 );
}

# _collector_watchdog_window($status)
# Normalizes the collector watchdog restart window and counter from persisted
# collector status.
# Input: collector status hash reference.
# Output: restart count integer, window-start ISO-8601 string, and window-start epoch.
sub _collector_watchdog_window {
    my ( $self, $status ) = @_;
    $status ||= {};
    my $now_epoch = time;
    my $count = $status->{watchdog_restart_count} || 0;
    my $window_epoch = $status->{watchdog_restart_window_started_at_epoch};
    my $window_at = $status->{watchdog_restart_window_started_at};
    if ( !defined $window_epoch || $window_epoch !~ /^\d+(?:\.\d+)?$/ || ( $now_epoch - $window_epoch ) > $self->_collector_restart_window_seconds ) {
        $count = 0;
        $window_epoch = $now_epoch;
        $window_at = _now_iso8601();
    }
    return ( $count, $window_at, $window_epoch );
}

# _mark_collector_watchdog_attention($name, $message, %args)
# Persists the collector watchdog attention state and records an explicit log
# entry explaining why automatic restarts stopped.
# Input: collector name string, human-readable message, and optional timing/count fields.
# Output: true value.
sub _mark_collector_watchdog_attention {
    my ( $self, $name, $message, %args ) = @_;
    my $observed_at = $args{observed_at} || _now_iso8601();
    my $observed_at_epoch = defined $args{observed_at_epoch} ? $args{observed_at_epoch} : time;
    $self->{collectors}->write_status(
        $name,
        {
            running                              => 0,
            watchdog_attention_required          => 1,
            watchdog_last_error                  => $message,
            watchdog_last_unexpected_stop_at     => $observed_at,
            watchdog_last_unexpected_stop_at_epoch => $observed_at_epoch,
            watchdog_restart_count               => $args{restart_count},
            watchdog_restart_window_started_at   => $args{window_started_at},
            watchdog_restart_window_started_at_epoch => $args{window_started_epoch},
            watchdog_status                      => 'attention_required',
        }
    );
    $self->_log_collector_watchdog_event( $name, $message );
    return 1;
}

# _log_collector_watchdog_event($name, $message)
# Writes one explicit watchdog event to the global collector log and the named
# collector transcript log.
# Input: collector name string and message text.
# Output: true value.
sub _log_collector_watchdog_event {
    my ( $self, $name, $message ) = @_;
    chomp $message if defined $message;
    my $timestamp = _now_iso8601();
    $self->{files}->append( 'collector_log', sprintf "[%s][watchdog][%s] %s\n", $timestamp, $name, $message );
    $self->{collectors}->append_log_entry(
        $name,
        happened_at => $timestamp,
        error       => $message,
        source      => 'watchdog',
    );
    return 1;
}

# _merge_collector_supervisor_targets($names)
# Adds collector names to the persisted watchdog target set and ensures the
# background supervisor process is running.
# Input: array reference of collector names.
# Output: supervisor pid integer or undef when no targets remain.
sub _merge_collector_supervisor_targets {
    my ( $self, $names ) = @_;
    my $state = $self->_collector_supervisor_state || {};
    my @merged = $self->_normalized_collector_watch_names( [ @{ $state->{watched_names} || [] }, @{ $names || [] } ] );
    return $self->_set_collector_supervisor_targets( \@merged );
}

# _remove_collector_supervisor_targets($names)
# Removes collector names from the persisted watchdog target set and stops the
# supervisor when no watched collectors remain.
# Input: array reference of collector names.
# Output: supervisor pid integer or undef.
sub _remove_collector_supervisor_targets {
    my ( $self, $names ) = @_;
    my %remove = map { $_ => 1 } $self->_normalized_collector_watch_names($names);
    my $state = $self->_collector_supervisor_state || {};
    my @remaining = grep { !$remove{$_} } @{ $state->{watched_names} || [] };
    return $self->_set_collector_supervisor_targets( \@remaining );
}

# _set_collector_supervisor_targets($names)
# Replaces the persisted watchdog target set, starting or stopping the
# supervisor process to match the desired collector fleet.
# Input: array reference of collector names.
# Output: supervisor pid integer or undef when the supervisor is stopped.
sub _set_collector_supervisor_targets {
    my ( $self, $names ) = @_;
    my @targets = $self->_normalized_collector_watch_names($names);
    if ( !@targets ) {
        $self->_stop_collector_supervisor;
        return;
    }

    my $pid = $self->_collector_supervisor_running;
    $self->_write_collector_supervisor_state(
        {
            pid          => $pid,
            process_name => $self->_collector_supervisor_process_title,
            status       => $pid ? 'running' : 'starting',
            watched_names => \@targets,
            updated_at   => _now_iso8601(),
        }
    );
    return $pid if $pid;
    return $self->_start_collector_supervisor;
}

# _start_collector_supervisor()
# Starts the long-lived collector watchdog background process when it is not
# already running.
# Input: none.
# Output: supervisor pid integer or undef when no watched targets exist.
sub _start_collector_supervisor {
    my ($self) = @_;
    my $state = $self->_collector_supervisor_state || {};
    my @targets = $self->_normalized_collector_watch_names( $state->{watched_names} );
    return if !@targets;

    if ( my $running = $self->_collector_supervisor_running ) {
        return $running;
    }

    if (is_windows()) {
        my @command = $self->_windows_background_collector_supervisor_command;
        my $pid = $self->_spawn_windows_background_command(@command);
        $self->{paths}->secure_file_permissions( $self->_collector_supervisor_pidfile );
        open my $fh, '>', $self->_collector_supervisor_pidfile or die "Unable to write " . $self->_collector_supervisor_pidfile . ": $!";
        print {$fh} $pid;
        close $fh;
        $self->{paths}->secure_file_permissions( $self->_collector_supervisor_pidfile );
        $self->_write_collector_supervisor_state(
            {
                %{$state},
                pid          => $pid,
                process_name => $self->_collector_supervisor_process_title,
                status       => 'running',
                started_at   => _now_iso8601(),
                heartbeat_at => _now_iso8601(),
            }
        );
        return $pid;
    }

    my $pid = fork();
    die "Unable to fork collector supervisor: $!" if !defined $pid;
    if ($pid) {
        open my $fh, '>', $self->_collector_supervisor_pidfile or die "Unable to write " . $self->_collector_supervisor_pidfile . ": $!";
        print {$fh} $pid;
        close $fh;
        $self->{paths}->secure_file_permissions( $self->_collector_supervisor_pidfile );
        $self->_write_collector_supervisor_state(
            {
                %{$state},
                pid          => $pid,
                process_name => $self->_collector_supervisor_process_title,
                status       => 'running',
                started_at   => _now_iso8601(),
                heartbeat_at => _now_iso8601(),
            }
        );
        return $pid;
    }

    return $self->_run_collector_supervisor_child;
}

# _run_collector_supervisor_child(%args)
# Runs the collector watchdog loop in the detached supervisor process.
# Input: optional daemonize and redirect booleans.
# Output: never returns in normal operation.
sub _run_collector_supervisor_child {
    my ( $self, %args ) = @_;
    my $daemonize = exists $args{daemonize} ? $args{daemonize} : 1;
    my $redirect  = exists $args{redirect}  ? $args{redirect}  : 1;

    if ($daemonize) {
        $self->_detach_web_process_session;
    }
    if ($redirect) {
        open STDIN, '<', File::Spec->devnull() or die $!;
        open STDOUT, '>>', $self->{files}->collector_log or die $!;
        open STDERR, '>>', $self->{files}->collector_log or die $!;
        $self->_close_inherited_fds( close_ipc => 1 );
    }

    $ENV{DEVELOPER_DASHBOARD_COLLECTOR_SUPERVISOR} = 1;
    local $0 = $self->_collector_supervisor_process_title;
    local $COLLECTOR_SUPERVISOR_MANAGER = $self;
    my $shutdown = sub { $self->_shutdown_collector_supervisor('stopped') };
    local $SIG{CHLD} = sub {
        return if !$COLLECTOR_SUPERVISOR_MANAGER;
        $COLLECTOR_SUPERVISOR_MANAGER->_reap_any_child_processes;
        return;
    };
    local $SIG{TERM} = $shutdown;
    local $SIG{INT}  = $shutdown;
    local $SIG{HUP}  = $shutdown;

    while (1) {
        $self->_reap_any_child_processes;
        my $state = $self->_collector_supervisor_state || {};
        my @targets = $self->_normalized_collector_watch_names( $state->{watched_names} );
        if ( !@targets ) {
            $self->_shutdown_collector_supervisor('stopped');
        }
        $self->_write_collector_supervisor_state(
            {
                %{$state},
                pid          => $$,
                process_name => $self->_collector_supervisor_process_title,
                status       => 'running',
                heartbeat_at => _now_iso8601(),
            }
        );
        eval { $self->_supervise_collectors_once( names => \@targets ) };
        if ($@) {
            my $error = "$@";
            chomp $error;
            $self->{files}->append( 'collector_log', sprintf "[%s][watchdog] %s\n", _now_iso8601(), $error );
            $self->_write_collector_supervisor_state(
                {
                    %{$state},
                    pid          => $$,
                    process_name => $self->_collector_supervisor_process_title,
                    status       => 'error',
                    error        => $error,
                    heartbeat_at => _now_iso8601(),
                }
            );
        }
        sleep $self->_collector_supervisor_poll_interval;
    }
}

# _shutdown_collector_supervisor($status)
# Persists the final watchdog supervisor state and removes its pid/state files.
# Input: final status string.
# Output: never returns.
sub _shutdown_collector_supervisor {
    my ( $self, $status ) = @_;
    $self->_reap_any_child_processes;
    my $state = $self->_collector_supervisor_state || {};
    $self->_write_collector_supervisor_state(
        {
            %{$state},
            pid          => $$,
            process_name => $self->_collector_supervisor_process_title,
            status       => $status || 'stopped',
            heartbeat_at => _now_iso8601(),
            stopped_at   => _now_iso8601(),
        }
    );
    $self->_cleanup_collector_supervisor_files;
    POSIX::_exit(0);
}

# _stop_collector_supervisor()
# Stops the background collector watchdog process when it is running.
# Input: none.
# Output: stopped supervisor pid integer or undef.
sub _stop_collector_supervisor {
    my ($self) = @_;
    my $pid = $self->_collector_supervisor_running;
    if ($pid) {
        $self->_send_signal( 'TERM', $pid );
        for ( 1 .. 20 ) {
            last if !$self->_pid_is_running($pid);
            sleep 0.1;
        }
        $self->_send_signal( 'KILL', $pid ) if $self->_pid_is_running($pid);
        for ( 1 .. 20 ) {
            last if !$self->_pid_is_running($pid);
            sleep 0.1;
        }
        $self->_reap_child_process($pid);
    }
    $self->_cleanup_collector_supervisor_files;
    return $pid;
}

# _collector_supervisor_running()
# Returns the live watchdog supervisor pid when the managed process is still
# active in the current pid namespace.
# Input: none.
# Output: supervisor pid integer or undef.
sub _collector_supervisor_running {
    my ($self) = @_;
    my $pidfile = $self->_collector_supervisor_pidfile;
    return if !-f $pidfile;
    open my $fh, '<', $pidfile or die "Unable to read $pidfile: $!";
    my $pid = <$fh>;
    chomp $pid if defined $pid;
    if ( $pid && $pid =~ /^\d+$/ && kill( 0, $pid ) && $self->_same_pid_namespace($pid) && $self->_is_collector_supervisor($pid) ) {
        return $pid + 0;
    }
    $self->_cleanup_collector_supervisor_files;
    return;
}

# _is_collector_supervisor($pid)
# Confirms whether a pid belongs to the managed collector watchdog process.
# Input: process id integer.
# Output: boolean managed flag.
sub _is_collector_supervisor {
    my ( $self, $pid ) = @_;
    return 0 if !$pid || !kill 0, $pid;
    my $marker = $self->_read_process_env_marker( $pid, 'DEVELOPER_DASHBOARD_COLLECTOR_SUPERVISOR' );
    return 1 if defined $marker && $marker eq '1';
    my $title = $self->_read_process_title($pid);
    return 0 if !defined $title || $title eq '';
    return 1 if $title eq $self->_collector_supervisor_process_title;
    return 1 if $self->_looks_like_collector_supervisor_process( { pid => $pid, args => $title } );
    return 0;
}

# _looks_like_collector_supervisor_process($proc)
# Determines whether one process record matches the detached watchdog command
# shape used on platforms that expose the helper command line instead of the
# process title.
# Input: process hash reference with args text.
# Output: boolean match flag.
sub _looks_like_collector_supervisor_process {
    my ( $self, $proc ) = @_;
    return 0 if !$proc || !$proc->{args};
    return 1 if $proc->{args} =~ /^dashboard collector supervisor$/;
    return 1 if $proc->{args} =~ m{^(?:\S+[\\/])?_dashboard-core\s+collector-supervisor-foreground(?:\s+.*)?$};
    return 1 if $proc->{args} =~ m{^(?:\S+[\\/])?perl(?:\.exe)?(?:\s+-\S+)*\s+(?:\S+[\\/])?_dashboard-core\s+collector-supervisor-foreground(?:\s+.*)?$}i;
    return 0;
}

# _collector_supervisor_pidfile()
# Returns the watchdog supervisor pidfile path.
# Input: none.
# Output: file path string.
sub _collector_supervisor_pidfile {
    my ($self) = @_;
    return File::Spec->catfile( $self->{paths}->state_root, 'collector-supervisor.pid' );
}

# _collector_supervisor_statefile()
# Returns the watchdog supervisor state file path.
# Input: none.
# Output: file path string.
sub _collector_supervisor_statefile {
    my ($self) = @_;
    return File::Spec->catfile( $self->{paths}->state_root, 'collector-supervisor.json' );
}

# _collector_supervisor_state()
# Loads the persisted watchdog supervisor state.
# Input: none.
# Output: state hash reference or undef.
sub _collector_supervisor_state {
    my ($self) = @_;
    my $file = $self->_collector_supervisor_statefile;
    return if !-f $file;
    open my $fh, '<:raw', $file or die "Unable to read $file: $!";
    local $/;
    return json_decode( scalar <$fh> );
}

# _write_collector_supervisor_state($state)
# Atomically persists the watchdog supervisor state snapshot.
# Input: state hash reference.
# Output: written state hash reference.
sub _write_collector_supervisor_state {
    my ( $self, $data ) = @_;
    my $file = $self->_collector_supervisor_statefile;
    my $tmp = sprintf '%s.%s.%s.pending', $file, $$, time;
    open my $fh, '>:raw', $tmp or die "Unable to write $tmp: $!";
    print {$fh} json_encode( $data || {} );
    close $fh;
    $self->{paths}->secure_file_permissions($tmp);
    $self->_replace_state_file( $tmp, $file );
    $self->{paths}->secure_file_permissions($file);
    return $data || {};
}

# _cleanup_collector_supervisor_files()
# Removes the watchdog supervisor pid and state files.
# Input: none.
# Output: true value.
sub _cleanup_collector_supervisor_files {
    my ($self) = @_;
    unlink $self->_collector_supervisor_pidfile if -f $self->_collector_supervisor_pidfile;
    unlink $self->_collector_supervisor_statefile if -f $self->_collector_supervisor_statefile;
    return 1;
}

# _collector_supervisor_process_title()
# Returns the managed process title used by the watchdog supervisor.
# Input: none.
# Output: process title string.
sub _collector_supervisor_process_title {
    return 'dashboard collector supervisor';
}

# _normalized_collector_watch_names($names)
# Deduplicates and sorts collector names for the watchdog target set.
# Input: array reference or list-like scalar containing collector names.
# Output: ordered list of collector name strings.
sub _normalized_collector_watch_names {
    my ( $self, $names ) = @_;
    my @names = ref($names) eq 'ARRAY' ? @{$names} : ();
    my %seen;
    return sort grep { defined && $_ ne '' && !$seen{$_}++ } @names;
}

# _collector_restart_limit()
# Returns how many unexpected collector restarts are allowed within the active
# watchdog window before human attention is required.
# Input: none.
# Output: positive integer restart limit.
sub _collector_restart_limit {
    my ($self) = @_;
    my $value = $ENV{DEVELOPER_DASHBOARD_COLLECTOR_RESTART_LIMIT};
    return $value if defined $value && $value =~ /^\d+$/ && $value > 0;
    return 3;
}

# _collector_restart_window_seconds()
# Returns the rolling time window used for watchdog restart-threshold tracking.
# Input: none.
# Output: positive integer number of seconds.
sub _collector_restart_window_seconds {
    my ($self) = @_;
    my $value = $ENV{DEVELOPER_DASHBOARD_COLLECTOR_RESTART_WINDOW_SECONDS};
    return $value if defined $value && $value =~ /^\d+$/ && $value > 0;
    return 300;
}

# _collector_stall_grace_seconds()
# Returns the extra grace period added to collector timeout-plus-interval
# windows before the watchdog treats a managed scheduled collector as stalled.
# Input: none.
# Output: positive integer number of seconds.
sub _collector_stall_grace_seconds {
    my ($self) = @_;
    my $value = $ENV{DEVELOPER_DASHBOARD_COLLECTOR_STALL_GRACE_SECONDS};
    return $value if defined $value && $value =~ /^\d+$/ && $value > 0;
    return 10;
}

# _collector_supervisor_poll_interval()
# Returns how often the watchdog supervisor scans the collector fleet.
# Input: none.
# Output: positive fractional second poll interval.
sub _collector_supervisor_poll_interval {
    my ($self) = @_;
    my $value = $ENV{DEVELOPER_DASHBOARD_COLLECTOR_SUPERVISOR_POLL_INTERVAL};
    return $value if defined $value && $value =~ /^(?:\d+|\d*\.\d+)$/ && $value > 0;
    return 5;
}

# stop_progress_tasks()
# Builds the ordered task list shown for dashboard stop progress output.
# Input: none.
# Output: array reference of task hash references.
sub stop_progress_tasks {
    my ( $self, %args ) = @_;
    my $scope = $args{scope} || 'all';
    my $name  = $args{name};
    my @tasks;
    if ( $scope eq 'all' || $scope eq 'web' ) {
        push @tasks,
          {
            id    => 'stop_web',
            label => 'Stop dashboard web service',
          };
    }
    if ( $scope eq 'all' || $scope eq 'collector' ) {
        my @loops = $self->{runner}->running_loops;
        my @names = defined $name && $name ne ''
          ? ($name)
          : map { $_->{name} } @loops;
        push @tasks, map {
            +{
                id    => "stop_collector:$_",
                label => "Stop collector $_",
            }
        } @names;
    }
    return \@tasks;
}

# restart_progress_tasks()
# Builds the ordered task list shown for dashboard restart progress output.
# Input: none.
# Output: array reference of task hash references.
sub restart_progress_tasks {
    my ( $self, %args ) = @_;
    my $scope = $args{scope} || 'all';
    my $name  = $args{name};
    my @tasks = @{ $self->stop_progress_tasks };
    @tasks = @{ $self->stop_progress_tasks(%args) };
    if ( $scope eq 'all' || $scope eq 'collector' ) {
        my @collector_names;
        if ( defined $name && $name ne '' ) {
            @collector_names = ($name);
        }
        else {
            for my $job ( @{ $self->{config}->collectors } ) {
                next if ref($job) ne 'HASH';
                my $schedule = $job->{schedule} || ( $job->{cron} ? 'cron' : $job->{interval} ? 'interval' : 'manual' );
                next if $schedule eq 'manual';
                my $collector_name = $job->{name} || '(unnamed)';
                push @collector_names, $collector_name;
            }
        }
        push @tasks,
          map {
            {
                id    => "start_collector:$_",
                label => "Start collector $_",
            }
          } @collector_names;
    }
    if ( $scope eq 'all' || $scope eq 'web' ) {
        push @tasks,
          {
            id    => 'start_web',
            label => 'Start dashboard web service',
          };
    }
    return \@tasks;
}

# web_state()
# Loads the persisted web service state file.
# Input: none.
# Output: state hash reference or undef.
sub web_state {
    my ($self) = @_;
    my $file = $self->{files}->web_state;
    return if !-f $file;
    open my $fh, '<:raw', $file or die "Unable to read $file: $!";
    local $/;
    return json_decode( scalar <$fh> );
}

# _shutdown_web($status)
# Persists final web state and exits the web child.
# Input: final status string.
# Output: never returns.
sub _shutdown_web {
    my ( $self, $status ) = @_;
    my $state = $self->web_state;
    if ( !$state ) {
        $state = {};
    }
    my $final_status = 'stopped';
    if ( defined $status && $status ne '' ) {
        $final_status = $status;
    }
    $self->_write_web_state(
        {
            %$state,
            pid        => $self->_normalized_process_id($$),
            status     => $final_status,
            updated_at => _now_iso8601(),
        }
    );
    POSIX::_exit(0);
}

# _run_web_child($writer, $host, $port, %args)
# Runs the daemonized web child lifecycle and reports startup status.
# Input: pipe writer handle, host, port, worker count, ssl flag, and detach/redirect options.
# Output: process exit code.
sub _run_web_child {
    my ( $self, $writer, $host, $port, %args ) = @_;
    my $detach   = exists $args{detach}   ? $args{detach}   : 1;
    my $redirect = exists $args{redirect} ? $args{redirect} : 1;
    my $workers  = exists $args{workers}  ? $args{workers}  : 1;
    my $ssl      = exists $args{ssl}      ? $args{ssl}      : 0;
    if ($detach) {
        $self->_detach_web_process_session;
        my $pid = $self->_fork_process();
        die "Unable to complete dashboard web daemonize: $!" if !defined $pid;
        return 0 if $pid;
    }
    if ($redirect) {
        open STDIN, '<', File::Spec->devnull() or die $!;
        open STDOUT, '>>', $self->{files}->dashboard_log or die $!;
        open STDERR, '>>', $self->{files}->dashboard_log or die $!;
    }
    $ENV{DEVELOPER_DASHBOARD_WEB_SERVICE} = 1;
    $ENV{DEVELOPER_DASHBOARD_WEB_HOST}    = $host;
    $ENV{DEVELOPER_DASHBOARD_WEB_PORT}    = $port;
    $ENV{DEVELOPER_DASHBOARD_WEB_WORKERS} = $workers;
    $ENV{DEVELOPER_DASHBOARD_WEB_SSL}     = $ssl;
    local $0 = $self->_web_process_title( $host, $port );
    local $SIGNAL_MANAGER = $self;
    my $shutdown = sub { $self->_shutdown_web('stopped') };
    local $SIG{TERM} = $shutdown;
    local $SIG{INT}  = $shutdown;
    local $SIG{HUP}  = $shutdown;

    my $server = eval { $self->{app_builder}->( host => $host, port => $port, workers => $workers, ssl => $ssl ) };
    if ($@) {
        $self->_write_startup_pipe_message( $writer, "err: $@" );
        return 1;
    }

    my $daemon = eval { $server->start_daemon };
    if ($@) {
        $self->_write_startup_pipe_message( $writer, "err: $@" );
        return 1;
    }

    my $bound_host = $daemon->sockhost;
    my $bound_port = $daemon->sockport;
    my $child_pid = $self->_normalized_process_id($$);
    $self->_write_startup_pipe_message( $writer, join( '|', 'ok', $child_pid, $bound_host, $bound_port ) . "\n" );
    $self->_close_inherited_fds( close_ipc => 1 ) if $detach || $redirect;

    $self->_write_web_state(
        {
            host         => $host,
            pid          => $child_pid,
            port         => $bound_port + 0,
            process_name => $self->_web_process_title( $host, $port ),
            started_at   => _now_iso8601(),
            status       => 'running',
            bound_host   => $bound_host,
            workers      => $workers + 0,
            ssl          => $ssl + 0,
        }
    );

    eval { $server->serve_daemon($daemon) };
    if ($@) {
        my $message = sprintf "[%s][web] %s\n", _now_iso8601(), $@;
        $self->{files}->append( 'dashboard_log', $message );
        $self->_write_web_state(
            {
                host       => $host,
                pid        => $child_pid,
                port       => $bound_port + 0,
                status     => 'error',
                error      => "$@",
                updated_at => _now_iso8601(),
                bound_host => $bound_host,
                workers    => $workers + 0,
            }
        );
        return 1;
    }

    $self->_write_web_state(
        {
            host       => $host,
            pid        => $child_pid,
            port       => $bound_port + 0,
            status     => 'stopped',
            updated_at => _now_iso8601(),
            bound_host => $bound_host,
            workers    => $workers + 0,
        }
    );
    return 0;
}

# _write_startup_pipe_message($writer, $message)
# Writes one startup status payload to the parent startup pipe without relying
# on buffered stdio semantics in detached children.
# Input: writable startup pipe handle and message string.
# Output: true value after the whole message is written and the handle closed.
sub _write_startup_pipe_message {
    my ( $self, $writer, $message ) = @_;
    $message = '' if !defined $message;
    my $fd = fileno($writer);
    if ( !defined $fd || $fd < 0 ) {
        print {$writer} $message or die "Unable to write startup pipe: $!";
    }
    else {
        my $offset = 0;
        while ( $offset < length $message ) {
            my $written = syswrite( $writer, $message, length($message) - $offset, $offset );
            die "Unable to write startup pipe: $!" if !defined $written;
            $offset += $written;
        }
    }
    if ( !$self->_close_startup_pipe_writer($writer) ) {
        die "Unable to close startup pipe: $!" if $! !~ /Bad file descriptor/;
    }
    return 1;
}

# _close_startup_pipe_writer($writer)
# Closes one startup pipe writer handle for web-service child startup reporting.
# Input: writable startup pipe handle.
# Output: true value when the close succeeds and false when the caller should
# inspect $! for an expected close failure such as Bad file descriptor.
sub _close_startup_pipe_writer {
    my ( $self, $writer ) = @_;
    return close $writer;
}

# _detach_web_process_session()
# Detaches the current web-service child from the parent session when the
# active platform supports POSIX setsid.
# Input: none.
# Output: true value after detaching or after explicitly skipping setsid on
# platforms that do not implement it.
sub _detach_web_process_session {
    my ($self) = @_;
    return 1 if is_windows();
    setsid() or die "Unable to detach dashboard web service: $!";
    return 1;
}

# _fork_process()
# Wraps Perl fork so tests can drive parent and child runtime paths directly.
# Input: none.
# Output: child pid in the parent, zero in the child, or undef on failure.
sub _fork_process {
    return fork();
}

# web_log(%args)
# Returns dashboard web-service log output, with optional tailing and follow mode.
# Input: optional lines count and follow flag.
# Output: log text string for non-follow mode, or streamed output via STDOUT in follow mode.
sub web_log {
    my ( $self, %args ) = @_;
    my $file = $self->{files}->resolve_file('dashboard_log');
    my $lines = $args{lines};
    my $follow = $args{follow} ? 1 : 0;
    my $start_pos = 0;
    if ( defined $lines ) {
        die 'Line count must be a positive integer' if $lines !~ /^\d+$/ || $lines < 1;
    }
    return '' if !$follow && !-f $file;

    my $log = '';
    if ( -f $file ) {
        open my $fh, '<', $file or die "Unable to read $file: $!";
        local $/;
        $log = <$fh>;
        $log = '' if !defined $log;
        $start_pos = tell($fh);
        close $fh;
    }
    $log = $self->_tail_text( $log, $lines ) if defined $lines;
    return $log if !$follow;

    my $old_stdout = select STDOUT;
    $| = 1;
    select $old_stdout;
    print $log if $log ne '';
    $self->_follow_log_file(
        file      => $file,
        start_pos => $start_pos,
    );
    return '';
}

# _tail_text($text, $lines)
# Returns the last N logical lines from a text buffer.
# Input: text string and positive integer line count.
# Output: tailed text string.
sub _tail_text {
    my ( $self, $text, $lines ) = @_;
    return '' if !defined $text || $text eq '';
    return $text if !defined $lines;
    my @parts = split /\n/, $text, -1;
    my $had_trailing_newline = @parts && $parts[-1] eq '' ? 1 : 0;
    pop @parts if $had_trailing_newline;
    my $start = @parts - $lines;
    $start = 0 if $start < 0;
    my $tail = join "\n", @parts[ $start .. $#parts ];
    $tail .= "\n" if $had_trailing_newline && $tail ne '';
    return $tail;
}

# _follow_log_file(%args)
# Streams appended content from one log file until interrupted.
# Input: file path plus optional poll interval seconds and start byte offset.
# Output: never returns under normal command use; prints new log chunks to STDOUT.
sub _follow_log_file {
    my ( $self, %args ) = @_;
    my $file = $args{file} || die 'Missing log file';
    my $interval = defined $args{interval} ? $args{interval} : 0.1;
    my $start_pos = $args{start_pos};
    my $fh;
    if ( !open( $fh, '<', $file ) ) {
        open my $create_fh, '>>', $file or die "Unable to create $file: $!";
        close $create_fh;
        $self->{paths}->secure_file_permissions($file);
        open( $fh, '<', $file ) or die "Unable to read $file: $!";
    }
    if ( defined $start_pos ) {
        seek $fh, $start_pos, 0 or die "Unable to seek $file: $!";
    }
    else {
        seek $fh, 0, 2 or die "Unable to seek $file: $!";
    }
    local $SIG{TERM} = sub { POSIX::_exit(0) };
    local $SIG{INT}  = sub { POSIX::_exit(0) };
    local $SIG{HUP}  = sub { POSIX::_exit(0) };
    while (1) {
        my $chunk = '';
        my $read = sysread( $fh, $chunk, 8192 );
        if ( defined $read && $read > 0 ) {
            print $chunk;
            next;
        }
        sleep $interval;
    }
}

# _write_web_state($state)
# Atomically persists the web service state snapshot.
# Input: state hash reference.
# Output: true value.
sub _write_web_state {
    my ( $self, $data ) = @_;
    my $payload = {};
    if ($data) {
        $payload = $data;
    }
    my $file = $self->{files}->web_state;
    my $tmp = sprintf '%s.%s.%s.pending', $file, $$, time;
    open my $fh, '>:raw', $tmp or die "Unable to write $tmp: $!";
    print {$fh} json_encode($payload);
    close $fh;
    $self->{paths}->secure_file_permissions($tmp);
    $self->_replace_state_file( $tmp, $file );
    $self->{paths}->secure_file_permissions($file);
    return $payload;
}

# _replace_state_file($source, $target)
# Replaces one runtime state file with a prepared temporary file, including a
# Windows-specific retry path when the destination already exists and plain
# rename replacement semantics are unavailable.
# Input: temporary source path and final state-file path.
# Output: true value after the target file has been replaced.
sub _replace_state_file {
    my ( $self, $source, $target ) = @_;
    return 1 if $self->_rename_path( $source, $target );

    my $rename_error = $!;
    if ( is_windows() ) {
        for my $attempt ( 1 .. 10 ) {
            if ( -e $target ) {
                $self->_unlink_path($target)
                  or die "Unable to remove $target before Windows replace retry: $!";
                return 1 if $self->_rename_path( $source, $target );
                $rename_error = $!;
            }

            my ( $fallback_ok, $fallback_error ) = $self->_replace_path_via_powershell( $source, $target );
            return 1 if $fallback_ok;
            if ( defined $fallback_error && $fallback_error ne '' ) {
                chomp $fallback_error;
                $rename_error = "$rename_error; PowerShell Move-Item fallback failed: $fallback_error";
            }
            my ( $overwrite_ok, $overwrite_error ) = $self->_overwrite_state_file_in_place( $source, $target );
            return 1 if $overwrite_ok;
            if ( defined $overwrite_error && $overwrite_error ne '' ) {
                chomp $overwrite_error;
                $rename_error = "$rename_error; in-place overwrite fallback failed: $overwrite_error";
            }
            last if $attempt == 10;
            sleep 0.05;
            return 1 if $self->_rename_path( $source, $target );
            $rename_error = $!;
        }
    }

    $self->_unlink_path($source) if -e $source;
    die "Unable to rename $source to $target: $rename_error";
}

# _rename_path($source, $target)
# Wraps rename so tests can simulate platform-specific file replacement
# failures without mutating the real filesystem behavior globally.
# Input: source file path and destination file path.
# Output: true when the rename succeeds, false otherwise.
sub _rename_path {
    my ( $self, $source, $target ) = @_;
    return rename $source, $target;
}

# _unlink_path($path)
# Wraps unlink so tests can observe cleanup and Windows replacement retries in
# isolation from the caller.
# Input: one filesystem path string.
# Output: true when the path was removed, false otherwise.
sub _unlink_path {
    my ( $self, $path ) = @_;
    return unlink $path;
}

# _replace_path_via_powershell($source, $target)
# Uses the native Windows Move-Item path as a last-resort file replacement
# fallback when Perl's in-process rename fails inside detached Windows runtime
# flows.
# Input: source file path and destination file path.
# Output: boolean success flag and optional failure text string.
sub _replace_path_via_powershell {
    my ( $self, $source, $target ) = @_;
    return ( 0, '' ) if !is_windows();
    my @script = (
        q{$ErrorActionPreference = 'Stop'},
        'Move-Item -LiteralPath '
          . _powershell_single_quote($source)
          . ' -Destination '
          . _powershell_single_quote($target)
          . ' -Force',
    );
    my ( $stdout, $stderr, $exit_code ) = capture {
        system 'powershell', '-NoLogo', '-NoProfile', '-Command', join '; ', @script;
        return $? >> 8;
    };
    return ( 1, '' ) if $exit_code == 0;
    return ( 0, join '', grep { defined && $_ ne '' } $stderr, $stdout );
}

# _overwrite_state_file_in_place($source, $target)
# Rewrites one runtime state target in place from the prepared temporary
# payload when Windows denies delete-or-move replacement but still permits a
# direct overwrite.
# Input: temporary source path and final state-file path.
# Output: boolean success flag and optional failure text string.
sub _overwrite_state_file_in_place {
    my ( $self, $source, $target ) = @_;
    return ( 0, '' ) if !is_windows();
    open my $source_fh, '<', $source or return ( 0, "Unable to read $source for in-place overwrite: $!" );
    local $/;
    my $content = <$source_fh>;
    close $source_fh or undef;

    open my $target_fh, '>', $target or return ( 0, "Unable to open $target for in-place overwrite: $!" );
    print {$target_fh} $content
      or return ( 0, "Unable to write $target during in-place overwrite: $!" );
    close $target_fh or undef;
    if ( -e $source ) {
        $self->_unlink_path($source) or undef;
    }
    return ( 1, '' );
}

# _cleanup_web_files()
# Removes persisted web pid and state files.
# Input: none.
# Output: true value.
sub _cleanup_web_files {
    my ($self) = @_;
    $self->{files}->remove('web_pid');
    $self->{files}->remove('web_state');
    return 1;
}

# _close_inherited_fds(%args)
# Closes inherited non-stdio descriptors in runtime children so background
# web/watchdog processes do not keep caller-side capture handles open after
# lifecycle commands exit.
# Input: optional keep array reference of descriptor integers, optional
# close_ipc boolean for socketpair/anon_inode cleanup, and optional
# preserve_harness boolean for in-process TAP harness execution.
# Output: true value.
sub _close_inherited_fds {
    my ( $self, %args ) = @_;
    return 1 if $args{preserve_harness} && $ENV{HARNESS_ACTIVE};
    my %keep = map { $_ => 1 } grep { defined $_ && $_ =~ /^\d+$/ } @{ $args{keep} || [] };
    $keep{0} = 1;
    $keep{1} = 1;
    $keep{2} = 1;
    for my $fd ( $self->_open_file_descriptors ) {
        next if $keep{$fd};
        next if !$self->_descriptor_is_inherited_pipe( $fd, %args );
        POSIX::close($fd);
    }
    return 1;
}

# _open_file_descriptors()
# Lists the current process file-descriptor numbers from procfs or /dev/fd so
# detached runtime children can close inherited caller pipes safely.
# Input: none.
# Output: sorted list of descriptor integers.
sub _open_file_descriptors {
    my ($self) = @_;
    my %seen;
    my @fds;
    for my $path ( glob('/proc/self/fd/*'), glob('/dev/fd/*') ) {
        next if $path !~ m{(?:/proc/self/fd|/dev/fd)/(\d+)\z};
        my $fd = $1 + 0;
        next if $seen{$fd}++;
        push @fds, $fd;
    }
    return sort { $a <=> $b } @fds;
}

# _descriptor_is_inherited_pipe($fd)
# Returns whether one descriptor currently points at an inherited capture or
# IPC endpoint that a detached runtime child should close after stdio has been
# redirected.
# Input: descriptor integer.
# Output: boolean true when the descriptor target is an inherited pipe,
# socketpair, or anonymous kernel handle.
sub _descriptor_is_inherited_pipe {
    my ( $self, $fd, %args ) = @_;
    return 0 if !defined $fd || $fd !~ /^\d+$/;
    my $proc_target = readlink("/proc/self/fd/$fd");
    my $dev_target  = readlink("/dev/fd/$fd");
    my $target = defined $proc_target ? $proc_target : $dev_target;
    return 0 if !defined $target || $target eq '';
    return 1 if $target =~ /^pipe:/;
    return 0 if !$args{close_ipc};
    return $target =~ /^(?:socket:|anon_inode:)/ ? 1 : 0;
}

# _web_process_title($host, $port)
# Builds the managed web process title string.
# Input: host and port values.
# Output: process title string.
sub _web_process_title {
    my ( $self, $host, $port ) = @_;
    return "dashboard web: $host:$port";
}

# _portable_signal($signal)
# Converts signal names used by dashboard lifecycle code into POSIX signal numbers.
# Input: signal name or numeric signal value.
# Output: numeric signal value safe for Perl builds that reject named signals.
sub _portable_signal {
    my ($signal) = @_;
    die 'Missing signal name' if !defined $signal || $signal eq '';
    return $signal + 0 if $signal =~ /^\d+$/;
    my %signal_number = (
        HUP  => 1,
        INT  => 2,
        TERM => 15,
        KILL => 9,
    );
    my $name = uc $signal;
    die "Unsupported signal name: $signal" if !exists $signal_number{$name};
    return $signal_number{$name};
}

# _send_signal($signal, @pids)
# Sends a portable numeric signal to live process ids.
# Input: signal name/number and candidate process id values.
# Output: number of process ids signalled by Perl kill.
sub _send_signal {
    my ( $self, $signal, @pids ) = @_;
    my @targets = grep { defined $_ && /^\d+$/ && $_ > 0 } @pids;
    return 0 if !@targets;
    if (is_windows()) {
        my $joined = join ',', @targets;
        my @taskkill = ('taskkill');
        for my $target (@targets) {
            push @taskkill, '/PID', $target;
        }
        push @taskkill, '/T', '/F';
        my ( $stdout, $stderr, $exit_code ) = capture {
            system @taskkill;
            return $? >> 8;
        };
        return scalar @targets if $exit_code == 0;
        if ( defined $stderr && $stderr =~ /not found/i ) {
            return scalar @targets;
        }
        if ( defined $stdout && $stdout =~ /not found/i ) {
            return scalar @targets;
        }
        die "Failed to stop Windows process ids $joined: $stderr$stdout"
          if $signal =~ /^(?:TERM|KILL)$/i;
        return 0;
    }
    my $portable_signal = _portable_signal($signal);
    return kill $portable_signal, @targets;
}

# _is_managed_web($pid)
# Checks whether a pid belongs to a managed dashboard web process.
# Input: process id integer.
# Output: boolean managed flag.
sub _is_managed_web {
    my ( $self, $pid ) = @_;
    return 0 if !$pid || !kill 0, $pid;
    return 0 if !$self->_same_pid_namespace($pid);
    my $marker = $self->_read_process_env_marker( $pid, 'DEVELOPER_DASHBOARD_WEB_SERVICE' );
    return 1 if defined $marker && $marker eq '1';
    my $title = $self->_read_process_title($pid);
    return 0 if !defined $title || $title eq '';
    return $title =~ /^dashboard web:/ ? 1 : 0;
}

# _windows_background_web_command(%args)
# Builds the detached helper command used to host the foreground Windows web
# listener in its own process without also starting collector loops.
# Input: host, port, worker count, and ssl flag.
# Output: command list suitable for system 1, @command on Windows.
sub _windows_background_web_command {
    my ( $self, %args ) = @_;
    my $core = $self->_dashboard_core_helper_path('web-foreground');
    my $perl = $self->_current_perl_command;
    my @command = (
        $perl,
        $core,
        'web-foreground',
        '--host',
        $args{host},
        '--port',
        $args{port},
        '--workers',
        $args{workers},
    );
    push @command, '--ssl' if $args{ssl};
    return @command;
}

# _windows_background_collector_supervisor_command()
# Builds the detached helper command used to host the collector watchdog on
# Windows without tying it to the current process lifetime.
# Input: none.
# Output: command list suitable for system 1, @command on Windows.
sub _windows_background_collector_supervisor_command {
    my ($self) = @_;
    my $core = $self->_dashboard_core_helper_path('collector-supervisor-foreground');
    my $perl = $self->_current_perl_command;
    return (
        $perl,
        $core,
        'collector-supervisor-foreground',
    );
}

# _current_perl_command()
# Resolves a runnable Perl interpreter path for detached helper launches,
# including Windows sessions where $^X can point at a nonexistent local::lib
# shim path.
# Input: none.
# Output: executable path string for the current Perl interpreter.
sub _current_perl_command {
    my ($self) = @_;
    if (is_windows()) {
        return command_in_path('perl')     if command_in_path('perl');
        return command_in_path('perl.exe') if command_in_path('perl.exe');
    }
    return $^X if defined $^X && $^X ne '' && -f $^X;
    return command_in_path('perl')     if command_in_path('perl');
    return command_in_path('perl.exe') if command_in_path('perl.exe');
    return $^X;
}

# _dashboard_core_helper_path()
# Resolves the staged private _dashboard-core helper used by detached Windows
# web launches.
# Input: none.
# Output: absolute helper path string.
sub _dashboard_core_helper_path {
    my ( $self, $command ) = @_;
    $command ||= 'web-foreground';
    my $staged = File::Spec->catfile( $self->{paths}->home_runtime_root, 'cli', 'dd', '_dashboard-core' );
    return $staged if $self->_helper_file_supports_internal_command( $staged, $command );

    my $shipped = eval { Developer::Dashboard::InternalCLI::_helper_asset_path('_dashboard-core') };
    $shipped = '' if !defined $shipped;
    return $shipped if $self->_helper_file_supports_internal_command( $shipped, $command );

    return $staged;
}

# _helper_file_supports_internal_command($path, $command)
# Checks whether one helper source file contains the requested private command
# branch so Windows background launches can avoid stale staged helpers.
# Input: helper file path and internal command string.
# Output: boolean true when the helper source contains the requested command.
sub _helper_file_supports_internal_command {
    my ( $self, $path, $command ) = @_;
    return 0 if !defined $path || $path eq '' || !-f $path;
    return 0 if !defined $command || $command eq '';
    open my $fh, '<:raw', $path or return 0;
    local $/;
    my $content = <$fh>;
    CORE::close($fh) or return 0;
    my $matched = $content =~ /\Q$command\E/ ? 1 : 0;
    return $matched;
}

# _spawn_windows_background_command(@command)
# Launches one detached background Windows process command and returns the
# spawned pid.
# Input: command list.
# Output: spawned pid integer or undef when the command could not be launched.
sub _spawn_windows_background_command {
    my ( $self, @command ) = @_;
    my $stdout_log = $self->{files}->dashboard_log;
    my $stderr_log = $stdout_log . '.stderr';
    my @script = (
        q{$ErrorActionPreference = 'Stop'},
        '$job = Start-Process'
          . ' -FilePath ' . _powershell_single_quote( $command[0] )
          . ' -ArgumentList ' . join( ', ', map { _powershell_single_quote($_) } @command[ 1 .. $#command ] )
          . ' -WindowStyle Hidden'
          . ' -RedirectStandardOutput ' . _powershell_single_quote($stdout_log)
          . ' -RedirectStandardError ' . _powershell_single_quote($stderr_log)
          . ' -PassThru',
        q{[Console]::Out.WriteLine($job.Id)},
    );
    my ( $stdout, $stderr, $exit_code ) = capture {
        system 'powershell', '-NoLogo', '-NoProfile', '-Command', join '; ', @script;
        return $? >> 8;
    };
    die "Unable to launch detached Windows web process: $stderr$stdout"
      if $exit_code != 0;
    my ($pid) = grep { defined $_ && /^\d+$/ && $_ > 0 } split /\r?\n/, ( $stdout || '' );
    return $pid;
}

# _powershell_single_quote($value)
# Escapes one literal string for safe use in a single-quoted PowerShell
# argument position.
# Input: raw scalar string value.
# Output: single-quoted PowerShell literal string.
sub _powershell_single_quote {
    my ($value) = @_;
    $value = '' if !defined $value;
    $value =~ s/'/''/g;
    return "'$value'";
}

# _pkill_perl($pattern)
# Kills Perl processes whose command lines match a pattern.
# Input: regular-expression pattern string.
# Output: true value.
sub _pkill_perl {
    my ( $self, $pattern ) = @_;
    if (is_windows()) {
        for my $proc ( $self->_ps_processes ) {
            next if !$self->_proc_owned_by_current_user($proc);
            next if $proc->{args} !~ /$pattern/;
            $self->_send_signal( 'TERM', $proc->{pid} );
        }
        return 1;
    }
    my ( undef, $stderr, $exit_code ) = capture {
        my $ok = system 'pkill', '-15', '-f', $pattern;
        return $ok == -1 ? -1 : ($? >> 8);
    };
    return 1 if $exit_code == 0 || $exit_code == 1;
    if ( $exit_code < 0 || $exit_code == 127 || ( defined $stderr && $stderr =~ /not found/i ) ) {
        for my $proc ( $self->_ps_processes ) {
            next if !$self->_proc_owned_by_current_user($proc);
            next if $proc->{args} !~ /$pattern/;
            $self->_send_signal( 'TERM', $proc->{pid} );
        }
        return 1;
    }
    return;
}

# _find_processes_by_prefix($prefix)
# Returns running processes whose command lines start with a prefix.
# Input: prefix string.
# Output: list of process hash references.
sub _find_processes_by_prefix {
    my ( $self, $prefix ) = @_;
    my @matches;
    for my $proc ( $self->_ps_processes ) {
        next if !$self->_proc_owned_by_current_user($proc);
        if ( defined $proc->{args} && $proc->{args} =~ /^\Q$prefix\E/ ) {
            push @matches, $proc;
            next;
        }
        my $title = $self->_read_process_title( $proc->{pid} );
        next if !defined $title || $title !~ /^\Q$prefix\E/;
        push @matches, {
            %{$proc},
            args => $title,
        };
    }
    return @matches;
}

# _find_web_processes()
# Returns managed or older-compatible dashboard web processes.
# Input: none.
# Output: list of process hash references.
sub _find_web_processes {
    my ($self) = @_;
    my @seen;
    my %seen_pid;
    for my $proc ( $self->_ps_processes ) {
        next if $proc->{pid} == $$;
        next if $seen_pid{ $proc->{pid} }++;
        next if !$self->_proc_owned_by_current_user($proc);
        next if !$self->_looks_like_web_process($proc);
        push @seen, $proc;
    }
    return @seen;
}

# _listener_pids_from_state($state)
# Resolves live listener process ids from persisted web state when the saved
# wrapper pid is no longer the real listener process.
# Input: persisted web state hash reference.
# Output: list of live listener process ids bound to the saved port.
sub _listener_pids_from_state {
    my ( $self, $state ) = @_;
    return () if ref($state) ne 'HASH';
    my $port = $state->{port};
    return () if !defined $port || $port eq '';
    return grep { $self->_same_pid_namespace($_) } $self->_listener_pids_for_port($port);
}

# _proc_owned_by_current_user($proc)
# Checks whether one scanned process belongs to the current runtime user.
# Input: process hash reference with optional uid metadata.
# Output: boolean true when the process belongs to the current uid.
sub _proc_owned_by_current_user {
    my ( $self, $proc ) = @_;
    return 0 if !$proc || !$proc->{pid};
    return 0 if !$self->_same_pid_namespace( $proc->{pid} );
    return 1 if !defined $proc->{uid} || $proc->{uid} eq '';
    return ( $proc->{uid} + 0 ) == ( $< + 0 ) ? 1 : 0;
}

# _find_legacy_web_processes()
# Returns older-style dashboard serve processes.
# Input: none.
# Output: list of process hash references.
sub _find_legacy_web_processes {
    my ($self) = @_;
    return grep { $_->{args} !~ /^dashboard web:/ } $self->_find_web_processes;
}

# _looks_like_web_process($proc)
# Determines whether a process record matches known web worker forms.
# Input: process hash reference with args.
# Output: boolean match flag.
sub _looks_like_web_process {
    my ( $self, $proc ) = @_;
    return 0 if !$proc || !$proc->{pid} || !$proc->{args};
    return 1 if $proc->{args} =~ /^dashboard web:\s+\S+:\d+$/;
    return 1 if $proc->{args} =~ m{^(?:\S+[\\/])?_dashboard-core\s+(?:serve|web-foreground)(?:\s+(?!logs(?:\s|$)|workers(?:\s|$)).*)?$};
    return 1 if $proc->{args} =~ m{^(?:\S+[\\/])?perl(?:\.exe)?(?:\s+-\S+)*\s+(?:\S+[\\/])?_dashboard-core\s+(?:serve|web-foreground)(?:\s+(?!logs(?:\s|$)|workers(?:\s|$)).*)?$}i;
    return 1 if $proc->{args} =~ m{^(?:\S+/env\s+)?perl(?:\s+-\S+)*\s+(?:\S+/)?dashboard\s+serve(?:\s+(?!logs(?:\s|$)|workers(?:\s|$)).*)?$};
    return 1 if $proc->{args} =~ m{^(?:\S+/env\s+)?perl(?:\s+-\S+)*\s+bin/dashboard\s+serve(?:\s+(?!logs(?:\s|$)|workers(?:\s|$)).*)?$};
    return 1 if $proc->{args} =~ m{^(?:\S+/)?dashboard\s+serve(?:\s+(?!logs(?:\s|$)|workers(?:\s|$)).*)?$};
    return 1 if $proc->{args} =~ m{^bin/dashboard\s+serve(?:\s+(?!logs(?:\s|$)|workers(?:\s|$)).*)?$};
    return 0;
}

# _ps_processes()
# Reads the process table into normalized process records.
# Input: none.
# Output: list of process hash references.
sub _ps_processes {
    my ($self) = @_;
    if (is_windows()) {
        my ( $stdout, undef, $exit_code ) = capture {
            system(
                'powershell',
                '-NoLogo',
                '-NoProfile',
                '-Command',
                q{$ErrorActionPreference = 'Stop'; Get-CimInstance Win32_Process | ForEach-Object { $cmd = $_.CommandLine; if ($null -eq $cmd) { $cmd = '' }; [Console]::Out.WriteLine(('{0}`t{1}' -f $_.ProcessId, $cmd)) }},
            );
            return $? >> 8;
        };
        return if $exit_code != 0;
        my @procs;
        for my $line ( split /\n/, $stdout ) {
            next if $line !~ /^\s*(\d+)\t?(.*)$/;
            push @procs, {
                pid  => $1 + 0,
                args => $2,
            };
        }
        return @procs;
    }
    my ( $stdout, undef, $exit_code ) = capture {
        system 'ps', '-eo', 'pid=,uid=,args=';
        return $? >> 8;
    };
    return if $exit_code != 0;
    my @procs;
    for my $line ( split /\n/, $stdout ) {
        next if $line !~ /^\s*(\d+)\s+(\d+)\s+(.*)$/;
        push @procs, {
            pid  => $1 + 0,
            uid  => $2 + 0,
            args => $3,
        };
    }
    return @procs;
}

# _managed_listener_pids_for_port($port)
# Returns managed web-service listener pids bound to one TCP port.
# Input: TCP port integer.
# Output: list of managed process ids.
sub _managed_listener_pids_for_port {
    my ( $self, $port ) = @_;
    return grep { $self->_is_managed_web($_) } $self->_listener_pids_for_port($port);
}

# _listener_pids_for_port($port)
# Returns TCP listener process ids bound to one port.
# Input: TCP port integer.
# Output: list of process ids.
sub _listener_pids_for_port {
    my ( $self, $port ) = @_;
    return () if !$port;
    if (is_windows()) {
        my ( $stdout, undef, $exit_code ) = capture {
            system(
                'powershell',
                '-NoLogo',
                '-NoProfile',
                '-Command',
                qq{\$ErrorActionPreference = 'Stop'; Get-NetTCPConnection -LocalPort $port -State Listen | Select-Object -ExpandProperty OwningProcess},
            );
            return $? >> 8;
        };
        if ( $exit_code == 0 && defined $stdout && $stdout ne '' ) {
            my %seen;
            return grep { !$seen{$_}++ } map { /^\s*(\d+)\s*$/ ? ($1 + 0) : () } split /\n/, $stdout;
        }
        return $self->_listener_pids_for_port_via_netstat($port);
    }
    if ( !command_in_path('ss') ) {
        my @pids = $self->_listener_pids_for_port_via_lsof($port);
        return @pids if @pids;
        return $self->_listener_pids_for_port_via_proc($port);
    }
    my ( $stdout, $stderr, $exit_code ) = capture {
        system 'ss', '-ltnp', "( sport = :$port )";
        return $? >> 8;
    };
    my @pids;
    my $has_stdout = defined $stdout && $stdout ne '';
    if ( $exit_code == 0 && $has_stdout ) {
        my %seen;
        @pids = grep { !$seen{$_}++ } ( $stdout =~ /pid=(\d+)/g );
    }
    else {
        my $ss_missing = 0;
        if ( $exit_code == 127 || $exit_code == 255 ) {
            $ss_missing = 1;
        }
        elsif ( defined $stderr && $stderr =~ /(?:not found|No such file or directory|Can't exec)/i ) {
            $ss_missing = 1;
        }
        if ($ss_missing) {
            @pids = $self->_listener_pids_for_port_via_lsof($port);
            @pids = $self->_listener_pids_for_port_via_proc($port) if !@pids;
        }
    }
    return @pids;
}

# _listener_pids_for_port_via_lsof($port)
# Resolves TCP listener process ids from lsof output on hosts that do not ship
# the Linux ss utility, such as macOS.
# Input: TCP port integer.
# Output: list of process ids.
sub _listener_pids_for_port_via_lsof {
    my ( $self, $port ) = @_;
    return () if !$port;
    my ( $stdout, $stderr, $exit_code ) = capture {
        system 'lsof', '-nP', "-iTCP:$port", '-sTCP:LISTEN', '-Fp';
        return $? >> 8;
    };
    return () if $exit_code != 0 || !defined $stdout || $stdout eq '';
    my %seen;
    my @pids;
    for my $line ( split /\n/, $stdout ) {
        next if $line !~ /^p(\d+)$/;
        my $pid = $1 + 0;
        next if $seen{$pid}++;
        push @pids, $pid;
    }
    return @pids;
}

# _listener_pids_for_port_via_netstat($port)
# Resolves TCP listener process ids from Windows netstat output.
# Input: TCP port integer.
# Output: list of process ids.
sub _listener_pids_for_port_via_netstat {
    my ( $self, $port ) = @_;
    return () if !$port;
    my ( $stdout, undef, $exit_code ) = capture {
        system 'netstat', '-ano', '-p', 'tcp';
        return $? >> 8;
    };
    return () if $exit_code != 0 || !defined $stdout || $stdout eq '';
    my %seen;
    my @pids;
    for my $line ( split /\n/, $stdout ) {
        next if $line !~ /^\s*TCP\s+\S+:$port\s+\S+\s+LISTENING\s+(\d+)\s*$/i;
        my $pid = $1 + 0;
        next if $seen{$pid}++;
        push @pids, $pid;
    }
    return @pids;
}

# _listener_pids_for_port_via_proc($port)
# Resolves TCP listener process ids from /proc when ss is unavailable.
# Input: TCP port integer.
# Output: list of process ids.
sub _listener_pids_for_port_via_proc {
    my ( $self, $port ) = @_;
    my %inode = map { $_ => 1 } $self->_listener_socket_inodes_for_port($port);
    return () if !%inode;
    return $self->_process_pids_for_socket_inodes( \%inode );
}

# _listener_socket_inodes_for_port($port)
# Reads /proc TCP tables and returns listener socket inodes for one port.
# Input: TCP port integer.
# Output: list of socket inode integers.
sub _listener_socket_inodes_for_port {
    my ( $self, $port ) = @_;
    return () if !$port;
    my $hex_port = sprintf '%04X', $port;
    my %seen;
    my @inodes;
    for my $file ( $self->_listener_socket_table_paths ) {
        next if !-r $file;
        open my $fh, '<', $file or next;
        while ( my $line = <$fh> ) {
            next if $line !~ /\S/;
            my @fields = split ' ', $line;
            next if @fields < 10;
            next if !defined $fields[1] || !defined $fields[3] || !defined $fields[9];
            my ( undef, $local_port ) = split /:/, $fields[1], 2;
            next if !defined $local_port || uc($local_port) ne $hex_port;
            next if $fields[3] ne '0A';
            my $inode = $fields[9];
            next if !$inode || $seen{$inode}++;
            push @inodes, $inode + 0;
        }
        close $fh;
    }
    return @inodes;
}

# _listener_socket_table_paths()
# Returns the procfs TCP table files used for listener discovery.
# Input: none.
# Output: list of file path strings.
sub _listener_socket_table_paths {
    return ( '/proc/net/tcp', '/proc/net/tcp6' );
}

# _process_pids_for_socket_inodes($inode_lookup)
# Maps socket inode values back to owning process ids through /proc fd links.
# Input: hash reference keyed by socket inode.
# Output: list of process ids.
sub _process_pids_for_socket_inodes {
    my ( $self, $inode_lookup ) = @_;
    return () if !$inode_lookup || ref($inode_lookup) ne 'HASH' || !%{$inode_lookup};
    my %seen;
    my @pids;
    for my $fd_path ( $self->_process_fd_paths ) {
        next if $fd_path !~ m{/(?:proc/)?(\d+)/fd/[^/]+$};
        my $pid = $1 + 0;
        my $target = readlink $fd_path;
        next if !defined $target || $target !~ /^socket:\[(\d+)\]$/;
        next if !$inode_lookup->{$1};
        next if $seen{$pid}++;
        push @pids, $pid;
    }
    return @pids;
}

# _process_fd_paths()
# Returns the procfs file-descriptor paths used for socket owner discovery.
# Input: none.
# Output: list of file path strings.
sub _process_fd_paths {
    return glob '/proc/[0-9]*/fd/*';
}

# _wait_for_port_release($port)
# Waits for a TCP port listener set to disappear after shutdown signals are sent.
# Input: TCP port integer.
# Output: true when the port is no longer listening.
sub _wait_for_port_release {
    my ( $self, $port ) = @_;
    return 1 if !$port;
    for ( 1 .. 50 ) {
        return 1 if !scalar $self->_listener_pids_for_port($port);
        sleep 0.1;
    }
    return !scalar $self->_listener_pids_for_port($port);
}

# _restart_web_with_retry(%args)
# Restarts the web listener with retries for transient port-release races.
# Input: host, port, worker-count, and ssl values.
# Output: restarted web pid.
sub _restart_web_with_retry {
    my ( $self, %args ) = @_;
    my $host = '0.0.0.0';
    if ( defined $args{host} ) {
        $host = $args{host};
    }
    my $port = 7890;
    if ( defined $args{port} ) {
        $port = $args{port};
    }
    my $workers = 1;
    if ( defined $args{workers} ) {
        $workers = $args{workers};
    }
    my $ssl = $args{ssl} ? 1 : 0;
    my $progress = $args{progress};
    $self->_progress_emit(
        $progress,
        {
            task_id => 'start_web',
            status  => 'running',
            label   => 'Start dashboard web service',
        }
    );
    my $attempts = 20;
    for my $attempt ( 1 .. $attempts ) {
        my $pid = eval { $self->start_web( host => $host, port => $port, workers => $workers, ssl => $ssl ) };
        my $error = $@;
        if ( defined $pid && !$error ) {
            if ( $self->_web_runtime_ready( $pid, $port ) ) {
                $self->_progress_emit(
                    $progress,
                    {
                        task_id => 'start_web',
                        status  => 'done',
                        label   => 'Start dashboard web service',
                    }
                );
                return $pid;
            }
            $self->_cleanup_web_files;
            $error = "Unable to confirm dashboard web service stayed running on $host:$port (pid $pid)\n";
        }
        if ( !$error ) {
            $error = "Unable to restart dashboard web service on $host:$port\n";
        }
        my $retryable_error = $error =~ /Address already in use|Unable to confirm dashboard web service stayed running|Unable to start dashboard web service/;
        $self->_progress_emit(
            $progress,
            {
                task_id => 'start_web',
                status  => 'failed',
                label   => 'Start dashboard web service',
            }
        ) if $attempt == $attempts || !$retryable_error;
        die $error if !$retryable_error;
        die $error if $attempt == $attempts;
        sleep 0.25;
    }
}

# _progress_emit($progress, $event)
# Sends one lifecycle progress event to an optional progress callback.
# Input: optional progress coderef and event hash reference.
# Output: true value.
sub _progress_emit {
    my ( $self, $progress, $event ) = @_;
    return 1 if !$progress || ref($progress) ne 'CODE';
    $progress->($event);
    return 1;
}

# _web_runtime_ready($pid, $port)
# Confirms that one reported web pid is still the active managed web process
# and that the configured listen port is actually bound, then keeps checking
# only long enough to catch an immediate post-ready crash.
# Input: process id integer and configured TCP port integer.
# Output: boolean true when the runtime exposed its listener and survived the
# short confirmation window afterwards.
sub _web_runtime_ready {
    my ( $self, $pid, $port ) = @_;
    $pid = $self->_normalized_process_id($pid);
    return 0 if !defined $pid;
    return 0 if $pid !~ /^\d+$/;
    return 0 if $pid < 1;
    if ( defined $port && $port ne '' ) {
        return 0 if $port !~ /^\d+$/;
        return 0 if $port < 1;
    }
    if ( is_windows() && $port ) {
        my $ready_polls = 0;
        for ( 1 .. $self->_runtime_stability_polls ) {
            my @listener_pids = $self->_listener_pids_for_port($port);
            my $listening = @listener_pids ? 1 : 0;
            $listening = 1 if !$listening && $self->_port_accepting_connections($port);
            if ($listening) {
                $ready_polls++;
                return 1 if $ready_polls >= $self->_runtime_confirmation_polls;
            }
            elsif ($ready_polls) {
                return 0;
            }
            sleep $self->_runtime_poll_interval;
        }
        return 0;
    }

    my $ready_polls = 0;
    for ( 1 .. $self->_runtime_stability_polls ) {
        my $running = $self->running_web;
        my $listening = 0;
        my $matches_runtime = 0;
        my $listener_pid;
        if ($running) {
            $matches_runtime = $self->_web_runtime_matches_pid( $running, $pid, $port ) ? 1 : 0;
        }
        my $listener_port = 0;
        $listener_port = $port if $port;
        $listener_port = $running->{port} if !$listener_port && $running && $running->{port};
        if ($listener_port) {
            my @listener_pids = grep { $self->_same_pid_namespace($_) } $self->_listener_pids_for_port($listener_port);
            if (@listener_pids) {
                $listening = 1;
                $listener_pid = $listener_pids[0];
                if ( !$matches_runtime && !$self->_same_pid_namespace($pid) ) {
                    $matches_runtime = 0;
                }
                elsif ( !$matches_runtime && $running ) {
                    $matches_runtime = 1;
                }
                if ( $matches_runtime && defined $listener_pid && $listener_pid =~ /^\d+$/ ) {
                    $self->_adopt_web_listener_pid(
                        listener_pid => $listener_pid,
                        state        => $running,
                    );
                    $running->{pid} = $listener_pid if $running;
                }
            }
            $listening = 1 if !$listening && $matches_runtime && $self->_port_accepting_connections($listener_port);
        }
        if ($listening) {
            $ready_polls++;
            return 1 if $ready_polls >= $self->_runtime_confirmation_polls;
        }
        elsif ($ready_polls) {
            return 0;
        }
        sleep $self->_runtime_poll_interval;
    }
    return 0;
}

# _adopt_web_listener_pid(%args)
# Replaces the transient startup wrapper pid in persisted web state with the
# real listener pid once the PSGI server has rebound under Starman.
# Input: listener_pid integer and optional current runtime-state hash reference.
# Output: adopted listener pid integer or undef when nothing was updated.
sub _adopt_web_listener_pid {
    my ( $self, %args ) = @_;
    my $listener_pid = $self->_normalized_process_id( $args{listener_pid} );
    return if !defined $listener_pid || $listener_pid !~ /^\d+$/ || $listener_pid < 1;
    return if !$self->_same_pid_namespace($listener_pid);

    my $state = ref( $args{state} ) eq 'HASH'
      ? { %{ $args{state} } }
      : { %{ $self->web_state || {} } };
    return if ( $state->{pid} || 0 ) == $listener_pid;

    $state->{pid} = $listener_pid + 0;
    $state->{status} = 'running';
    $state->{updated_at} = _now_iso8601();
    my $title = $self->_read_process_title($listener_pid);
    $state->{process_name} = $title if defined $title && $title ne '';
    $self->{files}->write( 'web_pid', "$listener_pid\n" );
    $self->_write_web_state($state);
    return $listener_pid;
}

# _normalized_process_id($pid)
# Normalizes one observed process id into a positive integer on platforms such
# as Windows where pseudo-fork bookkeeping can surface a negative startup pid.
# Input: optional process id scalar.
# Output: positive integer process id or the original scalar when it is not a
# numeric pid.
sub _normalized_process_id {
    my ( $self, $pid ) = @_;
    return $pid if !defined $pid;
    return $pid if $pid !~ /^-?\d+$/;
    return abs($pid);
}

# _web_runtime_matches_pid($running, $pid, $port)
# Determines whether one observed runtime record matches the expected startup
# pid closely enough to prove the replacement web service stayed up.
# Input: running runtime hash reference, startup pid integer, and requested
# TCP port integer.
# Output: boolean true when the observed runtime matches the expected startup.
sub _web_runtime_matches_pid {
    my ( $self, $running, $pid, $port ) = @_;
    return 0 if !$running || ref($running) ne 'HASH';
    return 1 if ( $running->{pid} || 0 ) == $pid;
    return 0 if !is_windows();
    my $listener_port = 0;
    $listener_port = $port if $port;
    $listener_port = $running->{port} if !$listener_port && $running->{port};
    return 0 if !$listener_port;
    return 0 if ( $running->{port} || 0 ) != $listener_port;
    return 1;
}

# _collector_runtime_ready($name, $pid)
# Confirms that a newly started collector loop became visible and stayed alive
# long enough to catch an immediate post-ready crash.
# Input: collector name string and process id integer.
# Output: boolean true when the collector loop became visible and survived the
# short confirmation window afterwards.
sub _collector_runtime_ready {
    my ( $self, $name, $pid ) = @_;
    return 0 if !defined $name || $name eq '';
    return 0 if !defined $pid || $pid !~ /^\d+$/ || $pid < 1;
    my $ready_polls = 0;
    for ( 1 .. $self->_runtime_stability_polls ) {
        my $state = $self->{runner}->can('loop_state') ? $self->{runner}->loop_state($name) : undef;
        my $state_ready = $state
          && ( $state->{pid} || 0 ) == $pid
          && ( $state->{name} || $name ) eq $name
          && ( $state->{status} || '' ) =~ /^(?:starting|running|error)$/
          && kill( 0, $pid );
        my ($running) = $state_ready
          ? ()
          : grep { $_->{name} eq $name && ( $_->{pid} || 0 ) == $pid } $self->{runner}->running_loops;
        if ( $state_ready || $running ) {
            $ready_polls++;
            return 1 if $ready_polls >= $self->_runtime_confirmation_polls;
        }
        elsif ($ready_polls) {
            return 0;
        }
        sleep $self->_runtime_poll_interval;
    }
    return 0;
}

# _runtime_stability_polls()
# Returns the number of readiness polls used to prove that a replacement
# runtime had enough time to become visible before it is declared dead on
# arrival.
# Input: none.
# Output: positive integer poll count.
sub _runtime_stability_polls {
    my $override = $ENV{DEVELOPER_DASHBOARD_RUNTIME_STABILITY_POLLS};
    return $override if defined $override && $override =~ /^\d+$/ && $override > 0;

    my $perl5opt = join ' ', grep { defined && $_ ne '' } @ENV{qw(PERL5OPT HARNESS_PERL_SWITCHES)};
    return 300 if $perl5opt =~ /Devel::Cover/ || exists $INC{'Devel/Cover.pm'};

    return 300;
}

# _runtime_confirmation_polls()
# Returns the number of consecutive ready polls required after startup first
# becomes visible before the runtime is declared stable.
# Input: none.
# Output: positive integer poll count.
sub _runtime_confirmation_polls {
    my $override = $ENV{DEVELOPER_DASHBOARD_RUNTIME_CONFIRMATION_POLLS};
    return $override if defined $override && $override =~ /^\d+$/ && $override > 0;
    return 3;
}

# _runtime_poll_interval()
# Returns the sleep interval in seconds between runtime readiness polls.
# Input: none.
# Output: fractional seconds between polls.
sub _runtime_poll_interval {
    return 0.1;
}

# _port_accepting_connections($port)
# Checks whether one TCP port is currently accepting local connections.
# Input: TCP port integer.
# Output: boolean true when a local TCP connection succeeds.
sub _port_accepting_connections {
    my ( $self, $port ) = @_;
    return 0 if !defined $port || $port !~ /^\d+$/ || $port < 1;
    my $socket = IO::Socket::INET->new(
        PeerAddr => '127.0.0.1',
        PeerPort => $port,
        Proto    => 'tcp',
        Timeout  => 1,
    );
    return 0 if !$socket;
    close $socket;
    return 1;
}

# _read_process_env_marker($pid, $key)
# Reads a specific environment variable from a running process when possible.
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

# _same_pid_namespace($pid)
# Confirms whether a process id belongs to the current pid namespace so host
# and container runtimes do not manage each other's processes.
# Input: process id integer.
# Output: boolean true when both processes share the same pid namespace or when
# namespace metadata is unavailable on this platform.
sub _same_pid_namespace {
    my ( $self, $pid ) = @_;
    return 0 if !defined $pid || $pid !~ /^\d+$/ || $pid < 1;
    my $current = $self->_current_pid_namespace_id;
    my $target  = $self->_pid_namespace_id($pid);
    return 1 if !defined $current || $current eq '';
    return 1 if !defined $target  || $target eq '';
    return $current eq $target ? 1 : 0;
}

# _current_pid_namespace_id()
# Returns the current process pid-namespace identity string when procfs
# exposes one.
# Input: none.
# Output: namespace identity string or undef.
sub _current_pid_namespace_id {
    my ($self) = @_;
    return $self->_pid_namespace_id($$);
}

# _pid_namespace_id($pid)
# Reads the pid-namespace identity for one process from procfs when available.
# Input: process id integer.
# Output: namespace identity string or undef.
sub _pid_namespace_id {
    my ( $self, $pid ) = @_;
    my $path = "/proc/$pid/ns/pid";
    return if !-l $path;
    return readlink $path;
}

# _read_process_title($pid)
# Reads a process command line for matching and diagnostics.
# Input: process id integer.
# Output: command line string or undef.
sub _read_process_title {
    my ( $self, $pid ) = @_;
    my $proc = "/proc/$pid/cmdline";
    if ( $self->_procfs_available ) {
        my $cmdline = $self->_slurp_proc_file($proc);
        return if !defined $cmdline;
        if ( defined $cmdline && $cmdline ne '' ) {
            $cmdline =~ s/\0/ /g;
            $cmdline =~ s/\s+$//;
            return $cmdline;
        }
        return;
    }

    my ( $stdout, undef, $exit_code ) = capture {
        system 'ps', '-o', 'args=', '-p', $pid;
        return $? >> 8;
    };
    return if $exit_code != 0;
    $stdout =~ s/\s+$// if defined $stdout;
    return $stdout;
}

# _read_process_state($pid)
# Reads one process state code so lifecycle checks can distinguish live
# processes from zombie entries that still answer signal 0.
# Input: process id integer.
# Output: one-letter process state string or undef.
sub _read_process_state {
    my ( $self, $pid ) = @_;
    my $proc = "/proc/$pid/stat";
    if ( $self->_procfs_available ) {
        my $stat = $self->_slurp_proc_file($proc);
        return if !defined $stat;
        if ( defined $stat && $stat ne '' && $stat =~ /^\d+\s+\(.*\)\s+(\S)/s ) {
            return $1;
        }
        return;
    }

    my ( $stdout, undef, $exit_code ) = capture {
        system 'ps', '-o', 'stat=', '-p', $pid;
        return $? >> 8;
    };
    return if $exit_code != 0;
    $stdout =~ s/^\s+|\s+$//g if defined $stdout;
    return if !defined $stdout || $stdout eq '';
    return substr( $stdout, 0, 1 );
}

# _process_exists($pid)
# Checks whether one process id still exists from the current runtime view.
# Input: process id integer.
# Output: boolean true when signal 0 succeeds.
sub _process_exists {
    my ( $self, $pid ) = @_;
    return kill( 0, $pid ) ? 1 : 0;
}

# _procfs_available()
# Reports whether procfs-backed process inspection is available on the current host.
# Input: none.
# Output: boolean true when /proc exists and process readers should prefer it.
sub _procfs_available {
    return -d '/proc' ? 1 : 0;
}

# _slurp_proc_file($path)
# Reads one procfs-backed text payload when it is available on disk.
# Input: absolute procfs file path string.
# Output: file content string or undef when the proc entry is unreadable.
sub _slurp_proc_file {
    my ( $self, $path ) = @_;
    return if !defined $path || $path eq '';
    return if !-r $path;
    open my $fh, '<', $path or return;
    local $/;
    return scalar <$fh>;
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

Developer::Dashboard::RuntimeManager - runtime lifecycle manager

=head1 SYNOPSIS

  my $runtime = Developer::Dashboard::RuntimeManager->new(...);
  my $pid = $runtime->start_web;

=head1 DESCRIPTION

This module manages the lifecycle of the dashboard web service and managed
collector loops, including stop and restart orchestration plus the collector
watchdog that restarts unexpectedly-dead loops and records explicit
attention-required state after repeated crashes. Shutdown uses numeric POSIX
signals internally so minimal Perl builds that reject named signals still stop
managed processes correctly.

=head1 METHODS

=head2 new, start_web, running_web, stop_web, start_collectors, serve_all, stop_collectors, stop_all, restart_all, web_state, web_log

Construct and manage the dashboard runtime.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module manages the dashboard runtime processes. It starts, stops, and restarts the web listener, tracks the web pid, coordinates collector lifecycle around restart/stop flows, supervises managed collector loops with a watchdog, sends numeric POSIX shutdown signals for Alpine/iSH compatibility, and exposes the process-management behavior behind the serve/restart/stop command family.

=head1 WHY IT EXISTS

It exists because runtime lifecycle management needs one owner for pid files, process validation, restart ordering, watchdog restart thresholds, and port-release races. That keeps the browser server and collector loops moving together instead of leaving each command to improvise process control.

=head1 WHEN TO USE

Use this file when changing how the web process is launched, how restart waits for ports to free up, how collectors are stopped, restarted, or watchdog-supervised with the web process, or how runtime state is validated before a lifecycle command acts.

=head1 HOW TO USE

Construct it with the path registry and any required collaborators, then call the lifecycle methods from CLI helpers. Keep process orchestration here and let the command wrappers only parse arguments and print results.

=head1 WHAT USES IT

It is used by the C<dashboard serve>, C<dashboard restart>, and C<dashboard stop> helpers, by integration smoke that exercises lifecycle commands, and by tests that cover pid handling and process validation.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::RuntimeManager -e 1

Do a direct compile-and-load check against the module from a source checkout.

Example 2:

  prove -lv t/00-load.t t/21-refactor-coverage.t

Run the focused regression tests that most directly exercise this module's behavior.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite before release.


=for comment FULL-POD-DOC END

=cut
