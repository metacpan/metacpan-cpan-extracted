package Google::Cloud::Backupdr::V1::BackupvaultGce::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'KeyRevocationActionType',
    as (Int | Str);

declare 'ComputeInstanceBackupProperties',
    as InstanceOf['Google::Cloud::Backupdr::V1::BackupvaultGce::ComputeInstanceBackupProperties'];

coerce 'ComputeInstanceBackupProperties',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::BackupvaultGce::ComputeInstanceBackupProperties'->new($_) };

declare 'RepeatedComputeInstanceBackupProperties',
    as ArrayRef[ComputeInstanceBackupProperties()];

coerce 'RepeatedComputeInstanceBackupProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::BackupvaultGce::ComputeInstanceBackupProperties'->new($_) } @$_ ] };

declare 'MapStringComputeInstanceBackupProperties',
    as HashRef[ComputeInstanceBackupProperties()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Backupdr::V1::BackupvaultGce::ComputeInstanceBackupProperties::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::BackupvaultGce::ComputeInstanceBackupProperties::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::BackupvaultGce::ComputeInstanceBackupProperties::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ComputeInstanceRestoreProperties',
    as InstanceOf['Google::Cloud::Backupdr::V1::BackupvaultGce::ComputeInstanceRestoreProperties'];

coerce 'ComputeInstanceRestoreProperties',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::BackupvaultGce::ComputeInstanceRestoreProperties'->new($_) };

declare 'RepeatedComputeInstanceRestoreProperties',
    as ArrayRef[ComputeInstanceRestoreProperties()];

coerce 'RepeatedComputeInstanceRestoreProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::BackupvaultGce::ComputeInstanceRestoreProperties'->new($_) } @$_ ] };

declare 'MapStringComputeInstanceRestoreProperties',
    as HashRef[ComputeInstanceRestoreProperties()];

declare 'InstancePrivateIpv6GoogleAccess',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Backupdr::V1::BackupvaultGce::ComputeInstanceRestoreProperties::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::BackupvaultGce::ComputeInstanceRestoreProperties::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::BackupvaultGce::ComputeInstanceRestoreProperties::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ComputeInstanceTargetEnvironment',
    as InstanceOf['Google::Cloud::Backupdr::V1::BackupvaultGce::ComputeInstanceTargetEnvironment'];

coerce 'ComputeInstanceTargetEnvironment',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::BackupvaultGce::ComputeInstanceTargetEnvironment'->new($_) };

declare 'RepeatedComputeInstanceTargetEnvironment',
    as ArrayRef[ComputeInstanceTargetEnvironment()];

coerce 'RepeatedComputeInstanceTargetEnvironment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::BackupvaultGce::ComputeInstanceTargetEnvironment'->new($_) } @$_ ] };

declare 'MapStringComputeInstanceTargetEnvironment',
    as HashRef[ComputeInstanceTargetEnvironment()];

declare 'ComputeInstanceDataSourceProperties',
    as InstanceOf['Google::Cloud::Backupdr::V1::BackupvaultGce::ComputeInstanceDataSourceProperties'];

coerce 'ComputeInstanceDataSourceProperties',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::BackupvaultGce::ComputeInstanceDataSourceProperties'->new($_) };

declare 'RepeatedComputeInstanceDataSourceProperties',
    as ArrayRef[ComputeInstanceDataSourceProperties()];

coerce 'RepeatedComputeInstanceDataSourceProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::BackupvaultGce::ComputeInstanceDataSourceProperties'->new($_) } @$_ ] };

declare 'MapStringComputeInstanceDataSourceProperties',
    as HashRef[ComputeInstanceDataSourceProperties()];

declare 'AdvancedMachineFeatures',
    as InstanceOf['Google::Cloud::Backupdr::V1::BackupvaultGce::AdvancedMachineFeatures'];

coerce 'AdvancedMachineFeatures',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::BackupvaultGce::AdvancedMachineFeatures'->new($_) };

declare 'RepeatedAdvancedMachineFeatures',
    as ArrayRef[AdvancedMachineFeatures()];

coerce 'RepeatedAdvancedMachineFeatures',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::BackupvaultGce::AdvancedMachineFeatures'->new($_) } @$_ ] };

declare 'MapStringAdvancedMachineFeatures',
    as HashRef[AdvancedMachineFeatures()];

declare 'ConfidentialInstanceConfig',
    as InstanceOf['Google::Cloud::Backupdr::V1::BackupvaultGce::ConfidentialInstanceConfig'];

coerce 'ConfidentialInstanceConfig',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::BackupvaultGce::ConfidentialInstanceConfig'->new($_) };

declare 'RepeatedConfidentialInstanceConfig',
    as ArrayRef[ConfidentialInstanceConfig()];

coerce 'RepeatedConfidentialInstanceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::BackupvaultGce::ConfidentialInstanceConfig'->new($_) } @$_ ] };

declare 'MapStringConfidentialInstanceConfig',
    as HashRef[ConfidentialInstanceConfig()];

declare 'DisplayDevice',
    as InstanceOf['Google::Cloud::Backupdr::V1::BackupvaultGce::DisplayDevice'];

coerce 'DisplayDevice',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::BackupvaultGce::DisplayDevice'->new($_) };

declare 'RepeatedDisplayDevice',
    as ArrayRef[DisplayDevice()];

coerce 'RepeatedDisplayDevice',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::BackupvaultGce::DisplayDevice'->new($_) } @$_ ] };

declare 'MapStringDisplayDevice',
    as HashRef[DisplayDevice()];

declare 'AcceleratorConfig',
    as InstanceOf['Google::Cloud::Backupdr::V1::BackupvaultGce::AcceleratorConfig'];

coerce 'AcceleratorConfig',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::BackupvaultGce::AcceleratorConfig'->new($_) };

declare 'RepeatedAcceleratorConfig',
    as ArrayRef[AcceleratorConfig()];

coerce 'RepeatedAcceleratorConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::BackupvaultGce::AcceleratorConfig'->new($_) } @$_ ] };

declare 'MapStringAcceleratorConfig',
    as HashRef[AcceleratorConfig()];

declare 'CustomerEncryptionKey',
    as InstanceOf['Google::Cloud::Backupdr::V1::BackupvaultGce::CustomerEncryptionKey'];

coerce 'CustomerEncryptionKey',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::BackupvaultGce::CustomerEncryptionKey'->new($_) };

declare 'RepeatedCustomerEncryptionKey',
    as ArrayRef[CustomerEncryptionKey()];

coerce 'RepeatedCustomerEncryptionKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::BackupvaultGce::CustomerEncryptionKey'->new($_) } @$_ ] };

declare 'MapStringCustomerEncryptionKey',
    as HashRef[CustomerEncryptionKey()];

declare 'Entry',
    as InstanceOf['Google::Cloud::Backupdr::V1::BackupvaultGce::Entry'];

coerce 'Entry',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::BackupvaultGce::Entry'->new($_) };

declare 'RepeatedEntry',
    as ArrayRef[Entry()];

coerce 'RepeatedEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::BackupvaultGce::Entry'->new($_) } @$_ ] };

declare 'MapStringEntry',
    as HashRef[Entry()];

declare 'Metadata',
    as InstanceOf['Google::Cloud::Backupdr::V1::BackupvaultGce::Metadata'];

coerce 'Metadata',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::BackupvaultGce::Metadata'->new($_) };

declare 'RepeatedMetadata',
    as ArrayRef[Metadata()];

coerce 'RepeatedMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::BackupvaultGce::Metadata'->new($_) } @$_ ] };

declare 'MapStringMetadata',
    as HashRef[Metadata()];

declare 'NetworkInterface',
    as InstanceOf['Google::Cloud::Backupdr::V1::BackupvaultGce::NetworkInterface'];

coerce 'NetworkInterface',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::BackupvaultGce::NetworkInterface'->new($_) };

declare 'RepeatedNetworkInterface',
    as ArrayRef[NetworkInterface()];

coerce 'RepeatedNetworkInterface',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::BackupvaultGce::NetworkInterface'->new($_) } @$_ ] };

declare 'MapStringNetworkInterface',
    as HashRef[NetworkInterface()];

declare 'StackType',
    as (Int | Str);

declare 'Ipv6AccessType',
    as (Int | Str);

declare 'NicType',
    as (Int | Str);

declare 'NetworkPerformanceConfig',
    as InstanceOf['Google::Cloud::Backupdr::V1::BackupvaultGce::NetworkPerformanceConfig'];

coerce 'NetworkPerformanceConfig',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::BackupvaultGce::NetworkPerformanceConfig'->new($_) };

declare 'RepeatedNetworkPerformanceConfig',
    as ArrayRef[NetworkPerformanceConfig()];

coerce 'RepeatedNetworkPerformanceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::BackupvaultGce::NetworkPerformanceConfig'->new($_) } @$_ ] };

declare 'MapStringNetworkPerformanceConfig',
    as HashRef[NetworkPerformanceConfig()];

declare 'Tier',
    as (Int | Str);

declare 'AccessConfig',
    as InstanceOf['Google::Cloud::Backupdr::V1::BackupvaultGce::AccessConfig'];

coerce 'AccessConfig',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::BackupvaultGce::AccessConfig'->new($_) };

declare 'RepeatedAccessConfig',
    as ArrayRef[AccessConfig()];

coerce 'RepeatedAccessConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::BackupvaultGce::AccessConfig'->new($_) } @$_ ] };

declare 'MapStringAccessConfig',
    as HashRef[AccessConfig()];

declare 'AccessType',
    as (Int | Str);

declare 'NetworkTier',
    as (Int | Str);

declare 'AliasIpRange',
    as InstanceOf['Google::Cloud::Backupdr::V1::BackupvaultGce::AliasIpRange'];

coerce 'AliasIpRange',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::BackupvaultGce::AliasIpRange'->new($_) };

declare 'RepeatedAliasIpRange',
    as ArrayRef[AliasIpRange()];

coerce 'RepeatedAliasIpRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::BackupvaultGce::AliasIpRange'->new($_) } @$_ ] };

declare 'MapStringAliasIpRange',
    as HashRef[AliasIpRange()];

declare 'InstanceParams',
    as InstanceOf['Google::Cloud::Backupdr::V1::BackupvaultGce::InstanceParams'];

coerce 'InstanceParams',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::BackupvaultGce::InstanceParams'->new($_) };

declare 'RepeatedInstanceParams',
    as ArrayRef[InstanceParams()];

coerce 'RepeatedInstanceParams',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::BackupvaultGce::InstanceParams'->new($_) } @$_ ] };

declare 'MapStringInstanceParams',
    as HashRef[InstanceParams()];

declare 'ResourceManagerTagsEntry',
    as InstanceOf['Google::Cloud::Backupdr::V1::BackupvaultGce::InstanceParams::ResourceManagerTagsEntry'];

coerce 'ResourceManagerTagsEntry',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::BackupvaultGce::InstanceParams::ResourceManagerTagsEntry'->new($_) };

declare 'RepeatedResourceManagerTagsEntry',
    as ArrayRef[ResourceManagerTagsEntry()];

coerce 'RepeatedResourceManagerTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::BackupvaultGce::InstanceParams::ResourceManagerTagsEntry'->new($_) } @$_ ] };

declare 'MapStringResourceManagerTagsEntry',
    as HashRef[ResourceManagerTagsEntry()];

declare 'AllocationAffinity',
    as InstanceOf['Google::Cloud::Backupdr::V1::BackupvaultGce::AllocationAffinity'];

coerce 'AllocationAffinity',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::BackupvaultGce::AllocationAffinity'->new($_) };

declare 'RepeatedAllocationAffinity',
    as ArrayRef[AllocationAffinity()];

coerce 'RepeatedAllocationAffinity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::BackupvaultGce::AllocationAffinity'->new($_) } @$_ ] };

declare 'MapStringAllocationAffinity',
    as HashRef[AllocationAffinity()];

declare 'Type',
    as (Int | Str);

declare 'Scheduling',
    as InstanceOf['Google::Cloud::Backupdr::V1::BackupvaultGce::Scheduling'];

coerce 'Scheduling',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::BackupvaultGce::Scheduling'->new($_) };

declare 'RepeatedScheduling',
    as ArrayRef[Scheduling()];

coerce 'RepeatedScheduling',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::BackupvaultGce::Scheduling'->new($_) } @$_ ] };

declare 'MapStringScheduling',
    as HashRef[Scheduling()];

declare 'OnHostMaintenance',
    as (Int | Str);

declare 'ProvisioningModel',
    as (Int | Str);

declare 'InstanceTerminationAction',
    as (Int | Str);

declare 'NodeAffinity',
    as InstanceOf['Google::Cloud::Backupdr::V1::BackupvaultGce::Scheduling::NodeAffinity'];

coerce 'NodeAffinity',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::BackupvaultGce::Scheduling::NodeAffinity'->new($_) };

declare 'RepeatedNodeAffinity',
    as ArrayRef[NodeAffinity()];

coerce 'RepeatedNodeAffinity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::BackupvaultGce::Scheduling::NodeAffinity'->new($_) } @$_ ] };

declare 'MapStringNodeAffinity',
    as HashRef[NodeAffinity()];

declare 'Operator',
    as (Int | Str);

declare 'SchedulingDuration',
    as InstanceOf['Google::Cloud::Backupdr::V1::BackupvaultGce::SchedulingDuration'];

coerce 'SchedulingDuration',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::BackupvaultGce::SchedulingDuration'->new($_) };

declare 'RepeatedSchedulingDuration',
    as ArrayRef[SchedulingDuration()];

coerce 'RepeatedSchedulingDuration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::BackupvaultGce::SchedulingDuration'->new($_) } @$_ ] };

declare 'MapStringSchedulingDuration',
    as HashRef[SchedulingDuration()];

declare 'ServiceAccount',
    as InstanceOf['Google::Cloud::Backupdr::V1::BackupvaultGce::ServiceAccount'];

coerce 'ServiceAccount',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::BackupvaultGce::ServiceAccount'->new($_) };

declare 'RepeatedServiceAccount',
    as ArrayRef[ServiceAccount()];

coerce 'RepeatedServiceAccount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::BackupvaultGce::ServiceAccount'->new($_) } @$_ ] };

declare 'MapStringServiceAccount',
    as HashRef[ServiceAccount()];

declare 'Tags',
    as InstanceOf['Google::Cloud::Backupdr::V1::BackupvaultGce::Tags'];

coerce 'Tags',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::BackupvaultGce::Tags'->new($_) };

declare 'RepeatedTags',
    as ArrayRef[Tags()];

coerce 'RepeatedTags',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::BackupvaultGce::Tags'->new($_) } @$_ ] };

declare 'MapStringTags',
    as HashRef[Tags()];

declare 'AttachedDisk',
    as InstanceOf['Google::Cloud::Backupdr::V1::BackupvaultGce::AttachedDisk'];

coerce 'AttachedDisk',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::BackupvaultGce::AttachedDisk'->new($_) };

declare 'RepeatedAttachedDisk',
    as ArrayRef[AttachedDisk()];

coerce 'RepeatedAttachedDisk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::BackupvaultGce::AttachedDisk'->new($_) } @$_ ] };

declare 'MapStringAttachedDisk',
    as HashRef[AttachedDisk()];

declare 'DiskType',
    as (Int | Str);

declare 'DiskMode',
    as (Int | Str);

declare 'DiskInterface',
    as (Int | Str);

declare 'DiskSavedState',
    as (Int | Str);

declare 'InitializeParams',
    as InstanceOf['Google::Cloud::Backupdr::V1::BackupvaultGce::AttachedDisk::InitializeParams'];

coerce 'InitializeParams',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::BackupvaultGce::AttachedDisk::InitializeParams'->new($_) };

declare 'RepeatedInitializeParams',
    as ArrayRef[InitializeParams()];

coerce 'RepeatedInitializeParams',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::BackupvaultGce::AttachedDisk::InitializeParams'->new($_) } @$_ ] };

declare 'MapStringInitializeParams',
    as HashRef[InitializeParams()];

declare 'GuestOsFeature',
    as InstanceOf['Google::Cloud::Backupdr::V1::BackupvaultGce::GuestOsFeature'];

coerce 'GuestOsFeature',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::BackupvaultGce::GuestOsFeature'->new($_) };

declare 'RepeatedGuestOsFeature',
    as ArrayRef[GuestOsFeature()];

coerce 'RepeatedGuestOsFeature',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::BackupvaultGce::GuestOsFeature'->new($_) } @$_ ] };

declare 'MapStringGuestOsFeature',
    as HashRef[GuestOsFeature()];

declare 'FeatureType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Backupdr::V1::BackupvaultGce::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
