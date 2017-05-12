package Encode::Base58::GMP;
use strict;
use warnings;
use 5.008_009;
our $VERSION   = '1.00';

use base         qw(Exporter);
our @EXPORT    = qw(encode_base58 decode_base58);
our @EXPORT_OK = qw(base58_from_to base58_flickr_to_gmp base58_gmp_to_flickr md5_base58);

use Carp;
use Digest::MD5  qw(md5_hex);
use Math::GMPz   qw(Rmpz_get_str);
use Scalar::Util qw(blessed);

sub encode_base58 {
  my ($int, $alphabet, $len) = @_;

  my $base58 = blessed($int) && $int->isa('Math::GMPz') ?
    Rmpz_get_str($int, 58) :
    Rmpz_get_str(Math::GMPz->new($int), 58);

  if ($len && $len =~ m|\A[0-9]+\Z|) {
    $base58 = sprintf("%0${len}s",$base58);
  }

  $alphabet && lc $alphabet eq 'gmp' ?
    $base58 :
    base58_from_to($base58,'gmp',$alphabet||'flickr');
}

sub decode_base58 { 
  my ($base58, $alphabet) = @_;

  unless ($alphabet && lc $alphabet eq 'gmp') {
    $base58 = base58_from_to($base58,$alphabet||'flickr','gmp');
  }

  Math::GMPz->new($base58, 58);
}

sub base58_from_to {
  my ($base58, $from_alphabet, $to_alphabet) = @_;

  my $alphabets = {
    bitcoin => '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz',
    flickr  => '123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ',
    gmp     => '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuv'
  };

  $from_alphabet = lc($from_alphabet||'flickr');
  $to_alphabet   = lc($to_alphabet  ||'flickr');

  return $base58 if $from_alphabet eq $to_alphabet;

  my $from_digits = $alphabets->{$from_alphabet}
    or croak("Encode::Base58::GMP::from_to called with invalid from_alphabet [$from_alphabet]");
  my $to_digits   = $alphabets->{$to_alphabet}
    or croak("Encode::Base58::GMP::from_to called with invalid to_alphabet [$to_alphabet]");

  if ($from_alphabet eq 'gmp') {
    if ($to_alphabet eq 'flickr') {
      $base58 =~ y|0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuv|123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ|;
    } else {
      $base58 =~ y|0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuv|123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz|;
    }
  } elsif ($from_alphabet eq 'flickr') {
    if ($to_alphabet eq 'gmp') {
      $base58 =~ y|123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ|0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuv|;
    } else {
      $base58 =~ y|123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ|123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz|;
    }
  } else {
    if ($to_alphabet eq 'gmp') {
      $base58 =~ y|123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz|0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuv|;
    } else {
      $base58 =~ y|123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz|123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ|;
    }
  }
  return $base58;
}

sub base58_gmp_to_flickr {
  return base58_from_to(shift||'','gmp','flickr');
}

sub base58_flickr_to_gmp {
  return base58_from_to(shift||'','flickr','gmp');
}

sub md5_base58 {
  encode_base58('0x'.md5_hex(shift), shift, 22);
}

1;

# ABSTRACT: High speed Base58 encoding using GMP with BigInt and MD5 support

=head1 NAME

Encode::Base58::GMP - High speed Base58 encoding using GMP with BigInt and MD5 support

For version 1.0 upgrades, please read the INCOMPATIBLE CHANGES section below.

=head1 SYNOPSIS

  use Encode::Base58::GMP;

  # Encode Int as Base58
  encode_base58(12345);                        # => 4ER string
  encode_base58('0x3039');                     # => 4ER string
  encode_base58(Math::GMPz->new('0x3039'));    # => 4ER string

  # Encode Int as Base58 using GMP alphabet
  encode_base58(12345,'bitcoin');              # => 4fr string
  encode_base58(12345,'gmp');                  # => 3cn string

  # Decode Base58 as Math::GMPz Int
  decode_base58('4ER');                        # => 12345 Math::GMPz object
  int decode_base58('4ER');                    # => 12345 integer

  # Decode Base58 as Math::GMPz Int using GMP alphabet
  decode_base58('4fr','bitcoin');              # => 12345 Math::GMPz object
  decode_base58('3cn','gmp');                  # => 12345 Math::GMPz object

  # MD5 Base58 Digest
  md5_base58('foo@bar.com');                   # => w6fdCRXnUXyz7EtDn5TgN9

  # Convert between alphabets for Bitcoin, Flickr and GMP
  base58_from_to('123456789abcdefghijk','flickr','gmp') # => 0123456789ABCDEFGHIJ
  base58_from_to('0123456789ABCDEFGHIJ','gmp','flickr') # => 123456789abcdefghijk

  # Convert between Flickr and GMP - Deprecated
  base58_flickr_to_gmp('123456789abcdefghijk') # => 0123456789ABCDEFGHIJ
  base58_gmp_to_flickr('0123456789ABCDEFGHIJ') # => 123456789abcdefghijk

=head1 DESCRIPTION

Encode::Base58::GMP is a Base58 encoder/decoder implementation using the GNU
Multiple Precision Arithmetic Library (GMP) with transcoding between
Flickr, Bitcoin and GMP Base58 implementations. The Flickr alphabet is the
default and used when no alphabet is provided.

Flickr Alphabet: [0-9a-zA-Z] excluding [0OIl] to improve human readability

Bitcoin Alphabet: [0-9A-Za-z] excluding [0OIl] to improve human readability

GMP Alphabet: [0-9A-Za-v]

The encode_base58, decode_base58 and md5_base58 methods support an alphabet
parameter which can be set to the supported alphabets ['bitcoin', 'flickr',
'gmp'] to indicate the value to be encoded or decoded.

=head2 Requirements

This module requires GMP 4.2.0 and above. Prior versions are limited to Base36.

Perl 5.8.9 or above is required to ensure proper bigint handling. If you are not
using bigint numbers, it may be possible to skip the bigint tests and do a force
install; however, lower Perl versions are not supported.

=head1 FUNCTIONS

=head2 encode_base58 ( $number [, $alphabet ] )

This routine encodes a $number in Base58. $number can be a Math::GMPz object
or a binary, octal, decimal or hexidecimal number. Binary, octal and hexidecimal
string literals must be prefixed with 0[Bb]/0/0[Xx] respectively. The Flickr
alphabet is used unless $alphabet is set to 'gmp'.

=head2 decode_base58 ( $base58 [, $alphabet ] )

This routine decodes a Base58 value and returns a Math::GMPz object. Use int
on the return value to convert the Math::GMPz object to an integer.
The Flickr alphabet is used unless $alphabet is set to 'gmp'.

=head2 base58_from_to( $base58, $from_alphabet, $to_alphabet )

This routine encodes a Base58 string from one encoding to another encoding.
This routing is not exported by default.

=head2 base58_flickr_to_gmp( $base58_as_flickr )

This routine converts a Flickr Base58 string to a GMP Base58 string. This
routine is not exported by default.

=head2 base58_gmp_to_flickr( $base58_as_gmp )

This routine converts a GMP Base58 string to a Flickr Base58 string. This
routine is not exported by default.

=head2 md5_base58( $data [, $alphabet ] )

This routine returns a MD5 digest in Base58. This routine is not exported
by default.

=head1 CHANGES

=item 1.00 April 30, 2013

Add Bitcoin alphabet support.

Add zero-padding for md5_base58. This is an incompatible change from version
0.09.

=head1 INCOMPATIBLE CHANGES

=item 1.00 April 30, 2013

md5_base58 is now zero-padded to provide a fixed-length Base58 string. Prior
versions were not padding with leading zero values.

=head1 SEE ALSO

L<Encode::Base58>, L<Encode::Base58::BigInt>, L<Math::GMPz>, L<Digest::MD5>

L<http://www.flickr.com/groups/api/discuss/72157616713786392/>

L<https://rubygems.org/gems/base58_gmp> (Base58 using GMP in Ruby)

L<http://marcus.bointon.com/archives/92-PHP-Base-62-encoding.html> (Base62 using GMP in PHP)

=head1 AUTHOR

John Wang <johncwang@gmail.com>, L<http://johnwang.com> 

=head1 COPYRIGHT AND LICENSE (The MIT License)

Copyright (c) 2011-2013 John Wang

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut
