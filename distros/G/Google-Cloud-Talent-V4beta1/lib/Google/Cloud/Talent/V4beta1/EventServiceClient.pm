package Google::Cloud::Talent::V4beta1::EventServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Talent::V4beta1::Batch;
use Google::Cloud::Talent::V4beta1::Histogram;
use Google::Cloud::Talent::V4beta1::Tenant;
use Google::Cloud::Talent::V4beta1::Event;
use Google::Cloud::Talent::V4beta1::Common;
use Google::Cloud::Talent::V4beta1::EventService;
use Google::Cloud::Talent::V4beta1::Job;
use Google::Cloud::Talent::V4beta1::CompletionService;
use Google::Cloud::Talent::V4beta1::Filters;
use Google::Cloud::Talent::V4beta1::TenantService;
use Google::Cloud::Talent::V4beta1::Company;
use Google::Cloud::Talent::V4beta1::JobService;
use Google::Cloud::Talent::V4beta1::CompanyService;

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

    my $target = 'jobs.googleapis.com:443';
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

sub create_client_event {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Talent::V4beta1::EventService::CreateClientEventRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Talent::V4beta1::Event::ClientEvent';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.talent.v4beta1.EventService/CreateClientEvent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.talent.v4beta1.EventService',
        method         => 'CreateClientEvent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Talent::V4beta1::EventServiceClient

__END__

=head1 NAME

Google::Cloud::Talent::V4beta1::EventServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Talent::V4beta1::EventServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Talent::V4beta1::EventServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Talent::V4beta1::EventServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Talent::V4beta1::EventServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/talent/v4beta1/batch.proto>

=item * C<googleapis/google/cloud/talent/v4beta1/common.proto>

=item * C<googleapis/google/cloud/talent/v4beta1/company.proto>

=item * C<googleapis/google/cloud/talent/v4beta1/company_service.proto>

=item * C<googleapis/google/cloud/talent/v4beta1/completion_service.proto>

=item * C<googleapis/google/cloud/talent/v4beta1/event.proto>

=item * C<googleapis/google/cloud/talent/v4beta1/event_service.proto>

=item * C<googleapis/google/cloud/talent/v4beta1/filters.proto>

=item * C<googleapis/google/cloud/talent/v4beta1/histogram.proto>

=item * C<googleapis/google/cloud/talent/v4beta1/job.proto>

=item * C<googleapis/google/cloud/talent/v4beta1/job_service.proto>

=item * C<googleapis/google/cloud/talent/v4beta1/tenant.proto>

=item * C<googleapis/google/cloud/talent/v4beta1/tenant_service.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Talent::V4beta1::EventServiceClient->new(
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

=item * B<create_client_event>

    my $response = $client->create_client_event(
        parent                   => $parent,
        client_event             => $client_event,
    );

Calls the RPC method C<CreateClientEvent> on C<google.cloud.talent.v4beta1.EventService>.

Request: L<Google::Cloud::Talent::V4beta1::EventService::CreateClientEventRequest>

Returns: L<Google::Cloud::Talent::V4beta1::Event::ClientEvent>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<client_event> - L<Google::Cloud::Talent::V4beta1::Event::ClientEvent>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
