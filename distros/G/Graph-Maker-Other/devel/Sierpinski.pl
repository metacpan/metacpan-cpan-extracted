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

use strict;
use FindBin;
use File::Spec;
use Graph;
use List::Util 'max';
use Math::BigInt try => 'GMP';
$|=1;

use lib File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'devel', 'lib');
use MyGraphs;
use Graph::Maker::SierpinskiTriangles;

# uncomment this to run the ### lines
# use Smart::Comments;

{
  # Sierpinski
  #   N=1 3-cycle   https://hog.grinvin.org/ViewGraphInfo.action?id=1374
  #   N=2           https://hog.grinvin.org/ViewGraphInfo.action?id=36261
  #
  my @graphs;
  for (my $N = 0; @graphs < 5; $N++) {
    my $graph = Graph::Maker->new('Sierpinski_triangles',
                                  N => $N,
                                  undirected=>1);
    $graph->set_graph_attribute(vertex_name_type_xy_triangular => 1);
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  MyGraphs::hog_upload_html($graphs[-1]);
  MyGraphs::Graph_view($graphs[-1]);
  exit 0;
}
{
  package Parts;
  use List::Util 'min','sum';
  my $verbose = 0;

  sub bigint {
    my ($n) = @_;
    return Math::BigInt->new($n);
  }
  #          *
  #         /c\
  #        a---b      U         
  #       /a\ /b\               
  #      0---a---1              
  #  $d0 |       | $d1          
  #      0---a---1              
  #       \a/ \b/               
  #        a---b      D         
  #         \c/                 
  #          *                  
  #
  sub NumVertices {
    my ($n) = @_;
    $n >= 0 or die;
    return (bigint(3)**$n + 1)*3/2;
  }
  sub two_split {
    my ($self, $n,$d0,$d1, $U,$D) = @_;
    $n >= 1 or die;
    if ($d0 > $d1) {
      ($d0,$d1) = ($d1,$d0);
      $U = [$U->[1],$U->[0], $U->[2]];
      $D = [$D->[1],$D->[0], $D->[2]];
    }
    if ($d1 >= $d0 + 2) {
      return ['one',$n, $d0, $U,$D ];
    }

    $n--;
    $d0 *= bigint(2);     # measured in units of 2**$n
    $d1 *= bigint(2);
    my $aU = [$U->[0], 1, 1];
    my $bU = [0, $U->[1], 1];
    my $cU = [0, 0, $U->[2]];
    my $aD = [$D->[0], 1, 1];
    my $bD = [0, $D->[1], 1];
    my $cD = [0, 0, $D->[2]];
    return(['two',$n,  $d0,  $d1+2,  $aU,$aD ],
           ['two',$n,  $d0+1, $d1+1, $aU,$bD ],
           ['two',$n,  $d0+1, $d1+2, $aU,$cD ],

           ['two',$n,  $d0+1, $d1+1, $bU,$aD ],
           ['two',$n,  $d0+2, $d1,   $bU,$bD ],
           ['two',$n,  $d0+2, $d1+1, $bU,$cD ],

           ['two',$n,  $d0+1, $d1+2, $cU,$aD ],
           ['two',$n,  $d0+2, $d1+1, $cU,$bD ],
           ['two',$n,  $d0+2, $d1+2, $cU,$cD ],
          );
  }

  sub corner_eval {
    my ($self, $n, $U) = @_;
    $n >= 0 or die;
    @$U == 3 or die;
    my $len = bigint(2)**$n;
    my $ret = bigint(6)**$n + $len;
    if (! $U->[1]) { $ret -= $len; }
    if (! $U->[2]) { $ret -= $len; }
    return $ret;
  }

  sub triplet_num_vertices {
    my ($self, $n,$U) = @_;
    return NumVertices($n) + sum(@$U)-3;
  }

  #   1         1
  #  /U\       /2\
  # 2---0 ... 0---2
  sub one_eval {
    my ($self, $n, $d, $U,$D) = @_;
    $n >= 0 or die;
    @$U == 3 or die;
    @$D == 3 or die;
    my $L = bigint(2)**$n;
    my $NumU = $self->triplet_num_vertices($n,$U);
    my $NumD = $self->triplet_num_vertices($n,$D);
    return $d*$L * $NumU * $NumD
      + $self->corner_eval($n,$U) * $NumD
      + $self->corner_eval($n,$D) * $NumU;
  }

  sub part_str {
    my ($part) = @_;
    return join(' ', map {ref $_ eq 'ARRAY' ? join('',@$_) : $_} @$part);
  }

  sub two_eval {
    my ($self, $n,$d0,$d1, $U,$D) = @_;
    $n >= 0 or die;
    my $d = min($d0,$d1);
    @$U == 3 or die;
    @$D == 3 or die;
    my $L = bigint(2)**$n;
    my $NumU = $self->triplet_num_vertices($n,$U);
    my $NumD = $self->triplet_num_vertices($n,$D);
    my $ret = $d*$L * $NumU * $NumD;
    $d0 -= $d;
    $d1 -= $d;
    ### $U
    ### $D
    ### $NumU
    ### $NumD
    ### $ret

    if ($n==0) {
      #       2
      #      /U\
      #     0---1
      #  d0 |   | d1
      #     0---1
      #      \D/
      #       2
      $ret += min($d0,  $d1+2) * ($U->[0] && $D->[0]);
      $ret += min($d0+1,$d1+1) * ($U->[0] && $D->[1]);
      $ret += min($d0+1,$d1+2) * ($U->[0] && $D->[2]);

      $ret += min($d0+1,$d1+1) * ($U->[1] && $D->[0]);
      $ret += min($d0+2,$d1  ) * ($U->[1] && $D->[1]);
      $ret += min($d0+2,$d1+1) * ($U->[1] && $D->[2]);

      $ret += min($d0+1,$d1+2) * ($U->[2] && $D->[0]);
      $ret += min($d0+2,$d1+1) * ($U->[2] && $D->[1]);
      $ret += min($d0+2,$d1+2) * ($U->[2] && $D->[2]);

    } else {
      if ($verbose) { print " from ",part_str(['two',$n,$d0,$d1, $U,$D]),"\n"; }
      foreach my $part ($self->two_split($n,$d0,$d1, $U,$D)) {
        my ($method, @args) = @$part;
        $method .= '_eval';
        my $length = $self->$method(@args);
        $ret += $length;
        if ($verbose) {
          my $num_paths = $self->part_num_paths($part);
          print " eval ",part_str($part)," gives $length by $num_paths paths\n";
        }
      }
    }
    return $ret;
  }

  #       2
  #      /U\
  #     u---c
  #    /D\ /
  #   2---d
  #
  sub third_parts {
    my ($self, $n) = @_;
    return ['two',$n,  0, 1, [1,1,1], [0,1,1] ];
  }
  sub whole_eval {
    my ($self,$n) = @_;
    $n >= 0 or die;
    if ($n == 0) {
      return 3;
    }
    return 3 * $self->two_eval($n-1, 0,1, [1,0,1], [0,1,1])
      + 3 * $self->whole_eval($n-1)
      - 3 * $self->corner_eval($n-1, [1,1,1]);
  }

  sub Graph_path_weight {
    my ($graph, @path) = @_;
    return sum(0,
               map {$graph->get_edge_weight($path[$_],$path[$_+1])//1}
               0 .. $#path-1);
  }

  sub two_eval_by_graph {
    my ($self, $n,$d0,$d1, $U,$D) = @_;
    my $T = Graph::Maker->new('Sierpinski_triangles',
                              N => $n,
                              undirected=>1);
    my @T_vertices = $T->vertices;
    my $L = bigint(2)**$n;
    my $L2 = 2*$L;
    my $graph = Graph->new(undirected=>1);
    $graph->add_edges(map {[map {"U$_"} @$_]} $T->edges);
    $graph->add_edges(map {[map {"D$_"} @$_]} $T->edges);
    $graph->add_path("U0,0",
                     (map {"d0,$_"} 1 .. $d0*$L),
                     "D0,0");
    $graph->add_path("U$L2,0",
                     (map {"d1,$_"} 1 .. $d1*$L),
                     "D$L2,0");
    my %exclude;
    if (! $U->[0]) { $exclude{"U0,0"} = 1; }
    if (! $U->[1]) { $exclude{"U$L2,0"} = 1; }
    if (! $U->[2]) { $exclude{"U$L,$L"} = 1; }
    if (! $D->[0]) { $exclude{"D0,0"} = 1; }
    if (! $D->[1]) { $exclude{"D$L2,0"} = 1; }
    if (! $D->[2]) { $exclude{"D$L,$L"} = 1; }
    if ($verbose) {
      print "vertices ",join(' ',sort $graph->vertices),"\n";
      print "exclude  ",join(' ',sort keys %exclude),"\n";
    }
    # $graph->vertices == 2*$T->vertices + $d0 + $d1 or die;

    my $ret = 0;
    my $apsp = $graph->all_pairs_shortest_paths;
    foreach my $u (@T_vertices) {
      my $u = "U$u";
      next if $exclude{$u};
      foreach my $v (@T_vertices) {
        my $v = "D$v";
        next if $exclude{$v};
        my $length = $apsp->path_length($u,$v) - 1;
        $ret += $length;
        if ($verbose) {
          print "$u to $v length $length\n";
        }
      }
    }
    return $ret;
  }
  sub part_num_paths {
    my ($self, $part) = @_;
    my $n = $part->[1];
    my $U = $part->[-2];
    my $D = $part->[-1];
    return $self->triplet_num_vertices($n,$U)
      * $self->triplet_num_vertices($n,$D);
  }
  my @UD_combinations = map {[ [($_&32?1:0), ($_&16?1:0), ($_&8?1:0)],
                               [($_&4?1:0), ($_&2?1:0), ($_&1?1:0)] ]} 0 .. 63;
  if (0) {
    foreach my $n (1..2) {
      foreach my $UD (@UD_combinations) {
        my ($U,$D) = @$UD;
        my @args = ($n, 0,0, $U,$D);
        my $by_whole = Parts->part_num_paths(['two',@args]);
        my $by_split = 0;
        my @parts = Parts->two_split(@args);
        foreach my $part (@parts) {
          $by_split += Parts->part_num_paths($part);
        }
        print "n=$n ",join('',@$U),' ',join('',@$D),
          " whole $by_whole split $by_split\n";
        if ($by_whole != $by_split) {
          foreach my $part (@parts) {
            print " ",part_str($part),
              "  gives ",Parts->part_num_paths($part),"\n";
          }
          die;
        }
      }
    }
  }
  if (0) {
    foreach my $n (2) {
      foreach my $UD (@UD_combinations) {
        my ($U,$D) = @$UD;
        my $d0 = 0;
        my $d1 = 0;
        my @args = ($n, $d0,$d1, $U,$D);
        my $by_graph = Parts->two_eval_by_graph(@args);
        my $by_func = Parts->two_eval(@args);
        print "n=$n d0=$d0 d1=$d1 ",join('',@$U),' ',join('',@$D),
          " graph $by_graph func $by_func\n";
        if ($by_graph != $by_func) {
          # MyGraphs::Graph_view($graph, scale => 2);
          die;
        }
      }
    }
  }
  use Memoize 'memoize';
  sub normalizer {
    shift @_;
    return part_str(\@_);
  }
  memoize('two_eval',
          NORMALIZER => \&normalizer,
          LIST_CACHE => 'MERGE');
  {
    my @want = (3, 21, 246, 3765, 64032, 1130463, 20215254, 363069729,
                6530385420, 117517503027, 2115137375634);
    print "W\n";
    foreach my $n (0..100) {
      my $by_func = Parts->whole_eval($n);
      print "$by_func,\n";
      if ($n <= $#want) { $by_func==$want[$n] or die; }
    }
    print "\n";
  }

  foreach my $n (0..4) {
    my $graph = Graph::Maker->new('Sierpinski_triangles',
                                  N => $n,
                                  undirected=>1);
    my $W = MyGraphs::Graph_Wiener_index($graph);
    my $by_func = Parts->whole_eval($n);
    print "whole $W func $by_func\n";
  }
  exit 0;


  # A290129  Wiener index of order N
  #
  # 3 * (1 - 27*x + 225*x^2 - 778*x^3 + 1068*x^4 - 360*x^5)  \
  #  / ( (1 - 2*x) * (1 - 3*x) * (1 - 6*x) * (1 - 18*x) * (1 - 5*x + 2*x^2) ) \
  # +O(x^10)
  #
  #  3/4/(1 - 2*x)
  #  + 9/20/(1 - 3*x)
  #  + 3/2/(1 - 6*x)
  #  + 699/1180/(1 - 18*x)
  #  + (-69/236 - 3/59*x)/(1 - 5*x + 2*x^2)
  #
  # as powers
  #  699/1180 * 18^n
  #  + 3/2 * 6^n
  #  + 9/20 * 3^n
  #  + 3/4 * 2^n
  #  + gf (-69/236 - 3/59*x)/(1 - 5*x + 2*x^2)
  #
  # sqrt(17)
  # poldisc(1 - 5*x + 2*x^2)
  #
  #
  # 699/1180 * 18^n  / (( (3^n)*3/2 )^2/2) / 2^n
  # GP-Test  699/1180 / ( ( 3/2)^2 /2)  == 466/885    /* per Hinz */
  # 466/885.0
  # 0.52655367231638418079
  # A276566

  #          *
  #         /c\           xx 2    < 4        aa = 2+2+2+2 = 8
  #        x---y          xy 2    < 5        aa
  #       /a\ /b\         xz   3  < 4           ab = 3+3 = 6
  #      0---z---1        yx 3    = 3        ba = 3+3 = 6
  #    0 |       | 1      yz 3    < 4 left      bb = 3
  #      0---x---1        yy   3  < 4        ba
  #       \a/ \b/         zx 2    = 2        aa
  #        y---z          zz   3  = 3           ab
  #         \c/           zy 2    < 4        aa
  #          *
  # 2+2 +3+3+3+3 +2 +3 +2 == 23


  # Andreas M. Hinz, "Shortest Paths Between Regular States of the Tower of
  # Hanoi", Information Sciences, volume 63, issues 1-2, September 1992,
  # pages 173-181.
  # https://doi.org/10.1016/0020-0255(92)90067-I

  # Andreas M. Hinz, Andreas Schief, "The Average Distance On the Sierpinski
  # Gasket", Probability Theory and Related Fields, volume 87, 1990, pages
  # 129-138.
  # https://doi.org/10.1007/BF01217750

  # Andreas M. Hinz, "The Tower of Hanoi", L'Enseignement Mathematique 35
  # 1989, pages 289-321.
  # https://www.unige.ch/math/EnsMath/EM_en/tables.html
  # https://www.unige.ch/math/EnsMath/tablemat.html
  # https://www.unige.ch/math/EnsMath/accueil0.html

  # Andreas M. Hinz, Sandi Klavzar, Uros Milutinovic, Daniele Parisse, Ciril
  # Petr, "Metric Properties of the Tower of Hanoi Graphs and Stern's
  # Diatomic Sequence", European Journal of Combinatorics, volume 26, number
  # 5, July 2005, pages 693-708.
  # https://doi.org/10.1016/j.ejc.2004.04.009
  # https://www.sciencedirect.com/science/article/pii/S0195669804000861

  # Andreas M. Hinz
  # http://www.mathematik.uni-muenchen.de/~hinz/
  # http://www.mathematik.uni-muenchen.de/~hinz/hanoi.html
  # https://oeis.org/wiki/User:Andreas_M._Hinz
  # https://oeis.org/history?user=Andreas%20M.%20Hinz

}

{
  # shortest path length and count ways
  # multi-shortest vertices
  # 1, 4, 13, 40, 121, 364, 1093, 3280, 9841, 29524,
  # (3^n - 1)/2

  foreach my $n (1 .. 10) {
    my $graph = Graph::Maker->new('Sierpinski_triangles',
                                  N => $n,
                                  undirected=>1);
    my $root = '0,0';
    my %shortest       = ('0,0' => 0);
    my %shortest_count = ('0,0' => 1);
    my @pending = ($root);
    my $distance = 0;
    while (@pending) {
      $distance++;
      my %new_pending;
      foreach my $from (@pending) {
        foreach my $to ($graph->neighbours($from)) {
          next if defined $shortest{$to} && $shortest{$to} < $distance;
          $shortest{$to} = $distance;
          $shortest_count{$to}++;
          $new_pending{$to} = 1;
        }
      }
      @pending = keys %new_pending;
    }
    my $mults = 0;
    foreach my $v (sort $graph->vertices) {
      #    print "$v  distance $shortest{$v} count $shortest_count{$v}\n";
      if ($shortest_count{$v} > 1) {
        $mults++;
      }
    }
    # print "multiples $mults max ",max(values %shortest_count),"\n";
    print "$mults, ";
  }
  exit 0;
}


{
  #     *          *
  #    /a\        / \
  #   x---y      A---C
  #  /b\ /c\     |   |
  # *---z---*    D---B
  # |       |     \ /
  # *---z---*      *
  #  \b/ \c/
  #   x---y
  #    \a/
  #     *
  #
  sub vertex_offset {
    my ($v, $dx,$dy) = @_;
    my ($x,$y) = split /,/, $v;
    $x += $dx;
    $y += $dy;
    "$x,$y";
  }
  sub elem_remove {
  }
  sub two {
    my ($n, $d, $u,$v) = @_;
    ### two: "n=$n d=$d  $u to $v"
    if ($n == 0) {
      return([vertex_offset($u,0,0), vertex_offset($v,0,0), $d],
             [vertex_offset($u,0,0), vertex_offset($v,2,0), $d + 1],
             [vertex_offset($u,0,0), vertex_offset($v,1,-1), $d + 1],
             [vertex_offset($u,2,0), vertex_offset($v,0,0), $d + 1],
             [vertex_offset($u,2,0), vertex_offset($v,2,0), $d],
             [vertex_offset($u,2,0), vertex_offset($v,1,-1), $d + 1],
             [vertex_offset($u,1,1), vertex_offset($v,0,0), $d + 1],
             [vertex_offset($u,1,1), vertex_offset($v,2,0), $d + 1],
             [vertex_offset($u,1,1), vertex_offset($v,1,-1), $d + 2]);
    }
    my @ret;
    my $L = bigint(2)**($n-1);
    push @ret, two($n-1, $d+$L,    # bc
                   vertex_offset($u,0,0), vertex_offset($v,2*$L,0));
    push @ret, two($n-1, $d+$L,    # cb
                   vertex_offset($u,2*$L,0), vertex_offset($v,0,0));
    my $z1 = vertex_offset($u,2*$L,0);
    my $z2 = vertex_offset($v,2*$L,0);

    my $pos = find_elem(\@ret, $z1,$z2) // die "zz $z1 $z2 not found";
    $ret[$pos]->[2] == $d + 2*$L
      or die "zz len ",$ret[$pos]->[2]," d=$d L=$L";
    splice @ret, $pos,1;  # remove

    #  + 2*one_1f1f(n-1, d)     \\ bb, cc
    #  + one_20(n-1,   d + L)  \\ ba
    #  + one_21f(n-1,  d + L)  \\ ca
    #  + one_20(n-1,  d + L)   \\ ab
    #  + one_21f(n-1,  d + L)  \\ ac
    #  + two_22(n-1, d + 2*L) \\ aa
    # 
    return @ret;
  }
  sub find_elem {
    my ($aref, $from,$to) = @_;
    foreach my $i (0 .. $#$aref) {
      if (($aref->[$i]->[0] eq $from && $aref->[$i]->[1] eq $to)
          || ($aref->[$i]->[0] eq $to && $aref->[$i]->[1] eq $from)) {
        return $i;
      }
    }
    return undef;
  }
  sub elem_to_str {
    my ($elem) = @_;
    my ($from,$to,$len) = @$elem;
    return "$from to $to  len $len";
  }
  sub elems_total_len {
    my ($aref) = @_;
    my $total = 0;
    foreach my $elem (@$aref) {
      my ($from,$to,$len) = @$elem;
      $total += $len;
    }
    return $total;
  }
  sub two_make_Graph {
    my ($n) = @_;
    my $L = 2 * 2**$n;
    my $graph = Graph::Maker->new('Sierpinski_triangles',
                                  N => $n,
                                  undirected=>1);
    $graph->set_graph_attribute (vertex_name_type_xy => 1);
    foreach my $edge ($graph->edges) {
      $graph->add_edge(map {
        my ($x,$y) = split /,/, $_;
        $y = -$y - 1;
        "$x,$y";
      } @$edge);
    }
    $graph->add_edge("0,0", "0,-1");
    $graph->add_edge("$L,0", "$L,-1");
    return $graph;
  }
  if (0) {
    my $graph = two_make_Graph(1);
    MyGraphs::Graph_view($graph, scale => 2);
    exit 0;
  }
  sub two_by_Graph {
    my $graph = two_make_Graph(1);
    my $apsp = $graph->APSP_Floyd_Warshall;
    my @ret;
    foreach my $u ($graph->vertices) {
      my ($ux,$uy) = split /,/, $u;
      $uy >= 0 or next;
      foreach my $v ($graph->vertices) {
        my ($vx,$vy) = split /,/, $v;
        $vy < 0 or next;
        push @ret, [$u,$v, $apsp->path_length($u,$v)];
      }
    }
    return @ret;
  }

  sub elems_to_hash {
    my ($aref) = @_;
    my %ret;
    @ret{map {elem_to_str($_)} @$aref} = ();
    return \%ret;
  }
  sub compare_twos {
    my ($A,$B) = @_;
    $A = elems_to_hash($A);
    $B = elems_to_hash($B);
    {
      my $count = 0;
      foreach my $str (keys %$A) {
        if (! exists $B->{$str}) {
          print "A not in B  $str\n";
          $count++;
        }
      }
      print "A not in B  count $count\n";
    }
    {
      my $count = 0;
      foreach my $str (keys %$B) {
        if (! exists $A->{$str}) {
          print "B not in A  $str\n";
          $count++;
        }
      }
      print "B not in A  count $count\n";
    }
  }

  {
    my @elems = two(0,1, '0,0', '0,-1');
    print "num elems ",scalar(@elems),
      " total length ",elems_total_len(\@elems),"\n";
    foreach my $elem (@elems) {
      print elem_to_str($elem),"\n";
    }
  }
  {
    my $n = 1;
    my @elems = two($n, 1, '0,0', '0,-1');
    print "num elems ",scalar(@elems),
      " total length ",elems_total_len(\@elems),"\n";
    foreach my $elem (@elems) {
      print "  ",elem_to_str($elem),"\n";
    }
    my @B = two_by_Graph($n);
    print "num B ",scalar(@B),
      " total length ",elems_total_len(\@B),"\n";
    foreach my $elem (@B) {
      print "  ",elem_to_str($elem),"\n";
    }

    compare_twos(\@B, \@elems);
  }
  exit 0;
}

{
  # Sierpinski Triangles - Wiener Index
  # A290129    3, 21, 246, 3765, 64032
  #
  # GP-DEFINE  A290129_samples = \
  # GP-DEFINE  [3,21,246,3765,64032,1130463,20215254,363069729,6530385420];
  # vector(6,i, A290129_samples[i+1] - 18*A290129_samples[i])
  # recurrence_guess(OEIS_samples("A290129"))

  # GP-DEFINE  NumVertices(N) = {
  # GP-DEFINE    N>=0 || error();
  # GP-DEFINE    (3^N+1)*3/2;
  # GP-DEFINE  }
  # GP-Test  vector(6,N,N--; NumVertices(N)) == [3, 6, 15, 42, 123, 366]
  #
  # GP-DEFINE  NumEdges(N) = {
  # GP-DEFINE    N>=0 || error();
  # GP-DEFINE    3^(N+1);
  # GP-DEFINE  }
  # GP-Test-Last  vector(6,N,N--; NumEdges(N)) == [3, 9, 27, 81, 243, 729]

  {
    #     @
    #    /a\
    #   x---y
    #  /b\ /c\
    # *---z---*
    #
    # GP-DEFINE  \\ total path lengths corner to each vertex
    # GP-DEFINE  \\ A074601
    # GP-DEFINE  corner(n,d=0) = 6^n + 2^n  + d*NumVertices(n);
    # GP-Test  NumVertices(0) == 3
    # GP-Test  corner(0) == 2
    # GP-Test  corner(1) == 2*1 + 3*2
    # GP-Test  vector(6,n,n--; corner(n)) == [2,8,40,224,1312,7808]
    # GP-DEFINE  corner_by_recurrence(n) = {
    # GP-DEFINE    n >= 0 || error();
    # GP-DEFINE    if(n==0, 2,
    # GP-DEFINE       corner(n-1)                  \\ a
    # GP-DEFINE       + 2*(2^(n-1)*NumVertices(n-1)
    # GP-DEFINE            + corner(n-1))  \\ b,c
    # GP-DEFINE       - 2*2^(n-1)    \\ x,y repeated
    # GP-DEFINE       - 2*2^(n-1));  \\ z repeated
    # GP-DEFINE  }
    # GP-Test  vector(16,n,n--; corner_by_recurrence(n)) == \
    # GP-Test  vector(16,n,n--; corner(n))
    # vector(10,n,n--; corner(n))
    # A074601
    #
    # GP-DEFINE  corner_1(n,d=0) = 6^n + 2^n  + d*(NumVertices(n)-1);
    #
    # GP-DEFINE  \\ total path lengths corner to each vertex,
    # GP-DEFINE  \\ omitting 1 far corner
    # GP-DEFINE  corner_1f(n,d=0) = 6^n  + d*(NumVertices(n)-1);
    # GP-Test  vector(8,n,n--; corner_1f(n)) == \
    # GP-Test  vector(8,n,n--; corner(n) - 2^n)
    # GP-DEFINE  corner_2(n,d=0) = 6^n  + d*(NumVertices(n)-2);

    foreach my $N (0..3) {
      my $graph = Graph::Maker->new('Sierpinski_triangles',
                                    N => $N,
                                    undirected=>1);
      my $v_corner = '0,0';
      $graph->has_vertex($v_corner) or die;
      $graph->degree($v_corner) == 2 or die;
      my $corner = 0;
      my $sptg = $graph->SPT_Dijkstra($v_corner);
      foreach my $v ($sptg->vertices) {
        if ($v ne $v_corner) {
          $corner += $sptg->get_vertex_attribute($v,'weight');
        }
      }
      print "$corner,";
    }
    print "\n";
  }
  {
    # GP-DEFINE  \\ between two n distance d apart
    # GP-DEFINE  one(n,d) = {
    # GP-DEFINE    n >= 0 || error();
    # GP-DEFINE    d*NumVertices(n)^2
    # GP-DEFINE    + 2*NumVertices(n) * corner(n);
    # GP-DEFINE  }
    # GP-Test  NumVertices(0) == 3
    # GP-Test  one(0,0) == 1+2+2 + 1+2+2 + 0+1+1
    # GP-Test  one(0,0) == 12
    # GP-Test  one(0,1) == 1+2+2 + 1+2+2 + 0+1+1  + 9
    # GP-Test  one(0,1) == 21
    # GP-Test  one(0,2) == 30
    # GP-Test  NumVertices(1) == 6
    # GP-Test  vector(5,n,n--; one(n,0)) == [12, 96, 1200, 18816, 322752]
    # GP-Test  vector(5,n,n--; one(n,1)) == [21,132, 1425, 20580, 337881]
    #
    # GP-DEFINE  one_by_parts(n,d) = {
    # GP-DEFINE    n >= 0 || error();
    # GP-DEFINE    if(n<1, return(one(n,d)));
    # GP-DEFINE    d*NumVertices(n)^2
    # GP-DEFINE    + 9*one(n-1, 0)
    # GP-DEFINE    + NumVertices(n-1)^2 * 2^(n-1) * (0+1+1 + 2*(1+2+2))
    # GP-DEFINE    - 48*NumVertices(n-1) * 2^(n-1)
    # GP-DEFINE    + 24* 2^(n-1)
    # GP-DEFINE    ;
    # GP-DEFINE  }
    # GP-Test  matrix(8,6,n,d, one(n,d)) == \
    # GP-Test  matrix(8,6,n,d, one_by_parts(n,d))
    #
    #     *             *
    #    /a\           /1\
    #   x---y         x---y
    #  /b\ /c\       /2\ /3\
    # *---z---* ... *---z---*
    #
    # GP-DEFINE  one_10(n,d) = {   \\ near corner omitted
    # GP-DEFINE    d*(NumVertices(n)-1)*NumVertices(n)
    # GP-DEFINE    + (NumVertices(n)-1) * corner(n)
    # GP-DEFINE    + NumVertices(n) * corner(n);
    # GP-DEFINE  }
    # GP-DEFINE  one_1f0(n,d) = {  \\ far corner omitted
    # GP-DEFINE    d*(NumVertices(n)-1)*NumVertices(n)
    # GP-DEFINE    + (NumVertices(n)-1) * corner(n)
    # GP-DEFINE    + NumVertices(n) * corner_1f(n);
    # GP-DEFINE  }
    # GP-DEFINE  one_11(n,d) = {
    # GP-DEFINE    d*(NumVertices(n)-1)^2
    # GP-DEFINE    + 2*(NumVertices(n)-1) * corner(n);
    # GP-DEFINE  }
    # GP-DEFINE  one_1f1f(n,d) = {  \\ one each far corner omitted
    # GP-DEFINE    d*(NumVertices(n)-1)^2
    # GP-DEFINE    + 2*(NumVertices(n)-1) * corner_1f(n);
    # GP-DEFINE  }
    # GP-DEFINE  one_20(n,d) = {
    # GP-DEFINE    d*(NumVertices(n)-2)*NumVertices(n)
    # GP-DEFINE    + (NumVertices(n)-2) * corner(n)
    # GP-DEFINE    + NumVertices(n) * corner_1f(n);
    # GP-DEFINE  }
    # GP-DEFINE  one_21(n,d) = {
    # GP-DEFINE    d*(NumVertices(n)-2)*(NumVertices(n)-1)
    # GP-DEFINE    + (NumVertices(n)-2) * corner(n)
    # GP-DEFINE    + (NumVertices(n)-1) * corner_1f(n);
    # GP-DEFINE  }
    # GP-DEFINE  one_21f(n,d) = {
    # GP-DEFINE    d*(NumVertices(n)-2)*(NumVertices(n)-1)
    # GP-DEFINE    + (NumVertices(n)-2) * corner_1f(n)
    # GP-DEFINE    + (NumVertices(n)-1) * corner_1f(n);
    # GP-DEFINE  }
    # GP-DEFINE  one_22(n,d) = {
    # GP-DEFINE    d*(NumVertices(n)-2)^2
    # GP-DEFINE    + 2*(NumVertices(n)-2) * corner_1f(n);
    # GP-DEFINE  }
    # GP-DEFINE  one_by_sans(n,d) = {
    # GP-DEFINE    n >= 0 || error();
    # GP-DEFINE    if(n<1, return(one(n,d)));
    # GP-DEFINE    one(n-1,d)                 \\ c2
    # GP-DEFINE    + one_10(n-1, d+2^(n-1))   \\ b2
    # GP-DEFINE    + one_20(n-1, d+2^(n-1))   \\ a2
    # GP-DEFINE    + one_10(n-1, d+2^(n-1))     \\ c3
    # GP-DEFINE    + one_11(n-1, d+2*2^(n-1))   \\ b3
    # GP-DEFINE    + one_21(n-1, d+2*2^(n-1))   \\ a3
    # GP-DEFINE    + one_20(n-1, d+2^(n-1))     \\ c2
    # GP-DEFINE    + one_21(n-1, d+2*2^(n-1))   \\ b2
    # GP-DEFINE    + one_22(n-1, d+2*2^(n-1))   \\ a2
    # GP-DEFINE    ;
    # GP-DEFINE  }
    # GP-Test  matrix(8,6,n,d, one(n,d)) == \
    # GP-Test  matrix(8,6,n,d, one_by_sans(n,d))
    # GP-Test  vector(8,n,n--; polcoeff(one_by_sans(n,'d),1,'d)) == \
    # GP-Test  vector(8,n,n--; NumVertices(n)^2)
    #
    # one_by_parts(1,1)
    # one_by_parts(2,1)
    # recurrence_guess(vector(40,n, (one(n,1) - one_by_parts(n,1) )))
    # [106,995, 13426]
    # vector(4,n, 2*NumVertices(n-1)-1)

    foreach my $N (1..2) {
      my $graph = Graph::Maker->new('Sierpinski_triangles',
                                    N => $N,
                                    undirected=>1);
      # print join(' ',$graph->vertices),"\n";
      my $other = Graph::Maker->new('Sierpinski_triangles',
                                    N => $N,
                                    undirected=>1);
      $other->set_graph_attribute (vertex_name_type_xy => 1);
      {
        my $top = 2**($N-1);
        foreach my $v ($other->vertices) {
          my ($x,$y) = split /,/, $v;
          if ($y > $top) { $other->delete_vertex($v); }
        }
        for (my $x = $top+2; $x <= 3*$top-2; $x += 2) {
          my $v = "$x,$top";
          $other->has_vertex($v) or die;
          $other->delete_vertex($v);
        }
      }
      # print join(' ',$other->vertices),"\n";
      # print "\nnum vertices ", scalar($other->vertices),"\n";
      # MyGraphs::Graph_view($other, scale => 2);
      $graph->add_edges(map {[map {"b$_"} @$_]} $other->edges);
      $graph->add_path('0,0',
                       # 'x',
                       'b0,0');
      # print join(' ',$graph->vertices),"\n";
      my $one = 0;
      $graph->for_shortest_paths
        (sub {
           my ($t, $u,$v, $n) = @_;
           if ($u =~ /,/ && $v =~ /,/        # skip middle path vertices
               && $u !~ /b/ && $v =~ /b/) {  # not-b to b
             # print "$u to $v length ", $t->path_length($u,$v), "\n";
             $one += $t->path_length($u,$v);
           }
         });
      print "$one,";
    }
    print "\n";
  }

  #         *
  #        /a\
  #       x---y
  #      /b\ /c\
  #     *---z---*
  #    /1\     /
  #   x---y   *
  #  /2\ /3\ /
  # *---z---*
  #
  {
    # GP-DEFINE  two_11(n,d) = {
    # GP-DEFINE    my(L=2^(n-1));
    # GP-DEFINE    two(n,d)
    # GP-DEFINE    - (d+L)*(2*NumVertices(n) - 1)
    # GP-DEFINE    - corner(n)      \\ A
    # GP-DEFINE    - corner_1f(n)    \\ B no repeat A-B
    # GP-DEFINE    ;
    # GP-DEFINE  }
    # GP-Test-Last  vector(8,n,n--; polcoeff(two_11(n,'d),1,'d)) == \
    # GP-Test-Last  vector(8,n,n--; (NumVertices(n)-1)^2)
    #
    # GP-DEFINE  two_22(n,d) = {
    # GP-DEFINE    my(L=2^(n-1));
    # GP-DEFINE    two(n,d)
    # GP-DEFINE    - 2*corner(n,d)    \\ A,C
    # GP-DEFINE    - 2*corner_2(n,d)  \\ D,B no repeats
    # GP-DEFINE    ;
    # GP-DEFINE  }
    # GP-Test-Last  vector(8,n,n--; polcoeff(two_22(n,'d),1,'d)) == \
    # GP-Test-Last  vector(8,n,n--; (NumVertices(n)-2)^2)
    #
    # GP-Test  vector(8,n,n--; polcoeff(one_22(n,'d),1,'d)) == \
    # GP-Test  vector(8,n,n--; (NumVertices(n)-2)^2)
    # GP-Test  vector(8,n,n--; polcoeff(one_21f(n,'d),1,'d)) == \
    # GP-Test  vector(8,n,n--; (NumVertices(n)-2)*(NumVertices(n)-1))
    # GP-Test  vector(8,n,n--; polcoeff(one_20(n,'d),1,'d)) == \
    # GP-Test  vector(8,n,n--; (NumVertices(n)-2)*NumVertices(n))
    # GP-Test  vector(8,n,n--; polcoeff(one_1f1f(n,'d),1,'d)) == \
    # GP-Test  vector(8,n,n--; (NumVertices(n)-1)^2)
    # GP-Test  vector(8,n,n--; polcoeff(one_1f0(n,'d),1,'d)) == \
    # GP-Test  vector(8,n,n--; (NumVertices(n)-1)*NumVertices(n))
    #
    #     *          *
    #    /a\        / \
    #   x---y      A---C
    #  /b\ /c\     |   |
    # *---z---*    D---B
    # |       |     \ /
    # *---z---*      *
    #  \b/ \c/
    #   x---y
    #    \a/
    #     *
    #
    # GP-DEFINE  \\ between two n distance d apart
    # GP-DEFINE  two(n,d) = {
    # GP-DEFINE    n >= 0 || error();
    # GP-DEFINE    if(n==0, return(3*3*d  + 1+1+2  + 2*(0+1+1)));
    # GP-DEFINE    my(L=2^(n-1));
    # GP-DEFINE      2*two(n-1,    d + L)   \\ bc, cb
    # GP-DEFINE    - (d + 2*L)              \\ z to z undup
    # GP-DEFINE    + 2*one_1f1f(n-1, d)     \\ bb, cc
    # GP-DEFINE    + one_20(n-1,   d + L)  \\ ba
    # GP-DEFINE    + one_21f(n-1,  d + L)  \\ ca
    # GP-DEFINE    + one_20(n-1,  d + L)   \\ ab
    # GP-DEFINE    + one_21f(n-1,  d + L)  \\ ac
    # GP-DEFINE    + two_22(n-1, d + 2*L) \\ aa
    # GP-DEFINE    ;
    # GP-DEFINE  }
    # GP-Test  vector(10,n,n--; polcoeff(two(n,'d),1,'d)) == \
    # GP-Test  vector(10,n,n--; NumVertices(n)^2)
    # FIXME:
    #  vector(6,n,n--; two(n,1)) 
    #  [17,106,1149,16582,271285,4681542]
    #
    # 2*9 -1 + 2*4
    # n=1
    # 2*two(n-1,    'd)   \\ bc, cb       18
    # -'d               \\ z to z undup    -1
    # 2*one_1f1f(n-1, 'd)  \\ bb,cc   4
    # two_22(n-1, 'd)   \\ aa    1
    # one_20(n-1,  'd)   \\ ab   3
    # one_21f(n-1,  'd)  \\ ac    2
    # one_20(n-1,   'd)  \\ ba   3
    # one_21f(n-1,  'd)  \\ ca   2
    # 2*9 - 1 + 4*4 + 6+4+3+2 + 3+2+1
    # GP-Test  two(0,0) == 1+1+2  + 2*(0+1+1)
    # GP-Test  two(0,1) == 2+2+3  + 2*(1+2+2)
    # lindep([ vector(5,n, two(n,1)) - [106,1149,16582,271285,4681542], \
    #          vector(5,n, NumVertices(n-1)^2 * 2^(n-1)), \
    #          vector(5,n, NumVertices(n-1) * 2^(n-1)), \
    #          vector(5,n, 2^(n-1)) ])
    # recurrence_guess(%)

    print "two: ";
    foreach my $N (0..6) {
      my $graph = Graph::Maker->new('Sierpinski_triangles',
                                    N => $N,
                                    undirected=>1);
      # print join(' ',$graph->vertices),"\n";
      my $L = '0,0';
      my $R = (2*2**$N).',0';
      foreach my $v ($L,$R) {
        $graph->has_vertex($v) or die "no vertex $v";
        $graph->degree($v) == 2 or die;
      }
      $graph->add_edges(map {[map {"b$_"} @$_]} $graph->edges);
      foreach my $v ($L,$R) {
        $graph->add_path($v,
                         # 'x',
                         "b$v");
      }
      # print join(' ',$graph->vertices),"\n";
      my $two = 0;
      $graph->for_shortest_paths
        (sub {
           my ($t, $u,$v, $n) = @_;
           if ($u =~ /,/ && $v =~ /,/        # skip middle path vertices
               && $u !~ /b/ && $v =~ /b/) {  # not-b to b
             # print "$u to $v length ", $t->path_length($u,$v), "\n";
             $two += $t->path_length($u,$v);
           }
         });
      print "$two,";
    }
    print "\n";
  }
  exit 0;
}


