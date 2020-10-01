# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde

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


# cf
#
# http://www.cut-the-knot.org/Curriculum/Geometry/PeanoComplete.shtml
#     applet, directions in 9 sub-parts
#
# math-image --path=PeanoCurve,radix=5 --all --output=numbers
# math-image --path=PeanoCurve,radix=5 --lines
#
# -----------
# Peano:
# T = 0.a1 a2 a3 a4 ...
#        x  y  x  y
#
# X = 0.b1        b2 ...
#       a1        a3.k(a2)
#
# Y = 0.c1        c2 ...
#       a2.k(a1)  a4.k(a1,a3)
#
# b1=a1
# c1 = a2 comp(a1)
# b2 = a3 comp(a2)
# c2 = a4 comp(a1+a3)
#
# bn = a[2n-1] comp a2+a4+...+a[2n-2]
# cn = a[2n] comp a1+a3+...+a[2n-1]
#
# Brouwer(?) no continuous one-to-one between R and RxR, so line and plane
# are distinguished.
#


package Math::PlanePath::PeanoCurve;
use 5.004;
use strict;
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 128;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_down_pow',
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';
use Math::PlanePath::Base::NSEW;

# uncomment this to run the ### lines
# use Smart::Comments;


use constant n_start => 0;
use constant class_x_negative => 0;
use constant class_y_negative => 0;
*xy_is_visited = \&Math::PlanePath::Base::Generic::xy_is_visited_quad1;

use constant parameter_info_array =>
  [ { name      => 'radix',
      display   => 'Radix',
      share_key => 'radix_3',
      type      => 'integer',
      minimum   => 2,
      default   => 3,
      width     => 3,
    } ];

# shared by WunderlichSerpentine
sub dx_minimum {
  my ($self) = @_;
  return ($self->{'radix'} % 2
          ? -1      # odd
          : undef); # even, unlimited
}
sub dx_maximum {
  my ($self) = @_;
  return ($self->{'radix'} % 2
          ? 1         # odd
          : undef);   # even, unlimited
}

# shared by WunderlichSerpentine
sub _UNDOCUMENTED__dxdy_list {
  my ($self) = @_;
  return ($self->{'radix'} % 2
          ? Math::PlanePath::Base::NSEW->_UNDOCUMENTED__dxdy_list
          : ());   # even, unlimited
}
#  *---  b^2-1 -- b^2 ---- b^2+b-1 = (b+1)b-1
#  |                          |
#  *-------
#          |
#  0 ----- b
#
sub _UNDOCUMENTED__dxdy_list_at_n {
  my ($self) = @_;
  return ($self->{'radix'} + 1) * $self->{'radix'} - 1;
}

# shared by WunderlichSerpentine
*dy_minimum = \&dx_minimum;
*dy_maximum = \&dx_maximum;

*dsumxy_minimum = \&dx_minimum;
*dsumxy_maximum = \&dx_maximum;

*ddiffxy_minimum = \&dx_minimum;
*ddiffxy_maximum = \&dx_maximum;

sub dir_maximum_dxdy {
  my ($self) = @_;
  return ($self->{'radix'} % 2
          ? (0,-1)   # odd, South
          : (0,0));  # even, supremum
}

sub _UNDOCUMENTED__turn_any_left_at_n {
  my ($self) = @_;
  return $self->{'radix'} - 1;
}
sub _UNDOCUMENTED__turn_any_right_at_n {
  my ($self) = @_;
  return ($self->{'radix'} == 2 ? 5
          : 2*$self->{'radix'} - 1);
}


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);

  if (! $self->{'radix'} || $self->{'radix'} < 2) {
    $self->{'radix'} = 3;
  }
  return $self;
}

sub _n_to_xykk {
  my ($self, $n) = @_;
  my $radix = $self->{'radix'};
  my $radix_minus_1 = $radix - 1;

  my @ndigits = digit_split_lowtohigh($n,$radix);
  if (scalar(@ndigits) & 1) {
    push @ndigits, 0;            # so even number of entries
  }
  ### @ndigits

  my $xk = 0;
  my $yk = 0;
  my @ydigits;
  my @xdigits;

  for (my $i = $#ndigits >> 1; @ndigits; $i--) {    # high to low
    ### $i
    {
      my $ndigit = pop @ndigits;  # high to low
      $xk ^= $ndigit;
      $ydigits[$i] = ($yk & 1 ? $radix_minus_1-$ndigit : $ndigit);
    }
    {
      my $ndigit = pop @ndigits;
      $yk ^= $ndigit;
      $xdigits[$i] = ($xk & 1 ? $radix_minus_1-$ndigit : $ndigit);
    }
  }
  my $zero = $n*0;
  return ((map {digit_join_lowtohigh($_, $radix, $zero)} \@xdigits, \@ydigits),
          $xk,$yk);
}


sub n_to_xy {
  my ($self, $n) = @_;
  ### PeanoCurve n_to_xy(): $n
  if ($n < 0) {            # negative
    return;
  }
  if (is_infinite($n)) {
    return ($n,$n);
  }

  {
    # ENHANCE-ME: for odd radix the ends join and the direction can be had
    # without a full N+1 calculation
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
    $n = $int; # BigFloat int() gives BigInt, use that
  }

  my ($x,$y) = _n_to_xykk($self,$n);
  return ($x,$y);
}

sub _xykk_to_n {
  my ($self, $x,$y, $offset_xk,$offset_yk) = @_;
  ### PeanoCurve _xykk_to_n(): "$x, $y offset $offset_xk,$offset_yk"

  if (($offset_xk    && ($x-=$offset_xk) < 0)
      || ($offset_yk && ($y-=$offset_yk) < 0)) {
    return;    # offset goes negative
  }

  my $radix = $self->{'radix'};
  my @x = digit_split_lowtohigh ($x, $radix);
  my @y = digit_split_lowtohigh ($y, $radix);

  my $radix_minus_1 = $radix - 1;
  my $xk = 0;
  my $yk = 0;

  my @n;  # stored low to high, generated from high to low
  my $i_high = max($#x,$#y);
  my $npos = 2*$i_high+1;

  foreach my $i (reverse 0 .. $i_high) {  # high to low
    {
      my $digit = $y[$i] || 0;
      if ($yk & 1) {
        $digit = $radix_minus_1 - $digit;  # reverse digit
      }
      $n[$npos--] = $digit;
      $xk ^= $digit;
    }
    {
      my $digit = $x[$i] || 0;
      if ($xk & 1) {
        $digit = $radix_minus_1 - $digit;  # reverse digit
      }
      $n[$npos--] = $digit;
      $yk ^= $digit;
    }
  }
  ### final n: @n
  ### final xkyk: ($xk&1).' '.($yk&1)
  return ((! defined $offset_xk    || ($xk&1) == $offset_xk)
          && (! defined $offset_yk || ($yk&1) == $offset_yk)
          ? (digit_join_lowtohigh (\@n, $radix,
                                   $x*0*$y))  # inherit bignum 0
          : ());
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### PeanoCurve xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);

  if ($x < 0 || $y < 0) { return undef; }
  if (is_infinite($x)) { return $x; }
  if (is_infinite($y)) { return $y; }

  return _xykk_to_n($self, $x,$y);
}

# exact
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

  my ($power, $level) = round_down_pow (max($x2,$y2), $radix);
  if (is_infinite($level)) {
    return (0, $level);
  }

  my $n_power = $power * $power * $radix;
  my $max_x = 0;
  my $max_y = 0;
  my $max_n = 0;
  my $max_xk = 0;
  my $max_yk = 0;

  my $min_x = 0;
  my $min_y = 0;
  my $min_n = 0;
  my $min_xk = 0;
  my $min_yk = 0;

  # l<=c<h doesn't overlap c1<=c<=c2 if
  #     l>c2 or h-1<c1
  #     l>c2 or h<=c1
  # so does overlap if
  #     l<=c2 and h>c1
  #
  my $radix_minus_1 = $radix - 1;
  my $overlap = sub {
    my ($c,$ck,$digit, $c1,$c2) = @_;
    if ($ck & 1) {
      $digit = $radix_minus_1 - $digit;
    }
    ### overlap consider: "inv".($ck&1)."digit=$digit ".($c+$digit*$power)."<=c<".($c+($digit+1)*$power)." cf $c1 to $c2 incl"
    return ($c + $digit*$power <= $c2
            && $c + ($digit+1)*$power > $c1);
  };

  while ($level-- >= 0) {
    ### $power
    ### $n_power
    ### $max_n
    ### $min_n
    {
      my $digit;
      for ($digit = $radix_minus_1; $digit > 0; $digit--) {
        last if &$overlap ($max_y,$max_yk,$digit, $y1,$y2);
      }
      $max_n += $n_power * $digit;
      $max_xk ^= $digit;
      if ($max_yk&1) { $digit = $radix_minus_1 - $digit; }
      $max_y += $power * $digit;
      ### max y digit (complemented): $digit
      ### $max_y
      ### $max_n
    }
    {
      my $digit;
      for ($digit = 0; $digit < $radix_minus_1; $digit++) {
        last if &$overlap ($min_y,$min_yk,$digit, $y1,$y2);
      }
      $min_n += $n_power * $digit;
      $min_xk ^= $digit;
      if ($min_yk&1) { $digit = $radix_minus_1 - $digit; }
      $min_y += $power * $digit;
      ### min y digit (complemented): $digit
      ### $min_y
      ### $min_n
    }

    $n_power = int($n_power/$radix);
    {
      my $digit;
      for ($digit = $radix_minus_1; $digit > 0; $digit--) {
        last if &$overlap ($max_x,$max_xk,$digit, $x1,$x2);
      }
      $max_n += $n_power * $digit;
      $max_yk ^= $digit;
      if ($max_xk&1) { $digit = $radix_minus_1 - $digit; }
      $max_x += $power * $digit;
      ### max x digit (complemented): $digit
      ### $max_x
      ### $max_n
    }
    {
      my $digit;
      for ($digit = 0; $digit < $radix_minus_1; $digit++) {
        last if &$overlap ($min_x,$min_xk,$digit, $x1,$x2);
      }
      $min_n += $n_power * $digit;
      $min_yk ^= $digit;
      if ($min_xk&1) { $digit = $radix_minus_1 - $digit; }
      $min_x += $power * $digit;
      ### min x digit (complemented): $digit
      ### $min_x
      ### $min_n
    }

    $power = int($power/$radix);
    $n_power = int($n_power/$radix);
  }
  ### is: "$min_n at $min_x,$min_y  to  $max_n at $max_x,$max_y"
  return ($min_n, $max_n);
}

#------------------------------------------------------------------------------
# levels

use Math::PlanePath::ZOrderCurve;
*level_to_n_range = \&Math::PlanePath::ZOrderCurve::level_to_n_range;
*n_to_level       = \&Math::PlanePath::ZOrderCurve::n_to_level;

#------------------------------------------------------------------------------
1;
__END__

#    +--+
#    |  |
# +--+--+--+
#    |  |
#    +--+
#
#          +
#          |
#       +--+--+
#       |  |  |
#    +--+--+--+--+
#    |  |  |  |  |
# +--+--+--+--+--+--+
#    |  |  |  |  |
#    +--+--+--+--+
#       |  |  |
#       +--+--+
#          |
#          +

#-----

=for stopwords Giuseppe Peano Peano's there'll eg Sur Une Courbe Qui Remplit Toute Aire Mathematische Annalen Ryde OEIS trit-twiddling ie bignums prepending trit Math-PlanePath versa Online Radix radix Georg representable Mephisto DOI bitwise PeanoDiagonals

=head1 NAME

Math::PlanePath::PeanoCurve -- 3x3 self-similar quadrant traversal

=head1 SYNOPSIS

 use Math::PlanePath::PeanoCurve;
 my $path = Math::PlanePath::PeanoCurve->new;
 my ($x, $y) = $path->n_to_xy (123);

 # or another radix digits ...
 my $path5 = Math::PlanePath::PeanoCurve->new (radix => 5);

=head1 DESCRIPTION

This path is an integer version of the curve described by Peano for filling
a unit square,

=over

Giuseppe Peano, "Sur Une Courbe, Qui Remplit Toute Une Aire Plane",
Mathematische Annalen, volume 36, number 1, 1890, pages 157-160.
DOI 10.1007/BF01199438.
L<https://eudml.org/doc/157489>,
L<https://link.springer.com/article/10.1007/BF01199438>

=back

It traverses a quadrant of the plane one step at a time in a self-similar
3x3 pattern,

       8    60--61--62--63--64--65  78--79--80--...
             |                   |   |
       7    59--58--57  68--67--66  77--76--75
                     |   |                   |
       6    54--55--56  69--70--71--72--73--74
             |
       5    53--52--51  38--37--36--35--34--33
                     |   |                   |
       4    48--49--50  39--40--41  30--31--32
             |                   |   |
       3    47--46--45--44--43--42  29--28--27
                                             |
       2     6---7---8---9--10--11  24--25--26
             |                   |   |
       1     5---4---3  14--13--12  23--22--21
                     |   |                   |
      Y=0    0---1---2  15--16--17--18--19--20

           X=0   1   2   3   4   5   6   7   8   9 ...

The start is an S shape of the nine points N=0 to N=8, and then nine of
those groups are put together in the same S configuration.  The sub-parts
are flipped horizontally and/or vertically to make the starts and ends
adjacent, so 8 is next to 9, 17 next to 18, etc,

    60,61,62 --- 63,64,65     78,79,80
    59,58,57     68,67,55     77,76,75
    54,55,56     69,70,71 --- 72,73,74
     |
     |
    53,52,51     38,37,36 --- 35,34,33
    48,49,50     39,40,41     30,31,32
    47,46,45 --- 44,43,42     29,28,27
                                     |
                                     |
     6,7,8  ----  9,10,11     24,25,26
     3,4,5       12,13,14     23,22,21
     0,1,2       15,16,17 --- 18,19,20

The process repeats, tripling in size each time.

Within a power-of-3 square, 3x3, 9x9, 27x27, 81x81 etc (3^k)x(3^k) at the
origin, all the N values 0 to 3^(2*k)-1 are within the square.  The top
right corner 8, 80, 728, etc is the 3^(2*k)-1 maximum in each.

Because each step is by 1, the distance along the curve between two X,Y
points is the difference in their N values as given by C<xy_to_n()>.

=head2 Radix

The C<radix> parameter can do the calculation in a base other than 3, using
the same kind of direction reversals.  For example radix 5 gives 5x5 groups,

=cut

# math-image --path=PeanoCurve,radix=5 --expression='i<=50?i:0' --output=numbers_dash

=pod

     radix => 5

      4  |  20--21--22--23--24--25--26--27--28--29
         |   |                                   |
      3  |  19--18--17--16--15  34--33--32--31--30
         |                   |   |
      2  |  10--11--12--13--14  35--36--37--38--39
         |   |                                   |
      1  |   9-- 8-- 7-- 6-- 5  44--43--42--41--40
         |                   |   |
     Y=0 |   0-- 1-- 2-- 3-- 4  45--46--47--48--49--50-...
         |
         +----------------------------------------------
           X=0   1   2   3   4   5   6   7   8   9  10

If the radix is even then the ends of each group don't join up.  For example
in radix 4 N=15 isn't next to N=16, nor N=31 to N=32, etc.

=cut

# math-image --path=PeanoCurve,radix=4 --expression='i<=33?i:0' --output=numbers_dash

=pod

     radix => 4

      3  |  15--14--13--12  16--17--18--19
         |               |               |
      2  |   8-- 9--10--11  23--22--21--20
         |   |               |
      1  |   7-- 6-- 5-- 4  24--25--26--27
         |               |               |
     Y=0 |   0-- 1-- 2-- 3  31--30--29--28  32--33-...
         |
         +------------------------------------------
           X=0   1   2   4   5   6   7   8   9  10

Even sizes can be made to join using other patterns, but this module is just
Peano's digit construction.  For joining up in 2x2 groupings see
C<HilbertCurve> (which is essentially the only way to join up in 2x2).  For
bigger groupings there's various ways.

=head2 Unit Square

Peano's original form was for filling a unit square by mapping a number T in
the range 0E<lt>TE<lt>1 to a pair of X,Y coordinates 0E<lt>XE<lt>1 and
0E<lt>YE<lt>1.  The curve is continuous and every such X,Y is reached by
some T, so it fills the unit square.  A unit cube or higher dimension can be
filled similarly by developing three or more coordinates X,Y,Z, etc.  Cantor
had shown a line is equivalent to the plane, Peano's mapping is a continuous
way to do that.

The code here could be pressed into service for a fractional T to X,Y by
multiplying up by a power of 9 to desired precision then dividing X and Y
back by the same power of 3 (perhaps swapping X,Y for which one should be
the first ternary digit).  Note that if T is a binary floating point then a
power of 3 division will round off in general since 1/3 is not exactly
representable.  (See C<HilbertCurve> or C<ZOrderCurve> for binary mappings.)

Sometimes the curve is drawn with line segments crossing unit squares.  See
PeanoDiagonals for that sort of path.

=head2 Power of 3 Patterns

Plotting sequences of values with some connection to ternary digits or
powers of 3 will usually give the most interesting patterns on the Peano
curve.  For example the Mephisto waltz sequence
(L<Math::NumSeq::MephistoWaltz>) makes diamond shapes,

    **   *  ***   *  *  *** **   *** **   *** ** **   *  *
    *  *   ** ** ***   ** ***  *  *   ** ** ***   ** ***
      *** **   *** ** **   *  ***   *  ***   *  *  *** **
     ** ***  *  *   ***  *   ** ** ***  *  *   ***  *   **
      *** **   *** ** **   *  ***   *  ***   *  *  *** **
    *  *   ** ** ***   ** ***  *  *   ** ** ***   ** ***
      *** **   *** ** **   *  ***   *  ***   *  *  *** **
     ** ***  *  *   ***  *   ** ** ***  *  *   ***  *   **
    **   *  ***   *  *  *** **   *** **   *** ** **   *  *
    *  *   ** ** ***   ** ***  *  *   ** ** ***   ** ***
    **   *  ***   *  *  *** **   *** **   *** ** **   *  *
     ** ***  *  *   ***  *   ** ** ***  *  *   ***  *   **
      *** **   *** ** **   *  ***   *  ***   *  *  *** **
     ** ***  *  *   ***  *   ** ** ***  *  *   ***  *   **
    **   *  ***   *  *  *** **   *** **   *** ** **   *  *
     ** ***  *  *   ***  *   ** ** ***  *  *   ***  *   **
      *** **   *** ** **   *  ***   *  ***   *  *  *** **
    *  *   ** ** ***   ** ***  *  *   ** ** ***   ** ***
      *** **   *** ** **   *  ***   *  ***   *  *  *** **
     ** ***  *  *   ***  *   ** ** ***  *  *   ***  *   **
    **   *  ***   *  *  *** **   *** **   *** ** **   *  *
    *  *   ** ** ***   ** ***  *  *   ** ** ***   ** ***
    **   *  ***   *  *  *** **   *** **   *** ** **   *  *
     ** ***  *  *   ***  *   ** ** ***  *  *   ***  *   **
    **   *  ***   *  *  *** **   *** **   *** ** **   *  *
    *  *   ** ** ***   ** ***  *  *   ** ** ***   ** ***
      *** **   *** ** **   *  ***   *  ***   *  *  *** **

This arises from each 3x3 block in the Mephisto waltz being one of two
shapes which are then flipped by the Peano pattern

    * * _                     _ _ *
    * _ _           or        _ * *    (inverse)
    _ _ *                     * * _

    0,0,1, 0,0,1, 1,1,0       1,1,0, 1,1,0, 0,0,1

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::PeanoCurve-E<gt>new ()>

=item C<$path = Math::PlanePath::PeanoCurve-E<gt>new (radix =E<gt> $integer)>

Create and return a new path object.

The optional C<radix> parameter gives the base for digit splitting.  The
default is ternary C<radix =E<gt> 3>.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

Fractional C<$n> give an X,Y position along a straight line between the
integer positions.  Integer positions are always just 1 apart either
horizontally or vertically, so the effect is that the fraction part appears
either added to or subtracted from X or Y.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return the integer point number for coordinates C<$x,$y>.  Each integer N is
considered the centre of a unit square and an C<$x,$y> within that square
returns N.

=item C<($n_lo, $n_hi) = $path-E<gt>rect_to_n_range ($x1,$y1, $x2,$y2)>

Return the range of N values which occur the a rectangle with corners at
C<$x1>,C<$y1> and C<$x2>,C<$y2>.  If the X,Y values are not integers then
the curve is treated as unit squares centred on each integer point and
squares which are partly covered by the given rectangle are included.

The returned range is exact, meaning C<$n_lo> and C<$n_hi> are the smallest
and biggest in the rectangle.

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<(0, $radix**(2*$level) - 1)>.

=back

=head1 FORMULAS

=head2 N to X,Y

Peano's calculation is based on putting base-3 digits of N alternately to X
or Y.  From the high end of N, a digit goes to Y then the next goes to X.
Beginning at an even digit position in N makes the last digit go to X so the
first N=0,1,2 is along the X axis.

At each stage a "complement" state is maintained for X and for Y.  When
complemented, the digit is reversed to S<2 - digit>, so 0,1,2 becomes 2,1,0.
This reverses the direction so points like N=12,13,14 shown above go
leftwards, or groups like 9,10,11 then 12,13,14 then 15,16,17 go downwards.

The complement is calculated by adding the digits from N which went to the
other one of X or Y.  So the X complement is the sum of digits which have
gone to Y so far.  Conversely the Y complement is the sum of digits put
to X.  If the complement sum is odd then the reversal is done.  A bitwise
XOR can be used instead of a sum to accumulate odd/even-ness the same way as
a sum.

When forming the complement state, the original digits from N are added,
before applying any complementing for putting them to X or Y.  If the radix
is odd, like the default 3, then complementing doesn't change it mod 2 so
before or after are the same, but if the radix is even then it's not the
same.

It also works to take the base-3 digits of N from low to high, generating
low to high digits in X and Y.  If an odd digit is put to X then the low
digits of Y so far must be complemented as S<22..22 - Y> (the 22..22 value
being all 2s in base 3, ie. 3^k-1).  Conversely if an odd digit is put to Y
then X must be complemented.  With this approach, the high digit position in
N doesn't have to be found, just peel off digits of N from the low end.  But
the subtract to complement is then more work if using bignums.

=head2 X,Y to N

The X,Y to N calculation can be done by an inverse of either the high to low
or low to high methods above.  In both cases digits are put alternately from
X and Y into N, with complement as necessary.

For the low to high approach, it's not easy to complement just the X digits
in the N constructed so far, but it works to build and complement the X and
Y digits separately then at the end interleave to make the final N.
Complementing is the ternary equivalent of an XOR in binary.  On a ternary
machine maybe some trit-twiddling would do it.

For low to high with even radix, the complementing is also tricky since
changing the accumulated X affects the digits of Y below that, and vice
versa.  What's the rule?  Is it alternate digits which end up complemented?
In any case the current C<xy_to_n()> code goes high to low which is easier,
but means breaking the X,Y inputs into arrays of digits before beginning.

=pod

=head2 N on Axes

N on the X axis is all Y digits 0 in the X,Y to N described above.  This
means N is the digits of X, and then digit 0 or 2 at each Y position
according to odd or even sum of X digits above.  The Y digits are at odd
positions so the 0 or 2 ternary is 0 or 6 for N in base-9.

    N on X axis = 0,1,2, 15,16,17, 18,19,20, 141, ...   (A163480)
          ternary 0,1,2, 120,121,122, 200,201,202, 12020

=cut

# GP-DEFINE  to_ternary(n) = fromdigits(digits(n,3));
# GP-DEFINE  to_base9(n) = fromdigits(digits(n,9));
#
# GP-DEFINE  \\ similar in PeanoCurve-oeis.t
# GP-DEFINE  N_on_X_axis(x) = {
# GP-DEFINE    my(v=digits(x,3),s=Mod(0,2));
# GP-DEFINE    for(i=1,#v, if(s,v[i]+=6); s+=v[i]);
# GP-DEFINE    fromdigits(v,9);
# GP-DEFINE  }
# GP-Test  vector(10,x,x--; N_on_X_axis(x)) == \
# GP-Test    [0,1,2, 15,16,17, 18,19,20, 141]
# GP-Test  vector(10,x,x--; to_ternary(N_on_X_axis(x))) == \
# GP-Test    [0,1,2, 120,121,122, 200,201,202, 12020]
# not in OEIS: 1,2, 120,121,122, 200,201,202, 12020    \\ X in base 3
# vector(10,x, to_base9(N_on_X_axis(x)))
# not in OEIS: 1, 2, 16, 17, 18, 20, 21, 22, 166, 167  \\ N in base 9
#
# my(v=OEIS_samples("A163480")); vector(#v,x,x--; N_on_X_axis(x)) == v
# GP-Test  vector(3^6,x,x--; N_on_X_axis(3*x)) == \
# GP-Test  vector(3^6,x,x--; 9*N_on_X_axis(x) + if(x%2,6))
# GP-Test  matrix(3^6,3,x,r,x--;r--; N_on_X_axis(3*x+r)) == \
# GP-Test  matrix(3^6,3,x,r,x--;r--; 9*N_on_X_axis(x) + r + if(x%2==1,6))

=pod

The Y axis is similar but the X digits are at even positions.

    N on Y axis = 0,5,6, 47,48,53, 54,59,60, 425, ...   (A163481)
          ternary 0,12,20, 1202,1210,1222, 2000,2012,2020, 120202

=cut

# GP-DEFINE  \\ similar in PeanoCurve-oeis.t
# GP-DEFINE  N_on_Y_axis(y) = {
# GP-DEFINE    my(v=digits(y,3),s=Mod(0,2));
# GP-DEFINE    for(i=1,#v, s+=v[i]; v[i] = 3*v[i]+if(s,2));
# GP-DEFINE    fromdigits(v,9);
# GP-DEFINE  }
# GP-Test  vector(10,y,y--; N_on_Y_axis(y)) == \
# GP-Test    [0,5,6, 47,48,53, 54,59,60, 425]
# GP-Test  vector(10,y,y--; to_ternary(N_on_Y_axis(y))) == \
# GP-Test    [0,12,20, 1202,1210,1222, 2000,2012,2020, 120202]
# not in OEIS: 12,20, 1202,1210,1222, 2000,2012,2020, 120202
# vector(10,x, to_base9(N_on_Y_axis(x)))
# not in OEIS: 5, 6, 52, 53, 58, 60, 65, 66, 522, 523
# my(v=OEIS_samples("A163481")); vector(#v,y,y--; N_on_Y_axis(y)) == v

=pod

N on the X=Y diagonal has the ternary digits of position d go to both X and
Y and so both complemented according to sum of digits of d above.  That
transformation within d is the ternary reflected Gray code.

    Gray3(d) = ternary flip 0<->2 when sum of digits above is odd
             = 0,1,2, 5,4,3, 6,7,8, 17, ...          (A128173)
       ternary 0,1,2, 12,11,10, 20,21,22, 122, ...

    N on X=Y diag = ternary Gray3(d) and 0,1,2 -> 0,4,8 base9,
                                         which is 4*digit
                  = 0,4,8, 44,40,36, 72,76,80, 404, ...  (A163343)
            ternary 0,11,22, 1122,1111,1100, 2200,2211,2222, 112222,

=cut

# GP-DEFINE  Gray3(d) = {
# GP-DEFINE    my(v=digits(d,3),s=Mod(0,2));
# GP-DEFINE    for(i=1,#v, if(s,v[i]=2-v[i]); s+=v[i]);
# GP-DEFINE    fromdigits(v,3);
# GP-DEFINE  }
# GP-Test  vector(10,d,d--; Gray3(d)) == \
# GP-Test    [0,1,2, 5,4,3, 6,7,8, 17]
# GP-Test  vector(10,d,d--; to_ternary(Gray3(d))) == \
# GP-Test    [0,1,2, 12,11,10, 20,21,22, 122]
# not in OEIS: 1,2, 12,11,10, 20,21,22, 122
#
# GP-DEFINE  N_on_XY_diagonal(d) = {
# GP-DEFINE    my(v=digits(Gray3(d),3));
# GP-DEFINE    v*=4;
# GP-DEFINE    fromdigits(v,9);
# GP-DEFINE  }
# GP-Test  vector(10,d,d--; N_on_XY_diagonal(d)) == \
# GP-Test    [0,4,8, 44,40,36, 72,76,80, 404]
# GP-Test  vector(10,d,d--; to_ternary(N_on_XY_diagonal(d))) == \
# GP-Test    [0,11,22, 1122,1111,1100, 2200,2211,2222, 112222]
# not in OEIS: 12,20, 1202,1210,1222, 2000,2012,2020, 120202
# vector(10,d, to_base9(N_on_XY_diagonal(d)))  \\ is 4*to_ternary(Gray3)
# not in OEIS: 4, 8, 48, 44, 40, 80, 84, 88, 488, 484

=pod

=head2 N to abs(dX),abs(dY)

The curve goes horizontally or vertically according to the number of
trailing "2" digits when N is written in ternary,

    N trailing 2s   direction     abs(dX)     abs(dY)
    -------------   ---------     -------     -------
      even          horizontal       1           0
      odd           vertical         0           1

    abs(dX) = 1,1,0, 1,1,0, 1,1,1, 1,1,0, 1,1,0, 1,1,1, ...  (A014578)
    abs(dY) = 0,0,1, 0,0,1, 0,0,0, 0,0,1, 0,0,1, 0,0,0, ...  (A182581)

For example N=5 is "12" in ternary has 1 trailing "2" which is odd so the
step from N=5 to N=6 is vertical.

This works because when stepping from N to N+1 a carry propagates through
the trailing 2s to increment the digit above.  Digits go alternately to X or
Y so odd or even trailing 2s put that carry into an X digit or Y digit.

          X Y X Y X
    N   ... 2 2 2 2
    N+1   1 0 0 0 0  carry propagates

=cut

# GP-DEFINE  count_low_2s(n) = valuation(n+1,3);
# GP-DEFINE  N_is_horizontal(N) = count_low_2s(N) % 2 == 0;
# GP-DEFINE  N_is_vertical(N)   = count_low_2s(N) % 2 == 1;
# GP-Test  vector(18,N,N--; N_is_horizontal(N)) == \
# GP-Test    [1,1,0, 1,1,0, 1,1,1, 1,1,0, 1,1,0, 1,1,1]
# GP-Test  vector(18,N,N--; N_is_vertical(N)) == \
# GP-Test    [0,0,1, 0,0,1, 0,0,0, 0,0,1, 0,0,1, 0,0,0]
# vector(100,N, N_is_vertical(N))

=pod

=head2 Rectangle to N Range

An easy over-estimate of the maximum N in a region can be had by going to
the next bigger (3^k)x(3^k) square enclosing the region.  This means the
biggest X or Y rounded up to the next power of 3 (perhaps using C<log()> if
you trust its accuracy), so

    find k with 3^k > max(X,Y)
    N_hi = 3^(2k) - 1

An exact N range can be found by following the "high to low" N to X,Y
procedure above.  Start with the easy over-estimate to find a 3^(2k) ternary
digit position in N bigger than the desired region, then choose a digit
0,1,2 for X, the biggest which overlaps some of the region.  Or if there's
an X complement then the smallest digit is the biggest N, again whichever
overlaps the region.  Then likewise for a digit of Y, etc.

Biggest and smallest N must maintain separate complement states as they
track down different N digits.  A single loop can be used since there's the
same "2k" many digits of N to consider for both.

The N range of any shape can be done this way, not just a rectangle like
C<rect_to_n_range()>.  The procedure only depends on asking whether a
one-third sub-part of X or Y overlaps the target region or not.

=head1 OEIS

This path is in Sloane's Online Encyclopedia of Integer Sequences in several
forms,

=over

L<http://oeis.org/A163528> (etc)

=back

    A163528    X coordinate
    A163529    Y coordinate
    A163530    X+Y coordinate sum
    A163531    X^2+Y^2 square of distance from origin
    A163532    dX, change in X -1,0,1
    A163533    dY, change in Y -1,0,1
    A014578    abs(dX) from n-1 to n, 1=horiz 0=vertical
    A182581    abs(dY) from n-1 to n, 0=horiz 1=vertical
    A163534    direction mod 4 of each step (ENWS)
    A163535    direction mod 4, transposed X,Y
    A163536    turn 0=straight,1=right,2=left
    A163537    turn, transposed X,Y
    A163342    diagonal sums
    A163479    diagonal sums divided by 6

    A163480    N on X axis
    A163481    N on Y axis
    A163343    N on X=Y diagonal, 0,4,8,44,40,36,etc
    A163344    N on X=Y diagonal divided by 4
    A007417    N+1 of positions of horizontals, ternary even trailing 0s
    A145204    N+1 of positions of verticals, ternary odd trailing 0s

    A163332    Peano N <-> ZOrder radix=3 N mapping (self-inverse)
    A163333    with ternary digit swaps before and after

And taking X,Y points by the Diagonals sequence, then the value of the
following sequences is the N of the Peano curve at those positions.

    A163334    numbering by diagonals, from same axis as first step
    A163336    numbering by diagonals, from opposite axis
    A163338    A163334 + 1, Peano starting from N=1
    A163340    A163336 + 1, Peano starting from N=1

C<Math::PlanePath::Diagonals> numbers points from the Y axis down, which is
the opposite axis to the Peano curve first step along the X axis, so a plain
C<Diagonals> -> C<PeanoCurve> is the "opposite axis" form A163336.

These sequences are permutations of the integers since all X,Y positions of
the first quadrant are reached eventually.  The inverses are as follows.
They can be thought of taking X,Y positions in the Peano curve order and
then asking what N the Diagonals would put there.

    A163335    inverse of A163334
    A163337    inverse of A163336
    A163339    inverse of A163338
    A163341    inverse of A163340

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::PeanoDiagonals>,
L<Math::PlanePath::HilbertCurve>,
L<Math::PlanePath::ZOrderCurve>,
L<Math::PlanePath::AR2W2Curve>,
L<Math::PlanePath::BetaOmega>,
L<Math::PlanePath::CincoCurve>,
L<Math::PlanePath::KochelCurve>,
L<Math::PlanePath::WunderlichMeander>

L<Math::PlanePath::KochCurve>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde

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
