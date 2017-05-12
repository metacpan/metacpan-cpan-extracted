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


#------------------------------------------------------------------------------
# cf A153003  total cells  0, 1, 4, 7, 10
#    A153004  added cells    +1, 3, 3, 3, 6
#    A153005  total which are primes
#      clipping parts=4 pattern to 3 quadrants,
#      X=0,Y=0 as a half toothpick not counted
#      X=0,Y=-1 as a half toothpick not counted
#      X=1,Y=-1 "root" would begin at depth=1, or count it as child of 1
#
#         |       |
#         2---1---2
#         |   |   |
#             X
#             |   |
#          ---X---2
#                 |
#
#------------------------------------------------------------------------------
# A160740 toothpick starting from 4 as cross
#   doesn't maintain XYeven=vertical, XYodd=horizontal
#             |
#             *
#             |
#      ---*--- ---*---
#             |
#             *
#             |
# A160426 cross with one long end for 5 initial toothpicks
# A160730 right angle of 2 toothpicks
# A168112 45-degree something related to 2 toothpick right-angle
# A160732 T of 3 toothpicks
#
#------------------------------------------------------------------------------
# cf A183004 toothpicks placed at ends, alternately vert,horiz
#    A183005 added  0,1,4,6,8,8,16,22,16,8,16,
#
#    .-4-.-4-.-4-.-4-            middle "3" touch two ends
#        3       3               counts just once
#    .   .-2-.-2-.
#        3   1   3
#    .   .-2-.-2-.
#        3       3
#    .-4-.-4-.-4-.-4-.
#
#------------------------------------------------------------------------------
# cf A160172 T-toothpick sequence
#
# A139250 total cells OFFSET=0 value=0
#    a(2^k) = A007583(k) = (2^(2n+1) + 1)/3
#    a(2^k-1) = A000969(2^k-2), A000969=floor (2*n+3)*(n+1)/3
# A139251 cells added
#   a(2^i)=2^i
#   a(2^i+j) = 2a(j)+a(j+1
#   0, 1, 2,
#   4,  4,
#   4, 8, 12, 8,
#   4, 8, 12, 12, 16, 28, 32, 16,
#   4, 8, 12, 12, 16, 28, 32, 20, 16, 28, 36, 40, 60, 88, 80, 32,
#   4, 8, 12, 12, 16, 28, 32, 20, 16, 28, 36, 40, 60, 88, 80, 36, 16, 28, 36, 40, 60, 88, 84, 56, 60, 92, 112, 140, 208, 256, 192, 64,
#   4, 8, 12, 12, 16, 28, 32, 20, 16, 28

# A160570 triangle, row sums are toothpick cumulative
# A160552 a(2^i+j)=2*a(j)+a(j+1) starting 0,1
# A151548  A160552 row 2^k totals
# A151549   half A151548
# A160762 convolution
#
# cf A160808 count cells Fibonacci spiral
#    A160809 cells added Fibonacci spiral
#
#    A160164 "I"-toothpick
#    A187220 gull

# "Q"
# A187210, A211001-A211003, A211010, A211020-A211024.
# A211011
# A210838 Coordinates (x,y) of the endpoint
# A210841 Coordinates (x,y) of the endpoint
# A211000 Coordinates (x,y) of the endpoint inflection at primes
# http://www.njohnston.ca/2011/03/the-q-toothpick-cellular-automaton/
# maybe hearts A188346 == toothpicks A139250
#
# T(level) = 4 * T(level-1) + 2
# T(level) = 2 * (4^level - 1) / 3
# total = T(level) + 2
# N = (4^level - 1)*2/3
# 4^level - 1 = 3*N/2
# 4^level = 3*N/2 + 1
#
# len=2^level
# total = (len*len-1)*2/3 + 2


#  |     |     |
#  * -*- * -*- *
#  |     |     |
#     |     |
# -*- o -*- * -*-
#     |     |
#  |     |     |
#  * -*- * -*- *
#  |     |     |
#
#------------------------------------------------------------------------------


package Math::PlanePath::ToothpickTree;
use 5.004;
use strict;
use Carp 'croak';
#use List::Util 'max','min';
*max = \&Math::PlanePath::_max;
*min = \&Math::PlanePath::_min;

use vars '$VERSION', '@ISA';
$VERSION = 18;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_down_pow';

# uncomment this to run the ### lines
# use Smart::Comments;


# Note: some of this shared with ToothpickReplicate
#
use constant n_start => 0;
use constant parameter_info_array =>
  [ { name      => 'parts',
      share_key => 'parts_toothpicktree',
      display   => 'Parts',
      type      => 'enum',
      default   => '4',
      choices   => ['4','3','2','1','octant','octant_up',
                    'wedge','two_horiz',
                   ],
      choices_display => ['4','3','2','1','Octant','Octant Up',
                          'Wedge','Two Horiz',
                         ],
      description => 'Which parts of the pattern to generate.',
    },
  ];

use constant class_x_negative => 1;
use constant class_y_negative => 1;
{
  my %x_negative = (4         => 1,
                    3         => 1,
                    2         => 1,
                    1         => 0,
                    octant    => 0,
                    octant_up => 0,
                    wedge     => 1,
                    'wedge+1' => 1,
                    two_horiz => 1,
                   );
  sub x_negative {
    my ($self) = @_;
    return $x_negative{$self->{'parts'}};
  }
}
{
  my %x_minimum = (1         => 1,
                   octant    => 1,
                   octant_up => 1,
                   # otherwise no minimum so undef
                  );
  sub x_minimum {
    my ($self) = @_;
    return $x_minimum{$self->{'parts'}};
  }
}
{
  my %y_negative = (4         => 1,
                    3         => 1,
                    2         => 0,
                    1         => 0,
                    octant    => 0,
                    octant_up => 0,
                    wedge     => 0,
                    two_horiz => 1,
                   );
  sub y_negative {
    my ($self) = @_;
    return $y_negative{$self->{'parts'}};
  }
}
{
  my %y_minimum = (2         => 1,
                   1         => 1,
                   octant    => 1,
                   octant_up => 2,
                   wedge     => 0,
                   'wedge+1' => -1,
                   # otherwise no minimum, undef
                  );
  sub y_minimum {
    my ($self) = @_;
    return $y_minimum{$self->{'parts'}};
  }
}

{
  my %x_negative_at_n = (4         => 4,
                         3         => 5,
                         2         => 2,
                         1         => undef,
                         octant    => undef,
                         octant_up => undef,
                         wedge     => 3,
                         'wedge+1' => 1,
                         two_horiz => 1,
                        );
  sub x_negative_at_n {
    my ($self) = @_;
    return $x_negative_at_n{$self->{'parts'}};
  }
}
{
  my %y_negative_at_n = (4         => 2,
                         3         => 1,
                         2         => undef,
                         1         => undef,
                         octant    => undef,
                         octant_up => undef,
                         wedge     => undef,
                         'wedge+1' => 1,
                         two_horiz => 4,
                        );
  sub y_negative_at_n {
    my ($self) = @_;
    return $y_negative_at_n{$self->{'parts'}};
  }
}

{
  my %sumxy_minimum = (1         => 2,  # X=1,Y=1
                       octant    => 2,  # X=1,Y=1
                       octant_up => 3,  # X=1,Y=2
                       wedge     => 0,  # X=0,Y=0
                       'wedge+1' => -1,
                       # otherwise no minimum, undef
                      );
  sub sumxy_minimum {
    my ($self) = @_;
    return $sumxy_minimum{$self->{'parts'}};
  }
}
{
  my %sumabsxy_minimum = (2         => 1,  # X=1,Y=0
                          1         => 2,  # X=1,Y=1
                          octant    => 2,  # X=1,Y=1
                          octant_up => 3,  # X=1,Y=2
                          wedge     => 0,  # X=0,Y=0
                         );
  sub sumabsxy_minimum {
    my ($self) = @_;
    return ($sumabsxy_minimum{$self->{'parts'}} || 0);
  }
}

{
  my %diffxy_minimum = (octant    => -1,  # X=1,Y=2
                       );
  sub diffxy_minimum {
    my ($self) = @_;
    return $diffxy_minimum{$self->{'parts'}};
  }
}
{
  my %diffxy_maximum = (octant_up => 0,  # Y>=X so X-Y<=0
                        wedge     => 0,  # Y>=X so X-Y<=0
                        'wedge+1' => 1,
                       );
  sub diffxy_maximum {
    my ($self) = @_;
    return $diffxy_maximum{$self->{'parts'}};
  }
}

{
  my %rsquared_minimum = (2         => 1,  # X=0,Y=1
                          1         => 2,  # X=1,Y=1
                          octant    => 2,  # X=1,Y=1
                          octant_up => 5,  # X=1,Y=2
                          # otherwise 0
                         );
  sub rsquared_minimum {
    my ($self) = @_;
    return ($rsquared_minimum{$self->{'parts'}} || 0);
  }
}
use constant tree_num_children_list => (0,1,2);


# parts=1 Dir4 max 5,-4
#                 14,-9
#                 62,-33
#                126,-65
#            2*2^k-2, -2^k+1   -> 2,-1
# parts=3 same as parts=1
#
# parts=4 dX=0,dY=-1 South, apparently
{
  my %dir_maximum_dxdy = (4         => [0,-2], # at N=1 South dX=0,dY=-2
                          2         => [0,0],  # supremum, dX=big,dY=-1
                          3         => [2,-1], # supremum
                          1         => [2,-1], # supremum
                          octant    => [1,-2], # at N=4
                          octant_up => [0,-2], # at N=16 South
                          wedge     => [0,-2], # at N=35 South
                          'wedge+1' => [0,0],  # supremum, dX=big,dY=-1
                          two_horiz => [0,0],  # supremum, dX=big,dY=-1
                         );
  sub dir_maximum_dxdy {
    my ($self) = @_;
    return @{$dir_maximum_dxdy{$self->{'parts'}}};
  }
}

#------------------------------------------------------------------------------

# add to $depth to give parts=4 style numbering
my %parts_depth_adjust = (4         => 0,
                          3         => 0,
                          2         => 1,
                          1         => 2,
                          octant    => 2,
                          octant_up => 2,
                          wedge     => -1,
                          # 'wedge+1' => 0, # not working
                          two_horiz => 2,
                         );

sub new {
  my $self = shift->SUPER::new(@_);
  my $parts = ($self->{'parts'} ||= 4);
  if (! exists $parts_depth_adjust{$parts}) {
    croak "Unrecognised parts: ",$parts;
  }
  return $self;
}


#------------------------------------------------------------------------------
# n_to_xy()

my %initial_n_to_xy
  = (4         => [ [0,0], [0,1], [0,-1],  [1,1], [-1,1], [-1,-1], [1,-1] ],
     3         => [ [0,0], [0,-1], [0,1], [1,-1], [1,1], [-1,1] ],
     2         => [ [0,1], [1,1], [-1,1] ],
     # 1         => [ ],
     # octant    => [ ],
     # octant_up => [ ],
     wedge     => [ [0,0],  [0,1],         [1,1],[-1,1] ],
     # 'wedge+1' => [ [0,0],  [0,1],[0,-1],  [1,1],[-1,1] ],
     two_horiz   => [ [1,0],[-1,0],  [2,0],[-2,0],
                      [2,-1],[2,1],[-2,1],[-2,-1] ],
    );

sub n_to_xy {
  my ($self, $n) = @_;
  ### ToothpickTree n_to_xy(): $n

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
  my $zero = $n*0;

  my $parts = $self->{'parts'};

  if (my $initial = $initial_n_to_xy{$parts}) {
    if ($n <= $#$initial) {
      ### initial_n_to_xy{}: $initial->[$n]
      return @{$initial->[$n]};
    }
  }

  (my $depth, $n) = _n0_to_depth_and_rem($self, $n);
  ### $depth
  ### remainder n: $n

  # $hdx,$hdy is the dx,dy offsets which is "horizontal".  Initially this is
  # hdx=1,hdy=0 so horizontal along the X axis, but subsequent blocks rotate
  # around or mirror to point other directions.
  #
  # $vdx,$vdy is similar dx,dy which is "vertical".  Initially vdx=0,vdy=1
  # so vertical along the Y axis.
  #
  # $mirror is true if in a "mirror image" block.  The difference is that in
  # a plain block points are numbered around anti-clockwise, but when
  # mirrored they're numbered clockwise.
  #
  my $x = 0;
  my $y = 0;
  my $hdx = 1;
  my $hdy = 0;
  my $vdx = 0;
  my $vdy = 1;
  my $mirror = 0;
  $depth += $parts_depth_adjust{$parts};
  ### depth in parts=4 style: $depth

  if ($parts eq 'octant') {

  } elsif ($parts eq 'octant_up') {
    $mirror = 1;
    $y = 1;
    $hdx = 0; $hdy = 1;  # initial transpose X,Y
    $vdx = 1; $vdy = 0;

  } elsif ($parts eq 'wedge') {
    $y = 1;
    $hdx = 0; $hdy = 1; $vdy = 0;
    my $add = _depth_to_octant_added([$depth],[1],$zero);
    if ($n < $add) {
      # right half
      $mirror = 1;
      $vdx = 1;
    } else {
      # left half
      $n -= $add;
      $vdx = -1;
    }

  } elsif ($parts eq 'two_horiz') {
    my $add = _depth_to_octant_added([$depth],[1],$zero);
    if ($n < $add) {
      ### first eighth ...
      $hdx = 0; $hdy = -1; $vdx = 1; $vdy = 0;
      $y = 1;
    } else {
      my $add3 = _depth_to_octant_added([$depth-3],[1],$zero);
      my $quad = $add + $add3 - 1;
      my $half = 2*$quad;
      ### $add
      ### $add3
      ### $quad
      ### $half
      if ($n >= $half) {
        $n -= $half;
        $hdx = -1; $vdy = -1;  # rotate 180
      }
      if ($n < $quad) {
        if ($n < $add) {
          ### fifth octant ...
          $hdx = 0; $hdy = 1; $vdx = -1; $vdy = 0;
          $y = -1;

        } else {
          ### second/sixth eighth ...
          $n -= $add - 1;  # and unduplicate spine
          $x = 2*$hdx;
          $depth -= 3;
          $mirror = 1;
          $hdy = -$hdy; $vdy = -$vdy; # reflect across X axis
        }
      } else {
        $n -= $quad;
        if ($n < $add3-1) {
          ### third/seventh eighth ...
          $depth -= 3;
          $x = 2*$hdx;
        } else {
          ### fourth/eighth eighth ...
          $n -= $add3-1;
          $y = -$vdy;
          $mirror = 1;
          ($hdx,$hdy, $vdx,$vdy) = ($vdx,$vdy, $hdx,$hdy);   # transpose X,Y
        }
      }
    }

  } else {
    my $add = _depth_to_octant_added([$depth],[1],$zero);
    ### $add

    if ($parts eq '3') {
      my $add_plus1 = _depth_to_octant_added([$depth+1],[1],$zero);
      my $add_quad = $add_plus1 + $add - 1;
      ### parts=3 lower quad: $add_quad
      if ($n < $add_quad) {
        ### initial block 1, rotate 90 ...
        $depth += 1;
        $add = $add_plus1;
        $x = -1;
        $hdx = 0; $hdy = -1; $vdx = 1; $vdy = 0;
        $parts = '1';
      } else {
        # now parts=2 style remaining
        $n -= $add_quad;
      }
    }

    if ($parts ne '1') {
      my $add_sub1 = _depth_to_octant_added([$depth-1], [1], $zero);
      my $add_quad = $add + $add_sub1 - 1;

      if ($parts eq '4') {
        my $add_half = 2*$add_quad;
        if ($n >= $add_half) {
          $n -= $add_half;
          $hdx = -1; $vdy = -1;  # rotate 180
        }
      }

      # parts=2 style two quadrants
      if ($n >= $add_quad) {
        ### second quadrant ...
        $n -= $add_quad;

        if ($n >= $add_sub1) {
          ### fourth octant ...
          $n -= $add_sub1;
          $n += 1;  # unduplicate diagonal
          $mirror = 1;
          $hdx = -$hdx; $hdy = -$hdy; # reflect horizontally
        } else {
          ### third octant ...
          $depth -= 1;
          ($hdx,$hdy, $vdx,$vdy)    # rotate -90
            = ($vdx,$vdy, -$hdx,-$hdy);
          $x += $hdx;
          $y += $hdy;
        }
        $add = $n+1;
      }
    }

    ### first quadrant split: "add=$add   n=$n depth=$depth"
    if ($n >= $add) {
      ### top half of quad ...
      $depth -= 1;
      $n -= $add;
      $n += 1;  # unduplicate diagonal
      $mirror ^= 1;
      $x += $vdx;
      $y += $vdy;
      ($hdx,$hdy, $vdx,$vdy)    # transpose X,Y
        = ($vdx,$vdy, $hdx,$hdy);
      ### transpose to: "hdxy=$hdx,$hdy  vdxy=$vdx,$vdy  n=$n depth=$depth"
    }
  }
  ### in parts=4 style: "n=$n depth=$depth   x=$x y=$y   hdxy=$hdx,$hdy vdxy=$vdx,$vdy"

  my ($pow,$exp) = round_down_pow ($depth, 2);
  for ( ; --$exp >= 0; $pow /=2) {
    ### at: "pow=$pow depth=$depth n=$n mirror=$mirror  xy=$x,$y  h=$hdx,$hdy v=$vdx,$vdy"

    if ($depth < $pow) {
      ### block 0 ...
      next;
    }
    $depth -= $pow;

    if ($depth == $pow-1) {
      ### pow-1 end toothpick ...
      $x += $pow * ($hdx + $vdx) - $hdx;
      $y += $pow * ($hdy + $vdy) - $hdy;
      last;
    }

    $x += $pow/2 * ($hdx + $vdx);
    $y += $pow/2 * ($hdy + $vdy);
    ### diagonal to: "depth=$depth  xy=$x,$y"

    if ($depth == 0) {
      ### toothpick A ...
      last;
    }
    if ($depth == 1) {
      ### toothpick B,other up,down ...
      if ($exp && $n == $mirror) {
        ### toothpick other (down): "subtract vdxdy=$vdx,$vdy"
        $x -= $vdx;
        $y -= $vdy;
      } else {
        ### toothpick B (up): "add vdxdy=$vdx,$vdy"
        $x += $vdx;
        $y += $vdy;
      }
      last;
    }

    if ($mirror) {
      #     /
      #    /3
      #   /--
      #  /|\2
      # /0|1\
      my $add = _depth_to_octant_added([$depth],[1],$zero);
      ### add in mirror block2,3: $add

      if ($n < $add) {
        ### mirror block 3, same ...
        next;
      }
      $n -= $add;

      if ($n < $add) {
        ### mirror block 2, unmirror, vertical invert ...
        $vdx = -$vdx;
        $vdy = -$vdy;
        $mirror = 0;
        next;
      }
      $n -= $add;
      $n += 1;  # undouble upper/lower diagonal

      ### mirror block 1, rotate 90 ...
      ### assert: $n < _depth_to_octant_added([$depth+1],[1],$zero);
      $depth += 1;
      $x -= $hdx; # offset
      $y -= $hdy;
      ($hdx,$hdy, $vdx,$vdy)    # rotate 90 in direction v toward h
        = (-$vdx,-$vdy, $hdx,$hdy);

    } else {
      ### assert: $mirror==0
      #     /
      #    /3
      #   /--
      #  /|\2
      # /0|1\

      if ($depth+1 < $pow) {
        my $add = _depth_to_octant_added([$depth+1],[1],$zero) - 1;
        ### add in block1, sans diagonal: $add
        if ($n < $add) {
          ### block 1 "lower", rotate +90 ...
          $depth += 1;
          $x -= $hdx; # offset
          $y -= $hdy;
          ($hdx,$hdy, $vdx,$vdy)    # rotate 90 in direction v toward h
            = (-$vdx,-$vdy, $hdx,$hdy);
          next;
        }
        $n -= $add;
      }

      my $add = _depth_to_octant_added([$depth],[1],$zero);
      ### add in block2: $add

      if ($n < $add) {
        ### block 2 "upper", vertical invert ...
        $vdx = -$vdx;
        $vdy = -$vdy;
        $mirror = 1;
      } else {
        ### block 3 "extend", same ...
        $n -= $add;
        ### assert: $n < $add
      }
    }
  }

  ### n_to_xy() return: "$x,$y  (depth=$depth n=$n)"
  return ($x,$y);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### ToothpickTree xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);

  my $zero = $x * 0 * $y;
  my $n = $zero;
  my @add_offset;
  my @add_mult;
  my $mirror = 0;
  my $depth = 0;
  my $depth_adjust = 0;

  my $parts = $self->{'parts'};

  if ($parts eq 'octant') {
    # if ($x < 1 || $y < 1 || $y > $x+1) { return undef; }
    $depth_adjust = 2;

  } elsif ($parts eq 'octant_up') {
    # if ($x > $y || $x < 1 || $y < 2) { return undef; }
    ($x,$y) = ($y-1,$x);
    $mirror = 1;
    $depth_adjust = 2;

  } elsif ($parts eq 'wedge') {
    if ($x > $y || $x < -$y) { return undef; }
    $depth_adjust = -1;
    $y -= 1;
    if ($y <= 0) {
      if ($y < 0) { return 0; }  #  X=0,Y=0 N=0
      # otherwise Y=1
      if ($x == 0) { return 1; }
      if ($x == 1) { return 2; }
      if ($x == -1) { return 3; }
    }

    if ($x >= 0) {
      ### wedge X positive half, transpose ...
      ($x,$y) = ($y,$x);
      $mirror = 1;
    } else {
      ### wedge X negative half, rotate -90 ...
      ($x,$y) = ($y,-$x);  # rotate -90
      push @add_offset, 0;
      push @add_mult, 1;
    }
    ### wedge: "x=$x y=$y"

  } elsif ($parts eq 'two_horiz') {
    if ($x == -1 && $y == 0) { return 1; }
    if ($x == -2 && $y == 0) { return 3; }

    my $mult = 0;
    my $mult3 = 0;
    if ($x < 0) {
      $x = -$x; $y = -$y;  # rotate 180
      $mult = 2;
      $mult3 = 2;
      $n -= 2; # unduplicate shared diagonals in first two quarters
      ### rotate 180 to: "$x,$y"
    }
    if ($y > 0) {
      $mult++;
      $mult3++;
      $n -= 1; # unduplicate shared diagonal in first quarter
      if ($x < $y+2) {
        ### fourth/eighth eighth ...
        $depth_adjust = 2;
        $mult3++;
        $n -= 1; # unduplicate shared diagonal
        ($x,$y) = ($y+1,$x);  # transpose and offset
        $mirror = 1;
      } else {
        ### third/seventh eighth ...
        $x -= 2;
        $depth_adjust = -1;
      }
    } else { # $y < 0
      if ($x > 2-$y) {
        ### second/sixth eighth ...
        $y = -$y;  # mirror across X axis
        $x -= 2;
        $mirror = 1;
        $mult++;
        $n -= 1; # unduplicate shared diagonal
        $depth_adjust = -1;
      } else {
        ### first/fifth eighth ...
        ($x,$y) = (1-$y,$x);  # rotate +90 and offset
        $depth_adjust = 2;
      }
    }
    if ($mult) {
      push @add_offset, $depth_adjust - 2;
      push @add_mult,   $mult;
      if ($mult3) {
        push @add_offset, $depth_adjust + 1;
        push @add_mult,   $mult3;
      }
    }

  } else {

    if ($parts eq '1') {
      if ($x < 1 || $y < 1) { return undef; }
      $depth_adjust = 2;

    } elsif ($parts eq '2') {
      if ($y < 1) { return undef; }
      if ($x == 0) {
        if ($y == 1) { return 0; }
      }
      if ($y == 1) {
        if ($x == 1) { return 1; }
        if ($x == -1) { return 2; }
      }
      $depth_adjust = 1;

    } elsif ($parts eq '3') {
      if ($x == 0) {
        if ($y == 0)  { return 0; }
        if ($y == -1) { return 1; }
        if ($y == 1)  { return 2; }
      }
      if ($y < 0) {
        if ($x < 0) {
          return undef;
        }
        ### parts=3 rotate +90 ...
        ($x,$y) = (-$y,$x+1);
        $depth_adjust = 1;
      } else {
        push @add_offset, -1,0;  # one quadrant
        push @add_mult,   1,1;
        $n -= 1; # unduplicate shared diagonal
      }

    } else {
      ### assert: $parts eq '4'
      if ($x == 0) {
        if ($y == 0)  { return 0; }
        if ($y == 1)  { return 1; }
        if ($y == -1) { return 2; }
      }
      if ($y < 0) {
        $x = -$x; $y = -$y;  # rotate 180
        push @add_offset, 0,1;  # two quadrants
        push @add_mult,   2,2;
        $n -= 2; # unduplicate shared diagonal
      }
    }

    if ($x < 0) {
      ### X negative mirror ...
      $x = -$x;
      $mirror = 1;
      push @add_offset, 0,1;  # one quadrant
      push @add_mult, 1,1;
      $n -= 1; # unduplicate shared diagonal
    }

    if ($y <= $x) {
      ### lower octant ...
      if ($mirror) {
        push @add_offset, 1;
        push @add_mult, 1;
        $n -= 1; # unduplicate shared diagonal
      }
    } else {
      ### upper octant ...
      ($x,$y) = ($y-1,$x);
      foreach (@add_offset) { $_-- }
      $depth_adjust--;
      if (! $mirror) {
        push @add_offset, -1;
        push @add_mult, 1;
        $n -= 1; # unduplicate shared diagonal
      }
      $mirror ^= 1;
    }
  }
  ### $depth_adjust
  ### xy: "$x,$y"

  if ($x < 1|| $y < 1 || $y > $x+1) {
    return undef;
  }

  my ($pow,$exp) = round_down_pow (max($x,$y-1), 2);
  $pow *= 2;
  if (is_infinite($exp)) {
    return ($exp);
  }

  #     /
  #    /3
  #   /--
  #  /|\2
  # /0|1\

  for (;;) {
    ### at: "x=$x,y=$y  pow=$pow depth=$depth mirror=$mirror  n=$n"
    ### assert: $x >= 1
    ### assert: $y >= 1         || $y!=$y
    ### assert: $y <= $x+1      || $y!=$y

    # if ($x == $pow) {
    #   if ($y == $pow) {
    #   }
    #   if ($y == $pow+1) {
    #     ### toothpick B, stop ...
    #     $depth += 2*$pow - 1;
    #     $n += 1-$mirror;  # "other" first if not mirrored
    #     last;
    #   }
    #   if ($y == $pow-1) {
    #     ### toothpick other, stop ...
    #     $depth += 2*$pow - 1;
    #     $n += $mirror;  # B first if not mirrored
    #     last;
    #   }
    # }

    if ($x < $pow) {
      if ($y == $pow && $x == $pow-1) {
        ### toothpick A, stop ...
        $depth += 2*$pow - 1;
        last;
      }
      ### block 0, no action ...

    } else {
      $x -= $pow;
      $y -= $pow;
      $depth += 2*$pow;

      if ($y == 0) {
        if ($x == 0) {
          ### toothpick B, stop ...
          last;
        } else {
          return undef;
        }

      } elsif ($y > 0) {
        ### block 3, same ...
        if ($y == 1 && $x == 0) {
          ### middle above point, stop ...
          $depth += 1;
          if (! $mirror) {
            $n += 1;
          }
          last;
        }
        if (! $mirror) {
          push @add_offset, $depth-1, $depth;  # past block 1,2
          push @add_mult, 1, 1;
          $n -= 1; # unduplicate shared diagonal
        }

      } else {
        if ($y == -1 && $x == 0) {
          ### middle below point, stop ...
          $depth += 1;
          if ($mirror) {
            $n += 1;
          }
          last;
        }
        if ($x >= -$y) {
          ### block 2, vertical flip mirror ...
          if ($y > -1) {
            return undef;  # no such point
          }
          $y = -$y;
          if ($mirror) {
            push @add_offset, $depth;  # past block 3
            push @add_mult, 1;
          } else {
            push @add_offset, $depth-1;  # past block 1
            push @add_mult, 1;
            $n -= 1; # unduplicate shared diagonal
          }
          $mirror ^= 1;

        } else {
          ### block 1, rotate and offset ...
          $depth -= 1;
          ($x,$y) = (-$y,$x+1); # rotate +90, offset
          if ($mirror) {
            push @add_offset, $depth+1;  # past block 3,2
            push @add_mult, 2;
            $n -= 1; # unduplicate shared diagonal 2,1
          }
        }
      }
    }

    if (--$exp < 0) {
      ### final xy: "$x,$y"
      if ($x == 1 && $y == 1) {
        $depth += 2;
      } elsif ($x == 1 && $y == 2) {
        $depth += 3;
      } else {
        ### not in final position ...
        return undef;
      }
      last;
    }
    $pow /= 2;
  }

  ### final depth: $depth - $depth_adjust
  ### $n
  ### depth_to_n: $self->tree_depth_to_n($depth - $depth_adjust)
  ### add_offset: join(',',@add_offset)
  ### add_mult:   join(',',@add_mult)

  $n += $self->tree_depth_to_n($depth - $depth_adjust);

  if (@add_offset) {
    foreach my $add_offset (@add_offset) {
      $add_offset = $depth - $add_offset; # mutate array
      ### add: "unadj depth=$add_offset", _depth_to_octant_added([$add_offset],[1], $zero)." x add_mult"
      # .$add_mult[$i]
    }
    ### total add: _depth_to_octant_added ([@add_offset], [@add_mult], $zero)
    $n += _depth_to_octant_added (\@add_offset, \@add_mult, $zero);
  }

  ### xy_to_n() return n: $n
  return $n;
}


# Shared with ToothpickReplicate.
# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### ToothpickTree rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;

  my $parts = $self->{'parts'};
  if ($parts eq 'wedge' || $parts eq 'wedge+1') {
    my ($len,$level) = round_down_pow ($y2, 2);
    return (0, (8*$len*$len-5)/3 + 2*$len);
  }

  if ($parts eq '4' || $parts eq 'two_horiz') {
    if ($parts eq 'two_horiz') {
      $x2 += 3;
      $x1 -= 3;
      $y2 += 2;
      $y1 -= 2;
    }
    my ($len,$level) = round_down_pow (max(-$x1,
                                           $x2,
                                           -1-$y1,
                                           $y2-1),
                                       2);
    return (0, (32*$len*$len-2)/3);
  }

  if ($parts eq '3') {
    if ($x2 < 0 && $y2 < 0) {
      ### third quadrant only, no points ...
      return (1,0);
    }
    # +---------+-------------+
    # | x1,y2-1 | x2,y2-1     |
    # +---------+-------------+
    #           | rot and X-1 |
    #           | x2-1+1,y1   |
    #           +-------------+
    # Point N=28 X=3,Y=-4 and further X=2^k-1,Y=-2^k belong in previous
    # $level level, but don't worry about that for now.
    my ($len,$level) = round_down_pow (max(-$x1,
                                           $x2,
                                           -$y1,
                                           $y2-1),
                                       2);
    return (0, 8*$len*$len);

  }
  if ($parts eq '2') {
    if ($y2 < 0) {
      return (1,0);
    }
    my ($len,$level) = round_down_pow (max(-$x1,
                                           $x2,
                                           $y2-1),
                                       2);
    return (0, (16*$len*$len-4)/3);

  }

  ### assert: $parts eq '1'
  if ($x2 < 1 || $y2 < 1) {
    return (1,0);
  }
  my ($len,$level) = round_down_pow (max($x2, $y2-1),
                                     2);
  return (0, (8*$len*$len-5)/3);
}

#------------------------------------------------------------------------------

# Is it possible to calculate this by the bits of N rather than by X,Y?
sub tree_n_children {
  my ($self, $n) = @_;
  ### tree_n_children(): $n

  my ($x,$y) = $self->n_to_xy($n)
    or return; # before n_start(), no children

  my ($n1,$n2);
  if (($x + $y) % 2) {
    # odd, horizontal to children
    $n1 = $self->xy_to_n($x-1,$y);
    $n2 = $self->xy_to_n($x+1,$y);
  } else  {
    # even, vertical to children
    $n1 = $self->xy_to_n($x,$y-1);
    $n2 = $self->xy_to_n($x,$y+1);
  }
  ### $n1
  ### $n2
  if (($n1||0) > ($n2||0)) {
    ($n1,$n2) = ($n2,$n1); # sorted
  }
  return ((defined $n1 && $n1 > $n ? $n1 : ()),
          (defined $n2 && $n2 > $n ? $n2 : ()));
}

my %parts_to_numroots = (two_horiz => 2,
                         # everything else 1 root
                        );
sub tree_num_roots {
  my ($self) = @_;
  return ($parts_to_numroots{$self->{'parts'}} || 1);
}

sub tree_n_parent {
  my ($self, $n) = @_;
  ### tree_n_parent(): $n

  $n = int($n);
  if ($n < ($parts_to_numroots{$self->{'parts'}} || 1)) {
    return undef;
  }
  my ($x,$y) = $self->n_to_xy($n)
    or return undef;

  ### parent at: "xy=$x,$y"
  ### parent odd  list: (($x%2) ^ ($y%2))  && ($self->xy_to_n_list($x,$y-1), $self->xy_to_n_list($x,$y+1))
  ### parent even list: !(($x%2) ^ ($y%2)) && ($self->xy_to_n_list($x-1,$y), $self->xy_to_n_list($x+1,$y))
  ### parent min: min($self->xy_to_n_list($x-1,$y), $self->xy_to_n_list($x+1,$y),$self->xy_to_n_list($x,$y-1), $self->xy_to_n_list($x,$y+1))

  return min((($x%2) ^ ($y%2))
             ?
             # odd X,Y, vertical to parent
             ($self->xy_to_n_list($x,$y-1),
              $self->xy_to_n_list($x,$y+1))
             :
             # even X,Y, horizontal to parent
             ($self->xy_to_n_list($x-1,$y),
              $self->xy_to_n_list($x+1,$y)));
}

sub tree_n_to_depth {
  my ($self, $n) = @_;
  ### tree_n_to_depth(): "$n"

  if ($n < 0) {
    return undef;
  }
  my ($depth) = _n0_to_depth_and_rem($self, int($n));
  ### n0 depth: $depth
  return $depth;
}


# Do a binary search for the bits of depth which give Ndepth <= N.
#
# Ndepth grows as roughly depth*depth, so this is about log4(N) many
# compares.  For large N wouldn't want to a table to search through to
# sqrt(N).

sub _n0_to_depth_and_rem {
  my ($self, $n) = @_;
  ### _n0_to_depth_and_rem(): "n=$n   parts=$self->{'parts'}"

  # For parts=4 have depth=2^exp formula
  # T[2^exp] = parts*(4^exp-1)*2/3 + 3
  # parts*(4^exp-1)*2/3 + 3 = N
  # 4^exp = (N-3)*3/2parts,   round down
  # but must be bigger ... (WHY-IS-IT-SO?)
  #
  my ($pow,$exp) = round_down_pow (12*$n,  # /$self->{'parts'}
                                   4);
  if (is_infinite($exp)) {
    return ($exp,0);
  }
  ### $pow
  ### $exp

  my $depth = 0;
  my $n_depth = 0;
  $pow = 2 ** $exp;  # pow=2^exp down to 1, inclusive

  while ($exp-- >= 0) {
    my $try_depth = $depth + $pow;
    my $try_n_depth = $self->tree_depth_to_n($try_depth);

    ### $depth
    ### $pow
    ### $try_depth
    ### $try_n_depth

    if ($try_n_depth <= $n) {
      ### use this tried depth ...
      $depth = $try_depth;
      $n_depth = $try_n_depth;
    }
    $pow /= 2;
  }

  ### _n0_to_depth_and_rem() final ...
  ### $depth
  ### remainder: $n - $n_depth

  return ($depth, $n - $n_depth);
}

# First unsorted @pending
#   depth=119 parts=4 pow=64   119
#   depth=119 parts=4 pow=32   56,55
#   depth=119 parts=4 pow=16   25,24,23
#   depth=119 parts=4 pow=8    10,9,8,7     <- list crosses pow=8 boundary
#   depth=119 parts=4 pow=4    3,2,7
#   depth=119 parts=4 pow=2    3

# T(2^k+rem) = T(2^k) + T(rem) + 2T(rem-1)   rem>=1


#------------------------------------------------------------------------------
# tree_depth_to_n()

# initial toothpicks not counted by the blocks crunching
my %depth_to_n_initial
  = (4         => 3,  # 1 origin + 1 above + 1 below
     3         => 2,  # 1 origin + 1 above
     2         => 1,  # 1 middle X=0,Y=1
     1         => 0,
     octant    => 0,
     octant_up => 0,
     wedge     => 4,
     'wedge+1' => 3,
     two_horiz => 0,
    );

my %tree_depth_to_n = (4         => [ 0, 1, 3 ],
                       3         => [ 0, 1, 3 ],
                       2         => [ 0, 1    ],
                       1         => [ 0, 1    ],
                       octant    => [ 0, 1    ],
                       octant_up => [ 0, 1    ],
                       wedge     => [ 0, 1, 2 ],
                       'wedge+1' => [ 0, 1    ],
                       two_horiz => [ 0, 2, 4 ],
                      );

sub tree_depth_to_n {
  my ($self, $depth) = @_;
  ### tree_depth_to_n(): "$depth  parts=$self->{'parts'}"

  if ($depth < 0) {
    return undef;
  }
  $depth = int($depth);

  my $parts = $self->{'parts'};
  {
    my $initial = $tree_depth_to_n{$parts};
    if ($depth <= $#$initial) {
      return $initial->[$depth];
    }
  }

  # Adjust $depth so it's parts=4 style counting from the origin X=0,Y=0 as
  # depth=0.  So for example parts=1 is adjusted $depth+=2 since its depth=0
  # is at X=1,Y=1 which is 2 levels down.
  #
  # The parts=4 style means that depth=2^k is the "A" point of a new
  # replication.
  #
  $depth += $parts_depth_adjust{$parts};

  # +1 for parts=3 using depth+1
  my ($pow,$exp) = round_down_pow ($depth+1, 2);
  if (is_infinite($exp)) {
    return $exp;
  }
  ### $pow
  ### $exp

  my $zero = $depth*0;
  my $n = $depth_to_n_initial{$parts} + $zero;

  # @pending is a list of depth values.
  # @mult is the multiple of T[depth] desired for that @pending entry.
  #
  # @pending has its values mostly in order high to low and growing by one
  # more value at each $exp level, but sometimes it grows a bit more and
  # sometimes values are not entirely high to low and may even be
  # duplicated.
  #
  my @pending;
  my @mult;

  if ($parts eq 'octant' || $parts eq 'octant_up') {
    @pending = ($depth);
    @mult = (1+$zero);

  } elsif ($parts eq 'wedge') {
    # wedge(depth) = 2*oct(depth-1) + 4
    @pending = ($depth);
    @mult = (2+$zero);

  } elsif ($parts eq 'wedge+1') {
    # wedge(depth) = 2*oct(depth-1) + depth - depth&1
    $n += $depth - ($depth%2);
    @pending = ($depth-1);
    @mult = (2+$zero);

  } elsif ($parts eq 'two_horiz') {
    $n -= 4*$depth - 16;  # overlapping spines
    @pending = ($depth,$depth-3);
    @mult = ((4+$zero) x 2);

  } elsif ($parts eq '3') {
    @pending = ($depth+1,  $depth, $depth-1);
    @mult    = (1+$zero, 3+$zero,  2+$zero);
    $n -= 3*$depth - 8;

  } else {
    # quadrant(depth) = oct(depth) + oct(depth-1) - (d-3)
    # half(depth) = 2*quadrant(depth) + 1
    # full(depth) = 4*quadrant(depth) + 3
    @pending = ($depth, $depth-1);
    @mult    = ($parts + $zero) x 2;
    $n -= $parts*($depth-3);
  }

  while (--$exp >= 0) {
    last unless @pending;

    ### @pending
    ### @mult
    ### $exp
    ### $pow

    my @new_pending;
    my @new_mult;
    my $tpow;

    # if (1||join(',',@pending) ne join(',',reverse sort {$a<=>$b} @pending)) {
    #   # print "depth=$depth parts=$parts pow=$pow   ",join(',',@pending),"\n";
    #   print "mult  ",join(',',@mult),"\n";
    # }

    foreach my $depth (@pending) {
      my $mult = shift @mult;
      ### assert: $depth >= 2
      ### assert: $depth < 2*$pow

      if ($depth <= 3) {
        if ($depth eq '3') {
          ### depth==3 total=1 ...
          $n += $mult;
        } else {
          ### depth==2 total=0 ...
        }
        next;
      }

      if ($depth < $pow) {
        # Smaller than $pow, keep unchanged.  Cannot stop processing
        # @pending on finding one $depth<$pow because @pending is not quite
        # sorted and therefore might have a later $depth>=$pow.
        push @new_pending, $depth;
        push @new_mult, $mult;
        next;
      }
      my $rem = $depth - $pow;

      ### $depth
      ### $mult
      ### $rem
      ### assert: $rem >= 0 && $rem < $pow

      my $basemult = $mult;  # multiple of oct(2^k) base part

      if ($rem == 0) {
        ### rem==0, so just the oct(2^k) part ...

      } elsif ($rem == 1) {
        ### rem==1 "A" ...
        $n += $mult;

      } else {
        ### rem >= 2, formula ...
        # formula oct(pow+rem) = oct(pow) + oct(rem+1) + 2*oct(rem) - rem + 4
        $n += (4-$rem)*$mult;

        $rem += 1;   # to give rem+1
        if ($rem == $pow) {
          ### rem+1==pow so oct(2^k) by increasing basemult ...
          $basemult += $mult;
        } elsif (@new_pending && $new_pending[-1] == $rem) {
          ### combine rem+1 here with rem of previous ...
          $new_mult[-1] += $mult;
        } else {
          push @new_pending, $rem;
          push @new_mult, $mult;
        }
        if ($rem -= 1) {  # to give plain rem again
          push @new_pending, $rem;
          push @new_mult, 2*$mult;
        }
      }

      # oct(2^k) = (4^(k-1) - 4)/3 + 2^(k-1)
      $tpow ||= ($pow*$pow - 16)/12 + $pow/2;
      $n += $basemult * $tpow;
    }
    @pending = @new_pending;
    @mult = @new_mult;
    $pow /= 2;
  }

  ### return: $n
  return $n;
}


#------------------------------------------------------------------------------
# $depth numbered from origin in parts=4 style.
# Return cells added at that depth,
# ie. added = depth_to_n($depth+1) - depth_to_n($depth)
#
# @$depth_list is a list of $depth values.
# @mult_list is the multiple of T[depth] desired for that @$depth_list entry.
# $depth_list->[0], ie. the first array entry, must be the biggest $depth.
#
# @$depth_list is maintained mostly high to low and growing by one more
# value at each $exp level, but sometimes it's a bit more and some values
# not high to low and possibly duplicated.
#
# added(pow)     = 1
# added(pow+1)   = 2
# added(pow+rem) = 2*added(rem) + added(rem+1) - 1
#
# added(pow+pow-1) = 2*added(pow-1) + added(pow) - 1
#                  = 2*added(pow-1) + 1 - 1
#                  = 2*added(pow-1)
# repeats down to added(2^k-1) = 2^(k-1)

sub _depth_to_octant_added {
  my ($depth_list, $mult_list, $zero) = @_;

  ### _depth_to_octant_added(): join(',',@$depth_list)
  ### assert: scalar(@$depth_list) >= 1
  ### assert: max(@$depth_list) == $depth_list->[0]

  my ($pow,$exp) = round_down_pow ($depth_list->[0], 2);
  if (is_infinite($exp)) {
    return $exp;
  }
  ### $pow
  ### $exp

  my $add = $zero;

  while (--$exp >= 0) {     # running $pow down to 2 (inclusive)
    ### assert: $pow >= 2
    last unless @$depth_list;

    ### pending: join(',',@$depth_list)
    ### mult   : join(',',@$mult_list)
    ### $exp
    ### $pow

    my @new_depth_list;
    my @new_mult_list;

    foreach my $depth (@$depth_list) {
      my $mult = shift @$mult_list;
      ### assert: $depth >= 0
      ### assert: $depth == int($depth)

      if ($depth <= 3) {
        ### depth==2or3 add=1 ...
        $add += $mult;
        next;
      }

      if ($depth < $pow) {
        # less than 2^exp so unchanged
        push @new_depth_list, $depth;
        push @new_mult_list, $mult;
        next;
      }

      my $rem = $depth - $pow;

      ### $depth
      ### $mult
      ### $rem
      ### assert: $rem >= 0 && $rem <= $pow

      if ($rem == 0 || $rem == $pow-1) {
        ### rem==0, A of each, add=1 ...
        ### or depth=2*pow-1, add=1 ...
        $add += $mult;

      } else {
        ### rem >= 2, formula ...
        # A(pow+rem) = A(rem+1) + 2A(rem) - 1
        $add -= $mult;

        $rem += 1;  # to make rem+1
        if (@new_depth_list && $new_depth_list[-1] == $rem) {
          # add to previously pushed pending depth
          # print "rem=$rem ",join(',',@new_depth_list),"\n";
          $new_mult_list[-1] += $mult;
        } else {
          push @new_depth_list, $rem;
          push @new_mult_list, $mult;
        }
        push @new_depth_list, $rem-1;  # back to plain rem
        push @new_mult_list, 2*$mult;
      }
    }
    $depth_list = \@new_depth_list;
    $mult_list  = \@new_mult_list;
    $pow /= 2;
  }

  ### return: $add
  return $add;
}

#------------------------------------------------------------------------------

sub tree_n_to_subheight {
  my ($self, $n) = @_;
  ### tree_n_to_subheight(): $n

  if ($n < 0)          { return undef; }
  if (is_infinite($n)) { return $n; }

  my $zero = $n * 0;
  (my $depth, $n) = _n0_to_depth_and_rem($self, int($n));
  ### $depth
  ### $n

  my $parts = $self->{'parts'};
  $depth += $parts_depth_adjust{$parts};
  ### depth adjusted to: $depth

  if ($parts eq 'octant') {
    my $add = _depth_to_octant_added ([$depth],[1], $zero);
    $n = $add-1 - $n;
    ### octant mirror numbering to n: $n

  } elsif ($parts eq 'octant_up') {

  } elsif ($parts eq 'wedge' || $parts eq 'wedge+1') {
    my $add = _depth_to_octant_added ([$depth],[1], $zero);
    ### wedge half width: $add
    if ($parts eq 'wedge+1') {
      # 0, 1 to $add, $add+1 to 2*$add, 2*$add+1
      if ($n == 0 || $n == 2*$add+1) {
        return 0;    # first,last toothpicks don't grow
      }
      $n -= 1;
    }
    ### assert: $n < 2*$add
    if ($n >= $add) {
      ### wedge second half
      $n = 2*$add-1 - $n;   # mirror
    }

  } elsif ($parts eq 'two_horiz') {
    ### two_horiz ...
    my $add = _depth_to_octant_added([$depth,$depth-3],[1,1], $zero) - 1;
    ### add quad: $add
    ### assert: $n < 4*$add
    if ($n >= 2*$add) {
      ### two_horiz symmetric left,right halves ...
      $n -= 2*$add;
      ### $n
    }
    if ($n >= $add) {
      ### two_horiz mirror top,bottom quarters ...
      $n = 2*$add-1 - $n;
      ### $n
    }

    $add = _depth_to_octant_added ([$depth],[1], $zero);
    ### add oct: $add
    if ($n < $add) {
      ### two_horiz first octant, mirror ...
      $n = $add-1 - $n;
    } else {
      ### two_horiz second octant, depth-3 ...
      $n -= $add-1;
      $depth -= 3;
    }

  } else {
    ### assert: $parts eq '1' || $parts eq '2' || $parts eq '3' || $parts eq '4'
    if ($parts eq '3') {
      my $add = _depth_to_octant_added ([$depth+1,$depth],[1,1], $zero)
        - 1; # undouble spine
      if ($n < $add) {
        $depth += 1;
      } else {
        $n -= $add;
        $parts = '2';
      }
    }

    if ($parts eq '2' || $parts eq '4') {
      my $add = _depth_to_octant_added([$depth,$depth-1],[1,1], $zero)
        - 1; # undouble spine
      if ($n >= 2*$add) {
        # parts=4 rotate lower ...
        $n -= 2*$add;
      }

      ### add quadrant: $add
      ### assert: $n < 2*$add
      if ($n >= $add) {
        ### parts=2 left half mirror ...
        $n = 2*$add-1 - $n;
        ### $n
      } else {
        ### parts=2 right half unchanged ...
      }
    }

    ### quadrant ...
    my $add = _depth_to_octant_added ([$depth],[1], $zero);
    $n -= $add;
    if ($n < 0) {
      ### lower octant ...
      $n = -1-$n;   # mirror
    } else {
      ### upper octant ...
      $depth -= 1;
      $n += 1;  # undouble spine
    }
  }

  if ($depth <= 4) {
    return undef;  # initial points
  }

  my $dbase;
  my ($pow,$exp) = round_down_pow ($depth, 2);

  for ( ; $exp--; $pow /= 2) {
    ### at: "depth=$depth pow=$pow n=$n   dbase=".($dbase||'inf')
    ### assert: $n >= 0

    if ($n == 0) {
      ### n=0 on spine ...
      last;
    }

    next if $depth < $pow;

    if (defined $dbase) { $dbase = $pow; }
    $depth -= $pow;
    ### depth remaining: $depth

    if ($depth == 1) {
      ### depth=1 is on upper,lower diagonal spine ...
      ### assert: $n == 1
      return $pow-3;
    }
    ### assert: $depth >= 2

    my $add = _depth_to_octant_added ([$depth],[1], $zero);
    ### $add

    if ($n < $add) {
      ### extend part ...
    } else {
      $dbase = $pow;
      $n -= 2*$add;
      ### sub 2add to: $n

      if ($n < 0) {
        ### upper part, mirror to n: -1 - $n
        $n = -1 - $n;   # mirror,  $n = $add-1 - $n = -($n-$add) - 1
      } else {
        ### lower part ...
        $depth += 1;
        $n += 1;  # undouble upper,lower spine
      }
    }

  }

  ### final ...
  ### $dbase
  ### $depth
  return (defined $dbase ? $dbase - $depth - 2 : undef);
}

#------------------------------------------------------------------------------
# levels

# parts               depth
# -----               -----
#  4            \
#  3            |  4*2^level - 1  = 3, 7, 15, 31, ...
#  wedge        |
#  two_horiz    /
#  2               4*2^level - 2  = 2, 6, 14, 30, ...
#  1               4*2^level - 3  = 1, 5, 13, 29, ...
#  octant       \  4*2^level - 4  = 0, 4, 12, 28, ...
#  octant_up    /
#                                      level=0 level=1 level=2 level=3
# parts=4 level depths 0, 3, 7           4-1=3,  8-1=7, 16-1=15
# parts=1 level depths 1  5, 13  2-3=-1  4-3=1,  8-3=5, 16-3=13
# parts=two_horiz                        4-1=3,  8-3=7, 16-4=15
my %level_depth_offset = (4         => 1,
                          3         => 1,
                          2         => 2,
                          1         => 3,  #
                          octant    => 4,  # sans upper
                          octant_up => 4,  #
                          wedge     => 1,  #
                          two_horiz => 1,  # like parts=4
                         );

sub level_to_n_range {
  my ($self, $level) = @_;
  return (0,
          $self->tree_depth_to_n_end(2**($level+2)
                                     - $level_depth_offset{$self->{'parts'}}));
}
sub n_to_level {
  my ($self, $n) = @_;
  my $depth = $self->tree_n_to_depth($n);
  if (! defined $depth) { return undef; }
  my ($pow, $exp) = round_down_pow
    ($depth + $level_depth_offset{$self->{'parts'}} - 1,
     2);
  return max(0, $exp - 1);
}

#------------------------------------------------------------------------------
1;
__END__

=for stopwords eg Ryde Math-PlanePath-Toothpick Applegate Automata Congressus Numerantium OEIS ie Ndepth Nquad Octant octant octants

=head1 NAME

Math::PlanePath::ToothpickTree -- toothpick pattern by rows

=head1 SYNOPSIS

 use Math::PlanePath::ToothpickTree;
 my $path = Math::PlanePath::ToothpickTree->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

X<Applegate, David>X<Pol, Omar E.>X<Sloane, Neil>This is the "toothpick"
sequence pattern expanding through the plane by non-overlapping line
segments as per

=over

David Applegate, Omar E. Pol, N.J.A. Sloane, "The Toothpick Sequence and
Other Sequences from Cellular Automata", Congressus Numerantium, volume 206
(2010), 157-191.  L<http://www.research.att.com/~njas/doc/tooth.pdf>

=back

Points are numbered by a breadth-first tree traversal and anti-clockwise at
each node.

=cut

# math-image --path=ToothpickTree --output=numbers --all --size=65x11

=pod

    --49---                         --48---            5
       |                               |
      44--38--  --37--  --36--  --35--43               4
       |   |       |       |       |   |
    --50- 27--17--26      25--16--24 -47---            3
           |   |               |   |
              12---8--- ---7--11                       2
           |   |   |       |   |   |
          28--18-- 4---1---3 -15--23                   1
           |       |   |   |       |
                       0                          <- Y=0
           |       |   |   |       |
          29--19-  5---2---6 -22--34                  -1
           |   |   |       |   |   |
              13---9--  --10--14                      -2
           |   |   |       |   |   |
    --51- 30--20--31      32--21--33 -54---           -3
       |   |       |       |       |   |
      45--39--- --40--- --41--- --42--46              -4
       |                               |
    --52---                         --53---           -5

                       ^
      -4   -3 -2  -1  X=0  1   2   3   4

Each X,Y is the centre of a toothpick of length 2.  The first toothpick is
vertical at the origin X=0,Y=0.

A toothpick is added at each exposed end, perpendicular to that end.  So N=1
and N=2 are added to the two ends of the initial N=0 toothpick.  Then points
N=3,4,5,6 are added at the four ends of those.

                                               ---8--- ---7---
                              |       |           |       |
             ---1---          4---1---3           4---1---3
    |           |             |   |   |           |   |   |
    0   ->      0       ->        0        ->         0
    |           |             |   |   |           |   |   |
             ---2---          5---2---6           5---2---6
                              |       |           |       |
                                               ---9--- --10---

Toothpicks are not added if they would overlap.  This means no toothpick at
X=1,Y=0 where the ends of N=3 and N=6 meet, and likewise not at X=-1,Y=0
where N=4 and N=5 meet.

The end of a new toothpick is allowed to touch an existing toothpick.  The
first time this happens is N=15 where its left end touches N=3.

The way each toothpick is perpendicular to the previous means that at even
depth the toothpicks are all vertical and are on "even" points X==Y mod 2.
Conversely at odd depth all toothpicks are horizontal and are on "odd"
points X!=Y mod 2.  (The initial N=0 is depth=0.)

The children at a given depth are numbered in order of their parents, and
anti-clockwise around when there's two children.

            |       |
            4---1---3         points 3,4 numbered
            |   |   |         anti-clockwise around
                0
                |

Anti-clockwise here is relative to the direction of the grandparent node.
So for example at N=1 its parent N=0 is downwards and the children of N=1
are then anti-clockwise around from there, hence first the right side for
N=3 and then the left for N=4.

=head2 Cellular Automaton

The toothpick rule can also be expressed as growing into a cell which has
just one of its two vertical or horizontal neighbours "ON", going to either
vertical or horizontal neighbours according to X+Y odd or even.

          Point            Grow
    ------------------   ------------------------------------------
    "even", X==Y mod 2   turn ON if 1 of 2 horizontal neighbours ON
    "odd",  X!=Y mod 2    turn ON if 1 of 2 vertical neighbours ON

For example X=0,Y=1 which is N=1 turns ON because it has a single vertical
neighbour (the origin X=0,Y=0).  But the cell X=1,Y=0 never turns ON because
initially its two vertical neighbours are OFF and then later at depth=3
they're both ON.  Only when there's exactly one of the two neighbours ON in
the relevant direction does the cell turn ON.

In the paper section 10 above this variation between odd and even points is
reckoned as an automaton on a directed graph where even X,Y points have
edges directed out horizontally, and conversely odd X,Y points are directed
out vertically.

         v          ^         v          ^         v
    <- -2,2  ---> -1,2  <--- 0,2  --->  1,2 <---  2,2 --
         ^          |         ^          |         ^
         |          v         |          v         |
    -> -2,1  <--- -1,1  ---> 0,1  <---  1,1 --->  2,1 <-
         |          ^         |          ^         |
         v          |         v          |         v
    <- -2,0  ---> -1,0  <--- 0,0  --->  1,0 <---  2,0 ->
         ^          |         ^          |         ^
         |          v         |          v         |
    -> -2,-1 <--- -1,-1 ---> 0,1  <--- 1,-1 ---> 2,-1 <-
         |          ^         |          ^         |
         v          |         v          |         v
    <- -2,-2 ---> -1,-2 <--- 0,-2 ---> 1,-2 <--- 2,-2 ->
         ^          v         ^          v         ^

The rule on this graph is then that a cell turns ON if precisely one of it's
neighbours is ON, looking along the outward directed edges.  For example
X=0,Y=0 starts as ON then the cell above X=0,Y=1 considers its two
outward-edge neighbours 0,0 and 0,2, of which just 0,0 is ON and so 0,1
turns ON.

=head2 Replication

Within each quadrant the pattern repeats in blocks of a power-of-2 size,
with an extra two toothpicks "A" and "B" in the middle.

    |
    |------------+------------A
    |            |            |
    |  block 3       block 2  |      in each quadrant
    |   mirror        same    |
    |     ^            ^      |
    |      \   --B--  /       |
    |       \    |   /        |
    |----------  A         ---+
    |            |            |
    |  block 0       block 1  |
    |     ^      |  \ rot +90 |
    |    /       |   \        |
    |   /        |    v       |
    +----------------------------

Toothpick "A" is at a power-of-2 position X=2^k,Y=2^k and toothpick "B" is
above it.  The B toothpick leading to blocks 2 and 3 means block 1 is one
growth row ahead of blocks 2 and 3.

In the first quadrant of the diagram above, N=3,N=7 is block 0 and those two
repeat as N=15,N=23 block 1, and N=24,N=35 block 2, and N=25,36 block 3.
The rotation for block 1 can be seen.  The mirroring for block 3 can be seen
at the next level (the diagram of the L</One Quadrant> form below extends to
there).

The initial N=3,N=7 can be thought of as an "A,B" middle pair with empty
blocks before and surrounding.

See L<Math::PlanePath::ToothpickReplicate> for a digit-based replication
instead of by rows.

=head2 Row Ranges

Each "A" toothpick is at a power-of-2 position,

   "A" toothpick
   -------------
   X=2^k, Y=2^k
   depth = 4^k              counting from depth=0 at the origin
   N = (8*4^k + 1)/3        N=3,11,43, etc
     = 222...223 in base4

N=222..223 in base-4 arises from the replication described above.  Each
replication is 4*N+2 of the previous, after the initial N=0,1,2.

The "A" toothpick coming out of corner of block 2 is the only growth from a
depth=4^k row.  The sides of blocks 1 and 2 and blocks 2 and 3 have all
endpoints meeting and so stop by the no-overlap rule, as can be seen for
example N=35,36,37,38 across the top above.

The number of points visited approaches 2/3 of the plane.  This be seen by
expressing the count of points up to "A" as a fraction of the area (in all
four quadrants) to there,

    N to "A"   (8*4^k + 1)/3      8/3 * 4^k
    -------- = -------------   -> --------- = 2/3
    Area X*Y   (2*2^k)*(2*2^k)    4   * 4^k

=head2 One Quadrant

Option C<parts =E<gt> 1> confines the pattern to the first quadrant,
starting from N=0 at X=1,Y=1 which is the first toothpick wholly within that
first quadrant.  This is a single copy of the repeating part in each of the
four quadrants of the full pattern.

=cut

# math-image --path=ToothpickTree,parts=1 --all --output=numbers

=pod

    parts => 1
                                    ...     ...
        |                            |       |
        |                           47--44--46
        |                                |   |
      8 | --41--  --40--  --39--  --38--42
        |    |       |       |       |   |   |
      7 |   36--28--35      34--27--33 -43--45
        |    |   |               |   |       |
      6 |       22--18--  --17--21          ...
        |    |   |   |       |   |   |
      5 |   37--29- 15--12--14 -26--32
        |                |   |       |
      4 | ---9--- ---8--10
        |    |       |   |   |       |
      3 |    7---4---6 -11--13 -25--31
        |        |   |       |   |   |
      2 | ---1---2      19--16--20
        |    |   |   |   |       |   |
      1 |    0 --3---5 -23--  --24--30
        |    |       |               |
    Y=0 |
        +----------------------------------
        X=0  1   2   3   4   5   6   7   8

The "A" toothpick at X=2^k,Y=2^k is

    N of "A" = (2*4^k - 2)/3 = 2,10,42,etc
             = "222...222" in base 4

The repeating part starts from N=0 here so there's no initial centre
toothpicks like the full pattern.  This means the repetition is a plain
4*N+2 and hence a N="222..222" in base 4.  It also means the depth is 2
smaller, since N=0 depth=0 at X=1,Y=1 corresponds to depth=2 in the full
pattern.

=head2 Half Plane

Option C<parts =E<gt> 2> confines the tree to the upper half plane
C<YE<gt>=1>, giving two symmetric parts above the X axis.  N=0 at X=0,Y=1 is
the first toothpick of the full pattern which is wholly within this half
plane.

=cut

# math-image --path=ToothpickTree,parts=2 --all --output=numbers

=pod

    parts => 2

    ...                             ...           5
     |                               |
    22--20--  --19--  --18--  --17--21            4
     |   |       |       |       |   |
    ... 15---9--14      13---8--12  ...           3
         |   |               |   |
             6---4--  ---3---5                    2
         |   |   |       |   |   |
        16--10-  2---0---1 --7--11                1
         |       |       |       |
                                             <- Y=0
    -----------------------------------
                     ^
    -4  -3  -2  -1  X=0  1   2   3   4

=cut

# Bigger sample of parts=2 ...
#
#    --37--    36--                  --35--  --34--      6
#       |       |                       |       |
#      31--25--30                      29--24--28        5
#           |                               |
#          22--20--  --19--  --18--  --17--21            4
#           |   |       |       |       |   |
#      32--26- 15---9--14      13---8--12 -23--27        3
#       |       |   |               |   |       |
#    --38--         6---4--  ---3---5        --33--      2
#               |   |   |       |   |   |
#              16--10-  2---0---1 --7--11                1
#               |       |       |       |
#                                                   <- Y=0
#    ---------------------------------------------
#                           ^
#      -5  -4  -3  -2  -1  X=0  1   2   3   4   6

=pod

=head2 Three Parts

Option C<parts =E<gt> 3> is the three replications which occur from an
X=2^k,Y=2^k point, continued on indefinitely confined to the upper and right
three quadrants.

=cut

# math-image --path=ToothpickTree,parts=3 --all --output=numbers

=pod

    parts => 3

    ..--32--  --31--  --30--  --29--..           4
         |       |       |       |
        26--18--25      24--17--23               3
         |   |               |   |
            12---8--  ---7--11                   2
         |   |   |       |   |   |
        27--19-  5---2---4 -16--22               1
         |       |   |   |       |
                     0                      <- Y=0
                     |   |       |
                  ---1---3 -15--21              -1
                         |   |   |
                     9---6--10                  -2
                     |       |   |
                  --13--  --14--20              -3
                                 |
                            ..--28--..          -4

                     ^
    -4  -3  -2  -1  X=0  1   2   3   4

The bottom right quarter is rotated by 90 degrees as per the "block 1"
growth from a power-of-2 corner.  This means it's not the same as the bottom
right of parts=4.  But the two upper parts are the same as in parts=4 and
parts=2.

As noted by David Applegate and Omar Pol in OEIS A153006, the three parts
replication means that N at the last row of a power-of-2 block is a
triangular number,

    depth=2^k-1
    N(depth) = (2^k-1)*2^k/2
             = triangular number depth*(depth+1)/2
    at X=(depth-1)/2, Y=-(depth+1)/2

For example depth=2^3-1=7 begins at N=7*8/2=28 and is at the lower right
corner X=(7-1)/2=3, Y=-(7+1)/2=-4.  If the depth is not such a 2^k-1 then
N(depth) is less than the triangular depth*(depth+1)/2.

=head2 One Octant

Option C<parts =E<gt> 'octant'> confines the quadrant pattern to the first
octant 0E<lt>=YE<lt>=X+1.  This means the stairstep diagonal spine and
everything below.

=cut

# math-image --path=ToothpickTree,parts=octant --all --output=numbers --size=75x10

=pod

    parts => "octant"

      9 |                                30-..
        |                                 |
      8 |                            27--28
        |                             |   |
      7 |                        22--26  29-..
        |                         |
      6 |                    14--17
        |                     |   |
      5 |                10--12  21--25
        |                 |
      4 |             7---8
        |             |   |
      3 |         4---6   9--11  20--24
        |         |           |   |
      2 |     1---2      15--13--16
        |     |   |       |       |
      1 |     0   3---5  18      19--23
        |
    Y=0 |
        +-----------------------------------
         X=0  1   2   3   4   5   6   7   8

In this arrangement N=0,1,2,4,6,7,8,10,etc on the stairstep diagonal is the
last N of each row (C<tree_depth_to_n_end()>).  The lines show the parent to
child descents.

The octant is self similar in blocks

                              --|
                            --  |
                          --    |
                        --      |
                      -- extend |
                    --          |
          2^k,2^k --------------|
                --| --   upper  |
              --  |   --  flip  |
            --    |     --      |
          --      | lower --    |
        --  base  | depth+1 --  |
      --          |           --|
    -----------------------------

"Upper" and "extend" are mirror images across the horizontal separating
them.  "Lower" is one growth row ahead of the upper and extend parts.

In the sample points shown above N=9 is the start of the "lower" copy of
N=0.  N=11 is the "upper" copy, which is 1 row depth later.  Then N=12 is
the "extend" copy.  The points N=7,8,10 are extras in between the
replications.

"Upper" and "lower" together make a square the same as the parts=1 style
quadrant, though here it stops at the X axis to be just a 2^k size block.
A quadrant consists of two octants with 1 row depth offset.

=head2 Upper Octant

Option C<parts =E<gt> 'octant_up'> confines the quadrant pattern to the
upper octant 0E<lt>=XE<lt>=Y.

=cut

# math-image --path=ToothpickTree,parts=octant_up --all --output=numbers --size=75x10

=pod

    parts => "octant_up"

      9 |    90 76    77 42 37 30 28 29
      8 |    26    25    24    23 27
      7 |    21 16 20    19 15 18
      6 |       14 12    11 13
      5 |    22 17 10  8  9
      4 |     6     5  7
      3 |     4  2  3
      2 |     0  1
      1 |
    Y=0 |
        +-------------------------------
         X=0  1  2  3  4  5  6  7  8  9

In this arrangement N=0,1,2,3,5,7,8,9,etc on stairstep diagonal is the first
N of each row (C<tree_depth_to_n()>).

The pattern is a mirror image of parts=octant, mirrored across a line
Y=X+0.5 which is the middle of the stairstep diagonal.  Points are still
numbered anti-clockwise so the effect is to reverse the order.  "octant"
numbers from the ragged edge to the diagonal, whereas "octant_up" numbers
from the diagonal to the ragged edge.

=head2 Wedge

Option C<parts =E<gt> 'wedge'> confines the full parts=4 pattern to a wedge
-YE<lt>=XE<lt>=Y.

=cut

# math-image --path=ToothpickTree,parts=wedge --all --output=numbers --size=90x9

=pod

    parts => "wedge"

    59 57    56    55    54    53    52    51    50 58        8
       49 39 48    47 38 46    43 35 42    41 34 40           7
          33 29    28 32          31 27    26 30              6
             25 21 24 37 45    44 36 23 20 22                 5
                19 17    16    15    14 18                    4
                   13  9 12    11  8 10                       3
                       7  5     4  6                          2
                          3  1  2                             1
                             0                          <-   Y=0
    ---------------------------------------------------
    -8 -7 -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6  7  8

This is two copies of the parts=octant_up, plus initial points N=0 and N=1.
In terms of toothpicks the wedge restriction is toothpicks which are wholly
within a wedge -Y-1E<lt>=XE<lt>=Y+1.

       |                               |
      19--17--  --16--  --15--  --14--18               4
       |   |       |       |       |   |
          13---9--12      11---8--10                   3
           |   |               |   |
               7---5--- ---4---6                       2
               |   |       |   |
                   3---1---2                           1
                   |   |   |
                       0                          <- Y=0
                       |


=head2 Two Horizontal

Option C<parts =E<gt> 'two_horiz'> starts the pattern from two horizontal
toothpicks in the style of OEIS A160158 by Omar Pol.  The two initial N=0
and N=1 are the roots of two trees extending to the right and left.  Points
are numbered breadth-wise anti-clockwise starting from N=0 on the right.

=cut

# math-image --path=ToothpickTree,parts=two_horiz --all --output=numbers --size=58x9

=pod

    parts => "two_horiz"

                   |               |
    --53      52--60              59--51      50--           4
       |       |   |               |   |       |
      43--32--42  72--92      91--71  41--31--40             3
           |                               |
          26--21      20      19      18--25                 2
           |   |       |       |       |   |
      44--33  13---6--12      11---5--10  30--39             1
                   |               |
                   3---1   .   0---2                    <- Y=0
                   |               |
      45--34  14---7--15       8---4---9  29--38            -1
           |   |       |       |       |   |
          27--22      23      16      17--24                -2
           |                               |
      46--35--47  79-103      80--64  36--28--37            -3
       |       |   |               |   |       |
    --54      55--63              56--48      49--          -4
                   |               |
                           ^
      -5  -4  -3  -2  -1  X=0  1   2   3   4   5

The effect is to make octants branching off the central stair-step diagonal
spine in each quadrant.

                \   oct | oct   /
                  \     |     /
    oct 2 behind    \   |   /   oct 2 behind
                      \ | /
                --------+--------
                      / | \
    oct 2 behind    /   |   \   oct 2 behind
                  /     |     \
                /  oct  |  oct  \

The four octants near the Y axis begin immediately.  The N=0 and N=2 points
are shared by the central octants going up and down on the right, and
likewise N=1,N=3 on the left.

The four octants near the X axis begin 3 row depth levels later.  This is
not the same as the quadrants of the full pattern (their opposite octants
are 1 depth offset).  For example the point N=10 at depth=3 is the start of
the lower octant in that quarter.  A bigger picture than what's shown above
makes this easier to see.

=head2 Octant Vertical or Horizontal

The parts=octant pattern is half a parts=1 quadrant across the diagonal.
It's also interesting to note that an octant is half a quadrant by taking
just the vertical or horizontal toothpicks in the quadrant (taking vertical
or horizontal according to the orientation of the last row in the octant).

    oct(d) = quad_verticals(d) + floor(d/2)    if d odd
             quad_horizontals(d) + floor(d/2)  if d even

    d = depth starting from 0 per tree_depth_to_n()

This works because in a quadrant the vertical toothpicks above the X=Y
diagonal can be folded down across the diagonal to become horizontal and
complete the lower octant.

     quadrant verticals                 octant made by quadrant
   numbered by row depth              upper verticals fold down
                                      to become horizontals

    |       |       |       |                                  |
   12      12      12      12                           ......12
    |   |   |       |   |   |                              |   |
       10              10                           ......10
    |   |   |       |   |   |                          |   |   |
   12       8       8      12                    ......8 -12--12
    |       |   |   |       |                      |   |       |
                6                            ......6
    |       |   |   |       |                  |   |   |       |
    4       4       8      12            ......4 --8---8 -12--12
    |   |   |   |   |   |   |              |   |       |   |   |
        2      10      10             .....2      10--10--10
    |   |   |   |       |   |          |   |   |   |       |   |
    0       4              12          0 --4---4 -12--   -12--12
    |       |               |          |       |               |

For example the vertical depth "4" toothpick which is above the X=Y diagonal
folds down to become the horizontal "4" in the lower octant.  Similarly the
block of five 8,10,12,12,12 above the diagonal fold down to make five
horizontals.  And the final 12 above becomes the horizontal 12.

However the horizontals which are on the central diagonal spine don't have
corresponding verticals above.  These are marked "....." in the octant shown
above.  This means 1 toothpick missing at every second row and therefore the
floor(depth/2) in the oct() formula above.

The key is that a quadrant has the upper octant running 1 growth row behind
the lower.  So the horizontals in the lower correspond to the verticals in
the upper (and vice-versa).

The correspondence can be seen algebraically in the formula for a quadrant,

    quad(d) = oct(d) + oct(d-1) + d

reversed to

    oct(d) = quad(d) - oct(d-1)

and the oct(d-1) term repeatedly expanded

    oct(d) = quad(d) - (quad(d-1) - oct(d-2) + d-1) + d
           = quad(d)-quad(d-1)+1 + oct(d-2)
           = ...
           = quad(d)-quad(d-1)+1 + quad(d-2)-quad(d-3)+1 + ...
           = quad(d)-quad(d-1) + quad(d-2)-quad(d-3) + ... + floor(d/2)

The difference quad(d)-quad(d-1) is the number of toothpicks added to make
depth d, and similarly quad(d-2)-quad(d-3) the number added to make depth
d-2.  This means the number added at every second row, so if d is even then
this counts only the vertical toothpicks added.  Or if d is odd then only
the horizontals.

The +d, +(d-1), +(d-2) additions from the quad(d) formula have alternating
signs and so cancel out to be +1 per pair, giving floor(d/2).

The parts=wedge pattern is two octants and therefore the wedge corresponds
to the horizontals or verticals of parts=2 which is two quadrants.  But
there's an adjustment to make there though since parts=2 doesn't have a
toothpick at the origin the way the wedge does.

=head2 Quadrant and 2^k-1 Sums

In OEIS A168002 (L<http://oeis.org/A168002>) Omar Pol observed that the
quadrant(d) total cells taken mod 2 gives the number of ways d can be
expressed as a sum of terms 2^k-1.

    d = (2^a - 1) + (2^b - 1) + (2^c - 1) + ...
    distinct a,b,c,...

There's only ever 0 or 1 way to write d as a sum of 2^k-1 terms, ie. d
either is or is not such a sum.  For example,

     d      ways
    ---     ----
     8       1     8 = 7+1
     9       0     no sum possible
     10      1     10 = 7+3
     11      1     11 = 7+3+1
     12      0     no sum possible

The sum can be formed by taking the highest possible 2^k-1 from d
repeatedly.  This works because smaller 2^k-1 terms are not big enough to
add up to that highest term.  The result is a recurrence

    ways(2^k-1)       = 1
    ways(2^k-1 + rem) = ways(rem)       1 <= rem < 2^k-1
    ways(2*(2^k-1))   = 0)

The quadrant total cells follows a similar recurrence when taken mod 2.
Using the quadrant count Q(d) in the paper by Applegate, Pol, Sloane above

    Q(d) = (T(d) - 3)/4

    numbered same as T,
    so Q(2)=0 then first quadrant toothpick Q(3)=1

Substituting the recurrences for T in the paper gives

    Q(2^k) = (4^k-4)/6
    Q(2^k+1) = Q(2^k) + 1
    Q(2^k + rem) = Q(2^k) + Q(rem+1) + 2*Q(rem) + 2
       for 2 <= rem < 2^k

Taking these modulo 2

    Q(2^k)   == 0 mod 2     since (4^k-4)/6 always even
    Q(2^k+1) == 1 mod 2
    Q(2^k + rem) == Q(rem+1) mod 2       2 <= rem < 2^k

    Q(2^k-1 + rem) == Q(rem) mod 2       1 <= rem < 2^k-1

The last formula is the key, being the same as the ways(2^k-1 + rem)
recurrence above.  Then Q(2^k)=0 corresponds to ways(2^k-2)=0, and
Q(2^k+1)=1 corresponding to ways(2^k-1)=1.  And therefore

    Q(d-2) == ways(d) mod 2

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::ToothpickTree-E<gt>new ()>

=item C<$path = Math::PlanePath::ToothpickTree-E<gt>new (parts =E<gt> $str)>

Create and return a new path object.  C<parts> can be

    "4"              full pattern (the default)
    "3"              three quadrants
    "2"              half plane
    "1"              single quadrant
    "octant"         single eighth
    "octant_up"      single eighth upper
    "wedge"          V-shaped wedge
    "two_horiz"      starting two horizontal toothpicks

=back

=head2 Tree Methods

=over

=item C<@n_children = $path-E<gt>tree_n_children($n)>

Return the children of C<$n>, or an empty list if C<$n> has no children
(including when C<$n E<lt> 0>, ie. before the start of the path).

The children are the new toothpicks added at the ends of C<$n> at the next
row.  This can be 0, 1 or 2 points.  For example in the parts=4 default N=24
has no children, N=8 has a single child N=12, and N=2 has two children
N=4,N=5.  The way points are numbered means that if there are two children
then they're consecutive N values.

=item C<$n_parent = $path-E<gt>tree_n_parent($n)>

Return the parent node of C<$n>, or C<undef> if no parent due to C<$n E<lt>=
0> (the start of the path).

=item C<$depth = $path-E<gt>tree_n_to_depth($n)>

=item C<$n = $path-E<gt>tree_depth_to_n($depth)>

Return the depth of point C<$n>, or first C<$n> at given C<$depth>,
respectively.

The first point N=0 is depth=0 in all "parts" forms.  The way parts=1 and
parts=2 don't start at the origin means their depth at a given X,Y differs
by 2 or 1 respectively from the full pattern at the same point.

=back

=head2 Tree Descriptive Methods

=over

=item C<$num = $path-E<gt>tree_num_roots ()>

Return the number of root nodes in C<$path>.  This is 1 except for
parts=two_horiz which is 2.

=item C<$num = $path-E<gt>tree_num_children_minimum()>

=item C<$num = $path-E<gt>tree_num_children_maximum()>

Return minimum 0 and maximum 2 since each node has 0, 1 or 2 children.

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<(0, tree_depth_to_n_end($depth)> where the depth for a completed
level is

    parts               depth
    -----               -----
     4            \
     3            |  4*2^level - 1  = 3, 7, 15, 31, ...
     wedge        |
     two_horiz    /
     2               4*2^level - 2  = 2, 6, 14, 30, ...
     1               4*2^level - 3  = 1, 5, 13, 29, ...
     octant       \  4*2^level - 4  = 0, 4, 12, 28, ...
     octant_up    /

parts=octant is one depth less than parts=1 because the lower eighth is one
row ahead of the upper, so parts=1 finishes one later.

parts=octant_up is the upper eighth of parts=1 but one depth less because
the octant starts at X=0,Y=1 which is one row later than parts=1.

In each case the depth is reckoned by the slowest eighth in the parts
pattern.  For example parts=two_horiz completes levels of the eighths
nearest the X axis (the "oct 2 behind" shown in L</Two Horizontal> above).

=back

=head1 FORMULAS

=head2 Depth to N

The first N at given depth is the total count of toothpicks in the preceding
rows.  The paper by Applegate, Pol and Sloane above gives formulas for
parts=4 and parts=1.  A similar formula can be made for parts=octant.

The depth in all the following is per the full pattern, which means the
octant starts at depth=2.  So oct(2)=0 then oct(3)=1.  This reckoning keeps
the replications on 2^k boundaries and is convenient for relating an octant
to the full pattern.  Note though that C<tree_depth_to_n()> always counts
from C<$depth = 0> so an adjustment +1 or +2 is applied there.

    for depth >= 2
    depth = pow + rem    where pow=2^k is the high bit of depth
                         so 0 <= rem < 2^k

    oct(2) = 0
    oct(pow) = (pow*pow - 16)/12 + pow/2
    oct(pow+1) = oct(pow) + 1
    oct(pow+rem) = oct(pow) + oct(rem+1) + 2*oct(rem) - rem + 4
                   for 2 <= rem < pow

The other parts patterns can be expressed in terms of an octant.  It's
convenient to make an octant the unit and have the others as multiples and
depth offsets from it.

    quad(d)    = oct(d) + oct(d-1) - d + 3
    half(d)    = 2*quad(d) + 1
    full(d)    = 4*quad(d) + 3
    3corner(d) = quad(d+1) + 2*quad(d) + 2
                = oct(d+1) + 3*oct(d) + 2*oct(d-1) - 3*d + 10
    wedge(d)   = 2*oct(d-1) + 4

In quad(d) the "-d" term adjusts for the stairstep diagonal spine being
counted twice by the oct(d)+oct(d-1).

The oct() recurrence corresponds to the sub-block breakdown shown under
L</One Octant> above.

    oct(pow+rem) = oct(pow)        "base"
                 + oct(rem+1)      "lower"
                 + 2*oct(rem)      "upper" and "extend"
                 - rem + 4         unduplicate diagonal

The stairstep diagonal between the "upper" and "lower" parts is duplicated
by those two parts, hence "-(rem-1)" to subtract one copy of it.  A further
+3 is the points in-between the replications, ie. the "A", "B" and one
further toothpick not otherwise counted by the replications.

oct(rem+1) + 2*oct(rem) is the important part of the recurrence.  It removes
the high bit of depth and spreads rem to an adjacent pair of smaller depths
rem+1 and rem.  A list of pending depth values can be maintained and
compared to a pow=2^k for reduction.

    for each pending depth
      if depth == 2^k or 2^k+1 then oct(pow) or oct(pow+1)
      if depth >= 2^k+2 then reduce by recurrence
    repeat for 2^(k-1)

rem+1,rem are adjacent so successive reductions make a list growing by one
further value each time, like

    d
    d+1, d
    d+2, d+1, d
    d+3, d+2, d+1, d

But when the list crosses a 2^k boundary some of these depths are reduced
and others unchanged.  When that happens the list is no longer successive
values, only mostly successive.  When accumulating rem+1 and rem it's enough
to check whether the current "rem+1" is equal to the "rem" of the previous
breakdown and if so then coalesce with that previously entry.

The factor of "2" in 2*oct(rem) is handled by keeping a desired multiplier
with each pending depth.  oct(rem+1) is the current multiplier unchanged.
2*oct(rem) doubles the current multiplier.  If rem+1 coalesces with the
previous rem then add to its multiplier.  Those additions mean the
multipliers are not powers-of-2.

If the pending list is successive integers then them rem+1,rem breakdown and
coalescing increases that list by just one value for each 1-bit of depth,
keeping the list to at most log2(depth) many entries.  But that's not so
when the list crosses a 2^k boundary.  It then behaves like two lists each
growing by one entry per bit.  In any case the list doesn't become huge.

=head2 N to Depth

The current C<tree_n_to_depth()> does a binary search for depth by calling
C<tree_depth_to_n()> on a successively narrower range.  Is there a better
approach?

Some intermediate values in the depth-to-N might be re-used by such repeated
calls, but it's not clear how many would be re-used and how many would be
needed only once.  The current code doesn't retain any such intermediates,
so large N can be handled without using a lot of memory.

=head1 OEIS

This cellular automaton is in Sloane's Online Encyclopedia of Integer
Sequences as follows, and images by Omar Pol.

=over

L<http://oeis.org/A139250> (etc)

=back

    parts=4
      A139250   total cells to given depth
      A139251    added cells at given depth
      A139253   total cells which are primes

      A147614   grid points covered at given depth
                 (including toothpick endpoints)

      A139252   line segments at given depth,
                 coalescing touching ends horiz or vert
      A139560   added segments, net of any new joins

      A162795   total cells parallel to initial (at X==Y mod 2)
      A162793    added parallel to initial
      A162796   total cells opposite to initial (at X!=Y mod 2)
      A162794    added opposite to initial
      A162797   difference total cells parallel - opposite

      http://www.polprimos.com/imagenespub/poltp4d4.jpg
      http://www.polprimos.com/imagenespub/poltp283.jpg

    parts=3
      A153006   total cells to given depth
      A152980    added cells at given depth
      A153009   total cells values which are primes

      A153007   difference depth*(depth+1)/2 - total cells,
                 which is 0 at depth=2^k-1
      A153001   added cells as "infinite row" beginning at depth=2^k

      http://www.polprimos.com/imagenespub/poltp028.jpg

    parts=2
      A152998   total cells to given depth
      A152968    added cells at given depth
      A152999   total cells values which are primes

    parts=1
      A153000   total cells to given depth
      A152978    added cells at given depth
      A153002   total cells values which are primes
      A168002   total cells mod 2, equals A079559 which is 0 or 1
                 according to n representable as sum of 2^k-1

      http://www.polprimos.com/imagenespub/poltp016.jpg

    parts=wedge
      A160406   total cells to given depth
      A160407    added cells at given depth

      http://www.polprimos.com/imagenespub/poltp406.jpg

    parts=two_horiz
      A160158   total cells to given depth
      A160159    added cells at given depth

Further sequences A153003, A153004, A153005 are another toothpick form
clipped to 3 quadrants.  They're not the same as the parts=3 corner pattern
here.  A153003 would have its X=1,Y=-1 cell as a 3rd child of X=0,Y=1.
Allowing the X=0,Y=0 and X=0,Y=-1 cells to be included would be a joined-up
pattern, but then the depth totals would be 2 bigger than those OEIS
entries.

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::ToothpickReplicate>,
L<Math::PlanePath::LCornerTree>,
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
