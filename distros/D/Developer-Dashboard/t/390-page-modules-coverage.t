#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Fcntl qw(O_RDONLY);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::PageDocument;
use Developer::Dashboard::PageResolver;
use Developer::Dashboard::PageRuntime;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Prompt;

my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
delete local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
delete local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT};
chdir $home or die "chdir $home: $!";

# PageDocument: an empty HEAD string is omitted from the legacy instruction.
{
    my $doc = Developer::Dashboard::PageDocument->from_hash( { id => 'h', title => 'T', meta => { head => '' } } );
    unlike( $doc->legacy_instruction, qr/^HEAD:/m, 'empty head metadata emits no HEAD section' );
}

# PageResolver: only an exact not-found falls through to providers.
{
    my $pages = bless {}, 'Local::DyingPages';
    {
        package Local::DyingPages;
        sub load_saved_page { die "parse exploded\n" }
    }
    my $resolver = Developer::Dashboard::PageResolver->new(
        config => {}, pages => $pages, paths => {}, actions => {},
    );
    my $report = [];
    eval { $resolver->load_named_page( 'boom', $report ) };
    like( $@, qr/parse exploded/, 'non-not-found saved page errors surface unchanged' );
    eval { $resolver->load_named_page('boom') };
    like( $@, qr/parse exploded/, 'same without a report' );
}

# PageRuntime: include roots.
{
    package Local::OddPaths;
    sub new { bless { d => $_[1], r => $_[2] }, $_[0] }
    sub dashboards_roots { @{ $_[0]{d} } }
    sub runtime_roots { @{ $_[0]{r} } }
}
{
    my $paths = Local::OddPaths->new( [ undef, '', 'a', 'a' ], ['a', 'b'] );
    my $rt = Developer::Dashboard::PageRuntime->new( paths => $paths );
    is_deeply( [ $rt->_template_include_roots(undef) ], [ 'a', 'b' ], 'undef page, blank and duplicate roots are dropped' );
    my $page = { meta => { skill_path => '' } };
    is_deeply( [ $rt->_template_include_roots($page) ], [ 'a', 'b' ], 'empty skill_path adds no root' );
    is_deeply( [ $rt->_template_include_roots( { meta => 'x' } ) ], [ 'a', 'b' ], 'non-hash meta tolerated' );
    my $none = Developer::Dashboard::PageRuntime->new( paths => Local::OddPaths->new( [], [] ) );
    is_deeply( [ $none->_template_include_roots(undef) ], ['.'], 'no roots falls back to dot' );
}

# PageRuntime: code inc roots and env overlay.
{
    my $rt = Developer::Dashboard::PageRuntime->new();
    my $skill = File::Spec->catdir( $home, 'skill-a' );
    my $layer = File::Spec->catdir( $home, 'layer-b' );
    my $bare  = File::Spec->catdir( $home, 'layer-c' );
    make_path( File::Spec->catdir( $skill, 'lib' ), File::Spec->catdir( $layer, 'lib' ), $bare );
    is_deeply(
        [ $rt->_code_inc_roots( { meta => { skill_path => $skill, skill_layers => [ $bare, $layer, $skill ] } } ) ],
        [ File::Spec->catdir( $skill, 'lib' ), File::Spec->catdir( $layer, 'lib' ) ],
        'page lib first, then layer libs, skipping missing and duplicate ones',
    );
    is_deeply( [ $rt->_code_inc_roots( { meta => { skill_path => '' } } ) ], [], 'empty skill_path yields no roots' );
    is_deeply( $rt->_code_env_overlay( { meta => { skill_path => '' } } ), {}, 'empty skill_path yields no env overlay' );
    {
        no warnings 'redefine';
        local *Developer::Dashboard::EnvLoader::load_skill_layers_into_hash = sub { return {} };
        is_deeply( $rt->_skill_env_overlay( [$skill] ), {}, 'loader without env key yields empty overlay' );
    }
}

# PageStore.
{
    my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
    my $store = Developer::Dashboard::PageStore->new( paths => $paths );
    my $root  = $paths->dashboards_root;

    my $gone = Developer::Dashboard::PageStore->new( paths => Local::OddStorePaths->new( File::Spec->catdir( $home, 'nope' ) ) );
    is_deeply( $gone->migrate_legacy_json_pages, [], 'missing dashboards root migrates nothing' );

    open my $fh, '>', File::Spec->catfile( $root, 'legacy.json' ) or die $!;
    print {$fh} '{"id":"legacy","title":"L"}';
    close $fh;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PageStore::_open_saved_page_for_read = sub { die "unreadable\n" };
        is_deeply( $store->migrate_legacy_json_pages, [], 'unreadable legacy json is skipped' );
    }
    ok( -f File::Spec->catfile( $root, 'legacy.json' ), 'skipped file remains' );

    eval { $store->_open_saved_page_at( root => $root, id => 'missing-page', flags => O_RDONLY ) };
    like( $@, qr/Invalid page path/, 'reading a missing page file fails' );
}

{
    package Local::OddStorePaths;
    sub new { bless { r => $_[1] }, $_[0] }
    sub dashboards_root { $_[0]{r} }
    sub dashboards_roots { $_[0]{r} }
}

done_testing;

__END__

=pod

=head1 NAME

t/390-page-modules-coverage.t - closes the remaining coverage gaps in the page modules

=head1 PURPOSE

Exercises the last uncovered branches and conditions of PageDocument (empty HEAD
metadata), PageResolver (non-not-found saved-page failures surface), PageRuntime
(template include roots, code inc roots and skill env overlays with empty,
duplicate and missing inputs) and PageStore (missing dashboards root, unreadable
legacy files, missing page file).

=head1 WHY IT EXISTS

These guard clauses are unreachable through ordinary save and render flows, so
this file reaches them directly to keep the modules at full coverage.

=head1 WHEN TO USE

Use it when changing page document, resolver, runtime or store guard logic.

=head1 HOW TO USE

Run C<prove -lv t/390-page-modules-coverage.t>.

=head1 WHAT USES IT

The repository test suite and the coverage gate.

=head1 EXAMPLES

Example 1:

  prove -lv t/390-page-modules-coverage.t

=cut
