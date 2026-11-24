package Google::Cloud::Compute::V1::NetworksClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Compute::V1::Compute;

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

    my $target = 'compute/v1.googleapis.com:443';
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

sub add_peering {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AddPeeringNetworkRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Networks/AddPeering',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Networks',
        method         => 'AddPeering',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub cancel_request_remove_peering {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::CancelRequestRemovePeeringNetworkRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Networks/CancelRequestRemovePeering',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Networks',
        method         => 'CancelRequestRemovePeering',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DeleteNetworkRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Networks/Delete',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Networks',
        method         => 'Delete',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetNetworkRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Network';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Networks/Get',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Networks',
        method         => 'Get',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_effective_firewalls {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetEffectiveFirewallsNetworkRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::NetworksGetEffectiveFirewallsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Networks/GetEffectiveFirewalls',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Networks',
        method         => 'GetEffectiveFirewalls',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub insert {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::InsertNetworkRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Networks/Insert',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Networks',
        method         => 'Insert',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListNetworksRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::NetworkList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Networks/List',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Networks',
        method         => 'List',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_peering_routes {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListPeeringRoutesNetworksRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::ExchangedPeeringRoutesList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Networks/ListPeeringRoutes',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Networks',
        method         => 'ListPeeringRoutes',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::PatchNetworkRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Networks/Patch',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Networks',
        method         => 'Patch',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub remove_peering {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::RemovePeeringNetworkRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Networks/RemovePeering',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Networks',
        method         => 'RemovePeering',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub request_remove_peering {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::RequestRemovePeeringNetworkRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Networks/RequestRemovePeering',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Networks',
        method         => 'RequestRemovePeering',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub switch_to_custom_mode {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SwitchToCustomModeNetworkRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Networks/SwitchToCustomMode',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Networks',
        method         => 'SwitchToCustomMode',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_peering {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::UpdatePeeringNetworkRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Networks/UpdatePeering',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Networks',
        method         => 'UpdatePeering',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Compute::V1::NetworksClient

__END__

=head1 NAME

Google::Cloud::Compute::V1::NetworksClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Compute::V1::NetworksClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Compute::V1::NetworksClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Compute::V1::NetworksClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Compute::V1::NetworksClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/compute/v1/compute.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Compute::V1::NetworksClient->new(
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

=item * B<add_peering>

    my $response = $client->add_peering(
        network                  => $network,
        networks_add_peering_request_resource => $networks_add_peering_request_resource,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<AddPeering> on C<google.cloud.compute.v1.Networks>.

Request: L<Google::Cloud::Compute::V1::Compute::AddPeeringNetworkRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<network> - C<string>

=item * C<networks_add_peering_request_resource> - L<Google::Cloud::Compute::V1::Compute::NetworksAddPeeringRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<cancel_request_remove_peering>

    my $response = $client->cancel_request_remove_peering(
        network                  => $network,
        networks_cancel_request_remove_peering_request_resource => $networks_cancel_request_remove_peering_request_resource,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<CancelRequestRemovePeering> on C<google.cloud.compute.v1.Networks>.

Request: L<Google::Cloud::Compute::V1::Compute::CancelRequestRemovePeeringNetworkRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<network> - C<string>

=item * C<networks_cancel_request_remove_peering_request_resource> - L<Google::Cloud::Compute::V1::Compute::NetworksCancelRequestRemovePeeringRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<delete>

    my $response = $client->delete(
        network                  => $network,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<Delete> on C<google.cloud.compute.v1.Networks>.

Request: L<Google::Cloud::Compute::V1::Compute::DeleteNetworkRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<network> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<get>

    my $response = $client->get(
        network                  => $network,
        project                  => $project,
    );

Calls the RPC method C<Get> on C<google.cloud.compute.v1.Networks>.

Request: L<Google::Cloud::Compute::V1::Compute::GetNetworkRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Network>

Parameters:

=over 4

=item * C<network> - C<string>

=item * C<project> - C<string>

=back

=item * B<get_effective_firewalls>

    my $response = $client->get_effective_firewalls(
        network                  => $network,
        project                  => $project,
    );

Calls the RPC method C<GetEffectiveFirewalls> on C<google.cloud.compute.v1.Networks>.

Request: L<Google::Cloud::Compute::V1::Compute::GetEffectiveFirewallsNetworkRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::NetworksGetEffectiveFirewallsResponse>

Parameters:

=over 4

=item * C<network> - C<string>

=item * C<project> - C<string>

=back

=item * B<insert>

    my $response = $client->insert(
        network_resource         => $network_resource,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<Insert> on C<google.cloud.compute.v1.Networks>.

Request: L<Google::Cloud::Compute::V1::Compute::InsertNetworkRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<network_resource> - L<Google::Cloud::Compute::V1::Compute::Network>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<list>

    my $response = $client->list(
        filter                   => $filter,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
    );

Calls the RPC method C<List> on C<google.cloud.compute.v1.Networks>.

Request: L<Google::Cloud::Compute::V1::Compute::ListNetworksRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::NetworkList>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=back

=item * B<list_peering_routes>

    my $response = $client->list_peering_routes(
        direction                => $direction,
        filter                   => $filter,
        max_results              => $max_results,
        network                  => $network,
        order_by                 => $order_by,
        page_token               => $page_token,
        peering_name             => $peering_name,
        project                  => $project,
        region                   => $region,
    );

Calls the RPC method C<ListPeeringRoutes> on C<google.cloud.compute.v1.Networks>.

Request: L<Google::Cloud::Compute::V1::Compute::ListPeeringRoutesNetworksRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::ExchangedPeeringRoutesList>

Parameters:

=over 4

=item * C<direction> - C<string>

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<network> - C<string>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<peering_name> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=back

=item * B<patch>

    my $response = $client->patch(
        network                  => $network,
        network_resource         => $network_resource,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<Patch> on C<google.cloud.compute.v1.Networks>.

Request: L<Google::Cloud::Compute::V1::Compute::PatchNetworkRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<network> - C<string>

=item * C<network_resource> - L<Google::Cloud::Compute::V1::Compute::Network>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<remove_peering>

    my $response = $client->remove_peering(
        network                  => $network,
        networks_remove_peering_request_resource => $networks_remove_peering_request_resource,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<RemovePeering> on C<google.cloud.compute.v1.Networks>.

Request: L<Google::Cloud::Compute::V1::Compute::RemovePeeringNetworkRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<network> - C<string>

=item * C<networks_remove_peering_request_resource> - L<Google::Cloud::Compute::V1::Compute::NetworksRemovePeeringRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<request_remove_peering>

    my $response = $client->request_remove_peering(
        network                  => $network,
        networks_request_remove_peering_request_resource => $networks_request_remove_peering_request_resource,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<RequestRemovePeering> on C<google.cloud.compute.v1.Networks>.

Request: L<Google::Cloud::Compute::V1::Compute::RequestRemovePeeringNetworkRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<network> - C<string>

=item * C<networks_request_remove_peering_request_resource> - L<Google::Cloud::Compute::V1::Compute::NetworksRequestRemovePeeringRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<switch_to_custom_mode>

    my $response = $client->switch_to_custom_mode(
        network                  => $network,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<SwitchToCustomMode> on C<google.cloud.compute.v1.Networks>.

Request: L<Google::Cloud::Compute::V1::Compute::SwitchToCustomModeNetworkRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<network> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<update_peering>

    my $response = $client->update_peering(
        network                  => $network,
        networks_update_peering_request_resource => $networks_update_peering_request_resource,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<UpdatePeering> on C<google.cloud.compute.v1.Networks>.

Request: L<Google::Cloud::Compute::V1::Compute::UpdatePeeringNetworkRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<network> - C<string>

=item * C<networks_update_peering_request_resource> - L<Google::Cloud::Compute::V1::Compute::NetworksUpdatePeeringRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
