#!/usr/bin/perl -w

# Copyright 2019 Kevin Ryde
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

use Graph::Maker::FoldedHypercube;

# uncomment this to run the ### lines
# use Smart::Comments;


{
  # N=3  complete 4
  # N=4  complete bipartite 4,4
  # N=5  Clebsch
  # N=6  Kummer
  #      https://hog.grinvin.org/ViewGraphInfo.action?id=1206

  my @graphs;
  foreach my $N (0) {
    # my $graph = make_folded_hypercube($N);
    my $graph = Graph::Maker->new('folded_hypercube', undirected => 1,
                                  N => $N);
    # print $graph->vertices,"\n";
    push @graphs, $graph;
    if ($N == 5) {
    }
     MyGraphs::Graph_view($graph);
    # $graph->vertices == 2**($N-1) or die;
    # if ($N >= 3) {
    #   scalar($graph->edges) == $N*2**($N-2) or die;
    # }
    # print scalar($graph->edges),",";
    print scalar($graph->diameter),",";
  }
  print "\n";
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

sub make_folded_hypercube {
  my ($N) = @_;
  my $graph = Graph::Maker->new('hypercube',
                                N => $N,
                                undirected => 1);
  if ($N > 0) {
    my $end = (1 << $N) + 1;
    foreach my $i (1 .. 1<<($N-1)) {
      $graph->path_length($i,$end-$i) == $N or die;
    }
    foreach my $i (1 .. 1<<($N-1)) {
      merge_vertices($graph, $i,$end-$i);
    }
  }
  return $graph;
}

sub merge_vertices {
  my ($graph, $u,$v) = @_;
  ### merge_vertices(): "$u $v"
  foreach my $to ($graph->neighbours($v)) {
    ### add: "$u to $to"
    unless ($u eq $to) {
      $graph->add_edge($u,$to);
    }
  }
  $graph->delete_vertex($v);
}





# Unused for now:
# Might want if have vertex_name_type options
#
  # my $graph = _make_graph(\%params);
  # ### $N
  # 
  # $graph->set_graph_attribute (name => "Folded Hypercube $N");
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
