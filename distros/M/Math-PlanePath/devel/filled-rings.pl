#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

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
use Math::PlanePath::FilledRings;

# uncomment this to run the ### lines
use Smart::Comments;


{
  # average diff step 
  my $path = Math::PlanePath::FilledRings->new;
  my $prev_n = $path->xy_to_n(0,0);
  my $prev_loop = $path->xy_to_n(0,0);
  my $diff_total = 0;
  my $diff_count = 0;
  foreach my $x (1 .. 500) {
    my $n = $path->xy_to_n($x,0);
    my $loop = $n - $prev_n;
    my $diff = $loop - $prev_loop;
    #printf "%2d %3d  %3d %3d\n", $x, $n, $loop, $diff;

    $prev_n = $n;
    $prev_loop = $loop;

    $diff_total += $diff;
    $diff_count++;
  }
  my $avg = $diff_total/$diff_count;
  my $sqavg = $avg*$avg;
  print "diff average $avg squared $sqavg\n";
  exit 0;
}
