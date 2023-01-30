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

use strict;
use 5.004;
use Test;
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

plan tests => 54;

require Graph::Maker::Hanoi;

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
  my $want_version = 19;
  ok ($Graph::Maker::Hanoi::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::Hanoi->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::Hanoi->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::Hanoi->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------

{
  # discs=0
  my $graph = Graph::Maker->new('hanoi', discs => 0);
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 1);
}
{
  # discs=1, directed
  my $graph = Graph::Maker->new('hanoi', discs => 1);
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 3);
  ok ($graph->is_directed?1:0, 1);
  ok ($graph->has_edge(0,1)?1:0, 1);
  ok ($graph->has_edge(1,0)?1:0, 1);

  ok ($graph->has_edge(1,2)?1:0, 1);
  ok ($graph->has_edge(2,1)?1:0, 1);

  ok ($graph->has_edge(2,1)?1:0, 1);
  ok ($graph->has_edge(1,2)?1:0, 1);
}
{
  my $graph = Graph::Maker->new('hanoi', discs => 2);
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 9);

  ok ($graph->has_edge(0,1)?1:0, 1);
  ok ($graph->has_edge(0,2)?1:0, 1);
  ok ($graph->has_edge(1,2)?1:0, 1);

  ok ($graph->has_edge(0,4)?1:0, 0);
}

{
  # discs=3 per POD
  my $graph = Graph::Maker->new('hanoi', discs => 3,
                                undirected => 1, countedged => 1);
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 27);
  ok ($graph->has_edge(0,1)?1:0, 1);
  ok ($graph->has_edge(0,2)?1:0, 1);
  ok ($graph->has_edge(1,2)?1:0, 1);

  ok ($graph->has_edge(7,8)?1:0, 1);
  ok ($graph->has_edge(8,17)?1:0, 1);
  ok ($graph->has_edge(17,15)?1:0, 1);
  ok ($graph->has_edge(15,12)?1:0, 1);

  ok ($graph->has_edge(5,4)?1:0, 1);
  ok ($graph->has_edge(4,22)?1:0, 1);

  my $want = Graph->new(undirected => 1);
  $want->add_cycle(0,1,7,8,17,15,12,13,14,11,9,18,19,25,26,24,21,22,4,5,2);
  $want->add_path(8,6,3,4);
  $want->add_edges([1,2],[7,6],[5,3]);
  $want->add_path(17,16,10,9);
  $want->add_edges([15,16],[12,14],[11,10]);
  $want->add_path(22,23,20,18);
  $want->add_edges([23,21],[20,19],[25,24]);

  ok (stringize_sorted($graph),
      stringize_sorted($want));
}

#------------------------------------------------------------------------------
# spindles = 1 or 2 per POD

{
  # spindles=1
  foreach my $discs (1 .. 5) {
    my $graph = Graph::Maker->new('hanoi', discs => $discs, spindles => 1);
    my $num_vertices = $graph->vertices;
    ok ($num_vertices, 1);
  }
}

{
  # spindles=2
  foreach my $undirected (0, 1) {
    foreach my $discs (1 .. 5) {
      my $graph = Graph::Maker->new('hanoi', discs => $discs, spindles => 2,
                                    undirected => $undirected,
                                    countedged => 1);
      my $num_vertices = $graph->vertices;
      my $num_edges = $graph->edges;
      ok ($num_vertices, 2**$discs);
      ok ($num_edges, 2**($discs-1) * ($undirected ? 1 : 2));
    }
  }
}

#------------------------------------------------------------------------------
exit 0;
