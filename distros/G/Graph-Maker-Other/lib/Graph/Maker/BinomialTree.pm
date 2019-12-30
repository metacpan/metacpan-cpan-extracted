# Copyright 2015, 2016, 2017, 2018, 2019 Kevin Ryde
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

package Graph::Maker::BinomialTree;
use 5.004;
use strict;
use Graph::Maker;

use vars '$VERSION','@ISA';
$VERSION = 14;
@ISA = ('Graph::Maker');

# uncomment this to run the ### lines
# use Smart::Comments;


sub _default_graph_maker {
  require Graph;
  Graph->new(@_);
}

sub init {
  my ($self, %params) = @_;

  my $N     = delete($params{'N'});
  my $order = delete($params{'order'});
  my $graph_maker = delete($params{'graph_maker'}) || \&_default_graph_maker;

  my $graph = $graph_maker->(%params);

  my $limit;
  if (! defined $N) {
    $limit = 2**$order - 1;
    $graph->set_graph_attribute (name => "Binomial Tree, order $order");
  } else {
    $limit = $N-1;
    if ($N <= 0) {
      $graph->set_graph_attribute (name => "Binomial Tree, empty");
    } else {
      $graph->set_graph_attribute (name => "Binomial Tree, 0 to $limit");
    }
  }

  ### $limit
  if ($limit >= 0) {
    $graph->add_vertex(0);
    my $add_edge = ($graph->is_directed ? 'add_cycle' : 'add_edge');

    foreach my $i (1 .. $limit) {
      my $parent = $i & ~($i ^ ($i-1));  # clear lowest 1-bit
      ### edge: "$parent down to $i"
      $graph->$add_edge($parent, $i);
    }
  }
  return $graph;
}

Graph::Maker->add_factory_type('binomial_tree' => __PACKAGE__);
1;

__END__

=for stopwords Ryde undirected Viswanathan Iyer Udaya Kumar Reddy Wiener subtrees OEIS Intl Math Engg pre yyy indnum domnum

=head1 NAME

Graph::Maker::BinomialTree - create binomial tree graph

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::BinomialTree;
 $graph = Graph::Maker->new ('binomial_tree', N => 32);

=head1 DESCRIPTION

C<Graph::Maker::BinomialTree> creates a C<Graph.pm> graph of the binomial
tree with N vertices.  Vertices are numbered from 0 at the root through to
N-1.

      __0___
     /  |   \        N => 8
    1   2    4
        |   / \
        3  5   6
               |
               7

The parent of vertex n is n with its lowest 1-bit cleared to 0.  Conversely,
the children of a vertex are each change each of its low 0s to a 1, provided
the result is < N.  For example n=1000 has children 1001, 1010, 1100.  At
the root, the children are single bit powers 2^j up to the high bit of the
vertex limit N-1.

By construction, the tree is labelled in pre-order since a vertex ...1000 has
below it all ...1xxx.

=head2 Order

Option C<order =E<gt> k> is another way to specify the number of vertices.
A tree of order k has N=2^k many vertices.  Such a tree has depth levels 0
to k inclusive.  The number of vertices at depth d is the binomial
coefficient binom(k,d), hence the name of the tree.

The N=8 example above is order=3 and the number of vertices at each depth is
1,3,3,1 which are binomials (3,0) through (3,3).

=for GP-Test  binomial(3,0) == 1

=for GP-Test  binomial(3,1) == 3

=for GP-Test  binomial(3,2) == 3

=for GP-Test  binomial(3,3) == 1

A top-down definition is order k tree as two copies of k-1, one at the root
and the other a child of that root.

     k-1___
    /...\  \           order k as two order k-1
            k-1
           /...\

In the N=8 order=3 example above, 0-3 is an order=2 and 4-7 is another
order=2, with 4 starting as a child of the root 0.

A bottom-up definition is order k tree as order k-1 with a new leaf vertex
added as a new first child of each existing vertex.  The vertices of k-1
with extra low 0-bit become the even vertices of k.  An extra low 1-bit is
the new leaves.

Binomial tree order=5 appears as the frontispiece (and the paperback cover)
in Knuth "The Art of Computer Programming", volume 1, "Fundamental
Algorithms", second and subsequent editions.  Vertex labels are binary dots.

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('binomial_tree', key =E<gt> value, ...)>

The key/value parameters are

    N           =>  integer
    order       =>  integer
    graph_maker => subr(key=>value) constructor, default Graph->new

Other parameters are passed to the constructor, either C<graph_maker> or
C<Graph-E<gt>new()>.

C<N> is the number of vertices, 0 to N-1.  Or instead C<order> gives
N=2^order many vertices.

Like C<Graph::Maker::BalancedTree>, if the graph is directed (the default)
then edges are added both up and down between each parent and child.  Option
C<undirected =E<gt> 1> creates an undirected graph and for it there is a
single edge from parent to child.

=back

=head1 FORMULAS

=head2 Wiener Index

The Wiener index of a binomial tree of order k is calculated in

=over

K. Viswanathan Iyer and K. R. Udaya Kumar Reddy, "Wiener index of
Binomial Trees and Fibonacci Trees", Intl J Math Engg with Comp, 2009,
L<https://arxiv.org/abs/0910.4432>

=back

                (k-1)*4^k + 2^k
    Wiener(k) = ---------------  = 0, 1, 10, 68, 392, ... (A192021)
                       2

=cut

#      __0      order=2 total path=2*10 = 20
#     /  |
#    1   2
#        |
#        3
#
# GP-DEFINE  Wiener(k) = ( (k-1)*4^k + 2^k ) /2;
# GP-Test  Wiener(0) == 0
# GP-Test  Wiener(1) == 1    \\ 2 vertices, path=1
# GP-Test  Wiener(2) == 10
# GP-Test  Wiener(3) == 68
# GP-Test  Wiener(4) == 392

=pod

The Wiener index is total distance between pairs of vertices, so the mean
distance is, with binomial to choose 2 of the 2^k vertices,

                     Wiener(k)                k
   MeanDist(k) = ----------------  = k-1 + -------      for k>=1
                 binomial(2^k, 2)          2^k - 1

=cut

# GP-DEFINE  num_vertices(k) = 2^k;
# GP-Test  num_vertices(0) == 1
# GP-Test  num_vertices(2) == 4
#
# GP-DEFINE  MeanDist(k) = Wiener(k) / binomial(num_vertices(k),2);
# GP-Test  vector(100,k, MeanDist(k)) == \
# GP-Test  vector(100,k, k-1 + k / (2^k-1))  /* k>=1 */

=pod

The tree for kE<gt>=1 has diameter 2*k-1 between ends of the deepest and
second-deepest subtrees of the root.  The mean distance as a fraction of the
diameter is then

    MeanDist(k)    1       1              1
    ----------- = --- - ------- + -------------------
    diameter(k)    2    4*k - 4   (2 - 1/k) * (2^k-1)

                -> 1/2  as k->infinity

=cut

# GP-DEFINE  diameter(k) = 2*k-1;
# GP-Test  diameter(2) == 3
# GP-Test  diameter(3) == 5
#
# GP-DEFINE  MeanDist_over_diameter(k) = MeanDist(k) / diameter(k);
# GP-DEFINE  MeanDist_over_diameter_simplified(k) = \
# GP-DEFINE    1/2 - 1/(4*k - 2) + 1 /( (2 - 1/k) * (2^k-1) );
# GP-Test  vector(100,k, MeanDist_over_diameter_simplified(k)) == \
# GP-Test  vector(100,k, MeanDist_over_diameter(k))
# GP-Test  my(k=100000); abs(MeanDist_over_diameter(k) - 1/2) < 1e-5
# binomial_mean -> 1/2
#

=pod

=head2 Balanced Binary

An ordered tree can be coded as pre-order balanced binary by writing at each
vertex

    1,  balanced binaries of children,  0

The bottom-up definition above is a new leaf as new first child of each
vertex.  That means the initial 1 becomes 110, so starting 10 for single
vertex get repeated substitutions

    10, 1100, 11011000, ...   (A210995)

The top-down definition above is a copy of the tree as new last child, so
one copy at *2 and one at *2^2^k, giving 

    k-1:   1, tree k-1, 0
    k:     1, tree k-1, 1, tree k-1, 0, 0

    b(k) = (2^(2^k)+2) * b(k-1), starting b(0)=2
         = 2*prod(i=1,k, 2^(2^i)+2)
         = 2, 12, 216, 55728, 3652301664, ...  (A092124)

=cut

# GP-DEFINE  b(k) = if(k==0,2, (2^(2^k)+2) * b(k-1));
# vector(10,k, vpar_to_balanced_binary(vpar_make_binomial_tree(2^k))) == \
# vector(10,k, b(k))
# GP-Test  vector(9,k, b(k)) == \
# GP-Test  vector(9,k, (2^(2^k)+2) * b(k-1))  /* recurrence */
# GP-Test  vector(10,k,k--; b(k)) == \
# GP-Test  vector(10,k,k--; 2*prod(i=1,k, 2^(2^i)+2))  /* product */
# GP-Test  vector(5,k,k--; b(k)) == \
# GP-Test    [2, 12, 216, 55728, 3652301664]  /* samples */

=pod

The tree is already labelled in pre-order so balanced binary follows from
the parent rule.  The balanced binary coding is 1 at a vertex and later 0
when pre-order skips up past it.  A vertex with L many low 1-bits skips up
past L many (including itself).

    vertex n:  1, 0 x L     where L=CountLowOnes(n)

The last L goes up only to the depth of the next vertex.  The balance can be
completed by extending to total length 2N for N vertices.  The tree
continued infinitely is

    1, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, ...   (A079559)
    ^  ^     ^  ^        ^  ^     ^  ^
    0  1     2  3        4  5     6  7

=head2 Independence and Domination

From the bottom-up definition above, a tree of even N has a perfect
matching, being each odd n which is a leaf and its even attachment.  An odd
N has a near-perfect matching (one vertex left over).

Like all trees with a perfect matching, the independence number is then half
the vertices, and when N odd can include the unpaired and work outwards from
there by matched pairs so indnum = ceil(N/2).

The domination number is found by starting each leaf not in the dominating
set and its attachment vertex in the set.  This is all vertices so domnum =
floor(N/2) except N=1 domination number 1.

=head1 HOUSE OF GRAPHS

House of Graphs entries for the trees here include

=over

L<https://hog.grinvin.org/ViewGraphInfo.action?id=1310> (etc)

=back

    1310      N=1 (order=0),  single vertex
    19655     N=2 (order=1),  path-2
    32234     N=3,            path-3
    594       N=4 (order=2),  path-4
    30        N=5,            fork
    496       N=6,            E graph
    714       N=7      
    700       N=8 (order=3)
    28507     N=16 (order=4)
    21088     N=32 (order=5)
    33543     N=64 (order=6)
    33545     N=128 (order=7)

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to the
binomial tree include

=over

L<http://oeis.org/A192021> (etc)

=back

    by N vertices
      A129760   parent vertex number, clear lowest 1-bit
      A000523   height, floor(log2(N))
      A090996   number of vertices at height, num high 1-bits

    by order
      A192021   Wiener index
      A092124   pre-order balanced binary coding, decimal
      A210995     binary
      A079559     binary sequence of 0s and 1s

=for GP-Test  vector(7,k,k--; Wiener(k)) == [0, 1, 10, 68, 392, 2064, 10272]

=cut

# k=0 N=1 vertex   W=0
# k=1 N=2 vertices W=1
# k=2 N=4 vertices path, W=3+2+1 + 2+1 + 1 = 10

=pod

=head1 SEE ALSO

L<Graph::Maker>,
L<Graph::Maker::BalancedTree>,
L<Graph::Maker::BinaryBeanstalk>

=head1 LICENSE

Copyright 2015, 2016, 2017, 2018, 2019 Kevin Ryde

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
