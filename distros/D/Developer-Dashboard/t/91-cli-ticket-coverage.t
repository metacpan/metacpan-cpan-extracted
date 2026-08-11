#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

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
    is_deeply( $create_plan->{attach_argv}, [ 'attach-session', '-t', 'DD-3' ], 'build_ticket_plan builds the attach argv for the resolved session' );
    is( $create_plan->{create_argv}[0], 'new-session', 'build_ticket_plan builds a detached new-session argv' );
}

# --- run_workspace_command / run_ticket_command -----------------------------

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
    local $ENV{PATH} = "$fake_bin:$dash_bin";
    my $plan = run_ticket_command( args => ['DD-3'] );
    is( $plan->{session}, 'DD-3', 'run_ticket_command drives the real tmux runner when none is supplied' );
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
environment variables a session is seeded with, how the top status row is
composed, how C<-c> resolves a registered directory, or how tmux failures are
reported back to the user - and whenever the coverage gate reports an
uncovered branch or condition in the ticket helper.

=head1 HOW TO USE

Run C<prove -lv t/91-cli-ticket-coverage.t> while iterating, then keep it green
under C<prove -lr t> and under the Devel::Cover run before release. The test is
hermetic: it roots HOME at a temporary directory, moves the process into it,
and resolves both C<tmux> and C<dashboard> through stub executables it writes
itself, so it never contacts a real tmux server.

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
