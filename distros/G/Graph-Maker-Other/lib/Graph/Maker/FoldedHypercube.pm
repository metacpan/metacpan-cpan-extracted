# Copyright 2019, 2020, 2021, 2022 Kevin Ryde
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

package Graph::Maker::FoldedHypercube;
use 5.004;
use strict;
use Graph::Maker;
use Graph::Maker::Hypercube;

use vars '$VERSION','@ISA';
$VERSION = 19;
@ISA = ('Graph::Maker');

# uncomment this to run the ### lines
# use Smart::Comments;


sub init {
  my ($self, %params) = @_;
  my $N = delete($params{'N'});

  # decrement to make N-1 half cube
  if ($N) { $N--; }
  my $graph = Graph::Maker->new('hypercube', N => $N, %params);

  # Graph::Maker::Hypercube in its version 0.01 has N=0 as empty instead
  # of 2^0=1 vertices.  Ensure vertex 1 in this case.
  $graph->add_vertex(1);

  if ($N > 1) {
    # 1..8 is edges from=1..4 to 5..8  with end=9
    my $add = $graph->is_directed ? 'add_cycle' : 'add_edge';
    my $end = (1 << $N) + 1;
    foreach my $from (1 .. ($end>>1)) {
      ### edge: [$from, $end - $from]
      $graph->$add ($from, $end - $from);
    }
  }
  ### edges: $graph->edges
  return $graph;
}

Graph::Maker->add_factory_type('folded_hypercube' => __PACKAGE__);
1;

__END__

# also cf
#   http://mathworld.wolfram.com/FoldedCubeGraph.html
#   http://www.distanceregular.org/indexes/foldedcubes.html
#   http://www.win.tue.nl/~aeb/drg/graphs/Folded-6-cube.html

=for stopwords Ryde undirected antipode Weisstein hypercubes OEIS

=head1 NAME

Graph::Maker::FoldedHypercube - create folded hypercube graph

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::FoldedHypercube;
 $graph = Graph::Maker->new ('folded_hypercube', N => 4);

=head1 DESCRIPTION

C<Graph::Maker::FoldedHypercube> creates a C<Graph.pm> graph of a folded
hypercube of order N.  This is a hypercube N where each pair of antipodal
vertices are merged,

    num vertices = /  1       if N=0
                   \ 2^(N-1)  if N>=1
                 = 1, 1, 2, 4, 8, 16, ...   (A011782)

=cut

# GP-DEFINE  num_vertices(n) = if(n==0,1, 2^(n-1));
# GP-Test  vector(6,n,n--;  num_vertices(n)) == [1, 1, 2, 4, 8, 16]
# vector(10,n,n--;  num_vertices(n))

=pod

The effect is an N-1 hypercube with the addition of edges between antipodal
vertices within that N-1 hypercube.  For example N=3 is an N-1=2 square with
additional edges between opposing corners

    3---4
    | X |      N => 3   (is complete-4)
    1---2

Vertices are numbered 1..2^(N-1) as per a hypercube of order N-1.  The extra
edges are each v to 2^(N-1)+1 - v.

=cut

# GP-Test  /* cross edges in N=3 */ \
# GP-Test  my(N=3,v=1); 2^(N-1)+1 - v == 4
# GP-Test  my(N=3,v=2); 2^(N-1)+1 - v == 3

=pod

N=0 is a singleton vertex, since that's all the hypercube 0 has and nothing
is merged.

N=1 is a singleton too, being a pair of vertices merged.

The graph is regular with degree N apart from initial exceptions,

    degree = / 0,0,1   if N=0,1,2 respectively
             \ N       otherwise
           = 0, 0, 1, 3, 4, 5, 6, ...

=cut

# GP-DEFINE  degree(n) = {
# GP-DEFINE    n>=0 || error();
# GP-DEFINE    if(n<=1,0, n<=2,n-1, n*2^(n-2));
# GP-DEFINE  }

=pod

Total number of edges are then

    num edges = 1/2 * (num vertices * degree)
              = / 0,0,1            if N = 0,1,2
                \ N * 2^(N-2)      if N >= 3
              = 0, 0, 1, 6, 16, 40, 96, 224, ...  (A057711)

=cut

# GP-DEFINE  num_edges(n) = if(n==0,0, n==1,0, n==2,1, n*2^(n-2));
# GP-Test  vector(8,n,n--; num_edges(n)) == [0, 0, 1, 6, 16, 40, 96, 224]
# GP-Test  vector(8,n,n--; num_edges(n)) == [0, 0, 1, 6, 16, 40, 96, 224]
# vector(10,n,n--;  num_edges(n))
# vector(10,n,n--;  num_edges(n))

# A few authors take folded N as a whole N with additional cross edges, but
# here folded N is reckoned by merged vertices of whole hypercube N.

=pod

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('folded_hypercube', key =E<gt> value, ...)>

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

=head2 Edges

It's convenient to think of hypercube vertices numbered 0 to 2^(N-1)-1
inclusive (instead of 1..2^(N-1)).  Edges are

    u,v   differing at exactly one bit position
    u,v   differing at all N-1 bit positions,
            so u = 2^(N-1)-1 - v

=head1 HOUSE OF GRAPHS

House of Graphs entries for the folded hypercubes here include

=over

L<https://hog.grinvin.org/ViewGraphInfo.action?id=1310> (etc)

=back

    1310    N=0,1  single vertex
    19655   N=2    path-2
    74      N=3    complete 4
    570     N=4    complete bipartite 4,4
    975     N=5    Clebsch, cyclotomic 16, Keller 2
    1206    N=6    Kummer
    49239   N=7
    49241   N=8

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to the
folded hypercube include

=over

L<http://oeis.org/A011782> (etc)

=back

    A011782   num vertices
    A057711   num edges
    A295921   total cliques

=head1 SEE ALSO

L<Graph::Maker>,
L<Graph::Maker::Hypercube>,
L<Graph::Maker::Keller>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/graph-maker-other/index.html>

=head1 LICENSE

Copyright 2019, 2020, 2021, 2022 Kevin Ryde

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
