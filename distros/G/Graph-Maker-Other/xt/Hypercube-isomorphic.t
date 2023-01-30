#!/usr/bin/perl -w

# Copyright 2022 Kevin Ryde
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
use FindBin;
use File::Slurp;
use List::Util 'sum';
use Test;
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use File::Spec;
use lib File::Spec->catdir('devel','lib');
use MyGraphs;

plan tests => 18;

require Graph::Maker::Hypercube;


#------------------------------------------------------------------------------
# Equivalents

sub make_hypercube_by_gmaker {
  my ($N) = @_;
}

# Each pair odd,even is merged,
# gives N-1 hypercube
sub make_merged_pairs_hypercube {
  my ($N) = @_;
  my $graph = Graph::Maker->new('hypercube',
                                undirected => 1,
                                N => $N);
  my $num_vertices = $graph->vertices;
  for (my $i = 1; $i <= $num_vertices; $i+=2) {
    MyGraphs::Graph_merge_vertices ($graph, $i, $i+1);
  }
  return $graph;
}


foreach my $N (1..6) {
  my $graph = Graph::Maker->new('hypercube',
                                undirected => 1,
                                N => $N-1);
  $graph->add_vertex(1);

  my $merged = make_merged_pairs_hypercube($N);
  ok (scalar($graph->vertices),  2**($N-1));
  ok (scalar($merged->vertices), 2**($N-1));
  ok (MyGraphs::Graph_is_isomorphic($graph, $merged), 1,
      "isomorphic, N=$N");
  # MyGraphs::Graph_view($graph);
  # MyGraphs::Graph_view($merged);
}


#------------------------------------------------------------------------------
exit 0;
