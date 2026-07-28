package Google::Cloud::Networksecurity::V1::NetworksecurityClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy;
use Google::Cloud::Networksecurity::V1::SecurityProfileGroupMirroring;
use Google::Cloud::Networksecurity::V1::SecurityProfileGroupThreatprevention;
use Google::Cloud::Networksecurity::V1::SecurityProfileGroupUrlfiltering;
use Google::Cloud::Networksecurity::V1::AuthzPolicy;
use Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule;
use Google::Cloud::Networksecurity::V1::DnsThreatDetector;
use Google::Cloud::Networksecurity::V1::UrlList;
use Google::Cloud::Networksecurity::V1::BackendAuthenticationConfig;
use Google::Cloud::Networksecurity::V1::TlsInspectionPolicy;
use Google::Cloud::Networksecurity::V1::AuthorizationPolicy;
use Google::Cloud::Networksecurity::V1::SecurityProfileGroupIntercept;
use Google::Cloud::Networksecurity::V1::Common;
use Google::Cloud::Networksecurity::V1::Tls;
use Google::Cloud::Networksecurity::V1::SecurityProfileGroup;
use Google::Cloud::Networksecurity::V1::AddressGroup;
use Google::Cloud::Networksecurity::V1::Intercept;
use Google::Cloud::Networksecurity::V1::Mirroring;
use Google::Cloud::Networksecurity::V1::FirewallActivation;
use Google::Cloud::Networksecurity::V1::SseRealm;
use Google::Cloud::Networksecurity::V1::ClientTlsPolicy;
use Google::Cloud::Networksecurity::V1::ServerTlsPolicy;
use Google::Cloud::Networksecurity::V1::SecurityProfileGroupService;
use Google::Cloud::Networksecurity::V1::Networksecurity;

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

sub list_authorization_policies {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Networksecurity::V1::AuthorizationPolicy::ListAuthorizationPoliciesRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Cloud::Networksecurity::V1::AuthorizationPolicy::ListAuthorizationPoliciesResponse';
    my $response = $self->transport->call({
        service        => 'google.cloud.networksecurity.v1.NetworkSecurity',
        method         => 'ListAuthorizationPolicies',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Networksecurity::V1::NetworksecurityClient

__END__

=head1 NAME

Google::Cloud::Networksecurity::V1::NetworksecurityClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::NetworksecurityClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Networksecurity::V1::NetworksecurityClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Networksecurity::V1::NetworksecurityClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Networksecurity::V1::NetworksecurityClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<google/cloud/networksecurity/v1/tls_inspection_policy.proto>

=item * C<google/cloud/networksecurity/v1/common.proto>

=item * C<google/cloud/networksecurity/v1/security_profile_group_mirroring.proto>

=item * C<google/cloud/networksecurity/v1/address_group.proto>

=item * C<google/cloud/networksecurity/v1/backend_authentication_config.proto>

=item * C<google/cloud/networksecurity/v1/tls.proto>

=item * C<google/cloud/networksecurity/v1/network_security.proto>

=item * C<google/cloud/networksecurity/v1/security_profile_group_service.proto>

=item * C<google/cloud/networksecurity/v1/gateway_security_policy.proto>

=item * C<google/cloud/networksecurity/v1/firewall_activation.proto>

=item * C<google/cloud/networksecurity/v1/dns_threat_detector.proto>

=item * C<google/cloud/networksecurity/v1/mirroring.proto>

=item * C<google/cloud/networksecurity/v1/authz_policy.proto>

=item * C<google/cloud/networksecurity/v1/security_profile_group.proto>

=item * C<google/cloud/networksecurity/v1/security_profile_group_intercept.proto>

=item * C<google/cloud/networksecurity/v1/authorization_policy.proto>

=item * C<google/cloud/networksecurity/v1/client_tls_policy.proto>

=item * C<google/cloud/networksecurity/v1/url_list.proto>

=item * C<google/cloud/networksecurity/v1/security_profile_group_urlfiltering.proto>

=item * C<google/cloud/networksecurity/v1/server_tls_policy.proto>

=item * C<google/cloud/networksecurity/v1/gateway_security_policy_rule.proto>

=item * C<google/cloud/networksecurity/v1/intercept.proto>

=item * C<google/cloud/networksecurity/v1/sse_realm.proto>

=item * C<google/cloud/networksecurity/v1/security_profile_group_threatprevention.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Networksecurity::V1::NetworksecurityClient->new(
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

=item * B<list_authorization_policies>

Calls the RPC method C<ListAuthorizationPolicies> on the service. Takes a hash of parameters representing the request.

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
