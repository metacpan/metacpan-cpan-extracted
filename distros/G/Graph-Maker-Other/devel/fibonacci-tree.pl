#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017, 2019 Kevin Ryde
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
use List::Util 'min','max','sum';
use POSIX 'ceil';

use FindBin;
use lib "$FindBin::Bin/lib";
use MyGraphs;

# uncomment this to run the ### lines
# use Smart::Comments;

{
  # FibonacciTree
  require Graph::Maker::FibonacciTree;
  my @graphs;
  foreach my $k (4) {
    my $graph = Graph::Maker->new('fibonacci_tree', undirected => 1,
                                  height => $k,
                                  series_reduced => 1,
                                  leaf_reduced => 1,
                                 );
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # FibonacciTree not 5,6
  # k=4 six with a leaf off it
  #     https://hog.grinvin.org/ViewGraphInfo.action?id=934
  # zero_node=>1 not 4,5,6
  require Graph::Maker::FibonacciTree;
  my @graphs;
  foreach my $k (0 .. 8) {
    my $graph = Graph::Maker->new('fibonacci_tree', undirected => 1,
                                  height => $k,
                                  leaf_reduced => 1,
                                  series_reduced => 0,
                                 );
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # FibonacciTree series_reduced diameter and centre
  # centre 1,2     for height>=3
  # diameter 2*H-3 for height >=3
  require Graph::Maker::FibonacciTree;
  foreach my $height (1 .. 10) {
    my $graph = Graph::Maker->new('fibonacci_tree',
                                  height => $height,
                                  series_reduced => 1,
                                  undirected => 1,
                                 );
    my $diameter = $graph->diameter;
    print "h=$height centre ",join(',',$graph->centre_vertices),
      "  diameter=$diameter \n";;
  }
  exit 0;
}

{
  # FibonacciTree forms ascii prints

  require Graph::Maker::FibonacciTree;
  my $height = 5;
  print " full\n";
  my $graph = Graph::Maker->new('fibonacci_tree',
                                height => $height,
                                leaf_reduced => 0,
                                series_reduced => 0,
                                # undirected => 1,
                               );
  Graph_tree_print($graph);

  print "\n branch reduced\n";
  $graph = Graph::Maker->new('fibonacci_tree',
                             height => $height,
                             leaf_reduced => 0,
                             series_reduced => 1,
                              undirected => 1,
                            );
  print " diameter=",scalar($graph->diameter),
    " vertices ",join(',',$graph->diameter),"\n";
  Graph_tree_print($graph);

  print " both reduced\n";
  $graph = Graph::Maker->new('fibonacci_tree',
                             height => $height,
                             leaf_reduced => 1,
                             series_reduced => 1,
                             # undirected => 1,
                            );
  Graph_tree_print($graph);
  # Graph_view($graph);

  print " leaf reduced\n";
  $graph = Graph::Maker->new('fibonacci_tree',
                             height => $height,
                             leaf_reduced => 1,
                             series_reduced => 0,
                             # undirected => 1,
                            );
  Graph_tree_print($graph);

  exit 0;
}

{
  # FibonacciTree non-leaf single children

  require Graph::Maker::FibonacciTree;
  require Math::NumSeq::Fibonacci;
  my $seq = Math::NumSeq::Fibonacci->new;
  foreach my $k (2 .. 50) {
    my $graph = Graph::Maker->new('fibonacci_tree', order => $k);

    my $count = 0;
    foreach my $v ($graph->vertices) {
      my $num_children = grep {$_ > $v} $graph->neighbours($v);
      if ($num_children == 1) {
        $count++;
      }
    }
    # 2*F(k+1)-1 - (F(k+2)-1)
    # = 2*F(k+1) - (F(k) + F(k+1))
    # = F(k+1) - F(k)
    # = F(k-1)
    my $F = $seq->ith($k-1);
    print "k=$k  $count   F(k-1)=$F\n";
  }
  exit 0;
}

{
  # Fibonacci tree by Fibonacci word

  require Graph::Easy;
  require Math::NumSeq::FibonacciWord;
  my $seq = Math::NumSeq::FibonacciWord->new;
  # $seq->next;

  my $upto = 1;
  my @leaf = ($upto++);
  my $easy = Graph::Easy->new;
  $easy->set_attribute('flow','south');
  $easy->add_vertex($leaf[0]);

  foreach my $depth (2 .. 6) {
    print "depth=$depth  count ",scalar(@leaf),"\n";
    my @new_leaf;
    while (my $v = shift @leaf) {
      my ($i, $value) = $seq->next;
      my $num_children = ($value ? 1 : 2);
      foreach (1 .. $num_children) {
        my $new_v = $upto++;
        $easy->add_edge($v, $new_v);
        push @new_leaf, $new_v;
      }
    }
    @leaf = @new_leaf;
     $seq->rewind;
    # $seq->next;
  }
  print "final row  count ",scalar(@leaf),"\n";

  require Graph::Convert;
  my $graph = Graph::Convert->as_graph($easy);
  Graph_tree_print($graph);

  $easy->set_attribute('root',$leaf[0]);  # for as_graphviz()
  $easy->{att}->{root} = $leaf[0];        # for root_node() for as_ascii()
  Graph_Easy_view($easy);
  # Graph_Easy_branch_reduce($easy);
  # Graph_Easy_view($easy);
  # Graph_Easy_leaf_reduce($easy);
  # Graph_Easy_view($easy);

  print "by FibonacciTree\n";
  require Graph::Maker::FibonacciTree;
  $graph = Graph::Maker->new('fibonacci_tree',
                             height => 6,
                             leaf_reduced => 0,
                             series_reduced => 0,
                            );
  Graph_tree_print($graph);
  exit 0;
}



{
  require Graph::Maker::FibonacciTree;
  my $graph = Graph::Maker->new('fibonacci_tree',
                                order => 15,
                                series_reduced => 0,
                                # undirected => 1,
                               );
  foreach my $v (1 .. 200) {
    my $num_children = Graph_vertex_num_children($graph,$v) || last;
    print "$num_children,"
  }
  print "\n";
  exit 0;
}

