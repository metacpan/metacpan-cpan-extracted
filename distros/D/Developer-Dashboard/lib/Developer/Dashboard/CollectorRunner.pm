package Developer::Dashboard::CollectorRunner;

use strict;
use warnings;

our $VERSION = '4.16';

use Capture::Tiny qw(capture);
use Cwd qw(cwd);
use File::Spec;
use POSIX qw(close setsid strftime);
use Template;
use Time::HiRes qw(sleep time);

use Developer::Dashboard::InternalCLI ();
use Developer::Dashboard::JSON qw(json_encode json_decode);
use Developer::Dashboard::PerlEnv ();
use Developer::Dashboard::Platform qw(command_in_path is_windows shell_command_argv);

our $SIGNAL_RUNNER;
our $SIGNAL_LOOP_NAME;
our $SIGNAL_LOOP_WORKERS;

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
    $self->{collectors}->mark_run_started(
        $name,
        {
            enabled         => 1,
            last_started_at => $started_at,
            schedule        => $job->{schedule} || ( $job->{cron} ? 'cron' : $job->{interval} ? 'interval' : 'manual' ),
        }
    );

    my $indicator_payload;
    my ( $stdout, $stderr, $exit_code, $timed_out ) = ( '', '', 255, 0 );
    my $ok = eval {
        ( $stdout, $stderr, $exit_code, $timed_out ) = $self->_run_job(
            mode       => $mode,
            source     => $source,
            cwd        => $cwd,
            env        => $job->{env},
            timeout_ms => $job->{timeout_ms} || ( $job->{timeout} ? $job->{timeout} * 1000 : undef ),
        );

        if ( $self->{indicators} && ref( $job->{indicator} ) eq 'HASH' ) {
            my $existing_indicator = eval {
                $self->{indicators}->get_indicator( $job->{indicator}{name} || $job->{name} );
            } || {};
            $indicator_payload = $self->{indicators}->collector_indicator_candidate(
                $job,
                existing => $existing_indicator,
                status => $exit_code ? 'error' : 'ok',
            );
            my $materialized = eval {
                $self->_materialize_indicator_state(
                    job       => $job,
                    indicator => $indicator_payload,
                    stdout    => $stdout,
                );
            };
            if ( !$materialized ) {
                my $error = "$@";
                $error =~ s/\s+\z//;
                $stderr = $self->_append_error_text( $stderr, $error );
                $exit_code = 255 if !$exit_code;
                $indicator_payload->{status} = 'error';
            }
            else {
                $indicator_payload = $materialized;
            }
        }
        return 1;
    };
    if ( !$ok ) {
        my $error = "$@";
        $error =~ s/\s+\z//;
        $stderr = $self->_append_error_text( $stderr, $error );
        $exit_code = 255;
    }

    $self->{collectors}->mark_run_finished(
        $name,
        exit_code => $exit_code,
        stdout    => $stdout,
        stderr    => $stderr,
        started_at => $started_at,
        output_format => $job->{output_format},
        timed_out  => $timed_out,
    );
    if ($indicator_payload) {
        $indicator_payload->{status} = $exit_code ? 'error' : 'ok';
        $self->{indicators}->set_indicator(
            $indicator_payload->{name},
            %{$indicator_payload},
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

# _materialize_indicator_state(%args)
# Renders TT-backed collector indicator fields into their live persisted values.
# Input: collector job hash, normalized indicator hash, and stdout text.
# Output: normalized indicator hash reference with rendered live values.
sub _materialize_indicator_state {
    my ( $self, %args ) = @_;
    my $job       = $args{job}       || die 'Missing collector job';
    my $indicator = $args{indicator} || die 'Missing indicator payload';
    my %materialized = %{$indicator};

    if ( defined $materialized{icon_template} && $materialized{icon_template} ne '' ) {
        $materialized{icon} = $self->_render_indicator_icon_template(
            collector_name => $job->{name},
            template       => $materialized{icon_template},
            stdout         => $args{stdout},
        );
    }

    return \%materialized;
}

# _render_indicator_icon_template(%args)
# Renders one collector indicator icon TT template against stdout JSON.
# Input: collector_name string, TT template string, and stdout JSON text.
# Output: rendered icon string.
sub _render_indicator_icon_template {
    my ( $self, %args ) = @_;
    my $collector_name = $args{collector_name} || die 'Missing collector name';
    my $template_text  = $args{template}       || die 'Missing indicator icon template';
    my $vars = $self->_indicator_template_vars(
        collector_name => $collector_name,
        stdout         => $args{stdout},
    );
    my $tt = Template->new();
    my $rendered = '';
    $tt->process( \$template_text, $vars, \$rendered )
      or die sprintf "Collector '%s' indicator icon template failed: %s\n", $collector_name, $tt->error();
    return $rendered;
}

# _indicator_template_vars(%args)
# Decodes collector stdout JSON into the TT variable set for indicator
# templates.
# Input: collector_name string and stdout JSON text.
# Output: hash reference of template variables.
sub _indicator_template_vars {
    my ( $self, %args ) = @_;
    my $collector_name = $args{collector_name} || die 'Missing collector name';
    my $stdout = defined $args{stdout} ? $args{stdout} : '';
    my $decoded = eval { json_decode($stdout) };
    if ($@) {
        my $error = "$@";
        $error =~ s/\s+\z//;
        die sprintf "Collector '%s' indicator icon template requires collector stdout JSON: %s\n", $collector_name, $error;
    }

    my %vars = ( data => $decoded );
    if ( ref($decoded) eq 'HASH' ) {
        %vars = ( %vars, %{$decoded} );
    }
    return \%vars;
}

# _append_error_text($stderr, $error)
# Appends one explicit runtime error line to captured stderr text.
# Input: existing stderr text and error text string.
# Output: merged stderr text string.
sub _append_error_text {
    my ( $self, $stderr, $error ) = @_;
    $stderr = '' if !defined $stderr;
    $error  = '' if !defined $error;
    return $stderr if $error eq '';
    $stderr .= "\n" if $stderr ne '' && $stderr !~ /\n\z/;
    return $stderr . $error . "\n";
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
    my $interval = $self->_effective_interval_seconds($job);
    my $configured_interval = defined $job->{interval} ? $job->{interval} : 30;
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

    if ( is_windows() ) {
        return $self->_start_windows_loop_process(
            configured_interval => $configured_interval,
            interval            => $interval,
            job                 => $job,
            name                => $name,
            schedule_mode       => $schedule_mode,
            title               => $title,
        );
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
                ( $interval != $configured_interval ? ( configured_interval => $configured_interval ) : () ),
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

# _start_windows_loop_process(%args)
# Launches one detached collector loop helper on Windows instead of relying on
# Perl pseudo-fork semantics for long-lived background processes.
# Input: collector job hash, collector name, title, effective interval,
# configured interval, and schedule mode.
# Output: detached loop pid integer.
sub _start_windows_loop_process {
    my ( $self, %args ) = @_;
    my $job                 = $args{job}                 || die 'Missing collector job';
    my $name                = $args{name}                || die 'Missing collector name';
    my $title               = $args{title}               || $self->_process_title($name);
    my $interval            = defined $args{interval} ? $args{interval} : 30;
    my $configured_interval = defined $args{configured_interval} ? $args{configured_interval} : 30;
    my $schedule_mode       = $args{schedule_mode}       || 'interval';
    my $pidfile             = $self->_pidfile($name);

    $self->{collectors}->write_job(
        $name,
        {
            %{$job},
            interval => $configured_interval,
            schedule => $schedule_mode,
        }
    );

    my @command = $self->_windows_background_loop_command($name);
    my $pid = $self->_spawn_windows_background_command(@command);
    die "Unable to launch collector '$name' on Windows\n" if !$pid;

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
            ( $interval != $configured_interval ? ( configured_interval => $configured_interval ) : () ),
            schedule     => $schedule_mode,
            status       => 'starting',
            started_at   => _now_iso8601(),
            heartbeat_at => _now_iso8601(),
        }
    );
    return $pid;
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

    $self->_scrub_coverage_environment;

    if ($daemonize) {
        $self->_detach_process_session;
        open STDIN, '<', File::Spec->devnull() or die $!;
        open STDOUT, '>>', $self->{files}->collector_log or die $!;
        open STDERR, '>>', $self->{files}->collector_log or die $!;
        $self->_close_inherited_fds( close_ipc => 1 );
    }

    $ENV{DEVELOPER_DASHBOARD_LOOP_NAME}   = $name;
    $ENV{DEVELOPER_DASHBOARD_LOOP_STATUS} = 'running';
    $0 = $title;
    local $SIGNAL_RUNNER    = $self;
    local $SIGNAL_LOOP_NAME = $name;
    my %active_workers;
    local $SIGNAL_LOOP_WORKERS = \%active_workers;
    local $SIG{CHLD} = sub {
        return if !$SIGNAL_RUNNER || ref($SIGNAL_LOOP_WORKERS) ne 'HASH';
        $SIGNAL_RUNNER->_reap_finished_loop_workers($SIGNAL_LOOP_WORKERS);
        return;
    };
    local $SIG{TERM} = \&_signal_stop;
    local $SIG{INT}  = \&_signal_stop;
    local $SIG{HUP}  = \&_signal_stop;
    my ( $execution_mode, $max_parallel ) = $self->_collector_execution_policy($job);

    while (1) {
        $self->_reap_finished_loop_workers( \%active_workers );
        $self->_write_loop_state(
            $name,
            {
                pid          => $$,
                name         => $name,
                process_name => $title,
                command      => $job->{command},
                cwd          => $job->{cwd},
                interval     => $interval,
                ( $interval != ( defined $job->{interval} ? $job->{interval} : 30 ) ? ( configured_interval => ( defined $job->{interval} ? $job->{interval} : 30 ) ) : () ),
                schedule     => $schedule_mode,
                status       => 'running',
                mode         => $execution_mode,
                multiple     => $max_parallel,
                active_runs  => scalar keys %active_workers,
                active_worker_pids => [ $self->_active_worker_pids( \%active_workers ) ],
                heartbeat_at => _now_iso8601(),
            }
        );
        my $due = $self->_job_is_due( $job, $name );
        if ( $due && scalar( keys %active_workers ) < $max_parallel ) {
            my $worker_pid = eval { $self->_start_loop_worker( $job, $name, $title ) };
            if ($@) {
                my $error = "$@";
                my $message = sprintf "[%s][%s] %s\n", _now_iso8601(), $name, $error;
                $self->{files}->append( 'collector_log', $message );
                $self->{collectors}->append_log_entry(
                    $name,
                    happened_at => _now_iso8601(),
                    error       => $error,
                    source      => 'loop error',
                );
                $self->_write_loop_state(
                    $name,
                    {
                        pid          => $$,
                        name         => $name,
                        process_name => $title,
                        command      => $job->{command},
                        cwd          => $job->{cwd},
                        interval     => $interval,
                        ( $interval != ( defined $job->{interval} ? $job->{interval} : 30 ) ? ( configured_interval => ( defined $job->{interval} ? $job->{interval} : 30 ) ) : () ),
                        schedule     => $schedule_mode,
                        status       => 'error',
                        mode         => $execution_mode,
                        multiple     => $max_parallel,
                        active_runs  => scalar keys %active_workers,
                        active_worker_pids => [ $self->_active_worker_pids( \%active_workers ) ],
                        heartbeat_at => _now_iso8601(),
                        error        => $error,
                    }
                );
            }
            elsif ($worker_pid) {
                $active_workers{$worker_pid} = 1;
            }
        }
        $self->_sleep_until_next_tick(
            interval       => $schedule_mode eq 'cron' ? 1 : $interval,
            active_workers => \%active_workers,
        );
        if ($single_tick) {
            $self->_settle_single_tick_workers( \%active_workers );
            return 1;
        }
    }
}

# _collector_execution_policy($job)
# Normalizes one collector loop execution policy from config, defaulting to
# singleton mode and a bounded multiple-run limit when requested.
# Input: collector job hash reference.
# Output: execution mode string and maximum parallel run count integer.
sub _collector_execution_policy {
    my ( $self, $job ) = @_;
    $job ||= {};
    my $mode = defined $job->{mode} && $job->{mode} ne '' ? $job->{mode} : 'singleton';
    die "Collector '$job->{name}' has unsupported mode '$mode'" if $mode ne 'singleton' && $mode ne 'multiple';
    return ( 'singleton', 1 ) if $mode eq 'singleton';
    my $max_parallel = defined $job->{multiple} ? $job->{multiple} : 2;
    die "Collector '$job->{name}' multiple value must be a positive integer"
      if $max_parallel !~ /^\d+$/ || $max_parallel < 1;
    return ( 'multiple', $max_parallel + 0 );
}

# _effective_interval_seconds($job)
# Normalizes one collector loop interval and applies a safety floor for
# dashboard-recursive shell collectors unless fast polling is explicitly
# allowed.
# Input: collector job hash reference.
# Output: positive numeric interval in seconds.
sub _effective_interval_seconds {
    my ( $self, $job ) = @_;
    $job ||= {};
    my $interval = defined $job->{interval} && $job->{interval} =~ /^(?:\d+|\d*\.\d+)$/ && $job->{interval} > 0
      ? $job->{interval} + 0
      : 30;
    return $interval if $job->{allow_fast_poll} || $job->{allow_fast_dashboard_poll};

    my $minimum = $self->_minimum_dashboard_command_interval_seconds;
    return $interval if $minimum < 1;
    return $interval if !$self->_is_dashboard_subcommand_collector($job);
    return $minimum if $interval < $minimum;
    return $interval;
}

# _minimum_dashboard_command_interval_seconds()
# Returns the safety floor for dashboard-recursive collector commands.
# Input: none.
# Output: non-negative numeric interval floor in seconds.
sub _minimum_dashboard_command_interval_seconds {
    my ($self) = @_;
    my $value = $ENV{DEVELOPER_DASHBOARD_MIN_DASHBOARD_COMMAND_INTERVAL_SECONDS};
    return 30 if !defined $value || $value eq '';
    return 30 if $value !~ /^(?:\d+|\d*\.\d+)$/;
    return $value + 0;
}

# _is_dashboard_subcommand_collector($job)
# Detects shell-command collectors that re-enter dashboard itself, which are
# significantly heavier than direct shell probes and should not hot-loop by
# default.
# Input: collector job hash reference.
# Output: boolean true when the collector command dispatches dashboard.
sub _is_dashboard_subcommand_collector {
    my ( $self, $job ) = @_;
    return 0 if ref($job) ne 'HASH';
    my $command = $job->{command};
    return 0 if !defined $command || $command eq '';
    return 1 if $command =~ /\A\s*(?:dashboard|d2)(?:\s|$)/;
    return 1 if $command =~ /\A\s*(?:"[^"]*\/dashboard"|'[^']*\/dashboard'|[^\s]+\/dashboard)(?:\s|$)/;
    return 0;
}

# _start_loop_worker($job, $name)
# Starts one collector execution worker from the scheduling loop so long
# collector runs do not block future interval ticks.
# Input: collector job hash reference and collector name string.
# Output: worker pid integer in the parent or never returns in the child.
sub _start_loop_worker {
    my ( $self, $job, $name, $title ) = @_;
    if ( is_windows() ) {
        my @command = $self->_windows_background_worker_command( $name, $$ );
        return $self->_spawn_windows_background_command(@command);
    }
    my $pid = $self->_fork_process();
    die "Unable to fork collector worker '$name': $!" if !defined $pid;
    return $pid if $pid;
    return $self->_run_loop_worker( $job, $name, $title, $$ );
}

# _run_loop_worker($job, $name, $title, $loop_pid)
# Executes one scheduled collector run in a worker child process.
# Input: collector job hash reference, collector name string, loop process
# title string, and owning loop pid integer.
# Output: never returns in normal operation.
sub _run_loop_worker {
    my ( $self, $job, $name, $title, $loop_pid ) = @_;
    $0 = "dashboard collector worker: $name";
    setsid() if !is_windows();
    local $SIG{TERM} = 'DEFAULT';
    local $SIG{INT}  = 'DEFAULT';
    local $SIG{HUP}  = 'DEFAULT';
    my $ok = eval { $self->run_once($job); 1 };
    if ( !$ok ) {
        my $error = "$@";
        my $message = sprintf "[%s][%s] %s\n", _now_iso8601(), $name, $error;
        $self->{files}->append( 'collector_log', $message );
        $self->{collectors}->append_log_entry(
            $name,
            happened_at => _now_iso8601(),
            error       => $error,
            source      => 'loop error',
        );
        $self->_write_loop_state(
            $name,
            {
                pid          => $loop_pid || $$,
                name         => $name,
                process_name => $title || $self->_process_title($name),
                command      => $job->{command},
                cwd          => $job->{cwd},
                interval     => $job->{interval},
                schedule     => $job->{schedule} || ( $job->{cron} ? 'cron' : $job->{interval} ? 'interval' : 'manual' ),
                status       => 'error',
                error        => $error,
                heartbeat_at => _now_iso8601(),
            }
        );
        exit 255;
    }
    exit 0;
}

# _reap_finished_loop_workers($active_workers)
# Reaps exited scheduled worker children and removes them from the active set
# so bounded parallel collector modes do not leak zombies.
# Input: hash reference keyed by active worker pid.
# Output: count of reaped worker processes.
sub _reap_finished_loop_workers {
    my ( $self, $active_workers ) = @_;
    $active_workers ||= {};
    my $reaped = 0;
    for my $pid ( keys %{$active_workers} ) {
        my $waited = $self->_waitpid_nonblocking($pid);
        next if $waited != $pid;
        delete $active_workers->{$pid};
        $reaped++;
    }
    return $reaped;
}

# _waitpid_nonblocking($pid)
# Wraps non-blocking waitpid so loop-reap behaviour can be tested without
# relying on process timing races.
# Input: worker pid integer.
# Output: waitpid return value.
sub _waitpid_nonblocking {
    my ( $self, $pid ) = @_;
    return waitpid( $pid, 1 );
}

# _terminate_loop_workers($active_workers)
# Stops and reaps all active scheduled collector workers during loop shutdown.
# Input: hash reference keyed by active worker pid.
# Output: true value.
sub _terminate_loop_workers {
    my ( $self, $active_workers ) = @_;
    $active_workers ||= {};
    for my $pid ( keys %{$active_workers} ) {
        next if !$self->_pid_is_running($pid);
        kill 15, -$pid if !is_windows();
        kill 15, $pid;
    }
    for my $pid ( keys %{$active_workers} ) {
        for ( 1 .. 20 ) {
            last if !$self->_pid_is_running($pid);
            sleep 0.1;
        }
        if ( $self->_pid_is_running($pid) ) {
            kill 9, -$pid if !is_windows();
            kill 9, $pid;
        }
        $self->_reap_child_process($pid);
        delete $active_workers->{$pid};
    }
    return 1;
}

# _active_worker_pids($active_workers)
# Normalizes one active-worker tracking hash into a stable numeric pid list for
# persisted loop state and lifecycle diagnostics.
# Input: hash reference keyed by worker pid.
# Output: sorted list of numeric worker pids.
sub _active_worker_pids {
    my ( $self, $active_workers ) = @_;
    $active_workers ||= {};
    my @pids;
    for my $pid ( keys %{$active_workers} ) {
        next if !defined $pid;
        next if $pid !~ /^\d+$/;
        next if $pid <= 0;
        push @pids, $pid;
    }
    return sort { $a <=> $b } @pids;
}

# _settle_single_tick_workers($active_workers)
# Gives single-tick test loops a bounded chance to observe immediate worker
# completion before returning control to the caller.
# Input: hash reference keyed by active worker pid.
# Output: true value after the bounded settle window.
sub _settle_single_tick_workers {
    my ( $self, $active_workers ) = @_;
    $active_workers ||= {};
    for ( 1 .. 50 ) {
        last if !keys %{$active_workers};
        $self->_reap_finished_loop_workers($active_workers);
        last if !keys %{$active_workers};
        sleep 0.01;
    }
    return 1;
}

# _sleep_until_next_tick(%args)
# Sleeps until the next collector loop tick while periodically reaping any
# finished worker children so zombies do not sit around for an entire interval
# when a CHLD wakeup is missed.
# Input: interval seconds and active_workers hash reference.
# Output: true value after the bounded sleep window completes.
sub _sleep_until_next_tick {
    my ( $self, %args ) = @_;
    my $remaining = defined $args{interval} ? $args{interval} : 0;
    $remaining = 0 if $remaining < 0;
    my $active_workers = $args{active_workers} || {};
    my $slice = $remaining > 0.1 ? 0.1 : $remaining;
    while ( $remaining > 0 ) {
        $slice = $remaining if $remaining < $slice || $slice <= 0;
        sleep $slice;
        $remaining -= $slice;
        $remaining = 0 if $remaining < 0;
        $self->_reap_finished_loop_workers($active_workers);
    }
    return 1;
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
    my @state_worker_pids = $self->_state_active_worker_pids($name);
    $self->_terminate_loop_workers( { map { $_ => 1 } @state_worker_pids } ) if @state_worker_pids;
    my $already_reaped = $pid ? $self->_reap_child_process($pid) : 0;
    my $same_namespace = $pid ? $self->_same_pid_namespace($pid) : 0;
    if (
        $pid
        && !$already_reaped
        && $same_namespace
        && ( $self->_is_managed_loop( $pid, $name ) || $self->_state_confirms_managed_loop( $name, $pid ) )
      )
    {
        kill 15, $pid;
        for ( 1 .. 20 ) {
            last if !$self->_pid_is_running($pid);
            sleep 0.1;
        }
        kill 9, $pid if $self->_pid_is_running($pid);
        for ( 1 .. 20 ) {
            last if !$self->_pid_is_running($pid);
            sleep 0.1;
        }
        $self->_terminate_loop_workers( { map { $_ => 1 } $self->_state_active_worker_pids($name) } );
        $self->_reap_child_process($pid);
        die "Collector '$name' did not stop after TERM and KILL\n" if $self->_pid_is_running($pid);
    }
    if ( $pid && !$same_namespace ) {
        $self->_cleanup_loop_files($name);
        return $pid;
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
        if ( $pid && $self->_reap_child_process($pid) ) {
            $self->_cleanup_loop_files($name);
            next;
        }
        my $same_namespace = $pid ? $self->_same_pid_namespace($pid) : 0;
        if ( $pid && $same_namespace && ( $self->_is_managed_loop( $pid, $name ) || $self->_state_confirms_managed_loop( $name, $pid ) ) ) {
            push @running, { name => $name, pid => $pid, state => scalar $self->loop_state($name) };
            next;
        }
        next if $pid && !$same_namespace;
        $self->_cleanup_loop_files($name);
    }
    closedir $dh;

    my @sorted = @running;
    @sorted = sort _sort_loop_names @sorted;
    return @sorted;
}

# _state_active_worker_pids($name)
# Reads the persisted loop metadata for one collector and extracts any active
# worker pid list recorded by the loop process itself.
# Input: collector name string.
# Output: sorted list of numeric active worker pids.
sub _state_active_worker_pids {
    my ( $self, $name ) = @_;
    return () if !defined $name || $name eq '';
    my $state = eval { $self->loop_state($name) };
    return () if ref($state) ne 'HASH';
    my $active = $state->{active_worker_pids};
    return () if ref($active) ne 'ARRAY';
    my %seen;
    return sort { $a <=> $b } grep { defined && /^\d+$/ && $_ > 0 && !$seen{$_}++ } @{$active};
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
    my $last_error = '';
    for ( 1 .. 3 ) {
        open my $fh, '<', $file or die "Unable to read $file: $!";
        local $/;
        my $payload = scalar <$fh>;
        close $fh;
        if ( defined $payload && $payload ne '' ) {
            my $decoded = eval { json_decode($payload) };
            return $decoded if $decoded;
            $last_error = $@ || 'Unable to decode loop state JSON';
        }
        else {
            $last_error = "Loop state file $file was empty";
        }
        sleep 0.01 if $_ < 3;
    }
    die $last_error;
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
    return 0 if !$self->_same_pid_namespace($pid);
    my $marker = $self->_read_process_env_marker( $pid, 'DEVELOPER_DASHBOARD_LOOP_NAME' );
    return 1 if defined $marker && $marker eq $name;
    my $title = $self->_read_process_title($pid);
    return 0 if !defined $title || $title eq '';
    return $title eq $self->_process_title($name) ? 1 : 0;
}

# _state_confirms_managed_loop($name, $pid)
# Confirms a managed collector loop from persisted loop-state metadata when the
# process marker or title is not observable yet.
# Input: collector name string and process id integer.
# Output: boolean managed flag.
sub _state_confirms_managed_loop {
    my ( $self, $name, $pid ) = @_;
    return 0 if !defined $name || $name eq '';
    return 0 if !$pid || !kill 0, $pid;
    my $state = eval { $self->loop_state($name) };
    return 0 if !$state || ref($state) ne 'HASH';
    return 0 if ( $state->{pid} || 0 ) != $pid;
    return 0 if ( $state->{name} || '' ) ne $name;
    return 0 if ( $state->{process_name} || '' ) ne $self->_process_title($name);
    return 0 if ( $state->{status} || '' ) !~ /^(?:starting|running|error)$/;
    return 1;
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

# _read_process_state($pid)
# Reads one process state code so lifecycle checks can distinguish live
# processes from unreapable zombie entries.
# Input: process id integer.
# Output: one-letter process state string or undef.
sub _read_process_state {
    my ( $self, $pid ) = @_;
    my $proc = "/proc/$pid/stat";
    my $stat = $self->_read_proc_file($proc);
    if ( defined $stat && $stat ne '' && $stat =~ /^\d+\s+\(.*\)\s+(\S)/s ) {
        return $1;
    }

    my ( $state, undef, $exit_code ) = capture {
        system 'ps', '-o', 'stat=', '-p', $pid;
        return $? >> 8;
    };
    return if defined $exit_code && $exit_code != 0;
    $state =~ s/^\s+|\s+$//g if defined $state;
    return if !defined $state || $state eq '';
    return substr( $state, 0, 1 );
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

# _same_pid_namespace($pid)
# Confirms whether a loop pid belongs to the current pid namespace so shared
# home runtimes do not stop collector loops from sibling containers.
# Input: process id integer.
# Output: boolean true when the pid namespace matches or procfs metadata is unavailable.
sub _same_pid_namespace {
    my ( $self, $pid ) = @_;
    return 0 if !defined $pid || $pid !~ /^\d+$/ || $pid < 1;
    my $current = $self->_pid_namespace_id($$);
    my $target  = $self->_pid_namespace_id($pid);
    return 1 if !defined $current || $current eq '';
    return 1 if !defined $target  || $target eq '';
    return $current eq $target ? 1 : 0;
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
    if ( is_windows() ) {
        sleep 0.05;
    }
    else {
        $self->{paths}->secure_file_permissions($tmp);
    }
    $self->_replace_state_file( $tmp, $file );
    $self->{paths}->secure_file_permissions($file);
    return \%state;
}

# _replace_state_file($source, $target)
# Replaces one collector state file with a prepared temporary file, including a
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
# fallback when Perl's in-process rename fails inside pseudo-forked collector
# flows.
# Input: source file path and destination file path.
# Output: boolean success flag and optional failure text string.
sub _replace_path_via_powershell {
    my ( $self, $source, $target ) = @_;
    return ( 0, '' ) if !is_windows();
    my $powershell = $self->_powershell_command;
    return ( 0, 'Unable to resolve a PowerShell executable for Windows state-file replacement' )
      if !defined $powershell || $powershell eq '';
    my @script = (
        q{$ErrorActionPreference = 'Stop'},
        'Move-Item -LiteralPath '
          . _powershell_single_quote($source)
          . ' -Destination '
          . _powershell_single_quote($target)
          . ' -Force',
    );
    my ( $stdout, $stderr, $exit_code ) = capture {
        system $powershell, '-NoLogo', '-NoProfile', '-Command', join '; ', @script;
        return $? >> 8;
    };
    return ( 1, '' ) if $exit_code == 0;
    return ( 0, join '', grep { defined && $_ ne '' } $stderr, $stdout );
}

# _overwrite_state_file_in_place($source, $target)
# Rewrites one collector state target in place from the prepared temporary
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

# _windows_background_loop_command($name)
# Builds the detached helper command used to host one collector loop on
# Windows without entering the pseudo-fork code path.
# Input: collector name string.
# Output: command list suitable for Start-Process.
sub _windows_background_loop_command {
    my ( $self, $name ) = @_;
    my $core = $self->_dashboard_core_helper_path('collector-loop-foreground');
    my $perl = $self->_current_perl_command;
    return (
        $perl,
        $core,
        'collector-loop-foreground',
        '--name',
        $name,
    );
}

# _windows_background_worker_command($name, $loop_pid)
# Builds the detached helper command used to host one collector worker on
# Windows when the loop schedule allows overlapping runs.
# Input: collector name string and owning loop pid integer.
# Output: command list suitable for Start-Process.
sub _windows_background_worker_command {
    my ( $self, $name, $loop_pid ) = @_;
    my $core = $self->_dashboard_core_helper_path('collector-worker-foreground');
    my $perl = $self->_current_perl_command;
    return (
        $perl,
        $core,
        'collector-worker-foreground',
        '--name',
        $name,
        '--loop-pid',
        $loop_pid,
    );
}

# _current_perl_command()
# Resolves a runnable Perl interpreter path for detached Windows helper
# launches, including local::lib sessions where $^X is no longer valid.
# Input: none.
# Output: executable path string.
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

# _dashboard_core_helper_path($command)
# Resolves the staged private _dashboard-core helper used by detached Windows
# collector loop and worker launches.
# Input: internal helper command string.
# Output: absolute helper path string.
sub _dashboard_core_helper_path {
    my ( $self, $command ) = @_;
    $command ||= 'collector-loop-foreground';
    my $staged = File::Spec->catfile( $self->{paths}->home_runtime_root, 'cli', 'dd', '_dashboard-core' );
    return $staged if $self->_helper_file_supports_internal_command( $staged, $command );

    my $shipped = eval { Developer::Dashboard::InternalCLI::_helper_asset_path('_dashboard-core') };
    $shipped = '' if !defined $shipped;
    return $shipped if $self->_helper_file_supports_internal_command( $shipped, $command );

    return $staged;
}

# _helper_file_supports_internal_command($path, $command)
# Checks whether one helper source file contains the requested private command
# branch so Windows collector launches can avoid stale staged helpers.
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
    return $content =~ /\Q$command\E/ ? 1 : 0;
}

# _spawn_windows_background_command(@command)
# Launches one detached background Windows helper command and returns the
# spawned pid.
# Input: command list.
# Output: spawned pid integer.
sub _spawn_windows_background_command {
    my ( $self, @command ) = @_;
    my $powershell = $self->_powershell_command;
    die "Unable to launch detached Windows collector process: powershell is unavailable\n"
      if !defined $powershell || $powershell eq '';

    my $stdout_log = $self->{files}->collector_log;
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
        system $powershell, '-NoLogo', '-NoProfile', '-Command', join '; ', @script;
        return $? >> 8;
    };
    die "Unable to launch detached Windows collector process: $stderr$stdout"
      if $exit_code != 0;
    my ($pid) = grep { defined $_ && /^\d+$/ && $_ > 0 } split /\r?\n/, ( $stdout || '' );
    return $pid;
}

# _powershell_command()
# Resolves the Windows PowerShell executable path for state-file replacement
# fallback commands, even when PATH has not been normalized yet inside a
# pseudo-forked collector branch.
# Input: none.
# Output: executable path string or empty string when no usable PowerShell
# binary can be found.
sub _powershell_command {
    my ($self) = @_;
    return '' if !is_windows();
    return command_in_path('powershell')     if command_in_path('powershell');
    return command_in_path('powershell.exe') if command_in_path('powershell.exe');
    my $system_root = $ENV{SystemRoot} || 'C:\\Windows';
    my $fallback = File::Spec->catfile( $system_root, 'System32', 'WindowsPowerShell', 'v1.0', 'powershell.exe' );
    return $fallback if -f $fallback;
    return '';
}

# _powershell_single_quote($value)
# Escapes one literal string for safe use inside a single-quoted PowerShell
# command fragment.
# Input: raw scalar string.
# Output: single-quoted PowerShell literal string.
sub _powershell_single_quote {
    my ($value) = @_;
    $value = '' if !defined $value;
    $value =~ s/'/''/g;
    return "'$value'";
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

# _close_inherited_fds(%args)
# Closes inherited non-stdio descriptors in detached collector children so
# background loops do not keep caller-side capture handles open after the
# lifecycle command exits.
# Input: optional keep array reference of descriptor integers and optional
# close_ipc boolean for socketpair/anon_inode cleanup.
# Output: true value.
sub _close_inherited_fds {
    my ( $self, %args ) = @_;
    my %keep;
    for my $fd ( @{ $args{keep} || [] } ) {
        next if !defined $fd;
        next if $fd !~ /^\d+$/;
        $keep{$fd} = 1;
    }
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
# detached children can close inherited caller pipes safely.
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
# IPC endpoint that a detached collector child should close after stdio has
# been redirected.
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

# _reap_child_process($pid)
# Reaps one managed collector child owned by the current process when it has
# already exited.
# Input: process id integer.
# Output: boolean true when waitpid reaped the child.
sub _reap_child_process {
    my ( $self, $pid ) = @_;
    return 0 if !defined $pid || $pid !~ /^\d+$/ || $pid < 1;
    my $waited = waitpid( $pid, 1 );
    return $waited == $pid ? 1 : 0;
}

# _process_exists($pid)
# Checks whether the current process can still signal one process id.
# Input: process id integer.
# Output: boolean true when signal 0 succeeds.
sub _process_exists {
    my ( $self, $pid ) = @_;
    return kill( 0, $pid ) ? 1 : 0;
}

# _pid_is_running($pid)
# Determines whether one collector loop pid is still alive after opportunistic
# child reaping.
# Input: process id integer.
# Output: boolean true when the pid is still running.
sub _pid_is_running {
    my ( $self, $pid ) = @_;
    return 0 if !defined $pid || $pid !~ /^\d+$/ || $pid < 1;
    return 0 if $self->_reap_child_process($pid);
    return 0 if ( $self->_read_process_state($pid) || '' ) eq 'Z';
    return $self->_process_exists($pid) ? 1 : 0;
}

# _detach_process_session()
# Detaches the current collector loop from the parent session when the active
# platform supports POSIX setsid.
# Input: none.
# Output: true value after detaching or after explicitly skipping setsid on
# platforms that do not implement it.
sub _detach_process_session {
    my ($self) = @_;
    return 1 if is_windows();
    setsid();
    return 1;
}

# _scrub_coverage_environment()
# Removes Devel::Cover-specific environment variables from managed collector
# children so daemonized loop processes do not inherit repository test
# instrumentation.
# Input: none.
# Output: none.
sub _scrub_coverage_environment {
    my ($self) = @_;
    return if !$self->_coverage_instrumentation_active;
    delete @ENV{qw(PERL5OPT HARNESS_PERL_SWITCHES)};
    return;
}

# _coverage_instrumentation_active()
# Detects whether the current process environment requests Devel::Cover
# instrumentation.
# Input: none.
# Output: boolean true when PERL5OPT or HARNESS_PERL_SWITCHES mentions
# Devel::Cover.
sub _coverage_instrumentation_active {
    my ($self) = @_;
    my $perl5opt = join ' ', grep { defined && $_ ne '' } @ENV{qw(PERL5OPT HARNESS_PERL_SWITCHES)};
    return $perl5opt =~ /Devel::Cover/ ? 1 : 0;
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
    my $stamp = strftime( '%Y-%m-%dT%H:%M%z', @now );
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
    my %dashboard_env = %{ Developer::Dashboard::PerlEnv->dashboard_child_env() };
    local @ENV{ keys %dashboard_env } = values %dashboard_env;
    my $timed_out = 0;
    my ( $stdout, $stderr, $exit_code ) = capture {
        local $SIG{ALRM} = sub { die "__COLLECTOR_TIMEOUT__\n" };
        alarm( int( ( $timeout_ms + 999 ) / 1000 ) );
        my $ok = eval {
            system shell_command_argv( $cmd, login => 0 );
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
    my ( $self, $name, $status, $active_workers ) = @_;
    $self->_terminate_loop_workers($active_workers) if ref($active_workers) eq 'HASH';
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
    $SIGNAL_RUNNER->_shutdown_loop( $SIGNAL_LOOP_NAME, 'stopped', $SIGNAL_LOOP_WORKERS );
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
# Returns the current local timestamp in ISO-8601 form with timezone offset.
# Input: none.
# Output: timestamp string.
sub _now_iso8601 {
    my @t = localtime();
    return strftime( '%Y-%m-%dT%H:%M:%S%z', @t );
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
state, shell-command collectors, Perl-code collectors, and TT-backed
collector indicator icon rendering from stdout JSON.

=head1 METHODS

=head2 new, run_once, start_loop, stop_loop, running_loops, loop_state

Construct and manage collector execution.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module manages live collector execution. It turns stored collector jobs into processes, captures their output, updates collector state files, renders TT-backed collector indicator icons from stdout JSON when configured, tracks pid ownership, and exposes the start/stop/restart/run/status lifecycle used by the CLI and web-facing status features.

=head1 WHY IT EXISTS

It exists because collector process control is more than a single C<system()> call. The dashboard needs a single owner for pid validation, output capture, environment preparation, enabled/disabled state, and restart behavior so the prompt and browser status strip can trust the result.

=head1 WHEN TO USE

Use this file when changing collector process spawning, pid validation, restart semantics, background job cleanup, TT-backed indicator icon rendering, or the contract between collector execution and the persisted collector state.

=head1 HOW TO USE

Construct it with the path registry and collector store, then call the lifecycle methods for one collector name. Keep process-management behavior and TT-backed collector icon rendering here; the CLI wrappers should only parse arguments and print the returned state.

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
