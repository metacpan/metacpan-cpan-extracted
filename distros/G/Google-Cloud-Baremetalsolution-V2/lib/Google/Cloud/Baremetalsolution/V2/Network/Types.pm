package Google::Cloud::Baremetalsolution::V2::Network::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Network',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Network::Network'];

coerce 'Network',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Network::Network'->new($_) };

declare 'RepeatedNetwork',
    as ArrayRef[Network()];

coerce 'RepeatedNetwork',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Network::Network'->new($_) } @$_ ] };

declare 'MapStringNetwork',
    as HashRef[Network()];

declare 'Type',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Network::Network::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Network::Network::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Network::Network::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'NetworkAddressReservation',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Network::NetworkAddressReservation'];

coerce 'NetworkAddressReservation',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Network::NetworkAddressReservation'->new($_) };

declare 'RepeatedNetworkAddressReservation',
    as ArrayRef[NetworkAddressReservation()];

coerce 'RepeatedNetworkAddressReservation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Network::NetworkAddressReservation'->new($_) } @$_ ] };

declare 'MapStringNetworkAddressReservation',
    as HashRef[NetworkAddressReservation()];

declare 'VRF',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Network::VRF'];

coerce 'VRF',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Network::VRF'->new($_) };

declare 'RepeatedVRF',
    as ArrayRef[VRF()];

coerce 'RepeatedVRF',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Network::VRF'->new($_) } @$_ ] };

declare 'MapStringVRF',
    as HashRef[VRF()];

declare 'State',
    as (Int | Str);

declare 'QosPolicy',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Network::VRF::QosPolicy'];

coerce 'QosPolicy',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Network::VRF::QosPolicy'->new($_) };

declare 'RepeatedQosPolicy',
    as ArrayRef[QosPolicy()];

coerce 'RepeatedQosPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Network::VRF::QosPolicy'->new($_) } @$_ ] };

declare 'MapStringQosPolicy',
    as HashRef[QosPolicy()];

declare 'VlanAttachment',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Network::VRF::VlanAttachment'];

coerce 'VlanAttachment',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Network::VRF::VlanAttachment'->new($_) };

declare 'RepeatedVlanAttachment',
    as ArrayRef[VlanAttachment()];

coerce 'RepeatedVlanAttachment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Network::VRF::VlanAttachment'->new($_) } @$_ ] };

declare 'MapStringVlanAttachment',
    as HashRef[VlanAttachment()];

declare 'LogicalInterface',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Network::LogicalInterface'];

coerce 'LogicalInterface',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Network::LogicalInterface'->new($_) };

declare 'RepeatedLogicalInterface',
    as ArrayRef[LogicalInterface()];

coerce 'RepeatedLogicalInterface',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Network::LogicalInterface'->new($_) } @$_ ] };

declare 'MapStringLogicalInterface',
    as HashRef[LogicalInterface()];

declare 'LogicalNetworkInterface',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Network::LogicalInterface::LogicalNetworkInterface'];

coerce 'LogicalNetworkInterface',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Network::LogicalInterface::LogicalNetworkInterface'->new($_) };

declare 'RepeatedLogicalNetworkInterface',
    as ArrayRef[LogicalNetworkInterface()];

coerce 'RepeatedLogicalNetworkInterface',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Network::LogicalInterface::LogicalNetworkInterface'->new($_) } @$_ ] };

declare 'MapStringLogicalNetworkInterface',
    as HashRef[LogicalNetworkInterface()];

declare 'GetNetworkRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Network::GetNetworkRequest'];

coerce 'GetNetworkRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Network::GetNetworkRequest'->new($_) };

declare 'RepeatedGetNetworkRequest',
    as ArrayRef[GetNetworkRequest()];

coerce 'RepeatedGetNetworkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Network::GetNetworkRequest'->new($_) } @$_ ] };

declare 'MapStringGetNetworkRequest',
    as HashRef[GetNetworkRequest()];

declare 'ListNetworksRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Network::ListNetworksRequest'];

coerce 'ListNetworksRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Network::ListNetworksRequest'->new($_) };

declare 'RepeatedListNetworksRequest',
    as ArrayRef[ListNetworksRequest()];

coerce 'RepeatedListNetworksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Network::ListNetworksRequest'->new($_) } @$_ ] };

declare 'MapStringListNetworksRequest',
    as HashRef[ListNetworksRequest()];

declare 'ListNetworksResponse',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Network::ListNetworksResponse'];

coerce 'ListNetworksResponse',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Network::ListNetworksResponse'->new($_) };

declare 'RepeatedListNetworksResponse',
    as ArrayRef[ListNetworksResponse()];

coerce 'RepeatedListNetworksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Network::ListNetworksResponse'->new($_) } @$_ ] };

declare 'MapStringListNetworksResponse',
    as HashRef[ListNetworksResponse()];

declare 'UpdateNetworkRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Network::UpdateNetworkRequest'];

coerce 'UpdateNetworkRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Network::UpdateNetworkRequest'->new($_) };

declare 'RepeatedUpdateNetworkRequest',
    as ArrayRef[UpdateNetworkRequest()];

coerce 'RepeatedUpdateNetworkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Network::UpdateNetworkRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateNetworkRequest',
    as HashRef[UpdateNetworkRequest()];

declare 'NetworkUsage',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Network::NetworkUsage'];

coerce 'NetworkUsage',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Network::NetworkUsage'->new($_) };

declare 'RepeatedNetworkUsage',
    as ArrayRef[NetworkUsage()];

coerce 'RepeatedNetworkUsage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Network::NetworkUsage'->new($_) } @$_ ] };

declare 'MapStringNetworkUsage',
    as HashRef[NetworkUsage()];

declare 'ListNetworkUsageRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Network::ListNetworkUsageRequest'];

coerce 'ListNetworkUsageRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Network::ListNetworkUsageRequest'->new($_) };

declare 'RepeatedListNetworkUsageRequest',
    as ArrayRef[ListNetworkUsageRequest()];

coerce 'RepeatedListNetworkUsageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Network::ListNetworkUsageRequest'->new($_) } @$_ ] };

declare 'MapStringListNetworkUsageRequest',
    as HashRef[ListNetworkUsageRequest()];

declare 'ListNetworkUsageResponse',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Network::ListNetworkUsageResponse'];

coerce 'ListNetworkUsageResponse',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Network::ListNetworkUsageResponse'->new($_) };

declare 'RepeatedListNetworkUsageResponse',
    as ArrayRef[ListNetworkUsageResponse()];

coerce 'RepeatedListNetworkUsageResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Network::ListNetworkUsageResponse'->new($_) } @$_ ] };

declare 'MapStringListNetworkUsageResponse',
    as HashRef[ListNetworkUsageResponse()];

declare 'NetworkMountPoint',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Network::NetworkMountPoint'];

coerce 'NetworkMountPoint',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Network::NetworkMountPoint'->new($_) };

declare 'RepeatedNetworkMountPoint',
    as ArrayRef[NetworkMountPoint()];

coerce 'RepeatedNetworkMountPoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Network::NetworkMountPoint'->new($_) } @$_ ] };

declare 'MapStringNetworkMountPoint',
    as HashRef[NetworkMountPoint()];

declare 'RenameNetworkRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Network::RenameNetworkRequest'];

coerce 'RenameNetworkRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Network::RenameNetworkRequest'->new($_) };

declare 'RepeatedRenameNetworkRequest',
    as ArrayRef[RenameNetworkRequest()];

coerce 'RepeatedRenameNetworkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Network::RenameNetworkRequest'->new($_) } @$_ ] };

declare 'MapStringRenameNetworkRequest',
    as HashRef[RenameNetworkRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Baremetalsolution::V2::Network::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
