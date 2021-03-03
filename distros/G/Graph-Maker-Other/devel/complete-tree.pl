#!/usr/bin/perl -w

# Copyright 2020 Kevin Ryde
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
use Math::BaseCnv 'cnv';
use Math::Trig 'pi';

use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'devel', 'lib');
use MyGraphs;
$|=1;

# uncomment this to run the ### lines
# use Smart::Comments;


{
  # Complete Binary
  #   h=1 n=3    32234  path-3
  #   h=2 n=7    498
  #   h=3 n=15   https://hog.grinvin.org/ViewGraphInfo.action?id=34618
  #   h=4 n=31   https://hog.grinvin.org/ViewGraphInfo.action?id=34620
  #   h=5 n=63   https://hog.grinvin.org/ViewGraphInfo.action?id=34622
  #   h=6 n=127  https://hog.grinvin.org/ViewGraphInfo.action?id=34624
  #   n=255 too big
  #
  # Complete Ternary
  #   h=1 n=4  claw
  #   h=2 n=13 https://hog.grinvin.org/ViewGraphInfo.action?id=662
  #   h=3 n=
  #   h=4 n=
  #
  # Complete 4-ary
  #
  require Graph::Maker::BalancedTree;
  my $num_children = 4;
  my @graphs;
  foreach my $rows (2..20) {
    my $graph = Graph::Maker->new('balanced_tree',
                                  fan_out => $num_children, height => $rows,
                                  undirected => 1,
                                 );
    my $num_vertices = $graph->vertices;
    my $h = $rows - 1;
    $graph->set_graph_attribute
      (name => "Complete $num_children-ary Tree, height $h ($rows rows, $num_vertices vertices)");
    last if $graph->vertices > 255;
    print "complete $num_children children\n";

    my $want_num_vertices = ($num_children**$rows - 1)/($num_children - 1);
    $num_vertices == $want_num_vertices
      or die "$num_vertices vs $want_num_vertices";

    MyGraphs::Graph_tree_height($graph,1) == $h or die;

    my @vertices = sort {$a<=>$b} $graph->vertices;
    print "  ",join(',',@vertices),"\n";
    balanced_tree_layout_rows($graph,$num_children);
    # balanced_tree_layout_around($graph,$num_children);
    push @graphs, $graph;
  }
  if (@graphs) {
    MyGraphs::hog_upload_html($graphs[2]);
    MyGraphs::hog_searches_html(@graphs);
  }
  exit 0;
}

sub balanced_tree_layout_rows {
  my ($graph,$num_children) = @_;
  my $height = MyGraphs::Graph_tree_height($graph,1);
  ### $num_children
  ### $height
  my $v = 1;
  my $spacing = $height+2;
  for (my $depth = 0; ; $depth++) {
    my $width = $num_children**$depth;
    ### $width
    ### $spacing
    my $pos = -($width-1)/2 * $spacing;
    foreach my $i (1 .. $width) {
      $graph->has_vertex($v) or return;
      ### set: "$v to $pos -$depth"
      MyGraphs::Graph_set_xy_points($graph, $v => [$pos,-$depth]);
      $pos += $spacing;
      $v++;
    }
    $spacing /= $num_children;
  }
}
sub balanced_tree_layout_around {
  my ($graph,$num_children) = @_;
  my $height = MyGraphs::Graph_tree_height($graph,1);
  my $v = 1;
  for (my $depth = 0; ; $depth++) {
    $graph->has_vertex($v) or return;
    my $width = $num_children**$depth;
    ### $width
    foreach my $i (0 .. $width-1) {
      $graph->has_vertex($v) or return;
      my $a = 2*pi() * ($i-($width-1)/2) / $width;
      MyGraphs::Graph_set_xy_points($graph, $v => [$depth*cos($a),
                                                   $depth*sin($a)]);
      $v++;
    }
  }
}
