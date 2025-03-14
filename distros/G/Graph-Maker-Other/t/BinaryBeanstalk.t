#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017, 2018, 2019, 2020, 2021 Kevin Ryde
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
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use Test;
plan tests => 331;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Graph::Maker::BinaryBeanstalk;


#------------------------------------------------------------------------------
{
  my $want_version = 19;
  ok ($Graph::Maker::BinaryBeanstalk::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::BinaryBeanstalk->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::BinaryBeanstalk->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::BinaryBeanstalk->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# direction_type

foreach my $height (0 .. 8) {
  {
    my $graph = Graph::Maker->new('binary_beanstalk',
                                  height => $height,
                                  direction_type => 'bigger');
    foreach my $edge ($graph->edges) {
      my ($from,$to) = @$edge;
      ok ($from < $to, 1);
    }

    my $graph2 = Graph::Maker->new('binary_beanstalk',
                                   height => $height,
                                   direction_type => 'child');
    ok ($graph->eq($graph2)?1:0, 1);
  }
  {
    my $graph = Graph::Maker->new('binary_beanstalk',
                                  height => $height,
                                  direction_type => 'smaller');
    foreach my $edge ($graph->edges) {
      my ($from,$to) = @$edge;
      ok ($from > $to, 1);
    }

    my $graph2 = Graph::Maker->new('binary_beanstalk',
                                   height => $height,
                                   direction_type => 'parent');
    ok ($graph->eq($graph2)?1:0, 1);
  }
}


#------------------------------------------------------------------------------

{
  # height=0 empty
  my $graph = Graph::Maker->new('binary_beanstalk', height => 0);
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 0);
  my $num_edges = $graph->edges;
  ok ($num_edges, 0);
}
{
  # height=1
  my $graph = Graph::Maker->new('binary_beanstalk', height => 1);
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 1);
  my $num_edges = $graph->edges;
  ok ($num_edges, 0);
}
{
  #  0
  #  |
  #  1
  {
    my $graph = Graph::Maker->new('binary_beanstalk', height => 2);
    my $num_vertices = $graph->vertices;
    ok ($num_vertices, 2);
    my $num_edges = $graph->edges;
    ok ($num_edges, 2);
    ok ($graph->has_edge(0,1)?1:0, 1);
    ok ($graph->has_edge(1,0)?1:0, 1);
  }
  {
    my $graph = Graph::Maker->new('binary_beanstalk', height => 2,
                                  direction_type => 'bigger');
    my $num_vertices = $graph->vertices;
    ok ($num_vertices, 2);
    my $num_edges = $graph->edges;
    ok ($num_edges, 1);
    ok ($graph->has_edge(0,1)?1:0, 1);
    ok ($graph->has_edge(1,0)?1:0, 0);
  }
  {
    my $graph = Graph::Maker->new('binary_beanstalk', height => 2,
                                  direction_type => 'smaller');
    my $num_vertices = $graph->vertices;
    ok ($num_vertices, 2);
    my $num_edges = $graph->edges;
    ok ($num_edges, 1);
    ok ($graph->has_edge(0,1)?1:0, 0);
    ok ($graph->has_edge(1,0)?1:0, 1);
  }
}
{
  #   0
  #   |
  #   1
  #  /
  # 2
  my $graph = Graph::Maker->new('binary_beanstalk', N => 3);
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 3);
  ok ($graph->has_edge(0,1)?1:0, 1);
  ok ($graph->has_edge(1,0)?1:0, 1);
  ok ($graph->has_edge(1,2)?1:0, 1);
  ok ($graph->has_edge(2,1)?1:0, 1);
  ok ($graph->has_edge(0,2)?1:0, 0);
  ok ($graph->has_edge(2,0)?1:0, 0);
}



#------------------------------------------------------------------------------
# height

foreach my $height (0 .. 10) {
  my $graph = Graph::Maker->new('binary_beanstalk',
                                height => $height,
                                undirected => 1);
  my $got = Graph_height($graph,0);
  ok ($got, $height);
}

sub Graph_height {
  my ($graph, $root) = @_;
  my $num_vertices = scalar($graph->vertices);
  if ($num_vertices < 2) { return $num_vertices; }
  return ($graph->vertex_eccentricity($root) || 0) + 1;
}


#------------------------------------------------------------------------------
# N num vertices

foreach my $N (0 .. 20) {
  foreach my $undirected (0, 1) {
    foreach my $multiedged (0, 1) {
      my $graph = Graph::Maker->new('binary_beanstalk',
                                    N => $N,
                                    undirected => $undirected,
                                    multiedged => $multiedged);
      my $num_vertices = $graph->vertices;
      ok ($num_vertices, $N);

      my $num_edges = $graph->edges;
      ok ($num_edges,
          ($N==0 ? 0 : $N-1) * ($undirected ? 1 : 2),
          "num_edges N=$N");
    }
  }
}


#------------------------------------------------------------------------------
# height vs N

{
  my $h = Graph::Maker->new('binary_beanstalk', height => 0);  # empty graphs
  my $g = Graph::Maker->new('binary_beanstalk', N => 0);
  ok ($g eq $h, 1);
}
{
  my $h = Graph::Maker->new('binary_beanstalk', height => 1);
  my $g = Graph::Maker->new('binary_beanstalk', N => 1);
  ok ($g eq $h, 1);
}
{
  my $h = Graph::Maker->new('binary_beanstalk', height => 2);
  my $g = Graph::Maker->new('binary_beanstalk', N => 2);
  ok ($g eq $h, 1);
}
{
  my $h = Graph::Maker->new('binary_beanstalk', height => 3);
  my $g = Graph::Maker->new('binary_beanstalk', N => 4);  # 4 vertices
  ok ($g eq $h, 1);
}
{
  my $h = Graph::Maker->new('binary_beanstalk', height => 4);
  my $g = Graph::Maker->new('binary_beanstalk', N => 6);  # 6 vertices
  ok ($g eq $h, 1);
}


#------------------------------------------------------------------------------
exit 0;
