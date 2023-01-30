# Copyright 2022 Kevin Ryde
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

package Graph::Maker::HalvedHypercube;
use 5.004;
use strict;
use Graph::Maker;
use Graph::Maker::Hypercube;

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
  my $N = delete($params{'N'});

  # decrement to make N-1 half cube
  if ($N) { $N--; }
  my $graph = Graph::Maker->new('hypercube', %params, N => $N);

  # Graph::Maker::Hypercube in its version 0.01 has N=0 as empty instead
  # of 2^0=1 vertices.  Ensure vertex 1 in this case.
  $graph->add_vertex(1);

  if ($N > 1) {
    my $add = $graph->is_directed ? 'add_cycle' : 'add_edge';
    my $num_vertices = 1 <<$N;
    my $directed = $graph->is_directed;
    foreach my $from (1 .. $num_vertices) {
      foreach my $i (1 .. $N-1) {   # bit position
        my $ito = ($from-1) ^ (1<<$i);
        next if $ito < $from;  # one way around only
        foreach my $j (0 .. $i-1) { # bit position
          my $to = ($ito ^ (1<<$j)) + 1;
          ### edge: "$from to $to"
          # printf "%0*b\n", $N, $from-1;
          # printf "%0*b\n\n", $N, $to-1;
          $graph->$add ($from, $to);
        }
      }
    }
  }
  return $graph;
}

Graph::Maker->add_factory_type('halved_hypercube' => __PACKAGE__);
1;

__END__

# also cf
#   http://www.distanceregular.org/indexes/halvedcubes.html
#   http://www.win.tue.nl/~aeb/drg/graphs/Halved-6-cube.html

=for stopwords Ryde undirected antipode Weisstein hypercubes OEIS

=head1 NAME

Graph::Maker::HalvedHypercube - create halved hypercube graph

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::HalvedHypercube;
 $graph = Graph::Maker->new ('halved_hypercube', N => 4);

=head1 DESCRIPTION

C<Graph::Maker::HalvedHypercube> creates a C<Graph.pm> graph of a "halved
hypercube" of order N.  This starts from the hypercube N and is halved by
replacing the edge set with pairs of vertices which had been distance-2
apart.  This results in two isomorphic connected components, which are each
the halved hypercube N.

The effect is an N-1 hypercube to which edges are added between vertices
distance 2 apart (and existing edges retained).

Vertices are numbered 1..2^(N-1) as per a hypercube of order N-1.

    num vertices = /  1       if N=0
                   \ 2^(N-1)  if N>=1
                 = 1, 1, 2, 4, 8, 16, ...   (A011782)

=cut

# GP-DEFINE  num_vertices(n) = if(n==0,1, 2^(n-1));
# GP-Test  vector(6,n,n--;  num_vertices(n)) == [1, 1, 2, 4, 8, 16]
# vector(10,n,n--;  num_vertices(n))

=pod

Edges are each u to v where in binary u-1 and v-1 differ at exactly 1 or 2
bit positions.  So degree regular and

    degree = binomial(N-1,1) + binomial(N-1,2)
           = N*(N-1)/2

    num_edges = num_vertices * degree / 2
              = 2^(N-3) * N*(N-1)
              = 0, 0, 1, 6, 24, 80, 240, 672, ...   (A001788)

N=0 is a singleton vertex, and so is N=1.

N=2 is a square with diagonal cross edges (vertices distance 2 apart), so a
complete-4.

N=4 is the "sixteen-cell" graph, and also 8-circulant with offsets 1,2,3
(L<Graph::Maker::Circulant>).

N=5 is the complement of the Clebsch graph.

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('halved_hypercube', key =E<gt> value, ...)>

The key/value parameters are

    N           => integer
    graph_maker => subr(key=>value) constructor, default Graph->new

Other parameters are passed to the constructor, either C<graph_maker> or
C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are added both ways
between vertices.  Option C<undirected =E<gt> 1> creates an undirected graph
and for it there is a single edge between vertices.

=back

=head1 HOUSE OF GRAPHS

House of Graphs entries for the halved hypercubes here include

=over

L<https://hog.grinvin.org/ViewGraphInfo.action?id=1310> (etc)

=back

    1310    N=0,1  singleton
    19655   N=2    path-2
    74      N=3    complete 4
    176     N=4    sixteen cell
    49258   N=5    Clebsch comlement
    49260   N=6
    49262   N=7
    49264   N=8

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to the
halved hypercube include

=over

L<http://oeis.org/A011782> (etc)

=back

    A011782   num vertices
    A161680   vertex degree
    A001788   num edges
    A005864   independence number
    A288943   number of independent sets

=head1 SEE ALSO

L<Graph::Maker>,
L<Graph::Maker::Hypercube>,
L<Graph::Maker::FoldedHypercube>

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
