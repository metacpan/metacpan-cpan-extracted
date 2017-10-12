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

use Graph::Maker::GosperIsland;

plan tests => 15;

# uncomment this to run the ### lines
# use Smart::Comments;


#------------------------------------------------------------------------------
{
  my $want_version = 8;
  ok ($Graph::Maker::GosperIsland::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::GosperIsland->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::GosperIsland->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::GosperIsland->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------

# {
#   my $graph = Graph->new (countedged => 1);
#   ok ($graph->is_multiedged, 1);
# }
# {
#   my $graph = Graph->new (multiedged => 1);
#   ok ($graph->is_multiedged, 1);
# }

foreach my $options ([],
                     [countedged => 1],
                     [multiedged => 1]) {
  my $graph = Graph::Maker->new('Gosper_island', level => 2,
                                undirected => 1, @$options);
  my %seen;
  my $duplicates = 0;
  foreach my $edge ($graph->edges) {
    my $str = join(' -- ',sort @$edge);
    if ($seen{$str}++) { $duplicates++; }
  }
  ### %seen
  ok ($duplicates, 0);
}

#------------------------------------------------------------------------------
# num vertices, edges, per POD

foreach my $k (0 .. 3) {
  my $graph = Graph::Maker->new('Gosper_island', level => $k, undirected => 1);
  ok (scalar($graph->vertices), 2*7**$k + 3**($k+1) + 1, "k=$k");
  ok (scalar($graph->edges),    3*7**$k + 3**($k+1));
}


#------------------------------------------------------------------------------
exit 0;
