# Copyright 2015, 2016, 2017 Kevin Ryde
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

our $VERSION = 8;


has graph => (default  => sub {
                require GraphViz2;
                return GraphViz2->new;  # directed=>0 is default
              },
              is       => 'rw',
              # isa     => 'GraphViz2',  # class requirement not enforced
              required => 0,
             );

# this not documented yet ...
sub default_vertex_name_func {
  return $_[0];
}

sub create {
  my ($self, %params) = @_;

  # this parameter not documented yet ...
  my $vertex_name_func = $params{'vertex_name_func'}
    || \&default_vertex_name_func;

  my $graph = $self->graph;
  my $ret = Graph::Graph6::read_graph
    (filename => $params{'file_name'},
     fh       => $params{'fh'},
     str      => $params{'str'},

     # Setting directedness is undocumented circa GraphViz2 2.46.  Would
     # quite like to set it, reckoned as information from the input applied
     # to the graph, but would want something like a default_global() to
     # control its global attributes like "directed".
     #
     # format_func => sub {
     #   my ($format) = @_;
     #   $graph->global->{'directed'}
     #     = ($format eq 'digraph6' ? 'digraph' : 'graph');
     # },

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

 # or in one chain ...
 my $graphviz2 = GraphViz2::Parse::Graph6->new
                   ->create(str => ":Bf\n")
                   ->graph;  # GraphViz2 object

=head1 DESCRIPTION

C<GraphViz2::Parse::Graph6> reads a graph6 or sparse6 format file into a
C<GraphViz2> graph object.  These file formats are per

=over 4

L<http://cs.anu.edu.au/~bdm/data/formats.txt>

=back

The formats represent a graph with vertices numbered 0 to n-1.  These are
made into C<GraphViz2> vertex names as numbers like "0" to "99".

graph6 and sparse6 are undirected.  sparse6 can have multi-edges and self
loops.  They are added to the graph with multiple C<add_edge()> in the usual
way.

See L<Graph::Graph6> for further notes on the formats.

=head1 FUNCTIONS

=over

=item C<$parse = GraphViz2::Parse::Graph6-E<gt>new (key=E<gt>value, ...)>

Create and return a new parse object.  The only key/value parameter is a
graph to read into

    graph   => GraphViz2 object

The default is to create a suitable undirected C<graph>.  Currently no
options or attributes are set on this default.

graph6 and sparse6 have no attributes (only vertex numbers and edges) so
it's up to an application to set any desired drawing styles.  That can be
done by giving a C<graph> with options, or by retrieving the
C<$parse-E<gt>graph> created and adding to it.  Note that C<node> or C<edge>
defaults should be set before reading with C<create()> since those settings
apply only to subsequently added nodes and edges.  A C<graph> given should
be undirected (which is the C<GraphViz2> default).

=item C<$graphviz2 = $parse-E<gt>graph ()>

=item C<$parse-E<gt>graph ($graphviz2)>

Get or set the graph object which C<create()> will write into.

=item C<$parse-E<gt>create (key=E<gt>value, ...)>

Read a graph from a file or string of graph6 or sparse6 data.  The key/value
parameters are

    file_name  => filename (string)
    fh         => file handle (globref)
    str        => string of graph6 or sparse6

One of these must be given as the input source.  The return value is the
C<$parse> object itself if successful, or C<undef> at end of file.

Invalid file contents or read error call the graph object C<log()> method
C<$graphviz2-E<gt>log(error=E<gt>"...")>, which by default is a C<die>.

It's common to have several graphs in a graph6 or sparse6 file, one after
the other.  They can be read successively by giving C<fh> as an open handle
to such a file.  After a successful read the handle is left positioned at
the next graph.

The end-of-file C<undef> return is given for C<fh> reaching EOF, or
immediate EOF on an empty file or empty C<str>.  This is designed to make
the three inputs the same (C<file_name> equivalent to open and C<fh>, or
both equivalent to slurp and contents as C<str>).  An application can
consider whether an empty file should mean no graphs or some error.

A C<$parse> object can be re-used to read further graphs.  Set a new empty
C<graph> to write to each time.  See F<examples/graphviz2-geng.pl> for a
complete sample program doing this.

=pod

=back

=head1 BUGS

digraph6 format is accepted by the code here, but the handling of
directedness of the resulting C<GraphViz2> object is not quite right.  The
intention is for C<create()> to set directedness of the target C<graph>,
reckoning directedness as being part of the input read, ie. the format
graph6, sparse6 or digraph6.  But C<GraphViz2> circa 2.46 takes directedness
only when creating the graph, not a later change.  For now reading digraph6
works if the application passes in a directed C<graph>.

=head1 SEE ALSO

L<GraphViz2>,
L<GraphViz2::Parse::Yacc>

L<Graph::Graph6>,
L<nauty-showg(1)>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/graph-graph6/index.html>

=head1 LICENSE

Copyright 2015, 2016, 2017 Kevin Ryde

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

