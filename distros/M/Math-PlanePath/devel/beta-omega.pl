#!/usr/bin/perl -w

# Copyright 2011, 2012, 2015 Kevin Ryde

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

use 5.004;
use strict;
use Math::PlanePath::Base::Digits 'round_down_pow';

# uncomment this to run the ### lines
use Smart::Comments;

use Math::PlanePath::BetaOmega;
use Math::PlanePath::KochCurve;

{
  require Math::BaseCnv;
  my $path = Math::PlanePath::BetaOmega->new;
  my @values;
  foreach my $x (0 .. 64) {
    my $n = $path->xy_to_n($x,0);
    my $n2 = Math::BaseCnv::cnv($n,10,4);
    printf "%8s\n", $n2;
    push @values, $n;
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values, verbose=>1);
  exit 0;
}

{
  require Math::BaseCnv;
  my $path = Math::PlanePath::BetaOmega->new;
  foreach my $n (0 .. 64) {
    my $n4 = sprintf '%3s', Math::BaseCnv::cnv($n,10,4);

    my ($x,$y) = $path->n_to_xy($n);
    my ($x2,$y2) = $path->n_to_xy($n+1);
    my $dx = $x2-$x;
    my $dy = $y2-$y;
    print "$n4   $dx,$dy\n";
  }
  exit 0;
}

{
  require Math::PlanePath::KochCurve;
  foreach my $y (reverse -16 .. 22) {
    my $y1 = $y;
    my $y2 = $y;
    {
      if ($y2 > 0) {
        # eg y=5 gives 3*5 = 15
        $y2 *= 3;
      } else {
        # eg y=-2 gives 1-3*-2 = 7
        $y2 = 1-3*$y1;
      }

      my ($ylen, $ylevel) = round_down_pow($y2,2);
      ($ylen, $ylevel) = Math::PlanePath::BetaOmega::_y_round_down_len_level($y);
      print "$y   $y2   $ylevel $ylen\n";
    }
  }
  exit 0;
}
