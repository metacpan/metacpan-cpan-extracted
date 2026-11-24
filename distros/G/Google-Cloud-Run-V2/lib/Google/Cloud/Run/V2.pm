package Google::Cloud::Run::V2;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Run::V2::Status;
use Google::Cloud::Run::V2::ContainerStatus;
use Google::Cloud::Run::V2::TrafficTarget;
use Google::Cloud::Run::V2::VendorSettings;
use Google::Cloud::Run::V2::K8sMin;
use Google::Cloud::Run::V2::InstanceSplit;
use Google::Cloud::Run::V2::Build;
use Google::Cloud::Run::V2::Condition;
use Google::Cloud::Run::V2::SourceUpload;
use Google::Cloud::Run::V2::Sandbox;
use Google::Cloud::Run::V2::Instance;
use Google::Cloud::Run::V2::Task;
use Google::Cloud::Run::V2::RevisionTemplate;
use Google::Cloud::Run::V2::WorkerPoolRevisionTemplate;
use Google::Cloud::Run::V2::Revision;
use Google::Cloud::Run::V2::TaskTemplate;
use Google::Cloud::Run::V2::Service;
use Google::Cloud::Run::V2::WorkerPool;
use Google::Cloud::Run::V2::Execution;
use Google::Cloud::Run::V2::ExecutionTemplate;
use Google::Cloud::Run::V2::Job;

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

    my $target = 'run.googleapis.com:443';
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

sub submit_build {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Run::V2::Build::SubmitBuildRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Run::V2::Build::SubmitBuildResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.run.v2.Builds/SubmitBuild',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.run.v2.Builds',
        method         => 'SubmitBuild',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_execution {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Run::V2::Execution::GetExecutionRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Run::V2::Execution::Execution';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.run.v2.Executions/GetExecution',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.run.v2.Executions',
        method         => 'GetExecution',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_instance {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Run::V2::Instance::CreateInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Longrunning::Operations::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.run.v2.Instances/CreateInstance',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.run.v2.Instances',
        method         => 'CreateInstance',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_instance {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Run::V2::Instance::UpdateInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Longrunning::Operations::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.run.v2.Instances/UpdateInstance',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.run.v2.Instances',
        method         => 'UpdateInstance',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub stop_instance {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Run::V2::Instance::StopInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Longrunning::Operations::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.run.v2.Instances/StopInstance',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.run.v2.Instances',
        method         => 'StopInstance',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_job {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Run::V2::Job::CreateJobRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Longrunning::Operations::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.run.v2.Jobs/CreateJob',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.run.v2.Jobs',
        method         => 'CreateJob',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_job {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Run::V2::Job::GetJobRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Run::V2::Job::Job';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.run.v2.Jobs/GetJob',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.run.v2.Jobs',
        method         => 'GetJob',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_job {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Run::V2::Job::UpdateJobRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Longrunning::Operations::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.run.v2.Jobs/UpdateJob',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.run.v2.Jobs',
        method         => 'UpdateJob',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_revision {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Run::V2::Revision::GetRevisionRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Run::V2::Revision::Revision';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.run.v2.Revisions/GetRevision',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.run.v2.Revisions',
        method         => 'GetRevision',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_service {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Run::V2::Service::CreateServiceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Longrunning::Operations::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.run.v2.Services/CreateService',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.run.v2.Services',
        method         => 'CreateService',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_service {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Run::V2::Service::GetServiceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Run::V2::Service::Service';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.run.v2.Services/GetService',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.run.v2.Services',
        method         => 'GetService',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_service {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Run::V2::Service::UpdateServiceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Longrunning::Operations::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.run.v2.Services/UpdateService',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.run.v2.Services',
        method         => 'UpdateService',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub upload_source {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Run::V2::SourceUpload::UploadSourceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Run::V2::SourceUpload::UploadSourceResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.run.v2.SourceUpload/UploadSource',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.run.v2.SourceUpload',
        method         => 'UploadSource',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_task {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Run::V2::Task::GetTaskRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Run::V2::Task::Task';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.run.v2.Tasks/GetTask',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.run.v2.Tasks',
        method         => 'GetTask',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_worker_pool {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Run::V2::WorkerPool::CreateWorkerPoolRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Longrunning::Operations::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.run.v2.WorkerPools/CreateWorkerPool',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.run.v2.WorkerPools',
        method         => 'CreateWorkerPool',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_worker_pool {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Run::V2::WorkerPool::GetWorkerPoolRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Run::V2::WorkerPool::WorkerPool';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.run.v2.WorkerPools/GetWorkerPool',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.run.v2.WorkerPools',
        method         => 'GetWorkerPool',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_worker_pool {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Run::V2::WorkerPool::UpdateWorkerPoolRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Longrunning::Operations::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.run.v2.WorkerPools/UpdateWorkerPool',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.run.v2.WorkerPools',
        method         => 'UpdateWorkerPool',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Run::V2

__END__

=head1 NAME

Google::Cloud::Run::V2 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Run::V2;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Run::V2->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Run::V2->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Run::V2> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/run/v2/build.proto>

=item * C<googleapis/google/cloud/run/v2/condition.proto>

=item * C<googleapis/google/cloud/run/v2/container_status.proto>

=item * C<googleapis/google/cloud/run/v2/execution.proto>

=item * C<googleapis/google/cloud/run/v2/execution_template.proto>

=item * C<googleapis/google/cloud/run/v2/instance.proto>

=item * C<googleapis/google/cloud/run/v2/instance_split.proto>

=item * C<googleapis/google/cloud/run/v2/job.proto>

=item * C<googleapis/google/cloud/run/v2/k8s.min.proto>

=item * C<googleapis/google/cloud/run/v2/revision.proto>

=item * C<googleapis/google/cloud/run/v2/revision_template.proto>

=item * C<googleapis/google/cloud/run/v2/sandbox.proto>

=item * C<googleapis/google/cloud/run/v2/service.proto>

=item * C<googleapis/google/cloud/run/v2/source_upload.proto>

=item * C<googleapis/google/cloud/run/v2/status.proto>

=item * C<googleapis/google/cloud/run/v2/task.proto>

=item * C<googleapis/google/cloud/run/v2/task_template.proto>

=item * C<googleapis/google/cloud/run/v2/traffic_target.proto>

=item * C<googleapis/google/cloud/run/v2/vendor_settings.proto>

=item * C<googleapis/google/cloud/run/v2/worker_pool.proto>

=item * C<googleapis/google/cloud/run/v2/worker_pool_revision_template.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Run::V2->new(
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

=item * B<submit_build>

    my $response = $client->submit_build(
        parent                   => $parent,
        image_uri                => $image_uri,
        service_account          => $service_account,
        worker_pool              => $worker_pool,
        tags                     => [ ... ],
        machine_type             => $machine_type,
        release_track            => $release_track,
        client                   => $client,
    );

Calls the RPC method C<SubmitBuild> on C<google.cloud.run.v2.Builds>.

Request: L<Google::Cloud::Run::V2::Build::SubmitBuildRequest>

Returns: L<Google::Cloud::Run::V2::Build::SubmitBuildResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<image_uri> - C<string>

=item * C<service_account> - C<string>

=item * C<worker_pool> - C<string>

=item * C<tags> - ArrayRef of C<string>

=item * C<machine_type> - C<string>

=item * C<release_track> - L<Google::Api::LaunchStage::LaunchStage>

=item * C<client> - C<string>

=back

=item * B<get_execution>

    my $response = $client->get_execution(
        name                     => $name,
    );

Calls the RPC method C<GetExecution> on C<google.cloud.run.v2.Executions>.

Request: L<Google::Cloud::Run::V2::Execution::GetExecutionRequest>

Returns: L<Google::Cloud::Run::V2::Execution::Execution>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<create_instance>

    my $response = $client->create_instance(
        parent                   => $parent,
        instance                 => $instance,
        instance_id              => $instance_id,
        validate_only            => $validate_only,
    );

Calls the RPC method C<CreateInstance> on C<google.cloud.run.v2.Instances>.

Request: L<Google::Cloud::Run::V2::Instance::CreateInstanceRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<instance> - L<Google::Cloud::Run::V2::Instance::Instance>

=item * C<instance_id> - C<string>

=item * C<validate_only> - C<bool>

=back

=item * B<update_instance>

    my $response = $client->update_instance(
        update_mask              => $update_mask,
        instance                 => $instance,
        validate_only            => $validate_only,
        allow_missing            => $allow_missing,
    );

Calls the RPC method C<UpdateInstance> on C<google.cloud.run.v2.Instances>.

Request: L<Google::Cloud::Run::V2::Instance::UpdateInstanceRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=item * C<instance> - L<Google::Cloud::Run::V2::Instance::Instance>

=item * C<validate_only> - C<bool>

=item * C<allow_missing> - C<bool>

=back

=item * B<stop_instance>

    my $response = $client->stop_instance(
        name                     => $name,
        validate_only            => $validate_only,
        etag                     => $etag,
    );

Calls the RPC method C<StopInstance> on C<google.cloud.run.v2.Instances>.

Request: L<Google::Cloud::Run::V2::Instance::StopInstanceRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<validate_only> - C<bool>

=item * C<etag> - C<string>

=back

=item * B<create_job>

    my $response = $client->create_job(
        parent                   => $parent,
        job                      => $job,
        job_id                   => $job_id,
        validate_only            => $validate_only,
    );

Calls the RPC method C<CreateJob> on C<google.cloud.run.v2.Jobs>.

Request: L<Google::Cloud::Run::V2::Job::CreateJobRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<job> - L<Google::Cloud::Run::V2::Job::Job>

=item * C<job_id> - C<string>

=item * C<validate_only> - C<bool>

=back

=item * B<get_job>

    my $response = $client->get_job(
        name                     => $name,
    );

Calls the RPC method C<GetJob> on C<google.cloud.run.v2.Jobs>.

Request: L<Google::Cloud::Run::V2::Job::GetJobRequest>

Returns: L<Google::Cloud::Run::V2::Job::Job>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<update_job>

    my $response = $client->update_job(
        job                      => $job,
        validate_only            => $validate_only,
        allow_missing            => $allow_missing,
    );

Calls the RPC method C<UpdateJob> on C<google.cloud.run.v2.Jobs>.

Request: L<Google::Cloud::Run::V2::Job::UpdateJobRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<job> - L<Google::Cloud::Run::V2::Job::Job>

=item * C<validate_only> - C<bool>

=item * C<allow_missing> - C<bool>

=back

=item * B<get_revision>

    my $response = $client->get_revision(
        name                     => $name,
    );

Calls the RPC method C<GetRevision> on C<google.cloud.run.v2.Revisions>.

Request: L<Google::Cloud::Run::V2::Revision::GetRevisionRequest>

Returns: L<Google::Cloud::Run::V2::Revision::Revision>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<create_service>

    my $response = $client->create_service(
        parent                   => $parent,
        service                  => $service,
        service_id               => $service_id,
        validate_only            => $validate_only,
    );

Calls the RPC method C<CreateService> on C<google.cloud.run.v2.Services>.

Request: L<Google::Cloud::Run::V2::Service::CreateServiceRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<service> - L<Google::Cloud::Run::V2::Service::Service>

=item * C<service_id> - C<string>

=item * C<validate_only> - C<bool>

=back

=item * B<get_service>

    my $response = $client->get_service(
        name                     => $name,
    );

Calls the RPC method C<GetService> on C<google.cloud.run.v2.Services>.

Request: L<Google::Cloud::Run::V2::Service::GetServiceRequest>

Returns: L<Google::Cloud::Run::V2::Service::Service>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<update_service>

    my $response = $client->update_service(
        update_mask              => $update_mask,
        service                  => $service,
        validate_only            => $validate_only,
        allow_missing            => $allow_missing,
        force_new_revision       => $force_new_revision,
    );

Calls the RPC method C<UpdateService> on C<google.cloud.run.v2.Services>.

Request: L<Google::Cloud::Run::V2::Service::UpdateServiceRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=item * C<service> - L<Google::Cloud::Run::V2::Service::Service>

=item * C<validate_only> - C<bool>

=item * C<allow_missing> - C<bool>

=item * C<force_new_revision> - C<bool>

=back

=item * B<upload_source>

    my $response = $client->upload_source(
        parent                   => $parent,
    );

Calls the RPC method C<UploadSource> on C<google.cloud.run.v2.SourceUpload>.

Request: L<Google::Cloud::Run::V2::SourceUpload::UploadSourceRequest>

Returns: L<Google::Cloud::Run::V2::SourceUpload::UploadSourceResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=back

=item * B<get_task>

    my $response = $client->get_task(
        name                     => $name,
    );

Calls the RPC method C<GetTask> on C<google.cloud.run.v2.Tasks>.

Request: L<Google::Cloud::Run::V2::Task::GetTaskRequest>

Returns: L<Google::Cloud::Run::V2::Task::Task>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<create_worker_pool>

    my $response = $client->create_worker_pool(
        parent                   => $parent,
        worker_pool              => $worker_pool,
        worker_pool_id           => $worker_pool_id,
        validate_only            => $validate_only,
    );

Calls the RPC method C<CreateWorkerPool> on C<google.cloud.run.v2.WorkerPools>.

Request: L<Google::Cloud::Run::V2::WorkerPool::CreateWorkerPoolRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<worker_pool> - L<Google::Cloud::Run::V2::WorkerPool::WorkerPool>

=item * C<worker_pool_id> - C<string>

=item * C<validate_only> - C<bool>

=back

=item * B<get_worker_pool>

    my $response = $client->get_worker_pool(
        name                     => $name,
    );

Calls the RPC method C<GetWorkerPool> on C<google.cloud.run.v2.WorkerPools>.

Request: L<Google::Cloud::Run::V2::WorkerPool::GetWorkerPoolRequest>

Returns: L<Google::Cloud::Run::V2::WorkerPool::WorkerPool>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<update_worker_pool>

    my $response = $client->update_worker_pool(
        update_mask              => $update_mask,
        worker_pool              => $worker_pool,
        validate_only            => $validate_only,
        allow_missing            => $allow_missing,
        force_new_revision       => $force_new_revision,
    );

Calls the RPC method C<UpdateWorkerPool> on C<google.cloud.run.v2.WorkerPools>.

Request: L<Google::Cloud::Run::V2::WorkerPool::UpdateWorkerPoolRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=item * C<worker_pool> - L<Google::Cloud::Run::V2::WorkerPool::WorkerPool>

=item * C<validate_only> - C<bool>

=item * C<allow_missing> - C<bool>

=item * C<force_new_revision> - C<bool>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
