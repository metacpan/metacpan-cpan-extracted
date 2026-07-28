package Google::Cloud::Sql::V1::CloudSqlResources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SqlFileType',
    as (Int | Str);

declare 'BakType',
    as (Int | Str);

declare 'SqlMaintenanceType',
    as (Int | Str);

declare 'SqlBackendType',
    as (Int | Str);

declare 'SqlIpAddressType',
    as (Int | Str);

declare 'SqlDatabaseVersion',
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

declare 'AutoDnsStatus',
    as (Int | Str);

declare 'AclEntry',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::AclEntry'];

coerce 'AclEntry',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::AclEntry'->new($_) };

declare 'RepeatedAclEntry',
    as ArrayRef[AclEntry()];

coerce 'RepeatedAclEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::AclEntry'->new($_) } @$_ ] };

declare 'MapStringAclEntry',
    as HashRef[AclEntry()];

declare 'ApiWarning',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::ApiWarning'];

coerce 'ApiWarning',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::ApiWarning'->new($_) };

declare 'RepeatedApiWarning',
    as ArrayRef[ApiWarning()];

coerce 'RepeatedApiWarning',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::ApiWarning'->new($_) } @$_ ] };

declare 'MapStringApiWarning',
    as HashRef[ApiWarning()];

declare 'SqlApiWarningCode',
    as (Int | Str);

declare 'BackupRetentionSettings',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::BackupRetentionSettings'];

coerce 'BackupRetentionSettings',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::BackupRetentionSettings'->new($_) };

declare 'RepeatedBackupRetentionSettings',
    as ArrayRef[BackupRetentionSettings()];

coerce 'RepeatedBackupRetentionSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::BackupRetentionSettings'->new($_) } @$_ ] };

declare 'MapStringBackupRetentionSettings',
    as HashRef[BackupRetentionSettings()];

declare 'RetentionUnit',
    as (Int | Str);

declare 'BackupConfiguration',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::BackupConfiguration'];

coerce 'BackupConfiguration',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::BackupConfiguration'->new($_) };

declare 'RepeatedBackupConfiguration',
    as ArrayRef[BackupConfiguration()];

coerce 'RepeatedBackupConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::BackupConfiguration'->new($_) } @$_ ] };

declare 'MapStringBackupConfiguration',
    as HashRef[BackupConfiguration()];

declare 'TransactionalLogStorageState',
    as (Int | Str);

declare 'BackupTier',
    as (Int | Str);

declare 'PerformDiskShrinkContext',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::PerformDiskShrinkContext'];

coerce 'PerformDiskShrinkContext',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::PerformDiskShrinkContext'->new($_) };

declare 'RepeatedPerformDiskShrinkContext',
    as ArrayRef[PerformDiskShrinkContext()];

coerce 'RepeatedPerformDiskShrinkContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::PerformDiskShrinkContext'->new($_) } @$_ ] };

declare 'MapStringPerformDiskShrinkContext',
    as HashRef[PerformDiskShrinkContext()];

declare 'PreCheckResponse',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::PreCheckResponse'];

coerce 'PreCheckResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::PreCheckResponse'->new($_) };

declare 'RepeatedPreCheckResponse',
    as ArrayRef[PreCheckResponse()];

coerce 'RepeatedPreCheckResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::PreCheckResponse'->new($_) } @$_ ] };

declare 'MapStringPreCheckResponse',
    as HashRef[PreCheckResponse()];

declare 'MessageType',
    as (Int | Str);

declare 'PreCheckMajorVersionUpgradeContext',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::PreCheckMajorVersionUpgradeContext'];

coerce 'PreCheckMajorVersionUpgradeContext',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::PreCheckMajorVersionUpgradeContext'->new($_) };

declare 'RepeatedPreCheckMajorVersionUpgradeContext',
    as ArrayRef[PreCheckMajorVersionUpgradeContext()];

coerce 'RepeatedPreCheckMajorVersionUpgradeContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::PreCheckMajorVersionUpgradeContext'->new($_) } @$_ ] };

declare 'MapStringPreCheckMajorVersionUpgradeContext',
    as HashRef[PreCheckMajorVersionUpgradeContext()];

declare 'BackupContext',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::BackupContext'];

coerce 'BackupContext',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::BackupContext'->new($_) };

declare 'RepeatedBackupContext',
    as ArrayRef[BackupContext()];

coerce 'RepeatedBackupContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::BackupContext'->new($_) } @$_ ] };

declare 'MapStringBackupContext',
    as HashRef[BackupContext()];

declare 'Database',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::Database'];

coerce 'Database',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::Database'->new($_) };

declare 'RepeatedDatabase',
    as ArrayRef[Database()];

coerce 'RepeatedDatabase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::Database'->new($_) } @$_ ] };

declare 'MapStringDatabase',
    as HashRef[Database()];

declare 'SqlServerDatabaseDetails',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::SqlServerDatabaseDetails'];

coerce 'SqlServerDatabaseDetails',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::SqlServerDatabaseDetails'->new($_) };

declare 'RepeatedSqlServerDatabaseDetails',
    as ArrayRef[SqlServerDatabaseDetails()];

coerce 'RepeatedSqlServerDatabaseDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::SqlServerDatabaseDetails'->new($_) } @$_ ] };

declare 'MapStringSqlServerDatabaseDetails',
    as HashRef[SqlServerDatabaseDetails()];

declare 'DatabaseFlags',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::DatabaseFlags'];

coerce 'DatabaseFlags',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::DatabaseFlags'->new($_) };

declare 'RepeatedDatabaseFlags',
    as ArrayRef[DatabaseFlags()];

coerce 'RepeatedDatabaseFlags',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::DatabaseFlags'->new($_) } @$_ ] };

declare 'MapStringDatabaseFlags',
    as HashRef[DatabaseFlags()];

declare 'MySqlSyncConfig',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::MySqlSyncConfig'];

coerce 'MySqlSyncConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::MySqlSyncConfig'->new($_) };

declare 'RepeatedMySqlSyncConfig',
    as ArrayRef[MySqlSyncConfig()];

coerce 'RepeatedMySqlSyncConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::MySqlSyncConfig'->new($_) } @$_ ] };

declare 'MapStringMySqlSyncConfig',
    as HashRef[MySqlSyncConfig()];

declare 'SyncFlags',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::SyncFlags'];

coerce 'SyncFlags',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::SyncFlags'->new($_) };

declare 'RepeatedSyncFlags',
    as ArrayRef[SyncFlags()];

coerce 'RepeatedSyncFlags',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::SyncFlags'->new($_) } @$_ ] };

declare 'MapStringSyncFlags',
    as HashRef[SyncFlags()];

declare 'InstanceReference',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::InstanceReference'];

coerce 'InstanceReference',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::InstanceReference'->new($_) };

declare 'RepeatedInstanceReference',
    as ArrayRef[InstanceReference()];

coerce 'RepeatedInstanceReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::InstanceReference'->new($_) } @$_ ] };

declare 'MapStringInstanceReference',
    as HashRef[InstanceReference()];

declare 'DemoteMasterConfiguration',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::DemoteMasterConfiguration'];

coerce 'DemoteMasterConfiguration',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::DemoteMasterConfiguration'->new($_) };

declare 'RepeatedDemoteMasterConfiguration',
    as ArrayRef[DemoteMasterConfiguration()];

coerce 'RepeatedDemoteMasterConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::DemoteMasterConfiguration'->new($_) } @$_ ] };

declare 'MapStringDemoteMasterConfiguration',
    as HashRef[DemoteMasterConfiguration()];

declare 'DemoteMasterMySqlReplicaConfiguration',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::DemoteMasterMySqlReplicaConfiguration'];

coerce 'DemoteMasterMySqlReplicaConfiguration',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::DemoteMasterMySqlReplicaConfiguration'->new($_) };

declare 'RepeatedDemoteMasterMySqlReplicaConfiguration',
    as ArrayRef[DemoteMasterMySqlReplicaConfiguration()];

coerce 'RepeatedDemoteMasterMySqlReplicaConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::DemoteMasterMySqlReplicaConfiguration'->new($_) } @$_ ] };

declare 'MapStringDemoteMasterMySqlReplicaConfiguration',
    as HashRef[DemoteMasterMySqlReplicaConfiguration()];

declare 'ExportContext',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::ExportContext'];

coerce 'ExportContext',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::ExportContext'->new($_) };

declare 'RepeatedExportContext',
    as ArrayRef[ExportContext()];

coerce 'RepeatedExportContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::ExportContext'->new($_) } @$_ ] };

declare 'MapStringExportContext',
    as HashRef[ExportContext()];

declare 'SqlCsvExportOptions',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::ExportContext::SqlCsvExportOptions'];

coerce 'SqlCsvExportOptions',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::ExportContext::SqlCsvExportOptions'->new($_) };

declare 'RepeatedSqlCsvExportOptions',
    as ArrayRef[SqlCsvExportOptions()];

coerce 'RepeatedSqlCsvExportOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::ExportContext::SqlCsvExportOptions'->new($_) } @$_ ] };

declare 'MapStringSqlCsvExportOptions',
    as HashRef[SqlCsvExportOptions()];

declare 'SqlExportOptions',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::ExportContext::SqlExportOptions'];

coerce 'SqlExportOptions',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::ExportContext::SqlExportOptions'->new($_) };

declare 'RepeatedSqlExportOptions',
    as ArrayRef[SqlExportOptions()];

coerce 'RepeatedSqlExportOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::ExportContext::SqlExportOptions'->new($_) } @$_ ] };

declare 'MapStringSqlExportOptions',
    as HashRef[SqlExportOptions()];

declare 'MysqlExportOptions',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::ExportContext::SqlExportOptions::MysqlExportOptions'];

coerce 'MysqlExportOptions',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::ExportContext::SqlExportOptions::MysqlExportOptions'->new($_) };

declare 'RepeatedMysqlExportOptions',
    as ArrayRef[MysqlExportOptions()];

coerce 'RepeatedMysqlExportOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::ExportContext::SqlExportOptions::MysqlExportOptions'->new($_) } @$_ ] };

declare 'MapStringMysqlExportOptions',
    as HashRef[MysqlExportOptions()];

declare 'PostgresExportOptions',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::ExportContext::SqlExportOptions::PostgresExportOptions'];

coerce 'PostgresExportOptions',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::ExportContext::SqlExportOptions::PostgresExportOptions'->new($_) };

declare 'RepeatedPostgresExportOptions',
    as ArrayRef[PostgresExportOptions()];

coerce 'RepeatedPostgresExportOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::ExportContext::SqlExportOptions::PostgresExportOptions'->new($_) } @$_ ] };

declare 'MapStringPostgresExportOptions',
    as HashRef[PostgresExportOptions()];

declare 'SqlBakExportOptions',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::ExportContext::SqlBakExportOptions'];

coerce 'SqlBakExportOptions',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::ExportContext::SqlBakExportOptions'->new($_) };

declare 'RepeatedSqlBakExportOptions',
    as ArrayRef[SqlBakExportOptions()];

coerce 'RepeatedSqlBakExportOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::ExportContext::SqlBakExportOptions'->new($_) } @$_ ] };

declare 'MapStringSqlBakExportOptions',
    as HashRef[SqlBakExportOptions()];

declare 'SqlTdeExportOptions',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::ExportContext::SqlTdeExportOptions'];

coerce 'SqlTdeExportOptions',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::ExportContext::SqlTdeExportOptions'->new($_) };

declare 'RepeatedSqlTdeExportOptions',
    as ArrayRef[SqlTdeExportOptions()];

coerce 'RepeatedSqlTdeExportOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::ExportContext::SqlTdeExportOptions'->new($_) } @$_ ] };

declare 'MapStringSqlTdeExportOptions',
    as HashRef[SqlTdeExportOptions()];

declare 'ImportContext',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::ImportContext'];

coerce 'ImportContext',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::ImportContext'->new($_) };

declare 'RepeatedImportContext',
    as ArrayRef[ImportContext()];

coerce 'RepeatedImportContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::ImportContext'->new($_) } @$_ ] };

declare 'MapStringImportContext',
    as HashRef[ImportContext()];

declare 'SqlImportOptions',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::ImportContext::SqlImportOptions'];

coerce 'SqlImportOptions',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::ImportContext::SqlImportOptions'->new($_) };

declare 'RepeatedSqlImportOptions',
    as ArrayRef[SqlImportOptions()];

coerce 'RepeatedSqlImportOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::ImportContext::SqlImportOptions'->new($_) } @$_ ] };

declare 'MapStringSqlImportOptions',
    as HashRef[SqlImportOptions()];

declare 'PostgresImportOptions',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::ImportContext::SqlImportOptions::PostgresImportOptions'];

coerce 'PostgresImportOptions',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::ImportContext::SqlImportOptions::PostgresImportOptions'->new($_) };

declare 'RepeatedPostgresImportOptions',
    as ArrayRef[PostgresImportOptions()];

coerce 'RepeatedPostgresImportOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::ImportContext::SqlImportOptions::PostgresImportOptions'->new($_) } @$_ ] };

declare 'MapStringPostgresImportOptions',
    as HashRef[PostgresImportOptions()];

declare 'SqlCsvImportOptions',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::ImportContext::SqlCsvImportOptions'];

coerce 'SqlCsvImportOptions',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::ImportContext::SqlCsvImportOptions'->new($_) };

declare 'RepeatedSqlCsvImportOptions',
    as ArrayRef[SqlCsvImportOptions()];

coerce 'RepeatedSqlCsvImportOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::ImportContext::SqlCsvImportOptions'->new($_) } @$_ ] };

declare 'MapStringSqlCsvImportOptions',
    as HashRef[SqlCsvImportOptions()];

declare 'SqlBakImportOptions',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::ImportContext::SqlBakImportOptions'];

coerce 'SqlBakImportOptions',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::ImportContext::SqlBakImportOptions'->new($_) };

declare 'RepeatedSqlBakImportOptions',
    as ArrayRef[SqlBakImportOptions()];

coerce 'RepeatedSqlBakImportOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::ImportContext::SqlBakImportOptions'->new($_) } @$_ ] };

declare 'MapStringSqlBakImportOptions',
    as HashRef[SqlBakImportOptions()];

declare 'EncryptionOptions',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::ImportContext::SqlBakImportOptions::EncryptionOptions'];

coerce 'EncryptionOptions',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::ImportContext::SqlBakImportOptions::EncryptionOptions'->new($_) };

declare 'RepeatedEncryptionOptions',
    as ArrayRef[EncryptionOptions()];

coerce 'RepeatedEncryptionOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::ImportContext::SqlBakImportOptions::EncryptionOptions'->new($_) } @$_ ] };

declare 'MapStringEncryptionOptions',
    as HashRef[EncryptionOptions()];

declare 'SqlTdeImportOptions',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::ImportContext::SqlTdeImportOptions'];

coerce 'SqlTdeImportOptions',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::ImportContext::SqlTdeImportOptions'->new($_) };

declare 'RepeatedSqlTdeImportOptions',
    as ArrayRef[SqlTdeImportOptions()];

coerce 'RepeatedSqlTdeImportOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::ImportContext::SqlTdeImportOptions'->new($_) } @$_ ] };

declare 'MapStringSqlTdeImportOptions',
    as HashRef[SqlTdeImportOptions()];

declare 'IpConfiguration',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::IpConfiguration'];

coerce 'IpConfiguration',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::IpConfiguration'->new($_) };

declare 'RepeatedIpConfiguration',
    as ArrayRef[IpConfiguration()];

coerce 'RepeatedIpConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::IpConfiguration'->new($_) } @$_ ] };

declare 'MapStringIpConfiguration',
    as HashRef[IpConfiguration()];

declare 'SslMode',
    as (Int | Str);

declare 'CaMode',
    as (Int | Str);

declare 'ServerCertificateRotationMode',
    as (Int | Str);

declare 'PscConfig',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::PscConfig'];

coerce 'PscConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::PscConfig'->new($_) };

declare 'RepeatedPscConfig',
    as ArrayRef[PscConfig()];

coerce 'RepeatedPscConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::PscConfig'->new($_) } @$_ ] };

declare 'MapStringPscConfig',
    as HashRef[PscConfig()];

declare 'PscAutoConnectionConfig',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::PscAutoConnectionConfig'];

coerce 'PscAutoConnectionConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::PscAutoConnectionConfig'->new($_) };

declare 'RepeatedPscAutoConnectionConfig',
    as ArrayRef[PscAutoConnectionConfig()];

coerce 'RepeatedPscAutoConnectionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::PscAutoConnectionConfig'->new($_) } @$_ ] };

declare 'MapStringPscAutoConnectionConfig',
    as HashRef[PscAutoConnectionConfig()];

declare 'LocationPreference',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::LocationPreference'];

coerce 'LocationPreference',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::LocationPreference'->new($_) };

declare 'RepeatedLocationPreference',
    as ArrayRef[LocationPreference()];

coerce 'RepeatedLocationPreference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::LocationPreference'->new($_) } @$_ ] };

declare 'MapStringLocationPreference',
    as HashRef[LocationPreference()];

declare 'MaintenanceWindow',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::MaintenanceWindow'];

coerce 'MaintenanceWindow',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::MaintenanceWindow'->new($_) };

declare 'RepeatedMaintenanceWindow',
    as ArrayRef[MaintenanceWindow()];

coerce 'RepeatedMaintenanceWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::MaintenanceWindow'->new($_) } @$_ ] };

declare 'MapStringMaintenanceWindow',
    as HashRef[MaintenanceWindow()];

declare 'DenyMaintenancePeriod',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::DenyMaintenancePeriod'];

coerce 'DenyMaintenancePeriod',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::DenyMaintenancePeriod'->new($_) };

declare 'RepeatedDenyMaintenancePeriod',
    as ArrayRef[DenyMaintenancePeriod()];

coerce 'RepeatedDenyMaintenancePeriod',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::DenyMaintenancePeriod'->new($_) } @$_ ] };

declare 'MapStringDenyMaintenancePeriod',
    as HashRef[DenyMaintenancePeriod()];

declare 'InsightsConfig',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::InsightsConfig'];

coerce 'InsightsConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::InsightsConfig'->new($_) };

declare 'RepeatedInsightsConfig',
    as ArrayRef[InsightsConfig()];

coerce 'RepeatedInsightsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::InsightsConfig'->new($_) } @$_ ] };

declare 'MapStringInsightsConfig',
    as HashRef[InsightsConfig()];

declare 'MySqlReplicaConfiguration',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::MySqlReplicaConfiguration'];

coerce 'MySqlReplicaConfiguration',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::MySqlReplicaConfiguration'->new($_) };

declare 'RepeatedMySqlReplicaConfiguration',
    as ArrayRef[MySqlReplicaConfiguration()];

coerce 'RepeatedMySqlReplicaConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::MySqlReplicaConfiguration'->new($_) } @$_ ] };

declare 'MapStringMySqlReplicaConfiguration',
    as HashRef[MySqlReplicaConfiguration()];

declare 'DiskEncryptionConfiguration',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::DiskEncryptionConfiguration'];

coerce 'DiskEncryptionConfiguration',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::DiskEncryptionConfiguration'->new($_) };

declare 'RepeatedDiskEncryptionConfiguration',
    as ArrayRef[DiskEncryptionConfiguration()];

coerce 'RepeatedDiskEncryptionConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::DiskEncryptionConfiguration'->new($_) } @$_ ] };

declare 'MapStringDiskEncryptionConfiguration',
    as HashRef[DiskEncryptionConfiguration()];

declare 'DiskEncryptionStatus',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::DiskEncryptionStatus'];

coerce 'DiskEncryptionStatus',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::DiskEncryptionStatus'->new($_) };

declare 'RepeatedDiskEncryptionStatus',
    as ArrayRef[DiskEncryptionStatus()];

coerce 'RepeatedDiskEncryptionStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::DiskEncryptionStatus'->new($_) } @$_ ] };

declare 'MapStringDiskEncryptionStatus',
    as HashRef[DiskEncryptionStatus()];

declare 'IpMapping',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::IpMapping'];

coerce 'IpMapping',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::IpMapping'->new($_) };

declare 'RepeatedIpMapping',
    as ArrayRef[IpMapping()];

coerce 'RepeatedIpMapping',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::IpMapping'->new($_) } @$_ ] };

declare 'MapStringIpMapping',
    as HashRef[IpMapping()];

declare 'SqlSubOperationType',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::SqlSubOperationType'];

coerce 'SqlSubOperationType',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::SqlSubOperationType'->new($_) };

declare 'RepeatedSqlSubOperationType',
    as ArrayRef[SqlSubOperationType()];

coerce 'RepeatedSqlSubOperationType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::SqlSubOperationType'->new($_) } @$_ ] };

declare 'MapStringSqlSubOperationType',
    as HashRef[SqlSubOperationType()];

declare 'Operation',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::Operation'];

coerce 'Operation',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::Operation'->new($_) };

declare 'RepeatedOperation',
    as ArrayRef[Operation()];

coerce 'RepeatedOperation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::Operation'->new($_) } @$_ ] };

declare 'MapStringOperation',
    as HashRef[Operation()];

declare 'SqlOperationType',
    as (Int | Str);

declare 'SqlOperationStatus',
    as (Int | Str);

declare 'OperationError',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::OperationError'];

coerce 'OperationError',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::OperationError'->new($_) };

declare 'RepeatedOperationError',
    as ArrayRef[OperationError()];

coerce 'RepeatedOperationError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::OperationError'->new($_) } @$_ ] };

declare 'MapStringOperationError',
    as HashRef[OperationError()];

declare 'OperationErrors',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::OperationErrors'];

coerce 'OperationErrors',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::OperationErrors'->new($_) };

declare 'RepeatedOperationErrors',
    as ArrayRef[OperationErrors()];

coerce 'RepeatedOperationErrors',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::OperationErrors'->new($_) } @$_ ] };

declare 'MapStringOperationErrors',
    as HashRef[OperationErrors()];

declare 'PasswordValidationPolicy',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::PasswordValidationPolicy'];

coerce 'PasswordValidationPolicy',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::PasswordValidationPolicy'->new($_) };

declare 'RepeatedPasswordValidationPolicy',
    as ArrayRef[PasswordValidationPolicy()];

coerce 'RepeatedPasswordValidationPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::PasswordValidationPolicy'->new($_) } @$_ ] };

declare 'MapStringPasswordValidationPolicy',
    as HashRef[PasswordValidationPolicy()];

declare 'Complexity',
    as (Int | Str);

declare 'DataCacheConfig',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::DataCacheConfig'];

coerce 'DataCacheConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::DataCacheConfig'->new($_) };

declare 'RepeatedDataCacheConfig',
    as ArrayRef[DataCacheConfig()];

coerce 'RepeatedDataCacheConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::DataCacheConfig'->new($_) } @$_ ] };

declare 'MapStringDataCacheConfig',
    as HashRef[DataCacheConfig()];

declare 'FinalBackupConfig',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::FinalBackupConfig'];

coerce 'FinalBackupConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::FinalBackupConfig'->new($_) };

declare 'RepeatedFinalBackupConfig',
    as ArrayRef[FinalBackupConfig()];

coerce 'RepeatedFinalBackupConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::FinalBackupConfig'->new($_) } @$_ ] };

declare 'MapStringFinalBackupConfig',
    as HashRef[FinalBackupConfig()];

declare 'Settings',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::Settings'];

coerce 'Settings',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::Settings'->new($_) };

declare 'RepeatedSettings',
    as ArrayRef[Settings()];

coerce 'RepeatedSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::Settings'->new($_) } @$_ ] };

declare 'MapStringSettings',
    as HashRef[Settings()];

declare 'SqlActivationPolicy',
    as (Int | Str);

declare 'Edition',
    as (Int | Str);

declare 'ConnectorEnforcement',
    as (Int | Str);

declare 'DataApiAccess',
    as (Int | Str);

declare 'UserLabelsEntry',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::Settings::UserLabelsEntry'];

coerce 'UserLabelsEntry',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::Settings::UserLabelsEntry'->new($_) };

declare 'RepeatedUserLabelsEntry',
    as ArrayRef[UserLabelsEntry()];

coerce 'RepeatedUserLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::Settings::UserLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringUserLabelsEntry',
    as HashRef[UserLabelsEntry()];

declare 'PerformanceCaptureConfig',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::PerformanceCaptureConfig'];

coerce 'PerformanceCaptureConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::PerformanceCaptureConfig'->new($_) };

declare 'RepeatedPerformanceCaptureConfig',
    as ArrayRef[PerformanceCaptureConfig()];

coerce 'RepeatedPerformanceCaptureConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::PerformanceCaptureConfig'->new($_) } @$_ ] };

declare 'MapStringPerformanceCaptureConfig',
    as HashRef[PerformanceCaptureConfig()];

declare 'TransactionKillType',
    as (Int | Str);

declare 'ConnectionPoolFlags',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::ConnectionPoolFlags'];

coerce 'ConnectionPoolFlags',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::ConnectionPoolFlags'->new($_) };

declare 'RepeatedConnectionPoolFlags',
    as ArrayRef[ConnectionPoolFlags()];

coerce 'RepeatedConnectionPoolFlags',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::ConnectionPoolFlags'->new($_) } @$_ ] };

declare 'MapStringConnectionPoolFlags',
    as HashRef[ConnectionPoolFlags()];

declare 'ConnectionPoolConfig',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::ConnectionPoolConfig'];

coerce 'ConnectionPoolConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::ConnectionPoolConfig'->new($_) };

declare 'RepeatedConnectionPoolConfig',
    as ArrayRef[ConnectionPoolConfig()];

coerce 'RepeatedConnectionPoolConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::ConnectionPoolConfig'->new($_) } @$_ ] };

declare 'MapStringConnectionPoolConfig',
    as HashRef[ConnectionPoolConfig()];

declare 'ReadPoolAutoScaleConfig',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::ReadPoolAutoScaleConfig'];

coerce 'ReadPoolAutoScaleConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::ReadPoolAutoScaleConfig'->new($_) };

declare 'RepeatedReadPoolAutoScaleConfig',
    as ArrayRef[ReadPoolAutoScaleConfig()];

coerce 'RepeatedReadPoolAutoScaleConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::ReadPoolAutoScaleConfig'->new($_) } @$_ ] };

declare 'MapStringReadPoolAutoScaleConfig',
    as HashRef[ReadPoolAutoScaleConfig()];

declare 'TargetMetric',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::ReadPoolAutoScaleConfig::TargetMetric'];

coerce 'TargetMetric',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::ReadPoolAutoScaleConfig::TargetMetric'->new($_) };

declare 'RepeatedTargetMetric',
    as ArrayRef[TargetMetric()];

coerce 'RepeatedTargetMetric',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::ReadPoolAutoScaleConfig::TargetMetric'->new($_) } @$_ ] };

declare 'MapStringTargetMetric',
    as HashRef[TargetMetric()];

declare 'AdvancedMachineFeatures',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::AdvancedMachineFeatures'];

coerce 'AdvancedMachineFeatures',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::AdvancedMachineFeatures'->new($_) };

declare 'RepeatedAdvancedMachineFeatures',
    as ArrayRef[AdvancedMachineFeatures()];

coerce 'RepeatedAdvancedMachineFeatures',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::AdvancedMachineFeatures'->new($_) } @$_ ] };

declare 'MapStringAdvancedMachineFeatures',
    as HashRef[AdvancedMachineFeatures()];

declare 'SslCert',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::SslCert'];

coerce 'SslCert',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::SslCert'->new($_) };

declare 'RepeatedSslCert',
    as ArrayRef[SslCert()];

coerce 'RepeatedSslCert',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::SslCert'->new($_) } @$_ ] };

declare 'MapStringSslCert',
    as HashRef[SslCert()];

declare 'SslCertDetail',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::SslCertDetail'];

coerce 'SslCertDetail',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::SslCertDetail'->new($_) };

declare 'RepeatedSslCertDetail',
    as ArrayRef[SslCertDetail()];

coerce 'RepeatedSslCertDetail',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::SslCertDetail'->new($_) } @$_ ] };

declare 'MapStringSslCertDetail',
    as HashRef[SslCertDetail()];

declare 'SqlActiveDirectoryConfig',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::SqlActiveDirectoryConfig'];

coerce 'SqlActiveDirectoryConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::SqlActiveDirectoryConfig'->new($_) };

declare 'RepeatedSqlActiveDirectoryConfig',
    as ArrayRef[SqlActiveDirectoryConfig()];

coerce 'RepeatedSqlActiveDirectoryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::SqlActiveDirectoryConfig'->new($_) } @$_ ] };

declare 'MapStringSqlActiveDirectoryConfig',
    as HashRef[SqlActiveDirectoryConfig()];

declare 'ActiveDirectoryMode',
    as (Int | Str);

declare 'SqlServerAuditConfig',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::SqlServerAuditConfig'];

coerce 'SqlServerAuditConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::SqlServerAuditConfig'->new($_) };

declare 'RepeatedSqlServerAuditConfig',
    as ArrayRef[SqlServerAuditConfig()];

coerce 'RepeatedSqlServerAuditConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::SqlServerAuditConfig'->new($_) } @$_ ] };

declare 'MapStringSqlServerAuditConfig',
    as HashRef[SqlServerAuditConfig()];

declare 'SqlServerEntraIdConfig',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::SqlServerEntraIdConfig'];

coerce 'SqlServerEntraIdConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::SqlServerEntraIdConfig'->new($_) };

declare 'RepeatedSqlServerEntraIdConfig',
    as ArrayRef[SqlServerEntraIdConfig()];

coerce 'RepeatedSqlServerEntraIdConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::SqlServerEntraIdConfig'->new($_) } @$_ ] };

declare 'MapStringSqlServerEntraIdConfig',
    as HashRef[SqlServerEntraIdConfig()];

declare 'AcquireSsrsLeaseContext',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::AcquireSsrsLeaseContext'];

coerce 'AcquireSsrsLeaseContext',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::AcquireSsrsLeaseContext'->new($_) };

declare 'RepeatedAcquireSsrsLeaseContext',
    as ArrayRef[AcquireSsrsLeaseContext()];

coerce 'RepeatedAcquireSsrsLeaseContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::AcquireSsrsLeaseContext'->new($_) } @$_ ] };

declare 'MapStringAcquireSsrsLeaseContext',
    as HashRef[AcquireSsrsLeaseContext()];

declare 'DnsNameMapping',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlResources::DnsNameMapping'];

coerce 'DnsNameMapping',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlResources::DnsNameMapping'->new($_) };

declare 'RepeatedDnsNameMapping',
    as ArrayRef[DnsNameMapping()];

coerce 'RepeatedDnsNameMapping',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlResources::DnsNameMapping'->new($_) } @$_ ] };

declare 'MapStringDnsNameMapping',
    as HashRef[DnsNameMapping()];

declare 'ConnectionType',
    as (Int | Str);

declare 'DnsScope',
    as (Int | Str);

declare 'RecordManager',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlResources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
