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

# uncomment this to run the ### lines
# use Smart::Comments;

plan tests => 51;

require Graph::Maker::Johnson;

sub stringize_sorted {
  my ($graph) = @_;
  ### stringize_sorted: "$graph"
  my @edges = $graph->edges;
  if (! @edges) {
    return join(',',$graph->vertices);
  }
  @edges = map { $_->[0] gt $_->[1] ? [ $_->[1], $_->[0] ] : $_ } @edges;
  @edges = sort {$a->[0] cmp $b->[0] || $a->[1] cmp $b->[1]} @edges;
  ### @edges
  return join(' ', map {$_->[0].'='.$_->[1]} @edges);
}


#------------------------------------------------------------------------------
{
  my $want_version = 18;
  ok ($Graph::Maker::Johnson::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::Johnson->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::Johnson->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::Johnson->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------

{
  # FIXME: What is a 0-element subset of the empty set.
  # Is it one subset, being the empty set?
  #
  my $graph = Graph::Maker->new('Johnson', N=>0, K=>0);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ($num_vertices, 1);
  ok ($num_edges, 0);
}
{
  my $graph = Graph::Maker->new('Johnson', N=>1, K=>1);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ($num_vertices, 1);
  ok ($num_edges, 0);
}

{
  my $graph = Graph::Maker->new('Johnson', N=>4, K=>2, undirected=>1);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  ok ($num_vertices, 6);
  ok ($num_edges, 12);
  ok (stringize_sorted($graph),
      '1,2=1,3 1,2=1,4 1,2=2,3 1,2=2,4'
      . ' 1,3=1,4 1,3=2,3 1,3=3,4'
      . ' 1,4=2,4 1,4=3,4'
      . ' 2,3=2,4 2,3=3,4'
      . ' 2,4=3,4' );
}
# GP-Test  binomial(4,2) == 6


#------------------------------------------------------------------------------
# Johnson N,1 is complete-N, same vertex numbers too

require Graph::Maker::Complete;
foreach my $N (2 .. 6) {
  foreach my $undirected (0, 1) {
    foreach my $multiedged (0, 1) {
      my $johnson  = Graph::Maker->new('Johnson', N=>$N, K=>1,
                                       undirected => $undirected,
                                       multiedged => $multiedged);
      my $complete = Graph::Maker->new('complete', N=>$N,
                                       undirected => $undirected,
                                       multiedged => $multiedged);
      ok ($johnson eq $complete, 1);

      my $num_edges = $johnson->edges;
      ok ($num_edges, T($N) * ($undirected ? 1 : 2));
    }
  }
}

# triangular numbers
sub T {
  my ($n) = @_;
  return $n*($n-1)/2;
}

#------------------------------------------------------------------------------
exit 0;
