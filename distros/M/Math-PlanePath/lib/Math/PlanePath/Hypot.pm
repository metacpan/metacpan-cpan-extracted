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



# A000328 Number of points of norm <= n^2 in square lattice.
#   1, 5, 13, 29, 49, 81, 113, 149, 197, 253, 317, 377, 441, 529, 613, 709, 797
#   a(n) = 1 + 4 * sum(j=0, n^2 / 4,    n^2 / (4*j+1) - n^2 / (4*j+3) )
# A014200 num points norm <= n^2, excluding 0, divided by 4
#
# A046109 num points norm == n^2
#
# A057655 num points x^2+y^2 <= n
# A014198 = A057655 - 1
#
# A004018 num points x^2+y^2 == n
#
# A057962 hypot count x-1/2,y-1/2 <= n
# is last point of each hypot in points=odd
#
# A057961 hypot count as radius increases
#

# points="square_horiz"
# points="square_vert"
# points="square_centre"
# A199015 square_centred partial sums
# 


package Math::PlanePath::Hypot;
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
# use Smart::Comments;


use constant parameter_info_array =>
  [ { name            => 'points',
      share_key       => 'points_aeo',
      display         => 'Points',
      type            => 'enum',
      default         => 'all',
      choices         => ['all','even','odd'],
      choices_display => ['All','Even','Odd'],
      description     => 'Which X,Y points visit, either all of them or just X+Y=even or odd.',
    },
    Math::PlanePath::Base::Generic::parameter_info_nstart1(),
  ];

{
  my %x_negative_at_n = (all  => 3,
                         even => 2,
                         odd  => 2);
  sub x_negative_at_n {
    my ($self) = @_;
    return $self->n_start + $x_negative_at_n{$self->{'points'}};
  }
}
{
  my %y_negative_at_n = (all  => 4,
                                        even => 3,
                                        odd  => 3);
  sub y_negative_at_n {
    my ($self) = @_;
    return $self->n_start + $y_negative_at_n{$self->{'points'}};
  }
}
sub rsquared_minimum {
  my ($self) = @_;
  return ($self->{'points'} eq 'odd'
          ? 1     # odd at X=1,Y=0
          : 0);   # even,all at X=0,Y=0
}
# points=even includes X=Y so abs(X-Y)>=0
# points=odd doesn't include X=Y so abs(X-Y)>=1
*absdiffxy_minimum = \&rsquared_minimum;
*sumabsxy_minimum  = \&rsquared_minimum;

use constant turn_any_right => 0; # always left or straight
sub turn_any_straight {
  my ($self) = @_;
  return ($self->{'points'} ne 'all');  # points=all is left always
}


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);

  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }

  my $points = ($self->{'points'} ||= 'all');
  if ($points eq 'all') {
    $self->{'n_to_x'} = [0];
    $self->{'n_to_y'} = [0];
    $self->{'hypot_to_n'} = [0];
    $self->{'y_next_x'} = [1, 1];
    $self->{'y_next_hypot'} = [1, 2];
    $self->{'x_inc'} = 1;
    $self->{'x_inc_factor'} = 2;
    $self->{'x_inc_squared'} = 1;
    $self->{'y_factor'} = 2;
    $self->{'opposite_parity'} = -1;

  } elsif ($points eq 'even') {
    $self->{'n_to_x'} = [0];
    $self->{'n_to_y'} = [0];
    $self->{'hypot_to_n'} = [0];
    $self->{'y_next_x'} = [2, 1];
    $self->{'y_next_hypot'} = [4, 2];
    $self->{'x_inc'} = 2;
    $self->{'x_inc_factor'} = 4;
    $self->{'x_inc_squared'} = 4;
    $self->{'y_factor'} = 2;
    $self->{'opposite_parity'} = 1;

  } elsif ($points eq 'odd') {
    $self->{'n_to_x'} = [];
    $self->{'n_to_y'} = [];
    $self->{'hypot_to_n'} = [];
    $self->{'y_next_x'} = [1];
    $self->{'y_next_hypot'} = [1];
    $self->{'x_inc'} = 2;
    $self->{'x_inc_factor'} = 4;
    $self->{'x_inc_squared'} = 4;
    $self->{'y_factor'} = 2;
    $self->{'opposite_parity'} = 0;

  } elsif ($points eq 'square_centred') {
    $self->{'n_to_x'} = [];
    $self->{'n_to_y'} = [];
    $self->{'hypot_to_n'} = [];
    $self->{'y_next_x'} = [undef,1];
    $self->{'y_next_hypot'} = [undef,2];
    $self->{'x_inc'} = 2;
    $self->{'x_inc_factor'} = 4;  # ((x+2)^2 - x^2) = 4*x+4
    $self->{'x_inc_squared'} = 4;
    $self->{'y_start'} = 1;
    $self->{'y_inc'} = 2;
    $self->{'opposite_parity'} = -1;

  } else {
    croak "Unrecognised points option: ", $points;
  }
  return $self;
}

sub _extend {
  my ($self) = @_;
  ### _extend() n: scalar(@{$self->{'n_to_x'}})
  ### y_next_x: $self->{'y_next_x'}

  my $n_to_x       = $self->{'n_to_x'};
  my $n_to_y       = $self->{'n_to_y'};
  my $hypot_to_n   = $self->{'hypot_to_n'};
  my $y_next_x     = $self->{'y_next_x'};
  my $y_next_hypot = $self->{'y_next_hypot'};
  my $y_start      = $self->{'y_start'} || 0;
  my $y_inc        = $self->{'y_inc'} || 1;

  # set @y to the Y with the smallest $y_next_hypot[$y], and if there's some
  # Y's with equal smallest hypot then all those Y's
  my @y = ($y_start);
  my $hypot = $y_next_hypot->[$y_start] || 99;
  for (my $y = $y_start+$y_inc; $y < @$y_next_x; $y += $y_inc) {
    if ($hypot == $y_next_hypot->[$y]) {
      push @y, $y;
    } elsif ($hypot > $y_next_hypot->[$y]) {
      @y = ($y);
      $hypot = $y_next_hypot->[$y];
    }
  }

  ### chosen y list: @y

  # if the endmost of the @$y_next_x, @$y_next_hypot arrays are used then
  # extend them by one
  if ($y[-1] == $#$y_next_x) {
    ### grow y_next_x ...
    my $y = $#$y_next_x + $y_inc;
    my $x = $y + ($self->{'points'} eq 'odd');
    $y_next_x->[$y] = $x;
    $y_next_hypot->[$y] = $x*$x+$y*$y;
    ### $y_next_x
    ### $y_next_hypot
    ### assert: $y_next_hypot->[$y] == $y**2 + $x*$x
  }

  # @x is the $y_next_x[$y] for each of the @y smallests, and step those
  # selected elements next X and hypot for that new X,Y
  my @x = map {
    my $y = $_;
    my $x = $y_next_x->[$y];
    $y_next_x->[$y] += $self->{'x_inc'};
    $y_next_hypot->[$y]
      += $self->{'x_inc_factor'} * $x + $self->{'x_inc_squared'};
    ### assert: $y_next_hypot->[$y] == ($x+$self->{'x_inc'})**2 + $y**2
    $x
  } @y;
  ### $hypot
  ### base octant: join(' ',map{"$x[$_],$y[$_]"} 0 .. $#x)

  # transpose X,Y to Y,X
  {
    my @base_x = @x;
    my @base_y = @y;
    unless ($y[0]) { # no transpose of x,0
      shift @base_x;
      shift @base_y;
    }
    if ($x[-1] == $y[-1]) { # no transpose of x,x
      pop @base_x;
      pop @base_y;
    }
    push @x, reverse @base_y;
    push @y, reverse @base_x;
  }
  ### with transpose q1: join(' ',map{"$x[$_],$y[$_]"} 0 .. $#x)

  # rotate +90 quadrant 1 into quadrant 2
  {
    my @base_y = @y;
    push @y, @x;
    push @x, map {-$_} @base_y;
  }
  ### with rotate q2: join(' ',map{"$x[$_],$y[$_]"} 0 .. $#x)

  # rotate +180 quadrants 1+2 into quadrants 2+3
  push @x, map {-$_} @x;
  push @y, map {-$_} @y;

  ### store: join(' ',map{"$x[$_],$y[$_]"} 0 .. $#x)
  ### at n: scalar(@$n_to_x)
  ### hypot_to_n: "h=$hypot n=".scalar(@$n_to_x)
  $hypot_to_n->[$hypot] = scalar(@$n_to_x);
  push @$n_to_x, @x;
  push @$n_to_y, @y;

  # ### hypot_to_n now: join(' ',map {defined($hypot_to_n->[$_]) && "h=$_,n=$hypot_to_n->[$_]"} 0 .. $#$hypot_to_n)


  # my $x = $y_next_x->[0];
  #
  # $x = $y_next_x->[$y];
  # $n_to_x->[$next_n] = $x;
  # $n_to_y->[$next_n] = $y;
  # $xy_to_n{"$x,$y"} = $next_n++;
  #
  # $y_next_x->[$y]++;
  # $y_next_hypot->[$y] = $y*$y + $y_next_x->[$y]**2;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### Hypot n_to_xy(): $n

  $n = $n - $self->{'n_start'};  # starting $n==0, warn if $n==undef
  if ($n < 0) { return; }
  if (is_infinite($n)) { return ($n,$n); }

  my $int = int($n);
  $n -= $int;  # fraction part

  my $n_to_x = $self->{'n_to_x'};
  my $n_to_y = $self->{'n_to_y'};

  while ($int >= $#$n_to_x) {
    _extend($self);
  }

  my $x = $n_to_x->[$int];
  my $y = $n_to_y->[$int];
  return ($x + $n * ($n_to_x->[$int+1] - $x),
          $y + $n * ($n_to_y->[$int+1] - $y));
}

sub xy_is_visited {
  my ($self, $x, $y) = @_;

  if ($self->{'opposite_parity'} >= 0) {
    $x = round_nearest ($x);
    $y = round_nearest ($y);
    if ((($x%2) ^ ($y%2)) == $self->{'opposite_parity'}) {
      return 0;
    }
  }
  if ($self->{'points'} eq 'square_centred') {
    unless (($y%2) && ($x%2)) {
      return 0;
    }
  }
  return 1;
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
  if ($self->{'points'} eq 'square_centred') {
    unless (($y%2) && ($x%2)) {
      return undef;
    }
  }

  my $hypot = $x*$x + $y*$y;
  if (is_infinite($hypot)) {
    ### infinity
    return undef;
  }

  my $n_to_x = $self->{'n_to_x'};
  my $n_to_y = $self->{'n_to_y'};

  my $hypot_to_n = $self->{'hypot_to_n'};
  while ($hypot > $#$hypot_to_n) {
    _extend($self);
  }

  my $n = $hypot_to_n->[$hypot];
  for (;;) {
    if ($x == $n_to_x->[$n] && $y == $n_to_y->[$n]) {
      return $n + $self->{'n_start'};
    }
    $n += 1;

    if ($n_to_x->[$n]**2 + $n_to_y->[$n]**2 != $hypot) {
      ### oops, hypot_to_n no good ...
      return undef;
    }
  }

  # if ($x < 0 || $y < 0) {
  #   return undef;
  # }
  # my $h = $x*$x + $y*$y;
  #
  # while ($y_next_x[$y] <= $x) {
  #   _extend($self);
  # }
  # return $xy_to_n{"$x,$y"};
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;

  $x1 = abs (round_nearest ($x1));
  $y1 = abs (round_nearest ($y1));
  $x2 = abs (round_nearest ($x2));
  $y2 = abs (round_nearest ($y2));

  if ($x1 > $x2) { ($x1,$x2) = ($x2,$x1); }
  if ($y1 > $y2) { ($y1,$y2) = ($y2,$y1); }

  # circle area pi*r^2, with r^2 = $x2**2 + $y2**2
  return ($self->{'n_start'},
          $self->{'n_start'} + int (3.2 * (($x2+1)**2 + ($y2+1)**2)));
}

1;
__END__




# Quadrant style ...
#
#      9      73  75  79  83  85
#      8      58  62  64  67  71  81  ...
#      7      45  48  52  54  61  69  78  86
#      6      35  37  39  43  50  56  65  77  88
#      5      26  28  30  33  41  47  55  68  80
#      4      17  19  22  25  31  40  49  60  70  84
#      3      11  13  15  20  24  32  42  53  66  82
#      2       6   8   9  14  21  29  38  51  63  76
#      1       3   4   7  12  18  27  36  46  59  74
#     Y=0      1   2   5  10  16  23  34  44  57  72
#
#             X=0  1   2   3   4   5   6   7   8   9  ...
#
# For example N=37 is at X=1,Y=6 which is sqrt(1*1+6*6) = sqrt(37) from the
# origin.  The next closest to the origin is X=6,Y=2 at sqrt(40).  In general
# it's the sums of two squares X^2+Y^2 taken in order from smallest to biggest.
#
# Points X,Y and swapped Y,X are the same distance from the origin.  The one
# with bigger X is taken first, then the swapped Y,X (as long as X!=Y).  For
# example N=21 is X=4,Y=2 and N=22 is X=2,Y=4.



=for stopwords Ryde Math-PlanePath ie hypot octant onwards OEIS hypots

=head1 NAME

Math::PlanePath::Hypot -- points in order of hypotenuse distance

=head1 SYNOPSIS

 use Math::PlanePath::Hypot;
 my $path = Math::PlanePath::Hypot->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path visits integer points X,Y in order of their distance from the
origin 0,0, or anti-clockwise from the X axis among those of equal distance,

=cut

# math-image --expression='i<=89?i:0' --path=Hypot --output=numbers --size=79

=pod

                    84  73  83                         5
            74  64  52  47  51  63  72                 4
        75  59  40  32  27  31  39  58  71             3
        65  41  23  16  11  15  22  38  62             2
    85  53  33  17   7   3   6  14  30  50  82         1
    76  48  28  12   4   1   2  10  26  46  70    <- Y=0
    86  54  34  18   8   5   9  21  37  57  89        -1
        66  42  24  19  13  20  25  45  69            -2
        77  60  43  35  29  36  44  61  81            -3
            78  67  55  49  56  68  80                -4
                    87  79  88                        -5

                         ^
    -5  -4  -3  -2  -1  X=0  1   2   3   4   5

For example N=58 is at X=4,Y=-1 is sqrt(4*4+1*1) = sqrt(17) from the origin.
The next furthest from the origin is X=3,Y=3 at sqrt(18).

See C<TriangularHypot> for points in order of X^2+3*Y^2, or C<DiamondSpiral>
and C<PyrmaidSides> in order of plain sum X+Y.

=head2 Equal Distances

Points with the same distance are taken in anti-clockwise order around from
the X axis.  For example X=3,Y=1 is sqrt(10) from the origin, as are the
swapped X=1,Y=3, and X=-1,Y=3 etc in other quadrants, for a total 8 points
N=30 to N=37 all the same distance.

When one of X or Y is 0 there's no negative, so just four negations like
N=10 to 13 points X=2,Y=0 through X=0,Y=-2.  Or on the diagonal X==Y there's
no swap, so just four like N=22 to N=25 points X=3,Y=3 through X=3,Y=-3.

There can be more than one way for the same distance to arise.
A Pythagorean triple like 3^2 + 4^2 == 5^2 has 8 points from the 3,4, then 4
points from the 5,0 giving a total 12 points N=70 to N=81.  Other
combinations like 20^2 + 15^2 == 24^2 + 7^2 occur too, and also with more
than two different ways to have the same sum.

=head2 Multiples of 4

The first point of a given distance from the origin is either on the X axis
or somewhere in the first octant.  The row Y=1 just above the axis is the
first of its equals from XE<gt>=2 onwards, and similarly further rows for
big enough X.

There's always a multiple of 4 many points with the same distance so the
first point has N=4*k+2, and similarly on the negative X side N=4*j, for
some k or j.  If you plot the prime numbers on the path then those even N's
(composites) are gaps just above the positive X axis, and on or just below
the negative X axis.

=head2 Circle Lattice

Gauss's circle lattice problem asks how many integer X,Y points there are
within a circle of radius R.

The points on the X axis N=2,10,26,46, etc are the first for which
X^2+Y^2==R^2 (integer X==R).  Adding option C<n_start=E<gt>0> to make them
each 1 less gives the number of points strictly inside, ie. X^2+Y^2 E<lt>
R^2.

The last point satisfying X^2+Y^2==R^2 is either in the octant below the X
axis, or is on the negative Y axis.  Those N's are the number of points
X^2+Y^2E<lt>=R^2, Sloane's A000328.

When that A000328 sequence is plotted on the path a straight line can be
seen in the fourth quadrant extending down just above the diagonal.  It
arises from multiples of the Pythagorean 3^2 + 4^2, first X=4,Y=-3, then
X=8,Y=-6, etc X=4*k,Y=-3*k.  But sometimes the multiple is not the last
among those of that 5*k radius, so there's gaps in the line.  For example
20,-15 is not the last since because 24,-7 is also 25 away from the origin.

=head2 Even Points

Option C<points =E<gt> "even"> visits just the even points, meaning the sum
X+Y even, so X,Y both even or both odd.

=cut

# math-image --expression='i<70?i:0' --path=Hypot,points=even --output=numbers --size=79

=pod

    points => "even"

          52    40    39    51             5
       47    32    23    31    46          4
    53    27    16    15    26    50       3
       33    11     7    10    30          2
    41    17     3     2    14    38       1
       24     8     1     6    22     <- Y=0
    42    18     4     5    21    45      -1
       34    12     9    13    37         -2
    54    28    19    20    29    57      -3
       48    35    25    36    49         -4
          55    43    44    56            -5

                    ^
    -5 -4 -3 -2 -1 X=0 1  2  3  4  5

Even points can be mapped to all points by a 45 degree rotate and flip.
N=1,6,22,etc on the X axis here is on the X=Y diagonal of all-points.  And
conversely N=1,2,10,26,etc on the X=Y diagonal here is the X axis of
all-points.

The sets of points with equal hypotenuse are the same in the even and all,
but the flip takes them in a reversed order.

=head2 Odd Points

Option C<points =E<gt> "odd"> visits just the odd points, meaning sum X+Y
odd, so X,Y one odd the other even.

=cut

# math-image --expression='i<=76?i:0' --path=Hypot,points=odd --output=numbers --size=78x30

=pod

    points => "odd"

                                             
             71    55    54    70                6
          63    47    36    46    62             5  
       64    37    27    26    35    61          4  
    72    38    19    14    18    34    69       3  
       48    20     7     6    17    45          2  
    56    28     8     2     5    25    53       1  
       39    15     3  +  1    13    33     <- Y=0  
    57    29     9     4    12    32    60      -1  
       49    21    10    11    24    52         -2  
    73    40    22    16    23    44    76      -3  
       65    41    30    31    43    68         -4  
          66    50    42    51    67            -5  
             74    58    59    75               -6
                                             
                       ^
    -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6

Odd points can be mapped to all points by a 45 degree rotate and a shift
X-1,Y+1 to put N=1 at the origin.  The effect of that shift is as if the
hypot measure in "all" points was (X-1/2)^2+(Y-1/2)^2 and for that reason
the sets of points with equal hypots are not the same in odd and all.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::Hypot-E<gt>new ()>

=item C<$path = Math::PlanePath::Hypot-E<gt>new (points =E<gt> $str), n_start =E<gt> $n>

Create and return a new hypot path object.  The C<points> option can be

    "all"         all integer X,Y (the default)
    "even"        only points with X+Y even
    "odd"         only points with X+Y odd

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.

For C<$n E<lt> 1> the return is an empty list, it being considered the first
point at X=0,Y=0 is N=1.

Currently it's unspecified what happens if C<$n> is not an integer.
Successive points are a fair way apart, so it may not make much sense to say
give an X,Y position in between the integer C<$n>.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return an integer point number for coordinates C<$x,$y>.  Each integer N is
considered the centre of a unit square and an C<$x,$y> within that square
returns N.

For "even" and "odd" options only every second square in the plane has an N
and if C<$x,$y> is a position not covered then the return is C<undef>.

=back

=head1 FORMULAS

The calculations are not particularly efficient currently.  Private arrays
are built similar to what's described for C<HypotOctant>, but with
replication for negative and swapped X,Y.

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
this path include

=over

L<http://oeis.org/A051132> (etc)

=back

    points="all", n_start=0
      A051132    N on X axis, being count points norm < X^2

    points="odd"
      A005883    count of points with norm==4*n+1

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::HypotOctant>,
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
