#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022 Kevin Ryde
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
# with this file.  See the file COPYING.  If not, see
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

plan tests => 574;


require Graph::Maker::TwindragonAreaTree;


#------------------------------------------------------------------------------
{
  my $want_version = 19;
  ok ($Graph::Maker::TwindragonAreaTree::VERSION, $want_version,
      'VERSION variable');
  ok (Graph::Maker::TwindragonAreaTree->VERSION,  $want_version,
      'VERSION class method');
  ok (eval { Graph::Maker::TwindragonAreaTree->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::TwindragonAreaTree->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# direction_type

foreach my $level (0 .. 7) {
  my $graph = Graph::Maker->new('twindragon_area_tree',
                                level => $level,
                                direction_type => 'bigger');
  foreach my $edge ($graph->edges) {
    my ($from,$to) = @$edge;
    ok ($from < $to, 1,
        "bigger edge $from to $to");
  }
}
foreach my $level (0 .. 7) {
  my $graph = Graph::Maker->new('twindragon_area_tree',
                                level => $level,
                                direction_type => 'smaller');
  foreach my $edge ($graph->edges) {
    my ($from,$to) = @$edge;
    ok ($from > $to, 1);
  }
}


#------------------------------------------------------------------------------

{
  # no parameters
  my $graph = Graph::Maker->new('twindragon_area_tree');
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 1);
}
{
  # level=1
  my $graph = Graph::Maker->new('twindragon_area_tree', level => 1);
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 2);
  ok ($graph->is_directed?1:0, 1);
  ok ($graph->has_edge(0,1)?1:0, 1);
  ok ($graph->has_edge(1,0)?1:0, 1);
}
{
  # level=2
  my $graph = Graph::Maker->new('twindragon_area_tree', level => 2,
                                undirected => 1);
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 4);
  ok ($graph->has_edge(0,1)?1:0, 1);
  ok ($graph->has_edge(0,2)?1:0, 0);
  ok ($graph->has_edge(1,2)?1:0, 1);
  ok ($graph->has_edge(2,3)?1:0, 1);
  ok ($graph->vertex_degree(2), 2);
  ok ($graph->vertex_degree(3), 1);
}

foreach my $level (0 .. 7) {
  foreach my $undirected (0, 1) {
    foreach my $multiedged (0, 1) {
      my $graph = Graph::Maker->new('twindragon_area_tree',
                                    level => $level,
                                    undirected => $undirected,
                                    multiedged => $multiedged);
      my $num_vertices = $graph->vertices;
      ok ($num_vertices, 2**$level);

      my $num_edges = $graph->edges;
      ok ($num_edges,
          ($num_vertices==0 ? 0 : $num_vertices-1) * ($undirected ? 1 : 2));
    }
  }
}

#------------------------------------------------------------------------------
exit 0;
