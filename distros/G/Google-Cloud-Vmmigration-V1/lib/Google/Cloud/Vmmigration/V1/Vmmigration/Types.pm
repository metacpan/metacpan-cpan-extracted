package Google::Cloud::Vmmigration::V1::Vmmigration::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ComputeEngineDiskType',
    as (Int | Str);

declare 'ComputeEngineLicenseType',
    as (Int | Str);

declare 'ComputeEngineBootOption',
    as (Int | Str);

declare 'OsCapability',
    as (Int | Str);

declare 'BootConversion',
    as (Int | Str);

declare 'UtilizationReportView',
    as (Int | Str);

declare 'MigratingVmView',
    as (Int | Str);

declare 'VmArchitecture',
    as (Int | Str);

declare 'ComputeEngineNetworkTier',
    as (Int | Str);

declare 'ReplicationCycle',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ReplicationCycle'];

coerce 'ReplicationCycle',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ReplicationCycle'->new($_) };

declare 'RepeatedReplicationCycle',
    as ArrayRef[ReplicationCycle()];

coerce 'RepeatedReplicationCycle',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ReplicationCycle'->new($_) } @$_ ] };

declare 'MapStringReplicationCycle',
    as HashRef[ReplicationCycle()];

declare 'State',
    as (Int | Str);

declare 'CycleStep',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::CycleStep'];

coerce 'CycleStep',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::CycleStep'->new($_) };

declare 'RepeatedCycleStep',
    as ArrayRef[CycleStep()];

coerce 'RepeatedCycleStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::CycleStep'->new($_) } @$_ ] };

declare 'MapStringCycleStep',
    as HashRef[CycleStep()];

declare 'InitializingReplicationStep',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::InitializingReplicationStep'];

coerce 'InitializingReplicationStep',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::InitializingReplicationStep'->new($_) };

declare 'RepeatedInitializingReplicationStep',
    as ArrayRef[InitializingReplicationStep()];

coerce 'RepeatedInitializingReplicationStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::InitializingReplicationStep'->new($_) } @$_ ] };

declare 'MapStringInitializingReplicationStep',
    as HashRef[InitializingReplicationStep()];

declare 'ReplicatingStep',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ReplicatingStep'];

coerce 'ReplicatingStep',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ReplicatingStep'->new($_) };

declare 'RepeatedReplicatingStep',
    as ArrayRef[ReplicatingStep()];

coerce 'RepeatedReplicatingStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ReplicatingStep'->new($_) } @$_ ] };

declare 'MapStringReplicatingStep',
    as HashRef[ReplicatingStep()];

declare 'PostProcessingStep',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::PostProcessingStep'];

coerce 'PostProcessingStep',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::PostProcessingStep'->new($_) };

declare 'RepeatedPostProcessingStep',
    as ArrayRef[PostProcessingStep()];

coerce 'RepeatedPostProcessingStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::PostProcessingStep'->new($_) } @$_ ] };

declare 'MapStringPostProcessingStep',
    as HashRef[PostProcessingStep()];

declare 'ReplicationSync',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ReplicationSync'];

coerce 'ReplicationSync',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ReplicationSync'->new($_) };

declare 'RepeatedReplicationSync',
    as ArrayRef[ReplicationSync()];

coerce 'RepeatedReplicationSync',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ReplicationSync'->new($_) } @$_ ] };

declare 'MapStringReplicationSync',
    as HashRef[ReplicationSync()];

declare 'MigratingVm',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::MigratingVm'];

coerce 'MigratingVm',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::MigratingVm'->new($_) };

declare 'RepeatedMigratingVm',
    as ArrayRef[MigratingVm()];

coerce 'RepeatedMigratingVm',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::MigratingVm'->new($_) } @$_ ] };

declare 'MapStringMigratingVm',
    as HashRef[MigratingVm()];

declare 'State',
    as (Int | Str);

declare 'Expiration',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::MigratingVm::Expiration'];

coerce 'Expiration',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::MigratingVm::Expiration'->new($_) };

declare 'RepeatedExpiration',
    as ArrayRef[Expiration()];

coerce 'RepeatedExpiration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::MigratingVm::Expiration'->new($_) } @$_ ] };

declare 'MapStringExpiration',
    as HashRef[Expiration()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::MigratingVm::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::MigratingVm::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::MigratingVm::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'CutoverForecast',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::CutoverForecast'];

coerce 'CutoverForecast',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::CutoverForecast'->new($_) };

declare 'RepeatedCutoverForecast',
    as ArrayRef[CutoverForecast()];

coerce 'RepeatedCutoverForecast',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::CutoverForecast'->new($_) } @$_ ] };

declare 'MapStringCutoverForecast',
    as HashRef[CutoverForecast()];

declare 'CloneJob',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::CloneJob'];

coerce 'CloneJob',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::CloneJob'->new($_) };

declare 'RepeatedCloneJob',
    as ArrayRef[CloneJob()];

coerce 'RepeatedCloneJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::CloneJob'->new($_) } @$_ ] };

declare 'MapStringCloneJob',
    as HashRef[CloneJob()];

declare 'State',
    as (Int | Str);

declare 'CloneStep',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::CloneStep'];

coerce 'CloneStep',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::CloneStep'->new($_) };

declare 'RepeatedCloneStep',
    as ArrayRef[CloneStep()];

coerce 'RepeatedCloneStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::CloneStep'->new($_) } @$_ ] };

declare 'MapStringCloneStep',
    as HashRef[CloneStep()];

declare 'AdaptingOSStep',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::AdaptingOSStep'];

coerce 'AdaptingOSStep',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::AdaptingOSStep'->new($_) };

declare 'RepeatedAdaptingOSStep',
    as ArrayRef[AdaptingOSStep()];

coerce 'RepeatedAdaptingOSStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::AdaptingOSStep'->new($_) } @$_ ] };

declare 'MapStringAdaptingOSStep',
    as HashRef[AdaptingOSStep()];

declare 'PreparingVMDisksStep',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::PreparingVMDisksStep'];

coerce 'PreparingVMDisksStep',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::PreparingVMDisksStep'->new($_) };

declare 'RepeatedPreparingVMDisksStep',
    as ArrayRef[PreparingVMDisksStep()];

coerce 'RepeatedPreparingVMDisksStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::PreparingVMDisksStep'->new($_) } @$_ ] };

declare 'MapStringPreparingVMDisksStep',
    as HashRef[PreparingVMDisksStep()];

declare 'InstantiatingMigratedVMStep',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::InstantiatingMigratedVMStep'];

coerce 'InstantiatingMigratedVMStep',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::InstantiatingMigratedVMStep'->new($_) };

declare 'RepeatedInstantiatingMigratedVMStep',
    as ArrayRef[InstantiatingMigratedVMStep()];

coerce 'RepeatedInstantiatingMigratedVMStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::InstantiatingMigratedVMStep'->new($_) } @$_ ] };

declare 'MapStringInstantiatingMigratedVMStep',
    as HashRef[InstantiatingMigratedVMStep()];

declare 'CutoverJob',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::CutoverJob'];

coerce 'CutoverJob',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::CutoverJob'->new($_) };

declare 'RepeatedCutoverJob',
    as ArrayRef[CutoverJob()];

coerce 'RepeatedCutoverJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::CutoverJob'->new($_) } @$_ ] };

declare 'MapStringCutoverJob',
    as HashRef[CutoverJob()];

declare 'State',
    as (Int | Str);

declare 'CutoverStep',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::CutoverStep'];

coerce 'CutoverStep',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::CutoverStep'->new($_) };

declare 'RepeatedCutoverStep',
    as ArrayRef[CutoverStep()];

coerce 'RepeatedCutoverStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::CutoverStep'->new($_) } @$_ ] };

declare 'MapStringCutoverStep',
    as HashRef[CutoverStep()];

declare 'ShuttingDownSourceVMStep',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ShuttingDownSourceVMStep'];

coerce 'ShuttingDownSourceVMStep',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ShuttingDownSourceVMStep'->new($_) };

declare 'RepeatedShuttingDownSourceVMStep',
    as ArrayRef[ShuttingDownSourceVMStep()];

coerce 'RepeatedShuttingDownSourceVMStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ShuttingDownSourceVMStep'->new($_) } @$_ ] };

declare 'MapStringShuttingDownSourceVMStep',
    as HashRef[ShuttingDownSourceVMStep()];

declare 'CreateCloneJobRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::CreateCloneJobRequest'];

coerce 'CreateCloneJobRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::CreateCloneJobRequest'->new($_) };

declare 'RepeatedCreateCloneJobRequest',
    as ArrayRef[CreateCloneJobRequest()];

coerce 'RepeatedCreateCloneJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::CreateCloneJobRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCloneJobRequest',
    as HashRef[CreateCloneJobRequest()];

declare 'CancelCloneJobRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::CancelCloneJobRequest'];

coerce 'CancelCloneJobRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::CancelCloneJobRequest'->new($_) };

declare 'RepeatedCancelCloneJobRequest',
    as ArrayRef[CancelCloneJobRequest()];

coerce 'RepeatedCancelCloneJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::CancelCloneJobRequest'->new($_) } @$_ ] };

declare 'MapStringCancelCloneJobRequest',
    as HashRef[CancelCloneJobRequest()];

declare 'CancelCloneJobResponse',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::CancelCloneJobResponse'];

coerce 'CancelCloneJobResponse',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::CancelCloneJobResponse'->new($_) };

declare 'RepeatedCancelCloneJobResponse',
    as ArrayRef[CancelCloneJobResponse()];

coerce 'RepeatedCancelCloneJobResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::CancelCloneJobResponse'->new($_) } @$_ ] };

declare 'MapStringCancelCloneJobResponse',
    as HashRef[CancelCloneJobResponse()];

declare 'ListCloneJobsRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ListCloneJobsRequest'];

coerce 'ListCloneJobsRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListCloneJobsRequest'->new($_) };

declare 'RepeatedListCloneJobsRequest',
    as ArrayRef[ListCloneJobsRequest()];

coerce 'RepeatedListCloneJobsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListCloneJobsRequest'->new($_) } @$_ ] };

declare 'MapStringListCloneJobsRequest',
    as HashRef[ListCloneJobsRequest()];

declare 'ListCloneJobsResponse',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ListCloneJobsResponse'];

coerce 'ListCloneJobsResponse',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListCloneJobsResponse'->new($_) };

declare 'RepeatedListCloneJobsResponse',
    as ArrayRef[ListCloneJobsResponse()];

coerce 'RepeatedListCloneJobsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListCloneJobsResponse'->new($_) } @$_ ] };

declare 'MapStringListCloneJobsResponse',
    as HashRef[ListCloneJobsResponse()];

declare 'GetCloneJobRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::GetCloneJobRequest'];

coerce 'GetCloneJobRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::GetCloneJobRequest'->new($_) };

declare 'RepeatedGetCloneJobRequest',
    as ArrayRef[GetCloneJobRequest()];

coerce 'RepeatedGetCloneJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::GetCloneJobRequest'->new($_) } @$_ ] };

declare 'MapStringGetCloneJobRequest',
    as HashRef[GetCloneJobRequest()];

declare 'Source',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::Source'];

coerce 'Source',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::Source'->new($_) };

declare 'RepeatedSource',
    as ArrayRef[Source()];

coerce 'RepeatedSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::Source'->new($_) } @$_ ] };

declare 'MapStringSource',
    as HashRef[Source()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::Source::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::Source::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::Source::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Encryption',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::Encryption'];

coerce 'Encryption',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::Encryption'->new($_) };

declare 'RepeatedEncryption',
    as ArrayRef[Encryption()];

coerce 'RepeatedEncryption',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::Encryption'->new($_) } @$_ ] };

declare 'MapStringEncryption',
    as HashRef[Encryption()];

declare 'VmwareSourceDetails',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::VmwareSourceDetails'];

coerce 'VmwareSourceDetails',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::VmwareSourceDetails'->new($_) };

declare 'RepeatedVmwareSourceDetails',
    as ArrayRef[VmwareSourceDetails()];

coerce 'RepeatedVmwareSourceDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::VmwareSourceDetails'->new($_) } @$_ ] };

declare 'MapStringVmwareSourceDetails',
    as HashRef[VmwareSourceDetails()];

declare 'AwsSourceDetails',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::AwsSourceDetails'];

coerce 'AwsSourceDetails',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::AwsSourceDetails'->new($_) };

declare 'RepeatedAwsSourceDetails',
    as ArrayRef[AwsSourceDetails()];

coerce 'RepeatedAwsSourceDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::AwsSourceDetails'->new($_) } @$_ ] };

declare 'MapStringAwsSourceDetails',
    as HashRef[AwsSourceDetails()];

declare 'State',
    as (Int | Str);

declare 'AccessKeyCredentials',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::AwsSourceDetails::AccessKeyCredentials'];

coerce 'AccessKeyCredentials',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::AwsSourceDetails::AccessKeyCredentials'->new($_) };

declare 'RepeatedAccessKeyCredentials',
    as ArrayRef[AccessKeyCredentials()];

coerce 'RepeatedAccessKeyCredentials',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::AwsSourceDetails::AccessKeyCredentials'->new($_) } @$_ ] };

declare 'MapStringAccessKeyCredentials',
    as HashRef[AccessKeyCredentials()];

declare 'Tag',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::AwsSourceDetails::Tag'];

coerce 'Tag',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::AwsSourceDetails::Tag'->new($_) };

declare 'RepeatedTag',
    as ArrayRef[Tag()];

coerce 'RepeatedTag',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::AwsSourceDetails::Tag'->new($_) } @$_ ] };

declare 'MapStringTag',
    as HashRef[Tag()];

declare 'MigrationResourcesUserTagsEntry',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::AwsSourceDetails::MigrationResourcesUserTagsEntry'];

coerce 'MigrationResourcesUserTagsEntry',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::AwsSourceDetails::MigrationResourcesUserTagsEntry'->new($_) };

declare 'RepeatedMigrationResourcesUserTagsEntry',
    as ArrayRef[MigrationResourcesUserTagsEntry()];

coerce 'RepeatedMigrationResourcesUserTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::AwsSourceDetails::MigrationResourcesUserTagsEntry'->new($_) } @$_ ] };

declare 'MapStringMigrationResourcesUserTagsEntry',
    as HashRef[MigrationResourcesUserTagsEntry()];

declare 'AzureSourceDetails',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::AzureSourceDetails'];

coerce 'AzureSourceDetails',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::AzureSourceDetails'->new($_) };

declare 'RepeatedAzureSourceDetails',
    as ArrayRef[AzureSourceDetails()];

coerce 'RepeatedAzureSourceDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::AzureSourceDetails'->new($_) } @$_ ] };

declare 'MapStringAzureSourceDetails',
    as HashRef[AzureSourceDetails()];

declare 'State',
    as (Int | Str);

declare 'ClientSecretCredentials',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::AzureSourceDetails::ClientSecretCredentials'];

coerce 'ClientSecretCredentials',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::AzureSourceDetails::ClientSecretCredentials'->new($_) };

declare 'RepeatedClientSecretCredentials',
    as ArrayRef[ClientSecretCredentials()];

coerce 'RepeatedClientSecretCredentials',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::AzureSourceDetails::ClientSecretCredentials'->new($_) } @$_ ] };

declare 'MapStringClientSecretCredentials',
    as HashRef[ClientSecretCredentials()];

declare 'MigrationResourcesUserTagsEntry',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::AzureSourceDetails::MigrationResourcesUserTagsEntry'];

coerce 'MigrationResourcesUserTagsEntry',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::AzureSourceDetails::MigrationResourcesUserTagsEntry'->new($_) };

declare 'RepeatedMigrationResourcesUserTagsEntry',
    as ArrayRef[MigrationResourcesUserTagsEntry()];

coerce 'RepeatedMigrationResourcesUserTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::AzureSourceDetails::MigrationResourcesUserTagsEntry'->new($_) } @$_ ] };

declare 'MapStringMigrationResourcesUserTagsEntry',
    as HashRef[MigrationResourcesUserTagsEntry()];

declare 'DatacenterConnector',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::DatacenterConnector'];

coerce 'DatacenterConnector',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::DatacenterConnector'->new($_) };

declare 'RepeatedDatacenterConnector',
    as ArrayRef[DatacenterConnector()];

coerce 'RepeatedDatacenterConnector',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::DatacenterConnector'->new($_) } @$_ ] };

declare 'MapStringDatacenterConnector',
    as HashRef[DatacenterConnector()];

declare 'State',
    as (Int | Str);

declare 'UpgradeStatus',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::UpgradeStatus'];

coerce 'UpgradeStatus',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::UpgradeStatus'->new($_) };

declare 'RepeatedUpgradeStatus',
    as ArrayRef[UpgradeStatus()];

coerce 'RepeatedUpgradeStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::UpgradeStatus'->new($_) } @$_ ] };

declare 'MapStringUpgradeStatus',
    as HashRef[UpgradeStatus()];

declare 'State',
    as (Int | Str);

declare 'AvailableUpdates',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::AvailableUpdates'];

coerce 'AvailableUpdates',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::AvailableUpdates'->new($_) };

declare 'RepeatedAvailableUpdates',
    as ArrayRef[AvailableUpdates()];

coerce 'RepeatedAvailableUpdates',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::AvailableUpdates'->new($_) } @$_ ] };

declare 'MapStringAvailableUpdates',
    as HashRef[AvailableUpdates()];

declare 'ApplianceVersion',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ApplianceVersion'];

coerce 'ApplianceVersion',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ApplianceVersion'->new($_) };

declare 'RepeatedApplianceVersion',
    as ArrayRef[ApplianceVersion()];

coerce 'RepeatedApplianceVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ApplianceVersion'->new($_) } @$_ ] };

declare 'MapStringApplianceVersion',
    as HashRef[ApplianceVersion()];

declare 'ListSourcesRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ListSourcesRequest'];

coerce 'ListSourcesRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListSourcesRequest'->new($_) };

declare 'RepeatedListSourcesRequest',
    as ArrayRef[ListSourcesRequest()];

coerce 'RepeatedListSourcesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListSourcesRequest'->new($_) } @$_ ] };

declare 'MapStringListSourcesRequest',
    as HashRef[ListSourcesRequest()];

declare 'ListSourcesResponse',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ListSourcesResponse'];

coerce 'ListSourcesResponse',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListSourcesResponse'->new($_) };

declare 'RepeatedListSourcesResponse',
    as ArrayRef[ListSourcesResponse()];

coerce 'RepeatedListSourcesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListSourcesResponse'->new($_) } @$_ ] };

declare 'MapStringListSourcesResponse',
    as HashRef[ListSourcesResponse()];

declare 'GetSourceRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::GetSourceRequest'];

coerce 'GetSourceRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::GetSourceRequest'->new($_) };

declare 'RepeatedGetSourceRequest',
    as ArrayRef[GetSourceRequest()];

coerce 'RepeatedGetSourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::GetSourceRequest'->new($_) } @$_ ] };

declare 'MapStringGetSourceRequest',
    as HashRef[GetSourceRequest()];

declare 'CreateSourceRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::CreateSourceRequest'];

coerce 'CreateSourceRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::CreateSourceRequest'->new($_) };

declare 'RepeatedCreateSourceRequest',
    as ArrayRef[CreateSourceRequest()];

coerce 'RepeatedCreateSourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::CreateSourceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSourceRequest',
    as HashRef[CreateSourceRequest()];

declare 'UpdateSourceRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::UpdateSourceRequest'];

coerce 'UpdateSourceRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::UpdateSourceRequest'->new($_) };

declare 'RepeatedUpdateSourceRequest',
    as ArrayRef[UpdateSourceRequest()];

coerce 'RepeatedUpdateSourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::UpdateSourceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSourceRequest',
    as HashRef[UpdateSourceRequest()];

declare 'DeleteSourceRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::DeleteSourceRequest'];

coerce 'DeleteSourceRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::DeleteSourceRequest'->new($_) };

declare 'RepeatedDeleteSourceRequest',
    as ArrayRef[DeleteSourceRequest()];

coerce 'RepeatedDeleteSourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::DeleteSourceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSourceRequest',
    as HashRef[DeleteSourceRequest()];

declare 'FetchInventoryRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::FetchInventoryRequest'];

coerce 'FetchInventoryRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::FetchInventoryRequest'->new($_) };

declare 'RepeatedFetchInventoryRequest',
    as ArrayRef[FetchInventoryRequest()];

coerce 'RepeatedFetchInventoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::FetchInventoryRequest'->new($_) } @$_ ] };

declare 'MapStringFetchInventoryRequest',
    as HashRef[FetchInventoryRequest()];

declare 'VmwareVmDetails',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::VmwareVmDetails'];

coerce 'VmwareVmDetails',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::VmwareVmDetails'->new($_) };

declare 'RepeatedVmwareVmDetails',
    as ArrayRef[VmwareVmDetails()];

coerce 'RepeatedVmwareVmDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::VmwareVmDetails'->new($_) } @$_ ] };

declare 'MapStringVmwareVmDetails',
    as HashRef[VmwareVmDetails()];

declare 'PowerState',
    as (Int | Str);

declare 'BootOption',
    as (Int | Str);

declare 'VmArchitecture',
    as (Int | Str);

declare 'AwsVmDetails',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::AwsVmDetails'];

coerce 'AwsVmDetails',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::AwsVmDetails'->new($_) };

declare 'RepeatedAwsVmDetails',
    as ArrayRef[AwsVmDetails()];

coerce 'RepeatedAwsVmDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::AwsVmDetails'->new($_) } @$_ ] };

declare 'MapStringAwsVmDetails',
    as HashRef[AwsVmDetails()];

declare 'PowerState',
    as (Int | Str);

declare 'BootOption',
    as (Int | Str);

declare 'VmVirtualizationType',
    as (Int | Str);

declare 'VmArchitecture',
    as (Int | Str);

declare 'TagsEntry',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::AwsVmDetails::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::AwsVmDetails::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::AwsVmDetails::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

declare 'AwsSecurityGroup',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::AwsSecurityGroup'];

coerce 'AwsSecurityGroup',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::AwsSecurityGroup'->new($_) };

declare 'RepeatedAwsSecurityGroup',
    as ArrayRef[AwsSecurityGroup()];

coerce 'RepeatedAwsSecurityGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::AwsSecurityGroup'->new($_) } @$_ ] };

declare 'MapStringAwsSecurityGroup',
    as HashRef[AwsSecurityGroup()];

declare 'AzureVmDetails',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::AzureVmDetails'];

coerce 'AzureVmDetails',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::AzureVmDetails'->new($_) };

declare 'RepeatedAzureVmDetails',
    as ArrayRef[AzureVmDetails()];

coerce 'RepeatedAzureVmDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::AzureVmDetails'->new($_) } @$_ ] };

declare 'MapStringAzureVmDetails',
    as HashRef[AzureVmDetails()];

declare 'PowerState',
    as (Int | Str);

declare 'BootOption',
    as (Int | Str);

declare 'VmArchitecture',
    as (Int | Str);

declare 'OSDisk',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::AzureVmDetails::OSDisk'];

coerce 'OSDisk',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::AzureVmDetails::OSDisk'->new($_) };

declare 'RepeatedOSDisk',
    as ArrayRef[OSDisk()];

coerce 'RepeatedOSDisk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::AzureVmDetails::OSDisk'->new($_) } @$_ ] };

declare 'MapStringOSDisk',
    as HashRef[OSDisk()];

declare 'Disk',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::AzureVmDetails::Disk'];

coerce 'Disk',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::AzureVmDetails::Disk'->new($_) };

declare 'RepeatedDisk',
    as ArrayRef[Disk()];

coerce 'RepeatedDisk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::AzureVmDetails::Disk'->new($_) } @$_ ] };

declare 'MapStringDisk',
    as HashRef[Disk()];

declare 'OSDescription',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::AzureVmDetails::OSDescription'];

coerce 'OSDescription',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::AzureVmDetails::OSDescription'->new($_) };

declare 'RepeatedOSDescription',
    as ArrayRef[OSDescription()];

coerce 'RepeatedOSDescription',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::AzureVmDetails::OSDescription'->new($_) } @$_ ] };

declare 'MapStringOSDescription',
    as HashRef[OSDescription()];

declare 'TagsEntry',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::AzureVmDetails::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::AzureVmDetails::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::AzureVmDetails::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

declare 'VmwareVmsDetails',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::VmwareVmsDetails'];

coerce 'VmwareVmsDetails',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::VmwareVmsDetails'->new($_) };

declare 'RepeatedVmwareVmsDetails',
    as ArrayRef[VmwareVmsDetails()];

coerce 'RepeatedVmwareVmsDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::VmwareVmsDetails'->new($_) } @$_ ] };

declare 'MapStringVmwareVmsDetails',
    as HashRef[VmwareVmsDetails()];

declare 'AwsVmsDetails',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::AwsVmsDetails'];

coerce 'AwsVmsDetails',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::AwsVmsDetails'->new($_) };

declare 'RepeatedAwsVmsDetails',
    as ArrayRef[AwsVmsDetails()];

coerce 'RepeatedAwsVmsDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::AwsVmsDetails'->new($_) } @$_ ] };

declare 'MapStringAwsVmsDetails',
    as HashRef[AwsVmsDetails()];

declare 'AzureVmsDetails',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::AzureVmsDetails'];

coerce 'AzureVmsDetails',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::AzureVmsDetails'->new($_) };

declare 'RepeatedAzureVmsDetails',
    as ArrayRef[AzureVmsDetails()];

coerce 'RepeatedAzureVmsDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::AzureVmsDetails'->new($_) } @$_ ] };

declare 'MapStringAzureVmsDetails',
    as HashRef[AzureVmsDetails()];

declare 'FetchInventoryResponse',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::FetchInventoryResponse'];

coerce 'FetchInventoryResponse',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::FetchInventoryResponse'->new($_) };

declare 'RepeatedFetchInventoryResponse',
    as ArrayRef[FetchInventoryResponse()];

coerce 'RepeatedFetchInventoryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::FetchInventoryResponse'->new($_) } @$_ ] };

declare 'MapStringFetchInventoryResponse',
    as HashRef[FetchInventoryResponse()];

declare 'FetchStorageInventoryRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::FetchStorageInventoryRequest'];

coerce 'FetchStorageInventoryRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::FetchStorageInventoryRequest'->new($_) };

declare 'RepeatedFetchStorageInventoryRequest',
    as ArrayRef[FetchStorageInventoryRequest()];

coerce 'RepeatedFetchStorageInventoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::FetchStorageInventoryRequest'->new($_) } @$_ ] };

declare 'MapStringFetchStorageInventoryRequest',
    as HashRef[FetchStorageInventoryRequest()];

declare 'StorageType',
    as (Int | Str);

declare 'FetchStorageInventoryResponse',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::FetchStorageInventoryResponse'];

coerce 'FetchStorageInventoryResponse',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::FetchStorageInventoryResponse'->new($_) };

declare 'RepeatedFetchStorageInventoryResponse',
    as ArrayRef[FetchStorageInventoryResponse()];

coerce 'RepeatedFetchStorageInventoryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::FetchStorageInventoryResponse'->new($_) } @$_ ] };

declare 'MapStringFetchStorageInventoryResponse',
    as HashRef[FetchStorageInventoryResponse()];

declare 'SourceStorageResource',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::SourceStorageResource'];

coerce 'SourceStorageResource',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::SourceStorageResource'->new($_) };

declare 'RepeatedSourceStorageResource',
    as ArrayRef[SourceStorageResource()];

coerce 'RepeatedSourceStorageResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::SourceStorageResource'->new($_) } @$_ ] };

declare 'MapStringSourceStorageResource',
    as HashRef[SourceStorageResource()];

declare 'UtilizationReport',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::UtilizationReport'];

coerce 'UtilizationReport',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::UtilizationReport'->new($_) };

declare 'RepeatedUtilizationReport',
    as ArrayRef[UtilizationReport()];

coerce 'RepeatedUtilizationReport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::UtilizationReport'->new($_) } @$_ ] };

declare 'MapStringUtilizationReport',
    as HashRef[UtilizationReport()];

declare 'State',
    as (Int | Str);

declare 'TimeFrame',
    as (Int | Str);

declare 'VmUtilizationInfo',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::VmUtilizationInfo'];

coerce 'VmUtilizationInfo',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::VmUtilizationInfo'->new($_) };

declare 'RepeatedVmUtilizationInfo',
    as ArrayRef[VmUtilizationInfo()];

coerce 'RepeatedVmUtilizationInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::VmUtilizationInfo'->new($_) } @$_ ] };

declare 'MapStringVmUtilizationInfo',
    as HashRef[VmUtilizationInfo()];

declare 'VmUtilizationMetrics',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::VmUtilizationMetrics'];

coerce 'VmUtilizationMetrics',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::VmUtilizationMetrics'->new($_) };

declare 'RepeatedVmUtilizationMetrics',
    as ArrayRef[VmUtilizationMetrics()];

coerce 'RepeatedVmUtilizationMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::VmUtilizationMetrics'->new($_) } @$_ ] };

declare 'MapStringVmUtilizationMetrics',
    as HashRef[VmUtilizationMetrics()];

declare 'ListUtilizationReportsRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ListUtilizationReportsRequest'];

coerce 'ListUtilizationReportsRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListUtilizationReportsRequest'->new($_) };

declare 'RepeatedListUtilizationReportsRequest',
    as ArrayRef[ListUtilizationReportsRequest()];

coerce 'RepeatedListUtilizationReportsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListUtilizationReportsRequest'->new($_) } @$_ ] };

declare 'MapStringListUtilizationReportsRequest',
    as HashRef[ListUtilizationReportsRequest()];

declare 'ListUtilizationReportsResponse',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ListUtilizationReportsResponse'];

coerce 'ListUtilizationReportsResponse',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListUtilizationReportsResponse'->new($_) };

declare 'RepeatedListUtilizationReportsResponse',
    as ArrayRef[ListUtilizationReportsResponse()];

coerce 'RepeatedListUtilizationReportsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListUtilizationReportsResponse'->new($_) } @$_ ] };

declare 'MapStringListUtilizationReportsResponse',
    as HashRef[ListUtilizationReportsResponse()];

declare 'GetUtilizationReportRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::GetUtilizationReportRequest'];

coerce 'GetUtilizationReportRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::GetUtilizationReportRequest'->new($_) };

declare 'RepeatedGetUtilizationReportRequest',
    as ArrayRef[GetUtilizationReportRequest()];

coerce 'RepeatedGetUtilizationReportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::GetUtilizationReportRequest'->new($_) } @$_ ] };

declare 'MapStringGetUtilizationReportRequest',
    as HashRef[GetUtilizationReportRequest()];

declare 'CreateUtilizationReportRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::CreateUtilizationReportRequest'];

coerce 'CreateUtilizationReportRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::CreateUtilizationReportRequest'->new($_) };

declare 'RepeatedCreateUtilizationReportRequest',
    as ArrayRef[CreateUtilizationReportRequest()];

coerce 'RepeatedCreateUtilizationReportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::CreateUtilizationReportRequest'->new($_) } @$_ ] };

declare 'MapStringCreateUtilizationReportRequest',
    as HashRef[CreateUtilizationReportRequest()];

declare 'DeleteUtilizationReportRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::DeleteUtilizationReportRequest'];

coerce 'DeleteUtilizationReportRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::DeleteUtilizationReportRequest'->new($_) };

declare 'RepeatedDeleteUtilizationReportRequest',
    as ArrayRef[DeleteUtilizationReportRequest()];

coerce 'RepeatedDeleteUtilizationReportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::DeleteUtilizationReportRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteUtilizationReportRequest',
    as HashRef[DeleteUtilizationReportRequest()];

declare 'ListDatacenterConnectorsResponse',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ListDatacenterConnectorsResponse'];

coerce 'ListDatacenterConnectorsResponse',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListDatacenterConnectorsResponse'->new($_) };

declare 'RepeatedListDatacenterConnectorsResponse',
    as ArrayRef[ListDatacenterConnectorsResponse()];

coerce 'RepeatedListDatacenterConnectorsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListDatacenterConnectorsResponse'->new($_) } @$_ ] };

declare 'MapStringListDatacenterConnectorsResponse',
    as HashRef[ListDatacenterConnectorsResponse()];

declare 'GetDatacenterConnectorRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::GetDatacenterConnectorRequest'];

coerce 'GetDatacenterConnectorRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::GetDatacenterConnectorRequest'->new($_) };

declare 'RepeatedGetDatacenterConnectorRequest',
    as ArrayRef[GetDatacenterConnectorRequest()];

coerce 'RepeatedGetDatacenterConnectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::GetDatacenterConnectorRequest'->new($_) } @$_ ] };

declare 'MapStringGetDatacenterConnectorRequest',
    as HashRef[GetDatacenterConnectorRequest()];

declare 'CreateDatacenterConnectorRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::CreateDatacenterConnectorRequest'];

coerce 'CreateDatacenterConnectorRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::CreateDatacenterConnectorRequest'->new($_) };

declare 'RepeatedCreateDatacenterConnectorRequest',
    as ArrayRef[CreateDatacenterConnectorRequest()];

coerce 'RepeatedCreateDatacenterConnectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::CreateDatacenterConnectorRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDatacenterConnectorRequest',
    as HashRef[CreateDatacenterConnectorRequest()];

declare 'DeleteDatacenterConnectorRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::DeleteDatacenterConnectorRequest'];

coerce 'DeleteDatacenterConnectorRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::DeleteDatacenterConnectorRequest'->new($_) };

declare 'RepeatedDeleteDatacenterConnectorRequest',
    as ArrayRef[DeleteDatacenterConnectorRequest()];

coerce 'RepeatedDeleteDatacenterConnectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::DeleteDatacenterConnectorRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDatacenterConnectorRequest',
    as HashRef[DeleteDatacenterConnectorRequest()];

declare 'UpgradeApplianceRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::UpgradeApplianceRequest'];

coerce 'UpgradeApplianceRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::UpgradeApplianceRequest'->new($_) };

declare 'RepeatedUpgradeApplianceRequest',
    as ArrayRef[UpgradeApplianceRequest()];

coerce 'RepeatedUpgradeApplianceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::UpgradeApplianceRequest'->new($_) } @$_ ] };

declare 'MapStringUpgradeApplianceRequest',
    as HashRef[UpgradeApplianceRequest()];

declare 'UpgradeApplianceResponse',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::UpgradeApplianceResponse'];

coerce 'UpgradeApplianceResponse',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::UpgradeApplianceResponse'->new($_) };

declare 'RepeatedUpgradeApplianceResponse',
    as ArrayRef[UpgradeApplianceResponse()];

coerce 'RepeatedUpgradeApplianceResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::UpgradeApplianceResponse'->new($_) } @$_ ] };

declare 'MapStringUpgradeApplianceResponse',
    as HashRef[UpgradeApplianceResponse()];

declare 'ListDatacenterConnectorsRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ListDatacenterConnectorsRequest'];

coerce 'ListDatacenterConnectorsRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListDatacenterConnectorsRequest'->new($_) };

declare 'RepeatedListDatacenterConnectorsRequest',
    as ArrayRef[ListDatacenterConnectorsRequest()];

coerce 'RepeatedListDatacenterConnectorsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListDatacenterConnectorsRequest'->new($_) } @$_ ] };

declare 'MapStringListDatacenterConnectorsRequest',
    as HashRef[ListDatacenterConnectorsRequest()];

declare 'ComputeEngineTargetDefaults',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ComputeEngineTargetDefaults'];

coerce 'ComputeEngineTargetDefaults',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ComputeEngineTargetDefaults'->new($_) };

declare 'RepeatedComputeEngineTargetDefaults',
    as ArrayRef[ComputeEngineTargetDefaults()];

coerce 'RepeatedComputeEngineTargetDefaults',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ComputeEngineTargetDefaults'->new($_) } @$_ ] };

declare 'MapStringComputeEngineTargetDefaults',
    as HashRef[ComputeEngineTargetDefaults()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ComputeEngineTargetDefaults::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ComputeEngineTargetDefaults::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ComputeEngineTargetDefaults::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ComputeEngineTargetDefaults::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ComputeEngineTargetDefaults::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ComputeEngineTargetDefaults::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'AdaptationModifier',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::AdaptationModifier'];

coerce 'AdaptationModifier',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::AdaptationModifier'->new($_) };

declare 'RepeatedAdaptationModifier',
    as ArrayRef[AdaptationModifier()];

coerce 'RepeatedAdaptationModifier',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::AdaptationModifier'->new($_) } @$_ ] };

declare 'MapStringAdaptationModifier',
    as HashRef[AdaptationModifier()];

declare 'ComputeEngineTargetDetails',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ComputeEngineTargetDetails'];

coerce 'ComputeEngineTargetDetails',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ComputeEngineTargetDetails'->new($_) };

declare 'RepeatedComputeEngineTargetDetails',
    as ArrayRef[ComputeEngineTargetDetails()];

coerce 'RepeatedComputeEngineTargetDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ComputeEngineTargetDetails'->new($_) } @$_ ] };

declare 'MapStringComputeEngineTargetDetails',
    as HashRef[ComputeEngineTargetDetails()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ComputeEngineTargetDetails::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ComputeEngineTargetDetails::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ComputeEngineTargetDetails::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ComputeEngineTargetDetails::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ComputeEngineTargetDetails::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ComputeEngineTargetDetails::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'NetworkInterface',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::NetworkInterface'];

coerce 'NetworkInterface',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::NetworkInterface'->new($_) };

declare 'RepeatedNetworkInterface',
    as ArrayRef[NetworkInterface()];

coerce 'RepeatedNetworkInterface',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::NetworkInterface'->new($_) } @$_ ] };

declare 'MapStringNetworkInterface',
    as HashRef[NetworkInterface()];

declare 'AppliedLicense',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::AppliedLicense'];

coerce 'AppliedLicense',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::AppliedLicense'->new($_) };

declare 'RepeatedAppliedLicense',
    as ArrayRef[AppliedLicense()];

coerce 'RepeatedAppliedLicense',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::AppliedLicense'->new($_) } @$_ ] };

declare 'MapStringAppliedLicense',
    as HashRef[AppliedLicense()];

declare 'Type',
    as (Int | Str);

declare 'SchedulingNodeAffinity',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::SchedulingNodeAffinity'];

coerce 'SchedulingNodeAffinity',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::SchedulingNodeAffinity'->new($_) };

declare 'RepeatedSchedulingNodeAffinity',
    as ArrayRef[SchedulingNodeAffinity()];

coerce 'RepeatedSchedulingNodeAffinity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::SchedulingNodeAffinity'->new($_) } @$_ ] };

declare 'MapStringSchedulingNodeAffinity',
    as HashRef[SchedulingNodeAffinity()];

declare 'Operator',
    as (Int | Str);

declare 'ComputeScheduling',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ComputeScheduling'];

coerce 'ComputeScheduling',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ComputeScheduling'->new($_) };

declare 'RepeatedComputeScheduling',
    as ArrayRef[ComputeScheduling()];

coerce 'RepeatedComputeScheduling',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ComputeScheduling'->new($_) } @$_ ] };

declare 'MapStringComputeScheduling',
    as HashRef[ComputeScheduling()];

declare 'OnHostMaintenance',
    as (Int | Str);

declare 'RestartType',
    as (Int | Str);

declare 'ComputeEngineDisksTargetDefaults',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ComputeEngineDisksTargetDefaults'];

coerce 'ComputeEngineDisksTargetDefaults',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ComputeEngineDisksTargetDefaults'->new($_) };

declare 'RepeatedComputeEngineDisksTargetDefaults',
    as ArrayRef[ComputeEngineDisksTargetDefaults()];

coerce 'RepeatedComputeEngineDisksTargetDefaults',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ComputeEngineDisksTargetDefaults'->new($_) } @$_ ] };

declare 'MapStringComputeEngineDisksTargetDefaults',
    as HashRef[ComputeEngineDisksTargetDefaults()];

declare 'PersistentDiskDefaults',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::PersistentDiskDefaults'];

coerce 'PersistentDiskDefaults',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::PersistentDiskDefaults'->new($_) };

declare 'RepeatedPersistentDiskDefaults',
    as ArrayRef[PersistentDiskDefaults()];

coerce 'RepeatedPersistentDiskDefaults',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::PersistentDiskDefaults'->new($_) } @$_ ] };

declare 'MapStringPersistentDiskDefaults',
    as HashRef[PersistentDiskDefaults()];

declare 'AdditionalLabelsEntry',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::PersistentDiskDefaults::AdditionalLabelsEntry'];

coerce 'AdditionalLabelsEntry',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::PersistentDiskDefaults::AdditionalLabelsEntry'->new($_) };

declare 'RepeatedAdditionalLabelsEntry',
    as ArrayRef[AdditionalLabelsEntry()];

coerce 'RepeatedAdditionalLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::PersistentDiskDefaults::AdditionalLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringAdditionalLabelsEntry',
    as HashRef[AdditionalLabelsEntry()];

declare 'VmAttachmentDetails',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::VmAttachmentDetails'];

coerce 'VmAttachmentDetails',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::VmAttachmentDetails'->new($_) };

declare 'RepeatedVmAttachmentDetails',
    as ArrayRef[VmAttachmentDetails()];

coerce 'RepeatedVmAttachmentDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::VmAttachmentDetails'->new($_) } @$_ ] };

declare 'MapStringVmAttachmentDetails',
    as HashRef[VmAttachmentDetails()];

declare 'DisksMigrationDisksTargetDefaults',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::DisksMigrationDisksTargetDefaults'];

coerce 'DisksMigrationDisksTargetDefaults',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::DisksMigrationDisksTargetDefaults'->new($_) };

declare 'RepeatedDisksMigrationDisksTargetDefaults',
    as ArrayRef[DisksMigrationDisksTargetDefaults()];

coerce 'RepeatedDisksMigrationDisksTargetDefaults',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::DisksMigrationDisksTargetDefaults'->new($_) } @$_ ] };

declare 'MapStringDisksMigrationDisksTargetDefaults',
    as HashRef[DisksMigrationDisksTargetDefaults()];

declare 'DisksMigrationVmTargetDefaults',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::DisksMigrationVmTargetDefaults'];

coerce 'DisksMigrationVmTargetDefaults',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::DisksMigrationVmTargetDefaults'->new($_) };

declare 'RepeatedDisksMigrationVmTargetDefaults',
    as ArrayRef[DisksMigrationVmTargetDefaults()];

coerce 'RepeatedDisksMigrationVmTargetDefaults',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::DisksMigrationVmTargetDefaults'->new($_) } @$_ ] };

declare 'MapStringDisksMigrationVmTargetDefaults',
    as HashRef[DisksMigrationVmTargetDefaults()];

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::DisksMigrationVmTargetDefaults::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::DisksMigrationVmTargetDefaults::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::DisksMigrationVmTargetDefaults::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::DisksMigrationVmTargetDefaults::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::DisksMigrationVmTargetDefaults::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::DisksMigrationVmTargetDefaults::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'BootDiskDefaults',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::BootDiskDefaults'];

coerce 'BootDiskDefaults',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::BootDiskDefaults'->new($_) };

declare 'RepeatedBootDiskDefaults',
    as ArrayRef[BootDiskDefaults()];

coerce 'RepeatedBootDiskDefaults',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::BootDiskDefaults'->new($_) } @$_ ] };

declare 'MapStringBootDiskDefaults',
    as HashRef[BootDiskDefaults()];

declare 'DiskImageDefaults',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::BootDiskDefaults::DiskImageDefaults'];

coerce 'DiskImageDefaults',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::BootDiskDefaults::DiskImageDefaults'->new($_) };

declare 'RepeatedDiskImageDefaults',
    as ArrayRef[DiskImageDefaults()];

coerce 'RepeatedDiskImageDefaults',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::BootDiskDefaults::DiskImageDefaults'->new($_) } @$_ ] };

declare 'MapStringDiskImageDefaults',
    as HashRef[DiskImageDefaults()];

declare 'ComputeEngineDisksTargetDetails',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ComputeEngineDisksTargetDetails'];

coerce 'ComputeEngineDisksTargetDetails',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ComputeEngineDisksTargetDetails'->new($_) };

declare 'RepeatedComputeEngineDisksTargetDetails',
    as ArrayRef[ComputeEngineDisksTargetDetails()];

coerce 'RepeatedComputeEngineDisksTargetDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ComputeEngineDisksTargetDetails'->new($_) } @$_ ] };

declare 'MapStringComputeEngineDisksTargetDetails',
    as HashRef[ComputeEngineDisksTargetDetails()];

declare 'PersistentDisk',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::PersistentDisk'];

coerce 'PersistentDisk',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::PersistentDisk'->new($_) };

declare 'RepeatedPersistentDisk',
    as ArrayRef[PersistentDisk()];

coerce 'RepeatedPersistentDisk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::PersistentDisk'->new($_) } @$_ ] };

declare 'MapStringPersistentDisk',
    as HashRef[PersistentDisk()];

declare 'DisksMigrationDisksTargetDetails',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::DisksMigrationDisksTargetDetails'];

coerce 'DisksMigrationDisksTargetDetails',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::DisksMigrationDisksTargetDetails'->new($_) };

declare 'RepeatedDisksMigrationDisksTargetDetails',
    as ArrayRef[DisksMigrationDisksTargetDetails()];

coerce 'RepeatedDisksMigrationDisksTargetDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::DisksMigrationDisksTargetDetails'->new($_) } @$_ ] };

declare 'MapStringDisksMigrationDisksTargetDetails',
    as HashRef[DisksMigrationDisksTargetDetails()];

declare 'DisksMigrationVmTargetDetails',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::DisksMigrationVmTargetDetails'];

coerce 'DisksMigrationVmTargetDetails',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::DisksMigrationVmTargetDetails'->new($_) };

declare 'RepeatedDisksMigrationVmTargetDetails',
    as ArrayRef[DisksMigrationVmTargetDetails()];

coerce 'RepeatedDisksMigrationVmTargetDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::DisksMigrationVmTargetDetails'->new($_) } @$_ ] };

declare 'MapStringDisksMigrationVmTargetDetails',
    as HashRef[DisksMigrationVmTargetDetails()];

declare 'SchedulePolicy',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::SchedulePolicy'];

coerce 'SchedulePolicy',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::SchedulePolicy'->new($_) };

declare 'RepeatedSchedulePolicy',
    as ArrayRef[SchedulePolicy()];

coerce 'RepeatedSchedulePolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::SchedulePolicy'->new($_) } @$_ ] };

declare 'MapStringSchedulePolicy',
    as HashRef[SchedulePolicy()];

declare 'CreateMigratingVmRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::CreateMigratingVmRequest'];

coerce 'CreateMigratingVmRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::CreateMigratingVmRequest'->new($_) };

declare 'RepeatedCreateMigratingVmRequest',
    as ArrayRef[CreateMigratingVmRequest()];

coerce 'RepeatedCreateMigratingVmRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::CreateMigratingVmRequest'->new($_) } @$_ ] };

declare 'MapStringCreateMigratingVmRequest',
    as HashRef[CreateMigratingVmRequest()];

declare 'ListMigratingVmsRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ListMigratingVmsRequest'];

coerce 'ListMigratingVmsRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListMigratingVmsRequest'->new($_) };

declare 'RepeatedListMigratingVmsRequest',
    as ArrayRef[ListMigratingVmsRequest()];

coerce 'RepeatedListMigratingVmsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListMigratingVmsRequest'->new($_) } @$_ ] };

declare 'MapStringListMigratingVmsRequest',
    as HashRef[ListMigratingVmsRequest()];

declare 'ListMigratingVmsResponse',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ListMigratingVmsResponse'];

coerce 'ListMigratingVmsResponse',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListMigratingVmsResponse'->new($_) };

declare 'RepeatedListMigratingVmsResponse',
    as ArrayRef[ListMigratingVmsResponse()];

coerce 'RepeatedListMigratingVmsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListMigratingVmsResponse'->new($_) } @$_ ] };

declare 'MapStringListMigratingVmsResponse',
    as HashRef[ListMigratingVmsResponse()];

declare 'GetMigratingVmRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::GetMigratingVmRequest'];

coerce 'GetMigratingVmRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::GetMigratingVmRequest'->new($_) };

declare 'RepeatedGetMigratingVmRequest',
    as ArrayRef[GetMigratingVmRequest()];

coerce 'RepeatedGetMigratingVmRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::GetMigratingVmRequest'->new($_) } @$_ ] };

declare 'MapStringGetMigratingVmRequest',
    as HashRef[GetMigratingVmRequest()];

declare 'UpdateMigratingVmRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::UpdateMigratingVmRequest'];

coerce 'UpdateMigratingVmRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::UpdateMigratingVmRequest'->new($_) };

declare 'RepeatedUpdateMigratingVmRequest',
    as ArrayRef[UpdateMigratingVmRequest()];

coerce 'RepeatedUpdateMigratingVmRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::UpdateMigratingVmRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateMigratingVmRequest',
    as HashRef[UpdateMigratingVmRequest()];

declare 'DeleteMigratingVmRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::DeleteMigratingVmRequest'];

coerce 'DeleteMigratingVmRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::DeleteMigratingVmRequest'->new($_) };

declare 'RepeatedDeleteMigratingVmRequest',
    as ArrayRef[DeleteMigratingVmRequest()];

coerce 'RepeatedDeleteMigratingVmRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::DeleteMigratingVmRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteMigratingVmRequest',
    as HashRef[DeleteMigratingVmRequest()];

declare 'StartMigrationRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::StartMigrationRequest'];

coerce 'StartMigrationRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::StartMigrationRequest'->new($_) };

declare 'RepeatedStartMigrationRequest',
    as ArrayRef[StartMigrationRequest()];

coerce 'RepeatedStartMigrationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::StartMigrationRequest'->new($_) } @$_ ] };

declare 'MapStringStartMigrationRequest',
    as HashRef[StartMigrationRequest()];

declare 'StartMigrationResponse',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::StartMigrationResponse'];

coerce 'StartMigrationResponse',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::StartMigrationResponse'->new($_) };

declare 'RepeatedStartMigrationResponse',
    as ArrayRef[StartMigrationResponse()];

coerce 'RepeatedStartMigrationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::StartMigrationResponse'->new($_) } @$_ ] };

declare 'MapStringStartMigrationResponse',
    as HashRef[StartMigrationResponse()];

declare 'PauseMigrationRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::PauseMigrationRequest'];

coerce 'PauseMigrationRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::PauseMigrationRequest'->new($_) };

declare 'RepeatedPauseMigrationRequest',
    as ArrayRef[PauseMigrationRequest()];

coerce 'RepeatedPauseMigrationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::PauseMigrationRequest'->new($_) } @$_ ] };

declare 'MapStringPauseMigrationRequest',
    as HashRef[PauseMigrationRequest()];

declare 'PauseMigrationResponse',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::PauseMigrationResponse'];

coerce 'PauseMigrationResponse',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::PauseMigrationResponse'->new($_) };

declare 'RepeatedPauseMigrationResponse',
    as ArrayRef[PauseMigrationResponse()];

coerce 'RepeatedPauseMigrationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::PauseMigrationResponse'->new($_) } @$_ ] };

declare 'MapStringPauseMigrationResponse',
    as HashRef[PauseMigrationResponse()];

declare 'ResumeMigrationRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ResumeMigrationRequest'];

coerce 'ResumeMigrationRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ResumeMigrationRequest'->new($_) };

declare 'RepeatedResumeMigrationRequest',
    as ArrayRef[ResumeMigrationRequest()];

coerce 'RepeatedResumeMigrationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ResumeMigrationRequest'->new($_) } @$_ ] };

declare 'MapStringResumeMigrationRequest',
    as HashRef[ResumeMigrationRequest()];

declare 'ResumeMigrationResponse',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ResumeMigrationResponse'];

coerce 'ResumeMigrationResponse',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ResumeMigrationResponse'->new($_) };

declare 'RepeatedResumeMigrationResponse',
    as ArrayRef[ResumeMigrationResponse()];

coerce 'RepeatedResumeMigrationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ResumeMigrationResponse'->new($_) } @$_ ] };

declare 'MapStringResumeMigrationResponse',
    as HashRef[ResumeMigrationResponse()];

declare 'FinalizeMigrationRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::FinalizeMigrationRequest'];

coerce 'FinalizeMigrationRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::FinalizeMigrationRequest'->new($_) };

declare 'RepeatedFinalizeMigrationRequest',
    as ArrayRef[FinalizeMigrationRequest()];

coerce 'RepeatedFinalizeMigrationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::FinalizeMigrationRequest'->new($_) } @$_ ] };

declare 'MapStringFinalizeMigrationRequest',
    as HashRef[FinalizeMigrationRequest()];

declare 'ExtendMigrationRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ExtendMigrationRequest'];

coerce 'ExtendMigrationRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ExtendMigrationRequest'->new($_) };

declare 'RepeatedExtendMigrationRequest',
    as ArrayRef[ExtendMigrationRequest()];

coerce 'RepeatedExtendMigrationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ExtendMigrationRequest'->new($_) } @$_ ] };

declare 'MapStringExtendMigrationRequest',
    as HashRef[ExtendMigrationRequest()];

declare 'ExtendMigrationResponse',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ExtendMigrationResponse'];

coerce 'ExtendMigrationResponse',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ExtendMigrationResponse'->new($_) };

declare 'RepeatedExtendMigrationResponse',
    as ArrayRef[ExtendMigrationResponse()];

coerce 'RepeatedExtendMigrationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ExtendMigrationResponse'->new($_) } @$_ ] };

declare 'MapStringExtendMigrationResponse',
    as HashRef[ExtendMigrationResponse()];

declare 'FinalizeMigrationResponse',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::FinalizeMigrationResponse'];

coerce 'FinalizeMigrationResponse',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::FinalizeMigrationResponse'->new($_) };

declare 'RepeatedFinalizeMigrationResponse',
    as ArrayRef[FinalizeMigrationResponse()];

coerce 'RepeatedFinalizeMigrationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::FinalizeMigrationResponse'->new($_) } @$_ ] };

declare 'MapStringFinalizeMigrationResponse',
    as HashRef[FinalizeMigrationResponse()];

declare 'TargetProject',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::TargetProject'];

coerce 'TargetProject',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::TargetProject'->new($_) };

declare 'RepeatedTargetProject',
    as ArrayRef[TargetProject()];

coerce 'RepeatedTargetProject',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::TargetProject'->new($_) } @$_ ] };

declare 'MapStringTargetProject',
    as HashRef[TargetProject()];

declare 'GetTargetProjectRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::GetTargetProjectRequest'];

coerce 'GetTargetProjectRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::GetTargetProjectRequest'->new($_) };

declare 'RepeatedGetTargetProjectRequest',
    as ArrayRef[GetTargetProjectRequest()];

coerce 'RepeatedGetTargetProjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::GetTargetProjectRequest'->new($_) } @$_ ] };

declare 'MapStringGetTargetProjectRequest',
    as HashRef[GetTargetProjectRequest()];

declare 'ListTargetProjectsRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ListTargetProjectsRequest'];

coerce 'ListTargetProjectsRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListTargetProjectsRequest'->new($_) };

declare 'RepeatedListTargetProjectsRequest',
    as ArrayRef[ListTargetProjectsRequest()];

coerce 'RepeatedListTargetProjectsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListTargetProjectsRequest'->new($_) } @$_ ] };

declare 'MapStringListTargetProjectsRequest',
    as HashRef[ListTargetProjectsRequest()];

declare 'ListTargetProjectsResponse',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ListTargetProjectsResponse'];

coerce 'ListTargetProjectsResponse',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListTargetProjectsResponse'->new($_) };

declare 'RepeatedListTargetProjectsResponse',
    as ArrayRef[ListTargetProjectsResponse()];

coerce 'RepeatedListTargetProjectsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListTargetProjectsResponse'->new($_) } @$_ ] };

declare 'MapStringListTargetProjectsResponse',
    as HashRef[ListTargetProjectsResponse()];

declare 'CreateTargetProjectRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::CreateTargetProjectRequest'];

coerce 'CreateTargetProjectRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::CreateTargetProjectRequest'->new($_) };

declare 'RepeatedCreateTargetProjectRequest',
    as ArrayRef[CreateTargetProjectRequest()];

coerce 'RepeatedCreateTargetProjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::CreateTargetProjectRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTargetProjectRequest',
    as HashRef[CreateTargetProjectRequest()];

declare 'UpdateTargetProjectRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::UpdateTargetProjectRequest'];

coerce 'UpdateTargetProjectRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::UpdateTargetProjectRequest'->new($_) };

declare 'RepeatedUpdateTargetProjectRequest',
    as ArrayRef[UpdateTargetProjectRequest()];

coerce 'RepeatedUpdateTargetProjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::UpdateTargetProjectRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTargetProjectRequest',
    as HashRef[UpdateTargetProjectRequest()];

declare 'DeleteTargetProjectRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::DeleteTargetProjectRequest'];

coerce 'DeleteTargetProjectRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::DeleteTargetProjectRequest'->new($_) };

declare 'RepeatedDeleteTargetProjectRequest',
    as ArrayRef[DeleteTargetProjectRequest()];

coerce 'RepeatedDeleteTargetProjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::DeleteTargetProjectRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTargetProjectRequest',
    as HashRef[DeleteTargetProjectRequest()];

declare 'Group',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::Group'];

coerce 'Group',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::Group'->new($_) };

declare 'RepeatedGroup',
    as ArrayRef[Group()];

coerce 'RepeatedGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::Group'->new($_) } @$_ ] };

declare 'MapStringGroup',
    as HashRef[Group()];

declare 'MigrationTargetType',
    as (Int | Str);

declare 'ListGroupsRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ListGroupsRequest'];

coerce 'ListGroupsRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListGroupsRequest'->new($_) };

declare 'RepeatedListGroupsRequest',
    as ArrayRef[ListGroupsRequest()];

coerce 'RepeatedListGroupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListGroupsRequest'->new($_) } @$_ ] };

declare 'MapStringListGroupsRequest',
    as HashRef[ListGroupsRequest()];

declare 'ListGroupsResponse',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ListGroupsResponse'];

coerce 'ListGroupsResponse',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListGroupsResponse'->new($_) };

declare 'RepeatedListGroupsResponse',
    as ArrayRef[ListGroupsResponse()];

coerce 'RepeatedListGroupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListGroupsResponse'->new($_) } @$_ ] };

declare 'MapStringListGroupsResponse',
    as HashRef[ListGroupsResponse()];

declare 'GetGroupRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::GetGroupRequest'];

coerce 'GetGroupRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::GetGroupRequest'->new($_) };

declare 'RepeatedGetGroupRequest',
    as ArrayRef[GetGroupRequest()];

coerce 'RepeatedGetGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::GetGroupRequest'->new($_) } @$_ ] };

declare 'MapStringGetGroupRequest',
    as HashRef[GetGroupRequest()];

declare 'CreateGroupRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::CreateGroupRequest'];

coerce 'CreateGroupRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::CreateGroupRequest'->new($_) };

declare 'RepeatedCreateGroupRequest',
    as ArrayRef[CreateGroupRequest()];

coerce 'RepeatedCreateGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::CreateGroupRequest'->new($_) } @$_ ] };

declare 'MapStringCreateGroupRequest',
    as HashRef[CreateGroupRequest()];

declare 'UpdateGroupRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::UpdateGroupRequest'];

coerce 'UpdateGroupRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::UpdateGroupRequest'->new($_) };

declare 'RepeatedUpdateGroupRequest',
    as ArrayRef[UpdateGroupRequest()];

coerce 'RepeatedUpdateGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::UpdateGroupRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateGroupRequest',
    as HashRef[UpdateGroupRequest()];

declare 'DeleteGroupRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::DeleteGroupRequest'];

coerce 'DeleteGroupRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::DeleteGroupRequest'->new($_) };

declare 'RepeatedDeleteGroupRequest',
    as ArrayRef[DeleteGroupRequest()];

coerce 'RepeatedDeleteGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::DeleteGroupRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteGroupRequest',
    as HashRef[DeleteGroupRequest()];

declare 'AddGroupMigrationRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::AddGroupMigrationRequest'];

coerce 'AddGroupMigrationRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::AddGroupMigrationRequest'->new($_) };

declare 'RepeatedAddGroupMigrationRequest',
    as ArrayRef[AddGroupMigrationRequest()];

coerce 'RepeatedAddGroupMigrationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::AddGroupMigrationRequest'->new($_) } @$_ ] };

declare 'MapStringAddGroupMigrationRequest',
    as HashRef[AddGroupMigrationRequest()];

declare 'AddGroupMigrationResponse',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::AddGroupMigrationResponse'];

coerce 'AddGroupMigrationResponse',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::AddGroupMigrationResponse'->new($_) };

declare 'RepeatedAddGroupMigrationResponse',
    as ArrayRef[AddGroupMigrationResponse()];

coerce 'RepeatedAddGroupMigrationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::AddGroupMigrationResponse'->new($_) } @$_ ] };

declare 'MapStringAddGroupMigrationResponse',
    as HashRef[AddGroupMigrationResponse()];

declare 'RemoveGroupMigrationRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::RemoveGroupMigrationRequest'];

coerce 'RemoveGroupMigrationRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::RemoveGroupMigrationRequest'->new($_) };

declare 'RepeatedRemoveGroupMigrationRequest',
    as ArrayRef[RemoveGroupMigrationRequest()];

coerce 'RepeatedRemoveGroupMigrationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::RemoveGroupMigrationRequest'->new($_) } @$_ ] };

declare 'MapStringRemoveGroupMigrationRequest',
    as HashRef[RemoveGroupMigrationRequest()];

declare 'RemoveGroupMigrationResponse',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::RemoveGroupMigrationResponse'];

coerce 'RemoveGroupMigrationResponse',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::RemoveGroupMigrationResponse'->new($_) };

declare 'RepeatedRemoveGroupMigrationResponse',
    as ArrayRef[RemoveGroupMigrationResponse()];

coerce 'RepeatedRemoveGroupMigrationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::RemoveGroupMigrationResponse'->new($_) } @$_ ] };

declare 'MapStringRemoveGroupMigrationResponse',
    as HashRef[RemoveGroupMigrationResponse()];

declare 'CreateCutoverJobRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::CreateCutoverJobRequest'];

coerce 'CreateCutoverJobRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::CreateCutoverJobRequest'->new($_) };

declare 'RepeatedCreateCutoverJobRequest',
    as ArrayRef[CreateCutoverJobRequest()];

coerce 'RepeatedCreateCutoverJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::CreateCutoverJobRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCutoverJobRequest',
    as HashRef[CreateCutoverJobRequest()];

declare 'CancelCutoverJobRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::CancelCutoverJobRequest'];

coerce 'CancelCutoverJobRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::CancelCutoverJobRequest'->new($_) };

declare 'RepeatedCancelCutoverJobRequest',
    as ArrayRef[CancelCutoverJobRequest()];

coerce 'RepeatedCancelCutoverJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::CancelCutoverJobRequest'->new($_) } @$_ ] };

declare 'MapStringCancelCutoverJobRequest',
    as HashRef[CancelCutoverJobRequest()];

declare 'CancelCutoverJobResponse',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::CancelCutoverJobResponse'];

coerce 'CancelCutoverJobResponse',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::CancelCutoverJobResponse'->new($_) };

declare 'RepeatedCancelCutoverJobResponse',
    as ArrayRef[CancelCutoverJobResponse()];

coerce 'RepeatedCancelCutoverJobResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::CancelCutoverJobResponse'->new($_) } @$_ ] };

declare 'MapStringCancelCutoverJobResponse',
    as HashRef[CancelCutoverJobResponse()];

declare 'ListCutoverJobsRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ListCutoverJobsRequest'];

coerce 'ListCutoverJobsRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListCutoverJobsRequest'->new($_) };

declare 'RepeatedListCutoverJobsRequest',
    as ArrayRef[ListCutoverJobsRequest()];

coerce 'RepeatedListCutoverJobsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListCutoverJobsRequest'->new($_) } @$_ ] };

declare 'MapStringListCutoverJobsRequest',
    as HashRef[ListCutoverJobsRequest()];

declare 'ListCutoverJobsResponse',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ListCutoverJobsResponse'];

coerce 'ListCutoverJobsResponse',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListCutoverJobsResponse'->new($_) };

declare 'RepeatedListCutoverJobsResponse',
    as ArrayRef[ListCutoverJobsResponse()];

coerce 'RepeatedListCutoverJobsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListCutoverJobsResponse'->new($_) } @$_ ] };

declare 'MapStringListCutoverJobsResponse',
    as HashRef[ListCutoverJobsResponse()];

declare 'GetCutoverJobRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::GetCutoverJobRequest'];

coerce 'GetCutoverJobRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::GetCutoverJobRequest'->new($_) };

declare 'RepeatedGetCutoverJobRequest',
    as ArrayRef[GetCutoverJobRequest()];

coerce 'RepeatedGetCutoverJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::GetCutoverJobRequest'->new($_) } @$_ ] };

declare 'MapStringGetCutoverJobRequest',
    as HashRef[GetCutoverJobRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'MigrationError',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::MigrationError'];

coerce 'MigrationError',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::MigrationError'->new($_) };

declare 'RepeatedMigrationError',
    as ArrayRef[MigrationError()];

coerce 'RepeatedMigrationError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::MigrationError'->new($_) } @$_ ] };

declare 'MapStringMigrationError',
    as HashRef[MigrationError()];

declare 'ErrorCode',
    as (Int | Str);

declare 'MigrationWarning',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::MigrationWarning'];

coerce 'MigrationWarning',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::MigrationWarning'->new($_) };

declare 'RepeatedMigrationWarning',
    as ArrayRef[MigrationWarning()];

coerce 'RepeatedMigrationWarning',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::MigrationWarning'->new($_) } @$_ ] };

declare 'MapStringMigrationWarning',
    as HashRef[MigrationWarning()];

declare 'WarningCode',
    as (Int | Str);

declare 'VmwareSourceVmDetails',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::VmwareSourceVmDetails'];

coerce 'VmwareSourceVmDetails',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::VmwareSourceVmDetails'->new($_) };

declare 'RepeatedVmwareSourceVmDetails',
    as ArrayRef[VmwareSourceVmDetails()];

coerce 'RepeatedVmwareSourceVmDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::VmwareSourceVmDetails'->new($_) } @$_ ] };

declare 'MapStringVmwareSourceVmDetails',
    as HashRef[VmwareSourceVmDetails()];

declare 'Firmware',
    as (Int | Str);

declare 'VmwareDiskDetails',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::VmwareSourceVmDetails::VmwareDiskDetails'];

coerce 'VmwareDiskDetails',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::VmwareSourceVmDetails::VmwareDiskDetails'->new($_) };

declare 'RepeatedVmwareDiskDetails',
    as ArrayRef[VmwareDiskDetails()];

coerce 'RepeatedVmwareDiskDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::VmwareSourceVmDetails::VmwareDiskDetails'->new($_) } @$_ ] };

declare 'MapStringVmwareDiskDetails',
    as HashRef[VmwareDiskDetails()];

declare 'AwsSourceVmDetails',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::AwsSourceVmDetails'];

coerce 'AwsSourceVmDetails',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::AwsSourceVmDetails'->new($_) };

declare 'RepeatedAwsSourceVmDetails',
    as ArrayRef[AwsSourceVmDetails()];

coerce 'RepeatedAwsSourceVmDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::AwsSourceVmDetails'->new($_) } @$_ ] };

declare 'MapStringAwsSourceVmDetails',
    as HashRef[AwsSourceVmDetails()];

declare 'Firmware',
    as (Int | Str);

declare 'AwsDiskDetails',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::AwsSourceVmDetails::AwsDiskDetails'];

coerce 'AwsDiskDetails',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::AwsSourceVmDetails::AwsDiskDetails'->new($_) };

declare 'RepeatedAwsDiskDetails',
    as ArrayRef[AwsDiskDetails()];

coerce 'RepeatedAwsDiskDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::AwsSourceVmDetails::AwsDiskDetails'->new($_) } @$_ ] };

declare 'MapStringAwsDiskDetails',
    as HashRef[AwsDiskDetails()];

declare 'AzureSourceVmDetails',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::AzureSourceVmDetails'];

coerce 'AzureSourceVmDetails',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::AzureSourceVmDetails'->new($_) };

declare 'RepeatedAzureSourceVmDetails',
    as ArrayRef[AzureSourceVmDetails()];

coerce 'RepeatedAzureSourceVmDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::AzureSourceVmDetails'->new($_) } @$_ ] };

declare 'MapStringAzureSourceVmDetails',
    as HashRef[AzureSourceVmDetails()];

declare 'Firmware',
    as (Int | Str);

declare 'AzureDiskDetails',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::AzureSourceVmDetails::AzureDiskDetails'];

coerce 'AzureDiskDetails',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::AzureSourceVmDetails::AzureDiskDetails'->new($_) };

declare 'RepeatedAzureDiskDetails',
    as ArrayRef[AzureDiskDetails()];

coerce 'RepeatedAzureDiskDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::AzureSourceVmDetails::AzureDiskDetails'->new($_) } @$_ ] };

declare 'MapStringAzureDiskDetails',
    as HashRef[AzureDiskDetails()];

declare 'ListReplicationCyclesRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ListReplicationCyclesRequest'];

coerce 'ListReplicationCyclesRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListReplicationCyclesRequest'->new($_) };

declare 'RepeatedListReplicationCyclesRequest',
    as ArrayRef[ListReplicationCyclesRequest()];

coerce 'RepeatedListReplicationCyclesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListReplicationCyclesRequest'->new($_) } @$_ ] };

declare 'MapStringListReplicationCyclesRequest',
    as HashRef[ListReplicationCyclesRequest()];

declare 'ListReplicationCyclesResponse',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ListReplicationCyclesResponse'];

coerce 'ListReplicationCyclesResponse',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListReplicationCyclesResponse'->new($_) };

declare 'RepeatedListReplicationCyclesResponse',
    as ArrayRef[ListReplicationCyclesResponse()];

coerce 'RepeatedListReplicationCyclesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListReplicationCyclesResponse'->new($_) } @$_ ] };

declare 'MapStringListReplicationCyclesResponse',
    as HashRef[ListReplicationCyclesResponse()];

declare 'GetReplicationCycleRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::GetReplicationCycleRequest'];

coerce 'GetReplicationCycleRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::GetReplicationCycleRequest'->new($_) };

declare 'RepeatedGetReplicationCycleRequest',
    as ArrayRef[GetReplicationCycleRequest()];

coerce 'RepeatedGetReplicationCycleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::GetReplicationCycleRequest'->new($_) } @$_ ] };

declare 'MapStringGetReplicationCycleRequest',
    as HashRef[GetReplicationCycleRequest()];

declare 'VmCapabilities',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::VmCapabilities'];

coerce 'VmCapabilities',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::VmCapabilities'->new($_) };

declare 'RepeatedVmCapabilities',
    as ArrayRef[VmCapabilities()];

coerce 'RepeatedVmCapabilities',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::VmCapabilities'->new($_) } @$_ ] };

declare 'MapStringVmCapabilities',
    as HashRef[VmCapabilities()];

declare 'ImageImport',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ImageImport'];

coerce 'ImageImport',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ImageImport'->new($_) };

declare 'RepeatedImageImport',
    as ArrayRef[ImageImport()];

coerce 'RepeatedImageImport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ImageImport'->new($_) } @$_ ] };

declare 'MapStringImageImport',
    as HashRef[ImageImport()];

declare 'ImageImportJob',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ImageImportJob'];

coerce 'ImageImportJob',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ImageImportJob'->new($_) };

declare 'RepeatedImageImportJob',
    as ArrayRef[ImageImportJob()];

coerce 'RepeatedImageImportJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ImageImportJob'->new($_) } @$_ ] };

declare 'MapStringImageImportJob',
    as HashRef[ImageImportJob()];

declare 'State',
    as (Int | Str);

declare 'ImageImportStep',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ImageImportStep'];

coerce 'ImageImportStep',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ImageImportStep'->new($_) };

declare 'RepeatedImageImportStep',
    as ArrayRef[ImageImportStep()];

coerce 'RepeatedImageImportStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ImageImportStep'->new($_) } @$_ ] };

declare 'MapStringImageImportStep',
    as HashRef[ImageImportStep()];

declare 'InitializingImageImportStep',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::InitializingImageImportStep'];

coerce 'InitializingImageImportStep',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::InitializingImageImportStep'->new($_) };

declare 'RepeatedInitializingImageImportStep',
    as ArrayRef[InitializingImageImportStep()];

coerce 'RepeatedInitializingImageImportStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::InitializingImageImportStep'->new($_) } @$_ ] };

declare 'MapStringInitializingImageImportStep',
    as HashRef[InitializingImageImportStep()];

declare 'LoadingImageSourceFilesStep',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::LoadingImageSourceFilesStep'];

coerce 'LoadingImageSourceFilesStep',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::LoadingImageSourceFilesStep'->new($_) };

declare 'RepeatedLoadingImageSourceFilesStep',
    as ArrayRef[LoadingImageSourceFilesStep()];

coerce 'RepeatedLoadingImageSourceFilesStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::LoadingImageSourceFilesStep'->new($_) } @$_ ] };

declare 'MapStringLoadingImageSourceFilesStep',
    as HashRef[LoadingImageSourceFilesStep()];

declare 'CreatingImageStep',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::CreatingImageStep'];

coerce 'CreatingImageStep',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::CreatingImageStep'->new($_) };

declare 'RepeatedCreatingImageStep',
    as ArrayRef[CreatingImageStep()];

coerce 'RepeatedCreatingImageStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::CreatingImageStep'->new($_) } @$_ ] };

declare 'MapStringCreatingImageStep',
    as HashRef[CreatingImageStep()];

declare 'DiskImageTargetDetails',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::DiskImageTargetDetails'];

coerce 'DiskImageTargetDetails',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::DiskImageTargetDetails'->new($_) };

declare 'RepeatedDiskImageTargetDetails',
    as ArrayRef[DiskImageTargetDetails()];

coerce 'RepeatedDiskImageTargetDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::DiskImageTargetDetails'->new($_) } @$_ ] };

declare 'MapStringDiskImageTargetDetails',
    as HashRef[DiskImageTargetDetails()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::DiskImageTargetDetails::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::DiskImageTargetDetails::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::DiskImageTargetDetails::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'MachineImageTargetDetails',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::MachineImageTargetDetails'];

coerce 'MachineImageTargetDetails',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::MachineImageTargetDetails'->new($_) };

declare 'RepeatedMachineImageTargetDetails',
    as ArrayRef[MachineImageTargetDetails()];

coerce 'RepeatedMachineImageTargetDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::MachineImageTargetDetails'->new($_) } @$_ ] };

declare 'MapStringMachineImageTargetDetails',
    as HashRef[MachineImageTargetDetails()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::MachineImageTargetDetails::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::MachineImageTargetDetails::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::MachineImageTargetDetails::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ServiceAccount',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ServiceAccount'];

coerce 'ServiceAccount',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ServiceAccount'->new($_) };

declare 'RepeatedServiceAccount',
    as ArrayRef[ServiceAccount()];

coerce 'RepeatedServiceAccount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ServiceAccount'->new($_) } @$_ ] };

declare 'MapStringServiceAccount',
    as HashRef[ServiceAccount()];

declare 'ShieldedInstanceConfig',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ShieldedInstanceConfig'];

coerce 'ShieldedInstanceConfig',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ShieldedInstanceConfig'->new($_) };

declare 'RepeatedShieldedInstanceConfig',
    as ArrayRef[ShieldedInstanceConfig()];

coerce 'RepeatedShieldedInstanceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ShieldedInstanceConfig'->new($_) } @$_ ] };

declare 'MapStringShieldedInstanceConfig',
    as HashRef[ShieldedInstanceConfig()];

declare 'SecureBoot',
    as (Int | Str);

declare 'MachineImageParametersOverrides',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::MachineImageParametersOverrides'];

coerce 'MachineImageParametersOverrides',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::MachineImageParametersOverrides'->new($_) };

declare 'RepeatedMachineImageParametersOverrides',
    as ArrayRef[MachineImageParametersOverrides()];

coerce 'RepeatedMachineImageParametersOverrides',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::MachineImageParametersOverrides'->new($_) } @$_ ] };

declare 'MapStringMachineImageParametersOverrides',
    as HashRef[MachineImageParametersOverrides()];

declare 'ImageImportOsAdaptationParameters',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ImageImportOsAdaptationParameters'];

coerce 'ImageImportOsAdaptationParameters',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ImageImportOsAdaptationParameters'->new($_) };

declare 'RepeatedImageImportOsAdaptationParameters',
    as ArrayRef[ImageImportOsAdaptationParameters()];

coerce 'RepeatedImageImportOsAdaptationParameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ImageImportOsAdaptationParameters'->new($_) } @$_ ] };

declare 'MapStringImageImportOsAdaptationParameters',
    as HashRef[ImageImportOsAdaptationParameters()];

declare 'DataDiskImageImport',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::DataDiskImageImport'];

coerce 'DataDiskImageImport',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::DataDiskImageImport'->new($_) };

declare 'RepeatedDataDiskImageImport',
    as ArrayRef[DataDiskImageImport()];

coerce 'RepeatedDataDiskImageImport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::DataDiskImageImport'->new($_) } @$_ ] };

declare 'MapStringDataDiskImageImport',
    as HashRef[DataDiskImageImport()];

declare 'SkipOsAdaptation',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::SkipOsAdaptation'];

coerce 'SkipOsAdaptation',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::SkipOsAdaptation'->new($_) };

declare 'RepeatedSkipOsAdaptation',
    as ArrayRef[SkipOsAdaptation()];

coerce 'RepeatedSkipOsAdaptation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::SkipOsAdaptation'->new($_) } @$_ ] };

declare 'MapStringSkipOsAdaptation',
    as HashRef[SkipOsAdaptation()];

declare 'GetImageImportRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::GetImageImportRequest'];

coerce 'GetImageImportRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::GetImageImportRequest'->new($_) };

declare 'RepeatedGetImageImportRequest',
    as ArrayRef[GetImageImportRequest()];

coerce 'RepeatedGetImageImportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::GetImageImportRequest'->new($_) } @$_ ] };

declare 'MapStringGetImageImportRequest',
    as HashRef[GetImageImportRequest()];

declare 'ListImageImportsRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ListImageImportsRequest'];

coerce 'ListImageImportsRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListImageImportsRequest'->new($_) };

declare 'RepeatedListImageImportsRequest',
    as ArrayRef[ListImageImportsRequest()];

coerce 'RepeatedListImageImportsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListImageImportsRequest'->new($_) } @$_ ] };

declare 'MapStringListImageImportsRequest',
    as HashRef[ListImageImportsRequest()];

declare 'ListImageImportsResponse',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ListImageImportsResponse'];

coerce 'ListImageImportsResponse',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListImageImportsResponse'->new($_) };

declare 'RepeatedListImageImportsResponse',
    as ArrayRef[ListImageImportsResponse()];

coerce 'RepeatedListImageImportsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListImageImportsResponse'->new($_) } @$_ ] };

declare 'MapStringListImageImportsResponse',
    as HashRef[ListImageImportsResponse()];

declare 'CreateImageImportRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::CreateImageImportRequest'];

coerce 'CreateImageImportRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::CreateImageImportRequest'->new($_) };

declare 'RepeatedCreateImageImportRequest',
    as ArrayRef[CreateImageImportRequest()];

coerce 'RepeatedCreateImageImportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::CreateImageImportRequest'->new($_) } @$_ ] };

declare 'MapStringCreateImageImportRequest',
    as HashRef[CreateImageImportRequest()];

declare 'DeleteImageImportRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::DeleteImageImportRequest'];

coerce 'DeleteImageImportRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::DeleteImageImportRequest'->new($_) };

declare 'RepeatedDeleteImageImportRequest',
    as ArrayRef[DeleteImageImportRequest()];

coerce 'RepeatedDeleteImageImportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::DeleteImageImportRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteImageImportRequest',
    as HashRef[DeleteImageImportRequest()];

declare 'GetImageImportJobRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::GetImageImportJobRequest'];

coerce 'GetImageImportJobRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::GetImageImportJobRequest'->new($_) };

declare 'RepeatedGetImageImportJobRequest',
    as ArrayRef[GetImageImportJobRequest()];

coerce 'RepeatedGetImageImportJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::GetImageImportJobRequest'->new($_) } @$_ ] };

declare 'MapStringGetImageImportJobRequest',
    as HashRef[GetImageImportJobRequest()];

declare 'ListImageImportJobsRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ListImageImportJobsRequest'];

coerce 'ListImageImportJobsRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListImageImportJobsRequest'->new($_) };

declare 'RepeatedListImageImportJobsRequest',
    as ArrayRef[ListImageImportJobsRequest()];

coerce 'RepeatedListImageImportJobsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListImageImportJobsRequest'->new($_) } @$_ ] };

declare 'MapStringListImageImportJobsRequest',
    as HashRef[ListImageImportJobsRequest()];

declare 'ListImageImportJobsResponse',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ListImageImportJobsResponse'];

coerce 'ListImageImportJobsResponse',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListImageImportJobsResponse'->new($_) };

declare 'RepeatedListImageImportJobsResponse',
    as ArrayRef[ListImageImportJobsResponse()];

coerce 'RepeatedListImageImportJobsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListImageImportJobsResponse'->new($_) } @$_ ] };

declare 'MapStringListImageImportJobsResponse',
    as HashRef[ListImageImportJobsResponse()];

declare 'CancelImageImportJobRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::CancelImageImportJobRequest'];

coerce 'CancelImageImportJobRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::CancelImageImportJobRequest'->new($_) };

declare 'RepeatedCancelImageImportJobRequest',
    as ArrayRef[CancelImageImportJobRequest()];

coerce 'RepeatedCancelImageImportJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::CancelImageImportJobRequest'->new($_) } @$_ ] };

declare 'MapStringCancelImageImportJobRequest',
    as HashRef[CancelImageImportJobRequest()];

declare 'CancelImageImportJobResponse',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::CancelImageImportJobResponse'];

coerce 'CancelImageImportJobResponse',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::CancelImageImportJobResponse'->new($_) };

declare 'RepeatedCancelImageImportJobResponse',
    as ArrayRef[CancelImageImportJobResponse()];

coerce 'RepeatedCancelImageImportJobResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::CancelImageImportJobResponse'->new($_) } @$_ ] };

declare 'MapStringCancelImageImportJobResponse',
    as HashRef[CancelImageImportJobResponse()];

declare 'DiskMigrationJob',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::DiskMigrationJob'];

coerce 'DiskMigrationJob',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::DiskMigrationJob'->new($_) };

declare 'RepeatedDiskMigrationJob',
    as ArrayRef[DiskMigrationJob()];

coerce 'RepeatedDiskMigrationJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::DiskMigrationJob'->new($_) } @$_ ] };

declare 'MapStringDiskMigrationJob',
    as HashRef[DiskMigrationJob()];

declare 'State',
    as (Int | Str);

declare 'DiskMigrationJobTargetDetails',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::DiskMigrationJobTargetDetails'];

coerce 'DiskMigrationJobTargetDetails',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::DiskMigrationJobTargetDetails'->new($_) };

declare 'RepeatedDiskMigrationJobTargetDetails',
    as ArrayRef[DiskMigrationJobTargetDetails()];

coerce 'RepeatedDiskMigrationJobTargetDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::DiskMigrationJobTargetDetails'->new($_) } @$_ ] };

declare 'MapStringDiskMigrationJobTargetDetails',
    as HashRef[DiskMigrationJobTargetDetails()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::DiskMigrationJobTargetDetails::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::DiskMigrationJobTargetDetails::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::DiskMigrationJobTargetDetails::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'DiskMigrationStep',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::DiskMigrationStep'];

coerce 'DiskMigrationStep',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::DiskMigrationStep'->new($_) };

declare 'RepeatedDiskMigrationStep',
    as ArrayRef[DiskMigrationStep()];

coerce 'RepeatedDiskMigrationStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::DiskMigrationStep'->new($_) } @$_ ] };

declare 'MapStringDiskMigrationStep',
    as HashRef[DiskMigrationStep()];

declare 'CreatingSourceDiskSnapshotStep',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::CreatingSourceDiskSnapshotStep'];

coerce 'CreatingSourceDiskSnapshotStep',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::CreatingSourceDiskSnapshotStep'->new($_) };

declare 'RepeatedCreatingSourceDiskSnapshotStep',
    as ArrayRef[CreatingSourceDiskSnapshotStep()];

coerce 'RepeatedCreatingSourceDiskSnapshotStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::CreatingSourceDiskSnapshotStep'->new($_) } @$_ ] };

declare 'MapStringCreatingSourceDiskSnapshotStep',
    as HashRef[CreatingSourceDiskSnapshotStep()];

declare 'CopyingSourceDiskSnapshotStep',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::CopyingSourceDiskSnapshotStep'];

coerce 'CopyingSourceDiskSnapshotStep',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::CopyingSourceDiskSnapshotStep'->new($_) };

declare 'RepeatedCopyingSourceDiskSnapshotStep',
    as ArrayRef[CopyingSourceDiskSnapshotStep()];

coerce 'RepeatedCopyingSourceDiskSnapshotStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::CopyingSourceDiskSnapshotStep'->new($_) } @$_ ] };

declare 'MapStringCopyingSourceDiskSnapshotStep',
    as HashRef[CopyingSourceDiskSnapshotStep()];

declare 'ProvisioningTargetDiskStep',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ProvisioningTargetDiskStep'];

coerce 'ProvisioningTargetDiskStep',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ProvisioningTargetDiskStep'->new($_) };

declare 'RepeatedProvisioningTargetDiskStep',
    as ArrayRef[ProvisioningTargetDiskStep()];

coerce 'RepeatedProvisioningTargetDiskStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ProvisioningTargetDiskStep'->new($_) } @$_ ] };

declare 'MapStringProvisioningTargetDiskStep',
    as HashRef[ProvisioningTargetDiskStep()];

declare 'ComputeEngineDisk',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ComputeEngineDisk'];

coerce 'ComputeEngineDisk',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ComputeEngineDisk'->new($_) };

declare 'RepeatedComputeEngineDisk',
    as ArrayRef[ComputeEngineDisk()];

coerce 'RepeatedComputeEngineDisk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ComputeEngineDisk'->new($_) } @$_ ] };

declare 'MapStringComputeEngineDisk',
    as HashRef[ComputeEngineDisk()];

declare 'AwsSourceDiskDetails',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::AwsSourceDiskDetails'];

coerce 'AwsSourceDiskDetails',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::AwsSourceDiskDetails'->new($_) };

declare 'RepeatedAwsSourceDiskDetails',
    as ArrayRef[AwsSourceDiskDetails()];

coerce 'RepeatedAwsSourceDiskDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::AwsSourceDiskDetails'->new($_) } @$_ ] };

declare 'MapStringAwsSourceDiskDetails',
    as HashRef[AwsSourceDiskDetails()];

declare 'Type',
    as (Int | Str);

declare 'TagsEntry',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::AwsSourceDiskDetails::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::AwsSourceDiskDetails::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::AwsSourceDiskDetails::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

declare 'CreateDiskMigrationJobRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::CreateDiskMigrationJobRequest'];

coerce 'CreateDiskMigrationJobRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::CreateDiskMigrationJobRequest'->new($_) };

declare 'RepeatedCreateDiskMigrationJobRequest',
    as ArrayRef[CreateDiskMigrationJobRequest()];

coerce 'RepeatedCreateDiskMigrationJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::CreateDiskMigrationJobRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDiskMigrationJobRequest',
    as HashRef[CreateDiskMigrationJobRequest()];

declare 'ListDiskMigrationJobsRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ListDiskMigrationJobsRequest'];

coerce 'ListDiskMigrationJobsRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListDiskMigrationJobsRequest'->new($_) };

declare 'RepeatedListDiskMigrationJobsRequest',
    as ArrayRef[ListDiskMigrationJobsRequest()];

coerce 'RepeatedListDiskMigrationJobsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListDiskMigrationJobsRequest'->new($_) } @$_ ] };

declare 'MapStringListDiskMigrationJobsRequest',
    as HashRef[ListDiskMigrationJobsRequest()];

declare 'ListDiskMigrationJobsResponse',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::ListDiskMigrationJobsResponse'];

coerce 'ListDiskMigrationJobsResponse',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListDiskMigrationJobsResponse'->new($_) };

declare 'RepeatedListDiskMigrationJobsResponse',
    as ArrayRef[ListDiskMigrationJobsResponse()];

coerce 'RepeatedListDiskMigrationJobsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::ListDiskMigrationJobsResponse'->new($_) } @$_ ] };

declare 'MapStringListDiskMigrationJobsResponse',
    as HashRef[ListDiskMigrationJobsResponse()];

declare 'GetDiskMigrationJobRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::GetDiskMigrationJobRequest'];

coerce 'GetDiskMigrationJobRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::GetDiskMigrationJobRequest'->new($_) };

declare 'RepeatedGetDiskMigrationJobRequest',
    as ArrayRef[GetDiskMigrationJobRequest()];

coerce 'RepeatedGetDiskMigrationJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::GetDiskMigrationJobRequest'->new($_) } @$_ ] };

declare 'MapStringGetDiskMigrationJobRequest',
    as HashRef[GetDiskMigrationJobRequest()];

declare 'UpdateDiskMigrationJobRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::UpdateDiskMigrationJobRequest'];

coerce 'UpdateDiskMigrationJobRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::UpdateDiskMigrationJobRequest'->new($_) };

declare 'RepeatedUpdateDiskMigrationJobRequest',
    as ArrayRef[UpdateDiskMigrationJobRequest()];

coerce 'RepeatedUpdateDiskMigrationJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::UpdateDiskMigrationJobRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDiskMigrationJobRequest',
    as HashRef[UpdateDiskMigrationJobRequest()];

declare 'DeleteDiskMigrationJobRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::DeleteDiskMigrationJobRequest'];

coerce 'DeleteDiskMigrationJobRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::DeleteDiskMigrationJobRequest'->new($_) };

declare 'RepeatedDeleteDiskMigrationJobRequest',
    as ArrayRef[DeleteDiskMigrationJobRequest()];

coerce 'RepeatedDeleteDiskMigrationJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::DeleteDiskMigrationJobRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDiskMigrationJobRequest',
    as HashRef[DeleteDiskMigrationJobRequest()];

declare 'RunDiskMigrationJobRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::RunDiskMigrationJobRequest'];

coerce 'RunDiskMigrationJobRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::RunDiskMigrationJobRequest'->new($_) };

declare 'RepeatedRunDiskMigrationJobRequest',
    as ArrayRef[RunDiskMigrationJobRequest()];

coerce 'RepeatedRunDiskMigrationJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::RunDiskMigrationJobRequest'->new($_) } @$_ ] };

declare 'MapStringRunDiskMigrationJobRequest',
    as HashRef[RunDiskMigrationJobRequest()];

declare 'RunDiskMigrationJobResponse',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::RunDiskMigrationJobResponse'];

coerce 'RunDiskMigrationJobResponse',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::RunDiskMigrationJobResponse'->new($_) };

declare 'RepeatedRunDiskMigrationJobResponse',
    as ArrayRef[RunDiskMigrationJobResponse()];

coerce 'RepeatedRunDiskMigrationJobResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::RunDiskMigrationJobResponse'->new($_) } @$_ ] };

declare 'MapStringRunDiskMigrationJobResponse',
    as HashRef[RunDiskMigrationJobResponse()];

declare 'CancelDiskMigrationJobRequest',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::CancelDiskMigrationJobRequest'];

coerce 'CancelDiskMigrationJobRequest',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::CancelDiskMigrationJobRequest'->new($_) };

declare 'RepeatedCancelDiskMigrationJobRequest',
    as ArrayRef[CancelDiskMigrationJobRequest()];

coerce 'RepeatedCancelDiskMigrationJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::CancelDiskMigrationJobRequest'->new($_) } @$_ ] };

declare 'MapStringCancelDiskMigrationJobRequest',
    as HashRef[CancelDiskMigrationJobRequest()];

declare 'CancelDiskMigrationJobResponse',
    as InstanceOf['Google::Cloud::Vmmigration::V1::Vmmigration::CancelDiskMigrationJobResponse'];

coerce 'CancelDiskMigrationJobResponse',
    from HashRef, via { 'Google::Cloud::Vmmigration::V1::Vmmigration::CancelDiskMigrationJobResponse'->new($_) };

declare 'RepeatedCancelDiskMigrationJobResponse',
    as ArrayRef[CancelDiskMigrationJobResponse()];

coerce 'RepeatedCancelDiskMigrationJobResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmmigration::V1::Vmmigration::CancelDiskMigrationJobResponse'->new($_) } @$_ ] };

declare 'MapStringCancelDiskMigrationJobResponse',
    as HashRef[CancelDiskMigrationJobResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Vmmigration::V1::Vmmigration::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
