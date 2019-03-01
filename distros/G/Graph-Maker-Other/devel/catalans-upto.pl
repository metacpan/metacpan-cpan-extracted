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

use Graph::Maker::CatalansUpto;

# uncomment this to run the ### lines
use Smart::Comments;


{
  my @graphs;
  foreach my $N (
                  3,
                 # 5, 6
                ) {
    print "N=$N\n";
    my $graph = Graph::Maker->new
      ('Catalans_upto',
       N          => $N,
       undirected => 0,
       countedged => 1,
       # rel_direction => 'down',
       # rel_direction => 'up',
       rel_type => 'below',
       rel_type => 'insert_left',
       rel_type => 'insert_right',
       rel_type => 'insert',
       # vertex_name_type => 'vpar_postorder',
       # vertex_name_type => 'run1s',
       # vertex_name_type => 'bracketing',
       # vertex_name_type => 'bracketing_reduced',
       # vertex_name_type => 'Ldepths',
       # vertex_name_type => 'Rdepths_inorder',
       # vertex_name_type => 'Rdepths_postorder',
       vertex_name_type => 'vpar',
       vertex_name_type => 'Lweights',
       vertex_name_type => 'balanced',
       # comma => '',
      );
    push @graphs, $graph;
    print "directed ",$graph->is_directed,"\n";
    $graph->set_graph_attribute (flow => 'north');
    $graph->set_graph_attribute (flow => 'south');
    print $graph->get_graph_attribute('name'),"\n";
    my $num_vertices = $graph->vertices;
    my $num_edges = $graph->edges;
    my $diameter = $graph->diameter || 0;
    my $canon_g6 = MyGraphs::graph6_str_to_canonical
      (MyGraphs::Graph_to_graph6_str($graph));
    my $hog = MyGraphs::hog_grep($canon_g6) || "not";
    print "$num_vertices vertices, $num_edges edges diam=$diameter  $hog\n";

    MyGraphs::Graph_run_dreadnaut($graph->is_directed ? $graph->undirected_copy : $graph,
                                  verbose=>0, base=>1);
    # print "vertices: ",join('  ',$graph->vertices),"\n";
    if ($graph->vertices < 200) {
      MyGraphs::Graph_view($graph, synchronous=>0);
    }

    my $d6str = MyGraphs::Graph_to_graph6_str($graph, format=>'digraph6');
    # print Graph::Graph6::HEADER_DIGRAPH6(), $d6str;
    print "\n";

    MyGraphs::Graph_print_tikz($graph);
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # Stanley, binary tree extensions
  require Graph;
  my @graphs;
  foreach my $N (3,4) {
    my $graph = Graph->new;
    $graph->add_edge('e','10');
    foreach my $n (1 .. $N-1) {
      foreach my $aref (balanced_list($n)) {
        foreach my $i (0 .. $#$aref) {
          if (! $aref->[$i]) {
            my @to = (@{$aref}[0..$i-1],
                      1, 0,
                      @{$aref}[$i..$#$aref]);
            $graph->add_edge(join('',@$aref),
                             join('',@to));
          }
        }
        $graph->add_edge(join('',@$aref),
                         join('',1,0,@$aref));

      }
    }
    MyGraphs::Graph_view($graph);
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

