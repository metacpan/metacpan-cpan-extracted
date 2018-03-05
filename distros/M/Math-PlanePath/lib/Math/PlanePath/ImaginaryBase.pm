# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.


# math-image --path=ImaginaryBase --lines --scale=10
# math-image --path=ImaginaryBase --all --output=numbers_dash --size=80x50
#
# cf A005351 positives as negabinary index
#    A005352 negatives as negabinary index
#    A039724 positives as negabinary index, in binary
#    A027615 negabinary bit count
#            = 3 * A072894(n+1) - 2n - 3
#    A098725 first diffs of A072894
#    A000695 same value binary and negabinary, being base 4 digits 0,1
#    A001045 abs(negabinary) of 0b11111 all ones (2^n-(-1)^n)/3
#    A185269 negabinary primes
#
#    A073785 positives as -3 index
#    A007608 positives as -4 index
#    A073786 -5
#    A073787 -6
#    A073788 -7
#    A073789 -8
#    A073790 -9
#    A039723 positives as negadecimal index
#    A051022 same value integer and negadecimal, 0s between digits
#
# http://mathworld.wolfram.com/Negabinary.html
# http://mathworld.wolfram.com/Negadecimal.html

package Math::PlanePath::ImaginaryBase;
use 5.004;
use strict;
#use List::Util 'min','max';
*min = \&Math::PlanePath::_min;
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 126;
use Math::PlanePath;
@ISA = ('Math::PlanePath');
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'parameter_info_array', # radix parameter
  'round_down_pow',
  'round_up_pow',
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';

use Math::PlanePath::ZOrderCurve;
*_digit_interleave = \&Math::PlanePath::ZOrderCurve::_digit_interleave;

# uncomment this to run the ### lines
#use Smart::Comments;


use constant n_start => 0;
use constant xy_is_visited => 1;
use constant absdx_minimum => 1;   # X coord always changes

sub x_negative_at_n {
  my ($self) = @_;
  return $self->{'radix'}**2;
}
sub y_negative_at_n {
  my ($self) = @_;
  return $self->{'radix'}**3;
}

sub dir_maximum_dxdy {
  my ($self) = @_;
  return ($self->{'radix'}-1, -2);
}

sub turn_any_straight {
  my ($self) = @_;
  return ($self->{'radix'} != 2);  # radix=2 never straight
}
sub _UNDOCUMENTED__turn_any_left_at_n {
  my ($self) = @_;
  return $self->{'radix'} - 1;
}
sub _UNDOCUMENTED__turn_any_right_at_n {
  my ($self) = @_;
  return $self->{'radix'};
}



#------------------------------------------------------------------------------
sub new {
  my $self = shift->SUPER::new(@_);

  my $radix = $self->{'radix'};
  if (! defined $radix || $radix <= 2) { $radix = 2; }
  $self->{'radix'} = $radix;

  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### ImaginaryBase n_to_xy(): $n

  if ($n < 0) { return; }
  if (is_infinite($n)) { return ($n,$n); }

  # ENHANCE-ME: lowest non-(r-1) digit determines direction to next, or
  # something like that
  {
    my $int = int($n);
    ### $int
    ### $n
    if ($n != $int) {
      my ($x1,$y1) = $self->n_to_xy($int);
      my ($x2,$y2) = $self->n_to_xy($int+1);
      my $frac = $n - $int;  # inherit possible BigFloat
      my $dx = $x2-$x1;
      my $dy = $y2-$y1;
      return ($frac*$dx + $x1, $frac*$dy + $y1);
    }
    $n = $int;       # BigFloat int() gives BigInt, use that
  }

  my $radix = $self->{'radix'};
  my $x = 0;
  my $y = 0;
  my $len = ($n*0)+1;  # inherit bignum 1

  if (my @digits = digit_split_lowtohigh($n, $radix)) {
    $radix = -$radix;
    for (;;) {
      $x += (shift @digits) * $len;  # digits low to high
      @digits || last;

      $y += (shift @digits) * $len;  # digits low to high
      @digits || last;

      $len *= $radix;  # $radix negative negates each time
    }
  }

  ### final: "$x,$y"
  return ($x,$y);
}

# ($x-$digit) and ($y-$digit) are multiples of $radix, but apply int() in
# case floating point rounding
#
sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### ImaginaryBase xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  if (is_infinite($x)) { return ($x); }

  $y = round_nearest ($y);
  if (is_infinite($y)) { return ($y); }

  my $radix = $self->{'radix'};
  my $zero = ($x * 0 * $y);  # inherit bignum 0
  my @n; # digits low to high

  while ($x || $y) {
    ### at: "x=$x,y=$y   n=".join(',',@n)

    push @n, _divrem_mutate ($x, $radix);
    $x = -$x;
    push @n, _divrem_mutate ($y, $radix);
    $y = -$y;
  }
  return digit_join_lowtohigh (\@n,$radix, $zero);
}

# left xmax = (r-1) + (r^2 -r) + (r^3-r^2) + ... + (r^k - r^(k-1))
#           = r^(k-1) - 1
#
# right xmin = - (r + r^3 + ... + r^(2k+1))
#            = -r * (1 + r^2 + ... + r^2k)
#            = -r * ((r^2)^(k+1) -1) / (r^2 - 1)
#

# exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### ImaginaryBase rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest($x1);
  $y1 = round_nearest($y1);
  $x2 = round_nearest($x2);
  $y2 = round_nearest($y2);

  my $zero = $x1 * 0 * $y1 * $x2 * $y2;
  my $radix = $self->{'radix'};

  my ($min_xdigits, $max_xdigits)
    = _negaradix_range_digits_lowtohigh($x1,$x2, $radix);
  unless (defined $min_xdigits) {
    return (0, $max_xdigits); # infinity
  }

  my ($min_ydigits, $max_ydigits)
    = _negaradix_range_digits_lowtohigh($y1,$y2, $radix);
  unless (defined $min_ydigits) {
    return (0, $max_ydigits); # infinity
  }

  ### $min_xdigits
  ### $max_xdigits
  ### min_x: digit_join_lowtohigh ($min_xdigits, $radix, $zero)
  ### max_x: digit_join_lowtohigh ($max_xdigits, $radix, $zero)
  ### $min_ydigits
  ### $max_ydigits
  ### min_y: digit_join_lowtohigh ($min_ydigits, $radix, $zero)
  ### max_y: digit_join_lowtohigh ($max_ydigits, $radix, $zero)

  my @min_digits = _digit_interleave ($min_xdigits, $min_ydigits);
  my @max_digits = _digit_interleave ($max_xdigits, $max_ydigits);

  ### final ...
  ### @min_digits
  ### @max_digits

  return (digit_join_lowtohigh (\@min_digits, $radix, $zero),
          digit_join_lowtohigh (\@max_digits, $radix, $zero));
}



# Return arrayrefs ($min_digits, $max_digits) which are the digits making
# up the index range for negaradix values $x1 to $x2 inclusive.
# The arrays are lowtohigh, so $min_digits->[0] is the least significant digit.
#
sub _negaradix_range_digits_lowtohigh {
  my ($x1,$x2, $radix) = @_;
  ### _negaradix_range_digits(): "$x1,$x2  radix=$radix"

  if ($x1 > $x2) { ($x1,$x2) = ($x2,$x1); }  # make x1 <= x2

  my $radix_minus_1 = $radix - 1;
  ### $radix
  ### $radix_minus_1


  my ($len, $level, $min_base) = _negaradix_range_level ($x1,$x2, $radix);
  ### $len
  ### $level
  if (is_infinite($level)) {
    return (undef, $level);
  }
  my $max_base = $min_base;

  ### assert: $min_base <= $x1
  ### assert: $min_base + $len > $x2

  my @min_digits;   # digits formed high to low, stored low to high
  my @max_digits;
  while (--$level > 0) {
    $len /= $radix;
    ### at: "len=$len  reverse"

    # reversed digits, x1 low end for max, x2 high end for min
    {
      my $digit = max (0,
                       min ($radix_minus_1,
                            int (($x2 - $min_base) / $len)));
      ### min base: $min_base
      ### min diff: $x2-$min_base
      ### min digit raw: $digit
      ### min digit reversed: $radix_minus_1 - $digit
      $min_base += $digit * $len;
      $min_digits[$level] = $radix_minus_1 - $digit;
    }
    {
      my $digit = max (0,
                       min ($radix_minus_1,
                            int (($x1 - $max_base) / $len)));
      ### max base: $max_base
      ### max diff: $x1-$max_base
      ### max digit raw: $digit
      ### max digit reversed: $radix_minus_1 - $digit
      $max_base += $digit * $len;
      $max_digits[$level--] = $radix_minus_1 - $digit;
    }

    $len /= $radix;
    ### at: "len=$len  plain"

    # plain digits, x1 low end for min, x2 high end for max
    {
      my $digit = max (0,
                       min ($radix_minus_1,
                            int (($x1 - $min_base) / $len)));
      ### min base: $min_base
      ### min diff: $x1-$min_base
      ### min digit: $digit
      $min_base += $digit * $len;
      $min_digits[$level] = $digit;
    }
    {
      my $digit = max (0,
                       min ($radix_minus_1,
                            int (($x2 - $max_base) / $len)));
      ### max base: $max_base
      ### max diff: $x2-$max_base
      ### max digit: $digit
      $max_base += $digit * $len;
      $max_digits[$level] = $digit;
    }
  }
  ### @min_digits
  ### @max_digits
  return (\@min_digits, \@max_digits);
}

# return ($len,$level,$base)
# $level = number of digits in the bigest integer in negaradix $x1..$x2,
#          rounded up to be $level even
# $len = $radix**$level
# $base = lowest negaradix reached by indexes from 0 to $len-1
#
# have $base <= $x1, $x2 < $base+$len
# and $level is the smallest even number with that coverage
#
# negabinary
# 0,1,5,21
#
# negaternary
#   1  3  9 27  81 243
# 0,2,   20    182
#     -6   -60    -546
#
sub _negaradix_range_level {
  my ($x1,$x2, $radix) = @_;
  ### _negaradix_range_level(): "$x1,$x2  radix=$radix"
  ### assert: $x1 <= $x2

  my ($len, $level)
    = round_down_pow (max($radix - $x1*($radix + 1),
                          (($radix+1)*$x2 - 1) * $radix),
                      $radix);
  if ($level & 1) {
    ### increase level to even ...
    $len *= $radix;
    $level += 1;
  }
  ### $len
  ### $level

  # because level is even r^2k-1 is a multiple of r^2-1 and therefore of r+1
  ### assert: ($len-1) % ($radix+1) == 0

  return ($len,
          $level,
          ((1-$len) / ($radix+1)) * $radix);  # base
}


#------------------------------------------------------------------------------
# levels

# shared by ImaginaryHalf and CubicBase
sub level_to_n_range {
  my ($self, $level) = @_;
  return (0, $self->{'radix'}**$level - 1);
}
sub n_to_level {
  my ($self, $n) = @_;
  if ($n < 0) { return undef; }
  if (is_infinite($n)) { return $n; }
  $n = round_nearest($n);
  my ($pow, $exp) = round_up_pow ($n+1, $self->{'radix'});
  return $exp;
}

#------------------------------------------------------------------------------
1;
__END__

=for stopwords eg Ryde Math-PlanePath quater-imaginary Radix radix ie Negabinary negabinary negaternary negadecimal NX negaradix Nmin Nmax Nmin,Nmax NX NX,NY OEIS Seminumerical CACM

=head1 NAME

Math::PlanePath::ImaginaryBase -- replications in four directions

=head1 SYNOPSIS

 use Math::PlanePath::ImaginaryBase;
 my $path = Math::PlanePath::ImaginaryBase->new (radix => 4);
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This is a simple pattern arising from complex numbers expressed in a base
i*sqrt(2) or other i*sqrt(r) base.  Or equivalently by negabinary encoded
X,Y digits interleaved.  The default radix=2 is

    38   39   34   35   54   55   50   51        5
    36   37   32   33   52   53   48   49        4
    46   47   42   43   62   63   58   59        3
    44   45   40   41   60   61   56   57        2
     6    7    2    3   22   23   18   19        1
     4    5    0    1   20   21   16   17    <- Y=0
    14   15   10   11   30   31   26   27       -1
    12   13    8    9   28   29   24   25       -2
               ^
    -2   -1   X=0   1    2    3    4    5

The pattern can be seen by dividing into blocks as follows,

    +---------------------------------------+
    | 38   39   34   35   54   55   50   51 |
    |                                       |
    | 36   37   32   33   52   53   48   49 |
    |                                       |
    | 46   47   42   43   62   63   58   59 |
    |                                       |
    | 44   45   40   41   60   61   56   57 |
    +---------+---------+-------------------+
    |  6    7 |  2    3 | 22   23   18   19 |
    |         +----+----+                   |
    |  4    5 |  0 |  1 | 20   21   16   17 |
    +---------+----+----+                   |
    | 14   15   10   11 | 30   31   26   27 |
    |                   |                   |
    | 12   13    8    9 | 28   29   24   25 |
    +-------------------+-------------------+

After N=0 at the origin, N=1 replicates that single point to the right.
Then that pair repeats above as N=2 and N=3.  Then that 2x2 block repeats to
the left as N=4 to N=7, then 4x2 repeated below as N=8 to N=16.  Then 4x4 to
the right as N=16 to N=31, etc.  Each repeat is 90 degrees further around.
The relative layout and orientation of a sub-part is unchanged when
replicated.

=head2 Complex Base

This pattern arises from representing a complex number in "base" i*sqrt(r).
For an integer X,Y,

    b = i*sqrt(r)
    a[i] = 0 to r-1 digits

    X+Y*i*sqrt(r) = a[k]*b^k + ... + a[2]*b^2 + a[1]*b + a[0]

and N is the a[i] digits in base r

    N = a[k]*r^k + ... + a[2]*r^2 + a[1]*r + a[0]

X<Knuth, Donald>The factor sqrt(r) makes the generated Y an integer.  For
actual use as a number base that factor can be omitted and instead
fractional digits a[-1]*r^-1 etc used to reach smaller Y values, as for
example in Knuth's "quater-imaginary" system of base 2*i, being i*sqrt(4),
with digits 0,1,2,3.  (Knuth Seminumerical Algorithms section 4.1 and CACM
1960 pp245-247.)

The powers of i in the base give the replication direction, so i^0=1 right,
i^1=i up, i^2=-1 right, i^3=-i down, etc.  The power of sqrt(r) then spreads
the replication in the respective direction.  It takes two steps to repeat
horizontally and sqrt(r)^2=r hence the doubling of 1x1 to the right, 2x2 to
the left, 4x4 to the right, etc, and similarly vertically.

=head2 Negabinary

The way blocks repeat horizontally first to the right and then to the left
is per the negabinary system base b=-2.

    X = x[k]*(-2)^k + ... + x[2]*(-2)^2 + x[1]*(-2) + x[0]

The effect is to represent any positive or negative X by a positive integer
index NX.

    X, negabinary: ... -1 -2  0  1  2  3  4  5 ...
    index NX:           2  3  0  1  6  7  4  5

Notice how the 0 point replicates to the right as 1 and then that pair 0,1
replicates to the left as 2,3.  Then the block 2,3,0,1 repeats to the right
as 6,7,4,5 which the same order with 4 added to each.  Then the resulting
block of eight repeats to the left similarly, in the same order with 8 added
to each.

The C<ImaginaryBase> takes the indexes NX and NY of these negabinary forms
and forms N by interleaving the digits (bits) of NX and NY.  That
interleaving is in the style of the C<ZOrderCurve>.

    zX,zY = ZOrderCurve n_to_xy(N)
    X = to_negabinary(zX)
    Y = to_negabinary(zY)
    X,Y equals ImaginaryBase n_to_xy(N)

The C<ZOrderCurve> replicates blocks alternately right and up, whereas for
C<ImaginaryBase> here it's right,up,left,down repeating.

=head2 Radix

The C<radix> parameter controls the radix used to break N into X,Y.  For
example radix 3 replicates to make 3x1, 3x3, 9x3, 9x9, etc blocks.  The
replications are radix-1=2 copies of the preceding level at each stage,

    radix => 3

    +------------------------+-----------+
    | 24  25  26  15  16  17 | 6   7   8 |      2
    |                        |           |
    | 21  22  23  12  13  14 | 3   4   5 |      1
    |                        +-----------+
    | 18  19  20   9  10  11 | 0   1   2 |  <- Y=0
    +------------------------+-----------+
    | 51  52  53  42  43  44  33  34  35 |     -1
    |                                    |
    | 48  49  50  39  40  41  30  31  32 |     -2
    |                                    |
    | 45  46  47  36  37  38  27  28  29 |     -3
    |                                    |
    | 78  79  80  69  70  71  60  61  62 |     -4
    |                                    |
    | 75  76  77  66  67  68  57  58  59 |     -5
    |                                    |
    | 72  73  74  63  64  65  54  55  56 |     -6
    +------------------------------------+
                               ^
      -6  -5  -4  -3  -2  -1  X=0  1   2

X,Y are "negaternary" in this case, and similar negaradix base=-radix for
higher values.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::ImaginaryBase-E<gt>new ()>

=item C<$path = Math::PlanePath::ImaginaryBase-E<gt>new (radix =E<gt> $r)>

Create and return a new path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

=item C<($n_lo, $n_hi) = $path-E<gt>rect_to_n_range ($x1,$y1, $x2,$y2)>

The returned range is exact, meaning C<$n_lo> and C<$n_hi> are the smallest
and biggest in the rectangle.

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<(0, $radix**$level - 1)>.

=back

=head1 FORMULAS

=head2 Rectangle to N Range

The X and Y ranges can be treated separately and then interleaved,

    NXmin,NXmax = negaradix range to cover x1..x2
    NYmin,NYmax = negaradix range to cover y1..y2

    Nmin = interleave digits NXmin, NYmin
    Nmax = interleave digits NXmax, NYmax

If the NX,NY ranges are exact then the resulting Nmin,Nmax range is exact.

An exact negaradix range can be calculated by digits high to low by
considering the range taken by the negaradix form.  For example two
negaternary digits,

    N digit              2         1         0
                   +---------+---------+---------+
    N index        | 6  7  8 | 3  4  5 | 0  1  2 |
                   +---------+---------+---------+
    X negaternary   -6 -5 -4  -3 -2 -1   0  1  2
                    ^
                   base

Taking the base=-90909...90 which is the lowest taken (where 9 is the radix
digit R-1), then the next digit of N is the position from X-base, taken
alternately reverse 2,1,0 as shown here or forward 0,1,2.

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to this
path include,

=over

L<http://oeis.org/A057300> (etc)

=back

    radix=2
      A057300    permutation N at transpose Y,X (swap bit pairs)

    radix=3
      A163327    permutation N at transpose Y,X (swap trit pairs)

    radix=4
      A126006    permutation N at transpose Y,X (swap digit pairs)

    radix=16
      A217558    permutation N at transpose Y,X (swap digit pairs)

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::ImaginaryHalf>,
L<Math::PlanePath::CubicBase>,
L<Math::PlanePath::ZOrderCurve>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

Math-PlanePath is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Math-PlanePath is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.

=cut
