package Math::GMPn;

our $VERSION = '0.03';

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw( GMP_LIMB_BITS
                  GMP_LIMB_BYTES

                  mpn_neg
                  mpn_not
                  mpn_add
                  mpn_sub
                  mpn_mul
                  mpn_sqr
                  mpn_divrem
                  mpn_addmul
                  mpn_submul

                  mpn_popcount
                  mpn_hamdist

                  mpn_divexact_by3

                  mpn_mul_ext
                  mpn_sqr_ext

                  mpn_add_uint
                  mpn_sub_uint
                  mpn_mod_uint
                  mpn_mul_uint
                  mpn_addmul_uint
                  mpn_submul_uint

                  mpn_lshift
                  mpn_rshift

                  mpn_scan0
                  mpn_scan1

                  mpn_ior
                  mpn_xor
                  mpn_and
                  mpn_andn
                  mpn_iorn
                  mpn_nand
                  mpn_nior
                  mpn_xnor

                  mpn_ior_uint
                  mpn_xor_uint
                  mpn_and_uint
                  mpn_andn_uint
                  mpn_iorn_uint
                  mpn_nand_uint
                  mpn_nior_uint
                  mpn_xnor_uint

                  mpn_cmp
                  mpn_perfect_square_p

                  mpn_gcd_dest

                  mpn_get_str
                  mpn_get_str0
                  mpn_set_str
                  mpn_set_str0

                  mpn_set_uint
                  mpn_get_uint
                  mpn_setior_uint

                  mpn_set_bitlen
                  mpn_set_random

                  mpn_get_bitlen
                  mpn_shorten
               );

require XSLoader;
XSLoader::load('Math::GMPn', $VERSION);

1;
__END__

=head1 NAME

Math::GMPn - Fixed length integer arithmetic.

=head1 SYNOPSIS

  use Math::GMPn;

  # 128bits;
  mpn_set_str($a,   "123450000000000", 10, 128);
  mpn_set_str($b,   "100000000000001", 16, 128); # hexadecimal
  mpn_set_str($c, "0x1f1f1f1f1f1f1f1",  0, 128); # hexadecimal too!
  mpn_set_num($d, 23 * 234);

  mpn_mul($r1, $a, $b);
  mpn_add($r2, $r1, $c);
  mpn_div($r3, $r4, $r2, $d);

  say mpn_get_str($r4);

=head1 DESCRIPTION

This module provides a set of functions to perform arithmetic on fixed
length but arbitrarily large bit strings implemented on top of the GMP
library low level functions (see
L<http://gmplib.org/manual/Low_002dlevel-Functions.html>).

Numbers are represented as arrays of GMP mp_limb_t integers (usually,
the native unsigned int) packed into Perl scalars without any
additional wrapping.

The bit length of the strings passed to the module must be a multiple
of the mp_limb_t bit size (32 and 64 bits for 32bit and 64bit machines
respectively). Most operations do not check that condition and their
results are unspecified when arguments with non conforming sizes are
used.

Also, the strings passed must by internally aligned on a mp_limb_t
boundary. That usually means not using the four argument variant of
C<substr> on any scalar that would be passed to Math::GMPn. For
instance:

  # don't do that:
  $a = ...; $b = ...;
  substr($a, 0, 3, "");
  mpn_add($r, $a, $b); # croaks!

When strings of different length are used on the same operation, the
result lenght is equal to that of the largest input. For instance,
adding a 128bit string and a 256bit string will output a 256bit
string. Overflows are silently discarded.

=head2 THE AIM FOR SPEED

This module is designed to be as fast as possible, trading of
user-friendliness by speed when required.

In practice, that translates into the following principles:

=over 4

=item output arguments

In order to minimize Perl internal data structures and memory
allocations, most functions do not return the result but use their
first argument for output.

For instance:

   mpn_add($r, $s1, $s2)

Returns the result value in $r.

Assembler programmers may find this way of doing familiar.

=item no OO

Interface is not object oriented but fully functional.

OO is ruled out because method invocation on objects is very
expensive.

=item no overloading

Overloading would require wrapping the Math::GMPn strings, using OO
and returning the results as new values, and so, drastically reducing
the performance of the module.

=item rough edges

Some functions have extraneous requirements, as no overlapping
arguments, input arguments being overwritten after the call, requiring
some value to be odd, etc.

Those are usually artifacts of the underlaying GMP low level functions
that can not be hidden without a noticiable impact on the performance
of the module.

=item secure

Besides going against the aim for speed, the module performs all the
checks required to ensure that it will not make your program crash
when bad inputs are given.

(Otherwise, report it as a bug, please ;-)

=back

=head2 OVERLAPING ARGUMENTS

Some of the functions of this module accept overlapping of input and
output arguments while others doesn't.

For instance:

  mpn_add($r, $r, $s); # valid!
  mpn_mul($r, $r, $s); # invalid!

The rules are as follow:

=over 4

=item arguments can overlap in...

logical operations (ior, xor, and, etc.), addition and substration, shifts.

=item arguments can't overlap in...

multiplication, division, squaring, root squaring, gcd, etc.

=back

when in doubt, just try!

=head2 EXPORT

The following functions are exported by the module:

=over 4

=item GMP_LIMB_BYTES()

Return the size in bytes of the mp_limb_t type used internally by GMP to
represent numbers (usually 4 for 32bit machines and 8 for 64bit ones).

=item GMP_LIMB_BITS()

Return the size in bits of the mp_limb_t type (usually 32 or 64 for
32bit or 64bit machines respectively).

=item mpn_set_str($r, $str, $base = 0, $bitlen)

Converts an ASCII representation of the number in the given base
C<$base> to Math::GMPn internal representation.

Digits must be in the range '0'-'9' and 'a'-'z' or 'A'-'Z'.

C<$base> must be between 2 and 36 (inclusive). When base is omitted
(or is 0), if the string starts by C<0b>, C<0o> or C<0x>, base 2, 8 or
16 is used respectively; otherwise, it defaults to 10.

If C<$bitlen> is not given, the minimum plausible bit length able to
store the given number is used.

=item mpn_set_str0($r, $str, $base = 10, $bitlen)

Converts a byte representation of the number in the given base
C<$base> to the internal representation.

For instance, the following calls are equivalent:

  mpn_set_str0($a1, "\xf0\xaa\x01", 16, 128);
  mpn_set_str($a2, "f0aa01", 16, 128);
  mpn_set_str($a2, "0xf0aa01", 0, 128);

=item mpn_set_random($r, $bitlen)

Generate a random number of length <$bitlen>. The most significant
limb is always non-zero.

=item mpn_set_uint($r, $u1, $bitlen = GMP_NUMB_BITS)

Converts a Perl native number to Math::GMPn internal format.

=item mpn_setior_uint($r, $u1, $bitix = 0, $bitlen = 0)

Performs an inplace inclusive or of the native Perl unsigned integer
C<$ul> displaced C<$bitix> bits to the right into C<$r>. Conceptually
it is equivalent to:

   $r ||= $u1 << ($bitix * GMP_LIMB_BITS)

This function can be used to build a Math::GMPn number from its limbs:

  my @limbs = (0x00000123, 0x00000340, 0xffffaaaa, 0x0034000f)
  my $r = '';
  mpn_setior_uint($r, $limbs[$_], 32 * $_) for my (0..$#limbs)
  # $r = 0x0034000fffffaaaa0000034000000123

=item mpn_shorten($r, $s)

Sets C<$r> to the value C<$s> but removing high limbs with value 0.

=item mpn_set_bitlen($r, $bitlen, $sign_extend = 0)

Extends or truncate $r to the given bitlen C<$bitlen>.

If the optional $sign_extend argument has a true value, the leftmost
bit of $r is used to fill the new bits.

=item $bits = mpn_get_bitlen($s1)

Return the size in bits of the given argument


=item $str = mpn_get_str($s1, $base = 10)

Converts the Math::GMPn number in $s1 to its ASCII representation in
base C<$base> (10 by default).

=item $bytes = mpn_get_str0($s1, $base = 10)

Converts the Math::GMPn number in $s1 to its byte representation in
base C<$base> (10 by default).

=item $u = mpn_get_uint($s1, $bitix = 0, $mask = ~0)

returns the value of the Math::GMPn number shifted to the right
C<$bitix> bits and masked by C<$mask>. Conceptually it is equivalent
to:

  $u = ($s1 >> $bitix ) & $mask;

=item mpn_not($r, $s1)

  $r = ~$s1

=item mpn_neg($r, $s1)

  $r = -$s1

=item mpn_ior($r, $s1, $s2)

  $r = $s1 | $s2

=item mpn_xor($r, $s1, $s2)

  $r = $s1 ^ $s2

=item mpn_and($r, $s1, $s2)

  $r = $s1 & $s2

=item mpn_andn($r, $s1, $s2)

  $r = $s1 & ~$s2

=item mpn_iorn($r, $s1, $s2)

  $r = $s1 | ~$s2

=item mpn_nand($r, $s1, $s2)

  $r = ~($s1 & $s2)

=item mpn_nior($r, $s1, $s2)

  $r = ~($s1 | $s2)

=item mpn_xnor($r, $s1, $s2)

  $r = ~($s1 ^ $s2)

=item mpn_add($r, $s1, $s2)

  $r = $s1 + $s2

=item mpn_sub($r, $s1, $s2)

  $r = $s1 - $s2

=item mpn_mul($r, $s1, $s2)

  $r = $s1 * $s2

=item mpn_mul_ext($r, $s1, $s2)

This function performs the multiplication of C<$s1> and C<$s2> but
does not truncate the result to the lenght of the largest argument so
that C<bitlen($r) = bitlen($s1) + bitlen($s2)>.

=item mpn_sqr($r, $s1)

  $r = $s1 * $s1

=item mpn_sqr_ext($r, $s1)

This function squares C<$s1> and returns the result untruncated.

=item mpn_divrem($q, $r, $s1, $s2)

Calculates the quoting and the remainder of dividing C<$s1> by
C<$s2>. Mathematically:

  $s1 = $q * $s2 + $r

=item mpn_divexact_by3($r, $s1)

  $r = $s1 / 3

$s1 must be a multiple of C<3>.

=item mpn_sqrtrem($r1, $r2, $s1)

Computes the square root and the remainder of C<$s1>. Mathematically:

  $s1 = $r1 * $r1 + $r2

=item mpn_addmul($r, $s1, $s2)

  $r += $s1 * $s2

=item mpn_submul($r, $s1, $s2)

  $r -= $s1 * $s2

=item mpn_lshift($r, $s1, $u1)

  $r = $s1 << $ul

=item mpn_rshift($r, $s1, $u1)

  $r = $s1 >> ul

=item $cnt = mpn_popcount($s1)

Counts the number of bits set on C<$s1>

=item $cnt = mpn_hamdist($s1, $s2)

Computes the hammin distance between C<$s1> and C<$s2>.

=item $pos = mpn_scan0($s1, $start = 0)

Returns the position of the first bit with value 0 starting at C<$start>.

=item $pos = mpn_scan1($s1, $start = 0)

Returns the position of the first bit with value 1 starting at C<$start>.

=item $cmp = mpn_cmp($s1, $s2)

  $cmp = $s1 <=> $s2

=item $bool = mpn_perfect_square_p($s1)

Returns true if C<$s1> is a perfect square

=item $mpn_gcd_dest($r, $sd1, $sd2)

Computes the greatest common divisor of C<$sd1> and C<$sd2>.

The values of C<$sd1> and C<$sd2> are destroyed on the operation.

=item mpn_ior_uint($r, $s1, $u1)

=item mpn_xor_uint($r, $s1, $u1)

=item mpn_and_uint($r, $s1, $u1)

=item mpn_andn_uint($r, $s1, $u1)

=item mpn_iorn_uint($r, $s1, $u1)

=item mpn_nand_uint($r, $s1, $u1)

=item mpn_nior_uint($r, $s1, $u1)

=item mpn_xnor_uint($r, $s1, $u1)

=item mpn_add_uint($r, $s1, $u1)

=item mpn_sub_uint($r, $s1, $u1)

=item mpn_mod_uint($r, $s1, $u1)

=item mpn_mul_uint($r, $s1, $u1)

=item mpn_addmul_uint($r, $s1, $u1)

=item mpn_submul_uint($r, $s1, $u1)

Those operations perform the same operations as the no C<_uint>
counterparts but take as their third argument a native Perl unsigned
int.

=back

=head1 BUGS AND SUPPORT

This is a very early release of this module, so it may contain lots of bugs.

If you find any use the CPAN RT system at L<http://rt.cpan.org> to
report them or just send my an email with the details.

For questions related to the usage of this module, post them at
PerlMonks: L<http://perlmonks.org>.

=head1 SEE ALSO

L<Math::GMPz>, L<Math::Int128>, L<Math::GMP>, L<Math::Pari>, L<Math::BigInt>.

L<http://gmplib.org/manual/Low_002dlevel-Functions.html#Low_002dlevel-Functions>.

L<http://perlmonks.org/?node_id=886488>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Salvador FaE<ntilde>dino E<lt>sfandino@yahoo.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
