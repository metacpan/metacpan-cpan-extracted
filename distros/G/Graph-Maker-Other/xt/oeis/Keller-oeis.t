#!/usr/bin/perl -w

# Copyright 2020, 2021 Kevin Ryde
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
plan tests => 3;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }
use MyOEIS;
use MyGraphs;

use Graph::Maker::Keller;

# GP-DEFINE  read("my-oeis.gp");


#------------------------------------------------------------------------------
# A284838 - num edges

MyOEIS::compare_values
  (anum => 'A284838',
   max_count => 4,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 1; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Keller', N => $N,
                                     undirected => 1);
       push @got, scalar($graph->edges);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A292056 - Wiener index

MyOEIS::compare_values
  (anum => 'A292056',
   max_count => 3,
   func => sub {
     my ($count) = @_;
     my @got = (12);  # initial 12 is not a Wiener index
     for (my $N = 2; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Keller', N => $N,
                                     undirected => 1);
       push @got, MyGraphs::Graph_Wiener_index($graph);
     }
     return \@got;
   });

# GP-DEFINE  NumVertices(n) = 4^n;
# GP-Test  NumVertices(2) == 16
# GP-DEFINE  A292056 = OEIS_bfile_func("A292056");
# GP-DEFINE  W(n) = A292056(n);
# GP-Test  W(2) == 200
# vector(10,n,n++; 2*W(n) / NumVertices(n))

#------------------------------------------------------------------------------
# A301571 - num vertices at distance 2 (from any)

MyOEIS::compare_values
  (anum => 'A301571',
   max_count => 4,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 1; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Keller',
                                     N => $N,
                                     undirected => 1);
       my @vertices = $graph->vertices;
       my $from = $vertices[0];  # form anywhere
       my $sptg = $graph->SPT_Dijkstra;
       my $num = 0;
       foreach my $v ($sptg->vertices) {
         my $dist = $sptg->get_vertex_attribute($_,'weight') || 0;
         if (($sptg->get_vertex_attribute($v,'weight') || 0) == 2) {
           $num++;
         }
       }
       push @got, $num;                      
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
