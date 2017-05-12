# Copyright 2015, 2016, 2017 Kevin Ryde
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

use vars '$VERSION','@ISA';
$VERSION = 6;
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

  my $graph = _make_graph(\%params);
  $graph->set_graph_attribute (name => "Petersen");

  $graph->add_cycle(1,2,3,4,5);
  $graph->add_cycle(6,8,10,7,9);
  $graph->add_edges([1,6],[2,7],[3,8],[4,9],[5,10]);

  if ($graph->is_directed) {
    $graph->add_edges(map {[reverse @$_]} $graph->edges);
  }
  return $graph;
}

Graph::Maker->add_factory_type('Petersen' => __PACKAGE__);
1;

__END__

=for stopwords Ryde

=head1 NAME

Graph::Maker::Petersen - create Petersen graph

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::Petersen;
 $graph = Graph::Maker->new ('Petersen');

=head1 DESCRIPTION

C<Graph::Maker::Petersen> creates a C<Graph.pm> graph of the Petersen
graph.

                       ___1___ 
                  ____/   |   \____
                 /        |        \
                5__       6       __2
                |  --10--/ \--7---  |
                |      \/   \/      |
                |      /--_- \      |
                |   __9--   --8__   |
                | --             -- |
                4-------------------3

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('Petersen', key =E<gt> value, ...)>

The key/value parameters are

    graph_maker => subr(key=>value) constructor, default Graph->new

Other parameters are passed to the constructor, either C<graph_maker> or
C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are added both forward and
backward between vertices.  Option C<undirected =E<gt> 1> creates an
undirected graph and for it there is a single edge between vertices.

=back

=head1 SEE ALSO

L<Graph::Maker>

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
