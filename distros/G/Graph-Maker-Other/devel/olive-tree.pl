#!/usr/bin/perl -w

# Copyright 2018 Kevin Ryde
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
use lib "$FindBin::Bin/lib";
use MyGraphs;
use Graph::Maker::OliveTree;

# uncomment this to run the ### lines
# use Smart::Comments;

{
  # N=0 singleton
  # N=1 path-2
  # N=2 path-4
  # N=3 
  #
  my @graphs;
  foreach my $N (0 .. 10) {
    my $graph = Graph::Maker->new('olive_tree',
                                  N => $N,
                                  undirected => 1);
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
