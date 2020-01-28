# Copyright 2019, 2020 Kevin Ryde
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
$VERSION = 15;
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
  my $N = delete($params{'N'});

  # decrement to make N-1 half cube
  if ($N) { $N--; }
  my $graph = Graph::Maker->new('hypercube', %params, N => $N);

  # Graph::Maker::Hypercube in its version 0.01 has N=0 as empty instead
  # of 2^0=1 vertices.  Ensure vertex 1 in this case.
  $graph->add_vertex(1);

  if ($N > 1) {
    my $directed = $graph->is_directed;
    my $end = (1 << $N) + 1;
    foreach my $from (1 .. ($end>>1)) {
      my $to = $end - $from;
      ### edge: "$from to $to"
      $graph->add_edge ($from, $to);
      if ($directed) {
        $graph->add_edge($to,$from);
      }
    }
  }
  return $graph;
}

Graph::Maker->add_factory_type('folded_hypercube' => __PACKAGE__);
1;

__END__

# also cf
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

C<Graph::Maker::FoldedHypercube> creates a C<Graph.pm> graph of a "folded
hypercube" of order N.  The folded hypercube is a hypercube where each pair
of antipodal vertices are merged, so half the vertices of the full
hypercube.

The folded hypercube graph created has vertices numbered 1 to 2^(N-1) like
the first half of a C<Graph::Maker::Hypercube>.  N=0 is a single vertex and
is not merged, so

    num vertices = /  1       if N=0
                   \ 2^(N-1)  if N>=1
                 = 1, 1, 2, 4, 8, 16, ...   (A011782)

The effect of the merging is to make an N-1 hypercube with the addition of
edges between antipodal pairs in that N-1 hypercube.  For example N=3 is an
N-1=2 square with additional edges between opposing corners

    3---4
    | X |      N => 3   (is complete-4)
    1---2

=cut

# GP-DEFINE  num_vertices(n) = if(n==0,1, 2^(n-1));
# GP-Test  vector(6,n,n--;  num_vertices(n)) == [1, 1, 2, 4, 8, 16]
# vector(10,n,n--;  num_vertices(n))

=pod

The additional antipodal edge is at every vertex, so regular of degree N,
except N=1 or N=2 where the antipodals are already edges, so

    degree = / N-1   if N=1,2
             \ N     otherwise
           = 0, 0, 1, 3, 4, 5, 6, ...

Total edges are

    num edges = 1/2 * (num vertices * degree)
              = / 0,0,1            if N = 0,1,2
                \ N * 2^(N-2)      if N >= 3
              = 0, 0, 1, 6, 16, 40, 96, 224, ...  (A057711)

=cut

# GP-DEFINE  num_edges(n) = if(n==0,0, n==1,0, n==2,1, n*2^(n-2));
# GP-Test  vector(8,n,n--; num_edges(n)) == [0, 0, 1, 6, 16, 40, 96, 224]
# vector(10,n,n--;  num_edges(n))

=pod

A few authors reckon folded N as a whole N with additional cross edges, but
here folded N is based on merged vertices of whole N.

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

=head2 Merged Antipodals

It's convenient to think of hypercube vertices numbered 0 to 2^N-1 inclusive
and edges between those differing by a single bit flip.

Antipodal vertices in the full hypercube are bit flipping all bits.
A vertex and its antipode are then a pair for the folded hypercube.  They
can be taken as the smaller of the two vertex numbers, which is the one
beginning with a 0-bit.  For example in N=4, 0000 and 1111 are a pair and
take 0000 as representing it.  The neighbours of each are

    0000 -> 1000, 0100, 0010, 0001    flip one bit
            0111                      smaller of its pair

    1111 -> 0111, 1011, 1101, 1110    flip one bit
                  0100  0010  0001    smaller of their pairs

So 0000 has an edge to 0111 in addition to its normal single bit flips.  And
its partner 1111 the same when reduced to the smaller of their folded pairs.

This 000 -> 111 is the all-bits flip which is the antipode of a vertex in
the N-1 hypercube comprising the smaller of each pair.  In terms of vertices
numbered 1 to 2^(N-1), this flip is 2^(N-1)+1-v.

In N=2, which is just a path-2, the all-bits flip is just a single bit so
nothing extra

    00 -> 10, 01    flip one bit
          01        smaller of its pair, same

    11 -> 01, 10    flip one bit
              01    smaller of its pair, same

N=1 hypercube is a path-2 and that pair merged is a single vertex folded
hypercube.

N=0 hypercube is a single vertex which doesn't have an antipode to merge
with.  This is left as a single vertex too (though it's not what
C<Graph::Maker::Hypercube> does, as of its version 0.01).

=head2 Cliques

Eric Weisstein counts total cliques, meaning all clique sizes 0 upwards,

=over

L<http://mathworld.wolfram.com/FoldedCubeGraph.html>

=back

    total cliques = / 2    if N=0 or 1 
                    | 16   if N=3
                    \ 1 + num_vertices(n) + num_edges(n)   otherwise
                  = 2, 2, 4, 16, 25, 57, 129, 289, ...    (A295921)

=cut

# GP-DEFINE  num_cliques(n) = {
# GP-DEFINE    if(n <= 1, num_vertices(n) + 1,
# GP-DEFINE       n == 3, 16, \
# GP-DEFINE       num_vertices(n) + num_edges(n) + 1);
# GP-DEFINE  }
# GP-Test  vector(8,n,n--;  num_cliques(n)) == [2, 2, 4, 16, 25, 57, 129, 289]
# vector(20,n,n--;  num_cliques(n))

=pod

This follows from noting that the clique number (size of the biggest clique)
is only

    clique number = / 1     if N=0 or 1
                    | 4     if N=3
                    \ 2     otherwise
                  = 1, 1, 2, 4, 2, 2, 2, ...

Clique number 2 means the cliques are an empty (1 of), each vertex a clique
size 1, and each edge a clique size 2.

That the clique number is only 2 is since two neighbours by flipping a
single bit don't have an edge between (to make a triangle) as that would be
2 bits flipped.  For N=3, the all bits flip is 2 bits, but not otherwise.

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

L<http://user42.tuxfamily.org/graph-maker/index.html>

=head1 LICENSE

Copyright 2019, 2020 Kevin Ryde

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
