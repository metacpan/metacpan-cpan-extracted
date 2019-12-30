#!/usr/bin/perl -w

# Copyright 2018, 2019 Kevin Ryde
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

use Graph::Maker::KnightGrid;

use File::Spec;
use lib File::Spec->catdir('devel','lib');
use MyGraphs;

plan tests => 62;


# $x,$y are arrayrefs of same length.
# Return the number of positions where $x->[$i] != $y->[$i].
sub arefs_num_diffs {
  my ($x,$y) = @_;
  $#$x==$#$y or die;
  return scalar(grep {$x->[$_] != $y->[$_]} 0 .. $#$x)
}
ok (arefs_num_diffs([],[]), 0);
ok (arefs_num_diffs([1,9],[9,1]), 2);
ok (arefs_num_diffs([1,9,5],[1,9,3]), 1);
ok (arefs_num_diffs([5,1,9],[3,1,9]), 1);

# make_aref_diffs($aref0, $aref1, ...)
# Each $arefN is an arrayref of integers.  All are the same length.
# Return an undirected Graph.pm of vertices 0..$#_ with edges between those
# $arefN which differ in one position.
#
sub make_aref_diffs {
  require Graph;
  my $graph = Graph->new (undirected => 1);
  $graph->add_vertices(0 .. $#_);
  foreach my $i (0 .. $#_) {
    foreach my $j ($i+1 .. $#_) {
      if (arefs_num_diffs($_[$i],$_[$j]) == 1) {
        $graph->add_edge($i,$j);
      }
    }
  }
  return $graph;
}

#------------------------------------------------------------------------------
# Unlabelled Trees - Lexmin

{
  # N=4 Vpar Lexmin Vectors Differing One Place
  # https://hog.grinvin.org/ViewGraphInfo.action?id=32190

  # canonical: HAA?PKy
  my @lexmin_forests_4 = ([0, 1, 2, 3],   # 0
                          [0, 1, 2, 2],
                          [0, 1, 1, 2],
                          [0, 0, 1, 3],
                          [0, 1, 1, 1],
                          [0, 0, 1, 1],
                          [0, 0, 1, 2],
                          [0, 0, 0, 1],
                          [0, 0, 0, 0]);  # 8
  ok (scalar(@lexmin_forests_4), 9);

  my $graph = make_aref_diffs (@lexmin_forests_4);
  ok (scalar($graph->vertices), 9);
  my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
  $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
  ok ($g6_str, "HAA?PKy\n");

  ok (join(',',map{$graph->degree($_)} 0..$#lexmin_forests_4),
      '1,2,3,2,2,4,3,2,1',
      'lexmin forests 4 degrees');

  ok ($graph->degree(0), 1);
  ok ($graph->degree(8), 1);

  MyGraphs::hog_compare(32190, $g6_str);
}

{
  # N=5 Vpar Lexmin Vectors Differing One Place
  # https://hog.grinvin.org/ViewGraphInfo.action?id=32188

  # canonical: S???@@???_@??g_C?AGO@@`??KoGcOaO_
  my @lexmin_forests_5 = ([0, 1, 2, 3, 4],   # 0
                          [0, 1, 2, 3, 3],
                          [0, 1, 2, 2, 3],
                          [0, 1, 1, 2, 4],
                          [0, 0, 1, 3, 4],   # 4
                          [0, 1, 2, 2, 2],
                          [0, 1, 1, 2, 2],

                          [0, 0, 1, 3, 3],   # 7
                          [0, 1, 1, 2, 3],
                          [0, 1, 1, 1, 2],
                          [0, 0, 1, 1, 3],   # 10
                          [0, 0, 1, 2, 3],   # 11
                          [0, 0, 0, 1, 4],
                          [0, 1, 1, 1, 1],
                          [0, 0, 1, 1, 1],
                          [0, 0, 1, 1, 2],
                          [0, 0, 0, 1, 1],
                          [0, 0, 0, 1, 2],
                          [0, 0, 0, 0, 1],
                          [0, 0, 0, 0, 0]);  # 0
  ok (scalar(@lexmin_forests_5), 20);

  my $graph = make_aref_diffs (@lexmin_forests_5);
  ok (scalar($graph->vertices), 20);
  my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
  $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
  ok ($g6_str, "S???\@\@???_\@??g_C?AGO\@\@`??KoGcOaO_\n");

  ok (join(',',map{$graph->degree($_)} 0..$#lexmin_forests_5),
      '1,2,3,2,1,2,4,3,4,3,4,3,2,2,4,4,4,3,2,1',
      'lexmin forests 5 degrees');

  ok ($graph->degree(0), 1);
  ok ($graph->degree(4), 1);
  ok ($graph->degree(19), 1);
  ok ($graph->has_edge(4,7), 1);
  ok ($graph->degree(7), 3);

  MyGraphs::hog_compare(32188, $g6_str);
}


#------------------------------------------------------------------------------
# Unlabelled Trees - Premax

{
  # N=4 Vpar Premax Vectors Differing One Place
  # https://hog.grinvin.org/ViewGraphInfo.action?id=32194

  # canonical: H@BQPS^
  my @premax_forests_4 = ([0, 1, 2, 3],
                          [0, 1, 2, 2],
                          [0, 1, 2, 1],
                          [0, 1, 2, 0],
                          [0, 1, 1, 1],
                          [0, 1, 1, 0],
                          [0, 1, 0, 3],
                          [0, 1, 0, 0],    # 7
                          [0, 0, 0, 0]);   # 8

  ok (scalar(@premax_forests_4), 9);

  my $graph = make_aref_diffs (@premax_forests_4);
  ok (scalar($graph->vertices), 9);
  my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
  $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
  ok ($g6_str, "H\@BQPS^\n");

 MyGraphs::hog_compare(32194, $g6_str);

  ok (join(',',map{$graph->degree($_)} 0..$#premax_forests_4),
      '4,3,4,5,2,3,2,4,1',
      'premax forests 5 degrees');

  ok (MyGraphs::Graph_is_clique($graph, 0,1,2,3), 1);

  # degree=4 three of
  ok (join(',',grep{$graph->degree($_)==4} 0..$#premax_forests_4),
      '0,2,7',  'premax forests 4 degree 4s');
  ok (!! $graph->has_edge(8,7), 1);

  # Hamiltonian path 8 to anywhere except neighbour v=7 or v=4
  foreach my $start (0 .. $#premax_forests_4) {
    ok (!! MyGraphs::Graph_is_Hamiltonian($graph, type=>'path', start=>$start),
        $start!=0 && $start!=7,
        "Hamiltonian path start $start");
  }
}

{
  # N=5 Vpar Premax Vectors Differing One Place
  # https://hog.grinvin.org/ViewGraphInfo.action?id=32192

  # canonical: S?G???CE?aWA@_@GCK?DDAOW?\GESaCE{
  my @premax_forests_5 = ([0, 1, 2, 3, 4],  # 0
                          [0, 1, 2, 3, 3],
                          [0, 1, 2, 3, 2],
                          [0, 1, 2, 3, 1],
                          [0, 1, 2, 3, 0],  # 4

                          [0, 1, 2, 2, 2],
                          [0, 1, 2, 2, 1],
                          [0, 1, 2, 2, 0],
                          [0, 1, 2, 1, 4],
                          [0, 1, 2, 1, 1],
                          [0, 1, 2, 1, 0],
                          [0, 1, 2, 0, 4],
                          [0, 1, 2, 0, 0],
                          [0, 1, 1, 1, 1],
                          [0, 1, 1, 1, 0],
                          [0, 1, 1, 0, 4],
                          [0, 1, 1, 0, 0],
                          [0, 1, 0, 3, 0],
                          [0, 1, 0, 0, 0],
                          [0, 0, 0, 0, 0]);

  ok (scalar(@premax_forests_5), 20);

  my $graph = make_aref_diffs (@premax_forests_5);
  ok (scalar($graph->vertices), 20);
  my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
  $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
  ok ($g6_str, "S?G???CE?aWA\@_\@GCK?DDAOW?\\GESaCE{\n");

  MyGraphs::hog_compare(32192, $g6_str);

  ok (join(',',map{$graph->degree($_)} 0..$#premax_forests_5),
      '6,4,5,6,8,3,4,5,4,5,6,4,6,2,3,2,4,2,4,1',
      'premax forests 5 degrees');

  ok (MyGraphs::Graph_is_clique($graph, 0,1,2,3,4), 1);

  # degree=8 at 4 only
  ok (join(',',grep{$graph->degree($_)==8} 0..$#premax_forests_5),
      '4',  'premax forests 5 degree 8s');
  ok ($graph->has_edge(19,18), 1);

  # Hamiltonian path 19 to anywhere except 4 or 18
  foreach my $start (0 .. $#premax_forests_5) {
    ok (!! MyGraphs::Graph_is_Hamiltonian($graph, type=>'path', start=>$start),
        $start!=4 && $start!=18,
        "Hamiltonian path start $start");
  }
}

#------------------------------------------------------------------------------
exit 0;
