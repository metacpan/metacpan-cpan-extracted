#!/usr/bin/perl -w

# Copyright 2013, 2014 Kevin Ryde

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


use 5.004;
use strict;
use Math::PlanePath::WythoffLines;

{
  foreach my $shift (-3 .. 17) {
    my $path = Math::PlanePath::WythoffLines->new (shift => $shift);
    my $x_minimum = $path->x_minimum;
    my $y_minimum = $path->y_minimum;
    my $m = Math::PlanePath::WythoffLines::_calc_minimum($shift);
    printf "%2d  %4d    %4d %4d\n", $shift, $m, $x_minimum, $y_minimum;
  }
  exit 0;
}

{
  my @values;
  for (my $shift = 8; $shift < 28; $shift += 2) {
    push @values, Math::PlanePath::WythoffLines::_calc_minimum($shift);
  }
  print join(',',@values),"\n";
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array=>\@values);
  exit 0;
}
