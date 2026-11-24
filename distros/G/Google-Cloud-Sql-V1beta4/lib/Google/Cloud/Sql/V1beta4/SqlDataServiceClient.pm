package Google::Cloud::Sql::V1beta4::SqlDataServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Sql::V1beta4::CloudSqlResources;
use Google::Cloud::Sql::V1beta4::CloudSqlData;
use Google::Cloud::Sql::V1beta4::CloudSqlTiers;
use Google::Cloud::Sql::V1beta4::CloudSqlIamPolicies;
use Google::Cloud::Sql::V1beta4::CloudSqlUsers;
use Google::Cloud::Sql::V1beta4::CloudSql;
use Google::Cloud::Sql::V1beta4::CloudSqlBlueGreenDeployments;
use Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures;
use Google::Cloud::Sql::V1beta4::CloudSqlConnect;

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

    my $target = 'sqladmin.googleapis.com:443';
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

sub stream_sql_data {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSqlData::StreamSqlDataRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlData::StreamSqlDataResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlDataService/StreamSqlData',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlDataService',
        method         => 'StreamSqlData',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Sql::V1beta4::SqlDataServiceClient

__END__

=head1 NAME

Google::Cloud::Sql::V1beta4::SqlDataServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1beta4::SqlDataServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Sql::V1beta4::SqlDataServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Sql::V1beta4::SqlDataServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Sql::V1beta4::SqlDataServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/sql/v1beta4/cloud_sql.proto>

=item * C<googleapis/google/cloud/sql/v1beta4/cloud_sql_blue_green_deployments.proto>

=item * C<googleapis/google/cloud/sql/v1beta4/cloud_sql_connect.proto>

=item * C<googleapis/google/cloud/sql/v1beta4/cloud_sql_data.proto>

=item * C<googleapis/google/cloud/sql/v1beta4/cloud_sql_iam_policies.proto>

=item * C<googleapis/google/cloud/sql/v1beta4/cloud_sql_resources.proto>

=item * C<googleapis/google/cloud/sql/v1beta4/cloud_sql_tiers.proto>

=item * C<googleapis/google/cloud/sql/v1beta4/cloud_sql_users.proto>

=item * C<googleapis/google/cloud/sql/v1beta4/cloud_sql_workload_captures.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Sql::V1beta4::SqlDataServiceClient->new(
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

=item * B<stream_sql_data>

    my $response = $client->stream_sql_data(
        ack                      => $ack,
        instance_id              => $instance_id,
    );

Calls the RPC method C<StreamSqlData> on C<google.cloud.sql.v1beta4.SqlDataService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSqlData::StreamSqlDataRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlData::StreamSqlDataResponse>

Parameters:

=over 4

=item * C<ack> - L<Google::Cloud::Sql::V1beta4::CloudSqlData::Ack>

=item * C<instance_id> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
