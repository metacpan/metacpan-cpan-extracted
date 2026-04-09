package Developer::Dashboard::CLI::SeededPages;

use strict;
use warnings;

our $VERSION = '2.02';

use File::Basename qw(dirname);
use File::Spec;
use File::ShareDir qw(dist_dir);

use Developer::Dashboard::PageDocument;

my %PAGE_CACHE;

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
embed the full bookmark source for the API and SQL dashboards.

=for comment FULL-POD-DOC START

=head1 PURPOSE

Perl module in the Developer Dashboard codebase. This file loads shipped bookmark source files from the distribution share directory.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to keep this responsibility in reusable Perl code instead of hiding it in the thin C<dashboard> switchboard, bookmark text, or duplicated helper scripts. That separation makes the runtime easier to test, safer to change, and easier for contributors to navigate.

=head1 WHEN TO USE

Use this file when you are changing the underlying runtime behaviour it owns, when you need to call its routines from another part of the project, or when a failing test points at this module as the real owner of the bug.

=head1 HOW TO USE

Load C<Developer::Dashboard::CLI::SeededPages> from Perl code under C<lib/> or from a focused test, then use the public routines documented in the inline function comments and existing SYNOPSIS/METHODS sections. This file is not a standalone executable.

=head1 WHAT USES IT

This file is used by whichever runtime path owns this responsibility: the public C<dashboard> entrypoint, staged private helper scripts under C<share/private-cli/>, the web runtime, update flows, and the focused regression tests under C<t/>.

=head1 EXAMPLES

  perl -Ilib -MDeveloper::Dashboard::CLI::SeededPages -e 'print qq{loaded\n}'

That example is only a quick load check. For real usage, follow the public routines already described in the inline code comments and any existing SYNOPSIS section.

=for comment FULL-POD-DOC END

=cut
