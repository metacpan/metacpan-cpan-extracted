#!/usr/bin/perl -w

# Copyright 2013 Kevin Ryde

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
use Math::PlanePath::FourReplicate;

# uncomment this to run the ### lines
#use Smart::Comments;


{
  require Math::BaseCnv;
  my $path = Math::PlanePath::FourReplicate->new;
  foreach my $n (0 .. 2**30) {
    my ($x,$y) = $path->n_to_xy($n);
    my ($n_lo,$n_hi) = $path->rect_to_n_range(0,0,$x,$y);
    if ($n_hi < $n) {
      my $n4 = Math::BaseCnv::cnv($n,10,4);
      my $n_hi4 = Math::BaseCnv::cnv($n_hi,10,4);
      print "n=$n4 outside n_hi=$n_hi4\n";
    }
  }
  exit 0;
}

{
  require Math::PlanePath::FourReplicate;
  my $path = Math::PlanePath::FourReplicate->new;
  my @table;
  my $xmod = 4;
  my $ymod = 4;
  foreach my $n (0 .. 2**8) {
    my ($x,$y) = $path->n_to_xy($n);
    my $mx = $x % $xmod;
    my $my = $y % $ymod;
    my $href = ($table[$mx][$my] ||= {});
    $href->{$n%4} = 1;
  }

  my $width = 3;
  foreach my $my (reverse 0 .. $ymod-1) {
    printf "%2d", $my;
    foreach my $mx (0 .. $xmod-1) {
      my $href = ($table[$mx][$my] ||= {});
      my $str = join(',', keys %$href);
      printf " %*s", $width, $str;
    }
    print "\n";
  }
  print "\n  ";
  foreach my $mx (0 .. $xmod-1) {
    printf " %*s", $width, $mx;
  }
  print "\n";
  exit 0;
}
