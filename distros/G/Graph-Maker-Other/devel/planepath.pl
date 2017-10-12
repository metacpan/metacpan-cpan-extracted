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
use Math::BaseCnv 'cnv';

use FindBin;
use lib "$FindBin::Bin/lib";
use MyGraphs;

# uncomment this to run the ### lines
# use Smart::Comments;


{
  # TriangularHypot hexagon of hexagons
  # N=1..24 2x2 hog not
  # N=1..54 3x3
  require Graph::Maker::PlanePath;
  my $graph = Graph::Maker->new
    ('planepath',
     undirected=>1,
     n_hi => 24,
     n_hi => 54,
     type => 'neighbours6',
     planepath => 'TriangularHypot,points=hex_centred',
     vertex_name_type => 'xy',
    );
  MyGraphs::Graph_view($graph);
  MyGraphs::hog_searches_html($graph);

  require Math::PlanePath::TriangularHypot;
  my $path = Math::PlanePath::TriangularHypot->new (points=>'hex_centred');
  foreach my $n (1 .. 54) {
    my ($x,$y) = $path->n_to_xy($n);
    print $x**2 + 3*$y**2, "\n";
  }
  exit 0;
}

{
  # hog trees and paths

  # state machines
  # Rpred high to low -- not
  # Lpred high to low, and reverse -- not
  # Rpred+Lpred for bridges -- not
  # complex plus boundary state machine and reversed -- not
  # C right boundary and reverse -- not
  # C doubles and reverse -- not
  # Terdragon Eboth -- not

  my @graphs;
  for (my $k = 2; @graphs < 6; $k++) {
    print "________________________________________________________\nk=$k\n";
    my $graph;

    # {
    #   # R5 quad-r5dragon 4-cycle k=1 not
    #   require Graph::Maker::R5Twindragon;
    #   $graph = Graph::Maker->new('r5twindragon', level=>$k, arms=>1,
    #                              undirected=>1);
    # }
    # {
    #   # Dragon blob
    #   #   k=4 https://hog.grinvin.org/ViewGraphInfo.action?id=674 single square
    #   #   k=5 https://hog.grinvin.org/ViewGraphInfo.action?id=25223
    #   #   k=6 not
    #   require Graph::Maker::Dragon;
    #   $graph = Graph::Maker->new('dragon', level=>$k,
    #                              part=>'blob',
    #                              undirected=>1);
    # }
    {
      # Dragon k=4,5 not
      # R5Dragon
      #   k=2 https://hog.grinvin.org/ViewGraphInfo.action?id=25149
      #   k=3 https://hog.grinvin.org/ViewGraphInfo.action?id=25147
      # Terdragon
      #   k=2  https://hog.grinvin.org/ViewGraphInfo.action?id=21138
      #   k=3  https://hog.grinvin.org/ViewGraphInfo.action?id=21140
      #   cf k=2 not same as boat 8 vertices of Christophe et al Graphedron
      #        *---*
      #         \
      #      *---*
      #       \ / \
      #        *---*
      #         \
      #      *---*
      # CCurve k=4..5 not
      require Graph::Maker::PlanePath;
      $graph = Graph::Maker->new('planepath',
                                 undirected=>1,
                                 level=>$k,
                                 planepath=>'AlternatePaper');
    }

    # UlamWarburton depth=2..3 not
    # UlamWarburton,parts=2 depth=3..4 not
    #  depth=2 https://hog.grinvin.org/ViewGraphInfo.action?id=816
    # UlamWarburton,parts=1 depth=3..4 not
    #  depth=4 same as SierpinskiTriangle depth=4
    # UlamWarburton,parts=octant depth=5..6 not
    # LCornerTree,parts=2 depth=3..4 not
    #  depth=2 https://hog.grinvin.org/ViewGraphInfo.action?id=452
    # ToothpickTree depth=3 (stage=4)
    #               https://hog.grinvin.org/ViewGraphInfo.action?id=25170
    # ToothpickTree depth=4..5 not
    # ToothpickTree,parts=1 depth=4..5 not
    # ToothpickTree,parts=2 depth=4..5 not
    # ToothpickTree,parts=octant depth=5..7 not
    # ToothpickTree,parts=wedge depth=5..7 not
    # OneOfEightTree,parts=4 depth=2..3 not
    # OneOfEightTree,parts=1 depth=3..4 not
    #  depth=1 fork https://hog.grinvin.org/ViewGraphInfo.action?id=30
    # OneOfEightTree,parts=octant depth=4..5 not
    #  depth=3 https://hog.grinvin.org/ViewGraphInfo.action?id=792
    # ComplexPlus neighbours4 level=4 not
    #  level=3 https://hog.grinvin.org/ViewGraphInfo.action?id=700
    # KochCurve neighbours6 level=2 not
    #   k=1 triangle+sides https://hog.grinvin.org/ViewGraphInfo.action?id=240
    #   also is SierpinskiTriangle rows 0 to 4 connected
    # SierpinskiTriangle
    #   depth=3 hog not
    #   depth=4 https://hog.grinvin.org/ViewGraphInfo.action?id=278 [done]
    #   depth=5,6,7 not
    #  neighbours6 level=2,3 not
    #  neighbours cf Hanoi graph H2
    # {
    #   require Graph::Maker::PlanePath;
    #   $graph = Graph::Maker->new('planepath',
    #                              undirected=>1,
    #                              # level=>$k,
    #                              depth => $k,
    #                              planepath => 'ToothpickTree',
    #                              # type => 'neighbours6',
    #                             );
    # }

    # {
    #   # BalancedTree
    #   # binary not 4,5
    #   #   height=3 https://hog.grinvin.org/ViewGraphInfo.action?id=498
    #   # ternary not 4
    #   #   height=3 https://hog.grinvin.org/ViewGraphInfo.action?id=662
    #   # quad tree not 4
    #   require Graph::Maker::BalancedTree;
    #   $graph = Graph::Maker->new('balanced_tree',
    #                              fan_out => 2, height => $k,
    #                             );
    # }

    # Graph_branch_reduce($graph);
    # print "delete hanging cycles " . Graph_delete_hanging_cycles($graph) . "\n";

    # next if $graph->vertices == 0;
    last if $graph->vertices > 200;

    Graph_xy_print($graph);
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # leftist toothpicks

  # ToothpickUpist depth=6 not
  # depth=14 https://hog.grinvin.org/ViewGraphInfo.action?id=26981
  my @graphs;
  foreach my $depth (14) {
    require Graph::Maker::PlanePath;
    my $graph = Graph::Maker->new('planepath',
                                  undirected=>1,
                                  depth => $depth,
                                  planepath => 'ToothpickUpist',
                                  vertex_name_type => 'xy',
                                 );
    Graph_view($graph);
    Graph_xy_print($graph);
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}


