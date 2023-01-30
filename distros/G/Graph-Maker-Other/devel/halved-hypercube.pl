#!/usr/bin/perl -w

# Copyright 2022 Kevin Ryde
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
use Graph::Maker::Hypercube;

use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'devel', 'lib');
use MyGraphs;
$|=1;

use Graph::Maker::HalvedHypercube;

# uncomment this to run the ### lines
use Smart::Comments;


# even 1s, differing in exactly 2 coords

{
  # N=0,1  singleton
  # N=2  path-2
  # N=3  complete-4
  # N=4  16-cell graph
  #      is N=8 circulant 1,2,3
  # N=5  49258  Clebsch complement
  # N=6  49260
  # N=7  49262
  # N=8  49264
  #
  #         @---*     *---@
  #         |   |     |   |
  #         *---@     @---*
  #      *---@     @---*
  #      |   |     |   |
  #      @---*     *---@
  # N=4 

  my @graphs;
  foreach my $N (8) {
    my $graph = Graph::Maker->new
      ('halved_hypercube',
       N => $N,
       undirected => 1);
    MyGraphs::Graph_hypercube_layout($graph);

    # my $graph = Graph::Maker->new('hypercube', undirected => 1, N => $N);
    # $graph = Graph_halve($graph);

    # print $graph->vertices,"\n";
    push @graphs, $graph;
    if ($N == 5) {
    # MyGraphs::Graph_view($graph);
    }
  }
  print "\n";
  MyGraphs::hog_searches_html(@graphs);
  MyGraphs::hog_upload_html($graphs[0]);
  exit 0;
}


# Unused for now:
# Might want if have vertex_name_type options
#
  # my $graph = _make_graph(\%params);
  # ### $N
  #
  # $graph->set_graph_attribute (name => "Halved Hypercube $N");
  #
  # $graph->add_vertex(1);
  # if ($N >= 2) {
  #   my $directed = $graph->is_directed;
  #   my $mask = (1<<($N-1)) - 1;
  #   foreach my $from (0 .. $mask-1) {
  #     ### $from
  #     for (my $flip = 1; $flip <= $mask; $flip<<=1) {
  #       if ((my $to = $from ^ $flip) > $from) {
  #         ### flip edge: "$from to $to"
  #         ### assert: ! $graph->has_edge($from,$to)
  #         $graph->add_edge($from,$to);
  #         if ($directed) {
  #           $graph->add_edge($to,$from);
  #         }
  #       }
  #     }
  #   }
  #   if ($mask > 1) {
  #     foreach my $from (0 .. $mask>>1) {
  #       my $to = $from ^ $mask;
  #       ### full edge: "$from to $to"
  #       ### assert: ! $graph->has_edge($from,$to)
  #       $graph->add_edge($from,$to);
  #       if ($directed) {
  #         $graph->add_edge($to,$from);
  #       }
  #     }
  #   }
  # }
  # return $graph;
