package Google::Cloud::Bigquery::V2::RowAccessPolicyServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Bigquery::V2::GenAiStats;
use Google::Cloud::Bigquery::V2::ManagedTableType;
use Google::Cloud::Bigquery::V2::FileSetSpecificationType;
use Google::Cloud::Bigquery::V2::MapTargetType;
use Google::Cloud::Bigquery::V2::Error;
use Google::Cloud::Bigquery::V2::JsonExtension;
use Google::Cloud::Bigquery::V2::LocationMetadata;
use Google::Cloud::Bigquery::V2::DecimalTargetTypes;
use Google::Cloud::Bigquery::V2::Clustering;
use Google::Cloud::Bigquery::V2::UdfResource;
use Google::Cloud::Bigquery::V2::RangePartitioning;
use Google::Cloud::Bigquery::V2::TableSchema;
use Google::Cloud::Bigquery::V2::SessionInfo;
use Google::Cloud::Bigquery::V2::StandardSql;
use Google::Cloud::Bigquery::V2::JobReference;
use Google::Cloud::Bigquery::V2::ExternalCatalogTableOptions;
use Google::Cloud::Bigquery::V2::BiglakeConfig;
use Google::Cloud::Bigquery::V2::PropertyGraphReference;
use Google::Cloud::Bigquery::V2::RoutineReference;
use Google::Cloud::Bigquery::V2::QueryParameter;
use Google::Cloud::Bigquery::V2::ModelReference;
use Google::Cloud::Bigquery::V2::HivePartitioning;
use Google::Cloud::Bigquery::V2::TableReference;
use Google::Cloud::Bigquery::V2::PartitioningDefinition;
use Google::Cloud::Bigquery::V2::ExternalCatalogDatasetOptions;
use Google::Cloud::Bigquery::V2::RestrictionConfig;
use Google::Cloud::Bigquery::V2::JobStatus;
use Google::Cloud::Bigquery::V2::JobCreationReason;
use Google::Cloud::Bigquery::V2::TimePartitioning;
use Google::Cloud::Bigquery::V2::RowAccessPolicyReference;
use Google::Cloud::Bigquery::V2::EncryptionConfig;
use Google::Cloud::Bigquery::V2::PrivacyPolicy;
use Google::Cloud::Bigquery::V2::DataFormatOptions;
use Google::Cloud::Bigquery::V2::DatasetReference;
use Google::Cloud::Bigquery::V2::ExternalDatasetReference;
use Google::Cloud::Bigquery::V2::Project;
use Google::Cloud::Bigquery::V2::SystemVariable;
use Google::Cloud::Bigquery::V2::Routine;
use Google::Cloud::Bigquery::V2::ExternalDataConfig;
use Google::Cloud::Bigquery::V2::TableConstraints;
use Google::Cloud::Bigquery::V2::RowAccessPolicy;
use Google::Cloud::Bigquery::V2::Model;
use Google::Cloud::Bigquery::V2::Dataset;
use Google::Cloud::Bigquery::V2::JobConfig;
use Google::Cloud::Bigquery::V2::Table;
use Google::Cloud::Bigquery::V2::JobStats;
use Google::Cloud::Bigquery::V2::Job;

our $VERSION = '0.04';

has credentials => ( is => 'ro', required => 0 );
has transport   => ( is => 'rw' );

sub BUILD {
    my ($self) = @_;

    # Resolve credentials: use passed credentials object if it implements get_token, or default to ADC
    my $auth = $self->credentials;
    if (!$auth || !eval { $auth->can('get_token') }) {
        $auth = Google::Auth->default();
    }
    my $token = $auth->get_token();

    my $target = 'localhost:50051';
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
        # Default high-performance HTTP/2 gRPC client
        my $client = Google::gRPC::Client->new(
            target     => $target,
            auth_token => $token,
        );
        $self->transport($client);
    }
}

sub list_row_access_policies {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::RowAccessPolicy::ListRowAccessPoliciesRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::RowAccessPolicy::ListRowAccessPoliciesResponse';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.RowAccessPolicyService',
        method         => 'ListRowAccessPolicies',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_row_access_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::RowAccessPolicy::GetRowAccessPolicyRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.RowAccessPolicyService',
        method         => 'GetRowAccessPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_row_access_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::RowAccessPolicy::CreateRowAccessPolicyRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.RowAccessPolicyService',
        method         => 'CreateRowAccessPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_row_access_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::RowAccessPolicy::UpdateRowAccessPolicyRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.RowAccessPolicyService',
        method         => 'UpdateRowAccessPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_row_access_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::RowAccessPolicy::DeleteRowAccessPolicyRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Protobuf::Empty::Empty';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.RowAccessPolicyService',
        method         => 'DeleteRowAccessPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub batch_delete_row_access_policies {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::RowAccessPolicy::BatchDeleteRowAccessPoliciesRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Protobuf::Empty::Empty';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.RowAccessPolicyService',
        method         => 'BatchDeleteRowAccessPolicies',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Bigquery::V2::RowAccessPolicyServiceClient

__END__

=head1 NAME

Google::Cloud::Bigquery::V2::RowAccessPolicyServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::V2::RowAccessPolicyServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Bigquery::V2::RowAccessPolicyServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Bigquery::V2::RowAccessPolicyServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Bigquery::V2::RowAccessPolicyServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<google/cloud/bigquery/v2/session_info.proto>

=item * C<google/cloud/bigquery/v2/job_reference.proto>

=item * C<google/cloud/bigquery/v2/query_parameter.proto>

=item * C<google/cloud/bigquery/v2/row_access_policy.proto>

=item * C<google/cloud/bigquery/v2/row_access_policy_reference.proto>

=item * C<google/cloud/bigquery/v2/project.proto>

=item * C<google/cloud/bigquery/v2/udf_resource.proto>

=item * C<google/cloud/bigquery/v2/time_partitioning.proto>

=item * C<google/cloud/bigquery/v2/table.proto>

=item * C<google/cloud/bigquery/v2/external_data_config.proto>

=item * C<google/cloud/bigquery/v2/data_format_options.proto>

=item * C<google/cloud/bigquery/v2/privacy_policy.proto>

=item * C<google/cloud/bigquery/v2/partitioning_definition.proto>

=item * C<google/cloud/bigquery/v2/restriction_config.proto>

=item * C<google/cloud/bigquery/v2/managed_table_type.proto>

=item * C<google/cloud/bigquery/v2/range_partitioning.proto>

=item * C<google/cloud/bigquery/v2/external_catalog_table_options.proto>

=item * C<google/cloud/bigquery/v2/model_reference.proto>

=item * C<google/cloud/bigquery/v2/biglake_config.proto>

=item * C<google/cloud/bigquery/v2/decimal_target_types.proto>

=item * C<google/cloud/bigquery/v2/routine_reference.proto>

=item * C<google/cloud/bigquery/v2/job_config.proto>

=item * C<google/cloud/bigquery/v2/job_status.proto>

=item * C<google/cloud/bigquery/v2/table_constraints.proto>

=item * C<google/cloud/bigquery/v2/json_extension.proto>

=item * C<google/cloud/bigquery/v2/file_set_specification_type.proto>

=item * C<google/cloud/bigquery/v2/location_metadata.proto>

=item * C<google/cloud/bigquery/v2/external_dataset_reference.proto>

=item * C<google/cloud/bigquery/v2/dataset_reference.proto>

=item * C<google/cloud/bigquery/v2/system_variable.proto>

=item * C<google/cloud/bigquery/v2/encryption_config.proto>

=item * C<google/cloud/bigquery/v2/table_reference.proto>

=item * C<google/cloud/bigquery/v2/hive_partitioning.proto>

=item * C<google/cloud/bigquery/v2/job.proto>

=item * C<google/cloud/bigquery/v2/gen_ai_stats.proto>

=item * C<google/cloud/bigquery/v2/standard_sql.proto>

=item * C<google/cloud/bigquery/v2/property_graph_reference.proto>

=item * C<google/cloud/bigquery/v2/external_catalog_dataset_options.proto>

=item * C<google/cloud/bigquery/v2/model.proto>

=item * C<google/cloud/bigquery/v2/clustering.proto>

=item * C<google/cloud/bigquery/v2/table_schema.proto>

=item * C<google/cloud/bigquery/v2/dataset.proto>

=item * C<google/cloud/bigquery/v2/error.proto>

=item * C<google/cloud/bigquery/v2/job_creation_reason.proto>

=item * C<google/cloud/bigquery/v2/job_stats.proto>

=item * C<google/cloud/bigquery/v2/map_target_type.proto>

=item * C<google/cloud/bigquery/v2/routine.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Bigquery::V2::RowAccessPolicyServiceClient->new(
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

=item * B<list_row_access_policies>

Calls the RPC method C<ListRowAccessPolicies> on the service. Takes a hash of parameters representing the request.

=item * B<get_row_access_policy>

Calls the RPC method C<GetRowAccessPolicy> on the service. Takes a hash of parameters representing the request.

=item * B<create_row_access_policy>

Calls the RPC method C<CreateRowAccessPolicy> on the service. Takes a hash of parameters representing the request.

=item * B<update_row_access_policy>

Calls the RPC method C<UpdateRowAccessPolicy> on the service. Takes a hash of parameters representing the request.

=item * B<delete_row_access_policy>

Calls the RPC method C<DeleteRowAccessPolicy> on the service. Takes a hash of parameters representing the request.

=item * B<batch_delete_row_access_policies>

Calls the RPC method C<BatchDeleteRowAccessPolicies> on the service. Takes a hash of parameters representing the request.

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
