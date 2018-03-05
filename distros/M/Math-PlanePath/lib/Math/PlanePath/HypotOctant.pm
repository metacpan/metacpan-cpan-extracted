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


# Circle drop splash rings from 
# math-image --path=HypotOctant --values=DigitProductSteps,values_type=count
# math-image --path=Hypot --values=DigitProduct
# math-image --path=Hypot --values=DigitCount
# math-image --path=Hypot --values=Modulo,modulus=1000
# http://stefan.guninski.com/oeisposter/
#
# pi*r^2 - pi*(r-1)^2 = pi*(2r-1)
# octant is 1/8 of that pi*(2x-1)/8
# pi*(2x-1)/8=100k
# 2x-1 = 100k*8/pi
# x = 100*4/pi*k
#
# A000328 Number of points of norm <= n^2 in square lattice.
# 1, 5, 13, 29, 49, 81, 113, 149, 197, 253, 317, 377, 441, 529, 613, 709, 797
# a(n) = 1 + 4 * sum(j=0, n^2 / 4,    n^2 / (4*j+1) - n^2 / (4*j+3) )
#
# A057655 num points norm <= n in square lattice.
#
# A036702 num points |z=a+bi| <= n with 0<=a, 0<=b<=a, so octant
# A036703 num points n-1 < z <= n, first diffs?



package Math::PlanePath::HypotOctant;
use 5.004;
use strict;
use Carp 'croak';

use vars '$VERSION', '@ISA';
$VERSION = 126;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';

# uncomment this to run the ### lines
#use Smart::Comments;


use constant parameter_info_array =>
  [ { name            => 'points',
      share_key       => 'points_aeo',
      display         => 'Points',
      type            => 'enum',
      default         => 'all',
      choices         => ['all','even','odd'],
      choices_display => ['All','Even','Odd'],
      description     => 'Which X,Y points visit, either all of them or just X+Y even or X+Y odd.',
    },
  ];

use constant class_x_negative => 0;
use constant class_y_negative => 0;

sub x_minimum {
  my ($self) = @_;
  return ($self->{'points'} eq 'odd'
          ? 1    # odd, line X=Y not included
          : 0);  # octant Y<=X so X-Y>=0
}
# points=odd X=1,Y=0
# otherwise  X=0,Y=0
*sumabsxy_minimum  = \&x_minimum;
*diffxy_minimum    = \&x_minimum;  # X>=Y so X-Y>=0
*absdiffxy_minimum = \&x_minimum;
*rsquared_minimum  = \&x_minimum;

sub absdy_minimum {
  my ($self) = @_;
  return ($self->{'points'} eq 'all'
          ? 0
          : 1);  # never same Y
}

sub dir_minimum_dxdy {
  my ($self) = @_;
  return ($self->{'points'} eq 'all'
          ? (1,0)    # all i=1 to X=1,Y=0
          : (1,1));  # odd,even always at least NE
}
# max direction SE diagonal as anything else is at most tangent to the
# eighth of a circle
use constant dir_maximum_dxdy => (1,-1); # South-East


#------------------------------------------------------------------------------

# my @n_to_x = (undef, 0);
# my @n_to_y = (undef, 0);
# my @hypot_to_n = (1);
# my @y_next_x = (1, 1);
# my @y_next_hypot = (1, 2);

sub new {
  my $self = shift->SUPER::new(@_);

  my $points = ($self->{'points'} ||= 'all');
  if ($points eq 'all') {
    $self->{'n_to_x'} = [undef];
    $self->{'n_to_y'} = [undef];
    $self->{'hypot_to_n'} = [];
    $self->{'y_next_x'} = [0];
    $self->{'y_next_hypot'} = [0];
    $self->{'x_inc'} = 1;
    $self->{'x_inc_factor'} = 2;
    $self->{'x_inc_squared'} = 1;
    $self->{'opposite_parity'} = -1;

  } elsif ($points eq 'even') {
    $self->{'n_to_x'} = [undef, 0];
    $self->{'n_to_y'} = [undef, 0];
    $self->{'hypot_to_n'} = [1];
    $self->{'y_next_x'} = [2, 1];
    $self->{'y_next_hypot'} = [4, 2];
    $self->{'x_inc'} = 2;
    $self->{'x_inc_factor'} = 4;
    $self->{'x_inc_squared'} = 4;
    $self->{'opposite_parity'} = 1;

  } elsif ($points eq 'odd') {
    $self->{'n_to_x'} = [undef];
    $self->{'n_to_y'} = [undef];
    $self->{'hypot_to_n'} = [undef];
    $self->{'y_next_x'} = [1];
    $self->{'y_next_hypot'} = [1];
    $self->{'x_inc'} = 2;
    $self->{'x_inc_factor'} = 4;
    $self->{'x_inc_squared'} = 4;
    $self->{'opposite_parity'} = 0;

  } else {
    croak "Unrecognised points option: ", $points;
  }
  return $self;
}


# at h=x^2+y^2
# step to (x+k)^2+y^2
# is add 2*x*k+k*k

sub _extend {
  my ($self) = @_;
  ### _extend() n: scalar(@{$self->{'n_to_x'}})

  my $n_to_x       = $self->{'n_to_x'};
  my $n_to_y       = $self->{'n_to_y'};
  my $hypot_to_n   = $self->{'hypot_to_n'};
  my $y_next_x     = $self->{'y_next_x'};
  my $y_next_hypot = $self->{'y_next_hypot'};

  my @y = (0);
  my $hypot = $y_next_hypot->[0];
  for (my $i = 1; $i < @$y_next_x; $i++) {
    if ($hypot == $y_next_hypot->[$i]) {
      push @y, $i;
    } elsif ($hypot > $y_next_hypot->[$i]) {
      @y = ($i);
      $hypot = $y_next_hypot->[$i];
    }
  }

  if ($y[-1] == $#$y_next_x) {
    my $y = scalar(@$y_next_x);
    my $x = $y + ($self->{'points'} eq 'odd');
    $y_next_x->[$y] = $x;
    $y_next_hypot->[$y] = $x*$x+$y*$y;
    ### assert: $y_next_hypot->[$y] == $y**2 + $y_next_x->[$y]**2
  }

  ### store: join(' ',map{"$n_to_x->[$_],$n_to_y->[$_]"} 0 .. $#$n_to_x)
  ### at n: scalar(@$n_to_x)
  ### hypot_to_n: "h=$hypot n=".scalar(@$n_to_x)

  $hypot_to_n->[$hypot] = scalar(@$n_to_x);
  push @$n_to_y, @y;
  push @$n_to_x,
    map {
      my $x = $y_next_x->[$_];
      $y_next_x->[$_] += $self->{'x_inc'};
      $y_next_hypot->[$_]
        += $self->{'x_inc_factor'} * $x + $self->{'x_inc_squared'};
      ### assert: $y_next_hypot->[$_] == $_**2 + $y_next_x->[$_]**2
      $x
    } @y;

  # ### hypot_to_n now: join(' ',map {defined($hypot_to_n->[$_]) && "h=$_,n=$hypot_to_n->[$_]"} 0 .. $#$hypot_to_n)
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### Hypot n_to_xy(): $n

  if ($n < 1) { return; }
  if (is_infinite($n)) { return ($n,$n); }

  {
    my $int = int($n);
    if ($n != $int) {
      my $frac = $n - $int;  # inherit possible BigFloat/BigRat
      my ($x1,$y1) = $self->n_to_xy($int);
      my ($x2,$y2) = $self->n_to_xy($int+1);
      my $dx = $x2-$x1;
      my $dy = $y2-$y1;
      return ($frac*$dx + $x1, $frac*$dy + $y1);
    }
  }

  my $n_to_x = $self->{'n_to_x'};
  my $n_to_y = $self->{'n_to_y'};

  while ($n > $#$n_to_x) {
    _extend($self);
  }

  return ($n_to_x->[$n], $n_to_y->[$n]);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### Hypot xy_to_n(): "$x, $y"
  ### hypot_to_n last: $#{$self->{'hypot_to_n'}}

  $x = round_nearest ($x);
  $y = round_nearest ($y);

  if ((($x%2) ^ ($y%2)) == $self->{'opposite_parity'}) {
    return undef;
  }

  my $hypot = $x*$x + $y*$y;
  if (is_infinite($hypot)) {
    return $hypot;
  }

  if ($x < 0 || $y < 0 || $y > $x) {
    ### outside first octant ...
    return undef;
  }

  my $hypot_to_n = $self->{'hypot_to_n'};
  while ($hypot > $#$hypot_to_n) {
    _extend($self);
  }

  my $n_to_x = $self->{'n_to_x'};
  my $n_to_y = $self->{'n_to_y'};

  my $n = $hypot_to_n->[$hypot];
  for (;;) {
    if ($x == $n_to_x->[$n] && $y == $n_to_y->[$n]) {
      return $n;
    }
    $n += 1;

    if ($n_to_x->[$n]**2 + $n_to_y->[$n]**2 != $hypot) {
      ### oops, hypot_to_n no good ...
      return undef;
    }
  }
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);
  if ($x1 > $x2) { ($x1,$x2) = ($x2,$x1); }
  if ($y1 > $y2) { ($y1,$y2) = ($y2,$y1); }

  if ($x2 < 0 || $y2 < 0) {
    return (1, 0);
  }

  # circle area pi*r^2, with r^2 = $x2**2 + $y2**2
  return (1, 1 + int (3.2/8 * (($x2+1)**2 + ($y2+1)**2)));
}

1;
__END__

=for stopwords Ryde Math-PlanePath hypot octant ie OEIS

=head1 NAME

Math::PlanePath::HypotOctant -- octant of points in order of hypotenuse distance

=head1 SYNOPSIS

 use Math::PlanePath::HypotOctant;
 my $path = Math::PlanePath::HypotOctant->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path visits an octant of integer points X,Y in order of their distance
from the origin 0,0.  The points are a rising triangle 0E<lt>=YE<lt>=X,

=cut

# math-image --all --path=HypotOctant --output=numbers --size=60x9

=pod

     8  |                                61
     7  |                            47  54
     6  |                        36  43  49
     5  |                    27  31  38  44
     4  |                18  23  28  34  39
     3  |            12  15  19  24  30  37
     2  |         6   9  13  17  22  29  35
     1  |     3   5   8  11  16  21  26  33
    Y=0 | 1   2   4   7  10  14  20  25  32  ...
        +---------------------------------------
         X=0  1   2   3   4   5   6   7   8


For example N=11 at X=4,Y=1 is sqrt(4*4+1*1) = sqrt(17) from the origin.
The next furthest from the origin is X=3,Y=3 at sqrt(18).

This octant is "primitive" elements X^2+Y^2 in the sense that it excludes
negative X or Y or swapped Y,X.

=head2 Equal Distances

Points with the same distance from the origin are taken in anti-clockwise
order from the X axis, which means by increasing Y.  Points with the same
distance occur when there's more than one way to express a given distance as
the sum of two squares.

Pythagorean triples give a point on the X axis and also above.  For example
5^2 == 4^2 + 3^2 has N=14 at X=5,Y=0 simply as 5^2 = 5^2 + 0 and then N=15
at X=4,Y=3 for the triple.  Both are 5 away from the origin.

Combinations like 20^2 + 15^2 == 24^2 + 7^2 occur too, and also with three
or more different ways to have the same sum distance.

=head2 Even Points

Option C<points =E<gt> "even"> visits just the even points, meaning the sum
X+Y even, so X,Y both even or both odd.

=cut

# math-image --all --path=HypotOctant,points=even --output=numbers --size=60

=pod

    12  |                                    66
    11  |     points => "even"            57
    10  |                              49    58
     9  |                           40    50
     8  |                        32    41    51
     7  |                     25    34    43
     6  |                  20    27    35    45
     5  |               15    21    29    37
     4  |            10    16    22    30    39
     3  |          7    11    17    24    33
     2  |       4     8    13    19    28    38
     1  |    2     5     9    14    23    31
    Y=0 | 1     3     6    12    18    26    36
        +---------------------------------------
        X=0  1  2  3  4  5  6  7  8  9 10 11 12

Even points can be mapped to all points by a 45 degree rotate and flip.
N=1,3,6,12,etc on the X axis here is on the X=Y diagonal of all-points.  And
conversely N=1,2,4,7,10,etc on the X=Y diagonal here is on the X axis of
all-points.

    all_X = (even_X + even_Y) / 2
    all_Y = (even_X - even_Y) / 2

    even_X = (all_X + all_Y)
    even_Y = (all_X - all_Y)

The sets of points with equal hypotenuse are the same in the even and all,
but the flip takes them in reverse order.  The first such reversal occurs at
N=14 and N=15.  In even-points they're at 7,1 and 5,5.  In all-points
they're at 5,0 and 4,3 and those two map 5,5 and 7,1, ie. the opposite way
around.

=head2 Odd Points

Option C<points =E<gt> "odd"> visits just the odd points, meaning sum X+Y
odd, so X,Y one odd the other even.

=cut

# math-image --all --path=HypotOctant,points=odd --output=numbers --size=60

=pod

    12  |                                       66
    11  |        points => "odd"             57
    10  |                                 47    58
     9  |                              39    49
     8  |                           32    41    51
     7  |                        25    33    42
     6  |                     20    26    35    45
     5  |                  14    21    29    37
     4  |               10    16    22    30    40
     3  |             7    11    17    24    34
     2  |          4     8    13    19    28    38
     1  |       2     5     9    15    23    31
    Y=0 |    1     3     6    12    18    27    36
        +------------------------------------------
        X=0  1  2  3  4  5  6  7  8  9 10 11 12 13

The X=Y diagonal is excluded because it has X+Y even.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::HypotOctant-E<gt>new ()>

=item C<$path = Math::PlanePath::HypotOctant-E<gt>new (points =E<gt> $str)>

Create and return a new hypot octant path object.  The C<points> option can be

    "all"         all integer X,Y (the default)
    "even"        only points with X+Y even
    "odd"         only points with X+Y odd

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.

For C<$n E<lt> 1> the return is an empty list, it being considered the first
point at X=0,Y=0 is N=1.

Currently it's unspecified what happens if C<$n> is not an integer.
Successive points are a fair way apart, so it may not make much sense to
give an X,Y position in between the integer C<$n>.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return an integer point number for coordinates C<$x,$y>.  Each integer N is
considered the centre of a unit square and an C<$x,$y> within that square
returns N.

=back

=head1 FORMULAS

The calculations are not very efficient currently.  For each Y row a current
X and the corresponding hypotenuse X^2+Y^2 are maintained.  To find the next
furthest a search through those hypotenuses is made seeking the smallest,
including equal smallest, which then become the next N points.

For C<n_to_xy()> an array is built in the object used for repeat
calculations.  For C<xy_to_n()> an array of hypot to N gives a the first N
of given X^2+Y^2 distance.  A search is then made through the next few N for
the case there's more than one X,Y of that hypot.

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
this path include

=over

L<http://oeis.org/A024507> (etc)

=back

    points="all"
      A024507   X^2+Y^2 of all points not on X axis or X=Y diagonal
      A024509   X^2+Y^2 of all points not on X axis
                  being integers occurring as sum of two non-zero squares,
                  with repetitions for multiple ways

    points="even"
      A036702   N on X=Y leading Diagonal
                  being count of points norm<=k

    points="odd"
      A057653   X^2+Y^2 values occurring
                  ie. odd numbers which are sum of two squares,
                  without repetitions

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::Hypot>,
L<Math::PlanePath::TriangularHypot>,
L<Math::PlanePath::PixelRings>,
L<Math::PlanePath::PythagoreanTree>

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
