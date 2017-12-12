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


# Leading diagonal 2,8,18 = 2*d^2
# cf A185787 lists numerous seqs for rows,columns,diagonals


package Math::PlanePath::Diagonals;
use 5.004;
use strict;
use Carp 'croak';
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 125;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'round_nearest';
*_sqrtint = \&Math::PlanePath::_sqrtint;

# uncomment this to run the ### lines
# use Smart::Comments;

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
    { name        => 'x_start',
      display     => 'X start',
      type        => 'integer',
      default     => 0,
      width       => 3,
      description => 'Starting X coordinate.',
    },
    { name        => 'y_start',
      display     => 'Y start',
      type        => 'integer',
      default     => 0,
      width       => 3,
      description => 'Starting Y coordinate.',
    },
  ];

sub x_minimum {
  my ($self) = @_;
  return $self->{'x_start'};
}
sub y_minimum {
  my ($self) = @_;
  return $self->{'y_start'};
}

sub dx_minimum {
  my ($self) = @_;
  return ($self->{'direction'} eq 'down'
          ? undef  # down jumps back unlimited at bottom
          : -1);   # up at most -1 across
}
sub dx_maximum {
  my ($self) = @_;
  return ($self->{'direction'} eq 'down'
          ? 1       # down at most +1 across
          : undef); # up jumps back across unlimited at top
}

sub dy_minimum {
  my ($self) = @_;
  return ($self->{'direction'} eq 'down'
          ? -1      # down at most -1
          : undef); # up jumps down unlimited at top
}
sub dy_maximum {
  my ($self) = @_;
  return ($self->{'direction'} eq 'down'
          ? undef  # down jumps up unlimited at bottom
          : 1);    # up at most +1
}

sub absdx_minimum {
  my ($self) = @_;
  return ($self->{'direction'} eq 'down'
          ? 0   # N=1 dX=0,dY=1
          : 1); # otherwise always changes
}
sub absdy_minimum {
  my ($self) = @_;
  return ($self->{'direction'} eq 'down'
          ? 1   # otherwise always changes
          : 0); # N=1 dX=1,dY=0
}

# within diagonal X+Y=k is dSum=0
# end of diagonal X=Xstart+k Y=Ystart
#             to  X=Xstart   Y=Ystart+k+1
# is (Xstart + Ystart+k+1) - (Xstart+k + Ystart) = 1 always, to next diagonal
#
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
          ? (0,1)   # North, vertical at N=1
          : (1,0)); # East,  horiz at N=1
}
sub dir_maximum_dxdy {
  my ($self) = @_;
  return ($self->{'direction'} eq 'down'
          ? (1,-1)    # South-East at N=2
          : (2,-1));  # ESE        at N=3
}

# If Xstart>0 or Ystart>0 then the origin is not reached.
sub rsquared_minimum {
  my ($self) = @_;
  return ((  $self->{'x_start'} > 0 ? $self->{'x_start'}**2 : 0)
          + ($self->{'y_start'} > 0 ? $self->{'y_start'}**2 : 0));
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

  $self->{'x_start'} ||= 0;
  $self->{'y_start'} ||= 0;
  return $self;
}

# start each diagonal at 0.5 earlier than the integer point
#   d = [    0,   1,   2,   3,   4 ]
#   n = [ -0.5, 0.5, 2.5, 5.5, 9.5 ]
#             +1   +2   +3   +4
#                1    1    1
# N = (1/2 d^2 + 1/2 d - 1/2)
#   = (1/2*$d**2 + 1/2*$d - 1/2)
#   = ((1/2*$d + 1/2)*$d - 1/2)
# d = -1/2 + sqrt(2 * $n + 5/4)
#   = (sqrt(8*$n + 5) -1)/2

sub n_to_xy {
  my ($self, $n) = @_;
  ### Diagonals n_to_xy(): "$n   ".(ref $n || '')

  # adjust to N=0 at origin X=0,Y=0
  $n = $n - $self->{'n_start'};

  my $d;
  {
    my $r = 8*$n + 5;
    if ($r < 1) {
      ### which is N < -0.5 ...
      return;
    }
    ### sqrt of: "$r"
    ### sqrt is: sqrt(int($r)).""

    $d = int((_sqrtint($r) - 1) / 2);
    ### assert: $d >= 0
    ### d: "$d"
    ### $d
  }

  # subtract for offset into diagonal, range -0.5 <= $n < $d+0.5
  $n -= $d*($d+1)/2;
  ### subtract to n: "$n"

  my $y = -$n + $d;  # $n first so BigFloat not BigInt from $d
  # and X=$n

  if ($self->{'direction'} eq 'up') {
    ($n,$y) = ($y,$n);
  }
  return ($n + $self->{'x_start'},
          $y + $self->{'y_start'});
}

# round y on an 0.5 downwards so that x=-0.5,y=0.5 gives n=1 which is the
# inverse of n_to_xy() ... or is that inconsistent with other classes doing
# floor() always?
#
# d(d+1)/2+1
#   = (d^2 + d + 2) / 2
#
sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### xy_to_n(): $x, $y
  $x = $x - $self->{'x_start'};   # "-" operator to provoke warning if x==undef
  $y = $y - $self->{'y_start'};
  if ($self->{'direction'} eq 'up') {
    ($x,$y) = ($y,$x);
  }
  $x = round_nearest ($x);
  $y = round_nearest (- $y);
  ### rounded
  ### $x
  ### $y
  if ($x < 0 || $y > 0) {
    return undef;  # outside
  }

  my $d = $x - $y;
  ### $d
  return $d*($d+1)/2 + $x + $self->{'n_start'};
}

# bottom-left to top-right, used by DiagonalsAlternating too
# exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;

  if ($x1 > $x2) { ($x1,$x2) = ($x2,$x1); }
  if ($y1 > $y2) { ($y1,$y2) = ($y2,$y1); }
  if ($x2 < $self->{'x_start'} || $y2 < $self->{'y_start'}) {
    return (1, 0); # rect all negative, no N
  }

  $x1 = max ($x1, $self->{'x_start'});
  $y1 = max ($y1, $self->{'y_start'});

  # exact range bottom left to top right
  return ($self->xy_to_n ($x1,$y1),
          $self->xy_to_n ($x2,$y2));
}

1;
__END__

=for stopwords PlanePath Ryde Math-PlanePath OEIS triangulars sqrt

=head1 NAME

Math::PlanePath::Diagonals -- points in diagonal stripes

=head1 SYNOPSIS

 use Math::PlanePath::Diagonals;
 my $path = Math::PlanePath::Diagonals->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path follows successive diagonals going from the Y axis down to the X
axis.

      6  |  22
      5  |  16  23
      4  |  11  17  24
      3  |   7  12  18  ...
      2  |   4   8  13  19
      1  |   2   5   9  14  20
    Y=0  |   1   3   6  10  15  21
         +-------------------------
           X=0   1   2   3   4   5

X<Triangular numbers>N=1,3,6,10,etc on the X axis is the triangular numbers.
N=1,2,4,7,11,etc on the Y axis is the triangular plus 1, the next point
visited after the X axis.

=head2 Direction

Option C<direction =E<gt> 'up'> reverses the order within each diagonal to
count upward from the X axis.

=cut

# math-image --path=Diagonals,direction=up  --all --output=numbers

=pod

    direction => "up"

      5  |  21
      4  |  15  20
      3  |  10  14  19 ...
      2  |   6   9  13  18  24
      1  |   3   5   8  12  17  23
    Y=0  |   1   2   4   7  11  16  22
         +-----------------------------
           X=0   1   2   3   4   5   6

This is merely a transpose changing X,Y to Y,X, but it's the same as in
C<DiagonalsOctant> and can be handy to control the direction when combining
C<Diagonals> with some other path or calculation.

=head2 N Start

The default is to number points starting N=1 as shown above.  An optional
C<n_start> can give a different start, in the same diagonals sequence.  For
example to start at 0,

=cut

# math-image --path=Diagonals,n_start=0 --all --output=numbers --size=35x5
# math-image --path=Diagonals,n_start=0,direction=up --all --output=numbers --size=35x5

=pod

    n_start => 0,                    n_start=>0
    direction=>"down"                direction=>"up"

      4  |  10                       |  14
      3  |   6 11                    |   9 13
      2  |   3  7 12                 |   5  8 12
      1  |   1  4  8 13              |   2  4  7 11
    Y=0  |   0  2  5  9 14           |   0  1  3  6 10
         +-----------------          +-----------------
           X=0  1  2  3  4             X=0  1  2  3  4

X<Triangular numbers>N=0,1,3,6,10,etc on the Y axis of "down" or the X axis
of "up" is the triangular numbers Y*(Y+1)/2.

=head2 X,Y Start

Options C<x_start =E<gt> $x> and C<y_start =E<gt> $y> give a starting
position for the diagonals.  For example to start at X=1,Y=1

      7  |   22               x_start => 1,
      6  |   16 23            y_start => 1
      5  |   11 17 24
      4  |    7 12 18 ...
      3  |    4  8 13 19
      2  |    2  5  9 14 20
      1  |    1  3  6 10 15 21
    Y=0  |
         +------------------
         X=0  1  2  3  4  5

The effect is merely to add a fixed offset to all X,Y values taken and
returned, but it can be handy to have the path do that to step through
non-negatives or similar.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::Diagonals-E<gt>new ()>

=item C<$path = Math::PlanePath::Diagonals-E<gt>new (direction =E<gt> $str, n_start =E<gt> $n, x_start =E<gt> $x, y_start =E<gt> $y)>

Create and return a new path object.  The C<direction> option (a string) can
be

    direction => "down"       the default
    direction => "up"         number upwards from the X axis

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.

For C<$n E<lt> 0.5> the return is an empty list, it being considered the
path begins at 1.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return the point number for coordinates C<$x,$y>.  C<$x> and C<$y> are
each rounded to the nearest integer, which has the effect of treating each
point C<$n> as a square of side 1, so the quadrant x>=-0.5, y>=-0.5 is
entirely covered.

=item C<($n_lo, $n_hi) = $path-E<gt>rect_to_n_range ($x1,$y1, $x2,$y2)>

The returned range is exact, meaning C<$n_lo> and C<$n_hi> are the smallest
and biggest in the rectangle.

=back

=head1 FORMULAS

=head2 X,Y to N

The sum d=X+Y numbers each diagonal from d=0 upwards, corresponding to the Y
coordinate where the diagonal starts (or X if direction=up).

    d=2
        \
    d=1  \
        \ \
    d=0  \ \
        \ \ \

N is then given by

    d = X+Y
    N = d*(d+1)/2 + X + Nstart

The d*(d+1)/2 shows how the triangular numbers fall on the Y axis when X=0
and Nstart=0.  For the default Nstart=1 it's 1 more than the triangulars, as
noted above.

=cut

# N = (X+Y)*(X+Y+1)/2 + X + Nstart
#   = [ (X+Y)*(X+Y+1) + 2X ]/2 + Nstart
#   = [ X^2 + XY + X + XY + Y^2 + Y + 2X ]/2 + Nstart
#   = [ X^2 + 3X + 2XY + Y + Y^2 ]/2 + Nstart

=pod

d can be expanded out to the following quite symmetric form.  This almost
suggests something parabolic but is still the straight line diagonals.

        X^2 + 3X + 2XY + Y + Y^2
    N = ------------------------ + Nstart
                   2

=head2 N to X,Y

The above formula N=d*(d+1)/2 can be solved for d as

    d = floor( (sqrt(8*N+1) - 1)/2 )
    # with n_start=0

For example N=12 is d=floor((sqrt(8*12+1)-1)/2)=4 as that N falls in the
fifth diagonal.  Then the offset from the Y axis NY=d*(d-1)/2 is the X
position,

    X = N - d*(d-1)/2
    Y = d - X

In the code fractional N is handled by imagining each diagonal beginning 0.5
back from the Y axis.  That's handled by adding 0.5 into the sqrt, which is
+4 onto the 8*N.

    d = floor( (sqrt(8*N+5) - 1)/2 )
    # N>=-0.5

The X and Y formulas are unchanged, since N=d*(d-1)/2 is still the Y axis.
But each diagonal d begins up to 0.5 before that and therefor X extends back
to -0.5.

=head2 Rectangle to N Range

Within each row increasing X is increasing N, and in each column increasing
Y is increasing N.  So in a rectangle the lower left corner is minimum N and
the upper right is maximum N.

    |            \     \ N max
    |       \ ----------+
    |        |     \    |\
    |        |\     \   |
    |       \| \     \  |
    |        +----------
    |  N min  \  \     \
    +-------------------------

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to this
path include

=over

L<http://oeis.org/A002262> (etc)

=back

    direction=down (the default)
      A002262    X coordinate, runs 0 to k
      A025581  	 Y coordinate, runs k to 0
      A003056  	 X+Y coordinate sum, k repeated k+1 times
      A114327  	 Y-X coordinate diff
      A101080    HammingDist(X,Y)

      A127949    dY, change in Y coordinate

      A000124    N on Y axis, triangular numbers + 1
      A001844    N on X=Y diagonal

      A185787    total N in row to X=Y diagonal
      A185788    total N in row to X=Y-1
      A100182    total N in column to Y=X diagonal
      A101165    total N in column to Y=X-1
      A185506    total N in rectangle 0,0 to X,Y

    direction=down, x_start=1, y_start=1
      A057555    X,Y pairs
      A057046    X at N=2^k
      A057047    Y at N=2^k

    direction=down, n_start=0
      A057554    X,Y pairs
      A023531    dSum = dX+dY, being 1 at N=triangular+1 (and 0)
      A000096    N on X axis, X*(X+3)/2
      A000217    N on Y axis, the triangular numbers
      A129184    turn 1=left,0=right
      A103451    turn 1=left or right,0=straight, but extra initial 1
      A103452    turn 1=left,0=straight,-1=right, but extra initial 1
    direction=up, n_start=0
      A129184    turn 0=left,1=right

    direction=up, n_start=-1
      A023531    turn 1=left,0=right
    direction=down, n_start=-1
      A023531    turn 0=left,1=right

    in direction=up the X,Y coordinate forms are the same but swap X,Y

    either direction
      A038722    permutation N at transpose Y,X
                   which is direction=down <-> direction=up

    either direction, x_start=1, y_start=1
      A003991    X*Y coordinate product
      A003989    GCD(X,Y) greatest common divisor starting (1,1)
      A003983    min(X,Y)
      A051125    max(X,Y)

    either direction, n_start=0
      A049581    abs(X-Y) coordinate diff
      A004197    min(X,Y)
      A003984    max(X,Y)
      A004247    X*Y coordinate product
      A048147    X^2+Y^2
      A109004    GCD(X,Y) greatest common divisor starting (0,0)
      A004198    X bit-and Y
      A003986    X bit-or Y
      A003987    X bit-xor Y
      A156319    turn 0=straight,1=left,2=right

      A061579    permutation N at transpose Y,X
                   which is direction=down <-> direction=up

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::DiagonalsAlternating>,
L<Math::PlanePath::DiagonalsOctant>,
L<Math::PlanePath::Corner>,
L<Math::PlanePath::Rows>,
L<Math::PlanePath::Columns>

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
