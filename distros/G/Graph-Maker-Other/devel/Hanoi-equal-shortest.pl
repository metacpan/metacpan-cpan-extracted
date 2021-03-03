#!/usr/bin/perl -w

# Copyright 2020, 2021 Kevin Ryde
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
use List::Util 'min','max','sum';
use Math::BaseCnv 'cnv';
use Math::Trig 'pi';
use Graph::Maker::Hanoi;

use FindBin;
use lib "$FindBin::Bin/lib";
use MyGraphs;
$|=1;

# uncomment this to run the ### lines
# use Smart::Comments;


# Hanoi graph vertex pairs with two shortest paths
#
# Andreas M. Hinz, Sandi Klavzar, Uros Milutinovic, Daniele Parisse, and
# Ciril Petr, "Metric Properties of the Tower of Hanoi graphs and Stern's
# Diatomic Sequence", European Journal of Combinatorics, volume 26, 2005,
# pages 693-708.  Proposition 3.9 x_n = graph N=n+1.


{
  my $N = 3;
  my $graph = Graph::Maker->new('hanoi',
                                discs => $N,
                                spindles => 3,
                                undirected => 1,
                               );
  my $total = 0;
  my %highlight = (1 => 1,
                   3 => 1,
                   7 => 1);

  my @histogram;
  foreach my $from (sort {$a<=>$b} $graph->vertices) {
    my $hash = SSSP_shortest_count_hash($graph,$from);
    my @to = sort {$a<=>$b} grep {$hash->{$_}>=2} keys %$hash;
    next unless @to;
    my $highlight = $highlight{$from} ? ' ***' : '';
    print "$from to ",join(',',@to),"$highlight\n";
    $total += scalar(@to);
    $histogram[scalar(@to)]++;
  }
  print "total $total\n";
  print "histogram ",join(', ', map {$_//0} @histogram), "\n";

  print "top to right\n";
  my %letters = (2 => 'A',
                 5 => 'B',
                 4 => 'C', 3 => 'D', 6 => 'E',
                 10 => 'R',
                 9 => 'S', 11 => 'T', 14 => 'U',
                );
  foreach my $from (sort {$a<=>$b} $graph->vertices) {
    next unless $from < 9;
    my $hash = SSSP_shortest_count_hash($graph,$from);
    my @to = grep {$hash->{$_}>=2} keys %$hash;
    @to = grep {$_ >= 9 && $_ < 18} @to;
    next unless @to;
    @to = sort {$a<=>$b} @to;
    my $from_letter = $letters{$from} // $from;
    my @to_letters = map {$letters{$_} // $_} @to;
    print "$from to ",join(',',@to),
      "  $from_letter to ",join(',',@to_letters),"\n";

  }

  Hanoi3_layout($graph, $N);
  while (my ($number,$letter) = each %letters) {
    MyGraphs::Graph_rename_vertex($graph, $number, $letter);
  }
  MyGraphs::Graph_view($graph, scale => 2);
  exit 0;

  sub SSSP_shortest_count_hash {
    my ($graph, $v) = @_;
    my %shortest       = ($v => 0);
    my %shortest_count = ($v => 1);
    my @pending = ($v);
    my $distance = 0;
    while (@pending) {
      $distance++;
      my %new_pending;
      foreach my $from (@pending) {
        foreach my $to ($graph->neighbours($from)) {
          if (defined $shortest{$to} && $shortest{$to} < $distance) {
            next;
          }
          if (! defined $shortest{$to} || $distance < $shortest{$to}) {
            $shortest{$to} = $distance;
            $shortest_count{$to}++;
            $new_pending{$to} = 1;
          } else {
            $shortest_count{$to}++;
          }
        }
      }
      @pending = keys %new_pending;
    }
    return \%shortest_count;
  }
}


#-------------
# Other Setups

# GP-DEFINE  read("my-oeis.gp");

# GP-DEFINE  A107839_formula(n) = \
# GP-DEFINE    polcoeff(lift(Mod('x,'x^2-5*'x+2)^(n+1)),1);
# GP-DEFINE  A107839(n) = {
# GP-DEFINE    n>=0 || error("A107839() is for n>=0");
# GP-DEFINE    A107839_formula(n);
# GP-DEFINE  }
# GP-Test  my(v=OEIS_samples("A107839"));   /* OFFSET=0 */ \
# GP-Test    vector(#v,n,n--; A107839(n)) == v
# GP-Test  my(g=OEIS_bfile_gf("A107839")); \
# GP-Test    g==Polrev(vector(poldegree(g)+1,n,n--;A107839(n)))
# poldegree(OEIS_bfile_gf("A107839"))

# GP-DEFINE  A052984_formula(n) = vecsum(Vec(lift(Mod('x,'x^2-5*'x+2)^(n+1))));
# GP-DEFINE  A052984(n) = {
# GP-DEFINE    n>=0 || error("A052984() is for n>=0");
# GP-DEFINE    A052984_formula(n);
# GP-DEFINE  }
# GP-Test  my(v=OEIS_samples("A052984"));  /* OFFSET=0 */ \
# GP-Test    vector(#v,n,n--; A052984(n)) == v
# GP-Test  my(g=OEIS_bfile_gf("A052984")); \
# GP-Test    g==Polrev(vector(poldegree(g)+1,n,n--;A052984(n)))
# poldegree(OEIS_bfile_gf("A052984"))

# my(v=OEIS_samples("A052984")); \
# lindep([v, vector(#v,n,n--; polcoeff(lift(Mod('x,'x^2-5*'x+2)^(n+1)), 0)), \
#            vector(#v,n,n--; polcoeff(lift(Mod('x,'x^2-5*'x+2)^(n+1)), 1)) ])

# GP-DEFINE  sqrt17 = quadgen(17*4);
# GP-Test  sqrt17^2 == 17

#-------------
# a(n) = New

# GP-DEFINE  P = (5 + sqrt17)/2;
# GP-DEFINE  PM_poly(x) = x^2 - 5*x + 2;
# GP-Test  PM_poly(P) == 0
# GP-Test  PM_poly(x) == ( (2*x-5)^2 - 17 )/4
# GP-Test  poldisc(PM_poly(x)) == 17
# GP-Test  subst( (2*x-5)^2 - 17, x, P ) == 0
# (5 + sqrt(17))/2
# 4.5615528128088 = A082486
# GP-Test  my(v=OEIS_samples("A082486"), \
# GP-Test    x=fromdigits(v)/10^(#v-1)); \
# GP-Test    PM_poly(x) < 0
# GP-Test  my(v=OEIS_samples("A082486")); v[#v]++; \
# GP-Test    my(x=fromdigits(v)/10^(#v-1)); \
# GP-Test    PM_poly(x) > 0

# GP-DEFINE  M = (5 - sqrt17)/2;
# (5 - sqrt(17))/2
# not in OEIS: 0.438447187191
# GP-Test  PM_poly(M) == 0
# GP-Test  P*M == 2

#---
# GP-DEFINE  \\ powers formula by Hinz et al, x_n for n+1 discs
# GP-DEFINE  xx(n) = {
# GP-DEFINE    3/(4*sqrt17)
# GP-DEFINE    * ((sqrt17+1)*P^(n+1) - 2*3^(n+1)*sqrt17 + (sqrt17-1)*M^(n+1));
# GP-DEFINE  }
# GP-Test  /* in x_n, A107839 across one pair n within n+1 */ \
# GP-Test  vector(10,n,n--; (xx(n+1) - 3*xx(n))/6) == \
# GP-Test  vector(10,n,n--; A107839(n))
#
# GP-DEFINE  a_formula(n) = xx(n-1);
# GP-DEFINE  a(n) = {
# GP-DEFINE    n>=1 || error("a() is for n>=1");
# GP-DEFINE    xx(n-1);
# GP-DEFINE  }
# GP-Test  vector(4,n, a(n)) == [0, 6, 48, 282]
# GP-Test  a(1) == 0  /* unit triangle only */
# GP-Test  a(2) == 6
# vector(12,n,n--; a(n))

# GP-Test  my(want=[0,6,48,282,1476,7302,35016,164850,767340,3546366,16315248,74837802,342621396, \
# GP-Test    1566620022,7157423256,32682574050,149184117180,680813718126,3106475197248, \
# GP-Test    14173073072922,64659388538916,294971717255142,1345602571317096,6138257708432850 ]); \
# GP-Test    vector(#want,n, a(n)) == want
# GP-Test  my(want=OEIS_samples("A340309")); \
# GP-Test    vector(#want,n, a(n)) == want
# GP-Test  my(g=OEIS_bfile_gf("A340309")); \
# GP-Test    g==x*Polrev(vector(poldegree(g),n, a(n)))
# poldegree(OEIS_bfile_gf("A340309"))

# GP-Test  /* powers by Hinz et al (offset adjusted to a(n)) */ \
# GP-Test  vector(100,n, a(n)) == \
# GP-Test  vector(100,n, (3/(4*sqrt17)) \
# GP-Test    *( (sqrt17+1)*P^n - 2*sqrt17*3^n + (sqrt17-1)*M^n ) )
#
# GP-Test  /* sum by Hinz et al, adjusted so a(n) */ \
# GP-Test  vector(100,n, a(n)) == \
# GP-Test  vector(100,n, \
# GP-Test    (6/sqrt17) * sum(k=0,n-1, 3^k * (P^(n-1-k) - M^(n-1-k))))
#
# GP-Test  /* sum by Hinz et al, adjusted so a(n) */ \
# GP-Test  vector(100,n, a(n)) == \
# GP-Test  vector(100,n, \
# GP-Test    (6/sqrt17) * sum(k=0,n-1, 3^k * (P^(n-1-k) - M^(n-1-k))))
#
# GP-Test  /* subgraphs using A107839 = num between subgraphs */ \
# GP-Test  vector(100,n,n++; a(n)) == \
# GP-Test  vector(100,n,n++; 3*a(n-1) + 6*A107839(n-2))
#
# GP-Test  my(n=1); a(n)                   == 0
# GP-Test  my(n=1); 6*A107839_formula(n-2) == 0
# GP-Test  my(n=0); a_formula(n)           == 0
# GP-Test  my(n=0); 6*A107839_formula(n-2) == -3
# GP-Test  my(n=-1); a_formula(n)          == 1
# GP-Test  /* including reversing back earlier */ \
# GP-Test  vector(100,n,n-=20; a_formula(n)) == \
# GP-Test  vector(100,n,n-=20; 3*a_formula(n-1) + 6*A107839_formula(n-2))
# GP-Test  my(n=3); A107839_formula(n-2) == 5  /* my n=3 example */
#
# GP-Test  /* recurrence 8, -17, 6
# GP-Test  vector(100,n,n+=2; a(n)) == \
# GP-Test  vector(100,n,n+=2; 8*a(n-1) - 17*a(n-2) + 6*a(n-3))
# GP-Test  vector(100,n,n-=20; a_formula(n)) == \
# GP-Test  vector(100,n,n-=20; \
# GP-Test          8*a_formula(n-1) - 17*a_formula(n-2) + 6*a_formula(n-3))
#
# GP-Test  /* using A052984 for the Lucas sequence part */ \
# GP-Test  vector(100,n, a(n)) == \
# GP-Test  vector(100,n, (A052984(n) - 3^n)*3/2 )

# GP-DEFINE  g(x) = 6*x^2/((1 - 5*x + 2*x^2)*(1 - 3*x));
# GP-Test  my(limit=100); g(x) + O(x^limit) == sum(n=1,limit-1, a(n)*x^n)
# GP-Test  (1 - 5*x + 2*x^2) == polrecip(PM_poly(x))
#
# GP-Test  /* partial fractions */ \
# GP-Test  g(x) == (3/2 - 3*x)/(1 - 5*x + 2*x^2) - (3/2)/(1 - 3*x)

# GP-DEFINE  \\ compact polmod
# GP-DEFINE  my(p=Mod('x, 'x^2-5*'x+2)); a_compact(n) = (vecsum(Vec(lift(p^(n+1)))) - 3^n)*3/2;
# GP-Test  vector(100,n, a(n)) == \
# GP-Test  vector(100,n, a_compact(n))
# GP-Test  vector(100,n,n-=20; a_formula(n)) == \
# GP-Test  vector(100,n,n-=20; a_compact(n))

# GP-Test  6*5 + 6*3*1 == 48

# GP-Test  /* A107839 across one pair n when making n+1 */ \
# GP-Test  vector(10,n, (a(n+1) - 3*a(n))/6) == \
# GP-Test  vector(10,n, A107839(n-1))
# GP-Test  vector(10,n, a(n+1)) == \
# GP-Test  vector(10,n, 6*A107839(n-1) + 3*a(n))

# vector(12,n,n--; (a(n) - 3*a(n-1))/6)
# OEIS_recurrence_guess(vector(120,n,n--; a(n)))
# recurrence_guess(%)


#------------------------------------------------------------------------------

# Put x,y locations as vertex attributes.
sub Hanoi3_layout {
  my ($graph,$N) = @_;
  $graph->set_graph_attribute('is_xy_triangular', 1);
  foreach my $v (sort {$a<=>$b} $graph->vertices) {
    my $str = cnv($v,10,3);
    $str = sprintf '%0*s', $N, $str;
    my $x = 0;
    my $y = 0;
    my @digits = reverse split //, $str;   # low to high
    my $rot = 0;
    for (my $i = 0; $i <= $#digits; $i += 2) {  # low to high
      if ($digits[$i]) { $digits[$i] ^= 3; }
    }
    foreach my $i (reverse 0 .. $#digits) {  # high to low
      my $d = ($digits[$i] + $rot) % 3;
      ### $d
      if ($d == 1) { $x -= 1<<$i; }
      if ($d == 2) { $x += 1<<$i; }
      if ($d) { $y -= 1<<$i; }
      if ($digits[$i] == 2) { $rot++; }
      if ($digits[$i] == 1) { $rot--; }
    }
    MyGraphs::Graph_set_xy_points($graph, $v => [$x,$y]);
  }
}
