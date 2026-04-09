package Developer::Dashboard::SeedSync;

use strict;
use warnings;

our $VERSION = '2.02';

use Digest::MD5 qw(md5_hex);
use Encode qw(encode_utf8);

# content_md5($content)
# Returns the MD5 digest for one in-memory text/blob payload.
# Input: optional scalar content string.
# Output: lowercase md5 hex string.
sub content_md5 {
    my ($content) = @_;
    $content = '' if !defined $content;
    return md5_hex( _content_bytes($content) );
}

# same_content_md5($left, $right)
# Compares two payloads by MD5 digest instead of relying on external tools.
# Input: left and right scalar content strings.
# Output: boolean true when both payloads have the same md5 digest.
sub same_content_md5 {
    my ( $left, $right ) = @_;
    return content_md5($left) eq content_md5($right);
}

# file_matches_content_md5($path, $content)
# Compares one on-disk file against in-memory content via MD5 digest.
# Input: absolute file path string and desired scalar content string.
# Output: boolean true when the file exists and matches the provided content.
sub file_matches_content_md5 {
    my ( $path, $content ) = @_;
    return 0 if !defined $path || $path eq '' || !-f $path;
    open my $fh, '<:raw', $path or die "Unable to read $path: $!";
    my $existing = do { local $/; <$fh> };
    close $fh or die "Unable to close $path: $!";
    return same_content_md5( $existing, $content );
}

# _content_bytes($content)
# Normalizes Perl scalar content into a byte string for stable md5 hashing.
# Input: scalar content string, possibly utf8-flagged.
# Output: byte string suitable for Digest::MD5.
sub _content_bytes {
    my ($content) = @_;
    return encode_utf8($content) if utf8::is_utf8($content);
    return $content;
}

1;

__END__

=head1 NAME

Developer::Dashboard::SeedSync - md5-based content checks for staged seed files

=head1 SYNOPSIS

  use Developer::Dashboard::SeedSync qw();

  my $same = Developer::Dashboard::SeedSync::file_matches_content_md5(
      $path,
      $wanted_content,
  );

=head1 DESCRIPTION

This module centralizes the content-digest checks used when Developer
Dashboard decides whether built-in helper files or shipped seeded bookmark
files need to be rewritten.

=for comment FULL-POD-DOC START

=head1 PURPOSE

Perl module in the Developer Dashboard codebase. This file provides reusable
MD5-based content comparison helpers for runtime seed files and staged helper
scripts. Open this file when you need the implementation, regression
coverage, or runtime entrypoint for that responsibility rather than guessing
which part of the tree owns it.

=head1 WHY IT EXISTS

It exists so C<dashboard init> and related bootstrap paths can skip copying
identical managed files without relying on shell commands or external md5
tools. Keeping the digest logic in Perl makes the copy contract portable,
testable, and explicit.

=head1 WHEN TO USE

Use this file when you are deciding whether a dashboard-managed helper,
seeded bookmark, or another shipped runtime file actually changed before
rewriting it.

=head1 HOW TO USE

Load C<Developer::Dashboard::SeedSync> and call
C<content_md5>, C<same_content_md5>, or C<file_matches_content_md5>.
Use those helpers before rewriting a managed runtime file so identical files
can be skipped cleanly.

=head1 WHAT USES IT

This file is used by the private helper staging path, the seeded bookmark
bootstrap/update flow, and the focused regression tests under C<t/>.

=head1 EXAMPLES

  perl -Ilib -MDeveloper::Dashboard::SeedSync -e '
    print Developer::Dashboard::SeedSync::same_content_md5("a\n", "a\n") ? "same\n" : "different\n";
  '

  perl -Ilib -MDeveloper::Dashboard::SeedSync -e '
    print Developer::Dashboard::SeedSync::content_md5("api-dashboard\n"), "\n";
  '

=for comment FULL-POD-DOC END

=cut
