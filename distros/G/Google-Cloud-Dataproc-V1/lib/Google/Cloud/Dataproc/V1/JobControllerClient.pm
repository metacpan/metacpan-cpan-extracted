package Google::Cloud::Dataproc::V1::JobControllerClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Dataproc::V1::AutoscalingPolicies;
use Google::Cloud::Dataproc::V1::Operations;
use Google::Cloud::Dataproc::V1::Shared;
use Google::Cloud::Dataproc::V1::Jobs;
use Google::Cloud::Dataproc::V1::Batches;
use Google::Cloud::Dataproc::V1::Clusters;
use Google::Cloud::Dataproc::V1::Sessions;
use Google::Cloud::Dataproc::V1::WorkflowTemplates;
use Google::Cloud::Dataproc::V1::NodeGroups;
use Google::Cloud::Dataproc::V1::SessionTemplates;

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

sub submit_job {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dataproc::V1::Jobs::SubmitJobRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Dataproc::V1::Jobs::Job';
    my $response = $self->transport->call({
        service        => 'google.cloud.dataproc.v1.JobController',
        method         => 'SubmitJob',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub submit_job_as_operation {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dataproc::V1::Jobs::SubmitJobRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Longrunning::Operations::Operation';
    my $response = $self->transport->call({
        service        => 'google.cloud.dataproc.v1.JobController',
        method         => 'SubmitJobAsOperation',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_job {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dataproc::V1::Jobs::GetJobRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Dataproc::V1::Jobs::Job';
    my $response = $self->transport->call({
        service        => 'google.cloud.dataproc.v1.JobController',
        method         => 'GetJob',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_jobs {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dataproc::V1::Jobs::ListJobsRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Dataproc::V1::Jobs::ListJobsResponse';
    my $response = $self->transport->call({
        service        => 'google.cloud.dataproc.v1.JobController',
        method         => 'ListJobs',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_job {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dataproc::V1::Jobs::UpdateJobRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Dataproc::V1::Jobs::Job';
    my $response = $self->transport->call({
        service        => 'google.cloud.dataproc.v1.JobController',
        method         => 'UpdateJob',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub cancel_job {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dataproc::V1::Jobs::CancelJobRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Dataproc::V1::Jobs::Job';
    my $response = $self->transport->call({
        service        => 'google.cloud.dataproc.v1.JobController',
        method         => 'CancelJob',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_job {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dataproc::V1::Jobs::DeleteJobRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Protobuf::Empty::Empty';
    my $response = $self->transport->call({
        service        => 'google.cloud.dataproc.v1.JobController',
        method         => 'DeleteJob',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Dataproc::V1::JobControllerClient

__END__

=head1 NAME

Google::Cloud::Dataproc::V1::JobControllerClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Dataproc::V1::JobControllerClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Dataproc::V1::JobControllerClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Dataproc::V1::JobControllerClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Dataproc::V1::JobControllerClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<google/cloud/dataproc/v1/node_groups.proto>

=item * C<google/cloud/dataproc/v1/autoscaling_policies.proto>

=item * C<google/cloud/dataproc/v1/batches.proto>

=item * C<google/cloud/dataproc/v1/session_templates.proto>

=item * C<google/cloud/dataproc/v1/operations.proto>

=item * C<google/cloud/dataproc/v1/shared.proto>

=item * C<google/cloud/dataproc/v1/workflow_templates.proto>

=item * C<google/cloud/dataproc/v1/sessions.proto>

=item * C<google/cloud/dataproc/v1/jobs.proto>

=item * C<google/cloud/dataproc/v1/clusters.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Dataproc::V1::JobControllerClient->new(
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

=item * B<submit_job>

Calls the RPC method C<SubmitJob> on the service. Takes a hash of parameters representing the request.

=item * B<submit_job_as_operation>

Calls the RPC method C<SubmitJobAsOperation> on the service. Takes a hash of parameters representing the request.

=item * B<get_job>

Calls the RPC method C<GetJob> on the service. Takes a hash of parameters representing the request.

=item * B<list_jobs>

Calls the RPC method C<ListJobs> on the service. Takes a hash of parameters representing the request.

=item * B<update_job>

Calls the RPC method C<UpdateJob> on the service. Takes a hash of parameters representing the request.

=item * B<cancel_job>

Calls the RPC method C<CancelJob> on the service. Takes a hash of parameters representing the request.

=item * B<delete_job>

Calls the RPC method C<DeleteJob> on the service. Takes a hash of parameters representing the request.

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
