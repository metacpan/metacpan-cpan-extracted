# Copyright 2013, 2014, 2015 Kevin Ryde

# This file is part of Math-PlanePath-Toothpick.
#
# Math-PlanePath-Toothpick is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Math-PlanePath-Toothpick is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath-Toothpick.  If not, see <http://www.gnu.org/licenses/>.


package Math::PlanePath::HTree;
use 5.004;
use strict;
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits 119  # v.119 for round_up_pow()
  'round_up_pow',
  'round_down_pow',
  'bit_split_lowtohigh',
  'digit_join_lowtohigh';

use Math::PlanePath::LCornerTree;
*_divrem = \&Math::PlanePath::LCornerTree::_divrem;

use vars '$VERSION', '@ISA';
$VERSION = 18;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

# uncomment this to run the ### lines
# use Smart::Comments;


# return $remainder, modify $n
# the scalar $_[0] is modified, but if it's a BigInt then a new BigInt is made
# and stored there, the bigint value is not changed
sub _divrem_mutate {
  my $d = $_[1];
  my $rem;
  if (ref $_[0] && $_[0]->isa('Math::BigInt')) {
    ($_[0], $rem) = $_[0]->copy->bdiv($d);  # quot,rem in array context
    if (! ref $d || $d < 1_000_000) {
      return $rem->numify;  # plain remainder if fits
    }
  } else {
    $rem = $_[0] % $d;
    $_[0] = int(($_[0]-$rem)/$d); # exact division stays in UV
  }
  return $rem;
}


use constant n_start => 1;
use constant class_x_negative => 0;
use constant class_y_negative => 0;
use constant tree_num_children_list => (0,1,2);

sub n_to_xy {
  my ($self, $n) = @_;
  ### HTree n_to_xy(): $n

  if ($n < 1) { return; }
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

  my $zero = $n * 0;
  my @nbits = bit_split_lowtohigh($n);
  my $len = (2 + $zero) ** int($#nbits/2);   # half power
  ### $len

  # eg. N=9 "up" block, nbits even, $#nbits odd, dX=1 dY=0 East
  # High 1-bit of sub-tree position does rotate +90 to North for
  # initial step North N=8 to N=9.
  #
  # eg. N=17 "right" block, nbits odd, $#nbits even, dX=0 dY=-1 South
  # High 1-bit of sub-tree position does rotate +90 to East for
  # initial step East N=16 to N=17.
  #
  my $dx = ($#nbits % 2);
  my $dy = $dx - 1;
  ### initial direction: "$dx, $dy"

  my $x = my $y = $len;
  if ($dx) {
    $y *= 2;
  }
  $x -= 1;
  $y -= 1;
  ### initial xy: "$x, $y"

  ### assert: $nbits[-1] == 1
  pop @nbits;  # strip high 1-bit which is N=2^k spine bit
  ### strip high spine 1-bit to: @nbits
  # N=10001xxx
  #    ^^^^^^^ leaving these

  # Strip high 0-bits of sub-tree.
  # Could have @nbits all 0-bits if N=2^k spine point.
  while (@nbits && ! $nbits[-1]) {
    pop @nbits;
  }
  ### strip high zeros to: @nbits
  # N=10001xxx
  #       ^^^^ leaving these
  # or if an N=1000000 spine point then @nbits now empty and no move $x,$y.

  foreach my $bit (reverse @nbits) {   # high to low
    ### at: "$x,$y  bit=$bit len=$len dir=$dx,$dy"

    ($dx,$dy) = ($dy,-$dx);  # rotate -90 for $bit==0
    if ($bit) {
      $dx = -$dx;            # rotate 180 to give rotate +90 for $bit==1
      $dy = -$dy;
    }
    ### turn to: "dir=$dx,$dy"

    if ($dx) { $len /= 2; }  # halve when going horizontal
    $x += $dx * $len;
    $y += $dy * $len;
  }

  ### return: "$x,$y"
  return ($x,$y);
}

#                                  |    [37]   |           34=10,0010
# 13            |                 4,13--5,13--6,13         35=10,0011
#               |                  |     |     |
# 12            |                        |                 36=10,0100
#               |          [33]          |                 37=10,0101
# 11       [35]1,7---------3,7----------5,7[34]
#               |           |            |
# 10  0,10      |           |     4,6    |
#      |        |    |      |      |     |     |
#  9  0,9-----1,9---2,9     |     4,5---5,5---6,5
#      |             |      |      |    [36]   |
#  8  0,8                   |     4,4
#                           |
#  7                   [32]3,7-------------------------------
#                           |
#  6  0,6            2,6    |      [30]        [29]          17=1,0001
#      |       [9]    |     |       |    [19]   |            18=1,0010
#  5  0,5------1,5---2,5    |     [23]---5,5---[22]          20=1,0100
#      |        |     |     |       |     |     |            24=1,1000
#  4  0,4       |    2,4    |      [31]   |    [28]
#     [15]      |           |             |
#  3        [8]1,3---------3,3-----------5,3[17]
#               |          [16]           |
#  2  0,2[3]    |    2,2[7]        [24]   |    [27]
#      |        |     |             |     |     |
#  1  0,1[2]---1,1---2,1[5]    [20]4,1---5,1---6,1[21]       21=1,0101
#      |        4     |             |    [18]   |
#  0  0,0[1]         2,0[6]        [25]        [26]
#
#      0        1     2      3      4     5      6

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### HTree xy_to_n(): "$x,$y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);
  if (is_infinite($x)) {
    return $x;
  }
  if (is_infinite($y)) {
    return $y;
  }

  my ($len,$exp);
  my $n;
  my ($xlen,$xexp) = round_down_pow($x+1, 2);
  my ($ylen,$yexp) = round_down_pow($y+1, 2);
  if ($yexp > $xexp) {
    ### Y bigger ...
    $len = $ylen/2;
    $exp = $yexp;
    $n = $len*$len*2;

    $y -= $ylen;
    ### to: "$x,$y  len=$len"
    if ($x == $len-1 && $y == -1) {
      ### spine ...
      return $n;
    }

  } else {
    ### X bigger, fake initial X bit ...
    $n = $xlen;
    $len = $xlen;
    $exp = $xexp;
    $n = $len*$len;

    if ($x == $len-1 && $y == $len-1) {
      ### spine ...
      return $n;
    }
  }

  if ($x < 0 || $y < 0) {
    return undef;
  }

  ### $n
  my @nbits;  # high to low


  while ($exp-- >= 0) {
    ### X at: "$x,$y len=$len"
    ### assert: $len >= 1
    ### assert: $x >= 0
    ### assert: $y >= 0
    ### assert: $x <= 2*$len
    ### assert: $y <= 2*$len

    if ($x == $len-1 && $y == $len-1) {
      ### midpoint X ...

      # ### nbits HtoL: join('',@nbits)
      # ### shift off high nbits ...
      # shift @nbits;

      last;
    }
    if ($x >= $len) {
      ### move left, digit 0 ...
      $x -= $len;
      push @nbits, 0;
    } else {
      ### rotate 180, digit 0: "$x,$y"
      push @nbits, 1;
      $x = $len-2 - $x;
      $y = 2*$len-2 - $y;
      if ($x < 0 || $y < 0) {
        ### outside: "$x,$y"
        return undef;
      }
    }

    ### Y at: "$x,$y len=$len"
    ### assert: $x >= 0
    ### assert: $y >= 0
    ### assert: $x <= $len
    ### assert: $y <= 2*$len

    if ($y == $len-1 && $x == $len/2-1) {
      ### midpoint Y ...

      last;
    }
    if ($y >= $len) {
      ### move down only, digit 1 ...
      $y -= $len;
      push @nbits, 1;
    } else {
      ### rotate 180, digit 0 ...
      push @nbits, 0;
      $x = $len-2 - $x;
      $y = $len-2 - $y;
      if ($x < 0 || $y < 0) {
        ### outside: "$x,$y"
        return undef;
      }
    }

    $len /= 2;
  }

  if ($yexp > $xexp) {
  } else {
    ### nbits HtoL: join('',@nbits)
    ### shift off high nbits ...
    shift @nbits;
  }

  ### nbits HtoL: join('',@nbits)

  if ($yexp > $xexp) {
  } else {
  }


  @nbits = reverse @nbits;
  push @nbits, 1;

  ### nbits HtoL: join('',reverse @nbits)
  return $n + digit_join_lowtohigh(\@nbits,2);
}


#  7
#                |
#  6  |       |  |  |       |
#  5  *---*---*  |  *---*---*
#  4  |   |   |  |  |   |   |
#         |      |      |
#  3      *------*------*
#         |             |
#  2  |   |   |     |   |   |
#  1  *---*---*     *---*---*
#  0  |       |     |       |
#     0   1   2  3  4   5   6
#
# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### HTree rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest($x1);
  $x2 = round_nearest($x2);
  $y1 = round_nearest($y1);
  $y2 = round_nearest($y2);

  $x2 = max($x1,$x2);
  $y2 = max($y1,$y2);
  if ($x2 < 0 || $y2 < 0) {
    ### all outside first quadrant ...
    return (1,0);
  }

  my ($pow) = round_down_pow(max(2*$x2, $y2) + 1,
                             2);
  return (1, $pow*$pow);

  # my ($xpow) = round_down_pow($x2+1, 2);
  # my ($ypow) = round_down_pow($y2+1, 2);
  # if ($xpow > $ypow) {
  #   return (1, 2*$xpow*$xpow);
  # } else {
  #   return (1, $ypow*$ypow);
  # }
}

# 5*2^n, 6*2^n successively
# being start of last two rows of each sub-tree
#   depth=13   160 10100000
#   depth=14   192 11000000
#
sub tree_depth_to_n {
  my ($self, $depth) = @_;
  ### HTree depth_to_n(): $depth
  $depth = int($depth);
  if ($depth < 3) {
    if ($depth < 0) { return undef; }
    return $depth + 1;
  }
  ($depth, my $rem) = _divrem ($depth-3, 2);
  return (5+$rem) * 2**$depth;
}

# spine 2^n
#
sub tree_depth_to_n_end {
  my ($self, $depth) = @_;
  ### HTree depth_to_n(): $depth
  if ($depth < 0) {
    return undef;
  }
  return 2**int($depth);
}

#  0  N=1
#      |
#  1  N=2--
#      |   \
#  2  N=3   N=4-------
#            |        \
#  3        N=5        N=8 ------------
#          /  \         |               \
#  4     N=6  N=7      N=9              N=16----------
#                     /    \             |            \
#  5              N=10      N=11        N=17           N=32------
#                 /  \      /  \        /   \           |        \
#  6           N=12 N=13  N=14 N=15   N=18 N=19        N=33       N=64---
#                                     /         \    /     \       |     \
#                                  N=20   [4of]      N=34 N=35     N=65   N=128
# 0  1  = 1
# 1  1  = 1
# 2  2  = 1 + 1
# 3  2  = 1 + 1
# 4  4  = 2 + 1 + 1
# 5  4  = 2 + 1 + 1
# 6  8  = 4 + 2 + 1 + 1
# 7  8
# 8  16
# 9  16
#
# 1 + sum i=0 to floor(depth/2)-1 of 2^i
#   = 2^floor(depth/2)

sub tree_depth_to_width {
  my ($self, $depth) = @_;
  ### HTree tree_n_to_subheight(): $depth

  if ($depth < 0) {
    return undef;
  }
  $depth = int($depth/2);
  return 2**$depth;
}


sub tree_n_to_depth {
  my ($self, $n) = @_;
  ### HTree n_to_depth(): $n

  if ($n < 1) { return undef; }
  $n = int($n);
  if (is_infinite($n)) { return $n; }
  my ($pow,$depth) = round_down_pow($n,2);
  if ($n -= $pow) {
    ($pow, my $exp) = round_down_pow($n,2);
    $depth += $exp+1;
  }
  return $depth;
}


# (n-pow)*2 + pow
#   = 2*n-2*pow+pow
#   = 2*n-pow
# (n-pow)*2 < pow
#   2*n-2*pow < pow
#   2*n-pow < 2*pow
# 1011 -> 011 -> 110 -> 1110
sub tree_n_children {
  my ($self, $n) = @_;
  ### HTree tree_n_children(): $n

  if ($n < 1) {
    return;
  }

  my ($pow) = round_down_pow($n,2);
  if ($pow == 1) {
    return $n+1;
  }
  if ($n == $pow) {
    return ($n+1, 2*$n);
  }

  $n *= 2;
  $n -= $pow;
  if ($n < 2*$pow) {
    return ($n, $n+1);
  } else {
    return;
  }
}

# 1
# 2 3
# 4 5,   6,7
#   101  11x
# 8 9,   10,11,    12,13,14,15
#   1001 1010,1011  1100,1101
#
# (n-pow)/2 + pow
#   = (n-pow+2*pow)/2
#   = (n+pow)/2
#
sub tree_n_parent {
  my ($self, $n) = @_;
  ### HTree tree_n_parent(): $n

  if ($n < 2) {
    return undef;
  }
  my ($pow) = round_down_pow($n,2);
  if ($n == $pow) {
    return $n/2;
  }
  return ($n + $pow - ($n%2)) / 2;
}

# length of the run of 0s immediately below the high 1-bit
#   10001111
#    ^^^------ 3 0-bits
#
sub tree_n_to_subheight {
  my ($self, $n) = @_;
  ### HTree tree_n_to_subheight(): $n

  if ($n < 2) {
    return undef;
  }
  my ($pow,$exp) = round_down_pow($n,2);
  if ($n == $pow) {
    return undef;  # spine, infinite
  }
  $n -= $pow;
  ($pow, my $exp2) = round_down_pow($n,2);
  return $exp - $exp2 - 1;
}


#------------------------------------------------------------------------------
# levels

sub level_to_n_range {
  my ($self, $level) = @_;
  return (1, 2**(2*$level+1) - 1);
}
sub n_to_level {
  my ($self, $n) = @_;
  if ($n < 1) { return undef; }
  if (is_infinite($n)) { return $n; }
  $n = round_nearest($n);
  _divrem_mutate ($n, 2);
  my ($pow, $exp) = round_up_pow ($n+1, 4);
  return $exp;
}

#------------------------------------------------------------------------------
1;
__END__

=for stopwords eg Ryde Math-PlanePath-Toothpick OEIS

=head1 NAME

Math::PlanePath::HTree -- H-tree

=head1 SYNOPSIS

 use Math::PlanePath::HTree;
 my $path = Math::PlanePath::HTree->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path is a version of the H-tree starting from an extremity and going
breadth-first into successive sub-blocks of the tree.

=cut

# math-image --path=HTree --output=numbers --all --size=75x16

=pod

                                    ...
                                     |
     14 58      57      54      53   | 122     121     118     117
      |  |       |       |       |   |   |       |       |       |
     13 45--38--44      43--37--42   |  93--78--92      91--77--90
      |  |   |   |       |   |   |   |   |   |   |       |   |   |
     12 59   |  56      55   |  52   | 123   | 120     119   | 116
      |      |               |       |       |               |
     11     35------33------34       |      71------67------70
      |      |       |       |       |       |       |       |
     10 60   |  63   |  48   |  51   | 124   | 127   | 112   | 115
      |  |   |   |   |   |   |   |   |   |   |   |   |   |   |   |
     9| 46--39--47   |  40--36--41   |  94--79--95   |  88--76--89
      |  |       |   |   |       |   |   |       |   |   |       |
     8| 61      62   |  49      50   | 125     126   | 113     114
      |              |               |               |
     7|             32--------------64--------------65
      |              |                               |
     6| 14      13   |  30      29      98      97   | 110     109
      |  |       |   |   |       |       |       |   |   |       |
     5| 11---9--10   |  23--19--22      81--72--80   |  87--75--86
      |  |   |   |   |   |   |   |       |   |   |   |   |   |   |
     4| 15   |  12   |  31   |  28      99   |  96   | 111   | 108
      |      |       |       |               |       |       |
     3|      8------16------17              68------66------69
      |      |               |               |               |
     2|  3   |   7      24   |  27     100   | 103     104   | 107
      |  |   |   |       |   |   |       |   |   |       |   |   |
     1|  2---4---5      20--18--21      82--73--83      84--74--85
      |  |       |       |       |       |       |       |       |
     0|  1       6      25      26     101     102     105     106
      |
       -------------------------------------------------------------
       X=0   1   2   3   4   5   6   7   8   9  10  11  12  13  14

Each tree block starts at N=2^k and goes up or right.  For example N=8
descends into block N=9 to N=15 above, and N=16 into block N=17 to N=31 to
the right.  The "spine" points N=2^k continue infinitely but the blocks
above or right terminate at sub-depth k.

    Spine         Sub-Tree

     N=1
      |
     N=2 --------- N=3
      |
     N=4 --------- N=5
      |            /  \
      |          N=6  N=7
      |
     N=8 ----------- N=9
      |            /     \
      |        N=10      N=11
      |        /  \      /  \
      |     N=12 N=13  N=14 N=15
      |
     N=16 ---
      |

Within a sub-block the points are a binary tree traversed breadth first and
anti-clockwise.  So for example N=20,21,22,23 go anti-clockwise, then the
next row N=24 to N=31 similarly anti-clockwise.

Notice the pattern made by the blocks is symmetric around the N=2^k spine,
so for example at N=64 the preceding parts on the left are the same pattern
as the block on the right.  The way the numbering goes is different, but the
shape is the same.

=head2 Infinitely Smaller

The H-tree is usually conceived as an initial H shape growing four smaller
H's at each endpoint.  The N=1 start is not like this, it begins at a corner
and grows across.

A central growth can be had here by beginning at a suitable sized "up"
direction block.  For example N=33 in the sample above.  "H" shaped parts
grow symmetrically around such a start.

    Nmid = 2*4^k+1 to 4*4^k-1        eg. k=2  N=33 to N=63
    being 2*4^k-1 many points            31 points
    and 2k tree rows                     4 rows
    beginning X=4^k/2                    X=8

A "right" side sub-part such as N=65 could be used in a similar way if a
2-high by 1-wide portion was wanted.

The tree is also often conceived as branch lengths decreasing by factor
sqrt(2) each time.  That could be had here using X*sqrt(2) to widen all the
horizontals.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::HTree-E<gt>new ()>

Create and return a new path object.

=back

=head2 Tree Methods

=over

=item C<@n_children = $path-E<gt>tree_n_children($n)>

Return the children of C<$n>, or an empty list if C<$n> has no children
(including when C<$n E<lt> 1>, ie. before the start of the path).

Within a sub-tree block the children are consecutive N values, but that's
not so for the spine points N=2^k.  For example N=16 has children N=17 and
N=32 which are not consecutive.

=item C<$n_parent = $path-E<gt>tree_n_parent($n)>

Return the parent node of C<$n>, or C<undef> if C<$n E<lt>= 1> (the start of
the path).

=back

=head2 Tree Descriptive Methods

=over

=item C<@nums = $path-E<gt>tree_num_children_list()>

Return list 0,1,2 since there are nodes with 0, 1 and 2 children in the
tree.  N=1 has 1 child and thereafter each point has 0 or 2.

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<(1, 2*4**$level - 1)>.  This is a square block of points X,Y E<lt>=
2*(2^level-1).

=back

=head1 FORMULAS

=head2 Depth to N

For C<tree_depth_to_n()> it can be noted the sub-trees overlap in the
following style,

    Depth

     0  N=1
         |
     1  N=2--
         |   \
     2  N=3   N=4------
               |       \
     3        N=5       N=8 -------------
             /  \        |               \
     4     N=6  N=7     N=9               N=16--------
                       /    \              |          \
     5              N=10      N=11        N=17        N=32-----
                    /  \      /  \        /   \        |       \
     6           N=12 N=13  N=14 N=15   N=18 N=19     N=33      N=64--
                                        /  \ / \      /   \      |

A sub-tree begins at depth k and ends at depth 2k.  So tree k-1 has ended at
depth 2k-2 leaving tree k as the smallest N for depths 2k-1 and 2k, those
being its last two rows.  For example depth=3,4 is sub-tree k=2, and
depth=5,6 is sub-tree k=3.

The last two rows of sub-tree k have N in binary

    1000000     N=2^k start
     ...
    101xxxx     second last row
    11xxxxx     last row

So third and second highest 1-bit formed by 5=[101]*2^d and 6=[110]*2^d give

    d = floor((depth-3)/2)
    Nrow = / 5*2^d   if depth odd
           \ 6*2^d   if depth even

Eg. depth=5, d=1, Nrow=5*2^1=10, or depth=6, d=1, Nrow=12.

=head2 Depth to N End

As can be seen in the L</Depth to N> diagram above, the last N in a tree row
is always the "spine" point N=2^depth.  All sub-trees are run to completion
before the next spine point is taken, and those sub-trees have power-of-2
many points.

=head2 Depth to Width

The total number of points in a given row is a sum across those sub-trees
which are running at that depth.  Sub-trees k=floor(depth/2) to k=depth are
running and their rows have

    e = floor(depth/2)
    2^(e-1) + 2^(e-2) + ... + 4 + 2 + 1

plus the spine point N=2^depth gives

    width = 2^floor(depth/2)

Notice this is not the same as Nend-Nrow, since the point numbering is not
breadth-wise across all sub-trees, only within each sub-tree.  This means N
descends into sub-trees and then jumps back up again to do the next so rows
are not contiguous runs of N.

=head2 N Children

For C<tree_n_children()>, a spine point N=2^k has two children, begin N+1
for the first of the sub-tree and 2N for the next spine point N=2^(k+1),

    spine point N=2^k   children N+1
                                 2N

Otherwise in a sub-tree the children are a bit-shift left

    N          = 10000xxx
    N children / 1000xxx0    left shift except for high 1-bit
               \ 1000xxx1

If the second highest bit of N is a 1-bit then that's the last row of the
sub-tree and there's no children

    N = 11xxxxxx    last row, no children

=head2 N Parent

For C<tree_n_parent()>, a spine point N=2^k the parent it the preceding
spine N=2^(k-1).  Otherwise going up a level in a sub-tree is a bit shift

    N       = 1000xxxx
    Nparent = 10000xxx    right shift except for high 1-bit

=head2 N to Sub-Tree Height

For C<tree_n_to_subheight()>, the height of the sub-tree at N is the number
of 0-bits between the two highest 1-bits of N.

    100010101
     ^^^--------- 3 zeros between highest 1-bits

If there's only a single 1-bit in N then it's an N=2^k "spine" point and the
sub-height is infinite since the spine continues infinitely.

This zeros rule works because the sub-trees at each N=2^k are numbered
breadth first with 2^m points in each row.  For example at N=17 the sub-tree
to the right goes

    N binary  N decimal    Sub-Height
    --------  ----------   ----------
    10000     spine N=16    infinite
    10001     N=17             3
    1001x     N=18 to 19       2
    101xx     N=20 to 23       1
    11xxx     N=24 to 31       0     leaf nodes

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
this path include

=over

L<http://oeis.org/A117625> (etc)

=back

    A164095     N start of each row, tree_depth_to_n()
                  being 5*2^k and 6*2^k alternately

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::UlamWarburton>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2013, 2014, 2015 Kevin Ryde

This file is part of Math-PlanePath-Toothpick.

Math-PlanePath-Toothpick is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option) any
later version.

Math-PlanePath-Toothpick is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
Math-PlanePath-Toothpick.  If not, see <http://www.gnu.org/licenses/>.

=cut
