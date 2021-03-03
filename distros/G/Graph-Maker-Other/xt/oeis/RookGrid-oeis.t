#!/usr/bin/perl -w

# Copyright 2017, 2018, 2020, 2021 Kevin Ryde
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
use MyGraphs;

use Graph::Maker::RookGrid;


#------------------------------------------------------------------------------
# A085537  NxN Wiener index

MyOEIS::compare_values
  (anum => 'A085537',
   max_count => 8,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 0; @got < $count; $n++) {
       my $graph = Graph::Maker->new('rook_grid', dims=>[$n,$n],
                                     undirected => 1);
       push @got, MyGraphs::Graph_Wiener_index($graph);
     }
     return \@got;
   });

# A292058 - Wiener index of complement
MyOEIS::compare_values
  (anum => 'A292058',
   max_count => 8,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 1; @got < $count; $n++) {
       if ($n == 2) {
         # 2x2 complement is disconnected so has no Wiener index
         # A292058 extends the recurrence backwards instead
         push @got, 10;
         next;
       }
       my $graph = Graph::Maker->new('rook_grid', dims=>[$n,$n],
                                     undirected => 1)
         ->complement;
       ($graph->vertices==0 || $graph->is_connected) or die;
       push @got, MyGraphs::Graph_Wiener_index($graph);
     }
     return \@got;
   });

# A088699    NxN number of independent sets
# A287274    NxM number of dominating sets
# A287065    NxN number of dominating sets
# A290632    NxM number of minimal dominating sets
# A289196    NxN number of connected dominating sets
# A286189    NxN number of connected induced subgraphs


#------------------------------------------------------------------------------
exit 0;
