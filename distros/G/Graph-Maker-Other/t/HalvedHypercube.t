#!/usr/bin/perl -w

# Copyright 2019, 2020, 2021, 2022 Kevin Ryde
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
use List::Util 'sum';
use Test;
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

plan tests => 181;

require Graph::Maker::HalvedHypercube;


#------------------------------------------------------------------------------
{
  my $want_version = 19;
  ok ($Graph::Maker::HalvedHypercube::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::HalvedHypercube->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::HalvedHypercube->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::HalvedHypercube->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# Invariants

# GP-DEFINE  num_vertices(n) = {
# GP-DEFINE    n>=0 || error();
# GP-DEFINE    if(n==0,1, 2^(n-1));
# GP-DEFINE  }

# binomial(N-1,1) distance 1, pick 1 diff bitpos
# binomial(N-1,2) distance 2  pick 2 diff bitpos
# GP-DEFINE  vertex_degree(n) = {
# GP-DEFINE    n>=0 || error();
# GP-DEFINE    binomial(n-1,1) + binomial(n-1,2);
# GP-DEFINE  }
# GP-Test  vector(10,n,n--; vertex_degree(n)) == \
# GP-Test  vector(10,n,n--; n*(n-1)/2)
# GP-Test  vector(6,n,n--; vertex_degree(n)) == \
# GP-Test    [0, 0, 1, 3, 6, 10]
#           N=0  1  2  3  4   5
# N=3 N-1=2 square, diagonal edges, degree 3
# GP-DEFINE  A161680(n) = binomial(n,2);
# GP-Test  OEIS_check_func("A161680",,['offset,0])
# GP-Test  vector(100,n,n--; vertex_degree(n)) == \
# GP-Test  vector(100,n,n--; A161680(n))
#
sub want_degree {
  my ($N) = @_;
  return ($N==0 ? 0 : $N*($N-1)/2);
}

# GP-DEFINE  num_edges(n) = {
# GP-DEFINE    n>=0 || error();
# GP-DEFINE    vertex_degree(n)*num_vertices(n) / 2;
# GP-DEFINE  }
# GP-Test  vector(10,n,n--; num_edges(n)) == \
# GP-Test  vector(10,n,n--; 2^(n-3)*n*(n-1))
# GP-Test  vector(8,n,n--; num_edges(n))
# GP-DEFINE  A001788(n) = n*(n+1)*2^(n-2);
# GP-Test  OEIS_check_func("A001788",,['offset,0])
# GP-Test  vector(100,n,n--; num_edges(n)) == \
# GP-Test  vector(100,n,n--; A001788(n-1))
#
sub want_num_edges {
  my ($N) = @_;
  return ($N==0 ? 0
          : 2**($N-2) * $N*($N-1)/2 );
}


#------------------------------------------------------------------------------
# No Duplicate Edges

foreach my $multiedged (0, 1) {
  foreach my $N (0 .. 6) {
    my $graph = Graph::Maker->new('halved_hypercube',
                                  undirected => 1,
                                  N => $N,
                                  multiedged => $multiedged);
    ok ($graph->is_multiedged ? 1 : 0, $multiedged);

    my $num_vertices = $graph->vertices;
    ok ($num_vertices,  $N==0 ? 1 : 2**($N-1),
        "num vertices N=$N multiedged=$multiedged");

    my $num_edges = $graph->edges;
    ok ($num_edges, want_num_edges($N),
        "num edges N=$N multiedged=$multiedged");

    # degree regular
    foreach my $v ($graph->vertices) {
      ok ($graph->degree($v), want_degree($N),
          "degree v=$v in N=$N multiedged=$multiedged");
    }
  }
}

#------------------------------------------------------------------------------
# Properties


{
  foreach my $N (0 .. 6) {
    my $graph = Graph::Maker->new('halved_hypercube',
                                  undirected => 1,
                                  N => $N);
    # FIXME: is this right
    ok ($graph->diameter || 0,  int($N/2),
        "diameter N=$N");
  }
}

#------------------------------------------------------------------------------
exit 0;
