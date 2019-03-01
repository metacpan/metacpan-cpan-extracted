#!/usr/bin/perl -w

# Copyright 2018 Kevin Ryde
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
use List::Util 'max','sum';

use FindBin;
use lib "$FindBin::Bin/lib";
use MyGraphs;
$|=1;

use Graph::Maker::PartitionSum;

# uncomment this to run the ### lines
# use Smart::Comments;


{
  # N=4  4-cycle and leaf
  #      https://hog.grinvin.org/ViewGraphInfo.action?id=206
  # N=5  crossover
  #      https://hog.grinvin.org/ViewGraphInfo.action?id=864
  #
  my @graphs;
  foreach my $N (
                 15
                ) {
    print "N=$N\n";
    my $graph = Graph::Maker->new
      ('partition_sum',
       N          => $N,
       distinct   => 1,
       undirected => 0,
      );
    push @graphs, $graph;
    print "directed ",$graph->is_directed,"\n";
    $graph->set_graph_attribute (flow => 'east');
    print $graph->get_graph_attribute('name'),"\n";
    my $num_vertices = $graph->vertices;
    my $num_edges = $graph->edges;
    my $diameter = $graph->diameter || 0;
    my $canon_g6 = MyGraphs::graph6_str_to_canonical
      (MyGraphs::Graph_to_graph6_str($graph));
    my $hog = MyGraphs::hog_grep($canon_g6) || "not";
    print "$num_vertices vertices, $num_edges edges diam=$diameter  $hog\n";

    # MyGraphs::Graph_run_dreadnaut($graph->undirected_copy,
    #                               verbose=>0, base=>1);
    # print "vertices: ",join('  ',$graph->vertices),"\n";
    if ($graph->vertices < 100) {
      MyGraphs::Graph_view($graph, synchronous=>0);
    }

    my $d6str = MyGraphs::Graph_to_graph6_str($graph, format=>'digraph6');
    # print Graph::Graph6::HEADER_DIGRAPH6(), $d6str;
    print "\n";
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # diameter undirected
  # N-1
  #
  # max degree
  # 0,0,1,2,3,3,5,6,7,7,10,11,11,12,13,16,17,18,18,19,19,
  # not in OEIS: 1,2,3,3,5,6,7,7,10,11,11,12,13,16,17,18,18,19,19,24,25,25,26,27,27,28,
  #
  # max out degree
  # not in OEIS: 1,2,2,2,2,3,3,3,4,4,4,4,5,5,6,5,7,6,7,6,8,7,8,7,10,8,11,8,11,9,12,9,12,10,12,10,15,11,16,11,16,12,17,

  my @graphs;
  foreach my $N (0 .. 30) {
    my $graph = Graph::Maker->new ('partition_sum', N => $N,
                                   undirected => 0,
                                  );
    # my $num_vertices = $graph->vertices;
    # print "$num_vertices,";
    # my $num_edges = $graph->edges;
    # my $diameter = $graph->diameter || 0;
    # print "$diameter,";

    print max(map {$graph->degree($_)} $graph->vertices),",";
    print max(map {$graph->out_degree($_)} $graph->vertices),",";
  }
  exit 0;
}

{
  my $graph = Graph::Maker->new
    ('partition_sum',
     N            => 6,
    );
  MyGraphs::Graph_view($graph, synchronous=>1);
  exit 0;
}
