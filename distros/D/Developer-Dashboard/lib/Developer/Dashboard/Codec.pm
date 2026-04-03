package Developer::Dashboard::Codec;

use strict;
use warnings;

our $VERSION = '1.33';

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

=cut
