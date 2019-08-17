# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018 Kevin Ryde

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


# math-image --path=SquareArms --lines --scale=10
# math-image --path=SquareArms --all --output=numbers_dash
# math-image --path=SquareArms --values=Polygonal,polygonal=8
#
# RepdigitsAnyBase fall on 14 or 15 lines ...
#

package Math::PlanePath::SquareArms;
use 5.004;
use strict;
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 127;
use Math::PlanePath;
use Math::PlanePath::Base::NSEW;
@ISA = ('Math::PlanePath::Base::NSEW',
        'Math::PlanePath');

use Math::PlanePath::Base::Generic
  'round_nearest';
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;
*_sqrtint = \&Math::PlanePath::_sqrtint;

# uncomment this to run the ### lines
#use Smart::Comments '###';


use constant arms_count => 4;
use constant xy_is_visited => 1;
use constant x_negative_at_n => 4;
use constant y_negative_at_n => 5;
use constant turn_any_right => 0; # only left or straight


#------------------------------------------------------------------------------

# 28
# 172 +144
# 444 +272 +128
# 844 +400 +128

# [ 0, 1, 2, 3,],
# [ 0, 2, 6, 12 ],
# N = (d^2 + d)
# d = -1/2 + sqrt(1 * $n + 1/4)
#   = (-1 + 2*sqrt($n + 1/4)) / 2
#   = (-1 + sqrt(4*$n + 1)) / 2

sub n_to_xy {
  my ($self, $n) = @_;
  ### SquareArms n_to_xy(): $n

  if ($n < 2) {
    if ($n < 1) { return; }
    ### centre
    return (0, 1-$n);  # from n=1 towards n=5 at x=0,y=-1
  }
  $n -= 2;

  my $frac;
  { my $int = int($n);
    $frac = $n - $int;
    $n = $int;  # BigFloat int() gives BigInt, use that
  }

  # arm as initial rotation
  my $rot = _divrem_mutate($n,4);
  ### $n

  my $d = int( (-1 + _sqrtint(4*$n+1)) / 2 );
  ### d frac: ((-1 + sqrt(4*$n + 1)) / 2)
  ### $d
  ### base: $d*($d+1)

  $n -= $d*($d+1);
  ### remainder: $n

  $rot += ($d % 4);
  my $x = $d + 1;
  my $y = $frac + $n - $d;

  $rot %= 4;
  if ($rot & 2) {
    $x = -$x;  # rotate 180
    $y = -$y;
  }
  if ($rot & 1) {
    return (-$y,$x);  # rotate +90
  } else {
    return ($x,$y);
  }
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  $x = round_nearest ($x);
  $y = round_nearest ($y);
  ### SquareArms xy_to_n: "$x,$y"

  if ($x == 0 && $y == 0) {
    return 1;
  }

  my $rot = 0;
  # eg. y=2 have (0<=>$y)-$y == -1-2 == -3
  if ($y <= ($x <=> 0) - $x) {
    ### below diagonal, rot 180 ...
    $rot = 2;
    $x = -$x;  # rotate 180
    $y = -$y;
  }
  if ($x < $y) {
    ### left of diagonal, rot -90 ...
    $rot++;
    ($x,$y) = ($y,-$x);       # rotate -90
  }

  # diagonal down from N=2
  #     x=1  d=0   n=2
  #     x=5  d=4   n=82
  #     x=9  d=8   n=290
  #     x=13 d=12  n=626
  # N = (4 d^2 + 4 d + 2)
  #   = (4 x^2 - 4 x + 2)
  # offset = y + x-1    upwards from diagonal
  # N + 4*offset
  #   = (4*x^2 - 4*x + 2) + 4*(y + x-1)
  #   = 4*x^2 - 4*x + 2 + 4*y + 4*x - 4
  #   = 4*x^2 + 4*y - 2
  # cf N=4*x^2 is on the X or Y axis, which is X axis after rotation
  #
  ### xy: "$x,$y"
  ### $rot
  ### x offset: $x-1 + $y
  ### d mod: $d % 4
  ### rot d mod: (($rot-$d) % 4)
  return ($x*$x + $y)*4 - 2 + (($rot-$x+1) % 4);
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
  my ($d_lo, $d_hi) = _rect_square_range ($x1,$y1, $x2,$y2);
  return (((4*$d_lo - 4)*$d_lo + 1),
          max ($self->xy_to_n($x1,$y1),
                $self->xy_to_n($x1,$y2),
                $self->xy_to_n($x2,$y1),
                $self->xy_to_n($x2,$y2)));
}

sub _rect_square_range {
  my ($x1,$y1, $x2,$y2) = @_;
  ### _rect_square_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  # if x1,x2 opposite signs then origin x=0 covered, similarly y
  my $x_zero_uncovered = ($x1<0) == ($x2<0);
  my $y_zero_uncovered = ($y1<0) == ($y2<0);

  foreach ($x1,$y1, $x2,$y2) {
    $_ = abs($_);
  }
  ### abs rect: "x=$x1 to $x2,  y=$y1 to $y2"

  if ($x2 < $x1) { ($x1,$x2) = ($x2,$x1) } # swap to x1<x2
  if ($y2 < $y1) { ($y1,$y2) = ($y2,$y1) } # swap to y1<y2

  my $dlo = ($x_zero_uncovered ? $x1 : 0);
  if ($y_zero_uncovered && $dlo < $y1) { $dlo = $y1 }

  return ($dlo,
          ($x2 > $y2 ? $x2 : $y2));
}

1;
__END__

=for stopwords Math-PlanePath Ryde repdigit dlo dlo-1 Nlo Nhi

=head1 NAME

Math::PlanePath::SquareArms -- four spiral arms

=head1 SYNOPSIS

 use Math::PlanePath::SquareArms;
 my $path = Math::PlanePath::SquareArms->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path follows four spiral arms, each advancing successively,

                ...--33--29                 3
                          |
     26--22--18--14--10  25                 2
      |               |   |
     30  11-- 7-- 3   6  21                 1
      |   |           |   |
    ...  15   4   1   2  17  ...        <- Y=0
          |   |   |       |   |
         19   8   5-- 9--13  32            -1
          |   |               |
         23  12--16--20--24--28            -2
          |
         27--31--...                       -3

      ^   ^   ^   ^   ^   ^   ^ 
     -3  -2  -1  X=0  1   2   3 ...

Each arm is quadratic, with each loop 128 longer than the preceding.
X<Square numbers>The perfect squares fall in eight straight lines 4, with
the even squares on the X and Y axes and the odd squares on the diagonals
X=Y and X=-Y.

Some novel straight lines arise from numbers which are a repdigit in one or
more bases (Sloane's A167782).  "111" in various bases falls on straight
lines.  Numbers "[16][16][16]" in bases 17,19,21,etc are a horizontal at Y=3
because they're perfect squares, and "[64][64][64]" in base 65,66,etc go a
vertically downwards from X=12,Y=-266 similarly because they're squares.

Each arm is N=4*k+rem for a remainder rem=0,1,2,3, so sequences related to
multiples of 4 or with a modulo 4 pattern may fall on particular arms.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::SquareArms-E<gt>new ()>

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

=head1 FORMULAS

=head2 Rectangle N Range

Within a square X=-d...+d, and Y=-d...+d the biggest N is the end of the N=5
arm in that square, which is N=9, 25, 49, 81, etc, (2d+1)^2, in successive
corners of the square.  So for a rectangle find a surrounding d square,

    d = max(abs(x1),abs(y1),abs(x2),abs(y2))

from which

    Nmax = (2*d+1)^2
         = (4*d + 4)*d + 1

This can be used for a minimum too by finding the smallest d covered by the
rectangle.

    dlo = max (0,
               min(abs(y1),abs(y2)) if x=0 not covered
               min(abs(x1),abs(x2)) if y=0 not covered
              )

from which the maximum of the preceding dlo-1 square,

    Nlo = /  1 if dlo=0
          \  (2*(dlo-1)+1)^2 +1  if dlo!=0
              = (2*dlo - 1)^2
              = (4*dlo - 4)*dlo + 1

For a tighter maximum, horizontally N increases to the left or right of the
diagonal X=Y line (or X=Y+/-1 line), which means one end or the other is the
maximum.  Similar vertically N increases above or below the off-diagonal
X=-Y so the top or bottom is the maximum.  This means for a rectangle the
biggest N is at one of the four corners,

    Nhi = max (xy_to_n (x1,y1),
               xy_to_n (x1,y2),
               xy_to_n (x2,y1),
               xy_to_n (x2,y2))

The current code uses a dlo for Nlo and the corners for Nhi, which means the
high is exact but the low is not.

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::DiamondArms>,
L<Math::PlanePath::HexArms>,
L<Math::PlanePath::SquareSpiral>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018 Kevin Ryde

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
