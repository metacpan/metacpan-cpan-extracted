#!/usr/bin/perl -w

# Copyright 2018, 2019, 2021 Kevin Ryde
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

use FindBin;
use lib "$FindBin::Bin/lib";
use MyGraphs;
$|=1;

use Graph::Maker::Circulant;

# uncomment this to run the ### lines
# use Smart::Comments;

{
  # Circulant HOG
  # N=7 1,2 https://hog.grinvin.org/ViewGraphInfo.action?id=710
  # N=8 1,2 https://hog.grinvin.org/ViewGraphInfo.action?id=160
  #         graphedron
  # N=8 1,3 https://hog.grinvin.org/ViewGraphInfo.action?id=570
  #         graphedron
  #

  require Algorithm::ChooseSubsets;
  my @graphs;
  my %seen;
  foreach my $N (
                 10
                ) {
    my $half = int($N/2);
    my @possible_offsets = (1 .. $half);
    my $it = Algorithm::ChooseSubsets->new(\@possible_offsets);
    while (my $offset_list = $it->next) {
      next if @$offset_list <= 1;                  # not cycle

      my $graph = Graph::Maker->new('circulant', undirected => 1,
                                    N => $N,
                                    offset_list => $offset_list);
      next if $graph->edges == $N*($N-1);  # not complete

      my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
      $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
      print "N=$N ",join(',',@$offset_list)," $g6_str";
      next if $seen{$g6_str}++;

      if (MyGraphs::hog_grep($g6_str)) {
        push @graphs, $graph;
      }
    }
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # Circulant equivalence 4
  my $N = 17;
  my @offset_list = (1,2,4,8);
  my $graph = Graph::Maker->new('circulant', undirected => 1,
                                N => $N, offset_list => \@offset_list);
  my $num_vertices = $graph->vertices;
  my $num_edges    = $graph->edges;
  my $diameter = $graph->diameter;
  print "  vertices $num_vertices edges $num_edges diameter $diameter\n";
  #  MyGraphs::Graph_print_tikz($graph);

  my $complement = $graph->complement;
  $graph->ne($complement) or die;
  if (MyGraphs::Graph_is_isomorphic($complement, $graph)) {
    print "self-complement\n";
  }

  foreach my $a (1..int($N/2)) {
    foreach my $b ($a..int($N/2)) {
      foreach my $c ($b..int($N/2)) {
        foreach my $d ($c..int($N/2)) {
          my $other = Graph::Maker->new('circulant', undirected => 1,
                                        N => $N, offset_list => [$a,$b,$c,$d]);
          if (MyGraphs::Graph_is_isomorphic($other, $graph)) {
            print "$a,$b,$c,$d\n";
          }
        }
      }
    }
  }
  exit 0;
}
{
  # Circulant equivalence 2
  my $N = 8;
  my @offset_list = (1,2);
  my $graph = Graph::Maker->new('circulant', undirected => 1,
                                N => $N, offset_list => \@offset_list);
  foreach my $a (1..int($N/2)) {
    foreach my $b ($a..int($N/2)) {
      my $other = Graph::Maker->new('circulant', undirected => 1,
                                    N => $N, offset_list => [$a,$b]);
      if (MyGraphs::Graph_is_isomorphic($other, $graph)) {
        print "$a,$b\n";
      }
    }
  }
  exit 0;
}



