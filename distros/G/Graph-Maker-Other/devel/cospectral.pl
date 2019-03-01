#!/usr/bin/perl -w

# Copyright 2018 Kevin Ryde
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
use List::Util 'min';

use FindBin;
use lib "$FindBin::Bin/../devel/lib";
use MyGraphs;
$|=1;

# uncomment this to run the ### lines
use Smart::Comments;


{
  # cycle and singleton
  # https://hog.grinvin.org/ViewGraphInfo.action?id=196

  require Graph::Maker::Cycle;
  my $graph = Graph::Maker->new('cycle', N=>4, undirected=>1);
  $graph->add_vertex(5);
  MyGraphs::hog_searches_html($graph);
  exit 0;
}

{
  # Abbe Mowshowitz, "The Characteristic Polynomial of a Graph", Journal of
  # Combinatorial Theory, series B, volume 12, 1972, pages 177-193.
  # https://www.sciencedirect.com/science/article/pii/0095895672900238
  #
  # Figure 1.
  # HOG https://hog.grinvin.org/ViewGraphInfo.action?id=1252
  # Parapluie Graph
  #
  #      7     5
  #     /    /  \
  #    6----1----2
  #         | \  |
  #         |  \ |
  #         |   \|
  #         3----4
  #
  # H digraph of k vertices.
  # f_H({i1,...,ir}) = number of collections of disjoint directed cycles in H
  # of lengths i1,...,ir.  Each i >= 1 and sum(i1,...,ir) = k.
  #
  # D digraph of n vertices.  k'th coeff of charpoly
  # a_k = sum prod(j=1,r, (-1)^(i_j+1) ) * f_D({i1,...,ir})
  # where sum over all rank r partitions {i1,...,ir}
  #
  # a_7 = -2f(2,5) + 2f(2,2,3) - 4f(3,4) + 2f(7)
  #           =0        =1          =0        =0
  # f(2) = 9    num edges
  # f(3) = 3    triangles
  # f(2,3) = 5    = 1+2+2
  # f(2,2) = 17
  # f(4) = 2    4-cycles
  #
  # m = [0,1,1,1,1,1,0;1,0,0,1,1,0,0;1,0,0,1,0,0,0;1,1,1,0,0,0,0;1,1,0,0,0,0,0;1,0,0,0,0,0,1;0,0,0,0,0,1,0]
  # p = charpoly(m)
  # p == x^7 - 9*x^5 - 6*x^4 + 13*x^3 + 8*x^2 - 4*x - 2
  # factor(p*I)
  # p == (x^2 + x - 1) * (x^5 - x^4 - 7*x^3 + 6*x + 2)
  # poldisc(x^2 + x - 1) == 5
  # polroots(x^5 - x^4 - 7*x^3 + 6*x + 2)

  require Graph;
  my $graph = Graph->new (undirected => 1);
  $graph->add_path(7,6,1,5,2,1,3,4,1,2,4);
  # MyGraphs::Graph_view($graph);
  MyGraphs::Graph_print_adjacency_matrix($graph); print "\n";
  MyGraphs::hog_searches_html($graph);
  exit 0;
}

{
  # geng regular graphs

  my $limit = 12;
  my $connected = '-c';
#  $connected = '';

  my $g6_filename = '/tmp/x.g6';
  unlink $g6_filename;
  foreach my $n (1 .. $limit) {
    foreach my $d (1 .. $n) {
      my $command = "nauty-geng $connected -d$d -D$d $n >>$g6_filename";
      print "$command\n";
      system($command);
    }
  }
  system("nauty-labelg $g6_filename >/tmp/temp && mv /tmp/temp $g6_filename");
  system("wc -l $g6_filename");

  # open my $fh, '<', $g6_filename or die;
  # while (defined (my $str = readline $fh)) {
  #   my $graph = MyGraphs::Graph_from_graph6_str($str);
  #   MyGraphs::Graph_print_adjacency_matrix($graph); print ",\n";
  # }

  my $gp_filename = '/tmp/x.gp';
  system("$FindBin::Bin/graph6-to-gp-adjacency.pl <$g6_filename >$gp_filename");

  exit 0;
}

{
  # geng all graphs

  my $limit = 9;
  my $g6_filename = '/tmp/x.g6';
  unlink $g6_filename;

  my $connected = '-c';
  $connected = '';

  foreach my $n (1 .. $limit) {
    my $command = "nauty-geng $connected $n >>$g6_filename";
    print "$command\n";
    system($command);
  }
  system("nauty-labelg $g6_filename >/tmp/temp && mv /tmp/temp $g6_filename");
  system("wc -l $g6_filename");

  my $gp_filename = '/tmp/x.gp';
  system("$FindBin::Bin/graph6-to-gp-adjacency.pl <$g6_filename >$gp_filename");

  exit 0;
}

{
  # Brouwer and Haemers, "Spectra of Graphs", page 14
  # example regular cospectrals
  #
  # I{cBIkkFG
  # Itp?W[r\?
  #
  # complements cospectral iff originals cospectral
  # I|qAzg\Jg
  # I}aJyWxLW


  # GP-DEFINE  a1=[0,1,0,0,0,1,1,0,1,0;1,0,1,0,0,0,1,1,0,0;0,1,0,1,0,0,0,1,0,1;0,0,1,0,1,0,1,0,0,1;0,0,0,1,0,1,0,0,1,1;1,0,0,0,1,0,0,1,1,0;1,1,0,1,0,0,0,0,1,0;0,1,1,0,0,1,0,0,0,1;1,0,0,0,1,1,1,0,0,0;0,0,1,1,1,0,0,1,0,0]
  # GP-DEFINE  a2=[0,1,0,0,0,1,1,0,0,1;1,0,1,0,0,0,1,1,0,0;0,1,0,1,0,0,0,1,1,0;0,0,1,0,1,0,1,0,1,0;0,0,0,1,0,1,0,0,1,1;1,0,0,0,1,0,0,1,0,1;1,1,0,1,0,0,0,0,1,0;0,1,1,0,0,1,0,0,0,1;0,0,1,1,1,0,1,0,0,0;1,0,0,0,1,1,0,1,0,0]
  # GP-Test  a1 != a2
  # GP-Test  charpoly(a1) == charpoly(a2)
  # GP-Test  poldisc(x^2 + x - 4) == 17
  # charpoly(a1)
  # polroots(charpoly(a1))
  # factor(charpoly(a1))
  # 4, 1, -1,-1,-1,-1, +/-sqrt5, (1+/-sqrt17)/2

  my @graphs;
  {
    #  1-------2-------3
    #  |               |
    #  |    7     8    |
    #  |               |
    #  |    9    10    |
    #  |               |
    #  4-------5-------6
    require Graph;
    my $graph = Graph->new (undirected => 1);
    $graph->add_cycle(1,2,3,4,5,6);
    $graph->add_cycle(2,7,9,5,10,8);
    $graph->add_cycle(1,7,9); $graph->add_cycle(3,8,10);
    $graph->add_path(7,4,10); $graph->add_path(8,6,9);
    # MyGraphs::Graph_view($graph);
    push @graphs, $graph;
    print MyGraphs::Graph_is_regular($graph),"\n";
    MyGraphs::Graph_print_adjacency_matrix($graph); print "\n";
    print MyGraphs::graph6_str_to_canonical
      (MyGraphs::Graph_to_graph6_str($graph));
  }
  {
    #  1-------2-------3
    #  |               |
    #  |    7     8    |
    #  |               |
    #  |    9    10    |
    #  |               |
    #  4-------5-------6
    require Graph;
    my $graph = Graph->new (undirected => 1);
    $graph->add_cycle(1,2,3,4,5,6);
    $graph->add_cycle(2,7,9,5,10,8);
    $graph->add_cycle(4,7,9); $graph->add_cycle(6,8,10);
    $graph->add_path(7,1,10); $graph->add_path(8,3,9);
    # MyGraphs::Graph_view($graph);
    push @graphs, $graph;
    print MyGraphs::Graph_is_regular($graph),"\n";
    MyGraphs::Graph_print_adjacency_matrix($graph); print "\n";
    print MyGraphs::Graph_is_regular($graph),"\n";
    print MyGraphs::graph6_str_to_canonical
      (MyGraphs::Graph_to_graph6_str($graph));

  }
  die if MyGraphs::Graph_is_isomorphic($graphs[0],$graphs[1]);
  {
    my $g = $graphs[1]->copy;
    $g->delete_edge(1,10); $g->add_edge(1,9);
    $g->delete_edge(3,9); $g->add_edge(3,10);

    $g->delete_edge(4,9); $g->add_edge(4,10);
    $g->delete_edge(6,10); $g->add_edge(6,9);
    $g eq $graphs[0] or die;
  }

  print "complements\n";
  foreach my $i (0,1) {
    my $graph = $graphs[$i];
    $graph = $graph->complement;
    push @graphs, $graph;
    print MyGraphs::graph6_str_to_canonical
      (MyGraphs::Graph_to_graph6_str($graph));
  }


  {
    # third
    my $graph = MyGraphs::Graph_from_graph6_str('>>graph6<<ItsI@KfT_');
    push @graphs, $graph;
  }
  {
    # fourth
    my $graph = MyGraphs::Graph_from_graph6_str('>>graph6<<IukH@LFT_');
    push @graphs, $graph;
    MyGraphs::Graph_print_tikz($graph);
  }

  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
