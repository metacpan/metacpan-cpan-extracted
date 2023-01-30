# Copyright 2021 Kevin Ryde
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


package Graph::Maker::FibonacciCube;
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

# End-most 00 xxxx becomse 01 0000.
# Otherwise start 0 xxxx becomes 1 0000
sub _fibbinary_next {
  my ($str, $Lucas) = @_;
  ### $Lucas
  ### str: substr($str,0,1)
  my $pos;
  if (($pos = rindex($str, '00',
                     length($str) - ($Lucas && substr($str,0,1) ? 3 : 2))) >= 0
      || do { $pos = -1;
              substr($str,0,1) eq '0' && (!$Lucas || $str ne '0') }) {
    #### $pos
    #### sub: substr($str,$pos+1)
    substr($str,$pos+1) = '1' . ('0' x (length($str)-$pos-2));
    return $str;
  } else {
    return undef;
  }
}

sub init {
  my ($self, %params) = @_;

  my $N = delete($params{'N'}) || 0;
  my $Lucas = delete($params{'Lucas'}) || 0;
  my $graph = _make_graph(\%params);
  $graph->set_graph_attribute (name => "Fibonacci Cube N=$N");

  my $add_edge = ($graph->is_directed ? 'add_cycle' : 'add_edge');
  my $from = '0' x $N;
  do {
    $graph->add_vertex($from);
    ### $from
    for (my $pos = 0; ($pos=index($from,'1',$pos)) >= 0; $pos++) {
      my $to = $from;
      substr($to,$pos,1) = '0';
      ### $to
      $graph->$add_edge($from, $to);
    }

  } while (defined($from = _fibbinary_next($from,$Lucas)));

  return $graph;
}

Graph::Maker->add_factory_type('Fibonacci_cube' => __PACKAGE__);
1;

__END__

=for stopwords Ryde Fibonacci FibonacciCube coderef undirected OEIS

=head1 NAME

Graph::Maker::FibonacciCube - create Fibonacci cube graphs

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Maker::FibonacciCube;
 $graph = Graph::Maker->new ('Fibonacci_cube', N => 4);

=head1 DESCRIPTION

C<Graph::Maker::FibonacciCube> creates C<Graph.pm> graphs of Fibonacci
cubes.  A Fibonacci cube N is the induced subgraph of the hypercube N formed
by keeping only vertices which as bit strings have nowhere bit pair 11.
These vertices are the fibbinary numbers.  The number of vertices if
Fibonacci number F(N+2).

    num vertices = F(N+2)
                 = 1, 2, 3, 5, 8, 13, 21, 34, ...   (A000045)

=head1 FUNCTIONS

=over

=item C<$graph = Graph::Maker-E<gt>new('Catalans', key =E<gt> value, ...)>

The key/value parameters are

    N            => integer, cube dimension
    graph_maker  => subr(key=>value) constructor,
                     default Graph->new

Other parameters are passed to the constructor, either the C<graph_maker>
coderef or C<Graph-E<gt>new()>.

If the graph is directed (the default) then edges are added in both
directions.  Option C<undirected =E<gt> 1> creates an undirected graph and
for it there is a single edge between vertices.

=back

=head1 HOUSE OF GRAPHS

House of Graphs entries for graphs here include

=over

L<https://hog.grinvin.org/ViewGraphInfo.action?id=1310>  etc

=back

    all rel_type
      1310   N=0, singleton
      19655  N=1, path-2

    below
      340    N=2, star-4, claw

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
this tree include

=over

L<http://oeis.org/A000108> (etc)

=back

    A014137    num vertices, cumulative Catalan numbers
    A000108    row widths, Catalan numbers

    below
      A006134    num edges
      A000142    num paths start to successorless, N!

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
