#!/usr/bin/perl -w

# Copyright 2017 Kevin Ryde
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
use Graph::Maker::RookGrid;

use FindBin;
use lib "$FindBin::Bin/lib";
use MyGraphs;

# uncomment this to run the ### lines
# use Smart::Comments;



{
  # Rook 4,4 cospectral with Shrikhande

  # charpoly = (x-6) * (x-2)^6 * (x+2)^9
  {
    require Graph::Maker::RookGrid;
    my $graph = Graph::Maker->new('rook_grid', dims=>[4,4], undirected=>1);

    my $num_vertices = $graph->vertices;
    my $num_edges    = $graph->edges;
    my $g6_str = MyGraphs::graph6_str_to_canonical
      (MyGraphs::Graph_to_graph6_str($graph));
    print "vertices $num_vertices edges $num_edges ",
      MyGraphs::hog_grep($g6_str)?"HOG":"not", "\n";

    require Graph::Writer::Matrix;
    print "factor(charpoly(";
    my $writer = Graph::Writer::Matrix->new (format => 'gp');
    $writer->write_graph($graph, \*STDOUT);
    print "))\n";
  }
  {
    my $graph = Shrikhande();

    my $num_vertices = $graph->vertices;
    my $num_edges    = $graph->edges;
    my $g6_str = MyGraphs::graph6_str_to_canonical
      (MyGraphs::Graph_to_graph6_str($graph));
    print "vertices $num_vertices edges $num_edges ",
      MyGraphs::hog_grep($g6_str)?"HOG":"not", "\n";

    require Graph::Writer::Matrix;
    # MyGraphs::Graph_view($graph);
    print "factor(charpoly(";
    my $writer = Graph::Writer::Matrix->new (format => 'gp');
    $writer->write_graph($graph, \*STDOUT);
    print "))\n";
  }
  exit 0;

  sub Shrikhande {
    my $graph = Graph->new(undirected=>1);
    foreach my $i (0 .. 7) {
      $graph->add_path (($i+1)%8, $i, ($i+2)%8);  # outer
      $graph->add_path ((($i-1)%8) + 8, $i, (($i+1)%8) + 8); # to middle
      $graph->add_path ((($i+2)%8) + 8, $i+8, (($i+3)%8) + 8); # inner
    }
    return $graph;
  }
}
{
  # 1xN various path
  # 2x2 4-cycle
  # 2x3 cross-linked triangles
  # 3x3

  # GP-DEFINE  rook_edges(w,h) = sum(x=1,w,sum(y=1,h, w-x + h-y));
  # GP-Test  rook_edges(2,3) == 9
  # GP-Test  rook_edges(8,8) == 448

  my @graphs;
  my @values;
  foreach my $w (4) {
    foreach my $h ($w .. 4) {

      my $graph = Graph::Maker->new('rook_grid',
                                    dims => [$w,$h],
                                    undirected => 1,
                                   );
    my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
    $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
      my $hog = (MyGraphs::hog_grep($g6_str) ? "   HOG" : "");

      push @graphs, $graph;
      my $num_edges = $graph->edges;
      print "$w x $h edges $num_edges$hog\n";
    }
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # Rook 4,4 tikz

  require Graph::Maker::RookGrid;
  my $graph = Graph::Maker->new('rook_grid', dims=>[4,4], undirected=>1);
  MyGraphs::Graph_print_tikz($graph);
  exit 0;
}


{
  # Lattice 4,4 = Rook
  require Graph::Maker::CompleteBipartite;
  my $graph = Graph::Maker->new('complete_bipartite', N1 => 4, N2 => 4,
                                undirected => 1);
  $graph = MyGraphs::Graph_line_graph($graph);
  my $can = MyGraphs::graph6_str_to_canonical
    (MyGraphs::Graph_to_graph6_str($graph));
  print MyGraphs::hog_grep($can)?"HOG":"not", "\n";
   MyGraphs::Graph_view($graph);

  my $g2 = Graph->new(undirected => 1);
  foreach my $x (1 .. 4) {
    foreach my $y (1 .. 4) {
      foreach my $t (1 .. 4) {
        if ($t != $x) { $g2->add_edge("$x,$y", "$t,$y"); }
        if ($t != $y) { $g2->add_edge("$x,$y", "$x,$t"); }
      }
    }
  }
  MyGraphs::Graph_view($g2);

  print "isomorphic ",MyGraphs::Graph_is_isomorphic($graph,$g2),"\n";
  $can = MyGraphs::graph6_str_to_canonical
    (MyGraphs::Graph_to_graph6_str($graph));
  print MyGraphs::hog_grep($can)?"HOG":"not", "\n";
  exit 0;
}
