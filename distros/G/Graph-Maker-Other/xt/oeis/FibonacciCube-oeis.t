#!/usr/bin/perl -w

# Copyright 2021 Kevin Ryde
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

use lib 't','xt';
use MyOEIS;
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use File::Spec;
use lib File::Spec->catdir('devel','lib');
use MyGraphs 'Graph_Wiener_index';

use Graph::Maker::FibonacciCube;

plan tests => 2;

#------------------------------------------------------------------------------
# A238419  Fibonacci cube Wiener index

MyOEIS::compare_values
  (anum => 'A238419',
   max_count => 10,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 0; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Fibonacci_cube',
                                     N => $N,
                                     undirected=>1);
       push @got, MyGraphs::Graph_Wiener_index($graph);
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A238420',
   max_count => 10,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 1; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Fibonacci_cube',
                                     N => $N,
                                     Lucas => 1,
                                     undirected=>1);
       push @got, MyGraphs::Graph_Wiener_index($graph);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
