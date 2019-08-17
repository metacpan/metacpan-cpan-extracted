# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.



# math-image --path=SierpinskiArrowheadCentres --lines --scale=10
#
# math-image --path=SierpinskiArrowheadCentres --all --output=numbers_dash
# math-image --path=SierpinskiArrowheadCentres --all --text --size=80


package Math::PlanePath::SierpinskiArrowheadCentres;
use 5.004;
use strict;

#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 127;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_down_pow',
  'round_up_pow',
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';

# uncomment this to run the ### lines
#use Smart::Comments;


use Math::PlanePath::SierpinskiArrowhead;
*parameter_info_array  # align parameter
  = \&Math::PlanePath::SierpinskiArrowhead::parameter_info_array;
*new = \&Math::PlanePath::SierpinskiArrowhead::new;

use constant n_start => 0;
use constant class_y_negative => 0;
*x_negative = \&Math::PlanePath::SierpinskiArrowhead::x_negative;
{
  my %x_negative_at_n = (triangular => 2,
                         # right      => undef,
                         left       => 2,
                         # diagonal   => undef,
                        );
  sub x_negative_at_n {
    my ($self) = @_;
    return $x_negative_at_n{$self->{'align'}};
  }
}
*x_maximum  = \&Math::PlanePath::SierpinskiArrowhead::x_maximum;
use constant sumxy_minimum => 0;  # triangular X>=-Y
use Math::PlanePath::SierpinskiTriangle;
*diffxy_maximum = \&Math::PlanePath::SierpinskiTriangle::diffxy_maximum;

use constant dy_minimum => -1;
use constant dy_maximum => 1;
*dx_minimum = \&Math::PlanePath::SierpinskiArrowhead::dx_minimum;
*dx_maximum = \&Math::PlanePath::SierpinskiArrowhead::dx_maximum;

*_UNDOCUMENTED__dxdy_list = \&Math::PlanePath::SierpinskiArrowhead::_UNDOCUMENTED__dxdy_list; # same
use constant _UNDOCUMENTED__dxdy_list_at_n => 15;

*absdx_minimum = \&Math::PlanePath::SierpinskiArrowhead::absdx_minimum;
*absdx_maximum = \&Math::PlanePath::SierpinskiArrowhead::absdx_maximum;
*dsumxy_minimum = \&Math::PlanePath::SierpinskiArrowhead::dsumxy_minimum;
*dsumxy_maximum = \&Math::PlanePath::SierpinskiArrowhead::dsumxy_maximum;
sub ddiffxy_minimum {
  my ($self) = @_;
  return ($self->{'align'} eq 'right' ? -1 : -2);
}
sub ddiffxy_maximum {
  my ($self) = @_;
  return ($self->{'align'} eq 'right' ? 1 : 2);
}
*dir_maximum_dxdy = \&Math::PlanePath::SierpinskiArrowhead::dir_maximum_dxdy;

#------------------------------------------------------------------------------

# States as multiples of 3 so that state+digit is the lookup for next state
# and x,y bit.
#
# 0        3           6        9           12       15
#
# 8        0           4        4           0        8
# |        |           |\       |\           \        \
# 7-6      1-2         3 5      5 3         2-1      6-7
#    \        \        |  \     |  \        |        |
# 1   5    7   3       2   6    6   2       3   7    5   1
# |\   \   |\   \       \  |     \  |       |   |\   |   |\
# 0 2-3-4  8 6-5-4     0-1 7-8  8-7 1-0     4-5-6 8  4-3-2 0

#  15                   6                    3
#  6  0                 0 12                 12 6

#  0,1                  0,2                   1,2

my @next_state = (6,0,15,  12,3,9,   # 3,6
                  0,6,12,  15,9,3,   # 6,9
                  3,12,6,  9,15,0);  # 12,15
my @state_to_xbit = (0,1,0, 0,1,0,
                     0,0,1, 1,0,0,
                     0,0,1, 1,0,0);  # 12,15
my @state_to_ybit = (0,0,1, 1,0,0,
                     0,1,0, 0,1,0,
                     1,0,0, 0,0,1);  # 12,15

# dx,dy for digit==0 and digit==1 in each stage
my @state_to_dx;
my @state_to_dy;
foreach my $state (0,1, 3,4, 6,7, 9,10, 12,13, 15,16) {
  $state_to_dx[$state] = $state_to_xbit[$state+1] - $state_to_xbit[$state];
  $state_to_dy[$state] = $state_to_ybit[$state+1] - $state_to_ybit[$state];
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### SierpinskiArrowheadCentres n_to_xy(): $n
  if ($n < 0) {
    return;
  }
  if (is_infinite($n)) {
    return ($n,$n);
  }

  my $int = int($n);
  $n -= $int;  # fraction part

  my @digits = digit_split_lowtohigh($int,3);
  my $state = ($#digits & 1 ? 6 : 0);
  ### @digits
  ### $state

  my (@x,@y); # bits low to high
  my $dirstate = $state ^ 6;  # if all digits==2

  foreach my $i (reverse 0 .. $#digits) {
    ### at: "x=".join(',',@x[($i+1)..$#digits])." y=".join(',',@y[($i+1)..$#digits])."  apply  i=$i state=$state digit=$digits[$i]"

    my $digit = $digits[$i];  # high to low
    $state += $digit;
    $x[$i] = $state_to_xbit[$state];
    $y[$i] = $state_to_ybit[$state];
    if ($digit != 2) {
      $dirstate = $state; # lowest non-2 digit
    }
    $state = $next_state[$state];
  }

  my $zero = $int * 0;
  my $x = $n*$state_to_dx[$dirstate] + digit_join_lowtohigh(\@x,2,$zero);
  my $y = $n*$state_to_dy[$dirstate] + digit_join_lowtohigh(\@y,2,$zero);

  if ($self->{'align'} eq 'right') {
    $y += $x;
  } elsif ($self->{'align'} eq 'left') {
    ($x,$y) = (-$y,$x+$y);
  } elsif ($self->{'align'} eq 'triangular') {
    ($x,$y) = ($x-$y,$x+$y);
  }
  return ($x,$y);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  $x = round_nearest ($x);
  $y = round_nearest ($y);
  ### SierpinskiArrowheadCentres xy_to_n(): "$x, $y"

  if ($y < 0) {
    return undef;
  }

  if ($self->{'align'} eq 'left') {
    if ($x > 0) {
      return undef;
    }
    $x = 2*$x + $y; # adjust to triangular style

  } elsif ($self->{'align'} eq 'triangular') {
    if (($x%2) != ($y%2)) {
      return undef;
    }

  } else {
    # right or diagonal
    if ($x < 0) {
      return undef;
    }
    if ($self->{'align'} eq 'right') {
      $x = 2*$x - $y;
    } else { # diagonal
      ($x,$y) = ($x-$y, $x+$y);
      }
  }
  ### adjusted xy: "$x,$y"


  my ($len, $level) = round_down_pow ($y, 2);
  ### pow2 round up: ($y + ($y==$x || $y==-$x))
  ### $len
  ### $level
  $level += 1;

  if (is_infinite($level)) {
    return $level;
  }

  my $n = 0;
  while ($level) {
    $n *= 3;
    ### at: "$x,$y  level=$level len=$len"

    if ($y < 0 || $x < -$y || $x > $y) {
      ### out of range ...
      return undef;
    }

    if ($y < $len) {
      ### digit 0, first triangle, no change ...

    } else {
      if ($level & 1) {
        ### odd level ...
        if ($x > 0) {
          ### digit 1, right triangle ...
          $n += 1;
          $y -= $len;
          $x = - ($x-$len);
          ### shift right and mirror to: "$x,$y"
        } else {
          ### digit 2, left triangle ...
          $n += 2;
          $x += 1;
          $y -= 2*$len-1;
          ### shift down to: "$x,$y"
          ($x,$y) = ((3*$y-$x)/2,   # rotate -120
                     ($x+$y)/-2);
          ### rotate to: "$x,$y"
        }
      } else {
        ### even level ...
        if ($x < 0) {
          ### digit 1, left triangle ...
          $n += 1;
          $y -= $len;
          $x = - ($x+$len);
          ### shift right and mirror to: "$x,$y"
        } else {
          ### digit 2, right triangle ...
          $n += 2;
          $x -= 1;
          $y -= 2*$len-1;
          ### shift down to: "$x,$y"
          ($x,$y) = (($x+3*$y)/-2,             # rotate +120
                     ($x-$y)/2);
          ### now: "$x,$y"
        }
      }
    }

    $level--;
    $len /= 2;
  }

  ### final: "$x,$y with n=$n"
  if ($x == 0 && $y == 0) {
    return $n;
  } else {
    return undef;
  }
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### SierpinskiArrowheadCentres rect_to_n_range(): "$x1,$y1, $x2,$y2"

  $y1 = round_nearest ($y1);
  $y2 = round_nearest ($y2);
  if ($y1 > $y2) { ($y1,$y2) = ($y2,$y1); } # swap to y1<=y2

  if ($self->{'align'} eq 'diagonal') {
    $y2 += max (round_nearest ($x1),
                round_nearest ($x2));
  }

  unless ($y2 >= 0) {
    ### rect all negative, no N ...
    return (1, 0);
  }

  my ($len,$level) = round_down_pow ($y2, 2);
  ### $y2
  ### $level
  return (0, 3**($level+1) - 1);
}

#-----------------------------------------------------------------------------
# level_to_n_range()

# shared by SierpinskiTriangle
sub level_to_n_range {
  my ($self, $level) = @_;
  my $n_start = $self->n_start;
  return ($n_start,  $n_start + 3**$level - 1);
}
sub n_to_level {
  my ($self, $n) = @_;
  $n = $n - $self->n_start;
  if ($n < 0) { return undef; }
  if (is_infinite($n)) { return $n; }
  $n = round_nearest($n);
  my ($pow, $exp) = round_up_pow ($n+1, 3);
  return $exp;
}

#-----------------------------------------------------------------------------
1;
__END__

#------------------------------------------------------------------------------
# Old n_to_xy() triangular with explicit add/sub.

  # my $x = my $y = ($int * 0); # inherit bigint 0
  # my $len = $x + 1;           # inherit bigint 1
  # 
  # my @digits = digit_split_lowtohigh($int,3);
  # for (;;) {
  #   unless (@digits) {
  #     $x = $n + $x;
  #     $y = $n + $y;
  #     last;
  #   }
  #   my $digit = shift @digits; # low to high
  # 
  #   ### odd right: "$x, $y  len=$len  frac=$n"
  #   ### $digit
  #   if ($digit == 0) {
  #     $x = $n + $x;
  #     $y = $n + $y;
  #     $n = 0;
  # 
  #   } elsif ($digit == 1) {
  #     $x = -2*$n -$x + $len;  # mirror and offset
  #     $y += $len;
  #     $n = 0;
  # 
  #   } else {
  #     ($x,$y) = (($x+3*$y)/-2 - 1,             # rotate +120
  #                ($x-$y)/2    + 2*$len-1);
  #   }
  # 
  #   unless (@digits) {
  #     $x = -$n + $x;
  #     $y = $n + $y;
  #     last;
  #   }
  #   $digit = shift @digits; # low to high
  #   $len *= 2;
  # 
  #   ### odd left: "$x, $y  len=$len  frac=$n"
  #   ### $digit
  #   if ($digit == 0) {
  #     $x = -$n + $x;
  #     $y = $n + $y;
  #     $n = 0;
  # 
  #   } elsif ($digit == 1) {
  #     $x = 2*$n + -$x - $len;  # mirror and offset
  #     $y += $len;
  #     $n = 0;
  # 
  #   } else {
  #     ($x,$y) = ((3*$y-$x)/2 + 1,              # rotate -120
  #                ($x+$y)/-2  + 2*$len-1);
  #   }
  #   $len *= 2;
  # }
  # 
  # ### final: "$x,$y"
  # if ($self->{'align'} eq 'right') {
  #   return (($x+$y)/2, $y);
  # } elsif ($self->{'align'} eq 'left') {
  #   return (($x-$y)/2, $y);
  # } elsif ($self->{'align'} eq 'diagonal') {
  #   return (($x+$y)/2, ($y-$x)/2);
  # } else { # triangular
  #   return ($x,$y);
  # }

#------------------------------------------------------------------------------

=for stopwords eg Ryde Sierpinski Nlevel ie Math-PlanePath bitand dX dY

=head1 NAME

Math::PlanePath::SierpinskiArrowheadCentres -- self-similar triangular path traversal

=head1 SYNOPSIS

 use Math::PlanePath::SierpinskiArrowheadCentres;
 my $path = Math::PlanePath::SierpinskiArrowheadCentres->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

X<Sierpinski, Waclaw>This path is variation on Sierpinski's curve from

=over

Waclaw Sierpinski, "Sur une Courbe Dont Tout Point est un Point de
Ramification", Comptes Rendus Hebdomadaires des SE<233>ances de
l'AcadE<233>mie des Sciences, volume 160, January-June 1915, pages 302-305.
L<http://gallica.bnf.fr/ark:/12148/bpt6k31131/f302.image.langEN>

=back

=cut

# PDF download pages 304 to 307 inclusive

=pod

The path here takes the centres of each triangle represented by the
arrowhead segments.  The points visited are the same as the
C<SierpinskiTriangle> path, but traversing in a connected sequence (rather
than across rows).

              ...                                 ...
               /                                   /
        .    30     .     .     .     .     .    65     .   ...
            /                                      \        /
    28----29     .     .     .     .     .     .    66    68      9
      \                                               \  /
       27     .     .     .     .     .     .     .    67         8
         \
          26----25    19----18----17    15----14----13            7
               /        \           \  /           /
             24     .    20     .    16     .    12               6
               \        /                       /
                23    21     .     .    10----11                  5
                  \  /                    \
                   22     .     .     .     9                     4
                                          /
                       4---- 5---- 6     8                        3
                        \           \  /
                          3     .     7                           2
                           \
                             2---- 1                              1
                                 /
                                0                             <- Y=0

    -9 -8 -7 -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6  7

The base figure is the N=0 to N=2 shape.  It's repeated up in mirror image
as N=3 to N=6 then rotated across as N=6 to N=9.  At the next level the same
is done with N=0 to N=8 as the base, then N=9 to N=17 up mirrored, and N=18
to N=26 across, etc.

The X,Y coordinates are on a triangular lattice using every second integer
X, per L<Math::PlanePath/Triangular Lattice>.

The base pattern is a triangle like

      .-------.-------.
       \     / \     /
        \ 2 /   \ 1 /
         \ /     \ /
          .- - - -.
           \     /
            \ 0 /
             \ /
              .

Higher levels replicate this within the triangles 0,1,2 but the middle is
not traversed.  The result is the familiar Sierpinski triangle by connected
steps of either 2 across or 1 diagonal.

    * * * * * * * * * * * * * * * *
     *   *   *   *   *   *   *   *
      * *     * *     * *     * *
       *       *       *       *
        * * * *         * * * *
         *   *           *   *
          * *             * *
           *               *
            * * * * * * * *
             *   *   *   *
              * *     * *
               *       *
                * * * *
                 *   *
                  * *
                   *

See the C<SierpinskiTriangle> path to traverse by rows instead.

=head2 Level Ranges

Counting the N=0,1,2 part as level 1, each replication level goes from

    Nstart = 0
    Nlevel = 3^level - 1     inclusive

For example level 2 from N=0 to N=3^2-1=9.  Each level doubles in size,

                 0  <= Y <= 2^level - 1
    - (2^level - 1) <= X <= 2^level - 1

The Nlevel position is alternately on the right or left,

    Xlevel = /  2^level - 1      if level even
             \  - 2^level + 1    if level odd

The Y axis ie. X=0, is crossed just after N=1,5,17,etc which is is 2/3
through the level, which is after two replications of the previous level,

    Ncross = 2/3 * 3^level - 1
           = 2 * 3^(level-1) - 1

=head2 Align Parameter

An optional C<align> parameter controls how the points are arranged relative
to the Y axis.  The default shown above is "triangular".  The choices are
the same as for the C<SierpinskiTriangle> path.

"right" means points to the right of the axis, packed next to each other and
so using an eighth of the plane.

=cut

# math-image --path=SierpinskiArrowheadCentres,align=right --all --output=numbers_dash

=pod

    align => "right"

        |   |
     7  |  26-25 19-18-17 15-14-13     
        |    /    |     |/     /       
     6  |  24    20    16    12        
        |   |   /           /          
     5  |  23 21       10-11           
        |   |/          |              
     4  |  22           9              
        |             /                
     3  |   4--5--6  8                 
        |   |     |/                   
     2  |   3     7                    
        |   |                          
     1  |   2--1                       
        |    /                         
    Y=0 |   0                          
        +--------------------------
           X=0 1  2  3  4  5  6  7

"left" is similar but skewed to the left of the Y axis, ie. into negative X.

=cut

# math-image --path=SierpinskiArrowheadCentres,align=left --all --output=numbers_dash

=pod

    align => "left"

    \                         |
     26-25 19-18-17 15-14-13  |  7 
         |   \     \ |     |  |    
        24    20    16    12  |  6 
          \    |           |  |    
           23 21       10-11  |  5 
             \ |         \    |    
              22           9  |  4 
                           |  |    
                  4--5--6  8  |  3 
                   \     \ |  |    
                     3     7  |  2 
                      \       |    
                        2--1  |  1 
                           |  |    
                           0  | Y=0
    --------------------------+

     -7 -6 -5 -4 -3 -2 -1 X=0

"diagonal" puts rows on diagonals down from the Y axis to the X axis.  This
uses the whole of the first quadrant, with gaps.

=cut

# math-image --expression='i<=26?i:0' --path=SierpinskiArrowheadCentres,align=diagonal --output=numbers_dash

=pod

    align => "diagonal"

        |   |                     
     7  |  26                     
        |    \                    
     6  |  24-25                  
        |   |                     
     5  |  23    19               
        |   |     |\              
     4  |  22-21-20 18            
        |             \           
     3  |   4          17         
        |   |\          |         
     2  |   3  5       16-15      
        |   |   \           \     
     1  |   2     6    10    14   
        |    \    |     |\     \  
    Y=0 |   0--1  7--8--9 11-12-13
        +--------------------------
           X=0 1  2  3  4  5  6  7

These diagonals visit all points X,Y where X and Y written in binary have no
1-bits in the same places, ie. where S<X bitand Y> = 0.  This is the same as
the C<SierpinskiTriangle> with align=diagonal.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::SierpinskiArrowheadCentres-E<gt>new ()>

=item C<$path = Math::PlanePath::SierpinskiArrowheadCentres-E<gt>new (align =E<gt> $str)>

Create and return a new arrowhead path object.  C<align> is a string, one of
the following as described above.

    "triangular"       the default
    "right"
    "left"
    "diagonal"

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

If C<$n> is not an integer then the return is on a straight line between the
integer points.

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<(0, 3**$level - 1)>.

=back

=head1 FORMULAS

=head2 N to X,Y

The align="diagonal" style is the most convenient to calculate.  Each
ternary digit of N becomes a bit of X and Y.

    ternary digits of N, high to low
        xbit = state_to_xbit[state+digit]
        ybit = state_to_ybit[state+digit]
        state = next_state[state+digit]

There's a total of 6 states which are the permutations of 0,1,2 in the three
triangular parts.  The states are in pairs as forward and reverse, but that
has no particular significance.  Numbering the states by "3"s allows the
digit 0,1,2 to be added to make an index into tables for X,Y bit and next
state.

    state=0     state=3      
    +---------+ +---------+  
    |^ 2 |    | |\ 0 |    |  
    | \  |    | | \  |    |  
    |  \ |    | |  v |    |  
    |----+----| |----+----|  
    |    |^   | |    ||   |  
    | 0  || 1 | | 0  || 1 |  
    |--->||   | |<---|v   |  
    +---------+ +---------+  

    state=6      state=9     
    +---------+  +---------+ 
    |    |    |  |    |    | 
    | 1  |    |  | 1  |    | 
    |--->|    |  |<---|    | 
    |----+----|  |----+----| 
    |^   |\ 2 |  ||   |^   | 
    ||0  | \  |  || 2 | \0 | 
    ||   |  v |  |v   |  \ | 
    +---------+  +---------+ 

    state=12     state=15    
    +---------+  +---------+ 
    || 0 |    |  |^   |    | 
    ||   |    |  || 2 |    | 
    |v   |    |  ||   |    | 
    |----+----|  |----+----| 
    |\ 1 |    |  |^ 1 |    | 
    | \  | 2  |  | \  |  0 | 
    |  v |--->|  |  \ |<---| 
    +---------+  +---------+ 

The initial state is 0 if an even number of ternary digits, or 6 if odd.  In
the samples above it can be seen for example that N=0 to N=8 goes upwards as
per state 0, whereas N=0 to N=2 goes across as per state 6.

Having calculated an X,Y in align="diagonal" style it can be mapped to the
other alignments by

    align        coordinates from diagonal X,Y
    -----        -----------------------------
    triangular      X-Y, X+Y
    right           X, X+Y
    left            -Y, X+Y    

=head2 N to dX,dY

For fractional N the direction of the curve towards the N+1 point can be
found from the least significant digit 0 or 1 (ie. a non-2 digit) and the
state at that point.

This works because if the least significant ternary digit of N is a 2 then
the direction of the curve is determined by the next level up, and so on for
all trailing 2s until reaching a non-2 digit.

If N is all 2s then the direction should be reckoned from an initial 0 digit
above them, which means the opposite 6 or 0 of the initial state.

=head2 Rectangle to N Range

An easy over-estimate of the range can be had from inverting the Nlevel
formulas in L</Level Ranges> above.

    level = floor(log2(Ymax)) + 1
    Nmax = 3^level - 1

For example Y=5, level=floor(log2(11))+1=3, so Nmax=3^3-1=26, which is the
left end of the Y=7 row, ie. rounded up to the end of the Y=4 to Y=7
replication.

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::SierpinskiArrowhead>,
L<Math::PlanePath::SierpinskiTriangle>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018 Kevin Ryde

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
