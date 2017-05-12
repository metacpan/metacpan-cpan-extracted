package Graph::SomeUtils;

use 5.012000;
use strict;
use warnings;
use base qw(Exporter);
use Graph;

our $VERSION = '0.02';

our %EXPORT_TAGS = ( 'all' => [ qw(
	graph_delete_vertices_fast
  graph_delete_vertex_fast
  graph_all_successors_and_self
  graph_all_predecessors_and_self
  graph_vertices_between
  graph_get_vertex_label
  graph_set_vertex_label
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

sub graph_get_vertex_label {
  my ($g, $v) = @_;
  return $g->get_vertex_attribute($v, 'label');
}

sub graph_set_vertex_label {
  my ($g, $v, $label) = @_;
  $g->set_vertex_attribute($v, 'label', $label);
}

sub graph_delete_vertex_fast {
  my $g = shift;
  $g->expect_non_unionfind;
  my $V = $g->[ Graph::_V ];
  return $g unless $V->has_path( @_ );
  $g->delete_edge($_[0], $_) for $g->successors($_[0]);
  $g->delete_edge($_, $_[0]) for $g->predecessors($_[0]);
  $V->del_path( @_ );
  $g->[ Graph::_G ]++;
  return $g;
}

sub graph_delete_vertices_fast {
  my $g = shift;
  graph_delete_vertex_fast($g, $_) for @_;
}

sub graph_vertices_between {
  my ($g, $src, $dst) = @_;
  my %from_src;
  
  $from_src{$_}++ for graph_all_successors_and_self($g, $src);
  
  return grep {
    $from_src{$_}
  } graph_all_predecessors_and_self($g, $dst);
}

sub graph_all_successors_and_self {
  my ($g, $v) = @_;
  return ((grep { $_ ne $v } $g->all_successors($v)), $v);
}

sub graph_all_predecessors_and_self {
  my ($g, $v) = @_;
  return ((grep { $_ ne $v } $g->all_predecessors($v)), $v);
}

1;

__END__

=head1 NAME

Graph::SomeUtils - Some utility functions for Graph objects

=head1 SYNOPSIS

  use Graph::SomeUtils ':all';

  graph_delete_vertex_fast($g, 'a');
  graph_delete_vertices_fast($g, 'a', 'b', 'c');

  my @pred = graph_all_predecessors_and_self($g, $v);
  my @succ = graph_all_successors_and_self($g, $v);

  my @between = graph_vertices_between($g, $source, $dest);
  
=head1 DESCRIPTION

Some helper functions for working with L<Graph> objects.

=head1 FUNCTIONS

=over

=item graph_delete_vertex_fast($g, $v)

The C<delete_vertex> method of the L<Graph> module C<v0.96> is very
slow. This function is an order-of-magnitude faster alternative. It
accesses internals of the Graph module and might break under newer
versions of the module.

=item graph_delete_vertices_fast($g, $v1, $v2, ...)

Same as C<graph_delete_vertex_fast> for multiple vertices.

=item graph_vertices_between($g, $source, $destination)

Returns the intersection of vertices that are reachable from C<$source>
and vertices from which C<$destination> is reachable, including the
C<$source> and C<$destination> vertices themself.

=item graph_all_successors_and_self($g, $v)

Returns the union of C<$g->all_successors($v)> and C<$v> in an arbitrary
order.

=item graph_all_predecessors_and_self($g, $v)

Returns the union of C<$g->all_predecessors($v)> and C<$v> in an arbitrary
order.

=item graph_get_vertex_label($g, $v)

Shorthand for getting the vertex attribute C<label>.

=item graph_set_vertex_label($g, $v, $label)

Shorthand for setting the vertex attribute C<label>.

=back

=head1 EXPORTS

None by default, each of the functions by request. Use C<:all> to
import them all at once.

=head1 AUTHOR / COPYRIGHT / LICENSE

  Copyright (c) 2014 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as Perl itself.

=cut
