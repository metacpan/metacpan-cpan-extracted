# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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


# cf Matthew Szudzik ElegantPairing.pdf going inwardly.
#
#   5 | 25--...
#     |
#   4 | 16--17--18--19  24
#     |                  |
#   3 |  9--10--11  15  23
#     |              |   |
#   2 |  4-- 5   8  14  22
#     |          |   |   |
#   1 |  1   4   7  13  21
#     |      |   |   |   |
# Y=0 |  0   2   6  12  20
#     +---------------------
#      X=0   1   2   3   4
#
# cf A185728 where diagonal is last in each gnomon
#    A185725 gnomon sides alternately starting from ends
#    A185726 gnomon sides alternately starting from diagonal
#
# corner going alternately up and down
#    A081344,A194280 by diagonals
#    A081345 X axis, A081346 Y axis
#
# corner alternately up and down, starting with 3-wide
#   A080335  N on diagonal
#   A081347  N on axis
#   A081348  N on axis
#
# cf A004120 ??
#

package Math::PlanePath::Corner;
use 5.004;
use strict;
use List::Util 'min';

use vars '$VERSION', '@ISA';
$VERSION = 125;
use Math::PlanePath;
*_sqrtint = \&Math::PlanePath::_sqrtint;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'round_nearest';

# uncomment this to run the ### lines
# use Smart::Comments;


use constant class_x_negative => 0;
use constant class_y_negative => 0;
use constant n_frac_discontinuity => .5;
*xy_is_visited = \&Math::PlanePath::Base::Generic::xy_is_visited_quad1;

use Math::PlanePath::SquareSpiral;
*parameter_info_array = \&Math::PlanePath::SquareSpiral::parameter_info_array;

use constant dx_maximum => 1;
use constant dy_minimum => -1;

# dSum east  dX=1,dY=0  for dSum=+1
#      south dX=0,dY=-1 for dSum=-1
# gnomon up to start of next gnomon is
#    X=wider+k,Y=0 to X=0,Y=k+1
#    dSum = 0-(wider+k) + (k+1)-0
#         = -wider-k + k + 1
#         = 1-wider
sub dsumxy_minimum {
  my ($self) = @_;
  return min(-1, 1-$self->{'wider'});
}
use constant dsumxy_maximum => 1;  # East along top

# dDiffXY east  dX=1,dY=0  for dDiffXY=1-0    = 1
#         south dX=0,dY=-1 for dDiffXY=0-(-1) = 1
# gnomon up to start of next gnomon is
#    X=wider+k,Y=0 to X=0,Y=k+1
#    dDiffXY = 0-(wider+k) - ((k+1)-0)
#            = -wider - 2*k - 1  unbounded negative
use constant ddiffxy_maximum => 1; # East along top

# use constant dir_minimum_dxdy => (1,0); # East  at N=2
use constant dir_maximum_dxdy => (0,-1); # South at N=3

sub turn_any_left {
  my ($self) = @_;
  return ($self->{'wider'} != 0);  # wider=0 no left, right or straight always
}
sub _UNDOCUMENTED__turn_any_left_at_n {
  my ($self) = @_;
  return ($self->{'wider'} ? $self->n_start + $self->{'wider'}
          : undef);   # wider=0 no left
}
sub _UNDOCUMENTED__turn_any_right_at_n {
  my ($self) = @_;
  return $self->n_start + $self->{'wider'} + 1;
}


#------------------------------------------------------------------------------

# same as PyramidSides, just 45 degress around

sub new {
  my $self = shift->SUPER::new (@_);
  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }
  $self->{'wider'} ||= 0;  # default
  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### Corner n_to_xy: $n

  # adjust to N=1 at origin X=0,Y=0
  $n = $n - $self->{'n_start'} + 1;

  # comparing $n<0.5, but done in integers for the benefit of Math::BigInt
  if (2*$n < 1) {
    return;
  }

  my $wider = $self->{'wider'};

  # wider==0
  #   vertical at X=0 has N=1, 2, 5, 10, 17, 26
  #   but start 0.5 back so at X=-0.5 have N=0.5, 1.5, 4.5, 9.5, 16.5, 25.5
  #   N = (Y^2 + 1/2)
  #   Y = floor sqrt(N - 1/2)
  #     = floor sqrt(4*N - 2)/2   staying in integers for the sqrt()
  #
  # wider==1
  #   0.5 back so at X=-0.5 have N=0.5, 2.5, 6.5, 12.5
  #   N = (Y^2 + Y + 1/2)
  #   Y = floor -1/2 + sqrt(N - 1/4)
  #     = floor (-1 + sqrt(4*N - 1))/2
  #
  # wider==2
  #   0.5 back so at X=-0.5 have N=0.5, 3.5, 8.5, 15.5
  #   N = (Y^2 + 2 Y + 1/2)
  #   Y = floor -1 + sqrt(N + 1/2)
  #     = floor (-2 + sqrt(4*N + 2))/2
  #
  # wider==3
  #   0.5 back so at X=-0.5 have N=0.5, 4.5, 10.5, 18.5
  #   N = (Y^2 + 3 Y + 1/2)
  #   Y = floor -3/2 + sqrt(N + 7/4)
  #     = floor (-3 + sqrt(4*N + 7))/2
  #
  # 0,1,4,9
  # my $y = int((sqrt(4*$n + -1) - $wider) / 2);
  # ### y frac: (sqrt(4*$n + -1) - $wider) / 2

  my $y = int((_sqrtint(4*$n + $wider*$wider - 2) - $wider) / 2);
  ### y frac: (sqrt(int(4*$n) + $wider*$wider - 2) - $wider) / 2
  ### $y

  # diagonal at X=Y has N=1, 3, 7, 13, 21
  # N = ((Y + 1)*Y + (Y+1)*wider + 1)
  #   = ((Y + 1 + wider)*Y + wider + 1)
  # so subtract that leaving N negative on the horizontal part, or positive
  # for the downward vertical part
  #
  $n -= $y*($y+1+$wider) + $wider + 1;
  ### corner n: $y*($y+1+$wider) + $wider + 1
  ### rem: $n
  ### assert: $n!=$n || $n >= -($y+$wider+0.5)
  # ### assert: $n <= ($y+0.5)

  if ($n < 0) {
    # top horizontal
    return ($n + $y+$wider,
            $y);
  } else {
    # right vertical
    return ($y+$wider,
            -$n + $y);
  }
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### Corner xy_to_n(): "$x,$y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);
  if ($x < 0 || $y < 0) {
    return undef;
  }

  my $wider = $self->{'wider'};
  my $xw = $x - $wider;
  if ($y >= $xw) {
    ### top edge, N left is: $y*$y + $wider*$y + 1
    return ($y*$y + $wider*$y      # Y axis N value
            + $x                   # plus X offset across
            + $self->{'n_start'});
  } else {
    ### right vertical, N diag is: $xw*$xw + $xw*$wider
    ### $xw
    # Ndiag = Nleft + Y+w
    # N = xw*xw + w*xw + 1 + xw+w + (xw - y)
    #   = xw*xw + w*xw + 1 + xw+w + xw - y
    #   = xw*xw + xw*(w+2) + 1 + w - y
    #   = xw*(xw + w+2) + w+1 - y
    return ($xw*($xw+$wider+2) + $wider
            - $y
            +  $self->{'n_start'});
  }
}

# exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### Corner rect_to_n_range(): "$x1,$y1, $x2,$y2"

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);
  if ($x1 > $x2) { ($x1,$x2) = ($x2,$x1); }
  if ($y1 > $y2) { ($y1,$y2) = ($y2,$y1); }

  if ($y2 < 0 || $x2 < 0) {
    return (1, 0); # rect all negative, no N
  }

  if ($x1 < 0) { $x1 *= 0; }   # "*=" to preserve bigint x1 or y1
  if ($y1 < 0) { $y1 *= 0; }

  my $wider = $self->{'wider'};
  my $ylo = $y1;
  my $xw = $x1 - $wider;

  if ($y1 <= $xw) {
    # left column is partly or wholly below X=Y diagonal
    #
    # make x1,y1 the min pos
    $y1 = ($y2 < $xw

           # wholly below diag, min "*" is at top y2 of the x1 column
           #
           # |        /
           # |       /
           # |      / *------+  y2
           # |     /  |      |
           # |    /   +------+  y1
           # |   /   x1     x2
           # +------------------
           #    ^.....^
           #    wider  xw
           #
           ? $y2

           # only partly below diag, min "*" is the X=Y+wider diagonal at x1
           #
           #            /
           # |      +------+  y2
           # |      | /    |
           # |      |/     |
           # |      *      |
           # |     /|      |
           # |    / +------+  y1
           # |   /  x1     x2
           # +------------------
           #    ^...^xw
           #    wider
           #
           : $xw);
  }

  if ($y2 <= $x2 - $wider) {
    # right column entirely at or below X=Y+wider diagonal so max is at the
    # ylo bottom end of the column
    #
    # |          /
    # |       --/---+  y2
    # |      | /    |
    # |      |/     |
    # |      /      |
    # |     /|      |
    # |    / +------+  ylo
    # |   /         x2
    # +------------------
    #    ^
    #    wider
    #
    $y2 = $ylo;   # x2,y2 now the max pos
  }

  ### min xy: "$x1,$y1"
  ### max xy: "$x2,$y2"
  return ($self->xy_to_n ($x1,$y1),
          $self->xy_to_n ($x2,$y2));
}

#------------------------------------------------------------------------------

sub _NOTDOCUMENTED_n_to_figure_boundary {
  my ($self, $n) = @_;
  ### _NOTDOCUMENTED_n_to_figure_boundary(): $n

  # adjust to N=1 at origin X=0,Y=0
  $n = $n - $self->{'n_start'} + 1;

  if ($n < 1) {
    return undef;
  }

  my $wider = $self->{'wider'};
  if ($n <= $wider) {
    # single block row
    # +---+-----+----+
    # | 1 | ... | $n |  boundary = 2*N + 2
    # +---+-----+----+
    return 2*$n + 2;
  }

  my $d = int((_sqrtint(4*$n + $wider*$wider - 2) - $wider) / 2);
  ### $d
  ### $wider

  if ($n > $d*($d+1+$wider) + $wider) {
    $wider++;
    ### increment for +2 after turn ...
  }
  return 4*$d + 2*$wider + 2;
}

#------------------------------------------------------------------------------
1;
__END__

=for stopwords pronic PlanePath Ryde Math-PlanePath ie OEIS gnomon Nstart

=head1 NAME

Math::PlanePath::Corner -- points shaped around in a corner

=head1 SYNOPSIS

 use Math::PlanePath::Corner;
 my $path = Math::PlanePath::Corner->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path puts points in layers working outwards from the corner of the
first quadrant.

=cut

# math-image --path=Corner --output=numbers_dash --all --size=30x14

=pod

      5 | 26--...
        |
      4 | 17--18--19--20--21
        |                  |
      3 | 10--11--12--13  22
        |              |   |
      2 |  5-- 6-- 7  14  23
        |          |   |   |
      1 |  2-- 3   8  15  24
        |  |   |   |   |   |
    Y=0 |  1   4   9  16  25
        +---------------------
         X=0   1   2   3   4

X<Gnomon>X<Square numbers>The horizontal 1,4,9,16,etc along Y=0 is the
perfect squares.  This is since each further row/column "gnomon" added to a
square makes a one-bigger square,

                            10 11 12 13
               5  6  7       5  6  7 14
    2  3       2  3  8       2  3  8 15
    1  4       1  4  9       1  4  9 16

     2x2        3x3           4x4

N=2,6,12,20,etc on the diagonal X=Y-1 up from X=0,Y=1 is the
X<Pronic numbers>pronic numbers k*(k+1) which are half way between the
squares.

Each gnomon is 2 longer than the previous.  This is similar to the
C<PyramidRows>, C<PyramidSides> and C<SacksSpiral> paths.  The C<Corner> and
the C<PyramidSides> are the same but C<PyramidSides> is stretched to two
quadrants instead of one for the C<Corner> here.

=head2 Wider

An optional C<wider =E<gt> $integer> makes the path wider horizontally,
becoming a rectangle.  For example

=cut

# math-image --path=Corner,wider=3 --all --output=numbers_dash --size=38x12

=pod

    wider => 3

     4  |  29--30--31--...
        |
     3  |  19--20--21--22--23--24--25
        |                           |
     2  |  11--12--13--14--15--16  26
        |                       |   |
     1  |   5---6---7---8---9  17  27
        |                   |   |   |
    Y=0 |   1---2---3---4  10  18  28
        |
         -----------------------------
            ^
           X=0  1   2   3   4   5   6

Each gnomon has the horizontal part C<wider> many steps longer.  Each gnomon
is still 2 longer than the previous since this widening is a constant amount
in each.

=head2 N Start

The default is to number points starting N=1 as shown above.  An optional
C<n_start> can give a different start with the same shape etc.  For example
to start at 0,

=cut

# math-image --path=Corner,n_start=0 --all --output=numbers --size=35x5

=pod

    n_start => 0

      5  |  25 ...
      4  |  16 17 18 19 20
      3  |   9 10 11 12 21
      2  |   4  5  6 13 22
      1  |   1  2  7 14 23
    Y=0  |   0  3  8 15 24
          -----------------
           X=0   1   2   3

In Nstart=0 the squares are on the Y axis and the pronic numbers are on the
X=Y leading diagonal.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::Corner-E<gt>new ()>

=item C<$path = Math::PlanePath::Corner-E<gt>new (wider =E<gt> $w, n_start =E<gt> $n)>

Create and return a new path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.

For C<$n < n_start()-0.5> the return is an empty list.  There's an extra 0.5
before Nstart, but nothing further before there.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return the point number for coordinates C<$x,$y>.

C<$x> and C<$y> are each rounded to the nearest integer, which has the
effect of treating each point as a square of side 1, so the quadrant x>=-0.5
and y>=-0.5 is entirely covered.

=item C<($n_lo, $n_hi) = $path-E<gt>rect_to_n_range ($x1,$y1, $x2,$y2)>

The returned range is exact, meaning C<$n_lo> and C<$n_hi> are the smallest
and biggest in the rectangle.

=back

=head1 FORMULAS

=head2 N to X,Y

Counting d=0 for the first L-shaped gnomon at Y=0, then the start of the
gnomon is

    StartN(d) = d^2 + 1 = 1,2,5,10,17,etc

The current C<n_to_xy()> code extends to the left by an extra 0.5 for
fractional N, so for example N=9.5 is at X=-0.5,Y=3.  With this the starting
N for each gnomon d is

    StartNfrac(d) = d^2 + 0.5

Inverting gives the gnomon d number for an N,

    d = floor(sqrt(N - 0.5))

Subtracting the gnomon start gives an offset into that gnomon

    OffStart = N - StartNfrac(d)

The corner point 1,3,7,13,etc where the gnomon turns down is at d+0.5 into
that remainder, and it's convenient to subtract that so negative for the
horizontal and positive for the vertical,

    Off = OffStart - (d+0.5)
        = N - (d*(d+1) + 1)

Then the X,Y coordinates are

    if (Off < 0)  then  X=d+Off, Y=d
    if (Off >= 0) then  X=d,     Y=d-Off

=head2 X,Y to N

For a given X,Y the bigger of X or Y determines the d gnomon.

If YE<gt>=X then X,Y is on the horizontal part.  At X=0 have N=StartN(d) per
the Start(N) formula above, and any further X is an offset from there.

    if Y >= X then
      d=Y
      N = StartN(d) + X
        = Y^2 + 1 + X

Otherwise if YE<lt>X then X,Y is on the vertical part.  At Y=0 N is the last
point on the gnomon, and one back from the start of the following gnomon,

    if Y <= X then
      d=X
      LastN(d) = StartN(d+1) - 1
               = (d+1)^2
      N = LastN(d) - Y
        = (X+1)^2 - Y

=head2 Rectangle N Range

For C<rect_to_n_range()>, in each row increasing X is increasing N so the
smallest N is in the leftmost column and the biggest N in the rightmost
column.

    |
    |  ------>  N increasing
    |
     -----------------------

Going up a column, N values are increasing away from the X=Y diagonal up or
down, and all N values above X=Y are bigger than the ones below.

    |    ^  N increasing up from X=Y diagonal
    |    |
    |    |/
    |    /
    |   /|
    |  / |  N increasing down from X=Y diagonal
    | /  v
    |/
     -----------------------

This means the biggest N is the top right corner if that corner is YE<gt>=X,
otherwise the bottom right corner.

                                           max N at top right
    |      /                          | --+     if corner Y>=X
    |     / --+                       |   | /
    |    /    |                       |   |/
    |   /     |                       |   |
    |  /  ----v                       |  /|
    | /     max N at bottom right     | --+
    |/        if corner Y<=X          |/
     ----------                        -------

For the smallest N, if the bottom left corner has YE<gt>X then it's in the
"increasing" part and that bottom left corner is the smallest N.  Otherwise
YE<lt>=X means some of the "decreasing" part is covered and the smallest N
is at Y=min(X,Ymax), ie. either the Y=X diagonal if it's in the rectangle or
the top right corner otherwise.

    |      /
    | |   /
    | |  /  min N at bottom left
    | +----  if corner Y>X
    |  /
    | /
    |/
     ----------

    |      /                           |      /
    |   | /                            |     /
    |   |/  min N at X=Y               |    /
    |   *    if diagonal crossed       |   / +-- min N at top left
    |  /|                              |  /  |    if corner Y<X
    | / +-----                         | /   |
    |/                                 |/    
     ----------                         ----------

    min N at Xmin,Ymin            if Ymin >= Xmin
             Xmin,min(Xmin,Ymax)  if Ymin <= Xmin


=head1 OEIS

This path is in Sloane's Online Encyclopedia of Integer Sequences as,

=over

L<http://oeis.org/A196199> (etc)

=back

    wider=0, n_start=1 (the defaults)
      A213088    X+Y sum
      A196199    X-Y diff, being runs -n to +n
      A053615    abs(X-Y), runs n to 0 to n, distance to next pronic

      A000290    N on X axis, perfect squares starting from 1
      A002522    N on Y axis, Y^2+1
      A002061    N on X=Y diagonal, extra initial 1
      A004201    N on and below X=Y diagonal, so X>=Y

      A020703    permutation N at transpose Y,X
      A060734    permutation N by diagonals up from X axis
      A064790     inverse
      A060736    permutation N by diagonals down from Y axis
      A064788     inverse

      A027709    boundary length of N unit squares
      A078633    grid sticks of N points

    n_start=0
      A000196    max(X,Y), being floor(sqrt(N))

      A005563    N on X axis, n*(n+2)
      A000290    N on Y axis, perfect squares
      A002378    N on X=Y diagonal, pronic numbers

    n_start=2
      A059100    N on Y axis, Y^2+2
      A014206    N on X=Y diagonal, pronic+2

    wider=1
      A053188    abs(X-Y), dist to nearest square, extra initial 0
    wider=1, n_start=0
      A002378    N on Y axis, pronic numbers
      A005563    N on X=Y diagonal, n*(n+2)
    wider=1, n_start=2
      A014206    N on Y axis, pronic+2

    wider=2, n_start=0
      A005563    N on Y axis, (Y+1)^2-1
      A028552    N on X=Y diagonal, k*(k+3)

    wider=3, n_start=0
      A028552    N on Y axis, k*(k+3)

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::PyramidSides>,
L<Math::PlanePath::PyramidRows>,
L<Math::PlanePath::SacksSpiral>,
L<Math::PlanePath::Diagonals>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
