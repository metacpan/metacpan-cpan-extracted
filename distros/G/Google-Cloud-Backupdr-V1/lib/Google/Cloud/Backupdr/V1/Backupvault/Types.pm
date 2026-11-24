package Google::Cloud::Backupdr::V1::Backupvault::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BackupConfigState',
    as (Int | Str);

declare 'BackupView',
    as (Int | Str);

declare 'BackupVaultView',
    as (Int | Str);

declare 'BackupVault',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::BackupVault'];

coerce 'BackupVault',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::BackupVault'->new($_) };

declare 'RepeatedBackupVault',
    as ArrayRef[BackupVault()];

coerce 'RepeatedBackupVault',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::BackupVault'->new($_) } @$_ ] };

declare 'MapStringBackupVault',
    as HashRef[BackupVault()];

declare 'BackupRetentionInheritance',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'AccessRestriction',
    as (Int | Str);

declare 'EncryptionConfig',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::BackupVault::EncryptionConfig'];

coerce 'EncryptionConfig',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::BackupVault::EncryptionConfig'->new($_) };

declare 'RepeatedEncryptionConfig',
    as ArrayRef[EncryptionConfig()];

coerce 'RepeatedEncryptionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::BackupVault::EncryptionConfig'->new($_) } @$_ ] };

declare 'MapStringEncryptionConfig',
    as HashRef[EncryptionConfig()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::BackupVault::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::BackupVault::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::BackupVault::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::BackupVault::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::BackupVault::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::BackupVault::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'DataSource',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::DataSource'];

coerce 'DataSource',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::DataSource'->new($_) };

declare 'RepeatedDataSource',
    as ArrayRef[DataSource()];

coerce 'RepeatedDataSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::DataSource'->new($_) } @$_ ] };

declare 'MapStringDataSource',
    as HashRef[DataSource()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::DataSource::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::DataSource::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::DataSource::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'BackupConfigInfo',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::BackupConfigInfo'];

coerce 'BackupConfigInfo',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::BackupConfigInfo'->new($_) };

declare 'RepeatedBackupConfigInfo',
    as ArrayRef[BackupConfigInfo()];

coerce 'RepeatedBackupConfigInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::BackupConfigInfo'->new($_) } @$_ ] };

declare 'MapStringBackupConfigInfo',
    as HashRef[BackupConfigInfo()];

declare 'LastBackupState',
    as (Int | Str);

declare 'GcpBackupConfig',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::GcpBackupConfig'];

coerce 'GcpBackupConfig',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::GcpBackupConfig'->new($_) };

declare 'RepeatedGcpBackupConfig',
    as ArrayRef[GcpBackupConfig()];

coerce 'RepeatedGcpBackupConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::GcpBackupConfig'->new($_) } @$_ ] };

declare 'MapStringGcpBackupConfig',
    as HashRef[GcpBackupConfig()];

declare 'BackupApplianceBackupConfig',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::BackupApplianceBackupConfig'];

coerce 'BackupApplianceBackupConfig',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::BackupApplianceBackupConfig'->new($_) };

declare 'RepeatedBackupApplianceBackupConfig',
    as ArrayRef[BackupApplianceBackupConfig()];

coerce 'RepeatedBackupApplianceBackupConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::BackupApplianceBackupConfig'->new($_) } @$_ ] };

declare 'MapStringBackupApplianceBackupConfig',
    as HashRef[BackupApplianceBackupConfig()];

declare 'DataSourceGcpResource',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::DataSourceGcpResource'];

coerce 'DataSourceGcpResource',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::DataSourceGcpResource'->new($_) };

declare 'RepeatedDataSourceGcpResource',
    as ArrayRef[DataSourceGcpResource()];

coerce 'RepeatedDataSourceGcpResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::DataSourceGcpResource'->new($_) } @$_ ] };

declare 'MapStringDataSourceGcpResource',
    as HashRef[DataSourceGcpResource()];

declare 'DataSourceBackupApplianceApplication',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::DataSourceBackupApplianceApplication'];

coerce 'DataSourceBackupApplianceApplication',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::DataSourceBackupApplianceApplication'->new($_) };

declare 'RepeatedDataSourceBackupApplianceApplication',
    as ArrayRef[DataSourceBackupApplianceApplication()];

coerce 'RepeatedDataSourceBackupApplianceApplication',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::DataSourceBackupApplianceApplication'->new($_) } @$_ ] };

declare 'MapStringDataSourceBackupApplianceApplication',
    as HashRef[DataSourceBackupApplianceApplication()];

declare 'ServiceLockInfo',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::ServiceLockInfo'];

coerce 'ServiceLockInfo',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::ServiceLockInfo'->new($_) };

declare 'RepeatedServiceLockInfo',
    as ArrayRef[ServiceLockInfo()];

coerce 'RepeatedServiceLockInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::ServiceLockInfo'->new($_) } @$_ ] };

declare 'MapStringServiceLockInfo',
    as HashRef[ServiceLockInfo()];

declare 'BackupApplianceLockInfo',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::BackupApplianceLockInfo'];

coerce 'BackupApplianceLockInfo',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::BackupApplianceLockInfo'->new($_) };

declare 'RepeatedBackupApplianceLockInfo',
    as ArrayRef[BackupApplianceLockInfo()];

coerce 'RepeatedBackupApplianceLockInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::BackupApplianceLockInfo'->new($_) } @$_ ] };

declare 'MapStringBackupApplianceLockInfo',
    as HashRef[BackupApplianceLockInfo()];

declare 'BackupLock',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::BackupLock'];

coerce 'BackupLock',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::BackupLock'->new($_) };

declare 'RepeatedBackupLock',
    as ArrayRef[BackupLock()];

coerce 'RepeatedBackupLock',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::BackupLock'->new($_) } @$_ ] };

declare 'MapStringBackupLock',
    as HashRef[BackupLock()];

declare 'Backup',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::Backup'];

coerce 'Backup',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::Backup'->new($_) };

declare 'RepeatedBackup',
    as ArrayRef[Backup()];

coerce 'RepeatedBackup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::Backup'->new($_) } @$_ ] };

declare 'MapStringBackup',
    as HashRef[Backup()];

declare 'State',
    as (Int | Str);

declare 'BackupType',
    as (Int | Str);

declare 'GCPBackupPlanInfo',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::Backup::GCPBackupPlanInfo'];

coerce 'GCPBackupPlanInfo',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::Backup::GCPBackupPlanInfo'->new($_) };

declare 'RepeatedGCPBackupPlanInfo',
    as ArrayRef[GCPBackupPlanInfo()];

coerce 'RepeatedGCPBackupPlanInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::Backup::GCPBackupPlanInfo'->new($_) } @$_ ] };

declare 'MapStringGCPBackupPlanInfo',
    as HashRef[GCPBackupPlanInfo()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::Backup::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::Backup::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::Backup::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'VerificationSummary',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::VerificationSummary'];

coerce 'VerificationSummary',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::VerificationSummary'->new($_) };

declare 'RepeatedVerificationSummary',
    as ArrayRef[VerificationSummary()];

coerce 'RepeatedVerificationSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::VerificationSummary'->new($_) } @$_ ] };

declare 'MapStringVerificationSummary',
    as HashRef[VerificationSummary()];

declare 'LastVerificationState',
    as (Int | Str);

declare 'CreateBackupVaultRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::CreateBackupVaultRequest'];

coerce 'CreateBackupVaultRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::CreateBackupVaultRequest'->new($_) };

declare 'RepeatedCreateBackupVaultRequest',
    as ArrayRef[CreateBackupVaultRequest()];

coerce 'RepeatedCreateBackupVaultRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::CreateBackupVaultRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBackupVaultRequest',
    as HashRef[CreateBackupVaultRequest()];

declare 'ListBackupVaultsRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::ListBackupVaultsRequest'];

coerce 'ListBackupVaultsRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::ListBackupVaultsRequest'->new($_) };

declare 'RepeatedListBackupVaultsRequest',
    as ArrayRef[ListBackupVaultsRequest()];

coerce 'RepeatedListBackupVaultsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::ListBackupVaultsRequest'->new($_) } @$_ ] };

declare 'MapStringListBackupVaultsRequest',
    as HashRef[ListBackupVaultsRequest()];

declare 'ListBackupVaultsResponse',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::ListBackupVaultsResponse'];

coerce 'ListBackupVaultsResponse',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::ListBackupVaultsResponse'->new($_) };

declare 'RepeatedListBackupVaultsResponse',
    as ArrayRef[ListBackupVaultsResponse()];

coerce 'RepeatedListBackupVaultsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::ListBackupVaultsResponse'->new($_) } @$_ ] };

declare 'MapStringListBackupVaultsResponse',
    as HashRef[ListBackupVaultsResponse()];

declare 'FetchUsableBackupVaultsRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::FetchUsableBackupVaultsRequest'];

coerce 'FetchUsableBackupVaultsRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::FetchUsableBackupVaultsRequest'->new($_) };

declare 'RepeatedFetchUsableBackupVaultsRequest',
    as ArrayRef[FetchUsableBackupVaultsRequest()];

coerce 'RepeatedFetchUsableBackupVaultsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::FetchUsableBackupVaultsRequest'->new($_) } @$_ ] };

declare 'MapStringFetchUsableBackupVaultsRequest',
    as HashRef[FetchUsableBackupVaultsRequest()];

declare 'FetchUsableBackupVaultsResponse',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::FetchUsableBackupVaultsResponse'];

coerce 'FetchUsableBackupVaultsResponse',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::FetchUsableBackupVaultsResponse'->new($_) };

declare 'RepeatedFetchUsableBackupVaultsResponse',
    as ArrayRef[FetchUsableBackupVaultsResponse()];

coerce 'RepeatedFetchUsableBackupVaultsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::FetchUsableBackupVaultsResponse'->new($_) } @$_ ] };

declare 'MapStringFetchUsableBackupVaultsResponse',
    as HashRef[FetchUsableBackupVaultsResponse()];

declare 'FetchBackupsForResourceTypeRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::FetchBackupsForResourceTypeRequest'];

coerce 'FetchBackupsForResourceTypeRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::FetchBackupsForResourceTypeRequest'->new($_) };

declare 'RepeatedFetchBackupsForResourceTypeRequest',
    as ArrayRef[FetchBackupsForResourceTypeRequest()];

coerce 'RepeatedFetchBackupsForResourceTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::FetchBackupsForResourceTypeRequest'->new($_) } @$_ ] };

declare 'MapStringFetchBackupsForResourceTypeRequest',
    as HashRef[FetchBackupsForResourceTypeRequest()];

declare 'FetchBackupsForResourceTypeResponse',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::FetchBackupsForResourceTypeResponse'];

coerce 'FetchBackupsForResourceTypeResponse',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::FetchBackupsForResourceTypeResponse'->new($_) };

declare 'RepeatedFetchBackupsForResourceTypeResponse',
    as ArrayRef[FetchBackupsForResourceTypeResponse()];

coerce 'RepeatedFetchBackupsForResourceTypeResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::FetchBackupsForResourceTypeResponse'->new($_) } @$_ ] };

declare 'MapStringFetchBackupsForResourceTypeResponse',
    as HashRef[FetchBackupsForResourceTypeResponse()];

declare 'GetBackupVaultRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::GetBackupVaultRequest'];

coerce 'GetBackupVaultRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::GetBackupVaultRequest'->new($_) };

declare 'RepeatedGetBackupVaultRequest',
    as ArrayRef[GetBackupVaultRequest()];

coerce 'RepeatedGetBackupVaultRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::GetBackupVaultRequest'->new($_) } @$_ ] };

declare 'MapStringGetBackupVaultRequest',
    as HashRef[GetBackupVaultRequest()];

declare 'UpdateBackupVaultRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::UpdateBackupVaultRequest'];

coerce 'UpdateBackupVaultRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::UpdateBackupVaultRequest'->new($_) };

declare 'RepeatedUpdateBackupVaultRequest',
    as ArrayRef[UpdateBackupVaultRequest()];

coerce 'RepeatedUpdateBackupVaultRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::UpdateBackupVaultRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBackupVaultRequest',
    as HashRef[UpdateBackupVaultRequest()];

declare 'DeleteBackupVaultRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::DeleteBackupVaultRequest'];

coerce 'DeleteBackupVaultRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::DeleteBackupVaultRequest'->new($_) };

declare 'RepeatedDeleteBackupVaultRequest',
    as ArrayRef[DeleteBackupVaultRequest()];

coerce 'RepeatedDeleteBackupVaultRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::DeleteBackupVaultRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBackupVaultRequest',
    as HashRef[DeleteBackupVaultRequest()];

declare 'ListDataSourcesRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::ListDataSourcesRequest'];

coerce 'ListDataSourcesRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::ListDataSourcesRequest'->new($_) };

declare 'RepeatedListDataSourcesRequest',
    as ArrayRef[ListDataSourcesRequest()];

coerce 'RepeatedListDataSourcesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::ListDataSourcesRequest'->new($_) } @$_ ] };

declare 'MapStringListDataSourcesRequest',
    as HashRef[ListDataSourcesRequest()];

declare 'ListDataSourcesResponse',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::ListDataSourcesResponse'];

coerce 'ListDataSourcesResponse',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::ListDataSourcesResponse'->new($_) };

declare 'RepeatedListDataSourcesResponse',
    as ArrayRef[ListDataSourcesResponse()];

coerce 'RepeatedListDataSourcesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::ListDataSourcesResponse'->new($_) } @$_ ] };

declare 'MapStringListDataSourcesResponse',
    as HashRef[ListDataSourcesResponse()];

declare 'GetDataSourceRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::GetDataSourceRequest'];

coerce 'GetDataSourceRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::GetDataSourceRequest'->new($_) };

declare 'RepeatedGetDataSourceRequest',
    as ArrayRef[GetDataSourceRequest()];

coerce 'RepeatedGetDataSourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::GetDataSourceRequest'->new($_) } @$_ ] };

declare 'MapStringGetDataSourceRequest',
    as HashRef[GetDataSourceRequest()];

declare 'UpdateDataSourceRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::UpdateDataSourceRequest'];

coerce 'UpdateDataSourceRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::UpdateDataSourceRequest'->new($_) };

declare 'RepeatedUpdateDataSourceRequest',
    as ArrayRef[UpdateDataSourceRequest()];

coerce 'RepeatedUpdateDataSourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::UpdateDataSourceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDataSourceRequest',
    as HashRef[UpdateDataSourceRequest()];

declare 'ListBackupsRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::ListBackupsRequest'];

coerce 'ListBackupsRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::ListBackupsRequest'->new($_) };

declare 'RepeatedListBackupsRequest',
    as ArrayRef[ListBackupsRequest()];

coerce 'RepeatedListBackupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::ListBackupsRequest'->new($_) } @$_ ] };

declare 'MapStringListBackupsRequest',
    as HashRef[ListBackupsRequest()];

declare 'ListBackupsResponse',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::ListBackupsResponse'];

coerce 'ListBackupsResponse',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::ListBackupsResponse'->new($_) };

declare 'RepeatedListBackupsResponse',
    as ArrayRef[ListBackupsResponse()];

coerce 'RepeatedListBackupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::ListBackupsResponse'->new($_) } @$_ ] };

declare 'MapStringListBackupsResponse',
    as HashRef[ListBackupsResponse()];

declare 'GetBackupRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::GetBackupRequest'];

coerce 'GetBackupRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::GetBackupRequest'->new($_) };

declare 'RepeatedGetBackupRequest',
    as ArrayRef[GetBackupRequest()];

coerce 'RepeatedGetBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::GetBackupRequest'->new($_) } @$_ ] };

declare 'MapStringGetBackupRequest',
    as HashRef[GetBackupRequest()];

declare 'UpdateBackupRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::UpdateBackupRequest'];

coerce 'UpdateBackupRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::UpdateBackupRequest'->new($_) };

declare 'RepeatedUpdateBackupRequest',
    as ArrayRef[UpdateBackupRequest()];

coerce 'RepeatedUpdateBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::UpdateBackupRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBackupRequest',
    as HashRef[UpdateBackupRequest()];

declare 'DeleteBackupRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::DeleteBackupRequest'];

coerce 'DeleteBackupRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::DeleteBackupRequest'->new($_) };

declare 'RepeatedDeleteBackupRequest',
    as ArrayRef[DeleteBackupRequest()];

coerce 'RepeatedDeleteBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::DeleteBackupRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBackupRequest',
    as HashRef[DeleteBackupRequest()];

declare 'RestoreBackupRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::RestoreBackupRequest'];

coerce 'RestoreBackupRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::RestoreBackupRequest'->new($_) };

declare 'RepeatedRestoreBackupRequest',
    as ArrayRef[RestoreBackupRequest()];

coerce 'RepeatedRestoreBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::RestoreBackupRequest'->new($_) } @$_ ] };

declare 'MapStringRestoreBackupRequest',
    as HashRef[RestoreBackupRequest()];

declare 'RestoreBackupResponse',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::RestoreBackupResponse'];

coerce 'RestoreBackupResponse',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::RestoreBackupResponse'->new($_) };

declare 'RepeatedRestoreBackupResponse',
    as ArrayRef[RestoreBackupResponse()];

coerce 'RepeatedRestoreBackupResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::RestoreBackupResponse'->new($_) } @$_ ] };

declare 'MapStringRestoreBackupResponse',
    as HashRef[RestoreBackupResponse()];

declare 'TargetResource',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::TargetResource'];

coerce 'TargetResource',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::TargetResource'->new($_) };

declare 'RepeatedTargetResource',
    as ArrayRef[TargetResource()];

coerce 'RepeatedTargetResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::TargetResource'->new($_) } @$_ ] };

declare 'MapStringTargetResource',
    as HashRef[TargetResource()];

declare 'GcpResource',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::GcpResource'];

coerce 'GcpResource',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::GcpResource'->new($_) };

declare 'RepeatedGcpResource',
    as ArrayRef[GcpResource()];

coerce 'RepeatedGcpResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::GcpResource'->new($_) } @$_ ] };

declare 'MapStringGcpResource',
    as HashRef[GcpResource()];

declare 'BackupGcpResource',
    as InstanceOf['Google::Cloud::Backupdr::V1::Backupvault::BackupGcpResource'];

coerce 'BackupGcpResource',
    from HashRef, via { 'Google::Cloud::Backupdr::V1::Backupvault::BackupGcpResource'->new($_) };

declare 'RepeatedBackupGcpResource',
    as ArrayRef[BackupGcpResource()];

coerce 'RepeatedBackupGcpResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1::Backupvault::BackupGcpResource'->new($_) } @$_ ] };

declare 'MapStringBackupGcpResource',
    as HashRef[BackupGcpResource()];

1;

__END__

=head1 NAME

Google::Cloud::Backupdr::V1::Backupvault::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
