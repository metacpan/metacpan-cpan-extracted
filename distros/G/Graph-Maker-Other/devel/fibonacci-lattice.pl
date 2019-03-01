#!/usr/bin/perl -w

# Copyright 2018, 2019 Kevin Ryde
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
use List::Util 'sum';

use FindBin;
use lib "$FindBin::Bin/lib";
use MyGraphs;
$|=1;

use Graph::Maker::FibonacciLattice;

# uncomment this to run the ### lines
use Smart::Comments;


{
  require Graph;
  my @graphs;
  foreach my $N (0..6) {
    my $graph = Graph::Maker->new ('Fibonacci_lattice', N => $N);
    $graph->set_graph_attribute (flow => 'north');
    $graph->set_graph_attribute (flow => 'east');
#    MyGraphs::Graph_view($graph);
    push @graphs, $graph;

    my $num_vertices = $graph->vertices;
    my $num_edges = $graph->edges;
    my $diameter = $graph->diameter || 0;
    my $canon_g6 = MyGraphs::graph6_str_to_canonical
      (MyGraphs::Graph_to_graph6_str($graph));
    my $hog = MyGraphs::hog_grep($canon_g6) || "not";
    print "$num_vertices vertices, $num_edges edges diam=$diameter  $hog\n";
    # foreach my $v (sort $graph->vertices) {
    #   print "$v\n";
    # }
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # sep code making
  my $make = sub {
    my ($N) = @_;
    require Graph;
    my $graph = Graph->new;
    my @vertices = ('1');
    for (my $i=0; $i <= $#vertices; $i++) {
      my $from = $vertices[$i];
      my @from = split //, $from;
      foreach my $add (1,2) {
        my @to = (@from, $add);
        if (sum(@to) <= $N) {
          push @vertices, join('',@to);
          if ($add==1) {
            my $to = join('',@to);
            $graph->add_edge($from,$to);
          }
        }
      }
    }
    foreach my $from (@vertices) {
      $graph->add_vertex($from);
    }
    foreach my $from (@vertices) {
      my @from = split //, $from;
      foreach my $i (0 .. $#from) {
        if ($from[$i]==1) {
          my @to = @from; $to[$i] = 2;
          my $to = join('',@to);
          if ($graph->has_vertex($to)) {
            $graph->add_edge($from,$to);
          }
        }
      }
    }
    return $graph;
  };

  require Graph;
  my @graphs;
  foreach my $N (5) {
    my $graph = $make->($N);
    $graph->set_graph_attribute (flow => 'north');
    MyGraphs::Graph_view($graph);
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
