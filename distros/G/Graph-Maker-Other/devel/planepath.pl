#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017, 2018, 2019, 2021 Kevin Ryde
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
use Carp 'croak';
use POSIX 'round';
use List::Util 'min','max','sum';

use FindBin;
use lib "$FindBin::Bin/lib";
use MyGraphs;
$|=1;

# uncomment this to run the ### lines
# use Smart::Comments;


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
  for (my $k = 1; @graphs <= 10; $k++) {
    print "________________________________________________________\nk=$k\n";
    my $graph;

    # {
    #   # R5 quad-r5dragon 4-cycle k=1 not
    #   require Graph::Maker::R5Twindragon;
    #   $graph = Graph::Maker->new('r5twindragon', level=>$k, arms=>1,
    #                              undirected=>1);
    # }
    if (0) {
      # Dragon
      #   k=3  https://hog.grinvin.org/ViewGraphInfo.action?id=414 path-9
      #   k=4  https://hog.grinvin.org/ViewGraphInfo.action?id=33739
      #   k=5  https://hog.grinvin.org/ViewGraphInfo.action?id=33741
      #   k=6  https://hog.grinvin.org/ViewGraphInfo.action?id=33743
      #   k=7  https://hog.grinvin.org/ViewGraphInfo.action?id=33745
      #   k=8  https://hog.grinvin.org/ViewGraphInfo.action?id=33747
      # Dragon blob
      #   k=4  https://hog.grinvin.org/ViewGraphInfo.action?id=674  unit square
      #   k=5  https://hog.grinvin.org/ViewGraphInfo.action?id=25223
      #   k=6  https://hog.grinvin.org/ViewGraphInfo.action?id=33749
      #   k=7  https://hog.grinvin.org/ViewGraphInfo.action?id=33751
      #   k=8  https://hog.grinvin.org/ViewGraphInfo.action?id=33753
      #   k=8  https://hog.grinvin.org/ViewGraphInfo.action?id=34163
      # BlobP(8) == 68
      # BlobP(9) == 133
      # BlobP(10) == 257
      require Graph::Maker::Dragon;
      $graph = Graph::Maker->new('dragon', level=>$k,
                                 part=>'all',
                                 part=>'blob',
                                 undirected=>1);
    }
    if (0) {
      # Twindragon
      #   k=1  https://hog.grinvin.org/GraphAdded.action?id=33755    2 squares
      #   k=2  https://hog.grinvin.org/GraphAdded.action?id=22744    4 squares
      #   k=3  https://hog.grinvin.org/GraphAdded.action?id=25145
      #   k=4  https://hog.grinvin.org/GraphAdded.action?id=25174
      #   k=5  https://hog.grinvin.org/GraphAdded.action?id=33757
      #   k=6  
      # TP(6) == 171
      # TP(7) == 329
      require Graph::Maker::Twindragon;
      $graph = Graph::Maker->new('twindragon', level=>$k,
                                 undirected=>1);
    }
    if (1) {
      # R5DragonCurve
      #   k=1 https://hog.grinvin.org/ViewGraphInfo.action?id=25149 5 segs path
      #   k=2 https://hog.grinvin.org/ViewGraphInfo.action?id=25149
      #   k=3 https://hog.grinvin.org/ViewGraphInfo.action?id=25147
      #
      # TerdragonCurve
      #   k=2  https://hog.grinvin.org/ViewGraphInfo.action?id=21138
      #   k=3  https://hog.grinvin.org/ViewGraphInfo.action?id=21140
      #   k=4  https://hog.grinvin.org/ViewGraphInfo.action?id=33761
      #   k=5  https://hog.grinvin.org/ViewGraphInfo.action?id=33763
      #   cf k=2 not same as boat 8 vertices of Christophe et al Graphedron
      #        *---*
      #         \
      #      *---*
      #       \ / \
      #        *---*
      #         \
      #      *---*
      # AlternateTerdragon
      #   k=2 https://hog.grinvin.org/ViewGraphInfo.action?id=30397
      #   k=3 https://hog.grinvin.org/ViewGraphInfo.action?id=30399
      #   k=4 https://hog.grinvin.org/ViewGraphInfo.action?id=33575
      #   k=5 https://hog.grinvin.org/ViewGraphInfo.action?id=33577
      #
      # Math::PlanePath::AlternatePaper
      #   k=1 https://hog.grinvin.org/ViewGraphInfo.action?id=19655 1 segs path
      #   k=1 https://hog.grinvin.org/ViewGraphInfo.action?id=32234 2 segs path
      #   k=2 https://hog.grinvin.org/ViewGraphInfo.action?id=286   4 segs path
      #   k=3 https://hog.grinvin.org/ViewGraphInfo.action?id=27008
      #   k=4 https://hog.grinvin.org/ViewGraphInfo.action?id=27010
      #   k=5 https://hog.grinvin.org/ViewGraphInfo.action?id=27012
      #   k=6 https://hog.grinvin.org/ViewGraphInfo.action?id=33778
      #   k=7 https://hog.grinvin.org/ViewGraphInfo.action?id=33780
      #   k=8 https://hog.grinvin.org/ViewGraphInfo.action?id=33782
      # CCurve
      #   k=4 https://hog.grinvin.org/ViewGraphInfo.action?id=33785
      #   k=5 https://hog.grinvin.org/ViewGraphInfo.action?id=33787
      #   k=6 https://hog.grinvin.org/ViewGraphInfo.action?id=33789
      #   k=7 https://hog.grinvin.org/ViewGraphInfo.action?id=33791
      #   k=8 https://hog.grinvin.org/ViewGraphInfo.action?id=33793
      #
      # Math::PlanePath::HilbertSides
      #   k=1 https://hog.grinvin.org/ViewGraphInfo.action?id=286   path-5
      #   k=2 https://hog.grinvin.org/ViewGraphInfo.action?id=33785 like CCurve

      require Graph::Maker::PlanePath;
      $graph = Graph::Maker->new('planepath',
                                 undirected=>1,
                                 level=>$k,
                                 planepath=>'HilbertSides');
      $graph->set_graph_attribute('vertex_name_type_xy',1);
      if($k==400) {
        MyGraphs::Graph_view($graph);
      }
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

    my @vertices = $graph->vertices;
    my $num_vertices = scalar(@vertices);
    if ($num_vertices > 255) {
      print "stop $k with $num_vertices vertices above limit 255\n";
      last;
    }

    if ($num_vertices < 100) {
      MyGraphs::Graph_xy_print($graph);
    }
    my @degrees_histogram;
    foreach my $v (@vertices) {
      $degrees_histogram[$graph->degree($v)]++;
    }
    foreach my $degree (keys @degrees_histogram) {
      my $count = $degrees_histogram[$degree] || 0;
      print "degree $degree vertices $count\n";
    }
    push @graphs, $graph;

    if ($k == 9) {
      MyGraphs::hog_upload_html($graph,
                               # rotate_degrees => $k*-45 + 180,
                               );
    }
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  my $k = 4;

  require Graph::Maker::Dragon;
  my $graph = Graph::Maker->new('dragon', level=>$k,
                                part=>'blob',
                                part=>'all',
                                undirected=>1);
  MyGraphs::Graph_xy_print($graph);

  # require Graph::Maker::Twindragon;
  # my $graph = Graph::Maker->new('twindragon', level=>$k,
  #                               undirected=>1);

  # require Graph::Maker::PlanePath;
  # my $graph = Graph::Maker->new('planepath',
  #                               undirected=>1,
  #                               level=>$k,
  #                               vertex_name_type => 'xy',
  #                               planepath=>'TerdragonCurve');
  # $graph->set_graph_attribute('vertex_name_type_xy',1);
  # $graph->set_graph_attribute('vertex_name_type_xy_triangular',1);

  MyGraphs::hog_upload_html($graph);
  MyGraphs::hog_searches_html($graph);
  exit 0;
}

{
  my $str = '64-253%3B64-321%3B135-321%3B134-253%3B203-254%3B203-181%3B133-181%3B133-108%3B203-109%3B266-113%3B326-114%3B326-182%3B266-181%3B326-257%3B391-256%3B391-182%3B';
  my (@x,@y);
  while ($str =~ /(\d+)-(\d+)\%3B/g) {
    my $x = $1;
    my $y = $2;
    print "$x, $y\n";
    push @x, $x;
    push @y, $y;
  }
  print "x=[",join(',',@x),"]\n";
  print "y=[",join(',',@y),"]\n";
  print "plothraw(x,y)\n";

  # x=[64,64,135,134,203,203,133,133,203,266,326,326,266,326,391,391]
  # y=[253,321,321,253,254,181,181,108,109,113,114,182,181,257,256,182]
  # plothraw(x,-y,1)

}

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


