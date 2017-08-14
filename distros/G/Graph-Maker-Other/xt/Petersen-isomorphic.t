#!/usr/bin/perl -w

# Copyright 2017 Kevin Ryde
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

use Graph::Maker::Petersen;

use lib
  'devel/lib';
use MyGraphs ();

plan tests => 2;


#------------------------------------------------------------------------------

{
  # N=4,K=1 is cube graph

  require Graph::Maker::Hypercube;
  my $hypercube = Graph::Maker->new('hypercube', undirected => 1, N=>3);
  my $petersen  = Graph::Maker->new('Petersen',  undirected => 1, N=>4, K=>1);
  ok (MyGraphs::Graph_is_isomorphic($hypercube, $petersen));
  # MyGraphs::Graph_view($petersen);
  # MyGraphs::Graph_view($hypercube);
}

{
  # Petersen = 2-element subsets of 1 to 5 with edges between pairs both
  # different

  require Graph;
  my $graph = Graph->new(undirected => 1);

  require Algorithm::ChooseSubsets;
  my $it = Algorithm::ChooseSubsets->new(set=>[1..5], size=>2);
  my @vertices;
  while (my $aref = $it->next) {
    ### $aref
    push @vertices, $aref;
    $graph->add_vertex("$aref->[0],$aref->[1]");
  }

  foreach my $v1 (@vertices) {
    foreach my $v2 (@vertices) {
      if ($v1->[0] != $v2->[0]
          && $v1->[0] != $v2->[1]
          && $v1->[1] != $v2->[0]
          && $v1->[1] != $v2->[1]) {
        $graph->add_edge("$v1->[0],$v1->[1]", "$v2->[0],$v2->[1]");
      }
    }
  }
  my $petersen = Graph::Maker->new('Petersen', undirected => 1);

  ok (MyGraphs::Graph_is_isomorphic($graph, $petersen))
}

#------------------------------------------------------------------------------
exit 0;
