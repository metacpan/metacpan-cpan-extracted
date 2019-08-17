# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018 Kevin Ryde

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



# math-image --path=GosperIslands --lines --scale=10
# math-image --path=GosperIslands --all --output=numbers_dash
#
# fractal dimension  2*log(3) / log(7) = 1.12915, A113211 decimal

# Check:
# A017926   boundary length, unit equilateral triangles
# A229977   boundary length, initial hexagon=1


package Math::PlanePath::GosperIslands;
use 5.004;
use strict;
use POSIX 'ceil';
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
use Math::PlanePath::Base::Digits
  'round_down_pow',
  'digit_split_lowtohigh';

use Math::PlanePath::SacksSpiral;

# uncomment this to run the ### lines
# use Smart::Comments;


use constant n_frac_discontinuity => 0;
use constant x_negative_at_n => 3;
use constant y_negative_at_n => 5;
use constant sumabsxy_minimum => 2; # minimum X=2,Y=0 or X=1,Y=1
use constant rsquared_minimum => 2; # minimum X=1,Y=1

# jump across rings is upwards, so dY maximum unbounded but minimum=-1
use constant dy_minimum => -1;

# dX and dY unbounded jumping between rings, with the jump position rotating
# around slowly with the twistiness of the ring.
use constant absdx_minimum => 1;

# jump across rings is ENE, so dSum maximum unbounded but minimum=-2
use constant dsumxy_minimum => -2;

# jump across rings is ENE, so dDiffXY minimum unbounded but maximum=+2
use constant ddiffxy_maximum => 2;

use constant dir_maximum_dxdy => (1,-1); # South-East
use constant turn_any_straight => 0; # never straight


#------------------------------------------------------------------------------
sub new {
  my $self = shift->SUPER::new (@_);
  $self->{'sides'} ||= 6; # default
  return $self;
}

# innermost hexagon level 0
#     level 0    len=6
#     level 1    len=18
# each sidelen = 3^level
# each ringlen = 6*3^level
#
# Nstart(level) = 1 + ringlen(0) + ... + ringlen(level-1)
#               = 1 + 6* [ 3^0 + ... + 3^(level-1) ]
#               = 1 + 6* [ (3^level - 1) / 2 ]
#               = 1 + 3*(3^level - 1)
#               = 1 + 3*3^level - 3
#               = 3^(level+1) - 2
#
# 3^(level+1) = N+2
# level+1 = log3(N+2)
# level = log3(N+2) - 1
#
# sides=3
# ringlen = 3*3^level
# Nstart(level) = 1 + 3* [ 3^0 + ... + 3^(level-1) ]
#               = 1 + 3* [ (3^level - 1) / 2 ]
#               = 1 + 3*(3^level - 1)/2
#               = 1 + (3*3^level - 3)/2
#               = (3*3^level - 3 + 2)/2
#               = (3^(level+1) - 1)/2
# 3^(level+1) - 1 = 2*N
# 3^(level+1) = 2*N+1

my @_xend = (2, 5);
my @_yend = (0, 1);
my @_hypotend = (4, 28);
sub _ends_for_level {
  my ($level) = @_;
  if ($#_xend < $level) {
    my $x = $_xend[-1];
    my $y = $_yend[-1];
    do {
      ($x,$y) = ((5*$x - 3*$y)/2,   # 2*$x + rotate +60
                 ($x + 5*$y)/2);    # 2*$y + rotate +60
      ### _ends_for_level() push: scalar(@_xend)."  $x,$y"
      # ### assert: "$x,$y" eq join(','__PACKAGE__->n_to_xy(scalar(@xend) ** 3))
      push @_xend, $x;
      push @_yend, $y;
      push @_hypotend, $_hypotend[-1] * 7;
    } while ($#_xend < $level);
  }
}

my @level_x = (0);
my @level_y = (0);

sub n_to_xy {
  my ($self, $n) = @_;
  ### GosperIslands n_to_xy(): $n
  if ($n < 1) {
    return;
  }
  if (is_infinite($n)) {
    return ($n,$n);
  }

  my $sides = $self->{'sides'};
  my ($pow, $level) = round_down_pow (($sides == 6 ? $n+2 : 2*$n+1),
                                      3);
  my $base = ($sides == 6 ? $pow-2 : ($pow-1)/2);
  ### $level
  ### $base

  $n -= $base;  # remainder
  my $sidelen = $pow / 3;
  $level--;
  my $side = int ($n / $sidelen);
  my ($x, $y) = _side_n_to_xy ($n - $side*$sidelen);

  _ends_for_level($level);
  ### raw xy: "$x,$y"
  ### pos: "$_xend[$level],$_yend[$level]"

  if ($sides == 6) {
    ($x,$y) = (($x+3*$y)/-2,             # rotate +120
               ($x-$y)/2);
    ### rotate xy: "$x,$y"

    $x += $_xend[$level];
    $y += $_yend[$level];
    if ($side >= 3) {
      $x = -$x;   # rotate 180
      $y = -$y;
      $side -= 3;
    }
    if ($side == 1) {
      ($x,$y) = (($x-3*$y)/2,   # rotate +60
                 ($x+$y)/2);
    } elsif ($side == 2) {
      ($x,$y) = (($x+3*$y)/-2,  # rotate +120
                 ($x-$y)/2);
    }
  } else {
    my $xend = $_xend[$level];
    my $yend = $_yend[$level];
    my $xp = 0;
    my $yp = 0;
    foreach (0 .. $level-1) {
      $xp +=$_xend[$_];
      $yp +=$_yend[$_];
    }
    ### ends: "$xend,$yend prev $xp,$yp"
    ($xp,$yp) = (($xp-3*$yp)/-2,   # rotate -120
                 ($xp+$yp)/-2);
    # ($xp,$yp) = (($xp-3*$yp)/2,   # rotate +60
    #              ($xp+$yp)/2);
    if ($side == 0) {
      $x += $xp;
      $y += $yp;
    } elsif ($side == 1) {
      ($x,$y) = (($x+3*$y)/-2,  # rotate +120
                 ($x-$y)/2);
      $x += $xp;
      $y += $yp;
      $x += $xend;
      $y += $yend;
    } elsif ($side == 2) {
      ($x,$y) = (($x-3*$y)/-2,   # rotate +240==-120
                 ($x+$y)/-2);
      $x += $xp;
      $y += $yp;
      $x += $xend;
      $y += $yend;
      ($xend,$yend) = (($xend+3*$yend)/-2,  # rotate +120
                       ($xend-$yend)/2);
      $x += $xend;
      $y += $yend;
    }
  }
  return ($x,$y);
}

# ENHANCE-ME: share with GosperSide ?
sub _side_n_to_xy {
  my ($n) = @_;
  ### _side_n_to_xy(): $n
  if ($n < 0) {
    return;
  }
  if (is_infinite($n)) {
    return ($n,$n);
  }

  my $x;
  my $y = 0;
  {
    my $int = int($n);
    $x = 2*($n - $int);
    $n = $int;  # BigFloat int() gives BigInt, use that
  }
  my $xend = 2;
  my $yend = 0;

  foreach my $digit (digit_split_lowtohigh($n,3)) {
    my $xend_offset = 3*($xend-$yend)/2;   # end and end +60
    my $yend_offset = ($xend+3*$yend)/2;

    ### at: "$x,$y"
    ### $digit
    ### $xend
    ### $yend
    ### $xend_offset
    ### $yend_offset

    if ($digit == 1) {
      ($x,$y) = (($x-3*$y)/2  + $xend,   # rotate +60
                 ($x+$y)/2    + $yend);
    } elsif ($digit == 2) {
      $x += $xend_offset;   # offset and offset +60
      $y += $yend_offset;
    }
    $xend += $xend_offset;   # offset and offset +60
    $yend += $yend_offset;
  }

  ### final: "$x,$y"
  return ($x, $y);
}


#------------------------------------------------------------------------------
# xy_to_n()

# innermost origin 0,0 N=0 level 0,
# first hexagon level 1
#
# Nstart(level) = 3^level - 2
# sidelength(level) = 3^(level-1)
# so Nstart(level) + side * sidelength(level)
#  = 3^level - 2 + side * 3^(level-1)
#  = (3 + side) * 3^(level-1) - 2
#
sub xy_to_n {
  my ($self, $x_full, $y_full) = @_;
  $x_full = round_nearest($x_full);
  $y_full = round_nearest($y_full);
  ### GosperIslands xy_to_n(): "$x_full,$y_full"

  foreach my $overflow (3*$x_full+3*$y_full, 3*$x_full-3*$y_full) {
    if (is_infinite($overflow)) { return $overflow; }
  }
  if (($x_full + $y_full) % 2) {
    ### odd point, not reached ...
    return undef;
  }

  my $r = hypot($x_full,$y_full);
  my $level_limit = ceil(log($r+1)/log(sqrt(7)));
  ### $r
  ### $level_limit
  if (is_infinite($level_limit)) {
    return $level_limit;
  }

  for my $level (0 .. $level_limit + 1) {
    _ends_for_level($level);
    my $xend = $_xend[$level];
    my $yend = $_yend[$level];

    my $x = $x_full - $xend;
    my $y = $y_full - $yend;
    ### level end: "$xend,$yend"
    ### level subtract to: "$x,$y"
    ($x,$y) = ((3*$y-$x)/2,  # rotate -120;
               ($x+$y)/-2);
    ### level rotate to: "$x,$y"

    foreach my $side (0 .. 5) {
      ### try: "level=$level side=$side  $x,$y"
      if (defined (my $n = _xy_to_n_in_level($x,$y,$level))) {
        return ($side+3)*3**$level + $n - 2;
      }
      $x -= $xend;
      $y -= $yend;
      ### subtract to: "$x,$y"
      ($x,$y) = (($x+3*$y)/2,   # rotate -60
                 ($y-$x)/2);

    }
  }
  return undef;
}

sub _xy_to_n_in_level {
  my ($x, $y, $level) = @_;

  _ends_for_level($level);
  my @pending_n = (0);
  my @pending_x = ($x);
  my @pending_y = ($y);
  my @pending_level = ($level);

  while (@pending_n) {
    my $n = pop @pending_n;
    $x = pop @pending_x;
    $y = pop @pending_y;
    $level = pop @pending_level;
    ### consider: "$x,$y  n=$n level=$level"

    if ($level == 0) {
      if ($x == 0 && $y == 0) {
        return $n;
      }
      ### level=0 and not 0,0
      next;
    }
    if (($x*$x+3*$y*$y) > $_hypotend[$level] * 1.1) {
      ### radius out of range: ($x*$x+3*$y*$y)." cf end ".$_hypotend[$level]
      next;
    }

    $level--;
    $n *= 3;
    my $xend = $_xend[$level];
    my $yend = $_yend[$level];
    ### descend: "end=$xend,$yend on level=$level"

    # digit 0
    push @pending_n, $n;
    push @pending_x, $x;
    push @pending_y, $y;
    push @pending_level, $level;
    ### push: "$x,$y  digit=0"

    # digit 1
    $x -= $xend;
    $y -= $yend;
    ($x,$y) = (($x+3*$y)/2,   # rotate -60
               ($y-$x)/2);
    push @pending_n, $n + 1;
    push @pending_x, $x;
    push @pending_y, $y;
    push @pending_level, $level;
    ### push: "$x,$y  digit=1"

    # digit 2
    $x -= $xend;
    $y -= $yend;
    ($x,$y) = (($x-3*$y)/2,   # rotate +60
               ($x+$y)/2);
    push @pending_n, $n + 2;
    push @pending_x, $x;
    push @pending_y, $y;
    push @pending_level, $level;
    ### push: "$x,$y  digit=2"
  }

  return undef;
}

# Each
#           *---
#          /
#      ---*
# is width=5 heightflat=1 is
#     hypot^2 = 5*5 + 3 * 1*1
#             = 25+3
#             = 28
#     hypot = 2*sqrt(7)
#
# comes in closer to
#     level=1   n=9,x=2,y=2  is hypot=sqrt(2*2+3*2*2) = sqrt(16) = 4
#     level=2   n=31,x=2,y=6 is hypot=sqrt(2*2+3*6*6) = sqrt(112) = sqrt(7)*4
# so
#     radius = 4 * sqrt(7)^(level-1)
#     radius/4 = sqrt(7)^(level-1)
#     level-1 = log(radius/4) / log(sqrt(7))
#     level = log(radius/4) / log(sqrt(7)) + 1
#
# Or
#     level=1   n=9,x=2,y=2  is h=2*2+3*2*2 = 16
#     level=2   n=31,x=2,y=6 is h=2*2+3*6*6 = 112 = 7*16
#     h = 16 * 7^(level-1)
#     h/16 = 7^(level-1)
#     level-1 = log(h/16) / log(7)
#     level = log(h/16) / log(7) + 1
#
# is the next outer level, so high covering is the end of the previous
# level,
#
# Nstart(level) - 1 = 3^(level+2) - 2 - 1
#                   = 3^(level+2) - 3
#
# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  $y1 *= sqrt(3);
  $y2 *= sqrt(3);
  my ($r_lo, $r_hi) = Math::PlanePath::SacksSpiral::_rect_to_radius_range
    ($x1,$y1, $x2,$y2);
  $r_hi *= 2;
  my $level_plus_1 = ceil( log(max(1,$r_hi/4)) / log(sqrt(7)) ) + 2;
  return (1, 3**$level_plus_1 - 3);
}

1;
__END__

=for stopwords eg Ryde Gosper Nstart wiggliness versa PlanePath Math-PlanePath

=head1 NAME

Math::PlanePath::GosperIslands -- concentric Gosper islands

=head1 SYNOPSIS

 use Math::PlanePath::GosperIslands;
 my $path = Math::PlanePath::GosperIslands->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

X<Gosper, William>This path is integer versions of the Gosper island at
successive levels, arranged as concentric rings on a triangular lattice (see
L<Math::PlanePath/Triangular Lattice>).  Each island is the outline of a
self-similar tiling of the plane by hexagons, and the sides are self-similar
expansions of line segments

          35----34                                           8
         /        \
    ..-36          33----32          29----28                7
                           \        /        \
                            31----30          27----26       6
                                                      \
                                                       25    5

                                                    78       4
                                                      \
                   11-----10                           77    3
                  /         \                         /
          13----12           9---- 8                76       2
         /                          \                 \
       14           3---- 2           7                ...   1
         \        /        \
          15     4           1    24                     <- Y=0
         /        \                 \
       16           5----- 6         23                     -1
         \                          /
          17----18          21----22                        -2
                  \        /
                   19----20                                 -3




       -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6  7  8  9 10 11

=head2 Hexagon Replications

The islands can be thought of as a self-similar tiling of the plane by
hexagonal shapes.  The innermost hexagon N=1 to N=6 is replicated six times
to make the next outline N=7 to N=24.

                *---*
               /     \
          *---*       *---*
         /     \     /     \
        *       *---*       *
         \     /     \     /
          *---*       *---*
         /     \     /     \
        *       *---*       *
         \     /     \     /
          *---*       *---*
               \     /
                *---*

Then that shape is in turn replicated six times around itself to make the
next level.


                        *---E
                       /     \
                  *---*       *---*       *---*
                 /                 \     /     \
                *                   *---*       *---*
                 \                 /                 \
                  *               *                   D
                 /                 \                 /
            *---*                   *               *
           /     \                 /                 \
      *---*       *---*       *---*                   *
     /                 \     /     \                 /
    *                   *---*       *---*       *---*
     \                 /                 \     /     \
      *               *                   C---*       *---*
     /                 \                 /                 \
    *                   *       O       *                   *
     \                 /                 \                 /
      *---*       *---*                   *               *
           \     /     \                 /                 \
            *---*       *---*       *---*                   *
           /                 \     /     \                 /
          *                   *---*       *---*       *---*
           \                 /                 \     /
            *               *                   *---*
           /                 \                 /
          *                   *               *
           \                 /                 \
            *---*       *---*                   *
                 \     /     \                 /
                  *---*       *---*       *---*
                                   \     /
                                    *---*

The shapes here and at higher level are like hexagons with wiggly sides.
The sides are symmetric, so they mate on opposite sides but the join
"corner" is not on the X axis (after the first level).  For example the
point marked "C" (N=7) is above the axis at X=5,Y=1.  The next replication
joins at point "D" (N=25) at X=11,Y=5.

=head2 Side and Radial Lines

The sides at each level is a self-similar line segment expansion,

                                 *---*
      *---*     becomes         /
                           *---*

This expanding side shape is also the radial line or spoke from the origin
out to "corner" join points.  At level 0 they're straight lines,

       ...----*
             / \
            /   \ side
           /     \
          /       \
         O---------*
                  /
                 /

Then at higher levels they're wiggly, such as level 1,

    ...--*
        / \
       *   *---*
        \       \
         *   *---C
        /   /   /
       O---*   ...

Or level 2,

         *---E
      ...   / \
           *   *---*       *---*
            \       \     /     \
             *       *---*       *---*
            /                         \
           *                       *---D
            \                     /   /
             *---*           *---*   ...
                  \         /
                   *       *
                  /         \
                 *           *
                  \         /
                   *   *---C
                  /   /
                 O---*

The lines become ever wigglier at higher levels, and in fact become "S"
shapes with the ends spiralling around and in (and in fact middle sections
likewise S and spiralling, to a lesser extent).

The spiralling means that the X axis is crossed multiple times at higher
levels.  For example in level 11 X>0,Y=0 occurs 22 times between N=965221 and
N=982146.  Likewise on diagonal lines X=Y and X=-Y which are "sixths" of the
initial hexagon.

The self-similar spiralling means the Y axis too is crossed multiple times
at higher levels.  In level 11 again X=0,Y>0 is crossed 7 times between
N=1233212 and N=1236579.  (Those N's are bigger than the X axis crossing,
because the Nstart position at level 11 has rotated around some 210 degrees
to just under the negative X axis.)

In general any radial straight line is crossed many times way eventually.

=head2 Level Ranges

Counting the inner hexagon as level=0, the side length and whole ring is

    sidelen = 3^level
    ringlen = 6 * 3^level

The starting N for each level is the total points preceding it, so

    Nstart = 1 + ringlen(0) + ... + ringlen(level-1)
           = 3^(level+1) - 2

For example level=2 starts at Nstart=3^3-2=25.

The way the side/radial lines expand as described above makes the Nstart
position rotate around at each level.  N=7 is at X=5,Y=1 which is angle

    angle = arctan(1*sqrt(3) / 5)
          = 19.106.. degrees

The sqrt(3) factor as usual turns the flattened integer X,Y coordinates into
proper equilateral triangles.  The further levels are then multiples of that
angle.  For example N=25 at X=11,Y=5 is 2*angle, or N=79 at X=20,Y=18 at
3*angle.

The N=7 which is the first radial replication at X=5,Y=1, scaled to unit
sided equilateral triangles, has distance from the origin

    d1 = hypot(5, 1*sqrt(3)) / 2
       = sqrt(7)

The subsequent levels are powers of that sqrt(7),

    Xstart,Ystart of the Nstart(level) position

    d = hypot(Xstart,Ystart*sqrt(3))/2
      = sqrt(7) ^ level

This multiple of the angle and powering of the radius means the Nstart
points are on a logarithmic spiral.

=head2 Fractal Island

The Gosper island is usually conceived as a fractal, with the initial
hexagon in a fixed position and the sides having the line segment
substitution described above, for ever finer levels of "S" spiralling
wiggliness.  The code here can be used for that by rotating the Nstart
position back to the X axis and scaling down to a desired unit radius.

    Xstart,Ystart of the Nstart(level) position

    scale factor = 0.5 / hypot(Ystart*sqrt(3), Xstart)
    rotate angle = - atan2 (Ystart*sqrt(3), Xstart)

This scale and rotate puts the Nstart point at X=1,Y=0 and further points of
the ring around from that.  Remember the sqrt(3) factor on Y for all points
to turn the integer coordinates into proper equilateral triangles.

Notice the line segment substitution doesn't change the area of the initial
hexagon.  Effectively (and not to scale),

                                 *
                                / \ 
    *-------*    becomes   *   /   *
                            \ /   
                             *

So the area lost below is gained above (or vice versa).  The result is a
line of ever greater length enclosing an unchanging area.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::GosperIslands-E<gt>new ()>

Create and return a new path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 1 and if C<$n E<lt> 0> then the return is an empty list.

=back

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::KochSnowflakes>,
L<Math::PlanePath::GosperSide>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018 Kevin Ryde

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
