# Copyright (c) 2012-2017 Martin Becker, Blaubeuren.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

package Math::Logic::Ternary::TFP_81;

use strict;
use warnings;
use Carp qw(croak);
use Math::BigInt try => 'GMP,Pari';
use Math::BigFloat;
use Math::Logic::Ternary::Trit;
use Math::Logic::Ternary::Word;

require Exporter;

our $VERSION     = '0.004';
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw(float81);

sub new {
    my ($class, $mantissa, $exponent) = @_;
    croak "$class: class not yet fully implemented";
    return bless [$mantissa, $exponent], $class;
}

sub float81 { __PACKAGE__->new(@_) }

1;
__END__

=head1 NAME

Math::Logic::Ternary::TFP_81 - 81-trit ternary floating point arithmetic

=head1 VERSION

This documentation refers to version 0.004 of Math::Logic::Ternary::TFP_81.

=head1 SYNOPSIS

  use Math::Logic::Ternary::TFP_81 qw(float81);

  $fp = float81($mantissa_72t, $exponent_9t);
  $fp = Math::Logic::Ternary::TFP_81->new($mantissa_72t, $exponent_9t);
  $fp = Math::Logic::Ternary::TFP_81->from_int($word_81t);
  $fp = Math::Logic::Ternary::TFP_81->from_ratio($numerator, $denominator);
  $fp = Math::Logic::Ternary::TFP_81->from_word($word_81t);

  $fp = Math::Logic::Ternary::TFP_81->plus_infinity;
  $fp = Math::Logic::Ternary::TFP_81->minus_infinity;
  $fp = Math::Logic::Ternary::TFP_81->plus_epsilon;
  $fp = Math::Logic::Ternary::TFP_81->minus_epsilon;
  $fp = Math::Logic::Ternary::TFP_81->not_a_number;
  $fp = Math::Logic::Ternary::TFP_81->undefined;

  $mantissa_72t = $fp->mantissa;
  $exponent_9t  = $fp->exponent;
  $trit         = $fp->sign;
  $word_81t     = $fp->as_word;
  $word_81t     = $fp->as_int;
  $bool         = $fp->is_number;
  $bool         = $fp->is_symbol;
  $bool         = $fp->is_well_formed;
  $bool         = $fp->is_zero;
  $bool         = $fp->is_p_inf;
  $bool         = $fp->is_m_inf;
  $bool         = $fp->is_nan;
  $bool         = $fp->is_p_eps;
  $bool         = $fp->is_m_eps;
  $bool         = $fp->is_undef;

  $fp2 = $fp1->Fneg;
  $fp3 = $fp1->Fadd($fp2);
  $fp3 = $fp1->Fsub($fp2);
  $fp2 = $fp1->Finv;
  $fp3 = $fp1->Fmul($fp2);
  $fp3 = $fp1->Fdiv($fp2);
  $fp3 = $fp1->Fpow($fp2);
  $fp2 = $fp1->Flog;
  $fp2 = $fp1->Fexp;
  $fp2 = $fp1->Ftrunc;
  $fp2 = $fp1->Ffrac;
  $fp2 = $fp1->Ffloor;
  $fp2 = $fp1->Fceil;
  $fp2 = $fp1->Fabs;
  $fp2 = $fp1->Fnormalize;

  $trit = $fp1->Fcmp($fp2);
  $trit = $fp1->Fasc($fp2);

=head1 DESCRIPTION

This module defines an 81-trit floating point format and emulates some
basic operations on numbers of this format.

=head2 Number Format

TFP_81 numbers are coded as 81-trit words with a mantissa of 72 trits
followed by an exponent of 9 trits.  The mantissa starts with a I<+1>
or I<-1> trit for all non-zero numbers.  It is a balanced ternary signed
integer number spanning the most significant 72 trits of the 81-trit word.
The exponent is a balanced ternary signed integer number, spanning the
least significant 9 trits of the 81-trit word.

Zero is represented as 81 zero trits (mantissa 0, exponent 0).  One is
represented as a I<+1> trit followed by 80 zero trits (3 ** 71, 0).

Plus infinity is represented as 72 zero trits followed by nine I<+1> trits
(0, 9841).  Minus infinity is represented as 72 zero trits followed by
eight I<+1> trits and a I<-1> trit (0, 9839).  Not-a-number is represented
as 72 zero trits followed by eight I<+1> trits and a zero trit (0, 9840).
Plus epsilon, a symbol that can be used to denote a positive number very
close to zero, is represented as 72 zero trits followed by eight I<-1>
trits and a I<+1> trit (0, -9839).  Minus epsilon is represented as
72 zero trits followed by nine I<-1> trits (0, -9841).  CtN (close to
naught), a symbol that can be used to denote a number with unknown sign
very close to zero or actually zero, is represented as 72 zero trits
followed by eight I<-1> trits and a zero trit (0, -9840).

Multiplying a non-zero number by three increases the exponent by one
while leaving the mantissa unchanged, unless the exponent was already
at its maximum (9841).  Results greater than the largest representable
number are replaced by plus infinity.  Results smaller than the smallest
representable number are replaced by minus infinity.  Results closer
to zero than any representable number are replaced by plus or minus
epsilon, respectively.  Operations with plus or minus epsilon that yield
another very small entity of unknown sign are replaced by the CtN symbol.
Results of undefined operations, such as division by zero, are replaced
by not-a-number.

The largest representable number is
C<(3 ** 72 - 1) / (2 * 3 ** 71) * 3 ** 9841>,
which is about C<3.36 * 10 ** 4695> or about C<1.15 * 2 ** 15598>.
The smallest well-formed representable positive number is
C<(3 ** 71 + 1) / (2 * 3 ** 71) * 3 ** -9841>,
which is about C<2.23 * 10 ** -4696> or about C<1.30 * 2 ** -15599>.

Numbers with a non-zero mantissa starting with a zero trit are legal to
use but not well-formed; such numbers will not occur as operation results.

Numbers with a mantissa of zero and an exponent other than those reserved
for the six symbolic values are treated as zero and will not occur as
operation results either.

=head2 Operation Tables

  +------+------+------+--------+--------+--------+---------+
  |   a  |  -a  |  1/a | sgn(a) | abs(a) |trunc(a)| frac(a) |
  +------+------+------+--------+--------+--------+---------+
  |   0  |   0  |  NaN |    0   |    0   |    0   |     0   |
  |   1  |  -1  |   1  |    1   |    1   |    1   |     0   |
  |  -1  |   1  |  -1  |   -1   |    1   |   -1   |     0   |
  | +Inf | -Inf | +Eps |    1   |  +Inf  |  +Inf  |    NaN  |
  | -Inf | +Inf | -Eps |   -1   |  +Inf  |  -Inf  |    NaN  |
  | +Eps | -Eps | +Inf |    1   |  +Eps  |    0   |   +Eps  |
  | -Eps | +Eps | -Inf |   -1   |  +Eps  |    0   |   -Eps  |
  |  CtN |  CtN |  NaN |   NaN  |  +Eps  |    0   |    CtN  |
  |  NaN |  NaN |  NaN |   NaN  |   NaN  |   NaN  |    NaN  |
  +------+------+------+--------+--------+--------+---------+

  +------+--------+---------+---------+--------+--------+
  |   a  |floor(a)| ceil(a) | sqrt(a) | log(a) | exp(a) |
  +------+--------+---------+---------+--------+--------+
  |   0  |    0   |     0   |    0    |  -Inf  |    1   |
  |   1  |    1   |     1   |    1    |    0   |    e   |
  |  -1  |   -1   |    -1   |   NaN   |   NaN  |   1/e  |
  | +Inf |  +Inf  |   +Inf  |  +Inf   |  +Inf  |  +Inf  |
  | -Inf |  -Inf  |   -Inf  |   NaN   |   NaN  |  +Eps  |
  | +Eps |    0   |     1   |  +Eps   |  -Inf  |    1   |
  | -Eps |   -1   |     0   |   NaN   |   NaN  |    1   |
  |  CtN |   NaN  |    NaN  |   NaN   |   NaN  |    1   |
  |  NaN |   NaN  |    NaN  |   NaN   |   NaN  |   NaN  |
  +------+--------+---------+---------+--------+--------+

  +------+------+------+------+------+------+------+
  |   a  |   b  |  a+b |  a-b |  a*b |  a/b | a**b |
  +------+------+------+------+------+------+------+
  |   0  | +Inf | +Inf | -Inf |  NaN |   0  |  NaN |
  |   0  | -Inf | -Inf | +Inf |  NaN |   0  |  NaN |
  |   0  | +Eps | +Eps | -Eps |   0  |  NaN |  NaN |
  |   0  | -Eps | -Eps | +Eps |   0  |  NaN |  NaN |
  |   0  |  NaN |  NaN |  NaN |  NaN |  NaN |  NaN |
  |   1  | +Inf | +Inf | -Inf | +Inf | +Eps |  NaN |
  |   1  | -Inf | -Inf | +Inf | -Inf | -Eps |  NaN |
  |   1  | +Eps |   1  |   1  | +Eps | +Inf |   1  |
  |   1  | -Eps |   1  |   1  | -Eps | -Inf |   1  |
  |   1  |  NaN |  NaN |  NaN |  NaN |  NaN |  NaN |
  |  -1  | +Inf | +Inf | -Inf | -Inf | -Eps |  NaN |
  |  -1  | -Inf | -Inf | +Inf | +Inf | +Eps |  NaN |
  |  -1  | +Eps |  -1  |  -1  | -Eps | -Inf |  NaN |
  |  -1  | -Eps |  -1  |  -1  | +Eps | +Inf |  NaN |
  |  -1  |  NaN |  NaN |  NaN |  NaN |  NaN |  NaN |
  | +Inf |   0  | +Inf | +Inf |  NaN |  NaN |  NaN |
  | +Inf |   1  | +Inf | +Inf | +Inf | +Inf | +Inf |
  | +Inf |  -1  | +Inf | +Inf | -Inf | -Inf | +Eps |
  | +Inf | +Inf | +Inf |  NaN | +Inf |  NaN | +Inf |
  | +Inf | -Inf |  NaN | +Inf | -Inf |  NaN | +Eps |
  | +Inf | +Eps | +Inf | +Inf |  NaN | +Inf |  NaN |
  | +Inf | -Eps | +Inf | +Inf |  NaN | -Inf |  NaN |
  | +Inf |  NaN |  NaN |  NaN |  NaN |  NaN |  NaN |
  | -Inf |   0  | -Inf | -Inf |  NaN |  NaN |  NaN |
  | -Inf |   1  | -Inf | -Inf | -Inf | -Inf |  NaN |
  | -Inf |  -1  | -Inf | -Inf | +Inf | +Inf |  NaN |
  | -Inf | +Inf |  NaN | -Inf | -Inf |  NaN |  NaN |
  | -Inf | -Inf | -Inf |  NaN | +Inf |  NaN |  NaN |
  | -Inf | +Eps | -Inf | -Inf |  NaN | -Inf |  NaN |
  | -Inf | -Eps | -Inf | -Inf |  NaN | +Inf |  NaN |
  | -Inf |  NaN |  NaN |  NaN |  NaN |  NaN |  NaN |
  +------+------+------+------+------+------+------+

  +------+------+------+------+------+------+------+
  |   a  |   b  |  a+b |  a-b |  a*b |  a/b | a**b |
  +------+------+------+------+------+------+------+
  | +Eps |   0  | +Eps | +Eps |   0  |  NaN |   1  |
  | +Eps |   1  |   1  |  -1  | +Eps | +Eps | +Eps |
  | +Eps |  -1  |  -1  |   1  | -Eps | -Eps | +Inf |
  | +Eps | +Inf | +Inf | -Inf |  NaN | +Eps |  NaN |
  | +Eps | -Inf | -Inf | +Inf |  NaN | -Eps | +Inf |
  | +Eps | +Eps | +Eps |   0  | +Eps |  NaN |  NaN |
  | +Eps | -Eps |   0  | +Eps | -Eps |  NaN |  NaN |
  | +Eps |  NaN |  NaN |  NaN |  NaN |  NaN |  NaN |
  | -Eps |   0  | -Eps | -Eps |   0  |  NaN |  NaN |
  | -Eps |   1  |   1  |  -1  | -Eps | -Eps | -Eps |
  | -Eps |  -1  |  -1  |   1  | +Eps | +Eps | -Inf |
  | -Eps | +Inf | +Inf | -Inf |  NaN | -Eps |  NaN |
  | -Eps | -Inf | -Inf | +Inf |  NaN | +Eps |  NaN |
  | -Eps | +Eps |  CtN | -Eps | -Eps |  NaN |  NaN |
  | -Eps | -Eps | -Eps |  CtN | +Eps |  NaN |  NaN |
  | -Eps |  NaN |  NaN |  NaN |  NaN |  NaN |  NaN |
  |  NaN |   0  |  NaN |  NaN |  NaN |  NaN |  NaN |
  |  NaN |   1  |  NaN |  NaN |  NaN |  NaN |  NaN |
  |  NaN |  -1  |  NaN |  NaN |  NaN |  NaN |  NaN |
  |  NaN | +Inf |  NaN |  NaN |  NaN |  NaN |  NaN |
  |  NaN | -Inf |  NaN |  NaN |  NaN |  NaN |  NaN |
  |  NaN | +Eps |  NaN |  NaN |  NaN |  NaN |  NaN |
  |  NaN | -Eps |  NaN |  NaN |  NaN |  NaN |  NaN |
  |  NaN |  NaN |  NaN |  NaN |  NaN |  NaN |  NaN |
  +------+------+------+------+------+------+------+

=head2 Exports

By default, nothing is exported into the caller's namespace.
The constructor I<float81> can be imported explicitly, though.

=head1 DEPENDENCIES

This module depends on Math::BigFloat and Math::Logic::Ternary::Word.
Installing Math::BigInt::GMP or Math::BigInt::Pari should make it faster.

=head1 BUGS AND LIMITATIONS

As of version 0.004, this module is not fully implemented.
The documentation is intended as a preview of its eventual content.

However, the definition of the TFP_81 number format, as given here,
should be taken as final, and can be used as a reference.

=head1 SEE ALSO

=over 4

=item *

L<Math::Logic::Ternary>

=item *

L<Math::Logic::Ternary::Word>

=item *

L<Math::BigFloat>

=back

=head1 AUTHOR

Martin Becker E<lt>becker-cpan-mpE<64>cozap.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2017 by Martin Becker.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
