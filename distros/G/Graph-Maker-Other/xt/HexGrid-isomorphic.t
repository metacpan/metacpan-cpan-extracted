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

use Graph::Maker::HexGrid;

use lib 'devel/lib';
use MyGraphs;

# uncomment this to run the ### lines
# use Smart::Comments;

plan tests => 285;


#------------------------------------------------------------------------------
# POD HOG Shown

{
  my %shown = ('1,1,1' => 670,
               '2,2,2' => 28529,
               '3,3,3' => 28500,
              );
  my $extras = 0;
  my %seen;
  foreach my $X (1 .. 4) {
    foreach my $Y ($X .. 4) {
      foreach my $Z ($Y .. 4) {
        my $graph = Graph::Maker->new('hex_grid', undirected => 1,
                                      dims => [$X,$Y,$Z]);
        my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
        $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
        next if $seen{$g6_str}++;
        my $key = "$X,$Y,$Z";
        if (my $id = $shown{$key}) {
          MyGraphs::hog_compare($id, $g6_str);
        } else {
          if (MyGraphs::hog_grep($g6_str)) {
            my $name = $graph->get_graph_attribute('name');
            MyTestHelpers::diag ("HOG $key not shown in POD");
            MyTestHelpers::diag ($name);
            MyTestHelpers::diag ($g6_str);
            MyGraphs::Graph_view($graph);
            $extras++;
          }
        }
      }
    }
  }
  ok ($extras, 0);
}

#------------------------------------------------------------------------------
# hex grid of 1,1 as ladder

{
  require Graph::Maker::Ladder;
  foreach my $n (1 .. 4) {
    my $rungs = 2*$n+1;
    my $ladder = Graph::Maker->new('ladder', rungs=>$rungs, undirected=>1);
    # this depends on the vertex numbering given by Graph::Maker::Ladder
    for (my $v = 2; $v < $rungs; $v+=2) {
      $ladder->delete_edge($v, $v+$rungs);
    }
    # MyGraphs::Graph_view($ladder);

    my $graph  = Graph::Maker->new('hex_grid', dims=>[$n,1,1], undirected=>1);

    ok (!!MyGraphs::Graph_is_isomorphic($graph,$ladder), 1);
  }
}

#------------------------------------------------------------------------------
# dims permutations are isomorphic

{
  require Math::Permute::Array;
  foreach my $undirected (0,1) {
    foreach my $x (1 .. 3) {
      foreach my $y ($x .. 4) {
        foreach my $z ($y .. 5) {
          my $dims_str = "$x,$y,$z";
          my $graph1 = Graph::Maker->new('hex_grid', dims=>[$x,$y,$z],
                                         undirected=>$undirected);
          my $graph1_name = $graph1->get_graph_attribute('name');
          foreach my $p (1 .. 5) {
            my $dims = Math::Permute::Array::Permute($p,[$x,$y,$z]);
            ### $dims
            my $graph2 = Graph::Maker->new('hex_grid', dims=>$dims,
                                           undirected=>$undirected);
            my $graph2_name = $graph2->get_graph_attribute('name');

            ok (!!MyGraphs::Graph_is_isomorphic($graph1,$graph2), 1,
                "$dims_str  $graph1_name vs $graph2_name");
          }
        }
      }
    }
  }
}

#------------------------------------------------------------------------------
exit 0;
