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

use lib 'devel/lib';
use MyGraphs;

plan tests => 3;


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
# POD HOG Shown

{
  my %shown = ('3,1' => 746,
               '4,1' => 1022,  '4,2' => 588,
               '5,2' => 660,
               '7,2' => 28482,
               '8,3' => 1229,
               '9,3' => 6700,
               '10,2' => 1043, '10,3' => 1036,
               '11,2' => 24052,
               '12,2' => 27325, '12,5' => 1234,
              );
  my $extras = 0;
  my %seen;
  foreach my $N (3 .. 25) {
    foreach my $K (1 .. $N-1) {
      my $graph = Graph::Maker->new('Petersen', undirected => 1,
                                    N => $N, K => $K);
      my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
      $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
      next if $seen{$g6_str}++;
      my $key = "$N,$K";
      if (my $id = $shown{$key}) {
        MyGraphs::hog_compare($id, $g6_str);
      } else {
        if (MyGraphs::hog_grep($g6_str)) {
          MyTestHelpers::diag ("HOG $key not shown in POD");
          MyTestHelpers::diag ($g6_str);
          MyGraphs::Graph_view($graph);
          $extras++
        }
      }
    }
  }
  ok ($extras, 0);
}


#------------------------------------------------------------------------------
exit 0;
