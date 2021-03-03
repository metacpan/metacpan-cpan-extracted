#!/usr/bin/perl -w

# Copyright 2020 Kevin Ryde
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
use List::Util 'max';

use FindBin;
use lib "$FindBin::Bin/lib";
use MyGraphs;
$|=1;

# uncomment this to run the ### lines
# use Smart::Comments;


{
  # Square-Free using 5 ternary letter pairs only

  my $square_re = qr/(.+)\1/;
  my @pending = ('a');
  my $graph = Graph->new (undirected => 0);
  $graph->set_graph_attribute
    (name => "Square-Free Ternary Letter Pairs");
  $graph->set_graph_attribute (root => $pending[0]);
  $graph->set_graph_attribute (flow => 'south');
  while (my $str = shift @pending) {
    $graph->add_vertex($str);
    foreach my $new_letter ('a','b','c') {
      my $new_str = $str . $new_letter;
      next if $new_str =~ /aa|bb|cc|ab/;  # forbidden pair
      $graph->add_edge($str, $new_str);
      unless ($new_str =~ $square_re) {
        push @pending, $new_str;
      }
    }
  }
  my @vertices = sort $graph->vertices;
  my $max_length = max(map {length} @vertices);
  print "longest $max_length\n";

  MyGraphs::Graph_set_xy_points($graph,
                                a => [0,0],
                                ac => [0,-1],
                                aca => [-1,-2],
                                acac => [-2,-3],
                                acb => [1,-2],
                                acba => [0,-3],
                                acba => [1,-3],
                                acbac => [0,-4],

                                acbc => [1,-3],
                                acbca => [1,-4],
                                acbcb => [2,-4],
                                acbcac => [1,-5],
                                acbcaca => [0,-6],

                                # this one extra
                                # acbcacac => [0,-7],

                                acbcacb => [2,-6],
                               );

  MyGraphs::Graph_view($graph, is_xy=>1, scale=>2);
  print "tree\n";
  MyGraphs::Graph_tree_print($graph, cmp => \&MyGraphs::cmp_alphabetic);
  # Graph_print_tikz($graph);
  MyGraphs::hog_searches_html($graph);
  exit 0;
}
