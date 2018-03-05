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


package Math::PlanePath::HexSpiralSkewed;
use 5.004;
use strict;
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 126;
use Math::PlanePath;
*_sqrtint = \&Math::PlanePath::_sqrtint;
@ISA = ('Math::PlanePath');

use Math::PlanePath::HexSpiral;
use Math::PlanePath::Base::Generic
  'round_nearest';

# uncomment this to run the ### lines
#use Devel::Comments;


use Math::PlanePath::SquareSpiral;
*parameter_info_array = \&Math::PlanePath::SquareSpiral::parameter_info_array;
use constant xy_is_visited => 1;

use constant dx_minimum => -1;
use constant dx_maximum => 1;
use constant dy_minimum => -1;
use constant dy_maximum => 1;

use constant _UNDOCUMENTED__dxdy_list => (1,0,   # E    four plus
                           0,1,   # N    NW and SE
                           -1,1,  # NW
                           -1,0,  # W
                           0,-1,  # S
                           1,-1,  # SE
                          );
*x_negative_at_n = \&Math::PlanePath::HexSpiral::x_negative_at_n;
*y_negative_at_n
  = \&Math::PlanePath::HexSpiral::y_negative_at_n;
*_UNDOCUMENTED__dxdy_list_at_n
  = \&Math::PlanePath::HexSpiral::_UNDOCUMENTED__dxdy_list_at_n;

use constant dsumxy_minimum => -1; # W,S straight
use constant dsumxy_maximum => 1;  # N,E straight
use constant ddiffxy_minimum => -2; # NW diagonal
use constant ddiffxy_maximum => 2;  # SE diagonal
use constant dir_maximum_dxdy => (1,-1); # South-East

use constant turn_any_right => 0; # only left or straight
sub _UNDOCUMENTED__turn_any_left_at_n {
  my ($self) = @_;
  return $self->n_start + $self->{'wider'} + 1;
}


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new (@_);

  # parameters
  $self->{'wider'} ||= 0;  # default
  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }

  return $self;
}

# Same as HexSpiral, but diagonal down and to the left is the downwards
# vertical at x=-$w_left.

sub n_to_xy {
  my ($self, $n) = @_;
  ### HexSpiralSkewed n_to_xy(): $n

  $n = $n - $self->{'n_start'};  # N=0 basis
  if ($n < 0) { return; }

  my $w = $self->{'wider'};
  my $w_right = int($w/2);
  my $w_left = $w - $w_right;
  #### $w
  #### $w_left
  #### $w_right

  my $d = int((_sqrtint(3*$n + ($w+2)*$w + 1) - 1 - $w) / 3);
  #### d frac: (_sqrtint(3*$n + ($w+2)*$w + 1) - 1 - $w) / 3
  #### $d
  $n -= (3*$d + 2 + 2*$w)*$d + 1;
  #### remainder: $n

  $n += 1; # N=1 basis

  if ($n <= $d+1+$w) {
    #### bottom horizontal
    return ($n - $w_left,
            -$d);
  }
  $n -= $d+1+$w;
  if ($n <= $d) {
    #### right lower vertical, being 1 shorter: $n
    return ($d + 1 + $w_right,
            $n - $d);
  }
  $n -= $d;
  if ($n <= $d+1) {
    #### right upper diagonal: $n
    return (-$n + $d + 1 + $w_right,
            $n);
  }
  $d = $d + 1; # no warnings if $d==infinity
  $n -= $d;
  if ($n <= $d+$w) {
    #### top horizontal
    return (-$n + $w_right,
            $d);
  }
  $n -= $d+$w;
  if ($n <= $d) {
    #### left upper vertical
    return (-$d - $w_left,
            -$n + $d);
  }
  #### left lower diagonal
  $n -= $d;
  return ($n - $d - $w_left,
          -$n);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);

  my $w = $self->{'wider'};
  my $w_right = int($w/2);
  my $w_left = $w - $w_right;

  if ($y > 0) {
    $x -= $w_right;
    if ($x < -$y-$w) {
      ### left upper vertical
      my $d = -$x - $w;
      ### $d
      ### base: (3*$d + 1 + 2*$w)*$d
      return ((3*$d + 1 + 2*$w)*$d
              - $y
              + $self->{'n_start'});
    } else {
      my $d = $y + max($x,0);
      ### right upper diagonal and top horizontal
      ### $d
      ### base: (3*$d - 1 + 2*$w)*$d - $w
      return ((3*$d - 1 + 2*$w)*$d - $w
              - $x
              + $self->{'n_start'});
    }

  } else {
    # $y < 0
    $x += $w_left;
    if ($x-$w <= -$y) {
      my $d = -$y + max(-$x,0);
      ### left lower diagonal and bottom horizontal
      ### $d
      ### base: (3*$d + 2 + 2*$w)*$d + 1
      return ((3*$d + 2 + 2*$w)*$d
              + $x
              + $self->{'n_start'});
    } else {
      ### right lower vertical
      my $d = $x - $w;
      ### $d
      ### base: (3*$d - 2 + 2*$w)*$d + 1 - $w
      return ((3*$d - 2 + 2*$w)*$d - $w
              + $y
              + $self->{'n_start'});
    }
  }
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### HexSpiralSkewed rect_to_n_range(): $x1,$y1, $x2,$y2

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  my $w = $self->{'wider'};
  my $w_right = int($w/2);
  my $w_left = $w - $w_right;

  my $d = 0;
  foreach my $x ($x1, $x2) {
    $x += $w_left;
    if ($x >= $w) {
      $x -= $w;
    }
    foreach my $y ($y1, $y2) {
      $d = max ($d,
                (($y > 0) == ($x > 0)
                 ? abs($x) + abs($y)      # top right or bottom left diagonals
                 : max(abs($x),abs($y)))); # top left or bottom right squares
    }
  }
  $d += 1;

  # diagonal downwards bottom right being the end of a revolution
  # s=0
  # s=1  n=7
  # s=2  n=19
  # s=3  n=37
  # s=4  n=61
  # n = 3*$d*$d + 3*$d + 1
  #
  ### gives: "sum $d is " . (3*$d*$d + 3*$d + 1)

  # ENHANCE-ME: find actual minimum if rect doesn't cover 0,0
  return ($self->{'n_start'},
          (3*$d + 3 + 2*$self->{'wider'})*$d + $self->{'n_start'});
}

1;
__END__

=for stopwords PlanePath Ryde Math-PlanePath OEIS

=head1 NAME

Math::PlanePath::HexSpiralSkewed -- integer points around a skewed hexagonal spiral

=head1 SYNOPSIS

 use Math::PlanePath::HexSpiralSkewed;
 my $path = Math::PlanePath::HexSpiralSkewed->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path makes a hexagonal spiral with points skewed so as to fit a square
grid and fully cover the plane.

    13--12--11   ...              2
     |         \   \
    14   4---3  10  23            1
     |   |     \   \   \
    15   5   1---2   9  22    <- Y=0
      \   \          |   | 
        16   6---7---8  21       -1
          \              |    
            17--18--19--20       -2

     ^   ^   ^   ^   ^   ^ 
    -2  -1  X=0  1   2   3  ...

The kinds of N=3*k^2 numbers which fall on straight lines in the plain
C<HexSpiral> also fall on straight lines when skewed.  See
L<Math::PlanePath::HexSpiral> for notes on this.

=head2 Skew

The skewed path is the same shape as the plain C<HexSpiral>, but fits more
points on a square grid.  The skew pushes the top horizontal to the left, as
shown by the following parts, and the bottom horizontal is similarly skewed
but to the right.

    HexSpiralSkewed               HexSpiral

    13--12--11                   13--12--11       
     |         \                /          \      
    14          10            14            10    
     |             \         /                \  
    15               9     15                   9

    -2  -1  X=0  1   2     -4 -3 -2  X=0  2  3  4

In general the coordinates can be converted each way by

    plain X,Y -> skewed (X-Y)/2, Y

    skewed X,Y -> plain 2*X+Y, Y

=head1 Corners

C<HexSpiralSkewed> is similar to the C<SquareSpiral> but cuts off the
top-right and bottom-left corners so that each loop is 6 steps longer than
the previous, whereas for the C<SquareSpiral> it's 8.  See
L<Math::PlanePath::SquareSpiral/Corners> for other corner cutting.

=head2 Wider

An optional C<wider> parameter makes the path wider, stretched along the top
and bottom horizontals.  For example

    $path = Math::PlanePath::HexSpiralSkewed->new (wider => 2);

gives

    21--20--19--18--17                    2
     |                 \    
    22   8---7---6---5  16                1
     |   |             \   \    
    23   9   1---2---3---4  15        <- Y=0
      \   \                  |     
       24   10--11--12--13--14  ...      -1
          \                      |    
            25--26--27--28--29--30       -2

     ^   ^   ^   ^   ^   ^   ^   ^ 
    -4  -3  -2  -1  X=0  1   2   3  ...

The centre horizontal from N=1 is extended by C<wider> many further places,
then the path loops around that shape.  The starting point 1 is shifted to
the left by wider/2 places (rounded up to an integer) to keep the spiral
centred on the origin X=0,Y=0.

Each loop is still 6 longer than the previous, since the widening is
basically a constant amount added into each loop.  The result is the same as
the plain C<HexSpiral> of the same widening too.  The effect looks better in
the plain C<HexSpiral>.

=head2 N Start

The default is to number points starting N=1 as shown above.  An optional
C<n_start> can give a different start with the same shape etc.  For example
to start at 0,

=cut

# math-image --path=HexSpiralSkewed,n_start=0 --all --output=numbers --size=70x9

=pod

    n_start => 0

    27  26  25  24                            3
    28  12  11  10  23                        2
    29  13   3   2   9  22                    1
    30  14   4   0   1   8  21 ...       <- Y=0
        31  15   5   6   7  20  39           -1
            32  16  17  18  19  38           -2
                33  34  35  36  37           -3
                 
    -3  -2  -1  X=0  1   2   3   4

In this numbering the X axis N=0,1,8,21,etc is the octagonal numbers
3*X*(X+1).

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::HexSpiralSkewed-E<gt>new ()>

=item C<$path = Math::PlanePath::HexSpiralSkewed-E<gt>new (wider =E<gt> $w)>

Create and return a new hexagon spiral object.  An optional C<wider>
parameter widens the spiral path, it defaults to 0 which is no widening.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return the point number for coordinates C<$x,$y>.  C<$x> and C<$y> are
each rounded to the nearest integer, which has the effect of treating each
point in the path as a square of side 1.

=back

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
this path include

=over

L<http://oeis.org/A056105> (etc)

=back

    A056105    N on X axis, 3n^2-2n+1
    A056106    N on Y axis, 3n^2-n+1
    A056107    N on North-West diagonal, 3n^2+1
    A056108    N on X negative axis, 3n^2+n+1
    A056109    N on Y negative axis, 3n^2+2n+1
    A003215    N on South-East diagonal, centred hexagonals

    n_start=0
      A000567    N on X axis, octagonal numbers
      A049450    N on Y axis
      A049451    N on X negative axis
      A045944    N on Y negative axis, octagonal numbers second kind
      A062783    N on X=Y diagonal north-east
      A033428    N on north-west diagonal, 3*k^2
      A063436    N on south-west diagonal
      A028896    N on south-east diagonal

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::HexSpiral>,
L<Math::PlanePath::HeptSpiralSkewed>,
L<Math::PlanePath::PentSpiralSkewed>,
L<Math::PlanePath::DiamondSpiral>

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
