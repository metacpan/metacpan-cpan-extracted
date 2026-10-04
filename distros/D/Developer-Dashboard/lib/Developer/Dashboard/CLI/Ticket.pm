package Developer::Dashboard::CLI::Ticket;

use strict;
use warnings;

our $VERSION = '5.51';

use Capture::Tiny qw(capture);
use Cwd qw(cwd);
use Exporter 'import';
use File::Basename qw(dirname);
use File::Spec ();
use Developer::Dashboard::EnvAudit;
use Developer::Dashboard::EnvLoader;
use Developer::Dashboard::Platform qw(command_in_path shell_quote_for);

our @EXPORT_OK = qw(
  apply_ticket_status
  apply_workspace_environment
  apply_workspace_status
  build_ticket_plan
  build_workspace_plan
  list_sessions
  registered_workspace_dir
  resolve_attach_runner
  resolve_ticket_request
  resolve_workspace_request
  run_ticket_command
  run_workspace_command
  session_exists
  split_workspace_change_dir_args
  ticket_environment
  workspace_environment
  tmux_command
);

# split_workspace_change_dir_args($argv)
# Separates the workspace -c change-directory flag from the remaining argv so
# the flag can appear before or after the workspace name.
# Input: array reference of workspace command arguments.
# Output: list of cleaned argv array reference and boolean change-directory flag.
sub split_workspace_change_dir_args {
    my ($argv) = @_;
    die 'Workspace args must be an array reference' if ref($argv) ne 'ARRAY';
    my $change_dir = 0;
    my @clean;
    for my $arg ( @{$argv} ) {
        if ( defined $arg && $arg eq '-c' ) {
            $change_dir = 1;
            next;
        }
        push @clean, $arg;
    }
    return ( \@clean, $change_dir );
}

# registered_workspace_dir($name)
# Resolves configured path aliases and skill Folder.pm methods like shell cdr.
# Input: workspace name string.
# Output: registered directory path string, or empty string when the name is
# not registered.
sub registered_workspace_dir {
    my ($name) = @_;
    require Developer::Dashboard::PathRegistry;
    require Developer::Dashboard::FileRegistry;
    require Developer::Dashboard::Config;
    my $home = $ENV{HOME} || '';
    my @roots = grep { -d } map { "$home/$_" } qw(projects src work);
    my $paths = Developer::Dashboard::PathRegistry->new(
        home            => $home,
        cwd             => cwd(),
        workspace_roots => \@roots,
        project_roots   => \@roots,
    );
    my $files  = Developer::Dashboard::FileRegistry->new( paths => $paths );
    my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    $paths->register_named_paths( $config->path_aliases );
    # An unregistered name is the expected signal to try Folder.pm; all other
    # PathRegistry failures must remain visible to the caller.
    my $target = eval { $paths->resolve_dir($name) };
    my $resolve_error = $@;
    die $resolve_error if $resolve_error ne '' && $resolve_error !~ /\AUnknown directory name /;
    return $target if defined $target;

    # Config aliases have first refusal. Resolve a skill Folder.pm method only
    # after the normal registry lookup has no result.
    require Developer::Dashboard::CLI::Paths;
    $target = Developer::Dashboard::CLI::Paths::_skill_folder_alias_target(
        paths => $paths,
        name  => $name,
    );
    return defined $target ? $target : '';
}

# resolve_workspace_request(%args)
# Resolves the target workspace reference from argv or the current environment.
# Input: args array reference and optional env_ticket/env_workspace scalar.
# Output: non-empty workspace/session name string or dies when none is available.
sub resolve_workspace_request {
    my (%args) = @_;
    my $argv = $args{args} || [];
    die 'Workspace args must be an array reference' if ref($argv) ne 'ARRAY';

    my $workspace = $argv->[0];
    $workspace = $args{env_workspace} if !defined $workspace || $workspace eq '';
    $workspace = $args{env_ticket} if ( !defined $workspace || $workspace eq '' ) && defined $args{env_ticket};
    $workspace = $ENV{WORKSPACE_REF} if !defined $workspace || $workspace eq '';
    $workspace = $ENV{TICKET_REF} if ( !defined $workspace || $workspace eq '' ) && defined $ENV{TICKET_REF};
    die "Please specify a workspace name\n" if !defined $workspace || $workspace eq '';
    return $workspace;
}

# resolve_ticket_request(%args)
# Compatibility wrapper for the older ticket terminology.
# Input: same as resolve_workspace_request.
# Output: workspace/session name string.
sub resolve_ticket_request {
    my (%args) = @_;
    my $argv = $args{args} || [];
    die 'Ticket args must be an array reference' if ref($argv) ne 'ARRAY';

    my $ticket = $argv->[0];
    $ticket = $args{env_ticket} if !defined $ticket || $ticket eq '';
    die "Please specify a ticket name\n" if !defined $ticket || $ticket eq '';
    return $ticket;
}

# workspace_environment($workspace)
# Builds the tmux environment values that travel with one workspace session.
# Input: non-empty workspace/session name string.
# Output: hash reference of tmux environment variable names and values.
sub workspace_environment {
    my ( $workspace, %args ) = @_;
    die "Workspace name is required\n" if !defined $workspace || $workspace eq '';
    my %env = (
        WORKSPACE_REF                   => $workspace,
        TICKET_REF                      => $workspace,
        B                               => $workspace,
        OB                              => "origin/$workspace",
        DEVELOPER_DASHBOARD_TMUX_STATUS => 1,
    );
    my $cwd = $args{cwd};
    $cwd = cwd() if !defined $cwd || $cwd eq '';
    my $layered = _workspace_layered_env( cwd => $cwd );
    @env{ keys %{$layered} } = values %{$layered} if %{$layered};
    $env{DEVELOPER_DASHBOARD_WORKSPACE_ENV_KEYS} = join ':', sort keys %{$layered};
    return {
        %env,
    };
}

# ticket_environment($ticket)
# Compatibility wrapper for the older ticket terminology.
# Input: non-empty ticket/session name string.
# Output: hash reference of tmux environment values.
sub ticket_environment {
    my ( $ticket, %args ) = @_;
    die "Ticket name is required\n" if !defined $ticket || $ticket eq '';
    my $env = workspace_environment( $ticket, %args );
    delete $env->{WORKSPACE_REF};
    delete $env->{DEVELOPER_DASHBOARD_WORKSPACE_ENV_KEYS};
    return $env;
}

# tmux_command(%args)
# Runs one tmux command and captures stdout, stderr, and exit status.
# Input: args array reference for tmux.
# Output: hash reference with stdout, stderr, and exit_code keys.
sub tmux_command {
    my (%args) = @_;

    # DD-597: system() below mutates the caller's global $? as a side
    # effect; without this guard that stays set in the caller's process
    # after this sub returns, regardless of the exit code already captured
    # in this sub's own return value.
    local $?;
    my $argv = $args{args} || [];
    die 'tmux args must be an array reference' if ref($argv) ne 'ARRAY';

    my ( $stdout, $stderr, $exit_code ) = capture {
        system 'tmux', @{$argv};
        return $? >> 8;
    };

    return {
        stdout    => $stdout,
        stderr    => $stderr,
        exit_code => $exit_code,
    };
}

# exec_workspace_attach(%args)
# Hands this process over to tmux for the attach, replacing the process image so
# no perl parent is left waiting behind an interactive session.
# Input: args array reference for tmux.
# Output: never returns on success; dies when the handoff itself fails.
sub exec_workspace_attach {
    my (%args) = @_;

    # No default. An argv of [] would exec a bare tmux, which is not an attach at
    # all, and the fallback was a branch that could only be exercised by letting
    # this replace the test process. Requiring the caller to say what it wants is
    # both safer and testable.
    my $argv = $args{args};

    die 'tmux args must be an array reference' if ref($argv) ne 'ARRAY';

    # The raw exec lives in _exec_tmux because Devel::Cover cannot attribute a
    # statement that follows a failed exec in the same sub; tests replace
    # _exec_tmux to reach the die below in-process.
    _exec_tmux( @{$argv} );
    die "Unable to exec tmux to attach the workspace session: $!\n";
}

# _exec_tmux(@args)
# Performs the bare exec of tmux; returns only when the exec fails.
# Input: tmux argument list.
# Output: false when exec fails, never returns on success.
sub _exec_tmux {
    my (@args) = @_;
    return exec 'tmux', @args;
}

# resolve_attach_runner(%args)
# Chooses what performs the attach: an explicitly supplied runner, otherwise an
# injected tmux runner, otherwise the real exec handoff.
# Input: optional attach and tmux coderefs.
# Output: coderef that performs the attach.
#
# The tmux fallback is deliberate rather than incidental. A caller that injects a
# tmux runner is observing this command instead of running it, and an observer
# that got a real exec would have its process replaced mid-test. Routing the
# attach to the same injected runner makes that impossible by construction, which
# is worth more than the symmetry of always execing.
sub resolve_attach_runner {
    my (%args) = @_;
    return $args{attach} || $args{tmux} || \&exec_workspace_attach;
}

# _tmux_stdout(%args)
# Runs one tmux command and returns trimmed stdout when the command succeeds.
# Input: tmux runner coderef plus argv array reference.
# Output: stdout string, or undef when tmux exits non-zero.
sub _tmux_stdout {
    my (%args) = @_;
    my $tmux = $args{tmux} || \&tmux_command;
    my $argv = $args{args} || [];
    my $result = $tmux->( args => $argv );
    return if ( $result->{exit_code} || 0 ) != 0;
    my $stdout = $result->{stdout};
    return if !defined $stdout;
    $stdout =~ s/\r?\n\z//;
    return $stdout;
}

# _dashboard_command_path()
# Resolves the explicit dashboard entrypoint path used in tmux status commands.
# Input: none.
# Output: absolute/relative dashboard command path string, or "dashboard" as a final fallback.
sub _dashboard_command_path {
    return $ENV{DEVELOPER_DASHBOARD_ENTRYPOINT}
      if defined $ENV{DEVELOPER_DASHBOARD_ENTRYPOINT}
      && $ENV{DEVELOPER_DASHBOARD_ENTRYPOINT} ne '';
    my $path = command_in_path('dashboard');
    return $path if defined $path;
    return 'dashboard';
}

# _workspace_env_files(%args)
# Returns the ordered plain .env files that should seed one tmux workspace
# session, from the highest ancestor down to the current directory.
# Input: cwd path string.
# Output: ordered list of .env file paths.
sub _workspace_env_files {
    my (%args) = @_;
    my $cwd = $args{cwd};
    $cwd = cwd() if !defined $cwd || $cwd eq '';
    my $dir = Developer::Dashboard::EnvLoader->_path_identity($cwd);
    return () if $dir eq '';
    my @files;
    while (1) {
        my $file = File::Spec->catfile( $dir, '.env' );
        push @files, $file if -f $file;
        last if $dir eq File::Spec->rootdir();
        my $parent = dirname($dir);
        last if $parent eq $dir;
        $dir = $parent;
    }
    return reverse @files;
}

# _workspace_layered_env(%args)
# Loads the ordered plain .env chain for one tmux workspace into a temporary
# environment so the session can be seeded or refreshed without mutating the
# current process environment permanently.
# Input: cwd path string.
# Output: hash reference of environment keys and values loaded from the .env chain.
sub _workspace_layered_env {
    my (%args) = @_;
    my @files = _workspace_env_files(%args);
    return {} if !@files;

    my %base_env = %ENV;
    local %ENV = %base_env;
    Developer::Dashboard::EnvAudit->clear;
    Developer::Dashboard::EnvLoader->load_files( files => \@files );
    my $audit = Developer::Dashboard::EnvAudit->keys;
    my %loaded;
    for my $key ( sort keys %{$audit} ) {
        $loaded{$key} = $ENV{$key};
    }
    Developer::Dashboard::EnvAudit->clear;
    return \%loaded;
}

# apply_workspace_environment(%args)
# Refreshes the tmux session environment for one workspace so resumed sessions
# pick up the current layered .env values and dropped keys are unset.
# Input: session name, workspace env hash reference, and optional tmux runner.
# Output: true on success or dies on tmux errors.
sub apply_workspace_environment {
    my (%args) = @_;
    my $session = $args{session} || die 'Missing session name';
    my $tmux = $args{tmux} || \&tmux_command;
    my $env  = $args{env}  || {};
    die 'Workspace env must be a hash reference' if ref($env) ne 'HASH';

    my $existing_keys = _tmux_stdout(
        tmux => $tmux,
        args => [ 'show-environment', '-t', $session, 'DEVELOPER_DASHBOARD_WORKSPACE_ENV_KEYS' ],
    );
    my %new = %{$env};
    my %new_keys = map { $_ => 1 } grep { $_ ne '' } split /:/, ( $new{DEVELOPER_DASHBOARD_WORKSPACE_ENV_KEYS} || '' );
    my %existing = map { $_ => 1 } grep { $_ ne '' } split /:/, ( defined $existing_keys ? ( $existing_keys =~ s/^DEVELOPER_DASHBOARD_WORKSPACE_ENV_KEYS=//r ) : '' );

    for my $key ( sort keys %existing ) {
        next if $new_keys{$key};
        my $unset = $tmux->( args => [ 'set-environment', '-t', $session, '-u', $key ] );
        die sprintf "Unable to refresh tmux workspace environment for '%s': %s%s",
          $session,
          ( $unset->{stderr} || '' ),
          ( $unset->{stdout} || '' )
          if $unset->{exit_code} != 0;
    }

    for my $key ( sort keys %new ) {
        my $set = $tmux->( args => [ 'set-environment', '-t', $session, $key, $new{$key} ] );
        die sprintf "Unable to refresh tmux workspace environment for '%s': %s%s",
          $session,
          ( $set->{stderr} || '' ),
          ( $set->{stdout} || '' )
          if $set->{exit_code} != 0;
    }

    return 1;
}

# apply_ticket_status(%args)
# Configures one tmux ticket session to render dashboard indicators on the top tmux status row.
# Input: session name plus optional tmux runner coderef and optional dashboard command path override.
# Output: true on success, or dies when tmux refuses the session status update.
sub apply_workspace_status {
    return apply_ticket_status(@_);
}

# _tmux_status_interval_seconds()
# Returns the tmux status refresh cadence used by dashboard-managed ticket and
# workspace sessions.
# Input: none.
# Output: positive integer number of seconds.
sub _tmux_status_interval_seconds {
    return 15;
}

# apply_ticket_status(%args)
# Configures a tmux session's status bar to show the dashboard's ticket
# indicator on top while preserving whatever status line the session already
# had, restoring it below the indicator.
# Input: session name, and optional tmux/dashboard command overrides for tests.
# Output: 1 on success, dies on a tmux configuration error.
sub apply_ticket_status {
    my (%args) = @_;
    my $session = $args{session} || die 'Missing session name';
    my $tmux = $args{tmux} || \&tmux_command;
    my $dashboard = $args{dashboard};
    $dashboard = _dashboard_command_path() if !$dashboard;

    my $default_status = _tmux_stdout(
        tmux => $tmux,
        args => [ 'show-options', '-gqv', '@dd_ticket_status_default' ],
    );
    if ( !defined $default_status || $default_status eq '' ) {
        $default_status = _tmux_stdout(
            tmux => $tmux,
            args => [ 'show-options', '-gqv', 'status-format[0]' ],
        );
        if ( defined $default_status && $default_status ne '' ) {
            my $saved = $tmux->(
                args => [ 'set-option', '-gq', '@dd_ticket_status_default', $default_status ],
            );
            die sprintf "Unable to record tmux ticket default status for '%s': %s%s",
              $session,
              ( $saved->{stderr} || '' ),
              ( $saved->{stdout} || '' )
              if $saved->{exit_code} != 0;
        }
    }

    my $indicator_status = sprintf '#(%s ps1 --mode tmux-status-top --width #{client_width})',
      shell_quote_for( 'sh', $dashboard );
    my @commands = (
        [ 'set-option', '-gq', 'status-position', 'bottom' ],
        [ 'set-option', '-gq', 'status',          '2' ],
        [ 'set-option', '-gq', 'status-interval', _tmux_status_interval_seconds() ],
        [ 'set-option', '-gq', 'status-format[0]', $indicator_status ],
        ( defined $default_status && $default_status ne ''
            ? ( [ 'set-option', '-gq', 'status-format[1]', $default_status ] )
            : () ),
        [ 'set-option', '-guq', 'status-format[2]' ],
    );

    for my $argv (@commands) {
        my $result = $tmux->( args => $argv );
        die sprintf "Unable to configure tmux ticket status for '%s': %s%s",
          $session,
          ( $result->{stderr} || '' ),
          ( $result->{stdout} || '' )
          if $result->{exit_code} != 0;
    }

    return 1;
}

# session_exists(%args)
# Checks whether the requested tmux session already exists.
# Input: session name and optional tmux runner coderef.
# Output: 1 when the normalized tmux session exists, 0 when it does not, or dies on tmux errors.
sub session_exists {
    my (%args) = @_;
    my $session = $args{session} || die 'Missing session name';
    my $tmux = $args{tmux} || \&tmux_command;
    my $result = $tmux->(
        args => [ 'has-session', '-t', _tmux_session_name($session) ],
    );

    return 1 if $result->{exit_code} == 0;
    return 0 if $result->{exit_code} == 1;
    die sprintf "Unable to inspect tmux session '%s': %s%s",
      $session,
      ( $result->{stderr} || '' ),
      ( $result->{stdout} || '' );
}

# _tmux_session_name($workspace)
# Converts the logical workspace reference to the tmux session identifier used
# by tmux, which normalizes periods to underscores and treats a raw period as a
# session/window target separator. Input: logical workspace name. Output: tmux
# session name with periods mapped to underscores.
sub _tmux_session_name {
    my ($workspace) = @_;
    die 'Missing session name' if !defined $workspace || $workspace eq '';
    $workspace =~ s/\./_/g;
    return $workspace;
}

# _verify_workspace_session_identity(%args)
# Rejects reuse of a normalized tmux session already tagged for a different
# logical workspace. Input: logical workspace, tmux-normalized session name,
# and optional runner. Output: true if untagged or correctly tagged; dies on a
# tmux query error or an identity collision.
sub _verify_workspace_session_identity {
    my (%args) = @_;
    my $workspace = $args{workspace} || die 'Missing workspace name';
    my $session = $args{tmux_session} || die 'Missing session name';
    my $tmux = $args{tmux} || \&tmux_command;
    my $result = $tmux->(
        args => [ 'show-environment', '-t', $session, 'WORKSPACE_REF' ],
    );
    return 1 if $result->{exit_code} == 1;
    die sprintf "Unable to verify tmux workspace session '%s': %s%s",
      $session,
      ( $result->{stderr} || '' ),
      ( $result->{stdout} || '' )
      if $result->{exit_code} != 0;

    my ($owner) = ( $result->{stdout} || '' ) =~ /^WORKSPACE_REF=(.*)\r?$/m;
    return 1 if !defined $owner || $owner eq '' || $owner eq $workspace;
    die sprintf "Tmux session '%s' belongs to workspace '%s', not '%s'; tmux normalizes periods to underscores\n",
      $session, $owner, $workspace;
}

# list_sessions(%args)
# Lists the current tmux session names for ticket completion and inspection.
# Input: optional tmux runner coderef.
# Output: ordered list of session name strings, or an empty list when tmux reports none.
sub list_sessions {
    my (%args) = @_;
    my $tmux = $args{tmux} || \&tmux_command;
    my $result = $tmux->(
        args => [ 'list-sessions', '-F', '#S' ],
    );

    return () if $result->{exit_code} == 1;
    die sprintf "Unable to list tmux ticket sessions: %s%s",
      ( $result->{stderr} || '' ),
      ( $result->{stdout} || '' )
      if $result->{exit_code} != 0;

    return grep { $_ ne '' } split /\r?\n/, ( $result->{stdout} || '' );
}

# build_workspace_plan(%args)
# Builds the tmux create/attach plan for one workspace session request.
# Input: args array reference, optional cwd/env_ticket/env_workspace values, and optional tmux runner coderef.
# Output: hash reference describing the logical workspace, normalized tmux session name, cwd, environment, and tmux argv lists.
sub build_workspace_plan {
    my (%args) = @_;
    my $workspace = resolve_workspace_request(
        args       => $args{args} || [],
        env_workspace => $args{env_workspace},
        env_ticket => $args{env_ticket},
    );
    my $plan_cwd = $args{cwd};
    $plan_cwd = cwd() if !defined $plan_cwd || $plan_cwd eq '';

    my $env = workspace_environment( $workspace, cwd => $plan_cwd );
    my $tmux_session = _tmux_session_name($workspace);
    my $exists = session_exists(
        session => $workspace,
        tmux    => $args{tmux},
    );

    my @env_args;
    for my $name ( sort keys %{$env} ) {
        push @env_args, '-e', "$name=$env->{$name}";
    }

    return {
        session     => $workspace,
        tmux_session => $tmux_session,
        cwd         => $plan_cwd,
        env         => $env,
        exists      => $exists,
        create      => $exists ? 0 : 1,
        create_argv => [
            'new-session',
            '-d',
            @env_args,
            '-c', $plan_cwd,
            '-s', $tmux_session,
            '-n', 'Code1',
        ],
        attach_argv => [
            'attach-session',
            '-t', $tmux_session,
        ],
    };
}

# build_ticket_plan(%args)
# Compatibility wrapper for the older ticket terminology.
# Input: same as build_workspace_plan.
# Output: workspace plan hash reference.
sub build_ticket_plan {
    return build_workspace_plan(@_);
}

# run_workspace_command(%args)
# Creates a tmux workspace session when needed and attaches to it; a registered
# path alias also selects the starting directory when -c was not requested.
# Input: args array reference plus optional cwd/env_ticket/env_workspace values
# and optional tmux runner, attach runner, and directory resolver coderefs.
# Output: plan hash reference after successful tmux create/attach operations.
sub run_workspace_command {
    my (%args) = @_;
    my $tmux = $args{tmux} || \&tmux_command;
    my ( $workspace_args, $change_dir ) = split_workspace_change_dir_args( $args{args} || [] );
    my $workspace = resolve_workspace_request(
        args          => $workspace_args,
        env_workspace => $args{env_workspace},
        env_ticket    => $args{env_ticket},
    );
    my $resolver = $args{resolve_dir} || \&registered_workspace_dir;
    my $target = $resolver->($workspace);
    if ($change_dir) {
        die "Workspace '$workspace' is not a registered dashboard path, so -c has no directory to change into\n"
          if !defined $target || $target eq '';
        die "Workspace '$workspace' resolves to '$target', which is not a directory\n"
          if !-d $target;
        chdir $target
          or die "Unable to change directory to '$target' for workspace '$workspace': $!\n";
        $args{cwd} = $target;
    }
    elsif ( defined $target && $target ne '' ) {
        die "Workspace path alias '$workspace' resolves to '$target', which is not a directory\n"
          if !-d $target;
        chdir $target
          or die "Unable to change directory to '$target' for workspace path alias '$workspace': $!\n";
        $args{cwd} = $target;
    }
    my $plan = build_workspace_plan(
        %args,
        args => $workspace_args,
        tmux => $tmux,
    );

    if ( $plan->{create} ) {
        my $created = $tmux->( args => $plan->{create_argv} );
        if ( $created->{exit_code} != 0 ) {
            my $create_detail = ( $created->{stderr} || '' ) . ( $created->{stdout} || '' );
            if ( $create_detail =~ /duplicate session/i ) {
                my ( $exists, $check_error );
                my $checked = eval {
                    $exists = session_exists(
                        session => $plan->{session},
                        tmux    => $tmux,
                    );
                    1;
                };
                $check_error = $@ if !$checked;
                die sprintf "Unable to create tmux ticket session '%s': %sSession recheck failed: %s",
                  $plan->{session}, $create_detail, $check_error
                  if !$checked;
                if ($exists) {
                    $plan->{exists} = 1;
                    $plan->{create} = 0;
                }
                else {
                    die sprintf "Unable to create tmux ticket session '%s': %s",
                      $plan->{session}, $create_detail;
                }
            }
            else {
                die sprintf "Unable to create tmux ticket session '%s': %s",
                  $plan->{session}, $create_detail;
            }
        }
    }

    _verify_workspace_session_identity(
        workspace    => $plan->{session},
        tmux_session => $plan->{tmux_session},
        tmux         => $tmux,
    ) if $plan->{exists};

    apply_workspace_environment(
        session => $plan->{tmux_session},
        env     => $plan->{env},
        tmux    => $tmux,
    );

    apply_ticket_status(
        session => $plan->{tmux_session},
        tmux    => $tmux,
    );

    # The handoff. Every tmux call above is a query or a setup command whose
    # output is read; this one is interactive and lasts as long as the session,
    # so it is not captured. On a real run this never returns.
    my $attach = resolve_attach_runner(%args);
    # A runner that reports nothing is a runner that raised nothing: treat a
    # missing exit code as success rather than comparing undef, which warns - and
    # warnings are errors here. Found by a test that returned nothing on purpose.
    my $attached = $attach->( args => $plan->{attach_argv} ) || {};
    $attached->{exit_code} = 0 if !defined $attached->{exit_code};
    die sprintf "Unable to attach tmux ticket session '%s': %s%s",
      $plan->{session},
      ( $attached->{stderr} || '' ),
      ( $attached->{stdout} || '' )
      if $attached->{exit_code} != 0;

    return $plan;
}

# run_ticket_command(%args)
# Compatibility wrapper for the older ticket terminology.
# Input: same as run_workspace_command.
# Output: workspace plan hash reference.
sub run_ticket_command {
    return run_workspace_command(@_);
}

1;

__END__

=head1 NAME

Developer::Dashboard::CLI::Ticket - private tmux ticket helper for Developer Dashboard

=head1 SYNOPSIS

  use Developer::Dashboard::CLI::Ticket qw(run_ticket_command);
  run_ticket_command( args => \@ARGV );

=head1 DESCRIPTION

Provides the shared implementation behind the private C<ticket> helper staged
under F<~/.developer-dashboard/cli/dd/> so C<dashboard ticket> can stay part of
the dashboard toolchain without installing a public top-level executable.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module owns the workspace-session runtime behind C<dashboard workspace>.
It resolves the requested workspace reference, builds the C<tmux> environment,
decides whether the session already exists, creates the session when needed,
and attaches the terminal to the chosen workspace session. Logical dotted names
are mapped to tmux's underscore-normalized names because tmux parses a period as
a session/window target separator. Existing tagged sessions are checked against
C<WORKSPACE_REF> to avoid reusing a name collision for another workspace.
If concurrent callers race to create the same session, a duplicate-session
response is accepted only after a second tmux query confirms the session exists.

=head1 WHY IT EXISTS

It exists because ticket-session behavior needs to stay deterministic and
testable. Keeping session naming, environment variables, create-vs-attach
decisions, and tmux error handling in one module prevents wrappers and prompt
helpers from inventing different rules.

=head1 WHEN TO USE

Use this file when changing how C<dashboard ticket> chooses the ticket name,
what tmux environment variables it seeds, or how create/attach failures are
reported back to the user.

=head1 HOW TO USE

Call C<run_ticket_command> from the staged helper, passing the raw argv list.
With an explicit ticket argument, that becomes both the tmux session name and
the seeded C<TICKET_REF>/C<B>/C<OB> environment set. Without an explicit
argument, the module falls back to C<$ENV{TICKET_REF}> when present. If the
session does not exist it creates a detached C<Code1> window in the current
working directory before attaching; if the session already exists it skips
creation and attaches directly. Dotted workspace references use underscores in
the tmux session name while their original dotted value remains in
C<WORKSPACE_REF>. If a normalized name is tagged for another workspace, the
command reports the collision instead of attaching to that unrelated session.
If another caller creates the session between the initial check and create
request, it rechecks the named session and attaches only after confirming the
duplicate exists; unrelated create errors remain visible.

The C<-c> option may appear before or after the workspace name. It resolves
configured path aliases first, then skill-qualified methods from each installed
skill's C<lib/Folder.pm> through the shared validated C<d2 paths>/C<cdr>
loader. Dotted nested-skill names are supported at arbitrary installed depth,
for example C<parent.child.work>. The session and its layered environment
refresh both start in the resolved directory. If no alias resolves, C<-c>
fails with an explicit error.
If another command creates the session between the initial existence check and
the create request, the helper rechecks the exact name and attaches only when
that session is confirmed; other create errors remain visible.

=head1 WHAT USES IT

It is used by the C<dashboard ticket> helper, by prompt/bootstrap flows that
want consistent ticket-session environment variables, and by regression tests
that verify explicit ticket selection, environment fallback, and tmux
create/attach error handling.

=head1 EXAMPLES

  dashboard ticket DD-123
  dashboard ticket
  TICKET_REF=DD-123 dashboard ticket
  dashboard ticket feature-branch-42
  dashboard workspace parent.child.work -c
  perl -Ilib -MDeveloper::Dashboard::CLI::Ticket=list_sessions -e 'print join qq(\n), list_sessions()'

=for comment FULL-POD-DOC END

=cut
