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

use strict;
use Graph;

use FindBin;
use lib "$FindBin::Bin/lib";
use MyGraphs;

{
  # Hypercube
  # N=3 cube      https://hog.grinvin.org/ViewGraphInfo.action?id=1022
  # N=4 tesseract https://hog.grinvin.org/ViewGraphInfo.action?id=1340
  # N=5           https://hog.grinvin.org/ViewGraphInfo.action?id=28533
  #     32 vertices 80 edges
  require Graph::Maker::Hypercube;
  my @graphs;
  for (my $k = 0; @graphs <= 5; $k++) {
    my $graph = Graph::Maker->new('hypercube', N => $k, undirected=>1);
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # Tesseract cospectral with Hoffman
  {
    # tesseract
    require Graph::Maker::Hypercube;
    my $graph = Graph::Maker->new('hypercube', N => 4, undirected=>1);
    require Graph::Writer::Matrix;
    print "factor(charpoly(";
    my $writer = Graph::Writer::Matrix->new (format => 'gp');
    $writer->write_graph($graph, \*STDOUT);
    print "))\n";
  }
  {
    # hoffman from hog
    require Graph::Reader::Graph6;
    my $reader = Graph::Reader::Graph6->new;
    my $graph = $reader->read_graph('/so/hog/graphs/graph_1167.g6');
    require Graph::Writer::Matrix;
    print "factor(charpoly(";
    my $writer = Graph::Writer::Matrix->new (format => 'gp');
    $writer->write_graph($graph, \*STDOUT);
    print "))\n";
  }
  exit 0;
}


