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
use Math::Trig 'pi';
use Graph::Maker::Hanoi;

use FindBin;
use lib "$FindBin::Bin/lib";
use MyGraphs;
$|=1;

# uncomment this to run the ### lines
use Smart::Comments;





{
  # Hanoi spindles=3, any
  #   discs=2  https://hog.grinvin.org/ViewGraphInfo.action?id=21136
  #   discs=3  https://hog.grinvin.org/ViewGraphInfo.action?id=22740
  #   discs=4  https://hog.grinvin.org/ViewGraphInfo.action?id=35479
  #   discs=5  https://hog.grinvin.org/ViewGraphInfo.action?id=35481
  #
  # spindles=3, linear
  #   discs=2  https://hog.grinvin.org/ViewGraphInfo.action?id=414
  #            path-9
  #
  # spindles=4, any
  #   discs=2  https://hog.grinvin.org/ViewGraphInfo.action?id=22742
  #
  # spindles=4, cyclic
  #   discs=2  https://hog.grinvin.org/ViewGraphInfo.action?id=25141
  #
  # spindles=4, linear
  #   discs=2  https://hog.grinvin.org/ViewGraphInfo.action?id=25143
  #
  # spindles=4, star
  #   discs=2  https://hog.grinvin.org/ViewGraphInfo.action?id=21152
  #
  my @graphs;
  foreach my $N (4) {
    my $spindles = 3;
    my $graph = Graph::Maker->new('hanoi',
                                  discs => $N,
                                  spindles => $spindles,
                                  # adjacency => 'cyclic',
                                  vertex_names => 'digits',
                                  # adjacency => 'star',
                                  # adjacency => 'linear',
                                  undirected => 1,
                                 );
    if ($spindles==3) { Hanoi3_layout($graph,$N); }
    else { HanoiS_layout($graph,$N,$spindles); }
    MyGraphs::Graph_view($graph);
    push @graphs, $graph;
    my $num_vertices = $graph->vertices;
    my $num_edges = $graph->edges;
    print "  $num_vertices vertices $num_edges edges\n";
  }
  MyGraphs::hog_searches_html(@graphs);
  MyGraphs::hog_upload_html($graphs[-1]);
  exit 0;

  sub HanoiS_layout {
    my ($graph,$N,$spindles) = @_;
    foreach my $v ($graph->vertices) {
      my $str = cnv($v,10,$spindles);
      $str = sprintf '%0*s', $N, $str;
      my $x = 0;
      my $y = 0;
      my @digits = reverse split //, $str;   # low to high
      ### $v
      ### @digits
      my @size = (3, 10);
      my $rot = 1/4;
      my $sign = 1;
      foreach my $i (reverse 0 .. $#digits) {  # high to low
        my $a = $sign*$digits[$i] * 2*pi/$spindles + $rot*2*pi;
        $x += cos($a) * $size[$i];
        $y += sin($a) * $size[$i];
        $rot += $digits[$i]*0/5;
        $sign = $sign;
      }
      MyGraphs::Graph_set_xy_points($graph, $v => [$x,$y]);
    }
  }

  sub Hanoi3_layout {
    my ($graph,$N) = @_;
    $graph->set_graph_attribute('is_xy_triangular', 1);
    foreach my $v (sort {$a<=>$b} $graph->vertices) {
      my $str = cnv($v,10,10);
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
      MyGraphs::Graph_set_xy_points($graph, $v => [-$x,$y]);
    }
  }

}
{
  # permutations
  #                 0                                      0
  #                / \        ternary                     / \      ternary
  #               1---2    disc on spindle               1---2    geometric
  #              /     \                                /     \
  #            21       12                            10       20
  #            / \     / \                            / \     / \
  #          22--20--10---11                        11--12--21---22
  #          /             \                        /             \
  #        122             211
  #        / \             / \
  #     121--120        212--210
  #      /     \         /     \
  #    101     110     202     220
  #    / \     / \     / \     / \
  #  111-112-102-100-200-201-221-222
  # 
  #                 0                                     0      
  #                / \                                   / \     
  #               1---2                                 1---2    
  #              /     \                               /     \   
  #             7       5                             3       6  
  #            / \     / \                           / \     / \ 
  #           8---6---3---4                         4---5---7---8
  #
  # 0,1,2, 7,5, 8,6,3,4   
  # 0,1,2, 3,6, 4,5,7,8
  # 0,2,1, 6,3, 8,7,5,4  rev rows
  #
  # not in OEIS: 0,1,2, 7,8,6, 5,3,4    \\ geom -> discs
  # not in OEIS: 0,1,2, 7,8,6, 5,3,4    \\ discs -> geom
  # not in OEIS: 0,2,1, 5,3,4, 7,6,8    \\ mirror geom -> discs

  # A060583     A ternary code related to the Tower of Hanoi.
  #    0, 2, 1, 7, 6, 8, 5, 4, 3, 23, 22, 21, 18, 20, 19, 25, 24, 26, 16, 15,
  # A060587
  #    0, 2, 1, 8, 7, 6, 4, 3, 5, 24, 26, 25, 23, 22, 21, 19, 18, 20, 12, 14,

  my %map;
  @map{0,1,2, 21,12, 22,20,10,11} = (0,1,2, 10,20, 11,12,21,22);
  @map{0,1,2, 21,12, 22,20,10,11} = (0,2,1, 20,10, 22,21,12,11);
  my %dec;
  while (my ($x,$y) = each %map) {
    ### $x
    $x = cnv($x,3,10);
    $y = cnv($y,3,10);
    $dec{$x} = $y;
  }
  foreach my $i (0 .. 8) {
    print "$dec{$i},";
  }
  exit 0;
}
{
  # ascii print rows downwards from 0

  my $discs = 3;
  my $graph = Graph::Maker->new('hanoi', discs => $discs, undirected => 1);
  print $graph->get_graph_attribute('name'),"\n";
  print "$graph\n";

  # MyGraphs::Graph_view($graph);
  my @v = ($graph->has_vertex(0) ? 0 : '0'x$discs);
  my @seen;
  while (@v) {
    print join('  ', map {cnv($_,10,3)} @v),"\n";
    foreach my $v (@v) { $seen[$v] = 1; }

    @v = map {$graph->neighbours($_)} @v;
    # @v = map {sort {$a cmp $b} $graph->neighbours($_)} @v;
    ### @v
    @v = grep {! $seen[$_]} @v;
  }
  my $count = sum(map {$_//0} @seen);
  print "count $count vertices\n";
  exit 0;
}

{
  # discs=2 spindles=5 layout

  # w5 = exp(2*Pi*I/5)
  # big = 2.9
  # small = 1
  # gap = w5*(big + small*conj(w5)) - ( big    + small*w5 )
  # side = w5*small - small
  # arg(gap)
  # arg(side)
  # gap/side
  #
  # big = phi+1
  # small=1
  # mid = ( w5^3*(big + small*conj(w5))  +  ( big    + small*w5 ) )*w5
  # arg(mid)*180/Pi
  # solve(big=2,3, real(( w5^3*(big + small*conj(w5))  +  ( big    + small*w5 ) )*w5))
  # phi+1

  my $N = 2;
  my $spindles = 5;
  my $adjacency;
  $adjacency = 'linear';
  $adjacency = 'cyclic';
  $adjacency = 'any';
  my $graph = Graph::Maker->new('hanoi',
                                discs => $N,
                                spindles => $spindles,
                                adjacency => $adjacency,
                                undirected => 1,
                               );
  HanoiS_layout($graph,$N,$spindles);
  my $phi = (sqrt(5)+1)/2;

  my $s = ($adjacency eq 'any' ? 2 : 3);
  my $b = 7.854101966;
  my $place = sub {
    my ($v, $a1,$a2, $s) = @_;
    if (1 || $adjacency eq 'linear') { $a1 -=2; $a2 -=2; }
    $s //= 3;
    MyGraphs::Graph_set_xy_points
        ($graph, $v =>
         [ $b*cos($a1/5*2*pi + pi/2) + $s*cos($a2/5*2*pi + pi/2),
           $b*sin($a1/5*2*pi + pi/2) + $s*sin($a2/5*2*pi + pi/2) ]);
  };
  $place->(0, 0,0);
  $place->(1, 0,4);
  $place->(2, 0,2, $s);
  $place->(3, 0,3, $s);
  $place->(4, 0,1);

  $place->(5, 1,2);
  $place->(6, 1,1);
  $place->(7, 1,0);
  $place->(8, 1,3, $s);
  $place->(9, 1,4, $s);

  $place->(10, 2,0, $s);
  $place->(11, 2,3);
  $place->(12, 2,2);
  $place->(13, 2,1);
  $place->(14, 2,4, $s);

  $place->(15, 3,0, $s);
  $place->(16, 3,1, $s);
  $place->(17, 3,4);
  $place->(18, 3,3);
  $place->(19, 3,2);

  $place->(20, 4,3);
  $place->(21, 4,1, $s);
  $place->(22, 4,2, $s);
  $place->(23, 4,0);
  $place->(24, 4,4);


  MyGraphs::Graph_view($graph, scale => 1);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  my $diameter = $graph->diameter;
  print "  $num_vertices vertices $num_edges edges  diameter $diameter\n";
  MyGraphs::hog_searches_html($graph);
  MyGraphs::hog_upload_html($graph);

  exit 0;
}
{
  # 2 discs linear square layout
  # https://hog.grinvin.org/ViewGraphInfo.action?id=44071
  # https://hog.grinvin.org/ViewGraphInfo.action?id=44073
  my $N = 2;
  my $spindles = 6;
  my $adjacency = 'linear';
  my $graph = Graph::Maker->new('hanoi',
                                discs => $N,
                                spindles => $spindles,
                                adjacency => $adjacency,
                                undirected => 1,
                               );
  foreach my $x (0..$spindles-1) {
    foreach my $y (0..$spindles-1) {
      MyGraphs::Graph_set_xy_points ($graph, $y*$spindles+$x => [2*$x,2*$y ]);
    }
  }
  MyGraphs::Graph_view($graph, scale=>2);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  my $diameter = $graph->diameter;
  print "  $num_vertices vertices $num_edges edges  diameter $diameter\n";
  MyGraphs::hog_searches_html($graph);
  MyGraphs::hog_upload_html($graph);

  exit 0;
}


{
  # Stockmeyer linear 4 spindles
  exit 0;

  # GP-DEFINE  \\ upper bound
  # GP-DEFINE  R_4linear(n) = 3^n + n - 1;
  # GP-Test  vector(100,n, R_4linear(n)) == \
  # GP-Test  vector(100,n,  \
  # GP-Test     R_4linear(n-1) + 2 + (3^(n-1)-1)  + 1 + (3^(n-1)-1) )
  # vector(20,n, R_4linear(n))
  # A301571

  # A160002 optimal
  # 3,10,19,34,57,88
  # ~/OEIS/A160002.html
}
{
  # FSM for A055662 by bits
  my $transition = sub {
    my ($t, $prev, $c, $bit) = @_;
    if ($bit != $prev) {
      $t = ($t - (-1)**$c) % 3;
    } else {
      $c = 1-$c;
    }
    $prev = $bit;
    return ($t,$prev,$c);
  };
  my $tpc_to_state = sub {
    my ($t, $prev, $c) = @_;
    my $s = $t + 3*$prev + 6*$c;
    if ($s == 0) { $s += 12; }
    return $s;
  };
  my $state_to_tpc = sub {
    my ($state) = @_;
    my $t    = $state % 3; $state = int($state/3);
    my $prev = $state % 2; $state = int($state/2);
    my $c    = $state % 2;
    return ($t, $prev, $c);
  };

  require MyFSM;
  use lib '../dragon/tools';
  my %table;
  my %accepting;
  foreach my $state (1..12) {
    foreach my $bit (0,1) {
      my ($t,$prev,$c) = $state_to_tpc->($state);
      $accepting{$state} = $t;
      ($t,$prev,$c) = $transition->($t,$prev,$c, $bit);
      my $to = $tpc_to_state->($t,$prev,$c);
      $table{$state}->{$bit} = $to;
    }
  }
  my $fsm = MyFSM->new(table => \%table,
                       initial => '6',
                       accepting => \%accepting,
                       flow => 'east',
                      );
  $fsm->simplify (verbose => 1);
  # $fsm->view;

  require FLAT;
  require MyFLAT;
  my $f = FLAT::NFA->new;
  $f->add_states(13);
  foreach my $state (1..12) {
    foreach my $bit (0,1) {
      my ($t,$prev,$c) = $state_to_tpc->($state);
      ($t,$prev,$c) = $transition->($t,$prev,$c, $bit);
      my $to = $tpc_to_state->($t,$prev,$c);
      $f->add_transition($state,$to, $bit);
    }
  }
  foreach my $c (0,1) {
    my $state = $tpc_to_state->(0,0,$c);
    $f->set_starting($state);
    my ($t,$prev,$c) = $transition->(0,0,$c, 1);
    print "start $state   0,0,$c to $t,$prev,$c\n";
  }
  # $f->MyFLAT::view;

  foreach my $bit (0,1) {
    foreach my $state (1..12) {
      my ($t,$prev,$c) = $state_to_tpc->($state);
      if ($t==0) { print " "; }
      ($t,$prev,$c) = $transition->($t,$prev,$c, $bit);
      my $to = $tpc_to_state->($t,$prev,$c);
      print $to,",";
    }
    print "\n";
  }

  { my @table;
    foreach my $state (1..12) {
      foreach my $bit (0,1) {
        my ($t,$prev,$c) = $state_to_tpc->($state);
        ($t,$prev,$c) = $transition->($t,$prev,$c, $bit);
        my $to = $tpc_to_state->($t,$prev,$c);
        $table[2*$state-1+$bit] = 2*$to-1;
      }
    }
    shift @table;
    print join(',',@table),"\n";
  }
  {
    my $state2_to_tpc = sub {
      my ($state) = @_;
      my $t    = $state % 3; $state = int($state/6);
      my $prev = $state % 2; $state = int($state/2);
      my $c    = $state % 2;
      return ($t, $prev, $c);
    };
    my %tpc_to_state2;
    for (my $state = 1; $state <= 23; $state+=2) {
      my ($t,$prev,$c) = $state2_to_tpc->($state);
      if (exists $tpc_to_state2{$t,$prev,$c}) {
        die "duplicate $t, $prev, $c already $tpc_to_state2{$t,$prev,$c}";
      }
      $tpc_to_state2{$t,$prev,$c} = $state;
    }
    for (my $state = 1; $state <= 23; $state+=2) {
      foreach my $bit (0,1) {
        my ($t,$prev,$c) = $state2_to_tpc->($state);
        ($t,$prev,$c) = $transition->($t,$prev,$c, $bit);
        my $to = $tpc_to_state2{$t,$prev,$c} // die;
        print "$to,";
      }
      if ($state == 11) { print "\n"; }
    }
    print "\n";
    foreach my $c (0,1) {
      my $state = $tpc_to_state2{0,0,$c};
      print "start $state   0,0,$c\n";
    }
  }
  exit 0;
}

{
  # linear path length 0 to S^N-1

  #      discs = 1   2   3   4    5    6     7    8
  # spindles=3:  2,  8, 26, 80, 242, 728, 2186, 6560       = 3^n - 1
  # spindles=4:  3, 10, 19, 34,  57,  88,  123, 176          A160002
  # spindles=5
  # not in OEIS: 4, 12, 22, 34,  52,  70,   96
  # spindles=6
  # not in OEIS: 5, 14, 25, 38,  53,  72,
  # spindles=7
  # not in OEIS: 6, 16, 28, 42,  58,  76,
  #
  # column 3 disc, S spindles = 3*n + 1 except first 3 disc 3 spindles
  # 26, 19, 22, 25, 28, 31, 34, 37, 40, 43, 46, 49,

  foreach my $discs (4,
                     # 1 .. 6,
                    ) {
    # print "S=$spindles\n";
    foreach my $spindles (3 .. 20) {
      my $graph = Graph::Maker->new('hanoi',
                                    discs => $discs,
                                    spindles => $spindles,
                                    adjacency => 'linear',
                                    undirected => 1);
      my $from = 0;
      my $to = $spindles**$discs-1;
      $graph->has_vertex($from) or die "no from $from";
      $graph->has_vertex($to) or die "no to $to";
      my @path = $graph->SP_Dijkstra($from,$to);
      # print "\n",join(' ',@path),"\n";
      my $length = scalar(@path) - 1;
      # my $length = $graph->path_length($from, $to);
      # my $length = Graph_path_length_by_breath_first($graph, $from, $to);
      print "$length, ";
    }
    print "\n";
  }
  exit 0;
}

{
  # SierpinskiTriangle
  my $depth = 4;

  require Graph;
  require Math::PlanePath::SierpinskiTriangle;
  my $path = Math::PlanePath::SierpinskiTriangle->new;
  my $n_lo = $path->n_start;
  my $n_hi = $path->tree_depth_to_n_end($depth);
  my $graph = Graph->new (vertices => [ $n_lo .. $n_hi ],
                          edges => [ map { my $n = $_;
                                           map { [ $n, $_ ] }
                                             $path->tree_n_children($n)
                                           }
                                     $n_lo .. $n_hi ]);
  print "$graph\n";
  ### cyclic: $graph->is_cyclic
  ### acyclic: $graph->is_acyclic
  ### all_successors: $graph->all_successors($n_lo)
  ### neighbours: $graph->neighbours($n_lo)
  ### interior_vertices: $graph->interior_vertices
  ### exterior_vertices: $graph->exterior_vertices

  print "in_degree: ",join(',',map{$graph->in_degree($_)}$n_lo..$n_hi),"\n";
  print "out_degree:   ",join(',',map{$graph->out_degree($_)}$n_lo..$n_hi),"\n";
  print "num_children: ",join(',',map{$path->tree_n_num_children($_)}$n_lo..$n_hi),"\n";
  exit 0;
}

{
  # cyclic 4-spindles
  # back or forward
  # distance 000 to 222:  2,4,10,16,22,32,50,68

  # lower bound
  # l(n) = sum(i=1,n, 4*(i-1)+2);
  # vector(7,n, l(n))      \\ 2,8,18,32,50,72,98
  # vector(7,n, 2*n^2)

  # 2,8,18,36,66,120,210
  #
  # forward only, 2 discs is small 6 cycle + big 2 = 8
  # *A  B  *C  D

  foreach my $discs (1 .. 8) {
    my $linear = Graph::Maker->new('hanoi',
                                   discs => $discs,
                                   spindles => 4,
                                   adjacency => 'cyclic',
                                   undirected => 1);
    my $from = 0;                # 000...00 base 4
    my $to = (4**$discs-1)*2/3;  # 222...22 base 4
    my $to4 = cnv($to,10,4);
     my $length = $linear->path_length($from, $to);
    # my $length = Graph_path_length_by_breath_first($linear, $from, $to);
    print "to $to=[$to4]  $length\n";
  }
  exit 0;
}


{
  # tikz print

  my $graph = Graph::Maker->new('hanoi',
                                discs => 2,
                                spindles => 4,
                                adjacency => 'star',
                                undirected => 1,
                                vertex_names => 'digits',
                               );
  my @count;
  foreach my $v ($graph->vertices) {
    $count[$graph->degree($v)]++;
  }
  foreach my $degree (0 .. $#count) {
    if ($count[$degree]) {
      print "  % degree=$degree count $count[$degree]\n";
    }
  }
  foreach my $v (sort {$a<=>$b} $graph->vertices) {
    if ($graph->degree($v) == 3) {
      print "  % deg3  ",cnv($v,10,4),"\n";
    }
  }
  Graph_print_tikz($graph);
  exit 0;
}
{
  # Dudeney spindles=4 path length N=8 is 33, N=10 is 49

  foreach my $N (10,
                 8,
                 # 21,
                ) {
    print "N=$N\n";
    my $graph = Graph::Maker->new('hanoi',
                                  discs => $N,
                                  spindles => 4,
                                  undirected => 1);
    my $num_vertices = $graph->vertices;
    my $num_edges = $graph->edges;
    my $from = 0;
    my $to = 4**$N-1;
    print "  $num_vertices vertices $num_edges edges, from $from to $to\n";
    # my $m = $graph->path_length(0, 4**$N-1);
    my $m = Graph_path_length_by_breath_first($graph, $from, $to);
    print "  m=$m\n";
  }
  exit 0;

  sub Graph_path_length_by_breath_first {
    my ($graph, $from, $to) = @_;
    my $verbose = 0;
    my %seen = ($from => undef);
    my @vertices = ($from);
    my $count = 0;
    while (@vertices) {
      my @new_vertices;
      $count++;
      if ($verbose) {
        print "  $count  ",scalar(@vertices),"   ";
        foreach my $i (0 .. min(5, $#vertices)) {
          print cnv($vertices[$i],10,4),",";
        }
        print "\n";
      }

      foreach my $v (@vertices) {
        foreach my $n ($graph->neighbours($v)) {
          next if exists $seen{$n};
          if ($n eq $to) {
            if ($verbose) { print "  $v to $n = $to\n"; }
            return $count;
          }
          $seen{$n} = undef;
          push @new_vertices, $n;
        }
      }
      @vertices = @new_vertices;
    }
  }
}


{
  # Hanoi number of edges for spindles

  # spindles=4  0,6,36,168,720,2976,12096,48768
  #             2*A103897 = 2 * 3*2^(n-1)*(2^n-1) = 3*2^n*(2^n-1)
  # 4 x complete-4 sub-graphs = 4*6 = 24 edges
  # discs=2 for given small disc position big disc binomial(3,2)=3
  # from<->to so 4*6 + 4*3 = 36

  foreach my $spindles (2 .. 10) {
    my @values;
    foreach my $discs (0 .. 7) {
      my $graph = Graph::Maker->new('hanoi',
                                    discs => $discs,
                                    spindles => $spindles,
                                    undirected => 1);
      my $num_vertices = $graph->vertices;
      my $num_edges = $graph->edges;
      print "s=$spindles d=$discs vertices $num_vertices edges $num_edges\n";
      push @values, $num_edges;
      last if $num_edges >= 20000;
    }
    require Math::OEIS::Grep;
    Math::OEIS::Grep->search(array => \@values,
                             name => "spindles $spindles",
                             verbose=>1);
  }
  exit 0;
}

{
  # planar layout forcing GraphViz2

  #            0,0
  #        -1,-1  1,-1
  #   -2,-3           3,-2
  # -4,-3 -2,-3     2,-3 4,-3

  my $discs = 3;
  my $graph = Graph::Maker->new('hanoi', discs => $discs, undirected => 1);
  print $graph->get_graph_attribute('name'),"\n";

  my @vertex_to_xy = ([0,0]);
  foreach my $k (0 .. $discs-1) {
    my $pow = 3**$k;
    my $y_hi = 2**($k+1) - 1;
    my $y_offset = 2**$k - 1;
    my $x_offset = 2**$k;
    ### $y_hi
    ### $x_offset
    ### $y_offset

    # foreach my $v (0 .. $pow-1) {
    #   $vertex_to_xy[$v]->[1] -= $y_offset;
    # }

    foreach my $v (0 .. $pow-1) {
      my ($x,$y) = @{$vertex_to_xy[$v]};
      print " $x,$y";
    }
    print "\n";

    foreach my $v (0 .. $pow-1) {
      my ($x,$y) = @{$vertex_to_xy[$v]};
      if ($k%2) { ($x,$y) = xy_rotate_plus120($x,$y); }
      else { ($x,$y) = xy_rotate_minus120($x,$y); }
      $vertex_to_xy[$v+$pow]   = [$x - ($k%2?-1:1)*$x_offset, $y - $y_hi];

      if ($k%2) { ($x,$y) = xy_rotate_plus120($x,$y); }
      else { ($x,$y) = xy_rotate_minus120($x,$y); }
      $vertex_to_xy[$v+2*$pow] = [$x + ($k%2?-1:1)*$x_offset, $y - $y_hi];
    }
  }

  require GraphViz2;
  my $graphviz2 = GraphViz2->new (directed => $graph->is_directed);
  foreach my $v ($graph->vertices) {
    my ($x,$y) = @{$vertex_to_xy[$v]};
    # $y = -$y;
    $graphviz2->add_node(name => $v,
                         pin => 1,
                         pos => "$x,$y",
                        );
  }
  foreach my $edge ($graph->edges) {
    my ($from, $to) = @$edge;
    $graphviz2->add_edge(from => $from, to => $to);
  }

  $graphviz2->run(format => 'xlib',
                  driver => 'neato',
                 );
  # print $graphviz2->dot_input;
  exit 0;
}

sub xy_rotate_plus120 {
  my ($x, $y) = @_;
  return (($x+3*$y)/-2,  # rotate +120
          ($x-$y)/2);
}
sub xy_rotate_minus120 {
  my ($x, $y) = @_;
  return ((3*$y-$x)/2,              # rotate -120
          ($x+$y)/-2);
}





#------------------------------------------------------------------------------
# unused init code:

  # # smallest disc $t2[-1] moves to either other spindle
  # foreach (1, 2) {
  #   $t2[-1]++;
  #   $t2[-1] %= 3;
  #   if ($directed || $t2[-1] > $t[-1]) {
  #     my $v2 = $vertex_name_func->(\@t2, $spindles);
  #     ### smallest disc: "$v to $v2"
  #     $graph->add_edge($v, $v2);
  #   }
  # }
  #
  # # on the spindles without the smallest disc, can move the smaller of
  # # their two top discs
  # for (my $pos = $#t-1; $pos >= 0; $pos--) {
  #   if ($t[$pos] != $t[-1]) {
  #     @t2 = @t;
  #     $t2[$pos]++;
  #     $t2[$pos] %= 3;
  #     if ($t2[$pos] == $t[-1]) {
  #       $t2[$pos]++;
  #       $t2[$pos] %= 3;
  #     }
  #     if ($directed || $t2[$pos] > $t[$pos]) {
  #       my $v2 = $vertex_name_func->(\@t2, $spindles);
  #       ### second disc: "$v to $v2"
  #       $graph->add_edge($v, $v2);
  #     }
  #     last;
  #   }
  # }
  #

  # # done in integers
  # if (0) {
  #   my $v_max = 3**$discs - 1;
  #   my $vpad_max = 3**($discs-1) - 1;
  #   ### $discs
  #   ### $v_max
  #   ### $vpad_max
  #
  #   foreach my $v (0 .. $v_max) {
  #     my $low = $v % 3;
  #     ### $v
  #
  #     foreach my $inc (1, 2) {
  #       ### $low
  #       ### $inc
  #       my $other = ($low + $inc) % 3;
  #       {
  #         my $v2 = $v - $low + $other;
  #         if ($directed || $v2 > $v) {
  #           ### smallest disc: "$v to $v2"
  #           $graph->add_edge($v, $v2);
  #         }
  #       }
  #
  #       ### $low
  #       ### $other
  #       my $pad = ($low - $inc) % 3;
  #       my $mod = 3;
  #       my $rem = $low;
  #       foreach (1 .. $discs) {
  #         $mod *= 3;
  #         $rem = 3*$rem + $low;
  #         my $got = $v % $mod;
  #         ### $mod
  #         ### $rem
  #         ### $got
  #         if ($got != $rem) {
  #           my $v2 = $v - $got + ((2*$got - $rem) % $mod);
  #           if ($directed || $v2 > $v) {
  #             ### second smallest: "$v to $v2"
  #             $graph->add_edge($v, $v2);
  #           }
  #           last;
  #         }
  #       }
  #
  #       # my $pad = ($low - $inc) % 3;
  #       # ### $other
  #       # ### $pad
  #       #
  #       # my $vpad = $v;
  #       # for (;;) {
  #       #   ### at: "vpad=$vpad  v2=$v2"
  #       #   last if $vpad >= $vpad_max || $v2 >= $vpad_max;
  #       #   $vpad = 3*$vpad + $pad;
  #       #   $v2   = 3*$v2 + $pad;
  #       #   if ($directed || $v2 > $vpad) {
  #       #     ### second smallest: "$vpad to $v2"
  #       #   }
  #       #     $graph->add_edge($vpad, $v2);
  #       # }
  #     }
  #   }
  # }
  #
  # return $graph;
