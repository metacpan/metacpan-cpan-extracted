package Google::Cloud::Dataflow::V1beta3::MetricsV1Beta3Client;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Dataflow::V1beta3::Streaming;
use Google::Dataflow::V1beta3::Environment;
use Google::Dataflow::V1beta3::Messages;
use Google::Dataflow::V1beta3::Snapshots;
use Google::Dataflow::V1beta3::Metrics;
use Google::Dataflow::V1beta3::Jobs;
use Google::Dataflow::V1beta3::Templates;

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

    my $target = 'dataflow.googleapis.com:443';
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

sub get_job_metrics {
    my ($self, %params) = @_;

    my $request_class = 'Google::Dataflow::V1beta3::Metrics::GetJobMetricsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Dataflow::V1beta3::Metrics::JobMetrics';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.dataflow.v1beta3.MetricsV1Beta3/GetJobMetrics',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.dataflow.v1beta3.MetricsV1Beta3',
        method         => 'GetJobMetrics',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_job_execution_details {
    my ($self, %params) = @_;

    my $request_class = 'Google::Dataflow::V1beta3::Metrics::GetJobExecutionDetailsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Dataflow::V1beta3::Metrics::JobExecutionDetails';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.dataflow.v1beta3.MetricsV1Beta3/GetJobExecutionDetails',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.dataflow.v1beta3.MetricsV1Beta3',
        method         => 'GetJobExecutionDetails',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_stage_execution_details {
    my ($self, %params) = @_;

    my $request_class = 'Google::Dataflow::V1beta3::Metrics::GetStageExecutionDetailsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Dataflow::V1beta3::Metrics::StageExecutionDetails';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.dataflow.v1beta3.MetricsV1Beta3/GetStageExecutionDetails',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.dataflow.v1beta3.MetricsV1Beta3',
        method         => 'GetStageExecutionDetails',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Dataflow::V1beta3::MetricsV1Beta3Client

__END__

=head1 NAME

Google::Cloud::Dataflow::V1beta3::MetricsV1Beta3Client - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Dataflow::V1beta3::MetricsV1Beta3Client;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Dataflow::V1beta3::MetricsV1Beta3Client->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Dataflow::V1beta3::MetricsV1Beta3Client->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Dataflow::V1beta3::MetricsV1Beta3Client> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/dataflow/v1beta3/environment.proto>

=item * C<googleapis/google/dataflow/v1beta3/jobs.proto>

=item * C<googleapis/google/dataflow/v1beta3/messages.proto>

=item * C<googleapis/google/dataflow/v1beta3/metrics.proto>

=item * C<googleapis/google/dataflow/v1beta3/snapshots.proto>

=item * C<googleapis/google/dataflow/v1beta3/streaming.proto>

=item * C<googleapis/google/dataflow/v1beta3/templates.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Dataflow::V1beta3::MetricsV1Beta3Client->new(
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

=item * B<get_job_metrics>

    my $response = $client->get_job_metrics(
        project_id               => $project_id,
        job_id                   => $job_id,
        start_time               => $start_time,
        location                 => $location,
    );

Calls the RPC method C<GetJobMetrics> on C<google.dataflow.v1beta3.MetricsV1Beta3>.

Request: L<Google::Dataflow::V1beta3::Metrics::GetJobMetricsRequest>

Returns: L<Google::Dataflow::V1beta3::Metrics::JobMetrics>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<job_id> - C<string>

=item * C<start_time> - L<Google::Protobuf::Timestamp::Timestamp>

=item * C<location> - C<string>

=back

=item * B<get_job_execution_details>

    my $response = $client->get_job_execution_details(
        project_id               => $project_id,
        job_id                   => $job_id,
        location                 => $location,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<GetJobExecutionDetails> on C<google.dataflow.v1beta3.MetricsV1Beta3>.

Request: L<Google::Dataflow::V1beta3::Metrics::GetJobExecutionDetailsRequest>

Returns: L<Google::Dataflow::V1beta3::Metrics::JobExecutionDetails>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<job_id> - C<string>

=item * C<location> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<get_stage_execution_details>

    my $response = $client->get_stage_execution_details(
        project_id               => $project_id,
        job_id                   => $job_id,
        location                 => $location,
        stage_id                 => $stage_id,
        page_size                => $page_size,
        page_token               => $page_token,
        start_time               => $start_time,
        end_time                 => $end_time,
    );

Calls the RPC method C<GetStageExecutionDetails> on C<google.dataflow.v1beta3.MetricsV1Beta3>.

Request: L<Google::Dataflow::V1beta3::Metrics::GetStageExecutionDetailsRequest>

Returns: L<Google::Dataflow::V1beta3::Metrics::StageExecutionDetails>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<job_id> - C<string>

=item * C<location> - C<string>

=item * C<stage_id> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<start_time> - L<Google::Protobuf::Timestamp::Timestamp>

=item * C<end_time> - L<Google::Protobuf::Timestamp::Timestamp>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
