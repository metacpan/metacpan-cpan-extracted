#!/usr/bin/perl -w

# Copyright 2011, 2012, 2018 Kevin Ryde

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
use Math::PlanePath::SierpinskiArrowheadCentres;

# uncomment this to run the ### lines
use Smart::Comments;


{
  # turn sequence

  require Math::NumSeq::PlanePathTurn;
  require Math::BaseCnv;
  my $seq = Math::NumSeq::PlanePathTurn->new
    (planepath => 'SierpinskiArrowheadCentres',
     turn_type => 'TTurn6n');
  for (my $n = 1; $n <= 400; $n += 1) {
  # for (my $n = 9; $n <= 400; $n += 9) {
  # for (my $n = 3; $n <= 400; $n += 3) {
    my $value = $seq->ith($n);
    my $n3 = Math::BaseCnv::cnv($n,10,3);
    # my $calc = calc_turnleft($n);
    my $calc = calc_turn6n($n);
    my $diff = ($value == $calc ? "" : " ***");
    printf "%3d %5s  %2d %2d%s\n", $n, $n3, $value, $calc, $diff;
  }

  sub calc_turn6n {
    my ($n) = @_;

    {
      my $flip = ($n%2 ? 1 : -1);
      if (($n%3)==1) {
        return 2*$flip;
      }
      my $ret  = 0;
      if (($n%3)==0) {
        ($ret,$flip) = ($flip,$ret);
        $n--;
      }
      do {
        ($ret,$flip) = ($flip,$ret);
        $n = int($n/3);
      } while (($n%3)==2);

      if (($n % 3) == 1) {
        ($ret,$flip) = ($flip,$ret);
      }
      return $ret;
    }
    {
      my $flip = ($n%2 ? 1 : -1);
      if (($n%3)==1) {
        return 2*$flip;
      }
      my $ret  = 0;
      if (($n%3)==2) {
        ($ret,$flip) = ($flip,$ret);
        $n++;
      }
      do {
        ($ret,$flip) = ($flip,$ret);
        $n = int($n/3);
      } while ($n && ($n%3)==0);

      if (($n % 3) == 1) {
        ($ret,$flip) = ($flip,$ret);
      }
      return $ret;
    }


    {
      my $flip = ($n%2 ? 1 : -1);
      if (($n%3)==1) {
        return 2*$flip;
      }
      my $ret  = 0;
      my $low = $n % 3;      # low 0s or 2s
      do {
        ($ret,$flip) = ($flip,$ret);
        $n = int($n/3);
      } while ($n && ($n%3)==$low);

      if (($n % 3) == 1) {
        ($ret,$flip) = ($flip,$ret);
      }
      return $ret;
    }
  }
  exit 0;
}


