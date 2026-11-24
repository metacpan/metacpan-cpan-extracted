package Google::Cloud::Netapp::V1::Volume::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Protocols',
    as (Int | Str);

declare 'AccessType',
    as (Int | Str);

declare 'SMBSettings',
    as (Int | Str);

declare 'SplitState',
    as (Int | Str);

declare 'SecurityStyle',
    as (Int | Str);

declare 'RestrictedAction',
    as (Int | Str);

declare 'ListVolumesRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::ListVolumesRequest'];

coerce 'ListVolumesRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::ListVolumesRequest'->new($_) };

declare 'RepeatedListVolumesRequest',
    as ArrayRef[ListVolumesRequest()];

coerce 'RepeatedListVolumesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::ListVolumesRequest'->new($_) } @$_ ] };

declare 'MapStringListVolumesRequest',
    as HashRef[ListVolumesRequest()];

declare 'ListVolumesResponse',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::ListVolumesResponse'];

coerce 'ListVolumesResponse',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::ListVolumesResponse'->new($_) };

declare 'RepeatedListVolumesResponse',
    as ArrayRef[ListVolumesResponse()];

coerce 'RepeatedListVolumesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::ListVolumesResponse'->new($_) } @$_ ] };

declare 'MapStringListVolumesResponse',
    as HashRef[ListVolumesResponse()];

declare 'ListBackupConfigsRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::ListBackupConfigsRequest'];

coerce 'ListBackupConfigsRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::ListBackupConfigsRequest'->new($_) };

declare 'RepeatedListBackupConfigsRequest',
    as ArrayRef[ListBackupConfigsRequest()];

coerce 'RepeatedListBackupConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::ListBackupConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListBackupConfigsRequest',
    as HashRef[ListBackupConfigsRequest()];

declare 'ListBackupConfigsResponse',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::ListBackupConfigsResponse'];

coerce 'ListBackupConfigsResponse',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::ListBackupConfigsResponse'->new($_) };

declare 'RepeatedListBackupConfigsResponse',
    as ArrayRef[ListBackupConfigsResponse()];

coerce 'RepeatedListBackupConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::ListBackupConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListBackupConfigsResponse',
    as HashRef[ListBackupConfigsResponse()];

declare 'VolumeBackupConfig',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::VolumeBackupConfig'];

coerce 'VolumeBackupConfig',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::VolumeBackupConfig'->new($_) };

declare 'RepeatedVolumeBackupConfig',
    as ArrayRef[VolumeBackupConfig()];

coerce 'RepeatedVolumeBackupConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::VolumeBackupConfig'->new($_) } @$_ ] };

declare 'MapStringVolumeBackupConfig',
    as HashRef[VolumeBackupConfig()];

declare 'GetVolumeRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::GetVolumeRequest'];

coerce 'GetVolumeRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::GetVolumeRequest'->new($_) };

declare 'RepeatedGetVolumeRequest',
    as ArrayRef[GetVolumeRequest()];

coerce 'RepeatedGetVolumeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::GetVolumeRequest'->new($_) } @$_ ] };

declare 'MapStringGetVolumeRequest',
    as HashRef[GetVolumeRequest()];

declare 'CreateVolumeRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::CreateVolumeRequest'];

coerce 'CreateVolumeRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::CreateVolumeRequest'->new($_) };

declare 'RepeatedCreateVolumeRequest',
    as ArrayRef[CreateVolumeRequest()];

coerce 'RepeatedCreateVolumeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::CreateVolumeRequest'->new($_) } @$_ ] };

declare 'MapStringCreateVolumeRequest',
    as HashRef[CreateVolumeRequest()];

declare 'UpdateVolumeRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::UpdateVolumeRequest'];

coerce 'UpdateVolumeRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::UpdateVolumeRequest'->new($_) };

declare 'RepeatedUpdateVolumeRequest',
    as ArrayRef[UpdateVolumeRequest()];

coerce 'RepeatedUpdateVolumeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::UpdateVolumeRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateVolumeRequest',
    as HashRef[UpdateVolumeRequest()];

declare 'DeleteVolumeRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::DeleteVolumeRequest'];

coerce 'DeleteVolumeRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::DeleteVolumeRequest'->new($_) };

declare 'RepeatedDeleteVolumeRequest',
    as ArrayRef[DeleteVolumeRequest()];

coerce 'RepeatedDeleteVolumeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::DeleteVolumeRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteVolumeRequest',
    as HashRef[DeleteVolumeRequest()];

declare 'RevertVolumeRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::RevertVolumeRequest'];

coerce 'RevertVolumeRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::RevertVolumeRequest'->new($_) };

declare 'RepeatedRevertVolumeRequest',
    as ArrayRef[RevertVolumeRequest()];

coerce 'RepeatedRevertVolumeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::RevertVolumeRequest'->new($_) } @$_ ] };

declare 'MapStringRevertVolumeRequest',
    as HashRef[RevertVolumeRequest()];

declare 'StartSplitRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::StartSplitRequest'];

coerce 'StartSplitRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::StartSplitRequest'->new($_) };

declare 'RepeatedStartSplitRequest',
    as ArrayRef[StartSplitRequest()];

coerce 'RepeatedStartSplitRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::StartSplitRequest'->new($_) } @$_ ] };

declare 'MapStringStartSplitRequest',
    as HashRef[StartSplitRequest()];

declare 'GetSplitStatusRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::GetSplitStatusRequest'];

coerce 'GetSplitStatusRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::GetSplitStatusRequest'->new($_) };

declare 'RepeatedGetSplitStatusRequest',
    as ArrayRef[GetSplitStatusRequest()];

coerce 'RepeatedGetSplitStatusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::GetSplitStatusRequest'->new($_) } @$_ ] };

declare 'MapStringGetSplitStatusRequest',
    as HashRef[GetSplitStatusRequest()];

declare 'SplitStatus',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::SplitStatus'];

coerce 'SplitStatus',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::SplitStatus'->new($_) };

declare 'RepeatedSplitStatus',
    as ArrayRef[SplitStatus()];

coerce 'RepeatedSplitStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::SplitStatus'->new($_) } @$_ ] };

declare 'MapStringSplitStatus',
    as HashRef[SplitStatus()];

declare 'Volume',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::Volume'];

coerce 'Volume',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::Volume'->new($_) };

declare 'RepeatedVolume',
    as ArrayRef[Volume()];

coerce 'RepeatedVolume',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::Volume'->new($_) } @$_ ] };

declare 'MapStringVolume',
    as HashRef[Volume()];

declare 'State',
    as (Int | Str);

declare 'CloneDetails',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::Volume::CloneDetails'];

coerce 'CloneDetails',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::Volume::CloneDetails'->new($_) };

declare 'RepeatedCloneDetails',
    as ArrayRef[CloneDetails()];

coerce 'RepeatedCloneDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::Volume::CloneDetails'->new($_) } @$_ ] };

declare 'MapStringCloneDetails',
    as HashRef[CloneDetails()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::Volume::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::Volume::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::Volume::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'LargeCapacityConfig',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::LargeCapacityConfig'];

coerce 'LargeCapacityConfig',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::LargeCapacityConfig'->new($_) };

declare 'RepeatedLargeCapacityConfig',
    as ArrayRef[LargeCapacityConfig()];

coerce 'RepeatedLargeCapacityConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::LargeCapacityConfig'->new($_) } @$_ ] };

declare 'MapStringLargeCapacityConfig',
    as HashRef[LargeCapacityConfig()];

declare 'ExportPolicy',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::ExportPolicy'];

coerce 'ExportPolicy',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::ExportPolicy'->new($_) };

declare 'RepeatedExportPolicy',
    as ArrayRef[ExportPolicy()];

coerce 'RepeatedExportPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::ExportPolicy'->new($_) } @$_ ] };

declare 'MapStringExportPolicy',
    as HashRef[ExportPolicy()];

declare 'SimpleExportPolicyRule',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::SimpleExportPolicyRule'];

coerce 'SimpleExportPolicyRule',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::SimpleExportPolicyRule'->new($_) };

declare 'RepeatedSimpleExportPolicyRule',
    as ArrayRef[SimpleExportPolicyRule()];

coerce 'RepeatedSimpleExportPolicyRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::SimpleExportPolicyRule'->new($_) } @$_ ] };

declare 'MapStringSimpleExportPolicyRule',
    as HashRef[SimpleExportPolicyRule()];

declare 'SquashMode',
    as (Int | Str);

declare 'SnapshotPolicy',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::SnapshotPolicy'];

coerce 'SnapshotPolicy',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::SnapshotPolicy'->new($_) };

declare 'RepeatedSnapshotPolicy',
    as ArrayRef[SnapshotPolicy()];

coerce 'RepeatedSnapshotPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::SnapshotPolicy'->new($_) } @$_ ] };

declare 'MapStringSnapshotPolicy',
    as HashRef[SnapshotPolicy()];

declare 'HourlySchedule',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::HourlySchedule'];

coerce 'HourlySchedule',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::HourlySchedule'->new($_) };

declare 'RepeatedHourlySchedule',
    as ArrayRef[HourlySchedule()];

coerce 'RepeatedHourlySchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::HourlySchedule'->new($_) } @$_ ] };

declare 'MapStringHourlySchedule',
    as HashRef[HourlySchedule()];

declare 'DailySchedule',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::DailySchedule'];

coerce 'DailySchedule',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::DailySchedule'->new($_) };

declare 'RepeatedDailySchedule',
    as ArrayRef[DailySchedule()];

coerce 'RepeatedDailySchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::DailySchedule'->new($_) } @$_ ] };

declare 'MapStringDailySchedule',
    as HashRef[DailySchedule()];

declare 'WeeklySchedule',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::WeeklySchedule'];

coerce 'WeeklySchedule',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::WeeklySchedule'->new($_) };

declare 'RepeatedWeeklySchedule',
    as ArrayRef[WeeklySchedule()];

coerce 'RepeatedWeeklySchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::WeeklySchedule'->new($_) } @$_ ] };

declare 'MapStringWeeklySchedule',
    as HashRef[WeeklySchedule()];

declare 'MonthlySchedule',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::MonthlySchedule'];

coerce 'MonthlySchedule',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::MonthlySchedule'->new($_) };

declare 'RepeatedMonthlySchedule',
    as ArrayRef[MonthlySchedule()];

coerce 'RepeatedMonthlySchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::MonthlySchedule'->new($_) } @$_ ] };

declare 'MapStringMonthlySchedule',
    as HashRef[MonthlySchedule()];

declare 'MountOption',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::MountOption'];

coerce 'MountOption',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::MountOption'->new($_) };

declare 'RepeatedMountOption',
    as ArrayRef[MountOption()];

coerce 'RepeatedMountOption',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::MountOption'->new($_) } @$_ ] };

declare 'MapStringMountOption',
    as HashRef[MountOption()];

declare 'RestoreParameters',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::RestoreParameters'];

coerce 'RestoreParameters',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::RestoreParameters'->new($_) };

declare 'RepeatedRestoreParameters',
    as ArrayRef[RestoreParameters()];

coerce 'RepeatedRestoreParameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::RestoreParameters'->new($_) } @$_ ] };

declare 'MapStringRestoreParameters',
    as HashRef[RestoreParameters()];

declare 'BackupConfig',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::BackupConfig'];

coerce 'BackupConfig',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::BackupConfig'->new($_) };

declare 'RepeatedBackupConfig',
    as ArrayRef[BackupConfig()];

coerce 'RepeatedBackupConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::BackupConfig'->new($_) } @$_ ] };

declare 'MapStringBackupConfig',
    as HashRef[BackupConfig()];

declare 'TieringPolicy',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::TieringPolicy'];

coerce 'TieringPolicy',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::TieringPolicy'->new($_) };

declare 'RepeatedTieringPolicy',
    as ArrayRef[TieringPolicy()];

coerce 'RepeatedTieringPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::TieringPolicy'->new($_) } @$_ ] };

declare 'MapStringTieringPolicy',
    as HashRef[TieringPolicy()];

declare 'TierAction',
    as (Int | Str);

declare 'HybridReplicationParameters',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::HybridReplicationParameters'];

coerce 'HybridReplicationParameters',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::HybridReplicationParameters'->new($_) };

declare 'RepeatedHybridReplicationParameters',
    as ArrayRef[HybridReplicationParameters()];

coerce 'RepeatedHybridReplicationParameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::HybridReplicationParameters'->new($_) } @$_ ] };

declare 'MapStringHybridReplicationParameters',
    as HashRef[HybridReplicationParameters()];

declare 'VolumeHybridReplicationType',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::HybridReplicationParameters::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::HybridReplicationParameters::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::HybridReplicationParameters::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'CacheParameters',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::CacheParameters'];

coerce 'CacheParameters',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::CacheParameters'->new($_) };

declare 'RepeatedCacheParameters',
    as ArrayRef[CacheParameters()];

coerce 'RepeatedCacheParameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::CacheParameters'->new($_) } @$_ ] };

declare 'MapStringCacheParameters',
    as HashRef[CacheParameters()];

declare 'CacheState',
    as (Int | Str);

declare 'CacheConfig',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::CacheConfig'];

coerce 'CacheConfig',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::CacheConfig'->new($_) };

declare 'RepeatedCacheConfig',
    as ArrayRef[CacheConfig()];

coerce 'RepeatedCacheConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::CacheConfig'->new($_) } @$_ ] };

declare 'MapStringCacheConfig',
    as HashRef[CacheConfig()];

declare 'CachePrePopulateState',
    as (Int | Str);

declare 'CachePrePopulate',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::CachePrePopulate'];

coerce 'CachePrePopulate',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::CachePrePopulate'->new($_) };

declare 'RepeatedCachePrePopulate',
    as ArrayRef[CachePrePopulate()];

coerce 'RepeatedCachePrePopulate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::CachePrePopulate'->new($_) } @$_ ] };

declare 'MapStringCachePrePopulate',
    as HashRef[CachePrePopulate()];

declare 'BlockDevice',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::BlockDevice'];

coerce 'BlockDevice',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::BlockDevice'->new($_) };

declare 'RepeatedBlockDevice',
    as ArrayRef[BlockDevice()];

coerce 'RepeatedBlockDevice',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::BlockDevice'->new($_) } @$_ ] };

declare 'MapStringBlockDevice',
    as HashRef[BlockDevice()];

declare 'RestoreBackupFilesRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::RestoreBackupFilesRequest'];

coerce 'RestoreBackupFilesRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::RestoreBackupFilesRequest'->new($_) };

declare 'RepeatedRestoreBackupFilesRequest',
    as ArrayRef[RestoreBackupFilesRequest()];

coerce 'RepeatedRestoreBackupFilesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::RestoreBackupFilesRequest'->new($_) } @$_ ] };

declare 'MapStringRestoreBackupFilesRequest',
    as HashRef[RestoreBackupFilesRequest()];

declare 'RestoreBackupFilesResponse',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::RestoreBackupFilesResponse'];

coerce 'RestoreBackupFilesResponse',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::RestoreBackupFilesResponse'->new($_) };

declare 'RepeatedRestoreBackupFilesResponse',
    as ArrayRef[RestoreBackupFilesResponse()];

coerce 'RepeatedRestoreBackupFilesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::RestoreBackupFilesResponse'->new($_) } @$_ ] };

declare 'MapStringRestoreBackupFilesResponse',
    as HashRef[RestoreBackupFilesResponse()];

declare 'RestoreVolumeRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::RestoreVolumeRequest'];

coerce 'RestoreVolumeRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::RestoreVolumeRequest'->new($_) };

declare 'RepeatedRestoreVolumeRequest',
    as ArrayRef[RestoreVolumeRequest()];

coerce 'RepeatedRestoreVolumeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::RestoreVolumeRequest'->new($_) } @$_ ] };

declare 'MapStringRestoreVolumeRequest',
    as HashRef[RestoreVolumeRequest()];

declare 'BackupSource',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::BackupSource'];

coerce 'BackupSource',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::BackupSource'->new($_) };

declare 'RepeatedBackupSource',
    as ArrayRef[BackupSource()];

coerce 'RepeatedBackupSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::BackupSource'->new($_) } @$_ ] };

declare 'MapStringBackupSource',
    as HashRef[BackupSource()];

declare 'OntapVolumeTarget',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::OntapVolumeTarget'];

coerce 'OntapVolumeTarget',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::OntapVolumeTarget'->new($_) };

declare 'RepeatedOntapVolumeTarget',
    as ArrayRef[OntapVolumeTarget()];

coerce 'RepeatedOntapVolumeTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::OntapVolumeTarget'->new($_) } @$_ ] };

declare 'MapStringOntapVolumeTarget',
    as HashRef[OntapVolumeTarget()];

declare 'RestoreVolumeResponse',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::RestoreVolumeResponse'];

coerce 'RestoreVolumeResponse',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::RestoreVolumeResponse'->new($_) };

declare 'RepeatedRestoreVolumeResponse',
    as ArrayRef[RestoreVolumeResponse()];

coerce 'RepeatedRestoreVolumeResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::RestoreVolumeResponse'->new($_) } @$_ ] };

declare 'MapStringRestoreVolumeResponse',
    as HashRef[RestoreVolumeResponse()];

declare 'EstablishVolumePeeringRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::EstablishVolumePeeringRequest'];

coerce 'EstablishVolumePeeringRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::EstablishVolumePeeringRequest'->new($_) };

declare 'RepeatedEstablishVolumePeeringRequest',
    as ArrayRef[EstablishVolumePeeringRequest()];

coerce 'RepeatedEstablishVolumePeeringRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::EstablishVolumePeeringRequest'->new($_) } @$_ ] };

declare 'MapStringEstablishVolumePeeringRequest',
    as HashRef[EstablishVolumePeeringRequest()];

declare 'UpdateBackupConfigRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::UpdateBackupConfigRequest'];

coerce 'UpdateBackupConfigRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::UpdateBackupConfigRequest'->new($_) };

declare 'RepeatedUpdateBackupConfigRequest',
    as ArrayRef[UpdateBackupConfigRequest()];

coerce 'RepeatedUpdateBackupConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::UpdateBackupConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBackupConfigRequest',
    as HashRef[UpdateBackupConfigRequest()];

declare 'UpdateBackupConfigResponse',
    as InstanceOf['Google::Cloud::Netapp::V1::Volume::UpdateBackupConfigResponse'];

coerce 'UpdateBackupConfigResponse',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Volume::UpdateBackupConfigResponse'->new($_) };

declare 'RepeatedUpdateBackupConfigResponse',
    as ArrayRef[UpdateBackupConfigResponse()];

coerce 'RepeatedUpdateBackupConfigResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Volume::UpdateBackupConfigResponse'->new($_) } @$_ ] };

declare 'MapStringUpdateBackupConfigResponse',
    as HashRef[UpdateBackupConfigResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Netapp::V1::Volume::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
