# Copyright 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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


package Math::PlanePath::DiagonalsOctant;
use 5.004;
use strict;
use Carp 'croak';

use vars '$VERSION', '@ISA';
$VERSION = 126;
use Math::PlanePath;
*_sqrtint = \&Math::PlanePath::_sqrtint;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'round_nearest';

# uncomment this to run the ### lines
#use Smart::Comments;


use constant class_x_negative => 0;
use constant class_y_negative => 0;
use constant n_frac_discontinuity => .5;

use constant parameter_info_array =>
  [ { name        => 'direction',
      share_key   => 'direction_downup',
      display     => 'Direction',
      type        => 'enum',
      default     => 'down',
      choices     => ['down','up'],
      choices_display => ['Down','Up'],
      description => 'Number points downwards or upwards along the diagonals.',
    },
    Math::PlanePath::Base::Generic::parameter_info_nstart1(),
  ];

use constant diffxy_maximum => 0; # octant X<=Y so X-Y<=0

sub dx_minimum {
  my ($self) = @_;
  return ($self->{'direction'} eq 'up' ? -1 : undef);
}
sub dx_maximum {
  my ($self) = @_;
  return ($self->{'direction'} eq 'down' ? 1 : undef);
}

sub dy_minimum {
  my ($self) = @_;
  return ($self->{'direction'} eq 'down' ? -1 : undef);
}
sub dy_maximum {
  my ($self) = @_;
  return ($self->{'direction'} eq 'up' ? 1 : undef);
}

sub absdy_minimum {
  my ($self) = @_;
  return ($self->{'direction'} eq 'down'
          ? 1   # 'down' always changes
          : 0); # 'up' N=2 dY=0
}

use constant dsumxy_minimum => 0; # advancing diagonals
use constant dsumxy_maximum => 1;
sub ddiffxy_minimum {
  my ($self) = @_;
  return ($self->{'direction'} eq 'down'
          ? undef  # "down" jumps back unlimited at bottom
          : -2);   # NW diagonal
}
sub ddiffxy_maximum {
  my ($self) = @_;
  return ($self->{'direction'} eq 'down'
          ? 2       # SE diagonal
          : undef); # "up" jumps down unlimited at top
}

sub dir_minimum_dxdy {
  my ($self) = @_;
  return ($self->{'direction'} eq 'down'
          ? (0,1)   # vertical N=1to2
          : (1,0)); # horizontal N=2to3
}
sub dir_maximum_dxdy {
  my ($self) = @_;
  return ($self->{'direction'} eq 'down'
          ? (1,-1)   # South-East diagonal
          : (2,-1)); # N=6 to N=7
}


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);
  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }

  my $direction = ($self->{'direction'} ||= 'down');
  if (! ($direction eq 'up' || $direction eq 'down')) {
    croak "Unrecognised direction option: ", $direction;
  }

  return $self;
}

# start from integers
# [  1,   2,   3,    4, 5 ],
# [ 1, 3, 7, 13, 21 ]
# N = (d^2 - d + 1)
#   = ($d**2 - $d + 1)
#   = (($d - 1)*$d + 1)
#
# starting 0.5 back from the odd Y, numbering d=1 for the Y=1
# [ 1,    2,    3,    4,     5 ],
# [ 2-.5, 5-.5, 10-.5, 17-.5, 26-.5 ]  # squares +0.5
# N = (d^2 + 1/2)
#   = ($d**2 + 1/2)
#   = ($d**2 + 1/2)
# d = 0 + sqrt(1 * $n + -1/2)
#   = sqrt($n -1/2)
#   = sqrt(4*$n-2)/2
#
#   9 | 26
#   8 | 21
#   7 | 17 22
#   6 | 13 18 23
#   5 | 10 14 19 24
#   4 |  7 11 15 20 25
#   3 |  5  8 12 16
#   2 |  3  6  9
#   1 |  2  4
# Y=0 |  1
#     +-------------
#
sub n_to_xy {
  my ($self, $n) = @_;
  ### DiagonalsOctant n_to_xy(): "$n   ".(ref $n || '')

  # adjust to N=1 at origin X=0,Y=0
  $n = $n - $self->{'n_start'} + 1;

  my $d = int(4*$n)-2;   # for sqrt
  if ($d < 0) {
    ### nothing at N < 0.5 ...
    return;
  }
  $d = int( _sqrtint($d)/2 );
  ### $d

  # remainder positive or negative relative to the start of the following
  # diagonal
  #
  $n -= $d*($d+1) + 1;
  ### remainder: $n

  # $n first in formulas to preserve n=BigFloat when d=integer is BigInt
  #
  if ($self->{'direction'} eq 'up') {
    if (2*$n >= -1) {
      return (-$n + $d,
              $n + $d);
    } else {
      return (-$n - 1,
              $n + 2*$d);
    }
  } else {
    if (2*$n >= -1) {
      # stripe of d+1 many points starting at Y even, eg. N=13
      return ($n,
              -$n + 2*$d);
    } else {
      # stripe of d many points starting at Y odd, eg. N=10
      return ($n + $d,
              -$n + $d - 1);
    }
  }
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### xy_to_n(): $x, $y

  $x = round_nearest ($x);
  if ($self->{'direction'} eq 'up') {
    $y = round_nearest ($y);
  } else {
    $y = - round_nearest (- $y);
  }

  ### rounded
  ### $x
  ### $y

  if ($y < 0 || $x < 0 || $x > $y) {
    ### outside upper octant ...
    return undef;
  }

  if ($self->{'direction'} eq 'up') {
    my $d = $x + $y + 2;
    ### $d
    return ($d*$d - ($d % 2))/4 - $x + $self->{'n_start'} - 1;
  } else {
    my $d = $x + $y + 1;
    ### $d
    return ($d*$d - ($d % 2))/4 + $x + $self->{'n_start'};
  }
}

# exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;

  $x1 = round_nearest ($x1);
  $x2 = round_nearest ($x2);
  if ($self->{'direction'} eq 'up') {
    $y1 = round_nearest ($y1);
    $y2 = round_nearest ($y2);
  } else {
    $y1 = - round_nearest (- $y1);
    $y2 = - round_nearest (- $y2);
  }

  # bottom-left and top-right same as Math::PlanePath::Diagonals, but also
  # brining $y1 up to within octant

  if ($x1 > $x2) { ($x1,$x2) = ($x2,$x1); }
  if ($y1 > $y2) { ($y1,$y2) = ($y2,$y1); }

  #       x2  |  /
  #  -----+   | /
  #       |   |/ +----
  #  -----+   +  |x1,y2
  #
  if ($x2 < 0 || $y2 < 0 || $x1 > $y2) {
    ### entirely outside upper octant, no range ...
    return (1, 0);
  }

  #     |
  #   +----   /
  #   | |    /
  #   +---- /
  # x1  | /
  #     +
  # increase x1 to within octant
  if ($x1 < 0) { $x1 *= 0; }  # zero by $x1*0 to preserve bignum

  #  |   | /
  #  |   |/
  #  |  /|
  #  | / +----y1
  #  +   x1
  # increase y1 so bottom-left x1,y1 is within octant
  if ($y1 < $x1) { $y1 = $x1; }

  #  |      /  x2
  #  | --------+
  #  |    /    |
  #  |  -------+
  #  | /
  #  +
  # decrease x2 so top-right  is within octant
  if ($x2 > $y2) { $x2 = $y2; }

  # exact range bottom left to top right
  return ($self->xy_to_n ($x1,$y1),
          $self->xy_to_n ($x2,$y2));
}

1;
__END__

=for stopwords PlanePath Ryde Math-PlanePath pronic sqrt eg flonums N-Nstart Nrem octant ie OEIS Nstart

=head1 NAME

Math::PlanePath::DiagonalsOctant -- points in diagonal stripes for an eighth of the plane

=head1 SYNOPSIS

 use Math::PlanePath::DiagonalsOctant;
 my $path = Math::PlanePath::DiagonalsOctant->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path follows successive diagonals downwards from the Y axis down to the
X=Y centre line, traversing the eighth of the plane on and above X=Y.

=cut

# math-image --path=DiagonalsOctant --all --output=numbers

=pod

    8 |  21 27 33 40 47 55 63 72 81
      |    \  \  \  \  \  \  \
    7 |  17 22 28 34 41 48 56 64
      |    \  \  \  \  \  \
    6 |  13 18 23 29 35 42 49
      |    \  \  \  \  \
    5 |  10 14 19 24 30 36
      |    \  \  \  \
    4 |   7 11 15 20 25
      |    \  \  \
    3 |   5  8 12 16
      |    \  \
    2 |   3  6  9
      |    \
    1 |   2  4
      |
  Y=0 |   1
      + ----------------------------
        X=0  1  2  3  4  5  6  7  8

X<Square numbers>N=1,4,9,16,etc on the X=Y leading diagonal are the perfect
squares.  N=2,6,12,20,etc at the ends of the other diagonals are the
X<Pronic numbers>pronic numbers k*(k+1).

Incidentally "octant" usually refers to an eighth of a 3-dimensional
coordinate space.  Since C<PlanePath> is only 2 dimensions there's no
confusion and at the risk of abusing nomenclature half a quadrant is
reckoned as an "octant".

=head2 Pyramid Rows

Taking two diagonals running from k^2+1 to (k+1)^2 is the same as a row of
the step=2 C<PyramidRows> (see L<Math::PlanePath::PyramidRows>).  Each
endpoint is the same, but here it's two diagonals instead of one row.  For
example in the C<PyramidRows> the Y=3 row runs from N=10 to N=16 ending at
X=3,Y=3.  Here that's in two diagonals N=10 to N=12 and then N=13 to N=16,
and that N=16 endpoint is the same X=3,Y=3.

=head2 Direction

Option C<direction =E<gt> 'up'> reverses the order within each diagonal and
counts upward from the centre to the Y axis.

=cut

# math-image --path=DiagonalsOctant,direction=up  --all --output=numbers_dash

=pod

    8 |  25 29 34 39 45 51 58 65 73 
      |    \  \  \  \  \  \  \
    7 |  20 24 28 33 38 44 50 57
      |    \  \  \  \  \  \
    6 |  16 19 23 27 32 37 43
      |    \  \  \  \  \
    5 |  12 15 18 22 26 31
      |    \  \  \  \
    4 |   9 11 14 17 21             direction => "up"
      |    \  \  \
    3 |   6  8 10 13
      |    \  \
    2 |   4  5  7
      |    \
    1 |   2  3
      |
  Y=0 |   1
      +---------------------------
        X=0  1  2  3  4  5  6  7  8

In this arrangement N=1,2,4,6,9,etc on the Y axis are alternately the
squares and the pronic numbers.  The squares are on even Y and pronic on
odd Y.

=head2 N Start

The default is to number points starting N=1 as shown above.  An optional
C<n_start> can give a different start, in the same diagonals sequence.  For
example to start at 0,

=cut

# math-image --path=DiagonalsOctant,n_start=0 --all --output=numbers --size=35x5
# math-image --path=DiagonalsOctant,n_start=0,direction=up --all --output=numbers --size=35x5

=pod

    n_start => 0                    n_start=>0
    direction => "down"             direction=>"up"

      6  | 12                        | 15
      5  |  9 13                     | 11 14
      4  |  6 10 14                  |  8 10 13
      3  |  4  7 11 15               |  5  7  9 12
      2  |  2  5  8                  |  3  4  6
      1  |  1  3                     |  1  2
    Y=0  |  0                        |  0
         +--------------             +--------------
          X=0  1  2  3                X=0  1  2  3

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::DiagonalsOctant-E<gt>new ()>

=item C<$path = Math::PlanePath::DiagonalsOctant-E<gt>new (direction =E<gt> $str, n_start =E<gt> $n)>

Create and return a new path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.

For C<$n E<lt> 0.5> the return is an empty list, it being considered the
path begins at 1.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return the point number for coordinates C<$x,$y>.  C<$x> and C<$y> are
each rounded to the nearest integer, which has the effect of treating each
point C<$n> as a square of side 1.

=item C<($n_lo, $n_hi) = $path-E<gt>rect_to_n_range ($x1,$y1, $x2,$y2)>

The returned range is exact, meaning C<$n_lo> and C<$n_hi> are the smallest
and biggest in the rectangle.

=back

=head1 FORMULAS

=head2 N to X,Y

To break N into X,Y it's convenient to take two diagonals at a time, since
the length then changes by 1 each pair making a quadratic.  Starting at each
X=0,Y=odd just after perfect square N allows just a sqrt.

    Nstart = d*d+1

where d numbers diagonal pairs, eg. d=3 for X=0,Y=5 going down.  This is
easily reversed as

    d = floor sqrt(N-1)

The code reckons the start of the diagonal as 0.5 further back, so that
N=9.5 is at X=-.5,Y=5.5.  To do that d is formed as

    d = floor sqrt(N-0.5)
      = int( sqrt(int(4*$n)-2)/2 )

Taking /2 out of the sqrt helps with C<Math::BigInt> which circa Perl 5.14
doesn't inter-operate with flonums very well.

In any case N-Nstart is an offset into two diagonals, the first of length d
many points and the second d+1.  For example d=3 starting Y=5 for points
N=10,11,12 followed by Y=6 N=13,14,15,16.

The formulas are simplified by calculating a remainder relative to the
second diagonal, so it's negative for the first and positive for the second,

    Nrem = N - (d*(d+1)+1)

d*(d+1)+1 is 1 past the pronic numbers when end each first diagonal, as
described above.  In any case for example d=3 is relative to N=13 making
Nrem=-3,-2,-1 or Nrem=0,1,2,3.

To include the preceding 0.5 in the second diagonal simply means reckoning
NremE<gt>=-0.5 as belonging to the second.  In that base

    if Nrem >= -0.5
      X = Nrem            # direction="down"
      Y = 2*d - Nrem
    else
      X = Nrem + d
      Y = d - Nrem - 1

For example N=15 Nrem=1 is the first case, X=1, Y=2*3-1=5.  Or N=11 Nrem=-2
the second X=-2+3=1, Y=3-(-2)-1=4.

For "up" direction the Nrem and d are the same, but the coordinate
directions reverse.

    if Nrem >= -0.5
      X = d - Nrem        # direction="up"
      Y = d + Nrem
    else
      X = -Nrem - 1
      Y = 2d + Nrem

Another way is to reckon Nstart from the X=0,Y=even diagonals, which is then
two diagonals of the same length and d formed by a sqrt inverting a pronic
Nstart=d*(d+1).

=head2 Rectangle to N Range

Within each row increasing X is increasing N, and in each column increasing
Y is increasing N.  This is so in both "down" and "up" arrangements.  On
that basis in a rectangle the lower left corner is the minimum N and the
upper right is the maximum N.

If the rectangle is partly outside the covered octant then the corners must
be shifted to put them in range, ie. trim off any rows or columns entirely
outside the rectangle.  For the lower left this means,

      |  |    /
      |  |   /
      +--------          if x1 < 0 then x1 = 0
    x1   | /             increase x1 to within octant
         |/
         +

         |  |/
         |  |            if y1 < x1 then y1 = x1
         | /|            increase y1 to bottom-left within octant
         |/ +----y1
         +  x1

And for the top right,

         |    /  x2
         | ------+ y2    if x2 > y2 then x2 = y2
         |  /    |       decrease x2 so top-right within octant
         | /     |         (the end of the y2 row)
         |/
         +

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
this path include

=over

L<http://oeis.org/A055087> (etc)

=back

    direction=down
      A002620    N at end each run X=k,Y=k and X=k,Y=k+1
    direction=down, n_start=0
      A055087    X coord, runs 0 to k twice
      A082375    Y-X, runs k to 0 or 1 stepping by 2
      A005563    N on X=Y diagonal, X*(X+2)

    direction=up
      A002620    N on Y axis, end of each run, quarter squares
    direction=up, n_start=0
      A024206    N on Y axis (starting from n=1 is Y=0, so Y=n-1)
      A014616    N in column X=1 (is Y axis N-1, from N=3)
      A002378    N on X=Y diagonal, pronic X*(X+1)

    either direction, n_start=0
      A055086    X+Y, k repeating floor(k/2)+1 times

    A004652      N start and end of each even-numbered diagonal

    permutations
      A056536     N of PyramidRows in DiagonalsOctant order
      A091995      with DiagonalsOctant direction=up
      A091018      N-1, ie. starting from 0
      A090894      N-1 and DiagonalsOctant direction=up

      A056537     N of DiagonalsOctant at X,Y in PyramidRows order
                   inverse of A056536

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::Diagonals>,
L<Math::PlanePath::DiagonalsAlternating>,
L<Math::PlanePath::PyramidRows>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
