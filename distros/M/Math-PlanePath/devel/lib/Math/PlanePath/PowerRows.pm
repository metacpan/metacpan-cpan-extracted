# Copyright 2013, 2014, 2015, 2016, 2017, 2018, 2019 Kevin Ryde

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


package Math::PlanePath::PowerRows;
use 5.004;
use strict;
#use List::Util 'min', 'max';
*min = \&Math::PlanePath::_min;

use vars '$VERSION', '@ISA';
$VERSION = 128;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_down_pow';


use constant class_y_negative => 0;
use constant n_frac_discontinuity => .5;

use constant parameter_info_array =>
  [ Math::PlanePath::Base::Digits::parameter_info_radix2(),
    { name            => 'align',
      type            => 'enum',
      share_key       => 'align_rl',
      display         => 'Align',
      default         => 'right',
      choices         => ['right', 'left'],
      choices_display => ['Right', 'Left'],
    },
  ];

sub x_minimum {
  my ($self) = @_;
  return ($self->{'align'} eq 'right' ? 0 : undef);
}
sub x_maximum {
  my ($self) = @_;
  return ($self->{'align'} eq 'left' ? 0 : undef);
}

#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);
  $self->{'align'} ||= 'right';
  $self->{'radix'} ||= 2;
  return $self;
}

# Nrow = 1/2 + (r + r + r^2 + ... + r^(depth-1))
#      = 1/2 + (r^depth - 1) / (r-1)
# (N-1/2)*(r-1) = r^depth - 1
# r^depth = (N-1/2)*(r-1) + 1
#         = (2N-1)*(r-1)/2 + 1
# 2Nrow = 1 + 2*(r^depth - 1) / (r-1);
#       = 1 + 2*(pow - 1) / (r-1);
#
sub n_to_xy {
  my ($self, $n) = @_;
  ### PowerRows n_to_xy(): $n

  $n *= 2;
  if ($n < 1) { return; }
  if (is_infinite($n)) { return ($n,$n); }

  my $radix = $self->{'radix'};
  my ($pow, $y) = round_down_pow (($n-1)*($radix-1)/2 + 1,
                                  $radix);
  if ($self->{'align'} eq 'left') {
    $n -= 2*$pow;
  } else {
    $n -= 2;
  }
  return ($n/2 - ($pow-1)/($radix-1), $y);
}

# uncomment this to run the ### lines
# use Smart::Comments;

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### PowerRows xy_to_n(): "$x, $y"

  $y = round_nearest ($y);
  if ($y < 0) {
    ### all Y negative ...
    return undef;
  }

  my $radix = $self->{'radix'};
  my $zero = $x * 0 * $y;
  $y = ($radix + $zero) ** $y;
  ### Y power: $y

  $x = round_nearest ($x);
  if ($self->{'align'} eq 'left') {
    if ($x > 0 || $x <= -$y) {
      ### X outside 0 to -R^Y ...
      return undef;
    }
    $x += $y;
    $x -= 1;
  } else {
    if ($x < 0 || $x >= $y) {
      ### X outside 0 to R^Y ...
      return undef;
    }
  }

  # Nrow = 1 + (r^depth - 1) / (r-1)
  return $x + ($y-1)/($radix-1) + 1;
}

# Nrow = 1 + (r^Y - 1) / (r-1)
# Nlast = Nrow(Y+1)-1
#       = 1 + (r^(Y+1) - 1) / (r-1) - 1
#       = (r^(Y+1) - 1) / (r-1)
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### PowerRows rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;

  if ($y2 < 0
      || ($self->{'align'} eq 'right' ? $x2 < 0 : $x1 > 0)) {
    ### all outside ...
    return (1, 0);
  }

  my $radix = $self->{'radix'};
  my $zero = $x1 * 0 * $x2 * $y1 * $y2;
  return (1,
          (($radix + $zero) ** ($y2+1) - 1) / ($radix-1))
}

1;
__END__
