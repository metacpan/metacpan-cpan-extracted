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

plan tests => 24;

use Graph::Maker::Petersen;


#------------------------------------------------------------------------------
{
  my $want_version = 14;
  ok ($Graph::Maker::Petersen::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::Petersen->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::Petersen->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::Petersen->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------

{
  my $graph = Graph::Maker->new('Petersen', undirected => 1);
  ok($graph->get_graph_attribute('name'),'Petersen');
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 10);

  my $other = Graph->new (undirected => 1);
  $other->add_cycle(1,2,3,4,5);
  $other->add_cycle(6,8,10,7,9);
  $other->add_edges([1,6],[2,7],[3,8],[4,9],[5,10]);
  ok ($graph->eq($other)?1:0, 1);
  # print "$graph\n";
  # print "$other\n";
}
{
  my $graph = Graph::Maker->new('Petersen', N=>5, K=>2);
  ok($graph->get_graph_attribute('name'),'Petersen');
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 10);
}


#------------------------------------------------------------------------------
# no multi-edges

foreach my $multiedged (0, 1) {
  foreach my $undirected (1, 0) {
    my $graph = Graph::Maker->new('Petersen',
                                  N=>4, K=>2,
                                  multiedged => $multiedged,
                                  undirected => $undirected);
    ok ($graph->is_multiedged ? 1 : 0, $multiedged);

    my $num_vertices = $graph->vertices;
    ok ($num_vertices, 8);

    my $num_edges = $graph->edges;
    my $want_num_edges = 4+4+2;
    unless ($undirected) { $want_num_edges *= 2; }
    ok ($num_edges, $want_num_edges);
  }
}

#------------------------------------------------------------------------------
# POD 7,9 = 7,5 = 7,2

{
  my $graph_79 = Graph::Maker->new('Petersen', N=>7, K=>9);
  my $graph_75 = Graph::Maker->new('Petersen', N=>7, K=>5);
  my $graph_72 = Graph::Maker->new('Petersen', N=>7, K=>2);
  ok($graph_79->eq($graph_75)?1:0, 1);
  ok($graph_79->eq($graph_72)?1:0, 1);
  ok($graph_75->eq($graph_72)?1:0, 1);
}

#------------------------------------------------------------------------------
exit 0;
