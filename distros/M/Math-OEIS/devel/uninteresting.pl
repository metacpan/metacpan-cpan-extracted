#!/usr/bin/perl -w

# Copyright 2016 Kevin Ryde

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
use Math::OEIS::Stripped;

# uncomment this to run the ### lines
use Smart::Comments;

{
  $| = 1;
  my $stripped = Math::OEIS::Stripped->new (use_bigint => 0);
  my $fh = $stripped->fh;
  my $seen = '';
  my $seen_neg = '';
  my $limit = 1_000_000;
  while (defined(my $line = readline $fh)) {
    my ($anum,$values) = $stripped->line_split_anum($line)
      or next;
    if (progress()) { print "$anum\r"; }
    foreach my $value ($stripped->values_split($values)) {
      if ($value >= 0 && $value <= $limit) {
        vec($seen,$value,1) = 1;
      }
      $value = -$value;
      if ($value >= 0 && $value <= $limit) {
        vec($seen_neg,$value,1) = 1;
      }
    }
  }
  foreach my $str ($seen, $seen_neg) {
    foreach my $value (0 .. $limit) {
      if (! vec($str,$value,1)) {
        print "uninteresting $value\n";
        last;
      }
    }
  }
  exit 0;

  my $t;
  sub progress {
    $t ||= 0;
    my $u = time();
    if (int($t/2) != int($u/2)) {
      $t = $u;
      return 1;
    } else {
      return 0;
    }
  }
}
