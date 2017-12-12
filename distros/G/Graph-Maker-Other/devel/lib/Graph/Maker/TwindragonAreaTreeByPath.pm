# Copyright 2015, 2016, 2017 Kevin Ryde
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

package Graph::Maker::BinaryBeanstalk;
use 5.004;
use strict;
use Graph::Maker;
use Math::PlanePath::ComplexPlus;
use Math::PlanePath::DragonCurve 117; # v.117 for level_to_n_range()

use vars '$VERSION','@ISA';
$VERSION = 10;
@ISA = ('Graph::Maker');

# uncomment this to run the ### lines
# use Smart::Comments;


sub _default_graph_maker {
  require Graph;
  Graph->new(@_);
}
sub init {
  my ($self, %params) = @_;

  my $level = delete($params{level}) || 0;
  my $graph_maker = delete($params{'graph_maker'}) || \&_default_graph_maker;
  ### $level

  my $graph = $graph_maker->(%params);
  $graph->set_graph_attribute(name => "Twindragon Area Tree $level by Path");

  my $path = Math::PlanePath::DragonCurve->new;
  my ($n_lo, $n_hi) = $path->level_to_n_range($level+1);

  # plain
  _planepath_area_tree($path, $graph, $n_lo, $n_hi, 'left');

  # rotated 180
  my ($x_hi,$y_hi) = $path->n_to_xy($n_hi);
  ### n range: "$n_lo, $n_hi"
  ### xy hi: "$x_hi,$y_hi"
  _planepath_area_tree($path, $graph, $n_lo, $n_hi, 'left',
                       sub {
                         my ($x,$y) = @_;
                         return ($x_hi-$x, $y_hi-$y);
                       });
  return $graph;
}
sub _transform_none {
  return @_;
}

# Unit squares on $side="left" or "right" of the segments of $path.
# Vertices numbered by ComplexPlus
#
#             1,1
#
#       0,0 -------- 1,0
#
sub _planepath_area_tree {
  my ($path, $graph, $n_lo, $n_hi, $side, $transform) = @_;
  $transform ||= \&_transform_none;
  $side ||= 'right';
  my ($prev_x,$prev_y) = $path->n_to_xy($n_lo);
  ($prev_x,$prev_y) = $transform->($prev_x,$prev_y);
  my $prev_v;

  my $plus = Math::PlanePath::ComplexPlus->new;
  foreach my $n ($n_lo+1 .. $n_hi) {
    my ($x,$y) = $path->n_to_xy($n);
    ($x,$y) = $transform->($x,$y);
    my $dx = $x - $prev_x;
    my $dy = $y - $prev_y;
    my ($lx,$ly) = ($side eq 'left'
                    ? (-$dy,$dx)   # rotate +90
                    : ($dy,-$dx)); # rotate -90
    my $mx = 2*$prev_x + $dx + $lx;
    my $my = 2*$prev_y + $dy + $ly;

    my $v;

    {
      # Vertex names by ComplexPlus N
      ($mx,$my) = ($mx + $my, $my - $mx); # mul 1-i
      ($mx,$my) = ($my,-$mx); # rotate -90
      $my += 2;
      $mx /= 4;
      $my /= 4;
      ### xy: "$x,$y  prev  $prev_x,$prev_y  lxy $lx,$ly"
      ### mxy: "$mx,$my"
      $v = $plus->xy_to_n($mx,$my)
        // die;
    }

    # {
    #   # Vertex names by mx,my integers
    #   $v = "$mx,$my";
    # }
    #
    # {
    #   # Vertex names by lower left corner of square
    #   $mx = ($mx - ($mx % 2))/2;
    #   $my = ($my - ($my % 2))/2;
    #   $v = "$mx,$my";
    # }

    if (defined $prev_v && $v ne $prev_v) {
      $graph->add_edge($prev_v, $v);
    }
    ($prev_x,$prev_y) = ($x,$y);
    $prev_v = $v;
  }
  if (defined $prev_v) {
    $graph->add_vertex($prev_v);
  }
  return $graph;
}

Graph::Maker->add_factory_type('twindragon_area_tree_by_path' => __PACKAGE__);
1;
