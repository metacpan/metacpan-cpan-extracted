#!/usr/bin/perl -w

# Copyright 2011, 2013 Kevin Ryde

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
use List::Util 'sum';
use Math::PlanePath::KochCurve;


{
  # A056832 All a(n) = 1 or 2; a(1) = 1; get next 2^k terms by repeating
  # first 2^k terms and changing last element so sum of first 2^(k+1) terms
  # is odd.
  # 
  # Is lowest non-zero base4 digit(n) 1,3->a(n)=1 2->a(n)=2.
  # a(2^k) flips 1<->2 each time for low non-zero flipping 1<->2.
  # a(2^k) always flips because odd sum becomes even on duplicating.
  #
  my @a = (1);
  for my $i (1 .. 6) {
    push @a, @a;
    unless (sum(@a) & 1) {
      $a[-1] = 3-$a[-1];  # 2<->1
      print "i=$i flip last\n";
    }
    print @a,"\n";
  }

  foreach my $i (1 .. 64) {
    my $d = base4_lowest_nonzero_digit($i);
    if ($d != 2) { $d = 1; }
    print $d;
  }
  print "\n";

  exit 0;
}

sub base4_lowest_nonzero_digit {
  my ($n) = @_;
  while (($n & 3) == 0) {
    $n >>= 2;
    if ($n == 0) { die "oops, no nonzero digits at all"; } 
  }
  return $n & 3;
}
sub base4_lowest_non3_digit {
  my ($n) = @_;
  while (($n & 3) == 3) {
    $n >>= 2;
  }
  return $n & 3;
}


{
  my $path = Math::PlanePath::KochCurve->new;
  foreach my $n (0 .. 16) {
    my ($x,$y) = $path->n_to_xy($n);
    my $rot = n_to_total_turn($n);
    print "$n  $x,$y  $rot\n";
  }
  print "\n";
  exit 0;

  sub n_to_total_turn {
    my ($n) = @_;
    my $rot = 0;
    while ($n) {
      if (($n % 4) == 1) {
        $rot++;
      } elsif (($n % 4) == 2) {
        $rot --;
      }
      $n = int($n/4);
    }
    return $rot;
  }
}

