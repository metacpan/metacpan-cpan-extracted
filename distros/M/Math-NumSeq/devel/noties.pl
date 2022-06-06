#!/usr/bin/perl -w

# Copyright 2020 Kevin Ryde

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
use List::Util 'sum';

# uncomment this to run the ### lines
# use Smart::Comments;


{
  # 1,2 scores
  # 4,12,42,148,540,1990,7434,27972,106008,403764
  # A135489 basketball
  #
  # 1,2,3 scores
  # A135490 basketball with 3-point
  #
  # 1,6 Aussie Rules
  # not in OEIS: 4,12,48,172,688,2576,10290,39284,156600,604336,
  #
  # 1,4,6 League
  # 6,30,180,1002,5922,33864,199266,1153926,6785028,39573654,

  my %counts = (0 => 1);
  my @possible_scores = (1,2,3);
  @possible_scores = (1,6);
  @possible_scores = (1,4,6);
  @possible_scores = (1,2);
  my $nons = 0;

  foreach my $n (1 .. 10) {
    my %new_counts;
    while (my ($from,$count) = each %counts) {
      ### $from
      ### $count
      foreach my $score (@possible_scores) {
        foreach my $delta ($score,-$score) {
          my $to = $from + $delta;
          ### $to
          if ($to != 0) {
            $new_counts{$to} += $count;
          }
        }
      }
    }
    %counts = %new_counts;
    my $total = sum(values %counts);
    # $total = 4**$n - $total;
    # print "$total,";
    # $nons += 4**$n - $total;
    # print "$nons,";
  }
  exit;
}
