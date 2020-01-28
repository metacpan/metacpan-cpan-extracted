#!/usr/bin/perl -w

# Copyright 2015, 2017, 2019, 2020 Kevin Ryde
#
# This file is part of Graph-Maker-Other.
#
# Graph-Maker-Other is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Graph-Maker-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Maker-Other.  If not, see <http://www.gnu.org/licenses/>.

use 5.005;
use strict;
use Graph::Maker::BinomialTree;
use List::Util 'min','max','sum';

use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'devel', 'lib');
use MyGraphs;
$|=1;

# uncomment this to run the ### lines
use Smart::Comments;

{
  # BinomialTree by n

  # n=0 empty
  # n=1 https://hog.grinvin.org/ViewGraphInfo.action?id=1310  single vertex
  # n=2 https://hog.grinvin.org/ViewGraphInfo.action?id=19655  path-2
  # n=3 hog not  path-3
  # n=4 https://hog.grinvin.org/ViewGraphInfo.action?id=594    path-4
  # n=5 https://hog.grinvin.org/ViewGraphInfo.action?id=30     fork
  # n=6 https://hog.grinvin.org/ViewGraphInfo.action?id=496    E graph
  # n=7 https://hog.grinvin.org/ViewGraphInfo.action?id=714   (Graphedron)
  # n=8 https://hog.grinvin.org/ViewGraphInfo.action?id=700
  # n=9 not
  # n=10 not
  # n=11 not
  # n=12 not
  # n=13 not
  # n=14 not
  # n=15 not
  # n=16 https://hog.grinvin.org/ViewGraphInfo.action?id=28507   order 4
  # n=32 https://hog.grinvin.org/ViewGraphInfo.action?id=21088   order 5
  # n=64 https://hog.grinvin.org/ViewGraphInfo.action?id=33543
  # n=128 https://hog.grinvin.org/ViewGraphInfo.action?id=33545

  my @graphs;
  foreach my $N (
                 9 .. 16,
                 64, 128,
                ) {
    my $graph = Graph::Maker->new('binomial_tree',
                                  N => $N,
                                  undirected => 1,
                                  coordinate_type => 'across',
                                 );
    print $graph->get_graph_attribute ('name'),"\n";
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  MyGraphs::hog_upload_html($graphs[0]);
  exit 0;
}
{
  # BinomialTree by n properties
  # total depths
  # 0,0,1,2,4,5,7,9,12,13,15,17,20,22,25,28,32,
  # A000788 total 1s
  #
  # total path lengths to end
  # 0,0,1,3,6,8,13,15,22,20,29,31,42,36,49,51,66,
  # 0 1 2 3 4 5  6  7  8
  # not in OEIS: 1,3,6,8,13,15,22,20,29,31,42,36,49,51,66,
  #              
  #
  foreach my $N (
                 0 .. 32
                ) {
    my $graph = Graph::Maker->new('binomial_tree',
                                  N => $N,
                                  undirected => 1);

    # my $total_depths = 0;
    # foreach my $v ($graph->vertices) {
    #   $total_depths += $graph->path_length(0,$v);
    # }
    # print "$total_depths,";

    my $total_ends = 0;
    foreach my $v ($graph->vertices) {
      $total_ends += $graph->path_length($N-1,$v);
    }
    print "$total_ends,";
  }
  exit 0;
}

{
  # BinomialTree N, Wiener index
  #
  # But better in vpar examples/binomial-tree-W.gp
  #
  # 2*n, add new under each
  #   4* existing
  #   new edge traversed 2*n-1 times, for n new edges
  # GP-Test  my(n=7); 4*46 + n*(2*n-1) == 275
  # N=14  W=275
  #
  # 2*n-1, add new under each except the last
  #   remove last traversed 2n-1 times
  #   remove 2* paths to n end, and n-1 new edges
  # my(n=7); 4*68 - (2*n-1) - 2*15 - (n-1)
  # N=13  W=226
  #
  # GP-DEFINE  highbit_k(n) = logint(n,2);
  # GP-Test  highbit_k(1) == 0
  # GP-Test  highbit_k(3) == 1
  # GP-Test  highbit_k(4) == 2
  # GP-DEFINE  highbit(n) = 1<<highbit_k(n);
  # GP-Test  highbit(1) == 1
  # GP-Test  highbit(3) == 2
  # GP-Test  highbit(4) == 4
  # GP-DEFINE  \\ Return a vector of powers so n = 2^v[1] + 2^v[2] + ...
  # GP-DEFINE  \\ Powers are in ascending order v[1] < v[2] < ...
  # GP-DEFINE  binary_powers(n) = {
  # GP-DEFINE    n>=0 || error();
  # GP-DEFINE    my(b=binary(n));
  # GP-DEFINE    my(v=select(bit->bit!=0, b, 1));
  # GP-DEFINE    vector(#v,i, #b - v[#v-i+1]);
  # GP-DEFINE  }
  # GP-Test  binary_powers(0) == []
  # GP-Test  binary_powers(2) == [1]
  # GP-Test  binary_powers(5) == [0,2]
  # GP-Test  binary_powers(13) == [0,2,3]
  # GP-Test  vector(1000,n,n--; my(v=binary_powers(n)); \
  # GP-Test                     sum(i=1,#v, 2^v[i])) == \
  # GP-Test  vector(1000,n,n--; n)
  #
  # GP-DEFINE  vector_is_strictly_increasing(v) = \
  # GP-DEFINE    for(i=1,#v-1, if(v[i]>=v[i+1], return(0))); 1;
  # GP-Test  vector(1000,n,n--; \
  # GP-Test   vector_is_strictly_increasing(binary_powers(n))) == \
  # GP-Test  vector(1000,n,n--; 1)
  #
  # GP-DEFINE  WtopK(k) = k*2^(k-1);
  # GP-Test  vector(100,k, WtopK(k)) == \
  # GP-Test  vector(100,k, 2*WtopK(k-1) + 2^(k-1))
  # vector(5,k,k--; Wtop(2^k))
  #
  # GP-DEFINE  WK(k) = (k-1)*2^(2*k-1) + 2^(k-1);  \\ Iyer and Reddy
  # GP-Test  /* two halves and across them */ \
  # GP-Test  vector(100,k, WK(k)) == \
  # GP-Test  vector(100,k, 2*WK(k-1) + 2^(k-1)*2^(k-1) + 2*WtopK(k-1)*2^(k-1))
  # GP-Test  /* each vertex becomes a pair */ \
  # GP-Test  vector(100,k, WK(k)) == \
  # GP-Test  vector(100,k, 4*WK(k-1) + 2^(k-1)*(2^k-1))
  #
  # GP-DEFINE  Wtop_sample(n) = [0,0,1,2,4,5,7,9,12,13,15,17,20,22,25,28,32,33,35,37,40,42,45,48,52,54,57,60,64,67,71,75,80][n+1];
  # GP-Test  Wtop_sample(0) == 0
  # GP-Test  Wtop_sample(1) == 0
  # GP-Test  Wtop_sample(2) == 1
  #
  # A000788 total 1s in 0 .. n
  # cf Wtop total in 0 .. n-1 which is n many vertices
  # GP-DEFINE  A000788(n) = sum(i=0,n, hammingweight(i));
  # my(v=OEIS_samples("A000788")); vector(#v,n,n--; A000788(n)) == v
  #
  # GP-DEFINE  A000788_by_bits(n) = {   \\ Shreevatsa R in A000788
  # GP-DEFINE    my(ret=0);
  # GP-DEFINE    while(n,
  # GP-DEFINE      my(k=highbit_k(n), h=1<<k, r=n-h);
  # GP-DEFINE      ret += k*2^(k-1) + r + 1;
  # GP-DEFINE      n = r);
  # GP-DEFINE    ret;
  # GP-DEFINE  }
  # GP-Test  vector(100,n,n--; A000788(n)) == \
  # GP-Test  vector(100,n,n--; A000788_by_bits(n))
  #
  #     0
  #     | \
  #     1  2
  #        |
  #        3
  # GP-Test  Wtop_sample(4) == 1+1+2  /* 4 vertices */
  # GP-DEFINE  Wtop(n) = {
  # GP-DEFINE    n--;   \\ max vertex number
  # GP-DEFINE    my(ret=0);
  # GP-DEFINE    while(n>0,
  # GP-DEFINE      my(k=highbit_k(n), h=1<<k, r=n-h);
  # GP-DEFINE      ret += WtopK(k) + r + 1;
  # GP-DEFINE      n = r);
  # GP-DEFINE    ret;
  # GP-DEFINE  }
  # GP-Test  vector(32,n,n--; Wtop(n)) == \
  # GP-Test  vector(32,n,n--; Wtop_sample(n))
  #
  # GP-DEFINE  Wtop_by_powers_WtopK(n) = {
  # GP-DEFINE     my(v=binary_powers(n));
  # GP-DEFINE     v=Vecrev(v);    \\ high to low
  # GP-DEFINE     sum(i=1,#v,  WtopK(v[i]) + (i-1)*2^v[i]);
  # GP-DEFINE  }
  # GP-Test  vector(1024,n,n--; Wtop(n)) == \
  # GP-Test  vector(1024,n,n--; Wtop_by_powers_WtopK(n))
  #
  # GP-DEFINE  Wtop_by_powers(n) = {
  # GP-DEFINE    my(k=Vecrev(binary_powers(n)));  \\ high to low
  # GP-DEFINE    sum(i=1,#k,  (k[i]/2 + (i-1))*2^k[i]);
  # GP-DEFINE  }
  # GP-Test  vector(1024,n,n--; Wtop(n)) == \
  # GP-Test  vector(1024,n,n--; Wtop_by_powers(n))
  # GP-Test  my(k=[2,0],i=1); (1/2*k[i] + (i-1))*2^k[i]  == 4
  # GP-Test  my(k=[2,0],i=2); (1/2*k[i] + (i-1))*2^k[i]  == 1
  #
  # n=1101 = 13 vertices  0 to 12 inclusive
  # GP-Test  sum(i=8,11, hammingweight(i)) == 8
  # GP-Test  my(k=[3,2,0],i=1); (1/2*k[i] + (i-1))*2^k[i]  == 12
  # GP-Test  my(k=[3,2,0],i=2); (1/2*k[i] + (i-1))*2^k[i]  == 8
  # GP-Test  my(k=[3,2,0],i=3); (1/2*k[i] + (i-1))*2^k[i]  == 2
  # Each term is sum terms from bits k[0..i-1] to k[0..i]-1 inclusive.
  # Index i-1 = 0,1,2,... is "extra" depth each of these.
  #
  # GP-DEFINE  Wtop_by_bittest(n) = {
  # GP-DEFINE    my(d=0, ret=0);
  # GP-DEFINE    forstep(k=logint(n+1,2),0,-1,
  # GP-DEFINE      if(bittest(n,k),
  # GP-DEFINE         ret += (k/2 + d)*2^k;
  # GP-DEFINE         d++));
  # GP-DEFINE    ret;
  # GP-DEFINE  }
  # GP-Test  vector(1024,n,n--; Wtop(n)) == \
  # GP-Test  vector(1024,n,n--; Wtop_by_bittest(n))
  #
  # -----------
  #
  #     0
  #     | \  \
  #     1  2   4
  #        |
  #        3   
  #
  # GP-DEFINE  Wend_sample(n) = [0,0,1,3,6,8,13,15,22,20,29,31,42,36,49,51,66,48,65,67,86,72,93,95,118,84,109,111,138,116,145,147,178][n+1];
  # GP-Test  Wend_sample(0) == 0
  # GP-Test  Wend_sample(1) == 0
  # GP-Test  Wend_sample(2) == 1   /* 2 vertices */
  #
  # GP-DEFINE  Wend(n) = {
  # GP-DEFINE    n--;   \\ n vertices, n-1 max vertex number
  # GP-DEFINE    my(ret=0);
  # GP-DEFINE    while(n>0,
  # GP-DEFINE      my(k=highbit_k(n), h=1<<k, r=n-h);
  # GP-DEFINE      \\ print("top k="k" and hamming n="n);
  # GP-DEFINE      ret += WtopK(k) + 2^k*hammingweight(n);
  # GP-DEFINE      n = r);
  # GP-DEFINE    ret;
  # GP-DEFINE  }
  # GP-DEFINE    
  # GP-Test  vector(32,n,n--; Wend_sample(n)) == \
  # GP-Test  vector(32,n,n--; Wend(n))
  # 
  # GP-DEFINE  Wend_by_powers_WtopK(n) = {
  # GP-DEFINE    if(n==0,0,
  # GP-DEFINE       my(k=binary_powers(n-1)); \\ n vertices, n-1 max vertex
  # GP-DEFINE       sum(i=1,#k,
  # GP-DEFINE         \\ print("power "k[i]);
  # GP-DEFINE         WtopK(k[i]) + i*2^k[i]));
  # GP-DEFINE  }
  # GP-DEFINE    
  # GP-Test  vector(100,n,n--; Wend(n)) == \
  # GP-Test  vector(100,n,n--; Wend_by_powers_WtopK(n))
  #
  # GP-DEFINE  Wend_by_powers(n) = {
  # GP-DEFINE    if(n==0,0,
  # GP-DEFINE       my(k=binary_powers(n-1)); \\ low to high, max vertex number
  # GP-DEFINE       sum(i=1,#k,  (k[i]/2 + i)*2^k[i]));
  # GP-DEFINE  }
  # GP-DEFINE    
  # GP-Test  vector(100,n,n--; Wend(n)) == \
  # GP-Test  vector(100,n,n--; Wend_by_powers(n))
  # GP-Test  binary_powers(3) == [0,1]
  # GP-Test  binary_powers(2) == [1]
  # GP-Test  Wtop(1) == 0
  # GP-Test  Wtop(0) == 0
  # GP-Test  2^1*2 == 4
  # GP-Test  Wend(3) == 3
  # GP-Test  Wend_by_powers(3) == 3
  # Each term is distances to vertices with low i many bits cleared ... maybe?
  #
  # -----------
  # GP-DEFINE  W_sample(n) = [0,0,1,4,10,18,31,46,68,88,117,148,190,226,275,326,392,440,505,572,658,730,823,918,1036,1120,1229,1340,1478,1594,1739,1886,2064][n+1];
  # GP-Test  vector(5,k,k--; W_sample(2^k)) == \
  # GP-Test  vector(5,k,k--; WK(k))
  #
  # Each vertex becomes a pair.
  # 4*W(n) between them, not including extra distance to the new ones.
  # new to old is n*n
  # new to new is n*(n-1)
  # GP-Test  /* each vertex becomes a pair */ \
  # GP-Test  vector(16,n,n--; W_sample(2*n)) == \
  # GP-Test  vector(16,n,n--; 4*W_sample(n) + n*n + n*(n-1))
  # GP-Test  vector(16,n,n--; W_sample(2*n)) == \
  # GP-Test  vector(16,n,n--; 4*W_sample(n) + n*(2*n-1))
  #
  # Odd extra Wend.
  # GP-Test  vector(16,n, W_sample(n)) == \
  # GP-Test  vector(16,n, W_sample(n-1) + Wend(n))
  #
  # W in 2^k blocks
  # my(k=3); vector(2^k,r,r--; my(n=2^k+r); W(n))
  # my(k=3); vector(2^k,r,r--; my(n=2^k+r); \
  #             W(2^k) + W(r)  + 2^k*r + Wtop(2^k)*r + Wtop(r)*2^k)
  # my(k=3); vector(2^k,r,r--; my(n=2^k+r); \
  #      2*(k-1)*4^(k-1) + ((k+2)*r + 1)*2^(k-1)  + W(r) + Wtop(r)*2^k)
  # n = 2^k + r
  # vector(25,k,k--; WK(k))
  #
  # GP-Test  W_sample(8) + W_sample(4) \
  # GP-Test    + Wtop(8)*2^2 + Wtop(4)*2^3 + 1*2^2*2^3 == \
  # GP-Test  W_sample(12)
  # GP-Test  (3-1)*2^(2*3-1) + 1/2*2^3 + \
  # GP-Test  (2-1)*2^(2*2-1) + 1/2*2^2 + \
  # GP-Test    (3/2 + 2/2 + 1)*2^(2+3) == \
  # GP-Test  W_sample(12)
  #
  # GP-DEFINE  W_by_powers(n) = {
  # GP-DEFINE    if(n==0,return(0));
  # GP-DEFINE    my(k=binary_powers(n)); \\ low to high, max vertex number
  # GP-DEFINE    sum(i=1,#k,  WK(k[i]))
  # GP-DEFINE    + sum(i=2,#k,
  # GP-DEFINE        sum(j=1,i-1,
  # GP-DEFINE          (k[i]/2 + k[j]/2 + i-j)*2^(k[i]+k[j])));
  # GP-DEFINE  }
  # GP-Test  vector(32,n, W_by_powers(n)) == \
  # GP-Test  vector(32,n, W_sample(n))
  # W_by_powers(12)
  #
  # GP-DEFINE  W_by_powers(n) = {
  # GP-DEFINE    if(n==0,return(0));
  # GP-DEFINE    my(k=binary_powers(n)); \\ low to high, max vertex number
  # GP-DEFINE    n/2       \\ each 1/2*2^k[i]
  # GP-DEFINE    + sum(i=1,#k,  (k[i]-1)/2 * 4^k[i])
  # GP-DEFINE    + sum(i=1,#k,
  # GP-DEFINE        sum(j=1,i-1,
  # GP-DEFINE          (k[i]/2 + k[j]/2 + i-j)*2^(k[i]+k[j])));
  # GP-DEFINE  }
  # GP-Test  vector(32,n, W_by_powers(n)) == \
  # GP-Test  vector(32,n, W_sample(n))
  #
  # GP-DEFINE  W_by_powers(n) = {
  # GP-DEFINE    my(k=binary_powers(n)); \\ low to high, max vertex number
  # GP-DEFINE    sum(i=1,#k,
  # GP-DEFINE        ((k[i]-1) * 4^k[i] + 2^k[i])/2
  # GP-DEFINE        + sum(j=i+1,#k,
  # GP-DEFINE            (k[i]/2 + k[j]/2 + j-i)*2^(k[i]+k[j])));
  # GP-DEFINE  }
  # GP-Test  vector(32,n,n--; W_by_powers(n)) == \
  # GP-Test  vector(32,n,n--; W_sample(n))
  #
  # GP-DEFINE  W_by_bits(n) = {       \\ FIXME: This wone is wrong.
  # GP-DEFINE    my(ret=0,m=0);
  # GP-DEFINE    forstep(k=logint(n+1,2),0,-1,
  # GP-DEFINE      ret = 4*ret + m*(2*m-1);
  # GP-DEFINE      m*=2;
  # GP-DEFINE      if(bittest(n,k),
  # GP-DEFINE         m++; ret+=Wend_by_powers(m+1)));
  # GP-DEFINE    m==n || error();
  # GP-DEFINE    ret;
  # GP-DEFINE  }
  #  vector(32,n,n--; W_by_bits(n))
  #  vector(32,n,n--; W_sample(n))

  foreach my $N (
                 0 .. 32
                ) {
    my $graph = Graph::Maker->new('binomial_tree',
                                  N => $N,
                                  undirected => 1);
    # print "N=",scalar($graph->vertices),
    #   "  W=",MyGraphs::Graph_Wiener_index($graph),"\n";
    # print MyGraphs::Graph_Wiener_index($graph),",";
  }
  exit 0;
}



{
  # BinomialTree forms ascii prints

  # order=0 https://hog.grinvin.org/ViewGraphInfo.action?id=1310  single vertex
  # order=1 https://hog.grinvin.org/ViewGraphInfo.action?id=19655  path-2
  # order=2 https://hog.grinvin.org/ViewGraphInfo.action?id=594    path-4
  # order=3 https://hog.grinvin.org/ViewGraphInfo.action?id=700
  # order=4 hog not
  # order=5 https://hog.grinvin.org/ViewGraphInfo.action?id=21088
  # order=6 hog not

  #    0       count 1      order=3
  # /--|--\
  # 1 2   4    count 3
  #   |  /^\
  #   3  5 6   count 3
  #        |
  #        7   count 1

  require Graph::Maker::BinomialTree;
  my @graphs;
  foreach my $order (0 .. 5) {
    my $graph = Graph::Maker->new('binomial_tree',
                                  order => $order,
                                  undirected => 1,
                                 );
    print $graph->get_graph_attribute ('name'),"\n";
    if ($order == 4) {
      MyGraphs::Graph_tree_print($graph);
      print "N=",scalar($graph->vertices),
        "  W=",MyGraphs::Graph_Wiener_index($graph),"\n";
    }
    # MyGraphs::Graph_view($graph);
    push @graphs, $graph;
    print "\n";
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  foreach my $i (1 .. 31) {
    my $mask = $i ^ ($i-1);
    my $parent = $i & ~$mask;
    my $diff = $parent ^ $i;
    printf "%5b %5b -> %5b   %5b\n", $i, $mask&0x1F, $parent, $diff;
  }
  exit 0;
}
