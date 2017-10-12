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
use Math::BaseCnv 'cnv';
use Graph::Maker::HexGrid;

use FindBin;
use lib "$FindBin::Bin/lib";
use MyGraphs;

# uncomment this to run the ### lines
# use Smart::Comments;


{
  # POD pictures
  my $graph = Graph::Maker->new('hex_grid', dims => [4,3,2],
                                undirected => 1);
  MyGraphs::Graph_xy_print_triangular($graph);

  $graph = Graph::Maker->new('hex_grid', dims => [4,3,1],
                             undirected => 1);
  MyGraphs::Graph_xy_print_triangular($graph);

  $graph = Graph::Maker->new('hex_grid', dims => [3,1,1],
                             undirected => 1);
  MyGraphs::Graph_xy_print_triangular($graph);
  print "\n\n";

  $graph = Graph::Maker->new('hex_grid', dims => [3,3,3],
                             undirected => 1);
  MyGraphs::Graph_xy_print_triangular($graph);
  print scalar($graph->vertices)," vertices ",scalar($graph->edges)," edges\n";

  exit 0;
}
{
  # HOG searches
  # 1,1,1 https://hog.grinvin.org/ViewGraphInfo.action?id=670  6-cycle
  # 1,1,2 not
  # 1,1,3 not
  # 1,2,2 not
  # 1,2,3 not
  # 1,3,3 not
  # 2,2,2 not (Gosper island)
  # 2,2,3 not
  # 2,3,3 not
  # 3,3,3 https://hog.grinvin.org/ViewGraphInfo.action?id=28500

  my @graphs;
  foreach my $x (1 .. 3) {
    foreach my $y ($x .. 3) {
      foreach my $z ($y .. 3) {
        my $graph = Graph::Maker->new('hex_grid', dims=>[$x,$y,$z],
                                      undirected=>1);
        my $num_vertices = $graph->vertices;
        my $num_edges    = $graph->edges;
        print "$x,$y,$z  $num_vertices $num_edges\n";
        push @graphs, $graph;
      }
    }
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}


{
  my $graph = Graph::Maker->new('hex_grid', dims => [2,5,8],
                                undirected => 1);
  print $graph->get_graph_attribute('name'),"\n";
  MyGraphs::Graph_view($graph);
  my $num_vertices = $graph->vertices;
  my $num_edges    = $graph->edges;
  my $diameter     = $graph->diameter;
  print "  diameter $diameter\n";
  exit 0;
}
