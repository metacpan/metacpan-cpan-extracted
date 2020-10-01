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




# math-image --path=TerdragonMidpoint --lines --scale=40
#
# math-image --path=TerdragonMidpoint --all --output=numbers_dash --size=78x60
# math-image --path=TerdragonMidpoint,arms=6 --all --output=numbers_dash --size=78x60


package Math::PlanePath::TerdragonMidpoint;
use 5.004;
use strict;
use List::Util 'min'; # 'max'
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 128;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'digit_join_lowtohigh',
  'round_up_pow';
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

# uncomment this to run the ### lines
# use Smart::Comments;


use constant n_start => 0;
use constant parameter_info_array => [ { name        => 'arms',
                                         share_key   => 'arms_6',
                                         display     => 'Arms',
                                         type        => 'integer',
                                         minimum     => 1,
                                         maximum     => 6,
                                         default     => 1,
                                         width       => 1,
                                         description => 'Arms',
                                       } ];

{
  my @x_negative_at_n = (undef, 12, 5, 2, 2, 2, 2);
  sub x_negative_at_n {
    my ($self) = @_;
    return $x_negative_at_n[$self->{'arms'}];
  }
}
{
  my @y_negative_at_n = (undef, 158, 73, 17, 7, 4, 4);
  sub y_negative_at_n {
    my ($self) = @_;
    return $y_negative_at_n[$self->{'arms'}];
  }
}
use constant sumabsxy_minimum => 2; # X=2,Y=0 or X=1,Y=1
sub rsquared_minimum {
  my ($self) = @_;
  return ($self->arms_count < 2
          ? 4   # 1 arm, minimum X=2,Y=0
          : 2); # 2 or more arms, minimum X=1,Y=1
}

use constant dx_minimum => -2;
sub dx_maximum {
  my ($self) = @_;
  return ($self->{'arms'} == 1 ? 1 : 2);
}
use constant dy_minimum => -1;
use constant dy_maximum => 1;

sub _UNDOCUMENTED__dxdy_list {
  my ($self) = @_;
  return ($self->{'arms'} == 1
          ? (1,1,   # NE
             -2,0,  # W
             1,-1)  # SE
          : Math::PlanePath::_UNDOCUMENTED__dxdy_list_six());
}
{
  my @_UNDOCUMENTED__dxdy_list_at_n = (undef,
                                        12, 25, 37,
                                        15, 18, 5);
  sub _UNDOCUMENTED__dxdy_list_at_n {
    my ($self) = @_;
    return $_UNDOCUMENTED__dxdy_list_at_n[$self->{'arms'}];
  }
}

use constant absdx_minimum => 1;
use constant dsumxy_minimum => -2; # diagonals
use constant dsumxy_maximum => 2;
use constant ddiffxy_minimum => -2;
use constant ddiffxy_maximum => 2;

# arms=1 curve goes at 60,180,300 degrees
# arms=2 second +60 to 120,240,0 degrees
# so when arms==1 dir minimum is 60 degrees North-East
#
sub dir_minimum_dxdy {
  my ($self) = @_;
  return ($self->{'arms'} == 1
          ? (1,1)     # North-East
          : (1,0));   # East
}
use constant dir_maximum_dxdy => (1,-1); # South-East

sub _UNDOCUMENTED__turn_any_right_at_n {
  my ($self) = @_;
  # N=5 first right, and on multi-arms 10,15,20,25,30
  return 5*$self->arms_count;
}


#------------------------------------------------------------------------------

# Not quite.
# # all even points when arms==3
# use Math::PlanePath::TerdragonCurve;
# *xy_is_visited = \&Math::PlanePath::TerdragonCurve::xy_is_visited;

sub new {
  my $self = shift->SUPER::new(@_);
  $self->{'arms'} = max(1, min(6, $self->{'arms'} || 1));
  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### TerdragonMidpoint n_to_xy(): $n

  if ($n < 0) { return; }
  if (is_infinite($n)) { return ($n, $n); }

  {
    my $int = int($n);
    if ($n != $int) {
      my ($x1,$y1) = $self->n_to_xy($int);
      my ($x2,$y2) = $self->n_to_xy($int+$self->{'arms'});
      my $frac = $n - $int;  # inherit possible BigFloat
      my $dx = $x2-$x1;
      my $dy = $y2-$y1;
      return ($frac*$dx + $x1, $frac*$dy + $y1);
    }
    $n = $int; # BigFloat int() gives BigInt, use that
  }

  # ENHANCE-ME: own code ...
  #
  require Math::PlanePath::TerdragonCurve;
  my ($x1,$y1) = $self->Math::PlanePath::TerdragonCurve::n_to_xy($n);
  my ($x2,$y2) = $self->Math::PlanePath::TerdragonCurve::n_to_xy($n+$self->{'arms'});

  # dx = x2-x1
  # X = 2 * (x1 + dx/2)
  #   = 2 * (x1 + x2/2 - x1/2)
  #   = 2 * (x1/2 + x2/2)
  #   = x1+x2
  return ($x1+$x2,
          $y1+$y2);
}

# sub n_to_xy {
#   my ($self, $n) = @_;
#   ### TerdragonMidpoint n_to_xy(): $n
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
#
#   my $zero = ($n * 0);  # inherit bignum 0
#
#   ($n, my $rot) = _divrem ($n, $self->{'arms'});
#
#   # ENHANCE-ME: sx,sy just from len,len
#   my @digits;
#   my @sx;
#   my @sy;
#   {
#     my $sx = $zero + 1;
#     my $sy = -$sx;
#     while ($n) {
#       push @digits, ($n % 2);
#       push @sx, $sx;
#       push @sy, $sy;
#       $n = int($n/2);
#
#       # (sx,sy) + rot+90(sx,sy)
#       ($sx,$sy) = ($sx - $sy,
#                    $sy + $sx);
#     }
#   }
#
#   ### @digits
#   my $rev = 0;
#   my $x = $zero;
#   my $y = $zero;
#   my $above_low_zero = 0;
#
#   for (my $i = $#digits; $i >= 0; $i--) {     # high to low
#     my $digit = $digits[$i];
#     my $sx = $sx[$i];
#     my $sy = $sy[$i];
#     ### at: "$x,$y  $digit   side $sx,$sy"
#     ### $rot
#
#     if ($rot & 2) {
#       $sx = -$sx;
#       $sy = -$sy;
#     }
#     if ($rot & 1) {
#       ($sx,$sy) = (-$sy,$sx);
#     }
#     ### rotated side: "$sx,$sy"
#
#     if ($rev) {
#       if ($digit) {
#         $x += -$sy;
#         $y += $sx;
#         ### rev add to: "$x,$y next is still rev"
#       } else {
#         $above_low_zero = $digits[$i+1];
#         $rot ++;
#         $rev = 0;
#         ### rev rot, next is no rev ...
#       }
#     } else {
#       if ($digit) {
#         $rot ++;
#         $x += $sx;
#         $y += $sy;
#         $rev = 1;
#         ### plain add to: "$x,$y next is rev"
#       } else {
#         $above_low_zero = $digits[$i+1];
#       }
#     }
#   }
#
#   # Digit above the low zero is the direction of the next turn, 0 for left,
#   # 1 for right.
#   #
#   ### final: "$x,$y  rot=$rot  above_low_zero=".($above_low_zero||0)
#
#   if ($rot & 2) {
#     $frac = -$frac;  # rotate 180
#     $x -= 1;
#   }
#   if (($rot+1) & 2) {
#     # rot 1 or 2
#     $y += 1;
#   }
#   if (!($rot & 1) && $above_low_zero) {
#     $frac = -$frac;
#   }
#   $above_low_zero ^= ($rot & 1);
#   if ($above_low_zero) {
#     $y = $frac + $y;
#   } else {
#     $x = $frac + $x;
#   }
#
#   ### rotated offset: "$x_offset,$y_offset   return $x,$y"
#   return ($x,$y);
# }


# w^2 = -1+w
# c = (X-Y)/2  x=2c+d
# d = Y        y=d
# (c+dw)/(w+1)
# = (c+dw)*(2-w)/3
#   = (2c-cw + 2dw-dw^2) / 3
#   = (2c-cw + 2dw-d(w-1)) / 3
#   = (2c-cw + 2dw-dw+d)) / 3
#   = (2c+d + w(-c + 2d-d)) / 3
#   = (2c+d + w(d-c)) / 3
#
#   = (x-y+y + w(y - (x-y)/2)) / 3
#   = (x + w((2y-x+y)/2)) / 3
#   = (x + w((3y-x)/2)) / 3
# then
# xq = 2c+d
#    = (2x + (3y-x)/2 ) / 3
#    = (4x + 3y-x)/6
#    = (3x+3y)/6
#    = (x+y)/2
# yq = d = (3y-x)/6
#
# (-1+5w)(2-w)    x=2*-1+5=3,y=5
#    = -2+w+10w-5w^2
#    = -2+11w-5(w-1)
#    = -2+11w-5w+5
#    = 3+6w -> 1+2w
# c=2*-1+5=3 d=-1+5=4
# x=2*1+2=4 y=3
#
# (w+1)*(2-w)
#   = 2w-w^2+2-w
#   = 2w-(w-1)+2-w
#   = 2w-w+1+2-w
#   = 3 -> 1   x=2
#
# 3w*(2-w)         x=3,y=3 div x=3,y(3+3)/2=3
#   = 6w-3w^2
#   = 6w-3(w-1)
#   = 6w-3w+3
#   = 3w+3 -> w+1  x=3,y=1
#
# (w+1)(w+1)
#   = w^2+2w+1
#   = w-1+2w+1
#   = 3w
#

#
# x=3,y=3  (x+y)/2=3

#              X=-3 -2 -1  0  1  2  3
my @yx_to_arm = ([9, 9, 9, 4, 9, 9, 9],  # Y=-2
                 [3, 9, 9, 9, 9, 9, 5],  # Y=-1
                 [9, 9, 9, 9, 9, 9, 9],  # Y=0
                 [2, 9, 9, 9, 9, 9, 0],  # Y=1
                 [9, 9, 9, 1, 9, 9, 9],  # Y= 2
                );

# my @yx_to_dxdy = (undef,undef, -1,1, undef,undef,  0,0, undef,undef, 1,-1,
#                   1,1,  0,0,       -1,-1, -2,0,         0,0,  2,0,
#                   undef,undef, 1,-1, undef,undef, -1,1, undef,undef,  0,0,
#                   0,0,  2,0,         1,1,  0,0,       -1,-1, -2,0,
#                   undef,undef,  0,0, undef,undef, 1,-1, undef,undef, -1,1,
#                   -1,-1, -2,0,         0,0,  2,0,         1,1,  0,0,
#                  );

my @yx_to_dxdy  # 12 each row
  = (undef,undef, undef,undef, 1,1,  undef,undef, undef,undef, undef,undef,
     0,0,  undef,undef, undef,undef, undef,undef, -1,-1, undef,undef,
     undef,undef, -1,1, undef,undef, 0,0,  undef,undef, 1,-1,
     undef,undef, 2,0,  undef,undef, 0,0,  undef,undef, -2,0,
     0,0,  undef,undef, undef,undef, undef,undef, -1,-1, undef,undef,
     undef,undef, undef,undef, 1,1,  undef,undef, undef,undef, undef,undef,
     undef,undef, 2,0,  undef,undef, 0,0,  undef,undef, -2,0,
     undef,undef, -1,1, undef,undef, 0,0,  undef,undef, 1,-1,
     undef,undef, undef,undef, 1,1,  undef,undef, undef,undef, undef,undef,
     0,0,  undef,undef, undef,undef, undef,undef, -1,-1, undef,undef,
     undef,undef, -1,1, undef,undef, 0,0,  undef,undef, 1,-1,
     undef,undef, 2,0,  undef,undef, 0,0,  undef,undef, -2,0,
     0,0,  undef,undef, undef,undef, undef,undef, -1,-1, undef,undef,
     undef,undef, undef,undef, 1,1,  undef,undef, undef,undef, undef,undef,
     undef,undef, 2,0,  undef,undef, 0,0,  undef,undef, -2,0,
     undef,undef, -1,1, undef,undef, 0,0,  undef,undef, 1,-1,
     undef,undef, undef,undef, 1,1,  undef,undef, undef,undef, undef,undef,
     0,0,  undef,undef, undef,undef, undef,undef, -1,-1, undef,undef,
     undef,undef, -1,1, undef,undef, 0,0,  undef,undef, 1,-1,
     undef,undef, 2,0,  undef,undef, 0,0,  undef,undef, -2,0,
     0,0,  undef,undef, undef,undef, undef,undef, -1,-1, undef,undef,
     undef,undef, undef,undef, 1,1,  undef,undef, undef,undef, undef,undef,
     undef,undef, 2,0,  undef,undef, 0,0,  undef,undef, -2,0,
     undef,undef, -1,1, undef,undef, 0,0,  undef,undef, 1,-1,
    );

my @x_to_digit = (1, 2, 0);  # digit = X+1 mod 3

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### TerdragonMidpoint xy_to_n(): "$x, $y"

  $x = round_nearest($x);
  $y = round_nearest($y);

  if (is_infinite($x)) {
    return $x;  # infinity
  }
  if (is_infinite($y)) {
    return $y;  # infinity
  }
  my $zero = ($x * 0 * $y); # inherit bignum 0
  my @ndigits;     # low to high;

  for (;;) {
    my $digit = $x_to_digit[$x%3];

    my $k = 2*(12*($y%12) + ($x%12));
    my $dx = $yx_to_dxdy[$k++];
    if (! defined $dx) {
      ### not a visited point: "k=$k"
      ### x mod 12: $x%12
      ### y mod 12: $y%12
      return undef;
    }

    ### at: "$x,$y (k=$k)  digit=$digit k=$k  offset=$yx_to_dxdy[$k-1],$yx_to_dxdy[$k] to ".($x+$yx_to_dxdy[$k-1]).",".($y+$yx_to_dxdy[$k])

    push @ndigits, $digit;
    $x += $dx;
    $y += $yx_to_dxdy[$k];

    last if ($x <= 3 && $x >= -3 && $y <= 2 && $y >= -2);

    ### assert: ($x+$y) % 2 == 0
    ### assert: $x % 3 == 0
    ### assert: (3 * $y - $x) % 6 == 0
    ($x,$y) = (($x+$y)/2,    # divide w+1
               ($y-$x/3)/2);
    ### divide down to: "$x,$y"
  }

  ### final: "xy=$x,$y"

  my $arm = $yx_to_arm[$y+2][$x+3] || 0;   # 0 to 5
  ### $arm

  my $arms_count = $self->arms_count;
  if ($arm >= $arms_count) {
    return undef;
  }
  if ($arm & 1) {
    ### flip ...
    @ndigits = map {2-$_} @ndigits;
  }

  return digit_join_lowtohigh(\@ndigits, 3, $zero) * $arms_count + $arm;
}

# quarter size of TerdragonCurve
#
# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### TerdragonCurve rect_to_n_range(): "$x1,$y1  $x2,$y2"
  my $xmax = int(max(abs($x1),abs($x2)));
  my $ymax = int(max(abs($y1),abs($y2)));
  return (0,
          int (($xmax*$xmax + 3*$ymax*$ymax + 1)
               / 2)
          * $self->{'arms'});
}

#-----------------------------------------------------------------------------
# level_to_n_range()

# 3^level segments, one midpoint each
# arms*3^level when multi-arm
# numbered starting 0
#
sub level_to_n_range {
  my ($self, $level) = @_;
  return (0,  3**$level * $self->{'arms'} - 1);
}
sub n_to_level {
  my ($self, $n) = @_;
  if ($n < 0) { return undef; }
  if (is_infinite($n)) { return $n; }
  $n = round_nearest($n);
  _divrem_mutate ($n, $self->{'arms'});
  my ($pow, $exp) = round_up_pow ($n+1, 3);
  return $exp;
}

#-----------------------------------------------------------------------------
1;
__END__



    #                               72----66----60----54
    #                                 \              /
    #          55                      78          48
    #         /  \                       \        /
    #       61    49          96----90----84    42
    #      /        \                          /
    #    67          43          19          36
    #   /              \        /  \        /
    # 73----79----85    37    25    13    30----24----18
    #            /        \  /        \              /
    #          91          31           7          12
    #         /                          \        /
    #       97    20----14-----8-----2     1     6    35----41----47--...
    #               \                          /        \
    #                26           3           0          29
    #                  \        /                          \
    #   ...-44----38----32     9     4     5----11----17----23    100
    #                        /        \                          /
    #                      15          10          34          94
    #                     /              \        /  \        /
    #                   21----27----33    16    28    40    88----82----76
    #                              /        \  /        \              /
    #                            39          22          46          70
    #                           /                          \        /
    #                         45    87----93----99          52    64
    #                        /        \                       \  /
    #                      51          81                      58
    #                     /              \
    #                   57----63----69----75




=for stopwords eg Ryde Terdragon Math-PlanePath Nlevel Davis Knuth et al terdragon ie Xadj Yadj

=head1 NAME

Math::PlanePath::TerdragonMidpoint -- dragon curve midpoints

=head1 SYNOPSIS

 use Math::PlanePath::TerdragonMidpoint;
 my $path = Math::PlanePath::TerdragonMidpoint->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

X<Davis>X<Knuth, Donald>This is midpoints of an integer version of the
terdragon curve by Davis and Knuth.

                      30----29----28----27                      13
                        \              /
                         31          26                         12
                           \        /
    36----35----34----33----32    25                            11
      \                          /
       37          41          24                               10
         \        /  \        /
          38    40    42    23----22----21                       9
            \  /        \              /
             39          43          20                          8
                           \        /
    48----47----46----45----44    19    12----11----10-----9     7
      \                          /        \              /
       49                      18          13           8        6
         \                    /              \        /
    ...---50                17----16----15----14     7           5
                                                   /
                                                  6              4
                                                /
                                               5-----4-----3     3
                                                         /
                                                        2        2
                                                      /
                                                     1           1
                                                   /
                                                  0         <- Y=0

        ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^
      -12-11-10 -9 -8 -7 -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5 ...

The points are the middle of each edge of a double-size C<TerdragonCurve>.

                            ...
                              \
      6             -----8-----      double size
                    \                TerdragonCurve
                     \               giving midpoints
      5               7
                       \
                        \
      4        -----6---- _
               \         / \
                \       /   \
      3          5     4     3
                  \   /       \
                   \_/         \
      2              _----2-----
                     \
                      \
      1                1
                        \
                         \
    Y=0 ->    +-----0-----.

              ^
             X=0 1  2  3  4  5  6

For example in the C<TerdragonCurve> N=3 to N=4 is X=3,Y=1 to X=2,Y=2 and
that's doubled out here to X=6,Y=2 and X=4,Y=4 then the midpoint of those
positions is X=5,Y=3 for N=3 in the C<TerdragonMidpoint>.

The result is integer X,Y coordinates on every second point per
L<Math::PlanePath/Triangular Lattice>, but visiting only 3 of every 4 such
triangular points, which in turn is 3 of 8 all integer X,Y points.  The
points used are a pattern of alternate rows with 1 of 2 points and 1 of 4
points.  For example the Y=7 row is 1 of 2 and the Y=8 row is 1 of 4.
Notice the pattern is the same when turned by 60 degrees.

    * * * * * * * * * * * * * * * * * * * *
     *   *   *   *   *   *   *   *   *   *
    * * * * * * * * * * * * * * * * * * * *
       *   *   *   *   *   *   *   *   *
    * * * * * * * * * * * * * * * * * * * *
     *   *   *   *   *   *   *   *   *   *
    * * * * * * * * * * * * * * * * * * * *
       *   *   *   *   *   *   *   *   *
    * * * * * * * * * * * * * * * * * * * *
     *   *   *   *   *   *   *   *   *   *
    * * * * * * * * * * * * * * * * * * * *
       *   *   *   *   *   *   *   *   *
    * * * * * * * * * * * * * * * * * * * *
     *   *   *   *   *   *   *   *   *   *
    * * * * * * * * * * * * * * * * * * * *

=head2 Arms

Multiple copies of the curve can be selected, each advancing successively.
Like the main C<TerdragonCurve> the midpoint curve covers 1/6 of the plane
and 6 arms rotated by 60, 120, 180, 240 and 300 degrees mesh together
perfectly.  With 6 arms all the alternating "1of2" and "1of4" points
described above are visited.

C<arms =E<gt> 6> begins as follows.  N=0,6,12,18,etc is the first arm (like
the single curve above), then N=1,7,13,19 the second copy rotated 60
degrees, N=2,8,14,20 the third rotated 120, etc.

     arms=>6                                 ...
                                             /
             ...                           42
               \                          /
                43          19          36
                  \        /  \        /
                   37    25    13    30----24----18
                     \  /        \              /
                      31           7          12
                                    \        /
             20----14-----8-----2     1     6    35----41----47-..
               \                          /        \
                26           3     .     0          29
                  \        /                          \
    ..-44----38----32     9     4     5----11----17----23
                        /        \
                      15          10          34
                     /              \        /  \
                   21----27----33    16    28    40
                              /        \  /        \
                            39          22          46
                           /                          \
                         45                            ...
                        /
                      ...

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::TerdragonMidpoint-E<gt>new ()>

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

Return C<(0, 3**$level - 1)>, or for multiple arms return C<(0, $arms *
3**$level - 1)>.

There are 3^level segments comprising the terdragon, or arms*3^level when
multiple arms, numbered starting from 0.

=back

=head1 FORMULAS

=head2 X,Y to N

An X,Y point can be turned into N by dividing out digits of a complex base
b=w+1 where

    w = 1/2 + i * sqrt(3)/2            w^2     w
      = 6th root of unity                 \   /
                                           \ /
                                w^3=-1 -----o------ w^0=1
                                           / \
                                          /   \
                                       w^4     w^5

At each step the low ternary digit is formed from X,Y and an adjustment
applied to move X,Y onto a multiple of w+1 ready to divide out w+1.

In the N points above it can be seen that each group of three N values make
a straight line, such as N=0,1,2, or N=3,4,5 etc.  The adjustment moves the
two ends N=0mod3 or N=2mod3 to the centre N=1mod3.  The centre N=1mod3
position is always a multiple of w+1.

The angles and positions for the N triples follow a 12-point pattern as
follows, where each / \ or - is a point on the path (any arm).

     \   /   /   \   /   /   \   /   /   \   /   /   \
    - \ / \ - - - \ / \ - - - \ / \ - - - \ / \ - - -
       /   \   /   /   \   /   /   \   /   /   \   /
    \ - - - \ / \ - - - \ / \ - - - \ / \ - - - \ / \
     \   /   /   \   /   /   \   /   /   \   /   /   \
    - \ / \ - - - \ / \ - - - \ / \ - - - \ / \ - - -
       /   \   /   /   \   /   /   \   /   /   \   /
    \ - - - \ / \ - - - \ / \ - - - \ / \ - - - \ / \
     \   /   /   \   /   /   \   /   /   \   /   /   \
    - \ / \ - - - \ / \ - - - \ / \ - - - \ / \ - - -
       /   \   /   /   \   /   /   \   /   /   \   /
    \ - - - \ / \ - - - \ / \ - - - \ / \ - - - \ / \
     \   /   /   \   /   /   \   /   /   \   /   /   \
    - \ / \ - - - \ / \ - - - \ / \ - - - \ / \ - - -
       /   \   /   /   \   /   /   \   /   /   \   /
    \ - - - \ / \ - - - \ / \ - - - \ / \ - - - \ / \
     \   /   /   \   /   /   \   /   /   \   /   /   \
    - \ / \ - - - \ / \ - - - \ / \ - - - \ / \ - - -
       /   \   /   /   \   /   /   \   /   /   \   /
    \ - - - \ / \ - - - \ / \ - - - \ / \ - - - \ / \
     \   /   /   \   /   /   \   /   /   \   /   /   \
    - \ / \ - - - \ / \ - - - \ / \ - - - \ / \ - - -
       /   \   /   /   \   /   /   \   /   /   \   /
    \ - - - \ / \ - - - \ / \ - - - \ / \ - - - \ / \

In the current code a 12x12 table is used, indexed by X mod 12 and Y mod 12.
With Xadj and Yadj from there

    Ndigit = (X + 1) mod 3      # N digits low to high

    Xm = X + Xadj[X mod 12, Y mod 12]
    Ym = Y + Yadj[X mod 12, Y mod 12]

    new X,Y = (Xm,Ym) / (w+1)
            = (Xm,Ym) * (2-w) / 3
            = ((Xm+Ym)/2, (Ym-(Xm/3))/2)

Is there a good aX+bY mod 12 or mod 24 for a smaller table?  Maybe X+3Y like
the digit?  Taking C=(X-Y)/2 in triangular coordinate style can reduce the
table to 6x6.

Points not reached by the curve (ie. not the 3 of 4 triangular or 3 of 8
rectangular described above) can be detected with C<undef> or suitably
tagged entries in the adjustment table.

The X,Y reduction stops at the midpoint of the first triple of the
originating arm.  So X=3,Y=1 which is N=1 for the first arm, and that point
rotated by 60,120,180,240,300 degrees for the others.  If only some of the
arms are of interest then reaching one of the others means the original X,Y
was outside the desired region.

    Arm     X,Y Endpoint
    ---     ------------
     0        3,1
     1        0,2
     2       -3,1
     3       -3,-1
     4        0,-2
     5        3,-1

For the odd arms 1,3,5 each digit of N must be flipped 2-digit so 0,1,2
becomes 2,1,0,

    if arm odd
    then  N = 3**numdigits - 1 - N

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::TerdragonCurve>,
L<Math::PlanePath::TerdragonRounded>

L<Math::PlanePath::DragonMidpoint>,
L<Math::PlanePath::R5DragonMidpoint>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019 Kevin Ryde

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
