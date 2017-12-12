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


# math-image --path=GosperReplicate --lines --scale=10
# math-image --path=GosperReplicate --all --output=numbers_dash
# math-image --path=GosperReplicate,numbering_type=rotate --all --output=numbers_dash
#

package Math::PlanePath::GosperReplicate;
use 5.004;
use strict;
use List::Util qw(max);
use POSIX 'ceil';
use Math::Libm 'hypot';
use Math::PlanePath::SacksSpiral;

use vars '$VERSION', '@ISA';
$VERSION = 125;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_up_pow',
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';

# uncomment this to run the ### lines
#use Smart::Comments;


use constant parameter_info_array =>
  [ { name            => 'numbering_type',
      display         => 'Numbering',
      share_key       => 'numbering_type_rotate',
      type            => 'enum',
      default         => 'fixed',
      choices         => ['fixed','rotate'],
      choices_display => ['Fixed','Rotate'],
      description     => 'Fixed or rotating sub-part numbering.',
    },
  ];

use constant n_start => 0;
*xy_is_visited = \&Math::PlanePath::Base::Generic::xy_is_even;

use constant x_negative_at_n => 3;
use constant y_negative_at_n => 5;
use constant absdx_minimum => 1;
use constant dir_maximum_dxdy => (3,-1);

#------------------------------------------------------------------------------
sub new {
  my $self = shift->SUPER::new (@_);
  $self->{'numbering_type'} ||= 'fixed';  # default
  return $self;
}

sub _digits_rotate_lowtohigh {
  my ($aref) = @_;
  my $rot = 0;
  foreach my $digit (reverse @$aref) {
    if ($digit) {
      $rot += $digit-1;
      $digit = ($rot % 6) + 1;  # mutate $aref
    }
  }
}
sub _digits_unrotate_lowtohigh {
  my ($aref) = @_;
  my $rot = 0;
  foreach my $digit (reverse @$aref) {
    if ($digit) {
      $digit = ($digit-1-$rot) % 6;  # mutate $aref
      $rot += $digit;
      $digit++;
    }
  }
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### GosperReplicate n_to_xy(): $n

  if ($n < 0) {
    return;
  }
  if (is_infinite($n)) {
    return ($n,$n);
  }

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

  my $x = my $y = $n*0;  # inherit bigint from $n
  my $sx = $x + 2;  # 2
  my $sy = $x;      # 0

  # digit
  #       3   2
  #        \ /
  #     4---0---1
  #        / \
  #       5   6

  my @digits = digit_split_lowtohigh($n,7);
  if ($self->{'numbering_type'} eq 'rotate') {
    _digits_rotate_lowtohigh(\@digits);
  }

  foreach my $digit (@digits) {
    ### digit: "$digit  $x,$y  side $sx,$sy"

    if ($digit == 1) {
      ### right ...
      # $x = -$x;  # rotate 180
      # $y = -$y;
      $x += $sx;
      $y += $sy;
    } elsif ($digit == 2) {
      ### up right ...
      # ($x,$y) = ((3*$y-$x)/2,   # rotate -120
      #            ($x+$y)/-2);
      $x += ($sx - 3*$sy)/2;    # at +60
      $y += ($sx + $sy)/2;

    } elsif ($digit == 3) {
      ### up left ...
      # ($x,$y) = (($x+3*$y)/2,   # -60
      #            ($y-$x)/2);
      $x += ($sx + 3*$sy)/-2;   # at +120
      $y += ($sx - $sy)/2;

    } elsif ($digit == 4) {
      ### left
      $x -= $sx;                # at -180
      $y -= $sy;

    } elsif ($digit == 5) {
      ### down left
      # ($x,$y) = (($x-3*$y)/2,    # rotate +60
      #            ($x+$y)/2);
      $x += (3*$sy - $sx)/2;    # at -120
      $y += ($sx + $sy)/-2;

    } elsif ($digit == 6) {
      ### down right
      # ($x,$y) = (($x+3*$y)/-2,  # rotate +120
      #            ($x-$y)/2);
      $x += ($sx + 3*$sy)/2;    # at -60
      $y += ($sy - $sx)/2;
    }

    # 2*(sx,sy) + rot+60(sx,sy)
    ($sx,$sy) = ((5*$sx - 3*$sy) / 2,
                 ($sx + 5*$sy) / 2);
  }
  return ($x,$y);
}

# modulus
#       1   3
#        \ /
#     5---0---2
#        / \
#       4   6
#                       0  1  2  3  4  5  6
my @modulus_to_x     = (0,-1, 2, 1,-1,-2, 1);
my @modulus_to_y     = (0, 1, 0, 1,-1, 0,-1);
my @modulus_to_digit = (0, 3, 1, 2, 5, 4, 6);

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### GosperReplicate xy_to_n(): "$x, $y"

  $x = round_nearest($x);
  $y = round_nearest($y);
  if (($x + $y) % 2) {
    return undef;
  }

  my $level = _xy_to_level_ceil($x,$y);
  if (is_infinite($level)) {
    return $level;
  }

  my $zero = ($x * 0 * $y);  # inherit bignum 0
  my @n; # digits low to high

  while ($level-- >= 0 && ($x || $y)) {
    ### at: "$x,$y  m=".(($x + 2*$y) % 7)

    my $m = ($x + 2*$y) % 7;
    push @n, $modulus_to_digit[$m];
    $x -= $modulus_to_x[$m];
    $y -= $modulus_to_y[$m];

    ### digit: "to $x,$y"
    ### assert: (3 * $y + 5 * $x) % 14 == 0
    ### assert: (5 * $y - $x) % 14 == 0

    # shrink
    ($x,$y) = ((3*$y + 5*$x) / 14,
               (5*$y - $x) / 14);
  }

  if ($self->{'numbering_type'} eq 'rotate') {
    _digits_unrotate_lowtohigh(\@n);
  }
  return digit_join_lowtohigh (\@n, 7, $zero);
}


# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  $y1 *= sqrt(3);
  $y2 *= sqrt(3);
  my ($r_lo, $r_hi) = Math::PlanePath::SacksSpiral::_rect_to_radius_range
    ($x1,$y1, $x2,$y2);
  $r_hi *= 2;
  my $level_plus_1 = ceil( log(max(1,$r_hi/4)) / log(sqrt(7)) ) + 2;
  return (0, 7**$level_plus_1 - 1);
}

sub _xy_to_level_ceil {
  my ($x,$y) = @_;
  my $r = hypot($x,$y);
  $r *= 2;
  return ceil( log(max(1,$r/4)) / log(sqrt(7)) ) + 1;
}

#------------------------------------------------------------------------------
# levels

sub level_to_n_range {
  my ($self, $level) = @_;
  return (0, 7**$level - 1);
}
sub n_to_level {
  my ($self, $n) = @_;
  if ($n < 0) { return undef; }
  if (is_infinite($n)) { return $n; }
  $n = round_nearest($n);
  my ($pow, $exp) = round_up_pow ($n+1, 7);
  return $exp;
}


#------------------------------------------------------------------------------
1;
__END__

=for stopwords eg Ryde Gosper Math-PlanePath

=head1 NAME

Math::PlanePath::GosperReplicate -- self-similar hexagon replications

=head1 SYNOPSIS

 use Math::PlanePath::GosperReplicate;
 my $path = Math::PlanePath::GosperReplicate->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This is a self-similar hexagonal tiling of the plane.  At each level the
shape is the Gosper island.

                         17----16                     4
                        /        \
          24----23    18    14----15                  3
         /        \     \
       25    21----22    19----20    10---- 9         2
         \                          /        \
          26----27     3---- 2    11     7---- 8      1
                     /        \     \
       31----30     4     0---- 1    12----13     <- Y=0
      /        \     \
    32    28----29     5---- 6    45----44           -1
      \                          /        \
       33----34    38----37    46    42----43        -2
                  /        \     \
                39    35----36    47----48           -3
                  \
                   40----41                          -4

                          ^
    -7 -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6  7

Points are spread out on every second X coordinate to make a triangular
lattice in integer coordinates (see L<Math::PlanePath/Triangular Lattice>).

The base pattern is the inner N=0 to N=6, then six copies of that shape are
arranged around as the blocks N=7,14,21,28,35,42.  Then six copies of the
resulting N=0 to N=48 shape are replicated around, etc.

Each point can be taken as a little hexagon, so that all points tile the
plane with hexagons.  The innermost N=0 to N=6 are for instance,

          *     *
         / \   / \
        /   \ /   \
       *     *     *
       |  3  |  2  |
       *     *     *
      / \   / \   / \
     /   \ /   \ /   \
    *     *     *     *
    |  4  |  0  |  1  |
    *     *     *     *
     \   / \   / \   /
      \ /   \ /   \ /
       *     *     *
       |  5  |  6  |
       *     *     *
        \   / \   /
         \ /   \ /
          *     *

The further replications are the same arrangement, but the sides become ever
wigglier and the centres rotate around.  The rotation can be seen N=7 at
X=5,Y=1 which is up from the X axis.

The C<FlowsnakeCentres> path is this same replicating shape, but starting
from a side instead of the middle and traversing in such as way as to make
each N adjacent.  The C<Flowsnake> curve itself is this replication too, but
segments across hexagons.

=head2 Complex Base

The path corresponds to expressing complex integers X+i*Y in a base

    b = 5/2 + i*sqrt(3)/2

=cut

# GP-DEFINE  sqrt3  = quadgen(12);
# GP-DEFINE  sqrt3i = quadgen(-12);
# GP-Test  sqrt3^2  == 3
# GP-Test  sqrt3i^2 == -3
# GP-DEFINE  b = 5/2 + sqrt3i/2;

=pod

with coordinates scaled to put equilateral triangles on a square grid.  So
for integer X,Y on the triangular grid (X,Y either both odd or both even),

    X/2 + i*Y*sqrt(3)/2 = a[n]*b^n + ... + a[2]*b^2 + a[1]*b + a[0]

where each digit a[i] is either 0 or a sixth root of unity encoded into
base-7 digits of N,

     w6 = e^(i*pi/3)            sixth root of unity, b = 2 + w6
        = 1/2 + i*sqrt(3)/2

     N digit     a[i] complex number
     -------     -------------------
       0          0
       1         w6^0 =  1
       2         w6^1 =  1/2 + i*sqrt(3)/2
       3         w6^2 = -1/2 + i*sqrt(3)/2
       4         w6^3 = -1
       5         w6^4 = -1/2 - i*sqrt(3)/2
       6         w6^5 =  1/2 - i*sqrt(3)/2

=cut

# GP-DEFINE  w6 = 1/2 + sqrt3i/2;
# GP-Test  w6^6 == 1

# GP-Test  w6^0 == 1
# GP-Test  w6^1 ==  1/2 + sqrt3i/2
# GP-Test  w6^2 == -1/2 + sqrt3i/2
# GP-Test  w6^3 == -1
# GP-Test  w6^4 == -1/2 - sqrt3i/2
# GP-Test  w6^5 ==  1/2 - sqrt3i/2
# GP-Test  (5/2)^2 + (sqrt3/2)^2 == 7

# GP-DEFINE  z_digit(d) = [0, 1,w6,w6^2, -1,w6^4,w6^5][d+1];
# GP-DEFINE  z_point(n) = \
# GP-DEFINE    subst(Pol(apply(z_digit,digits(n,7))),'x,b);
# GP-Test  z_point(0) == 0
# GP-Test  z_point(1) == 1
# GP-Test  z_point(2) == w6
# GP-Test  z_point(7) == w6+2

# GP-DEFINE  nearly_equal_epsilon = 1e-15;
# GP-DEFINE  nearly_equal(x,y, epsilon=nearly_equal_epsilon) = \
# GP-DEFINE    abs(x-y) < epsilon;
# GP-DEFINE  to_base7(n) = fromdigits(digits(n,7));
# GP-DEFINE  from_base7(n) = fromdigits(digits(n),7);

=pod

7 digits suffice because

     norm(b) = (5/2)^2 + (sqrt(3)/2)^2 = 7

=cut

# GP-Test  norm(b) == 7
# GP-Test  (5/2)^2 + (sqrt3/2)^2 == 7

=pod

=head2 Rotate Numbering

Parameter C<numbering_type =E<gt> 'rotate'> applies a rotation in each
sub-part according to its location around the preceding level.

The effect can be illustrated by writing N in base-7.  Part 10-16 is the
same as the middle 0-6.  Part 20-26 has a rotation by +60 degrees.  Part
30-36 has rotation by +120 degrees, and so on.

=cut

# start from this, then mangled by hand
# math-image --path=GosperReplicate,numbering_type=rotate --all --output=numbers_dash

=pod

                         22----21
                        /     /           numbering_type => 'rotate'
          31    36    23    20    26          N shown in base-7
         /  \     \     \        /
       32    30    35    24----25    13----12
         \        /                 /        \
          33----34     3---- 2    14    10----11
                     /        \     \
       46----45     4     0---- 1    15----16
               \     \
    41----40    44     5---- 6    64----63
      \        /                 /        \
       42----43    55----54    65    60    62
                  /        \     \     \  /
                56    50    53    66    61
                     /     /
                   51----52

Notice this means in each part the 11, 21, 31, etc, points are directed
away from the middle in the same way, relative to the sub-part locations.

Working through the expansions gives the following rule for when an N is
on the boundary of level k,

    write N in k many base-7 digits  (empty string if k=0)
    if any 0 digit then non-boundary
    ignore high digit and all 1 digits
    if any 4 or 5 digit then non-boundary
    if any 32, 33, 66 pair then non-boundary

A 0 digit is the middle of a block, or 4 or 5 digit the inner side of a
block, for kE<gt>=1, hence non-boundary.  After that the 6,1,2,3 parts
variously expand with rotations so that a 66 is enclosed on the clockwise
side and 32 and 33 on the anti-clockwise side.

=cut

# in decimal
#                      16----15
#                     /     /
#       22    27    17    14    20
#      /  \     \     \        /
#    23    21    26    18----19    10---- 9
#      \        /                 /        \
#       24----25     3---- 2    11     7---- 8
#                  /        \     \
#    34----33     4     0---- 1    12----13
#            \     \
# 29----28    32     5---- 6    46----45
#   \        /                 /        \
#    30----31    40----39    47    42    44
#               /        \     \     \  /
#             41    35    38    48    43
#                  /     /
#                36----37

=pod

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::GosperReplicate-E<gt>new ()>

=item C<$path = Math::PlanePath::GosperReplicate-E<gt>new (numbering_type =E<gt> $str)>

Create and return a new path object.  The C<numbering_type> parameter can be

    "fixed"        (default)
    "rotate"

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<(0, 7**$level - 1)>.

=back

=head1 FORMULAS

=head2 Axis Rotations

In the fixed numbering, digit positions 1,2,3,4,5,6 go around +60deg each,
so the N for rotation of X,Y by +60 degrees is each digit +1.

    N          = 0, 1, 2, 3, 4, 5, 6, 10, 11, 12

    rot+60(N)  = 0, 2, 3, 4, 5, 6, 1, 14, 16, 17, ... decimal
               = 0, 2, 3, 4, 5, 6, 1, 20, 22, 23, ... base7

    rot+120(N) = 0, 3, 4, 5, 6, 1, 2, 21, 24, 25, ... decimal
               = 0, 3, 4, 5, 6, 1, 2, 30, 33, 34, ... base7

    etc

=cut

    # rot180(N)  = 0, 4, 5, 6, 1, 2, 3, 28, 32, 33, ... decimal
    #            = 0, 4, 5, 6, 1, 2, 3, 40, 44, 45, ... base7
    #
    # rot-120(N) = 0, 5, 6, 1, 2, 3, 4, 35, 40, 41, ... decimal
    #            = 0, 5, 6, 1, 2, 3, 4, 50, 55, 56, ... base7
    #
    # rot-60(N)  = 0, 6, 1, 2, 3, 4, 5, 42, 48, 43, ... decimal
    #            = 0, 6, 1, 2, 3, 4, 5, 60, 66, 61, ... base7

# GP-DEFINE  digit_plus1(d)  = [0,2,3,4,5,6,1][d+1];
# GP-DEFINE  digit_plus2(d)  = [0,3,4,5,6,1,2][d+1];
# GP-DEFINE  digit_plus3(d)  = [0,4,5,6,1,2,3][d+1];
# GP-DEFINE  digit_minus2(d) = [0,5,6,1,2,3,4][d+1];
# GP-DEFINE  digit_minus1(d) = [0,6,1,2,3,4,5][d+1];
# GP-DEFINE  N_rotate_plus60(n) = fromdigits(apply(digit_plus1, digits(n,7)),7);
# GP-DEFINE  N_rotate_plus120(n)= fromdigits(apply(digit_plus2, digits(n,7)),7);
# GP-DEFINE  N_rotate_180(n)    = fromdigits(apply(digit_plus3, digits(n,7)),7);
# GP-DEFINE  N_rotate_minus120(n)=fromdigits(apply(digit_minus2,digits(n,7)),7);
# GP-DEFINE  N_rotate_minus60(n)= fromdigits(apply(digit_minus1,digits(n,7)),7);

# GP-Test  my(v=[0, 2, 3, 4, 5, 6, 1, 14, 16, 17]); /* samples shown */ \
# GP-Test    vector(#v,n,n--; N_rotate_plus60(n)) == v
# GP-Test  my(v=[0, 2, 3, 4, 5, 6, 1, 20, 22, 23]); /* samples shown */ \
# GP-Test    vector(#v,n,n--; to_base7(N_rotate_plus60(n))) == v

# GP-Test  my(v=[0, 3, 4, 5, 6, 1, 2, 21, 24, 25]); /* samples shown */ \
# GP-Test    vector(#v,n,n--; N_rotate_plus120(n)) == v
# GP-Test  my(v=[0, 3, 4, 5, 6, 1, 2, 30, 33, 34]); /* samples shown */ \
# GP-Test    vector(#v,n,n--; to_base7(N_rotate_plus120(n))) == v

# GP-Test  my(v=[0, 4, 5, 6, 1, 2, 3, 28, 32, 33]); /* samples shown */ \
# GP-Test    vector(#v,n,n--; N_rotate_180(n)) == v
# GP-Test  my(v=[0, 4, 5, 6, 1, 2, 3, 40, 44, 45]); /* samples shown */ \
# GP-Test    vector(#v,n,n--; to_base7(N_rotate_180(n))) == v

# GP-Test  my(v=[0, 5, 6, 1, 2, 3, 4, 35, 40, 41]); /* samples shown */ \
# GP-Test    vector(#v,n,n--; N_rotate_minus120(n)) == v
# GP-Test  my(v=[0, 5, 6, 1, 2, 3, 4, 50, 55, 56]); /* samples shown */ \
# GP-Test    vector(#v,n,n--; to_base7(N_rotate_minus120(n))) == v

# GP-Test  my(v=[0, 6, 1, 2, 3, 4, 5, 42, 48, 43]); /* samples shown */ \
# GP-Test    vector(#v,n,n--; N_rotate_minus60(n)) == v
# GP-Test  my(v=[0, 6, 1, 2, 3, 4, 5, 60, 66, 61]); /* samples shown */ \
# GP-Test    vector(#v,n,n--; to_base7(N_rotate_minus60(n))) == v

# GP-Test  vector(500,n,n--; z_point(N_rotate_plus60(n))) == \
# GP-Test  vector(500,n,n--; w6*z_point(n))

# GP-Test  vector(500,n,n--; z_point(N_rotate_plus120(n))) == \
# GP-Test  vector(500,n,n--; w6^2*z_point(n))

# GP-Test  vector(500,n,n--; z_point(N_rotate_180(n))) == \
# GP-Test  vector(500,n,n--; -z_point(n))

# GP-Test  vector(500,n,n--; z_point(N_rotate_minus120(n))) == \
# GP-Test  vector(500,n,n--; conj(w6)^2*z_point(n))

# GP-Test  vector(500,n,n--; z_point(N_rotate_minus60(n))) == \
# GP-Test  vector(500,n,n--; conj(w6)*z_point(n))

# not in OEIS: 2, 3, 4, 5, 6, 1, 14, 16, 17
# not in OEIS: 2, 3, 4, 5, 6, 1, 20, 22, 23

# not in OEIS: 3, 4, 5, 6, 1, 2, 21, 24, 25
# not in OEIS: 3, 4, 5, 6, 1, 2, 30, 33, 34

# not in OEIS: 4, 5, 6, 1, 2, 3, 28, 32, 33
# not in OEIS: 4, 5, 6, 1, 2, 3, 40, 44, 45

# not in OEIS: 5, 6, 1, 2, 3, 4, 35, 40, 41
# not in OEIS: 5, 6, 1, 2, 3, 4, 50, 55, 56

# not in OEIS: 6, 1, 2, 3, 4, 5, 42, 48, 43
# not in OEIS: 6, 1, 2, 3, 4, 5, 60, 66, 61

=pod

In the rotate numbering, just adding +1 (etc) at the high digit alone is
rotation.

=cut

# GP-DEFINE  n_rotate_highdigit(n,offset) = {
# GP-DEFINE    my(v=digits(n));
# GP-DEFINE    v[1] = ((v[1]-1+offset)%6) + 1;
# GP-DEFINE    fromdigits(v,7);
# GP-DEFINE  }

# for(offset=1,6,print(vector(18,n, n_rotate_highdigit(n,offset))))
# not in OEIS: 2, 3, 4, 5, 6, 1, 2, 3, 4, 14, 15, 16, 17, 18, 19, 20, 21, 22
# not in OEIS: 3, 4, 5, 6, 1, 2, 3, 4, 5, 21, 22, 23, 24, 25, 26, 27, 28, 29
# not in OEIS: 4, 5, 6, 1, 2, 3, 4, 5, 6, 28, 29, 30, 31, 32, 33, 34, 35, 36
# not in OEIS: 5, 6, 1, 2, 3, 4, 5, 6, 1, 35, 36, 37, 38, 39, 40, 41, 42, 43
# not in OEIS: 6, 1, 2, 3, 4, 5, 6, 1, 2, 42, 43, 44, 45, 46, 47, 48, 49, 50
# not in OEIS: 1, 2, 3, 4, 5, 6, 1, 2, 3, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16

=pod

=head2 X,Y Extents

The maximum X in a given level N=0 to 7^k-1 can be calculated from the
replications.  A given high digit 1 to 6 has sub-parts located at
b^k*w6^(d-1).  Those sub-parts are all the same, so the one with maximum
real(b^k*w6^(d-1)) contains the maximum X.

    N_xmax_digit(j) = d=1to6 where real(w6^(d-1) * b^j) is maximum
                    = 1,1,6,6,6,5,5,5,4,4,4,3,3,3,3,2,2, ...

                 k-1
    N_xmax(k) = digits N_xmax_digit(j)    low digit j=0
                 j=0
              = 0, 1, 8, 302, 2360, 16766, 100801, ...  decimal
              = 0, 1, 11, 611, 6611, 66611, 566611, ...  base7

                k-1
    z_xmax(k) = sum  w6^d[j] * b^j
                j=0      each d[j] with real(w6^d[j] * b^j) maximum
          = 0, 1, 7/2+1/2*sqrt3*i, 10-sqrt3*i, 57/2-3/2*sqrt3*i,...

    xmax(k) = 2*real(z_xmax(k))
            = 0, 2, 7, 20, 57, 151, 387, 1070, 2833, 7106, ...

=cut

# GP-DEFINE  N_xmax_digit(j) = \
# GP-DEFINE    my(p=b^j,d); vecmax(vector(6,d,real(w6^(d-1)*p)),&d); d;
# GP-Test  my(v=[1,1,6,6,6,5,5,5,4,4,4,3,3,3,3,2,2]); /* samples shown */ \
# GP-Test    vector(#v,j,j--; N_xmax_digit(j)) == v

# GP-DEFINE  N_xmax(k) = fromdigits(Vecrev(vector(k,j,j--; N_xmax_digit(j))),7);
# GP-Test  my(v=[0, 1, 8, 302, 2360, 16766, 100801]); /* samples shown */ \
# GP-Test    vector(#v,j,j--; N_xmax(j)) == v
# GP-Test  my(v=[0, 1, 11, 611, 6611, 66611, 566611]); /* samples shown */ \
# GP-Test    vector(#v,j,j--; to_base7(N_xmax(j))) == v
# GP-Test  to_base7(N_xmax(51)) \
# GP-Test    == 334445556661112222333444555666111222333344455566611

# GP-DEFINE  z_xmax(k) = {
# GP-DEFINE    sum(j=0,k-1,
# GP-DEFINE        my(p=b^j, v=vector(6,d,(w6^(d-1)*p)), i);
# GP-DEFINE        vecmax(real(v),&i);
# GP-DEFINE        v[i]);
# GP-DEFINE  }
# GP-Test  my(v=[0, 1, 7/2+1/2*sqrt3i, 10-sqrt3i, 57/2-3/2*sqrt3i]); \
# GP-Test    vector(#v,k,k--; z_xmax(k)) == v
# GP-Test  z_xmax(0) == 0
# GP-Test  z_xmax(1) == 1
# GP-Test  z_point(7) == 5/2 + 1/2*sqrt3i
# GP-Test  z_point(8) == 7/2 + 1/2*sqrt3i

# GP-DEFINE  xmax(k) = real(z_xmax(k));
# GP-Test  my(v=[0, 2, 7, 20, 57, 151, 387, 1070, 2833, 7106]); \
# GP-Test    vector(#v,k,k--; 2*xmax(k)) == v
# GP-Test  2*xmax(45) == 12321054172600214702
# GP-Test  2*xmax(2) == 7  /* X of N=8 shown in sample numbers */

# vector(15,k,k--; N_xmax_digit(k))
# not in OEIS: 1, 1, 6, 6, 6, 5, 5, 5, 4, 4, 4, 3, 3, 3, 3

# vector(8,k,k++; N_xmax(k))
# vector(8,k,k++; to_base7(N_xmax(k)))
# not in OEIS: 8, 57, 400, 10004, 77232, 547828, 3018457, 20312860
# not in OEIS: 11, 111, 1111, 41111, 441111, 4441111, 34441111, 334441111

# vector(6,k,k--; z_xmax(k))
# vector(8,k, norm(z_xmax(k)))
# vector(10,k,k++; 2*real(z_xmax(k)))
# vector(10,k,k++; 2*imag(z_xmax(k)))
# vector(10,k,k++; real(z_xmax(k))+imag(z_xmax(k)))
# not in OEIS: 1, 13, 103, 819, 5827, 39243, 291772, 2026399       \\ norm
# not in OEIS: 7, 20, 57, 151, 387, 1070, 2833, 7106, 19686, 52675 \\ real
# not in OEIS: 1, -2, -3, 13, -49, -86, 163, -1102, -2128, 1597    \\ imag
# not in OEIS: 4, 9, 27, 82, 169, 492, 1498, 3002, 8779, 27136     \\ real+imag

# GP-DEFINE  z_points(k) = vector(7^k,n,n--; z_point(n));
# GP-DEFINE  N_xmax_by_points(k) = my(n); vecmax(real(z_points(k)),&n); n-1;
# GP-Test  vector(5,k,k--; N_xmax_by_points(k)) == \
# GP-Test  vector(5,k,k--; N_xmax(k))
# GP-Test  z_point(302) == 10 - sqrt3i
# GP-Test  z_point(57)  ==  9 + 3*sqrt3i
# GP-Test  to_base7(302) == 611
# GP-Test  to_base7(57)  == 111

=pod

For computer calculation these maximums can be calculated from the powers.
The parts resulting can also be written in terms of the angle

    arg(b) = atan(sqrt(3)/5) = 19.106... degrees

=cut

# GP-DEFINE  b_angle = arg(b);
# GP-DEFINE  b_angle_degrees = b_angle * 180/Pi;
# GP-Test  nearly_equal( b_angle, atan(sqrt3/5) )
# GP-Test  b_angle_degrees > 19.106
# GP-Test  b_angle_degrees < 19.106+1/10^3
# not in OEIS: 0.333473172251832115336090     \\ radians
# not in OEIS: 19.1066053508690943945174      \\ degrees

=pod

For successive k, if adding this pushes the b^k angle past +30deg then the
preceding digit goes past -30deg and becomes the new maximum X.  Write the
angle as a fraction of 60deg (pi/3),

    F = atan(sqrt(3)/5) / (pi/3)  = 0.318443 ...

=cut

# GP-DEFINE  angle_F = atan(sqrt3/5) / (Pi/3);
# GP-Test  angle_F > 0.318443
# GP-Test  angle_F < 0.318443 + 1/10^6
# not in OEIS: 0.318443422514484906575291

=pod

This is irrational since b^k is never on the X or Y axes.  That can be seen
since 2/sqrt3*imag(b^k) mod 7 goes in a repeating pattern 1,5,4,6,2,3.
Similarly 2*real(b^k) mod 7 so not on the Y axis, and also anything on the Y
axis would have 3*k fall on the X axis.

=cut

# GP-DEFINE  is_integer(x) = (x==floor(x));
# GP-Test  vector(100,k,k--; is_integer(imag(2*b^k))) == vector(100,k,1)
# GP-Test  vector(100,k,k--; imag(2*b^k)%7) == \
# GP-Test  vector(100,k,k--; if(k==0,0, [1,5,4,6,2,3][(k-1)%6+1]))
#
# GP-Test  vector(100,k,k--; is_integer(real(2*b^k))) == vector(100,k,1)
# GP-Test  vector(100,k,k--; real(2*b^k)%7) == \
# GP-Test  vector(100,k,k--; if(k==0,2, [5, 4, 6, 2, 3, 1][(k-1)%6+1]))

=pod

Digits low to high are successive steps back cyclically 6,5,4,3,2,1 so that
(with mod giving 0 to 5),

    N_xmax_digit(j) = (-floor(F*j+1/2) mod 6) + 1

=cut

# GP-DEFINE  N_xmax_digit_by_floor(j) = (-floor(angle_F*j+1/2) % 6) + 1;
# GP-Test  vector(1000,j,j--; N_xmax_digit_by_floor(j)) == \
# GP-Test  vector(1000,j,j--; N_xmax_digit(j))

=pod

The +1/2 is since initial direction b^0=1 is angle 0 which is half way
between -30 and +30 deg.

Similarly for the location, using conj(w6) for rotation back

    z_xmax_exp(j) = floor(F*j+1/2)
                  = 0,0,1,1,1,2,2,2,3,3,3,4,4,4,4,5,5,5, ...
    z_xmax(k) = sum(j=0,k-1, conj(w6)^z_xmax_exp(j) * b^j)

=cut

# GP-DEFINE  z_xmax_exp(j) = floor(angle_F*j+1/2);
# GP-Test  my(v=[0,0,1,1,1,2,2,2,3,3,3,4,4,4,4,5,5,5]); /* samples shown */ \
# GP-Test    vector(#v,j,j--; z_xmax_exp(j)) == v

# GP-DEFINE  z_xmax_by_floor(k) = sum(j=0,k-1, conj(w6)^z_xmax_exp(j) * b^j);
# GP-Test  vector(200,j,j--; z_xmax_by_floor(j)) == \
# GP-Test  vector(200,j,j--; z_xmax(j))
#
#
# vector(35,k,k++; z_xmax_exp(k))     \\ floor(angle_F*j+1/2))
# not in OEIS: 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 7, 8, 8, 8, 9, 9, 9, 10, 10, 10, 11, 11, 11, 11
# not A082964 a(n) = m given by arctan(tan(n)) = n - m*Pi.
# GP-DEFINE  A082964(n) = round((n-atan(tan(n)))/Pi);
#
# atan(tan(n)) gives fractional part -pi/2 to +pi/2, so how many revolutions
# angle n makes around a circle, up to -pi/2, so factor 1/Pi
# 1/Pi \\ 0.318309886183790671537767 is close to F
#
# GP-DEFINE  A082964_by_floor(n) = floor(1/Pi*n+1/2);
# GP-Test  vector(10000,n,A082964(n)) == \
# GP-Test  vector(10000,n,A082964_by_floor(n))

# GP-Test  vector(1000,n,A082964(n)) != \
# GP-Test  vector(1000,j, floor(angle_F*j+1/2))

=pod

By symmetry the maximum extent is the same in 60deg, 120deg, etc directions,
suitably rotated.  The N in those cases has the digits 1,2,3,4,5,6 cycled
around for the rotation.  In PlanePath triangular X,Y coordinates direction
60deg means when sum X+3*Y is a maximum, etc.

=cut

# GP-DEFINE  w12_times_sqrt3 = 1+w6;   /* w12 * sqrt(3) */
# (x/2+y*sqrt3i/2) * conj(w6) == (x/4 + 3*y/4) + (-x/4 + y*1/4)*sqrt3i
# (x/2+y*sqrt3i/2) * conj(w12_times_sqrt3) == (x*3/4 + y*3/4) + (-x/4 + y*3/4)*sqrt3i

# GP-DEFINE  z_to_x(z) = 2*real(z);
# GP-DEFINE  z_to_y(z) = 2*imag(z);
# GP-Test  z_to_x(z_point(1)) == 2
# GP-Test  z_to_x(z_point(3)) == -1
# GP-Test  z_to_y(z_point(3)) == 1

# GP-DEFINE  N_s3max_by_points(k) = my(n); vecmax(real(z_points(k)/w6),&n); n-1;
# GP-Test  to_base7(N_s3max_by_points(3)) == 122
# GP-Test  to_base7(N_s3max_by_points(4)) == 1122

=pod

If the +1/2 in the floor is omitted then the effect is to find the maximum
point in direction +30deg.  In the PlanePath coordinates this means maximum
sum S = X+Y.

    N_smax_digit(j) = (-floor(F*j) mod 6) + 1
                    = 1,1,1,1,6,6,6,5,5,5,4,4,4,3,3, ...

                 k-1
    N_smax(k) = digits N_smax_digit(j)    low digit j=0
                 j=0
              = 0, 1, 8, 57, 400, 14806, 115648, ...     decimal
              = 0, 1, 11, 111, 1111, 61111, 661111, ...  base7
    and also N_smax() + 1

    z_smax_exp(j) = floor(F*j)
                  = 0,0,0,0,1,1,1,2,2,2,3,3,3,4,4,4,5,5,5,6, ...
    z_smax(k) = sum(j=0,k-1, conj(w6)^z_smax_exp(j) * b^j)
              = 0, 1, 7/2+1/2*sqrt3*i, 9+3*sqrt3*i, 19+12*sqrt3*i, ...
    and also z_smax() + w6^2

    smax(k) = 2*real(z_smax(k)) + imag(z_smax(k))*2/sqrt3
            = 0, 2, 8, 24, 62, 172, 470, 1190, 3202, 8740, ...
              coordinate sum X+Y max

In the base figure, points 1 and 2 have the same X+Y=2 and this remains so
in subsequent levels, so that for kE<gt>=1 N_smax(k) and N_smax(k)+1 are
equal maximums.

=cut

# GP-DEFINE  N_smax_digit(j) = (-floor(angle_F*j) % 6) + 1;
# GP-Test  my(v=[1,1,1,1,6,6,6,5,5,5,4,4,4,3,3]); /* samples shown */ \
# GP-Test    vector(#v,j,j--; N_smax_digit(j)) == v

# GP-DEFINE  N_smax(k) = fromdigits(Vecrev(vector(k,j,j--; N_smax_digit(j))),7);
# GP-Test  N_smax(0) == 0
# GP-Test  N_smax(1) == 1
# GP-Test  N_smax(6) == 115648
# GP-Test  to_base7(N_smax(51)) \
# GP-Test    == 444555566611122233344455566661112223334445556661111
# GP-Test  my(v=[0, 1, 8, 57, 400, 14806, 115648]); /* samples shown */ \
# GP-Test    vector(#v,j,j--; N_smax(j)) == v
# GP-Test  my(v=[0, 1, 11, 111, 1111, 61111, 661111]); /* samples shown */ \
# GP-Test    vector(#v,j,j--; to_base7(N_smax(j))) == v

# vector(25,k,k--; N_smax_digit(k))
# vector(8,k, N_smax(k))
# vector(8,k, to_base7(N_smax(k)))
# not in OEIS: 1,1,1,1,6,6,6,5,5,5,4,4,4,3,3,3,2,2,2,1,1,1,6,6,6  \\ digits
# not in OEIS: 1, 8, 57, 400, 14806, 115648                       \\ decimal
# not in OEIS: 1, 11, 111, 1111, 61111, 661111                    \\ base7
# vector(8,k, N_smax(k)+1)
# vector(8,k, to_base7(N_smax(k))+1)
# not in OEIS: 2, 9, 58, 401, 14807, 115649, 821543, 4939258      \\ decimal
# not in OEIS: 2, 12, 112, 1112, 61112, 661112, 6661112, 56661112 \\ base7

# GP-DEFINE  z_smax_exp(j) = floor(angle_F*j);
# GP-Test  my(v=[0,0,0,0,1,1,1,2,2,2,3,3,3,4,4,4,5,5,5,6]); /*samples shown*/ \
# GP-Test    vector(#v,j,j--; z_smax_exp(j)) == v

# GP-DEFINE  z_smax(k) = sum(j=0,k-1, conj(w6)^z_smax_exp(j) * b^j);
# GP-Test  my(v=[0, 1, 7/2+1/2*sqrt3i, 9+3*sqrt3i, 19+12*sqrt3i]); /*samples*/ \
# GP-Test    vector(#v,j,j--; z_smax(j)) == v
# GP-Test  vector(50,j,j--; real(  z_smax(j)       / w12_times_sqrt3 )) == \
# GP-Test  vector(50,j,j--; real( (z_smax(j)+w6^2) / w12_times_sqrt3 ))

# GP-DEFINE  smax(k) = my(z=z_smax(k)); z_to_x(z)+z_to_y(z);
# GP-Test  my(v=[0, 2, 8, 24, 62, 172, 470, 1190, 3202, 8740]); /*samples*/ \
# GP-Test    vector(#v,j,j--; smax(j)) == v

# vector(50,k,k++; z_smax_exp(k))   \\ floor(angle_F*j)
# not in OEIS: 4,4,4,5,5,5,6,6,6,7,7,7,7,8,8,8,9,9,9,10,10,10,11,11,11,12,12,12,13,13,13,14,14,14,14,15,15,15,16
# not A032615 = floor(n/Pi)
# 1/Pi   \\ = 0.318309886183790671537767 is close to F
# GP-DEFINE  A032615(n) = floor(1/Pi*n);
#
# is not A062300 which is same, almost, maybe, as A032615 after initial terms
# A062300 a(n) = floor cosec( pi/(n+1) )
# GP-DEFINE  A062300(n) = floor(1/sin(Pi/(n+1)));
# GP-Test  vector(10000,n,n+=4; A062300(n)) == \
# GP-Test  vector(10000,n,n+=4; A032615(n+1))
# GP-Test  vector(200,n,n+=4; A062300(n)) != \
# GP-Test  vector(200,n,n+=4; z_smax_exp(n+1))
# sin(x)~x when x small so floor(1/sin(Pi/(n+1))) ~ floor((n+1)/Pi)
# but with sin(x)<x maybe 1/sin(Pi/(n+1)) would be just above the next integer
# agree to 100000 terms

# vector(16,k,k++; z_smax(k))
# vector(8,k,k++; norm(z_smax(k)))
# vector(10,k,k++; 2*real(z_smax(k)))
# vector(10,k,k++; 2*imag(z_smax(k)))
# not in OEIS: 13, 108, 793, 5556, 41509, 288775, 1932703, 14322999 \\ norm
# not in OEIS: 7, 18, 38, 132, 343, 740, 2503, 6537, 14366, 47355   \\ 2*real
# not in OEIS: 1, 6, 24, 40, 127, 450, 699, 2203, 7980, 11705       \\ 2*imag
# vector(10,k,k++; smax(k))
# vector(10,k,k++; smax(k)/2)
# not in OEIS: 8, 24, 62, 172, 470, 1190, 3202, 8740, 22346, 59060 \\ 2*re+2*im
# not in OEIS: 4, 12, 31, 86, 235, 595, 1601, 4370, 11173, 29530   \\ re+im

# GP-DEFINE  N_smax_list_by_points(k) = {
# GP-DEFINE    my(v=real(z_points(k)/w12_times_sqrt3), z=vecmax(v));
# GP-DEFINE    apply(n->n-1, Vec(select(e->e==z,v,1)));
# GP-DEFINE  }
# GP-Test  N_smax_list_by_points(0) == [0]
# GP-Test  N_smax_list_by_points(1) == [1,2]
# GP-Test  N_smax_list_by_points(2) == [8,9]
# GP-Test  N_smax_list_by_points(3) == [57,58]
# GP-Test  N_smax(3) == 57

# tan(n)
# atan(tan(n))
# n-atan(tan(n))
# (n-atan(tan(n)))/Pi
# n - m*Pi




=pod

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::GosperIslands>,
L<Math::PlanePath::Flowsnake>,
L<Math::PlanePath::FlowsnakeCentres>,
L<Math::PlanePath::QuintetReplicate>,
L<Math::PlanePath::ComplexPlus>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
