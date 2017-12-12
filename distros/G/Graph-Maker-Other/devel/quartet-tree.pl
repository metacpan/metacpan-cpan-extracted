#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017 Kevin Ryde
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
use List::Util 'min','max','sum';

use FindBin;
use lib "$FindBin::Bin/lib";
use MyGraphs;
use Graph::Maker::QuartetTree;

# uncomment this to run the ### lines
use Smart::Comments;



{
  # pictures and hog

  # level=0  https://hog.grinvin.org/ViewGraphInfo.action?id=19655
  # level=1  https://hog.grinvin.org/ViewGraphInfo.action?id=496
  # level=2  https://hog.grinvin.org/ViewGraphInfo.action?id=30345
  # level=3  https://hog.grinvin.org/ViewGraphInfo.action?id=30347

  my @graphs;
  foreach my $level (0 .. 3) {
    my $graph = Graph::Maker->new('quartet_tree',
                                  level => $level,
                                  undirected=>1);
    MyGraphs::Graph_xy_print($graph);
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # not working

  sub QuartetParent {
    my ($n) = @_;
    $n>=1 || die 'QuartetParent() is for n>=1';
    my $n_orig = $n;
    my $low = $n % 5;
    $n = int($n/5);
    while ($n%5==1) { $n = int($n/5); }
    my $r = $n%5;
    #               0   1   2   3   4
    my @forward = (-1, -1, +1, +1, -3);
    my @reverse = (-1, -1, -1, -1, -3);
    my $parent = $n_orig + ($r==0 ? $forward[$low] : $reverse[$low]);
    ### parent: "n=$n_orig  r=$r low=$low  parent=$parent"
    return $parent;
  }

  foreach my $k (2) {
    my $graph = Graph::Maker->new('quartet_tree',
                                  level => $k,
                                  undirected=>1);

    my $g2 = Graph->new(directed=>1,
                       );
    $g2->set_graph_attribute (flow => 'north');
    foreach my $n (1 .. 5**$k) {
      $g2->add_edge($n, QuartetParent($n));
    }
    print MyGraphs::Graph_is_isomorphic($graph,$g2) ? "yes" : "no", "\n";
    MyGraphs::Graph_view($g2);
  }
  exit 0;
}
