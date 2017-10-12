#!/usr/bin/perl -w

# Copyright 2017 Kevin Ryde
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
use 5.010;
use File::Slurp;
use List::Util 'min','max';
$|=1;

use FindBin;
use lib "$FindBin::Bin/lib";
use MyGraphs;
use Graph::Maker::Crown;

# uncomment this to run the ### lines
use Smart::Comments;

{
  require Graph;
  my $graph = Graph->new(undirected => 1);
  $graph->add_edges([1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 7], [7, 8],
                    [8, 9], [9, 10], [10, 11], [11, 12], [12, 13], [13, 14],
                    [14, 15], [15, 16], [16, 17], [17, 18], [1, 18], [2, 19],
                    [5, 20], [8, 21], [11, 22], [14, 23], [17, 24], [19, 20],
                    [20, 21], [21, 22], [22, 23], [23, 24], [19, 24]);
  MyGraphs::Graph_view($graph);
  exit 0;
}
{
  # counts of dominating sets
  # A287063 a(n) = 4^n - 2^n*(n + 2) + n^2 + n + 3.
  # 1,9,39,183,833,3629 domsets
  #
  # minimal
  # 1,4,5,12,37,98,219,430
  # A289121 a(n) = (8 - 2*n + 11*n^2 - 6*n^3 + n^4)/4.

  require Algorithm::ChooseSubsets;
  my $num_children = 2;
  foreach my $n (1 .. 10) {
    my $graph = Graph::Maker->new('crown', N=>$n, undirected => 1);
    my $name = $graph->get_graph_attribute('name');

    # MyGraphs::Graph_view($graph);
    print "$name\n";

    my @vertices = sort {$a<=>$b} $graph->vertices;
    my $it = Algorithm::ChooseSubsets->new(\@vertices);
    my $count_domsets = 0;
    my $count_minimal_domsets = 0;
    while (my $aref = $it->next) {
      my $any = 0;

      my $is_domset = MyGraphs::Graph_is_domset($graph,$aref) ? 1 : 0;
      # $any ||= $is_domset;
      $count_domsets += $is_domset;

      my $is_minimal_domset = MyGraphs::Graph_is_minimal_domset($graph,$aref)?1:0;
      # $any ||= $is_minimal_domset;
      $count_minimal_domsets += $is_minimal_domset;

      if ($any) {
        my $aref_str = join(',',@$aref);
        printf "%-14s %d %d\n", $aref_str, $is_domset, $is_minimal_domset;
      }
    }
    print "  domsets $count_domsets\n";
    print "  minimal domsets  $count_minimal_domsets\n";
  }
  exit 0;
}

{
  # HOG crowns

  # 2   path-4
  # 3   fork
  # 4   cross
  # 3   H graph
  # 4
  # 4   Ethane

  my @graphs;
  foreach my $n (1 .. 20) {
    my $graph = Graph::Maker->new('crown', N=>$n, undirected=>1);
    if ($n == 4) {
      MyGraphs::Graph_print_tikz($graph);
      MyGraphs::Graph_view($graph);
    }
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
