# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde

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


# math-image --path=MooreSpiral --all --output=numbers_dash
# math-image --path=MooreSpiral,arms=2 --all --output=numbers_dash

# www.nahee.com/spanky/www/fractint/lsys/variations.html
# William McWorter mcworter@midohio.net
# http://www.nahee.com/spanky/www/fractint/lsys/moore.gif

package Math::PlanePath::MooreSpiral;
use 5.004;
use strict;
use List::Util 'min'; # 'max'
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 129;

use Math::PlanePath;
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

use Math::PlanePath::Base::NSEW;
@ISA = ('Math::PlanePath::Base::NSEW',
        'Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_down_pow',
  'digit_split_lowtohigh';

# uncomment this to run the ### lines
#use Smart::Comments;


use constant n_start => 0;

use constant parameter_info_array => [ { name      => 'arms',
                                         share_key => 'arms_2',
                                         display   => 'Arms',
                                         type      => 'integer',
                                         minimum   => 1,
                                         maximum   => 2,
                                         default   => 1,
                                         width     => 1,
                                         description => 'Arms',
                                       } ];
sub new {
  my $self = shift->SUPER::new(@_);
  $self->{'arms'} = max(1, min(2, $self->{'arms'} || 1));
  return $self;
}

my @next_state = (20,30, 0, 60, 0,10, 70,60,50, undef,    # 0
                  30, 0, 10,70,10, 20,40,70, 60,undef,    # 10
                   0, 10,20,40, 20,30,50, 40,70,undef,    # 20
                  10,20,30, 50,30, 0, 60,50,40, undef,    # 30
                  10,20, 30,50,40, 20,40,70, 60,undef,    # 40
                  20, 30, 0,60, 50,30,50, 40,70,undef,    # 50
                  30, 0,10, 70,60, 0, 60,50,40, undef,    # 60
                   0,10, 20,40,70, 10,70,60, 50,undef);   # 70
my @digit_to_x = ( 0, 1, 1,  0,-1,-2, -2,-2,-3, -3,    # 0
                   0, 0, -1,-1,-1, -1, 0, 1,  1, 0,    # 10
                   0, -1,-1, 0,  1, 2, 2,  2, 3, 3,    # 20
                   0, 0, 1,  1, 1, 1,  0,-1,-1,  0,    # 30
                   0, 0,  1, 1, 1,  2, 3, 4,  4, 3,    # 40
                   0,  1, 1, 0, -1,-1,-1, -1, 0, 0,    # 50
                   0, 0,-1, -1,-1,-2, -3,-4,-4, -3,    # 60
                   0,-1, -1, 0, 1,  1, 1, 1,  0, 0);   # 70
my @digit_to_y = ( 0, 0, 1,  1, 1, 1,  0,-1,-1,  0,    # 0
                   0, 1,  1, 0,-1, -2,-2,-2, -3,-3,    # 10
                   0,  0,-1,-1, -1,-1, 0,  1, 1, 0,    # 20
                   0,-1,-1,  0, 1, 2,  2, 2, 3,  3,    # 30
                   0,-1, -1, 0, 1,  1, 1, 1,  0, 0,    # 40
                   0,  0, 1, 1,  1, 2, 3,  4, 4, 3,    # 50
                   0, 1, 1,  0,-1,-1, -1,-1, 0,  0,    # 60
                   0, 0, -1,-1,-1, -2,-3,-4, -4,-3);   # 70
# state length 80 in each of 4 tables
# rot2 state 20

sub n_to_xy {
  my ($self, $n) = @_;
  ### MooreSpiral n_to_xy(): $n

  if ($n < 0) { return; }
  if (is_infinite($n)) { return ($n,$n); }

  my $int = int($n);
  $n -= $int;  # frac

  # initial state from arm number $int mod $arms
  my $state = 20;
  my $arms = $self->{'arms'};
  if ($arms > 1) {
    my $arm = _divrem_mutate($int,2);
    if ($arm) {
      $state = 0;
      $int += 1;
    }
  }

  my @digits = digit_split_lowtohigh($int,9);

  my $zero = $int*0;   # inherit bignum 0
  my $len = ($zero+3) ** scalar(@digits);
  unless ($#digits & 1) {
    $state ^= 20; # rot 18re0
  }

  ### digits: join(', ',@digits)."   count ".scalar(@digits)
  ### $len
  ### initial state: $state

  my $x = 0;
  my $y = 0;
  my $dir = 0;

  while (@digits) {
    $len /= 3;

    ### at: "$x,$y"
    ### $len
    ### digit: $digits[-1]
    ### state: $state
    # . "   ".state_string($state)

    $state += (my $digit = pop @digits);
    if ($digit != 8) {
    }
    $dir = $state;  # lowest non-zero digit

    ### digit_to_x: $digit_to_x[$state]
    ### digit_to_y: $digit_to_y[$state]
    ### next_state: $next_state[$state]

    $x += $len * $digit_to_x[$state];
    $y += $len * $digit_to_y[$state];
    $state = $next_state[$state];
  }

  ### final: "$x,$y"

  # with $n fractional part
  return ($n * ($digit_to_x[$dir+1] - $digit_to_x[$dir]) + $x,
          $n * ($digit_to_y[$dir+1] - $digit_to_y[$dir]) + $y);
}


#                            61-62 67-68-69-70            4
#                             |  |  |        |
#                            60 63 66 73-72-71            3
#                             |  |  |  |
#                            59 64-65 74-75-76            2
#                             |              |
# 11-10  5--4--3--2          58-57-56 83-82 77            1
#  |  |  |        |                 |  |  |  |
# 12  9  6     0--1          53-54-55 84 81 78       <- Y=0
#  |  |  |                    |        |  |  |
# 13  8--7                   52-51-50 85 80-79           -1
#  |                                |  |
# 14-15-16 25-26 31-32-33-34 43-44 49 86-87-88 97-98     -2
#        |  |  |  |        |  |  |  |        |  |  |
# 19-18-17 24 27 30 37-36-35 42 45 48 91-90-89 96 99     -3
#  |        |  |  |  |        |  |  |  |        |  |
# 20-21-22-23 28-29 38-39-40-41 46-47 92-93-94-95 ...    -4

# 40 -3*9 = 40-27=13
# 13 -8   = 5
#

# bottom right corner "40" N=(9^level-1)/2
# bottom left corner "20"
#   N=(9^level-1)/2 - 3*3^level
# len=3 Nr=(9*len*len-1)/2=40
#       Nl=Nr - 2*len*len - (len-1)
#         = (9*len*len-1)/2 - 2*len*len - (len-1)
#         = (9*len*len-1 - 4*len*len - 2*(len-1))/2
#         = (9*len*len - 1 - 4*len*len - 2*len + 2)/2
#         = (5*len*len - 2*len + 1)/2
#         = ((5*len - 2)*len + 1)/2
#
# round 2,5,etc 1+(3^level-1)/2 = x
#               2*(x-1) = 3^level-1
#               3^level = 2x-2+1 = 2x-1
# offset 1,4,etc 1+...+3^(level-1) = (3^level-1)/2
#

my @yx_to_rot   = (0,3,0,   # y=0
                   1,2,1,   # y=1
                   0,3,0);  # y=2
my @yx_to_digit = (-2,-3,-4,  # y=0
                   -1,0,1,    # y=1
                   4,3,2);    # y=2

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### MooreSpiral xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);

  my ($len, $level) = round_down_pow (max(abs($x),abs($y))*2 - 1,
                                      3);
  ### $len
  ### $level

  # offset to make bottom left corner X=0,Y=0
  {
    my $offset = (3*$len-1)/2;
    $x += $offset;
    $y += $offset;
    ### $offset
    ### offset to: "$x,$y"
    ### assert: $x >= 0
    ### assert: $y >= 0
    ### assert: $x < 3*$len
    ### assert: $y < 3*$len
  }
  if (is_infinite($x)) {
    return $x;
  }
  if (is_infinite($y)) {
    return $y;
  }

  my $arms = $self->{'arms'};
  my $npow = $len*$len;
  my $n = ($x * 0 * $y); #  + (9*$npow - 1)/2;
  my $rot = ($level & 1 ? 2 : 0);

  my @x = digit_split_lowtohigh ($x, 3);
  my @y = digit_split_lowtohigh ($y, 3);
  ### @x
  ### @y

  for ( ; $level >= 0; $level--) {
    ### $n
    ### $rot

    $x = $x[$level] || 0;
    $y = $y[$level] || 0;
    ### raw xy digits: "$x,$y"

    if ($rot&1) {
      ($x,$y) = (2-$y,$x)  # rotate +90
    }
    if ($rot&2) {
      $x = 2-$x;  # rotate 180
      $y = 2-$y;
    }
    ### rotated xy digits: "$x,$y"

    my $k = $y*3+$x;
    $rot += $yx_to_rot[$k];

    my $digit = $yx_to_digit[$k];
    $n += $npow*$digit;
    ### $digit
    ### add to n: $npow*$digit

    if ($n < 0 && $self->{'arms'} < 2) {
      ### negative when only 1 arm ...
      return undef;
    }

    $npow /= 9;
  }

  ### final n: $n

  if ($arms < 2) {
    return $n;
  }
  if ($n < 0) {
    return -1-2*$n;
  } else {
    return 2*$n;
  }
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### MooreSpiral rect_to_n_range(): "$x1,$y1, $x2,$y2"

  $x1 = round_nearest ($x1);
  $x2 = round_nearest ($x2);
  $y1 = round_nearest ($y1);
  $y2 = round_nearest ($y2);

  my ($len, $level) = round_down_pow (max(abs($x1),abs($y1),
                                          abs($x2),abs($y2))*2-1,
                                      3);
  ### $len
  ### $level

  return (0,
          ($x1 * 0 * $y1 * $x2 * $y2)
          + (9*$len*$len - 1) * $self->{'arms'} / 2);
}

1;
__END__

=for stopwords eg Ryde ie MooreSpiral Math-PlanePath Moore

=head1 NAME

Math::PlanePath::MooreSpiral -- 9-segment self-similar spiral

=head1 SYNOPSIS

 use Math::PlanePath::MooreSpiral;
 my $path = Math::PlanePath::MooreSpiral->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This is an integer version of a 9-segment self-similar curve by ...

                               61-62 67-68-69-70            4
                                |  |  |        |
                               60 63 66 73-72-71            3
                                |  |  |  |
                               59 64-65 74-75-76            2
                                |              |
    11-10  5--4--3--2          58-57-56 83-82 77            1
     |  |  |        |                 |  |  |  |
    12  9  6     0--1          53-54-55 84 81 78       <- Y=0
     |  |  |                    |        |  |  |
    13  8--7                   52-51-50 85 80-79           -1
     |                                |  |
    14-15-16 25-26 31-32-33-34 43-44 49 86-87-88 97-98     -2
           |  |  |  |        |  |  |  |        |  |  |
    19-18-17 24 27 30 37-36-35 42 45 48 91-90-89 96 99     -3
     |        |  |  |  |        |  |  |  |        |  |
    20-21-22-23 28-29 38-39-40-41 46-47 92-93-94-95 ...    -4

    -4 -3 -2 -1 X=0 1  2  3  4  5  6  7  8  9 10 11 12

The base pattern is the N=0 to N=9 shape.  Then there's 9 copies of that
shape in the same relative directions as those segments and with reversals
in the 3,6,7,8 parts.  The first reversed section is N=3*9=27 to N=4*9=36.

                       rev
              5------4------3------2
              |                    |
              |                    |
       9      6             0------1
       |      |rev
    rev|      |
       8------7
         rev

Notice the points N=9,18,27,...,81 are the base shape rotated 180 degrees.
Likewise for N=81,162,etc and any multiples of N=9^level, with each
successive level being rotated 180 degrees relative to the preceding.  The
effect is to spiral around with an ever fatter 3^level width,

    ******************************************************
    ******************************************************
    ******************************************************
    ******************************************************
    ******************************************************
    ******************************************************
    ******************************************************
    ******************************************************
    ******************************************************
    ***************************                  *********
    ***************************                  *********
    ***************************                  *********
    ***************************         ******   *********
    ***************************         *** **   *********
    ***************************         ***      *********
    ***************************         ******************
    ***************************         ******************
    ***************************         ******************
    ***************************
    ***************************
    ***************************
    ***************************
    ***************************
    ***************************
    ***************************
    ***************************
    ***************************

=head2 Arms

The optional C<arms =E<gt> 2> parameter can give a second copy of the spiral
rotated 180 degrees.  With two arms all points of the plane are covered.

     93--91  81--79--77--75  57--55  45--43--41--39 122-124  ..
      |   |   |           |   |   |   |           |   |   |   |
     95  89  83  69--71--73  59  53  47  33--35--37 120 126 132 
      |   |   |   |           |   |   |   |           |   |   | 
     97  87--85  67--65--63--61  51--49  31--29--27 118 128-130 
      |                                           |   |
     99-101-103  22--20  10-- 8-- 6-- 4  13--15  25 116-114-112 
              |   |   |   |           |   |   |   |           | 
    109-107-105  24  18  12   1   0-- 2  11  17  23 106-108-110 
      |           |   |   |   |           |   |   |   |         
    111-113-115  26  16--14   3-- 5-- 7-- 9  19--21 104-102-100 
              |   |                                           | 
    129-127 117  28--30--32  50--52  62--64--66--68  86--88  98 
      |   |   |           |   |   |   |           |   |   |   |
    131 125 119  38--36--34  48  54  60  74--72--70  84  90  96 
      |   |   |   |           |   |   |   |           |   |   | 
     .. 123-121  40--42--44--46  56--58  76--78--80--82  92--94 

The first arm is the even numbers N=0,2,4,etc and the second arm is the odd
numbers N=1,3,5,etc.

=head2 Wunderlich Serpentine Curve

The way the ends join makes little "S" shapes similar to the PeanoCurve.
The first is at N=5 to N=13,

    11-10  5
     |  |  |
    12  9  6
     |  |  | 
    13  8--7 

The wider parts then have these sections alternately horizontal or vertical
in the style of Walter Wunderlich's "serpentine" type 010 101 010 curve.
For example the 9x9 block N=41 to N=101,

    61--62  67--68--69--70 115-116 121
     |   |   |           |   |   |   |
    60  63  66  73--72--71 114 117 120
     |   |   |   |           |   |   |
    59  64--65  74--75--76 113 118-119
     |                   |   |        
    58--57--56  83--82  77 112-111-110
             |   |   |   |           |
    53--54--55  84  81  78 107-108-109
     |           |   |   |   |        
    52--51--50  85  80--79 106-105-104
             |   |                   |
    43--44  49  86--87--88  97--98 103
     |   |   |           |   |   |   |
    42  45  48  91--90--89  96  99 102
     |   |   |   |           |   |   |
    41  46--47  92--93--94--95 100-101

The whole curve is in fact like the Wunderlich serpentine started from the
middle.  This can be seen in the two arms picture above (in mirror image of
the usual PlanePath start direction for Wunderlich's curve).

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for the behaviour common to all path
classes.

=over 4

=item C<$path = Math::PlanePath::MooreSpiral-E<gt>new ()>

Create and return a new path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

=back

=head1 FORMULAS

=head2 X,Y to N

The correspondence to Wunderlich's 3x3 serpentine curve can be used to turn
X,Y coordinates in base 3 into an N.  Reckoning the innermost 3x3 as level=1
then the smallest abs(X) or abs(Y) in a level is

    Xlevelmin = (3^level + 1) / 2
    eg. level=2 Xlevelmin=5

which can be reversed as

    level = log3floor( max(abs(X),abs(Y)) * 2 - 1 )
    eg. X=7 level=log3floor(2*7-1)=2

An offset can be applied to put X,Y in the range 0 to 3^level-1,

    offset = (3^level-1)/2
    eg. level=2 offset=4

Then a table can give the N base-9 digit corresponding to X,Y digits

    Y=2   4   3   2      N digit
    Y=1  -1   0   1
    Y=0  -2  -3  -4
         X=0 X=1 X=2

A current rotation maintains the "S" part directions and is updated by a
table

    Y=2   0  +3   0     rotation when descending
    Y=1  +1  +2  +1     into sub-part
    Y=0   0  +3   0
         X=0 X=1 X=2

The negative digits of N represent backing up a little in some higher part.
If N goes negative at any state then X,Y was off the main curve and instead
on the second arm.  If the second arm is not of interest the calculation can
stop at that stage.

It no doubt would also work to take take X,Y as balanced ternary digits
1,0,-1, but it's not clear that would be any faster or easier to calculate.

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::PeanoCurve>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde

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
