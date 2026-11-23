package Google::Cloud::Dataflow::V1beta3::TemplatesServiceClient;

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

sub create_job_from_template {
    my ($self, %params) = @_;

    my $request_class = 'Google::Dataflow::V1beta3::Templates::CreateJobFromTemplateRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Dataflow::V1beta3::Jobs::Job';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.dataflow.v1beta3.TemplatesService/CreateJobFromTemplate',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.dataflow.v1beta3.TemplatesService',
        method         => 'CreateJobFromTemplate',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub launch_template {
    my ($self, %params) = @_;

    my $request_class = 'Google::Dataflow::V1beta3::Templates::LaunchTemplateRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Dataflow::V1beta3::Templates::LaunchTemplateResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.dataflow.v1beta3.TemplatesService/LaunchTemplate',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.dataflow.v1beta3.TemplatesService',
        method         => 'LaunchTemplate',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_template {
    my ($self, %params) = @_;

    my $request_class = 'Google::Dataflow::V1beta3::Templates::GetTemplateRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Dataflow::V1beta3::Templates::GetTemplateResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.dataflow.v1beta3.TemplatesService/GetTemplate',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.dataflow.v1beta3.TemplatesService',
        method         => 'GetTemplate',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Dataflow::V1beta3::TemplatesServiceClient

__END__

=head1 NAME

Google::Cloud::Dataflow::V1beta3::TemplatesServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Dataflow::V1beta3::TemplatesServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Dataflow::V1beta3::TemplatesServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Dataflow::V1beta3::TemplatesServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Dataflow::V1beta3::TemplatesServiceClient> is an auto-generated client library for Google Cloud Services.

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

    my $client = Google::Cloud::Dataflow::V1beta3::TemplatesServiceClient->new(
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

=item * B<create_job_from_template>

Calls the RPC method C<CreateJobFromTemplate> on the service. Takes a hash of parameters representing the request.

=item * B<launch_template>

Calls the RPC method C<LaunchTemplate> on the service. Takes a hash of parameters representing the request.

=item * B<get_template>

Calls the RPC method C<GetTemplate> on the service. Takes a hash of parameters representing the request.

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
