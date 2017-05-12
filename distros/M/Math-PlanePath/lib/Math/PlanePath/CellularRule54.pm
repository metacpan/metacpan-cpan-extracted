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

# math-image --path=CellularRule54 --all --scale=10
# math-image --path=CellularRule54 --all --output=numbers --size=132x50

package Math::PlanePath::CellularRule54;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 124;
use Math::PlanePath;
@ISA = ('Math::PlanePath');
*_divrem = \&Math::PlanePath::_divrem;
*_sqrtint = \&Math::PlanePath::_sqrtint;

use Math::PlanePath::Base::Generic
  'round_nearest';

# uncomment this to run the ### lines
#use Smart::Comments;


use constant parameter_info_array =>
  [ Math::PlanePath::Base::Generic::parameter_info_nstart1(),
  ];

use constant class_y_negative => 0;
use constant n_frac_discontinuity => .5;
sub x_negative_at_n {
  my ($self) = @_;
  return $self->n_start + 1;
}
use constant sumxy_minimum => 0;  # triangular X>=-Y so X+Y>=0
use constant diffxy_maximum => 0; # triangular X<=Y so X-Y<=0
use constant dx_maximum => 4;
use constant dy_minimum => 0;
use constant dy_maximum => 1;
use constant absdx_minimum => 1;
use constant dsumxy_maximum => 4;  # straight East dX=+4
use constant ddiffxy_maximum => 4; # straight East dX=+4
use constant dir_maximum_dxdy => (-1,0); # supremum, West and dY=+1 up


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new (@_);
  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }
  return $self;
}
#            left   add
# even  y=0    0     1
#         2    1     2
#         4    3     3
#         6    6     4
# left = y/2*(y/2+1)/2
#      = y*(y+2)/8   of 4-cell figures
# inverse y = -1 + sqrt(2 * $n + -1)
#
#            left   add
# odd   y=1    0     3
#         3    3     6
#         5    9     9
#         7   18    12
# left = 3*(y-1)/2*((y-1)/2+1)/2
#      = 3*(y-1)*(y+1)/8     of 4-cell figures
#
# nbase y even = y*(y+2)/8 + 3*((y+1)-1)*((y+1)+1)/8
#              = [ y*(y+2) + 3*y*(y+2) ] / 8
#              = y*(y+2)/2
# y=0  nbase=0
# y=2  nbase=4
# y=4  nbase=12
# y=6  nbase=24
#
# nbase y odd = 3*(y-1)*(y+1)/8  + (y+1)*(y+3)/8
#             = (y+1) * (3y-3 + y+3)/8
#             = (y+1)*4y/8
#             = y*(y+1)/2
# y=1  nbase=1
# y=3  nbase=6
# y=5  nbase=15
# y=7  nbase=28
# inverse y = -1/2 + sqrt(2 * $n + -7/4)
#           = sqrt(2n-7/4) - 1/2
#           = (2*sqrt(2n-7/4) - 1)/2
#           = (sqrt(4n-7)-1)/2
#
# dual
# d = [ 0, 1,  2,  3 ]
# N = [ 1, 5, 13, 25 ]
# N = (2 d^2 + 2 d + 1)
#   = ((2*$d + 2)*$d + 1)
# d = -1/2 + sqrt(1/2 * $n + -1/4)
#   = sqrt(1/2 * $n + -1/4) - 1/2
#   = [ 2*sqrt(1/2 * $n + -1/4) - 1 ] / 2
#   = [ sqrt(4/2 * $n + -4/4) - 1 ] / 2
#   = [ sqrt(2*$n - 1) - 1 ] / 2
#

sub n_to_xy {
  my ($self, $n) = @_;
  ### CellularRule54 n_to_xy(): $n

  $n = $n - $self->{'n_start'}; # to N=0 basis
  my $frac;
  {
    my $int = int($n);
    $frac = $n - $int;
    $n = $int;       # BigFloat int() gives BigInt, use that
    if (2*$frac >= 1) {  # $frac>=0.5 and BigInt friendly
      $frac -= 1;
      $n += 1;
    }
    # -0.5 <= $frac < 0.5
    ### assert: $frac >= -0.5
    ### assert: $frac < 0.5
  }

  if ($n < 0) {
    return;
  }

  # d is the two-row group number, d=2*y, where n belongs
  # start of the two-row group is nbase = 2 d^2 + 2 d starting from N=0 
  #
  my $d = int((_sqrtint(2*$n+1) - 1) / 2);
  $n -= (2*$d + 2)*$d;   # remainder within two-row
  ### $d
  ### remainder: $n
  if ($n <= $d) {
    # d+1 many points in the Y=0,2,4,6 etc even row, spaced 4*n apart
    $d *= 2;    # y=2*d
    return ($frac + 4*$n - $d,
            $d);
  } else {
    # 3*d many points in the Y=1,3,5,7 etc odd row, using 3 in 4 cells
    $n -= $d+1;    # remainder 0 upwards into odd row
    $d = 2*$d+1;   # y=2*d+1
    my ($q) = _divrem($n,3);
    return ($frac + $n + $q - $d,
            $d);
  }
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  $x = round_nearest ($x);
  $y = round_nearest ($y);
  ### CellularRule54 xy_to_n(): "$x,$y"

  if ($y < 0
      || $x < -$y
      || $x > $y) {
    return undef;
  }
  $x += $y;
  ### x centred: $x
  if ($y % 2) {
    ### odd row, 3 in 4 ...
    if (($x % 4) == 3) {
      return undef;
    }
    return $x - int($x/4) + $y*($y+1)/2 + $self->{'n_start'};
  } else {
    ## even row, sparse ...
    if ($x % 4) {
      return undef;
    }
    return $x/4 + $y*($y+2)/2 + $self->{'n_start'};
  }
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### CellularRule54 rect_to_n_range(): "$x1,$y1, $x2,$y2"

  ($x1,$y1, $x2,$y2) = _rect_for_V ($x1,$y1, $x2,$y2)
    or return (1,0); # rect outside pyramid

  my $zero = ($x1 * 0 * $y1 * $x2 * $y2);  # inherit bignum

  # nbase y even y*(y+2)/2
  # nbase y odd  y*(y+1)/2
  # y even end (y+1)*(y+2)/2
  # y odd end  (y+1)*(y+3)/2

  $y2 += 1;
  return (# even/odd left end
          $zero + $y1*($y1 + 2-($y1%2))/2 + $self->{'n_start'},

          # even/odd right end
          $zero + $y2*($y2 + 2-($y2%2))/2 + $self->{'n_start'} - 1);
}

# Return ($x1,$y1, $x2,$y2) which is the rectangle part chopped to the top
# row entirely within the pyramid V and the bottom row partly within.
#
sub _rect_for_V {
  my ($x1,$y1, $x2,$y2) = @_;
  ### _rect_for_V(): "$x1,$y1, $x2,$y2"

  $y1 = round_nearest ($y1);
  $y2 = round_nearest ($y2);
  if ($y1 > $y2) { ($y1,$y2) = ($y2,$y1); } # swap to y1<=y2

  unless ($y2 >= 0) {
    ### rect all negative, no N ...
    return;
  }
  unless ($y1 >= 0) {
    # increase y1 to zero, including negative infinity discarded
    $y1 = 0;
  }

  $x1 = round_nearest ($x1);
  $x2 = round_nearest ($x2);
  if ($x1 > $x2) { ($x1,$x2) = ($x2,$x1); } # swap to x1<=x2
  my $neg_y2 = -$y2;

  #     \        /
  #   y2 \      / +-----
  #       \    /  |
  #        \  /
  #         \/    x1
  #
  #        \        /
  #   ----+ \      /  y2
  #       |  \    /
  #           \  /
  #       x2   \/
  #
  if ($x1 > $y2            # off to the right
      || $x2 < $neg_y2) {  # off to the left
    ### rect all off to the left or right, no N
    return;
  }

  #     \        /  x2
  #      \   +------+ y2
  #       \  | /    |
  #        \ +------+
  #         \/
  #
  if ($x2 > $y2) {
    ### top-right beyond pyramid, reduce ...
    $x2 = $y2;
  }

  #
  #    x1  \        /
  # y2 +--------+  /  y2
  #    |     \  | /
  #    +--------+/
  #            \/
  #
  if ($x1 < $neg_y2) {
    ### top-left beyond pyramid, increase ...
    $x1 = $neg_y2;
  }

  #     \       | /
  #      \      |/
  #       \    /|       |
  #    y1  \  / +-------+
  #         \/  x1
  #
  #        \|       /
  #         \      /
  #         |\    /
  #  -------+ \  /   y1
  #        x2  \/
  #
  # in both of the following y1=x2 or y1=-x2 leaves y1<=y2 because have
  # already established some part of the rectangle is in the V shape
  #
  if ($x1 > $y1) {
    ### x1 off to the right, so y1 row is outside, increase y1 ...
    $y1 = $x1;

  } elsif ((my $neg_x2 = -$x2) > $y1) {
    ### x2 off to the left, so y1 row is outside, increase y1 ...
    $y1 = $neg_x2;
  }

  # values ordered
  ### assert: $x1 <= $x2
  ### assert: $y1 <= $y2

  # top row x1..x2 entirely within pyramid
  ### assert: $x1 >= -$y2
  ### assert: $x2 <= $y2

  # bottom row x1..x2 some part within pyramid
  ### assert: $x1 <= $y1
  ### assert: $x2 >= -$y1

  return ($x1,$y1, $x2,$y2);
}

1;
__END__

=for stopwords straight-ish Ryde Math-PlanePath ie hexagonals 18-gonal Xmax-Xmin Nleft Nright OEIS

=head1 NAME

Math::PlanePath::CellularRule54 -- cellular automaton points

=head1 SYNOPSIS

 use Math::PlanePath::CellularRule54;
 my $path = Math::PlanePath::CellularRule54->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

X<Wolfram, Stephen>This is the pattern of Stephen Wolfram's "rule 54"
cellular automaton

=over

L<http://mathworld.wolfram.com/Rule54.html>

=back

arranged as rows,

    29 30 31  . 32 33 34  . 35 36 37  . 38 39 40     7
       25  .  .  . 26  .  .  . 27  .  .  . 28        6
          16 17 18  . 19 20 21  . 22 23 24           5
             13  .  .  . 14  .  .  . 15              4
                 7  8  9  . 10 11 12                 3
                    5  .  .  .  6                    2
                       2  3  4                       1
                          1                      <- Y=0

    -7 -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6  7

The initial figure N=1,2,3,4 repeats in two-row groups with 1 cell gap
between figures.  Each two-row group has one extra figure, for a step of 4
more points than the previous two-row.

X<Hexagonal numbers>The rightmost N on the even rows Y=0,2,4,6 etc is the
hexagonal numbers N=1,6,15,28, etc k*(2k-1).  The hexagonal numbers of the
"second kind" 1, 3, 10, 21, 36, etc j*(2j+1) are a steep sloping line
upwards in the middle too.  Those two taken together are the
X<Triangular numbers>triangular numbers 1,3,6,10,15 etc, k*(k+1)/2.

The 18-gonal numbers 18,51,100,etc are the vertical line at X=-3 on every
fourth row Y=5,9,13,etc.

=head2 Row Ranges

The left end of each row is

    Nleft = Y*(Y+2)/2 + 1     if Y even
            Y*(Y+1)/2 + 1     if Y odd

The right end is

    Nright = (Y+1)*(Y+2)/2    if Y even
             (Y+1)*(Y+3)/2    if Y odd

           = Nleft(Y+1) - 1   ie. 1 before next Nleft

The row width Xmax-Xmin is 2*Y but with the gaps the number of visited
points in a row is less than that, being either about 1/4 or 3/4 of the
width on even or odd rows.

    rowpoints = Y/2 + 1        if Y even
                3*(Y+1)/2      if Y odd

For any Y of course the Nleft to Nright difference is the number of points
in the row too

    rowpoints = Nright - Nleft + 1

=head2 N Start

The default is to number points starting N=1 as shown above.  An optional
C<n_start> can give a different start, in the same pattern.  For example to
start at 0,

=cut

# math-image --path=CellularRule54,n_start=0 --all --output=numbers --size=75x6

=pod

    n_start => 0

    15 16 17    18 19 20    21 22 23           5 
       12          13          14              4 
           6  7  8     9 10 11                 3 
              4           5                    2 
                 1  2  3                       1 
                    0                      <- Y=0

    -5 -4 -3 -2 -1 X=0 1  2  3  4  5

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::CellularRule54-E<gt>new ()>

=item C<$path = Math::PlanePath::CellularRule54-E<gt>new (n_start =E<gt> $n)>

Create and return a new path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return the point number for coordinates C<$x,$y>.  C<$x> and C<$y> are each
rounded to the nearest integer, which has the effect of treating each cell
as a square of side 1.  If C<$x,$y> is outside the pyramid or on a skipped
cell the return is C<undef>.

=back

=head1 OEIS

This pattern is in Sloane's Online Encyclopedia of Integer Sequences in a
couple of forms,

=over

L<http://oeis.org/A118108> (etc)

=back

    A118108    whole-row used cells as bits of a bignum
    A118109    1/0 used and unused cells across rows

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::CellularRule>,
L<Math::PlanePath::CellularRule57>,
L<Math::PlanePath::CellularRule190>,
L<Math::PlanePath::PyramidRows>

L<Cellular::Automata::Wolfram>

L<http://mathworld.wolfram.com/Rule54.html>

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
