package Google::Cloud::Sql::V1::SqlWorkloadCapturesServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Sql::V1::CloudSqlResources;
use Google::Cloud::Sql::V1::CloudSqlIamPolicies;
use Google::Cloud::Sql::V1::CloudSqlTiers;
use Google::Cloud::Sql::V1::CloudSqlInstanceNames;
use Google::Cloud::Sql::V1::CloudSqlEvents;
use Google::Cloud::Sql::V1::CloudSqlRegions;
use Google::Cloud::Sql::V1::CloudSqlAvailableDatabaseVersions;
use Google::Cloud::Sql::V1::CloudSqlFeatureEligibility;
use Google::Cloud::Sql::V1::CloudSqlSslCerts;
use Google::Cloud::Sql::V1::CloudSqlBackupRuns;
use Google::Cloud::Sql::V1::CloudSqlUsers;
use Google::Cloud::Sql::V1::CloudSqlFlags;
use Google::Cloud::Sql::V1::CloudSqlOperations;
use Google::Cloud::Sql::V1::CloudSqlInstances;
use Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures;
use Google::Cloud::Sql::V1::CloudSqlDatabases;
use Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments;
use Google::Cloud::Sql::V1::CloudSqlConnect;
use Google::Cloud::Sql::V1::CloudSqlBackups;

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

sub start {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::WorkloadCapturesStartRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1.SqlWorkloadCapturesService/Start',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1.SqlWorkloadCapturesService',
        method         => 'Start',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub stop {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::WorkloadCapturesStopRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1.SqlWorkloadCapturesService/Stop',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1.SqlWorkloadCapturesService',
        method         => 'Stop',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub start_replay {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::WorkloadCapturesStartReplayRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1.SqlWorkloadCapturesService/StartReplay',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1.SqlWorkloadCapturesService',
        method         => 'StartReplay',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub stop_replay {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::WorkloadCapturesStopReplayRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1.SqlWorkloadCapturesService/StopReplay',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1.SqlWorkloadCapturesService',
        method         => 'StopReplay',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::SqlWorkloadCapturesListRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::WorkloadCapturesListResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1.SqlWorkloadCapturesService/List',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1.SqlWorkloadCapturesService',
        method         => 'List',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Sql::V1::SqlWorkloadCapturesServiceClient

__END__

=head1 NAME

Google::Cloud::Sql::V1::SqlWorkloadCapturesServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::SqlWorkloadCapturesServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Sql::V1::SqlWorkloadCapturesServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Sql::V1::SqlWorkloadCapturesServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Sql::V1::SqlWorkloadCapturesServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_available_database_versions.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_backup_runs.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_backups.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_blue_green_deployments.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_connect.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_databases.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_events.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_feature_eligibility.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_flags.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_iam_policies.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_instance_names.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_instances.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_operations.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_regions.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_resources.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_ssl_certs.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_tiers.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_users.proto>

=item * C<googleapis/google/cloud/sql/v1/cloud_sql_workload_captures.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Sql::V1::SqlWorkloadCapturesServiceClient->new(
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

=item * B<start>

    my $response = $client->start(
        project                  => $project,
        instance                 => $instance,
        start_workload_capture_context => $start_workload_capture_context,
    );

Calls the RPC method C<Start> on C<google.cloud.sql.v1.SqlWorkloadCapturesService>.

Request: L<Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::WorkloadCapturesStartRequest>

Returns: L<Google::Cloud::Sql::V1::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<instance> - C<string>

=item * C<start_workload_capture_context> - L<Google::Cloud::Sql::V1::CloudSqlResources::StartWorkloadCaptureContext>

=back

=item * B<stop>

    my $response = $client->stop(
        project                  => $project,
        instance                 => $instance,
        stop_workload_capture_context => $stop_workload_capture_context,
    );

Calls the RPC method C<Stop> on C<google.cloud.sql.v1.SqlWorkloadCapturesService>.

Request: L<Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::WorkloadCapturesStopRequest>

Returns: L<Google::Cloud::Sql::V1::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<instance> - C<string>

=item * C<stop_workload_capture_context> - L<Google::Cloud::Sql::V1::CloudSqlResources::StopWorkloadCaptureContext>

=back

=item * B<start_replay>

    my $response = $client->start_replay(
        project                  => $project,
        instance                 => $instance,
        start_workload_replay_context => $start_workload_replay_context,
        workload_id              => $workload_id,
    );

Calls the RPC method C<StartReplay> on C<google.cloud.sql.v1.SqlWorkloadCapturesService>.

Request: L<Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::WorkloadCapturesStartReplayRequest>

Returns: L<Google::Cloud::Sql::V1::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<instance> - C<string>

=item * C<start_workload_replay_context> - L<Google::Cloud::Sql::V1::CloudSqlResources::StartWorkloadReplayContext>

=item * C<workload_id> - C<string>

=back

=item * B<stop_replay>

    my $response = $client->stop_replay(
        project                  => $project,
        instance                 => $instance,
        stop_workload_replay_context => $stop_workload_replay_context,
    );

Calls the RPC method C<StopReplay> on C<google.cloud.sql.v1.SqlWorkloadCapturesService>.

Request: L<Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::WorkloadCapturesStopReplayRequest>

Returns: L<Google::Cloud::Sql::V1::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<instance> - C<string>

=item * C<stop_workload_replay_context> - L<Google::Cloud::Sql::V1::CloudSqlResources::StopWorkloadReplayContext>

=back

=item * B<list>

    my $response = $client->list(
        project                  => $project,
        instance                 => $instance,
    );

Calls the RPC method C<List> on C<google.cloud.sql.v1.SqlWorkloadCapturesService>.

Request: L<Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::SqlWorkloadCapturesListRequest>

Returns: L<Google::Cloud::Sql::V1::CloudSqlWorkloadCaptures::WorkloadCapturesListResponse>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<instance> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
