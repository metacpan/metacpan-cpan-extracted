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


package Math::PlanePath::SierpinskiCurve;
use 5.004;
use strict;
use List::Util 'sum','first';
#use List::Util 'min','max';
*min = \&Math::PlanePath::_min;
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 125;
use Math::PlanePath;
@ISA = ('Math::PlanePath');
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_up_pow',
  'round_down_pow',
  'digit_split_lowtohigh';

# uncomment this to run the ### lines
# use Smart::Comments;


use constant n_start => 0;

sub x_negative {
  my ($self) = @_;
  return ($self->{'arms'} >= 3);
}
sub y_negative {
  my ($self) = @_;
  return ($self->{'arms'} >= 5);
}

use constant parameter_info_array =>
  [
   { name        => 'arms',
     share_key   => 'arms_8',
     display     => 'Arms',
     type        => 'integer',
     minimum     => 1,
     maximum     => 8,
     default     => 1,
     width       => 1,
     description => 'Arms',
   },

   { name        => 'straight_spacing',
     display     => 'Straight Spacing',
     type        => 'integer',
     minimum     => 1,
     default     => 1,
     width       => 1,
     description => 'Spacing of the straight line points.',
   },
   { name        => 'diagonal_spacing',
     display     => 'Diagonal Spacing',
     type        => 'integer',
     minimum     => 1,
     default     => 1,
     width       => 1,
     description => 'Spacing of the diagonal points.',
   },
  ];

# Ntop = (4^level)/2 - 1
# Xtop = 3*2^(level-1) - 1
# fill = Ntop / (Xtop*(Xtop-1)/2)
#      -> 2 * ((4^level)/2 - 1) / (3*2^(level-1) - 1)^2
#      -> 2 * ((4^level)/2) / (3*2^(level-1))^2
#      =  4^level / (9*4^(level-1)
#      =  4/9 = 0.444

sub x_negative_at_n {
  my ($self) = @_;
  return $self->arms_count >= 3 ? 2 : undef;
}
sub y_negative_at_n {
  my ($self) = @_;
  return $self->arms_count >= 5 ? 4 : undef;
}

{
  # Note: shared by Math::PlanePath::SierpinskiCurveStair
  my @x_minimum = (undef,
                   1,  # 1 arm
                   0,  # 2 arms
                  );   # more than 2 arm, X goes negative
  sub x_minimum {
    my ($self) = @_;
    return $x_minimum[$self->arms_count];
  }
}
{
  # Note: shared by Math::PlanePath::SierpinskiCurveStair
  my @sumxy_minimum = (undef,
                       1,  # 1 arm, octant and X>=1 so X+Y>=1
                       1,  # 2 arms, X>=1 or Y>=1 so X+Y>=1
                       0,  # 3 arms, Y>=1 and X>=Y, so X+Y>=0
                      );   # more than 3 arm, Sum goes negative so undef
  sub sumxy_minimum {
    my ($self) = @_;
    return $sumxy_minimum[$self->arms_count];
  }
}
use constant sumabsxy_minimum => 1;

# Note: shared by Math::PlanePath::SierpinskiCurveStair
#                 Math::PlanePath::AlternatePaper
#                 Math::PlanePath::AlternatePaperMidpoint
sub diffxy_minimum {
  my ($self) = @_;
  return ($self->arms_count == 1
          ? 1       # octant Y<=X-1 so X-Y>=1
          : undef); # more than 1 arm, DiffXY goes negative
}
use constant absdiffxy_minimum => 1; # X=Y never occurs
use constant rsquared_minimum => 1; # minimum X=1,Y=0

sub dx_minimum {
  my ($self) = @_;
  return - max($self->{'straight_spacing'},
               $self->{'diagonal_spacing'});
}
*dy_minimum = \&dx_minimum;

sub dx_maximum {
  my ($self) = @_;
  return max($self->{'straight_spacing'},
             $self->{'diagonal_spacing'});
}
*dy_maximum = \&dx_maximum;

sub _UNDOCUMENTED__dxdy_list {
  my ($self) = @_;
  my $s = $self->{'straight_spacing'};
  my $d = $self->{'diagonal_spacing'};
  return ($s,0,                    # E     eight scaled
          ($d ? ( $d, $d) : ()),   # NE    except s=0
          ($s ? (  0, $s) : ()),   # N     or d=0 skips
          ($d ? (-$d, $d) : ()),   # NW
          ($s ? (-$s,  0) : ()),   # W
          ($d ? (-$d,-$d) : ()),   # SW
          ($s ? (  0,-$s) : ()),   # S
          ($d ? ( $d,-$d) : ()));  # SE

}
{
  my @_UNDOCUMENTED__dxdy_list_at_n = (undef,
                                       21, 20, 27, 36,
                                       29, 12, 12, 13);
  sub _UNDOCUMENTED__dxdy_list_at_n {
    my ($self) = @_;
    return $_UNDOCUMENTED__dxdy_list_at_n[$self->{'arms'}];
  }
}
sub dsumxy_minimum {
  my ($self) = @_;
  return - max($self->{'straight_spacing'},
               2*$self->{'diagonal_spacing'});
}
sub dsumxy_maximum {
  my ($self) = @_;
  return max($self->{'straight_spacing'},
             2*$self->{'diagonal_spacing'});
}
*ddiffxy_minimum = \&dsumxy_minimum;
*ddiffxy_maximum = \&dsumxy_maximum;

use constant dir_maximum_dxdy => (1,-1); # South-East
use constant turn_any_straight => 0; # never straight


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);

  $self->{'arms'} = max(1, min(8, $self->{'arms'} || 1));
  $self->{'straight_spacing'} ||= 1;
  $self->{'diagonal_spacing'} ||= 1;
  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### SierpinskiCurve n_to_xy(): $n

  if ($n < 0) {
    return;
  }
  if (is_infinite($n)) {
    return ($n,$n);
  }

  my $int = int($n); # BigFloat int() gives BigInt, use that
  $n -= $int;   # preserve possible BigFloat
  ### $int
  ### $n

  my $arm = _divrem_mutate ($int, $self->{'arms'});

  my $s = $self->{'straight_spacing'};
  my $d = $self->{'diagonal_spacing'};
  my $base = 2*$d+$s;
  my $x = my $y = ($int * 0);  # inherit big 0
  my $len = $x + $base;      # inherit big

  foreach my $digit (digit_split_lowtohigh($int,4)) {
    ### at: "$x,$y  digit=$digit"

    if ($digit == 0) {
      $x = $n*$d + $x;
      $y = $n*$d + $y;
      $n = 0;

    } elsif ($digit == 1) {
      ($x,$y) = ($n*$s - $y + $len-$d-$s,   # rotate +90
                 $x + $d);
      $n = 0;

    } elsif ($digit == 2) {
      # rotate -90
      ($x,$y) = ($n*$d + $y  + $len-$d,
                 -$n*$d - $x + $len-$d-$s);
      $n = 0;

    } else { # digit==3
      $x += $len;
    }
    $len *= 2;
  }

  # n=0 or n=33..33
  $x = $n*$d + $x;
  $y = $n*$d + $y;

  $x += 1;
  if ($arm & 1) {
    ($x,$y) = ($y,$x);   # mirror 45
  }
  if ($arm & 2) {
    ($x,$y) = (-1-$y,$x);   # rotate +90
  }
  if ($arm & 4) {
    $x = -1-$x;   # rotate 180
    $y = -1-$y;
  }

  # use POSIX 'floor';
  # $x += floor($x/3);
  # $y += floor($y/3);

  # $x += floor(($x-1)/3) + floor(($x-2)/3);
  # $y += floor(($y-1)/3) + floor(($y-2)/3);


  ### final: "$x,$y"
  return ($x,$y);
}

my @digit_to_dir = (0, -2, 2, 0);
my @dir8_to_dx = (1, 1, 0,-1, -1, -1,  0, 1);
my @dir8_to_dy = (0, 1, 1, 1,  0, -1, -1,-1);
my @digit_to_nextturn = (-1,   # after digit=0
                         2,    #       digit=1
                         -1);  #       digit=2
sub n_to_dxdy {
  my ($self, $n) = @_;
  ### n_to_dxdy(): $n

  if ($n < 0) {
    return;  # first direction at N=0
  }

  my $int = int($n);
  $n -= $int;

  my $arm = _divrem_mutate($int,$self->{'arms'});
  my $lowbit = _divrem_mutate($int,2);
  ### $lowbit
  ### $int

  if (is_infinite($int)) {
    return ($int,$int);
  }
  my @ndigits = digit_split_lowtohigh($int,4);
  ### @ndigits

  my $dir8 = sum(0, map {$digit_to_dir[$_]} @ndigits);
  if ($arm & 1) {
    $dir8 = - $dir8;  # mirrored on second,fourth,etc arm
  }
  $dir8 += ($arm|1);  # NE,NW,SW, or SE

  my $turn;
  if ($n || $lowbit) {
    # next turn

    # lowest non-3 digit, or zero if all 3s (implicit 0 above high digit)
    $turn = $digit_to_nextturn[ first {$_!=3} @ndigits, 0 ];
    if ($arm & 1) {
      $turn = - $turn;  # mirrored on second,fourth,etc arm
    }
  }

  if ($lowbit) {
    $dir8 += $turn;
  }

  my $s = $self->{'straight_spacing'};
  my $d = $self->{'diagonal_spacing'};

  $dir8 &= 7;
  my $spacing = ($dir8 & 1 ? $d : $s);
  my $dx = $spacing * $dir8_to_dx[$dir8];
  my $dy = $spacing * $dir8_to_dy[$dir8];

  if ($n) {
    $dir8 += $turn;
    $dir8 &= 7;
    $spacing = ($dir8 & 1 ? $d : $s);
    $dx += $n*($spacing * $dir8_to_dx[$dir8]
               - $dx);
    $dy += $n*($spacing * $dir8_to_dy[$dir8]
               - $dy);
  }

  return ($dx, $dy);
}

# 2| . 3 .
# 1| 1 . 2
# 0| . 0 .
#  +------
#    0 1 2
#
# 4| . . . 3 .          # diagonal_spacing == 3
# 3| . . . . 2 4        # mod=2*3+1=7
# 2| . . . . . . .
# 1| 1 . . . . . . .
# 0| . 0 . . . . . . 6
#  +------------------
#    0 1 2 3 4 5 6 7 8
#
sub _NOTWORKING__xy_is_visited {
  my ($self, $x, $y) = @_;
  $x = round_nearest($x);
  $y = round_nearest($y);
  my $mod = 2*$self->{'diagonal_spacing'} + $self->{'straight_spacing'};
  return (_rect_within_arms($x,$y, $x,$y, $self->{'arms'})
          && ((($x%$mod)+($y%$mod)) & 1));
}

#   x1    *  x2 *
#    +-----*-+y2*
#    |      *|  *
#    |       *  *
#    |       |* *
#    |       | **
#    +-------+y1*
#   ----------------
#
# arms=5 x1,y2 after X=Y-1 line, so x1 > y2-1, x1 >= y2
# ************
#      x1   *   x2
#      +---*----+y2
#      |  *     |
#      | *      |
#      |*       |
#      *        |
#     *+--------+y1
#    *
#
# arms=7 x1,y1 after X=-2-Y line, so x1 > -2-y1
# ************
# ** +------+
# * *|      |
# *  *      |
# *  |*     |
# *  | *    |
# *y1+--*---+
# * x1   *
#
# _rect_within_arms() returns true if rectangle x1,y1,x2,y2 has some part
# within the extent of the $arms set of octants.
#
sub _rect_within_arms {
  my ($x1,$y1, $x2,$y2, $arms) = @_;
  return ($arms <= 4
          ? ($y2 >= 0  # y2 top edge must be positive
             && ($arms <= 2
                 ? ($arms == 1 ? $x2 > $y1   # arms==1  bottom right
                    :            $x2 >= 0)   # arms==2  right edge
                 : ($arms == 4               # arms==4  anything
                    || $x2 >= -$y2)))        # arms==3  top right

          # arms >= 5
          : ($y2 >= 0  # y2 top edge positive is good, otherwise check
             || ($arms <= 6
                 ? ($arms == 5 ? $x1 < $y2   # arms==5  top left
                    :            $x1 < 0)    # arms==6  left edge
                 : ($arms == 8               # arms==8  anything
                    || $x1 <= -2-$y1))));    # arms==7  bottom left
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### SierpinskiCurve xy_to_n(): "$x, $y"

  $x = round_nearest($x);
  $y = round_nearest($y);

  my $arm = 0;
  if ($y < 0) {
    $arm = 4;
    $x = -1-$x;  # rotate -180
    $y = -1-$y;
  }
  if ($x < 0) {
    $arm += 2;
    ($x,$y) = ($y, -1-$x);  # rotate -90
  }
  if ($y > $x) {       # second octant
    $arm++;
    ($x,$y) = ($y,$x); # mirror 45
  }

  my $arms = $self->{'arms'};
  if ($arm >= $arms) {
    return undef;
  }

  $x -= 1;
  if ($x < 0 || $x < $y) {
    return undef;
  }
  ### x adjust to zero: "$x,$y"
  ### assert: $x >= 0
  ### assert: $y >= 0

  my $s = $self->{'straight_spacing'};
  my $d = $self->{'diagonal_spacing'};
  my $base = (2*$d+$s);
  my ($len,$level) = round_down_pow (($x+$y)/$base || 1,  2);
  ### $level
  ### $len
  if (is_infinite($level)) {
    return $level;
  }

  # Xtop = 3*2^(level-1)-1
  #
  $len *= 2*$base;
  ### initial len: $len

  my $n = 0;
  foreach (0 .. $level) {
    $n *= 4;
    ### at: "loop=$_ len=$len   x=$x,y=$y  n=$n"
    ### assert: $x >= 0
    ### assert: $y >= 0

    my $len_sub_d = $len - $d;
    if ($x < $len_sub_d) {
      ### digit 0 or 1...
      if ($x+$y+$s < $len) {
        ### digit 0 ...
      } else {
        ### digit 1 ...
        ($x,$y) = ($y-$d, $len-$s-$d-$x);   # shift then rotate -90
        $n += 1;
      }
    } else {
      $x -= $len_sub_d;
      ### digit 2 or 3 to: "x=$x y=$y"
      if ($x < $y) {   # before diagonal
        ### digit 2...
        ($x,$y) = ($len-$d-$s-$y, $x);     # shift y-len then rotate +90
        $n += 2;
      } else {
        #### digit 3...
        $x -= $d;
        $n += 3;
      }
      if ($x < 0) {
        return undef;
      }
    }
    $len /= 2;
  }

  ### end at: "x=$x,y=$y   n=$n"
  ### assert: $x >= 0
  ### assert: $y >= 0

  $n *= 4;
  if ($y == 0 && $x == 0) {
    ### final digit 0 ...
  } elsif ($x == $d && $y == $d) {
    ### final digit 1 ...
    $n += 1;
  } elsif ($x == $d+$s && $y == $d) {
    ### final digit 2 ...
    $n += 2;
  } elsif ($x == $base && $y == 0) {
    ### final digit 3 ...
    $n += 3;
  } else {
    return undef;
  }

  return $n*$arms + $arm;
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### SierpinskiCurve rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest ($x1);
  $x2 = round_nearest ($x2);
  $y1 = round_nearest ($y1);
  $y2 = round_nearest ($y2);
  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;

  my $arms = $self->{'arms'};
  unless (_rect_within_arms($x1,$y1, $x2,$y2, $arms)) {
    ### rect outside octants, for arms: $arms
    return (1,0);
  }

  my $max = ($x2 + $y2);
  if ($arms >= 3) {
    _apply_max ($max, -1-$x1 + $y2);

    if ($arms >= 5) {
      _apply_max ($max, -1-$x1 - $y1-1);

      if ($arms >= 7) {
        _apply_max ($max, $x2 - $y1-1);
      }
    }
  }

  # base=2d+s
  # level begins at
  #   base*(2^level-1)-s = X+Y     ... maybe
  #   base*2^level = X+base
  #   2^level = (X+base)/base
  #   level = log2((X+base)/base)
  # then
  #   Nlevel = 4^level-1

  my $base = 2 * $self->{'diagonal_spacing'} + $self->{'straight_spacing'};
  my ($power) = round_down_pow (int(($max+$base-2)/$base),
                                2);
  return (0, 4*$power*$power * $arms - 1);
}

sub _apply_max {
  ### _apply_max(): "$_[0] cf $_[1]"
  unless ($_[0] > $_[1]) {
    $_[0] = $_[1];
  }
}

#------------------------------------------------------------------------------

sub level_to_n_range {
  my ($self, $level) = @_;
  return (0,  4**$level * $self->{'arms'} - 1);
}
sub n_to_level {
  my ($self, $n) = @_;
  if ($n < 0) { return undef; }
  if (is_infinite($n)) { return $n; }
  $n = round_nearest($n);
  _divrem_mutate ($n, $self->{'arms'});
  my ($pow, $exp) = round_up_pow ($n+1, 4);
  return $exp;
}

#------------------------------------------------------------------------------
1;
__END__



# #      ...0    ...1
# #      ...1    ...2
# #      ...2    ...3
# #    ..0333  ..1000    any low 3s
# #      ..02    ..03
# #      ..12    ..13
# #      ..22    ..23
# #   ..03332 ..03333
# #   ..13332 ..13333
# #   ..23332 ..23333
#
# my @lowdigit_to_dir = (1,-2, 1, 0);
# my @digit_to_dir    = (0, 2,-2, 0);
# my @dir8_to_dx = (1, 1, 0,-1, -1, -1,  0, 1);
# my @dir8_to_dy = (0, 1, 1, 1,  0, -1, -1,-1);
# my @digit_to_nextturn  = (-1,-1,2);
# my @digit_to_nextturn2 = (2,-1,2);
#
# sub _WORKING_BUT_HAIRY__n_to_dxdy {
#   my ($self, $n) = @_;
#   ### n_to_dxdy(): $n
#
#   if ($n < 0) {
#     return;  # first direction at N=0
#   }
#   if (is_infinite($n)) {
#     return ($n,$n);
#   }
#
#   my $int = int($n);
#   $n -= $int;
#   my @digits = digit_split_lowtohigh($int,4);
#   ### @digits
#
#   # strip low 3s
#   my $any_low3s;
#   while (($digits[0]||0) == 3) {
#     shift @digits;
#     $any_low3s = 1;
#   }
#
#   my $dir8 = $lowdigit_to_dir[$digits[0] || 0];
#   $dir8 += sum(0, map {$digit_to_dir[$_]} @digits);
#   $dir8 &= 7;
#   my $dx = $dir8_to_dx[$dir8];
#   my $dy = $dir8_to_dy[$dir8];
#
#   if ($n) {
#     # fraction part
#
#     if ($any_low3s) {
#       $dir8 += $digit_to_nextturn2[$digits[0]||0];
#     } else {
#       my $digit = $digits[0] || 0;
#       if ($digit == 2) {
#         shift @digits;
#         # lowest non-3 digit
#         do {
#           $digit = shift @digits || 0;  # zero if all 3s or no digits at all
#         } until ($digit != 3);
#         $dir8 += $digit_to_nextturn2[$digit];
#       } else {
#         $dir8 += $digit_to_nextturn[$digit];
#       }
#     }
#     $dir8 &= 7;
#     $dx += $n*($dir8_to_dx[$dir8] - $dx);
#     $dy += $n*($dir8_to_dy[$dir8] - $dy);
#   }
#   return ($dx, $dy);
# }





   #                                              63-64            14
   #                                               |  |
   #                                              62 65            13
   #                                             /     \
   #                                        60-61       66-67      12
   #                                         |              |
   #                                        59-58       69-68      11
   #                                             \     /
   #                                  51-52       57 70            10
   #                                   |  |        |  |
   #                                  50 53       56 71       ...   9
   #                                 /     \     /     \     /
   #                            48-49       54-55       72-73       8
   #                             |
   #                            47-46       41-40                   7
   #                                 \     /     \
   #                      15-16       45 42       39                6
   #                       |  |        |  |        |
   #                      14 17       44-43       38                5
   #                     /     \                 /
   #                12-13       18-19       36-37                   4
   #                 |              |        |
   #                11-10       21-20       35-34                   3
   #                     \     /                 \
   #           3--4        9 22       27-28       33                2
   #           |  |        |  |        |  |        |
   #           2  5        8 23       26 29       32                1
   #         /     \     /     \     /     \     /
   #     0--1        6--7       24-25       30-31                 Y=0
   #
   #  ^
   # X=0 1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 ...


# The factor of 3 arises because there's a gap between each level, increasing
# it by a fixed extra each time,
#
#     length(level) = 2*length(level-1) + 2
#                   = 2^level + (2^level + 2^(level-1) + ... + 2)
#                   = 2^level + (2^(level+1)-1 - 1)
#                   = 3*2^level - 2




=for stopwords eg Ryde Waclaw Sierpinski Sierpinski's Math-PlanePath Nlevel Nend Ntop Xlevel OEIS dX dY dX,dY nextturn

=head1 NAME

Math::PlanePath::SierpinskiCurve -- Sierpinski curve

=head1 SYNOPSIS

 use Math::PlanePath::SierpinskiCurve;
 my $path = Math::PlanePath::SierpinskiCurve->new (arms => 2);
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

X<Sierpinski, Waclaw>This is an integer version of the self-similar curve by
Waclaw Sierpinski traversing the plane by right triangles.  The default is a
single arm of the curve in an eighth of the plane.

=cut

# math-image --path=SierpinskiCurve --all --output=numbers_dash --size=79x26

=pod

    10  |                                  31-32
        |                                 /     \
     9  |                               30       33
        |                                |        |
     8  |                               29       34
        |                                 \     /
     7  |                         25-26    28 35    37-38
        |                        /     \  /     \  /     \
     6  |                      24       27       36       39
        |                       |                          |
     5  |                      23       20       43       40
        |                        \     /  \     /  \     /
     4  |                 7--8    22-21    19 44    42-41    55-...
        |               /     \           /     \           /
     3  |              6        9       18       45       54
        |              |        |        |        |        |
     2  |              5       10       17       46       53
        |               \     /           \     /           \
     1  |        1--2     4 11    13-14    16 47    49-50    52
        |      /     \  /     \  /     \  /     \  /     \  /
    Y=0 |  .  0        3       12       15       48       51
        |
        +-----------------------------------------------------------
           ^
          X=0 1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16

The tiling it represents is

                    /
                   /|\
                  / | \
                 /  |  \
                /  7| 8 \
               / \  |  / \
              /   \ | /   \
             /  6  \|/  9  \
            /-------|-------\
           /|\  5  /|\ 10  /|\
          / | \   / | \   / | \
         /  |  \ /  |  \ /  |  \
        /  1| 2 X 4 |11 X 13|14 \
       / \  |  / \  |  / \  |  / \ ...
      /   \ | /   \ | /   \ | /   \
     /  0  \|/  3  \|/  12 \|/  15 \
    ----------------------------------

The points are on a square grid with integer X,Y.  4 points are used in each
3x3 block.  In general a point is used if

    X%3==1 or Y%3==1 but not both

    which means
    ((X%3)+(Y%3)) % 2 == 1

The X axis N=0,3,12,15,48,etc are all the integers which use only digits 0
and 3 in base 4.  For example N=51 is 303 base4.  Or equivalently the values
all have doubled bits in binary, for example N=48 is 110000 binary.
(Compare the C<CornerReplicate> which also has these values along the X
axis.)

=head2 Level Ranges

Counting the N=0 point as level=0, and with each level being 4 copies of the
previous, the levels end at

    Nlevel = 4^level - 1     = 0, 3, 15, ...
    Xlevel = 3*2^level - 2   = 1, 4, 10, ...
    Ylevel = 0

For example level=2 is Nlevel = 2^(2*2)-1 = 15 at X=3*2^2-2 = 10.

=for GP-DEFINE  Nlevel(level) = 4^level - 1

=for GP-DEFINE  Xlevel(level) = 3*2^level - 2

=for GP-Test  Nlevel(0) == 0

=for GP-Test  Nlevel(1) == 3

=for GP-Test  Nlevel(2) == 15

=for GP-Test  Xlevel(0) == 1

=for GP-Test  Xlevel(1) == 4

=for GP-Test  Xlevel(2) == 10

Doubling a level is the middle of the next level and is the top of the
triangle in that next level.

    Ntop = 2*4^level - 1               = 1, 7, 31, ...
    Xtop = 3*2^level - 1               = 2, 5, 11, ...
    Ytop = 3*2^level - 2  = Xlevel     = 1, 4, 10, ...

For example doubling level=2 is Ntop = 2*4^2-1 = 31 at X=3*2^2-1 = 11 and
Y=3*2^2-2 = 10.

=for GP-DEFINE  Ntop(level) = 2*4^level - 1

=for GP-DEFINE  Xtop(level) = 3*2^level - 1

=for GP-DEFINE  Ytop(level) = 3*2^level - 2

=for GP-Test  2*4^2-1 == 31

=for GP-Test  Ntop(2) == 31

=for GP-Test  X=3*2^2-1 == 11

=for GP-Test  Xtop(2) == 11

=for GP-Test  3*2^2-2 == 10

=for GP-Test  Ytop(2) == 10

The factor of 3 arises from the three steps which make up the N=0,1,2,3
section.  The Xlevel width grows as

    Xlevel(1) = 3
    Xlevel(level) = 2*Xwidth(level-1) + 3

which dividing out the factor of 3 is 2*w+1, giving 2^k-1 (in binary a left
shift and bring in a new 1 bit).

Notice too the Nlevel points as a fraction of the triangular area
Xlevel*(Xlevel-1)/2 gives the 4 out of 9 points filled,

    FillFrac = Nlevel / (Xlevel*(Xlevel-1)/2)
            -> 4/9

=head2 Arms

The optional C<arms> parameter can draw multiple curves, each advancing
successively.  For example 2 arms,


    arms => 2                            ...
                                          |
    11  |     33       39       57       63
        |    /  \     /  \     /  \     /
    10  |  31    35-37    41 55    59-61    62-...
        |    \           /     \           /
     9  |     29       43       53       60
        |      |        |        |        |
     8  |     27       45       51       58
        |    /           \     /           \
     7  |  25    21-19    47-49    50-52    56
        |    \  /     \           /     \  /
     6  |     23       17       48       54
        |               |        |
     5  |      9       15       46       40
        |    /  \     /           \     /  \
     4  |   7    11-13    14-16    44-42    38
        |    \           /     \           /
     3  |      5       12       18       36
        |      |        |        |        |
     2  |      3       10       20       34
        |    /           \     /           \
     1  |   1     2--4     8 22    26-28    32
        |       /     \  /     \  /     \  /
    Y=0 |      0        6       24       30
        |
        +-----------------------------------------
            ^
           X=0 1  2  3  4  5  6  7  8  9 10 11

The N=0 point is at X=1,Y=0 (in all arms forms) so that the second arm is
within the first quadrant.

1 to 8 arms can be done this way.  For example 8 arms are

    arms => 8

           ...                       ...           6
            |                          |
           58       34       33       57           5
             \     /  \     /  \     /
    ...-59    50-42    26 25    41-49    56-...    4
          \           /     \           /
           51       18       17       48           3
            |        |        |        |
           43       10        9       40           2
          /           \     /           \
        35    19-11     2  1     8-16    32        1
          \  /     \           /     \  /
           27        3     .  0       24       <- Y=0

           28        4        7       31          -1
          /  \     /           \     /  \
        36    20-12     5  6    15-23    39       -2
          \           /     \           /
           44       13       14       47          -3
            |        |        |        |
           52       21       22       55          -4
          /           \     /           \
    ...-60    53-45    29 30    46-54    63-...   -5
             /     \  /     \  /     \
           61       37       38       62          -6
            |                          |
           ...                       ...          -7

                           ^
     -7 -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6

The middle "." is the origin X=0,Y=0.  It would be more symmetrical to make
the origin the middle of the eight arms, at X=-0.5,Y=-0.5 in the above, but
that would give fractional X,Y values.  Apply an offset X+0.5,Y+0.5 to
centre it if desired.

=head2 Spacing

The optional C<diagonal_spacing> and C<straight_spacing> can increase the
space between points diagonally or vertically+horizontally.  The default for
each is 1.

=cut

# math-image --path=SierpinskiCurve,straight_spacing=2,diagonal_spacing=1 --all --output=numbers_dash --size=79x26
# math-image --path=SierpinskiCurve,straight_spacing=3,diagonal_spacing=3 --all --output=numbers_dash --size=79x26

=pod

    straight_spacing => 2
    diagonal_spacing => 1

                        7 ----- 8
                     /           \
                    6               9
                    |               |
                    |               |
                    |               |
                    5              10              ...
                     \           /                   \
        1 ----- 2       4      11      13 ---- 14      16
     /           \   /           \   /           \   /
    0               3              12              15

   X=0  1   2   3   4   5   6   7   8   9  10  11  12  13 ...


The effect is only to spread the points.  The straight lines are both
horizontal and vertical so when they're stretched the curve remains on a 45
degree angle in an eighth of the plane.

In the level formulas above the "3" factor becomes 2*d+s, effectively being
the N=0 to N=3 section sized as d+s+d.

    d = diagonal_spacing
    s = straight_spacing

    Xlevel = (2d+s)*(2^level - 1)  + 1

    Xtop = (2d+s)*2^(level-1) - d - s + 1
    Ytop = (2d+s)*2^(level-1) - d - s

=head2 Closed Curve

Sierpinski's original conception was a closed curve filling a unit square by
ever greater self-similar detail,

    /\_/\ /\_/\ /\_/\ /\_/\
    \   / \   / \   / \   /
     | |   | |   | |   | |
    / _ \_/ _ \ / _ \_/ _ \
    \/ \   / \/ \/ \   / \/
       |  |         | |
    /\_/ _ \_/\ /\_/ _ \_/\
    \   / \   / \   / \   /
     | |   | |   | |   | |
    / _ \ / _ \_/ _ \ / _ \
    \/ \/ \/ \   / \/ \/ \/
              | |
    /\_/\ /\_/ _ \_/\ /\_/\
    \   / \   / \   / \   /
     | |   | |   | |   | |
    / _ \_/ _ \ / _ \_/ _ \
    \/ \   / \/ \/ \   / \/
       |  |         | |
    /\_/ _ \_/\ /\_/ _ \_/\
    \   / \   / \   / \   /
     | |   | |   | |   | |
    / _ \ / _ \ / _ \ / _ \
    \/ \/ \/ \/ \/ \/ \/ \/

The code here might be pressed into use for this by drawing a mirror image
of the curve N=0 through Nlevel.  Or using the C<arms=E<gt>2> form N=0 to
N=4^level - 1, inclusive, and joining up the ends.

The curve is also usually conceived as scaling down by quarters.  This can
be had with C<straight_spacing =E<gt> 2> and then an offset to X+1,Y+1 to
centre in a 4*2^level square

=head2 Koch Curve Midpoints

The replicating structure is the same as the Koch curve
(L<Math::PlanePath::KochCurve>) in that the curve repeats four times to make
the next level.

The Sierpinski curve points are midpoints of a Koch curve of 90 degree
angles with a unit gap between verticals.

     Koch Curve                  Koch Curve
                          90 degree angles, unit gap

           /\                       |  |
          /  \                      |  |
         /    \                     |  |
    -----      -----          ------    ------

=cut

=pod

   Sierpinski curve points "*" as midpoints

                      |  |
                      7  8
                      |  |
               ---6---    ---9---

               ---5---    --10---
           |  |       |  |       |  |
           1  2       4  11     13  14
           |  |       |  |       |  |
    ---0---    ---3---    --12---    --15---


=head2 Koch Curve Rounded

The Sierpinski curve in mirror image across the X=Y diagonal and rotated -45
degrees is pairs of points on the lines of the Koch curve 90 degree angles
unit gap from above.

    Sierpinski curve mirror image and turn -45 degrees
    two points on each Koch line segment

                          15   16
                           |    |
                          14   17

                  12--13   .    .   18--19

                  11--10   .    .   21--20

           3   4           9   22            27   28
           |   |           |    |             |    |
           2   5           8   23            26   29

    0---1  .   .   6---7   .    .   24--25    .    .   30--31

This is a kind of "rounded" form of the 90-degree Koch, similar what
C<DragonRounded> does for the C<DragonCurve>.  Each 90 turn of the Koch
curve is done by two turns of 45 degrees in the Sierpinski curve here, and
each 180 degree turn in the Koch is two 90 degree turns here.  So the
Sierpinski turn sequence is pairs of the Koch turn sequence, as follows.
The mirroring means a swap leftE<lt>-E<gt>right between the two.

           N=1    2    3    4    5     6      7      8
    Koch     L    R    L    L    L     R      L      R     ...

           N=1,2  3,4  5,6  7,8  9,10  11,12  13,14  15,16
    Sierp    R R  L L  R R  R R  R R   L  L   R  R   L  L  ...

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::SierpinskiCurve-E<gt>new ()>

=item C<$path = Math::PlanePath::SierpinskiCurve-E<gt>new (arms =E<gt> $integer, diagonal_spacing =E<gt> $integer, straight_spacing =E<gt> $integer)>

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

Return C<(0, 4**$level - 1)>, or for multiple arms return C<(0, $arms *
4**$level - 1)>.

There are 4^level points in a level, or arms*4^level when multiple arms,
numbered starting from 0.

=back

=head1 FORMULAS

=head2 N to dX,dY

The curve direction at N even can be calculated from the base-4 digits of
N/2 in a fashion similar to the Koch curve (L<Math::PlanePath::KochCurve/N
to Direction>).  Counting direction in eighths so 0=East, 1=North-East,
2=North, etc,

    digit     direction
    -----     ---------
      0           0
      1          -2
      2           2
      3           0

    direction = 1 + sum direction[base-4 digits of N/2]
      for N even

For example the direction at N=10 has N/2=5 which is "11" in base-4, so
direction = 1+(-2)+(-2) = -3 = south-west.

The 1 in 1+sum is direction north-east for N=0, then -2 or +2 for the digits
follow the curve.  For an odd arm the curve is mirrored and the sign of each
digit direction is flipped, so a subtract instead of add,

    direction
    mirrored  = 1 - sum direction[base-4 digits of N/2]
       for N even

For odd N=2k+1 the direction at N=2k is calculated and then also the turn
which is made from N=2k to N=2(k+1).  This is similar to the Koch curve next
turn (L<Math::PlanePath::KochCurve/N to Next Turn>).

   lowest non-3      next turn
   digit of N/2   (at N=2k+1,N=2k+2)
   ------------   ----------------
        0           -1 (right)
        1           +2 (left)
        2           -1 (right)

Again the turn is in eighths, so -1 means -45 degrees (to the right).  For
example at N=14 has N/2=7 which is "13" in base-4 so lowest non-3 is "1"
which is turn +2, so at N=15 and N=16 turn by 90 degrees left.


   direction = 1 + sum direction[base-4 digits of k]
                 + if N odd then nextturn[low-non-3 of k]
     for N=2k or 2k+1

   dX,dY = direction to 1,0 1,1 0,1 etc

For fractional N the same nextturn is applied to calculate the direction of
the next segment, and combined with the integer dX,dY as per
L<Math::PlanePath/N to dX,dY -- Fractional>.

   N=2k or 2k+1 + frac

   direction = 1 + sum direction[base-4 digits of k]

   if (frac != 0 or N odd)
     turn = nextturn[low-non-3 of k]

   if N odd then direction += turn
   dX,dY = direction to 1,0 1,1 0,1 etc

   if frac!=0 then
     direction += turn
     next_dX,next_dY = direction to 1,0 1,1 0,1 etc

     dX += frac*(next_dX - dX)
     dY += frac*(next_dY - dY)

For the C<straight_spacing> and C<diagonal_spacing> options the dX,dY values
are not units like dX=1,dY=0 but instead are the spacing amount, either
straight or diagonal so

    direction      delta with spacing
    ---------    -------------------------
        0        dX=straight_spacing, dY=0
        1        dX=diagonal_spacing, dY=diagonal_spacing
        2        dX=0, dY=straight_spacing
        3        dX=-diagonal_spacing, dY=diagonal_spacing
       etc

As an alternative, it's possible to take just base-4 digits of N, without
separate handling for the low-bit of N, but it requires an adjustment on the
low base-4 digit, and the next turn calculation for fractional N becomes
hairier.  A little state table could encode the cumulative and lowest
whatever if desired, to take N by base-4 digits high to low, or equivalently
by bits high to low with an initial state based on high bit at an odd or
even bit position.

=head1 OEIS

The Sierpinski curve is in Sloane's Online Encyclopedia of Integer Sequences
as,

=over

L<http://oeis.org/A039963> (etc)

=back

    A039963   turn 1=right,0=left, doubling the KochCurve turns
    A081706   N-1 of left turn positions
               (first values 2,3 whereas N=3,4 here)
    A127254   abs(dY), so 0=horizontal, 1=vertical or diagonal,
                except extra initial 1
    A081026   X at N=2^k, being successively 3*2^j-1, 3*2^j

A039963 is numbered starting n=0 for the first turn, which is at the point
N=1 in the path here.

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::SierpinskiCurveStair>,
L<Math::PlanePath::SierpinskiArrowhead>,
L<Math::PlanePath::KochCurve>

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
