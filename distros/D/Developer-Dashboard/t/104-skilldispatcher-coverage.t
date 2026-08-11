#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;
use Cwd qw(abs_path getcwd);

use lib 'lib';

# Intercept the final exec() handoff so exec_command / _exec_replacement can be
# exercised without actually replacing the running test process. The shim only
# fakes a failure for argv whose final element matches $FAIL_RE, leaving hook
# open3 children (which exec other paths) running for real.
BEGIN {
    package Local::ExecShim;
    our $FAIL_RE;
    sub exec {
        my @args = @_;
        if ( defined $FAIL_RE && @args && $args[-1] =~ $FAIL_RE ) {
            $! = 2;
            return 0;
        }
        return CORE::exec(@args);
    }
    package main;
    no warnings 'redefine';
    *CORE::GLOBAL::exec = \&Local::ExecShim::exec;
}

use Developer::Dashboard::SkillDispatcher;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::SkillManager;
use Developer::Dashboard::PageDocument;

# ---- stub path/manager objects for branches unreachable through PathRegistry ----
{
    package Local::StubPaths;
    sub new { my ( $c, %a ) = @_; return bless {%a}, $c; }
    sub home                 { $_[0]{home} }
    sub skill_layers         { my ( $s, $n ) = @_; return @{ $s->{layers}{ $n // '' } || [] }; }
    sub installed_skill_roots { return @{ $_[0]{installed} || [] }; }
    sub config_layers        { return @{ $_[0]{config_layers} || [] }; }

    package Local::PathsNoSkillLayers;    # deliberately lacks skill_layers()
    sub new { my ( $c, %a ) = @_; return bless {%a}, $c; }
    sub home                 { $_[0]{home} }
    sub installed_skill_roots { return @{ $_[0]{installed} || [] }; }
    sub config_layers        { return @{ $_[0]{config_layers} || [] }; }

    package Local::PathsNoConfigLayers;    # deliberately lacks config_layers()
    sub new { my ( $c, %a ) = @_; return bless {%a}, $c; }
    sub home         { $_[0]{home} }
    sub skill_layers { my ( $s, $n ) = @_; return @{ $s->{layers}{ $n // '' } || [] }; }
    sub installed_skill_roots { return @{ $_[0]{installed} || [] }; }

    package Local::StubManager;
    sub new { my ( $c, %a ) = @_; return bless {%a}, $c; }
    sub get_skill_path { my ( $s, $n ) = @_; return $s->{skill_paths}{ $n // '' }; }
    sub is_enabled     { return 1; }

    package Local::StubApp;
    sub new { return bless { runtime => Local::StubRuntime->new }, shift; }
    sub _decorate_skill_page_routes { return $_[1]; }
    sub _page_with_runtime_state    { return $_[1]; }
    sub _page_response              { return [ 200, 'text/html; charset=utf-8', 'stub-render' ]; }

    package Local::StubRuntime;
    sub new { return bless {}, shift; }
    sub prepare_page { my ( $s, %a ) = @_; return $a{page}; }
}

# ---- filesystem helpers ----
sub write_file {
    my ( $path, $content ) = @_;
    make_path( File::Spec->catdir( ( File::Spec->splitpath($path) )[ 0, 1 ] ) )
      if !-d ( File::Spec->splitpath($path) )[1];
    open my $fh, '>', $path or die "write $path: $!";
    print {$fh} $content;
    close $fh;
    return $path;
}

sub write_exec {
    my ( $path, $content ) = @_;
    write_file( $path, $content );
    chmod 0755, $path or die "chmod $path: $!";
    return $path;
}

sub mkd { make_path( $_[0] ); return $_[0]; }

# Run a coderef with STDOUT and STDERR routed to the null device so the
# streaming hook runner's live passthrough does not clutter the harness output.
# The in-process capture is unaffected because it reads the child pipe directly,
# and Test::More writes TAP through its own dup of STDOUT.
sub quietly {
    my ($code) = @_;
    open my $save_out, '>&', \*STDOUT or die "dup STDOUT: $!";
    open my $save_err, '>&', \*STDERR or die "dup STDERR: $!";
    open STDOUT, '>', File::Spec->devnull() or die "silence STDOUT: $!";
    open STDERR, '>', File::Spec->devnull() or die "silence STDERR: $!";
    my @result = eval { $code->() };
    my $err = $@;
    open STDOUT, '>&', $save_out or die "restore STDOUT: $!";
    open STDERR, '>&', $save_err or die "restore STDERR: $!";
    close $save_out;
    close $save_err;
    die $err if $err;
    return wantarray ? @result : $result[0];
}

# ---- hermetic runtime with two inheritance layers (home + project) ----
my $orig_cwd = getcwd();
my $tmp      = tempdir( CLEANUP => 1 );
my $proj_dir = File::Spec->catdir( $tmp, 'project' );
mkd($proj_dir);
chdir $proj_dir or die $!;

my $HOME = abs_path($tmp);
my $PROJ = abs_path($proj_dir);
local $ENV{HOME} = $HOME;

my $home_skills = File::Spec->catdir( $HOME, '.developer-dashboard', 'skills' );
my $proj_skills = File::Spec->catdir( $PROJ, '.developer-dashboard', 'skills' );
my $home_config = File::Spec->catdir( $HOME, '.developer-dashboard', 'config' );
my $proj_config = File::Spec->catdir( $PROJ, '.developer-dashboard', 'config' );

my $home_runner = File::Spec->catdir( $home_skills, 'runner' );
my $proj_runner = File::Spec->catdir( $proj_skills, 'runner' );

# --- home layer of runner: a command provider + a shared nav template ---
write_exec( File::Spec->catfile( $home_runner, 'cli', 'greet' ), "#!/bin/sh\necho greet-home\n" );
write_file( File::Spec->catfile( $home_runner, 'dashboards', 'nav', 'common.tt' ), "home-common\n" );

# --- project (deepest) layer of runner ---
write_exec( File::Spec->catfile( $proj_runner, 'cli', 'greet' ), "#!/bin/sh\necho greet-out\n" );
write_exec( File::Spec->catfile( $proj_runner, 'cli', 'solo' ),  "#!/bin/sh\necho solo-out\n" );
write_exec( File::Spec->catfile( $proj_runner, 'cli', 'exectest' ), "#!/bin/sh\necho exec-out\n" );
# greet hooks: a non-runnable file (skipped) plus two runnable hooks, one of
# which writes to both stdout and stderr.
write_file( File::Spec->catfile( $proj_runner, 'cli', 'greet.d', '00-skip' ), "not runnable\n" );
write_exec( File::Spec->catfile( $proj_runner, 'cli', 'greet.d', '01-run' ), "#!/bin/sh\necho hook1-out\necho hook1-err >&2\n" );
write_exec( File::Spec->catfile( $proj_runner, 'cli', 'greet.d', '02-run' ), "#!/bin/sh\necho hook2-out\n" );
write_exec( File::Spec->catfile( $proj_runner, 'cli', 'exectest.d', '01-h' ), "#!/bin/sh\necho eh-out\n" );

write_file( File::Spec->catfile( $proj_runner, 'config', 'config.json' ),
    qq|{"indicator":{"icon":"leaf"},"collectors":[{"name":"alpha","interval":20}],"providers":[{"id":"main","title":"Leaf"}]}\n| );
write_file( File::Spec->catfile( $proj_runner, 'config', 'routes.json' ), <<'JSON' );
{ "ajax": { "shared": { "path": "/skill/shared", "type": "json", "aliases": ["/skill/shared-alt"] } } }
JSON

write_file( File::Spec->catfile( $proj_runner, 'dashboards', 'index' ), <<'PAGE' );
=== TITLE ===
Runner Index
=== HTML ===
runner index body
PAGE
write_file( File::Spec->catfile( $proj_runner, 'dashboards', 'welcome' ), <<'PAGE' );
=== TITLE ===
Runner Welcome
=== HTML ===
welcome body
PAGE
# A dashboards-level file literally named routes.json (must be filtered out of
# bookmark listings) and a nav template whose body is a Perl-false string.
write_file( File::Spec->catfile( $proj_runner, 'dashboards', 'routes.json' ), "ignored\n" );
write_file( File::Spec->catfile( $proj_runner, 'dashboards', 'nav', 'common.tt' ), "proj-common\n" );
write_file( File::Spec->catfile( $proj_runner, 'dashboards', 'nav', 'zero.tt' ),   "0" );
write_file( File::Spec->catfile( $proj_runner, 'dashboards', 'nav', 'group', 'deep.tt' ), "deep-nav\n" );
write_file( File::Spec->catfile( $proj_runner, 'dashboards', 'ajax', 'foo' ), "print qq({});\n" );
write_file( File::Spec->catfile( $proj_runner, 'dashboards', 'public', 'js', 'app.js' ), "console.log(1);\n" );

# nested + disabled-nested skills under runner
write_exec( File::Spec->catfile( $proj_runner, 'skills', 'child', 'cli', 'sub' ), "#!/bin/sh\necho child-sub\n" );
write_file( File::Spec->catfile( $proj_runner, 'skills', 'child', 'dashboards', 'nav', 'n.tt' ), "child-nav\n" );
mkd( File::Spec->catdir( $proj_runner, 'skills', 'disabledchild', 'cli' ) );
write_file( File::Spec->catfile( $proj_runner, 'skills', 'disabledchild', '.disabled' ), "" );

# secondary skills in the project layer
mkd( File::Spec->catdir( $proj_skills, 'nocfg' ) );                       # exists, no config/dashboards
write_file( File::Spec->catfile( $proj_skills, 'arrcfg', 'config', 'config.json' ), "[1,2,3]\n" );
write_file( File::Spec->catfile( $proj_skills, 'navonly', 'dashboards', 'nav', 'x.tt' ), "nav-only\n" );
write_file( File::Spec->catfile( $proj_skills, 'disabledskill', '.disabled' ), "" );

# runtime-level (config-layer) custom routes
write_file( File::Spec->catfile( $proj_config, 'routes.json' ), <<'JSON' );
{ "app": { "home": { "path": "/home-page", "aliases": ["/home-alt"] } } }
JSON
mkd($home_config);    # a config layer that has no routes.json (exercises the skip)

my $paths      = Developer::Dashboard::PathRegistry->new( home => $HOME );
my $manager    = Developer::Dashboard::SkillManager->new( paths => $paths );
my $disp       = Developer::Dashboard::SkillDispatcher->new( manager => $manager );
my @runner_layers = $paths->skill_layers('runner');
is( scalar @runner_layers, 2, 'runner resolves across two inheritance layers' );

# ---------------------------------------------------------------------------
# new() without an explicit manager builds a SkillManager from paths.
# ---------------------------------------------------------------------------
my $disp_auto = Developer::Dashboard::SkillDispatcher->new( paths => $paths );
isa_ok( $disp_auto->{manager}, 'Developer::Dashboard::SkillManager', 'new() builds a manager when none supplied' );

# ---------------------------------------------------------------------------
# dispatch(): guards, real hook execution, and last_result handling.
# ---------------------------------------------------------------------------
is( $disp->dispatch( '', 'greet' )->{error},  'Missing skill name',   'dispatch rejects a missing skill name' );
is( $disp->dispatch( 'runner', '' )->{error}, 'Missing command name', 'dispatch rejects a missing command name' );
ok( $disp->dispatch( 'nope', 'greet' )->{error},        'dispatch reports an unknown skill' );
ok( $disp->dispatch( 'runner', 'nosuchcmd' )->{error},  'dispatch reports an unknown command' );
ok( $disp->dispatch( 'disabledskill', 'greet' )->{error}, 'dispatch refuses a disabled skill' );

my $run = $disp->dispatch( 'runner', 'greet', 'ARG' );
like( $run->{stdout}, qr/greet-out/, 'dispatch runs the resolved command and captures stdout' );
like( $run->{stdout}, qr/hook1-out/, 'dispatch prepends hook stdout' );
is( $run->{exit_code}, 0, 'dispatch reports the command exit code' );
ok( exists $run->{hooks}{'01-run'}, 'dispatch returns the hook capture map' );

my $run_solo = $disp->dispatch( 'runner', 'solo' );
like( $run_solo->{stdout}, qr/solo-out/, 'dispatch runs a command that has no hooks (clears last_result)' );

# ---------------------------------------------------------------------------
# exec_command(): guards plus the exec handoff (faked via the shim).
# ---------------------------------------------------------------------------
is( $disp->exec_command( '', 'greet' )->{error},  'Missing skill name',   'exec_command rejects a missing skill name' );
is( $disp->exec_command( 'runner', '' )->{error}, 'Missing command name', 'exec_command rejects a missing command name' );
ok( $disp->exec_command( 'nope', 'greet' )->{error},          'exec_command reports an unknown skill' );
ok( $disp->exec_command( 'runner', 'nosuchcmd' )->{error},    'exec_command reports an unknown command' );
ok( $disp->exec_command( 'disabledskill', 'greet' )->{error}, 'exec_command refuses a disabled skill' );

{
    local %ENV = %ENV;
    local $Local::ExecShim::FAIL_RE = qr{/solo\z};
    my $exec_solo = $disp->exec_command( 'runner', 'solo' );
    like( $exec_solo->{error}, qr/\AUnable to exec /, 'exec_command surfaces the exec failure for a hookless command' );
}
{
    local %ENV = %ENV;
    local $Local::ExecShim::FAIL_RE = qr{/exectest\z};
    my $exec_hooked = quietly( sub { $disp->exec_command( 'runner', 'exectest' ) } );
    like( $exec_hooked->{error}, qr/\AUnable to exec /, 'exec_command runs streaming hooks then reports the exec failure' );
}

# ---------------------------------------------------------------------------
# execute_hooks() and the streaming hook runner directly.
# ---------------------------------------------------------------------------
is_deeply( $disp->execute_hooks( '', 'greet' ),  { hooks => {}, result_state => {} }, 'execute_hooks guards a missing skill name' );
is_deeply( $disp->execute_hooks( 'runner', '' ), { hooks => {}, result_state => {} }, 'execute_hooks guards a missing command name' );
is_deeply( $disp->execute_hooks( 'nope', 'greet' ), { hooks => {}, result_state => {} }, 'execute_hooks guards an unknown skill' );
is_deeply( $disp->execute_hooks( 'disabledskill', 'greet' ), { hooks => {}, result_state => {} }, 'execute_hooks guards a disabled skill' );

my $streamed = quietly( sub { $disp->_execute_hooks_streaming( 'runner', 'greet', \@runner_layers, 'ARG' ) } );
like( $streamed->{hooks}{'01-run'}{stdout}, qr/hook1-out/, 'streaming hook runner captures live stdout' );
like( $streamed->{hooks}{'01-run'}{stderr}, qr/hook1-err/, 'streaming hook runner captures live stderr' );
ok( $streamed->{last_result}, 'streaming hook runner records last_result after a hook runs' );

my $streamed_none = $disp->_execute_hooks_streaming( 'runner', 'solo', \@runner_layers );
ok( !exists $streamed_none->{last_result}, 'streaming hook runner omits last_result when no hook runs' );
is_deeply( $disp->_execute_hooks_streaming( '', 'greet', \@runner_layers ), { hooks => {}, result_state => {} }, 'streaming guards a missing skill name' );
is_deeply( $disp->_execute_hooks_streaming( 'runner', 'greet', [] ), { hooks => {}, result_state => {} }, 'streaming guards empty skill layers' );

my $child = quietly( sub {
    $disp->_run_child_command_streaming(
        command    => [ '/bin/sh', '-c', 'echo direct-out; echo direct-err >&2' ],
        stdin_mode => 'null',
    );
} );
like( $child->{stdout}, qr/direct-out/, 'direct child runner captures stdout and clears last_result when none is supplied' );

# ---------------------------------------------------------------------------
# execute_hooks() where the command has no runnable file but the skill has
# layers: falls back to _skill_layers and returns empty.
# ---------------------------------------------------------------------------
is_deeply( $disp->execute_hooks( 'runner', 'nosuchcmd' ), { hooks => {}, result_state => {} },
    'execute_hooks falls back to skill layers when the command is unresolved' );

# ---------------------------------------------------------------------------
# _exec_resolved_command / _exec_replacement error handoff.
# ---------------------------------------------------------------------------
{
    local $Local::ExecShim::FAIL_RE = qr{/bin/false\z};
    my $res = $disp->_exec_resolved_command( '/bin/false', [ '/bin/false' ], [] );
    like( $res->{error}, qr{\AUnable to exec /bin/false:}, '_exec_resolved_command returns the exec failure' );
}

# ---------------------------------------------------------------------------
# _skill_env() env building, including shared/local perl5 lib inclusion.
# ---------------------------------------------------------------------------
mkd( File::Spec->catdir( $HOME, 'perl5', 'lib', 'perl5' ) );
mkd( File::Spec->catdir( $proj_runner, 'perl5', 'lib', 'perl5' ) );
my %env = $disp->_skill_env(
    skill_name   => 'runner',
    skill_path   => $proj_runner,
    skill_layers => \@runner_layers,
    command      => 'greet',
);
is( $env{DEVELOPER_DASHBOARD_SKILL_NAME}, 'runner', '_skill_env exports the skill name' );
like( $env{PERL5LIB}, qr/\Q$proj_runner\E/, '_skill_env prepends an existing skill-local perl5 lib' );
my %env_min = $disp->_skill_env( skill_path => $proj_runner );
ok( $env_min{PERL5LIB}, '_skill_env works without an explicit skill_layers list' );
{
    my $died = !eval { $disp->_skill_env( skill_name => 'x' ); 1 };
    ok( $died, '_skill_env dies without a skill path' );
}

# ---------------------------------------------------------------------------
# _skill_layers() and nested / disabled resolution.
# ---------------------------------------------------------------------------
is_deeply( [ $disp->_skill_layers('') ], [], '_skill_layers guards an empty skill name' );
is_deeply( [ $disp->_skill_layers('/') ], [], '_skill_layers guards a slash-only skill name' );
is( scalar( $disp->_skill_layers('runner/child') ), 1, '_skill_layers resolves a nested installed skill' );
is_deeply( [ $disp->_skill_layers('runner/disabledchild') ], [], '_skill_layers masks a disabled nested skill' );
is( scalar( $disp->_skill_layers( 'runner/disabledchild', include_disabled => 1 ) ), 1,
    '_skill_layers includes a disabled nested skill when asked' );

# _skill_layers do{} fallback for a paths object lacking skill_layers().
{
    my $good = mkd( File::Spec->catdir( $tmp, 'plainskill' ) );
    my $nsl_mgr = Local::StubManager->new(
        paths       => Local::PathsNoSkillLayers->new( home => $HOME ),
        skill_paths => { good => $good, bad => undef },
    );
    my $nsl_disp = Developer::Dashboard::SkillDispatcher->new( manager => $nsl_mgr );
    is_deeply( [ $nsl_disp->_skill_layers('good') ], [$good], '_skill_layers uses get_skill_path when paths lacks skill_layers' );
    is_deeply( [ $nsl_disp->_skill_layers('bad') ],  [],      '_skill_layers returns empty when the fallback path is missing' );
}

# ---------------------------------------------------------------------------
# resolve_route_segments() and _command_root_specs() edge inputs.
# ---------------------------------------------------------------------------
is( $disp->resolve_route_segments(undef), undef, 'resolve_route_segments guards an undef list' );
is( $disp->resolve_route_segments( [] ),  undef, 'resolve_route_segments guards an empty list' );
my $seg = $disp->resolve_route_segments( [ undef, '', 'runner', 'index' ] );
is( $seg->{skill_name}, 'runner', 'resolve_route_segments finds the installed prefix and skips blanks' );

is_deeply( [ $disp->_command_root_specs(undef) ], [], '_command_root_specs guards an undef list' );
is_deeply( [ $disp->_command_root_specs( [] ) ],  [], '_command_root_specs guards an empty list' );

# ---------------------------------------------------------------------------
# _nested_skill_path() edge inputs.
# ---------------------------------------------------------------------------
is( $disp->_nested_skill_path( '/root', [] ),    '/root', '_nested_skill_path returns the root for empty segments' );
is( $disp->_nested_skill_path( '/root', undef ), '/root', '_nested_skill_path guards an undef segment list' );
like( $disp->_nested_skill_path( '/root', ['a'] ), qr{skills.a\z}, '_nested_skill_path nests under skills/<name>' );

# ---------------------------------------------------------------------------
# _command_spec() / command_spec() / command_path() / command_hook_paths().
# ---------------------------------------------------------------------------
is( $disp->command_spec( '', 'greet' ),  undef, 'command_spec guards a missing skill name' );
is( $disp->command_spec( 'runner', '' ), undef, 'command_spec guards a missing command name' );
ok( $disp->command_spec( 'runner', 'greet' ), 'command_spec resolves a runnable command' );
is( $disp->_command_spec( 'runner', '.' ), undef, '_command_spec guards a dotted command that splits to nothing' );
ok( $disp->_command_spec( 'runner', 'child.sub' ), '_command_spec resolves a nested dotted command' );
is( $disp->_command_spec( 'runner', 'missingchild.sub' ), undef, '_command_spec skips a missing nested provider path' );
is( $disp->command_path( 'runner', '' ), undef, 'command_path guards a missing command name' );
ok( $disp->command_path( 'runner', 'greet' ), 'command_path returns the runnable path' );

is_deeply( [ $disp->command_hook_paths( 'runner', '' ) ], [], 'command_hook_paths guards a missing command name' );
is_deeply( [ $disp->command_hook_paths( '', 'greet' ) ], [], 'command_hook_paths guards a missing skill name' );
is_deeply( [ $disp->command_hook_paths( 'runner', 'nosuchcmd' ) ], [], 'command_hook_paths returns empty for an unresolved command' );
my @hook_paths = $disp->command_hook_paths( 'runner', 'greet' );
is( scalar @hook_paths, 2, 'command_hook_paths lists only the runnable hook files' );

# ---------------------------------------------------------------------------
# _page_location() and page/bookmark loading.
# ---------------------------------------------------------------------------
is( $disp->_page_location( '', 'index' ),    undef, '_page_location guards a missing skill name' );
is( $disp->_page_location( 'runner', '' ),   undef, '_page_location guards a missing route id' );
my ( $idx_file, $idx_owner ) = $disp->_page_location( 'runner', 'index' );
ok( -f $idx_file, '_page_location resolves an existing dashboard file' );

{
    my $died = !eval { $disp->_load_skill_page( route_id => 'index' ); 1 };
    ok( $died, '_load_skill_page dies without a skill name' );
    $died = !eval { $disp->_load_skill_page( skill_name => 'runner' ); 1 };
    ok( $died, '_load_skill_page dies without a route id' );
    $died = !eval { $disp->_load_skill_page( skill_name => 'runner', route_id => 'ghost' ); 1 };
    ok( $died, '_load_skill_page dies when the bookmark file is missing' );
}
my $idx_page = $disp->_load_skill_page( skill_name => 'runner', route_id => 'index' );
is( $idx_page->{id}, 'runner', '_load_skill_page namespaces the index bookmark id' );
my $nav_page = $disp->_load_skill_page( skill_name => 'runner', route_id => 'nav/zero.tt' );
is( $nav_page->{meta}{skill_route_id}, 'nav/zero.tt', '_load_skill_page wraps an unparsable nav template' );

# _load_skill_page dying on a non-nav bookmark (parser failure path).
{
    no warnings qw(redefine once);
    local *Developer::Dashboard::PageDocument::from_instruction = sub { die "parse boom\n" };
    my $died = !eval { $disp->_load_skill_page( skill_name => 'runner', route_id => 'welcome' ); 1 };
    ok( $died, '_load_skill_page surfaces a parser failure for a non-nav bookmark' );
}

# ---------------------------------------------------------------------------
# skill_nav_pages() / all_skill_nav_pages() / _skill_page_response().
# ---------------------------------------------------------------------------
is_deeply( $disp->skill_nav_pages(''), [], 'skill_nav_pages guards a missing skill name' );
ok( scalar @{ $disp->skill_nav_pages('runner') }, 'skill_nav_pages loads nav templates' );
ok( scalar @{ $disp->all_skill_nav_pages },       'all_skill_nav_pages aggregates across installed skills' );

my $raw = $disp->_skill_page_response( skill_name => 'runner', route_id => 'index' );
is( $raw->[0], 200, '_skill_page_response returns a raw page without an app' );
my $zero = $disp->_skill_page_response( skill_name => 'runner', route_id => 'nav/zero.tt' );
is( $zero->[0], 200, '_skill_page_response falls back to canonical_instruction for a false raw body' );
my $missing = $disp->_skill_page_response( skill_name => 'runner', route_id => 'ghost' );
is( $missing->[0], 404, '_skill_page_response returns 404 for a missing page' );

my $app = Local::StubApp->new;
my $with_app = $disp->_skill_page_response(
    skill_name   => 'runner',
    route_id     => 'index',
    app          => $app,
    query_params => { a => 1 },
    body_params  => { b => 2 },
    headers      => { H => 1 },
    path         => '/custom/path',
);
is( $with_app->[0], 200, '_skill_page_response renders through an app with request metadata' );
my $with_app_defaults = $disp->_skill_page_response(
    skill_name => 'runner',
    route_id   => 'index',
    app        => $app,
);
is( $with_app_defaults->[0], 200, '_skill_page_response supplies default params/path when omitted' );

# ---------------------------------------------------------------------------
# route_response().
# ---------------------------------------------------------------------------
is( $disp->route_response( route => 'index' )->[0], 404, 'route_response 404s when the skill name is blank' );
is( $disp->route_response( skill_name => 'nope', route => '' )->[0], 404, 'route_response 404s an unknown skill' );
is( $disp->route_response( skill_name => 'nocfg', route => 'x' )->[0], 404, 'route_response 404s a skill without dashboards' );
is( $disp->route_response( skill_name => 'runner' )->[0], 200, 'route_response defaults an undef route to the index page' );
is( $disp->route_response( skill_name => 'runner', route => 'bookmarks' )->[0], 200, 'route_response serves the bookmark listing' );
is( $disp->route_response( skill_name => 'navonly', route => 'bookmarks' )->[0], 404, 'route_response 404s bookmarks when none exist' );
is( $disp->route_response( skill_name => 'runner', route => 'bookmarks/welcome' )->[0], 200, 'route_response serves a legacy bookmark id' );

# ---------------------------------------------------------------------------
# _skill_bookmark_entries() / _skill_nav_route_ids().
# ---------------------------------------------------------------------------
is_deeply( [ $disp->_skill_bookmark_entries('') ], [], '_skill_bookmark_entries guards a missing skill name' );
my @entries = $disp->_skill_bookmark_entries('runner');
ok( ( grep { $_ eq 'index' } @entries ), '_skill_bookmark_entries lists bookmark files' );
ok( !( grep { $_ eq 'routes.json' } @entries ), '_skill_bookmark_entries filters routes.json' );
is_deeply( [ $disp->_skill_bookmark_entries('nocfg') ], [], '_skill_bookmark_entries returns empty without a dashboards dir' );

is_deeply( { $disp->_skill_nav_route_ids('') }, {}, '_skill_nav_route_ids guards a missing skill name' );
my %nav_ids = $disp->_skill_nav_route_ids('runner');
is( $nav_ids{'common.tt'}, 'nav/common.tt', '_skill_nav_route_ids merges a nav template present in two layers' );

# ---------------------------------------------------------------------------
# get_skill_config() / config_fragment() / get_skill_path().
# ---------------------------------------------------------------------------
is_deeply( $disp->config_fragment(''), {}, 'config_fragment guards a missing skill name' );
is_deeply( $disp->config_fragment('nocfg'), {}, 'config_fragment is empty for a skill with no config' );
ok( $disp->config_fragment('runner')->{_runner}, 'config_fragment wraps a populated skill config' );
is_deeply( $disp->get_skill_config('arrcfg'), {}, 'get_skill_config ignores a non-object config.json' );
ok( $disp->get_skill_path('runner'), 'get_skill_path returns an installed skill path' );

# ---------------------------------------------------------------------------
# custom-route resolution across runtime and skill config layers.
# ---------------------------------------------------------------------------
is( $disp->resolve_custom_route_path(undef), undef, 'resolve_custom_route_path guards an undef path' );
is( $disp->resolve_custom_route_path(''),    undef, 'resolve_custom_route_path guards an empty path' );
is( $disp->resolve_custom_route_path('/home-page')->{route_id}, 'home', 'resolve_custom_route_path matches a runtime route path' );
is( $disp->resolve_custom_route_path('/home-alt')->{route_id},  'home', 'resolve_custom_route_path matches a runtime route alias' );
is( $disp->resolve_custom_route_path('/skill/shared')->{kind},     'ajax', 'resolve_custom_route_path matches an installed skill route path' );
is( $disp->resolve_custom_route_path('/skill/shared-alt')->{kind}, 'ajax', 'resolve_custom_route_path matches an installed skill route alias' );
is( $disp->resolve_custom_route_path('/no/such/route'), undef, 'resolve_custom_route_path returns undef for an unknown path' );

is( $disp->resolve_ajax_route_path('/skill/shared')->{kind}, 'ajax', 'resolve_ajax_route_path returns an ajax spec' );
is( $disp->resolve_ajax_route_path('/home-page'), undef, 'resolve_ajax_route_path rejects a non-ajax route' );
is( $disp->resolve_ajax_route_path('/no/such/route'), undef, 'resolve_ajax_route_path returns undef when no route matches' );

ok( $disp->skill_ajax_route_spec( 'runner', 'shared' ), 'skill_ajax_route_spec resolves a skill ajax route' );
is( $disp->skill_route_spec( '', 'runner', 'shared' ),  undef, 'skill_route_spec guards a missing kind' );
is( $disp->skill_route_spec( 'ajax', '', 'shared' ),    undef, 'skill_route_spec guards a missing skill name' );
is( $disp->skill_route_spec( 'ajax', 'runner', '' ),    undef, 'skill_route_spec guards a missing target' );
is_deeply( $disp->_skill_routes_for( '', 'ajax' ), {}, '_skill_routes_for guards a missing skill name' );
is_deeply( $disp->_skill_routes_for( 'runner', '' ), {}, '_skill_routes_for guards a missing kind' );

# ---------------------------------------------------------------------------
# skill ajax / static file resolution.
# ---------------------------------------------------------------------------
is( $disp->skill_ajax_file_path( '', 'foo' ),  undef, 'skill_ajax_file_path guards a missing skill name' );
is( $disp->skill_ajax_file_path( 'runner', '' ), undef, 'skill_ajax_file_path guards a missing ajax file' );
ok( -f $disp->skill_ajax_file_path( 'runner', 'foo' ), 'skill_ajax_file_path resolves a layered ajax file' );
is( $disp->skill_static_file_path( '', 'js', 'app.js' ), undef, 'skill_static_file_path guards a missing skill name' );
is( $disp->skill_static_file_path( 'runner', '', 'app.js' ), undef, 'skill_static_file_path guards a missing type' );
is( $disp->skill_static_file_path( 'runner', 'js', '' ), undef, 'skill_static_file_path guards a missing file' );
ok( -f $disp->skill_static_file_path( 'runner', 'js', 'app.js' ), 'skill_static_file_path resolves a layered static asset' );

# ---------------------------------------------------------------------------
# DD-416: every layered resolver joins untrusted browser input onto a skill
# root with File::Spec, which does not collapse parent-directory components,
# so each resolver has to reject unsafe segments instead of resolving them.
# ---------------------------------------------------------------------------
is( $disp->_page_location( 'runner', '../../../etc/passwd' ), undef,
    '_page_location rejects a parent-directory route id' );
is( $disp->_page_location( 'runner', 'nav/../../../index' ), undef,
    '_page_location rejects an embedded parent-directory route id' );
is( $disp->_page_location( 'runner', '/etc/passwd' ), undef,
    '_page_location rejects an absolute route id' );
is( $disp->skill_ajax_file_path( 'runner', '../../../foo' ), undef,
    'skill_ajax_file_path rejects a parent-directory ajax file' );
is( $disp->skill_static_file_path( 'runner', 'js', '../../../../app.js' ), undef,
    'skill_static_file_path rejects a parent-directory asset path' );
is( $disp->skill_static_file_path( 'runner', '..', 'app.js' ), undef,
    'skill_static_file_path rejects a parent-directory asset type' );
is( $disp->skill_static_file_path( 'runner', 'js/nested', 'app.js' ), undef,
    'skill_static_file_path rejects a multi-segment asset type' );
is_deeply( [ $disp->_skill_layers('..') ], [],
    '_skill_layers rejects a parent-directory skill name' );
is_deeply( [ $disp->_skill_layers('runner/..') ], [],
    '_skill_layers rejects a parent-directory nested skill segment' );
is_deeply( [ $disp->_skill_layers('runner/./child') ], [],
    '_skill_layers rejects a current-directory nested skill segment' );
is( $disp->resolve_route_segments( [ 'runner', '..', '..', 'passwd' ] )->{skill_name}, 'runner',
    'route resolution stops at the installed skill and leaves traversal segments in the route tail' );

# skill_static_roots exposes the layered public roots the web layer asserts
# containment against before it opens a resolved skill asset.
is_deeply(
    [ $disp->skill_static_roots( 'runner', 'js' ) ],
    [ map { File::Spec->catdir( $_, 'dashboards', 'public', 'js' ) } $disp->_skill_lookup_roots('runner') ],
    'skill_static_roots lists every layered public root in lookup order'
);
is_deeply( [ $disp->skill_static_roots( '', 'js' ) ], [], 'skill_static_roots guards a missing skill name' );
is_deeply( [ $disp->skill_static_roots( 'runner', '' ) ], [], 'skill_static_roots guards a missing asset type' );
is_deeply( [ $disp->skill_static_roots( 'runner', '..' ) ], [], 'skill_static_roots rejects a parent-directory asset type' );

# ---------------------------------------------------------------------------
# _descendant_skill_names() and _relative_files() edge inputs.
# ---------------------------------------------------------------------------
is_deeply( [ $disp->_descendant_skill_names( '', $proj_runner ) ], [], '_descendant_skill_names guards a missing name' );
is_deeply( [ $disp->_descendant_skill_names( 'x', '/no/such/dir' ) ], [], '_descendant_skill_names guards a missing root' );
my @descendants = $disp->_descendant_skill_names( 'runner', $proj_runner );
ok( ( grep { $_ eq 'runner/child' } @descendants ), '_descendant_skill_names includes an enabled nested skill' );
ok( !( grep { $_ eq 'runner/disabledchild' } @descendants ), '_descendant_skill_names skips a disabled nested skill' );

is_deeply( [ $disp->_relative_files('') ], [], '_relative_files guards an empty root' );
is_deeply( [ $disp->_relative_files('/no/such/dir') ], [], '_relative_files guards a missing root' );
{
    my $rroot = mkd( File::Spec->catdir( $tmp, 'relfiles' ) );
    write_file( File::Spec->catfile( $rroot, 'sub', 'leaf.txt' ), "leaf\n" );
    symlink( File::Spec->catfile( $rroot, 'nowhere' ), File::Spec->catfile( $rroot, 'dangling' ) );
    my @rel = $disp->_relative_files($rroot);
    ok( ( grep { $_ eq 'sub/leaf.txt' } @rel ), '_relative_files recurses into subdirectories' );
    ok( !( grep { $_ eq 'dangling' } @rel ), '_relative_files skips a dangling symlink' );
}

# ---------------------------------------------------------------------------
# _all_installed_skill_names() with a slashless installed root (stub paths).
# ---------------------------------------------------------------------------
{
    my $real = mkd( File::Spec->catdir( $tmp, 'names', 'skills', 'realskill' ) );
    my $spaths = Local::StubPaths->new( home => $HOME, installed => [ 'noslash', $real ] );
    my $sdisp  = Developer::Dashboard::SkillDispatcher->new( manager => Local::StubManager->new( paths => $spaths ) );
    my @names  = $sdisp->_all_installed_skill_names;
    is_deeply( \@names, ['realskill'], '_all_installed_skill_names skips a root without a trailing name segment' );
}

# ---------------------------------------------------------------------------
# _runtime_custom_route_specs() guards (paths undef / no config_layers).
# ---------------------------------------------------------------------------
{
    my $no_paths = Developer::Dashboard::SkillDispatcher->new( manager => Local::StubManager->new( paths => undef ) );
    is_deeply( [ $no_paths->_runtime_custom_route_specs ], [], '_runtime_custom_route_specs guards an undef paths object' );
    my $no_cfg = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::StubManager->new( paths => Local::PathsNoConfigLayers->new( home => $HOME ) ) );
    is_deeply( [ $no_cfg->_runtime_custom_route_specs ], [], '_runtime_custom_route_specs guards a paths object without config_layers' );
}

# ---------------------------------------------------------------------------
# _skill_routes_for() duplicate-path detection (isolated stub dispatcher).
# ---------------------------------------------------------------------------
{
    my $dupdir = File::Spec->catdir( $tmp, 'dup' );
    write_file( File::Spec->catfile( $dupdir, 'config', 'routes.json' ),
        '{ "ajax": { "a": { "path": "/dup/x" }, "b": { "path": "/dup/x" } } }' . "\n" );
    my $dpaths = Local::StubPaths->new( home => $HOME, layers => { dup => [$dupdir] } );
    my $ddisp  = Developer::Dashboard::SkillDispatcher->new( manager => Local::StubManager->new( paths => $dpaths ) );
    my $died = !eval { $ddisp->skill_route_spec( 'ajax', 'dup', 'a' ); 1 };
    ok( $died, '_skill_routes_for rejects two targets that claim the same path' );
    like( $@, qr/Duplicate ajax route path/, 'the duplicate-path failure stays explicit' );
}

# ---------------------------------------------------------------------------
# _load_skill_routes_file() schema validation.
# ---------------------------------------------------------------------------
my $scratch = mkd( File::Spec->catdir( $tmp, 'routes' ) );
sub load_routes_dies {
    my ( $name, $json, $re ) = @_;
    my $file = File::Spec->catfile( $scratch, $name );
    write_file( $file, $json );
    my $died = !eval { $disp->_load_skill_routes_file($file); 1 };
    ok( $died, "$name is rejected" );
    like( $@, $re, "$name failure is explicit" ) if $re;
    return;
}
load_routes_dies( 'badjson.json', "{ not json", qr/Invalid JSON/ );
load_routes_dies( 'array.json',   "[1,2,3]\n",  qr/must contain a JSON object/ );
load_routes_dies( 'flatmixed.json', '{ "/good": "/ajax/x", "bad": "/ajax/y" }' . "\n", qr/must use absolute custom-path keys/ );
load_routes_dies( 'ver.json', '{ "version": 2 }' . "\n", qr/version must be 1/ );

my $ok_typed = $disp->_load_skill_routes_file( write_file( File::Spec->catfile( $scratch, 'typed.json' ), '{ "version": 1, "ajax": { "z": { "path": "/z" } } }' . "\n" ) );
is( ref $ok_typed->{app}, 'HASH', '_load_skill_routes_file backfills omitted typed route kinds' );
# version 0 must be rejected too (exercises the ( version || 0 ) default).
{
    write_file( File::Spec->catfile( $scratch, 'zero.json' ), '{ "version": 0 }' . "\n" );
    my $died = !eval { $disp->_load_skill_routes_file( File::Spec->catfile( $scratch, 'zero.json' ) ); 1 };
    ok( $died, 'a zero version is rejected via the (version || 0) default' );
}

# ---------------------------------------------------------------------------
# _expand_flat_skill_routes_payload() validation (direct + via loader).
# ---------------------------------------------------------------------------
{
    my $died = !eval { $disp->_expand_flat_skill_routes_payload( 'x.json', { 'nogood' => '/ajax/y' } ); 1 };
    ok( $died, '_expand_flat rejects a non-absolute route path' );
}
sub flat_dies {
    my ( $name, $json, $re ) = @_;
    my $file = write_file( File::Spec->catfile( $scratch, $name ), $json );
    my $died = !eval { $disp->_load_skill_routes_file($file); 1 };
    ok( $died, "$name is rejected" );
    like( $@, $re, "$name failure is explicit" ) if $re;
    return;
}
flat_dies( 'flatunknown.json', '{ "/x": { "to": "/ajax/y", "bogus": 1 } }' . "\n", qr/unsupported keys/ );
flat_dies( 'flatnoto.json',    '{ "/x": { "type": "json" } }' . "\n", qr/non-empty route target/ );
flat_dies( 'flatrefto.json',   '{ "/x": { "to": ["a"] } }' . "\n", qr/non-empty route target/ );
flat_dies( 'flatemptyto.json', '{ "/x": "" }' . "\n", qr/non-empty route target/ );
flat_dies( 'flatbadkind.json', '{ "/x": "/bogus/y" }' . "\n", qr{must map to /ajax/} );
flat_dies( 'flatnotarget.json', '{ "/x": "/ajax/" }' . "\n", qr/target must not be empty/ );
flat_dies( 'flattyperef.json',  '{ "/x": { "to": "/ajax/y", "type": [1] } }' . "\n", qr/type must be a scalar/ );
flat_dies( 'flattypeempty.json', '{ "/x": { "to": "/ajax/y", "type": "" } }' . "\n", qr/type must not be empty/ );
flat_dies( 'flatapptype.json',  '{ "/x": { "to": "/app/y", "type": "z" } }' . "\n", qr{type for /app} );
flat_dies( 'flatjstype.json',   '{ "/x": { "to": "/js/y", "type": "z" } }' . "\n", qr{type for /js} );
flat_dies( 'flatcsstype.json',  '{ "/x": { "to": "/css/y", "type": "z" } }' . "\n", qr{type for /css} );
my $ok_flat = $disp->_load_skill_routes_file( write_file( File::Spec->catfile( $scratch, 'flatok.json' ), '{ "/a": "/ajax/handler" }' . "\n" ) );
is( $ok_flat->{ajax}{handler}{type}, 'json', '_expand_flat defaults an ajax route type to json' );
# An others route with a type passes every app/js/css type guard without dying.
my $ok_others = $disp->_load_skill_routes_file( write_file( File::Spec->catfile( $scratch, 'flatothers.json' ), '{ "/x": { "to": "/others/y", "type": "z" } }' . "\n" ) );
is( $ok_others->{others}{y}{type}, 'z', '_expand_flat keeps a type on an others route' );

# ---------------------------------------------------------------------------
# _normalize_skill_route_spec() validation.
# ---------------------------------------------------------------------------
my $rf = File::Spec->catfile( $scratch, 'norm.json' );
sub norm_dies {
    my ( $desc, %args ) = @_;
    my $died = !eval { $disp->_normalize_skill_route_spec(%args); 1 };
    ok( $died, $desc );
    return;
}
norm_dies( '_normalize requires a kind',        target => 't', routes_file => $rf, spec => { path => '/p' } );
norm_dies( '_normalize requires a target',      kind => 'ajax', routes_file => $rf, spec => { path => '/p' } );
norm_dies( '_normalize requires a routes_file', kind => 'ajax', target => 't', spec => { path => '/p' } );
norm_dies( '_normalize requires a hash spec',   kind => 'ajax', target => 't', routes_file => $rf, spec => 'scalar' );
norm_dies( '_normalize requires a path',        kind => 'ajax', target => 't', routes_file => $rf, spec => {} );
norm_dies( '_normalize requires an absolute path', kind => 'ajax', target => 't', routes_file => $rf, spec => { path => 'rel' } );
norm_dies( '_normalize rejects a ref type',     kind => 'ajax', target => 't', routes_file => $rf, spec => { path => '/p', type => [1] } );
norm_dies( '_normalize rejects an empty type',  kind => 'ajax', target => 't', routes_file => $rf, spec => { path => '/p', type => '' } );
norm_dies( '_normalize rejects an empty-string path', kind => 'ajax', target => 't', routes_file => $rf, spec => { path => '' } );
norm_dies( '_normalize rejects an explicit undef type', kind => 'ajax', target => 't', routes_file => $rf, spec => { path => '/p', type => undef } );
norm_dies( '_normalize rejects a typed app route', kind => 'app', target => 't', routes_file => $rf, spec => { path => '/p', type => 'x' } );
my $norm_blank = $disp->_normalize_skill_route_spec( kind => 'ajax', skill_name => '', target => 't', routes_file => $rf, spec => { path => '/p' } );
ok( !exists $norm_blank->{skill_name}, '_normalize omits a blank skill name' );

# ---------------------------------------------------------------------------
# _merge_array_items_by_identity() and _merge_skill_hashes().
# ---------------------------------------------------------------------------
my $merged_items = $disp->_merge_array_items_by_identity(
    [ 'scalar1', { name => 'a', v => 1 }, { name => '', x => 1 }, { noname => 1 } ],
    [ 'scalar2', { name => 'a', v => 2 }, { name => 'b' }, { name => '', y => 1 }, { nope => 1 } ],
    'name',
);
is_deeply(
    ( grep { ref eq 'HASH' && ( $_->{name} // '' ) eq 'a' } @{$merged_items} )[0],
    { name => 'a', v => 2 },
    '_merge_array_items_by_identity replaces items sharing an identity and keeps the rest',
);

is_deeply( $disp->_merge_skill_hashes( undef, { a => 1 } ), { a => 1 }, '_merge_skill_hashes defaults a missing left hash' );
is_deeply( $disp->_merge_skill_hashes( { a => 1 }, undef ), { a => 1 }, '_merge_skill_hashes defaults a missing right hash' );
is_deeply(
    $disp->_merge_skill_hashes(
        { deep => { keep => 1 }, arr => [1], mix => { x => 1 }, list => [1] },
        { deep => { add  => 2 }, arr => [2], mix => 'scalar',   list => 'scalar', providers => undef },
    ),
    { deep => { keep => 1, add => 2 }, arr => [2], mix => 'scalar', list => 'scalar', providers => undef },
    '_merge_skill_hashes recurses, replaces plain arrays, and overrides on type mismatch',
);
is_deeply(
    $disp->_merge_skill_hashes(
        { providers => [ { id => 'a', v => 1 } ] },
        { providers => [ { id => 'a', v => 2 }, { id => 'b' } ] },
    ),
    { providers => [ { id => 'a', v => 2 }, { id => 'b' } ] },
    '_merge_skill_hashes merges provider arrays by id',
);

# _arrayref_or_empty / _hashref_or_empty / _defined_or_default already covered
# implicitly, exercise the valid-ref branches explicitly.
is_deeply( $disp->_arrayref_or_empty( [ 1, 2 ] ), [ 1, 2 ], '_arrayref_or_empty passes a real array ref through' );
is_deeply( $disp->_hashref_or_empty( { a => 1 } ), { a => 1 }, '_hashref_or_empty passes a real hash ref through' );
is( $disp->_defined_or_default( 'v', 'd' ), 'v', '_defined_or_default keeps a defined value' );

# ---------------------------------------------------------------------------
# Remaining guard edges reached only through unusual inputs.
# ---------------------------------------------------------------------------
# execute_hooks reaches its empty-skill-layers guard when get_skill_path
# succeeds but the resolver yields no participating layers.
{
    my $edir = mkd( File::Spec->catdir( $tmp, 'emptyskill' ) );
    my $emgr = Local::StubManager->new(
        paths       => Local::StubPaths->new( home => $HOME, layers => { emptyskill => [] } ),
        skill_paths => { emptyskill => $edir },
    );
    my $edisp = Developer::Dashboard::SkillDispatcher->new( manager => $emgr );
    is_deeply(
        $edisp->execute_hooks( 'emptyskill', 'greet' ),
        { hooks => {}, result_state => {} },
        'execute_hooks returns empty when an enabled skill resolves to no layers',
    );
}

# _command_spec guards both operands of its skill/command check directly.
is( $disp->_command_spec( '', 'greet' ),  undef, '_command_spec guards a missing skill name' );
is( $disp->_command_spec( 'runner', '' ), undef, '_command_spec guards a missing command name' );

# _descendant_skill_names with a truthy name but an empty root string.
is_deeply( [ $disp->_descendant_skill_names( 'x', '' ) ], [], '_descendant_skill_names guards an empty root string' );

chdir $orig_cwd or die $!;
done_testing;

__END__

=pod

=head1 NAME

t/104-skilldispatcher-coverage.t - branch and condition coverage for the skill dispatcher

=head1 PURPOSE

This test drives C<Developer::Dashboard::SkillDispatcher> across every command,
hook, bookmark, route, and configuration code path so the release coverage gate
keeps the module at full branch and condition coverage. It builds a two-layer
installed-skill tree on disk, actually executes skill commands and their sorted
hook files, and pushes each helper through its guard clauses and error paths.

=head1 WHY IT EXISTS

The dispatcher owns skill command execution, streaming hook chaining, isolated
environment construction, layered bookmark and nav loading, and custom route
resolution. Earlier direct tests exercised the pure resolver helpers but never
ran a real command or hook, so the execution, streaming, and exec-handoff
branches went unmeasured. This file exists to execute those paths for real and
to reach the failure and guard branches that only trigger on unusual input.

=head1 WHEN TO USE

Use this file when changing dispatch, exec handoff, hook streaming, the skill
environment contract, layered page or bookmark loading, or the custom route and
routes.json schema handling in the skill dispatcher.

=head1 HOW TO USE

Run C<prove -lv t/104-skilldispatcher-coverage.t> while iterating, and run it
under C<HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t> to confirm the
dispatcher stays at full coverage before release.

=head1 WHAT USES IT

The repository test harness and the Devel::Cover release gate use this file to
lock down skill dispatcher behaviour that sits behind dotted
C<dashboard E<lt>repoE<gt>.E<lt>commandE<gt>> dispatch and the skill browser
routes.

=head1 EXAMPLES

Example 1:

  prove -lv t/104-skilldispatcher-coverage.t

Run the dispatcher coverage regression by itself.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Re-check the module under the repository coverage gate.

=cut
