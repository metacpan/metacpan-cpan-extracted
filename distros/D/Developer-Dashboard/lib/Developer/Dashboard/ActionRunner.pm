package Developer::Dashboard::ActionRunner;

use strict;
use warnings;

our $VERSION = '6.31';

use Capture::Tiny qw(capture);
use Developer::Dashboard::PathIdentity qw(current_working_directory);
use Digest::SHA qw(sha256_hex);
use File::Spec;

use Developer::Dashboard::Codec qw(encode_payload decode_payload);
use Developer::Dashboard::JSON qw(json_encode);
use Developer::Dashboard::Platform qw(is_windows shell_command_argv);
use Developer::Dashboard::TimeUtils qw(_now_iso8601);

# new(%args)
# Constructs an action runner bound to file and path registries.
# Input: files and paths objects.
# Output: Developer::Dashboard::ActionRunner object.
sub new {
    my ( $class, %args ) = @_;
    my $files = $args{files} || die 'Missing file registry';
    my $paths = $args{paths} || die 'Missing path registry';
    return bless {
        files => $files,
        paths => $paths,
    }, $class;
}

# run_page_action(%args)
# Executes a page action after applying trust checks and action kind routing.
# Input: page document, action hash, source string, and optional params hash.
# Output: result hash reference or dies on unsupported/untrusted actions.
sub run_page_action {
    my ( $self, %args ) = @_;
    my $page   = $args{page}   || die 'Missing page';
    my $action = $args{action} || die 'Missing action';
    my $source = $args{source} || 'saved';
    die 'Page action must be a hash' if ref($action) ne 'HASH';

    my $kind = $action->{kind} || 'builtin';
    if ( $kind eq 'builtin' ) {
        return $self->_run_builtin_action(
            action => $action,
            page   => $page,
            params => $args{params} || {},
        );
    }

    if ( $kind eq 'command' ) {
        die "Action '$action->{id}' is not trusted for source '$source'\n"
          if !$self->_is_action_trusted( page => $page, action => $action, source => $source );
        return $self->run_command_action(
            command    => $action->{command},
            cwd        => $action->{cwd},
            env        => $action->{env},
            timeout_ms => $action->{timeout_ms},
            background => $action->{background},
        );
    }

    die "Unsupported action kind '$kind'\n";
}

# encode_action_payload(%args)
# Encodes a self-contained action transport payload for a page action.
# Input: page document, action hash, and source string.
# Output: encoded action token string.
sub encode_action_payload {
    my ( $self, %args ) = @_;
    my $page   = $args{page}   || die 'Missing page';
    my $action = $args{action} || die 'Missing action';
    my $payload = {
        version      => 1,
        source       => $args{source} || 'saved',
        page_source  => $page->can('canonical_instruction') ? $page->canonical_instruction : '',
        action       => $action,
        trusted_id   => sha256_hex(
            join ':',
            $args{source} || 'saved',
            ( $page->as_hash->{id} || '' ),
            ( $action->{id} || '' ),
            ( $page->can('canonical_instruction') ? $page->canonical_instruction : '' ),
        ),
    };
    return encode_payload( json_encode($payload) );
}

# decode_action_payload($token)
# Decodes an encoded action transport token.
# Input: encoded action token string.
# Output: decoded action payload hash reference.
sub decode_action_payload {
    my ( $self, $token ) = @_;
    my $payload = Developer::Dashboard::JSON::json_decode( decode_payload($token) );
    die 'Action payload must be a hash' if ref($payload) ne 'HASH';
    return $payload;
}

# run_encoded_action(%args)
# Decodes and executes an encoded action transport payload at the untrusted
# transient trust level, refusing command actions that arrive over the
# forgeable token transport.
# Input: encoded action token and optional params hash.
# Output: builtin action result hash reference (dies for command actions).
sub run_encoded_action {
    my ( $self, %args ) = @_;
    my $payload = $self->decode_action_payload( $args{token} || '' );
    my $page_class = 'Developer::Dashboard::PageDocument';
    my $page = $page_class->from_instruction( $payload->{page_source} || '' );

    # SECURITY: the encoded action token is a client-supplied, unauthenticated
    # transport (gzip + base64), and its 'trusted_id' is an unkeyed digest an
    # attacker can recompute, so no field carried in the payload can prove a
    # genuine trusted origin: neither the claimed 'source', nor the per-action
    # 'safe' flag, nor 'trusted_id'. A command action even carries its own
    # executable string inside that same forgeable payload, so a decoded command
    # action is always fully attacker-controlled and must never run through this
    # path. Command actions are only trusted through the authenticated saved-page
    # route, where the server itself loaded the page source. Built-in actions map
    # to a fixed server-side allowlist and stay safe, but are still evaluated at
    # the untrusted transient trust level rather than any origin the payload claims.
    my $action = $payload->{action};
    die "Command actions cannot be executed through an encoded action token\n"
      if ref($action) eq 'HASH' && ( $action->{kind} || 'builtin' ) eq 'command';

    return $self->run_page_action(
        action => $action,
        page   => $page,
        source => 'transient',
        params => $args{params} || {},
    );
}

# DD-881: the cwd-alias fallback below must dispatch ONLY to these no-arg
# PathRegistry directory getters - never to any other public method
# (register_named_paths/unregister_named_path mutate state, resolve_dir
# and others take required arguments), or a config-supplied cwd that
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

# run_command_action(%args)
# Executes a local command action synchronously or in the background.
# Input: command, cwd, env, timeout_ms, and background options.
# Output: structured result hash reference.
sub run_command_action {
    my ( $self, %args ) = @_;
    my $cmd = $args{command} || die 'Missing command';
    my $cwd = $args{cwd};
    $cwd = current_working_directory() if !$cwd;
    if ( !File::Spec->file_name_is_absolute($cwd) && $RESOLVABLE_ACCESSOR{$cwd} ) {
        $cwd = $self->{paths}->$cwd();
    }
    die "Action cwd '$cwd' does not exist" if !-d $cwd;

    my $env = ref( $args{env} ) eq 'HASH' ? { %{ $args{env} } } : {};
    my $timeout_ms = $args{timeout_ms} || 30_000;
    my $background = $args{background} ? 1 : 0;

    if ($background) {
        return $self->_spawn_background_action(
            command    => $cmd,
            cwd        => $cwd,
            env        => $env,
            timeout_ms => $timeout_ms,
        );
    }

    return $self->_run_command(
        cmd        => $cmd,
        cwd        => $cwd,
        env        => $env,
        timeout_ms => $timeout_ms,
    );
}

# _spawn_background_action(%args)
# Launches a detached native supervisor for a background command action.
# Input: command string, validated cwd, environment hash, and timeout in milliseconds.
# Output: the public background result hash with the native supervisor pid.
sub _spawn_background_action {
    my ( $self, %args ) = @_;
    require Developer::Dashboard::GoRoutine;
    my $log = $self->{files}->dashboard_log;
    my $payload = json_encode(
        {
            command    => $args{command},
            cwd        => $args{cwd},
            timeout_ms => $args{timeout_ms},
            log        => $log,
        }
    );
    my @argv = (
        $^X,
        '-MDeveloper::Dashboard::ActionRunner',
        '-e',
        'exit Developer::Dashboard::ActionRunner->run_background_supervisor($ARGV[0]);',
        $payload,
    );
    my $pid = eval {
        Developer::Dashboard::GoRoutine::spawn(
            \@argv,
            {
                cwd           => $args{cwd},
                env           => $args{env},
                process_group => 1,
                stdin         => File::Spec->devnull(),
                stdout        => $log,
                stderr        => $log,
            },
        );
    };
    my $spawn_error = $@;
    die "Unable to launch background action supervisor: $spawn_error"
      if $spawn_error ne '' || !$pid;
    return {
        background => 1,
        pid        => $pid + 0,
        started_at => _now_iso8601( tz => 'utc' ),
    };
}

# _terminate_background_child($pid)
# Ends one supervisor command child, including every descendant it spawned.
# On Windows the command runs through PowerShell, so the real command is a
# grandchild: terminating only the direct child orphans it, and the orphan
# inherits the harness stdio pipe handles (CreateProcess bInheritHandles),
# so prove never sees EOF and the run stalls after the test prints its plan
# (round 58: t/121 printed 1..13, then the Windows leg sat silent until the
# 180s watchdog killed it). CommandRunner::terminate_command_process
# kills the whole tree (taskkill /T) - the discipline CollectorRunner already
# follows - so the supervisor uses it on Windows. POSIX commands exec the
# script directly, so there is no grandchild and the single-pid TERM, grace
# wait, then KILL sequence stands.
# Input: direct command child pid integer.
# Output: true value.
sub _terminate_background_child {
    my ($pid) = @_;
    if ( is_windows() ) {
        require Developer::Dashboard::CommandRunner;
        Developer::Dashboard::CommandRunner::terminate_command_process($pid);
        return 1;
    }
    Developer::Dashboard::GoRoutine::terminate_process( $pid, 'TERM' );
    _wait_background_child_exit($pid, 0.2);
    Developer::Dashboard::GoRoutine::terminate_process( $pid, 'KILL' )
      if !Developer::Dashboard::GoRoutine::process_exited($pid);
    return 1;
}

# run_background_supervisor($payload_json)
# Runs the detached command child, enforcing its timeout and forwarding stop signals.
# Input: JSON scalar containing the trusted command, cwd, timeout, and log path; environment is inherited.
# Output: child exit status, 124 on timeout, or 128+signal after a stop request.
sub run_background_supervisor {
    my ( $class, $payload_json ) = @_;
    my $payload = Developer::Dashboard::JSON::json_decode($payload_json);
    die 'Background action supervisor payload must be a hash' if ref($payload) ne 'HASH';
    for my $required (qw(command cwd timeout_ms log)) {
        die "Background action supervisor is missing $required"
          if !exists $payload->{$required};
    }
    require Developer::Dashboard::GoRoutine;
    my @argv = shell_command_argv( $payload->{command} );
    # Install the stop handlers BEFORE spawning the child, so a stop signal
    # arriving while the supervisor is starting is handled instead of lost.
    # Previously the child was spawned first and the handlers installed
    # after, so a signal sent immediately after launch (as t/11 does) could
    # arrive before the handler existed and be discarded, leaving the
    # supervisor to run until its child finished or its timeout expired.
    my $stop_signal;
    local $SIG{TERM} = sub { $stop_signal = 'TERM' };
    local $SIG{INT}  = sub { $stop_signal = 'INT' };
    my $child_pid = Developer::Dashboard::GoRoutine::spawn(
        \@argv,
        {
            cwd    => $payload->{cwd},
            stdout => $payload->{log},
            stderr => $payload->{log},
        },
    );
    my $timeout_ms = $payload->{timeout_ms};
    my $deadline = $timeout_ms > 0 ? time() + ( $timeout_ms / 1000 ) : undef;
    while (1) {
        if ($stop_signal) {
            _terminate_background_child($child_pid);
            Developer::Dashboard::GoRoutine::wait_process($child_pid);
            return 0;
        }
        if (Developer::Dashboard::GoRoutine::process_exited($child_pid)) {
            return Developer::Dashboard::GoRoutine::wait_process($child_pid);
        }
        if ( defined $deadline && time() >= $deadline ) {
            _terminate_background_child($child_pid);
            Developer::Dashboard::GoRoutine::wait_process($child_pid);
            return 124;
        }
        select undef, undef, undef, 0.02;
    }
}

# _wait_background_child_exit($pid, $seconds)
# Polls the native process API until the command exits or a bounded grace period expires.
# Input: child process id and maximum wait duration in seconds.
# Output: true if the child exited during the grace period, otherwise false.
sub _wait_background_child_exit {
    my ( $pid, $seconds ) = @_;
    my $deadline = time() + $seconds;
    while ( time() < $deadline ) {
        return 1 if Developer::Dashboard::GoRoutine::process_exited($pid);
        select undef, undef, undef, 0.01;
    }
    return Developer::Dashboard::GoRoutine::process_exited($pid) ? 1 : 0;
}

# _wait_status_exit_code($raw_status)
# Normalizes one raw waitpid status word into the shell-style exit code that
# the detached background supervisor should use when its command child exits.
# Input: raw wait status integer from $? or waitpid.
# Output: normalized exit status integer.
sub _wait_status_exit_code {
    my ( $self, $raw_status ) = @_;
    my $status = $raw_status >> 8;
    $status = 128 + ( $raw_status & 127 ) if !$status && ( $raw_status & 127 );
    return $status;
}

# _reap_child_process($pid)
# Observes and collects the exit result for one native background process.
# Input: process id integer.
# Output: boolean true when the process has exited.
sub _reap_child_process {
    my ( $self, $pid ) = @_;
    return 0 if !defined $pid || $pid !~ /^\d+$/ || $pid < 1;
    require Developer::Dashboard::GoRoutine;
    return 0 if !Developer::Dashboard::GoRoutine::process_running($pid);
    return 0 if !Developer::Dashboard::GoRoutine::process_exited($pid);
    Developer::Dashboard::GoRoutine::wait_process($pid);
    return 1;
}

# The default is the real Linux procfs. Tests can point this at a temporary
# fixture so its parser also runs under macOS coverage.
our $PROCFS_ROOT = '/proc';

# _read_process_state($pid)
# Reads the current process state so zombie background action wrappers can be
# treated as stopped even when signal 0 still succeeds.
# Input: process id integer.
# Output: one-letter process state string or undef.
sub _read_process_state {
    my ( $self, $pid ) = @_;
    # A QUERY MUST NOT DECIDE ITS CALLER'S EXIT STATUS (DD-591, same shape as
    # DD-585/DD-589/DD-590). The ps fallback below runs whenever /proc is
    # unreadable for this pid; without this guard its raw $? stays set in the
    # caller's process after this sub returns.
    local $?;
    my $proc = "$PROCFS_ROOT/$pid/stat";
    if ( -r $proc ) {
        open my $fh, '<', $proc or return;
        local $/;
        my $stat = scalar <$fh>;
        return $1 if $stat =~ /^\d+\s+\(.*\)\s+(\S)/s;
    }

    if ( is_windows() ) {
        # ps does not exist on Windows, so a state that procfs did not
        # supply is simply unavailable. Callers already treat undef as
        # unknown; spawning cmd.exe for a ps that can never exist would
        # only waste a process and surface its "not recognized" text
        # through the capture.
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

# _pid_is_running($pid)
# Determines whether one background action pid is still alive after
# opportunistic reaping and zombie-state checks.
# Input: process id integer.
# Output: boolean true when the process still appears to be running.
sub _pid_is_running {
    my ( $self, $pid ) = @_;
    return 0 if !defined $pid || $pid !~ /^\d+$/ || $pid < 1;
    return 0 if $self->_reap_child_process($pid);
    require Developer::Dashboard::GoRoutine;
    return Developer::Dashboard::GoRoutine::process_running($pid) ? 1 : 0;
}

# _run_builtin_action(%args)
# Executes one of the built-in safe dashboard actions.
# Input: action hash, page document, and optional params hash.
# Output: structured result hash reference.
sub _run_builtin_action {
    my ( $self, %args ) = @_;
    my $action = $args{action};
    my $page   = $args{page};
    my $id     = $action->{builtin} || $action->{id} || '';

    if ( $id eq 'page.source' ) {
        return {
            kind         => 'builtin',
            content_type => 'text/plain; charset=utf-8',
            body         => $page->canonical_instruction,
        };
    }

    if ( $id eq 'page.state' ) {
        return {
            kind         => 'builtin',
            content_type => 'application/json; charset=utf-8',
            body         => json_encode( $page->as_hash->{state} || {} ),
        };
    }

    if ( $id eq 'paths.list' ) {
        return {
            kind         => 'builtin',
            content_type => 'application/json; charset=utf-8',
            body         => json_encode(
                {
                    home       => $self->{paths}->home,
                    runtime    => $self->{paths}->runtime_root,
                    dashboards => $self->{paths}->dashboards_root,
                    config     => $self->{paths}->config_root,
                    cli        => $self->{paths}->cli_root,
                }
            ),
        };
    }

    die "Unsupported builtin action '$id'\n";
}

# _is_action_trusted(%args)
# Determines whether a page action may execute for the given source.
# Input: page document, action hash, and source string.
# Output: boolean trust flag.
sub _is_action_trusted {
    my ( $self, %args ) = @_;
    my $page   = $args{page};
    my $action = $args{action};
    my $source = $args{source} || '';
    return 1 if $action->{safe};
    return 1 if $source eq 'saved' || $source eq 'provider';

    my $permissions = $page->as_hash->{permissions} || {};
    return 0 if !$permissions->{allow_untrusted_actions};
    if ( ref( $permissions->{trusted_actions} ) eq 'ARRAY' ) {
        my %allowed = map { $_ => 1 } @{ $permissions->{trusted_actions} };
        return $allowed{ $action->{id} } ? 1 : 0;
    }
    return 0;
}

# _run_command(%args)
# Runs a shell command with cwd/env/timeout handling and captured output.
# Input: command string, cwd path, env hash, timeout_ms.
# Output: structured result hash reference.
sub _run_command {
    my ( $self, %args ) = @_;

    # DD-597: system() below mutates the caller's global $? as a side effect;
    # without this guard that stays set in the caller's process after this
    # sub returns, regardless of the exit code already captured in this sub's
    # own return value.
    local $?;
    my $cmd        = $args{cmd};
    my $cwd        = $args{cwd};
    my $env        = $args{env} || {};
    my $timeout_ms = $args{timeout_ms} || 30_000;

    my $old = current_working_directory();
    chdir $cwd or die "Unable to chdir to $cwd: $!";
    local @ENV{ keys %$env } = values %$env if %$env;

    my $timed_out = 0;
    my ( $stdout, $stderr, $exit_code ) = capture {
        local $SIG{ALRM} = sub { die "__ACTION_TIMEOUT__\n" };
        alarm( int( ( $timeout_ms + 999 ) / 1000 ) );
        my $ok = eval {
            system shell_command_argv($cmd);
            return $self->_wait_status_exit_code($?);
        };
        if ($@) {
            die $@ if $@ !~ /__ACTION_TIMEOUT__/;
            $timed_out = 1;
            return 124;
        }
        alarm(0);
        return $ok;
    };
    alarm(0);
    chdir $old or die "Unable to restore cwd to $old: $!";

    return {
        background  => 0,
        command     => $cmd,
        cwd         => $cwd,
        env         => $env,
        exit_code   => $exit_code,
        stdout      => $stdout,
        stderr      => $stderr,
        timed_out   => $timed_out ? 1 : 0,
        content_type => 'application/json; charset=utf-8',
        started_at  => _now_iso8601( tz => "utc" ),
    };
}

1;

__END__

=head1 NAME

Developer::Dashboard::ActionRunner - trusted action execution runtime

=head1 SYNOPSIS

  my $runner = Developer::Dashboard::ActionRunner->new(files => $files, paths => $paths);
  my $result = $runner->run_page_action(...);

=head1 DESCRIPTION

This module executes built-in and trusted command actions for dashboard pages,
including encoded action transport payloads.

=head1 METHODS

=head2 new, run_page_action, encode_action_payload, decode_action_payload, run_encoded_action, run_command_action

Construct and execute actions.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module validates and executes page actions. It decides whether a page action is a built-in d2 action or an explicit command action, enforces the saved-page trust rules, captures command output, and returns structured result hashes for the page runtime and web routes.

=head1 WHY IT EXISTS

It exists because bookmark actions need one place that owns trust checks and command execution semantics. Without that boundary, the web layer, page renderer, and saved-action transport would each grow their own action policy and drift apart.

=head1 WHEN TO USE

Use this file when changing page action security, the transport payload for encoded actions, command backgrounding rules, or the way page actions report stdout, stderr, and exit codes back to callers.

=head1 HOW TO USE

Construct it with a file registry and path registry, then call C<run_page_action> for one decoded action hash or C<encode_action_payload> when a route needs a portable transport token. Keep action execution policy here instead of duplicating it in controllers or bookmark templates.

=head1 WHAT USES IT

It is used by C<Developer::Dashboard::Web::App>, by provider pages resolved through the page resolver, by saved page action buttons in the browser, and by action/web regression tests.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::ActionRunner -e 1

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
