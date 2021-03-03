#!/usr/bin/perl -w

# Copyright 2016, 2017, 2021 Kevin Ryde
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
plan tests => 7;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }
use MyOEIS;

use MyGraphs;
require Graph::Maker::HexGrid;


#------------------------------------------------------------------------------
# A143366 Wiener index of NxNxN
# n*(164n^4-30n^2+1)/5.

MyOEIS::compare_values
  (anum => 'A143366',
   max_count => 5,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $n = 1; @got < $count; $n++) {
       my $graph = Graph::Maker->new('hex_grid',
                                     dims=>[$n,$n,$n],
                                     undirected=>1);
       push @got, MyGraphs::Graph_Wiener_index($graph);
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
