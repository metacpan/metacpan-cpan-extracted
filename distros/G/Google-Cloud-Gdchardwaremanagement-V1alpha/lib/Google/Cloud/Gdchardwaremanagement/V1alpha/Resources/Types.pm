package Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PowerSupply',
    as (Int | Str);

declare 'Entity',
    as (Int | Str);

declare 'Order',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Order'];

coerce 'Order',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Order'->new($_) };

declare 'RepeatedOrder',
    as ArrayRef[Order()];

coerce 'RepeatedOrder',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Order'->new($_) } @$_ ] };

declare 'MapStringOrder',
    as HashRef[Order()];

declare 'State',
    as (Int | Str);

declare 'Type',
    as (Int | Str);

declare 'DeploymentType',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Order::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Order::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Order::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Site',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Site'];

coerce 'Site',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Site'->new($_) };

declare 'RepeatedSite',
    as ArrayRef[Site()];

coerce 'RepeatedSite',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Site'->new($_) } @$_ ] };

declare 'MapStringSite',
    as HashRef[Site()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Site::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Site::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Site::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'HardwareGroup',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::HardwareGroup'];

coerce 'HardwareGroup',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::HardwareGroup'->new($_) };

declare 'RepeatedHardwareGroup',
    as ArrayRef[HardwareGroup()];

coerce 'RepeatedHardwareGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::HardwareGroup'->new($_) } @$_ ] };

declare 'MapStringHardwareGroup',
    as HashRef[HardwareGroup()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::HardwareGroup::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::HardwareGroup::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::HardwareGroup::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Hardware',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Hardware'];

coerce 'Hardware',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Hardware'->new($_) };

declare 'RepeatedHardware',
    as ArrayRef[Hardware()];

coerce 'RepeatedHardware',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Hardware'->new($_) } @$_ ] };

declare 'MapStringHardware',
    as HashRef[Hardware()];

declare 'State',
    as (Int | Str);

declare 'MacAddress',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Hardware::MacAddress'];

coerce 'MacAddress',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Hardware::MacAddress'->new($_) };

declare 'RepeatedMacAddress',
    as ArrayRef[MacAddress()];

coerce 'RepeatedMacAddress',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Hardware::MacAddress'->new($_) } @$_ ] };

declare 'MapStringMacAddress',
    as HashRef[MacAddress()];

declare 'AddressType',
    as (Int | Str);

declare 'DiskInfo',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Hardware::DiskInfo'];

coerce 'DiskInfo',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Hardware::DiskInfo'->new($_) };

declare 'RepeatedDiskInfo',
    as ArrayRef[DiskInfo()];

coerce 'RepeatedDiskInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Hardware::DiskInfo'->new($_) } @$_ ] };

declare 'MapStringDiskInfo',
    as HashRef[DiskInfo()];

declare 'MachineInfo',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Hardware::MachineInfo'];

coerce 'MachineInfo',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Hardware::MachineInfo'->new($_) };

declare 'RepeatedMachineInfo',
    as ArrayRef[MachineInfo()];

coerce 'RepeatedMachineInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Hardware::MachineInfo'->new($_) } @$_ ] };

declare 'MapStringMachineInfo',
    as HashRef[MachineInfo()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Hardware::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Hardware::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Hardware::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Comment',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Comment'];

coerce 'Comment',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Comment'->new($_) };

declare 'RepeatedComment',
    as ArrayRef[Comment()];

coerce 'RepeatedComment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Comment'->new($_) } @$_ ] };

declare 'MapStringComment',
    as HashRef[Comment()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Comment::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Comment::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Comment::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ChangeLogEntry',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::ChangeLogEntry'];

coerce 'ChangeLogEntry',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::ChangeLogEntry'->new($_) };

declare 'RepeatedChangeLogEntry',
    as ArrayRef[ChangeLogEntry()];

coerce 'RepeatedChangeLogEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::ChangeLogEntry'->new($_) } @$_ ] };

declare 'MapStringChangeLogEntry',
    as HashRef[ChangeLogEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::ChangeLogEntry::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::ChangeLogEntry::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::ChangeLogEntry::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Sku',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Sku'];

coerce 'Sku',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Sku'->new($_) };

declare 'RepeatedSku',
    as ArrayRef[Sku()];

coerce 'RepeatedSku',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Sku'->new($_) } @$_ ] };

declare 'MapStringSku',
    as HashRef[Sku()];

declare 'Type',
    as (Int | Str);

declare 'Range',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Sku::Range'];

coerce 'Range',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Sku::Range'->new($_) };

declare 'RepeatedRange',
    as ArrayRef[Range()];

coerce 'RepeatedRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Sku::Range'->new($_) } @$_ ] };

declare 'MapStringRange',
    as HashRef[Range()];

declare 'Zone',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Zone'];

coerce 'Zone',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Zone'->new($_) };

declare 'RepeatedZone',
    as ArrayRef[Zone()];

coerce 'RepeatedZone',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Zone'->new($_) } @$_ ] };

declare 'MapStringZone',
    as HashRef[Zone()];

declare 'State',
    as (Int | Str);

declare 'ProvisioningState',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Zone::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Zone::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Zone::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'OrganizationContact',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::OrganizationContact'];

coerce 'OrganizationContact',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::OrganizationContact'->new($_) };

declare 'RepeatedOrganizationContact',
    as ArrayRef[OrganizationContact()];

coerce 'RepeatedOrganizationContact',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::OrganizationContact'->new($_) } @$_ ] };

declare 'MapStringOrganizationContact',
    as HashRef[OrganizationContact()];

declare 'Contact',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Contact'];

coerce 'Contact',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Contact'->new($_) };

declare 'RepeatedContact',
    as ArrayRef[Contact()];

coerce 'RepeatedContact',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Contact'->new($_) } @$_ ] };

declare 'MapStringContact',
    as HashRef[Contact()];

declare 'HardwareConfig',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::HardwareConfig'];

coerce 'HardwareConfig',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::HardwareConfig'->new($_) };

declare 'RepeatedHardwareConfig',
    as ArrayRef[HardwareConfig()];

coerce 'RepeatedHardwareConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::HardwareConfig'->new($_) } @$_ ] };

declare 'MapStringHardwareConfig',
    as HashRef[HardwareConfig()];

declare 'SkuConfig',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::SkuConfig'];

coerce 'SkuConfig',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::SkuConfig'->new($_) };

declare 'RepeatedSkuConfig',
    as ArrayRef[SkuConfig()];

coerce 'RepeatedSkuConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::SkuConfig'->new($_) } @$_ ] };

declare 'MapStringSkuConfig',
    as HashRef[SkuConfig()];

declare 'SkuInstance',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::SkuInstance'];

coerce 'SkuInstance',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::SkuInstance'->new($_) };

declare 'RepeatedSkuInstance',
    as ArrayRef[SkuInstance()];

coerce 'RepeatedSkuInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::SkuInstance'->new($_) } @$_ ] };

declare 'MapStringSkuInstance',
    as HashRef[SkuInstance()];

declare 'HardwarePhysicalInfo',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::HardwarePhysicalInfo'];

coerce 'HardwarePhysicalInfo',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::HardwarePhysicalInfo'->new($_) };

declare 'RepeatedHardwarePhysicalInfo',
    as ArrayRef[HardwarePhysicalInfo()];

coerce 'RepeatedHardwarePhysicalInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::HardwarePhysicalInfo'->new($_) } @$_ ] };

declare 'MapStringHardwarePhysicalInfo',
    as HashRef[HardwarePhysicalInfo()];

declare 'PowerReceptacleType',
    as (Int | Str);

declare 'NetworkUplinkType',
    as (Int | Str);

declare 'Voltage',
    as (Int | Str);

declare 'Amperes',
    as (Int | Str);

declare 'HardwareInstallationInfo',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::HardwareInstallationInfo'];

coerce 'HardwareInstallationInfo',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::HardwareInstallationInfo'->new($_) };

declare 'RepeatedHardwareInstallationInfo',
    as ArrayRef[HardwareInstallationInfo()];

coerce 'RepeatedHardwareInstallationInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::HardwareInstallationInfo'->new($_) } @$_ ] };

declare 'MapStringHardwareInstallationInfo',
    as HashRef[HardwareInstallationInfo()];

declare 'RackType',
    as (Int | Str);

declare 'ZoneNetworkConfig',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::ZoneNetworkConfig'];

coerce 'ZoneNetworkConfig',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::ZoneNetworkConfig'->new($_) };

declare 'RepeatedZoneNetworkConfig',
    as ArrayRef[ZoneNetworkConfig()];

coerce 'RepeatedZoneNetworkConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::ZoneNetworkConfig'->new($_) } @$_ ] };

declare 'MapStringZoneNetworkConfig',
    as HashRef[ZoneNetworkConfig()];

declare 'Subnet',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Subnet'];

coerce 'Subnet',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Subnet'->new($_) };

declare 'RepeatedSubnet',
    as ArrayRef[Subnet()];

coerce 'RepeatedSubnet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Subnet'->new($_) } @$_ ] };

declare 'MapStringSubnet',
    as HashRef[Subnet()];

declare 'TimePeriod',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::TimePeriod'];

coerce 'TimePeriod',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::TimePeriod'->new($_) };

declare 'RepeatedTimePeriod',
    as ArrayRef[TimePeriod()];

coerce 'RepeatedTimePeriod',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::TimePeriod'->new($_) } @$_ ] };

declare 'MapStringTimePeriod',
    as HashRef[TimePeriod()];

declare 'Dimensions',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Dimensions'];

coerce 'Dimensions',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Dimensions'->new($_) };

declare 'RepeatedDimensions',
    as ArrayRef[Dimensions()];

coerce 'RepeatedDimensions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Dimensions'->new($_) } @$_ ] };

declare 'MapStringDimensions',
    as HashRef[Dimensions()];

declare 'RackSpace',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::RackSpace'];

coerce 'RackSpace',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::RackSpace'->new($_) };

declare 'RepeatedRackSpace',
    as ArrayRef[RackSpace()];

coerce 'RepeatedRackSpace',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::RackSpace'->new($_) } @$_ ] };

declare 'MapStringRackSpace',
    as HashRef[RackSpace()];

declare 'HardwareLocation',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::HardwareLocation'];

coerce 'HardwareLocation',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::HardwareLocation'->new($_) };

declare 'RepeatedHardwareLocation',
    as ArrayRef[HardwareLocation()];

coerce 'RepeatedHardwareLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::HardwareLocation'->new($_) } @$_ ] };

declare 'MapStringHardwareLocation',
    as HashRef[HardwareLocation()];

declare 'SubscriptionConfig',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::SubscriptionConfig'];

coerce 'SubscriptionConfig',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::SubscriptionConfig'->new($_) };

declare 'RepeatedSubscriptionConfig',
    as ArrayRef[SubscriptionConfig()];

coerce 'RepeatedSubscriptionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::SubscriptionConfig'->new($_) } @$_ ] };

declare 'MapStringSubscriptionConfig',
    as HashRef[SubscriptionConfig()];

declare 'SubscriptionState',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Gdchardwaremanagement::V1alpha::Resources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
