#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

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


# Usage: perl alternate-paper-dxdy.pl
#

use 5.010;
use strict;

# uncomment this to run the ### lines
#use Smart::Comments;

{
  my @pending_state;
  foreach my $rot (0,1,2,3) {
    foreach my $oddpos (0,1) {
      push @pending_state, make_state (bit => 0,
                                       lowerbit => 0,
                                       rot => $rot,
                                       oddpos => $oddpos,
                                       nextturn => 0);
    }
  }
  my $count = 0;
  my @seen_state;
  my $depth = 1;
  foreach my $state (@pending_state) {
    $seen_state[$state] = $depth;
  }
  while (@pending_state) {
    my @new_pending_state;
    foreach my $state (@pending_state) {
      $count++;
      ### consider state: $state

      foreach my $bit (0 .. 1) {
        my $next_state = $next_state[$state+$bit];
        if (! $seen_state[$next_state]) {
          $seen_state[$next_state] = $depth;
          push @new_pending_state, $next_state;
          ### push: "$next_state  depth $depth"
        }
      }
      $depth++;
    }
    @pending_state = @new_pending_state;
  }
  for (my $state = 0; $state < @next_state; $state += 2) {
    $seen_state[$state] ||= '-';
    my $state_string = state_string($state);
    print "# used state $state   depth $seen_state[$state]  $state_string\n";
  }
  print "used state count $count\n";
}

exit 0;
