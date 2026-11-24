package Google::Cloud::Notebooks::V1::Runtime::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Runtime',
    as InstanceOf['Google::Cloud::Notebooks::V1::Runtime::Runtime'];

coerce 'Runtime',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Runtime::Runtime'->new($_) };

declare 'RepeatedRuntime',
    as ArrayRef[Runtime()];

coerce 'RepeatedRuntime',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Runtime::Runtime'->new($_) } @$_ ] };

declare 'MapStringRuntime',
    as HashRef[Runtime()];

declare 'State',
    as (Int | Str);

declare 'HealthState',
    as (Int | Str);

declare 'RuntimeAcceleratorConfig',
    as InstanceOf['Google::Cloud::Notebooks::V1::Runtime::RuntimeAcceleratorConfig'];

coerce 'RuntimeAcceleratorConfig',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Runtime::RuntimeAcceleratorConfig'->new($_) };

declare 'RepeatedRuntimeAcceleratorConfig',
    as ArrayRef[RuntimeAcceleratorConfig()];

coerce 'RepeatedRuntimeAcceleratorConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Runtime::RuntimeAcceleratorConfig'->new($_) } @$_ ] };

declare 'MapStringRuntimeAcceleratorConfig',
    as HashRef[RuntimeAcceleratorConfig()];

declare 'AcceleratorType',
    as (Int | Str);

declare 'EncryptionConfig',
    as InstanceOf['Google::Cloud::Notebooks::V1::Runtime::EncryptionConfig'];

coerce 'EncryptionConfig',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Runtime::EncryptionConfig'->new($_) };

declare 'RepeatedEncryptionConfig',
    as ArrayRef[EncryptionConfig()];

coerce 'RepeatedEncryptionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Runtime::EncryptionConfig'->new($_) } @$_ ] };

declare 'MapStringEncryptionConfig',
    as HashRef[EncryptionConfig()];

declare 'LocalDisk',
    as InstanceOf['Google::Cloud::Notebooks::V1::Runtime::LocalDisk'];

coerce 'LocalDisk',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Runtime::LocalDisk'->new($_) };

declare 'RepeatedLocalDisk',
    as ArrayRef[LocalDisk()];

coerce 'RepeatedLocalDisk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Runtime::LocalDisk'->new($_) } @$_ ] };

declare 'MapStringLocalDisk',
    as HashRef[LocalDisk()];

declare 'RuntimeGuestOsFeature',
    as InstanceOf['Google::Cloud::Notebooks::V1::Runtime::LocalDisk::RuntimeGuestOsFeature'];

coerce 'RuntimeGuestOsFeature',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Runtime::LocalDisk::RuntimeGuestOsFeature'->new($_) };

declare 'RepeatedRuntimeGuestOsFeature',
    as ArrayRef[RuntimeGuestOsFeature()];

coerce 'RepeatedRuntimeGuestOsFeature',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Runtime::LocalDisk::RuntimeGuestOsFeature'->new($_) } @$_ ] };

declare 'MapStringRuntimeGuestOsFeature',
    as HashRef[RuntimeGuestOsFeature()];

declare 'LocalDiskInitializeParams',
    as InstanceOf['Google::Cloud::Notebooks::V1::Runtime::LocalDiskInitializeParams'];

coerce 'LocalDiskInitializeParams',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Runtime::LocalDiskInitializeParams'->new($_) };

declare 'RepeatedLocalDiskInitializeParams',
    as ArrayRef[LocalDiskInitializeParams()];

coerce 'RepeatedLocalDiskInitializeParams',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Runtime::LocalDiskInitializeParams'->new($_) } @$_ ] };

declare 'MapStringLocalDiskInitializeParams',
    as HashRef[LocalDiskInitializeParams()];

declare 'DiskType',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Notebooks::V1::Runtime::LocalDiskInitializeParams::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Runtime::LocalDiskInitializeParams::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Runtime::LocalDiskInitializeParams::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'RuntimeAccessConfig',
    as InstanceOf['Google::Cloud::Notebooks::V1::Runtime::RuntimeAccessConfig'];

coerce 'RuntimeAccessConfig',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Runtime::RuntimeAccessConfig'->new($_) };

declare 'RepeatedRuntimeAccessConfig',
    as ArrayRef[RuntimeAccessConfig()];

coerce 'RepeatedRuntimeAccessConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Runtime::RuntimeAccessConfig'->new($_) } @$_ ] };

declare 'MapStringRuntimeAccessConfig',
    as HashRef[RuntimeAccessConfig()];

declare 'RuntimeAccessType',
    as (Int | Str);

declare 'RuntimeSoftwareConfig',
    as InstanceOf['Google::Cloud::Notebooks::V1::Runtime::RuntimeSoftwareConfig'];

coerce 'RuntimeSoftwareConfig',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Runtime::RuntimeSoftwareConfig'->new($_) };

declare 'RepeatedRuntimeSoftwareConfig',
    as ArrayRef[RuntimeSoftwareConfig()];

coerce 'RepeatedRuntimeSoftwareConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Runtime::RuntimeSoftwareConfig'->new($_) } @$_ ] };

declare 'MapStringRuntimeSoftwareConfig',
    as HashRef[RuntimeSoftwareConfig()];

declare 'PostStartupScriptBehavior',
    as (Int | Str);

declare 'RuntimeMetrics',
    as InstanceOf['Google::Cloud::Notebooks::V1::Runtime::RuntimeMetrics'];

coerce 'RuntimeMetrics',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Runtime::RuntimeMetrics'->new($_) };

declare 'RepeatedRuntimeMetrics',
    as ArrayRef[RuntimeMetrics()];

coerce 'RepeatedRuntimeMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Runtime::RuntimeMetrics'->new($_) } @$_ ] };

declare 'MapStringRuntimeMetrics',
    as HashRef[RuntimeMetrics()];

declare 'SystemMetricsEntry',
    as InstanceOf['Google::Cloud::Notebooks::V1::Runtime::RuntimeMetrics::SystemMetricsEntry'];

coerce 'SystemMetricsEntry',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Runtime::RuntimeMetrics::SystemMetricsEntry'->new($_) };

declare 'RepeatedSystemMetricsEntry',
    as ArrayRef[SystemMetricsEntry()];

coerce 'RepeatedSystemMetricsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Runtime::RuntimeMetrics::SystemMetricsEntry'->new($_) } @$_ ] };

declare 'MapStringSystemMetricsEntry',
    as HashRef[SystemMetricsEntry()];

declare 'RuntimeShieldedInstanceConfig',
    as InstanceOf['Google::Cloud::Notebooks::V1::Runtime::RuntimeShieldedInstanceConfig'];

coerce 'RuntimeShieldedInstanceConfig',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Runtime::RuntimeShieldedInstanceConfig'->new($_) };

declare 'RepeatedRuntimeShieldedInstanceConfig',
    as ArrayRef[RuntimeShieldedInstanceConfig()];

coerce 'RepeatedRuntimeShieldedInstanceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Runtime::RuntimeShieldedInstanceConfig'->new($_) } @$_ ] };

declare 'MapStringRuntimeShieldedInstanceConfig',
    as HashRef[RuntimeShieldedInstanceConfig()];

declare 'VirtualMachine',
    as InstanceOf['Google::Cloud::Notebooks::V1::Runtime::VirtualMachine'];

coerce 'VirtualMachine',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Runtime::VirtualMachine'->new($_) };

declare 'RepeatedVirtualMachine',
    as ArrayRef[VirtualMachine()];

coerce 'RepeatedVirtualMachine',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Runtime::VirtualMachine'->new($_) } @$_ ] };

declare 'MapStringVirtualMachine',
    as HashRef[VirtualMachine()];

declare 'VirtualMachineConfig',
    as InstanceOf['Google::Cloud::Notebooks::V1::Runtime::VirtualMachineConfig'];

coerce 'VirtualMachineConfig',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Runtime::VirtualMachineConfig'->new($_) };

declare 'RepeatedVirtualMachineConfig',
    as ArrayRef[VirtualMachineConfig()];

coerce 'RepeatedVirtualMachineConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Runtime::VirtualMachineConfig'->new($_) } @$_ ] };

declare 'MapStringVirtualMachineConfig',
    as HashRef[VirtualMachineConfig()];

declare 'NicType',
    as (Int | Str);

declare 'BootImage',
    as InstanceOf['Google::Cloud::Notebooks::V1::Runtime::VirtualMachineConfig::BootImage'];

coerce 'BootImage',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Runtime::VirtualMachineConfig::BootImage'->new($_) };

declare 'RepeatedBootImage',
    as ArrayRef[BootImage()];

coerce 'RepeatedBootImage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Runtime::VirtualMachineConfig::BootImage'->new($_) } @$_ ] };

declare 'MapStringBootImage',
    as HashRef[BootImage()];

declare 'GuestAttributesEntry',
    as InstanceOf['Google::Cloud::Notebooks::V1::Runtime::VirtualMachineConfig::GuestAttributesEntry'];

coerce 'GuestAttributesEntry',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Runtime::VirtualMachineConfig::GuestAttributesEntry'->new($_) };

declare 'RepeatedGuestAttributesEntry',
    as ArrayRef[GuestAttributesEntry()];

coerce 'RepeatedGuestAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Runtime::VirtualMachineConfig::GuestAttributesEntry'->new($_) } @$_ ] };

declare 'MapStringGuestAttributesEntry',
    as HashRef[GuestAttributesEntry()];

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Notebooks::V1::Runtime::VirtualMachineConfig::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Runtime::VirtualMachineConfig::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Runtime::VirtualMachineConfig::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Notebooks::V1::Runtime::VirtualMachineConfig::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Runtime::VirtualMachineConfig::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Runtime::VirtualMachineConfig::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Notebooks::V1::Runtime::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
