package Google::Cloud::Alloydb::V1::Resources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'InstanceView',
    as (Int | Str);

declare 'ClusterView',
    as (Int | Str);

declare 'DatabaseVersion',
    as (Int | Str);

declare 'SubscriptionType',
    as (Int | Str);

declare 'UserPassword',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::UserPassword'];

coerce 'UserPassword',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::UserPassword'->new($_) };

declare 'RepeatedUserPassword',
    as ArrayRef[UserPassword()];

coerce 'RepeatedUserPassword',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::UserPassword'->new($_) } @$_ ] };

declare 'MapStringUserPassword',
    as HashRef[UserPassword()];

declare 'MigrationSource',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::MigrationSource'];

coerce 'MigrationSource',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::MigrationSource'->new($_) };

declare 'RepeatedMigrationSource',
    as ArrayRef[MigrationSource()];

coerce 'RepeatedMigrationSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::MigrationSource'->new($_) } @$_ ] };

declare 'MapStringMigrationSource',
    as HashRef[MigrationSource()];

declare 'MigrationSourceType',
    as (Int | Str);

declare 'EncryptionConfig',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::EncryptionConfig'];

coerce 'EncryptionConfig',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::EncryptionConfig'->new($_) };

declare 'RepeatedEncryptionConfig',
    as ArrayRef[EncryptionConfig()];

coerce 'RepeatedEncryptionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::EncryptionConfig'->new($_) } @$_ ] };

declare 'MapStringEncryptionConfig',
    as HashRef[EncryptionConfig()];

declare 'EncryptionInfo',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::EncryptionInfo'];

coerce 'EncryptionInfo',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::EncryptionInfo'->new($_) };

declare 'RepeatedEncryptionInfo',
    as ArrayRef[EncryptionInfo()];

coerce 'RepeatedEncryptionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::EncryptionInfo'->new($_) } @$_ ] };

declare 'MapStringEncryptionInfo',
    as HashRef[EncryptionInfo()];

declare 'Type',
    as (Int | Str);

declare 'SslConfig',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::SslConfig'];

coerce 'SslConfig',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::SslConfig'->new($_) };

declare 'RepeatedSslConfig',
    as ArrayRef[SslConfig()];

coerce 'RepeatedSslConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::SslConfig'->new($_) } @$_ ] };

declare 'MapStringSslConfig',
    as HashRef[SslConfig()];

declare 'SslMode',
    as (Int | Str);

declare 'CaSource',
    as (Int | Str);

declare 'AutomatedBackupPolicy',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::AutomatedBackupPolicy'];

coerce 'AutomatedBackupPolicy',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::AutomatedBackupPolicy'->new($_) };

declare 'RepeatedAutomatedBackupPolicy',
    as ArrayRef[AutomatedBackupPolicy()];

coerce 'RepeatedAutomatedBackupPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::AutomatedBackupPolicy'->new($_) } @$_ ] };

declare 'MapStringAutomatedBackupPolicy',
    as HashRef[AutomatedBackupPolicy()];

declare 'WeeklySchedule',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::AutomatedBackupPolicy::WeeklySchedule'];

coerce 'WeeklySchedule',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::AutomatedBackupPolicy::WeeklySchedule'->new($_) };

declare 'RepeatedWeeklySchedule',
    as ArrayRef[WeeklySchedule()];

coerce 'RepeatedWeeklySchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::AutomatedBackupPolicy::WeeklySchedule'->new($_) } @$_ ] };

declare 'MapStringWeeklySchedule',
    as HashRef[WeeklySchedule()];

declare 'TimeBasedRetention',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::AutomatedBackupPolicy::TimeBasedRetention'];

coerce 'TimeBasedRetention',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::AutomatedBackupPolicy::TimeBasedRetention'->new($_) };

declare 'RepeatedTimeBasedRetention',
    as ArrayRef[TimeBasedRetention()];

coerce 'RepeatedTimeBasedRetention',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::AutomatedBackupPolicy::TimeBasedRetention'->new($_) } @$_ ] };

declare 'MapStringTimeBasedRetention',
    as HashRef[TimeBasedRetention()];

declare 'QuantityBasedRetention',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::AutomatedBackupPolicy::QuantityBasedRetention'];

coerce 'QuantityBasedRetention',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::AutomatedBackupPolicy::QuantityBasedRetention'->new($_) };

declare 'RepeatedQuantityBasedRetention',
    as ArrayRef[QuantityBasedRetention()];

coerce 'RepeatedQuantityBasedRetention',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::AutomatedBackupPolicy::QuantityBasedRetention'->new($_) } @$_ ] };

declare 'MapStringQuantityBasedRetention',
    as HashRef[QuantityBasedRetention()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::AutomatedBackupPolicy::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::AutomatedBackupPolicy::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::AutomatedBackupPolicy::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ContinuousBackupConfig',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::ContinuousBackupConfig'];

coerce 'ContinuousBackupConfig',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::ContinuousBackupConfig'->new($_) };

declare 'RepeatedContinuousBackupConfig',
    as ArrayRef[ContinuousBackupConfig()];

coerce 'RepeatedContinuousBackupConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::ContinuousBackupConfig'->new($_) } @$_ ] };

declare 'MapStringContinuousBackupConfig',
    as HashRef[ContinuousBackupConfig()];

declare 'ContinuousBackupInfo',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::ContinuousBackupInfo'];

coerce 'ContinuousBackupInfo',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::ContinuousBackupInfo'->new($_) };

declare 'RepeatedContinuousBackupInfo',
    as ArrayRef[ContinuousBackupInfo()];

coerce 'RepeatedContinuousBackupInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::ContinuousBackupInfo'->new($_) } @$_ ] };

declare 'MapStringContinuousBackupInfo',
    as HashRef[ContinuousBackupInfo()];

declare 'BackupSource',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::BackupSource'];

coerce 'BackupSource',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::BackupSource'->new($_) };

declare 'RepeatedBackupSource',
    as ArrayRef[BackupSource()];

coerce 'RepeatedBackupSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::BackupSource'->new($_) } @$_ ] };

declare 'MapStringBackupSource',
    as HashRef[BackupSource()];

declare 'ContinuousBackupSource',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::ContinuousBackupSource'];

coerce 'ContinuousBackupSource',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::ContinuousBackupSource'->new($_) };

declare 'RepeatedContinuousBackupSource',
    as ArrayRef[ContinuousBackupSource()];

coerce 'RepeatedContinuousBackupSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::ContinuousBackupSource'->new($_) } @$_ ] };

declare 'MapStringContinuousBackupSource',
    as HashRef[ContinuousBackupSource()];

declare 'MaintenanceUpdatePolicy',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::MaintenanceUpdatePolicy'];

coerce 'MaintenanceUpdatePolicy',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::MaintenanceUpdatePolicy'->new($_) };

declare 'RepeatedMaintenanceUpdatePolicy',
    as ArrayRef[MaintenanceUpdatePolicy()];

coerce 'RepeatedMaintenanceUpdatePolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::MaintenanceUpdatePolicy'->new($_) } @$_ ] };

declare 'MapStringMaintenanceUpdatePolicy',
    as HashRef[MaintenanceUpdatePolicy()];

declare 'MaintenanceWindow',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::MaintenanceUpdatePolicy::MaintenanceWindow'];

coerce 'MaintenanceWindow',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::MaintenanceUpdatePolicy::MaintenanceWindow'->new($_) };

declare 'RepeatedMaintenanceWindow',
    as ArrayRef[MaintenanceWindow()];

coerce 'RepeatedMaintenanceWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::MaintenanceUpdatePolicy::MaintenanceWindow'->new($_) } @$_ ] };

declare 'MapStringMaintenanceWindow',
    as HashRef[MaintenanceWindow()];

declare 'DenyMaintenancePeriod',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::MaintenanceUpdatePolicy::DenyMaintenancePeriod'];

coerce 'DenyMaintenancePeriod',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::MaintenanceUpdatePolicy::DenyMaintenancePeriod'->new($_) };

declare 'RepeatedDenyMaintenancePeriod',
    as ArrayRef[DenyMaintenancePeriod()];

coerce 'RepeatedDenyMaintenancePeriod',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::MaintenanceUpdatePolicy::DenyMaintenancePeriod'->new($_) } @$_ ] };

declare 'MapStringDenyMaintenancePeriod',
    as HashRef[DenyMaintenancePeriod()];

declare 'MaintenanceSchedule',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::MaintenanceSchedule'];

coerce 'MaintenanceSchedule',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::MaintenanceSchedule'->new($_) };

declare 'RepeatedMaintenanceSchedule',
    as ArrayRef[MaintenanceSchedule()];

coerce 'RepeatedMaintenanceSchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::MaintenanceSchedule'->new($_) } @$_ ] };

declare 'MapStringMaintenanceSchedule',
    as HashRef[MaintenanceSchedule()];

declare 'Cluster',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Cluster'];

coerce 'Cluster',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Cluster'->new($_) };

declare 'RepeatedCluster',
    as ArrayRef[Cluster()];

coerce 'RepeatedCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Cluster'->new($_) } @$_ ] };

declare 'MapStringCluster',
    as HashRef[Cluster()];

declare 'State',
    as (Int | Str);

declare 'ClusterType',
    as (Int | Str);

declare 'NetworkConfig',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Cluster::NetworkConfig'];

coerce 'NetworkConfig',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Cluster::NetworkConfig'->new($_) };

declare 'RepeatedNetworkConfig',
    as ArrayRef[NetworkConfig()];

coerce 'RepeatedNetworkConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Cluster::NetworkConfig'->new($_) } @$_ ] };

declare 'MapStringNetworkConfig',
    as HashRef[NetworkConfig()];

declare 'SecondaryConfig',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Cluster::SecondaryConfig'];

coerce 'SecondaryConfig',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Cluster::SecondaryConfig'->new($_) };

declare 'RepeatedSecondaryConfig',
    as ArrayRef[SecondaryConfig()];

coerce 'RepeatedSecondaryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Cluster::SecondaryConfig'->new($_) } @$_ ] };

declare 'MapStringSecondaryConfig',
    as HashRef[SecondaryConfig()];

declare 'PrimaryConfig',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Cluster::PrimaryConfig'];

coerce 'PrimaryConfig',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Cluster::PrimaryConfig'->new($_) };

declare 'RepeatedPrimaryConfig',
    as ArrayRef[PrimaryConfig()];

coerce 'RepeatedPrimaryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Cluster::PrimaryConfig'->new($_) } @$_ ] };

declare 'MapStringPrimaryConfig',
    as HashRef[PrimaryConfig()];

declare 'PscConfig',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Cluster::PscConfig'];

coerce 'PscConfig',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Cluster::PscConfig'->new($_) };

declare 'RepeatedPscConfig',
    as ArrayRef[PscConfig()];

coerce 'RepeatedPscConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Cluster::PscConfig'->new($_) } @$_ ] };

declare 'MapStringPscConfig',
    as HashRef[PscConfig()];

declare 'TrialMetadata',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Cluster::TrialMetadata'];

coerce 'TrialMetadata',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Cluster::TrialMetadata'->new($_) };

declare 'RepeatedTrialMetadata',
    as ArrayRef[TrialMetadata()];

coerce 'RepeatedTrialMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Cluster::TrialMetadata'->new($_) } @$_ ] };

declare 'MapStringTrialMetadata',
    as HashRef[TrialMetadata()];

declare 'DataplexConfig',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Cluster::DataplexConfig'];

coerce 'DataplexConfig',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Cluster::DataplexConfig'->new($_) };

declare 'RepeatedDataplexConfig',
    as ArrayRef[DataplexConfig()];

coerce 'RepeatedDataplexConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Cluster::DataplexConfig'->new($_) } @$_ ] };

declare 'MapStringDataplexConfig',
    as HashRef[DataplexConfig()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Cluster::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Cluster::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Cluster::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Cluster::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Cluster::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Cluster::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'TagsEntry',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Cluster::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Cluster::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Cluster::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

declare 'Instance',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Instance'];

coerce 'Instance',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Instance'->new($_) };

declare 'RepeatedInstance',
    as ArrayRef[Instance()];

coerce 'RepeatedInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Instance'->new($_) } @$_ ] };

declare 'MapStringInstance',
    as HashRef[Instance()];

declare 'State',
    as (Int | Str);

declare 'InstanceType',
    as (Int | Str);

declare 'AvailabilityType',
    as (Int | Str);

declare 'ActivationPolicy',
    as (Int | Str);

declare 'MachineConfig',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Instance::MachineConfig'];

coerce 'MachineConfig',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Instance::MachineConfig'->new($_) };

declare 'RepeatedMachineConfig',
    as ArrayRef[MachineConfig()];

coerce 'RepeatedMachineConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Instance::MachineConfig'->new($_) } @$_ ] };

declare 'MapStringMachineConfig',
    as HashRef[MachineConfig()];

declare 'Node',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Instance::Node'];

coerce 'Node',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Instance::Node'->new($_) };

declare 'RepeatedNode',
    as ArrayRef[Node()];

coerce 'RepeatedNode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Instance::Node'->new($_) } @$_ ] };

declare 'MapStringNode',
    as HashRef[Node()];

declare 'QueryInsightsInstanceConfig',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Instance::QueryInsightsInstanceConfig'];

coerce 'QueryInsightsInstanceConfig',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Instance::QueryInsightsInstanceConfig'->new($_) };

declare 'RepeatedQueryInsightsInstanceConfig',
    as ArrayRef[QueryInsightsInstanceConfig()];

coerce 'RepeatedQueryInsightsInstanceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Instance::QueryInsightsInstanceConfig'->new($_) } @$_ ] };

declare 'MapStringQueryInsightsInstanceConfig',
    as HashRef[QueryInsightsInstanceConfig()];

declare 'QueryInsightsInstanceInfo',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Instance::QueryInsightsInstanceInfo'];

coerce 'QueryInsightsInstanceInfo',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Instance::QueryInsightsInstanceInfo'->new($_) };

declare 'RepeatedQueryInsightsInstanceInfo',
    as ArrayRef[QueryInsightsInstanceInfo()];

coerce 'RepeatedQueryInsightsInstanceInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Instance::QueryInsightsInstanceInfo'->new($_) } @$_ ] };

declare 'MapStringQueryInsightsInstanceInfo',
    as HashRef[QueryInsightsInstanceInfo()];

declare 'ObservabilityInstanceConfig',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Instance::ObservabilityInstanceConfig'];

coerce 'ObservabilityInstanceConfig',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Instance::ObservabilityInstanceConfig'->new($_) };

declare 'RepeatedObservabilityInstanceConfig',
    as ArrayRef[ObservabilityInstanceConfig()];

coerce 'RepeatedObservabilityInstanceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Instance::ObservabilityInstanceConfig'->new($_) } @$_ ] };

declare 'MapStringObservabilityInstanceConfig',
    as HashRef[ObservabilityInstanceConfig()];

declare 'ObservabilityInstanceInfo',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Instance::ObservabilityInstanceInfo'];

coerce 'ObservabilityInstanceInfo',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Instance::ObservabilityInstanceInfo'->new($_) };

declare 'RepeatedObservabilityInstanceInfo',
    as ArrayRef[ObservabilityInstanceInfo()];

coerce 'RepeatedObservabilityInstanceInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Instance::ObservabilityInstanceInfo'->new($_) } @$_ ] };

declare 'MapStringObservabilityInstanceInfo',
    as HashRef[ObservabilityInstanceInfo()];

declare 'ReadPoolConfig',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Instance::ReadPoolConfig'];

coerce 'ReadPoolConfig',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Instance::ReadPoolConfig'->new($_) };

declare 'RepeatedReadPoolConfig',
    as ArrayRef[ReadPoolConfig()];

coerce 'RepeatedReadPoolConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Instance::ReadPoolConfig'->new($_) } @$_ ] };

declare 'MapStringReadPoolConfig',
    as HashRef[ReadPoolConfig()];

declare 'ClientConnectionConfig',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Instance::ClientConnectionConfig'];

coerce 'ClientConnectionConfig',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Instance::ClientConnectionConfig'->new($_) };

declare 'RepeatedClientConnectionConfig',
    as ArrayRef[ClientConnectionConfig()];

coerce 'RepeatedClientConnectionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Instance::ClientConnectionConfig'->new($_) } @$_ ] };

declare 'MapStringClientConnectionConfig',
    as HashRef[ClientConnectionConfig()];

declare 'PscInterfaceConfig',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Instance::PscInterfaceConfig'];

coerce 'PscInterfaceConfig',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Instance::PscInterfaceConfig'->new($_) };

declare 'RepeatedPscInterfaceConfig',
    as ArrayRef[PscInterfaceConfig()];

coerce 'RepeatedPscInterfaceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Instance::PscInterfaceConfig'->new($_) } @$_ ] };

declare 'MapStringPscInterfaceConfig',
    as HashRef[PscInterfaceConfig()];

declare 'PscAutoConnectionConfig',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Instance::PscAutoConnectionConfig'];

coerce 'PscAutoConnectionConfig',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Instance::PscAutoConnectionConfig'->new($_) };

declare 'RepeatedPscAutoConnectionConfig',
    as ArrayRef[PscAutoConnectionConfig()];

coerce 'RepeatedPscAutoConnectionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Instance::PscAutoConnectionConfig'->new($_) } @$_ ] };

declare 'MapStringPscAutoConnectionConfig',
    as HashRef[PscAutoConnectionConfig()];

declare 'PscInstanceConfig',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Instance::PscInstanceConfig'];

coerce 'PscInstanceConfig',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Instance::PscInstanceConfig'->new($_) };

declare 'RepeatedPscInstanceConfig',
    as ArrayRef[PscInstanceConfig()];

coerce 'RepeatedPscInstanceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Instance::PscInstanceConfig'->new($_) } @$_ ] };

declare 'MapStringPscInstanceConfig',
    as HashRef[PscInstanceConfig()];

declare 'InstanceNetworkConfig',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Instance::InstanceNetworkConfig'];

coerce 'InstanceNetworkConfig',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Instance::InstanceNetworkConfig'->new($_) };

declare 'RepeatedInstanceNetworkConfig',
    as ArrayRef[InstanceNetworkConfig()];

coerce 'RepeatedInstanceNetworkConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Instance::InstanceNetworkConfig'->new($_) } @$_ ] };

declare 'MapStringInstanceNetworkConfig',
    as HashRef[InstanceNetworkConfig()];

declare 'AuthorizedNetwork',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Instance::InstanceNetworkConfig::AuthorizedNetwork'];

coerce 'AuthorizedNetwork',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Instance::InstanceNetworkConfig::AuthorizedNetwork'->new($_) };

declare 'RepeatedAuthorizedNetwork',
    as ArrayRef[AuthorizedNetwork()];

coerce 'RepeatedAuthorizedNetwork',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Instance::InstanceNetworkConfig::AuthorizedNetwork'->new($_) } @$_ ] };

declare 'MapStringAuthorizedNetwork',
    as HashRef[AuthorizedNetwork()];

declare 'ConnectionPoolConfig',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Instance::ConnectionPoolConfig'];

coerce 'ConnectionPoolConfig',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Instance::ConnectionPoolConfig'->new($_) };

declare 'RepeatedConnectionPoolConfig',
    as ArrayRef[ConnectionPoolConfig()];

coerce 'RepeatedConnectionPoolConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Instance::ConnectionPoolConfig'->new($_) } @$_ ] };

declare 'MapStringConnectionPoolConfig',
    as HashRef[ConnectionPoolConfig()];

declare 'FlagsEntry',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Instance::ConnectionPoolConfig::FlagsEntry'];

coerce 'FlagsEntry',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Instance::ConnectionPoolConfig::FlagsEntry'->new($_) };

declare 'RepeatedFlagsEntry',
    as ArrayRef[FlagsEntry()];

coerce 'RepeatedFlagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Instance::ConnectionPoolConfig::FlagsEntry'->new($_) } @$_ ] };

declare 'MapStringFlagsEntry',
    as HashRef[FlagsEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Instance::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Instance::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Instance::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'DatabaseFlagsEntry',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Instance::DatabaseFlagsEntry'];

coerce 'DatabaseFlagsEntry',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Instance::DatabaseFlagsEntry'->new($_) };

declare 'RepeatedDatabaseFlagsEntry',
    as ArrayRef[DatabaseFlagsEntry()];

coerce 'RepeatedDatabaseFlagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Instance::DatabaseFlagsEntry'->new($_) } @$_ ] };

declare 'MapStringDatabaseFlagsEntry',
    as HashRef[DatabaseFlagsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Instance::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Instance::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Instance::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'ConnectionInfo',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::ConnectionInfo'];

coerce 'ConnectionInfo',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::ConnectionInfo'->new($_) };

declare 'RepeatedConnectionInfo',
    as ArrayRef[ConnectionInfo()];

coerce 'RepeatedConnectionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::ConnectionInfo'->new($_) } @$_ ] };

declare 'MapStringConnectionInfo',
    as HashRef[ConnectionInfo()];

declare 'Backup',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Backup'];

coerce 'Backup',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Backup'->new($_) };

declare 'RepeatedBackup',
    as ArrayRef[Backup()];

coerce 'RepeatedBackup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Backup'->new($_) } @$_ ] };

declare 'MapStringBackup',
    as HashRef[Backup()];

declare 'State',
    as (Int | Str);

declare 'Type',
    as (Int | Str);

declare 'QuantityBasedExpiry',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Backup::QuantityBasedExpiry'];

coerce 'QuantityBasedExpiry',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Backup::QuantityBasedExpiry'->new($_) };

declare 'RepeatedQuantityBasedExpiry',
    as ArrayRef[QuantityBasedExpiry()];

coerce 'RepeatedQuantityBasedExpiry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Backup::QuantityBasedExpiry'->new($_) } @$_ ] };

declare 'MapStringQuantityBasedExpiry',
    as HashRef[QuantityBasedExpiry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Backup::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Backup::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Backup::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Backup::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Backup::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Backup::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'TagsEntry',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Backup::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Backup::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Backup::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

declare 'SupportedDatabaseFlag',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::SupportedDatabaseFlag'];

coerce 'SupportedDatabaseFlag',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::SupportedDatabaseFlag'->new($_) };

declare 'RepeatedSupportedDatabaseFlag',
    as ArrayRef[SupportedDatabaseFlag()];

coerce 'RepeatedSupportedDatabaseFlag',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::SupportedDatabaseFlag'->new($_) } @$_ ] };

declare 'MapStringSupportedDatabaseFlag',
    as HashRef[SupportedDatabaseFlag()];

declare 'ValueType',
    as (Int | Str);

declare 'Scope',
    as (Int | Str);

declare 'StringRestrictions',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::SupportedDatabaseFlag::StringRestrictions'];

coerce 'StringRestrictions',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::SupportedDatabaseFlag::StringRestrictions'->new($_) };

declare 'RepeatedStringRestrictions',
    as ArrayRef[StringRestrictions()];

coerce 'RepeatedStringRestrictions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::SupportedDatabaseFlag::StringRestrictions'->new($_) } @$_ ] };

declare 'MapStringStringRestrictions',
    as HashRef[StringRestrictions()];

declare 'IntegerRestrictions',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::SupportedDatabaseFlag::IntegerRestrictions'];

coerce 'IntegerRestrictions',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::SupportedDatabaseFlag::IntegerRestrictions'->new($_) };

declare 'RepeatedIntegerRestrictions',
    as ArrayRef[IntegerRestrictions()];

coerce 'RepeatedIntegerRestrictions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::SupportedDatabaseFlag::IntegerRestrictions'->new($_) } @$_ ] };

declare 'MapStringIntegerRestrictions',
    as HashRef[IntegerRestrictions()];

declare 'User',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::User'];

coerce 'User',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::User'->new($_) };

declare 'RepeatedUser',
    as ArrayRef[User()];

coerce 'RepeatedUser',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::User'->new($_) } @$_ ] };

declare 'MapStringUser',
    as HashRef[User()];

declare 'UserType',
    as (Int | Str);

declare 'Database',
    as InstanceOf['Google::Cloud::Alloydb::V1::Resources::Database'];

coerce 'Database',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::Resources::Database'->new($_) };

declare 'RepeatedDatabase',
    as ArrayRef[Database()];

coerce 'RepeatedDatabase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::Resources::Database'->new($_) } @$_ ] };

declare 'MapStringDatabase',
    as HashRef[Database()];

1;

__END__

=head1 NAME

Google::Cloud::Alloydb::V1::Resources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
