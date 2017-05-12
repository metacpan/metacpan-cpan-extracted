# Copyright 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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


# math-image --path=SquareReplicate --lines --scale=10
# math-image --path=SquareReplicate --all --output=numbers_dash --size=80x50


package Math::PlanePath::SquareReplicate;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 124;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_down_pow',
  'round_up_pow',
  'digit_split_lowtohigh';

# uncomment this to run the ### lines
#use Devel::Comments;


use constant n_start => 0;
use constant xy_is_visited => 1;
use constant x_negative_at_n => 4;
use constant y_negative_at_n => 6;
use constant ddiffxy_maximum => 1;
use constant dir_maximum_dxdy => (0,-1); # South


#------------------------------------------------------------------------------
#  4 3 2
#  5 0 1
#  6 7 8
#
my @digit_to_x = (0,1, 1,0,-1, -1, -1,0,1);
my @digit_to_y = (0,0, 1,1,1,   0, -1,-1,-1);

sub n_to_xy {
  my ($self, $n) = @_;
  ### SquareReplicate n_to_xy(): $n

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

  my $x = my $y = ($n * 0);  # inherit bignum 0
  my $len = ($x + 1);        # inherit bignum 1

  foreach my $digit (digit_split_lowtohigh($n,9)) {
    ### at: "$x,$y  digit=$digit"

    $x += $digit_to_x[$digit] * $len;
    $y += $digit_to_y[$digit] * $len;
    $len *= 3;
  }

  ### final: "$x,$y"
  return ($x,$y);
}

#   mod    digit
#  5 3 4   4 3 2     (x mod 3) + 3*(y mod 3)
#  2 0 1   5 0 1
#  8 6 7   6 7 8
#
my @mod_to_digit = (0,1,5, 3,2,4, 7,8,6);

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### SquareReplicate xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);

  my ($len,$level_limit);
  {
    my $xa = abs($x);
    my $ya = abs($y);
    ($len,$level_limit) = round_down_pow (2*($xa > $ya ? $xa : $ya) || 1, 3);
    ### $level_limit
    ### $len
  }
  $level_limit += 2;
  if (is_infinite($level_limit)) {
    return $level_limit;
  }

  my $n = ($x * 0 * $y);  # inherit bignum 0
  my $power = ($n + 1);   # inherit bignum 1
  while ($x || $y) {
    if ($level_limit-- < 0) {
      ### oops, level limit reached ...
      return undef;
    }
    my $m = ($x % 3) + 3*($y % 3);
    my $digit = $mod_to_digit[$m];
    ### at: "$x,$y  m=$m digit=$digit"

    $x -= $digit_to_x[$digit];
    $y -= $digit_to_y[$digit];
    ### subtract: "$digit_to_x[$digit],$digit_to_y[$digit] to $x,$y"

    ### assert: $x % 3 == 0
    ### assert: $y % 3 == 0
    $x /= 3;
    $y /= 3;
    $n += $digit * $power;
    $power *= 9;
  }
  return $n;
}

# level   N    Xmax
#   1   9^1-1    1
#   2   9^2-1    1+3
#   3   9^3-1    1+3+9
# X <= 3^0+3^1+...+3^(level-1)
# X <= 1 + 3^0+3^1+...+3^(level-1)
# X <= (3^level - 1)/2
# 2*X+1 <= 3^level
# level >= log3(2*X+1)
#
# X < 1  +  3^0+3^1+...+3^(level-1)
# X < 1 + (3^level - 1)/2
# (3^level - 1)/2 > X-1
# 3^level - 1 > 2*X-2
# 3^level > 2*X-1
#
# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### SquareReplicate rect_to_n_range(): "$x1,$y1  $x2,$y2"

  my $max = abs(round_nearest($x1));
  foreach ($y1, $x2, $y2) {
    my $m = abs(round_nearest($_));
    if ($m > $max) { $max = $m }
  }
  my ($pow) = round_down_pow (2*($max||1)-1, 3);
  return (0, 9*$pow*$pow - 1);  # 9^level-1
}

#-----------------------------------------------------------------------------
# level_to_n_range()

# shared by Math::PlanePath::WunderlichMeander and more
sub level_to_n_range {
  my ($self, $level) = @_;
  return (0, 9**$level - 1);
}
sub n_to_level {
  my ($self, $n) = @_;
  if ($n < 0) { return undef; }
  if (is_infinite($n)) { return $n; }
  $n = round_nearest($n);
  my ($pow, $exp) = round_up_pow ($n+1, 9);
  return $exp;
}

#-----------------------------------------------------------------------------
1;
__END__

=for stopwords eg Ryde Math-PlanePath aabbccdd

=head1 NAME

Math::PlanePath::SquareReplicate -- replicating squares

=head1 SYNOPSIS

 use Math::PlanePath::SquareReplicate;
 my $path = Math::PlanePath::SquareReplicate->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path is a self-similar replicating square,

    40--39--38  31--30--29  22--21--20         4
     |       |   |       |   |       |
    41  36--37  32  27--28  23  18--19         3
     |           |           |
    42--43--44  33--34--35  24--25--26         2

    49--48--47   4-- 3-- 2  13--12--11         1
     |       |   |       |   |       |
    50  45--46   5   0-- 1  14   9--10     <- Y=0
     |           |           |
    51--52--53   6-- 7-- 8  15--16--17        -1

    58--57--56  67--66--65  76--75--74        -2
     |       |   |       |   |       |
    59  54--55  68  63--64  77  72--73        -3
     |           |           |
    60--61--62  69--70--71  78--79--80        -4

                     ^
    -4  -3  -2  -1  X=0  1   2   3   4

The base shape is the initial N=0 to N=8 section,

   4  3  2
   5  0  1
   6  7  8

It then repeats with 3x3 blocks arranged in the same pattern, then 9x9
blocks, etc.

    36 --- 27 --- 18
     |             |
     |             |
    45      0 ---  9
     |              
     |              
    54 --- 63 --- 72

The replication means that the values on the X axis are those using only
digits 0,1,5 in base 9.  Those to the right have a high 1 digit and those to
the left a high 5 digit.  These digits are the values in the initial N=0 to
N=8 figure which fall on the X axis.

Similarly on the Y axis digits 0,3,7 in base 9, or the leading diagonal X=Y
0,2,6 and opposite diagonal 0,4,8.  The opposite diagonal digits 0,4,8 are
00,11,22 in base 3, so is all the values in base 3 with doubled digits
aabbccdd, etc.

=head2 Level Ranges

A given replication extends to

    Nlevel = 9^level - 1
    - (3^level - 1) <= X <= (3^level - 1)
    - (3^level - 1) <= Y <= (3^level - 1)

=head2 Complex Base

This pattern corresponds to expressing a complex integer X+i*Y in base b=3,

    X+Yi = a[n]*b^n + ... + a[2]*b^2 + a[1]*b + a[0]

using complex digits a[i] encoded in N in integer base 9,

    a[i] digit     N digit
    ----------     -------
          0           0
          1           1
        i+1           2
        i             3
        i-1           4
         -1           5
       -i-1           6
       -i             7
       -i+1           8

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::SquareReplicate-E<gt>new ()>

Create and return a new path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<(0, 9**$level - 1)>.

=back

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::CornerReplicate>,
L<Math::PlanePath::LTiling>,
L<Math::PlanePath::GosperReplicate>,
L<Math::PlanePath::QuintetReplicate>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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
