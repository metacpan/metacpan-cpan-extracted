package FalkorDB;

use strict;
use warnings;
use Redis::Fast;
use Carp qw(croak);
use FalkorDB::Graph;

our $VERSION = '0.01';

sub new {
    my ( $class, %args ) = @_;

    my $redis;
    if ( $args{redis} ) {
        $redis = $args{redis};
    }
    else {
        my $host   = $args{host} // 'falkordb';
        my $port   = $args{port} // 6379;
        my $server = "$host:$port";

        my %redis_args = ( server => $server, );

        # Only add password if it is defined and not empty
        if ( defined $args{password} && $args{password} ne '' ) {
            $redis_args{password} = $args{password};
        }

        $redis = Redis::Fast->new(%redis_args);

        # If username is provided, we can attempt AUTH (RESP3 uses AUTH username password)
        # But for empty username/password as requested, we don't need to authenticate.
        if (   defined $args{username}
            && $args{username} ne ''
            && defined $args{password}
            && $args{password} ne '' )
        {
            $redis->auth( $args{username}, $args{password} );
        }
    }

    my $self = { redis => $redis, };

    return bless $self, $class;
}

sub redis {
    my ($self) = @_;
    return $self->{redis};
}

sub select_graph {
    my ( $self, $name ) = @_;
    return FalkorDB::Graph->new( $self, $name );
}

sub graph {
    my ( $self, $name ) = @_;
    return $self->select_graph($name);
}

sub delete_graph {
    my ( $self, $name )  = @_;
    my ( $res,  $error ) = $self->{redis}->__std_cmd( "GRAPH.DELETE", $name );
    if ( defined $error ) {
        croak("[GRAPH.DELETE] $error");
    }
    return defined $res && $res eq 'OK';
}

sub list_graphs {
    my ($self) = @_;
    my ( $res, $error ) = $self->{redis}->__std_cmd("GRAPH.LIST");
    if ( defined $error ) {
        croak("[GRAPH.LIST] $error");
    }
    return ref $res eq 'ARRAY' ? $res : [];
}

1;
__END__

=head1 NAME

FalkorDB - Perl client module for FalkorDB

=head1 WARNING

This code was mostly generated using AI tools and has not been checked manually yet.
Check the source code before starting to use it!

=head1 SYNOPSIS

    use FalkorDB;

    my $db = FalkorDB->new(
        host => 'falkordb',
        port => 6379,
    );

    # Select a graph
    my $graph = $db->select_graph('SocialNetwork');

    # Execute a write query
    $graph->query("CREATE (:person {name: 'Alice', age: 30})");

    # Execute a parameterized read query
    my $res = $graph->query(
        "MATCH (p:person) WHERE p.age = \$age RETURN p.name, p.age",
        { age => 30 }
    );

    # Iterate over results
    while (my $row = $res->next_row()) {
        my ($name, $age) = @$row;
        print "Found person: $name ($age)\n";
    }

=head1 DESCRIPTION

FalkorDB is a Perl client for FalkorDB, a low-latency graph database built on Redis.
It maps Cypher queries to FalkorDB command invocations and parses the RESP output
into structured Perl objects (Nodes, Edges, Paths).

=head1 METHODS

=head2 new(%args)

Creates a new FalkorDB connection.
Supported arguments:

=over 4

=item * C<host> - Hostname of the FalkorDB server (default: 'falkordb')

=item * C<port> - Port number of the FalkorDB server (default: 6379)

=item * C<username> - Username for authentication (optional)

=item * C<password> - Password for authentication (optional)

=item * C<redis> - An existing L<Redis::Fast> object to reuse

=back

=head2 redis()

Returns the underlying L<Redis::Fast> client instance.

=head2 select_graph($name) or graph($name)

Selects a graph by name and returns a L<FalkorDB::Graph> instance.

=head2 delete_graph($name)

Deletes a graph by name. Returns true on success.

=head2 list_graphs()

Returns an array reference of the names of all graphs.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Gabor Szabo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
