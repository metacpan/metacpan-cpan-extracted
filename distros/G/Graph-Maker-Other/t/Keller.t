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
use Test;
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

plan tests => 150;

require Graph::Maker::Keller;


#------------------------------------------------------------------------------
{
  my $want_version = 19;
  ok ($Graph::Maker::Keller::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::Keller->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::Keller->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::Keller->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------

{
  # N=0
  my $graph = Graph::Maker->new('Keller');
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ($num_vertices, 1);
  ok ($num_edges, 0);
}
{
  # N=1
  my $graph = Graph::Maker->new('Keller', N=>1);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ($num_vertices, 4);
  ok ($num_edges, 0);
}
{
  # N=2, directed
  my $graph = Graph::Maker->new('Keller', N=>2);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ($num_vertices, 16);
  ok ($num_edges, 80);
}
{
  # N=2, undirected
  my $graph = Graph::Maker->new('Keller', N=>2, undirected => 1);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ($num_vertices, 16);
  ok ($num_edges, 40);
}
{
  # N=3, directed
  my $graph = Graph::Maker->new('Keller', N=>3);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ($num_vertices, 64);
  ok ($num_edges, 2*1088);
}
foreach my $undirected (0, 1) {
  # N=3, undirected
  my $graph = Graph::Maker->new('Keller', N=>3,
                                undirected => $undirected);
  my @vertices = $graph->vertices;
  ok (scalar(@vertices), 64);
  my $num_edges = $graph->edges;
  ok ($num_edges, 1088 * ($undirected ? 1 : 2));

  foreach my $rep (1 .. 20) {
    my ($u,$v) = aref_two_random_elems(\@vertices);
    ok ($u ne $v, 1);
    my ($num_diffs, $have_2mod4) = diff_digits($u,$v);
    my $got_distance = $graph->path_length($u,$v);
    my $want_distance = ($num_diffs == 0 ? 0
                : $num_diffs >= 2 && $have_2mod4 ? 1
                : 2);
    ok ($got_distance, $want_distance, "u=$u v=$v");

    my $got_notadjacent = $got_distance >= 2 ? 1 : 0;
    my $want_notadjacent
      = ! $have_2mod4 || ($have_2mod4 && $num_diffs == 1) ? 1 : 0;
    ok ($got_notadjacent, $want_notadjacent, "u=$u v=$v");
  }
}
sub diff_digits {
  my ($u, $v) = @_;
  my $num_diffs = 0;
  my $have_2mod4 = 0;
  while ($u || $v) {
    if (($u & 3) != ($v & 3)) { $num_diffs++; }
    if ((($u - $v) & 3) == 2) { $have_2mod4 = 1; }
    $u >>= 2;
    $v >>= 2;
  }
  return ($num_diffs, $have_2mod4);
}
sub aref_two_random_elems {
  my ($aref) = @_;
  my $len = scalar(@$aref);
  $len >= 2 or die "aref_two_random_elems() is for aref >=2 elems";
  my $a = int(rand($len));
  my $b = int(rand($len-1));
  if ($b >= $a) { $b++; }
  return $aref->[$a], $aref->[$b];
}

#------------------------------------------------------------------------------
# Keller subgraph

{
  # N=0
  my $graph = Graph::Maker->new('Keller', subgraph=>1);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ($num_vertices, 0);
  ok ($num_edges, 0);
}
{
  # N=1, is a star
  my $graph = Graph::Maker->new('Keller', subgraph=>1, N=>1);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ($num_vertices, 0);
  ok ($num_edges, 0);
}
{
  # N=2, undirected
  #
  # 00   21  12
  #      22    
  #      23  32
  # no edges between neighbours
  #
  my $graph = Graph::Maker->new('Keller', N=>2, subgraph=>1, undirected => 1);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ($num_vertices, 5);
  ok ($num_edges, 0);
}
{
  # N=2, directed
  my $graph = Graph::Maker->new('Keller', N=>2, subgraph=>1);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ($num_vertices, 5);
  ok ($num_edges, 0);
}

{
  # N=3, undirected
  my $graph = Graph::Maker->new('Keller', N=>3, subgraph=>1, undirected => 1);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ($num_vertices, 34);
  ok ($num_edges, 261);
}
{
  # N=3, directed
  my $graph = Graph::Maker->new('Keller', N=>3, subgraph=>1);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ($num_vertices, 34);
  # ok ($num_edges, 2*261);
}

{
  # N=4, undirected
  my $graph = Graph::Maker->new('Keller', N=>4, subgraph=>1, undirected => 1);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ($num_vertices, 171);
  # ok ($num_edges, 295);
}

#------------------------------------------------------------------------------
exit 0;
