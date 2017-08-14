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

plan tests => 323;


require Graph::Maker::Caterpillar;


#------------------------------------------------------------------------------
{
  my $want_version = 7;
  ok ($Graph::Maker::Caterpillar::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::Caterpillar->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::Caterpillar->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::Caterpillar->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------

{
  my $graph = Graph::Maker->new('caterpillar', N_list => []);
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 0);
}
{
  my $graph = Graph::Maker->new('caterpillar', N_list => [0]);
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 0);
}
{
  my $graph = Graph::Maker->new('caterpillar', N_list => [1]);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ("$graph", "1");
  ok ($num_vertices, 1);
  ok ($num_edges, 0);
}

{
  my $graph = Graph::Maker->new('caterpillar', N_list => [2]);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ("$graph", "1-2,2-1");
  ok ($num_vertices, 2);
  ok ($num_edges, 2);
}
{
  my $graph = Graph::Maker->new('caterpillar', N_list => [2], undirected => 1);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ("$graph", "1=2");
  ok ($num_vertices, 2);
  ok ($num_edges, 1);
}


#------------------------------------------------------------------------------
exit 0;
