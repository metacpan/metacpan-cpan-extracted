#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017, 2018, 2019, 2020, 2021 Kevin Ryde
#
# This file is part of Graph-Maker-Other.
#
# This file is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# This file is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Maker-Other.  See the file COPYING.  If not, see
# <http://www.gnu.org/licenses/>.


# cf A178522 series reduced row counts
#    A178523 series reduced sum depths
#    A178524 series reduced leaf count at depth k
#    A178525 series reduced sum of costs
#    A180566 pairs at distance k

use strict;
use 5.004;
use Test;
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
# use Smart::Comments;

plan tests => 1661;


require Graph::Maker::FibonacciTree;

# Return Fibonacci number F(n), starting F(0)=0 and F(1)=1 in the usual way.
sub F {
  my ($n) = @_;
  if ($n < 0) { return undef; }
  my $a = 0;
  my $b = 1;
  for (1 .. $n) {
    ($a, $b) = ($b, $a+$b);
  }
  return $a;
}
ok(F(0), 0);
ok(F(1), 1);
ok(F(2), 1);
ok(F(3), 2);
ok(F(4), 3);
ok(F(5), 5);
ok(F(6), 8);

sub num_children {
  my ($graph, $v) = @_;
  return scalar(grep {$_ > $v} $graph->neighbours($v));
}

sub stringize_sorted {
  my ($graph) = @_;
  my @edges = $graph->edges;
  if (! @edges) {
    return join(',',$graph->vertices);
  }
  @edges = map { $_->[0] > $_->[1] ? [ $_->[1], $_->[0] ] : $_ } @edges;
  @edges = sort {$a->[0] <=> $b->[0] || $a->[1] <=> $b->[1]} @edges;
  return join(',', map {$_->[0].'='.$_->[1]} @edges);
}


#------------------------------------------------------------------------------
{
  my $want_version = 18;
  ok ($Graph::Maker::FibonacciTree::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::FibonacciTree->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::FibonacciTree->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::FibonacciTree->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# direction_type

foreach my $series_reduced (0, 1) {
  foreach my $leaf_reduced (1, 1) {
    foreach my $height (0 .. 8) {
      {
        my $graph = Graph::Maker->new('fibonacci_tree',
                                      height => $height,
                                      leaf_reduced => $leaf_reduced,
                                      series_reduced => $series_reduced,
                                      direction_type => 'bigger');
        foreach my $edge ($graph->edges) {
          my ($from,$to) = @$edge;
          ok ($from < $to, 1);
        }

        my $graph2 = Graph::Maker->new('fibonacci_tree',
                                       height => $height,
                                       leaf_reduced => $leaf_reduced,
                                       series_reduced => $series_reduced,
                                       direction_type => 'child');
        ok ($graph->eq($graph2)?1:0, 1);
      }
      {
        my $graph = Graph::Maker->new('fibonacci_tree',
                                      height => $height,
                                      leaf_reduced => $leaf_reduced,
                                      series_reduced => $series_reduced,
                                      direction_type => 'smaller');
        foreach my $edge ($graph->edges) {
          my ($from,$to) = @$edge;
          ok ($from > $to, 1);
        }

        my $graph2 = Graph::Maker->new('fibonacci_tree',
                                       height => $height,
                                       leaf_reduced => $leaf_reduced,
                                       series_reduced => $series_reduced,
                                       direction_type => 'parent');
        ok ($graph->eq($graph2)?1:0, 1);
      }
    }
  }
}


#------------------------------------------------------------------------------
# full tree

{
  #         1            per POD
  #       /   \          height => 4
  #     2       3
  #    / \      |
  #   4   5     6
  #  / \  |    / \
  # 7  8  9  10   11

  my $graph = Graph::Maker->new('fibonacci_tree',
                                height => 4,
                                undirected => 1);
  ok (stringize_sorted($graph),
      "1=2,1=3,2=4,2=5,3=6,4=7,4=8,5=9,6=10,6=11");
}

{
  # Hofstadter as per Tognetti, Winley and van Ravenstein
  #
  #                      1
  #                      |
  #                      2
  #                      |
  #                  ____3____
  #               __/         \___
  #           _ 4                  5
  #         _/    \_               |
  #       6          7           _ 8 _
  #     /   \        |        __/     \__
  #    9     10     11      12           13     F(8)=21 total
  #   /\      |     /\      /\            |
  # 14  15   16   17  18  19  20         21     F(6)=8 leaf

  # num children 1, 1, 2, 2,1, 2,1,2,2,1

  my $graph = Graph::Maker->new('fibonacci_tree',
                                height => 5,
                                undirected => 1);
  ok (stringize_sorted($graph),
      "1=2,1=3,2=4,2=5,3=6,4=7,4=8,5=9,6=10,6=11,"
      . "7=12,7=13,8=14,9=15,9=16,10=17,10=18,11=19");
}

foreach my $height (0 .. 5) {
  foreach my $undirected (0, 1) {
    foreach my $multiedged (0, 1) {
      ### $height
      ### $undirected
      ### $multiedged
      my $graph = Graph::Maker->new('fibonacci_tree',
                                    height => $height,
                                    undirected => $undirected,
                                    multiedged => $multiedged);
      unless ($multiedged) {  # cannot diameter of multiedged
        # diameter 2*height
        my $got = $graph->diameter || 0;
        my $want = ($height==0 ? 0 : 2*$height-2);
        ok ($got, $want);
      }
      my $num_vertices = scalar($graph->vertices);
      ok ($num_vertices, F($height+3)-2);

      my $num_edges = $graph->edges;
      ok ($num_edges,
          ($num_vertices==0 ? 0 : $num_vertices-1) * ($undirected ? 1 : 2));
    }
  }
}

#------------------------------------------------------------------------------
# series_reduced => 1

# height=1
#     1  single node             Horibe order=1,2
#
{
  my $graph = Graph::Maker->new('fibonacci_tree',
                                height => 1,
                                series_reduced => 1,
                                undirected => 1);
  ok (scalar($graph->vertices), 1);
  ok (stringize_sorted($graph), "1");
}

# height=2, series_reduced=1
#             1                  Horibe order=3
#            / \
#           2   3
{
  my $graph = Graph::Maker->new('fibonacci_tree',
                                height => 2,
                                series_reduced => 1,
                                undirected => 1);

  ok (stringize_sorted($graph), "1=2,1=3");
}

# height=3,series_reduced=1
#             1                   Horibe order=4
#            / \
#           2   3
#          / \
#         4   5
{
  my $graph = Graph::Maker->new('fibonacci_tree',
                                height => 3,
                                series_reduced => 1,
                                undirected => 1);

  ok (stringize_sorted($graph), "1=2,1=3,2=4,2=5");
}

# height=4,series_reduced=1
#               1                   Horibe order=5  F(5)=5 leaf
#             /   \
#           2       3
#          / \     / \
#         4   5   6   7
#        / \
#       8   9
{
  my $graph = Graph::Maker->new('fibonacci_tree',
                                height => 4,
                                series_reduced => 1,
                                undirected => 1);

  ok (stringize_sorted($graph),
      "1=2,1=3,"
      . "2=4,2=5,3=6,3=7,"
      . "4=8,4=9");
}

# height=5,series_reduced=1
#                          ___1___             Horibe order=6
#                      ___/       \___
#                 __2__                3
#              __/     \_            /   \
#            4            5         6    7
#           / \          / \       / \
#         8     9      10  11     12 13        F(6)=8 leaf
#        / \                                  2*F(6)-1 = 15 total
#      14  15
{
  my $graph = Graph::Maker->new('fibonacci_tree',
                                height => 5,
                                series_reduced => 1,
                                undirected => 1);

  ok (stringize_sorted($graph),
      "1=2,1=3,"
      . "2=4,2=5,3=6,3=7,"
      . "4=8,4=9,5=10,5=11,6=12,6=13,"
      . "8=14,8=15");
}

# height=6,series_reduced=1
#                          ___1___       per Knuth would be Horibe order=7
#                      ___/       \___
#                 __2__                3
#              __/     \_            /   \
#            4            5         6    7           F(7)=13 leaf
#           / \          / \       / \   /\
#         8     9      10  11     12 13 14 15
#        / \    /\     /\        /\
#      16  17 18  19 20  21    22  23
#      /\
#    24  25
{
  my $graph = Graph::Maker->new('fibonacci_tree',
                                height => 6,
                                series_reduced => 1,
                                undirected => 1);

  ok (stringize_sorted($graph),
      "1=2,1=3,"
      . "2=4,2=5,3=6,3=7,"
      . "4=8,4=9,5=10,5=11,6=12,6=13,7=14,7=15,"
      . "8=16,8=17,9=18,9=19,10=20,10=21,12=22,12=23,"
      . "16=24,16=25");
}

# diameter 0 for order=0, otherwise 2*order-1 for order>=1
foreach my $k (0 .. 5) {
  my $graph = Graph::Maker->new('fibonacci_tree',
                                height => $k,
                                undirected => 1,
                                series_reduced => 1,
                               );
  my $got = $graph->diameter || 0;
  my $want = ($k==0 ? 0
              : $k==1 ? 0
              : $k==2 ? 2
              : 2*$k-3);
  ok ($got, $want, "diameter k=$k");
}

#------------------------------------------------------------------------------
# series_reduced => 1
# leaf_reduced => 1

# height=4, per POD
#         1
#       /   \        Fibonacci tree
#     2       3        height 4
#    / \     /       series_reduced => 1
#   4   5   6        leaf_reduced => 1
#  /
# 7
{
  my $graph = Graph::Maker->new('fibonacci_tree',
                                height => 4,
                                undirected => 1,
                                series_reduced => 1,
                                leaf_reduced => 1,
                               );

  ok (stringize_sorted($graph), "1=2,1=3,2=4,2=5,3=6,4=7");
}

# diameter 0 for order=0, otherwise 2*order-1 for order>=1
foreach my $k (0 .. 5) {
  my $graph = Graph::Maker->new('fibonacci_tree',
                                height => $k,
                                undirected => 1,
                                series_reduced => 1,
                                leaf_reduced => 1,
                               );
  my $got = $graph->diameter || 0;
  my $want = ($k==0 ? 0
              : $k==1 ? 0
              : 2*$k-3);
  ok ($got, $want);
}

#------------------------------------------------------------------------------
# counts of degree 0,1,2 nodes

foreach my $series_reduced (0, 1) {
  foreach my $leaf_reduced (1, 1) {
    foreach my $height (0 .. 12) {
      my $name = "height $height leaf_reduced=$leaf_reduced series_reduced=$series_reduced ";
      my $graph = Graph::Maker->new('fibonacci_tree',
                                    height => $height,
                                    leaf_reduced => $leaf_reduced,
                                    series_reduced => $series_reduced,
                                    undirected => 1);
      my $num_vertices = $graph->vertices;
      my @counts = (0,0,0);
      foreach my $v ($graph->vertices) {
        $counts[num_children($graph,$v)]++;
      }

      ok ($graph->is_directed ? 1 : 0,
          0);
      ok ($num_vertices == 0 || $graph->is_connected ? 1 : 0,
          1,
          "$name is_connected");

      my $want_num_vertices;
      my @want_counts;
      if (! $leaf_reduced) {
        $want_counts[0] = F($height+1);    # leaf
        $want_counts[1] = 0;              # no branches
        $want_counts[2] = F($height+1) - 1;
        $want_num_vertices = 2*F($height+1) - 1;

        if (! $series_reduced) {
          $want_counts[2] = F($height) - 1;
          $want_num_vertices = 2*F($height+1) - 1;
        }

      } else {
        $want_counts[0] = F($height);    # leaf
        $want_counts[1] = ($height == 0 ? 0 : F($height-1));
        $want_counts[2] = ($height == 0 ? 0 : F($height) - 1);
        $want_num_vertices = F($height+2) - 1;

        if (! $series_reduced) {
          $want_counts[1] = F($height+1) - 1;
          $want_num_vertices = ($height==0 ? 0 : F($height) + F($height+2) - 2);
        }
      }

      foreach my $i (0, 1, 2) {
        ok ($counts[$i], $want_counts[$i],
            "$name num_children=$i");
      }
      ok ($num_vertices, $want_num_vertices,
          "$name num_vertices");
    }
  }
}


#------------------------------------------------------------------------------
exit 0;
