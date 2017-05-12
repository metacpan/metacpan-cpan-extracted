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

# uncomment this to run the ### lines
# use Smart::Comments;

{
  # BinomialTree forms ascii prints

  require Graph::Maker::StarOfStars;
  my @graphs;
  foreach my $level (0 .. 2) {
    my $graph = Graph::Maker->new('star_of_stars',
                                  level => $level,
                                  N => 4,
                                  undirected => 1,
                                 );
    print $graph->get_graph_attribute('name'),"\n";
    Graph_tree_print($graph);
    Graph_view($graph);
    push @graphs, $graph;
  }
  hog_searches_html(@graphs);
  exit 0;
}
