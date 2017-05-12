#!/usr/bin/perl -w

# Copyright 2015, 2016 Kevin Ryde
#
# This file is part of Graph-Maker-Other.
#
# Graph-Maker-Other is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Graph-Maker-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Maker-Other.  If not, see <http://www.gnu.org/licenses/>.

use 5.005;
use strict;
use FindBin;
use MyGraphs;

use lib 'devel/lib';
use Graph::Maker::Petersen;

# uncomment this to run the ### lines
# use Smart::Comments;

{
  # Petersen    https://hog.grinvin.org/ViewGraphInfo.action?id=660
  # line graph  hog not
  my $graph = Graph::Maker->new('Petersen', undirected => 1);
  my $line = Graph_line_graph($graph);
   Graph_print_tikz($line);
  # Graph_view($line);
  # hog_searches_html($graph, $line);
  print "is_subgraph ",Graph_is_subgraph($line,$graph),"\n";
  print "is_induced_subgraph ",Graph_is_induced_subgraph($line,$graph),"\n";
  exit 0;
}
{
  # 2-element subsets of 1 to 5 with edges between pairs both different

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

  my $same = Graph_is_isomorphic($graph, $petersen);
  print $same ? "yes\n" : "no\n";
  exit 0;
}


