#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PageDocument;
use Developer::Dashboard::SeedSync ();
use Developer::Dashboard::CLI::SeededPages;

# A mock paths registry that exposes only config_root, so _write_manifest's
# capability guard around secure_file_permissions can take its skip branch, and
# so failure-injection tests can point the manifest file at a chosen directory.
{
    package Test::PathsNoSecure;
    sub new         { my ( $class, %args ) = @_; return bless { root => $args{root} }, $class }
    sub config_root { return $_[0]{root} }
}

# A mock page store whose read_saved_entry raises an error that is NOT the
# "not found" sentinel, so ensure_seeded_page must re-throw it unchanged.
{
    package Test::PagesReadBoom;
    sub new             { return bless {}, $_[0] }
    sub read_saved_entry { die "backend read exploded\n" }
}

# Warning collector: this repository treats warnings as errors, so any warning
# emitted while exercising the module must fail the test.
my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

# Hermetic runtime rooted in a throwaway home; config resolution walks up from
# the current working directory, so we must actually chdir into the temp home.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
my $store = Developer::Dashboard::PageStore->new( paths => $paths );

my $SP = 'Developer::Dashboard::CLI::SeededPages';

# --------------------------------------------------------------------------
# Argument-guard die paths ("|| die"): every required-argument short circuit.
# --------------------------------------------------------------------------
{
    my $err = eval { $SP->can('seed_manifest_path')->(); 1 } ? '' : $@;
    like( $err, qr/Missing paths registry/, 'seed_manifest_path dies without a paths registry' );

    $err = eval { $SP->can('ensure_seeded_page')->(); 1 } ? '' : $@;
    like( $err, qr/Missing page store/, 'ensure_seeded_page dies without a page store' );

    $err = eval { $SP->can('ensure_seeded_page')->( pages => $store ); 1 } ? '' : $@;
    like( $err, qr/Missing paths registry/, 'ensure_seeded_page dies without a paths registry' );

    $err = eval { $SP->can('ensure_seeded_page')->( pages => $store, paths => $paths ); 1 } ? '' : $@;
    like( $err, qr/Missing seeded page/, 'ensure_seeded_page dies without a page' );

    $err = eval {
        $SP->can('ensure_seeded_page')->(
            pages => $store,
            paths => $paths,
            page  => { id => '', title => 'No Id', layout => { body => 'b' } },
        );
        1;
    } ? '' : $@;
    like( $err, qr/Missing seeded page id/, 'ensure_seeded_page dies when the page has no id' );

    $err = eval { $SP->can('_write_manifest')->( manifest => {} ); 1 } ? '' : $@;
    like( $err, qr/Missing paths registry/, '_write_manifest dies without a paths registry' );

    $err = eval { $SP->can('_record_manifest_md5')->(); 1 } ? '' : $@;
    like( $err, qr/Missing paths registry/, '_record_manifest_md5 dies without a paths registry' );

    $err = eval { $SP->can('_record_manifest_md5')->( paths => $paths ); 1 } ? '' : $@;
    like( $err, qr/Missing seeded page id/, '_record_manifest_md5 dies without an id' );

    $err = eval { $SP->can('_record_manifest_md5')->( paths => $paths, id => 'x' ); 1 } ? '' : $@;
    like( $err, qr/Missing seeded page md5/, '_record_manifest_md5 dies without an md5' );

    $err = eval { $SP->can('_manifest_md5_matches')->(); 1 } ? '' : $@;
    like( $err, qr/Missing paths registry/, '_manifest_md5_matches dies without a paths registry' );
}

# --------------------------------------------------------------------------
# is_known_managed_page_md5: empty-md5 short circuit and a non-empty digest.
# --------------------------------------------------------------------------
{
    is( $SP->can('is_known_managed_page_md5')->( id => 'known' ), 0,
        'is_known_managed_page_md5 returns 0 for an empty md5' );
    is( $SP->can('is_known_managed_page_md5')->( id => 'known', md5 => 'abc123' ), 0,
        'is_known_managed_page_md5 returns 0 for an unrecognized non-empty md5' );
}

# --------------------------------------------------------------------------
# ensure_seeded_page happy statuses against a real page store: created,
# current, updated (manifest-matched refresh), and preserved (user divergence).
# --------------------------------------------------------------------------
{
    my $created_page = Developer::Dashboard::PageDocument->new(
        id     => 'seed-one',
        title  => 'Seed One',
        layout => { body => 'created body' },
    );
    is(
        $SP->can('ensure_seeded_page')->( pages => $store, paths => $paths, page => $created_page ),
        'created',
        'ensure_seeded_page writes a brand new managed page',
    );
    is(
        $SP->can('ensure_seeded_page')->( pages => $store, paths => $paths, page => $created_page ),
        'current',
        'ensure_seeded_page reports an unchanged managed page as current',
    );

    my $v1 = Developer::Dashboard::PageDocument->new(
        id     => 'seed-upd',
        title  => 'Version One',
        layout => { body => 'version one body' },
    );
    is(
        $SP->can('ensure_seeded_page')->( pages => $store, paths => $paths, page => $v1 ),
        'created',
        'ensure_seeded_page seeds the refresh candidate on first write',
    );
    my $v2 = Developer::Dashboard::PageDocument->new(
        id     => 'seed-upd',
        title  => 'Version Two',
        layout => { body => 'version two body' },
    );
    is(
        $SP->can('ensure_seeded_page')->( pages => $store, paths => $paths, page => $v2 ),
        'updated',
        'ensure_seeded_page refreshes a managed page still matching the recorded manifest md5',
    );

    # A user-edited page whose md5 was never recorded in the manifest must be
    # preserved rather than overwritten.
    $store->save_page(
        Developer::Dashboard::PageDocument->new(
            id     => 'seed-pres',
            title  => 'User Edited',
            layout => { body => 'hand edited by user' },
        )
    );
    is(
        $SP->can('ensure_seeded_page')->(
            pages => $store,
            paths => $paths,
            page  => Developer::Dashboard::PageDocument->new(
                id     => 'seed-pres',
                title  => 'Shipped Version',
                layout => { body => 'freshly shipped body' },
            ),
        ),
        'preserved',
        'ensure_seeded_page preserves a diverged user-edited managed page',
    );
}

# --------------------------------------------------------------------------
# ensure_seeded_page re-throws a non-"not found" backend read failure.
# --------------------------------------------------------------------------
{
    my $real_page = Developer::Dashboard::PageDocument->new(
        id     => 'boom-page',
        title  => 'Boom',
        layout => { body => 'boom body' },
    );
    my $err = eval {
        $SP->can('ensure_seeded_page')->(
            pages => Test::PagesReadBoom->new,
            paths => $paths,
            page  => $real_page,
        );
        1;
    } ? '' : $@;
    like( $err, qr/backend read exploded/,
        'ensure_seeded_page re-throws read failures that are not the not-found sentinel' );
}

# --------------------------------------------------------------------------
# _manifest_md5_matches: empty-id and empty-md5 short circuits, plus a real
# lookup where the manifest holds no digest for the requested id.
# --------------------------------------------------------------------------
{
    is( $SP->can('_manifest_md5_matches')->( paths => $paths, md5 => 'abcdef' ), 0,
        '_manifest_md5_matches returns 0 when the id is empty' );
    is( $SP->can('_manifest_md5_matches')->( paths => $paths, id => 'seed-missing' ), 0,
        '_manifest_md5_matches returns 0 when the md5 is empty' );
    is( $SP->can('_manifest_md5_matches')->( paths => $paths, id => 'seed-absent', md5 => 'deadbeef' ), 0,
        '_manifest_md5_matches returns 0 when the manifest has no digest recorded for the id' );
}

# --------------------------------------------------------------------------
# _read_manifest edge cases driven through mock paths and hand-written files.
# --------------------------------------------------------------------------
my $mock_index = 0;
my $write_manifest_file = sub {
    my ($content) = @_;
    $mock_index++;
    my $root = File::Spec->catdir( $home, "mock-config-$mock_index" );
    make_path($root);
    my $file = File::Spec->catfile( $root, 'seeded-pages.json' );
    open my $fh, '>:raw', $file or die "Unable to seed $file: $!";
    print {$fh} $content if length $content;
    close $fh or die "Unable to close $file: $!";
    return ( Test::PathsNoSecure->new( root => $root ), $file );
};

{
    my ($mock_paths) = $write_manifest_file->('');
    is_deeply( $SP->can('_read_manifest')->( paths => $mock_paths ), {},
        '_read_manifest treats an empty manifest file as an empty hash' );
}
{
    my ($mock_paths) = $write_manifest_file->("   \n\t  ");
    is_deeply( $SP->can('_read_manifest')->( paths => $mock_paths ), {},
        '_read_manifest treats a whitespace-only manifest file as an empty hash' );
}
{
    my ($mock_paths) = $write_manifest_file->('{"seed":{"asset":"seed","md5":"cafe"}}');
    is_deeply(
        $SP->can('_read_manifest')->( paths => $mock_paths ),
        { seed => { asset => 'seed', md5 => 'cafe' } },
        '_read_manifest decodes a populated manifest hash',
    );
}
{
    my ($mock_paths) = $write_manifest_file->('[]');
    my $err = eval { $SP->can('_read_manifest')->( paths => $mock_paths ); 1 } ? '' : $@;
    like( $err, qr/must decode to a hash/,
        '_read_manifest rejects a manifest that decodes to a non-hash' );
}
{
    my ( $mock_paths, $file ) = $write_manifest_file->('{}');
    chmod 0000, $file;
    my $err = eval { $SP->can('_read_manifest')->( paths => $mock_paths ); 1 } ? '' : $@;
    chmod 0644, $file;
    like( $err, qr/Unable to read/,
        '_read_manifest dies when an existing manifest file cannot be opened for reading' );
}

# --------------------------------------------------------------------------
# _write_manifest: capability-skip success, open failure, and close failure.
# --------------------------------------------------------------------------
{
    my $root = File::Spec->catdir( $home, 'mock-write-ok' );
    make_path($root);
    my $mock_paths = Test::PathsNoSecure->new( root => $root );
    my $written = $SP->can('_write_manifest')->( paths => $mock_paths, manifest => { ok => 1 } );
    is( $written, File::Spec->catfile( $root, 'seeded-pages.json' ),
        '_write_manifest returns the manifest path and skips securing when no permission helper exists' );
    is_deeply(
        $SP->can('_read_manifest')->( paths => $mock_paths ),
        { ok => 1 },
        '_write_manifest persisted a round-trippable manifest without a permission helper' );
}
{
    my $root = File::Spec->catdir( $home, 'mock-write-dir' );
    make_path( File::Spec->catdir( $root, 'seeded-pages.json' ) );    # occupy the target path with a directory
    my $mock_paths = Test::PathsNoSecure->new( root => $root );
    my $err = eval { $SP->can('_write_manifest')->( paths => $mock_paths, manifest => {} ); 1 } ? '' : $@;
    like( $err, qr/Unable to write/,
        '_write_manifest dies when the manifest file cannot be opened for writing' );
}

SKIP: {
    skip 'no writable /dev/full on this host', 1 if !-w '/dev/full';
    my $root = File::Spec->catdir( $home, 'mock-write-full' );
    make_path($root);
    my $target = File::Spec->catfile( $root, 'seeded-pages.json' );
    symlink '/dev/full', $target or skip 'cannot symlink /dev/full', 1;
    my $mock_paths = Test::PathsNoSecure->new( root => $root );
    my $err = eval { $SP->can('_write_manifest')->( paths => $mock_paths, manifest => { fill => 'buffer' } ); 1 } ? '' : $@;
    like( $err, qr/Unable to close/,
        '_write_manifest dies when flushing the manifest on close fails (ENOSPC via /dev/full)' );
}

is_deeply( \@warnings, [], 'module exercised without emitting any warnings' )
  or diag "warnings: @warnings";

done_testing;

__END__

=head1 NAME

t/71-cli-seededpages-coverage.t - branch and condition coverage closure for the seeded-page manifest module

=head1 PURPOSE

This test is the executable coverage contract for
Developer::Dashboard::CLI::SeededPages. It drives every argument guard, every
manifest read/write failure mode, and each ensure_seeded_page status outcome so
the module's branch and condition coverage stays at 100 percent without hiding
real behavior behind untested fallbacks.

=head1 WHY IT EXISTS

It exists because the seeded-page refresh policy decides whether a
dashboard-managed starter page is created, left current, safely refreshed, or
preserved against user edits, and those decisions hinge on manifest bookkeeping
and defensive file-IO error handling. Several of those branches - a re-thrown
non-"not found" read error, a manifest that decodes to a non-hash, an
unreadable or unwritable manifest file, and a flush-on-close failure - are never
reached by the higher level init and CLI flows, so they need a dedicated test
that provokes each one deliberately.

=head1 WHEN TO USE

Use this file when changing the manifest format, the ensure_seeded_page status
contract, the managed-md5 recognition helpers, or any of the manifest file-IO
error handling in the seeded-pages module.

=head1 HOW TO USE

Run C<prove -lv t/71-cli-seededpages-coverage.t> while iterating on the module,
then confirm branch and condition coverage with a scoped
C<HARNESS_PERL_SWITCHES=-MDevel::Cover> run before keeping it green under
C<prove -lr t>.

=head1 WHAT USES IT

Developers during TDD, the repository test suite, and the Devel::Cover coverage
gate all rely on this file to keep the seeded-page manifest logic fully
exercised and non-destructive.

=head1 EXAMPLES

Example 1:

  prove -lv t/71-cli-seededpages-coverage.t

Run the focused seeded-page coverage test by itself while changing the module.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/71-cli-seededpages-coverage.t

Exercise the same test while collecting branch and condition coverage for the
seeded-page manifest module.

Example 3:

  prove -lr t

Put the change back through the entire repository suite before release.

=cut
