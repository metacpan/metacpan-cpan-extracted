# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde

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


# math-image --path=KochCurve --lines --scale=10
# math-image --path=KochCurve --all --scale=10

# continuous but nowhere differentiable
#
# Sur une Courbe Continue sans Tangente, Obtenue par une Construction
# Géométrique Élémentaire
#
# http://www.nku.edu/~curtin/grenouille.html
# http://www.nku.edu/~curtin/koch_171.jpg
#
# Cesàro, "Remarques sur la Courbe de von Koch." Atti della
# R. Accad. della Scienze Fisiche e Matem. Napoli 12, No. 15, 1-12,
# 1905. Reprinted as §228 in Opere scelte, a cura dell'Unione matematica
# italiana e col contributo del Consiglio nazionale delle ricerche, Vol. 2:
# Geometria, Analisi, Fisica Matematica. Rome: Edizioni Cremonese,
# pp. 464-479, 1964.
#
# Thue-Morse count 1s mod 2 is net direction
# Toeplitz first diffs is turn sequence +1 or -1
#
# J. Ma and J.A. Holdener. When Thue-Morse Meets Koch. In Fractals:
# Complex Geometry, Patterns, and Scaling in Nature and Society, volume 13,
# pages 191-206, 2005.
# http://personal.kenyon.edu/holdenerj/StudentResearch/WhenThueMorsemeetsKochJan222005.pdf
#
# F.M. Dekking. On the Distribution of Digits In Arithmetic Sequences.
# In Seminaire de Theorie des Nombres de Bordeaux, volume 12, 1983, pages
# 3201-3212,
#



package Math::PlanePath::KochCurve;
use 5.004;
use strict;
use List::Util 'sum','first';

use vars '$VERSION', '@ISA';
$VERSION = 128;
use Math::PlanePath;
@ISA = ('Math::PlanePath');
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_down_pow',
  'round_up_pow',
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';

# uncomment this to run the ### lines
# use Smart::Comments;


use constant n_start => 0;
use constant class_x_negative => 0;
use constant class_y_negative => 0;
use constant diffxy_minimum => 0;  # X>=Y octant so X-Y>=0
use constant dx_minimum => -2;
use constant dx_maximum => 2;
use constant dy_minimum => -1;
use constant dy_maximum => 1;
*_UNDOCUMENTED__dxdy_list = \&Math::PlanePath::_UNDOCUMENTED__dxdy_list_six;
use constant absdx_minimum => 1; # never vertical
use constant dsumxy_minimum => -2; # diagonals
use constant dsumxy_maximum => 2;
use constant ddiffxy_minimum => -2;
use constant ddiffxy_maximum => 2;
use constant dir_maximum_dxdy => (1,-1); # South-East
use constant turn_any_straight => 0; # never straight


#------------------------------------------------------------------------------

sub n_to_xy {
  my ($self, $n) = @_;
  ### KochCurve n_to_xy(): $n

  # secret negatives to -.5
  if (2*$n < -1) { return; }
  if (is_infinite($n)) { return ($n,$n); }

  my $x;
  my $y;
  {
    my $int = int($n);
    $x = 2 * ($n - $int);  # usually positive, but n=-0.5 gives x=-0.5
    $y = $x * 0;           # inherit possible bigrat 0
    $n = $int;             # BigFloat int() gives BigInt, use that
  }

  my $len = $y+1;  # inherit bignum 1
  foreach my $digit (digit_split_lowtohigh($n,4)) {
    ### at: "$x,$y  digit=$digit"

    if ($digit == 0) {

    } elsif ($digit == 1) {
      ($x,$y) = (($x-3*$y)/2 + 2*$len,     # rotate +60
                 ($x+$y)/2);

    } elsif ($digit == 2) {
      ($x,$y) = (($x+3*$y)/2 + 3*$len,    # rotate -60
                 ($y-$x)/2   + $len);

    } else {
      ### assert: $digit==3
      $x += 4*$len;
    }
    $len *= 3;
  }

  ### final: "$x,$y"
  return ($x,$y);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### KochPeaks xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);
  if ($y < 0 || $x < 0 || (($x ^ $y) & 1)) {
    ### neg y or parity different ...
    return undef;
  }
  my ($len,$level) = round_down_pow(($x/2)||1, 3);
  ### $level
  ### $len
  if (is_infinite($level)) {
    return $level;
  }

  my $n = 0;
  foreach (0 .. $level) {
    $n *= 4;
    ### at: "level=$level len=$len   x=$x,y=$y  n=$n"
    if ($x < 3*$len) {
      if ($x < 2*$len) {
        ### digit 0 ...
      } else {
        ### digit 1 ...
        $x -= 2*$len;
        ($x,$y) = (($x+3*$y)/2,   # rotate -60
                   ($y-$x)/2);
        $n += 1;
      }
    } else {
      $x -= 4*$len;
      ### digit 2 or 3 to: "x=$x"
      if ($x < $y) {   # before diagonal
        ### digit 2...
        $x += $len;
        $y -= $len;
        ($x,$y) = (($x-3*$y)/2,     # rotate +60
                   ($x+$y)/2);
        $n += 2;
      } else {
        #### digit 3...
        $n += 3;
      }
    }
    $len /= 3;
  }
  ### end at: "x=$x,y=$y   n=$n"
  if ($x != 0 || $y != 0) {
    return undef;
  }
  return $n;
}

# level extends to x= 2*3^level
#                  level = log3(x/2)
#
# exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### KochCurve rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest ($x1);
  $x2 = round_nearest ($x2);
  $y1 = round_nearest ($y1);
  $y2 = round_nearest ($y2);
  if ($x1 > $x2) { ($x1,$x2) = ($x2,$x1); }
  if ($y1 > $y2) { ($y1,$y2) = ($y2,$y1); }

  if ($x2 < 0 || $y2 < 0
      || 3*$y1 > $x2 ) {   # above line Y=X/3
    return (1,0);
  }

  #        \
  #          \
  #       *    \
  #      / \     \
  # o-+-*   *-+-e  \
  # 0     3     6
  #
  # 3*Y+X/2 - (Y!=0)
  #
  #                  /
  #             *-+-*
  #              \
  #       *       *
  #      / \     /
  # o-+-*   *-+-*
  # 0     3     6   X/2
  #
  my ($len, $level) = round_down_pow ($x2/2, 3);
  return _rect_to_n_range_rot ($len, $level, 0, $x1,$y1, $x2,$y2);



  # (undef, my $level) = round_down_pow ($x2/2, 3);
  # ### $level
  # return (0, 4**($level+1)-1);
}


my @dir6_to_dx = (2, 1,-1,-2, -1, 1);
my @dir6_to_dy = (0, 1, 1, 0, -1,-1);
my @max_digit_to_rot = (1, -2, 1, 0);
my @min_digit_to_rot = (0, 1, -2, 1);
my @max_digit_to_offset = (-1, -1, -1, 2);

sub _rect_to_n_range_rot {
  my ($initial_len, $level_max, $initial_rot, $x1,$y1, $x2,$y2) = @_;
  ### KochCurve _rect_to_n_range_rot(): "$x1,$y1  $x2,$y2  len=$initial_len level=$level_max rot=$initial_rot"

  my ($rot, $len, $x, $y);
  my $overlap = sub {
    ### overlap: "$x,$y len=$len rot=$rot"

    if ($len == 1) {
      return ($x >= $x1 && $x <= $x2
              && $y >= $y1 && $y <= $y2);
    }
    my $len = $len / 3;

    if ($rot < 3) {
      if ($rot == 0) {
        #       *
        #      / \
        # o-+-*   *-+-.
        return ($y <= $y2               # bottom before end
                && $y+$len >= $y1
                && $x <= $x2
                && $x+6*$len > $x1);    # right before end, exclusive
      } elsif ($rot == 1) {
        #       .
        #      /
        # *-+-*
        #  \
        #   *  +-----
        #  /   |x1,y2
        # o
        return ($x <= $x2              # left before end
                && $y+3*$len > $y1     # top after start, exclusive
                && $y-$x <= $y2-$x1);  # diag before corner
      } else {
        # .    |x1,y1
        #  \   +-----
        #   *
        #  /
        # *-+-*
        #      \
        #       o
        return ($y <= $y2              # bottom before end
                && $x-3*$len <=$x2     # left before end
                && $y+$x >= $y1+$x1);  # diag after corner
      }
    } else {
      if ($rot == 3) {
        # .-+-*   *-+-o
        #      \ /
        #       *
        return ($y >= $y1              # top after start
                && $y-$len <= $y2      # bottom before end
                && $x >= $x1           # right after start
                && $x-6*$len < $x2);   # left before end, exclusive
      } elsif ($rot == 4) {
        # x2,y1|    o
        # -----+   /
        #         *
        #          \
        #       *-+-*
        #      /
        #     .
        return ($x >= $x1              # right after start
                && $y-3*$len < $y2     # bottom before end, exclusive
                && $y-$x >= $y1-$x2);  # diag after corner
      } else {
        #    o
        #     \
        #      *-+-*
        #         /
        #        *
        # -----+  \
        # x2,y2|   .
        return ($y >= $y1              # top after start
                && $x+3*$len >= $x1    # right after start
                && $y+$x <= $y2+$x2);  # diag before corner
      }
    }
  };

  my $zero = 0*$x1*$x2*$y1*$y2;
  my @lens = ($initial_len);
  my $n_hi;
  $rot = $initial_rot;
  $len = $initial_len;
  $x = $zero;
  $y = $zero;
  my @digits = (4);

  for (;;) {
    my $digit = --$digits[-1];
    ### max at: "digits=".join(',',@digits)."  xy=$x,$y   len=$len"

    if ($digit < 0) {
      pop @digits;
      if (! @digits) {
        ### nothing found to level_max ...
        return (1, 0);
      }
      ### end of digits, backtrack ...
      $len = $lens[$#digits];
      next;
    }

    my $offset = $max_digit_to_offset[$digit];
    $rot = ($rot - $max_digit_to_rot[$digit]) % 6;
    $x += $dir6_to_dx[$rot] * $offset * $len;
    $y += $dir6_to_dy[$rot] * $offset * $len;

    ### $offset
    ### $rot

    if (&$overlap()) {
      if ($#digits >= $level_max) {
        ### yes overlap, found n_hi ...
        ### digits: join(',',@digits)
        ### n_hi: _digit_join_hightolow (\@digits, 4, $zero)
        $n_hi = _digit_join_hightolow (\@digits, 4, $zero);
        last;
      }
      ### yes overlap, descend ...
      push @digits, 4;
      $len = ($lens[$#digits] ||= $len/3);
    } else {
      ### no overlap, next digit ...
    }
  }

  $rot = $initial_rot;
  $x = $zero;
  $y = $zero;
  $len = $initial_len;
  @digits = (-1);

  for (;;) {
    my $digit = ++$digits[-1];
    ### min at: "digits=".join(',',@digits)."  xy=$x,$y   len=$len"

    if ($digit > 3) {
      pop @digits;
      if (! @digits) {
        ### oops, n_lo not found to level_max ...
        return (1, 0);
      }
      ### end of digits, backtrack ...
      $len = $lens[$#digits];
      next;
    }

    ### $digit
    ### rot increment: $min_digit_to_rot[$digit]
    $rot = ($rot + $min_digit_to_rot[$digit]) % 6;

    if (&$overlap()) {
      if ($#digits >= $level_max) {
        ### yes overlap, found n_lo ...
        ### digits: join(',',@digits)
        ### n_lo: _digit_join_hightolow (\@digits, 4, $zero)
        return (_digit_join_hightolow (\@digits, 4, $zero),
                $n_hi);
      }
      ### yes overlap, descend ...
      push @digits, -1;
      $len = ($lens[$#digits] ||= $len/3);

    } else {
      ### no overlap, next digit ...
      $x += $dir6_to_dx[$rot] * $len;
      $y += $dir6_to_dy[$rot] * $len;
    }
  }
}

# $aref->[0] high digit
sub _digit_join_hightolow {
  my ($aref, $radix, $zero) = @_;
  my @lowtohigh = reverse @$aref;
  return digit_join_lowtohigh(\@lowtohigh, $radix, $zero);
}


my @digit_to_dir = (0, 1, -1, 0);
my @digit_to_nextturn = (1,  # digit=1 (with +1 for "next" N)
                         -2, # digit=2
                         1); # digit=3
sub n_to_dxdy {
  my ($self, $n) = @_;
  ### n_to_dxdy(): $n

  if ($n < 0) {
    return;  # first direction at N=0
  }
  if (is_infinite($n)) {
    return ($n,$n);
  }

  my $int = int($n);
  $n -= $int;
  my @ndigits = digit_split_lowtohigh($int,4);

  my $dir6 = sum(0, map {$digit_to_dir[$_]} @ndigits) % 6;
  my $dx = $dir6_to_dx[$dir6];
  my $dy = $dir6_to_dy[$dir6];

  if ($n) {
    # fraction part

    # lowest non-3 digit, or zero if all 3s (0 above high digit)
    $dir6 += $digit_to_nextturn[ first {$_!=3} @ndigits, 0 ];
    $dir6 %= 6;
    $dx += $n*($dir6_to_dx[$dir6] - $dx);
    $dy += $n*($dir6_to_dy[$dir6] - $dy);
  }
  return ($dx, $dy);
}

sub _UNTESTED__n_to_dir6 {
  my ($self, $n) = @_;
  if ($n < 0) {
    return undef;  # first direction at N=0
  }
  if (is_infinite($n)) {
    return ($n,$n);
  }
  return (sum (map {$digit_to_dir[$_]} digit_split_lowtohigh($n,4))
          || 0) # if empty
    % 6;
}

my @n_to_turn6 = (undef,
                      1,  # +60 degrees
                      -2, # -120 degrees
                      1); # +60 degrees
sub _UNTESTED__n_to_turn6 {
  my ($self, $n) = @_;
  if (is_infinite($n)) {
    return undef;
  }
  while ($n) {
    my $digit = _divrem_mutate($n,4);
    if ($digit) {
      # lowest non-zero digit
      return $n_to_turn6[$digit];
    }
  }
  return 0;
}
sub _UNTESTED__n_to_turn_LSR {
  my ($self, $n) = @_;
  my $turn6 = $self->_UNTESTED__n_to_turn6($n) || return undef;
  return ($turn6 > 0 ? 1 : -1);
}
sub _UNTESTED__n_to_turn_left {
  my ($self, $n) = @_;
  my $turn6 = $self->_UNTESTED__n_to_turn6($n) || return undef;
  return ($turn6 > 0 ? 1 : 0);
}
sub _UNTESTED__n_to_turn_right {
  my ($self, $n) = @_;
  my $turn6 = $self->_UNTESTED__n_to_turn6($n) || return undef;
  return ($turn6 < 0 ? 1 : 0);
}

#------------------------------------------------------------------------------
# levels

sub level_to_n_range {
  my ($self, $level) = @_;
  return (0, 4**$level);
}
sub n_to_level {
  my ($self, $n) = @_;
  if ($n < 0) { return undef; }
  if (is_infinite($n)) { return $n; }
  $n = round_nearest($n);
  my ($pow, $exp) = round_up_pow ($n, 4);
  return $exp;
}


#------------------------------------------------------------------------------
1;
__END__

=for stopwords eg Ryde Helge von Koch Math-PlanePath Nlevel differentiable ie OEIS Xlevel floorlevel Nhi Nlo Ndigit Une thode trique mentaire tude de Certaines orie des Courbes Acta Arithmetica

=head1 NAME

Math::PlanePath::KochCurve -- horizontal Koch curve

=head1 SYNOPSIS

 use Math::PlanePath::KochCurve;
 my $path = Math::PlanePath::KochCurve->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

X<Koch, Helge von>This is an integer version of the self-similar Koch curve,

=over 4

Helge von Koch, "Une ME<233>thode GE<233>omE<233>trique
E<201>lE<233>mentaire pour l'E<201>tude de Certaines Questions de la
ThE<233>orie des Courbes Planes", Acta Arithmetica, volume 30, 1906, pages
145-174.  L<http://archive.org/details/actamathematica11lefgoog>

=back

It goes along the X axis and makes triangular excursions upwards.

                               8                                   3
                             /  \
                      6---- 7     9----10                18-...    2
                       \              /                    \
             2           5          11          14          17     1
           /  \        /              \        /  \        /
     0----1     3---- 4                12----13    15----16    <- Y=0

     ^
    X=0   2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19

The replicating shape is the initial N=0 to N=4,

            *
           / \
      *---*   *---*

which is rotated and repeated 3 times in the same pattern to give sections
N=4 to N=8, N=8 to N=12, and N=12 to N=16.  Then that N=0 to N=16 is itself
replicated three times at the angles of the base pattern, and so on
infinitely.

The X,Y coordinates are arranged on a square grid using every second point,
per L<Math::PlanePath/Triangular Lattice>.  The result is flattened
triangular segments with diagonals at a 45 degree angle.

=head2 Level Ranges

Each replication adds 3 copies of the existing points and is thus 4 times
bigger, so if N=0 to N=4 is reckoned as level 1 then a given replication
level goes from

    Nstart = 0
    Nlevel = 4^level   (inclusive)

Each replication is 3 times the width.  The initial N=0 to N=4 figure is 6
wide and in general a level runs from

    Xstart = 0
    Xlevel = 2*3^level   at N=Nlevel

The highest Y is 3 times greater at each level similarly.  The peak is at
the midpoint of each level,

    Npeak = (4^level)/2
    Ypeak = 3^level
    Xpeak = 3^level

It can be seen that the N=6 point backtracks horizontally to the same X as
the start of its section N=4 to N=8.  This happens in the further
replications too and is the maximum extent of the backtracking.

The Nlevel is multiplied by 4 to get the end of the next higher level.  The
same 4*N can be applied to all points N=0 to N=Nlevel to get the same shape
but a factor of 3 bigger X,Y coordinates.  The in-between points 4*N+1,
4*N+2 and 4*N+3 are then new finer structure in the higher level.

=head2 Fractal

Koch conceived the curve as having a fixed length and infinitely fine
structure, making it continuous everywhere but differentiable nowhere.  The
code here can be pressed into use for that sort of construction for a given
level of granularity by scaling

    X/3^level
    Y/3^level

which makes it a fixed 2 wide by 1 high.  Or for unit-side equilateral
triangles then apply further factors 1/2 and sqrt(3)/2, as noted in
L<Math::PlanePath/Triangular Lattice>.

    (X/2) / 3^level
    (Y*sqrt(3)/2) / 3^level


=head2 Area

The area under the curve to a given level can be calculated from its
self-similar nature.  The curve at level+1 is 3 times wider and higher and
adds a triangle of unit area onto each line segment.  So reckoning the line
segment N=0 to N=1 as level=0 (which is area[0]=0),

    area[level] = 9*area[level-1] + 4^(level-1)
                = 4^(level-1) + 9*4^(level-2) + ... + 9^(level-1)*4^0

                  9^level - 4^level
                = -----------------
                          5

                = 0, 1, 13, 133, 1261, 11605, 105469, ...  (A016153)

The sides are 6 different angles.  The triangles added on the sides are
always the same shape either pointing up or down.  Base width=2 and height=1
gives area=1.

       *            *-----*   ^
      / \            \   /    | height=1
     /   \            \ /     |
    *-----*            *      v     triangle area = 2*1/2 = 1

    <-----> width=2

If the Y coordinates are stretched to make equilateral triangles then the
number of triangles is not changed and so the area increases by a factor of
the area of the equilateral triangle, sqrt(3)/4.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::KochCurve-E<gt>new ()>

Create and return a new path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

Fractional positions give an X,Y position along a straight line between the
integer positions.

=item C<($n_lo, $n_hi) = $path-E<gt>rect_to_n_range ($x1,$y1, $x2,$y2)>

The returned range is exact, meaning C<$n_lo> and C<$n_hi> are the smallest
and biggest in the rectangle.

=item C<$n = $path-E<gt>n_start()>

Return 0, the first N in the path.

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<(0, 4**$level)>.

=back

=head1 FORMULAS

=head2 N to Turn

The curve always turns either +60 degrees or -120 degrees, it never goes
straight ahead.  In the base 4 representation of N, the lowest non-zero
digit gives the turn.  The first turn is at N=1 so there's always a non-zero
digit in N.

   low digit
    base 4         turn
   ---------   ------------
      1         +60 degrees (left)
      2        -120 degrees (right)
      3         +60 degrees (left)

For example N=8 is 20 base 4, so lowest nonzero "2" means turn -120 degrees
for the next segment.

If the least significant digit is non-zero then it determines the turn,
making the base N=0 to N=4 shape.  If the least significant is zero then the
next level up is in control, eg. N=0,4,8,12,16, making a turn according to
the base shape again at that higher level.  The first and last segments of
the base shape are "straight" so there's no extra adjustment to apply in
those higher digits.

This base 4 digit rule is equivalent to counting low 0-bits.  A low base-4
digit 1 or 3 is an even number of low 0-bits and a low digit 2 is an odd
number of low 0-bits.

    count low 0-bits         turn
    ----------------     ------------
         even             +60 degrees (left)
         odd             -120 degrees (right)

For example N=8 in binary "1000" has 3 low 0-bits and 3 is odd so turn -120
degrees (right).

See L<Math::PlanePath::GrayCode/Turn> for a similar turn sequence arising
from binary Gray code.

=head2 N to Next Turn

The turn at N+1, ie the next turn, can be found from the base-4 digits by
considering how the digits of N change when 1 is added, and the low-digit
turn calculation is applied on those changed digits.

Adding 1 means low digit 0, 1 or 2 will become non-zero.  Any low 3s wrap
around to become low 0s.  So the turn at N+1 can be found from the digits of
N by seeking the lowest non-3

   lowest non-3       turn
    digit of N       at N+1
   ------------   ------------
        0          +60 degrees (left)
        1         -120 degrees (right)
        2          +60 degrees (left)

=head2 N to Direction

The total turn at a given N can be found by counting digits 1 and 2 in
base 4.

    direction = ((count of 1-digits in base 4)
                 - (count of 2-digits in base 4)) * 60 degrees

For example N=11 is "23" in base 4, so 60*(0-1) = -60 degrees.

In this formula the count of 1s and 2s can go past 360 degrees, representing
a spiralling around which occurs at progressively higher replication levels.
The direction can be taken mod 360 degrees, or the count mod 6, for a
direction 0 to 5 if desired.

=head2 N to abs(dX),abs(dY)

The direction expressed as abs(dX) and abs(dY) can be calculated simply from
N modulo 3.  abs(dX) is a repeating pattern 2,1,1 and abs(dY) repeating
0,1,1.

    N mod 3     abs(dX),abs(dY)
    -------     ---------------
       0             2,0            horizontal, East or West
       1             1,1            slope North-East or South-West
       2             1,1            slope North-West or South-East

This works because the direction calculation above corresponds to N mod 3.
Each N digit in base 4 becomes

    N digit
    base 4    direction add
    -------   -------------
       0            0
       1            1
       2           -1
       3            0

Notice that direction == Ndigit mod 3.  Then because 4==1 mod 3 the
power-of-4 for each digit reduces down to 1,

    N = 4^k * digit_k + ... 4^0 * digit_0
    N mod 3 = 1 * digit_k + ... 1 * digit_0
            = digit_k + ... digit_0
    same as
    direction = digit_k + ... + digit_0    taken mod 3

=head2 Rectangle to N Range -- Level

An easy over-estimate of the N values in a rectangle can be had from the
Xlevel formula above.  If XlevelE<gt>rectangleX then Nlevel is past the
rectangle extent.

    X = 2*3^level

so

    floorlevel = floor log_base_3(X/2)
    Nhi = 4^(floorlevel+1) - 1

For example a rectangle extending to X=13 has floorlevel =
floor(log3(13/2))=1 and so Nhi=4^(1+1)-1=15.

The rounding-down of the log3 ensures a point such as X=18 which is the
first in the next Nlevel will give that next level.  So
floorlevel=log3(18/2)=2 (exactly) and Nhi=4^(2+1)-1=63.

The worst case for this over-estimate is when rectangleX==Xlevel, ie. the
rectangle is just into the next level.  In that case Nhi is nearly a factor
4 bigger than it needs to be.

=head2 Rectangle to N Range -- Exact

The exact Nlo and Nhi in a rectangle can be found by searching along the
curve.  For Nlo search forward from the origin N=0.  For Nhi search backward
from the Nlevel over-estimate described above.

At a given digit position in the prospective N the sub-part of the curve
comprising the lower digits has a certain triangular extent.  If it's
outside the target rectangle then step to the next digit value, and to the
next of the digit above when past digit=3 (or below digit=0 when searching
backwards).

There's six possible orientations for the curve sub-part.  In the following
pictures "o" is the start and the surrounding lines show the triangular
extent.  There's just four curve parts shown in each, but these triangles
bound a sub-curve of any level.

   rot=0   -+-               +-----------------+
         --   --              - .-+-*   *-+-o -
       --   *   --             --    \ /    --
     --    / \    --             --   *   --
    - o-+-*   *-+-. -              --   --
   +-----------------+       rot=3   -+-

   rot=1
   +---------+               rot=4    /+
   |      . /                        / |
   |     / /                        / o|
   |*-+-* /                        / / |
   | \   /                        / *  |
   |  * /                        /   \ |
   | / /                        / *-+-*|
   |o /                        / /     |
   | /                        / .      |
   +/                        +---------+

   +\  rot=2                 +---------+
   | \                        \ o      |
   |. \                        \ \     |
   | \ \                        \ *-+-*|
   |  * \                        \   / |
   | /   \                        \ *  |
   |*-+-* \                        \ \ |
   |     \ \                        \ .|
   |      o \                rot=5   \ |
   +---------+                        \+

The "." is the start of the next sub-curve.  It belongs to the next digit
value and so can be excluded.  For rot=0 and rot=3 this means simply
shortening the X range permitted.  For rot=1 and rot=4 similarly the Y
range.  For rot=2 and rot=5 it would require a separate test.

Tight sub-part extent checking reduces the sub-parts which are examined, but
it works perfectly well with a looser check, such as a square box for the
sub-curve extents.  Doing that might be easier if the target region is not a
rectangle but instead some trickier shape.

=head1 OEIS

The Koch curve is in Sloane's Online Encyclopedia of Integer Sequences in
various forms,

=over

L<http://oeis.org/A035263> (etc)

=back

    A335358   (X-Y)/2 diagonal coordinate
    A335359   Y coordinate

    A035263   turn 1=left,0=right, by morphism
    A096268   turn 0=left,1=right, period doubling sequence
    A056832   turn 1=left,2=right, by replicate and flip last
    A309873   turn 1=left,-1=right
    A029883   turn +/-1=left,0=right, Thue-Morse first differences
    A089045   turn +/-1=left,0=right, by +/- something

    A177702   abs(dX) from N=1 onwards, being 1,1,2 repeating
    A011655   abs(dY), being 0,1,1 repeating

    A003159   N positions of left turns, ending even number 0 bits
    A036554   N positions of right turns, ending odd number 0 bits

    A065359   segment direction, *60 degrees
    A229216   segment direction, 1,2,3,-1,-2,-3
    A050292   num left turns 1 to N
    A123087   num right turns 1 to N
    A020988   num left turns 1 to 4^k-1, being 2*(4^k-1)/3
    A002450   num right turns 1 to 4^k-1, being (4^k-1)/3
    A016153   area under the curve, (9^k-4^k)/5

For reference, A217586 is not quite the same as A096268 right turn.  A217586
differs by a 0E<lt>-E<gt>1 flip at N=2^k due to different initial a(1)=1.

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::PeanoCurve>,
L<Math::PlanePath::HilbertCurve>,
L<Math::PlanePath::KochPeaks>,
L<Math::PlanePath::KochSnowflakes>,
L<Math::PlanePath::CCurve>

L<Math::Fractal::Curve>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde

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
