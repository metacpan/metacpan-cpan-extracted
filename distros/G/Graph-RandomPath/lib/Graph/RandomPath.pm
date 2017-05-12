package Graph::RandomPath;

use 5.012000;
use strict;
use warnings;
use base qw(Exporter);
use Graph;
use Carp;

our $VERSION = '0.01';

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

sub create_generator {
  my ($class, $g, $src, $dst, %opt) = @_;

  $opt{max_length} //= 64;
  
  my %to_src = map { $_ => 1 } $src, $g->all_successors($src);
  my %to_dst = map { $_ => 1 } $dst, $g->all_predecessors($dst);
  
  my $copy = $g->new;
  $copy->set_edge_weight($_->[1], $_->[0], 1) for grep {
    $to_src{$_->[0]} and $to_src{$_->[1]} and
    $to_dst{$_->[0]} and $to_dst{$_->[1]}
  } $g->edges;
  
  my $sptg;
  
  eval {
    $sptg = $copy->SPT_Dijkstra($dst);
  };
  
  if ($@) {
    # This is here in case the module is updated to allow user-
    # supplied weights for the edges, which might then be nega-
    # tive and require a different shortest path algorithm.
    $sptg = $copy->SPT_Bellman_Ford($dst);
  }
  
  Carp::confess "Unable to generate paths for these parameters" unless
    (defined $sptg->get_vertex_attribute($src, 'weight') and
    $sptg->get_vertex_attribute($src, 'weight') < $opt{max_length});

  return sub {
    my @path = ($src);
    my $target = rand($opt{max_length});
    while (1) {
      my $v = $copy->random_predecessor($path[-1]);

      last if $path[-1] eq $dst and
        (not defined $v or @path > $target);
        
      my $w = $sptg->get_vertex_attribute($v, 'weight') // 0;
      
      if (@path + $w > $opt{max_length}) {
        my $v = $sptg->get_vertex_attribute($v, 'p');
      };
      
      push @path, $v;
    }
    @path;
  }
}

1;

__END__

=head1 NAME

Graph::RandomPath - Find a random path between two graph vertices

=head1 SYNOPSIS

  use Graph::RandomPath;
  my $generator = Graph::RandomPath->create_generator($g, $from, $to);
  say "Vertices on random path 1: ", join ' ', $generator->();
  say "Vertices on random path 2: ", join ' ', $generator->();

=head1 DESCRIPTION

Generates random paths between two vertices in a L<Graph>.

=head1 CLASS METHODS

=over

=item create_generator($graph, $start_vertex, $final_vertex, %opt)

Returns a reference to a sub routine that returns a list of vertices
that describe a path from (inclusive) C<$start_vertex> to C<$final_vertex>
(inclusive) in the L<Graph>-compatible object C<$graph>. The function
stores a snapshot of the graph, modifications to the orignal graph are
ignored. An exception is raised if no paths can be generated, e.g. when
there is no path from C<$start_vertex> to C<$final_vertex> at all. The
number of vertices in the path determines the length, edge weights are
currently ignored.

The options hash C<%opt> can set the following values:

=over

=item max_length => 64

The maximum length for generated paths. The default is C<64>.

=back

=back

=head1 EXPORTS

None.

=head1 CAVEATS

The C<create_generator> function internally calls C<SPT_Dijkstra> on
a reduced graph containing only reachable vertices. Depending on how
the supplied Graph object implements this method it might not work on
large graphs due to the algorithmic complexity of the function.

=head1 AUTHOR / COPYRIGHT / LICENSE

  Copyright (c) 2014 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as Perl itself.

=cut
