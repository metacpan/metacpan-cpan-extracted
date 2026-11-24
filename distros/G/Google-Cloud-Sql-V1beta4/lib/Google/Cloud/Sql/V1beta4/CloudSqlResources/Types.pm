package Google::Cloud::Sql::V1beta4::CloudSqlResources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SqlFileType',
    as (Int | Str);

declare 'BakType',
    as (Int | Str);

declare 'AutoDnsStatus',
    as (Int | Str);

declare 'SqlMaintenanceType',
    as (Int | Str);

declare 'CertificateType',
    as (Int | Str);

declare 'Intent',
    as (Int | Str);

declare 'SqlBackupRunStatus',
    as (Int | Str);

declare 'SqlBackupRunType',
    as (Int | Str);

declare 'SqlBackupKind',
    as (Int | Str);

declare 'SqlBackendType',
    as (Int | Str);

declare 'SqlIpAddressType',
    as (Int | Str);

declare 'SqlInstanceType',
    as (Int | Str);

declare 'SqlDatabaseVersion',
    as (Int | Str);

declare 'SqlSuspensionReason',
    as (Int | Str);

declare 'SqlPricingPlan',
    as (Int | Str);

declare 'SqlReplicationType',
    as (Int | Str);

declare 'SqlDataDiskType',
    as (Int | Str);

declare 'SqlAvailabilityType',
    as (Int | Str);

declare 'SqlUpdateTrack',
    as (Int | Str);

declare 'SqlFlagType',
    as (Int | Str);

declare 'SqlFlagScope',
    as (Int | Str);

declare 'AclEntry',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::AclEntry'];

coerce 'AclEntry',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::AclEntry'->new($_) };

declare 'RepeatedAclEntry',
    as ArrayRef[AclEntry()];

coerce 'RepeatedAclEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::AclEntry'->new($_) } @$_ ] };

declare 'MapStringAclEntry',
    as HashRef[AclEntry()];

declare 'ApiWarning',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::ApiWarning'];

coerce 'ApiWarning',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ApiWarning'->new($_) };

declare 'RepeatedApiWarning',
    as ArrayRef[ApiWarning()];

coerce 'RepeatedApiWarning',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ApiWarning'->new($_) } @$_ ] };

declare 'MapStringApiWarning',
    as HashRef[ApiWarning()];

declare 'SqlApiWarningCode',
    as (Int | Str);

declare 'BackupRetentionSettings',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::BackupRetentionSettings'];

coerce 'BackupRetentionSettings',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::BackupRetentionSettings'->new($_) };

declare 'RepeatedBackupRetentionSettings',
    as ArrayRef[BackupRetentionSettings()];

coerce 'RepeatedBackupRetentionSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::BackupRetentionSettings'->new($_) } @$_ ] };

declare 'MapStringBackupRetentionSettings',
    as HashRef[BackupRetentionSettings()];

declare 'RetentionUnit',
    as (Int | Str);

declare 'BackupConfiguration',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::BackupConfiguration'];

coerce 'BackupConfiguration',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::BackupConfiguration'->new($_) };

declare 'RepeatedBackupConfiguration',
    as ArrayRef[BackupConfiguration()];

coerce 'RepeatedBackupConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::BackupConfiguration'->new($_) } @$_ ] };

declare 'MapStringBackupConfiguration',
    as HashRef[BackupConfiguration()];

declare 'TransactionalLogStorageState',
    as (Int | Str);

declare 'BackupTier',
    as (Int | Str);

declare 'BackupRun',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::BackupRun'];

coerce 'BackupRun',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::BackupRun'->new($_) };

declare 'RepeatedBackupRun',
    as ArrayRef[BackupRun()];

coerce 'RepeatedBackupRun',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::BackupRun'->new($_) } @$_ ] };

declare 'MapStringBackupRun',
    as HashRef[BackupRun()];

declare 'Backup',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::Backup'];

coerce 'Backup',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Backup'->new($_) };

declare 'RepeatedBackup',
    as ArrayRef[Backup()];

coerce 'RepeatedBackup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Backup'->new($_) } @$_ ] };

declare 'MapStringBackup',
    as HashRef[Backup()];

declare 'SqlBackupType',
    as (Int | Str);

declare 'SqlBackupState',
    as (Int | Str);

declare 'BackupRunsListResponse',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::BackupRunsListResponse'];

coerce 'BackupRunsListResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::BackupRunsListResponse'->new($_) };

declare 'RepeatedBackupRunsListResponse',
    as ArrayRef[BackupRunsListResponse()];

coerce 'RepeatedBackupRunsListResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::BackupRunsListResponse'->new($_) } @$_ ] };

declare 'MapStringBackupRunsListResponse',
    as HashRef[BackupRunsListResponse()];

declare 'BinLogCoordinates',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::BinLogCoordinates'];

coerce 'BinLogCoordinates',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::BinLogCoordinates'->new($_) };

declare 'RepeatedBinLogCoordinates',
    as ArrayRef[BinLogCoordinates()];

coerce 'RepeatedBinLogCoordinates',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::BinLogCoordinates'->new($_) } @$_ ] };

declare 'MapStringBinLogCoordinates',
    as HashRef[BinLogCoordinates()];

declare 'BackupContext',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::BackupContext'];

coerce 'BackupContext',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::BackupContext'->new($_) };

declare 'RepeatedBackupContext',
    as ArrayRef[BackupContext()];

coerce 'RepeatedBackupContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::BackupContext'->new($_) } @$_ ] };

declare 'MapStringBackupContext',
    as HashRef[BackupContext()];

declare 'CloneContext',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::CloneContext'];

coerce 'CloneContext',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::CloneContext'->new($_) };

declare 'RepeatedCloneContext',
    as ArrayRef[CloneContext()];

coerce 'RepeatedCloneContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::CloneContext'->new($_) } @$_ ] };

declare 'MapStringCloneContext',
    as HashRef[CloneContext()];

declare 'Database',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::Database'];

coerce 'Database',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Database'->new($_) };

declare 'RepeatedDatabase',
    as ArrayRef[Database()];

coerce 'RepeatedDatabase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Database'->new($_) } @$_ ] };

declare 'MapStringDatabase',
    as HashRef[Database()];

declare 'SqlServerDatabaseDetails',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlServerDatabaseDetails'];

coerce 'SqlServerDatabaseDetails',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlServerDatabaseDetails'->new($_) };

declare 'RepeatedSqlServerDatabaseDetails',
    as ArrayRef[SqlServerDatabaseDetails()];

coerce 'RepeatedSqlServerDatabaseDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlServerDatabaseDetails'->new($_) } @$_ ] };

declare 'MapStringSqlServerDatabaseDetails',
    as HashRef[SqlServerDatabaseDetails()];

declare 'DatabaseFlags',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::DatabaseFlags'];

coerce 'DatabaseFlags',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DatabaseFlags'->new($_) };

declare 'RepeatedDatabaseFlags',
    as ArrayRef[DatabaseFlags()];

coerce 'RepeatedDatabaseFlags',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DatabaseFlags'->new($_) } @$_ ] };

declare 'MapStringDatabaseFlags',
    as HashRef[DatabaseFlags()];

declare 'SyncFlags',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::SyncFlags'];

coerce 'SyncFlags',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SyncFlags'->new($_) };

declare 'RepeatedSyncFlags',
    as ArrayRef[SyncFlags()];

coerce 'RepeatedSyncFlags',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SyncFlags'->new($_) } @$_ ] };

declare 'MapStringSyncFlags',
    as HashRef[SyncFlags()];

declare 'InstanceReference',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::InstanceReference'];

coerce 'InstanceReference',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstanceReference'->new($_) };

declare 'RepeatedInstanceReference',
    as ArrayRef[InstanceReference()];

coerce 'RepeatedInstanceReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstanceReference'->new($_) } @$_ ] };

declare 'MapStringInstanceReference',
    as HashRef[InstanceReference()];

declare 'DatabaseInstance',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::DatabaseInstance'];

coerce 'DatabaseInstance',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DatabaseInstance'->new($_) };

declare 'RepeatedDatabaseInstance',
    as ArrayRef[DatabaseInstance()];

coerce 'RepeatedDatabaseInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DatabaseInstance'->new($_) } @$_ ] };

declare 'MapStringDatabaseInstance',
    as HashRef[DatabaseInstance()];

declare 'SqlInstanceState',
    as (Int | Str);

declare 'SqlNetworkArchitecture',
    as (Int | Str);

declare 'DatabaseCenterIntegration',
    as (Int | Str);

declare 'SqlFailoverReplica',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::DatabaseInstance::SqlFailoverReplica'];

coerce 'SqlFailoverReplica',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DatabaseInstance::SqlFailoverReplica'->new($_) };

declare 'RepeatedSqlFailoverReplica',
    as ArrayRef[SqlFailoverReplica()];

coerce 'RepeatedSqlFailoverReplica',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DatabaseInstance::SqlFailoverReplica'->new($_) } @$_ ] };

declare 'MapStringSqlFailoverReplica',
    as HashRef[SqlFailoverReplica()];

declare 'SqlScheduledMaintenance',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::DatabaseInstance::SqlScheduledMaintenance'];

coerce 'SqlScheduledMaintenance',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DatabaseInstance::SqlScheduledMaintenance'->new($_) };

declare 'RepeatedSqlScheduledMaintenance',
    as ArrayRef[SqlScheduledMaintenance()];

coerce 'RepeatedSqlScheduledMaintenance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DatabaseInstance::SqlScheduledMaintenance'->new($_) } @$_ ] };

declare 'MapStringSqlScheduledMaintenance',
    as HashRef[SqlScheduledMaintenance()];

declare 'SqlOutOfDiskReport',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::DatabaseInstance::SqlOutOfDiskReport'];

coerce 'SqlOutOfDiskReport',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DatabaseInstance::SqlOutOfDiskReport'->new($_) };

declare 'RepeatedSqlOutOfDiskReport',
    as ArrayRef[SqlOutOfDiskReport()];

coerce 'RepeatedSqlOutOfDiskReport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DatabaseInstance::SqlOutOfDiskReport'->new($_) } @$_ ] };

declare 'MapStringSqlOutOfDiskReport',
    as HashRef[SqlOutOfDiskReport()];

declare 'SqlOutOfDiskState',
    as (Int | Str);

declare 'PoolNodeConfig',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::DatabaseInstance::PoolNodeConfig'];

coerce 'PoolNodeConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DatabaseInstance::PoolNodeConfig'->new($_) };

declare 'RepeatedPoolNodeConfig',
    as ArrayRef[PoolNodeConfig()];

coerce 'RepeatedPoolNodeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DatabaseInstance::PoolNodeConfig'->new($_) } @$_ ] };

declare 'MapStringPoolNodeConfig',
    as HashRef[PoolNodeConfig()];

declare 'TagsEntry',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::DatabaseInstance::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DatabaseInstance::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DatabaseInstance::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

declare 'BlueGreenDeploymentInfo',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::BlueGreenDeploymentInfo'];

coerce 'BlueGreenDeploymentInfo',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::BlueGreenDeploymentInfo'->new($_) };

declare 'RepeatedBlueGreenDeploymentInfo',
    as ArrayRef[BlueGreenDeploymentInfo()];

coerce 'RepeatedBlueGreenDeploymentInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::BlueGreenDeploymentInfo'->new($_) } @$_ ] };

declare 'MapStringBlueGreenDeploymentInfo',
    as HashRef[BlueGreenDeploymentInfo()];

declare 'State',
    as (Int | Str);

declare 'SourceRole',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::BlueGreenDeploymentInfo::SourceRole'];

coerce 'SourceRole',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::BlueGreenDeploymentInfo::SourceRole'->new($_) };

declare 'RepeatedSourceRole',
    as ArrayRef[SourceRole()];

coerce 'RepeatedSourceRole',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::BlueGreenDeploymentInfo::SourceRole'->new($_) } @$_ ] };

declare 'MapStringSourceRole',
    as HashRef[SourceRole()];

declare 'TargetRole',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::BlueGreenDeploymentInfo::TargetRole'];

coerce 'TargetRole',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::BlueGreenDeploymentInfo::TargetRole'->new($_) };

declare 'RepeatedTargetRole',
    as ArrayRef[TargetRole()];

coerce 'RepeatedTargetRole',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::BlueGreenDeploymentInfo::TargetRole'->new($_) } @$_ ] };

declare 'MapStringTargetRole',
    as HashRef[TargetRole()];

declare 'WorkloadReplayConfig',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::WorkloadReplayConfig'];

coerce 'WorkloadReplayConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::WorkloadReplayConfig'->new($_) };

declare 'RepeatedWorkloadReplayConfig',
    as ArrayRef[WorkloadReplayConfig()];

coerce 'RepeatedWorkloadReplayConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::WorkloadReplayConfig'->new($_) } @$_ ] };

declare 'MapStringWorkloadReplayConfig',
    as HashRef[WorkloadReplayConfig()];

declare 'ReplayMode',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'WorkloadCaptureConfig',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::WorkloadCaptureConfig'];

coerce 'WorkloadCaptureConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::WorkloadCaptureConfig'->new($_) };

declare 'RepeatedWorkloadCaptureConfig',
    as ArrayRef[WorkloadCaptureConfig()];

coerce 'RepeatedWorkloadCaptureConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::WorkloadCaptureConfig'->new($_) } @$_ ] };

declare 'MapStringWorkloadCaptureConfig',
    as HashRef[WorkloadCaptureConfig()];

declare 'CaptureMode',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'DnsNameMapping',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::DnsNameMapping'];

coerce 'DnsNameMapping',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DnsNameMapping'->new($_) };

declare 'RepeatedDnsNameMapping',
    as ArrayRef[DnsNameMapping()];

coerce 'RepeatedDnsNameMapping',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DnsNameMapping'->new($_) } @$_ ] };

declare 'MapStringDnsNameMapping',
    as HashRef[DnsNameMapping()];

declare 'ConnectionType',
    as (Int | Str);

declare 'DnsScope',
    as (Int | Str);

declare 'RecordManager',
    as (Int | Str);

declare 'GeminiInstanceConfig',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::GeminiInstanceConfig'];

coerce 'GeminiInstanceConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::GeminiInstanceConfig'->new($_) };

declare 'RepeatedGeminiInstanceConfig',
    as ArrayRef[GeminiInstanceConfig()];

coerce 'RepeatedGeminiInstanceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::GeminiInstanceConfig'->new($_) } @$_ ] };

declare 'MapStringGeminiInstanceConfig',
    as HashRef[GeminiInstanceConfig()];

declare 'ReplicationCluster',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::ReplicationCluster'];

coerce 'ReplicationCluster',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ReplicationCluster'->new($_) };

declare 'RepeatedReplicationCluster',
    as ArrayRef[ReplicationCluster()];

coerce 'RepeatedReplicationCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ReplicationCluster'->new($_) } @$_ ] };

declare 'MapStringReplicationCluster',
    as HashRef[ReplicationCluster()];

declare 'AvailableDatabaseVersion',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::AvailableDatabaseVersion'];

coerce 'AvailableDatabaseVersion',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::AvailableDatabaseVersion'->new($_) };

declare 'RepeatedAvailableDatabaseVersion',
    as ArrayRef[AvailableDatabaseVersion()];

coerce 'RepeatedAvailableDatabaseVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::AvailableDatabaseVersion'->new($_) } @$_ ] };

declare 'MapStringAvailableDatabaseVersion',
    as HashRef[AvailableDatabaseVersion()];

declare 'DatabasesListResponse',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::DatabasesListResponse'];

coerce 'DatabasesListResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DatabasesListResponse'->new($_) };

declare 'RepeatedDatabasesListResponse',
    as ArrayRef[DatabasesListResponse()];

coerce 'RepeatedDatabasesListResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DatabasesListResponse'->new($_) } @$_ ] };

declare 'MapStringDatabasesListResponse',
    as HashRef[DatabasesListResponse()];

declare 'DemoteMasterConfiguration',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::DemoteMasterConfiguration'];

coerce 'DemoteMasterConfiguration',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DemoteMasterConfiguration'->new($_) };

declare 'RepeatedDemoteMasterConfiguration',
    as ArrayRef[DemoteMasterConfiguration()];

coerce 'RepeatedDemoteMasterConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DemoteMasterConfiguration'->new($_) } @$_ ] };

declare 'MapStringDemoteMasterConfiguration',
    as HashRef[DemoteMasterConfiguration()];

declare 'DemoteMasterContext',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::DemoteMasterContext'];

coerce 'DemoteMasterContext',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DemoteMasterContext'->new($_) };

declare 'RepeatedDemoteMasterContext',
    as ArrayRef[DemoteMasterContext()];

coerce 'RepeatedDemoteMasterContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DemoteMasterContext'->new($_) } @$_ ] };

declare 'MapStringDemoteMasterContext',
    as HashRef[DemoteMasterContext()];

declare 'DemoteMasterMySqlReplicaConfiguration',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::DemoteMasterMySqlReplicaConfiguration'];

coerce 'DemoteMasterMySqlReplicaConfiguration',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DemoteMasterMySqlReplicaConfiguration'->new($_) };

declare 'RepeatedDemoteMasterMySqlReplicaConfiguration',
    as ArrayRef[DemoteMasterMySqlReplicaConfiguration()];

coerce 'RepeatedDemoteMasterMySqlReplicaConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DemoteMasterMySqlReplicaConfiguration'->new($_) } @$_ ] };

declare 'MapStringDemoteMasterMySqlReplicaConfiguration',
    as HashRef[DemoteMasterMySqlReplicaConfiguration()];

declare 'DemoteContext',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::DemoteContext'];

coerce 'DemoteContext',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DemoteContext'->new($_) };

declare 'RepeatedDemoteContext',
    as ArrayRef[DemoteContext()];

coerce 'RepeatedDemoteContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DemoteContext'->new($_) } @$_ ] };

declare 'MapStringDemoteContext',
    as HashRef[DemoteContext()];

declare 'ExportContext',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::ExportContext'];

coerce 'ExportContext',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ExportContext'->new($_) };

declare 'RepeatedExportContext',
    as ArrayRef[ExportContext()];

coerce 'RepeatedExportContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ExportContext'->new($_) } @$_ ] };

declare 'MapStringExportContext',
    as HashRef[ExportContext()];

declare 'SqlCsvExportOptions',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::ExportContext::SqlCsvExportOptions'];

coerce 'SqlCsvExportOptions',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ExportContext::SqlCsvExportOptions'->new($_) };

declare 'RepeatedSqlCsvExportOptions',
    as ArrayRef[SqlCsvExportOptions()];

coerce 'RepeatedSqlCsvExportOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ExportContext::SqlCsvExportOptions'->new($_) } @$_ ] };

declare 'MapStringSqlCsvExportOptions',
    as HashRef[SqlCsvExportOptions()];

declare 'SqlExportOptions',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::ExportContext::SqlExportOptions'];

coerce 'SqlExportOptions',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ExportContext::SqlExportOptions'->new($_) };

declare 'RepeatedSqlExportOptions',
    as ArrayRef[SqlExportOptions()];

coerce 'RepeatedSqlExportOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ExportContext::SqlExportOptions'->new($_) } @$_ ] };

declare 'MapStringSqlExportOptions',
    as HashRef[SqlExportOptions()];

declare 'MysqlExportOptions',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::ExportContext::SqlExportOptions::MysqlExportOptions'];

coerce 'MysqlExportOptions',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ExportContext::SqlExportOptions::MysqlExportOptions'->new($_) };

declare 'RepeatedMysqlExportOptions',
    as ArrayRef[MysqlExportOptions()];

coerce 'RepeatedMysqlExportOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ExportContext::SqlExportOptions::MysqlExportOptions'->new($_) } @$_ ] };

declare 'MapStringMysqlExportOptions',
    as HashRef[MysqlExportOptions()];

declare 'PostgresExportOptions',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::ExportContext::SqlExportOptions::PostgresExportOptions'];

coerce 'PostgresExportOptions',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ExportContext::SqlExportOptions::PostgresExportOptions'->new($_) };

declare 'RepeatedPostgresExportOptions',
    as ArrayRef[PostgresExportOptions()];

coerce 'RepeatedPostgresExportOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ExportContext::SqlExportOptions::PostgresExportOptions'->new($_) } @$_ ] };

declare 'MapStringPostgresExportOptions',
    as HashRef[PostgresExportOptions()];

declare 'SqlBakExportOptions',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::ExportContext::SqlBakExportOptions'];

coerce 'SqlBakExportOptions',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ExportContext::SqlBakExportOptions'->new($_) };

declare 'RepeatedSqlBakExportOptions',
    as ArrayRef[SqlBakExportOptions()];

coerce 'RepeatedSqlBakExportOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ExportContext::SqlBakExportOptions'->new($_) } @$_ ] };

declare 'MapStringSqlBakExportOptions',
    as HashRef[SqlBakExportOptions()];

declare 'SqlTdeExportOptions',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::ExportContext::SqlTdeExportOptions'];

coerce 'SqlTdeExportOptions',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ExportContext::SqlTdeExportOptions'->new($_) };

declare 'RepeatedSqlTdeExportOptions',
    as ArrayRef[SqlTdeExportOptions()];

coerce 'RepeatedSqlTdeExportOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ExportContext::SqlTdeExportOptions'->new($_) } @$_ ] };

declare 'MapStringSqlTdeExportOptions',
    as HashRef[SqlTdeExportOptions()];

declare 'FailoverContext',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::FailoverContext'];

coerce 'FailoverContext',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::FailoverContext'->new($_) };

declare 'RepeatedFailoverContext',
    as ArrayRef[FailoverContext()];

coerce 'RepeatedFailoverContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::FailoverContext'->new($_) } @$_ ] };

declare 'MapStringFailoverContext',
    as HashRef[FailoverContext()];

declare 'Flag',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::Flag'];

coerce 'Flag',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Flag'->new($_) };

declare 'RepeatedFlag',
    as ArrayRef[Flag()];

coerce 'RepeatedFlag',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Flag'->new($_) } @$_ ] };

declare 'MapStringFlag',
    as HashRef[Flag()];

declare 'FlagsListResponse',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::FlagsListResponse'];

coerce 'FlagsListResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::FlagsListResponse'->new($_) };

declare 'RepeatedFlagsListResponse',
    as ArrayRef[FlagsListResponse()];

coerce 'RepeatedFlagsListResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::FlagsListResponse'->new($_) } @$_ ] };

declare 'MapStringFlagsListResponse',
    as HashRef[FlagsListResponse()];

declare 'ImportContext',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::ImportContext'];

coerce 'ImportContext',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ImportContext'->new($_) };

declare 'RepeatedImportContext',
    as ArrayRef[ImportContext()];

coerce 'RepeatedImportContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ImportContext'->new($_) } @$_ ] };

declare 'MapStringImportContext',
    as HashRef[ImportContext()];

declare 'SqlImportOptions',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::ImportContext::SqlImportOptions'];

coerce 'SqlImportOptions',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ImportContext::SqlImportOptions'->new($_) };

declare 'RepeatedSqlImportOptions',
    as ArrayRef[SqlImportOptions()];

coerce 'RepeatedSqlImportOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ImportContext::SqlImportOptions'->new($_) } @$_ ] };

declare 'MapStringSqlImportOptions',
    as HashRef[SqlImportOptions()];

declare 'PostgresImportOptions',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::ImportContext::SqlImportOptions::PostgresImportOptions'];

coerce 'PostgresImportOptions',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ImportContext::SqlImportOptions::PostgresImportOptions'->new($_) };

declare 'RepeatedPostgresImportOptions',
    as ArrayRef[PostgresImportOptions()];

coerce 'RepeatedPostgresImportOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ImportContext::SqlImportOptions::PostgresImportOptions'->new($_) } @$_ ] };

declare 'MapStringPostgresImportOptions',
    as HashRef[PostgresImportOptions()];

declare 'SqlCsvImportOptions',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::ImportContext::SqlCsvImportOptions'];

coerce 'SqlCsvImportOptions',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ImportContext::SqlCsvImportOptions'->new($_) };

declare 'RepeatedSqlCsvImportOptions',
    as ArrayRef[SqlCsvImportOptions()];

coerce 'RepeatedSqlCsvImportOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ImportContext::SqlCsvImportOptions'->new($_) } @$_ ] };

declare 'MapStringSqlCsvImportOptions',
    as HashRef[SqlCsvImportOptions()];

declare 'SqlBakImportOptions',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::ImportContext::SqlBakImportOptions'];

coerce 'SqlBakImportOptions',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ImportContext::SqlBakImportOptions'->new($_) };

declare 'RepeatedSqlBakImportOptions',
    as ArrayRef[SqlBakImportOptions()];

coerce 'RepeatedSqlBakImportOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ImportContext::SqlBakImportOptions'->new($_) } @$_ ] };

declare 'MapStringSqlBakImportOptions',
    as HashRef[SqlBakImportOptions()];

declare 'EncryptionOptions',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::ImportContext::SqlBakImportOptions::EncryptionOptions'];

coerce 'EncryptionOptions',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ImportContext::SqlBakImportOptions::EncryptionOptions'->new($_) };

declare 'RepeatedEncryptionOptions',
    as ArrayRef[EncryptionOptions()];

coerce 'RepeatedEncryptionOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ImportContext::SqlBakImportOptions::EncryptionOptions'->new($_) } @$_ ] };

declare 'MapStringEncryptionOptions',
    as HashRef[EncryptionOptions()];

declare 'SqlTdeImportOptions',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::ImportContext::SqlTdeImportOptions'];

coerce 'SqlTdeImportOptions',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ImportContext::SqlTdeImportOptions'->new($_) };

declare 'RepeatedSqlTdeImportOptions',
    as ArrayRef[SqlTdeImportOptions()];

coerce 'RepeatedSqlTdeImportOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ImportContext::SqlTdeImportOptions'->new($_) } @$_ ] };

declare 'MapStringSqlTdeImportOptions',
    as HashRef[SqlTdeImportOptions()];

declare 'InstancesCloneRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesCloneRequest'];

coerce 'InstancesCloneRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesCloneRequest'->new($_) };

declare 'RepeatedInstancesCloneRequest',
    as ArrayRef[InstancesCloneRequest()];

coerce 'RepeatedInstancesCloneRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesCloneRequest'->new($_) } @$_ ] };

declare 'MapStringInstancesCloneRequest',
    as HashRef[InstancesCloneRequest()];

declare 'InstancesDemoteMasterRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesDemoteMasterRequest'];

coerce 'InstancesDemoteMasterRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesDemoteMasterRequest'->new($_) };

declare 'RepeatedInstancesDemoteMasterRequest',
    as ArrayRef[InstancesDemoteMasterRequest()];

coerce 'RepeatedInstancesDemoteMasterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesDemoteMasterRequest'->new($_) } @$_ ] };

declare 'MapStringInstancesDemoteMasterRequest',
    as HashRef[InstancesDemoteMasterRequest()];

declare 'InstancesDemoteRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesDemoteRequest'];

coerce 'InstancesDemoteRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesDemoteRequest'->new($_) };

declare 'RepeatedInstancesDemoteRequest',
    as ArrayRef[InstancesDemoteRequest()];

coerce 'RepeatedInstancesDemoteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesDemoteRequest'->new($_) } @$_ ] };

declare 'MapStringInstancesDemoteRequest',
    as HashRef[InstancesDemoteRequest()];

declare 'InstancesExportRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesExportRequest'];

coerce 'InstancesExportRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesExportRequest'->new($_) };

declare 'RepeatedInstancesExportRequest',
    as ArrayRef[InstancesExportRequest()];

coerce 'RepeatedInstancesExportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesExportRequest'->new($_) } @$_ ] };

declare 'MapStringInstancesExportRequest',
    as HashRef[InstancesExportRequest()];

declare 'InstancesFailoverRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesFailoverRequest'];

coerce 'InstancesFailoverRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesFailoverRequest'->new($_) };

declare 'RepeatedInstancesFailoverRequest',
    as ArrayRef[InstancesFailoverRequest()];

coerce 'RepeatedInstancesFailoverRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesFailoverRequest'->new($_) } @$_ ] };

declare 'MapStringInstancesFailoverRequest',
    as HashRef[InstancesFailoverRequest()];

declare 'InstancesImportRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesImportRequest'];

coerce 'InstancesImportRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesImportRequest'->new($_) };

declare 'RepeatedInstancesImportRequest',
    as ArrayRef[InstancesImportRequest()];

coerce 'RepeatedInstancesImportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesImportRequest'->new($_) } @$_ ] };

declare 'MapStringInstancesImportRequest',
    as HashRef[InstancesImportRequest()];

declare 'InstancesPreCheckMajorVersionUpgradeRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesPreCheckMajorVersionUpgradeRequest'];

coerce 'InstancesPreCheckMajorVersionUpgradeRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesPreCheckMajorVersionUpgradeRequest'->new($_) };

declare 'RepeatedInstancesPreCheckMajorVersionUpgradeRequest',
    as ArrayRef[InstancesPreCheckMajorVersionUpgradeRequest()];

coerce 'RepeatedInstancesPreCheckMajorVersionUpgradeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesPreCheckMajorVersionUpgradeRequest'->new($_) } @$_ ] };

declare 'MapStringInstancesPreCheckMajorVersionUpgradeRequest',
    as HashRef[InstancesPreCheckMajorVersionUpgradeRequest()];

declare 'MySqlSyncConfig',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::MySqlSyncConfig'];

coerce 'MySqlSyncConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::MySqlSyncConfig'->new($_) };

declare 'RepeatedMySqlSyncConfig',
    as ArrayRef[MySqlSyncConfig()];

coerce 'RepeatedMySqlSyncConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::MySqlSyncConfig'->new($_) } @$_ ] };

declare 'MapStringMySqlSyncConfig',
    as HashRef[MySqlSyncConfig()];

declare 'InstancesListResponse',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesListResponse'];

coerce 'InstancesListResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesListResponse'->new($_) };

declare 'RepeatedInstancesListResponse',
    as ArrayRef[InstancesListResponse()];

coerce 'RepeatedInstancesListResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesListResponse'->new($_) } @$_ ] };

declare 'MapStringInstancesListResponse',
    as HashRef[InstancesListResponse()];

declare 'InstancesListServerCasResponse',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesListServerCasResponse'];

coerce 'InstancesListServerCasResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesListServerCasResponse'->new($_) };

declare 'RepeatedInstancesListServerCasResponse',
    as ArrayRef[InstancesListServerCasResponse()];

coerce 'RepeatedInstancesListServerCasResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesListServerCasResponse'->new($_) } @$_ ] };

declare 'MapStringInstancesListServerCasResponse',
    as HashRef[InstancesListServerCasResponse()];

declare 'InstancesListServerCertificatesResponse',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesListServerCertificatesResponse'];

coerce 'InstancesListServerCertificatesResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesListServerCertificatesResponse'->new($_) };

declare 'RepeatedInstancesListServerCertificatesResponse',
    as ArrayRef[InstancesListServerCertificatesResponse()];

coerce 'RepeatedInstancesListServerCertificatesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesListServerCertificatesResponse'->new($_) } @$_ ] };

declare 'MapStringInstancesListServerCertificatesResponse',
    as HashRef[InstancesListServerCertificatesResponse()];

declare 'InstancesListEntraIdCertificatesResponse',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesListEntraIdCertificatesResponse'];

coerce 'InstancesListEntraIdCertificatesResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesListEntraIdCertificatesResponse'->new($_) };

declare 'RepeatedInstancesListEntraIdCertificatesResponse',
    as ArrayRef[InstancesListEntraIdCertificatesResponse()];

coerce 'RepeatedInstancesListEntraIdCertificatesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesListEntraIdCertificatesResponse'->new($_) } @$_ ] };

declare 'MapStringInstancesListEntraIdCertificatesResponse',
    as HashRef[InstancesListEntraIdCertificatesResponse()];

declare 'InstancesRestoreBackupRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesRestoreBackupRequest'];

coerce 'InstancesRestoreBackupRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesRestoreBackupRequest'->new($_) };

declare 'RepeatedInstancesRestoreBackupRequest',
    as ArrayRef[InstancesRestoreBackupRequest()];

coerce 'RepeatedInstancesRestoreBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesRestoreBackupRequest'->new($_) } @$_ ] };

declare 'MapStringInstancesRestoreBackupRequest',
    as HashRef[InstancesRestoreBackupRequest()];

declare 'InstancesRotateServerCaRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesRotateServerCaRequest'];

coerce 'InstancesRotateServerCaRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesRotateServerCaRequest'->new($_) };

declare 'RepeatedInstancesRotateServerCaRequest',
    as ArrayRef[InstancesRotateServerCaRequest()];

coerce 'RepeatedInstancesRotateServerCaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesRotateServerCaRequest'->new($_) } @$_ ] };

declare 'MapStringInstancesRotateServerCaRequest',
    as HashRef[InstancesRotateServerCaRequest()];

declare 'InstancesRotateServerCertificateRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesRotateServerCertificateRequest'];

coerce 'InstancesRotateServerCertificateRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesRotateServerCertificateRequest'->new($_) };

declare 'RepeatedInstancesRotateServerCertificateRequest',
    as ArrayRef[InstancesRotateServerCertificateRequest()];

coerce 'RepeatedInstancesRotateServerCertificateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesRotateServerCertificateRequest'->new($_) } @$_ ] };

declare 'MapStringInstancesRotateServerCertificateRequest',
    as HashRef[InstancesRotateServerCertificateRequest()];

declare 'InstancesRotateEntraIdCertificateRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesRotateEntraIdCertificateRequest'];

coerce 'InstancesRotateEntraIdCertificateRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesRotateEntraIdCertificateRequest'->new($_) };

declare 'RepeatedInstancesRotateEntraIdCertificateRequest',
    as ArrayRef[InstancesRotateEntraIdCertificateRequest()];

coerce 'RepeatedInstancesRotateEntraIdCertificateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesRotateEntraIdCertificateRequest'->new($_) } @$_ ] };

declare 'MapStringInstancesRotateEntraIdCertificateRequest',
    as HashRef[InstancesRotateEntraIdCertificateRequest()];

declare 'InstancesTruncateLogRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesTruncateLogRequest'];

coerce 'InstancesTruncateLogRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesTruncateLogRequest'->new($_) };

declare 'RepeatedInstancesTruncateLogRequest',
    as ArrayRef[InstancesTruncateLogRequest()];

coerce 'RepeatedInstancesTruncateLogRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesTruncateLogRequest'->new($_) } @$_ ] };

declare 'MapStringInstancesTruncateLogRequest',
    as HashRef[InstancesTruncateLogRequest()];

declare 'InstancesAcquireSsrsLeaseRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesAcquireSsrsLeaseRequest'];

coerce 'InstancesAcquireSsrsLeaseRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesAcquireSsrsLeaseRequest'->new($_) };

declare 'RepeatedInstancesAcquireSsrsLeaseRequest',
    as ArrayRef[InstancesAcquireSsrsLeaseRequest()];

coerce 'RepeatedInstancesAcquireSsrsLeaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesAcquireSsrsLeaseRequest'->new($_) } @$_ ] };

declare 'MapStringInstancesAcquireSsrsLeaseRequest',
    as HashRef[InstancesAcquireSsrsLeaseRequest()];

declare 'PointInTimeRestoreContext',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::PointInTimeRestoreContext'];

coerce 'PointInTimeRestoreContext',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::PointInTimeRestoreContext'->new($_) };

declare 'RepeatedPointInTimeRestoreContext',
    as ArrayRef[PointInTimeRestoreContext()];

coerce 'RepeatedPointInTimeRestoreContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::PointInTimeRestoreContext'->new($_) } @$_ ] };

declare 'MapStringPointInTimeRestoreContext',
    as HashRef[PointInTimeRestoreContext()];

declare 'PerformDiskShrinkContext',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::PerformDiskShrinkContext'];

coerce 'PerformDiskShrinkContext',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::PerformDiskShrinkContext'->new($_) };

declare 'RepeatedPerformDiskShrinkContext',
    as ArrayRef[PerformDiskShrinkContext()];

coerce 'RepeatedPerformDiskShrinkContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::PerformDiskShrinkContext'->new($_) } @$_ ] };

declare 'MapStringPerformDiskShrinkContext',
    as HashRef[PerformDiskShrinkContext()];

declare 'PreCheckResponse',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::PreCheckResponse'];

coerce 'PreCheckResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::PreCheckResponse'->new($_) };

declare 'RepeatedPreCheckResponse',
    as ArrayRef[PreCheckResponse()];

coerce 'RepeatedPreCheckResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::PreCheckResponse'->new($_) } @$_ ] };

declare 'MapStringPreCheckResponse',
    as HashRef[PreCheckResponse()];

declare 'MessageType',
    as (Int | Str);

declare 'PreCheckMajorVersionUpgradeContext',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::PreCheckMajorVersionUpgradeContext'];

coerce 'PreCheckMajorVersionUpgradeContext',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::PreCheckMajorVersionUpgradeContext'->new($_) };

declare 'RepeatedPreCheckMajorVersionUpgradeContext',
    as ArrayRef[PreCheckMajorVersionUpgradeContext()];

coerce 'RepeatedPreCheckMajorVersionUpgradeContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::PreCheckMajorVersionUpgradeContext'->new($_) } @$_ ] };

declare 'MapStringPreCheckMajorVersionUpgradeContext',
    as HashRef[PreCheckMajorVersionUpgradeContext()];

declare 'SqlInstancesGetDiskShrinkConfigResponse',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlInstancesGetDiskShrinkConfigResponse'];

coerce 'SqlInstancesGetDiskShrinkConfigResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlInstancesGetDiskShrinkConfigResponse'->new($_) };

declare 'RepeatedSqlInstancesGetDiskShrinkConfigResponse',
    as ArrayRef[SqlInstancesGetDiskShrinkConfigResponse()];

coerce 'RepeatedSqlInstancesGetDiskShrinkConfigResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlInstancesGetDiskShrinkConfigResponse'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesGetDiskShrinkConfigResponse',
    as HashRef[SqlInstancesGetDiskShrinkConfigResponse()];

declare 'SqlInstancesVerifyExternalSyncSettingsResponse',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlInstancesVerifyExternalSyncSettingsResponse'];

coerce 'SqlInstancesVerifyExternalSyncSettingsResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlInstancesVerifyExternalSyncSettingsResponse'->new($_) };

declare 'RepeatedSqlInstancesVerifyExternalSyncSettingsResponse',
    as ArrayRef[SqlInstancesVerifyExternalSyncSettingsResponse()];

coerce 'RepeatedSqlInstancesVerifyExternalSyncSettingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlInstancesVerifyExternalSyncSettingsResponse'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesVerifyExternalSyncSettingsResponse',
    as HashRef[SqlInstancesVerifyExternalSyncSettingsResponse()];

declare 'SqlExternalSyncSettingError',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlExternalSyncSettingError'];

coerce 'SqlExternalSyncSettingError',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlExternalSyncSettingError'->new($_) };

declare 'RepeatedSqlExternalSyncSettingError',
    as ArrayRef[SqlExternalSyncSettingError()];

coerce 'RepeatedSqlExternalSyncSettingError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlExternalSyncSettingError'->new($_) } @$_ ] };

declare 'MapStringSqlExternalSyncSettingError',
    as HashRef[SqlExternalSyncSettingError()];

declare 'SqlExternalSyncSettingErrorType',
    as (Int | Str);

declare 'IpConfiguration',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::IpConfiguration'];

coerce 'IpConfiguration',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::IpConfiguration'->new($_) };

declare 'RepeatedIpConfiguration',
    as ArrayRef[IpConfiguration()];

coerce 'RepeatedIpConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::IpConfiguration'->new($_) } @$_ ] };

declare 'MapStringIpConfiguration',
    as HashRef[IpConfiguration()];

declare 'SslMode',
    as (Int | Str);

declare 'CaMode',
    as (Int | Str);

declare 'ServerCertificateRotationMode',
    as (Int | Str);

declare 'PscConfig',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::PscConfig'];

coerce 'PscConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::PscConfig'->new($_) };

declare 'RepeatedPscConfig',
    as ArrayRef[PscConfig()];

coerce 'RepeatedPscConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::PscConfig'->new($_) } @$_ ] };

declare 'MapStringPscConfig',
    as HashRef[PscConfig()];

declare 'PscAutoConnectionConfig',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::PscAutoConnectionConfig'];

coerce 'PscAutoConnectionConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::PscAutoConnectionConfig'->new($_) };

declare 'RepeatedPscAutoConnectionConfig',
    as ArrayRef[PscAutoConnectionConfig()];

coerce 'RepeatedPscAutoConnectionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::PscAutoConnectionConfig'->new($_) } @$_ ] };

declare 'MapStringPscAutoConnectionConfig',
    as HashRef[PscAutoConnectionConfig()];

declare 'IpMapping',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::IpMapping'];

coerce 'IpMapping',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::IpMapping'->new($_) };

declare 'RepeatedIpMapping',
    as ArrayRef[IpMapping()];

coerce 'RepeatedIpMapping',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::IpMapping'->new($_) } @$_ ] };

declare 'MapStringIpMapping',
    as HashRef[IpMapping()];

declare 'LocationPreference',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::LocationPreference'];

coerce 'LocationPreference',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::LocationPreference'->new($_) };

declare 'RepeatedLocationPreference',
    as ArrayRef[LocationPreference()];

coerce 'RepeatedLocationPreference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::LocationPreference'->new($_) } @$_ ] };

declare 'MapStringLocationPreference',
    as HashRef[LocationPreference()];

declare 'MaintenanceWindow',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::MaintenanceWindow'];

coerce 'MaintenanceWindow',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::MaintenanceWindow'->new($_) };

declare 'RepeatedMaintenanceWindow',
    as ArrayRef[MaintenanceWindow()];

coerce 'RepeatedMaintenanceWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::MaintenanceWindow'->new($_) } @$_ ] };

declare 'MapStringMaintenanceWindow',
    as HashRef[MaintenanceWindow()];

declare 'DenyMaintenancePeriod',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::DenyMaintenancePeriod'];

coerce 'DenyMaintenancePeriod',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DenyMaintenancePeriod'->new($_) };

declare 'RepeatedDenyMaintenancePeriod',
    as ArrayRef[DenyMaintenancePeriod()];

coerce 'RepeatedDenyMaintenancePeriod',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DenyMaintenancePeriod'->new($_) } @$_ ] };

declare 'MapStringDenyMaintenancePeriod',
    as HashRef[DenyMaintenancePeriod()];

declare 'InsightsConfig',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::InsightsConfig'];

coerce 'InsightsConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InsightsConfig'->new($_) };

declare 'RepeatedInsightsConfig',
    as ArrayRef[InsightsConfig()];

coerce 'RepeatedInsightsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InsightsConfig'->new($_) } @$_ ] };

declare 'MapStringInsightsConfig',
    as HashRef[InsightsConfig()];

declare 'MySqlReplicaConfiguration',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::MySqlReplicaConfiguration'];

coerce 'MySqlReplicaConfiguration',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::MySqlReplicaConfiguration'->new($_) };

declare 'RepeatedMySqlReplicaConfiguration',
    as ArrayRef[MySqlReplicaConfiguration()];

coerce 'RepeatedMySqlReplicaConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::MySqlReplicaConfiguration'->new($_) } @$_ ] };

declare 'MapStringMySqlReplicaConfiguration',
    as HashRef[MySqlReplicaConfiguration()];

declare 'SelectedObjects',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::SelectedObjects'];

coerce 'SelectedObjects',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SelectedObjects'->new($_) };

declare 'RepeatedSelectedObjects',
    as ArrayRef[SelectedObjects()];

coerce 'RepeatedSelectedObjects',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SelectedObjects'->new($_) } @$_ ] };

declare 'MapStringSelectedObjects',
    as HashRef[SelectedObjects()];

declare 'OnPremisesConfiguration',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::OnPremisesConfiguration'];

coerce 'OnPremisesConfiguration',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::OnPremisesConfiguration'->new($_) };

declare 'RepeatedOnPremisesConfiguration',
    as ArrayRef[OnPremisesConfiguration()];

coerce 'RepeatedOnPremisesConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::OnPremisesConfiguration'->new($_) } @$_ ] };

declare 'MapStringOnPremisesConfiguration',
    as HashRef[OnPremisesConfiguration()];

declare 'SslOption',
    as (Int | Str);

declare 'DiskEncryptionConfiguration',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::DiskEncryptionConfiguration'];

coerce 'DiskEncryptionConfiguration',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DiskEncryptionConfiguration'->new($_) };

declare 'RepeatedDiskEncryptionConfiguration',
    as ArrayRef[DiskEncryptionConfiguration()];

coerce 'RepeatedDiskEncryptionConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DiskEncryptionConfiguration'->new($_) } @$_ ] };

declare 'MapStringDiskEncryptionConfiguration',
    as HashRef[DiskEncryptionConfiguration()];

declare 'DiskEncryptionStatus',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::DiskEncryptionStatus'];

coerce 'DiskEncryptionStatus',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DiskEncryptionStatus'->new($_) };

declare 'RepeatedDiskEncryptionStatus',
    as ArrayRef[DiskEncryptionStatus()];

coerce 'RepeatedDiskEncryptionStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DiskEncryptionStatus'->new($_) } @$_ ] };

declare 'MapStringDiskEncryptionStatus',
    as HashRef[DiskEncryptionStatus()];

declare 'SqlSubOperationType',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlSubOperationType'];

coerce 'SqlSubOperationType',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlSubOperationType'->new($_) };

declare 'RepeatedSqlSubOperationType',
    as ArrayRef[SqlSubOperationType()];

coerce 'RepeatedSqlSubOperationType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlSubOperationType'->new($_) } @$_ ] };

declare 'MapStringSqlSubOperationType',
    as HashRef[SqlSubOperationType()];

declare 'Operation',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation'];

coerce 'Operation',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation'->new($_) };

declare 'RepeatedOperation',
    as ArrayRef[Operation()];

coerce 'RepeatedOperation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation'->new($_) } @$_ ] };

declare 'MapStringOperation',
    as HashRef[Operation()];

declare 'SqlOperationType',
    as (Int | Str);

declare 'SqlOperationStatus',
    as (Int | Str);

declare 'OperationError',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::OperationError'];

coerce 'OperationError',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::OperationError'->new($_) };

declare 'RepeatedOperationError',
    as ArrayRef[OperationError()];

coerce 'RepeatedOperationError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::OperationError'->new($_) } @$_ ] };

declare 'MapStringOperationError',
    as HashRef[OperationError()];

declare 'OperationErrors',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::OperationErrors'];

coerce 'OperationErrors',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::OperationErrors'->new($_) };

declare 'RepeatedOperationErrors',
    as ArrayRef[OperationErrors()];

coerce 'RepeatedOperationErrors',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::OperationErrors'->new($_) } @$_ ] };

declare 'MapStringOperationErrors',
    as HashRef[OperationErrors()];

declare 'PasswordValidationPolicy',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::PasswordValidationPolicy'];

coerce 'PasswordValidationPolicy',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::PasswordValidationPolicy'->new($_) };

declare 'RepeatedPasswordValidationPolicy',
    as ArrayRef[PasswordValidationPolicy()];

coerce 'RepeatedPasswordValidationPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::PasswordValidationPolicy'->new($_) } @$_ ] };

declare 'MapStringPasswordValidationPolicy',
    as HashRef[PasswordValidationPolicy()];

declare 'Complexity',
    as (Int | Str);

declare 'OperationsListResponse',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::OperationsListResponse'];

coerce 'OperationsListResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::OperationsListResponse'->new($_) };

declare 'RepeatedOperationsListResponse',
    as ArrayRef[OperationsListResponse()];

coerce 'RepeatedOperationsListResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::OperationsListResponse'->new($_) } @$_ ] };

declare 'MapStringOperationsListResponse',
    as HashRef[OperationsListResponse()];

declare 'ReplicaConfiguration',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::ReplicaConfiguration'];

coerce 'ReplicaConfiguration',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ReplicaConfiguration'->new($_) };

declare 'RepeatedReplicaConfiguration',
    as ArrayRef[ReplicaConfiguration()];

coerce 'RepeatedReplicaConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ReplicaConfiguration'->new($_) } @$_ ] };

declare 'MapStringReplicaConfiguration',
    as HashRef[ReplicaConfiguration()];

declare 'RestoreBackupContext',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::RestoreBackupContext'];

coerce 'RestoreBackupContext',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::RestoreBackupContext'->new($_) };

declare 'RepeatedRestoreBackupContext',
    as ArrayRef[RestoreBackupContext()];

coerce 'RepeatedRestoreBackupContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::RestoreBackupContext'->new($_) } @$_ ] };

declare 'MapStringRestoreBackupContext',
    as HashRef[RestoreBackupContext()];

declare 'RotateServerCaContext',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::RotateServerCaContext'];

coerce 'RotateServerCaContext',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::RotateServerCaContext'->new($_) };

declare 'RepeatedRotateServerCaContext',
    as ArrayRef[RotateServerCaContext()];

coerce 'RepeatedRotateServerCaContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::RotateServerCaContext'->new($_) } @$_ ] };

declare 'MapStringRotateServerCaContext',
    as HashRef[RotateServerCaContext()];

declare 'RotateServerCertificateContext',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::RotateServerCertificateContext'];

coerce 'RotateServerCertificateContext',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::RotateServerCertificateContext'->new($_) };

declare 'RepeatedRotateServerCertificateContext',
    as ArrayRef[RotateServerCertificateContext()];

coerce 'RepeatedRotateServerCertificateContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::RotateServerCertificateContext'->new($_) } @$_ ] };

declare 'MapStringRotateServerCertificateContext',
    as HashRef[RotateServerCertificateContext()];

declare 'RotateEntraIdCertificateContext',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::RotateEntraIdCertificateContext'];

coerce 'RotateEntraIdCertificateContext',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::RotateEntraIdCertificateContext'->new($_) };

declare 'RepeatedRotateEntraIdCertificateContext',
    as ArrayRef[RotateEntraIdCertificateContext()];

coerce 'RepeatedRotateEntraIdCertificateContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::RotateEntraIdCertificateContext'->new($_) } @$_ ] };

declare 'MapStringRotateEntraIdCertificateContext',
    as HashRef[RotateEntraIdCertificateContext()];

declare 'DataCacheConfig',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::DataCacheConfig'];

coerce 'DataCacheConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DataCacheConfig'->new($_) };

declare 'RepeatedDataCacheConfig',
    as ArrayRef[DataCacheConfig()];

coerce 'RepeatedDataCacheConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DataCacheConfig'->new($_) } @$_ ] };

declare 'MapStringDataCacheConfig',
    as HashRef[DataCacheConfig()];

declare 'FinalBackupConfig',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::FinalBackupConfig'];

coerce 'FinalBackupConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::FinalBackupConfig'->new($_) };

declare 'RepeatedFinalBackupConfig',
    as ArrayRef[FinalBackupConfig()];

coerce 'RepeatedFinalBackupConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::FinalBackupConfig'->new($_) } @$_ ] };

declare 'MapStringFinalBackupConfig',
    as HashRef[FinalBackupConfig()];

declare 'Settings',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::Settings'];

coerce 'Settings',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Settings'->new($_) };

declare 'RepeatedSettings',
    as ArrayRef[Settings()];

coerce 'RepeatedSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Settings'->new($_) } @$_ ] };

declare 'MapStringSettings',
    as HashRef[Settings()];

declare 'SqlActivationPolicy',
    as (Int | Str);

declare 'MsdtcRpcAuthMode',
    as (Int | Str);

declare 'Edition',
    as (Int | Str);

declare 'ConnectorEnforcement',
    as (Int | Str);

declare 'DataApiAccess',
    as (Int | Str);

declare 'UserLabelsEntry',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::Settings::UserLabelsEntry'];

coerce 'UserLabelsEntry',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Settings::UserLabelsEntry'->new($_) };

declare 'RepeatedUserLabelsEntry',
    as ArrayRef[UserLabelsEntry()];

coerce 'RepeatedUserLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Settings::UserLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringUserLabelsEntry',
    as HashRef[UserLabelsEntry()];

declare 'PerformanceCaptureConfig',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::PerformanceCaptureConfig'];

coerce 'PerformanceCaptureConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::PerformanceCaptureConfig'->new($_) };

declare 'RepeatedPerformanceCaptureConfig',
    as ArrayRef[PerformanceCaptureConfig()];

coerce 'RepeatedPerformanceCaptureConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::PerformanceCaptureConfig'->new($_) } @$_ ] };

declare 'MapStringPerformanceCaptureConfig',
    as HashRef[PerformanceCaptureConfig()];

declare 'TransactionKillType',
    as (Int | Str);

declare 'AdvancedMachineFeatures',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::AdvancedMachineFeatures'];

coerce 'AdvancedMachineFeatures',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::AdvancedMachineFeatures'->new($_) };

declare 'RepeatedAdvancedMachineFeatures',
    as ArrayRef[AdvancedMachineFeatures()];

coerce 'RepeatedAdvancedMachineFeatures',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::AdvancedMachineFeatures'->new($_) } @$_ ] };

declare 'MapStringAdvancedMachineFeatures',
    as HashRef[AdvancedMachineFeatures()];

declare 'SslCert',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::SslCert'];

coerce 'SslCert',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SslCert'->new($_) };

declare 'RepeatedSslCert',
    as ArrayRef[SslCert()];

coerce 'RepeatedSslCert',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SslCert'->new($_) } @$_ ] };

declare 'MapStringSslCert',
    as HashRef[SslCert()];

declare 'SslCertDetail',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::SslCertDetail'];

coerce 'SslCertDetail',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SslCertDetail'->new($_) };

declare 'RepeatedSslCertDetail',
    as ArrayRef[SslCertDetail()];

coerce 'RepeatedSslCertDetail',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SslCertDetail'->new($_) } @$_ ] };

declare 'MapStringSslCertDetail',
    as HashRef[SslCertDetail()];

declare 'DNSEntry',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::DNSEntry'];

coerce 'DNSEntry',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DNSEntry'->new($_) };

declare 'RepeatedDNSEntry',
    as ArrayRef[DNSEntry()];

coerce 'RepeatedDNSEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::DNSEntry'->new($_) } @$_ ] };

declare 'MapStringDNSEntry',
    as HashRef[DNSEntry()];

declare 'CustomerManagedCertificate',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::CustomerManagedCertificate'];

coerce 'CustomerManagedCertificate',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::CustomerManagedCertificate'->new($_) };

declare 'RepeatedCustomerManagedCertificate',
    as ArrayRef[CustomerManagedCertificate()];

coerce 'RepeatedCustomerManagedCertificate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::CustomerManagedCertificate'->new($_) } @$_ ] };

declare 'MapStringCustomerManagedCertificate',
    as HashRef[CustomerManagedCertificate()];

declare 'CustomerManagedCertificateConfig',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::CustomerManagedCertificateConfig'];

coerce 'CustomerManagedCertificateConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::CustomerManagedCertificateConfig'->new($_) };

declare 'RepeatedCustomerManagedCertificateConfig',
    as ArrayRef[CustomerManagedCertificateConfig()];

coerce 'RepeatedCustomerManagedCertificateConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::CustomerManagedCertificateConfig'->new($_) } @$_ ] };

declare 'MapStringCustomerManagedCertificateConfig',
    as HashRef[CustomerManagedCertificateConfig()];

declare 'SslCertsCreateEphemeralRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::SslCertsCreateEphemeralRequest'];

coerce 'SslCertsCreateEphemeralRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SslCertsCreateEphemeralRequest'->new($_) };

declare 'RepeatedSslCertsCreateEphemeralRequest',
    as ArrayRef[SslCertsCreateEphemeralRequest()];

coerce 'RepeatedSslCertsCreateEphemeralRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SslCertsCreateEphemeralRequest'->new($_) } @$_ ] };

declare 'MapStringSslCertsCreateEphemeralRequest',
    as HashRef[SslCertsCreateEphemeralRequest()];

declare 'SslCertsInsertRequest',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::SslCertsInsertRequest'];

coerce 'SslCertsInsertRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SslCertsInsertRequest'->new($_) };

declare 'RepeatedSslCertsInsertRequest',
    as ArrayRef[SslCertsInsertRequest()];

coerce 'RepeatedSslCertsInsertRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SslCertsInsertRequest'->new($_) } @$_ ] };

declare 'MapStringSslCertsInsertRequest',
    as HashRef[SslCertsInsertRequest()];

declare 'SqlInstancesRescheduleMaintenanceRequestBody',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlInstancesRescheduleMaintenanceRequestBody'];

coerce 'SqlInstancesRescheduleMaintenanceRequestBody',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlInstancesRescheduleMaintenanceRequestBody'->new($_) };

declare 'RepeatedSqlInstancesRescheduleMaintenanceRequestBody',
    as ArrayRef[SqlInstancesRescheduleMaintenanceRequestBody()];

coerce 'RepeatedSqlInstancesRescheduleMaintenanceRequestBody',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlInstancesRescheduleMaintenanceRequestBody'->new($_) } @$_ ] };

declare 'MapStringSqlInstancesRescheduleMaintenanceRequestBody',
    as HashRef[SqlInstancesRescheduleMaintenanceRequestBody()];

declare 'RescheduleType',
    as (Int | Str);

declare 'Reschedule',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlInstancesRescheduleMaintenanceRequestBody::Reschedule'];

coerce 'Reschedule',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlInstancesRescheduleMaintenanceRequestBody::Reschedule'->new($_) };

declare 'RepeatedReschedule',
    as ArrayRef[Reschedule()];

coerce 'RepeatedReschedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlInstancesRescheduleMaintenanceRequestBody::Reschedule'->new($_) } @$_ ] };

declare 'MapStringReschedule',
    as HashRef[Reschedule()];

declare 'SslCertsInsertResponse',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::SslCertsInsertResponse'];

coerce 'SslCertsInsertResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SslCertsInsertResponse'->new($_) };

declare 'RepeatedSslCertsInsertResponse',
    as ArrayRef[SslCertsInsertResponse()];

coerce 'RepeatedSslCertsInsertResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SslCertsInsertResponse'->new($_) } @$_ ] };

declare 'MapStringSslCertsInsertResponse',
    as HashRef[SslCertsInsertResponse()];

declare 'SslCertsListResponse',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::SslCertsListResponse'];

coerce 'SslCertsListResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SslCertsListResponse'->new($_) };

declare 'RepeatedSslCertsListResponse',
    as ArrayRef[SslCertsListResponse()];

coerce 'RepeatedSslCertsListResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SslCertsListResponse'->new($_) } @$_ ] };

declare 'MapStringSslCertsListResponse',
    as HashRef[SslCertsListResponse()];

declare 'TruncateLogContext',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::TruncateLogContext'];

coerce 'TruncateLogContext',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::TruncateLogContext'->new($_) };

declare 'RepeatedTruncateLogContext',
    as ArrayRef[TruncateLogContext()];

coerce 'RepeatedTruncateLogContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::TruncateLogContext'->new($_) } @$_ ] };

declare 'MapStringTruncateLogContext',
    as HashRef[TruncateLogContext()];

declare 'SqlActiveDirectoryConfig',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlActiveDirectoryConfig'];

coerce 'SqlActiveDirectoryConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlActiveDirectoryConfig'->new($_) };

declare 'RepeatedSqlActiveDirectoryConfig',
    as ArrayRef[SqlActiveDirectoryConfig()];

coerce 'RepeatedSqlActiveDirectoryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlActiveDirectoryConfig'->new($_) } @$_ ] };

declare 'MapStringSqlActiveDirectoryConfig',
    as HashRef[SqlActiveDirectoryConfig()];

declare 'ActiveDirectoryMode',
    as (Int | Str);

declare 'SqlServerAuditConfig',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlServerAuditConfig'];

coerce 'SqlServerAuditConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlServerAuditConfig'->new($_) };

declare 'RepeatedSqlServerAuditConfig',
    as ArrayRef[SqlServerAuditConfig()];

coerce 'RepeatedSqlServerAuditConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlServerAuditConfig'->new($_) } @$_ ] };

declare 'MapStringSqlServerAuditConfig',
    as HashRef[SqlServerAuditConfig()];

declare 'SqlServerEntraIdConfig',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlServerEntraIdConfig'];

coerce 'SqlServerEntraIdConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlServerEntraIdConfig'->new($_) };

declare 'RepeatedSqlServerEntraIdConfig',
    as ArrayRef[SqlServerEntraIdConfig()];

coerce 'RepeatedSqlServerEntraIdConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlServerEntraIdConfig'->new($_) } @$_ ] };

declare 'MapStringSqlServerEntraIdConfig',
    as HashRef[SqlServerEntraIdConfig()];

declare 'InitialUsersConfig',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::InitialUsersConfig'];

coerce 'InitialUsersConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InitialUsersConfig'->new($_) };

declare 'RepeatedInitialUsersConfig',
    as ArrayRef[InitialUsersConfig()];

coerce 'RepeatedInitialUsersConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InitialUsersConfig'->new($_) } @$_ ] };

declare 'MapStringInitialUsersConfig',
    as HashRef[InitialUsersConfig()];

declare 'InitialUser',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::InitialUsersConfig::InitialUser'];

coerce 'InitialUser',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InitialUsersConfig::InitialUser'->new($_) };

declare 'RepeatedInitialUser',
    as ArrayRef[InitialUser()];

coerce 'RepeatedInitialUser',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InitialUsersConfig::InitialUser'->new($_) } @$_ ] };

declare 'MapStringInitialUser',
    as HashRef[InitialUser()];

declare 'SqlUserType',
    as (Int | Str);

declare 'ConnectionPoolFlags',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::ConnectionPoolFlags'];

coerce 'ConnectionPoolFlags',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ConnectionPoolFlags'->new($_) };

declare 'RepeatedConnectionPoolFlags',
    as ArrayRef[ConnectionPoolFlags()];

coerce 'RepeatedConnectionPoolFlags',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ConnectionPoolFlags'->new($_) } @$_ ] };

declare 'MapStringConnectionPoolFlags',
    as HashRef[ConnectionPoolFlags()];

declare 'ReadPoolAutoScaleConfig',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::ReadPoolAutoScaleConfig'];

coerce 'ReadPoolAutoScaleConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ReadPoolAutoScaleConfig'->new($_) };

declare 'RepeatedReadPoolAutoScaleConfig',
    as ArrayRef[ReadPoolAutoScaleConfig()];

coerce 'RepeatedReadPoolAutoScaleConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ReadPoolAutoScaleConfig'->new($_) } @$_ ] };

declare 'MapStringReadPoolAutoScaleConfig',
    as HashRef[ReadPoolAutoScaleConfig()];

declare 'TargetMetric',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::ReadPoolAutoScaleConfig::TargetMetric'];

coerce 'TargetMetric',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ReadPoolAutoScaleConfig::TargetMetric'->new($_) };

declare 'RepeatedTargetMetric',
    as ArrayRef[TargetMetric()];

coerce 'RepeatedTargetMetric',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ReadPoolAutoScaleConfig::TargetMetric'->new($_) } @$_ ] };

declare 'MapStringTargetMetric',
    as HashRef[TargetMetric()];

declare 'ConnectionPoolConfig',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::ConnectionPoolConfig'];

coerce 'ConnectionPoolConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ConnectionPoolConfig'->new($_) };

declare 'RepeatedConnectionPoolConfig',
    as ArrayRef[ConnectionPoolConfig()];

coerce 'RepeatedConnectionPoolConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::ConnectionPoolConfig'->new($_) } @$_ ] };

declare 'MapStringConnectionPoolConfig',
    as HashRef[ConnectionPoolConfig()];

declare 'AcquireSsrsLeaseContext',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::AcquireSsrsLeaseContext'];

coerce 'AcquireSsrsLeaseContext',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::AcquireSsrsLeaseContext'->new($_) };

declare 'RepeatedAcquireSsrsLeaseContext',
    as ArrayRef[AcquireSsrsLeaseContext()];

coerce 'RepeatedAcquireSsrsLeaseContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::AcquireSsrsLeaseContext'->new($_) } @$_ ] };

declare 'MapStringAcquireSsrsLeaseContext',
    as HashRef[AcquireSsrsLeaseContext()];

declare 'StartWorkloadCaptureContext',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::StartWorkloadCaptureContext'];

coerce 'StartWorkloadCaptureContext',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::StartWorkloadCaptureContext'->new($_) };

declare 'RepeatedStartWorkloadCaptureContext',
    as ArrayRef[StartWorkloadCaptureContext()];

coerce 'RepeatedStartWorkloadCaptureContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::StartWorkloadCaptureContext'->new($_) } @$_ ] };

declare 'MapStringStartWorkloadCaptureContext',
    as HashRef[StartWorkloadCaptureContext()];

declare 'StopWorkloadCaptureContext',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::StopWorkloadCaptureContext'];

coerce 'StopWorkloadCaptureContext',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::StopWorkloadCaptureContext'->new($_) };

declare 'RepeatedStopWorkloadCaptureContext',
    as ArrayRef[StopWorkloadCaptureContext()];

coerce 'RepeatedStopWorkloadCaptureContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::StopWorkloadCaptureContext'->new($_) } @$_ ] };

declare 'MapStringStopWorkloadCaptureContext',
    as HashRef[StopWorkloadCaptureContext()];

declare 'StartWorkloadReplayContext',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::StartWorkloadReplayContext'];

coerce 'StartWorkloadReplayContext',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::StartWorkloadReplayContext'->new($_) };

declare 'RepeatedStartWorkloadReplayContext',
    as ArrayRef[StartWorkloadReplayContext()];

coerce 'RepeatedStartWorkloadReplayContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::StartWorkloadReplayContext'->new($_) } @$_ ] };

declare 'MapStringStartWorkloadReplayContext',
    as HashRef[StartWorkloadReplayContext()];

declare 'StopWorkloadReplayContext',
    as InstanceOf['Google::Cloud::Sql::V1beta4::CloudSqlResources::StopWorkloadReplayContext'];

coerce 'StopWorkloadReplayContext',
    from HashRef, via { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::StopWorkloadReplayContext'->new($_) };

declare 'RepeatedStopWorkloadReplayContext',
    as ArrayRef[StopWorkloadReplayContext()];

coerce 'RepeatedStopWorkloadReplayContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1beta4::CloudSqlResources::StopWorkloadReplayContext'->new($_) } @$_ ] };

declare 'MapStringStopWorkloadReplayContext',
    as HashRef[StopWorkloadReplayContext()];

1;

__END__

=head1 NAME

Google::Cloud::Sql::V1beta4::CloudSqlResources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
