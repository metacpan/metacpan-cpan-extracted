#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use File::Spec;
use File::Path qw(make_path remove_tree);
use File::Temp qw(tempdir);
use Scalar::Util qw(refaddr);
use Time::HiRes qw(sleep);

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

my $watcher_chdir_probe = q{
    use lib 'lib';
    use Developer::Dashboard::SkillDispatcher;
    chdir $ARGV[0] or die "Unable to enter probe directory: $!\n";
    my $dispatcher = bless {}, 'Developer::Dashboard::SkillDispatcher';
    $dispatcher->_skill_nav_pages_watcher;
};
my $watcher_chdir_status = system( $^X, '-e', $watcher_chdir_probe, File::Spec->tmpdir );
is( $watcher_chdir_status, 0,
    'lazy skill-nav watcher loads from the absolute module path after chdir with relative @INC' );

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

    sub runtime_roots {
        my ($self) = @_;
        return @{ $self->{runtime_roots} || [] };
    }

    sub installed_skill_entries {
        my ($self) = @_;
        my @entries;
        for my $root ( @{ $self->{installed} || [] } ) {
            my ($name) = $root =~ m{/([^/]+)\z};
            next if !defined $name;
            push @entries, {
                skill_name => $name,
                skill_root => $root,
                layers     => $self->{layers}{$name} || [$root],
            };
        }
        return @entries;
    }

    sub config_layers {
        my ($self) = @_;
        return @{ $self->{config_layers} || [] };
    }
}

{
    package Local::SkillPathsWithSkillsRoots;

    our @ISA = ('Local::SkillPaths');

    sub skills_roots { return @{ $_[0]{skills_roots} || [] } }
}

{
    package Local::LegacySkillPaths;

    sub new { return bless { installed => $_[1], layers => $_[2] }, $_[0] }
    sub installed_skill_roots { return @{ $_[0]{installed} || [] } }
    sub skill_layers { return @{ $_[0]{layers}{ $_[1] } || [] } }
}

{
    package Local::InvalidSkillEntriesPaths;

    sub new { return bless { entries => $_[1] || [] }, $_[0] }
    sub installed_skill_entries { return @{ $_[0]{entries} } }
}

{
    package Local::Problem48SkillNavWatch;

    sub configure {
        my ( $self, $signature, $paths ) = @_;
        $self->{configure_calls}++;
        if ( defined $self->{configure_error} ) {
            $self->{error} = $self->{configure_error};
            return 0;
        }
        $self->{signature} = $signature;
        $self->{paths} = [ @{$paths} ];
        return 1;
    }

    sub unchanged {
        my ( $self, $signature ) = @_;
        return 0 if !defined $self->{signature} || $self->{signature} ne $signature;
        return 0 if defined $self->{error};
        my $changed = delete $self->{changed};
        return $changed ? 0 : 1;
    }

    sub last_error { return $_[0]{error} }
    sub close { $_[0]{closed}++; return 1 }
}

{
    package Local::Problem48SkillNavWatchCloseFalse;

    sub close { return 0 }
}

{
    package Local::Problem48SkillNavWatchCloseError;

    sub close { die "injected watcher close exception\n" }
}

{
    package Local::Problem48SkillNavWatchLastError;

    sub close { return 0 }
    sub last_error { return 'injected watcher close diagnostic' }
}

{
    package Local::Problem48SkillNavWatchEmptyCloseError;

    sub close { return 0 }
    sub last_error { return '' }
}

{
    package Local::Problem48SkillNavWatchStaleWithoutError;

    sub unchanged { return 0 }
    sub close { return 1 }
}

{
    package Local::Problem48SkillNavWatchStaleCloseFailure;

    sub unchanged { return 0 }
    sub last_error { return 'injected stale watcher failure' }
    sub close { return 0 }
}

{
    package Local::Problem48SkillNavWatchStaleEmptyError;

    sub unchanged { return 0 }
    sub last_error { return '' }
    sub close { return 1 }
}

{
    package Local::Problem48SkillNavWatchStaleEmptyCloseError;

    sub unchanged { return 0 }
    sub last_error { return ++$_[0]{error_calls} == 1 ? 'injected watcher failure' : '' }
    sub close { return 0 }
}

{
    package Local::Problem48SkillNavWatchSetupWithoutDiagnostics;

    sub configure { return 0 }
    sub close { return 0 }
}

{
    package Local::Problem48SkillNavWatchSetupCloseError;

    sub configure { return 0 }
    sub last_error { return 'injected watcher close error' }
    sub close { return 0 }
}

{
    package Local::Problem48SkillNavWatchSetupEmptyError;

    sub configure { return 0 }
    sub last_error { return '' }
    sub close { return 0 }
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
    File::Spec->catfile( $base_skill, 'dashboards', 'nav', 'leaf.tt' ),
    "<div>base duplicate nav</div>\n",
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
my $nested_cli_dir = File::Spec->catdir( $nested_skill, 'cli' );
make_path($nested_cli_dir);
my $nested_bob = File::Spec->catfile( $nested_cli_dir, 'bob' );
_write_file( $nested_bob, "#!/usr/bin/env perl\nprint qq(bob\\n);\n" );
chmod 0755, $nested_bob or die "Unable to chmod $nested_bob: $!";
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

my $nested_command_spec = $dispatcher->command_spec( 'layered', 'child.bob' );
is( $nested_command_spec->{cmd_path}, $nested_bob, 'nested skill command resolves its leaf executable' );
is_deeply(
    $nested_command_spec->{env_skill_layers},
    [ $base_skill, $leaf_skill, File::Spec->catdir( $leaf_skill, 'skills', 'child' ) ],
    'nested skill command inherits environment layers from the parent skill through the nested leaf',
);

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
ok( !defined scalar $dispatcher->_page_location( 'layered', '../outside' ),
    '_page_location rejects an untrusted parent-directory route' );
ok( !defined scalar $dispatcher->_page_location(
        'layered', 'nav/index.tt', layers => [$leaf_skill], validated_route_segments => ['nav', '..', 'index.tt'] ),
    '_page_location rejects unsafe segments even when supplied through its internal fast path' );
my ( $validated_nav_file, $validated_nav_owner ) = $dispatcher->_page_location(
    'layered', 'nav/leaf.tt', layers => [$leaf_skill], validated_route_segments => ['nav', 'leaf.tt']
);
is( $validated_nav_file, File::Spec->catfile( $leaf_skill, 'dashboards', 'nav', 'leaf.tt' ),
    '_page_location accepts safe inventory-derived segments for an existing nav file' );
is( $validated_nav_owner, $leaf_skill,
    '_page_location retains the file owner when safe inventory-derived segments are used' );
for my $case (
    [ 'undefined segment', [ 'nav', undef ] ],
    [ 'reference segment', [ 'nav', [] ] ],
    [ 'empty segment', [ 'nav', '' ] ],
    [ 'current-directory segment', [ 'nav', '.' ] ],
    [ 'slash-containing segment', [ 'nav', 'nested/file.tt' ] ],
    [ 'control-byte segment', [ 'nav', "bad\x01name" ] ],
    [ 'drive-prefixed first segment', ['C:outside'] ],
) {
    my ( $label, $segments ) = @{$case};
    ok( !defined scalar $dispatcher->_page_location(
            'layered', 'nav/leaf.tt', layers => [$leaf_skill], validated_route_segments => $segments ),
        "_page_location rejects $label on its inventory fast path" );
}
ok( !defined scalar $dispatcher->_page_location(
        'layered', 'nav/leaf.tt', layers => [$leaf_skill], validated_route_segments => [] ),
    '_page_location rejects an empty inventory segment list' );
ok( !defined scalar $dispatcher->_page_location(
        'layered', 'nav/leaf.tt', layers => [$leaf_skill], validated_route_segments => 'nav/leaf.tt' ),
    '_page_location rejects a non-array inventory segment value' );

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
is_deeply( { $dispatcher->_skill_nav_route_ids('') }, {},
    '_skill_nav_route_ids returns an empty inventory when the skill name is missing' );

{
    my $inventory_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $paths ),
        paths   => $paths,
    );
    my $original_relative_files = Developer::Dashboard::SkillDispatcher->can('_relative_files');
    my $inventory_scans = 0;
    no warnings qw(redefine once);
    local *Developer::Dashboard::SkillDispatcher::_relative_files = sub {
        $inventory_scans++;
        return $original_relative_files->(@_);
    };
    my %first_inventory = $inventory_dispatcher->_skill_nav_route_ids('layered');
    is( $inventory_scans, 2, 'first layered nav inventory scans each contributing nav root once' );
    my %second_inventory = $inventory_dispatcher->_skill_nav_route_ids('layered');
    is_deeply( \%second_inventory, \%first_inventory, 'repeated nav inventory preserves layered route ids' );
    is( $inventory_scans, 2, 'unchanged layered nav inventory skips repeated recursive directory scans' );

    my $inventory_added_file = File::Spec->catfile( $leaf_skill, 'dashboards', 'nav', 'inventory-added.tt' );
    _write_file( $inventory_added_file, '<div>new route</div>\n' );
    my %updated_inventory = $inventory_dispatcher->_skill_nav_route_ids('layered');
    ok( exists $updated_inventory{'inventory-added.tt'}, 'nav inventory notices a newly added route' );
    is( $inventory_scans, 3, 'changed directory metadata triggers only the affected nav-root rescan' );
    unlink $inventory_added_file or die "Unable to remove inventory nav fixture '$inventory_added_file': $!";
}

{
    my $aggregate_root = File::Spec->catdir( $root, 'aggregate-skill' );
    my $aggregate_nav = File::Spec->catdir( $aggregate_root, 'dashboards', 'nav' );
    make_path($aggregate_nav);
    my $aggregate_page = File::Spec->catfile( $aggregate_nav, 'index.tt' );
    _write_file( $aggregate_page, '<span>first</span>' );
    my $aggregate_paths = Local::SkillPaths->new(
        home      => $root,
        installed => [$aggregate_root],
        layers    => { 'aggregate-skill' => [$aggregate_root] },
    );
    my $aggregate_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $aggregate_paths ),
        paths   => $aggregate_paths,
    );
    require Developer::Dashboard::IndicatorStore::Watch;
    my $watch;
    my $load_count = 0;
    my $original_load = Developer::Dashboard::SkillDispatcher->can('_load_skill_page');
    no warnings qw(redefine once);
    local *Developer::Dashboard::IndicatorStore::Watch::new = sub {
        $watch ||= bless {}, 'Local::Problem48SkillNavWatch';
        return $watch;
    };
    local *Developer::Dashboard::SkillDispatcher::_load_skill_page = sub {
        $load_count++;
        return $original_load->(@_);
    };

    my $first_pages = $aggregate_dispatcher->all_skill_nav_pages;
    is( scalar @{$first_pages}, 1, 'aggregate literal-nav snapshot includes its initial route' );
    is( $first_pages->[0]{layout}{body}, '<span>first</span>', 'aggregate snapshot preserves the literal nav body' );
    my $escape_calls = 0;
    my $first_html = $aggregate_dispatcher->all_skill_nav_literal_items_html(
        sub { $escape_calls++; return $_[0] }
    );
    is( $first_html, '<li data-nav-id="aggregate-skill/nav/index.tt"><span>first</span></li>',
        'aggregate literal nav snapshot renders a reusable list item string' );
    is( $escape_calls, 1, 'initial literal nav HTML escapes each route id once' );
    is_deeply( $aggregate_dispatcher->_skill_nav_paths_signature,
        $aggregate_dispatcher->{_skill_nav_pages_snapshot}{paths_signature},
        'aggregate snapshot retains its current runtime-root identity',
    );
    my $loads_after_first = $load_count;
    my $second_pages = $aggregate_dispatcher->all_skill_nav_pages;
    is( $load_count, $loads_after_first, 'event-free aggregate snapshot skips repeated page path resolution' );
    is( refaddr($second_pages->[0]), refaddr($first_pages->[0]), 'event-free aggregate snapshot reuses the immutable literal page' );
    my $second_html = $aggregate_dispatcher->all_skill_nav_literal_items_html(
        sub { $escape_calls++; return $_[0] }
    );
    is( $second_html, $first_html, 'event-free aggregate snapshot reuses byte-identical rendered nav HTML' );
    is( $escape_calls, 1, 'event-free aggregate snapshot skips repeated route escaping and markup assembly' );

    $aggregate_paths->{runtime_roots} = [$root];
    my $loads_before_root_change = $load_count;
    my $changed_root_pages = $aggregate_dispatcher->all_skill_nav_pages;
    is( scalar @{$changed_root_pages}, 1, 'runtime-layer change still returns the installed literal nav page' );
    ok( $load_count > $loads_before_root_change,
        'runtime-root identity change invalidates the aggregate snapshot before watcher reuse' );

    _write_file( $aggregate_page, '<span>other</span>' );
    $watch->{changed} = 1;
    my $edited_pages = $aggregate_dispatcher->all_skill_nav_pages;
    is( $edited_pages->[0]{layout}{body}, '<span>other</span>', 'watch event reloads an edited literal nav page' );
    my $edited_html = $aggregate_dispatcher->all_skill_nav_literal_items_html(
        sub { $escape_calls++; return $_[0] }
    );
    like( $edited_html, qr{<span>other</span>}, 'watch event invalidates rendered literal nav HTML' );
    unlike( $edited_html, qr{<span>first</span>}, 'rendered nav HTML drops the previous body after an event' );
    ok( $load_count > $loads_after_first, 'watch event re-enters page resolution for a changed source' );

    my $added_page = File::Spec->catfile( $aggregate_nav, 'second.tt' );
    _write_file( $added_page, '<span>added</span>' );
    $watch->{changed} = 1;
    my $added_pages = $aggregate_dispatcher->all_skill_nav_pages;
    is( scalar @{$added_pages}, 2, 'watch event discovers a newly added nav route' );
    unlink $added_page or die "Unable to remove aggregate nav fixture '$added_page': $!";
    $watch->{changed} = 1;
    my $removed_pages = $aggregate_dispatcher->all_skill_nav_pages;
    is( scalar @{$removed_pages}, 1, 'watch event removes a deleted nav route from the aggregate snapshot' );

    my $cached_snapshot = $aggregate_dispatcher->{_skill_nav_pages_snapshot};
    $cached_snapshot->{pages}[0]{meta}{codes} = ['print q{dynamic};'];
    delete $cached_snapshot->{html};
    is(
        $aggregate_dispatcher->all_skill_nav_literal_items_html( sub { return $_[0] } ),
        undef,
        'literal HTML assembly rejects a raw-nav page that carries executable code sections',
    );

    my $coded_nav = Developer::Dashboard::PageDocument->new(
        id     => 'coded-nav',
        title  => 'Coded nav',
        layout => { body => '<span>coded</span>' },
        meta   => { source_format => 'raw-nav-tt', codes => ['print q{dynamic};'] },
    );
    ok(
        !$aggregate_dispatcher->_cache_all_skill_nav_pages(
            [$coded_nav], [$aggregate_root], [$aggregate_root]
        ),
        'aggregate page caching rejects raw-nav pages that carry executable code sections',
    );

    $cached_snapshot->{pages}[0]{meta}{codes} = [];
    delete $cached_snapshot->{html};
    is(
        $aggregate_dispatcher->all_skill_nav_literal_items_html( sub { return $_[0] } ),
        '<li data-nav-id="aggregate-skill/nav/index.tt"><span>other</span></li>',
        'literal HTML assembly accepts an empty code-section array on a static nav fragment',
    );
    my $empty_code_nav = Developer::Dashboard::PageDocument->new(
        id     => 'empty-code-nav',
        title  => 'Empty code nav',
        layout => { body => '<span>empty</span>' },
        meta   => { source_format => 'raw-nav-tt', codes => [] },
    );
    ok(
        $aggregate_dispatcher->_cache_all_skill_nav_pages(
            [$empty_code_nav], [$aggregate_root], [$aggregate_root]
        ),
        'aggregate page caching accepts an empty code-section array on a static nav fragment',
    );

    my $guard_page = Developer::Dashboard::PageDocument->new(
        id     => 'guard-page',
        title  => 'Guard page',
        layout => { body => '<span>guard</span>' },
        meta   => { source_format => 'raw-nav-tt', codes => [] },
    );
    my $guard_pages = [$guard_page];
    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::SkillDispatcher::all_skill_nav_pages = sub { return $guard_pages };
        my $guard_dispatcher = Developer::Dashboard::SkillDispatcher->new(
            manager => Local::SkillManager->new( paths => $aggregate_paths ),
            paths   => $aggregate_paths,
        );
        $guard_dispatcher->{_skill_nav_pages_snapshot} = { pages => $guard_pages };

        $guard_dispatcher->{_skill_nav_pages_snapshot} = [];
        is( $guard_dispatcher->all_skill_nav_literal_items_html( sub { $_[0] } ), undef,
            'literal renderer declines a non-hash aggregate snapshot' );
        $guard_dispatcher->{_skill_nav_pages_snapshot} = { pages => 'not-an-array' };
        is( $guard_dispatcher->all_skill_nav_literal_items_html( sub { $_[0] } ), undef,
            'literal renderer declines a malformed snapshot page list' );
        $guard_dispatcher->{_skill_nav_pages_snapshot} = { pages => [] };
        is( $guard_dispatcher->all_skill_nav_literal_items_html( sub { $_[0] } ), undef,
            'literal renderer declines page lists that do not match the snapshot identity' );
        local *Developer::Dashboard::SkillDispatcher::all_skill_nav_pages = sub {
            return 'not-an-array';
        };
        $guard_dispatcher->{_skill_nav_pages_snapshot} = { pages => $guard_pages };
        is( $guard_dispatcher->all_skill_nav_literal_items_html( sub { $_[0] } ), undef,
            'literal renderer declines a non-array rendered page list' );
        local *Developer::Dashboard::SkillDispatcher::all_skill_nav_pages = sub {
            return $guard_pages;
        };
        $guard_dispatcher->{_skill_nav_pages_snapshot} = { pages => $guard_pages };

        my $error = '';
        eval { $guard_dispatcher->all_skill_nav_literal_items_html('not a callback'); 1 }
          or $error = $@;
        like( $error, qr/attribute escaper must be a code reference/,
            'literal nav renderer rejects a non-code attribute escaper' );

        $guard_dispatcher->{_skill_nav_pages_snapshot}{html} = undef;
        $error = '';
        eval { $guard_dispatcher->all_skill_nav_literal_items_html( sub { $_[0] } ); 1 }
          or $error = $@;
        like( $error, qr/Malformed rendered skill-nav HTML cache/,
            'literal nav renderer rejects an undefined rendered HTML cache' );
        $guard_dispatcher->{_skill_nav_pages_snapshot}{html} = [];
        $error = '';
        eval { $guard_dispatcher->all_skill_nav_literal_items_html( sub { $_[0] } ); 1 }
          or $error = $@;
        like( $error, qr/Malformed rendered skill-nav HTML cache/,
            'literal nav renderer rejects a reference-valued rendered HTML cache' );
        delete $guard_dispatcher->{_skill_nav_pages_snapshot}{html};

        for my $bad_page ( [], bless( { meta => {}, layout => {} }, 'Local::WrongSkillNavPage' ) ) {
            $guard_pages = [$bad_page];
            $guard_dispatcher->{_skill_nav_pages_snapshot}{pages} = $guard_pages;
            $error = '';
            eval { $guard_dispatcher->all_skill_nav_literal_items_html( sub { $_[0] } ); 1 }
              or $error = $@;
            like( $error, qr/Malformed page in literal skill-nav snapshot/,
                'literal nav renderer rejects a non-PageDocument page object' );
        }

        my $bad_meta = Developer::Dashboard::PageDocument->new(
            id => 'bad-meta', title => 'Bad meta', layout => { body => 'body' }, meta => {},
        );
        $bad_meta->{meta} = [];
        $guard_pages = [$bad_meta];
        $guard_dispatcher->{_skill_nav_pages_snapshot}{pages} = $guard_pages;
        $error = '';
        eval { $guard_dispatcher->all_skill_nav_literal_items_html( sub { $_[0] } ); 1 }
          or $error = $@;
        like( $error, qr/Malformed page in literal skill-nav snapshot/,
            'literal nav renderer rejects a page with malformed metadata' );

        my $bad_layout = Developer::Dashboard::PageDocument->new(
            id => 'bad-layout', title => 'Bad layout', layout => { body => 'body' }, meta => {},
        );
        $bad_layout->{layout} = [];
        $guard_pages = [$bad_layout];
        $guard_dispatcher->{_skill_nav_pages_snapshot}{pages} = $guard_pages;
        $error = '';
        eval { $guard_dispatcher->all_skill_nav_literal_items_html( sub { $_[0] } ); 1 }
          or $error = $@;
        like( $error, qr/Malformed page in literal skill-nav snapshot/,
            'literal nav renderer rejects a page with malformed layout data' );

        my $not_literal = Developer::Dashboard::PageDocument->new(
            id => 'not-literal', title => 'Dynamic', layout => { body => '[% dynamic %]' },
            meta => { source_format => 'raw-nav-tt' },
        );
        $guard_pages = [$not_literal];
        $guard_dispatcher->{_skill_nav_pages_snapshot}{pages} = $guard_pages;
        is( $guard_dispatcher->all_skill_nav_literal_items_html( sub { $_[0] } ), undef,
            'literal nav renderer declines a template-bearing body' );

        my $scalar_codes = Developer::Dashboard::PageDocument->new(
            id => 'scalar-codes', title => 'Scalar codes', layout => { body => 'body' },
            meta => { source_format => 'raw-nav-tt', codes => 'not-an-array' },
        );
        $guard_pages = [$scalar_codes];
        $guard_dispatcher->{_skill_nav_pages_snapshot}{pages} = $guard_pages;
        is( $guard_dispatcher->all_skill_nav_literal_items_html( sub { $_[0] } ), undef,
            'literal nav renderer declines a malformed code-section collection' );

        my $empty_format = Developer::Dashboard::PageDocument->new(
            id => 'empty-format', title => 'Empty format', layout => { body => 'body' },
            meta => { source_format => '' },
        );
        $guard_pages = [$empty_format];
        $guard_dispatcher->{_skill_nav_pages_snapshot}{pages} = $guard_pages;
        is( $guard_dispatcher->all_skill_nav_literal_items_html( sub { $_[0] } ), undef,
            'literal nav renderer declines a page without the raw-nav format marker' );
        my $missing_format = Developer::Dashboard::PageDocument->new(
            id => 'missing-format', title => 'Missing format', layout => { body => 'body' }, meta => {},
        );
        $guard_pages = [$missing_format];
        $guard_dispatcher->{_skill_nav_pages_snapshot}{pages} = $guard_pages;
        is( $guard_dispatcher->all_skill_nav_literal_items_html( sub { $_[0] } ), undef,
            'literal nav renderer declines a page whose source format is absent' );
        my $other_format = Developer::Dashboard::PageDocument->new(
            id => 'other-format', title => 'Other format', layout => { body => 'body' },
            meta => { source_format => 'bookmark' },
        );
        $guard_pages = [$other_format];
        $guard_dispatcher->{_skill_nav_pages_snapshot}{pages} = $guard_pages;
        is( $guard_dispatcher->all_skill_nav_literal_items_html( sub { $_[0] } ), undef,
            'literal nav renderer declines a defined non-nav source format' );
        for my $invalid_literal (
            [ 'missing body', { source_format => 'raw-nav-tt' }, {} ],
            [ 'reference body', { source_format => 'raw-nav-tt' }, { body => [] } ],
            [ 'non-empty code sections', { source_format => 'raw-nav-tt', codes => ['print 1'] }, { body => 'body' } ],
        ) {
            my ( $label, $meta, $layout ) = @{$invalid_literal};
            my $page = Developer::Dashboard::PageDocument->new(
                id => "invalid-$label", title => $label, layout => $layout, meta => $meta,
            );
            $guard_pages = [$page];
            $guard_dispatcher->{_skill_nav_pages_snapshot}{pages} = $guard_pages;
            is( $guard_dispatcher->all_skill_nav_literal_items_html( sub { $_[0] } ), undef,
                "literal nav renderer declines $label" );
        }

        $guard_page->{id} = undef;
        $guard_pages = [$guard_page];
        $guard_dispatcher->{_skill_nav_pages_snapshot}{pages} = $guard_pages;
        $error = '';
        eval { $guard_dispatcher->all_skill_nav_literal_items_html( sub { $_[0] } ); 1 }
          or $error = $@;
        like( $error, qr/Malformed route id in literal skill-nav snapshot/,
            'literal nav renderer rejects an undefined route id' );
        $guard_page->{id} = 'guard-page';

        $guard_page->{id} = [];
        $error = '';
        eval { $guard_dispatcher->all_skill_nav_literal_items_html( sub { $_[0] } ); 1 }
          or $error = $@;
        like( $error, qr/Malformed route id in literal skill-nav snapshot/,
            'literal nav renderer rejects a reference-valued route id' );
        $guard_page->{id} = 'guard-page';

        $error = '';
        eval { $guard_dispatcher->all_skill_nav_literal_items_html( sub { return [] } ); 1 }
          or $error = $@;
        like( $error, qr/attribute escaper returned a non-scalar value/,
            'literal nav renderer rejects a reference-valued escaped route id' );

        $error = '';
        eval { $guard_dispatcher->all_skill_nav_literal_items_html( sub { return } ); 1 }
          or $error = $@;
        like( $error, qr/attribute escaper returned a non-scalar value/,
            'literal nav renderer rejects an undefined escaped route id' );

        $guard_page->{layout}{body} = 'x' x ( 10 * 1024 * 1024 + 1 );
        my $oversized_html = $guard_dispatcher->all_skill_nav_literal_items_html( sub { $_[0] } );
        like( $oversized_html, qr/^<li data-nav-id="guard-page">x+<\/li>$/,
            'literal nav renderer returns oversized markup without truncation' );
        ok( !exists $guard_dispatcher->{_skill_nav_pages_snapshot}{html},
            'literal nav renderer does not retain oversized markup in its cache' );
    }

    ok( $watch->{configure_calls} >= 1, 'aggregate snapshot configures a watcher for its validated roots' );
    ok( grep( { $_ eq $root } @{ $watch->{paths} } ), 'watch set includes the parent that detects new or removed installed skills' );
    ok( grep( { $_ eq $aggregate_root } @{ $watch->{paths} } ), 'watch set includes each skill root for in-place state markers' );
    ok( grep( { $_ eq $aggregate_nav } @{ $watch->{paths} } ), 'watch set includes the active nav directory for content and route changes' );
    undef $aggregate_dispatcher;
    is( $watch->{closed}, 1, 'dispatcher destruction closes the native skill-nav watcher' );
}

{
    my $cache_paths = Local::SkillPaths->new( home => $root, runtime_roots => ['runtime-a'] );
    my $cache_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $cache_paths ),
        paths   => $cache_paths,
    );
    $cache_dispatcher->{_skill_nav_pages_snapshot} = {
        pages           => [],
        signature       => 'watch-signature',
        paths_signature => [ refaddr($cache_paths), 'runtime-old' ],
    };
    is( $cache_dispatcher->_cached_all_skill_nav_pages, undef,
        'aggregate snapshot invalidates when a runtime root changes without changing inventory length' );
    ok( !exists $cache_dispatcher->{_skill_nav_pages_snapshot},
        'same-length runtime-root changes discard the old aggregate snapshot' );

    $cache_dispatcher->{_skill_nav_pages_snapshot} = {
        pages           => [],
        signature       => 'watch-signature',
        paths_signature => $cache_dispatcher->_skill_nav_paths_signature,
    };
    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::IndicatorStore::Watch::new = sub { return };
        is( $cache_dispatcher->_cached_all_skill_nav_pages, undef,
            'aggregate cache declines a cached snapshot when its optional watcher is unavailable' );
    }
    ok( !exists $cache_dispatcher->{_skill_nav_pages_snapshot},
        'watcher unavailability removes the unvalidated aggregate snapshot' );

    for my $bad_snapshot (
        { pages => 'not-an-array', signature => 'signature', paths_signature => [ refaddr($cache_paths), 'runtime-a' ] },
        { pages => [], signature => undef, paths_signature => [ refaddr($cache_paths), 'runtime-a' ] },
        { pages => [], signature => [], paths_signature => [ refaddr($cache_paths), 'runtime-a' ] },
    ) {
        my $malformed_dispatcher = Developer::Dashboard::SkillDispatcher->new(
            manager => Local::SkillManager->new( paths => $cache_paths ),
            paths   => $cache_paths,
        );
        $malformed_dispatcher->{_skill_nav_pages_snapshot} = $bad_snapshot;
        my $error = '';
        eval { $malformed_dispatcher->_cached_all_skill_nav_pages; 1 } or $error = $@;
        like( $error, qr/Malformed aggregate skill-nav page cache/,
            'aggregate cache rejects malformed page or signature fields explicitly' );
    }

    for my $bad_paths_signature (
        undef,
        'not-an-array',
        [ refaddr($cache_paths) ],
    ) {
        my $malformed_dispatcher = Developer::Dashboard::SkillDispatcher->new(
            manager => Local::SkillManager->new( paths => $cache_paths ),
            paths   => $cache_paths,
        );
        $malformed_dispatcher->{_skill_nav_pages_snapshot} = {
            pages => [], signature => 'signature', paths_signature => $bad_paths_signature,
        };
        {
            no warnings qw(redefine once);
            local *Developer::Dashboard::IndicatorStore::Watch::new = sub { return };
            is( $malformed_dispatcher->_cached_all_skill_nav_pages, undef,
                'aggregate cache invalidates a missing, malformed, or length-mismatched path signature' );
        }
    }

    my $missing_runtime_signature_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $cache_paths ),
        paths   => $cache_paths,
    );
    $missing_runtime_signature_dispatcher->{_skill_nav_pages_snapshot} = {
        pages => [], signature => 'signature',
        paths_signature => [ refaddr($cache_paths), 'runtime-a' ],
    };
    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::SkillDispatcher::_skill_nav_paths_signature = sub { return };
        is( $missing_runtime_signature_dispatcher->_cached_all_skill_nav_pages, undef,
            'aggregate cache invalidates when the live runtime-root signature is unavailable' );
    }

    my $undefined_path_signature_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $cache_paths ),
        paths   => $cache_paths,
    );
    $undefined_path_signature_dispatcher->{_skill_nav_pages_snapshot} = {
        pages => [], signature => 'signature',
        paths_signature => [ refaddr($cache_paths), undef ],
    };
    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::IndicatorStore::Watch::new = sub { return };
        is( $undefined_path_signature_dispatcher->_cached_all_skill_nav_pages, undef,
            'aggregate cache invalidates an undefined cached runtime-root identity' );
    }

    my $stale_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $cache_paths ),
        paths   => $cache_paths,
    );
    $stale_dispatcher->{_skill_nav_pages_snapshot} = {
        pages => [], signature => 'signature',
        paths_signature => $stale_dispatcher->_skill_nav_paths_signature,
    };
    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::IndicatorStore::Watch::new = sub {
            return bless {}, 'Local::Problem48SkillNavWatchStaleWithoutError';
        };
        is( $stale_dispatcher->_cached_all_skill_nav_pages, undef,
            'watcher event without an error invalidates the aggregate cache' );
    }
    ok( !exists $stale_dispatcher->{_skill_nav_pages_snapshot},
        'watcher event without an error removes stale pages' );

    my $empty_error_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $cache_paths ),
        paths   => $cache_paths,
    );
    $empty_error_dispatcher->{_skill_nav_pages_snapshot} = {
        pages => [], signature => 'empty-error-signature',
        paths_signature => $empty_error_dispatcher->_skill_nav_paths_signature,
    };
    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::IndicatorStore::Watch::new = sub {
            return bless {}, 'Local::Problem48SkillNavWatchStaleEmptyError';
        };
        is( $empty_error_dispatcher->_cached_all_skill_nav_pages, undef,
            'an empty watcher error invalidates the cached aggregate snapshot without a warning' );
    }
    ok( !exists $empty_error_dispatcher->{_skill_nav_pages_snapshot},
        'an empty watcher diagnostic never preserves stale aggregate pages' );

    my $close_failure_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $cache_paths ),
        paths   => $cache_paths,
    );
    $close_failure_dispatcher->{_skill_nav_pages_snapshot} = {
        pages => [], signature => 'signature',
        paths_signature => $close_failure_dispatcher->_skill_nav_paths_signature,
    };
    my $close_warning = '';
    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::IndicatorStore::Watch::new = sub {
            return bless {}, 'Local::Problem48SkillNavWatchStaleCloseFailure';
        };
        local $SIG{__WARN__} = sub { $close_warning .= join '', @_ };
        is( $close_failure_dispatcher->_cached_all_skill_nav_pages, undef,
            'watcher close failure still invalidates stale aggregate pages' );
    }
    like( $close_warning, qr/Skill nav snapshot watcher close failed:/,
        'stale watcher close failure is visible to the operator' );

    my $empty_close_error_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $cache_paths ),
        paths   => $cache_paths,
    );
    $empty_close_error_dispatcher->{_skill_nav_pages_snapshot} = {
        pages => [], signature => 'empty-close-signature',
        paths_signature => $empty_close_error_dispatcher->_skill_nav_paths_signature,
    };
    my $empty_close_warning = '';
    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::IndicatorStore::Watch::new = sub {
            return bless {}, 'Local::Problem48SkillNavWatchStaleEmptyCloseError';
        };
        local $SIG{__WARN__} = sub { $empty_close_warning .= join '', @_ };
        is( $empty_close_error_dispatcher->_cached_all_skill_nav_pages, undef,
            'stale cache invalidates when a watcher reports an empty error and cannot close' );
    }
    like( $empty_close_warning, qr/unknown close failure/,
        'empty stale-watcher close diagnostics use an explicit fallback message' );
}

{
    my $paths = Local::SkillPaths->new( home => $root, runtime_roots => ['runtime-a'] );
    my $dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $paths ),
        paths   => $paths,
    );
    for my $case (
        [ 'pages', undef, [], [], qr/pages must be an array reference/ ],
        [ 'skill roots', [], undef, [], qr/skill roots must be an array reference/ ],
        [ 'skill layers', [], [], undef, qr/skill layers must be an array reference/ ],
    ) {
        my ( $name, $pages_arg, $roots_arg, $layers_arg, $expected ) = @{$case};
        my $error = '';
        eval { $dispatcher->_cache_all_skill_nav_pages( $pages_arg, $roots_arg, $layers_arg ); 1 }
          or $error = $@;
        like( $error, $expected, "aggregate page cache validates its $name argument" );
    }
    ok( !$dispatcher->_cache_all_skill_nav_pages( [ (undef) x 8193 ], [], [] ),
        'aggregate page cache declines more than its page-count bound' );

    my $no_runtime_paths = Local::LegacySkillPaths->new( [], {} );
    my $no_runtime_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $no_runtime_paths ),
        paths   => $no_runtime_paths,
    );
    ok( !$no_runtime_dispatcher->_cache_all_skill_nav_pages( [], [], [] ),
        'aggregate page cache declines when runtime-root identity is unavailable' );

    my $invalid_root_paths = Local::SkillPaths->new( home => $root, runtime_roots => [ undef ] );
    my $invalid_root_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $invalid_root_paths ),
        paths   => $invalid_root_paths,
    );
    my $root_error = '';
    eval { $invalid_root_dispatcher->_skill_nav_paths_signature; 1 } or $root_error = $@;
    like( $root_error, qr/Invalid runtime root in skill-nav paths signature/,
        'runtime-root signature refuses undefined roots rather than caching them' );

    my $not_page = Developer::Dashboard::PageDocument->new( title => 'not literal' );
    ok( !$dispatcher->_cache_all_skill_nav_pages( [$not_page], [], [] ),
        'aggregate page cache declines a parsed non-literal page' );
    my $bad_meta_page = Developer::Dashboard::PageDocument->new(
        id => 'bad-meta', title => 'bad-meta', layout => { body => 'body' },
        meta => { source_format => 'raw-nav-tt' },
    );
    $bad_meta_page->{meta} = [];
    ok( !$dispatcher->_cache_all_skill_nav_pages( [$bad_meta_page], [], [] ),
        'aggregate page cache declines malformed metadata' );
    my $missing_body_page = Developer::Dashboard::PageDocument->new(
        id => 'missing-body', title => 'missing-body', layout => {},
        meta => { source_format => 'raw-nav-tt' },
    );
    ok( !$dispatcher->_cache_all_skill_nav_pages( [$missing_body_page], [], [] ),
        'aggregate page cache declines a missing literal body' );
    my $reference_body_page = Developer::Dashboard::PageDocument->new(
        id => 'reference-body', title => 'reference-body', layout => { body => [] },
        meta => { source_format => 'raw-nav-tt' },
    );
    ok( !$dispatcher->_cache_all_skill_nav_pages( [$reference_body_page], [], [] ),
        'aggregate page cache declines reference-valued markup' );
    for my $case (
        [ 'missing raw-nav marker', { source_format => '' }, 'body' ],
        [ 'template syntax', { source_format => 'raw-nav-tt' }, '[% dynamic %]' ],
        [ 'non-empty code list', { source_format => 'raw-nav-tt', codes => ['print 1'] }, 'body' ],
    ) {
        my ( $label, $meta, $body ) = @{$case};
        my $page = Developer::Dashboard::PageDocument->new(
            id => "rejected-$label", title => $label, layout => { body => $body }, meta => $meta,
        );
        ok( !$dispatcher->_cache_all_skill_nav_pages( [$page], [], [] ),
            "aggregate page cache declines $label" );
    }
    my $large_page = Developer::Dashboard::PageDocument->new(
        id => 'large', title => 'large', layout => { body => 'x' x ( 8 * 1024 * 1024 + 1 ) },
        meta => { source_format => 'raw-nav-tt' },
    );
    ok( !$dispatcher->_cache_all_skill_nav_pages( [$large_page], [], [] ),
        'aggregate page cache declines content over its byte bound' );

    my $empty_watch_paths = Local::SkillPaths->new( home => $root, runtime_roots => [] );
    my $empty_watch_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $empty_watch_paths ),
        paths   => $empty_watch_paths,
    );
    my $literal_page = Developer::Dashboard::PageDocument->new(
        id => 'literal', title => 'literal', layout => { body => 'body' },
        meta => { source_format => 'raw-nav-tt' },
    );
    ok( !$empty_watch_dispatcher->_cache_all_skill_nav_pages( [$literal_page], [], [] ),
        'aggregate page cache declines when no filesystem paths can be watched' );

    my $setup_paths = Local::SkillPaths->new( home => $root, runtime_roots => [$root] );
    my $setup_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $setup_paths ),
        paths   => $setup_paths,
    );
    my $setup_warning = '';
    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::IndicatorStore::Watch::new = sub {
            return bless {}, 'Local::Problem48SkillNavWatchSetupWithoutDiagnostics';
        };
        local $SIG{__WARN__} = sub { $setup_warning .= join '', @_ };
        ok( !$setup_dispatcher->_cache_all_skill_nav_pages( [$literal_page], [$root], [$root] ),
            'aggregate page cache declines when the watcher setup fails' );
    }
    like( $setup_warning, qr/Skill nav snapshot watch setup failed: unknown watcher error/,
        'watch setup failure without a backend diagnostic remains explicit' );
    like( $setup_warning, qr/Skill nav snapshot watcher close failed: unknown close failure/,
        'watcher close failure without diagnostics remains explicit' );

    my $setup_close_error_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $setup_paths ),
        paths   => $setup_paths,
    );
    my $setup_close_error_warning = '';
    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::IndicatorStore::Watch::new = sub {
            return bless {}, 'Local::Problem48SkillNavWatchSetupCloseError';
        };
        local $SIG{__WARN__} = sub { $setup_close_error_warning .= join '', @_ };
        ok( !$setup_close_error_dispatcher->_cache_all_skill_nav_pages( [$literal_page], [$root], [$root] ),
            'aggregate page cache rejects a watcher whose setup and close fail' );
    }
    like( $setup_close_error_warning, qr/Skill nav snapshot watcher close failed: injected watcher close error/,
        'watcher close diagnostic is included when the backend exposes last_error' );

    my $setup_empty_error_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $setup_paths ),
        paths   => $setup_paths,
    );
    my $setup_empty_error_warning = '';
    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::IndicatorStore::Watch::new = sub {
            return bless {}, 'Local::Problem48SkillNavWatchSetupEmptyError';
        };
        local $SIG{__WARN__} = sub { $setup_empty_error_warning .= join '', @_ };
        ok( !$setup_empty_error_dispatcher->_cache_all_skill_nav_pages( [$literal_page], [$root], [$root] ),
            'aggregate page cache rejects watcher setup with empty diagnostics' );
    }
    like( $setup_empty_error_warning, qr/Skill nav snapshot watch setup failed: unknown watcher error/,
        'empty setup diagnostics use the explicit unknown-error message' );
    like( $setup_empty_error_warning, qr/Skill nav snapshot watcher close failed: unknown close failure/,
        'empty close diagnostics use the explicit unknown-close message' );

    for my $bad_inventory (
        [ 'non-hash inventory', [], qr/Malformed aggregate skill-nav inventory cache/ ],
        [ 'non-hash entries', { entries => [] }, qr/Malformed aggregate skill-nav inventory cache/ ],
        [ 'non-hash entry', { entries => { item => [] } }, qr/Malformed aggregate skill-nav inventory directories/ ],
        [ 'non-array directories', { entries => { item => { directories => 'bad' } } }, qr/Malformed aggregate skill-nav inventory directories/ ],
    ) {
        my ( $label, $inventory, $expected ) = @{$bad_inventory};
        $dispatcher->{_skill_nav_inventory_cache} = $inventory;
        my $inventory_error = '';
        eval { $dispatcher->_cache_all_skill_nav_pages( [], [], [] ); 1 }
          or $inventory_error = $@;
        like( $inventory_error, $expected, "aggregate watcher rejects $label" );
    }

    for my $bad_watch_target (
        [ 'undefined inventory path', undef ],
        [ 'reference inventory path', [] ],
        [ 'empty inventory path', '' ],
    ) {
        my ( $label, $target ) = @{$bad_watch_target};
        $dispatcher->{_skill_nav_inventory_cache} = {
            entries => { item => { directories => [ [ $target ] ] } },
        };
        no warnings qw(redefine once);
        local *Developer::Dashboard::IndicatorStore::Watch::new = sub { return };
        ok( !$dispatcher->_cache_all_skill_nav_pages( [], [], [] ),
            "aggregate watcher ignores an $label and retains the portable fallback" );
        delete $dispatcher->{_skill_nav_inventory_cache};
    }

    my $unblessed_paths_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => 'not-an-object' ),
        paths   => 'not-an-object',
    );
    ok( !defined $unblessed_paths_dispatcher->_skill_nav_paths_signature,
        'skill-nav path signature declines an unblessed path provider' );

    ok( !$dispatcher->_cache_all_skill_nav_pages( [ [] ], [], [] ),
        'aggregate page cache declines a non-PageDocument value' );
    my $scalar_codes_page = Developer::Dashboard::PageDocument->new(
        id => 'scalar-codes', title => 'scalar-codes', layout => { body => 'body' },
        meta => { source_format => 'raw-nav-tt', codes => 'invalid' },
    );
    ok( !$dispatcher->_cache_all_skill_nav_pages( [$scalar_codes_page], [], [] ),
        'aggregate page cache declines a non-array code-section field' );
    my $templated_page = Developer::Dashboard::PageDocument->new(
        id => 'templated', title => 'templated', layout => { body => '[% value %]' },
        meta => { source_format => 'raw-nav-tt' },
    );
    ok( !$dispatcher->_cache_all_skill_nav_pages( [$templated_page], [], [] ),
        'aggregate page cache declines template-bearing markup' );

    my $malformed_inventory_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $paths ),
        paths   => $paths,
    );
    $malformed_inventory_dispatcher->{_skill_nav_inventory_cache} = 'not-a-hash';
    my $inventory_error = '';
    eval { $malformed_inventory_dispatcher->_cache_all_skill_nav_pages( [$literal_page], [], [] ); 1 }
      or $inventory_error = $@;
    like( $inventory_error, qr/Malformed aggregate skill-nav inventory cache/,
        'aggregate page cache rejects a malformed route-inventory container' );

    $malformed_inventory_dispatcher->{_skill_nav_inventory_cache} = {
        entries => { root => 'not-a-hash' },
    };
    $inventory_error = '';
    eval { $malformed_inventory_dispatcher->_cache_all_skill_nav_pages( [$literal_page], [], [] ); 1 }
      or $inventory_error = $@;
    like( $inventory_error, qr/Malformed aggregate skill-nav inventory directories/,
        'aggregate page cache rejects malformed inventory-directory metadata' );

    my $bad_inventory_path_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $paths ),
        paths   => $paths,
    );
    $bad_inventory_path_dispatcher->{_skill_nav_pages_watcher} =
      bless {}, 'Local::Problem48SkillNavWatch';
    $bad_inventory_path_dispatcher->{_skill_nav_inventory_cache} = {
        entries => { root => { directories => [ [ undef, 'fingerprint' ] ] } },
    };
    ok( $bad_inventory_path_dispatcher->_cache_all_skill_nav_pages( [$literal_page], [], [] ),
        'aggregate page cache skips an invalid inventory path while watching valid runtime roots' );

    my $invalid_roots_paths = Local::SkillPathsWithSkillsRoots->new(
        home => $root, runtime_roots => [], skills_roots => [ undef, [], '' ],
    );
    my $invalid_roots_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $invalid_roots_paths ),
        paths   => $invalid_roots_paths,
    );
    ok( !$invalid_roots_dispatcher->_cache_all_skill_nav_pages(
            [$literal_page], [ undef, [], '' ], [ undef, [], '' ]
        ),
        'aggregate page cache skips invalid root and layer values and refuses an empty watch set' );

    my $no_runtime_method_paths = Local::LegacySkillPaths->new( [], {} );
    my $no_runtime_method_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $no_runtime_method_paths ),
        paths   => $no_runtime_method_paths,
    );
    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::SkillDispatcher::_skill_nav_paths_signature = sub { return [] };
        ok( !$no_runtime_method_dispatcher->_cache_all_skill_nav_pages( [$literal_page], [], [] ),
            'aggregate cache handles a compatible signature provider without runtime_roots' );
    }

    my $ancestor_paths = Local::SkillPaths->new( home => $root, runtime_roots => [] );
    my $ancestor_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $ancestor_paths ),
        paths   => $ancestor_paths,
    );
    {
        no warnings qw(redefine once);
        my $catdir_calls = 0;
        local *File::Spec::Unix::catdir = sub { $catdir_calls++; return undef };
        ok( !$ancestor_dispatcher->_cache_all_skill_nav_pages( [$literal_page], [], ['layer'] ),
            'aggregate cache skips an invalid target returned by path construction' );
        is( $catdir_calls, 3, 'aggregate cache attempts all watched directory targets through File::Spec' );
    }
    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::SkillDispatcher::dirname = sub { return $_[0] };
        ok( !$ancestor_dispatcher->_cache_all_skill_nav_pages( [$literal_page], [], ['missing-layer'] ),
            'aggregate cache stops walking when a directory parent does not advance' );
    }
}

{
    my @shutdown_cases = (
        [ 'Local::Problem48SkillNavWatchCloseFalse', qr/unknown watcher shutdown failure/, 'false close without diagnostics' ],
        [ 'Local::Problem48SkillNavWatchCloseError', qr/injected watcher close exception/, 'close exception' ],
        [ 'Local::Problem48SkillNavWatchLastError', qr/injected watcher close diagnostic/, 'close diagnostic' ],
        [ 'Local::Problem48SkillNavWatchEmptyCloseError', qr/unknown watcher shutdown failure/, 'empty close diagnostic' ],
    );
    for my $case (@shutdown_cases) {
        my ( $watch_class, $expected, $label ) = @{$case};
        my $dispatcher = Developer::Dashboard::SkillDispatcher->new(
            manager => Local::SkillManager->new( paths => $paths ),
            paths   => $paths,
        );
        $dispatcher->{_skill_nav_pages_watcher} = bless {}, $watch_class;
        my $warning = '';
        {
            local $SIG{__WARN__} = sub { $warning .= join '', @_ };
            $dispatcher->DESTROY;
        }
        like( $warning, $expected, "dispatcher reports $label during watcher shutdown" );
        ok( !exists $dispatcher->{_skill_nav_pages_watcher}, "dispatcher clears watcher state after $label" );
    }
}

{
    my $fallback_root = File::Spec->catdir( $root, 'fallback-skill' );
    my $fallback_nav = File::Spec->catdir( $fallback_root, 'dashboards', 'nav' );
    make_path($fallback_nav);
    _write_file( File::Spec->catfile( $fallback_nav, 'index.tt' ), '<span>fallback</span>' );
    my $fallback_paths = Local::SkillPaths->new(
        home      => $root,
        installed => [$fallback_root],
        layers    => { 'fallback-skill' => [$fallback_root] },
    );
    my $fallback_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $fallback_paths ),
        paths   => $fallback_paths,
    );
    require Developer::Dashboard::IndicatorStore::Watch;
    my $fallback_loads = 0;
    my $original_load = Developer::Dashboard::SkillDispatcher->can('_load_skill_page');
    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::IndicatorStore::Watch::new = sub { return };
        local *Developer::Dashboard::SkillDispatcher::_load_skill_page = sub {
            $fallback_loads++;
            return $original_load->(@_);
        };
        $fallback_dispatcher->all_skill_nav_pages;
        $fallback_dispatcher->all_skill_nav_pages;
    }
    is( $fallback_loads, 2, 'missing optional native watcher keeps the portable page validation path' );
    ok( !exists $fallback_dispatcher->{_skill_nav_pages_snapshot},
        'missing native watcher does not install an unvalidated aggregate snapshot' );

    my $failure_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $fallback_paths ),
        paths   => $fallback_paths,
    );
    my $failed_watch = bless { configure_error => 'injected setup failure' }, 'Local::Problem48SkillNavWatch';
    my $warning = '';
    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::IndicatorStore::Watch::new = sub { return $failed_watch };
        local $SIG{__WARN__} = sub { $warning .= join '', @_ };
        my $pages = $failure_dispatcher->all_skill_nav_pages;
        is( scalar @{$pages}, 1, 'watch setup failure preserves rendered skill nav pages' );
    }
    like( $warning, qr/Skill nav snapshot watch setup failed: injected setup failure/,
        'watch setup failure is visible instead of silently selecting the portable path' );
    ok( !exists $failure_dispatcher->{_skill_nav_pages_snapshot},
        'watch setup failure does not install an aggregate snapshot' );

    my $read_failure_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $fallback_paths ),
        paths   => $fallback_paths,
    );
    my $read_failure_watch = bless {}, 'Local::Problem48SkillNavWatch';
    my $read_warning = '';
    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::IndicatorStore::Watch::new = sub { return $read_failure_watch };
        $read_failure_dispatcher->all_skill_nav_pages;
        $read_failure_watch->{error} = 'injected read failure';
        local $SIG{__WARN__} = sub { $read_warning .= join '', @_ };
        my $pages = $read_failure_dispatcher->all_skill_nav_pages;
        is( scalar @{$pages}, 1, 'watch read failure preserves fresh skill nav pages' );
    }
    like( $read_warning, qr/Skill nav snapshot watch disabled: injected read failure/,
        'watch read failure is visible and invalidates the aggregate cache' );
    ok( !exists $read_failure_dispatcher->{_skill_nav_pages_snapshot},
        'watch read failure removes the potentially stale aggregate snapshot' );
}

ok( Developer::Dashboard::SkillDispatcher::_skill_nav_inventory_within_limits( 1, 1, 1 ),
    'nav inventory size guard accepts an ordinary tree' );
ok( !Developer::Dashboard::SkillDispatcher::_skill_nav_inventory_within_limits( undef, 1, 1 ),
    'nav inventory size guard rejects a missing directory count' );
ok( !Developer::Dashboard::SkillDispatcher::_skill_nav_inventory_within_limits( 4097, 1, 1 ),
    'nav inventory size guard rejects a tree beyond its directory bound' );
ok( !Developer::Dashboard::SkillDispatcher::_skill_nav_inventory_within_limits( 1, undef, 1 ),
    'nav inventory size guard rejects a missing file count' );
ok( !Developer::Dashboard::SkillDispatcher::_skill_nav_inventory_within_limits( 1, 8193, 1 ),
    'nav inventory size guard rejects a tree beyond its file bound' );
ok( !Developer::Dashboard::SkillDispatcher::_skill_nav_inventory_within_limits( 1, 1, undef ),
    'nav inventory size guard rejects a missing byte count' );
ok( !Developer::Dashboard::SkillDispatcher::_skill_nav_inventory_within_limits( 1, 1, 262145 ),
    'nav inventory size guard rejects an oversized inventory' );
ok( !defined Developer::Dashboard::SkillDispatcher::_skill_nav_directory_fingerprint(''),
    'nav directory fingerprint rejects an empty path' );
ok( !defined Developer::Dashboard::SkillDispatcher::_skill_nav_directory_fingerprint(undef),
    'nav directory fingerprint rejects an undefined path' );
ok( !defined Developer::Dashboard::SkillDispatcher::_skill_nav_directory_fingerprint(
        File::Spec->catfile( $solo_skill, 'dashboards', 'nav', 'solo.tt' ) ),
    'nav directory fingerprint rejects a regular file' );
ok( !defined Developer::Dashboard::SkillDispatcher::_skill_nav_directory_fingerprint(
        File::Spec->catdir( $solo_skill, 'dashboards', 'nav', 'missing' ) ),
    'nav directory fingerprint rejects a missing directory' );

{
    my $inventory_nav_root = File::Spec->catdir( $solo_skill, 'dashboards', 'nav' );
    my @bad_cache_states = (
        [ 'scalar cache', 'bad', qr/Malformed skill-nav inventory cache/ ],
        [ 'bad entries container', { entries => [], order => [] }, qr/Malformed skill-nav inventory entries/ ],
        [ 'bad order container', { entries => {}, order => {} }, qr/Malformed skill-nav inventory order/ ],
        [ 'scalar entry', { entries => { $inventory_nav_root => 'bad' }, order => [] }, qr/Malformed skill-nav inventory entry/ ],
        [ 'bad files container', { entries => { $inventory_nav_root => { files => {}, directories => [] } }, order => [] }, qr/Malformed skill-nav inventory files/ ],
        [ 'bad directories container', { entries => { $inventory_nav_root => { files => [], directories => {} } }, order => [] }, qr/Malformed skill-nav inventory directories/ ],
        [ 'bad fingerprint container', { entries => { $inventory_nav_root => { files => [], directories => ['bad'] } }, order => [] }, qr/Malformed skill-nav inventory directory fingerprint/ ],
        [ 'bad fingerprint width', { entries => { $inventory_nav_root => { files => [], directories => [[]] } }, order => [] }, qr/Malformed skill-nav inventory directory fingerprint width/ ],
    );
    for my $case (@bad_cache_states) {
        my ( $label, $state, $expected_error ) = @{$case};
        my $cache_dispatcher = Developer::Dashboard::SkillDispatcher->new(
            manager => Local::SkillManager->new( paths => $paths ),
            paths   => $paths,
        );
        $cache_dispatcher->{_skill_nav_inventory_cache} = $state;
        my $cache_error;
        eval { $cache_dispatcher->_skill_nav_inventory($inventory_nav_root); 1 } or $cache_error = $@;
        like( $cache_error, $expected_error, "malformed $label fails explicitly" );
    }

    my $missing_fingerprint_dir = File::Spec->catdir( $inventory_nav_root, 'missing-child' );
    my $missing_fingerprint_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $paths ),
        paths   => $paths,
    );
    $missing_fingerprint_dispatcher->{_skill_nav_inventory_cache} = {
        entries => {
            $inventory_nav_root => {
                files       => ['stale.tt'],
                directories => [ [ $missing_fingerprint_dir, 'old-fingerprint' ] ],
            },
        },
        order => [$inventory_nav_root],
    };
    my @after_missing_fingerprint = $missing_fingerprint_dispatcher->_skill_nav_inventory($inventory_nav_root);
    ok( !grep( { $_ eq 'stale.tt' } @after_missing_fingerprint ),
        'missing cached directory fingerprints invalidate the route inventory' );

    my $bad_segment_map_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $paths ),
        paths   => $paths,
    );
    $bad_segment_map_dispatcher->_skill_nav_inventory($inventory_nav_root);
    $bad_segment_map_dispatcher->{_skill_nav_inventory_cache}{entries}{$inventory_nav_root}{segments} = [];
    my $bad_segment_map_error;
    eval { $bad_segment_map_dispatcher->_skill_nav_inventory($inventory_nav_root); 1 }
      or $bad_segment_map_error = $@;
    like( $bad_segment_map_error, qr/Malformed skill-nav inventory segments/,
        'malformed cached segment map fails explicitly' );

    my $bad_segment_entry_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $paths ),
        paths   => $paths,
    );
    $bad_segment_entry_dispatcher->_skill_nav_inventory($inventory_nav_root);
    my ($cached_segment_file) = @{ $bad_segment_entry_dispatcher->{_skill_nav_inventory_cache}{entries}{$inventory_nav_root}{files} };
    $bad_segment_entry_dispatcher->{_skill_nav_inventory_cache}{entries}{$inventory_nav_root}{segments}{$cached_segment_file} = 'unsafe';
    my $bad_segment_entry_error;
    eval { $bad_segment_entry_dispatcher->_skill_nav_inventory($inventory_nav_root); 1 }
      or $bad_segment_entry_error = $@;
    like( $bad_segment_entry_error, qr/Malformed skill-nav inventory segment entry/,
        'malformed cached route-segment entry fails explicitly' );

    my $missing_segment_entry_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $paths ),
        paths   => $paths,
    );
    $missing_segment_entry_dispatcher->_skill_nav_inventory($inventory_nav_root);
    my ($missing_segment_file) = @{ $missing_segment_entry_dispatcher->{_skill_nav_inventory_cache}{entries}{$inventory_nav_root}{files} };
    delete $missing_segment_entry_dispatcher->{_skill_nav_inventory_cache}{entries}{$inventory_nav_root}{segments}{$missing_segment_file};
    my $missing_segment_error;
    eval { $missing_segment_entry_dispatcher->_skill_nav_inventory($inventory_nav_root); 1 }
      or $missing_segment_error = $@;
    like( $missing_segment_error, qr/Malformed skill-nav inventory segment entry/,
        'cached inventory rejects a route missing its validated-segment entry' );

    my $optional_segments_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $paths ),
        paths   => $paths,
    );
    $optional_segments_dispatcher->_skill_nav_inventory($inventory_nav_root);
    my @cached_without_segments = $optional_segments_dispatcher->_skill_nav_inventory(
        $inventory_nav_root, 'not-a-hash'
    );
    ok( @cached_without_segments,
        'cached inventory remains available when the optional segment output is not a hash' );

    SKIP: {
        skip 'POSIX filenames with backslashes are unavailable on Windows', 4 if $^O eq 'MSWin32';
        my $unsafe_nav_root = File::Spec->catdir( $solo_skill, 'dashboards', 'nav' );
        my $unsafe_nav_file = File::Spec->catfile( $unsafe_nav_root, 'unsafe\\route.tt' );
        _write_file( $unsafe_nav_file, '<span>unsafe name</span>\n' );
        my $unsafe_nav_dispatcher = Developer::Dashboard::SkillDispatcher->new(
            manager => Local::SkillManager->new( paths => $paths ),
            paths   => $paths,
        );
        my %unsafe_segments;
        my @unsafe_files = $unsafe_nav_dispatcher->_skill_nav_inventory( $unsafe_nav_root, \%unsafe_segments );
        ok( grep( { $_ eq 'unsafe\\route.tt' } @unsafe_files ),
            'inventory reports an untrusted filename without treating it as a route path' );
        ok( exists $unsafe_segments{'unsafe\\route.tt'} && !defined $unsafe_segments{'unsafe\\route.tt'},
            'inventory marks a filename rejected by route validation as unusable' );
        my %unsafe_cached_segments;
        $unsafe_nav_dispatcher->_skill_nav_inventory( $unsafe_nav_root, \%unsafe_cached_segments );
        ok( exists $unsafe_cached_segments{'unsafe\\route.tt'} && !defined $unsafe_cached_segments{'unsafe\\route.tt'},
            'cached inventory preserves the unusable route-segment marker' );
        my %unsafe_route_segments;
        my %unsafe_route_ids = $unsafe_nav_dispatcher->_skill_nav_route_ids(
            'solo-skill', [$solo_skill], \%unsafe_route_segments
        );
        ok( exists $unsafe_route_ids{'unsafe\\route.tt'} && !defined $unsafe_route_segments{'unsafe\\route.tt'},
            'layered route listing keeps invalid inventory names unavailable to the page loader' );
        unlink $unsafe_nav_file or die "Unable to remove unsafe nav fixture '$unsafe_nav_file': $!";
    }

    my $vanishing_directory = File::Spec->catdir( $inventory_nav_root, 'vanishing' );
    make_path($vanishing_directory);
    my $vanishing_file = File::Spec->catfile( $vanishing_directory, 'child.tt' );
    _write_file( $vanishing_file, '<div>temporary</div>\n' );
    my $missing_child_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $paths ),
        paths   => $paths,
    );
    $missing_child_dispatcher->_skill_nav_inventory($inventory_nav_root);
    unlink $vanishing_file or die "Unable to remove nav inventory fixture '$vanishing_file': $!";
    rmdir $vanishing_directory or die "Unable to remove nav inventory fixture '$vanishing_directory': $!";
    my @after_child_removal = $missing_child_dispatcher->_skill_nav_inventory($inventory_nav_root);
    ok( !grep( { $_ eq 'vanishing/child.tt' } @after_child_removal ),
        'nav inventory invalidates when a previously visited nested directory disappears' );

    my $unstable_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $paths ),
        paths   => $paths,
    );
    my $fingerprint_reads = 0;
    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::SkillDispatcher::_skill_nav_directory_fingerprint = sub {
            $fingerprint_reads++;
            return $fingerprint_reads == 1 ? 'before-scan' : 'after-scan';
        };
        $unstable_dispatcher->_skill_nav_inventory($inventory_nav_root);
        ok( !exists $unstable_dispatcher->{_skill_nav_inventory_cache},
            'an inventory scan with changing directory metadata is not cached' );
    }

    my $unstatable_after_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $paths ),
        paths   => $paths,
    );
    $fingerprint_reads = 0;
    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::SkillDispatcher::_skill_nav_directory_fingerprint = sub {
            $fingerprint_reads++;
            return 'before-scan' if $fingerprint_reads == 1;
            return;
        };
        $unstatable_after_dispatcher->_skill_nav_inventory($inventory_nav_root);
        ok( !exists $unstatable_after_dispatcher->{_skill_nav_inventory_cache},
            'an inventory whose post-scan directory stat fails is not cached' );
    }

    my $unstatable_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $paths ),
        paths   => $paths,
    );
    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::SkillDispatcher::_skill_nav_directory_fingerprint = sub { return };
        $unstatable_dispatcher->_skill_nav_inventory($inventory_nav_root);
        ok( !exists $unstatable_dispatcher->{_skill_nav_inventory_cache},
            'an inventory with an unstatted directory is not cached' );
    }

    my $oversized_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $paths ),
        paths   => $paths,
    );
    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::SkillDispatcher::_skill_nav_inventory_within_limits = sub { return 0 };
        $oversized_dispatcher->_skill_nav_inventory($inventory_nav_root);
        ok( !exists $oversized_dispatcher->{_skill_nav_inventory_cache},
            'a stable but oversized nav inventory is returned without caching' );
    }

    is_deeply( [ $missing_fingerprint_dispatcher->_skill_nav_inventory(undef) ], [],
        'nav inventory returns empty for an undefined root' );
    is_deeply(
        [ $missing_fingerprint_dispatcher->_skill_nav_inventory( File::Spec->catdir( $root, 'absent-nav-root' ) ) ],
        [], 'nav inventory returns empty for a missing root',
    );
}

{
    my $inventory_roots = File::Spec->catdir( $root, 'many-nav-roots' );
    my $bounded_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $paths ),
        paths   => $paths,
    );
    for my $index ( 1 .. 129 ) {
        my $nav_root = File::Spec->catdir( $inventory_roots, "nav-$index" );
        make_path($nav_root);
        $bounded_dispatcher->_skill_nav_inventory($nav_root);
    }
    is( scalar keys %{ $bounded_dispatcher->{_skill_nav_inventory_cache}{entries} }, 128,
        'skill-nav inventory cache retains no more than 128 roots' );
    ok( !exists $bounded_dispatcher->{_skill_nav_inventory_cache}{entries}{
            File::Spec->catdir( $inventory_roots, 'nav-1' )
        }, 'skill-nav inventory cache evicts its oldest root first' );
    remove_tree($inventory_roots);
}

is_deeply(
    { $dispatcher->_skill_nav_route_ids('layered/child') },
    {
        'group/deep.tt' => 'nav/group/deep.tt',
        'index.tt' => 'nav/index.tt',
    },
    '_skill_nav_route_ids resolves nav templates for nested installed skills',
);

{
    my $validated_segment_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $paths ),
        paths   => $paths,
    );
    my $original_validated_segments = Developer::Dashboard::PathRegistry->can('validated_path_segments');
    my $segment_validation_calls = 0;
    no warnings qw(redefine once);
    local *Developer::Dashboard::PathRegistry::validated_path_segments = sub {
        $segment_validation_calls++;
        return $original_validated_segments->(@_);
    };
    my $first_segment_pages = $validated_segment_dispatcher->_skill_nav_pages_for_layers(
        'layered', [ $base_skill, $leaf_skill ] );
    is( scalar @{$first_segment_pages}, 2, 'prevalidated nav segments retain every layered nav page' );
    is( $segment_validation_calls, 3, 'route inventory validates each layered nav id once when it is discovered' );
    my $second_segment_pages = $validated_segment_dispatcher->_skill_nav_pages_for_layers(
        'layered', [ $base_skill, $leaf_skill ] );
    is( scalar @{$second_segment_pages}, 2, 'cached route inventory keeps layered nav pages available' );
    is( $segment_validation_calls, 3,
        'cached route inventory reuses validated path segments without per-request revalidation' );
}

my $bookmark_page = $dispatcher->_load_skill_page(
    skill_name => 'layered',
    route_id   => 'index',
);
is( $bookmark_page->{id}, 'layered', '_load_skill_page namespaces index bookmark ids under the skill name' );
is( $bookmark_page->{meta}{skill_path}, $leaf_skill, '_load_skill_page records the leaf skill path for the serving bookmark' );

my $original_instruction_parser = Developer::Dashboard::PageDocument->can('from_instruction');
my $raw_nav_instruction_parse_calls = 0;
my $nav_page;
{
    no warnings qw(redefine once);
    local *Developer::Dashboard::PageDocument::from_instruction = sub {
        $raw_nav_instruction_parse_calls++;
        return $original_instruction_parser->(@_);
    };
    $nav_page = $dispatcher->_load_skill_page(
        skill_name => 'layered',
        route_id   => 'nav/leaf.tt',
    );
}
is( $nav_page->{id}, 'layered/nav/leaf.tt', '_load_skill_page namespaces raw nav templates under the skill route id' );
is( $nav_page->{meta}{source_format}, 'raw-nav-tt', '_load_skill_page wraps raw nav templates in a synthetic page document' );
is( $raw_nav_instruction_parse_calls, 0,
    '_load_skill_page skips structured instruction parsing for raw nav-template text' );

_write_file(
    File::Spec->catfile( $leaf_skill, 'dashboards', 'nav', 'legacy-structured.tt' ),
    "TITLE: Legacy nav title\n---\nHTML: <span>legacy-structured</span>\n",
);
my $legacy_nav_page = $dispatcher->_load_skill_page(
    skill_name => 'layered',
    route_id   => 'nav/legacy-structured.tt',
);
is( $legacy_nav_page->{title}, 'Legacy nav title',
    '_load_skill_page still parses a legacy structured nav document' );
is( $legacy_nav_page->{meta}{source_format}, 'legacy',
    'legacy structured nav keeps its source-format metadata' );
like( $legacy_nav_page->{layout}{body}, qr/legacy-structured/,
    'legacy structured nav keeps its HTML section' );

_write_file(
    File::Spec->catfile( $leaf_skill, 'dashboards', 'nav', 'modern-structured.tt' ),
    "===TITLE===\nModern nav title\n===HTML===\n<span>modern-structured</span>\n",
);
my $modern_nav_page = $dispatcher->_load_skill_page(
    skill_name => 'layered',
    route_id   => 'nav/modern-structured.tt',
);
is( $modern_nav_page->{title}, 'Modern nav title',
    '_load_skill_page still parses a modern structured nav document' );
is( $modern_nav_page->{meta}{source_format}, 'modern',
    'modern structured nav keeps its source-format metadata' );

ok( Developer::Dashboard::SkillDispatcher::_looks_like_skill_page_instruction("TITLE: legacy\n"),
    'instruction detector recognizes a legacy header without separators' );
ok( Developer::Dashboard::SkillDispatcher::_looks_like_skill_page_instruction(
        "TITLE: legacy\n$Developer::Dashboard::PageDocument::LEGACY_SEP\nHTML: body\n"),
    'instruction detector recognizes the canonical legacy section separator' );
ok( !Developer::Dashboard::SkillDispatcher::_looks_like_skill_page_instruction(undef),
    'instruction detector rejects undefined content' );
ok( !Developer::Dashboard::SkillDispatcher::_looks_like_skill_page_instruction( [] ),
    'instruction detector rejects reference-valued content' );

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

{
    my $original_skill_layers = Developer::Dashboard::SkillDispatcher->can('_skill_layers');
    my $skill_layer_calls = 0;
    no warnings qw(redefine once);
    local *Developer::Dashboard::SkillDispatcher::_skill_layers = sub {
        $skill_layer_calls++;
        return $original_skill_layers->(@_);
    };
    my $skill_nav_pages = $dispatcher->skill_nav_pages('layered');
    is( scalar @{$skill_nav_pages}, 4, 'skill_nav_pages loads every layered nav template page' );
    is( $skill_layer_calls, 1,
        'skill_nav_pages resolves skill layers once and reuses them for route listing and page loading' );
}
is_deeply( $dispatcher->skill_nav_pages('missing-skill'), [],
    'skill_nav_pages returns an empty list for an uninstalled skill' );

_write_file(
    File::Spec->catfile( $leaf_skill, 'dashboards', 'nav', 'unrecognized-sections.tt' ),
    "---\nnot a recognized page section\n",
);
my $fallback_nav_page = $dispatcher->_load_skill_page(
    skill_name => 'layered',
    route_id   => 'nav/unrecognized-sections.tt',
);
is( $fallback_nav_page->{meta}{source_format}, 'raw-nav-tt',
    '_load_skill_page retains the raw-fragment fallback for unrecognized section-like nav text' );

_write_file(
    File::Spec->catfile( $leaf_skill, 'dashboards', 'nav', 'url.tt' ),
    "https://example.invalid/nav\n",
);
my $nav_url_page = $dispatcher->_load_skill_page(
    skill_name => 'layered',
    route_id   => 'nav/url.tt',
);
is( $nav_url_page->{meta}{source_format}, 'raw-url',
    '_load_skill_page preserves raw URL handling for a nav path' );
is( $nav_url_page->{meta}{raw_url}, 'https://example.invalid/nav',
    'raw nav URL target is preserved without instruction parsing' );

{
    my $original_skill_layers = Developer::Dashboard::SkillDispatcher->can('_skill_layers');
    my $skill_layer_calls = 0;
    no warnings qw(redefine once);
    local *Developer::Dashboard::SkillDispatcher::_skill_layers = sub {
        $skill_layer_calls++;
        return $original_skill_layers->(@_);
    };
    my $page = $dispatcher->_load_skill_page(
        skill_name => 'layered',
        route_id   => 'nav/leaf.tt',
    );
    is( $page->{meta}{skill_name}, 'layered', '_load_skill_page preserves skill metadata with shared layer resolution' );
    is( $skill_layer_calls, 1, '_load_skill_page resolves the skill layers once and reuses them for page lookup and metadata' );
}

my @expected_skill_names = $dispatcher->_all_installed_skill_names;
my $expected_all_nav_pages = [ map { @{ $dispatcher->skill_nav_pages($_) } } @expected_skill_names ];
my $original_skill_layers_for_nav = Developer::Dashboard::SkillDispatcher->can('_skill_layers');
my $all_nav_skill_layer_calls = 0;
my $all_nav_pages;
{
    no warnings qw(redefine once);
    local *Developer::Dashboard::SkillDispatcher::_skill_layers = sub {
        $all_nav_skill_layer_calls++;
        return $original_skill_layers_for_nav->(@_);
    };
    $all_nav_pages = $dispatcher->all_skill_nav_pages;
}
ok( scalar @{$all_nav_pages} >= 2, 'all_skill_nav_pages aggregates nav pages from every installed skill' );
my $nav_page_summaries = sub {
    return [ map { [ $_->{id}, $_->{title}, $_->{layout}{body}, $_->{meta}{skill_path} ] } @{ $_[0] } ];
};
is_deeply( $nav_page_summaries->($all_nav_pages), $nav_page_summaries->($expected_all_nav_pages),
    'all_skill_nav_pages preserves layered and nested page order and content' );
is( $all_nav_skill_layer_calls, 1,
    'all_skill_nav_pages reuses bulk top-level layers and resolves only the nested skill layer' );
{
    my $cache_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $paths ),
        paths   => $paths,
    );
    my $find_solo_page = sub {
        my ($pages) = @_;
        my ($page) = grep {
            ref($_) eq 'Developer::Dashboard::PageDocument'
              && ( $_->{meta}{skill_path} || '' ) eq $solo_skill
              && ( $_->{meta}{skill_route_id} || '' ) eq 'nav/solo.tt'
        } @{$pages};
        return $page;
    };
    my $first_pages = $cache_dispatcher->all_skill_nav_pages;
    my $first_solo = $find_solo_page->($first_pages);
    ok( $first_solo, 'all_skill_nav_pages includes the static solo-skill navigation fragment' );
    my $second_pages = $cache_dispatcher->all_skill_nav_pages;
    my $second_solo = $find_solo_page->($second_pages);
    is( refaddr($second_solo), refaddr($first_solo),
        'unchanged literal skill navigation reuses its parsed page object' );

    sleep 0.01;
    _write_file(
        File::Spec->catfile( $solo_skill, 'dashboards', 'nav', 'solo.tt' ),
        "<div>tira nav</div>\n",
    );
    my $third_pages = $cache_dispatcher->all_skill_nav_pages;
    my $third_solo = $find_solo_page->($third_pages);
    is( $third_solo->{layout}{body}, "<div>tira nav</div>\n",
        'literal skill navigation cache observes an edited file before returning a page' );
    isnt( refaddr($third_solo), refaddr($second_solo),
        'changed literal skill navigation replaces the cached page object' );

    my $added_nav_file = File::Spec->catfile( $solo_skill, 'dashboards', 'nav', 'added.tt' );
    _write_file( $added_nav_file, "<div>added nav</div>\n" );
    my $added_pages = $cache_dispatcher->all_skill_nav_pages;
    ok(
        scalar( grep { ( $_->{meta}{skill_route_id} || '' ) eq 'nav/added.tt' } @{$added_pages} ),
        'literal nav cache observes a newly added skill-nav file',
    );
    unlink $added_nav_file or die "Unable to remove added skill nav fixture '$added_nav_file': $!";
    my $removed_pages = $cache_dispatcher->all_skill_nav_pages;
    ok(
        !scalar( grep { ( $_->{meta}{skill_route_id} || '' ) eq 'nav/added.tt' } @{$removed_pages} ),
        'literal nav cache stops returning a removed skill-nav file',
    );

    my $bad_order_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $paths ),
        paths   => $paths,
    );
    $bad_order_dispatcher->all_skill_nav_pages;
    $bad_order_dispatcher->{_skill_literal_nav_cache}{order} = {};
    my $bad_order_error;
    eval { $bad_order_dispatcher->all_skill_nav_pages; 1 } or $bad_order_error = $@;
    like( $bad_order_error, qr/Malformed literal skill-nav cache order/,
        'malformed literal nav cache order fails explicitly' );

    my $bad_bytes_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $paths ),
        paths   => $paths,
    );
    $bad_bytes_dispatcher->all_skill_nav_pages;
    $bad_bytes_dispatcher->{_skill_literal_nav_cache}{bytes} = 'invalid';
    my $bad_bytes_error;
    eval { $bad_bytes_dispatcher->all_skill_nav_pages; 1 } or $bad_bytes_error = $@;
    like( $bad_bytes_error, qr/Malformed literal skill-nav cache byte count/,
        'malformed literal nav cache byte count fails explicitly' );

    my $bad_entry_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $paths ),
        paths   => $paths,
    );
    $bad_entry_dispatcher->all_skill_nav_pages;
    my ($cached_key) = keys %{ $bad_entry_dispatcher->{_skill_literal_nav_cache}{entries} };
    $bad_entry_dispatcher->{_skill_literal_nav_cache}{entries}{$cached_key}{bytes} = undef;
    my $cached_file = $bad_entry_dispatcher->{_skill_literal_nav_cache}{entries}{$cached_key}{page}{meta}{skill_path};
    my $cached_route = $bad_entry_dispatcher->{_skill_literal_nav_cache}{entries}{$cached_key}{page}{meta}{skill_route_id};
    _write_file(
        File::Spec->catfile( $cached_file, 'dashboards', split( '/', $cached_route ) ),
        "<div>changed invalid entry</div>\n",
    );
    my $bad_entry_error;
    eval { $bad_entry_dispatcher->all_skill_nav_pages; 1 } or $bad_entry_error = $@;
    like( $bad_entry_error, qr/Malformed literal skill-nav cache entry size/,
        'malformed stale literal nav entry size fails explicitly' );
}
{
    require Developer::Dashboard::PageDocument;
    my $cache_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $paths ),
        paths   => $paths,
    );
    my $cache_page = Developer::Dashboard::PageDocument->new(
        id => 'cache-fixture', title => 'cache fixture', layout => { body => 'literal' },
    );

    my $close_error;
    eval {
        $cache_dispatcher->_read_skill_page_instruction(
            File::Spec->catfile( $solo_skill, 'dashboards', 'nav', 'solo.tt' ),
            sub { CORE::close( $_[0] ); $! = 5; return 0 },
        );
        1;
    } or $close_error = $@;
    like( $close_error, qr/Unable to close .*solo\.tt:/,
        'skill-nav instruction reader exposes an explicit close failure' );

    is( Developer::Dashboard::SkillDispatcher::_skill_nav_fingerprint(undef), undef,
        'skill-nav fingerprint rejects a non-array stat result' );
    is( Developer::Dashboard::SkillDispatcher::_skill_nav_fingerprint([ 1 .. 10 ]), undef,
        'skill-nav fingerprint rejects a short stat result' );
    is( $cache_dispatcher->_cached_literal_skill_nav_page( undef, 'fingerprint' ), undef,
        'literal nav cache lookup rejects a missing key' );
    is( $cache_dispatcher->_cached_literal_skill_nav_page( 'key', undef ), undef,
        'literal nav cache lookup rejects a missing fingerprint' );

    $cache_dispatcher->{_skill_literal_nav_cache} = [];
    is( $cache_dispatcher->_cached_literal_skill_nav_page( 'key', 'fingerprint' ), undef,
        'literal nav cache lookup ignores a non-hash cache' );
    $cache_dispatcher->{_skill_literal_nav_cache} = { entries => [], order => [], bytes => 0 };
    is( $cache_dispatcher->_cached_literal_skill_nav_page( 'key', 'fingerprint' ), undef,
        'literal nav cache lookup ignores malformed entries storage' );
    $cache_dispatcher->{_skill_literal_nav_cache} = { entries => {}, order => [], bytes => undef };
    my $undefined_cache_bytes_error;
    eval { $cache_dispatcher->_cached_literal_skill_nav_page( 'key', 'fingerprint' ); 1 }
      or $undefined_cache_bytes_error = $@;
    like( $undefined_cache_bytes_error, qr/Malformed literal skill-nav cache byte count/,
        'literal nav cache lookup rejects an undefined byte count' );
    $cache_dispatcher->{_skill_literal_nav_cache} = { entries => {}, order => [], bytes => 0 };
    is( $cache_dispatcher->_cached_literal_skill_nav_page( 'key', 'fingerprint' ), undef,
        'literal nav cache lookup misses an absent key' );

    my $entry_cache = $cache_dispatcher->{_skill_literal_nav_cache};
    $entry_cache->{entries}{key} = { fingerprint => 'fingerprint', page => {}, bytes => 0 };
    is( $cache_dispatcher->_cached_literal_skill_nav_page( 'key', 'fingerprint' ), undef,
        'literal nav cache rejects an entry with the wrong page type' );
    $entry_cache->{entries}{key} = { fingerprint => undef, page => $cache_page, bytes => 0 };
    is( $cache_dispatcher->_cached_literal_skill_nav_page( 'key', 'fingerprint' ), undef,
        'literal nav cache invalidates an entry without a fingerprint' );
    $entry_cache->{entries}{key} = { fingerprint => 'stale', page => $cache_page, bytes => 'invalid' };
    my $invalid_entry_bytes_error;
    eval { $cache_dispatcher->_cached_literal_skill_nav_page( 'key', 'fingerprint' ); 1 }
      or $invalid_entry_bytes_error = $@;
    like( $invalid_entry_bytes_error, qr/Malformed literal skill-nav cache entry size/,
        'literal nav cache rejects a non-numeric stale entry size' );

    for my $invalid ( [ undef, 'fingerprint', $cache_page, 1 ],
        [ 'key', undef, $cache_page, 1 ],
        [ 'key', 'fingerprint', {}, 1 ],
        [ 'key', 'fingerprint', $cache_page, undef ],
        [ 'key', 'fingerprint', $cache_page, 'invalid' ] )
    {
        is( $cache_dispatcher->_cache_literal_skill_nav_page(@{$invalid}), 0,
            'literal nav cache declines invalid insertion arguments' );
    }

    my $invalid_inner_cache = { entries => [], order => [], bytes => 0 };
    $cache_dispatcher->{_skill_literal_nav_cache} = $invalid_inner_cache;
    is( $cache_dispatcher->_cache_literal_skill_nav_page( 'key', 'fingerprint', $cache_page, 1 ), 0,
        'literal nav cache declines malformed entries storage' );
    $cache_dispatcher->{_skill_literal_nav_cache} = { entries => {}, order => {}, bytes => 0 };
    is( $cache_dispatcher->_cache_literal_skill_nav_page( 'key', 'fingerprint', $cache_page, 1 ), 0,
        'literal nav cache declines malformed insertion order' );
    $cache_dispatcher->{_skill_literal_nav_cache} = { entries => {}, order => [], bytes => undef };
    is( $cache_dispatcher->_cache_literal_skill_nav_page( 'key', 'fingerprint', $cache_page, 1 ), 0,
        'literal nav cache declines an undefined insertion byte count' );
    $cache_dispatcher->{_skill_literal_nav_cache} = { entries => {}, order => [], bytes => 'invalid' };
    is( $cache_dispatcher->_cache_literal_skill_nav_page( 'key', 'fingerprint', $cache_page, 1 ), 0,
        'literal nav cache declines a non-numeric insertion byte count' );

    $cache_dispatcher->{_skill_literal_nav_cache} = { entries => {}, order => [], bytes => 0 };
    ok( $cache_dispatcher->_cache_literal_skill_nav_page( 'key', 'fingerprint', $cache_page, 1 ),
        'literal nav cache accepts valid insertion arguments' );
    ok( $cache_dispatcher->_cache_literal_skill_nav_page( 'key', 'new-fingerprint', $cache_page, 2 ),
        'literal nav cache replaces an existing valid entry' );
    is( $cache_dispatcher->{_skill_literal_nav_cache}{bytes}, 2,
        'literal nav cache replacement keeps its byte accounting exact' );
    $cache_dispatcher->{_skill_literal_nav_cache} = { bytes => 0, entries => {}, order => [] };
    $cache_dispatcher->_cache_literal_skill_nav_page( 'zero-byte', 'fingerprint', $cache_page, 0 );
    $cache_dispatcher->_cache_literal_skill_nav_page( 'zero-byte', 'fingerprint-2', $cache_page, 1 );
    is( $cache_dispatcher->{_skill_literal_nav_cache}{bytes}, 1,
        'literal nav cache replacement handles a zero-byte prior entry' );
    $cache_dispatcher->{_skill_literal_nav_cache}{entries}{key} = 'stale';
    $cache_dispatcher->{_skill_literal_nav_cache}{bytes} = 0;
    ok( $cache_dispatcher->_cache_literal_skill_nav_page( 'key', 'fingerprint', $cache_page, 1 ),
        'literal nav cache replaces a malformed stale entry without byte metadata' );

    $cache_dispatcher->{_skill_literal_nav_cache} = { bytes => 0, entries => {}, order => [] };
    for my $index ( 1 .. 257 ) {
        $cache_dispatcher->_cache_literal_skill_nav_page( "route-$index", 'fingerprint', $cache_page, 0 );
    }
    is( scalar @{ $cache_dispatcher->{_skill_literal_nav_cache}{order} }, 256,
        'literal nav cache enforces its FIFO entry bound' );
    ok( !exists $cache_dispatcher->{_skill_literal_nav_cache}{entries}{'route-1'},
        'literal nav cache evicts the oldest route first' );
    is( $cache_dispatcher->{_skill_literal_nav_cache}{bytes}, 0,
        'literal nav eviction keeps zero-byte entry accounting exact' );

    my %orphaned_cache_entries = map {
        ( "route-$_" => { fingerprint => 'fingerprint', page => $cache_page, bytes => 0 } )
    } 1 .. 255;
    $cache_dispatcher->{_skill_literal_nav_cache} = {
        bytes   => 0,
        entries => \%orphaned_cache_entries,
        order   => [ 'orphaned-route', map { "route-$_" } 1 .. 255 ],
    };
    ok( $cache_dispatcher->_cache_literal_skill_nav_page( 'route-256', 'fingerprint', $cache_page, 0 ),
        'literal nav cache tolerates a stale FIFO key during eviction' );
    is( scalar @{ $cache_dispatcher->{_skill_literal_nav_cache}{order} }, 256,
        'literal nav cache removes the stale FIFO key without evicting a live entry' );

    my %malformed_fifo_entries = map {
        ( "route-$_" => { fingerprint => 'fingerprint', page => $cache_page, bytes => 0 } )
    } 1 .. 255;
    $malformed_fifo_entries{'route-1'} = 'malformed';
    $cache_dispatcher->{_skill_literal_nav_cache} = {
        bytes   => 0,
        entries => \%malformed_fifo_entries,
        order   => [ map { "route-$_" } 1 .. 256 ],
    };
    ok( $cache_dispatcher->_cache_literal_skill_nav_page( 'route-257', 'fingerprint', $cache_page, 0 ),
        'literal nav cache can evict a malformed FIFO entry' );
    ok( !exists $cache_dispatcher->{_skill_literal_nav_cache}{entries}{'route-1'},
        'literal nav cache removes a malformed FIFO entry without byte metadata' );

    $cache_dispatcher->{_skill_literal_nav_cache} = { bytes => 0, entries => {}, order => [] };
    $cache_dispatcher->_cache_literal_skill_nav_page( 'oversized', 'fingerprint', $cache_page, 8_388_609 );
    is( $cache_dispatcher->{_skill_literal_nav_cache}{bytes}, 0,
        'literal nav cache evicts an entry exceeding its byte bound' );

    my $invalid_stat_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new( paths => $paths ),
        paths   => $paths,
    );
    _write_file(
        File::Spec->catfile( $solo_skill, 'dashboards', 'nav', 'solo.tt' ),
        "<div>no stat metadata</div>\n",
    );
    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::SkillDispatcher::_page_location = sub {
            my ( $self, $skill_name, $route_id ) = @_;
            return ( File::Spec->catfile( $solo_skill, 'dashboards', 'nav', 'solo.tt' ), $solo_skill, 'stat' );
        };
        my $page = $invalid_stat_dispatcher->_load_skill_page(
            skill_name => 'solo-skill', route_id => 'nav/solo.tt', layers => [$solo_skill], cache_literal_nav => 1,
        );
        is( $page->{layout}{body}, "<div>no stat metadata</div>\n",
            'literal skill-nav loading still serves content if path resolution has no stat array' );
        is( $invalid_stat_dispatcher->{_skill_literal_nav_cache}, undef,
            'literal skill-nav loading skips caching when path stat metadata is unavailable' );
    }

    my $non_nav_page = $invalid_stat_dispatcher->_load_skill_page(
        skill_name => 'leaf-skill', route_id => 'index', layers => [$leaf_skill], cache_literal_nav => 1,
    );
    ok( $non_nav_page, 'cache opt-in does not alter ordinary skill bookmark loading' );

    my $structured_nav = File::Spec->catfile( $solo_skill, 'dashboards', 'nav', 'structured.tt' );
    _write_file( $structured_nav, "=== HTML ===\n<div>structured nav</div>\n" );
    my $structured_page = $invalid_stat_dispatcher->_load_skill_page(
        skill_name => 'solo-skill', route_id => 'nav/structured.tt', layers => [$solo_skill], cache_literal_nav => 1,
    );
    is( $structured_page->{meta}{source_format}, 'modern',
        'structured skill-nav documents retain the normal instruction parser' );
    ok( !defined $invalid_stat_dispatcher->{_skill_literal_nav_cache},
        'structured skill-nav documents are not cached as literal pages' );

    my $unknown_format_file = File::Spec->catfile( $solo_skill, 'dashboards', 'nav', 'unknown-format.tt' );
    _write_file( $unknown_format_file, "=== HTML ===\n<div>unknown format</div>\n" );
    my $unknown_format_page;
    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::PageDocument::from_instruction = sub {
            return Developer::Dashboard::PageDocument->new(
                id => 'unknown-format', layout => { body => 'unknown format' }, meta => {},
            );
        };
        $unknown_format_page = $invalid_stat_dispatcher->_load_skill_page(
            skill_name => 'solo-skill', route_id => 'nav/unknown-format.tt', layers => [$solo_skill],
            cache_literal_nav => 1,
        );
    }
    ok( $unknown_format_page, 'unclassified skill-nav pages keep their normal uncached load path' );

    my $dynamic_nav = File::Spec->catfile( $solo_skill, 'dashboards', 'nav', 'dynamic.tt' );
    _write_file( $dynamic_nav, '<span>[% title %]</span>\n' );
    my $dynamic_page = $invalid_stat_dispatcher->_load_skill_page(
        skill_name => 'solo-skill', route_id => 'nav/dynamic.tt', layers => [$solo_skill], cache_literal_nav => 1,
    );
    is( $dynamic_page->{meta}{source_format}, 'raw-nav-tt',
        'dynamic skill-nav source remains a raw template fragment' );
    ok( !defined $invalid_stat_dispatcher->{_skill_literal_nav_cache},
        'dynamic skill-nav fragments do not enter the literal cache' );

    my @missing_nav_location = $dispatcher->_page_location( 'solo-skill', 'nav/missing.tt', layers => [$solo_skill] );
    is( scalar @missing_nav_location, 0,
        'page lookup returns no location when a nav file is missing' );
    my $directory_route = File::Spec->catdir( $solo_skill, 'dashboards', 'nav', 'directory.tt' );
    make_path($directory_route);
    my @directory_nav_location = $dispatcher->_page_location(
        'solo-skill', 'nav/directory.tt', layers => [$solo_skill]
    );
    is( scalar @directory_nav_location, 0,
        'page lookup rejects a directory whose name has a nav-file suffix' );
}
my $empty_nav_skill = File::Spec->catdir( $root, 'empty-nav-skill' );
make_path($empty_nav_skill);
is_deeply( $dispatcher->_skill_nav_pages_for_layers( 'empty-nav-skill', [$empty_nav_skill] ), [],
    '_skill_nav_pages_for_layers returns an empty list when no nav routes exist' );
is_deeply( $dispatcher->_skill_nav_pages_for_layers( 'leaf-skill', [] ), [],
    '_skill_nav_pages_for_layers returns an empty list when the layer list is empty' );
is_deeply( $dispatcher->_skill_nav_pages_for_layers( 'leaf-skill', undef ), [],
    '_skill_nav_pages_for_layers returns an empty list when layers are not an array' );
is_deeply( $dispatcher->_skill_nav_pages_for_layers( '', [] ), [],
    '_skill_nav_pages_for_layers returns an empty list when the skill name is empty' );

my $legacy_paths = Local::LegacySkillPaths->new(
    [ $leaf_skill ],
    { 'leaf-skill' => [ $leaf_skill ] },
);
my $legacy_dispatcher = Developer::Dashboard::SkillDispatcher->new(
    manager => Local::SkillManager->new( paths => $legacy_paths ),
);
my $legacy_pages = $legacy_dispatcher->all_skill_nav_pages;
ok( scalar( grep { ( $_->{meta}{skill_name} || '' ) eq 'leaf-skill' } @{$legacy_pages} ),
    'all_skill_nav_pages retains the root-enumeration fallback for path registries without bulk entries' );

for my $invalid_entry (
    [],
    { skill_root => $leaf_skill, layers => [] },
    { skill_name => 'invalid', layers => [] },
    { skill_name => 'invalid', skill_root => $leaf_skill, layers => undef },
  )
{
    my $invalid_inventory_dispatcher = Developer::Dashboard::SkillDispatcher->new(
        manager => Local::SkillManager->new(
            paths => Local::InvalidSkillEntriesPaths->new( [$invalid_entry] ),
        ),
    );
    my $invalid_inventory_result = eval { $invalid_inventory_dispatcher->all_skill_nav_pages; 1 };
    ok( !$invalid_inventory_result, 'all_skill_nav_pages rejects malformed bulk inventory entries' );
    like( $@, qr/Invalid installed skill entry for nav discovery/,
        'malformed bulk inventory failure remains explicit' );
}

my $missing_nav_paths_dispatcher = Developer::Dashboard::SkillDispatcher->new(
    manager => Local::SkillManager->new( paths => undef ),
);
my $missing_nav_paths_result = eval { $missing_nav_paths_dispatcher->all_skill_nav_pages; 1 };
ok( !$missing_nav_paths_result, 'all_skill_nav_pages rejects a missing paths registry' );
like( $@, qr/Skill paths are required for nav discovery/,
    'missing paths registry failure is explicit' );
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
It also verifies literal skill-nav page cache fingerprint rejection and
same-size edit detection, plus route-inventory cache freshness after additions,
removals, nested-directory deletion, and a directory change during scanning.
Malformed cache structures fail explicitly, cache size constraints are
enforced, the 128-root FIFO retains its oldest-first eviction behavior, and
the inventory-derived path fast path rejects malformed and unsafe segments.
Aggregate literal-nav snapshots are tested for event-free reuse, runtime-root
identity changes, edited/added/removed routes, watcher setup and read failures,
portable fallback when native watching is unavailable, and watcher cleanup at
dispatcher destruction. Literal-nav HTML assembly and aggregate caching also
reject otherwise literal page documents that carry executable code sections.
The aggregate inventory-path filtering check injects a watcher so it remains
independent of the optional platform-specific FFI backend.
An isolated subprocess changes directory before first watcher construction to
verify that lazy module loading does not depend on relative C<@INC> entries.
Empty CODE-section arrays remain eligible for literal-nav caching because they
carry no executable work.
Same-length runtime-root mutations and watcher disappearance invalidate cached
snapshots, while false, exceptional, and diagnosed watcher-close failures stay
visible and release dispatcher state.
An empty close-diagnostic accessor is tested separately from a watcher that
does not implement the optional diagnostic method, and both use the explicit
unknown-failure message.

=cut
