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


package Math::PlanePath::LTiling;
use 5.004;
use strict;
use Carp 'croak';
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 129;
use Math::PlanePath;
@ISA = ('Math::PlanePath');
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_down_pow',
  'round_up_pow',
  'digit_split_lowtohigh';


# uncomment this to run the ### lines
#use Smart::Comments;


use constant n_start => 0;
use constant class_x_negative => 0;
use constant class_y_negative => 0;

use constant parameter_info_array =>
  [ { name            => 'L_fill',
      display         => 'L Fill',
      type            => 'enum',
      default         => 'middle',
      choices         => ['middle','left','upper','ends','all'],
      choices_display => ['Middle','Left','Upper','Ends','All'],
      description     => 'Which points to number with each "L".',
    },
  ];

my %sumxy_minimum = (middle => 0, # X=0,Y=0
                     left   => 1, # X=1,Y=0
                     upper  => 1, # X=0,Y=1
                     ends   => 1, # X=1,Y=0  and X=0,Y=1
                     all    => 0, # X=0,Y=0
                    );
sub sumxy_minimum {
  my ($self) = @_;
  return $sumxy_minimum{$self->{'L_fill'}};
}
*sumabsxy_minimum  = \&sumxy_minimum;
*absdiffxy_minimum = \&sumxy_minimum;
*rsquared_minimum  = \&sumxy_minimum;

{
  my %turn_any_straight = (# middle => 0,
                           left   => 1,
                           # upper  => 0,
                           ends   => 1,
                           all    => 1,
                          );
  sub turn_any_straight {
    my ($self) = @_;
    return $turn_any_straight{$self->{'L_fill'}};
  }
}

#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new (@_);
  my $L_fill = $self->{'L_fill'};
  if (! defined $L_fill) {
    $self->{'L_fill'} = 'middle';
  } elsif (! exists $sumxy_minimum{$L_fill}) {
    croak "Unrecognised L_fill option: ",$L_fill;
  }
  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### LTiling n_to_xy(): $n

  if ($n < 0) { return; }
  if (is_infinite($n)) { return ($n,$n); }

  {
    my $int = int($n);
    ### $int
    ### $n
    if ($n != $int) {
      my ($x1,$y1) = $self->n_to_xy($int);
      my ($x2,$y2) = $self->n_to_xy($int+1);
      my $frac = $n - $int;  # inherit possible BigFloat
      my $dx = $x2-$x1;
      my $dy = $y2-$y1;
      return ($frac*$dx + $x1, $frac*$dy + $y1);
    }
    $n = $int;       # BigFloat int() gives BigInt, use that
  }

  my $x = my $y = ($n * 0);  # inherit bignum 0
  my $len = $x + 1;          # inherit bignum 1

  my $L_fill = $self->{'L_fill'};
  if ($L_fill eq 'left') {
    $x += 1;
  } elsif ($L_fill eq 'upper') {
    $y += 1;
  } elsif ($L_fill eq 'ends') {
    my $rem = _divrem_mutate ($n, 2);
    if ($rem) { # low digit==1
      $y = $len;  # 1
    } else { # low digit==0
      $x = $len;  # 1
    }
  } elsif ($L_fill eq 'all') {
    my $rem = _divrem_mutate ($n, 3);
    if ($rem == 1) {
      $x = $len;  # 1
    } elsif ($rem == 2) {
      $y = $len;  # 1
    }
  }

  foreach my $digit (digit_split_lowtohigh($n,4)) {
    ### at: "$x,$y  digit=$digit"

    if ($digit == 1) {
      ($x,$y) = (4*$len-1-$y,$x);
    } elsif ($digit == 2) {
      $x += $len;
      $y += $len;
    } elsif ($digit == 3) {
      ($x,$y) = ($y,4*$len-1-$x);
    }
    $len *= 2;
  }

  ### final: "$x,$y"
  return ($x,$y);
}

my @yx_to_digit = ([0,0,1,1],
                   [0,2,2,1],
                   [3,2],
                   [3,3]);
my %fill_factor = (middle => 1,
                   left   => 1,
                   upper  => 1,
                   ends   => 2,
                   all    => 3);
my %yx_to_fill = (middle => [[0]],
                  left   => [[undef,0]],
                  upper   => [[],
                              [0]],
                  ends   => [[undef,0],
                             [1]],
                  all    => [[0,1],
                             [2]]);
sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### LTiling xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);
  if ($x < 0 || $y < 0) {
    return undef;
  }

  my ($len, $level) = round_down_pow (max($x,$y),
                                      2);
  if (is_infinite($level)) {
    return $level;
  }

  my $n = ($x * 0 * $y);  # inherit bignum 0

  while ($level-- >= 0) {
    ### assert: $x >= 0
    ### assert: $y >= 0
    ### assert: ($y < 2*$len && $x < 4*$len) || ($x < 2*$len && $y < 4*$len)

    ### $len
    ### x: int($x/$len)
    ### y: int($y/$len)

    my $digit = $yx_to_digit[int($y/$len)]->[int($x/$len)];
    if ($digit == 1) {
      ($x,$y) = ($y,4*$len-1-$x);
    } elsif ($digit == 2) {
      $x -= $len;
      $y -= $len;
    } elsif ($digit == 3) {
      ($x,$y) = (4*$len-1-$y,$x);
    }

    ### to: "digit=$digit  xy=$x,$y"

    $n = $n*4 + $digit;
    $len /= 2;
  }

  ### assert: ($x==0 && $y== 0) || ($x==1 && $y== 0) || ($x==0 && $y== 1)

  my $fill = $self->{'L_fill'};
  if (defined (my $digit = $yx_to_fill{$fill}->[$y]->[$x])) {
    return $n*$fill_factor{$fill} + $digit;
  }
  return undef;
}

my %range_factor = (middle => 3,
                    left   => 3,
                    upper  => 3,
                    ends   => 6,
                    all    => 8);
# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### LTiling rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);
  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;
  ### rect: "X = $x1 to $x2, Y = $y1 to $y2"

  if ($x2 < 0 || $y2 < 0) {
    ### rectangle outside first quadrant ...
    return (1, 0);
  }

  my ($len, $level) = round_down_pow (max($x2,$y2), 2);
  ### $len
  ### $level
  if (is_infinite($level)) {
    return (0,$level);
  }

  return (0,
          $len*$len * $range_factor{$self->{'L_fill'}});
}


#------------------------------------------------------------------------------
# levels

sub level_to_n_range {
  my ($self, $level) = @_;
  return (0,  4**$level * $fill_factor{$self->{'L_fill'}} - 1);
}
sub n_to_level {
  my ($self, $n) = @_;
  if ($n < 0) { return undef; }
  if (is_infinite($n)) { return $n; }
  $n = round_nearest($n);
  _divrem_mutate ($n, $fill_factor{$self->{'L_fill'}});
  my ($pow, $exp) = round_up_pow ($n+1, 4);
  return $exp;
}

#------------------------------------------------------------------------------
1;
__END__


=for stopwords eg Ryde ie Math-PlanePath Asano Ranjan Roos Welzl Widmayer Informatics Nlevel OEIS bitwise

=head1 NAME

Math::PlanePath::LTiling -- 2x2 self-similar of four pattern parts

=head1 SYNOPSIS

 use Math::PlanePath::LTiling;
 my $path = Math::PlanePath::LTiling->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This is a self-similar tiling by "L" shapes.  A base "L" is replicated four
times with end parts turned +90 and -90 degrees to make a larger L,

                                        +-----+-----+
                                        |12   |   15|
                                        |  +--+--+  |
                                        |  |14   |  |
                                        +--+  +--+--+
                                        |  |  |11   |
                                        |  +--+  +--+
                                        |13   |  |  |
                   +-----+              +-----+--+  +--+--+-----+
                   | 3   |              | 3   |  |10   |  |    5|
                   |  +--+        -->   |  +--+  +--+--+  +--+  |
                   |  |  |              |  |  | 8   |   9 |  |  |
    +--+           +--+  +--+--+        +--+  +--+--+--+--+  +--+
    |  |     -->   |  | 2   |  |        |  | 2   |  |  |   6 |  |
    |  +--+        |  +--+--+  |        |  +--+--+  |  +--+--+  |
    | 0   |        | 0   |   1 |        | 0   |   1 | 7   |   4 |
    +-----+        +-----+-----+        +-----+-----+-----+-----+

The parts are numbered to the left then middle then upper.  This relative
numbering is maintained when rotated at the next replication level, as for
example N=4 to N=7.

The result is to visit 1 of every 3 points in the first quadrant with a
subtle layout of points and spaces making diagonal lines and little 2x2
blocks.

    15  |  48          51  61          60 140         143 163
    14  |      50                  62         142                 168
    13  |          56          59                 139         162
    12  |  49          58              63 141             160
    11  |  55              44          47 131         138
    10  |          57          46                 136         137
     9  |      54                  43         130                 134
     8  |  52          53  45             128         129 135
     7  |  12          15  35          42              37  21
     6  |      14                  40          41                  22
     5  |          11          34                  38          25
     4  |  13              32          33  39          36
     3  |   3          10               5  31              26
     2  |           8           9                  27          24
     1  |       2                   6          30                  18
    Y=0 |   0           1   7           4  28          29  19
        +------------------------------------------------------------
          X=0   1   2   3   4   5   6   7   8   9  10  11  12  13  14

On the X=Y leading diagonal N=0,2,8,10,32,etc is the integers made from only
digits 0 and 2 in base 4.  Or equivalently integers which have zero bits at
all even numbered positions, binary c0d0e0f0.

=head2 Left or Upper

Option C<L_fill =E<gt> "left"> or C<L_fill =E<gt> "upper"> numbers the tiles
instead at their left end or upper end respectively.

    L_fill => 'left'           8  |      52              45  43        
                               7  |          15                      42
    +-----+                    6  |  12              35          40    
    |     |                    5  |      14                  34  33    
    |  +--+                    4  |      13  11          32            
    | 3|  |                    3  |                  10   9   5        
    +--+  +--+--+              2  |   3           8           6      31
    |  |    2| 1|              1  |           2   1               4    
    |  +--+--+  |             Y=0 |       0               7            
    |    0|     |                 +------------------------------------
    +-----+-----+                   X=0   1   2   3   4   5   6   7   8


    L_fill => 'upper'          8  |          53                  42
                               7  |      12              35  40
    +-----+                    6  |          14  15      34          41
    |    3|                    5  |  13          11  32              39
    |  +--+                    4  |              10          33
    |  | 2|                    3  |       3   8
    +--+  +--+--+              2  |       2           9           5
    | 0|     |  |              1  |   0               7   6          28
    |  +--+--+  |             Y=0 |           1               4
    |     | 1   |                 +------------------------------------
    +-----+-----+                   X=0   1   2   3   4   5   6   7   8

The effect is to disrupt the pattern a bit though the overall structure of
the replications is unchanged.

"left" is as viewed looking towards the L from above.  It may have been
better to call it "right", but won't change that now.

=head2 Ends

Option C<L_fill =E<gt> "ends"> numbers the two endpoints within each "L",
first the left then upper.  This is the inverse of the default middle shown
above, ie. it visits all the points which the middle option doesn't, and so
2 of every 3 points in the first quadrant.

    +-----+
    |    7|
    |  +--+
    | 6| 5|
    +--+  +--+--+
    | 1|    4| 2|
    |  +--+--+  |
    |    0| 3   |
    +-----+-----+

     15  |      97 102         123 120         281 286         327 337
     14  |  96     101 103 122 124     121 280     285 287 326 325
     13  |  99 100     113 118     125 126 283 284     279 321     324
     12  |      98 112     117 119 127         282 278 277     320 323
     11  |     111 115 116      89  94         263 273     276 274 266
     10  | 110 109     114  88      93  95 262 261     272 275     268
      9  | 105     108 106  91  92      87 257     260 258 271 269
      8  |     104 107          90  86  85     256 259         270 265
      7  |      25  30          71  81      84  82  74          43  40
      6  |  24      29  31  70  69      80  83      76  75  42  44
      5  |  27  28      23  65      68  66  79  77      72  50      45
      4  |      26  22  21      64  67          78  73      52  51  47
      3  |       7  17      20  18  10          63  55  53      48  34
      2  |   6   5      16  19      12  11  62  61      54  49      36
      1  |   1       4   2  15  13       8  57      60  58  39  37
     Y=0 |       0   3          14   9          56  59          38  33
         +------------------------------------------------------------
           X=0   1   2   3   4   5   6   7   8   9  10  11  12  13  14

=head2 All

Option C<L_fill =E<gt> "all"> numbers all three points of each "L", as
middle, left then right.  With this the path visits all points of the first
quadrant.

                           7  |  36  38  46  45 105 107 122 126
    +-----+                6  |  37  42  44  47 106 104 120 121
    | 9 11|                5  |  41  43  33  35  98 102 103 100
    |  +--+                4  |  39  40  34  32  96  97 101  99
    |10| 8|                3  |   9  11  26  30  31  28  16  15
    +--+  +--+--+          2  |  10   8  24  25  29  27  19  17
    | 2| 6  7| 4|          1  |   2   6   7   4  23  20  18  13
    |  +--+--+  |         Y=0 |   0   1   5   3  21  22  14  12
    | 0  1| 5  3|             +--------------------------------
    +-----+-----+               X=0   1   2   3   4   5   6   7

Along the X=Y leading diagonal N=0,6,24,30,96,etc are triples of the values
from the single-point case, so 3* numbers using digits 0 and 2 in base 4,
which is the same as 2* numbers using 0 and 3 in base 4.

=head2 Level Ranges

For the "middles", "left" or "upper" cases with one N per tile, and taking
the initial N=0 tile as level 0, a replication level is

    Nstart = 0
     to
    Nlevel = 4^level - 1      inclusive

    Xmax = Ymax = 2 * 2^level - 1

For example level 2 which is the large tiling shown in the introduction is
N=0 to N=4^2-1=15 and extends to Xmax=Ymax=2*2^2-1=7.

For the "ends" variation there's two points per tile, or for "all" there's
three, in which case the Nlevel increases to

    Nlevel_ends = 2 * 4^level - 1
    Nlevel_all  = 3 * 4^level - 1

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::LTiling-E<gt>new ()>

=item C<$path = Math::PlanePath::LTiling-E<gt>new (L_fill =E<gt> $str)>

Create and return a new path object.  The C<L_fill> choices are

    "middle"    the default
    "left"
    "upper"
    "ends"
    "all"

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return

    0,   4**$level - 1      middle, left, upper
    0, 2*4**$level - 1      ends
    0, 3*4**$level - 1      all

There are 4^level L shapes in a level, each containing 1, 2 or 3 points,
numbered starting from 0.

=back

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to this
path include

=over

L<http://oeis.org/A062880> (etc)

=back

    L_fill=middle
      A062880    N on X=Y diagonal, base 4 digits 0,2 only
      A048647    permutation N at transpose Y,X
                   base4 digits 1<->3 and 0,2 unchanged
      A112539    X+Y+1 mod 2, parity inverted

    L_fill=left or upper
      A112539    X+Y mod 2, parity

A112539 is a parity of bits at even positions in N, ie. count 1-bits at even
bit positions (least significant is bit position 0), then add 1 and take
mod 2.  This works because in the pattern sub-blocks 0 and 2 are unchanged
and 1 and 3 are turned so as to be on opposite X,Y odd/even parity, so a
flip for every even position 1-bit.  L_fill=middle starts on a 0 even
parity, and L_fill=left and upper start on 1 odd parity.  The latter is the
form in A112539 and L_fill=middle is the bitwise 0E<lt>-E<gt>1 inverse.

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::CornerReplicate>,
L<Math::PlanePath::SquareReplicate>,
L<Math::PlanePath::QuintetReplicate>,
L<Math::PlanePath::GosperReplicate>

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
