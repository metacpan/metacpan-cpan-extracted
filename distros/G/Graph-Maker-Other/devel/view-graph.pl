#!/usr/bin/perl -w

# Copyright 2017 Kevin Ryde
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

# uncomment this to run the ### lines
# use Smart::Comments;

### @ARGV

my $name = '';
while (@ARGV) {
  my $arg = shift @ARGV;
  if ($arg eq '--name') {
    $name = shift @ARGV // '';
    next;
  }
  if ($arg eq '--graph6') {
    my $graph6 = shift @ARGV // die "missing argument to --graph6";
    MyGraphs::graph6_view($graph6);
    next;
  }
  if ($arg eq '--name') {
    $name = shift @ARGV;
    next;
  }
  if ($arg eq '--vpar') {
    require Graph;
    my $graph = Graph->new (directed=>1);
    $graph->set_graph_attribute (name => $name);
    $graph->set_graph_attribute (flow => 'north');
    @ARGV = map {split /, /} @ARGV;
    foreach my $v0 (0 .. $#ARGV) {
      my $v1 = $v0 + 1;
      $graph->add_vertex($v1);
      my $p1 = $ARGV[$v0] || next;
      $graph->add_edge ($v1,$p1);
    }
    # print "$graph\n";
    # print $graph->vertices,"\n";
    # print scalar $graph->vertices,"\n";
    MyGraphs::Graph_view($graph);
    last;
  }
  # if ($arg eq '--hog') {
  #   # ...
  #   next;
  # }
  die "unrecognised option $arg";
}
exit 0;
