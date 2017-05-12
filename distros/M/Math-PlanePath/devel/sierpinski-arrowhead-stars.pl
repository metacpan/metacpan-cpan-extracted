#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

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
use POSIX ();
use Math::PlanePath::SierpinskiArrowhead;

# uncomment this to run the ### lines
use Smart::Comments;

{
  my $path = Math::PlanePath::SierpinskiArrowhead->new;
  my @rows = ((' ' x 79) x 64);
  foreach my $n (0 .. 3 * 3**4) {
    my ($x, $y) = $path->n_to_xy ($n);
    $x += 32;
    substr ($rows[$y], $x,1, '*');
  }
  local $,="\n";
  print reverse @rows;
  exit 0;
}

{
  my @rows = ((' ' x 64) x 32);
  foreach my $p (0 .. 31) {
    foreach my $q (0 .. 31) {
      next if ($p & $q);

      my $x = $p-$q;
      my $y = $p+$q;
      next if ($y >= @rows);
      $x += 32;
      substr ($rows[$y], $x,1, '*');
    }
  }
  local $,="\n";
  print reverse @rows;
  exit 0;
}
