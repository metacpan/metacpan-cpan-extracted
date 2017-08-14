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
use List::Util 'min','max','sum';
use MyGraphs;

# uncomment this to run the ### lines
use Smart::Comments;


{
  # BinomialTree forms ascii prints

  # order=0 https://hog.grinvin.org/ViewGraphInfo.action?id=1310  single vertex
  # order=1 https://hog.grinvin.org/ViewGraphInfo.action?id=19655  path-2
  # order=2 https://hog.grinvin.org/ViewGraphInfo.action?id=594    path-4
  # order=3 https://hog.grinvin.org/ViewGraphInfo.action?id=700
  # order=4 hog not
  # order=5 https://hog.grinvin.org/ViewGraphInfo.action?id=21088
  # order=6 hog not

  #    0       count 1      order=3
  # /--|--\
  # 1 2   4    count 3
  #   |  /^\
  #   3  5 6   count 3
  #        |
  #        7   count 1

  require Graph::Maker::BinomialTree;
  my @graphs;
  foreach my $order (0 .. 5) {
    my $graph = Graph::Maker->new('binomial_tree',
                                  order => $order,
                                  undirected => 1,
                                 );
    print $graph->get_graph_attribute ('name'),"\n";
    if ($order == 4) {
      MyGraphs::Graph_tree_print($graph);
      print "N=",scalar($graph->vertices),
        "  W=",MyGraphs::Graph_Wiener_index($graph),"\n";
    }
    # MyGraphs::Graph_view($graph);
    push @graphs, $graph;
    print "\n";
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # BinomialTree by n

  # n=0 empty
  # n=1 https://hog.grinvin.org/ViewGraphInfo.action?id=1310  single vertex
  # n=2 https://hog.grinvin.org/ViewGraphInfo.action?id=19655  path-2
  # n=3 hog not  path-3
  # n=4 https://hog.grinvin.org/ViewGraphInfo.action?id=594    path-4
  # n=5 https://hog.grinvin.org/ViewGraphInfo.action?id=30     fork
  # n=6 https://hog.grinvin.org/ViewGraphInfo.action?id=496    E graph
  # n=7 https://hog.grinvin.org/ViewGraphInfo.action?id=714   (Graphedron)
  # n=8 https://hog.grinvin.org/ViewGraphInfo.action?id=700
  # n=9 not
  # n=10 not
  # n=11 not
  # n=12 not
  # n=13 not
  # n=14 not
  # n=15 not

  require Graph::Maker::BinomialTree;
  my @graphs;
  foreach my $N (0 .. 16) {
    my $graph = Graph::Maker->new('binomial_tree',
                                  N => $N,
                                  undirected => 1,
                                 );
    print $graph->get_graph_attribute ('name'),"\n";
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  foreach my $i (1 .. 31) {
    my $mask = $i ^ ($i-1);
    my $parent = $i & ~$mask;
    my $diff = $parent ^ $i;
    printf "%5b %5b -> %5b   %5b\n", $i, $mask&0x1F, $parent, $diff;
  }
  exit 0;
}

