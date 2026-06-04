package FalkorDB::Node;

use strict;
use warnings;

sub new {
    my ( $class, %args ) = @_;
    return bless \%args, $class;
}

sub id         { shift->{id} }
sub labels     { shift->{labels} }
sub properties { shift->{properties} }

sub property {
    my ( $self, $key ) = @_;
    return $self->{properties}->{$key};
}

sub new_from_resp {
    my ( $class, $resp ) = @_;
    my ( $id, $labels, $properties );

    for my $pair (@$resp) {
        my ( $k, $v ) = @$pair;
        if ( $k eq 'id' ) {
            $id = $v;
        }
        elsif ( $k eq 'labels' ) {
            $labels = $v;
        }
        elsif ( $k eq 'properties' ) {
            $properties = FalkorDB::QueryResult::_parse_properties($v);
        }
    }

    return $class->new(
        id         => $id,
        labels     => $labels     || [],
        properties => $properties || {},
    );
}

1;
__END__

=head1 NAME

FalkorDB::Node - Representation of a graph node in FalkorDB

=head1 DESCRIPTION

Represents a node retrieved from the graph database.

=head1 METHODS

=head2 id()

Returns the internal ID of the node.

=head2 labels()

Returns an array reference of labels associated with the node.

=head2 properties()

Returns a hash reference of all properties on the node.

=head2 property($name)

Returns the value of a specific property by name.

=cut
