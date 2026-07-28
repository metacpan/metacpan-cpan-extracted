package Google::Cloud::Sql::V1::CloudSqlInstances::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ExternalSyncParallelLevel',
    as (Int | Str);

declare 'SqlInstanceType',
    as (Int | Str);

declare 'SqlSuspensionReason',
    as (Int | Str);

declare 'SqlInstancesAddServerCaRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesAddServerCaRequest'];

coerce 'SqlInstancesAddServerCaRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesAddServerCaRequest'->new($_) };

declare 'RepeatedSqlInstancesAddServerCaRequest',
    as ArrayRef[SqlInstancesAddServerCaRequest()];

coerce 'RepeatedSqlInstancesAddServerCaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesAddServerCaRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesAddServerCaRequest',
    as HashRef[SqlInstancesAddServerCaRequest()];

declare 'SqlInstancesAddServerCertificateRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesAddServerCertificateRequest'];

coerce 'SqlInstancesAddServerCertificateRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesAddServerCertificateRequest'->new($_) };

declare 'RepeatedSqlInstancesAddServerCertificateRequest',
    as ArrayRef[SqlInstancesAddServerCertificateRequest()];

coerce 'RepeatedSqlInstancesAddServerCertificateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesAddServerCertificateRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesAddServerCertificateRequest',
    as HashRef[SqlInstancesAddServerCertificateRequest()];

declare 'SqlInstancesAddEntraIdCertificateRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesAddEntraIdCertificateRequest'];

coerce 'SqlInstancesAddEntraIdCertificateRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesAddEntraIdCertificateRequest'->new($_) };

declare 'RepeatedSqlInstancesAddEntraIdCertificateRequest',
    as ArrayRef[SqlInstancesAddEntraIdCertificateRequest()];

coerce 'RepeatedSqlInstancesAddEntraIdCertificateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesAddEntraIdCertificateRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesAddEntraIdCertificateRequest',
    as HashRef[SqlInstancesAddEntraIdCertificateRequest()];

declare 'SqlInstancesCloneRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesCloneRequest'];

coerce 'SqlInstancesCloneRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesCloneRequest'->new($_) };

declare 'RepeatedSqlInstancesCloneRequest',
    as ArrayRef[SqlInstancesCloneRequest()];

coerce 'RepeatedSqlInstancesCloneRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesCloneRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesCloneRequest',
    as HashRef[SqlInstancesCloneRequest()];

declare 'SqlInstancesDeleteRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesDeleteRequest'];

coerce 'SqlInstancesDeleteRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesDeleteRequest'->new($_) };

declare 'RepeatedSqlInstancesDeleteRequest',
    as ArrayRef[SqlInstancesDeleteRequest()];

coerce 'RepeatedSqlInstancesDeleteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesDeleteRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesDeleteRequest',
    as HashRef[SqlInstancesDeleteRequest()];

declare 'SqlInstancesDemoteMasterRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesDemoteMasterRequest'];

coerce 'SqlInstancesDemoteMasterRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesDemoteMasterRequest'->new($_) };

declare 'RepeatedSqlInstancesDemoteMasterRequest',
    as ArrayRef[SqlInstancesDemoteMasterRequest()];

coerce 'RepeatedSqlInstancesDemoteMasterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesDemoteMasterRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesDemoteMasterRequest',
    as HashRef[SqlInstancesDemoteMasterRequest()];

declare 'SqlInstancesDemoteRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesDemoteRequest'];

coerce 'SqlInstancesDemoteRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesDemoteRequest'->new($_) };

declare 'RepeatedSqlInstancesDemoteRequest',
    as ArrayRef[SqlInstancesDemoteRequest()];

coerce 'RepeatedSqlInstancesDemoteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesDemoteRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesDemoteRequest',
    as HashRef[SqlInstancesDemoteRequest()];

declare 'SqlInstancesExportRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesExportRequest'];

coerce 'SqlInstancesExportRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesExportRequest'->new($_) };

declare 'RepeatedSqlInstancesExportRequest',
    as ArrayRef[SqlInstancesExportRequest()];

coerce 'RepeatedSqlInstancesExportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesExportRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesExportRequest',
    as HashRef[SqlInstancesExportRequest()];

declare 'SqlInstancesFailoverRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesFailoverRequest'];

coerce 'SqlInstancesFailoverRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesFailoverRequest'->new($_) };

declare 'RepeatedSqlInstancesFailoverRequest',
    as ArrayRef[SqlInstancesFailoverRequest()];

coerce 'RepeatedSqlInstancesFailoverRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesFailoverRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesFailoverRequest',
    as HashRef[SqlInstancesFailoverRequest()];

declare 'SqlInstancesGetRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesGetRequest'];

coerce 'SqlInstancesGetRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesGetRequest'->new($_) };

declare 'RepeatedSqlInstancesGetRequest',
    as ArrayRef[SqlInstancesGetRequest()];

coerce 'RepeatedSqlInstancesGetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesGetRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesGetRequest',
    as HashRef[SqlInstancesGetRequest()];

declare 'SqlInstancesImportRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesImportRequest'];

coerce 'SqlInstancesImportRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesImportRequest'->new($_) };

declare 'RepeatedSqlInstancesImportRequest',
    as ArrayRef[SqlInstancesImportRequest()];

coerce 'RepeatedSqlInstancesImportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesImportRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesImportRequest',
    as HashRef[SqlInstancesImportRequest()];

declare 'SqlInstancesInsertRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesInsertRequest'];

coerce 'SqlInstancesInsertRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesInsertRequest'->new($_) };

declare 'RepeatedSqlInstancesInsertRequest',
    as ArrayRef[SqlInstancesInsertRequest()];

coerce 'RepeatedSqlInstancesInsertRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesInsertRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesInsertRequest',
    as HashRef[SqlInstancesInsertRequest()];

declare 'SqlInstancesListRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesListRequest'];

coerce 'SqlInstancesListRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesListRequest'->new($_) };

declare 'RepeatedSqlInstancesListRequest',
    as ArrayRef[SqlInstancesListRequest()];

coerce 'RepeatedSqlInstancesListRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesListRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesListRequest',
    as HashRef[SqlInstancesListRequest()];

declare 'SqlInstancesListServerCasRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesListServerCasRequest'];

coerce 'SqlInstancesListServerCasRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesListServerCasRequest'->new($_) };

declare 'RepeatedSqlInstancesListServerCasRequest',
    as ArrayRef[SqlInstancesListServerCasRequest()];

coerce 'RepeatedSqlInstancesListServerCasRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesListServerCasRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesListServerCasRequest',
    as HashRef[SqlInstancesListServerCasRequest()];

declare 'SqlInstancesListServerCertificatesRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesListServerCertificatesRequest'];

coerce 'SqlInstancesListServerCertificatesRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesListServerCertificatesRequest'->new($_) };

declare 'RepeatedSqlInstancesListServerCertificatesRequest',
    as ArrayRef[SqlInstancesListServerCertificatesRequest()];

coerce 'RepeatedSqlInstancesListServerCertificatesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesListServerCertificatesRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesListServerCertificatesRequest',
    as HashRef[SqlInstancesListServerCertificatesRequest()];

declare 'SqlInstancesListEntraIdCertificatesRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesListEntraIdCertificatesRequest'];

coerce 'SqlInstancesListEntraIdCertificatesRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesListEntraIdCertificatesRequest'->new($_) };

declare 'RepeatedSqlInstancesListEntraIdCertificatesRequest',
    as ArrayRef[SqlInstancesListEntraIdCertificatesRequest()];

coerce 'RepeatedSqlInstancesListEntraIdCertificatesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesListEntraIdCertificatesRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesListEntraIdCertificatesRequest',
    as HashRef[SqlInstancesListEntraIdCertificatesRequest()];

declare 'SqlInstancesPatchRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesPatchRequest'];

coerce 'SqlInstancesPatchRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesPatchRequest'->new($_) };

declare 'RepeatedSqlInstancesPatchRequest',
    as ArrayRef[SqlInstancesPatchRequest()];

coerce 'RepeatedSqlInstancesPatchRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesPatchRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesPatchRequest',
    as HashRef[SqlInstancesPatchRequest()];

declare 'SqlInstancesPromoteReplicaRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesPromoteReplicaRequest'];

coerce 'SqlInstancesPromoteReplicaRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesPromoteReplicaRequest'->new($_) };

declare 'RepeatedSqlInstancesPromoteReplicaRequest',
    as ArrayRef[SqlInstancesPromoteReplicaRequest()];

coerce 'RepeatedSqlInstancesPromoteReplicaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesPromoteReplicaRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesPromoteReplicaRequest',
    as HashRef[SqlInstancesPromoteReplicaRequest()];

declare 'SqlInstancesSwitchoverRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesSwitchoverRequest'];

coerce 'SqlInstancesSwitchoverRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesSwitchoverRequest'->new($_) };

declare 'RepeatedSqlInstancesSwitchoverRequest',
    as ArrayRef[SqlInstancesSwitchoverRequest()];

coerce 'RepeatedSqlInstancesSwitchoverRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesSwitchoverRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesSwitchoverRequest',
    as HashRef[SqlInstancesSwitchoverRequest()];

declare 'SqlInstancesResetSslConfigRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesResetSslConfigRequest'];

coerce 'SqlInstancesResetSslConfigRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesResetSslConfigRequest'->new($_) };

declare 'RepeatedSqlInstancesResetSslConfigRequest',
    as ArrayRef[SqlInstancesResetSslConfigRequest()];

coerce 'RepeatedSqlInstancesResetSslConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesResetSslConfigRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesResetSslConfigRequest',
    as HashRef[SqlInstancesResetSslConfigRequest()];

declare 'ResetSslMode',
    as (Int | Str);

declare 'SqlInstancesRestartRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesRestartRequest'];

coerce 'SqlInstancesRestartRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesRestartRequest'->new($_) };

declare 'RepeatedSqlInstancesRestartRequest',
    as ArrayRef[SqlInstancesRestartRequest()];

coerce 'RepeatedSqlInstancesRestartRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesRestartRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesRestartRequest',
    as HashRef[SqlInstancesRestartRequest()];

declare 'SqlInstancesRestoreBackupRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesRestoreBackupRequest'];

coerce 'SqlInstancesRestoreBackupRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesRestoreBackupRequest'->new($_) };

declare 'RepeatedSqlInstancesRestoreBackupRequest',
    as ArrayRef[SqlInstancesRestoreBackupRequest()];

coerce 'RepeatedSqlInstancesRestoreBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesRestoreBackupRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesRestoreBackupRequest',
    as HashRef[SqlInstancesRestoreBackupRequest()];

declare 'SqlInstancesRotateServerCaRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesRotateServerCaRequest'];

coerce 'SqlInstancesRotateServerCaRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesRotateServerCaRequest'->new($_) };

declare 'RepeatedSqlInstancesRotateServerCaRequest',
    as ArrayRef[SqlInstancesRotateServerCaRequest()];

coerce 'RepeatedSqlInstancesRotateServerCaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesRotateServerCaRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesRotateServerCaRequest',
    as HashRef[SqlInstancesRotateServerCaRequest()];

declare 'SqlInstancesRotateServerCertificateRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesRotateServerCertificateRequest'];

coerce 'SqlInstancesRotateServerCertificateRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesRotateServerCertificateRequest'->new($_) };

declare 'RepeatedSqlInstancesRotateServerCertificateRequest',
    as ArrayRef[SqlInstancesRotateServerCertificateRequest()];

coerce 'RepeatedSqlInstancesRotateServerCertificateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesRotateServerCertificateRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesRotateServerCertificateRequest',
    as HashRef[SqlInstancesRotateServerCertificateRequest()];

declare 'SqlInstancesRotateEntraIdCertificateRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesRotateEntraIdCertificateRequest'];

coerce 'SqlInstancesRotateEntraIdCertificateRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesRotateEntraIdCertificateRequest'->new($_) };

declare 'RepeatedSqlInstancesRotateEntraIdCertificateRequest',
    as ArrayRef[SqlInstancesRotateEntraIdCertificateRequest()];

coerce 'RepeatedSqlInstancesRotateEntraIdCertificateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesRotateEntraIdCertificateRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesRotateEntraIdCertificateRequest',
    as HashRef[SqlInstancesRotateEntraIdCertificateRequest()];

declare 'SqlInstancesStartReplicaRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesStartReplicaRequest'];

coerce 'SqlInstancesStartReplicaRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesStartReplicaRequest'->new($_) };

declare 'RepeatedSqlInstancesStartReplicaRequest',
    as ArrayRef[SqlInstancesStartReplicaRequest()];

coerce 'RepeatedSqlInstancesStartReplicaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesStartReplicaRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesStartReplicaRequest',
    as HashRef[SqlInstancesStartReplicaRequest()];

declare 'SqlInstancesStopReplicaRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesStopReplicaRequest'];

coerce 'SqlInstancesStopReplicaRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesStopReplicaRequest'->new($_) };

declare 'RepeatedSqlInstancesStopReplicaRequest',
    as ArrayRef[SqlInstancesStopReplicaRequest()];

coerce 'RepeatedSqlInstancesStopReplicaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesStopReplicaRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesStopReplicaRequest',
    as HashRef[SqlInstancesStopReplicaRequest()];

declare 'SqlInstancesTruncateLogRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesTruncateLogRequest'];

coerce 'SqlInstancesTruncateLogRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesTruncateLogRequest'->new($_) };

declare 'RepeatedSqlInstancesTruncateLogRequest',
    as ArrayRef[SqlInstancesTruncateLogRequest()];

coerce 'RepeatedSqlInstancesTruncateLogRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesTruncateLogRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesTruncateLogRequest',
    as HashRef[SqlInstancesTruncateLogRequest()];

declare 'SqlInstancesPerformDiskShrinkRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesPerformDiskShrinkRequest'];

coerce 'SqlInstancesPerformDiskShrinkRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesPerformDiskShrinkRequest'->new($_) };

declare 'RepeatedSqlInstancesPerformDiskShrinkRequest',
    as ArrayRef[SqlInstancesPerformDiskShrinkRequest()];

coerce 'RepeatedSqlInstancesPerformDiskShrinkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesPerformDiskShrinkRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesPerformDiskShrinkRequest',
    as HashRef[SqlInstancesPerformDiskShrinkRequest()];

declare 'SqlInstancesUpdateRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesUpdateRequest'];

coerce 'SqlInstancesUpdateRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesUpdateRequest'->new($_) };

declare 'RepeatedSqlInstancesUpdateRequest',
    as ArrayRef[SqlInstancesUpdateRequest()];

coerce 'RepeatedSqlInstancesUpdateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesUpdateRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesUpdateRequest',
    as HashRef[SqlInstancesUpdateRequest()];

declare 'SqlInstancesRescheduleMaintenanceRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesRescheduleMaintenanceRequest'];

coerce 'SqlInstancesRescheduleMaintenanceRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesRescheduleMaintenanceRequest'->new($_) };

declare 'RepeatedSqlInstancesRescheduleMaintenanceRequest',
    as ArrayRef[SqlInstancesRescheduleMaintenanceRequest()];

coerce 'RepeatedSqlInstancesRescheduleMaintenanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesRescheduleMaintenanceRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesRescheduleMaintenanceRequest',
    as HashRef[SqlInstancesRescheduleMaintenanceRequest()];

declare 'SqlInstancesReencryptRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesReencryptRequest'];

coerce 'SqlInstancesReencryptRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesReencryptRequest'->new($_) };

declare 'RepeatedSqlInstancesReencryptRequest',
    as ArrayRef[SqlInstancesReencryptRequest()];

coerce 'RepeatedSqlInstancesReencryptRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesReencryptRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesReencryptRequest',
    as HashRef[SqlInstancesReencryptRequest()];

declare 'InstancesReencryptRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::InstancesReencryptRequest'];

coerce 'InstancesReencryptRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesReencryptRequest'->new($_) };

declare 'RepeatedInstancesReencryptRequest',
    as ArrayRef[InstancesReencryptRequest()];

coerce 'RepeatedInstancesReencryptRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesReencryptRequest'->new($_) } @$_ ] };

declare 'MapStringInstancesReencryptRequest',
    as HashRef[InstancesReencryptRequest()];

declare 'BackupReencryptionConfig',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::BackupReencryptionConfig'];

coerce 'BackupReencryptionConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::BackupReencryptionConfig'->new($_) };

declare 'RepeatedBackupReencryptionConfig',
    as ArrayRef[BackupReencryptionConfig()];

coerce 'RepeatedBackupReencryptionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::BackupReencryptionConfig'->new($_) } @$_ ] };

declare 'MapStringBackupReencryptionConfig',
    as HashRef[BackupReencryptionConfig()];

declare 'BackupType',
    as (Int | Str);

declare 'ExternalSyncSelectedObject',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::ExternalSyncSelectedObject'];

coerce 'ExternalSyncSelectedObject',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::ExternalSyncSelectedObject'->new($_) };

declare 'RepeatedExternalSyncSelectedObject',
    as ArrayRef[ExternalSyncSelectedObject()];

coerce 'RepeatedExternalSyncSelectedObject',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::ExternalSyncSelectedObject'->new($_) } @$_ ] };

declare 'MapStringExternalSyncSelectedObject',
    as HashRef[ExternalSyncSelectedObject()];

declare 'SqlInstancesGetDiskShrinkConfigRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesGetDiskShrinkConfigRequest'];

coerce 'SqlInstancesGetDiskShrinkConfigRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesGetDiskShrinkConfigRequest'->new($_) };

declare 'RepeatedSqlInstancesGetDiskShrinkConfigRequest',
    as ArrayRef[SqlInstancesGetDiskShrinkConfigRequest()];

coerce 'RepeatedSqlInstancesGetDiskShrinkConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesGetDiskShrinkConfigRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesGetDiskShrinkConfigRequest',
    as HashRef[SqlInstancesGetDiskShrinkConfigRequest()];

declare 'SqlInstancesVerifyExternalSyncSettingsRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesVerifyExternalSyncSettingsRequest'];

coerce 'SqlInstancesVerifyExternalSyncSettingsRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesVerifyExternalSyncSettingsRequest'->new($_) };

declare 'RepeatedSqlInstancesVerifyExternalSyncSettingsRequest',
    as ArrayRef[SqlInstancesVerifyExternalSyncSettingsRequest()];

coerce 'RepeatedSqlInstancesVerifyExternalSyncSettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesVerifyExternalSyncSettingsRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesVerifyExternalSyncSettingsRequest',
    as HashRef[SqlInstancesVerifyExternalSyncSettingsRequest()];

declare 'ExternalSyncMode',
    as (Int | Str);

declare 'MigrationType',
    as (Int | Str);

declare 'SqlInstancesStartExternalSyncRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesStartExternalSyncRequest'];

coerce 'SqlInstancesStartExternalSyncRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesStartExternalSyncRequest'->new($_) };

declare 'RepeatedSqlInstancesStartExternalSyncRequest',
    as ArrayRef[SqlInstancesStartExternalSyncRequest()];

coerce 'RepeatedSqlInstancesStartExternalSyncRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesStartExternalSyncRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesStartExternalSyncRequest',
    as HashRef[SqlInstancesStartExternalSyncRequest()];

declare 'SqlInstancesResetReplicaSizeRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesResetReplicaSizeRequest'];

coerce 'SqlInstancesResetReplicaSizeRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesResetReplicaSizeRequest'->new($_) };

declare 'RepeatedSqlInstancesResetReplicaSizeRequest',
    as ArrayRef[SqlInstancesResetReplicaSizeRequest()];

coerce 'RepeatedSqlInstancesResetReplicaSizeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesResetReplicaSizeRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesResetReplicaSizeRequest',
    as HashRef[SqlInstancesResetReplicaSizeRequest()];

declare 'SqlInstancesCreateEphemeralCertRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesCreateEphemeralCertRequest'];

coerce 'SqlInstancesCreateEphemeralCertRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesCreateEphemeralCertRequest'->new($_) };

declare 'RepeatedSqlInstancesCreateEphemeralCertRequest',
    as ArrayRef[SqlInstancesCreateEphemeralCertRequest()];

coerce 'RepeatedSqlInstancesCreateEphemeralCertRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesCreateEphemeralCertRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesCreateEphemeralCertRequest',
    as HashRef[SqlInstancesCreateEphemeralCertRequest()];

declare 'InstancesCloneRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::InstancesCloneRequest'];

coerce 'InstancesCloneRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesCloneRequest'->new($_) };

declare 'RepeatedInstancesCloneRequest',
    as ArrayRef[InstancesCloneRequest()];

coerce 'RepeatedInstancesCloneRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesCloneRequest'->new($_) } @$_ ] };

declare 'MapStringInstancesCloneRequest',
    as HashRef[InstancesCloneRequest()];

declare 'InstancesDemoteMasterRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::InstancesDemoteMasterRequest'];

coerce 'InstancesDemoteMasterRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesDemoteMasterRequest'->new($_) };

declare 'RepeatedInstancesDemoteMasterRequest',
    as ArrayRef[InstancesDemoteMasterRequest()];

coerce 'RepeatedInstancesDemoteMasterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesDemoteMasterRequest'->new($_) } @$_ ] };

declare 'MapStringInstancesDemoteMasterRequest',
    as HashRef[InstancesDemoteMasterRequest()];

declare 'InstancesDemoteRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::InstancesDemoteRequest'];

coerce 'InstancesDemoteRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesDemoteRequest'->new($_) };

declare 'RepeatedInstancesDemoteRequest',
    as ArrayRef[InstancesDemoteRequest()];

coerce 'RepeatedInstancesDemoteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesDemoteRequest'->new($_) } @$_ ] };

declare 'MapStringInstancesDemoteRequest',
    as HashRef[InstancesDemoteRequest()];

declare 'InstancesExportRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::InstancesExportRequest'];

coerce 'InstancesExportRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesExportRequest'->new($_) };

declare 'RepeatedInstancesExportRequest',
    as ArrayRef[InstancesExportRequest()];

coerce 'RepeatedInstancesExportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesExportRequest'->new($_) } @$_ ] };

declare 'MapStringInstancesExportRequest',
    as HashRef[InstancesExportRequest()];

declare 'InstancesFailoverRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::InstancesFailoverRequest'];

coerce 'InstancesFailoverRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesFailoverRequest'->new($_) };

declare 'RepeatedInstancesFailoverRequest',
    as ArrayRef[InstancesFailoverRequest()];

coerce 'RepeatedInstancesFailoverRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesFailoverRequest'->new($_) } @$_ ] };

declare 'MapStringInstancesFailoverRequest',
    as HashRef[InstancesFailoverRequest()];

declare 'SslCertsCreateEphemeralRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SslCertsCreateEphemeralRequest'];

coerce 'SslCertsCreateEphemeralRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SslCertsCreateEphemeralRequest'->new($_) };

declare 'RepeatedSslCertsCreateEphemeralRequest',
    as ArrayRef[SslCertsCreateEphemeralRequest()];

coerce 'RepeatedSslCertsCreateEphemeralRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SslCertsCreateEphemeralRequest'->new($_) } @$_ ] };

declare 'MapStringSslCertsCreateEphemeralRequest',
    as HashRef[SslCertsCreateEphemeralRequest()];

declare 'InstancesImportRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::InstancesImportRequest'];

coerce 'InstancesImportRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesImportRequest'->new($_) };

declare 'RepeatedInstancesImportRequest',
    as ArrayRef[InstancesImportRequest()];

coerce 'RepeatedInstancesImportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesImportRequest'->new($_) } @$_ ] };

declare 'MapStringInstancesImportRequest',
    as HashRef[InstancesImportRequest()];

declare 'InstancesPreCheckMajorVersionUpgradeRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::InstancesPreCheckMajorVersionUpgradeRequest'];

coerce 'InstancesPreCheckMajorVersionUpgradeRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesPreCheckMajorVersionUpgradeRequest'->new($_) };

declare 'RepeatedInstancesPreCheckMajorVersionUpgradeRequest',
    as ArrayRef[InstancesPreCheckMajorVersionUpgradeRequest()];

coerce 'RepeatedInstancesPreCheckMajorVersionUpgradeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesPreCheckMajorVersionUpgradeRequest'->new($_) } @$_ ] };

declare 'MapStringInstancesPreCheckMajorVersionUpgradeRequest',
    as HashRef[InstancesPreCheckMajorVersionUpgradeRequest()];

declare 'InstancesListResponse',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::InstancesListResponse'];

coerce 'InstancesListResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesListResponse'->new($_) };

declare 'RepeatedInstancesListResponse',
    as ArrayRef[InstancesListResponse()];

coerce 'RepeatedInstancesListResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesListResponse'->new($_) } @$_ ] };

declare 'MapStringInstancesListResponse',
    as HashRef[InstancesListResponse()];

declare 'InstancesListServerCasResponse',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::InstancesListServerCasResponse'];

coerce 'InstancesListServerCasResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesListServerCasResponse'->new($_) };

declare 'RepeatedInstancesListServerCasResponse',
    as ArrayRef[InstancesListServerCasResponse()];

coerce 'RepeatedInstancesListServerCasResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesListServerCasResponse'->new($_) } @$_ ] };

declare 'MapStringInstancesListServerCasResponse',
    as HashRef[InstancesListServerCasResponse()];

declare 'InstancesListServerCertificatesResponse',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::InstancesListServerCertificatesResponse'];

coerce 'InstancesListServerCertificatesResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesListServerCertificatesResponse'->new($_) };

declare 'RepeatedInstancesListServerCertificatesResponse',
    as ArrayRef[InstancesListServerCertificatesResponse()];

coerce 'RepeatedInstancesListServerCertificatesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesListServerCertificatesResponse'->new($_) } @$_ ] };

declare 'MapStringInstancesListServerCertificatesResponse',
    as HashRef[InstancesListServerCertificatesResponse()];

declare 'InstancesListEntraIdCertificatesResponse',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::InstancesListEntraIdCertificatesResponse'];

coerce 'InstancesListEntraIdCertificatesResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesListEntraIdCertificatesResponse'->new($_) };

declare 'RepeatedInstancesListEntraIdCertificatesResponse',
    as ArrayRef[InstancesListEntraIdCertificatesResponse()];

coerce 'RepeatedInstancesListEntraIdCertificatesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesListEntraIdCertificatesResponse'->new($_) } @$_ ] };

declare 'MapStringInstancesListEntraIdCertificatesResponse',
    as HashRef[InstancesListEntraIdCertificatesResponse()];

declare 'InstancesRestoreBackupRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::InstancesRestoreBackupRequest'];

coerce 'InstancesRestoreBackupRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesRestoreBackupRequest'->new($_) };

declare 'RepeatedInstancesRestoreBackupRequest',
    as ArrayRef[InstancesRestoreBackupRequest()];

coerce 'RepeatedInstancesRestoreBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesRestoreBackupRequest'->new($_) } @$_ ] };

declare 'MapStringInstancesRestoreBackupRequest',
    as HashRef[InstancesRestoreBackupRequest()];

declare 'InstancesRotateServerCaRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::InstancesRotateServerCaRequest'];

coerce 'InstancesRotateServerCaRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesRotateServerCaRequest'->new($_) };

declare 'RepeatedInstancesRotateServerCaRequest',
    as ArrayRef[InstancesRotateServerCaRequest()];

coerce 'RepeatedInstancesRotateServerCaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesRotateServerCaRequest'->new($_) } @$_ ] };

declare 'MapStringInstancesRotateServerCaRequest',
    as HashRef[InstancesRotateServerCaRequest()];

declare 'InstancesRotateServerCertificateRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::InstancesRotateServerCertificateRequest'];

coerce 'InstancesRotateServerCertificateRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesRotateServerCertificateRequest'->new($_) };

declare 'RepeatedInstancesRotateServerCertificateRequest',
    as ArrayRef[InstancesRotateServerCertificateRequest()];

coerce 'RepeatedInstancesRotateServerCertificateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesRotateServerCertificateRequest'->new($_) } @$_ ] };

declare 'MapStringInstancesRotateServerCertificateRequest',
    as HashRef[InstancesRotateServerCertificateRequest()];

declare 'InstancesRotateEntraIdCertificateRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::InstancesRotateEntraIdCertificateRequest'];

coerce 'InstancesRotateEntraIdCertificateRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesRotateEntraIdCertificateRequest'->new($_) };

declare 'RepeatedInstancesRotateEntraIdCertificateRequest',
    as ArrayRef[InstancesRotateEntraIdCertificateRequest()];

coerce 'RepeatedInstancesRotateEntraIdCertificateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesRotateEntraIdCertificateRequest'->new($_) } @$_ ] };

declare 'MapStringInstancesRotateEntraIdCertificateRequest',
    as HashRef[InstancesRotateEntraIdCertificateRequest()];

declare 'InstancesTruncateLogRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::InstancesTruncateLogRequest'];

coerce 'InstancesTruncateLogRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesTruncateLogRequest'->new($_) };

declare 'RepeatedInstancesTruncateLogRequest',
    as ArrayRef[InstancesTruncateLogRequest()];

coerce 'RepeatedInstancesTruncateLogRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesTruncateLogRequest'->new($_) } @$_ ] };

declare 'MapStringInstancesTruncateLogRequest',
    as HashRef[InstancesTruncateLogRequest()];

declare 'InstancesAcquireSsrsLeaseRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::InstancesAcquireSsrsLeaseRequest'];

coerce 'InstancesAcquireSsrsLeaseRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesAcquireSsrsLeaseRequest'->new($_) };

declare 'RepeatedInstancesAcquireSsrsLeaseRequest',
    as ArrayRef[InstancesAcquireSsrsLeaseRequest()];

coerce 'RepeatedInstancesAcquireSsrsLeaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesAcquireSsrsLeaseRequest'->new($_) } @$_ ] };

declare 'MapStringInstancesAcquireSsrsLeaseRequest',
    as HashRef[InstancesAcquireSsrsLeaseRequest()];

declare 'SqlInstancesPreCheckMajorVersionUpgradeRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesPreCheckMajorVersionUpgradeRequest'];

coerce 'SqlInstancesPreCheckMajorVersionUpgradeRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesPreCheckMajorVersionUpgradeRequest'->new($_) };

declare 'RepeatedSqlInstancesPreCheckMajorVersionUpgradeRequest',
    as ArrayRef[SqlInstancesPreCheckMajorVersionUpgradeRequest()];

coerce 'RepeatedSqlInstancesPreCheckMajorVersionUpgradeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesPreCheckMajorVersionUpgradeRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesPreCheckMajorVersionUpgradeRequest',
    as HashRef[SqlInstancesPreCheckMajorVersionUpgradeRequest()];

declare 'SqlInstancesVerifyExternalSyncSettingsResponse',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesVerifyExternalSyncSettingsResponse'];

coerce 'SqlInstancesVerifyExternalSyncSettingsResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesVerifyExternalSyncSettingsResponse'->new($_) };

declare 'RepeatedSqlInstancesVerifyExternalSyncSettingsResponse',
    as ArrayRef[SqlInstancesVerifyExternalSyncSettingsResponse()];

coerce 'RepeatedSqlInstancesVerifyExternalSyncSettingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesVerifyExternalSyncSettingsResponse'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesVerifyExternalSyncSettingsResponse',
    as HashRef[SqlInstancesVerifyExternalSyncSettingsResponse()];

declare 'SqlInstancesGetDiskShrinkConfigResponse',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesGetDiskShrinkConfigResponse'];

coerce 'SqlInstancesGetDiskShrinkConfigResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesGetDiskShrinkConfigResponse'->new($_) };

declare 'RepeatedSqlInstancesGetDiskShrinkConfigResponse',
    as ArrayRef[SqlInstancesGetDiskShrinkConfigResponse()];

coerce 'RepeatedSqlInstancesGetDiskShrinkConfigResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesGetDiskShrinkConfigResponse'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesGetDiskShrinkConfigResponse',
    as HashRef[SqlInstancesGetDiskShrinkConfigResponse()];

declare 'SqlInstancesGetLatestRecoveryTimeRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesGetLatestRecoveryTimeRequest'];

coerce 'SqlInstancesGetLatestRecoveryTimeRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesGetLatestRecoveryTimeRequest'->new($_) };

declare 'RepeatedSqlInstancesGetLatestRecoveryTimeRequest',
    as ArrayRef[SqlInstancesGetLatestRecoveryTimeRequest()];

coerce 'RepeatedSqlInstancesGetLatestRecoveryTimeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesGetLatestRecoveryTimeRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesGetLatestRecoveryTimeRequest',
    as HashRef[SqlInstancesGetLatestRecoveryTimeRequest()];

declare 'SqlInstancesGetLatestRecoveryTimeResponse',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesGetLatestRecoveryTimeResponse'];

coerce 'SqlInstancesGetLatestRecoveryTimeResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesGetLatestRecoveryTimeResponse'->new($_) };

declare 'RepeatedSqlInstancesGetLatestRecoveryTimeResponse',
    as ArrayRef[SqlInstancesGetLatestRecoveryTimeResponse()];

coerce 'RepeatedSqlInstancesGetLatestRecoveryTimeResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesGetLatestRecoveryTimeResponse'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesGetLatestRecoveryTimeResponse',
    as HashRef[SqlInstancesGetLatestRecoveryTimeResponse()];

declare 'CloneContext',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::CloneContext'];

coerce 'CloneContext',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::CloneContext'->new($_) };

declare 'RepeatedCloneContext',
    as ArrayRef[CloneContext()];

coerce 'RepeatedCloneContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::CloneContext'->new($_) } @$_ ] };

declare 'MapStringCloneContext',
    as HashRef[CloneContext()];

declare 'PointInTimeRestoreContext',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::PointInTimeRestoreContext'];

coerce 'PointInTimeRestoreContext',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::PointInTimeRestoreContext'->new($_) };

declare 'RepeatedPointInTimeRestoreContext',
    as ArrayRef[PointInTimeRestoreContext()];

coerce 'RepeatedPointInTimeRestoreContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::PointInTimeRestoreContext'->new($_) } @$_ ] };

declare 'MapStringPointInTimeRestoreContext',
    as HashRef[PointInTimeRestoreContext()];

declare 'BinLogCoordinates',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::BinLogCoordinates'];

coerce 'BinLogCoordinates',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::BinLogCoordinates'->new($_) };

declare 'RepeatedBinLogCoordinates',
    as ArrayRef[BinLogCoordinates()];

coerce 'RepeatedBinLogCoordinates',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::BinLogCoordinates'->new($_) } @$_ ] };

declare 'MapStringBinLogCoordinates',
    as HashRef[BinLogCoordinates()];

declare 'DatabaseInstance',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::DatabaseInstance'];

coerce 'DatabaseInstance',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::DatabaseInstance'->new($_) };

declare 'RepeatedDatabaseInstance',
    as ArrayRef[DatabaseInstance()];

coerce 'RepeatedDatabaseInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::DatabaseInstance'->new($_) } @$_ ] };

declare 'MapStringDatabaseInstance',
    as HashRef[DatabaseInstance()];

declare 'SqlInstanceState',
    as (Int | Str);

declare 'SqlNetworkArchitecture',
    as (Int | Str);

declare 'SqlFailoverReplica',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::DatabaseInstance::SqlFailoverReplica'];

coerce 'SqlFailoverReplica',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::DatabaseInstance::SqlFailoverReplica'->new($_) };

declare 'RepeatedSqlFailoverReplica',
    as ArrayRef[SqlFailoverReplica()];

coerce 'RepeatedSqlFailoverReplica',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::DatabaseInstance::SqlFailoverReplica'->new($_) } @$_ ] };

declare 'MapStringSqlFailoverReplica',
    as HashRef[SqlFailoverReplica()];

declare 'SqlScheduledMaintenance',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::DatabaseInstance::SqlScheduledMaintenance'];

coerce 'SqlScheduledMaintenance',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::DatabaseInstance::SqlScheduledMaintenance'->new($_) };

declare 'RepeatedSqlScheduledMaintenance',
    as ArrayRef[SqlScheduledMaintenance()];

coerce 'RepeatedSqlScheduledMaintenance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::DatabaseInstance::SqlScheduledMaintenance'->new($_) } @$_ ] };

declare 'MapStringSqlScheduledMaintenance',
    as HashRef[SqlScheduledMaintenance()];

declare 'SqlOutOfDiskReport',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::DatabaseInstance::SqlOutOfDiskReport'];

coerce 'SqlOutOfDiskReport',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::DatabaseInstance::SqlOutOfDiskReport'->new($_) };

declare 'RepeatedSqlOutOfDiskReport',
    as ArrayRef[SqlOutOfDiskReport()];

coerce 'RepeatedSqlOutOfDiskReport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::DatabaseInstance::SqlOutOfDiskReport'->new($_) } @$_ ] };

declare 'MapStringSqlOutOfDiskReport',
    as HashRef[SqlOutOfDiskReport()];

declare 'SqlOutOfDiskState',
    as (Int | Str);

declare 'PoolNodeConfig',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::DatabaseInstance::PoolNodeConfig'];

coerce 'PoolNodeConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::DatabaseInstance::PoolNodeConfig'->new($_) };

declare 'RepeatedPoolNodeConfig',
    as ArrayRef[PoolNodeConfig()];

coerce 'RepeatedPoolNodeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::DatabaseInstance::PoolNodeConfig'->new($_) } @$_ ] };

declare 'MapStringPoolNodeConfig',
    as HashRef[PoolNodeConfig()];

declare 'TagsEntry',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::DatabaseInstance::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::DatabaseInstance::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::DatabaseInstance::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

declare 'GeminiInstanceConfig',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::GeminiInstanceConfig'];

coerce 'GeminiInstanceConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::GeminiInstanceConfig'->new($_) };

declare 'RepeatedGeminiInstanceConfig',
    as ArrayRef[GeminiInstanceConfig()];

coerce 'RepeatedGeminiInstanceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::GeminiInstanceConfig'->new($_) } @$_ ] };

declare 'MapStringGeminiInstanceConfig',
    as HashRef[GeminiInstanceConfig()];

declare 'ReplicationCluster',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::ReplicationCluster'];

coerce 'ReplicationCluster',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::ReplicationCluster'->new($_) };

declare 'RepeatedReplicationCluster',
    as ArrayRef[ReplicationCluster()];

coerce 'RepeatedReplicationCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::ReplicationCluster'->new($_) } @$_ ] };

declare 'MapStringReplicationCluster',
    as HashRef[ReplicationCluster()];

declare 'AvailableDatabaseVersion',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::AvailableDatabaseVersion'];

coerce 'AvailableDatabaseVersion',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::AvailableDatabaseVersion'->new($_) };

declare 'RepeatedAvailableDatabaseVersion',
    as ArrayRef[AvailableDatabaseVersion()];

coerce 'RepeatedAvailableDatabaseVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::AvailableDatabaseVersion'->new($_) } @$_ ] };

declare 'MapStringAvailableDatabaseVersion',
    as HashRef[AvailableDatabaseVersion()];

declare 'SqlInstancesRescheduleMaintenanceRequestBody',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesRescheduleMaintenanceRequestBody'];

coerce 'SqlInstancesRescheduleMaintenanceRequestBody',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesRescheduleMaintenanceRequestBody'->new($_) };

declare 'RepeatedSqlInstancesRescheduleMaintenanceRequestBody',
    as ArrayRef[SqlInstancesRescheduleMaintenanceRequestBody()];

coerce 'RepeatedSqlInstancesRescheduleMaintenanceRequestBody',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesRescheduleMaintenanceRequestBody'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesRescheduleMaintenanceRequestBody',
    as HashRef[SqlInstancesRescheduleMaintenanceRequestBody()];

declare 'RescheduleType',
    as (Int | Str);

declare 'Reschedule',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesRescheduleMaintenanceRequestBody::Reschedule'];

coerce 'Reschedule',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesRescheduleMaintenanceRequestBody::Reschedule'->new($_) };

declare 'RepeatedReschedule',
    as ArrayRef[Reschedule()];

coerce 'RepeatedReschedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesRescheduleMaintenanceRequestBody::Reschedule'->new($_) } @$_ ] };

declare 'MapStringReschedule',
    as HashRef[Reschedule()];

declare 'DemoteMasterContext',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::DemoteMasterContext'];

coerce 'DemoteMasterContext',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::DemoteMasterContext'->new($_) };

declare 'RepeatedDemoteMasterContext',
    as ArrayRef[DemoteMasterContext()];

coerce 'RepeatedDemoteMasterContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::DemoteMasterContext'->new($_) } @$_ ] };

declare 'MapStringDemoteMasterContext',
    as HashRef[DemoteMasterContext()];

declare 'DemoteContext',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::DemoteContext'];

coerce 'DemoteContext',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::DemoteContext'->new($_) };

declare 'RepeatedDemoteContext',
    as ArrayRef[DemoteContext()];

coerce 'RepeatedDemoteContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::DemoteContext'->new($_) } @$_ ] };

declare 'MapStringDemoteContext',
    as HashRef[DemoteContext()];

declare 'FailoverContext',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::FailoverContext'];

coerce 'FailoverContext',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::FailoverContext'->new($_) };

declare 'RepeatedFailoverContext',
    as ArrayRef[FailoverContext()];

coerce 'RepeatedFailoverContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::FailoverContext'->new($_) } @$_ ] };

declare 'MapStringFailoverContext',
    as HashRef[FailoverContext()];

declare 'RestoreBackupContext',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::RestoreBackupContext'];

coerce 'RestoreBackupContext',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::RestoreBackupContext'->new($_) };

declare 'RepeatedRestoreBackupContext',
    as ArrayRef[RestoreBackupContext()];

coerce 'RepeatedRestoreBackupContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::RestoreBackupContext'->new($_) } @$_ ] };

declare 'MapStringRestoreBackupContext',
    as HashRef[RestoreBackupContext()];

declare 'RotateServerCaContext',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::RotateServerCaContext'];

coerce 'RotateServerCaContext',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::RotateServerCaContext'->new($_) };

declare 'RepeatedRotateServerCaContext',
    as ArrayRef[RotateServerCaContext()];

coerce 'RepeatedRotateServerCaContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::RotateServerCaContext'->new($_) } @$_ ] };

declare 'MapStringRotateServerCaContext',
    as HashRef[RotateServerCaContext()];

declare 'RotateServerCertificateContext',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::RotateServerCertificateContext'];

coerce 'RotateServerCertificateContext',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::RotateServerCertificateContext'->new($_) };

declare 'RepeatedRotateServerCertificateContext',
    as ArrayRef[RotateServerCertificateContext()];

coerce 'RepeatedRotateServerCertificateContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::RotateServerCertificateContext'->new($_) } @$_ ] };

declare 'MapStringRotateServerCertificateContext',
    as HashRef[RotateServerCertificateContext()];

declare 'RotateEntraIdCertificateContext',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::RotateEntraIdCertificateContext'];

coerce 'RotateEntraIdCertificateContext',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::RotateEntraIdCertificateContext'->new($_) };

declare 'RepeatedRotateEntraIdCertificateContext',
    as ArrayRef[RotateEntraIdCertificateContext()];

coerce 'RepeatedRotateEntraIdCertificateContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::RotateEntraIdCertificateContext'->new($_) } @$_ ] };

declare 'MapStringRotateEntraIdCertificateContext',
    as HashRef[RotateEntraIdCertificateContext()];

declare 'TruncateLogContext',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::TruncateLogContext'];

coerce 'TruncateLogContext',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::TruncateLogContext'->new($_) };

declare 'RepeatedTruncateLogContext',
    as ArrayRef[TruncateLogContext()];

coerce 'RepeatedTruncateLogContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::TruncateLogContext'->new($_) } @$_ ] };

declare 'MapStringTruncateLogContext',
    as HashRef[TruncateLogContext()];

declare 'SqlExternalSyncSettingError',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlExternalSyncSettingError'];

coerce 'SqlExternalSyncSettingError',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlExternalSyncSettingError'->new($_) };

declare 'RepeatedSqlExternalSyncSettingError',
    as ArrayRef[SqlExternalSyncSettingError()];

coerce 'RepeatedSqlExternalSyncSettingError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlExternalSyncSettingError'->new($_) } @$_ ] };

declare 'MapStringSqlExternalSyncSettingError',
    as HashRef[SqlExternalSyncSettingError()];

declare 'SqlExternalSyncSettingErrorType',
    as (Int | Str);

declare 'SelectedObjects',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SelectedObjects'];

coerce 'SelectedObjects',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SelectedObjects'->new($_) };

declare 'RepeatedSelectedObjects',
    as ArrayRef[SelectedObjects()];

coerce 'RepeatedSelectedObjects',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SelectedObjects'->new($_) } @$_ ] };

declare 'MapStringSelectedObjects',
    as HashRef[SelectedObjects()];

declare 'OnPremisesConfiguration',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::OnPremisesConfiguration'];

coerce 'OnPremisesConfiguration',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::OnPremisesConfiguration'->new($_) };

declare 'RepeatedOnPremisesConfiguration',
    as ArrayRef[OnPremisesConfiguration()];

coerce 'RepeatedOnPremisesConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::OnPremisesConfiguration'->new($_) } @$_ ] };

declare 'MapStringOnPremisesConfiguration',
    as HashRef[OnPremisesConfiguration()];

declare 'SslOption',
    as (Int | Str);

declare 'ReplicaConfiguration',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::ReplicaConfiguration'];

coerce 'ReplicaConfiguration',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::ReplicaConfiguration'->new($_) };

declare 'RepeatedReplicaConfiguration',
    as ArrayRef[ReplicaConfiguration()];

coerce 'RepeatedReplicaConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::ReplicaConfiguration'->new($_) } @$_ ] };

declare 'MapStringReplicaConfiguration',
    as HashRef[ReplicaConfiguration()];

declare 'SqlInstancesExecuteSqlRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesExecuteSqlRequest'];

coerce 'SqlInstancesExecuteSqlRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesExecuteSqlRequest'->new($_) };

declare 'RepeatedSqlInstancesExecuteSqlRequest',
    as ArrayRef[SqlInstancesExecuteSqlRequest()];

coerce 'RepeatedSqlInstancesExecuteSqlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesExecuteSqlRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesExecuteSqlRequest',
    as HashRef[SqlInstancesExecuteSqlRequest()];

declare 'ExecuteSqlPayload',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::ExecuteSqlPayload'];

coerce 'ExecuteSqlPayload',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::ExecuteSqlPayload'->new($_) };

declare 'RepeatedExecuteSqlPayload',
    as ArrayRef[ExecuteSqlPayload()];

coerce 'RepeatedExecuteSqlPayload',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::ExecuteSqlPayload'->new($_) } @$_ ] };

declare 'MapStringExecuteSqlPayload',
    as HashRef[ExecuteSqlPayload()];

declare 'PartialResultMode',
    as (Int | Str);

declare 'SqlInstancesExecuteSqlResponse',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesExecuteSqlResponse'];

coerce 'SqlInstancesExecuteSqlResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesExecuteSqlResponse'->new($_) };

declare 'RepeatedSqlInstancesExecuteSqlResponse',
    as ArrayRef[SqlInstancesExecuteSqlResponse()];

coerce 'RepeatedSqlInstancesExecuteSqlResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesExecuteSqlResponse'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesExecuteSqlResponse',
    as HashRef[SqlInstancesExecuteSqlResponse()];

declare 'Message',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesExecuteSqlResponse::Message'];

coerce 'Message',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesExecuteSqlResponse::Message'->new($_) };

declare 'RepeatedMessage',
    as ArrayRef[Message()];

coerce 'RepeatedMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesExecuteSqlResponse::Message'->new($_) } @$_ ] };

declare 'MapStringMessage',
    as HashRef[Message()];

declare 'QueryResult',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::QueryResult'];

coerce 'QueryResult',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::QueryResult'->new($_) };

declare 'RepeatedQueryResult',
    as ArrayRef[QueryResult()];

coerce 'RepeatedQueryResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::QueryResult'->new($_) } @$_ ] };

declare 'MapStringQueryResult',
    as HashRef[QueryResult()];

declare 'Column',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::Column'];

coerce 'Column',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::Column'->new($_) };

declare 'RepeatedColumn',
    as ArrayRef[Column()];

coerce 'RepeatedColumn',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::Column'->new($_) } @$_ ] };

declare 'MapStringColumn',
    as HashRef[Column()];

declare 'Row',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::Row'];

coerce 'Row',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::Row'->new($_) };

declare 'RepeatedRow',
    as ArrayRef[Row()];

coerce 'RepeatedRow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::Row'->new($_) } @$_ ] };

declare 'MapStringRow',
    as HashRef[Row()];

declare 'Value',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::Value'];

coerce 'Value',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::Value'->new($_) };

declare 'RepeatedValue',
    as ArrayRef[Value()];

coerce 'RepeatedValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::Value'->new($_) } @$_ ] };

declare 'MapStringValue',
    as HashRef[Value()];

declare 'Metadata',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::Metadata'];

coerce 'Metadata',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::Metadata'->new($_) };

declare 'RepeatedMetadata',
    as ArrayRef[Metadata()];

coerce 'RepeatedMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::Metadata'->new($_) } @$_ ] };

declare 'MapStringMetadata',
    as HashRef[Metadata()];

declare 'SqlInstancesAcquireSsrsLeaseRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesAcquireSsrsLeaseRequest'];

coerce 'SqlInstancesAcquireSsrsLeaseRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesAcquireSsrsLeaseRequest'->new($_) };

declare 'RepeatedSqlInstancesAcquireSsrsLeaseRequest',
    as ArrayRef[SqlInstancesAcquireSsrsLeaseRequest()];

coerce 'RepeatedSqlInstancesAcquireSsrsLeaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesAcquireSsrsLeaseRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesAcquireSsrsLeaseRequest',
    as HashRef[SqlInstancesAcquireSsrsLeaseRequest()];

declare 'SqlInstancesAcquireSsrsLeaseResponse',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesAcquireSsrsLeaseResponse'];

coerce 'SqlInstancesAcquireSsrsLeaseResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesAcquireSsrsLeaseResponse'->new($_) };

declare 'RepeatedSqlInstancesAcquireSsrsLeaseResponse',
    as ArrayRef[SqlInstancesAcquireSsrsLeaseResponse()];

coerce 'RepeatedSqlInstancesAcquireSsrsLeaseResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesAcquireSsrsLeaseResponse'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesAcquireSsrsLeaseResponse',
    as HashRef[SqlInstancesAcquireSsrsLeaseResponse()];

declare 'SqlInstancesReleaseSsrsLeaseRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesReleaseSsrsLeaseRequest'];

coerce 'SqlInstancesReleaseSsrsLeaseRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesReleaseSsrsLeaseRequest'->new($_) };

declare 'RepeatedSqlInstancesReleaseSsrsLeaseRequest',
    as ArrayRef[SqlInstancesReleaseSsrsLeaseRequest()];

coerce 'RepeatedSqlInstancesReleaseSsrsLeaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesReleaseSsrsLeaseRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesReleaseSsrsLeaseRequest',
    as HashRef[SqlInstancesReleaseSsrsLeaseRequest()];

declare 'SqlInstancesReleaseSsrsLeaseResponse',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesReleaseSsrsLeaseResponse'];

coerce 'SqlInstancesReleaseSsrsLeaseResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesReleaseSsrsLeaseResponse'->new($_) };

declare 'RepeatedSqlInstancesReleaseSsrsLeaseResponse',
    as ArrayRef[SqlInstancesReleaseSsrsLeaseResponse()];

coerce 'RepeatedSqlInstancesReleaseSsrsLeaseResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesReleaseSsrsLeaseResponse'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesReleaseSsrsLeaseResponse',
    as HashRef[SqlInstancesReleaseSsrsLeaseResponse()];

declare 'SqlInstancesPointInTimeRestoreRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesPointInTimeRestoreRequest'];

coerce 'SqlInstancesPointInTimeRestoreRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesPointInTimeRestoreRequest'->new($_) };

declare 'RepeatedSqlInstancesPointInTimeRestoreRequest',
    as ArrayRef[SqlInstancesPointInTimeRestoreRequest()];

coerce 'RepeatedSqlInstancesPointInTimeRestoreRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesPointInTimeRestoreRequest'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesPointInTimeRestoreRequest',
    as HashRef[SqlInstancesPointInTimeRestoreRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlInstances::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
