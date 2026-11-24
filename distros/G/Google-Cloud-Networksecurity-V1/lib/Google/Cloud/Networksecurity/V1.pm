package Google::Cloud::Networksecurity::V1;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Networksecurity::V1::Common;
use Google::Cloud::Networksecurity::V1::Tls;
use Google::Cloud::Networksecurity::V1::SecurityProfileGroupThreatprevention;
use Google::Cloud::Networksecurity::V1::SecurityProfileGroupUrlfiltering;
use Google::Cloud::Networksecurity::V1::SecurityProfileGroupIntercept;
use Google::Cloud::Networksecurity::V1::BackendAuthenticationConfig;
use Google::Cloud::Networksecurity::V1::DnsThreatDetector;
use Google::Cloud::Networksecurity::V1::AuthzPolicy;
use Google::Cloud::Networksecurity::V1::TlsInspectionPolicy;
use Google::Cloud::Networksecurity::V1::SecurityProfileGroupMirroring;
use Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule;
use Google::Cloud::Networksecurity::V1::AuthorizationPolicy;
use Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy;
use Google::Cloud::Networksecurity::V1::UrlList;
use Google::Cloud::Networksecurity::V1::AddressGroup;
use Google::Cloud::Networksecurity::V1::Intercept;
use Google::Cloud::Networksecurity::V1::FirewallActivation;
use Google::Cloud::Networksecurity::V1::SseRealm;
use Google::Cloud::Networksecurity::V1::Mirroring;
use Google::Cloud::Networksecurity::V1::ClientTlsPolicy;
use Google::Cloud::Networksecurity::V1::ServerTlsPolicy;
use Google::Cloud::Networksecurity::V1::SecurityProfileGroup;
use Google::Cloud::Networksecurity::V1::NetworkSecurity;
use Google::Cloud::Networksecurity::V1::SecurityProfileGroupService;

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

    my $target = 'networksecurity.googleapis.com:443';
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

sub list_address_groups {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Networksecurity::V1::AddressGroup::ListAddressGroupsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Networksecurity::V1::AddressGroup::ListAddressGroupsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.networksecurity.v1.AddressGroupService/ListAddressGroups',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.networksecurity.v1.AddressGroupService',
        method         => 'ListAddressGroups',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_dns_threat_detectors {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Networksecurity::V1::DnsThreatDetector::ListDnsThreatDetectorsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Networksecurity::V1::DnsThreatDetector::ListDnsThreatDetectorsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.networksecurity.v1.DnsThreatDetectorService/ListDnsThreatDetectors',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.networksecurity.v1.DnsThreatDetectorService',
        method         => 'ListDnsThreatDetectors',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_firewall_endpoints {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Networksecurity::V1::FirewallActivation::ListFirewallEndpointsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Networksecurity::V1::FirewallActivation::ListFirewallEndpointsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.networksecurity.v1.FirewallActivation/ListFirewallEndpoints',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.networksecurity.v1.FirewallActivation',
        method         => 'ListFirewallEndpoints',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_intercept_endpoint_groups {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Networksecurity::V1::Intercept::ListInterceptEndpointGroupsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Networksecurity::V1::Intercept::ListInterceptEndpointGroupsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.networksecurity.v1.Intercept/ListInterceptEndpointGroups',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.networksecurity.v1.Intercept',
        method         => 'ListInterceptEndpointGroups',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_mirroring_endpoint_groups {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Networksecurity::V1::Mirroring::ListMirroringEndpointGroupsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Networksecurity::V1::Mirroring::ListMirroringEndpointGroupsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.networksecurity.v1.Mirroring/ListMirroringEndpointGroups',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.networksecurity.v1.Mirroring',
        method         => 'ListMirroringEndpointGroups',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_authorization_policies {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Networksecurity::V1::AuthorizationPolicy::ListAuthorizationPoliciesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Networksecurity::V1::AuthorizationPolicy::ListAuthorizationPoliciesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.networksecurity.v1.NetworkSecurity/ListAuthorizationPolicies',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.networksecurity.v1.NetworkSecurity',
        method         => 'ListAuthorizationPolicies',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_security_profile_groups {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::ListSecurityProfileGroupsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::ListSecurityProfileGroupsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.networksecurity.v1.SecurityProfileGroupService/ListSecurityProfileGroups',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.networksecurity.v1.SecurityProfileGroupService',
        method         => 'ListSecurityProfileGroups',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_sacrealms {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Networksecurity::V1::SseRealm::ListSACRealmsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Networksecurity::V1::SseRealm::ListSACRealmsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.networksecurity.v1.SSERealmService/ListSACRealms',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.networksecurity.v1.SSERealmService',
        method         => 'ListSACRealms',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Networksecurity::V1

__END__

=head1 NAME

Google::Cloud::Networksecurity::V1 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Networksecurity::V1->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Networksecurity::V1->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Networksecurity::V1> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/networksecurity/v1/address_group.proto>

=item * C<googleapis/google/cloud/networksecurity/v1/authorization_policy.proto>

=item * C<googleapis/google/cloud/networksecurity/v1/authz_policy.proto>

=item * C<googleapis/google/cloud/networksecurity/v1/backend_authentication_config.proto>

=item * C<googleapis/google/cloud/networksecurity/v1/client_tls_policy.proto>

=item * C<googleapis/google/cloud/networksecurity/v1/common.proto>

=item * C<googleapis/google/cloud/networksecurity/v1/dns_threat_detector.proto>

=item * C<googleapis/google/cloud/networksecurity/v1/firewall_activation.proto>

=item * C<googleapis/google/cloud/networksecurity/v1/gateway_security_policy.proto>

=item * C<googleapis/google/cloud/networksecurity/v1/gateway_security_policy_rule.proto>

=item * C<googleapis/google/cloud/networksecurity/v1/intercept.proto>

=item * C<googleapis/google/cloud/networksecurity/v1/mirroring.proto>

=item * C<googleapis/google/cloud/networksecurity/v1/network_security.proto>

=item * C<googleapis/google/cloud/networksecurity/v1/security_profile_group.proto>

=item * C<googleapis/google/cloud/networksecurity/v1/security_profile_group_intercept.proto>

=item * C<googleapis/google/cloud/networksecurity/v1/security_profile_group_mirroring.proto>

=item * C<googleapis/google/cloud/networksecurity/v1/security_profile_group_service.proto>

=item * C<googleapis/google/cloud/networksecurity/v1/security_profile_group_threatprevention.proto>

=item * C<googleapis/google/cloud/networksecurity/v1/security_profile_group_urlfiltering.proto>

=item * C<googleapis/google/cloud/networksecurity/v1/server_tls_policy.proto>

=item * C<googleapis/google/cloud/networksecurity/v1/sse_realm.proto>

=item * C<googleapis/google/cloud/networksecurity/v1/tls.proto>

=item * C<googleapis/google/cloud/networksecurity/v1/tls_inspection_policy.proto>

=item * C<googleapis/google/cloud/networksecurity/v1/url_list.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Networksecurity::V1->new(
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

=item * B<list_address_groups>

    my $response = $client->list_address_groups(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        return_partial_success   => $return_partial_success,
    );

Calls the RPC method C<ListAddressGroups> on C<google.cloud.networksecurity.v1.AddressGroupService>.

Request: L<Google::Cloud::Networksecurity::V1::AddressGroup::ListAddressGroupsRequest>

Returns: L<Google::Cloud::Networksecurity::V1::AddressGroup::ListAddressGroupsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<return_partial_success> - C<bool>

=back

=item * B<list_dns_threat_detectors>

    my $response = $client->list_dns_threat_detectors(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListDnsThreatDetectors> on C<google.cloud.networksecurity.v1.DnsThreatDetectorService>.

Request: L<Google::Cloud::Networksecurity::V1::DnsThreatDetector::ListDnsThreatDetectorsRequest>

Returns: L<Google::Cloud::Networksecurity::V1::DnsThreatDetector::ListDnsThreatDetectorsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<list_firewall_endpoints>

    my $response = $client->list_firewall_endpoints(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        filter                   => $filter,
        order_by                 => $order_by,
    );

Calls the RPC method C<ListFirewallEndpoints> on C<google.cloud.networksecurity.v1.FirewallActivation>.

Request: L<Google::Cloud::Networksecurity::V1::FirewallActivation::ListFirewallEndpointsRequest>

Returns: L<Google::Cloud::Networksecurity::V1::FirewallActivation::ListFirewallEndpointsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<filter> - C<string>

=item * C<order_by> - C<string>

=back

=item * B<list_intercept_endpoint_groups>

    my $response = $client->list_intercept_endpoint_groups(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        filter                   => $filter,
        order_by                 => $order_by,
    );

Calls the RPC method C<ListInterceptEndpointGroups> on C<google.cloud.networksecurity.v1.Intercept>.

Request: L<Google::Cloud::Networksecurity::V1::Intercept::ListInterceptEndpointGroupsRequest>

Returns: L<Google::Cloud::Networksecurity::V1::Intercept::ListInterceptEndpointGroupsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<filter> - C<string>

=item * C<order_by> - C<string>

=back

=item * B<list_mirroring_endpoint_groups>

    my $response = $client->list_mirroring_endpoint_groups(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        filter                   => $filter,
        order_by                 => $order_by,
    );

Calls the RPC method C<ListMirroringEndpointGroups> on C<google.cloud.networksecurity.v1.Mirroring>.

Request: L<Google::Cloud::Networksecurity::V1::Mirroring::ListMirroringEndpointGroupsRequest>

Returns: L<Google::Cloud::Networksecurity::V1::Mirroring::ListMirroringEndpointGroupsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<filter> - C<string>

=item * C<order_by> - C<string>

=back

=item * B<list_authorization_policies>

    my $response = $client->list_authorization_policies(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListAuthorizationPolicies> on C<google.cloud.networksecurity.v1.NetworkSecurity>.

Request: L<Google::Cloud::Networksecurity::V1::AuthorizationPolicy::ListAuthorizationPoliciesRequest>

Returns: L<Google::Cloud::Networksecurity::V1::AuthorizationPolicy::ListAuthorizationPoliciesResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<list_security_profile_groups>

    my $response = $client->list_security_profile_groups(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListSecurityProfileGroups> on C<google.cloud.networksecurity.v1.SecurityProfileGroupService>.

Request: L<Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::ListSecurityProfileGroupsRequest>

Returns: L<Google::Cloud::Networksecurity::V1::SecurityProfileGroupService::ListSecurityProfileGroupsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<list_sacrealms>

    my $response = $client->list_sacrealms(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        filter                   => $filter,
        order_by                 => $order_by,
    );

Calls the RPC method C<ListSACRealms> on C<google.cloud.networksecurity.v1.SSERealmService>.

Request: L<Google::Cloud::Networksecurity::V1::SseRealm::ListSACRealmsRequest>

Returns: L<Google::Cloud::Networksecurity::V1::SseRealm::ListSACRealmsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<filter> - C<string>

=item * C<order_by> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
