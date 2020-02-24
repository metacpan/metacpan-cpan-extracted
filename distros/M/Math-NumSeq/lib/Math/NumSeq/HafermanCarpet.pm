# Copyright 2013, 2014, 2016, 2017, 2019 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.


package Math::NumSeq::HafermanCarpet;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 74;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::Repdigits;
*_digit_split_lowtohigh = \&Math::NumSeq::Repdigits::_digit_split_lowtohigh;

# uncomment this to run the ### lines
# use Smart::Comments;


use constant description => Math::NumSeq::__('Flattened Haferman carpet.');
use constant default_i_start => 0;
use constant values_min => 0;
use constant values_max => 1;
use constant characteristic_integer => 1;
use constant characteristic_smaller => 1;

# 000 all zeros
# 001 infs are box fractal
# 010 evens  is plain starting from 1
# 011      odd=1 even=0 inf=0  is inverse of plain
# 100 odds odd=0 even=1 inf=1  is plain starting from 0
# 101 inverse of evens
# 110 inverse of infs box fractal
# 111 all ones

# start0     carpet 0
# start0 inv carpet 0 inverse
# start1     carpet 1
# start1 inv carpet 1 inverse
# box
# box inverse

use constant parameter_info_array =>
  [
   # { name    => 'haferman_type',
   #   display => Math::NumSeq::__('Type'),
   #   type    => 'enum',
   #   default => 'array',
   #   choices => ['array','alt','side'],
   # },
   { name    => 'initial_value',
     display => Math::NumSeq::__('Initial'),
     type    => 'integer',
     default => 0,
     minimum => 0,
     maximum => 1,
     width   => 1,
   },
   { name    => 'inverse',
     display => Math::NumSeq::__('Inverse'),
     type    => 'boolean',
     default => 0,
   },
   # { name        => 'radix',
   #   share_key   => 'radix_3',
   #   type        => 'integer',
   #   display     => Math::NumSeq::__('Radix'),
   #   default     => 3,
   #   minimum     => 2,
   #   width       => 3,
   #   description => Math::NumSeq::__('Radix, ie. base, for the values calculation.  Default is base 3.'),
   # },
  ];

#------------------------------------------------------------------------------

# 000 all zeros
# 001 infs are box fractal
# 010 evens inverse of starting from 1
# 011      odd=1 even=0 inf=0  is inverse of plain
# 100 odds odd=0 even=1 inf=1  is plain starting from 0
# 101                          is plain starting from 1
# 110 inverse of infs box fractal
# 111 all ones
#
# my %odd_by_type  = (start0 => 1,
#                     start1 => 1,
#                     box    => 0);
# my %inf_by_type  = (start0 => 0,
#                     start1 => 1,
#                     box    => 1);
sub ith {
  my ($self, $i) = @_;
  ### ith(): $i

  if ($i < 0 || _is_infinite($i)) {  # don't loop forever if $i is +infinity
    return undef;
  }

  my $haferman_type = $self->{'haferman_type'} || 'array';
  my $radix = $self->{'radix'} || 3;
  my $two_digits;
  if ($haferman_type eq 'array') {
    if ($radix & 1) {
      $radix *= $radix;
    } else {
      $two_digits = 1;
    }
  } else {
    $two_digits = ($haferman_type eq 'alt');
  }

  my $value = 0;  # position even or odd
  for (;;) {
    if ($i) {
      my $digit = _divrem_mutate($i,$radix);
      if ($two_digits) {
        my $digit2 = _divrem_mutate($i,$radix);
        if ($haferman_type eq 'array') {
          $digit += $digit2;
        }
      }
      if ($digit & 1) {
        # stop at odd digit
        if ($value) {
          $value = 0;  # even position value=0 always
        } else {
          $value = ($haferman_type eq 'box' ? 0 : 1);
        }
        last;
      } else {
        # step position across even digit
        $value ^= 1;
      }
    } else {
      # no more digits, all even, no odd
      $value = $self->{'initial_value'};
      last;
    }
  }
  if ($self->{'inverse'}) {
    $value ^= 1;
  }
  return $value;
}

sub pred {
  my ($self, $value) = @_;
  return ($value == 0 || $value == 1);
}

#------------------------------------------------------------------------------

# return $remainder, modify $n
# the scalar $_[0] is modified, but if it's a BigInt then a new BigInt is made
# and stored there, the bigint value is not changed
sub _divrem_mutate {
  my $d = $_[1];
  my $rem;
  if (ref $_[0] && $_[0]->isa('Math::BigInt')) {
    ($_[0], $rem) = $_[0]->copy->bdiv($d);  # quot,rem in array context
    if (! ref $d || $d < 1_000_000) {
      return $rem->numify;  # plain remainder if fits
    }
  } else {
    $rem = $_[0] % $d;
    $_[0] = int(($_[0]-$rem)/$d); # exact division stays in UV
  }
  return $rem;
}

1;
__END__

=for stopwords Ryde Math-NumSeq

=head1 NAME

Math::NumSeq::HafermanCarpet -- bits of the Haferman carpet

=head1 SYNOPSIS

 use Math::NumSeq::HafermanCarpet;
 my $seq = Math::NumSeq::HafermanCarpet->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

X<Haferman, Jeff>This sequence is 0,1 bits of the Haferman carpet pattern
flattened for plotting in Z-Order or similar.

    0,1,0,1,0,1,0,1,0, 0,1,0,1,0,1,0,1,0, 0,1,0,1,0,1,0,1,0, 0,..
    starting i=0

When plotted in Z-Order with radix=3 the result begins as follows.  At a
bigger size an attractive pattern of interlocking loops can be seen.

=cut

# math-image --text --values=HafermanCarpet --path=ZOrderCurve,radix=3 --size=63x27

=pod

     *  *  * *** * *** *  *  *  *  *  * *** * *** *  *  *  *  *  *
    * ** ** ***** ***** ** ** ** ** ** ***** ***** ** ** ** ** ** *
     *  *  * *** * *** *  *  *  *  *  * *** * *** *  *  *  *  *  *
     *  *  *  * *** *  *  *  *  *  *  *  * *** *  *  *  *  *  *  *
    * ** ** ** ***** ** ** ** ** ** ** ** ***** ** ** ** ** ** ** *
     *  *  *  * *** *  *  *  *  *  *  *  * *** *  *  *  *  *  *  *
     *  *  * *** * *** *  *  *  *  *  * *** * *** *  *  *  *  *  *
    * ** ** ***** ***** ** ** ** ** ** ***** ***** ** ** ** ** ** *
     *  *  * *** * *** *  *  *  *  *  * *** * *** *  *  *  *  *  *
    *** * *** *  *  * *** * ****** * *** *  *  * *** * ****** * ***
    **** ***** ** ** ***** ******** ***** ** ** ***** ******** ****
    *** * *** *  *  * *** * ****** * *** *  *  * *** * ****** * ***
     * *** *  *  *  *  * *** *  * *** *  *  *  *  * *** *  * *** *
    * ***** ** ** ** ** ***** ** ***** ** ** ** ** ***** ** ***** *
     * *** *  *  *  *  * *** *  * *** *  *  *  *  * *** *  * *** *
    *** * *** *  *  * *** * ****** * *** *  *  * *** * ****** * ***
    **** ***** ** ** ***** ******** ***** ** ** ***** ******** ****
    *** * *** *  *  * *** * ****** * *** *  *  * *** * ****** * ***
     *  *  * *** * *** *  *  *  *  *  * *** * *** *  *  *  *  *  *
    * ** ** ***** ***** ** ** ** ** ** ***** ***** ** ** ** ** ** *
     *  *  * *** * *** *  *  *  *  *  * *** * *** *  *  *  *  *  *
     *  *  *  * *** *  *  *  *  *  *  *  * *** *  *  *  *  *  *  *
    * ** ** ** ***** ** ** ** ** ** ** ** ***** ** ** ** ** ** ** *
     *  *  *  * *** *  *  *  *  *  *  *  * *** *  *  *  *  *  *  *
     *  *  * *** * *** *  *  *  *  *  * *** * *** *  *  *  *  *  *
    * ** ** ***** ***** ** ** ** ** ** ***** ***** ** ** ** ** ** *
     *  *  * *** * *** *  *  *  *  *  * *** * *** *  *  *  *  *  *

The pattern is formed by a "morphism" where each 0 or 1 bit expands to a 3x3
array

          1  1  1             0  1  0
    0 ->  1  1  1       1 ->  1  0  1
          1  1  1             0  1  0

For the purpose of this sequence those arrays are flattened so

    0  -> 1,1,1,1,1,1,1,1,1
    1  -> 0,1,0,1,0,1,0,1,0

The sequence starts from a single initial value 0.  The expansion rules are
applied twice so as to grow that initial value to 9*9=81 values.  Then the
rules applied to each of those values twice again to give 9^4=6561 values,
and so on indefinitely.

An even number of expansion steps ensures the existing values are unchanged.
If an odd number of expansions were done then the first bit flips
0E<lt>-E<gt>1.  The even number of expansions can also be expressed as each
bit morphing into an 81-long run.

    0  -> 0,1,0,1,0,1,0,1,0,  # 9 times repeat
          0,1,0,1,0,1,0,1,0,
          0,1,0,1,0,1,0,1,0,
          ...

    1  -> 1,1,1,1,1,1,1,1,1,  # 9 times repeat
          0,1,0,1,0,1,0,1,0,  # alternate 111..111 or 010..010
          1,1,1,1,1,1,1,1,1,
          0,1,0,1,0,1,0,1,0,
          ...

See L</Ith> below for how the position of the lowest odd digit of i in
base-9 determines the sequence values.

=head2 Initial 1

Option C<initial_value =E<gt> 1> can start the sequence from a single value
1 instead.

    # initial_value => 1
    1,1,1,1,1,1,1,1,1,0,1,0,1,0,1,0,1,0,1,1,1,1,1,1,1,1,1,0,1,0,1,0,...

When plotted in Z-Order this begins

=cut

# math-image --text --values=HafermanCarpet,initial_value=1 --path=ZOrderCurve,radix=3 --size=63x27

=pod

    *** * ****** * ****** * *** *  *  * *** * *** *  *  * *** * ***
    **** ******** ******** ***** ** ** ***** ***** ** ** ***** ****
    *** * ****** * ****** * *** *  *  * *** * *** *  *  * *** * ***
     * *** *  * *** *  * *** *  *  *  *  * *** *  *  *  *  * *** *
    * ***** ** ***** ** ***** ** ** ** ** ***** ** ** ** ** ***** *
     * *** *  * *** *  * *** *  *  *  *  * *** *  *  *  *  * *** *
    *** * ****** * ****** * *** *  *  * *** * *** *  *  * *** * ***
    **** ******** ******** ***** ** ** ***** ***** ** ** ***** ****
    *** * ****** * ****** * *** *  *  * *** * *** *  *  * *** * ***
    *** * ****** * ****** * ****** * *** *  *  * *** * ****** * ***
    **** ******** ******** ******** ***** ** ** ***** ******** ****
    *** * ****** * ****** * ****** * *** *  *  * *** * ****** * ***
     * *** *  * *** *  * *** *  * *** *  *  *  *  * *** *  * *** *
    * ***** ** ***** ** ***** ** ***** ** ** ** ** ***** ** ***** *
     * *** *  * *** *  * *** *  * *** *  *  *  *  * *** *  * *** *
    *** * ****** * ****** * ****** * *** *  *  * *** * ****** * ***
    **** ******** ******** ******** ***** ** ** ***** ******** ****
    *** * ****** * ****** * ****** * *** *  *  * *** * ****** * ***
    *** * ****** * ****** * *** *  *  * *** * *** *  *  * *** * ***
    **** ******** ******** ***** ** ** ***** ***** ** ** ***** ****
    *** * ****** * ****** * *** *  *  * *** * *** *  *  * *** * ***
     * *** *  * *** *  * *** *  *  *  *  * *** *  *  *  *  * *** *
    * ***** ** ***** ** ***** ** ** ** ** ***** ** ** ** ** ***** *
     * *** *  * *** *  * *** *  *  *  *  * *** *  *  *  *  * *** *
    *** * ****** * ****** * *** *  *  * *** * *** *  *  * *** * ***
    **** ******** ******** ***** ** ** ***** ***** ** ** ***** ****
    *** * ****** * ****** * *** *  *  * *** * *** *  *  * *** * ***

This form has some 1s where the initial_value=0 had 0s.  The positions of
these extra 1s are the box fractal.

    * *   * *         * *   * *
     *     *           *     *
    * *   * *         * *   * *
       * *               * *
        *                 *
       * *               * *
    * *   * *         * *   * *
     *     *           *     *
    * *   * *         * *   * *
             * *   * *
              *     *
             * *   * *
                * *
                 *
                * *
             * *   * *
              *     *
             * *   * *
    * *   * *         * *   * *
     *     *           *     *
    * *   * *         * *   * *
       * *               * *
        *                 *
       * *               * *
    * *   * *         * *   * *
     *     *           *     *
    * *   * *         * *   * *

=head2 Inverse

The C<inverse =E<gt> 1> option (a boolean) can invert the 0,1 bits to
instead 1,0.  This can be applied to any of the types.  For example on the
default initial_value=0,

    # inverse => 1
    1,0,1,0,1,0,1,0,1,1,0,1,0,1,0,1,0,1,1,0,1,0,1,0,1,0,1,1,0,1,0,1,...

=head2 Plotting Order

The Z-Order curve (per for example L<Math::PlanePath::ZOrderCurve>) numbers
its sub-parts

    +---+---+---+
    | 6 | 7 | 8 |
    +---+---+---+
    | 3 | 4 | 5 |
    +---+---+---+
    | 0 | 1 | 2 |
    +---+---+---+

This suits the sequence here because the numbering is alternately odd and
even in adjacent sub-parts,

    +------+------+------+
    | even | odd  | even |
    +------+------+------+
    | odd  | even | odd  |
    +------+------+------+
    | even | odd  | even |
    +------+------+------+

X<Peano curve>X<Kochel curve>X<Haverkort>X<Wunderlich>X<Gray code path>Any
self-similar expansion which numbers by an odd/even alternation like this
gives the same result.  This includes the Peano curve, Wunderlich's
serpentine and meander, Haverkort's Kochel curve, and reflected Gray code
path (radix=3).

Incidentally, drawing each pixel by this sequence is not very efficient.
It's much faster to follow the array expansions described above and block
copy areas of "0" or "1".  An initial single pixel 0 expands to 3x3 then
9x9, etc.  Two images representing a "0" or a "1" can be maintained, though
with care some copying of sub-parts allows just one image to be built up.
See F<examples/other/haferman-carpet-x11.pl> for some code doing that.

=cut

# cf
# math-image --text --values=HafermanCarpet --path=SquareReplicate --size=63x27

=pod

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for the behaviour common to all path classes.

=over 4

=item C<$seq = Math::NumSeq::HafermanCarpet-E<gt>new (initial_value =E<gt> $integer, inverse =E<gt> $bool)>

Create and return a new sequence object.  C<initial_value> can be 0 or 1.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the C<$i>'th value from the sequence.

=back

=head1 FORMULAS

=head2 Ith

The effect of the morphism described above is to find the least significant
odd digit 1,3,5,7 when i is written in base-9.

    i lowest base-9
     digit 1,3,5,7           value
    --------------       -------------
    even position              1
    odd position               0
    no such digit        initial_value

    Position counted from low end.
    Least significant digit is position=0 so is an "even position".

For example i=609 is base-9 "746" and its lowest odd digit is the "7" which
is 2 digits from the low end and thus an "even position" and so value=1.

Or i=357 is base-9 "436" and its lowest odd digit is the "3" which is 1
digit from the low end and thus an "odd position" so value=0.

If i contains no odd base-9 digits at all then it's "no such digit" and the
result is the C<initial_value>.  For example i=58 is base-9 "64" which has
no odd digits so value=0 in the default "initial_value=0".  These i with no
odd base-9 digit are the box fractal pattern shown above which are the
places where initial_value 0 or 1 changes the sequence value.

"Position of lowest odd base-9 digit" can also be thought of as "count
trailing even base-9 digits".  If i is entirely even digits then that count
should be reckoned as infinite by imagining 0 digits extending infinitely at
the high end of i.  That "infinite" case is then the "no such digit" of the
table.

The value assigned to the three cases odd,even,none can each be 0 or 1 for a
total 8 combinations.  The cases above are 1,0,0 and 1,0,1 and their
1E<lt>-E<gt>0 inverses 0,1,1 and 0,1,0 per the C<inverse> option are the
four most intersting combinations.  The box fractal 0,0,1 and its inverse
1,1,0 are interesting but not generated by the code here.  The remaining two
0,0,0 which is all zeros or 1,1,1 all ones are not very interesting.

=head2 Density

The number of 1s in the first 9^k many values from the sequence is as
follows.

                     9^(k+1) - (2*(-1)^k + 7) * 5^k
    Seq1s_init0(k) = ------------------------------
                                   14

and for initial_value=1

                     9^(k+1) - (2*(-1)^k - 7) * 5^k
    Seq1s_init1(k) = ------------------------------
                                  14

The difference between the two is 5^k,

    Seq1s_init1 = Seq1s_init0 + 5^k

This difference is the box fractal 1s described above which are gained in
the initial_value=1 form.  They're at positions where i has only even digits
0,2,4,6,8 in base 9, so 5 digit possibilities at each of k many digit
positions giving 5^k.

X<Weinstein, Eric>The formulas can be calculated by considering how the 0s
and 1s expand.  The array morphism form with initial_value=1 is given by
Eric Weinstein,

=over

L<http://mathworld.wolfram.com/HafermanCarpet.html>,
L<http://oeis.org/A118005>

=back

Each point expands

    0 -> 9 of 1s
    1 -> 4 of 1s plus 5 of 0s

The 1s in the expanded form are therefore 9 from each existing "0" and 4
from each existing "1".  Since 0s+1s = 9^k this can be expressed in terms of
Array1s.

    Array1s(k+1) = 4*Array1s(k) + 9*Array0s(k)
                 = 4*Array1s(k) + 9*(9^k - Array1s(k))     # 0s+1s=9^k
                 = 9^(k+1) - 5*Array1s(k)

Expanding this recurrence repeatedly gives

    Array1s(k) =  5^0     * 9^k
                - 5^1     * 9^(k-1)
                + 5^2     * 9^(k-2)
                ...
                - (-5)^(k-1) * 9^1
                - (-5)^k     * 9^0 * Array1s(0)

The alternating signs in each term are -5 as the increasing power.  Since
Array1s(0)=1 the last term is included and the powers sum as follows in the
usual way.

                       9^(k+1) - (-5)^(k+1)
    Array1s_init1(k) = --------------------
                             9 - (-5)

If the initial starting cell is 0 instead of 1 then Array1s(0)=0 and the
last term S<(-1)^k * 5^k> is omitted.  Subtracting that leaves

                       9^(k+1) - 9*(-5)^k
    Array1s_init0(k) = ------------------
                            9 - (-5)

For the sequence forms here the initial value does not change, unlike the
array alternating 0E<lt>-E<gt>1.  The sequence takes the array starting 0 or
1 according as k is even or odd, thereby ensuring the first value is 0.  So,

    Seq1s_init0(k) = /  Array1s_init0(k)   if k even
                     \  Array1s_init1(k)   if k odd

The term S<(2*(-1)^k - 7)> seen above in the Seq1s_init0() formula selects
between 9 or 5 as the multiplier for (-5)^k.  That 9 or 5 multiplier is the
difference between the two Array1s forms.

=head1 SEE ALSO

L<Math::NumSeq>

L<Math::PlanePath::ZOrderCurve>,
L<Math::PlanePath::PeanoCurve>,
L<Math::PlanePath::WunderlichSerpentine>,
L<Math::PlanePath::KochelCurve>,
L<Math::PlanePath::GrayCode>,
L<Math::PlanePath::SquareReplicate>

F<examples/other/haferman-carpet-x11.pl> draws the carpet interactively with
C<X11::Protocol>.

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2013, 2014, 2016, 2017, 2019 Kevin Ryde

Math-NumSeq is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Math-NumSeq is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

=cut

# Local variables:
# compile-command: "math-image --wx --values=HafermanCarpet --path=ZOrderCurve,radix=3 --scale=5"
# End:
#
