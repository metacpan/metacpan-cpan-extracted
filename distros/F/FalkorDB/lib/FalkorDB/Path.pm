package FalkorDB::Path;

use strict;
use warnings;

sub new {
    my ( $class, %args ) = @_;
    return bless \%args, $class;
}

sub nodes    { shift->{nodes} }
sub edges    { shift->{edges} }
sub elements { shift->{elements} }

sub new_from_string {
    my ( $class, $path_str ) = @_;
    my @nodes;
    my @edges;
    my @elements;

    if ( $path_str =~ /^\[(.*)\]$/ ) {
        my $content = $1;
        while ( $content =~ /(\(\d+\)|\[\d+\])/g ) {
            my $token = $1;
            if ( $token =~ /^\((\d+)\)$/ ) {
                my $node_id = 0 + $1;
                push @nodes, $node_id;
                push @elements, { type => 'node', id => $node_id };
            }
            elsif ( $token =~ /^\[(\d+)\]$/ ) {
                my $edge_id = 0 + $1;
                push @edges, $edge_id;
                push @elements, { type => 'edge', id => $edge_id };
            }
        }
    }

    return $class->new(
        nodes    => \@nodes,
        edges    => \@edges,
        elements => \@elements,
    );
}

1;
__END__

=head1 NAME

FalkorDB::Path - Representation of a graph traversal path in FalkorDB

=head1 DESCRIPTION

Represents a path retrieved from the graph database, which is an alternating sequence of nodes and edges.

=head1 METHODS

=head2 nodes()

Returns an array reference of node IDs constituting the path in traversal order.

=head2 edges()

Returns an array reference of edge IDs constituting the path in traversal order.

=head2 elements()

Returns an array reference of alternating element hashes:
C<[ { type => 'node', id => X }, { type => 'edge', id => Y }, ... ]>

=cut
