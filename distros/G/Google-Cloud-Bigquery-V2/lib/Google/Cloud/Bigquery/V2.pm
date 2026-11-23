package Google::Cloud::Bigquery::V2;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Bigquery::V2::FileSetSpecificationType;
use Google::Cloud::Bigquery::V2::JsonExtension;
use Google::Cloud::Bigquery::V2::Clustering;
use Google::Cloud::Bigquery::V2::Error;
use Google::Cloud::Bigquery::V2::MapTargetType;
use Google::Cloud::Bigquery::V2::ManagedTableType;
use Google::Cloud::Bigquery::V2::LocationMetadata;
use Google::Cloud::Bigquery::V2::GenAiStats;
use Google::Cloud::Bigquery::V2::Arrow;
use Google::Cloud::Bigquery::V2::DecimalTargetTypes;
use Google::Cloud::Bigquery::V2::UdfResource;
use Google::Cloud::Bigquery::V2::QueryParameter;
use Google::Cloud::Bigquery::V2::SessionInfo;
use Google::Cloud::Bigquery::V2::RowAccessPolicyReference;
use Google::Cloud::Bigquery::V2::RoutineReference;
use Google::Cloud::Bigquery::V2::JobCreationReason;
use Google::Cloud::Bigquery::V2::TableSchema;
use Google::Cloud::Bigquery::V2::JobReference;
use Google::Cloud::Bigquery::V2::ExternalDatasetReference;
use Google::Cloud::Bigquery::V2::RestrictionConfig;
use Google::Cloud::Bigquery::V2::PrivacyPolicy;
use Google::Cloud::Bigquery::V2::TimePartitioning;
use Google::Cloud::Bigquery::V2::PartitioningDefinition;
use Google::Cloud::Bigquery::V2::ExternalCatalogTableOptions;
use Google::Cloud::Bigquery::V2::PropertyGraphReference;
use Google::Cloud::Bigquery::V2::DataFormatOptions;
use Google::Cloud::Bigquery::V2::StandardSql;
use Google::Cloud::Bigquery::V2::HivePartitioning;
use Google::Cloud::Bigquery::V2::EncryptionConfig;
use Google::Cloud::Bigquery::V2::ExternalCatalogDatasetOptions;
use Google::Cloud::Bigquery::V2::ModelReference;
use Google::Cloud::Bigquery::V2::BiglakeConfig;
use Google::Cloud::Bigquery::V2::JobStatus;
use Google::Cloud::Bigquery::V2::TableReference;
use Google::Cloud::Bigquery::V2::DatasetReference;
use Google::Cloud::Bigquery::V2::RangePartitioning;
use Google::Cloud::Bigquery::V2::Project;
use Google::Cloud::Bigquery::V2::RowAccessPolicy;
use Google::Cloud::Bigquery::V2::Routine;
use Google::Cloud::Bigquery::V2::SystemVariable;
use Google::Cloud::Bigquery::V2::ExternalDataConfig;
use Google::Cloud::Bigquery::V2::TableConstraints;
use Google::Cloud::Bigquery::V2::Model;
use Google::Cloud::Bigquery::V2::Dataset;
use Google::Cloud::Bigquery::V2::JobConfig;
use Google::Cloud::Bigquery::V2::Table;
use Google::Cloud::Bigquery::V2::JobStats;
use Google::Cloud::Bigquery::V2::Job;

our $VERSION = '0.05';

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

sub cancel_job {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Job::CancelJobRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Bigquery::V2::Job::JobCancelResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.bigquery.v2.JobService/CancelJob',
            request        => $request,
            response_class => $response_class,
        });
    }

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
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Bigquery::V2::Job::Job';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.bigquery.v2.JobService/GetJob',
            request        => $request,
            response_class => $response_class,
        });
    }

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
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Bigquery::V2::Job::Job';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.bigquery.v2.JobService/InsertJob',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.JobService',
        method         => 'InsertJob',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_job {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Job::DeleteJobRequest';
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
            path           => '/google.cloud.bigquery.v2.JobService/DeleteJob',
            request        => $request,
            response_class => $response_class,
        });
    }

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
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Bigquery::V2::Job::JobList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.bigquery.v2.JobService/ListJobs',
            request        => $request,
            response_class => $response_class,
        });
    }

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
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Bigquery::V2::Job::GetQueryResultsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.bigquery.v2.JobService/GetQueryResults',
            request        => $request,
            response_class => $response_class,
        });
    }

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
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Bigquery::V2::Job::QueryResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.bigquery.v2.JobService/Query',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.JobService',
        method         => 'Query',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_model {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Model::GetModelRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Bigquery::V2::Model::Model';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.bigquery.v2.ModelService/GetModel',
            request        => $request,
            response_class => $response_class,
        });
    }

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
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Bigquery::V2::Model::ListModelsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.bigquery.v2.ModelService/ListModels',
            request        => $request,
            response_class => $response_class,
        });
    }

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
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Bigquery::V2::Model::Model';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.bigquery.v2.ModelService/PatchModel',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.bigquery.v2.ModelService/DeleteModel',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.ModelService',
        method         => 'DeleteModel',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_service_account {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Project::GetServiceAccountRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Bigquery::V2::Project::GetServiceAccountResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.bigquery.v2.ProjectService/GetServiceAccount',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.ProjectService',
        method         => 'GetServiceAccount',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_routine {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Routine::GetRoutineRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Bigquery::V2::Routine::Routine';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.bigquery.v2.RoutineService/GetRoutine',
            request        => $request,
            response_class => $response_class,
        });
    }

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
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Bigquery::V2::Routine::Routine';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.bigquery.v2.RoutineService/InsertRoutine',
            request        => $request,
            response_class => $response_class,
        });
    }

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
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Bigquery::V2::Routine::Routine';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.bigquery.v2.RoutineService/UpdateRoutine',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.RoutineService',
        method         => 'UpdateRoutine',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_routine {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Routine::DeleteRoutineRequest';
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
            path           => '/google.cloud.bigquery.v2.RoutineService/DeleteRoutine',
            request        => $request,
            response_class => $response_class,
        });
    }

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
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Bigquery::V2::Routine::ListRoutinesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.bigquery.v2.RoutineService/ListRoutines',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.RoutineService',
        method         => 'ListRoutines',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_row_access_policies {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::RowAccessPolicy::ListRowAccessPoliciesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Bigquery::V2::RowAccessPolicy::ListRowAccessPoliciesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.bigquery.v2.RowAccessPolicyService/ListRowAccessPolicies',
            request        => $request,
            response_class => $response_class,
        });
    }

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
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.bigquery.v2.RowAccessPolicyService/GetRowAccessPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

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
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.bigquery.v2.RowAccessPolicyService/CreateRowAccessPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

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
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.bigquery.v2.RowAccessPolicyService/UpdateRowAccessPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.bigquery.v2.RowAccessPolicyService/DeleteRowAccessPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.bigquery.v2.RowAccessPolicyService/BatchDeleteRowAccessPolicies',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.RowAccessPolicyService',
        method         => 'BatchDeleteRowAccessPolicies',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_table {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Bigquery::V2::Table::GetTableRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Bigquery::V2::Table::Table';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.bigquery.v2.TableService/GetTable',
            request        => $request,
            response_class => $response_class,
        });
    }

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
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Bigquery::V2::Table::Table';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.bigquery.v2.TableService/InsertTable',
            request        => $request,
            response_class => $response_class,
        });
    }

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
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Bigquery::V2::Table::Table';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.bigquery.v2.TableService/PatchTable',
            request        => $request,
            response_class => $response_class,
        });
    }

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
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Bigquery::V2::Table::Table';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.bigquery.v2.TableService/UpdateTable',
            request        => $request,
            response_class => $response_class,
        });
    }

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
            path           => '/google.cloud.bigquery.v2.TableService/DeleteTable',
            request        => $request,
            response_class => $response_class,
        });
    }

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
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Bigquery::V2::Table::TableList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.bigquery.v2.TableService/ListTables',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.bigquery.v2.TableService',
        method         => 'ListTables',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Bigquery::V2

__END__

=head1 NAME

Google::Cloud::Bigquery::V2 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::V2;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Bigquery::V2->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Bigquery::V2->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Bigquery::V2> is an auto-generated client library for Google Cloud Services.

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

=item * C<googleapis/google/cloud/bigquery/v2/job_config.proto>

=item * C<googleapis/google/cloud/bigquery/v2/job_creation_reason.proto>

=item * C<googleapis/google/cloud/bigquery/v2/job.proto>

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

=item * C<googleapis/google/cloud/bigquery/v2/table_constraints.proto>

=item * C<googleapis/google/cloud/bigquery/v2/table.proto>

=item * C<googleapis/google/cloud/bigquery/v2/table_reference.proto>

=item * C<googleapis/google/cloud/bigquery/v2/table_schema.proto>

=item * C<googleapis/google/cloud/bigquery/v2/time_partitioning.proto>

=item * C<googleapis/google/cloud/bigquery/v2/udf_resource.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Bigquery::V2->new(
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

=item * B<cancel_job>

Calls the RPC method C<CancelJob> on the service. Takes a hash of parameters representing the request.

=item * B<get_job>

Calls the RPC method C<GetJob> on the service. Takes a hash of parameters representing the request.

=item * B<insert_job>

Calls the RPC method C<InsertJob> on the service. Takes a hash of parameters representing the request.

=item * B<delete_job>

Calls the RPC method C<DeleteJob> on the service. Takes a hash of parameters representing the request.

=item * B<list_jobs>

Calls the RPC method C<ListJobs> on the service. Takes a hash of parameters representing the request.

=item * B<get_query_results>

Calls the RPC method C<GetQueryResults> on the service. Takes a hash of parameters representing the request.

=item * B<query>

Calls the RPC method C<Query> on the service. Takes a hash of parameters representing the request.

=item * B<get_model>

Calls the RPC method C<GetModel> on the service. Takes a hash of parameters representing the request.

=item * B<list_models>

Calls the RPC method C<ListModels> on the service. Takes a hash of parameters representing the request.

=item * B<patch_model>

Calls the RPC method C<PatchModel> on the service. Takes a hash of parameters representing the request.

=item * B<delete_model>

Calls the RPC method C<DeleteModel> on the service. Takes a hash of parameters representing the request.

=item * B<get_service_account>

Calls the RPC method C<GetServiceAccount> on the service. Takes a hash of parameters representing the request.

=item * B<get_routine>

Calls the RPC method C<GetRoutine> on the service. Takes a hash of parameters representing the request.

=item * B<insert_routine>

Calls the RPC method C<InsertRoutine> on the service. Takes a hash of parameters representing the request.

=item * B<update_routine>

Calls the RPC method C<UpdateRoutine> on the service. Takes a hash of parameters representing the request.

=item * B<delete_routine>

Calls the RPC method C<DeleteRoutine> on the service. Takes a hash of parameters representing the request.

=item * B<list_routines>

Calls the RPC method C<ListRoutines> on the service. Takes a hash of parameters representing the request.

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

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
