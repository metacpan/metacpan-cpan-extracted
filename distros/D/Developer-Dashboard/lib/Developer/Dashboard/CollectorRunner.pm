package Developer::Dashboard::CollectorRunner;

use strict;
use warnings;

our $VERSION = '5.51';

use Capture::Tiny qw(capture);
use Cwd qw(cwd);
use File::Spec;
use File::Temp qw(tempfile);
use POSIX qw(close setsid strftime);
use Template;
use Time::HiRes qw(sleep time);

use Developer::Dashboard::InternalCLI ();
use Developer::Dashboard::FileSlurp qw(slurp_file);
use Developer::Dashboard::JSON qw(json_encode json_decode);
use Developer::Dashboard::Config;
use Developer::Dashboard::PerlEnv ();
use Developer::Dashboard::CommandRunner ();
use Developer::Dashboard::TimeUtils qw(_now_iso8601);
use Developer::Dashboard::Platform qw(command_in_path is_windows shell_command_argv);
use Developer::Dashboard::ProcessSupervision qw(
    _current_perl_command
    _descriptor_is_inherited_pipe
    _fork_process
    _open_file_descriptors
    _overwrite_state_file_in_place
    _pid_is_running
    _pid_namespace_id
    _powershell_single_quote
    _process_exists
    _read_process_env_marker
    _reap_child_process
    _powershell_command
    _rename_path
    _replace_state_file
    _unlink_path
    _helper_file_supports_internal_command
    _same_pid_namespace
    _close_inherited_fds
    _dashboard_core_helper_path
);

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

# DD-881: the cwd-alias fallback below must dispatch ONLY to these no-arg
# PathRegistry directory getters - never to any other public method
# (register_named_paths/unregister_named_path mutate state, resolve_dir
# and others take required arguments), or a job-config-supplied cwd that
# merely collides with a method name becomes an arbitrary method call.
# Mirrors PathRegistry's own %RESOLVABLE_ACCESSOR (DD-870).
my %RESOLVABLE_ACCESSOR = map { $_ => 1 } qw(
  home runtime_root home_runtime_root home_runtime_path project_runtime_root
  state_root state_base_root cache_root home_cache_root logs_root
  dashboards_root bookmarks bookmarks_root cli_root skills_root
  collectors_root indicators_root sessions_root temp_root config_root
  auth_root repo_dashboard_root users_root current_project_root
  current_working_directory cwd
);

# run_once($job)
# Executes a collector job a single time with cwd/env/timeout handling; cwd
# may be a built-in accessor, configured path alias, or skill Folder.pm alias.
# Input: collector job hash reference.
# Output: result hash reference with stdout, stderr, exit_code, and timed_out.
sub run_once {
    my ( $self, $job ) = @_;
    die 'Collector job must be a hash' if ref($job) ne 'HASH';
    my $name = $job->{name} || die 'Collector job missing name';
    my ( $mode, $source ) = $self->_collector_source($job);

    my $cwd = $job->{cwd};
    $cwd = cwd() if !$cwd;
    if ( !File::Spec->file_name_is_absolute($cwd) && $RESOLVABLE_ACCESSOR{$cwd} ) {
        $cwd = $self->{paths}->$cwd();
    }
    elsif ( !File::Spec->file_name_is_absolute($cwd) ) {
        $cwd = $self->_resolve_collector_cwd_alias($cwd);
    }

    die "Collector cwd '$cwd' does not exist" if !-d $cwd;

    my $started_at = _now_iso8601( tz => "local" );
    # Normalize the timeout to milliseconds once and persist it under its own
    # field. Storing a millisecond value under the seconds-keyed 'timeout' field
    # made a persisted-and-reloaded job (for example the Windows worker re-read,
    # and the watchdog stale window) re-inflate the timeout by 1000x, so keep
    # 'timeout' as seconds and record the derived 'timeout_ms' explicitly.
    my $timeout_ms = $self->_normalize_timeout_ms($job);
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
            timeout    => $job->{timeout},
            timeout_ms => $timeout_ms,
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
            schedule        => $self->_schedule_mode($job),
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
            timeout_ms => $timeout_ms,
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

# _resolve_collector_cwd_alias($name)
# Resolves a relative collector cwd from configured aliases, then installed
# skill Folder.pm aliases, without dispatching arbitrary registry methods.
# Input: relative cwd or alias string.
# Output: resolved path string, or the original string if no alias applies.
sub _resolve_collector_cwd_alias {
    my ( $self, $name ) = @_;
    my $paths = $self->{paths};
    return $name if !defined $name || ref($name);
    return $name if !$paths->can('named_paths') || !$paths->can('resolve_dir');

    my $config = Developer::Dashboard::Config->for_paths($paths);
    $paths->register_named_paths( $config->path_aliases );
    my $configured = $paths->named_paths;
    return $paths->resolve_dir($name) if exists $configured->{$name};

    if ( $name =~ /\A[A-Za-z0-9_.-]+\.[A-Za-z0-9_.-]+\z/ ) {
        require Developer::Dashboard::CLI::Paths;
        my $target = Developer::Dashboard::CLI::Paths::_skill_folder_alias_target(
            paths => $paths,
            name  => $name,
        );
        return $target if defined $target;
    }

    return $name;
}

# _normalize_timeout_ms($job)
# Normalizes a collector job timeout to milliseconds, preferring an explicit
# millisecond value and otherwise converting the seconds-keyed timeout, so a
# persisted-and-reloaded job keeps the same effective timeout instead of being
# re-inflated by 1000x.
# Input: collector job hash reference.
# Output: timeout in milliseconds, or undef when no timeout is configured.
sub _normalize_timeout_ms {
    my ( $self, $job ) = @_;
    return undef if ref($job) ne 'HASH';
    return $job->{timeout_ms} if $job->{timeout_ms};
    return $job->{timeout} * 1000 if $job->{timeout};
    return undef;
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
    my $schedule_mode = $self->_schedule_mode($job);
    die "Collector '$name' uses manual schedule and should be run on demand" if $schedule_mode eq 'manual';
    if ( $schedule_mode eq 'cron' ) {
        my ( undef, $cron_error ) = _parse_cron_expression( $job->{cron} );
        die "Collector '$name' has invalid cron expression: $cron_error\n" if $cron_error;
    }

    # DD-737: a collector with neither 'command' nor 'code' used to be forked
    # into a loop anyway, which then died on its very first tick inside
    # _collector_source and every tick after that, forever, without ever
    # disabling itself - observed on a real machine as hundreds of unreaped
    # zombie loop-worker processes from one permanently misconfigured
    # collector. _collector_source already performs exactly the check this
    # needs; running it here, before any pidfile or fork, turns a doomed
    # loop into an immediate, visible failure instead.
    $self->_collector_source($job);

    my $pidfile = $self->_pidfile($name);
    my $title   = $self->_process_title($name);

    my $adopted_pid = $self->_adopt_existing_loop_if_running(
        pidfile       => $pidfile,
        name          => $name,
        title         => $title,
        interval      => $interval,
        schedule_mode => $schedule_mode,
    );
    return $adopted_pid if defined $adopted_pid;

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
        # The loop STATE is written before the pidfile, and the order is
        # load-bearing rather than stylistic.
        #
        # running_loops keys on the pidfile: it lists pidfiles, and for each one
        # decides whether that pid is a loop it manages. It recognises the pid
        # either by its process title or by this recorded state. Written the other
        # way round there is a window - pidfile present, state not yet written -
        # in which a freshly forked child that has not yet adopted its title is
        # unrecognisable by either route. A concurrent running_loops in any other
        # process then treats a perfectly healthy loop as an orphan and unlinks
        # its pidfile.
        #
        # The consequence is the exact failure the surrounding code exists to
        # prevent: stop_loop returns early on a missing pidfile so the loop can no
        # longer be stopped by name, and start_loop consults the loop-state
        # fallback only inside its `-f $pidfile` branch, so the next supervisor
        # start forks a DUPLICATE. The fallback that would have caught it cannot
        # fire, because the sweep deleted the evidence it reads.
        #
        # Writing the state first closes the window instead of widening a wait:
        # the pidfile - the thing the sweep keys on - never exists without the
        # state that identifies it.
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
                started_at   => _now_iso8601( tz => "local" ),
                heartbeat_at => _now_iso8601( tz => "local" ),
            }
        );
        open my $fh, '>', $pidfile or die "Unable to write $pidfile: $!";
        print {$fh} $pid;
        close $fh;
        $self->{paths}->secure_file_permissions($pidfile);
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

# _adopt_existing_loop_if_running(%args)
# Checks whether a collector loop is already running for this name and, if
# so, adopts it - rewriting its recorded state (and repairing a missing
# pidfile) rather than letting start_loop fork a duplicate. Runs entirely
# before any fork, so it carries none of start_loop's fork-timing risk.
# Input: pidfile path, collector name, process title, effective interval,
# and schedule mode.
# Output: the adopted pid if a genuinely running loop was found and adopted;
# undef if start_loop should proceed to fork a fresh loop.
sub _adopt_existing_loop_if_running {
    my ( $self, %args ) = @_;
    my ( $pidfile, $name, $title, $interval, $schedule_mode )
      = @args{qw(pidfile name title interval schedule_mode)};

    # The pidfile is a RECORD of what is running, not the authority on it. Asking
    # only the file is what let 27 supervisor loops accumulate for a collector
    # declared singleton: once the file was gone - a crash before the write, a
    # cleanup, a /tmp sweep - every start forked another loop that nothing could
    # see, stop or count, and each one went on spawning work every interval.
    #
    # So if the record is missing, ask the process table before forking, then
    # consult the parent's state record if process-title matching has not caught
    # a newly forked child yet. An existing loop is adopted and its record
    # rewritten, which is both the correct outcome and the repair of the missing
    # file.
    my $existing = -f $pidfile ? do { my $recorded = slurp_file($pidfile); chomp $recorded; $recorded } : undef;
    if (!$existing) {
        $existing = $self->_find_running_loop($name);
        if (!$existing) {
            # The parent records the forked pid and its intended title before
            # returning from start_loop. A concurrent start can therefore see a
            # valid state record while the child is still adopting that title,
            # which makes process-table matching temporarily miss it. Consult
            # that parent-written state before deciding to fork another loop.
            my $state = $self->loop_state($name);
            my $state_pid = ref($state) eq 'HASH' ? $state->{pid} : undef;
            $existing = $state_pid
              if defined $state_pid
              && "$state_pid" =~ /\A[1-9][0-9]*\z/
              && $self->_state_confirms_managed_loop( $name, $state_pid );
        }
    }

    # Truthy rather than merely defined, and that is the guarantee the line above
    # already gives: an empty or zero pidfile leaves $existing false, and that case
    # is replaced by process-table and state discovery, each of which returns a
    # live pid or undef. So a false-but-defined $existing cannot arrive here.
    #
    # This read `defined $existing` with a further `$pid &&` inside, and that inner
    # test was the last genuinely uncovered condition in lib (DD-532): unreachable
    # by construction, while looking reachable enough that three rounds of theories
    # were spent on an unrelated line before anyone read the per-outcome counts.
    # Deleting the dead test beats annotating it - the guarantee is now stated once,
    # where it actually holds, rather than re-checked where it cannot fail.
    if ($existing) {
        my $pid = $existing;
        # Recognize an already-running managed loop by its recorded state as
        # well as by proc/ps identity, so the supervisor's start_loop does not
        # create a DUPLICATE loop when it races the fresh loop before that loop
        # has set its process title.
        if ( $self->_is_managed_loop( $pid, $name ) || $self->_state_confirms_managed_loop( $name, $pid ) ) {
            $self->_write_loop_state(
                $name,
                {
                    pid          => $pid,
                    name         => $name,
                    process_name => $title,
                    interval     => $interval,
                    schedule     => $schedule_mode,
                    status       => 'running',
                    heartbeat_at => _now_iso8601( tz => "local" ),
                }
            );

            # Repair the missing record, AFTER the state and never before:
            # running_loops keys on the pidfile and identifies the pid from the
            # recorded state, so a pidfile existing without one is exactly the
            # window DD-488 closed. Adopting a loop found in the process table and
            # leaving its pidfile absent would fix the duplicate while leaving the
            # collector invisible to stop and to status, which both key off that
            # file - one missing record causing two more symptoms.
            #
            # close is unchecked, like the original write further down: checking it
            # raised "Bad file descriptor" and killed start_loop outright, which is
            # a far worse outcome than an unclosed handle.
            if ( !-f $pidfile ) {
                open my $fh, '>', $pidfile or die "Unable to write $pidfile: $!";
                print {$fh} $pid;
                close $fh;
                $self->{paths}->secure_file_permissions($pidfile);
            }
            return $pid;
        }
        $self->_cleanup_loop_files($name);
    }

    return undef;
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
    my $title               = $args{title};
    $title = $self->_process_title($name) if !$title;
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
            started_at   => _now_iso8601( tz => "local" ),
            heartbeat_at => _now_iso8601( tz => "local" ),
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
    my $title         = $args{title};
    $title = $self->_process_title($name) if !$title;
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
                heartbeat_at => _now_iso8601( tz => "local" ),
            }
        );
        my $due = $self->_job_is_due( $job, $name );
        if ( $due && scalar( keys %active_workers ) < $max_parallel ) {
            my $worker_pid = eval { $self->_start_loop_worker( $job, $name, $title ) };
            if ($@) {
                my $error = "$@";
                my $message = sprintf "[%s][%s] %s\n", _now_iso8601( tz => "local" ), $name, $error;
                $self->{files}->append( 'collector_log', $message );
                $self->{collectors}->append_log_entry(
                    $name,
                    happened_at => _now_iso8601( tz => "local" ),
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
                        heartbeat_at => _now_iso8601( tz => "local" ),
                        error        => $error,
                    }
                );
            }
            elsif ($worker_pid) {
                $active_workers{$worker_pid} = 1;
                $self->_write_loop_state(
                    $name,
                    {
                        active_runs        => scalar keys %active_workers,
                        active_worker_pids => [ $self->_active_worker_pids( \%active_workers ) ],
                    }
                );
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
        my $message = sprintf "[%s][%s] %s\n", _now_iso8601( tz => "local" ), $name, $error;
        $self->{files}->append( 'collector_log', $message );
        $self->{collectors}->append_log_entry(
            $name,
            happened_at => _now_iso8601( tz => "local" ),
            error       => $error,
            source      => 'loop error',
        );
        my $state_pid      = $loop_pid;
        $state_pid = $$ if !$state_pid;
        my $state_title    = $title;
        $state_title = $self->_process_title($name) if !$state_title;
            my $state_schedule = $self->_schedule_mode($job);
        $self->_write_loop_state(
            $name,
            {
                pid          => $state_pid,
                name         => $name,
                process_name => $state_title,
                command      => $job->{command},
                cwd          => $job->{cwd},
                interval     => $job->{interval},
                schedule     => $state_schedule,
                status       => 'error',
                error        => $error,
                heartbeat_at => _now_iso8601( tz => "local" ),
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
        # Send the group SIGKILL unconditionally: a command child that ignores
        # SIGTERM can still be alive in the worker's process group even after
        # the worker (group leader) has exited, and a running leader is only
        # signalled directly when it is still alive. kill on an empty group is a
        # harmless no-op.
        kill 9, -$pid if !is_windows();
        kill 9, $pid if $self->_pid_is_running($pid);
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
        $slice = $remaining if $remaining < $slice;
        sleep $slice;
        $remaining -= $slice;
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

    # A missing pidfile does not mean nothing is running. Returning here - which
    # this did - is how a stop reported success while supervisor loops kept
    # firing every interval, and it is the same wrong assumption start_loop made.
    my $pid;
    if ( -f $pidfile ) {
        $pid = slurp_file($pidfile);
        chomp $pid;
    }
    else {
        $pid = $self->_find_running_loop($name);
        return if !defined $pid;
    }
    my @state_worker_pids = $self->_state_active_worker_pids($name);
    my $already_reaped = $pid ? $self->_reap_child_process($pid) : 0;
    my $same_namespace = $pid ? $self->_same_pid_namespace($pid) : 0;
    if (
        $pid
        && !$already_reaped
        && $same_namespace
        && ( $self->_is_managed_loop( $pid, $name ) || $self->_state_confirms_managed_loop( $name, $pid ) )
      )
    {
        # Kill the loop FIRST so it stops spawning new workers and its own
        # SIGTERM handler can terminate its accurate in-memory worker set. Scale
        # the grace to the recorded worker count so the loop is not KILL-9'd
        # mid-cleanup (its handler may spend up to ~2s per stubborn worker).
        kill 15, $pid;
        my $grace = 20 + 20 * scalar(@state_worker_pids);
        for ( 1 .. $grace ) {
            last if !$self->_pid_is_running($pid);
            sleep 0.1;
        }
        kill 9, -$pid if !is_windows();
        kill 9, $pid  if $self->_pid_is_running($pid);
        for ( 1 .. 20 ) {
            last if !$self->_pid_is_running($pid);
            sleep 0.1;
        }
        # Backstop after the loop is gone: sweep any worker the loop did not
        # reap (the KILL escalation path skips its handler). Fix A keeps the
        # persisted set complete, and the sweep kills each worker's process
        # group so command subtrees are reaped too.
        $self->_terminate_loop_workers( { map { $_ => 1 } $self->_state_active_worker_pids($name) } );
        $self->_reap_child_process($pid);
        die "Collector '$name' did not stop after TERM and KILL\n" if $self->_pid_is_running($pid);
    }
    else {
        # The loop is not signalable here (already dead/crashed, foreign
        # namespace, or unrecognized): still sweep any workers recorded in state
        # so a crashed loop does not leave orphaned worker subtrees behind.
        $self->_terminate_loop_workers( { map { $_ => 1 } @state_worker_pids } ) if @state_worker_pids;
    }
    $self->{collectors}->mark_stopped($name);
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
        my $pid  = eval { slurp_file( File::Spec->catfile( $root, $entry ) ) };
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
        if ( $payload ne '' ) {
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

# _find_running_loop($name)
# Finds a supervisor loop already running for one collector by asking the
# process table, for use when no pidfile records it.
# Input: collector name string.
# Output: process id of a live managed loop, or undef when none is running.
#
# This exists because the pidfile is a record and not the authority. A record can
# be lost while the thing it describes keeps running, and when that happened here
# every subsequent start forked another supervisor: 27 were alive at once for a
# singleton collector, each firing every 900 seconds, while stop knew about one
# and status reported none.
#
# /proc is read directly rather than shelling out to ps, because a process search
# spawned from here would match itself - a trap this project has already been
# caught by twice, once killing its own command and once reading a finished job
# as still running for four hours.
sub _find_running_loop {
    my ( $self, $name ) = @_;
    return if !defined $name || $name eq '';

    opendir my $dh, '/proc' or return;
    my @candidates = sort { $a <=> $b } grep { /\A[0-9]+\z/ } readdir $dh;
    closedir $dh;

    # Identity by TITLE, not by the environment marker. _is_managed_loop accepts
    # either, which is right when confirming a pid you already have - but the
    # marker is set into %ENV and every forked child INHERITS it, so a collector's
    # own worker is indistinguishable from its supervisor by that test. Searching
    # on it found two "supervisors" four pids apart: the loop and the command it
    # had just spawned. A supervisor sets its own title; a worker does not carry
    # its parent's.
    my $title = $self->_process_title($name);
    for my $pid (@candidates) {
        next if $pid == $$;

        # DD-1054: skip a candidate whose /proc/$pid/cmdline is READABLE but
        # EMPTY before ever calling _read_process_title - that is the ordinary,
        # permanent shape of a kernel thread (kworker, ksoftirqd, ...), never a
        # race, and _read_process_title falls back to spawning a `ps` SUBPROCESS
        # per pid when cmdline is empty. On a host with hundreds of kernel
        # threads that made every collector start/check scan cost one subprocess
        # spawn per thread - reproduced live: 943 empty-cmdline /proc entries on
        # one host made `dashboard serve --foreground` hang 90+ seconds with zero
        # output whenever any skill declared a collector. An empty cmdline can
        # never equal $title (a non-empty string), so skipping it here costs
        # nothing correct and removes the pathological cost entirely. Only a
        # genuinely UNREADABLE cmdline (undef - the process vanished between
        # readdir and this read) still falls through to the ps fallback below,
        # which is the race _read_process_title's own fallback exists for.
        my $cmdline = $self->_read_proc_file("/proc/$pid/cmdline");
        next if defined $cmdline && $cmdline eq '';

        my $running = $self->_read_process_title($pid);
        next if !defined $running || $running ne $title;
        # A process carrying this collector's exact title while living in a
        # DIFFERENT pid namespace cannot be constructed from a test without a
        # container runtime.
        return $pid if $self->_same_pid_namespace($pid);
    }
    return;
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
    # The recorded pid+name+process-title identity is strong evidence we own
    # this loop even when /proc and ps are unavailable (Windows), so recognize
    # any live recorded loop except one that has already marked itself stopped.
    return 0 if ( $state->{status} || '' ) eq 'stopped';
    return 1;
}


# _read_process_title($pid)
# Reads the command line title for a process.
# Input: process id integer.
# Output: process title string or undef.
sub _read_process_title {
    my ( $self, $pid ) = @_;
    # A QUERY MUST NOT DECIDE ITS CALLER'S EXIT STATUS (DD-585). The ps fallback
    # below runs whenever /proc is unreadable for this pid, which is the ordinary
    # case for a process that vanished between readdir and the read. ps then exits
    # 1 and leaves $? at 256 - and Perl's exit status is whatever $? holds at exit.
    # A caller doing this inside an END block therefore inherits a false failure:
    # t/153 walked /proc in its END, one vanished pid poisoned $?, and Test::Builder
    # (whose END runs after, since END blocks are last-in-first-out) turned it into
    # "exited with 256" and failed the file at 255 with all 15 subtests passing.
    # CI run 32011417394 died exactly that way. Containing $? here fixes it for
    # every caller rather than for the one test that noticed.
    local $?;
    my $proc = "/proc/$pid/cmdline";
    my $cmdline = $self->_read_proc_file($proc);
    if ( defined $cmdline && $cmdline ne '' ) {
        $cmdline =~ s/\0/ /g;
        $cmdline =~ s/\s+$//;
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
    # A QUERY MUST NOT DECIDE ITS CALLER'S EXIT STATUS (DD-585). The ps fallback
    # below runs whenever /proc is unreadable for this pid, which is the ordinary
    # case for a process that vanished between readdir and the read. ps then exits
    # 1 and leaves $? at 256 - and Perl's exit status is whatever $? holds at exit.
    # A caller doing this inside an END block therefore inherits a false failure:
    # t/153 walked /proc in its END, one vanished pid poisoned $?, and Test::Builder
    # (whose END runs after, since END blocks are last-in-first-out) turned it into
    # "exited with 256" and failed the file at 255 with all 15 subtests passing.
    # CI run 32011417394 died exactly that way. Containing $? here fixes it for
    # every caller rather than for the one test that noticed.
    local $?;
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



# _pending_loop_state_file($file)
# Builds the per-writer staging path _write_loop_state writes to before the
# atomic rename into $file. Its own sub (matching the pattern in
# Auth.pm/Collector.pm/SessionStore.pm/Zipper.pm) exists so a coverage test
# can exercise the real path-generation logic directly. DD-850: pid+wall-
# clock-second alone is NOT collision-safe (see DD-848) - the per-process
# monotonic counter below guarantees no two calls from one process ever
# collide, whatever the timing; cross-process collision remains prevented
# by pid uniqueness among live processes.
# Input: final destination file path string.
# Output: staging file path string.
my $_loop_state_seq = 0;

sub _pending_loop_state_file {
    my ( $self, $file ) = @_;
    return sprintf '%s.%s.%s.%s.pending', $file, $$, time, ++$_loop_state_seq;
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
    my $tmp = $self->_pending_loop_state_file($file);
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




# _replace_path_via_powershell($source, $target)
# Uses the native Windows Move-Item path as a last-resort file replacement
# fallback when Perl's in-process rename fails inside pseudo-forked collector
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
    my $powershell = _powershell_command;
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
    return ( 0, join '', grep { $_ ne '' } $stderr, $stdout );
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


# _spawn_windows_background_command(@command)
# Launches one detached background Windows helper command and returns the
# spawned pid.
# Input: command list.
# Output: spawned pid integer.
sub _spawn_windows_background_command {
    my ( $self, @command ) = @_;

    # DD-597: system() below mutates the caller's global $? as a side effect;
    # without this guard that stays set in the caller's process after this
    # sub returns.
    local $?;
    my $powershell = _powershell_command;
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
    my ($pid) = grep { /^\d+$/ && $_ > 0 } split /\r?\n/, ( $stdout || '' );
    return $pid;
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

# _schedule_mode($job)
# Resolves the schedule mode of one collector job: an explicit schedule wins,
# otherwise a cron expression, then an interval, and finally manual.
# Input: collector job hash reference.
# Output: schedule mode string (cron, interval, manual, or the explicit value).
sub _schedule_mode {
    my ( $self, $job ) = @_;
    return $job->{schedule} if $job->{schedule};
    return 'cron'           if $job->{cron};
    return 'interval'       if $job->{interval};
    return 'manual';
}

# _job_is_due($job, $name)
# Decides whether the current loop tick should execute the collector job.
# Input: collector job hash reference and collector name string.
# Output: boolean due flag.
sub _job_is_due {
    my ( $self, $job, $name ) = @_;
    my $mode = $self->_schedule_mode($job);
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
    # A missing or malformed cron expression must not become an every-second
    # schedule. A fully-wildcard "* * * * *" still reaches the per-minute
    # last_cron_slot de-duplication below.
    my ( $fields, $error ) = _parse_cron_expression($expr);
    return 0 if $error;
    my @now = localtime();
    return 0 if !$fields->[0]{ $now[1] };
    return 0 if !$fields->[1]{ $now[2] };
    return 0 if !$fields->[3]{ $now[4] + 1 };

    my $day_of_month_matches = $fields->[2]{ $now[3] } ? 1 : 0;
    my $day_of_week_matches  = $fields->[4]{ $now[6] } ? 1 : 0;
    my $dom_is_wildcard = $fields->[2]{_wildcard} ? 1 : 0;
    my $dow_is_wildcard = $fields->[4]{_wildcard} ? 1 : 0;
    my $day_matches = $dom_is_wildcard && $dow_is_wildcard
      ? 1
      : $dom_is_wildcard
        ? $day_of_week_matches
        : $dow_is_wildcard
          ? $day_of_month_matches
          : $day_of_month_matches || $day_of_week_matches;
    return 0 if !$day_matches;

    my $state = $self->loop_state($name) || {};
    my $stamp = strftime( '%Y-%m-%dT%H:%M%z', @now );
    return 0 if ( $state->{last_cron_slot} || '' ) eq $stamp;
    $self->_write_loop_state( $name, { last_cron_slot => $stamp } );
    return 1;
}

# _parse_cron_expression($expr)
# Validates a five-field crontab expression and expands each field into a set
# of matching values, including standard names, lists, ranges and step values.
# Input: cron expression string.
# Output: array reference of five match-set hashes and an empty error string,
# or undef and a visible validation message.
sub _parse_cron_expression {
    my ($expr) = @_;
    return ( undef, 'expression is missing' ) if !defined $expr || $expr !~ /\S/;
    return ( undef, 'expression is longer than 256 characters' ) if length($expr) > 256;
    $expr =~ s/\A\s+|\s+\z//g;
    my @specs = split /\s+/, $expr;
    return ( undef, 'expected exactly five fields' ) if @specs != 5;

    my @limits = ( [ 0, 59, {} ], [ 0, 23, {} ], [ 1, 31, {} ],
        [ 1, 12, { JAN => 1, FEB => 2, MAR => 3, APR => 4, MAY => 5, JUN => 6, JUL => 7, AUG => 8, SEP => 9, OCT => 10, NOV => 11, DEC => 12 } ],
        [ 0, 7, { SUN => 0, MON => 1, TUE => 2, WED => 3, THU => 4, FRI => 5, SAT => 6 } ], );
    my @fields;
    for my $index ( 0 .. 4 ) {
        my ( $set, $error ) = _parse_cron_field( $specs[$index], @{$limits[$index]} );
        return ( undef, sprintf( 'field %d (%s): %s', $index + 1, $specs[$index], $error ) ) if $error;
        $set->{_wildcard} = $specs[$index] eq '*' ? 1 : 0;
        if ( $index == 4 && delete $set->{7} ) {
            $set->{0} = 1;
        }
        push @fields, $set;
    }
    return ( \@fields, '' );
}

# _parse_cron_field($spec, $minimum, $maximum, $names)
# Parses one crontab field and returns its finite set of matching numeric values.
# Input: field string, inclusive numeric bounds, and optional name-to-number map.
# Output: hash reference and empty error string, or undef and validation message.
sub _parse_cron_field {
    my ( $spec, $minimum, $maximum, $names ) = @_;
    return ( undef, 'field is empty' ) if !defined $spec || $spec eq '';
    my %values;
    for my $item ( split /,/, $spec, -1 ) {
        return ( undef, 'empty list item' ) if $item eq '';
        my ( $base, $step ) = split m{/}, $item, -1;
        return ( undef, 'multiple step separators' ) if $item =~ m{/.*\/};
        if ( defined $step ) {
            return ( undef, 'step must be a positive integer' )
              if length($step) > 4 || $step !~ /\A\d+\z/ || $step < 1;
        }
        else {
            $step = 1;
        }

        my ( $start, $end );
        if ( $base eq '*' ) {
            ( $start, $end ) = ( $minimum, $maximum );
        }
        elsif ( $base =~ /\A([^,-]+)-([^,-]+)\z/ ) {
            ( $start, $end ) = ( _cron_value( $1, $names ), _cron_value( $2, $names ) );
            return ( undef, 'range endpoint is not a valid number or name' ) if !defined $start || !defined $end;
            return ( undef, 'range start exceeds range end' ) if $start > $end;
        }
        else {
            $start = _cron_value( $base, $names );
            return ( undef, 'value is not a valid number or name' ) if !defined $start;
            # Wildcards and ranges were handled above, so a slash remaining
            # here can only be an invalid scalar step (for example, 5/2).
            return ( undef, 'a step requires a wildcard or range' ) if $item =~ m{/};
            $end = $start;
        }

        return ( undef, 'value is outside the field limits' ) if $start < $minimum || $end > $maximum;
        for ( my $value = $start; $value <= $end; $value += $step ) {
            $values{$value} = 1;
        }
    }
    return ( \%values, '' );
}

# _cron_value($token, $names)
# Resolves a numeric token or case-insensitive crontab name.
# Input: field token and optional name-to-number hash reference.
# Output: numeric value, or undef when the token is invalid.
sub _cron_value {
    my ( $token, $names ) = @_;
    return 0 + $token if defined($token) && length($token) <= 3 && $token =~ /\A\d+\z/;
    return undef if ref($names) ne 'HASH';
    return $names->{ uc($token // '') };
}

# _cron_wday_normalize($spec)
# Aliases crontab's weekday value 7 to 0 (Sunday) in numeric lists.
# Input: weekday field string, possibly undefined.
# Output: weekday string with each bare 7 token normalized to 0.
sub _cron_wday_normalize {
    my ($spec) = @_;
    return $spec if !defined $spec;
    return join( ',', map { $_ eq '7' ? '0' : $_ } split /,/, $spec );
}

# _cron_match($spec, $value, $minimum, $maximum, $names)
# Matches one cron field by parsing its numeric, name, range or step syntax.
# Input: field string, numeric value, optional inclusive bounds, and name map.
# Output: boolean match flag.
sub _cron_match {
    my ( $spec, $value, $minimum, $maximum, $names ) = @_;
    $minimum = 0 if !defined $minimum;
    $maximum = 60 if !defined $maximum;
    return 0 if !defined($value) || length($value) > 3 || $value !~ /\A\d+\z/ || $value < $minimum || $value > $maximum;
    return 1 if !defined($spec) || $spec eq '' || $spec eq '*';
    my ( $values, $error ) = _parse_cron_field( $spec, $minimum, $maximum, $names );
    return 0 if $error;
    return $values->{$value} ? 1 : 0;
}

# DD-947: this cluster (run_command through exit_code_from_status) was
# extracted into Developer::Dashboard::CommandRunner - confirmed zero
# instance-state ($self->{...}) dependency before the move. These are
# thin one-line forwarders so every existing caller of $self->_run_command
# etc. keeps working unchanged.
sub _run_command                { my $self = shift; return Developer::Dashboard::CommandRunner::run_command(@_); }
sub _await_windows_command      { my $self = shift; return Developer::Dashboard::CommandRunner::await_windows_command(@_); }
sub _spawn_windows_command      { my $self = shift; return Developer::Dashboard::CommandRunner::spawn_windows_command(@_); }
sub _record_command_pid         { my $self = shift; return Developer::Dashboard::CommandRunner::record_command_pid(@_); }
sub _command_launcher_argv      { my $self = shift; return Developer::Dashboard::CommandRunner::command_launcher_argv(@_); }
sub _command_pid_from_file      { my $self = shift; return Developer::Dashboard::CommandRunner::command_pid_from_file(@_); }
sub _await_command_pid          { my $self = shift; return Developer::Dashboard::CommandRunner::await_command_pid(@_); }
sub _forward_command_signal     { my $self = shift; return Developer::Dashboard::CommandRunner::forward_command_signal(@_); }
sub _terminate_command_process  { my $self = shift; return Developer::Dashboard::CommandRunner::terminate_command_process(@_); }
sub _exit_code_from_status      { return Developer::Dashboard::CommandRunner::exit_code_from_status(@_); }

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
            heartbeat_at => _now_iso8601( tz => "local" ),
            stopped_at   => _now_iso8601( tz => "local" ),
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
    my ($signal) = @_;

    # Record WHICH signal stopped the loop. Perl hands the handler the signal
    # name and this threw it away, so a collector that stopped left no trace of
    # why - the state said 'stopped' and the pidfile was gone, which is
    # indistinguishable from an orderly shutdown, a watchdog, and somebody's
    # stray kill. That ambiguity cost hours on DD-532, where a supervisor was
    # being signalled during batch test runs and every investigation started
    # from "it died" rather than "it was told to stop".
    eval {
        $SIGNAL_RUNNER->{collectors}->append_log_entry(
            $SIGNAL_LOOP_NAME,
            happened_at => _now_iso8601( tz => "local" ),
            source      => 'loop stopped by signal',
            error       => 'SIG' . ( $signal // 'unknown' ) . " received by pid $$",
        );
    };

    $SIGNAL_RUNNER->_shutdown_loop( $SIGNAL_LOOP_NAME, 'stopped', $SIGNAL_LOOP_WORKERS );
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
collector indicator icon rendering from stdout JSON. Collector working
directories resolve built-in accessors and configured path aliases, followed
by skill-qualified aliases provided by installed C<lib/Folder.pm> modules.

=head1 CRON SCHEDULING

Managed loops infer cron mode from a non-empty C<cron> property or accept the
explicit C<schedule =E<gt> 'cron'> setting. The expression must contain exactly
five fields: minute, hour, day of month, month, and day of week. The parser
supports numeric values, comma-separated lists, ranges, range steps,
C<*/step>, and case-insensitive month and weekday names. Sunday may be 0 or 7.
When both date fields are restricted, either a day-of-month or day-of-week
match makes the date due. The loop evaluates machine-local time once per
second and persists the last matching minute to prevent duplicate runs.

Missing, empty, malformed, out-of-range, or overlong expressions are rejected
before a loop process is spawned. This keeps a bad configuration from turning
into an every-second job. See the user-facing dashboard documentation for the
C<config/config.json> example and accepted syntax.

=head1 METHODS

=head2 new, run_once, start_loop, stop_loop, running_loops, loop_state

Construct and manage collector execution.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module manages live collector execution. It turns stored collector jobs into processes, captures their output, updates collector state files, renders TT-backed collector indicator icons from stdout JSON when configured, tracks pid ownership, and exposes the start/stop/restart/run/status lifecycle used by the CLI and web-facing status features.

=head1 WHY IT EXISTS

It exists because collector process control is more than a single C<system()> call. The dashboard needs a single owner for pid validation, output capture, environment preparation, enabled/disabled state, and restart behavior so the prompt and browser status strip can trust the result.

=head1 WHEN TO USE

Use this file when changing collector process spawning, pid validation, restart semantics, background job cleanup, TT-backed indicator icon rendering, the contract between collector execution and persisted collector state, or how the collector's C<cwd> value resolves from path aliases.

=head1 HOW TO USE

Construct it with the path registry and collector store, then call the lifecycle methods for one collector name. Keep process-management behavior and TT-backed collector icon rendering here; the CLI wrappers should only parse arguments and print the returned state.

For C<run_once>, a relative C<cwd> first checks built-in directory accessors,
then configured aliases from merged dashboard config, then a qualified skill
C<Folder.pm> method (for example C<collectorpaths.workspace>). If no alias
applies, an existing relative directory remains valid. Config aliases win over
skill methods with the same name; skill aliases are read-only.

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
