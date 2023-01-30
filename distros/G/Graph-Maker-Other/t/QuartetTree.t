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

plan tests => 36;

require Graph::Maker::QuartetTree;

#------------------------------------------------------------------------------
{
  my $want_version = 19;
  ok ($Graph::Maker::QuartetTree::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::QuartetTree->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::QuartetTree->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::QuartetTree->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------

foreach my $level (0 .. 3) {
  foreach my $undirected (0, 1) {
    foreach my $multiedged (0, 1) {
      my $graph = Graph::Maker->new('quartet_tree',
                                    level => $level,
                                    undirected => $undirected,
                                    multiedged => $multiedged);
      my $num_vertices = scalar($graph->vertices);
      ok ($num_vertices, 5**$level + 1);

      my $num_edges = $graph->edges;
      ok ($num_edges,
          ($num_vertices==0 ? 0 : $num_vertices-1) * ($undirected ? 1 : 2));
    }
  }
}

#------------------------------------------------------------------------------
exit 0;
