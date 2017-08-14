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
use MyGraphs;

use FindBin;
use lib "$FindBin::Bin/lib";
use Graph::Maker::GosperIsland;

# uncomment this to run the ### lines
# use Smart::Comments;

{
  # level 2 points
  my @graphs;
  my $k = 2;
  my $graph = Graph::Maker->new('Gosper_island', undirected => 1, level => $k);

  require Image::Base::Text;
  my $image = Image::Base::Text->new (-width => 80, -height => 24);
  my $offset_x = 18;
  my $offset_y = 10;

  foreach my $v ($graph->vertices) {
    my ($x,$y) = split /,/, $v;
    $x += $offset_x;
    $y += $offset_y;
    $image->xy($x,$y, '*');
  }
  $image->save('/dev/stdout');
  exit 0;
}
{
  # level 1 picture
  my @graphs;
  my $k = 1;
  my $graph = Graph::Maker->new('Gosper_island', undirected => 1, level => $k);
  MyGraphs::Graph_xy_print($graph);
  exit 0;
}
{
  # diameter 3, 7, 19
  my @graphs;
  foreach my $level (0 .. 3) {
    my $graph = Graph::Maker->new('Gosper_island', undirected => 1,
                                  level => $level);
    if (0) { MyGraphs::Graph_view($graph); }
    my $num_vertices = $graph->vertices;
    my $num_edges    = $graph->edges;
    print "k=$level  vertices $num_vertices edges $num_edges\n";
    my $diameter     = $graph->diameter;
    print "  diameter $diameter\n";
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # HOG by planepath

  my @graphs;
  for (my $k = 0; ; $k++) {
    if (@graphs > 3) {
      print "stop at ",scalar(@graphs)," graphs\n";
      last;
    }

    my $graph;

    # Flowsnake neighbours6 level=1..2 not
    # FlowsnakeCentres neighbours6 level=1..2 not
    #   level=1 would be wheel 7
    {
      require Graph::Maker::PlanePath;
      $graph = Graph::Maker->new('planepath',
                                 undirected=>1,
                                 level=>$k,
                                 # planepath => 'KochCurve',
                                 planepath => 'TerdragonCurve',
                                 # planepath => 'FlowsnakeCentres',
                                 # planepath => 'Flowsnake',
                                 type => 'neighbours6',

                                 # planepath => 'DragonCurve',
                                 # type => 'neighbours4',
                                );
    }

    # next if $graph->vertices == 0;
    my $num_vertices = $graph->vertices;
    if ($num_vertices > 200) {
      print "stop for num_vertices = $num_vertices\n";
      last;
    }

    Graph_view($graph, xy=>1);
    push @graphs, $graph;
  }
  hog_searches_html(@graphs);
  exit 0;
}
