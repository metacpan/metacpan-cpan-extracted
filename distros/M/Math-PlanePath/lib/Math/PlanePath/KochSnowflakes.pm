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


# math-image --path=KochSnowflakes --lines --scale=10
#
# area approaches sqrt(48)/10
#     *     height=sqrt(1-1/4)=sqrt(3)/2
#    /|\    halfbase=1/2
#   / | \   trianglearea = sqrt(3)/4
#  *-----*
# segments = 3*4^level = 3,12,48,192,...
#
# with initial triangle area=1
# add a new triangle onto each side
# x,y scale by 3* so 9*area
#
# area[level+1] = 9*area[level] + segments
#               = 9*area[level] + 3*4^level

# area[0] = 1
# area[1] = 9*area[0] + 3       = 9 + 3 = 12
# area[2] = 9*area[1] + 3*4
#         = 9*(9*1 + 3) + 3*4
#         = 9*9 + 3*9 + 3*4     = 120
# area[3] = 9*area[2] + 3*4
#         = 9*(9*9 + 3*9 + 3*4) + 3*4^2
#         = 9^3 + 3*9^2 + 3*0*4 + 3*4^2

# area[level+1]
#   = 9^(level+1) + (9^(level+1) - 4^(level+1)) * 3/5
#   = (5*9^(level+1) + 3*9^(level+1) - 3*4^(level+1)) / 5
#   = (8*9^(level+1) - 3*4^(level+1)) / 5
#
# area[level] = (8*9^level - 3*4^level) / 5
#             = 1,12,120,1128,10344,93864,847848
#
#         .
#        / \       area[0] = 1
#       .---.  
#
#         .
#        / \       area=[1] = 12 = 9*area[0] + 3*4^0
#   .---.---.---.
#    \ / \ / \ /
#     .---.---.
#    / \ / \ / \
#   .---.---.---.
#        \ /
#         .
#
# area[level] / 9^level
#   = (8*9^level / 9^level - 3*4^level / 9^level) / 5
#   = (8 - 3*(4/0)^level)/5
#   -> 8/5   as level->infinity

# in integer coords
# initial triangle area
#         *       2/3        1*2 / 2 = 1 unit
#        / \
#       *---*     -1/3
#      -1   +1
#
# so area[level] / (sqrt(3)/2)



package Math::PlanePath::KochSnowflakes;
use 5.004;
use strict;
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
  'round_down_pow';
use Math::PlanePath::KochCurve;

# uncomment this to run the ### lines
# use Smart::Comments;


use constant n_frac_discontinuity => 0;
use constant x_negative_at_n => 1;
use constant y_negative_at_n => 1;
use constant sumabsxy_minimum => 2/3; # minimum X=0,Y=2/3
use constant rsquared_minimum => 4/9; # minimum X=0,Y=2/3
# maybe: use constant radius_minimum => 2/3; # minimum X=0,Y=2/3

# jump across rings is WSW slope 2, so following maximums
use constant dx_maximum => 2;
use constant dy_maximum => 1;
use constant dsumxy_maximum => 2;
use constant ddiffxy_maximum => 2;

use constant absdx_minimum => 1; # never vertical
use constant dir_maximum_dxdy => (1,-1); # South-East

# N=1 gcd(-1, -1/3) = 1/3
# N=2 gcd( 1, -1/3) = 1/3
# N=3 gcd( 0, 2/3)  = 2/3
use constant gcdxy_minimum => 1/3;

use constant turn_any_straight => 0; # never straight


#------------------------------------------------------------------------------
sub new {
  my $self = shift->SUPER::new (@_);
  $self->{'sides'} ||= 3; # default
  return $self;
}

# N=1 to 3      3 of, level=1
# N=4 to 15    12 of, level=2
# N=16 to ..   48 of, level=3
#
# each loop = 3*4^level
#
#     n_base = 1 + 3*4^0 + 3*4^1 + ... + 3*4^(level-1)
#            = 1 + 3*[ 4^0 + 4^1 + ... + 4^(level-1) ]
#            = 1 + 3*[ (4^level - 1)/3 ]
#            = 1 + (4^level - 1)
#            = 4^level
#
# each side = loop/3
#           = 3*4^level / 3
#           = 4^level
#
# 6 sides
# n_base = 1 + 2*3*4^0 + ...
#        = 2*4^level - 1
# level = log4 (n+1)/2

### loop 1: 3* 4**1
### loop 2: 3* 4**2
### loop 3: 3* 4**3

# sub _level_to_base {
#   my ($level) = @_;
#   return -3*$level + 4**($level+1) - 2;
# }
# ### level_to_base(1): _level_to_base(1)
# ### level_to_base(2): _level_to_base(2)
# ### level_to_base(3): _level_to_base(3)

sub n_to_xy {
  my ($self, $n) = @_;
  ### KochSnowflakes n_to_xy(): $n
  if ($n < 1) { return; }
  if (is_infinite($n)) { return ($n,$n); }

  my $sides = $self->{'sides'};
  my ($sidelen, $level) = round_down_pow (($sides == 6 ? ($n+1)/2 : $n),
                                          4);
  my $base = ($sides == 6 ? 2*$sidelen - 1 : $sidelen);
  my $rem = $n - $base;

  ### $level
  ### $base
  ### $sidelen
  ### $rem
  ### assert: $n >= $base
  ### assert: $rem >= 0
  ### assert: $rem < $sidelen * $sides

  my $side = int($rem / $sidelen);
  ### $side
  ### $rem
  ### subtract: $side*$sidelen
  $rem -= $side*$sidelen;

  ### assert: $side >= 0 && $side < $sides

  my ($x, $y) = Math::PlanePath::KochCurve->n_to_xy ($rem);
  ### $x
  ### $y

  if ($sides == 3) {
    my $len = 3**($level-1);
    if ($side < 1) {
      ### horizontal rightwards
      return ($x - 3*$len,
              -$y - $len);
    } elsif ($side < 2) {
      ### right slope upwards
      return (($x-3*$y)/-2 + 3*$len,  # flip vert and rotate +120
              ($x+$y)/2 - $len);
    } else {
      ### left slope downwards
      return ((-3*$y-$x)/2,  # flip vert and rotate -120
              ($y-$x)/2 + 2*$len);
    }
  } else {

    #          3
    #     5-----4
    #  4 /       \
    #   /         \ 2
    #  6     o     3
    # 5 \   . .   /
    #    \ .   . / 1
    #     1-----2
    #      0
    #  7
    #
    my $len = 3**$level;
    $x -= $len;    # -y flip vert and offset
    $y = -$y - $len;
    if ($side >= 3) {
      ### rotate 180 ...
      $x = -$x;   # rotate 180
      $y = -$y;
      $side -= 3;
    }
    if ($side >= 2) {
      ### upper right slope upwards ...
      return (($x+3*$y)/-2,  # rotate +120
              ($x-$y)/2);
    }
    if ($side >= 1) {
      ### lower right slope upwards ...
      return (($x-3*$y)/2,  # rotate +60
              ($x+$y)/2);
    }
    ### horizontal ...
    return ($x,$y);
  }
}


# N=1 overlaps N=5
# N=2 overlaps N=7
#      +---------+         +---------+   Y=1.5
#      |         |         |         |
#      |         +---------+         |   Y=7/6 = 1.166
#      |         |         |         |
#      |    * 13 |         |    * 11 |   Y=1
#      |         |         |         |
#      |         |    * 3  |         |   Y=2/3 = 0.666
#      |         |         |         |
#      +---------+         +---------+   Y=0.5
#                |         |
#      +---------+---------+---------+   Y=1/6 = 0.166
#      |         |    O    |         | --Y=0
#      |         |         |         |
#      |         |         |         |
#      |    * 1  |         |    * 2  |   Y=-1/3 = -0.333
#      |         |         |         |
#      +---------+         +---------+   Y=-3/6 = -0.5
#      |         |         |         |
#      +---------+         +---------+   Y=-5/6 = -0.833
#      |         |         |         |
#      |    * 5  |         |    * 7  |   Y=-1
#      |         |         |         |
#      |         |         |         |
#      +---------+         +---------+   Y=-1.5
#
sub xy_to_n {
  return scalar((shift->xy_to_n_list(@_))[0]);
}
sub xy_to_n_list {
  my ($self, $x, $y) = @_;
  ### KochSnowflakes xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  if (abs($x) <= 1) {
    if ($x == 0) {
      my $y6 = 6*$y;
      if ($y6 >= 1 && $y6 < 7) {
        # Y = 2/3-1/2=1/6 to 2/3+1/2=7/6
        return 3;
      }
    } else {
      my $y6 = 6*$y;
      if ($y6 >= -5 && $y6 < 1) {
        # Y = -1/3-1/2=-5/6 to -1/3+1/2=+1/6
        return (1 + ($x > 0),
                ($y6 < -3 ? (5+2*($x>0)) : ()));   # 5 or 7 up to Y<-1/2
      }
    }
  }

  $y = round_nearest ($y);
  if (($x % 2) != ($y % 2)) {
    ### diff parity...
    return;
  }

  my $high;
  if ($x > 0 && $x >= -3*$y) {
    ### right upper third n=2 ...
    ($x,$y) = ((3*$y-$x)/2,   # rotate -120 and flip vert
               ($x+$y)/2);
    $high = 2;
  } elsif ($x <= 0 && 3*$y > $x) {
    ### left upper third n=3 ...
    ($x,$y) = (($x+3*$y)/-2,             # rotate +120 and flip vert
               ($y-$x)/2);
    $high = 3;
  } else {
    ### lower third n=1 ...
    $y = -$y;  # flip vert
    $high = 1;
  }
  ### rotate/flip is: "$x,$y"

  if ($y <= 0) {
    return;
  }

  my ($len,$level) = round_down_pow($y, 3);
  $level += 1;
  ### $level
  ### $len
  if (is_infinite($level)) {
    return $level;
  }


  $y -= $len;  # shift to Y=0 basis
  $len *= 3;

  ### compare for end: ($x+$y)." >= 3*len=".$len
  if ($x + $y >= $len) {
    ### past end of this level, no points ...
    return;
  }
  $x += $len;  # shift to X=0 basis

  my $n = Math::PlanePath::KochCurve->xy_to_n($x, $y);

  ### plain curve on: ($x+3*$len).",".($y-$len)."  n=".(defined $n && $n)
  ### $high
  ### high: (4**$level)*$high

  if (defined $n) {
    return (4**$level)*$high + $n;
  } else {
    return;
  }
}

# level extends to x= +/- 3^level
#                  y= +/- 2*3^(level-1)
#                   =     2/3 * 3^level
#                  1.5*y = 3^level
#
# ENHANCE-ME: share KochCurve segment checker to find actual min/max
#
# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### KochSnowflakes rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;

  #
  #          |
  # +------  .   -----+
  # |x1,y2  /|\  x2,y2|
  #        / | \
  #       /  |  \
  # -----/---m---\-----
  #     /    |    \
  #    .-----------.
  #          |
  #           y1
  #        -------
  #
  # -y1 bottom horizontal
  # (x2+y2)/2 right side
  # (-x1+y2)/2 left side
  # each giving a power of 3 of the level
  #
  ### right: ($x2+$y2)/2
  ### left: (-$x1+$y2)/2
  ### bottom: -$y1

  my $sides = $self->{'sides'};
  my ($pow, $level) = round_down_pow (max ($sides == 6
                                           ? ($x1/-2,
                                              $x2/2,
                                              -$y1,
                                              $y2)
                                           : (int(($x2+$y2)/2),
                                              int((-$x1+$y2)/2),
                                              -$y1)),
                                      3);
  ### $level
  # end of $level is 1 before base of $level+1
  return (1, 4**($level+2) - 1);
}

#------------------------------------------------------------------------------
# Nstart = 4^k
# length = 3*4^k many points
# Nend = Nstart + length-1
#      = 4^k + 3*4^k - 1
#      = 4*4^k - 1
#      = Nstart(k+1) - 1
sub level_to_n_range {
  my ($self, $level) = @_;
  my $pow = 4**$level;
  return ($pow, 4*$pow-1);
}
sub n_to_level {
  my ($self, $n) = @_;
  if ($n < 1) { return undef; }
  if (is_infinite($n)) { return $n; }
  $n = round_nearest($n);
  my ($sidelen, $level) = round_down_pow (($self->{'sides'} == 6 ? ($n+1)/2 : $n),
                                          4);
  return $level;
}

#------------------------------------------------------------------------------
1;
__END__

=for stopwords eg Ryde ie SVG Math-PlanePath Ylo OEIS

=head1 NAME

Math::PlanePath::KochSnowflakes -- Koch snowflakes as concentric rings

=head1 SYNOPSIS

 use Math::PlanePath::KochSnowflakes;
 my $path = Math::PlanePath::KochSnowflakes->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path traces out concentric integer versions of the Koch snowflake at
successively greater iteration levels.

                               48                                6
                              /  \
                      50----49    47----46                       5
                        \              /
             54          51          45          42              4
            /  \        /              \        /  \
    56----55    53----52                44----43    41----40     3
      \                                                  /
       57                      12                      39        2
      /                       /  \                       \
    58----59          14----13    11----10          37----38     1
            \           \       3      /           /
             60          15  1----2   9          36         <- Y=0
            /                          \           \
    62----61           4---- 5    7---- 8           35----34    -1
      \                       \  /                       /
       63                       6                      33       -2
                                                         \
    16----17    19----20                28----29    31----32    -3
            \  /        \              /        \  /
             18          21          27          30             -4
                        /              \
                      22----23    25----26                      -5
                              \  /
                               24                               -6

                                ^
    -9 -8 -7 -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6  7  8  9

The initial figure is the triangle N=1,2,3 then for the next level each
straight side expands to 3x longer and a notch like N=4 through N=8,

      *---*     becomes     *---*   *---*
                                 \ /
                                  *

The angle is maintained in each replacement, for example the segment N=5 to
N=6 becomes N=20 to N=24 at the next level.

=head2 Triangular Coordinates

The X,Y coordinates are arranged as integers on a square grid per
L<Math::PlanePath/Triangular Lattice>, except the Y coordinates of the
innermost triangle which is

                  N=3     X=0, Y=+2/3
                   *
                  / \
                 /   \
                /     \
               /   o   \
              /         \
         N=1 *-----------* N=2
    X=-1, Y=-1/3      X=1, Y=-1/3

These values are not integers, but they're consistent with the
centring and scaling of the higher levels.  If all-integer is desired
then rounding gives Y=0 or Y=1 and doesn't overlap the subsequent
points.

=head2 Level Ranges

Counting the innermost triangle as level 0, each ring is

    Nstart = 4^level
    length = 3*4^level    many points

For example the outer ring shown above is level 2 starting N=4^2=16 and
having length=3*4^2=48 points (through to N=63 inclusive).

The X range at a given level is the initial triangle baseline iterated out.
Each level expands the sides by a factor of 3 so

     Xlo = -(3^level)
     Xhi = +(3^level)

For example level 2 above runs from X=-9 to X=+9.  The Y range is the
points N=6 and N=12 iterated out.  Ylo in level 0 since there's no
downward notch on that innermost triangle.

    Ylo = / -(2/3)*3^level if level >= 1
          \ -1/3           if level == 0
    Yhi = +(2/3)*3^level

Notice that for each level the extents grow by a factor of 3 but the
notch introduced in each segment is not big enough to go past the
corner positions.  They can equal the extents horizontally, for
example in level 1 N=14 is at X=-3 the same as the corner N=4, and on
the right N=10 at X=+3 the same as N=8, but they don't go past.

The snowflake is an example of a fractal curve with ever finer structure.
The code here can be used for that by going from N=Nstart to
N=Nstart+length-1 and scaling X/3^level Y/3^level to give a 2-wide 1-high
figure of desired fineness.  See F<examples/koch-svg.pl> for a complete
program doing that as an SVG image file.

=head2 Area

The area of the snowflake at a given level can be calculated from the area
under the Koch curve per L<Math::PlanePath::KochCurve/Area> which is the 3
sides, and the central triangle

                 *          ^ Yhi
                / \         |          height = 3^level
               /   \        |                 
              /     \       |
             *-------*      v

             <------->      width = 3^level - (- 3^level) = 2*3^level
            Xlo      Xhi

    triangle_area = width*height/2 = 9^level

    snowflake_area[level] = triangle_area[level] + 3*curve_area[level]
                          = 9^level + 3*(9^level - 4^level)/5
                          = (8*9^level - 3*4^level) / 5

If the snowflake is conceived as a fractal of fixed initial triangle size
and ever-smaller notches then the area is divided by that central triangle
area 9^level,

    unit_snowflake[level] = snowflake_area[level] / 9^level
                          = (8 - 3*(4/9)^level) / 5
                          -> 8/5      as level -> infinity

Which is the well-known 8/5 * initial triangle area for the fractal
snowflake.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::KochSnowflakes-E<gt>new ()>

Create and return a new path object.

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return per L</Level Ranges> above,

    (4**$level,
     4**($level+1) - 1)

=back

=head1 FORMULAS

=head2 Rectangle to N Range

As noted in L</Level Ranges> above, for a given level

          -(3^level) <= X <= 3^level
    -(2/3)*(3^level) <= Y <= (2/3)*(3^level)

So the maximum X,Y in a rectangle gives

    level = ceil(log3(max(abs(x1), abs(x2), abs(y1)*3/2, abs(y2)*3/2)))

and the last point in that level is

    Nlevel = 4^(level+1) - 1

Using this as an N range is an over-estimate, but an easy calculation.  It's
not too difficult to trace down for an exact range


=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to the
Koch snowflake include the following.  See
L<Math::PlanePath::KochCurve/OEIS> for entries related to a single Koch side.

=over

L<http://oeis.org/A164346> (etc)

=back

    A164346   number of points in ring n, being 3*4^n
    A178789   number of acute angles in ring n, 4^n + 2
    A002446   number of obtuse angles in ring n, 2*4^n - 2

The acute angles are those of +/-120 degrees and the obtuse ones +/-240
degrees.  Eg. in the outer ring=2 shown above the acute angles are at N=18,
22, 24, 26, etc.  The angles are all either acute or obtuse, so A178789 +
A002446 = A164346.    

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::KochCurve>,
L<Math::PlanePath::KochPeaks>

L<Math::PlanePath::QuadricIslands>

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
