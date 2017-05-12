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


package Math::PlanePath::TriangleSpiralSkewed;
use 5.004;
use strict;
#use List::Util 'max','min';
*max = \&Math::PlanePath::_max;
*min = \&Math::PlanePath::_min;

use vars '$VERSION', '@ISA';
$VERSION = 124;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'round_nearest';
*_sqrtint = \&Math::PlanePath::_sqrtint;

# uncomment this to run the ### lines
# use Smart::Comments;

use constant xy_is_visited => 1;
use constant parameter_info_array =>
  [
   { name            => 'skew',
     type            => 'enum',
     share_key       => 'skew_lrud',
     display         => 'Skew',
     default         => 'left',
     choices         => ['left', 'right','up','down' ],
     choices_display => ['Left', 'Right','Up','Down' ],
   },
   Math::PlanePath::Base::Generic::parameter_info_nstart1(),
  ];

{
  my %x_negative_at_n = (left  => 3,
                         right => 5,
                         up    => 3,
                         down  => 5);
  sub x_negative_at_n {
    my ($self) = @_;
    return $self->n_start + $x_negative_at_n{$self->{'skew'}};
  }
}
{
  my %y_negative_at_n = (left  => 6,
                                        right => 6,
                                        up    => 5,
                                        down  => 1);
  sub y_negative_at_n {
    my ($self) = @_;
    return $self->n_start + $y_negative_at_n{$self->{'skew'}};
  }
}
use constant dx_minimum => -1;
use constant dx_maximum => 1;
use constant dy_minimum => -1;
use constant dy_maximum => 1;
{
  my %_UNDOCUMENTED__dxdy_list = (left  => [1,0,   # E
                             -1,1,  # NW
                             0,-1], # S
                   right => [1,0,    # E
                             0,1,    # N
                             -1,-1], # SW
                   up    => [1,1,   # NE
                             -1,0,  # W
                             0,-1], # S
                   down  => [0,1,   # N
                             -1,0,  # W
                             1,-1], # SE
                  );
  sub _UNDOCUMENTED__dxdy_list {
    my ($self) = @_;
    return @{$_UNDOCUMENTED__dxdy_list{$self->{'skew'}}};
  }
}
{
  my %dsumxy_minimum = (left  => -1,  # diagonal only NW across
                        right => -2,  # SW
                        up    => -1,  # S
                        down  => -1); # W
  sub dsumxy_minimum {
    my ($self) = @_;
    return $dsumxy_minimum{$self->{'skew'}};
  }
}
{
  my %dsumxy_maximum = (left  => 1,  # E
                        right => 1,  # N
                        up    => 2,  # NE
                        down  => 1); # N
  sub dsumxy_maximum {
    my ($self) = @_;
    return $dsumxy_maximum{$self->{'skew'}};
  }
}
{
  my %ddiffxy_minimum = (left  => -2,  # North-West
                         right => -1,  # N
                         up    => -1,  # W
                         down  => -1); # W
  sub ddiffxy_minimum {
    my ($self) = @_;
    return $ddiffxy_minimum{$self->{'skew'}};
  }
}
{
  my %ddiffxy_maximum = (left  => 1,  # S
                         right => 1,  # S
                         up    => 1,  # S
                         down  => 2); # South-East
  sub ddiffxy_maximum {
    my ($self) = @_;
    return $ddiffxy_maximum{$self->{'skew'}};
  }
}

{
  my %dir_minimum_dxdy = (left  => [1,0],  # East
                          right => [1,0],  # East
                          up    => [1,1],  # NE
                          down  => [0,1]); # North
  sub dir_minimum_dxdy {
    my ($self) = @_;
    return @{$dir_minimum_dxdy{$self->{'skew'}}};
  }
}
{
  my %dir_maximum_dxdy = (left  => [0,-1],   # South
                          right => [-1,-1],  # South-West
                          up    => [0,-1],   # South
                          down  => [1,-1]);  # South-East
  sub dir_maximum_dxdy {
    my ($self) = @_;
    return @{$dir_maximum_dxdy{$self->{'skew'}}};
  }
}

use constant turn_any_right => 0; # only left or straight


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new (@_);
  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }
  $self->{'skew'} ||= 'left';
  return $self;
}

# base at bottom left corner, N=0 basis, first loop d=1
#   d = [ 1,  2,  3 ]
#   n = [ 0,  6, 21 ]
#   d = 5/6 + sqrt(2/9 * $n + 1/36)
#     = (5 + sqrt(8N + 1))/6
# N = (9/2 d^2 - 15/2 d + 3)
#   = (9/2*$d**2 - 15/2*$d + 3)
#   = ((9/2*$d - 15/2)*$d + 3)
#   = (9*$d - 15)*$d/2 + 3
#
# bottom right corner is further 3*$d along, so
#   rem = $n - (9/2 d^2 - 15/2 d + 3) - 3*d
#       = $n - (9/2 d^2 - 9/2 d + 3)
#       = $n - (9/2*$d + -9/2)*$d - 3
#       = $n - (9*$d + -9)*$d/2 - 3
#       = $n - ($d - 1)*$d*9/2 - 3
# is rem < 0       bottom horizontal
#    rem <= 3*d-1  right slope
#    rem >= 3*d-1  left vertical
#
sub n_to_xy {
  my ($self, $n) = @_;
  #### TriangleSpiralSkewed n_to_xy: $n

  $n = $n - $self->{'n_start'};  # starting N==0, and warning if $n==undef
  if ($n < 0) { return; }

  my $d = int((_sqrtint(8*$n + 1) + 5) / 6);  # first loop d=1 at n=0
  #### $d

  $n -= ($d-1)*$d/2 * 9;
  #### remainder: $n

  my $zero = $n*0; # inherit BigFloat frac rather than $d=BigInt
  my ($x,$y);

  if ($n <= 1) {
    ### bottom horizontal: "nrem=$n"
    $d -= 1;
    $y = $zero - $d;
    $x = $n + 2*$d;
  } elsif (($n -= 3*$d) <= 0) {
    ### right slope: "nrem=$n"
    $x = -$n - $d;
    $y = $n + 2*$d;
  } else {
    ### left vertical: "nrem=$n"
    $x = $zero - $d;
    $y = - $n + 2*$d;
  }
  ### xy skew=left: "$x,$y"

  if ($self->{'skew'} eq 'right') {
    $x += $y;
  } elsif ($self->{'skew'} eq 'up') {
    $y += $x;
  } elsif ($self->{'skew'} eq 'down') {
    ($x,$y) = ($x+$y, -$x);
  }
  return ($x,$y);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  $x = round_nearest ($x);
  $y = round_nearest ($y);
  ### xy_to_n(): "$x,$y"

  if ($self->{'skew'} eq 'right') {
    $x -= $y;
  } elsif ($self->{'skew'} eq 'up') {
    $y -= $x;
  } elsif ($self->{'skew'} eq 'down') {
    ($x,$y) = (-$y, $x+$y);
  }
  # now $x,$y in skew="left" style

  my $n;
  if ($y < 0 && $y <= $x && $x <= -2*$y) {
    ### bottom horizontal ...

    # negative y, vertical at x=0
    #   [ -1, -2, -3, -4 ]
    #   [  8, 24, 49, 83 ]
    #   n = (9/2*$d**2 + -5/2*$d + 1)
    #
    $n = (9*$y - 5)*$y/2 + $x;

  } elsif ($x < 0 && $x <= $y && $y <= -2*$x) {
    ### upper left vertical ...

    # negative x, horizontal at y=0
    #   [ -1, -2, -3, -4 ]
    #   [  6, 20, 43, 75 ]
    #   n = (9/2*$d**2 + -1/2*$d + 1)
    #
    $n = (9*$x - 1)*$x/2 - $y;

  } else {
    my $d = $x + $y;
    ### upper right slope ...
    ### $d

    # positive y, vertical at x=0
    #   [ 1,  2,  3,  4 ]
    #   [ 3, 14, 34, 63 ]
    #   n = (9/2*$d**2 + -5/2*$d + 1)
    #
    $n = (9*$d - 5)*$d/2 - $x;
  }

  return $n + $self->{'n_start'};
}

# n_hi exact, n_lo not
# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  return ($self->{'n_start'},
          max ($self->xy_to_n ($x1,$y1),
               $self->xy_to_n ($x1,$y2),
               $self->xy_to_n ($x2,$y1),
               $self->xy_to_n ($x2,$y2)));
}
# my $d = 0;
# foreach my $x ($x1, $x2) {
#   foreach my $y ($y1, $y2) {
#     $d = max ($d,
#               1 + ($y < 0 && $y <= $x && $x <= -2*$y
#                    ? -$y                          # bottom horizontal
#                    : $x < 0 && $x <= $y && $y <= 2*-$x
#                    ? -$x              # left vertical
#                    : abs($x) + $y));  # right slope
#   }
# }
#         (9*$d - 9)*$d + 1 + $self->{'n_start'});

1;
__END__

=for stopwords Ryde Math-PlanePath 11-gonals hendecagonal hendecagonals OEIS

=head1 NAME

Math::PlanePath::TriangleSpiralSkewed -- integer points drawn around a skewed equilateral triangle

=head1 SYNOPSIS

 use Math::PlanePath::TriangleSpiralSkewed;
 my $path = Math::PlanePath::TriangleSpiralSkewed->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path makes an spiral shaped as an equilateral triangle (each side the
same length), but skewed to the left to fit on a square grid,

=cut

# math-image --path=TriangleSpiralSkewed --expression='i<=31?i:0' --output=numbers_dash

=pod

    16                              4
     |\
    17 15                           3
     |   \
    18  4 14                        2
     |  |\  \
    19  5  3 13                     1
     |  |   \  \
    20  6  1--2 12 ...         <- Y=0
     |  |         \  \
    21  7--8--9-10-11 30           -1
     |                  \
    22-23-24-25-26-27-28-29        -2

           ^
    -2 -1 X=0 1  2  3  4  5

The properties are the same as the spread-out C<TriangleSpiral>.  The
triangle numbers fall on straight lines as the do in the C<TriangleSpiral>
but the skew means the top corner goes up at an angle to the vertical and
the left and right downwards are different angles plotted (but are symmetric
by N count).

=head2 Skew Right

Option C<skew =E<gt> 'right'> directs the skew towards the right, giving

=cut

# math-image --path=TriangleSpiralSkewed,skew=right --expression='i<=31?i:0' --output=numbers_dash

=pod

      4                  16      skew="right"
                        / |
      3               17 15
                     /    |
      2            18  4 14
                  /  / |  |
      1        ...  5  3 13
                  /    |  |
    Y=0 ->       6  1--2 12
               /          |
     -1       7--8--9-10-11

                    ^
             -2 -1 X=0 1  2

This is a shear "X -E<gt> X+Y" of the default skew="left" shown above.  The
coordinates are related by

    Xright = Xleft + Yleft         Xleft = Xright - Yright
    Yright = Yleft                 Yleft = Yright          

=head2 Skew Up

=cut

# math-image --path=TriangleSpiralSkewed,skew=up --expression='i<=31?i:0' --output=numbers_dash

=pod

      2       16-15-14-13-12-11      skew="up"
               |            /   
      1       17  4--3--2 10
               |  |   /  /  
    Y=0 ->    18  5  1  9 
               |  |   /  
     -1      ...  6  8 
                  |/  
     -2           7 

                    ^
             -2 -1 X=0 1  2

This is a shear "Y -E<gt> X+Y" of the default skew="left" shown above.  The
coordinates are related by

    Xup = Xleft                 Xleft = Xup
    Yup = Yleft + Xleft         Yleft = Yup - Xup

=head2 Skew Down

=cut

# math-image --path=TriangleSpiralSkewed,skew=down --expression='i<=31?i:0' --output=numbers_dash

=pod

      2          ..-18-17-16       skew="down"
                           |  
      1        7--6--5--4 15 
                \       |  | 
    Y=0 ->        8  1  3 14 
                   \  \ |  | 
     -1              9  2 13 
                      \    | 
     -2                10 12 
                         \ | 
                          11 

                     ^
              -2 -1 X=0 1  2

This is a rotate by -90 degrees of the skew="up" above.  The coordinates are
related

    Xdown = Yup          Xup = - Ydown
    Ydown = - Xup        Yup = Xdown

Or related to the default skew="left" by

    Xdown = Yleft + Xleft        Xleft = - Ydown
    Ydown = - Xleft              Yleft = Xdown + Ydown

=head2 N Start

The default is to number points starting N=1 as shown above.  An optional
C<n_start> can give a different start, with the same shape etc.  For example
to start at 0,

=cut

# math-image --path=TriangleSpiralSkewed,n_start=0 --expression='i<=31?i:0' --output=numbers_dash

=pod

    15        n_start => 0
     |\
    16 14
     |   \
    17  3 13 ...
     |  |\  \  \
    18  4  2 12 31
     |  |   \  \  \
    19  5  0--1 11 30
     |  |         \  \
    20  6--7--8--9-10 29
     |                  \
    21-22-23-24-25-26-27-28

With this adjustment for example the X axis N=0,1,11,30,etc is (9X-7)*X/2,
the hendecagonal numbers (11-gonals).  And South-East N=0,8,25,etc is the
hendecagonals of the second kind, (9Y-7)*Y/2 with Y negative.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::TriangleSpiralSkewed-E<gt>new ()>

=item C<$path = Math::PlanePath::TriangleSpiralSkewed-E<gt>new (skew =E<gt> $str, n_start =E<gt> $n)>

Create and return a new skewed triangle spiral object.  The C<skew>
parameter can be

    "left"    (the default)
    "right"
    "up"
    "down"

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return the point number for coordinates C<$x,$y>.  C<$x> and C<$y> are
each rounded to the nearest integer, which has the effect of treating each N
in the path as centred in a square of side 1, so the entire plane is
covered.

=back

=head1 FORMULAS

=head2 Rectangle to N Range

Within each row there's a minimum N and the N values then increase
monotonically away from that minimum point.  Likewise in each column.  This
means in a rectangle the maximum N is at one of the four corners of the
rectangle.

              |
    x1,y2 M---|----M x2,y2        maximum N at one of
          |   |    |              the four corners
       -------O---------          of the rectangle
          |   |    |
          |   |    |
    x1,y1 M---|----M x1,y1
              |

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to this
path include

=over

L<http://oeis.org/A117625> (etc)

=back

    n_start=1, skew="left" (the defaults)
      A204439     abs(dX)
      A204437     abs(dY)
      A010054     turn 1=left,0=straight, extra initial 1

      A117625     N on X axis
      A064226     N on Y axis, but without initial value=1
      A006137     N on X negative
      A064225     N on Y negative
      A081589     N on X=Y leading diagonal
      A038764     N on X=Y negative South-West diagonal
      A081267     N on X=-Y negative South-East diagonal
      A060544     N on ESE slope dX=+2,dY=-1
      A081272     N on SSE slope dX=+1,dY=-2

      A217010     permutation N values of points in SquareSpiral order
      A217291      inverse
      A214230     sum of 8 surrounding N
      A214231     sum of 4 surrounding N

    n_start=0
      A051682     N on X axis (11-gonal numbers)
      A081268     N on X=1 vertical (next to Y axis)
      A062708     N on Y axis
      A062725     N on Y negative axis
      A081275     N on X=Y+1 North-East diagonal
      A062728     N on South-East diagonal (11-gonal second kind)
      A081266     N on X=Y negative South-West diagonal
      A081270     N on X=1-Y North-West diagonal, starting N=3
      A081271     N on dX=-1,dY=2 NNW slope up from N=1 at X=1,Y=0

    n_start=-1
      A023531     turn 1=left,0=straight, being 1 at N=k*(k+3)/2
      A023532     turn 1=straight,0=left

    n_start=1, skew="right"
      A204435     abs(dX)
      A204437     abs(dY)
      A217011     permutation N values of points in SquareSpiral order
                    but with 90-degree rotation
      A217292     inverse
      A214251     sum of 8 surrounding N

    n_start=1, skew="up"
      A204439     abs(dX)
      A204435     abs(dY)
      A217012     permutation N values of points in SquareSpiral order
                    but with 90-degree rotation
      A217293     inverse
      A214252     sum of 8 surrounding N

    n_start=1, skew="down"
      A204435     abs(dX)
      A204439     abs(dY)

The square spiral order in A217011,A217012 and their inverses has first step
at 90-degrees to the first step of the triangle spiral, hence the rotation
by 90 degrees when relating to the C<SquareSpiral> path.  A217010 on the
other hand has no such rotation since it reckons the square and triangle
spirals starting in the same direction.

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::TriangleSpiral>,
L<Math::PlanePath::PyramidSpiral>,
L<Math::PlanePath::SquareSpiral>

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
