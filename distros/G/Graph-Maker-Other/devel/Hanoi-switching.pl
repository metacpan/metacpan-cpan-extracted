#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017, 2020, 2021 Kevin Ryde
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
use Math::Complex 'pi';
use Graph::Maker::Hanoi;

use FindBin;
use lib "$FindBin::Bin/lib";
use MyGraphs;
use Graph::Maker::HanoiSwitching;
$|=1;

# uncomment this to run the ### lines
# use Smart::Comments;


# Sandi Klavzar, Uros Milutinovic, "Graphs S(n,k) and a Variant of the Tower
# of Hanoi Problem",



{
  # isomorphic to plain

  #       plain, disc on spindle             switching
  #                  0                                      0
  #                 / \                                    / \   
  #                1---2                                  1---2  
  #               /     \                                /     \
  #             21       12                            10       20
  #             / \     / \                            / \     / \
  #           22--20--10---11                        11--12--21---22
  #           /             \                        /             \
  #         122             211                    100             200
  #         / \             / \                    / \             / \
  #       120--121        212--210               101--102        210--212
  #       /     \         /     \                /     \         /     \
  #     110     101     202     220            110     120     220     202
  #     / \     / \     / \     / \            / \     / \     / \     / \
  #   111-112-102-100-200-201-221-222        111-112-121-122-211-212-221-222
  #   /                             \        /                             \
  # 2111                           1222    1000                           2000
  #
  # not in OEIS: 0,1,2, 21,22,20, 12,10,11, 122,120,121, 110,111,112, 101,102,100
  # not in OEIS: 0, 1, 2, 7,8,6, 5,3,4, 17,15,16, 12,13,14, 10,11,9

  # GP-DEFINE  to_ternary(n)=fromdigits(digits(n,3))*sign(n);
  # GP-DEFINE  onetwo_evens(n) = {
  # GP-DEFINE    my(v=digits(n,3));
  # GP-DEFINE    forstep(i=#v,1,-2, v[i]=-v[i]%3);
  # GP-DEFINE    fromdigits(v,3);
  # GP-DEFINE  }
  # vector(20,n, onetwo_evens(n))
  # not in OEIS: 2, 1, 3, 5, 4, 6, 8, 7, 18, 20, 19, 21, 23, 22, 24, 26, 25, 9, 11, 10

  # GP-DEFINE  onetwo_odds(n) = {
  # GP-DEFINE    my(v=digits(n,3));
  # GP-DEFINE    forstep(i=#v-1,1,-2, v[i]=-v[i]%3);
  # GP-DEFINE    fromdigits(v,3);
  # GP-DEFINE  }
  # vector(20,n, onetwo_odds(n))
  # not in OEIS: 1, 2, 6, 7, 8, 3, 4, 5, 9, 10, 11, 15, 16, 17, 12, 13, 14, 18, 19, 20

  # GP-DEFINE  onetwo_all(n) = {
  # GP-DEFINE    my(v=digits(n,3));
  # GP-DEFINE    for(i=1,#v, v[i]=-v[i]%3);
  # GP-DEFINE    fromdigits(v,3);
  # GP-DEFINE  }
  # vector(20,n, onetwo_all(n))
  # A004488 Tersum n + n.
  # GP-Test  vector(1000,n, onetwo_all(n)) == \
  # GP-Test  vector(1000,n, onetwo_evens(onetwo_odds(n)))

  # GP-DEFINE  rot(n) = {
  # GP-DEFINE    my(v=digits(n,3), rot=0);
  # GP-DEFINE    for(i=1,#v, [v[i],rot] = [(v[i]+rot)%3, rot-v[i]]);
  # GP-DEFINE    fromdigits(v,3);
  # GP-DEFINE  }
  # vector(20,n, rot(n))
  # not in OEIS: 1, 2, 5, 3, 4, 7, 8, 6, 17, 15, 16, 10, 11, 9, 12, 13, 14, 22, 23, 21
  # GP-Test  vector(18,n,n--; rot(onetwo_odds(n))) == \
  # GP-Test    [0, 1, 2, 7,8,6, 5,3,4, 17,15,16, 12,13,14, 10,11,9]
  # vector(18,n,n--; to_ternary(rot(n)))
  # not in OEIS: 1, 2, 12, 10, 11, 21, 22, 20, 122, 120, 121, 101, 102, 100, 110, 111, 112
  # GP-DEFINE  ternary_diffs(x,y) = \
  # GP-DEFINE    my(ret=0); while(x||y, ret+=(x%3!=y%3); x\=3;y\=3); ret;
  # for(n=9,27, printf("%4d  %d\n", to_ternary(rot(n)), ternary_diffs(rot(n),rot(n-1))))

  # GP-DEFINE  plusrot(n) = {
  # GP-DEFINE    my(v=digits(n,3), rot=0);
  # GP-DEFINE    for(i=1,#v, [v[i],rot] = [(v[i]+rot)%3, rot+v[i]]);
  # GP-DEFINE    fromdigits(v,3);
  # GP-DEFINE  }
  # vector(20,n, plusrot(n))
  # A105529 ternary modular UnGray

  sub perm {
    my ($n) = @_;
    my @v = split //, cnv($n,10,3);
    ### split to: @v

    my $rot = 0;
    my $flip = $#v % 2;
    foreach (@v) {
      ### at: "rot=$rot flip=$flip"
      if ($_ && $flip) { $_ ^= 3; }  # 1 <-> 2 flip odds
      my $new = ($_ + $rot) % 3;
      $rot -= $_;
      $_ = $new;
    }

    $n = join('',@v);
    ### @v
    return cnv($n,3,10);
  }
  foreach my $n (0..27) {
    my $p = perm($n);
    my $q = perm($p);
    my $r = perm($q);
    my $s = perm($r);
    printf "%2d %4d -> %2d %4d  -> %2d %2d %2d\n", $n, cnv($n,10,3), $p, cnv($p,10,3), $q, $r, $s;
  }
  exit 0;

  my $discs = 4;
  my $graph = Graph::Maker->new('hanoi_switching',
                                discs => $discs,
                                spindles => 3,
                                vertex_names => 'digits',
                                undirected => 1);
  Hanoi_switching_layout($graph, 3);
  MyGraphs::Graph_view($graph, scale => 16 / 2**$discs);

  exit 0;
}

{
  my @graphs;
  foreach my $discs (3) {
    my $spindles = 4;
    my $plain = Graph::Maker->new('hanoi',
                                  discs => $discs,
                                  spindles => $spindles,
                                  vertex_names => 'digits',
                                  undirected => 1);
    push @graphs, $plain;
    {
      my @vertices = $plain->vertices;
      my $num_vertices = scalar(@vertices);
      my $num_edges = $plain->edges;
      print "plain    $num_vertices vertices $num_edges edges\n";
    }

    my $graph = Graph::Maker->new('hanoi_switching',
                                  discs => $discs,
                                  spindles => $spindles,
                                  # vertex_names => 'digits',
                                  undirected => 1);
    Hanoi_switching_layout($graph, $spindles);
    push @graphs, $graph;

    # if ($spindles == 3) {
    #   Hanoi3_layout($plain, $discs);
    #   # Hanoi3_layout($graph, $discs);
    # }
    my @vertices = $graph->vertices;
    my $num_vertices = scalar(@vertices);
    my $num_edges = $graph->edges;
    print "switching $num_vertices vertices $num_edges edges\n";

    if ($discs <= 4) {
      my $len = $graph->path_length(min(@vertices), max(@vertices)) // 'none';
      print "  solution length $len\n";
      my $diameter = $graph->diameter || -1;
      print "  $num_vertices vertices $num_edges edges  diameter $diameter\n";
    }
    print "\n";
    MyGraphs::Graph_view($graph, scale => 16 / 2**$discs);
  }
  # MyGraphs::Graph_view($plain, scale => 16 / 2**$discs);
  # MyGraphs::Graph_print_tikz($graph);
  print "searches:\n";
  MyGraphs::hog_searches_html(@graphs);
  # MyGraphs::hog_upload_html($graphs[0]);
  exit 0;

  # for 3 spindles
  sub HanoiExchange3_layout {
    my ($graph,$N) = @_;
    $graph->set_graph_attribute('is_xy_triangular', 1);
    my $from_base = (min($graph->vertices) =~ /^00/ ? 3 : 10);
    foreach my $v (sort {$a<=>$b} $graph->vertices) {
      my $str = cnv($v,$from_base,3);
      $str = sprintf '%0*s', $N, $str;
      my $x = 0;
      my $y = 0;
      my @digits = reverse split //, $str;   # low to high
      foreach my $i (reverse 0 .. $#digits) {  # high to low
        my $d = $digits[$i];
        ### $d
        if ($d == 1) { $x -= 1<<$i; }
        if ($d == 2) { $x += 1<<$i; }
        if ($d) { $y -= 1<<$i; }
      }
      MyGraphs::Graph_set_xy_points($graph, $v => [$x,$y]);
    }
  }
}


sub Hanoi3_layout {
  my ($graph,$N) = @_;
  $graph->set_graph_attribute('is_xy_triangular', 1);
  foreach my $v (sort {$a<=>$b} $graph->vertices) {
    my $str = cnv($v,3,3);
    $str = sprintf '%0*s', $N, $str;
    my $x = 0;
    my $y = 0;
    my @digits = reverse split //, $str;   # low to high
    my $rot = 0;
    # every second digit low to high
    for (my $i = 0; $i <= $#digits; $i += 2) {
      if ($digits[$i]) { $digits[$i] ^= 3; }   # 1 <-> 2 flip
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
sub Hanoi_switching_layout {
  my ($graph, $spindles) = @_;
  my $w = Math::Complex->emake(1, 2*pi/$spindles);
  my $wsqrt = Math::Complex->emake(1, pi/$spindles/2);
  my $scale = ($spindles <= 4 ? 2
               : $spindles == 5 ? 2.5
               : 4);
  my $from_base = (min($graph->vertices) =~ /^00/ ? 3 : 10);
  foreach my $v (sort {$a<=>$b} $graph->vertices) {
    my $str = cnv($v,$from_base,$spindles);
    $str = sprintf '%0*s', $spindles, $str;
    my @digits = reverse split //, $str;   # low to high
    my $z = Math::Complex->new(0);
    foreach my $i (0 .. $#digits) {
      $z += $w**$digits[$i] * $scale**$i;
    }
#    $z /= -$wsqrt;
    $z *= Math::Complex->new(0,1);
    MyGraphs::Graph_set_xy_points($graph, $v => [$z->Re, $z->Im]);
  }
}
