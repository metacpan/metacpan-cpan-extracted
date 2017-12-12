# Copyright 2016, 2017 Kevin Ryde
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

package Graph::Maker::BinaryBeanstalk;
use 5.004;
use strict;
use Graph::Maker;

use vars '$VERSION','@ISA';
$VERSION = 10;
@ISA = ('Graph::Maker');


# uncomment this to run the ### lines
# use Smart::Comments;


sub _default_graph_maker {
  require Graph;
  Graph->new(@_);
}
sub init {
  my ($self, %params) = @_;

  my $height = delete($params{'height'});
  my $N      = delete($params{'N'});
  my $graph_maker = delete($params{'graph_maker'}) || \&_default_graph_maker;

  my $graph = $graph_maker->(%params);

  if ((defined $height && $height > 0)
      || (defined $N && $N > 0)) {
    $graph->add_vertex(0);
    my $directed = $graph->is_directed;

    my $row_start = 0;
    my $v = 1;
    my $h = 1;
    for (;;) {
      my $parent = $v - _count_1_bits($v);
      ### at: "$v parent $parent  h=$h"
      if ($parent >= $row_start) {
        $row_start = $v;

        $h++;
        if (defined $height && $h > $height) {
          # stop for height limit
          $graph->set_graph_attribute(name=>"Binary Beanstalk height $height");
          last;
        }
      }
      if (defined $N && $v >= $N) {
        # stop for N limit
        $graph->set_graph_attribute (name => "Binary Beanstalk $N Vertices");
        last;
      }

      $graph->add_edge($parent, $v);
      if ($directed) { $graph->add_edge($v, $parent); }

      $v++;
    }
  } else {
    $graph->set_graph_attribute (name => "Binary Beanstalk empty");
  }
  return $graph;
}

sub _count_1_bits {
  my ($n) = @_;
  my $count = 0;
  while ($n) {
    $count += ($n & 1);
    $n >>= 1;
  }
  return $count;
}

Graph::Maker->add_factory_type('binary_beanstalk' => __PACKAGE__);
1;

__END__

__END__

=for stopwords Ryde OEIS undirected

=head1 NAME

Graph::Maker::BinaryBeanstalk - create binary beanstalk graph

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::BinaryBeanstalk;
 $graph = Graph::Maker->new ('binary_beanstalk', height => 4);

=head1 DESCRIPTION

C<Graph::Maker::BinaryBeanstalk> creates C<Graph.pm> graphs of the binary
beanstalk per OEIS A179016 etc.

    12  13  14  15
      \ /    \ /
       10    11           height => 8
         \  /
           8   9
            \ /
         6   7
          \ /
           4   5
            \ /
         2   3
          \ /
           1
           |
           0

=for GP-Test  vector(16,n,n--; n-hammingweight(n)) == [0,0,1,1,3,3,4,4,7,7,8,8,10,10,11,11]

Vertices are integers starting at root 0.  Vertex n has parent
n-CountOneBits(n).  For example 9 = 1001 binary has 2 1-bits so parent
9-2=7.  For nE<gt>=1 each vertex has either 0 or 2 children, hence "binary"
beanstalk.

After the root there are exactly 0 or 2 children.  There are always 2
children since if a given even vertex c has parent c-CountOneBits(c)=n then
the next vertex c+1 has same

    parent(c+1) = (c+1) - (CountOneBits(c)+1)  = n

There are no more than 2 children since the next even vertex c+2 has 1-bit
count

    CountOneBits(c+2) <= CountOneBits(c) + 1
    equality when c==0 mod 4, otherwise less

due to flipping run of 1-bits at second lowest bit position.  So parent(c+2)
E<gt>= c+2 - (CountOneBits(c)+1) = n+1, so not the same n parent of c.

=for GP-Test  binary(14) == [1,1,1,0]

This also means the parent n is always increasing, and therefore the
vertices in a given row are contiguous integers.  That's so of the single
vertex row 1 and thereafter remains so by parent number increasing.

The vertices in a given row which have children are not always contiguous.
The first gap occurs at depth 36 where the vertices with children are
116,117,119 skipping 118.

    120 121  122 123    124 125
     \   /    \   /      \   /
      116      117   118  119
        \     /       \   /
          112          113
           \-----v------/

=head2 Options

C<height> specifies the height of the tree, as number of rows.  Height 1 is
the root alone, height 2 is two rows being are vertices 0 and 1, etc.

C<N> specifies how many vertices, being vertex numbers 0 to N-1 inclusive.

If both C<height> and C<N> are given then the tree stops at whichever
C<height> or C<N> comes first.  Since vertex numbers in a row are
contiguous, specifying height is equivalent to an N limit of the first
vertex of the row after, so 1, 2, 4, 6, 8, etc (OEIS A213708).

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('binary_beanstalk', key =E<gt> value, ...)>

The key/value parameters are

    height  =>  integer
    N       =>  integer
    graph_maker => subr(key=>value) constructor, default Graph->new

Other parameters are passed to the constructor, either C<graph_maker> or
C<Graph-E<gt>new()>.

Like C<Graph::Maker::BalancedTree>, if the graph is directed (the default)
then edges are added both up and down between each parent and child.  Option
C<undirected =E<gt> 1> creates an undirected graph and for it there is a
single edge from parent to child.

=back

=head1 HOUSE OF GRAPHS

House of Graphs entries for graphs here include

=over

=item height=1 (N=1), L<https://hog.grinvin.org/ViewGraphInfo.action?id=1310>  (single vertex)

=item height=2 (N=2), L<https://hog.grinvin.org/ViewGraphInfo.action?id=19655>  (path-2)

=item height=3 (N=4), L<https://hog.grinvin.org/ViewGraphInfo.action?id=500>  (claw)

=item N=5, L<https://hog.grinvin.org/ViewGraphInfo.action?id=30>  (fork)

=item height=4 (N=6), L<https://hog.grinvin.org/ViewGraphInfo.action?id=334>  (H graph)

=item N=7, L<https://hog.grinvin.org/ViewGraphInfo.action?id=714>

=item height=5 (N=8), L<https://hog.grinvin.org/ViewGraphInfo.action?id=502>

=item N=13, L<https://hog.grinvin.org/ViewGraphInfo.action?id=60>

=back

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
this tree include

=over

L<http://oeis.org/A179016> (etc)

=back

    A011371    parent vertex, being n-CountOneBits(n)
    A213723    child vertex, smaller
    A213724    child vertex, bigger

    A071542    depth of vertex
    A213706    depth of vertex, cumulative
    A213708    first vertex in row
    A173601    last vertex in row
    A086876    row width (run lengths of depth)

    A055938    leaf vertices
    A005187    non-leaf vertices
    A179016    trunk vertices
    A213712    trunk increments, = count 1-bits of trunk vertex
    A213719    trunk vertex predicate 0,1
    A213729    trunk vertices mod 2
    A213728    trunk vertices mod 2, flip 0<->1
    A213732    depths of even trunk vertices
    A213733    depths of odd trunk vertices
    A213713    non-trunk vertices
    A213717    non-trunk non-leaf vertices
    A213731    0=leaf, 1=trunk, 2=non-trunk,non-leaf
    A213730    start of non-trunk subtree
    A213715    trunk position within non-leafs
    A213716    non-trunk position within non-leafs
    A213727    num vertices in subtree under n (inc self), or 0=trunk
    A213726    num leafs in subtree under n (inc self), or 0=trunk
    A257126    nth leaf - nth non-leaf
    A257130    new high positions of nth leaf - nth non-leaf
    A218254    paths to root 0
    A213707    positions of root 0 in these paths

    A218604    num vertices after trunk in row
    A213714    how many non-leaf vertices precede n
    A218608    depths where trunk is last in row
    A218606    depths+1 where trunk is last in row
    A257265    depth down to a leaf, minimum
    A213725    depth down to a leaf, maximum in subtree

    A218600    depth of n=2^k-1
    A213709    depth levels from n=2^k-1 to n=2^(k+1)-1
    A213711    how many n=2^k-1 blocks preceding given depth
    A213722    num non-trunk,non-leaf v between 2^n <= v < 2^(n+1)

=head1 SEE ALSO

L<Graph::Maker>, L<Graph::Maker::BinomialTree>

=head1 LICENSE

Copyright 2015, 2016, 2017 Kevin Ryde

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
