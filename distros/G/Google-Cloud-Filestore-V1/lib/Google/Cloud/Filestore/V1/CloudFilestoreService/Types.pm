package Google::Cloud::Filestore::V1::CloudFilestoreService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'NetworkConfig',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::NetworkConfig'];

coerce 'NetworkConfig',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::NetworkConfig'->new($_) };

declare 'RepeatedNetworkConfig',
    as ArrayRef[NetworkConfig()];

coerce 'RepeatedNetworkConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::NetworkConfig'->new($_) } @$_ ] };

declare 'MapStringNetworkConfig',
    as HashRef[NetworkConfig()];

declare 'AddressMode',
    as (Int | Str);

declare 'ConnectMode',
    as (Int | Str);

declare 'FileShareConfig',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::FileShareConfig'];

coerce 'FileShareConfig',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::FileShareConfig'->new($_) };

declare 'RepeatedFileShareConfig',
    as ArrayRef[FileShareConfig()];

coerce 'RepeatedFileShareConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::FileShareConfig'->new($_) } @$_ ] };

declare 'MapStringFileShareConfig',
    as HashRef[FileShareConfig()];

declare 'NfsExportOptions',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::NfsExportOptions'];

coerce 'NfsExportOptions',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::NfsExportOptions'->new($_) };

declare 'RepeatedNfsExportOptions',
    as ArrayRef[NfsExportOptions()];

coerce 'RepeatedNfsExportOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::NfsExportOptions'->new($_) } @$_ ] };

declare 'MapStringNfsExportOptions',
    as HashRef[NfsExportOptions()];

declare 'AccessMode',
    as (Int | Str);

declare 'SquashMode',
    as (Int | Str);

declare 'ReplicaConfig',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::ReplicaConfig'];

coerce 'ReplicaConfig',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::ReplicaConfig'->new($_) };

declare 'RepeatedReplicaConfig',
    as ArrayRef[ReplicaConfig()];

coerce 'RepeatedReplicaConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::ReplicaConfig'->new($_) } @$_ ] };

declare 'MapStringReplicaConfig',
    as HashRef[ReplicaConfig()];

declare 'State',
    as (Int | Str);

declare 'StateReason',
    as (Int | Str);

declare 'Replication',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::Replication'];

coerce 'Replication',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::Replication'->new($_) };

declare 'RepeatedReplication',
    as ArrayRef[Replication()];

coerce 'RepeatedReplication',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::Replication'->new($_) } @$_ ] };

declare 'MapStringReplication',
    as HashRef[Replication()];

declare 'Role',
    as (Int | Str);

declare 'Instance',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::Instance'];

coerce 'Instance',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::Instance'->new($_) };

declare 'RepeatedInstance',
    as ArrayRef[Instance()];

coerce 'RepeatedInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::Instance'->new($_) } @$_ ] };

declare 'MapStringInstance',
    as HashRef[Instance()];

declare 'State',
    as (Int | Str);

declare 'Tier',
    as (Int | Str);

declare 'SuspensionReason',
    as (Int | Str);

declare 'FileProtocol',
    as (Int | Str);

declare 'IOPSPerTB',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::Instance::IOPSPerTB'];

coerce 'IOPSPerTB',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::Instance::IOPSPerTB'->new($_) };

declare 'RepeatedIOPSPerTB',
    as ArrayRef[IOPSPerTB()];

coerce 'RepeatedIOPSPerTB',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::Instance::IOPSPerTB'->new($_) } @$_ ] };

declare 'MapStringIOPSPerTB',
    as HashRef[IOPSPerTB()];

declare 'FixedIOPS',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::Instance::FixedIOPS'];

coerce 'FixedIOPS',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::Instance::FixedIOPS'->new($_) };

declare 'RepeatedFixedIOPS',
    as ArrayRef[FixedIOPS()];

coerce 'RepeatedFixedIOPS',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::Instance::FixedIOPS'->new($_) } @$_ ] };

declare 'MapStringFixedIOPS',
    as HashRef[FixedIOPS()];

declare 'PerformanceConfig',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::Instance::PerformanceConfig'];

coerce 'PerformanceConfig',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::Instance::PerformanceConfig'->new($_) };

declare 'RepeatedPerformanceConfig',
    as ArrayRef[PerformanceConfig()];

coerce 'RepeatedPerformanceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::Instance::PerformanceConfig'->new($_) } @$_ ] };

declare 'MapStringPerformanceConfig',
    as HashRef[PerformanceConfig()];

declare 'PerformanceLimits',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::Instance::PerformanceLimits'];

coerce 'PerformanceLimits',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::Instance::PerformanceLimits'->new($_) };

declare 'RepeatedPerformanceLimits',
    as ArrayRef[PerformanceLimits()];

coerce 'RepeatedPerformanceLimits',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::Instance::PerformanceLimits'->new($_) } @$_ ] };

declare 'MapStringPerformanceLimits',
    as HashRef[PerformanceLimits()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::Instance::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::Instance::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::Instance::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'TagsEntry',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::Instance::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::Instance::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::Instance::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

declare 'CreateInstanceRequest',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::CreateInstanceRequest'];

coerce 'CreateInstanceRequest',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::CreateInstanceRequest'->new($_) };

declare 'RepeatedCreateInstanceRequest',
    as ArrayRef[CreateInstanceRequest()];

coerce 'RepeatedCreateInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::CreateInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateInstanceRequest',
    as HashRef[CreateInstanceRequest()];

declare 'GetInstanceRequest',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::GetInstanceRequest'];

coerce 'GetInstanceRequest',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::GetInstanceRequest'->new($_) };

declare 'RepeatedGetInstanceRequest',
    as ArrayRef[GetInstanceRequest()];

coerce 'RepeatedGetInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::GetInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringGetInstanceRequest',
    as HashRef[GetInstanceRequest()];

declare 'UpdateInstanceRequest',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::UpdateInstanceRequest'];

coerce 'UpdateInstanceRequest',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::UpdateInstanceRequest'->new($_) };

declare 'RepeatedUpdateInstanceRequest',
    as ArrayRef[UpdateInstanceRequest()];

coerce 'RepeatedUpdateInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::UpdateInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateInstanceRequest',
    as HashRef[UpdateInstanceRequest()];

declare 'RestoreInstanceRequest',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::RestoreInstanceRequest'];

coerce 'RestoreInstanceRequest',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::RestoreInstanceRequest'->new($_) };

declare 'RepeatedRestoreInstanceRequest',
    as ArrayRef[RestoreInstanceRequest()];

coerce 'RepeatedRestoreInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::RestoreInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringRestoreInstanceRequest',
    as HashRef[RestoreInstanceRequest()];

declare 'RevertInstanceRequest',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::RevertInstanceRequest'];

coerce 'RevertInstanceRequest',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::RevertInstanceRequest'->new($_) };

declare 'RepeatedRevertInstanceRequest',
    as ArrayRef[RevertInstanceRequest()];

coerce 'RepeatedRevertInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::RevertInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringRevertInstanceRequest',
    as HashRef[RevertInstanceRequest()];

declare 'DeleteInstanceRequest',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::DeleteInstanceRequest'];

coerce 'DeleteInstanceRequest',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::DeleteInstanceRequest'->new($_) };

declare 'RepeatedDeleteInstanceRequest',
    as ArrayRef[DeleteInstanceRequest()];

coerce 'RepeatedDeleteInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::DeleteInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteInstanceRequest',
    as HashRef[DeleteInstanceRequest()];

declare 'ListInstancesRequest',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::ListInstancesRequest'];

coerce 'ListInstancesRequest',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::ListInstancesRequest'->new($_) };

declare 'RepeatedListInstancesRequest',
    as ArrayRef[ListInstancesRequest()];

coerce 'RepeatedListInstancesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::ListInstancesRequest'->new($_) } @$_ ] };

declare 'MapStringListInstancesRequest',
    as HashRef[ListInstancesRequest()];

declare 'ListInstancesResponse',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::ListInstancesResponse'];

coerce 'ListInstancesResponse',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::ListInstancesResponse'->new($_) };

declare 'RepeatedListInstancesResponse',
    as ArrayRef[ListInstancesResponse()];

coerce 'RepeatedListInstancesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::ListInstancesResponse'->new($_) } @$_ ] };

declare 'MapStringListInstancesResponse',
    as HashRef[ListInstancesResponse()];

declare 'Snapshot',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::Snapshot'];

coerce 'Snapshot',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::Snapshot'->new($_) };

declare 'RepeatedSnapshot',
    as ArrayRef[Snapshot()];

coerce 'RepeatedSnapshot',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::Snapshot'->new($_) } @$_ ] };

declare 'MapStringSnapshot',
    as HashRef[Snapshot()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::Snapshot::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::Snapshot::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::Snapshot::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'TagsEntry',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::Snapshot::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::Snapshot::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::Snapshot::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

declare 'CreateSnapshotRequest',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::CreateSnapshotRequest'];

coerce 'CreateSnapshotRequest',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::CreateSnapshotRequest'->new($_) };

declare 'RepeatedCreateSnapshotRequest',
    as ArrayRef[CreateSnapshotRequest()];

coerce 'RepeatedCreateSnapshotRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::CreateSnapshotRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSnapshotRequest',
    as HashRef[CreateSnapshotRequest()];

declare 'GetSnapshotRequest',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::GetSnapshotRequest'];

coerce 'GetSnapshotRequest',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::GetSnapshotRequest'->new($_) };

declare 'RepeatedGetSnapshotRequest',
    as ArrayRef[GetSnapshotRequest()];

coerce 'RepeatedGetSnapshotRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::GetSnapshotRequest'->new($_) } @$_ ] };

declare 'MapStringGetSnapshotRequest',
    as HashRef[GetSnapshotRequest()];

declare 'DeleteSnapshotRequest',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::DeleteSnapshotRequest'];

coerce 'DeleteSnapshotRequest',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::DeleteSnapshotRequest'->new($_) };

declare 'RepeatedDeleteSnapshotRequest',
    as ArrayRef[DeleteSnapshotRequest()];

coerce 'RepeatedDeleteSnapshotRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::DeleteSnapshotRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSnapshotRequest',
    as HashRef[DeleteSnapshotRequest()];

declare 'UpdateSnapshotRequest',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::UpdateSnapshotRequest'];

coerce 'UpdateSnapshotRequest',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::UpdateSnapshotRequest'->new($_) };

declare 'RepeatedUpdateSnapshotRequest',
    as ArrayRef[UpdateSnapshotRequest()];

coerce 'RepeatedUpdateSnapshotRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::UpdateSnapshotRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSnapshotRequest',
    as HashRef[UpdateSnapshotRequest()];

declare 'ListSnapshotsRequest',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::ListSnapshotsRequest'];

coerce 'ListSnapshotsRequest',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::ListSnapshotsRequest'->new($_) };

declare 'RepeatedListSnapshotsRequest',
    as ArrayRef[ListSnapshotsRequest()];

coerce 'RepeatedListSnapshotsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::ListSnapshotsRequest'->new($_) } @$_ ] };

declare 'MapStringListSnapshotsRequest',
    as HashRef[ListSnapshotsRequest()];

declare 'ListSnapshotsResponse',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::ListSnapshotsResponse'];

coerce 'ListSnapshotsResponse',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::ListSnapshotsResponse'->new($_) };

declare 'RepeatedListSnapshotsResponse',
    as ArrayRef[ListSnapshotsResponse()];

coerce 'RepeatedListSnapshotsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::ListSnapshotsResponse'->new($_) } @$_ ] };

declare 'MapStringListSnapshotsResponse',
    as HashRef[ListSnapshotsResponse()];

declare 'Backup',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::Backup'];

coerce 'Backup',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::Backup'->new($_) };

declare 'RepeatedBackup',
    as ArrayRef[Backup()];

coerce 'RepeatedBackup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::Backup'->new($_) } @$_ ] };

declare 'MapStringBackup',
    as HashRef[Backup()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::Backup::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::Backup::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::Backup::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'TagsEntry',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::Backup::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::Backup::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::Backup::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

declare 'CreateBackupRequest',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::CreateBackupRequest'];

coerce 'CreateBackupRequest',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::CreateBackupRequest'->new($_) };

declare 'RepeatedCreateBackupRequest',
    as ArrayRef[CreateBackupRequest()];

coerce 'RepeatedCreateBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::CreateBackupRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBackupRequest',
    as HashRef[CreateBackupRequest()];

declare 'DeleteBackupRequest',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::DeleteBackupRequest'];

coerce 'DeleteBackupRequest',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::DeleteBackupRequest'->new($_) };

declare 'RepeatedDeleteBackupRequest',
    as ArrayRef[DeleteBackupRequest()];

coerce 'RepeatedDeleteBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::DeleteBackupRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBackupRequest',
    as HashRef[DeleteBackupRequest()];

declare 'UpdateBackupRequest',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::UpdateBackupRequest'];

coerce 'UpdateBackupRequest',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::UpdateBackupRequest'->new($_) };

declare 'RepeatedUpdateBackupRequest',
    as ArrayRef[UpdateBackupRequest()];

coerce 'RepeatedUpdateBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::UpdateBackupRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBackupRequest',
    as HashRef[UpdateBackupRequest()];

declare 'PromoteReplicaRequest',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::PromoteReplicaRequest'];

coerce 'PromoteReplicaRequest',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::PromoteReplicaRequest'->new($_) };

declare 'RepeatedPromoteReplicaRequest',
    as ArrayRef[PromoteReplicaRequest()];

coerce 'RepeatedPromoteReplicaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::PromoteReplicaRequest'->new($_) } @$_ ] };

declare 'MapStringPromoteReplicaRequest',
    as HashRef[PromoteReplicaRequest()];

declare 'GetBackupRequest',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::GetBackupRequest'];

coerce 'GetBackupRequest',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::GetBackupRequest'->new($_) };

declare 'RepeatedGetBackupRequest',
    as ArrayRef[GetBackupRequest()];

coerce 'RepeatedGetBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::GetBackupRequest'->new($_) } @$_ ] };

declare 'MapStringGetBackupRequest',
    as HashRef[GetBackupRequest()];

declare 'ListBackupsRequest',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::ListBackupsRequest'];

coerce 'ListBackupsRequest',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::ListBackupsRequest'->new($_) };

declare 'RepeatedListBackupsRequest',
    as ArrayRef[ListBackupsRequest()];

coerce 'RepeatedListBackupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::ListBackupsRequest'->new($_) } @$_ ] };

declare 'MapStringListBackupsRequest',
    as HashRef[ListBackupsRequest()];

declare 'ListBackupsResponse',
    as InstanceOf['Google::Cloud::Filestore::V1::CloudFilestoreService::ListBackupsResponse'];

coerce 'ListBackupsResponse',
    from HashRef, via { 'Google::Cloud::Filestore::V1::CloudFilestoreService::ListBackupsResponse'->new($_) };

declare 'RepeatedListBackupsResponse',
    as ArrayRef[ListBackupsResponse()];

coerce 'RepeatedListBackupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Filestore::V1::CloudFilestoreService::ListBackupsResponse'->new($_) } @$_ ] };

declare 'MapStringListBackupsResponse',
    as HashRef[ListBackupsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Filestore::V1::CloudFilestoreService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
