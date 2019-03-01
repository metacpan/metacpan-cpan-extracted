#!/usr/bin/perl -w

# Copyright 2018, 2019 Kevin Ryde
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

use Graph::Maker::Permutations;

# uncomment this to run the ### lines
use Smart::Comments;


{
  my @graphs;
  foreach my $N (
                  3
                ) {
    print "N=$N\n";
    my $graph = Graph::Maker->new
      ('permutations',
       N          => $N,
       undirected => 0,
       # rel_direction => 'down',
       # rel_direction => 'up',
       rel_type => 'onepos',
       rel_type => 'cycle_append',
       rel_type => 'transpose_plus1',
       rel_type => 'transpose_adjacent',
       rel_type => 'transpose_cyclic',
       rel_type => 'transpose',
       rel_type => 'transpose_cover',
       # vertex_name_type => 'perm',
       # vertex_name_type => 'cycles',
       vertex_name_inverse => 0,
       comma => '',
      );
    push @graphs, $graph;
    print "directed ",$graph->is_directed,"\n";
    $graph->set_graph_attribute (flow => 'north');
    $graph->set_graph_attribute (flow => 'east');
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
    if ($graph->vertices < 30) {
      MyGraphs::Graph_view($graph, synchronous=>0);
    }

    my $d6str = MyGraphs::Graph_to_graph6_str($graph, format=>'digraph6');
    # print Graph::Graph6::HEADER_DIGRAPH6(), $d6str;
    print "\n";

    MyGraphs::Graph_print_tikz($graph);
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
