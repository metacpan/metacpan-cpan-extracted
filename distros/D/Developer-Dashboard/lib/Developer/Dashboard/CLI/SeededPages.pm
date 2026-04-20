package Developer::Dashboard::CLI::SeededPages;

use strict;
use warnings;

our $VERSION = '2.72';

use File::Basename qw(dirname);
use File::Spec;
use File::ShareDir qw(dist_dir);
use Developer::Dashboard::JSON qw(json_decode json_encode);
use Developer::Dashboard::SeedSync ();

use Developer::Dashboard::PageDocument;

my %PAGE_CACHE;
my %ID_TO_ASSET = (
    'api-dashboard' => 'api-dashboard.page',
    'sql-dashboard' => 'sql-dashboard.page',
);
my %LEGACY_MANAGED_PAGE_MD5 = (
    'sql-dashboard' => [
        '7d9101e0e2585c159e575f0dbd49b3ef',
        'f62a03c9ff7d25cdce65ce569cf2e07b',
        '10a14e5749f374a78429654b6c49b5f0',
    ],
);

# api_dashboard_page()
# Loads the seeded api-dashboard bookmark definition from the shipped asset file.
# Input: none.
# Output: Developer::Dashboard::PageDocument object.
sub api_dashboard_page {
    return _page_from_asset('api-dashboard.page');
}

# sql_dashboard_page()
# Loads the seeded sql-dashboard bookmark definition from the shipped asset file.
# Input: none.
# Output: Developer::Dashboard::PageDocument object.
sub sql_dashboard_page {
    return _page_from_asset('sql-dashboard.page');
}

# page_for_id($id)
# Loads one shipped seeded bookmark page by its saved bookmark id.
# Input: seeded bookmark id string such as api-dashboard or sql-dashboard.
# Output: Developer::Dashboard::PageDocument object.
sub page_for_id {
    my ($id) = @_;
    my $filename = _seeded_page_asset_filename($id);
    return _page_from_asset($filename);
}

# seed_manifest_path(%args)
# Resolves the runtime manifest file that records the last shipped md5 written
# for each dashboard-managed seeded page.
# Input: hash containing a required path registry under the "paths" key.
# Output: absolute manifest file path string.
sub seed_manifest_path {
    my (%args) = @_;
    my $paths = $args{paths} || die 'Missing paths registry';
    return File::Spec->catfile( $paths->config_root, 'seeded-pages.json' );
}

# known_managed_page_md5s($id)
# Returns the list of md5 digests that identify shipped dashboard-managed
# copies of one seeded page across current and bridged older releases.
# Input: seeded bookmark id string.
# Output: ordered list of lowercase md5 hex strings.
sub known_managed_page_md5s {
    my ($id) = @_;
    my $filename = _seeded_page_asset_filename($id);
    my %seen;
    my @md5s = (
        Developer::Dashboard::SeedSync::content_md5( _seeded_page_instruction($filename) ),
        @{ $LEGACY_MANAGED_PAGE_MD5{$id} || [] },
    );
    return grep { defined $_ && $_ ne '' && !$seen{$_}++ } @md5s;
}

# is_known_managed_page_md5(%args)
# Decides whether one md5 digest belongs to a shipped dashboard-managed seeded
# page copy that may be refreshed automatically.
# Input: seeded bookmark id string under "id" and md5 hex string under "md5".
# Output: boolean true when the digest belongs to a known dashboard-managed copy.
sub is_known_managed_page_md5 {
    my (%args) = @_;
    my $id  = $args{id}  || '';
    my $md5 = $args{md5} || '';
    return 0 if $id eq '' || $md5 eq '';
    my $matches = scalar grep { $_ eq $md5 } known_managed_page_md5s($id);
    return $matches ? 1 : 0;
}

# ensure_seeded_page(%args)
# Writes or refreshes one shipped seeded page only when the target is missing,
# unchanged from a known dashboard-managed copy, or matches the recorded seed
# manifest md5. Diverged user-edited pages are preserved.
# Input: hash containing required page store, path registry, and page document
# under "pages", "paths", and "page".
# Output: status string: created, updated, current, or preserved.
sub ensure_seeded_page {
    my (%args) = @_;
    my $pages = $args{pages} || die 'Missing page store';
    my $paths = $args{paths} || die 'Missing paths registry';
    my $page  = $args{page}  || die 'Missing seeded page';
    if ( ref($page) ne 'Developer::Dashboard::PageDocument' ) {
        $page = Developer::Dashboard::PageDocument->from_hash($page);
    }

    my $id = $page->as_hash->{id} || die 'Missing seeded page id';
    my $wanted = $page->canonical_instruction;
    my $wanted_md5 = Developer::Dashboard::SeedSync::content_md5($wanted);

    my $current;
    my $loaded = eval {
        $current = $pages->read_saved_entry($id);
        1;
    };
    if ( !$loaded ) {
        die $@ if $@ !~ /Page '\Q$id\E' not found/;
        $pages->save_page($page);
        _record_manifest_md5(
            paths => $paths,
            id    => $id,
            md5   => $wanted_md5,
        );
        return 'created';
    }

    my $current_md5 = Developer::Dashboard::SeedSync::content_md5($current);
    if ( $current_md5 eq $wanted_md5 ) {
        _record_manifest_md5(
            paths => $paths,
            id    => $id,
            md5   => $wanted_md5,
        );
        return 'current';
    }

    if ( _manifest_md5_matches( paths => $paths, id => $id, md5 => $current_md5 )
        || is_known_managed_page_md5( id => $id, md5 => $current_md5 ) )
    {
        $pages->save_page($page);
        _record_manifest_md5(
            paths => $paths,
            id    => $id,
            md5   => $wanted_md5,
        );
        return 'updated';
    }

    return 'preserved';
}

# _page_from_asset($filename)
# Reads one seeded bookmark instruction file and parses it into a page document.
# Input: asset filename under share/seeded-pages.
# Output: Developer::Dashboard::PageDocument object.
sub _page_from_asset {
    my ($filename) = @_;
    die "Missing seeded page filename\n" if !defined $filename || $filename eq '';
    my $instruction = _seeded_page_instruction($filename);
    return Developer::Dashboard::PageDocument->from_instruction($instruction);
}

# _seeded_page_instruction($filename)
# Returns one shipped seeded bookmark instruction string, caching repeated reads.
# Input: asset filename under share/seeded-pages.
# Output: bookmark instruction string.
sub _seeded_page_instruction {
    my ($filename) = @_;
    die "Missing seeded page filename\n" if !defined $filename || $filename eq '';
    return $PAGE_CACHE{$filename} if exists $PAGE_CACHE{$filename};

    my $path = _seeded_page_asset_path($filename);
    open my $fh, '<:raw', $path or die "Unable to read $path: $!";
    my $instruction = do { local $/; <$fh> };
    close $fh or die "Unable to close $path: $!";
    $PAGE_CACHE{$filename} = $instruction;
    return $instruction;
}

# _seeded_page_asset_filename($id)
# Resolves the shipped seeded-page asset filename for one seeded bookmark id.
# Input: seeded bookmark id string.
# Output: asset filename string.
sub _seeded_page_asset_filename {
    my ($id) = @_;
    die "Unknown seeded page id '$id'\n" if !defined $id || !$ID_TO_ASSET{$id};
    return $ID_TO_ASSET{$id};
}

# _seeded_page_asset_path($filename)
# Resolves one shipped seeded bookmark asset path from the repo tree during
# development or from the installed distribution share dir after install.
# Input: asset filename under share/seeded-pages.
# Output: absolute asset path string.
sub _seeded_page_asset_path {
    my ($filename) = @_;
    die "Missing seeded page filename\n" if !defined $filename || $filename eq '';
    my $repo_path = File::Spec->catfile( _repo_seeded_pages_root(), $filename );
    return $repo_path if -f $repo_path;
    return File::Spec->catfile( _shared_seeded_pages_root(), $filename );
}

# _repo_seeded_pages_root()
# Resolves the repo-tree seeded-pages directory for development checkouts.
# Input: none.
# Output: absolute seeded-pages directory path.
sub _repo_seeded_pages_root {
    return File::Spec->catdir(
        dirname(__FILE__),
        File::Spec->updir,
        File::Spec->updir,
        File::Spec->updir,
        File::Spec->updir,
        'share',
        'seeded-pages',
    );
}

# _shared_seeded_pages_root()
# Resolves the installed distribution share directory for seeded bookmark assets.
# Input: none.
# Output: absolute seeded-pages directory path inside the installed dist share.
sub _shared_seeded_pages_root {
    return File::Spec->catdir( dist_dir('Developer-Dashboard'), 'seeded-pages' );
}

# _read_manifest(%args)
# Loads the runtime seeded-page manifest when present.
# Input: hash containing a required path registry under the "paths" key.
# Output: hash reference of seeded-page manifest entries.
sub _read_manifest {
    my (%args) = @_;
    my $manifest_path = seed_manifest_path(%args);
    return {} if !-f $manifest_path;
    open my $fh, '<:raw', $manifest_path or die "Unable to read $manifest_path: $!";
    my $json = do { local $/; <$fh> };
    close $fh or die "Unable to close $manifest_path: $!";
    $json = '{}' if !defined $json || $json =~ /\A\s*\z/;
    my $manifest = json_decode($json);
    die "Seed manifest at $manifest_path must decode to a hash\n" if ref($manifest) ne 'HASH';
    return $manifest;
}

# _write_manifest(%args)
# Persists one seeded-page manifest hash to the runtime config tree.
# Input: hash containing a required path registry under "paths" and a manifest
# hash reference under "manifest".
# Output: manifest file path string.
sub _write_manifest {
    my (%args) = @_;
    my $paths = $args{paths} || die 'Missing paths registry';
    my $manifest = $args{manifest};
    die 'Missing seeded page manifest hash' if ref($manifest) ne 'HASH';
    my $manifest_path = seed_manifest_path( paths => $paths );
    open my $fh, '>:raw', $manifest_path or die "Unable to write $manifest_path: $!";
    print {$fh} json_encode($manifest);
    print {$fh} "\n";
    close $fh or die "Unable to close $manifest_path: $!";
    $paths->secure_file_permissions($manifest_path) if $paths->can('secure_file_permissions');
    return $manifest_path;
}

# _record_manifest_md5(%args)
# Records the latest shipped md5 for one seeded page in the runtime manifest.
# Input: hash containing required path registry, seeded page id, and md5 string
# under "paths", "id", and "md5".
# Output: recorded md5 string.
sub _record_manifest_md5 {
    my (%args) = @_;
    my $paths = $args{paths} || die 'Missing paths registry';
    my $id    = $args{id}    || die 'Missing seeded page id';
    my $md5   = $args{md5}   || die 'Missing seeded page md5';
    my $manifest = _read_manifest( paths => $paths );
    $manifest->{$id} = {
        asset => _seeded_page_asset_filename($id),
        md5   => $md5,
    };
    _write_manifest(
        paths    => $paths,
        manifest => $manifest,
    );
    return $md5;
}

# _manifest_md5_matches(%args)
# Checks whether the runtime manifest recorded one seeded page at the supplied
# md5 digest, proving the current file is still the last dashboard-managed copy.
# Input: hash containing required path registry, seeded page id, and md5 string.
# Output: boolean true when the manifest matches the supplied md5.
sub _manifest_md5_matches {
    my (%args) = @_;
    my $paths = $args{paths} || die 'Missing paths registry';
    my $id    = $args{id}    || '';
    my $md5   = $args{md5}   || '';
    return 0 if $id eq '' || $md5 eq '';
    my $manifest = _read_manifest( paths => $paths );
    my $recorded = $manifest->{$id}{md5} || '';
    return $recorded eq $md5 ? 1 : 0;
}

1;

__END__

=head1 NAME

Developer::Dashboard::CLI::SeededPages - shipped bookmark assets for dashboard init

=head1 SYNOPSIS

  use Developer::Dashboard::CLI::SeededPages;
  my $page = Developer::Dashboard::CLI::SeededPages::api_dashboard_page();

=head1 DESCRIPTION

Loads the shipped seeded bookmark instruction files used by C<dashboard init>
and runtime bootstrap so the public C<dashboard> entrypoint does not need to
embed the full bookmark source for the API and SQL dashboards. It also owns
the non-destructive starter-page refresh contract: missing or stale
dashboard-managed copies may refresh to the latest shipped seed, while
diverged user-edited saved pages stay untouched.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module manages shipped starter pages such as C<project-home>, C<api-dashboard>, and C<sql-dashboard>. It decides whether a runtime should receive a seed, whether a dashboard-managed copy is still safe to refresh, and how bridged historical managed digests are recognized during upgrades.

=head1 WHY IT EXISTS

It exists because seeding starter pages is not just a copy operation. The runtime must preserve real user edits while still refreshing dashboard-managed pages when the shipped content changed or when an older managed digest needs to be upgraded in place.

=head1 WHEN TO USE

Use this file when changing dashboard init seeding rules, starter-page refresh behavior, bridge digests for older releases, or the safe-update policy for managed seed copies in runtime dashboards.

=head1 HOW TO USE

Call the seeding and refresh routines from init/update flows with the active runtime paths and page store. Keep managed-seed detection here so the command layer does not guess about whether a page is user-owned or dashboard-managed.

=head1 WHAT USES IT

It is used by C<dashboard init>, runtime bootstrap/update scripts, seed-refresh regressions for stale managed copies, and the SQL/API dashboard starter-page tests.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::CLI::SeededPages -e 1

Do a direct compile-and-load check against the module from a source checkout.

Example 2:

  prove -lv t/04-update-manager.t t/26-sql-dashboard.t

Run the focused regression tests that most directly exercise this module's behavior.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite before release.


=for comment FULL-POD-DOC END

=cut
