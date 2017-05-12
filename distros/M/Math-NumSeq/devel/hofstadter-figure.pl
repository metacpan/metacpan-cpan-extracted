#!/usr/bin/perl

# Copyright 2010, 2011, 2012 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
#use Smart::Comments;

{
  foreach my $start (-2 .. 10) {
    my $value = $start;
    my $inc = 1;
    my $prev_inc = 0;
    my @next_inc = (-1);
    for (;;) {
      $next_inc[2 + $value] = -1;
      do {
        $inc++;
      } while ($next_inc[2 + $inc]);
      $next_inc[2 + $prev_inc] = $inc;
      if ($inc < $value) {
        last;
      }
      $value += $inc;
      $prev_inc = $inc;
    }
    $, = ',';
    print "$start: ";
    print map {$_//'undef'} @next_inc;
    print "\n";
  }
  exit 0;
}
