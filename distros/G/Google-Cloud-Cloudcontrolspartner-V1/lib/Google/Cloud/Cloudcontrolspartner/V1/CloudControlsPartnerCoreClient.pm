package Google::Cloud::Cloudcontrolspartner::V1::CloudControlsPartnerCoreClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Cloudcontrolspartner::V1::CompletionState;
use Google::Cloud::Cloudcontrolspartner::V1::PartnerPermissions;
use Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads;
use Google::Cloud::Cloudcontrolspartner::V1::AccessApprovalRequests;
use Google::Cloud::Cloudcontrolspartner::V1::Customers;
use Google::Cloud::Cloudcontrolspartner::V1::EkmConnections;
use Google::Cloud::Cloudcontrolspartner::V1::Partners;
use Google::Cloud::Cloudcontrolspartner::V1::Violations;
use Google::Cloud::Cloudcontrolspartner::V1::Core;
use Google::Cloud::Cloudcontrolspartner::V1::Monitoring;

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

    my $target = 'cloudcontrolspartner.googleapis.com:443';
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

sub get_workload {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::GetWorkloadRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::Workload';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.cloudcontrolspartner.v1.CloudControlsPartnerCore/GetWorkload',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.cloudcontrolspartner.v1.CloudControlsPartnerCore',
        method         => 'GetWorkload',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Cloudcontrolspartner::V1::CloudControlsPartnerCoreClient

__END__

=head1 NAME

Google::Cloud::Cloudcontrolspartner::V1::CloudControlsPartnerCoreClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Cloudcontrolspartner::V1::CloudControlsPartnerCoreClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Cloudcontrolspartner::V1::CloudControlsPartnerCoreClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Cloudcontrolspartner::V1::CloudControlsPartnerCoreClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Cloudcontrolspartner::V1::CloudControlsPartnerCoreClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/cloudcontrolspartner/v1/access_approval_requests.proto>

=item * C<googleapis/google/cloud/cloudcontrolspartner/v1/completion_state.proto>

=item * C<googleapis/google/cloud/cloudcontrolspartner/v1/core.proto>

=item * C<googleapis/google/cloud/cloudcontrolspartner/v1/customer_workloads.proto>

=item * C<googleapis/google/cloud/cloudcontrolspartner/v1/customers.proto>

=item * C<googleapis/google/cloud/cloudcontrolspartner/v1/ekm_connections.proto>

=item * C<googleapis/google/cloud/cloudcontrolspartner/v1/monitoring.proto>

=item * C<googleapis/google/cloud/cloudcontrolspartner/v1/partner_permissions.proto>

=item * C<googleapis/google/cloud/cloudcontrolspartner/v1/partners.proto>

=item * C<googleapis/google/cloud/cloudcontrolspartner/v1/violations.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Cloudcontrolspartner::V1::CloudControlsPartnerCoreClient->new(
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

=item * B<get_workload>

    my $response = $client->get_workload(
        name                     => $name,
    );

Calls the RPC method C<GetWorkload> on C<google.cloud.cloudcontrolspartner.v1.CloudControlsPartnerCore>.

Request: L<Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::GetWorkloadRequest>

Returns: L<Google::Cloud::Cloudcontrolspartner::V1::CustomerWorkloads::Workload>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
