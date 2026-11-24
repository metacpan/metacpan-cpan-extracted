package Google::Cloud::Designcenter::V1::DesignCenterClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Designcenter::V1::Enums;
use Google::Cloud::Designcenter::V1::Parameters;
use Google::Cloud::Designcenter::V1::Metadata;
use Google::Cloud::Designcenter::V1::Ingestion;
use Google::Cloud::Designcenter::V1::Export;
use Google::Cloud::Designcenter::V1::ApphubIntegration;
use Google::Cloud::Designcenter::V1::Assessment;
use Google::Cloud::Designcenter::V1::Deployment;
use Google::Cloud::Designcenter::V1::Iac;
use Google::Cloud::Designcenter::V1::ApphubIntegrationMessages;
use Google::Cloud::Designcenter::V1::BestPractices;
use Google::Cloud::Designcenter::V1::Authoring;
use Google::Cloud::Designcenter::V1::BestPracticesMessages;
use Google::Cloud::Designcenter::V1::CatalogManagement;
use Google::Cloud::Designcenter::V1::AuthoringMessages;
use Google::Cloud::Designcenter::V1::DeploymentResources;
use Google::Cloud::Designcenter::V1::Sharing;
use Google::Cloud::Designcenter::V1::CatalogManagementMessages;
use Google::Cloud::Designcenter::V1::DeploymentMessages;
use Google::Cloud::Designcenter::V1::SharingMessages;
use Google::Cloud::Designcenter::V1::Designcenter;

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

    my $target = 'designcenter.googleapis.com:443';
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

sub get_space {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Designcenter::V1::CatalogManagementMessages::GetSpaceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Designcenter::V1::CatalogManagement::Space';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.designcenter.v1.DesignCenter/GetSpace',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.designcenter.v1.DesignCenter',
        method         => 'GetSpace',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Designcenter::V1::DesignCenterClient

__END__

=head1 NAME

Google::Cloud::Designcenter::V1::DesignCenterClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Designcenter::V1::DesignCenterClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Designcenter::V1::DesignCenterClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Designcenter::V1::DesignCenterClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Designcenter::V1::DesignCenterClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/designcenter/v1/apphub_integration.proto>

=item * C<googleapis/google/cloud/designcenter/v1/apphub_integration_messages.proto>

=item * C<googleapis/google/cloud/designcenter/v1/assessment.proto>

=item * C<googleapis/google/cloud/designcenter/v1/authoring.proto>

=item * C<googleapis/google/cloud/designcenter/v1/authoring_messages.proto>

=item * C<googleapis/google/cloud/designcenter/v1/best_practices.proto>

=item * C<googleapis/google/cloud/designcenter/v1/best_practices_messages.proto>

=item * C<googleapis/google/cloud/designcenter/v1/catalog_management.proto>

=item * C<googleapis/google/cloud/designcenter/v1/catalog_management_messages.proto>

=item * C<googleapis/google/cloud/designcenter/v1/deployment.proto>

=item * C<googleapis/google/cloud/designcenter/v1/deployment_messages.proto>

=item * C<googleapis/google/cloud/designcenter/v1/deployment_resources.proto>

=item * C<googleapis/google/cloud/designcenter/v1/designcenter.proto>

=item * C<googleapis/google/cloud/designcenter/v1/enums.proto>

=item * C<googleapis/google/cloud/designcenter/v1/export.proto>

=item * C<googleapis/google/cloud/designcenter/v1/iac.proto>

=item * C<googleapis/google/cloud/designcenter/v1/ingestion.proto>

=item * C<googleapis/google/cloud/designcenter/v1/metadata.proto>

=item * C<googleapis/google/cloud/designcenter/v1/parameters.proto>

=item * C<googleapis/google/cloud/designcenter/v1/sharing.proto>

=item * C<googleapis/google/cloud/designcenter/v1/sharing_messages.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Designcenter::V1::DesignCenterClient->new(
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

=item * B<get_space>

    my $response = $client->get_space(
        name                     => $name,
    );

Calls the RPC method C<GetSpace> on C<google.cloud.designcenter.v1.DesignCenter>.

Request: L<Google::Cloud::Designcenter::V1::CatalogManagementMessages::GetSpaceRequest>

Returns: L<Google::Cloud::Designcenter::V1::CatalogManagement::Space>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
