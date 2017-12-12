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


# math-image --path=DiamondArms --lines --scale=10
# math-image --path=DiamondArms --all --output=numbers_dash
# math-image --path=DiamondArms --values=Polygonal,polygonal=8
#
# RepdigitsAnyBase fall on 14 or 15 lines ...
#

package Math::PlanePath::DiamondArms;
use 5.004;
use strict;
#use List::Util 'min', 'max';
*min = \&Math::PlanePath::_min;
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 125;
use Math::PlanePath;
@ISA = ('Math::PlanePath');
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;
*_sqrtint = \&Math::PlanePath::_sqrtint;

use Math::PlanePath::Base::Generic
  'round_nearest';
use Math::PlanePath::DiamondSpiral;

# uncomment this to run the ### lines
#use Devel::Comments;


use constant arms_count => 4;
use constant xy_is_visited => 1;
use constant x_negative_at_n => 8;
use constant y_negative_at_n => 5;

use constant dx_minimum => -1;
use constant dx_maximum => 1;
use constant dy_minimum => -1;
use constant dy_maximum => 1;
use constant _UNDOCUMENTED__dxdy_list => (1,1,   # NE  diagonals
                           -1,1,  # NW
                           -1,-1, # SW
                           1,-1); # SE
use constant absdx_minimum => 1;
use constant absdy_minimum => 1;
use constant dsumxy_minimum => -2; # diagonals
use constant dsumxy_maximum => 2;
use constant ddiffxy_minimum => -2;
use constant ddiffxy_maximum => 2;
use constant dir_minimum_dxdy => (1,1);  # North-East
use constant dir_maximum_dxdy => (1,-1); # South-East
use constant turn_any_right => 0; # only left or straight


#------------------------------------------------------------------------------
# 28
# 172 +144
# 444 +272 +128
# 844 +400 +128

# [ 0, 1, 2, 3,],
# [ 0, 1, 3, 6 ],
# N = (1/2 d^2 + 1/2 d)
#   = (1/2*$d**2 + 1/2*$d)
#   = ($d+1)*$d/2
# d = -1/2 + sqrt(2 * $n + 1/4)
#   = (-1 + sqrt(8*$n + 1))/2

sub n_to_xy {
  my ($self, $n) = @_;
  ### DiamondArms n_to_xy(): $n
  if ($n < 1) {
    return;
  }
  $n -= 1;
  my $frac;
  {
    my $int = int($n);
    $frac = $n - $int;
    $n = $int;  # BigFloat int() gives BigInt, use that
  }

  # arm as initial rotation
  my $rot = _divrem_mutate($n,4);
  ### $n

  # if (($rot%4) != 3) {
  #   return;
  # }

  my $d = int ((-1 + _sqrtint(8*$n+1)) / 2);
  ### d frac: ((-1 + sqrt(8*$n + 1)) / 2)
  ### $d
  ### base: $d*($d+1)/2

  $n -= $d*($d+1)/2;
  ### remainder: $n
  ### assert: $n <= $d

  my $x = ($frac + $n) - $d;
  my $y = - ($frac + $n);
  ### unrot: "$x,$y"

  $rot = ($rot + $d) % 4;
  ### $rot

  if ($rot == 1) {
    ($x,$y) = (1-$y, $x);    # rotate +90 and right
  } elsif ($rot == 2) {
    ($x,$y) = (1-$x, 1-$y);   # rotate 180 and up+right
  } elsif ($rot == 3) {
    ($x,$y) = ($y, 1-$x);    # rotate +90 and up
  }
  return ($x,$y);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  $x = round_nearest ($x);
  $y = round_nearest ($y);
  ### DiamondArms xy_to_n: "$x,$y"

  my $rot = 0;
  # eg. y=2 have (0<=>$y)-$y == -1-2 == -3
  if ($y >= ($x > 0)) {
    ### above horizontal, rot -180 ...
    $rot = 2;
    $x = 1-$x;  # rotate 180 and offset
    $y = 1-$y;
  }
  if ($x > 0) {
    ### right of vertical, rot -90 ...
    $rot++;
    ($x,$y) = ($y,1-$x);       # rotate -90 and offset
  }

  # horizontal negative X axis
  # d = -x + -y
  #     d=0     n=1
  #     d=4    n=41
  #     d=8    n=145
  #     d=12   n=313
  # N = (2 d^2 + 2 d + 1)
  #   = (2*$d**2 + 2*$d + 1)
  #   = ((2*$d + 2)*$d + 1)
  #
  my $d = -$x - $y;
  ### xy: "$x,$y"
  ### $d
  ### $rot
  ### base: ((2*$d + 2)*$d + 1)
  ### offset: -4 * $y
  ### rot d mod: (($rot+$d+2) % 4)
  return ((2*$d + 2)*$d + 1) - 4*$y + (($rot-$d) % 4);
}


# d    = [ 1, 2,   3,  4,  5,   6,   7,   8,   9 ],
# Nmax = [ 9, 25, 49, 81, 121, 169, 225, 289, 361 ]
#   being the N=5 arm one spot before the corner of each run
# N = (4 d^2 + 4 d + 1)
#   = (2d+1)^2
#   = ((4*$d + 4)*$d + 1)
# or for d-1
# N = (4 d^2 - 4 d + 1)
#   = (2d-1)^2
#   = ((4*$d - 4)*$d + 1)
#
# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);
  my $x = (($x1<0) == ($x2<0) ? min(abs($x1),abs($x2)) : 0);
  my $y = (($y1<0) == ($y2<0) ? min(abs($y1),abs($y2)) : 0);
  my $d = max(0, $x + $y - 2);
  return (((2*$d + 2)*$d + 1),
          max ($self->xy_to_n($x1,$y1),
               $self->xy_to_n($x1,$y2),
               $self->xy_to_n($x2,$y1),
               $self->xy_to_n($x2,$y2)));
}

1;
__END__

      #                25                              4
      #              /    \
      #           29   14   21     ...                 3
      #         /    /    \    \     \
      #     ...   18    7   10   17    32              2
      #         /    /    \    \    \    \
      #      22   11    4    3    6   13   28          1
      #    /    /    /         /    /    /
      # 26   15    8    1    2    9   24           <- Y=0
      #    \    \    \    \    /    /
      #      30   19   12    5   20  ...              -1
      #         \    \    \    /    /
      #         ...    23   16   31                   -2
      #                   \    /
      #                     27                        -3

      #            25                             4
      #           /    \
      #        29  14  21    ...                 3
      #       /   /   \   \    \
      #    ... 18   7  10  17  32              2
      #       /   /   \   \   \   \
      #     22 11   4   3   6  13   28          1
      #   /   /   /       /   /    /
      # 26  15  8   1   2   9  24           <- Y=0
      #   \   \   \   \   /   /
      #     30 19  12   5  20  ...              -1
      #       \   \   \   /   /
      #       ...  23  16  31                   -2
      #                  \   /
      #                   27                        -3


=for stopwords Math-PlanePath Ryde ie

=head1 NAME

Math::PlanePath::DiamondArms -- four spiral arms

=head1 SYNOPSIS

 use Math::PlanePath::DiamondArms;
 my $path = Math::PlanePath::DiamondArms->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path follows four spiral arms, each advancing successively in a diamond
pattern,

                 25   ...                    4
             29  14  21  36                  3
         33  18   7  10  17  32              2
     ... 22  11   4   3   6  13  28          1
     26  15   8   1   2   9  24 ...      <- Y=0
         30  19  12   5  20  35             -1
             34  23  16  31                 -2
               ...   27                     -3

                  ^
     -3  -2  -1  X=0  1   2   3   4

Each arm makes a spiral widening out by 4 each time around, thus leaving
room for four such arms.  Each arm loop is 64 longer than the preceding
loop.  For example N=13 to N=85 below is 84-13=72 points, and the next loop
N=85 to N=221 is 221-85=136 which is an extra 64, ie. 72+64=136.

                 25          ...
                /  \           \
              29  . 21  .  .  . 93
             /        \           \
           33  .  .  . 17  .  .  . 89
          /              \           \
        37  .  .  .  .  . 13  .  .  . 85
       /                 /           /
     41  .  .  .  1  .  9  .  .  . 81
       \           \  /           /
        45  .  .  .  5  .  .  . 77
          \                    /
           49  .  .  .  .  . 73
             \              /
              53  .  .  . 69
                \        /
                 57  . 65
                   \  /
                    61

Each arm is N=4*k+rem for a remainder rem=0,1,2,3, so sequences related to
multiples of 4 or with a modulo 4 pattern may fall on particular arms.

The starts of each arm N=1,2,3,4 are at X=0 or 1 and Y=0 or 1,

               ..
                 \
             4    3  ..          Y=1
           /        /
         ..  1    2           <- Y=0
              \
               ..
             ^    ^
            X=0  X=1

They could be centred around the origin by taking X-1/2,Y-1/2 so for example
N=1 would be at -1/2,-1/2.  But the it's done as N=1 at 0,0 to stay in
integers.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::DiamondArms-E<gt>new ()>

Create and return a new path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  For C<$n
E<lt> 1> the return is an empty list, as the path starts at 1.

Fractional C<$n> gives a point on the line between C<$n> and C<$n+4>, that
C<$n+4> being the next point on the same spiralling arm.  This is probably
of limited use, but arises fairly naturally from the calculation.

=back

=head2 Descriptive Methods

=over

=item C<$arms = $path-E<gt>arms_count()>

Return 4.

=back

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::SquareArms>,
L<Math::PlanePath::DiamondSpiral>

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
