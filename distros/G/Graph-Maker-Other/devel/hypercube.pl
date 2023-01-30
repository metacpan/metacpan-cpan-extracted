#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017, 2019, 2020, 2021, 2022 Kevin Ryde
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
use FindBin;
use File::Spec;
use Graph;
use Math::Trig 'pi';
use Graph::Maker::Hypercube;

use lib File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'devel', 'lib');
use MyGraphs;

# uncomment this to run the ### lines
# use Smart::Comments;

{
  # Hypercube
  # N=3 cube      https://hog.grinvin.org/ViewGraphInfo.action?id=1022
  # N=4 tesseract https://hog.grinvin.org/ViewGraphInfo.action?id=1340
  # N=5           https://hog.grinvin.org/ViewGraphInfo.action?id=28533
  #     32 vertices 80 edges
  # N=6           https://hog.grinvin.org/ViewGraphInfo.action?id=33768
  # N=7           https://hog.grinvin.org/ViewGraphInfo.action?id=33770

  require Graph::Maker::Hypercube;
  my @graphs;
  for (my $N = 3; $N<=8; $N++) {
    # my $graph = Graph::Maker->new('hypercube', N => $N, undirected=>1);
    my $graph = make_merged_hypercube($N);
    ### $graph
    MyGraphs::Graph_hypercube_layout($graph);
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  # MyGraphs::hog_upload_html($graphs[0]);
  # MyGraphs::Graph_view($graphs[-1]);
  exit 0;
}

{
  foreach my $N (3..3) {
    my $graph = Graph::Maker->new('hypercube', N => $N, undirected=>1);
    my @vertices = $graph->vertices;
    my @edges = $graph->edges;
    print "vertices ", join(' ',@vertices),"\n";
    print "edges ", join(' ',map {join(',',@$_)} @edges),"\n";
  }
  exit 0;
}

{
  # Hypercube plus complete graph clique for each N-1 dimension face
  # N=3 cube   https://hog.grinvin.org/ViewGraphInfo.action?id=176
  #
  # 2^(N-1) cross edges not present

  my @graphs;
  foreach my $N (3..5) {
    my $graph = Graph::Maker->new('hypercube', N => $N, undirected=>1);
    MyGraphs::hypercube_layout($graph);

    my @vertices = $graph->vertices;
    # print "vertices ", join(' ',@vertices),"\n";
    foreach my $pos (0 .. $N-1) {
      my $mask = 1<<$pos;
      foreach my $want (0,$mask) {
        my @face = grep {(($_-1) & $mask) == $want} @vertices;
        @face == 1<<($N-1) or die;
        # print "face ", join(' ',@face),"\n";
        add_clique($graph,@face);
      }
    }
    my @edges = $graph->edges;
    my $num_edges = scalar(@edges);
    $graph = $graph->complement;
    print "vertices ", join(' ',@vertices),"\n";
    print "edges ", join(' ',map {join(',',@$_)} @edges),"\n";
    print "N=$N  $num_edges edges\n";
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  # MyGraphs::hog_upload_html($graphs[1]);
  # MyGraphs::Graph_view($graphs[-1]);
  exit 0;

  sub add_clique {
    my ($graph, @vertices) = @_;
    foreach my $from_i (0 .. $#vertices) {
      foreach my $to_i (($graph->is_undirected ? $from_i+1 : 0) .. $#vertices) {
        next if $from_i == $to_i;
        $graph->add_edge ($vertices[$from_i], $vertices[$to_i]);
      }
    }
  }
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


