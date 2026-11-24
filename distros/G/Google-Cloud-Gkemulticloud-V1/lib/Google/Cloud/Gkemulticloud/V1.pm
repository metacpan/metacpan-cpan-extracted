package Google::Cloud::Gkemulticloud::V1;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Gkemulticloud::V1::CommonResources;
use Google::Cloud::Gkemulticloud::V1::AwsResources;
use Google::Cloud::Gkemulticloud::V1::AttachedResources;
use Google::Cloud::Gkemulticloud::V1::AzureResources;
use Google::Cloud::Gkemulticloud::V1::AwsService;
use Google::Cloud::Gkemulticloud::V1::AttachedService;
use Google::Cloud::Gkemulticloud::V1::AzureService;

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

    my $target = 'gkemulticloud.googleapis.com:443';
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

sub create_attached_cluster {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Gkemulticloud::V1::AttachedService::CreateAttachedClusterRequest';
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
            path           => '/google.cloud.gkemulticloud.v1.AttachedClusters/CreateAttachedCluster',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.gkemulticloud.v1.AttachedClusters',
        method         => 'CreateAttachedCluster',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_aws_cluster {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Gkemulticloud::V1::AwsService::CreateAwsClusterRequest';
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
            path           => '/google.cloud.gkemulticloud.v1.AwsClusters/CreateAwsCluster',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.gkemulticloud.v1.AwsClusters',
        method         => 'CreateAwsCluster',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_azure_client {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Gkemulticloud::V1::AzureService::CreateAzureClientRequest';
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
            path           => '/google.cloud.gkemulticloud.v1.AzureClusters/CreateAzureClient',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.gkemulticloud.v1.AzureClusters',
        method         => 'CreateAzureClient',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Gkemulticloud::V1

__END__

=head1 NAME

Google::Cloud::Gkemulticloud::V1 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Gkemulticloud::V1;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Gkemulticloud::V1->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Gkemulticloud::V1->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Gkemulticloud::V1> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/gkemulticloud/v1/attached_resources.proto>

=item * C<googleapis/google/cloud/gkemulticloud/v1/attached_service.proto>

=item * C<googleapis/google/cloud/gkemulticloud/v1/aws_resources.proto>

=item * C<googleapis/google/cloud/gkemulticloud/v1/aws_service.proto>

=item * C<googleapis/google/cloud/gkemulticloud/v1/azure_resources.proto>

=item * C<googleapis/google/cloud/gkemulticloud/v1/azure_service.proto>

=item * C<googleapis/google/cloud/gkemulticloud/v1/common_resources.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Gkemulticloud::V1->new(
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

=item * B<create_attached_cluster>

    my $response = $client->create_attached_cluster(
        parent                   => $parent,
        attached_cluster         => $attached_cluster,
        attached_cluster_id      => $attached_cluster_id,
        validate_only            => $validate_only,
    );

Calls the RPC method C<CreateAttachedCluster> on C<google.cloud.gkemulticloud.v1.AttachedClusters>.

Request: L<Google::Cloud::Gkemulticloud::V1::AttachedService::CreateAttachedClusterRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<attached_cluster> - L<Google::Cloud::Gkemulticloud::V1::AttachedResources::AttachedCluster>

=item * C<attached_cluster_id> - C<string>

=item * C<validate_only> - C<bool>

=back

=item * B<create_aws_cluster>

    my $response = $client->create_aws_cluster(
        parent                   => $parent,
        aws_cluster              => $aws_cluster,
        aws_cluster_id           => $aws_cluster_id,
        validate_only            => $validate_only,
    );

Calls the RPC method C<CreateAwsCluster> on C<google.cloud.gkemulticloud.v1.AwsClusters>.

Request: L<Google::Cloud::Gkemulticloud::V1::AwsService::CreateAwsClusterRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<aws_cluster> - L<Google::Cloud::Gkemulticloud::V1::AwsResources::AwsCluster>

=item * C<aws_cluster_id> - C<string>

=item * C<validate_only> - C<bool>

=back

=item * B<create_azure_client>

    my $response = $client->create_azure_client(
        parent                   => $parent,
        azure_client             => $azure_client,
        azure_client_id          => $azure_client_id,
        validate_only            => $validate_only,
    );

Calls the RPC method C<CreateAzureClient> on C<google.cloud.gkemulticloud.v1.AzureClusters>.

Request: L<Google::Cloud::Gkemulticloud::V1::AzureService::CreateAzureClientRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<azure_client> - L<Google::Cloud::Gkemulticloud::V1::AzureResources::AzureClient>

=item * C<azure_client_id> - C<string>

=item * C<validate_only> - C<bool>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
