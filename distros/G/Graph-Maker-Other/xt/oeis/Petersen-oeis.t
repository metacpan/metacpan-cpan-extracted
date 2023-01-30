#!/usr/bin/perl -w

# Copyright 2017, 2018, 2021 Kevin Ryde
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

use 5.004;
use strict;
use Test;
plan tests => 2;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }
use MyOEIS;

use Graph::Maker::Petersen;

# cf indsets in nautyextra misc.c

#------------------------------------------------------------------------------
# A077105   number of non-isomorphic K for given N



#------------------------------------------------------------------------------
# A077105   number of non-isomorphic K for given N
# K <= floor((N-1)/2), so excludes N=K/2 when K even which is paths across
# opposite outer vertices

MyOEIS::compare_values
  (anum => 'A077105',
   max_count => 20,
   func => sub {
     my ($count) = @_;
     require MyGraphs;
     my @got;
     for (my $N = 3; @got < $count; $N++) {
       my %seen;
       foreach my $K (1 .. (($N-1)>>1)) {
         my $graph = Graph::Maker->new('Petersen', N => $N, K => $K);
         my $str = MyGraphs::Graph_to_graph6_str($graph);
         $str = MyGraphs::graph6_str_to_canonical($str);
         $seen{$str} = 1;
       }
       push @got, scalar keys %seen;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A274047 diameter of n,2, starting from n=5 Petersen graph

MyOEIS::compare_values
  (anum => 'A274047',
   max_count => 30,    # Graph.pm diameter is a bit slow
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 5; @got < $count; $n++) {
       my $graph = Graph::Maker->new('Petersen', N => $n, K => 2);
       push @got, scalar $graph->diameter;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
