#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017, 2019 Kevin Ryde
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

use strict;
use 5.004;
use Test;
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Graph::Maker::Keller;

use File::Spec;
use lib File::Spec->catdir('devel','lib');
use MyGraphs;

plan tests => 11;

# uncomment this to run the ### lines
# use Smart::Comments;


#------------------------------------------------------------------------------
# Keller N=2 made by 5-hypercube antipodal merge

{
  require Graph::Maker::Hypercube;
  my $hyper = Graph::Maker->new('hypercube', N => 5, undirected => 1);
  my $diameter = $hyper->diameter;
  ### hyper diameter: $diameter
  my @merge;
  my %merge_seen;
  $hyper->for_shortest_paths(sub {
                               my ($trans, $u,$v) = @_;
                               if ($u >= $v) { return; }
                               if ($trans->path_length($u,$v) == $diameter) {
                                 push @merge, [$u,$v];
                                 ### merge: "$u - $v"
                                 if ($merge_seen{$u} || $merge_seen{$v}) {
                                   print "  umm, repeat $u,$v\n";
                                 }
                                 $merge_seen{$u} = 1;
                                 $merge_seen{$v} = 1;
                               }
                             });
  foreach my $elem (@merge) {
    my ($u,$v) = @$elem;
    my $m = "$u-$v";
    $hyper->add_vertex($m);
    foreach my $to ($hyper->neighbours($u),
                    $hyper->neighbours($v)) {
      $hyper->add_edge($m, $to);
    }
    $hyper->delete_vertices($u, $v);
  }
  ### num merges: scalar(@merge)
  ok (scalar(@merge), 16);

  my $num_vertices = $hyper->vertices;
  my $num_edges    = $hyper->edges;
  ### $num_vertices
  ### $num_edges

  my $Keller = Graph::Maker->new('Keller', N => 2, undirected => 1);

  ok (MyGraphs::Graph_is_isomorphic($hyper,$Keller), 1);
}

#------------------------------------------------------------------------------
# Keller subgraph is induced subgraph

foreach my $N (1 .. 3) {
  my $graph = Graph::Maker->new('Keller', N=>$N, undirected => 1);
  my $subgraph = Graph::Maker->new('Keller', N=>$N, undirected => 1);
  ok (MyGraphs::Graph_is_induced_subgraph($graph, $subgraph)?1:0, 1);
}

#------------------------------------------------------------------------------
# clique numbers
{
  my $N = 2;
  my $graph = Graph::Maker->new('Keller', N=>$N, undirected => 1);
  ok (MyGraphs::Graph_clique_number($graph), 2);

  $graph = Graph::Maker->new('Keller', N=>$N, subgraph => 1, undirected => 1);
  ok (MyGraphs::Graph_clique_number($graph), 1);
}
{
  my $N = 3;
  my $graph = Graph::Maker->new('Keller', N=>$N, undirected => 1);
  ok (MyGraphs::Graph_clique_number($graph), 5);

  $graph = Graph::Maker->new('Keller', N=>$N, subgraph => 1, undirected => 1);
  ok (MyGraphs::Graph_clique_number($graph), 4);
}


#------------------------------------------------------------------------------
# Keller subgraph size
{
  # N=5, undirected  (a bit slow to calculate)
  my $graph = Graph::Maker->new('Keller', N=>5, subgraph=>1, undirected => 1);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ($num_vertices, 776);
  ok ($num_edges, 225990);
}

#------------------------------------------------------------------------------
exit 0;
