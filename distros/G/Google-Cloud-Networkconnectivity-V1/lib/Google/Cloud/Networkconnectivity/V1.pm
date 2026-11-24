package Google::Cloud::Networkconnectivity::V1;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Networkconnectivity::V1::Common;
use Google::Cloud::Networkconnectivity::V1::InternalRange;
use Google::Cloud::Networkconnectivity::V1::Hub;
use Google::Cloud::Networkconnectivity::V1::DataTransfer;
use Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting;
use Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation;

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

    my $target = 'networkconnectivity.googleapis.com:443';
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

sub list_service_connection_maps {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ListServiceConnectionMapsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ListServiceConnectionMapsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.networkconnectivity.v1.CrossNetworkAutomationService/ListServiceConnectionMaps',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.networkconnectivity.v1.CrossNetworkAutomationService',
        method         => 'ListServiceConnectionMaps',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_multicloud_data_transfer_configs {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Networkconnectivity::V1::DataTransfer::ListMulticloudDataTransferConfigsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Networkconnectivity::V1::DataTransfer::ListMulticloudDataTransferConfigsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.networkconnectivity.v1.DataTransferService/ListMulticloudDataTransferConfigs',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.networkconnectivity.v1.DataTransferService',
        method         => 'ListMulticloudDataTransferConfigs',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_hubs {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Networkconnectivity::V1::Hub::ListHubsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Networkconnectivity::V1::Hub::ListHubsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.networkconnectivity.v1.HubService/ListHubs',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.networkconnectivity.v1.HubService',
        method         => 'ListHubs',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_hub {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Networkconnectivity::V1::Hub::UpdateHubRequest';
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
            path           => '/google.cloud.networkconnectivity.v1.HubService/UpdateHub',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.networkconnectivity.v1.HubService',
        method         => 'UpdateHub',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_internal_ranges {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Networkconnectivity::V1::InternalRange::ListInternalRangesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Networkconnectivity::V1::InternalRange::ListInternalRangesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.networkconnectivity.v1.InternalRangeService/ListInternalRanges',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.networkconnectivity.v1.InternalRangeService',
        method         => 'ListInternalRanges',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_policy_based_routes {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::ListPolicyBasedRoutesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::ListPolicyBasedRoutesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.networkconnectivity.v1.PolicyBasedRoutingService/ListPolicyBasedRoutes',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.networkconnectivity.v1.PolicyBasedRoutingService',
        method         => 'ListPolicyBasedRoutes',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_policy_based_route {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::DeletePolicyBasedRouteRequest';
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
            path           => '/google.cloud.networkconnectivity.v1.PolicyBasedRoutingService/DeletePolicyBasedRoute',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.networkconnectivity.v1.PolicyBasedRoutingService',
        method         => 'DeletePolicyBasedRoute',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Networkconnectivity::V1

__END__

=head1 NAME

Google::Cloud::Networkconnectivity::V1 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Networkconnectivity::V1;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Networkconnectivity::V1->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Networkconnectivity::V1->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Networkconnectivity::V1> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/networkconnectivity/v1/common.proto>

=item * C<googleapis/google/cloud/networkconnectivity/v1/cross_network_automation.proto>

=item * C<googleapis/google/cloud/networkconnectivity/v1/data_transfer.proto>

=item * C<googleapis/google/cloud/networkconnectivity/v1/hub.proto>

=item * C<googleapis/google/cloud/networkconnectivity/v1/internal_range.proto>

=item * C<googleapis/google/cloud/networkconnectivity/v1/policy_based_routing.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Networkconnectivity::V1->new(
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

=item * B<list_service_connection_maps>

    my $response = $client->list_service_connection_maps(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        filter                   => $filter,
        order_by                 => $order_by,
    );

Calls the RPC method C<ListServiceConnectionMaps> on C<google.cloud.networkconnectivity.v1.CrossNetworkAutomationService>.

Request: L<Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ListServiceConnectionMapsRequest>

Returns: L<Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ListServiceConnectionMapsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<filter> - C<string>

=item * C<order_by> - C<string>

=back

=item * B<list_multicloud_data_transfer_configs>

    my $response = $client->list_multicloud_data_transfer_configs(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        filter                   => $filter,
        order_by                 => $order_by,
        return_partial_success   => $return_partial_success,
    );

Calls the RPC method C<ListMulticloudDataTransferConfigs> on C<google.cloud.networkconnectivity.v1.DataTransferService>.

Request: L<Google::Cloud::Networkconnectivity::V1::DataTransfer::ListMulticloudDataTransferConfigsRequest>

Returns: L<Google::Cloud::Networkconnectivity::V1::DataTransfer::ListMulticloudDataTransferConfigsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<filter> - C<string>

=item * C<order_by> - C<string>

=item * C<return_partial_success> - C<bool>

=back

=item * B<list_hubs>

    my $response = $client->list_hubs(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        filter                   => $filter,
        order_by                 => $order_by,
    );

Calls the RPC method C<ListHubs> on C<google.cloud.networkconnectivity.v1.HubService>.

Request: L<Google::Cloud::Networkconnectivity::V1::Hub::ListHubsRequest>

Returns: L<Google::Cloud::Networkconnectivity::V1::Hub::ListHubsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<filter> - C<string>

=item * C<order_by> - C<string>

=back

=item * B<update_hub>

    my $response = $client->update_hub(
        update_mask              => $update_mask,
        hub                      => $hub,
        request_id               => $request_id,
    );

Calls the RPC method C<UpdateHub> on C<google.cloud.networkconnectivity.v1.HubService>.

Request: L<Google::Cloud::Networkconnectivity::V1::Hub::UpdateHubRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=item * C<hub> - L<Google::Cloud::Networkconnectivity::V1::Hub::Hub>

=item * C<request_id> - C<string>

=back

=item * B<list_internal_ranges>

    my $response = $client->list_internal_ranges(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        filter                   => $filter,
        order_by                 => $order_by,
    );

Calls the RPC method C<ListInternalRanges> on C<google.cloud.networkconnectivity.v1.InternalRangeService>.

Request: L<Google::Cloud::Networkconnectivity::V1::InternalRange::ListInternalRangesRequest>

Returns: L<Google::Cloud::Networkconnectivity::V1::InternalRange::ListInternalRangesResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<filter> - C<string>

=item * C<order_by> - C<string>

=back

=item * B<list_policy_based_routes>

    my $response = $client->list_policy_based_routes(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        filter                   => $filter,
        order_by                 => $order_by,
    );

Calls the RPC method C<ListPolicyBasedRoutes> on C<google.cloud.networkconnectivity.v1.PolicyBasedRoutingService>.

Request: L<Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::ListPolicyBasedRoutesRequest>

Returns: L<Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::ListPolicyBasedRoutesResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<filter> - C<string>

=item * C<order_by> - C<string>

=back

=item * B<delete_policy_based_route>

    my $response = $client->delete_policy_based_route(
        name                     => $name,
        request_id               => $request_id,
    );

Calls the RPC method C<DeletePolicyBasedRoute> on C<google.cloud.networkconnectivity.v1.PolicyBasedRoutingService>.

Request: L<Google::Cloud::Networkconnectivity::V1::PolicyBasedRouting::DeletePolicyBasedRouteRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<request_id> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
