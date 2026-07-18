package Google::Cloud::Bigquery::V2;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Api::Inclusion;
use Google::Cloud::Bigquery::V2::UdfResource;
use Google::Cloud::Bigquery::V2::Error;
use Google::Cloud::Bigquery::V2::PartitioningDefinition;
use Google::Cloud::Bigquery::V2::Routine;
use Google::Cloud::Bigquery::V2::SecureContext;
use Google::Cloud::Bigquery::V2::TableReference;
use Google::Cloud::Bigquery::V2::JobReference;
use Google::Cloud::Bigquery::V2::Project;
use Google::Cloud::Bigquery::V2::Clustering;
use Google::Cloud::Bigquery::V2::RowAccessPolicyReference;
use Google::Cloud::Bigquery::V2::QueryParameter;
use Google::Cloud::Bigquery::V2::ExternalDataConfig;
use Google::Cloud::Bigquery::V2::DataFormatOptions;
use Google::Cloud::Bigquery::V2::Model;
use Google::Cloud::Bigquery::V2::ExternalCatalogTableOptions;
use Google::Cloud::Bigquery::V2::ModelReference;
use Google::Cloud::Bigquery::V2::RoutineReference;
use Google::Cloud::Bigquery::V2::MapTargetType;
use Google::Cloud::Bigquery::V2::JsonExtension;
use Google::Cloud::Bigquery::V2::LocationMetadata;
use Google::Cloud::Bigquery::V2::RestrictionConfig;
use Google::Cloud::Bigquery::V2::ManagedTableType;
use Google::Cloud::Bigquery::V2::Table;
use Google::Cloud::Bigquery::V2::PropertyGraphReference;
use Google::Cloud::Bigquery::V2::PropertyGraph;
use Google::Cloud::Bigquery::V2::DecimalTargetTypes;
use Google::Cloud::Bigquery::V2::JobStats;
use Google::Cloud::Bigquery::V2::JobConfig;
use Google::Cloud::Bigquery::V2::StandardSql;
use Google::Cloud::Bigquery::V2::BiglakeMetastoreDatasetReference;
use Google::Cloud::Bigquery::V2::SystemVariable;
use Google::Cloud::Bigquery::V2::JobCreationReason;
use Google::Cloud::Bigquery::V2::BiglakeConfig;
use Google::Cloud::Bigquery::V2::Job;
use Google::Cloud::Bigquery::V2::PrivacyPolicy;
use Google::Cloud::Bigquery::V2::RangePartitioning;
use Google::Cloud::Bigquery::V2::GenAiStats;
use Google::Cloud::Bigquery::V2::Tabledata;
use Google::Cloud::Bigquery::V2::Dataset;
use Google::Cloud::Bigquery::V2::ExternalDatasetReference;
use Google::Cloud::Bigquery::V2::FileSetSpecificationType;
use Google::Cloud::Bigquery::V2::HivePartitioning;
use Google::Cloud::Bigquery::V2::Arrow;
use Google::Cloud::Bigquery::V2::SystemProcedure;
use Google::Cloud::Bigquery::V2::TableConstraints;
use Google::Cloud::Bigquery::V2::TimePartitioning;
use Google::Cloud::Bigquery::V2::ValueConversionModes;
use Google::Cloud::Bigquery::V2::TableSchema;
use Google::Cloud::Bigquery::V2::Bqml;
use Google::Cloud::Bigquery::V2::RowAccessPolicy;
use Google::Cloud::Bigquery::V2::DatasetReference;
use Google::Cloud::Bigquery::V2::JobStatus;
use Google::Cloud::Bigquery::V2::EncryptionConfig;
use Google::Cloud::Bigquery::V2::SessionInfo;
use Google::Cloud::Bigquery::V2::ExternalCatalogDatasetOptions;
use Google::Cloud::Bigquery::V2::IcebergManagedTableConfig;
use Google::Cloud::Bigquery::V2::ThriftOptions;

our $VERSION = '0.02';

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

    my $target = 'bigquery.googleapis.com';
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
        # Default gRPC transport
        my $client = Google::gRPC::Client->new(
            target     => $target,
            auth_token => $token,
        );
        $self->transport($client);
    }
}

sub get_routine {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Routine::GetRoutineRequest';
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::Routine::Routine';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.RoutineService',
        method         => 'GetRoutine',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub insert_routine {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Routine::InsertRoutineRequest';
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::Routine::Routine';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.RoutineService',
        method         => 'InsertRoutine',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_routine {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Routine::UpdateRoutineRequest';
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::Routine::Routine';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.RoutineService',
        method         => 'UpdateRoutine',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch_routine {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Routine::PatchRoutineRequest';
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::Routine::Routine';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.RoutineService',
        method         => 'PatchRoutine',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_routine {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Routine::DeleteRoutineRequest';
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Protobuf::Empty::Empty';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.RoutineService',
        method         => 'DeleteRoutine',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_routines {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Routine::ListRoutinesRequest';
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::Routine::ListRoutinesResponse';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.RoutineService',
        method         => 'ListRoutines',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_projects {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Project::ListProjectsRequest';
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::Project::ProjectList';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.ProjectService',
        method         => 'ListProjects',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_service_account {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Project::GetServiceAccountRequest';
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::Project::GetServiceAccountResponse';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.ProjectService',
        method         => 'GetServiceAccount',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_model {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Model::GetModelRequest';
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::Model::Model';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.ModelService',
        method         => 'GetModel',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_models {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Model::ListModelsRequest';
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::Model::ListModelsResponse';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.ModelService',
        method         => 'ListModels',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch_model {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Model::PatchModelRequest';
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::Model::Model';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.ModelService',
        method         => 'PatchModel',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_model {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Model::DeleteModelRequest';
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Protobuf::Empty::Empty';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.ModelService',
        method         => 'DeleteModel',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_table {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Table::GetTableRequest';
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::Table::Table';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.TableService',
        method         => 'GetTable',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub insert_table {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Table::InsertTableRequest';
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::Table::Table';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.TableService',
        method         => 'InsertTable',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch_table {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Table::UpdateOrPatchTableRequest';
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::Table::Table';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.TableService',
        method         => 'PatchTable',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_table {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Table::UpdateOrPatchTableRequest';
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::Table::Table';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.TableService',
        method         => 'UpdateTable',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_table {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Table::DeleteTableRequest';
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Protobuf::Empty::Empty';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.TableService',
        method         => 'DeleteTable',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_tables {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Table::ListTablesRequest';
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::Table::TableList';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.TableService',
        method         => 'ListTables',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_property_graph {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::PropertyGraph::GetPropertyGraphRequest';
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::PropertyGraph::PropertyGraph';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.PropertyGraphService',
        method         => 'GetPropertyGraph',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_property_graphs {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::PropertyGraph::ListPropertyGraphsRequest';
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::PropertyGraph::ListPropertyGraphsResponse';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.PropertyGraphService',
        method         => 'ListPropertyGraphs',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_property_graph {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::PropertyGraph::DeletePropertyGraphRequest';
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Protobuf::Empty::Empty';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.PropertyGraphService',
        method         => 'DeletePropertyGraph',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub cancel_job {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Job::CancelJobRequest';
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::Job::JobCancelResponse';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.JobService',
        method         => 'CancelJob',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_job {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Job::GetJobRequest';
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::Job::Job';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.JobService',
        method         => 'GetJob',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub insert_job {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Job::InsertJobRequest';
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::Job::Job';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.JobService',
        method         => 'InsertJob',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_job {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Job::UpdateJobRequest';
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::Job::Job';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.JobService',
        method         => 'UpdateJob',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_job {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Job::DeleteJobRequest';
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Protobuf::Empty::Empty';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.JobService',
        method         => 'DeleteJob',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_jobs {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Job::ListJobsRequest';
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::Job::JobList';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.JobService',
        method         => 'ListJobs',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_query_results {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Job::GetQueryResultsRequest';
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::Job::GetQueryResultsResponse';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.JobService',
        method         => 'GetQueryResults',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub query {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Job::PostQueryRequest';
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::Job::QueryResponse';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.JobService',
        method         => 'Query',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub insert_all {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Tabledata::TableDataInsertAllRequest';
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::Tabledata::TableDataInsertAllResponse';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.TableDataService',
        method         => 'InsertAll',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Tabledata::TableDataListRequest';
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::Tabledata::TableDataList';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.TableDataService',
        method         => 'List',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_dataset {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Dataset::GetDatasetRequest';
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::Dataset::Dataset';
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
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::Dataset::Dataset';
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
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::Dataset::Dataset';
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
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::Dataset::Dataset';
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
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Protobuf::Empty::Empty';
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
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::Dataset::DatasetList';
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
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Cloud::Bigquery::V2::Dataset::Dataset';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.DatasetService',
        method         => 'UndeleteDataset',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_row_access_policies {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::RowAccessPolicy::ListRowAccessPoliciesRequest';
    my $request = $request_class->new(%params);

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
    my $request = $request_class->new(%params);

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
    my $request = $request_class->new(%params);

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
    my $request = $request_class->new(%params);

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
    my $request = $request_class->new(%params);

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
    my $request = $request_class->new(%params);

    my $response_class = 'Google::Protobuf::Empty::Empty';
    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.RowAccessPolicyService',
        method         => 'BatchDeleteRowAccessPolicies',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Bigquery::V2

__END__

=head1 NAME

Google::Cloud::Bigquery::V2 - Auto-generated client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::V2;
    use Google::Auth;

    my $auth = Google::Auth->new(...);
    my $client = Google::Cloud::Bigquery::V2->new(
        credentials => $auth
    );

=head1 DESCRIPTION

This is an auto-generated Protocol Buffers client library for Google Cloud Services, built on top of high-performance gRPC and Protocol Buffers!

=head1 METHODS

The following RPC methods are available in this client:

=over 4

=item * B<get_routine>

Calls the RPC method C<GetRoutine> on the service. Takes a hash of parameters representing the request.

=item * B<insert_routine>

Calls the RPC method C<InsertRoutine> on the service. Takes a hash of parameters representing the request.

=item * B<update_routine>

Calls the RPC method C<UpdateRoutine> on the service. Takes a hash of parameters representing the request.

=item * B<patch_routine>

Calls the RPC method C<PatchRoutine> on the service. Takes a hash of parameters representing the request.

=item * B<delete_routine>

Calls the RPC method C<DeleteRoutine> on the service. Takes a hash of parameters representing the request.

=item * B<list_routines>

Calls the RPC method C<ListRoutines> on the service. Takes a hash of parameters representing the request.

=item * B<list_projects>

Calls the RPC method C<ListProjects> on the service. Takes a hash of parameters representing the request.

=item * B<get_service_account>

Calls the RPC method C<GetServiceAccount> on the service. Takes a hash of parameters representing the request.

=item * B<get_model>

Calls the RPC method C<GetModel> on the service. Takes a hash of parameters representing the request.

=item * B<list_models>

Calls the RPC method C<ListModels> on the service. Takes a hash of parameters representing the request.

=item * B<patch_model>

Calls the RPC method C<PatchModel> on the service. Takes a hash of parameters representing the request.

=item * B<delete_model>

Calls the RPC method C<DeleteModel> on the service. Takes a hash of parameters representing the request.

=item * B<get_table>

Calls the RPC method C<GetTable> on the service. Takes a hash of parameters representing the request.

=item * B<insert_table>

Calls the RPC method C<InsertTable> on the service. Takes a hash of parameters representing the request.

=item * B<patch_table>

Calls the RPC method C<PatchTable> on the service. Takes a hash of parameters representing the request.

=item * B<update_table>

Calls the RPC method C<UpdateTable> on the service. Takes a hash of parameters representing the request.

=item * B<delete_table>

Calls the RPC method C<DeleteTable> on the service. Takes a hash of parameters representing the request.

=item * B<list_tables>

Calls the RPC method C<ListTables> on the service. Takes a hash of parameters representing the request.

=item * B<get_property_graph>

Calls the RPC method C<GetPropertyGraph> on the service. Takes a hash of parameters representing the request.

=item * B<list_property_graphs>

Calls the RPC method C<ListPropertyGraphs> on the service. Takes a hash of parameters representing the request.

=item * B<delete_property_graph>

Calls the RPC method C<DeletePropertyGraph> on the service. Takes a hash of parameters representing the request.

=item * B<cancel_job>

Calls the RPC method C<CancelJob> on the service. Takes a hash of parameters representing the request.

=item * B<get_job>

Calls the RPC method C<GetJob> on the service. Takes a hash of parameters representing the request.

=item * B<insert_job>

Calls the RPC method C<InsertJob> on the service. Takes a hash of parameters representing the request.

=item * B<update_job>

Calls the RPC method C<UpdateJob> on the service. Takes a hash of parameters representing the request.

=item * B<delete_job>

Calls the RPC method C<DeleteJob> on the service. Takes a hash of parameters representing the request.

=item * B<list_jobs>

Calls the RPC method C<ListJobs> on the service. Takes a hash of parameters representing the request.

=item * B<get_query_results>

Calls the RPC method C<GetQueryResults> on the service. Takes a hash of parameters representing the request.

=item * B<query>

Calls the RPC method C<Query> on the service. Takes a hash of parameters representing the request.

=item * B<insert_all>

Calls the RPC method C<InsertAll> on the service. Takes a hash of parameters representing the request.

=item * B<list>

Calls the RPC method C<List> on the service. Takes a hash of parameters representing the request.

=item * B<get_dataset>

Calls the RPC method C<GetDataset> on the service. Takes a hash of parameters representing the request.

=item * B<insert_dataset>

Calls the RPC method C<InsertDataset> on the service. Takes a hash of parameters representing the request.

=item * B<patch_dataset>

Calls the RPC method C<PatchDataset> on the service. Takes a hash of parameters representing the request.

=item * B<update_dataset>

Calls the RPC method C<UpdateDataset> on the service. Takes a hash of parameters representing the request.

=item * B<delete_dataset>

Calls the RPC method C<DeleteDataset> on the service. Takes a hash of parameters representing the request.

=item * B<list_datasets>

Calls the RPC method C<ListDatasets> on the service. Takes a hash of parameters representing the request.

=item * B<undelete_dataset>

Calls the RPC method C<UndeleteDataset> on the service. Takes a hash of parameters representing the request.

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
