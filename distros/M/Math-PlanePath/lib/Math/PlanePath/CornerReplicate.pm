# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde

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


package Math::PlanePath::CornerReplicate;
use 5.004;
use strict;
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 129;
use Math::PlanePath;
@ISA = ('Math::PlanePath');
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_down_pow',
  'bit_split_lowtohigh',
  'digit_split_lowtohigh';

# uncomment this to run the ### lines
# use Smart::Comments;


use constant n_start => 0;
use constant class_x_negative => 0;
use constant class_y_negative => 0;
*xy_is_visited = \&Math::PlanePath::Base::Generic::xy_is_visited_quad1;

use constant dy_maximum => 1;     # dY=1,-1,-3,-7,-15,etc only
use constant dsumxy_maximum => 1;
use constant ddiffxy_minimum => -1;
use constant dir_maximum_dxdy => (2,-1);  # ESE
use constant turn_any_straight => 0; # never straight


#------------------------------------------------------------------------------
my @digit_to_x = (0,1,1,0);
my @digit_to_y = (0,0,1,1);

sub n_to_xy {
  my ($self, $n) = @_;
  ### CornerReplicate n_to_xy(): $n

  if ($n < 0) { return; }
  if (is_infinite($n)) { return ($n,$n); }

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

  my $x = my $y = ($n * 0);  # inherit bignum 0
  my $len = $x + 1;          # inherit bignum 1

  foreach my $digit (digit_split_lowtohigh($n,4)) {
    ### at: "$x,$y  digit=$digit"

    $x += $digit_to_x[$digit] * $len;
    $y += $digit_to_y[$digit] * $len;
    $len *= 2;
  }

  ### final: "$x,$y"
  return ($x,$y);
}

my @digit_to_next_dx = (1, 0, -1, -1);
my @digit_to_next_dy = (0, 1,  0, 0);

# use Smart::Comments;
sub n_to_dxdy {
  my ($self, $n) = @_;
  ### CornerReplicate n_to_dxdy(): $n

  if ($n < 0) { return; }
  if (is_infinite($n)) { return ($n,$n); }

  my $zero = $n * 0;
  my $int = int($n);
  $n -= $int;  # fractional part

  my $digit = _divrem_mutate($int,4);
  ### low digit: $digit

  if ($digit == 0) {
    # N = "...0" eg. N=0
    #     ^
    #     |   this dX=1,dY=0
    # N---*   next dX=0,dY=1
    # dX = dXthis*(1-frac) + dXnext*frac
    #    = 1*(1-frac) + 0*frac
    #    = 1-frac
    # dY = dYthis*(1-frac) + dYnext*frac
    #    = 0*(1-frac) + 1*frac
    #    = frac
    return (1-$n,$n);
  }

  if ($digit == 1) {
    # N = "...1" eg. N=1
    # <---*
    #     |   this dX=0,dY=1
    #     N   next dX=-1,dY=0
    # dX = dXthis*(1-frac) + dXnext*frac
    #    = 0*(1-frac) + -1*frac
    #    = -frac
    # dY = dYthis*(1-frac) + dYnext*frac
    #    = 1*(1-frac) + 0*frac
    #    = 1-frac
    return (-$n,1-$n);
  }

  my ($dx,$dy);
  if ($digit == 2) {
    # N="...2"
    #  *---N     this dX=-1, dY=0
    #   \        next dX=power, dY=power
    #    \
    # power part for next only needed if $n fractional
    $dx = -1;
    $dy = 0;

    if ($n) {
      # N = "[digit]333..3332"
      (my $exp, $digit) = _count_low_base4_3s($int);

      if ($digit == 1) {
        # N = "1333..3332" so N=6, N=30, N=126, ...
        #  ^
        #  |         this dX=-1, dY=0
        #  *---N     next dX=0, dY=+1
        # dX = dXthis*(1-frac) + dXnext*frac
        #    = -1*(1-frac) + 0*frac
        #    = frac-1
        # dY = dYthis*(1-frac) + dYnext*frac
        #    = 0*(1-frac) + 1*frac
        #    = frac
        return ($n-1, $n);
      }

      my $next_dx = (2+$zero) ** ($exp+1);
      my $next_dy;
      ### power: $dx

      if ($digit) { # $digit == 2
        # N = "2333..3332" so N=10, N=14, N=62, ...
        #    *---N     this dX=-1, dY=0
        #   /          next dX=-2^k, dY=-(2^k-1)=1-2^k
        #  /
        $next_dx = -$next_dx;
        $next_dy = $next_dx+1;
      } else {            # $digit == 0
        # N = "0333..3332" so N=2, N=14, N=62, ...
        #  *---N     this dX=-1, dY=0
        #   \        next dX=+2^k, dY=-(2^k-1)=1-2^k
        #    \
        $next_dy = 1-$next_dx;
      }

      my $f1 = 1-$n;
      $dx = $f1*$dx + $n*$next_dx;
      $dy = $f1*$dy + $n*$next_dy;
    }

  } else { # $digit == 3
    my ($exp, $digit) = _count_low_base4_3s($int);
    ### $exp
    ### $digit

    if ($digit == 1) {
      # N   = "1333..333" eg. N=31
      # N+1 = "2000..000" eg. N=32
      # *--->
      # |      this dX=0, dY=+1
      # N      next dX=+1, dY=0
      # dX = dXthis*(1-frac) + dXnext*frac
      #    = 0*(1-frac) + 1*frac
      #    = frac
      # dY = dYthis*(1-frac) + dYnext*frac
      #    = 1*(1-frac) + 0*frac
      #    = 1-frac
      return ($n, 1-$n);
    }

    $dx = (2+$zero) ** ($exp+1);
    ### power: $dx
    if ($digit) { # $digit == 2
      # N = "2333..333" so N=11, N=47, N=191
      #    N
      #   /       this dX=-2^k, dY=-(2^k-1)=1-2^k
      #  /        next dX=1, dY=0
      # *->
      $dx = -$dx;
      $dy = $dx+1;
    } else {            # $digit == 0
      # N = "0333..333" so N=3, N=15, N=63, ...
      # N
      #  \        this dX=2^k, dY=-(2^k-1)=1-2^k
      #   \       next dX=1, dY=0
      #    *->
      $dy = 1-$dx;
    }

    if ($n) {
      # dX*(1-frac) + nextdX*frac
      # dY*(1-frac) + nextdY*frac
      # nextdX=1, nextdY=0
      my $f1 = 1-$n;
      $dx = $f1*$dx + $n;
      $dy = $f1*$dy;
    }
  }
  ### final: "$dx,$dy"
  return ($dx,$dy);
}

# Return ($count,$digit) where $count is how many trailing 3s on $n
# (possibly 0), and $digit is the next digit above those 3s.
sub _count_low_base4_3s {
  my ($n) = @_;
  my $count =0;
  for (;;) {
    my $digit = _divrem_mutate($n,4);
    if ($digit != 3) {
      return ($count,$digit);
    }
    $count++;
  }
}

# my @yx_to_digit = ([0,1],
#                    [3,2]);
sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### CornerReplicate xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);
  if ($x < 0 || $y < 0) {
    return undef;
  }
  if (is_infinite($x)) { return $x; }
  if (is_infinite($y)) { return $y; }

  my @xbits = bit_split_lowtohigh($x);
  my @ybits = bit_split_lowtohigh($y);

  my $n = ($x * 0 * $y); # inherit bignum 0
  foreach my $i (reverse 0 .. max($#xbits,$#ybits)) {  # high to low
    $n *= 4;
    my $ydigit = $ybits[$i] || 0;
    $n += 2*$ydigit + (($xbits[$i]||0) ^ $ydigit);
  }
  return $n;
}

# these tables generated by tools/corner-replicate-table.pl
my @min_digit = (0,0,1, 0,0,1, 3,2,2);
my @max_digit = (0,1,1, 3,3,2, 3,3,2);

# exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### CornerReplicate rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);
  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;
  ### rect: "X = $x1 to $x2, Y = $y1 to $y2"

  if ($x2 < 0 || $y2 < 0) {
    ### rectangle outside first quadrant ...
    return (1, 0);
  }

  my ($len, $level) = round_down_pow (max($x2,$y2), 2);
  ### $len
  ### $level
  if (is_infinite($level)) {
    return (0,$level);
  }

  my $n_min = my $n_max
    = my $x_min = my $y_min
      = my $x_max = my $y_max
        = ($x1 * 0 * $x2 * $y1 * $y2); # inherit bignum 0

  while ($level-- >= 0) {
    ### $level

    {
      my $x_cmp = $x_max + $len;
      my $y_cmp = $y_max + $len;
      my $digit = $max_digit[($x1 >= $x_cmp ? 2 : $x2 >= $x_cmp ? 1 : 0)
                             + ($y1 >= $y_cmp ? 6 : $y2 >= $y_cmp ? 3 : 0)];
      $n_max = 4*$n_max + $digit;
      if ($digit_to_x[$digit]) { $x_max += $len; }
      if ($digit_to_y[$digit]) { $y_max += $len; }

      # my $key = ($x1 >= $x_cmp ? 2 : $x2 >= $x_cmp ? 1 : 0)
      #   + ($y1 >= $y_cmp ? 6 : $y2 >= $y_cmp ? 3 : 0);
      ### max ...
      ### len:  sprintf "%#X", $len
      ### $x_cmp
      ### $y_cmp
      # ### $key
      ### $digit
      ### n_max: sprintf "%#X", $n_max
      ### $x_max
      ### $y_max
    }

    {
      my $x_cmp = $x_min + $len;
      my $y_cmp = $y_min + $len;
      my $digit = $min_digit[($x1 >= $x_cmp ? 2 : $x2 >= $x_cmp ? 1 : 0)
                             + ($y1 >= $y_cmp ? 6 : $y2 >= $y_cmp ? 3 : 0)];
      $n_min = 4*$n_min + $digit;
      if ($digit_to_x[$digit]) { $x_min += $len; }
      if ($digit_to_y[$digit]) { $y_min += $len; }

      # my $key = ($x1 >= $x_cmp ? 2 : $x2 >= $x_cmp ? 1 : 0)
      #   + ($y1 >= $y_cmp ? 6 : $y2 >= $y_cmp ? 3 : 0);
      ### min ...
      ### len:  sprintf "%#X", $len
      ### $x_cmp
      ### $y_cmp
      # ### $key
      ### $digit
      ### n_min: sprintf "%#X", $n_min
      ### $x_min
      ### $y_min
    }
    $len /= 2;
  }

  return ($n_min, $n_max);
}

#------------------------------------------------------------------------------
# levels

use Math::PlanePath::HilbertCurve;
*level_to_n_range = \&Math::PlanePath::HilbertCurve::level_to_n_range;
*n_to_level       = \&Math::PlanePath::HilbertCurve::n_to_level;

#------------------------------------------------------------------------------
1;
__END__

=for stopwords eg Ryde Math-PlanePath OEIS bitwise dSum=dX+dY dX dSum

=head1 NAME

Math::PlanePath::CornerReplicate -- replicating U parts

=head1 SYNOPSIS

 use Math::PlanePath::CornerReplicate;
 my $path = Math::PlanePath::CornerReplicate->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path is a self-similar replicating corner fill with 2x2 blocks.
X<U Order>It's sometimes called a "U order" since the base N=0 to N=3 is
like a "U" (sideways).

     7  | 63--62  59--58  47--46  43--42
        |      |       |       |       |
     6  | 60--61  56--57  44--45  40--41
        |          |               |
     5  | 51--50  55--54  35--34  39--38
        |      |       |       |       |
     4  | 48--49  52--53  32--33  36--37
        |                  |
     3  | 15--14  11--10  31--30  27--26
        |      |       |       |       |
     2  | 12--13   8-- 9  28--29  24--25
        |          |               |
     1  |  3-- 2   7-- 6  19--18  23--22
        |      |       |       |       |
    Y=0 |  0-- 1   4-- 5  16--17  20--21
        +--------------------------------
          X=0  1   2   3   4   5   6   7

The pattern is the initial N=0 to N=3 section,

    +-------+-------+
    |       |       |
    |   3   |   2   |
    |       |       |
    +-------+-------+
    |       |       |
    |   0   |   1   |
    |       |       |
    +-------+-------+

It repeats as 2x2 blocks arranged in the same pattern, then 4x4 blocks, etc.
There's no rotations or reflections within sub-parts.

X axis N=0,1,4,5,16,17,etc is all the integers which use only digits 0 and 1
in base 4.  For example N=17 is 101 in base 4.

Y axis N=0,3,12,15,48,etc is all the integers which use only digits 0 and 3
in base 4.  For example N=51 is 303 in base 4.

The X=Y diagonal N=0,2,8,10,32,34,etc is all the integers which use only
digits 0 and 2 in base 4.

The X axis is the same as the C<ZOrderCurve>.  The Y axis here is the X=Y
diagonal of the C<ZOrderCurve>, and conversely the X=Y diagonal here is the
Y axis of the C<ZOrderCurve>.

The N value at a given X,Y is converted to or from the C<ZOrderCurve> by
transforming base-4 digit values 2E<lt>-E<gt>3.  This can be done by a
bitwise "X xor Y".  When Y has a 1-bit the xor swaps 2E<lt>-E<gt>3 in N.

    ZOrder X  = CRep X xor CRep Y
    ZOrder Y  = CRep Y

    CRep X  = ZOrder X xor ZOrder Y
    CRep Y  = ZOrder Y

See L<Math::PlanePath::LCornerReplicate> for a rotating corner form.

=head2 Level Ranges

A given replication extends to

    Nlevel = 4^level - 1
    0 <= X < 2^level
    0 <= Y < 2^level

=head2 Hamming Distance

The Hamming distance between two integers X and Y is the number of bit
positions where the two values differ when written in binary.  In this
corner replicate each bit-pair of N becomes a bit of X and a bit of Y,

       N      X   Y
    ------   --- ---
    0 = 00    0   0
    1 = 01    1   0     <- difference 1 bit
    2 = 10    1   1
    3 = 11    0   1     <- difference 1 bit

So the Hamming distance is the number of base4 bit-pairs of N which are 01
or 11.  Counting bit positions from 0 for least significant bit, this is the
1-bits in even positions,

    HammingDist(X,Y) = count 1-bits at even bit positions in N
                     = 0,1,0,1, 1,2,1,2, 0,1,0,1, 1,2,1,2, ... (A139351)

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::CornerReplicate-E<gt>new ()>

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

Return C<(0, 4**$level - 1)>.

=back

=head1 FORMULAS

=head2 N to dX,dY

The change dX,dY is given by N in base 4 count trailing 3s and the digit
above those trailing 3s.

    N = ...[d]333...333      base 4
              \--exp--/

When N to N+1 crosses between 4^k blocks it goes as follows.  Within a block
the pattern is the same, since there's no rotations or transposes etc.

    N, N+1        X      Y        dX       dY       dSum     dDiffXY
    --------   -----  -------   -----  --------    ------    -------
    033..33       0    2^k-1      2^k  -(2^k-1)        +1    2*2^k-1
    100..00      2^k       0

    133..33      2^k    2^k-1       0       +1         +1       -1
    200..00      2^k    2^k

    133..33      2^k  2*2^k-1    -2^k     1-2^k   -(2^k-1)      -1
    200..00       0     2^k

    133..33       0   2*2^k-1   2*2^k -(2*2^k-1)       +1    4*2^k-1
    200..00    2*2^k      0

It can be noted dSum=dX+dY the change in X+Y is at most +1, taking values 1,
-1, -3, -7, -15, etc.  The crossing from block 2 to 3 drops back, such as at
N=47="233" to N=48="300".  Everywhere else it advances by +1 anti-diagonal.

The difference dDiffXY=dX-dY the change in X-Y decreases at most -1, taking
similar values -1, 1, 3, 7, 15, etc but in a different order to dSum.

=head1 OEIS

This path is in Sloane's Online Encyclopedia of Integer Sequences as

=over

L<http://oeis.org/A000695> (etc)

=back

    A059906    Y coordinate
    A059905    X xor Y, being ZOrderCurve X
    A139351    HammingDist(X,Y), count 1-bits at even positions in N

    A000695    N on X axis, base 4 digits 0,1 only
    A001196    N on Y axis, base 4 digits 0,3 only
    A062880    N on diagonal, base 4 digits 0,2 only
    A163241    permutation base-4 flip 2<->3,
                 converts N to ZOrderCurve N, and back

    A048647    permutation N at transpose Y,X
                 base4 digits 1<->3

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::LTiling>,
L<Math::PlanePath::SquareReplicate>,
L<Math::PlanePath::GosperReplicate>,
L<Math::PlanePath::ZOrderCurve>,
L<Math::PlanePath::GrayCode>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde

This file is part of Math-PlanePath.

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
