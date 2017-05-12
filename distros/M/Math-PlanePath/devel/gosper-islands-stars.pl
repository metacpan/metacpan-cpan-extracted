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


use 5.005;
use strict;
use POSIX ();
use Math::PlanePath::GosperIslands;

# uncomment this to run the ### lines
use Smart::Comments;

{
  my $path = Math::PlanePath::GosperIslands->new;
  my @rows = ((' ' x 64) x 78);

  my $level = 3;
  my $n_start = 3**$level - 2;
  my $n_end = 3**($level+1) - 2 - 1;

  foreach my $n ($n_start .. $n_end) {
    my ($x, $y) = $path->n_to_xy ($n);
    # $x *= 2;
    $x+= 16;
    $y+= 16;
    substr ($rows[$y], $x,1, '*');
  }
  local $,="\n";
  print reverse @rows;
  exit 0;
}
