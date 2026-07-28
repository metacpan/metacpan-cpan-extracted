#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 125;

sub not_in_file_ok {
    my ($filename, %regex) = @_;
    open( my $fh, '<', $filename )
        or die "couldn't open $filename for reading: $!";

    my %violated;

    while (my $line = <$fh>) {
        while (my ($desc, $regex) = each %regex) {
            if ($line =~ $regex) {
                push @{$violated{$desc}||=[]}, $.;
            }
        }
    }

    if (%violated) {
        fail("$filename contains boilerplate text");
        diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
    } else {
        pass("$filename contains no boilerplate text");
    }
}

sub module_boilerplate_ok {
    my ($module) = @_;
    not_in_file_ok($module =>
        'the great new $MODULENAME'   => qr/ - The great new /,
        'boilerplate description'     => qr/Quick summary of what the module/,
        'stub function definition'    => qr/function[12]/,
    );
}

TODO: {
  local $TODO = "Need to replace the boilerplate text";

  not_in_file_ok(README =>
    "The README is used..."       => qr/The README is used/,
    "'version information here'"  => qr/to provide version information/,
  );

  not_in_file_ok(Changes =>
    "placeholder date/time"       => qr(Date/time)
  );

  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/AcceleratorTypesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/AddressesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/AdviceClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/AutoscalersClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/BackendBucketsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/BackendServicesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/CrossSiteNetworksClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/DiskTypesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/DisksClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/ExternalVpnGatewaysClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/FirewallPoliciesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/FirewallsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/ForwardingRulesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/FutureReservationsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/GlobalAddressesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/GlobalForwardingRulesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/GlobalNetworkEndpointGroupsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/GlobalOperationsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/GlobalOrganizationOperationsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/GlobalPublicDelegatedPrefixesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/GlobalVmExtensionPoliciesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/HealthChecksClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/ImageFamilyViewsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/ImagesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/InstanceGroupManagerResizeRequestsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/InstanceGroupManagersClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/InstanceGroupsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/InstanceSettingsServiceClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/InstanceTemplatesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/InstancesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/InstantSnapshotGroupsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/InstantSnapshotsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/InterconnectAttachmentGroupsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/InterconnectAttachmentsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/InterconnectGroupsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/InterconnectLocationsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/InterconnectRemoteLocationsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/InterconnectsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/LicenseCodesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/LicensesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/MachineImagesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/MachineTypesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/NetworkAttachmentsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/NetworkEdgeSecurityServicesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/NetworkEndpointGroupsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/NetworkFirewallPoliciesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/NetworkProfilesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/NetworksClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/NodeGroupsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/NodeTemplatesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/NodeTypesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/OrganizationSecurityPoliciesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/PacketMirroringsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/PreviewFeaturesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/ProjectsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/PublicAdvertisedPrefixesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/PublicDelegatedPrefixesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RegionAutoscalersClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RegionBackendBucketsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RegionBackendServicesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RegionCommitmentsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RegionCompositeHealthChecksClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RegionDiskTypesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RegionDisksClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RegionHealthAggregationPoliciesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RegionHealthCheckServicesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RegionHealthChecksClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RegionHealthSourcesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RegionInstanceGroupManagerResizeRequestsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RegionInstanceGroupManagersClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RegionInstanceGroupsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RegionInstanceTemplatesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RegionInstancesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RegionInstantSnapshotGroupsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RegionInstantSnapshotsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RegionNetworkEndpointGroupsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RegionNetworkFirewallPoliciesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RegionNotificationEndpointsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RegionOperationsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RegionSecurityPoliciesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RegionSnapshotSettingsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RegionSnapshotsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RegionSslCertificatesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RegionSslPoliciesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RegionTargetHttpProxiesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RegionTargetHttpsProxiesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RegionTargetTcpProxiesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RegionUrlMapsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RegionZonesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RegionsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/ReservationBlocksClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/ReservationSlotsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/ReservationSubBlocksClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/ReservationsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/ResourcePoliciesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RolloutPlansClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RolloutsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RoutersClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/RoutesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/SecurityPoliciesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/ServiceAttachmentsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/SnapshotSettingsServiceClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/SnapshotsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/SslCertificatesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/SslPoliciesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/StoragePoolTypesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/StoragePoolsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/SubnetworksClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/TargetGrpcProxiesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/TargetHttpProxiesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/TargetHttpsProxiesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/TargetInstancesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/TargetPoolsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/TargetSslProxiesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/TargetTcpProxiesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/TargetVpnGatewaysClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/UrlMapsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/VpnGatewaysClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/VpnTunnelsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/WireGroupsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/ZoneOperationsClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/ZoneVmExtensionPoliciesClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Compute/V1/ZonesClient.pm');


}

