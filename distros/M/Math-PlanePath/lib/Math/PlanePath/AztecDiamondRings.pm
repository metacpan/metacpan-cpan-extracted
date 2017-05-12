# Copyright 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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



# cute groupings
# AztecDiamondRings, FibonacciWord fibonacci_word_type plain, 10x10 scale 15


package Math::PlanePath::AztecDiamondRings;
use 5.004;
use strict;
#use List::Util 'min', 'max';
*min = \&Math::PlanePath::_min;
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 124;
use Math::PlanePath;
@ISA = ('Math::PlanePath');
*_sqrtint = \&Math::PlanePath::_sqrtint;

use Math::PlanePath::Base::Generic
  'round_nearest';

# uncomment this to run the ### lines
# use Smart::Comments;


use constant parameter_info_array =>
  [
   Math::PlanePath::Base::Generic::parameter_info_nstart1(),
  ];

use constant n_frac_discontinuity => 0;
use constant xy_is_visited => 1;

sub x_negative_at_n {
  my ($self) = @_;
  return $self->n_start + 1;
}
sub y_negative_at_n {
  my ($self) = @_;
  return $self->n_start + 2;
}
use constant dx_minimum => -1;
use constant dx_maximum => 1;
use constant dy_minimum => -1;
use constant dy_maximum => 1;
use constant _UNDOCUMENTED__dxdy_list => (1,0,   # E
                           1,1,   # NE
                           # not North
                           -1,1,  # NW
                           -1,0,  # W
                           -1,-1, # SW
                           0,-1,  # S
                           1,-1); # SE;
use constant dsumxy_minimum => -2; # diagonals
use constant dsumxy_maximum => 2;
use constant ddiffxy_minimum => -2;
use constant ddiffxy_maximum => 2;
use constant dir_maximum_dxdy => (1,-1); # South-East
use constant turn_any_right => 0; # only left or straight


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);
  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }
  return $self;
}

# starting from X axis and n_start=0
# d = [ 1, 2, 3, 4, 5 ]
# n = [ 0,4,12,24,40 ]
# N = (2 d^2 - 2 d)
#   = (2*$d**2 - 2*$d)
#   = ((2*$d - 2)*$d)
# d = 1/2 + sqrt(1/2 * $n + 1/4)
#   = (sqrt(2*$n+1) + 1)/2
#
# X negative axis
# d = [ 1, 2, 3, 4,5 ]
# n = [ 2, 8, 18, 32, 50 ]
# N = (2 d^2)

sub n_to_xy {
  my ($self, $n) = @_;
  #### n_to_xy: $n

  # adjust to N=0 at origin X=0,Y=0
  $n = $n - $self->{'n_start'};
  if ($n < 0) { return; }

  my $d = int( (_sqrtint(2*$n+1) + 1)/2 );
  $n -= 2*$d*$d;   # to $n=0 half way around at horiz Y=-1 X<-1

  if ($n < 0) {
    my $x = -$d-$n-1;
    if ($n < -$d) {
      # top-right
      return ($x,
              min($n+2*$d, $d-1));
    } else {
      # top-left
      return (max($x, -$d),
              -1-$n);
    }
  } else {
    my $x = $n-$d;
    if ($n < $d) {
      # bottom-left
      my $y = -1-$n;
      return ($x,
              max($y, -$d));
    } else {
      # bottom-right
      return (min($x, $d-1),
              $n-2*$d);
    }
  }
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### AztecDiamondRings xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);

  if ($x >= 0) {
    my $d = $x + abs($y);
    return (2*$d + 2)*$d + $y + $self->{'n_start'};
  }
  if ($y >= 0) {
    my $d = $y - $x;
    return 2*$d*$d - 1 - $y + $self->{'n_start'};
  } else {
    my $d = $y + $x;
    return (2*$d + 4)*$d + 1 - $y + $self->{'n_start'};
  }
}


#          |                   |  x2>=-x1         |
#    M---+ |               M-------M              |  +---M
#    |   | |               |   |   |              |  |   |
#    +---m |               +----m--+              |  m---+
#          |                   |                  |
#     -----+------      -------+-------      -----+--------
#          |                   |                  |
#
#          |                   |                  |
#    M---+ |               M-------M  y2>=-y1     |  +---M
#    |   | |               |   |   |              |  |   |
#    |   m |               |   |   |              |  m   |
#   -------+------      -------m-------      -----+--------
#    |   | |               |   |   |              |  |   |
#    M---+ |               M-------M              |  +---M
#          |                   |                  |
#
#          |                   |                  |
#     -----+------      -------+-------      -----+--------
#          |                   |                  |
#    +---m |               +--m----+              |  m---+
#    |   | |               |   |   |              |  |   |
#    M---+ |               M-------M              |  +---M
#          |                   |                  |

# exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### AztecDiamondRings rect_to_n_range(): "$x1,$y1, $x2,$y2"

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;

  my $min_x = 0;
  my $min_y = ($y2 < 0   ? ($min_x = -1, $y2)
               : $y1 > 0 ? $y1
               : 0);
  if ($x2 < $min_x)    { $min_x = $x2 }  # right edge if 0/-1 not covered
  elsif ($x1 > $min_x) { $min_x = $x1 }  # left edge if 0/-1 not covered

  my $max_y = ($y2 >= -$y1 ? $y2 : $y1);
  my $max_x = ($x2 >= -$x1-($max_y<0) ? $x2 : $x1);

  ### min at: "$min_x, $min_y"
  ### max at: "$max_x, $max_y"
  return ($self->xy_to_n($min_x,$min_y),
          $self->xy_to_n($max_x,$max_y));
}

1;
__END__

=for stopwords eg Ryde Math-PlanePath ie xbase OEIS

=head1 NAME

Math::PlanePath::AztecDiamondRings -- rings around an Aztec diamond shape

=head1 SYNOPSIS

 use Math::PlanePath::AztecDiamondRings;
 my $path = Math::PlanePath::AztecDiamondRings->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path makes rings around an Aztec diamond shape,

=cut

# math-image --path=AztecDiamondRings --all --output=numbers --size=60x14

=pod

                 46-45                       4
                /     \
              47 29-28 44                    3
             /  /     \  \
           48 30 16-15 27 43  ...            2
          /  /  /     \  \  \  \
        49 31 17  7--6 14 26 42 62           1
       /  /  /  /     \  \  \  \  \
     50 32 18  8  2--1  5 13 25 41 61    <- Y=0
      |  |  |  |  |  |  |  |  |  |
     51 33 19  9  3--4 12 24 40 60          -1
       \  \  \  \     /  /  /  /
        52 34 20 10-11 23 39 59             -2
          \  \  \     /  /  /
           53 35 21-22 38 58                -3
             \  \     /  /
              54 36-37 57                   -4
                \     /
                 55-56                      -5

                     ^
    -5 -4 -3 -2 -1  X=0 1  2  3  4  5

This is similar to the C<DiamondSpiral>, but has all four corners flattened
to 2 vertical or horizontal, instead of just one in the C<DiamondSpiral>.
This is only a small change to the alignment of numbers in the sides, but is
more symmetric.

X<Hexagonal numbers>Y axis N=1,6,15,28,45,66,etc are the hexagonal numbers
k*(2k-1).  The hexagonal numbers of the "second kind" 3,10,21,36,55,78, etc
k*(2k+1), are the vertical at X=-1 going downwards.  Combining those two is
the triangular numbers 3,6,10,15,21,etc, k*(k+1)/2, alternately on one line
and the other.  Those are the positions of all the horizontal steps,
ie. where dY=0.

X<Centred square numbers>X axis N=1,5,13,25,etc is the "centred square
numbers".  Those numbers are made by drawing concentric squares with an
extra point on each side each time.  The path here grows the same way,
adding one extra point to each of the four sides.

    *---*---*---*
    |           |
    | *---*---* |     count total "*"s for
    | |       | |     centred square numbers
    * | *---* | *
    | | |   | | |
    | * | * | * |
    | | |   | | |
    | | *---* | |
    * |       | *
    | *---*---* |
    |           |
    *---*---*---*

=head2 N Start

The default is to number points starting N=1 as shown above.  An optional
C<n_start> can give a different start, in the same pattern.  For example to
start at 0,

=cut

# math-image --path=AztecDiamondRings,n_start=0 --expression='i<=59?i:0' --output=numbers --size=50x10

=pod

    n_start => 0

                45 44
             46 28 27 43
          47 29 15 14 26 42
       48 30 16  6  5 13 25 41
    49 31 17  7  1  0  4 12 24 40
    50 32 18  8  2  3 11 23 39 59
       51 33 19  9 10 22 38 58
          52 34 20 21 37 57
             53 35 36 56
                54 55

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::AztecDiamondRings-E<gt>new ()>

=item C<$path = Math::PlanePath::AztecDiamondRings-E<gt>new (n_start =E<gt> $n)>

Create and return a new Aztec diamond spiral object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.

For C<$n < 1> the return is an empty list, it being considered the path
starts at 1.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return the point number for coordinates C<$x,$y>.  C<$x> and C<$y> are
each rounded to the nearest integer, which has the effect of treating each
point in the path as a square of side 1, so the entire plane is covered.

=item C<($n_lo, $n_hi) = $path-E<gt>rect_to_n_range ($x1,$y1, $x2,$y2)>

The returned range is exact, meaning C<$n_lo> and C<$n_hi> are the smallest
and biggest in the rectangle.

=back

=head1 FORMULAS

=head2 X,Y to N

The path makes lines in each quadrant.  The quadrant is determined by the
signs of X and Y, then the line in that quadrant is either d=X+Y or d=X-Y.
A quadratic in d gives a starting N for the line and Y (or X if desired) is
an offset from there,

    Y>=0 X>=0     d=X+Y  N=(2d+2)*d+1 + Y
    Y>=0 X<0      d=Y-X  N=2d^2       - Y
    Y<0  X>=0     d=X-Y  N=(2d+2)*d+1 + Y
    Y<0  X<0      d=X+Y  N=(2d+4)*d+2 - Y

For example

    Y=2 X=3       d=2+3=5      N=(2*5+2)*5+1  + 2  = 63
    Y=2 X=-1      d=2-(-1)=3   N=2*3*3        - 2  = 16
    Y=-1 X=4      d=4-(-1)=5   N=(2*5+2)*5+1  + -1 = 60
    Y=-2 X=-3     d=-3+(-2)=-5 N=(2*-5+4)*-5+2 - (-2) = 34

The two XE<gt>=0 cases are the same N formula and can be combined with an
abs,

    X>=0          d=X+abs(Y)   N=(2d+2)*d+1 + Y

This works because at Y=0 the last line of one ring joins up to the start of
the next.  For example N=11 to N=15,

    15             2
      \
       14          1
         \
          13   <- Y=0

       12         -1
      /
    11            -2

     ^
    X=0 1  2

=head2 Rectangle to N Range

Within each row N increases as X increases away from the Y axis, and within
each column similarly N increases as Y increases away from the X axis.  So
in a rectangle the maximum N is at one of the four corners of the rectangle.

              |
    x1,y2 M---|----M x2,y2
          |   |    |
       -------O---------
          |   |    |
          |   |    |
    x1,y1 M---|----M x1,y1
              |

For any two rows y1 and y2, the values in row y2 are all bigger than in y1
if y2E<gt>=-y1.  This is so even when y1 and y2 are on the same side of the
origin, ie. both positive or both negative.

For any two columns x1 and x2, the values in the part with YE<gt>=0 are all
bigger if x2E<gt>=-x1, or in the part of the columns with YE<lt>0 it's
x2E<gt>=-x1-1.  So the biggest corner is at

    max_y = (y2 >= -y1              ? y2 ? y1)
    max_x = (x2 >= -x1 - (max_y<0)  ? x2 : x1)

The difference in the X handling for Y positive or negative is due to the
quadrant ordering.  When YE<gt>=0, at X and -X the bigger N is the X
negative side, but when YE<lt>0 it's the X positive side.

A similar approach gives the minimum N in a rectangle.

    min_y = / y2 if y2 < 0, and set xbase=-1
            | y1 if y1 > 0, and set xbase=0
            \ 0 otherwise,  and set xbase=0

    min_x = / x2 if x2 < xbase
            | x1 if x1 > xbase
            \ xbase otherwise

The minimum row is Y=0, but if that's not in the rectangle then the y2 or y1
top or bottom edge is the minimum.  Then within any row the minimum N is at
xbase=0 if YE<lt>0 or xbase=-1 if YE<gt>=0.  If that xbase is not in range
then the x2 or x1 left or right edge is the minimum.

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
this path include

=over

L<http://oeis.org/A001844> (etc)

=back

    n_start=1 (the default)
      A001844    N on X axis, the centred squares 2k(k+1)+1

    n_start=0
      A046092    N on X axis, 4*triangular
      A139277    N on diagonal X=Y
      A023532    abs(dY), being 0 if N=k*(k+3)/2

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::DiamondSpiral>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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
