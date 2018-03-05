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


# math-image --path=DragonRounded --lines --scale=10
# math-image --path=DragonRounded,arms=4 --all --output=numbers_dash --size=132x60
#


package Math::PlanePath::DragonRounded;
use 5.004;
use strict;
#use List::Util 'min','max';
*min = \&Math::PlanePath::_min;
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 126;
use Math::PlanePath;
@ISA = ('Math::PlanePath');
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest',
  'floor';
use Math::PlanePath::Base::Digits
  'round_up_pow';
use Math::PlanePath::DragonMidpoint;

# uncomment this to run the ### lines
#use Smart::Comments;


use constant n_start => 0;
use constant parameter_info_array => [ { name      => 'arms',
                                         share_key => 'arms_4',
                                         display   => 'Arms',
                                         type      => 'integer',
                                         minimum   => 1,
                                         maximum   => 4,
                                         default   => 1,
                                         width     => 1,
                                         description => 'Arms',
                                       } ];

{
  my @x_negative_at_n = (undef, 8,5,2,2);
  sub x_negative_at_n {
    my ($self) = @_;
    return $x_negative_at_n[$self->{'arms'}];
  }
}
{
  my @y_negative_at_n = (undef, 26,17,8,3);
  sub y_negative_at_n {
    my ($self) = @_;
    return $y_negative_at_n[$self->{'arms'}];
  }
}
use constant sumabsxy_minimum  => 1;
use constant absdiffxy_minimum => 1; # X=Y doesn't occur
use constant rsquared_minimum  => 1; # minimum X=1,Y=0

use constant dx_minimum => -1;
use constant dx_maximum => 1;
use constant dy_minimum => -1;
use constant dy_maximum => 1;
*_UNDOCUMENTED__dxdy_list = \&Math::PlanePath::_UNDOCUMENTED__dxdy_list_eight;
use constant dsumxy_minimum => -2; # diagonals
use constant dsumxy_maximum => 2;
use constant ddiffxy_minimum => -2;
use constant ddiffxy_maximum => 2;
use constant dir_maximum_dxdy => (1,-1); # South-East
use constant turn_any_straight => 0; # never straight


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);
  $self->{'arms'} = max(1, min(4, $self->{'arms'} || 1));
  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### DragonRounded n_to_xy(): $n

  if ($n < 0) { return; }
  if (is_infinite($n)) { return ($n, $n); }

  my $frac;
  {
    my $int = int($n);
    $frac = $n - $int;
    $n = $int; # BigFloat int() gives BigInt, use that
  }
  ### $frac

  my $zero = ($n * 0);  # inherit bignum 0

  # arm as initial rotation
  my $rot = _divrem_mutate ($n, $self->{'arms'});

  # two points per edge
  my $x_offset = _divrem_mutate ($n, 2);

  # ENHANCE-ME: sx,sy just from len=3*2**level
  my @digits;
  my @sx;
  my @sy;
  {
    my $sx = $zero + 3;
    my $sy = $zero;
    while ($n) {
      push @digits, ($n % 2);
      push @sx, $sx;
      push @sy, $sy;
      $n = int($n/2);

      # (sx,sy) + rot+90(sx,sy)
      ($sx,$sy) = ($sx - $sy,
                   $sy + $sx);
    }
  }

  ### @digits
  my $rev = 0;
  my $x = $zero;
  my $y = $zero;
  my $above_low_zero = 0;

  for (my $i = $#digits; $i >= 0; $i--) {     # high to low
    my $digit = $digits[$i];
    my $sx = $sx[$i];
    my $sy = $sy[$i];
    ### at: "$x,$y  $digit   side $sx,$sy"
    ### $rot

    if ($rot & 2) {
      ($sx,$sy) = (-$sx,-$sy);
    }
    if ($rot & 1) {
      ($sx,$sy) = (-$sy,$sx);
    }
    ### rotated side: "$sx,$sy"

    if ($rev) {
      if ($digit) {
        $x += -$sy;
        $y += $sx;
        ### rev add to: "$x,$y next is still rev"
      } else {
        $above_low_zero = $digits[$i+1];
        $rot ++;
        $rev = 0;
        ### rev rot, next is no rev ...
      }
    } else {
      if ($digit) {
        $rot ++;
        $x += $sx;
        $y += $sy;
        $rev = 1;
        ### plain add to: "$x,$y next is rev"
      } else {
        $above_low_zero = $digits[$i+1];
      }
    }
  }

  # Digit above the low zero is the direction of the next turn, 0 for left,
  # 1 for right, and that determines the y_offset to apply to go across
  # towards the next edge.  When original input $n is odd, which means
  # $x_offset 0 at this point, there's no y_offset as going along the edge
  # not across the vertex.
  #
  my $y_offset = ($x_offset ? ($above_low_zero ? -$frac : $frac)
                  : 0);
  $x_offset = $frac + 1 + $x_offset;

  ### final: "$x,$y  rot=$rot  above_low_zero=$above_low_zero   offset=$x_offset,$y_offset"
  if ($rot & 2) {
    ($x_offset,$y_offset) = (-$x_offset,-$y_offset);  # rotate 180
  }
  if ($rot & 1) {
    ($x_offset,$y_offset) = (-$y_offset,$x_offset);  # rotate +90
  }
  $x = $x_offset + $x;
  $y = $y_offset + $y;
  ### rotated offset: "$x_offset,$y_offset   return $x,$y"
  return ($x,$y);
}

my @yx_rtom_dx = ([undef,     1,     1, undef,     1,     1],
                  [    0, undef, undef,     1, undef, undef],
                  [    0, undef, undef,     1, undef, undef],
                  [undef,     1,     1, undef,     1,     1],
                  [    1, undef, undef,     0, undef, undef],
                  [    1, undef, undef,     0, undef, undef]);

my @yx_rtom_dy = ([undef,     0,     0, undef,    -1,    -1],
                  [    0, undef, undef,     0, undef, undef],
                  [    0, undef, undef,     0, undef, undef],
                  [undef,    -1,    -1, undef,     0,     0],
                  [    0, undef, undef,     0, undef, undef],
                  [    0, undef, undef,     0, undef, undef]);

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### DragonRounded xy_to_n(): "$x, $y"

  $x = round_nearest($x);
  $y = round_nearest($y);

  my $x6 = $x % 6;
  my $y6 = $y % 6;
  my $dx = $yx_rtom_dx[$y6][$x6];  defined $dx or return undef;
  my $dy = $yx_rtom_dy[$y6][$x6];  defined $dy or return undef;

  # my $n = $self->Math::PlanePath::DragonMidpoint::xy_to_n
  #   ($x - floor($x/3) - $dx,
  #    $y - floor($y/3) - $dy);
  # ### dxy: "$dx, $dy"
  # ### to: ($x - floor($x/3) - $dx).", ".($y - floor($y/3) - $dy)
  # ### $n

  return $self->Math::PlanePath::DragonMidpoint::xy_to_n
    ($x - floor($x/3) - $dx,
     $y - floor($y/3) - $dy);
}

# level 21  n=1048576 .. 2097152
#   min 1052677 0b100000001000000000101   at -1026,1  factor 1.99610706057474
#   n=2^20 min r^2=2^20 plus a bit
#   maybe ...
#
# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### DragonRounded rect_to_n_range(): "$x1,$y1  $x2,$y2  arms=$self->{'arms'}"

  $x1 = abs($x1);
  $x2 = abs($x2);
  $y1 = abs($y1);
  $y2 = abs($y2);
  my $xmax = int(max($x1,$x2) / 3);
  my $ymax = int(max($y1,$y2) / 3);
  return (0,
          ($xmax*$xmax + $ymax*$ymax + 1) * $self->{'arms'} * 16);
}

#------------------------------------------------------------------------------

# each 2 points is a line segment, so 2*DragonMidpoint
# level 0  0--1
# level 1  0--1 2--3
# level 2  0--1 2--3 4--5 6--7
#
# arms=4
# level 0  0--3  /  1--4  /  2--5  /  3--7
# level 1  
#
# 2^level segments
# 2*2^level rounded points
# arms*2^level when multi-arm
# numbered starting 0
#
sub level_to_n_range {
  my ($self, $level) = @_;
  return (0, 2**($level+1) * $self->{'arms'} - 1);
}

sub n_to_level {
  my ($self, $n) = @_;
  if ($n < 0) { return undef; }
  if (is_infinite($n)) { return $n; }
  $n = round_nearest($n);
  _divrem_mutate ($n, 2*$self->{'arms'});
  my ($pow, $exp) = round_up_pow ($n+1, 2);
  return $exp;
}

#------------------------------------------------------------------------------
1;
__END__

=for stopwords eg Ryde Dragon Math-PlanePath Nlevel Heighway Harter et al vertices multi-arm Xadj,Yadj OEIS Xadj

=head1 NAME

Math::PlanePath::DragonRounded -- dragon curve, with rounded corners

=head1 SYNOPSIS

 use Math::PlanePath::DragonRounded;
 my $path = Math::PlanePath::DragonRounded->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This is a version of the dragon curve by Harter, Heighway, et al, done with
two points per edge and skipping vertices so as to make rounded-off corners,

                          17-16              9--8                 6
                         /     \           /     \
                       18       15       10        7              5
                        |        |        |        |
                       19       14       11        6              4
                         \        \     /           \
                          20-21    13-12              5--4        3
                               \                          \
                                22                          3     2
                                 |                          |
                                23                          2     1
                               /                          /
        33-32             25-24                    .  0--1       Y=0
       /     \           /
     34       31       26                                        -1
      |        |        |
     35       30       27                                        -2
       \        \     /
        36-37    29-28    44-45                                  -3
             \           /     \
              38       43       46                               -4
               |        |        |
              39       42       47                               -5
                \     /        /
                 40-41    49-48                                  -6
                         /
                       50                                        -7
                        |
                       ...


      ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^
    -15-14-13-12-11-10 -9 -8 -7 -6 -5 -4 -3 -2 -1 X=0 1  2  3 ...

The two points on an edge have one of X or Y a multiple of 3 and the other Y
or X at 1 mod 3 or 2 mod 3.  For example N=19 and N=20 are on the X=-9 edge
(a multiple of 3), and at Y=4 and Y=5 (1 and 2 mod 3).

The "rounding" of the corners ensures that for example N=13 and N=21 don't
touch as they approach X=-6,Y=3.  The curve always approaches vertices like
this and never crosses itself.

=head2 Arms

The dragon curve fills a quarter of the plane and four copies mesh together
rotated by 90, 180 and 270 degrees.  The C<arms> parameter can choose 1 to 4
curve arms, successively advancing.  For example C<arms =E<gt> 4> gives


                36-32             59-...          6
               /     \           /
    ...      40       28       55                 5
     |        |        |        |
    56       44       24       51                 4
      \     /           \        \
       52-48    13--9    20-16    47-43           3
               /     \        \        \
             17        5       12       39        2
              |        |        |        |
             21        1        8       35        1
            /                 /        /
       29-25     6--2     0--4    27-31       <- Y=0
      /        /                 /
    33       10        3       23                -1
     |        |        |        |
    37       14        7       19                -2
      \        \        \     /
       41-45    18-22    11-15    50-54          -3
            \        \           /     \
             49       26       46       58       -4
              |        |        |        |
             53       30       42       ...      -5
            /           \     /
      ...-57             34-38                   -6



     ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^
    -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6

With 4 arms like this all 3x3 blocks are visited, using 4 out of 9 points in
each.

=head2 Midpoint

The points of this rounded curve correspond to the C<DragonMidpoint> with a
little squish to turn each 6x6 block into a 4x4 block.  For instance in the
following N=2,3 are pushed to the left, and N=6 through N=11 shift down and
squashes up horizontally.

     DragonRounded               DragonMidpoint

        9--8                     
       /    \
     10      7                     9---8         
      |      |                     |   |         
     11      6                    10   7         
    /         \                    |   |         
               5--4      <=>     -11   6---5---4 
                   \                           | 
                    3                          3 
                    |                          | 
                    2                          2 
                   /                           | 
             . 0--1                        0---1 
                            

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::DragonRounded-E<gt>new ()>

=item C<$path = Math::PlanePath::DragonRounded-E<gt>new (arms =E<gt> $aa)>

Create and return a new path object.

The optional C<arms> parameter makes a multi-arm curve.  The default is 1
for just one arm.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

=item C<$n = $path-E<gt>n_start()>

Return 0, the first N in the path.

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<(0, 2 * 2**$level - 1)>, or for multiple arms return C<(0, $arms *
2 * 2**$level - 1)>.

There are 2^level segments comprising the dragon, or arms*2^level when
multiple arms.  Each has 2 points in this rounded curve, numbered starting
from 0.

=back

=head1 FORMULAS

=head2 X,Y to N

The correspondence with the C<DragonMidpoint> noted above allows the method
from that module to be used for the rounded C<xy_to_n()>.

The correspondence essentially reckons each point on the rounded curve as
the midpoint of a dragon curve of one greater level of detail, and segments
on 45-degree angles.

The coordinate conversion turns each 6x6 block of C<DragonRounded> to a 4x4
block of C<DragonMidpoint>.  There's no rotations or anything.

    Xmid = X - floor(X/3) - Xadj[X%6][Y%6]
    Ymid = Y - floor(Y/3) - Yadj[X%6][Y%6]

    N = DragonMidpoint n_to_xy of Xmid,Ymid

    Xadj[][] is a 6x6 table of 0 or 1 or undef
    Yadj[][] is a 6x6 table of -1 or 0 or undef

The Xadj,Yadj tables are a handy place to notice X,Y points not on the
C<DragonRounded> style 4 of 9 points.  Or 16 of 36 points since the tables
are 6x6.

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to this
path include the various C<DragonCurve> sequences at even N, and in addition

=over

L<http://oeis.org/A152822> (etc)

=back

    A152822   abs(dX), so 0=vertical,1=not, being 1,1,0,1 repeating
    A166486   abs(dY), so 0=horizontal,1=not, being 0,1,1,1 repeating

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::DragonCurve>,
L<Math::PlanePath::DragonMidpoint>,
L<Math::PlanePath::TerdragonRounded>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
