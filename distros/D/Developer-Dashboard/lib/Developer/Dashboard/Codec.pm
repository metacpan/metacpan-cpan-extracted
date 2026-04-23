package Developer::Dashboard::Codec;

use strict;
use warnings;

our $VERSION = '3.04';

use Exporter 'import';
use IO::Compress::Gzip qw(gzip $GzipError);
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use MIME::Base64 qw(encode_base64 decode_base64);

our @EXPORT_OK = qw(encode_payload decode_payload);

# encode_payload($text)
# Compresses and base64-encodes a text payload.
# Input: scalar text value.
# Output: encoded scalar token or undef for undefined/empty input.
sub encode_payload {
    my ($text) = @_;
    return if !defined $text;

    gzip \$text => \my $zipped
      or die "gzip failed: $GzipError";

    return encode_base64( $zipped, '' );
}

# decode_payload($token)
# Decodes and inflates a previously encoded payload token.
# Input: base64 token scalar.
# Output: decoded text scalar or undef for undefined/empty input.
sub decode_payload {
    my ($token) = @_;
    return if !defined $token || $token eq '';

    my $zipped = decode_base64($token);
    gunzip \$zipped => \my $text
      or die "gunzip failed: $GunzipError";

    return $text;
}

1;

__END__

=head1 NAME

Developer::Dashboard::Codec - payload encoding helpers for Developer Dashboard

=head1 SYNOPSIS

  use Developer::Dashboard::Codec qw(encode_payload decode_payload);
  my $token = encode_payload($text);
  my $text  = decode_payload($token);

=head1 DESCRIPTION

This module provides the compact payload transport used by Developer
Dashboard for transient page and action tokens.

=head1 FUNCTIONS

=head2 encode_payload

Compress and base64-encode a text payload.

=head2 decode_payload

Decode and inflate a token back to text.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module implements the compressed token format used by transient page URLs and action payloads. It gzips text payloads and base64-encodes them for transport, then reverses that process when a token comes back into the runtime.

=head1 WHY IT EXISTS

It exists because token encoding is a core transport contract shared by bookmarks, Ajax helpers, and page/action flows. Keeping that codec in one place prevents subtle mismatches between producers and consumers.

=head1 WHEN TO USE

Use this file when changing token size, encoding behavior, compression handling, or any flow that creates or reads the portable payload tokens used in URLs and form posts.

=head1 HOW TO USE

Import C<encode_payload> and C<decode_payload> where a runtime component needs to turn text into a transport token or recover the original text from one. The interface is intentionally small so the token contract stays easy to reason about.

=head1 WHAT USES IT

It is used by transient page and action flows, by compatibility helpers that still expose tokenised URLs, and by coverage tests that exercise encode/decode stability.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::Codec -e 1

Do a direct compile-and-load check against the module from a source checkout.

Example 2:

  prove -lv t/21-refactor-coverage.t t/00-load.t

Run the focused regression tests that most directly exercise this module's behavior.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite before release.


=for comment FULL-POD-DOC END

=cut
