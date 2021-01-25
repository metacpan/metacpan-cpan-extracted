# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021 Kevin Ryde

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


package Math::PlanePath::PyramidSpiral;
use 5.004;
use strict;
#use List::Util 'min';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 129;
use Math::PlanePath;
*_sqrtint = \&Math::PlanePath::_sqrtint;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'round_nearest';

# uncomment this to run the ### lines
#use Smart::Comments;


use constant parameter_info_array =>
  [ Math::PlanePath::Base::Generic::parameter_info_nstart1() ];

use constant xy_is_visited => 1;
sub x_negative_at_n {
  my ($self) = @_;
  return $self->n_start + 3;
}
sub y_negative_at_n {
  my ($self) = @_;
  return $self->n_start + 4;
}
sub _UNDOCUMENTED__dxdy_list_at_n {
  my ($self) = @_;
  return $self->n_start + 2;
}
use constant dx_minimum => -1;
use constant dx_maximum => 1;
use constant dy_minimum => -1;
use constant dy_maximum => 1;
use constant 1.02 _UNDOCUMENTED__dxdy_list => (1,0,   # E
                                               -1,1,  # NW
                                               -1,-1, # SW
                                              );
use constant absdx_minimum => 1;
use constant dsumxy_minimum => -2; # SW diagonal
use constant dsumxy_maximum => 1;
use constant ddiffxy_minimum => -2; # NW diagonal
use constant ddiffxy_maximum => 1;
use constant dir_maximum_dxdy => (-1,-1);  # South-West
use constant turn_any_right => 0; # only left or straight


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new (@_);
  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }
  return $self;
}

# bottom left corner, N=0 basis
# [  0,  1,  2,  3 ],
# [  0,  4, 16, 36 ]
# N = (4 d^2)
#   = (4*$d**2)
#   = (4*$d**2)
# d = 0 + sqrt(1/4 * $n + 0)
#   = sqrt($n)/2
#
sub n_to_xy {
  my ($self, $n) = @_;
  #### PyramidSpiral n_to_xy: $n

  $n = $n - $self->{'n_start'};  # start N=0, and warn if $n==undef
  if ($n < 0) { return; }

  my $d = int( _sqrtint($n)/2 );
  $n -= (4*$d+2)*$d;  # to $n==0 on Y negative axis

  if ($n <= 2*$d+1) {
    ### bottom horizontal ...
    return ($n, -$d);
  }
  $n -= 4*$d+2;
  ### sides, remainder pos/neg from top ...
  return (-$n,
          - abs($n) + $d + 1);
}

# negative y, x=0 centres
#   [ 1,  2,  3 ]
#   [ 7, 21, 43 ]
#   n = (4*$y*$y + 2*abs($y) + 1)
#
# positive y, x=0 centres
#   [ 1,  2,  3 ]
#   [ 3, 13, 31 ]
#   n = (4*$d*$d + -2*$d + 1)
#

sub xy_to_n {
  my ($self, $x, $y) = @_;
  $x = round_nearest ($x);
  $y = round_nearest ($y);
  ### xy_to_n(): "$x,$y"

  if ($y < 0 && abs($x) <= 2*-$y) {
    ### bottom horizontal
    return 4*$y*$y - 2*$y + $x + $self->{'n_start'};
  }

  ### sides diagonal
  my $k = 2 * (abs($x) + $y);
  return $k*($k-1) - $x + $self->{'n_start'};
}

# Each row N increases away from some midpoint.
# Each column N increase away from some midpoint.
# So maximum must be at one of the corners.
#
# maybe:
# Minimum in row is at X=0 when Y>=0
#                or at X=2*Y slope when Y<0
# Minimum in column is at Y=floor(X/2) when X<=0
#                   or at Y=-floor(X/2) when X>=0
#
# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;

  # ENHANCE-ME: find exact minimum
  return ($self->n_start,
          max ($self->xy_to_n($x1,$y1),
               $self->xy_to_n($x1,$y2),
               $self->xy_to_n($x2,$y1),
               $self->xy_to_n($x2,$y2)));
}

1;
__END__

=for stopwords pronic PlanePath Ryde Math-PlanePath OEIS

=head1 NAME

Math::PlanePath::PyramidSpiral -- integer points drawn around a pyramid

=head1 SYNOPSIS

 use Math::PlanePath::PyramidSpiral;
 my $path = Math::PlanePath::PyramidSpiral->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path makes a pyramid shaped spiral,

=cut

# math-image --path=PyramidSpiral --all --output=numbers_dash

=pod

                      31                          3
                     /  \
                   32 13 30                       2
                  /  /  \  \
                33 14  3 12 29                    1
               /  /  /  \  \  \
             34 15  4  1--2 11 28 ...         <- Y=0
            /  /  /           \  \  \
          35 16  5--6--7--8--9-10 27 52          -1
         /  /                       \  \
       36 17-18-19-20-21-22-23-24-25-26 51       -2
      /                                   \
    37-38-39-40-41-42-43-44-45-46-47-48-49-50    -3

                       ^
    -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6  7

X<Square numbers>The perfect squares 1,4,9,16 fall one before the bottom
left corner of each loop, and the X<Pronic numbers>pronic numbers
2,6,12,20,30,etc are the vertical upwards from X=1,Y=0.

=head2 Square Spiral

This spiral goes around at the same rate as the C<SquareSpiral>.  It's as if
two corners are cut off (like the C<DiamondSpiral>) and two others extended
(like the C<OctagramSpiral>).  The net effect is the same looping rate but
the points pushed around a bit.

Taking points up to a perfect square shows the similarity.  The two
triangular cut-off corners marked by "."s are matched by the two triangular
extensions.

            +--------------------+   7x7 square
            | .  .  . 31  .  .  .|
            | .  . 32 13 30  .  .|
            | . 33 14  3 12 29  .|
            |34 15  4  1  2 11 28|
          35|16  5  6  7  8  9 10|27
       36 17|18 19 20 21 22 23 24|25 26
    37 38 39|40 41 42 43 44 45 46|47 48 49
            +--------------------+

=head2 N Start

The default is to number points starting N=1 as shown above.  An optional
C<n_start> can give a different start, with the same shape etc.  For example
to start at 0,

=cut

# math-image --path=PyramidSpiral,n_start=0 --all --output=numbers_dash --size=35x16

=pod

                12         n_start => 0
               /  \  
             13  2 11 
            /  /  \  \  
          14  3  0--1 10 
         /  /           \  
       15  4--5--6--7--8--9 
      /            
    16-17-18-19-20-21-22-...

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::PyramidSpiral-E<gt>new ()>

=item C<$path = Math::PlanePath::PyramidSpiral-E<gt>new (n_start =E<gt> $n)>

Create and return a new pyramid spiral object.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return the point number for coordinates C<$x,$y>.  C<$x> and C<$y> are
each rounded to the nearest integer, which has the effect of treating each N
in the path as centred in a square of side 1, so the entire plane is
covered.

=back

=head1 OEIS

This path is in Sloane's Online Encyclopedia of Integer Sequences as

=over

L<http://oeis.org/A053615> (etc)

=back

    n_start=1 (the default)
      A053615    abs(X), distance to next pronic, but starts n=0
      A054552    N on X axis, 4n^2 - 3n + 1
      A033951    N on South-East diagonal, 4n^2 + 3n + 1

      A214250    sum N of eight surrounding cells

      A217013    permutation N of points in SquareSpiral order
                   rotated +90 degrees
      A217294    inverse

In the two permutations the pyramid spiral is conceived as starting to the
left and the square spiral starting upwards.  The paths here start in the
same direction (both to the right), hence rotate 90 to adjust the
orientation.

    n_start=0
      A329116    X coordinate
      A329972    Y coordinate
      A053615    abs(X)
      A339265    dX-dY increments (runs +1,-1)
      A001107    N on X axis, decagonal numbers
      A002939    N on Y axis
      A033991    N on X negative axis
      A002943    N on Y negative axis
      A007742    N on diagonal South-West
      A033954    N on diagonal South-East, decagonal second kind

    n_start=2
      A185669    N on diagonal South-East

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::SquareSpiral>,
L<Math::PlanePath::PyramidRows>,
L<Math::PlanePath::TriangleSpiral>,
L<Math::PlanePath::TriangleSpiralSkewed>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021 Kevin Ryde

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
