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

for my $dir (
    File::Spec->catdir( $base_skill, 'dashboards', 'nav' ),
    File::Spec->catdir( $leaf_skill, 'dashboards', 'nav' ),
    File::Spec->catdir( $leaf_skill, 'config' ),
    File::Spec->catdir( $solo_skill, 'dashboards', 'nav' ),
)
{
    make_path($dir);
}

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
    File::Spec->catfile( $base_skill, 'dashboards', 'nav', 'base.tt' ),
    "<div>base nav</div>\n",
);
_write_file(
    File::Spec->catfile( $leaf_skill, 'dashboards', 'nav', 'leaf.tt' ),
    "<div>leaf nav</div>\n",
);
_write_file(
    File::Spec->catfile( $leaf_skill, 'config', 'config.json' ),
    qq|{"indicator":{"icon":"leaf"},"collectors":[{"name":"alpha","interval":20}],"providers":[{"id":"main","title":"Leaf"}]}\n|,
);
_write_file(
    File::Spec->catfile( $solo_skill, 'dashboards', 'nav', 'solo.tt' ),
    "<div>solo nav</div>\n",
);

my $paths = Local::SkillPaths->new(
    home      => $root,
    layers    => {
        layered   => [ $base_skill, $leaf_skill ],
        'leaf-skill' => [$leaf_skill],
        'solo-skill' => [$solo_skill],
        solo      => [$solo_skill],
    },
    installed => [ $leaf_skill, $solo_skill ],
);
my $manager = Local::SkillManager->new( paths => $paths );
my $dispatcher = Developer::Dashboard::SkillDispatcher->new( manager => $manager );

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
    { $dispatcher->_skill_nav_route_ids('layered') },
    {
        'base.tt' => 'nav/base.tt',
        'leaf.tt' => 'nav/leaf.tt',
    },
    '_skill_nav_route_ids exposes layered nav templates as route ids',
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
