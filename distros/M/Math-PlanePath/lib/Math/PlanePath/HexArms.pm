# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.


# math-image --path=HexArms --lines --scale=10
# math-image --path=HexArms --all --output=numbers_dash
# math-image --path=HexArms --values=Polygonal,polygonal=8

# Abundant: A005101
# octagonal numbers ...
# 26-gonal near vertical x2
# 152 near horizontal
#
# 2
# 164  +162
# 542  +378  +216
# 1136 +594  +216
#

package Math::PlanePath::HexArms;
use 5.004;
use strict;
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 126;
use Math::PlanePath;
@ISA = ('Math::PlanePath');
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;
*_sqrtint = \&Math::PlanePath::_sqrtint;

use Math::PlanePath::Base::Generic
  'round_nearest';

# uncomment this to run the ### lines
#use Devel::Comments '###';


use constant arms_count => 6;
*xy_is_visited = \&Math::PlanePath::Base::Generic::xy_is_even;

use constant x_negative_at_n => 4;
use constant y_negative_at_n => 6;
use constant dx_minimum => -2;
use constant dx_maximum => 2;
use constant dy_minimum => -1;
use constant dy_maximum => 1;
*_UNDOCUMENTED__dxdy_list = \&Math::PlanePath::_UNDOCUMENTED__dxdy_list_six;
use constant absdx_minimum => 1;
use constant dsumxy_minimum => -2; # diagonals
use constant dsumxy_maximum => 2;
use constant ddiffxy_minimum => -2;
use constant ddiffxy_maximum => 2;
use constant dir_maximum_dxdy => (1,-1); # South-East
use constant turn_any_right => 0; # only left or straight


#------------------------------------------------------------------------------

# [ 0, 1, 2, 3,],
# [ 0, 1, 3, 6 ],
# N = (1/2 d^2 + 1/2 d)
# d = -1/2 + sqrt(2 * $n + 1/4)
#   = (-1 + 2*sqrt(2 * $n + 1/4)) / 2
#   = (-1 + sqrt(8 * $n + 1)) / 2

sub n_to_xy {
  my ($self, $n) = @_;
  #### HexArms n_to_xy: $n

  if ($n < 2) {
    if ($n < 1) { return; }
    ### centre
    $n--;
    return ($n, -$n);  # from n=1 towards n=7 at x=1,y=-1
  }
  $n -= 2;

  my $frac;
  { my $int = int($n);
    $frac = $n - $int;
    $n = $int;  # BigFloat int() gives BigInt, use that
  }

  # arm as initial rotation
  my $rot = _divrem_mutate($n,6);
  ### $n

  my $d = int ((-1 + _sqrtint(8 * $n + 1)) / 2);
  ### d frac: ((-1 + _sqrtint(8 * $n + 1)) / 2)
  ### $d
  ### base: $d*($d+1)/2

  $n -= $d*($d+1)/2;
  ### remainder: $n
  ### assert: $n <= $d

  $rot += ($d % 6);
  my $x = $frac + 2 + $d + $n;
  my $y = $frac     - $d + $n;

  $rot %= 6;
  if ($rot >= 3) {
    $rot -= 3;
    $x = -$x;  # rotate 180
    $y = -$y;
  }
  if ($rot == 0) {
    return ($x,$y);
  } elsif ($rot == 1) {
    return (($x-3*$y)/2,   # rotate +60
            ($x+$y)/2);
  } else {
    return (($x+3*$y)/-2,  # rotate +120
            ($x-$y)/2);
  }
}

sub xy_to_n {
  my ($self, $x, $y) = @_;

  $x = round_nearest ($x);
  $y = round_nearest ($y);
  ### HexArms xy_to_n: "x=$x, y=$y"
  if (($x ^ $y) & 1) {
    return undef;  # nothing on odd points
  }
  if ($x == 0 && $y == 0) {
    return 1;
  }

  my $rot = 0;
  # eg. y=2 have (0<=>$y)-$y == -1-2 == -3
  if ($x < (0 <=> $y) - $y) {
    ### left diagonal half ...
    $rot = 3;
    $x = -$x;  # rotate 180
    $y = -$y;
  }
  if ($x < $y) {
    ### upper mid sixth, rot 2 ...
    $rot += 2;
    ($x,$y) = ((3*$y-$x)/2,              # rotate -120
               ($x+$y)/-2);
  } elsif ($y > 0) {
    ### first sixth, rot 1 ...
    $rot++;
    ($x,$y) = (($x+3*$y)/2,   # rotate -60
               ($y-$x)/2);
  } else {
    ### last sixth, rot 0 ...
  }
  ### assert: ($x+$y) % 2 == 0

  # diagonal down from N=2
  #     d=0  n=2
  #     d=6  n=128
  #     d=12  n=470
  # N = (3 d^2 + 3 d + 2)
  #   = ((3*$d + 3)*$d + 2)
  # xoffset = 3*($x+$y-2)
  # N + xoffset = ((3*$d + 3)*$d + 2) + 3*($x+$y-2)
  #             = (3*$d + 3)*$d + 2 + 3*($x+$y) - 6
  #             = (3*$d + 3)*$d + 3*($x+$y) - 4
  #
  my $d = ($x-$y-2)/2;
  ### xy: "$x,$y"
  ### $rot
  ### x offset: $x+$y-2
  ### x offset sixes: 3*($x+$y-2)
  ### quadratic: "d=$d  q=".((3*$d + 3)*$d + 2)
  ### d mod: $d % 6
  ### rot d mod: (($rot-$d) % 6)
  return ((3*$d + 3)*$d) + 3*($x+$y) - 4 + (($rot-$d) % 6);
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;

  # d    = [ 1, 2,   3,  4,  5,   6,   7,   8,   9 ],
  # Nmax = [ 7, 19, 37, 61, 91, 127, 169, 217, 271 ]
  #   being the N=7 arm one spot before the corner of each run
  # N = (3 d^2 + 3 d + 1)
  #   = ((3*$d + 3)*$d + 1)
  #
  my $d = _rect_to_hex_radius ($x1,$y1, $x2,$y2);
  return (1,
          ((3*$d + 3)*$d + 1));
}

# hexagonal distance
sub _rect_to_hex_radius {
  my ($x1,$y1, $x2,$y2) = @_;

  $x1 = abs (round_nearest ($x1));
  $y1 = abs (round_nearest ($y1));
  $x2 = abs (round_nearest ($x2));
  $y2 = abs (round_nearest ($y2));

  # radial symmetric in +/-y
  my $y = max (abs($y1), abs($y2));

  # radial symmetric in +/-x
  my $x = max (abs($x1), abs($x2));

  return ($y >= $x
          ? $y                      # middle
          : int(($x + $y + 1)/2));  # end, round up
}

1;
__END__

=for stopwords Math-PlanePath Ryde

=head1 NAME

Math::PlanePath::HexArms -- six spiral arms

=head1 SYNOPSIS

 use Math::PlanePath::HexArms;
 my $path = Math::PlanePath::HexArms->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path follows six spiral arms, each advancing successively,

                                   ...--66                      5
                                          \
             67----61----55----49----43    60                   4
            /                         \      \
         ...    38----32----26----20    37    54                3
               /                    \     \     \
             44    21----15---- 9    14    31    48   ...       2
            /     /              \      \    \     \     \
          50    27    10---- 4     3     8    25    42    65    1
          /    /     /                 /     /     /     /
       56    33    16     5     1     2    19    36    59    <-Y=0
      /     /     /     /        \        /     /     /
    62    39    22    11     6     7----13    30    53         -1
      \     \     \     \     \              /     /
      ...    45    28    17    12----18----24    47            -2
               \     \     \                    /
                51    34    23----29----35----41   ...         -3
                  \     \                          /
                   57    40----46----52----58----64            -4
                     \
                      63--...                                  -5

     ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^
    -9 -8 -7 -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6  7  8  9

The X,Y points are integers using every second position to give a triangular
lattice, per L<Math::PlanePath/Triangular Lattice>.

Each arm is N=6*k+rem for a remainder rem=0,1,2,3,4,5, so sequences related
to multiples of 6 or with a modulo 6 pattern may fall on particular arms.

=head2 Abundant Numbers

The "abundant" numbers are those N with sum of proper divisors E<gt> N.  For
example 12 is abundant because it's divisible by 1,2,3,4,6 and their sum is
16.  All multiples of 6 starting from 12 are abundant.  Plotting the
abundant numbers on the path gives the 6*k arm and some other points in
between,

                * * * * * * * * * * * *   *   *   ...
               *                       *           *
              *   *   *           *     *   *       *
             *                           *           *
            *           *                 *           *
           *                           *   *           *
          *           * * * * * *           *       *   *
         *           *           *   *       *           *
        *   *   *   *         *   *           *       *   *
       *           *               *   *   *   *           *
      *   *   *   *                 *           *   *       *
     *           *   *             *   *       *           *
    *       *   *                 *           *           *
     *           *           * * *           *           *
      *           *                 *       *           *
       *   *       *   *   *           *   *           *
        *           *                     *   *       *
         *           *       *           *           *
          *   *       *                 *   *   *   *
           *           * * * * * * * * *           *
            *   *                         *       *
             *         *       *                 *
              *   *                         *   *
               *         *       *       *     *
                *                             *
                 * * * * * * * * * * * * * * *

There's blank arms either side of the 6*k because 6*k+1 and 6*k-1 are not
abundant until some fairly big values.  The first abundant 6*k+1 might be
5,391,411,025, and the first 6*k-1 might be 26,957,055,125.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::HexArms-E<gt>new ()>

Create and return a new square spiral object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.

For C<$n E<lt> 1> the return is an empty list, as the path starts at 1.

Fractional C<$n> gives a point on the line between C<$n> and C<$n+6>, that
C<$n+6> being the next on the same spiralling arm.  This is probably of
limited use, but arises fairly naturally from the calculation.

=back

=head2 Descriptive Methods

=over

=item C<$arms = $path-E<gt>arms_count()>

Return 6.

=back

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::SquareArms>,
L<Math::PlanePath::DiamondArms>,
L<Math::PlanePath::HexSpiral>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
