package KinoSearch1::Search::SearchClient;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Searcher );

use Storable qw( nfreeze thaw );

BEGIN {
    __PACKAGE__->init_instance_vars(
        # params/members
        analyzer     => undef,
        peer_address => undef,
        password     => undef,
        # members
        similarity => undef,
    );
}

use IO::Socket::INET;

sub init_instance {
    my $self = shift;

    $self->{similarity} ||= KinoSearch1::Search::Similarity->new;
    $self->{field_sims} = {};

    # establish a connection
    my $sock = IO::Socket::INET->new(
        PeerAddr => $self->{peer_address},
        Proto    => 'tcp',
    );
    confess("No socket: $!") unless $sock;
    $sock->autoflush(1);
    $self->{sock} = $sock;

    # verify password
    print $sock "$self->{password}\n";
    chomp( my $response = <$sock> );
    confess("Failed to connect: '$response'") unless $response =~ /accept/i;
}

=for comment

Make a remote procedure call.  For every call that does not close/terminate
the socket connection, expect a response back that's been serialized using
Storable.

=cut

sub _rpc {
    my ( $self, $method, $args ) = @_;
    my $sock = $self->{sock};

    my $serialized = nfreeze($args);
    my $packed_len = pack( 'N', bytes::length($serialized) );
    print $sock "$method\n$packed_len$serialized";

    # bail out if we're either closing or shutting down the server remotely
    return if $method eq 'done';
    return if $method eq 'terminate';

    # decode response
    $sock->read( $packed_len, 4 );
    my $arg_len = unpack( 'N', $packed_len );
    my $check_val = read( $sock, $serialized, $arg_len );
    confess("Tried to read $arg_len bytes, got $check_val")
        unless ( defined $arg_len and $check_val == $arg_len );
    return thaw($serialized);
}

sub get_field_names {
    my $self = shift;
    return $self->_rpc( 'get_field_names', {} );
}

my %search_hit_collector_args = (
    hit_collector => undef,
    weight        => undef,
    filter        => undef,
    sort_spec     => undef,
);

sub search_hit_collector {
    my $self = shift;
    confess kerror() unless verify_args( \%search_hit_collector_args, @_ );
    my %args = ( %search_hit_collector_args, @_ );
    confess("remote filtered search not supported") if defined $args{filter};

    # replace the HitCollector with a size rather than serialize it
    my $collector = delete $args{hit_collector};
    if ( a_isa_b( $collector, "KinoSearch1::Search::OffsetCollector" ) ) {
        $args{num_wanted} = $collector->get_storage->get_max_size;
    }
    else {
        $args{num_wanted} = $collector->get_max_size;
    }

    # Make the remote call, which returns a hashref of doc => score pairs.
    # Accumulate hits into the HitCollector if the query is valid.
    my $score_pairs = $self->_rpc( 'search_hit_collector', \%args );
    while ( my ( $doc, $score ) = each %$score_pairs ) {
        $collector->collect( $doc, $score );
    }
}

sub terminate {
    my $self = shift;
    return $self->_rpc( 'terminate', {} );
}

sub fetch_doc {
    my ( $self, $doc_num ) = @_;
    return $self->_rpc( 'fetch_doc', { doc_num => $doc_num } );
}

sub max_doc {
    my $self = shift;
    return $self->_rpc( 'max_doc', {} );
}

sub doc_freq {
    my ( $self, $term ) = @_;
    return $self->_rpc( 'doc_freq', { term => $term } );
}

sub doc_freqs {
    my ( $self, $terms ) = @_;
    return $self->_rpc( 'doc_freqs', { terms => $terms } );
}

sub close {
    my $self = shift;
    $self->_rpc( 'done', {} );
    my $sock = $self->{sock};
    close $sock or confess("Error when closing socket: $!");
    undef $self->{sock};
}

sub DESTROY {
    my $self = shift;
    $self->close if defined $self->{sock};
}

1;

__END__

=head1 NAME

KinoSearch1::Search::SearchClient - connect to a remote SearchServer

=head1 SYNOPSIS

    my $client = KinoSearch1::Search::SearchClient->new(
        peer_address => 'searchserver1:7890',
        password     => $pass,
        analyzer     => $analyzer,
    );
    my $hits = $client->search( query => $query );

=head1 DESCRIPTION

SearchClient is a subclass of L<KinoSearch1::Searcher> which can be used to
search an index on a remote machine made accessible via
L<SearchServer|KinoSearch1::Search::SearchServer>.

=head1 METHODS

=head2 new

Constructor.  Takes hash-style params.

=over

=item *

B<peer_address> - The name/IP and the port number which the client should
attempt to connect to.

=item *

B<password> - Password to be supplied to the SearchServer when initializing
socket connection.

=item *

B<analyzer> - An object belonging to a subclass of
L<KinoSearch1::Analysis::Analyzer> 

=back

=head1 LIMITATIONS

Limiting search results with a QueryFilter is not yet supported.

=head1 COPYRIGHT

Copyright 2006-2010 Marvin Humphrey

=head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

=cut

