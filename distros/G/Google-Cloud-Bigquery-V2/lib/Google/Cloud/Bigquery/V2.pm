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
use Google::Cloud::Bigquery::V2::Error;
use Google::Cloud::Bigquery::V2::Arrow;
use Google::Cloud::Bigquery::V2::ManagedTableType;
use Google::Cloud::Bigquery::V2::GenAiStats;
use Google::Cloud::Bigquery::V2::DecimalTargetTypes;
use Google::Cloud::Bigquery::V2::FileSetSpecificationType;
use Google::Cloud::Bigquery::V2::MapTargetType;
use Google::Cloud::Bigquery::V2::Clustering;
use Google::Cloud::Bigquery::V2::JsonExtension;
use Google::Cloud::Bigquery::V2::LocationMetadata;
use Google::Cloud::Bigquery::V2::UdfResource;
use Google::Cloud::Bigquery::V2::BiglakeConfig;
use Google::Cloud::Bigquery::V2::JobReference;
use Google::Cloud::Bigquery::V2::SessionInfo;
use Google::Cloud::Bigquery::V2::EncryptionConfig;
use Google::Cloud::Bigquery::V2::JobStatus;
use Google::Cloud::Bigquery::V2::TableReference;
use Google::Cloud::Bigquery::V2::DatasetReference;
use Google::Cloud::Bigquery::V2::DataFormatOptions;
use Google::Cloud::Bigquery::V2::RoutineReference;
use Google::Cloud::Bigquery::V2::StandardSql;
use Google::Cloud::Bigquery::V2::JobCreationReason;
use Google::Cloud::Bigquery::V2::PartitioningDefinition;
use Google::Cloud::Bigquery::V2::RestrictionConfig;
use Google::Cloud::Bigquery::V2::ExternalCatalogTableOptions;
use Google::Cloud::Bigquery::V2::ModelReference;
use Google::Cloud::Bigquery::V2::TableSchema;
use Google::Cloud::Bigquery::V2::HivePartitioning;
use Google::Cloud::Bigquery::V2::TimePartitioning;
use Google::Cloud::Bigquery::V2::RowAccessPolicyReference;
use Google::Cloud::Bigquery::V2::RangePartitioning;
use Google::Cloud::Bigquery::V2::ExternalCatalogDatasetOptions;
use Google::Cloud::Bigquery::V2::PrivacyPolicy;
use Google::Cloud::Bigquery::V2::PropertyGraphReference;
use Google::Cloud::Bigquery::V2::QueryParameter;
use Google::Cloud::Bigquery::V2::Project;
use Google::Cloud::Bigquery::V2::ExternalDatasetReference;
use Google::Cloud::Bigquery::V2::TableConstraints;
use Google::Cloud::Bigquery::V2::Routine;
use Google::Cloud::Bigquery::V2::SystemVariable;
use Google::Cloud::Bigquery::V2::Model;
use Google::Cloud::Bigquery::V2::ExternalDataConfig;
use Google::Cloud::Bigquery::V2::RowAccessPolicy;
use Google::Cloud::Bigquery::V2::Dataset;
use Google::Cloud::Bigquery::V2::JobStats;
use Google::Cloud::Bigquery::V2::JobConfig;
use Google::Cloud::Bigquery::V2::Table;
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

=item * B<cancel_job>

    my $response = $client->cancel_job(
        project_id               => $project_id,
        job_id                   => $job_id,
        location                 => $location,
    );

Calls the RPC method C<CancelJob> on C<google.cloud.bigquery.v2.JobService>.

Request: L<Google::Cloud::Bigquery::V2::Job::CancelJobRequest>

Returns: L<Google::Cloud::Bigquery::V2::Job::JobCancelResponse>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<job_id> - C<string>

=item * C<location> - C<string>

=back

=item * B<get_job>

    my $response = $client->get_job(
        project_id               => $project_id,
        job_id                   => $job_id,
        location                 => $location,
    );

Calls the RPC method C<GetJob> on C<google.cloud.bigquery.v2.JobService>.

Request: L<Google::Cloud::Bigquery::V2::Job::GetJobRequest>

Returns: L<Google::Cloud::Bigquery::V2::Job::Job>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<job_id> - C<string>

=item * C<location> - C<string>

=back

=item * B<insert_job>

    my $response = $client->insert_job(
        project_id               => $project_id,
        job                      => $job,
    );

Calls the RPC method C<InsertJob> on C<google.cloud.bigquery.v2.JobService>.

Request: L<Google::Cloud::Bigquery::V2::Job::InsertJobRequest>

Returns: L<Google::Cloud::Bigquery::V2::Job::Job>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<job> - L<Google::Cloud::Bigquery::V2::Job::Job>

=back

=item * B<delete_job>

    my $response = $client->delete_job(
        project_id               => $project_id,
        job_id                   => $job_id,
        location                 => $location,
    );

Calls the RPC method C<DeleteJob> on C<google.cloud.bigquery.v2.JobService>.

Request: L<Google::Cloud::Bigquery::V2::Job::DeleteJobRequest>

Returns: L<Google::Protobuf::Empty::Empty>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<job_id> - C<string>

=item * C<location> - C<string>

=back

=item * B<list_jobs>

    my $response = $client->list_jobs(
        project_id               => $project_id,
        all_users                => $all_users,
        max_results              => $max_results,
        min_creation_time        => $min_creation_time,
        max_creation_time        => $max_creation_time,
        page_token               => $page_token,
        projection               => $projection,
        state_filter             => [ ... ],
        parent_job_id            => $parent_job_id,
    );

Calls the RPC method C<ListJobs> on C<google.cloud.bigquery.v2.JobService>.

Request: L<Google::Cloud::Bigquery::V2::Job::ListJobsRequest>

Returns: L<Google::Cloud::Bigquery::V2::Job::JobList>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<all_users> - C<bool>

=item * C<max_results> - L<Google::Protobuf::Int32Value::Int32Value>

=item * C<min_creation_time> - C<uint64>

=item * C<max_creation_time> - L<Google::Protobuf::UInt64Value::UInt64Value>

=item * C<page_token> - C<string>

=item * C<projection> - L<Google::Cloud::Bigquery::V2::Job::Projection>

=item * C<state_filter> - ArrayRef of L<Google::Cloud::Bigquery::V2::Job::StateFilter>

=item * C<parent_job_id> - C<string>

=back

=item * B<get_query_results>

    my $response = $client->get_query_results(
        project_id               => $project_id,
        job_id                   => $job_id,
        start_index              => $start_index,
        page_token               => $page_token,
        max_results              => $max_results,
        timeout_ms               => $timeout_ms,
        location                 => $location,
        format_options           => $format_options,
    );

Calls the RPC method C<GetQueryResults> on C<google.cloud.bigquery.v2.JobService>.

Request: L<Google::Cloud::Bigquery::V2::Job::GetQueryResultsRequest>

Returns: L<Google::Cloud::Bigquery::V2::Job::GetQueryResultsResponse>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<job_id> - C<string>

=item * C<start_index> - L<Google::Protobuf::UInt64Value::UInt64Value>

=item * C<page_token> - C<string>

=item * C<max_results> - L<Google::Protobuf::UInt32Value::UInt32Value>

=item * C<timeout_ms> - L<Google::Protobuf::UInt32Value::UInt32Value>

=item * C<location> - C<string>

=item * C<format_options> - L<Google::Cloud::Bigquery::V2::DataFormatOptions::DataFormatOptions>

=back

=item * B<query>

    my $response = $client->query(
        project_id               => $project_id,
        query_request            => $query_request,
    );

Calls the RPC method C<Query> on C<google.cloud.bigquery.v2.JobService>.

Request: L<Google::Cloud::Bigquery::V2::Job::PostQueryRequest>

Returns: L<Google::Cloud::Bigquery::V2::Job::QueryResponse>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<query_request> - L<Google::Cloud::Bigquery::V2::Job::QueryRequest>

=back

=item * B<get_model>

    my $response = $client->get_model(
        project_id               => $project_id,
        dataset_id               => $dataset_id,
        model_id                 => $model_id,
    );

Calls the RPC method C<GetModel> on C<google.cloud.bigquery.v2.ModelService>.

Request: L<Google::Cloud::Bigquery::V2::Model::GetModelRequest>

Returns: L<Google::Cloud::Bigquery::V2::Model::Model>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<dataset_id> - C<string>

=item * C<model_id> - C<string>

=back

=item * B<list_models>

    my $response = $client->list_models(
        project_id               => $project_id,
        dataset_id               => $dataset_id,
        max_results              => $max_results,
        page_token               => $page_token,
    );

Calls the RPC method C<ListModels> on C<google.cloud.bigquery.v2.ModelService>.

Request: L<Google::Cloud::Bigquery::V2::Model::ListModelsRequest>

Returns: L<Google::Cloud::Bigquery::V2::Model::ListModelsResponse>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<dataset_id> - C<string>

=item * C<max_results> - L<Google::Protobuf::UInt32Value::UInt32Value>

=item * C<page_token> - C<string>

=back

=item * B<patch_model>

    my $response = $client->patch_model(
        project_id               => $project_id,
        dataset_id               => $dataset_id,
        model_id                 => $model_id,
        model                    => $model,
    );

Calls the RPC method C<PatchModel> on C<google.cloud.bigquery.v2.ModelService>.

Request: L<Google::Cloud::Bigquery::V2::Model::PatchModelRequest>

Returns: L<Google::Cloud::Bigquery::V2::Model::Model>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<dataset_id> - C<string>

=item * C<model_id> - C<string>

=item * C<model> - L<Google::Cloud::Bigquery::V2::Model::Model>

=back

=item * B<delete_model>

    my $response = $client->delete_model(
        project_id               => $project_id,
        dataset_id               => $dataset_id,
        model_id                 => $model_id,
    );

Calls the RPC method C<DeleteModel> on C<google.cloud.bigquery.v2.ModelService>.

Request: L<Google::Cloud::Bigquery::V2::Model::DeleteModelRequest>

Returns: L<Google::Protobuf::Empty::Empty>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<dataset_id> - C<string>

=item * C<model_id> - C<string>

=back

=item * B<get_service_account>

    my $response = $client->get_service_account(
        project_id               => $project_id,
    );

Calls the RPC method C<GetServiceAccount> on C<google.cloud.bigquery.v2.ProjectService>.

Request: L<Google::Cloud::Bigquery::V2::Project::GetServiceAccountRequest>

Returns: L<Google::Cloud::Bigquery::V2::Project::GetServiceAccountResponse>

Parameters:

=over 4

=item * C<project_id> - C<string>

=back

=item * B<get_routine>

    my $response = $client->get_routine(
        project_id               => $project_id,
        dataset_id               => $dataset_id,
        routine_id               => $routine_id,
    );

Calls the RPC method C<GetRoutine> on C<google.cloud.bigquery.v2.RoutineService>.

Request: L<Google::Cloud::Bigquery::V2::Routine::GetRoutineRequest>

Returns: L<Google::Cloud::Bigquery::V2::Routine::Routine>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<dataset_id> - C<string>

=item * C<routine_id> - C<string>

=back

=item * B<insert_routine>

    my $response = $client->insert_routine(
        project_id               => $project_id,
        dataset_id               => $dataset_id,
        routine                  => $routine,
    );

Calls the RPC method C<InsertRoutine> on C<google.cloud.bigquery.v2.RoutineService>.

Request: L<Google::Cloud::Bigquery::V2::Routine::InsertRoutineRequest>

Returns: L<Google::Cloud::Bigquery::V2::Routine::Routine>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<dataset_id> - C<string>

=item * C<routine> - L<Google::Cloud::Bigquery::V2::Routine::Routine>

=back

=item * B<update_routine>

    my $response = $client->update_routine(
        project_id               => $project_id,
        dataset_id               => $dataset_id,
        routine_id               => $routine_id,
        routine                  => $routine,
    );

Calls the RPC method C<UpdateRoutine> on C<google.cloud.bigquery.v2.RoutineService>.

Request: L<Google::Cloud::Bigquery::V2::Routine::UpdateRoutineRequest>

Returns: L<Google::Cloud::Bigquery::V2::Routine::Routine>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<dataset_id> - C<string>

=item * C<routine_id> - C<string>

=item * C<routine> - L<Google::Cloud::Bigquery::V2::Routine::Routine>

=back

=item * B<delete_routine>

    my $response = $client->delete_routine(
        project_id               => $project_id,
        dataset_id               => $dataset_id,
        routine_id               => $routine_id,
    );

Calls the RPC method C<DeleteRoutine> on C<google.cloud.bigquery.v2.RoutineService>.

Request: L<Google::Cloud::Bigquery::V2::Routine::DeleteRoutineRequest>

Returns: L<Google::Protobuf::Empty::Empty>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<dataset_id> - C<string>

=item * C<routine_id> - C<string>

=back

=item * B<list_routines>

    my $response = $client->list_routines(
        project_id               => $project_id,
        dataset_id               => $dataset_id,
        max_results              => $max_results,
        page_token               => $page_token,
        filter                   => $filter,
    );

Calls the RPC method C<ListRoutines> on C<google.cloud.bigquery.v2.RoutineService>.

Request: L<Google::Cloud::Bigquery::V2::Routine::ListRoutinesRequest>

Returns: L<Google::Cloud::Bigquery::V2::Routine::ListRoutinesResponse>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<dataset_id> - C<string>

=item * C<max_results> - L<Google::Protobuf::UInt32Value::UInt32Value>

=item * C<page_token> - C<string>

=item * C<filter> - C<string>

=back

=item * B<list_row_access_policies>

    my $response = $client->list_row_access_policies(
        project_id               => $project_id,
        dataset_id               => $dataset_id,
        table_id                 => $table_id,
        page_token               => $page_token,
        page_size                => $page_size,
    );

Calls the RPC method C<ListRowAccessPolicies> on C<google.cloud.bigquery.v2.RowAccessPolicyService>.

Request: L<Google::Cloud::Bigquery::V2::RowAccessPolicy::ListRowAccessPoliciesRequest>

Returns: L<Google::Cloud::Bigquery::V2::RowAccessPolicy::ListRowAccessPoliciesResponse>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<dataset_id> - C<string>

=item * C<table_id> - C<string>

=item * C<page_token> - C<string>

=item * C<page_size> - C<int32>

=back

=item * B<get_row_access_policy>

    my $response = $client->get_row_access_policy(
        project_id               => $project_id,
        dataset_id               => $dataset_id,
        table_id                 => $table_id,
        policy_id                => $policy_id,
    );

Calls the RPC method C<GetRowAccessPolicy> on C<google.cloud.bigquery.v2.RowAccessPolicyService>.

Request: L<Google::Cloud::Bigquery::V2::RowAccessPolicy::GetRowAccessPolicyRequest>

Returns: L<Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<dataset_id> - C<string>

=item * C<table_id> - C<string>

=item * C<policy_id> - C<string>

=back

=item * B<create_row_access_policy>

    my $response = $client->create_row_access_policy(
        project_id               => $project_id,
        dataset_id               => $dataset_id,
        table_id                 => $table_id,
        row_access_policy        => $row_access_policy,
    );

Calls the RPC method C<CreateRowAccessPolicy> on C<google.cloud.bigquery.v2.RowAccessPolicyService>.

Request: L<Google::Cloud::Bigquery::V2::RowAccessPolicy::CreateRowAccessPolicyRequest>

Returns: L<Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<dataset_id> - C<string>

=item * C<table_id> - C<string>

=item * C<row_access_policy> - L<Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy>

=back

=item * B<update_row_access_policy>

    my $response = $client->update_row_access_policy(
        project_id               => $project_id,
        dataset_id               => $dataset_id,
        table_id                 => $table_id,
        policy_id                => $policy_id,
        row_access_policy        => $row_access_policy,
    );

Calls the RPC method C<UpdateRowAccessPolicy> on C<google.cloud.bigquery.v2.RowAccessPolicyService>.

Request: L<Google::Cloud::Bigquery::V2::RowAccessPolicy::UpdateRowAccessPolicyRequest>

Returns: L<Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<dataset_id> - C<string>

=item * C<table_id> - C<string>

=item * C<policy_id> - C<string>

=item * C<row_access_policy> - L<Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy>

=back

=item * B<delete_row_access_policy>

    my $response = $client->delete_row_access_policy(
        project_id               => $project_id,
        dataset_id               => $dataset_id,
        table_id                 => $table_id,
        policy_id                => $policy_id,
        force                    => $force,
    );

Calls the RPC method C<DeleteRowAccessPolicy> on C<google.cloud.bigquery.v2.RowAccessPolicyService>.

Request: L<Google::Cloud::Bigquery::V2::RowAccessPolicy::DeleteRowAccessPolicyRequest>

Returns: L<Google::Protobuf::Empty::Empty>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<dataset_id> - C<string>

=item * C<table_id> - C<string>

=item * C<policy_id> - C<string>

=item * C<force> - C<bool>

=back

=item * B<batch_delete_row_access_policies>

    my $response = $client->batch_delete_row_access_policies(
        project_id               => $project_id,
        dataset_id               => $dataset_id,
        table_id                 => $table_id,
        policy_ids               => [ ... ],
        force                    => $force,
    );

Calls the RPC method C<BatchDeleteRowAccessPolicies> on C<google.cloud.bigquery.v2.RowAccessPolicyService>.

Request: L<Google::Cloud::Bigquery::V2::RowAccessPolicy::BatchDeleteRowAccessPoliciesRequest>

Returns: L<Google::Protobuf::Empty::Empty>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<dataset_id> - C<string>

=item * C<table_id> - C<string>

=item * C<policy_ids> - ArrayRef of C<string>

=item * C<force> - C<bool>

=back

=item * B<get_table>

    my $response = $client->get_table(
        project_id               => $project_id,
        dataset_id               => $dataset_id,
        table_id                 => $table_id,
        selected_fields          => $selected_fields,
        view                     => $view,
    );

Calls the RPC method C<GetTable> on C<google.cloud.bigquery.v2.TableService>.

Request: L<Google::Cloud::Bigquery::V2::Table::GetTableRequest>

Returns: L<Google::Cloud::Bigquery::V2::Table::Table>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<dataset_id> - C<string>

=item * C<table_id> - C<string>

=item * C<selected_fields> - C<string>

=item * C<view> - L<Google::Cloud::Bigquery::V2::Table::TableMetadataView>

=back

=item * B<insert_table>

    my $response = $client->insert_table(
        project_id               => $project_id,
        dataset_id               => $dataset_id,
        table                    => $table,
    );

Calls the RPC method C<InsertTable> on C<google.cloud.bigquery.v2.TableService>.

Request: L<Google::Cloud::Bigquery::V2::Table::InsertTableRequest>

Returns: L<Google::Cloud::Bigquery::V2::Table::Table>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<dataset_id> - C<string>

=item * C<table> - L<Google::Cloud::Bigquery::V2::Table::Table>

=back

=item * B<patch_table>

    my $response = $client->patch_table(
        project_id               => $project_id,
        dataset_id               => $dataset_id,
        table_id                 => $table_id,
        table                    => $table,
        autodetect_schema        => $autodetect_schema,
    );

Calls the RPC method C<PatchTable> on C<google.cloud.bigquery.v2.TableService>.

Request: L<Google::Cloud::Bigquery::V2::Table::UpdateOrPatchTableRequest>

Returns: L<Google::Cloud::Bigquery::V2::Table::Table>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<dataset_id> - C<string>

=item * C<table_id> - C<string>

=item * C<table> - L<Google::Cloud::Bigquery::V2::Table::Table>

=item * C<autodetect_schema> - C<bool>

=back

=item * B<update_table>

    my $response = $client->update_table(
        project_id               => $project_id,
        dataset_id               => $dataset_id,
        table_id                 => $table_id,
        table                    => $table,
        autodetect_schema        => $autodetect_schema,
    );

Calls the RPC method C<UpdateTable> on C<google.cloud.bigquery.v2.TableService>.

Request: L<Google::Cloud::Bigquery::V2::Table::UpdateOrPatchTableRequest>

Returns: L<Google::Cloud::Bigquery::V2::Table::Table>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<dataset_id> - C<string>

=item * C<table_id> - C<string>

=item * C<table> - L<Google::Cloud::Bigquery::V2::Table::Table>

=item * C<autodetect_schema> - C<bool>

=back

=item * B<delete_table>

    my $response = $client->delete_table(
        project_id               => $project_id,
        dataset_id               => $dataset_id,
        table_id                 => $table_id,
    );

Calls the RPC method C<DeleteTable> on C<google.cloud.bigquery.v2.TableService>.

Request: L<Google::Cloud::Bigquery::V2::Table::DeleteTableRequest>

Returns: L<Google::Protobuf::Empty::Empty>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<dataset_id> - C<string>

=item * C<table_id> - C<string>

=back

=item * B<list_tables>

    my $response = $client->list_tables(
        project_id               => $project_id,
        dataset_id               => $dataset_id,
        max_results              => $max_results,
        page_token               => $page_token,
    );

Calls the RPC method C<ListTables> on C<google.cloud.bigquery.v2.TableService>.

Request: L<Google::Cloud::Bigquery::V2::Table::ListTablesRequest>

Returns: L<Google::Cloud::Bigquery::V2::Table::TableList>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<dataset_id> - C<string>

=item * C<max_results> - L<Google::Protobuf::UInt32Value::UInt32Value>

=item * C<page_token> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
