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

use 5.005;
use strict;
use List::Util 'min';

use FindBin;
use lib "$FindBin::Bin/../devel/lib";
use MyGraphs;
$|=1;

# uncomment this to run the ### lines
# use Smart::Comments;


{
  # identity graphs, asymmetric
  MyGraphs::hog_searches_html
      (# 5-cycle and leaf, 7 edges
       'ECro',

       # diamond and 2 leaves, 7 edges
       'ECrg',

       # triangle, leaf, path-2, 6 edges
       'ECZG',

       # diamond, triangle, leaf, 8 edges
       'ECzW',

       # square, triangle, leaf, 7 edges
       # https://hog.grinvin.org/ViewGraphInfo.action?id=25152
       'EEhW',

       # diamond and square, 8 edges
       'EEjo',

       # 3 triangles and leaf, 8 edges
       'EEjW',

       # 3 triangles and square, 9 edges
       'EEno',
      );
  exit 0;
}
{
  # regular not maximum median
  # GCZJd_
  # GCXmd_

  foreach my $g6_str ('GCZJd_',  # n=8
                      'GCXmd_',
                      'HCOethk',   # n=9
                     ) {
    MyGraphs::Graph_print_tikz(MyGraphs::Graph_from_graph6_str($g6_str));
    my $can = MyGraphs::graph6_str_to_canonical($g6_str);
    print MyGraphs::hog_grep($can)?"HOG":"not", "\n";
  }
  exit 0;
}
{
  my $want = "GEhtr{\n";
  $want = MyGraphs::graph6_str_to_canonical($want);
  print MyGraphs::hog_grep($want)?"HOG":"not", "\n";
  my $iterator_func = MyGraphs::make_graph_iterator_edge_aref
    (num_vertices_min => 1,
     num_vertices_max => 9,
     connected => 1,
    );
  while (my $edge_aref = $iterator_func->()) {
    my $graph = MyGraphs::Graph_from_edge_aref($edge_aref);
    my $linegraph = MyGraphs::Graph_line_graph($graph);
    my $got = MyGraphs::graph6_str_to_canonical
      (MyGraphs::Graph_to_graph6_str($linegraph));
    if ($got eq $want) {
      my $graph_g6 = MyGraphs::graph6_str_to_canonical
        (MyGraphs::Graph_to_graph6_str($graph));
      print MyGraphs::hog_grep($graph_g6)?"HOG":"not", "\n";
      # MyGraphs::Graph_print_tikz($graph);
      # MyGraphs::Graph_view($graph);
      exit;
    }
  }
  exit 0;
}
{
  # GCQbUG
  #   linegraph 1
  # GCQREO
  #   linegraph 1
  # GCpddW
  #   linegraph 1
  # GEhtr{
  #   linegraph 1

  foreach my $g6_str ('GCQbUG',
                      'GCQREO',
                      'GCpddW',
                      'GEhtr{') {
    MyGraphs::Graph_print_tikz(MyGraphs::Graph_from_graph6_str($g6_str));
  }
  exit 0;
}
{
  # Harary and Palmer two triangles
  #
  #    2       3
  #   / \     / \
  #  1---5---6---7---4---0
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30306
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30308  removal

  my $graph = Graph->new (undirected=>1);
  print "is linegraph ",MyGraphs::Graph_is_line_graph_by_Beineke($graph),"\n";

  $graph->add_cycle(1,2,5);
  $graph->add_path(5,6,7,4,0);
  $graph->add_path(6,3,7);
  my $u = 5;
  my $v = 7;
  my $gu = $graph->copy;
  my $gv = $graph->copy;
  $gu->delete_vertex($u);
  $gv->delete_vertex($v);
  print "isomorphic ",MyGraphs::Graph_is_isomorphic($gu,$gv),"\n";
  MyGraphs::Graph_view($gu);
  MyGraphs::Graph_view($gv);

  MyGraphs::hog_searches_html($graph, $gu);
  exit 0;
}
{
  # hog_grep()
  my $graph = Graph->new (undirected=>1);
  $graph->add_path(0,1);
  my $g6_str = MyGraphs::graph6_str_to_canonical
    (MyGraphs::Graph_to_graph6_str($graph));
  print MyGraphs::hog_grep($g6_str)?"HOG":"not", "\n";
  exit 0;
}

{
  # totdomnum max
  my @graphs = (
                # triangle with arms
                # https://hog.grinvin.org/ViewGraphInfo.action?id=28537
                '>>graph6<<G?`aeG',

                # tree
                '>>graph6<<G?`@f?',

                # tree
                '>>graph6<<G?B@dO',
               );
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # Harary and Palmer K4-e * 3 pseudosimilar

  # .  0   3---4   7
  # .  |   | / | / |
  # .  1---2---5---6
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30310

  my $graph = Graph->new (undirected=>1);
  $graph->add_path(0,1,2,3,4,5,6,7,5);
  $graph->add_path(4,2,5);
  my $u = 2;
  my $v = 5;
  MyGraphs::Graph_view($graph);

  my $gu = $graph->copy;
  my $gv = $graph->copy;
  $gu->delete_vertex($u);
  $gv->delete_vertex($v);
  print "isomorphic ",MyGraphs::Graph_is_isomorphic($gu,$gv),"\n";
  MyGraphs::Graph_view($gv);

  MyGraphs::hog_searches_html($graph);
  exit 0;
}

{
  # n=11 no duplicated leaf
  # https://hog.grinvin.org/ViewGraphInfo.action?id=28553
  # https://hog.grinvin.org/ViewGraphInfo.action?id=28555

  my $n = 11;
  my $formula = int((2*$n-1)/3);
  print "n=$n\n";
  print "formula $formula\n";

  my $iterator_func = MyGraphs::make_tree_iterator_edge_aref
    (num_vertices_min => $n,
     num_vertices_max => $n,
     connected => 1);
  my $count = 0;
  my @graphs;
  while (my $edge_aref = $iterator_func->()) {
    my $graph = MyGraphs::Graph_from_edge_aref($edge_aref, num_vertices => $n);
    next if Graph_has_duplicated_leaf($graph);
    my $indnum = MyGraphs::Graph_tree_indnum($graph);
    if ($indnum == $formula) {
      my $g6_str = MyGraphs::graph6_str_to_canonical
        (MyGraphs::Graph_to_graph6_str($graph));
      print "n=$n  ",MyGraphs::hog_grep($g6_str)?"HOG":"not", "\n";
      # MyGraphs::Graph_view($graph);
      # sleep 5;
      $count++;
      push @graphs, $graph;
    }
  }
  print "count $count\n";
  MyGraphs::hog_searches_html(@graphs);
  exit 0;

  sub Graph_has_duplicated_leaf {
    my ($graph) = @_;
    my %seen;
    foreach my $v ($graph->vertices) {
      if ($graph->vertex_degree($v) == 1) {
        my ($attachment) = $graph->neighbours($v);
        if ($seen{$attachment}++) {
          return 1;
        }
      }
    }
    return 0;
  }
}

{
  # n=27 minimal_domsets_count max
  # https://hog.grinvin.org/ViewGraphInfo.action?id=28551

  # non maximum, arms length 4
  # my $graph = MyGraphs::Graph_from_graph6_str(':Z_`abc`e`g`i`k_mnopmrmtmvmx');

  # maximum, 6,6
  my $graph = MyGraphs::Graph_from_graph6_str(':Z_`a`c`e`g`i`k_mnmpmrmtmvmx');
  MyGraphs::Graph_view($graph);
  print MyGraphs::Graph_tree_minimal_domsets_count($graph),"\n";
  MyGraphs::hog_searches_html($graph);

  # MyGraphs::Graph_view($graph);
  foreach (1 .. 20) {
    my $minimal_domsets_count
      = MyGraphs::Graph_tree_minimal_domsets_count($graph);
    print "count $minimal_domsets_count\n";
  }
  exit 0;
}
{
  # try Graph_tree_minimal_domsets_count()

  # 81 pairs 19,20  1649265868801
  # 12161^3      == 1798489329281

  require Graph;
  require Math::BigInt;
  Math::BigInt->import(try=>'GMP');
  require Math::BigFloat;
  my $base;
  foreach my $k (1 .. 5) {
    my $graph = make_T1 (6,6,$k);
    my $num_vertices = $graph->vertices;
    # MyGraphs::Graph_view($graph);
    my $count = MyGraphs::Graph_tree_minimal_domsets_count($graph);
    print "k=$k  count $count  n=$num_vertices\n";

    if ($k==1) { $base = $count; }
    else {
      my $pow = $base ** $k;
      print "           $pow\n";
      my $two = Math::BigFloat->new(2)**(($num_vertices)/2);
      print "   2^(n/2) $two\n";
    }
  }

  my $graph = make_T1 (19,20);
  my $minimal_domsets_count
    = MyGraphs::Graph_tree_minimal_domsets_count($graph);
  my $num_vertices = $graph->vertices;
  print "$num_vertices   count $minimal_domsets_count\n";
  exit 0;
}



{
  # Jou and Lin, "Independence Numbers in Trees", Open Journal of Discrete
  # Mathematics, volume 5, 2015, pages 27-31,
  # http://dx.doi.org/10.4236/ojdm.2015.53003

  # no duplicated leaf

  # GP-Test  my(k=4,n=3*k);   2*k-1 == 7 && n==12
  # GP-Test  my(k=4,n=3*k+1); 2*k   == 8 && n==13
  # GP-Test  my(k=4,n=3*k+2); 2*k+1 == 9 && n==14

  # n=15 indnum 9

  foreach my $n (# 12 .. 14,
                 11,
                ) {
    my $graph = make_extremal_nodupicated_leaf_indnum($n);
    MyGraphs::Graph_view($graph);
    my $indnum = MyGraphs::Graph_tree_indnum($graph);
    my $formula = int((2*$n-1)/3);
    print "n=$n  indnum $indnum formula $formula\n";
    $graph->vertices == $n or die;
  }
  exit 0;

  sub make_extremal_nodupicated_leaf_indnum {
    my ($n) = @_;
    my $graph = Graph->new (undirected=>1);
    $graph->set_graph_attribute (name => "n=$n");
    my $upto = 1;   # next prospective vertex number
    $graph->add_vertex($upto++);
    while ($upto <= $n) {
      ### $upto
      my $more = min(3, $n-$upto+1);
      $graph->add_path(1, $upto .. $upto+$more-1);
      $upto += $more;
    }
    return $graph;
  }
}



{
  # most indomsets

  # n=6   https://hog.grinvin.org/ViewGraphInfo.action?id=132
  # n=7   https://hog.grinvin.org/ViewGraphInfo.action?id=698
  # n=8   https://hog.grinvin.org/ViewGraphInfo.action?id=118
  # n=9   https://hog.grinvin.org/ViewGraphInfo.action?id=28526
  # n=10  https://hog.grinvin.org/ViewGraphInfo.action?id=658
  my @graphs;
  foreach my $n (6 .. 20) {
    my $graph = MyGraphs::Graph_make_most_indomsets($n);
    my $g6_str = MyGraphs::graph6_str_to_canonical
      (MyGraphs::Graph_to_graph6_str($graph));
    print "n=$n  ",MyGraphs::hog_grep($g6_str)?"HOG":"not", "\n";
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # most minimum dominating sets

  my @graphs = ('>>graph6<<D]w',  # n=5      got
                '>>graph6<<E]~o',  # n=6     got
                '>>graph6<<FCZbg',  # n=7    got
                '>>graph6<<GCxvBo',  # n=8
               );
  foreach my $graph6 (@graphs) {
    MyGraphs::Graph_print_tikz(MyGraphs::Graph_from_graph6_str($graph6));
    print "---------\n";
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # most maximum independent sets
  # https://hog.grinvin.org/ViewGraphInfo.action?id=496

  MyGraphs::hog_searches_html('>>graph6<<DQw',  # n=5
                              '>>graph6<<DUW',  # n=5 cycle
                              '>>graph6<<EQjO',  # n=6
                              '>>graph6<<FQhVO',  # n=7
                              '>>graph6<<GQhTUg',  # n=8
                              '>>graph6<<HCOcaRc',  # n=9
                             );
  exit 0;
}
{
  print MyGraphs::hog_grep("E?CW\n");
  exit 0;
}


{
  # path-4 plus middle leaf
  # https://hog.grinvin.org/ViewGraphInfo.action?id=496

  require Graph::Maker::Linear;
  my $graph = Graph::Maker->new('linear', N=>5, undirected=>1);
  $graph->add_edge(3,6);
  MyGraphs::Graph_view($graph);
  MyGraphs::hog_searches_html($graph);
  exit 0;
}

{
  # 5-cycle
  # https://hog.grinvin.org/ViewGraphInfo.action?id=340

  require Graph::Maker::Cycle;
  my $graph = Graph::Maker->new('cycle', N=>5, undirected=>1);
  MyGraphs::Graph_view($graph);
  MyGraphs::hog_searches_html($graph);
  exit 0;
}

{
  # bicentral and bicentroidal  disjoint

  # https://hog.grinvin.org/ViewGraphInfo.action?id=28234
  # 3  2
  #   \|
  # 4--1--7--8--9--10--11--12
  #   /|
  # 5  6

  require Graph::Maker::Star;
  my $graph = Graph::Maker->new('star', N=>7, undirected=>1);
  $graph->add_path(7,8,9,10,11,12);
  MyGraphs::Graph_view($graph);
  MyGraphs::hog_searches_html($graph);
  exit 0;
}
{
  # centre and centroid disjoint

  my @graphs;
  {
    # https://hog.grinvin.org/ViewGraphInfo.action?id=792
    # file:///so/hog/graphs/792.html
    #             *
    #             |
    # *---*---C---G---*
    #             |
    #             *
    my $graph = Graph->new (undirected=>1);
    $graph->add_path(1,2,3,4,5);
    $graph->add_path(6,4,7);
    push @graphs, $graph;
  }
  {
    # https://hog.grinvin.org/ViewGraphInfo.action?id=28225
    #           *   *
    #            \ /
    # *---*---C---G---*
    #             |
    #             *
    my $graph = Graph->new (undirected=>1);
    $graph->add_path(1,2,3,4,5);
    $graph->add_path(6,4,7);
    $graph->add_path(4,8);
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # n=8 cyclic domnum=4
  #
  # triangle with 3x1 and 1x2 hanging
  # hog not
  #    *---*---*---*  
  #        | \
  #    *---*---*---*
  #
  # square with extra vertex each
  # https://hog.grinvin.org/ViewGraphInfo.action?id=48
  # file:///so/hog/graphs/48.html
  #    *---*---*---*  
  #        |   |
  #    *---*---*---*
  #
  # square with cross edge and extra vertex each
  # hog not
  #    *---*---*---*  
  #        | / |
  #    *---*---*---*
  #
  # tetrahedral (complete-4) with extra vertex each
  # https://hog.grinvin.org/ViewGraphInfo.action?id=228
  # file:///so/hog/graphs/228.html
  #    *---*---*---*  
  #        | X |
  #    *---*---*---*

  my @graphs;
  foreach my $g6 ('>>graph6<<G?`DEc',
                  '>>graph6<<G?`FE_',
                  '>>graph6<<G?`FEc',
                  '>>graph6<<G?bDKk',
                 ) {
    push @graphs, $g6;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}




{
  # maximum induced claws

  # star-7
  # https://hog.grinvin.org/ViewGraphInfo.action?id=622
  #
  # bipartite 5,2
  # https://hog.grinvin.org/ViewGraphInfo.action?id=866

  # bipartite 5,2 with edge between 2
  # https://hog.grinvin.org/ViewGraphInfo.action?id=580

  my @graphs;
  foreach my $g6 ('>>graph6<<F??Fw',  # star-7
                  '>>graph6<<F?B~o',  # bipartite 5,2
                  '>>graph6<<F?B~w',  # bipartite 5,2 with edge between 2
                 ) {
    push @graphs, $g6;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # bipartite claw count

  # star-n < complete bipartite n-2,2 for n>=8

  # complete n,3
  # star_claws(n) = binomial(n-1,3);  \\ (n-1)(n-2)(n-3)/6
  # complete_bipartite_claws(n,m) = n*binomial(m,3) + m*binomial(n,3);
  # complete_bipartite_claws(0,3)
  # vector(10,n, star_claws(n))
  # vector(10,n, (n-1)*(n-2)*(n-3)/6)
  # vector(10,n, complete_bipartite_claws(n-1,1))
  # vector(10,n, complete_bipartite_claws(n-2,2))
  # vector(10,n, (n-2)*(n-3)*(n-4)/3)
  # vector(10,n, complete_bipartite_claws(floor(n/2),ceil(n/2)))

  # vector(10,n, (n-2)*(n-3)*(n-4)/3) - vector(10,n, (n-1)*(n-2)*(n-3)/6)
  # vector(10,n, (n-2)*(n-3)*(n-7)/6)
  # my(n=7); (n-2)*(n-3)*(n-7)/6
  # my(n=8); (n-2)*(n-3)*(n-7)/6

  # read("vpar.gp");
  # matrix(5,5,n,m,n++;m++; vpar_claw_count(vpar_make_bistar(n,m)))

  require Graph::Maker::CompleteBipartite;
  foreach my $n (2 .. 8) {
    foreach my $m (2 .. 8) {
      my $graph = Graph::Maker->new('complete_bipartite', N1 => $n, N2 => $m,
                                    undirected => 1);
      # if ($n == $m && $n == 4) {
      #   MyGraphs::Graph_view($graph);
      # }
      printf "%4d", MyGraphs::Graph_claw_count($graph);
    }
    print "\n";
  }

  foreach my $n (2 .. 6) {
    foreach my $m (2 .. 6) {
      my $graph = Graph::Maker->new('complete_bipartite', N1 => $n, N2 => $m,
                                    undirected => 1);
      my $count = $n*binomial($m,3) + $m*binomial($n,3);
      printf "%4d", $count;
    }
    print "\n";
  }
  print "\n";

  foreach my $n (2 .. 6) {
    foreach my $m (2 .. 6) {
      my $count = binomial($n+$m,3);
      printf "%4d", $count;
    }
    print "\n";
  }
  exit 0;

  # seq1 => [($m)x$n],
  # seq2 => [($n)x$m],

  sub binomial {
    my ($n, $m) = @_;
    my $ret = 1;
    foreach my $i ($n-$m+1 .. $n) {
      $ret *= $i;
    }
    foreach my $i (1 .. $m) {
      $ret /= $i;
    }
    return $ret;
  }
}

{
  # claw-free graphs
  require Graph;
  require Graph::Writer::Sparse6;
  foreach my $num_vertices (5) {

    my $iterator_func = MyGraphs::make_graph_iterator_edge_aref
      (num_vertices_min => $num_vertices,
       num_vertices_max => $num_vertices,
       connected => 1,
      );
    my @graphs;
    while (my $edge_aref = $iterator_func->()) {
      my $graph = MyGraphs::Graph_from_edge_aref($edge_aref,
                                                 num_vertices => $num_vertices);
      my $has_claw = MyGraphs::Graph_has_claw($graph);
      if ($has_claw) {
        Graph::Writer::Sparse6->new->write_graph($graph,\*STDOUT);
        MyGraphs::Graph_view($graph);
      } else {
        push @graphs, $graph;
      }
    }
    my $num_graphs = scalar(@graphs);
    print "N=$num_vertices [$num_graphs] ";
  }
  exit 0;
}
{
  # cycle maximal independent sets

  require Graph::Maker::Cycle;
  require MyGraphs;
  my @values;
  foreach my $n (3 .. 10) {
    my $graph = Graph::Maker->new('cycle', N => $n, undirected => 1);
    MyGraphs::Graph_view($graph);
    # my $count = MyGraphs::Graph_tree_maximal_indsets_count($graph);
    # push @values, $count;
  }
  # require Math::OEIS::Grep;
  # Math::OEIS::Grep->search(array => \@values, verbose=>1);
  exit 0;
}


{
  # n=12

  #    / *--*              2
  #   *--*--*--*--*        4
  #    \ *--*--*--*--*     5
  #              1 2 3 4 5 6 7 8 9 10 11 12
  # vpar  n=12   0 1 2 3 4 5 2 7 1  9 10 11

  require Graph;
  require Algorithm::ChooseSubsets;
  my $graph = Graph->new (undirected=>1);

  $graph->add_path('01','02','03','04','05','06');
  $graph->add_path(     '02','07','08');
  $graph->add_path('01','09','10','11','12');

  # $graph->add_path('01','02','03','04','05','12');
  # $graph->add_path('06','07','08','09',     '12');
  # $graph->add_path('10','11',               '12');

  # MyGraphs::Graph_view($graph);
  print "by pred ", MyGraphs::Graph_minimal_domsets_count_by_pred($graph),"\n";
  mindomset_parts_show($graph, '01', print=>1);

  foreach (1 .. 20) {
    my $minimal_domsets_count
      = MyGraphs::Graph_tree_minimal_domsets_count($graph);
    print "count $minimal_domsets_count\n";
  }
  exit 0;

  sub is_domset_without_dom_notsole {
    my ($graph, $aref, $v) = @_;
    if (grep {$_==$v} @$aref) { return 0; }
    $graph = $graph->copy;
    my $extra = 'is_domset_without_sole';
    $graph->add_edge ($v, $extra);
    return MyGraphs::Graph_is_minimal_domset($graph, [$extra,@$aref]);
  }

  sub is_domset_with_notmin_unless_undom_above {
    my ($graph, $aref, $v) = @_;
    if (! grep {$_==$v} @$aref) { return 0; }
    if (MyGraphs::Graph_is_minimal_domset($graph,$aref)) { return 0; }
    $graph = $graph->copy;
    my $extra = 'is_domset_with_notmin_unless_undom_above';
    $graph->add_edge ($v, $extra);
    return MyGraphs::Graph_is_minimal_domset($graph, $aref);
  }

  sub mindomset_parts_show {
    my ($graph, $root, %options) = @_;
    my $total = 0;
    my $with        = 0;
    my $without_dom = 0;
    my $without_dom_notsole = 0;
    my $with_notmin_unless_undom_above = 0;
    my @vertices = sort $graph->vertices;
    my $it = Algorithm::ChooseSubsets->new(\@vertices);
    while (my $aref = $it->next) {
      if (is_domset_with_notmin_unless_undom_above($graph,$aref,$root)) {
        $with_notmin_unless_undom_above++;
      }

      if (MyGraphs::Graph_is_minimal_domset($graph,$aref)) {
        my $contains = sub {
          my ($v) = @_;
          return !! (grep {$_==$v} @$aref);
        };

        $total++;
        my $is_with = $contains->($root);
        my $is_without_dom = ! $is_with;
        my $is_without_dom_notsole = $is_without_dom
          && is_domset_without_dom_notsole($graph,$aref,$root);
        my $is_without_dom_sole = $is_without_dom
          && ! $is_without_dom_notsole;
        $with                += $is_with;
        $without_dom         += $is_without_dom;
        $without_dom_notsole += $is_without_dom_notsole;

        #       /-7--8            2
        #   1--2--3--4--5--6      6
        #    \-9-10-11-12         4

        my $show = sub {
          my ($v) = @_;
          return $contains->($v) ? '*' : '.';
        };
        if ($options{'print'}) {
          print "    /-",$show->('07'),"--",$show->('08'),"    ",$is_without_dom_sole?' sole':'',"\n";
          print $show->('01'),"--",$show->('02'),"--",$show->('03'),"--",$show->('04'),"--",$show->('05'),"--",$show->('06'),"\n";
          print " \\-",$show->('09'),"--",$show->('10'),"--",$show->('11'),"--",$show->('12'),"\n";
          print "\n";
        }
      }
    }
    my $without_dom_sole = $without_dom - $without_dom_notsole;
    ### $with_notmin_unless_undom_above
    ### $with
    ### $without_dom
    ### $without_dom_sole
    ### $without_dom_notsole
    ### $total
  }
}
{
  # try Graph_tree_minimal_domsets_count()

  # 81 pairs 19,20  1649265868801
  # 12161^3      == 1798489329281
  # k=3  count      1798489329281

  require Graph;
  require Math::BigInt;
  Math::BigInt->import(try=>'GMP');
  # for (my $n = 9; $n <= 55; $n += 2) {
  foreach my $n (3*27) {
    my $max_count = 0;
    my $max_L_pairs = 0;
    my $max_R_pairs = 0;
    my $pairs = ($n-3)/2;
    foreach my $L_pairs (0 .. int($pairs/2)) {
      my $R_pairs = $pairs - $L_pairs;
      my $graph = make_T1 ($L_pairs, $R_pairs);
      my $minimal_domsets_count
        = MyGraphs::Graph_tree_minimal_domsets_count($graph);
      print "n=$n pairs $L_pairs+$R_pairs = $pairs  count $minimal_domsets_count\n";

      if ($max_count < $minimal_domsets_count) {
        $max_count = $minimal_domsets_count;
        $max_L_pairs = $L_pairs;
        $max_R_pairs = $R_pairs;
      }
    }
    print "max L_pairs $max_L_pairs R_pairs $max_R_pairs  count $max_count\n";
    print "\n";
  }
  exit 0;

  sub make_T1 {
    my ($L_pairs, $R_pairs, $k) = @_;
    $k ||= 1;
    my @pairs = shift; push @pairs, shift;
    my $graph = Graph->new (undirected => 1);
    my $from;
    foreach my $kk (1 .. $k) {
      foreach my $side (0,1) {
        my $side_name = ($side == 0 ? 'L' : 'R');
        foreach my $i (1 .. $pairs[$side]) {
          $graph->add_path ("${side_name}_leaf_${i}_k$kk",
                            "${side_name}_mid_${i}_k$kk",
                            "${side_name}_k$kk");
        }
      }
      $graph->add_path ("L_k$kk","T_k$kk","R_k$kk");
      if (defined $from) {
        my $to = "L_mid_1_k$kk";
        $graph->add_edge ($from, $to);
      }
      $from = "R_mid_1_k$kk",
    }
    return $graph;
  }
}
{
  # path minimal domsets parts
  # 2+4+5 + 1 == 12

  # p1      with_notmin_unless_undom_above_gross => 6
  #         without_undom => 2
  #         with_notmin_unless_undom_above = 4
  # path-4  without_undom => 1
  #
  # p1      without_undom => 2
  # path-4  with_notmin_unless_undom_above_gross => 1
  #         without_undom => 1
  #         with_notmin_unless_undom_above = 0


  require Algorithm::ChooseSubsets;
  require Graph::Maker::Linear;
  my @path_graphs;
  my @data;
  foreach my $n (0 .. 7) {
    my $graph = Graph::Maker->new('linear', N => $n, undirected => 1);
    my $data = MyGraphs::Graph_tree_minimal_domsets_count_data($graph);
    printf "n=%2d   %s  %2s-%2s  %2s-%s  %s  notmin %s\n",
      $n,
      $data->{'with_req_notbelow'},
      $data->{'with_req_below_gross'}, $data->{'with_req_below_sub'},
      $data->{'without_dom_notsole_gross'}, $data->{'without_undom'},
      $data->{'without_dom_sole'},
      $data->{'with_notmin_unless_undom_above_gross'};
    $data[$n] = $data;
    $path_graphs[$n] = $graph;
  }

  # n= 2   0   1- 0   1-0  0
  # n= 4   1   2- 1   2-1  1
  # n= 5   0   2- 0   2-0  0

  #       /-*--*            2
  #   *--*--*--*--*--*      6
  #    \-*--*--*--*         4

  ### path-2 ...
  ### data: $data[2]

  ### path-4 ...
  ### data: $data[4]

  my $p1 = MyGraphs::tree_minimal_domsets_count_data_product($data[4],$data[2]);
  ### $p1
  ### p1 with_notmin_unless_undom_above: $p1->{'with_notmin_unless_undom_above_gross'} - $p1->{'without_undom'}
  ### p1 without_dom_sole   : $p1->{'without_dom_sole'}
  ### p1 without_dom_notsole: $p1->{'without_dom_notsole_gross'} - $p1->{'without_undom'}
  ### p1 without_dom        : $p1->{'without_dom_notsole_gross'} - $p1->{'without_undom'} + $p1->{'without_dom_sole'}
  my $p1_ret    = MyGraphs::tree_minimal_domsets_count_data_ret($p1);
  my $path7_ret = MyGraphs::tree_minimal_domsets_count_data_ret($data[7]);
  ### p1        : "$p1_ret"
  ### cf path-7 : "$path7_ret"

  ### p1 ...
  mindomset_parts_show($path_graphs[7], '3', print=>0);

  ### path-4: $data[4]

  my $r = MyGraphs::tree_minimal_domsets_count_data_product($p1, $data[4]);
  ### $r
  ### r with       : $r->{'with_req_notbelow'} + $r->{'with_req_below_gross'} - $r->{'with_req_below_sub'}
  ### r without dom: $r->{'without_dom_notsole_gross'} - $r->{'without_undom'} + $r->{'without_dom_sole'}
  ### r without dom sole   : $r->{'without_dom_sole'}
  ### r without dom notsole: $r->{'without_dom_notsole_gross'} - $r->{'without_undom'}

  my $minimal_domsets_count = MyGraphs::tree_minimal_domsets_count_data_ret($r);
  ### $minimal_domsets_count

  exit 0;
}


{
  # try Graph_tree_minimal_domsets_count()

  require Graph::Maker::BalancedTree;
  require Graph::Maker::Linear;
  my $num_children = 2;
  foreach my $n (1 .. 6) {
    my $graph = Graph::Maker->new('balanced_tree',
                                  fan_out => $num_children, height => $n,
                                  undirected => 1,
                                 );
    # my $graph = Graph::Maker->new('linear', N => $n, undirected => 1);

    my $minimal_domsets_count
      = MyGraphs::Graph_tree_minimal_domsets_count($graph);
    print "n=$n  $minimal_domsets_count\n";
  }
  exit 0;
}

{
  # v_mindomsets = v_with + v_without_dom
  #
  # v_with =   prod(c_with_req_below + c_without)
  #          - prod(c_with_req_below)
  # at least one c_without
  #
  # v_without_dom =   prod(c_without_dom + c_with)
  #                 - prod(c_without_dom)
  # at least one c_with
  #
  # v_without_dom += exactly_one_notmin
  # exactly_one_notmin = exactly_one_notmin * c_without_dom
  #                    + prod_c_without_dom * c_with_notmin_unless_undom_above
  # prod_c_without_dom *= c_without_dom

  #           0 1 2 3 4 5 6 7  8  9 10
  # want path 1,1,2,2,4,4,7,9,13,18,25,36,49,70,97,137,191,268,376,526,738,

  #             0 1 2 3 4
  # want binary 1,2,4,41,1438

  # leaf
  my $v_with_req_notbelow       = 1;
  my $v_with_req_below      = 0;
  my $v_with_notmin_unless_undom_above = 0;
  my $v_without_dom_sole    = 0;
  my $v_without_dom_notsole = 0;
  my $v_without_undom       = 1;
  my $fan = 1;

  {
    my $n = 1;
    my $v_mindomsets = $v_with_req_notbelow + $v_with_req_below
      + $v_without_dom_sole + $v_without_dom_notsole;
    print "n=$n mindomsets $v_mindomsets  with $v_with_req_notbelow+$v_with_req_below  without $v_without_dom_sole+$v_without_dom_notsole+$v_without_undom    req below $v_with_req_below notmin unless $v_with_notmin_unless_undom_above\n";
  }

  foreach my $n (2 .. 8) {
    my $c_without_dom_sole    = $v_without_dom_sole;
    my $c_without_dom_notsole = $v_without_dom_notsole;
    my $c_without_undom       = $v_without_undom;
    my $c_with_req_notbelow       = $v_with_req_notbelow;
    my $c_with_req_below      = $v_with_req_below;
    my $c_with                = $c_with_req_notbelow + $c_with_req_below;
    my $c_with_notmin_unless_undom_above = $v_with_notmin_unless_undom_above;
    my $c_without_dom = $c_without_dom_sole + $c_without_dom_notsole;

    ### $n
    ### $c_with_req_notbelow
    ### $c_with_req_below
    ### $c_with
    ### $c_with_notmin_unless_undom_above
    ### $c_without_dom_sole
    ### $c_without_dom_notsole
    ### $c_without_undom

    #----

    # =0 child undom
    $v_with_req_notbelow = ($c_without_dom_notsole)**$fan;

    # >=1 child undom
    $v_with_req_below
      = ($c_with_req_below + $c_without_dom_notsole + $c_without_undom)**$fan
      - ($c_with_req_below + $c_without_dom_notsole                   )**$fan;


    # =1 child with notmin unless undom above,
    # this v without cannot be re-dominated above
    $v_without_dom_sole
      = $fan* $c_without_dom**($fan-1) * $c_with_notmin_unless_undom_above;

    # =0 child with
    $v_without_undom = $c_without_dom**$fan;

    # >=1 child with
    $v_without_dom_notsole
      = ($c_with           + $c_without_dom)**$fan
      - $v_without_undom;
    # - (                    $c_without_dom)**$fan;

    # at least one c_with
    $v_with_notmin_unless_undom_above
      = ($c_with_req_below + $c_without_dom)**$fan
      - $v_without_undom;
    #   (                    $c_without_dom)**$fan;

    my $v_with        = $v_with_req_notbelow + $v_with_req_below;
    my $v_without_dom = $v_without_dom_sole + $v_without_dom_notsole;
    my $v_mindomsets = $v_with + $v_without_dom;

    print "n=$n mindomsets $v_mindomsets  with $v_with  without $v_without_dom_sole + $v_without_dom_notsole + $v_without_undom  req below $v_with_req_below notmin unless $v_with_notmin_unless_undom_above\n";
  }

  # with = (1 + 3) - 1 = 3
  # 1,3,5
  # 2,3,5 <-- not minimal
  #  2, 5

  exit 0;
}
{
  # counts of minimal dominating sets

  # h=2 complete binary tree
  # 1              1 1,0 plus 1      with
  # 2,3            1 0,1 plus 0      without notsole
  # none without undom

  # h=3 complete binary tree
  # 1,4,5,6,7      1 1,0 plus 1      with, and is req below
  # 2,3            1 0,1 plus 0      without notsole
  # 2,6,7          1 0,1 plus 0      without notsole
  # 3,4,5          1 0,1 plus 0      without notsole
  # 4,5,6,7                          without undom
  # 1,2,3          0 0,0 plus 1
  # 1,2,6,7        0 0,0 plus 1
  # 1,3,4,5        0 0,0 plus 1
  #
  #  with req   without   undom
  # (    1    +   1     +  0)^2 = 4    - 1^2 = 3
  # 1,4,5,3    not minimal, as 1 covered
  # 1,2,6,7    not minimal, as 1 covered

  # n=4 path
  # 1,4            1 1,0 plus 1      with
  # 2,4            1 0,1 plus 0      with
  # 1,3            1 1,0 plus 1      without dom notsole
  # 2,3            1 0,1 plus 0      without dom sole
  #  2                               without undom

  # n=5 path with 2, without 2
  # 1,3,5          1 1,0 plus 1      with
  # 2,5            1 0,1 plus 0      with
  # 1,4            1 1,0 plus 1      without dom notsole
  # 2,4            1 0,1 plus 0      without dom notsole
  #  1,3                             without undom   from 4 without dom notsole
  #  2,3                             without undom   from 4 without dom sole
  # 1,2,5          0 0,0 plus 1
  # minimal domsets         4
  # minimal domsets with    2
  # minimal domsets without 2

  # n=6 path
  # 1,4,6          1 1,0 plus 1      with   from 5 dom notsole
  # 2,4,6          1 0,1 plus 0      with   from 5 dom notsole
  # 1,3,6          1 1,0 plus 1      with   from 5 undom
  # 2,3,6          1 0,1 plus 0      with   from 5 undom
  # 2,5            1 0,1 plus 0      without notsole
  # 1,3,5          1 1,0 plus 1      without notsole
  # 1,4,5          1 1,0 plus 1      without sole
  # 1,2,5          0 0,0 plus 1      without undom


  require Algorithm::ChooseSubsets;
  require Graph::Maker::BalancedTree;
  require Graph::Maker::Linear;
  my $num_children = 2;
  my $n = 2;
  my $graph = Graph::Maker->new('balanced_tree',
                                fan_out => $num_children, height => $n,
                                undirected => 1,
                               );
  # my $graph = Graph::Maker->new('linear', N => $n, undirected => 1);

  my $root = 1;
  my $graph_plus = $graph->copy;
  $graph_plus->add_edge ($root,'extra');

  # MyGraphs::Graph_view($graph);
  print "graph $graph\n";
  print "graph_plus $graph_plus\n";

  my @vertices = sort {$a<=>$b} $graph->vertices;
  my $it = Algorithm::ChooseSubsets->new(\@vertices);
  my $count_domsets = 0;
  my $count_minimal_domsets = 0;
  my $count_minimal_domsets_with = 0;
  my $count_minimal_domsets_without = 0;
  while (my $aref = $it->next) {
    my $any = 0;

    my $is_domset = MyGraphs::Graph_is_domset($graph,$aref) ? 1 : 0;
    # $any ||= $is_domset;
    $count_domsets += $is_domset;

    my $is_minimal_domset = MyGraphs::Graph_is_minimal_domset($graph,$aref)?1:0;
    $any ||= $is_minimal_domset;
    $count_minimal_domsets += $is_minimal_domset;

    my $includes_root = grep {$_ eq $root} @$aref;
    my $is_minimal_domset_with    =  $includes_root & $is_minimal_domset;
    my $is_minimal_domset_without = !$includes_root & $is_minimal_domset;

    $count_minimal_domsets_with    += $is_minimal_domset_with;
    $count_minimal_domsets_without += $is_minimal_domset_without;

    my $plus_is_minimal_domset = MyGraphs::Graph_is_minimal_domset($graph_plus,$aref)?1:0;
    $any ||= $plus_is_minimal_domset;

    if ($any) {
      my $aref_str = join(',',@$aref);
      printf "%-14s %d %d %d,%d plus %d\n",
        $aref_str, $is_domset,
        $is_minimal_domset, $is_minimal_domset_with,$is_minimal_domset_without,
        $plus_is_minimal_domset;
    }
  }
  print "domsets $count_domsets\n";
  print "minimal domsets         $count_minimal_domsets\n";
  print "minimal domsets with    $count_minimal_domsets_with\n";
  print "minimal domsets without $count_minimal_domsets_without\n";
  exit 0;
}


{
  #     *---*
  #     |   |
  # *---*---*---*
  #     |   |
  #     *   *
  # hog not

  require Graph;
  my $graph = Graph->new (undirected => 1);
  $graph->add_cycle (1,2,3,4);
  $graph->add_edge('1a',1);
  $graph->add_edge('1b',1);
  $graph->add_edge('2a',2);
  $graph->add_edge('2b',2);
  MyGraphs::hog_searches_html($graph);
  exit 0;
}
{
  # T1
  # hog not
  require Graph;
  my $graph = Graph->new (undirected => 1);
  foreach my $side ('L','R') {
    foreach my $i (1 .. 6) {
      $graph->add_path ("${side}t$i","${side}s$i",$side);
    }
  }
  $graph->add_path ('L','T','R');
  # MyGraphs::Graph_view($graph);
  MyGraphs::hog_searches_html($graph);
  exit 0;
}

{
  # path minimals 1,1,2,2,4,4,7,9,13,18,25,36,49

  require Graph::Maker::BalancedTree;
  require Graph::Maker::Linear;
  my $num_children = 2;
  foreach my $n (5) {
    # my $graph = Graph::Maker->new('balanced_tree',
    #                               fan_out => $num_children, height => $n,
    #                               undirected => 1,
    #                              );
    my $graph = Graph::Maker->new('linear', N => $n, undirected => 1);
    MyGraphs::Graph_tree_domsets_count($graph);
    my $count = MyGraphs::Graph_tree_minimal_domsets_count($graph);
    print "n=$n  domsets count $count\n";
  }
  exit 0;
}

{
  require Graph::Maker::BalancedTree;
  my $num_children = 2;
  foreach my $h (0 .. 10) {
    my $graph = Graph::Maker->new('balanced_tree',
                                  fan_out => $num_children, height => $h,
                                  undirected => 1,
                                 );
    my $domnum = MyGraphs::Graph_tree_domnum($graph);
    print "h=$h  domnum $domnum\n";
  }
  exit 0;
}

{
  # cubefree substring relations
  # 11,19,31,49,77,117
  # v = apply(n->2*n+1,[11,19,31,49,77,117])
  # vector(#v-1,i,v[i+1]-v[i]) \\ A028445 cubefrees

  my $max_len = 3;
  my $delta1 = 1;
  my $prefix = 1;

  my @cubefrees = ('');
  {
    my @pending = ('');
    foreach my $len (1 .. $max_len) {
      my @new_pending;
      foreach my $str (@pending) {
        foreach my $ext ('0','1') {
          my $new_str = $str.$ext;
          if (is_cubefree($new_str)) {
            push @new_pending, $new_str;
          }
        }
      }
      @pending = @new_pending;
      push @cubefrees, @pending;
    }
  }
  my $num_vertices = scalar(@cubefrees);
  print "num_vertices = $num_vertices\n";

  require Graph;
  my $graph = Graph->new (undirected => 1);
  $graph->set_graph_attribute
    (name => "Cubefree Substring Relations, Max Length $max_len");
  $graph->set_graph_attribute (root => "!");
  foreach my $from_i (0 .. $#cubefrees) {
    my $from_str = $cubefrees[$from_i];
    foreach my $to_i (0 .. $from_i-1) {
      my $to_str = $cubefrees[$to_i];
      if ($delta1) {
        next unless length($from_str) - length($to_str) == 1;
      }
      my $pos = index($from_str,$to_str);
      if ($prefix) {
        next unless $pos==0;
      }
      if ($pos >= 0) {
        my $from_str = (length($from_str) ? $from_str : '!');
        my $to_str = (length($to_str) ? $to_str : '!');
        $graph->add_edge($from_str, $to_str);
      }
    }
  }

  MyGraphs::Graph_view($graph);
  print "tree\n";
  MyGraphs::Graph_tree_print($graph, cmp => \&MyGraphs::cmp_alphabetic);
  # Graph_print_tikz($graph);
  # MyGraphs::hog_searches_html($graph);
  exit 0;

  sub find_cube {
    my ($str) = @_;
    foreach my $c (1 .. int(length($str)/3)) {
      my $re = '('.('.' x $c).')\\1\\1';
      ### $re
      if ($str =~ $re) {
        ### $str
        ### cube: $1
        return $1;
      }
    }
    return undef;
  }
  sub is_cubefree {
    my ($str) = @_;
    return ! defined find_cube($str);
  }
}

{
  # subgraph relations among all graphs to N vertices -- graph drawing
  #
  # N=4
  #   all graphs          = mucho edges  [hog not]
  #     complement = some disconnecteds
  #     https://hog.grinvin.org/ViewGraphInfo.action?id=26965
  #   all graphs, delta 1 = diam 6
  #     https://hog.grinvin.org/ViewGraphInfo.action?id=26963
  #   connected graphs    = complete-6 less 3 edges (in a path)
  #     https://hog.grinvin.org/ViewGraphInfo.action?id=748
  #   connected, delta 1  = square plus 2  "A Graph"
  #     https://hog.grinvin.org/ViewGraphInfo.action?id=945
  #     http://mathworld.wolfram.com/AGraph.html
  # N=3
  #   all graphs          = complete-4
  #   all graphs, delta 1 = path-4
  #   connected graphs    = path-2

  my $num_vertices = 4;
  my $connected = 0;
  my $delta1 = 0;
  my $complement = 1;

  require Graph;
  my $iterator_func = MyGraphs::make_graph_iterator_edge_aref
    (num_vertices_min => $num_vertices,
     num_vertices_max => $num_vertices,
     connected => $connected,
    );
  my @graphs;
  while (my $edge_aref = $iterator_func->()) {
    ### graph: edge_aref_string($edge_aref)
    push @graphs, Graph_from_edge_aref($edge_aref,
                                       num_vertices => $num_vertices);
  }
  print "total ",scalar(@graphs)," graphs\n";
  my $graph = Graph->new (undirected => 1);
  $graph->set_graph_attribute
    (name => "Subgraph Relations N=$num_vertices, "
     . ($connected ? ' Connected' : 'All'));
  foreach my $i (0 .. $#graphs) {
    my $n = $graphs[$i]->vertices;
    my $c = $graphs[$i]->is_connected ? 'C' : 'nc';
    my $s = "$graphs[$i]";
    print "$i [v=$n $s] subgraphs: ";
    foreach my $j (0 .. $#graphs) {
      next if $i==$j;
      if ($delta1
          && abs(scalar($graphs[$i]->edges)
                 - scalar($graphs[$j]->edges)) > 1) {
        next;
      }
      if (Graph_is_subgraph($graphs[$i], $graphs[$j])) {
        print "$j, ";
        $graph->add_edge($i, $j);
      }
    }
    print "\n";
  }

  my @named;
  require Graph::Maker::Star;
  push @named, [$num_vertices==4 ? 'claw' : 'star',
                Graph::Maker->new('star', N=>$num_vertices, undirected=>1)];

  require Graph::Maker::Linear;
  push @named, ['path',
                Graph::Maker->new('linear', N=>$num_vertices, undirected=>1)];

  require Graph::Maker::Complete;
  push @named, ['complete',
                Graph::Maker->new('complete', N=>$num_vertices, undirected=>1)];

  require Graph::Maker::Disconnected;
  push @named, ['disconnected',
                Graph::Maker->new('disconnected',
                                  N=>$num_vertices, undirected=>1)];

  require Graph::Maker::Cycle;
  push @named, ['cycle',
                Graph::Maker->new('cycle', N=>$num_vertices, undirected=>1)];
  {
    my $g = Graph::Maker->new('cycle', N=>$num_vertices, undirected=>1);
    $g->add_edge(1,int(($num_vertices+2)/2));
    push @named, ['cycle across',$g];
  }
  if ($num_vertices >= 4) {
    my $n = $num_vertices-1;
    my $g = Graph::Maker->new('cycle', N=>$n, undirected=>1);
    $g->add_edge(1,$num_vertices);
    push @named, ["cycle$n hanging",$g];
  }
  if ($num_vertices >= 4) {
    my $n = $num_vertices-1;
    my $g = Graph::Maker->new('cycle', N=>$n, undirected=>1);
    $g->add_vertex($num_vertices);
    push @named, ["cycle$n disc",$g];
  }
  foreach my $i (1 .. $num_vertices-1) {
    my $g = Graph::Maker->new('linear', N=>$i, undirected=>1);
    $g->add_vertices(1 .. $num_vertices);
    push @named, ["p-$i",$g];
  }
  if ($num_vertices >= 4) {
    my $g = Graph->new(undirected=>1);
    $g->add_vertices(1 .. $num_vertices);
    $g->add_edge(1,2);
    $g->add_edge(3,4);
    push @named, ["2-sep",$g];
  }
  foreach my $i (0 .. $#graphs) {
    foreach my $elem (@named) {
      if (Graph_is_isomorphic($graphs[$i],$elem->[1])) {
        print "$i = $elem->[0]\n";
        Graph_rename_vertex($graph, $i, $elem->[0]);
        last;
      }
    }
  }

  print "graph ",scalar($graph->edges)," edges ",
    scalar($graph->vertices), " vertices\n";

  if ($complement) {
    print "complement\n";
    $graph = complement($graph);
    print "graph ",scalar($graph->edges)," edges ",
      scalar($graph->vertices), " vertices\n";
    $graph->set_graph_attribute
      (name => $graph->get_graph_attribute('name') . ', Complement');
  }

  Graph_view($graph);
  Graph_print_tikz($graph);
  hog_searches_html($graph);
  exit 0;

  sub complement {
    my ($graph) = @_;
    my @vertices = $graph->vertices;
    $graph = $graph->complement;
    $graph->add_vertices(@vertices);
    return $graph;
  }
}

{
  # subgraph relations among graphs to N vertices -- counts
  #
  # all graphs:
  #   count
  #     0,1,6,46,409,6945
  #   count delta1
  #     0,1,3,14,74,571
  #     A245246 Number of ways to delete an edge (up to the outcome) in the simple unlabeled graphs on n nodes.
  #     A245246 ,0,1,3,14,74,571,6558,125066,4147388,
  #   non count
  #     0,0,0,9,152
  #   non count, both ways
  #     0,1,6,64,713
  #   total count, n*(n-1)/2 of A000088 num graphs 1,1,2,4,11,34,156,
  #     0,1,6,55,561
  #     apply(n->n*(n-1)/2, [1,1,2,4,11,34,156])==[0,0,1,6,55,561,12090]
  #
  # connected graphs:
  #   count         0,0,1,12,143,3244
  #   count_delta1  0,0,1,6,42,401
  #   non_count     0,0,0,3,67,2972
  #   total_count   0,0,1,15,210,6216
  #     total count, n*(n-1)/2 of A001349 num conn graphs 1,1,1,2,6,21,112,853,
  #   apply(n->n*(n-1)/2,[1,1,1,2,6,21,112,853])==[0,0,0,1,15,210,6216,363378]

  require Graph;
  my @num_graphs;
  my @count;
  my @count_delta1;
  my @non_count;
  my @total_count;
  foreach my $num_vertices (1 .. 6) {

    my $iterator_func = MyGraphs::make_graph_iterator_edge_aref
      (num_vertices_min => $num_vertices,
       num_vertices_max => $num_vertices,
       connected => 1,
      );
    my @graphs;
    while (my $edge_aref = $iterator_func->()) {
      ### graph: edge_aref_string($edge_aref)
      push @graphs, Graph_from_edge_aref($edge_aref,
                                         num_vertices => $num_vertices);
    }
    my $num_graphs = scalar(@graphs);
    push @num_graphs, $num_graphs;
    print "N=$num_vertices [$num_graphs] ";

    my $count = 0;
    my $count_delta1 = 0;
    my $non_count = 0;
    foreach my $i (0 .. $#graphs) {
      foreach my $j ($i+1 .. $#graphs) {

        if (Graph_is_subgraph($graphs[$i], $graphs[$j])
            || Graph_is_subgraph($graphs[$j], $graphs[$i])) {
          $count++;
          if (abs(scalar($graphs[$i]->edges) - scalar($graphs[$j]->edges)) <= 1) {
            $count_delta1++;
          }
        } else {
          $non_count++;
        }
      }
    }
    print " $count  $count_delta1\n";
    push @count, $count;
    push @count_delta1, $count_delta1;
    push @non_count, $non_count;
    push @total_count, $count + $non_count;
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@num_graphs, verbose=>1, name=>'num_graphs');
  Math::OEIS::Grep->search(array => \@count, verbose=>1, name=>'count');
  Math::OEIS::Grep->search(array => \@count_delta1, verbose=>1, name=>'count_delta1');
  Math::OEIS::Grep->search(array => \@non_count, verbose=>1, name=>'non_count');
  Math::OEIS::Grep->search(array => \@total_count, verbose=>1, name=>'total_count');
  exit 0;
}
{
  # longest induced path by search

  # dragon blobs
  # longest 0 cf v=0  [0 of]
  # longest 0 cf v=0  [0 of]
  # longest 0 cf v=0  [0 of]
  # longest 0 cf v=0  [0 of]
  # longest 3 cf v=4  [8 of] -2,1 -- -2,2 -- -3,2
  # longest 7 cf v=9  [4 of] -2,-1 -- -2,-2 -- -3,-2 -- -4,-2 -- -4,-1 -- -4,0 -- -5,0
  # longest 10 cf v=17  [4 of] -2,-6 -- -1,-6 -- -1,-5 -- -1,-4 -- -2,-4 -- -3,-4 -- -3,-5 -- -4,-5 -- -4,-4 -- -5,-4
  # longest 17 cf v=34  [32 of] ...
  # longest 31 cf v=68  [112 of] ...

  require Graph;
  my $graph = Graph->new (undirected=>1);
  $graph->add_cycle (0,1,2,3);
  $graph->add_path (2,4,5);

  # search_induced_paths($graph,
  #                      sub {
  #                        my ($path) = @_;
  #                        ### $path
  #                        # print "path: ", join(', ',@$aref), "\n";
  #                      });
  # show_longest_induced_path($graph);

  require Graph::Maker::Dragon;
  foreach my $k (0 .. 10) {
    print "------------------------------------------------\n";
    my $graph = Graph::Maker->new('dragon',
                                  level => $k,
                                  arms => 1,
                                  part => 'blob',
                                  undirected=>1);
    # Graph_view($graph);
    show_longest_induced_path($graph);
  }
  exit 0;

  sub show_longest_induced_path {
    my ($graph) = @_;
    my @longest_path;
    my $count = 0;
    search_induced_paths($graph,
                         sub {
                           my @path = @_;
                           if (@_ > @longest_path) {
                             @longest_path = @_;
                             $count = 1;
                           } elsif (@_ == @longest_path) {
                             $count++;
                           }
                         });
    my $num_vertices = scalar($graph->vertices);
    my $length = scalar(@longest_path);
    my $longest_path = ($length > 10 ? '...' : join(' -- ',@longest_path));
    print "longest $length cf v=$num_vertices  [$count of] $longest_path\n";

    my $subgraph = $graph->subgraph(\@longest_path);
    Graph_xy_print($graph);
    Graph_xy_print($subgraph);
  }

  sub search_induced_paths {
    my ($graph, $callback) = @_;
    my @names = sort $graph->vertices;
    ### @names
    my $last_v = $#names;
    ### $last_v
    my %name_to_v = map { $names[$_] => $_ } 0 .. $#names;
    ### %name_to_v
    my @neighbours = map {[ sort {$a<=>$b}
                            map {$name_to_v{$_}}
                            $graph->neighbours($names[$_])
                          ]} 0 .. $#names;
    ### @neighbours
    my @path;
    my @path_try = ([0 .. $#names]);
    my @path_try_upto = (0);
    my @exclude;

    for (;;) {
      my $pos = scalar(@path);
      ### at: "path=".join(',',@path)." pos=$pos, try v=".($path_try[$pos]->[$path_try_upto[$pos]]//'undef')
      my $v = $path_try[$pos]->[$path_try_upto[$pos]++];
      if (! defined $v) {
        ### backtrack ...
        $v = pop @path;
        if (! defined $v) {
          return;
        }
        $exclude[$v]--;
        if (@path) {
          my $n = $neighbours[$path[-1]];
          ### unexclude prev neighbours: join(',',@$n)
          foreach my $neighbour (@$n) {
            $exclude[$neighbour]--;
          }
        }
        next;
      }

      if ($exclude[$v]) {
        ### skip excluded ...
        next;
      }

      push @path, $v;
      $callback->(map {$names[$_]} @path);

      if ($#path >= $last_v) {
        ### found path through all vertices ...
        pop @path;
        next;
      }

      ### add: "$v trying ".join(',',@{$neighbours[$v]})
      $exclude[$v]++;
      if ($pos >= 1) {
        my $n = $neighbours[$path[-2]];
        ### exclude prev neighbours: join(',',@$n)
        foreach my $neighbour (@$n) {
          $exclude[$neighbour]++;
        }
      }
      $pos++;
      $path_try[$pos] = $neighbours[$v];
      $path_try_upto[$pos] = 0;
    }
  }
}


{
  # Vertices as permutations, edges for some elements swap
  # 3 cycle of 6
  # 4 row   4-cycles cross connected
  #         truncated octahedral
  #         https://hog.grinvin.org/ViewGraphInfo.action?id=1391
  # 4 cycle rolling cube
  #         https://hog.grinvin.org/ViewGraphInfo.action?id=1292
  # 4 all   Reye graph = transposition graph order 4
  #         https://hog.grinvin.org/ViewGraphInfo.action?id=1277
  # 4 star  Nauru graph
  #         generalized Petersen, perumtation star graph 4
  #         https://hog.grinvin.org/ViewGraphInfo.action?id=1234
  require Graph;
  my $graph = Graph->new (undirected=>1);
  my $num_elements;
  my @swaps;

  $num_elements = 3;
  @swaps = ([0,1], [1,2]);         # 3-row = cycle of 6

  $num_elements = 4;
  @swaps = ([0,1], [0,2], [0,3], [1,2], [1,3], [2,3]);  # 4-all
  @swaps = ([0,1], [0,2], [0,3]);  # 4-star claw
  @swaps = ([0,1], [1,2], [2,3]);         # 4-row
  @swaps = ([0,1], [1,2], [2,3], [3,0]);  # 4-cycle

  my @pending = ([0 .. $num_elements-1]);
  my %seen;
  while (@pending) {
    my $from = pop @pending;
    my $from_str = join('',@$from);
    next if $seen{$from_str}++;

    foreach my $swap (@swaps) {
      my ($s1,$s2) = @$swap;
      my $to = [ @$from ];
      ($to->[$s1], $to->[$s2]) = ($to->[$s2], $to->[$s1]);
      my $to_str = join('',@$to);
      $graph->add_edge($from_str,$to_str);
      push @pending, $to;
    }
  }
#  Graph_view($graph);
#  Graph_print_tikz($graph);
  my $diameter = $graph->diameter;

  my @from = (0 .. $num_elements-1);
  my $from_str = join('',@from);
  my @rev = (reverse 0 .. $num_elements-1);
  my $rev_str = join('',@rev);
  print "diameter $diameter  from $from_str\n";
  print "reversal $rev_str distance=",
    $graph->path_length($from_str,$rev_str),"\n";
  foreach my $v (sort $graph->vertices) {
    my $len = $graph->path_length($from_str,$v) || 0;
    print " to $v distance $len",
      $len == $diameter ? "****" : "",
      "\n";
  }
  my @cycles;
  Graph_find_all_4cycles($graph, callback=>sub {
                           my @cycle = @_;
                           push @cycles, join(' -- ',@cycle);
                         });
  @cycles = sort @cycles;
  my $count = @cycles;
  foreach my $cycle (@cycles) {
    print "cycle $cycle\n";
  }
  print "count $count cycles\n";

  hog_searches_html($graph);
  exit 0;
}


{
  # neighbours
  require Graph;
  my $graph = Graph->new (undirected=>1);
  my $num_elements = 4;
  my @swaps = ([0,1], [1,2], [2,3]);

  my @pending = ([0 .. $num_elements-1]);
  my %seen;
  while (@pending) {
    my $from = pop @pending;
    my $from_str = join('-',@$from);
    next if $seen{$from_str}++;

    foreach my $swap (@swaps) {
      my ($s1,$s2) = @$swap;
      my $to = [ @$from ];
      ($to->[$s1], $to->[$s2]) = ($to->[$s2], $to->[$s1]);
      my $to_str = join('-',@$to);
      $graph->add_edge($from_str,$to_str);
      push @pending, $to;
    }
  }

  foreach my $x (sort $graph->vertices) {
    my @neighbours = $graph->neighbours($x);
    foreach my $y (@neighbours) {
      foreach (1 .. 5) {
        my $has_edge = $graph->has_edge($x, $y);
        print $has_edge;
        $has_edge = $graph->has_edge($y, $x);
        print $has_edge;
      }
    }
  }
  print "\n";

  Graph_find_all_4cycles($graph);
  exit 0;
}

{
  # count graphs with uniquely attained diameter
  # unique     1,1,1,2, 5, 25,185, 2459
  # not unique 0,0,1,4,16, 87,668, 8658
  # total      1,1,2,6,21,112,853,11117              A001349

  # count trees with uniquely attained diameter
  # unique     1,1,1,1,1,2, 3, 6,11, 24, 51,118, 271, 651,1572
  # not unique 0,0,0,1,2,4, 8,17,36, 82,184,433,1030,2508,6169
  # total      1,1,1,2,3,6,11,23,47,106,235,551,1301,3159,7741    A000055
  # increment    0,0,0,0,0, 0, 0, 0,  1,  4, 12,  36, 100, 271
  # diff = unique[n] - total[n-2]

  require Graph;
  my @count_unique;
  my @count_not;
  my @count_total;
  my @diff;
  foreach my $num_vertices (1 .. 8) {
    my $count_unique = 0;
    my $count_not = 0;
    my $count_total = 0;

    # my $iterator_func = make_tree_iterator_edge_aref
    #   (num_vertices => $num_vertices);
    my $iterator_func = MyGraphs::make_graph_iterator_edge_aref
      (num_vertices => $num_vertices);
  GRAPH: while (my $edge_aref = $iterator_func->()) {
      my $graph = Graph_from_edge_aref($edge_aref);
      my $apsp = $graph->all_pairs_shortest_paths;
      my $diameter = $apsp->diameter;
      my $attained = 0;
      $count_total++;
      my @vertices = $graph->vertices;
      foreach my $i (0 .. $#vertices) {
        my $u = $vertices[$i];
        foreach my $j ($i+1 .. $#vertices) {
          my $v = $vertices[$j];
          if ($apsp->path_length($u,$v) == $diameter) {
            $attained++;
            if ($attained > 1) {
              $count_not++;
              next GRAPH;
            }
          }
        }
      }
      $count_unique++;
    }
    my $diff = (@count_total>=2 ? $count_unique - $count_total[-2] : 0);
    print "n=$num_vertices total $count_total unique $count_unique not $count_not  diff $diff\n";
    push @count_unique, $count_unique;
    push @count_not, $count_not;
    push @count_total, $count_total;
    if (@count_total >= 2) {
      push @diff, $diff;
    }
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@count_unique, verbose=>1, name=>'unique');
  Math::OEIS::Grep->search(array => \@count_not, verbose=>1, name=>'not');
  Math::OEIS::Grep->search(array => \@count_total, verbose=>1, name=>'total');
  Math::OEIS::Grep->search(array => \@diff, verbose=>1, name=>'diff');

  exit 0;
}
