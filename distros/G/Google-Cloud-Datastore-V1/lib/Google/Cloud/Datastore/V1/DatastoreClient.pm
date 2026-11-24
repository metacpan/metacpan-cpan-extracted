package Google::Cloud::Datastore::V1::DatastoreClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Datastore::V1::Entity;
use Google::Datastore::V1::QueryProfile;
use Google::Datastore::V1::Query;
use Google::Datastore::V1::AggregationResult;
use Google::Datastore::V1::Datastore;

our $VERSION = '0.06';

has credentials => ( is => 'ro', required => 0 );
has transport   => ( is => 'rw' );

sub BUILD {
    my ($self) = @_;

    my $auth = $self->credentials;
    if (!defined $auth) {
        $auth = Google::Auth->default();
    } elsif (!eval { $auth->can('get_token') }) {
        croak 'Invalid credentials object: must implement get_token()';
    }
    my $token = $auth->get_token();

    my $target = 'datastore.googleapis.com:443';
    my $t = $self->transport || 'grpc';

    if (ref($t) && eval { $t->can('call') }) {
        # Already a transport object
    } elsif (lc($t) eq 'rest') {
        my $client = Google::Cloud::REST::Client->new(
            target     => $target,
            auth_token => $token,
        );
        $self->transport($client);
    } else {
        my $client = Google::gRPC::Client->new(
            target     => $target,
            auth_token => $token,
        );
        $self->transport($client);
    }
}

sub lookup {
    my ($self, %params) = @_;

    my $request_class = 'Google::Datastore::V1::Datastore::LookupRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Datastore::V1::Datastore::LookupResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.datastore.v1.Datastore/Lookup',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.datastore.v1.Datastore',
        method         => 'Lookup',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub run_query {
    my ($self, %params) = @_;

    my $request_class = 'Google::Datastore::V1::Datastore::RunQueryRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Datastore::V1::Datastore::RunQueryResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.datastore.v1.Datastore/RunQuery',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.datastore.v1.Datastore',
        method         => 'RunQuery',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub run_aggregation_query {
    my ($self, %params) = @_;

    my $request_class = 'Google::Datastore::V1::Datastore::RunAggregationQueryRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Datastore::V1::Datastore::RunAggregationQueryResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.datastore.v1.Datastore/RunAggregationQuery',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.datastore.v1.Datastore',
        method         => 'RunAggregationQuery',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub begin_transaction {
    my ($self, %params) = @_;

    my $request_class = 'Google::Datastore::V1::Datastore::BeginTransactionRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Datastore::V1::Datastore::BeginTransactionResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.datastore.v1.Datastore/BeginTransaction',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.datastore.v1.Datastore',
        method         => 'BeginTransaction',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub commit {
    my ($self, %params) = @_;

    my $request_class = 'Google::Datastore::V1::Datastore::CommitRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Datastore::V1::Datastore::CommitResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.datastore.v1.Datastore/Commit',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.datastore.v1.Datastore',
        method         => 'Commit',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub rollback {
    my ($self, %params) = @_;

    my $request_class = 'Google::Datastore::V1::Datastore::RollbackRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Datastore::V1::Datastore::RollbackResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.datastore.v1.Datastore/Rollback',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.datastore.v1.Datastore',
        method         => 'Rollback',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub allocate_ids {
    my ($self, %params) = @_;

    my $request_class = 'Google::Datastore::V1::Datastore::AllocateIdsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Datastore::V1::Datastore::AllocateIdsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.datastore.v1.Datastore/AllocateIds',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.datastore.v1.Datastore',
        method         => 'AllocateIds',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub reserve_ids {
    my ($self, %params) = @_;

    my $request_class = 'Google::Datastore::V1::Datastore::ReserveIdsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Datastore::V1::Datastore::ReserveIdsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.datastore.v1.Datastore/ReserveIds',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.datastore.v1.Datastore',
        method         => 'ReserveIds',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Datastore::V1::DatastoreClient

__END__

=head1 NAME

Google::Cloud::Datastore::V1::DatastoreClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Datastore::V1::DatastoreClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Datastore::V1::DatastoreClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Datastore::V1::DatastoreClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Datastore::V1::DatastoreClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/datastore/v1/aggregation_result.proto>

=item * C<googleapis/google/datastore/v1/datastore.proto>

=item * C<googleapis/google/datastore/v1/entity.proto>

=item * C<googleapis/google/datastore/v1/query.proto>

=item * C<googleapis/google/datastore/v1/query_profile.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Datastore::V1::DatastoreClient->new(
        credentials => $auth,   # Optional: Google::Auth object (defaults to ADC)
        transport   => 'grpc', # Optional: 'grpc' (default) or 'rest'
    );

=head1 ATTRIBUTES

=head2 credentials

Returns or accepts the L<Google::Auth> credentials object.

=head2 transport

Returns or accepts the active transport object (L<Google::gRPC::Client> or L<Google::Cloud::REST::Client>).

=head1 METHODS

=head2 METHODS

The following RPC methods are available in this client:

=over 4

=item * B<lookup>

    my $response = $client->lookup(
        project_id               => $project_id,
        database_id              => $database_id,
        read_options             => $read_options,
        keys                     => [ ... ],
        property_mask            => $property_mask,
        request_options          => $request_options,
    );

Calls the RPC method C<Lookup> on C<google.datastore.v1.Datastore>.

Request: L<Google::Datastore::V1::Datastore::LookupRequest>

Returns: L<Google::Datastore::V1::Datastore::LookupResponse>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<database_id> - C<string>

=item * C<read_options> - L<Google::Datastore::V1::Datastore::ReadOptions>

=item * C<keys> - ArrayRef of L<Google::Datastore::V1::Entity::Key>

=item * C<property_mask> - L<Google::Datastore::V1::Datastore::PropertyMask>

=item * C<request_options> - L<Google::Datastore::V1::Datastore::RequestOptions>

=back

=item * B<run_query>

    my $response = $client->run_query(
        project_id               => $project_id,
        database_id              => $database_id,
        partition_id             => $partition_id,
        read_options             => $read_options,
        property_mask            => $property_mask,
        explain_options          => $explain_options,
        request_options          => $request_options,
    );

Calls the RPC method C<RunQuery> on C<google.datastore.v1.Datastore>.

Request: L<Google::Datastore::V1::Datastore::RunQueryRequest>

Returns: L<Google::Datastore::V1::Datastore::RunQueryResponse>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<database_id> - C<string>

=item * C<partition_id> - L<Google::Datastore::V1::Entity::PartitionId>

=item * C<read_options> - L<Google::Datastore::V1::Datastore::ReadOptions>

=item * C<property_mask> - L<Google::Datastore::V1::Datastore::PropertyMask>

=item * C<explain_options> - L<Google::Datastore::V1::QueryProfile::ExplainOptions>

=item * C<request_options> - L<Google::Datastore::V1::Datastore::RequestOptions>

=back

=item * B<run_aggregation_query>

    my $response = $client->run_aggregation_query(
        project_id               => $project_id,
        database_id              => $database_id,
        partition_id             => $partition_id,
        read_options             => $read_options,
        explain_options          => $explain_options,
        request_options          => $request_options,
    );

Calls the RPC method C<RunAggregationQuery> on C<google.datastore.v1.Datastore>.

Request: L<Google::Datastore::V1::Datastore::RunAggregationQueryRequest>

Returns: L<Google::Datastore::V1::Datastore::RunAggregationQueryResponse>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<database_id> - C<string>

=item * C<partition_id> - L<Google::Datastore::V1::Entity::PartitionId>

=item * C<read_options> - L<Google::Datastore::V1::Datastore::ReadOptions>

=item * C<explain_options> - L<Google::Datastore::V1::QueryProfile::ExplainOptions>

=item * C<request_options> - L<Google::Datastore::V1::Datastore::RequestOptions>

=back

=item * B<begin_transaction>

    my $response = $client->begin_transaction(
        project_id               => $project_id,
        database_id              => $database_id,
        transaction_options      => $transaction_options,
        request_options          => $request_options,
    );

Calls the RPC method C<BeginTransaction> on C<google.datastore.v1.Datastore>.

Request: L<Google::Datastore::V1::Datastore::BeginTransactionRequest>

Returns: L<Google::Datastore::V1::Datastore::BeginTransactionResponse>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<database_id> - C<string>

=item * C<transaction_options> - L<Google::Datastore::V1::Datastore::TransactionOptions>

=item * C<request_options> - L<Google::Datastore::V1::Datastore::RequestOptions>

=back

=item * B<commit>

    my $response = $client->commit(
        project_id               => $project_id,
        database_id              => $database_id,
        mode                     => $mode,
        mutations                => [ ... ],
        request_options          => $request_options,
    );

Calls the RPC method C<Commit> on C<google.datastore.v1.Datastore>.

Request: L<Google::Datastore::V1::Datastore::CommitRequest>

Returns: L<Google::Datastore::V1::Datastore::CommitResponse>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<database_id> - C<string>

=item * C<mode> - L<Google::Datastore::V1::Datastore::Mode>

=item * C<mutations> - ArrayRef of L<Google::Datastore::V1::Datastore::Mutation>

=item * C<request_options> - L<Google::Datastore::V1::Datastore::RequestOptions>

=back

=item * B<rollback>

    my $response = $client->rollback(
        project_id               => $project_id,
        database_id              => $database_id,
        transaction              => $transaction,
        request_options          => $request_options,
    );

Calls the RPC method C<Rollback> on C<google.datastore.v1.Datastore>.

Request: L<Google::Datastore::V1::Datastore::RollbackRequest>

Returns: L<Google::Datastore::V1::Datastore::RollbackResponse>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<database_id> - C<string>

=item * C<transaction> - C<bytes>

=item * C<request_options> - L<Google::Datastore::V1::Datastore::RequestOptions>

=back

=item * B<allocate_ids>

    my $response = $client->allocate_ids(
        project_id               => $project_id,
        database_id              => $database_id,
        keys                     => [ ... ],
        request_options          => $request_options,
    );

Calls the RPC method C<AllocateIds> on C<google.datastore.v1.Datastore>.

Request: L<Google::Datastore::V1::Datastore::AllocateIdsRequest>

Returns: L<Google::Datastore::V1::Datastore::AllocateIdsResponse>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<database_id> - C<string>

=item * C<keys> - ArrayRef of L<Google::Datastore::V1::Entity::Key>

=item * C<request_options> - L<Google::Datastore::V1::Datastore::RequestOptions>

=back

=item * B<reserve_ids>

    my $response = $client->reserve_ids(
        project_id               => $project_id,
        database_id              => $database_id,
        keys                     => [ ... ],
        request_options          => $request_options,
    );

Calls the RPC method C<ReserveIds> on C<google.datastore.v1.Datastore>.

Request: L<Google::Datastore::V1::Datastore::ReserveIdsRequest>

Returns: L<Google::Datastore::V1::Datastore::ReserveIdsResponse>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<database_id> - C<string>

=item * C<keys> - ArrayRef of L<Google::Datastore::V1::Entity::Key>

=item * C<request_options> - L<Google::Datastore::V1::Datastore::RequestOptions>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
