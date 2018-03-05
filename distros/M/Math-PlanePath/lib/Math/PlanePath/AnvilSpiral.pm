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


# math-image --path=AnvilSpiral --all --output=numbers_dash
# math-image --path=AnvilSpiral,wider=3 --all --output=numbers_dash

package Math::PlanePath::AnvilSpiral;
use 5.004;
use strict;
#use List::Util 'min','max';
*min = \&Math::PlanePath::_min;
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 126;
use Math::PlanePath;
@ISA = ('Math::PlanePath');
*_sqrtint = \&Math::PlanePath::_sqrtint;

use Math::PlanePath::Base::Generic
  'round_nearest';


# pentagonal N = (3k-1)*k/2
# preceding
# Np = (3k-1)*k/2 - 1
#    = (3k^2 - k - 2)/2
#    = (3k+2)(k-1)/2
#


# parameters "wider","n_start"
use Math::PlanePath::SquareSpiral;
*parameter_info_array
  = \&Math::PlanePath::SquareSpiral::parameter_info_array;
use constant xy_is_visited => 1;

use constant dx_minimum => -1;
use constant dx_maximum => 1;
use constant dy_minimum => -1;
use constant dy_maximum => 1;
use constant _UNDOCUMENTED__dxdy_list => (1,0,   # E       # no N,S
                           1,1,   # NE
                           -1,1,  # NW
                           -1,0,  # W
                           -1,-1, # SW
                           1,-1); # SE
# last NW at lower right
#     2w+4 ------- w+1
#       \          /
#        *  0---- w  *
#       /             \
#     2w+6 ---------- 3w+10    w=3; 1+3*w+10=20
#
sub x_negative_at_n {
  my ($self) = @_;
  return $self->n_start + ($self->{'wider'} ? 0 : 3);
}
sub y_negative_at_n {
  my ($self) = @_;
  return $self->n_start + 2*$self->{'wider'} + 6;
}
sub _UNDOCUMENTED__dxdy_list_at_n {
  my ($self) = @_;
  return $self->n_start + 3*$self->{'wider'} + 10;
}

use constant absdx_minimum => 1;  # abs(dX)=1 always
use constant dsumxy_minimum => -2; # diagonals
use constant dsumxy_maximum => 2;
use constant ddiffxy_minimum => -2;
use constant ddiffxy_maximum => 2;
use constant dir_maximum_dxdy => (1,-1); # South-East

sub _UNDOCUMENTED__turn_any_left_at_n {
  my ($self) = @_;
  # left turn at w when w!=0 or at w+1 when w==0
  return $self->n_start + ($self->{'wider'} || 1);
}
sub _UNDOCUMENTED__turn_any_right_at_n {
  my ($self) = @_;
  return $self->n_start + 2*$self->{'wider'} + 5;
}


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new (@_);

  # parameters
  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }
  $self->{'wider'} ||= 0;  # default

  return $self;
}

# [1,2,3,4],[1,12,35,70]   # horizontal
# N = (6 d^2 - 7 d + 2)
#   = (6*$d**2 - 7*$d + 2)
#   = ((6*$d - 7)*$d + 2)
# d = 7/12 + sqrt(1/6 * $n + 1/144)
#   = (7 + 12*sqrt(1/6 * $n + 1/144))/12
#   = (7 + sqrt(144/6*$n + 1))/12
#   = (7 + sqrt(24*$n + 1))/12
#
# wider=1
# [1,2,3,4],[1+1,12+1+2,35+1+2+2,70+1+2+2+2]
# N = (6 d^2 - 5 d + 1)
# d = 5/12 + sqrt(1/6 * $n + 1/144)
#
# wider=2
# [1,2,3,4],[1+2,12+2+4,35+2+4+4,70+2+4+4+4]
# N = (6 d^2 - 3 d)
# d = 3/12 + sqrt(1/6 * $n + 9/144)
#
# wider=3
# [1,2,3,4],[1+3,12+3+6,35+3+6+6,70+3+6+6+6]
# N = (6 d^2 - d - 1)
# d = 1/12 + sqrt(1/6 * $n + 25/144)
#
# wider=4
# [1,2,3,4],[1+4,12+4+8,35+4+8+8,70+4+8+8+8]
# N = (6 d^2 + d - 2)
# d = -1/12 + sqrt(1/6 * $n + 49/144)         # 49=7*7=(2w-1)*(2w-1)
#
# in general
# N = (6 d^2 - (7-2w) d + 2-w)
#   = (6d - (7-2w)) d + 2-w
#   = (6d - 7 + 2w))*d + 2-w
# d = (7-2w)/12 + sqrt(1/6 * $n + (w-1)^2/144)
#   = [ 7-2w + 12*sqrt(1/6 * $n + (w-1)^2/144) ] / 12
#   = [ 7-2w + sqrt(144/6*$n + (w-1)^2) ] / 12
#   = [ 7-2w + sqrt(24*$n + (w-1)^2) ] / 12



sub n_to_xy {
  my ($self, $n) = @_;
  ### AnvilSpiral n_to_xy(): $n

  $n = $n - $self->{'n_start'};  # to N=0 basis, warning if $n==undef
  if ($n < 0) { return; }
  my $w = $self->{'wider'};
  my $w_right = int($w/2);
  my $w_left = $w - $w_right;
  ### $w
  ### $w_left
  ### $w_right

  if ($n <= $w) {
    ### centre horizontal
    return ($n - $w_left,  # N=0 at $w_left
            0);
  }

  my $d = int((_sqrtint(24*($n+1) + (2*$w-1)**2) + 7-2*$w) / 12);
  ### ($n+1)
  ### $d
  ### d frac: ((sqrt(int(24*($n+1)) + (2*$w-1)**2) + 7-2*$w) / 12)
  ### d sqrt add: ($w-1)*($w-1)
  ### d const part: 7-2*$w

  $n -= (6*$d - 7 + 2*$w)*$d + 2-$w;
  ### base: (6*$d - 7 + 2*$w)*$d + 2-$w
  ### remainder: $n

  if ($n <= 5*$d+$w-2) {
    if ($n+1 <= $d) {
      ### upper right slope ...
      return ($n + $d + $w_right,
              $n+1);
    } else {
      ### top ...
      return (-$n + 3*$d + $w_right - 2,
              $d);
    }
  }

  $n -= 7*$d + $w - 2;
  if ($n <= 0) {
    ### left slopes: $n
    return (-abs($n+$d) - $d - $w_left,
            -$n - $d);
  }

  $n -= 4*$d + $w;
  if ($n < 0) {
    ### bottom ...
    return ($n + 2*$d + $w_right,
            -$d);
  } else {
    ### right lower ...
    return (-$n + 2*$d + $w_right,
            $n - $d);
  }
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### AnvilSpiral xy_to_1 n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);

  my $w = $self->{'wider'};
  my $w_right = int($w/2);
  my $w_left = $w - $w_right;
  ### $w
  ### $w_left
  ### $w_right

  my $abs_y = abs($y);
  if ($x-$w_right >= 2*$abs_y) {
    ### right slopes: "d=".($x-$w_right - $abs_y)
    my $d = $x-$w_right - $abs_y;  # zero based
    return ((6*$d + 5 + 2*$w)*$d + $w
            + $y
            + $self->{'n_start'});
  }

  if ($x+$w_left < -2*$abs_y) {
    ### left slopes: "d=".($x+$w_left + $abs_y)
    my $d = $x+$w_left + $abs_y;  # negative, and zero based
    return ((6*$d + 1 - 2*$w)*$d
            - $y
            + $self->{'n_start'});
  }

  if ($y > 0) {
    ### top horizontal ...
    return ((6*$y - 4 + 2*$w)*$y - $w
            + $w_right-$x
            + $self->{'n_start'});
  } else {
    ### bottom horizontal ...
    # y negative
    return ((6*$y - 2 - 2*$w)*$y
            + $x+$w_left
            + $self->{'n_start'});
  }
}

# uncomment this to run the ### lines
#use Smart::Comments;

#      ...-78-77-76-75-74
#                     /
# 43-42-41-40-39-38 73
#               /  /
# 17-16-15-14 37 72
#         /  /  /
# -3--2 13 36 71
#   /  /  /  /
#  1 12 35 70
#
# column X=2, dmin decreasing until Y=1=floor(x/2)
# column X=3, dmin decreasing until Y=2=ceil(x/2)
# so x1 - min(y2,int((x1+1)/2))
#
#
# column Xmax=2, dmax increasing down until x2-y1
#
# horizontal Y>=0 N increases left and right of X=Y*3/2
#    so candidate max at top-left x1,y2 or top-right x2,y2
#
# horizontal Y<0 N increases left and right of X=-Y*3/2
#    so candidate max at bottom-left x1,y1 or bottom-right x2,y1
#
# vertical Y>=0 N increases above and below Y=ceil(X/2)
#    so candidate max at top-right or bottom-right, or Y=0
#
# vertical Y<0 N increases above and below Y=ceil(X/2)
#    so candidate max at top-right or bottom-right, or Y=0
#
  # int(($y2+1)/2), $y2
  # int(($y1+1)/2), $y1
  # 
  # my @corners = ($self->xy_to_n($x1,$y1),
  #                $self->xy_to_n($x2,$y1),
  #                $self->xy_to_n($x1,$y2),
  #                $self->xy_to_n($x2,$y2));
  # return (($x_zero && $y_zero ? 1 : min (@corners)),
  #         max (@corners,
  #               ($y_zero ? ($self->xy_to_n($x1,0),
  #                           $self->xy_to_n($x2,0)) : ())));




# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### AnvilSpiral rect_to_n_range(): "$x1,$y1  $x2,$y2"

  my $w = $self->{'wider'};
  my $w_right = int($w/2);
  my $w_left = $w - $w_right;

  $x1 = round_nearest($x1);
  $x2 = round_nearest($x2);
  $y1 = round_nearest($y1);
  $y2 = round_nearest($y2);

  my $x_zero = (($x1<0) != ($x2<0));
  my $y_zero = (($y1<0) != ($y2<0));
  ### $x_zero
  ### $y_zero

  $x1 += $w_left;
  $x2 += $w_left;

  if ($x1 < 0) { $x1 = $w-$x1; }
  if ($x2 < 0) { $x2 = $w-$x2; }
  $y1 = abs($y1);
  $y2 = abs($y2);

  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;

  if ($x_zero) { $x1 = 0; }
  if ($y_zero) { $y1 = 0; }

  ### abs: "$x1,$y1  $x2,$y2"
  ### d1 slope max y: int(($x1+1)/2)
  ### d1 slope: $x1 - min($y2,int(($x1+1)/2))

  #   --------*
  #          /
  #         /
  #        *   <-y=0
  # x=0....w
  #
  # d=x-w-y on the slope
  # d=y     on the top horizontal
  #
  my $d1 = min ($x1-$w - min($y2,int(($x1-$w+1)/2)) - 1,
                $y2);
  my $d2 = 1 + max ($x2-$w - $y1,
                    $y2);
  ### $d1
  ### $d2
  ### d2 right slope would be: $x2-$w_right - $y2

  # d1==0 is the centre horizontal
  #

  return ($d1 <= 0
          ? $self->{'n_start'}
          : (6*$d1 - 7 + 2*$w)*$d1 + 1-$w + $self->{'n_start'},

          (6*$d2 - 6 + 2*$w)*$d2 - $w + $self->{'n_start'});
}

1;
__END__

=for stopwords Ryde Math-PlanePath pentagonals OEIS

=head1 NAME

Math::PlanePath::AnvilSpiral -- integer points around an "anvil" shape

=head1 SYNOPSIS

 use Math::PlanePath::AnvilSpiral;
 my $path = Math::PlanePath::AnvilSpiral->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path makes a spiral around an anvil style shape,

                           ...-78-77-76-75-74       4
                                          /
    49-48-47-46-45-44-43-42-41-40-39-38 73          3
      \                             /  /
       50 21-20-19-18-17-16-15-14 37 72             2
         \  \                 /  /  /
          51 22  5--4--3--2 13 36 71                1
            \  \  \     /  /  /  /
             52 23  6  1 12 35 70              <- Y=0
            /  /  /        \  \  \
          53 24  7--8--9-10-11 34 69               -1
         /  /                    \  \
       54 25-26-27-28-29-30-31-32-33 68            -2
      /                                \
    55-56-57-58-59-60-61-62-63-64-65-66-67         -3

                       ^
    -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6  7

The pentagonal numbers 1,5,12,22,etc, P(k) = (3k-1)*k/2 fall alternately on
the X axis XE<gt>0, and on the Y=1 horizontal XE<lt>0.

Those pentagonals are always composites, from the factorization shown, and
as noted in L<Math::PlanePath::PyramidRows/Step 3 Pentagonals>, the
immediately preceding P(k)-1 and P(k)-2 are also composites.  So plotting
the primes on the spiral has a 3-high horizontal blank line at Y=0,-1,-2 for
positive X, and Y=1,2,3 for negative X (after the first few values).

Each loop around the spiral is 12 longer than the preceding.  This is 4*
more than the step=3 C<PyramidRows> so straight lines on a C<PyramidRows>
like these pentagonals are also straight lines here, but split into two
parts.

The outward diagonal excursions are similar to the C<OctagramSpiral>, but
there's just 4 of them here where the C<OctagramSpiral> has 8.  This is
reflected in the loop step.  The basic C<SquareSpiral> is step 8, but by
taking 4 excursions here increases that to 12, and in the C<OctagramSpiral>
8 excursions adds 8 to make step 16.

=head2 Wider

An optional C<wider> parameter makes the path wider by starting with a
horizontal section of given width.  For example

    $path = Math::PlanePath::SquareSpiral->new (wider => 3);

gives

=cut

# math-image --path=AnvilSpiral,wider=3 --all --output=numbers_dash --size=60x12
# but 2 chars per cell

=pod

    33-32-31-30-29-28-27-26-25-24-23 ...            2
      \                          /  /                
       34 11-10--9--8--7--6--5 22 51                1
         \  \              /  /  /                   
          35 12  1--2--3--4 21 50              <- Y=0
         /  /                 \  \                   
       36 13-14-15-16-17-18-19-20 49               -1
      /                             \                
    37-38-39-40-41-42-43-44-45-46-47-48            -2

                       ^
    -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5

The starting point 1 is shifted to the left by ceil(wider/2) places to keep
the spiral centred on the origin X=0,Y=0.  This is the same starting offset
as the C<SquareSpiral> C<wider>.

Widening doesn't change the nature of the straight lines which arise, it
just rotates them around.  Each loop is still 12 longer than the previous,
since the widening is essentially a constant amount in each loop.

=head2 N Start

The default is to number points starting N=1 as shown above.  An optional
C<n_start> can give a different start with the same shape.  For example to
start at 0,

=cut

# math-image --path=AnvilSpiral,n_start=0 --all --output=numbers_dash --size=37x12

=pod

    n_start => 0

    20-19-18-17-16-15-14-13 ...
      \                 /  /
       21  4--3--2--1 12 35
         \  \     /  /  /
          22  5  0 11 34
         /  /        \  \
       23  6--7--8--9-10 33
      /                    \ 
    24-25-26-27-28-29-30-31-32

The only effect is to push the N values around by a constant amount.  It
might help match coordinates with something else zero-based.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::AnvilSpiral-E<gt>new ()>

=item C<$path = Math::PlanePath::AnvilSpiral-E<gt>new (wider =E<gt> $integer, n_start =E<gt> $n)>

Create and return a new anvil spiral object.  An optional C<wider> parameter
widens the spiral path, it defaults to 0 which is no widening.

=back

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to this
path include

=over

L<http://oeis.org/A033581> (etc)

=back

    default wider=0, n_start=1
      A033570    N on X axis, alternate pentagonals (2n+1)*(3n+1)
      A126587    N on Y axis
      A136392    N on Y negative (n=-Y+1)
      A033568    N on X=Y diagonal, alternate second pents (2*n-1)*(3*n-1)
      A085473    N on south-east diagonal

    wider=0, n_start=0
      A211014    N on X axis, 14-gonal numbers of the second kind
      A139267    N on Y axis, 2*octagonal
      A049452    N on X negative, alternate pentagonals
      A033580    N on Y negative, 4*pentagonals
      A051866    N on X=Y diagonal, 14-gonal numbers
      A094159    N on north-west diagonal, 3*hexagonals
      A049453    N on south-west diagonal, alternate second pentagonal
      A195319    N on south-east diagonal, 3*second hexagonals

    wider=1, n_start=0
      A051866    N on X axis, 14-gonal numbers
      A049453    N on Y negative, alternate second pentagonal
      A033569    N on north-west diagonal
      A085473    N on south-west diagonal
      A080859    N on Y negative
      A033570    N on south-east diagonal
                   alternate pentagonals (2n+1)*(3n+1)

    wider=2, n_start=1
      A033581    N on Y axis (6*n^2) except for initial N=2

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::SquareSpiral>,
L<Math::PlanePath::OctagramSpiral>,
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
