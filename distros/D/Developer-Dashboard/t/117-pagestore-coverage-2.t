#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Cwd qw(abs_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;

# Hermetic runtime: HOME and the cwd both point at a throwaway layer so the
# dashboards roots resolve inside the temporary tree only.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
delete local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
delete local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT};
chdir $home or die "Unable to chdir to $home: $!";

my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
my $store = Developer::Dashboard::PageStore->new( paths => $paths );
my $root  = $paths->dashboards_root;
ok( -d $root, 'dashboards root exists inside the temporary home layer' );

# Baseline: the descriptor-based write/read path runs for both open modes so
# the shared dup-mode selection is exercised in this run as well.
{
    my $file = $store->save_page(
        {
            id     => 'coverage/openat-page.tt',
            title  => 'Openat page',
            layout => { body => 'body text' },
        }
    );
    ok( -f $file, 'save_page writes through the no-follow descriptor path' );
    my $loaded = $store->load_saved_page('coverage/openat-page.tt');
    is( $loaded->as_hash->{title}, 'Openat page', 'saved page reloads through the read descriptor path' );
}

# A dashboards root whose own parent directory is missing cannot be resolved,
# so abs_path() yields undef and containment must skip that root instead of
# comparing against an unresolved path.
{
    my $missing_root = File::Spec->catdir( $home, 'absent-layer', 'dashboards' );
    ok( !defined abs_path($missing_root), 'unresolvable root really has no abs_path' );

    my $probe = File::Spec->catfile( $missing_root, 'page.tt' );
    my $err = do {
        local $@;
        eval { $store->_assert_page_path_contained( $probe, root => $missing_root ); 1 } ? '' : $@;
    };
    like( $err, qr/Invalid page path/, 'containment refuses a page under an unresolvable dashboards root' );
}

# A write walk that climbs out of a not-yet-created path must stop at a
# dangling symlink ancestor: the link itself does not exist as a target, so a
# plain -e test would keep climbing past the component that escapes the root.
{
    my $escape = File::Spec->catdir( $home, 'outside-target' );
    my $link   = File::Spec->catdir( $root, 'dangling' );
    symlink $escape, $link or die "Unable to create dangling symlink $link: $!";

    ok( !-e $link, 'the dangling ancestor does not exist' );
    ok( -l $link,  'the dangling ancestor is a symlink' );

    my $target = File::Spec->catfile( $link, 'page.tt' );
    ok( !-e $target && !-l $target, 'the write target beneath the dangling ancestor is absent' );

    my $err = do {
        local $@;
        eval {
            $store->_assert_page_path_contained( $target, root => $root, for_write => 1 );
            1;
        } ? '' : $@;
    };
    like( $err, qr/Invalid page path/,
        'a write through a dangling symlink ancestor that escapes the root is refused' );
    ok( !-e $escape, 'the refused write created nothing outside the dashboards root' );
}

# The same containment walk still accepts a nested write target whose nearest
# existing ancestor is a real directory inside the root.
{
    my $target = File::Spec->catfile( $root, 'deeper', 'nested', 'page.tt' );
    ok(
        $store->_assert_page_path_contained( $target, root => $root, for_write => 1 ),
        'containment accepts a new nested write target inside the root'
    );
}

done_testing;

__END__

=pod

=head1 NAME

t/117-pagestore-coverage-2.t - page-store containment coverage for unresolvable roots and dangling ancestors

=head1 PURPOSE

This test pins the two path-containment decisions the page store makes before
it follows a bookmark path: what happens when a configured dashboards root
cannot be resolved at all, and where the write-time ancestor walk has to stop
when the nearest existing component is a dangling symlink. Both are asserted as
observable refusals of the page path rather than as internal state.

=head1 WHY IT EXISTS

It exists because those two decisions are the last line of defence against a
saved bookmark write escaping the dashboards tree, and neither was reachable
from the higher-level page tests. An unresolvable root must be skipped instead
of silently comparing against an unresolved string, and the ancestor walk must
treat a dangling symlink as an existing component so containment is judged on
the link, not on some directory further up the tree.

=head1 WHEN TO USE

Use this file when changing bookmark path containment, the write-time ancestor
walk, dashboards root resolution, or the symlink-refusing descriptor open path
in the page store.

=head1 HOW TO USE

Run it directly with the checkout library path, or as part of the suite:

  perl -Ilib t/117-pagestore-coverage-2.t
  prove -lv t/117-pagestore-coverage-2.t

It builds its own temporary home layer, so it needs no fixtures and leaves
nothing behind.

=head1 WHAT USES IT

The repository test suite runs it as part of the page-store regression set,
alongside the broader saved-bookmark tests, and the coverage gate relies on it
for the containment branches in the page store.

=head1 EXAMPLES

Example 1:

  perl -Ilib t/117-pagestore-coverage-2.t

Run this containment regression on its own while editing the page store.

Example 2:

  prove -lv t/117-pagestore-coverage-2.t t/14-coverage-closure-extra.t

Run it with the wider page-store closure test after touching path handling.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Re-check the page store's branch and condition coverage under the repository
coverage gate.

=cut
