package Developer::Dashboard::SeedSync;

use strict;
use warnings;

our $VERSION = '2.76';

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

This module provides the MD5-based content comparison helpers used when the dashboard stages private helpers and seeds starter pages. It answers the question "did the shipped managed content actually change?" without relying on external checksum tools.

=head1 WHY IT EXISTS

It exists because seed refresh and helper staging have to distinguish unchanged managed files from files that need a rewrite. Putting that digest logic in one module keeps the non-destructive bootstrap contract portable and testable.

=head1 WHEN TO USE

Use this file when changing how managed seed files are compared, when adding a new dashboard-managed asset type, or when diagnosing why init/bootstrap did or did not refresh a managed runtime file.

=head1 HOW TO USE

Call C<content_md5>, C<same_content_md5>, or C<file_matches_content_md5> before rewriting a managed file. The helpers accept either in-memory strings or an on-disk file path, so callers do not need shelling-out checksum code.

=head1 WHAT USES IT

It is used by helper staging, seeded-page refresh logic, historical managed-digest bridges, and tests that verify non-destructive managed file updates.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::SeedSync -e 1

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
