package Developer::Dashboard::RuntimeManager;

use strict;
use warnings;

our $VERSION = '6.31';

use Capture::Tiny qw(capture);
use File::Spec;
use IO::Socket::INET;
use POSIX qw(close setsid);
use Time::HiRes qw(sleep time);

use Developer::Dashboard::Collector;
use Developer::Dashboard::CollectorRunner ();
use Developer::Dashboard::DirEntries qw(sorted_dir_entries);
use Developer::Dashboard::TimeUtils qw(_now_iso8601);
use Developer::Dashboard::InternalCLI ();
use Developer::Dashboard::JSON qw(json_encode json_decode json_decode_state);
use Developer::Dashboard::Platform qw(command_in_path is_windows);
use Developer::Dashboard::ProcessSupervision qw(
    _current_perl_command
    _perl_library_args
    _descriptor_is_inherited_pipe
    _open_file_descriptors
    _overwrite_state_file_in_place
    _pid_is_running
    _lifetime_owner_pid
    _lifetime_owner_is_gone
    _lifetime_owner_poll_seconds
    _pid_namespace_id
    _powershell_command
    _powershell_single_quote
    _taskkill_command
    _process_exists
    _read_process_env_marker
    _reap_child_process
    _rename_path
    _replace_state_file
    _source_is_movable
    _unlink_path
    _helper_file_supports_internal_command
    _same_pid_namespace
    _close_inherited_fds
    _dashboard_core_helper_path
);

our $SIGNAL_MANAGER;
our $COLLECTOR_SUPERVISOR_MANAGER;
# Root of the procfs tree probed by _procfs_available; tests point it at a
# missing directory to reach the no-procfs fallback on a Linux host.
our $PROCFS_ROOT = '/proc';

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
        collectors  => $args{collectors} ? $args{collectors} : Developer::Dashboard::Collector->new( paths => $paths ),
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
        local $ENV{DEVELOPER_DASHBOARD_WEB_SERVICE} = 1;
        local $ENV{DEVELOPER_DASHBOARD_WEB_HOST}    = $host;
        local $ENV{DEVELOPER_DASHBOARD_WEB_PORT}    = $port;
        local $ENV{DEVELOPER_DASHBOARD_WEB_WORKERS} = $workers;
        local $ENV{DEVELOPER_DASHBOARD_WEB_SSL}     = $ssl;
        local $0 = $self->_web_process_title( $host, $port );
        my $server = $self->{app_builder}->( host => $host, port => $port, workers => $workers, ssl => $ssl );
        return $server->run;
    }

    my $running = $self->running_web;
    return $running->{pid}
      if $running
      && $self->_running_web_satisfies_request( $running, $host, $port, $workers, $ssl );

    if (is_windows()) {
        return $self->_start_web_windows_background(
            host    => $host,
            port    => $port,
            workers => $workers,
            ssl     => $ssl,
        );
    }

    return $self->_start_web_background(
        host    => $host,
        port    => $port,
        workers => $workers,
        ssl     => $ssl,
    );
}

# serve_ssl_backend_foreground(%args)
# Rebuilds the normal web application in the isolated TLS backend helper and
# runs its Starman runner against the frontend's internal loopback endpoint.
# Input: internal host, internal port, and worker count.
# Output: backend runner exit status.
sub serve_ssl_backend_foreground {
    my ( $self, %args ) = @_;
    my $host = $args{host} // die 'Missing SSL backend host';
    my $port = $args{port} // die 'Missing SSL backend port';
    my $workers = $args{workers} // 1;
    die 'SSL backend port must be a positive integer' if $port !~ /\A\d+\z/ || $port < 1;
    die 'Worker count must be a positive integer' if $workers !~ /\A\d+\z/ || $workers < 1;
    my $server = $self->{app_builder}->(
        host    => $host,
        port    => $port,
        workers => $workers,
        ssl     => 1,
    );
    require Developer::Dashboard::Web::Server::Daemon;
    my $daemon = Developer::Dashboard::Web::Server::Daemon->new(
        host          => $host,
        port          => $port,
        internal_host => $host,
        internal_port => $port,
    );
    return $server->_run_ssl_backend_process($daemon);
}

# _start_web_background(%args)
# Launches the web listener as an independently supervised GoRoutine child and
# persists its identity after the configured endpoint accepts connections.
# Input: host, port, worker count, and ssl flag.
# Output: listener process id; dies with the child status if startup fails.
sub _start_web_background {
    my ( $self, %args ) = @_;
    my $host = defined $args{host} ? $args{host} : '0.0.0.0';
    my $port = defined $args{port} ? $args{port} : 7890;
    my $workers = defined $args{workers} ? $args{workers} : 1;
    my $ssl = $args{ssl} ? 1 : 0;

    $self->_cleanup_web_files;
    my @command = $self->_background_web_command(
        host    => $host,
        port    => $port,
        workers => $workers,
        ssl     => $ssl,
    );
    require Developer::Dashboard::GoRoutine;
    my $log = $self->{files}->dashboard_log;
    my $pid = Developer::Dashboard::GoRoutine::spawn(
        \@command,
        {
            stdin  => File::Spec->devnull(),
            stdout => $log,
            stderr => $log . '.stderr',
            env    => {
                DEVELOPER_DASHBOARD_WEB_SERVICE => 1,
                DEVELOPER_DASHBOARD_WEB_HOST    => $host,
                DEVELOPER_DASHBOARD_WEB_PORT    => $port,
                DEVELOPER_DASHBOARD_WEB_WORKERS => $workers,
                DEVELOPER_DASHBOARD_WEB_SSL     => $ssl,
            },
        },
    );
    die "Unable to launch dashboard web service process\n" if !$pid;

    for ( 1 .. $self->_runtime_stability_polls ) {
        my @listener_pids = $self->_listener_pids_for_port($port);
        if (@listener_pids && $self->_port_accepting_connections($port)) {
            my $listener_pid = $listener_pids[0];
            $listener_pid = $pid if !$listener_pid;
            # The spawned helper becomes the Starman master in-process, but
            # every worker also holds the listen socket, so the ss order may
            # list a worker first. Recording a worker means stop_web only
            # ever signals that worker directly: the master survives a stop
            # whenever listener discovery misses it (for example when the
            # persisted port is stale) and respawns a replacement worker.
            # Prefer the spawned pid whenever it is one of the listeners:
            # it is the master, and also our direct child, so it is the pid
            # stop_web can terminate and reap.
            $listener_pid = $pid if grep { $_ == $pid } @listener_pids;
            my $state = {
                host         => $host,
                pid          => $listener_pid,
                port         => $port + 0,
                process_name => $self->_web_process_title( $host, $port ),
                started_at   => _now_iso8601( tz => 'utc' ),
                status       => 'running',
                workers      => $workers + 0,
                ssl          => $ssl + 0,
            };
            $self->{files}->write( 'web_pid', "$listener_pid\n" );
            $self->_write_web_state($state);
            return $listener_pid;
        }
        sleep $self->_runtime_poll_interval;
    }

    Developer::Dashboard::GoRoutine::terminate_process( $pid, 'KILL' );
    my $exit = Developer::Dashboard::GoRoutine::wait_process($pid);
    die "Unable to start dashboard web service on $host:$port (child $pid exited with status $exit); see $log and $log.stderr\n";
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
        # The pid query runs on every poll, as the tests pin: a listener
        # is adopted as soon as the query reports it, even before the
        # port accepts connections. But the query's PowerShell fallback
        # costs ~5-9s per call on Windows (solo #351), and before the
        # child has bound there is no listener for it to find - every
        # pre-bind poll paid it. So the query is asked to run its
        # fallback only once the port accepts: the listener is then up,
        # netstat finds it directly in the normal case, and the fallback
        # runs at most once, for a live listener netstat cannot see
        # (build #98). The flag changes nothing when the port already
        # accepts, and nothing when netstat sees the listener.
        my @listener_pids = $self->_listener_pids_for_port( $port, 1 );
        if (@listener_pids) {
            my $listener_pid = $listener_pids[0];
            # See _start_web_background: prefer the spawned master pid over
            # a worker that ss happens to list first.
            $listener_pid = $pid if grep { $_ == $pid } @listener_pids;
            $running = {
                host         => $host,
                pid          => $listener_pid,
                port         => $port + 0,
                process_name => $self->_web_process_title( $host, $port ),
                started_at   => _now_iso8601( tz => "utc" ),
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
            pid          => $running->{pid} ? $running->{pid} : $pid,
            port         => $port + 0,
            process_name => $running->{process_name},
            started_at   => $running->{started_at},
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

# _running_web_satisfies_request($running, $host, $port, $workers, $ssl)
# Decides whether an already running web service satisfies a background start
# request. The endpoint decides identity and must be known: an unknown host or
# port is a mismatch, never an uninitialized-value warning. A property the
# persisted payload does not carry is unverifiable rather than different, so it
# never justifies forking a second listener onto an endpoint that already
# matches, which would strand the running child as an untrackable orphan.
# Input: running web state hash reference, requested host, port, worker count,
# and ssl flag.
# Output: boolean true when the running service already satisfies the request.
sub _running_web_satisfies_request {
    my ( $self, $running, $host, $port, $workers, $ssl ) = @_;
    return 0 if !defined $running->{host} || !defined $running->{port};
    return 0 if $running->{host} ne $host;
    return 0 if $running->{port} != $port;
    return 0 if defined $running->{workers} && $running->{workers} != $workers;
    return 0 if defined $running->{ssl} && $running->{ssl} != $ssl;
    return 1;
}

# _state_settle_polls()
# Returns how many times a lifecycle read re-checks a state file that exists but
# yields no usable payload before concluding there is no state to read. The
# budget stays small on purpose: the window it covers is a single file
# replacement, and every probe pays it when a state file is corrupt rather than
# merely mid-write.
# Input: none.
# Output: positive poll count integer.
sub _state_settle_polls {
    return 10;
}

# _state_settle_interval()
# Returns the pause between re-checks of a state file that exists but yields no
# usable payload.
# Input: none.
# Output: fractional seconds.
sub _state_settle_interval {
    return 0.01;
}

# _read_settled_web_state()
# Reads persisted web state for lifecycle decisions, tolerating the brief window
# in which an existing state file is observable as empty or partially written.
# The lifecycle uses this answer to deduplicate starts and to delete persisted
# files, so a transient observation must never be treated as a fact.
# Input: none.
# Output: two-element list of the state hash reference or undef, and a flag that
# is true when a state file exists but never yielded a usable payload.
sub _read_settled_web_state {
    my ($self) = @_;
    my $file  = $self->{files}->web_state;
    my $polls = $self->_state_settle_polls;
    for my $attempt ( 1 .. $polls ) {
        my $state = $self->web_state;
        return ( $state, 0 ) if ref($state) eq 'HASH';
        return ( undef, 0 ) if !-f $file;
        sleep $self->_state_settle_interval if $attempt < $polls;
    }
    return ( undef, 1 );
}

# _web_state_with_endpoint($state, $pid)
# Builds the running-web answer for one live managed pid, filling a host or port
# the persisted payload does not carry from the live process title. Callers
# compare the reported endpoint against a requested one, so a gap in the
# persisted payload must never surface as an unknown endpoint.
# Input: persisted state hash reference and live process id.
# Output: web state hash reference carrying the live pid.
sub _web_state_with_endpoint {
    my ( $self, $state, $pid ) = @_;
    my $running = {
        %{$state},
        pid => $pid + 0,
    };
    return $running if defined $running->{host} && defined $running->{port};

    my $title = $self->_read_process_title($pid);
    if ( defined $title && $title =~ /^d2 web:\s+(\S+):(\d+)$/ ) {
        $running->{host} = defined $running->{host} ? $running->{host} : $1;
        $running->{port} = defined $running->{port} ? $running->{port} : $2 + 0;
    }
    return $running;
}

# running_web()
# Discovers the currently running managed web service if present.
# Input: none.
# Output: web state hash reference or undef.
sub running_web {
    my ($self) = @_;

    my ( $settled, $unresolved ) = $self->_read_settled_web_state;
    my $state = $settled || {};
    if ( my $pid = $self->{files}->read('web_pid') ) {
        chomp $pid;
        $pid = $self->_normalized_process_id($pid);
        if ( $pid && $self->_pid_is_running($pid) && $self->_same_pid_namespace($pid) ) {
            if ( $self->_is_managed_web($pid) || ( $state->{status} || '' ) eq 'running' ) {
                return $self->_web_state_with_endpoint( $state, $pid );
            }
        }
    }

    for my $proc ( $self->_find_web_processes ) {
        if ( $proc->{args} =~ /^d2 web:\s+(\S+):(\d+)$/ ) {
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

    # A state file that exists but never yielded a usable payload is evidence of
    # nothing. Removing it here would destroy the persisted identity of a service
    # this probe merely failed to observe, so leave the files for the next read.
    return if $unresolved;

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
        # The POSIX branch below stops the saved ajax singleton workers
        # with the web service; the Windows branch never did, so stop_all
        # left them running (build #243 failed t/09 test 170 on Windows
        # with the ajax child still alive after stop_all). Mirror it:
        # TERM the managed ajax workers, then KILL the ones still alive
        # after the web shutdown wait. The ajax and legacy sweeps run
        # back to back over the same process table, so share one scan:
        # each full enumeration costs a PowerShell Get-CimInstance
        # Win32_Process (seconds on Windows, solo #351).
        my @stop_scan = $self->_ps_processes;
        my @ajax_workers = $self->_managed_ajax_processes( \@stop_scan );
        my @ajax_worker_pids = map { $_->{pid} } @ajax_workers;
        $self->_send_signal( 'TERM', @ajax_worker_pids ) if @ajax_worker_pids;
        # Same gap as the ajax workers above: the POSIX branch also
        # stops legacy d2 serve processes, the Windows branch never
        # did, so a stubborn legacy child survived stop_web (build
        # #246 failed t/09 test 186 on Windows). Mirror it the same way.
        my @legacy_web_pids = map { $_->{pid} } $self->_find_legacy_web_processes( \@stop_scan );
        $self->_send_signal( 'TERM', @legacy_web_pids ) if @legacy_web_pids;
        for ( 1 .. 30 ) {
            last if !$self->_wait_for_windows_web_shutdown( $pid, $port, \@listener_pids );
            sleep 0.1;
        }
        my @still_listening = grep { kill 0, $_ } @listener_pids;
        $self->_send_signal( 'KILL', $pid ) if $pid && kill 0, $pid;
        $self->_send_signal( 'KILL', @still_listening );
        my @lingering_ajax = grep { $self->_pid_is_running($_) } @ajax_worker_pids;
        $self->_send_signal( 'KILL', @lingering_ajax ) if @lingering_ajax;
        my @lingering_legacy = grep { $self->_pid_is_running($_) } @legacy_web_pids;
        $self->_send_signal( 'KILL', @lingering_legacy ) if @lingering_legacy;
        if ( $port && !$self->_wait_for_port_release($port) ) {
            my @late_listeners = grep { kill 0, $_ } $self->_listener_pids_for_port($port);
            $self->_send_signal( 'KILL', @late_listeners );
            $self->_wait_for_port_release($port);
        }
        # The POSIX branch below reaps the stopped children so a later
        # liveness check sees them gone; the Windows branch never did.
        # On Windows an exited GoRoutine child stays in the spawn
        # registry until it is reaped, and process_running reports
        # registry membership, so an unreaped listener still read as
        # running after stop_web (build #261 failed t/09 test 348 on
        # Windows; micro t/989 proved the child was dead and only the
        # registry entry survived). Mirror the reap here.
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

    $self->_send_signal( 'TERM', $pid ) if $pid;
    $self->_send_signal( 'TERM', @listener_pids );
    $self->_pkill_perl('^d2 web:');
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

# _managed_ajax_processes($rows)
# Returns dashboard Ajax singleton workers that belong to the current runtime so
# web stop and restart actions do not interfere with unrelated dashboard Ajax
# processes owned by the same user.
# Input: optional process-table rows (array reference as returned by
# _ps_processes) to search instead of scanning the table again; callers
# that already hold a scan pass its rows in.
# Output: list of ajax process hash references for the active runtime root.
#
# A real Ajax worker is found two ways. By its adopted title, `d2 ajax:
# <singleton>`, which _find_processes_by_prefix matches - on a host where
# the title is observable. And, where procfs exists, by its pre-exec
# environment marker DEVELOPER_DASHBOARD_AJAX_SINGLETON, which the worker
# is spawned with (see PageRuntime::_saved_ajax_env). The marker scan is
# what finds a real worker under qemu user-mode emulation: the worker's
# literal argv never contains 'd2 ajax:' (only the env var holds the
# singleton name, and the $0 assignment that would show it is invisible
# there), so the prefix scan alone can never see it. The scan is a no-op
# where there is no procfs (Windows, macOS): _read_process_env_marker
# reads nothing there, so nothing extra is ever matched. A worker's own
# children inherit its environ, so the scan can also match a descendant of
# a worker - that descendant belongs to the worker's subtree, and stopping
# it with the web runtime is the intended outcome, not a false positive.
sub _managed_ajax_processes {
    my ( $self, $rows ) = @_;
    my $runtime_root = $self->{paths} ? $self->{paths}->state_root : '';
    my @matches;
    my %seen_pid;
    for my $proc ( $self->_find_processes_by_prefix( 'd2 ajax:', $rows ) ) {
        my $marker = $self->_read_process_env_marker( $proc->{pid}, 'DEVELOPER_DASHBOARD_RUNTIME_ROOT' );
        next if defined $marker && $marker ne '' && $marker ne $runtime_root;
        next if defined $marker && $marker eq '' && $runtime_root ne '';
        next if !defined $marker && $self->_procfs_available && $runtime_root ne '';
        push @matches, $proc;
        $seen_pid{ $proc->{pid} } = 1;
    }
    if ( $self->_procfs_available ) {
        my @table = ref($rows) eq 'ARRAY' ? @{$rows} : $self->_ps_processes;
        for my $proc ( @table ) {
            next if $seen_pid{ $proc->{pid} };
            next if !$self->_proc_owned_by_current_user($proc);
            my $singleton = $self->_read_process_env_marker( $proc->{pid}, 'DEVELOPER_DASHBOARD_AJAX_SINGLETON' );
            next if !defined $singleton || $singleton eq '';
            my $marker = $self->_read_process_env_marker( $proc->{pid}, 'DEVELOPER_DASHBOARD_RUNTIME_ROOT' );
            next if defined $marker && $marker ne '' && $marker ne $runtime_root;
            next if defined $marker && $marker eq '' && $runtime_root ne '';
            next if !defined $marker && $runtime_root ne '';
            my $title = $self->_read_process_title( $proc->{pid} );
            push @matches, {
                %{$proc},
                args => ( defined $title && $title ne '' ? $title : $proc->{args} ),
            };
            $seen_pid{ $proc->{pid} } = 1;
        }
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

    # A REAP MUST LEAVE THE EXIT STATUS AND ERRNO AS IT FOUND THEM. The
    # supervisor runs this from its CHLD handler, and on Linux that handler
    # is delivered straight after a system() the supervisor made itself,
    # between the system() and the statement that reads its exit status.
    # The wait below then finds no child and sets $? to -1 and $! to
    # ECHILD, so "system ...; return $? >> 8" read a failed command where
    # the command had exited 0 - the listener lookup came back empty and
    # the supervisor did not recognise its own recorded web. Both values
    # are restored when this sub returns, whichever caller it has.
    local $?;
    local $!;
    if ( is_windows() ) {
        # waitpid(-1) cannot see GoRoutine (CreateProcess) children, so
        # there is no wait-any equivalent on Windows. The spawn registry
        # knows every GoRoutine child this process started; reap the ones
        # that have already exited from there instead.
        require Developer::Dashboard::GoRoutine;
        return Developer::Dashboard::GoRoutine::reap_any_exited();
    }
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
        my $schedule = _job_schedule($job);
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

    @targets = sort { $a->{name} cmp $b->{name} } @targets;
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
        for my $entry ( grep { /\.pid\z/ } sorted_dir_entries($dh) ) {
            my ($name) = $entry =~ /\A(.*)\.pid\z/;
            next if $name eq '' || $seen{$name}++;
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
        my $name = $job->{name} || '';
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

# _job_schedule($job)
# Resolves the schedule name of one collector job hash: the explicit schedule
# when present, otherwise cron, interval, or manual from the other fields.
# Input: collector job hash reference.
# Output: schedule name string (never empty).
sub _job_schedule {
    my ($job) = @_;
    return $job->{schedule} if $job->{schedule};
    return 'cron'     if $job->{cron};
    return 'interval' if $job->{interval};
    return 'manual';
}

# _loop_job_for_named_start($job)
# Normalizes one collector job into a loopable schedule for explicit named starts.
# Input: collector job hash reference.
# Output: collector job hash reference ready for CollectorRunner::start_loop.
sub _loop_job_for_named_start {
    my ( $self, $job ) = @_;
    my %loop_job = %{$job || {}};
    my $schedule = _job_schedule( \%loop_job );
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
        my $outcome = $self->_supervise_one_collector( $name, $running{$name} );
        next if !$outcome;
        push @{ $result{ $outcome->{bucket} } }, $outcome->{entry};
    }

    return \%result;
}

# _supervise_one_collector($name, $running_entry)
# Runs one watchdog pass for a single named collector: checks whether it is
# stalled or dead, stops and restarts it if the restart budget allows, and
# records the outcome via the same status-writing and logging calls the
# original inline loop body used.
# Input: collector name, and its running_loops entry if currently running
# (undef otherwise).
# Output: undef when the collector needed no action (running and healthy);
# otherwise a hash reference with "bucket" ('restarted' or 'attention') and
# "entry" (the hash to push onto that bucket).
sub _supervise_one_collector {
    my ( $self, $name, $running_entry ) = @_;

    my $job = eval { $self->_collector_job_by_name($name) };
    if ( !$job ) {
        my $error = $@;    # _collector_job_by_name always dies (setting $@) when it yields a false job, so $@ is the message
        $self->_mark_collector_watchdog_attention(
            $name,
            $error,
            restart_count => 0,
        );
        return { bucket => 'attention', entry => { name => $name, reason => $error } };
    }

    my $status = $self->{collectors}->read_status($name) || {};
    my $stalled = $running_entry
      ? $self->_collector_stalled_for_watchdog( $job, $status, $running_entry )
      : 0;
    return undef if $running_entry && !$stalled;

    my $stopped_stalled = 0;
    if ($running_entry) {
        my $ok = eval { $self->{runner}->stop_loop($name); 1 };
        if ( !$ok ) {
            my $error = $@;    # the failed stop_loop eval always leaves a truthy $@, so it carries the message
            chomp $error;
            $self->_mark_collector_watchdog_attention(
                $name,
                $error,
                restart_count => 0,
            );
            return { bucket => 'attention', entry => { name => $name, reason => $error } };
        }
        $stopped_stalled = 1;
    }

    my ( $restart_count, $window_started_at, $window_started_epoch ) =
      $self->_collector_watchdog_window($status);
    my $observed_at_epoch = time;
    my $observed_at = _now_iso8601( tz => "utc" );
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
        return { bucket => 'attention', entry => { name => $name, reason => $message } };
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
        return undef;
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
    return { bucket => 'restarted', entry => { name => $name, pid => $pid } };
}

# _collector_stalled_for_watchdog($job, $status, $running_entry)
# Detects when a managed scheduled collector loop is alive but has stopped
# making progress long enough that the watchdog should recycle it. Cron loops
# are judged by their scheduler heartbeat rather than job execution time, since
# a long gap between scheduled runs is expected behavior.
# Input: collector job hash reference, collector status hash reference, and
# optional running-loop entry containing persisted loop state.
# Output: boolean true when the collector is stalled.
sub _collector_stalled_for_watchdog {
    my ( $self, $job, $status, $running_entry ) = @_;
    return 0 if ref($job) ne 'HASH';
    return 0 if ref($status) ne 'HASH';

    my $latest_epoch;
    if ( _job_schedule($job) eq 'cron' ) {
        my $loop_state = ref($running_entry) eq 'HASH' && ref( $running_entry->{state} ) eq 'HASH'
          ? $running_entry->{state}
          : {};
        my $heartbeat = $loop_state->{heartbeat_at};
        return 0 if !defined $heartbeat || $heartbeat eq '';
        $latest_epoch = eval { $self->{collectors}->_iso8601_to_epoch($heartbeat) } || 0;
    }
    else {
        $latest_epoch = $self->_collector_watchdog_last_progress_epoch($status);
    }
    return 0 if !$latest_epoch;
    my $stale_after = $self->_collector_watchdog_stale_seconds($job);
    return 0 if $stale_after < 1;
    # A loop that started less than one stale window ago cannot be stalled.
    # Its first run has not had a full window in which to happen yet, and
    # the collector status still carries the pre-start last-run timestamp,
    # so judging the fresh loop on that timestamp restarts a healthy loop
    # (t/05 test 319, round 78: the supervisor's first poll landed before
    # the fresh loop's first run and restarted it on the stale timestamp).
    if ( ref($running_entry) eq 'HASH' && ref( $running_entry->{state} ) eq 'HASH' ) {
        my $started_at = $running_entry->{state}->{started_at};
        if ( defined $started_at && $started_at ne '' ) {
            my $started_epoch = eval { $self->{collectors}->_iso8601_to_epoch($started_at) } || 0;
            return 0 if $started_epoch && time - $started_epoch < $stale_after;
        }
    }
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
        $window_at = _now_iso8601( tz => "utc" );
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
    my $observed_at = $args{observed_at} ? $args{observed_at} : _now_iso8601( tz => "utc" );
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
    chomp $message;
    my $timestamp = _now_iso8601( tz => "utc" );
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
            updated_at   => _now_iso8601( tz => "utc" ),
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

    require Developer::Dashboard::GoRoutine;
    my @command = $self->_background_collector_supervisor_command;
    my $log = $self->{files}->collector_log;
    # The supervisor marker travels in the INITIAL environ, exactly like
    # the web marker: the kernel environ block is fixed at exec, so the
    # post-exec $ENV assignment in _run_collector_supervisor_child was
    # invisible to /proc readers on every platform. The child deletes it
    # from %ENV on entry, so a collector loop it restarts cannot inherit
    # it and be mistaken for a supervisor.
    my $pid = Developer::Dashboard::GoRoutine::spawn(
        \@command,
        {
            stdin  => File::Spec->devnull(),
            stdout => $log,
            stderr => $log . '.stderr',
            env    => { DEVELOPER_DASHBOARD_COLLECTOR_SUPERVISOR => 1 },
        },
    );
    die "Unable to launch detached collector supervisor process\n" if !$pid;

    my $pidfile = $self->_collector_supervisor_pidfile;
    open my $fh, '>', $pidfile or die "Unable to write $pidfile: $!";
    if ( !print {$fh} $pid ) {
        my $error = $!;
        CORE::close($fh);
        die "Unable to write collector supervisor pid to $pidfile: $error";
    }
    CORE::close($fh) or die "Unable to close collector supervisor pidfile $pidfile: $!";
    $self->{paths}->secure_file_permissions($pidfile);
    $self->_write_collector_supervisor_state(
        {
            %{$state},
            pid          => $pid,
            process_name => $self->_collector_supervisor_process_title,
            status       => 'running',
            started_at   => _now_iso8601( tz => "utc" ),
            heartbeat_at => _now_iso8601( tz => "utc" ),
        }
    );
    return $pid;
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

    # The supervisor marker is NOT assigned here any more. It arrives in
    # the child's INITIAL environ (see _start_collector_supervisor): the
    # kernel environ block is fixed at exec, so a post-exec $ENV assignment
    # is invisible to /proc readers and the marker was a dead recognition
    # path. It is deleted from %ENV instead, before any collector is
    # supervised, so a loop this supervisor restarts cannot inherit it and
    # be mistaken for a supervisor itself. The delete also removes the
    # marker from the supervisor's own /proc environ block (Perl's delete
    # calls unsetenv, which rewrites that block), so after the first ~0.2s
    # of boot no recognition path sees the marker; only the process title
    # and the helper-command shape can identify the supervisor.
    delete $ENV{DEVELOPER_DASHBOARD_COLLECTOR_SUPERVISOR};
    local $0 = $self->_collector_supervisor_process_title;
    local $COLLECTOR_SUPERVISOR_MANAGER = $self;
    my $shutdown = sub { $self->_shutdown_collector_supervisor('stopped') };
    local $SIG{CHLD} = sub {
        $COLLECTOR_SUPERVISOR_MANAGER->_reap_any_child_processes;
        return;
    };
    local $SIG{TERM} = $shutdown;
    local $SIG{INT}  = $shutdown;
    local $SIG{HUP}  = $shutdown;

    # The adopted serve (web) parent the supervisor follows, kept across
    # loop iterations: pid once a live web pid has been seen, and the
    # epoch the adopted parent was first seen dead. Empty until the
    # first live web pid is adopted, so a supervisor started before its
    # web (restart) or with no web at all (standalone collectors) never
    # exits on a parent it never had.
    my $serve_parent = {};

    # Epoch since which no watched loop has been running, for the
    # quiesce check below. Undef while any watched loop is alive.
    my $no_live_work_since;

    # The process this whole runtime's lifetime is tied to, when the
    # starter opted in through DEVELOPER_DASHBOARD_LIFETIME_PID, and how
    # many polls in a row it has been seen dead. Undef pid when the
    # starter did not opt in, which is every ordinary user.
    my $lifetime_owner = { pid => $self->_lifetime_owner_pid, dead_polls => 0 };

    while (1) {
        $self->_reap_any_child_processes;
        my $state = $self->_collector_supervisor_state || {};
        my @targets = $self->_normalized_collector_watch_names( $state->{watched_names} );
        if ( !@targets ) {
            $self->_shutdown_collector_supervisor('stopped');
        }
        $self->_check_collector_supervisor_parent( \@targets, $serve_parent );
        $self->_check_collector_supervisor_lifetime_owner( \@targets, $lifetime_owner );
        $self->_write_collector_supervisor_state(
            {
                %{$state},
                pid          => $$,
                process_name => $self->_collector_supervisor_process_title,
                status       => 'running',
                heartbeat_at => _now_iso8601( tz => "utc" ),
            }
        );
        eval { $self->_supervise_collectors_once( names => \@targets ) };
        if ($@) {
            my $error = "$@";
            chomp $error;
            $self->{files}->append( 'collector_log', sprintf "[%s][watchdog] %s\n", _now_iso8601( tz => "utc" ), $error );
            $self->_write_collector_supervisor_state(
                {
                    %{$state},
                    pid          => $$,
                    process_name => $self->_collector_supervisor_process_title,
                    status       => 'error',
                    error        => $error,
                    heartbeat_at => _now_iso8601( tz => "utc" ),
                }
            );
        }
        # Quiesce: a supervisor with no adopted parent (no web at all,
        # for example a standalone collector start) and no live watched
        # loop for a continuous period has nothing left to watch, so it
        # exits instead of idling forever over dead loops. The timer
        # resets whenever any watched loop is running, so a healthy
        # supervisor never quiesces. A clean `d2 stop` already stops
        # the supervisor, so this only covers the killed-run case,
        # where no stop ever runs; _start_collector_supervisor
        # respawns on the next collector start. When the loop scan
        # itself fails, stay alive rather than quiescing blind.
        if ( !defined $serve_parent->{pid} ) {
            my @live = eval { $self->{runner}->running_loops };
            my $scan_failed = $@ ? 1 : 0;
            my %watched = map { $_ => 1 } @targets;
            my $any_live = $scan_failed
              || scalar grep { $watched{ $_->{name} } } @live;
            if ($any_live) {
                $no_live_work_since = undef;
            }
            else {
                $no_live_work_since = time if !defined $no_live_work_since;
                if ( time - $no_live_work_since >= $self->_collector_supervisor_quiesce_seconds ) {
                    $self->_shutdown_collector_supervisor('quiesced');
                }
            }
        }
        sleep $self->_collector_supervisor_poll_interval;
    }
}

# _is_starman_worker($pid)
# Reports whether a pid is a Starman worker process. Workers hold the
# listen socket like the master, so listener discovery can record one
# in web.json, but a worker never dies on its own, so it must never be
# adopted as a supervisor parent. Starman sets a worker's title to
# "starman worker ..." and the master's to "starman master ...". An
# unreadable title is not a worker: adoption keeps its previous
# behaviour when the title cannot be read.
# Input: process id integer.
# Output: boolean true when the process title starts with "starman worker".
sub _is_starman_worker {
    my ( $self, $pid ) = @_;
    return 0 if !defined $pid || $pid !~ /\A\d+\z/ || $pid <= 0;
    my $title = $self->_read_process_title($pid);
    return 0 if !defined $title;
    return $title =~ /\Astarman worker\b/ ? 1 : 0;
}

# _check_collector_supervisor_parent($targets, $parent)
# Adopts the serve (web) pid as the supervisor's parent and exits
# once that parent has been dead longer than the grace period, stopping
# the watched loops on the way out. The spawner pid is deliberately NOT
# followed: restart and collector-start flows spawn the supervisor from
# short-lived CLI processes, so spawner-following would kill a healthy
# supervisor seconds after every restart. Adoption takes a dead pid as
# well as a live one, with dead_since starting at adoption, so a
# supervisor that starts after its web has already died still exits
# once the grace expires instead of idling forever; a new live web
# re-adopts on the next poll before the grace expires. A live Starman
# worker is never adopted: workers hold the listen socket like the
# master, so listener discovery can record one in web.json, but a
# worker never dies on its own, so a supervisor that adopts it stays
# alive forever. When web.json names a live worker and no parent is
# adopted, no adoption happens and the quiesce check applies; when an
# adopted parent is still alive, it still decides. A supervisor
# with no web at all (standalone collectors) never adopts here and
# keeps running while its loops are alive; once all its watched loops
# have been dead for the quiesce period it exits via the quiesce check
# in _run_collector_supervisor_child. Parent liveness is _pid_is_running,
# which is already platform-aware, so the identical code path runs on
# Windows; no getppid() anywhere (unimplemented on Strawberry Perl).
# Input: watched collector names array reference, and the parent-state
# hash reference the caller keeps across loop iterations.
# Output: never returns once the adopted parent has been dead past the
# grace period; otherwise undef.
sub _check_collector_supervisor_parent {
    my ( $self, $targets, $parent ) = @_;
    my $web = eval { $self->web_state };
    my $web_pid;
    if ( !$@ && $web && defined $web->{pid} && $web->{pid} =~ /\A\d+\z/ && $web->{pid} > 0 ) {
        $web_pid = $web->{pid} + 0;
    }
    my $web_running = defined $web_pid && $self->_pid_is_running($web_pid);
    if ($web_running) {
        if ( defined $parent->{pid} && $parent->{pid} == $web_pid ) {
            # Same pid as already adopted: refresh the grace and stay.
            # The title was checked at adoption, so there is no
            # per-poll title read here; on Windows a title read costs
            # a full process-table enumeration.
            $parent->{dead_since} = undef;
            return;
        }
        if ( $self->_is_starman_worker($web_pid) ) {
            # A live worker is not a parent. A live adopted parent
            # still decides (web.json can name a worker after a
            # restart that recorded one); otherwise no adoption
            # happens and the quiesce check applies.
            return if defined $parent->{pid} && $self->_pid_is_running( $parent->{pid} );
        }
        else {
            $parent->{pid}        = $web_pid;
            $parent->{dead_since} = undef;
            return;
        }
    }
    if ( defined $web_pid && !defined $parent->{pid} && !$web_running ) {
        # Adopt a dead web pid as well. A supervisor that starts after
        # its web has already died (or whose web.json names a pid from
        # an earlier run) would otherwise never adopt and never exit.
        # dead_since starts now, so the grace period still covers a
        # restart handover, and a new live web re-adopts on the next
        # poll before the grace expires.
        $parent->{pid}        = $web_pid;
        $parent->{dead_since} = time;
    }
    return if !defined $parent->{pid};
    $parent->{dead_since} = time if !defined $parent->{dead_since};
    return if time - $parent->{dead_since} < $self->_collector_supervisor_parent_grace_seconds;
    for my $name ( @{$targets} ) {
        eval { $self->{runner}->stop_loop($name); 1 };
    }
    $self->_shutdown_collector_supervisor('parent-gone');
}

# _check_collector_supervisor_lifetime_owner($targets, $owner)
# Ends the whole runtime once the opted-in lifetime owner is dead: stops
# the watched loops, stops this runtime's own recorded web process, then
# shuts the supervisor down. The owner must be seen dead on two polls in a row, so one failed
# liveness probe cannot end a healthy runtime. Liveness is
# _pid_is_running, the same platform-aware check the serve-parent guard
# uses, so the identical path runs on Windows. A stop that fails is not
# allowed to keep the supervisor alive, and it is not silent either: the
# supervisor writes to the global collector log whether it stopped its
# recorded web process (naming owner pid and web pid), whether that
# stop died (with the error), or whether the recorded pid was running
# but not recognised as a managed web and so left alone. No recorded
# web, or one already gone, needs no line.
# Input: watched collector names array reference, and the owner-state
# hash reference the caller keeps across loop iterations (pid,
# dead_polls).
# Output: never returns once the owner has been confirmed dead;
# otherwise undef.
sub _check_collector_supervisor_lifetime_owner {
    my ( $self, $targets, $owner ) = @_;
    return if !$self->_lifetime_owner_is_gone($owner);
    for my $name ( @{$targets} ) {
        eval { $self->{runner}->stop_loop($name); 1 };
    }
    my $prefix = "lifetime owner gone; lifetime owner pid $owner->{pid} is gone;";
    my ( $recorded, $stopped );
    my $finished = eval {
        $recorded = $self->_recorded_web_pid_for_lifetime_owner;
        $stopped  = $self->_stop_recorded_web_for_lifetime_owner;
        1;
    };
    my $error = $@;
    eval {
        my $named = defined $recorded ? "recorded web pid $recorded" : 'the recorded web process';
        if ( !$finished ) {
            $error = 'unknown error' if !defined $error || !length $error;
            $self->_log_collector_supervisor_lifetime_event(
                "web not stopped: $prefix the stop attempt on $named died: $error");
        }
        elsif ($stopped) {
            $self->_log_collector_supervisor_lifetime_event("web stopped: $prefix web pid $stopped is stopping");
        }
        elsif ( defined $recorded && $self->_pid_is_running($recorded) ) {
            $self->_log_collector_supervisor_lifetime_event(
                "web not stopped: $prefix recorded web pid $recorded is not recognised as a managed dashboard web process and is left alone"
            );
        }
        1;
    };
    $self->_shutdown_collector_supervisor('lifetime-owner-gone');
}

# _log_collector_supervisor_lifetime_event($message)
# Appends one line to the global collector log saying what the collector
# supervisor did because its lifetime owner is gone. That is the one log
# a supervisor can always write to: it is the file its own watchdog
# events already go to, it lives under this runtime's logs root, and it
# belongs to no single collector, where the web owner watcher's log is
# named after a web pid the supervisor may not even have. A failed write
# is silent: a missing log line must never keep the supervisor alive.
# Input: message text without time stamp or line ending.
# Output: 1 when the line was written, otherwise undef.
sub _log_collector_supervisor_lifetime_event {
    my ( $self, $message ) = @_;
    return if !defined $message || !length $message;
    $message =~ s/\s+/ /g;
    $message =~ s/\A | \z//g;
    my $written = eval {
        $self->{files}->append( 'collector_log',
            sprintf "[%s][supervisor][lifetime-owner] %s\n", _now_iso8601( tz => 'utc' ), $message );
        1;
    };
    return $written ? 1 : undef;
}

# _recorded_web_pid_for_lifetime_owner()
# Reads the web pid this runtime itself recorded.
# Input: none.
# Output: pid integer, or undef when none is recorded or it is malformed.
sub _recorded_web_pid_for_lifetime_owner {
    my ($self) = @_;
    my $pid = $self->{files}->read('web_pid');
    return undef if !defined $pid;
    chomp $pid;
    return undef if $pid !~ /\A\d+\z/ || $pid < 1;
    return $pid + 0;
}

# _stop_recorded_web_for_lifetime_owner()
# Stops the one web process this runtime itself recorded, and nothing
# else. stop_web is deliberately not used here: it also ends every
# 'd2 web:' process on the machine by name, which is right for a user
# running `d2 stop` but wrong for a supervisor acting on its own some
# seconds after its owner died, when a different runtime (the next test
# run, for one) may already be up. The recorded pid is only signalled
# while it still proves to be a managed dashboard web process, so a pid
# that has been reused by something else is left alone. TERM first, a
# short wait, then KILL if it is still there.
# Input: none.
# Output: stopped web pid integer, or undef when there was nothing of
# this runtime's to stop.
sub _stop_recorded_web_for_lifetime_owner {
    my ($self) = @_;
    my $pid = $self->_recorded_web_pid_for_lifetime_owner;
    return if !defined $pid;
    return if !$self->_pid_is_running($pid) || !$self->_is_managed_web($pid);
    return $self->_stop_web_pid_for_lifetime_owner($pid);
}

# _stop_web_pid_for_lifetime_owner($pid)
# Stops one web process by pid and nothing else: TERM first, a short
# wait, then KILL if it is still there. It stops the pid only while it
# still proves to be a managed dashboard web process, the same proof
# _stop_recorded_web_for_lifetime_owner makes: if the web process died
# and its pid was reused by an unrelated program, the pid is left alone.
# The proof is the env-marker read first, so a real web process passes
# it without touching runtime state; the state read behind it is only
# reached when the marker is absent, which is the case the guard exists
# for. That state read needs this object's file registry, so this must
# be called on a real object, never on the class name. Nothing is looked
# up by name here, for the reason given at
# _stop_recorded_web_for_lifetime_owner.
# Input: web process id integer.
# Output: the pid that was signalled, or undef when it is not stopped.
sub _stop_web_pid_for_lifetime_owner {
    my ( $self, $pid ) = @_;
    return if !$self->_pid_is_running($pid) || !$self->_is_managed_web($pid);
    $self->_send_signal( 'TERM', $pid );
    for ( 1 .. 30 ) {
        return $pid if !$self->_pid_is_running($pid);
        sleep $self->_runtime_poll_interval;
    }
    $self->_send_signal( 'KILL', $pid );
    return $pid;
}

# _web_watcher_spares_itself()
# Says whether the web owner watcher must stop its web without a tree
# kill. On Windows the watcher is a child of the web it watches, and the
# ordinary stop there is a whole-tree kill of the web, which ends the
# watcher inside its own stop before it can confirm anything or write a
# line (Jenkins run-tests #75). Everywhere else a signal to the web pid
# reaches that pid alone and the watcher outlives it.
# Input: none.
# Output: 1 on Windows, otherwise 0.
sub _web_watcher_spares_itself {
    return is_windows() ? 1 : 0;
}

# _web_watcher_tree_looks()
# Returns how many times the watcher lists the web's tree in one stop:
# the first listing, then looks for a child born after it.
# Input: none.
# Output: integer number of looks.
sub _web_watcher_tree_looks {
    return 3;
}

# _windows_process_tree_rows()
# Lists every process with its parent process id and its start time, so
# a caller can walk a process tree itself instead of asking taskkill
# for a tree kill. The start time is the creation time in ticks, a
# plain run of digits; it is empty when the system does not give one.
# Input: none.
# Output: array reference of hash references with pid, ppid and started
# keys, or undef when the listing could not be made.
sub _windows_process_tree_rows {
    my ($self) = @_;
    local $?;
    my $powershell = _powershell_command;
    return if !length $powershell;
    my ( $stdout, undef, $exit_code ) = capture {
        system(
            $powershell,
            '-NoLogo',
            '-NoProfile',
            '-Command',
            q{$ErrorActionPreference = 'Stop'; Get-CimInstance Win32_Process | ForEach-Object { $t = ''; if ($null -ne $_.CreationDate) { $t = $_.CreationDate.ToUniversalTime().Ticks.ToString() }; [Console]::Out.WriteLine($_.ProcessId.ToString() + [char]9 + $_.ParentProcessId.ToString() + [char]9 + $t) }},
        );
        return $? >> 8;
    };
    return if $exit_code != 0 || !defined $stdout;
    my @rows;
    for my $line ( split /\n/, $stdout ) {
        next if $line !~ /^\s*(\d+)\t(\d+)\t(\d*)\s*$/;
        push @rows, { pid => $1 + 0, ppid => $2 + 0, started => $3 };
    }
    return if !@rows;
    return \@rows;
}

# _process_started_not_before($child_started, $parent_started)
# Compares two start times given as runs of digits. A real child never
# starts before its parent, so a process that names a parent pid but is
# older than the process holding that pid is not its child: the pid was
# reused. A start time that cannot be read proves nothing.
# Input: child start time string, parent start time string.
# Output: 1 when both are readable and the child is not older, else 0.
sub _process_started_not_before {
    my ( $child, $parent ) = @_;
    return 0 if !defined $child  || $child  !~ /\A\d+\z/;
    return 0 if !defined $parent || $parent !~ /\A\d+\z/;
    $child  =~ s/\A0+(?=\d)//;
    $parent =~ s/\A0+(?=\d)//;
    return length $child > length $parent ? 1 : 0 if length $child != length $parent;
    return $child ge $parent ? 1 : 0;
}

# _descendant_pids_sparing($rows, $roots, $spare_pid)
# Walks a process listing down from the given tree members and returns
# every process below them that is not itself one of them, deepest
# first. The members are given with their start times, so a member that
# has already ended and left the listing still anchors the walk: a child
# keeps naming its parent pid after the parent is gone. The spared pid
# is never returned and nothing below it is walked, so the caller and
# its own helper commands are left out. A process is only taken as a
# child when its start time shows it is not older than its parent; one
# that fails that check is returned as refused instead and nothing
# below it is walked.
# Input: array reference of listing rows, hash reference of member pid
# to start time string, pid to spare.
# Output: two array references: [pid, start time] pairs to stop, deepest
# first, and refused pids with the reason, as "pid: reason" strings.
sub _descendant_pids_sparing {
    my ( $self, $rows, $roots, $spare_pid ) = @_;
    my %children;
    push @{ $children{ $_->{ppid} } }, $_ for grep { $_->{pid} != $_->{ppid} } @{ $rows || [] };
    my ( @found, @refused );
    my %seen  = map { $_ => 1 } keys %{ $roots || {} };
    my @queue = map { [ $_, $roots->{$_}, 0 ] } sort { $a <=> $b } keys %{ $roots || {} };
    while ( my $item = shift @queue ) {
        my ( $pid, $started, $depth ) = @{$item};
        for my $row ( sort { $a->{pid} <=> $b->{pid} } @{ $children{$pid} || [] } ) {
            next if $seen{ $row->{pid} }++;
            next if defined $spare_pid && $row->{pid} == $spare_pid;
            if ( !_process_started_not_before( $row->{started}, $started ) ) {
                my $why = defined $row->{started} && $row->{started} =~ /\A\d+\z/
                  ? 'it is older than the process holding its parent pid, so that pid was reused'
                  : 'a start time could not be read';
                push @refused, "$row->{pid}: $why";
                next;
            }
            push @found, [ $row->{pid}, $row->{started}, $depth + 1 ];
            push @queue, [ $row->{pid}, $row->{started}, $depth + 1 ];
        }
    }
    my @ordered = map { [ $_->[0], $_->[1] ] } sort { $b->[2] <=> $a->[2] || $a->[0] <=> $b->[0] } @found;
    return ( \@ordered, \@refused );
}

# _kill_exact_pids(@pids)
# Ends each given process by its exact pid on Windows, one taskkill per
# pid and never the tree option, in the order given.
# Input: process id values.
# Output: number of pids taskkill reported ended or already gone.
sub _kill_exact_pids {
    my ( $self, @pids ) = @_;
    local $?;
    my $ended = 0;
    for my $pid ( grep { defined $_ && /^\d+$/ && $_ > 0 } @pids ) {
        my @taskkill = ( _taskkill_command, '/PID', $pid, '/F' );
        my ( $stdout, $stderr, $exit_code ) = capture {
            system @taskkill;
            return $? >> 8;
        };
        $ended++ if $exit_code == 0 || join( ' ', grep { defined } $stdout, $stderr ) =~ /not found/i;
    }
    return $ended;
}

# _stop_web_pid_as_its_watcher($pid, $log_path, $prefix)
# The stop the web owner watcher itself makes. Off Windows it is exactly
# _stop_web_pid_for_lifetime_owner. On Windows the watcher is a child of
# the web, so it lists the web's tree, leaves its own pid out, ends each
# descendant by exact pid, deepest first, then the web pid, and looks
# again for a child born in between; it then waits for the web pid to
# go, as the ordinary stop does. Nothing here writes the line that says
# the web was stopped: the caller writes it after this returns. What it
# does write is what it left alone and why. When the tree cannot be
# listed it says so, says that the tree kill it falls back to will end
# this watcher as well, and makes that tree kill, so no part of the tree
# is left behind for want of a listing.
# Input: web process id integer, log file path string or undef, the text
# that names the dead owner at the start of each line.
# Output: the pid that was stopped, or undef when it is not stopped.
sub _stop_web_pid_as_its_watcher {
    my ( $self, $pid, $log_path, $prefix ) = @_;
    return $self->_stop_web_pid_for_lifetime_owner($pid) if !$self->_web_watcher_spares_itself;
    return if !$self->_pid_is_running($pid) || !$self->_is_managed_web($pid);
    $prefix = '' if !defined $prefix;
    my $rows = $self->_windows_process_tree_rows;
    my ($root) = grep { $_->{pid} == $pid } @{ $rows || [] };
    if ( !$rows || !$root || !defined $root->{started} || $root->{started} !~ /\A\d+\z/ ) {
        $self->_log_web_lifetime_owner_event( $log_path,
            "web tree not listed: $prefix the process tree of web pid $pid could not be listed with start times; falling back to a whole-tree kill of web pid $pid, which ends watcher pid $$ as well, so no further line follows from this watcher" );
        return $self->_stop_web_pid_for_lifetime_owner($pid);
    }
    my $looks = $self->_web_watcher_tree_looks;
    my %known = ( $pid => $root->{started} );
    my %refused;
    for my $look ( 1 .. $looks ) {
        if ( $look > 1 ) {
            $rows = $self->_windows_process_tree_rows;
            last if !$rows;
        }
        my ( $found, $refused ) = $self->_descendant_pids_sparing( $rows, \%known, $$ );
        $refused{$_} = 1 for @{$refused};
        my @targets = map { $_->[0] } @{$found};
        if ( $look == 1 ) {
            push @targets, $pid;
        }
        else {
            push @targets,
              map { $_->{pid} }
              grep { exists $known{ $_->{pid} } && defined $_->{started} && $_->{started} eq $known{ $_->{pid} } } @{$rows};
        }
        $known{ $_->[0] } = $_->[1] for @{$found};
        last if !@targets;
        $self->_kill_exact_pids(@targets);
    }
    $self->_log_web_lifetime_owner_event( $log_path,
        "web tree member left alone: $prefix under web pid $pid, pid $_" )
      for sort keys %refused;
    for ( 1 .. 30 ) {
        return $pid if !$self->_pid_is_running($pid);
        sleep $self->_runtime_poll_interval;
    }
    $self->_kill_exact_pids($pid);
    return $pid;
}

# _log_web_lifetime_owner_event($log_path, $text)
# Appends one time-stamped line to the web owner watcher's log. Every
# line the watcher writes goes through here. A failed write is silent:
# a missing log must never keep the watcher alive or change its exit
# status.
# Input: log file path string (undef means no log is kept) and the line
# text without its time stamp or line ending.
# Output: 1 when the line was written, otherwise undef.
sub _log_web_lifetime_owner_event {
    my ( $self, $log_path, $text ) = @_;
    return if !defined $log_path || !length $log_path;
    return if !defined $text     || !length $text;
    $text =~ s/\s+/ /g;
    $text =~ s/\A | \z//g;
    open my $fh, '>>', $log_path or return;
    print {$fh} _now_iso8601( tz => 'utc' ) . " $text\n";
    CORE::close $fh;
    return 1;
}

# _log_web_lifetime_owner_stop($log_path, $owner_pid, $web_pid)
# Writes the one line that says a web process was stopped because its
# lifetime owner is gone, naming both pids, so a later reader has
# positive evidence the stop happened. A failed write is silent: the
# watcher has already stopped the web process, and a missing log must
# never keep it alive or change its exit status.
# Input: log file path string (undef means no log is kept), owner pid
# integer, web pid integer.
# Output: 1 when the line was written, otherwise undef.
sub _log_web_lifetime_owner_stop {
    my ( $self, $log_path, $owner_pid, $web_pid ) = @_;
    return if !defined $owner_pid || !defined $web_pid;
    return $self->_log_web_lifetime_owner_event( $log_path,
        "web stopped: lifetime owner gone; lifetime owner pid $owner_pid is gone; web pid $web_pid is stopping" );
}

# _web_lifetime_owner_watcher_object()
# Builds the runtime manager object the web owner watcher process works
# on. The watcher is started as a bare perl that calls
# _run_web_lifetime_owner_watcher on the class name, but the proof that
# a pid is a managed dashboard web process reads the persisted web state
# whenever the env-marker read gives nothing, and that read needs a file
# registry. The object must resolve the same state folder as the web
# process that started the watcher, or the watcher would look for
# web.json where its own web never wrote it. So the path registry is
# built exactly the way the private helper that serves the web builds
# its own (see _web_lifetime_owner_watcher_paths), and the file registry
# on those paths. The state folder itself is resolved from the home
# directory, the environment and the working directory, all of which
# the watcher inherits unchanged from the web process at the moment it
# is started. The configured file aliases that helper also registers
# are deliberately not read here: the web state file is always reached
# through the file registry's own web_state accessor, which no alias
# can redirect, and reading the whole configuration would give the
# watcher a way to fail that its web does not have once it is serving.
# The app builder refuses to run, because a watcher never serves.
# Input: none; called on the class name or on an object.
# Output: Developer::Dashboard::RuntimeManager object (an object
# invocant is returned as it is).
sub _web_lifetime_owner_watcher_object {
    my ($class) = @_;
    return $class if ref $class;
    require Developer::Dashboard::Config;
    require Developer::Dashboard::FileRegistry;
    require Developer::Dashboard::IndicatorStore;
    require Developer::Dashboard::PathRegistry;
    my $paths      = $class->_web_lifetime_owner_watcher_paths;
    my $files      = Developer::Dashboard::FileRegistry->new( paths => $paths );
    my $collectors = Developer::Dashboard::Collector->new( paths => $paths );
    return $class->new(
        app_builder => sub { die "the web lifetime owner watcher never serves\n" },
        collectors  => $collectors,
        config      => Developer::Dashboard::Config->new( files => $files, paths => $paths ),
        files       => $files,
        paths       => $paths,
        runner      => Developer::Dashboard::CollectorRunner->new(
            collectors => $collectors,
            files      => $files,
            indicators => Developer::Dashboard::IndicatorStore->new( paths => $paths ),
            paths      => $paths,
        ),
    );
}

# _web_lifetime_owner_watcher_paths()
# Builds the path registry for the web owner watcher with the same
# arguments the private helper that serves the web gives its own
# (share/private-cli/_dashboard-core): the existing projects, src and
# work folders under the home directory as both workspace roots and
# project roots, and nothing else, so home, working directory and
# environment are read the same way in both processes. The home
# directory is the one the path registry itself resolves, which is the
# value that helper has already put in HOME before it starts anything.
# Input: none; called on the class name or on an object.
# Output: Developer::Dashboard::PathRegistry object.
sub _web_lifetime_owner_watcher_paths {
    require Developer::Dashboard::PathRegistry;
    my $home = Developer::Dashboard::PathRegistry::_resolved_home_from_env();
    my @roots = defined $home && $home ne '' ? grep { -d } map { "$home/$_" } qw(projects src work) : ();
    return Developer::Dashboard::PathRegistry->new(
        workspace_roots => [@roots],
        project_roots   => [@roots],
    );
}

# _web_pid_outlives_stop_confirm($pid)
# Says whether a web pid the watcher has just signalled is still running
# after a short bounded wait. The stop returns straight after its last
# signal, and a process that has just been signalled can still be seen
# for an instant, so one look straight away could report a web process
# as still running when it is already on its way out. This looks up to
# _web_stop_confirm_looks times, _web_stop_confirm_pause_seconds apart,
# and gives up waiting as soon as the pid is gone, so the "not
# confirmed" line is only written for a web process that really is
# still there about two seconds later.
# Input: web process id integer.
# Output: 1 when the pid is still running after every look, otherwise 0.
sub _web_pid_outlives_stop_confirm {
    my ( $self, $pid ) = @_;
    my $looks = $self->_web_stop_confirm_looks;
    for my $look ( 1 .. $looks ) {
        return 0 if !$self->_pid_is_running($pid);
        sleep $self->_web_stop_confirm_pause_seconds if $look < $looks;
    }
    return 1;
}

# _web_stop_confirm_looks()
# Returns how many times the watcher looks at a signalled web pid before
# it says the stop is not confirmed.
# Input: none.
# Output: integer number of looks.
sub _web_stop_confirm_looks {
    return 10;
}

# _web_stop_confirm_pause_seconds()
# Returns the pause between two of those looks, so ten looks take about
# two seconds in all.
# Input: none.
# Output: number of seconds.
sub _web_stop_confirm_pause_seconds {
    return 0.2;
}

# _run_web_lifetime_owner_watcher($web_pid, $log_path)
# Body of the watcher process a web process starts for itself when its
# starter opted in to a lifetime owner (see _start_lifetime_owner_watcher
# in Developer::Dashboard::Web::Server). It polls two pids: when the web
# process is gone the watcher has nothing left to do and ends; when the
# owner has been dead on two polls in a row it stops that one web
# process and ends. The web pid is only signalled straight after a poll
# that saw it alive. The watcher process calls this on the class name;
# once there is something to watch it builds a real object (see
# _web_lifetime_owner_watcher_object) and works on that, because the
# managed-web proof behind the stop reads the persisted web state
# whenever the env-marker read gives nothing. The watcher's own pid is
# refused as the web pid, and an owner that is the web process itself
# is refused, so nothing can be tied to itself.
# The proof behind the stop is _is_managed_web exactly as every other
# caller uses it; the watcher changes nothing about it. When the watcher
# could not build its object it says so at once in its log, in words
# that state it CANNOT stop the web process in that state, and carries
# on with the class name. The stop line is written once the stop has
# actually signalled the web pid, so the line never claims a stop that
# did not happen.
# The watcher never fails silently. Its first act once it has its
# object and something to watch is a line saying which web pid it
# watches for which owner, so a watcher that was started and then died
# before it could watch is told apart from one that is watching (the
# web process itself writes the line that says a watcher was started,
# or could not be). That line is not written by a watcher that could
# not build its object: it would read as a working watcher straight
# after the line that says it cannot work. Whatever it does once the
# owner is gone, it says in its log as well: a second line after the
# stop line when the signalled web pid is still running after a short
# bounded wait (see _web_pid_outlives_stop_confirm), a line when the web
# pid is running but does not prove to be a managed dashboard web
# process and so is left alone, and a line with the error when the stop
# attempt died, which is what happens to a watcher without its object.
# The log path is optional: with none the watcher does the same work
# and keeps no log. A web process that ended by itself before the stop
# needs no line.
# Input: web process id integer, log file path string or undef.
# Output: 0, the watcher's exit status, once there is nothing to watch.
sub _run_web_lifetime_owner_watcher {
    my ( $invocant, $web_pid, $log_path ) = @_;
    return 0 if !defined $web_pid || $web_pid !~ /\A\d+\z/ || $web_pid < 1 || $web_pid == $$;
    my $owner = { pid => $invocant->_lifetime_owner_pid, dead_polls => 0 };
    return 0 if !defined $owner->{pid} || $owner->{pid} == $web_pid;
    my $self  = eval { $invocant->_web_lifetime_owner_watcher_object };
    my $built = ref $self ? 1 : 0;
    if ( !$built ) {
        my $error = defined $@ && length $@ ? $@ : 'no object was returned';
        $self = $invocant;
        eval {
            $self->_log_web_lifetime_owner_event( $log_path,
                "watcher for web pid $web_pid could not build its runtime object: it CANNOT stop web pid $web_pid when the lifetime owner goes, and carries on only to say so in this log: $error"
            );
            1;
        };
    }
    eval {
        $self->_log_web_lifetime_owner_event( $log_path,
            "watcher pid $$ is watching web pid $web_pid for lifetime owner pid $owner->{pid}" )
          if $built;
        1;
    };
    while (1) {
        return 0 if !$self->_pid_is_running($web_pid);
        if ( $self->_lifetime_owner_is_gone($owner) ) {
            my $prefix = "lifetime owner gone; lifetime owner pid $owner->{pid} is gone;";
            my $stopped;
            my $finished = eval { $stopped = $self->_stop_web_pid_as_its_watcher( $web_pid, $log_path, $prefix ); 1 };
            my $error    = $@;
            eval {
                if ( !$finished ) {
                    $error = 'unknown error' if !defined $error || !length $error;
                    $self->_log_web_lifetime_owner_event( $log_path,
                        "web not stopped: $prefix the stop attempt on web pid $web_pid died: $error" );
                }
                elsif ($stopped) {
                    $self->_log_web_lifetime_owner_stop( $log_path, $owner->{pid}, $web_pid );
                    $self->_log_web_lifetime_owner_event( $log_path,
                        "web stop not confirmed: $prefix web pid $web_pid was signalled and is still running" )
                      if $self->_web_pid_outlives_stop_confirm($web_pid);
                }
                elsif ( $self->_pid_is_running($web_pid) ) {
                    $self->_log_web_lifetime_owner_event( $log_path,
                        "web not stopped: $prefix web pid $web_pid is not recognised as a managed dashboard web process and is left alone" );
                }
                1;
            };
            return 0;
        }
        sleep $self->_lifetime_owner_poll_seconds;
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
            heartbeat_at => _now_iso8601( tz => "utc" ),
            stopped_at   => _now_iso8601( tz => "utc" ),
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
    # Close before any cleanup: Windows refuses to unlink a file that is
    # still open, which left a stale pidfile behind there. CORE::close,
    # because close in this file is POSIX::close.
    CORE::close($fh);
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
#
# The helper-command shapes also allow one leading emulator token (a
# whitespace-separated token whose name contains `qemu-`): under qemu
# user-mode emulation every process shows as
# `/usr/bin/qemu-aarch64 <real-binary> <args>`, so the supervisor's spawn
# argv is prefixed by the emulator binary and the anchored patterns below
# would otherwise never match. Only the emulator token is skipped - the
# rest of the shape must still match in full, so an unrelated process can
# never match by sharing a prefix.
sub _looks_like_collector_supervisor_process {
    my ( $self, $proc ) = @_;
    return 0 if !$proc || !$proc->{args};
    return 1 if $proc->{args} =~ /^d2 collector supervisor$/;
    # The helper's own title between spawn and the supervisor's own $0
    # assignment: _dashboard-core sets $0 to 'developer-dashboard <command>'
    # before dispatching, so a booting supervisor carries
    # 'developer-dashboard collector-supervisor-foreground' for ~2.5s on the
    # Pi. By then the child has already deleted the environ marker from %ENV
    # (which removes it from /proc environ too) and the spawn-argv
    # shape below is gone, so without this pattern the supervisor is
    # unrecognisable to _is_collector_supervisor for the whole window. A
    # stop landing in it then sends no signal and the supervisor survives
    # to respawn the collector (t/05 test 319, round 71).
    return 1 if $proc->{args} =~ /^developer-dashboard collector-supervisor-foreground(?:\s+.*)?$/;
    return 1 if $proc->{args} =~ m{^(?:\S*qemu-\S*\s+)?(?:\S+[\\/])?_dashboard-core\s+collector-supervisor-foreground(?:\s+.*)?$};
    return 1 if $proc->{args} =~ m{^(?:\S*qemu-\S*\s+)?(?:\S+[\\/])?perl(?:\.exe)?(?:\s+-\S+)*\s+(?:\S+[\\/])?_dashboard-core\s+collector-supervisor-foreground(?:\s+.*)?$}i;
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
    return json_decode_state( scalar <$fh> );
}

# _pending_collector_supervisor_state_file($file)
# Builds the per-writer staging path _write_collector_supervisor_state writes
# to before the atomic rename into $file. Its own sub (matching the pattern
# in Auth.pm/Collector.pm/SessionStore.pm/Zipper.pm) exists so a coverage test
# can exercise the real path-generation logic directly. DD-850: pid+wall-
# clock-second alone is NOT collision-safe (see DD-848) - the per-process
# monotonic counter below guarantees no two calls from one process ever
# collide, whatever the timing; cross-process collision remains prevented
# by pid uniqueness among live processes.
# Input: final destination file path string.
# Output: staging file path string.
my $_collector_supervisor_state_seq = 0;

sub _pending_collector_supervisor_state_file {
    my ( $self, $file ) = @_;
    return sprintf '%s.%s.%s.%s.pending', $file, $$, time, ++$_collector_supervisor_state_seq;
}

# _write_collector_supervisor_state($state)
# Atomically persists the watchdog supervisor state snapshot.
# Input: state hash reference.
# Output: written state hash reference.
sub _write_collector_supervisor_state {
    my ( $self, $data ) = @_;
    my $file = $self->_collector_supervisor_statefile;
    my $tmp = $self->_pending_collector_supervisor_state_file($file);
    open my $fh, '>:raw', $tmp or die "Unable to write $tmp: $!";
    print {$fh} json_encode( $data || {} );
    # CORE::close: plain close is POSIX::close in this file (raw, no flush).
    CORE::close $fh;
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
    return 'd2 collector supervisor';
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
# DD-624: the env var takes precedence (unchanged), then config.json's
# watchdog.restart_limit, then the hardcoded default - see
# Config::watchdog_restart_limit for the config-key documentation.
# Input: none.
# Output: positive integer restart limit.
sub _collector_restart_limit {
    my ($self) = @_;
    my $value = $ENV{DEVELOPER_DASHBOARD_COLLECTOR_RESTART_LIMIT};
    return $value if defined $value && $value =~ /^\d+$/ && $value > 0;
    $value = $self->{config}->watchdog_restart_limit;
    return $value if defined $value;
    return 3;
}

# _collector_restart_window_seconds()
# Returns the rolling time window used for watchdog restart-threshold tracking.
# DD-624: env var, then config.json's watchdog.restart_window_seconds, then
# the hardcoded default - see Config::watchdog_restart_window_seconds.
# Input: none.
# Output: positive integer number of seconds.
sub _collector_restart_window_seconds {
    my ($self) = @_;
    my $value = $ENV{DEVELOPER_DASHBOARD_COLLECTOR_RESTART_WINDOW_SECONDS};
    return $value if defined $value && $value =~ /^\d+$/ && $value > 0;
    $value = $self->{config}->watchdog_restart_window_seconds;
    return $value if defined $value;
    return 300;
}

# _collector_stall_grace_seconds()
# Returns the extra grace period added to collector timeout-plus-interval
# windows before the watchdog treats a managed scheduled collector as stalled.
# DD-624: env var, then config.json's watchdog.stall_grace_seconds, then the
# hardcoded default - see Config::watchdog_stall_grace_seconds.
# Input: none.
# Output: positive integer number of seconds.
sub _collector_stall_grace_seconds {
    my ($self) = @_;
    my $value = $ENV{DEVELOPER_DASHBOARD_COLLECTOR_STALL_GRACE_SECONDS};
    return $value if defined $value && $value =~ /^\d+$/ && $value > 0;
    $value = $self->{config}->watchdog_stall_grace_seconds;
    return $value if defined $value;
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

# _collector_supervisor_parent_grace_seconds()
# Returns how long the adopted serve parent may be dead before the
# supervisor exits, in seconds. Covers the restart handover, where the
# old web is dead and the new one is not up yet.
# Input: none.
# Output: positive fractional second grace period.
sub _collector_supervisor_parent_grace_seconds {
    my ($self) = @_;
    my $value = $ENV{DEVELOPER_DASHBOARD_COLLECTOR_SUPERVISOR_PARENT_GRACE_SECONDS};
    return $value if defined $value && $value =~ /^(?:\d+|\d*\.\d+)$/ && $value > 0;
    return 30;
}

# _collector_supervisor_quiesce_seconds()
# Returns how long a supervisor with no adopted serve parent may have no
# live watched loop before it exits, in seconds. Covers the killed-run
# case, where no stop ever runs and the supervisor would otherwise idle
# forever over dead loops. A healthy supervisor resets the timer on
# every pass, so only a sustained dead state quiesces.
# Input: none.
# Output: positive fractional second quiesce period.
sub _collector_supervisor_quiesce_seconds {
    my ($self) = @_;
    my $value = $ENV{DEVELOPER_DASHBOARD_COLLECTOR_SUPERVISOR_QUIESCE_SECONDS};
    return $value if defined $value && $value =~ /^(?:\d+|\d*\.\d+)$/ && $value > 0;
    return 600;
}

# stop_progress_tasks()
# Builds the ordered task list shown for d2 stop progress output.
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
# Builds the ordered task list shown for d2 restart progress output.
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
                my $schedule = _job_schedule($job);
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
    return json_decode_state( scalar <$fh> );
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
            updated_at => _now_iso8601( tz => "utc" ),
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
        my $pid = $self->_start_web_background(
            host    => $host,
            port    => $port,
            workers => $workers,
            ssl     => $ssl,
        );
        $self->_write_startup_pipe_message( $writer, join( '|', 'ok', $pid, $host, $port ) . "\n" );
        return 0;
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

    # The startup pipe is a private handshake with the forking parent, which
    # persists pid and state synchronously before start_web returns. Signalling it
    # before this child's own state write therefore exposes no consumer-visible
    # window: every caller that learns about the service through start_web already
    # sees persisted state, and the write below only refreshes it with the bound
    # endpoint. Keep the order - reversing it would delay the parent's read
    # without closing any window.
    $self->_write_startup_pipe_message( $writer, join( '|', 'ok', $child_pid, $bound_host, $bound_port ) . "\n" );
    # Detached startup returned above, so this child path only needs the
    # inherited-fd cleanup when its I/O was redirected.
    $self->_close_inherited_fds( close_ipc => 1 ) if $redirect;

    $self->_write_web_state(
        {
            host         => $host,
            pid          => $child_pid,
            port         => $bound_port + 0,
            process_name => $self->_web_process_title( $host, $port ),
            started_at   => _now_iso8601( tz => "utc" ),
            status       => 'running',
            bound_host   => $bound_host,
            workers      => $workers + 0,
            ssl          => $ssl + 0,
        }
    );

    eval { $server->serve_daemon($daemon) };
    if ($@) {
        my $message = sprintf "[%s][web] %s\n", _now_iso8601( tz => "utc" ), $@;
        $self->{files}->append( 'dashboard_log', $message );
        $self->_write_web_state(
            {
                host       => $host,
                pid        => $child_pid,
                port       => $bound_port + 0,
                status     => 'error',
                error      => "$@",
                updated_at => _now_iso8601( tz => "utc" ),
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
            updated_at => _now_iso8601( tz => "utc" ),
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
        die 'Line count must be a non-negative integer' if $lines !~ /^\d+$/;
    }
    return '' if !$follow && !-f $file;

    my $log = '';
    if ( -f $file ) {
        open my $fh, '<', $file or die "Unable to read $file: $!";
        local $/;
        $log = <$fh>;
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
# Input: text string and non-negative integer line count.
# Output: tailed text string.
sub _tail_text {
    my ( $self, $text, $lines ) = @_;
    return '' if !defined $text || $text eq '';
    return $text if !defined $lines;
    return '' if $lines == 0;
    my @parts = split /\n/, $text, -1;
    my $had_trailing_newline = $parts[-1] eq '' ? 1 : 0;
    pop @parts if $had_trailing_newline;
    my $start = @parts - $lines;
    $start = 0 if $start < 0;
    my $tail = join "\n", @parts[ $start .. $#parts ];
    $tail .= "\n" if $had_trailing_newline && $tail ne '';
    return $tail;
}

# _follow_log_file(%args)
# Streams appended content from one log file until interrupted, installing
# termination handlers before any filesystem setup so an early signal is clean.
# Input: file path plus optional poll interval seconds and start byte offset.
# Output: never returns under normal command use; prints new log chunks to STDOUT.
sub _follow_log_file {
    my ( $self, %args ) = @_;
    my $file = $args{file} || die 'Missing log file';
    my $interval = defined $args{interval} ? $args{interval} : 0.1;
    my $start_pos = $args{start_pos};
    local $SIG{TERM} = sub { POSIX::_exit(0) };
    local $SIG{INT}  = sub { POSIX::_exit(0) };
    local $SIG{HUP}  = sub { POSIX::_exit(0) };
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

# _pending_web_state_file($file)
# Builds the per-writer staging path _write_web_state writes to before the
# atomic rename into $file. Its own sub (matching the pattern in
# Auth.pm/Collector.pm/SessionStore.pm/Zipper.pm) exists so a coverage test
# can exercise the real path-generation logic directly. DD-850: pid+wall-
# clock-second alone is NOT collision-safe (see DD-848) - the per-process
# monotonic counter below guarantees no two calls from one process ever
# collide, whatever the timing; cross-process collision remains prevented
# by pid uniqueness among live processes.
# Input: final destination file path string.
# Output: staging file path string.
my $_web_state_seq = 0;

sub _pending_web_state_file {
    my ( $self, $file ) = @_;
    return sprintf '%s.%s.%s.%s.pending', $file, $$, time, ++$_web_state_seq;
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
    my $tmp = $self->_pending_web_state_file($file);
    open my $fh, '>:raw', $tmp or die "Unable to write $tmp: $!";
    print {$fh} json_encode($payload);
    # CORE::close: plain close is POSIX::close in this file (raw, no flush).
    CORE::close $fh;
    $self->{paths}->secure_file_permissions($tmp);
    $self->_replace_state_file( $tmp, $file );
    $self->{paths}->secure_file_permissions($file);
    return $payload;
}




# _replace_path_via_powershell($source, $target)
# Uses the native Windows Move-Item path as a last-resort file replacement
# fallback when Perl's in-process rename fails inside detached Windows runtime
# flows.
# Input: source file path and destination file path.
# Output: boolean success flag and optional failure text string.
sub _replace_path_via_powershell {
    my ( $self, $source, $target ) = @_;

    # DD-597: system() below mutates the caller's global $? as a side effect;
    # without this guard that stays set in the caller's process after this
    # sub returns.
    local $?;
    return ( 0, '' ) if !is_windows();
    my @script = (
        q{$ErrorActionPreference = 'Stop'},
        'Move-Item -LiteralPath '
          . _powershell_single_quote($source)
          . ' -Destination '
          . _powershell_single_quote($target)
          . ' -Force',
    );
    my $powershell = _powershell_command;
    return ( 0, 'Unable to resolve a PowerShell executable for the dashboard runtime' )
      if !length $powershell;
    my ( $stdout, $stderr, $exit_code ) = capture {
        system $powershell, '-NoLogo', '-NoProfile', '-Command', join '; ', @script;
        return $? >> 8;
    };
    return ( 1, '' ) if $exit_code == 0;
    return ( 0, join '', grep { defined && $_ ne '' } $stderr, $stdout );
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




# _web_process_title($host, $port)
# Builds the managed web process title string.
# Input: host and port values.
# Output: process title string.
sub _web_process_title {
    my ( $self, $host, $port ) = @_;
    return "d2 web: $host:$port";
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

    # DD-597: system() below (Windows taskkill path) mutates the caller's
    # global $? as a side effect; without this guard that stays set in the
    # caller's process after this sub returns.
    local $?;
    my @targets = grep { defined $_ && /^\d+$/ && $_ > 0 } @pids;
    return 0 if !@targets;
    if (is_windows()) {
        my $joined = join ',', @targets;
        my @taskkill = (_taskkill_command);
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
        if ( $signal =~ /^(?:TERM|KILL)$/i ) {
            # taskkill exits non-zero when ANY process in the tree fails,
            # even when the target itself was terminated: solo #220 saw the
            # target 9000 and one child terminated, but a just-exited worker
            # child refused with "The operation attempted is not
            # supported", so the restart died while the web was already
            # down and printed plain text instead of JSON. The stop's goal
            # is the target being gone: verify that directly, with the same
            # bounded wait the other stop paths use, and only die when a
            # target is still alive afterwards. Callers re-verify liveness
            # themselves (stop_web escalates, _ensure_collector_pid_stopped
            # dies on a survivor), so a target that is verifiably gone can
            # never be masked by this.
            for ( 1 .. 20 ) {
                last if !grep { $self->_pid_is_running($_) } @targets;
                sleep 0.1;
            }
            my @still_running = grep { $self->_pid_is_running($_) } @targets;
            return scalar @targets if !@still_running;
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

    # The persisted-state proof goes before the title read. The title
    # read costs a full process-table enumeration on Windows (one
    # PowerShell Get-CimInstance Win32_Process per call, solo #351), and
    # the readiness waits call this on every poll - while on Windows the
    # title read almost never proves anything anyway, because $0 never
    # rewrites the Windows launch command line. When persisted running
    # state already names this pid and the live socket table confirms it
    # owns that exact saved listener port, that is the same proof the old
    # order used for the otherwise-opaque Starman master, so there is
    # nothing left for the title read to add. When state does not name
    # this pid, or the socket table does not list it as the owner, fall
    # through to the title read unchanged: the order changes, the answer
    # does not. The state check
    # never returns 0 on its own - a socket that has not appeared yet is
    # not proof the process is foreign, and the title is the proof the
    # original order consulted first.
    my ( $state ) = $self->_read_settled_web_state;
    if ( ref($state) eq 'HASH'
        && ( $state->{status} || '' ) eq 'running'
        && $state->{pid}
        && $state->{pid} =~ /^\d+$/
        && $state->{pid} == $pid
        && defined $state->{port}
        && $state->{port} =~ /^\d+$/
        && $state->{port} >= 1 )
    {
        return 1
          if scalar( grep { $_ == $pid } $self->_listener_pids_for_port( $state->{port} ) );
    }

    my $title = $self->_read_process_title($pid);
    return 1 if defined $title && $title =~ /^d2 web:/;
    return 0;
}

# _background_web_command(%args)
# Builds the detached helper command used to host the foreground web listener
# in its own process without also starting collector loops.
# Input: host, port, worker count, and ssl flag.
# Output: argument list for the private foreground supervisor helper.
sub _background_web_command {
    my ( $self, %args ) = @_;
    my $core = $self->_dashboard_core_helper_path('web-foreground');
    my $perl = $self->_current_perl_command;
    my @command = (
        $perl,
        $self->_perl_library_args,
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

# _windows_background_web_command(%args)
# Retains the historical Windows helper name while delegating to the shared
# platform-neutral command builder.
# Input: host, port, worker count, and ssl flag.
# Output: argument list for the private foreground supervisor helper.
sub _windows_background_web_command {
    my ( $self, %args ) = @_;
    return $self->_background_web_command(%args);
}

# _background_collector_supervisor_command()
# Builds the helper command used to start the detached collector watchdog on
# every supported platform.
# Input: none.
# Output: command list suitable for system 1, @command on Windows.
sub _background_collector_supervisor_command {
    my ($self) = @_;
    my $core = $self->_dashboard_core_helper_path('collector-supervisor-foreground');
    my $perl = $self->_current_perl_command;
    return (
        $perl,
        $self->_perl_library_args,
        $core,
        'collector-supervisor-foreground',
    );
}


# _spawn_windows_background_command(@command)
# Launches one detached background Windows process command and returns the
# spawned pid.
# Input: command list.
# Output: spawned pid integer or undef when the command could not be launched.
sub _spawn_windows_background_command {
    my ( $self, @command ) = @_;

    # DD-597: system() below mutates the caller's global $? as a side effect;
    # without this guard that stays set in the caller's process after this
    # sub returns.
    local $?;
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
    my $powershell = _powershell_command;
    die "Unable to launch detached Windows web process: powershell is unavailable\n"
      if !length $powershell;
    my ( $stdout, $stderr, $exit_code ) = capture {
        system $powershell, '-NoLogo', '-NoProfile', '-Command', join '; ', @script;
        return $? >> 8;
    };
    die "Unable to launch detached Windows web process: $stderr$stdout"
      if $exit_code != 0;
    my ($pid) = grep { /^\d+$/ && $_ > 0 } split /\r?\n/, ( $stdout || '' );
    return $pid;
}


# _pkill_perl($pattern)
# Kills Perl processes whose command lines match a pattern.
# Input: regular-expression pattern string.
# Output: true value.
sub _pkill_perl {
    my ( $self, $pattern ) = @_;

    # DD-597: system() below (the pkill path) mutates the caller's global $?
    # as a side effect; without this guard that stays set in the caller's
    # process after this sub returns.
    local $?;
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

# _find_processes_by_prefix($prefix, $rows)
# Returns running processes whose command lines start with a prefix.
# Input: prefix string and optional process-table rows (array reference
# as returned by _ps_processes) to search instead of scanning the table
# again; callers that already hold a scan pass its rows in.
# Output: list of process hash references.
#
# A process also matches when its command line shows it ADOPTING the prefix
# as its title - a `$0 = "<prefix>..."` (or '$0 = ...') assignment in the
# program text. Under qemu user-mode emulation the guest's $0 write never
# reaches the host's /proc, so the adopted title itself is invisible, but
# the assignment that sets it is still visible in the spawn argv: a fixture
# child spawned as `perl -e '$0 = "d2 ajax: NAME"; ...'` shows
# `/usr/bin/qemu-aarch64 /usr/bin/perl -e $0 = "d2 ajax: NAME"; ...`.
# This is deliberately NOT a plain substring match: the assignment form is
# precise, and a plain substring would newly match unrelated processes whose
# own argv merely mentions the pattern - a `pkill -f '^d2 ajax: NAME$'`
# command line, for example, contains the pattern text but never a $0
# assignment.
sub _find_processes_by_prefix {
    my ( $self, $prefix, $rows ) = @_;
    my @matches;
    my @procs = ref($rows) eq 'ARRAY' ? @{$rows} : $self->_ps_processes;
    for my $proc ( @procs ) {
        next if !$self->_proc_owned_by_current_user($proc);
        if ( defined $proc->{args} && $proc->{args} =~ /^\Q$prefix\E/ ) {
            push @matches, $proc;
            next;
        }
        if ( defined $proc->{args} && $proc->{args} =~ /\$0\s*=\s*\\?["']\Q$prefix\E/ ) {
            push @matches, $proc;
            next;
        }
        # The title can differ from the scanned arguments (the qemu case
        # in the header comment), so fall back to a title read. Hand this
        # scan's rows in: on Windows the title is read out of those very
        # rows, and a fresh table scan per process would cost one full
        # PowerShell enumeration each.
        my $title = $self->_read_process_title( $proc->{pid}, \@procs );
        next if !defined $title;
        next if $title !~ /^\Q$prefix\E/ && $title !~ /\$0\s*=\s*\\?["']\Q$prefix\E/;
        push @matches, {
            %{$proc},
            args => $title,
        };
    }
    return @matches;
}

# _find_web_processes($rows)
# Returns managed or older-compatible dashboard web processes.
# Input: optional process-table rows (array reference as returned by
# _ps_processes) to search instead of scanning the table again; callers
# that already hold a scan pass its rows in.
# Output: list of process hash references.
sub _find_web_processes {
    my ( $self, $rows ) = @_;
    my @seen;
    my %seen_pid;
    for my $proc ( ref($rows) eq 'ARRAY' ? @{$rows} : $self->_ps_processes ) {
        next if $proc->{pid} == $$;
        next if $seen_pid{ $proc->{pid} }++;
        next if !$self->_proc_owned_by_current_user($proc);
        next if !$self->_looks_like_web_process($proc);
        my $adopted = $self->_adopted_process_title( $proc->{args} );
        if ( defined $adopted && $adopted =~ /^d2 web:\s+\S+:\d+$/ ) {
            $proc = { %{$proc}, args => $adopted };
        }
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

# _find_legacy_web_processes($rows)
# Returns older-style d2 serve processes.
# Input: optional process-table rows (array reference as returned by
# _ps_processes) to search instead of scanning the table again; callers
# that already hold a scan pass its rows in.
# Output: list of process hash references.
sub _find_legacy_web_processes {
    my ( $self, $rows ) = @_;
    return grep { $_->{args} !~ /^d2 web:/ } $self->_find_web_processes($rows);
}

# _looks_like_web_process($proc)
# Determines whether a process record matches known web worker forms.
# Input: process hash reference with args.
# Output: boolean match flag.
sub _looks_like_web_process {
    my ( $self, $proc ) = @_;
    return 0 if !$proc || !$proc->{pid} || !$proc->{args};
    return 1 if $proc->{args} =~ /^d2 web:\s+\S+:\d+$/;
    return 1 if $proc->{args} =~ /\$0\s*=\s*\\?["']d2 web:\s+\S+:\d+\\?["']/;
    return 1 if $proc->{args} =~ m{^(?:\S+[\\/])?_dashboard-core\s+(?:serve|web-foreground|web-ssl-backend-foreground)(?:\s+(?!logs(?:\s|$)|workers(?:\s|$)).*)?$};
    return 1 if $proc->{args} =~ m{^(?:\S+[\\/])?perl(?:\.exe)?(?:\s+-\S+)*\s+(?:\S+[\\/])?_dashboard-core\s+(?:serve|web-foreground|web-ssl-backend-foreground)(?:\s+(?!logs(?:\s|$)|workers(?:\s|$)).*)?$}i;
    return 1 if $proc->{args} =~ m{^(?:\S+/env\s+)?perl(?:\s+-\S+)*\s+(?:\S+/)?d2\s+serve(?:\s+(?!logs(?:\s|$)|workers(?:\s|$)).*)?$};
    return 1 if $proc->{args} =~ m{^(?:\S+/)?d2\s+serve(?:\s+(?!logs(?:\s|$)|workers(?:\s|$)).*)?$};
    return 0;
}

# _ps_processes()
# Reads the process table into normalized process records.
# Input: none.
# Output: list of process hash references.
sub _ps_processes {
    my ($self) = @_;

    # DD-597: system() below mutates the caller's global $? as a side effect;
    # without this guard that stays set in the caller's process after this
    # sub returns - a query function must not decide its caller's exit
    # status.
    local $?;
    if (is_windows()) {
        # The emitter uses [char]9, not a double-quoted format string:
        # double quotes do not survive the argv-to-CommandLine round
        # trip to powershell -Command (they arrive stripped, and the
        # -f format then fails to parse), while single quotes leave a
        # literal backtick-t in the output instead of a tab. Command
        # lines are flattened to one line first: a child spawned with a
        # multi-line -e script would otherwise split across output
        # lines and lose everything after the first newline, including
        # any $0 assignment it carries.
        my $powershell = _powershell_command;
        return () if !length $powershell;
        my ( $stdout, undef, $exit_code ) = capture {
            system(
                $powershell,
                '-NoLogo',
                '-NoProfile',
                '-Command',
                q{$ErrorActionPreference = 'Stop'; Get-CimInstance Win32_Process | ForEach-Object { $cmd = $_.CommandLine; if ($null -eq $cmd) { $cmd = '' }; $cmd = $cmd -replace '\s+', ' '; [Console]::Out.WriteLine($_.ProcessId.ToString() + [char]9 + $cmd) }},
            );
            return $? >> 8;
        };
        return if $exit_code != 0;
        return () if !defined $stdout;
        my @procs;
        for my $line ( split /\n/, $stdout ) {
            next if $line !~ /^\s*(\d+)\t(.*)$/;
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

# _listener_pids_for_port($port, $fallback_when_accepting)
# Returns TCP listener process ids bound to one port.
# Input: TCP port integer and optional flag: when true, the Windows
# PowerShell fallback runs only while the port accepts connections (a
# readiness wait passes this, so the fallback is not paid on every
# pre-bind poll for a listener that cannot exist yet).
# Output: list of process ids.
sub _listener_pids_for_port {
    my ( $self, $port, $fallback_when_accepting ) = @_;

    # DD-597: system() below mutates the caller's global $? as a side effect;
    # without this guard that stays set in the caller's process after this
    # sub returns - a query function must not decide its caller's exit
    # status.
    local $?;
    return () if !$port;
    if (is_windows()) {
        # Netstat is ~100x faster than the PowerShell Get-NetTCPConnection
        # lookup on Windows (~0.03s vs ~4s per call, Jenkins build #98),
        # and every readiness wait polls this on each iteration
        # (_start_web_windows_background, _web_runtime_ready,
        # _wait_for_port_release). At PowerShell prices a stop whose
        # port-release wait runs its full 50-poll budget burns ~200s and
        # trips the 3-minute fail-safe (build #98 stop-cleanup). Try the
        # fast netstat path first; fall back to PowerShell only when
        # netstat finds no listener.
        my @netstat_pids = $self->_listener_pids_for_port_via_netstat($port);
        return @netstat_pids if @netstat_pids;
        # A readiness wait asks for the fallback only once the port
        # accepts: before the child has bound there is no listener for
        # the fallback to find, and each pre-bind poll paid ~5-9s for it
        # (solo #351: Windows restarts took 112-151s). The fallback still
        # runs when the port accepts, so a live listener netstat cannot
        # see (build #98) is still found. Callers that must be sure the
        # port is free - the shutdown and port-release waits - do not pass
        # the flag, so their fallback is ungated as before.
        if ( $fallback_when_accepting && !$self->_port_accepting_connections($port) ) {
            return ();
        }
        my $powershell = _powershell_command;
        return () if !length $powershell;
        my ( $stdout, undef, $exit_code ) = capture {
            system(
                $powershell,
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
        return ();
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

    # DD-597: system() below mutates the caller's global $? as a side effect;
    # without this guard that stays set in the caller's process after this
    # sub returns - a query function must not decide its caller's exit
    # status.
    local $?;
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

    # DD-597: system() below mutates the caller's global $? as a side effect;
    # without this guard that stays set in the caller's process after this
    # sub returns - a query function must not decide its caller's exit
    # status.
    local $?;
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
        if ( defined $pid ) {
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
            # Consult running_web BEFORE the listener check, as the
            # POSIX branch does: the listener stubs in the tests count
            # running_web calls, so a listener that disappears after a
            # few running_web polls must be re-checked after them
            # (build #258 failed t/09 test 237 on Windows because the
            # listener was checked first and never saw the disappearance).
            my $running = $self->running_web;
            # Gate the PowerShell fallback on the port accepting, as
            # _start_web_windows_background already does: without the flag
            # every poll while the listener is absent pays the ~5s
            # Get-NetTCPConnection fallback (solo #351), so this 300-poll
            # budget burns ~25 minutes of silence and trips the 3-minute
            # fail-safe (round 51 stalled here inside d2 restart, after
            # test 202, with zero test failures). With it, an absent
            # listener costs one fast netstat probe per poll and the budget
            # is the ~45s it was designed to be; a live listener netstat
            # cannot see is still found once the port accepts, and the
            # _port_accepting_connections check below covers the rest.
            my @listener_pids = $self->_listener_pids_for_port( $port, 1 );
            # The POSIX branch below adopts the real listener pid once
            # Starman replaces the startup wrapper; the Windows branch
            # never did, so the adopted pid was never persisted and the
            # namespace fallback tests never saw running_web consulted
            # (build #255 failed t/09 tests 229-231, 237 and 241-242 on
            # Windows). Mirror the matching and adoption here, keeping
            # the Windows listening and confirmation shape unchanged.
            if (@listener_pids) {
                my $matches_runtime = $running ? $self->_web_runtime_matches_pid( $running, $pid, $port ) : 0;
                if ( !$matches_runtime && !$self->_same_pid_namespace($pid) ) {
                    $matches_runtime = 0;
                }
                elsif ( !$matches_runtime && $running ) {
                    $matches_runtime = 1;
                }
                if ($matches_runtime) {
                    $self->_adopt_web_listener_pid(
                        listener_pid => $listener_pids[0],
                        state        => $running,
                    );
                    $running->{pid} = $listener_pids[0];
                }
            }
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
                if ($matches_runtime) {
                    $self->_adopt_web_listener_pid(
                        listener_pid => $listener_pid,
                        state        => $running,
                    );
                    $running->{pid} = $listener_pid;
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
    $state->{updated_at} = _now_iso8601( tz => "utc" );
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
# A single un-ready poll while the loop process is still alive is not
# evidence the loop died: the loop state file is metadata the child itself
# rewrites, and a poll can land while a state replace is in flight (the file
# transiently absent, or briefly holding a stale pid). Only a gone process
# fails fast; otherwise the confirmation count resets and polling continues
# until the stability budget is spent.
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
        elsif ( !kill( 0, $pid ) ) {
            # The loop process itself is gone: fail fast instead of burning
            # the rest of the stability budget waiting on a dead child.
            return 0;
        }
        else {
            # The process is alive but its loop state is transiently
            # un-ready. Reset the confirmation so it must be consecutive,
            # and keep polling until the budget is spent.
            $ready_polls = 0;
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





# _adopted_process_title($args)
# Extracts a $0-assigned process title from a command line. A $0 assignment
# never rewrites the Windows launch command line, but a child spawned with
# the assignment in its arguments still carries the assignment text there,
# so the title is recoverable from the command line even though the live
# title itself is invisible to another process. The same shape is already
# what _find_processes_by_prefix matches against. The quotes around the
# assignment may be backslash-escaped: the Windows spawn layer quotes an
# argument that contains spaces, so a -e script reaches the process table
# with its inner double quotes as \" rather than ".
# Input: command line string.
# Output: assigned title string or undef when the command line carries no
# $0 assignment.
sub _adopted_process_title {
    my ( $self, $args ) = @_;
    return if !defined $args || $args eq '';
    return $2 if $args =~ /\$0\s*=\s*\\?(["'])([^"']+?)\\?\1/;
    return;
}

# _read_process_title($pid, $rows)
# Reads a process command line for matching and diagnostics.
# Input: process id integer and optional process-table rows (array reference
# as returned by _ps_processes) to search instead of scanning the table
# again; callers that already hold a scan pass its rows in.
# Output: command line string or undef.
sub _read_process_title {
    my ( $self, $pid, $rows ) = @_;
    # A QUERY MUST NOT DECIDE ITS CALLER'S EXIT STATUS (DD-590, same shape as
    # DD-585's fix in CollectorRunner.pm and DD-589's fix in IndicatorStore.pm).
    # The ps fallback below runs whenever /proc is unavailable and reads $?
    # into its own return value, but without this guard the raw, unshifted $?
    # from that subprocess stays set in the caller's process after this sub
    # returns. `local` restores the caller's $? on return regardless of how
    # many system() calls run inside.
    local $?;
    my $proc = "/proc/$pid/cmdline";
    if ( $self->_procfs_available ) {
        my $cmdline = $self->_slurp_proc_file($proc);
        return if !defined $cmdline;
        if ( $cmdline ne '' ) {
            $cmdline =~ s/\0/ /g;
            $cmdline =~ s/\s+$//;
            return $cmdline;
        }
        return;
    }

    if ( is_windows() ) {
        # ps does not exist on Windows, so read the command line from the
        # process table instead: a $0 assignment never rewrites the
        # Windows launch command line, but a child spawned with the
        # assignment in its arguments still carries it there, so the
        # adopted title is what callers match against. Without an
        # assignment the command line itself is the title, the same shape
        # ps args gives on POSIX. A pid the table no longer lists is
        # simply unknown. Callers already treat undef as unknown;
        # spawning cmd.exe for a ps that can never exist would only waste
        # a process and surface its "not recognized" text through the
        # capture. Callers that already hold a table scan pass its rows
        # in so this read costs no fresh scan.
        return if !defined $pid || $pid !~ /^\d+$/;
        my @table = ref($rows) eq 'ARRAY' ? @{$rows} : $self->_ps_processes;
        for my $row ( @table ) {
            next if $row->{pid} != $pid;
            my $adopted = $self->_adopted_process_title( $row->{args} );
            return $adopted if defined $adopted;
            return $row->{args} if defined $row->{args} && $row->{args} ne '';
            return;
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
    # A QUERY MUST NOT DECIDE ITS CALLER'S EXIT STATUS (DD-590, same shape as
    # DD-585's fix in CollectorRunner.pm and DD-589's fix in IndicatorStore.pm).
    # The ps fallback below runs whenever /proc is unavailable and reads $?
    # into its own return value, but without this guard the raw, unshifted $?
    # from that subprocess stays set in the caller's process after this sub
    # returns. `local` restores the caller's $? on return regardless of how
    # many system() calls run inside.
    local $?;
    my $proc = "/proc/$pid/stat";
    if ( $self->_procfs_available ) {
        my $stat = $self->_slurp_proc_file($proc);
        return if !defined $stat;
        if ( $stat =~ /^\d+\s+\(.*\)\s+(\S)/s ) {
            return $1;
        }
        return;
    }

    if ( is_windows() ) {
        # As _read_process_title above: ps does not exist on Windows, so
        # a state that procfs did not supply is simply unavailable and
        # the callers treat undef as unknown.
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


# _procfs_available()
# Reports whether procfs-backed process inspection is available on the current host.
# Input: none.
# Output: boolean true when /proc exists and process readers should prefer it.
sub _procfs_available {
    return -d $PROCFS_ROOT ? 1 : 0;
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
managed processes correctly. Cron loops are monitored by their scheduler
heartbeat rather than the age of the last scheduled job execution, so a valid
quiet period does not trigger repeated restart warnings.

=head1 METHODS

=head2 new, start_web, serve_ssl_backend_foreground, running_web, stop_web, start_collectors, serve_all, stop_collectors, stop_all, restart_all, web_state, web_log

Construct and manage the dashboard runtime.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module manages the dashboard runtime processes. It starts, stops, and restarts the web listener, tracks the web pid, coordinates collector lifecycle around restart/stop flows, supervises managed collector loops with a watchdog, sends numeric POSIX shutdown signals for Alpine/iSH compatibility, and exposes the process-management behavior behind the serve/restart/stop command family.

=head1 WHY IT EXISTS

It exists because runtime lifecycle management needs one owner for pid files, process validation, restart ordering, watchdog restart thresholds, and port-release races. That keeps the browser server and collector loops moving together instead of leaving each command to improvise process control.

=head1 WHEN TO USE

Use this file when changing how the web process is launched, how restart waits for ports to free up, how collectors are stopped, restarted, or watchdog-supervised with the web process, or how runtime state is validated before a lifecycle command acts.

For cron collectors, keep scheduler-loop heartbeat separate from job progress:
an old execution timestamp is normal between scheduled runs, while a stale
loop heartbeat still indicates that the scheduler may need recovery.

The C<serve_ssl_backend_foreground> helper entry point rebuilds the normal
dashboard application in the separately supervised internal TLS backend
process. It accepts a host, positive port, and positive worker count, then
serves the TLS Starman runner on that internal endpoint and returns its exit
status. The public SSL frontend launches it through GoRoutine's native process
API so foreground and managed web serving share the same lifecycle contract.

The C<web_log> method reads the d2 log, optionally returns only the last
N lines, or follows appended data after printing that tail. A zero line count
prints no existing lines before follow mode begins; line counts must be
non-negative integers.

=head1 HOW TO USE

Construct it with the path registry and any required collaborators, then call the lifecycle methods from CLI helpers. Keep process orchestration here and let the command wrappers only parse arguments and print results.

=head1 WHAT USES IT

It is used by the C<d2 serve>, C<d2 restart>, and C<d2 stop> helpers, by integration smoke that exercises lifecycle commands, and by tests that cover pid handling and process validation.

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

Example 5:

  d2 serve logs -t --tail=0

Read no current log lines with timestamps enabled. When combined with C<-f>,
this starts following future log entries without first printing the existing
content.


=for comment FULL-POD-DOC END

=cut
