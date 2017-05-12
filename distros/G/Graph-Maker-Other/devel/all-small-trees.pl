#!/usr/bin/perl -w

# Copyright 2015, 2016 Kevin Ryde
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
use MyGraphs;

{
  # Chung, Graham, Pippenger all small subtrees

  # edges=3, unique
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30
  #
  # edges=4 is 3 subtrees, count 2 with all
  #       *          shown  *            *--*--*--*--*     *
  #       |                 |                              |
  # *--*--*--*--*  *--*--*--*--*         *--*--*--*     *--*--*
  #       |                 |                  |           |
  #       *                 *                  *           *
  # example shown https://hog.grinvin.org/ViewGraphInfo.action?id=792
  # other         https://hog.grinvin.org/ViewGraphInfo.action?id=616
  #
  # edges=5 is 6 subtrees, count 3 with all
  #     *   *  (A,shown)           *   *  (C)         (B)      *   *
  #     |   |                      |   |                       |   |
  # *---*---*---*---*---*  *---*---*---*---*---*   *---*---*---*---*---*
  #    / \                        / \                         / \
  #   *   *                      *   *                       *   *
  # A https://hog.grinvin.org/ViewGraphInfo.action?id=25139
  # B not
  # C not
  #
  # edges=6 is 11 subtrees
  #
  #   *   *     *   *        *   *              *   *        *   *   *
  #    \ /       \ /          \ /                \ /          \ /   /
  #  *--*--*   *--*--*--*   *--*--*--*--*   *--*--*--*--*   *--*---*--*
  #    / \       /
  #   *   *     *
  #                         *                     *
  #                         |                     |
  #  *--*--*--*--*--*    *--*--*--*--*--*   *--*--*--*--*--*
  #
  #     *  *            *     *            *--*
  #     |  |            |     |            |
  #  *--*--*--*--*   *--*--*--*--*   *--*--*--*--*
  #
  # edges=6, 19 of
  # 0-10,1-10,0-11,2-11,3-12,4-12,5-12,0-13,3-13,6-13,7-13,8-13,9-13 [13 edges]
  # 0-10,1-10,2-11,3-11,0-12,4-12,5-12,0-13,2-13,6-13,7-13,8-13,9-13 [13 edges]
  # 0-10,1-10,2-11,3-11,4-12,5-12,6-12,2-13,4-13,7-13,8-13,9-13,10-13 [13 edges]
  # 0-9,1-10,0-11,2-11,2-12,3-12,4-12,1-13,2-13,5-13,6-13,7-13,8-13 [13 edges]
  # 0-9,1-10,0-11,2-11,2-12,3-12,4-12,1-13,5-13,6-13,7-13,8-13,11-13 [13 edges]
  # 0-9,1-10,0-11,2-11,3-12,4-12,5-12,0-13,1-13,3-13,6-13,7-13,8-13 [13 edges]
  # 0-9,1-10,2-11,3-11,0-12,1-12,4-12,4-13,5-13,6-13,7-13,8-13,11-13 [13 edges]
  # 0-9,1-10,2-11,3-11,0-12,2-12,4-12,1-13,2-13,5-13,6-13,7-13,8-13 [13 edges]
  # 0-9,1-10,2-11,3-11,0-12,4-12,5-12,0-13,1-13,2-13,6-13,7-13,8-13 [13 edges]
  # 0-9,1-10,2-11,3-11,0-12,4-12,5-12,1-13,4-13,6-13,7-13,8-13,11-13 [13 edges]
  # 0-9,1-10,2-11,3-11,2-12,4-12,5-12,0-13,1-13,6-13,7-13,8-13,11-13 [13 edges]
  # 0-9,0-10,1-10,1-11,2-11,3-12,4-12,1-13,5-13,6-13,7-13,8-13,12-13 [13 edges]
  # 0-9,0-10,1-10,2-11,3-11,4-12,5-12,0-13,4-13,6-13,7-13,8-13,11-13 [13 edges]
  # 0-9,0-10,1-10,2-11,3-11,4-12,5-12,1-13,6-13,7-13,8-13,11-13,12-13 [13 edges]
  # 0-9,1-10,2-10,1-11,3-11,0-12,4-12,0-13,1-13,5-13,6-13,7-13,8-13 [13 edges]
  # 0-9,1-10,2-10,1-11,3-11,4-12,5-12,0-13,6-13,7-13,8-13,10-13,12-13 [13 edges]
  # 0-8,1-9,2-10,3-11,0-12,1-12,2-12,0-13,3-13,4-13,5-13,6-13,7-13 [13 edges]
  # 0-8,1-9,2-10,3-11,0-12,1-12,4-12,0-13,2-13,3-13,5-13,6-13,7-13 [13 edges]
  # 0-8,1-9,2-10,0-11,3-11,1-12,4-12,0-13,1-13,2-13,5-13,6-13,7-13 [13 edges]
  #
  #           count                2  3
  #           edges    0  1  2  3  4  5   6   7
  my @num_edges_max = (0, 1, 2, 4, 6, 9, 13, 17);
  my @graphs;
  foreach my $num_edges (5) {  # of the subtrees
    my $num_edges_max = $num_edges_max[$num_edges];
    print "edges=$num_edges  <= $num_edges_max\n";
    my @subtree_edge_arefs;
    {
      my $iterator_func = make_tree_iterator_edge_aref
        (num_vertices => $num_edges+1);
      while (my $subtree_edge_aref = $iterator_func->()) {
        push @subtree_edge_arefs, $subtree_edge_aref;
        # print "  want ",edge_aref_string($subtree_edge_aref),"\n";
        # if ($num_edges == 6) {
        #   Graph_Easy_view(edge_aref_to_Graph_Easy($subtree_edge_aref));
        # }
      }
    }
    my $count = 0;
    $| = 1;
    my $iterator_func = make_tree_iterator_edge_aref
      (num_vertices_min => $num_edges+1,
       num_vertices_max => $num_edges_max+1);
  TREE: while (my $edge_aref = $iterator_func->()) {
      $count++;
      # print "$count ($#$edge_aref)\r";
      foreach my $subtree_edge_aref (@subtree_edge_arefs) {
        if (! edge_aref_degrees_allow_subgraph($edge_aref, $subtree_edge_aref)) {
          next TREE;
        }
      }
      foreach my $subtree_edge_aref (@subtree_edge_arefs) {
        if (! edge_aref_is_induced_subgraph($edge_aref, $subtree_edge_aref)) {
          next TREE;
        }
      }
      print "  ",edge_aref_string($edge_aref),"\n";
      # if ($num_edges == 5) {
      #   Graph_Easy_view(edge_aref_to_Graph_Easy($edge_aref));
      # }
      my $easy = edge_aref_to_Graph_Easy($edge_aref);
      $easy->set_attribute (label => "edges=$num_edges");
      push @graphs, $easy;
    }
  }
  hog_searches_html(@graphs);
  exit 0;
}

{
  # Chung and Graham graphs n=6,7 containing all subtrees
  #
  # 1-2,3-4,0-5,3-5,4-5,0-6,1-6,2-6,3-6,4-6,5-6 [11 edges]
  # 3-4,1-5,3-5,2-6,4-6,5-6,0-7,1-7,2-7,3-7,4-7,5-7,6-7 [13 edges]

  my @graphs;
  my @g6_strs;
  require Graph;
  require Graph::Writer::Graph6;
  my $writer = Graph::Writer::Graph6->new;
  {
    # n=6
    # https://hog.grinvin.org/ViewGraphInfo.action?id=21128
    #         2    6
    #       / | \ / \
    #      1-----4---7
    #       \ | / \
    #         3----5
    my $graph = Graph->new(undirected=>1);
    $graph->add_edges(1,2, 1,3, 1,4,
                      2,3, 2,4,
                      3,2, 3,4, 3,5,
                      4,5, 4,6, 4,7,
                      6,7);
    push @graphs, $graph;
    open my $fh, '>', \$g6_strs[0] or die;
    $writer->write_graph($graph, $fh);
  }
  {
    # n=7
    # https://hog.grinvin.org/ViewGraphInfo.action?id=21130
    #         3---5
    #       / | \ |
    #      1---__\|
    #      |  |__ 6---8
    #      2---  /|
    #       \ | / |
    #         4---7
    my $graph = Graph->new(undirected=>1);
    $graph->add_edges(1,2, 1,3, 1,6,
                      2,4, 2,6,
                      3,4, 3,5, 3,6,
                      4,6, 4,7,
                      5,6, 6,7, 6,8);
    push @graphs, $graph;
    open my $fh, '>', \$g6_strs[1] or die;
    $writer->write_graph($graph, $fh);
  }

  foreach my $g6_str (@g6_strs) {
    $g6_str = graph6_str_to_canonical($g6_str);
    my $edge_aref = [];
    Graph::Graph6::read_graph(str => $g6_str,
                              edge_aref => $edge_aref) or die;
    print edge_aref_string($edge_aref),"\n";
    push @graphs, $edge_aref;
  }

  hog_searches_html(@graphs);
  exit 0;
}

{
  # Chung and Graham graph containing all subtrees
  my @graphs;
  foreach my $str (
                   # # [11 edges]  vertices=7
                   # 
                   # # hog not
                   # '0-4,1-4,0-5,1-5,2-5,0-6,1-6,2-6,3-6,4-6,5-6',
                   # 
                   # # hog not
                   # '0-4,1-4,0-5,2-5,3-5,0-6,1-6,2-6,3-6,4-6,5-6',
                   # 
                   # # https://hog.grinvin.org/ViewGraphInfo.action?id=784
                   # '0-4,1-4,0-5,2-5,4-5,0-6,1-6,2-6,3-6,4-6,5-6',
                   # 
                   # # hog not
                   # '0-3,1-4,0-5,1-5,2-5,0-6,1-6,2-6,3-6,4-6,5-6',
                   # 
                   # # hog not
                   # '0-3,1-4,0-5,1-5,3-5,0-6,1-6,2-6,3-6,4-6,5-6',
                   # 
                   # # hog not, this one from Chung and Graham
                   # '0-3,1-4,0-5,2-5,3-5,0-6,1-6,2-6,3-6,4-6,5-6',
                   # 
                   # # hog not
                   # '0-3,0-4,1-4,1-5,2-5,0-6,1-6,2-6,3-6,4-6,5-6',


                   # hog not
                   '0-4,0-5,1-5,0-6,1-6,2-6,0-7,1-7,2-7,3-7,4-7,5-7,6-7',

                   '0-4,0-5,1-5,1-6,2-6,3-6,0-7,1-7,2-7,3-7,4-7,5-7,6-7',
                   '0-4,0-5,1-5,1-6,2-6,4-6,0-7,1-7,2-7,3-7,4-7,5-7,6-7',
                   '0-4,1-5,2-5,0-6,1-6,2-6,0-7,1-7,2-7,3-7,4-7,5-7,6-7',
                   '0-4,1-5,2-5,0-6,1-6,3-6,0-7,1-7,2-7,3-7,4-7,5-7,6-7',
                   '0-4,1-5,2-5,1-6,2-6,3-6,0-7,1-7,2-7,3-7,4-7,5-7,6-7',
                   '0-4,1-5,2-5,0-6,1-6,4-6,0-7,1-7,2-7,3-7,4-7,5-7,6-7',
                   '0-4,1-5,2-5,0-6,3-6,4-6,0-7,1-7,2-7,3-7,4-7,5-7,6-7',
                   '0-4,1-5,2-5,0-6,1-6,5-6,0-7,1-7,2-7,3-7,4-7,5-7,6-7',
                   '0-4,1-5,2-5,0-6,3-6,5-6,0-7,1-7,2-7,3-7,4-7,5-7,6-7',
                   '0-4,1-5,2-5,1-6,3-6,5-6,0-7,1-7,2-7,3-7,4-7,5-7,6-7',
                   '0-3,1-4,2-5,0-6,1-6,2-6,0-7,1-7,2-7,3-7,4-7,5-7,6-7',
                   '0-3,1-4,2-5,0-6,1-6,3-6,0-7,1-7,2-7,3-7,4-7,5-7,6-7',
                   # 13 of
                  ) {
    push @graphs, edge_aref_string_to_edge_aref($str);
  }
  hog_searches_html(@graphs);
  exit 0;

  sub edge_aref_string_to_edge_aref {
    my ($str) = @_;
    return [ map {[split /-/, $_]} split /,/, $str ];
  }
}




{
  # graph G*(n) with all small subtrees

  # d(k) = floor((n+k-1)/k);
  # Gedges(n) = 1/2*sum(k=1,n+1, ceil(n/k));
  # ceil(vector(20,n,Gedges(n)))

  # edges=1  <= 1
  # >A /usr/bin/nauty-geng -cd1D1 n=2 e=1
  # >Z 1 graphs generated in 0.00 sec
  #   0-1 [1 edges]  vertices=2
  # edges=2  <= 2
  # >A /usr/bin/nauty-geng -cd1D2 n=3 e=2
  # >Z 1 graphs generated in 0.00 sec
  #   0-2,1-2 [2 edges]  vertices=3
  #
  # edges=3  <= 4
  # >A /usr/bin/nauty-geng -cd1D3 n=4 e=3-4
  # >Z 4 graphs generated in 0.00 sec
  #   0-2,0-3,1-3,2-3 [4 edges]  vertices=4
  #   https://hog.grinvin.org/ViewGraphInfo.action?id=646
  # 2 subtrees, 4-path, 4-star=claw
  #                    *                     *
  #                    |          graph    / |
  #   *--*--*--*    *--*--*               *--*--*
  #                     
  # edges=4  <= 6
  # >A /usr/bin/nauty-geng -cd1D4 n=5 e=4-6
  # >Z 13 graphs generated in 0.00 sec
  #   0-3,1-3,0-4,1-4,2-4,3-4 [6 edges]  vertices=5
  #     https://hog.grinvin.org/ViewGraphInfo.action?id=1026  dart graph
  #   0-2,1-3,0-4,1-4,2-4,3-4 [6 edges]  vertices=5
  #     https://hog.grinvin.org/ViewGraphInfo.action?id=776   bowtie/hourglass
  # 3 subtrees
  #   *--*--*--*--*
  #                   
  #      *            *   * bowtie        0     dart 
  #      |            |\ /|              / \
  #   *--*--*--*      | * |             3---4--2
  #                   |/ \|              \ /
  #      *            *   *               1
  #      |      
  #   *--*--*
  #      |      
  #      *      
  #
  # edges=5  <= 8
  # >A /usr/bin/nauty-geng -cd1D5 n=6 e=5-8
  # >Z 60 graphs generated in 0.00 sec
  #   0-3,0-4,1-4,0-5,1-5,2-5,3-5,4-5 [8 edges]  vertices=6 
  #     https://hog.grinvin.org/ViewGraphInfo.action?id=860
  #   0-3,1-4,2-4,0-5,1-5,2-5,3-5,4-5 [8 edges]  vertices=6 [Shown]
  #     hog not
  #     https://hog.grinvin.org/ViewGraphInfo.action?id=21132
  # 6 subtrees
  #       
  # 1-3,2-4,3-4,0-5,1-5,2-5,3-5,4-5 [8 edges]  vertices=6
  # 2-3,0-4,1-4,0-5,1-5,2-5,3-5,4-5 [8 edges]  vertices=6 [Shown]
  #       *   *          *     *
  #      / \ /           | \ / |
  #     *---*            *--*--*
  #      \ / \           | /
  #       *---*          *
  #   
  #
  # edges=6  <= 11
  # >A /usr/bin/nauty-geng -cd1D6 n=7 e=6-11
  # >Z 488 graphs generated in 0.00 sec
  #   2-4,3-4,1-5,2-5,3-5,0-6,1-6,2-6,3-6,4-6,5-6 [11 edges]  vertices=7
  #   2-3,3-4,0-5,1-5,4-5,0-6,1-6,2-6,3-6,4-6,5-6 [11 edges]  vertices=7
  #   1-4,3-4,2-5,3-5,4-5,0-6,1-6,2-6,3-6,4-6,5-6 [11 edges]  vertices=7
  #   1-3,2-4,0-5,3-5,4-5,0-6,1-6,2-6,3-6,4-6,5-6 [11 edges]  vertices=7
  #   1-2,3-4,2-5,3-5,4-5,0-6,1-6,2-6,3-6,4-6,5-6 [11 edges]  vertices=7
  #   1-2,3-4,0-5,3-5,4-5,0-6,1-6,2-6,3-6,4-6,5-6 [11 edges]  vertices=7 [Shown]
  #   2-3,0-4,2-4,1-5,3-5,0-6,1-6,2-6,3-6,4-6,5-6 [11 edges]  vertices=7
  #   7 of
  #
  # edges=7  <= 13
  # >A /usr/bin/nauty-geng -cd1D7 n=8 e=7-13
  # >Z 4271 graphs generated in 0.01 sec
  #   3-4,1-5,3-5,2-6,4-6,5-6,0-7,1-7,2-7,3-7,4-7,5-7,6-7 [13 edges]  vertices=8 [shown]
  #   2-4,3-5,4-5,0-6,1-6,3-6,0-7,1-7,2-7,3-7,4-7,5-7,6-7 [13 edges]  vertices=8
  #   2-4,3-5,4-5,1-6,2-6,3-6,0-7,1-7,2-7,3-7,4-7,5-7,6-7 [13 edges]  vertices=8
  #
  #   0-4,0-5,1-5,0-6,1-6,2-6,0-7,1-7,2-7,3-7,4-7,5-7,6-7 [13 edges]  vertices=8
  #   0-4,0-5,1-5,1-6,2-6,3-6,0-7,1-7,2-7,3-7,4-7,5-7,6-7 [13 edges]  vertices=8
  #   0-4,0-5,1-5,1-6,2-6,4-6,0-7,1-7,2-7,3-7,4-7,5-7,6-7 [13 edges]  vertices=8
  #   0-4,1-5,2-5,0-6,1-6,2-6,0-7,1-7,2-7,3-7,4-7,5-7,6-7 [13 edges]  vertices=8
  #   0-4,1-5,2-5,0-6,1-6,3-6,0-7,1-7,2-7,3-7,4-7,5-7,6-7 [13 edges]  vertices=8
  #   0-4,1-5,2-5,1-6,2-6,3-6,0-7,1-7,2-7,3-7,4-7,5-7,6-7 [13 edges]  vertices=8
  #   0-4,1-5,2-5,0-6,1-6,4-6,0-7,1-7,2-7,3-7,4-7,5-7,6-7 [13 edges]  vertices=8
  #   0-4,1-5,2-5,0-6,3-6,4-6,0-7,1-7,2-7,3-7,4-7,5-7,6-7 [13 edges]  vertices=8
  #   0-4,1-5,2-5,0-6,1-6,5-6,0-7,1-7,2-7,3-7,4-7,5-7,6-7 [13 edges]  vertices=8
  #   0-4,1-5,2-5,0-6,3-6,5-6,0-7,1-7,2-7,3-7,4-7,5-7,6-7 [13 edges]  vertices=8
  #   0-4,1-5,2-5,1-6,3-6,5-6,0-7,1-7,2-7,3-7,4-7,5-7,6-7 [13 edges]  vertices=8
  #   0-3,1-4,2-5,0-6,1-6,2-6,0-7,1-7,2-7,3-7,4-7,5-7,6-7 [13 edges]  vertices=8
  #   0-3,1-4,2-5,0-6,1-6,3-6,0-7,1-7,2-7,3-7,4-7,5-7,6-7 [13 edges]  vertices=8
  # 13 of

  #                    0  1  2  3  4  5   6   7
  my @num_edges_max = (0, 1, 2, 4, 6, 8, 11, 13);
  my @graphs;
  foreach my $num_edges (5,
                         # 1 .. 5
                        ) {
    my $num_edges_max = $num_edges_max[$num_edges];
    print "edges=$num_edges  <= $num_edges_max\n";
    my @subtree_edge_arefs;
    {
      my $iterator_func = make_tree_iterator_edge_aref
        (num_vertices => $num_edges+1);
      while (my $subtree_edge_aref = $iterator_func->()) {
        push @subtree_edge_arefs, $subtree_edge_aref;
      }
      my $num_subtrees = scalar(@subtree_edge_arefs);
      print "  $num_subtrees subtrees\n";
      if ($num_subtrees < 8) {
        foreach my $subtree_edge_aref (@subtree_edge_arefs) {
          print "    ",edge_aref_string($subtree_edge_aref),"\n";
          if ($num_edges == 3) {
            Graph_Easy_view(edge_aref_to_Graph_Easy($subtree_edge_aref));
          }
        }
      }
    }
    my $count = 0;
    $| = 1;
    my $iterator_func = make_graph_iterator_edge_aref
      (num_vertices => $num_edges+1,
       num_edges_min => $num_edges,
       num_edges_max => $num_edges_max);
  TREE: while (my $edge_aref = $iterator_func->()) {
      $count++;
      print "$count ($#$edge_aref)\r";
      foreach my $subtree_edge_aref (@subtree_edge_arefs) {
        if (! edge_aref_is_subgraph($edge_aref, $subtree_edge_aref)) {
          next TREE;
        }
      }
      my $easy = edge_aref_to_Graph_Easy($edge_aref);
      my $num_vertices = $easy->vertices;
      print "  ",edge_aref_string($edge_aref),"  vertices=$num_vertices\n";
      # if ($num_edges == 5) {
      #   Graph_Easy_view(edge_aref_to_Graph_Easy($edge_aref));
      # }
      $easy->set_attribute (label => "vertices=$num_vertices");
      push @graphs, $easy;
    }
  }
  hog_searches_html(@graphs);
  exit 0;
}




{
  # subtrees n=7 edges
  # hog not
  my $easy = Graph::Easy->new (undirected => 1);
  $easy->add_edge(0,1);
  $easy->add_edge(1,2);
  $easy->add_edge(2,3);
  $easy->add_edge(3,4);$easy->add_edge(3,5);
  $easy->add_edge(5,6);$easy->add_edge(5,7);
  $easy->add_edge(5,8);$easy->add_edge(5,9);
  $easy->add_edge(5,10);$easy->add_edge(5,11);
  $easy->add_edge(10,12);
  $easy->add_edge(11,13);$easy->add_edge(11,14);$easy->add_edge(11,15);
  $easy->add_edge(15,16);$easy->add_edge(15,17);
  hog_searches_html($easy);
  exit 0;
}
{
  # subtrees n=6 edges
  # hog not
  my $easy = Graph::Easy->new (undirected => 1);
  $easy->add_edge(0,1);
  $easy->add_edge(1,2);
  $easy->add_edge(2,3);$easy->add_edge(2,4);
  $easy->add_edge(4,5);$easy->add_edge(4,6);
  $easy->add_edge(6,7);$easy->add_edge(6,8);$easy->add_edge(6,9);
  $easy->add_edge(6,10);$easy->add_edge(6,11);
  $easy->add_edge(10,12);
  $easy->add_edge(11,13);
  hog_searches_html($easy);
  exit 0;
}
