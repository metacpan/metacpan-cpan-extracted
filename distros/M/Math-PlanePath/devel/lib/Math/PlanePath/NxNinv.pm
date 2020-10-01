# Copyright 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019 Kevin Ryde

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


# A072732
# A072733 inverse
# A072736 X coord
# A072737 Y coord
#
# A072734
# A072740 X coord
# A072741 Y coord


package Math::PlanePath::NxNinv;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 128;
use Math::PlanePath;
@ISA = ('Math::PlanePath');
*_sqrtint = \&Math::PlanePath::_sqrtint;

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';

# uncomment this to run the ### lines
#use Smart::Comments;


use constant n_start => 0;
use constant class_x_negative => 0;
use constant class_y_negative => 0;

sub n_to_xy {
  my ($self, $n) = @_;
  ### NxN n_to_xy(): $n

  if ($n < 0) { return; }
  if (is_infinite($n)) { return ($n,$n); }

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

  # d = [   0,  1, 2, 3,  4 ]
  # n = [   0,  1, 3, 6, 10 ]
  # N = (d+1)*d/2
  # d = (-1 + sqrt(8*$n+1))/2
  #
  my $d = int( (_sqrtint(8*$n+1) - 1) / 2 );
  $n -= $d*($d+1)/2;
  ### $d
  ### $n

  my $x = $d-$n;  # downwards
  my $y = $n;     # upwards
  my $diff = $x-$y;

  ### diagonals xy: "$x, $y  diff=$diff"

  if ($x <= $y) {
    my $h = int($x/2);
    return ($h,
            $h + ($x%2) + 2*($y - 2*$h - ($x%2)));
  } else {
    my $h = int($y/2);
    return (1 + $h + ($y%2) + 2*($x-1 - 2*$h - ($y%2)),
            $h);
  }
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### NxN xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);
  if ($x < 0 || $y < 0) {
    return undef;
  }

  my $diff = $x-$y;
  if ($diff <= 0) {
    ($x,$y) = (2*$x + ($diff % 2),
               2*$x + int((1-$diff)/2));
  } else {
    ### pos diff, use y ...
    ($x,$y) = (2*($y+1) - 1 + int($diff/2),
               2*$y + (($diff+1) % 2));
  }
  return (($x+$y)**2 + $x+3*$y)/2;
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### NxN rect_to_n_range(): "$x1,$y1  $x2,$y2"

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

  return (0, $self->xy_to_n($x2,0));
  return (0, $self->xy_to_n($x2,$y2));
}

1;
__END__
