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

use 5.004;
use strict;
use Test;
plan tests => 35;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

require Graph::Maker::TwinAlternateAreaTree;

# uncomment this to run the ### lines
# use Smart::Comments '###';


#------------------------------------------------------------------------------
# A053754 even binary length, vertical spine and attached vertices
# A053738 odd binary length, NW spine and attached vertices

{
  my $k = 10;
  # GP-Test  my(k=10); sum(n=0,2^k-1,length(binary(n))%2==0) == 683
  # GP-Test  my(k=10); sum(n=0,2^k-1,length(binary(n))%2==1) == 341

  my $graph = Graph::Maker->new('twin_alternate_area_tree',
                                level => $k,
                                undirected => 1);
  $graph->delete_edge(0,1);
  my @cc = $graph->connected_components;

  MyOEIS::compare_values
      (anum => 'A053754',
       max_count => 683,
       func => sub {
         my ($count) = @_;
         my $index = $graph->connected_component_by_vertex(0);
         my @got = sort {$a<=>$b} $graph->connected_component_by_index($index);
         $#got = $count-1;
         return \@got;
       });

  MyOEIS::compare_values
      (anum => 'A053738',
       max_count => 341,
       func => sub {
         my ($count) = @_;
         my $index = $graph->connected_component_by_vertex(1);
         my @got = sort {$a<=>$b} $graph->connected_component_by_index($index);
         $#got = $count-1;
         return \@got;
       });
}


#------------------------------------------------------------------------------
# A001196 vertical spine TAspineV()

{
  my $k = 10;
  my $graph = Graph::Maker->new('twin_alternate_area_tree',
                                level => $k,
                                undirected => 1);
  my ($aref, $i_start, $filename) = MyOEIS::read_values('A001196');
  foreach my $i (0 .. $#$aref-1) {
    my $from = $aref->[$i];
    my $to   = $aref->[$i+1];
    last unless $graph->has_vertex($to);
    ok (!! $graph->has_edge($from,$to), 1);
  }
}


#------------------------------------------------------------------------------
# A077866 height

MyOEIS::compare_values
  (anum => 'A077866',
   max_count => 8,  # Graph.pm 0.9704 vertex_eccentricity() is a bit slow
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 1; @got < $count; $k++) {
       my $graph = Graph::Maker->new('twin_alternate_area_tree',
                                     level => $k,
                                     undirected => 1);
       push @got, $graph->vertex_eccentricity(0) || 0;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A053599 diameter

MyOEIS::compare_values
  (anum => 'A053599',
   max_count => 7,  # Graph.pm 0.9704 diameter() is a bit slow
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $k = 1; @got < $count; $k++) {
       my $graph = Graph::Maker->new('twin_alternate_area_tree',
                                     level => $k,
                                     undirected => 1);
       push @got, $graph->diameter || 0;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
exit 0;
