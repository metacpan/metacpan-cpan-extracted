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


package Math::PlanePath::DiamondSpiral;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 125;
use Math::PlanePath;
*_sqrtint = \&Math::PlanePath::_sqrtint;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'round_nearest';

# uncomment this to run the ### lines
#use Smart::Comments;

use constant xy_is_visited => 1;
use constant parameter_info_array =>
  [ Math::PlanePath::Base::Generic::parameter_info_nstart1() ];

sub x_negative_at_n {
  my ($self) = @_;
  return $self->n_start + 3;
}
sub y_negative_at_n {
  my ($self) = @_;
  return $self->n_start + 4;
}
use constant dx_minimum => -1;
use constant dx_maximum => 1;
use constant dy_minimum => -1;
use constant dy_maximum => 1;
use constant _UNDOCUMENTED__dxdy_list => (1,0,   # E  N=1 and other bottom
                                          1,1,   # NE N=6
                                          -1,1,  # NW N=2
                                          -1,-1, # SW N=3
                                          1,-1); # SE N=4
sub _UNDOCUMENTED__dxdy_list_at_n {
  my ($self) = @_;
  return $self->n_start + 5;
}
use constant absdx_minimum => 1;
use constant dsumxy_minimum => -2; # diagonals
use constant dsumxy_maximum => 2;
use constant ddiffxy_minimum => -2;
use constant ddiffxy_maximum => 2;
use constant dir_maximum_dxdy => (1,-1); # South-East

use constant turn_any_right => 0; # only left or straight


#------------------------------------------------------------------------------
sub new {
  my $self = shift->SUPER::new (@_);
  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }
  return $self;
}

# start cycle at the vertical downwards from x=1,y=0
# s = [ 0, 1,  2, 3 ]
# n = [ 2, 6, 14,26 ]
# n = 2*$s*$s - 2*$s + 2
# s = .5 + sqrt(.5*$n-.75)
#
# then top of the diamond at 2*$s - 1
# so n - (2*$s*$s - 2*$s + 2 + 2*$s - 1)
#    n - (2*$s*$s + 1)
#
# gives y=$s - n
# then x=$s-abs($y) on the right or x=-$s+abs($y) on the left
#
sub n_to_xy {
  my ($self, $n) = @_;
  #### n_to_xy: $n

  $n = $n - $self->{'n_start'};  # starting $n==0, and warn if $n==undef
  if ($n < 1) {
    if ($n < 0) { return; }
    return ($n, 0);
  }

  my $d = int ( (1 + _sqrtint(2*$n-1)) / 2 );
  #### $d
  #### d frac: ( (1 + _sqrtint(2*$n-1)) / 2 )
  #### base: 2*$d*$d - 2*$d + 2
  #### extra: 2*$d - 1
  #### sub: 2*$d*$d +1

  $n -= 2*$d*$d;
  ### rem from top: $n

  my $y = -abs($n) + $d;  # y=+$d at the top, down to y=-$d
  my $x = abs($y) - $d;  # 0 to $d on the right
  #### uncapped y: $y
  #### abs x: $x

  # cap for horiz at 5 to 6, 13 to 14 etc
  $d = -$d;
  if ($y < $d) { $y = $d; }

  return (($n >= 0 ? $x : -$x),  # negate if on the right
          $y);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  $x = round_nearest ($x);
  $y = round_nearest ($y);
  my $d = abs($x) + abs($y);

  # vertical along the y>=0 axis
  # s=0  n=1
  # s=1  n=3
  # s=2  n=9
  # s=3  n=19
  # s=4  n=33
  # n = 2*$d*$d + 1
  #
  my $n = 2*$d*$d;

  # then +/- $d to go to left or right x axis, and -/+ $y from there
  if ($x > 0) {
    ### right quad 1 and 4
    return $n - $d + $y + $self->{'n_start'};
  } else {
    # left quads 2 and 3
    return $n + $d - $y + $self->{'n_start'};
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
  ### DiamondSpiral rect_to_n_range(): "$x1,$y1, $x2,$y2"

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;

  my $min_x = ($x2 < 0   ? $x2
               : $x1 > 0 ? $x1
               : 0);
  my $min_y = ($y2 < 0   ? $y2
               : $y1 > 0 ? $y1
               : 0);

  my $max_x = ($x2 > -$x1 ? $x2 : $x1);
  my $max_y = ($y2 >= -$y1+($max_x<=0) ? $y2 : $y1);

  return ($self->xy_to_n($min_x,$min_y),
          $self->xy_to_n($max_x,$max_y));
}

1;
__END__


    #                         73                               6
    #                     74  51  72                           5
    #                 75  52  33  50  71                       4
    #             76  53  34  19  32  49  70                   3
    #         77  54  35  20   9  18  31  48  69               2
    #     78  55  36  21  10   3   8  17  30  47  68           1
    # 79  56  37  22  11   4   1   2   7  16  29  46  67   <- Y=0
    #     80  57  38  23  12   5   6  15  28  45  66          -1
    #         81  58  39  24  13  14  27  44  65  ...         -2
    #             82  59  40  25  26  43  64  89              -3
    #                 83  60  41  42  63  88                  -4
    #                     84  61  62  87                      -5
    #                         85  86                          -6
    #
    #                          ^
    # -6  -5  -4  -3  -2  -1  X=0  1   2   3   4   5   6


=for stopwords ie eg PlanePath Ryde Math-PlanePath OEIS

=head1 NAME

Math::PlanePath::DiamondSpiral -- integer points around a diamond shaped spiral

=head1 SYNOPSIS

 use Math::PlanePath::DiamondSpiral;
 my $path = Math::PlanePath::DiamondSpiral->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path makes a diamond shaped spiral.

                19                    3
              /    \
            20   9  18                2
          /    /   \   \
        21  10   3   8  17            1
      /    /   /   \  \   \
    22  11   4   1---2   7  16    <- Y=0
      \    \   \       /   /
        23  12   5---6  15  ...      -1
          \   \        /   /
            24  13--14  27           -2
              \        /
                25--26               -3

                 ^
    -3  -2  -1  X=0  1   2   3

This is not simply the C<SquareSpiral> rotated, it spirals around faster,
with side lengths following a pattern 1,1,1,1, 2,2,2,2, 3,3,3,3, etc, if the
flat kink at the bottom (like N=13 to N=14) is treated as part of the lower
right diagonal.

Going diagonally on the sides as done here is like cutting the corners of
the C<SquareSpiral>, which is how it gets around in fewer steps than the
C<SquareSpiral>.  See C<PentSpiralSkewed>, C<HexSpiralSkewed> and
C<HeptSpiralSkewed> for similar cutting just 3, 2 or 1 of the corners.

X<Centred square numbers>N=1,5,13,25,etc on the Y negative axis is the
"centred square numbers" 2*k*(k+1)+1.

=head2 N Start

The default is to number points starting N=1 as shown above.  An optional
C<n_start> can give a different start, with the same shape etc.  For example
to start at 0,

=cut

# math-image --path=DiamondSpiral,n_start=0 --all --output=numbers_dash --size=35x16

=pod

    n_start => 0         18
                       /   \  
                     19   8  17 
                   /   /   \   \  
                 20   9   2   7  16 
               /   /   /   \   \   \  
             21  10   3   0-- 1   6  15 
               \   \   \       /   /
                 22  11   4-- 5  14  ...
                   \   \       /   /
                     23  12--13  26 
                       \       / 
                         24--25 

X<Hexagonal numbers>N=0,1,6,15,28,etc on the X axis is the hexagonal numbers
k*(2k-1).  N=0,3,10,21,36,etc on the negative X axis is the hexagonal
numbers of the "second kind" k*(2k-1) for kE<lt>0.  Combining those two is
the triangular numbers 0,1,3,6,10,15,21,etc, k*(k+1)/2, on the X axis
alternately positive and negative.

X<Square numbers>N=0,2,8,18,etc on the Y axis is 2*squares, 2*Y^2.
N=0,4,12,24,etc on the negative Y axis is X<Pronic numbers>2*pronic,
2*Y*(Y+1).

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::DiamondSpiral-E<gt>new ()>

=item C<$path = Math::PlanePath::DiamondSpiral-E<gt>new (n_start =E<gt> $n)>

Create and return a new diamond spiral object.

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

=head2 Rectangle to N Range

Within each row N increases as X moves away from the Y axis, and within each
column similarly N increases as Y moves away from the X axis.  So in a
rectangle the maximum N is at one of the four corners.

              |
    x1,y2 M---|----M x2,y2
          |   |    |
       -------O---------
          |   |    |
          |   |    |
    x1,y1 M---|----M x1,y1
              |

For any two columns x1 and x2 with x1E<lt>x2, the values in column x2 are
all bigger if x2E<gt>-x1.  This is so even when x1 and x2 are on the same
side of the origin, ie. both positive or both negative.

For any two rows y1 and y2, the values in the part of the row with XE<gt>0
are bigger if y2E<gt>=-y1, and in the part of the row with XE<lt>=0 it's
y2E<gt>-y1, or equivalently y2E<gt>=-y1+1.  So the biggest corner is at

    max_x = (x2 > -x1             ? x2 : x1)
    max_y = (y2 >= -y1+(max_x<=0) ? y2 : y1)

The minimum is similar but a little simpler.  In any column the minimum is
at Y=0, and in any row the minimum is at X=0.  So at 0,0 if that's in the
rectangle, or the edge on the side nearest the origin when not.

    min_x = / if x2 < 0 then x2
            | if x1 > 0 then x1
            \ else           0

    min_y = / if y2 < 0 then y2
            | if y1 > 0 then y1
            \ else           0

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
this path include

=over

L<http://oeis.org/A010751> (etc)

=back

    n_start=1
      A130883    N on X axis, 2*n^2-n+1
      A058331    N on Y axis, 2*n^2 + 1
      A001105    N on column X=1, 2*n^2
      A084849    N on X negative axis, 2*n^2+n+1
      A001844    N on Y negative axis, centred squares 2*n^2+2n+1
      A215471    N with >=5 primes among its 8 neighbours
      A215468    sum 8 neighbours N

      A217015    N permutation points order SquareSpiral rotate -90,
                   value DiamondSpiral N at each
      A217296    inverse permutation

    n_start=0
      A010751    X coordinate, runs 1 inc, 2 dec, 3 inc, etc
      A053616    abs(Y), runs k to 0 to k
      A000384    N on X axis, hexagonal numbers
      A001105    N on Y axis, 2*n^2 (and cf similar A184636)
      A014105    N on X negative axis, second hexagonals
      A046092    N on Y negative axis, 2*pronic
      A003982    delta(abs(X)+abs(Y)), 1 when N on Y negative axis
                   which is where move "outward" to next ring

    n_start=-1
      A188551    N positions of turns, from N=1 up
      A188552      and which are primes

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::DiamondArms>,
L<Math::PlanePath::AztecDiamondRings>,
L<Math::PlanePath::SquareSpiral>,
L<Math::PlanePath::HexSpiralSkewed>,
L<Math::PlanePath::PyramidSides>,
L<Math::PlanePath::ToothpickSpiral>

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
