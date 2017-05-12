#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012 Kevin Ryde

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

{
  require Math::PlanePath::DivisibleColumns;
  my $path = Math::PlanePath::DivisibleColumns->new;
  $path->xy_to_n(2000,2000);

  foreach my $k (3 .. 1000) {

    # my $total = 0;
    # my $limit = int(sqrt($k));
    # foreach my $i (1 .. $limit) {
    #   $total += int($k/$i);
    # }
    # $total = 2*$total - $limit*$limit;

    my $n = $path->xy_to_n($k,$k);
    my (undef, $nhi) = $path->rect_to_n_range(0,0,$k,$k);
    my $total = Math::PlanePath::DivisibleColumns::_count_divisors_cumulative($k);

    printf "%d %d,%d %d\n", $k, $n,$nhi, $total;
  }
  exit 0;
}
