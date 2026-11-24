package Google::Cloud::Compute::V1::ReservationSubBlocksClient;

use strict;
use warnings;

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Compute::V1::Compute;

our $VERSION = '0.06';
1; # End of Google::Cloud::Compute::V1::ReservationSubBlocksClient

__END__

=head1 NAME

Google::Cloud::Compute::V1::ReservationSubBlocksClient - Auto-generated Protocol Buffers schema container

=head1 DESCRIPTION

This is an auto-generated Protocol Buffers schema container module for Google Cloud Services.

=head1 SYNOPSIS

    use Google::Cloud::Compute::V1::AcceleratorTypesClient;

    my $client = Google::Cloud::Compute::V1::AcceleratorTypesClient->new();

=head1 CLIENTS

This distribution provides the following service client classes:

=over 4

=item * L<Google::Cloud::Compute::V1::AcceleratorTypesClient>

=item * L<Google::Cloud::Compute::V1::AddressesClient>

=item * L<Google::Cloud::Compute::V1::AdviceClient>

=item * L<Google::Cloud::Compute::V1::AutoscalersClient>

=item * L<Google::Cloud::Compute::V1::BackendBucketsClient>

=item * L<Google::Cloud::Compute::V1::BackendServicesClient>

=item * L<Google::Cloud::Compute::V1::CrossSiteNetworksClient>

=item * L<Google::Cloud::Compute::V1::DiskTypesClient>

=item * L<Google::Cloud::Compute::V1::DisksClient>

=item * L<Google::Cloud::Compute::V1::ExternalVpnGatewaysClient>

=item * L<Google::Cloud::Compute::V1::FirewallPoliciesClient>

=item * L<Google::Cloud::Compute::V1::FirewallsClient>

=item * L<Google::Cloud::Compute::V1::ForwardingRulesClient>

=item * L<Google::Cloud::Compute::V1::FutureReservationsClient>

=item * L<Google::Cloud::Compute::V1::GlobalAddressesClient>

=item * L<Google::Cloud::Compute::V1::GlobalForwardingRulesClient>

=item * L<Google::Cloud::Compute::V1::GlobalFrontendSettingsServiceClient>

=item * L<Google::Cloud::Compute::V1::GlobalNetworkEndpointGroupsClient>

=item * L<Google::Cloud::Compute::V1::GlobalOperationsClient>

=item * L<Google::Cloud::Compute::V1::GlobalOrganizationOperationsClient>

=item * L<Google::Cloud::Compute::V1::GlobalPublicDelegatedPrefixesClient>

=item * L<Google::Cloud::Compute::V1::GlobalVmExtensionPoliciesClient>

=item * L<Google::Cloud::Compute::V1::HealthChecksClient>

=item * L<Google::Cloud::Compute::V1::HostsClient>

=item * L<Google::Cloud::Compute::V1::ImageFamilyViewsClient>

=item * L<Google::Cloud::Compute::V1::ImageViewsClient>

=item * L<Google::Cloud::Compute::V1::ImagesClient>

=item * L<Google::Cloud::Compute::V1::InstanceGroupManagerResizeRequestsClient>

=item * L<Google::Cloud::Compute::V1::InstanceGroupManagersClient>

=item * L<Google::Cloud::Compute::V1::InstanceGroupsClient>

=item * L<Google::Cloud::Compute::V1::InstanceSettingsServiceClient>

=item * L<Google::Cloud::Compute::V1::InstanceTemplatesClient>

=item * L<Google::Cloud::Compute::V1::InstancesClient>

=item * L<Google::Cloud::Compute::V1::InstantSnapshotGroupsClient>

=item * L<Google::Cloud::Compute::V1::InstantSnapshotsClient>

=item * L<Google::Cloud::Compute::V1::InterconnectAttachmentGroupsClient>

=item * L<Google::Cloud::Compute::V1::InterconnectAttachmentsClient>

=item * L<Google::Cloud::Compute::V1::InterconnectGroupsClient>

=item * L<Google::Cloud::Compute::V1::InterconnectLocationsClient>

=item * L<Google::Cloud::Compute::V1::InterconnectRemoteLocationsClient>

=item * L<Google::Cloud::Compute::V1::InterconnectsClient>

=item * L<Google::Cloud::Compute::V1::LicenseCodesClient>

=item * L<Google::Cloud::Compute::V1::LicensesClient>

=item * L<Google::Cloud::Compute::V1::MachineImagesClient>

=item * L<Google::Cloud::Compute::V1::MachineTypesClient>

=item * L<Google::Cloud::Compute::V1::ManagedRulesetsClient>

=item * L<Google::Cloud::Compute::V1::NetworkAttachmentsClient>

=item * L<Google::Cloud::Compute::V1::NetworkEdgeSecurityServicesClient>

=item * L<Google::Cloud::Compute::V1::NetworkEndpointGroupsClient>

=item * L<Google::Cloud::Compute::V1::NetworkFirewallPoliciesClient>

=item * L<Google::Cloud::Compute::V1::NetworkProfilesClient>

=item * L<Google::Cloud::Compute::V1::NetworksClient>

=item * L<Google::Cloud::Compute::V1::NodeGroupsClient>

=item * L<Google::Cloud::Compute::V1::NodeTemplatesClient>

=item * L<Google::Cloud::Compute::V1::NodeTypesClient>

=item * L<Google::Cloud::Compute::V1::OrganizationSecurityPoliciesClient>

=item * L<Google::Cloud::Compute::V1::PacketMirroringsClient>

=item * L<Google::Cloud::Compute::V1::PreviewFeaturesClient>

=item * L<Google::Cloud::Compute::V1::ProjectViewsClient>

=item * L<Google::Cloud::Compute::V1::ProjectsClient>

=item * L<Google::Cloud::Compute::V1::PublicAdvertisedPrefixesClient>

=item * L<Google::Cloud::Compute::V1::PublicDelegatedPrefixesClient>

=item * L<Google::Cloud::Compute::V1::RegionAutoscalersClient>

=item * L<Google::Cloud::Compute::V1::RegionBackendBucketsClient>

=item * L<Google::Cloud::Compute::V1::RegionBackendServicesClient>

=item * L<Google::Cloud::Compute::V1::RegionCommitmentsClient>

=item * L<Google::Cloud::Compute::V1::RegionCompositeHealthChecksClient>

=item * L<Google::Cloud::Compute::V1::RegionDiskTypesClient>

=item * L<Google::Cloud::Compute::V1::RegionDisksClient>

=item * L<Google::Cloud::Compute::V1::RegionHealthAggregationPoliciesClient>

=item * L<Google::Cloud::Compute::V1::RegionHealthCheckServicesClient>

=item * L<Google::Cloud::Compute::V1::RegionHealthChecksClient>

=item * L<Google::Cloud::Compute::V1::RegionHealthSourcesClient>

=item * L<Google::Cloud::Compute::V1::RegionInstanceGroupManagerResizeRequestsClient>

=item * L<Google::Cloud::Compute::V1::RegionInstanceGroupManagersClient>

=item * L<Google::Cloud::Compute::V1::RegionInstanceGroupsClient>

=item * L<Google::Cloud::Compute::V1::RegionInstanceTemplatesClient>

=item * L<Google::Cloud::Compute::V1::RegionInstancesClient>

=item * L<Google::Cloud::Compute::V1::RegionInstantSnapshotGroupsClient>

=item * L<Google::Cloud::Compute::V1::RegionInstantSnapshotsClient>

=item * L<Google::Cloud::Compute::V1::RegionNetworkEndpointGroupsClient>

=item * L<Google::Cloud::Compute::V1::RegionNetworkFirewallPoliciesClient>

=item * L<Google::Cloud::Compute::V1::RegionNotificationEndpointsClient>

=item * L<Google::Cloud::Compute::V1::RegionOperationsClient>

=item * L<Google::Cloud::Compute::V1::RegionSecurityPoliciesClient>

=item * L<Google::Cloud::Compute::V1::RegionSnapshotSettingsClient>

=item * L<Google::Cloud::Compute::V1::RegionSnapshotsClient>

=item * L<Google::Cloud::Compute::V1::RegionSslCertificatesClient>

=item * L<Google::Cloud::Compute::V1::RegionSslPoliciesClient>

=item * L<Google::Cloud::Compute::V1::RegionTargetHttpProxiesClient>

=item * L<Google::Cloud::Compute::V1::RegionTargetHttpsProxiesClient>

=item * L<Google::Cloud::Compute::V1::RegionTargetTcpProxiesClient>

=item * L<Google::Cloud::Compute::V1::RegionUrlMapsClient>

=item * L<Google::Cloud::Compute::V1::RegionZonesClient>

=item * L<Google::Cloud::Compute::V1::RegionsClient>

=item * L<Google::Cloud::Compute::V1::ReliabilityRisksClient>

=item * L<Google::Cloud::Compute::V1::ReservationBlocksClient>

=item * L<Google::Cloud::Compute::V1::ReservationSlotsClient>

=item * L<Google::Cloud::Compute::V1::ReservationSubBlocksClient>

=item * L<Google::Cloud::Compute::V1::ReservationsClient>

=item * L<Google::Cloud::Compute::V1::ResourcePoliciesClient>

=item * L<Google::Cloud::Compute::V1::RolloutPlansClient>

=item * L<Google::Cloud::Compute::V1::RolloutsClient>

=item * L<Google::Cloud::Compute::V1::RoutersClient>

=item * L<Google::Cloud::Compute::V1::RoutesClient>

=item * L<Google::Cloud::Compute::V1::SecurityPoliciesClient>

=item * L<Google::Cloud::Compute::V1::ServiceAttachmentsClient>

=item * L<Google::Cloud::Compute::V1::SnapshotSettingsServiceClient>

=item * L<Google::Cloud::Compute::V1::SnapshotsClient>

=item * L<Google::Cloud::Compute::V1::SslCertificatesClient>

=item * L<Google::Cloud::Compute::V1::SslPoliciesClient>

=item * L<Google::Cloud::Compute::V1::StoragePoolTypesClient>

=item * L<Google::Cloud::Compute::V1::StoragePoolsClient>

=item * L<Google::Cloud::Compute::V1::SubnetworksClient>

=item * L<Google::Cloud::Compute::V1::TargetGrpcProxiesClient>

=item * L<Google::Cloud::Compute::V1::TargetHttpProxiesClient>

=item * L<Google::Cloud::Compute::V1::TargetHttpsProxiesClient>

=item * L<Google::Cloud::Compute::V1::TargetInstancesClient>

=item * L<Google::Cloud::Compute::V1::TargetPoolsClient>

=item * L<Google::Cloud::Compute::V1::TargetSslProxiesClient>

=item * L<Google::Cloud::Compute::V1::TargetTcpProxiesClient>

=item * L<Google::Cloud::Compute::V1::TargetVpnGatewaysClient>

=item * L<Google::Cloud::Compute::V1::UrlMapsClient>

=item * L<Google::Cloud::Compute::V1::VpnGatewaysClient>

=item * L<Google::Cloud::Compute::V1::VpnTunnelsClient>

=item * L<Google::Cloud::Compute::V1::WireGroupsClient>

=item * L<Google::Cloud::Compute::V1::ZoneOperationsClient>

=item * L<Google::Cloud::Compute::V1::ZoneVmExtensionPoliciesClient>

=item * L<Google::Cloud::Compute::V1::ZonesClient>

=back

=head1 SEE ALSO

L<Google::Cloud::Compute::V1::AcceleratorTypesClient>, L<Google::Cloud::Compute::V1::AddressesClient>, L<Google::Cloud::Compute::V1::AdviceClient>, L<Google::Cloud::Compute::V1::AutoscalersClient>, L<Google::Cloud::Compute::V1::BackendBucketsClient>, L<Google::Cloud::Compute::V1::BackendServicesClient>, L<Google::Cloud::Compute::V1::CrossSiteNetworksClient>, L<Google::Cloud::Compute::V1::DiskTypesClient>, L<Google::Cloud::Compute::V1::DisksClient>, L<Google::Cloud::Compute::V1::ExternalVpnGatewaysClient>, L<Google::Cloud::Compute::V1::FirewallPoliciesClient>, L<Google::Cloud::Compute::V1::FirewallsClient>, L<Google::Cloud::Compute::V1::ForwardingRulesClient>, L<Google::Cloud::Compute::V1::FutureReservationsClient>, L<Google::Cloud::Compute::V1::GlobalAddressesClient>, L<Google::Cloud::Compute::V1::GlobalForwardingRulesClient>, L<Google::Cloud::Compute::V1::GlobalFrontendSettingsServiceClient>, L<Google::Cloud::Compute::V1::GlobalNetworkEndpointGroupsClient>, L<Google::Cloud::Compute::V1::GlobalOperationsClient>, L<Google::Cloud::Compute::V1::GlobalOrganizationOperationsClient>, L<Google::Cloud::Compute::V1::GlobalPublicDelegatedPrefixesClient>, L<Google::Cloud::Compute::V1::GlobalVmExtensionPoliciesClient>, L<Google::Cloud::Compute::V1::HealthChecksClient>, L<Google::Cloud::Compute::V1::HostsClient>, L<Google::Cloud::Compute::V1::ImageFamilyViewsClient>, L<Google::Cloud::Compute::V1::ImageViewsClient>, L<Google::Cloud::Compute::V1::ImagesClient>, L<Google::Cloud::Compute::V1::InstanceGroupManagerResizeRequestsClient>, L<Google::Cloud::Compute::V1::InstanceGroupManagersClient>, L<Google::Cloud::Compute::V1::InstanceGroupsClient>, L<Google::Cloud::Compute::V1::InstanceSettingsServiceClient>, L<Google::Cloud::Compute::V1::InstanceTemplatesClient>, L<Google::Cloud::Compute::V1::InstancesClient>, L<Google::Cloud::Compute::V1::InstantSnapshotGroupsClient>, L<Google::Cloud::Compute::V1::InstantSnapshotsClient>, L<Google::Cloud::Compute::V1::InterconnectAttachmentGroupsClient>, L<Google::Cloud::Compute::V1::InterconnectAttachmentsClient>, L<Google::Cloud::Compute::V1::InterconnectGroupsClient>, L<Google::Cloud::Compute::V1::InterconnectLocationsClient>, L<Google::Cloud::Compute::V1::InterconnectRemoteLocationsClient>, L<Google::Cloud::Compute::V1::InterconnectsClient>, L<Google::Cloud::Compute::V1::LicenseCodesClient>, L<Google::Cloud::Compute::V1::LicensesClient>, L<Google::Cloud::Compute::V1::MachineImagesClient>, L<Google::Cloud::Compute::V1::MachineTypesClient>, L<Google::Cloud::Compute::V1::ManagedRulesetsClient>, L<Google::Cloud::Compute::V1::NetworkAttachmentsClient>, L<Google::Cloud::Compute::V1::NetworkEdgeSecurityServicesClient>, L<Google::Cloud::Compute::V1::NetworkEndpointGroupsClient>, L<Google::Cloud::Compute::V1::NetworkFirewallPoliciesClient>, L<Google::Cloud::Compute::V1::NetworkProfilesClient>, L<Google::Cloud::Compute::V1::NetworksClient>, L<Google::Cloud::Compute::V1::NodeGroupsClient>, L<Google::Cloud::Compute::V1::NodeTemplatesClient>, L<Google::Cloud::Compute::V1::NodeTypesClient>, L<Google::Cloud::Compute::V1::OrganizationSecurityPoliciesClient>, L<Google::Cloud::Compute::V1::PacketMirroringsClient>, L<Google::Cloud::Compute::V1::PreviewFeaturesClient>, L<Google::Cloud::Compute::V1::ProjectViewsClient>, L<Google::Cloud::Compute::V1::ProjectsClient>, L<Google::Cloud::Compute::V1::PublicAdvertisedPrefixesClient>, L<Google::Cloud::Compute::V1::PublicDelegatedPrefixesClient>, L<Google::Cloud::Compute::V1::RegionAutoscalersClient>, L<Google::Cloud::Compute::V1::RegionBackendBucketsClient>, L<Google::Cloud::Compute::V1::RegionBackendServicesClient>, L<Google::Cloud::Compute::V1::RegionCommitmentsClient>, L<Google::Cloud::Compute::V1::RegionCompositeHealthChecksClient>, L<Google::Cloud::Compute::V1::RegionDiskTypesClient>, L<Google::Cloud::Compute::V1::RegionDisksClient>, L<Google::Cloud::Compute::V1::RegionHealthAggregationPoliciesClient>, L<Google::Cloud::Compute::V1::RegionHealthCheckServicesClient>, L<Google::Cloud::Compute::V1::RegionHealthChecksClient>, L<Google::Cloud::Compute::V1::RegionHealthSourcesClient>, L<Google::Cloud::Compute::V1::RegionInstanceGroupManagerResizeRequestsClient>, L<Google::Cloud::Compute::V1::RegionInstanceGroupManagersClient>, L<Google::Cloud::Compute::V1::RegionInstanceGroupsClient>, L<Google::Cloud::Compute::V1::RegionInstanceTemplatesClient>, L<Google::Cloud::Compute::V1::RegionInstancesClient>, L<Google::Cloud::Compute::V1::RegionInstantSnapshotGroupsClient>, L<Google::Cloud::Compute::V1::RegionInstantSnapshotsClient>, L<Google::Cloud::Compute::V1::RegionNetworkEndpointGroupsClient>, L<Google::Cloud::Compute::V1::RegionNetworkFirewallPoliciesClient>, L<Google::Cloud::Compute::V1::RegionNotificationEndpointsClient>, L<Google::Cloud::Compute::V1::RegionOperationsClient>, L<Google::Cloud::Compute::V1::RegionSecurityPoliciesClient>, L<Google::Cloud::Compute::V1::RegionSnapshotSettingsClient>, L<Google::Cloud::Compute::V1::RegionSnapshotsClient>, L<Google::Cloud::Compute::V1::RegionSslCertificatesClient>, L<Google::Cloud::Compute::V1::RegionSslPoliciesClient>, L<Google::Cloud::Compute::V1::RegionTargetHttpProxiesClient>, L<Google::Cloud::Compute::V1::RegionTargetHttpsProxiesClient>, L<Google::Cloud::Compute::V1::RegionTargetTcpProxiesClient>, L<Google::Cloud::Compute::V1::RegionUrlMapsClient>, L<Google::Cloud::Compute::V1::RegionZonesClient>, L<Google::Cloud::Compute::V1::RegionsClient>, L<Google::Cloud::Compute::V1::ReliabilityRisksClient>, L<Google::Cloud::Compute::V1::ReservationBlocksClient>, L<Google::Cloud::Compute::V1::ReservationSlotsClient>, L<Google::Cloud::Compute::V1::ReservationSubBlocksClient>, L<Google::Cloud::Compute::V1::ReservationsClient>, L<Google::Cloud::Compute::V1::ResourcePoliciesClient>, L<Google::Cloud::Compute::V1::RolloutPlansClient>, L<Google::Cloud::Compute::V1::RolloutsClient>, L<Google::Cloud::Compute::V1::RoutersClient>, L<Google::Cloud::Compute::V1::RoutesClient>, L<Google::Cloud::Compute::V1::SecurityPoliciesClient>, L<Google::Cloud::Compute::V1::ServiceAttachmentsClient>, L<Google::Cloud::Compute::V1::SnapshotSettingsServiceClient>, L<Google::Cloud::Compute::V1::SnapshotsClient>, L<Google::Cloud::Compute::V1::SslCertificatesClient>, L<Google::Cloud::Compute::V1::SslPoliciesClient>, L<Google::Cloud::Compute::V1::StoragePoolTypesClient>, L<Google::Cloud::Compute::V1::StoragePoolsClient>, L<Google::Cloud::Compute::V1::SubnetworksClient>, L<Google::Cloud::Compute::V1::TargetGrpcProxiesClient>, L<Google::Cloud::Compute::V1::TargetHttpProxiesClient>, L<Google::Cloud::Compute::V1::TargetHttpsProxiesClient>, L<Google::Cloud::Compute::V1::TargetInstancesClient>, L<Google::Cloud::Compute::V1::TargetPoolsClient>, L<Google::Cloud::Compute::V1::TargetSslProxiesClient>, L<Google::Cloud::Compute::V1::TargetTcpProxiesClient>, L<Google::Cloud::Compute::V1::TargetVpnGatewaysClient>, L<Google::Cloud::Compute::V1::UrlMapsClient>, L<Google::Cloud::Compute::V1::VpnGatewaysClient>, L<Google::Cloud::Compute::V1::VpnTunnelsClient>, L<Google::Cloud::Compute::V1::WireGroupsClient>, L<Google::Cloud::Compute::V1::ZoneOperationsClient>, L<Google::Cloud::Compute::V1::ZoneVmExtensionPoliciesClient>, L<Google::Cloud::Compute::V1::ZonesClient>

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/compute/v1/compute.proto>



=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
