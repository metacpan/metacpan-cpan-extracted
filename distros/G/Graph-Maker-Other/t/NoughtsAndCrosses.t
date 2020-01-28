#!/usr/bin/perl -w

# Copyright 2017, 2018, 2019 Kevin Ryde
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

plan tests => 76;

require Graph::Maker::NoughtsAndCrosses;

sub num_children {
  my ($graph, $v) = @_;
  return scalar(grep {$_ > $v} $graph->neighbours($v));
}

#------------------------------------------------------------------------------
{
  my $want_version = 15;
  ok ($Graph::Maker::NoughtsAndCrosses::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::NoughtsAndCrosses->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::NoughtsAndCrosses->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::NoughtsAndCrosses->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# 0 players single vertex

foreach my $N (0 .. 5) {
  foreach my $undirected (0, 1) {
    my $graph = Graph::Maker->new('noughts_and_crosses',
                                  N => $N,
                                  players => 0,
                                  undirected => $undirected);
    my $num_vertices = $graph->vertices;
    ok ($num_vertices, 1);
    my $num_edges = $graph->edges;
    ok ($num_edges, 0);
  }
}

#------------------------------------------------------------------------------
# no duplicate edges

foreach my $multiedged (0, 1) {
  foreach my $undirected (0, 1) {
    my $graph = Graph::Maker->new('noughts_and_crosses',
                                  N => 2,
                                  multiedged => $multiedged,
                                  undirected => $undirected);
    ok ($graph->is_multiedged ? 1 : 0, $multiedged);

    my $num_vertices = $graph->vertices;
    my $num_edges = $graph->edges;
    ok ($num_vertices, 29);
    ok ($num_edges, 40);
  }
}

#------------------------------------------------------------------------------
# 2x2

{
  my $graph = Graph::Maker->new('noughts_and_crosses',
                                N => 2);
  ok (scalar($graph->vertices), 29);
  ok (scalar($graph->edges), 40);
}

{
  #  2x2 1-player equivalent to half a tesseract
  #
  my $graph = Graph::Maker->new('noughts_and_crosses',
                                N => 2,
                                players => 1,
                                undirected => 1);
  ok (scalar($graph->vertices), 11);
  ok (scalar($graph->edges), 16);
}

{
  #       *             2x2 1-player up to reflection
  #     /   \
  # *--*--*--*--*
  #     \   /
  #       *
  my $graph = Graph::Maker->new('noughts_and_crosses',
                                N => 2,
                                players => 1,
                                reflect => 1,
                                undirected => 1);
  ok (scalar($graph->vertices), 7);
  ok (scalar($graph->edges), 8);

  my @centres = $graph->centre_vertices;
  ok (scalar(@centres), 3);
  ok (join(',',sort @centres), '0000,1001,1010');
}

{
  # 2x2 1-player up to rotation, broken wheel plus 1 vertex
  #
  my $graph = Graph::Maker->new('noughts_and_crosses',
                                N => 2,
                                players => 2,
                                rotate => 1,
                                undirected => 1);
  ok (scalar($graph->vertices), 8);
  ok (scalar($graph->edges), 10);

  my $root = '0000';
  ok (!! $graph->has_vertex($root), 1);
  $graph->delete_vertex('0000');

  my @centres = $graph->centre_vertices;
  ok (scalar(@centres), 1);
  ok ($centres[0], '1000');

  my @ones = grep {count_filled($_)==1} $graph->vertices;
  ok (join(',',sort @centres), join(',',sort @ones));
}

{
  my $graph = Graph::Maker->new('noughts_and_crosses',
                                N => 2,
                                players => 1);
  ok (scalar($graph->vertices), 11);
  ok (scalar($graph->edges), 16);
}

#------------------------------------------------------------------------------
# 3x3 1-player

sub count_filled {
  my ($v) = @_;
  scalar(grep {$_} split //, $v);
}
sub neighbour_degrees_string {
  my ($graph,$v) = @_;
  return join(',',
              sort {$a<=>$b}
              map {$graph->vertex_degree($_)} $graph->neighbours($v));
}

{
  my $graph = Graph::Maker->new('noughts_and_crosses',
                                N => 3,
                                players => 1,
                                rotate => 1,
                                reflect => 1);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ($num_vertices, 87);
  ok ($num_edges, 193);
  ok ($graph->diameter, 7);

  my @vertices = $graph->vertices;
  my $num_sixes_not_end = grep {count_filled($_) == 6
                                  && $graph->successors($_) > 0} @vertices;
  ok ($num_sixes_not_end, 1);

  my $num_sevens = grep {count_filled($_) == 7} @vertices;
  ok ($num_sevens, 2);   # 1 opposite corners, 1 centre and corner

  my @roots = $graph->predecessorless_vertices;
  ok (scalar(@roots), 1);
  my $root = $roots[0];
  ok ($graph->in_degree($root), 0);
  ok ($graph->out_degree($root), 3);

  my @depth1_vertices = $graph->successors($root);
  {
    my @depth1_degrees = map {$graph->in_degree($_) + $graph->out_degree($_)}
      @depth1_vertices;
    ok (join(',',sort @depth1_degrees), '3,6,6');
  }

  # my @depth1_degrees = map {$graph->in_degree($_) + $graph->out_degree($_)}
  #   @depth1_vertices;

  my $ugraph = $graph->undirected_copy;
  ok ($ugraph->diameter, 10);
  ok ($ugraph->vertex_eccentricity($root), 7);
  ok ($ugraph->vertex_degree($root), 3);
  {
    my @depth1_degrees = map {$ugraph->degree($_)} @depth1_vertices;
    ok (join(',',sort @depth1_degrees), '3,6,6');
  }

  my @ecc7_vertices = grep {$ugraph->vertex_eccentricity($_)==7} $ugraph->vertices;
  ok(scalar(@ecc7_vertices), 30);

  my @ecc7_deg3_vertices = grep {$ugraph->vertex_degree($_)==3} @ecc7_vertices;
  ok(scalar(@ecc7_deg3_vertices), 5);

  # root is degree-3 ecc 7 and only one with neighbour degrees 3,6,6
  my @ecc7_deg3_366_vertices
    = grep {neighbour_degrees_string($ugraph,$_) eq '3,6,6'}
    @ecc7_deg3_vertices;
  ok(join(',',@ecc7_deg3_366_vertices), $root);
}

{
  my $graph = Graph::Maker->new('noughts_and_crosses',
                                N => 3,
                                players => 1);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ($num_vertices, 450);
  ok ($num_edges, 1297);

  my @vertices = $graph->vertices;
  my $num_sixes_not_end = grep {count_filled($_) == 6
                                  && $graph->successors($_) > 0} @vertices;
  ok ($num_sixes_not_end, 2);

  my $num_sevens = grep {count_filled($_) == 7} @vertices;
  ok ($num_sevens, 6);   # 2 opposite corners, 4 centre and corner
}

#------------------------------------------------------------------------------
exit 0;
