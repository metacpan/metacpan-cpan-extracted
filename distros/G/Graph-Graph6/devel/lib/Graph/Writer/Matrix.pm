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

package Graph::Writer::Matrix;
use 5.004;
use strict;
use Carp 'croak';
use Graph::Writer;

use vars '@ISA','$VERSION';
@ISA = ('Graph::Writer');
$VERSION = 7;

# uncomment this to run the ### lines
# use Smart::Comments;

sub _init  {
  my ($self,%param) = @_;
  $self->SUPER::_init();
  %$self = (%param, %$self);
}

sub _write_graph {
  my ($self, $graph, $fh) = @_;

  my @vertices = sort $graph->vertices;

  my $format = $self->{'format'} || 'amtog';
  my $matrix_type = $self->{'matrix_type'} || 'adjacency';

  ### $matrix_type
  ### $format

  my $elem_func;
  if ($matrix_type eq 'adjacency') {
    # adjacency 0 or 1
    $elem_func = sub {
      my ($i, $j) = @_;
      return $graph->has_edge($vertices[$i], $vertices[$j]) ? 1 : 0;
    };
  } elsif ($matrix_type eq 'Laplacian') {
    # Laplacian Degree - adjacency 0 or 1
    $elem_func = sub {
      my ($i, $j) = @_;
      return ($i==$j ? $graph->vertex_degree($vertices[$i]) : 0)
        - ($graph->has_edge($vertices[$i], $vertices[$j]) ? 1 : 0);
    };
  } elsif ($matrix_type eq 'Seidel') {
    # 0 for from=to, -1 if edge from-to, +1 if no edge
    $elem_func = sub {
      my ($i, $j) = @_;
      return ($i==$j ? 0
              : $graph->has_edge($vertices[$i], $vertices[$j]) ? -1 : 1);
    };
  } else {
    croak "Unrecognised matrix_type: ",$matrix_type;
  }

  if ($format eq 'gp') {
    my $join = '[';
    foreach my $i (0 .. $#vertices) {
      foreach my $j (0 .. $#vertices) {
        print $fh $join, $elem_func->($i, $j);
        $join = ',';
      }
      $join = ';';
    }
    print $fh "]";

  } elsif ($format eq 'amtog') {
    my $nauty_type = ($self->{'nauty_type'}
                      || ($graph->is_undirected
                          && scalar($graph->self_loop_vertices) == 0
                          ? 't' : 'm'));
    my $triangle = ($nauty_type eq 't');

    print $fh
      "n=",scalar(@vertices),"\n",
      $triangle ? "t\n" : "m\n";

    foreach my $i (0 .. $#vertices - ($triangle ? 1 : 0)) {
      foreach my $j (($triangle ? $i+1 : 0) .. $#vertices) {
        print $fh $elem_func->($i, $j);
      }
      print $fh "\n";
    }
    print $fh "q\n";

  } else {
    croak "Unrecognised format: ",$format;
  }
}

1;
__END__

=for stopwords Ryde nauty undirected NxN

=head1 NAME

Graph::Writer::Matrix - write Graph as a matrix

=for test_synopsis my ($graph, $filehandle)

=head1 SYNOPSIS

 use Graph::Writer::Matrix;
 my $writer = Graph::Writer::Matrix->new;
 $writer->write_graph($graph, 'filename.txt');
 $writer->write_graph($graph, $filehandle);

=head1 DESCRIPTION

C<Graph::Writer::Matrix> writes a C<Graph.pm> graph to a file as a matrix.
The output is rows and columns of the matrix.  There are no vertex names or
attributes in the output.  In the current implementation
C<$graph-E<gt>vertices()> is sorted alphabetically (C<sort>) to give a
consistent (though slightly arbitrary) matrix.

=head2 Format C<gp>

C<format =E<gt> "gp"> is the matrix syntax of Pari/GP, including
surrounding brackets,

    [0,0,1;1,1,1;0,1,1]

There is no final newline, so the matrix can be printed somewhere in a
bigger expression.

=head2 Format C<amtog>

C<format =E<gt> "amtog"> is the matrix format read by the nauty tools
C<amtog> program.

=over 4

L<http://pallini.di.uniroma1.it>

=back

This a vertex count followed by adjacency matrix.  Matrix entry i,j is 0 or
1 according to whether there is an edge from i to j.  For an undirected
graph with no self-loops the "t" upper triangle form is written.

    n=5
    t
    1000
    110
    10
    1
    q

For a directed graph or if there are self-loops the "m" form is written.
(Though most of the nauty tools only operate on undirected graphs.)

    n=5
    m
    01000
    00100
    00010
    01000
    00010
    q

=head2 Matrix Type C<adjacency>

C<matrix_type =E<gt> "adjacency"> selects an adjacency matrix.  This is the
default.  Entry i,j is 1 or 0 according as there is or is not an edge from i
to j.  Diagonal entries i,i are likewise 1 or 0, according to whether there
is a self-loop i to i.

For an undirected graph this matrix is a symmetric M[i,j]=M[j,i].  For a
directed graph the entries are edge directions from i to j.

=head2 Matrix Type C<Laplacian>

C<matrix_type =E<gt> "Laplacian"> selects the Laplacian matrix.  This is a
diagonal where entry i,i is the degree of vertex i, then subtract the
adjacency matrix described above.  If there are self-loops then they
subtract from the diagonal entries.

The eigenvalues of the Laplacian have various properties.  For a tree of n
vertices the Wiener index = n * sum 1/eigenvalue[i], where the sum excludes
the zero eigenvalue.

=head2 Matrix Type C<Seidel>

C<matrix_type =E<gt> "Seidel"> selects the Seidel matrix.  Entry i,j is -1
if an edge i to j, +1 if no edge, and 0 on the diagonal i,i.

=head1 FUNCTIONS

=over

=item C<$writer = Graph::Writer::Graph6-E<gt>new (key =E<gt> value, ...)>

Create and return a new writer object.  The only key/value option is

    format       => string
    matrix_type  => string

C<format> can be

    "amtog" (the default)
    "gp"

C<matrix_type> can be

    "adjacency"      1=edge, 0=not  (the default)
    "Laplacian"      degree - adjacency 0,1
    "Seidel"         adjacency -1=edge, +1=not, 0 on diagonal

=item C<$writer-E<gt>write_graph($graph, $filename_or_fh)>

Write C<$graph> to C<$filename_or_fh> as a matrix of the selected C<format>
and C<matrix_type>.

=back

=head1 SEE ALSO

L<Graph>, L<Graph::Writer>, L<nauty-amtog(1)>

L<Graph::Writer::Graph6>, L<Graph::Writer::Sparse6>

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
