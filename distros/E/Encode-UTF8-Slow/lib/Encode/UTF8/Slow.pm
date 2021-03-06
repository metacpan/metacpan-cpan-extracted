package Encode::UTF8::Slow;
use strict;
use Encode 'encode';
use Exporter 'import';

our $VERSION = 0.01;
our @EXPORT_OK = qw/bytes_to_codepoint codepoint_to_bytes/;

# utf8 handling per RFC 3629
# Char. number range  |        UTF-8 octet sequence
#    (hexadecimal)    |              (binary)
# --------------------+------------------------------------
# 0000 0000-0000 007F | 0xxxxxxx
# 0000 0080-0000 07FF | 110xxxxx 10xxxxxx
# 0000 0800-0000 FFFF | 1110xxxx 10xxxxxx 10xxxxxx
# 0001 0000-0010 FFFF | 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx

sub codepoint_to_bytes {
  my $codepoint = shift;

  if ($codepoint < 0x80) {
    return pack 'C', $codepoint;
  }
  elsif ($codepoint < 0x800) {
    return pack 'CC',
           $codepoint >>  6 | 0b11000000,
           $codepoint       & 0b00111111 | 0b10000000;
  }
  elsif ($codepoint < 0x10000) {
    return pack 'CCC',
           $codepoint >> 12 | 0b11100000,
           $codepoint >>  6 & 0b00111111 | 0b10000000,
           $codepoint       & 0b00111111 | 0b10000000;
  }
  else {
    return pack 'CCCC',
           $codepoint >> 18 | 0b11110000,
           $codepoint >> 12 & 0b00111111 | 0b10000000,
           $codepoint >>  6 & 0b00111111 | 0b10000000,
           $codepoint       & 0b00111111 | 0b10000000;
  }
}

sub bytes_to_codepoint {
  # treat the scalar as bytes/octets
  my $input    = encode('UTF-8', shift);

  # length returns number of bytes
  my $len      = length $input;
  my $template = 'C' x $len;
  my @bytes    = unpack $template, $input;

  # reverse encoding
  if ($len == 1) {
    return $bytes[0];
  }
  elsif ($len == 2) {
    return (($bytes[0] & 0b00011111) <<  6) +
            ($bytes[1] & 0b00111111);
  }
  elsif ($len == 3) {
    return (($bytes[0] & 0b00001111) << 12) +
           (($bytes[1] & 0b00111111) <<  6) +
           ( $bytes[2] & 0b00111111);
  }
  else {
    return (($bytes[0] & 0b00000111) << 18) +
           (($bytes[1] & 0b00111111) << 12) +
           (($bytes[2] & 0b00111111) <<  6) +
            ($bytes[3] & 0b00111111);
  }
}

1;
__END__
=encoding utf8

=head1 NAME

Encode::UTF8::Slow - A pure Perl, naive UTF-8 encoder/decoder

=head1 SYNOPSIS

  use Encode::UTF8::Slow qw/bytes_to_codepoint codepoint_to_bytes/;

  my $bytes = codepoint_to_bytes(0x1F4FA); #television

  my $codepoint = bytes_to_codepoint('🗼');

=head1 FUNCTIONS

=head2 codepoint_to_bytes

Takes a Unicode codepoint number and returns a scalar of UTF-8 encoded bytes
for it. Exported on request.

=head2 bytes_to_codepoint

Takes UTF-8 encoded bytes in a scalar and returns the Unicode codepoint for it.
Exported on request.

=head1 WARNING

This is a naive encoder - it doesn't handle UTF-16 pairs, BOM or other
noncharacters like 0xFFFE. It's also very slow!

=head1 SEE ALSO

=over 4

=item *

L<Unicode::UTF8|https://metacpan.org/pod/Unicode::UTF8> for a super fast UTF-8 encoder.

=item *

L<Building a UTF-8 encoder in Perl|http://perltricks.com/article/building-a-utf-8-encoder-in-perl/> my PerlTricks.com article about this code.

=item *

L<RFC 3629|https://tools.ietf.org/html/rfc3629> - which defines the current UTF-8 standard.

=back

=head1 REPOSITORY

This code is hosted at L<GitHub|https://github.com/dnmfarrell/Encode-UTF8-Slow>.

=head1 AUTHOR

E<copy> 2016 David Farrell

=head1 LICENSE

FreeBSD, see LICENSE.

=cut
