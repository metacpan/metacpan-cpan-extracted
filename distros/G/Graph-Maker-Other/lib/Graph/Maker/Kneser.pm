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

package Graph::Maker::Kneser;
use 5.004;
use strict;
use Graph::Maker;

use vars '$VERSION','@ISA';
$VERSION = 14;
@ISA = ('Graph::Maker');

# uncomment this to run the ### lines
# use Smart::Comments;

use Graph::Maker::Johnson;

sub init {
  my ($self, %params) = @_;

  my $N = delete($params{'N'}) || 0;
  my $K = delete($params{'K'}) || 0;
  ### $N
  ### $K
  my $graph = Graph::Maker::Johnson::_make_graph(\%params);

  $graph->set_graph_attribute (name => "Kneser $N,$K");
  my $directed = $graph->is_directed;

  my @vertices = Graph::Maker::Johnson::_N_K_subsets($N,$K);
  foreach my $v (@vertices) {
    $graph->add_vertex(join(',',@$v));
  }

  my $add_edge = ($graph->is_directed ? 'add_cycle' : 'add_edge');
  foreach my $i_from (0 .. $#vertices-1) {
    my $from = $vertices[$i_from];
    foreach my $i_to ($i_from+1 .. $#vertices) {
      my $to = $vertices[$i_to];
      ### consider: "from=".join(',',@$from)." to=".join(',',@$to)

      my $count = Graph::Maker::Johnson::_sorted_arefs_count_same($from, $to);
      ### $count
      if ($count == 0) {
        my $v_from = join(',',@$from);
        my $v_to   = join(',',@$to);
        ### edge: "$v_from to $v_to"
        $graph->$add_edge($v_from, $v_to);
      }
    }
  }
  return $graph;
}

Graph::Maker->add_factory_type('Kneser' => __PACKAGE__);
1;

__END__

=for stopwords Ryde Kneser undirected

=head1 NAME

Graph::Maker::Kneser - create Kneser graphs

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::Kneser;
 $graph = Graph::Maker->new ('Kneser', N => 8, K => 3);

=head1 DESCRIPTION

C<Graph::Maker::Kneser> creates C<Graph.pm> graphs of Kneser graphs.  Each
vertex is a K-many subset of the integers 1 to N.  Edges are between
vertices with all integers distinct.  Vertex names are the list of integers
separated by commas, such as "1,5,6,8".

K=1 is the complete-N graph.  Vertex names are the same as
C<Graph::Maker::Complete> (integers 1 to N).

N=5,K=2 is the Petersen graph.

N=2*K-1 is the "odd" graph K.

=for GP-Test  my(N=5,K=3); N==2*K-1

K E<gt> N/2 has no edges since the K-many subsets are each more than half of
1..N so are never disjoint

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('Kneser', key =E<gt> value, ...)>

The key/value parameters are

    N   =>  integer
    K   =>  integer
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

=item N=4, K=2, L<https://hog.grinvin.org/ViewGraphInfo.action?id=484>

=item N=5, K=2, L<https://hog.grinvin.org/ViewGraphInfo.action?id=660> (Petersen, odd 3)

=item N=6, K=2, L<https://hog.grinvin.org/ViewGraphInfo.action?id=19271>

=back

=head1 SEE ALSO

L<Graph::Maker>,
L<Graph::Maker::Johnson>

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
