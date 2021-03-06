#!/usr/bin/perl -w

# Copyright 2018, 2019, 2020 Kevin Ryde
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
use Graph::Maker::BulgarianSolitaire;
use List::Util 'sum';

use FindBin;
use lib "$FindBin::Bin/lib";
use MyGraphs;
$|=1;

# uncomment this to run the ### lines
# use Smart::Comments;


{
  # Bulgarian Solitaire, all n
  MyGraphs::hog_searches_html
      (
       '>>sparse6<<:@',      # n=1 singleton
       '>>sparse6<<:Ab',     # n=2 2-cycle
       '>>sparse6<<:Bc',     # n=3 path-3
       '>>sparse6<<:DaXIN',  # n=4 3-cycle and hanging path-2 
       ':FaYgxb',            # n=5

       # n=6 tree
       '>>sparse6<<:J`E_xRcYcW^',

       ':N`E_xTeY\RwdQKN',
       ':U_`dBaebcFcfgGhJnBMeiad`_',
       ':]_`dBaehBcFgcghImiNjcfPhlqbekad`_',  # n=9
       ':i_OWoMDFd?w_aJHaQXOqZPdrIcuJHddY@YdWn@BkaTNjow{yDE_oN',

       # n=10 tree
       ':i_OWoMDFd?w_aJHaQXOqZPdrIcuJHddY@YdWn@BkaTNjow{yDE_oN',
       
       # n=15
       ':~?Ao_C@`?B_SH`wB__I_kE_{J`cL`sZ?cJ`wPakWbK]aCacoPaOba[cckkAcedwTaofa{gbCXDKYDSD`cQaojbKYb{cd?kdSmdgpeSmEcyf{nGTBg{oeLIeTNEXJhcselS?sLa[VbHLcCddChHsme@Ne[zf|@IDEILGhtWiPZjl`ktRloF`sRapjbC_c`kc{ld{yLk}gDDhlVjT_mDroWF`iAaSTb{bcskfK|gdUjLno[E`cPac]cSjfC{ilm_kJaC\cKvicC`SNbcu_[Hb[A`C@_F',
      );
  exit 0;
}
{
  # HOG
  # N=4 3-cycle and hanging 2-path
  #   https://hog.grinvin.org/ViewGraphInfo.action?id=330
  # N=5 3-cycle and tree
  #   https://hog.grinvin.org/ViewGraphInfo.action?id=820
  # and more ...
  # stop at N=16 as next N=17 > 255 vertices
  my @graphs;
  foreach my $N (
                 # 3,4,5,6,7,8,9,10
                 # 3..20,
                 13,14,16,17
                ) {
    foreach my $compositions (
                              0,
                              # 'append',
                             ) {
      print "N=$N\n";
      my $graph = Graph::Maker->new
        ('Bulgarian_solitaire',
         N            => $N,
         compositions => $compositions,
         undirected => 0,
         no_self_loop => 1);
      # $graph = MyGraphs::Graph_subdivide($graph);
      # $graph = $graph->undirected_copy;
      push @graphs, $graph;
      my $num_vertices = $graph->vertices;
      my $directed     = $graph->is_directed ? 1 : 0;
      print $graph->get_graph_attribute('name'),"\n";
      print "  num vertices $num_vertices directed $directed\n";
      $graph->set_graph_attribute (flow => 'north');

      if (0) {
        my $i = 1;
        foreach my $v (sort $graph->vertices) {
          MyGraphs::Graph_rename_vertex($graph, $v, 's'.$i++);
        }
        $i = 1;
        foreach my $v (sort $graph->vertices) {
          MyGraphs::Graph_rename_vertex($graph, $v, $i++);
        }
      }

      # MyGraphs::Graph_run_dreadnaut($graph->undirected_copy,
      #                               verbose=>0, base=>1);
      # print "vertices: ",join('  ',$graph->vertices),"\n";
      if ($graph->vertices < 100) {
        # MyGraphs::Graph_view($graph, synchronous=>0);
      }

      my $d6str = MyGraphs::Graph_to_graph6_str($graph, format=>'digraph6');
      # print Graph::Graph6::HEADER_DIGRAPH6(), $d6str;
      # print "\n";

      # MyGraphs::Graph_print_tikz($graph);
    }
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  my $N = 4;
  my $compositions = 'append';

  my $graph = Graph::Maker->new ('Bulgarian_solitaire',
                                 N => $N,
                                 compositions => $compositions,
                                 undirected => 1);
  my @centre = $graph->centre_vertices;
  ### @centre
  foreach my $v ($graph->vertices) {
    next unless $graph->degree($v) == 1;
    my $len = $graph->path_length($v,$centre[0]);
    print "$v   dist $len\n";
  }

  $graph = Graph::Maker->new ('Bulgarian_solitaire',
                              N => $N,
                              compositions => $compositions,
                              undirected => 0);
  $graph->set_graph_attribute (flow => 'north');
  $graph->set_graph_attribute (root => '1,2,3');
  MyGraphs::Graph_view($graph, synchronous=>1);
  # MyGraphs::Graph_tree_print($graph);

  exit 0;
}
{
  my $graph = Graph::Maker->new
    ('Bulgarian_solitaire',
     N            => 6,
    );
  MyGraphs::Graph_view($graph, synchronous=>1);
  exit 0;
}

CHECK {
  ! Scalar::Util::looks_like_number('1,1') or die;
}
