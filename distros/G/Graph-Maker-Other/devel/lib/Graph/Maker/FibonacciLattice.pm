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


package Graph::Maker::FibonacciLattice;
use 5.004;
use strict;
use Graph::Maker;

use vars '$VERSION','@ISA';
$VERSION = 19;
@ISA = ('Graph::Maker');

# uncomment this to run the ### lines
# use Smart::Comments;


sub _default_graph_maker {
  require Graph;
  return Graph->new(@_);
}
sub _make_graph {
  my ($params) = @_;
  my $graph_maker = delete($params->{'graph_maker'}) || \&_default_graph_maker;
  return $graph_maker->(%$params);
}

sub init {
  my ($self, %params) = @_;
  ### FibonacciLattice init ...

  my $N = delete($params{'N'}) || 0;
  my $graph = _make_graph(\%params);
  $graph->set_graph_attribute (name => "Fibonacci Lattice N=$N");

  my @vertices = ([]);
  $graph->add_vertex('');
  foreach (1 .. $N) {
    my @new_vertices;
    foreach my $from_aref (@vertices) {
      my $from_str = join('',@$from_aref);

      foreach my $i (0 .. $#$from_aref) {
        if ($from_aref->[$i]==1) {
          my @to = @$from_aref;
          $to[$i] = 2;
          my $to_str = join('',@to);
          $graph->add_edge($from_str,$to_str);
          push @new_vertices, \@to;
        }
      }
      $graph->add_edge($from_str,$from_str.'1');
      push @new_vertices, [@$from_aref,1];
    }
    @vertices = @new_vertices;
  }
  return $graph;
}

Graph::Maker->add_factory_type('Fibonacci_lattice' => __PACKAGE__);
1;

__END__

=for stopwords Ryde Fibonacci coderef undirected OEIS Stanley

=head1 NAME

Graph::Maker::FibonacciLattice - create Fibonacci lattice graph

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::FibonacciLattice;
 $graph = Graph::Maker->new ('Fibonacci_lattice', N => 4);

=head1 DESCRIPTION

C<Graph::Maker::FibonacciLattice> creates C<Graph.pm> graphs of the
Fibonacci lattice per

=over

Richard P. Stanley, "The Fibonacci Lattice", Fibonacci Quarterly, volume
13, number 3, October 1975.
L<http://fq.math.ca/13-3.html>
L<http://fq.math.ca/Scanned/13-3/stanley.pdf>

=back

Vertex names are strings of 1s and 2s like 1122121, with sum E<lt>= N.
Edges are by increasing a 1 to 2, or by appending a 1, thus increasing the
sum by +1.  The start is an empty string.

    [empty] ---> 1 ---> 2 ---> 21            
                  \          ^             N => 3
                   \       /
                    --> 11 --> 12
                          \
                           --> 111

Stanley conceives the lattice as infinite (locally finite in that vertices
with given sum are finite).  The graph here is vertices with sums 0 to N
inclusive.

The number of vertices with sum = k is Fibonacci number F(k+1).  That
follows by making k from k-1 append 1 or k-2 append 2.  (Or equivalently per
Stanley, sum over binomials choosing where 1s.)

    VK(k) = VK(k-1) + VK(k-2)                  num vertices sum k
              starting VK(0)=1, VK(1)=1
          = Fibonacci(k+1)
          = 1, 1, 2, 3, 5, 8, 13, 21, ...      (A000045)

    V(N)   = sum(k=0,N, VK(k))             num vertices
           = Fibonacci(N+3) - 1
           = 1, 2, 4, 7, 12, 20, 33, 54, ...   (A000071)

=cut

# GP-DEFINE  VK(k) = k>=0||error(); fibonacci(k+1);
# GP-Test  VK(0) == 1
# GP-Test  VK(1) == 1
# GP-Test  vector(100,k,k++; VK(k)) == \
# GP-Test  vector(100,k,k++; VK(k-1) + VK(k-2))
# GP-Test  vector(8,n,n--; VK(n)) == [1, 1, 2, 3, 5, 8, 13, 21]
#
# GP-DEFINE  V(N) = sum(k=0,N, VK(k));
# GP-Test  vector(8,N,N--; V(N)) == [1, 2, 4, 7, 12, 20, 33, 54]
# GP-Test  vector(20,N,N--; V(N)) == \
# GP-Test  vector(20,N,N--; fibonacci(N+3) - 1) 

=pod

The number of 1s in the vertices of sum k is a similar recurrence, but an
extra 1 in the append to each V(k-1).  Count of 2s is Ones(k-1).

    Ones(k) = Ones(k-1) + VK(k-1) + Ones(k-2)      total 1s in k
                starting Ones(0)=0, Ones(1)=1
            = 0, 1, 2, 5, 10, 20, 38, 71, ...      (A001629)

=cut

# GP-DEFINE  onesandtwos_list(k) = {
# GP-DEFINE    k>=0 || error();
# GP-DEFINE    if(k==0,return([[]]));
# GP-DEFINE    my(vec=onesandtwos_list(k-1),
# GP-DEFINE       ret=List([]));
# GP-DEFINE    for(i=1,#vec,
# GP-DEFINE      for(j=1,#vec[i],
# GP-DEFINE        if(vec[i][j]==1,
# GP-DEFINE           my(new=vec[i]); new[j]=2;
# GP-DEFINE           listput(ret,new)));
# GP-DEFINE      listput(ret,concat(vec[i],[1])));
# GP-DEFINE    Set(ret);
# GP-DEFINE  }
# GP-Test  onesandtwos_list(0) == [ [] ]
# GP-Test  onesandtwos_list(1) == [ [1] ]
# GP-Test  onesandtwos_list(2) == [ [2], [1,1] ]
# GP-Test  onesandtwos_list(3) == [ [1,2], [2,1], [1,1,1] ]
# GP-Test  vector(10,k,#onesandtwos_list(k)) == vector(10,k,VK(k))
#
# GP-DEFINE  Ones(k) = {
# GP-DEFINE    my(v=onesandtwos_list(k));
# GP-DEFINE    sum(i=1,#v, sum(j=1,#v[i], v[i][j]==1));
# GP-DEFINE  }
# A001629 
# GP-Test  vector(10,n, Ones(n)) == \
# GP-Test  vector(10,n, sum(k=1,n, k*binomial(n-k+1, k)))
# GP-Test  vector(8,n,n--; Ones(n)) == [0, 1, 2, 5, 10, 20, 38, 71]
# GP-Test  vector(10,k,k++; Ones(k)) == \
# GP-Test  vector(10,k,k++; Ones(k-1) + VK(k-1) + Ones(k-2))
# GP-Test  Ones(0) == 0
# GP-Test  Ones(1) == 1  /* 1         */
# GP-Test  Ones(2) == 2  /* 1,1 and 2 */
# GP-Test  VK(1) == 1    /* 1 only */
#
# GP-DEFINE  Twos(k) = {
# GP-DEFINE    my(v=onesandtwos_list(k));
# GP-DEFINE    sum(i=1,#v, sum(j=1,#v[i], v[i][j]==2));
# GP-DEFINE  }
# GP-Test  vector(10,n, Ones(n))  == \
# GP-Test  vector(10,n, Twos(n+1))

=pod

Edges leaving k are each such 1 becoming 2, and an append 1 to each vertex.
Total graph edges are sum over k

    EK(k) = Ones(k) + V(k)                    num edges leaving k
          = 1, 2, 4, 8, 15, 28, 51, 92, ...   (A029907)

    E(N)  = sum(k=0,N-1, EK(k)                num edges
          = 0, 1, 3, 7, 15, 30, 58, 109, ...   (A023610)

=cut

# GP-DEFINE  EK(k) = Ones(k) + VK(k);
# GP-Test  vector(8,n,n--; EK(n)) == [1, 2, 4, 8, 15, 28, 51, 92]
# vector(18,n,n--; EK(n)) 
#
# GP-DEFINE  E(N) = sum(k=0,N-1, EK(k));
# GP-Test  vector(8,N,N--; E(N)) == [0, 1, 3, 7, 15, 30, 58, 109]

=pod

There are various different paths possible from the empty start up to the
sum=N end vertices.  The total number is a recurrence

    P(N) = P(N-1) + (N-1)*P(N-2)
             starting P(0)=1, P(1)=1
         = 1, 1, 2, 4, 10, 26, 76, 232, ...    (A000085)

Vertices 1xxxx in N descend to empty by first descending the xxxx N-1, then
the initial 1 with no extra ways.  Vertices 2xxxx in N descend by descending
the xxxx of N-2, but with choice of where to decrease 2-E<gt>1.  That can be
done before any of the N-2 steps of xxxx, or after them, so N-1.  This paths
count is OEIS A000085 and has many other combinatorial interpretations.

=cut

# GP-DEFINE  P(N) = if(N<=1, 1, P(N-1) + (N-1)*P(N-2));
# GP-Test  vector(8,n,n--; P(n)) == [1, 1, 2, 4, 10, 26, 76, 232]

=pod


Edges leaving k are each such 1 becoming 2, and an
append 1 to each vertex.

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('FibonacciLattice', key =E<gt> value, ...)>

The key/value parameters are

    N            => integer, for sums 0 to N
    graph_maker  => subr(key=>value) constructor,
                     default Graph->new

Other parameters are passed to the constructor, either the C<graph_maker>
coderef or C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are only in the
"successor" direction.

=back

=head1 HOUSE OF GRAPHS

House of Graphs entries for graphs here include,

=over

L<https://hog.grinvin.org/ViewGraphInfo.action?id=1310>  etc

=back

    1310     N=0, singleton
    19655    N=1, path-2
    500      N=2, star-4 claw
    33640    N=6 (Stanley's example)

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
this tree include

=over

L<http://oeis.org/A000108> (etc)

=back

    A000071    num vertices, Fibonacci - 1
    A023610    num edges
    A029907    num edges leaving vertices of sum k
    A000085    num maximal paths

=head1 SEE ALSO

L<Graph::Maker>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/graph-maker-other/index.html>

=head1 LICENSE

Copyright 2018, 2019, 2020, 2021 Kevin Ryde

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
