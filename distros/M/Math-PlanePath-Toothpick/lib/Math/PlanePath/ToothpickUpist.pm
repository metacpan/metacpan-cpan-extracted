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


#
# A151567 four copies of leftist toothpicks
#   becomes 2*left(n)+2*left(n+1)-4n-1  undoubling diagonals
#
# A151565 ,1,1,2,2,2,2, 4, 4, 2, 2,4,4,4,4,8,8,2,2,4,4,4,4,8,8,4,4,8,8,8,8,16,
# A151566 ,0,1,2,4,6,8,10,14,18,20,22,26,30,34,38,46,54,56,58,62,66,70,74,82,90

# A175099,A160018 leftist closed rectangles

package Math::PlanePath::ToothpickUpist;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 18;
use Math::PlanePath;
@ISA = ('Math::PlanePath');


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


use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits 119  # v.119 for round_up_pow()
  'round_up_pow',
  'round_down_pow',
  'bit_split_lowtohigh',
  'digit_join_lowtohigh';

# uncomment this to run the ### lines
# use Smart::Comments;


use constant default_n_start => 0;
use constant class_x_negative => 1;
use constant class_y_negative => 0;
use constant x_negative_at_n => 2;
use constant sumxy_minimum => 0;   # triangular X>=-Y
use constant diffxy_maximum => 0;  # triangular X<=Y so X-Y<=0
use constant dy_minimum => 0; # across rows dY=0
use constant dy_maximum => 1; # then up dY=1 at end
use constant tree_num_children_list => (0,1,2);
use constant dir_maximum_dxdy => (-1,0); # West


#------------------------------------------------------------------------------
sub new {
  my $self = shift->SUPER::new(@_);
  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }
  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### ToothpickUpist n_to_xy(): $n

  # written as $n-n_start() rather than "-=" so as to provoke an
  # uninitialized value warning if $n==undef
  $n = $n - $self->{'n_start'};   # N=0 basis

  if ($n < 0) {
    return;
  }
  if ($n == 0 || is_infinite($n)) {
    return ($n,$n);
  }

  # this frac behaviour unspecified yet
  {
    my $int = int($n);
    ### $int
    ### $n
    if ($n != $int) {
      my $frac = $n - $int;  # inherit possible BigFloat
      $int += $self->{'n_start'};
      my ($x1,$y1) = $self->n_to_xy($int);
      my ($x2,$y2) = $self->n_to_xy($int+1);
      my $dx = $x2-$x1;
      my $dy = $y2-$y1;
      return ($frac*$dx + $x1, $frac*$dy + $y1);
    }
    $n = $int;       # BigFloat int() gives BigInt, use that
  }
  ### $n

  my ($depthbits, $lowbit, $ndepth) = _n0_to_depthbits($n);
  ### $depthbits
  ### $ndepth
  ### n remainder: $n-$ndepth

  my @nbits = bit_split_lowtohigh($n-$ndepth); # offset into row

  ### @nbits
  ### $lowbit

  # Where there's a 0-bit in the depth remains a 0-bit.
  # Where there's a 1-bit in the depth takes a bit from Noffset.
  # Small Noffset has less bits than the depth 1s, hence "|| 0".
  #
  my @xbits = map {$_ && (shift @nbits || 0)} @$depthbits;
  ### @xbits

  my $zero = $n * 0;
  my $x = digit_join_lowtohigh (\@xbits,    2, $zero);
  my $y = digit_join_lowtohigh ($depthbits, 2, $zero);

  ### Y without lowbit: $y

  return (2*$x-$y,  # triangular style
          $y + $lowbit);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### ToothpickUpist xy_to_n(): "$x, $y"

  $y = round_nearest ($y);
  $x = round_nearest($x);

  # odd points X!=Ymod2 are the second copy of the triangle, go to Y-1 for them
  $x += $y;
  my $lowbit = _divrem_mutate ($x, 2);
  $y -= $lowbit;
  ### odd adjusted xy: "$x,$y"

  return _right_xy_to_n ($self, $x,$y, $lowbit);
}

# with X,Y in the align="right" style,
#
#  |
sub _right_xy_to_n {
  my ($self, $x, $y, $lowbit) = @_;
  ### _right_xy_to_n(): "x=$x y=$y lowbit=$lowbit"

  unless ($x >= 0 && $x <= $y && $y >= 0) {
    ### outside horizontal row range ...
    return undef;
  }
  if (is_infinite($y)) {
    return $y;
  }

  my $zero = ($y * 0);
  my $n = $zero;          # inherit bignum 0
  my $npower = $zero+2;   # inherit bignum 2

  my @xbits = bit_split_lowtohigh($x);
  my @depthbits = bit_split_lowtohigh($y);

  my @nbits;  # N offset into row
  foreach my $i (0 .. $#depthbits) {      # x,y bits low to high
    if ($depthbits[$i]) {
      $n = 2*$n + $npower;
      push @nbits, $xbits[$i] || 0;   # low to high
    } else {
      if ($xbits[$i]) {
        return undef;
      }
    }
    $npower *= 3;
  }

  if ($lowbit) {
    push @nbits, 1;
  }

  ### n at left end of y row: $n
  ### n offset for x: @nbits
  ### total: $n + digit_join_lowtohigh(\@nbits,2,$zero) + $self->{'n_start'}

  return $n + digit_join_lowtohigh(\@nbits,2,$zero) + $self->{'n_start'};
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### ToothpickUpist rect_to_n_range(): "$x1,$y1, $x2,$y2"

  $y1 = round_nearest ($y1);
  $y2 = round_nearest ($y2);
  if ($y1 > $y2) { ($y1,$y2) = ($y2,$y1) }

  $x1 = round_nearest ($x1);
  $x2 = round_nearest ($x2);
  if ($x1 > $x2) { ($x1,$x2) = ($x2,$x1) }

  if ($y2 < 0) {
    ### all negative ...
    return (1, 0);
  }
  $y1 -= 1;
  if ($y1 < 0) {
    $y1 = 0;
  }

  ### range using: "y1=$y1  y2=$y2"

  return (_right_xy_to_n($self,   0,$y1, 0),
          _right_xy_to_n($self, $y2,$y2, 1));
}


#------------------------------------------------------------------------------
use constant tree_num_roots => 1;

sub tree_n_num_children {
  my ($self, $n) = @_;

  $n = $n - $self->{'n_start'};   # N=0 basis
  if (is_infinite($n) || $n < 0) {
    return undef;
  }

  my ($depthbits, $lowbit, $ndepth) = _n0_to_depthbits($n);
  if (! $lowbit) {
    return 1;
  }
  unless (shift @$depthbits) {  # low bit above $lowbit doubling
    # Depth even (or zero), two children under every point.
    return 2;
  }

  # Depth odd, single child under some or all points.
  # When depth==1mod4 it's all points, when depth has more than one
  # trailing 1-bit then it's only some points.
  #
  $n -= $ndepth;  # Noffset into row
  my $repbit = _divrem_mutate($n,2);
  while (shift @$depthbits) {  # low to high
    if (_divrem_mutate($n,2) != $repbit) {
      return 0;
    }
  }
  return 1;
}

sub tree_n_children {
  my ($self, $n) = @_;
  ### tree_n_children(): $n

  $n = $n - $self->{'n_start'};   # N=0 basis
  if (is_infinite($n) || $n < 0) {
    return;
  }

  my ($depthbits, $lowbit, $ndepth, $nwidth) = _n0_to_depthbits($n);
  if (! $lowbit) {
    ### doubled to children at nwidth below ...
    return ($n + $nwidth);
  }

  $n -= $ndepth;  # Noffset into row

  if (shift @$depthbits) {
    # Depth odd, single child under some or all points.
    # When depth==1mod4 it's all points, when depth has more than one
    # trailing 1-bit then it's only some points.
    while (shift @$depthbits) {  # depth==3mod4 or more low 1s
      my $repbit = _divrem_mutate($n,2);
      if (($n % 2) != $repbit) {
        return;
      }
    }
    return $n + $ndepth+$nwidth + $self->{'n_start'};

  } else {
    # Depth even (or zero), two children under every point.
    $n = 2*$n + $ndepth+$nwidth + $self->{'n_start'};
    return ($n,$n+1);
  }
}

sub tree_n_parent {
  my ($self, $n) = @_;

  my ($x,$y) = $self->n_to_xy($n)
    or return undef;

  if (($x%2) != ($y%2)) {
    ### odd, directly down ...
    return $self->xy_to_n($x,$y-1);
  }

  ### even, to one side or the other ...
  my $n_parent = $self->xy_to_n($x-1, $y);
  if (defined $n_parent) {
    return $n_parent;
  }
  return $self->xy_to_n($x+1,$y);
}

sub tree_n_to_depth {
  my ($self, $n) = @_;
  ### ToothpickUpist n_to_depth(): $n
  $n = $n - $self->{'n_start'};
  unless ($n >= 0) {
    return undef;  # negatives, -infinity, NaN
  }
  if (is_infinite($n)) {
    return $n;     # +infinity
  }
  my ($depthbits, $lowbit) = _n0_to_depthbits($n);
  unshift @$depthbits, $lowbit;
  return digit_join_lowtohigh ($depthbits, 2, $n*0);
}
sub tree_depth_to_n {
  my ($self, $depth) = @_;
  ### tree_depth_to_n(): $depth
  if ($depth >= 0) {
    # $depth==+infinity becomes nan from divrem, prefer to return N=+infinity
    # for +inf depth
    if (is_infinite($depth)) {
      return $depth;
    }
    my $lowbit = _divrem_mutate($depth,2);
    return _right_xy_to_n($self,0,$depth, $lowbit);
  } else {
    return undef;
  }
}

sub tree_n_to_subheight {
  my ($self, $n) = @_;
  ### ToothpickUpist tree_n_to_subheight(): $n

  $n = $n - $self->{'n_start'};
  if (is_infinite($n) || $n < 0) {
    return undef;
  }
  my ($depthbits, $lowbit, $ndepth) = _n0_to_depthbits($n);
  $n -= $ndepth;      # remaining offset into row
  my @nbits = bit_split_lowtohigh($n);

  ### $lowbit
  ### $depthbits

  my $target = $nbits[0] || 0;
  foreach my $i (0 .. $#$depthbits) {
    unless ($depthbits->[$i] ^= 1) {  # flip 0<->1, at original==1 take nbit
      if ((shift @nbits || 0) != $target) {
        unshift @$depthbits, 1-$lowbit;
        $#$depthbits = $i;
        ### $depthbits
        return digit_join_lowtohigh($depthbits, 2, $n*0);
      }
    }
  }
  return undef; # first or last of row, infinite
}

sub _EXPERIMENTAL__tree_n_to_leafdist {
  my ($self, $n) = @_;
  ### _EXPERIMENTAL__tree_n_to_leafdist(): $n

  $n = $n - $self->{'n_start'};   # N=0 basis
  if (is_infinite($n) || $n < 0) {
    return undef;
  }

  # depth bits leafdist
  #   0     0,0    7
  #   1     0,1    6
  #   2     1,0    5
  #   3     1,1    4
  #   4   1,0,0    3
  #   5   1,0,1    2
  #   6   1,1,0    1 or 9
  #   7   1,1,1    0 or 8
  # ignore $lowbit until last, bits above same as SierpinskiTriangle
  #
  my ($depthbits, $lowbit, $ndepth) = _n0_to_depthbits($n);
  $lowbit = 1-$lowbit;

  my $ret = 6 - 2*((shift @$depthbits)||0);
  if (shift @$depthbits) { $ret -= 4; }
  ### $ret
  if ($ret) {
    return $ret + $lowbit;
  }

  $n -= $ndepth;
  ### Noffset into row: $n

  # Low bits of Nrem unchanging while trailing 1-bits in @depthbits,
  # to distinguish between leaf or non-leaf.  Same as tree_n_children().
  #
  my $repbit = _divrem_mutate($n,2); # low bit of $n
  ### $repbit
  do {
    ### next bit: $n%2
    if (_divrem_mutate($n,2) != $repbit) {  # bits of $n offset low to high
      return $lowbit;  # is a leaf
    }
  } while (shift @$depthbits);
  return 8+$lowbit; # is a non-leaf
}

# Ndepth = 2 * (        3^a      first N at this depth
#               +   2 * 3^b
#               + 2^2 * 3^c
#               + 2^3 * 3^d
#               + ... )

sub _n0_to_depthbits {
  my ($n) = @_;
  ### _n0_to_depthbits(): $n

  if ($n == 0) {
    return ([], 0, 0, 1);
  }

  my ($nwidth, $bitpos) = round_down_pow ($n/2, 3);
  ### nwidth power-of-3: $nwidth
  ### $bitpos

  $nwidth *= 2;   # two of each row

  my @depthbits;
  my $ndepth = 0;
  for (;;) {
    ### at: "n=$n nwidth=$nwidth bitpos=$bitpos depthbits=".join(',',map{$_||0}@depthbits)

    if ($n >= $ndepth + $nwidth) {
      $depthbits[$bitpos] = 1;
      $ndepth += $nwidth;
      $nwidth *= 2;
    } else {
      $depthbits[$bitpos] = 0;
    }
    last unless --$bitpos >= 0;
    $nwidth /= 3;
  }

  # Nwidth = 2**count1bits(depth)
  ### assert: $nwidth == 2*(1 << scalar(grep{$_}@depthbits))

  # first or second of the two of each row
  $nwidth /= 2;
  my $lowbit = ($n >= $ndepth + $nwidth ? 1 : 0);
  if ($lowbit) {
    $ndepth += $nwidth;
  }
  ### final depthbits: join(',',@depthbits)

  return (\@depthbits, $lowbit, $ndepth, $nwidth);
}

#------------------------------------------------------------------------------
# levels

sub level_to_n_range {
  my ($self, $level) = @_;
  return (0, 2* 3**$level - 1);
}
sub n_to_level {
  my ($self, $n) = @_;
  if ($n < 0) { return undef; }
  if (is_infinite($n)) { return $n; }
  $n = round_nearest($n);
  _divrem_mutate ($n, 2);
  my ($pow, $exp) = round_up_pow ($n+1, 3);
  return $exp;
}

#------------------------------------------------------------------------------
1;
__END__

=for stopwords eg Ryde Sierpinski ie Ymin Ymax OEIS Online rowpoints Nleft Math-PlanePath-Toothpick Gould's Nend bitand Noffset Applegate Automata Congressus Numerantium

=head1 NAME

Math::PlanePath::ToothpickUpist -- self-similar triangular tree traversal

=head1 SYNOPSIS

 use Math::PlanePath::ToothpickUpist;
 my $path = Math::PlanePath::ToothpickUpist->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This is toothpick variation where a vertical toothpick may only extend
upwards.

=cut

# math-image --path=ToothpickUpist --all --output=numbers --size=180x11

=pod

    66 62    63 67                                  68 64    65 69      10
       58 56 59                                        60 57 61          9
          54 46    47    48    49    50    51    52    53 55             8
             38 34 39    40 35 41    42 36 43    44 37 45                7
                30 26    27 31          32 28    29 33                   6
                   22 20 23                24 21 25                      5
                      18 14    15    16    17 19                         4
                         10  8 11    12  9 13                            3
                             6  4     5  7                               2
                                2  1  3                                  1
                                   0                                <- Y=0

    X= -9 -8 -7 -6 -5 -4 -3 -2 -1  0  1  2  3  4  5  6  7  8  9 10 ...

X<Applegate, David>X<Pol, Omar E.>X<Sloane, Neil>This is a 90-degree rotated
version of the "leftist" pattern from part 7 "Leftist Toothpicks" of

=over

David Applegate, Omar E. Pol, N.J.A. Sloane, "The Toothpick Sequence and
Other Sequences from Cellular Automata", Congressus Numerantium, volume 206
(2010), pages 157-191.  L<http://www.research.att.com/~njas/doc/tooth.pdf>

=back

As per C<ToothpickTree> (L<Math::PlanePath::ToothpickTree>) each point is
considered a toothpick of length 2, starting from an initial vertical
toothpick at the origin X=0,Y=0.  Then the pattern grows by adding a
toothpick at each exposed end, so long as it would not cause two toothpicks
to overlap (an end can touch, but toothpicks cannot overlap).  The variation
here is that vertical toothpicks can only grow upwards, so nothing is ever
added at the bottom end of a vertical.

    ...     ...     ...      ...
     |       |       |        |
    10---8--11      12---9---13
     |   |               |    |
         6---4--- ---5---7
         |   |       |   |
             2---1---3
             |   |   |
                 0
                 |

Points are numbered breadth-first tree traversal and left to right across
the row.  This means for example N=6 and N=7 are up toothpicks giving N=8
and N=9 in row Y=3, and then those two grow to N=10,11,12,13 respectively
left and right.

=head2 Sierpinski Triangle

X<Sierpinski, Waclaw>As described in the paper above, the rule gives a
version of the Sierpinski triangle where each row is doubled.  (See
L<Math::PlanePath::SierpinskiTriangle>.)

Vertical toothpicks are on "even" points X==Y mod 2 and make the Sierpinski
triangle pattern.  Horizontal toothpicks are on "odd" points X!=Y mod 2 and
are a second copy of the triangle, positioned up one at Y+1.

      5                                    h               h
      4     v               v                h   h   h   h
      3       v   v   v   v                    h       h
      2         v       v         plus           h   h
      1           v   v                            h
    Y=0             v

                        gives ToothpickUpist

                    5   ..h..           ..h..
                    4     v h   h   h   h v       
                    3       v h v   v h v
                    2         v h   h v
                    1           v h v
                  Y=0             v

A vertical toothpick always has a child at its upwards end.  But the
horizontal toothpicks may or may not be able to grow at its two ends.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::ToothpickUpist-E<gt>new ()>

Create and return a new path object.

=back

=head2 Tree Methods

=over

=item C<@n_children = $path-E<gt>tree_n_children($n)>

Return the children of C<$n>, or an empty list if C<$nE<lt>0> (ie. before
the start of the path).

Every vertical toothpick has a single child.  The horizontal toothpicks have
either 0, 1 or 2 children according to the Sierpinski triangle pattern.
(See L<Math::PlanePath::SierpinskiTriangle/N to Number of Children>).

=item C<$n_parent = $path-E<gt>tree_n_parent($n)>

Return the parent node of C<$n>, or C<undef> if C<$nE<lt>=0> (the start of
tree).

For a horizontal toothpick the parent is the vertical below it.  For a
vertical toothpick the parent is the horizontal to its left or its right,
according to the Sierpinski triangle pattern.

=item C<$depth = $path-E<gt>tree_n_to_depth($n)>

Return the depth of node C<$n>, or C<undef> if there's no point C<$n>.

Each row Y has two depth levels, starting from Y=1 having depth=1 and
depth=2, so depth=ceil(Y/2).

=item C<$n = $path-E<gt>tree_depth_to_n($depth)>

=item C<$n = $path-E<gt>tree_depth_to_n_end($depth)>

Return the first or last N of tree row C<$depth>.  The start of the tree is
depth=0 at the origin X=0,Y=0.

For even C<$depth> this is the N at the left end of each row X=-Y,Y=depth/2.
For odd C<$depth> it's the point above there, one cell in from the left end,
so X=-Y+1,Y=ceil(depth/2).

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<(0, 2 * 3**$level - 1)>.  There are 3^level pairs of points making
up a level, numbered starting from 0.

=back

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to this
path include,

=over

L<http://oeis.org/A151566> (etc)

=back

    A151566    total cells at depth=n, tree_depth_to_n()
    A060632     cells added, 2^count1bits(floor(n/2))
    A151565     cells added (duplicate of A060632)
    A175098    total lattice points touched by length=2 toothpicks

    A160742    total*2
    A160744    total*3
    A160745    added*3
    A160746    total*4

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::SierpinskiTriangle>,
L<Math::PlanePath::ToothpickTree>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014, 2015 Kevin Ryde

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

# Local variables:
# compile-command: "math-image --wx --path=ToothpickUpist --all --figure=toothpick --scale=10"
# End:
