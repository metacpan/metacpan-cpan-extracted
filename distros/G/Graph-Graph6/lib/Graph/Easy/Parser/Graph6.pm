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

package Graph::Easy::Parser::Graph6;
use 5.006;  # Graph::Easy is 5.008 anyway
use strict;
use warnings;
use Graph::Graph6;
use Graph::Easy::Parser;

our $VERSION = 6;
our @ISA = ('Graph::Easy::Parser');

# uncomment this to run the ### lines
# use Smart::Comments;


sub _default_vertex_name_func {
  my ($n, $num_vertices) = @_;
  return sprintf '%0*d', length($num_vertices-1), $n;
}
sub _init {
  my ($self, $args) = @_;
  $self->{'vertex_name_func'} = delete $args->{'vertex_name_func'}
    || \&_default_vertex_name_func;
  return $self->SUPER::_init($args);
}

sub from_file {
  my ($self, $filename_or_fh) = @_;
  return _read_graph6($self,
                     (ref $filename_or_fh
                      ? (fh       => $filename_or_fh)
                      : (filename => $filename_or_fh)));
}
sub from_text {
  my ($self, $str) = @_;
  return _read_graph6($self, str => $str);
}

sub _read_graph6 {
  my ($self, @options) = @_;

  if (! ref $self) { $self = $self->new; } # class method
  $self->reset;

  my $graph = $self->{'_graph'};
  $graph->set_attribute (type => 'undirected');

  my $num_vertices;
  my $vertex_name_func = $self->{'vertex_name_func'};

  my $ret = Graph::Graph6::read_graph
    (@options,
     num_vertices_func => sub {
       my ($n) = @_;
       ### num_vertices_func(): $n
       $num_vertices = $n;
       foreach my $i (0 .. $n-1) {
         my $name = $vertex_name_func->($i,$num_vertices);
         $graph->add_node($name);
       }
     },
     edge_func => sub {
       my ($from, $to) = @_;
       ### edge_func() ...
       ### $from
       ### $to
       $graph->add_edge($vertex_name_func->($from,$num_vertices),
                        $vertex_name_func->($to,  $num_vertices));
     },
     error_func => sub {
       $self->error(@_);
     });
  ### $ret

  if (defined $ret && $ret == 0) {
    return undef;  # EOF
  }

  # When fatal_errors is false Graph::Easy::Parser returns a partial graph,
  # though its docs suggest undef.  Try to follow its behaviour.
  return $graph;
}

1;
__END__

=for stopwords Ryde undirected multi-edges filename

=head1 NAME

Graph::Easy::Parser::Graph6 - read graph6 or sparse6 file to a Graph::Easy graph

=for test_synopsis my ($graph)

=head1 SYNOPSIS

 use Graph::Easy::Parser::Graph6;
 my $parser = Graph::Easy::Parser::Graph6->new;
 $graph = $parser->from_file('foo.g6');
 $graph = $parser->from_text(':Fa@x^');

=head1 CLASS HIERARCHY

C<Graph::Easy::Parser::Graph6> is a subclass of C<Graph::Easy::Parser>.

    Graph::Easy::Parser
      Graph::Easy::Parser::Graph6

=head1 DESCRIPTION

C<Graph::Easy::Parser::Graph6> reads a graph6 or sparse6 format file to
create a C<Graph::Easy> graph object.  These file formats are per

=over 4

L<http://cs.anu.edu.au/~bdm/data/formats.txt>

=back

Both formats represent an undirected graph with vertices numbered 0 to n-1.
They are made into C<Graph::Easy> vertex names as strings like "000" to
"999" with however many decimal digits are needed for the number of
vertices.  These names are designed to be round-trip clean to an
alphabetical re-write.

Sparse6 can have multi-edges and self loops.  They are added to the graph
with multiple C<add_edge()> in the usual way.

See L<Graph::Graph6> for further notes on the formats.  See
F<examples/graph-easy-print.pl> in the Graph-Graph6 sources for a complete
sample program.

=head1 FUNCTIONS

=over

=item C<$parser = Graph::Easy::Parser::Graph6-E<gt>new (key=E<gt>value, ...)>

Create and return a new parser object.  The key/value options are per
C<Graph::Easy::Parser>.

=item C<$graph = Graph::Easy::Parser::Graph6-E<gt>from_file ($filename)>

=item C<$graph = $parser-E<gt>from_file ($filename)>

=item C<$graph = $parser-E<gt>from_text ($str)>

Read the given filename or string and return a new C<Graph::Easy> graph.

For compatibility with C<Graph::Easy::Parser>, if C<$filename> is a
reference then it's assumed to be a file handle, though this is not a
documented in C<Graph::Easy::Parser> as of its version 0.75.  The suggestion
is to pass only a plain string for a filename.

=cut

# The return is a C<Graph::Easy> object if successful, or C<undef> at end of
# file.
# 
# The default C<fatal_errors> option is to croak on invalid contents or read
# error.  If C<fatal_errors> is false then return C<undef> for error and
# C<$parser-E<gt>error()> is an error message string.  The
# C<Graph::Easy::Parser> docs say return C<undef>, but its code actually
# returns an empty graph.  For now follow its docs but if
# C<Graph::Easy::Parser> goes the other way then expect the code here to
# change too.

=pod

=back

=head1 SEE ALSO

L<Graph::Easy>,
L<Graph::Easy::Parser>,
L<Graph::Easy::As_graph6>,
L<Graph::Easy::As_sparse6>

L<nauty-showg(1)>,
L<Graph::Graph6>

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
