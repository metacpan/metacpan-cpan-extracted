# Copyright 2019, 2020 Kevin Ryde

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


package Math::PlanePath::PeanoDiagonals;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 129;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath;
*max = \&Math::PlanePath::_max;

use Math::PlanePath::PeanoCurve;
*_n_to_xykk = \&Math::PlanePath::PeanoCurve::_n_to_xykk;
*_xykk_to_n = \&Math::PlanePath::PeanoCurve::_xykk_to_n;

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_up_pow',
  'round_down_pow',
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';


# uncomment this to run the ### lines
# use Smart::Comments;


use constant n_start => 0;
use constant class_x_negative => 0;
use constant class_y_negative => 0;
use constant turn_any_straight => 0; # never straight

use constant dx_minimum => -1;
use constant dx_maximum => 1;
use constant dy_minimum => -1;
use constant dy_maximum => 1;

use constant parameter_info_array =>
  [ { name      => 'radix',
      share_key => 'radix_3',
      display   => 'Radix',
      type      => 'integer',
      minimum   => 2,
      default   => 3,
      width     => 3,
    } ];

# odd radix is unit steps diagonally,
# even radix unlimited
sub _UNDOCUMENTED__dxdy_list {
  my ($self) = @_;
  return ($self->{'radix'} % 2
          ? (1,1, -1,1, -1,-1, 1,-1)
          : ());   # even, unlimited
}

sub new {
  my $self = shift->SUPER::new(@_);

  if (! $self->{'radix'} || $self->{'radix'} < 2) {
    $self->{'radix'} = 3;
  }
  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### PeanoDiagonals n_to_xy(): "$n"
  if ($n < 0) {            # negative
    return;
  }
  if (is_infinite($n)) {
    return ($n,$n);
  }

  my $frac;
  {
    my $int = int($n);
    $frac = $n - $int;  # inherit possible BigFloat
    $n = $int;
  }

  my ($x,$y, $xk,$yk) = _n_to_xykk($self,$n);
  ### xykk: "$x,$y  $xk,$yk"

  return ($x + ($xk&1 ? 1-$frac : $frac),
          $y + ($yk&1 ? 1-$frac : $frac));
}

sub xy_to_n {
  return scalar((shift->xy_to_n_list(@_))[0]);
}
sub xy_to_n_list {
  my ($self, $x, $y) = @_;
  ### PeanoDiagonals xy_to_n(): "$x, $y"

  # For odd radix, if X is even then segments are NE or SW, so offset 0,0 or
  # 1,1 to go to "middle" points.  Conversely if X is odd then segments are
  # NW or SE so offset 0,1 or 1,0.
  #
  # ENHANCE-ME: For odd radix, the two offsets are exactly the two visits.
  # Should be able to pay attention to the low 0s or 2s and so have the
  # digits of both N in one look.
  #
  # ENHANCE-ME: Is the offset rule for even radix found as easily?

  $x = round_nearest ($x);
  $y = round_nearest ($y);

  if ($x < 0 || $y < 0) { return; }
  if (is_infinite($x)) { return $x; }
  if (is_infinite($y)) { return $y; }

  return
    sort {$a<=>$b}
    map {_xykk_to_n($self, $x,$y, @$_)}
    ($self->{'radix'}&1
     ? ($x&1 ? ([0,1],[1,0]) : ([0,0],[1,1]))
     : ([0,0],[1,1], [0,1],[1,0]));
}


#------------------------------------------------------------------------------
# not exact
# block 0 .. 3^k-1 contains all 

sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);
  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;
  ### rect_to_n_range(): "$x1,$y1 to $x2,$y2"

  if ($x2 < 0 || $y2 < 0) {
    return (1, 0);
  }

  my $radix = $self->{'radix'};

  my ($power, $level) = round_down_pow (max($x2,$y2)*$radix, $radix);
  if (is_infinite($level)) {
    return (0, $level);
  }
  return (0, $power*$power - 1);
}

#------------------------------------------------------------------------------
# levels

sub level_to_n_range {
  my ($self, $level) = @_;
  return (0,  $self->{'radix'}**(2*$level));
}
sub n_to_level {
  my ($self, $n) = @_;
  if ($n < 0) { return undef; }
  $n = round_nearest($n);
  my ($pow, $exp) = round_up_pow ($n, $self->{'radix'}*$self->{'radix'});
  return $exp;
}

#------------------------------------------------------------------------------

# num low ternary 0s, and whether odd or even above there which is parity of
# how many 1-digits
#
sub _UNDOCUMENTED__n_to_turn_LSR {
  my ($self, $n) = @_;
  if ($n < 1 || is_infinite($n)) { return undef; }
  my $radix = $self->{'radix'};
  if ($radix & 1) {
    my $turn = 1;
    until ($n % $radix) {              # parity of low 0s
      $turn = -$turn;
      $n /= $radix;
    }
    return ($n % 2 ? -$turn : $turn);  # and flip again if odd
  }
  return $self->SUPER::_UNDOCUMENTED__n_to_turn_LSR($n);
}

#------------------------------------------------------------------------------

1;
__END__

=for stopwords Giuseppe Peano Peano's eg Sur Une Courbe Qui Remplit Toute Aire Mathematische Annalen Ryde OEIS ZOrderCurve ie Math-PlanePath versa Online Radix radix HilbertCurve PeanoCurve DOI

=head1 NAME

Math::PlanePath::PeanoDiagonals -- 3x3 self-similar quadrant traversal across squares

=head1 SYNOPSIS

 use Math::PlanePath::PeanoDiagonals;
 my $path = Math::PlanePath::PeanoDiagonals->new;
 my ($x, $y) = $path->n_to_xy (123);

 # or another radix digits ...
 my $path5 = Math::PlanePath::PeanoDiagonals->new (radix => 5);

=head1 DESCRIPTION

This path is the Peano curve with segments going diagonally across unit
squares.

=over

Giuseppe Peano, "Sur Une Courbe, Qui Remplit Toute Une Aire Plane",
Mathematische Annalen, volume 36, number 1, 1890, pages 157-160.
DOI 10.1007/BF01199438.
L<https://link.springer.com/article/10.1007/BF01199438>,
L<https://eudml.org/doc/157489>

=back

Points N are at each corner of the squares, so even locations (X+Y even),

=cut

# generated by:
# math-image --path=PeanoDiagonals --all --output=numbers --size=45x10

=pod

      9 |    61,425      63,423      65,421      79,407      81,405
      8 | 60       58,62       64,68       66,78       76,80
      7 |    55,59       57,69       67,71       73,77       75,87
      6 | 54       52,56       38,70       36,72       34,74
      5 |    49,53       39,51       37,41       31,35       33,129
      4 | 48       46,50       40,44       30,42       28,32
      3 |     7,47        9,45       11,43       25,29       27,135
      2 |  6        4,8        10,14       12,24       22,26
      1 |     1,5         3,15       13,17       19,23       21,141
    Y=0 |  0         2          16          18          20
        +----------------------------------------------------------
         X=0   1     2     3     4     5     6     7     8     9

Moore (figure 3) draws this form, though here is transposed so first unit
squares go East.

=over

E. H. Moore, "On Certain Crinkly Curves", Transactions of the American
Mathematical Society, volume 1, number 1, 1900, pages 72-90.

L<http://www.ams.org/journals/tran/1900-001-01/S0002-9947-1900-1500526-4/>,
L<http://www.ams.org/journals/tran/1900-001-04/S0002-9947-1900-1500428-3/>

=back

=cut

# Eliakim Hastings

=pod

Segments between the initial points can be illustrated,

      |    \              \
      +--- 47,7 ----+--- 45,9 --
      |    ^ | \    |   ^  | \
      |  /   |  \   |  /   |  v
      | /    |   v  | /    |  ...
      6 -----+---- 4,8 ----+--
      | ^    |    / | ^    |
      |   \  |   /  |   \  |
      |    \ | v    |    \ |
      +-----5,1 ----+---- 3,15
      |   ^  | \    |   ^  |
      |  /   |  \   |  /   |
      | /    |   v  | /    |
    N=0------+------2------+--

Segment N=0 to N=1 goes from the origin X=0,Y=0 up to X=1,Y=1, then N=2 is
down again to X=2,Y=0, and so on.  The plain PeanoCurve is the middle of
each square, so points N + 1/2 here (and reckoning the first such midpoint
as the origin).

The rule for block reversals is described with PeanoCurve.  N is split to an
X and Y digit alternately.  If the sum of Y digits above is odd then the X
digit is reversed, and vice versa X odd is Y reversed.

A plain diagonal is North-East per N=0 to 1.  Diagonals are mirrored
according to the final sum of all digits.  If sum of Y digits is odd then
mirror horizontally.  If sum of X digits is odd then mirror vertically.
Such mirroring is X+1 and/or Y+1 as compared to the plain PeanoCurve.

An integer N is at the start of the segment with its final reversal.
Fractional N follows the diagonal across its unit square.

As noted above all locations are even (X+Y even).  Those on the axes are
visited once and all others twice.

=cut

# Peano's conception for a space-filling curve is ternary digits below the
# radix point to X and Y ...  of a fractional f which fills a unit square going from f=0
# at X=0,Y=0 up to f=1 at X=1,Y=1.  The integer form here does this with
# digits above the ternary point.

=pod

=head2 Diamond Shape

Some authors take this diagonals form and raw it rotated -45 degrees so that
the segments are X,Y aligned, and the pattern fills a wedge shape between
diagonals X=Y and X=-Y (for XE<gt>=0).

         6----7,47
         |     |
         |     |
    0---1,5---4,8---9,45
         |     |     |
         |     |    ...
         2----3,15

In terms of the coordinates here, this is (X+Y)/2, (Y-X)/2.

=for GP-Test  ('x+I*'y)/(1+I) == ('x+'y)/2 + ('y-'x)/2 * I

=head2 Even Radix

In an even radix, the mirror rule for diagonals across unit squares is
applied the same way.  But in this case the end of one segment does not
always coincide with the start of the next.

=cut

# compare
# math-image --path=PeanoDiagonals,radix=4 --all --output=numbers --size=30x9

=pod

      +---15,125----+---13,127-- 16 -----+----18,98-
      |   /  | ^    |   /  | ^    | \    |   ^  | \
      |  /   |  \   |  /   |  \   |  \   |  /   |  \
      | v    |   \  | v    |   \  |   v  | /    |   v
      +----- 9 --- 14 --- 11 --- 12 --- 17 -----+--  ...
      |    ^ | \    |   ^  | \    |
      |  /   |  \   |  /   |  \   |
      | /    |   v  | /    |    v |
      8 ---- 7 --- 10 ---- 5 -----+---
      |   /  | ^    |   /  | ^    |
      |  /   |  \   |  /   |  \   |         radix => 4
      | v    |   \  | v    |   \  |
      +----- 1 ---- 6 ---- 3 ---- 4 --
      |   ^  | \    |   ^  | \    |
      |  /   |  \   |  /   |  \   |
      | /    |   v  | /    |   v  |
    N=0------+----- 2 -----+------+---

The first row N=0 to N=3 goes left to right.  The next row N=4 to N=7 is a
horizontal mirror image to go right to left.  N = 3.99.. < 4 follows its
diagonal across its unit square, so approaches X=3.99,Y=0.  There is then a
discontinuity up to N=4 at X=4,Y=1.

Block N=0 to N=15 repeats starting N=16, with vertical mirror image.  There
is a bigger discontinuity between N=15 to N=16 (like there is in even radix
PeanoCurve).

Some double-visited points occur, such as N=15 and N=125 both at X=1,Y=4.
This is when the 4x16 block N=0 to 64 is copied above, mirrored
horizontally.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for the behaviour common to all path
classes.

=over 4

=item C<$path = Math::PlanePath::PeanoDiagonals-E<gt>new ()>

=item C<$path = Math::PlanePath::PeanoDiagonals-E<gt>new (radix =E<gt> $r)>

Create and return a new path object.

The optional C<radix> parameter gives the base for digit splitting.  The
default is ternary, C<radix =E<gt> 3>.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

Fractional C<$n> gives an X,Y position along the diagonals across unit
squares.

=item C<($n_lo, $n_hi) = $path-E<gt>rect_to_n_range ($x1,$y1, $x2,$y2)>

Return a range of N values which covers the rectangle with corners at
C<$x1>,C<$y1> and C<$x2>,C<$y2>.  If the X,Y values are not integers then
the curve is treated as unit squares centred on each integer point and
squares which are partly covered by the given rectangle are included.

In the current implementation, the returned range is an over-estimate, so
that C<$n_lo> might be smaller than the smallest actually in the rectangle,
and C<$n_hi> bigger than the actual biggest.

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<(0, $radix**(2*$level) - 1)>.

=back

=head1 FORMULAS

=head2 N to Turn

The curve turns left or right 90 degrees at each point N E<gt>= 1.  The turn
is 90 degrees

    turn(N) = (-1)^(N + number of low ternary 0s of N)
            = -1,1,1,1,-1,-1,-1,1,-1,1,-1,-1,-1,1,1,1,-1,1
    by 90 degrees (+1 left, -1 right)

=cut

# checking in xt/PeanoDiagonals-seq.t too.
#
# GP-DEFINE  turn(n) = (-1)^(n + valuation(n,3));
# GP-Test  vector(18,n, turn(n)) == \
# GP-Test    [-1,1, 1, 1,-1, -1, -1,1,-1,1,-1, -1, -1,1,1,1,-1,1]

# not in OEIS: -1,1,1,1,-1,-1,-1,1,-1,1,-1,-1,-1,1,1,1,-1,1
# not in OEIS: 1,-1,-1,-1,1,1,1,-1,1,-1,1,1,1,-1,-1,-1,1,-1  \\ negated
# not in OEIS: 0,1,1,1,0,0,0,1,0,1,0,0,0,1,1,1,0,1,0,1,1,1,0,0,0,1,1,1,0,0  \\  ones
# not in OEIS: 1,0,0,0,1,1,1,0,1,0,1,1,1,0,0,0,1,0  \\ zeros

# vector(25,n, (-1)^valuation(n,3))
# not in OEIS: 1,1,-1,1,1,-1,1,1,1,1,1,-1,1,1,-1,1,1,1,1,1,-1,1,1,-1,1,1,-1,1
# vector(100,n, valuation(n,3)%2)
# A182581 num ternary low 0s mod 2

=pod

The power of -1 means left or right flip for each low ternary 0 of N, and
flip again if N is odd.  Odd N is an odd number of ternary 1 digits.

This formula follows from the turns in a new low base-9 digit.  For a
segment crossing a given unit square, the expanded segments have the same
start and end directions, so existing turns, now 9*N, are unchanged.  Then
9*N+r goes as r in the base figure, but flipped LE<lt>-E<gt>R when N odd
since blocks are mirrored alternately.

    turn(9N)   = turn(N)
    turn(9N+r) = turn(r)*(-1)^N         for  1 <= r <= 8

=cut

# GP-Test  vector(900,n, turn(9*n)) == \
# GP-Test  vector(900,n, turn(n))
# GP-Test  matrix(90,8,n,r, turn(9*n+r)) == \
# GP-Test  matrix(90,8,n,r, turn(r)*(-1)^n)

=pod

Or in terms of base 3, a single new low ternary digit is a transpose of
what's above, and the base figure turns r=1,2 are LE<lt>-E<gt>R when N above
is odd.

    turn(3N)   = - turn(N)
    turn(3N+r) = turn(r)*(-1)^N         for r = 1 or 2

=cut

# GP-Test  vector(900,n, turn(3*n)) == \
# GP-Test  vector(900,n, - turn(n))
# GP-Test  matrix(900,2,n,r, turn(3*n+r)) == \
# GP-Test  matrix(900,2,n,r, turn(r)*(-1)^n)

# GP-Test  vector(900,n, turn(3*n)) == \
# GP-Test  vector(900,n, -turn(n))
# GP-Test  vector(900,n, turn(3*n+1)) == \
# GP-Test  vector(900,n, -(-1)^n)
# GP-Test  vector(900,n, turn(3*n+2)) == \
# GP-Test  vector(900,n, (-1)^n)

=pod

Similarly in any odd radix.

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::PeanoCurve>,
L<Math::PlanePath::HilbertSides>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2019, 2020 Kevin Ryde

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
