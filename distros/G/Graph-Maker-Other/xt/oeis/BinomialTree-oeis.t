#!/usr/bin/perl -w

# Copyright 2016, 2017, 2018, 2019 Kevin Ryde
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
MyTestHelpers::nowarnings();
use MyOEIS;
use MyGraphs;

require Graph::Maker::BinomialTree;


#------------------------------------------------------------------------------
# A210995  balanced binary
# A092124  in decimal

MyOEIS::compare_values
  (anum => 'A210995',
   func => sub {
     my ($count) = @_;
     my @got = (1);
     for (my $k = 0; @got < $count; $k++) {
       my $graph = Graph::Maker->new('binomial_tree', order => $k);
       push @got, balanced_binary_str($graph);
     }
     return \@got;
   });

MyOEIS::compare_values
  (anum => 'A092124',
   func => sub {
     my ($count) = @_;
     require Math::BigInt;
     my @got;
     for (my $k = 0; @got < $count; $k++) {
       my $graph = Graph::Maker->new('binomial_tree', order => $k);
       push @got, Math::BigInt->new('0b'.balanced_binary_str($graph));
     }
     return \@got;
   });

sub balanced_binary_str {
  my ($graph, $v) = @_;
  $v ||= 0;
  my $ret = '1';
  foreach my $c (sort {$a<=>$b} grep {$_>$v} $graph->neighbours($v)) {
    $ret .= balanced_binary_str($graph, $c);
  }
  return $ret . '0';
}


#------------------------------------------------------------------------------
# A192021  Wiener index of order k

MyOEIS::compare_values
  (anum => 'A192021',
   max_count => 7,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 1; @got < $count; $k++) {
       my $graph = Graph::Maker->new('binomial_tree', order => $k);
       push @got, MyGraphs::Graph_Wiener_index($graph);
     }
     return \@got;
   });


#------------------------------------------------------------------------------
exit 0;
