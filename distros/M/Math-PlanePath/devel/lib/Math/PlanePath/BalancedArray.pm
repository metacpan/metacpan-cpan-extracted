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


package Math::PlanePath::BalancedArray;
use 5.004;
use strict;
use List::Util 'max';

use vars '$VERSION', '@ISA';
$VERSION = 125;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';

use Math::NumSeq::BalancedBinary;

# uncomment this to run the ### lines
#use Smart::Comments;


use constant class_x_negative => 0;
use constant class_y_negative => 0;
use constant xy_is_visited => 1;

sub new {
  my $self = shift->SUPER::new (@_);
  $self->{'seq'} = Math::NumSeq::BalancedBinary->new;
  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### BalancedArray n_to_xy(): $n

  if ($n < 0) { return; }
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

  my $value = $self->{'seq'}->ith($n)||0;
  ### value: sprintf '%#b', $value

  my $x = 0;
  while (($value % 4) == 2) {
    $x++;
    $value -= 2;
    $value /= 4;
  }
  return ($x,
          $value ? $self->{'seq'}->value_to_i($value) : 0);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### BalancedArray xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);
  if ($x < 0 || $y < 0) {
    return undef;
  }
  my $zero = $x * 0 * $y;

  if (is_infinite($x)) { return $x; }
  if (is_infinite($y)) { return $y; }

  my $value = $self->{'seq'}->ith($y) || 0;
  ### value at y: $value

  my $pow = (4+$zero)**$x;
  $value *= $pow;
  $value += 2*($pow-1)/3;

  ### mul: sprintf '%#b', $pow
  ### add: sprintf '%#b', 2*($pow-1)/3
  ### value: sprintf '%#b', $value
### $value
  ### value: ref $value && $value->as_bin

  return $self->{'seq'}->value_to_i($value);
}

# exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### BalancedArray rect_to_n_range(): "$x1,$y1  $x2,$y2"

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

  return (0,
          4**($x2+$y2));


  return ($self->xy_to_n($x1,$y1),    # bottom left
          $self->xy_to_n($x2,$y2));   # top right
}

1;
__END__

