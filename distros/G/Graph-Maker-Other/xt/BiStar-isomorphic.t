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

use strict;
use 5.004;
use Test;
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;
use Graph::Maker::Star;
use Graph::Maker::BiStar;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use lib 'devel/lib';
use MyGraphs;

plan tests => 96;


sub make_star {
  my %params = @_;
  my $graph = Graph::Maker->new('star', %params);
  # fix for Graph::Maker::Star version 0.01 makes empty for 1-vertex
  if ($params{'N'}==1 && $graph->vertices==0) { $graph->add_vertex(1); }
  return $graph;
}

#------------------------------------------------------------------------------

# bistar_W(n,m) = n--; m--; n + 2*n*(n-1)/2 + 2*n + 3*n*m \
#                         + 1 + 2*m \
#                         + m + 2*m*(m-1)/2;
# bistar_W(n,m) = (n+m)^2 + (n+1)*(m+2) - 5*n - 4*m;
# bistar_W(n,m) = (n+m)*(n+m-3) + n*m + 2;
# bistar_W('n,'m)
# bistar_W(10,6) == 270
# bistar_W(11,6) == 306
# 306/bistar_pairs(11,6)/3 == 3/4
# bistar_pairs(n,m) = (n+m)*(n+m-1)/2;
# diameter=3
# matrix(16,16,n,m, floor(bistar_W(n,m) / bistar_pairs(n,m) / 3 *1000))
# bistar_W(n,m) / bistar_pairs(n,m) / 3  = 3/4
# 4*bistar_W(n,m) = 9*bistar_pairs(n,m)
# 4*bistar_W(n,m) - 9*bistar_pairs(n,m) == \
#   -1/2*n^2 + 3*m*n - 15/2*n + -1/2*m^2 - 15/2*m + 8
# 2*(4*bistar_W(n,m) - 9*bistar_pairs(n,m)) == \
#   -n^2 + 6*m*n - m^2 - 15*n - 15*m + 16
# bistar_W_diff(n,m) = -n^2 + 6*m*n - m^2 - 15*n - 15*m + 16;
# my(len=10000);for(n=1,len,for(m=1,n, my(d=bistar_W_diff(n,m)); if(d==0,print(n","m" = "n+m); if(d>0,break()))));
#
# my(a='a,b='b); -(n+a)^2 + 6*(m+b)*(n+a) - (m+b)^2 - 15*(n+a) - 15*(m+b) + 16
#  6*a - 2*b = 15
# -2*a + 6*b = 15
# [6,-2;-2,6]^-1*[15;15]
# my(a=15/4,b=15/4); -(n+a)^2 + 6*(m+b)*(n+a) - (m+b)^2 - 15*(n+a) - 15*(m+b) + 16
# 4*n^2 - 24*m*n + 4*m^2 = -161
# 24-4*4*4 == -40  \\ positive definite

sub BiStar_Wiener {
  my ($N,$M) = @_;
  return ($N+$M)*($N+$M-3) + $N*$M + 2
    + ($M==0 ? $N-1 : 0)
    + ($N==0 ? $M-1 : 0);
}
{
  foreach my $N (0 .. 5) {
    foreach my $M (0 .. $N) {
      my $bistar = Graph::Maker->new('bi_star', N=>$N, M=>$M, undirected=>1);
      my $W_graph = MyGraphs::Graph_Wiener_index($bistar);

      my $W_formula = BiStar_Wiener($N,$M);
      ok ($W_formula, $W_graph, "BiStar Wiener N=$N, M=$M");
    }
  }
}

sub Star_Wiener {
  my ($N) = @_;
  return ($N-1)**2 + ($N==0 ? -1 : 0);
}
{
  foreach my $N (0 .. 5) {
    my $star   = make_star(N=>$N, undirected=>1);
    my $W_graph = MyGraphs::Graph_Wiener_index($star);

    my $W_formula = Star_Wiener($N);
    ok ($W_formula, $W_graph, "Star Wiener N=$N");
  }
}

#------------------------------------------------------------------------------

sub BiStar_diameter {
  my ($N,$M) = @_;
  return ($N>=2) + ($M>=2) + ($N>=3 || $M>=3 || ($N>=1&&$M>=1));
}
{
  foreach my $N (0 .. 5) {
    foreach my $M (0 .. 5) {
      my $graph = Graph::Maker->new('bi_star', N=>$N, M=>$M, undirected=>1);
      my $d_graph = $graph->diameter || 0;

      my $d_formula = BiStar_diameter($N,$M);
      ok ($d_formula, $d_graph, "BiStar diameter N=$N, M=$M");
    }
  }
}

#------------------------------------------------------------------------------
# N=1 or M=1 or N=0 or M=0 same as star N+M

{
  foreach my $N (0, 1) {
    foreach my $M (0 .. 4) {
      foreach my $swap (0,1) {
        my $N = $N;
        my $M = $M;
        if ($swap) { ($N,$M) = ($M,$N); }

        my $star   = make_star(N=>$N+$M, undirected=>1);

        my $bistar = Graph::Maker->new('bi_star', N=>$N, M=>$M, undirected=>1);
        # MyGraphs::Graph_view($star);
        # MyGraphs::Graph_view($bistar);

        ok (!! MyGraphs::Graph_is_isomorphic($bistar, $star),
            1,
            "N=$N, M=$M");
      }
    }
  }
}

#------------------------------------------------------------------------------
# N,M swap is isomorphic

{
  foreach my $undirected (0,1) {
    foreach my $N (0, 4) {
      foreach my $M (0 .. $N) {
        my $bistar1 = Graph::Maker->new('bi_star', N=>$N, M=>$M,
                                        undirected=>$undirected);
        my $bistar2 = Graph::Maker->new('bi_star', N=>$M, M=>$N,
                                        undirected=>$undirected);

        ok (!! MyGraphs::Graph_is_isomorphic($bistar1, $bistar2),
            1,
            "N=$N, M=$M");
      }
    }
  }
}


#------------------------------------------------------------------------------
# POD HOG Shown

{
  my %shown = ('2,2' => 1,
               '3,2' => 1,
               '3,3' => 1,
               '4,2' => 1,
               '4,3' => 1,
               '4,4' => 1,
               '5,2' => 1,
               '5,4' => 1,
               '5,5' => 1,
               '6,2' => 1,
               '6,5' => 1,
               '6,6' => 1,
               '7,2' => 1,
               '7,6' => 1,
               '7,7' => 1,
               '8,2' => 1,
               '8,7' => 1,
               '9,2' => 1,
               '10,2' => 1,
               '10,6' => 1,
              );
  my $extras = 0;
  my %seen;
  foreach my $N (3 .. 25) {
    foreach my $M (3 .. $N) {
      my $graph = Graph::Maker->new('bi_star', undirected => 1,
                                    N => $N, M => $M);
      my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
      $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
      next if $seen{$g6_str}++;
      next if $shown{"$N,$M"};
      if (MyGraphs::hog_grep($g6_str)) {
        MyTestHelpers::diag ("HOG N=$N,M=$M not shown in POD");
        MyTestHelpers::diag ($g6_str);
        MyGraphs::Graph_view($graph);
        $extras++
      }
    }
  }
  ok ($extras, 0);
}


#------------------------------------------------------------------------------
exit 0;
