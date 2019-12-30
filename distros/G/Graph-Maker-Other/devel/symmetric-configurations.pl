#!/usr/bin/perl -w

# Copyright 2019 Kevin Ryde
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
use List::Util 'min';
use Math::BaseCnv 'cnv';
use Math::Trig 'pi';

use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'devel', 'lib');
use MyGraphs;
$|=1;

# uncomment this to run the ### lines
# use Smart::Comments;

{
  # 9,3 Symmetric Configurations
  # http://mathworld.wolfram.com/Configuration.html
  # A001403 num N,3 symmetric configurations

  # Pappus = Brianchon-Pascal

  # cf
  # 10,3
  # https://hog.grinvin.org/ViewGraphInfo.action?id=1034
  #   Desargues Configuration
  # https://hog.grinvin.org/ViewGraphInfo.action?id=1036
  #   Desargues Graph  (indicence graph)

  require Graph;
  my @graphs;

  {
    # Pappus
    #
    # paths for lines geometrically
    # https://hog.grinvin.org/ViewGraphInfo.action?id=33731
    #
    # cycles for lines, is N=9 circulant 1,2,4
    # https://hog.grinvin.org/ViewGraphInfo.action?id=370
    #
    # incidence Pappus graph
    # https://hog.grinvin.org/ViewGraphInfo.action?id=1248
    #
    print "Pappus\n";
    my @lines = ([7,6,5],
                 [8,9,4],
                 [1,2,3],

                 [7,8,2],
                 [7,9,3],
                 [6,8,1],
                 [6,4,3],
                 [5,9,1],
                 [5,4,2]);
    foreach my $method ('add_path','add_cycle') {
      my $graph = Graph->new (undirected => 1);
      $graph->set_graph_attribute (name => "Pappus 9,3 Configuration $method");
      foreach my $line (@lines) {
        $graph->$method (@$line);
      }
      my @vertices = sort $graph->vertices;
      my @degrees = map {$graph->degree($_)} @vertices;
      print join(',',@degrees),"\n";
      push @graphs, $graph;
    }
    my $graph = Graph->new (undirected => 1);
    $graph->set_graph_attribute (name => " Pappus 9,3 Symmetric Incidence");
    foreach my $i (0 .. $#lines) {
      foreach my $v (@{$lines[$i]}) {
        $graph->add_edge ($v, "L$i");
      }
    }
    print "incidence ",Graph_is_configuration_incidence($graph),"\n";
    push @graphs, $graph;
  }
  {
    # Tri-Hex 9,3 Symmetric Configuration
    #
    # T. H. O'Beirne. "New Grids for Old Puzzles", New Scientist,
    # 11 January 1962.
    #
    # Martin Gardner, "Mathematical Games", Scientific American, volume 217,
    # number 5, November 1967.  Reprinted in Martin Gardner, "The Colossal
    # Book of Short Puzzles and Problems", W.W. Norton and Company, 2006,
    # ISBN 0-393-06114-0 (hardback), problem 11.10, pages 318, 330-331.

    print "tri-hex\n";
    my @lines = (
                 # O'Beirne figure 3
                 [1,8,3], [1,4,7], [1,9,5],
                 [3,6,9],[3,7,5],
                 [5,2,8],
                 [8,4,6],[7,6,2],[9,2,4]

                 # # Gardner
                 # [1,2,3],
                 # [1,8,4],
                 # [1,6,5],
                 #
                 # [2,7,5],
                 # [2,8,9],
                 # [3,9,6],
                 # [3,4,5],
                 # [4,9,7],
                 # [6,7,8]
                );
    my $make = sub {
      my ($method) = @_;
      my $graph = Graph->new (undirected => 1);
      $graph->set_graph_attribute (name => "Tri-Hex 9,3 Symmetric $method");
      foreach my $line (@lines) {
        $graph->$method (@$line);
      }
      return $graph;
    };
    foreach my $method ('add_path','add_cycle') {
      my $graph = $make->($method);
      push @graphs, $graph;
      my @vertices = sort $graph->vertices;
      my @degrees = map {$graph->degree($_)} @vertices;
      print join(',',@degrees),"\n";

      my $big = 2.5;
      my $medium = 1.6;
      my $small = .5;
      my $a = pi*.07;
      my $b = pi*-.05;

      MyGraphs::Graph_set_xy_points
          ($graph,
           1 => [$big*cos(pi/2), $big*sin(pi/2)],
           3 => [$big*cos(pi/2+2*pi/3), $big*sin(pi/2+2*pi/3)],
           5 => [$big*cos(pi/2+4*pi/3), $big*sin(pi/2+4*pi/3)],
           6 => [$small*cos($b-pi/2), $small*sin($b-pi/2)],
           2 => [$small*cos($b-pi/2+2*pi/3), $small*sin($b-pi/2+2*pi/3)],
           4 => [$small*cos($b-pi/2+4*pi/3), $small*sin($b-pi/2+4*pi/3)],
           9 => [$medium*cos($a), $medium*sin($a)],
           8 => [$medium*cos($a+pi*2/3), $medium*sin($a+pi*2/3)],
           7 => [$medium*cos($a+pi*4/3), $medium*sin($a+pi*4/3)],
          );
    }
    {
      # incidence graph
      # https://hog.grinvin.org/ViewGraphInfo.action?id=33797

      my $graph = Graph->new (undirected => 1);
      $graph->set_graph_attribute (name => "9,3 Symmetric Tri-Hex Incidence");
      foreach my $i (0 .. $#lines) {
        foreach my $v (@{$lines[$i]}) {
          $graph->add_edge ($v, "L$i");
        }
      }
      print "incidence ",Graph_is_configuration_incidence($graph),"\n";

      MyGraphs::Graph_set_xy_points
          ($graph,
           1 => [0,0],
           3 => [3,0],
           5 => [6,0],
           8 => [1,0],
           7 => [4,0],
           9 => [7,0],
           4 => [2,0],
           6 => [5,0],
           2 => [8,0],

           L0 => [0,-1], # 1
           L1 => [1,-1],
           L2 => [2,-1],
           L3 => [3,-1],
           L4 => [6,-1],
           L5 => [5,-1],
           L6 => [4,-1],
           L7 => [7,-1],
           L8 => [8,-1],
          );

      my $a = 2*pi/18;
      my $b = $a*-.5;
      MyGraphs::Graph_set_xy_points
          ($graph,
           1 => [2*sin($b+$a*0),2*cos($b+$a*0)],
           3 => [2*sin($b+$a*6),2*cos($b+$a*6)],
           5 => [2*sin($b+$a*12),2*cos($b+$a*12)],
           8 => [2*sin($b+$a*2),2*cos($b+$a*2)],
           7 => [2*sin($b+$a*8),2*cos($b+$a*8)],
           9 => [2*sin($b+$a*14),2*cos($b+$a*14)],
           4 => [2*sin($b+$a*4),2*cos($b+$a*4)],
           6 => [2*sin($b+$a*10),2*cos($b+$a*10)],
           2 => [2*sin($b+$a*16),2*cos($b+$a*16)],

           L0 => [2*sin($b+$a*1),2*cos($b+$a*1)],
           L1 => [2*sin($b+$a*17),2*cos($b+$a*17)],
           L2 => [2*sin($b+$a*13),2*cos($b+$a*13)],
           L3 => [2*sin($b+$a*5),2*cos($b+$a*5)],
           L4 => [2*sin($b+$a*7),2*cos($b+$a*7)],
           L5 => [2*sin($b+$a*11),2*cos($b+$a*11)],
           L6 => [2*sin($b+$a*3),2*cos($b+$a*3)],
           L7 => [2*sin($b+$a*9),2*cos($b+$a*9)],
           L8 => [2*sin($b+$a*15),2*cos($b+$a*15)],
          );

      push @graphs, $graph;
      # MyGraphs::Graph_print_tikz($graph);
      # MyGraphs::Graph_view($graph);
    }

    if (0) {
      # Lines as paths, but rotated as to which edge missing from each cycle.
      # Makes 16 different up to isomorphism
      # 6^3 == 216
      # 7^3 == 343
      my %seen;
      for (my $r0 = 0; $r0 < 3; $r0++, rotate_aref($lines[0])) {
        for (my $r1 = 0; $r1 < 3; $r1++, rotate_aref($lines[1])) {
          for (my $r2 = 0; $r2 < 3; $r2++, rotate_aref($lines[2])) {
            for (my $r3 = 0; $r3 < 3; $r3++, rotate_aref($lines[3])) {
              for (my $r4 = 0; $r4 < 3; $r4++, rotate_aref($lines[4])) {
                for (my $r5 = 0; $r5 < 3; $r5++, rotate_aref($lines[5])) {
                  for (my $r6 = 0; $r6 < 3; $r6++, rotate_aref($lines[6])) {
                    my $graph = $make->('add_path');
                    $graph->set_graph_attribute (name => "different $r0,$r1");
                    my $canon_g6 = MyGraphs::graph6_str_to_canonical
                      (MyGraphs::Graph_to_graph6_str($graph));
                    next if $seen{$canon_g6}++;
                    print "tri-hex different $r0,$r1,$r2,$r3,$r4,$r5,$r6\n";
                    push @graphs, $graph;
                  }
                }
              }
            }
          }
        }
      }
      print "tri-hex different ",scalar(keys %seen),"\n";
    }
  }
  {
    # Other 9,3 Symmetric
    # lines      https://hog.grinvin.org/ViewGraphInfo.action?id=33799
    # cliques    https://hog.grinvin.org/ViewGraphInfo.action?id=33801
    # incidence  https://hog.grinvin.org/ViewGraphInfo.action?id=33803
    #
    print "other\n";
    my @lines = (
                 # O'Beirne figure 2
                 ['A','F','D'],
                 ['A','H','E'],
                 ['A','C','G'],
                 ['D','B','H'],
                 ['D','K','G'],
                 ['G','E','B'],
                 ['F','H','C'],
                 ['F','B','K'],
                 ['C','E','K'],

                 # [1,2,3],
                 # [1,7,9],
                 # [1,6,5],
                 #
                 # [2,7,6],
                 # [2,8,4],
                 # [3,8,7],
                 # [3,4,5],
                 # [4,9,6],
                 # [5,9,8]
                );
    foreach my $method ('add_path','add_cycle') {
      my $graph = Graph->new (undirected => 1);
      $graph->set_graph_attribute (name => "Other 9,3 Symmetric $method");
      foreach my $line (@lines) {
        $graph->$method (@$line);
      }
      my @vertices = sort $graph->vertices;
      my @degrees = map {$graph->degree($_)} @vertices;
      print join(',',@degrees),"\n";
      push @graphs, $graph;
      # MyGraphs::Graph_print_tikz($graph);

      require Math::Complex;
      my $w6 = Math::Complex->new(.5, sqrt(3)/2);
      my $w3 = $w6**2;
      my $x = (sqrt(5)+1)/2;
      my $K = Math::Complex->new(0,0);
      my $E = $w6;
      my $B = $w3;
      my $C = 2*$w6;
      my $H = $w6+$w3;
      my $F = 2*$w3;
      my $G = $E + $x;
      my $A = $H + $x* $w3;
      my $D = $B + $x* ~$w3;

      if ($method eq 'add_cycle') {
        my $o = Math::Complex->new(-.1, .2);
        $E += $o;
        $H += $o*$w3;
        $B += $o * ~$w3;

        $o = Math::Complex->new(.2, .2);
        $G += $o;
        $A += $o*$w3;
        $D += $o * ~$w3;
      }

      # B = w3
      # E = w6
      # x = phi
      # x = 'x
      # G = E + x
      # D = B - x*w6
      # y= D + (G-D) * abs(real(D))/real(G-D)
      # plot(x=1,2,imag(subst(y,'x,x)))
      # solve(x=1,2,imag(subst(y,'x,x)))

      # real(D) == -5/4
      # G-D == 7/4 - 3/4*w
      #
      # G = w6 + 'x
      # D = w3 + 'x*conj(w3)
      # G-D = w6-w3 + x - x*conj(w3)
      #     = (3/2 + 1/2*w)*x + 1
      # D + f*(G-D)
      # w3 + x*conj(w3) + f*((3/2 + 1/2*w)*x + 1)
      # real (1/2*f*w + (3/2*f - 1/2))*x + (f - 1/2)
      # imag -1/2*x + 1/2
      #
      # Im D/G = 0
      # Im (F + G/w3)/G = 0
      # Im (F/G + w3) = 0
      # Im F/(w6 + x) + w3 = 0
      # Im 2*w3/(w6 + x) +w3 = 0
      # 2*w3/(w6+'x) + w3
      # polroots(x^2 + 3*x + 3)
      # x =

      MyGraphs::Graph_set_xy_points
          ($graph,
           A => [$A->Re, $A->Im],
           B => [$B->Re, $B->Im],
           C => [$C->Re, $C->Im],
           D => [$D->Re, $D->Im],
           E => [$E->Re, $E->Im],
           F => [$F->Re, $F->Im],
           G => [$G->Re, $G->Im],
           H => [$H->Re, $H->Im],
           K => [$K->Re, $K->Im],
          );
      if ($method eq 'add_cycle') {
      }
    }

    {
      my $graph = Graph->new (undirected => 1);
      $graph->set_graph_attribute (name => "Other 9,3 Symmetric Incidence");
      foreach my $i (0 .. $#lines) {
        foreach my $v (@{$lines[$i]}) {
          $graph->add_edge ($v, "L$i");
        }
      }
      print "incidence ",Graph_is_configuration_incidence($graph),"\n";

      my $a = 2*pi/18;
      my $b = $a*-2.5;
      MyGraphs::Graph_set_xy_points
          ($graph,
           A => [2*sin($b+$a*0),2*cos($b+$a*0)],
           D => [2*sin($b+$a*6),2*cos($b+$a*6)],
           G => [2*sin($b+$a*12),2*cos($b+$a*12)],
           F => [2*sin($b+$a*2),2*cos($b+$a*2)],
           K => [2*sin($b+$a*8),2*cos($b+$a*8)],
           C => [2*sin($b+$a*14),2*cos($b+$a*14)],
           H => [2*sin($b+$a*4),2*cos($b+$a*4)],
           B => [2*sin($b+$a*10),2*cos($b+$a*10)],
           E => [2*sin($b+$a*16),2*cos($b+$a*16)],

           L0 => [2*sin($b+$a*1),2*cos($b+$a*1)],
           L1 => [2*sin($b+$a*17),2*cos($b+$a*17)],
           L2 => [2*sin($b+$a*13),2*cos($b+$a*13)],
           L3 => [2*sin($b+$a*5),2*cos($b+$a*5)],
           L4 => [2*sin($b+$a*7),2*cos($b+$a*7)],
           L5 => [2*sin($b+$a*11),2*cos($b+$a*11)],
           L6 => [2*sin($b+$a*3),2*cos($b+$a*3)],
           L7 => [2*sin($b+$a*9),2*cos($b+$a*9)],
           L8 => [2*sin($b+$a*15),2*cos($b+$a*15)],
          );

      push @graphs, $graph;
      # MyGraphs::Graph_print_tikz($graph);
      # MyGraphs::Graph_view($graph);
      MyGraphs::hog_upload_html($graph);
    }
  }
  {
    # block cyclic 0,1,3
    print "Block Cyclic\n";
    my @lines = (map {[$_, ($_+1)%9, ($_+2)%9]} 0 .. 8);
    foreach my $method ('add_path','add_cycle') {
      my $graph = Graph->new (undirected => 1);
      $graph->set_graph_attribute (name => "9,3 Cyclic");
      foreach my $line (@lines) {
        $graph->$method (@$line);
      }
      my @vertices = sort $graph->vertices;
      my @degrees = map {$graph->degree($_)} @vertices;
      print join(',',@degrees),"\n";
      push @graphs, $graph;
    }
    my $graph = Graph->new (undirected => 1);
    $graph->set_graph_attribute (name => "Other 9,3 Symmetric Incidence");
    foreach my $i (0 .. $#lines) {
      foreach my $v (@{$lines[$i]}) {
        $graph->add_edge ($v, "L$i");
      }
    }
    print "incidence ",Graph_is_configuration_incidence($graph),"\n";
    push @graphs, $graph;
    # MyGraphs::Graph_print_tikz($graph);
    # MyGraphs::Graph_view($graph);
  }

  {
    # circulant
    require Graph::Maker::Circulant;
    my $graph = Graph::Maker->new('circulant', undirected => 1,
                                  N => 9, offset_list => [1,2,3]);
    push @graphs, $graph;
    # MyGraphs::Graph_view($graph);
  }
  {
    # circulant
    require Graph::Maker::Circulant;
    my $graph = Graph::Maker->new('circulant', undirected => 1,
                                  N => 9, offset_list => [1,2,4]);
    push @graphs, $graph;
    # MyGraphs::Graph_view($graph);
  }
  {
    # Complete 6 and Ends

    require Graph::Maker::Complete;
    my $graph = Graph::Maker->new('complete', undirected => 1, N=>6);
    $graph->set_graph_attribute (name => "Complete 6 and Ends");
    $graph->add_path (1,7,2);
    $graph->add_path (3,8,4);
    $graph->add_path (5,9,6);
    my @vertices = sort $graph->vertices;
    my @degrees = map {$graph->degree($_)} @vertices;
    print join(',',@degrees),"\n";
    push @graphs, $graph;
    # MyGraphs::Graph_print_tikz($graph);
    # MyGraphs::Graph_view($graph);
  }
  # print "iso ",MyGraphs::Graph_is_isomorphic($graphs[0],$graphs[1]),"\n";
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # 21,3
  #
  # incidence graph
  #   https://hog.grinvin.org/ViewGraphInfo.action?id=33736

  require Graph;
  my @graphs;

  my @lines = map { [split //, $_] }
    qw(012 034 056 178 19a 2bc 2de 37f 3bg 48h 49i 57d 5cj 6bi 6hk 8gj 9dk
       ach aeg efi fjk);
  foreach my $method ('add_path','add_cycle') {
    my $graph = Graph->new (undirected => 1);
    $graph->set_graph_attribute (name => "21,3 Configuration $method");
    foreach my $line (@lines) {
      $graph->$method (@$line);
    }
    my @vertices = sort $graph->vertices;
    my @degrees = map {$graph->degree($_)} @vertices;
    print join(',',@degrees),"\n";
    push @graphs, $graph;
  }
  {
    my $graph = Graph->new (undirected => 1);
    $graph->set_graph_attribute (name => "21,3 Symmetric Incidence");
    foreach my $i (0 .. $#lines) {
      foreach my $v (@{$lines[$i]}) {
        $graph->add_edge ($v, "L$i");
      }
    }
    print "incidence ",Graph_is_configuration_incidence($graph),"\n";
    push @graphs, $graph;
  }

  {
    my $graph = Graph->new (undirected => 1);
    $graph->set_graph_attribute (name => "Heawood");
    foreach my $i (0 .. 13) {
      $graph->add_edge ($i, ($i+1)%14);
      if ($i % 2 == 0) {
        $graph->add_edge ($i, ($i+5)%14);
      } else {
        $graph->add_edge ($i, ($i-5)%14);
      }
    }
    push @graphs, $graph;

    $graph = $graph->copy;
    $graph->set_graph_attribute (name => "Heawood Subdivided");
    my $n = 100;
    for (my $i = 0; $i < 14; $i += 2) {
      my @new;
      foreach my $offsets ([0,1], [-2,3], [-6,7]) {
        my ($a,$b) = @$offsets;
        my $from = ($i+$a)%14;
        my $to = ($i+$b)%14;
        $graph->has_edge ($from, $to) or die "$a $b";
        $graph->delete_edge ($from, $to);
        $graph->add_path ($from, $n, $to);
        ### subdiv: "$from $n $to"
        push @new, $n++;
      }
      my $to = $n++;
      foreach my $from (@new) {
        $graph->add_edge ($from, $to);
      }
    }
    push @graphs, $graph;
  }

  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # 7,3 Symmetric Configurations - Fano Plane
  #
  #              5
  #           /  |  \
  #          /   |   \
  #         6 _  |  _ 4
  #        /    _7_    \
  #       / __-- | --__ \
  #      1 ----- 2 ----- 3
  #
  # https://hog.grinvin.org/ViewGraphInfo.action?id=19174
  #   Fano plane with middle cycle
  #   Unique triangulation with 7 vertices.
  #   3 separating triangles and minimal Hamiltonian cycles.
  #
  # https://hog.grinvin.org/ViewGraphInfo.action?id=58
  #   Cycles.
  #   Circulant N=7 1,2,3
  #
  # https://hog.grinvin.org/ViewGraphInfo.action?id=1154
  #   Heawood, incidence graph.

  require Graph;
  my @graphs;

  my @lines = ([1,2,3],
               [3,4,5],
               [5,6,1],

               [1,7,4],
               [3,7,6],
               [5,7,2],
               [2,4,6]);
  my $make = sub {
    my ($method) = @_;
    my $graph = Graph->new (undirected => 1);
    $graph->set_vertex_attribute(1, x => 0);
    $graph->set_vertex_attribute(1, y => 0);
    $graph->set_vertex_attribute(2, x => 2);
    $graph->set_vertex_attribute(2, y => 0);
    $graph->set_vertex_attribute(3, x => 4);
    $graph->set_vertex_attribute(3, y => 0);
    $graph->set_vertex_attribute(4, x => 3);
    $graph->set_vertex_attribute(4, y => 1);
    $graph->set_vertex_attribute(5, x => 2);
    $graph->set_vertex_attribute(5, y => 2);
    $graph->set_vertex_attribute(6, x => 1);
    $graph->set_vertex_attribute(6, y => 1);
    $graph->set_vertex_attribute(7, x => 2);
    $graph->set_vertex_attribute(7, y => .6);

    $graph->set_graph_attribute (name => "Fano 7,3 Configuration $method");
    foreach my $line (@lines) {
      $graph->$method (@$line);
    }
    return $graph;
  };
  foreach my $method ('add_path','add_cycle') {
    my $graph = $make->($method);
    my @vertices = sort $graph->vertices;
    my @degrees = map {$graph->degree($_)} @vertices;
    print join(',',@degrees),"\n";
    push @graphs, $graph;

    if ($method eq 'add_path') {
      # middle cycle
      $graph = $graph->deep_copy;
      $graph->set_graph_attribute (name => "Fano Plane middle cycle");
      die if $graph->has_edge(2,6);
      $graph->add_edge(2,6);
      push @graphs, $graph;
    }
  }
  {
    my $graph = Graph->new (undirected => 1);
    $graph->set_graph_attribute (name => "Fano 7,3 Symmetric Incidence");
    foreach my $i (0 .. $#lines) {
      foreach my $v (@{$lines[$i]}) {
        $graph->add_edge ($v, "L$i");
      }
    }
    print "incidence ",Graph_is_configuration_incidence($graph),"\n";
    push @graphs, $graph;
  }
  {
    # circulant
    require Graph::Maker::Circulant;
    my $graph = Graph::Maker->new('circulant', undirected => 1,
                                  N => 7, offset_list => [1,2,3]);
    push @graphs, $graph;
    # MyGraphs::Graph_view($graph);
  }

  if (0) {
    # Lines as paths, but rotated as to which edge missing from each cycle.
    # Makes 16 different up to isomorphism
    # 6^3 == 216
    # 7^3 == 343
    my %seen;
    for (my $r0 = 0; $r0 < 3; $r0++, rotate_aref($lines[0])) {
      for (my $r1 = 0; $r1 < 3; $r1++, rotate_aref($lines[1])) {
        for (my $r2 = 0; $r2 < 3; $r2++, rotate_aref($lines[2])) {
          for (my $r3 = 0; $r3 < 3; $r3++, rotate_aref($lines[3])) {
            for (my $r4 = 0; $r4 < 3; $r4++, rotate_aref($lines[4])) {
              for (my $r5 = 0; $r5 < 3; $r5++, rotate_aref($lines[5])) {
                for (my $r6 = 0; $r6 < 3; $r6++, rotate_aref($lines[6])) {
                  my $graph = $make->('add_path');
                  $graph->set_graph_attribute (name => "different $r0,$r1");
                  my $canon_g6 = MyGraphs::graph6_str_to_canonical
                    (MyGraphs::Graph_to_graph6_str($graph));
                  next if $seen{$canon_g6}++;
                  push @graphs, $graph;
                }
              }
            }
          }
        }
      }
    }
    print "different ",scalar(keys %seen),"\n";
  }

  MyGraphs::hog_searches_html(@graphs);
  exit 0;

  sub rotate_aref {
    my ($aref) = @_;
    push @$aref, shift @$aref;
    return $aref;
  }
}




{
  # 8,3 Symmetric Configuration
  #
  # https://hog.grinvin.org/ViewGraphInfo.action?id=176
  #   Cycles for lines.
  #   Sixteen Cell Graph
  #   Complete 4-partite 4x2.
  #
  # https://hog.grinvin.org/ViewGraphInfo.action?id=1229
  #   Incidence graph.
  #   Mobius Kantor Graph.

  require Graph;
  my @graphs;

  {
    # circulant HOG 160
    require Graph::Maker::Circulant;
    my $graph = Graph::Maker->new('circulant', undirected => 1,
                                  N => 8, offset_list => [1,2]);
    push @graphs, $graph;
    # MyGraphs::Graph_view($graph);
  }
  {
    # circulant HOG 176
    require Graph::Maker::Circulant;
    my $graph = Graph::Maker->new('circulant', undirected => 1,
                                  N => 8, offset_list => [1,2,3]);
    push @graphs, $graph;
    # MyGraphs::Graph_view($graph);
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # Symmetric Configurations Incidence Graphs - Search
  # >>graph6<<Ms??GCAEOpCgPGY??
  # nauty-genbg -c -d3 -D3 7 7
  # nauty-genbg -c -d3 -D3 8 8
  # nauty-genbg -c -d3 -D3 9 9

  # degree-3 regular bipartites N,N
  # not in OEIS: 1, 1, 2, 6, 15, 48, 215, 1140,
  # A006823 up to isomorphism (one of each dual)
  # 1, 1, 2, 5, 13, 38, 149, 703,
  # difference
  # not in OEIS: 1, 2, 10, 66, 437

  my @graphs;
  require IPC::Run;
  require File::Spec;
  my $verbose = 0;
  foreach my $N (8 .. 8) {
    IPC::Run::run (['nauty-genbg','-c','-d3','-D3',
                    '-l',
                    $N,$N],
                   '>', \my $out,
                   '2>', File::Spec->devnull);
    my $count = count_lines($out);
    if (0) {
      my $in = $out;
      IPC::Run::run (['nauty-labelg'],
                     '<', \$in,
                     '2>', File::Spec->devnull,
                     '|', ['sort','-u'],
                     '>', \$out);
    }
    my $count_canon = count_lines($out);
    if (0) {
      my $in = $out;
      IPC::Run::run (['/so/nauty/nauty27b6/edgetransg','-v'],
                     '<', \$in,
                     '>', \$out,
                     '2>', File::Spec->devnull
                    );
    }
    if ($verbose) {
      print $out;
    }

    my $count_incidence = 0;
    foreach my $g6_str (split /\n/, $out) {
      my $graph = MyGraphs::Graph_from_graph6_str($g6_str);
      Graph_is_configuration_incidence($graph) or next;
      $count_incidence++;
      $graph->set_graph_attribute (name => "$N,3 Incidence ($count_incidence)");

      { my @ret = Graph_bipartite_vertices($graph);
        @ret = map {[sort @$_]} @ret;
        ### @ret
      }
      my $conf = Graph_incidence_to_configuration($graph);
      $graph->set_graph_attribute (name => "$N,3 Configuration Cliques ($count_incidence)");
      my $conf_g6 = MyGraphs::Graph_to_graph6_str($conf);
      my $canon_g6 = MyGraphs::graph6_str_to_canonical($conf_g6);
      my $num_vertices = $conf->vertices;
      my $num_edges = $conf->edges;
      if ($verbose) {
        print "vertices $num_vertices edges $num_edges\n";
        print "graph6:    >>graph6<<",$conf_g6;
        print "canonical: >>graph6<<",$canon_g6;
      }
      push @graphs, $conf;
      push @graphs, $graph;
    }

    my $count_trans = count_lines($out);
    # print $count-$count_canon,", ";
    print $count_incidence,", ";
  }
  print "\n";

  # >>graph6<<Ms???@KOpSBGHOD_?
  # >>graph6<<Ms??OGKB?ccKS_WO?
  # MyGraphs::Graph_from_graph6_str
  #                               ('>>graph6<<Ms???@KOpSBGHOD_?'),
  #                               MyGraphs::Graph_from_graph6_str
  #                               ('>>graph6<<Ms??OGKB?ccKS_WO?'));
  MyGraphs::hog_searches_html(@graphs);
  exit 0;

  sub count_lines {
    my ($str) = @_;
    scalar(@{[$str =~ /\n/g]});
  }
  CHECK {
    count_lines("") == 0 or die;
    count_lines("\n\n") == 2 or die;
  }

  sub Graph_is_configuration_incidence {
    my ($graph) = @_;
    foreach my $part (Graph_bipartite_vertices($graph)) {
      if (Graph_is_num_common_neighbours_le($graph, 1, $part)) {
        return 1;
      }
    }
    return 0;
  }
  sub Graph_is_num_common_neighbours_le {
    my ($graph, $limit, $vertices) = @_;
    $vertices ||= [$graph->vertices];
    foreach my $i (0 .. $#$vertices-1) {
      my %i_neighbours = map {$_=>1} $graph->neighbours($vertices->[$i]);
      foreach my $j ($i+1 .. $#$vertices) {
        my $count = 0;
        foreach my $jv ($graph->neighbours($vertices->[$j])) {
          if ($i_neighbours{$jv} && ++$count > $limit) {
            return 0;
          }
        }
      }
    }
    return 1;
  }

  sub Graph_incidence_to_configuration {
    my ($graph) = @_;
    my ($a_list,$b_list) = Graph_bipartite_vertices($graph);
    my $conf = Graph->new (undirected => 1);
    foreach my $b (@$b_list) {
      ### neighbours: $graph->neighbours($b)
      Graph_add_clique($conf, $graph->neighbours($b));
    }
    return $conf;
  }
  sub Graph_add_clique {
    my $graph = shift;
    foreach my $i (0 .. $#_-1) {
      foreach my $j ($i+1 .. $#_) {
        $graph->add_edge($_[$i],$_[$j]);
      }
    }
  }

  sub Graph_bipartite_vertices {
    my ($graph) = @_;
    my @vertices = $graph->vertices;
    my %parity;
    my @queue = @vertices;
    my @ret;
    while (@queue) {
      my $v = pop @queue;
      if (! defined $parity{$v}) {
        $parity{$v} = 0;
        push @{$ret[0]}, $v;
      }
      my $p = 1 - $parity{$v};
      foreach my $u ($graph->neighbours($v)) {
        if (! defined $parity{$u}) {
          $parity{$u} = $p;
          push @{$ret[$p]}, $u;
          push @queue, $u;
        } elsif ($parity{$u} != 1 - $parity{$v}) {
          return; # not bipartite
        }
      }
    }
    return @ret;
  }
}
