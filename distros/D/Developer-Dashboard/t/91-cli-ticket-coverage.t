#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Capture::Tiny qw(capture);
use Test::More;
use Cwd qw(abs_path cwd);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::CLI::Ticket qw(
  apply_ticket_status
  apply_workspace_environment
  apply_workspace_status
  build_ticket_plan
  build_workspace_plan
  list_sessions
  registered_workspace_dir
  resolve_ticket_request
  resolve_workspace_request
  run_ticket_command
  resolve_attach_runner
  run_workspace_command
  session_exists
  split_workspace_change_dir_args
  ticket_environment
  tmux_command
  workspace_environment
);

# registered_workspace_dir() resolves these three at run time; load them here so
# the hermetic chdir below cannot strand a relative library path.
use Developer::Dashboard::Config      ();
use Developer::Dashboard::FileRegistry ();
use Developer::Dashboard::PathRegistry ();
use Developer::Dashboard::JSON qw(json_encode);

my $repo = abs_path('.');

# Warnings are fatal in this repository: collect any and assert none escaped.
my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0]; return; };

# Hermetic runtime rooted at a temp home. Config layers resolve from the deepest
# .developer-dashboard directory at or above the invocation cwd, so move the
# process into the temp home before exercising any path-aware code.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME}                           = $home;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
chdir $home or die "Unable to chdir to $home: $!";

my $paths = Developer::Dashboard::PathRegistry->new(
    home            => $home,
    cwd             => $home,
    workspace_roots => [],
    project_roots   => [],
);
is( $paths->home, $home, 'the hermetic path registry is rooted at the temp home the module discovers through HOME' );

# write_file($path, $content)
# Creates any missing parent directories and writes one fixture file.
# Input: absolute file path and file body.
# Output: the file path.
sub write_file {
    my ( $path, $content ) = @_;
    make_path( dirname($path) );
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $content;
    close $fh or die "Unable to close $path: $!";
    return $path;
}

# write_stub_command($path)
# Writes one silent, successful executable stub used to stand in for a real
# command found through PATH.
# Input: absolute file path for the stub.
# Output: the stub path.
sub write_stub_command {
    my ($path) = @_;
    write_file( $path, "#!/bin/sh\nexit 0\n" );
    chmod 0755, $path or die "Unable to chmod $path: $!";
    return $path;
}

# error_from($code)
# Runs one coderef and returns the exception it raised.
# Input: coderef.
# Output: exception string, or empty string when the coderef returned normally.
sub error_from {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? '' : "$@";
}

# tmux_stub($dispatch)
# Builds a tmux runner stand-in that answers each argv from one dispatch
# coderef, defaulting every field the dispatch omits to a silent success.
# Input: coderef receiving the tmux argv list and returning a partial result.
# Output: coderef carrying the module's tmux runner signature.
sub tmux_stub {
    my ($dispatch) = @_;
    return sub {
        my (%args) = @_;
        my $reply = $dispatch->( @{ $args{args} } ) || {};
        return { exit_code => 0, stdout => '', stderr => '', %{$reply} };
    };
}

# ok_tmux()
# Builds a tmux runner stand-in that succeeds silently for every argv.
# Input: none.
# Output: tmux runner coderef.
sub ok_tmux { return tmux_stub( sub { return {} } ) }

my $fake_bin  = File::Spec->catdir( $home, 'fakebin' );
my $dash_bin  = File::Spec->catdir( $home, 'dashbin' );
my $empty_bin = File::Spec->catdir( $home, 'emptybin' );
make_path($empty_bin);
write_stub_command( File::Spec->catfile( $fake_bin, 'tmux' ) );
write_stub_command( File::Spec->catfile( $dash_bin, 'dashboard' ) );

my $ws_dir = File::Spec->catdir( $home, 'ws' );
write_file( File::Spec->catfile( $ws_dir, '.env' ), "WS_LAYER_KEY=layer\n" );
my $ws_env_file = File::Spec->catfile( abs_path($ws_dir), '.env' );

# --- split_workspace_change_dir_args ---------------------------------------

{
    like(
        error_from( sub { split_workspace_change_dir_args('nope') } ),
        qr/Workspace args must be an array reference/,
        'split_workspace_change_dir_args rejects a non-array argv container',
    );

    my ( $clean, $change_dir ) = split_workspace_change_dir_args( [ undef, 'DD-1', '-c' ] );
    is_deeply( $clean, [ undef, 'DD-1' ], 'split_workspace_change_dir_args passes an undefined argument through and strips -c' );
    is( $change_dir, 1, 'split_workspace_change_dir_args reports -c wherever it appears in argv' );

    my ( $plain, $no_change ) = split_workspace_change_dir_args( ['DD-1'] );
    is_deeply( $plain, ['DD-1'], 'split_workspace_change_dir_args leaves a plain workspace argv untouched' );
    is( $no_change, 0, 'split_workspace_change_dir_args reports no change-directory request by default' );
}

# --- registered_workspace_dir ----------------------------------------------

{
    is( registered_workspace_dir( File::Spec->rootdir ), File::Spec->rootdir, 'registered_workspace_dir passes an absolute path straight through' );
    is( registered_workspace_dir('dd-ticket-unregistered-workspace'), '', 'registered_workspace_dir returns empty for a name no layer registers' );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::PathRegistry::resolve_dir = sub { die "unexpected resolver failure\n" };
    like(
        error_from( sub { registered_workspace_dir('bar.root') } ),
        qr/unexpected resolver failure/,
        'registered_workspace_dir propagates real path resolver errors instead of treating them as absent aliases',
    );
}

{
    my $skill_target = File::Spec->catdir( $home, 'skill-project' );
    my $skill_config = File::Spec->catfile( $home, '.developer-dashboard', 'skills', 'bar', 'config', 'config.json' );
    make_path($skill_target);
    write_file( $skill_config, json_encode( { path_aliases => { foo => $skill_target } } ) );

    is( registered_workspace_dir('bar.foo'), $skill_target,
        'registered_workspace_dir resolves a path alias qualified by its owning skill' );

    my $old_cwd = cwd();
    my $plan = run_workspace_command(
        args   => ['bar.foo'],
        tmux   => ok_tmux(),
        attach => sub { return { exit_code => 0 } },
    );
    is( $plan->{session}, 'bar.foo', 'workspace keeps the qualified skill alias as the tmux session name' );
    is( $plan->{cwd}, $skill_target, 'workspace alias starts the session in its resolved skill path without requiring -c' );
    chdir $old_cwd or die "Unable to restore cwd to $old_cwd: $!";
}

{
    my $skill_root = File::Spec->catdir( $home, '.developer-dashboard', 'skills', 'bar' );
    my $nested_root = File::Spec->catdir( $skill_root, 'skills', 'baz' );
    my $deep_root = File::Spec->catdir( $nested_root, 'skills', 'qux' );
    my $skill_target = File::Spec->catdir( $home, 'folder-project' );
    my $nested_target = File::Spec->catdir( $home, 'nested-folder-project' );
    my $deep_target = File::Spec->catdir( $home, 'deep-folder-project' );
    my $configured_target = File::Spec->catdir( $home, 'configured-folder-project' );
    make_path( $skill_target, $nested_target, $deep_target, $configured_target );
    write_file(
        File::Spec->catfile( $skill_root, 'lib', 'Folder.pm' ),
        "package Folder; sub __list__ { return qw(root collision); } sub root { return '$skill_target'; } sub collision { return '$skill_target'; } 1;\n",
    );
    write_file(
        File::Spec->catfile( $skill_root, 'config', 'config.json' ),
        json_encode( { path_aliases => { collision => $configured_target } } ),
    );
    write_file(
        File::Spec->catfile( $nested_root, 'lib', 'Folder.pm' ),
        "package Folder; sub __list__ { return qw(nested); } sub nested { return '$nested_target'; } 1;\n",
    );
    write_file(
        File::Spec->catfile( $deep_root, 'lib', 'Folder.pm' ),
        "package Folder; sub __list__ { return qw(leaf); } sub leaf { return '$deep_target'; } 1;\n",
    );

    for my $case (
        [ 'bar.root',       $skill_target,  'top-level skill Folder.pm alias' ],
        [ 'bar.baz.nested', $nested_target, 'nested skill Folder.pm alias' ],
        [ 'bar.baz.qux.leaf', $deep_target, 'deeper nested skill Folder.pm alias' ],
    ) {
        my ( $alias, $target, $label ) = @{$case};
        is( registered_workspace_dir($alias), $target, "registered_workspace_dir resolves $label" );
        my $old_cwd = cwd();
        my $plan = run_workspace_command(
            args   => [ $alias, '-c' ],
            tmux   => ok_tmux(),
            attach => sub { return { exit_code => 0 } },
        );
        is( $plan->{cwd}, $target, "workspace -c starts in the $label target" );
        chdir $old_cwd or die "Unable to restore cwd to $old_cwd: $!";
    }
    is( registered_workspace_dir('bar.collision'), $configured_target,
        'configured skill path aliases take precedence over same-named Folder.pm methods' );

    my $fake_bin = File::Spec->catdir( $home, 'fake-tmux-bin' );
    my $tmux_trace = File::Spec->catfile( $home, 'tmux.trace' );
    my $fake_tmux = File::Spec->catfile( $fake_bin, 'tmux' );
    write_file(
        $fake_tmux,
        "#!/bin/sh\nprintf '%s|%s\\n' \"\$PWD\" \"\$*\" >> \"\$TMUX_TRACE\"\n[ \"\$1\" = has-session ] && exit 1\nexit 0\n",
    );
    chmod 0755, $fake_tmux or die "Unable to chmod $fake_tmux: $!";
    {
        local $ENV{PATH} = "$fake_bin:$ENV{PATH}";
        local $ENV{TMUX_TRACE} = $tmux_trace;
        my ( $stdout, $stderr, $exit ) = capture {
            system $^X, "-I" . File::Spec->catdir( $repo, 'lib' ),
              File::Spec->catfile( $repo, 'bin', 'd2' ),
              'workspace', 'bar.baz.qux.leaf', '-c';
            return $? >> 8;
        };
        is( $exit, 0, 'd2 workspace -c accepts a deepest nested skill Folder.pm alias through the public short entrypoint' );
        is( $stderr, '', 'public workspace alias resolution emits no error' );
        open my $trace_fh, '<', $tmux_trace or die "Unable to read $tmux_trace: $!";
        local $/;
        my $trace = <$trace_fh>;
        close $trace_fh or die "Unable to close $tmux_trace: $!";
        like( $trace, qr/\Q$deep_target\E\|new-session .* -c \Q$deep_target\E/s,
            'public workspace CLI creates its tmux session in the deepest Folder.pm target' );
    }
}

{
    local %ENV = %ENV;
    $ENV{HOME} = '';
    delete $ENV{USERPROFILE};
    delete $ENV{HOMEDRIVE};
    delete $ENV{HOMEPATH};
    like(
        error_from( sub { registered_workspace_dir('dd-ticket-unregistered-workspace') } ),
        qr/Missing home directory/,
        'registered_workspace_dir refuses to invent a path inventory when the environment carries no home directory',
    );
}

# --- resolve_workspace_request ---------------------------------------------

{
    local %ENV = %ENV;
    delete $ENV{WORKSPACE_REF};
    delete $ENV{TICKET_REF};

    like(
        error_from( sub { resolve_workspace_request( args => 'nope' ) } ),
        qr/Workspace args must be an array reference/,
        'resolve_workspace_request rejects a non-array argv container',
    );
    like(
        error_from( sub { resolve_workspace_request() } ),
        qr/Please specify a workspace name/,
        'resolve_workspace_request dies when neither argv, arguments, nor the environment name a workspace',
    );
    is( resolve_workspace_request( args => ['DD-1'] ), 'DD-1', 'resolve_workspace_request prefers the explicit argv workspace' );
    is(
        resolve_workspace_request( args => [''], env_workspace => '', env_ticket => 'DD-2' ),
        'DD-2',
        'resolve_workspace_request falls back to env_ticket when argv and env_workspace are both empty',
    );
}

{
    local %ENV = %ENV;
    $ENV{WORKSPACE_REF} = '';
    $ENV{TICKET_REF}    = 'DD-3';
    is(
        resolve_workspace_request( args => [''], env_workspace => '' ),
        'DD-3',
        'resolve_workspace_request falls back to TICKET_REF when every earlier source is empty',
    );
}

{
    local %ENV = %ENV;
    $ENV{WORKSPACE_REF} = '';
    $ENV{TICKET_REF}    = '';
    like(
        error_from( sub { resolve_workspace_request( args => [''], env_workspace => '', env_ticket => '' ) } ),
        qr/Please specify a workspace name/,
        'resolve_workspace_request treats a defined-but-empty value from every source as no workspace at all',
    );
}

# --- resolve_ticket_request ------------------------------------------------

{
    like(
        error_from( sub { resolve_ticket_request( args => 'nope' ) } ),
        qr/Ticket args must be an array reference/,
        'resolve_ticket_request rejects a non-array argv container',
    );
    like(
        error_from( sub { resolve_ticket_request() } ),
        qr/Please specify a ticket name/,
        'resolve_ticket_request dies when no argv list is supplied at all',
    );
    is( resolve_ticket_request( args => ['DD-1'] ), 'DD-1', 'resolve_ticket_request prefers the explicit argv ticket' );
    is( resolve_ticket_request( args => [''], env_ticket => 'DD-2' ), 'DD-2', 'resolve_ticket_request falls back to env_ticket for an empty argv ticket' );
    like(
        error_from( sub { resolve_ticket_request( args => [''], env_ticket => '' ) } ),
        qr/Please specify a ticket name/,
        'resolve_ticket_request rejects a defined-but-empty env_ticket fallback',
    );
}

# --- _workspace_env_files ---------------------------------------------------

{
    my @files = Developer::Dashboard::CLI::Ticket::_workspace_env_files( cwd => $ws_dir );
    is( $files[-1], $ws_env_file, '_workspace_env_files ends the ordered chain at the requested directory .env' );
}

{
    chdir $ws_dir or die "Unable to chdir to $ws_dir: $!";
    my @files = Developer::Dashboard::CLI::Ticket::_workspace_env_files( cwd => '' );
    is( $files[-1], $ws_env_file, '_workspace_env_files falls back to the process cwd for an empty cwd argument' );
    chdir $home or die "Unable to chdir to $home: $!";
}

{
    my @files = Developer::Dashboard::CLI::Ticket::_workspace_env_files( cwd => 'dd/ticket/no/such/dir' );
    is_deeply( \@files, [], '_workspace_env_files stops walking once an unresolvable relative path bottoms out at the current directory' );
}

{
    # Cwd::cwd() returns undef when the process working directory cannot be
    # resolved at all; the loader must then report no layered env files rather
    # than walk an undefined path.
    local *Developer::Dashboard::CLI::Ticket::cwd = sub { return undef };
    my @files = Developer::Dashboard::CLI::Ticket::_workspace_env_files();
    is_deeply( \@files, [], '_workspace_env_files returns nothing when the process cwd cannot be resolved' );
}

# --- workspace_environment / ticket_environment ----------------------------

{
    like( error_from( sub { workspace_environment(undef) } ), qr/Workspace name is required/, 'workspace_environment rejects an undefined workspace name' );
    like( error_from( sub { workspace_environment('') } ),    qr/Workspace name is required/, 'workspace_environment rejects an empty workspace name' );

    my $env = workspace_environment( 'DD-1', cwd => $ws_dir );
    is( $env->{WORKSPACE_REF}, 'DD-1',        'workspace_environment seeds WORKSPACE_REF from the workspace name' );
    is( $env->{OB},            'origin/DD-1', 'workspace_environment seeds the origin branch alias' );
    is( $env->{WS_LAYER_KEY},  'layer',       'workspace_environment overlays the layered .env chain for the requested cwd' );
    like( $env->{DEVELOPER_DASHBOARD_WORKSPACE_ENV_KEYS}, qr/\bWS_LAYER_KEY\b/, 'workspace_environment records the layered env keys for later session refresh' );

    my $default_cwd_env = workspace_environment('DD-2');
    is( $default_cwd_env->{B}, 'DD-2', 'workspace_environment defaults to the process cwd when no cwd is supplied' );

    my $empty_cwd_env = workspace_environment( 'DD-3', cwd => '' );
    is( $empty_cwd_env->{B}, 'DD-3', 'workspace_environment treats an empty cwd argument as the process cwd' );
}

{
    like( error_from( sub { ticket_environment(undef) } ), qr/Ticket name is required/, 'ticket_environment rejects an undefined ticket name' );
    like( error_from( sub { ticket_environment('') } ),    qr/Ticket name is required/, 'ticket_environment rejects an empty ticket name' );

    my $env = ticket_environment( 'DD-4', cwd => $ws_dir );
    is( $env->{TICKET_REF}, 'DD-4', 'ticket_environment seeds the legacy TICKET_REF value' );
    ok( !exists $env->{WORKSPACE_REF},                          'ticket_environment drops the workspace-only reference' );
    ok( !exists $env->{DEVELOPER_DASHBOARD_WORKSPACE_ENV_KEYS}, 'ticket_environment drops the workspace-only env key manifest' );
}

# --- tmux_command -----------------------------------------------------------

{
    like( error_from( sub { tmux_command( args => 'nope' ) } ), qr/tmux args must be an array reference/, 'tmux_command rejects a non-array argv container' );

    local $ENV{PATH} = $fake_bin;
    my $bare = tmux_command();
    is( $bare->{exit_code}, 0,  'tmux_command runs tmux with no arguments when none are supplied' );
    is( $bare->{stdout},    '', 'tmux_command captures stdout from the tmux process' );
    is( $bare->{stderr},    '', 'tmux_command captures stderr from the tmux process' );

    my $versioned = tmux_command( args => ['-V'] );
    is( $versioned->{exit_code}, 0, 'tmux_command reports the exit status of an explicit tmux argv' );

    # DD-597: system() above mutates the caller's global $? as a side effect;
    # without a guard at the sub's entry that stays set in the caller's
    # process after this sub returns, regardless of the exit code already
    # captured in this sub's own return value.
    $? = 12 << 8;    ## no critic (Variables::RequireLocalizedPunctuationVars)
    tmux_command();
    is( $? >> 8, 12, 'tmux_command does not leak its own subprocess status into the caller global $?' );
}

# --- _tmux_stdout -----------------------------------------------------------

{
    local $ENV{PATH} = $fake_bin;
    is( scalar Developer::Dashboard::CLI::Ticket::_tmux_stdout(), '', '_tmux_stdout defaults to the real tmux runner and an empty argv' );
}

is(
    scalar Developer::Dashboard::CLI::Ticket::_tmux_stdout(
        tmux => tmux_stub( sub { return { stdout => "value\r\n" } } ),
        args => ['show-options'],
    ),
    'value',
    '_tmux_stdout trims the trailing newline from a successful tmux read',
);
is(
    scalar Developer::Dashboard::CLI::Ticket::_tmux_stdout(
        tmux => tmux_stub( sub { return { exit_code => 3, stdout => "ignored\n" } } ),
        args => ['show-options'],
    ),
    undef,
    '_tmux_stdout discards stdout when tmux exits non-zero',
);
is(
    scalar Developer::Dashboard::CLI::Ticket::_tmux_stdout(
        tmux => tmux_stub( sub { return { stdout => undef } } ),
        args => ['show-options'],
    ),
    undef,
    '_tmux_stdout returns undef when a succeeding tmux call produced no stdout at all',
);

# --- _dashboard_command_path ------------------------------------------------

{
    local %ENV = %ENV;
    $ENV{DEVELOPER_DASHBOARD_ENTRYPOINT} = '/opt/dd/bin/dashboard';
    is( Developer::Dashboard::CLI::Ticket::_dashboard_command_path(), '/opt/dd/bin/dashboard', '_dashboard_command_path prefers an explicit entrypoint override' );
}

{
    local %ENV = %ENV;
    $ENV{DEVELOPER_DASHBOARD_ENTRYPOINT} = '';
    $ENV{PATH}                           = $dash_bin;
    is(
        Developer::Dashboard::CLI::Ticket::_dashboard_command_path(),
        File::Spec->catfile( $dash_bin, 'dashboard' ),
        '_dashboard_command_path ignores an empty entrypoint override and searches PATH',
    );
}

{
    local %ENV = %ENV;
    delete $ENV{DEVELOPER_DASHBOARD_ENTRYPOINT};
    $ENV{PATH} = $empty_bin;
    is( Developer::Dashboard::CLI::Ticket::_dashboard_command_path(), 'dashboard', '_dashboard_command_path falls back to the bare command name when PATH holds no dashboard' );
}

# --- apply_workspace_environment --------------------------------------------

like( error_from( sub { apply_workspace_environment() } ), qr/Missing session name/, 'apply_workspace_environment requires a session name' );
like(
    error_from( sub { apply_workspace_environment( session => 'DD-1', env => 'nope', tmux => ok_tmux() ) } ),
    qr/Workspace env must be a hash reference/,
    'apply_workspace_environment rejects a non-hash workspace env',
);

{
    local $ENV{PATH} = $fake_bin;
    is( apply_workspace_environment( session => 'DD-1' ), 1, 'apply_workspace_environment defaults to the real tmux runner and an empty env' );
}

{
    my @calls;
    my $tmux = tmux_stub(
        sub {
            my (@argv) = @_;
            push @calls, [@argv];
            return { stdout => "DEVELOPER_DASHBOARD_WORKSPACE_ENV_KEYS=DROPPED:KEPT\n" } if $argv[0] eq 'show-environment';
            return {};
        }
    );

    is(
        apply_workspace_environment(
            session => 'DD-1',
            tmux    => $tmux,
            env     => {
                DEVELOPER_DASHBOARD_WORKSPACE_ENV_KEYS => 'KEPT',
                KEPT                                   => 'value',
            },
        ),
        1,
        'apply_workspace_environment reports success once the session environment is refreshed',
    );

    my @unset = grep { $_->[0] eq 'set-environment' && $_->[3] eq '-u' } @calls;
    is_deeply(
        [ map { $_->[4] } @unset ],
        ['DROPPED'],
        'apply_workspace_environment unsets only the layered keys the workspace no longer carries',
    );
}

{
    my $tmux = tmux_stub(
        sub {
            my (@argv) = @_;
            return { exit_code => 1, stderr => "no server running\n" } if $argv[0] eq 'show-environment';
            return {};
        }
    );
    is(
        apply_workspace_environment( session => 'DD-1', env => { FOO => 'bar' }, tmux => $tmux ),
        1,
        'apply_workspace_environment treats an unreadable session environment as having no previous layered keys',
    );
}

{
    my $tmux = tmux_stub(
        sub {
            my (@argv) = @_;
            return { stdout => "DEVELOPER_DASHBOARD_WORKSPACE_ENV_KEYS=DROPPED\n" } if $argv[0] eq 'show-environment';
            return { exit_code => 1, stderr => "unset refused\n", stdout => "unset detail\n" } if $argv[0] eq 'set-environment' && $argv[3] eq '-u';
            return {};
        }
    );
    my $err = error_from( sub { apply_workspace_environment( session => 'DD-1', env => {}, tmux => $tmux ) } );
    like( $err, qr/Unable to refresh tmux workspace environment for 'DD-1': unset refused/, 'apply_workspace_environment reports tmux stderr when unsetting a dropped key fails' );
    like( $err, qr/unset detail/, 'apply_workspace_environment also reports tmux stdout when unsetting a dropped key fails' );
}

{
    my $tmux = tmux_stub(
        sub {
            my (@argv) = @_;
            return { stdout => "DEVELOPER_DASHBOARD_WORKSPACE_ENV_KEYS=DROPPED\n" } if $argv[0] eq 'show-environment';
            return { exit_code => 1 } if $argv[0] eq 'set-environment' && $argv[3] eq '-u';
            return {};
        }
    );
    my $err = error_from( sub { apply_workspace_environment( session => 'DD-1', env => {}, tmux => $tmux ) } );
    like( $err, qr/Unable to refresh tmux workspace environment for 'DD-1'/, 'apply_workspace_environment still fails loudly when a refused unset says nothing at all' );
}

{
    my $tmux = tmux_stub(
        sub {
            my (@argv) = @_;
            return { exit_code => 1, stderr => "set refused\n", stdout => "set detail\n" } if $argv[0] eq 'set-environment';
            return {};
        }
    );
    my $err = error_from( sub { apply_workspace_environment( session => 'DD-1', env => { FOO => 'bar' }, tmux => $tmux ) } );
    like( $err, qr/Unable to refresh tmux workspace environment for 'DD-1': set refused/, 'apply_workspace_environment reports tmux stderr when seeding a key fails' );
    like( $err, qr/set detail/, 'apply_workspace_environment also reports tmux stdout when seeding a key fails' );
}

{
    my $tmux = tmux_stub(
        sub {
            my (@argv) = @_;
            return { exit_code => 1 } if $argv[0] eq 'set-environment';
            return {};
        }
    );
    my $err = error_from( sub { apply_workspace_environment( session => 'DD-1', env => { FOO => 'bar' }, tmux => $tmux ) } );
    like( $err, qr/Unable to refresh tmux workspace environment for 'DD-1'/, 'apply_workspace_environment still fails loudly when a refused set says nothing at all' );
}

# --- apply_ticket_status / apply_workspace_status ---------------------------

like( error_from( sub { apply_ticket_status() } ), qr/Missing session name/, 'apply_ticket_status requires a session name' );

{
    local $ENV{PATH} = "$fake_bin:$dash_bin";
    is( apply_ticket_status( session => 'DD-1' ), 1, 'apply_ticket_status defaults to the real tmux runner and the resolved dashboard entrypoint' );
}

{
    my @calls;
    my $tmux = tmux_stub(
        sub {
            my (@argv) = @_;
            push @calls, [@argv];
            return { stdout => "SAVED-DEFAULT\n" } if $argv[0] eq 'show-options';
            return {};
        }
    );
    is(
        apply_workspace_status( session => 'DD-1', dashboard => '/opt/dd/bin/dashboard', tmux => $tmux ),
        1,
        'apply_workspace_status configures the session status through the ticket-status implementation',
    );

    my ($restored) = grep { $_->[0] eq 'set-option' && $_->[2] eq 'status-format[1]' } @calls;
    is_deeply(
        $restored,
        [ 'set-option', '-gq', 'status-format[1]', 'SAVED-DEFAULT' ],
        'apply_workspace_status keeps the recorded default status on the second status row',
    );

    my ($indicators) = grep { $_->[0] eq 'set-option' && $_->[2] eq 'status-format[0]' } @calls;
    like( $indicators->[3], qr{\Q/opt/dd/bin/dashboard\E}, 'apply_workspace_status renders dashboard indicators on the top status row' );
}

{
    my $tmux = tmux_stub(
        sub {
            my (@argv) = @_;
            return { exit_code => 1 } if $argv[0] eq 'show-options';
            return {};
        }
    );
    is(
        apply_ticket_status( session => 'DD-1', dashboard => 'dashboard', tmux => $tmux ),
        1,
        'apply_ticket_status configures a session whose tmux exposes no readable status options',
    );
}

{
    my @calls;
    my $tmux = tmux_stub(
        sub {
            my (@argv) = @_;
            push @calls, [@argv];
            return { stdout => "FMT0\n" } if $argv[0] eq 'show-options' && $argv[2] eq 'status-format[0]';
            return {};
        }
    );
    is(
        apply_ticket_status( session => 'DD-1', dashboard => 'dashboard', tmux => $tmux ),
        1,
        'apply_ticket_status records the live status row as the default before overwriting it',
    );
    my ($saved) = grep { $_->[0] eq 'set-option' && $_->[2] eq '@dd_ticket_status_default' } @calls;
    is_deeply( $saved, [ 'set-option', '-gq', '@dd_ticket_status_default', 'FMT0' ], 'apply_ticket_status saves the discovered status row under the dashboard option' );
}

{
    my $tmux = tmux_stub(
        sub {
            my (@argv) = @_;
            return { stdout => "FMT0\n" } if $argv[0] eq 'show-options' && $argv[2] eq 'status-format[0]';
            return { exit_code => 1, stderr => "save refused\n", stdout => "save detail\n" } if $argv[0] eq 'set-option' && $argv[2] eq '@dd_ticket_status_default';
            return {};
        }
    );
    my $err = error_from( sub { apply_ticket_status( session => 'DD-1', dashboard => 'dashboard', tmux => $tmux ) } );
    like( $err, qr/Unable to record tmux ticket default status for 'DD-1': save refused/, 'apply_ticket_status reports tmux stderr when the default status cannot be recorded' );
    like( $err, qr/save detail/, 'apply_ticket_status also reports tmux stdout when the default status cannot be recorded' );
}

{
    my $tmux = tmux_stub(
        sub {
            my (@argv) = @_;
            return { stdout => "FMT0\n" } if $argv[0] eq 'show-options' && $argv[2] eq 'status-format[0]';
            return { exit_code => 1 } if $argv[0] eq 'set-option' && $argv[2] eq '@dd_ticket_status_default';
            return {};
        }
    );
    my $err = error_from( sub { apply_ticket_status( session => 'DD-1', dashboard => 'dashboard', tmux => $tmux ) } );
    like( $err, qr/Unable to record tmux ticket default status for 'DD-1'/, 'apply_ticket_status still fails loudly when a refused default-status save says nothing at all' );
}

{
    my $tmux = tmux_stub(
        sub {
            my (@argv) = @_;
            return { stdout => "SAVED-DEFAULT\n" } if $argv[0] eq 'show-options';
            return { exit_code => 1, stderr => "status refused\n", stdout => "status detail\n" } if $argv[0] eq 'set-option';
            return {};
        }
    );
    my $err = error_from( sub { apply_ticket_status( session => 'DD-1', dashboard => 'dashboard', tmux => $tmux ) } );
    like( $err, qr/Unable to configure tmux ticket status for 'DD-1': status refused/, 'apply_ticket_status reports tmux stderr when a status option is refused' );
    like( $err, qr/status detail/, 'apply_ticket_status also reports tmux stdout when a status option is refused' );
}

{
    my $tmux = tmux_stub(
        sub {
            my (@argv) = @_;
            return { stdout => "SAVED-DEFAULT\n" } if $argv[0] eq 'show-options';
            return { exit_code => 1 } if $argv[0] eq 'set-option';
            return {};
        }
    );
    my $err = error_from( sub { apply_ticket_status( session => 'DD-1', dashboard => 'dashboard', tmux => $tmux ) } );
    like( $err, qr/Unable to configure tmux ticket status for 'DD-1'/, 'apply_ticket_status still fails loudly when a refused status option says nothing at all' );
}

# --- session_exists ---------------------------------------------------------

like( error_from( sub { session_exists() } ), qr/Missing session name/, 'session_exists requires a session name' );

{
    local $ENV{PATH} = $fake_bin;
    is( session_exists( session => 'DD-1' ), 1, 'session_exists defaults to the real tmux runner' );
}

is( session_exists( session => 'DD-1', tmux => ok_tmux() ), 1, 'session_exists reports an existing session' );
is( session_exists( session => 'DD-1', tmux => tmux_stub( sub { return { exit_code => 1 } } ) ), 0, 'session_exists reports a missing session' );
{
    my @session_query;
    session_exists(
        session => 'ch.docker',
        tmux    => tmux_stub( sub { @session_query = @_; return { exit_code => 0 } } ),
    );
    is_deeply( \@session_query, [ 'has-session', '-t', 'ch_docker' ],
        'session_exists uses tmux-normalized names when a workspace contains dots' );
}

{
    my $err = error_from( sub { session_exists( session => 'DD-1', tmux => tmux_stub( sub { return { exit_code => 2, stderr => "inspect refused\n", stdout => "inspect detail\n" } } ) ) } );
    like( $err, qr/Unable to inspect tmux session 'DD-1': inspect refused/, 'session_exists reports tmux stderr for an unusable tmux' );
    like( $err, qr/inspect detail/, 'session_exists also reports tmux stdout for an unusable tmux' );
}

{
    my $err = error_from( sub { session_exists( session => 'DD-1', tmux => tmux_stub( sub { return { exit_code => 2 } } ) ) } );
    like( $err, qr/Unable to inspect tmux session 'DD-1'/, 'session_exists still fails loudly when an unusable tmux says nothing at all' );
}

# --- list_sessions ----------------------------------------------------------

{
    local $ENV{PATH} = $fake_bin;
    is_deeply( [ list_sessions() ], [], 'list_sessions defaults to the real tmux runner and reports no sessions for empty output' );
}

is_deeply(
    [ list_sessions( tmux => tmux_stub( sub { return { stdout => "alpha\r\n\nbeta\n" } } ) ) ],
    [ 'alpha', 'beta' ],
    'list_sessions splits session names on either line ending and drops blank lines',
);

is( Developer::Dashboard::CLI::Ticket::_tmux_session_name('ch.docker'), 'ch_docker',
    '_tmux_session_name mirrors tmux period-to-underscore normalization' );
is( Developer::Dashboard::CLI::Ticket::_tmux_session_name('DD-123'), 'DD-123',
    '_tmux_session_name leaves ordinary workspace references unchanged' );
like( error_from( sub { Developer::Dashboard::CLI::Ticket::_tmux_session_name() } ), qr/Missing session name/,
    '_tmux_session_name rejects an absent workspace reference' );
like( error_from( sub { Developer::Dashboard::CLI::Ticket::_tmux_session_name('') } ), qr/Missing session name/,
    '_tmux_session_name rejects an empty workspace reference' );
is_deeply( [ list_sessions( tmux => tmux_stub( sub { return { exit_code => 1 } } ) ) ], [], 'list_sessions reports no sessions when tmux has no server running' );

{
    my $err = error_from( sub { list_sessions( tmux => tmux_stub( sub { return { exit_code => 2, stderr => "list refused\n", stdout => "list detail\n" } } ) ) } );
    like( $err, qr/Unable to list tmux ticket sessions: list refused/, 'list_sessions reports tmux stderr for an unusable tmux' );
    like( $err, qr/list detail/, 'list_sessions also reports tmux stdout for an unusable tmux' );
}

{
    my $err = error_from( sub { list_sessions( tmux => tmux_stub( sub { return { exit_code => 2 } } ) ) } );
    like( $err, qr/Unable to list tmux ticket sessions:/, 'list_sessions still fails loudly when an unusable tmux says nothing at all' );
}

# --- build_workspace_plan / build_ticket_plan -------------------------------

{
    local %ENV = %ENV;
    delete $ENV{WORKSPACE_REF};
    delete $ENV{TICKET_REF};

    my $plan = build_workspace_plan( env_workspace => 'DD-1', tmux => ok_tmux() );
    is( $plan->{session}, 'DD-1', 'build_workspace_plan resolves the workspace without an argv list' );
    is( $plan->{cwd},     cwd(),  'build_workspace_plan defaults the session cwd to the process cwd' );
    is( $plan->{exists},  1,      'build_workspace_plan reports an already-running session' );
    is( $plan->{create},  0,      'build_workspace_plan skips creation for an already-running session' );

    my $empty_cwd_plan = build_workspace_plan( args => ['DD-2'], cwd => '', tmux => ok_tmux() );
    is( $empty_cwd_plan->{cwd}, cwd(), 'build_workspace_plan treats an empty cwd argument as the process cwd' );

    my $create_plan = build_ticket_plan( args => ['DD-3'], cwd => $ws_dir, tmux => tmux_stub( sub { return { exit_code => 1 } } ) );
    is( $create_plan->{cwd},    $ws_dir, 'build_ticket_plan honours an explicit session cwd' );
    is( $create_plan->{create}, 1,       'build_ticket_plan asks for creation when the session does not exist' );
    is( $create_plan->{tmux_session}, 'DD-3', 'build_ticket_plan records the exact tmux session name separately from the workspace reference' );
    is_deeply( $create_plan->{attach_argv}, [ 'attach-session', '-t', 'DD-3' ], 'build_ticket_plan builds the attach argv for the resolved session' );
    is( $create_plan->{create_argv}[0], 'new-session', 'build_ticket_plan builds a detached new-session argv' );
}

# --- run_workspace_command / run_ticket_command -----------------------------

{
    my @calls;
    my $has_session_calls = 0;
    my $tmux = sub {
        my (%args) = @_;
        my @argv = @{ $args{args} || [] };
        push @calls, [@argv];
        if ( $argv[0] eq 'has-session' ) {
            $has_session_calls++;
            return { exit_code => $has_session_calls == 1 ? 1 : 0 };
        }
        if ( $argv[0] eq 'new-session' ) {
            return { exit_code => 1, stderr => "duplicate session: ch.docker\n" };
        }
        return { exit_code => 0 };
    };
    my @attached;
    my $old_cwd = cwd();
    my $plan = run_workspace_command(
        args       => [ 'ch.docker', '-c' ],
        resolve_dir => sub { return $ws_dir },
        tmux       => $tmux,
        attach     => sub { my (%args) = @_; push @attached, $args{args}; return { exit_code => 0 } },
    );
    chdir $old_cwd or die "Unable to restore cwd to $old_cwd: $!";
    is( $plan->{exists}, 1, 'run_workspace_command accepts a duplicate-session response after confirming the session now exists' );
    is( $plan->{create}, 0, 'run_workspace_command updates its plan when another caller created the session first' );
    is( $has_session_calls, 2, 'run_workspace_command rechecks session state only after a failed create' );
    is( scalar( grep { $_->[0] eq 'new-session' } @calls ), 1, 'run_workspace_command makes only one create attempt for a racing session' );
    my ($create_call) = grep { $_->[0] eq 'new-session' } @calls;
    my ($session_flag) = grep { $create_call->[$_] eq '-s' } 0 .. $#{$create_call};
    is( $create_call->[ $session_flag + 1 ], 'ch_docker', 'run_workspace_command creates dotted workspaces under tmux-normalized names' );
    is_deeply( $attached[0], [ 'attach-session', '-t', 'ch_docker' ], 'run_workspace_command attaches using the tmux-normalized session target' );
}

{
    my $has_session_calls = 0;
    my $tmux = sub {
        my (%args) = @_;
        my $operation = $args{args}[0];
        return { exit_code => ++$has_session_calls <= 2 ? 1 : 0 } if $operation eq 'has-session';
        return { exit_code => 1, stderr => "duplicate session: ch.docker\n" } if $operation eq 'new-session';
        return { exit_code => 0 };
    };
    like(
        error_from( sub { run_workspace_command( args => ['ch.docker'], tmux => $tmux, attach => sub { return { exit_code => 0 } } ) } ),
        qr/Unable to create tmux ticket session 'ch\.docker': duplicate session/,
        'run_workspace_command reports the duplicate when a successful session recheck still finds no session',
    );
}

{
    my $has_calls = 0;
    my $tmux = sub {
        my (%args) = @_;
        my @argv = @{ $args{args} || [] };
        if ( $argv[0] eq 'has-session' ) {
            $has_calls++;
            return { exit_code => 1 } if $has_calls == 1;
            return { exit_code => 2, stderr => "server unavailable\n" };
        }
        return { exit_code => 1, stderr => "duplicate session: ch.docker\n" }
          if $argv[0] eq 'new-session';
        return { exit_code => 0 };
    };
    my $err = error_from(
        sub {
            run_workspace_command(
                args        => ['ch.docker'],
                tmux        => $tmux,
                resolve_dir => sub { return undef },
                attach      => sub { return { exit_code => 0 } },
            );
        }
    );
    like( $err, qr/Unable to create tmux ticket session 'ch\.docker': duplicate session/,
        'run_workspace_command preserves a duplicate error when the recheck says the session is still absent' );
}

{
    my $has_calls = 0;
    my $tmux = sub {
        my (%args) = @_;
        my @argv = @{ $args{args} || [] };
        if ( $argv[0] eq 'has-session' ) {
            $has_calls++;
            return { exit_code => 1 } if $has_calls == 1;
            return { exit_code => 2, stderr => "server unavailable\n" };
        }
        return { exit_code => 1, stderr => "duplicate session: ch.docker\n" }
          if $argv[0] eq 'new-session';
        return { exit_code => 2, stderr => "server unavailable\n" };
    };
    my $err = error_from(
        sub {
            run_workspace_command(
                args   => ['ch.docker'],
                tmux   => $tmux,
                attach => sub { return { exit_code => 0 } },
            );
        }
    );
    like( $err, qr/duplicate session: ch\.docker.*Session recheck failed: Unable to inspect tmux session 'ch\.docker': server unavailable/s,
        'run_workspace_command reports both the create race and failed confirmation query' );
}

{
    my @attached;
    my $tmux = sub {
        my (%args) = @_;
        my @argv = @{ $args{args} || [] };
        return { exit_code => 0 }
          if $argv[0] eq 'has-session';
        return { exit_code => 0, stdout => "WORKSPACE_REF=ch_docker\n" }
          if $argv[0] eq 'show-environment' && $argv[-1] eq 'WORKSPACE_REF';
        return { exit_code => 0 };
    };
    my $err = error_from(
        sub {
            run_workspace_command(
                args   => ['ch.docker'],
                tmux   => $tmux,
                attach => sub { my (%args) = @_; push @attached, $args{args}; return { exit_code => 0 } },
            );
        }
    );
    like( $err, qr/Tmux session 'ch_docker' belongs to workspace 'ch_docker', not 'ch\.docker'/,
        'run_workspace_command refuses to attach to an unrelated workspace that collides after tmux dot normalization' );
    is( scalar @attached, 0, 'run_workspace_command does not attach after detecting a normalized-name collision' );
}

{
    like(
        error_from( sub { Developer::Dashboard::CLI::Ticket::_verify_workspace_session_identity( tmux_session => 'ch_docker' ) } ),
        qr/Missing workspace name/,
        '_verify_workspace_session_identity requires a logical workspace name',
    );
    like(
        error_from( sub { Developer::Dashboard::CLI::Ticket::_verify_workspace_session_identity( workspace => 'ch.docker' ) } ),
        qr/Missing session name/,
        '_verify_workspace_session_identity requires a normalized tmux session name',
    );

    {
        no warnings 'redefine';
        local *Developer::Dashboard::CLI::Ticket::tmux_command = sub { return { exit_code => 1 }; };
        is(
            Developer::Dashboard::CLI::Ticket::_verify_workspace_session_identity(
                workspace    => 'ch.docker',
                tmux_session => 'ch_docker',
                tmux         => undef,
            ),
            1,
            '_verify_workspace_session_identity accepts tmux absence as the ordinary missing-session result',
        );
    }

    is(
        Developer::Dashboard::CLI::Ticket::_verify_workspace_session_identity(
            workspace    => 'ch.docker',
            tmux_session => 'ch_docker',
            tmux         => tmux_stub( sub { return { exit_code => 0, stdout => "WORKSPACE_REF=ch.docker\n" } } ),
        ),
        1,
        '_verify_workspace_session_identity accepts the matching logical workspace environment',
    );
    is(
        Developer::Dashboard::CLI::Ticket::_verify_workspace_session_identity(
            workspace    => 'ch.docker',
            tmux_session => 'ch_docker',
            tmux         => tmux_stub( sub { return { exit_code => 0, stdout => "WORKSPACE_REF=\n" } } ),
        ),
        1,
        '_verify_workspace_session_identity accepts a present but empty workspace marker as unowned',
    );
    like(
        error_from(
            sub {
                Developer::Dashboard::CLI::Ticket::_verify_workspace_session_identity(
                    workspace    => 'ch.docker',
                    tmux_session => 'ch_docker',
                    tmux         => tmux_stub( sub { return { exit_code => 2, stderr => "query failed\n" } } ),
                );
            }
        ),
        qr/Unable to verify tmux workspace session 'ch_docker': query failed/,
        '_verify_workspace_session_identity reports a tmux query error',
    );
    like(
        error_from(
            sub {
                Developer::Dashboard::CLI::Ticket::_verify_workspace_session_identity(
                    workspace    => 'ch.docker',
                    tmux_session => 'ch_docker',
                    tmux         => tmux_stub( sub { return { exit_code => 2, stderr => '', stdout => 'query output' } } ),
                );
            }
        ),
        qr/Unable to verify tmux workspace session 'ch_docker': query output/,
        '_verify_workspace_session_identity preserves stdout when tmux stderr is empty',
    );
    like(
        error_from(
            sub {
                Developer::Dashboard::CLI::Ticket::_verify_workspace_session_identity(
                    workspace    => 'ch.docker',
                    tmux_session => 'ch_docker',
                    tmux         => tmux_stub( sub { return { exit_code => 2, stderr => 'query stderr', stdout => '' } } ),
                );
            }
        ),
        qr/Unable to verify tmux workspace session 'ch_docker': query stderr/,
        '_verify_workspace_session_identity preserves stderr when tmux stdout is empty',
    );
    is(
        Developer::Dashboard::CLI::Ticket::_verify_workspace_session_identity(
            workspace    => 'ch.docker',
            tmux_session => 'ch_docker',
            tmux         => tmux_stub( sub { return { exit_code => 1 } } ),
        ),
        1,
        '_verify_workspace_session_identity treats exit status one as a missing session',
    );
}

{
    my $tmux = tmux_stub(
        sub {
            my (@argv) = @_;
            return { exit_code => 1 } if $argv[0] eq 'has-session';
            return {};
        }
    );
    my $plan = run_workspace_command( args => ['DD-1'], tmux => $tmux );
    is( $plan->{session}, 'DD-1', 'run_workspace_command returns the plan it executed' );
    is( $plan->{create},  1,      'run_workspace_command creates a session that does not exist yet' );
}

{
    local %ENV = %ENV;
    delete $ENV{WORKSPACE_REF};
    delete $ENV{TICKET_REF};
    my $plan = run_workspace_command( env_workspace => 'DD-2', tmux => ok_tmux() );
    is( $plan->{session}, 'DD-2', 'run_workspace_command resolves the workspace without an argv list' );
}

{
    # The attach is stubbed here and the tmux runner is not, which is the whole
    # point: this case exercises the REAL tmux_command for the queries and the
    # setup, while refusing the one call that would replace this process. Before
    # DD-537 no stub was needed because the attach was captured like every other
    # call; leaving it unstubbed now ends the test file at this line, silently
    # and with a zero exit, because exec succeeds against the PATH tmux stub. A
    # test that hands its process away does not fail - it stops, and the run
    # looks like a pass with a missing plan.
    local $ENV{PATH} = "$fake_bin:$dash_bin";
    my $plan = run_ticket_command( args => ['DD-3'], attach => sub { return { exit_code => 0 } } );
    is( $plan->{session}, 'DD-3', 'run_ticket_command drives the real tmux runner for every call it captures' );
}

{
    my $err = error_from( sub { run_workspace_command( args => [ '-c', 'DD-4' ], tmux => ok_tmux(), resolve_dir => sub { return undef } ) } );
    like( $err, qr/Workspace 'DD-4' is not a registered dashboard path/, 'run_workspace_command refuses -c when the resolver knows nothing about the workspace' );
}

{
    my $err = error_from( sub { run_workspace_command( args => [ '-c', 'DD-5' ], tmux => ok_tmux(), resolve_dir => sub { return '' } ) } );
    like( $err, qr/Workspace 'DD-5' is not a registered dashboard path/, 'run_workspace_command refuses -c when the resolver returns an empty path' );
}

{
    my $err = error_from( sub { run_workspace_command( args => [ '-c', 'dd-ticket-unregistered-workspace' ], tmux => ok_tmux() ) } );
    like(
        $err,
        qr/Workspace 'dd-ticket-unregistered-workspace' is not a registered dashboard path/,
        'run_workspace_command defaults -c to the registered-paths inventory',
    );
}

{
    my $err = error_from( sub { run_workspace_command( args => [ '-c', 'DD-6' ], tmux => ok_tmux(), resolve_dir => sub { return File::Spec->catfile( $ws_dir, '.env' ) } ) } );
    like( $err, qr/which is not a directory/, 'run_workspace_command refuses -c when the resolved path is not a directory' );
}

{
    my $plan = run_workspace_command( args => [ '-c', 'DD-7' ], tmux => ok_tmux(), resolve_dir => sub { return $ws_dir } );
    is( $plan->{cwd}, $ws_dir, 'run_workspace_command changes into the resolved workspace directory before planning the session' );
    chdir $home or die "Unable to chdir to $home: $!";

    my $alias_plan = run_workspace_command( args => ['DD-7A'], tmux => ok_tmux(), resolve_dir => sub { return $ws_dir } );
    is( $alias_plan->{cwd}, $ws_dir, 'run_workspace_command also changes into a resolved path alias without -c' );
    chdir $home or die "Unable to restore cwd after path alias test: $!";
    my $unresolved_plan = run_workspace_command( args => ['DD-7B'], tmux => ok_tmux(), resolve_dir => sub { return undef } );
    ok( $unresolved_plan->{cwd}, 'run_workspace_command keeps the normal cwd when the workspace is not a path alias' );

    my $blocked_dir = File::Spec->catdir( $home, 'blocked-workspace-directory' );
    make_path($blocked_dir);
    SKIP: {
        chmod 0000, $blocked_dir or skip 'chmod not honored on this filesystem', 2;
        if ( opendir my $probe, $blocked_dir ) {
            closedir $probe or die "Unable to close permission probe for $blocked_dir: $!";
            chmod 0700, $blocked_dir or die "Unable to restore permissions on $blocked_dir: $!";
            skip 'running root can still access a mode-0000 directory', 2;
        }
        my $chdir_error = error_from( sub {
            run_workspace_command( args => ['DD-7C'], tmux => ok_tmux(), resolve_dir => sub { return $blocked_dir } );
        } );
        like( $chdir_error, qr/Unable to change directory to .*blocked-workspace-directory.*for workspace path alias 'DD-7C'/,
            'run_workspace_command reports a real chdir failure for an inaccessible directory' );
        $chdir_error = error_from( sub {
            run_workspace_command( args => [ '-c', 'DD-7D' ], tmux => ok_tmux(), resolve_dir => sub { return $blocked_dir } );
        } );
        like( $chdir_error, qr/Unable to change directory to .*blocked-workspace-directory.*for workspace 'DD-7D'/,
            'run_workspace_command reports a real chdir failure for an inaccessible -c target' );
        chmod 0700, $blocked_dir or die "Unable to restore permissions on $blocked_dir: $!";
    }
    my $file_error = error_from( sub {
        run_workspace_command( args => ['DD-7E'], tmux => ok_tmux(), resolve_dir => sub { return File::Spec->catfile( $ws_dir, '.env' ) } );
    } );
    like( $file_error, qr/Workspace path alias 'DD-7E' resolves to .*which is not a directory/,
        'run_workspace_command refuses a non-directory path alias without -c' );
}

{
    my $tmux = tmux_stub(
        sub {
            my (@argv) = @_;
            return { exit_code => 1 } if $argv[0] eq 'has-session';
            return { exit_code => 1, stderr => "create refused\n", stdout => "create detail\n" } if $argv[0] eq 'new-session';
            return {};
        }
    );
    my $err = error_from( sub { run_workspace_command( args => ['DD-8'], tmux => $tmux ) } );
    like( $err, qr/Unable to create tmux ticket session 'DD-8': create refused/, 'run_workspace_command reports tmux stderr when session creation fails' );
    like( $err, qr/create detail/, 'run_workspace_command also reports tmux stdout when session creation fails' );
}

{
    my $tmux = tmux_stub(
        sub {
            my (@argv) = @_;
            return { exit_code => 1 } if $argv[0] eq 'has-session';
            return { exit_code => 1 } if $argv[0] eq 'new-session';
            return {};
        }
    );
    my $err = error_from( sub { run_workspace_command( args => ['DD-9'], tmux => $tmux ) } );
    like( $err, qr/Unable to create tmux ticket session 'DD-9'/, 'run_workspace_command still fails loudly when a refused creation says nothing at all' );
}

{
    my $tmux = tmux_stub(
        sub {
            my (@argv) = @_;
            return { exit_code => 1, stderr => "attach refused\n", stdout => "attach detail\n" } if $argv[0] eq 'attach-session';
            return {};
        }
    );
    my $err = error_from( sub { run_ticket_command( args => ['DD-10'], tmux => $tmux ) } );
    like( $err, qr/Unable to attach tmux ticket session 'DD-10': attach refused/, 'run_ticket_command reports tmux stderr when attaching fails' );
    like( $err, qr/attach detail/, 'run_ticket_command also reports tmux stdout when attaching fails' );
}

{
    my $tmux = tmux_stub(
        sub {
            my (@argv) = @_;
            return { exit_code => 1 } if $argv[0] eq 'attach-session';
            return {};
        }
    );
    my $err = error_from( sub { run_ticket_command( args => ['DD-11'], tmux => $tmux ) } );
    like( $err, qr/Unable to attach tmux ticket session 'DD-11'/, 'run_ticket_command still fails loudly when a refused attach says nothing at all' );
}

# DD-537: attaching is a handoff, not a captured command.
#
# Every other tmux call this module makes is a query whose output is read. The
# attach is the last thing the command does, it is interactive, and it lasts as
# long as the session. Running it through the capturing runner funnelled a
# full-screen terminal application through Capture::Tiny and left the perl
# process parked underneath it for the life of the session doing nothing but
# waiting for an exit code. It execs now, so tmux inherits the terminal and the
# perl process is gone rather than idle.
#
# The RESOLUTION is a named sub precisely so it can be tested. The exec itself
# cannot be: it replaces the process image, so Devel::Cover never gets to write
# what it observed, and a forked child that execs successfully takes its
# coverage with it. That one line is annotated uncoverable, exactly as the same
# handoff is in SkillDispatcher and PageRuntime.
{
    my $explicit = sub { return { exit_code => 0 } };
    my $runner   = sub { return { exit_code => 0 } };

    is( resolve_attach_runner( attach => $explicit, tmux => $runner ),
        $explicit, 'an explicit attach runner wins, so a test can observe the handoff' );

    is( resolve_attach_runner( tmux => $runner ),
        $runner, 'an injected tmux runner also takes the attach - injecting a runner means nothing real should happen' );

    is( resolve_attach_runner(),
        \&Developer::Dashboard::CLI::Ticket::exec_workspace_attach,
        'with nothing injected the attach execs, replacing this process instead of parenting it' );
}

{
    my @attached;
    my $tmux = tmux_stub( sub { return {} } );
    run_workspace_command(
        args   => ['DD-12'],
        tmux   => $tmux,
        attach => sub { my (%args) = @_; push @attached, $args{args}; return { exit_code => 0 } },
    );
    is_deeply( \@attached, [ [ 'attach-session', '-t', 'DD-12' ] ],
        'run_workspace_command hands the attach argv to the attach runner, not to the capturing runner' );
}

{
    my $tmux = tmux_stub( sub { return {} } );
    my $err  = error_from(
        sub {
            run_workspace_command(
                args   => ['DD-13'],
                tmux   => $tmux,
                attach => sub { return { exit_code => 1, stderr => "refused\n" } },
            );
        }
    );
    like( $err, qr/Unable to attach tmux ticket session 'DD-13': refused/,
        'a refused attach still fails loudly when it comes back through an attach runner' );
}


# exec_workspace_attach's GUARD is reachable even though its handoff is not: it
# rejects a bad argv before reaching exec. Covering it matters because the sub
# was otherwise entirely unexercised, which read as a subroutine nobody calls
# rather than as a handoff nobody can record.
{
    like(
        error_from( sub { Developer::Dashboard::CLI::Ticket::exec_workspace_attach( args => 'not-an-array' ) } ),
        qr/tmux args must be an array reference/,
        'the exec handoff refuses a non-array argv before it hands the process away',
    );
}


{
    # An attach runner that returns nothing at all: the || {} guard exists so a
    # runner which reports nothing is treated as success rather than crashing on
    # an undefined hash.
    my $tmux = tmux_stub( sub { return {} } );
    my $plan = run_workspace_command( args => ['DD-14'], tmux => $tmux, attach => sub { return } );
    is( $plan->{session}, 'DD-14', 'an attach runner that returns nothing is treated as a silent success' );
}

{
    like(
        error_from( sub { Developer::Dashboard::CLI::Ticket::exec_workspace_attach() } ),
        qr/tmux args must be an array reference/,
        'the exec handoff refuses to attach with no arguments at all, rather than execing a bare tmux',
    );
}


{
    # The exec handoff, driven through a FAILING exec - which is how PageRuntime
    # and SkillDispatcher cover their identical handoffs. With no tmux on PATH the
    # exec returns instead of replacing this process, so the statement and the
    # true branch are both recorded, and only a SUCCESSFUL exec stays unreachable.
    local $ENV{PATH} = $empty_bin;

    # Perl warns "Can't exec ..." when exec fails, which is the expected
    # behaviour under test rather than a defect. Suppressed for this block ONLY -
    # the suite-wide no-warnings assertion stays intact, because weakening it
    # would hide every other warning this file exists to catch.
    local $SIG{__WARN__} = sub { return };

    like(
        error_from( sub { Developer::Dashboard::CLI::Ticket::exec_workspace_attach( args => ['attach-session'] ) } ),
        qr/Unable to exec tmux to attach the workspace session/,
        'when the handoff cannot exec at all it says so, rather than failing silently',
    );
}

is_deeply( \@warnings, [], 'no warnings were emitted during the CLI ticket coverage run' )
  or diag( "warnings:\n" . join( '', @warnings ) );

done_testing;

__END__

=pod

=head1 NAME

t/91-cli-ticket-coverage.t - branch and condition coverage closure for the tmux workspace/ticket CLI helper

=head1 PURPOSE

This test is the executable coverage contract for
C<Developer::Dashboard::CLI::Ticket>. It drives every decision point in the
tmux workspace runtime: the C<-c> argv split, the workspace-name resolution
ladder from argv through explicit arguments to the ambient reference
variables, the layered C<.env> chain walk that seeds a session, the dashboard
entrypoint lookup, the session create-versus-attach plan, and every tmux
failure report. Read it to see the concrete inputs that reach each branch and
condition instead of inferring them from the module source.

=head1 WHY IT EXISTS

It exists because this helper is mostly decisions, and almost all of them are
about things going wrong: tmux exiting non-zero, a session environment that
cannot be read back, a workspace name that no layer registers, a status option
the server refuses. Those paths never run in a healthy session, so they rot
silently unless a test pins them. This file supplies a stubbed tmux runner and
a stubbed PATH so each refusal, each fallback, and each empty-string edge is
exercised deliberately, keeping the module at full branch and condition
coverage.

=head1 WHEN TO USE

Use this file when changing how the helper picks a workspace name, what tmux
environment variables a session is seeded with, how concurrent duplicate
session creation is handled, how the top status row is
composed, how C<-c> resolves a registered directory, or how tmux failures are
reported back to the user. It also pins path-alias chdir failures for both the
ordinary and C<-c> forms - and whenever the coverage gate reports an
uncovered branch or condition in the ticket helper. Skill aliases are checked
at root, nested, and deeper skill levels; a public CLI subprocess with a fake
tmux verifies the actual C<workspace -c> handoff.

=head1 HOW TO USE

Run C<prove -lv t/91-cli-ticket-coverage.t> while iterating, then keep it green
under C<prove -lr t> and under the Devel::Cover run before release. The test is
hermetic: it roots HOME at a temporary directory and moves the process into
it. A public-entrypoint subprocess invokes C<bin/d2> with a fake C<tmux>, so
C<workspace -c> is verified through the short command without contacting a
real tmux server. A race fixture makes the initial existence query miss a
session, returns tmux's duplicate-session error on creation, and confirms the
second query controls whether attachment proceeds; an unconfirmed duplicate
and a failed confirmation query remain visible errors.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, and the coverage gates
all rely on this file to keep the ticket helper's decision points exercised and
its failure modes explicit.

=head1 EXAMPLES

Example 1:

  prove -lv t/91-cli-ticket-coverage.t

Run the focused ticket-helper coverage test by itself.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/91-cli-ticket-coverage.t

Exercise the same test while collecting coverage for the ticket helper.

Example 3:

  prove -lr t

Run it inside the whole repository suite before calling the work finished.

=cut
