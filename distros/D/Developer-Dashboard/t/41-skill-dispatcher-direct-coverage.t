#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use File::Spec;
use File::Path qw(make_path);
use File::Temp qw(tempdir);

use lib 'lib';

BEGIN {
    package Local::ExecShim;

    our $MODE = 'real';

    sub exec {
        if ( $MODE eq 'fail' ) {
            $! = 2;
            return 0;
        }
        CORE::exec(@_);
    }

    package main;

    no warnings 'redefine';
    *CORE::GLOBAL::exec = \&Local::ExecShim::exec;
}

use Developer::Dashboard::SkillDispatcher;

{
    package Local::SkillPaths;

    sub new {
        my ( $class, %args ) = @_;
        return bless \%args, $class;
    }

    sub home {
        return $_[0]{home};
    }

    sub skill_layers {
        my ( $self, $skill_name ) = @_;
        return @{ $self->{layers}{$skill_name} || [] };
    }

    sub installed_skill_roots {
        my ($self) = @_;
        return @{ $self->{installed} || [] };
    }

    sub config_layers {
        my ($self) = @_;
        return @{ $self->{config_layers} || [] };
    }
}

{
    package Local::SkillManager;

    sub new {
        my ( $class, %args ) = @_;
        return bless \%args, $class;
    }

    sub get_skill_path {
        my ( $self, $skill_name ) = @_;
        my @layers = $self->{paths}->skill_layers($skill_name);
        return $layers[-1];
    }

    sub is_enabled {
        return 1;
    }
}

my $root = tempdir( CLEANUP => 1 );
my $base_skill = File::Spec->catdir( $root, 'base-skill' );
my $leaf_skill = File::Spec->catdir( $root, 'leaf-skill' );
my $solo_skill = File::Spec->catdir( $root, 'solo-skill' );
my $alias_skill = File::Spec->catdir( $root, 'alias-skill' );
my $nested_skill = File::Spec->catdir( $leaf_skill, 'skills', 'child' );
my $runtime_home_config = File::Spec->catdir( $root, 'runtime-home', 'config' );
my $runtime_leaf_config = File::Spec->catdir( $root, 'runtime-leaf', 'config' );

for my $dir (
    File::Spec->catdir( $base_skill, 'dashboards', 'nav' ),
    File::Spec->catdir( $base_skill, 'dashboards', 'ajax' ),
    File::Spec->catdir( $base_skill, 'dashboards', 'public', 'others' ),
    File::Spec->catdir( $leaf_skill, 'dashboards', 'nav' ),
    File::Spec->catdir( $leaf_skill, 'dashboards', 'ajax' ),
    File::Spec->catdir( $leaf_skill, 'dashboards', 'public', 'js' ),
    File::Spec->catdir( $base_skill, 'config' ),
    File::Spec->catdir( $nested_skill, 'dashboards', 'nav' ),
    File::Spec->catdir( $nested_skill, 'dashboards', 'ajax' ),
    File::Spec->catdir( $nested_skill, 'dashboards', 'nav', 'group' ),
    File::Spec->catdir( $nested_skill, 'dashboards', 'public', 'css', 'group' ),
    File::Spec->catdir( $leaf_skill, 'config' ),
    File::Spec->catdir( $nested_skill, 'config' ),
    File::Spec->catdir( $solo_skill, 'config' ),
    File::Spec->catdir( $solo_skill, 'dashboards', 'nav' ),
    File::Spec->catdir( $alias_skill, 'config' ),
    $runtime_home_config,
    $runtime_leaf_config,
)
{
    make_path($dir);
}

_write_file(
    File::Spec->catfile( $runtime_home_config, 'routes.json' ),
    <<'EOF'
{
   "app" : {
      "learn.ai" : {
         "path" : "/java-home",
         "aliases" : ["/java-alias"]
      }
   }
}
EOF
);

_write_file(
    File::Spec->catfile( $runtime_leaf_config, 'routes.json' ),
    <<'EOF'
{
   "/java" : "/app/learn.ai",
   "/runtime/status" : {
      "to" : "/ajax/runtime/status",
      "type" : "text"
   },
   "/runtime/main.js" : "/js/site/main.js",
   "/runtime/main.css" : "/css/site/main.css",
   "/runtime/page.txt" : "/others/docs/page.txt"
}
EOF
);

_write_file(
    File::Spec->catfile( $base_skill, 'dashboards', 'index' ),
    <<'EOF'
TITLE: Base Index
:--------------------------------------------------------------------------------:
BOOKMARK: index
:--------------------------------------------------------------------------------:
HTML:
base index
EOF
);
_write_file(
    File::Spec->catfile( $leaf_skill, 'dashboards', 'index' ),
    <<'EOF'
TITLE: Leaf Index
:--------------------------------------------------------------------------------:
BOOKMARK: index
:--------------------------------------------------------------------------------:
HTML:
leaf index
EOF
);
_write_file(
    File::Spec->catfile( $base_skill, 'dashboards', 'welcome' ),
    <<'EOF'
TITLE: Welcome
:--------------------------------------------------------------------------------:
BOOKMARK: welcome
:--------------------------------------------------------------------------------:
HTML:
welcome
EOF
);
_write_file(
    File::Spec->catfile( $base_skill, 'dashboards', 'ajax', 'base-only' ),
    qq{print "base-only\\n";\n},
);
_write_file(
    File::Spec->catfile( $base_skill, 'dashboards', 'nav', 'base.tt' ),
    "<div>base nav</div>\n",
);
_write_file(
    File::Spec->catfile( $base_skill, 'dashboards', 'public', 'others', 'base.txt' ),
    "base static\n",
);
_write_file(
    File::Spec->catfile( $base_skill, 'config', 'routes.json' ),
    <<'EOF'
{
   "/apps/layered/welcome" : "/app/welcome",
   "/v1/layered/base-only" : {
      "to" : "/ajax/base-only",
      "type" : "text/plain"
   },
   "/v1/layered/shared-base" : "/ajax/shared",
   "/downloads/layered/base.txt" : {
      "to" : "/others/base.txt",
      "type" : "text/plain; charset=utf-8"
   }
}
EOF
);
_write_file(
    File::Spec->catfile( $leaf_skill, 'dashboards', 'nav', 'leaf.tt' ),
    "<div>leaf nav</div>\n",
);
_write_file(
    File::Spec->catfile( $leaf_skill, 'dashboards', 'ajax', 'shared' ),
    "print qq({\"shared\":true}\\n);\n",
);
_write_file(
    File::Spec->catfile( $leaf_skill, 'dashboards', 'public', 'js', 'shared.js' ),
    "console.log('shared');\n",
);
_write_file(
    File::Spec->catfile( $leaf_skill, 'config', 'routes.json' ),
    <<'EOF'
{
   "/v1/layered/shared" : "/ajax/shared",
   "/assets/layered/shared.js" : "/js/shared.js"
}
EOF
);
_write_file(
    File::Spec->catfile( $nested_skill, 'dashboards', 'nav', 'index.tt' ),
    "<div>nested nav</div>\n",
);
_write_file(
    File::Spec->catfile( $nested_skill, 'dashboards', 'ajax', 'nested' ),
    qq{print "<p>nested</p>\\n";\n},
);
_write_file(
    File::Spec->catfile( $nested_skill, 'dashboards', 'nav', 'group', 'deep.tt' ),
    "<div>nested deep nav</div>\n",
);
_write_file(
    File::Spec->catfile( $nested_skill, 'dashboards', 'public', 'css', 'group', 'deep.css' ),
    "body { color: #fff; }\n",
);
_write_file(
    File::Spec->catfile( $nested_skill, 'config', 'routes.json' ),
    <<'EOF'
{
   "/apps/layered/child/foo" : "/app/foo",
   "/v1/layered/nested" : {
      "to" : "/ajax/nested",
      "type" : "html"
   },
   "/assets/layered/child/deep.css" : "/css/group/deep.css"
}
EOF
);
_write_file(
    File::Spec->catfile( $leaf_skill, 'config', 'config.json' ),
    qq|{"indicator":{"icon":"leaf"},"collectors":[{"name":"alpha","interval":20}],"providers":[{"id":"main","title":"Leaf"}]}\n|,
);
_write_file(
    File::Spec->catfile( $solo_skill, 'dashboards', 'nav', 'solo.tt' ),
    "<div>solo nav</div>\n",
);
_write_file(
    File::Spec->catfile( $solo_skill, 'config', 'routes.json' ),
    <<'EOF'
{
   "version" : 1
}
EOF
);
_write_file(
    File::Spec->catfile( $alias_skill, 'config', 'routes.json' ),
    <<'EOF'
{
   "version" : 1,
   "ajax" : {
      "legacy-alias" : {
         "path" : "/v1/alias/canonical",
         "aliases" : ["/v1/alias/alt"],
         "type" : "text/plain"
      }
   }
}
EOF
);

my $paths = Local::SkillPaths->new(
    home      => $root,
    config_layers => [ $runtime_home_config, $runtime_leaf_config ],
    layers    => {
        layered   => [ $base_skill, $leaf_skill ],
        alias     => [$alias_skill],
        'alias-skill' => [$alias_skill],
        'leaf-skill' => [$leaf_skill],
        'solo-skill' => [$solo_skill],
        solo      => [$solo_skill],
    },
    installed => [ $leaf_skill, $solo_skill, $alias_skill ],
);
my $manager = Local::SkillManager->new( paths => $paths );
my $dispatcher = Developer::Dashboard::SkillDispatcher->new( manager => $manager );

is_deeply(
    $dispatcher->resolve_custom_route_path('/java'),
    {
        aliases     => [],
        kind        => 'app',
        path        => '/java',
        route_id    => 'learn.ai',
        source_file => File::Spec->catfile( $runtime_leaf_config, 'routes.json' ),
        target      => 'learn.ai',
        type        => undef,
    },
    'resolve_custom_route_path also resolves runtime config app aliases for saved bookmark ids that include dots',
);

is_deeply(
    $dispatcher->resolve_custom_route_path('/java-alias'),
    {
        aliases     => ['/java-alias'],
        kind        => 'app',
        path        => '/java-home',
        route_id    => 'learn.ai',
        source_file => File::Spec->catfile( $runtime_home_config, 'routes.json' ),
        target      => 'learn.ai',
        type        => undef,
    },
    'resolve_custom_route_path also matches runtime app aliases declared through the typed schema',
);

is_deeply(
    $dispatcher->resolve_custom_route_path('/runtime/status'),
    {
        ajax_file   => 'runtime/status',
        aliases     => [],
        kind        => 'ajax',
        path        => '/runtime/status',
        source_file => File::Spec->catfile( $runtime_leaf_config, 'routes.json' ),
        target      => 'runtime/status',
        type        => 'text',
    },
    'resolve_custom_route_path also resolves runtime config ajax aliases',
);

is_deeply(
    $dispatcher->resolve_custom_route_path('/runtime/main.js'),
    {
        aliases     => [],
        file        => 'site/main.js',
        kind        => 'js',
        path        => '/runtime/main.js',
        source_file => File::Spec->catfile( $runtime_leaf_config, 'routes.json' ),
        target      => 'site/main.js',
        type        => undef,
    },
    'resolve_custom_route_path also resolves runtime config js aliases',
);

is_deeply(
    $dispatcher->resolve_custom_route_path('/runtime/main.css'),
    {
        aliases     => [],
        file        => 'site/main.css',
        kind        => 'css',
        path        => '/runtime/main.css',
        source_file => File::Spec->catfile( $runtime_leaf_config, 'routes.json' ),
        target      => 'site/main.css',
        type        => undef,
    },
    'resolve_custom_route_path also resolves runtime config css aliases',
);

is_deeply(
    $dispatcher->resolve_custom_route_path('/runtime/page.txt'),
    {
        aliases     => [],
        file        => 'docs/page.txt',
        kind        => 'others',
        path        => '/runtime/page.txt',
        source_file => File::Spec->catfile( $runtime_leaf_config, 'routes.json' ),
        target      => 'docs/page.txt',
        type        => undef,
    },
    'resolve_custom_route_path also resolves runtime config other-file aliases',
);

is_deeply(
    [ $dispatcher->_skill_layers('layered') ],
    [ $base_skill, $leaf_skill ],
    '_skill_layers returns every participating skill layer in inheritance order',
);

is_deeply(
    [ $dispatcher->_skill_lookup_roots('layered') ],
    [ $leaf_skill, $base_skill ],
    '_skill_lookup_roots reverses skill layers into effective lookup order',
);

my ( $leaf_index, $leaf_owner ) = $dispatcher->_page_location( 'layered', 'index' );
is( $leaf_index, File::Spec->catfile( $leaf_skill, 'dashboards', 'index' ), '_page_location prefers the deepest layered dashboard file' );
is( $leaf_owner, $leaf_skill, '_page_location reports the skill layer that served the dashboard file' );

my ( $base_welcome, $base_owner ) = $dispatcher->_page_location( 'layered', 'welcome' );
is( $base_welcome, File::Spec->catfile( $base_skill, 'dashboards', 'welcome' ), '_page_location falls back to inherited dashboard files when the leaf layer has none' );
is( $base_owner, $base_skill, '_page_location reports the inherited layer when falling back' );

is_deeply(
    [ $dispatcher->_skill_bookmark_entries('layered') ],
    [ 'index', 'welcome' ],
    '_skill_bookmark_entries lists layered bookmark files without nav entries',
);

is_deeply(
    $dispatcher->_skill_ajax_routes_for('solo'),
    {},
    '_skill_ajax_routes_for treats routes.json without an ajax key as an empty ajax route map',
);

is_deeply(
    { $dispatcher->_skill_nav_route_ids('layered') },
    {
        'base.tt' => 'nav/base.tt',
        'leaf.tt' => 'nav/leaf.tt',
    },
    '_skill_nav_route_ids exposes layered nav templates as route ids',
);

is_deeply(
    { $dispatcher->_skill_nav_route_ids('layered/child') },
    {
        'group/deep.tt' => 'nav/group/deep.tt',
        'index.tt' => 'nav/index.tt',
    },
    '_skill_nav_route_ids resolves nav templates for nested installed skills',
);

my $bookmark_page = $dispatcher->_load_skill_page(
    skill_name => 'layered',
    route_id   => 'index',
);
is( $bookmark_page->{id}, 'layered', '_load_skill_page namespaces index bookmark ids under the skill name' );
is( $bookmark_page->{meta}{skill_path}, $leaf_skill, '_load_skill_page records the leaf skill path for the serving bookmark' );

my $nav_page = $dispatcher->_load_skill_page(
    skill_name => 'layered',
    route_id   => 'nav/leaf.tt',
);
is( $nav_page->{id}, 'layered/nav/leaf.tt', '_load_skill_page namespaces raw nav templates under the skill route id' );
is( $nav_page->{meta}{source_format}, 'raw-nav-tt', '_load_skill_page wraps raw nav templates in a synthetic page document' );

_write_file(
    File::Spec->catfile( $leaf_skill, 'dashboards', 'broken' ),
    "this is not a dashboard instruction\n",
);
{
    no warnings qw(redefine once);
    require Developer::Dashboard::PageDocument;
    local *Developer::Dashboard::PageDocument::from_instruction = sub { die "parse failure\n" };
    my $error = eval {
        $dispatcher->_load_skill_page(
            skill_name => 'layered',
            route_id   => 'broken',
        );
        1;
    };
    ok( !$error, '_load_skill_page dies when a non-nav bookmark cannot be parsed' );
    like( $@, qr/parse failure/, '_load_skill_page surfaces the parser failure for non-nav bookmark files' );
}

my $skill_nav_pages = $dispatcher->skill_nav_pages('layered');
is( scalar @{$skill_nav_pages}, 2, 'skill_nav_pages loads every layered nav template page' );

my $all_nav_pages = $dispatcher->all_skill_nav_pages;
ok( scalar @{$all_nav_pages} >= 2, 'all_skill_nav_pages aggregates nav pages from every installed skill' );
ok(
    scalar( grep { ( $_->{meta}{skill_name} || '' ) eq 'leaf-skill/child' } @{$all_nav_pages} ),
    'all_skill_nav_pages includes nav pages from nested installed skills',
);
ok(
    scalar( grep { ( $_->{meta}{skill_route_id} || '' ) eq 'nav/group/deep.tt' } @{$all_nav_pages} ),
    'all_skill_nav_pages keeps recursively discovered nested nav fragment paths',
);

my $raw_response = $dispatcher->_skill_page_response(
    skill_name => 'layered',
    route_id   => 'index',
);
is( $raw_response->[0], 200, '_skill_page_response returns 200 for a resolvable skill page without a web app' );
like( $raw_response->[2], qr/Leaf Index/, '_skill_page_response returns the raw bookmark instruction when no app renderer is supplied' );

my $bookmark_response = $dispatcher->route_response(
    skill_name => 'layered',
    route      => 'bookmarks',
);
is( $bookmark_response->[0], 200, 'route_response serves the legacy bookmarks listing route' );
like( $bookmark_response->[2], qr/welcome/, 'route_response includes inherited bookmarks in the compatibility listing payload' );

my $index_response = $dispatcher->route_response(
    skill_name => 'layered',
    route      => '',
);
is( $index_response->[0], 200, 'route_response defaults an empty skill route to the skill index page' );

is(
    $dispatcher->route_response( skill_name => 'missing', route => '' )->[0],
    404,
    'route_response rejects unknown skills',
);

is_deeply(
    $dispatcher->config_fragment('layered'),
    {
        _layered => {
            indicator  => { icon => 'leaf' },
            collectors => [ { name => 'alpha', interval => 20 } ],
            providers  => [ { id => 'main', title => 'Leaf' } ],
        },
    },
    'config_fragment wraps merged layered skill config under the underscored skill key',
);

is_deeply(
    $dispatcher->_merge_skill_hashes(
        {
            indicator  => { icon => 'base', status => 'ok' },
            collectors => [ { name => 'alpha', interval => 10 } ],
            providers  => [ { id => 'main', title => 'Base' } ],
        },
        {
            indicator  => { status => 'warn' },
            collectors => [ { name => 'alpha', interval => 20 }, { name => 'beta', interval => 30 } ],
            providers  => [ { id => 'main', title => 'Leaf' }, { id => 'extra', title => 'Extra' } ],
        },
    ),
    {
        indicator  => { icon => 'base', status => 'warn' },
        collectors => [
            { name => 'alpha', interval => 20 },
            { name => 'beta',  interval => 30 },
        ],
        providers => [
            { id => 'main',  title => 'Leaf' },
            { id => 'extra', title => 'Extra' },
        ],
    },
    '_merge_skill_hashes recursively merges hashes and routes layered collector/provider arrays through identity-aware replacement',
);

is_deeply(
    $dispatcher->_arrayref_or_empty(undef),
    [],
    '_arrayref_or_empty falls back to an empty array reference when no array ref is supplied',
);

is_deeply(
    $dispatcher->_hashref_or_empty(undef),
    {},
    '_hashref_or_empty falls back to an empty hash reference when no hash ref is supplied',
);

is(
    $dispatcher->_defined_or_default( undef, 'fallback' ),
    'fallback',
    '_defined_or_default returns the fallback scalar when the candidate value is undef',
);

is_deeply(
    $dispatcher->skill_route_spec( 'app', 'layered', 'welcome' ),
    {
        aliases     => [],
        kind        => 'app',
        path        => '/apps/layered/welcome',
        route_id    => 'welcome',
        skill_name  => 'layered',
        source_file => File::Spec->catfile( $base_skill, 'config', 'routes.json' ),
        target      => 'welcome',
        type        => undef,
    },
    'skill_route_spec resolves app route metadata from inherited layers',
);

is_deeply(
    $dispatcher->skill_ajax_route_spec( 'layered', 'shared' ),
    {
        ajax_file   => 'shared',
        aliases     => [],
        kind        => 'ajax',
        path        => '/v1/layered/shared',
        skill_name  => 'layered',
        source_file => File::Spec->catfile( $leaf_skill, 'config', 'routes.json' ),
        target      => 'shared',
        type        => 'json',
    },
    'skill_ajax_route_spec prefers the deepest layered routes.json entry for one ajax file',
);

is_deeply(
    $dispatcher->skill_ajax_route_spec( 'layered', 'base-only' ),
    {
        ajax_file   => 'base-only',
        aliases     => [],
        kind        => 'ajax',
        path        => '/v1/layered/base-only',
        skill_name  => 'layered',
        source_file => File::Spec->catfile( $base_skill, 'config', 'routes.json' ),
        target      => 'base-only',
        type        => 'text/plain',
    },
    'skill_ajax_route_spec falls back to inherited routes.json entries when the leaf layer has none',
);

is_deeply(
    $dispatcher->skill_route_spec( 'js', 'layered', 'shared.js' ),
    {
        aliases     => [],
        file        => 'shared.js',
        kind        => 'js',
        path        => '/assets/layered/shared.js',
        skill_name  => 'layered',
        source_file => File::Spec->catfile( $leaf_skill, 'config', 'routes.json' ),
        target      => 'shared.js',
        type        => undef,
    },
    'skill_route_spec resolves static js route metadata',
);

is_deeply(
    $dispatcher->resolve_custom_route_path('/v1/layered/shared'),
    {
        ajax_file   => 'shared',
        aliases     => [],
        kind        => 'ajax',
        path        => '/v1/layered/shared',
        skill_name  => 'leaf-skill',
        source_file => File::Spec->catfile( $leaf_skill, 'config', 'routes.json' ),
        target      => 'shared',
        type        => 'json',
    },
    'resolve_custom_route_path returns the canonical custom route spec for a top-level skill ajax handler',
);

my $legacy_alias_spec = $dispatcher->resolve_custom_route_path('/v1/alias/alt');
ok( $legacy_alias_spec, 'resolve_custom_route_path also resolves legacy typed alias routes' );
is( $legacy_alias_spec->{kind}, 'ajax', 'legacy typed alias route keeps the ajax kind' );
is( $legacy_alias_spec->{skill_name}, 'alias-skill', 'legacy typed alias route keeps the owning skill name' );
is( $legacy_alias_spec->{ajax_file}, 'legacy-alias', 'legacy typed alias route keeps the ajax target' );
is( $legacy_alias_spec->{path}, '/v1/alias/canonical', 'legacy typed alias route keeps the canonical path' );
is_deeply( $legacy_alias_spec->{aliases}, ['/v1/alias/alt'], 'legacy typed alias route keeps the declared aliases' );

is_deeply(
    $dispatcher->resolve_custom_route_path('/v1/layered/nested'),
    {
        ajax_file   => 'nested',
        aliases     => [],
        kind        => 'ajax',
        path        => '/v1/layered/nested',
        skill_name  => 'leaf-skill/child',
        source_file => File::Spec->catfile( $nested_skill, 'config', 'routes.json' ),
        target      => 'nested',
        type        => 'html',
    },
    'resolve_custom_route_path also resolves nested skill ajax custom entries',
);

is_deeply(
    $dispatcher->resolve_ajax_route_path('/v1/layered/shared'),
    {
        ajax_file   => 'shared',
        aliases     => [],
        kind        => 'ajax',
        path        => '/v1/layered/shared',
        skill_name  => 'leaf-skill',
        source_file => File::Spec->catfile( $leaf_skill, 'config', 'routes.json' ),
        target      => 'shared',
        type        => 'json',
    },
    'resolve_ajax_route_path keeps the ajax-specific compatibility wrapper working for flat custom routes',
);

is(
    $dispatcher->resolve_ajax_route_path('/apps/layered/child/foo'),
    undef,
    'resolve_ajax_route_path rejects non-ajax custom routes',
);

is_deeply(
    $dispatcher->resolve_custom_route_path('/apps/layered/child/foo'),
    {
        aliases     => [],
        kind        => 'app',
        path        => '/apps/layered/child/foo',
        route_id    => 'foo',
        skill_name  => 'leaf-skill/child',
        source_file => File::Spec->catfile( $nested_skill, 'config', 'routes.json' ),
        target      => 'foo',
        type        => undef,
    },
    'resolve_custom_route_path also resolves nested custom app routes',
);

is_deeply(
    $dispatcher->resolve_custom_route_path('/assets/layered/child/deep.css'),
    {
        aliases     => [],
        file        => 'group/deep.css',
        kind        => 'css',
        path        => '/assets/layered/child/deep.css',
        skill_name  => 'leaf-skill/child',
        source_file => File::Spec->catfile( $nested_skill, 'config', 'routes.json' ),
        target      => 'group/deep.css',
        type        => undef,
    },
    'resolve_custom_route_path also resolves nested static css route entries',
);

is_deeply(
    $dispatcher->_normalize_skill_route_spec(
        kind       => 'ajax',
        skill_name => 'layered',
        target     => 'alias-test',
        routes_file => File::Spec->catfile( $leaf_skill, 'config', 'routes.json' ),
        spec       => {
            path    => '/v1/layered/alias-test',
            aliases => [ undef, '', '/v1/layered/alias-alt' ],
            type    => 'application/json',
        },
    ),
    {
        ajax_file   => 'alias-test',
        aliases     => ['/v1/layered/alias-alt'],
        kind        => 'ajax',
        path        => '/v1/layered/alias-test',
        skill_name  => 'layered',
        source_file => File::Spec->catfile( $leaf_skill, 'config', 'routes.json' ),
        target      => 'alias-test',
        type        => 'application/json',
    },
    '_normalize_skill_route_spec trims blank aliases and preserves explicit ajax types',
);

{
    my $invalid_skill = File::Spec->catdir( $root, 'invalid-skill' );
    make_path( File::Spec->catdir( $invalid_skill, 'dashboards', 'ajax' ) );
    make_path( File::Spec->catdir( $invalid_skill, 'config' ) );
    _write_file(
        File::Spec->catfile( $invalid_skill, 'dashboards', 'ajax', 'broken' ),
        qq{print "broken\\n";\n},
    );
    _write_file(
        File::Spec->catfile( $invalid_skill, 'config', 'routes.json' ),
        <<'EOF'
{
   "v1/not-absolute" : "/ajax/broken"
}
EOF
    );
    my $invalid_paths = Local::SkillPaths->new(
        home      => $root,
        layers    => { invalid => [$invalid_skill] },
        installed => [$invalid_skill],
    );
    my $invalid_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $invalid_paths ),
    );
    my $ok = eval { $invalid_dispatcher->skill_ajax_route_spec( 'invalid', 'broken' ); 1 };
    ok( !$ok, 'invalid routes.json dies explicitly' );
    like( $@, qr/unsupported top-level keys/, 'invalid routes.json surfaces the flat-schema key validation failure' );
}

{
    my $mixed_skill = File::Spec->catdir( $root, 'mixed-skill' );
    make_path( File::Spec->catdir( $mixed_skill, 'config' ) );
    my $mixed_routes = File::Spec->catfile( $mixed_skill, 'config', 'routes.json' );
    _write_file(
        $mixed_routes,
        <<'EOF'
{
   "ajax" : {
      "bar" : { "path" : "/v1/mixed/bar" }
   },
   "/v1/mixed/bar" : "/ajax/bar"
}
EOF
    );
    my $ok = eval { $dispatcher->_load_skill_routes_file($mixed_routes); 1 };
    ok( !$ok, '_load_skill_routes_file rejects mixed flat and typed route schemas' );
    like( $@, qr/must not mix flat custom-path routes with typed route sections/, 'mixed schema failure stays explicit' );
}

{
    my $typed_invalid_skill = File::Spec->catdir( $root, 'typed-invalid-skill' );
    make_path( File::Spec->catdir( $typed_invalid_skill, 'config' ) );
    my $typed_invalid_routes = File::Spec->catfile( $typed_invalid_skill, 'config', 'routes.json' );
    _write_file(
        $typed_invalid_routes,
        <<'EOF'
{
   "ajax" : [ "not-a-hash" ]
}
EOF
    );
    my $ok = eval { $dispatcher->_load_skill_routes_file($typed_invalid_routes); 1 };
    ok( !$ok, '_load_skill_routes_file rejects typed route sections that are not JSON objects' );
    like( $@, qr/ajax must be a JSON object/, 'typed route section validation stays explicit' );
}

{
    my $object_invalid_skill = File::Spec->catdir( $root, 'object-invalid-skill' );
    make_path( File::Spec->catdir( $object_invalid_skill, 'config' ) );
    my $object_invalid_routes = File::Spec->catfile( $object_invalid_skill, 'config', 'routes.json' );
    _write_file(
        $object_invalid_routes,
        <<'EOF'
{
   "/v1/object-invalid" : [ "not-a-string-or-object" ]
}
EOF
    );
    my $ok = eval { $dispatcher->_load_skill_routes_file($object_invalid_routes); 1 };
    ok( !$ok, '_load_skill_routes_file rejects flat route values that are neither strings nor objects' );
    like( $@, qr/must map to a string or JSON object/, 'flat route value validation stays explicit' );
}

{
    my $duplicate_target_skill = File::Spec->catdir( $root, 'duplicate-target-skill' );
    make_path( File::Spec->catdir( $duplicate_target_skill, 'config' ) );
    my $duplicate_target_routes = File::Spec->catfile( $duplicate_target_skill, 'config', 'routes.json' );
    _write_file(
        $duplicate_target_routes,
        <<'EOF'
{
   "/v1/duplicate/one" : "/ajax/shared",
   "/v1/duplicate/two" : "/ajax/shared"
}
EOF
    );
    my $ok = eval { $dispatcher->_load_skill_routes_file($duplicate_target_routes); 1 };
    ok( !$ok, '_load_skill_routes_file rejects duplicate flat routes that claim the same internal target' );
    like( $@, qr/Duplicate ajax route target '\/ajax\/shared'/, 'duplicate flat route target failure stays explicit' );
}

{
    my $ok = eval {
        $dispatcher->_normalize_skill_route_spec(
            kind       => 'ajax',
            skill_name => 'layered',
            target     => 'bad-aliases',
            routes_file => File::Spec->catfile( $leaf_skill, 'config', 'routes.json' ),
            spec       => {
                path    => '/v1/layered/bad-aliases',
                aliases => 'not-an-array',
            },
        );
        1;
    };
    ok( !$ok, '_normalize_skill_route_spec rejects non-array alias metadata' );
    like( $@, qr/aliases must be an array/, 'non-array alias metadata surfaces a direct validation error' );
}

{
    my $ok = eval {
        $dispatcher->_normalize_skill_route_spec(
            kind       => 'ajax',
            skill_name => 'layered',
            target     => 'bad-alias-path',
            routes_file => File::Spec->catfile( $leaf_skill, 'config', 'routes.json' ),
            spec       => {
                path    => '/v1/layered/bad-alias-path',
                aliases => ['relative-alias'],
            },
        );
        1;
    };
    ok( !$ok, '_normalize_skill_route_spec rejects aliases without a leading slash' );
    like( $@, qr/aliases must start with \//, 'alias path validation stays explicit' );
}

{
    local $Local::ExecShim::MODE = 'fail';
    my $error = $dispatcher->_exec_resolved_command(
        '/bin/echo',
        ['/bin/echo'],
        [],
    );
    like( $error->{error}, qr/\AUnable to exec \/bin\/echo:/, '_exec_resolved_command returns an explicit error when exec fails' );
}

done_testing();

sub _write_file {
    my ( $path, $content ) = @_;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $content;
    close $fh;
    return 1;
}

__END__

=pod

=head1 NAME

t/41-skill-dispatcher-direct-coverage.t

=head1 PURPOSE

Exercises layered C<Developer::Dashboard::SkillDispatcher> page, route, and
config helpers directly so the release coverage gate keeps those code paths
measured even when larger integration tests evolve.

=head1 WHY IT EXISTS

This focused file keeps the late-file skill page and bookmark helpers covered
without depending on broader integration tests to touch every layered route
combination.

=head1 WHEN TO USE

Run this test when changing layered skill page lookup, nav route discovery,
bookmark compatibility routes, or the recursive layered config merge logic in
C<Developer::Dashboard::SkillDispatcher>.

=head1 HOW TO USE

Execute it with C<prove -lv t/41-skill-dispatcher-direct-coverage.t> for a
fast direct regression and include it in covered suite runs when checking
release coverage.

=head1 WHAT USES IT

The repo test harness and release coverage gates use this file to lock down
layered skill dispatcher behaviour that sits behind the public
C<dashboard app> and skill route features.

=head1 EXAMPLES

  prove -lv t/41-skill-dispatcher-direct-coverage.t
  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/41-skill-dispatcher-direct-coverage.t

=head1 COVERAGE

This file covers layered skill lookup order, bookmark and nav route loading,
raw skill page responses, config fragments, and layered config merging.

=cut
