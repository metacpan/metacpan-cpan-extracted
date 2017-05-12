# Copyright 2013, 2014, 2015, 2016 Kevin Ryde

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


package Math::PlanePath::WythoffDifference;
use 5.004;
use strict;
use List::Util 'max';

use vars '$VERSION', '@ISA';
$VERSION = 124;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';

# uncomment this to run the ### lines
# use Smart::Comments;


use constant class_x_negative => 0;
use constant class_y_negative => 0;
use constant xy_is_visited => 1;

use Math::PlanePath::WythoffArray;
my $wythoff = Math::PlanePath::WythoffArray->new;

sub n_to_xy {
  my ($self, $n) = @_;
  ### WythoffDifference n_to_xy(): $n

  if ($n < 1) { return; }
  if (is_infinite($n) || $n == 0) { return ($n,$n); }

  {
    # fractions on straight line ?
    my $int = int($n);
    if ($n != $int) {
      my $frac = $n - $int;  # inherit possible BigFloat/BigRat
      my ($x1,$y1) = $self->n_to_xy($int);
      my ($x2,$y2) = $self->n_to_xy($int+1);
      my $dx = $x2-$x1;
      my $dy = $y2-$y1;
      return ($frac*$dx + $x1, $frac*$dy + $y1);
    }
    $n = $int;
  }

  # f1+f0 > i
  # f0 > i-f1
  # check i-f1 as the stopping point, so that if i=UV_MAX then won't
  # overflow a UV trying to get to f1>=i
  #
  my @fibs;
  {
    my $f0 = ($n * 0);  # inherit bignum 0
    my $f1 = $f0 + 1;   # inherit bignum 1
    while ($f0 <= $n-$f1) {
      ($f1,$f0) = ($f1+$f0,$f1);
      push @fibs, $f1;      # starting $fibs[0]=1
    }
  }
  ### @fibs

  my $orig_n = $n;

  # indices into fib[] which are the Fibonaccis adding up to $n
  my @indices;
  for (my $i = $#fibs; $i >= 0; $i--) {
    ### at: "n=$n f=".$fibs[$i]
    if ($n >= $fibs[$i]) {
      push @indices, $i;
      $n -= $fibs[$i];
      ### sub: "$fibs[$i] to n=$n"
      --$i;
    }
  }
  ### @indices

  my $y = 0;
  my $shift;
  my $x;
  my $low = $indices[-1];
  if ($low % 2) {
    # odd trailing zeros
    $x = ($low+1)/2;
    $shift = $low + 2;
    pop @indices;
  } else {
    # even trailing zeros
    $x = 0;
    $shift = 1;
    if ($low == 0) {
      pop @indices;
    } else {
      $y = -1;
    }
  }

  foreach my $i (@indices) {
    ### y add: "ishift=".($i-$shift)." fib=".$fibs[$i-$shift]
    $y += $fibs[$i-$shift];
  }
  ### $y
  return ($x, $y);
}

# 6 | 11 28  73 191 500
# 5 |  9 23  60 157 411
# 4 |  8 20  52 136 356
# 3 |  6 15  39 102 267
# 2 |  4 10  26  68 178
# 1 |  3  7  18  47 123
# 0 |  1  2   5  13  34
#   +-------------------
#      0  1   2   3   4

# 9 | 100100 10001010 1000101000 100010100000 10001010000000
# 8 | 100001 10000010 1000001000 100000100000 10000010000000
# 7 |  10101  1010010  101001000  10100100000  1010010000000
# 6 |  10100  1001010  100101000  10010100000  1001010000000
# 5 |  10001  1000010  100001000  10000100000  1000010000000
# 4 |  10000   101010   10101000   1010100000   101010000000
# 3 |   1001   100010   10001000   1000100000   100010000000
# 2 |    101    10010    1001000    100100000    10010000000
# 1 |    100     1010     101000     10100000     1010000000
# 0 |      1       10       1000       100000       10000000
#   +--------------------------------------------------------
#          0        1          2            3              4

sub xy_to_n {
  my ($self, $x, $y) = @_;

  $x = round_nearest ($x);
  if ($x == 0) {
    my $n1 = $wythoff->xy_to_n(1,$y);
    if ($n1) {
      $n1 -= $wythoff->xy_to_n(0,$y);
    }
    return $n1;
  }
  return $wythoff->xy_to_n(2*$x-1,$y);
}

# exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### WythoffDifference rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;

  if ($x2 < 0 || $y2 < 0) {
    ### all outside first quadrant ...
    return (1, 0);
  }

  # bottom left into first quadrant
  if ($x1 < 0) { $x1 *= 0; }
  if ($y1 < 0) { $y1 *= 0; }

  return ($self->xy_to_n($x1,$y1),    # bottom left
          $self->xy_to_n($x2,$y2));   # top right
}

1;
__END__

