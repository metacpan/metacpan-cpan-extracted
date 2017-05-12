package Encode::Base32::GMP;
use strict;
use warnings;
use 5.008_009;
our $VERSION   = '0.02';

use base         qw(Exporter);
our @EXPORT    = qw(encode_base32 decode_base32);
our @EXPORT_OK = qw(base32_from_to md5_base32);

use Carp;
use Digest::MD5  qw(md5_hex);
use Math::GMPz   qw(Rmpz_get_str);
use Scalar::Util qw(blessed);

sub encode_base32 {
  my ($int, $alphabet, $len) = @_;

  my $base32 = blessed($int) && $int->isa('Math::GMPz') ?
    Rmpz_get_str($int, 32) :
    Rmpz_get_str(Math::GMPz->new($int), 32);

  if ($len && $len =~ m|\A[0-9]+\Z|) {
    $base32 = sprintf("%0${len}s",$base32);
  }

  $alphabet && lc $alphabet eq 'gmp' ?
    uc($base32) :
    base32_from_to($base32,'gmp',$alphabet||'crockford');
}

sub decode_base32 { 
  my ($base32, $alphabet) = @_;

  unless ($alphabet && lc $alphabet eq 'gmp') {
    $base32 = base32_from_to($base32,$alphabet||'crockford','gmp');
  }

  Math::GMPz->new($base32, 32);
}

sub base32_from_to {
  my ($base32, $from_alphabet, $to_alphabet) = @_;

  my $alphabets =  {
    crockford   => '0123456789ABCDEFGHJKMNPQRSTVWXYZ',
    rfc4648     => 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567',
    zbase32     => 'YBNDRFG8EJKMCPQXOT1UWISZA345H769',
    base32hex   => '0123456789ABCDEFGHIJKLMNOPQRSTUV',
    gmp         => '0123456789ABCDEFGHIJKLMNOPQRSTUV',
  };

  $from_alphabet = lc($from_alphabet||'crockford');
  $to_alphabet   = lc($to_alphabet  ||'crockford');
  $from_alphabet = 'gmp' if $from_alphabet eq 'base32hex';
  $to_alphabet   = 'gmp' if $to_alphabet   eq 'base32hex';
  $base32        = uc($base32);

  if ($from_alphabet eq 'crockford') {
    $base32 =~ y|O|0|;
    $base32 =~ y|IL|11|;
  } elsif ($from_alphabet eq 'rfc4648') {
    $base32 =~ y|0|O|;
    $base32 =~ y|1|L|;
  }

  my $from_digits = $alphabets->{$from_alphabet}
    or croak("Encode::Base32::GMP::from_to called with invalid from_alphabet [$from_alphabet]");
  my $to_digits   = $alphabets->{$to_alphabet}
    or croak("Encode::Base32::GMP::from_to called with invalid to_alphabet [$to_alphabet]");

  if ($from_alphabet ne $to_alphabet) {
    if ($from_alphabet eq 'gmp') {
      if ($to_alphabet eq 'crockford') {
        $base32 =~ y|0123456789ABCDEFGHIJKLMNOPQRSTUV|0123456789ABCDEFGHJKMNPQRSTVWXYZ|;
      } elsif ($to_alphabet eq 'rfc4648' ) {
        $base32 =~ y|0123456789ABCDEFGHIJKLMNOPQRSTUV|ABCDEFGHIJKLMNOPQRSTUVWXYZ234567|;
      } elsif ($to_alphabet eq 'zbase32') {
        $base32 =~ y|0123456789ABCDEFGHIJKLMNOPQRSTUV|YBNDRFG8EJKMCPQXOT1UWISZA345H769|;
      }
    } elsif ($from_alphabet eq 'crockford') {
      if ($to_alphabet eq 'gmp') {
        $base32 =~ y|0123456789ABCDEFGHJKMNPQRSTVWXYZ|0123456789ABCDEFGHIJKLMNOPQRSTUV|;
      } elsif ($to_alphabet eq 'rfc4648' ) {
        $base32 =~ y|0123456789ABCDEFGHJKMNPQRSTVWXYZ|ABCDEFGHIJKLMNOPQRSTUVWXYZ234567|;
      } elsif ($to_alphabet eq 'zbase32') {
        $base32 =~ y|0123456789ABCDEFGHJKMNPQRSTVWXYZ|YBNDRFG8EJKMCPQXOT1UWISZA345H769|;
      }
    } elsif ($from_alphabet eq 'rfc4648') {
      if ($to_alphabet eq 'gmp') {
        $base32 =~ y|ABCDEFGHIJKLMNOPQRSTUVWXYZ234567|0123456789ABCDEFGHIJKLMNOPQRSTUV|;
      } elsif ($to_alphabet eq 'crockford' ) {
        $base32 =~ y|ABCDEFGHIJKLMNOPQRSTUVWXYZ234567|0123456789ABCDEFGHJKMNPQRSTVWXYZ|;
      } elsif ($to_alphabet eq 'zbase32') {
        $base32 =~ y|ABCDEFGHIJKLMNOPQRSTUVWXYZ234567|YBNDRFG8EJKMCPQXOT1UWISZA345H769|;
      }
    } else {
      if ($to_alphabet eq 'gmp') {
        $base32 =~ y|YBNDRFG8EJKMCPQXOT1UWISZA345H769|0123456789ABCDEFGHIJKLMNOPQRSTUV|;
      } elsif ($to_alphabet eq 'crockford' ) {
        $base32 =~ y|YBNDRFG8EJKMCPQXOT1UWISZA345H769|0123456789ABCDEFGHJKMNPQRSTVWXYZ|;
      } elsif ($to_alphabet eq 'rfc4648') {
        $base32 =~ y|YBNDRFG8EJKMCPQXOT1UWISZA345H769|ABCDEFGHIJKLMNOPQRSTUVWXYZ234567|;
      }
    }
  }

  return $base32;
}

sub md5_base32 {
  encode_base32('0x'.md5_hex(shift), shift, 26);
}

1;

# ABSTRACT: High speed Base32 encoding using GMP with BigInt and MD5 support

=head1 NAME

Encode::Base32::GMP - High speed Base32 encoding using GMP with BigInt and MD5 support

=head1 SYNOPSIS

  use Encode::Base32::GMP;

  # Encode Int as Base32
  encode_base32(12345);                        # => C1S string
  encode_base32('0x3039');                     # => C1S string
  encode_base32(Math::GMPz->new('0x3039'));    # => C1S string

  # Encode Int as Base32 using GMP alphabet
  encode_base32(12345,'rfc4648');              # => MBZ string
  encode_base32(12345,'zbase32');              # => CB3 string
  encode_base32(12345,'base32hex');            # => C1P string
  encode_base32(12345,'gmp');                  # => C1P string

  # Decode Base32 as Math::GMPz Int
  decode_base32('C1S');                        # => 12345 Math::GMPz object
  int decode_base32('C1S');                    # => 12345 integer

  # Decode Base32 as Math::GMPz Int using normaliztion (built-in)
  decode_base32('c1s');                        # => 12345 Math::GMPz object
  decode_base32('cis');                        # => 12345 Math::GMPz object

  # Decode Base32 as Math::GMPz Int using GMP alphabet
  decode_base32('MBZ','rfc4648');              # => 12345 Math::GMPz object
  decode_base32('CB3','zbase32');              # => 12345 Math::GMPz object

  # MD5 Base32 Digest
  md5_base32('foo@bar.com');                   # => 7KNPJ0BKM91DQR41099QNH5P58

  # Convert between alphabets, e.g. Crockford and RFC-4648
  base32_from_to('0123456789ABCDEFGHJKMNPQRSTVWXYZ','crockford','rfc4648');
    # => ABCDEFGHIJKLMNOPQRSTUVWXYZ234567
  base32_from_to('ABCDEFGHIJKLMNOPQRSTUVWXYZ234567','rfc4648','zbase32');
    # => YBNDRFG8EJKMCPQXOT1UWISZA345H769

=head1 DESCRIPTION

Encode::Base32::GMP is a numerical Base32 encoder/decoder implementation using
the GNU Multiple Precision Arithmetic Library (GMP) with transcoding between
Crockford, RFC 4648, z-base-32, and Base32hex / GMP implementations. The
Crockford alphabet is the default and used when no alphabet is provided.
Crockford was selected as the default because it extends hexadecimal more
naturally than other alphabets and it is easier to distinguish visually.

  crockford: [0123456789ABCDEFGHJKMNPQRSTVWXYZ]
  rfc4648:   [ABCDEFGHIJKLMNOPQRSTUVWXYZ234567]
  zbase32:   [YBNDRFG8EJKMCPQXOT1UWISZA345H769]
  base32hex: [0123456789ABCDEFGHIJKLMNOPQRSTUV]
  gmp:       [0123456789ABCDEFGHIJKLMNOPQRSTUV]

The encode_base32, decode_base32 and md5_base32 methods support an alphabet
parameter which can be set to the supported alphabets to indicate the value
to be encoded or decoded:

  [qw/crockford rfc4648 base32hex zbase32 gmp/]

This module functions similarly to L<Encode::Base58::GMP> with Base32 being
ideal for case-insensitive encoding and Base58 being ideal for case-sensitive
encoding. 

=head1 FUNCTIONS

=head2 encode_base32 ( $number [, $alphabet ] )

This routine encodes a $number in Base32. $number can be a Math::GMPz object
or a binary, octal, decimal or hexidecimal number. Binary, octal and hexidecimal
string literals must be prefixed with 0[Bb]/0/0[Xx] respectively. The resulting
Base32 encoded number is provided in upper case per Crockford and RFC-4648
definitions. The Crockford alphabet is used unless $alphabet is set.

=head2 decode_base32( $base32 [, $alphabet ] )

This routine decodes a Base32 value and returns a Math::GMPz object. Use int
on the return value to convert the Math::GMPz object to an integer. The input
can be upper or lower case. Crockford and RFC-4648 inputs are normalized
exchanging the set [01ilo] as necessary. The Crockford alphabet is used unless
$alphabet is set.

=head2 base32_from_to( $base32, $from_alphabet, $to_alphabet )

This routine encodes a Base32 string from one encoding to another encoding.
The input can be upper or lower case. Crockford and RFC-4648 inputs are
normalized exchanging the set [01ilo] as necessary. The resulting Base32
encoded number is provided in upper case per Crockford and RFC-4648
definitions. This routing is not exported by default.

=head2 md5_base32( $data [, $alphabet ] )

This routine returns a MD5 digest in Base32. This routine is not exported
by default.

=head1 NOTE

This module is designed to encode and decode numbers. As such, it is backward
compatible with L<Encode::Base32::Crockford> while also adding BigInt support.

While this module can be used to transcode other Base32 encodings, this
module is not designed to encode and decode binary strings, for which
L<Convert::Base32>, L<Convert::Base32::Crockford>, and L<MIME::Base32> can
be used. These modules also result in different and longer encodings for
numbers which is not desirable when encoding digests and other uids.

=head1 SEE ALSO

Crockford Base32 Encoding Definition: L<http://www.crockford.com/wrmg/base32.html>

RFC 4648 Definition: L<http://tools.ietf.org/html/rfc4648>

z-base-32 Definition: L<http://philzimmermann.com/docs/human-oriented-base-32-encoding.txt>

GMP: L<http://gmplib.org/>

L<Encode::Base32::Crockford>, L<Encode::Base58::GMP>, L<Math::GMPz>, L<Digest::MD5>

=head1 AUTHOR

John Wang <johncwang@gmail.com>, L<http://johnwang.com> 

=head1 COPYRIGHT

Copyright 2013 by John Wang <johncwang@gmail.com>.

This software is released under the MIT license cited below.

=head2 COPYRIGHT AND LICENSE (The MIT License)

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