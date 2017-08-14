#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017 Kevin Ryde
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

use strict;
use 5.010;
use FindBin;
use File::Slurp;
use List::Util 'min','max';
use POSIX 'ceil';
use MyGraphs;
# GP-DEFINE  nearly_equal(x,y,delta=1-e10) = abs(x-y) < delta;
$|=1;

# uncomment this to run the ### lines
use Smart::Comments;


{
  # subdivision of bi-star minimal dominating sets
  require Graph::Maker::BiStar;
  my @graphs;
  foreach my $args ([N=>5,M=>5],
                    [N=>6,M=>4],
                    [N=>4,M=>6],
                   ) {
    my $graph = Graph::Maker->new('bi_star', undirected=>1, @$args);
    MyGraphs::Graph_subdivide($graph);
    push @graphs, $graph;
    print $graph->get_graph_attribute('name'),
      "  ", MyGraphs::Graph_tree_minimal_domsets_count($graph),"\n";
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # HOG bistars

  # 2,2 https://hog.grinvin.org/ViewGraphInfo.action?id=594   path-4
  # 3,2 https://hog.grinvin.org/ViewGraphInfo.action?id=30    fork
  # 4,2 https://hog.grinvin.org/ViewGraphInfo.action?id=208   cross
  # 3,3 https://hog.grinvin.org/ViewGraphInfo.action?id=334   H graph
  # 4,3 https://hog.grinvin.org/ViewGraphInfo.action?id=452
  # 4,4 https://hog.grinvin.org/ViewGraphInfo.action?id=586   Ethane
  # 5,2 https://hog.grinvin.org/ViewGraphInfo.action?id=266
  # 5,3 not
  # 5,4 https://hog.grinvin.org/ViewGraphInfo.action?id=634
  # 5,5 https://hog.grinvin.org/ViewGraphInfo.action?id=112
  #
  # 6,2 https://hog.grinvin.org/ViewGraphInfo.action?id=332
  # 6,3 not
  # 6,4 not
  # 6,5 https://hog.grinvin.org/ViewGraphInfo.action?id=650
  # 6,6 https://hog.grinvin.org/ViewGraphInfo.action?id=36
  #
  # 7,2 https://hog.grinvin.org/ViewGraphInfo.action?id=366
  # 7,3 not
  # 7,4 not
  # 7,5 not
  # 7,6 https://hog.grinvin.org/ViewGraphInfo.action?id=38
  # 7,7 https://hog.grinvin.org/ViewGraphInfo.action?id=166
  #
  # 8,2 https://hog.grinvin.org/ViewGraphInfo.action?id=436
  # 8,3 not
  # 8,4 not
  # 8,5 not
  # 8,6 not
  # 8,7 https://hog.grinvin.org/ViewGraphInfo.action?id=168
  # 8,8 not
  #
  # 9,2 https://hog.grinvin.org/ViewGraphInfo.action?id=316
  # 9,3 not
  # 9,4 not
  # 9,5 not
  # 9,6 not
  # 9,7 not
  # 9,8 not
  # 9,9 not
  #
  # 10,2 https://hog.grinvin.org/ViewGraphInfo.action?id=320
  # 10,3 not
  # 10,4 not
  # 10,5 not
  # 10,6 https://hog.grinvin.org/ViewGraphInfo.action?id=27414  (me)
  # 10,7 not
  # 10,8 not
  # 10,9 not
  # 10,10 not

  require Graph::Maker::BiStar;
  my @graphs;
  foreach my $n (8 .. 10) {
    foreach my $m (# 2,
                   3 .. $n,
                  ) {
      my $graph = Graph::Maker->new('bi_star', N=>$n, M=>$m, undirected=>1);
      push @graphs, $graph;
    }
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # HOG subdivision of bi-star, extra vertex in each edge

  # 3,3 https://hog.grinvin.org/ViewGraphInfo.action?id=25170  toothpick
  # 4,3 not
  # 4,4 not
  # 5,3 not
  # 5,4 not
  # 5,5 not https://hog.grinvin.org/ViewGraphInfo.action?id=28220
  # 6,3 not
  # 6,4 not https://hog.grinvin.org/ViewGraphInfo.action?id=28222
  # 6,5 not
  # 6,6 not

  require Graph::Maker::BiStar;
  my @graphs;
  foreach my $n (3 .. 6) {
    foreach my $m (3 .. $n) {
      my $graph = Graph::Maker->new('bi_star', N=>$n, M=>$m, undirected=>1);
      MyGraphs::Graph_subdivide($graph);
      push @graphs, $graph;
    }
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}





# GP-DEFINE  bistar_W(n,m) = (n+m)*(n+m-3) + n*m + 2 \
# GP-DEFINE                  + if(m==0,n-1) \
# GP-DEFINE                  + if(n==0,m-1);
# GP-DEFINE  bistar_pairs(n,m) = (n+m)*(n+m-1)/2;
# GP-Test  bistar_W('n,'m) == 'n^2 + 3*'n*'m + 'm^2 - 3*'n - 3*'m + 2
#
# GP-Test  matrix(16,16,n,m, bistar_W(n,m)) == \
# GP-Test  matrix(16,16,n,m, n--; m--; n + 2*n*(n-1)/2 + 2*n + 3*n*m \
# GP-Test                              + 1 + 2*m \
# GP-Test                              + m + 2*m*(m-1)/2)
# GP-Test  bistar_W(n,m) == (n+m)^2 + (n+1)*(m+2) - 5*n - 4*m
# GP-Test  bistar_W(10,6) == 270
# GP-Test  bistar_W(11,6) == 306
# GP-Test  306/bistar_pairs(11,6)/3 == 3/4
# bistar_W('n,'m)
# diameter=3
#
# BiStar 3,4 is mean distance 2/3 of diameter.
# GP-Test  bistar_W(3,4) == 42
# GP-Test  bistar_W(3,4) / bistar_pairs(3,4) == 2
#
#
# matrix(16,16,n,m, floor(bistar_W(n,m) / bistar_pairs(n,m) / 3 *1000))
# bistar_W(n,m) / bistar_pairs(n,m) / 3  = 3/4
# 4*bistar_W(n,m) = 9*bistar_pairs(n,m)
# GP-Test  bistar_W('n,'m) - 3*3/4*bistar_pairs('n,'m) == \
# GP-Test    -1/8*'n^2 + 3/4*'m*'n + -1/8*'m^2 - 15/8*'n - 15/8*'m + 2
#
# GP-DEFINE  bistar_W_diff(n,m) = \
# GP-DEFINE    1/8*n^2 - 3/4*m*n + 1/8*m^2 + 15/8*n + 15/8*m - 2
# GP-Test  bistar_W_diff(n,m) ==  9/4*bistar_pairs(n,m) - bistar_W(n,m)
# GP-Test  8*bistar_W_diff('n,'m) == 'n^2 - 6*'n*'m + 'm^2 + 15*'n + 15*'m - 16
#
# my(len=10000);for(n=1,len,for(m=1,n, my(d=bistar_W_diff(n,m)); if(d==0,print(n","m" = "n+m); if(d>0,break()))));
#
# bistar_W_diff('n-'a,'m-'b)
# GP-Test  bistar_W_diff('n-'a,'m-'b) == \
# GP-Test    1/8*'n^2 - 3/4*'m*'n + 1/8*'m^2 \
# GP-Test    + (-1/4*'a + 3/4*'b + 15/8)*'n \
# GP-Test    + ( 3/4*'a - 1/4*'b + 15/8)*'m \
# GP-Test    + 1/8*'a^2 - 3/4*'b*'a + 1/8*'b^2 - 15/8*'a - 15/8*'b - 2
#
# GP-Test  matsolve([-1/4,3/4; 3/4,-1/4],[-15/8;-15/8]) == [-15/4;-15/4]
#
# GP-Test  bistar_W_diff('n+15/4, 'm+15/4) == \
# GP-Test    1/8*n^2 - 3/4*m*n + 1/8*m^2 + 161/32
# GP-Test  32*bistar_W_diff('n+15/4, 'm+15/4) == \
# GP-Test    4*n^2 - 24*m*n + 4*m^2 + 161
# GP-Test  32*subst(subst(bistar_W_diff('n,'m),'n,'s+15/4),'m,'t+15/4) == \
# GP-Test    4*'s^2 - 24*'s*'t + 4*'t^2 + 161
#
# my(a=15/4,b=15/4); -(n+a)^2 + 6*(m+b)*(n+a) - (m+b)^2 - 15*(n+a) - 15*(m+b) + 16
# 4*n^2 - 24*m*n + 4*m^2 = -161
# GP-Test  24^2-4*4*4 == 512
# poldisc(Qfb(4,-24,4)) == 512
# qfeval(Qfb(4,-24,4),[1,0]) == 4
# qfeval(Qfb(4,-24,4),[1,2]) == -28
# qfeval(Qfb(4,-24,4),[2,2]) == -64
# qfeval(Qfb(4,-24,4),[2,-2]) == 128

# ax^2 + bxy + cy^2 + dx + ey + f = 0
# D=b^2-4ac  E=bd-2ae  F=d^2-4af
# DY^2 = (Dy+E)^2 + DF - E^2
# X=Dy+E
# Y=2ax+by+d
# N=E^2-D*F
# X^2 - DY^2 = N
# http://www.alpertron.com.ar/QUAD.HTM
# https://www.alpertron.com.ar/QUAD.HTM

# GP-DEFINE  quad_D(a,b,c,d,e,f) = b^2-4*a*c;
# GP-DEFINE  quad_E(a,b,c,d,e,f) = b*d-2*a*e;
# GP-DEFINE  quad_F(a,b,c,d,e,f) = d^2-4*a*f;
# GP-DEFINE  quad_N(a,b,c,d,e,f) = \
# GP-DEFINE    quad_E(a,b,c,d,e,f)^2 - quad_D(a,b,c,d,e,f)*quad_F(a,b,c,d,e,f);

# DY^2 = (Dy+E)^2 + DF - E^2

# GP-DEFINE  quad_X(x,y, a,b,c,d,e,f) = \
# GP-DEFINE    quad_D(a,b,c,d,e,f)*y + quad_E(a,b,c,d,e,f);
# GP-DEFINE  quad_Y(x,y, a,b,c,d,e,f) = 2*a*x + b*y + d;

# GP-DEFINE  quad_xy_to_XY(x,y, a,b,c,d,e,f) = \
# GP-DEFINE    [ quad_D(a,b,c,d,e,f)*y + quad_E(a,b,c,d,e,f); \
# GP-DEFINE      2*a*x + b*y + d ];

# GP-Test  my(XY=quad_xy_to_XY('x,'y, 'a,'b,'c,'d,'e,'f)); XY[1,1] == \
# GP-Test    quad_D('a,'b,'c,'d,'e,'f)*'y \
# GP-Test  + quad_E('a,'b,'c,'d,'e,'f)
# GP-Test  my(XY=quad_xy_to_XY('x,'y, 'a,'b,'c,'d,'e,'f)); \
# GP-Test  XY[2,1] == 2*'a*'x + 'b*'y + 'd

# GP-Test  my(XY=quad_xy_to_XY('x,'y, 'a,'b,'c,'d,'e,'f)); \
# GP-Test  ( quad_X('x,'y, 'a,'b,'c,'d,'e,'f)^2 \
# GP-Test  - quad_D('a,'b,'c,'d,'e,'f)*quad_Y('x,'y, 'a,'b,'c,'d,'e,'f)^2 \
# GP-Test  - quad_N('a,'b,'c,'d,'e,'f) \
# GP-Test  ) / (16*'c*'a^2 - 4*'b^2*'a) == \
# GP-Test  'a*x^2 + 'b*'x*'y + 'c*'y^2 + 'd*'x + 'e*'y + 'f
#
# 'n^2 - 6*'n*'m + 'm^2 + 15*'n + 15*'m - 16
# GP-Test  quad_D(1,-6,1,15,15,-16) == 32   \\ necessary odd prime factors 4*n+1
# GP-Test  quad_N(1,-6,1,15,15,-16) == 5152
# GP-Test  5152 == 2^5 * 7 * 23
# X^2 - 32*Y^2 = 5152
# q=Qfb(1,0,-32)
# qfbred(q)
# qfbredsl2(q) == [ Qfb(1,10,-7), [-1,-5; 0,-1] ]
# Mat(Qfb(1,0,32))
# Mat(Qfb(1,10,-7))
# Mat(Qfb(1,10,-7)) * [-1,-5; 0,-1]
# [-1,-5; 0,-1] * Mat(Qfb(1,0,32))
# Mat(Qfb(1,0,32)) * [-1,-5; 0,-1]
# my(n=5152,d=poldisc(q)); print("d="d" q="q); \
# for(h=0,2*n, if((h^2-d)%(4*n)==0, \
#     my(l=(h^2-d)/(4*n)); l==floor(l)||error(); \
#     my(nhl=Qfb(n,h,l)); \
#     if(qfbred(nhl)==qfbred(q), \
#        print("h="h" l="l))));
#
# q=Qfb(1,10,-7)
# poldisc(q)
# qfbsolve(q,5152)
# qfbsolve(q,2)
# qfeval(q,[-15,1])
# qfeval(q,[20016,19441])
#
# GP-DEFINE  quad_XY_to_xy(X,Y, a,b,c,d,e,f) = \
# GP-DEFINE    matsolve([0, quad_D(a,b,c,d,e,f); \
# GP-DEFINE             2*a,b], [X-quad_E(a,b,c,d,e,f); Y-d]);
# GP-Test  quad_XY_to_xy(-15,1, 1,-6,1,15,15,-16) ==[ 91/32; 105/32]
# GP-Test  quad_xy_to_XY(91/32, 105/32, 1,-6,1,15,15,-16) == [-15;1]
# bistar_W_diff(-265/8, -209/24)
# type(q)

# GP-Test  quad_X(10,6, 1,-6,1,15,15,-16) == 72
# GP-Test  quad_Y(10,6, 1,-6,1,15,15,-16) == -1
# GP-Test  72^2 - 32*(-1)^2 == 5152

# GP-Test  quad_X(11,6, 1,-6,1,15,15,-16) == 72
# GP-Test  quad_Y(11,6, 1,-6,1,15,15,-16) == 1
# GP-Test  72^2 - 32*(1)^2 == 5152

# GP-Test  quad_X(39,10, 1,-6,1,15,15,-16) == 200
# GP-Test  quad_Y(39,10, 1,-6,1,15,15,-16) == 33
# GP-Test  200^2 - 32*(33)^2 == 5152

# GP-Test  5152 % 16 == 0
# X^2 - 32*Y^2 = 5152


# Qfb(1,2,3).disc
# Qfb(1,1,-3).disc


{
  # N=4 star  
  # (1+2*2)/3 == 5/3

  require Graph::Maker::Star;
  require Graph::Maker::BiStar;
  # my $graph = Graph::Maker->new('bi_star', N=>3, M=>2, undirected=>1);
  my $graph = Graph::Maker->new('star', N=>4, undirected=>1);
  foreach my $u (sort $graph->vertices) {
    foreach my $v (sort $graph->vertices) {
      my $a = $graph->average_path_length($u,$v);
      my $l = $graph->path_length($u,$v);
      print "$u $v  a=",$a//'undef'," l=",$l//'undef',"\n";
    }
  }
  print "all ",$graph->average_path_length,"\n";
  foreach my $u (sort $graph->vertices) {
    my $a = $graph->average_path_length($u,undef);
    print "from $u  a=",$a//'undef',"\n";
  }
  foreach my $u (sort $graph->vertices) {
    my $a = $graph->average_path_length(undef,$u);
    print "to $u  a=",$a//'undef',"\n";
  }
  exit 0;
}
  
