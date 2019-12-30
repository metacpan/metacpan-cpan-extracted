# Copyright 2018, 2019 Kevin Ryde
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

package Graph::Maker::OliveTree;
use 5.004;
use strict;
use Graph::Maker;

use vars '$VERSION','@ISA';
$VERSION = 14;
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
  my $graph = _make_graph(\%params);
  $graph->set_graph_attribute (name => "Olive Tree $N");

  my $directed = $graph->is_directed;
  $graph->add_vertex(1);
  my $v = 2;
  foreach my $i (1 .. $N) {
    my @vertices = (1, map {$v++} 1 .. $i);
    $graph->add_path(@vertices);
    if ($directed) { $graph->add_path(reverse @vertices); }
  }
  return $graph;
}

Graph::Maker->add_factory_type('olive_tree' => __PACKAGE__);
1;

__END__

=for stopwords Ryde

=head1 NAME

Graph::Maker::OliveTree - create star-like graphs

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::OliveTree;
 $graph = Graph::Maker->new ('olive_tree', N => 3);

=head1 DESCRIPTION

C<Graph::Maker::OliveTree> creates C<Graph.pm> olive tree graphs.  An olive
tree is a root vertex with N paths below it of successive lengths 1..N.  For
example

       1
     / | \
    2  3  5        N => 3
       |  |
       4  6
          |
          7

N=0 is no arms, just the single root vertex.

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('olive_tree', key =E<gt> value, ...)>

The key/value parameters are

    N           => integer
    graph_maker => subr(key=>value) constructor, default Graph->new

Other parameters are passed to the constructor, either C<graph_maker> or
C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are added in both
directions.  Option C<undirected =E<gt> 1> creates an undirected graph and
for it there is a single edge each.

=back

=head1 SEE ALSO

L<Graph::Maker>,
L<Graph::Maker::Star>

=head1 LICENSE

Copyright 2018, 2019 Kevin Ryde

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
