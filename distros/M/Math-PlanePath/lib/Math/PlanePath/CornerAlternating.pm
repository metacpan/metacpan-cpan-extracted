# Copyright 2021 Kevin Ryde

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


package Math::PlanePath::CornerAlternating;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 129;
use Math::PlanePath;
use Math::PlanePath::Base::NSEW;
*_sqrtint = \&Math::PlanePath::_sqrtint;
@ISA = ('Math::PlanePath::Base::NSEW',
        'Math::PlanePath');

use Math::PlanePath::Base::Generic
  'round_nearest';

# uncomment this to run the ### lines
# use Smart::Comments;


use constant class_x_negative => 0;
use constant class_y_negative => 0;
*xy_is_visited = \&Math::PlanePath::Base::Generic::xy_is_visited_quad1;

use Math::PlanePath::SquareSpiral;
*parameter_info_array = \&Math::PlanePath::SquareSpiral::parameter_info_array;

use constant dx_maximum => 1;
use constant dy_minimum => -1;

#     |  4---5---6   first South at 6 completing all NSEW
#     |  |       |
#   1 |  3---2       first right turn at 3
#     |      |
# Y=0 |  0---1       first left turn at 1
#     +-----------
sub _UNDOCUMENTED__turn_any_left_at_n {
  my ($self) = @_;
  return $self->{'n_start'} + $self->{'wider'} + 1;
}
sub _UNDOCUMENTED__turn_any_right_at_n {
  my ($self) = @_;
  return $self->{'n_start'} + 2*$self->{'wider'} + 3;
}
sub _UNDOCUMENTED__dxdy_list_at_n {
  my ($self) = @_;
  return $self->{'n_start'} + 3*$self->{'wider'} + 6;
}

#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new (@_);
  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }
  $self->{'wider'} ||= 0;  # default
  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### Corner n_to_xy: $n

  # adjust to N=0 at origin X=0,Y=0
  $n = $n - $self->{'n_start'};
  if ($n < 0) { return; }

  my $wider = $self->{'wider'};
  my $int = int($n);
  $n -= $int;          # frac part

  # wider==0 n_start=0
  #   row start N=0, 1, 4, 9, 16, 25
  #   N = Y^2
  #   Y = floor sqrt(N)
  #
  # wider==2 n_start=0
  #   N=0, 3, 8, 15, 24
  #   N = Y^2 + 2*Y
  #   Y = floor (-w + sqrt(w^2 + 4*N))/2

  # gnomon number d,
  # starting d=0 for point N=0 at the origin (and more when wider),
  # with point immediately before each gnomon included in the following one
  #
  my $d = int ((_sqrtint(4*($int+1) + $wider*$wider) - $wider) / 2);
  ### d frac: (sqrt(int(4*($int+1)) + $wider*$wider) - $wider) / 2
  ### $d

  # $r ranges -1 upwards, with -1 being the point immediately before gnomon $d
  my $r = $int - $d*($d+$wider);
  ### subtract start: $d*($d+$wider)
  ### $r
  if ($d % 2) {
    if ($r < 0) {
      ### X axis rightward ...
      return ($d+$wider+$n-1, 0);
    } elsif ($r < $d) {
      ### right upward ...
      return ($d+$wider, $r+$n);
    } else {
      ### top leftward ...
      return ($d+$wider-($r-$d)-$n, $d);
    }
  } else {
    if ($r < 0) {
      ### Y axis upward ...
      return (0, $d-1+$n);
    } elsif ($r < $d + $wider) {
      ### top rightward ...
      return ($r+$n, $d);
    } else {
      ### right downward ...
      return ($d+$wider, $d-($r-$d-$wider) - $n);
    }
  }
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### Corner xy_to_n(): "$x,$y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);
  if ($x < 0 || $y < 0) {
    return undef;
  }

  my $wider = $self->{'wider'};
  my $xw = $x - $wider;
  if ($y >= $xw) {
    ### top edge ...
    return ($y*($y+$wider)  + ($y % 2 ? 2*$y+$wider - $x : $x)
            + $self->{'n_start'});
  } else {
    ### right vertical ...
    return ($x*$xw          + ($xw % 2 ? $y : $x+$xw - $y)
            +  $self->{'n_start'});
  }
}

# exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### Corner rect_to_n_range(): "$x1,$y1, $x2,$y2"

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);
  if ($x1 > $x2) { ($x1,$x2) = ($x2,$x1); }
  if ($y1 > $y2) { ($y1,$y2) = ($y2,$y1); }

  if ($y2 < 0 || $x2 < 0) {
    return (1, 0); # rect all negative, no N
  }

  if ($x1 < 0) { $x1 *= 0; }   # "*=" to preserve bigint x1 or y1
  if ($y1 < 0) { $y1 *= 0; }

  my $wider = $self->{'wider'};
  my $xmin = $x1;
  my $ymin = $y1;

  my $t = $wider + $y1;     # x where diagonal goes through row y1
  if ($x1 <= $t) {
    ### for min, x1,y1 at or before diagonal ...
    # |   +-------+ / y2
    # |   |       |/          |
    # |   |       /           |                  /
    # |   |      /|           |    +------+     /   y2
    # |   |     / |           |    |      |    /
    # |   @----@--+  y1       |    @------@   /     y1
    # |   x1  /   x2          |   x1     x2  /
    # +------------------     +--------------------
    #  ..wider
    if ($y1 % 2) {
      ### leftward row y1, min at smaller of x2 or diagonal ...
      $xmin = ($x2 < $t ? $x2 : $t);
    }

  } else {
    ### for min, x1,y1 after diagonal ...
    #            /
    # |      +------+  y2     |
    # |      | /    |         |        /
    # |      |/     |         |       /
    # |      @      |         |      / @------+  y2
    # |     /|      |         |     /  |      |
    # |    / @------+  y1     |    /   @------+  y1
    # |   /  x1     x2        |   /   x1     x2
    # +------------------     +------------------
    #    ^...^xw
    #    wider

    $t = $x1 - $wider;
    unless ($t % 2) {
      ### column x1 even, downward ...
      $ymin = ($y2 < $t ? $y2 : $t);
    }
  }

  #-----
  my $xmax = $x2;
  my $ymax = $y2;

  #     |           /
  #     |   @------/  y2     x2,y2 on the diagonal
  #     |   |     /|         executes both "on or before"
  #     |   |    / |         and "on or after"
  #     |   |   /  |         selecting one or other of
  #     |   |  /   |         the opposite points
  #     |   +-/----@  y1     according as direction of
  #     |  x1/     x2        the gnomon
  #     +---------------

  $t = $x2 - $wider;  # y where diagonal passes column x2
  if ($y2 >= $t) {
    ### for max, x2,y2 on or before diagonal ...
    # max is x1 in an odd row (leftward)
    #
    # |              /
    # |    @------@ /y2
    # |    |      |/
    # |    |      /
    # |    |     /|
    # |    |    / |
    # |    +---/--+  y1
    # |   x1  /   x2
    # +----------------
    if ($y2 % 2) {
      ### top row odd, max at leftward x1 ...
      $xmax = $x1;
    }
  }
  if ($y2 <= $t) {
    ### for max, x2,y2 on or after of diagonal ...
    # max is y1 in a downward column ...
    #
    # |         /
    # |     +--/---@  y2
    # |     | /    |
    # |     |/     |
    # |     /      |
    # |    /|      |
    # |   / +------@  y1
    # |  /         x2
    # +-----------------
    #   ^
    #   wider
    #
    unless ($t % 2) {
      ### x2 column even, downward ...
      $ymax = $y1;
    }
  }

  ### min xy: "$xmin,$ymin"
  ### max xy: "$xmax,$ymax"
  return ($self->xy_to_n ($xmin,$ymin),
          $self->xy_to_n ($xmax,$ymax));
}

#------------------------------------------------------------------------------

sub _NOTDOCUMENTED_n_to_figure_boundary {
  my ($self, $n) = @_;
  ### _NOTDOCUMENTED_n_to_figure_boundary(): $n

  # adjust to N=1 at origin X=0,Y=0
  $n = $n - $self->{'n_start'} + 1;

  if ($n < 1) {
    return undef;
  }

  my $wider = $self->{'wider'};
  if ($n <= $wider) {
    # single block row, nothing special at diagonal
    # +---+-----+----+
    # | 1 | ... | $n |  boundary = 2*N + 2
    # +---+-----+----+
    return 2*$n + 2;
  }

  my $d = int((_sqrtint(4*$n + $wider*$wider - 2) - $wider) / 2);
  ### $d
  ### $wider

  if ($n > $d*($d+1+$wider) + ($d%2 ? 0 : $wider)) {
    $wider++;
    ### increment for +2 after turn on diagonal ...
  }
  return 4*$d + 2*$wider + 2;
}

#------------------------------------------------------------------------------
1;
__END__

# cf A219159 going alternating two rows, the flip
#    A213928 going alternating three rows, the flip

# corners alternating "shell"
#
# A319514 interleaved x,y
# x=OEIS_bfile_func("A319289");
# y=OEIS_bfile_func("A319290");
# plothraw(vector(3^3,n,n--; x(n)), \
#          vector(3^3,n,n--; y(n)), 1+8+16+32)


=for stopwords pronic PlanePath Ryde Math-PlanePath ie OEIS gnomon Nstart

=head1 NAME

Math::PlanePath::CornerAlternating -- points shaped around a corner alternately

=head1 SYNOPSIS

 use Math::PlanePath::CornerAlternating;
 my $path = Math::PlanePath::CornerAlternating->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path is points in layers around a square outwards from a corner in the
first quadrant, alternately upward or downward.  X<Gnomon>Each row/column
"gnomon" added to a square makes a one-bigger square.

=cut

# math-image --path=CornerAlternating --output=numbers_dash --all --size=30x14

=pod

      4 | 17--18--19--20--21 ...
        |  |               |   |
      3 | 16--15--14--13  22  29
        |              |   |   |
      2 |  5---6---7  12  23  28
        |  |       |   |   |   |
      1 |  4---3   8  11  24  27
        |      |   |   |   |   |
    Y=0 |  1---2   9--10  25--26
        +-------------------------
         X=0   1   2   3   4   5

This is like the Corner path, but here gnomons go back and forward and in
particular so points are always a unit step apart.

=head2 Wider

An optional C<wider =E<gt> $integer> makes the path wider horizontally,
becoming a rectangle.  For example

=cut

# math-image --path=CornerAlternating,wider=3 --all --output=numbers_dash --size=38x12

=pod

     4  |  29--30--31--32--33--34--35--36  ...
        |   |                           |   |
     3  |  28--27--26--25--24--23--22  37  44      wider => 3
        |                           |   |   |
     2  |  11--12--13--14--15--16  21  38  43
        |   |                   |   |   |   |
     1  |  10---9---8---7---6  17  20  39  42
        |                   |   |   |   |   |
    Y=0 |   1---2---3---4---5  18--19  40--41
        +--------------------------------------
          X=0   1   2   3   4   5   6   7   8

Each gnomon has the horizontal part C<wider> many steps longer.  For wider=3
shown, the additional points are 2,3,4 in the first row, then 5..10 are the
next gnomon.  Each gnomon is still 2 longer than the previous since this
widening is a constant amount in each.

=head2 N Start

The default is to number points starting N=1 as shown above.  An optional
C<n_start> can give a different start with the same shape etc.  For example
to start at 0,

=cut

# math-image --path=CornerAlternating,n_start=0 --all --output=numbers --size=50x11

=pod

      4  |  16  17  18  19  20
      3  |  15  14  13  12  21      n_start => 0
      2  |   4   5   6  11  22
      1  |   3   2   7  10  23
    Y=0  |   0   1   8   9  24
          ---------------------
           X=0   1   2   3   4

With Nstart=0, the pronic numbers are on the X=Y leading diagonal.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::CornerAlternating-E<gt>new ()>

=item C<$path = Math::PlanePath::CornerAlternating-E<gt>new (wider =E<gt> $w, n_start =E<gt> $n)>

Create and return a new path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.

For C<$n < n_start()> the return is an empty list.  Fractional C<$n> gives
an X,Y position along a straight line between the integer positions.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return the point number for coordinates C<$x,$y>.

C<$x> and C<$y> are each rounded to the nearest integer, which has the
effect of treating each point as a square of side 1, so the quadrant x>=-0.5
and y>=-0.5 is entirely covered.

=item C<($n_lo, $n_hi) = $path-E<gt>rect_to_n_range ($x1,$y1, $x2,$y2)>

The returned range is exact, meaning C<$n_lo> and C<$n_hi> are the smallest
and biggest in the rectangle.

=back

=head1 FORMULAS

Most calculations are similar to the Corner path (without the 0.5 fractional
part), and a reversal applied when the d gnomon number is odd.  When
wider>0, that reversal must allow for the horizontals and verticals
different lengths.

=head2 Rectangle N Range

For C<rect_to_n_range()>, the largest gnomon is either the top or right of
the rectangle, depending where the top right corner x2,y2 falls relative to
the leading diagonal,

    |  A---B /    x2<y2         |       /       x2>y2
    |  |   |/     top           |  +------B     right
    |  |   |      row           |  |  /   |     side
    |  |  /|     biggest        |  | /    |     biggest
    |  +---+     gnomon         |  +------C     gnomon
    |   /                       |  /
    +---------                  +-----------

Then the maximum is at A or B, or B or C according as which way that gnomon
goes, so odd or even.

If it happens that B is on the diagonal, so x2=y2, then it's either A or C
according as the gnomon odd or even

    |        /
    |  A----+     x2=y2
    |  |   /|
    |  |  / |
    |  +----C
    |   /
    +-----------

For wider E<gt> 0, the diagonal shifts across so that x2-wider E<lt>=E<gt>
y2 is the relevant test.

=head1 OEIS

This path is in Sloane's Online Encyclopedia of Integer Sequences as,

=over

L<http://oeis.org/A319289> (etc)

=back

    wider=0, n_start=1 (the defaults)
      A220603    X+1 coordinate
      A220604    Y+1 coordinate
      A213088    X+Y sum
      A081346    N on X axis
      A081345    N on Y axis
      A002061    N on X=Y diagonal, extra initial 1
      A081344    permutation N by diagonals
      A194280      inverse
      A020703    permutation N at transpose Y,X

      A027709    boundary length of N unit squares
      A078633    grid sticks of N points

    n_start=0
      A319290    X coordinate
      A319289    Y coordinate
      A319514    Y,X coordinate pairs
      A329116    X-Y diff
      A053615    abs(X-Y) diff
      A000196    max(X,Y), being floor(sqrt(N))
      A339265    dX-dY increments (runs +1,-1)
      A002378    N on X=Y diagonal, pronic numbers
      A220516    permutation N by diagonals

    n_start=2
      A014206    N on X=Y diagonal, pronic+2

    wider=1, n_start=1
      A081347    N on X axis
      A081348    N on Y axis
      A080335    N on X=Y diagonal
      A093650    permutation N by diagonals

    wider=1, n_start=0
      A180714    X-Y diff

    wider=2, n_start=1
      A081350    N on X axis
      A081351    N on Y axis
      A081352    N on X=Y diagonal
      A081349    permutation N by diagonals

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::Corner>,
L<Math::PlanePath::DiagonalsAlternating>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2021 Kevin Ryde

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
