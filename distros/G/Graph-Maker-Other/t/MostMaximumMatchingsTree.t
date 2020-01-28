#!/usr/bin/perl -w

# Copyright 2020 Kevin Ryde
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
use Graph::Maker::Star;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

plan tests => 75;

require Graph::Maker::MostMaximumMatchingsTree;


#------------------------------------------------------------------------------
{
  my $want_version = 15;
  ok ($Graph::Maker::MostMaximumMatchingsTree::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::MostMaximumMatchingsTree->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::MostMaximumMatchingsTree->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::MostMaximumMatchingsTree->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------

ok (-4 <=> 0, -1);
ok ( 4 <=> 0,  1);
ok ( 0 <=> 0,  0);


#------------------------------------------------------------------------------

# Graph::Maker::Star version 0.01 has a bug where N=1 make no vertices, skip
# that for now
foreach my $N (0, 2 .. 6) {
  my $graph = Graph::Maker->new('most_maximum_matchings_tree', N => $N,
                                undirected => 1);
  if ($N >= 1) {
    ok ($graph->degree(1), $N-1);
  }

  my $star = Graph::Maker->new('star', N => $N,
                               undirected => 1);
  ok (scalar($star->vertices), $N);
  ok ($graph->eq($star), 1,
      "equals star N=$N");

  # print $graph,"\n";
  # print $star,"\n";
}

#------------------------------------------------------------------------------

foreach my $N (0 .. 50) {
  my $graph = Graph::Maker->new('most_maximum_matchings_tree', N => $N);
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, $N);
}

#------------------------------------------------------------------------------
exit 0;
