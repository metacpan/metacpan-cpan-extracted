# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018 Kevin Ryde

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


# math-image --path=PyramidReplicate --lines --scale=10
# math-image --path=PyramidReplicate --all --output=numbers_dash --size=80x50

package Math::PlanePath::PyramidReplicate;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 127;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_down_pow';

# uncomment this to run the ### lines
#use Devel::Comments;


use constant n_start => 0;

#  4 3 2
#  5 0 1
#  6 7 8
#
my @digit_to_x = (0,1,0,-1,  -2,-3,-2,-1,  0,-1, 0, 1, 2,1,2,3);
my @digit_to_y = (0,0,1, 0,   1, 1, 0, 1, -1,-1,-2,-1, 1,1,0,1);

sub n_to_xy {
  my ($self, $n) = @_;
  ### PyramidReplicate n_to_xy(): $n

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

  my $bx = 1;
  my $by = 1;

  while ($n) {
    my $digit = $n % 16;
    $n = int($n/16);
    ### at: "$x,$y"
    ### $digit

    $x += $digit_to_x[$digit] * $bx;
    $y += $digit_to_y[$digit] * $by;
    $bx *= 6;
    $by *= 4;
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
  ### PyramidReplicate xy_to_n(): "$x, $y"

  return undef;

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
  ### PyramidReplicate rect_to_n_range(): "$x1,$y1  $x2,$y2"

  my $max = abs(round_nearest($x1));
  foreach ($y1, $x2, $y2) {
    my $m = abs(round_nearest($_));
    if ($m > $max) { $max = $m }
  }
  my ($len,$level) = round_down_pow (2*($max||1)-1, 3);
  return (0, 9*$len*$len - 1);  # 9^level-1
}

1;
__END__

=for stopwords eg Ryde Math-PlanePath aabbccdd

=head1 NAME

Math::PlanePath::PyramidReplicate -- replicating squares

=head1 SYNOPSIS

 use Math::PlanePath::PyramidReplicate;
 my $path = Math::PlanePath::PyramidReplicate->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This is a self-similar replicating pyramid shape made from 4 points each,

                                               4

                                               3

                                               2

                                               1

                                           <- Y=0

                                              -1

                                              -2

                                              -3

                                              -4

                     ^
    -4  -3  -2  -1  X=0  1   2   3   4

The base shape is the initial N=0 to N=8 section,

      +---+
      | 2 |
  +---+---+---+
  | 3 | 0 | 1 |
  +---+---+---+

It then repeats inverted to make a similar shape but upside-down,

        +---+---+---+---+---+---+---+
        | 5   4   7 | 2 |13  12  15 |
        +---+   +---+   +---+   +---+
            | 6 | 3   0   1 |14 |
            +---+---+---+---+---+
                | 9   8  11 |
                +---+   +---+
                    |10 |
                    +---+

=head2 Level Ranges

A given replication extends to ...

    Nlevel = 4^level - 1
    - ... <= X <= ...
    - ... <= Y <= ...

=head2 Complex Base

This pattern corresponds to expressing a complex integer X+i*Y in base b=...

    X+Yi = a[n]*b^n + ... + a[2]*b^2 + a[1]*b + a[0]

using complex digits a[i] encoded in N in integer base 4 ...

    a[i] digit     N digit
    ----------     -------
         0            0
         1            1
         i            2
        -1            3

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for the behaviour common to all path
classes.

=over 4

=item C<$path = Math::PlanePath::PyramidReplicate-E<gt>new ()>

Create and return a new path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

=back

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::CornerReplicate>,
L<Math::PlanePath::SquareReplicate>,
L<Math::PlanePath::LTiling>,
L<Math::PlanePath::GosperReplicate>,
L<Math::PlanePath::QuintetReplicate>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018 Kevin Ryde

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
