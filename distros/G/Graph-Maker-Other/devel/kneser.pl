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
use FindBin;
use List::Util 'min','max','sum';
use MyGraphs;
use Graph::Maker::Kneser;

# uncomment this to run the ### lines
# use Smart::Comments;


{
  # Kneser
  #
  # K(4,2) https://hog.grinvin.org/ViewGraphInfo.action?id=484
  #        3 of path-2
  # K(5,2) https://hog.grinvin.org/ViewGraphInfo.action?id=660
  #        Petersen
  # K(6,2) https://hog.grinvin.org/ViewGraphInfo.action?id=19271
  #        W(2) generalized quadrangle order 2,2 ...
  # K(6,3) hog not
  #        10 of path-2
  # K(7,2) hog not
  # K(7,3) hog not
  #  

  require Graph::Maker::Kneser;
  my @graphs;
  foreach my $N (7) {
    foreach my $K (2 .. int($N/2)) {
      my $graph = Graph::Maker->new('Kneser',
                                    N => $N, K => $K,
                                    undirected => 1,
                                   );
      print $graph->get_graph_attribute ('name'),"\n";
      my $num_vertices = $graph->vertices;
      my $num_edges    = $graph->edges;
      print "  num vertices $num_vertices  num edges $num_edges\n";
      # Graph_view($graph);
      push @graphs, $graph;
    }
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
