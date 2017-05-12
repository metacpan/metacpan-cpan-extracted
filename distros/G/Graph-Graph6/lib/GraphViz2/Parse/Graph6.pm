# Copyright 2015, 2016 Kevin Ryde
#
# This file is part of Graph-Graph6.
#
# Graph-Graph6 is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Graph-Graph6 is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Graph6.  If not, see <http://www.gnu.org/licenses/>.

package GraphViz2::Parse::Graph6;
use 5.006;
use strict;
use warnings;
use Moo;
use Graph::Graph6;

our $VERSION = 6;

# uncomment this to run the ### lines
# use Smart::Comments;


has graph => (default  => sub {
                require GraphViz2;
                return GraphViz2->new;  # directed=>0 is default
              },
              is       => 'rw',
              # isa     => 'GraphViz2',  # class requirement not enforced
              required => 0,
             );

# this func not documented yet ...
sub default_vertex_name_func {
  return $_[0];
}

sub create {
  my ($self, %params) = @_;

  my $graph = $self->graph;

  # this parameter not documented yet ...
  my $vertex_name_func = $params{'vertex_name_func'}
    || \&default_vertex_name_func;

  my $ret = Graph::Graph6::read_graph
    (filename => $params{'file_name'},
     fh       => $params{'fh'},
     str      => $params{'str'},
     num_vertices_func => sub {
       my ($n) = @_;
       foreach my $i (0 .. $n-1) {
         $graph->add_node(name => $vertex_name_func->($i));
       }
     },
     edge_func => sub {
       my ($from, $to) = @_;
       $graph->add_edge(from => $vertex_name_func->($from),
                        to   => $vertex_name_func->($to));
     },
     error_func => sub {
       $graph->log(error => join('',@_));
     });

  # Normally log('error') is a die, but if it returns for any reason then
  # $ret is undef and return undef here.  Not documenting this as such yet,
  # but this is probably reasonable.
  #
  return ($ret ? $self : undef);
}

1;
__END__

=for stopwords Ryde undirected multi-edges filename GraphViz accessor

=head1 NAME

GraphViz2::Parse::Graph6 - read graph6 or sparse6 file into a GraphViz2 graph

=for test_synopsis my ($file_handle, $string)

=head1 SYNOPSIS

 use GraphViz2::Parse::Graph6;
 my $parse = GraphViz2::Parse::Graph6->new;
 $parse->create(file_name => 'foo.g6');
 my $graphviz2 = $parse->graph;  # GraphViz2 object

=head1 DESCRIPTION

C<GraphViz2::Parse::Graph6> reads a graph6 or sparse6 format file into a
C<GraphViz2> graph object.  These file formats are per

=over 4

L<http://cs.anu.edu.au/~bdm/data/formats.txt>

=back

Both formats represent an undirected graph with vertices numbered 0 to n-1.
They are made into C<GraphViz2> vertex names as numbers like "0" to "999".

Sparse6 can have multi-edges and self loops.  They are added to the graph
with multiple C<add_edge()> in the usual way.  See L<Graph::Graph6> for
further notes on the formats.

=head1 FUNCTIONS

=over

=item C<$parse = GraphViz2::Parse::Graph6-E<gt>new (key=E<gt>value, ...)>

Create and return a new parse object.  The only key/value parameter is a
graph to read into

    graph   => GraphViz2 object (or default created)

C<graph> should be undirected.  The default is a suitable new empty
C<GraphViz2>.

graph6 and sparse6 have no attributes (only vertex numbers and edges) so
it's up to an application to set any desired drawing styles.  That can be
done by giving a graph with options, or by retrieving the
C<$parse-E<gt>graph> created and adding to it.  Note that C<node> or C<edge>
defaults should be set before reading with C<create()> since those settings
apply only to subsequently added nodes and edges.

=item C<$graphviz2 = $parse-E<gt>graph ()>

=item C<$parse-E<gt>graph ($graphviz2)>

Get or set the graph object which C<create()> will write into.

=item C<$parse-E<gt>create (key=E<gt>value, ...)>

Read a given file or string of graph6 or sparse6 data.  The key/value
parameters are

    file_name  => string filename
    fh         => ref to file handle
    str        => string of graph6 or sparse6

One of these must be given as the input source.  The return value is the
C<$parse> object itself if successful, or C<undef> at end of file.

Invalid file contents or read error call the graph object C<log()> method
C<$graphviz2-E<gt>log(error=E<gt>"...")>, which by default is a C<die>.

It's common to have several graphs in a graph6 or sparse6 file one after the
other.  They can be read successively by giving C<fh> as an open handle to
such a file.  The handle is left positioned ready to read the next graph.

The end-of-file C<undef> return is given for immediate EOF on an empty file
or empty C<str> as well as C<fh> reaching EOF.  This is designed to make the
three inputs the same (C<file_name> equivalent to open and C<fh>, and both
equivalent to slurp and contents as C<str>).  An application can consider
whether an empty file should mean no graphs or some error.

A C<$parse> object can be re-used to read successive graphs from the same or
difference source.  Set a new empty C<graph> to write to each time.  See
F<examples/graphviz2-geng.pl> in the Graph-Graph6 sources for a complete
sample program doing this.

=pod

=back

=head1 SEE ALSO

L<GraphViz2>,
L<GraphViz2::Parse::Yacc>

L<Graph::Graph6>,
L<nauty-showg(1)>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/graph-graph6/index.html>

=head1 LICENSE

Copyright 2015, 2016 Kevin Ryde

Graph-Graph6 is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Graph-Graph6 is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Graph-Graph6.  If not, see L<http://www.gnu.org/licenses/>.

=cut

# The GraphViz2::Parse::Yacc etc don't document themselves as Moo.
# Don't do that here either, in case maybe it changed.
# 
# =head1 CLASS HIERARCHY
# 
# C<GraphViz2::Parse::Graph6> is a C<Moo> object,
# 
#     GraphViz2::Parse::Graph6
#       Moo::Object

