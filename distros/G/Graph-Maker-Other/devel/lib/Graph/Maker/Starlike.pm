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

package Graph::Maker::Starlike;
use 5.004;
use strict;
use Graph::Maker;

use vars '$VERSION','@ISA';
$VERSION = 13;
@ISA = ('Graph::Maker');


sub _default_graph_maker {
  require Graph;
  Graph->new(@_);
}

sub init {
  my ($self, %params) = @_;

  my $arm_list = delete($params{'arm_list'});
  my $graph_maker = delete($params{'graph_maker'}) || \&_default_graph_maker;

  my $graph = $graph_maker->(%params);
  $graph->set_graph_attribute (name => "Starlike ".join(',',@$arm_list));

  my $directed = $graph->is_directed;
  $graph->add_vertex(1);
  my $v = 2;
  foreach my $i (0 .. $#$arm_list) {
    my @vertices = (1, map {$V++} 1 .. $arm_list->[$i]);
    $graph->add_path(@vertices);
    if ($directed) { $graph->add_path(reverse @vertices); }
  }
  return $graph;
}

Graph::Maker->add_factory_type('starlike' => __PACKAGE__);
1;

__END__

=for stopwords Ryde

=head1 NAME

Graph::Maker::Starlike - create star-like graphs

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::Starlike;
 $graph = Graph::Maker->new ('starlike', arm_list => [3,1,4]);

=head1 DESCRIPTION

C<Graph::Maker::Starlike> creates C<Graph.pm> starlike graphs.  A starlike
graph has a centre vertex and from it some arms which are linear paths.  For
example

                *                arm_list => [2,1,3,3]
                |
    *---*---*---*---*---*
                |
                *
                |
                *
                |
                *

A zero in C<arm_list> is taken to be arm of no vertices, resulting in
nothing added from the centre.

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('starlike', key =E<gt> value, ...)>

The key/value parameters are

    arm_list => arrayref of integers
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
L<Graph::Maker::Linear>

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
