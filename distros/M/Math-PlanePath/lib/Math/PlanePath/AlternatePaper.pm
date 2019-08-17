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


# ENHANCE-ME: Explanation for this bit ...
# 'arms=4' =>
# { dSum  => 'A020985', # GRS
#   # OEIS-Other: A020985 planepath=AlternatePaper,arms=4 delta_type=dSum
# },


package Math::PlanePath::AlternatePaper;
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
  'round_down_pow',
  'digit_split_lowtohigh',
  'digit_join_lowtohigh',
  'bit_split_lowtohigh';
*_divrem = \&Math::PlanePath::_divrem;
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

# uncomment this to run the ### lines
# use Smart::Comments;


use constant parameter_info_array => [ { name      => 'arms',
                                         share_key => 'arms_8',
                                         display   => 'Arms',
                                         type      => 'integer',
                                         minimum   => 1,
                                         maximum   => 8,
                                         default   => 1,
                                         width     => 1,
                                         description => 'Arms',
                                       } ];

use constant n_start => 0;
sub x_negative {
  my ($self) = @_;
  return ($self->{'arms'} >= 3);
}
sub y_negative {
  my ($self) = @_;
  return ($self->{'arms'} >= 5);
}
{
  my @x_negative_at_n = (undef,
                         undef,undef,8,7,
                         4,4,4,4);
  sub x_negative_at_n {
    my ($self) = @_;
    return $x_negative_at_n[$self->{'arms'}];
  }
}
{
  my @y_negative_at_n = (undef,
                                        undef,undef,undef,undef,
                                        44,23,13,14);
  sub y_negative_at_n {
    my ($self) = @_;
    return $y_negative_at_n[$self->{'arms'}];
  }
}

sub sumxy_minimum {
  my ($self) = @_;
  return ($self->arms_count <= 3
          ? 0        # 1,2,3 arms above X=-Y diagonal
          : undef);
}
sub diffxy_minimum {
  my ($self) = @_;
  return ($self->arms_count == 1
          ? 0        # 1 arms right of X=Y diagonal
          : undef);
}

use constant turn_any_straight => 0; # never straight


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);
  $self->{'arms'} = max(1, min(8, $self->{'arms'} || 1));
  return $self;
}


# state=0  /|         +----+----+
#         / |         |\ 1||<--/
#        /2 |         |^\ || 0/
#       /-->|         || \v| /
#      +----+         ||3 \|/
#     /|\ 3||         +----+
#    / |^\ ||         |<--/   state=4
#   / 0|| \v|         | 2/
#  /-->||1 \|         | /
# +----+----+         |/
#
# |\  state=8         +----+----+  state=12
# |^\                  \ 1||<--/|
# || \                  \ || 0/ |
# ||3 \                  \v| /2 |
# +----+                  \|/-->|
# |<--/|\                  +----+
# | 2/ |^\                  \ 3||
# | /0 || \                  \ ||
# |/-->||1 \                  \v|
# +----+----+                  \|

my @next_state = (0,  8, 0, 12,   # forward
                  4, 12, 4,  8,   # forward NW
                  0,  8, 4,  8,   # reverse
                  4, 12, 0, 12,   # reverse NE
                 );
my @digit_to_x = (0,1,1,1,
                  1,0,0,0,
                  0,1,0,0,
                  1,0,1,1,
                 );
my @digit_to_y = (0,0,1,0,
                  1,1,0,1,
                  0,0,0,1,
                  1,1,1,0,
                 );

# state_to_dx[S] == state_to_x[S+3] - state_to_x[S+0]
my @state_to_dx = (1, undef,undef,undef,
                   -1, undef,undef,undef,
                   0, undef,undef,undef,
                   0, undef,undef,undef,
                  );
my @state_to_dy = (0, undef,undef,undef,
                   0, undef,undef,undef,
                   1, undef,undef,undef,
                   -1, undef,undef,undef,
                  );

sub n_to_xy {
  my ($self, $n) = @_;
  ### AlternatePaper n_to_xy(): $n

  if ($n < 0) { return; }
  if (is_infinite($n)) { return ($n, $n); }

  my $int = int($n);  # integer part
  $n -= $int;         # fraction part
  ### $int
  ### $n

  my $zero = ($int * 0);  # inherit bignum 0
  my $arm = _divrem_mutate ($int, $self->{'arms'});

  ### $arm
  ### $int

  my @digits = digit_split_lowtohigh($int,4);
  my $state = 0;
  my (@xbits,@ybits); # bits low to high (like @digits)

  foreach my $i (reverse 0 .. $#digits) {  # high to low
    $state += $digits[$i];
    $xbits[$i] = $digit_to_x[$state];
    $ybits[$i] = $digit_to_y[$state];
    $state = $next_state[$state];
  }
  my $x = digit_join_lowtohigh(\@xbits,2,$zero);
  my $y = digit_join_lowtohigh(\@ybits,2,$zero);

  # X+1,Y+1 for final state=4 or state=12
  $x += $digit_to_x[$state];
  $y += $digit_to_y[$state];

  ### final: "xy=$x,$y state=$state"

  # apply possible fraction part of $n in direction of $state
  $x = $n * $state_to_dx[$state] + $x;
  $y = $n * $state_to_dy[$state] + $y;

  # rotate,transpose for arm number
  if ($arm & 1) {
    ($x,$y) = ($y,$x);   # transpose
  }
  if ($arm & 2) {
    ($x,$y) = (-$y,$x+1);  # rotate +90 and shift origin to X=0,Y=1
  }
  if ($arm & 4) {
    $x = -1 - $x;      # rotate +180 and shift origin to X=-1,Y=1
    $y = 1 - $y;
  }

  ### rotated return: "$x,$y"
  return ($x,$y);
}

#                                                      8
#
#                                          42   43     7
#
#                                    40 41/45   44     6
#
#                              34 35/39 38/46   47     5
#
#                        32-33/53-36/52-37/49---48     4
#                        | \
#                  10 11/31 30/54 51/55 50/58   59     3
#                        |       \
#             8  9/13 12/28 25/29 24/56 57/61   60     2
#                        |             \
#       2   3/7  6/14 15/27 18/26 19/23 22/62   63     1
#                        |                   \
# 0     1     4     5    16    17    20    21 ==64     0
#
# 0     1     2     3     4     5     6     7    8

sub xy_to_n {
  return scalar((shift->xy_to_n_list(@_))[0]);
}
sub xy_to_n_list {
  my ($self, $x, $y) = @_;
  ### AlternatePaper xy_to_n(): "$x, $y"

  $x = round_nearest($x);
  $y = round_nearest($y);
  if (is_infinite($x)) { return $x; }
  if (is_infinite($y)) { return $y; }

  my $arms = $self->{'arms'};
  my $arm = 0;
  my @ret;
  foreach (1 .. 4) {
    push @ret, map {$_*$arms+$arm} _xy_to_n_list__onearm($self,$x,$y);
    last if ++$arm >= $arms;

    ($x,$y) = ($y,$x); # transpose
    push @ret, map {$_*$arms+$arm} _xy_to_n_list__onearm($self,$x,$y);
    last if ++$arm >= $arms;

    # X,Y -> Y,X
    #     -> Y,X-1     # Y-1 shift
    #     -> X-1,-Y    # rot -90
    # ie. mirror across X axis and shift
    ($x,$y) = ($x-1,-$y);
  }
  return sort {$a<=>$b} @ret;
}

sub _xy_to_n_list__onearm {
  my ($self, $x, $y) = @_;
  ### _xy_to_n_list__onearm(): "$x,$y"

  if ($y < 0 || $y > $x || $x < 0) {
    ### outside first octant ...
    return;
  }

  my ($len,$level) = round_down_pow($x, 2);
  ### $len
  ### $level
  if (is_infinite($level)) {
    return;
  }

  my $n = my $big_n = $x * 0 * $y;  # inherit bignum 0
  my $rev = 0;

  my $big_x = $x;
  my $big_y = $y;
  my $big_rev = 0;

  while ($level-- >= 0) {
    ### at: "$x,$y  len=$len  n=$n"

    # the smaller N
    {
      $n *= 4;
      if ($rev) {
        if ($x+$y < 2*$len) {
          ### rev 0 or 1 ...
          if ($x < $len) {
          } else {
            ### rev 1 ...
            $rev = 0;
            $n -= 2;
            ($x,$y) = ($len-$y, $x-$len);   # x-len,y-len then rotate +90
          }

        } else {
          ### rev 2 or 3 ...
          if ($y > $len || ($x==$len && $y==$len)) {
            ### rev 2 ...
            $n -= 2;
            $x -= $len;
            $y -= $len;
          } else {
            ### rev 3 ...
            $n -= 4;
            $rev = 0;
            ($x,$y) = ($y, 2*$len-$x);   # to origin then rotate -90
          }
        }
      } else {
        if ($x+$y <= 2*$len
            && !($x==$len && $y==$len)
            && !($x==2*$len && $y==0)) {
          ### 0 or 1 ...
          if ($x <= $len) {
          } else {
            ### 1 ...
            $n += 2;
            $rev = 1;
            ($x,$y) = ($len-$y, $x-$len);   # x-len,y-len then rotate +90
          }

        } else {
          ### 2 or 3 ...
          if ($y >= $len && !($x==2*$len && $y==$len)) {
            $n += 2;
            $x -= $len;
            $y -= $len;
          } else {
            $n += 4;
            $rev = 1;
            ($x,$y) = ($y, 2*$len-$x);   # to origin then rotate -90
          }
        }
      }
    }

    # the bigger N
    {
      $big_n *= 4;
      if ($big_rev) {
        if ($big_x+$big_y <= 2*$len
            && !($big_x==$len && $big_y==$len)
            && !($big_x==2*$len && $big_y==0)) {
          ### rev 0 or 1 ...
          if ($big_x <= $len) {
          } else {
            ### rev 1 ...
            $big_rev = 0;
            $big_n -= 2;
            ($big_x,$big_y) = ($len-$big_y, $big_x-$len);   # x-len,y-len then rotate +90
          }

        } else {
          ### rev 2 or 3 ...
          if ($big_y >= $len && !($big_x==2*$len && $big_y==$len)) {
            ### rev 2 ...
            $big_n -= 2;
            $big_x -= $len;
            $big_y -= $len;
          } else {
            ### rev 3 ...
            $big_n -= 4;
            $big_rev = 0;
            ($big_x,$big_y) = ($big_y, 2*$len-$big_x);   # to origin then rotate -90
          }
        }
      } else {
        if ($big_x+$big_y < 2*$len) {
          ### 0 or 1 ...
          if ($big_x < $len) {
          } else {
            ### 1 ...
            $big_n += 2;
            $big_rev = 1;
            ($big_x,$big_y) = ($len-$big_y, $big_x-$len);   # x-len,y-len then rotate +90
          }

        } else {
          ### 2 or 3 ...
          if ($big_y > $len || ($big_x==$len && $big_y==$len)) {
            $big_n += 2;
            $big_x -= $len;
            $big_y -= $len;
          } else {
            $big_n += 4;
            $big_rev = 1;
            ($big_x,$big_y) = ($big_y, 2*$len-$big_x);   # to origin then rotate -90
          }
        }
      }
    }
    $len /= 2;
  }

  if ($x) {
    $n += ($rev ? -1 : 1);
  }
  if ($big_x) {
    $big_n += ($big_rev ? -1 : 1);
  }

  ### final: "$x,$y  n=$n  rev=$rev"
  ### final: "$x,$y  big_n=$n  big_rev=$rev"

  return ($n,
          ($n == $big_n ? () : ($big_n)));
}


# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### AlternatePaper rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest($x1);
  $x2 = round_nearest($x2);
  $y1 = round_nearest($y1);
  $y2 = round_nearest($y2);

  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;

  ### rounded: "$x1,$y1  $x2,$y2"

  my $arms = $self->{'arms'};
  if (($arms == 1 && $y1 > $x2)       # x2,y1 bottom right corner
      || ($arms <= 2 && $x2 < 0)
      || ($arms <= 4 && $y2 < 0)) {
    ### outside ...
    return (1,0);
  }

  # arm start 0,1 at X=0,Y=0
  #           2,3 at X=0,Y=1
  #           4,5 at X=-1,Y=1
  #           6,7 at X=-1,Y=1
  # arms>=6 is arm=5 starting at Y=+1, so 1-$y1
  # arms>=8 starts at X=-1 so extra +1 for x2 to the right in that case
  my ($len, $level) =round_down_pow (max ($x2+($arms>=8),
                                          ($arms >= 2 ? $y2 : ()),
                                          ($arms >= 4 ? -$x1 : ()),
                                          ($arms >= 6 ? 1-$y1 : ())),
                                     2);
  return (0, 4*$arms*$len*$len-1);
}


my @dir4_to_dx = (1,0,-1,0);
my @dir4_to_dy = (0,1,0,-1);

sub n_to_dxdy {
  my ($self, $n) = @_;
  ### n_to_dxdy(): $n

  my $int = int($n);
  $n -= $int;  # $n fraction part
  ### $int
  ### $n

  my $arm = _divrem_mutate ($int, $self->{'arms'});
  ### $arm
  ### $int

  # $dir initial direction from the arm.
  # $inc +/-1 according to the bit position odd or even, but also odd
  # numbered arms are transposed so flip them.
  #
  my @bits = bit_split_lowtohigh($int);
  my $dir = ($arm+1) >> 1;
  my $inc = (($#bits ^ $arm) & 1 ? -1 : 1);
  my $prev = 0;

  ### @bits
  ### initial dir: $dir
  ### initial inc: $inc

  foreach my $bit (reverse @bits) {
    if ($bit != $prev) {
      $dir += $inc;
      $prev = $bit;
    }
    $inc = -$inc;   # opposite at each bit
  }
  $dir &= 3;
  my $dx = $dir4_to_dx[$dir];
  my $dy = $dir4_to_dy[$dir];
  ### $dx
  ### $dy

  if ($n) {
    ### apply fraction part: $n

    # maybe:
    # +/- $n as dx or dy
    # +/- (1-$n) as other dy or dx

    # strip any low 1-bits, and the 0-bit above them
    # $inc is +1 at an even bit position or -1 at an odd bit position
    $inc = my $inc = ($arm & 1 ? -1 : 1);
    while (shift @bits) {
      $inc = -$inc;
    }
    if ($bits[0]) { # bit above lowest 0-bit, 1=right,0=left
      $inc = -$inc;
    }
    $dir += $inc;   # apply turn to give $dir at $n+1
    $dir &= 3;
    $dx += $n*($dir4_to_dx[$dir] - $dx);
    $dy += $n*($dir4_to_dy[$dir] - $dy);
  }

  ### result: "$dx, $dy"
  return ($dx,$dy);
}

# {
#   sub print_table {
#     my ($name, $aref) = @_;
#     print "my \@$name = (";
#     my $entry_width = max (map {length($_//'')} @$aref);
#
#     foreach my $i (0 .. $#$aref) {
#       printf "%*s", $entry_width, $aref->[$i]//'undef';
#       if ($i == $#$aref) {
#         print ");\n";
#       } else {
#         print ",";
#         if (($i % 16) == 15
#             || ($entry_width >= 3 && ($i % 4) == 3)) {
#           print "\n        ".(" " x length($name));
#         } elsif (($i % 4) == 3) {
#           print " ";
#         }
#       }
#     }
#   }
#
#   my @next_state;
# my @state_to_dxdy;
#
# sub make_state {
#   my %values = @_;
#   #  if ($oddpos) { $rot = ($rot-1)&3; }
#   my $state = delete $values{'nextturn'};
#   $state <<= 2; $state |= delete $values{'rot'};
#   $state <<= 1; $state |= delete $values{'oddpos'};
#   $state <<= 1; $state |= delete $values{'lowerbit'};
#   $state <<= 1; $state |= delete $values{'bit'};
#   die if %values;
#   return $state;
# }
# sub state_string {
#   my ($state) = @_;
#   my $bit = $state & 1;  $state >>= 1;
#   my $lowerbit = $state & 1;  $state >>= 1;
#   my $oddpos = $state & 1;  $state >>= 1;
#   my $rot = $state & 3;  $state >>= 2;
#   my $nextturn = $state;
#   #  if ($oddpos) { $rot = ($rot+1)&3; }
#   return "rot=$rot,oddpos=$oddpos nextturn=$nextturn  lowerbit=$lowerbit (bit=$bit)";
# }
#
# foreach my $nextturn (0, 1, 2) {
#   foreach my $rot (0, 1, 2, 3) {
#     foreach my $oddpos (0, 1) {
#       foreach my $lowerbit (0, 1) {
#         foreach my $bit (0, 1) {
#           my $state = make_state (bit      => $bit,
#                                   lowerbit => $lowerbit,
#                                   rot      => $rot,
#                                   oddpos   => $oddpos,
#                                   nextturn => $nextturn);
#           ### $state
#
#           my $new_nextturn = $nextturn;
#           my $new_lowerbit = $bit;
#           my $new_rot = $rot;
#           my $new_oddpos = $oddpos ^ 1;
#
#           if ($bit != $lowerbit) {
#             if ($oddpos) {
#               $new_rot++;
#             } else {
#               $new_rot--;
#             }
#             $new_rot &= 3;
#           }
#           if ($lowerbit == 0 && ! $nextturn) {
#             $new_nextturn = ($bit ^ $oddpos ? 1 : 2);  # bit above lowest 0
#           }
#
#           my $dx = 1;
#           my $dy = 0;
#           if ($rot & 2) {
#             $dx = -$dx;
#             $dy = -$dy;
#           }
#           if ($rot & 1) {
#             ($dx,$dy) = (-$dy,$dx); # rotate +90
#           }
#           ### rot to: "$dx, $dy"
#
#           # if ($oddpos) {
#           #   ($dx,$dy) = (-$dy,$dx); # rotate +90
#           # } else {
#           #   ($dx,$dy) = ($dy,-$dx); # rotate -90
#           # }
#
#           my $next_dx = $dx;
#           my $next_dy = $dy;
#           if ($nextturn == 2) {
#             ($next_dx,$next_dy) = (-$next_dy,$next_dx); # left, rotate +90
#           } else {
#             ($next_dx,$next_dy) = ($next_dy,-$next_dx); # right, rotate -90
#           }
#           my $frac_dx = $next_dx - $dx;
#           my $frac_dy = $next_dy - $dy;
#
#           # mask to rot,oddpos only, ignore bit,lowerbit
#           my $masked_state = $state & ~3;
#           $state_to_dxdy[$masked_state]     = $dx;
#           $state_to_dxdy[$masked_state + 1] = $dy;
#           $state_to_dxdy[$masked_state + 2] = $frac_dx;
#           $state_to_dxdy[$masked_state + 3] = $frac_dy;
#
#           my $next_state =  make_state (bit      => 0,
#                                         lowerbit => $new_lowerbit,
#                                         rot      => $new_rot,
#                                         oddpos   => $new_oddpos,
#                                         nextturn => $new_nextturn);
#           $next_state[$state] = $next_state;
#         }
#       }
#     }
#   }
# }
#
# my @arm_to_state;
# foreach my $arm (0 .. 7) {
#   my $rot = $arm >> 1;
#   my $oddpos = 0;
#   if ($arm & 1) {
#     $rot++;
#     $oddpos ^= 1;
#   }
#   $arm_to_state[$arm] = make_state (bit => 0,
#                                     lowerbit => 0,
#                                     rot => $rot,
#                                     oddpos => $oddpos,
#                                     nextturn => 0);
# }
#
# ### @next_state
# ### @state_to_dxdy
# ### next_state length: 4*(4*2*2 + 4*2)
#
# print "# next_state length ", scalar(@next_state), "\n";
# print_table ("next_state", \@next_state);
# print_table ("state_to_dxdy", \@state_to_dxdy);
# print_table ("arm_to_state", \@arm_to_state);
# print "\n";
#
# foreach my $arm (0 .. 7) {
#   print "# arm=$arm  ",state_string($arm_to_state[$arm]),"\n";
# }
# print "\n";
#
#
#
#   use Smart::Comments;
#
#   sub n_to_dxdy {
#     my ($self, $n) = @_;
#     ### n_to_dxdy(): $n
#
#     my $int = int($n);
#     $n -= $int;  # $n fraction part
#     ### $int
#     ### $n
#
#     my $state = _divrem_mutate ($int, $self->{'arms'}) << 2;
#     ### arm as initial state: $state
#
#     foreach my $bit (bit_split_lowtohigh($int)) {
#       $state = $next_state[$state + $bit];
#     }
#     $state &= 0x1C;  # mask out "prevbit"
#
#     ### final state: $state
#     ### dx: $state_to_dxdy[$state]
#     ### dy: $state_to_dxdy[$state+1],
#     ### frac dx: $state_to_dxdy[$state+2],
#     ### frac dy: $state_to_dxdy[$state+3],
#
#     return ($state_to_dxdy[$state]   + $n * $state_to_dxdy[$state+2],
#             $state_to_dxdy[$state+1] + $n * $state_to_dxdy[$state+3]);
#   }
#
# }

#------------------------------------------------------------------------------
# levels

use Math::PlanePath::DragonCurve;
*level_to_n_range = \&Math::PlanePath::DragonCurve::level_to_n_range;
*n_to_level       = \&Math::PlanePath::DragonCurve::n_to_level;

#------------------------------------------------------------------------------

sub _UNDOCUMENTED_level_to_right_line_boundary {
  my ($self, $level) = @_;
  if ($level == 0) {
    return 1;
  }
  my ($h,$odd) = _divrem($level,2);
  return ($odd
          ? 6 * 2**$h - 4
          : 2 * 2**$h);
}
sub _UNDOCUMENTED_level_to_left_line_boundary {
  my ($self, $level) = @_;
  if ($level == 0) {
    return 1;
  }
  my ($h,$odd) = _divrem($level,2);
  return ($odd
          ? 2 * 2**$h
          : 4 * 2**$h - 4);
}
sub _UNDOCUMENTED_level_to_line_boundary {
  my ($self, $level) = @_;
  my ($h,$odd) = _divrem($level,2);
  return (($odd?8:6) * 2**$h - 4);
}

sub _UNDOCUMENTED_level_to_hull_area {
  my ($self, $level) = @_;
  return (2**$level - 1)/2;
}

sub _UNDOCUMENTED__n_is_x_positive {
  my ($self, $n) = @_;
  if (! ($n >= 0) || is_infinite($n)) { return 0; }

  $n = int($n);
  {
    my $arm = _divrem_mutate($n, $self->{'arms'});

    # arm 1 good only on N=1 which is remaining $n==0
    if ($arm == 1) {
      return ($n == 0);
    }

    # arm 0 good
    # arm 8 good for N>=15 which is remaining $n>=1
    unless ($arm == 0
            || ($arm == 7 && $n > 0)) {
      return 0;
    }
  }

  return _is_base4_01($n);
}

sub _UNDOCUMENTED__n_is_diagonal_NE {
  my ($self, $n) = @_;
  if (! ($n >= 0) || is_infinite($n)) { return 0; }

  $n = int($n);
  if ($self->{'arms'} >= 8 && $n == 15) { return 1; }
  if (_divrem_mutate($n, $self->{'arms'}) >= 2) { return 0; }
  return _is_base4_02($n);
}

# X axis N is base4 digits 0,1
# and -1 from even is 0,1 low 0333333
# and -2 from even is 0,1 low 0333332
# so $n+2 low digit any then 0,1s above
sub _UNDOCUMENTED__n_segment_is_right_boundary {
  my ($self, $n) = @_;
  if ($self->{'arms'} >= 8
      || ! ($n >= 0)
      || is_infinite($n)) {
    return 0;
  }
  $n = int($n);

  if (_divrem_mutate($n, $self->{'arms'}) >= 1) {
    return 0;
  }
  $n += 2;
  _divrem_mutate($n,4);
  return _is_base4_01($n);
}

# diagonal N is base4 digits 0,2,
# and -1 from there is 0,2 low 1
#                   or 0,2 low 13333
# so $n+1 low digit possible 1 or 3 then 0,2s above
# which means $n+1 low digit any and 0,2s above
#use Smart::Comments;

sub _UNDOCUMENTED__n_segment_is_left_boundary {
  my ($self, $n) = @_;
  ### _UNDOCUMENTED__n_segment_is_left_boundary(): $n

  my $arms = $self->{'arms'};
  if ($arms >= 8
      || ! ($n >= 0)
      || is_infinite($n)) {
    return 0;
  }
  $n = int($n);

  if (($n == 1 && $arms >= 4)
      || ($n == 3 && $arms >= 5)
      || ($n == 5 && $arms == 7)) {
    return 1;
  }
  if (_divrem_mutate($n, $arms) < $arms-1) {
    ### no, not last arm ...
    return 0;
  }

  if ($arms % 2) {
    ### odd arms, stair-step boundary ...
    $n += 1;
    _divrem_mutate($n,4);
    return _is_base4_02($n);
  } else {
    # even arms, notched like right boundary
    $n += 2;
    _divrem_mutate($n,4);
    return _is_base4_01($n);
  }
}

sub _is_base4_01 {
  my ($n) = @_;
  while ($n) {
    my $digit = _divrem_mutate($n,4);
    if ($digit >= 2) { return 0; }
  }
  return 1;
}
sub _is_base4_02 {
  my ($n) = @_;
  while ($n) {
    my $digit = _divrem_mutate($n,4);
    if ($digit == 1 || $digit == 3) { return 0; }
  }
  return 1;
}

1;
__END__

#------------------------------------------------------------------------------


# Old code with explicit rotation etc rather than state table.
#
# my @dir4_to_dx = (1,0,-1,0);
# my @dir4_to_dy = (0,1,0,-1);
#
# my @arm_to_x = (0,0, 0,0, -1,-1, -1,-1);
# my @arm_to_y = (0,0, 1,1,   1,1,  0,0);
#
# sub XXn_to_xy {
#   my ($self, $n) = @_;
#   ### AlternatePaper n_to_xy(): $n
#
#   if ($n < 0) { return; }
#   if (is_infinite($n)) { return ($n, $n); }
#
#   my $frac;
#   {
#     my $int = int($n);
#     $frac = $n - $int;  # inherit possible BigFloat
#     $n = $int;          # BigFloat int() gives BigInt, use that
#   }
#   ### $frac
#
#   my $zero = ($n * 0);  # inherit bignum 0
#
#   my $arm = _divrem_mutate ($n, $self->{'arms'});
#
#   my @bits = bit_split_lowtohigh($n);
#   if (scalar(@bits) & 1) {
#     push @bits, 0;  # extra high to make even
#   }
#
#   my @sx;
#   my @sy;
#   {
#     my $sy = $zero;   # inherit BigInt
#     my $sx = $sy + 1; # inherit BigInt
#     ### $sx
#     ### $sy
#
#     foreach (1 .. scalar(@bits)/2) {
#       push @sx, $sx;
#       push @sy, $sy;
#
#       # (sx,sy) + rot+90(sx,sy)
#       ($sx,$sy) = ($sx - $sy,
#                    $sy + $sx);
#
#       push @sx, $sx;
#       push @sy, $sy;
#
#       # (sx,sy) + rot-90(sx,sy)
#       ($sx,$sy) = ($sx + $sy,
#                    $sy - $sx);
#     }
#   }
#
#   ### @bits
#   ### @sx
#   ### @sy
#   ### assert: scalar(@sx) == scalar(@bits)
#
#   my $rot = int($arm/2);  # arm to initial rotation
#   my $rev = 0;
#   my $x = $zero;
#   my $y = $zero;
#   while (@bits) {
#     {
#       my $bit = pop @bits;   # high to low
#       my $sx = pop @sx;
#       my $sy = pop @sy;
#       ### at: "$x,$y  $bit   side $sx,$sy"
#       ### $rot
#
#       if ($rot & 2) {
#         ($sx,$sy) = (-$sx,-$sy);
#       }
#       if ($rot & 1) {
#         ($sx,$sy) = (-$sy,$sx);
#       }
#
#       if ($rev) {
#         if ($bit) {
#           $x -= $sy;
#           $y += $sx;
#           ### rev add to: "$x,$y next is still rev"
#         } else {
#           $rot ++;
#           $rev = 0;
#         }
#       } else {
#         if ($bit) {
#           $rot ++;
#           $x += $sx;
#           $y += $sy;
#           $rev = 1;
#           ### add to: "$x,$y next is rev"
#         }
#       }
#     }
#
#     @bits || last;
#
#     {
#       my $bit = pop @bits;
#       my $sx = pop @sx;
#       my $sy = pop @sy;
#       ### at: "$x,$y  $bit   side $sx,$sy"
#       ### $rot
#
#       if ($rot & 2) {
#         ($sx,$sy) = (-$sx,-$sy);
#       }
#       if ($rot & 1) {
#         ($sx,$sy) = (-$sy,$sx);
#       }
#
#       if ($rev) {
#         if ($bit) {
#           $x += $sy;
#           $y -= $sx;
#           ### rev add to: "$x,$y next is still rev"
#         } else {
#           $rot --;
#           $rev = 0;
#         }
#       } else {
#         if ($bit) {
#           $rot --;
#           $x += $sx;
#           $y += $sy;
#           $rev = 1;
#           ### add to: "$x,$y next is rev"
#         }
#       }
#     }
#   }
#
#   ### $rot
#   ### $rev
#
#   if ($rev) {
#     $rot += 2;
#     ### rev change rot to: $rot
#   }
#
#   if ($arm & 1) {
#     ($x,$y) = ($y,$x);  # odd arms transpose
#   }
#
#   $rot &= 3;
#   $x = $frac * $dir4_to_dx[$rot] + $x + $arm_to_x[$arm];
#   $y = $frac * $dir4_to_dy[$rot] + $y + $arm_to_y[$arm];
#
#   ### final: "$x,$y"
#   return ($x,$y);
# }



=for :stopwords eg Ryde Math-PlanePath Nlevel et al vertices doublings OEIS Online DragonCurve ZOrderCurve 0xAA..AA Golay-Rudin-Shapiro Rudin-Shapiro dX dY dX,dY GRS dSum undoubled MendE<232>s Tenenbaum des Courbes Papiers de ie ceil

=head1 NAME

Math::PlanePath::AlternatePaper -- alternate paper folding curve

=head1 SYNOPSIS

 use Math::PlanePath::AlternatePaper;
 my $path = Math::PlanePath::AlternatePaper->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This is an integer version of the alternate paper folding curve (a variation
on the DragonCurve paper folding).

=cut

# math-image --path=AlternatePaper --expression='i<=128?i:0' --output=numbers --size=60

=pod

      8 |                                                      128
        |                                                       |
      7 |                                                42---43/127
        |                                                |      |
      6 |                                         40---41/45--44/124
        |                                         |      |      |
      5 |                                  34---35/39--38/46--47/123
        |                                  |      |      |      |
      4 |                           32---33/53--36/52--37/49--48/112
        |                           |      |      |      |      |
      3 |                    10---11/31--30/54--51/55--50/58--59/111
        |                    |      |      |      |      |      |
      2 |              8----9/13--12/28--29/25--24/56--57/61--60/108
        |              |     |      |      |      |      |      |
      1 |        2----3/7---6/14--15/27--26/18--19/23---22/62--63/107
        |        |     |     |      |      |      |      |      |
    Y=0 |  0-----1     4-----5     16-----17     20-----21     64---..
        |
        +------------------------------------------------------------
          X=0    1     2     3      4      5      6      7      8

The curve visits the X axis points and the X=Y diagonal points once each and
visits "inside" points between there twice each.  The first doubled point is
X=2,Y=1 which is N=3 and also N=7.  The segments N=2,3,4 and N=6,7,8 have
touched, but the curve doesn't cross over itself.  The doubled vertices are
all like this, touching but not crossing, and no edges repeat.

The first step N=1 is to the right along the X axis and the path fills the
eighth of the plane up to the X=Y diagonal inclusive.

The X axis N=0,1,4,5,16,17,etc is the integers which have only digits 0,1 in
base 4, or equivalently those which have a 0 bit at each odd numbered bit
position.

The X=Y diagonal N=0,2,8,10,32,etc is the integers which have only digits
0,2 in base 4, or equivalently those which have a 0 bit at each even
numbered bit position.

The X axis values are the same as on the ZOrderCurve X axis, and the X=Y
diagonal is the same as the ZOrderCurve Y axis, but in between the two are
different.  (See L<Math::PlanePath::ZOrderCurve>.)

=head2 Paper Folding

The curve arises from thinking of a strip of paper folded in half
alternately one way and the other, and then unfolded so each crease is a 90
degree angle.  The effect is that the curve repeats in successive doublings
turned 90 degrees and reversed.

The first segment N=0 to N=1 unfolds clockwise, pivoting at the endpoint
"1",

                                    2
                               ->   |
                 unfold       /     |
                  ===>       |      |
                                    |
    0------1                0-------1

Then that "L" shape unfolds again, pivoting at the end "2", but
anti-clockwise, on the opposite side to the first unfold,

                                    2-------3
           2                        |       |
           |     unfold             |   ^   |
           |      ===>              | _/    |
           |                        |       |
    0------1                0-------1       4

In general after each unfold the shape is a triangle as follows.  "N" marks
the N=2^k endpoint in the shape, either bottom right or top centre.

    after even number          after odd number
       of unfolds,                of unfolds,
     N=0 to N=2^even            N=0 to N=2^odd

               .                       N
              /|                      / \
             / |                     /   \
            /  |                    /     \
           /   |                   /       \
          /    |                  /         \
         /_____N                 /___________\
        0,0                     0,0

For an even number of unfolds the triangle consists of 4 sub-parts numbered
by the high digit of N in base 4.  Those sub-parts are self-similar in the
direction "E<gt>", "^" etc as follows, and with a reversal for parts 1
and 3.

              +
             /|
            / |
           /  |
          / 2>|
         +----+
        /|\  3|
       / | \ v|
      /  |^ \ |
     / 0>| 1 \|
    +----+----+

=head2 Arms

The C<arms> parameter can choose 1 to 8 curve arms successively advancing.
Each fills an eighth of the plane.  The second arm is mirrored across the
X=Y leading diagonal, so

=cut

# math-image --path=AlternatePaper,arms=2 --expression='i<=128?i:0' --output=numbers --size=60

=pod

      arms => 2

        |   |     |       |       |       |
      4 |  33---31/55---25/57---23/63---64/65--
        |         |       |       |       |
      3 |  11---13/29---19/27---20/21---22/62--
        |   |     |       |       |       |
      2 |   9----7/15---16/17---18/26---24/56--
        |         |       |       |       |
      1 |   3----4/5-----6/14---12/28---30/54--
        |   |     |       |       |       |
    Y=0 |  0/1----2       8------10      32---
        |
        +------------- -------------------------
          X=0     1       2       3       4

Here the even N=0,2,4,6,etc is the plain curve below the X=Y diagonals and
odd N=1,3,5,7,9,etc is the mirrored copy.

Arms 3 and 4 are the same but rotated +90 degrees and starting from X=0,Y=1.
That start point ensures each edge between integer points is traversed just
once.

=cut

# math-image --path=AlternatePaper,arms=4 --expression='i<=256?i:0' --output=numbers --size=60

=pod

    arms => 4

        |       |       |      |        |
    --34/35---14/30---18/21--25/57----37/53--        3
        |       |       |      |        |
    --15/31---10/11----6/17--13/29----32/33--        2
        |       |       |      |        |
     --19       7-----2/3/5---8/9-----12/28--        1
                        |      |        |
                       0/1-----4        16--     <- Y=0

    -----------------------------------------
       -1      -2      X=0     1        2

Points N=0,4,8,12,etc is the plain curve, N=1,5,9,13,etc the second mirrored
arm, N=2,6,10,14,etc is arm 3 which is the plain curve rotated +90, and
N=3,7,11,15,etc the rotated and mirrored.

Arms 5 and 6 start at X=-1,Y=1, and arms 7 and 8 start at X=-1,Y=0 so they
too traverse each edge once.  With a full 8 arms each point is visited twice
except for the four start points which are three times.

=cut

# math-image --path=AlternatePaper,arms=8 --expression='i<=256?i:0' --output=numbers --size=60

=pod

    arms => 8

        |       |       |       |       |       |
    --75/107--66/67---26/58---34/41---49/113--73/105--        3
        |       |       |       |       |       |
    --51/115---27/59---18/19--10/33---25/57---64/65--         2
        |       |       |       |       |       |
    --36/43---12/35---4/5/11---2/3/9--16/17---24/56--         1
        |       |       |       |       |       |
    --28/60---20/21---6/7/13--0/1/15---8/39---32/47--     <- Y=0
        |       |       |       |       |       |
    --68/69---29/61----14/37---22/23--31/63---55/119--       -1
        |       |       |       |       |       |
    --77/109--53/117---38/45---30/62--70/71---79/111--       -2
        |       |       |       |       |       |

                                ^
       -3      -2      -1      X=0     1        2

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::AlternatePaper-E<gt>new ()>

=item C<$path = Math::PlanePath::AlternatePaper-E<gt>new (arms =E<gt> $integer)>

Create and return a new path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

Fractional positions give an X,Y position along a straight line between the
integer points.

=item C<@n_list = $path-E<gt>xy_to_n_list ($x,$y)>

Return a list of N point numbers for coordinates C<$x,$y>.

For arms=1 there may be none, one or two N's for a given C<$x,$y>.  For
multiple arms the origin points X=0 or 1 and Y=0 or -1 have up to 3 Ns,
being the starting points of the arms.  For arms=8 those 4 points have 3 N
and every other C<$x,$y> has exactly two Ns.

=item C<$n = $path-E<gt>n_start()>

Return 0, the first N in the path.

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<(0, 2**$level)>, or for multiple arms return C<(0, $arms *
2**$level + ($arms-1))>.

This is the same as L<Math::PlanePath::DragonCurve/Level Methods>.  Each
level is an unfold (on alternate sides left or right).

=back

=head1 FORMULAS

Various formulas for coordinates, lengths and area can be found in the
author's mathematical write-up

=over

L<http://user42.tuxfamily.org/alternate/index.html>

=back

=head2 Turn

At each point N the curve always turns either left or right, it never goes
straight ahead.  The turn is given by the bit above the lowest 1 bit in N
and whether that position is odd or even.

    N = 0b...z100..00   (including possibly no trailing 0s)
             ^
             pos, counting from 0 for least significant bit

    (z bit) XOR (pos&1)   Turn
    -------------------   ----
             0            right
             1            left

For example N=10 binary 0b1010 has lowest 1 bit at 0b__1_ and the bit above
that is a 0 at even number pos=2, so turn to the right.

=head2 Next Turn

The bits also give the turn after next by looking at the bit above the
lowest 0.

    N = 0b...w011..11    (including possibly no trailing 1s)
             ^
             pos, counting from 0 for least significant bit

    (w bit) XOR (pos&1)    Next Turn
    -------------------    ---------
             0             right
             1             left

For example at N=10 binary 0b1010 the lowest 0 is the least significant bit,
and above that is a 1 at odd pos=1, so at N=10+1=11 turn right.  This works
simply because w011..11 when incremented becomes w100..00 which is the "z"
form above.

The inversion at odd bit positions can be applied with an xor 0b1010..1010.
With that done the turn calculation is then the same as the DragonCurve (see
L<Math::PlanePath::DragonCurve/Turn>).

=head2 Total Turn

The total turn can be calculated from the segment replacements resulting
from the bits of N.

    each bit of N from high to low

      when plain state
       0 -> no change
       1 -> turn left if even bit pos or turn right if odd bit pos
              and go to reversed state

      when reversed state
       1 -> no change
       0 -> turn left if even bit pos or turn right if odd bit pos
              and go to plain state

    (bit positions numbered from 0 for the least significant bit)

This is similar to the DragonCurve (see L<Math::PlanePath::DragonCurve/Total
Turn>) except the turn is either left or right according to an odd or even
bit position of the transition, instead of always left for the DragonCurve.

=head2 dX,dY

Since there's always a turn either left or right, never straight ahead, the
X coordinate changes, then Y coordinate changes, alternately.

        N=0
    dX   1  0  1  0  1  0 -1  0  1  0  1  0 -1  0  1  0  ...
    dY   0  1  0 -1  0  1  0  1  0  1  0 -1  0 -1  0 -1  ...

X changes when N is even, Y changes when N is odd.  Each change is either +1
or -1.  Which it is follows the Golay-Rudin-Shapiro sequence which is parity
odd or even of the count of adjacent 11 bit pairs.

In the total turn above it can be seen that if the 0-E<gt>1 transition is at
an odd position and 1-E<gt>0 transition at an even position then there's a
turn to the left followed by a turn to the right for no net change.
Likewise an even and an odd.  This means runs of 1 bits with an odd length
have no effect on the direction.  Runs of even length on the other hand are
a left followed by a left, or a right followed by a right, for 180 degrees,
which negates the dX change.  Thus

    if N even then dX = (-1)^(count even length runs of 1 bits in N)
    if N odd  then dX = 0

This (-1)^count is related to the Golay-Rudin-Shapiro sequence,

    GRS = (-1) ^ (count of adjacent 11 bit pairs in N)
        = (-1) ^ count_1_bits(N & (N>>1))
        = /  +1 if (N & (N>>1)) even parity
          \  -1 if (N & (N>>1)) odd parity

The GRS is +1 on an odd length run of 1 bits, for example a run 111 is two
11 bit pairs.  The GRS is -1 on an even length run, for example 1111 is
three 11 bit pairs.  So modulo 2 the power in the GRS is the same as the
count of even length runs and therefore

    dX = /  GRS(N)  if N even
         \  0       if N odd

For dY the total turn and odd/even runs of 1s is the same 180 degree
changes, except N is odd for a Y change so the least significant bit is 1
and there's no return to "plain" state.  If this lowest run of 1s starts on
an even position (an odd number of 1s) then it's a turn left for +1.
Conversely if the run started at an odd position (an even number of 1s) then
a turn right for -1.  The result for this last run is the same "negate if
even length" as the rest of the GRS, just for a slightly different reason.

    dY = /  0       if N even
         \  GRS(N)  if N odd

=head2 dX,dY Pair

At a consecutive pair of points N=2k and N=2k+1 the dX and dY can be
expressed together in terms of GRS(k) as

    dX = GRS(2k)
       = GRS(k)

    dY = GRS(2k+1)
       = GRS(k) * (-1)^k
       = /  GRS(k) if k even
         \  -GRS(k) if k odd

For dY reducing 2k+1 to k drops a 1 bit from the low end.  If the second
lowest bit is also a 1 then they were a "11" bit pair which is lost from
GRS(k).  The factor (-1)^k adjusts for that, being +1 if k even or -1 if k
odd.

=head2 dSum

From the dX and dY formulas above it can be seen that their sum is simply
GRS(N),

    dSum = dX + dY = GRS(N)

The sum X+Y is a numbering of anti-diagonal lines,

   | \ \ \
   |\ \ \ \
   | \ \ \ \
   |\ \ \ \ \
   | \ \ \ \ \
   |\ \ \ \ \ \
   +------------
     0 1 2 3 4 5

The curve steps each time either up to the next or back to the previous
according to dSum=GRS(N).

The way the curve visits outside edge X,Y points once each and inner X,Y
points twice each means an anti-diagonal s=X+Y is visited a total of s many
times.  The diagonal has floor(s/2)+1 many points.  When s is odd the first
is visited once and the rest visited twice.  When s is even the X=Y point is
only visited once.  In each case the total is s many visits.

The way the coordinate sum s=X+Y occurs s many times is a geometric
interpretation to the way the cumulative GRS sequence has each value k
occurring k many times.  (See L<Math::NumSeq::GolayRudinShapiroCumulative>.)

=head1 OEIS

The alternate paper folding curve is in Sloane's Online Encyclopedia of
Integer Sequences as

=over

L<http://oeis.org/A106665> (etc)

=back

    A020986   X coordinate unduplicated, X+Y coordinate sum
                being Golay/Rudin/Shapiro cumulative
    A020990   Y coordinate unduplicated, X-Y diff starting from N=1
                being Golay/Rudin/Shapiro * (-1)^n cumulative
    A068915   Y when N even, X when N odd

Since the X and Y coordinates each change alternately, each coordinate
appears twice, for instance X=0,1,1,2,2,3,3,2,2,etc.  A020986 and A020990
are "undoubled" X and Y in the sense of just one copy of each of those
paired values.

    A209615   turn 1=left,-1=right
    A292077   turn 0=left,1=right
    A106665   next turn 1=left,0=right, a(0) is turn at N=1
    A020985   dX and dY alternately, dSum change in X+Y
                being Golay/Rudin/Shapiro sequence +1,-1                
    A020987   GRS with values 0,1 instead of +1,-1

    A077957   Y at N=2^k, being alternately 0 and 2^(k/2)

    A000695   N on X axis, being base 4 digits 0,1 only
    A007088     in base-4
    A151666   predicate 0,1 for N on X axis
    A062880   N on diagonal, being base 4 digits 0,2 only
    A169965     in base-4

    A126684   N single-visited points, either X axis or diagonal
    A176237   N double-visited points

    A270804   N segments of X=Y diagonal stair-step
    A270803     0,1 predicate for these segments

    A022155   N positions of West or South segments,
                being GRS < 0,
                ie. dSum < 0 so move to previous anti-diagonal
    A203463   N positions of East or North segments,
                being GRS > 0,
                ie. dSum > 0 so move to next anti-diagonal

    A212591   N-1 of first time on X+Y=s anti-diagonal
    A047849   N of first time on X+Y=2^k anti-diagonal

    A020991   N-1 of last time on X+Y=s anti-diagonal
    A053644   X of last time on X+Y=s anti-diagonal
    A053645   Y of last time on X+Y=s anti-diagonal
    A080079   X-Y of last time on X+Y=s anti-diagonal

    A093573   N-1 of points on the anti-diagonals d=X+Y,
                by ascending N-1 value within each diagonal
    A004277   num visits in column X

A020991 etc have values N-1, ie. the numbering differs by 1 from the N here,
since they're based on the A020986 cumulative GRS starting at n=0 for value
GRS(0).  This matches the turn sequence A106665 starting at n=0 for the
first turn, whereas for the path here that's N=1.

    A274230   area to N=2^k = double-visited points to N=2^k
    A027556   2*area to N=2^k
    A134057   area to N=4^k
    A060867   area to N=2*4^k
    A122746   area increment N=2^k to N=2^(k+1)
                = num segments West  N=0 to 2^k-1

    A005418   num segments East  N=0 to 2^k-1
    A051437   num segments North N=0 to 2^k-1
    A007179   num segments South N=0 to 2^k-1
    A097038   num runs of 8 consecutive segments within N=0 to 2^k-1
                each segment enclosing a new unit square

    A000225   convex hull area*2, being 2^k-1

    A027383   boundary/2 to N=2^k
               also boundary verticals or horizontals
               (boundary is half verticals half horizontals)
    A131128   boundary to N=4^k
    A028399   boundary to N=2*4^k

    A052955   single-visited points to N=2^k
    A052940   single-visited points to N=4^k, being 3*2^n-1

    A181666   n XOR other(n) occurring at double-visited points
    A086341   graph diameter of level N=0 to 2^k  (for k>=3)

    arms=2
      A062880   N on X axis, base 4 digits 0,2 only

    arms=3
      A001196   N on X axis, base 4 digits 0,3 only

=head1 HOUSE OF GRAPHS

House of Graphs entries for the alternate paperfolding curve as a graph
include

=over

=item level=3, L<https://hog.grinvin.org/ViewGraphInfo.action?id=27008>

=item level=4, L<https://hog.grinvin.org/ViewGraphInfo.action?id=27010>

=item level=5, L<https://hog.grinvin.org/ViewGraphInfo.action?id=27012>

=back

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::AlternatePaperMidpoint>

L<Math::PlanePath::DragonCurve>,
L<Math::PlanePath::CCurve>,
L<Math::PlanePath::HIndexing>,
L<Math::PlanePath::ZOrderCurve>

L<Math::NumSeq::GolayRudinShapiro>,
L<Math::NumSeq::GolayRudinShapiroCumulative>

Michel MendE<232>s France and G. Tenenbaum, "Dimension des Courbes Planes,
Papiers Plies et Suites de Rudin-Shapiro", Bulletin de la S.M.F., volume
109, 1981, pages 207-215.
L<http://www.numdam.org/item?id=BSMF_1981__109__207_0>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018 Kevin Ryde

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
