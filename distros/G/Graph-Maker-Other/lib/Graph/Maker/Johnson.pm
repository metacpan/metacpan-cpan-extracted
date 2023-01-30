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

package Graph::Maker::Johnson;
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

# $aref and $bref are arrayrefs of integers sorted in ascending order.
# Return the number of integers common to both arrays.
sub _sorted_arefs_count_same {
  my ($aref, $bref) = @_;
  my $i = 0;
  my $j = 0;
  my $count = 0;
  while ($i <= $#$aref && $j <= $#$bref) {
    if ($aref->[$i] == $bref->[$j]) {
      $count++;
      $i++;
      $j++;
    } elsif ($aref->[$i] < $bref->[$j]) {
      $i++;
    } else {
      $j++;
    }
  }
  return $count;
}

# Return a list of arrayrefs which contain all the $K element subsets of
# integers 1 to $N.  The integers in each subset are in ascending order.
# The order of the subsets themselves is unspecified.
#
sub _N_K_subsets {
  my ($N, $K) = @_;

  # $pos is 0 to $K-1
  # $upto[$pos] to maximum $N-($K-1)+$pos
  # the top $upto[$K-1] runs to maximum $N-($K-1)+($K-1) = $N
  # so $upto[$pos] <= $N-$K+1+$pos
  my @ret;
  my @upto = (0);
  my $pos = 0;
  my $limit = $N-$K+1;
  for (;;) {
    ### @upto
    ### $pos
    if (++$upto[$pos] > $limit+$pos) {
      # backtrack
      if (--$pos < 0) {
        last;
      }
    } else {
      if (++$pos >= $K) {
        ### subset: "@upto"
        push @ret, [@upto];
        $pos--;
      } else {
        $upto[$pos] = $upto[$pos-1];
      }
    }
  }
  return @ret;
}


sub init {
  my ($self, %params) = @_;

  my $N = delete($params{'N'}) || 0;
  my $K = delete($params{'K'}) || 0;
  ### $N
  ### $K
  my $graph = _make_graph(\%params);

  $graph->set_graph_attribute (name => "Johnson $N,$K");

  my @vertices = _N_K_subsets($N,$K);
  foreach my $v (@vertices) {
    $graph->add_vertex(join(',',@$v));
  }

  my $add_edge = ($graph->is_directed ? 'add_cycle' : 'add_edge');
  foreach my $i_from (0 .. $#vertices-1) {
    my $from = $vertices[$i_from];
    foreach my $i_to ($i_from+1 .. $#vertices) {
      my $to = $vertices[$i_to];
      ### consider: "from=".join(',',@$from)." to=".join(',',@$to)

      my $count = _sorted_arefs_count_same($from, $to);
      ### $count
      if ($count == $K - 1) {
        my $v_from = join(',',@$from);
        my $v_to   = join(',',@$to);
        ### edge: "$v_from to $v_to"
        $graph->$add_edge($v_from, $v_to);
      }
    }
  }
  return $graph;
}

Graph::Maker->add_factory_type('Johnson' => __PACKAGE__);
1;

__END__

=for stopwords Ryde Kneser undirected

=head1 NAME

Graph::Maker::Johnson - create Johnson graphs

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::Johnson;
 $graph = Graph::Maker->new ('Johnson', N => 8, K => 3);

=head1 DESCRIPTION

C<Graph::Maker::Johnson> creates C<Graph.pm> graphs of Johnson graphs.  Each
vertex is a K-many subset of the integers 1 to N.  Edges are between
vertices which have K-1 integers the same and 1 integer different.  Vertex
names are the list of K integers separated by commas, such as "1,5,6,8".

An N,K graph is the same as an N,N-K but different vertex names.

K=1 or K=N-1 is the complete-N graph.  For K=1, the vertex names are the
same as C<Graph::Maker::Complete> (integers 1 to N).

K=2 or K=N-2 is the triangular graph, which is the line graph of the
complete-N graph.

N=5,K=2, which is triangular-5, is the complement of the Petersen graph.
The Petersen graph can be considered as the Kneser 5,2 which is edges
between pairs of integers with both different, whereas here edges between
one different.  (Neither has edges for none different as that would be
self-loops.)

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('Johnson', key =E<gt> value, ...)>

The key/value parameters are

    N  =>  integer
    K  =>  integer
    graph_maker => subr(key=>value) constructor, default Graph->new

Other parameters are passed to the constructor, either C<graph_maker> or
C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are added both forward and
backward between vertices.  Option C<undirected =E<gt> 1> creates an
undirected graph and for it there is a single edge between vertices.

=back

=head1 HOUSE OF GRAPHS

House of Graphs entries for the graphs here include

=over

=item N=4, K=2, L<https://hog.grinvin.org/ViewGraphInfo.action?id=226>

=item N=5, K=2, L<https://hog.grinvin.org/ViewGraphInfo.action?id=21154> (complement of Petersen)

=back

=head1 SEE ALSO

L<Graph::Maker>,
L<Graph::Maker::Kneser>,
L<Graph::Maker::Petersen>

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
