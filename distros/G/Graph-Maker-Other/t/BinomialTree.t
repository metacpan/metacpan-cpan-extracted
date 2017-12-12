#!/usr/bin/perl -w

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

use strict;
use 5.004;
use Test;
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

plan tests => 104;

require Graph::Maker::BinomialTree;


#------------------------------------------------------------------------------
{
  my $want_version = 10;
  ok ($Graph::Maker::BinomialTree::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::BinomialTree->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::BinomialTree->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::BinomialTree->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# diameter 0 for order=0, otherwise 2*order-1 for order>=1

foreach my $order (0 .. 5) {
  my $graph = Graph::Maker->new('binomial_tree',
                                order => $order,
                                undirected => 1);
  my $got = $graph->diameter || 0;
  my $want = ($order==0 ? 0 : 2*$order - 1);
  ok ($got, $want);
}


#------------------------------------------------------------------------------

{
  # 0 only
  my $graph = Graph::Maker->new('binomial_tree', order => 0);
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 1);
}
{
  #   0
  #  /
  # 1
  my $graph = Graph::Maker->new('binomial_tree', order => 1);
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 2);
  ok ($graph->has_edge(0,1)?1:0, 1);
  ok ($graph->has_edge(1,0)?1:0, 1);
}
{
  #   0
  #  /
  # 1
  my $graph = Graph::Maker->new('binomial_tree', order => 1,
                                undirected => 1);
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 2);
  ok ($graph->is_directed?1:0, 0);
  ok ($graph->has_edge(0,1)?1:0, 1);
  ok ($graph->has_edge(1,0)?1:0, 1);
}
{
  #   0
  #  / \
  # 1   2
  #      \
  #       3
  my $graph = Graph::Maker->new('binomial_tree', order => 2);
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 4);
}

{
  #   0
  #  / \
  # 1   2
  my $graph = Graph::Maker->new('binomial_tree', N => 3);
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, 3);
  ok ($graph->has_edge(0,1)?1:0, 1);
  ok ($graph->has_edge(0,2)?1:0, 1);
  ok ($graph->has_edge(1,2)?1:0, 0);
}


#------------------------------------------------------------------------------
# order giving height

foreach my $order (0 .. 5) {
  my $graph = Graph::Maker->new('binomial_tree',
                                order => $order,
                                undirected => 1);
  my $got = Graph_height($graph,0);
  my $want = $order + 1;     # order=0 single vertex height=1
  ok ($got, $want);
}

sub Graph_height {
  my ($graph, $root) = @_;
  if (scalar($graph->vertices) == 1) { return 1; }
  return ($graph->vertex_eccentricity($root) || 0) + 1;
}


#------------------------------------------------------------------------------
# N num vertices

foreach my $N (0 .. 20) {
  my $graph = Graph::Maker->new('binomial_tree',
                                N => $N,
                                undirected => 1);
  my $num_vertices = $graph->vertices;
  ok ($num_vertices, $N);
}


#------------------------------------------------------------------------------
# widths are binomials

sub binomial {
  my ($n, $m) = @_;
  my $ret = 1;
  foreach my $i ($n-$m+1 .. $n) {
    $ret *= $i;
  }
  foreach my $i (1 .. $m) {
    $ret /= $i;
  }
  return $ret;
}
ok (binomial(3,0), 1);
ok (binomial(3,1), 3);
ok (binomial(3,2), 3);
ok (binomial(3,3), 1);

ok (binomial(4,0), 1);
ok (binomial(4,1), 4);
ok (binomial(4,2), 6);
ok (binomial(4,3), 4);
ok (binomial(4,4), 1);


sub Graph_width_list {
  my ($graph, $root) = @_;
  my @widths;
  my %seen;
  my @pending = ($root);
  while (@pending) {
    push @widths, scalar(@pending);

    my @new_pending;
    foreach my $v (@pending) {
      $seen{$v} = 1;
      my @children = $graph->neighbours($v);
      @children = grep {! $seen{$_}} @children;
      push @new_pending, @children;
    }
    @pending = @new_pending;
  }
  return @widths;
}

foreach my $order (0 .. 8) {
  my $graph = Graph::Maker->new('binomial_tree', order => $order);
  my @widths = Graph_width_list($graph, 0);
  foreach my $depth (0 .. $order) {
    my $got = $widths[$depth];
    my $want = binomial($order, $depth);
    ok ($got, $want);
  }
}

#------------------------------------------------------------------------------
exit 0;
