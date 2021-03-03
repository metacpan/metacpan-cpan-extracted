# Copyright 2015, 2016, 2017, 2018, 2019, 2020, 2021 Kevin Ryde
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

package Graph::Maker::Petersen;
use 5.004;
use strict;
use Graph::Maker;
use List::Util 'min';

use vars '$VERSION','@ISA';
$VERSION = 18;
@ISA = ('Graph::Maker');

# uncomment this to run the ### lines
# use Smart::Comments;


# Usage: $graph = $self->make_graph(key=>value)
# Create and return a graph with given key/value parameters.
# Parameter graph_maker is used (and removed) if given, or Graph.pm otherwise.
sub make_graph {
  my ($self, %params) = @_;
  my $graph_maker = delete($params{'graph_maker'}) || \&_default_graph_maker;
  return $graph_maker->(%params);
}
sub _default_graph_maker {
  require Graph;
  return Graph->new(@_);
}

sub init {
  my ($self, %params) = @_;
  my $N = delete($params{'N'}) || 5;
  my $K = delete($params{'K'}) || 2;

  my $graph = $self->make_graph(%params);
  $graph->set_graph_attribute (name => ($N==5 && $K==2 ? "Petersen" : "Petersen $N,$K"));

  $K = min($K%$N, (-$K)%$N);
  ### K reduced: $K
  ### cf N/2: $N/2

  $graph->add_cycle(1 .. $N);      # outer cycle
  foreach my $i (1 .. $N) {
    $graph->add_edge($i,$i+$N);    # outer to inner
  }
  foreach my $i (0 .. ($K==$N/2 ? $N/2 : $N)-1) {
    $graph->add_edge($N+1+$i, $N+1+(($i+$K)%$N));  # inner circulant
  }
  if ($graph->is_directed) {
    $graph->add_edges(map {[reverse @$_]} $graph->edges);
  }
  return $graph;
}

Graph::Maker->add_factory_type('Petersen' => __PACKAGE__);
1;

__END__

=for stopwords Ryde generalized circulant Mobius undirected Mobius Kantor Dodecahedral Desargues OEIS

=head1 NAME

Graph::Maker::Petersen - create Petersen and generalized Petersen graphs

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::Petersen;
 $graph = Graph::Maker->new ('Petersen');
 $graph = Graph::Maker->new ('Petersen', N=>7, K=>3);

=head1 DESCRIPTION

C<Graph::Maker::Petersen> creates a C<Graph.pm> graph of the Petersen
graph,

                       ___1___
                  ____/   |   \____
                 /        |        \
                2__       6       __5           N => 5
                |  ---7--/-\--10--  |           K => 2
                |      \/   \/      |        (the defaults)
                |      / \ / \      |
                |   __8--/ \--9__   |
                | --             -- |
                3-------------------4

Parameters C<N> and C<K> give generalized Petersen graphs.  For example

    $graph = Graph::Maker->new('Petersen', N=>7, K=>3);

C<N> is the number of vertices in the outer cycle, and the same again in the
inner circulant.  C<K> is how many steps between connections for the inner.
In the default Petersen 5,2 for example at inner vertex 6 step by 2 for edge
6--8.  The outer vertices are numbered C<1 .. N> and the inner C<N+1
.. 2*N>.

Should have C<N E<gt>= 3> and C<K != 0 mod N>.  K=1 is an inner vertex cycle
the same as the outer.

K will usually be in the range 1 E<lt>= K E<lt>= N/2.  Other values are
accepted but become the same as something in that range since the K steps
wrap-around and go as both K and -K mod N.  So for example 7,9 and 7,5 are
both the same as 7,2.

N=4,K=1 is equivalent to the cube graph (L<Graph::Maker::Hypercube> of 3
dimensions).  N=4,K=2 is equivalent to a Mobius ladder of 4 rungs with 2
consecutive rungs deleted.

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('Petersen', key =E<gt> value, ...)>

The key/value parameters are

    N           => integer, number of outer vertices
                             (and corresponding inner)
    K           => integer, step for inner circulant
    graph_maker => subr(key=>value) constructor, default Graph->new

Other parameters are passed to the constructor, either C<graph_maker> or
C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are added both ways
between vertices.  Option C<undirected =E<gt> 1> creates an undirected graph
and for it there is a single edge between vertices.

=back

=head1 HOUSE OF GRAPHS

House of Graphs entries for graphs here include

=over

L<https://hog.grinvin.org/ViewGraphInfo.action?id=746> (etc)

=back

    746     N=3, K=1    circular ladder 3 rungs
    1022    N=4, K=1    cube
    588     N=4, K=2
    36274   N=5, K=1    circular ladder 5 rungs
    660     N=5, K=2    Petersen
    32798   N=6, K=1    cross-connected 6-cycles
    34383   N=6, K=2
    36287   N=7, K=1    circular ladder 7 rungs
    28482   N=7, K=2
    36292   N=8, K=1    circular ladder 8 rungs
    1229    N=8, K=3    Mobius Kantor
    36298   N=9, K=1    circular ladder 9 rungs
    6700    N=9, K=3
    36310   N=10, K=1   circular ladder 10 rungs
    1043    N=10, K=2   Dodecahedral
    1036    N=10, K=3   Desargues

    24052   N=11, K=2
    27325   N=12, K=2
    1234    N=12, K=5   Nauru
    36346   N=13, K=5
    36361   N=15, K=4

    (And a few more at bigger N.)

=head1 OEIS

A few of the many entries in Sloane's Online Encyclopedia of Integer
Sequences related to these graphs include

=over

L<http://oeis.org/A077105> (etc)

=back

    A077105   number of non-isomorphic K for given N,
                K <= floor((N-1)/2), so not K=N/2 when N even
    A182054   number of independent sets in N,2 for even N
    A182077   number of independent sets in N,2 for odd N
    A274047   diameter of N,2

=head1 SEE ALSO

L<Graph::Maker>,
L<Graph::Maker::Cycle>,
L<Graph::Maker::Hypercube>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/graph-maker-other/index.html>

=head1 LICENSE

Copyright 2015, 2016, 2017, 2018, 2019, 2020, 2021 Kevin Ryde

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
