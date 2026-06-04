package FalkorDB::Graph;

use strict;
use warnings;
use Scalar::Util qw(looks_like_number);
use FalkorDB::QueryResult;

sub new {
    my ( $class, $db, $name ) = @_;
    my $self = {
        db   => $db,
        name => $name,
    };
    return bless $self, $class;
}

sub db {
    my ($self) = @_;
    return $self->{db};
}

sub name {
    my ($self) = @_;
    return $self->{name};
}

sub delete {
    my ($self) = @_;
    return $self->db->delete_graph( $self->name );
}

sub query {
    my ( $self, $cypher, $params ) = @_;
    my $query_str = $self->_build_query_string( $cypher, $params );
    my ( $raw_res, $error ) = $self->db->redis->__std_cmd( "GRAPH.QUERY", $self->name, $query_str );
    if ( defined $error ) {
        require Carp;
        Carp::croak("[GRAPH.QUERY] $error");
    }
    return FalkorDB::QueryResult->new_from_raw($raw_res);
}

sub ro_query {
    my ( $self, $cypher, $params ) = @_;
    my $query_str = $self->_build_query_string( $cypher, $params );
    my ( $raw_res, $error ) =
      $self->db->redis->__std_cmd( "GRAPH.RO_QUERY", $self->name, $query_str );
    if ( defined $error ) {
        require Carp;
        Carp::croak("[GRAPH.RO_QUERY] $error");
    }
    return FalkorDB::QueryResult->new_from_raw($raw_res);
}

sub explain {
    my ( $self, $cypher, $params ) = @_;
    my $query_str = $self->_build_query_string( $cypher, $params );
    my ( $raw_res, $error ) =
      $self->db->redis->__std_cmd( "GRAPH.EXPLAIN", $self->name, $query_str );
    if ( defined $error ) {
        require Carp;
        Carp::croak("[GRAPH.EXPLAIN] $error");
    }
    return $raw_res;
}

sub profile {
    my ( $self, $cypher, $params ) = @_;
    my $query_str = $self->_build_query_string( $cypher, $params );
    my ( $raw_res, $error ) =
      $self->db->redis->__std_cmd( "GRAPH.PROFILE", $self->name, $query_str );
    if ( defined $error ) {
        require Carp;
        Carp::croak("[GRAPH.PROFILE] $error");
    }
    return $raw_res;
}

sub create_index {
    my ( $self, $label, $property ) = @_;
    return $self->query("CREATE INDEX FOR (n:$label) ON (n.$property)");
}

sub drop_index {
    my ( $self, $label, $property ) = @_;
    return $self->query("DROP INDEX FOR (n:$label) ON (n.$property)");
}

# --- Parameter Serialization ---

sub _build_query_string {
    my ( $self, $cypher, $params ) = @_;

    return $cypher unless $params && ref $params eq 'HASH';

    my @serialized;
    while ( my ( $k, $v ) = each %$params ) {
        push @serialized, "$k=" . _serialize_param($v);
    }

    if (@serialized) {
        return "CYPHER " . join( " ", @serialized ) . " " . $cypher;
    }

    return $cypher;
}

sub _serialize_param {
    my ($val) = @_;

    if ( !defined $val ) {
        return 'null';
    }

    if ( ref $val ) {
        my $ref_type = ref $val;

        # Handle boolean wrappers (e.g. JSON::PP::Boolean, Types::Serialiser::Boolean)
        if (   $ref_type eq 'JSON::PP::Boolean'
            || $ref_type eq 'Types::Serialiser::Boolean' )
        {
            return $$val ? 'true' : 'false';
        }
        elsif ( $ref_type eq 'ARRAY' ) {
            my @elems = map { _serialize_param($_) } @$val;
            return '[' . join( ', ', @elems ) . ']';
        }
        elsif ( $ref_type eq 'HASH' ) {
            my @pairs;
            while ( my ( $k, $v ) = each %$val ) {
                my $safe_key = $k;
                if ( $k =~ /[^a-zA-Z0-9_]/ ) {
                    $safe_key = "`$k`";
                }
                push @pairs, "$safe_key: " . _serialize_param($v);
            }
            return '{' . join( ', ', @pairs ) . '}';
        }
        else {
            # Stringify fallback for unrecognized references
            return '"' . _escape_string("$val") . '"';
        }
    }

    # Check for boolean keywords passed as strings
    if ( $val eq 'true' || $val eq 'false' ) {
        return $val;
    }

    # Check if value is numeric (so we avoid quoting it)
    if ( looks_like_number($val) && $val !~ /^0\d+/ ) {
        return $val;
    }

    # Default: quote as string
    return '"' . _escape_string($val) . '"';
}

sub _escape_string {
    my ($str) = @_;
    $str =~ s/\\/\\\\/g;
    $str =~ s/"/\\"/g;
    $str =~ s/\n/\\n/g;
    $str =~ s/\r/\\r/g;
    $str =~ s/\t/\\t/g;
    return $str;
}

1;
__END__

=head1 NAME

FalkorDB::Graph - Graph representation in FalkorDB

=head1 DESCRIPTION

This module represents a specific graph in FalkorDB. It is created via the L<FalkorDB> C<select_graph> method.

=head1 METHODS

=head2 query($cypher, $params)

Executes a write/read Cypher query against the graph. Returns a L<FalkorDB::QueryResult> object.
Optionally accepts a hash reference of parameters C<$params> to bind.

=head2 ro_query($cypher, $params)

Executes a read-only Cypher query against the graph. This can run on replica instances.
Returns a L<FalkorDB::QueryResult> object.

=head2 explain($cypher, $params)

Returns the execution plan for the query as an array reference of strings.

=head2 profile($cypher, $params)

Runs the query and returns the detailed execution plan with profiling stats as an array reference of strings.

=head2 delete()

Deletes the graph from the database.

=head2 create_index($label, $property)

Convenience method to create an index for a specific label and property.

=head2 drop_index($label, $property)

Convenience method to drop an index for a specific label and property.

=cut
