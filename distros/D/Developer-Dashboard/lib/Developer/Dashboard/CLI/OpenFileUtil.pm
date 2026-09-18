package Developer::Dashboard::CLI::OpenFileUtil;

use strict;
use warnings;

our $VERSION = '4.45';

use Exporter 'import';

our @EXPORT_OK = qw(_unique_matches _unique_existing_dirs);

# _unique_matches(@matches)
# Deduplicates resolved open-file matches while preserving their original order.
# Input: list of matched file path strings.
# Output: ordered list of unique file path strings.
sub _unique_matches {
    my (@matches) = @_;
    my %seen;
    return grep { defined && $_ ne '' && !$seen{$_}++ } @matches;
}

# _unique_existing_dirs(@candidates)
# Deduplicates a candidate path list while preserving original order and
# dropping anything undef, empty, or not an existing directory (DD-913,
# shared by Developer::Dashboard::CLI::OpenFile's _open_file_roots and
# Developer::Dashboard::CLI::OpenFileJavaSource's _java_source_archive_roots
# so the filter has one place to change if its semantics ever need to).
# Input: list of candidate path strings.
# Output: ordered list of unique, existing directory path strings.
sub _unique_existing_dirs {
    my (@candidates) = @_;
    my %seen;
    return grep { defined && $_ ne '' && -d $_ && !$seen{$_}++ } @candidates;
}

1;

__END__

=pod

=head1 NAME

Developer::Dashboard::CLI::OpenFileUtil - small shared helpers for dashboard of

=head1 SYNOPSIS

  use Developer::Dashboard::CLI::OpenFileUtil qw(_unique_matches _unique_existing_dirs);

=head1 DESCRIPTION

Holds the two tiny deduplication helpers shared between
C<Developer::Dashboard::CLI::OpenFile> and
C<Developer::Dashboard::CLI::OpenFileJavaSource> (DD-918's split). Neither
module imports from the other, so both depend on this instead - avoiding a
circular C<use> between the two larger modules.

=for comment FULL-POD-DOC START

=head1 PURPOSE

Deduplicate a list of file or directory path strings while preserving
original discovery order, optionally requiring each surviving candidate to
be an existing directory.

=head1 WHY IT EXISTS

C<Developer::Dashboard::CLI::OpenFile> and
C<Developer::Dashboard::CLI::OpenFileJavaSource> both need these two
one-line-bodied helpers. Having either module import from the other would
create a circular dependency at compile time, since each also needs to call
into the other (OpenFile dispatches into OpenFileJavaSource for Java
lookups). A tiny shared module both depend on breaks the cycle.

=head1 WHEN TO USE

Use this file when either OpenFile.pm or OpenFileJavaSource.pm needs a third
consumer for these helpers, or when their dedup semantics need to change in
one place for both.

=head1 HOW TO USE

  use Developer::Dashboard::CLI::OpenFileUtil qw(_unique_matches _unique_existing_dirs);
  my @deduped = _unique_matches(@candidates);
  my @dirs    = _unique_existing_dirs(@candidates);

=head1 WHAT USES IT

C<Developer::Dashboard::CLI::OpenFile> and
C<Developer::Dashboard::CLI::OpenFileJavaSource>.

=head1 EXAMPLES

  _unique_matches(qw(a b a c));        # => (a, b, c)
  _unique_existing_dirs('/tmp', '/nonexistent-xyz');   # => ('/tmp')

=for comment FULL-POD-DOC END

=cut
