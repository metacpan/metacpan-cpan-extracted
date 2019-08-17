# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019 Kevin Ryde

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


# math-image --path=DragonMidpoint --lines --scale=20
# math-image --path=DragonMidpoint --all --output=numbers_dash

# A006466 contfrac 2*sum( 1/2^(2^n)), 1 and 2 only
#    a(5n) recurrence ...
#    1,1,1,1, 2,
#    1,1,1,1,1,1,1, 2,
#    1,1,1,1, 2,
#    1,1,1,1, 2,
#    1, 2,
#    1,1,1,1, 2,
#    1,1,1,1,1,1,1, 2,
#    1,1,1,1, 2,
#    1, 2,
#    1,1,1,1,1,1,1, 2,
#    1,1,1,1, 2,
#    1, 2,
#    1,1,1,1, 2,
#    1,1,1,1, 2,
#    1,1,1,1,1,1,1, 2,
#    1,1,1,1, 2,
#    1, 2,
#    1,1,1,1,1,1,1, 2,
#    1,1,1,1, 2,
#    1,1,1,1, 2,
#    1, 2
# A076214   in decimal
#
# A073097 number of 4s - 6s - 2s - 1 is -1,0,1
# A081769 positions of 2s
# A073088 cumulative total multiples of 4 roughly, hence (4n-3-cum)/2
#
# A088435 (contfrac+1)/2 of sum(k>=1,1/3^(2^k)).
# A007404   in decimal
#


package Math::PlanePath::DragonMidpoint;
use 5.004;
use strict;
use List::Util 'min'; # 'max'
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 127;
use Math::PlanePath;
use Math::PlanePath::Base::NSEW;
@ISA = ('Math::PlanePath::Base::NSEW',
        'Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'bit_split_lowtohigh',
  'digit_join_lowtohigh',
  'round_up_pow';
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

# uncomment this to run the ### lines
# use Smart::Comments;


# whole plane when arms==4
use Math::PlanePath::DragonCurve;


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
  my @x_negative_at_n = (undef, 6,5,2,2);
  sub x_negative_at_n {
    my ($self) = @_;
    return $x_negative_at_n[$self->{'arms'}];
  }
}
{
  my @y_negative_at_n = (undef, 27,19,11,7);
  sub y_negative_at_n {
    my ($self) = @_;
    return $y_negative_at_n[$self->{'arms'}];
  }
}
{
  my @_UNDOCUMENTED__dxdy_list_at_n = (undef, 9, 9, 5, 3);
  sub _UNDOCUMENTED__dxdy_list_at_n {
    my ($self) = @_;
    return $_UNDOCUMENTED__dxdy_list_at_n[$self->{'arms'}];
  }
}


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);
  $self->{'arms'} = max(1, min(4, $self->{'arms'} || 1));
  return $self;
}

# sub n_to_xy {
#   my ($self, $n) = @_;
#   ### DragonMidpoint n_to_xy(): $n
#
#   if ($n < 0) { return; }
#   if (is_infinite($n)) { return ($n, $n); }
#
#   {
#     my $int = int($n);
#     if ($n != $int) {
#       my ($x1,$y1) = $self->n_to_xy($int);
#       my ($x2,$y2) = $self->n_to_xy($int+$self->{'arms'});
#       my $frac = $n - $int;  # inherit possible BigFloat
#       my $dx = $x2-$x1;
#       my $dy = $y2-$y1;
#       return ($frac*$dx + $x1, $frac*$dy + $y1);
#     }
#     $n = $int; # BigFloat int() gives BigInt, use that
#   }
#
#   my ($x1,$y1) = Math::PlanePath::DragonCurve->n_to_xy($n);
#   my ($x2,$y2) = Math::PlanePath::DragonCurve->n_to_xy($n+1);
#
#   my $dx = $x2-$x1;
#   my $dy = $y2-$y1;
#   return ($x1+$y1 + ($dx+$dy-1)/2,
#           $y1-$x1 + ($dy-$dx+1)/2);
# }

sub n_to_xy {
  my ($self, $n) = @_;
  ### DragonMidpoint n_to_xy(): $n

  if ($n < 0) { return; }
  if (is_infinite($n)) { return ($n, $n); }

  my $frac;
  {
    my $int = int($n);
    $frac = $n - $int;  # inherit possible BigFloat
    $n = $int;          # BigFloat int() gives BigInt, use that
  }
  my $zero = ($n * 0);  # inherit bignum 0

  # arm as initial rotation
  my $rot = _divrem_mutate ($n, $self->{'arms'});

  ### $arms
  ### rot from arm: $rot
  ### $n

  # ENHANCE-ME: sx,sy just from len,len
  my @digits = bit_split_lowtohigh($n);
  my @sx;
  my @sy;

  {
    my $sx = $zero + 1;
    my $sy = -$sx;
    foreach (@digits) {
      push @sx, $sx;
      push @sy, $sy;

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
      $sx = -$sx;
      $sy = -$sy;
    }
    if ($rot & 1) {
      ($sx,$sy) = (-$sy,$sx);
    }
    ### rotated side: "$sx,$sy"

    if ($rev) {
      if ($digit) {
        $x -= $sy;
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
  # 1 for right.
  #
  ### final: "$x,$y  rot=$rot  above_low_zero=".($above_low_zero||0)

  if ($rot & 2) {
    $frac = -$frac;  # rotate 180
    $x -= 1;
  }
  if (($rot+1) & 2) {
    # rot 1 or 2
    $y += 1;
  }
  if (!($rot & 1) && $above_low_zero) {
    $frac = -$frac;
  }
  $above_low_zero ^= ($rot & 1);
  if ($above_low_zero) {
    $y = $frac + $y;
  } else {
    $x = $frac + $x;
  }

  ### rotated return: "$x,$y"
  return ($x,$y);
}

# or tables arithmetically,
#
#   my $ax = ((($x+1) ^ ($y+1)) >> 1) & 1;
#   my $ay = (($x^$y) >> 1) & 1;
#   ### assert: $ax == - $yx_adj_x[$y%4]->[$x%4]
#   ### assert: $ay == - $yx_adj_y[$y%4]->[$x%4]
#
my @yx_adj_x = ([0,1,1,0],
                [1,0,0,1],
                [1,0,0,1],
                [0,1,1,0]);

my @yx_adj_y = ([0,0,1,1],
                [0,0,1,1],
                [1,1,0,0],
                [1,1,0,0]);

# arm $x $y         2 | 1     Y=1
#  0   0  0         3 | 0     Y=0
#  1   0  1       ----+----
#  2  -1  1       X=-1  X=0
#  3  -1  0
my @xy_to_arm = ([0,   # x=0,y=0
                  1],  # x=0,y=1
                 [3,   # x=-1,y=0
                  2]); # x=-1,y=1

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### DragonMidpoint xy_to_n(): "$x, $y"

  $x = round_nearest($x);
  $y = round_nearest($y);

  { my $overflow = abs($x)+abs($y)+2;
    if (is_infinite($overflow)) { return $overflow; }
  }
  my $zero = ($x * 0 * $y);
  my @nbits;  # low to high

  while ($x < -1 || $x > 0 || $y < 0 || $y > 1) {
    my $y4 = $y % 4;
    my $x4 = $x % 4;
    my $ax = $yx_adj_x[$y4]->[$x4];
    my $ay = $yx_adj_y[$y4]->[$x4];

    ### at: "$x,$y  n=$n  axy=$ax,$ay  bit=".($ax^$ay)

    push @nbits, $ax^$ay;

    $x -= $ax;
    $y -= $ay;
    ### assert: ($x+$y)%2 == 0
    ($x,$y) = (($x+$y)/2,   # rotate -45 and divide sqrt(2)
               ($y-$x)/2);
  }

  ### final: "xy=$x,$y"

  my $arm = $xy_to_arm[$x]->[$y];
  ### $arm
  my $arms_count = $self->arms_count;
  if ($arm >= $arms_count) {
    return undef;
  }

  if ($arm & 1) {
    ### flip ...
    @nbits = map {$_^1} @nbits;
  }

  return digit_join_lowtohigh(\@nbits, 2, $zero) * $arms_count + $arm;
}

#------------------------------------------------------------------------------
# xy_is_visited()

sub xy_is_visited {
  my ($self, $x, $y) = @_;
  return ($self->{'arms'} >= 4
          || _xy_to_arm($x,$y) < $self->{'arms'});
}

# return arm number 0,1,2,3
sub _xy_to_arm {
  my ($x, $y) = @_;
  ### DragonMidpoint _xy_to_arm(): "$x, $y"

  $x = round_nearest($x);
  $y = round_nearest($y);

  { my $overflow = abs($x)+abs($y)+2;
    if (is_infinite($overflow)) { return $overflow; }
  }

  while ($x < -1 || $x > 0 || $y < 0 || $y > 1) {
    my $y4 = $y % 4;
    my $x4 = $x % 4;
    $x -= $yx_adj_x[$y4]->[$x4];
    $y -= $yx_adj_y[$y4]->[$x4];

    ### assert: ($x+$y)%2 == 0
    ($x,$y) = (($x+$y)/2,   # rotate -45 and divide sqrt(2)
               ($y-$x)/2);
  }
  return $xy_to_arm[$x]->[$y];
}

#------------------------------------------------------------------------------

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### DragonMidpoint rect_to_n_range(): "$x1,$y1  $x2,$y2  arms=$self->{'arms'}"
  $x1 = abs($x1);
  $x2 = abs($x2);
  $y1 = abs($y1);
  $y2 = abs($y2);
  my $xmax = int(max($x1,$x2));
  my $ymax = int(max($y1,$y2));
  return (0,
          ($xmax*$xmax + $ymax*$ymax + 1) * $self->{'arms'} * 5);
}

# sub rect_to_n_range {
#   my ($self, $x1,$y1, $x2,$y2) = @_;
#   ### DragonMidpoint rect_to_n_range(): "$x1,$y1  $x2,$y2"
#
#   return Math::PlanePath::DragonCurve->rect_to_n_range
#     (sqrt(2)*$x1, sqrt(2)*$y1, sqrt(2)*$x2, sqrt(2)*$y2);
# }

#------------------------------------------------------------------------------

sub level_to_n_range {
  my ($self, $level) = @_;
  return (0, 2**$level * $self->{'arms'} - 1);
}
sub n_to_level {
  my ($self, $n) = @_;
  if ($n < 0) { return undef; }
  if (is_infinite($n)) { return $n; }
  $n = round_nearest($n);
  _divrem_mutate ($n, $self->{'arms'});
  my ($pow, $exp) = round_up_pow ($n+1, 2);
  return $exp;
}

#------------------------------------------------------------------------------
1;
__END__


# wider drawn arms ...
#
#
# ...            36---32             59---63-...        5
#  |              |    |              |
# 60             40   28             55                 4
#  |              |    |              |
# 56---52---48---44   24---20---16   51                 3
#                                |    |
#           17---13----9----5   12   47---43---39       2
#            |              |    |              |
#           21    6--- 2    1    8   27---31---35       1
#            |    |              |    |
# 33---29---25   10    3    0--- 4   23             <- Y=0
#  |              |    |              |
# 37---41---45   14    7---11---15---19                -1
#            |    |
#           49   18---22---26   46---50---54---58      -2
#            |              |    |              |
#           53             30   42             62      -3
#            |              |    |              |
# ...--61---57             34---38             ...     -4
#
#
#
#  ^    ^    ^    ^    ^    ^    ^    ^    ^    ^
# -5   -4   -3   -2   -1   X=0   1    2    3    4



# DragonMidpoint abs(dY) is A073089, but that seq has an extra leading 0
#
#   --*--+   dy=+/-1  vert and left
#        |            horiz and right
#        *
#        |
#   |
#   *
#   |
#   +--*--   dy=+/-1
#
#   +--*--   dx=+/-1  vert and right
#   |                 horiz and left
#   *
#   |
#        |   dx=+/-1
#        *
#        |
#   --*--+
#
# left turn  ...01000
# right turn ...11000
# vert           ...1
# horiz          ...0

# Offset=1  0,0,1,1,1,0,0,1,1,0,1,1,0,0,0,1,1,0,1,1,1,0,0,1,0,0,1,1,0,0,0,1,1,0,1,1,1,0,0,1,1,0,1,1,0,0,0,1,

# mod16
# 0     1
# 1        8n+1=4n+1
# 2  0
# 3      1
# 4     1
# 5       1
# 6  0
# 7   0
# 8     1
# 9       8n+1=4n+1
# 10 0
# 11     1
# 12    1
# 13   0
# 14 0
# 15  0
#
# a(1) = a(4n+2) = a(8n+7) = a(16n+13) = 0,
# a(4n) = a(8n+3) = a(16n+5) = 1
# a(8n+1) = a(4n+1)

# N=0   0,1,1,1,0,0,1,1,0,1,1,0,0,0,1,1,0,1,1,1,0,0,1,0,0,1,1,0,0,0,1,1,0,1,1,1,0,0,1,1,0,1,1,0,0,0,1,0,0,1,1,





=for stopwords eg Ryde Dragon Math-PlanePath Nlevel Heighway Harter et al bignum Xadj,Yadj lookup OEIS 0b.zz111 0b..zz11 ie tilingsearch Xadj

=head1 NAME

Math::PlanePath::DragonMidpoint -- dragon curve midpoints

=head1 SYNOPSIS

 use Math::PlanePath::DragonMidpoint;
 my $path = Math::PlanePath::DragonMidpoint->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This is the midpoint of each segment of the dragon curve of Heighway,
Harter, et al, per L<Math::PlanePath::DragonCurve>.


                    17--16           9---8                5
                     |   |           |   |
                    18  15          10   7                4
                     |   |           |   |
                    19  14--13--12--11   6---5---4        3
                     |                           |
                    20--21--22                   3        2
                             |                   |
    33--32          25--24--23                   2        1
     |   |           |                           |
    34  31          26                       0---1    <- Y=0
     |   |           |
    35  30--29--28--27                                   -1
     |
    36--37--38  43--44--45--46                           -2
             |   |           |
            39  42  49--48--47                           -3
             |   |   |
            40--41  50                                   -4
                     |
                    51                                   -5
                     |
                    52--53--54                           -6
                             |
    ..--64          57--56--55                           -7
         |           |
        63          58                                   -8
         |           |
        62--61--60--59                                   -9


     ^   ^   ^   ^   ^   ^   ^   ^   ^   ^   ^   ^
    -10 -9  -8  -7  -6  -5  -4  -3  -2  -1  X=0  1

The dragon curve begins as follows.  The midpoints of each segment are
numbered starting from 0,

     +--8--+     +--4--+
     |     |     |     |
     9     7     5     3
     |     |     |     |                               |
     +-10--+--6--+     +--2--+       rotate 45 degrees |
           |                 |                         v
          11                 1
           |                 |
     +-12--+           *--0--+       * = Origin
     |
    ...

These midpoints are on fractions X=0.5,Y=0, X=1,Y=0.5, etc.  For this
C<DragonMidpoint> path they're turned clockwise 45 degrees and shrunk by
sqrt(2) to be integer X,Y values a unit apart and initial direction to the
right.

The midpoints are distinct X,Y positions because the dragon curve traverses
each edge only once.

The dragon curve is self-similar in 2^level sections due to its unfolding.
This can be seen in the midpoints too as for example above N=0 to N=16 is
the same shape as N=16 to N=32, with the latter rotated 90 degrees and in
reverse.

For reference, Knuth in "Diamonds and Dragons" has a different numbering for
segment midpoints where the dragon orientation is unchanged and instead
multiply by 2 to have midpoints as integers.  For example the first dragon
midpoint at X=1/2,Y=0 is doubled out to X=1,Y=0.  That can be obtained from
the path here by

    KnuthX = X - Y + 1
    KnuthY = X + Y

=for GP-Test  0-0 + 1 == 1    /* N=1 */

=for GP-Test  0+0     == 0

=for GP-Test  1-0 + 1 == 2    /* N=1 */

=for GP-Test  1+0     == 1

=for GP-Test  1-1 + 1 == 1    /* N=2 */

=for GP-Test  1+1     == 2

=for GP-Test  1-2 + 1 == 0    /* N=3 */

=for GP-Test  1+2     == 3

=head2 Arms

Like the C<DragonCurve> the midpoints fill a quarter of the plane and four
copies mesh together perfectly when rotated by 90, 180 and 270 degrees.  The
C<arms> parameter can choose 1 to 4 curve arms, successively advancing.

For example C<arms =E<gt> 4> begins as follows, with N=0,4,8,12,etc being
the first arm (the same as the plain curve above), N=1,5,9,13 the second,
N=2,6,10,14 the third and N=3,7,11,15 the fourth.

    arms => 4

                    ...-107-103  83--79--75--71             6
                              |   |           |
     68--64          36--32  99  87  59--63--67             5
      |   |           |   |   |   |   |
     72  60          40  28  95--91  55                     4
      |   |           |   |           |
     76  56--52--48--44  24--20--16  51                     3
      |                           |   |
     80--84--88  17--13---9---5  12  47--43--39 ...         2
              |   |           |   |           |  |
    100--96--92  21   6---2   1   8  27--31--35 106         1
      |           |   |           |   |          |
    104  33--29--25  10   3   0---4  23  94--98-102    <- Y=0
      |   |           |   |           |   |
    ...  37--41--45  14   7--11--15--19  90--86--82        -1
                  |   |                           |
                 49  18--22--26  46--50--54--58  78        -2
                  |           |   |           |   |
                 53  89--93  30  42          62  74        -3
                  |   |   |   |   |           |   |
         65--61--57  85  97  34--38          66--70        -4
          |           |   |
         69--73--77--81 101-105-...                        -5

                              ^
     -6  -5  -4  -3  -2  -1  X=0  1   2   3   4   5

With four arms like this every X,Y point is visited exactly once, because
four arms of the C<DragonCurve> traverse every edge exactly once.

=head2 Tiling

Taking pairs of adjacent points N=2k and N=2k+1 gives little rectangles with
the following tiling of the plane repeating in 4x4 blocks.

         +---+---+---+-+-+---+-+-+---+
         |   | | |   | | |   | | |   |
         +---+ | +---+ | +---+ | +---+
         |   | | |9 8| | |   | | |   |
         +-+-+---+-+-+-+-+-+-+-+-+-+-+
         | | |   | |7|   | | |   | | |
         | | +---+ | +---+ | +---+ | |
         | | |   | |6|5 4| | |   | | |
         +---+-+-+-+-+-+-+-+-+-+-+-+-+
         |   | | |   | |3|   | | |   |
         +---+ | +---+ | +---+ | +---+
         |   | | |   | |2|   | | |   |
         +-+-+-+-+-+-+-+-+-+-+-+-+-+-+
         | | |   | | |0 1| | |   | | |   <- Y=0
         | | +---+ | +---+ | +---+ | |
         | | |   | | |   | | |   | | |
         +-+-+-+-+-+-+-+-+-+-+-+-+-+-+
         |   | | |   | | |   | | |   |
         +---+ | +---+ | +---+ | +---+
         |   | | |   | | |   | | |   |
         +---+-+-+---+-+-+---+-+-+---+
                      ^
                     X=0

The pairs follow this pattern both for the main curve N=0 etc shown, and
also for the rotated copies per L</Arms> above.  This tiling is in the
tilingsearch database as

=over

L<http://tilingsearch.org/HTML/data24/K02A.html>

=back

Taking pairs N=2k+1 and N=2k+2, being each odd N and its successor, gives a
regular pattern too, but this time repeating in blocks of 16x16.

    |||--||||||--||--||--||||||--||||||--||||||--||||||--||||||--|||
    |||--||||||--||--||--||||||--||||||--||||||--||||||--||||||--|||
    -||------||------||------||------||------||------||------||-----
    -||------||------||------||------||------||------||------||-----
    |||--||||||||||||||--||||||||||||||--||||||||||||||--|||||||||||
    |||--||||||||||||||--||||||||||||||--||||||||||||||--|||||||||||
    -----||------||------||------||------||------||------||------||-
    -----||------||------||------||------||------||------||------||-
    -||--||--||--||--||--||||||--||--||--||--||--||--||--||||||--||-
    -||--||--||--||--||--||||||--||--||--||--||--||--||--||||||--||-
    -||------||------||------||------||------||------||------||-----
    -||------||------||------||------||------||------||------||-----
    |||||||||||--||||||||||||||--||||||||||||||--||||||||||||||--|||
    |||||||||||--||||||||||||||--||||||||||||||--||||||||||||||--|||
    -----||------||------||------||------||------||------||------||-
    -----||------||------||------||------||------||------||------||-
    |||--||||||--||--||--||||||--||  ||--||||||--||--||--||||||--|||
    |||--||||||--||--||--||||||--||  ||--||||||--||--||--||||||--|||
    -||------||------||------||------||------||------||------||-----
    -||------||------||------||------||------||------||------||-----
    |||--||||||||||||||--||||||||||||||--||||||||||||||--|||||||||||
    |||--||||||||||||||--||||||||||||||--||||||||||||||--|||||||||||
    -----||------||------||------||------||------||------||------||-
    -----||------||------||------||------||------||------||------||-
    -||--||||||--||--||--||--||--||--||--||||||--||--||--||--||--||-
    -||--||||||--||--||--||--||--||--||--||||||--||--||--||--||--||-
    -||------||------||------||------||------||------||------||-----
    -||------||------||------||------||------||------||------||-----
    |||||||||||--||||||||||||||--||||||||||||||--||||||||||||||--|||
    |||||||||||--||||||||||||||--||||||||||||||--||||||||||||||--|||
    -----||------||------||------||------||------||------||------||-
    -----||------||------||------||------||------||------||------||-

=head2 Curve from Midpoints

Since the dragon curve always turns left or right, never straight ahead or
reverse, its segments are alternately horizontal and vertical.  Rotated -45
degrees for the midpoints here this means alternately "opposite diagonal"
and "leading diagonal".  They fall on X,Y alternately even or odd.  So the
original dragon curve can be recovered from the midpoints by choosing
leading diagonal or opposite diagonal segment according to X,Y even or odd,
which is the same as N even or odd.

    DragonMidpoint                  dragon segment
    --------------                 -----------------
    "even" N==0 mod 2              opposite diagonal
      which is X+Y==0 mod 2 too

    "odd"  N==1 mod 2              leading diagonal
      which is X+Y==1 mod 2 too

               /
              3         0 at X=0,Y=0 "even", opposite diagonal
             /          1 at X=1,Y=0 "odd", leading diagonal
             \          etc
              2
               \
         \     /
          0   1
           \ /

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::DragonMidpoint-E<gt>new ()>

Create and return a new path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

Fractional positions give an X,Y position along a straight line between the
integer positions.

=item C<$n = $path-E<gt>n_start()>

Return 0, the first N in the path.

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<(0, 2**$level - 1)>, or for multiple arms return C<(0, $arms *
2**$level - 1)>.

There are 2^level segments comprising the dragon, or arms*2^level when
multiple arms, numbered starting from 0.

=back

=head1 FORMULAS

=head2 X,Y to N

An X,Y point is turned into N by dividing out digits of a complex base i+1.
This base is per the doubling of the C<DragonCurve> at each level.  In
midpoint coordinates an adjustment subtracting 0 or 1 must be applied to
move an X,Y which is either N=2k or N=2k+1 to the position where dividing
out i+1 gives the N=k X,Y.

The adjustment is in a repeating pattern of 4x4 blocks.  Points N=2k and
N=2k+1 both move to the same place corresponding to N=k multiplied by i+1.
The adjustment pattern is a little like the pair tiling shown above, but for
some pairs both the N=2k and N=2k+1 positions must move, it's not enough
just to shift the N=2k+1 to the N=2k.

            Xadj               Yadj
    Ymod4              Ymod4
      3 | 0 1 1 0        3 | 1 1 0 0
      2 | 1 0 0 1        2 | 1 1 0 0
      1 | 1 0 0 1        1 | 0 0 1 1
      0 | 0 1 1 0        0 | 0 0 1 1
        +--------          +--------
          0 1 2 3            0 1 2 3
           Xmod4              Xmod4

The same tables work for both the main curve and for the rotated copies per
L</Arms> above.

    until -1<=X<=0 and 0<=Y<=1

      Xm = X - Xadj(X mod 4, Y mod 4)
      Ym = Y - Yadj(X mod 4, Y mod 4)

      new X,Y = (Xm+i*Ym) / (i+1)
              = (Xm+i*Ym) * (1-i)/2
              = (Xm+Ym)/2, (Ym-Xm)/2     # Xm+Ym and Ym-Xm are both even

      Nbit = Xadj xor Yadj               # bits of N low to high

The X,Y reduction stops at one of the start points for the four arms

    X,Y endpoint   Arm        +---+---+
    ------------   ---        | 2 | 1 |  Y=1
        0, 0        0         +---+---+
        0, 1        1         | 3 | 0 |  Y=0
       -1, 1        2         +---+---+
       -1, 0        3         X=-1 X=0

For arms 1 and 3 the N bits must be flipped 0E<lt>-E<gt>1.  The arm number
and hence whether this flip is needed is not known until reaching the
endpoint.

For bignum calculations there's no need to apply the "/2" shift in
newX=(Xm+Ym)/2 and newY=(Ym-Xm)/2.  Instead keep a bit position which is the
logical low end and pick out two bits from there for the Xadj,Yadj lookup.
A whole word can be dropped when the bit position becomes a multiple of 32
or 64 or whatever.

=head2 Boundary

Taking unit squares at each point, the boundary MB[k] of the resulting shape
from 0 to N=2^k-1 inclusive can be had from the boundary B[k] of the plain
dragon curve.  Taking points N=0 to N=2^k-1 inclusive is the midpoints of
the dragon curve line segments N=0 to N=2^k inclusive.


    MB[k] = B[k] + 2
          = 4, 6, 10, 18, 30, 50, 86, 146, 246, 418, 710, 1202, ...

                             2 + x + 2*x^2
    generating function  2 * -------------
                             1 - x - 2*x^3

=for GP-DEFINE gB(x)=(2 + 2*x^2) / ((1 - x - 2*x^3) * (1-x))

=for GP-DEFINE gMB(x) = (4 + 2*x + 4*x^2) / (1 - x - 2*x^3)

=for GP-Test gMB(x) == 2*(2 + x + 2*x^2)/(1-x-2*x^3)

=for GP-DEFINE gOnes(x)=1/(1-x) /* 1,1,1,1,1,1,etc */

=for GP-Test gMB(x) == gB(x) + 2*gOnes(x)

=for GP-Test Vec(gMB(x) - O(x^12)) == [4, 6, 10, 18, 30, 50, 86, 146, 246, 418, 710, 1202]

A unit square at the midpoint is a diamond on a dragon line segment

      / \
     /   \         midpoint m
    *--m--*        diamond on dragon curve line segment
     \   /
      \ /

A boundary segment of the dragon curve has two sides of the diamond which
are boundary.  But when the boundary makes a right hand turn two such sides
touch and are therefore not midpoint boundary.

     /^\
    / | \        right turn
    \ | //\      two diamond sides touch
     \|//  \
      *<----*
       \   /
        \ /

The dragon curve at N=0 points East and the last segment N=2^k-1 to N=2^k is
North.  Since the curve never overlaps itself this means that when going
around the right side of the curve there is 1 more left turn than right
turn,

    lefts - rights = 1

The total line segments on the right is the dragon curve R[k] and there are
R[k]-1 turns, so the total turns lefts+rights is

    lefts + rights + 1 = R[k]

So the lefts and rights are obtained separately

    2*lefts            = R[k]       adding the two equations
    2*rights           = R[k] - 2   subtracting the two equations

The result is then

    MR[k] = 2*R[k] - 2*rights
          = 2*R[k] - 2*(R[k]-2)/2
          = R[k] + 2

A similar calculation is made on the left side of the curve.  The net turn
is the same and so the same lefts-rights=1 and thus from the dragon curve
L[k] left boundary

    ML[k] = 2*L[k] - 2*lefts
          = 2*L[k] - 2*(L[k]/2)
          = L[k]

The total is then

    MB[k] = MR[k] + ML[k]
          = R[k]+2 + L[k]
          = B[k] + 2                 since B[k]=R[k]+L[k]

The generating function can be had from the partial fractions form of the
dragon curve boundary.  B[k]+2 means adding 2/(1-x) which cancels out the
-2/(1-x) in gB(x).

=cut

#  /\     B[0]=2
# *--*    MB[0]=4
#  \/
#
#    *
#   /|\
#  /\|/   B[0]=4
# *--*    MB[0]=6
#  \/
#
#    *
#   /|\     B[0] = 8
#   \|/\    MR[2] = 6
#    *--*   ML[2] = 4
#     \/|\  MB[2] = 10
#     /\|/
#    *--*
#     \/
#
# 4,6,10,18,30,50,86,146,246,418,710,1202,
# 6,8,12,20,32,52,88,148,248,420,712,1204,

=pod

=head1 OEIS

The C<DragonMidpoint> is in Sloane's Online Encyclopedia of Integer
Sequences as

=over

L<http://oeis.org/A073089> (etc)

=back

    A073089   abs(dY) of n-1 to n, so 0=horizontal,1=vertical
                (extra initial 0)
    A077860   Y at N=2^k, being Re(-(i+1)^k + i-1)
    A090678   0=straight, 1=not straight  (extra initial 1,1)
    A203175   boundary of unit squares N=0 to N=2^k-1, value 4 onwards

=head2 A073089

For A073089=abs(dY), the midpoint curve is vertical when the C<DragonCurve>
has a vertical followed by a left turn, or horizontal followed by a right
turn.  C<DragonCurve> verticals are whenever N is odd, and the turn is the
bit above the lowest 0 in N (per L<Math::PlanePath::DragonCurve/Turn>).  So

    abs(dY) = lowbit(N) XOR bit-above-lowest-zero(N)

The n in A073089 is offset by 2 from the N numbering of the path here, so
n=N+2.  The initial value at n=1 in A073089 has no corresponding N (it would
be N=-1).

The mod-16 definitions in A073089 express combinations of N odd/even and
bit-above-low-0 which are the vertical midpoint segments.  The recurrence
a(8n+1)=a(4n+1) acts to strip zeros above a low 1 bit,

    n = 0b..uu0001
     -> 0b...uu001

In terms of N=n-2 this reduces

    N = 0b..vv1111
     -> 0b...vv111

which has the effect of seeking a lowest 0 in the range of the mod-16
conditions.

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::DragonCurve>,
L<Math::PlanePath::DragonRounded>

L<Math::PlanePath::AlternatePaperMidpoint>,
L<Math::PlanePath::R5DragonMidpoint>,
L<Math::PlanePath::TerdragonMidpoint>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019 Kevin Ryde

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
