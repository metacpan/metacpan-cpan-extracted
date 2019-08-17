# works, worth having separately ?

# alternating diagonals when even radix ?



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


# math-image --path=PeanoVertices --all --output=numbers
# math-image --path=PeanoVertices,radix=5 --lines
#


package Math::PlanePath::PeanoVertices;
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
  'round_down_pow',
  'digit_split_lowtohigh';

use Math::PlanePath::PeanoCurve;

# uncomment this to run the ### lines
# use Smart::Comments;


use constant n_start => 0;
use constant class_x_negative => 0;
use constant class_y_negative => 1;

use constant parameter_info_array =>
  [ { name      => 'radix',
      share_key => 'radix_3',
      display   => 'Radix',
      type      => 'integer',
      minimum   => 2,
      default   => 3,
      width     => 3,
    } ];

sub new {
  my $self = shift->SUPER::new(@_);
  $self->{'radix'} ||= 3;
  $self->{'peano'} = Math::PlanePath::PeanoCurve->new (radix => $self->{'radix'});
  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### PeanoVertices n_to_xy(): $n

  if ($n < 0) { return; }
  if (is_infinite($n)) { return ($n,$n); }

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

  my ($x,$y) = $self->{'peano'}->n_to_xy($n)
    or return;
  if ($x % 2) {
    if ($y % 2) {
      $x += 1;
      $y += 1;
    } else {
      $x -= 0;
      $y += 1;
    }
  } else {
    if ($y % 2) {
      $x += 1;
      $y -= 0;
    } else {
      $x -= 0;
      $y -= 0;
    }
  }

  ($x,$y) = (($y+$x)/2, ($y-$x)/2);
  return ($x, $y);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### PeanoVertices xy_to_n(): "$x, $y"

    return undef;

  $x = round_nearest ($x);
  $y = round_nearest ($y);

  if ($x < 0 || $y < 0) {
    return undef;
  }
  if (is_infinite($x)) {
    return $x;
  }
  if (is_infinite($y)) {
    return $y;
  }

}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;

  return (0, 1000);

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

  my ($power, $level) = round_down_pow (max($x2,$y2)*$radix/2, $radix);
  if (is_infinite($level)) {
    return (0, $level);
  }
  return (0, 2*$power*$power - 1);
}

1;
__END__
