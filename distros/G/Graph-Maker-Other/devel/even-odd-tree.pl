#!/usr/bin/perl -w

# Copyright 2019 Kevin Ryde
#
# This file is part of Graph-Maker-Other.
#
# Graph-Maker-Other is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Graph-Maker-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Maker-Other.  If not, see <http://www.gnu.org/licenses/>.

use 5.005;
use strict;
use List::Util 'sum';

use FindBin;
use lib "$FindBin::Bin/lib";
use MyGraphs;
$|=1;

use Graph::Maker::EvenOddTree;

# uncomment this to run the ### lines
use Smart::Comments;


{
  my @graphs;
  foreach my $N (
                  3
                ) {
    print "N=$N\n";
    my $graph = Graph::Maker->new
      ('even_odd_tree',
       N          => $N,
       undirected => 0,
       # rel_direction => 'down',
       # rel_direction => 'up',
       # comma => '',
      );
    push @graphs, $graph;
    print "directed ",$graph->is_directed,"\n";
    $graph->set_graph_attribute (flow => 'south');
    print $graph->get_graph_attribute('name'),"\n";
    my $num_vertices = $graph->vertices;
    my $num_edges = $graph->edges;
    my $diameter = $graph->diameter || 0;
    my $canon_g6 = MyGraphs::graph6_str_to_canonical
      (MyGraphs::Graph_to_graph6_str($graph));
    my $hog = MyGraphs::hog_grep($canon_g6) || "not";
    print "$num_vertices vertices, $num_edges edges diam=$diameter  $hog\n";

    MyGraphs::Graph_run_dreadnaut($graph->is_directed ? $graph->undirected_copy : $graph,
                                  verbose=>0, base=>1);
    # print "vertices: ",join('  ',$graph->vertices),"\n";
    if ($graph->vertices < 300) {
      MyGraphs::Graph_view($graph, synchronous=>0);
    }
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}


{
  # Even/Odd Expansion Tree

  # 1 row singleton HOG 1310
  # 2 rows path-3 HOG 32234
  # 3 rows HOG ...
  # 5 rows HOG ...
  #
  # num vertices
  # not in OEIS: 1, 3, 6, 11, 19, 31, 49, 76, 117, 179
  # num edges
  # not in OEIS: 0, 2, 5, 10, 18, 30, 48, 75, 116, 178

  my @graphs;
  foreach my $rows (1 .. 10) {
    my $graph = make_even_odd_tree($rows);
    push @graphs, $graph;
  }
  # MyGraphs::Graph_view($graphs[9]);
  foreach my $graph (@graphs) {
    my $num_vertices = $graph->vertices;
    my $num_edges = $graph->edges;
    print "$num_vertices $num_edges\n";
    # MyGraphs::Graph_view($graph);
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;

  sub make_even_odd_tree {
    my ($rows) = @_;
    require Graph;
    my $graph = Graph->new;
    my $width = 1;
    foreach my $row (0 .. $rows-1) {
      foreach my $i (0 .. $width-1) {
        $graph->add_vertex("r$row $i");
      }
      if ($row < $rows-1) {
        my $next_i = 0;
        my $next_row = $row+1;
        foreach my $i (0 .. $width-1) {
          foreach my $rep (1 .. ($i % 2 == 0 ? 2 : 1)) {
            $graph->add_edge("r$row $i", "r$next_row $next_i");
            $next_i++;
          }
        }
        $width = $next_i;
      }
    }
    return $graph;
  }
}
