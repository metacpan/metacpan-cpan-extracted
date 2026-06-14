#!/usr/bin/env perl

use strict;
use warnings;

use Cwd qw(getcwd);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;
use URI::Escape qw(uri_escape);

use lib 'lib';
use Developer::Dashboard::PageDocument;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::SkillManager;
use Developer::Dashboard::Web::App;

my $original_cwd = getcwd();
local $ENV{HOME} = tempdir( CLEANUP => 1 );
my $test_cwd = tempdir( CLEANUP => 1 );
chdir $test_cwd or die "Unable to chdir to $test_cwd: $!";
my $test_repos = tempdir( CLEANUP => 1 );
my $paths = Developer::Dashboard::PathRegistry->new( home => $ENV{HOME} );
my $manager = Developer::Dashboard::SkillManager->new( paths => $paths );

my $repo = _create_skill_repo('route-skill');
my $install = $manager->install( 'file://' . $repo );
ok( !$install->{error}, 'route skill installs cleanly' ) or diag $install->{error};
my $other_repo = _create_skill_repo( 'other-skill', nav_label => 'Other Skill Nav' );
my $other_install = $manager->install( 'file://' . $other_repo );
ok( !$other_install->{error}, 'second route skill installs cleanly' ) or diag $other_install->{error};

my $store = Developer::Dashboard::PageStore->new( paths => $paths );
$store->save_page(
    Developer::Dashboard::PageDocument->from_instruction(<<'BOOKMARK')
TITLE: Shared Index
:--------------------------------------------------------------------------------:
BOOKMARK: index
:--------------------------------------------------------------------------------:
HTML:
Shared Index
BOOKMARK
);

my $app = Developer::Dashboard::Web::App->new(
    auth     => bless( {}, 'Local::AuthStub' ),
    pages    => $store,
    sessions => bless( {}, 'Local::SessionsStub' ),
    config   => {},
);

my $missing = $app->handle(
    path        => '/app/missing-skill/foo',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $missing->[0], 404, 'missing nested skill routes return 404' );

my $index = $app->handle(
    path        => '/app/route-skill',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $index->[0], 200, 'installed skill index route returns success' );
like( $index->[2], qr/Skill Route Index/, 'installed skill index route renders the skill index bookmark' );
like( $index->[2], qr/Skill Route Nav/, 'installed skill index route renders skill nav fragments' );
like( $index->[2], qr/Other Skill Nav/, 'installed skill index route also renders nav fragments from other installed skills' );
like( $index->[2], qr{href="/app/route-skill/edit" id="view-source-url"}, 'installed skill index render exposes the smart-routed edit link' );

my $index_edit = $app->handle(
    path        => '/app/route-skill/edit',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $index_edit->[0], 200, 'installed skill index edit route returns success' );
like( $index_edit->[2], qr{<form method="post" action="/app/route-skill/edit" id="instruction-form">}, 'installed skill index edit route posts back to the smart-routed edit alias' );
like( $index_edit->[2], qr/Skill Route Index/, 'installed skill index edit route loads the skill index bookmark source' );

my $index_source = $app->handle(
    path        => '/app/route-skill/source',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $index_source->[0], 200, 'installed skill index source route returns success' );
like( $index_source->[2], qr/TITLE: Skill Route Index/, 'installed skill index source route returns the skill source text' );

my $skill_play_instruction = <<'BOOKMARK';
TITLE: Skill Route Index
:--------------------------------------------------------------------------------:
BOOKMARK: index
:--------------------------------------------------------------------------------:
HTML:
Skill Route Index Edited
BOOKMARK
my $index_play = $app->handle(
    path        => '/app/route-skill/edit',
    method      => 'POST',
    body        => 'mode=render&instruction=' . _uri_escape($skill_play_instruction),
    headers     => {
        host           => '127.0.0.1',
        'content-type' => 'application/x-www-form-urlencoded',
    },
    remote_addr => '127.0.0.1',
);
is( $index_play->[0], 200, 'installed skill index play POST returns success' );
like( $index_play->[2], qr/Skill Route Index Edited/, 'installed skill index play POST renders the edited transient skill page' );
like( $index_play->[2], qr{href="/app/route-skill/edit" id="view-source-url"}, 'installed skill index play POST keeps the smart-routed view source link' );

my $render = $app->handle(
    path        => '/app/route-skill/foo',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $render->[0], 200, 'installed skill page route returns success' );
like( $render->[2], qr/Skill Route Foo/, 'skill page route renders the requested skill bookmark html' );
like( $render->[2], qr/Skill Route Nav/, 'installed skill page route renders skill nav fragments' );
like( $render->[2], qr/Other Skill Nav/, 'installed skill page route renders nav contributed by other installed skills too' );

my $custom_index = $app->handle(
    path        => '/apps/route-skill/home',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $custom_index->[0], 200, 'custom skill app index route returns success' );
like( $custom_index->[2], qr/Skill Route Index/, 'custom skill app index route renders the skill index bookmark' );

my $custom_page = $app->handle(
    path        => '/apps/route-skill/foo',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $custom_page->[0], 200, 'custom skill app page route returns success' );
like( $custom_page->[2], qr/Skill Route Foo/, 'custom skill app page route renders the requested skill bookmark html' );

{
    no warnings 'redefine';
    local *Developer::Dashboard::SkillDispatcher::resolve_route_segments = sub {
        return {
            skill_name     => 'route-skill',
            route_segments => ['foo'],
            skill_layers   => [],
        };
    };
    my $broken_spec = $app->_skill_app_fallback_response( id => 'route-skill/foo' );
    is( $broken_spec->[0], 404, 'skill route fallback returns 404 when a resolved spec has no concrete skill layers' );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::SkillDispatcher::resolve_route_segments = sub { return; };
    my $missing_nested_spec = $app->_skill_app_fallback_response( id => 'route-skill/foo' );
    is( $missing_nested_spec->[0], 404, 'skill route fallback returns 404 when an installed skill prefix exists but no deeper route resolves' );
}

{
    no warnings 'redefine';
    my $loaded_route_id = '';
    local *Developer::Dashboard::Web::App::_resolve_skill_route_spec = sub {
        return {
            skill_name     => 'route-skill',
            route_segments => [],
            skill_layers   => ['layer'],
        };
    };
    local *Developer::Dashboard::Web::App::_skill_dispatcher = sub { bless {}, 'Local::SkillDispatcherProbe' };
    local *Local::SkillDispatcherProbe::_load_skill_page = sub {
        my ( $self, %args ) = @_;
        $loaded_route_id = $args{route_id};
        return Developer::Dashboard::PageDocument->new(
            id    => 'route-skill',
            title => 'Skill Route Index',
            meta  => { source_kind => 'skill' },
        );
    };
    my $empty_route_page = $app->_load_skill_named_page('route-skill');
    is( $loaded_route_id, 'index', 'empty smart route specs load the skill index bookmark id' );
    isa_ok( $empty_route_page, 'Developer::Dashboard::PageDocument', 'empty smart route specs still return a page document' );
    is( $empty_route_page->{meta}{render_route}, '/app/route-skill', 'empty smart route specs keep the canonical smart-routed render alias' );
}

{
    no warnings 'redefine';
    my $loaded_route_id = '';
    local *Developer::Dashboard::Web::App::_resolve_skill_route_spec = sub {
        return {
            skill_name   => 'route-skill',
            skill_layers => ['layer'],
        };
    };
    local *Developer::Dashboard::Web::App::_skill_dispatcher = sub { bless {}, 'Local::SkillDispatcherProbeMissingSegments' };
    local *Local::SkillDispatcherProbeMissingSegments::_load_skill_page = sub {
        my ( $self, %args ) = @_;
        $loaded_route_id = $args{route_id};
        return Developer::Dashboard::PageDocument->new(
            id    => 'route-skill',
            title => 'Skill Route Index',
            meta  => { source_kind => 'skill' },
        );
    };
    my $missing_segments_page = $app->_load_skill_named_page('route-skill');
    is( $loaded_route_id, 'index', 'missing smart route segments default to the skill index bookmark id' );
    isa_ok( $missing_segments_page, 'Developer::Dashboard::PageDocument', 'missing smart route segments still return a page document' );
    is( $missing_segments_page->{meta}{render_route}, '/app/route-skill', 'missing smart route segments keep the canonical smart-routed render alias' );
}

my $ajax_page = $app->handle(
    path        => '/app/route-skill/ajax-demo',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $ajax_page->[0], 200, 'skill ajax demo page route returns success' );
like( $ajax_page->[2], qr{set_chain_value\(endpoints,'bar','/v1/route-skill/bar'\)}, 'skill page binds saved ajax helper to the canonical custom skill route' );

my $skill_alias_ajax = $app->handle(
    path        => '/v1/route-skill/bar',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $skill_alias_ajax->[0], 200, 'custom skill ajax alias route returns success' );
is( $skill_alias_ajax->[1], 'application/json; charset=utf-8', 'custom skill ajax alias route applies its default json content type' );
is( _drain_stream_body( $skill_alias_ajax->[2] ), qq|{"route":"bar"}\n|, 'custom skill ajax alias route streams the skill handler output' );

my $raw_mime_ajax = $app->handle(
    path        => '/v1/route-skill/raw',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $raw_mime_ajax->[0], 200, 'custom skill ajax route with a raw mime type returns success' );
is( $raw_mime_ajax->[1], 'application/vnd.route+json', 'custom skill ajax route keeps an arbitrary configured mime type' );
is( _drain_stream_body( $raw_mime_ajax->[2] ), qq|{"route":"raw"}\n|, 'custom skill ajax route with a raw mime type streams the skill handler output' );

my $skill_ajax = $app->handle(
    path        => '/ajax/route-skill/bar',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $skill_ajax->[0], 200, 'legacy smart skill ajax route still returns success' );
is( _drain_stream_body( $skill_ajax->[2] ), qq|{"route":"bar"}\n|, 'legacy smart skill ajax route still streams the skill handler output' );

my $custom_js = $app->handle(
    path        => '/assets/route-skill.js',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $custom_js->[0], 200, 'custom skill js route returns success' );
is( $custom_js->[2], qq{console.log("route-skill js");\n}, 'custom skill js route serves the skill asset' );

my $skill_js = $app->handle(
    path        => '/js/route-skill/skill.js',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $skill_js->[0], 200, 'skill-local js route returns success' );
is( $skill_js->[2], qq{console.log("route-skill js");\n}, 'skill-local js route serves the skill asset' );

my $skill_css = $app->handle(
    path        => '/css/route-skill/skill.css',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $skill_css->[0], 200, 'skill-local css route returns success' );
is( $skill_css->[2], qq{body { color: #123456; }\n}, 'skill-local css route serves the skill asset' );

my $custom_css = $app->handle(
    path        => '/assets/route-skill.css',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $custom_css->[0], 200, 'custom skill css route returns success' );
is( $custom_css->[2], qq{body { color: #123456; }\n}, 'custom skill css route serves the skill asset' );

my $skill_other = $app->handle(
    path        => '/others/route-skill/info.txt',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $skill_other->[0], 200, 'skill-local others route returns success' );
is( $skill_other->[2], "route-skill info\n", 'skill-local others route serves the skill asset' );

my $custom_other = $app->handle(
    path        => '/downloads/route-skill.txt',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $custom_other->[0], 200, 'custom skill others route returns success' );
is( $custom_other->[1], 'text/plain; charset=utf-8', 'custom skill others route applies an explicit configured mime type' );
is( $custom_other->[2], "route-skill info\n", 'custom skill others route serves the skill asset' );

my $nested_index = $app->handle(
    path        => '/app/route-skill/def',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $nested_index->[0], 200, 'nested skill index route returns success' );
like( $nested_index->[2], qr/Nested Skill Index/, 'nested skill index route renders the nested skill bookmark' );
like( $nested_index->[2], qr/Nested Skill Nav/, 'nested skill index route renders nav fragments contributed by the nested skill' );
like( $nested_index->[2], qr{href="/app/route-skill/def/edit" id="view-source-url"}, 'nested skill index render exposes the smart-routed edit link' );

my $nested_index_edit = $app->handle(
    path        => '/app/route-skill/def/edit',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $nested_index_edit->[0], 200, 'nested skill index edit route returns success' );
like( $nested_index_edit->[2], qr{<form method="post" action="/app/route-skill/def/edit" id="instruction-form">}, 'nested skill index edit route posts back to the nested smart-routed edit alias' );
like( $nested_index_edit->[2], qr/Nested Skill Index/, 'nested skill index edit route loads the nested skill index bookmark source' );

my $nested_page = $app->handle(
    path        => '/app/route-skill/def/foo',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $nested_page->[0], 200, 'nested skill page route returns success' );
like( $nested_page->[2], qr/Nested Skill Foo/, 'nested skill page route renders the nested skill bookmark' );
like( $nested_page->[2], qr/Nested Skill Nav/, 'nested skill page route renders nav fragments contributed by the nested skill' );

my $nested_custom_page = $app->handle(
    path        => '/apps/route-skill/child/foo',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $nested_custom_page->[0], 200, 'nested custom skill app route returns success' );
like( $nested_custom_page->[2], qr/Nested Skill Foo/, 'nested custom skill app route renders the nested skill bookmark' );

my $nested_ajax_page = $app->handle(
    path        => '/app/route-skill/def/ajax-demo',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $nested_ajax_page->[0], 200, 'nested skill ajax demo page route returns success' );
like( $nested_ajax_page->[2], qr{set_chain_value\(endpoints,'nested','/v1/route-skill/nested'\)}, 'nested skill page binds saved ajax helper to the nested canonical custom route' );

my $nested_alias_ajax = $app->handle(
    path        => '/v1/route-skill/nested',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $nested_alias_ajax->[0], 200, 'nested custom ajax alias route returns success' );
is( $nested_alias_ajax->[1], 'text/html; charset=utf-8', 'nested custom ajax alias route applies its default html content type' );
is( _drain_stream_body( $nested_alias_ajax->[2] ), "<p>nested skill ajax route</p>\n", 'nested custom ajax alias route streams the nested skill handler output' );

my $nested_ajax = $app->handle(
    path        => '/ajax/route-skill/def/nested',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $nested_ajax->[0], 200, 'legacy nested skill-local ajax route still returns success' );
is( _drain_stream_body( $nested_ajax->[2] ), "<p>nested skill ajax route</p>\n", 'legacy nested skill-local ajax route still streams the nested skill handler output' );

my $nested_custom_js = $app->handle(
    path        => '/assets/route-skill-nested.js',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $nested_custom_js->[0], 200, 'nested custom skill js route returns success' );
is( $nested_custom_js->[2], qq{console.log("nested js");\n}, 'nested custom skill js route serves the nested skill asset' );

my $nested_js = $app->handle(
    path        => '/js/route-skill/def/ijk/lmn.js',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $nested_js->[0], 200, 'nested skill-local js route returns success' );
is( $nested_js->[2], qq{console.log("nested js");\n}, 'nested skill-local js route serves the nested skill asset' );

my $nested_css = $app->handle(
    path        => '/css/route-skill/def/ijk/lmn.css',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $nested_css->[0], 200, 'nested skill-local css route returns success' );
is( $nested_css->[2], qq{body { background: #abcdef; }\n}, 'nested skill-local css route serves the nested skill asset' );

my $nested_custom_css = $app->handle(
    path        => '/assets/route-skill-nested.css',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $nested_custom_css->[0], 200, 'nested custom skill css route returns success' );
is( $nested_custom_css->[2], qq{body { background: #abcdef; }\n}, 'nested custom skill css route serves the nested skill asset' );

my $nested_other = $app->handle(
    path        => '/others/route-skill/def/ijk/lmn.txt',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $nested_other->[0], 200, 'nested skill-local others route returns success' );
is( $nested_other->[2], "nested other asset\n", 'nested skill-local others route serves the nested skill asset' );

my $nested_custom_other = $app->handle(
    path        => '/downloads/route-skill-nested.txt',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $nested_custom_other->[0], 200, 'nested custom skill others route returns success' );
is( $nested_custom_other->[2], "nested other asset\n", 'nested custom skill others route serves the nested skill asset' );

my $global_public_dir = File::Spec->catdir( $paths->dashboards_root, 'public', 'js', 'route-skill' );
make_path($global_public_dir);
_write_file( File::Spec->catfile( $global_public_dir, 'fallback.js' ), qq{console.log("global fallback");\n}, 0644 );
my $global_prefixed_js = $app->handle(
    path        => '/js/route-skill/fallback.js',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $global_prefixed_js->[0], 200, 'global nested js route still works when the first segment matches a skill name' );
is( $global_prefixed_js->[2], qq{console.log("global fallback");\n}, 'global nested js route falls back to the non-skill asset path' );

my $global_ajax_dir = File::Spec->catdir( $paths->runtime_root, 'dashboards', 'ajax', 'route-skill' );
make_path($global_ajax_dir);
_write_file( File::Spec->catfile( $global_ajax_dir, 'fallback' ), qq{print "global ajax fallback\\n";\n}, 0700 );
my $global_prefixed_ajax = $app->handle(
    path        => '/ajax/route-skill/fallback',
    query       => 'type=text',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $global_prefixed_ajax->[0], 200, 'global nested ajax route still works when the first segment matches a skill name' );
is( _drain_stream_body( $global_prefixed_ajax->[2] ), "global ajax fallback\n", 'global nested ajax route falls back to the non-skill saved ajax file' );

my $shared_index = $app->handle(
    path        => '/app/index',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $shared_index->[0], 200, 'saved non-skill index route returns success' );
like( $shared_index->[2], qr/Shared Index/, 'saved non-skill index route renders the shared saved page body' );
like( $shared_index->[2], qr/Skill Route Nav/, 'saved non-skill index route renders nav from installed skills' );
like( $shared_index->[2], qr/Other Skill Nav/, 'saved non-skill index route renders nav from every installed skill' );
like( $shared_index->[2], qr/Nested Skill Nav/, 'saved non-skill index route also renders nav from nested installed skills' );

my $disable = $manager->disable('other-skill');
ok( !$disable->{error}, 'other-skill disables cleanly for route coverage' ) or diag $disable->{error};

my $disabled_shared_index = $app->handle(
    path        => '/app/index',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $disabled_shared_index->[0], 200, 'shared index still renders after disabling one skill' );
like( $disabled_shared_index->[2], qr/Skill Route Nav/, 'shared index keeps nav from enabled skills after a disable' );
unlike( $disabled_shared_index->[2], qr/Other Skill Nav/, 'shared index drops nav from disabled skills' );

my $disabled_skill = $app->handle(
    path        => '/app/other-skill',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $disabled_skill->[0], 404, 'disabled skill routes are no longer served' );

my $legacy_render = $app->handle(
    path        => '/skill/route-skill/bookmarks/foo',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $legacy_render->[0], 200, 'legacy /skill/<repo>/bookmarks/<id> route still returns success' );
like( $legacy_render->[2], qr/Skill Route Foo/, 'legacy skill bookmark route still renders the requested skill bookmark html' );

my $missing_bookmark = $app->handle(
    path        => '/app/route-skill/missing',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $missing_bookmark->[0], 404, 'missing skill bookmark routes return 404' );

sub _uri_escape {
    my ($text) = @_;
    return uri_escape($text);
}

done_testing();

END {
    chdir $original_cwd if defined $original_cwd && length $original_cwd;
}

sub _create_skill_repo {
    my ( $name, %args ) = @_;
    my $repo = File::Spec->catdir( $test_repos, $name );
    make_path($repo);
    my $cwd = getcwd();
    chdir $repo or die "Unable to chdir to $repo: $!";
    _run_or_die(qw(git init --quiet));
    _run_or_die(qw(git config user.email test@example.com));
    _run_or_die(qw(git config user.name Test));
    make_path('cli');
    make_path('config');
    make_path('dashboards');
    make_path( File::Spec->catdir( 'dashboards', 'ajax' ) );
    make_path( File::Spec->catdir( 'dashboards', 'public', 'js' ) );
    make_path( File::Spec->catdir( 'dashboards', 'public', 'css' ) );
    make_path( File::Spec->catdir( 'dashboards', 'public', 'others' ) );
    _write_file( File::Spec->catfile( 'cli', 'noop' ), "#!/usr/bin/env perl\nprint qq{noop\\n};\n", 0755 );
    _write_file( File::Spec->catfile( 'config', 'config.json' ), qq|{"skill_name":"$name"}\n|, 0644 );
    _write_file(
        File::Spec->catfile( 'dashboards', 'index' ),
        <<'BOOKMARK',
TITLE: Skill Route Index
:--------------------------------------------------------------------------------:
BOOKMARK: index
:--------------------------------------------------------------------------------:
HTML:
Skill Route Index
BOOKMARK
        0644,
    );
    _write_file(
        File::Spec->catfile( 'dashboards', 'foo' ),
        <<'BOOKMARK',
TITLE: Skill Route Foo
:--------------------------------------------------------------------------------:
BOOKMARK: foo
:--------------------------------------------------------------------------------:
HTML:
Skill Route Foo
BOOKMARK
        0644,
    );
    _write_file(
        File::Spec->catfile( 'dashboards', 'ajax-demo' ),
        <<'BOOKMARK',
TITLE: Skill Ajax Demo
:--------------------------------------------------------------------------------:
BOOKMARK: ajax-demo
:--------------------------------------------------------------------------------:
HTML:
<div id="ajax-demo">Ajax Demo</div>
<script>
var endpoints = {};
</script>
:--------------------------------------------------------------------------------:
CODE1: Ajax jvar => 'endpoints.bar', file => 'bar', type => 'json', code => q{
print qq|{"route":"bar"}\n|;
};
BOOKMARK
        0644,
    );
    _write_file(
        File::Spec->catfile( 'config', 'routes.json' ),
        sprintf(
            <<'JSON',
{
   "/apps/%s/home" : "/app/index",
   "/apps/%s/foo" : "/app/foo",
   "/v1/%s/bar" : "/ajax/bar",
   "/v1/%s/raw" : {
      "to" : "/ajax/raw",
      "type" : "application/vnd.route+json"
   },
   "/assets/%s.css" : "/css/skill.css",
   "/assets/%s.js" : "/js/skill.js",
   "/downloads/%s.txt" : {
      "to" : "/others/info.txt",
      "type" : "text/plain; charset=utf-8"
   }
}

JSON
            ($name) x 7,
        ),
        0644,
    );
    _write_file( File::Spec->catfile( 'dashboards', 'ajax', 'bar' ), qq{print qq|{"route":"bar"}\\n|;\n}, 0700 );
    _write_file( File::Spec->catfile( 'dashboards', 'ajax', 'raw' ), qq{print qq|{"route":"raw"}\\n|;\n}, 0700 );
    _write_file( File::Spec->catfile( 'dashboards', 'public', 'js', 'skill.js' ), qq{console.log("$name js");\n}, 0644 );
    _write_file( File::Spec->catfile( 'dashboards', 'public', 'css', 'skill.css' ), qq{body { color: #123456; }\n}, 0644 );
    _write_file( File::Spec->catfile( 'dashboards', 'public', 'others', 'info.txt' ), "$name info\n", 0644 );
    make_path( File::Spec->catdir( 'skills', 'def', 'dashboards', 'ajax' ) );
    make_path( File::Spec->catdir( 'skills', 'def', 'dashboards', 'nav' ) );
    make_path( File::Spec->catdir( 'skills', 'def', 'dashboards', 'public', 'js', 'ijk' ) );
    make_path( File::Spec->catdir( 'skills', 'def', 'dashboards', 'public', 'css', 'ijk' ) );
    make_path( File::Spec->catdir( 'skills', 'def', 'dashboards', 'public', 'others', 'ijk' ) );
    make_path( File::Spec->catdir( 'skills', 'def', 'config' ) );
    _write_file(
        File::Spec->catfile( 'skills', 'def', 'dashboards', 'index' ),
        <<'BOOKMARK',
TITLE: Nested Skill Index
:--------------------------------------------------------------------------------:
BOOKMARK: index
:--------------------------------------------------------------------------------:
HTML:
Nested Skill Index
BOOKMARK
        0644,
    );
    _write_file(
        File::Spec->catfile( 'skills', 'def', 'dashboards', 'foo' ),
        <<'BOOKMARK',
TITLE: Nested Skill Foo
:--------------------------------------------------------------------------------:
BOOKMARK: foo
:--------------------------------------------------------------------------------:
HTML:
Nested Skill Foo
BOOKMARK
        0644,
    );
    _write_file(
        File::Spec->catfile( 'skills', 'def', 'dashboards', 'ajax-demo' ),
        <<'BOOKMARK',
TITLE: Nested Skill Ajax Demo
:--------------------------------------------------------------------------------:
BOOKMARK: ajax-demo
:--------------------------------------------------------------------------------:
HTML:
<div id="nested-ajax-demo">Nested Ajax Demo</div>
<script>
var endpoints = {};
</script>
:--------------------------------------------------------------------------------:
CODE1: Ajax jvar => 'endpoints.nested', file => 'nested', code => q{
print "<p>nested skill ajax route</p>\n";
};
BOOKMARK
        0644,
    );
    _write_file(
        File::Spec->catfile( 'skills', 'def', 'config', 'routes.json' ),
        sprintf(
            <<'JSON',
{
   "/apps/%s/child/foo" : "/app/foo",
   "/v1/%s/nested" : {
      "to" : "/ajax/nested",
      "type" : "html"
   },
   "/assets/%s-nested.css" : "/css/ijk/lmn.css",
   "/assets/%s-nested.js" : "/js/ijk/lmn.js",
   "/downloads/%s-nested.txt" : "/others/ijk/lmn.txt"
}
JSON
            ($name) x 5,
        ),
        0644,
    );
    _write_file( File::Spec->catfile( 'skills', 'def', 'dashboards', 'ajax', 'nested' ), qq{print "<p>nested skill ajax route</p>\\n";\n}, 0700 );
    _write_file( File::Spec->catfile( 'skills', 'def', 'dashboards', 'nav', 'index.tt' ), "<div>Nested Skill Nav</div>\n", 0644 );
    _write_file( File::Spec->catfile( 'skills', 'def', 'dashboards', 'public', 'js', 'ijk', 'lmn.js' ), qq{console.log("nested js");\n}, 0644 );
    _write_file( File::Spec->catfile( 'skills', 'def', 'dashboards', 'public', 'css', 'ijk', 'lmn.css' ), qq{body { background: #abcdef; }\n}, 0644 );
    _write_file( File::Spec->catfile( 'skills', 'def', 'dashboards', 'public', 'others', 'ijk', 'lmn.txt' ), "nested other asset\n", 0644 );
    make_path( File::Spec->catdir( 'dashboards', 'nav' ) );
    _write_file(
        File::Spec->catfile( 'dashboards', 'nav', 'skill.tt' ),
        '<div>' . ( $args{nav_label} || 'Skill Route Nav' ) . "</div>\n",
        0644,
    );
    _run_or_die(qw(git add .));
    _run_or_die( 'git', 'commit', '-m', 'Initial route skill' );
    chdir $cwd or die "Unable to chdir back to $cwd: $!";
    return $repo;
}

sub _write_file {
    my ( $path, $content, $mode ) = @_;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $content;
    close $fh;
    chmod $mode, $path or die "Unable to chmod $path: $!";
    return 1;
}

sub _run_or_die {
    my (@command) = @_;
    system(@command) == 0 or die "Command failed: @command";
    return 1;
}

sub _drain_stream_body {
    my ($body) = @_;
    return $body if ref($body) ne 'HASH' || ref( $body->{stream} ) ne 'CODE';
    my $output = '';
    $body->{stream}->( sub { $output .= $_[0] if defined $_[0] } );
    return $output;
}

package Local::AuthStub;
sub trust_tier { return 'admin' }
sub helper_users_enabled { return 1 }

package Local::SessionsStub;

__END__

=pod

=head1 NAME

t/20-skill-web-routes.t - test isolated skill bookmark routes

=head1 License

This test is part of Developer Dashboard.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for the isolated skill installation and routing stack. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because the isolated skill installation and routing stack has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing the isolated skill installation and routing stack, when a focused CI failure points here, or when you want a faster regression loop than running the entire suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/20-skill-web-routes.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. 

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/20-skill-web-routes.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/20-skill-web-routes.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
