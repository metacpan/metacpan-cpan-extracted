#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use lib 'lib';

use Test::More;
use Fcntl qw(O_RDONLY O_WRONLY O_CREAT O_TRUNC);
use File::Temp qw(tempdir);
use File::Spec;
use File::Basename qw(dirname);
use File::Path qw(make_path);

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PageDocument;

# Absolute path to the module under test, resolved before the hermetic chdir
# below leaves the @INC-relative entry pointing at nothing.
my $page_store_source = File::Spec->rel2abs( $INC{'Developer/Dashboard/PageStore.pm'} );

# ---------------------------------------------------------------------------
# Hermetic runtime: an isolated HOME and state root, with the current working
# directory set to the temp home so DD-OOP-LAYER discovery resolves entirely
# inside the sandbox.
# ---------------------------------------------------------------------------
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME}                           = $home;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
chdir $home or die "Unable to chdir to $home: $!";

my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
my $store = Developer::Dashboard::PageStore->new( paths => $paths );

# write_raw($file, $bytes): write exact bytes with no encoding layer.
sub write_raw {
    my ( $file, $bytes ) = @_;
    open my $fh, '>:raw', $file or die "Unable to write $file: $!";
    print {$fh} $bytes;
    close $fh or die "Unable to close $file: $!";
    return $file;
}

my $droot = $paths->dashboards_root;

# ---------------------------------------------------------------------------
# page_file() id validation (line 35: !defined $id || $id eq '').
# ---------------------------------------------------------------------------
ok( !eval { $store->page_file(undef); 1 }, 'page_file(undef) dies on missing id' );
ok( !eval { $store->page_file(''); 1 },    'page_file("") dies on empty id' );
ok( $store->page_file('welcome'),          'page_file(valid id) returns a path' );

# ---------------------------------------------------------------------------
# _normalized_page_id() undef handling (line 211: $id = '' if !defined $id).
# ---------------------------------------------------------------------------
is( $store->_normalized_page_id(undef),      '',    '_normalized_page_id(undef) => empty string' );
is( $store->_normalized_page_id('/app/foo'), 'foo', '_normalized_page_id strips /app/ prefix' );

{
    no warnings qw(once redefine);
    local *Developer::Dashboard::PageStore::_normalized_page_id = sub {
        die 'common nav id should not enter the normalization path';
    };
    is( $store->_validated_page_id('nav/item-1.tt'), 'nav/item-1.tt',
        'a common canonical nav id uses the validation fast path' );
}
is( $store->_validated_page_id('nav/a..b.tt'), 'nav/a..b.tt',
    'a valid nav id outside the fast-path grammar retains the normal validation path' );
is( $store->_validated_page_id('/app/nav/item-1.tt'), 'nav/item-1.tt',
    'the /app/ compatibility prefix retains normal id normalization' );
{
    no warnings qw(once redefine);
    local *Developer::Dashboard::PageStore::_normalized_page_id = sub {
        die 'canonical flat ids should not enter the normalization path';
    };
    is( $store->_validated_page_id('welcome'), 'welcome',
        'a canonical flat page id bypasses general normalization' );
    is( $store->_validated_page_id('team-status_2.json'), 'team-status_2.json',
        'a canonical flat page id preserves supported punctuation' );
}
ok( !eval { $store->_validated_page_id('nav/../escape.tt'); 1 },
    'a parent-directory component in a nav id remains rejected' );
like( $@, qr/Invalid page id/, 'a parent-directory nav id reports the standard validation error' );
ok( !eval { $store->_validated_page_id(undef); 1 },
    'undefined page id remains rejected through the normalization fallback' );
like( $@, qr/Invalid page id/, 'undefined page id reports the standard validation error' );
{
    package DD::PageStore::OverloadedPageId;
    use overload '""' => sub { 'nav/item-2.tt' }, fallback => 1;
}
is( $store->_validated_page_id( bless( {}, 'DD::PageStore::OverloadedPageId' ) ), 'nav/item-2.tt',
    'overloaded reference ids retain the general normalization path' );

# ---------------------------------------------------------------------------
# Saved page ids stay beneath dashboards_root. Nested ids are supported, but
# parent/current-directory components can otherwise escape the storage root.
# ---------------------------------------------------------------------------
for my $unsafe_id ( '../escaped', 'nested/../../escaped', './escaped', 'nested/./escaped' ) {
    my $outside = File::Spec->catfile( dirname($droot), 'escaped' );
    unlink $outside if -e $outside;
    my $ok = eval { $store->save_page( { id => $unsafe_id, title => 'Traversal proof' } ); 1 };
    ok( !$ok, "save_page rejects unsafe id '$unsafe_id'" );
    like( $@, qr/Invalid page id/, "unsafe id '$unsafe_id' reports an explicit validation error" );
    ok( !-e $outside, "unsafe id '$unsafe_id' creates no file outside dashboards_root" );
}

my $nested_file = $store->save_page( { id => 'team/status', title => 'Nested page' } );
is(
    $nested_file,
    File::Spec->catfile( $droot, 'team', 'status' ),
    'save_page preserves valid nested page ids beneath dashboards_root',
);

for my $platform_id ( 'C:\\outside', 'C:relative', 'double//separator', 'trailing/' ) {
    my $ok = eval { $store->page_file($platform_id); 1 };
    ok( !$ok, "page_file rejects platform-ambiguous id '$platform_id'" );
    like( $@, qr/Invalid page id/, "platform-ambiguous id '$platform_id' reports a validation error" );
}

# Given a nested directory entry beneath dashboards_root is a symlink to an
# outside directory, when a page is saved through it, then the save is rejected
# and no outside file is created.
{
    my $outside_dir = tempdir( CLEANUP => 1 );
    my $linked_dir = File::Spec->catdir( $droot, 'linked-outside' );
    symlink $outside_dir, $linked_dir
      or die "Unable to create directory symlink $linked_dir -> $outside_dir: $!";
    my $outside_file = File::Spec->catfile( $outside_dir, 'escaped' );

    my $ok = eval { $store->save_page( { id => 'linked-outside/escaped', title => 'Symlink escape' } ); 1 };
    ok( !$ok, 'save_page rejects a symlinked directory beneath dashboards_root' );
    like( $@, qr/Invalid page (?:id|path)/, 'symlinked directory save reports an explicit validation error' );
    ok( !-e $outside_file, 'symlinked directory save creates no file outside dashboards_root' );
}

# Given a saved-page filename is a dangling symlink to an outside target that
# does not exist yet, when a page is saved, then open() must not follow the link
# and create the outside target.
{
    my $outside_dir = tempdir( CLEANUP => 1 );
    my $outside_file = File::Spec->catfile( $outside_dir, 'not-created-yet' );
    my $linked_file = File::Spec->catfile( $droot, 'dangling-write' );
    symlink $outside_file, $linked_file
      or die "Unable to create dangling file symlink $linked_file -> $outside_file: $!";

    my $ok = eval { $store->save_page( { id => 'dangling-write', title => 'Dangling symlink escape' } ); 1 };
    ok( !$ok, 'save_page rejects a dangling file symlink beneath dashboards_root' );
    like( $@, qr/Invalid page (?:id|path)/, 'dangling file symlink save reports an explicit validation error' );
    ok( !-e $outside_file, 'dangling file symlink save creates no target outside dashboards_root' );
}

# Given a saved-page filename beneath dashboards_root is a symlink to an
# outside bookmark, when parsed or read raw, then neither API follows it.
{
    my $outside_dir = tempdir( CLEANUP => 1 );
    my $outside_file = File::Spec->catfile( $outside_dir, 'outside-bookmark' );
    write_raw( $outside_file, "TITLE: Outside secret\nBOOKMARK: linked-file\nHTML: outside secret body\n" );
    my $linked_file = File::Spec->catfile( $droot, 'linked-file' );
    symlink $outside_file, $linked_file
      or die "Unable to create file symlink $linked_file -> $outside_file: $!";

    my $loaded;
    my $load_ok = eval { $loaded = $store->load_saved_page('linked-file'); 1 };
    ok( !$load_ok, 'load_saved_page rejects a symlinked saved-page file' );
    like( $@, qr/(?:Invalid page (?:id|path)|not found)/, 'symlinked saved-page parse reports an explicit rejection' );
    ok( !defined $loaded, 'load_saved_page returns no outside bookmark content through a symlink' );

    my $raw;
    my $read_ok = eval { $raw = $store->read_saved_entry('linked-file'); 1 };
    ok( !$read_ok, 'read_saved_entry rejects a symlinked saved-page file' );
    like( $@, qr/(?:Invalid page (?:id|path)|not found)/, 'symlinked saved-page raw read reports an explicit rejection' );
    ok( !defined $raw, 'read_saved_entry returns no outside bookmark content through a symlink' );
}

# Given layered bookmark roots, a target path is valid only when it remains
# inside the particular lookup/write root that lexically owns that candidate.
# A symlink in the writable root must not be accepted merely because it points
# into a different configured fallback root.
{
    my $layer_base = tempdir( CLEANUP => 1 );
    my $write_root = File::Spec->catdir( $layer_base, 'write', 'dashboards' );
    my $fallback_root = File::Spec->catdir( $layer_base, 'fallback', 'dashboards' );
    make_path( $write_root, $fallback_root );

    my $layer_paths = bless {
        write_root    => $write_root,
        fallback_root => $fallback_root,
    }, 'DD395::LayeredPaths';
    my $layer_store = Developer::Dashboard::PageStore->new( paths => $layer_paths );
    my $linked_dir = File::Spec->catdir( $write_root, 'fallback-link' );
    symlink $fallback_root, $linked_dir
      or die "Unable to create layered-root symlink $linked_dir -> $fallback_root: $!";

    my $outside_file = File::Spec->catfile( $fallback_root, 'overwritten' );
    my $ok = eval { $layer_store->save_page( { id => 'fallback-link/overwritten', title => 'Wrong root' } ); 1 };
    ok( !$ok, 'save_page rejects a writable-root symlink into another configured bookmark root' );
    like( $@, qr/Invalid page (?:id|path)/, 'cross-layer symlink save reports an explicit validation error' );
    ok( !-e $outside_file, 'cross-layer symlink save does not write into the fallback root' );
}

{
    package DD395::LayeredPaths;
    sub dashboards_root  { $_[0]->{write_root} }
    sub dashboards_roots { ( $_[0]->{write_root}, $_[0]->{fallback_root} ) }
    sub ensure_dir {
        my ( $self, $dir ) = @_;
        make_path($dir) if !-d $dir;
        return $dir;
    }
    sub secure_file_permissions { $_[1] }
}

# A dangling directory symlink must be rejected before directory creation, so
# even the attempted validation cannot create state outside dashboards_root.
{
    my $outside_dir = tempdir( CLEANUP => 1 );
    my $missing_target = File::Spec->catdir( $outside_dir, 'created-by-escape' );
    my $linked_dir = File::Spec->catdir( $droot, 'dangling-dir' );
    symlink $missing_target, $linked_dir
      or die "Unable to create dangling directory symlink $linked_dir -> $missing_target: $!";

    my $ok = eval { $store->save_page( { id => 'dangling-dir/page', title => 'No outside mkdir' } ); 1 };
    ok( !$ok, 'save_page rejects a dangling directory symlink beneath dashboards_root' );
    like( $@, qr/Invalid page (?:id|path)/, 'dangling directory symlink reports an explicit validation error' );
    ok( !-e $missing_target, 'dangling directory symlink creates no outside directory' );
}

# Listing must not parse valid-looking bookmark content reached through a
# symlink to an external file.
{
    my $outside_dir = tempdir( CLEANUP => 1 );
    my $outside_file = File::Spec->catfile( $outside_dir, 'listed-outside' );
    write_raw( $outside_file, "TITLE: Listed outside\nBOOKMARK: external-list-entry\nHTML: outside\n" );
    my $linked_file = File::Spec->catfile( $droot, 'external-list-entry' );
    symlink $outside_file, $linked_file
      or die "Unable to create list symlink $linked_file -> $outside_file: $!";

    my @listed = $store->list_saved_pages;
    ok( !grep( { $_ eq 'external-list-entry' } @listed ), 'list_saved_pages excludes symlinked external bookmarks' );
}

# Legacy migration must not read/import a JSON file reached through a symlink
# to an external source.
{
    my $bm = tempdir( CLEANUP => 1 );
    my $outside_dir = tempdir( CLEANUP => 1 );
    my $outside_json = File::Spec->catfile( $outside_dir, 'outside.json' );
    write_raw( $outside_json, '{"id":"imported-outside","title":"outside"}' );
    my $linked_json = File::Spec->catfile( $bm, 'external.json' );
    symlink $outside_json, $linked_json
      or die "Unable to create migration symlink $linked_json -> $outside_json: $!";

    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS} = $bm;
    my $migrated = $store->migrate_legacy_json_pages;
    is( scalar @{$migrated}, 0, 'legacy migration skips a symlinked external JSON source' );
    ok( !-e File::Spec->catfile( $bm, 'imported-outside' ), 'legacy migration does not import external symlink content' );
    ok( -f $outside_json, 'legacy migration leaves the external JSON source untouched' );
}

# ---------------------------------------------------------------------------
# Containment primitive units: every deterministic rejection reason in
# _validated_page_id and _assert_page_path_contained.
# ---------------------------------------------------------------------------
ok( !eval { $store->page_file('/app/'); 1 }, 'page_file rejects an id that normalizes to nothing' );
like( $@, qr/Invalid page id/, 'an id that normalizes to nothing reports a validation error' );

ok( !eval { $store->_assert_page_path_contained(undef); 1 }, 'containment rejects an undefined path' );
ok( !eval { $store->_assert_page_path_contained(''); 1 },    'containment rejects an empty path' );
ok( $store->_assert_page_path_contained( File::Spec->catfile( $droot, 'team', 'status' ) ),
    'containment accepts a real page path against the configured roots' );
ok( !eval { $store->_assert_page_path_contained( File::Spec->catfile( $home, 'outside-any-root' ) ); 1 },
    'containment rejects a path outside every configured root' );
ok( !eval { $store->_assert_page_path_contained( File::Spec->catfile( $droot, 'x' ), root => undef ); 1 },
    'containment rejects an undefined root' );
ok( !eval { $store->_assert_page_path_contained( File::Spec->catfile( $droot, 'x' ), root => '' ); 1 },
    'containment rejects an empty root' );
ok( !eval { $store->_assert_page_path_contained( File::Spec->catfile( $droot, 'x' ), root => File::Spec->catdir( $home, 'missing-root' ) ); 1 },
    'containment rejects a root that does not resolve' );
ok( !eval { $store->_assert_page_path_contained( File::Spec->catfile( $droot, 'missing-dir', 'missing-probe' ), root => $droot ); 1 },
    'containment rejects a read probe that does not resolve' );
ok( $store->_assert_page_path_contained( File::Spec->catfile( $droot, 'brand-new-dir', 'brand-new-file' ), root => $droot, for_write => 1 ),
    'containment accepts a new nested write by its nearest existing ancestor' );
ok( $store->_assert_page_path_contained( File::Spec->catfile( $droot, 'team', 'brand-new-file' ), root => $droot, for_write => 1 ),
    'containment accepts a new write in an existing subdirectory' );
ok( $store->_assert_page_path_contained( File::Spec->catfile( $droot, 'team', 'status' ), root => $droot, for_write => 1 ),
    'containment accepts overwriting an existing page for write' );
{
    no warnings qw(once redefine);
    local *Developer::Dashboard::PageStore::is_windows = sub { 1 };
    ok( $store->_assert_page_path_contained( File::Spec->catfile( $droot, 'team', 'status' ), root => $droot ),
        'containment still accepts a contained path under Windows comparison rules' );
}

# POSIX treats backslash as a valid filename character. It must not be
# normalized into a separator while comparing a real root against a sibling.
SKIP: {
    skip 'POSIX-only path comparison regression', 1 if $^O eq 'MSWin32';
    my $comparison_root = tempdir( CLEANUP => 1 );
    my $literal_backslash_root = File::Spec->catdir( $comparison_root, 'root\\segment' );
    my $outside_root_alias = File::Spec->catdir( $comparison_root, 'root', 'segment' );
    make_path($literal_backslash_root);
    make_path($outside_root_alias);
    my $outside_file = File::Spec->catfile( $outside_root_alias, 'outside-page' );
    write_raw( $outside_file, "TITLE: outside\n" );
    ok( !eval { $store->_assert_page_path_contained( $outside_file, root => $literal_backslash_root ); 1 },
        'POSIX containment does not normalize a literal backslash into a path separator' );
}

# ---------------------------------------------------------------------------
# _existing_page_file context contract: file in scalar context, file plus the
# owning root in list context.
# ---------------------------------------------------------------------------
my $scalar_file = $store->_existing_page_file('team/status');
is( $scalar_file, File::Spec->catfile( $droot, 'team', 'status' ),
    '_existing_page_file returns the file in scalar context' );
my ( $list_file, $list_root ) = $store->_existing_page_file('team/status');
is( $list_root, $droot, '_existing_page_file returns the owning root in list context' );

my $containment_assertions = 0;
my $original_containment_assert = Developer::Dashboard::PageStore->can('_assert_page_path_contained');
{
    no warnings qw(once redefine);
    local *Developer::Dashboard::PageStore::_assert_page_path_contained = sub {
        $containment_assertions++;
        return $original_containment_assert->(@_);
    };
    my $raw_entry = $store->read_saved_entry('team/status');
    like( $raw_entry, qr/TITLE: Nested page/, 'read_saved_entry reads the selected bookmark through the secure open path' );
}
is( $containment_assertions, 1,
    'read_saved_entry validates candidate containment once at the secure open boundary' );

my $root_snapshot_reads = 0;
my $next_dashboard_root = File::Spec->catdir( $home, 'later-dashboard-layer' );
{
    no warnings qw(once redefine);
    local *Developer::Dashboard::PathRegistry::dashboards_roots = sub {
        $root_snapshot_reads++;
        return $root_snapshot_reads == 1 ? ($droot) : ($next_dashboard_root);
    };
    {
        local $store->{_page_roots_snapshot};
        my @first_roots  = $store->_page_file_candidates('team/status');
        my @second_roots = $store->_page_file_candidates('team/status');
        is_deeply( [ map { $_->{root} } @first_roots ], [$droot],
            'first page lookup receives the roots discovered for this request' );
        is_deeply( [ map { $_->{root} } @second_roots ], [$droot],
            'later lookups in the same request reuse its ordered roots' );
        is( $root_snapshot_reads, 1, 'one request discovers its dashboard roots once' );
    }
    {
        local $store->{_page_roots_snapshot};
        my @fresh_roots = $store->_page_file_candidates('team/status');
        is_deeply( [ map { $_->{root} } @fresh_roots ], [$next_dashboard_root],
            'a subsequent request observes the newly discovered dashboard root' );
        is( $root_snapshot_reads, 2, 'a subsequent request obtains a fresh root inventory' );
    }
}

# ---------------------------------------------------------------------------
# Descriptor-open unit paths: missing root, missing intermediate directory,
# nested reads through existing directories, and writes without directory
# creation.
# ---------------------------------------------------------------------------
ok( !eval { $store->_open_saved_page_at( id => 'x', flags => O_RDONLY ); 1 },
    'descriptor open requires a root' );
ok( !eval { $store->_open_saved_page_for_read( File::Spec->catdir( $home, 'missing-root' ), 'x' ); 1 },
    'descriptor open rejects a missing root directory' );
ok( !eval { $store->_open_saved_page_for_read( $droot, 'no-such-dir/no-such-file' ); 1 },
    'descriptor open rejects a missing intermediate directory on read' );
my $reloaded_nested = $store->load_saved_page('team/status');
is( $reloaded_nested->{id}, 'team/status', 'a nested page reloads through existing directory descriptors' );
{
    my $no_create = $store->_open_saved_page_for_write( $droot, 'no-create-flat' );
    print {$no_create} "TITLE: No create\n";
    close $no_create;
    ok( -f File::Spec->catfile( $droot, 'no-create-flat' ), 'a root-level write succeeds without directory creation' );
}

# ---------------------------------------------------------------------------
# Containment assertion failures propagate as skips in listing and migration.
# ---------------------------------------------------------------------------
{
    no warnings qw(once redefine);
    local *Developer::Dashboard::PageStore::_assert_page_path_contained = sub { die "Invalid page path\n" };
    is_deeply( [ $store->_saved_page_entries_for_root($droot) ], [],
        'entry listing skips every file the containment assertion rejects' );
}
{
    my $bm = tempdir( CLEANUP => 1 );
    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS} = $bm;
    write_raw( File::Spec->catfile( $bm, 'contained.json' ), '{"id":"contained","title":"t"}' );
    no warnings qw(once redefine);
    local *Developer::Dashboard::PageStore::_assert_page_path_contained = sub { die "Invalid page path\n" };
    my $migrated = $store->migrate_legacy_json_pages;
    is( scalar @{$migrated}, 0, 'legacy migration skips sources the containment assertion rejects' );
    ok( -f File::Spec->catfile( $bm, 'contained.json' ), 'a rejected migration source stays in place' );
}

# ---------------------------------------------------------------------------
# Legacy migration skips a source file it cannot open for reading.
# ---------------------------------------------------------------------------
{
    my $bm = tempdir( CLEANUP => 1 );
    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS} = $bm;
    my $locked = write_raw( File::Spec->catfile( $bm, 'locked.json' ), 'not json either way' );
  SKIP: {
        chmod 0000, $locked or skip 'chmod not honored on this filesystem', 1;
        if ( open my $probe, '<', $locked ) {
            close $probe or die "Unable to close probe on $locked: $!";
            chmod 0600, $locked or die "Unable to restore permissions on $locked: $!";
            skip 'this process can read a mode-0000 file, so the open failure cannot occur', 1;
        }

        my $migrated = $store->migrate_legacy_json_pages;
        is( scalar @{$migrated}, 0, 'legacy migration skips a source file it cannot open' );
    }

    chmod 0600, $locked or die "Unable to restore permissions on $locked: $!";
}

# ---------------------------------------------------------------------------
# One saved-page open path on every host. The former descriptor-relative fast
# path was reachable only where an h2ph-generated header happened to be
# installed: present on this box and on Fedora, absent on stock ubuntu:24.04,
# on Alpine, on every official perl image and therefore on CI, and excluded on
# Windows by construction. That made the symlink-refusing traversal a control
# some installs received and others silently did not, and it left the
# all-metric coverage gate unable to read 100.0 on a clean runner while
# reading 100.0 here. Pin the single path so neither can drift back.
# ---------------------------------------------------------------------------
{
    open my $source_fh, '<:encoding(UTF-8)', $page_store_source
      or die "Unable to read $page_store_source: $!";
    my $source = do { local $/; <$source_fh> };
    close $source_fh or die "Unable to close $page_store_source: $!";

    unlike( $source, qr/syscall/i,
        'PageStore opens saved pages with no host-dependent raw kernel-call path' );
    unlike( $source, qr/\bO_DIRECTORY\b/,
        'PageStore imports no directory-descriptor flag that only the removed path needed' );
}

# ---------------------------------------------------------------------------
# The portable containment path: saved pages still create nested directories,
# stay contained, and refuse symlink escapes.
# ---------------------------------------------------------------------------
{
    my $bm = tempdir( CLEANUP => 1 );
    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS} = $bm;

    my $saved_ok = eval { $store->save_page( { id => 'fbdir/page', title => 'Fallback nested' } ); 1 };
    ok( $saved_ok, 'a nested page is created inside the dashboards root' ) or diag($@);
    ok( -f File::Spec->catfile( $bm, 'fbdir', 'page' ), 'fallback nested save lands inside the dashboards root' );

    ok( eval { $store->save_page( { id => 'fb-flat', title => 'Fallback flat' } ); 1 },
        'fallback save writes a root-level page' ) or diag($@);
    like( $store->read_saved_entry('fbdir/page'), qr/Fallback nested/, 'fallback read returns nested page content' );

    my $outside_dir  = tempdir( CLEANUP => 1 );
    my $outside_file = File::Spec->catfile( $outside_dir, 'fb-outside' );
    write_raw( $outside_file, "TITLE: FB outside\n" );
    symlink $outside_file, File::Spec->catfile( $bm, 'fb-linked' )
      or die "Unable to create fallback file symlink: $!";
    ok( !eval { $store->read_saved_entry('fb-linked'); 1 }, 'fallback read refuses a symlinked page file' );

    my $dangling_target = File::Spec->catfile( $outside_dir, 'fb-not-created' );
    symlink $dangling_target, File::Spec->catfile( $bm, 'fb-dangling' )
      or die "Unable to create fallback dangling symlink: $!";
    ok( !eval { $store->save_page( { id => 'fb-dangling', title => 'X' } ); 1 },
        'fallback save refuses a dangling symlink target' );
    ok( !-e $dangling_target, 'fallback save creates nothing outside the root through a dangling symlink' );

    make_path( File::Spec->catdir( $bm, 'fb-isadir' ) );
    ok( !eval { $store->save_page( { id => 'fb-isadir', title => 'X' } ); 1 },
        'fallback save dies when the target is a directory' );

    my $locked = write_raw( File::Spec->catfile( $bm, 'fb-locked' ), "TITLE: locked\n" );
  SKIP: {
        chmod 0000, $locked or skip 'chmod not honored on this filesystem', 1;
        if ( open my $probe, '<', $locked ) {
            close $probe or die "Unable to close probe on $locked: $!";
            chmod 0600, $locked or die "Unable to restore permissions on $locked: $!";
            skip 'this process can read a mode-0000 file, so the open failure cannot occur', 1;
        }

        ok( !eval { $store->read_saved_entry('fb-locked'); 1 }, 'fallback read dies when the file cannot be opened' );
    }

    chmod 0600, $locked or die "Unable to restore permissions on $locked: $!";

    my $nomode = $store->_open_saved_page_at( root => $bm, id => 'fb-nomode', flags => O_WRONLY | O_CREAT | O_TRUNC );
    print {$nomode} "TITLE: No mode\n";
    close $nomode;
    ok( -f File::Spec->catfile( $bm, 'fb-nomode' ), 'fallback direct open applies the default create mode' );
}

# ---------------------------------------------------------------------------
# Forced-Windows saves use the portable path-based fallback end to end.
# ---------------------------------------------------------------------------
{
    my $bm = tempdir( CLEANUP => 1 );
    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS} = $bm;
    no warnings qw(once redefine);
    local *Developer::Dashboard::PageStore::is_windows = sub { 1 };
    ok( eval { $store->save_page( { id => 'windir/page', title => 'Windows path' } ); 1 },
        'forced-Windows saves use the portable fallback' ) or diag($@);
    like( $store->read_saved_entry('windir/page'), qr/Windows path/, 'forced-Windows reads return the saved content' );
}

# ---------------------------------------------------------------------------
# load_saved_page inheriting an id when the parsed page has none
# (line 69: $page->{id} ||= $id, for both a truthy and a falsy load id).
# ---------------------------------------------------------------------------
write_raw( File::Spec->catfile( $droot, 'noident' ), "TITLE: Hi\n" );
write_raw( File::Spec->catfile( $droot, '0' ),       "TITLE: Hi\n" );

my $p_noident = $store->load_saved_page('noident');
is( $p_noident->{id}, 'noident', 'empty-id page inherits a truthy load id' );

my $p_zero = $store->load_saved_page('0');
is( $p_zero->{id}, '0', 'empty-id page inherits a falsy load id' );

$store->save_page( { id => 'realid', title => 'Real' } );
my $p_real = $store->load_saved_page('realid');
is( $p_real->{id}, 'realid', 'saved page keeps its own parsed id' );

# ---------------------------------------------------------------------------
# encode_page raw-instruction handling
# (line 108: defined $raw_instruction && $raw_instruction ne '').
# ---------------------------------------------------------------------------
my $doc_undef = Developer::Dashboard::PageDocument->from_hash( { id => 'e1', title => 'T' } );
ok( length $store->encode_page($doc_undef), 'encode_page without raw_instruction encodes canonical text' );

my $doc_empty = Developer::Dashboard::PageDocument->from_hash( { id => 'e2', title => 'T' } );
$doc_empty->{meta}{raw_instruction} = '';
ok( length $store->encode_page($doc_empty), 'encode_page with empty raw_instruction falls through to canonical' );

my $doc_raw = Developer::Dashboard::PageDocument->from_hash( { id => 'e3', title => 'T' } );
$doc_raw->{meta}{raw_instruction} = "TITLE: raw\n";
ok( length $store->encode_page($doc_raw), 'encode_page uses a present raw_instruction' );

# ---------------------------------------------------------------------------
# list_saved_pages skipping malformed entries (line 150). The saved-entry
# helper is fed crafted rows (undef id, empty id, valid id) so the id guard's
# every side executes; naturally-produced entries always carry a non-empty id.
# ---------------------------------------------------------------------------
{
    my $vf = File::Spec->catfile( $droot, 'listok' );
    write_raw( $vf, "TITLE: Listed\n" );
    my @entries = (
        { id => undef,    file => $vf },
        { id => '',       file => $vf },
        { id => 'listok', file => $vf },
    );
    no warnings 'redefine';
    local *Developer::Dashboard::PageStore::_saved_page_entries_for_root = sub { @entries };
    my @ids = $store->list_saved_pages;
    is_deeply( \@ids, ['listok'], 'list_saved_pages skips undef/empty ids and keeps valid ones' );
}

# ---------------------------------------------------------------------------
# _load_page_file error path when instruction parsing fails
# (line 241: $args{id} || ''  and  line 249: die($@ || "...")).
# ---------------------------------------------------------------------------
{
    my $junk = File::Spec->catfile( $droot, 'junk.bm' );
    write_raw( $junk, "no colon just prose\n" );

    ok( !eval { $store->_load_page_file($junk); 1 },
        '_load_page_file without an id dies on unparseable content' );
    ok( !eval { $store->_load_page_file( $junk, id => 'x' ); 1 },
        '_load_page_file with an id dies on unparseable content' );
}

# ---------------------------------------------------------------------------
# _raw_nav_fragment_page id and instruction handling (lines 258 and 259).
# ---------------------------------------------------------------------------
ok( !eval { $store->_raw_nav_fragment_page(); 1 }, '_raw_nav_fragment_page dies without an id' );

my $nav_noinstr = $store->_raw_nav_fragment_page( id => 'nav/a.tt' );
is( $nav_noinstr->{layout}{body}, '', 'raw nav fragment defaults to an empty body' );

my $nav_instr = $store->_raw_nav_fragment_page( id => 'nav/b.tt', instruction => 'BODY' );
is( $nav_instr->{layout}{body}, 'BODY', 'raw nav fragment keeps its instruction body' );

# ---------------------------------------------------------------------------
# _looks_like_raw_nav_fragment classification (lines 274 and 276).
# ---------------------------------------------------------------------------
is( $store->_looks_like_raw_nav_fragment(undef),          0, 'undef fragment is not raw nav' );
is( $store->_looks_like_raw_nav_fragment(''),             0, 'empty fragment is not raw nav' );
is( $store->_looks_like_raw_nav_fragment('plain words'),  0, 'plain text is not raw nav' );
is( $store->_looks_like_raw_nav_fragment('<div>x</div>'), 1, 'an html tag looks like raw nav' );

# load_nav_fragment returns literal HTML before allocating or parsing a page.
{
    my $nav_dir = File::Spec->catdir( $droot, 'nav' );
    make_path($nav_dir);
    my $literal_nav = File::Spec->catfile( $nav_dir, 'literal.tt' );
    write_raw( $literal_nav, '<span id="literal-nav">ready</span>' );

    my $full_parser_calls = 0;
    my $literal_result;
    {
        no warnings qw(once redefine);
        local *Developer::Dashboard::PageDocument::from_instruction = sub {
            $full_parser_calls++;
            die 'Literal nav must not enter the page parser';
        };
        $literal_result = $store->load_nav_fragment('nav/literal.tt');
    }
    is( $literal_result->{kind}, 'literal', 'load_nav_fragment classifies static HTML as literal output' );
    is( $literal_result->{body}, '<span id="literal-nav">ready</span>', 'literal output preserves exact HTML bytes after UTF-8 decoding' );
    is( $full_parser_calls, 0, 'literal nav bypasses PageDocument construction and parsing' );

    my $candidate_lookups = 0;
    my $original_candidates = Developer::Dashboard::PageStore->can('_page_file_candidates');
    delete $store->{_nav_fragment_cache};
    {
        no warnings qw(once redefine);
        local *Developer::Dashboard::PageStore::_page_file_candidates = sub {
            $candidate_lookups++;
            return $original_candidates->(@_);
        };
        my $root_selected = $store->load_nav_fragment( 'nav/literal.tt', root => $droot );
        is( $root_selected->{body}, '<span id="literal-nav">ready</span>', 'known-layer nav lookup returns the expected literal content' );
    }
    is( $candidate_lookups, 0, 'a known dashboard layer avoids searching every candidate root' );
    my $original_path_containment = Developer::Dashboard::PageStore->can('_assert_page_path_contained');
    my $cache_miss_containment_checks = 0;
    delete $store->{_nav_fragment_cache};
    {
        no warnings qw(once redefine);
        local *Developer::Dashboard::PageStore::_assert_page_path_contained = sub {
            $cache_miss_containment_checks++;
            return $original_path_containment->(@_);
        };
        my $cache_miss = $store->load_nav_fragment( 'nav/literal.tt', root => $droot );
        is( $cache_miss->{body}, '<span id="literal-nav">ready</span>',
            'a literal nav cache miss preserves its body while secure reading it' );
    }
    is( $cache_miss_containment_checks, 1,
        'a cache miss checks containment once at the secure open boundary' );

    my $cached_path_containment_checks = 0;
    {
        no warnings qw(once redefine);
        local *Developer::Dashboard::PageStore::_assert_page_path_contained = sub {
            $cached_path_containment_checks++;
            return $original_path_containment->(@_);
        };
        $store->load_nav_fragment( 'nav/literal.tt', root => $droot );
    }
    is( $cached_path_containment_checks, 1, 'a cached nav hit still checks path containment on every request' );
    ok( !eval { $store->load_nav_fragment( 'nav/literal.tt', root => dirname($droot) ); 1 },
        'load_nav_fragment rejects a root outside configured dashboard layers' );
    like( $@, qr/Invalid nav fragment root/, 'an untrusted nav root has an explicit diagnostic' );

    my $original_read_saved_instruction = Developer::Dashboard::PageStore->can('_read_saved_instruction');
    my $literal_file_reads = 0;
    delete $store->{_nav_fragment_cache};
    {
        no warnings qw(once redefine);
        local *Developer::Dashboard::PageStore::_read_saved_instruction = sub {
            $literal_file_reads++;
            return $original_read_saved_instruction->(@_);
        };
        my $cached_first = $store->load_nav_fragment('nav/literal.tt');
        my $cached_second = $store->load_nav_fragment('nav/literal.tt');
        is( $cached_first->{body}, $cached_second->{body}, 'cached literal nav keeps exact content' );
        is( $literal_file_reads, 1, 'an unchanged literal nav avoids reopening and decoding its file' );

        write_raw( $literal_nav, '<span id="literal-nav">fresh</span>' );
        my $updated = $store->load_nav_fragment('nav/literal.tt');
        is( $updated->{body}, '<span id="literal-nav">fresh</span>', 'literal nav cache invalidates on a same-size file edit' );
        is( $literal_file_reads, 2, 'a changed literal nav is reopened once to refresh its cached content' );
    }

    my $dynamic_nav = File::Spec->catfile( $nav_dir, 'dynamic.tt' );
    write_raw( $dynamic_nav, '<a href="[% url %]">dynamic</a>' );
    my $dynamic_result = $store->load_nav_fragment('nav/dynamic.tt');
    is( $dynamic_result->{kind}, 'page', 'Template Toolkit nav remains a page document' );
    is( $dynamic_result->{page}{meta}{source_format}, 'raw-nav-tt', 'dynamic raw nav retains its source classification' );
    is( $dynamic_result->{page}{meta}{source_kind}, 'saved', 'dynamic raw nav retains its saved-page source kind' );
    is( $dynamic_result->{page}{meta}{raw_instruction}, '<a href="[% url %]">dynamic</a>', 'dynamic raw nav retains its original instruction' );

    my $structured_nav = File::Spec->catfile( $nav_dir, 'structured.tt' );
    write_raw( $structured_nav, "=== HTML ===\n<strong>structured</strong>" );
    my $structured_result = $store->load_nav_fragment('nav/structured.tt');
    is( $structured_result->{kind}, 'page', 'structured nav remains a page document' );
    like( $structured_result->{page}{layout}{body}, qr/structured/, 'structured nav retains parsed content' );

    ok( !defined $store->load_nav_fragment('nav/missing.tt'), 'missing nav file is reported as absent' );
    ok( !eval { $store->load_nav_fragment('pages/outside.tt'); 1 }, 'load_nav_fragment rejects ids outside nav/*.tt' );
    like( $@, qr/Invalid nav fragment id/, 'invalid nav fragment id has an explicit diagnostic' );

    my $outside_nav = File::Spec->catfile( dirname($droot), 'outside-nav-fragment.tt' );
    write_raw( $outside_nav, '<span id="outside-nav">secret</span>' );
    unlink $literal_nav or die "Unable to replace literal nav cache fixture '$literal_nav': $!";
    SKIP: {
        skip 'symlink creation is unavailable for this user', 2 if !symlink( $outside_nav, $literal_nav );
        my $symlink_error = eval { $store->load_nav_fragment('nav/literal.tt'); 1 } ? '' : $@;
        like( $symlink_error, qr/Invalid page path/, 'cached literal nav never follows a replacement symlink' );
        unlike( $symlink_error, qr/outside-nav-fragment/, 'symlink rejection does not expose the outside path' );
        unlink $literal_nav or die "Unable to remove nav symlink '$literal_nav': $!";
    }
    unlink $outside_nav or die "Unable to remove outside nav fixture '$outside_nav': $!";

    my $bounded_cache_store = Developer::Dashboard::PageStore->new( paths => $paths );
    ok( !$bounded_cache_store->_cache_literal_nav_fragment( undef, 'fingerprint', 'body' ),
        'literal nav cache rejects incomplete keys' );
    $bounded_cache_store->{_nav_fragment_cache} = { bytes => 0, entries => [], order => [] };
    ok( !$bounded_cache_store->_cache_literal_nav_fragment( 'nav/bad.tt', 'fingerprint', 'body' ),
        'literal nav cache refuses malformed in-memory cache state' );
    delete $bounded_cache_store->{_nav_fragment_cache};
    ok( $bounded_cache_store->_cache_literal_nav_fragment( 'nav/one.tt', 'fingerprint', 'body' ),
        'literal nav cache accepts a complete small entry' );
    ok( $bounded_cache_store->_cache_literal_nav_fragment( 'nav/one.tt', 'updated', 'fresh' ),
        'literal nav cache replaces an existing entry' );
    for my $index ( 2 .. 129 ) {
        $bounded_cache_store->_cache_literal_nav_fragment( "nav/$index.tt", "fingerprint-$index", 'x' );
    }
    is( scalar( keys %{ $bounded_cache_store->{_nav_fragment_cache}{entries} } ), 128,
        'literal nav cache evicts entries above its bounded item count' );
    is( $bounded_cache_store->{_nav_fragment_cache}{bytes}, 128,
        'literal nav cache byte accounting follows evictions' );

    my $byte_bounded_store = Developer::Dashboard::PageStore->new( paths => $paths );
    my $large_literal = 'x' x 262144;
    $byte_bounded_store->_cache_literal_nav_fragment( "nav/large-$_.tt", "large-$_", $large_literal )
      for 1 .. 17;
    is( scalar( keys %{ $byte_bounded_store->{_nav_fragment_cache}{entries} } ), 16,
        'literal nav cache evicts entries above its byte budget' );
    is( $byte_bounded_store->{_nav_fragment_cache}{bytes}, 4_194_304,
        'literal nav cache stays within its four-megabyte body budget' );
}

# Exercise the remaining filesystem/race and bounded-cache branches without
# weakening the production path checks.
{
    my $nav_dir = File::Spec->catdir( $droot, 'nav' );
    make_path($nav_dir);
    my $known_root_file = File::Spec->catfile( $nav_dir, 'known-root.tt' );
    write_raw( $known_root_file, '<span>known root</span>' );

    delete $store->{_validated_nav_roots};
    local $store->{_page_roots_snapshot} = [$droot];
    my $known_root_result = $store->load_nav_fragment( 'nav/known-root.tt', root => $droot );
    is( $known_root_result->{kind}, 'literal', 'an uncached configured root is validated against the request snapshot' );
    ok( !defined $store->load_nav_fragment( 'nav/root-missing.tt', root => $droot ),
        'a configured root whose fragment disappeared returns absence' );

    my $root_symlink = File::Spec->catfile( $nav_dir, 'root-symlink.tt' );
    my $outside = File::Spec->catfile( dirname($droot), 'outside-root-nav.tt' );
    write_raw( $outside, '<span>outside</span>' );
    SKIP: {
        skip 'symlink creation is unavailable for this user', 2 if !symlink( $outside, $root_symlink );
        ok( !eval { $store->load_nav_fragment( 'nav/root-symlink.tt', root => $droot ); 1 },
            'the known-root path rejects a symlinked fragment before reading it' );
        like( $@, qr/Invalid page path/, 'the known-root symlink rejection is explicit' );
        unlink $root_symlink or die "Unable to remove nav symlink '$root_symlink': $!";
    }
    unlink $outside or die "Unable to remove outside nav fixture '$outside': $!";

    my $root_directory = File::Spec->catfile( $nav_dir, 'root-directory.tt' );
    make_path($root_directory);
    ok( !defined $store->load_nav_fragment( 'nav/root-directory.tt', root => $droot ),
        'a directory where a known-root nav file is expected is treated as absent' );

    my $missing_initial_stat = File::Spec->catfile( $nav_dir, 'initial-stat-race.tt' );
    write_raw( $missing_initial_stat, '<span>initial stat race</span>' );
    my $real_lstat = Time::HiRes->can('lstat');
    my $initial_lstat_calls = 0;
    {
        no warnings qw(once redefine);
        local *Time::HiRes::lstat = sub {
            return if $_[0] eq $missing_initial_stat && ++$initial_lstat_calls == 1;
            return $real_lstat->(@_);
        };
        my $result = $store->load_nav_fragment('nav/initial-stat-race.tt');
        is( $result->{kind}, 'literal', 'a transient missing initial stat does not corrupt a later secure read' );
        ok( !exists $store->{_nav_fragment_cache}{entries}{$missing_initial_stat},
            'a file without an initial stat fingerprint is not cached' );
    }

    my $missing_final_stat = File::Spec->catfile( $nav_dir, 'final-stat-race.tt' );
    write_raw( $missing_final_stat, '<span>final stat race</span>' );
    my $final_lstat_calls = 0;
    {
        no warnings qw(once redefine);
        local *Time::HiRes::lstat = sub {
            return if $_[0] eq $missing_final_stat && ++$final_lstat_calls == 2;
            return $real_lstat->(@_);
        };
        my $result = $store->load_nav_fragment('nav/final-stat-race.tt');
        is( $result->{kind}, 'literal', 'a transient missing final stat keeps the already-read body' );
        ok( !exists $store->{_nav_fragment_cache}{entries}{$missing_final_stat},
            'a file without a final stat fingerprint is not cached' );
    }

    my $large_store = Developer::Dashboard::PageStore->new( paths => $paths );
    my $oversized_file = File::Spec->catfile( $nav_dir, 'oversized-literal.tt' );
    write_raw( $oversized_file, '<div>' . ( 'x' x 262_145 ) . '</div>' );
    my $oversized_result = $large_store->load_nav_fragment( 'nav/oversized-literal.tt', root => $droot );
    is( $oversized_result->{kind}, 'literal', 'oversized literal nav still renders from its secure read' );
    ok( !exists $large_store->{_nav_fragment_cache}{entries}{$oversized_file},
        'oversized literal nav is not retained in the bounded cache' );

    for my $invalid ( [ 'nav/no-fingerprint.tt', undef, 'body' ], [ 'nav/no-body.tt', 'fingerprint', undef ] ) {
        ok( !$large_store->_cache_literal_nav_fragment( $invalid->[0], $invalid->[1], $invalid->[2] ),
            'literal nav cache rejects an absent fingerprint or body' );
    }

    for my $bad_cache (
        { entries => {}, order => {}, bytes => 0 },
        { entries => {}, order => [], bytes => undef },
        { entries => {}, order => [], bytes => 'not-a-count' },
    ) {
        my $bad_store = Developer::Dashboard::PageStore->new( paths => $paths );
        $bad_store->{_nav_fragment_cache} = $bad_cache;
        ok( !$bad_store->_cache_literal_nav_fragment( 'nav/bad-state.tt', 'fingerprint', 'body' ),
            'literal nav cache rejects each malformed order/byte-count state' );
    }

    my $replace_store = Developer::Dashboard::PageStore->new( paths => $paths );
    $replace_store->{_nav_fragment_cache} = {
        bytes   => 0,
        entries => { 'nav/replace.tt' => { fingerprint => 'old', body => undef } },
        order   => ['nav/replace.tt'],
    };
    ok( $replace_store->_cache_literal_nav_fragment( 'nav/replace.tt', 'new', 'replacement' ),
        'replacing a cache entry with an absent old body preserves valid accounting' );

    my $stale_order_store = Developer::Dashboard::PageStore->new( paths => $paths );
    $stale_order_store->{_nav_fragment_cache} = {
        bytes   => 4_194_304,
        entries => {
            'nav/malformed-entry.tt' => [],
            'nav/undef-body.tt' => { fingerprint => 'empty', body => undef },
            'nav/large-body.tt' => { fingerprint => 'large', body => 'x' x 4_194_304 },
        },
        order => [ 'nav/stale.tt', 'nav/malformed-entry.tt', 'nav/undef-body.tt', 'nav/large-body.tt' ],
    };
    ok( $stale_order_store->_cache_literal_nav_fragment( 'nav/new-entry.tt', 'new', 'x' ),
        'bounded cache recovers while evicting stale ordering and an absent body' );
    ok( !exists $stale_order_store->{_nav_fragment_cache}{entries}{'nav/stale.tt'},
        'stale ordering metadata does not create a cache entry' );
    ok( !exists $stale_order_store->{_nav_fragment_cache}{entries}{'nav/malformed-entry.tt'},
        'evicting a malformed cache entry does not dereference it as a hash' );
}

my $raw_nav_parse_calls = 0;
{
    no warnings 'redefine';
    local *Developer::Dashboard::PageDocument::from_instruction = sub {
        $raw_nav_parse_calls++;
        die 'Raw nav must not enter the full bookmark parser';
    };
    my $raw_nav_fast = $store->_load_page_instruction(
        '<div class="nav-fast-path">raw navigation</div>',
        id => 'nav/fast-path.tt',
    );
    is( $raw_nav_fast->{meta}{source_format}, 'raw-nav-tt',
        'raw HTML nav fragment selects the direct wrapper fast path' );
}
is( $raw_nav_parse_calls, 0, 'raw HTML nav fragment bypasses legacy instruction parsing' );

my $structured_nav = $store->_load_page_instruction(
    "=== HTML ===\n<span class=\"nav-structured\">structured navigation</span>",
    id => 'nav/structured.tt',
);
like( $structured_nav->{layout}{body}, qr/structured navigation/,
    'structured bookmark headers in a nav file still use the instruction parser' );

# Cover the literal-fragment cache's defensive read paths and filesystem races
# through the public loader, rather than testing only its private cache helper.
{
    my $nav_dir = File::Spec->catdir( $droot, 'nav' );
    make_path($nav_dir);
    my $cache_file = File::Spec->catfile( $nav_dir, 'cache-validation.tt' );
    write_raw( $cache_file, '<b>source body</b>' );

    my @malformed_caches = (
        { bytes => 0, entries => [], order => [] },
        { bytes => 0, entries => { $cache_file => [] }, order => [] },
        { bytes => 0, entries => { $cache_file => { body => '<b>stale</b>' } }, order => [] },
        { bytes => 0, entries => { $cache_file => { fingerprint => 'stale', body => '<b>stale</b>' } }, order => [] },
    );
    for my $index ( 0 .. $#malformed_caches ) {
        my $cache_store = Developer::Dashboard::PageStore->new( paths => $paths );
        $cache_store->{_nav_fragment_cache} = $malformed_caches[$index];
        my $result = $cache_store->load_nav_fragment('nav/cache-validation.tt');
        is( $result->{body}, '<b>source body</b>', "malformed or stale cache entry $index falls through to current file content" );
    }

    my $bad_root_store = Developer::Dashboard::PageStore->new( paths => $paths );
    $bad_root_store->{_page_roots_snapshot} = [undef];
    ok( !eval { $bad_root_store->load_nav_fragment( 'nav/cache-validation.tt', root => $droot ); 1 },
        'a configured-root lookup rejects a snapshot without a usable root' );
    like( $@, qr/Invalid nav fragment root/, 'the invalid root snapshot failure is explicit' );

    my $nonregular_file = File::Spec->catfile( $nav_dir, 'nonregular-race.tt' );
    write_raw( $nonregular_file, '<b>will become directory</b>' );
    my $existing_page_file = Developer::Dashboard::PageStore->can('_existing_page_file');
    {
        no warnings qw(once redefine);
        local *Developer::Dashboard::PageStore::_existing_page_file = sub {
            my @resolved = $existing_page_file->(@_);
            unlink $resolved[0] or die "Unable to replace nav file with directory '$resolved[0]': $!";
            make_path( $resolved[0] );
            return @resolved;
        };
        ok( !eval { $store->load_nav_fragment('nav/nonregular-race.tt'); 1 },
            'a file replaced by a directory before lstat is rejected' );
        like( $@, qr/Invalid page path/, 'the non-regular replacement has an explicit path error' );
    }
    rmdir $nonregular_file or die "Unable to remove nav race directory '$nonregular_file': $!";

    my $page_file = File::Spec->catfile( $nav_dir, 'page-id-fallback.tt' );
    write_raw( $page_file, "TITLE: page id fallback\nplain body\n" );
    {
        no warnings qw(once redefine);
        local *Developer::Dashboard::PageStore::_load_page_instruction = sub { return { meta => {} } };
        my $result = $store->load_nav_fragment('nav/page-id-fallback.tt');
        is( $result->{page}{id}, 'nav/page-id-fallback.tt',
            'a parsed nav page without an id receives the validated id' );
    }

    my $replacement_file = File::Spec->catfile( $nav_dir, 'post-read-replacement.tt' );
    my $replacement_target = File::Spec->catfile( dirname($droot), 'post-read-outside.tt' );
    write_raw( $replacement_file, '<b>read before replacement</b>' );
    write_raw( $replacement_target, '<b>outside</b>' );
    SKIP: {
        skip 'symlink creation is unavailable for this user', 2 if !symlink( $replacement_target, "$replacement_file.symlink-probe" );
        unlink "$replacement_file.symlink-probe"
          or die "Unable to remove symlink probe '$replacement_file.symlink-probe': $!";
        my $real_read = Developer::Dashboard::PageStore->can('_read_saved_instruction');
        my $reads = 0;
        {
            no warnings qw(once redefine);
            local *Developer::Dashboard::PageStore::_read_saved_instruction = sub {
                my $body = $real_read->(@_);
                if ( $_[1] eq $replacement_file && !$reads++ ) {
                    unlink $replacement_file or die "Unable to replace nav file '$replacement_file': $!";
                    symlink $replacement_target, $replacement_file
                      or die "Unable to create replacement nav symlink '$replacement_file': $!";
                }
                return $body;
            };
            my $result = $store->load_nav_fragment('nav/post-read-replacement.tt');
            is( $result->{body}, '<b>read before replacement</b>',
                'a post-read path replacement does not change the already securely read response' );
            ok( !exists $store->{_nav_fragment_cache}{entries}{$replacement_file},
                'a post-read symlink replacement is never cached' );
        }
        unlink $replacement_file or die "Unable to remove replacement nav symlink '$replacement_file': $!";
    }
    unlink $replacement_target or die "Unable to remove replacement nav target '$replacement_target': $!";

    my $changed_file = File::Spec->catfile( $nav_dir, 'changed-during-read.tt' );
    write_raw( $changed_file, '<b>first body</b>' );
    my $real_read = Developer::Dashboard::PageStore->can('_read_saved_instruction');
    my $changed_reads = 0;
    {
        no warnings qw(once redefine);
        local *Developer::Dashboard::PageStore::_read_saved_instruction = sub {
            my $body = $real_read->(@_);
            if ( $_[1] eq $changed_file && !$changed_reads++ ) {
                write_raw( $changed_file, '<b>other body</b>' );
            }
            return $body;
        };
        my $result = $store->load_nav_fragment('nav/changed-during-read.tt');
        is( $result->{body}, '<b>first body</b>', 'the in-flight response keeps the bytes it securely read' );
        ok( !exists $store->{_nav_fragment_cache}{entries}{$changed_file},
            'content changed during a read is not cached under the stale fingerprint' );
    }
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::PageDocument::from_instruction = sub {
        die 'synthetic structured nav parse rejection';
    };
    my $legacy_nav_fallback = $store->_load_page_instruction(
        "TITLE: legacy nav\n<span>fallback navigation</span>",
        id => 'nav/legacy-fallback.tt',
    );
    is( $legacy_nav_fallback->{meta}{source_format}, 'raw-nav-tt',
        'raw nav fallback remains available when structured parsing rejects a fragment' );
}

# ---------------------------------------------------------------------------
# _read_saved_instruction decode paths
# (line 286 open-fail; line 291 UTF-8 decode fallback across all three outcomes).
# ---------------------------------------------------------------------------
ok( !eval { $store->_read_saved_instruction( File::Spec->catfile( $home, 'no-such-file-xyz' ) ); 1 },
    '_read_saved_instruction dies when the file cannot be opened' );

my $empty_file = File::Spec->catfile( $droot, 'empty.bm' );
write_raw( $empty_file, '' );
is( $store->_read_saved_instruction($empty_file), '', 'an empty saved file reads back as empty text' );

my $valid_file = File::Spec->catfile( $droot, 'valid.bm' );
write_raw( $valid_file, "hello world\n" );
is( $store->_read_saved_instruction($valid_file), "hello world\n", 'a valid UTF-8 file decodes strictly' );

my $invalid_file = File::Spec->catfile( $droot, 'invalid.bm' );
write_raw( $invalid_file, "bad\xFF\xFEbytes" );
ok( length $store->_read_saved_instruction($invalid_file),
    'an invalid UTF-8 file falls back to lenient decoding' );

# ---------------------------------------------------------------------------
# _normalize_legacy_icon_markup undef handling (line 301).
# ---------------------------------------------------------------------------
is( $store->_normalize_legacy_icon_markup(undef),   '',      'normalize(undef) => empty string' );
is( $store->_normalize_legacy_icon_markup('plain'), 'plain', 'normalize passes plain text through' );
is(
    $store->_normalize_legacy_icon_markup("\x{1F9D1}\x{FFFD}\x{1F4BB}"),
    "\x{1F9D1}\x{200D}\x{1F4BB}",
    'normalize repairs the legacy malformed person-at-computer sequence',
);
is(
    $store->_normalize_legacy_icon_markup("<h2>\x{FFFD} Heading"),
    "<h2>◈ Heading",
    'normalize repairs the legacy heading glyph only in its heading context',
);
is(
    $store->_normalize_legacy_icon_markup('<span class="icon">' . "\x{FFFD}" . '</span>'),
    '<span class="icon">🏷️</span>',
    'normalize repairs the legacy icon glyph only in its icon span',
);
is(
    $store->_normalize_legacy_icon_markup("ordinary \x{FFFD} replacement text"),
    "ordinary \x{FFFD} replacement text",
    'normalize preserves unrelated replacement characters',
);

# ---------------------------------------------------------------------------
# _saved_page_entries_for_root root guards (line 314: defined $root && -d $root).
# ---------------------------------------------------------------------------
is_deeply( [ $store->_saved_page_entries_for_root(undef) ], [],
    '_saved_page_entries_for_root(undef) returns nothing' );
is_deeply( [ $store->_saved_page_entries_for_root( File::Spec->catfile( $home, 'missing-dir' ) ) ], [],
    '_saved_page_entries_for_root on a missing directory returns nothing' );
ok( scalar( $store->_saved_page_entries_for_root($droot) ),
    '_saved_page_entries_for_root on a real directory finds entries' );

# ---------------------------------------------------------------------------
# save_page write failure (line 53: open my $fh, '>', $file or die).
# The target id resolves onto an existing directory, so the write fails.
# ---------------------------------------------------------------------------
{
    my $bm = tempdir( CLEANUP => 1 );
    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS} = $bm;
    make_path( File::Spec->catdir( $bm, 'isadir' ) );
    ok( !eval { $store->save_page( { id => 'isadir', title => 'X' } ); 1 },
        'save_page dies when the target path is a directory' );
}

# ---------------------------------------------------------------------------
# migrate_legacy_json_pages happy + skip paths (lines 172, 174, 179, 180, and
# the 184/188 success sides).
# ---------------------------------------------------------------------------
{
    my $bm = tempdir( CLEANUP => 1 );
    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS} = $bm;
    write_raw( File::Spec->catfile( $bm, 'withid.json' ), '{"id":"withid","title":"t"}' );
    write_raw( File::Spec->catfile( $bm, 'notid.json' ),  '{"title":"t"}' );
    write_raw( File::Spec->catfile( $bm, '0.json' ),      '{"title":"t"}' );
    write_raw( File::Spec->catfile( $bm, 'bad.json' ),    'this is not json' );
    write_raw( File::Spec->catfile( $bm, 'readme.txt' ),  'hello' );
    write_raw( File::Spec->catfile( $bm, 'hostile.json' ), '{"id":"../evil","title":"t"}' );
    make_path( File::Spec->catdir( $bm, 'dir.json' ) );

    my $migrated = $store->migrate_legacy_json_pages;
    my %by_id = map { $_->{id} => 1 } @$migrated;
    ok( $by_id{withid}, 'migrate keeps an explicit json id' );
    ok( $by_id{notid},  'migrate falls back to a truthy basename id' );
    ok( $by_id{'0'},    'migrate falls back to a falsy basename id' );
    is( scalar @$migrated, 3, 'migrate skips non-json, directory, and unparseable json entries' );
    ok( !$by_id{'../evil'}, 'migrate skips a json entry whose embedded id attempts traversal' );
    ok( !-e File::Spec->catfile( dirname($bm), 'evil' ),
        'migrate creates nothing outside the dashboards root for a traversal id' );
    ok( -e File::Spec->catfile( $bm, 'hostile.json' ),
        'migrate leaves the traversal-id source file unmigrated in place' );
}

# ---------------------------------------------------------------------------
# migrate target write failure (line 184: open my $out, '>', $target or die).
# The migrated id resolves onto an existing directory.
# ---------------------------------------------------------------------------
{
    my $bm = tempdir( CLEANUP => 1 );
    local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS} = $bm;
    write_raw( File::Spec->catfile( $bm, 'clash.json' ), '{"title":"t"}' );
    make_path( File::Spec->catdir( $bm, 'clash' ) );
    ok( !eval { $store->migrate_legacy_json_pages; 1 },
        'migrate dies when the target path is a directory' );
}

# ---------------------------------------------------------------------------
# Permission-dependent failure paths. These require a process that can actually
# BE DENIED, which is not the same as a non-root one: a root process with
# CAP_DAC_OVERRIDE dropped is denied here, and root with it held is not.
#   line 167  opendir on an unreadable root
#   line 175  open '<' on an unreadable json file
#   line 188  unlink of a source file in a read-only root
# ---------------------------------------------------------------------------
SKIP: {
    # Was `skip ... if $> == 0`. Identity is a proxy for the real condition and
    # it comes apart: -r and $> both say "root can read this" whether or not the
    # kernel would allow it, so the identity form skipped three assertions that
    # a capability-dropped root would have run and passed. Probe once, by
    # attempting the operation, and let the answer stand for all three sites.
    my $probe_root = tempdir( CLEANUP => 1 );
    chmod 0000, $probe_root or skip 'chmod not honored on this filesystem', 3;
    my $probe_dh;
    my $denial_observable = opendir( $probe_dh, $probe_root ) ? do { closedir $probe_dh; 0 } : 1;
    chmod 0700, $probe_root;
    skip 'this process can open a mode-0000 directory, so these denials cannot occur', 3
      if !$denial_observable;

    # line 167: an unreadable bookmarks root makes opendir fail.
    {
        my $ro = tempdir( CLEANUP => 1 );
        chmod 0300, $ro or die "Unable to chmod $ro: $!";
        local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS} = $ro;
        my $migrated = $store->migrate_legacy_json_pages;
        is_deeply( $migrated, [], 'migrate returns empty when the root cannot be read' );
        chmod 0700, $ro;
    }

    # line 175: an unreadable json file is skipped.
    {
        my $bm = tempdir( CLEANUP => 1 );
        local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS} = $bm;
        my $np = File::Spec->catfile( $bm, 'noperm.json' );
        write_raw( $np, '{"title":"t"}' );
        chmod 0000, $np or die "Unable to chmod $np: $!";
        my $migrated = $store->migrate_legacy_json_pages;
        is( scalar @$migrated, 0, 'migrate skips an unreadable json file' );
        chmod 0644, $np;
    }

    # line 188: a read-only root leaves the source unlink to fail after the
    # target (in a still-writable subdirectory) is written.
    {
        my $bm = tempdir( CLEANUP => 1 );
        local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS} = $bm;
        write_raw( File::Spec->catfile( $bm, 'src.json' ), '{"id":"sub/page","title":"t"}' );
        make_path( File::Spec->catdir( $bm, 'sub' ) );
        chmod 0500, $bm or die "Unable to chmod $bm: $!";
        ok( !eval { $store->migrate_legacy_json_pages; 1 },
            'migrate dies when the source file cannot be unlinked' );
        chmod 0700, $bm;
    }
}

done_testing;

__END__

=pod

=head1 NAME

t/73-pagestore-coverage.t - branch and condition coverage for the page store

=head1 PURPOSE

This test drives the residual branch and condition paths of the saved-page and
transient-page store so its behaviour under malformed input, permission errors,
legacy-migration edge cases, and canonical flat-id validation fast paths is
pinned by an executable contract rather than left implicit.

=head1 WHY IT EXISTS

The coverage gate requires the page store to reach one hundred percent on every
Devel::Cover metric, including branch and condition. Several of the store's
defensive paths - missing and empty page ids, id inheritance for parsed pages
without a bookmark, the strict-then-lenient UTF-8 decode fallback, legacy JSON
migration skips, and the write/read/unlink failure exits - are never touched by
the happy-path suite. This test exercises each of them directly so those guards
cannot silently rot or be removed. It also pins all three legacy icon repairs
and verifies that unrelated Unicode replacement characters remain untouched
when the common no-repair path is used.

=head1 WHEN TO USE

Use this file when changing saved-page file layout, page id normalization,
transient encoding, legacy JSON migration, raw-file UTF-8 decoding, or legacy
icon normalization in the page store. Re-run it whenever a page-store branch
or validation fast path is added or reshaped.

=head1 HOW TO USE

Run C<perl -Ilib t/73-pagestore-coverage.t> or C<prove -lv t/73-pagestore-coverage.t>
while iterating. Confirm the page store stays fully covered under the repository
coverage gate before release. The permission-based cases self-skip when run as
the superuser, which bypasses the directory and file permission bits they probe.

=head1 WHAT USES IT

The repository test suite and the Devel::Cover coverage gate run this file to
keep the page store's error and migration branches verified end to end.

=head1 EXAMPLES

Example 1:

  perl -Ilib t/73-pagestore-coverage.t

Run the page-store coverage regression by itself.

Example 2:

  prove -lv t/73-pagestore-coverage.t

Run it verbosely through the harness while iterating on the page store.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the page store under the repository coverage gate.

=cut
