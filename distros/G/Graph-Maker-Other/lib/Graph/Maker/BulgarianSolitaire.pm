# Copyright 2018, 2019, 2020, 2021 Kevin Ryde
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


package Graph::Maker::BulgarianSolitaire;
use 5.004;
use strict;
use Carp 'croak';
use List::Util 'sum';
use Graph::Maker;

use vars '$VERSION','@ISA';
$VERSION = 18;
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

# $aref is an arrayref to a partition, with terms in ascending order.
# Eg. [1,3,3,5]
# Modify the contents of $aref to the lexicographically next partition.
# Return 1 if that is done, or return 0 if no more partitions.
# The first (lex smallest) partition is [1,1,...,1] and iteration can
# proceed from there
#
# partition last terms ..., x, y
# x increment +1 as long as x+1 <= y-1, which is x<=y-2
# otherwise x increment +y, to make one last term x+y
# after x += increment and y -= increment, remaining y is applied as terms
# x,x,...,x, r where r>=x (the new incremented x that is)
#
sub _partition_next {
  my ($aref) = @_;
  ### _partition_next(): join(',',@$aref)

  if (@$aref < 2) {
    ### no more ...
    return 0;
  }
  my $y = pop @$aref;
  my $x = $aref->[-1];
  my $inc = ($x <= $y-2 ? 1 : $y);
  $aref->[-1] = ($x += $inc);
  while ($y -= $inc) {
    $inc = ($y >= $x<<1 ? $x : $y);
    push @$aref, $inc;
  }
  ### ret: join(',',@$aref)
  return 1;
}

# start 1 1 1 1 1
# 1 0 1 0 1
# ending 1, decrement by last term add to prev
# 1 0 1 0 0
# ending 0, decrement by second last +1, and all 1s
#
sub _composition_next {
  my ($aref) = @_;
  if (@$aref < 2) {
    ### no more ...
    return 0;
  }
  my $y = pop @$aref;
  $aref->[-1]++;
  push @$aref, (1) x ($y-1);
  return 1;
}

# composition parameter, whether to push new term onto end of partition,
# otherwise unshift onto start
my %compositions_to_end = (0       => 1,
                           append  => 1,
                           prepend => 0);

sub init {
  my ($self, %params) = @_;
  ### BulgarianSolitaire init ...

  my $N            = delete($params{'N'}) || 0;
  my $compositions = delete($params{'compositions'}) || 0;
  my $no_self_loop = delete($params{'no_self_loop'}) || 0;

  # $end true if new term goes at the end of the list
  my $end = $compositions_to_end{$compositions};
  if (! defined $end) {
    croak "Unrecognised compositions type: ", $compositions;
  }

  my $graph = _make_graph(\%params);
  $graph->set_graph_attribute
    (name => "Bulgarian Solitaire N=$N"
     . ($compositions ? ", Compositions ".ucfirst($compositions) : ''));

  ### $N

  my $next = $compositions ? \&_composition_next : \&_partition_next;
  my @from = (1) x $N;
  do {
    my $from_str = join(',',@from);

    my @to = map {$_ - 1} @from;    # decrement each term
    splice @to, $end ? scalar(@to) : 0, 0,  scalar(@from);  # new term
    @to = grep {$_} @to;             # discard 0s
    unless ($compositions) {
      # sort for partitions, no sort for compositions
      @to = sort {$a<=>$b} @to;
    }
    my $to_str = join(',',@to);
    ### $to_str

    if ($no_self_loop && $from_str eq $to_str) {
      $graph->add_vertex ($from_str);
    } else {
      $graph->add_edge ($from_str, $to_str);
    }
  } while ($next->(\@from));

  ### total vertices: scalar $graph->vertices
  ### total edges   : scalar $graph->edges

  return $graph;
}

Graph::Maker->add_factory_type('Bulgarian_solitaire' => __PACKAGE__);
1;

__END__

=for stopwords Ryde BulgarianSolitaire ie Griggs prepend Combinatorics coderef multigraph OEIS characterized predecessorless LargestTerm NumTerms undirected automata Combinatorial

=head1 NAME

Graph::Maker::BulgarianSolitaire - create Bulgarian solitaire trees and graphs

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::BulgarianSolitaire;
 $graph = Graph::Maker->new ('Bulgarian_solitaire', N => 6);

=head1 DESCRIPTION

X<Bulgarian solitaire>C<Graph::Maker::BulgarianSolitaire> creates
C<Graph.pm> graphs of Bulgarian solitaire steps.

                 +-+
                 v |     (self loop)
                1,2,3
                  ^
                  |
                 2,4                    N => 6
               ^     ^                has 11 vertices
              /       \
        1,1,1,3        1,5
         /            /    \
     2,2,2           6    1,1,1,1,2
       |             |
      3,3       1,1,1,1,1,1
       |
     1,1,4
       |
    1,1,2,2

Each vertex is a partition of the integer N, meaning a set of integers which
sum to N.  Vertex names are the terms in ascending order separated by
commas.  For example vertex 1,3,3,5 in N=12.

    num vertices = 1, 1, 2, 3, 5, 7, 11, 15, ...   (A000041)
    num edges = num vertices (one out each)

=cut

# GP-Test  vector(8,n,n--; numbpart(n)) == [1, 1, 2, 3, 5, 7, 11, 15]
# GP-Test  vecsum([1,3,3,5]) == 12
# GP-Test  numbpart(6) == 11

=pod

Bulgarian solitaire steps a partition by subtracting 1 from each element,
summing the subtractions as a new term, and discarding any zeros.  For
example 1,3,3,5 steps to 2,2,4,5.  Graph edges are from a partition to its
successor by this rule.

N=0 is a single empty partition.  N=1 is a single 1 partition.

=cut

# GP-DEFINE  triangular(t) = t*(t+1)/2;
# GP-Test  vector(5,t,t--; triangular(t)) == [0, 1, 3, 6, 10]

=pod

If N is a triangular number N = t*(t+1)/2 = 1,3,6,10,... then partition
1,2,3,...,t steps to itself, so is a "fixed point".  Per various authors,
all partitions in triangular N eventually reach this fixed point (because
the diagonal extent eventually decreases).  The default is to include a
self-loop at this partition so all vertices have out-degree 1.  Optional
parameter C<no_self_loop> can omit,

    $graph = Graph::Maker->new ('Bulgarian_solitaire', N => 10,
                                no_self_loop => 1);

C<no_self_loop> is intended for making such N a tree, rather than tree and
loop.

Non-triangular N gives one or more components, each with a cycle at the top.
The number of components (C<$graph-E<gt>connected_components()>), is
determined, for all N, in

=over

Ethan Akin and Morton Davis, "Bulgarian Solitaire", American Mathematical
Monthly, volume 92, number 4, April 1985, pages 237-250.
L<http://www.jstor.org/stable/2323643>

=back

    num components = num compositions of t,r up to cyclic shifts,
                       for N = triangular(t-1) + r
                = 1,1,1,1,1,1,1,2,1,1,1,2,2,1,1,1,3,4,3 ... (A037306)

Some cycles are between 2 vertices.  In an undirected simple graph, they
become a single edge between the two.  A C<multiedged=E<gt>1> or
C<countedged=E<gt>1> has two edges between them.

=cut

# GP-DEFINE  num_compositions_up_to_rotation(t,r) = \
# GP-DEFINE    sumdiv(gcd(t,r),d, eulerphi(d)*binomial(t/d,r/d)) / t;
# GP-Test  my(want=[1,1,1,1,1,1,1,2,1,1,1,2,2,1,1,1,3,4,3], \
# GP-Test     l=List()); \
# GP-Test  for(t=1,6, for(r=1,t, my(n=triangular(t-1) + r); \
# GP-Test    if(#l>=#want,break(2)); \
# GP-Test    listput(l, num_compositions_up_to_rotation(t,r)))); \
# GP-Test  Vec(l) == want

=pod

Some vertices have no predecessors, ie. in-degree 0
(C<$graph-E<gt>predecessorless_vertices()>).  These are called "Garden of
Eden" partitions after some terminology of Edward Moore in cellular
automata.  They are characterized and counted in

=over

Brian Hopkins and James A. Sellers, "Exact Enumeration of Garden of Eden
Partitions", INTEGERS: Electronic Journal of Combinatorial Number Theory,
volume 7 number 2, 2007, #A19.

=back

    num predecessorless   = 0,0,0,1,1,2,3,5,7,10,14, ... (A123975)
      = sum(j=1,up, (-1)^(j+1) * NumPartions(n - 3*j*(j+1)/2))
    num with predecessors = 1,1,2,2,4,5,8,10,15,20,28,... (A260894)

=cut

# GP-DEFINE  num_Garden_of_Eden(n) = \
# GP-DEFINE    sum(j=1,n, (-1)^(j+1) * numbpart(n - 3*j*(j+1)/2));
# GP-Test  vector(11,n,n--; num_Garden_of_Eden(n)) == \
# GP-Test    [0,0,0,1,1,2,3,5,7,10,14]
# GP-Test  vector(11,n,n--; numbpart(n) - num_Garden_of_Eden(n)) == \
# GP-Test    [1,1,2,2,4,5,8,10,15,20,28]

=pod

Predecessorless are all partitions with rank E<lt>= -2, where rank =
LargestTerm - NumTerms (per Dyson).  For example largest term 3 and having 5
or more terms is Garden of Eden.

=head2 Compositions

Option C<compositions =E<gt> $type> applies the solitaire rule to
compositions of N (partitions with ordered terms).  Griggs and Ho call this
X<Carolina solitaire>"Carolina solitaire".  C<$type> can be "append" to
append the new term or "prepend" to prepend.  Append and prepend give the
same structure, just with terms in each composition reversed.

    1,2,1 ---> 1,3  ---->  2,2 <--- 3,1 <-- 4 <-- 1,1,1,1
              ^   ^       /
             /     \     v                N => 4
         2,1,1      1,1,2          compositions => 'append'

The number of compositions is

    num vertices = 2^(N-1), or 1 if N=0 = 1,1,2,4,8,16,... (A011782)
    num edges = num vertices (one out each)

Hopkins and Jones show the number of Garden of Eden compositions is 2^(N-1)
- Fibonacci(N+1).

=cut

# vector(10,n,n--; if(n==0,1,2^(n-1)))
# GP-Test  my(n=4); 2^(n-1)-fibonacci(n+1) == 3   /* N=4 above */
# GP-Test  my(n=1); 2^(n-1)-fibonacci(n+1) == 0
# GP-Test  vector(8,n,n+=2; 2^(n-1)-fibonacci(n+1)) == [1,3,8,19,43,94,201,423]
# A008466

=pod

=over

Brian Hopkins, Michael A. Jones, "Shift-Induced Dynamical Systems on
Partitions and Compositions", The Electronic Journal of Combinatorics
13 (2006), #R80.

=back

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('Bulgarian_solitaire', key =E<gt> value, ...)>

The key/value parameters are

    N             => integer, to partition
    compositions  => string "0", "append", "prepend"
                       default "0"
    no_self_loop  => boolean, default false
    graph_maker   => subr(key=>value) constructor, default Graph->new

C<compositions> defaults to "0" meaning not compositions, but partitions.
C<no_self_loop> omits the self-loop at the fixed point of triangular N.

Other parameters are passed to the constructor, either C<graph_maker>
coderef or C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are added just in the
successor direction.  Option C<undirected =E<gt> 1> creates an undirected
graph.  Some steps can be a 2-cycle A-E<gt>B and back B-E<gt>A.  In an
undirected multigraph they are two edges.

=back

=head1 HOUSE OF GRAPHS

House of Graphs entries for graphs here include the following.  House of
Graphs is undirected simple graphs, so for example N=2 is a directed 2-cycle
which as simple undirected is a 2-path.  N=8 includes such a 2-cycle
collapsing too.

=over

L<https://hog.grinvin.org/ViewGraphInfo.action?id=1310>  etc

=back

    1310    N=1, singleton
    19655   N=2, path-2
    32234   N=3, path-3
    330     N=4
    820     N=5
    32254   N=6
    32380   N=7
    32256   N=8
    32382   N=9
    32258   N=10
    32384   N=11
    32386   N=12
    32388   N=13
    32390   N=14
    32260   N=15
    32392   N=16

Compositions are the same as partitions for NE<lt>=2, and then

    594     N=3, path-4

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
these graphs include

=over

L<http://oeis.org/A000041> (etc)

=back

    A000041    num vertices = num partitions
                 = num edges too
    A260894    num with predecessors
    A123975    num predecessorless, Garden of Eden
    A037306    num connected components
    A054531    smallest cycle length = girth, for N>=1
    A277227      same, for N>=0
    A183110    longest cycle length 
    A201144    longest path length (non-repeating)

For N=triangular (so a tree),

    A066655    num vertices = num partitions of triangular
                 = num edges too
    A002378    tree height (pronic numbers)

Compositions,

    A011782    num vertices = 2^(N-1) or 1 when N=0
    A000045    num with predecessors = Fibonacci(N+1)
    A008466    num predecessorless, Garden of Eden
                 = 2^(N-1) - Fibonacci(N+1)

=cut

# vector(10,n,n--; 2^max(0,n-1))

=pod

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
