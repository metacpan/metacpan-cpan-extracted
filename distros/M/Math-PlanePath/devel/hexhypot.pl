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


use 5.010;
use strict;
use warnings;
use Smart::Comments;

{
  my $x = 2;
  my $y = 0;
  ### initial: "$x,$y"
  foreach (1 .. 6) {
    # ($x,$y) = (($x+3*$y)/-2,  # 120
    #            ($x-$y)/2);

    # ($x,$y) = ((3*$y-$x)/2,   # 2x120
    #            ($x+$y)/-2);

    # ($x,$y) = (($x-3*$y)/2,   # 60
    #            ($x+$y)/2);

    ($x,$y) = (($x+3*$y)/2,   # -60
               ($y-$x)/2);

    ### to: "$x,$y"
  }
  exit 0;
}

{
  my @seen;
  foreach my $x (2 .. 20) {
    my $ylimit = $x/3;
    for (my $y = ($x&1); $y <= $ylimit; $y+=2) {
      my $h = 3*$y*$y + $x*$x;
      if ($seen[$h]) {
        print "duplicate $x,$y: $seen[$h]\n";
      } else {
        $seen[$h] = "$x,$y";
      }
    }
  }

  my @hypots = map {defined $seen[$_] ? $_ : ()} 0 .. $#seen;
  @hypots = sort {$a<=>$b} @hypots;
  $,=',';
  print @hypots,"\n";
  exit 0;
}
