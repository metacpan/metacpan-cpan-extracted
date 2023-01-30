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


package Graph::Maker::Permutations;
use 5.004;
use strict;
use constant 1.02;
use Carp 'croak';
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

#----------------
# Vertex Names

sub _vertex_name_type_perm {
  my ($aref) = @_;
  return @$aref;
}

sub _perm_inverse {
  my @ret;
  foreach my $i (0 .. $#_) {
    $ret[$_[$i]] = $i;
  }
  return @ret;
}
sub _noop {
  return @_;
}

sub _vertex_name_type_inversions {
  my ($aref) = @_;
  my @ret;
  foreach my $i (0 .. $#$aref-1) {
    push @ret, 
      join('',
           map {$aref->[$i] > $aref->[$_] ? 1 : 0}
           $i+1 .. $#$aref);
  }
  return @ret;
}

sub _vertex_name_type_cycles {
  my ($aref) = @_;
  my @seen;
  my @ret = ('');
  foreach my $i (1 .. scalar(@$aref)) {
    if (! $seen[$i]++) {
      my $p = $aref->[$i-1];
      if ($seen[$p]) {
        $ret[-1] .= "($i)";
      } else {
        $ret[-1] .= "($i";
        for (;;) {
          $seen[$p] = 1;
          my $t = $aref->[$p-1];
          if ($seen[$t]) {
            push @ret,"$p)";
            last;
          }
          push @ret, $p;
          $p = $t;
        }
      }
    }
  }
  return ($ret[0] eq '' ? () : @ret);
}

#----------
# Transpose

use constant _rel_type_name_transpose => 'Transpose';
sub _rel_type_transpose {
  my ($aref, $adjacent) = @_;
  my @ret;
  foreach my $i (0 .. $#$aref-1) {
    foreach my $j ($i+1 .. ($adjacent ? $i+1 : $#$aref)) {
      if ($aref->[$i] < $aref->[$j]) {
        my @to = @$aref;
        $to[$i] = $aref->[$j];
        $to[$j] = $aref->[$i];
        push @ret, \@to;
      }
    }
  }
  return @ret;
}
use constant _rel_type_name_transpose_adjacent => 'Transpose Adjacent';
sub _rel_type_transpose_adjacent {
  return _rel_type_transpose(@_,1);
}
use constant _rel_type_name_transpose_cyclic => 'Transpose Cyclic';
sub _rel_type_transpose_cyclic {
  my ($aref) = @_;
  return
    _rel_type_transpose($aref,1),
    ($#$aref>0 && $aref->[0] < $aref->[-1]
     ? do {
       my @to = @$aref;
       $to[0] = $aref->[-1];
       $to[-1] = $aref->[0];
       \@to }
     : ());
}

use constant _rel_type_name_transpose_cover => 'Transpose Cover';
sub _rel_type_transpose_cover {
  my ($aref) = @_;
  my @ret;
  foreach my $i (0 .. $#$aref-1) {
    J: foreach my $j ($i+1 .. $#$aref) {
      next unless $aref->[$i] < $aref->[$j];
      foreach my $k ($i+1 .. $j-1) {
        next J if $aref->[$i] < $aref->[$k] && $aref->[$k] < $aref->[$j];
      }
      my @to = @$aref;
      $to[$i] = $aref->[$j];
      $to[$j] = $aref->[$i];
      push @ret, \@to;
    }
  }
  return @ret;
}

# Option C<rel_type =E<gt> 'transpose_plus1'> restricts to transposes of
# x...x+1.  So at each element x, swap with x+1 when that x+1 is somewhere
# later in the permutation.
#
#     from   x ... x+1          transpose_plus1
#      to    x+1 ... x
#
# The result is isomorphic to C<transpose_adjacent>, under suitable
# relabelling.  The initial edges at 1,2,3,4 are the same, since the
# adjacent 1,2 etc are also x,x+1.
#
use constant _rel_type_name_transpose_plus1 => 'Transpose Plus1';
sub _rel_type_transpose_plus1 {
  my ($aref) = @_;
  my @ret;
  foreach my $i (0 .. $#$aref-1) {
    my $target = $aref->[$i] + 1;
    foreach my $j ($i+1 .. $#$aref) {
      if ($aref->[$j] == $target) {
        my @to = @$aref;
        $to[$i]++;
        $to[$j]--;
        push @ret, \@to;
      }
    }
  }
  return @ret;
}

#---------
# Onepos

# =head2 Onepos
# 
# Option C<rel_type =E<gt> 'onepos'> is at each position in a permutation,
# step to the next bigger which is later, and sort what had been there and
# the rest in ascending order, as a kind of minimum increment.
# 
#     from  x A y B         where y smallest > x      onepos
#      to   y sort(x,A,B)

use constant _rel_type_name_onepos => 'Onepos';
sub _rel_type_onepos {
  my ($aref) = @_;
  my @ret;
 OUTER: foreach my $i (0 .. $#$aref-1) {
    my @rest = sort @{$aref}[$i..$#$aref];
    if ($rest[-1] > $aref->[$i]) {
      foreach my $j (0 .. $#rest) {
        if ($rest[$j] > $aref->[$i]) {
          my ($next) = splice @rest, $j, 1;
          push @ret, [ @{$aref}[0 .. $i-1],
                       $next,
                       @rest ];
          next OUTER;
        }
      }
    }
  }
  return @ret;
}

#-------------
# Cycle Append

# =head2 Cycle Append
# 
# The default C<rel_type =E<gt> 'cycle_append'> appends one cycle to another
# to reach a new permutation.  For example
# 
#     from  (1,3,2)(4,5)
#      to   (1,3,2,4,5)
# 
# The cycles are taken with their smallest element first.  The append thus
# splices in at what would be the return to the smallest element in each.
# 
# The number of cycles decreases by 1 each step, going from (1)(2)(3)(4) to
# end at one of the single cycles (1234), (1324), etc.
#
    # cycle_append
    #   872    N=3


use constant _rel_type_name_cycle_append => 'Cycle Append';
sub _rel_type_cycle_append {
  my ($aref) = @_;
  my @seen;
  my @cycle_end;
  foreach my $i (1 .. scalar(@$aref)) {
    if (! $seen[$i]++) {
      my $p = $i;
      for (;;) {
        $seen[$p] = 1;
        my $t = $aref->[$p-1];
        if ($seen[$t]) {
          ### cycle found: "$i to $p"
          $cycle_end[$i] = $p;
          last;
        }
        $p = $t;
      }
    }
  }

  my @ret;
  foreach my $i (1 .. $#cycle_end) {
    next unless $cycle_end[$i];
    foreach my $j ($i+1 .. $#cycle_end) {
      next unless $cycle_end[$j];

      my @to = @$aref;
      $to[$cycle_end[$i]-1] = $j;
      $to[$cycle_end[$j]-1] = $i;
      push @ret, \@to;

      ### cycle append: "$i to $cycle_end[$i] append $j to $cycle_end[$j]"
      ### is: join(',',@to)
    }
  }
  return @ret;
}

#------------------

sub init {
  my ($self, %params) = @_;
  ### Permutations init ...

  my $N = delete($params{'N'}) || 0;

  my $rel_type = delete($params{'rel_type'}) || 'onepos';
  my $rel_type_func = $self->can("_rel_type_$rel_type")
    || croak "Unrecognised rel_type: ",$rel_type;

  my $rel_direction = delete($params{'rel_direction'}) || 'up';

  my $vertex_name_type = delete($params{'vertex_name_type'}) || 'perm';
  my $order = delete($params{'order'}) || 'pre';
  my $vertex_name_func = $self->can("_vertex_name_type_$vertex_name_type")
    || croak "Unrecognised vertex_name_type: ",$vertex_name_type;
  my $inverse_func = (delete $params{'vertex_name_inverse'}
                      ? \&_perm_inverse
                      : \&_noop);

  my $comma = delete($params{'comma'});
  if (! defined $comma) {
    $comma = ',';
  }

  my $graph = _make_graph(\%params);
  $graph->set_graph_attribute
    (name => "Permutations N=$N, " . $self->can("_rel_type_name_$rel_type")->());

  unless ($graph->is_directed) {
    $rel_direction = 'up';
  }
  my $up   = ($rel_direction ne 'down');
  my $down = ($rel_direction ne 'up');

  if ($N==0) {
    $graph->add_vertex('');
  } else {
    my @array = (1.. $N);
    my @upto;
    my $pos = 0;
    $upto[0] = -1;
    for (;;) {
      ### at: join('',@array)." upto ".join(',',@upto[0..$pos])." pos=$pos"

      if ($upto[$pos] > $pos) {
        ($array[$pos], $array[$upto[$pos]]) = ($array[$upto[$pos]], $array[$pos]);
        ### unswap: "$pos and $upto[$pos]"
        ### array: join('',@array)
      }

      if (++$upto[$pos] >= $N) {
        ### backtrack ...
        last if --$pos < 0;
        next;
      }

      ($array[$pos], $array[$upto[$pos]]) = ($array[$upto[$pos]], $array[$pos]);
      ### swap: "$pos and $upto[$pos]"
      ### array: join('',@array)
      if ($pos < $N-2) {
        $pos++;
        $upto[$pos] = $pos-1;
        ### descend: "pos=$pos"
      } else {

        my $from = join($comma,$vertex_name_func->(\@array));
        $graph->add_vertex($from);
        ### $from

        foreach my $to_aref ($rel_type_func->(\@array)) {
          my $to = join($comma,$vertex_name_func->($to_aref));
          ### to array: join('',@$to_aref)
          ### $to
          if ($up)   { $graph->add_edge($from,$to); }
          if ($down) { $graph->add_edge($to,$from); }
        }
      }
    }
  }
  return $graph;
}

Graph::Maker->add_factory_type('permutations' => __PACKAGE__);
1;

__END__

#------------------------------------------------------------------------------

=for stopwords Ryde coderef undirected OEIS Bruhat

=head1 NAME

Graph::Maker::Permutations - create transposition graph and more

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::Permutations;
 $graph = Graph::Maker->new ('permutations', N => 4);

=head1 DESCRIPTION

C<Graph::Maker::Permutations> creates C<Graph.pm> graphs where each vertex
is a permutation of the integers 1..N.  N=0 is understood as an empty
permutation.

    num vertices = N! = 1,1,2,6,24,120, ...   (A000142)

=cut

# GP-Test  vector(6,N,N--; N!) == [1,1,2,6,24,120]

=pod

The default is the transpositions graph (see L</Transpose> below).

=head2 Vertex Names

Option C<vertex_name_type> chooses the vertex name style.  The default
C<vertex_name_type =E<gt> 'perm'> is a list of integers 1 to N.

    4,1,3,2       perm
    1 2 3 4       position, so 1->4, 2->1, etc

Option C<vertex_name_type =E<gt> 'cycles'> is list of cycles

    (1,4,2)(3)    cycles  

In the usual way a cycle like (1,4,2) means permute 1-E<gt>4, 4-E<gt>2,
2-E<gt>1.  For vertex names the cycles have their smallest element first and
in order of the smallest element.

=head3 Comma

Option C<comma =E<gt> "string"> is the separator to use between quantities
in the vertex names.  The default is comma ",".

When N E<lt> 10, permutation terms are single digits and omitting the comma
might be preferred for compact viewing.  N=10 ambiguity would be at 10! =
3628800 many vertices which is probably too big to be practical, but may be
just in reach of a fast machine with plenty of memory.

=cut

# GP-DEFINE  10! == 3628800

=pod

=head2 Transpose

The default C<rel_type =E<gt> 'transpose'> is graph edges where swapping two
elements in the permutation gives a lexicographically bigger permutation.

    from  x ... y      transpose
     to   y ... x       values x<y                     

        --> 2,1,3 --> 2,3,1 --\
       /         \   ^         v          N => 3
    1,2,3  --------X------->  3,2,1       rel_type => "transpose"
       \         /   v         ^
        --> 1,3,2 --> 3,1,2 --/

Each permutation has binomial(N,2) element pairs, and across all
permutations they are, by symmetry, half smaller-bigger and half
bigger-smaller so

    num edges = N!*N*(N-1)/4
              = 0,0,1,9,72,600,5400,...     (A001809)

=cut

# GP-DEFINE  transpose_num_edges(N) = N!*N*(N-1)/4;
# GP-Test  vector(7,N,N--; transpose_num_edges(N)) == [0,0,1,9,72,600,5400]
#
# The "transpose_..." relation types below restrict to just some transposes so
# are edge subsets of full "transpose".

=pod

=head2 Transpose Cover

Option C<rel_type =E<gt> 'transpose_cover'> restricts to those transposes
which are cover relations of the transposes (so the Hasse diagram).  This
means if a path u -E<gt> z -E<gt> ... -E<gt> v exists then omit direct u
-E<gt> v.  In N=3 this means no edge 123 -E<gt> 321.

        --> 2,1,3 --> 2,3,1 --\
       /         \   ^         v       N => 3
    1,2,3          X          3,2,1    rel_type => "transpose_cover"
       \         /   v         ^
        --> 1,3,2 --> 3,1,2 --/

A cover is when the x...y swap has, between those locations, no values
between x and y.  If such an intermediate t then could do the x,y swap by
three transposes x,t, t,y, x,t, which in each case are lex increases.  This
is seen across the top of N=3 above.  Other combinations using t are
possible too.  The number of covers is

    num edges = sum 1<=i<j<N of N!/(j-i+1)
              = 0,0,1,8,58,444,3708,...    (A002538)

This sum is per David Callan in OEIS A002538.  Elements i and j are to be
swapped.  Those and the i+1,i+2,...,j-1 values between them are ordered
(j-i+1)! ways (within the whole permutation).  But cannot have intermediate
values between i,j.  Perms of i..j with i,j adjacent are only (j-i)!, so
fraction (j-i)!/(j-i+1)! = 1/(j-i+1) of all N! perms.

=cut

# GP-DEFINE  \\ formula per A002538 but starting N=2 at value=1
# GP-DEFINE  transpose_cover_num_edges(N) = /* per A002538 */ \
# GP-DEFINE    if(N<=1,0, (N+1)*transpose_cover_num_edges(N-1) + (N-1)*(N-1)!);
# GP-Test  vector(7,N,N--; transpose_cover_num_edges(N)) == [0,0,1,8,58,444,3708]
#
# new element N at any of N positions
# covers in N-1 still good so N*covers(N-1)
# covers i to N has new N bigger
# so x ... N with N at any position
#
# sum N* for i<j<N
# then j=N
# vector(10,N, sum(i=1,N-1, N!/(N-i+1)))
# vector(10,N, sum(i=1,N-1, N!/(N-i+1)) + N*transpose_cover_num_edges(N-1))
# A001705 gen Stirling 
# vector(10,N, sum(i=1,N-1, N!/(N-i+1)) - transpose_cover_num_edges(N-1))

=pod

An "inversion" in a permutation is a pair of out-of-order elements, so x...y
with xE<gt>y.  A cover transpose increases the number of inversions by +1.
A transpose of x,y with xE<lt>y goes to yE<gt>x so +1 inversions.  If an
element tE<gt>y is between them then +1 inversion for new t,x position but
-1 for new y,t.  Similarly the other way for an element smaller E<lt>x.  An
element t between x and y values would be +2 inversions.  So an equivalent
definition is to take cover as step by +1 inversion.

=head2 Transpose Adjacent

Option C<rel_type =E<gt> 'transpose_adjacent'> restricts to swapping an
adjacent pair of elements.  This is the weak Bruhat order.

    from  x y     transpose_adjacent
     to   y x        values x<y

        --> 2,1,3 --> 2,3,1 --\
       /                       v       N => 3
    1,2,3                     3,2,1    rel_type => "transpose_cover"
       \                       ^
        --> 1,3,2 --> 3,1,2 --/

Each of the N-1 non-last elements has a next neighbour and by symmetry they
are half smaller-bigger and half bigger-smaller so

    num edges = N!*(N-1)/2, or 0 if N=0
              = 0,0,1,6,36,240,1800,...     (A001286)

=cut

# GP-DEFINE  transpose_adjacent_num_edges(N) = if(N==0,0, N!*(N-1)/2);
# GP-Test  vector(7,N,N--; transpose_adjacent_num_edges(N)) == \
# GP-Test    [0,0,1,6,36,240,1800]

=pod

=head2 Transpose Cyclic

Option C<rel_type =E<gt> 'transpose_cyclic'> restricts to transposing an
adjacent pair of elements, with adjacent including wraparound so first and
last can swap.

    from  x y   or    [start] x ... y [end]    transpose_cyclic
     to   y x         [start] y ... x [end]     values x<y

For N=3 this is the same as all C<transpose>, but in bigger N there are
fewer edges.  Each of the N elements has a next neighbour wrapping around
and by symmetry they are half smaller-bigger and half bigger-smaller so

    num edges = N!*N/2, or 0 if N=1
              = 0,0,2,9,48,300,2160,...     (A074143)

=cut

# GP-DEFINE  transpose_cyclic_num_edges(N) = if(N==1,0, N!*N/2);
# GP-Test  vector(7,N,N--; transpose_cyclic_num_edges(N)) == \
# GP-Test    [0,0,2,9,48,300,2160]

=pod

=head2 Relation Direction

For a directed graph, edges are in the direction of the rules above.  This
is the default C<rel_direction =E<gt> 'up'>, being a lexicographic increase
in the perm.  Direction "down" is the opposite, the same as
C<$graph-E<gt>transpose>.  Direction "both" is edges both ways.  An
undirected graph is just one edge between vertices in all cases.

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('permutations', key =E<gt> value, ...)>

The key/value parameters are

    N            => integer, represented trees size
    graph_maker  => subr(key=>value) constructor,
                     default Graph->new

    rel_type     => string
      "transpose" (default), "transpose_cover"
      "transpose_adjacent", "transpose_cyclic"

    rel_direction     => string "up" (default), "down", "both"

    vertex_name_type  => string
      "perm" (default), "cycles"

    comma        => string, default "," or empty ""

Other parameters are passed to the constructor, either the C<graph_maker>
coderef or C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are only in the
"successor" direction for the given C<rel_type>.

=back

=head1 HOUSE OF GRAPHS

House of Graphs entries for graphs here include

=over

L<https://hog.grinvin.org/ViewGraphInfo.action?id=1310>  etc

=back

    all rel_type
      1310   N=0 and N=1, singleton
      19655  N=2, path-2

    transpose
      84     N=3
      1277   N=4, Reye graph
      33628  N=5

    transpose_cover
      938    N=3
      33636  N=4
      33638  N=5

    transpose_adjacent
      670    N=3, 6-cycle
      1391   N=4, truncated octahedral

    transpose_cyclic
      84     N=3, same as all transposes
      1292   N=4

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
this tree include

=over

L<http://oeis.org/A000142> (etc)

=back

    A000142    num vertices, N!

    transpose
      A001809    num edges
      A165208    num paths start to end

    transpose_cover
      A002538    num edges
      A061710    num paths start to end
                  (= num max-length paths in transpose)

    transpose_adjacent
      A001286    num edges
      A007767    num intervals
      A005118    num paths start to end

    transpose_cyclic
      A074143    num edges

    onepos
      A067318    num edges, total transpositions

In the above, "num intervals" is the number of pairs of vertices $u to $v
where $v is reachable from $u.  In a lattice this means $u and $v are
comparable.  $u reachable from $u itself is included (an empty path), so sum
C<1 + $graph-E<gt>all_successors($u)> over all $u.

=head1 SEE ALSO

L<Graph::Maker>,
L<Graph::Maker::Catalans>

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
