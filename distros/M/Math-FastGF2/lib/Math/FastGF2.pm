package Math::FastGF2;

use 5.006000;
use strict;
use warnings;
no warnings qw(redefine);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

require Exporter;

@ISA = qw(Exporter);
%EXPORT_TAGS = ( 'all' => [ qw(gf2_mul gf2_inv gf2_div gf2_pow gf2_info) ],
		 'ops' => [ qw(gf2_mul gf2_inv gf2_div gf2_pow) ],
		 'info' => [ qw(gf2_info) ],
	       );
@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT = (  );
$VERSION = '0.07';

require XSLoader;
XSLoader::load('Math::FastGF2', $VERSION);


1;

__END__

=head1 NAME

Math::FastGF2 - Perl extension for fast Galois Field arithmetic

=head1 SYNOPSIS

  use Math::FastGF2 ":ops";
  use strict;
  my ($a,$b,$c,$d);

  $a = gf2_mul(8,0x53,0xca);	# GF(2^8) multiplication mod {11B}
  $b = gf2_inv(8,0x53);		# 1 / {53}               mod {11B}
  $c = gf2_div(8,0x53,0xca;     # {53} / {CA}            mod {11B}
  $d = gf2_pow(8,0x53,3);       # {53} * {53} * {53}     mod {11B}
  $a = $b ^ $c ^ $d             # add field elements     mod {11B}

=head1 DESCRIPTION

This module provides an interface for performing single modulo
arithmetic operations on Galois Field polynomials in GF(2^8), GF(2^16)
and GF(2^32). All values to be operated on are simple Perl numeric
scalars which are taken to represent polynomials with binary
co-efficients. For example, the value 0x53, whose binary
representation is 10010011, represents the polynomial:

        7       6       5       4       3       2       1       0
    (1)x  + (0)x  + (0)x  + (1)x  + (0)x  + (0)x  + (1)x  + (1)x

or, simply:

     7    4
    x  + x  + x  + 1

Operations such as multiplication, division and calculating powers
operate on the polynomials rather than the binary values. Also, all
such calculations are done modulo another polynomial, which is called
the irreducible polynomial for the field. For GF(2^8), the irreducible
polynomial used here has the hex value 0x11b (decimal 283). In binary
this is 100011011, so this represents the polynomial

     8    4    3
    x  + x  + x  + x + 1

The irreducible polynomials used for fields GF(2^16) and GF(2^32) have
16 and 32 as their highest power of x, respectively. It follows that
since all calculations in these fields are done modulo the appropriate
irreducible polynomial that all field elements in GF(2^8) will fit in
a single 8-bit byte, that GF(2^16) elements fit in a single 16-bit
word, and so on.

Addition of polynomials in GF(2^n) is accomplished by xoring the
binary representation of the two polynomials being operated on. Since
field elements are stored as simple Perl scalars, the regular ^ (xor)
operator suffices, and hence this module does not provide any gf2_add
or gf2_sub methods (there is no difference between addition and
subtraction in GF(2^n); the xor operator works for both).

For more detailed descriptions of arithmetic in Galois Fields, and
some applications, consult the references listed below.

=head2 EXPORT

By default, the module does not export any methods. By adding the
":ops" parameter to the "use" line, it exports the following routines:

=over

=item * gf2_mul( $field_size, $op1, $op2 )

=item * gf2_inv( $field_size, $op1 )

=item * gf2_div( $field_size, $op1, $op2 )

=item * gf2_pow( $field_size, $op1, $op2 )

=back

Currently, the module implements one other method which is not
exported by default. This is the C<gf2_info> method which returns
either the irreducible polynomial being used for a particular field
size, or (if passed an unsupported field size) the total number of
bytes being used by the module for arithmetic lookup tables. To use
it, either prefix the method name with the module name as in:

 $tablesize = Math::FastGF2::gf2_info(0);   # get table size
 $poly_16   = Math::FastGF2::gf2_info(16);  # get poly for GF(2^16)

or tell the module to export all symbols at the time you "use" it:

 use Math::FastGF2 ":all";

after which you can make calls to C<gf2_info> without having to
prefix the module name.

=head1 TECHNICAL INFORMATION

=head2 BACKGROUND

The initial motivation for writing this library was as a means of
implementing Michael O. Rabin's Information Dispersal Algorithm (see
below). This module started out as a generic (unoptimised),
arbitrary-precision implementation using Bit::Vector to perform all
the field operations. While the implementation worked, it was far too
slow to be practical, so I began to re-implement the critical sections
of the code as a separate C program. As I had no experience of
integrating C code with Perl code at the time, I dabbled with using
C<Inline::C> and some C<XS> code for a while. Despite some progress, I
decided that there were too many problems with developing the
interface code in parallel with the other code so I switched back to
polishing up the C implementation and left writing a Perl module
interface until later.

After implementing and testing several different optimised C routines,
I identified a few methods that performed somewhere between quite well
and very well on a variety of hardware platforms and that also had the
advantage of using very little memory. I had, at that point, worked
out most of the architectural problems of my project, so I decided it
was time to come back and attack the C<XS> part of the code, the first
result of which you see documented here.

=head2 ALGORITHMS

The module uses lookup tables for performing most operations. The
exceptions to this are for performing inverses and powers on fields of
size 16 and 32 bits. For inverses in these fields a version of the
extended Euclidean algorithm for calculating Greatest Common Divisor
is used. Another routine implements powers by rewriting the expression
to be calculated into one involving only multiplication by x and
squaring of sub-products. Also, multiplication is optimised in these
fields, at the expense of division, in which C<a/b> is implemented as
C<a * inv(b)>.

For calculations in 8-bit fields, all results are looked up from log
and antilog (exponent) tables. These tables are optimised to eliminate
the need to check for cases where an operand is zero or, in the case
of division, to do bounds checking on exp table lookups. The following
identities are used when using log/exp tables:

=over

=item * C<a * b = exp[ log [a] + log [b] ]>

=item * C<1 / a = exp[ 255 - log [a] ]>

=item * C<a / b = exp[ 255 + log [a] - log [b] ]>

=item * C<a ^ b = exp[ (log [a] * b) % 255 ]>

=back

As mentioned, multiplication in fields of size 8 and 16 are optimised
by using table lookups. The method used is to break up one of the
operands into 8-bit blocks and the other into 4-bit blocks and to look
up the result in a straight (non-modular) multiplication
table. Sub-products are loaded into a temporary variable, starting
with the high bytes/nibbles and shifted 8 bits at a time using a shift
lookup table. The shift lookup table takes care of the modulo part of
the overall operation. The following example illustrates the general
approach, multiplying the hex values A0BD and F0CD by breaking both
values into 8-bit blocks:

             A0 BD
      x      F0 CD
      ------------
           BD x CD    (subproducts can use a 256x256 lookup table)
      CD x A0 << 8    ( "<<" may be regular shift or modulo shift)
      F0 x BD << 8
 +   F0 x A0 << 16
   ---------------
 = ((F0 x A0) << 8) + (F0 x BD) + (CD x A0)) << 8 + (BD x CD)

Obviously, as mentioned, the method used in the module is slightly
more complicated since it breaks one value into 4-bit blocks. Also,
instead of using just one multiplication table and shifting 4 bits at
a time, it uses a "high nibble" multiplication table and a "low
nibble" table. The results are then combined before shifting a full 8
bits at a time. A final optimisation of the 32-bit multiply is to use
faster regular shifts in two cases, and "safe", modular shifts for the
remaining ones.

The major space saving advantage of the algorithm relies on being able
to re-use the same straight (non-modular) multiplication tables for
both 16 and 32-bit field sizes. Also, the shift tables are optimised
to be only 256 words apiece rather than the full field size, since
bits shifted off the end are used to look up a mask to be applied to
the sub-product to effect the modulo operation. Although the code for
generating the tables is not included, armed with this description it
should be easy enough to understand how the multiply code works.

=head2 PERFORMANCE

Compared with my original Bit::Vector implementation, these routines
achieve a speedup of between 15 and 20 times.  Compared with the
equivalent stand-alone C functions, however, they are at least 30
times slower. From testing, it's clear that the difference between the
plain C and Perl/XS implementations can be mostly attributed to a
combination of function calling overheads introduced in the XS layer
and overheads in the Perl benchmarking code, with a much smaller
amount attributable to the dispatch code which calls the appropriate C
function based on the field size. In fact, it appears that the amount
of time spent in the Perl code is more than that actually spent doing
computations.

A simple benchmarking program is included in this distribution. It is
named C<benchmark-Math-FastGF2.pl>. It tests all operations on all
field sizes.

As noted earlier, and can be seen from running the benchmark program,
multiplications are generally faster than divisions, which in turn are
faster than power operations.

No tests were done to examine performance in a multi-process or
multi-threaded program, but the code should be thread-safe. Further,
the relatively small size of the lookup tables means less memory that
needs to be copied when fork()ing or spawning a new thread. So it is
possible that some performance gains could be made by using this
module in a multi-process/multi-thread program.

=head2 FUTURE DIRECTIONS

While the module does provides all the primitives needed for
calculations in selected Galois Fields, it only provides the bare
minimum functionality. It is probably sufficient for writing code
which only needs to operate on small amounts of data (such as
encrypting or decrypting keys rather than full files), or for writing
proof-of-concept code. However, there are a few major deficiencies:

=over

=item * the choice of polynomial in each field is hard-wired;

=item * the lack of features; and

=item * the overheads involved in the XS function call.

=back

Currently I do not have any requirement for using different
polynomials, though if it appears that this feature is needed, or
there is any demand for it, I will implement it. Likewise, given that
the multiplication tables are already available, it would be fairly
simple to implement a straight multiplication routine, although I do
not foresee any need for it.

As for the other two problems, the natural solution is to provide
functions that do more work with each call. Specifically, starting
with version 0.02, there is support for matrix-related operations in
the L<Math::FastGF2::Matrix> module to allow efficient operations on
large blocks of data from a single call.

I intend future versions to be backward-compatible with this one.  In
terms of design, I've decided that using Perl scalars for storing
field elements is perfectly sufficient, so as a consequence of this
decision, I will not be implementing any objects to store them or
implementing any kind of operator overloading code. Obviously, this
also means that field sizes beyond the size of Perl's scalars will not
be possible.

=head2 APPLICATIONS

Besides Rabin's IDA, Galois Fields also have a number of other
applications involving codes or cryptography. The main ones are:

=over

=item * The Advanced Encryption Standard (Rijndael) algorithm for
encrpytion. This operates on 8-bit fields and uses the same
irreducible polynomial as implemented in this library.

=item * Error-correcting codes, particularly Reed-Solomon
encoding. (RS encoding and Rabin's IDA are actually versions of the
same algorithm)

=back

See the SEE ALSO section for links. Also, see the included scripts
C<shamir-split.pl> and C<shamir-combine.pl>, which implement Shamir's
threshold system for secret sharing.

=head2 DIVISION BY ZERO (and friends)

Although technically an error, these modules allow division by zero
and (with one exception, below) return 0 as the result rather than
failing or raising an exception. It is up to the user to ensure that
their program checks for division by zero wherever it might occur
I<before> calling C<gf2_div>.

The other zero-related issue is how the code handles 0^0 (zero to the
power of zero). I'm going with Knuth's advice in defining this to be
1, rather than 0.


=head2 POLYNOMIALS

The polynomials used in this implementation are (in hex) 0x11b,
0x1002b and 0x10000008d for, respectively, fields of size 8, 16 and 32
bits. These represent the irreducible polynomials:

     8    4    3
    x  + x  + x  + x + 1     GF(2^8)
 
     16    5    3
    x   + x  + x  + x  + 1   GF(2^16)
  
     32    7    3    2
    x   + x  + x  + x  + 1   GF(2^32)

These values can be retrieved by using the C<gf2_info> method. Note
that the polynomials returned by this method will have the high order
bit stripped off, so C<gf2_info(8)> returns 0x1b and not 0x11b.

=head1 KNOWN BUGS

The result of gf2_div(8,0,0) is 1, and not 0 as it is with other field
sizes. There is a trivial fix for this but I do not intend to fix it
for the following reasons:

=over

=item * technically, division by zero gives an undefined result, so
the problem is with the calling program (which shouldn't have asked to
divide by zero) rather than this module; and

=item * while the fix is trivial, the extra test needed would slow
down all calls to the division routine to handle a case that should
really happen only very rarely.

=back

=head1 SEE ALSO

I<http://en.wikipedia.org/wiki/Finite_field_arithmetic>

A (mostly) readable description of arithmetic operations in Galois
Fields.

I<http://point-at-infinity.org/ssss/>

B. Poettering's implementation of Shamir's secret sharing scheme. This
uses Galois Fields, and my own implementation of C<gf2_inv> is based
on this code.

I<"Efficient dispersal of information for security, load balancing,
and fault tolerance">, by Michael O. Rabin. JACM Volume 36, Issue 2
(1989).

The initial motivation for writing this module.

I<Introduction to the new AES Standard: Rijndael>, by Paul Donis,
I<http://islab.oregonstate.edu/koc/ece575/aes/intro.pdf>

Besides the AES info, this is also a very good introduction to
arithmetic in GF(2^m).

I<"Optimizing Galois Field Arithmetic for Diverse Processor
Architectures and Applications">, by Kevin M. Greenan, Ethan L. Miller
and Thomas J. E. Schwarz, S.J. (MASCOTS 2008)

Paper giving an overview of several optimisation techniques for
calculations in Galois Fields. I have used the optimised log/exp
technique described therein, and a modified version of the l-r tables
described (called "high-nibble" and "low-nibble" above) . Comments in
the paper that optimisations may need to be tailored to the particular
hardware architecture have been borne out in my testing.

I<http://www.cs.utk.edu/~plank/plank/papers/CS-07-593/>

James S. Plank's C/C++ implementation of optimised Galois Field
calculations. Although I haven't explored the code in great detail, I
have used it as a source of benchmarks. In fact, my benchmarking code
is modelled on this code. Plank's code is much more fully-featured
than mine, so if that is what you want, I would recommend using it
instead. If, on the other hand, you want something that's simple,
doesn't use much memory and is usable from Perl, I recommend this
module of course.

I<Studies on hardware-assisted implementation of arithmetic operations in
Galois Field GF(2^m)>, by Katsuki Kobayashi.

Despite being aimed at hardware, this paper also contains a wealth of
information on software algorithms including several field inversion
algorithms.

I<http://charles.karney.info/misc/secret.html> Original implementation
of Shamir's secret sharing algorithm, on which C<shamir-split.pl> and
C<shamir-combine.pl> are based. These new versions replace the integer
modulo a prime fields with Galois fields implemented with
Math::FastGF2.

The L<Math::FastGF2::Matrix> module has a range of Matrix functions to
operate more efficiently on large blocks of data.

This module is part of the GnetRAID project. For project development
page, see:

  https://sourceforge.net/projects/gnetraid/develop

=head1 AUTHOR

Declan Malone, E<lt>idablack@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2019 by Declan Malone

This package is free software; you can redistribute it and/or modify
it under the terms of the "GNU General Public License" ("GPL").

The C code at the core of this Perl module can additionally be
redistributed and/or modified under the terms of the "GNU Library
General Public License" ("LGPL"). For the purpose of that license, the
"library" is defined as the unmodified C code in the clib/ directory
of this distribution. You are permitted to change the typedefs and
function prototypes to match the word sizes on your machine, but any
further modification (such as removing the static modifier for
non-exported function or data structure names) are not permitted under
the LGPL, so the library will revert to being covered by the full
version of the GPL.

Please refer to the files "GNU_GPL.txt" and "GNU_LGPL.txt" in this
distribution for details.

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

=cut

