# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018 Kevin Ryde

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


# Hlawka, angles of point N is
# phi(n) = sum k=1 to n of arcsin 1/sqrt(k+1)
# is equidistributed mod 2pi


package Math::PlanePath::TheodorusSpiral;
use 5.004;
use strict;
use Math::Libm 'hypot';
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 127;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';

# uncomment this to run the ### lines
#use Smart::Comments;


use constant n_start => 0;
use constant figure => 'circle';
use constant x_negative_at_n => 4;
use constant y_negative_at_n => 7;
use constant gcdxy_maximum => 1;
use constant dx_minimum => -1; # supremum when straight
use constant dx_maximum => 1;  # at N=0
use constant dy_minimum => -1;
use constant dy_maximum => 1;  # at N=1
use constant dsumxy_minimum => -sqrt(2); # supremum diagonal
use constant dsumxy_maximum => sqrt(2);
use constant ddiffxy_minimum => -sqrt(2); # supremum diagonal
use constant ddiffxy_maximum => sqrt(2);
use constant turn_any_right    => 0; # left always
use constant turn_any_straight => 0; # left always


#------------------------------------------------------------------------------

# This adding up of unit steps isn't very good.  The last x,y,n is kept
# anticipating successively higher n, not necessarily consecutive, plus past
# x,y,n at _SAVE intervals for going backwards.
#
# The simplest formulas for the polar angle, possibly with the analytic
# continuation version don't seem much better, but theta approaches
# 2*sqrt(N) + const, or 2*sqrt(N) + 1/(6*sqrt(N+1)) + const + O(n^(3/2)), so
# more terms of that might have tolerably rapid convergence.
#
# The arctan sums for the polar angle end up as the generalized Riemann
# zeta, or the generalized minus the plain.  Is there a good formula for
# that which would converge quickly?

use constant 1.02; # for leading underscore
use constant _SAVE => 1000;

my @save_n = (1);
my @save_x = (1);
my @save_y = (0);
my $next_save = _SAVE;

sub new {
  return shift->SUPER::new (i => 1,
                            x => 1,
                            y => 0,
                            @_);
}

# r = sqrt(int)
# (frac r)^2
#   = hypot(r, frac)^2   frac at right angle to radial
#   = r^2 + $frac^2
#   = sqrt(int)^2 + $frac^2
#   = $int + $frac^2
#
sub n_to_rsquared {
  my ($self, $n) = @_;
  if ($n < 0) { return undef; }
  my $int = int($n);
  $n -= $int;  # fractional part
  return $n*$n + $int;
}

# r = sqrt(i)
# x,y angle
# r*x/hypot, r*y/hypot 
#
# newx = x - y/r
# newy = y + x/r
# (x-y/r)^2 + (y+x/r)^2
#   =   x^2 - 2y/r + y^2/r^2
#     + y^2 + 2x/r + x^2/r^2

sub n_to_xy {
  my ($self, $n) = @_;
  #### TheodorusSpiral n_to_xy(): $n

  if ($n < 0) { return; }
  if (is_infinite($n)) { return ($n,$n); }

  if ($n < 1) {
    return ($n, 0);
  }
  my $frac = $n;
  $n = int($n);
  $frac -= $n;

  my $i = $self->{'i'};
  my $x = $self->{'x'};
  my $y = $self->{'y'};
  #### n_to_xy(): "$n from state $i $x,$y"

  if ($i > $n) {
    for (my $pos = $#save_n; $pos >= 0; $pos--) {
      if ($save_n[$pos] <= $n) {
        $i = $save_n[$pos];
        $x = $save_x[$pos];
        $y = $save_y[$pos];
        last;
      }
    }
    ### resume: "$i  $x,$y"
  }

  while ($i < $n) {
    my $r = sqrt($i);
    ($x,$y) = ($x - $y/$r, $y + $x/$r);
    $i++;

    if ($i == $next_save) {
      push @save_n, $i;
      push @save_x, $x;
      push @save_y, $y;
      $next_save += _SAVE;

      ### save: $i
      ### @save_n
      ### @save_x
      ### @save_y
    }
  }

  $self->{'i'} = $i;
  $self->{'x'} = $x;
  $self->{'y'} = $y;

  if ($frac) {
    my $r = sqrt($n);
    return ($x - $frac*$y/$r,
            $y + $frac*$x/$r);
  } else {
    #### integer return: "$i  $x,$y"
    return ($x,$y);
  }
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### TheodorusSpiral xy_to_n(): "$x, $y"
  my $r = hypot ($x,$y);
  my $n_lo = int (max (0, $r - .51) ** 2);
  my $n_hi = int (($r + .51) ** 2);
  ### $n_lo
  ### $n_hi

  if (is_infinite($n_lo) || is_infinite($n_hi)) {
    ### infinite range, r inf or too big ...
    return undef;
  }

  # for(;;) loop since $n_lo..$n_hi limited to IV range
  for (my $n = $n_lo; $n <= $n_hi; $n += 1) {
    my ($nx,$ny) = $self->n_to_xy($n);
    #### $n
    #### $nx
    #### $ny
    #### hypot: hypot ($x-$nx,$y-$ny)
    if (hypot ($x-$nx,$y-$ny) <= 0.5) {
      return $n;
    }
  }
  return undef;
}

use Math::PlanePath::SacksSpiral;
# not exact
*rect_to_n_range = \&Math::PlanePath::SacksSpiral::rect_to_n_range;

1;
__END__

=for stopwords Theodorus Ryde Math-PlanePath Archimedean Nhi Nlo arctan xlo,ylo xhi,yhi rlo Nlo Nhi Nhi-Nlo RSquared ceil OEIS xlo xhi

=head1 NAME

Math::PlanePath::TheodorusSpiral -- right-angle unit step spiral

=head1 SYNOPSIS

 use Math::PlanePath::TheodorusSpiral;
 my $path = Math::PlanePath::TheodorusSpiral->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path puts points on the spiral of Theodorus, also called the square
root spiral.


                                   61                 6
                                     60
               27 26 25 24                            5
            28            23           59
          29                 22          58           4

       30                      21         57          3
      31                         20
                   4                       56         2
     32          5    3          19
               6         2                 55         1
    33                            18
              7       0  1                 54    <- Y=0
    34                           17
              8                            53        -1
    35                          16
               9                          52         -2
     36                       15
                 10         14           51          -3
      37           11 12 13            50
                                                     -4
        38                           49
          39                       48                -5
            40                  47
               41             46                     -6
                  42 43 44 45


                      ^
   -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6  7

Each step is a unit distance at right angles to the previous radial spoke.
So for example,

       3        <- Y=1+1/sqrt(2)
        \
         \
         ..2    <- Y=1
       ..  |
      .    |
     0-----1    <- Y=0

     ^
    X=0   X=1

1 to 2 is a unit step at right angles to the 0 to 1 radial.  Then 2 to 3
steps at a right angle to radial 0 to 2 which is 45 degrees, etc.

The radial distance 0 to 2 is sqrt(2), 0 to 3 is sqrt(3), and in general

    R = sqrt(N)

because each step is a right triangle with radius(N+1)^2 = S<radius(N)^2
+ 1>.  The resulting shape is very close to an Archimedean spiral with
successive loops increasing in radius by pi = 3.14159 or thereabouts
each time.

X,Y positions returned are fractional and each integer N position is exactly
1 away from the previous.  Fractional N values give positions on the
straight line between the integer points.  (An analytic continuation for a
rounded curve between points is possible, but not currently implemented.)

Each loop is just under 2*pi^2 = 19.7392 many N points longer than the
previous.  This means quadratic values 9.8696*k^2 for integer k are an
almost straight line.  Quadratics close to 9.87 (or a square multiple of
that) nearly line up.  For example the 22-polygonal numbers have 10*k^2 and
at low values are nearly straight because 10 is close to 9.87, but then
spiral away.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

The code is currently implemented by adding unit steps in X,Y coordinates,
so it's not particularly fast.  The last X,Y is saved in the object
anticipating successively higher N (not necessarily consecutive), and
previous positions 1000 apart are saved for re-use or to go back.

=over 4

=item C<$path = Math::PlanePath::TheodorusSpiral-E<gt>new ()>

Create and return a new Theodorus spiral object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.

C<$n> can be any value C<$n E<gt>= 0> and fractions give positions on the
spiral in between the integer points.

For C<$n < 0> the return is an empty list, it being currently considered
there are no negative points in the spiral.  (The analytic continuation by
Davis would be a possibility, though the resulting "inner spiral" makes
positive and negative points overlap a bit.  A spiral starting at X=-1 would
fit in between the positive points.)

=item C<$rsquared = $path-E<gt>n_to_rsquared ($n)>

Return the radial distance R^2 of point C<$n>, or C<undef> if C<$n> is
negative.  For integer C<$n> this is simply C<$n> itself.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return an integer point number for coordinates C<$x,$y>.  Each integer N
is considered the centre of a circle of diameter 1 and an C<$x,$y> within
that circle returns N.

The unit steps of the spiral means those unit circles don't overlap, but the
loops are roughly 3.14 apart so there's gaps in between.  If C<$x,$y> is not
within one of the unit circles then the return is C<undef>.

=item C<$str = $path-E<gt>figure ()>

Return string "circle".

=back

=head1 FORMULAS

=head2 N to RSquared

For integer N the spiral has radius R=sqrt(N) and the square is simply
RSquared=R^2=N.  For fractional N the point is on a straight line at right
angles to the integer position, so

    R = hypot(sqrt(Ninteger), Nfrac)
    RSquared = (sqrt(Ninteger))^2 + Nfrac^2
             = Ninteger + Nfrac^2

=head2 X,Y to N

For a given X,Y the radius R=hypot(X,Y) determines the N position as N=R^2.
An N point up to 0.5 away radially might cover X,Y, so the range of N to
consider is

    Nlo = (R-.5)^2
    Nhi = (R+.5)^2

A simple search is made through those N's seeking which, if any, covers X,Y.
The number of N's searched is Nhi-Nlo = 2*R+1 which is about 1/3 of a loop
around the spiral (2*R/2*pi*R ~= 1/3).  Actually 0.51 is used to guard
against floating point round-off, which is then about 4*.51 = 2.04*R many
points.

The angle of the X,Y position determines which part of the spiral is
intersected, but using that doesn't seem particularly easy.  The angle for a
given N is an arctan sum and there doesn't seem to be a good closed-form or
converging series to invert, or apply some Newton's method, or whatever.

=head2 Rectangle to N Range

For C<rect_to_n_range()> the corner furthest from the origin determines the
high N.  For that corner

    Rhi = hypot(xhi,yhi)
    Nhi = (Rhi+.5)^2

The extra .5 is since a unit circle figure centred as much as .5 further out
might intersect the xhi,yhi.  The square root hypot() can be avoided by the
following over-estimate, and ceil can keep it in integers for integer Nhi.

    Nhi = Rhi^2 + Rhi + 1/4
        <= Xhi^2+Yhi^2 + Xhi+Yhi + 1      # since Rhi<=Xhi+Yhi
        = Xhi*(Xhi+1) + Yhi*(Yhi+1) + 1
        <= ceilXhi*(ceilXhi+1) + ceilYhi*(ceilYhi+1) + 1

With either formula the worst case is when Nhi doesn't intersect the xhi,yhi
corner but is just before it, anti-clockwise.  Nhi is then a full revolution
bigger than it need be, depending where the other corners fall.

Similarly for the corner or axis crossing nearest the origin (when the
origin itself isn't covered by the rectangle),

    Rlo = hypot(Xlo,Ylo)
    Nlo = (Rlo-.5)^2, or 0 if origin covered by rectangle

And again in integers without a square root if desired,

    Nlo = Rlo^2 - Rlo + 1/4
        >= Xlo^2+Ylo^2 - (Xlo+Ylo)        # since Xlo+Ylo>=Rlo
        = Xlo*(Xlo-1) + Ylo*(Ylo-1)
        >= floorXlo*(floorXlo-1) + floorYlo(floorYlo-1)

The worst case is when this Nlo doesn't intersect the xlo,ylo corner but is
just after it anti-clockwise, so Nlo is a full revolution smaller than it
need be.

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to this
path include

=over

L<http://oeis.org/A072895> (etc)

=back

    A072895    N just below X axis
    A137515    N-1 just below X axis
                 counting num points for n revolutions
    A172164    loop length increases

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::ArchimedeanChords>,
L<Math::PlanePath::SacksSpiral>,
L<Math::PlanePath::MultipleRings>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2015 Kevin Ryde

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


# Detlef Gronau "The Spiral of Theodorus", AMM, 111(3), March 2004,
# http://www.uni-graz.at/~gronau/monthly230-237.pdf

# Philip J. Davis, book "Spirals: From Theodorus to Chaos", published
# A. K. Peters, 1993, pages 7-11, 37-43.

# K. J. Heuvers, D.S. Moak, B.Boursaw, "The Functional Equation of the
# Square Root Spiral", Functional Equations and Inequalities,
# ed. T. M. Rassias, Kluwer 2000, pages 111-117, MR1792078 (2001k:39033)

# David Brink, "The Spiral of Theodorus and Sums of Zeta-values at the
# Half-integers", American Mathematical Monthly, Vol. 119, No. 9 (November
# 2012),
# pp. 779-786. http://www.jstor.org/stable/10.4169/amer.math.monthly.119.09.779

# A226317 constant of theodorus in decimal
