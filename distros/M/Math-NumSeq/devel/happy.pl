#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

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
use List::Util 'max';

{
  # long cycles
  foreach my $radix (2 .. 200) {
    my $max_steps = 0;
    my @max_seen;
    foreach my $start (2 .. 100) {
      my $steps = 0;
      my %seen;
      my @seen = ($start);
      my $i = $start;
      for (;;) {
        my $sum = 0;
        while ($i) {
          my $digit = ($i % $radix);
          $sum += $digit * $digit;
          $i = int($i/$radix);
        }
        $i = $sum;
        push @seen, $i;
        $steps++;

        if ($i == $start) {
          if ($steps > $max_steps) {
            $max_steps = $steps;
            @max_seen = @seen;
          }
          last;
        }
        if ($seen{$i}) {
          last;
        }
        $seen{$i} = 1;
      }
    }
    print "$radix  $max_steps  ",join(',',@max_seen),"\n";
  }
  exit 0;
}
