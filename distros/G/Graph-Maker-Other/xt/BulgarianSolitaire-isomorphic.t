#!/usr/bin/perl -w

# Copyright 2017, 2018, 2019 Kevin Ryde
#
# This file is part of Graph-Maker-Other.
#
# This file is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# This file is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Maker-Other.  See the file COPYING.  If not, see
# <http://www.gnu.org/licenses/>.

use strict;
use 5.004;
use Test;
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Graph::Maker::BulgarianSolitaire;

use lib 'devel/lib';
use MyGraphs;

plan tests => 39;


sub triangular {
  my ($t) = @_;
  return ($t*($t+1)) >> 1;
}
# sub is_triangular {
#   my ($n) = @_;
#   foreach my $t (0 .. $n) {
#     if (triangular($t) == $n) { return 1; }
#   }
#   return 0;
# }
# sub gcd {
#   my ($x,$y) = @_;
#   for (;;) {
#     if ($x > $y) { ($x,$y) = ($y,$x); }
#     if ($x==0 || $y <= 1) { return 


#------------------------------------------------------------------------------
# Girth

#    1,1,2,1,3,3,1,4,2,4,1,5,5,5,5,1,6,3,2,3,6,ok 1
#1,1,1,1,2,1,1,1,3,1,1,2,1,4,1,1,1,1,1,5,1,ok 1
use Math::PlanePath::GcdRationals;

{
  my $N = 1;
  foreach my $t (0 .. 5) {
    foreach my $r (reverse 0 .. $t-1) {
      ok (triangular($t) - $r,  $N);
      my $graph = Graph::Maker->new('Bulgarian_solitaire', N=>$N);
      my $girth = MyGraphs::Graph_girth($graph);
      ok ($girth,
          $t / Math::PlanePath::GcdRationals::_gcd($t,$r),
          "girth N=$N");
      # print "$N,";
      # print "$girth,";
      # print additive_order_mod_n($t,$r),",";
      # print $t/Math::PlanePath::GcdRationals::_gcd($t,$r),",";
      $N++;
    }
  }
}


#------------------------------------------------------------------------------
# compositions append isomorphic to prepend

{
  foreach my $N (0 .. 7) {
    my $append = Graph::Maker->new('Bulgarian_solitaire',
                                   N=>$N, compositions=>'append');
    my $prepend = Graph::Maker->new('Bulgarian_solitaire',
                                    N=>$N, compositions=>'prepend');
    ok (MyGraphs::Graph_is_isomorphic($append, $prepend), 1);
  }
}


#------------------------------------------------------------------------------
# POD HOG Shown

# N=16 numbpart=231 most <= 255
# vector(17,n,numbpart(n))
{
  my %shown = (
               1 => 1310,
               2 => 19655,
               3 => 32234,
               4 => 330,
               5 => 820,
               6 => 32254,
               7 => 32380,
               8 => 32256,
               9 => 32382,
               10 => 32258,
               11 => 32384,
               12 => 32386,
               13 => 32388,
               14 => 32390,
               15 => 32260,
               16 => 32392,

               '1,append' => 1310,
               '2,append' => 19655,
               '3,append' => 594,
              );
  my $extras = 0;
  foreach my $N (1 .. 8) {
    foreach my $compositions (0, 'append') {
      my $graph = Graph::Maker->new('Bulgarian_solitaire',
                                    N => $N,
                                    compositions => $compositions);
      my $key = "$N" . ($compositions ? ",$compositions" : "");
      my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
      $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
      if (my $id = $shown{$key}) {
        MyGraphs::hog_compare($id, $g6_str);
      } else {
        if (MyGraphs::hog_grep($g6_str)) {
          MyTestHelpers::diag ("HOG got $key, not shown in POD");
          MyTestHelpers::diag ($g6_str);
          MyGraphs::Graph_view($graph);
          $extras++
        }
      }
    }
  }
  ok ($extras, 0);
}


#------------------------------------------------------------------------------
exit 0;
