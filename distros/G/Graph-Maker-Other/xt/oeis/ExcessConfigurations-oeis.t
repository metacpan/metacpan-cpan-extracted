#!/usr/bin/perl -w

# Copyright 2019, 2021 Kevin Ryde
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
use List::Util 'sum';

use lib 't','xt';
use MyOEIS;
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Graph::Maker::ExcessConfigurations;

use File::Spec;
use lib File::Spec->catdir('devel','lib');
use MyGraphs;

plan tests => 2;


#------------------------------------------------------------------------------

# not in OEIS: 1,1,2,5,15,52,203,867,4026,20050
#
# MyOEIS::compare_values
#   (anum => 'A000000',
#    max_count => 10,
#    func => sub {
#      my ($count) = @_;
#      my @got;
#      for (my $N = 0; @got < $count; $N++) {
#        my $graph = Graph::Maker->new('excess_configurations', N => $N);
#        push @got, MyGraphs::Graph_num_maximal_paths($graph);
#      }
#      return \@got;
#    });

#------------------------------------------------------------------------------
# A000070 num vertices

MyOEIS::compare_values
  (anum => 'A000070',
   max_count => 15,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 0; @got < $count; $N++) {
       my $graph = Graph::Maker->new('excess_configurations', N => $N);
       push @got, scalar($graph->vertices);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A029859 num edges

MyOEIS::compare_values
  (anum => 'A029859',
   max_count => 15,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 2; @got < $count; $N++) {
       my $graph = Graph::Maker->new('excess_configurations', N => $N);
       push @got, scalar($graph->edges);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A000041 num successorless

MyOEIS::compare_values
  (anum => 'A000041',
   max_count => 15,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 0; @got < $count; $N++) {
       my $graph = Graph::Maker->new('excess_configurations', N => $N);
       push @got, scalar($graph->successorless_vertices);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
exit 0;
