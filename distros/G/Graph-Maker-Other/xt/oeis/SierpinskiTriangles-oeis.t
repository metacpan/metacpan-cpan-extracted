#!/usr/bin/perl -w

# Copyright 2020, 2021, 2022 Kevin Ryde
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
use File::Spec;
use Test;
plan tests => 3;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }
use MyOEIS;
use MyGraphs;

use lib File::Spec->catdir('devel','lib');
require Graph::Maker::SierpinskiTriangles;

# GP-DEFINE  read("OEIS-data.gp");
# GP-DEFINE  read("OEIS-data-wip.gp");

# A193256 Number of spanning trees in the n-Sierpinski sieve graph.
# A234634 Numbers of undirected cycles in the n-Sierpinski sieve graph.
# A288629 Number of (undirected) paths in the n-Sierpinski sieve graph.
# A292708 Number of independent vertex sets and vertex covers in the n-Sierpinski sieve graph.
# A292968 Number of matchings in the n-Sierpinski sieve graph.
# A246959 Numbers of (undirected) Hamiltonian cycles in the n-Sierpinski sieve graph.
#  Number of (not necessarily maximum) cliques in the n-Sierpinski sieve graph.



#------------------------------------------------------------------------------
# A295933  number of cliques, not necessarily maximum
# 8, 20, 55, 160, 475, 1420, 4255, 12760, 38275

MyOEIS::compare_values
  (anum => 'A295933',
   max_count => 5,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 0; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Sierpinski_triangles',
                                     N => $N,
                                     undirected => 1);
       print "N=$N  $graph\n";
       my $triangles = MyGraphs::Graph_triangle_count($graph);
       if ($N == 0) { $triangles == 1 or die $triangles; }
       if ($N >= 1) { $triangles == 4*3**($N-1) or die $triangles; }
       push @got,
         1                           # 0-clique
         + scalar($graph->vertices)  # 1-cliques
         + scalar($graph->edges)     # 2-cliques
         + $triangles;               # 3-cliques
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A290129  Wiener index of order N
# 3, 21, 246, 3765, 64032, 1130463, 20215254, 363069729, 6530385420,

MyOEIS::compare_values
  (anum => 'A290129',
   max_count => 5,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 0; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Sierpinski_triangles',
                                     N => $N,
                                     undirected => 1);
       push @got, MyGraphs::Graph_Wiener_index($graph);
     }
     return \@got;
   });

# distances to corner  2^n + 6^n
# 2,8,40,224,1312
MyOEIS::compare_values
  (anum => 'A074601',
   max_count => 5,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $N = 0; @got < $count; $N++) {
       my $graph = Graph::Maker->new('Sierpinski_triangles',
                                     N => $N,
                                     undirected => 1);
       push @got, MyGraphs::Graph_Wiener_part_at_vertex($graph,'0,0');
     }
     return \@got;
   });

# GP-DEFINE  NumVertices(N) = {
# GP-DEFINE    N>=0 || error();
# GP-DEFINE    (3^N+1)*3/2;
# GP-DEFINE  }
# GP-DEFINE  cornerW(n) = {
# GP-DEFINE    if(n==0,2,
# GP-DEFINE       3*cornerW(n-1)
# GP-DEFINE       + 2*2^(n-1)*(NumVertices(n-1)-1)
# GP-DEFINE       - 2^n);
# GP-DEFINE  }
# GP-Test  vector(5,n,n--; cornerW(n)) == [2,8,40,224,1312]
# GP-Test  OEIS_check_func("A074601",cornerW)
#
# top vertices NumVertices(n-1)-1
# left to top cornerW(n-1) for each those
#
# right vertices NumVertices(n-1)-2
# left to right cornerW(n-1) for each those
#
# but some shorter by half way
#
# GP-DEFINE  W(n) = {
# GP-DEFINE    if(n==0,3,
# GP-DEFINE       n==1,21,
# GP-DEFINE       3*W(n-1)
# GP-DEFINE       + 3*cornerW(n-1)*(2*NumVertices(n-1) - 2)
# GP-DEFINE       );
# GP-DEFINE  }
# xGP-Test  vector(5,n,n--; W(n)) - \
# xGP-Test  [3, 21, 246, 3765, 64032]


#------------------------------------------------------------------------------
# A193256 - Num Spanning Trees
#
# a(n) = (3/20)^(1/4) * (5/3)^(-(n-1)/2) * (540^(1/4))^(3^(n-1))
# vector(6,n, a(n))
# GP-DEFINE  NumSpanningTrees(n) = {
# GP-DEFINE      2^((3^(n-1)       - 1)/2)
# GP-DEFINE    * 3^((3^n     + 2*n - 1)/4)
# GP-DEFINE    * 5^((3^(n-1) - 2*n + 1)/4);
# GP-DEFINE  }
# OEIS_data("A193256")
# GP-Test  OEIS_check_func("A193256",NumSpanningTrees)
# recurrence_guess(vector(12,n, NumSpanningTrees(n)))


#------------------------------------------------------------------------------
exit 0;
