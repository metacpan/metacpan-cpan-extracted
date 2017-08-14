#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017 Kevin Ryde
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

# uncomment this to run the ### lines
# use Smart::Comments;

plan tests => 95;


require Graph::Maker::KnightGrid;


#------------------------------------------------------------------------------
{
  my $want_version = 7;
  ok ($Graph::Maker::KnightGrid::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::KnightGrid->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::KnightGrid->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::KnightGrid->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------

{
  # empty
  my $graph = Graph::Maker->new('knight_grid');
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 0);
}
{
  # dims empty
  my $graph = Graph::Maker->new('knight_grid', dims => []);
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 0);
}

# 1 dim is no edges
foreach my $undirected (0, 1) {
  foreach my $cyclic (0, 1) {
    my $graph = Graph::Maker->new('knight_grid', dims => [5],
                                  undirected => $undirected,
                                  cyclic => $cyclic);
    my $num_vertices = $graph->vertices;
    ok ($num_vertices, 5);

    my $num_edges = $graph->edges;
    ok ($num_edges, 0);
  }
}

{
  # 2x3
  # 1  2  3
  # 4  5  6
  my $graph = Graph::Maker->new('knight_grid', dims => [2,3]);
  ### graph: "$graph"
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 6);
  ok ($graph->has_edge(1,6)?1:0, 1);
  ok ($graph->has_edge(3,4)?1:0, 1);
  ok ($graph->has_edge(1,2)?1:0, 0);
  ok ($graph->vertex_degree(2), 0);
  ok ($graph->vertex_degree(5), 0);
}

{
  # 2x3 cyclic
  # 1  2  3
  # 4  5  6
  my $graph = Graph::Maker->new('knight_grid', dims => [2,3], cyclic => 1,
                               undirected => 1);
  ### graph: "$graph"
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 6);
  ok ($graph->has_edge(1,6)?1:0, 1);
  ok ($graph->has_edge(3,4)?1:0, 1);
  ok ($graph->has_edge(1,2)?1:0, 1);
  ok ($graph->degree(1), 4);
  ok ($graph->degree(2), 4);
  ok ($graph->degree(5), 4);
}

{
  # 3x4 per POD
  my $graph = Graph::Maker->new('knight_grid', dims => [3,4],
                                undirected => 1);
  ### graph: "$graph"
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 12);

  ok ($graph->degree(1), 2);
  ok ($graph->has_edge(1,7)?1:0, 1);
  ok ($graph->has_edge(1,10)?1:0, 1);

  ok ($graph->degree(2), 3);
  ok ($graph->has_edge(2,9)?1:0, 1);
  ok ($graph->has_edge(2,11)?1:0, 1);
  ok ($graph->has_edge(2,8)?1:0, 1);

  ok ($graph->degree(6), 2);
  ok ($graph->has_edge(6,4)?1:0, 1);
  ok ($graph->has_edge(6,12)?1:0, 1);
}

{
  # 5,5 cyclic vertex degrees
  my $d = 5;
  my $graph = Graph::Maker->new('knight_grid', dims => [$d,$d], cyclic=>1,
                                undirected => 1);
  foreach my $v (1 .. $d*$d) {
    ok ($graph->degree($v), 8);
  }
}

#------------------------------------------------------------------------------
# 1x1 cyclic self-loop

# 1x plain, no edges
foreach my $d (0 .. 4) {
  my $graph = Graph::Maker->new('knight_grid', dims => [(1) x $d]);
  my $num_vertices = $graph->vertices;
  my $want_num_vertices = ($d >= 1 ? 1 : 0);
  ok ($num_vertices, $want_num_vertices);

  my $num_edges = $graph->edges;
  ok ($num_edges, 0);
}

# 1x cyclic, self loop when >=2 dims
foreach my $d (0 .. 4) {
  my $graph = Graph::Maker->new('knight_grid', dims => [(1) x $d], cyclic=>1);
  my $num_vertices = $graph->vertices;
  my $want_num_vertices = ($d >= 1 ? 1 : 0);
  ok ($num_vertices, $want_num_vertices);

  my $num_edges = $graph->edges;
  my $want_num_edges = ($d >= 2 ? 1 : 0);
  ok ($num_edges, $want_num_edges, "d=$d");
  ok ($graph->has_edge(1,1)?1:0, $want_num_edges);
}

#------------------------------------------------------------------------------
# Nx1 2-steps

{
  # 4x1 plain, no edges
  my $graph = Graph::Maker->new('knight_grid', dims => [4,1]);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ($num_vertices, 4);
  ok ($num_edges, 0);
}
{
  # 4x1 cyclic
  # 1 -- 2 -- 3 -- 4
  my $graph = Graph::Maker->new('knight_grid', dims => [4,1], cyclic=>1,
                                undirected => 1);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ($num_vertices, 4);
  ok ($num_edges, 6);
  ok ($graph->has_edge(1,2)?1:0, 1);
  ok ($graph->has_edge(1,3)?1:0, 1);
  ok ($graph->has_edge(2,4)?1:0, 1);
}

#------------------------------------------------------------------------------
exit 0;
