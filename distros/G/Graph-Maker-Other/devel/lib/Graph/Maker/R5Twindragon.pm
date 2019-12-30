# Copyright 2015, 2016, 2017, 2018, 2019 Kevin Ryde
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

package Graph::Maker::R5Twindragon;
use 5.004;
use strict;
use Graph::Maker;
use Math::PlanePath::R5DragonCurve 117; # v.117 for level_to_n_range()

use vars '$VERSION','@ISA';
$VERSION = 14;
@ISA = ('Graph::Maker');

# uncomment this to run the ### lines
use Smart::Comments;

sub _default_graph_maker {
  require Graph;
  Graph->new(@_);
}
sub _make_graph {
  my ($params) = @_;
  my $graph_maker = delete($params->{'graph_maker'}) || \&_default_graph_maker;
  return $graph_maker->(%$params);
}

sub init {
  my ($self, %params) = @_;

  my $level = delete($params{'level'}) || 0;
  my $arms = delete($params{'arms'}) || 1;
  my $graph = _make_graph(\%params);
  $graph->set_graph_attribute(name =>
                              "R5 Twindragon level=$level"
                              . ($arms != 1 ? ", arms=$arms" : ''));

  my $path = Math::PlanePath::R5DragonCurve->new;
  my ($n_lo, $n_hi) = $path->level_to_n_range($level);
  ($n_lo,$n_hi) = (4*$n_hi, 8*$n_hi);
  ### $n_lo
  ### $n_hi

  my ($x_hi,$y_hi) = $path->n_to_xy($n_hi);

  # if ($arms > 1) {
  #   my ($x,$y) = (-$x,-$y);
  #   my ($prev_x,$prev_y) = (-$prev_x,-$prev_y);
  #   $graph->add_edge("$prev_x,$prev_y", "$x,$y");
  #   $graph->add_edge(($x_hi-$prev_x).','.($y_hi-$prev_y),
  #                    ($x_hi-$x)     .','.($y_hi-$y));
  # }

  my ($prev_x,$prev_y) = $path->n_to_xy($n_lo);
  foreach my $n ($n_lo+1 .. $n_hi) {
    my ($x,$y) = $path->n_to_xy($n);
    $graph->add_edge("$prev_x,$prev_y", "$x,$y");
    ($prev_x,$prev_y) = ($x,$y);
  }

  return $graph;
}

Graph::Maker->add_factory_type('r5twindragon' => __PACKAGE__);
1;




  # my $path = Math::PlanePath::DragonCurve->new;
  # my $num_vertices = 0;
  # my @point;
  # my ($n_lo, $n_hi) = $path->level_to_n_range($level+1);
  # my ($x_hi,$y_hi) = $path->n_to_xy($n_hi);
  # foreach my $n ($n_lo .. $n_hi) {
  #   my ($x,$y) = $path->n_to_xy($n);
  #   foreach (0,1) {
  #     {
  #       my ($x,$y) = ($x,$y);
  #       foreach my $arm (1 .. $arms) {
  #         unless ($seen{"$x,$y"}++) {
  #           $point[$num_vertices++] = [$x,$y];
  #         }
  #         ($x,$y) = (-$x,-$y);
  #       }
  #     }
  #     ($x,$y) = ($x_hi-$x, $y_hi-$y);
  #   }
  # }

  # foreach my $k (10,
  #                # 0 .. 6,
  #               ) {
  #   my %seen;
  #   my ($n_lo, $n_hi) = $path->level_to_n_range($k+1);
  #   my ($x_hi,$y_hi) = $path->n_to_xy($n_hi);
  #   foreach my $n ($n_lo .. $n_hi) {
  #     my ($x,$y) = $path->n_to_xy($n);
  #     foreach (0,1) {
  #       unless ($seen{"$x,$y"}++) {
  #         $point[$num_vertices++] = [$x,$y];
  #       }
  #       ($x,$y) = ($x_hi-$x, $y_hi-$y);
  #     }
  #     Graph::Graph6::write_graph
  #         (format => 'sparse6',
  #          fh = \*STDOUT,
  #          edge_predicate => sub {
  #            my ($from,$to) = @_;
  #            return $path->xyxy_to_n_either(@$point[$from],
  #                                           @$point[$to]);
  #          });
  #   }
  # }
