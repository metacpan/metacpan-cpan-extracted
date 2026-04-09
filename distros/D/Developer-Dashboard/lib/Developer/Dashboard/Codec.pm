package Developer::Dashboard::Codec;

use strict;
use warnings;

our $VERSION = '2.02';

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

Perl module in the Developer Dashboard codebase. This file wraps the project encoding and decoding helpers used across runtime data flows.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to keep this responsibility in reusable Perl code instead of hiding it in the thin C<dashboard> switchboard, bookmark text, or duplicated helper scripts. That separation makes the runtime easier to test, safer to change, and easier for contributors to navigate.

=head1 WHEN TO USE

Use this file when you are changing the underlying runtime behaviour it owns, when you need to call its routines from another part of the project, or when a failing test points at this module as the real owner of the bug.

=head1 HOW TO USE

Load C<Developer::Dashboard::Codec> from Perl code under C<lib/> or from a focused test, then use the public routines documented in the inline function comments and existing SYNOPSIS/METHODS sections. This file is not a standalone executable.

=head1 WHAT USES IT

This file is used by whichever runtime path owns this responsibility: the public C<dashboard> entrypoint, staged private helper scripts under C<share/private-cli/>, the web runtime, update flows, and the focused regression tests under C<t/>.

=head1 EXAMPLES

  perl -Ilib -MDeveloper::Dashboard::Codec -e 'print qq{loaded\n}'

That example is only a quick load check. For real usage, follow the public routines already described in the inline code comments and any existing SYNOPSIS section.

=for comment FULL-POD-DOC END

=cut
