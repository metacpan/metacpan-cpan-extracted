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


package Math::PlanePath::PyramidSides;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 126;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'round_nearest';
*_sqrtint = \&Math::PlanePath::_sqrtint;

# uncomment this to run the ### lines
#use Smart::Comments;


use constant class_y_negative => 0;
use constant n_frac_discontinuity => 0.5;
*xy_is_visited = \&Math::PlanePath::Base::Generic::xy_is_visited_quad12;

use constant parameter_info_array =>
  [ Math::PlanePath::Base::Generic::parameter_info_nstart1() ];

sub x_negative_at_n {
  my ($self) = @_;
  return $self->n_start + 1;
}
use constant dx_maximum => 1;
use constant dy_minimum => -1;
use constant dy_maximum => 1;
use constant absdx_minimum => 1;
use constant dsumxy_maximum => 2; # NE diagonal
use constant ddiffxy_maximum => 2; # SE diagonal

use constant dir_minimum_dxdy => (1,1);  # North-East
use constant dir_maximum_dxdy => (1,-1); # South-East

use constant turn_any_left =>  0; # only right or straight


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);
  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }
  return $self;
}

# starting each left side at 0.5 before
#
# d = [  0,   1,   2,   3,    4  ]
# n = [ 0-0.5, 1-0.5, 4-0.5, 9-0.5, 16-0.5 ]
# N = (d^2 - 1/2)
#   = ($d**2 - 1/2)
# d = 0 + sqrt(1 * $n + 1/2)
#   = sqrt(4*$n+2)/2
#
sub n_to_xy {
  my ($self, $n) = @_;
  ### PyramidSides n_to_xy: $n

  # adjust to N=0 at origin X=0,Y=0
  $n = $n - $self->{'n_start'};

  my $d;
  {
    my $r = 4*$n + 2;
    if ($r < 0) {
      return;   # N < -0.5
    }
    $d = int( _sqrtint($r) / 2 );
  }
  $n -= $d*($d+1);   # to $n=0 on Y axis, so X=$n
  ### remainder: $n

  return ($n,
          - abs($n) + $d);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### PyramidSides xy_to_n(): $x, $y

  $y = round_nearest ($y);
  if ($y < 0) {
    return undef;
  }
  $x = round_nearest ($x);

  my $d = abs($x) + $y;
  return $d*$d + $x+$d + $self->{'n_start'};
}

# exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  if ($y1 > $y2) { ($y1,$y2) = ($y2,$y1); } # swap to y1<=y2
  if ($y2 < 0) {
    return (1, 0); # rect all negative, no N
  }
  if ($y1 < 0) { $y1 *= 0; }   # "*=" to preserve bigint y1

  my ($xlo, $xhi) = (abs($x1) < abs($x2)   # lo,hi by absolute value
                     ? ($x1, $x2)
                     : ($x2, $x1));
  if ($x2 == -$x1) {
    # when say x1=-5 x2=+5 then x=+5 is the bigger N
    $xhi = abs($xhi);
  }
  if (($x1 >= 0) ^ ($x2 >= 0)) {
    # if x1>=0 and x2<0 or other way around then x=0 is covered and is the
    # smallest N
    $xlo *= 0;   # "*=" to preserve bigint
  }

  return ($self->xy_to_n ($xlo, $y1),
          $self->xy_to_n ($xhi, $y2));
}

1;
__END__

=for stopwords pronic versa PlanePath Ryde Math-PlanePath ie Euler's OEIS

=head1 NAME

Math::PlanePath::PyramidSides -- points along the sides of pyramid

=head1 SYNOPSIS

 use Math::PlanePath::PyramidSides;
 my $path = Math::PlanePath::PyramidSides->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path puts points in layers along the sides of a pyramid growing
upwards.

                        21                        4
                    20  13  22                    3
                19  12   7  14  23                2
            18  11   6   3   8  15  24            1
        17  10   5   2   1   4   9  16  25    <- Y=0
       ------------------------------------
                         ^
    ... -4  -3  -2  -1  X=0  1   2   3   4 ...

X<Square numbers>N=1,4,9,16,etc along the positive X axis is the perfect
squares.  N=2,6,12,20,etc in the X=-1 vertical is the
X<Pronic numbers>pronic numbers k*(k+1) half way between those successive
squares.

The pattern is the same as the C<Corner> path but turned and spread so the
single quadrant in the C<Corner> becomes a half-plane here.

The pattern is similar to C<PyramidRows> (with its default step=2), just
with the columns dropped down vertically to start at the X axis.  Any
pattern occurring within a column is unchanged, but what was a row becomes a
diagonal and vice versa.

=head2 Lucky Numbers of Euler

An interesting sequence for this path is Euler's k^2+k+41.  The low values
are spread around a bit, but from N=1763 (k=41) they're the vertical at
X=40.  There's quite a few primes in this quadratic and when plotting primes
that vertical stands out a little denser than its surrounds (at least for up
to the first 2500 or so values).  The line shows in other step==2 paths too,
but not as clearly.  In the C<PyramidRows> for instance the beginning is up
at Y=40, and in the C<Corner> path it's a diagonal.

=head2 N Start

The default is to number points starting N=1 as shown above.  An optional
C<n_start> can give a different start, in the same pyramid pattern.  For
example to start at 0,

=cut

# math-image --path=PyramidSides,n_start=0 --all --output=numbers --size=48x5

=pod

    n_start => 0

                20                    4
             19 12 21                 3
          18 11  6 13 22              2
       17 10  5  2  7 14 23           1
    16  9  4  1  0  3  8 15 24    <- Y=0
    --------------------------
    -4 -3 -2 -1 X=0 1  2  3  4

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::PyramidSides-E<gt>new ()>

=item C<$path = Math::PlanePath::PyramidSides-E<gt>new (n_start =E<gt> $n)>

Create and return a new path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.

For C<$n < 0.5> the return is an empty list, it being considered there are no
negative points in the pyramid.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return the point number for coordinates C<$x,$y>.  C<$x> and C<$y> are
each rounded to the nearest integer which has the effect of treating points
in the pyramid as a squares of side 1, so the half-plane y>=-0.5 is entirely
covered.

=item C<($n_lo, $n_hi) = $path-E<gt>rect_to_n_range ($x1,$y1, $x2,$y2)>

The returned range is exact, meaning C<$n_lo> and C<$n_hi> are the smallest
and biggest in the rectangle.

=back

=head1 FORMULAS

=head2 Rectangle to N Range

For C<rect_to_n_range()>, in each column N increases so the biggest N is in
the topmost row and and smallest N in the bottom row.

In each row N increases along the sequence X=0,-1,1,-2,2,-3,3, etc.  So the
biggest N is at the X of biggest absolute value and preferring the positive
X=k over the negative X=-k.

The smallest N conversely is at the X of smallest absolute value.  If the X
range crosses 0, ie. C<$x1> and C<$x2> have different signs, then X=0 is the
smallest.

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to this
path include

=over

L<http://oeis.org/A196199> (etc)

=back

    n_start=1 (the default)
      A049240    abs(dY), being 0=horizontal step at N=square
      A002522    N on X negative axis, x^2+1
      A033951    N on X=Y diagonal, 4d^2+3d+1
      A004201    N for which X>=0, ie. right hand half
      A020703    permutation N at -X,Y
 
   n_start=0
      A196199    X coordinate, runs -n to +n
      A053615    abs(X), runs n to 0 to n
      A000196    abs(X)+abs(Y), being floor(sqrt(N)),
                   k repeated 2k+1 times starting 0

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::PyramidRows>,
L<Math::PlanePath::Corner>,
L<Math::PlanePath::DiamondSpiral>,
L<Math::PlanePath::SacksSpiral>,
L<Math::PlanePath::MPeaks>

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
