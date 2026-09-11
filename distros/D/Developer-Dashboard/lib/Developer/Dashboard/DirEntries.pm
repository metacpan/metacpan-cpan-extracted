package Developer::Dashboard::DirEntries;

use strict;
use warnings;

our $VERSION = '4.31';

use Exporter 'import';

our @EXPORT_OK = qw(sorted_dir_entries);

# sorted_dir_entries($dh)
# Reads every entry from an already-open directory handle, excluding the
# dot and dot-dot self/parent entries, sorted.
# Input: an open directory handle.
# Output: a sorted list of entry names, with . and .. removed.
sub sorted_dir_entries {
    my ($dh) = @_;
    return sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
}

1;

__END__

=head1 NAME

Developer::Dashboard::DirEntries - shared dot-filtered directory listing helper

=head1 SYNOPSIS

  use Developer::Dashboard::DirEntries qw(sorted_dir_entries);
  opendir my $dh, $some_dir or die "Unable to read $some_dir: $!";
  for my $entry ( sorted_dir_entries($dh) ) { ... }

=head1 DESCRIPTION

Provides C<sorted_dir_entries>, the single home for a filter that used to be
written out identically at six call sites across three modules.

=head1 PURPOSE

This module exists to give the codebase one place to read a directory's
entries excluding C<.> and C<..>, sorted, instead of repeating the same
C<grep>/C<sort> idiom verbatim at every call site.

=head1 WHY IT EXISTS

Six sites in C<SkillDispatcher.pm>, C<DockerCompose.pm> and
C<CLI/Which.pm> carried byte-identical C<sort grep { $_ ne '.' && $_ ne
'..' } readdir($dh)> expressions with no shared helper (DD-762). Each
instance was correct, but a future change to what counts as a filterable
entry would have to find every site by hand, since nothing connects them
by name.

=head1 WHEN TO USE

Use C<sorted_dir_entries> whenever code needs to iterate a directory's
real entries (excluding the self/parent pseudo-entries) in a stable
order. It does not own opening or closing the handle - callers keep that
responsibility, since error handling and root resolution differ per
caller.

=head1 HOW TO USE

Open the directory yourself first, with whatever error handling your
caller needs, then pass the open handle straight to
C<sorted_dir_entries>. It never opens or closes anything on its own, so
it is safe to call from inside a loop that reuses one handle, or from
code that has already validated the directory exists:

  opendir my $dh, $dir or die "Unable to read $dir: $!";
  for my $entry ( sorted_dir_entries($dh) ) {
      ...
  }
  closedir $dh;

=head1 WHAT USES IT

C<Developer::Dashboard::SkillDispatcher>, C<Developer::Dashboard::DockerCompose>
and C<Developer::Dashboard::CLI::Which> all call it in place of their own
former copies of the same filter.

=head1 EXAMPLES

Example 1:

  opendir my $dh, '/tmp' or die $!;
  my @names = sorted_dir_entries($dh);

Returns every entry under C</tmp> except C<.> and C<..>, sorted.

=cut
