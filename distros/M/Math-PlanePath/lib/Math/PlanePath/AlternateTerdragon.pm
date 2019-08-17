# Copyright 2018 Kevin Ryde

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


package Math::PlanePath::AlternateTerdragon;
use 5.004;
use strict;
use List::Util 'first';
use List::Util 'min'; # 'max'
*max = \&Math::PlanePath::_max;

use Math::PlanePath;
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest',
  'xy_is_even';
use Math::PlanePath::Base::Digits
  'digit_split_lowtohigh',
  'digit_join_lowtohigh',
  'round_up_pow';

use vars '$VERSION', '@ISA';
$VERSION = 127;
@ISA = ('Math::PlanePath');

use Math::PlanePath::TerdragonMidpoint;

# uncomment this to run the ### lines
# use Smart::Comments;


use constant n_start => 0;
use constant parameter_info_array =>
  [ { name      => 'arms',
      share_key => 'arms_6',
      display   => 'Arms',
      type      => 'integer',
      minimum   => 1,
      maximum   => 6,
      default   => 1,
      width     => 1,
      description => 'Arms',
    } ];

sub x_negative {
  my ($self) = @_;
  return ($self->{'arms'} >= 2);
}
{
  my @x_negative_at_n = (undef,  undef, 5, 5, 6, 7, 8);
  sub x_negative_at_n {
    my ($self) = @_;
    return $x_negative_at_n[$self->{'arms'}];
  }
}
{
  my @y_negative_at_n = (undef,  6, 12, 18, 11, 9, 10);
  sub y_negative_at_n {
    my ($self) = @_;
    return $y_negative_at_n[$self->{'arms'}];
  }
}
sub dx_minimum {
  my ($self) = @_;
  return ($self->{'arms'} == 1 ? -1 : -2);
}
use constant dx_maximum => 2;
use constant dy_minimum => -1;
use constant dy_maximum => 1;

sub sumxy_minimum {
  my ($self) = @_;
  # arm 0 and arm 1 are always above X+Y=0 opposite diagonal, which is +120 deg
  return ($self->{'arms'} <= 2 ? 0 : undef);
}
sub diffxy_minimum {
  my ($self) = @_;
  # arm 0 remains below the X-Y leading diagonal, being +60 deg
  return ($self->{'arms'} <= 1 ? 0 : undef);
}

sub _UNDOCUMENTED__dxdy_list {
  my ($self) = @_;
  return ($self->{'arms'} == 1
          ? Math::PlanePath::_UNDOCUMENTED__dxdy_list_three()
          : Math::PlanePath::_UNDOCUMENTED__dxdy_list_six());
}
{
  my @_UNDOCUMENTED__dxdy_list_at_n = (undef, 3, 7, 10, 7, 8, 5);
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

# arms=1 curve goes at 0,120,240 degrees
# arms=2 second +60 to 60,180,300 degrees
# so when arms==1 dir maximum is 240 degrees
sub dir_maximum_dxdy {
  my ($self) = @_;
  return ($self->{'arms'} == 1
          ? (-1,-1)    # 0,2,4 only           South-West
          : ( 1,-1));  # rotated to 1,3,5 too South-East
}

use constant turn_any_straight => 0; # never straight


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);
  $self->{'arms'} = max(1, min(6, $self->{'arms'} || 1));
  return $self;
}

my @dir6_to_dx = (2, 1,-1,-2, -1, 1);
my @dir6_to_dy = (0, 1, 1, 0, -1,-1);

sub n_to_xy {
  my ($self, $n) = @_;
  ### AlternateTerdragon n_to_xy(): $n

  if ($n < 0) { return; }
  if (is_infinite($n)) { return ($n, $n); }

  my $zero = ($n * 0);  # inherit bignum 0
  my $i;             # X
  my $j = $zero;             # +60
  my $k = $zero;             # +120
  my $pow = $zero + 1;  # inherit bignum 1

  # initial rotation from arm number
  my $rot;
  {
    my $int = int($n);
    $i = $n - $int;   # frac, inherit possible BigFloat
    $n = $int;        # BigFloat int() gives BigInt, use that
    $rot = _divrem_mutate ($n, $self->{'arms'});
  }

  # even si = pow, sj = 0, sk = 0
  # odd  si = pow, sj = 0, sk = -pow

  my $even = 1;
  my @n = digit_split_lowtohigh($n,3);
  while (@n) {
    my $digit = shift @n;
    ### at: "$i, $j, $k  even digit $digit"
    if ($digit == 1) {
      ($i,$j,$k) = ($pow-$j, -$k, $i);  # rotate +120 and add
    } elsif ($digit == 2) {
      $j += $pow;  # add rotated +60
    }

    last unless @n;
    $digit = shift @n;
    if ($digit == 1) {
      ($i,$j,$k) = ($pow+$k, $pow-$i, -$j);  # rotate -120 and add
    } elsif ($digit == 2) {
      $i += $pow;   # add * b
      $k -= $pow;
    }
    $pow *= 3;
  }

  ### final: "$i, $j, $k"
  ### is: (2*$i + $j - $k).", ".($j+$k)

  ### $rot
  if ($rot >= 3) {
    ($i,$j,$k) = (-$i,-$j,-$k);
    $rot -= 3;
  }
  if ($rot == 1)    { ($i,$j,$k) = (-$k,$i,$j); } # rotate +60
  elsif ($rot == 2) { ($i,$j,$k) = (-$j,-$k, $i); } # rotate +128

  return (2*$i + $j - $k, $j+$k);
}

# all even points when arms==6
sub xy_is_visited {
  my ($self, $x, $y) = @_;
  if ($self->{'arms'} == 6) {
    return xy_is_even($self,$x,$y);
  } else {
    return defined($self->xy_to_n($x,$y));
  }
}

sub xy_to_n {
  return scalar((shift->xy_to_n_list(@_))[0]);
}
sub xy_to_n_list {
  my ($self, $x,$y) = @_;
  ### AlternateTerdragon xy_to_n_list(): "$x, $y"

  $x = round_nearest($x);
  $y = round_nearest($y);
  {
    # nothing at an odd point, and trap overflows in $x+$y dividing out b
    my $sum = abs($x) + abs($y);
    if (is_infinite($sum)) { return $sum; }  # infinity
    if ($sum % 2) { return; }
  }

  if ($x==0 && $y==0) {
    return 0 .. $self->{'arms'}-1;
  }

  my $arms_count = $self->arms_count;
  my $zero = ($x * 0 * $y); # inherit bignum 0

  my @n_list;
  foreach my $d (0,1,2) {
    my ($ndigits,$arm) = _xy_d_to_ndigits_and_arm($x,$y,$d);
    next if $arm >= $arms_count;
    if ($arm & 1) {
      ### flip ...
      @$ndigits = map {2-$_} @$ndigits;
    }
    push @n_list,
      digit_join_lowtohigh($ndigits, 3, $zero) * $arms_count + $arm;
  }

  ### unsorted n_list: @n_list
  return sort {$a<=>$b} @n_list;
}

my @digit_to_x = ([0,2,1],  [0,-1,-2],  [0,-1, 1]);
my @digit_to_y = ([0,0,1],  [0, 1, 0],  [0,-1,-1]);

# $d = 0,1,2 for segment leaving $x,$y at direction $d*120 degrees.
# For odd arms the digits are 0<->2 reversals.
sub _xy_d_to_ndigits_and_arm {
  my ($x,$y, $d) = @_;
  ### _xy_d_to_ndigits_and_arm(): "$x,$y d=$d"
  my @ndigits;
  my $arm;
  for (;;) {
    ### at: "$x,$y d=$d"
    if ($x==0 && $y==0) { $arm = 2*$d; last; }
    if ($d==2 && $x==1  && $y==1) { $arm = 1; last; }
    if ($d==0 && $x==-2 && $y==0) { $arm = 3; last; }
    if ($d==1 && $x==1  && $y==-1) { $arm = 5; last; }
    my $a = $x % 3;          # z mod b = -x mod 3
    if ($a) { $a = 3-$a; }
    push @ndigits, $a;

    if ($a==1) { $d = ($d-1) % 3; }
    ### a: $a
    ### new d: $d

    $x -= $digit_to_x[$d]->[$a];
    $y -= $digit_to_y[$d]->[$a];
    ### subtract: "$digit_to_x[$d]->[$a],$digit_to_y[$d]->[$a] to $x,$y"

    ### assert: ($x+$y) % 2 == 0
    ### assert: $x % 3 == 0
    ### assert: ($y-$x/3) % 2 == 0
    ### assert: (3*$y-$x) % 6 == 0

    ($x,$y) = (($x+$y)/2,    # divide b = w6+1
               ($y-$x/3)/2);

    $y = -$y;
    $d = (-$d) % 3;
  }
  if (scalar(@ndigits) & 1) { $arm = (6-$arm) % 6; }
  ### $arm
  ### @ndigits
  return (\@ndigits, $arm);
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### AlternateTerdragon rect_to_n_range(): "$x1,$y1  $x2,$y2"
  my $xmax = int(max(abs($x1),abs($x2)));
  my $ymax = int(max(abs($y1),abs($y2)));
  return (0,
          ($xmax*$xmax + 3*$ymax*$ymax + 1)
          * 2
          * $self->{'arms'});
}

my @digit_to_nextturn = (2,-2);
sub n_to_dxdy {
  my ($self, $n) = @_;
  ### AlternateTerdragon n_to_dxdy(): $n

  if ($n < 0) {
    return;  # first direction at N=0
  }
  if (is_infinite($n)) {
    return ($n,$n);
  }

  my $int = int($n);  # integer part
  $n -= $int;         # fraction part

  # initial direction from arm
  my $dir6 = _divrem_mutate ($int, $self->{'arms'});

  my @ndigits = digit_split_lowtohigh($int,3);
  foreach my $i (0 .. $#ndigits) {
    if ($ndigits[$i] == 1) {
      $dir6 += 2*($i&1 ? -1 : 1);   # count 1s for total turn
    }
  }
  $dir6 %= 6;
  my $dx = $dir6_to_dx[$dir6];
  my $dy = $dir6_to_dy[$dir6];

  if ($n) {
    ### fraction part: $n

    # find lowest non-2 digit, or zero if all 2s or no digits at all
    my $above = scalar(@ndigits);
    foreach my $i (0 .. $#ndigits) {
      if ($ndigits[$i] != 2) {
        ### lowest non-2: "at i=$i digit=$ndigits[$i]"
        $above = $ndigits[$i] ^ $i;
        last;
      }
    }

    $dir6 = ($dir6 + $digit_to_nextturn[$above & 1]) % 6;
    ### $above
    ### $dir6

    $dx += $n*($dir6_to_dx[$dir6] - $dx);
    $dy += $n*($dir6_to_dy[$dir6] - $dy);
  }
  return ($dx, $dy);
}


#-----------------------------------------------------------------------------
# eg. arms=5 0 .. 5*3^k    step by 5s
#            1 .. 5*3^k+1  step by 5s
#            4 .. 5*3^k+4  step by 5s
#
sub level_to_n_range {
  my ($self, $level) = @_;
  return (0,  (3**$level + 1) * $self->{'arms'} - 1);
}
sub n_to_level {
  my ($self, $n) = @_;
  if ($n < 0) { return undef; }
  if (is_infinite($n)) { return $n; }
  $n = round_nearest($n);
  _divrem_mutate ($n, $self->{'arms'});
  my ($pow, $exp) = round_up_pow ($n, 3);
  return $exp;
}

1;
__END__

=for stopwords eg Ryde Math-PlanePath terdragon Ns dX ie OEIS

=head1 NAME

Math::PlanePath::AlternateTerdragon -- alternate terdragon curve

=head1 SYNOPSIS

 use Math::PlanePath::AlternateTerdragon;
 my $path = Math::PlanePath::AlternateTerdragon->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

X<Davis>X<Knuth, Donald>This is the alternate terdragon curve by Davis and
Knuth,

=over

Chandler Davis and Donald Knuth, "Number Representations and Dragon Curves
-- I", Journal Recreational Mathematics, volume 3, number 2 (April 1970),
pages 66-81 and "Number Representations and Dragon Curves -- II", volume 3,
number 3 (July 1970), pages 133-149.

Reprinted with addendum in Knuth "Selected Papers on Fun and Games", 2010,
pages 571--614.  L<http://www-cs-faculty.stanford.edu/~uno/fg.html>

=back

Points are a triangular grid using every second integer X,Y as per
L<Math::PlanePath/Triangular Lattice>, beginning

=cut

# generated by code in devel/alternate-terdragon.pl

=pod

                                 \   /       \   /
    Y=2                          14,17 --- 15,24,33 --
                                     \       /   \
                                       \   /       \   /
    Y=1          2 ------- 3,12 ---- 10,13,34 -- 32,35,38
                   \       /   \       /   \       /   \
                     \   /       \   /       \   /
    Y=0    0 -------- 1,4 ----- 5,8,11 ----- 9,36 ----
                                 /   \
                               /       \
    Y=-1                     6 --------- 7

           ^     ^     ^     ^     ^     ^     ^     ^
          X=0    1     2     3     4     5     6     7

A segment 0 to 1 is unfolded to

       2-----3
        \
         \
    0-----1

Then 0 to 3 is unfolded likewise, but the folds are the opposite way.  Where
1-2 went on the left, for 3-6 goes to the right.

       2-----3                   2-----3
        \   /                     \   /
         \ /                       \ /
    0----1,4----5             0----1,4---5,8----9
               /                         / \
              /                         /   \
             6                         6-----7

Successive unfolds go alternate ways.  Taking two unfold at a time is
segment replacement by the 0 to 9 figure (rotated as necessary).  The curve
never crosses itself.  Vertices touch at triangular corners.  Points can be
visited 1, 2 or 3 times.

The two triangles have segment 4-5 between.  In general points to a level
N=3^k have a single segment between two blobs, for example N=0 to N=3^6=729
below.  But as the curve continues it comes back to put further segments
there (and a single segment between bigger blobs).

=cut

# the following generated by
#   math-image --path=AlternateTerdragon --expression='i<=729?i:0' --text --size=132x40

=pod

                 * *
                * * * *
                 * * * *
              * * * * *   * *
             * * * * * * * * * *
              * * * * * * * * * *
             * * * * * * * * * *
              * * * * * * * * * * *
                 * * * * * * * * * *
        * *   * * * * * * * * * * *         * *
       * * * * * * * * * * * * *           * * * *
        * * * * * * * * * * * * *           * * * *
     * * * * * * * * * * * * * *   * *   * * * * *   * *
    O * * * * * * * * * * * * * * * * * * * * * * * * * * E
       * *   * * * * *   * *   * * * * * * * * * * * * * *
            * * * *           * * * * * * * * * * * * *
             * * * *           * * * * * * * * * * * * *
                * *         * * * * * * * * * * *   * *
                           * * * * * * * * * *
                            * * * * * * * * * * *
                               * * * * * * * * * *
                              * * * * * * * * * *
                               * * * * * * * * * *
                                  * *   * * * * *
                                       * * * *
                                        * * * *
                                           * *

The top boundary extent is at an angle +60 degrees and the bottom at -30
degrees,

       / 60 deg
      /
     /
    O-------------------
     --__
         --__ 30 deg

An even expansion level is within a rectangle with endpoint at
X=2*3^(k/2),Y=0.

=head2 Arms

The curve fills a sixth of the plane and six copies rotated by 60, 120, 180,
240 and 300 degrees mesh together perfectly.  The C<arms> parameter can
choose 1 to 6 such curve arms successively advancing.

For example C<arms =E<gt> 6> begins as follows.  N=0,6,12,18,etc is the
first arm (the same shape as the plain curve above), then N=1,7,13,19 the
second, N=2,8,14,20 the third, etc.

=cut

# generated by code in devel/alternate-terdragon.pl

=pod

                  \         /             \           /
                   \       /               \         /
                --- 7,8,26 ----------------- 1,12,19 ---
                  /        \               /         \
     \           /          \             /           \          /
      \         /            \           /             \        /
    --- 3,14,21 ------------- 0,1,2,3,4,5 -------------- 6,11,24 ---
      /         \            /           \             /        \
     /           \          /             \           /          \
                  \        /               \         /
               ---- 9,10,28 ---------------- 5,16,23 ---
                  /        \               /         \
                 /          \             /           \

With six arms every X,Y point is visited three times, except the origin 0,0
where all six begin.  Every edge between points is traversed once.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::AlternateTerdragon-E<gt>new ()>

=item C<$path = Math::PlanePath::AlternateTerdragon-E<gt>new (arms =E<gt> 6)>

Create and return a new path object.

The optional C<arms> parameter can make 1 to 6 copies of the curve, each arm
successively advancing.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

Fractional positions give an X,Y position along a straight line between the
integer positions.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return the point number for coordinates C<$x,$y>.  If there's nothing at
C<$x,$y> then return C<undef>.

The curve can visit an C<$x,$y> up to three times.  C<xy_to_n()> returns the
smallest of the these N values.

=item C<@n_list = $path-E<gt>xy_to_n_list ($x,$y)>

Return a list of N point numbers for coordinates C<$x,$y>.

The origin 0,0 has C<arms_count()> many N since it's the starting point for
each arm.  Other points have up to 3 Ns for a given C<$x,$y>.  If arms=6
then every even C<$x,$y> except the origin has exactly 3 Ns.

=back

=head2 Descriptive Methods

=over

=item C<$n = $path-E<gt>n_start()>

Return 0, the first N in the path.

=item C<$dx = $path-E<gt>dx_minimum()>

=item C<$dx = $path-E<gt>dx_maximum()>

=item C<$dy = $path-E<gt>dy_minimum()>

=item C<$dy = $path-E<gt>dy_maximum()>

The dX,dY values on the first arm take three possible combinations, being
120 degree angles.

    dX,dY   for arms=1
    -----
     2, 0        dX minimum = -1, maximum = +2
    -1, 1        dY minimum = -1, maximum = +1
     1,-1

For 2 or more arms the second arm is rotated by 60 degrees so giving the
following additional combinations, for a total six.  This changes the dX
minimum.

    dX,dY   for arms=2 or more
    -----
    -2, 0        dX minimum = -2, maximum = +2
     1, 1        dY minimum = -1, maximum = +1
    -1,-1

=item C<$sum = $path-E<gt>sumxy_minimum()>

=item C<$sum = $path-E<gt>sumxy_maximum()>

Return the minimum or maximum values taken by coordinate sum X+Y reached by
integer N values in the path.  If there's no minimum or maximum then return
C<undef>.

S=X+Y is an anti-diagonal.  The first arm is entirely above a line 135deg --
-45deg, per the +60deg to -30deg extents shown above.  Likewise the second
arm which is to 60+60=120deg.  They have C<sumxy_minimum = 0>.  More arms
and all C<sumxy_maximum> are unbounded so C<undef>.

=item C<$diffxy = $path-E<gt>diffxy_minimum()>

=item C<$diffxy = $path-E<gt>diffxy_maximum()>

Return the minimum or maximum values taken by coordinate difference X-Y
reached by integer N values in the path.  If there's no minimum or maximum
then return C<undef>.

D=X-Y is a leading diagonal.  The first arm is entirely right of a line
45deg -- -135deg, per the +60deg to -30deg extents shown above, so it has
C<diffxy_minimum = 0>.  More arms and all C<diffxy_maximum> are unbounded so
C<undef>.

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<(0, 3**$level)>, or for multiple arms return C<(0, $arms *
3**$level + ($arms-1))>.

There are 3^level segments in a curve level, so 3^level+1 points numbered
from 0.  For multiple arms there are arms*(3^level+1) points, numbered from
0 so n_hi = arms*(3^level+1)-1.

=back

=head1 FORMULAS

=cut

# Various formulas for coordinates, boundary, area and more can be found in
# the author's mathematical write-up
#
# =over
#
# L<http://user42.tuxfamily.org/terdragon/index.html>
#
# =back
#
# =head2 N to X,Y
#
# There's no reversals or reflections in the curve so C<n_to_xy()> can take
# the digits of N either low to high or high to low and apply what is
# effectively powers of the N=3 position.  The current code goes low to high
# using i,j,k coordinates as described in L<Math::PlanePath/Triangular
# Calculations>.
#
#     si = 1    # position of endpoint N=3^level
#     sj = 0    #    where level=number of digits processed
#     sk = 0
#
#     i = 0     # position of N for digits so far processed
#     j = 0
#     k = 0
#
#     loop base 3 digits of N low to high
#        if digit == 0
#           i,j,k no change
#        if digit == 1
#           (i,j,k) = (si-j, sj-k, sk+i)  # rotate +120, add si,sj,sk
#        if digit == 2
#           i -= sk      # add (si,sj,sk) rotated +60
#           j += si
#           k += sj
#
#        (si,sj,sk) = (si - sk,      # add rotated +60
#                      sj + si,
#                      sk + sj)
#
# The digit handling is a combination of rotate and offset,
#
#     digit==1                   digit 2
#     rotate and offset          offset at si,sj,sk rotated
#
#          ^                          2------>
#           \
#            \                          \
#     *---  --1                  *--   --*
#
# The calculation can also be thought of in term of w=1/2+I*sqrt(3)/2, a
# complex number sixth root of unity.  i is the real part, j in the w
# direction (60 degrees), and k in the w^2 direction (120 degrees).  si,sj,sk
# increase as if multiplied by w+1.

=pod

=head2 Turn

At each point N the curve always turns 120 degrees either to the left or
right, it never goes straight ahead.  If N is written in ternary then the
lowest non-zero digit at its position gives the turn.  Positions are counted
from 0 for the least significant digit and up from there.

   turn          ternary lowest non-zero digit
   -----     ---------------------------------------
   left      1 at even position or 2 at odd position
   right     2 at even position or 1 at odd position

The flip of turn at odd positions is the "alternating" in the curve.

   next turn         ternary lowest non-2 digit
   ---------    ---------------------------------------
     left       0 at even position or 1 at odd position
     right      1 at even position or 0 at odd position

=head2 Total Turn

The direction at N, ie. the total cumulative turn, is given by the 1 digits
of N written in ternary.

    direction = 120deg * sum / +1  if digit=1 at even position
                             \ -1  if digit=1 at odd position

This is used mod 3 for C<n_to_dxdy()>.

=head2 X,Y to N

The current code is roughly the same as C<TerdragonCurve> C<xy_to_n()>, but
with a conjugate (negate Y, reverse direction d) after each digit low to
high.

=head2 X,Y Visited

When arms=6 all "even" points of the plane are visited.  As per the
triangular representation of X,Y this means

    X+Y mod 2 == 0        "even" points

=head1 OEIS

Sequences in Sloane's Online Encyclopedia of Integer Sequences related to
the alternate terdragon include,

=over

L<http://oeis.org/A156595> (etc)

=back

    A156595   next turn 0=left, 1=right (morphism)
    A189715   N positions of left turns
    A189716   N positions of right turns
    A189717   count right turns so far

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::TerdragonCurve>

L<Math::PlanePath::DragonCurve>,
L<Math::PlanePath::AlternatePaper>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2018 Kevin Ryde

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
