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
use Graph::Graph6;


for (;;) {
  my @m;
  Graph::Graph6::read_graph(fh => \*STDIN,
                            num_vertices_ref => \my $num_vertices,
                            edge_func => sub {
                              my ($u,$v) = @_;
                              $m[$u]->[$v] = 1;
                              $m[$v]->[$u] = 1;
                            })
      or last;

  print "[";
  my $last_vertex = $num_vertices-1;
  foreach my $u (0 .. $last_vertex) {
    foreach my $v (0 .. $last_vertex) {
      print $m[$u]->[$v] ? 1 : 0,
        $v<$last_vertex ? ',' :
        $u<$last_vertex ? ';' : '';
    }
  }
  print "]\n";
}
