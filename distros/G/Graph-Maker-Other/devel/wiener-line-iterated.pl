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
use lib "$FindBin::Bin/../devel/lib";
use MyGraphs;

{
  # Wiener of line graph
  # Buckley: tree  W(L(G)) = W(G) - binomial(num vertices, 2)
  #
  my @values;
  foreach my $k (0 .. 10) {
    # require Graph::Maker::Star;
    # my $graph = Graph::Maker->new('star', N=>$k, undirected=>1);

    # require Graph::Maker::Linear;
    # my $graph = Graph::Maker->new('linear', N=>$k, undirected=>1);

    # require Graph::Maker::BalancedTree;
    # my $graph = Graph::Maker->new('balanced_tree',
    #                               fan_out => 2, height => $k,
    #                               undirected=>1,
    #                              );

    # require Graph::Maker::FibonacciTree;
    # my $graph = Graph::Maker->new('fibonacci_tree',
    #                               height => $k,
    #                               # leaf_reduced => 1,
    #                               # series_reduced => 1,
    #                               undirected=>1,
    #                              );

    # require Graph::Maker::BinomialTree;
    # my $graph = Graph::Maker->new('binomial_tree',
    #                               order => $k,
    #                               undirected => 1,
    #                              );

    require Graph::Maker::TwindragonAreaTree;
    my $graph = Graph::Maker->new('twindragon_area_tree',
                                  level => $k,
                                  undirected => 1,
                                 );
    print "k=$k\n";
    if ($graph->vertices <= 16) { print "$graph\n"; }
    my $W = Graph_Wiener_index($graph);
    print "  W=$W\n";
    my $WL;
    for (;;) {
      $graph = Graph_line_graph($graph);
      $WL = Graph_Wiener_index($graph);
      print "  WL=$WL\n";
      last if $WL > $W;
      last if $WL == 0;
      last;
    }
    push @values, $WL;
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values,
                           verbose => 1);

  exit 0;
}

{
  # trees G which have iterated line graph Wiener index W(L^2(G)) = W(G)
  # A051175 number of such trees
  # num(9,10,11) = 1 each
  #
  # n=9  https://hog.grinvin.org/ViewGraphInfo.action?id=25131
  # n=10 https://hog.grinvin.org/ViewGraphInfo.action?id=25133
  # n=11 https://hog.grinvin.org/ViewGraphInfo.action?id=25135

  # Dobrynin, Entringer, Gutman "Wiener Index of Trees: Theory and
  # Applications" Acta Applicandae Mathematicae, May 2001, 66, 3, survey
  # of
  # Dobrynin "Distance of Iterated Line Graphs", Graph Theory Notes of New
  # York, volume 37, 1999, page 8-9.

  my $iterator_func = make_tree_iterator_edge_aref
    (num_vertices_min => 2,
     num_vertices_max => 11);
  my @array;
 TREE: while (my $edge_aref = $iterator_func->()) {
    my $graph = Graph_from_edge_aref($edge_aref);
    my $W = Graph_Wiener_index($graph);
    my $graph_L = Graph_line_graph($graph);
    # $graph_L = Graph_line_graph($graph_L);  # try L^3
    my $graph_L2 = Graph_line_graph($graph_L);
    my $WL2 = Graph_Wiener_index($graph_L2);
    if ($W == $WL2) {
      my $num_vertices = $graph->vertices;
      print "[$num_vertices] $graph\n";
      $graph->set_graph_attribute (name => "W(G)=W(L^2(G)) $num_vertices vertices");
      $graph_L->set_graph_attribute (name => "line graph");
      $graph_L2->set_graph_attribute (name => "line graph * 2");
      # Graph_view($graph);
      push @array, $graph;
      push @array, $graph_L;
      push @array, $graph_L2;
    }
  }
  hog_searches_html(@array);
  exit 0;
}

{
  # Knor, Macaj, Potocnik, Skrekovski  W(L^3(G)) = W(G)
  # a = 128 + 3*i^2 + 3*j^2 - 3*i*j + i
  # b = 128 + 3*i^2 + 3*j^2 - 3*i*j + j
  # c = 128 + 3*i^2 + 3*j^2 - 3*i*j + i+j
  # a+b+c == 9*i^2 + 9*j^2 - 9*i*j + 2*i + 2*j + 384
  # abc(i,j) = 9*i^2 + 9*j^2 - 9*i*j + 2*i + 2*j + 384;
  # my(m=10^10); for(i=0,20,for(j=0,20, m=min(m,abc(i,j)))); m
  # minimum 384 of branches plus 4 in middle = 388 vertices
  exit 0;
}
