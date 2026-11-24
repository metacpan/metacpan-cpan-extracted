package Google::Cloud::Run::V2::WorkerPoolsClient;

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
use Google::Cloud::Run::V2::VendorSettings;
use Google::Cloud::Run::V2::K8sMin;
use Google::Cloud::Run::V2::InstanceSplit;
use Google::Cloud::Run::V2::TrafficTarget;
use Google::Cloud::Run::V2::Condition;
use Google::Cloud::Run::V2::Build;
use Google::Cloud::Run::V2::Sandbox;
use Google::Cloud::Run::V2::SourceUpload;
use Google::Cloud::Run::V2::Instance;
use Google::Cloud::Run::V2::RevisionTemplate;
use Google::Cloud::Run::V2::Task;
use Google::Cloud::Run::V2::WorkerPoolRevisionTemplate;
use Google::Cloud::Run::V2::TaskTemplate;
use Google::Cloud::Run::V2::Revision;
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
1; # End of Google::Cloud::Run::V2::WorkerPoolsClient

__END__

=head1 NAME

Google::Cloud::Run::V2::WorkerPoolsClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Run::V2::WorkerPoolsClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Run::V2::WorkerPoolsClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Run::V2::WorkerPoolsClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Run::V2::WorkerPoolsClient> is an auto-generated client library for Google Cloud Services.

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

    my $client = Google::Cloud::Run::V2::WorkerPoolsClient->new(
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
