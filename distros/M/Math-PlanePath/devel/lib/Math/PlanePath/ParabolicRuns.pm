# Copyright 2012, 2013, 2014, 2015, 2016, 2017, 2018 Kevin Ryde

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


package Math::PlanePath::ParabolicRuns;
use 5.004;
use strict;
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 127;
use Math::PlanePath;
@ISA = ('Math::PlanePath');
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_down_pow';

# uncomment this to run the ### lines
#use Smart::Comments;


use constant class_x_negative => 0;
use constant class_y_negative => 0;

sub n_to_xy {
  my ($self, $n) = @_;
  ### ParabolicRuns n_to_xy(): $n

  if ($n < 1) { return; }
  if (is_infinite($n)) { return ($n,$n); }

  $n -= 1;
  my @x;
  for (my $k = 0; ; $k++) {
    $x[$k] = 0;
    for (my $y = $k; $y >= 0; $y--) {
      my $len = $k-$y+1;
      if ($n < $len) {
        return ($x[$y] + $n, $y);
      }
      $x[$y] += $len;
      $n -= $len;
    }
  }
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### ParabolicRuns xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);

  if ($x < 0 || $y < 0) { return undef; }
  if (is_infinite($x)) { return $x; }
  if (is_infinite($y)) { return $y; }

  my $n = 1;
  my @sx;
  for (my $k = 0; ; $k++) {
    $sx[$k] = 0;
    for (my $sy = $k; $sy >= 0; $sy--) {
      my $len = $k-$sy+1;
      if ($y == $sy) {
        if ($x < $len) {
          return ($n + $x);
        }
        $x -= $len;
      }
      $n += $len;
    }
  }
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### ParabolicRuns rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;

  return (1,
          2*($x2+1)*($y2+1)**2);
}

1;
__END__
