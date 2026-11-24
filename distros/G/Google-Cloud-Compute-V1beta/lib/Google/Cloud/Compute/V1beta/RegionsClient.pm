package Google::Cloud::Compute::V1beta::RegionsClient;

use strict;
use warnings;

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Compute::V1beta::Compute;

our $VERSION = '0.06';
1; # End of Google::Cloud::Compute::V1beta::RegionsClient

__END__

=head1 NAME

Google::Cloud::Compute::V1beta::RegionsClient - Auto-generated Protocol Buffers schema container

=head1 DESCRIPTION

This is an auto-generated Protocol Buffers schema container module for Google Cloud Services.

=head1 SYNOPSIS

    use Google::Cloud::Compute::V1beta::AcceleratorTypesClient;

    my $client = Google::Cloud::Compute::V1beta::AcceleratorTypesClient->new();

=head1 CLIENTS

This distribution provides the following service client classes:

=over 4

=item * L<Google::Cloud::Compute::V1beta::AcceleratorTypesClient>

=item * L<Google::Cloud::Compute::V1beta::AddressesClient>

=item * L<Google::Cloud::Compute::V1beta::AdviceClient>

=item * L<Google::Cloud::Compute::V1beta::AutoscalersClient>

=item * L<Google::Cloud::Compute::V1beta::BackendBucketsClient>

=item * L<Google::Cloud::Compute::V1beta::BackendServicesClient>

=item * L<Google::Cloud::Compute::V1beta::CrossSiteNetworksClient>

=item * L<Google::Cloud::Compute::V1beta::DhcpOptionsConfigsClient>

=item * L<Google::Cloud::Compute::V1beta::DiskSettingsServiceClient>

=item * L<Google::Cloud::Compute::V1beta::DiskTypesClient>

=item * L<Google::Cloud::Compute::V1beta::DisksClient>

=item * L<Google::Cloud::Compute::V1beta::ExternalVpnGatewaysClient>

=item * L<Google::Cloud::Compute::V1beta::FirewallPoliciesClient>

=item * L<Google::Cloud::Compute::V1beta::FirewallsClient>

=item * L<Google::Cloud::Compute::V1beta::ForwardingRulesClient>

=item * L<Google::Cloud::Compute::V1beta::FutureReservationsClient>

=item * L<Google::Cloud::Compute::V1beta::GlobalAddressesClient>

=item * L<Google::Cloud::Compute::V1beta::GlobalForwardingRulesClient>

=item * L<Google::Cloud::Compute::V1beta::GlobalFrontendSettingsServiceClient>

=item * L<Google::Cloud::Compute::V1beta::GlobalNetworkEndpointGroupsClient>

=item * L<Google::Cloud::Compute::V1beta::GlobalOperationsClient>

=item * L<Google::Cloud::Compute::V1beta::GlobalOrganizationOperationsClient>

=item * L<Google::Cloud::Compute::V1beta::GlobalPublicDelegatedPrefixesClient>

=item * L<Google::Cloud::Compute::V1beta::GlobalVmExtensionPoliciesClient>

=item * L<Google::Cloud::Compute::V1beta::HealthChecksClient>

=item * L<Google::Cloud::Compute::V1beta::HostsClient>

=item * L<Google::Cloud::Compute::V1beta::ImageFamilyViewsClient>

=item * L<Google::Cloud::Compute::V1beta::ImageViewsClient>

=item * L<Google::Cloud::Compute::V1beta::ImagesClient>

=item * L<Google::Cloud::Compute::V1beta::InstanceGroupManagerResizeRequestsClient>

=item * L<Google::Cloud::Compute::V1beta::InstanceGroupManagersClient>

=item * L<Google::Cloud::Compute::V1beta::InstanceGroupsClient>

=item * L<Google::Cloud::Compute::V1beta::InstanceSettingsServiceClient>

=item * L<Google::Cloud::Compute::V1beta::InstanceTemplatesClient>

=item * L<Google::Cloud::Compute::V1beta::InstancesClient>

=item * L<Google::Cloud::Compute::V1beta::InstantSnapshotGroupsClient>

=item * L<Google::Cloud::Compute::V1beta::InstantSnapshotsClient>

=item * L<Google::Cloud::Compute::V1beta::InterconnectAttachmentGroupsClient>

=item * L<Google::Cloud::Compute::V1beta::InterconnectAttachmentsClient>

=item * L<Google::Cloud::Compute::V1beta::InterconnectGroupsClient>

=item * L<Google::Cloud::Compute::V1beta::InterconnectLocationsClient>

=item * L<Google::Cloud::Compute::V1beta::InterconnectRemoteLocationsClient>

=item * L<Google::Cloud::Compute::V1beta::InterconnectsClient>

=item * L<Google::Cloud::Compute::V1beta::LicenseCodesClient>

=item * L<Google::Cloud::Compute::V1beta::LicensesClient>

=item * L<Google::Cloud::Compute::V1beta::MachineImagesClient>

=item * L<Google::Cloud::Compute::V1beta::MachineTypesClient>

=item * L<Google::Cloud::Compute::V1beta::ManagedRulesetsClient>

=item * L<Google::Cloud::Compute::V1beta::NetworkAttachmentsClient>

=item * L<Google::Cloud::Compute::V1beta::NetworkEdgeSecurityServicesClient>

=item * L<Google::Cloud::Compute::V1beta::NetworkEndpointGroupsClient>

=item * L<Google::Cloud::Compute::V1beta::NetworkFirewallPoliciesClient>

=item * L<Google::Cloud::Compute::V1beta::NetworkProfilesClient>

=item * L<Google::Cloud::Compute::V1beta::NetworksClient>

=item * L<Google::Cloud::Compute::V1beta::NodeGroupsClient>

=item * L<Google::Cloud::Compute::V1beta::NodeTemplatesClient>

=item * L<Google::Cloud::Compute::V1beta::NodeTypesClient>

=item * L<Google::Cloud::Compute::V1beta::OrganizationRolloutPlansClient>

=item * L<Google::Cloud::Compute::V1beta::OrganizationRolloutsClient>

=item * L<Google::Cloud::Compute::V1beta::OrganizationSecurityPoliciesClient>

=item * L<Google::Cloud::Compute::V1beta::OrganizationSnapshotRecycleBinPolicyClient>

=item * L<Google::Cloud::Compute::V1beta::PacketMirroringsClient>

=item * L<Google::Cloud::Compute::V1beta::PreviewFeaturesClient>

=item * L<Google::Cloud::Compute::V1beta::ProjectViewsClient>

=item * L<Google::Cloud::Compute::V1beta::ProjectsClient>

=item * L<Google::Cloud::Compute::V1beta::PublicAdvertisedPrefixesClient>

=item * L<Google::Cloud::Compute::V1beta::PublicDelegatedPrefixesClient>

=item * L<Google::Cloud::Compute::V1beta::RecoverableSnapshotsClient>

=item * L<Google::Cloud::Compute::V1beta::RegionAutoscalersClient>

=item * L<Google::Cloud::Compute::V1beta::RegionBackendBucketsClient>

=item * L<Google::Cloud::Compute::V1beta::RegionBackendServicesClient>

=item * L<Google::Cloud::Compute::V1beta::RegionCommitmentsClient>

=item * L<Google::Cloud::Compute::V1beta::RegionCompositeHealthChecksClient>

=item * L<Google::Cloud::Compute::V1beta::RegionDiskSettingsClient>

=item * L<Google::Cloud::Compute::V1beta::RegionDiskTypesClient>

=item * L<Google::Cloud::Compute::V1beta::RegionDisksClient>

=item * L<Google::Cloud::Compute::V1beta::RegionHealthAggregationPoliciesClient>

=item * L<Google::Cloud::Compute::V1beta::RegionHealthCheckServicesClient>

=item * L<Google::Cloud::Compute::V1beta::RegionHealthChecksClient>

=item * L<Google::Cloud::Compute::V1beta::RegionHealthSourcesClient>

=item * L<Google::Cloud::Compute::V1beta::RegionInstanceGroupManagerResizeRequestsClient>

=item * L<Google::Cloud::Compute::V1beta::RegionInstanceGroupManagersClient>

=item * L<Google::Cloud::Compute::V1beta::RegionInstanceGroupsClient>

=item * L<Google::Cloud::Compute::V1beta::RegionInstanceTemplatesClient>

=item * L<Google::Cloud::Compute::V1beta::RegionInstancesClient>

=item * L<Google::Cloud::Compute::V1beta::RegionInstantSnapshotGroupsClient>

=item * L<Google::Cloud::Compute::V1beta::RegionInstantSnapshotsClient>

=item * L<Google::Cloud::Compute::V1beta::RegionMultiMigMembersClient>

=item * L<Google::Cloud::Compute::V1beta::RegionMultiMigsClient>

=item * L<Google::Cloud::Compute::V1beta::RegionNetworkEndpointGroupsClient>

=item * L<Google::Cloud::Compute::V1beta::RegionNetworkFirewallPoliciesClient>

=item * L<Google::Cloud::Compute::V1beta::RegionNetworkPoliciesClient>

=item * L<Google::Cloud::Compute::V1beta::RegionNotificationEndpointsClient>

=item * L<Google::Cloud::Compute::V1beta::RegionOperationsClient>

=item * L<Google::Cloud::Compute::V1beta::RegionSecurityPoliciesClient>

=item * L<Google::Cloud::Compute::V1beta::RegionSnapshotSettingsClient>

=item * L<Google::Cloud::Compute::V1beta::RegionSnapshotsClient>

=item * L<Google::Cloud::Compute::V1beta::RegionSslCertificatesClient>

=item * L<Google::Cloud::Compute::V1beta::RegionSslPoliciesClient>

=item * L<Google::Cloud::Compute::V1beta::RegionTargetHttpProxiesClient>

=item * L<Google::Cloud::Compute::V1beta::RegionTargetHttpsProxiesClient>

=item * L<Google::Cloud::Compute::V1beta::RegionTargetTcpProxiesClient>

=item * L<Google::Cloud::Compute::V1beta::RegionUrlMapsClient>

=item * L<Google::Cloud::Compute::V1beta::RegionZonesClient>

=item * L<Google::Cloud::Compute::V1beta::RegionsClient>

=item * L<Google::Cloud::Compute::V1beta::ReliabilityRisksClient>

=item * L<Google::Cloud::Compute::V1beta::ReservationBlocksClient>

=item * L<Google::Cloud::Compute::V1beta::ReservationSlotsClient>

=item * L<Google::Cloud::Compute::V1beta::ReservationSubBlocksClient>

=item * L<Google::Cloud::Compute::V1beta::ReservationsClient>

=item * L<Google::Cloud::Compute::V1beta::ResourcePoliciesClient>

=item * L<Google::Cloud::Compute::V1beta::RolloutPlansClient>

=item * L<Google::Cloud::Compute::V1beta::RolloutsClient>

=item * L<Google::Cloud::Compute::V1beta::RoutersClient>

=item * L<Google::Cloud::Compute::V1beta::RoutesClient>

=item * L<Google::Cloud::Compute::V1beta::SecurityPoliciesClient>

=item * L<Google::Cloud::Compute::V1beta::ServiceAttachmentsClient>

=item * L<Google::Cloud::Compute::V1beta::SnapshotGroupsClient>

=item * L<Google::Cloud::Compute::V1beta::SnapshotRecycleBinPolicyServiceClient>

=item * L<Google::Cloud::Compute::V1beta::SnapshotSettingsServiceClient>

=item * L<Google::Cloud::Compute::V1beta::SnapshotsClient>

=item * L<Google::Cloud::Compute::V1beta::SslCertificatesClient>

=item * L<Google::Cloud::Compute::V1beta::SslPoliciesClient>

=item * L<Google::Cloud::Compute::V1beta::StoragePoolTypesClient>

=item * L<Google::Cloud::Compute::V1beta::StoragePoolsClient>

=item * L<Google::Cloud::Compute::V1beta::SubnetworksClient>

=item * L<Google::Cloud::Compute::V1beta::TargetGrpcProxiesClient>

=item * L<Google::Cloud::Compute::V1beta::TargetHttpProxiesClient>

=item * L<Google::Cloud::Compute::V1beta::TargetHttpsProxiesClient>

=item * L<Google::Cloud::Compute::V1beta::TargetInstancesClient>

=item * L<Google::Cloud::Compute::V1beta::TargetPoolsClient>

=item * L<Google::Cloud::Compute::V1beta::TargetSslProxiesClient>

=item * L<Google::Cloud::Compute::V1beta::TargetTcpProxiesClient>

=item * L<Google::Cloud::Compute::V1beta::TargetVpnGatewaysClient>

=item * L<Google::Cloud::Compute::V1beta::UrlMapsClient>

=item * L<Google::Cloud::Compute::V1beta::VpnGatewaysClient>

=item * L<Google::Cloud::Compute::V1beta::VpnTunnelsClient>

=item * L<Google::Cloud::Compute::V1beta::WireGroupsClient>

=item * L<Google::Cloud::Compute::V1beta::ZoneOperationsClient>

=item * L<Google::Cloud::Compute::V1beta::ZoneVmExtensionPoliciesClient>

=item * L<Google::Cloud::Compute::V1beta::ZonesClient>

=back

=head1 SEE ALSO

L<Google::Cloud::Compute::V1beta::AcceleratorTypesClient>, L<Google::Cloud::Compute::V1beta::AddressesClient>, L<Google::Cloud::Compute::V1beta::AdviceClient>, L<Google::Cloud::Compute::V1beta::AutoscalersClient>, L<Google::Cloud::Compute::V1beta::BackendBucketsClient>, L<Google::Cloud::Compute::V1beta::BackendServicesClient>, L<Google::Cloud::Compute::V1beta::CrossSiteNetworksClient>, L<Google::Cloud::Compute::V1beta::DhcpOptionsConfigsClient>, L<Google::Cloud::Compute::V1beta::DiskSettingsServiceClient>, L<Google::Cloud::Compute::V1beta::DiskTypesClient>, L<Google::Cloud::Compute::V1beta::DisksClient>, L<Google::Cloud::Compute::V1beta::ExternalVpnGatewaysClient>, L<Google::Cloud::Compute::V1beta::FirewallPoliciesClient>, L<Google::Cloud::Compute::V1beta::FirewallsClient>, L<Google::Cloud::Compute::V1beta::ForwardingRulesClient>, L<Google::Cloud::Compute::V1beta::FutureReservationsClient>, L<Google::Cloud::Compute::V1beta::GlobalAddressesClient>, L<Google::Cloud::Compute::V1beta::GlobalForwardingRulesClient>, L<Google::Cloud::Compute::V1beta::GlobalFrontendSettingsServiceClient>, L<Google::Cloud::Compute::V1beta::GlobalNetworkEndpointGroupsClient>, L<Google::Cloud::Compute::V1beta::GlobalOperationsClient>, L<Google::Cloud::Compute::V1beta::GlobalOrganizationOperationsClient>, L<Google::Cloud::Compute::V1beta::GlobalPublicDelegatedPrefixesClient>, L<Google::Cloud::Compute::V1beta::GlobalVmExtensionPoliciesClient>, L<Google::Cloud::Compute::V1beta::HealthChecksClient>, L<Google::Cloud::Compute::V1beta::HostsClient>, L<Google::Cloud::Compute::V1beta::ImageFamilyViewsClient>, L<Google::Cloud::Compute::V1beta::ImageViewsClient>, L<Google::Cloud::Compute::V1beta::ImagesClient>, L<Google::Cloud::Compute::V1beta::InstanceGroupManagerResizeRequestsClient>, L<Google::Cloud::Compute::V1beta::InstanceGroupManagersClient>, L<Google::Cloud::Compute::V1beta::InstanceGroupsClient>, L<Google::Cloud::Compute::V1beta::InstanceSettingsServiceClient>, L<Google::Cloud::Compute::V1beta::InstanceTemplatesClient>, L<Google::Cloud::Compute::V1beta::InstancesClient>, L<Google::Cloud::Compute::V1beta::InstantSnapshotGroupsClient>, L<Google::Cloud::Compute::V1beta::InstantSnapshotsClient>, L<Google::Cloud::Compute::V1beta::InterconnectAttachmentGroupsClient>, L<Google::Cloud::Compute::V1beta::InterconnectAttachmentsClient>, L<Google::Cloud::Compute::V1beta::InterconnectGroupsClient>, L<Google::Cloud::Compute::V1beta::InterconnectLocationsClient>, L<Google::Cloud::Compute::V1beta::InterconnectRemoteLocationsClient>, L<Google::Cloud::Compute::V1beta::InterconnectsClient>, L<Google::Cloud::Compute::V1beta::LicenseCodesClient>, L<Google::Cloud::Compute::V1beta::LicensesClient>, L<Google::Cloud::Compute::V1beta::MachineImagesClient>, L<Google::Cloud::Compute::V1beta::MachineTypesClient>, L<Google::Cloud::Compute::V1beta::ManagedRulesetsClient>, L<Google::Cloud::Compute::V1beta::NetworkAttachmentsClient>, L<Google::Cloud::Compute::V1beta::NetworkEdgeSecurityServicesClient>, L<Google::Cloud::Compute::V1beta::NetworkEndpointGroupsClient>, L<Google::Cloud::Compute::V1beta::NetworkFirewallPoliciesClient>, L<Google::Cloud::Compute::V1beta::NetworkProfilesClient>, L<Google::Cloud::Compute::V1beta::NetworksClient>, L<Google::Cloud::Compute::V1beta::NodeGroupsClient>, L<Google::Cloud::Compute::V1beta::NodeTemplatesClient>, L<Google::Cloud::Compute::V1beta::NodeTypesClient>, L<Google::Cloud::Compute::V1beta::OrganizationRolloutPlansClient>, L<Google::Cloud::Compute::V1beta::OrganizationRolloutsClient>, L<Google::Cloud::Compute::V1beta::OrganizationSecurityPoliciesClient>, L<Google::Cloud::Compute::V1beta::OrganizationSnapshotRecycleBinPolicyClient>, L<Google::Cloud::Compute::V1beta::PacketMirroringsClient>, L<Google::Cloud::Compute::V1beta::PreviewFeaturesClient>, L<Google::Cloud::Compute::V1beta::ProjectViewsClient>, L<Google::Cloud::Compute::V1beta::ProjectsClient>, L<Google::Cloud::Compute::V1beta::PublicAdvertisedPrefixesClient>, L<Google::Cloud::Compute::V1beta::PublicDelegatedPrefixesClient>, L<Google::Cloud::Compute::V1beta::RecoverableSnapshotsClient>, L<Google::Cloud::Compute::V1beta::RegionAutoscalersClient>, L<Google::Cloud::Compute::V1beta::RegionBackendBucketsClient>, L<Google::Cloud::Compute::V1beta::RegionBackendServicesClient>, L<Google::Cloud::Compute::V1beta::RegionCommitmentsClient>, L<Google::Cloud::Compute::V1beta::RegionCompositeHealthChecksClient>, L<Google::Cloud::Compute::V1beta::RegionDiskSettingsClient>, L<Google::Cloud::Compute::V1beta::RegionDiskTypesClient>, L<Google::Cloud::Compute::V1beta::RegionDisksClient>, L<Google::Cloud::Compute::V1beta::RegionHealthAggregationPoliciesClient>, L<Google::Cloud::Compute::V1beta::RegionHealthCheckServicesClient>, L<Google::Cloud::Compute::V1beta::RegionHealthChecksClient>, L<Google::Cloud::Compute::V1beta::RegionHealthSourcesClient>, L<Google::Cloud::Compute::V1beta::RegionInstanceGroupManagerResizeRequestsClient>, L<Google::Cloud::Compute::V1beta::RegionInstanceGroupManagersClient>, L<Google::Cloud::Compute::V1beta::RegionInstanceGroupsClient>, L<Google::Cloud::Compute::V1beta::RegionInstanceTemplatesClient>, L<Google::Cloud::Compute::V1beta::RegionInstancesClient>, L<Google::Cloud::Compute::V1beta::RegionInstantSnapshotGroupsClient>, L<Google::Cloud::Compute::V1beta::RegionInstantSnapshotsClient>, L<Google::Cloud::Compute::V1beta::RegionMultiMigMembersClient>, L<Google::Cloud::Compute::V1beta::RegionMultiMigsClient>, L<Google::Cloud::Compute::V1beta::RegionNetworkEndpointGroupsClient>, L<Google::Cloud::Compute::V1beta::RegionNetworkFirewallPoliciesClient>, L<Google::Cloud::Compute::V1beta::RegionNetworkPoliciesClient>, L<Google::Cloud::Compute::V1beta::RegionNotificationEndpointsClient>, L<Google::Cloud::Compute::V1beta::RegionOperationsClient>, L<Google::Cloud::Compute::V1beta::RegionSecurityPoliciesClient>, L<Google::Cloud::Compute::V1beta::RegionSnapshotSettingsClient>, L<Google::Cloud::Compute::V1beta::RegionSnapshotsClient>, L<Google::Cloud::Compute::V1beta::RegionSslCertificatesClient>, L<Google::Cloud::Compute::V1beta::RegionSslPoliciesClient>, L<Google::Cloud::Compute::V1beta::RegionTargetHttpProxiesClient>, L<Google::Cloud::Compute::V1beta::RegionTargetHttpsProxiesClient>, L<Google::Cloud::Compute::V1beta::RegionTargetTcpProxiesClient>, L<Google::Cloud::Compute::V1beta::RegionUrlMapsClient>, L<Google::Cloud::Compute::V1beta::RegionZonesClient>, L<Google::Cloud::Compute::V1beta::RegionsClient>, L<Google::Cloud::Compute::V1beta::ReliabilityRisksClient>, L<Google::Cloud::Compute::V1beta::ReservationBlocksClient>, L<Google::Cloud::Compute::V1beta::ReservationSlotsClient>, L<Google::Cloud::Compute::V1beta::ReservationSubBlocksClient>, L<Google::Cloud::Compute::V1beta::ReservationsClient>, L<Google::Cloud::Compute::V1beta::ResourcePoliciesClient>, L<Google::Cloud::Compute::V1beta::RolloutPlansClient>, L<Google::Cloud::Compute::V1beta::RolloutsClient>, L<Google::Cloud::Compute::V1beta::RoutersClient>, L<Google::Cloud::Compute::V1beta::RoutesClient>, L<Google::Cloud::Compute::V1beta::SecurityPoliciesClient>, L<Google::Cloud::Compute::V1beta::ServiceAttachmentsClient>, L<Google::Cloud::Compute::V1beta::SnapshotGroupsClient>, L<Google::Cloud::Compute::V1beta::SnapshotRecycleBinPolicyServiceClient>, L<Google::Cloud::Compute::V1beta::SnapshotSettingsServiceClient>, L<Google::Cloud::Compute::V1beta::SnapshotsClient>, L<Google::Cloud::Compute::V1beta::SslCertificatesClient>, L<Google::Cloud::Compute::V1beta::SslPoliciesClient>, L<Google::Cloud::Compute::V1beta::StoragePoolTypesClient>, L<Google::Cloud::Compute::V1beta::StoragePoolsClient>, L<Google::Cloud::Compute::V1beta::SubnetworksClient>, L<Google::Cloud::Compute::V1beta::TargetGrpcProxiesClient>, L<Google::Cloud::Compute::V1beta::TargetHttpProxiesClient>, L<Google::Cloud::Compute::V1beta::TargetHttpsProxiesClient>, L<Google::Cloud::Compute::V1beta::TargetInstancesClient>, L<Google::Cloud::Compute::V1beta::TargetPoolsClient>, L<Google::Cloud::Compute::V1beta::TargetSslProxiesClient>, L<Google::Cloud::Compute::V1beta::TargetTcpProxiesClient>, L<Google::Cloud::Compute::V1beta::TargetVpnGatewaysClient>, L<Google::Cloud::Compute::V1beta::UrlMapsClient>, L<Google::Cloud::Compute::V1beta::VpnGatewaysClient>, L<Google::Cloud::Compute::V1beta::VpnTunnelsClient>, L<Google::Cloud::Compute::V1beta::WireGroupsClient>, L<Google::Cloud::Compute::V1beta::ZoneOperationsClient>, L<Google::Cloud::Compute::V1beta::ZoneVmExtensionPoliciesClient>, L<Google::Cloud::Compute::V1beta::ZonesClient>

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/compute/v1beta/compute.proto>



=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
