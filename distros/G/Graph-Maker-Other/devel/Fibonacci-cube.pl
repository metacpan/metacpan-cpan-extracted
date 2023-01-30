#!/usr/bin/perl -w

# Copyright 2021, 2022 Kevin Ryde
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

use 5.010;
use strict;
use List::Util 'min','max','sum';

use FindBin;
use lib "$FindBin::Bin/lib";
use MyGraphs;
$|=1;

use lib::abs $FindBin::Bin;
use Graph::Maker::FibonacciCube;

# uncomment this to run the ### lines
use Smart::Comments;

{
  # Fibonacci Cube Wiener Index
  # A238419 a(n) = the Wiener index of the Fibonacci cube G_n.
  # recurrence_guess(OEIS_data("A238419"))
  #  0, 1, 8, 36, 164, 694, 2792, 11008, 42484, 161395

  # S. Klavzar, M. Mollard, Wiener index and Hosoya Polynomial
  # of Fibonacci and Lucas cubes, MATCH Commun.  Math.  Comput.
  # Chem., 68, 2012, 311-324.
  # http://match.pmf.kg.ac.rs/electronic_versions/Match68/n1/match68n1_311-324.pdf

  #         010
  #          |
  #         000
  #        /   \
  #      001   100
  #        \   /
  #         101
  # 1+2+2+3 + 1+1+2 + 1+2 + 1 == 16

  # 16,54,176,548,1667,4968,14592,42348


  my @graphs;
  foreach my $N (3 .. 10) {
    my $graph = Graph::Maker->new('Fibonacci_cube',
                                  N => $N,
                                  undirected => 1,
                                 );
    my $num_vertices = $graph->vertices;
    my $num_edges = $graph->edges;
    my $W = MyGraphs::Graph_Wiener_index($graph);
    print "N=$N $num_vertices vertices $num_edges edges  W=$W\n";
    push @graphs, $graph;
    if ($N==4) { MyGraphs::Graph_view($graph); }
  }
  MyGraphs::hog_searches_html(@graphs);
  # MyGraphs::hog_upload_html($graphs[-1]);
  exit 0;
}

{
  my $str = '000';
  for (;;) {
    print "$str\n";
    $str = Graph::Maker::FibonacciCube::_fibbinary_next($str) // last;
  }
  exit 0;
}




__END__


#                E. Munarini, N. Z. Salvi, Structural and Enumerative
#                Properties of the Fibonacci Cubes, Discrete Math., 255,
#                2002, 317-324.
# 
#               a(n) = number of vertices of the Fibonacci cube Gamma(n-1)
#                having an even number of ones.  The Fibonacci cube Gamma(n)
#                can be defined as the graph whose vertices are the binary
#                strings of length n without two consecutive 1's and in which
#                two vertices are adjacent when their Hamming distance is
#                exactly 1.  Example: a(4) = 2; indeed, the Fibonacci cube
#                Gamma(3) has the five vertices 000, 010, 001, 100, 101, two
#                of which have an even number of ones.  See the E. Munarini et
#                al. reference, p. 323. 
# 

# A228702 Wiener index   generalized Q_n(111)
# recurrence_guess(OEIS_data("A228702")*484)
#   + gf (-4 + 13*x + 17*x^2)  /(1 + x + x^2 - x^3)
#   + gf (-4 - 90*x + 118*x^2) /(1 + x + x^2 - x^3)^2
#   + gf (-124 - 47*x - 17*x^2)/(1 - 3*x - x^2 - x^3)
#   + gf (132 + 176*x + 88*x^2)/(1 - 3*x - x^2 - x^3)^2
# 
# recurrence_guess(       vector(#v,n,n--; n*polcoeff(lift(p^n),0)))
#   + gf (-5 + x + x^2)   /(1 - x - x^2 - x^3)
#   + gf (5 - 6*x - 5*x^2)/(1 - x - x^2 - x^3)^2
# 
# recurrence_guess(       vector(#v,n,n--; n*polcoeff(lift((p^n)^2),0)))
#   + gf (-6 + 6*x)/(1 - 3*x - x^2 - x^3)
#   + gf (6 - 24*x + 14*x^2)/(1 - 3*x - x^2 - x^3)^2
# 
# recurrence_guess(       vector(#v,n,n--; n*polcoeff(lift(p^-n),0)))
#   + gf -3             /(1 + x + x^2 - x^3)
#   + gf (3 + 2*x + x^2)/(1 + x + x^2 - x^3)^2
# 
# /* From Klavzar and Rho paper, Theorem 2.4: */
#  T:=[n le 3 select Floor(n/3) else Self(n-1)+Self(n-2)+Self(n-3): n in [1..40]]; /* being T=A000073 */
# 
# [((268+67*n)*T[n+4]^2 
#  - (118+4*n)*T[n+4]*T[n+5]
#  - (50-14*n)*T[n+4]*T[n+6]
#  - (66+7*n)*T[n+5]^2
#  + (90+16*n)*T[n+5]*T[n+6]
#  - (18+6*n)*T[n+6]^2
#  )/484: n in [0..#T-6]];
# 
# 1/('a+'b*x+'c*x^2 + p*0)
# p=Mod(x,x^3-x^2-x-1);
# q=Mod(x,x^3+x^2+x-1);
# vector(20,n,n-=5; polcoeff(lift(p^n),2))
# vector(20,n,n-=5; polcoeff(lift(p^n),2))
# vector(20,n,n-=5; polcoeff(lift(q^n),2))
# vector(20,n,n-=5; polcoeff(lift(1/q^n),2))
# vector(20,n,n-=5; polcoeff(lift(1/q^(2*n)),2))
# vector(20,n,n-=5; polcoeff(lift(p^(2*n)),2))
# 
#        vector(#v,n,n--; polcoeff(lift(p^n),0)), \
#        vector(#v,n,n--; polcoeff(lift(p^n),1)), \
#        vector(#v,n,n--; polcoeff(lift(p^n),2)), \
#        vector(#v,n,n--; n*polcoeff(lift(p^n),0)), \
#        vector(#v,n,n--; n*polcoeff(lift(p^n),1)), \
#        vector(#v,n,n--; n*polcoeff(lift(p^n),2)), \
# 
# -1
# -8 + 60*x + 12*x^2
# - 27 + 43*x -9*x^2
# 8 + 41*x + 50*x^2
# 146 + 274*x 499**x^2
# recurrence_guess(v)
# recurrence_guess( vector(#v,n,n--; my(P=p^n,R=1/P); \
#                  -8*polcoeff(lift(R),0)\
#                  +60*polcoeff(lift(R),1)\
#                  +12*polcoeff(lift(R),2)\
#                  -27*n*polcoeff(lift(R),0)\
#                  +43*n*polcoeff(lift(R),1)\
#                  -9*n*polcoeff(lift(R),2)))
# 
# recurrence_guess( vector(#v,n,n--; my(P=p^n,Q=P^2); \
#                  -8*polcoeff(lift(Q),0)\
#                  +41*polcoeff(lift(Q),1)\
#                  +50*polcoeff(lift(Q),2)\
#                  +146*n*polcoeff(lift(Q),0)\
#                  +274*n*polcoeff(lift(Q),1)\
#                  +499*n*polcoeff(lift(Q),2)))
# 
# a(n) = my(P=p^n,R=1/P,Q=P^2); \
#  ( -8*polcoeff(lift(R),0)\
#   +60*polcoeff(lift(R),1)\
#   +12*polcoeff(lift(R),2)\
#   -27*n*polcoeff(lift(R),0)\
#   +43*n*polcoeff(lift(R),1)\
#   -9*n*polcoeff(lift(R),2) \
#                  +8*polcoeff(lift(Q),0)\
#                  +41*polcoeff(lift(Q),1)\
#                  +50*polcoeff(lift(Q),2)\
#                  +146*n*polcoeff(lift(Q),0)\
#                  +274*n*polcoeff(lift(Q),1)\
#                  +499*n*polcoeff(lift(Q),2) )/484;
# 
# vector(4,n,n--; lift(1/p^n))
# vector(4,n,n--; lift(p^n^2))
# my(p=Mod(x,x^3-x^2-x-1)); \
# a(n) = my(P=p^n); \
#  ( polcoeff(lift(( (-27*n-8) + (-52*n-48)*x + (43*n+60)*x^2)*P^-1),0)\
#   +polcoeff(lift(( (146*n+8) + (225*n+9)*x + (274*n+41)*x^2)*P^2),0) )/484;
# 
# my(p=Mod(x,x^3-x^2-x-1)); \
# a(n) = my(P=p^n); \
#  (  polcoeff(lift(( (43*n+60) - (52*n+48)*x - (27*n+8)*x^2)*P^-1),2)\
#   + polcoeff(lift(( (79*n+1) + (128*n+33)*x + (146*n+8)*x^2)*P^2),2) )/484;
# 
# my(p=Mod(x,x^3-x^2-x-1), A=-25+70*x-27*x^2, B=-40+68*x-8*x^2, C=79+128*x+146*x^2, D=1+33*x+8*x^2); \
# a(n) = my(P=p^n); polcoeff(lift((A*n+B)*P^-1 + (C*n+D)*P^2), 2)/484;
# 
# my(p=Mod(x,x^3-x^2-x-1), A=-2-122*x+70*x^2, B=32-116*x+68*x^2, C=67+97*x+128*x^2, D=7-24*x+33*x^2); \
# a(n) = my(P=p^n); vecsum(Vec(lift((A*n+B)/P + (C*n+D)*P^2)))/968;
# 
# OEIS_data("A228702")
# my(v=OEIS_data("A228702")); vector(#v,n,n--; a(n)) - v
# 
# Vec(Vecrev(x),3)
# v=Vec(484*2 * x * (1 + x^2) * (1 + 4*x + x^2) / ( (1 + x + x^2 - x^3)^2 * (1 - 3*x - x^2 - x^3)^2 ) + O(x^500)); #v
# for(o=-0,0,print(o"  "\
# lindep([v, \
#        vector(#v,n,n+=o; n*vecsum(Vec(lift(1/p^n)))), \
#        vector(#v,n,n+=o; n*vecsum(Vec(lift(x*1/p^n)))), \
#        vector(#v,n,n+=o; n*vecsum(Vec(lift(x^2*1/p^n)))), \
#        vector(#v,n,n+=o; vecsum(Vec(lift(1/p^n)))), \
#        vector(#v,n,n+=o; vecsum(Vec(lift(x*1/p^n)))), \
#        vector(#v,n,n+=o; vecsum(Vec(lift(x^2*1/p^n)))), \
#        \
#        vector(#v,n,n+=o; n*vecsum(Vec(lift((p^n)^2)))), \
#        vector(#v,n,n+=o; n*vecsum(Vec(lift(x*(p^n)^2)))), \
#        vector(#v,n,n+=o; n*vecsum(Vec(lift(x^2*(p^n)^2)))), \
#        vector(#v,n,n+=o; vecsum(Vec(lift((p^n)^2)))), \
#        vector(#v,n,n+=o; vecsum(Vec(lift(x*(p^n)^2)))), \
#        vector(#v,n,n+=o; vecsum(Vec(lift(x^2*(p^n)^2)))) \
#        ])))
# 
# for(o=-0,0,print(o"  "\
# lindep([v, \
#        vector(#v,n,n+=o; n*polcoeff(lift(1/p^n),2)), \
#        vector(#v,n,n+=o; n*polcoeff(lift(x*1/p^n),2)), \
#        vector(#v,n,n+=o; n*polcoeff(lift(x^2*1/p^n),2)), \
#        vector(#v,n,n+=o; polcoeff(lift(1/p^n),2)), \
#        vector(#v,n,n+=o; polcoeff(lift(x*1/p^n),2)), \
#        vector(#v,n,n+=o; polcoeff(lift(x^2*1/p^n),2)), \
#        \
#        vector(#v,n,n+=o; n*polcoeff(lift((p^n)^2),2)), \
#        vector(#v,n,n+=o; n*polcoeff(lift(x*(p^n)^2),2)), \
#        vector(#v,n,n+=o; n*polcoeff(lift(x^2*(p^n)^2),2)), \
#        vector(#v,n,n+=o; polcoeff(lift((p^n)^2),2)), \
#        vector(#v,n,n+=o; polcoeff(lift(x*(p^n)^2),2)), \
#        vector(#v,n,n+=o; polcoeff(lift(x^2*(p^n)^2),2)) \
#        ])))
# 
# for(o=-0,0,print(o"  "\
# lindep([v, \
#        vector(#v,n,n+=o; n*polcoeff(lift(1/p^n),0)), \
#        vector(#v,n,n+=o; polcoeff(lift(1/p^n),0)), \
#        vector(#v,n,n+=o; n*polcoeff(lift(x*1/p^n),0)), \
#        vector(#v,n,n+=o; polcoeff(lift(x*1/p^n),0)), \
#        vector(#v,n,n+=o; n*polcoeff(lift(x^2*1/p^n),0)), \
#        vector(#v,n,n+=o; polcoeff(lift(x^2*1/p^n),0)), \
#        \
#        vector(#v,n,n+=o; n*polcoeff(lift((p^n)^2),0)), \
#        vector(#v,n,n+=o; polcoeff(lift((p^n)^2),0)), \
#        vector(#v,n,n+=o; n*polcoeff(lift(x*(p^n)^2),0)), \
#        vector(#v,n,n+=o; polcoeff(lift(x*(p^n)^2),0)), \
#        vector(#v,n,n+=o; n*polcoeff(lift(x^2*(p^n)^2),0)), \
#        vector(#v,n,n+=o; polcoeff(lift(x^2*(p^n)^2),0)) \
#        ])))
# 
# for(o=-0,0,print(o"  "\
# lindep([v, \
#        vector(#v,n,n+=o; polcoeff(lift(1/p^n),0)), \
#        vector(#v,n,n+=o; polcoeff(lift(1/p^n),1)), \
#        vector(#v,n,n+=o; polcoeff(lift(1/p^n),2)), \
#        vector(#v,n,n+=o; n*polcoeff(lift(1/p^n),0)), \
#        vector(#v,n,n+=o; n*polcoeff(lift(1/p^n),1)), \
#        vector(#v,n,n+=o; n*polcoeff(lift(1/p^n),2)), \
#        \
#        vector(#v,n,n+=o; polcoeff(lift((p^n)^2),0)), \
#        vector(#v,n,n+=o; polcoeff(lift((p^n)^2),1)), \
#        vector(#v,n,n+=o; polcoeff(lift((p^n)^2),2)), \
#        vector(#v,n,n+=o; n*polcoeff(lift((p^n)^2),0)), \
#        vector(#v,n,n+=o; n*polcoeff(lift((p^n)^2),1)), \
#        vector(#v,n,n+=o; n*polcoeff(lift((p^n)^2),2)) \
#        ])))
# 
# lindep([vector(#v,n,n--; polcoeff(lift(p^-n),0)), \
#        vector(#v,n,n--; polcoeff(lift(p^-n),1)), \
#        vector(#v,n,n--; polcoeff(lift(p^-n),2)), \
#        vector(#v,n,n--; polcoeff(lift(p^n),0)), \
#        vector(#v,n,n--; polcoeff(lift(p^n),1)), \
#        vector(#v,n,n--; polcoeff(lift(p^n),2))])
# 
# %H <a href="/index/Rec#order_12">Index entries for linear recurrences with constant coefficients</a>, signature (4,2,0,-35,-32,-32,16,5,12,-2,0,-1).
# %F a(n) = 4*a(n-1) + 2*a(n-2) - 35*a(n-4) - 32*a(n-5) - 32*a(n-6) + 16*a(n-7) + 5*a(n-8) + 12*a(n-9) - 2*a(n-10) - a(n-12).
# 
#  as powers
#   + gf (-1/121 + 13/484*x + 17/484*x^2) /(1 + x + x^2 - x^3)
#   + gf (-1/121 - 45/242*x + 59/242*x^2) /(1 + x + x^2 - x^3)^2
#   + gf (-31/121 - 47/484*x - 17/484*x^2)/(1 - 3*x - x^2 - x^3)
#   + gf (3/11 + 4/11*x + 2/11*x^2)       /(1 - 3*x - x^2 - x^3)^2
# 
# Tribonacci                             x^2/(1 - x - x^2 - x^3)
# other A057597 a(n) = -a(n-1) - a(n-2) + a(n-3), a(0)=0, a(1)=0, a(2)=1.
# 
# Vec(1/(1 + x + x^2 - x^3) + O(x^100))
# 
# vector(20,n,n-=5; polcoeff(lift(p^n),2))
# 
# A000073(n)=([0, 1, 0; 0, 0, 1; 1, 1, 1]^n)[1, 3]
# 
# --
# A057597  negative index Tribonaccis
# A046738 Period of Fibonacci 3-step sequence A000073 mod n.  For positives.
# 
# %o (PARI) my(p=Mod(x,x^3+x^2+x-1)); a(n) = polcoeff(lift(p^n),2);
# my(v=OEIS_data("A057597")); vector(#v,n,n--; a(n)) == v  \\ OFFSET=0
# 
# vector(20,n,n-=5; a(-n))
# vector(20,n,n-=5; a(n))
# p=Mod(x,x^3+x^2+x-1);
# vector(20,n,n-=5; polcoeff(lift(p^n),2))
# [4, 2, 1, 1, 0, 0, 1, -1, 0, 2, -3, 1, 4, -8, 5, 7, -20, 18, 9, -47]
# 
# Mod(1,x^3+x^2+x-1)'
# 
# polrecip(1 + x + x^2 - x^3)

