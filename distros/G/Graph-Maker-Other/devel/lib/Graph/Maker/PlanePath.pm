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


package Graph::Maker::PlanePath;
use 5.004;
use strict;
use Carp 'croak';
use Graph::Maker;

use vars '$VERSION','@ISA';
$VERSION = 6;
@ISA = ('Graph::Maker');

# uncomment this to run the ### lines
# use Smart::Comments;

sub _default_graph_maker {
  require Graph;
  Graph->new(@_);
}

my @dir6_to_dx = (2, 1,-1,-2, -1, 1);
my @dir6_to_dy = (0, 1, 1, 0, -1,-1);

my %neighbours = (4 => [ [1,0], [0,1], [-1,0], [0,-1] ],
                  6 => [ [2,0], [1,1], [-1,1], [-2,0], [-1,-1], [1,-1] ],
                 );

sub init {
  my ($self, %params) = @_;

  my $planepath = delete($params{'planepath'});
  my $path = delete($params{'planepath_object'})
    || do {
      require Math::NumSeq::PlanePathCoord;
      Math::NumSeq::PlanePathCoord::_planepath_name_to_object($planepath)
      };

  my @name;
  my ($n_lo, $n_hi);
  if (defined (my $level = delete($params{'level'}))) {
    ($n_lo, $n_hi) = $path->level_to_n_range($level);
    @name = ("level=$level");
    push @name, "N=$n_lo to $n_hi";
  }

  my $depth = delete($params{'depth'});
  if ($path->is_tree && defined $depth) {
    $n_hi = $path->tree_depth_to_n_end($depth);
    @name = ("depth=$depth");
  }

  if (defined (my $lo = delete($params{'n_lo'}))) {
    $n_lo = $lo;
  }
  if (! defined $n_lo) {
    $n_lo = $path->n_start;
  }

  if (defined (my $hi = delete($params{'n_hi'}))) {
    $n_hi = $hi;
    $name[0] = "N=$n_lo to $n_hi";
  }
  if (! defined $n_hi) {
    croak "No level, depth, or n_hi";
  }
  unshift @name, defined $planepath ? $planepath : ref $path;

  my $type = delete($params{'type'});
  $type ||= ($path->is_tree ? 'tree' : 'touch');
  ### $type

  my $vertex_name_type = delete($params{'vertex_name_type'}) // 'N';
  ### $type
  my $n_to_name = sub {
    my ($n, $x,$y) = @_;
    if ($vertex_name_type eq 'N') {
      return $n;
    }
    if (! defined $x) {
      ($x,$y) = $path->n_to_xy($n);
      ($x,$y) = (-$y,$x);
    }
    return "$x,$y";
  };

  my $graph_maker = delete($params{graph_maker}) || \&_default_graph_maker;

  my $graph = $graph_maker->(%params);

  if ($vertex_name_type eq 'xy') {
    $graph->set_graph_attribute(vertex_name_type => 'xy');
  }

  if ($type eq 'tree') {
    foreach my $n ($n_lo .. $n_hi) {
      next if defined $depth && $path->tree_n_to_depth($n) > $depth;
      my $n_parent = $path->tree_n_parent($n);
      my $v = $n_to_name->($n);
      if (defined $n_parent) {
        my $v_parent = $n_to_name->($n_parent);
        $graph->add_edge($v, $v_parent);
      } else {
        $graph->add_vertex($v);
      }
    }

  } elsif ($type eq 'touch') {
    my ($prev_x,$prev_y) = $path->n_to_xy($n_lo);
    foreach my $n ($n_lo+1 .. $n_hi) {
      my ($x,$y) = $path->n_to_xy($n);
      $graph->add_edge("$prev_x,$prev_y", "$x,$y");
      ### edge: "$prev_x,$prev_y to $x,$y"
      ($prev_x,$prev_y) = ($x,$y);
    }

  } elsif ($type =~ /^neighbours(.*)$/) {
    my $neighbours_aref = $neighbours{$1}
      || croak "Unknown neighbours type $1";
    push @name, "$type";

    foreach my $n ($n_lo .. $n_hi) {
      my ($x,$y) = $path->n_to_xy($n);
      my $from = "$x,$y";
      $graph->add_vertex($from);
      foreach my $dxdy (@$neighbours_aref) {
        my ($dx,$dy) = @$dxdy;
        my $x2 = $x + $dx;
        my $y2 = $y + $dy;
        # ### consider: "$x,$y to $x2,$y2"
        my $n2 = $path->xy_to_n ($x2,$y2);
        if (defined $n2 && $n2 >= $n_lo && $n2 <= $n_hi) {
          $graph->add_edge($from, "$x2,$y2");
        }
      }
    }
  }

  ### @name
  $graph->set_graph_attribute(name => join(', ', @name));
  return $graph;
}

Graph::Maker->add_factory_type('planepath' => __PACKAGE__);
1;
