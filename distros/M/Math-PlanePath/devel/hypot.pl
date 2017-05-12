#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

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
use POSIX ();
use Math::PlanePath::Hypot;
use Math::PlanePath::HypotOctant;

{
  # even equivalence
  my $all = Math::PlanePath::HypotOctant->new (points => 'all');
  my $even = Math::PlanePath::HypotOctant->new (points => 'even');
  for (my $n = $all->n_start; $n < 300; $n++) {
    my ($ex,$ey) = $even->n_to_xy($n);
    my ($ax,$ay) = $all->n_to_xy($n);
    my $cx = ($ex+$ey)/2;
    my $cy = ($ex-$ey)/2;
    my $diff = ($cx!=$ax || $cy!=$ay ? ' **' : '');
    print "$n  $ax,$ay  $cx,$cy$diff\n";
  }
  exit 0;
}

{
  my %comb;
  my $limit = 1000;
  my $xlimit = int(sqrt($limit / 2));
  foreach my $x (1 .. $xlimit) {
    foreach my $y (1 .. $x) {
      my $h = $x*$x+$y*$y;
      if ($h <= $limit) {
        $comb{$h} = 1;
      }
    }
  }
  my @all = sort {$a<=>$b} keys %comb;
  print join(',',@all),"\n";
  print "all ",scalar(@all),"\n";
  foreach my $h (keys %comb) {
    foreach my $j (keys %comb) {
      if ($j < $h
          && ($h % $j) == 0
          && is_int(sqrt($h / $j))) {
        delete $comb{$h};
        last;
      }
    }
  }
  my @comb = sort {$a<=>$b} keys %comb;
  print join(',',@comb),"\n";
  print "count ",scalar(@comb),"\n";
  exit 0;

  sub is_int {
    return $_[0] == int $_[0];
  }
}


{
  my @seen_ways;
  for (my $s = 1; $s < 1000; $s++) {
    my $h = $s * $s;
    my @ways;
    for (my $x = 1; $x < $s; $x++) {
      my $y = sqrt($h - $x*$x);
      # if ($y < $x) {
      #   last;
      # }
      if ($x >= $y && $y == int($y)) {
        push @ways, "   $x*$x + $y*$y\n";
      }
    }
    my $num_ways = scalar(@ways);
    $seen_ways[$num_ways]
      ||= $seen_ways[$num_ways] = "$s*$s = $h   $num_ways ways\n" . join('',@ways);
  }
  print grep {defined} @seen_ways;
  exit 0;
}

{
  for (1 .. 1000) {
    Math::PlanePath::Hypot::_extend();
  }
  # $,="\n";
  # print map {$_//'undef'} @Math::PlanePath::Hypot::hypot_to_n;

  exit 0;
}


