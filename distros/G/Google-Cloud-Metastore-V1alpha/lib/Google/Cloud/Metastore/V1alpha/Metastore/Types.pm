package Google::Cloud::Metastore::V1alpha::Metastore::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Service',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::Service'];

coerce 'Service',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::Service'->new($_) };

declare 'RepeatedService',
    as ArrayRef[Service()];

coerce 'RepeatedService',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::Service'->new($_) } @$_ ] };

declare 'MapStringService',
    as HashRef[Service()];

declare 'State',
    as (Int | Str);

declare 'Tier',
    as (Int | Str);

declare 'ReleaseChannel',
    as (Int | Str);

declare 'DatabaseType',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::Service::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::Service::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::Service::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'MetadataIntegration',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::MetadataIntegration'];

coerce 'MetadataIntegration',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::MetadataIntegration'->new($_) };

declare 'RepeatedMetadataIntegration',
    as ArrayRef[MetadataIntegration()];

coerce 'RepeatedMetadataIntegration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::MetadataIntegration'->new($_) } @$_ ] };

declare 'MapStringMetadataIntegration',
    as HashRef[MetadataIntegration()];

declare 'DataCatalogConfig',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::DataCatalogConfig'];

coerce 'DataCatalogConfig',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::DataCatalogConfig'->new($_) };

declare 'RepeatedDataCatalogConfig',
    as ArrayRef[DataCatalogConfig()];

coerce 'RepeatedDataCatalogConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::DataCatalogConfig'->new($_) } @$_ ] };

declare 'MapStringDataCatalogConfig',
    as HashRef[DataCatalogConfig()];

declare 'DataplexConfig',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::DataplexConfig'];

coerce 'DataplexConfig',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::DataplexConfig'->new($_) };

declare 'RepeatedDataplexConfig',
    as ArrayRef[DataplexConfig()];

coerce 'RepeatedDataplexConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::DataplexConfig'->new($_) } @$_ ] };

declare 'MapStringDataplexConfig',
    as HashRef[DataplexConfig()];

declare 'LakeResourcesEntry',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::DataplexConfig::LakeResourcesEntry'];

coerce 'LakeResourcesEntry',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::DataplexConfig::LakeResourcesEntry'->new($_) };

declare 'RepeatedLakeResourcesEntry',
    as ArrayRef[LakeResourcesEntry()];

coerce 'RepeatedLakeResourcesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::DataplexConfig::LakeResourcesEntry'->new($_) } @$_ ] };

declare 'MapStringLakeResourcesEntry',
    as HashRef[LakeResourcesEntry()];

declare 'Lake',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::Lake'];

coerce 'Lake',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::Lake'->new($_) };

declare 'RepeatedLake',
    as ArrayRef[Lake()];

coerce 'RepeatedLake',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::Lake'->new($_) } @$_ ] };

declare 'MapStringLake',
    as HashRef[Lake()];

declare 'MaintenanceWindow',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::MaintenanceWindow'];

coerce 'MaintenanceWindow',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::MaintenanceWindow'->new($_) };

declare 'RepeatedMaintenanceWindow',
    as ArrayRef[MaintenanceWindow()];

coerce 'RepeatedMaintenanceWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::MaintenanceWindow'->new($_) } @$_ ] };

declare 'MapStringMaintenanceWindow',
    as HashRef[MaintenanceWindow()];

declare 'HiveMetastoreConfig',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::HiveMetastoreConfig'];

coerce 'HiveMetastoreConfig',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::HiveMetastoreConfig'->new($_) };

declare 'RepeatedHiveMetastoreConfig',
    as ArrayRef[HiveMetastoreConfig()];

coerce 'RepeatedHiveMetastoreConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::HiveMetastoreConfig'->new($_) } @$_ ] };

declare 'MapStringHiveMetastoreConfig',
    as HashRef[HiveMetastoreConfig()];

declare 'EndpointProtocol',
    as (Int | Str);

declare 'ConfigOverridesEntry',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::HiveMetastoreConfig::ConfigOverridesEntry'];

coerce 'ConfigOverridesEntry',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::HiveMetastoreConfig::ConfigOverridesEntry'->new($_) };

declare 'RepeatedConfigOverridesEntry',
    as ArrayRef[ConfigOverridesEntry()];

coerce 'RepeatedConfigOverridesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::HiveMetastoreConfig::ConfigOverridesEntry'->new($_) } @$_ ] };

declare 'MapStringConfigOverridesEntry',
    as HashRef[ConfigOverridesEntry()];

declare 'AuxiliaryVersionsEntry',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::HiveMetastoreConfig::AuxiliaryVersionsEntry'];

coerce 'AuxiliaryVersionsEntry',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::HiveMetastoreConfig::AuxiliaryVersionsEntry'->new($_) };

declare 'RepeatedAuxiliaryVersionsEntry',
    as ArrayRef[AuxiliaryVersionsEntry()];

coerce 'RepeatedAuxiliaryVersionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::HiveMetastoreConfig::AuxiliaryVersionsEntry'->new($_) } @$_ ] };

declare 'MapStringAuxiliaryVersionsEntry',
    as HashRef[AuxiliaryVersionsEntry()];

declare 'KerberosConfig',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::KerberosConfig'];

coerce 'KerberosConfig',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::KerberosConfig'->new($_) };

declare 'RepeatedKerberosConfig',
    as ArrayRef[KerberosConfig()];

coerce 'RepeatedKerberosConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::KerberosConfig'->new($_) } @$_ ] };

declare 'MapStringKerberosConfig',
    as HashRef[KerberosConfig()];

declare 'Secret',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::Secret'];

coerce 'Secret',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::Secret'->new($_) };

declare 'RepeatedSecret',
    as ArrayRef[Secret()];

coerce 'RepeatedSecret',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::Secret'->new($_) } @$_ ] };

declare 'MapStringSecret',
    as HashRef[Secret()];

declare 'EncryptionConfig',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::EncryptionConfig'];

coerce 'EncryptionConfig',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::EncryptionConfig'->new($_) };

declare 'RepeatedEncryptionConfig',
    as ArrayRef[EncryptionConfig()];

coerce 'RepeatedEncryptionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::EncryptionConfig'->new($_) } @$_ ] };

declare 'MapStringEncryptionConfig',
    as HashRef[EncryptionConfig()];

declare 'AuxiliaryVersionConfig',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::AuxiliaryVersionConfig'];

coerce 'AuxiliaryVersionConfig',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::AuxiliaryVersionConfig'->new($_) };

declare 'RepeatedAuxiliaryVersionConfig',
    as ArrayRef[AuxiliaryVersionConfig()];

coerce 'RepeatedAuxiliaryVersionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::AuxiliaryVersionConfig'->new($_) } @$_ ] };

declare 'MapStringAuxiliaryVersionConfig',
    as HashRef[AuxiliaryVersionConfig()];

declare 'ConfigOverridesEntry',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::AuxiliaryVersionConfig::ConfigOverridesEntry'];

coerce 'ConfigOverridesEntry',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::AuxiliaryVersionConfig::ConfigOverridesEntry'->new($_) };

declare 'RepeatedConfigOverridesEntry',
    as ArrayRef[ConfigOverridesEntry()];

coerce 'RepeatedConfigOverridesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::AuxiliaryVersionConfig::ConfigOverridesEntry'->new($_) } @$_ ] };

declare 'MapStringConfigOverridesEntry',
    as HashRef[ConfigOverridesEntry()];

declare 'NetworkConfig',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::NetworkConfig'];

coerce 'NetworkConfig',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::NetworkConfig'->new($_) };

declare 'RepeatedNetworkConfig',
    as ArrayRef[NetworkConfig()];

coerce 'RepeatedNetworkConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::NetworkConfig'->new($_) } @$_ ] };

declare 'MapStringNetworkConfig',
    as HashRef[NetworkConfig()];

declare 'Consumer',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::NetworkConfig::Consumer'];

coerce 'Consumer',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::NetworkConfig::Consumer'->new($_) };

declare 'RepeatedConsumer',
    as ArrayRef[Consumer()];

coerce 'RepeatedConsumer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::NetworkConfig::Consumer'->new($_) } @$_ ] };

declare 'MapStringConsumer',
    as HashRef[Consumer()];

declare 'TelemetryConfig',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::TelemetryConfig'];

coerce 'TelemetryConfig',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::TelemetryConfig'->new($_) };

declare 'RepeatedTelemetryConfig',
    as ArrayRef[TelemetryConfig()];

coerce 'RepeatedTelemetryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::TelemetryConfig'->new($_) } @$_ ] };

declare 'MapStringTelemetryConfig',
    as HashRef[TelemetryConfig()];

declare 'LogFormat',
    as (Int | Str);

declare 'MetadataManagementActivity',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::MetadataManagementActivity'];

coerce 'MetadataManagementActivity',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::MetadataManagementActivity'->new($_) };

declare 'RepeatedMetadataManagementActivity',
    as ArrayRef[MetadataManagementActivity()];

coerce 'RepeatedMetadataManagementActivity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::MetadataManagementActivity'->new($_) } @$_ ] };

declare 'MapStringMetadataManagementActivity',
    as HashRef[MetadataManagementActivity()];

declare 'MetadataImport',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::MetadataImport'];

coerce 'MetadataImport',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::MetadataImport'->new($_) };

declare 'RepeatedMetadataImport',
    as ArrayRef[MetadataImport()];

coerce 'RepeatedMetadataImport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::MetadataImport'->new($_) } @$_ ] };

declare 'MapStringMetadataImport',
    as HashRef[MetadataImport()];

declare 'State',
    as (Int | Str);

declare 'DatabaseDump',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::MetadataImport::DatabaseDump'];

coerce 'DatabaseDump',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::MetadataImport::DatabaseDump'->new($_) };

declare 'RepeatedDatabaseDump',
    as ArrayRef[DatabaseDump()];

coerce 'RepeatedDatabaseDump',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::MetadataImport::DatabaseDump'->new($_) } @$_ ] };

declare 'MapStringDatabaseDump',
    as HashRef[DatabaseDump()];

declare 'DatabaseType',
    as (Int | Str);

declare 'MetadataExport',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::MetadataExport'];

coerce 'MetadataExport',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::MetadataExport'->new($_) };

declare 'RepeatedMetadataExport',
    as ArrayRef[MetadataExport()];

coerce 'RepeatedMetadataExport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::MetadataExport'->new($_) } @$_ ] };

declare 'MapStringMetadataExport',
    as HashRef[MetadataExport()];

declare 'State',
    as (Int | Str);

declare 'Backup',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::Backup'];

coerce 'Backup',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::Backup'->new($_) };

declare 'RepeatedBackup',
    as ArrayRef[Backup()];

coerce 'RepeatedBackup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::Backup'->new($_) } @$_ ] };

declare 'MapStringBackup',
    as HashRef[Backup()];

declare 'State',
    as (Int | Str);

declare 'Restore',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::Restore'];

coerce 'Restore',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::Restore'->new($_) };

declare 'RepeatedRestore',
    as ArrayRef[Restore()];

coerce 'RepeatedRestore',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::Restore'->new($_) } @$_ ] };

declare 'MapStringRestore',
    as HashRef[Restore()];

declare 'State',
    as (Int | Str);

declare 'RestoreType',
    as (Int | Str);

declare 'ScalingConfig',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::ScalingConfig'];

coerce 'ScalingConfig',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::ScalingConfig'->new($_) };

declare 'RepeatedScalingConfig',
    as ArrayRef[ScalingConfig()];

coerce 'RepeatedScalingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::ScalingConfig'->new($_) } @$_ ] };

declare 'MapStringScalingConfig',
    as HashRef[ScalingConfig()];

declare 'InstanceSize',
    as (Int | Str);

declare 'ListServicesRequest',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::ListServicesRequest'];

coerce 'ListServicesRequest',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::ListServicesRequest'->new($_) };

declare 'RepeatedListServicesRequest',
    as ArrayRef[ListServicesRequest()];

coerce 'RepeatedListServicesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::ListServicesRequest'->new($_) } @$_ ] };

declare 'MapStringListServicesRequest',
    as HashRef[ListServicesRequest()];

declare 'ListServicesResponse',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::ListServicesResponse'];

coerce 'ListServicesResponse',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::ListServicesResponse'->new($_) };

declare 'RepeatedListServicesResponse',
    as ArrayRef[ListServicesResponse()];

coerce 'RepeatedListServicesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::ListServicesResponse'->new($_) } @$_ ] };

declare 'MapStringListServicesResponse',
    as HashRef[ListServicesResponse()];

declare 'GetServiceRequest',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::GetServiceRequest'];

coerce 'GetServiceRequest',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::GetServiceRequest'->new($_) };

declare 'RepeatedGetServiceRequest',
    as ArrayRef[GetServiceRequest()];

coerce 'RepeatedGetServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::GetServiceRequest'->new($_) } @$_ ] };

declare 'MapStringGetServiceRequest',
    as HashRef[GetServiceRequest()];

declare 'CreateServiceRequest',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::CreateServiceRequest'];

coerce 'CreateServiceRequest',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::CreateServiceRequest'->new($_) };

declare 'RepeatedCreateServiceRequest',
    as ArrayRef[CreateServiceRequest()];

coerce 'RepeatedCreateServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::CreateServiceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateServiceRequest',
    as HashRef[CreateServiceRequest()];

declare 'UpdateServiceRequest',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::UpdateServiceRequest'];

coerce 'UpdateServiceRequest',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::UpdateServiceRequest'->new($_) };

declare 'RepeatedUpdateServiceRequest',
    as ArrayRef[UpdateServiceRequest()];

coerce 'RepeatedUpdateServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::UpdateServiceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateServiceRequest',
    as HashRef[UpdateServiceRequest()];

declare 'DeleteServiceRequest',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::DeleteServiceRequest'];

coerce 'DeleteServiceRequest',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::DeleteServiceRequest'->new($_) };

declare 'RepeatedDeleteServiceRequest',
    as ArrayRef[DeleteServiceRequest()];

coerce 'RepeatedDeleteServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::DeleteServiceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteServiceRequest',
    as HashRef[DeleteServiceRequest()];

declare 'ListMetadataImportsRequest',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::ListMetadataImportsRequest'];

coerce 'ListMetadataImportsRequest',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::ListMetadataImportsRequest'->new($_) };

declare 'RepeatedListMetadataImportsRequest',
    as ArrayRef[ListMetadataImportsRequest()];

coerce 'RepeatedListMetadataImportsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::ListMetadataImportsRequest'->new($_) } @$_ ] };

declare 'MapStringListMetadataImportsRequest',
    as HashRef[ListMetadataImportsRequest()];

declare 'ListMetadataImportsResponse',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::ListMetadataImportsResponse'];

coerce 'ListMetadataImportsResponse',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::ListMetadataImportsResponse'->new($_) };

declare 'RepeatedListMetadataImportsResponse',
    as ArrayRef[ListMetadataImportsResponse()];

coerce 'RepeatedListMetadataImportsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::ListMetadataImportsResponse'->new($_) } @$_ ] };

declare 'MapStringListMetadataImportsResponse',
    as HashRef[ListMetadataImportsResponse()];

declare 'GetMetadataImportRequest',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::GetMetadataImportRequest'];

coerce 'GetMetadataImportRequest',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::GetMetadataImportRequest'->new($_) };

declare 'RepeatedGetMetadataImportRequest',
    as ArrayRef[GetMetadataImportRequest()];

coerce 'RepeatedGetMetadataImportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::GetMetadataImportRequest'->new($_) } @$_ ] };

declare 'MapStringGetMetadataImportRequest',
    as HashRef[GetMetadataImportRequest()];

declare 'CreateMetadataImportRequest',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::CreateMetadataImportRequest'];

coerce 'CreateMetadataImportRequest',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::CreateMetadataImportRequest'->new($_) };

declare 'RepeatedCreateMetadataImportRequest',
    as ArrayRef[CreateMetadataImportRequest()];

coerce 'RepeatedCreateMetadataImportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::CreateMetadataImportRequest'->new($_) } @$_ ] };

declare 'MapStringCreateMetadataImportRequest',
    as HashRef[CreateMetadataImportRequest()];

declare 'UpdateMetadataImportRequest',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::UpdateMetadataImportRequest'];

coerce 'UpdateMetadataImportRequest',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::UpdateMetadataImportRequest'->new($_) };

declare 'RepeatedUpdateMetadataImportRequest',
    as ArrayRef[UpdateMetadataImportRequest()];

coerce 'RepeatedUpdateMetadataImportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::UpdateMetadataImportRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateMetadataImportRequest',
    as HashRef[UpdateMetadataImportRequest()];

declare 'ListBackupsRequest',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::ListBackupsRequest'];

coerce 'ListBackupsRequest',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::ListBackupsRequest'->new($_) };

declare 'RepeatedListBackupsRequest',
    as ArrayRef[ListBackupsRequest()];

coerce 'RepeatedListBackupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::ListBackupsRequest'->new($_) } @$_ ] };

declare 'MapStringListBackupsRequest',
    as HashRef[ListBackupsRequest()];

declare 'ListBackupsResponse',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::ListBackupsResponse'];

coerce 'ListBackupsResponse',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::ListBackupsResponse'->new($_) };

declare 'RepeatedListBackupsResponse',
    as ArrayRef[ListBackupsResponse()];

coerce 'RepeatedListBackupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::ListBackupsResponse'->new($_) } @$_ ] };

declare 'MapStringListBackupsResponse',
    as HashRef[ListBackupsResponse()];

declare 'GetBackupRequest',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::GetBackupRequest'];

coerce 'GetBackupRequest',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::GetBackupRequest'->new($_) };

declare 'RepeatedGetBackupRequest',
    as ArrayRef[GetBackupRequest()];

coerce 'RepeatedGetBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::GetBackupRequest'->new($_) } @$_ ] };

declare 'MapStringGetBackupRequest',
    as HashRef[GetBackupRequest()];

declare 'CreateBackupRequest',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::CreateBackupRequest'];

coerce 'CreateBackupRequest',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::CreateBackupRequest'->new($_) };

declare 'RepeatedCreateBackupRequest',
    as ArrayRef[CreateBackupRequest()];

coerce 'RepeatedCreateBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::CreateBackupRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBackupRequest',
    as HashRef[CreateBackupRequest()];

declare 'DeleteBackupRequest',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::DeleteBackupRequest'];

coerce 'DeleteBackupRequest',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::DeleteBackupRequest'->new($_) };

declare 'RepeatedDeleteBackupRequest',
    as ArrayRef[DeleteBackupRequest()];

coerce 'RepeatedDeleteBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::DeleteBackupRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBackupRequest',
    as HashRef[DeleteBackupRequest()];

declare 'ExportMetadataRequest',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::ExportMetadataRequest'];

coerce 'ExportMetadataRequest',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::ExportMetadataRequest'->new($_) };

declare 'RepeatedExportMetadataRequest',
    as ArrayRef[ExportMetadataRequest()];

coerce 'RepeatedExportMetadataRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::ExportMetadataRequest'->new($_) } @$_ ] };

declare 'MapStringExportMetadataRequest',
    as HashRef[ExportMetadataRequest()];

declare 'RestoreServiceRequest',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::RestoreServiceRequest'];

coerce 'RestoreServiceRequest',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::RestoreServiceRequest'->new($_) };

declare 'RepeatedRestoreServiceRequest',
    as ArrayRef[RestoreServiceRequest()];

coerce 'RepeatedRestoreServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::RestoreServiceRequest'->new($_) } @$_ ] };

declare 'MapStringRestoreServiceRequest',
    as HashRef[RestoreServiceRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'LocationMetadata',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::LocationMetadata'];

coerce 'LocationMetadata',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::LocationMetadata'->new($_) };

declare 'RepeatedLocationMetadata',
    as ArrayRef[LocationMetadata()];

coerce 'RepeatedLocationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::LocationMetadata'->new($_) } @$_ ] };

declare 'MapStringLocationMetadata',
    as HashRef[LocationMetadata()];

declare 'HiveMetastoreVersion',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::LocationMetadata::HiveMetastoreVersion'];

coerce 'HiveMetastoreVersion',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::LocationMetadata::HiveMetastoreVersion'->new($_) };

declare 'RepeatedHiveMetastoreVersion',
    as ArrayRef[HiveMetastoreVersion()];

coerce 'RepeatedHiveMetastoreVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::LocationMetadata::HiveMetastoreVersion'->new($_) } @$_ ] };

declare 'MapStringHiveMetastoreVersion',
    as HashRef[HiveMetastoreVersion()];

declare 'DatabaseDumpSpec',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::DatabaseDumpSpec'];

coerce 'DatabaseDumpSpec',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::DatabaseDumpSpec'->new($_) };

declare 'RepeatedDatabaseDumpSpec',
    as ArrayRef[DatabaseDumpSpec()];

coerce 'RepeatedDatabaseDumpSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::DatabaseDumpSpec'->new($_) } @$_ ] };

declare 'MapStringDatabaseDumpSpec',
    as HashRef[DatabaseDumpSpec()];

declare 'Type',
    as (Int | Str);

declare 'RemoveIamPolicyRequest',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::RemoveIamPolicyRequest'];

coerce 'RemoveIamPolicyRequest',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::RemoveIamPolicyRequest'->new($_) };

declare 'RepeatedRemoveIamPolicyRequest',
    as ArrayRef[RemoveIamPolicyRequest()];

coerce 'RepeatedRemoveIamPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::RemoveIamPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringRemoveIamPolicyRequest',
    as HashRef[RemoveIamPolicyRequest()];

declare 'RemoveIamPolicyResponse',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::RemoveIamPolicyResponse'];

coerce 'RemoveIamPolicyResponse',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::RemoveIamPolicyResponse'->new($_) };

declare 'RepeatedRemoveIamPolicyResponse',
    as ArrayRef[RemoveIamPolicyResponse()];

coerce 'RepeatedRemoveIamPolicyResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::RemoveIamPolicyResponse'->new($_) } @$_ ] };

declare 'MapStringRemoveIamPolicyResponse',
    as HashRef[RemoveIamPolicyResponse()];

declare 'QueryMetadataRequest',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::QueryMetadataRequest'];

coerce 'QueryMetadataRequest',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::QueryMetadataRequest'->new($_) };

declare 'RepeatedQueryMetadataRequest',
    as ArrayRef[QueryMetadataRequest()];

coerce 'RepeatedQueryMetadataRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::QueryMetadataRequest'->new($_) } @$_ ] };

declare 'MapStringQueryMetadataRequest',
    as HashRef[QueryMetadataRequest()];

declare 'QueryMetadataResponse',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::QueryMetadataResponse'];

coerce 'QueryMetadataResponse',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::QueryMetadataResponse'->new($_) };

declare 'RepeatedQueryMetadataResponse',
    as ArrayRef[QueryMetadataResponse()];

coerce 'RepeatedQueryMetadataResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::QueryMetadataResponse'->new($_) } @$_ ] };

declare 'MapStringQueryMetadataResponse',
    as HashRef[QueryMetadataResponse()];

declare 'ErrorDetails',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::ErrorDetails'];

coerce 'ErrorDetails',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::ErrorDetails'->new($_) };

declare 'RepeatedErrorDetails',
    as ArrayRef[ErrorDetails()];

coerce 'RepeatedErrorDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::ErrorDetails'->new($_) } @$_ ] };

declare 'MapStringErrorDetails',
    as HashRef[ErrorDetails()];

declare 'DetailsEntry',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::ErrorDetails::DetailsEntry'];

coerce 'DetailsEntry',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::ErrorDetails::DetailsEntry'->new($_) };

declare 'RepeatedDetailsEntry',
    as ArrayRef[DetailsEntry()];

coerce 'RepeatedDetailsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::ErrorDetails::DetailsEntry'->new($_) } @$_ ] };

declare 'MapStringDetailsEntry',
    as HashRef[DetailsEntry()];

declare 'MoveTableToDatabaseRequest',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::MoveTableToDatabaseRequest'];

coerce 'MoveTableToDatabaseRequest',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::MoveTableToDatabaseRequest'->new($_) };

declare 'RepeatedMoveTableToDatabaseRequest',
    as ArrayRef[MoveTableToDatabaseRequest()];

coerce 'RepeatedMoveTableToDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::MoveTableToDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringMoveTableToDatabaseRequest',
    as HashRef[MoveTableToDatabaseRequest()];

declare 'MoveTableToDatabaseResponse',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::MoveTableToDatabaseResponse'];

coerce 'MoveTableToDatabaseResponse',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::MoveTableToDatabaseResponse'->new($_) };

declare 'RepeatedMoveTableToDatabaseResponse',
    as ArrayRef[MoveTableToDatabaseResponse()];

coerce 'RepeatedMoveTableToDatabaseResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::MoveTableToDatabaseResponse'->new($_) } @$_ ] };

declare 'MapStringMoveTableToDatabaseResponse',
    as HashRef[MoveTableToDatabaseResponse()];

declare 'AlterMetadataResourceLocationRequest',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::AlterMetadataResourceLocationRequest'];

coerce 'AlterMetadataResourceLocationRequest',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::AlterMetadataResourceLocationRequest'->new($_) };

declare 'RepeatedAlterMetadataResourceLocationRequest',
    as ArrayRef[AlterMetadataResourceLocationRequest()];

coerce 'RepeatedAlterMetadataResourceLocationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::AlterMetadataResourceLocationRequest'->new($_) } @$_ ] };

declare 'MapStringAlterMetadataResourceLocationRequest',
    as HashRef[AlterMetadataResourceLocationRequest()];

declare 'AlterMetadataResourceLocationResponse',
    as InstanceOf['Google::Cloud::Metastore::V1alpha::Metastore::AlterMetadataResourceLocationResponse'];

coerce 'AlterMetadataResourceLocationResponse',
    from HashRef, via { 'Google::Cloud::Metastore::V1alpha::Metastore::AlterMetadataResourceLocationResponse'->new($_) };

declare 'RepeatedAlterMetadataResourceLocationResponse',
    as ArrayRef[AlterMetadataResourceLocationResponse()];

coerce 'RepeatedAlterMetadataResourceLocationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::V1alpha::Metastore::AlterMetadataResourceLocationResponse'->new($_) } @$_ ] };

declare 'MapStringAlterMetadataResourceLocationResponse',
    as HashRef[AlterMetadataResourceLocationResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Metastore::V1alpha::Metastore::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
