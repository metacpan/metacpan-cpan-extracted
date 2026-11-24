package Google::Cloud::Bigquery::V2::DatasetServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Bigquery::V2::ManagedTableType;
use Google::Cloud::Bigquery::V2::Arrow;
use Google::Cloud::Bigquery::V2::Error;
use Google::Cloud::Bigquery::V2::GenAiStats;
use Google::Cloud::Bigquery::V2::DecimalTargetTypes;
use Google::Cloud::Bigquery::V2::LocationMetadata;
use Google::Cloud::Bigquery::V2::JsonExtension;
use Google::Cloud::Bigquery::V2::Clustering;
use Google::Cloud::Bigquery::V2::MapTargetType;
use Google::Cloud::Bigquery::V2::FileSetSpecificationType;
use Google::Cloud::Bigquery::V2::UdfResource;
use Google::Cloud::Bigquery::V2::RangePartitioning;
use Google::Cloud::Bigquery::V2::TimePartitioning;
use Google::Cloud::Bigquery::V2::RowAccessPolicyReference;
use Google::Cloud::Bigquery::V2::HivePartitioning;
use Google::Cloud::Bigquery::V2::PropertyGraphReference;
use Google::Cloud::Bigquery::V2::PrivacyPolicy;
use Google::Cloud::Bigquery::V2::ExternalCatalogDatasetOptions;
use Google::Cloud::Bigquery::V2::ModelReference;
use Google::Cloud::Bigquery::V2::ExternalCatalogTableOptions;
use Google::Cloud::Bigquery::V2::RestrictionConfig;
use Google::Cloud::Bigquery::V2::PartitioningDefinition;
use Google::Cloud::Bigquery::V2::JobCreationReason;
use Google::Cloud::Bigquery::V2::TableSchema;
use Google::Cloud::Bigquery::V2::TableReference;
use Google::Cloud::Bigquery::V2::JobStatus;
use Google::Cloud::Bigquery::V2::EncryptionConfig;
use Google::Cloud::Bigquery::V2::StandardSql;
use Google::Cloud::Bigquery::V2::DataFormatOptions;
use Google::Cloud::Bigquery::V2::RoutineReference;
use Google::Cloud::Bigquery::V2::DatasetReference;
use Google::Cloud::Bigquery::V2::JobReference;
use Google::Cloud::Bigquery::V2::SessionInfo;
use Google::Cloud::Bigquery::V2::BiglakeConfig;
use Google::Cloud::Bigquery::V2::QueryParameter;
use Google::Cloud::Bigquery::V2::ExternalDatasetReference;
use Google::Cloud::Bigquery::V2::Project;
use Google::Cloud::Bigquery::V2::RowAccessPolicy;
use Google::Cloud::Bigquery::V2::ExternalDataConfig;
use Google::Cloud::Bigquery::V2::TableConstraints;
use Google::Cloud::Bigquery::V2::Model;
use Google::Cloud::Bigquery::V2::SystemVariable;
use Google::Cloud::Bigquery::V2::Routine;
use Google::Cloud::Bigquery::V2::Dataset;
use Google::Cloud::Bigquery::V2::Table;
use Google::Cloud::Bigquery::V2::JobStats;
use Google::Cloud::Bigquery::V2::JobConfig;
use Google::Cloud::Bigquery::V2::Job;

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

    my $target = 'bigquery.googleapis.com:443';
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

sub get_dataset {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Dataset::GetDatasetRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Bigquery::V2::Dataset::Dataset';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.bigquery.v2.DatasetService/GetDataset',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.DatasetService',
        method         => 'GetDataset',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub insert_dataset {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Dataset::InsertDatasetRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Bigquery::V2::Dataset::Dataset';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.bigquery.v2.DatasetService/InsertDataset',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.DatasetService',
        method         => 'InsertDataset',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch_dataset {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Dataset::UpdateOrPatchDatasetRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Bigquery::V2::Dataset::Dataset';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.bigquery.v2.DatasetService/PatchDataset',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.DatasetService',
        method         => 'PatchDataset',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_dataset {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Dataset::UpdateOrPatchDatasetRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Bigquery::V2::Dataset::Dataset';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.bigquery.v2.DatasetService/UpdateDataset',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.DatasetService',
        method         => 'UpdateDataset',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_dataset {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Dataset::DeleteDatasetRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Protobuf::Empty::Empty';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.bigquery.v2.DatasetService/DeleteDataset',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.DatasetService',
        method         => 'DeleteDataset',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_datasets {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Dataset::ListDatasetsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Bigquery::V2::Dataset::DatasetList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.bigquery.v2.DatasetService/ListDatasets',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.DatasetService',
        method         => 'ListDatasets',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub undelete_dataset {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Dataset::UndeleteDatasetRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Bigquery::V2::Dataset::Dataset';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.bigquery.v2.DatasetService/UndeleteDataset',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.DatasetService',
        method         => 'UndeleteDataset',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Bigquery::V2::DatasetServiceClient

__END__

=head1 NAME

Google::Cloud::Bigquery::V2::DatasetServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::V2::DatasetServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Bigquery::V2::DatasetServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Bigquery::V2::DatasetServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Bigquery::V2::DatasetServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/bigquery/v2/arrow.proto>

=item * C<googleapis/google/cloud/bigquery/v2/biglake_config.proto>

=item * C<googleapis/google/cloud/bigquery/v2/clustering.proto>

=item * C<googleapis/google/cloud/bigquery/v2/data_format_options.proto>

=item * C<googleapis/google/cloud/bigquery/v2/dataset.proto>

=item * C<googleapis/google/cloud/bigquery/v2/dataset_reference.proto>

=item * C<googleapis/google/cloud/bigquery/v2/decimal_target_types.proto>

=item * C<googleapis/google/cloud/bigquery/v2/encryption_config.proto>

=item * C<googleapis/google/cloud/bigquery/v2/error.proto>

=item * C<googleapis/google/cloud/bigquery/v2/external_catalog_dataset_options.proto>

=item * C<googleapis/google/cloud/bigquery/v2/external_catalog_table_options.proto>

=item * C<googleapis/google/cloud/bigquery/v2/external_data_config.proto>

=item * C<googleapis/google/cloud/bigquery/v2/external_dataset_reference.proto>

=item * C<googleapis/google/cloud/bigquery/v2/file_set_specification_type.proto>

=item * C<googleapis/google/cloud/bigquery/v2/gen_ai_stats.proto>

=item * C<googleapis/google/cloud/bigquery/v2/hive_partitioning.proto>

=item * C<googleapis/google/cloud/bigquery/v2/job.proto>

=item * C<googleapis/google/cloud/bigquery/v2/job_config.proto>

=item * C<googleapis/google/cloud/bigquery/v2/job_creation_reason.proto>

=item * C<googleapis/google/cloud/bigquery/v2/job_reference.proto>

=item * C<googleapis/google/cloud/bigquery/v2/job_stats.proto>

=item * C<googleapis/google/cloud/bigquery/v2/job_status.proto>

=item * C<googleapis/google/cloud/bigquery/v2/json_extension.proto>

=item * C<googleapis/google/cloud/bigquery/v2/location_metadata.proto>

=item * C<googleapis/google/cloud/bigquery/v2/managed_table_type.proto>

=item * C<googleapis/google/cloud/bigquery/v2/map_target_type.proto>

=item * C<googleapis/google/cloud/bigquery/v2/model.proto>

=item * C<googleapis/google/cloud/bigquery/v2/model_reference.proto>

=item * C<googleapis/google/cloud/bigquery/v2/partitioning_definition.proto>

=item * C<googleapis/google/cloud/bigquery/v2/privacy_policy.proto>

=item * C<googleapis/google/cloud/bigquery/v2/project.proto>

=item * C<googleapis/google/cloud/bigquery/v2/property_graph_reference.proto>

=item * C<googleapis/google/cloud/bigquery/v2/query_parameter.proto>

=item * C<googleapis/google/cloud/bigquery/v2/range_partitioning.proto>

=item * C<googleapis/google/cloud/bigquery/v2/restriction_config.proto>

=item * C<googleapis/google/cloud/bigquery/v2/routine.proto>

=item * C<googleapis/google/cloud/bigquery/v2/routine_reference.proto>

=item * C<googleapis/google/cloud/bigquery/v2/row_access_policy.proto>

=item * C<googleapis/google/cloud/bigquery/v2/row_access_policy_reference.proto>

=item * C<googleapis/google/cloud/bigquery/v2/session_info.proto>

=item * C<googleapis/google/cloud/bigquery/v2/standard_sql.proto>

=item * C<googleapis/google/cloud/bigquery/v2/system_variable.proto>

=item * C<googleapis/google/cloud/bigquery/v2/table.proto>

=item * C<googleapis/google/cloud/bigquery/v2/table_constraints.proto>

=item * C<googleapis/google/cloud/bigquery/v2/table_reference.proto>

=item * C<googleapis/google/cloud/bigquery/v2/table_schema.proto>

=item * C<googleapis/google/cloud/bigquery/v2/time_partitioning.proto>

=item * C<googleapis/google/cloud/bigquery/v2/udf_resource.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Bigquery::V2::DatasetServiceClient->new(
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

=item * B<get_dataset>

    my $response = $client->get_dataset(
        project_id               => $project_id,
        dataset_id               => $dataset_id,
        dataset_view             => $dataset_view,
        access_policy_version    => $access_policy_version,
    );

Calls the RPC method C<GetDataset> on C<google.cloud.bigquery.v2.DatasetService>.

Request: L<Google::Cloud::Bigquery::V2::Dataset::GetDatasetRequest>

Returns: L<Google::Cloud::Bigquery::V2::Dataset::Dataset>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<dataset_id> - C<string>

=item * C<dataset_view> - L<Google::Cloud::Bigquery::V2::Dataset::DatasetView>

=item * C<access_policy_version> - C<int32>

=back

=item * B<insert_dataset>

    my $response = $client->insert_dataset(
        project_id               => $project_id,
        dataset                  => $dataset,
        access_policy_version    => $access_policy_version,
    );

Calls the RPC method C<InsertDataset> on C<google.cloud.bigquery.v2.DatasetService>.

Request: L<Google::Cloud::Bigquery::V2::Dataset::InsertDatasetRequest>

Returns: L<Google::Cloud::Bigquery::V2::Dataset::Dataset>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<dataset> - L<Google::Cloud::Bigquery::V2::Dataset::Dataset>

=item * C<access_policy_version> - C<int32>

=back

=item * B<patch_dataset>

    my $response = $client->patch_dataset(
        project_id               => $project_id,
        dataset_id               => $dataset_id,
        dataset                  => $dataset,
        update_mode              => $update_mode,
        access_policy_version    => $access_policy_version,
    );

Calls the RPC method C<PatchDataset> on C<google.cloud.bigquery.v2.DatasetService>.

Request: L<Google::Cloud::Bigquery::V2::Dataset::UpdateOrPatchDatasetRequest>

Returns: L<Google::Cloud::Bigquery::V2::Dataset::Dataset>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<dataset_id> - C<string>

=item * C<dataset> - L<Google::Cloud::Bigquery::V2::Dataset::Dataset>

=item * C<update_mode> - L<Google::Cloud::Bigquery::V2::Dataset::UpdateMode>

=item * C<access_policy_version> - C<int32>

=back

=item * B<update_dataset>

    my $response = $client->update_dataset(
        project_id               => $project_id,
        dataset_id               => $dataset_id,
        dataset                  => $dataset,
        update_mode              => $update_mode,
        access_policy_version    => $access_policy_version,
    );

Calls the RPC method C<UpdateDataset> on C<google.cloud.bigquery.v2.DatasetService>.

Request: L<Google::Cloud::Bigquery::V2::Dataset::UpdateOrPatchDatasetRequest>

Returns: L<Google::Cloud::Bigquery::V2::Dataset::Dataset>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<dataset_id> - C<string>

=item * C<dataset> - L<Google::Cloud::Bigquery::V2::Dataset::Dataset>

=item * C<update_mode> - L<Google::Cloud::Bigquery::V2::Dataset::UpdateMode>

=item * C<access_policy_version> - C<int32>

=back

=item * B<delete_dataset>

    my $response = $client->delete_dataset(
        project_id               => $project_id,
        dataset_id               => $dataset_id,
        delete_contents          => $delete_contents,
    );

Calls the RPC method C<DeleteDataset> on C<google.cloud.bigquery.v2.DatasetService>.

Request: L<Google::Cloud::Bigquery::V2::Dataset::DeleteDatasetRequest>

Returns: L<Google::Protobuf::Empty::Empty>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<dataset_id> - C<string>

=item * C<delete_contents> - C<bool>

=back

=item * B<list_datasets>

    my $response = $client->list_datasets(
        project_id               => $project_id,
        max_results              => $max_results,
        page_token               => $page_token,
        all                      => $all,
        filter                   => $filter,
    );

Calls the RPC method C<ListDatasets> on C<google.cloud.bigquery.v2.DatasetService>.

Request: L<Google::Cloud::Bigquery::V2::Dataset::ListDatasetsRequest>

Returns: L<Google::Cloud::Bigquery::V2::Dataset::DatasetList>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<max_results> - L<Google::Protobuf::UInt32Value::UInt32Value>

=item * C<page_token> - C<string>

=item * C<all> - C<bool>

=item * C<filter> - C<string>

=back

=item * B<undelete_dataset>

    my $response = $client->undelete_dataset(
        project_id               => $project_id,
        dataset_id               => $dataset_id,
        deletion_time            => $deletion_time,
    );

Calls the RPC method C<UndeleteDataset> on C<google.cloud.bigquery.v2.DatasetService>.

Request: L<Google::Cloud::Bigquery::V2::Dataset::UndeleteDatasetRequest>

Returns: L<Google::Cloud::Bigquery::V2::Dataset::Dataset>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<dataset_id> - C<string>

=item * C<deletion_time> - L<Google::Protobuf::Timestamp::Timestamp>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
