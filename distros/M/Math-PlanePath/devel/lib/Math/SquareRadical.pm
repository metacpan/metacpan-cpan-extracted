# Copyright 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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


package Math::SquareRadical;
use 5.004;
use strict;
use Carp 'croak';
use Scalar::Util 'blessed';

use vars '$VERSION', '@ISA';
$VERSION = 125;

# uncomment this to run the ### lines
use Smart::Comments;


use overload
  '""' => \&stringize;
  '0+' => \&numize;
  'bool' => \&bool;
  # '<=>' => \&spaceship;
  'neg' => \&neg;
  '+' => \&add,
  '-' => \&sub,
  '*' => \&mul,
  fallback => 1;

sub new {
  my ($class, $int, $factor, $root) = @_;
  $factor ||= 0;
  $root ||= 0;
  unless ($root >= 0) {
    croak "Negative root for SquareRadical";
  }
  return bless [ $int, $factor, $root ], $class;
}

sub bool {
  my ($self) = @_;
  ### bool(): @$self
  return $self->[0] || $self->[1];
}
sub numize {
  my ($self) = @_;
  ### numize(): @$self
  return ($self->[0] + $self->[1]*sqrt($self->[2])) + 0;
}
sub stringize {
  my ($self) = @_;
  ### stringize(): @$self
  my $factor = $self->[1];
  if ($factor == 0) {
    return "$self->[0]";
  } else {
    return "$self->[0]".($factor >= 0 ? '+' : '').$factor."*sqrt($self->[2])";
  }
}

# a+b*sqrt(c) <=> d
# b*sqrt(c) <=> d-a
# b^2*c <=> (d-a)^2     # if both same sign
#
# a+b*sqrt(c) <=> d+e*sqrt(f)
# (a-d)+b*sqrt(c) <=> e*sqrt(f)
# (a-d)^2 + 2*(a-d)*b*sqrt(c) + b^2*c <=> e^2*f
# 2*(a-d)*b*sqrt(c) <=> e^2*f - b^2*c - (a-d)^2
# 4*(a-d)^2*b^2*c <=> (e^2*f - b^2*c - (a-d)^2)^2
#
sub spaceship {
  my ($self, $other) = @_;
  ### spaceship() ...
  if (blessed($other) && $other->isa('Math::SquareRadical')) {
    if ($self->[1] != $other->[1]) {
      croak "Different roots";
    }
    return bless [ $self->[0] + $other->[0],
                   $self->[1] + $other->[1] ];
  } else {
    my $factor = $self->[1];
    my $rhs = ($other - $self->[0]);
    return (($rhs < 0) <=> ($factor < 0)
            || (($factor*$factor*$self->[2] <=> $rhs*$rhs)
                * ($rhs < 0 ? -1 : 1)));
  }
}

sub neg {
  my ($self) = @_;
  ### neg(): @$self
  return $self->new(- $self->[0],
                    - $self->[1],
                    $self->[2]);
}

# c = g^2*f
# a+b*sqrt(c) + d+e*sqrt(f)
# = a+d + b*g*sqrt(f) + e*sqrt(f)
# = (a+d) + (b*g + e)*sqrt(f)
#
sub add {
  my ($self, $other) = @_;
  ### add(): @$self
  if (blessed($other) && $other->isa('Math::SquareRadical')) {
    my $root1 = $self->[2];
    my $root2 = $other->[2];
    if ($root1 % $root2 == 0) {
      $self->new($self->[0] + $other->[0],
                 ($root1/$root2)*$self->[1] + $other->[1],
                 $root2);
    } elsif ($root1 % $root2 == 0) {
      $self->new($self->[0] + $other->[0],
                 ($root1/$root2)*$self->[1] + $other->[1],
                 $root2);
    } else {
      croak "Different roots";
    }
  } else {
    return $self->new($self->[0] + $other, $self->[1], $self->[2]);
  }
}
# sub sub {
#   my ($self, $other, $swap) = @_;
#   my $ret;
#   if (blessed($other) && $other->isa('Math::SquareRadical')) {
#     if ($self->[1] != $other->[1]) {
#       croak "Different roots";
#     }
#     $ret = bless [ $self->[0] - $other->[0],
#                    $self->[1] - $other->[1] ];
#   } else {
#     $ret = bless [ $self->[0] - $other, $self->[1] ];
#   }
#   if ($swap) {
#     $ret->[0] = - $ret->[0];
#     $ret->[1] = - $ret->[1];
#   }
#   return $ret;
# }

# (a + b*sqrt(c))*(d + e*sqrt(f))
# = a*d + b*d*sqrt(c) + a*e*sqrt(f) + b*e*sqrt(c*f)
# if c=g^2*f
# = a*d + b*d*g*sqrt(f) + a*e*sqrt(f) + b*e*g*f
sub mul {
  my ($self, $other) = @_;
  ### mul(): @$self
  if (blessed($other) && $other->isa('Math::SquareRadical')) {
    my $root1 = $self->[2];
    my $root2 = $other->[2];
    if ($root1 % $root2 == 0) {
      my $g2 = $root1/$root2;
      my $g = sqrt($g2);
      if ($g*$g == $g2) {
        $self->new($self->[0] + $other->[0],
                   $g*$self->[1] + $other->[1],
                   $root2);
      }
    } elsif ($root2 % $root1 == 0) {
      my $g2 = $root2/$root1;
      my $g = sqrt($g2);
      if ($g*$g == $g2) {
        $self->new($self->[0] + $other->[0],
                   $self->[1] + $g*$other->[1],
                   $root1);
      }
    } else {
      croak "Different roots";
    }
  } else {
    return $self->new($self->[0] * $other, $self->[1] * $other, $self->[2]);
  }
}
