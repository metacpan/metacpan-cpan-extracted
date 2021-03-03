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
use Graph;
use Math::BaseCnv 'cnv';
use Math::BigRat;
use Test;
use List::Util 'min','max','sum';
plan tests => 20;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }
use MyOEIS;

use MyGraphs;
require Graph::Maker::Hanoi;

# uncomment this to run the ### lines
# use Smart::Comments;

# GP-DEFINE  read("my-oeis.gp");

sub discs_to_num_vertices {
  my ($discs) = @_;
  return 3**$discs;
}

# Return the number of discs needed for the graph to have >= $num_vertices
sub num_vertices_to_discs {
  my ($num_vertices) = @_;
  my $discs = 0;
  while ($num_vertices > discs_to_num_vertices($discs)) { $discs++; }
  return $discs;
}

# GP-DEFINE  to_ternary(n)=fromdigits(digits(n,3))*sign(n);
# GP-DEFINE  from_ternary(n)=fromdigits(digits(n),3);


#------------------------------------------------------------------------------
# A060586 - path length vertex n to 00..00
# vertex coded in ternary digits

MyOEIS::compare_values
  (anum => 'A060586',
   func => sub {
     my ($count) = @_;
     my $discs = num_vertices_to_discs ($count);
     my $graph = Graph::Maker->new('hanoi',
                                   discs => $discs,
                                   undirected => 1);
     my @got;
     my $from = 0;
     $graph->has_vertex($from) or die;
     for (my $to = 0; @got < $count; $to++) {
       $graph->has_vertex($to) or die;
       my @path = $graph->SP_Dijkstra($from,$to);
       push @got, scalar(@path)-1;
     }
     return \@got;
   });

# cf also A007798 to reach solution by random moves
# arxiv 1304.3780
#
# A060589 - total path lengths all to 00..00
MyOEIS::compare_values
  (anum => 'A060589',
   max_count => 5,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $discs = 0; @got < $count; $discs++) {
       my $graph = Graph::Maker->new('hanoi',
                                     discs => $discs,
                                     undirected => 1);
       my $from = min($graph->vertices);
       my $sptg = $graph->SPT_Dijkstra($from);
       push @got, sum(0,
                      map {$sptg->get_vertex_attribute($_,'weight') || 0}
                      $sptg->vertices)
     }
     return \@got;
   });

# A060590 - numerator of mean path length vertex to 00..00
MyOEIS::compare_values
  (anum => 'A060590',
   max_count => 5,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $discs = 0; @got < $count; $discs++) {
       my $graph = Graph::Maker->new('hanoi',
                                     discs => $discs,
                                     undirected => 1);
       my $from = min($graph->vertices);
       my $sptg = $graph->SPT_Dijkstra($from);
       my $num_paths = $sptg->vertices;
       my $total = sum(0,
                       map {$sptg->get_vertex_attribute($_,'weight') || 0}
                       $sptg->vertices);
       my $mean = Math::BigRat->new($total, $num_paths || 1);
       push @got, $mean->numerator;
       ok ($mean->denominator, $discs%2 ? 3 : 1);
     }
     return \@got;
   });

# path n to 00000 next vertex
# not in OEIS: 5,5,2,7,1,7,10,16,10,15,12,12,17,17,8
#        0,0,0,5,5,2,7,1,7,10
#        0 1 2 3 4 5 6 7 8  9
# not in OEIS: 12,12, 2,21, 1,21,101,121,101,120,110,110,122,122
#              10 11 12 20 21 22 100 101 102
# MyOEIS::compare_values
#   (anum => 'A060586',
#    func => sub {
#      my ($count) = @_;
#      my $discs = num_vertices_to_discs ($count);
#      my $graph = Graph::Maker->new('hanoi',
#                                    discs => $discs,
#                                    undirected => 1);
#      my @got;
#      my $from = 0;
#      $graph->has_vertex($from) or die;
#      for (my $to = 0; @got < $count; $to++) {
#        $graph->has_vertex($to) or die;
#        my @path = $graph->SP_Dijkstra($from,$to);
#        if (@path < 2) { push @got, $path[0]; next }
#        my $second_last_v = $path[-2];
#        # $second_last_v = cnv($second_last_v, 10,3);
#        push @got, $second_last_v;
#      }
#      return \@got;
#    });


#------------------------------------------------------------------------------
# A055662 - path vertices 000 to 11111 etc solution, in ternary

foreach my $elem (['A055661', radix => 10],  # configurations in decimal
                  ['A055662', radix => 3],   # configurations in ternary digits
                  ['A060573', spindle => 0],   # smallest on spindle
                  ['A060574', spindle => 1],   #
                  ['A060575', spindle => 2],   #
                 ) {
  my ($anum, %options) = @$elem;
  MyOEIS::compare_values
      (anum => $anum,
       max_count => 3**5,
       func => sub {
         my ($count) = @_;
         my @got;
         my $discs = 1;
         while (2**$discs < $count) { $discs *=2; }
         
         my $graph = Graph::Maker->new('hanoi',
                                       discs => $discs,
                                       undirected => 1);
         my $from = min($graph->vertices);  # centre
         my $to   = max($graph->vertices);  # outer spindle
         if ($discs % 2) { $to /= 2; }  # to 111 or 2222
         $graph->has_vertex($from) or die;
         $graph->has_vertex($to)   or die;
         ### $from
         ### to: "$to = ".cnv($to,10,3)
         my @path = $graph->SP_Dijkstra($from,$to);
         
         if (defined $options{'spindle'}) {
           # which is the smallest disc on spindle, smallest disc number 1
           foreach my $i (0 .. $#path) {
             my $v = $path[$i];
             $path[$i] = 0;  # or 0 if spindle is empty
             for (my $disc = 1; ; $disc++) {
               if ($v%3 == $options{'spindle'}) {
                 $path[$i] = $disc;
                 last;
               }
               $v = int($v)/3 || last;
             }
           }
         } else {
           # whole configuration
           @path = map {cnv($_, 10, $options{'radix'})} @path;
         }
         $#path = $count-1;
         return \@path;
       });
}

# GP-DEFINE  \\ formula in A055662
# GP-DEFINE  A055662(n) = {
# GP-DEFINE    sum(j=0,if(n,logint(n,2)),
# GP-DEFINE        10^j * (floor((n/2^j + 1)/2)*(-1)^j % 3));
# GP-DEFINE  }
# GP-Test  my(v=OEIS_samples("A055662")); /* OFFSET=0 */ \
# GP-Test    vector(#v,n,n--; A055662(n)) == v
#
# x x x . x x
#    +1
#    |floor
# vector(20,n,hammingweight(n)%2)
# GP-Test  vector(20,k, (2^k)%3) == \
# GP-Test  vector(20,k, k%2 + 1)

# 6 periodic, 12 periodic, etc 6*2^k, opposite ways
# low digit: 0, 1, 1, 2, 2, 0
# 2nd digit: 0, 0, 2, 2, 2, 2, 1, 1, 1, 1, 0, 0
# vector(20,n,n--; A055662(n)%10)
# vector(20,n,n--; A055662(n)\10%10)
# vector(20,n,n--; A055662(n)\100%10)

# matrix(80,8,n,j,j--; (floor((n/2^j + 1)/2)*(-1)^j % 3)) == \
# matrix(80,8,n,j,j--; n>>=j; ( -(-1)^j * ( n + bittest(n,0) ) % 3))
# row(n) = Vecrev(vector(12,j,j--; my(n=n>>j); ( -(-1)^j * ( n + bittest(n,0) ) % 3)))
# R(n) = my(v=binary(n),t=0); while(#v<12,v=concat(0,v)); \
#   for(i=1,#v, [t,v[i]] = [ t=v[i]+2*t, (2*v[i]+2*t)*(-1)^(#v-i) % 3 ] ); v;
# R(n) = my(v=binary(n),t=Mod(0,3)); \
#   while(#v<12,v=concat(0,v)); \
#   my(s=-Mod(-1,3)^#v, T=s*t); \
#   for(i=1,#v, t=-t-v[i]; T-=s*v[i]; v[i] = lift(T - s*v[i]); s=-s ); v;
# R(n) = my(v=binary(n),T=Mod(0,3)); \
#   while(#v<12,v=concat(0,v)); \
#   my(s=Mod(-1,3)^#v); \
#   for(i=1,#v, T += s*v[i]; v[i] = lift(T + s*v[i]); s=-s ); v;
# R(n) = my(v=binary(n)); \
#   while(#v<12,v=concat(0,v)); \
#   my(t=Mod(0,3), s=Mod(-1,3)^#v); \
#   for(i=1,#v, t=v[i]-t; v[i]=lift((t+v[i])*s); s=-s); v;
# R(340)
# row(340)
# R(140)
# row(140)
# vector(1000,n,R(n)) == \
# vector(1000,n,row(n))
# binary(350)
# n=350; n>>=7; [n, n+bittest(n,0), (n+bittest(n,0))%3, ( -(-1)^j * ( n + bittest(n,0) ) % 3)]

# GP-Test  vector(10000,n,n--; A055662(n)) == \
# GP-Test  vector(10000,n,n--; my(v=binary(n)); \
# GP-Test    my(t=Mod(0,3), s=(-1)^#v); \
# GP-Test    for(i=1,#v, t=v[i]-t; v[i]=lift((t+v[i])*s); s=-s); \
# GP-Test    fromdigits(v))
#
# GP-Test  vector(10000,n,n--; A055662(n)) == \
# GP-Test  vector(10000,n,n--; \
# GP-Test    my(v=binary(n)); my(t=0, s=(-1)^#v); \
# GP-Test    for(i=1,#v, t=v[i]-t; v[i]=s*(t+v[i])%3; s=-s); \
# GP-Test    fromdigits(v))
#
# vector(10,n,n--; A055662(2*n)) - \
# vector(10,n,n--; (10^(#digits(A055662(n))+1)-1)/3 - 10*A055662(n))

# vector(100,n,n--; valuation(A055662(n+1) - A055662(n),10))
# vector(10,n,n--; A055662(n+1) - A055662(n))
# vector(10,n,n--; my(d=A055662(n+1) - A055662(n)); \
#                  if(d<0, d+=3*10^logint(abs(d),10)); d)

# GP-Test  /* +1 or -1 as bit position and num transitions so far */ \
# GP-Test  vector(2^12,n,n--; A055662(n)) == \
# GP-Test  vector(2^12,n,n--; \
# GP-Test    my(v=binary(bitxor(n,n>>1))); \
# GP-Test    my(t=0, c=#v); \
# GP-Test    for(i=1,#v, if(v[i], t-=(-1)^(i+(c--))); v[i]=t%3); \
# GP-Test    fromdigits(v))
#
# GP-Test  /* arithmetic, alternating digits */ \
# GP-Test  vector(2^12,n,n--; A055662(n)) == \
# GP-Test  vector(2^12,n,n--; \
# GP-Test    my(v=binary(bitxor(n,n>>1)), t=Mod(0,3), c=(-1)^#v); \
# GP-Test    for(i=1,#v, if(v[i],t-=c,c=-c); v[i]=lift(t)); \
# GP-Test    fromdigits(v))

# vector(30,n,n--; A055662(n+1) - A055662(n))

#------------------------------------------------------------------------------
# A060592 - square array path length m to n
# vertex coded in ternary digits

MyOEIS::compare_values
  (anum => 'A060592',
   func => sub {
     my ($count) = @_;
     my $discs = -1;
     my $graph = Graph->new;
     my $ensure_graph = sub {
       my ($v) = @_;
       unless ($graph->has_vertex($v)) {
         $discs++;
         $graph = Graph::Maker->new('hanoi',
                                    discs => $discs,
                                    undirected => 1);
       }
     };
     my @got;
     for (my $s = 0; @got < $count; $s++) {  # anti-diagonal sum
       foreach my $to (0 .. $s) {
         my $from = $s - $to;
         $ensure_graph->($from);
         $ensure_graph->($to);
         push @got, $graph->path_length($from,$to);
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A007665 - 5 spindles solution length

MyOEIS::compare_values
  (anum => 'A007665',
   max_count => 4,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $discs = 1; @got < $count; $discs++) {
       my $graph = Graph::Maker->new('hanoi',
                                     discs => $discs,
                                     spindles => 5);
       my $from = min($graph->vertices);
       my $to   = max($graph->vertices);
       my @path = $graph->SP_Dijkstra($from,$to);
       push @got, scalar(@path)-1;
     }
     return \@got;
   });

# Codrut Grosu, "A New Lower Bound For the Towers of Hanoi Problem",
# arxiv 1508.04272
# lower bound
# p>=4 spindles, n>=1 discs
# n-1 = binomial(m+p-3,p-2) + binomial(t+p-4,p-3) + r      m,t,r
# m>=t and 0 <= r < binomial(t+p-4,p-4)
# GP-DEFINE  mtr(p,n) = {
# GP-DEFINE    n>=1 || error();
# GP-DEFINE    p>=4 || error();
# GP-DEFINE    for(m=0,oo,
# GP-DEFINE      my(s = n-1 - binomial(m+p-3,p-2));
# GP-DEFINE      if(s<0, error("n="n" m="m));
# GP-DEFINE      for(t=0,m,
# GP-DEFINE        my(r = s - binomial(t+p-4,p-3));
# GP-DEFINE        if(0 <= r && r < binomial(t+p-4,p-4),
# GP-DEFINE          return([m,t,r]))));
# GP-DEFINE  }
# GP-DEFINE  Hmin(p,n) = \
# GP-DEFINE    my(m,t,r);[m,t,r]=mtr(p,n);  (m+t)*2^(m-2*(p-2));
# vector(10,n, mtr(5,n))
# vector(15,n, Hmin(5,n))
# my(p=5); \
# for(n=1,100, my(m,t,r);[m,t,r]=mtr(p,n); \
#   print(n" "m" "t" "r"  "Hmin(p,n)))

#------------------------------------------------------------------------------
# A182058 - 6 spindles solution length

MyOEIS::compare_values
  (anum => 'A182058',
   max_count => 5,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $discs = 1; @got < $count; $discs++) {
       my $graph = Graph::Maker->new('hanoi',
                                     discs => $discs,
                                     spindles => 6);
       my $from = min($graph->vertices);
       my $to   = max($graph->vertices);
       my @path = $graph->SP_Dijkstra($from,$to);
       push @got, scalar(@path)-1;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A060583 ternary code
# A060587 inverse

# GP-DEFINE  \\ x,y are 0,1,2 and different, return the term not x and not y
# GP-DEFINE  other3(x,y) = {
# GP-DEFINE    my(v=setminus([0,1,2],Set([x,y])));
# GP-DEFINE    #v==1 || error();
# GP-DEFINE    v[1];
# GP-DEFINE  }
# GP-Test  matrix(3,3,x,y,x--;y--; if(x!=y, other3(x,y))) == \
# GP-Test  matrix(3,3,x,y,x--;y--; if(x!=y, 3-x-y))

# GP-DEFINE  A060583(n) = {
# GP-DEFINE    my(v=digits(n,3),p=0);
# GP-DEFINE    for(i=1,#v, if(v[i]!=p, p=3-p-v[i]; v[i]=p));
# GP-DEFINE    fromdigits(v,3);
# GP-DEFINE  }
# GP-DEFINE  A060583(n) = {
# GP-DEFINE    my(v=digits(n,3),p=0);
# GP-DEFINE    if(#v, v[1]=3-v[1];
# GP-DEFINE           for(i=2,#v, if(v[i]!=v[i-1], v[i]=3-v[i-1]-v[i])));
# GP-DEFINE    fromdigits(v,3);
# GP-DEFINE  }
# GP-Test  my(v=OEIS_samples("A060583")); /* OFFSET=0 */ \
# GP-Test    vector(#v,n,n--; A060583(n)) == v
# GP-Test  A060583(46) == 76

# GP-DEFINE  A060587(n) = {
# GP-DEFINE    my(v=digits(n,3),p=0);
# GP-DEFINE    for(i=1,#v, if(v[i]!=p, [p,v[i]] = [v[i], 3-p-v[i]]));
# GP-DEFINE    fromdigits(v,3);
# GP-DEFINE  }
# GP-DEFINE  A060587(n) = {
# GP-DEFINE    my(v=digits(n,3),p=0);
# GP-DEFINE    if(#v,
# GP-DEFINE       forstep(i=#v,2,-1, if(v[i]!=v[i-1], v[i] = 3-v[i-1]-v[i]));
# GP-DEFINE       v[1]=3-v[1]);
# GP-DEFINE    fromdigits(v,3);
# GP-DEFINE  }
# GP-Test  my(v=OEIS_samples("A060587")); /* OFFSET=0 */ \
# GP-Test    vector(#v,n,n--; A060587(n)) == v
# GP-Test  A060587(76) == 46
# GP-Test  /* inverses */ \
# GP-Test  vector(1000,n, A060587(A060583(n))) == \
# GP-Test  vector(1000,n, n)

# GP-Test  to_ternary(A060583(from_ternary(11111222220000022221111))) == \
# GP-Test                                  20202222221212101011111

# GP-Test  to_ternary(A060587(from_ternary(11111222220000022221111))) == \
# GP-Test                                  21111022221000012220111

# vector(9,n,n--; to_ternary(A060587(n)))
# vector(9,n,n--; to_ternary(A060583(n)))
#         00                 00
#       02  01             02  01
#     21      12         22      11
#   20  22  11  10     21  20  10  12
#
#            00
#          01  02
#        10      20
#      11  12  21  22
#   100              200
#  [0,1,2, 3,4,5, 6,7,8] by sub-triangles


#------------------------------------------------------------------------------
# A292764 - 4 spindles directed cyclic solution length

# Graph::Maker::Hanoi doesn't have directed cycle yet.
#
# MyOEIS::compare_values
#   (anum => 'A292764',
#    max_count => 6,
#    func => sub {
#      my ($count) = @_;
#      my @got;
#      for (my $discs = 0; @got < $count; $discs++) {
#        my $graph = Graph::Maker->new('hanoi',
#                                      discs => $discs,
#                                      spindles => 4,
#                                      adjacency => 'cyclic');
#        my $from = min($graph->vertices);
#        my $to   = max($graph->vertices) *2/3;  # all digit 3s -> 2s
#        my @path = $graph->SP_Dijkstra($from,$to);
#        push @got, scalar(@path)-1;
#      }
#      return \@got;
#    });

#------------------------------------------------------------------------------
# A007664 - 4 spindles solution length (Frame-Stewart)

MyOEIS::compare_values
  (anum => 'A007664',
   max_count => 6,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $discs = 0; @got < $count; $discs++) {
       my $graph = Graph::Maker->new('hanoi',
                                     discs => $discs,
                                     spindles => 4);
       my $from = min($graph->vertices);
       my $to   = max($graph->vertices);
       my @path = $graph->SP_Dijkstra($from,$to);
       push @got, scalar(@path)-1;
     }
     return \@got;
   });

#------------------------------------------------------------------------------
# A005665, A005666 - 3 spindles cyclic one-way solution length

# Graph::Maker::Hanoi doesn't have directed cycle yet.
#
# MyOEIS::compare_values
#   (anum => 'A005665',
#    max_count => 5,
#    func => sub {
#      my ($count) = @_;
#      my @got;
#      for (my $discs = 0; @got < $count; $discs++) {
#        my $graph = Graph::Maker->new('hanoi',
#                                      discs => $discs,
#                                      adjacency => 'cyclic');
#        my $from = min($graph->vertices);
#        my $to   = max($graph->vertices);
#        my @path = $graph->SP_Dijkstra($from,$to);
#        push @got, scalar(@path)-1;
#      }
#      return \@got;
#    });


#------------------------------------------------------------------------------
# A089280 - num pegs occupied after n moves (by discs moved so far)

# GP-DEFINE  ternary_num_diff_digits(n) = #Set(digits(n,3));
# GP-Test  my(v=OEIS_samples("A043530")); /* OFFSET=1 */ \
# GP-Test    vector(#v,n, ternary_num_diff_digits(n)) == v
# vector(50,n, ternary_num_diff_digits(n))

# GP-DEFINE  num_diff_digits(n) = #Set(digits(n));
# GP-Test  my(v=OEIS_samples("A043537")); /* OFFSET=1 */ \
# GP-Test    vector(#v,n, num_diff_digits(n)) == v
# vector(50,n, num_diff_digits(n))

# num diff digits in A055662
# vector(50,n, A055662(n))
# vector(50,n, num_diff_digits(A055662(n)))

# GP-DEFINE  A089280(n) = {
# GP-DEFINE    if(n>>=valuation(n+(n%2),2),
# GP-DEFINE       my(k); while(n>>=(k=valuation(n+(n%2),2)),
# GP-DEFINE                    if(k%2,return(3))); 2,
# GP-DEFINE       1);
# GP-DEFINE  }
# GP-Test  my(v=OEIS_samples("A089280")); /* OFFSET=1 */ \
# GP-Test    vector(#v,n, A089280(n)) == v
# GP-Test  vector(2^14,n, num_diff_digits(A055662(n))) == \
# GP-Test  vector(2^14,n, A089280(n))

# digit      0,1,2
# prev bit   0,1
# num diffs and pos parity  0,1
# 3*2*2 == 12 \\ states
#
# GP-DEFINE  {
# GP-DEFINE    my(table=[7,8, 2,12,1, 12,1,2, 7,8,6, 6;
# GP-DEFINE              3,4, 9,10,11, 10,11,9, 3,4,5, 5]);
# GP-DEFINE    A055662_by_transitions_mat(n) =
# GP-DEFINE      my(v=binary(n), state=if(#v%2,6,12));
# GP-DEFINE      for(i=1,#v,
# GP-DEFINE        state=table[1+v[i],state];
# GP-DEFINE        v[i]=state%3);
# GP-DEFINE      fromdigits(v);
# GP-DEFINE  }
# GP-Test  vector(2^14,n, A055662_by_transitions_mat(n)) == \
# GP-Test  vector(2^14,n, A055662(n))
# GP-DEFINE  {
# GP-DEFINE    my(table=[13,9,15,11,17,7,3,19,5,21,1,23,
# GP-DEFINE              1,23,3,19,5,21,17,7,13,9,15,11]);
# GP-DEFINE    A055662_by_transitions(n) =
# GP-DEFINE      my(v=binary(n), state=if(#v%2,15,3));
# GP-DEFINE      for(i=1,#v, state=table[state+v[i]]; v[i]=state%3);
# GP-DEFINE      fromdigits(v);
# GP-DEFINE  }
# GP-Test  vector(2^14,n, A055662_by_transitions(n)) == \
# GP-Test  vector(2^14,n, A055662(n))
#
# by_transitions(0)
# by_transitions(1)
# my(n=from_binary(11111100001111001110110000000)); \
#   printf("%7d\n%7d\n%7d\n\n", to_binary(n), A055662(n), by_transitions(n));

# GP-DEFINE  to_binary(n)=fromdigits(binary(n))*sign(n);
# GP-DEFINE  from_binary(n)=fromdigits(digits(n),2);
# for(n=16,32, printf("%7d\n%7d\n%7d\n\n", to_binary(n), A055662(n), by_transitions(n)));



#------------------------------------------------------------------------------
# A103897 - 3 * 2^(n-1)*(2^n - 1).
# num_edges/2 of 4 spindles

MyOEIS::compare_values
  (anum => 'A103897',
   max_count => 6,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $discs = 1; @got < $count; $discs++) {
       my $graph = Graph::Maker->new('hanoi',
                                     discs => $discs,
                                     spindles => 4,
                                     undirected => 1);
       push @got, scalar($graph->edges) / 2;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A160002 - 4 spindles linear, n discs steps to move first to last spindle

MyOEIS::compare_values
  (anum => 'A160002',
   max_count => 6,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $discs = 0; @got < $count; $discs++) {
       my $graph = Graph::Maker->new('hanoi',
                                     discs => $discs,
                                     spindles => 4,
                                     adjacency => 'linear',
                                     undirected => 1);
       my $from = min($graph->vertices);  # centre
       my $to   = max($graph->vertices);  # outer
       my @path = $graph->SP_Dijkstra($from,$to);
       push @got, scalar(@path) - 1;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
# A291877  4 spindles star, n discs steps to move centre to arm

MyOEIS::compare_values
  (anum => 'A291877',
   max_count => 6,
   func => sub {
     my ($count) = @_;
     my @got;
     for (my $discs = 1; @got < $count; $discs++) {
       my $graph = Graph::Maker->new('hanoi',
                                     discs => $discs,
                                     spindles => 4,
                                     adjacency => 'star',
                                     undirected => 1);
       my $from = min($graph->vertices);  # centre
       my $to   = max($graph->vertices);  # outer
       my @path = $graph->SP_Dijkstra($from,$to);
       push @got, scalar(@path) - 1;
     }
     return \@got;
   });


#------------------------------------------------------------------------------
exit 0;
