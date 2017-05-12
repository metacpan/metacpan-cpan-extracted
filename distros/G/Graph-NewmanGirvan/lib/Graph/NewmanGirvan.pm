package Graph::NewmanGirvan;

use 5.010000;
use strict;
use warnings;
use List::Util 'sum';

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
  newman_girvan
  newman_girvan_r
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.3';

require XSLoader;
XSLoader::load('Graph::NewmanGirvan', $VERSION);

sub newman_girvan {
  my $g = shift;
  my $p = Graph::NewmanGirvan->new;
  my %default_weight;

  for ($g->edges) {
    my ($src, $dst) = @$_;
    my $weight = $g->get_edge_weight($src, $dst) // 1.0;
    $p->add_edge($src, $dst, $weight);
    $default_weight{$src} += $weight;
    $default_weight{$dst} += $weight;
  }
  foreach my $vertex ($g->vertices) {
    my $weight = $g->get_vertex_weight($vertex) // $default_weight{$vertex};
    $p->set_vertex_weight($vertex, $weight);
  }
  return $p->compute;
}

sub newman_girvan_r {
  my ($g) = @_;
  my %clustering = newman_girvan($g);
  my %reverse;
  push @{ $reverse{ $clustering{$_} } }, $_ for keys %clustering;
  %reverse;
}


1;
__END__

=head1 NAME

Graph::NewmanGirvan - Newman-Girvan Graph node clustering

=head1 SYNOPSIS

  use Graph::NewmanGirvan 'newman_girvan';
  use Graph::Undirected;
  my $g = Graph::Undirected->new;
  $g->add_weighted_edge('a', 'b', 0.3);
  ...
  my %vertex_to_cluster = newman_girvan($g);

=head1 DESCRIPTION

The C<newman_girvan> sub takes a Graph object and computes clusters
for each vertex in the graph. The implementation is a quick and dirty
port of the code in Andreas Noack's linloglayout utility, tested only
with graphs with edges with edge weights greater than zero. Should work
with directed and undirected graphs. The function C<newman_girvan_r>
is a convenience wrapper for C<newman_girvan> that returns a hash with
the cluster identifiers as keys and array references of vertices as
values. The vertex weight of each vertex defaults to sum of the weights
of the edges leaving or entering the vertex.

=head2 EXPORTS

The functions C<newman_girvan> and C<newman_girvan_r> on request,
none by default.

=head1 SEE ALSO

L<http://code.google.com/p/linloglayout/>

=head1 AUTHOR / COPYRIGHT / LICENSE

  Copyright (c) 2011 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as linloglayout.
  Uses code from linloglayout Copyright (C) 2008 Andreas Noack.

=cut
