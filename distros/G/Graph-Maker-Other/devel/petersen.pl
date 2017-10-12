#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017 Kevin Ryde
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
use Graph::Maker::Petersen;

use FindBin;
use lib "$FindBin::Bin/../devel/lib";
use MyGraphs;
$|=1;

# uncomment this to run the ### lines
# use Smart::Comments;

{
  # Petersen triangle replaced
  # = cubic vertex-transitive graph "Ct66"
  # https://hog.grinvin.org/ViewGraphInfo.action?id=28537

  # require Graph::Maker::Cycle;
  # $graph = Graph::Maker->new('cycle', N=>4, undirected => 1);

  my $graph = Graph::Maker->new('Petersen', undirected => 1);
  my $line = MyGraphs::Graph_line_graph($graph);
  my $triangle = Graph_triangle_replacement($graph);
  print "line and triangle isomorphic ",MyGraphs::Graph_is_isomorphic($line,$triangle)||0,"\n";
  MyGraphs::Graph_view($triangle);
  MyGraphs::hog_searches_html($triangle);
  # MyGraphs::Graph_print_tikz($triangle);

  # slow but runs to completion
  print "try Hamiltonian\n";
  print MyGraphs::Graph_is_Hamiltonian($triangle, verbose => 1);
  exit 0;

  # $graph is an undirected Graph.pm.

  # Return a new Graph.pm which is the given $graph with each vertex
  # replaced by a triangle.  Existing edges go to different vertices of the
  # new triangle.  Must have all vertices of the original $graph degree <= 3.
  #
  sub Graph_triangle_replacement {
    my ($graph) = @_;
    my $new_graph = Graph->new (undirected => 1);
    foreach my $v ($graph->vertices) {
      $new_graph->add_cycle($v.'-1', $v.'-2', $v.'-3');
    }
    my %upto;
    foreach my $edge ($graph->edges) {
      $new_graph->add_edge(map {$_.'-'.++$upto{$_}} @$edge);
    }
    $new_graph;
  }
}
{
  # Petersen HOG
  
  # N=3 K=1 https://hog.grinvin.org/ViewGraphInfo.action?id=746
  #         triangles cross connected
  # N=4 K=1 https://hog.grinvin.org/ViewGraphInfo.action?id=1022
  #         squares cross connected = cube
  # N=4 K=2 https://hog.grinvin.org/ViewGraphInfo.action?id=588
  #         squares with cross connected pairs
  # N=5 K=1 hog not
  # N=5 K=2 https://hog.grinvin.org/ViewGraphInfo.action?id=660
  #         Petersen
  # N=6 K=1 hog not
  # N=6 K=2 hog not
  # N=6 K=3 hog not
  # N=7 K=1 hog not
  # N=7 K=2 https://hog.grinvin.org/ViewGraphInfo.action?id=28482
  # N=7 K=3 hog not
  # N=8 K=1 hog not
  # N=8 K=2 hog not
  # N=8 K=3 https://hog.grinvin.org/ViewGraphInfo.action?id=1229
  #         Moebius Kantor Graph
  # N=8 K=4 hog not
  # N=9 K=1 hog not
  # N=9 K=2 hog not
  # N=9 K=3 https://hog.grinvin.org/ViewGraphInfo.action?id=6700
  # N=10 K=1
  # N=10 K=2 https://hog.grinvin.org/ViewGraphInfo.action?id=1043
  #          Dodecahedral Graph
  # N=10 K=3 https://hog.grinvin.org/ViewGraphInfo.action?id=1036
  #          Desargues Graph
  # N=10 K=4
  # N=10 K=5
  # N=11 K=2 https://hog.grinvin.org/ViewGraphInfo.action?id=24052
  # N=12 K=2 https://hog.grinvin.org/ViewGraphInfo.action?id=27325
  # N=12 K=5 https://hog.grinvin.org/ViewGraphInfo.action?id=1234
  #          Nauru
  #    http://11011110.livejournal.com/124705.html (gone)
  #    http://web.archive.org/web/1id_/http://11011110.livejournal.com/124705.html

  my @graphs;
  my %seen;
  foreach my $N (8 .. 9) {
    foreach my $K (1 .. $N-1) {
      my $graph = Graph::Maker->new('Petersen', undirected => 1,
                                    N => $N, K => $K);
      my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
      $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
      next if $seen{$g6_str}++;

      push @graphs, $graph;
    }
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}



{
  # Petersen 7,2
  # 7,2 cf Goddard and Henning
  #     hog not
  # Ms?G?DCQ@DAID_IO?
  # Ms?G?DCQ@CaKHOE_?

  my $graph = Graph::Maker->new('Petersen', undirected => 1,
                                N => 7, K => 2);
  MyGraphs::Graph_view($graph);
  MyGraphs::hog_searches_html($graph);
  my $num_vertices = $graph->vertices;
  my $name = $graph->get_graph_attribute ('name');
  print "$name  n=$num_vertices\n";
  print "  girth ",MyGraphs::Graph_girth($graph),"\n";

  my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
  print $g6_str;
  print MyGraphs::graph6_str_to_canonical($g6_str);

  my $petersen = Graph->new(undirected=>1);
  $petersen->add_cycle(1,2,3,4,5);
  $petersen->add_cycle(6,8,10,7,9);
  $petersen->add_edges([1,6],[2,7],[3,8],[4,9],[5,10]);
  $num_vertices = $graph->vertices;
  print "n=$num_vertices\n";
  my $num_edges = $graph->edges;
  print "edges $num_edges\n";

  print "is_isomorphic ",MyGraphs::Graph_is_isomorphic($petersen,$graph)||0,"\n";

  exit 0;
}
{
  # Coxeter - hypohamiltonian, n=28
  # https://hog.grinvin.org/ViewGraphInfo.action?id=981

  # Coxeter triangle replaced
  # https://hog.grinvin.org/ViewGraphInfo.action?id=1382

  # Coxeter edge excision, n=26
  # https://hog.grinvin.org/ViewGraphInfo.action?id=1055

  require Graph::Reader::Graph6;
  my $graph = Graph::Reader::Graph6->new
    ->read_graph('/so/hog/graphs/graph_981.g6');
  my $triangle = Graph_triangle_replacement($graph);
  MyGraphs::Graph_view($triangle);
  MyGraphs::hog_searches_html($triangle);
  exit 0;
}


{
  # Petersen    https://hog.grinvin.org/ViewGraphInfo.action?id=660
  # line graph  hog not
  my $graph = Graph::Maker->new('Petersen', undirected => 1);
  my $line = Graph_line_graph($graph);
  Graph_print_tikz($line);
  # Graph_view($line);
  MyGraphs::hog_searches_html($graph, $line);
  print "is_subgraph ",Graph_is_subgraph($line,$graph),"\n";
  print "is_induced_subgraph ",Graph_is_induced_subgraph($line,$graph),"\n";
  exit 0;
}



