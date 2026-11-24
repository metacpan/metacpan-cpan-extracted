package Google::Cloud::Notebooks::V2::GceSetup::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DiskEncryption',
    as (Int | Str);

declare 'DiskType',
    as (Int | Str);

declare 'NetworkInterface',
    as InstanceOf['Google::Cloud::Notebooks::V2::GceSetup::NetworkInterface'];

coerce 'NetworkInterface',
    from HashRef, via { 'Google::Cloud::Notebooks::V2::GceSetup::NetworkInterface'->new($_) };

declare 'RepeatedNetworkInterface',
    as ArrayRef[NetworkInterface()];

coerce 'RepeatedNetworkInterface',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V2::GceSetup::NetworkInterface'->new($_) } @$_ ] };

declare 'MapStringNetworkInterface',
    as HashRef[NetworkInterface()];

declare 'NicType',
    as (Int | Str);

declare 'VmImage',
    as InstanceOf['Google::Cloud::Notebooks::V2::GceSetup::VmImage'];

coerce 'VmImage',
    from HashRef, via { 'Google::Cloud::Notebooks::V2::GceSetup::VmImage'->new($_) };

declare 'RepeatedVmImage',
    as ArrayRef[VmImage()];

coerce 'RepeatedVmImage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V2::GceSetup::VmImage'->new($_) } @$_ ] };

declare 'MapStringVmImage',
    as HashRef[VmImage()];

declare 'ContainerImage',
    as InstanceOf['Google::Cloud::Notebooks::V2::GceSetup::ContainerImage'];

coerce 'ContainerImage',
    from HashRef, via { 'Google::Cloud::Notebooks::V2::GceSetup::ContainerImage'->new($_) };

declare 'RepeatedContainerImage',
    as ArrayRef[ContainerImage()];

coerce 'RepeatedContainerImage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V2::GceSetup::ContainerImage'->new($_) } @$_ ] };

declare 'MapStringContainerImage',
    as HashRef[ContainerImage()];

declare 'AcceleratorConfig',
    as InstanceOf['Google::Cloud::Notebooks::V2::GceSetup::AcceleratorConfig'];

coerce 'AcceleratorConfig',
    from HashRef, via { 'Google::Cloud::Notebooks::V2::GceSetup::AcceleratorConfig'->new($_) };

declare 'RepeatedAcceleratorConfig',
    as ArrayRef[AcceleratorConfig()];

coerce 'RepeatedAcceleratorConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V2::GceSetup::AcceleratorConfig'->new($_) } @$_ ] };

declare 'MapStringAcceleratorConfig',
    as HashRef[AcceleratorConfig()];

declare 'AcceleratorType',
    as (Int | Str);

declare 'ShieldedInstanceConfig',
    as InstanceOf['Google::Cloud::Notebooks::V2::GceSetup::ShieldedInstanceConfig'];

coerce 'ShieldedInstanceConfig',
    from HashRef, via { 'Google::Cloud::Notebooks::V2::GceSetup::ShieldedInstanceConfig'->new($_) };

declare 'RepeatedShieldedInstanceConfig',
    as ArrayRef[ShieldedInstanceConfig()];

coerce 'RepeatedShieldedInstanceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V2::GceSetup::ShieldedInstanceConfig'->new($_) } @$_ ] };

declare 'MapStringShieldedInstanceConfig',
    as HashRef[ShieldedInstanceConfig()];

declare 'GPUDriverConfig',
    as InstanceOf['Google::Cloud::Notebooks::V2::GceSetup::GPUDriverConfig'];

coerce 'GPUDriverConfig',
    from HashRef, via { 'Google::Cloud::Notebooks::V2::GceSetup::GPUDriverConfig'->new($_) };

declare 'RepeatedGPUDriverConfig',
    as ArrayRef[GPUDriverConfig()];

coerce 'RepeatedGPUDriverConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V2::GceSetup::GPUDriverConfig'->new($_) } @$_ ] };

declare 'MapStringGPUDriverConfig',
    as HashRef[GPUDriverConfig()];

declare 'DataDisk',
    as InstanceOf['Google::Cloud::Notebooks::V2::GceSetup::DataDisk'];

coerce 'DataDisk',
    from HashRef, via { 'Google::Cloud::Notebooks::V2::GceSetup::DataDisk'->new($_) };

declare 'RepeatedDataDisk',
    as ArrayRef[DataDisk()];

coerce 'RepeatedDataDisk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V2::GceSetup::DataDisk'->new($_) } @$_ ] };

declare 'MapStringDataDisk',
    as HashRef[DataDisk()];

declare 'BootDisk',
    as InstanceOf['Google::Cloud::Notebooks::V2::GceSetup::BootDisk'];

coerce 'BootDisk',
    from HashRef, via { 'Google::Cloud::Notebooks::V2::GceSetup::BootDisk'->new($_) };

declare 'RepeatedBootDisk',
    as ArrayRef[BootDisk()];

coerce 'RepeatedBootDisk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V2::GceSetup::BootDisk'->new($_) } @$_ ] };

declare 'MapStringBootDisk',
    as HashRef[BootDisk()];

declare 'ServiceAccount',
    as InstanceOf['Google::Cloud::Notebooks::V2::GceSetup::ServiceAccount'];

coerce 'ServiceAccount',
    from HashRef, via { 'Google::Cloud::Notebooks::V2::GceSetup::ServiceAccount'->new($_) };

declare 'RepeatedServiceAccount',
    as ArrayRef[ServiceAccount()];

coerce 'RepeatedServiceAccount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V2::GceSetup::ServiceAccount'->new($_) } @$_ ] };

declare 'MapStringServiceAccount',
    as HashRef[ServiceAccount()];

declare 'GceSetup',
    as InstanceOf['Google::Cloud::Notebooks::V2::GceSetup::GceSetup'];

coerce 'GceSetup',
    from HashRef, via { 'Google::Cloud::Notebooks::V2::GceSetup::GceSetup'->new($_) };

declare 'RepeatedGceSetup',
    as ArrayRef[GceSetup()];

coerce 'RepeatedGceSetup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V2::GceSetup::GceSetup'->new($_) } @$_ ] };

declare 'MapStringGceSetup',
    as HashRef[GceSetup()];

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Notebooks::V2::GceSetup::GceSetup::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Notebooks::V2::GceSetup::GceSetup::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V2::GceSetup::GceSetup::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Notebooks::V2::GceSetup::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
