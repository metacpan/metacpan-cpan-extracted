package Google::Cloud::Networksecurity::V1::OrganizationSecurityProfileGroupServiceClient;

use strict;
use warnings;

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Networksecurity::V1::SecurityProfileGroupThreatprevention;
use Google::Cloud::Networksecurity::V1::SecurityProfileGroupUrlfiltering;
use Google::Cloud::Networksecurity::V1::Tls;
use Google::Cloud::Networksecurity::V1::SecurityProfileGroupMirroring;
use Google::Cloud::Networksecurity::V1::SecurityProfileGroupIntercept;
use Google::Cloud::Networksecurity::V1::Common;
use Google::Cloud::Networksecurity::V1::GatewaySecurityPolicy;
use Google::Cloud::Networksecurity::V1::UrlList;
use Google::Cloud::Networksecurity::V1::GatewaySecurityPolicyRule;
use Google::Cloud::Networksecurity::V1::TlsInspectionPolicy;
use Google::Cloud::Networksecurity::V1::AuthzPolicy;
use Google::Cloud::Networksecurity::V1::BackendAuthenticationConfig;
use Google::Cloud::Networksecurity::V1::AuthorizationPolicy;
use Google::Cloud::Networksecurity::V1::DnsThreatDetector;
use Google::Cloud::Networksecurity::V1::ServerTlsPolicy;
use Google::Cloud::Networksecurity::V1::ClientTlsPolicy;
use Google::Cloud::Networksecurity::V1::SecurityProfileGroup;
use Google::Cloud::Networksecurity::V1::SseRealm;
use Google::Cloud::Networksecurity::V1::Mirroring;
use Google::Cloud::Networksecurity::V1::Intercept;
use Google::Cloud::Networksecurity::V1::AddressGroup;
use Google::Cloud::Networksecurity::V1::FirewallActivation;
use Google::Cloud::Networksecurity::V1::NetworkSecurity;
use Google::Cloud::Networksecurity::V1::SecurityProfileGroupService;

our $VERSION = '0.05';
1; # End of Google::Cloud::Networksecurity::V1::OrganizationSecurityProfileGroupServiceClient

__END__

=head1 NAME

Google::Cloud::Networksecurity::V1::OrganizationSecurityProfileGroupServiceClient - Auto-generated Protocol Buffers schema container

=head1 DESCRIPTION

This is an auto-generated Protocol Buffers schema container module for Google Cloud Services.

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1::AddressGroupServiceClient;

    my $client = Google::Cloud::Networksecurity::V1::AddressGroupServiceClient->new();

=head1 CLIENTS

This distribution provides the following service client classes:

=over 4

=item * L<Google::Cloud::Networksecurity::V1::AddressGroupServiceClient>

=item * L<Google::Cloud::Networksecurity::V1::DnsThreatDetectorServiceClient>

=item * L<Google::Cloud::Networksecurity::V1::FirewallActivationClient>

=item * L<Google::Cloud::Networksecurity::V1::InterceptClient>

=item * L<Google::Cloud::Networksecurity::V1::MirroringClient>

=item * L<Google::Cloud::Networksecurity::V1::NetworkSecurityClient>

=item * L<Google::Cloud::Networksecurity::V1::OrganizationAddressGroupServiceClient>

=item * L<Google::Cloud::Networksecurity::V1::OrganizationSecurityProfileGroupServiceClient>

=item * L<Google::Cloud::Networksecurity::V1::SSERealmServiceClient>

=item * L<Google::Cloud::Networksecurity::V1::SecurityProfileGroupServiceClient>

=back

=head1 SEE ALSO

L<Google::Cloud::Networksecurity::V1::AddressGroupServiceClient>, L<Google::Cloud::Networksecurity::V1::DnsThreatDetectorServiceClient>, L<Google::Cloud::Networksecurity::V1::FirewallActivationClient>, L<Google::Cloud::Networksecurity::V1::InterceptClient>, L<Google::Cloud::Networksecurity::V1::MirroringClient>, L<Google::Cloud::Networksecurity::V1::NetworkSecurityClient>, L<Google::Cloud::Networksecurity::V1::OrganizationAddressGroupServiceClient>, L<Google::Cloud::Networksecurity::V1::OrganizationSecurityProfileGroupServiceClient>, L<Google::Cloud::Networksecurity::V1::SSERealmServiceClient>, L<Google::Cloud::Networksecurity::V1::SecurityProfileGroupServiceClient>

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

=item * C<googleapis/google/cloud/networksecurity/v1/security_profile_group_intercept.proto>

=item * C<googleapis/google/cloud/networksecurity/v1/security_profile_group_mirroring.proto>

=item * C<googleapis/google/cloud/networksecurity/v1/security_profile_group.proto>

=item * C<googleapis/google/cloud/networksecurity/v1/security_profile_group_service.proto>

=item * C<googleapis/google/cloud/networksecurity/v1/security_profile_group_threatprevention.proto>

=item * C<googleapis/google/cloud/networksecurity/v1/security_profile_group_urlfiltering.proto>

=item * C<googleapis/google/cloud/networksecurity/v1/server_tls_policy.proto>

=item * C<googleapis/google/cloud/networksecurity/v1/sse_realm.proto>

=item * C<googleapis/google/cloud/networksecurity/v1/tls_inspection_policy.proto>

=item * C<googleapis/google/cloud/networksecurity/v1/tls.proto>

=item * C<googleapis/google/cloud/networksecurity/v1/url_list.proto>



=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
