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
use Graph;
use List::Util 'min';

use FindBin;
use lib "$FindBin::Bin/../devel/lib";
use MyGraphs;
$|=1;

# uncomment this to run the ### lines
# use Smart::Comments;

{
  # Stable Equimatchable N=10
  my @graphs = (
                # HOG not
                ':I`EKWp`]~',
                ':I`EKWolYv',

                # Complete Tree 3,2
                # https://hog.grinvin.org/ViewGraphInfo.action?id=492
                ':I`EKIS`]~',

                # star-10
                ':I`ACGO`AF',
               );
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  require Graph::Maker::BalancedTree;
  my @graphs;

  # n=7 complete binary tree
  # https://hog.grinvin.org/ViewGraphInfo.action?id=498
  #
  my $graph = Graph::Maker->new('balanced_tree',
                                fan_out => 2, height => 3,
                                undirected => 1);
  # MyGraphs::Graph_view($graph);
  push @graphs, $graph;
  MyGraphs::Graph_is_isomorphic
      ($graph, MyGraphs::Graph_from_vpar([undef, 0, 1, 2, 2, 1, 5, 5],
                                         undirected=>1)) or die;
  {
    # n=8
    # https://hog.grinvin.org/ViewGraphInfo.action?id=31053
    my $graph = $graph->copy;
    $graph->add_edge ('L', 3);
    MyGraphs::Graph_is_isomorphic
        ($graph, MyGraphs::Graph_from_vpar([undef, 0, 1, 2, 2, 2, 1, 6, 6],
                                           undirected=>1)) or die;
    push @graphs, $graph;
  }
  {
    # n=9  2,4
    # https://hog.grinvin.org/ViewGraphInfo.action?id=31114
    my $graph = $graph->copy;
    $graph->add_edge ('L1', 3);
    $graph->add_edge ('L2', 3);
    MyGraphs::Graph_is_isomorphic
        ($graph, MyGraphs::Graph_from_vpar([undef, 0, 1, 2, 2, 2, 2, 1, 7, 7],
                                           undirected=>1)) or die;
    push @graphs, $graph;
  }
  {
    # n=9   3,3
    # https://hog.grinvin.org/ViewGraphInfo.action?id=672
    my $graph = $graph->copy;
    $graph->add_edge ('L1', 2);
    $graph->add_edge ('L2', 3);
    MyGraphs::Graph_is_isomorphic
        ($graph, MyGraphs::Graph_from_vpar([undef, 0, 1, 2, 2, 2, 1, 6, 6, 6],
                                           undirected=>1)) or die;
    push @graphs, $graph;
  }
  {
    # n=10 Complete 3,2
    # https://hog.grinvin.org/ViewGraphInfo.action?id=492
    my $graph = $graph->copy;
    $graph->add_edge ('T1', 1);
    $graph->add_edge ('T2', 'T1');
    $graph->add_edge ('T3', 'T1');
    push @graphs, $graph;
  }

  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # n=15 smallest tree edge stable not vertex stable
  # HOG not
  #            1
  #        /       \
  #      2          9
  #    / | \      / | \
  #   3  7  8   14  15 10
  #   |                 |
  #   4                11
  #  / \              /  \
  # 5   6           12    13
  MyGraphs::hog_searches_html
      (MyGraphs::Graph_from_vpar([undef, 0, 1, 2, 3, 4, 4, 2, 2, 1, 9, 10, 11, 11, 9, 9],
                                 undirected=>1)) or die;
  exit 0;
}
{
  # :@                   0 empty
  # :An                  1 path-2
  # :Bc                  2 path-3  >>graph6<<BW  >>graph6<<Bw
  # :Ccf                 3 claw    >>graph6<<CF
  # :FaGnK               6  n=7
  # :I`ACySf]~           8  n=10

  # state, but not edge stable equimatchable
  # :DaYj                4
  # :EaIm~               5  n=6
  # :H`ASxqlZ            7  n=9
  # :I`ASxol]~           9  n=10
  # :L`ASxol]|lY         10 n=13  HOG not
  # :O`ASxqlYE\Yrvn      11 n=16  HOG not

  my @graphs = (':@',
                ':An',
                ':Bc',
                ':Ccf',
                ':FaGnK',
                ':I`ACySf]~',
               );
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

