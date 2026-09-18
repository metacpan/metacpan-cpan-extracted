package Developer::Dashboard::TextUtils;

use strict;
use warnings;

our $VERSION = '4.45';

use Exporter 'import';

our @EXPORT_OK = qw(_trim);

# _trim($text)
# Trims leading and trailing whitespace from a text string.
# Input: text string (or undef, normalized to '').
# Output: trimmed text string.
sub _trim {
    my ($text) = @_;
    $text = '' if !defined $text;
    $text =~ s/\A\s+//;
    $text =~ s/\s+\z//;
    return $text;
}

1;

__END__

=head1 NAME

Developer::Dashboard::TextUtils - shared small text-manipulation helpers

=head1 SYNOPSIS

  use Developer::Dashboard::TextUtils qw(_trim);
  my $clean = _trim("  hello world  \n");   # 'hello world'

=head1 DESCRIPTION

Provides C<_trim>, the single home for a whitespace-trim helper that used
to be written out identically in C<Developer::Dashboard::PageDocument> and
C<Developer::Dashboard::Web::App> (DD-891) - the same "small helper
reimplemented per file instead of shared" pattern this project already
fixed once in C<Developer::Dashboard::DirEntries> (DD-762).

=head1 PURPOSE

Give every module that needs to strip leading/trailing whitespace from a
text string one canonical implementation to call, rather than each
maintaining its own private copy that can silently drift out of sync with
the others.

=head1 WHY IT EXISTS

C<PageDocument::_trim> and C<Web::App::_trim> were byte-for-byte identical
- the same undef-guard, the same two substitutions, the same return - with
no reason for the two copies to ever diverge and no mechanism to notice if
one changed and the other did not. Extracting the shared behavior removes
that latent-drift risk before an edit to one copy silently stops matching
the other.

=head1 WHEN TO USE

Any module in this codebase that needs to trim leading/trailing whitespace
from a text string should C<use> this module rather than writing a private
C<_trim>.

=head1 HOW TO USE

Import C<_trim> explicitly via C<@EXPORT_OK> and call it on any text value
that may carry leading or trailing whitespace, including a value that may
be C<undef> (it normalizes to an empty string rather than raising a
warning):

  use Developer::Dashboard::TextUtils qw(_trim);
  my $clean = _trim($raw_text);
  my $title = _trim( $args{title} );   # safe even if $args{title} is undef

=head1 WHAT USES IT

C<Developer::Dashboard::PageDocument> and C<Developer::Dashboard::Web::App>,
at the 9 call sites the DD-891 extraction migrated.

=head1 EXAMPLES

  _trim(undef)                        # ''
  _trim('')                           # ''
  _trim("  hello world  \n")          # 'hello world'
  _trim('  internal   spacing  kept  ')  # 'internal   spacing  kept'

=cut
