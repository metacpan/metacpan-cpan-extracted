#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017, 2018 Kevin Ryde
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
use Graph;
use List::Util 'min';

use FindBin;
use lib "$FindBin::Bin/../devel/lib";
use MyGraphs;
$|=1;

# uncomment this to run the ### lines
# use Smart::Comments;

{
  # Clemens Heuberger and Stephan Wagner, "The Number of Maximum Matchings In
  # a Tree", Discrete Mathematics, volume 311, issue 21, November 2011, pages
  # 2512-2542.
  # https://arxiv.org/abs/1011.6554
  #
  # https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3226351/
  # full text html
  # https://math.stackexchange.com/questions/1759752/is-there-an-efficient-algorithm-to-find-all-the-maximum-matching-in-any-tree

  # n=1  https://hog.grinvin.org/ViewGraphInfo.action?id=1310
  # n=2  https://hog.grinvin.org/ViewGraphInfo.action?id=19655
  # n=3 path-3 HOG not
  # n=4  https://hog.grinvin.org/ViewGraphInfo.action?id=500
  #      claw
  # n=5  https://hog.grinvin.org/ViewGraphInfo.action?id=544
  #      star-5
  # n=6  https://hog.grinvin.org/ViewGraphInfo.action?id=598
  #      star-6
  # n=6  https://hog.grinvin.org/ViewGraphInfo.action?id=288
  #      graphedron
  # n=7  complete binary tree
  #      https://hog.grinvin.org/ViewGraphInfo.action?id=498
  # n=8  https://hog.grinvin.org/ViewGraphInfo.action?id=31053
  # n=9  https://hog.grinvin.org/ViewGraphInfo.action?id=672
  # n=10 https://hog.grinvin.org/ViewGraphInfo.action?id=25168
  #      (mine mean distance = 1/2 diameter)
  # n=34 https://hog.grinvin.org/ViewGraphInfo.action?id=31068
  # n=34 other
  #      https://hog.grinvin.org/ViewGraphInfo.action?id=31070
  # n=181  https://hog.grinvin.org/ViewGraphInfo.action?id=31057

  my @graphs = (
                ':@',
                ':An',
                ':Bd',
                ':Cdn',
                ':DaGb',
                ':EaGaN',      # n=6 star
                ':EaYm~',      # n=6

                ':FaXbK',      # n=7   8 matchings
                ':GaXeLv',     # n=8   11 matchings
                ':H`EKWTjV',   # n=9   15 matchings
                ':I`ESgTlYF',  # n=10   21 matchings
                ':J`ESgTlYCN', # n=11
                ':K`EShOl]{G^', # n=12
                ':L`EShOl]|wO',  # n=13
                ':M`ESgTlYE\Y`',  # n=14
                ':N`ESxpbBE\Ypb',  # n=15

                ':Oc?KWp`Y|{yt]CN',
                ':P_`aa_dee_hii_lmm',
                ':Q_``bcc`fggijjgmnn',
                ':R__abbdeeb__jkkmnnk',
                ':S___d?CcchCGgggkllnool',
                ':T___bcceffcijjlmmjpqq',
                ':U_``bcc`fggijjgmnnpqqn',
                ':Va?@`bcceffc``_lmmoppm__',
                ':W_`aa_dee_hiiklliopp_stt',
                ':X_``bcc`fggijjgmnnpqqntuu',
                ':Y_`aacdda_hiiklli__qrrtuur',
                ':Za?@`bcc`fgg`jkk_noo_rss_vww',
                ':[___bcceffcijjlmmjpqqsttqwxx',
                ':\_``bcc`fggijjgmnnpqqntuuwxxu',
                ':]a?@`bcceffc``_lmmoppm__uvvxyyv',
                ':^_`aa_deeghhekll_opprsspvww_z{{',
                ':__``bcc`fggijjgmnnpqqntuuwxxu{||',
                ':`_OWSIHDaogCeTIeRXki@?hSy\UlUhuZTix\mun',

                ':a`??KEFCaOW{aP@drHcA^OgSi\\M`UjtwDivZ_Vj|~',  # n=34 general
                ':a_OWSIHDaqOOaPIdqxCy^NcSi\\M@UjtwDivZ_Vj|~',  # n=34 other

               );

  my $vpar181 = [undef, 0, 1, 2, 3, 3, 5, 6, 6, 3, 9, 10, 10, 12, 13, 13, 10, 16, 17, 17, 19, 20, 20, 24, 17, 23, 25, 26, 26, 28, 29, 29, 26, 32, 33, 33, 35, 36, 36, 33, 39, 40, 40, 42, 43, 43, 40, 46, 47, 47, 23, 50, 51, 51, 53, 54, 54, 51, 57, 58, 58, 60, 61, 61, 58, 64, 65, 65, 67, 68, 68, 65, 71, 72, 72, 23, 75, 76, 76, 78, 79, 79, 76, 82, 83, 83, 85, 86, 86, 83, 89, 90, 90, 92, 93, 93, 90, 96, 97, 97, 1, 100, 101, 101, 103, 104, 104, 101, 107, 108, 108, 110, 111, 111, 108, 114, 115, 115, 117, 118, 118, 115, 121, 122, 122, 124, 125, 125, 122, 128, 129, 129, 1, 132, 133, 133, 135, 136, 136, 133, 139, 140, 140, 142, 143, 143, 140, 146, 147, 147, 149, 150, 150, 147, 153, 154, 154, 1, 157, 158, 158, 160, 161, 161, 158, 164, 165, 165, 167, 168, 168, 165, 171, 172, 172, 174, 175, 175, 172, 178, 179, 179];
  push @graphs, MyGraphs::Graph_from_vpar($vpar181, undirected=>1);

  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # Biedl, Demaine, Duncan, Fleischer, Kobourov, "Tight Bounds on Maximal
  # and Maximum Matchings", Proceedings ISAAC 2001, Lecture Notes in
  # Computer Science volume 2223, 2001, pages 308-319.
  # http://erikdemaine.org/papers/MatchingBounds_ISAAC2001/
  # https://www2.cs.arizona.edu/~kobourov/art.ps

  # n=34 vertices
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30707
  # n=88 vertices
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30709


  # cf
  # Discrete Mathematics, volume 285, number 1-3, August 2004, pages 7-15.

  # (4n-1)/9
  # for n = 16 mod 18
  # GP-Test  3+3*5 == 18
  # starting
  # GP-Test  6*5 + 3 + 1 == 34
  # GP-Test  34 % 18 == 16
  # GP-Test  my(n=34); (4*n-1)/9 == 15
  # GP-Test  my(n=34); n-2*15 == 4
  # GP-Test  my(n=34); (n+2)/9 == 4     /* of m */
  # GP-Test  my(n=34); (n+20)/9.0 == 6
  # GP-Test  my(n=34); (n+2)/6 == 6

  # GP-Test  my(n=52); n%18 == 16
  # GP-Test  my(n=52); (4*n-1)/9 == 23
  # GP-Test  my(n=52); (n+2)/9 == 6     /* of m, no is 5 */
  # GP-Test  my(n=52); (n-7)/9 == 5     /* of m */
  # GP-Test  my(n=52); (n+20)/9.0 == 8
  # my(n=52-9); (2*n+11)/9.0

  # GP-Test  my(n=70); n%18 == 16
  # GP-Test  my(n=70); (4*n-1)/9 == 31

  # GP-Test  my(n=88); n%18 == 16
  # GP-Test  my(n=88); (4*n-1)/9 == 39
  # GP-Test  my(n=88); (n+2)/9 == 10     /* of m, no is 9 */
  # GP-Test  my(n=88); (n-7)/9 == 9      /* of m */
  # GP-Test  my(n=88); (n-16)/18 == 4  /* tops */
  # my(n=88); (2*n-11)/9
  # GP-Test  my(n=88); (2*n-5)/9 == 19   /* odd components sep by m */

  # GP-Test  my(n=88); (n+2)/6 == 15    /* blocks */
  # GP-Test  (('n-7)/9-3) * 3/2 + 6 == ('n+2)/6

  # GP-Test  (('n-7)/9-3) * 3/2 + 6 + ('n-16)/18 == (2*'n-5)/9
  

  my $graph = make_4n19(4);
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  my $num_m = grep /^m/, $graph->vertices;
  print "$num_vertices vertices, $num_edges edges, $num_m m\n";
  MyGraphs::Graph_view($graph);
  MyGraphs::hog_searches_html($graph);
  exit 0;

  sub make_4n19 {
    my ($T) = @_;
    my $graph = Graph->new (undirected=>1);
    my $t = 1;
    # T underneath + T-1 between + 2 ends
    # T+T-1+2 == 2*T+1
    my $m_max = 2*$T+1;
    my $b = 1;
    my $x = 0;
    foreach my $m (1 .. $m_max) {
      $graph->add_edge("m$m", "t$t");
      $graph->set_vertex_attribute("t$t", x => $t*6-.5);
      $graph->set_vertex_attribute("t$t", y => 4);

      my $single = ($m%2==1 && $m > 1 && $m < $m_max);
      if ($single) {
        $t++;
        $graph->add_edge("m$m", "t$t");
      }
      $graph->set_vertex_attribute("m$m", x => $x+1.5-$single);
      $graph->set_vertex_attribute("m$m", y => 3);

      foreach (1 .. ($single ? 1 : 2)) {
        $graph->add_path("m$m","b$b.u","b$b.a","b$b.b","b$b.c","b$b.d","b$b.u");
        $graph->add_edge("b$b.a","b$b.c");
        $graph->add_edge("b$b.b","b$b.d");
        $graph->set_vertex_attribute("b$b.a", x => $x);
        $graph->set_vertex_attribute("b$b.a", y => 1);
        $graph->set_vertex_attribute("b$b.b", x => $x);
        $graph->set_vertex_attribute("b$b.b", y => 0);
        $graph->set_vertex_attribute("b$b.u", x => $x+.5);
        $graph->set_vertex_attribute("b$b.u", y => 2);
        $x++;
        $graph->set_vertex_attribute("b$b.c", x => $x);
        $graph->set_vertex_attribute("b$b.c", y => 0);
        $graph->set_vertex_attribute("b$b.d", x => $x);
        $graph->set_vertex_attribute("b$b.d", y => 1);
        $x++;

        $b++;
      }
    }
    return $graph;
  }
}
{
  # Biedl, Demaine, Duncan, Fleischer, Kobourov, "Tight Bounds on Maximal
  # and Maximum Matchings"
  # https://www2.cs.arizona.edu/~kobourov/art.ps
  #
  # Degree <= 3 graph has matching at least n/2 - l/3 - deg2s/6
  # l = 2-block tree vertices

  # 3-regular
  # tetrahedral n=4, 6 edges
  # GP-Test  my(n=4); 3/2*n == 6
  # matchnum = 2
  # my(n=4,l=0); n/2 - l/3 - 0
  # my(n=4,l=0); 5*n/2 - l/3 - 6

  # 2-block tree
  # node each biconnected component (maximal bi-connected block)
  # node each cut vertex
  # edge cut vertex to biconnected component containing it


  # Mathworld: Pasch Graph
  # https://hog.grinvin.org/ViewGraphInfo.action?id=1254

  require Graph::Maker::Complete;
  my $graph = Graph::Maker->new('complete', N=>4, undirected=>1);
  $graph = MyGraphs::Graph_subdivide($graph);
  MyGraphs::Graph_view($graph);
  MyGraphs::hog_searches_html($graph);
  exit 0;
}
