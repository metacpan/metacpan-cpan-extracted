#!/usr/bin/perl -w

# Copyright 2015, 2017 Kevin Ryde
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
use lib "$FindBin::Bin/lib";
use MyGraphs;
use Graph::Maker::BestOf;

# uncomment this to run the ### lines
# use Smart::Comments;


{
  # BestOf grep

  # bestof(N) = my(h=floor(N/2)); if(N%2==0, (h+1)^2 + 2*h, (h+1)^2 + 2*(h+1));
  # bestof(N) = my(h=floor(N/2)); 1/4*if(N%2==0, N^2 + 8*N + 4, N^2 + 6*N + 5);
  # vector(9,N,N--; bestof(N))

  # N=2  square with 2 hanging
  #   https://hog.grinvin.org/ViewGraphInfo.action?id=422   graphedron
  # N=3  square with 4 hanging  hog not
  # N=4  3x3 with 4  hanging  hog not
  # N=5  3x3 with 6  hanging  hog not
  # N=6  4x4 with 6  hanging  hog not
  # N=7  4x4 with 8  hanging  hog not
  #

  my @graphs;
  my @values;
  foreach my $N (0 .. 8) {
    my $graph = Graph::Maker->new('best_of',
                                  N => $N,
                                  undirected => 0,
                                 );

    my $num_vertices = $graph->vertices;
    my $num_edges = $graph->edges;
    print "N=$N vertices $num_vertices edges $num_edges\n";
    push @values, $num_vertices;

    {
      require Graph::Convert;
      my $easy = Graph::Convert->as_graph_easy($graph);
      $easy->set_attribute('flow','east');
      # Graph_Easy_view($easy);
      # push @graphs, $easy;
    }
    push @graphs, $graph;

    # {
    #   require Graph::Writer::Graph6;
    #   my $writer = Graph::Writer::Graph6->new;
    #   my $g6_str;
    #   open my $fh, '>', \$g6_str or die;
    #   $writer->write_graph($graph, $fh);
    #   print graph6_str_to_canonical($g6_str);
    # }
  }
  MyGraphs::hog_searches_html(@graphs);

  print join(',',@values),"\n";
  exit 0;
}

