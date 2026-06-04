package FalkorDB::Edge;

use strict;
use warnings;

sub new {
    my ( $class, %args ) = @_;
    return bless \%args, $class;
}

sub id         { shift->{id} }
sub type       { shift->{type} }
sub src_node   { shift->{src_node} }
sub dest_node  { shift->{dest_node} }
sub properties { shift->{properties} }

sub property {
    my ( $self, $key ) = @_;
    return $self->{properties}->{$key};
}

sub new_from_resp {
    my ( $class, $resp ) = @_;
    my ( $id, $type, $src_node, $dest_node, $properties );

    for my $pair (@$resp) {
        my ( $k, $v ) = @$pair;
        if ( $k eq 'id' ) {
            $id = $v;
        }
        elsif ( $k eq 'type' ) {
            $type = $v;
        }
        elsif ( $k eq 'src_node' ) {
            $src_node = $v;
        }
        elsif ( $k eq 'dest_node' ) {
            $dest_node = $v;
        }
        elsif ( $k eq 'properties' ) {
            $properties = FalkorDB::QueryResult::_parse_properties($v);
        }
    }

    return $class->new(
        id         => $id,
        type       => $type,
        src_node   => $src_node,
        dest_node  => $dest_node,
        properties => $properties || {},
    );
}

1;
__END__

=head1 NAME

FalkorDB::Edge - Representation of a graph relationship/edge in FalkorDB

=head1 DESCRIPTION

Represents a relationship (edge) between two nodes retrieved from the graph database.

=head1 METHODS

=head2 id()

Returns the internal ID of the relationship.

=head2 type()

Returns the relationship type name (e.g. 'knows').

=head2 src_node()

Returns the internal ID of the source node of the relationship.

=head2 dest_node()

Returns the internal ID of the destination node of the relationship.

=head2 properties()

Returns a hash reference of all properties on the relationship.

=head2 property($name)

Returns the value of a specific property by name.

=cut
