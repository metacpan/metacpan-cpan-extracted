#!/usr/bin/perl -w

# Copyright 2013, 2014 Kevin Ryde

# This file is part of Math-PlanePath-Toothpick.
#
# Math-PlanePath-Toothpick is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Math-PlanePath-Toothpick is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath-Toothpick.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use List::Util 'min', 'max';
use List::MoreUtils 'uniq';
use Math::PlanePath::Base::Digits 'round_down_pow';

# uncomment this to run the ### lines
use Smart::Comments;


{
  # depth_to_n
  # 5*2^n, 6*2^n
  require Math::PlanePath::HTree;
  my $path = Math::PlanePath::HTree->new;
  my @values;
  my $want_depth = 0;
  foreach my $n ($path->n_start .. 99999) {
    my $depth = $path->tree_n_to_depth($n);
    if ($depth == $want_depth) {
      my $got_n = $path->tree_depth_to_n($depth);
      printf "%d   %d %b   %d\n", $depth, $n,$n, $got_n;
      push @values, $n;
      $want_depth++;
      last if $want_depth >= 15;
    }
  }
  shift @values;
  shift @values;
  shift @values;
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values);
  exit 0;
}

{
  # row widths
  require Math::PlanePath::HTree;
  my $path = Math::PlanePath::HTree->new;
  my @count;
  my $depth_limit = 10;
  foreach my $n ($path->n_start .. $path->tree_depth_to_n_end($depth_limit)) {
    my $depth = $path->tree_n_to_depth($n);
    if ($depth <= $depth_limit) {
      $count[$depth]++;
    }
  }
  ### @count
  my @values;
  foreach my $depth (0 .. $depth_limit) {
    push @values, $count[$depth];
    print "$depth  $count[$depth]\n";
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values);
  exit 0;
}

{
  # count 0-bits below high 1-bit, not in OEIS
  require Math::PlanePath::HTree;
  my $path = Math::PlanePath::HTree->new;
  my @values;
  foreach my $n ($path->n_start+3 .. 30) {
    push @values, $path->tree_n_to_subheight(2*$n+1);
  }
  @values = reverse @values;
  print join(',',@values),"\n";
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values);
  exit 0;
}

{
  require Math::PlanePath::HTree;
  my $path = Math::PlanePath::HTree->new;
  foreach my $n ($path->n_start .. 256) {
    my $parent = $path->tree_n_parent($n) // 'undef';
    my @children = $path->tree_n_children($n);

    my $subheight = $path->tree_n_to_subheight($n) // 'inf';
    my $depth = $path->tree_n_to_depth($n);
    my $ns = $path->tree_depth_to_n($depth);
    my $ne = $path->tree_depth_to_n_end($depth);
    print "$n d=$depth,$ns-$ne  $parent  c=",join(',',@children),
      "  subh=$subheight\n";
  }
  exit 0;
}

{
  require Math::PlanePath::HTree;
  my $path = Math::PlanePath::HTree->new;
  foreach my $y (reverse -5 .. 5) {
    foreach my $x (-5 .. 5) {
      my $n = $path->xy_to_n($x,$y) // '.';
      printf "%3s", $n;
    }
    print "\n";
  }
  exit 0;
}

