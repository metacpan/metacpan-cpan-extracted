#!/usr/bin/perl -w

# Copyright 2017, 2018, 2019 Kevin Ryde
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
use FindBin;
use File::Spec;
use File::Slurp;
use Test;
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Math::BaseCnv 'cnv';
use Math::NumSeq::Catalan;
use Math::NumSeq::BalancedBinary;

use Graph::Maker::Catalans;

use File::Spec;
use lib File::Spec->catdir('devel','lib');
use MyGraphs;

# uncomment this to run the ### lines
# use Smart::Comments;

plan tests => 2420;

my $seq = Math::NumSeq::BalancedBinary->new;

my @rel_types
  = ('rotate',
     'rotate_first','rotate_last',
     'rotate_Aempty','rotate_Bempty','rotate_Cempty',
     'rotate_leftarm','rotate_rightarm',
     'dexter',
     'split',
     'flip',
     'filling');

my @vertex_name_types
  = ('balanced', 'balanced_postorder',
     'Ldepths',
     'Ldepths_inorder', 'Rdepths_inorder', 'Bdepths_inorder',
     'Rdepths_postorder',
     'Lweights','Rweights',
     'run1s','run0s',
     'vpar', 'vpar_postorder');
ok (scalar(@vertex_name_types), 13);


#------------------------------------------------------------------------------
# Knuth fasc4a section 7.2.1.6 exercise 30(d), result of lakser on
# complementary pairs in the Tamari lattice.

# $vpar is an arrayref of vertex parents, for vertices numbered 1..N (but
# entries in the array 0..N-1).
# Return a list of N flags for the "footprint",
# being each vertex 1 when childful, 0 when childless.
# Childless is simply that vertex number not appearing in $vpar.
#
sub vpar_to_footprint {
  my ($vpar) = @_;
  my @has_child;
  foreach my $p (@$vpar) {
    $has_child[$p] = 1;
  }
  return map{$_?1:0} @has_child[1..scalar(@$vpar)];
}
ok (join('', vpar_to_footprint([0,0])), '00');
ok (join('', vpar_to_footprint([0,1])), '10');

{
  #
  #
  #                   *      021
  #                  / \     PLL
  #                 *   *    LPL
  #  111       -------> 110010 -------_        003  run0s
  #  LLL      /                        v       PPL  preorder leaf
  #  LLL  101010                      111000   LLP  postorder leaf
  #           \                        ^
  #            --> 101100 --> 110100 -/
  #
  #                  *          *
  #            102    \        /   012
  #            LPL     *      *    PLL
  #            LLP    /        \   LLP
  #                  *          *
  #
  # complementary = two points in a lattice have min(x,y) = lowest
  #                                              max(x,y) = highest
  # footprint = sequence 1=nonleaf, 0=leaf
  #
  # Tamari lattice points complementary if and only if their postorder
  # footprints are complementary, meaning opposite leaf/nonleaf,
  # excluding first vertex which is always leaf.
  #
  # Knuth takes the definition of rotate on preorder subtree sizes vector,
  # whereas here per rotate is per Pallo Lweights which is postorder subtree
  # sizes vector.  Hence applying the "footprint" to postorder instead of
  # preorder.
  #
  # Knuth's answer notes that a rotates increase, so two points with a leaf
  # in common can leave it alone and increase rest to a max < highest.
  # Similarly unrotate decreases to nonleaf in common can leave alone and
  # decrease rest to min > lowest.
  #
  # Exercise 30(c) is that the leaf-ness is per run0s.  Here that name type
  # is preorder, so does not suit here.
  #
  foreach my $N (2 .. 5) {
    my $graph = Graph::Maker->new('Catalans', N => $N,
                                  vertex_name_type => 'vpar_postorder');
    # require MyGraphs; MyGraphs::Graph_view($graph);

    ok ($graph->vertices >= 2,  1);
    my $lowest = MyGraphs::Graph_lattice_lowest($graph);
    my $highest = MyGraphs::Graph_lattice_highest($graph);
    my $href = MyGraphs::Graph_lattice_minmax_hash($graph);
    MyGraphs::Graph_lattice_minmax_validate($graph,$href);

    # Knuth fasc4a section 7.2.1.6 exercise 32, Tamari lattice is
    # semidistributive.
    MyGraphs::lattice_minmax_is_semidistributive($graph,$href);

    my $count_complementary = 0;
    foreach my $u ($graph->vertices) {
      my @u_vpar = split /,/,$u;
      my @u_footprint = vpar_to_footprint(\@u_vpar);
      shift @u_footprint;  # f[1]..f[n-1] for compare
      my $u_footprint = join('',@u_footprint);

      foreach my $v ($graph->vertices) {
        my @v_vpar = split /,/,$v;
        my @v_footprint = vpar_to_footprint(\@v_vpar);
        shift @v_footprint;  # f[1]..f[n-1] for compare
        my $v_footprint = join('', @v_footprint);
        my @v_complement = map {1-$_} @v_footprint;
        my $v_complement = join('', @v_complement);

        my $min = $href->{'min'}->{$u}->{$v};
        my $max = $href->{'max'}->{$u}->{$v};
        my $is_complementary = ($min eq $lowest && $max eq $highest);
        # print "$u  $v  min $min max $max comp '$is_complementary'  footprints $u_footprint $v_footprint $v_complement\n";
        ok ($is_complementary, $u_footprint eq $v_complement);
        $count_complementary += $is_complementary;
      }
    }
  }
}


#------------------------------------------------------------------------------
# POD HOG Shown

{
  # my %shown = (
  #              # all rel_type the same on N=0,1,2
  #
  #              # N=0,1 singleton in all cases
  #              'N=0,rotate' => 1310,
  #              'N=1,rotate' => 1310,
  #              'N=0,rotate_first' => 1310,
  #              'N=1,rotate_first' => 1310,
  #              'N=0,rotate_last' => 1310,
  #              'N=1,rotate_last' => 1310,
  #              'N=0,rotate_Aempty' => 1310,
  #              'N=1,rotate_Aempty' => 1310,
  #              'N=0,rotate_Bempty' => 1310,
  #              'N=1,rotate_Bempty' => 1310,
  #              'N=0,rotate_Cempty' => 1310,
  #              'N=1,rotate_Cempty' => 1310,
  #              'N=0,rotate_rightarm' => 1310,
  #              'N=1,rotate_rightarm' => 1310,
  #              'N=0,rotate_leftarm' => 1310,
  #              'N=1,rotate_leftarm' => 1310,
  #              'N=0,dexter' => 1310,
  #              'N=1,dexter' => 1310,
  #              'N=0,split' => 1310,
  #              'N=1,split' => 1310,
  #              'N=0,flip' => 1310,
  #              'N=1,flip' => 1310,
  #              'N=0,filling' => 1310,
  #              'N=1,filling' => 1310,
  #
  #              # N=2 path-2 in all cases
  #              'N=2,rotate' => 19655,
  #              'N=2,rotate_first' => 19655,
  #              'N=2,rotate_last' => 19655,
  #              'N=2,rotate_Aempty' => 19655,
  #              'N=2,rotate_Bempty' => 19655,
  #              'N=2,rotate_Cempty' => 19655,
  #              'N=2,rotate_rightarm' => 19655,
  #              'N=2,rotate_leftarm'  => 19655,
  #              'N=2,dexter' => 19655,
  #              'N=2,split' => 19655,
  #              'N=2,flip' => 19655,
  #              'N=2,filling' => 19655,
  #
  #              'N=3,rotate'          => 340,  # 5-cycle
  #              'N=3,rotate_first'    => 286,  # path-5
  #              'N=3,rotate_last'     => 286,  # path-5
  #              'N=3,rotate_Cempty'   => 286,  # path-5
  #              'N=3,rotate_rightarm' => 286,  # path-5
  #              'N=3,rotate_leftarm'  => 286,  # path-5
  #              'N=3,dexter'          => 206,  # 4-cycle and leaf
  #
  #              'N=4,rotate'          => 33547,
  #              'N=5,rotate'          => 33549,
  #              'N=6,rotate'          => 33551,
  #
  #              'N=4,rotate_first'    => 33563,
  #              'N=5,rotate_first'    => 33565,
  #              'N=6,rotate_first'    => 33567,
  #
  #              'N=4,rotate_last'     => 33569,
  #              'N=5,rotate_last'     => 33571,
  #              'N=6,rotate_last'     => 33573,
  #
  #              'N=3,rotate_Aempty'   => 286,  # path-5
  #              'N=4,rotate_Aempty'   => 33607,
  #              'N=5,rotate_Aempty'   => 33609,
  #              'N=6,rotate_Aempty'   => 33611,
  #
  #              'N=3,rotate_Bempty'   => 286,  # path-5
  #              'N=4,rotate_Bempty'   => 33601,
  #              'N=5,rotate_Bempty'   => 33603,
  #              'N=6,rotate_Bempty'   => 33605,
  #
  #              'N=3,flip'            => 206,  # 4-cycle and leaf
  #              'N=4,flip'            => 33589,
  #              'N=5,flip'            => 33591,
  #              'N=6,flip'            => 33593,
  #
  #              'N=3,filling'         => 544,  # star-5
  #              'N=4,filling'         => 33595,
  #              'N=5,filling'         => 33597,
  #              'N=6,filling'         => 33599,
  #
  #              'N=3,split'           => 264,
  #              'N=4,split'           => 33557,
  #              'N=5,split'           => 33559,
  #              'N=6,split'           => 33561,
  #             );

  my %shown;
  {
    my $content = File::Slurp::read_file
      (File::Spec->catfile($FindBin::Bin,
                           File::Spec->updir,
                           'lib','Graph','Maker','Catalans.pm'));
    $content =~ /=head1 HOUSE OF GRAPHS.*?=head1/s or die;
    $content = $&;
    my $rel_type;
    my $count = 0;
    while ($content =~ /^    (?<rel>\w+)|^      (?<id>\d+) +N=(?<N>\d+)/mg) {
      if (defined $+{'rel'}) {
        $rel_type = $+{'rel'};
      } else {
        $count++;
        my $N = $+{'N'};
        foreach my $t
          ($rel_type eq 'all' ? @rel_types
           : $rel_type eq 'rotate_Aempty'   ? ($rel_type,'rotate_Cempty')
           : $rel_type eq 'rotate_rightarm' ? ($rel_type,'rotate_leftarm')
           : $rel_type) {
          $shown{"N=$N,$t"} = $+{'id'};
          if ($N eq '0') {     # "N=0 and N=1"
            $shown{"N=1,$t"} = $+{'id'};
          }
        }
      }
    }
    ok ($count, 42, 'HOG ID number lines');
  }
  ok (scalar(keys %shown), 84);
  ### %shown

  my $extras = 0;
  my %seen;
  foreach my $N (0 .. 6) {
    foreach my $rel_type (@rel_types) {
      my $graph = Graph::Maker->new('Catalans', N => $N,
                                    rel_type => $rel_type,
                                    undirected => 1);
      my $key = "N=$N,$rel_type";
      ### $key
      my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
      $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
      if (my $id = $shown{$key}) {
        MyGraphs::hog_compare($id, $g6_str);
      } else {
        if (MyGraphs::hog_grep($g6_str)) {
          MyTestHelpers::diag ("HOG got $key, not shown in POD");
          MyTestHelpers::diag ($g6_str);
          MyGraphs::Graph_view($graph);
          $extras++
        }
      }
    }
  }
  ok ($extras, 0);
}


#------------------------------------------------------------------------------
# Distinct rel_type to Isomorphism

{
  my $N = 5;
  my %g6_to_rel_types;
  foreach my $rel_type (@rel_types) {
    my $graph = Graph::Maker->new('Catalans', N => $N,
                                  rel_type   => $rel_type,
                                  undirected => 1);
    my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
    $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
    push @{$g6_to_rel_types{$g6_str}}, $rel_type;
  }

  my $content = File::Slurp::read_file
    (File::Spec->catfile($FindBin::Bin,
                         File::Spec->updir,
                         'lib','Graph','Maker','Catalans.pm'));
  $content =~ /(\d+)\s+relation\s+types/s or die;
  ok (scalar(@rel_types), $1);
  $content =~ /(\d+)\s+up\s+to\s+isomorphism/s or die;
  ok (scalar(keys %g6_to_rel_types), $1);

  # 10 different, per POD
  ok (scalar(@rel_types),            12);
  ok (scalar(keys %g6_to_rel_types), 10);

  {
    # POD intro text "... and 13 vertex name types"
    $content =~ /(\d+)\s+vertex\s+name\s+types/s or die;
    my $pod_count = $1;
    ok (scalar(@vertex_name_types), $pod_count,
        "POD intro text showing number of vertex name types");
    ok (scalar(@vertex_name_types), 13);
  }

  my @sames = sort map {join(' = ',@$_)} values %g6_to_rel_types;
  ok (join("\n",@sames),
      "dexter
filling
flip
rotate
rotate_Aempty = rotate_Cempty
rotate_Bempty
rotate_first
rotate_last
rotate_leftarm = rotate_rightarm
split");

  # foreach my $same (@sames ) {
  #   print "$same\n";
  # }
}


#------------------------------------------------------------------------------
# G. Kreweras, "Sur les Partitions Non-Croisees d'Un Cycle", Discrete
# Mathematics, volume 1, number 4, 1972, pages 333-350.

{
  # Kreweras figure 1.
  my $N = 4;
  my $noncrossing = Graph->new (undirected => 1);
  $noncrossing->add_edges(['abcd','abc,d'],
                          ['abcd','a,bcd'],
                          ['abcd','ad,bc'],
                          ['abcd','ab,cd'],
                          ['abcd','abd,c'],
                          ['abcd','acd,b'],

                          ['abc,d','a,bc,d'],
                          ['abc,d','ab,c,d'],
                          ['abc,d','ac,b,d'],

                          ['a,bcd','a,bc,d'],
                          ['a,bcd','a,bd,c'],
                          ['a,bcd','a,b,cd'],

                          ['ad,bc','a,bc,d'],
                          ['ad,bc','ad,b,c'],

                          ['ab,cd','ab,c,d'],
                          ['ab,cd','a,b,cd'],

                          ['abd,c','ab,c,d'],
                          ['abd,c','a,bd,c'],
                          ['abd,c','ad,b,c'],

                          ['acd,b','ac,b,d'],
                          ['acd,b','a,b,cd'],
                          ['acd,b','ad,b,c'],

                          ['a,b,c,d','a,bc,d'],
                          ['a,b,c,d','ab,c,d'],
                          ['a,b,c,d','a,bd,c'],
                          ['a,b,c,d','ac,b,d'],
                          ['a,b,c,d','a,b,cd'],
                          ['a,b,c,d','ad,b,c'],
                         );
  ok (scalar($noncrossing->vertices), 14);
  ok (scalar($noncrossing->edges), 28);

  my $catalans = Graph::Maker->new('Catalans', N => $N,
                                   rel_type => 'split',
                                   undirected => 1);
  ok (scalar($catalans->edges), 28);
  ok (!! MyGraphs::Graph_is_isomorphic($catalans,$noncrossing), 1);
}


#------------------------------------------------------------------------------
# Winfried Geyer, "On Tamari Lattices", Discrete Mathematics, volume 133,
# 1994, pages 99-122.

{
  my $pairs = Graph->new (undirected => 1);
  $pairs->add_edges(['top','<33>'],
                    ['top','<22>'],
                    ['top','<11>'],
                    ['<33>','<23>'],
                    ['<33>','[24]'],
                    ['<22>','[14]'],
                    ['<22>','<12>'],

                    ['<23>','<13>'],
                    ['<23>','[14]'],
                    ['<12>','[12]'],
                    ['<12>','[34]'],
                    ['<11>','[24]'],
                    ['<11>','[34]'],

                    ['<13>','[13]'],
                    ['<13>','[23]'],
                    ['[14]','[13]'],
                    ['[24]','[23]'],

                    ['[13]','[12]'],
                    ['[34]','bottom'],

                    ['[12]','bottom'],
                    ['[23]','bottom']);
  ok (scalar($pairs->vertices), 14);
  ok (scalar($pairs->edges), 14*3/2);

  my $catalans = Graph::Maker->new('Catalans', N => 4, undirected => 1);
  ok (!! MyGraphs::Graph_is_isomorphic($catalans,$pairs), 1);
}


#------------------------------------------------------------------------------
# rotate_Aempty
# rotate_Bempty
# rotate_Cempty

foreach my $N (4 .. 6) {
  my $A_graph = Graph::Maker->new('Catalans', N => $N,
                                  rel_type => 'rotate_Aempty',
                                  undirected => 1);
  my $B_graph = Graph::Maker->new('Catalans', N => $N,
                                  rel_type => 'rotate_Bempty',
                                  undirected => 1);
  my $C_graph = Graph::Maker->new('Catalans', N => $N,
                                  rel_type => 'rotate_Cempty',
                                  undirected => 1);
  ok (! MyGraphs::Graph_is_isomorphic($A_graph,$B_graph), 1);
  ok (! MyGraphs::Graph_is_isomorphic($B_graph,$C_graph), 1);

  ok (!! MyGraphs::Graph_is_isomorphic($A_graph,$C_graph), 1,
      'rotate_Aempty isomorphic rotate_Cempty');
}


#------------------------------------------------------------------------------
# Limits.

ok (Math::NumSeq::Catalan->new->ith(6), 132);


#------------------------------------------------------------------------------
# In terms of BalancedBinary.

sub balanced_binary_list {
  my ($n) = @_;
  my $i = $seq->value_to_i_ceil(4**($n-1));
  my $limit = 4**$n;
  my @ret;
  for (;;) {
    my $value = $seq->ith($i);
    last if $value >= $limit;
    push @ret, $value;
    $i++;
  }
  return @ret;
}

# from 101010
#   to 101100 pos=2 len=2
#   to 110100 pos=4 len=4

# from 101100
#       43
#   to 101010 pos=3 len=2
#   to 111000 pos=4 len=4

# from 111000
#      54
#   to 110100 pos=4 len=2
#   to 110010 pos=5 len=4

sub balanced_binary_long_len {
  my ($value, $pos) = @_;
  my $d = 0;
  my $len = 0;
  my $one = $value*0 + 1;
  my $bit = $one << $pos;
  while ($bit) {
    $d += ($value & $bit ? 1 : -1);
    return 0 if $d < 0;
    $len++;
    last if $d == 0;
    $bit >>= 1;
  }
  return $len;
}

sub make_by_masks {
  my ($n) = @_;
  my $graph = Graph->new (undirected => 1);
  my @balanced_binary = balanced_binary_list($n);
  $graph->add_vertices(@balanced_binary);
  my $one = $balanced_binary[0]*0 + 1;
  foreach my $from (@balanced_binary) {
    ### from: cnv($from,10,2)
    foreach my $pos (2 .. 2*$n-1) {
      my $hi = $one << $pos;
      $from & $hi or next;
      my $len = balanced_binary_long_len($from,$pos-1) || next;
      my $lo = $one << ($pos-$len);
      my $mask = $hi - $lo;
      my $to = ($from & ~($hi|$mask))
        | (($from & $hi) >> $len)
        | (($from & $mask) << 1);
      ### edge: cnv($from,10,2).' to '.cnv($to,10,2)." pos=$pos len=$len"
      $seq->pred($to) || die "oops";
      $graph->add_edge($from,$to);
    }
  }
  return $graph;
}

foreach my $N (1 .. 4) {
  my $graph = Graph::Maker->new('Catalans',
                                comma=>'', N => $N, undirected=>1);
  # print "$graph\n";
  my $b_graph = make_by_masks($N);
  ### num vertices: scalar $b_graph->vertices
  ### num edges   : scalar $b_graph->edges
  # print "$b_graph\n";
  # MyGraphs::Graph_view($b_graph);
  ok (!! MyGraphs::Graph_is_isomorphic($graph,$b_graph), 1);
}


#------------------------------------------------------------------------------
# Sleator, Tarjan, Thurston, "Rotation Distance, Triangulations, and
# Hyperbolic Geometry", Journal of the American Mathematical Society, volume
# 1, number 3, July 1988.  Figure 4: rotation graph of hexagon, RG(6).
#
#         +-------------------------+
#         |                         |
#         |    1 ----- 2 ----- 3    |
#         | /  |       |       | \  |
#         |/   |     /-7-\     |  \ |
#         4    5 -- 6     9 -- 10  11
#          \   |     \-8-/     |  /
#           \  |       |       | /
#             12 ---- 13 ---- 14

{
  my $hexagons = Graph->new (undirected => 1);
  $hexagons->add_cycle(4,1,2,3,11,14,13,12);
  $hexagons->add_edge(4,11);
  $hexagons->add_path(1,5,12);
  $hexagons->add_path(3,10,14);
  $hexagons->add_path(2,7,6,8,13); $hexagons->add_path(7,9,8);
  $hexagons->add_path(5,6); $hexagons->add_path(9,10);

  my $catalans = Graph::Maker->new('Catalans', N => 4, undirected => 1);

  ok (!! MyGraphs::Graph_is_isomorphic($catalans,$hexagons), 1);
}

#------------------------------------------------------------------------------

{
  my $diagram = Graph->new (undirected => 1);
  $diagram->add_edges([1,2], [1,3], [1,4],
                      [2,5],[2,6], [3,5],[3,7], [4,6],[4,7],
                      [5,8],[5,9], [6,9], [7,9],[7,10],
                      [8,11], [9,11],[9,12], [10,12],
                      [11,13], [12,13],
                      [13,14]);
  my $catalans = Graph::Maker->new('Catalans', N => 4,
                                   rel_type => 'flip',
                                   undirected => 1);

  ok (!! MyGraphs::Graph_is_isomorphic($catalans,$diagram), 1);

}

#------------------------------------------------------------------------------
# Richard P. Stanley, "The Fibonacci Lattice", Fibonacci Quarterly, volume
# 13, number 3, October 1975, pages 215-232.
# https://fq.math.ca/13-3.html
# https://fq.math.ca/Scanned/13-3/stanley.pdf
# page 222 J(S(3)) picture
#
#            14
#             |
#            13
#           /   \
#        11      12
#       /   \   /   \
#     8       9       10
#       \   / | \   /
#         5   6   7
#         | X   X |
#         2   3   4
#           \ | /
#             1
#
# Olivier Bernardi, "Catalan Lattices and Realizers of Triangulations", slides.
# Page 8 Stanley lattice.
#
#          14
#           |
#          13
#        /    \
#       11     12
#      /  \   /  \
#     8     9    10
#     |  /  |  \  |
#     5     6     7
#     |  X     X  |
#     2     3     4
#       \   |   /
#           1
{
  my $diagram = Graph->new (undirected => 1);
  $diagram->add_edges([1,2], [1,3], [1,4],
                      [2,5],[2,6], [3,5],[3,7], [4,6],[4,7],
                      [5,8],[5,9], [6,9], [7,9],[7,10],
                      [8,11], [9,11],[9,12], [10,12],
                      [11,13], [12,13],
                      [13,14]);
  my $catalans = Graph::Maker->new('Catalans', N => 4,
                                   rel_type => 'flip',
                                   undirected => 1);

  ok (!! MyGraphs::Graph_is_isomorphic($catalans,$diagram), 1);
}

#------------------------------------------------------------------------------
# Isomorphic with Different vertex_name_type

foreach my $N (0 .. 5) {
  foreach my $rel_type ('rotate','split',
                        'rotate_first','rotate_last',
                        'flip',
                       ) {
    my $graph = Graph::Maker->new('Catalans', N => $N,
                                  rel_type => $rel_type,
                                  undirected=>1);

    foreach my $vertex_name_type (@vertex_name_types) {
      my $graph2 = Graph::Maker->new('Catalans', N => $N,
                                     rel_type => $rel_type,
                                     vertex_name_type => $vertex_name_type,
                                     undirected => 1);
      ok (!! MyGraphs::Graph_is_isomorphic($graph,$graph2), 1,
         "rel_type=$rel_type default isomorphic to $vertex_name_type");
    }
  }
}


#------------------------------------------------------------------------------
exit 0;
