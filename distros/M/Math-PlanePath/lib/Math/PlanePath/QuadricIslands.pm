# Copyright 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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


# math-image --path=QuadricIslands --lines --scale=10
# math-image --path=QuadricIslands --all --output=numbers_dash --size=132x50


package Math::PlanePath::QuadricIslands;
use 5.004;
use strict;
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 124;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest',
  'floor';
use Math::PlanePath::Base::Digits
  'round_down_pow';

use Math::PlanePath::QuadricCurve;

# uncomment this to run the ### lines
#use Smart::Comments;


use constant n_frac_discontinuity => 0;
use constant x_negative_at_n => 1;
use constant y_negative_at_n => 1;
use constant sumabsxy_minimum => 1;   # minimum X=1/2,Y=1/2
use constant rsquared_minimum => 0.5; # minimum X=1/2,Y=1/2

use constant dx_maximum => 1;
use constant dy_maximum => 1;
use constant dsumxy_maximum => 1;
use constant ddiffxy_minimum => -1; # dDiffXY=+1 or -1
use constant ddiffxy_maximum => 1;
use constant dir_maximum_dxdy => (0,-1); # South

# N=1,2,3,4  gcd(1/2,1/2) = 1/2
use constant gcdxy_minimum => 1/2;

#------------------------------------------------------------------------------

# N=1 to 4      4 of, level=0
# N=5 to 36    12 of, level=1
# N=37 to ..   48 of, level=3
#
# each loop = 4*8^level
#
#     n_base = 1 + 4*8^0 + 4*8^1 + ... + 4*8^(level-1)
#            = 1 + 4*[ 8^0 + 8^1 + ... + 8^(level-1) ]
#            = 1 + 4*[ (8^level - 1)/7 ]
#            = 1 + 4*(8^level - 1)/7
#            = (4*8^level - 4 + 7)/7
#            = (4*8^level + 3)/7
#
#     n >= (4*8^level + 3)/7
#     7*n = 4*8^level + 3
#     (7*n - 3)/4 = 8^level
#
#    nbase(k+1)-nbase(k)
#       = (4*8^(k+1)+3  - (4*8^k+3)) / 7
#       = (4*8*8^k - 4*8^k) / 7
#       = (4*8-4) * 8^k / 7
#       = 28 * 8^k / 7
#       = 4 * 8^k
#
#    nbase(0) = (4*8^0 + 3)/7 = (4+3)/7 = 1
#    nbase(1) = (4*8^1 + 3)/7 = (4*8+3)/7 = (32+3)/7 = 35/7 = 5
#    nbase(2) = (4*8^2 + 3)/7 = (4*64+3)/7 = (256+3)/7 = 259/7 = 37
#
### loop 1: 4* 8**1
### loop 2: 4* 8**2
### loop 3: 4* 8**3

# sub _level_to_base {
#   my ($level) = @_;
#   return (4*8**$level + 3) / 7;
# }
# ### level_to_base(1): _level_to_base(1)
# ### level_to_base(2): _level_to_base(2)
# ### level_to_base(3): _level_to_base(3)

# base = (4 * 8**$level + 3)/7
#      = (4 * 8**($level+1) / 8 + 3)/7
#      = (8**($level+1) / 2 + 3)/7
sub _n_to_base_and_level {
  my ($n) = @_;
  my ($base,$level) = round_down_pow ((7*$n - 3)*2, 8);
  return (($base/2 + 3)/7,
          $level - 1);
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### QuadricIslands n_to_xy(): "$n"
  if ($n < 1) { return; }
  if (is_infinite($n)) { return ($n,$n); }

  my ($base, $level) = _n_to_base_and_level($n);
  ### $level
  ### $base
  ### level: "$level"
  ### next base would be: (4 * 8**($level+1) + 3)/7

  my $rem = $n - $base;
  ### $rem

  ### assert: $n >= $base
  ### assert: $n < 8**($level+1)
  ### assert: $rem>=0
  ### assert: $rem < 4 * 8 ** $level

  my $sidelen = 8**$level;
  my $side = int($rem / $sidelen);
  ### $sidelen
  ### $side
  ### $rem
  $rem -= $side*$sidelen;
  ### assert: $side >= 0 && $side < 4
  my ($x, $y) = Math::PlanePath::QuadricCurve::n_to_xy ($self, $rem);

  my $pos = 4**$level / 2;
  ### side calc: "$x,$y   for pos $pos"
  ### $x
  ### $y

  if ($side < 1) {
    ### horizontal rightwards
    return ($x - $pos,
            $y - $pos);
  } elsif ($side < 2) {
    ### right vertical upwards
    return (-$y + $pos,     # rotate +90, offset
            $x - $pos);
  } elsif ($side < 3) {
    ### horizontal leftwards
    return (-$x + $pos,     # rotate 180, offset
            -$y + $pos);
  } else {
    ### left vertical downwards
    return ($y - $pos,     # rotate -90, offset
            -$x + $pos);
  }
}

#   +-------+-------+-------+
#   |31     | 24 0,1|     23|
#   |       |       |       |
#   |   +-------+-------+   |
#   |   |4  |   |3  |   |   |
#   |   |   |   |   |   |   |
#   +---|--- ---|--- ---|---+   Y=0.5
#   |32 |   |   |   |   | 16|
#   |   |   |   |   |   |   |
#   |   +=======+=======+   |   Y=0
#   |   |1  |   |2  |   |   |
#   |   |   |   |   |   |   |
#   +---|--- ---|--- ---|---+   Y=-0.5
#   |   |   |   |   |   |   |
#   |   |   |   |   |   |   |
#   |   +-------+-------+   |   Y=-1
#   |       |       |       |
#   |7      |8      |     15|
#   +-------+-------+-------+
#
# -2 <= 2*x < 2, round to -2,-1,0,1
# then 4*yround -8,-4,0,4
# total -10 to 5 inclusive

my @inner_n_list = ([1,7], [1,8], [2,8], [2,15],  # Y=-1
                    [1,32], [1],   [2],  [2,16],  # Y=-0.5
                    [4,32], [4],   [3],  [3,16],  # Y=0
                    [4,31],[4,24],[3,24],[3,23]); # Y=0.5

sub xy_to_n {
  return scalar((shift->xy_to_n_list(@_))[0]);
}
sub xy_to_n_list {
  my ($self, $x, $y) = @_;
  ### QuadricIslands xy_to_n(): "$x, $y"

  if ($x >= -1 && $x < 1
      && $y >= -1 && $y < 1) {

    ### round 2x: floor(2*$x)
    ### round 2y: floor(2*$y)
    ### index: floor(2*$x) + 4*floor(2*$y) + 10
    ### assert: floor(2*$x) + 4*floor(2*$y) + 10 >= 0
    ### assert: floor(2*$x) + 4*floor(2*$y) + 10 <= 15

    return @{$inner_n_list[ floor(2*$x)
                            + 4*floor(2*$y)
                            + 10 ]};
  }

  $x = round_nearest($x);
  $y = round_nearest($y);

  my $high;
  if ($x >= $y + ($y>0)) {
    # +($y>0) to exclude the downward bump of the top side
    ### below leading diagonal ...
    if ($x < -$y) {
      ### bottom quarter ...
      $high = 0;
    } else {
      ### right quarter ...
      $high = 1;
      ($x,$y) = ($y, -$x);   # rotate -90
    }
  } else {
    ### above leading diagonal
    if ($y > -$x) {
      ### top quarter ...
      $high = 2;
      $x = -$x;   # rotate 180
      $y = -$y;
    } else {
      ### right quarter ...
      $high = 3;
      ($x,$y) = (-$y, $x);   # rotate +90
    }
  }
  ### rotate to: "$x,$y   high=$high"

  # ymax = (10*4^(l-1)-1)/3
  # ymax < (10*4^(l-1)-1)/3+1
  # (10*4^(l-1)-1)/3+1 > ymax
  # (10*4^(l-1)-1)/3 > ymax-1
  # 10*4^(l-1)-1 > 3*(ymax-1)
  # 10*4^(l-1) > 3*(ymax-1)+1
  # 10*4^(l-1) > 3*(ymax-1)+1
  # 10*4^(l-1) > 3*ymax-3+1
  # 10*4^(l-1) > 3*ymax-2
  # 4^(l-1) > (3*ymax-2)/10
  #
  # (2*4^(l-1) + 1)/3 = ymin
  # 2*4^(l-1) + 1 = 3*y
  # 2*4^(l-1) = 3*y-1
  # 4^(l-1) = (3*y-1)/2
  #
  # ypos = 4^l/2 = 2*4^(l-1)


  # z = -2*y+x
  # (2*4**($level-1) + 1)/3 = z
  # 2*4**($level-1) + 1 = 3*z
  # 2*4**($level-1) = 3*z - 1
  # 4**($level-1) = (3*z - 1)/2
  #               = (3*(-2y+x)-1)/2
  #               = (-6y+3x - 1)/2
  #               = -3*y + (3x-1)/2

  # 2*4**($level-1) = -2*y-x
  # 4**($level-1) = -y-x/2
  # 4**$level = -4y-2x
  #
  # line slope y/x = 1/2 as an index
  my $z = -$y-$x/2;
  my ($len,$level) = round_down_pow ($z, 4);
  ### $z
  ### amin: 2*4**($level-1)
  ### $level
  ### $len
  if (is_infinite($level)) {
    return $level;
  }

  $len *= 2;
  $x += $len;
  $y += $len;
  ### shift to: "$x,$y"
  my $n = Math::PlanePath::QuadricCurve::xy_to_n($self, $x, $y);

  # Nmin = (4*8^l+3)/7
  # Nmin+high = (4*8^l+3)/7 + h*8^l
  #           = (4*8^l + 3 + 7h*8^l)/7 +
  #           = ((4+7h)*8^l + 3)/7
  #
  ### plain curve on: ($x+2*$len).",".($y+2*$len)."  give n=".(defined $n && $n)
  ### $high
  ### high: (8**$level)*$high
  ### base: (4 * 8**($level+1) + 3)/7
  ### base with high: ((4+7*$high) * 8**($level+1) + 3)/7

  if (defined $n) {
    return ((4+7*$high) * 8**($level+1) + 3)/7 + $n;
  } else {
    return;
  }
}

# level width extends
#    side = 4^level
#    ypos = 4^l / 2
#    width = 1 + 4 + ... + 4^(l-1)
#          = (4^l - 1)/3
#    ymin = ypos(l) - 4^(l-1) - width(l-1)
#         = 4^l / 2  - 4^(l-1) - (4^(l-1) - 1)/3
#         = 4^(l-1) * (2 - 1 - 1/3) + 1/3
#         = (2*4^(l-1) + 1) / 3
#
#    (2*4^(l-1) + 1) / 3 = y
#    2*4^(l-1) + 1 = 3*y
#    2*4^(l-1) = 3*y-1
#    4^(l-1) = (3*y-1)/2
#
# ENHANCE-ME: slope Y=X/2+1 or thereabouts for sides
#
# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### QuadricIslands rect_to_n_range(): "$x1,$y1  $x2,$y2"

  # $x1 = round_nearest ($x1);
  # $y1 = round_nearest ($y1);
  # $x2 = round_nearest ($x2);
  # $y2 = round_nearest ($y2);

  my $m = max(abs($x1), abs($x2),
              abs($y1), abs($y2));

  my ($len,$level) = round_down_pow (6*$m-2, 4);
  ### $len
  ### $level
  return (1,
          (32*8**$level - 4)/7);
}

#    ymax = ypos(l) + 4^(l-1) + width(l-1)
#         = 4^l / 2  + 4^(l-1) + (4^(l-1) - 1)/3
#         = 4^(l-1) * (4/2 + 1 + 1/3) - 1/3
#         = 4^(l-1) * (2 + 1 + 1/3) - 1/3
#         = 4^(l-1) * 10/3 - 1/3
#         = (10*4^(l-1) - 1) / 3
#
#    (10*4^(l-1) - 1) / 3 = y
#    10*4^(l-1) - 1 = 3*y
#    10*4^(l-1) = 3*y+1
#    4^(l-1) = (3*y+1)/10
#
# based on max ??? ...
#
# my ($power,$level) = round_down_pow ((3*$m+1-3)/10, 4);
# ### $power
# ### $level
# return (1,
#         (4*8**($level+3) + 3)/7 - 1);

#------------------------------------------------------------------------------
# Nstart(k) = (4*8^k + 3)/7
# Nend(k) = Nstart(k+1) - 1
#         = (4*8*8^k + 3)/7 - 1
#         = (4*8*8^k + 8*3 - 8*3 + 3)/7 - 1
#         = (4*8*8^k + 8*3)/7 + (-8*3 + 3)/7 - 1
#         = 8*Nstart(k) + (-8*3 + 3)/7 - 1
#         = 8*Nstart(k) - 4

sub level_to_n_range {
  my ($self, $level) = @_;
  my $n_lo = (4 * 8**$level + 3)/7;
  return ($n_lo, 8*$n_lo - 4);
}
sub n_to_level {
  my ($self, $n) = @_;
  if ($n < 1) { return undef; }
  if (is_infinite($n)) { return $n; }
  $n = round_nearest($n);
  my ($base,$level) = _n_to_base_and_level($n);
  return $level;
}

#------------------------------------------------------------------------------
1;
__END__

      #                     55--56      10--11                -3
      #                      |   |
      # ...             53--54  57  60--61                    -4
      #                  |       |   |   |
      #                 52--51  58--59  62--63                -5
      #                      |               |
      #             48--49--50      66--65--64                -6
      #              |               |
      #     39--40  47--46          67--68                    -7
      #      |   |       |               |
      # 37--38  41  44--45              69                    -8
      #          |   |                   |
      #         42--43                  70--71                -9
      #                                      |
      #                             74--73--72               -10
      #                              |
      #                             75--76  79--80      ...  -11
      #                                  |   |   |       |
      #                                 77--78  81  84--85   -12
      #                                          |   |
      #                                         82--83       -13
      #
      #                                  ^
      # -8  -7  -6  -5  -4  -3  -2  -1  X=0  1   2   3   4

=for stopwords eg Ryde ie Math-PlanePath quadric onwards

=head1 NAME

Math::PlanePath::QuadricIslands -- quadric curve rings

=head1 SYNOPSIS

 use Math::PlanePath::QuadricIslands;
 my $path = Math::PlanePath::QuadricIslands->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path is concentric islands made from four sides each an eight segment
zig-zag (per the C<QuadicCurve> path).

            27--26                     3
             |   |
        29--28  25  22--21             2
         |       |   |   |
        30--31  24--23  20--19         1
             | 4--3          |
    34--33--32    | 16--17--18     <- Y=0
     |         1--2  |
    35--36   7---8  15--14            -1
             |   |       |
         5---6   9  12--13            -2
                 |   |
                10--11                -3

                 ^
    -3  -2  -1  X=0  1   2   3   4

The initial figure is the square N=1,2,3,4 then for the next level each
straight side expands to 4x longer and a zigzag like N=5 through N=13 and
the further sides to N=36.  The individual sides are levels of the
C<QuadricCurve> path.

                                *---*
                                |   |
      *---*     becomes     *---*   *   *---*
                                    |   |
                                    *---*
         * <------ *
         |         ^
         |         |
         |         |
         v         |
         * ------> *

The name C<QuadricIslands> here is a slight mistake.  Mandelbrot ("Fractal
Geometry of Nature" 1982 page 50) calls any islands initiated from a square
"quadric", not just this eight segment expansion.  This curve also appears
(unnamed) in Mandelbrot's "How Long is the Coast of Britain", 1967.

=head2 Level Ranges

Counting the innermost square as level 0, each ring is

    length = 4 * 8^level     many points
    Nlevel = 1 + length[0] + ... + length[level-1]
           = (4*8^level + 3)/7
    Xstart = - 4^level / 2
    Ystart = - 4^level / 2

=for GP-DEFINE  Nlevel(k) = (4*8^k + 3)/7

=for GP-Test (4*8^2+3)/7 == 37

For example the lower partial ring shown above is level 2 starting
N=(4*8^2+3)/7=37 at X=-(4^2)/2=-8,Y=-8.

The innermost square N=1,2,3,4 is on 0.5 coordinates, for example N=1 at
X=-0.5,Y=-0.5.  This is centred on the origin and consistent with the
(4^level)/2.  Points from N=5 onwards are integer X,Y.

       4-------3    Y=+1/2
       |       |
       |   o   |
               |
       1-------2    Y=-1/2

    X=-1/2   X=+1/2

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::QuadricIslands-E<gt>new ()>

Create and return a new path object.

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return per L</Level Ranges> above,

    ( ( 4 * 8**$level + 3) / 7,
      (32 * 8**$level - 4) / 7 )

=for GP-DEFINE  Nend(k) = (32*8^k - 4)/7

=for GP-Test  Nlevel(0) == 1

=for GP-Test  Nend(0) == 4

=for GP-Test  Nlevel(1) == 5

=for GP-Test  Nend(1) == 36

=for GP-Test  Nlevel(2) == 37

=for GP-Test  vector(20,k, Nlevel(k)) == vector(20,k, Nend(k-1)+1)

=back

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::QuadricCurve>,
L<Math::PlanePath::KochSnowflakes>,
L<Math::PlanePath::GosperIslands>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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
