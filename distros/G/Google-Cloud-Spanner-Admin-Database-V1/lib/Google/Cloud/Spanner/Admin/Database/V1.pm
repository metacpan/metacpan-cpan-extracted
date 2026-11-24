package Google::Cloud::Spanner::Admin::Database::V1;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Spanner::Admin::Database::V1::Common;
use Google::Spanner::Admin::Database::V1::Backup;
use Google::Spanner::Admin::Database::V1::BackupSchedule;
use Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin;

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

    my $target = 'spanner.googleapis.com:443';
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

sub list_databases {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::ListDatabasesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::ListDatabasesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.spanner.admin.database.v1.DatabaseAdmin/ListDatabases',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.database.v1.DatabaseAdmin',
        method         => 'ListDatabases',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub internal_update_graph_operation {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::InternalUpdateGraphOperationRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::InternalUpdateGraphOperationResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.spanner.admin.database.v1.DatabaseAdmin/InternalUpdateGraphOperation',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.database.v1.DatabaseAdmin',
        method         => 'InternalUpdateGraphOperation',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Spanner::Admin::Database::V1

__END__

=head1 NAME

Google::Cloud::Spanner::Admin::Database::V1 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Spanner::Admin::Database::V1;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Spanner::Admin::Database::V1->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Spanner::Admin::Database::V1->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Spanner::Admin::Database::V1> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/spanner/admin/database/v1/backup.proto>

=item * C<googleapis/google/spanner/admin/database/v1/backup_schedule.proto>

=item * C<googleapis/google/spanner/admin/database/v1/common.proto>

=item * C<googleapis/google/spanner/admin/database/v1/spanner_database_admin.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Spanner::Admin::Database::V1->new(
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

=item * B<list_databases>

    my $response = $client->list_databases(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListDatabases> on C<google.spanner.admin.database.v1.DatabaseAdmin>.

Request: L<Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::ListDatabasesRequest>

Returns: L<Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::ListDatabasesResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<internal_update_graph_operation>

    my $response = $client->internal_update_graph_operation(
        database                 => $database,
        operation_id             => $operation_id,
        vm_identity_token        => $vm_identity_token,
        progress                 => $progress,
        status                   => $status,
    );

Calls the RPC method C<InternalUpdateGraphOperation> on C<google.spanner.admin.database.v1.DatabaseAdmin>.

Request: L<Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::InternalUpdateGraphOperationRequest>

Returns: L<Google::Spanner::Admin::Database::V1::SpannerDatabaseAdmin::InternalUpdateGraphOperationResponse>

Parameters:

=over 4

=item * C<database> - C<string>

=item * C<operation_id> - C<string>

=item * C<vm_identity_token> - C<string>

=item * C<progress> - C<double>

=item * C<status> - L<Google::Rpc::Status::Status>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
