#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017, 2018, 2019 Kevin Ryde
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

plan tests => 30;

require Graph::Maker::Keller;


#------------------------------------------------------------------------------
{
  my $want_version = 15;
  ok ($Graph::Maker::Keller::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::Keller->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::Keller->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::Keller->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------

{
  # N=0
  my $graph = Graph::Maker->new('Keller');
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ($num_vertices, 1);
  ok ($num_edges, 0);
}
{
  # N=1
  my $graph = Graph::Maker->new('Keller', N=>1);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ($num_vertices, 4);
  ok ($num_edges, 0);
}
{
  # N=2, directed
  my $graph = Graph::Maker->new('Keller', N=>2);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ($num_vertices, 16);
  ok ($num_edges, 80);
}
{
  # N=2, undirected
  my $graph = Graph::Maker->new('Keller', N=>2, undirected => 1);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ($num_vertices, 16);
  ok ($num_edges, 40);
}
{
  # N=3, directed
  my $graph = Graph::Maker->new('Keller', N=>3);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ($num_vertices, 64);
  ok ($num_edges, 2*1088);
}
foreach my $undirected (0, 1) {
  # N=3, undirected
  my $graph = Graph::Maker->new('Keller', N=>3,
                                undirected => $undirected);
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 64);
  my $num_edges = $graph->edges;
  ok ($num_edges, 1088 * ($undirected ? 1 : 2));
}

#------------------------------------------------------------------------------
# Keller subgraph

{
  # N=0
  my $graph = Graph::Maker->new('Keller', subgraph=>1);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ($num_vertices, 0);
  ok ($num_edges, 0);
}
{
  # N=1, is a star
  my $graph = Graph::Maker->new('Keller', subgraph=>1, N=>1);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ($num_vertices, 0);
  ok ($num_edges, 0);
}
{
  # N=2, undirected
  #
  # 00   21  12
  #      22    
  #      23  32
  # no edges between neighbours
  #
  my $graph = Graph::Maker->new('Keller', N=>2, subgraph=>1, undirected => 1);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ($num_vertices, 5);
  ok ($num_edges, 0);
}
{
  # N=2, directed
  my $graph = Graph::Maker->new('Keller', N=>2, subgraph=>1);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ($num_vertices, 5);
  ok ($num_edges, 0);
}

{
  # N=3, undirected
  my $graph = Graph::Maker->new('Keller', N=>3, subgraph=>1, undirected => 1);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ($num_vertices, 34);
  ok ($num_edges, 261);
}
{
  # N=3, directed
  my $graph = Graph::Maker->new('Keller', N=>3, subgraph=>1);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ($num_vertices, 34);
  # ok ($num_edges, 2*261);
}

{
  # N=4, undirected
  my $graph = Graph::Maker->new('Keller', N=>4, subgraph=>1, undirected => 1);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ($num_vertices, 171);
  # ok ($num_edges, 295);
}

#------------------------------------------------------------------------------
exit 0;
