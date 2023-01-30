# Copyright 2019, 2020, 2021 Kevin Ryde
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

package Graph::Maker::MostMaximumMatchingsTree;
use 5.004;
use strict;
use Carp 'croak';
use Graph::Maker;

use vars '$VERSION','@ISA';
$VERSION = 19;
@ISA = ('Graph::Maker');

# uncomment this to run the ### lines
# use Smart::Comments;


sub _default_graph_maker {
  require Graph;
  Graph->new(@_);
}
sub _make_graph {
  my ($params) = @_;
  my $graph_maker = delete($params->{'graph_maker'}) || \&_default_graph_maker;
  return $graph_maker->(%$params);
}

sub init {
  my ($self, %params) = @_;
  my $coordinate_type = delete($params{'coordinate_type'}) || '';
  my $N     = delete($params{'N'});
  my $graph = _make_graph(\%params);
  $graph->set_graph_attribute (name => "Most Maximum Matchings Tree, N=$N");

  my $add_edge = ($graph->is_directed ? 'add_cycle' : 'add_edge');

  # Add a new vertex attached to $p and located at offset $dx,$dy.
  # Return the new vertex number.
  my $upto = 1;
  my $add = sub {
    my ($p, $dx,$dy) = @_;
     ### add: "parent $p at ".$graph->get_vertex_attribute($p,'x').' '.$graph->get_vertex_attribute($p,'y')." dxdy $dx $dy"
    my $v = $upto++;
    my $x = 0;
    my $y = 0;
    if (defined $p) {
      $graph->$add_edge ($p,$v);
      if ($coordinate_type eq 'HW') {
        $x = $graph->get_vertex_attribute($p,'x') + $dx;
        $y = $graph->get_vertex_attribute($p,'y') + $dy;
      }
    }
    $graph->set_vertex_attribute($v, x => $x);
    $graph->set_vertex_attribute($v, y => $y);
    return $v;
  };

  my $s = 1;
  my $one_C = sub {
    my ($p, $dx,$dy) = @_;
    $p = $add->($p, $s*$dx,$s*$dy);    # middle
    $s = 1;
    my $hx = ($dx ? 0 : -1);     # left or down
    my $hy = ($dx ? -1 : 0);
    $add->($p, -$hx,-$hy);  # right
    {
      my $t = $add->($p, $hx,$hy);  # left
      $t = $add->($t, $hx,$hy);
      $add->($t, $hx-$dx/2, $hy-$dy/2);
      $add->($t, $hx+$dx/2, $hy+$dy/2);
    }
    return $add->($p, $dx,$dy);   # below
  };

  my $chain_C = sub {
    my ($p, $len, $dx,$dy) = @_;
    ### chain_C: "dxdy=$dx,$dy s=$s"
    foreach (1 .. $len) {
      $p = $one_C->($p, $dx,$dy);
    }
    return $p;
  };
  # add a chain of $len many C and final L (which is a single vertex),
  # starting from vertex $p
  my $CL = sub {
    my ($p, $len, $dx,$dy) = @_;
    $p = $add->($p, $s*$dx,$s*$dy);    # between
    $s = 1;
    return $chain_C->($p, $len, $dx,$dy);
  };

  # add a fork F attached to vertex $p
  my $F = sub {
    my ($p, $dx,$dy) = @_;
    $p = $add->($p, $dx,$dy);
    $add->($p, $dx+$dy/2, $dy-$dx/2);
    $add->($p, $dx-$dy/2, $dy+$dx/2);
  };

  # add a chain of $len many C and final F,
  # starting from attached to vertex $p
  my $CF = sub {
    my ($p, $len, $dx,$dy, $s) = @_;
    $p = $CL->($p, $len, $dx,$dy, $s);
    $F->($p, $dx,$dy);
  };

  if ($N) {
    my $m = $upto++;
    $graph->add_vertex($m);
    $graph->set_vertex_attribute($m, x => 0);
    $graph->set_vertex_attribute($m, y => 0);
    my $N7 = $N % 7;

    if ($N <= 6) {
      # star  figure 5(a) T6,1  star-6
      #       other N=0 to 5 also star
      if ($N >= 2) {
        foreach my $i (0 .. $N-2) {
          $add->($m, _rat_to_xy($i, $N-1));
        }
      }

    } elsif ($N eq '6.5') {
      #           *     figure 5(b) T6,2
      #           |     different from F ends of 6 mod 7
      #  m--*--*--*
      #           |
      #           *
      $m = $add->($m, 1,0);
      $m = $add->($m, 1,0);
      $m = $add->($m, 1,0);
      $add->($m, 0,  1);
      $add->($m, 0, -1);

    } elsif ($N == 10) {
      #       L        figure 5(c)   N = 10
      #       |          different from N==3 mod 7
      #  F -- m -- F
      $F->($add->($m,-1,0), -1,0);
      $F->($add->($m, 1,0),  1,0);
      $add->($m, 0,1);  # top L

    } elsif ($N7 == 6 && $N <= 20) {
      #     *     *     * or CL     figure 5(d) T13
      #     |     |     |           figure 5(e) T20
      #  m--*--*--*--*--*--*        different from F ends of 6 mod 7
      #     |     |     |
      #     *     *     *
      foreach my $i (1 .. 3) {
        $m = $add->($m, 1,0);           # right to centre
        $add->($m, 0,-1);               # down
        $CL->($m, $i==3 && $N==20,  0,1);   # up L or CL
        $m = $add->($m, 1,0);           # go right
      }

      #===================
      # Now general cases:

    } elsif ($N7 == 1) {
      #      CL    theorem 3.3 case 1        1,8,15,22,29
      $chain_C->($m, int(($N-1)/7), 1,0);

    } elsif ($N7 == 2) {
      #      C3L        C4L        figure 4(a)     N = 2 mod 7
      #       |          |                         9,16,23,30,37,44,51,72,107
      #  L -- m -- C0 -- r -- L
      #       |          |
      #      C1L        C2L
      # GP-Test  my(n=30,j=1); (n-9+7*j)\35 == 0
      # GP-Test  my(n=30,j=4); (n-9+7*j)\35 == 1
      my $k = sub { my($j)=@_; int(($N - ($N>=37 ? 2:9) + 7*$j)/35); };
      if ($k->(3)) { $s = 2; }
      my $r = $CL->($m,  $N<37 ? 0 : int(($N-37)/35),   # C0 across to r
                    1,0);
      $r = $add->($r, $k->(4)==0 ? 1 : 4, 0);
      $CL->($m, $k->(1), 0,-1);     # C1L
      $CL->($r, $k->(2), 0,-1);     # C2L
      $CL->($m, $k->(3), 0,1);
      $CL->($r, $k->(4), 0,1);
      $add->($m, -1,0);  # left L most
      $add->($r, 1,0);   # right L

    } elsif ($N7 == 3) {
      #        C2F        figure 4(b)  N == 3 mod 7       10,17,24,31,73
      #         |
      #  C1F -- m -- C3F
      #         |
      #        C0F
      my $k = sub { my($j)=@_; int(($N - 17 + 7*$j)/28); };
      $CF->($m, $k->(0),  0,-1);
      if ($k->(2)) { $s = 4; }
      $CF->($m, $k->(1), -1,0);         # left C1F
      $CF->($m, $k->(2),  0,1);
      if ($k->(2)) { $s = 2; }
      $CF->($m, $k->(3),  1,0);         # right C3F

    } elsif ($N7 == 4) {
      #      CF    theorem 3.3 case 4   N == 4 mod 7     74
      $m = $chain_C->($m, int(($N-4)/7), 1,0);
      $F->($m, 1,0);

    } elsif ($N7 == 5) {
      #        C2L         figure 4(c)  N == 5 mod 7     75
      #         |
      #  C1L -- m -- L
      #         |
      #        C0L
      my $k = sub { my($j)=@_; int(($N-5+7*$j)/21); };
      $CL->($m, $k->(0),  0,-1);
      if ($k->(1) && $k->(2)) { $s = 4; }
      $CL->($m, $k->(1), -1,0);
      $CL->($m, $k->(2),  0,1);
      $add->($m, 1,0);   # right L

    } elsif ($N==34.5 || $N7 == 6) {
      #        C5F        C6F        figure 4(d)  N == 6 mod 7
      #         |          |                      and N >= 27
      #  C3F -- m -- C0 -- r -- C4F               76
      #         |          |
      #        C1F        C2F
      my $k = sub {
        my($j)=@_;
        if ($N==34.5) { return $j==0; }
        int(($N - 27 + 7*$j)/49);
      };
      if ($k->(5)) { $s = 2; }
      my $r = $CL->($m, $k->(0), 1,0);
      $r = $add->($r, $k->(6)==0 ? 1 : 4, 0);
      $CF->($m, $k->(1),  0,-1);
      $CF->($r, $k->(2),  0,-1);
      if ($k->(5)) { $s = 4; }
      $CF->($m, $k->(3), -1,0);
      if ($k->(2)) { $s = 2; }
      $CF->($r, $k->(4),  1,0);
      $CF->($m, $k->(5),  0,1);
      $CF->($r, $k->(6),  0,1);

    } elsif ($N7 == 0) {
      #     L        figure 4(e) N == 0 mod 7
      #     |
      #     m -- CF
      #     |
      #     L
      $add->($m, 0,1);
      $add->($m, 0,-1);
      $CF->($m, int(($N-7)/7), 1,0);

    } else {
      croak "Unrecognised N=",$N;
    }
  }
  return $graph;
}

# $num/$den is a rational fraction of a 360 degree circle.
# Return a pair $x,$y of coordinates for the point at that angle and unit
# distance.
# $den==2 or 4 are forced to exact values where floating point would
# otherwise round-off 90 degrees or 180 degrees in radians to something not
# quite exact.
# $num==0 which is $a==0 comes out exact from sin() and cos() already.
#
sub _rat_to_xy {
  my ($num,$den) = @_;
  ### _rat_to_xy(): "$num $den"
  if (4*$num == $den) { return (0,1); } # 90 degrees
  if (4*$num == 2*$den) { return (-1,0); } # 180 degrees
  if (4*$num == 3*$den) { return (0,-1); } # 270 degrees
  my $a = 6.283185 * $num / $den;
  my $x = cos($a);
  my $y = sin($a);
  if (3*$num == $den || 3*$num == 2*$den) { $x = -.5; } # 120,240 degrees
  return ($x,$y);
}

Graph::Maker->add_factory_type('most_maximum_matchings_tree' => __PACKAGE__);
1;

__END__

=for stopwords Heuberger Wagner Ryde matchings undirected

=head1 NAME

Graph::Maker::MostMaximumMatchingsTree - create trees of most maximum matchings

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::MostMaximumMatchingsTree;
 $graph = Graph::Maker->new ('most_maximum_matchings_tree', N => 9);

=head1 DESCRIPTION

C<Graph::Maker::MostMaximumMatchingsTree> creates a C<Graph.pm> graph of N
vertices with the most maximum matchings per

=over

Clemens Heuberger and Stephan Wagner, "The Number of Maximum
Matchings In a Tree", Discrete Mathematics, volume 311, issue 21,
November 2011, pages 2512-2542.
L<http://arxiv.org/abs/1011.6554>

L<http://www.ncbi.nlm.nih.gov/pmc/articles/PMC3226351/>
(full text HTML)

=back

A matching is a set of vertex pairs with the vertices of each pair connected
by an edge, and no vertex used more than once.  Or equivalently, a set of
edges with no end vertices in common.  In a given tree, there is a maximum
size matching (the match number).  Various different matchings may be this
maximum size.

Heuberger and Wagner consider the number of maximum matchings a tree of N
vertices might have and show for N != 6,34 there is a unique tree with the
most maximum matchings, and for N=6,34 two trees of equal most.

The trees have various special cases for small N, and then general forms
according to N mod 7.  Vertices are presently numbered 1 to N, but don't
rely on that, nor on exactly which is attached to which.

Trees of N=0 to 6 vertices inclusive are stars the same as
L<Graph::Maker::Star>.  The second tree of 6 vertices is a special N=6.5.

       2                                *
       |       N => 6                   |    N => 6.5
    6--1--3    star,           *--B--*--B
      / \      5 maximum                |    5 maximum
     5   4     matchings                *    matchings

For 34 vertices, the general case tree is

                         *   *
                          \ /
                           B
                           |             N => 34
          *   *            *
           \ /     *\      |             59049 maximum matchings
            B        B--*--B--*          match number 10
            |      */      |
            *              *
    *\      |              |      /*
      B--*--B------*-------B--*--B
    */      |              |      \*
            *              *
            |              |
            B              B
           / \            / \
          *   *          *   *

=cut

# GP-Test  1 + 3 + 4 + 2 == 10   /* B vertices, matchnum */

=pod

And the second tree is a special N=34.5,


          *   *          *   *
           \ /            \ /            N => 34.5
            B              B
            |              |             same
            *      *       *             59049 maximum matchings
    *\      |      |       |      /*     match number 10
      B--*--B--*---B---*---B--*--B
    */      |      |       |      \*
            *      *       *
            |      |       |
            B      B       B
           / \    / \     / \
          *   *  *   *   *   *

=cut

# GP-Test  2 + 5 + 3 == 10   /* B vertices, matchnum */

=pod

Heuberger and Wagner take vertices in two types.  Type B are matched in
every maximum matching, and type A are not.  Their final most maximum
matchings trees have A and B alternating.  All leaf vertices and vertices an
even distance from a leaf are type A, and all odd distance from a leaf are
type B.

The match number is the number of B vertices.  This is since when making the
match number, a vertex with a leaf neighbour must be matched (or it and one
of its leaves unmatched would be not maximal), and taking the leaf rather
than the next vertex inwards is an equal or bigger match number for the
rest.

=head2 Coordinates

There's a secret undocumented coordinates option which sets vertex
attributes for locations in the style of Heuberger and Wagner's example
picture.  This is a good way to see the pattern, but don't rely on this yet
as it might change or be removed.

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('most_maximum_matchings_tree', key =E<gt> value, ...)>

The key/value parameters are

    N           => integer, number of vertices
                     or special 6.5 or 34.5
    graph_maker => subr(key=>value) constructor, default Graph->new

Other parameters are passed to the constructor, either C<graph_maker> or
C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are added both ways
between vertices.  Option C<undirected =E<gt> 1> creates an undirected graph
and for it there is a single edge between vertices.

=back

=head1 HOUSE OF GRAPHS

House of Graphs entries for the graphs here include

=over

L<https://hog.grinvin.org/ViewGraphInfo.action?id=1310> (etc)

=back

    1310     N=1     singleton
    19655    N=2     path-2
    32234    N=3     path-3
    500      N=4     claw, star-4
    544      N=5     star-5
    598      N=6     star-6
    288      N=6.5   other equal most N=6
    498      N=7     complete binary tree
    31053    N=8
    672      N=9
    25168    N=10    (mean distance = 1/2 diameter)
    34225, 34227, 34229, 34231, 34233    N=11 to N=15
    34235, 34237, 34239, 34241, 34243    N=16 to N=20
    34245, 34247, 34249, 34251, 34253    N=21 to N=25
    34255, 34257, 34259, 34261, 34263    N=26 to N=30
    34265, 34267, 34269                  N=31 to N=33
    31068    N=34
    31070    N=34.5
    31057    N=181   example in Heuberger and Wagner's paper

=head1 SEE ALSO

L<Graph::Maker>

My C<vpar> includes an F<examples/most-maximum-matchings.gp> program making
these trees in Pari/GP, and recurrences for their number of maximum
matchings.

=over

L<http://user42.tuxfamily.org/pari-vpar/index.html>

=back

Heuberger and Wagner's Sage code includes general case tree creation, and
counting of the maximum matchings.

=over

L<https://www.math.tugraz.at/~cheub/publications/max-card-matching/>

=back

=head1 HOME PAGE

L<http://user42.tuxfamily.org/graph-maker-other/index.html>

=head1 LICENSE

Copyright 2019, 2020, 2021 Kevin Ryde

This file is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

This file is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
This file.  If not, see L<http://www.gnu.org/licenses/>.

=cut
