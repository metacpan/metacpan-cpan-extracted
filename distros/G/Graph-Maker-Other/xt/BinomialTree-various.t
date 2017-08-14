#!/usr/bin/perl -w

# Copyright 2017 Kevin Ryde
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
use POSIX 'ceil';
use Test;
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }


plan tests => 74;

use Graph::Maker::BinomialTree;

use lib
  'devel/lib';
use MyGraphs;


#------------------------------------------------------------------------------
# independence and domination

foreach my $N (0 .. 32) {
  my $graph = Graph::Maker->new('binomial_tree',
                                N => $N,
                                undirected => 1);
  ok (MyGraphs::Graph_tree_indnum($graph),
      ceil($N/2),
      "indnum N=$N");
  ok (MyGraphs::Graph_tree_domnum($graph),
      $N==1 ? 1 : int($N/2),
      "domnum N=$N");
}


#------------------------------------------------------------------------------
# k+1 is k with a new leaf on every existing vertex

foreach my $k (0 .. 7) {
  my $tree_k = Graph::Maker->new('binomial_tree',
                                 order => $k,
                                 undirected => 1);
  my $tree_k_plus_1 = Graph::Maker->new('binomial_tree',
                                        order => $k+1,
                                        undirected => 1);
  foreach my $v ($tree_k->vertices) {
    $tree_k->add_edge($v, "$v-extra");
  }
  ok (!! MyGraphs::Graph_is_isomorphic($tree_k,$tree_k_plus_1), 1);
}


#------------------------------------------------------------------------------
exit 0;
