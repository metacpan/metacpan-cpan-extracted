package Graph::Nauty;

use strict;
use warnings;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    are_isomorphic
    automorphism_group_size
    canonical_order
    orbits
    orbits_are_same
);

our $VERSION = '0.5.3'; # VERSION

our $worksize = 0;
our $warn_deprecated = 1;

require XSLoader;
XSLoader::load('Graph::Nauty', $VERSION);

use Graph::Nauty::EdgeVertex;
use Graph::Undirected;
use Scalar::Util qw(blessed);

sub _cmp
{
    my( $a, $b, $sub ) = @_;

    if( blessed $a && $a->isa( Graph::Nauty::EdgeVertex:: ) &&
        blessed $b && $b->isa( Graph::Nauty::EdgeVertex:: ) ) {
        return $a->color cmp $b->color;
    } elsif( blessed $a && $a->isa( Graph::Nauty::EdgeVertex:: ) ) {
        return 1;
    } elsif( blessed $b && $b->isa( Graph::Nauty::EdgeVertex:: ) ) {
        return -1;
    } else {
        return $sub->( $a ) cmp $sub->( $b );
    }
}

sub _nauty_graph
{
    my( $graph, $color_sub, $order_sub ) = @_;

    $color_sub = sub { "$_[0]" } unless $color_sub;
    $order_sub = sub { "$_[0]" } unless $order_sub;

    die "cannot handle graphs with self-loops\n" if $graph->self_loop_vertices;

    if( grep { $graph->has_edge_attributes( @$_ ) } $graph->edges ) {
        # colored bonds detected, need to transform the graph
        my $graph_now = Graph::Undirected->new( vertices => [ $graph->vertices ] );
        for my $edge ( $graph->edges ) {
            if( $graph->has_edge_attributes( @$edge ) ) {
                my $edge_vertex = Graph::Nauty::EdgeVertex->new( $graph->get_edge_attributes( @$edge ) );
                $graph_now->add_edge( $edge->[0], $edge_vertex );
                $graph_now->add_edge( $edge_vertex, $edge->[1] );
            } else {
                $graph_now->add_edge( @$edge );
            }
        }
        $graph = $graph_now;
    }

    my $nauty_graph = {
        nv  => scalar $graph->vertices,
        nde => scalar $graph->edges * 2, # as undirected
        e   => [],
        d   => [],
        v   => [],
    };

    my $n = 0;
    my $vertices = { map { $_ => { index => $n++, vertex => $_ } }
                     sort { _cmp( $a, $b, $color_sub ) ||
                            _cmp( $a, $b, $order_sub ) }
                         $graph->vertices };

    my @breaks;
    my $prev;
    for my $v (map  { $vertices->{$_}{vertex} }
               sort { $vertices->{$a}{index} <=>
                      $vertices->{$b}{index} } keys %$vertices) {
        # scalar $graph->neighbours( $v ) cannot be used to get the
        # number of neighbours since Graph v0.9717, see
        # https://github.com/graphviz-perl/Graph/issues/22
        my @neighbours = $graph->neighbours( $v );
        push @{$nauty_graph->{d}}, scalar @neighbours;
        push @{$nauty_graph->{v}}, scalar @{$nauty_graph->{e}};
        push @{$nauty_graph->{original}}, $v;
        for (sort { $vertices->{$a}{index} <=> $vertices->{$b}{index} }
                  @neighbours) {
            push @{$nauty_graph->{e}}, $vertices->{$_}{index};
        }
        if( defined $prev ) {
            push @breaks, int(_cmp( $prev, $v, $color_sub ) == 0);
        }
        $prev = $v;
    }
    push @breaks, 0;

    return ( $nauty_graph, [ 0..$n-1 ], \@breaks );
}

# Converts Graph to dreadnaut input
sub _to_dreadnaut
{
    my( $graph, $color_sub, $order_sub ) = @_;

    my( $nauty_graph, undef, $breaks ) = _nauty_graph( @_ );

    my $out = 'n=' .  $nauty_graph->{nv} . " g\n";

    my $offset = 0;
    my @neighbour_list;
    for my $v (0..$nauty_graph->{nv}-1) {
        my $neighbour_count = $nauty_graph->{d}[$v];
        push @neighbour_list,
             join( ' ', @{$nauty_graph->{e}}[$offset..$offset+$neighbour_count-1] );
        $offset += $neighbour_count;
    }
    $out .= join( ";\n", @neighbour_list ) . ".\n";

    my $partition = '';
    $partition .= 0 if $nauty_graph->{nv};
    for (0..$#$breaks-1) {
        $partition .= $breaks->[$_] ? ',' : '|';
        $partition .= $_ + 1;
    }
    $out .= "f=[$partition]\n";

    return $out;
}

sub automorphism_group_size
{
    my( $graph, $color_sub ) = @_;

    my $statsblk = sparsenauty( _nauty_graph( $graph, $color_sub ),
                                undef,
                                $worksize );
    return $statsblk->{grpsize1} * 10 ** $statsblk->{grpsize2};
}

sub orbits
{
    my( $graph, $color_sub, $order_sub ) = @_;

    my( $nauty_graph, $labels, $breaks ) =
        _nauty_graph( $graph, $color_sub, $order_sub );
    my $statsblk = sparsenauty( $nauty_graph,
                                $labels,
                                $breaks,
                                undef,
                                $worksize );

    my %orbits;
    for my $i (0..$nauty_graph->{nv}-1) {
        my $vertex = $nauty_graph->{original}[$i];
        next if blessed $vertex && $vertex->isa( Graph::Nauty::EdgeVertex:: );

        my $orbit = $statsblk->{orbits}[$i];
        push @{$orbits{$orbit}}, $vertex;
    }

    return map { $orbits{$_} } sort keys %orbits;
}

sub are_isomorphic
{
    my( $graph1, $graph2, $color_sub ) = @_;

    $color_sub = sub { "$_[0]" } unless $color_sub;

    return 0 if !$graph1->could_be_isomorphic( $graph2 );

    my @nauty_graph1 = _nauty_graph( $graph1, $color_sub );
    my @nauty_graph2 = _nauty_graph( $graph2, $color_sub );

    return 0 if $nauty_graph1[0]->{nv} != $nauty_graph2[0]->{nv};

    # aresame_sg() seemingly segfaults with empty graphs, thus this is
    # a getaround to avoid it:
    return 1 if $nauty_graph1[0]->{nv} == 0;

    my $statsblk1 = sparsenauty( @nauty_graph1, { getcanon => 1 }, $worksize );
    my $statsblk2 = sparsenauty( @nauty_graph2, { getcanon => 1 }, $worksize );

    for my $i (0..$nauty_graph1[0]->{nv}-1) {
        my $j = $statsblk1->{lab}[$i];
        my $k = $statsblk2->{lab}[$i];
        return 0 if _cmp( $nauty_graph1[0]->{original}[$j],
                          $nauty_graph2[0]->{original}[$k],
                          $color_sub ) != 0;
    }

    return aresame_sg( $statsblk1->{canon}, $statsblk2->{canon} );
}

sub canonical_order
{
    my( $graph, $color_sub, $order_sub ) = @_;

    my( $nauty_graph, $labels, $breaks ) =
        _nauty_graph( $graph, $color_sub, $order_sub );
    my $statsblk = sparsenauty( $nauty_graph,
                                $labels,
                                $breaks,
                                { getcanon => 1 },
                                $worksize );

    return grep { !blessed $_ || !$_->isa( Graph::Nauty::EdgeVertex:: ) }
                map { $nauty_graph->{original}[$_] }
                    @{$statsblk->{lab}};
}

# DEPRECATED: order of orbits may be different even in isomorphic graphs
sub orbits_are_same
{
    my( $graph1, $graph2, $color_sub ) = @_;

    $color_sub = sub { "$_[0]" } unless $color_sub;

    return 0 if !$graph1->could_be_isomorphic( $graph2 );

    warn 'orbits_are_same() is deprecated, as order of orbits may be different ' .
         'even in isomorphic graphs' . "\n" if $warn_deprecated;

    my @orbits1 = orbits( $graph1, $color_sub );
    my @orbits2 = orbits( $graph2, $color_sub );

    return 0 if scalar @orbits1 != scalar @orbits2;

    for my $i (0..$#orbits1) {
        return 0 if scalar @{$orbits1[$i]} != scalar @{$orbits2[$i]};
        return 0 if $color_sub->( $orbits1[$i]->[0] ) ne
                    $color_sub->( $orbits2[$i]->[0] );
    }

    return 1;
}

1;
__END__

=head1 NAME

Graph::Nauty - Perl bindings for Nauty

=head1 SYNOPSIS

  use Graph::Nauty qw(
      are_isomorphic
      automorphism_group_size
      canonical_order
      orbits
  );
  use Graph::Undirected;

  my $A = Graph::Undirected->new;
  my $B = Graph::Undirected->new;

  # Create graphs here

  # Get the size of the automorphism group:
  print automorphism_group_size( $A );

  # Get automorphism group orbits:
  print orbits( $A );

  # Check whether two graphs are isomorphs:
  print are_isomorphic( $A, $B );

  # Get canonical order of vertices:
  print canonical_order( $A );

=head1 DESCRIPTION

Graph::Nauty provides an interface to Nauty, a set of procedures for
determining the automorphism group of a vertex-coloured graph, and for
testing graphs for isomorphism.

Currently Graph::Nauty only supports
L<Graph::Undirected|Graph::Undirected>, that is, it does not handle
directed graphs. Both colored vertices and edges are accounted for when
determining equivalence classes.

=head2 Vertex color

As L<Graph|Graph> supports any data types as graph vertices, not much
can be inferred about them automatically. For now, Graph::Nauty by
default stringifies every vertex (using Perl C<""> operator) and splits
them into equivalence classes. If different behavior is needed, a custom
anonymous subroutine can be passed inside an option hash:

  print orbits( $A, sub { return length $_[0] } );

Subroutine gets a vertex as its 0th parameter, and is expected to return
a string, or anything stringifiable.

In subroutines where the order of returned vertices is important, a
second anonymous subroutine can be passed to order vertices inside each
of the equivalence classes:

  print orbits( $A, sub { return length $_[0] }, sub { return "$_[0]" } );

If an ordering subroutine is not given, stringification (Perl C<"">
operator) is used by default.

=head2 Edge color

Edge colors are generated from L<Graph|Graph> edge attributes. Complete
hash of each edge's attributes is stringified (deterministically) and
used to divide edges into equivalence classes.

=head2 Working storage size

Nauty needs working storage, which it does not allocate by itself.
Graph::Nauty follows the advice of the Nauty user guide by allocating
the recommended amount of memory, but for certain graphs this might not
be enough, still. To control that, C<$Graph::Nauty::worksize> could be
used to set the size of memory in the units of Nauty's C<setword>.

=head1 INSTALLING

Building and installing Graph::Nauty from source requires shared library
and C headers for Nauty, which can be downloaded from
L<https://users.cecs.anu.edu.au/~bdm/nauty/>. Both the library and C
headers have to be installed to locations visible by Perl's C compiler.

=head1 SEE ALSO

For the description of Nauty refer to L<http://pallini.di.uniroma1.it>.

=head1 AUTHOR

Andrius Merkys, L<mailto:merkys@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Andrius Merkys

Graph::Nauty is distributed under the BSD-3-Clause license.

=cut
