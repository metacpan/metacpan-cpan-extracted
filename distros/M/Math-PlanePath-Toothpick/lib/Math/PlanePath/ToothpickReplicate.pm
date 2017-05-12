# Copyright 2012, 2013, 2014, 2015 Kevin Ryde

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

# block_order => 'AB123'
# block_order => 'A1B32' is depth first and finite parts first,
# in parts=1 where single infinite spine
#
# maybe tree methods same structure as ToothpickTree
#

# cf A175262 odd binary length and middle digit 1
#    A175263 odd binary length and middle digit 0
#

package Math::PlanePath::ToothpickReplicate;
use 5.004;
use strict;
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 18;
use Math::PlanePath;
@ISA = ('Math::PlanePath');


# return ($quotient, $remainder)
sub _divrem {
  my ($n, $d) = @_;
  if (ref $n && $n->isa('Math::BigInt')) {
    my ($quot,$rem) = $n->copy->bdiv($d);
    if (! ref $d || $d < 1_000_000) {
      $rem = $rem->numify;  # plain remainder if fits
    }
    return ($quot, $rem);
  }
  my $rem = $n % $d;
  return (int(($n-$rem)/$d), # exact division stays in UV
          $rem);
}


use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits 119  # v.119 for round_up_pow()
  'round_up_pow',
  'round_down_pow';

# uncomment this to run the ### lines
# use Smart::Comments;

use Math::PlanePath::ToothpickTree;
*new = \&Math::PlanePath::ToothpickTree::new;
*x_negative = \&Math::PlanePath::ToothpickTree::x_negative;
*y_negative = \&Math::PlanePath::ToothpickTree::y_negative;
*rect_to_n_range = \&Math::PlanePath::ToothpickTree::rect_to_n_range;
*x_minimum = \&Math::PlanePath::ToothpickTree::x_minimum;
*y_minimum = \&Math::PlanePath::ToothpickTree::y_minimum;
*sumxy_minimum    = \&Math::PlanePath::ToothpickTree::sumxy_minimum;
*sumabsxy_minimum = \&Math::PlanePath::ToothpickTree::sumabsxy_minimum;
*rsquared_minimum = \&Math::PlanePath::ToothpickTree::rsquared_minimum;

use constant parameter_info_array =>
  [ { name      => 'parts',
      share_key => 'parts_toothpickreplicate',
      display   => 'Parts',
      type      => 'enum',
      default   => '4',
      choices   => ['4','3','2','1'],
      choices_display => ['4','3','2','1'],
      description => 'Which parts of the pattern to generate.',
    },
  ];

use constant n_start => 0;
use constant class_x_negative => 1;
use constant class_y_negative => 1;

{
  my @x_negative_at_n = (undef,
                         undef,  # 1
                         3,      # 2
                         6,      # 3
                         5,      # 4
                        );
  sub x_negative_at_n {
    my ($self) = @_;
    return $x_negative_at_n[$self->{'parts'}];
  }
}
{
  my @y_negative_at_n = (undef,
                         undef,  # 1
                         undef,  # 2
                         2,      # 3
                         2,      # 4
                        );
  sub y_negative_at_n {
    my ($self) = @_;
    return $y_negative_at_n[$self->{'parts'}];
  }
}

# parts=1 same as parts=4
# parts=2 same as parts=4
# parts=3 same as parts=4
# parts=4    33,-12
#           133,-30
#           333,-112
#          1333,-230
#          3332,-1112    -> 3,-1
use constant dir_maximum_dxdy => (3,-1);

#------------------------------------------------------------------------------
# Fraction covered
# Xlevel = 2^(level+1) - 1
# Ylevel = 2^(level+1)
# Nend = (2*4^(level+1) + 1)/3 - 1
#
# Nend / (Xlevel*Ylevel)
#  -> ((2*4^(level+1) + 1)/3 - 1) / 4^(level+1)
#  -> (2*4^(level+1) + 1)/3 / 4^(level+1)
#  -> 2*4^(level+1)/3 / 4^(level+1)
#  -> 2/3

# Leading diagonal 1,3, 7,11,
#                  23,25,29,43,  +22,22,22,32
#                  87,89,93,97,  +86,86,86,86
#                  109,111,115,171,  +86,128
#                  343
# part2start = (4^level + 5)/3    = 3,7,23,87,343
# sums of part2start(level), but +2 in second half of each
# (3)/3=1
# (3+ 1+5)/3=3
# (3+ 1+5 + 4+5)/3=9


# v              v
# |      ->      |     part 3
# +---h      h---+
#
# +---v      h
# |      ->  |         part 1 rot then part 3
# h          +---v
#
#     v      v
#     |  ->  |         part 3 then part 3 again
# h---+      +---h
#

# v          +---v
# |      ->  |         part 1
# +---h      h
#
#     v      v---+
#     |  ->      |     part 3 then part 1 rot is +90
# h---+          h

# N = (2*4^level + 1)/3 + 1   is first of "level"
# 3N-3 = 2*4^level + 1
# 2*4^level = 3N-4
# 4^(level+1) = 6N-8
#
# part = (2*4^level - 2)/3  many points in "level"
# above = (2*4^(level+1) - 2)/3
#       = (4*2*4^level - 2)/3
#       = 4*(2*4^level - 2/4)/3
#       = 4*(2*4^level - 2)/3 + 4*(+ 2 - 2/4)/3
#       = 4*(2*4^level - 2)/3 + 2
#       = 4*part + 2
# part = (above-2)/4

my @quadrant_to_hdx = (1,-1, -1,1);
my @quadrant_to_vdy = (1, 1, -1,-1);

sub n_to_xy {
  my ($self, $n) = @_;
  ### ToothpickReplicate n_to_xy(): $n

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

  my $parts = $self->{'parts'};
  my $x = 0;
  my $y = 0;
  my $hdx = 1;
  my $hdy = 0;
  my $vdx = 0;
  my $vdy = 1;

  if ($parts eq '2') {
    if ($n == 0) {
      return (0,1);
    }

    # first of a replication level
    # Nlevel = 2*(2*4^level - 2)/3 + 1
    #        = (4*4^level - 4)/3 + 1
    #        = (4*4^level - 4 + 3)/3
    #        = (4*4^level - 1)/3     = 5,21
    # 3N = 4*4^level - 1
    # 4^(level+1) = 3N+1

    my ($len,$level) = round_down_pow(3*$n+1, 4);
    my $three_parts = $len/2;

    ### $len
    ### $level
    ### $three_parts
    ### start this level: ($len-1)/3
    ### n reduced: $n-($len-1)/3

    (my $quadrant, $n) = _divrem ($n-($len-1)/3, $three_parts);
    ### $quadrant
    ### n remainder: $n
    ### assert: $quadrant >= 0
    ### assert: $quadrant <= 1

    $n += ($len/2-2)/3;
    if ($quadrant) { $hdx = -1; }
    ### n in quarter: $n

  } elsif ($parts == 3) {
    if ($n <= 1) {
      return (0,$n);
    }
    # Nend = 3*(2*4^level - 2)/3 + 2
    #      = (2*4^level - 2) + 2
    #      = 2*4^level     = 2,8,32
    # N-1 = 2*4^level
    # 4^(level+1) = 2N-2

    my ($len,$level) = round_down_pow(2*$n, 4);
    my $three_parts = $len/2;

    ### $len
    ### $level
    ### $three_parts
    ### start this level: ($len/2+1)
    ### n reduced: $n-($len/2+1)

    (my $quadrant, $n) = _divrem ($n-$len/2, $three_parts);
    ### $quadrant
    ### n remainder: $n
    ### assert: $quadrant >= 0
    ### assert: $quadrant <= 2

    $n += ($len/2-2)/3;
    ### n in quarter: $n

    if ($quadrant == 0) {
      $hdx = 0;  # rotate -90
      $hdy = -1;
      $vdx = 1;
      $vdy = 0;
      $x = -1; # offset
    } elsif ($quadrant == 2) {
      $hdx = -1;  # mirror
    }

  } elsif ($parts == 4) {
    if ($n <= 2) {
      if ($n == 0) { return (0,0); }
      if ($n == 1) { return (0,1); }
      return (0,-1);  # N==2
    }
    # first of a replication level
    # Nlevel = 4*(2*4^level - 2)/3 + 3
    #        = (8*4^level - 8)/3 + 3
    #        = (8*4^level - 8 + 9)/3
    #        = (8*4^level+1)/3           11,43,171
    # 3N = 8*4^level+1
    # 8*4^level = 3N-1
    # 4^(level+2) = 6N-2
    #
    # first of this level, using level+2
    # Nlevel = (4^(level+2)/2+1)/3
    #        = (4^(level+2)+2)/6
    #
    # three count = 3*(2*4^level - 2)/3 + 2
    #             = 2*4^level
    # 43-11 = 32
    # 172-44 = 128

    # getting level+2 and len = 4^(level+2)
    my ($len,$level) = round_down_pow(6*$n-2, 4);
    my $three_parts = $len/8;

    ### all breakdown ...
    ### $level
    ### $len
    ### $three_parts
    ### Nlevel base: ($len+2)/6

    (my $quadrant, $n) = _divrem ($n-($len+2)/6, $three_parts);
    ### $quadrant
    ### n remainder: $n
    ### assert: $quadrant >= 0
    ### assert: $quadrant <= 3

    # quarter middle
    # Nquarter = (2*4^level - 2)/3  = 2,10,42
    $n += ($len/8-2)/3;
    $hdx = $quadrant_to_hdx[$quadrant];
    $vdy = $quadrant_to_vdy[$quadrant];
    ### n in quarter: $n
  }

  # quarter first of a replication level
  # Nlevel = 4*(2*4^level - 2)/3 + 2
  #        = (8*4^level - 8)/3 + 2
  #        = (8*4^level - 8 + 6)/3
  #        = (8*4^level - 2)/3           2,10,42
  # 3N = 8*4^level-2
  # 8*4^level = 3N+2
  # 4^(level+2) = 6N+4
  #
  # using level+1
  # Nlevel = (8*4^level - 2)/3
  #        = (2*4^(level+1) - 2)/3


  # getting level+2 and 16*len
  my ($len,$level) = round_down_pow(6*$n+4, 4);
  my $part_n = (2*$len-2)/3;
  ### $level
  ### $part_n

  $len = 2**$level;
  for ( ;
        $level-- >= 0;
        $len /= 2,  $part_n = ($part_n-2)/4) {

    ### at: "x=$x,y=$y level=$level hxy=$hdx,$hdy vxy=$vdx,$vdy   n=$n"
    ### $len
    ### $part_n
    ### assert: $len == 2 ** ($level+1)
    ### assert: $part_n == (2 * 4 ** ($level+1) - 2)/3

    if ($n < $part_n) {
      ### part 0, no change ...
      next;
    }

    $n -= $part_n;
    $x += $len * ($hdx + $vdx);  # diagonal
    $y += $len * ($hdy + $vdy);

    if ($n == 0) {
      ### toothpick A ...
      last;
    }
    if ($n == 1) {
      ### toothpick B ...
      $x += $vdx;
      $y += $vdy;
      last;
    }
    $n -= 2;

    if ($n < $part_n) {
      ### part 1, rotate ...
      $x -= $hdx; # offset
      $y -= $hdy;
      ($hdx,$hdy, $vdx,$vdy)    # rotate 90 in direction v toward h
        = (-$vdx,-$vdy, $hdx,$hdy);
      next;
    }
    $n -= $part_n;

    if ($n < $part_n) {
      ### part 2 ...
      next;
    }
    $n -= $part_n;

    ### part 3, mirror ...
    $hdx = -$hdx;
    $hdy = -$hdy;
  }

  ### assert: $n == 0 || $n == 1

  ### final: "x=$x y=$y"
  return ($x,$y);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### ToothpickReplicate xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);

  my $parts = $self->{'parts'};
  my $rotated = ($parts == 3 && $x >= 0 && $y < 0);
  if ($rotated) {
    ($x,$y) = (-$y,$x+1);  # rotate +90 and shift up
    ### rotated: "x=$x y=$y"
  }

  my ($len,$level) = round_down_pow (max(abs($x), abs($y)-1),
                                     2);
  if (is_infinite($level)) {
    return $level;
  }
  ### $level
  ### $len

  my $zero = $x * 0 * $y;
  my $n = $zero;

  if ($parts == 2) {
    if ($x == 0) {
      if ($y == 1) { return 0; }
    }
    $n += (2*$len*$len+1)/3;   # +1,+3,+11,+43
    if ($x < 0) {
      $x = -$x;
      $n += 2*$len*$len;  # second quad, +2,+8,+32
    }

  } elsif ($parts == 3) {
    ### 3/4 ...
    if ($x == 0) {
      if ($y == 0) { return 0; }
      if ($y == 1) { return 1; }
    }
    $n += (10*$len*$len+2)/3;   # +4,+14,+54,+214,+854,+3414
    if ($rotated) {
      $n -= 2*$len*$len;  # fourth quad, -2, -8, -32
    } elsif ($x < 0) {
      $x = -$x;
      if ($y > 0) {
        $n += 2*$len*$len;  # second quad, +2, +8, +32
      } else {
        return undef;  # third quad, empty
      }
    }
  } elsif ($parts == 4) {
    if ($x == 0) {
      if ($y == 0)  { return 0; }
      if ($y == 1)  { return 1; }
      if ($y == -1) { return 2; }
    }
    $n += (2*$len*$len+1);
    if ($x < 0) {
      $x = -$x;
      if ($y > 0) {
        $n += 2*$len*$len;  # second quad, +2, +8, +32
      } else {
        $n += 4*$len*$len;  # third quad, +4,+16
        $y = -$y;
      }
    } else {
      if ($y < 0) {
        $n += 6*$len*$len;  # fourth quad
        $y = -$y;
      }
    }
  }

  #                              2^(level+1)-1
  #                              v
  #          +-----------+---------+
  #          |           |         | <- 2^(level+1)
  #          |   3             2   |
  #          | mirror        same  |
  #          |         --B--       | <- 2^level + 1
  #          |           |         |
  #          +--         A       --+ <- 2^level
  #                      |         |
  #                          1     |
  #                         rot    |
  #             0           +90    |
  #                    |           |
  #                    +-----------+
  #                      ^
  #                     2^level

  my $part_n = (2*$len*$len - 2) / 3;
  ### $part_n

  while ($level-- > 0) {
    ### at: "x=$x,y=$y  len=$len part_n=$part_n   n=$n"
    ### assert: $len == 2 ** ($level+1)
    ### assert: $part_n == (2 * 4 ** ($level+1) - 2)/3

    if ($x == $len) {
      if ($y == $len) {
        ### toothpick A ...
        return $n + $part_n;
      }
      if ($y == $len+1) {
        ### toothpick B ...
        return $n + $part_n + 1;
      }
    }

    if ($y <= $len) {
      if ($x < $len) {
        ### part 0 ...
      } else {
        ### part 1, rotate ...
        $n += $part_n + 2;
        ($x,$y) = ($len-$y,$x-$len+1); # shift, rotate +90
      }
    } else {
      $y -= $len;
      if ($x > $len) {
        ### part 2 ...
        $n += 2*$part_n + 2;
        $x -= $len;
      } else {
        ### part 3 ...
        $n += 3*$part_n + 2;
        $x = $len-$x; # mirror
      }
    }

    $len /= 2;
    $part_n = ($part_n-2)/4;
  }

  ### end loop: "x=$x y=$y   n=$n"

  if ($x == 1) {
    if ($y == 1) {
      return $n;
    } elsif ($y == 2) {
      return $n + 1;
    }
  }

  return undef;
}

#------------------------------------------------------------------------------
# levels

# parts=1
# LevelPoints[k] = 4*LevelPoints[k] + 2  starting LevelPoints[0] = 2
# LevelPoints[k] = 2 + 2*4 + 2*4^2 + ... + 2*4^(k-1) + 4^k*LevelPoints[0]
# LevelPoints[k] = 2 + 2*4 + 2*4^2 + ... + 2*4^(k-1) + 2*4^k
# LevelPoints[k] = 2*(4^(k+1) - 1)/3

{
  my %level_to_n_range = (4 => -2,
                          3 => -3,
                          2 => -4,
                          1 => -5,
                         );
  sub level_to_n_range {
    my ($self, $level) = @_;
    return (0,
            (4**($level+1) * (2*$self->{'parts'})
             + $level_to_n_range{$self->{'parts'}}) / 3);
  }
}
{
  # $level_to_n_range{} and _divrem_mutate() rounded up
  my %n_to_level = (4 => 2 + 2*4-1,
                    3 => 3 + 2*3-1,
                    2 => 4 + 2*2-1,
                    1 => 5 + 2-1,
                   );
  sub n_to_level {
    my ($self, $n) = @_;
    if ($n < 0) { return undef; }
    if (is_infinite($n)) { return $n; }
    $n = round_nearest($n);
    $n *= 3;
    $n += $n_to_level{$self->{'parts'}};
    _divrem_mutate ($n, 2*$self->{'parts'});
    my ($pow, $exp) = round_down_pow ($n-1, 4);
    return $exp;
  }
}

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

#------------------------------------------------------------------------------
1;
__END__

=for stopwords eg Ryde Math-PlanePath-Toothpick OEIS

=head1 NAME

Math::PlanePath::ToothpickReplicate -- toothpick pattern by replication

=head1 SYNOPSIS

 use Math::PlanePath::ToothpickReplicate;
 my $path = Math::PlanePath::ToothpickReplicate->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This is the "toothpick" pattern of the C<ToothpickTree> path numbered as a
self-similar replicating pattern.

=cut

# math-image --path=ToothpickReplicate --all --output=numbers --size=60x10

=pod

                                   ...
                                    |
    ..-24--  --26--  --18--  --16--43         4
        |       |       |       |   |
       23--20--25      17--12--15  ...        3
        |   |               |   |
           19---6--  ---4--11                 2
        |   |   |       |   |   |
       22--21-  5---1---3 -13--14             1
        |       |   |   |       |
                    0                    <- Y=0
        |       |   |   |       |
       30--29-  7---2---9 -37--38            -1
        |   |   |       |   |   |
           27---8--  --10--35                -2
        |   |               |   |
       31--28--33      41--36--39            -3
        |       |       |       |
    ..-32--  --34--  --42--  --40--..        -4

                    ^
       -3  -2  -1  X=0  1   2   3   4

=head2 One Quadrant

Option C<parts =E<gt> 1> selects a single quadrant of replications.

=cut

# math-image --path=ToothpickReplicate,parts=1 --all --output=numbers --size=80x50

=pod

        |                               ...
        |                                |
      8 | --39--  --41--  --31--  --29--42
        |    |       |       |       |   |
      7 |   38--35--40      30--25--28  ...
        |    |   |               |   |
      6 |       34--33--  --23--24
        |    |   |   |       |   |   |
      5 |   37--36- 32--11--22 -26--27
        |                |   |       |
      4 | ---9--  ---7--10
        |    |       |   |   |       |
      3 |    8---3---6 -12--13  20--21
        |        |   |       |   |   |
      2 | ---1---2      16--14--15
        |    |   |   |   |       |   |
      1 |    0 --4---5  17    --18--19
        |    |       |               |
    Y=0 |
        +-----------------------------------
        X=0  1   2   3   4   5   6   7   8

=head2 Replication

The points visited are the same as L<Math::PlanePath::ToothpickTree>, but in
a self-similar order.  The pattern within each quarter repeats at 2^level
size blocks.

    +------------+------------+
    |            |            |
    |  block 3       block 2  |
    |   mirror        same    |
    |                         |
    |          --B--          |
    |            |            |
    +----------  A         ---+
    |            |            |
    |  block 0       block 1  |
    |            |   rot +90  |
    |            |            |
    |            |            |
    +------------+------------+

In the parts=1 above (L</One Quadrant>),

    N=1 to N=10     "0" block
    N=11            "A" middle point
    N=12            "B" middle point
    N=13 to N=22    "1" block, rotated +90 degrees
    N=23 to N=32    "2" block, same layout as the "0" block
    N=33 to N=42    "3" block, mirror image of "0" block

The very first points N=1 and N=2 are effectively the "A" and "B" middle
toothpicks with no points at all for the 0,1,2,3 sub-blocks.

The full parts=4 form (the default) is four quarters, each advancing by a
replication level each time.

The initial N=0,1,2 make the centre, and then each quadrant is extended in
turn by blocks.

    +------------+------------A
    |            |            |
    |  block 3       block 2  |      in each quadrant
    |   mirror        same    |
    |     ^            ^      |
    |      \   --B--  /       |
    |       \    |   /        |
    +----------  A         ---+
    |            |            |
    |  block 0       block 1  |
    |     ^      |  \ rot +90 |
    |    /       |   \        |
    |   /        |    v       |
    +------------+------------+

Block 0 is the existing part.  Then toothpick A and B are counted, followed
by replications of block 0 in blocks 1,2,3.  For example in the first
quadrant

    N=11      toothpick "A"
    N=12      toothpick "B"
    N=13,14   block 1 \
    N=15,16   block 2 |  replicating block 0 N=3,N=4
    N=17,18   block 3 /

Each such replication doubles the size in a quadrant, so the "A" toothpick
is on a power-of-2 X=2^k,Y=2^k.  For example N=11 at X=2,Y=2 and N=43 at
X=4,Y=4.

=head2 Half Plane

Option C<parts =E<gt> 2> confines the pattern to the upper half plane
C<YE<gt>=1>, giving two symmetric parts above the X axis.  N=0 at X=0,Y=1 is
the first toothpick of the full pattern which is wholly within this half
plane.

=cut

# math-image --path=ToothpickReplicate,parts=2 --all --output=numbers --size=80x12

=pod

     ...                             ...          5
      |                               |
     53--18--  --20--  --12--  --10--21           4
      |   |       |       |       |   |
     ... 17--14--19      11---6---9  ...          3
          |   |               |   |
             13---4--  ---2---5                   2
          |   |   |       |   |   |
         16--15-  3---0---1 --7---8               1
          |       |       |       |
                                             <- Y=0
    ------------------------------------
                      ^
     -4   -3 -2  -1  X=0  1   2   3   4

=head2 Three Parts

Option C<parts =E<gt> 3> is the three replications which occur from an
X=2^k,Y=2^k point, but continued on indefinitely confined to the upper and
right three quadrants.

=cut

# math-image --path=ToothpickReplicate,parts=3 --all --output=numbers --size=80x16

=pod
                                                                              
    ..--29--  --31--  --23--  --21--..          4
         |       |       |       |
        28--25--30      22--17--20              3
         |   |               |   |
            24---7--  ---5--16                  2
         |   |   |       |   |   |
        27--26-  6---1---4 -18--19              1
         |       |   |   |       |
                     0                     <- Y=0
                     |   |       |
                   --2---3 -14--15             -1
                         |   |   |
                    10---8---9                 -2
                     |       |   |
                  --11--  --12--13             -3
                                 |
                                ...            -4
                     ^
    -4  -3  -2  -1  X=0  1   2   3   4

N=1,4,5,6,7,16,etc above the X axis have an odd number of bits when written
in binary.  For example N=6 is binary "110" which is 3 digits.  Conversely
N=0,2,3,8,etc below the X axis have an even number of digits.  For example
N=8 is "1000" which is 4 digits.

   odd bit       odd bit
   length     |  length     
              |
     "11"     |  "10"            high two bits of N,
              |                  at odd bit position
    ----------+----------
              |
              |  "01" 
              |
              |  even bit length

This occurs because each quadrant contains (4^k-1)*2/3 many points on each
doubling.  Three of them plus A and B make 3*(4^k-1)*2/3+2 = 2*4^k at each
doubling, so with the origin as N=0 each replication level starts

    Nlevel_start = 2*4^k
    Nlast_below  = 2*4^k + 3*(4^k-1)*2/3+2 - 1
                 = 2*4^k + 2*4^k-1

=cut

# 4^k + 3*(4^k-1)*2/3+2 - 1
#  = 4^k + (4^k-1)*2+2 - 1
#  =  4^k + 2*4^k-2+2 - 1
#  =  4^k + 2*4^k - 1

=pod

For example k=1 has Nlevel_start = 2*4^1 = 8 and runs through to Nlast_below
= 2*4^1 + 2*4^1-1 = 15.  In binary this is "1000" through "1111" which are
all length 4.  The first quadrant then runs 32 to 47 which is binary "10000"
to 101111", and the second quadrant 48 to 63 "110000" to "111111".

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::ToothpickReplicate-E<gt>new ()>

=item C<$path = Math::PlanePath::ToothpickTree-E<gt>new (parts =E<gt> $integer)>

Create and return a new path object.  C<parts> can be

    4    whole plane (the default)
    3    three quadrants
    2    half plane
    1    quadrant

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<$n_lo = 0> and

    parts    $n_hi
    -----    -----
      4      (4*8 * 4**$level - 2) / 3
      3      (3*8 * 4**$level - 3) / 3
      2      (2*8 * 4**$level - 4) / 3
      1      (  8 * 4**$level - 5) / 3

=for Test-Pari-DEFINE  Level4(k) = (4*8 * 4^k - 2)/3

=for Test-Pari-DEFINE  Level3(k) = (3*8 * 4^k - 3)/3

=for Test-Pari-DEFINE  Level2(k) = (2*8 * 4^k - 4)/3

=for Test-Pari-DEFINE  Level1(k) = (  8 * 4^k - 5)/3

=for Test-Pari  Level4(0) == 10

=for Test-Pari  Level4(1) == 42

=for Test-Pari  Level1(0) == 1

=for Test-Pari  Level1(1) == 9

=for Test-Pari  Level1(2) == 41

=for Test-Pari  Level2(0) == 4

=for Test-Pari  Level2(1) == 20

=for Test-Pari  Level3(0) == 7

=for Test-Pari  Level3(1) == 31

It can be noted that parts=3 finishes one N point sooner than the
corresponding parts=3 pattern of the C<ToothpickTree> form.  This is because
the Replicate form here finishes the upper quadrants before continuing the
lower quadrant, whereas C<ToothpickTree> is by rows so continues to grow the
lower quadrant at the same time as the last row of the upper two quadrants.
That lower quadrant growth is a single point.

=back

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to this
path include

=over

L<http://oeis.org/A053738> (etc)

=back

    parts=3
      A053738   N of points with Y>0, being odd bit length
                 also N of parts=3 when taking X,Y points by parts=2 order
      A053754   N of points with Y<=0, being even bit length

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::ToothpickTree>,
L<Math::PlanePath::LCornerReplicate>,
L<Math::PlanePath::UlamWarburton>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014, 2015 Kevin Ryde

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
