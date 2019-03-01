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

use Graph::Maker::ExcessConfigurations;

# uncomment this to run the ### lines
# use Smart::Comments;


{
  my @graphs;
  foreach my $N (
                 3,4,5
                ) {
    print "N=$N\n";
    my $graph = Graph::Maker->new
      ('excess_configurations',
       N            => $N,
       undirected => 0,
      );
    push @graphs, $graph;
    print "directed ",$graph->is_directed,"\n";
    $graph->set_graph_attribute (flow => 'east');
    print $graph->get_graph_attribute('name'),"\n";
    my $num_vertices = $graph->vertices;
    my $num_edges = $graph->edges;
    my $canon_g6 = MyGraphs::graph6_str_to_canonical
      (MyGraphs::Graph_to_graph6_str($graph));
    my $hog = MyGraphs::hog_grep($canon_g6) || "not";
    print "$num_vertices vertices, $num_edges edges  $hog\n";

    # MyGraphs::Graph_run_dreadnaut($graph->undirected_copy,
    #                               verbose=>0, base=>1);
    # print "vertices: ",join('  ',$graph->vertices),"\n";
    if ($graph->vertices < 100) {
      MyGraphs::Graph_view($graph, synchronous=>0);
    }
    MyGraphs::Graph_print_tikz($graph);

    my $d6str = MyGraphs::Graph_to_graph6_str($graph, format=>'digraph6');
    # print Graph::Graph6::HEADER_DIGRAPH6(), $d6str;
    print "\n";
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # number of vertices
  # 1,2,4,7,12,19,30,45,67,97,139,
  # A000070 cumulative partitions
  # Euler transform of 2, 1, 1, 1, 1, 1, 1
  #
  # number of edges
  # 0,1,3,8,17,34,62,109,182,296,466,719,1084,1609,2347,3380,4802,6750,9384,12929,17650,
  # A029859 Euler transform 3 2 1 1 1 1 1 1...
  # first diffs
  # 1, 2, 5, 9, 17, 28, 47
  # A000097 partitions with two kinds 1s, two kinds 2s
  # Euler transform of 2 2 1 1 1 1 1
  # numbpart(3) == 3
  # partitions(3)
  # [1,1,1]     [1a,1a,1a] [1a,1a,1b] [1a,1b,1b] [1b,1b,1b] 
  # [1,2]       [1a,2a] [1b,2a]  [1a,2b] [1b,2b]       
  # [3]         [3]       total 9
  # partition r,s sum r+s+1    
  # partition r -> r+1    each distinct term
  # partition new 1       1
  #
  # vector(6,n, numbpart(n))
  # vector(8,n,n+=3; vecsum(apply(p->my(t=length(Set(Vec(p))));t*(t+1)/2,partitions(n))) - numbpart(n+1))
  # vector(8,n, vecsum(apply(p->my(t=length(Set(Vec(p))));t*(t+1)/2,partitions(n))))
  # vector(6,n, vecsum(apply(p->length(Set(Vec(p)))+1,partitions(n))))
  # = numbpart
  # vector(6,n, vecsum(apply(p->length(Set(Vec(p))),partitions(n))))
  # total distinct = numbpart
  # vector(6,n, vecsum(apply(length,partitions(n))))
  # 0,1,3,6,12,20
  # A006128 num parts in all partitions length n
  #
  # vector(16,n, #select(p->Vec(p)==Set(p), partitions(n)))
  # A000009 partitions into distinct parts
  # vector(16,n, vecsum(apply(p->if(Vec(p)==Set(p),length(p)), partitions(n))))
  # A015723 total parts in partitions with distinct parts

  my @graphs;
  foreach my $N (0 .. 20) {
    my $graph = Graph::Maker->new ('excess_configurations', N => $N);
    my $num_vertices = $graph->vertices;
    my $num_edges = $graph->edges;
    # print "$num_vertices,";
    print "$num_edges,";
  }
  exit 0;
}
{
  my $graph = Graph::Maker->new
    ('excess_configurations',
     N            => 6,
    );
  MyGraphs::Graph_view($graph, synchronous=>1);
  exit 0;
}

CHECK {
  ! Scalar::Util::looks_like_number('1,1') or die;
}
