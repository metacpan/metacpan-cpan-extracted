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
use List::Util 'min';
use Graph;

use FindBin;
use lib "$FindBin::Bin/../devel/lib";
use MyGraphs;
$|=1;

# uncomment this to run the ### lines
use Smart::Comments;



{
  # Three Plug Tree, de Sa et al
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30657

  # Vinicius G.P. de Sa, Celina M.H. de Figueiredo, Guilherme D. da Fonseca,
  # Raphael Machado, "Complexity Dichotomy on Partial Grid Recognition",
  # Theoretical Computer Science, volume 412, 2011, pages 2370-2379.
  # Extended version
  # http://vigusmao.github.io/manuscripts/journals/PartialGrids.pdf

  my $graph = Graph->new (undirected => 1);
  $graph->set_graph_attribute (vertex_name_type_xy => 1);
  add_xy_path($graph, -3,0, 3,0);
  add_xy_path($graph, -2,0, -2,-2);
  add_xy_path($graph, -2,-1, -1,-1);
  add_xy_path($graph, -1,0, -1,3);
  add_xy_path($graph, -1,2, 0,2);
  add_xy_path($graph, -1,1, -3,1);
  add_xy_path($graph, -2,1, -2,2);
  add_xy_path($graph, 1,0, 1,2);
  add_xy_path($graph, 1,1, 0,1);
  add_xy_path($graph, 2,0, 2,2);
  add_xy_path($graph, 2,1, 3,1);

  add_xy_path($graph, 0,0, 0,-3);
  add_xy_path($graph, 0,-2, -1,-2);
  add_xy_path($graph, 0,-1, 2,-1);
  add_xy_path($graph, 1,-1, 1,-3);
  add_xy_path($graph, 1,-2, 2,-2);

  $graph->is_connected or die;
  $graph->is_acyclic or die;

  # GP-Test  4*4 + 2*2 + 3 == 23  /* vertices */

  my $num_vertices = $graph->vertices;
  my $num_edges    = $graph->edges;
  my $diameter = $graph->diameter;
  print "vertices $num_vertices edges $num_edges diameter $diameter\n";

  MyGraphs::Graph_xy_print($graph);
  # MyGraphs::Graph_view($graph);
  MyGraphs::hog_searches_html($graph);
  exit 0;
}
{
  # Windmill Tree, de Sa et al
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30655

  # Vinicius G.P. de Sa, Celina M.H. de Figueiredo, Guilherme D. da Fonseca,
  # Raphael Machado, "Complexity Dichotomy on Partial Grid Recognition",
  # Theoretical Computer Science, volume 412, 2011, pages 2370-2379.
  # In extended version
  # http://vigusmao.github.io/manuscripts/journals/PartialGrids.pdf

  my $graph = Graph->new (undirected => 1);
  $graph->set_graph_attribute (vertex_name_type_xy => 1);
  foreach my $rot (0..3) {
    my $addrot = sub {
      my ($x1,$y1, $x2,$y2) = @_;
      foreach (1..$rot) {
        ($x1,$y1) = xy_rotate_plus90($x1,$y1);
        ($x2,$y2) = xy_rotate_plus90($x2,$y2);
      }
      add_xy_path($graph, $x1,$y1, $x2,$y2);
    };
    $addrot->(0,0, 2,0);
    $addrot->(1,0, 1,1);
    $addrot->(2,-1, 2,1);
  }

  $graph->is_connected or die;
  $graph->is_acyclic or die;

  my $num_vertices = $graph->vertices;
  my $num_edges    = $graph->edges;
  my $diameter = $graph->diameter;
  print "vertices $num_vertices edges $num_edges diameter $diameter\n";

  print "degrees ";
  my @degrees;
  foreach my $v ($graph->vertices) {
    $degrees[$graph->vertex_degree($v)]++;
  }
  foreach my $d (0 .. $#degrees) {
    if ($degrees[$d]) { print "$d,"; }
  }
  print "\ncounts  ";
  foreach my $d (0 .. $#degrees) {
    if ($degrees[$d]) { print "$degrees[$d],"; }
  }
  print "\n";

  # MyGraphs::Graph_view($graph);
  MyGraphs::Graph_xy_print($graph);
  MyGraphs::hog_searches_html($graph);
  exit 0;
}
{
  # Gregori U-tree

  # FIXME one less bottom-most leaf ?

  # A. Gregori, "Unit-Length Embedding of Binary Trees On a Square Grid",
  # Information Processing Letters, volume 31, 1989, pages 167-173.
  #
  # de Sa et al PartialGrids.pdf draw with some mirror image instead of
  # rotation

  my $graph = Graph->new (undirected => 1);
  $graph->set_graph_attribute (vertex_name_type_xy => 1);
  my $add = sub {
    my ($x1,$y1, $x2,$y2) = @_;
    my $dx = $x2 - $x1;
    my $dy = $y2 - $y1;
    if ($dx) { $dx /= abs($dx); }
    if ($dy) { $dy /= abs($dy); }
    while ($x1 != $x2 || $y1 != $y2) {
      my $next_x = $x1 + $dx;
      my $next_y = $y1 + $dy;
      if ($graph->has_edge("$x1,$y1", "$next_x,$next_y")) { die; }
      $graph->add_edge("$x1,$y1", "$next_x,$next_y");
      $x1 = $next_x;
      $y1 = $next_y;
    }
  };
  add_xy_path($graph, 0,-1, 0,1);
  add_xy_path($graph, 0,0, 1,0);
  add_xy_path($graph, 1,1, -1,1);
  add_xy_path($graph, 1,-1, -1,-1);
  add_xy_path($graph, -2,0, -1,0);

  foreach my $rot (0..3) {
    my $addrot = sub {
      my ($x1,$y1, $x2,$y2) = @_;
      foreach (1..$rot) {
        ($x1,$y1) = xy_rotate_plus90($x1,$y1);
        ($x2,$y2) = xy_rotate_plus90($x2,$y2);
      }
      add_xy_path($graph, $x1,$y1, $x2,$y2);
    };
    $addrot->(1,1, 6,1);
    $addrot->(3,1, 3,0);
    $addrot->(5,1, 5,2);

    $addrot->(2,1, 2,4);
    $addrot->(2,4, 3,4);
    $addrot->(2,2, 4,2);
    $addrot->(3,2, 3,3);
    $addrot->(4,2, 4,3);

    $addrot->(1,1, 1,6);
    $addrot->(1,2, 0,2);
    $addrot->(1,5, 2,5);
    $addrot->(1,4, 0,4);
    $addrot->(0,4, 0,6);
  }
  $graph->is_connected or die;

  # GP-Test  6*7/2*4 + 13 + 12 == 109  /* vertices */

  my $num_vertices = $graph->vertices;
  my $num_edges    = $graph->edges;
  # my $diameter = $graph->diameter;
  my @diameter = MyGraphs::Graph_tree_diameter_path($graph);
  my $diameter = scalar(@diameter) - 1;
  print "vertices $num_vertices edges $num_edges diameter $diameter\n";

  print "degrees ";
  my @degrees;
  foreach my $v ($graph->vertices) {
    $degrees[$graph->vertex_degree($v)] = 1;
  }
  foreach my $d (0 .. $#degrees) {
    if ($degrees[$d]) { print "$d,"; }
  }
  print "\n";

  # MyGraphs::Graph_view($graph);
  MyGraphs::Graph_xy_print($graph);
  MyGraphs::hog_searches_html($graph);
  exit 0;
}

{
  # Double Ladder, de Sa et al
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30648

  # Vinicius G.P. de Sa, Celina M.H. de Figueiredo, Guilherme D. da Fonseca,
  # Raphael Machado, "Complexity Dichotomy on Partial Grid Recognition",
  # Theoretical Computer Science, volume 412, 2011, pages 2370-2379.

  my $graph = Graph->new (undirected => 1);
  $graph->set_graph_attribute (vertex_name_type_xy => 1);
  add_xy_path($graph, 0,0, 4,0);
  add_xy_path($graph, 0,0, 0,4);
  add_xy_path($graph, 4,4, 0,4);
  add_xy_path($graph, 4,4, 4,0);

  add_xy_path($graph, 1,0, 1,4);  # verticals
  add_xy_path($graph, 3,0, 3,4);

  add_xy_path($graph, 0,1, 1,1);
  add_xy_path($graph, 0,3, 1,3);
  add_xy_path($graph, 3,1, 4,1);
  add_xy_path($graph, 3,3, 4,3);

  add_xy_path($graph, 1,2, 3,2);

  $graph->is_connected or die;
  $graph->is_cyclic or die;

  # GP-Test  4*4 + 2*2 + 3 == 23  /* vertices */

  my $num_vertices = $graph->vertices;
  my $num_edges    = $graph->edges;
  my $diameter = $graph->diameter;
  print "vertices $num_vertices edges $num_edges diameter $diameter\n";

  print "degrees ";
  my @degrees;
  foreach my $v ($graph->vertices) {
    $degrees[$graph->vertex_degree($v)] = 1;
  }
  foreach my $d (0 .. $#degrees) {
    if ($degrees[$d]) { print "$d,"; }
  }
  print "\n";

  MyGraphs::Graph_xy_print($graph);
  # MyGraphs::Graph_view($graph);
  MyGraphs::hog_searches_html($graph);
  exit 0;
}









sub add_xy_path {
  my ($graph, $x1,$y1, $x2,$y2) = @_;
  my $dx = $x2 - $x1;
  my $dy = $y2 - $y1;
  if ($dx) { $dx /= abs($dx); }
  if ($dy) { $dy /= abs($dy); }
  while ($x1 != $x2 || $y1 != $y2) {
    my $next_x = $x1 + $dx;
    my $next_y = $y1 + $dy;
    if ($graph->has_edge("$x1,$y1", "$next_x,$next_y")) { die; }
    $graph->add_edge("$x1,$y1", "$next_x,$next_y");
    $x1 = $next_x;
    $y1 = $next_y;
  }
}

sub xy_rotate_plus90 {
  my ($x,$y) = @_;
  return (-$y,$x);  # rotate +90
}
sub xy_rotate_minus90 {
  my ($x,$y) = @_;
  return ($y,-$x);  # rotate -90
}
