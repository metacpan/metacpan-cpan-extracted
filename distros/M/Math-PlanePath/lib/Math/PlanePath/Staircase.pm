# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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


package Math::PlanePath::Staircase;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 124;
use Math::PlanePath;
@ISA = ('Math::PlanePath');
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;
*_sqrtint = \&Math::PlanePath::_sqrtint;

use Math::PlanePath::Base::Generic
  'round_nearest';

# uncomment this to run the ### lines
#use Smart::Comments;


use constant class_x_negative => 0;
use constant class_y_negative => 0;
use constant n_frac_discontinuity => .5;
*xy_is_visited = \&Math::PlanePath::Base::Generic::xy_is_visited_quad1;

use constant dx_maximum => 1;
use constant dy_minimum => -1;
use constant dsumxy_minimum => -1; # straight S
use constant dsumxy_maximum => 2;  # next row
use constant ddiffxy_maximum => 1; # straight S,E
use constant dir_maximum_dxdy => (0,-1); # South

use constant parameter_info_array =>
  [
   Math::PlanePath::Base::Generic::parameter_info_nstart1(),
  ];


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);
  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }
  return $self;
}

# start from 0.5 back
#     d = [ 0, 1,  2, 3 ]
#     n = [ 1.5, 6.5, 15.5 ]
#     n = ((2*$d - 1)*$d + 0.5)
#     d = 1/4 + sqrt(1/2 * $n + -3/16)
#
# start from integer vertical
#     d = [ 0, 1,  2,  3,  4 ]
#     n = [ 1, 2,  7, 16, 29 ]
#     n = ((2*$d - 1)*$d + 1)
#     d = 1/4 + sqrt(1/2 * $n + -7/16)
#       = [1 + sqrt(8*$n-7) ] / 4
#
sub n_to_xy {
  my ($self, $n) = @_;
  #### Staircase n_to_xy: $n

  # adjust to N=1 start
  $n = $n - $self->{'n_start'} + 1;

  my $d;
  {
    my $r = 8*$n - 3;
    if ($r < 1) {
      return;   # N < 0.5, so before start of path
    }
    $d = int( (_sqrtint($r) + 1)/4 );
  }
  ### $d
  ### base: ((2*$d - 1)*$d + 0.5)

  $n -= (2*$d - 1)*$d;
  ### fractional: $n

  my $int = int($n);
  $n -= $int;

  my $rem = _divrem_mutate ($int, 2);
  if ($rem) {
    ### down ...
    return ($int,
            -$n + 2*$d - $int);
  } else {
    ### across ...
    return ($n + $int-1,
            2*$d - $int);
  }
}

# d = [ 1  2, 3, 4 ]
# N = [ 2, 7, 16, 29 ]
# N = (2 d^2 - d + 1)
# and add 2*$d
# base = 2*d^2 - d + 1 + 2*d
#      = 2*d^2 + d + 1
#      = (2*$d + 1)*$d + 1
#
sub xy_to_n {
  my ($self, $x, $y) = @_;

  $x = round_nearest ($x);
  $y = round_nearest ($y);
  if ($x < 0 || $y < 0) {
    return undef;
  }
  my $d = int(($x + $y + 1) / 2);
  return (2*$d + 1)*$d - $y + $x + $self->{'n_start'};
}

# exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### Staircase rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  if ($x1 > $x2) { ($x1,$x2) = ($x2,$x1); }  # x2 > x1
  if ($y1 > $y2) { ($y1,$y2) = ($y2,$y1); }  # y2 > y1
  if ($x2 < 0 || $y2 < 0) {
    return (1, 0);   # nothing outside first quadrant
  }

  if ($x1 < 0) { $x1 *= 0; }
  if ($y1 < 0) { $y1 *= 0; }
  my $y_min = $y1;

  if ((($x1 ^ $y1) & 1) && $y1 < $y2) {  # y2==y_max
    $y1 += 1;
    ### y1 inc: $y1
  }
  if (! (($x2 ^ $y2) & 1) && $y2 > $y_min) {
    $y2 -= 1;
    ### y2 dec: $y2
  }
  return ($self->xy_to_n($x1,$y1),
          $self->xy_to_n($x2,$y2));
}

1;
__END__

=for stopwords eg Ryde Math-PlanePath Legendre's OEIS

=head1 NAME

Math::PlanePath::Staircase -- integer points in stair-step diagonal stripes

=head1 SYNOPSIS

 use Math::PlanePath::Staircase;
 my $path = Math::PlanePath::Staircase->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path makes a staircase pattern down from the Y axis to the X,

=cut

# math-image --path=Staircase --all --output=numbers_dash --size=70x30

=pod

     8      29
             |
     7      30---31
                  |
     6      16   32---33
             |         |
     5      17---18   34---35
                  |         |
     4       7   19---20   36---37
             |         |         |
     3       8--- 9   21---22   38---39
                  |         |         |
     2       2   10---11   23---24   40...
             |         |         |
     1       3--- 4   12---13   25---26
                  |         |         |
    Y=0 ->   1    5--- 6   14---15   27---28

             ^
            X=0   1    2    3    4    5    6

X<Hexagonal numbers>The 1,6,15,28,etc along the X axis at the end of each
run are the hexagonal numbers k*(2*k-1).  The diagonal 3,10,21,36,etc up
from X=0,Y=1 is the second hexagonal numbers k*(2*k+1), formed by extending
the hexagonal numbers to negative k.  The two together are the
X<Triangular numbers>triangular numbers k*(k+1)/2.

Legendre's prime generating polynomial 2*k^2+29 bounces around for some low
values then makes a steep diagonal upwards from X=19,Y=1, at a slope 3 up
for 1 across, but only 2 of each 3 drawn.

=head2 N Start

The default is to number points starting N=1 as shown above.  An optional
C<n_start> can give a different start, in the same pattern.  For example to
start at 0,

=cut

# math-image --path=Staircase,n_start=0 --expression='i<=38?i:0' --output=numbers --size=80x10

=pod

    n_start => 0

    28
    29 30
    15 31 32
    16 17 33 34
     6 18 19 35 36
     7  8 20 21 37 38
     1  9 10 22 23 ....
     2  3 11 12 24 25
     0  4  5 13 14 26 27

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::Staircase-E<gt>new ()>

=item C<$path = Math::PlanePath::AztecDiamondRings-E<gt>new (n_start =E<gt> $n)>

Create and return a new staircase path object.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return the point number for coordinates C<$x,$y>.  C<$x> and C<$y> are
rounded to the nearest integers, which has the effect of treating each point
C<$n> as a square of side 1, so the quadrant x>=-0.5, y>=-0.5 is covered.

=item C<($n_lo, $n_hi) = $path-E<gt>rect_to_n_range ($x1,$y1, $x2,$y2)>

The returned range is exact, meaning C<$n_lo> and C<$n_hi> are the smallest
and biggest in the rectangle.

=back

=head1 FORMULAS

=head2 Rectangle to N Range

Within each row increasing X is increasing N, and in each column increasing
Y is increasing pairs of N.  Thus for C<rect_to_n_range()> the lower left
corner vertical pair is the minimum N and the upper right vertical pair is
the maximum N.

A given X,Y is the larger of a vertical pair when ((X^Y)&1)==1.  If that
happens at the lower left corner then it's X,Y+1 which is the smaller N, as
long as Y+1 is in the rectangle.  Conversely at the top right if
((X^Y)&1)==0 then it's X,Y-1 which is the bigger N, again as long as Y-1 is
in the rectangle.

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
this path include

=over

L<http://oeis.org/A084849> (etc)

=back

    n_start=1 (the default)
      A084849    N on diagonal X=Y

    n_start=0
      A014105    N on diagonal X=Y, second hexagonal numbers

    n_start=2
      A128918    N on X axis, except initial 1,1
      A096376    N on diagonal X=Y

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::Diagonals>,
L<Math::PlanePath::Corner>,
L<Math::PlanePath::ToothpickSpiral>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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
