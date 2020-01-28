# Copyright 2018, 2019, 2020 Kevin Ryde
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

package Graph::Maker::EvenOddTree;
use 5.004;
use strict;
use Graph::Maker;

use vars '$VERSION','@ISA';
$VERSION = 15;
@ISA = ('Graph::Maker');


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

  my $N = delete($params{'N'}) || 0;
  my $comma = delete($params{'comma'});
  if (! defined $comma) {
    $comma = ',';
  }

  my $graph = _make_graph(\%params);
  $graph->set_graph_attribute (name => "Even/Odd Tree $N");

  my $directed = $graph->is_directed;
  my $e = 0;
  foreach my $row (1 .. $N) {
    my $child = -1;
    foreach my $i (0 .. $e) {
      my $from = $row . $comma . $i;
      $graph->add_vertex($from);
      if ($row < $N) {
        foreach (1 .. 2-($i&1)) {
          $graph->add_edge($from, ($row+1).$comma.(++$child));
        }
      }
    }
    $e = $child;
  }
  return $graph;
}

Graph::Maker->add_factory_type('even_odd_tree' => __PACKAGE__);
1;

__END__

=for stopwords Ryde

=head1 NAME

Graph::Maker::EvenOddTree - create star-like graphs

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::EvenOddTree;
 $graph = Graph::Maker->new ('evenodd_tree', N => 3);

=head1 DESCRIPTION

C<Graph::Maker::EvenOddTree> creates C<Graph.pm> even/odd tree graphs.  An
even/odd tree has, across a row, 2 children under an even position vertex
and 1 child under an odd position vertex.  Positions across a row are
reckoned starting from 0 so the first is even.

    1,0
     |  \---------\
    2,0            2,1           N => 4 rows
     |  \----\      |
    3,0       3,1  3,2
     |  \      |    |  \
    4,0  4,1  4,2  4,4  4,5

Tree N=5 is isomorphic to L<Graph::Maker::FibonacciTree>.  But in general
even/odd is not the same as Fibonacci.  Both are 1 or 2 children, but here
this goes by row position whereas Fibonacci is sibling position (second has
1 child).

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('evenodd_tree', key =E<gt> value, ...)>

The key/value parameters are

    N           => integer, number of rows
    graph_maker => subr(key=>value) constructor, default Graph->new

Other parameters are passed to the constructor, either C<graph_maker> or
C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are added in both
directions.  Option C<undirected =E<gt> 1> creates an undirected graph and
for it there is a single edge each.

=back

=head1 HOUSE OF GRAPHS

House of Graphs entries for graphs here include

=over

L<https://hog.grinvin.org/ViewGraphInfo.action?id=1310>  etc

=back

    1310   N=1, singleton
    32234  N=2, path-3
    288    N=3
    21059  N=5

=head1 SEE ALSO

L<Graph::Maker>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/graph-maker/index.html>

=head1 LICENSE

Copyright 2018, 2019, 2020 Kevin Ryde

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
