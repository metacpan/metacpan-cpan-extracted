# Copyright 2013, 2014, 2015, 2016, 2017, 2018 Kevin Ryde

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


# A134561 triangle T(n,k) = k-th number whose Zeckendorf has exactly n terms

# 4180 5777 6387 6620 6709 6743 6756 6761 6763 6764 8361
# 1596 2206 2439 2528 2562 2575 2580 2582 2583 3193 3426
#  609  842  931  965  978  983  985  986 1219 1308 1342
#  232  321  355  368  373  375  376  465  499  512  517
#   88  122  135  140  142  143  177  190  195  197  198
#   33   46   51   53   54   67   72   74   75   80   82
#   12   17   19   20   25   27   28   30   31   32   38
#    4    6    7    9   10   11   14   15   16   18   22
#    1    2    3    5    8   13   21   34   55   89  144

# Y=1  Fibonacci
# Y=2  A095096

# X=1  first with Y many bits is Zeck    101010101
#      A027941 Fib(2n+1)-1
# X=2  second with Y many bits is Zeck  1001010101   high 1, low 10101
#      A005592 F(2n+1)+F(2n-1)-1
# X=3  third with Y many bits is  Zeck  1010010101
#      A005592 F(2n+1)+F(2n-1)-1
# X=4  fourth with Y many bits is Zeck  1010100101

package Math::PlanePath::ZeckendorfTerms;
use 5.004;
use strict;
use List::Util 'max';

use vars '$VERSION', '@ISA';
$VERSION = 127;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';

# uncomment this to run the ### lines
# use Smart::Comments;


use constant class_x_negative => 0;
use constant class_y_negative => 0;
use constant y_minimum => 1;
use constant x_minimum => 1;


use Math::NumSeq::FibbinaryBitCount;
my $fbc = Math::NumSeq::FibbinaryBitCount->new;

my $next_n = 1;
my @n_to_x;
my @n_to_y;
my @yx_to_n;

sub _extend {
  my ($self) = @_;
  my $n = $next_n++;
  my $y = $fbc->ith($n);
  my $row = ($yx_to_n[$y] ||= []);
  my $x = scalar(@$row) || 1;
  $row->[$x] = $n;
  $n_to_x[$n] = $x;
  $n_to_y[$n] = $y;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### ZeckendorfTerms n_to_xy(): $n

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

  my $y = $fbc->ith($n);
  while ($next_n <= $n) {
    _extend($self);
  }
  ### $self
  return ($n_to_x[$n], $n_to_y[$n]);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### ZeckendorfTerms xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);

  if ($x < 1 || $y < 1) { return undef; }
  if (is_infinite($x)) { return $x; }
  if (is_infinite($y)) { return $y; }

  for (;;) {
    if (defined (my $n = $yx_to_n[$y][$x])) {
      return $n;
    }
    _extend($self);
  }
}

sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### ZeckendorfTerms rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;

  return (1, 1000);

  # increasing horiziontal and vertical
  return (1, $self->xy_to_n($x2,$y2));
}

1;
__END__

=cut

# math-image  --path=ZeckendorfTerms --output=numbers --all --size=60x14

=pod
