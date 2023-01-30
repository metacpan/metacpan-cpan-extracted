# Copyright 2020, 2021 Kevin Ryde
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


# cf
# http://mathworld.wolfram.com/SierpinskiSieveGraph.html


package Graph::Maker::SierpinskiTriangles;
use 5.004;
use strict;
use Carp 'croak';
use Graph::Maker;
use Graph::Maker::Hypercube;

use vars '$VERSION','@ISA';
$VERSION = 19;
@ISA = ('Graph::Maker');


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
  my $N = delete($params{'N'});

  my $graph = _make_graph(\%params);
  $graph->set_graph_attribute (name => "Sierpinski $N");

  my $directed = $graph->is_directed;
  my $v = 1;
  my $add;
  $add = sub {
    my ($N, $x,$y) = @_;
    if ($N <= 0) {
      my $L = "$x,$y";
      my $R = ($x+2).",$y";
      my $T = ($x+1).','.($y+1);
      $graph->add_cycle($L,$R,$T);
      if ($directed) { $graph->add_cycle($T,$R,$L); }
    } else {
      $N--;
      my $d = 1<<$N;
      $add->($N, $x,      $y);     # left
      $add->($N, $x+2*$d, $y);     # right
      $add->($N, $x+$d,   $y+$d);  # top
    }
  };
  $add->($N, 0,0);
  return $graph;

  #   *           *                *
  #  / \         / \              / \
  # *---*       *---*            *---*
  #            / \ / \          / \ / \
  #           *---*---*        *---*---*
  #                           / \     / \
  #                          *---*   *---*
  #                         / \ / \ / \ / \
  #                        *---*---*---*---*
}

Graph::Maker->add_factory_type('Sierpinski_triangles' => __PACKAGE__);
1;

__END__

=for stopwords Ryde undirected Weisstein OEIS

=head1 NAME

Graph::Maker::SierpinskiTriangles - create Sierpinski graph

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::SierpinskiTriangles;
 $graph = Graph::Maker->new ('Sierpinski_triangles', N => 3);

=head1 DESCRIPTION

C<Graph::Maker::SierpinskiTriangles> creates a C<Graph.pm> graph of the
Sierpinski triangles graph.  This is graph vertices at the vertices of the
unit triangles in the Sierpinski triangle order N, and graph edges along the
sides of those unit triangles.

    N=>0       N => 1           N => 2

      *           *                *
     / \         / \              / \
    *---*       *---*            *---*
               / \ / \          / \ / \
              *---*---*        *---*---*
                              / \     / \
                             *---*   *---*
                            / \ / \ / \ / \
                           *---*---*---*---*

Vertex names are unspecified.  (In the current code they are coordinates in
this sort of grid, but don't rely on that.)

Graph N comprises 3 copies of graph N-1 arranged around an empty middle
triangle, and corner vertices in common.

          *
         / \
        / G \          three copies,
       @-----@         common corner vertices "@",
      / \   / \        empty middle
     / G \ / G \
    *-----@-----*

This vertex merging, and edges tripling with no merging, means

    NumVertices(N) = 3*NumVertices(N-1) - 3
                   = (3^N + 1) * 3/2
                   = 3, 6, 15, 42, 123, 366, ...   (A067771)

    NumEdges(N)    = 3^(N+1)
                   = 3, 9, 27, 81, 243, 729, ...   (A000244)

=cut

# GP-DEFINE  NumVertices(N) = {
# GP-DEFINE    N>=0 || error();
# GP-DEFINE    (3^N+1)*3/2;
# GP-DEFINE  }
# GP-Test  vector(6,N,N--; NumVertices(N)) == [3, 6, 15, 42, 123, 366]
# GP-Test  vector(100,N, NumVertices(N)) == \
# GP-Test  vector(100,N, 3*NumVertices(N-1) - 3)
#
# GP-DEFINE  NumEdges(N) = {
# GP-DEFINE    N>=0 || error();
# GP-DEFINE    3^(N+1);
# GP-DEFINE  }
# GP-Test  vector(6,N,N--; NumEdges(N)) == [3, 9, 27, 81, 243, 729]

=pod

An equivalent bottom-up definition is to take each vertical unit triangle
(horizontal base, peak upwards), insert a new vertex into each edge, and add
a cycle of edges around them, in the manner of N=0 becoming N=1.

                 *              *
      unit      / \            / \       new vertices "@"
    triangle   /   \    =>    @---@      subdividing edges,
              /     \        / \ / \     new cycle around them
             *-------*      *---@---*

The number of such unit triangles is 3^N just by the replications (top-down
or bottom-up).

=cut

# GP-DEFINE  NumUnit(N) = 3^N;
# GP-Test  vector(100,N, NumVertices(N)) == \
# GP-Test  vector(100,N, NumVertices(N-1) + 3*NumUnit(N-1))

# GP-Test  vector(100,N, NumEdges(N)) == \
# GP-Test  vector(100,N, 3*NumEdges(N-1))

=pod

There are various enclosed regions other than such upwards unit triangles.
Total number of interior regions follows from the top-down replications by 3
copies and a new middle,

    NumRegions(N) = 3*NumRegions(N) + 1
                  = (3^(N+1) - 1)/2
                  = 1, 4, 13, 40, 121, 364, ...       (A003462)

The graph is planar by its construction, so the combination of vertices,
edges and interior regions satisfy Euler's formula

    NumVertices(N) + NumRegions(N) = NumEdges(N) + 1

=cut

# GP-DEFINE  NumRegions(N) = {
# GP-DEFINE    N>=0 || error();
# GP-DEFINE    (3^(N+1) - 1)/2;
# GP-DEFINE  }
# GP-Test  NumRegions(0) == 1
# GP-Test  NumRegions(1) == 4
# GP-Test  vector(6,N,N--; NumRegions(N)) == [1, 4, 13, 40, 121, 364]
# GP-Test  vector(100,N, NumVertices(N) + NumRegions(N)) == \
# GP-Test  vector(100,N, NumEdges(N) + 1)

=pod

The towers of Hanoi state graph (L<Graph::Maker::Hanoi>) is related to the
graph here by taking the inside of each upward unit triangle as a vertex,
and put edges between those unit triangles which touch at corners.

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('Sierpinski_triangles', key =E<gt> value, ...)>

The key/value parameters are

    N           => integer
    graph_maker => subr(key=>value) constructor, default Graph->new

Other parameters are passed to the constructor, either C<graph_maker> or
C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are added both ways
between vertices.  Option C<undirected =E<gt> 1> creates an undirected graph
and for it there is a single edge between vertices.

=back

=head1 FORMULAS

=head2 Wiener Index

=head1 HOUSE OF GRAPHS

House of Graphs entries for the folded hypercubes here include

=over

L<https://hog.grinvin.org/ViewGraphInfo.action?id=1310> (etc)

=back

     1374   N=0   3-cycle
    36261   N=1

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to the
folded hypercube include

=over

L<http://oeis.org/A011782> (etc)

=back

    A067771   num vertices
    A000244   num edges
    A003462   num interior regions

=head1 SEE ALSO

L<Graph::Maker>,
L<Graph::Maker::Hanoi>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/graph-maker-other/index.html>

=head1 LICENSE

Copyright 2020, 2021 Kevin Ryde

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
