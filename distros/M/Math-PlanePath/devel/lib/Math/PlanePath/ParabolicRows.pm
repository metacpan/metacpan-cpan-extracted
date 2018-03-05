# Copyright 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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


# A056520 1,2,6,15 (n+2)*(2*n^2-n+3)/6 starting n=0
#

package Math::PlanePath::ParabolicRows;
use 5.004;
use strict;
#use List::Util 'min', 'max';
*min = \&Math::PlanePath::_min;

use vars '$VERSION', '@ISA';
$VERSION = 126;
use Math::PlanePath;
@ISA = ('Math::PlanePath');
*_sqrtint = \&Math::PlanePath::_sqrtint;

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';

# uncomment this to run the ### lines
#use Smart::Comments;


use constant class_x_negative => 0;
use constant class_y_negative => 0;
use constant n_frac_discontinuity => .5;

# first N in row, counting from N=1 at X=0,Y=0
# [ 0,1,2,3 ],
# [ 1,2,6,15 ]
# N = (1/3 y^3 + 1/2 y^2 + 1/6 y + 1)
#   = (2 y^3 + 3 y^2 + y + 1) / 6
#   = ((2*y + 3)*y + 1)*y/6 + 1 + $x;

sub n_to_xy {
  my ($self, $n) = @_;
  ### ParabolicRows n_to_xy(): $n

  if ($n < 1) { return; }
  if (is_infinite($n)) { return ($n,$n); }

  my $int = int($n);
  $n -= $int;
  if (2*$n >= 1) {  # if frac>=0.5
    $int += 1;
    $n -= 1;
  }
  ### $int
  ### $n

  my $yhi = _sqrtint($int) + 2;
  my $y = 0;
  for (;;) {
    my $ymid = int(($yhi+$y)/2);
    ### at: "y=$y   ymid=$ymid   yhi=$yhi"

    if ($ymid == $y) {
      ### assert: $y+1 == $yhi
      ### found, row starting: ((2*$y + 3)*$y + 1)*$y/6 + 1
      ### $y
      ### x: $n + ($int - ((2*$y + 3)*$y + 1)*$y/6)
      return ($n + ($int - ((2*$y + 3)*$y + 1)*$y/6 - 1),
              $y);
    }
    ### compare: ((2*$ymid + 3)*$ymid + 1)*$ymid/6 + 1
    if ($int >= ((2*$ymid + 3)*$ymid + 1)*$ymid/6 + 1) {
      $y = $ymid;
    } else {
      $yhi = $ymid;
    }
  }


  # my $y = 0; 
  # for (;;) {
  #   my $max = ($y+1)**2;
  #   if ($int <= $max) {
  #     return ($n+$int-1,$y);
  #   }
  #   $y++;
  #   $int -= $max;
  # }
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### ParabolicRows xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);
  if ($y < 0) {
    return undef;
  }
  my $ysquared = ($y+1)*($y+1);
  if ($x >= $ysquared) {
    return undef;
  }

  return ((2*$y + 3)*$y + 1)*$y/6 + 1 + $x;
}

# exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### ParabolicRows rect_to_n_range(): "$x1,$y1  $x2,$y2"

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

  if ($y1 < 0) {
    $y1 *= 0;
  }
  if ($x1 < 0) {
    $x1 *= 0;
  } elsif ($x1 >= ($y1+1)*($y1+1)) {
    $y1 = _sqrt_ceil($x1+1);
    ### increase y1 to put x1 in range: $y1
  }

  ### assert: defined $self->xy_to_n ($x1, $y1)
  ### assert: defined $self->xy_to_n (min($x2,($y2+2)*$y2), $y2)

  # monotonic increasing in $x and $y directions, so this is exact
  return ($self->xy_to_n ($x1, $y1),
          $self->xy_to_n (min($x2,($y2+2)*$y2), $y2));
}

sub _sqrt_ceil {
  my ($n) = @_;
  my $sqrt = _sqrtint($n);
  if ($sqrt*$sqrt < $n) {
    $sqrt += 1;
  }
  return $sqrt;
}

1;
__END__
