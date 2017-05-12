#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use POSIX 'floor';
use List::Util 'min', 'max';
use Math::PlanePath::GreekKeySpiral;

# uncomment this to run the ### lines
use Smart::Comments;

{
  {
    package Math::PlanePath::GreekKeySpiral;
    sub new {
      my $self = shift->SUPER::new (@_);

      my $turns = $self->{'turns'};
      if (! defined $turns) {
        $turns = 2;
      } elsif ($turns < 0) {
      }
      $self->{'turns'} = $turns;

      $self->{'centre_x'} = int($turns/2);
      $self->{'centre_y'} = int(($turns+1)/2);

      $self->{'midpoint'} = ($turns+1)*$turns/2;

      return $self;
    }
  }
  sub _n_part_to_xy {
    my ($self, $n) = @_;
    ### _n_part_to_xy(): $n


    # if ($rot & 2) {
    #   $y = -$y;
    # }
    # if ($d & 1) {
    #   $x = -$x;
    # }
    #
    #   my $d = int((sqrt(-8*$n-7) + 1) / 2);
    #   $x = $n;
    #   $y = 0;
    # } elsif (($n -= 1) < 0) {
    #   ### centre ...
    #   $x =  + $n;
    #   $y = $self->{'centre_y'};
    #   $rot = $self->{'turns'};
    # } else {
    #   $rot = $d;
    #   $x = $n;
    #   $y = 0;
    # }
  }

  my $turns = 6;
  my $self = Math::PlanePath::GreekKeySpiral->new (turns => $turns);
  ### $self
  foreach my $n (# 20 .. ($turns+1)**2
                 0, 6, 11, 15, 18, 20, 21,
                 21.25,
                 21.75,
                  22, 23, 25, 28, 32, 37, 43, 49
                ) {
    my $nn = $n;
    my $n = $n;
    my $rot = $self->{'turns'};

    my $centre_x = $self->{'centre_x'};
    my $centre_y = $self->{'centre_y'};
    if (($n -= $self->{'midpoint'}) <= 0) {
      $n = -$n;
      $rot += 0;
      $centre_x += 1;
    } elsif ($n < 1) {
      $rot -= 1;
      $centre_x += 1;
    } else {
      $n -= 1;
      $rot += 2;
    }

    my $d = int((sqrt(8*$n + 1) + 1) / 2);
    $n -= $d*($d-1)/2;

    my $half = int($d/2);
    my $x = $half - $n;
    my $y = $n*0 - $half;
    if (($d % 4) == 2) {
      $x -= 1;
    }
    if (($d % 4) == 3) {
      $y -= 1;
    }

    $rot -= $d;
    if ($rot & 2) {
      $x = -$x;
      $y = -$y;
    }
    if ($rot & 1) {
      ($x,$y) = (-$y,$x);
    }
    $x += $centre_x;
    $y += $centre_y;

    $rot &= 3;
    print "$nn  $d,$n,rot=$rot   $x,$y\n";
  }
  exit 0;
}
