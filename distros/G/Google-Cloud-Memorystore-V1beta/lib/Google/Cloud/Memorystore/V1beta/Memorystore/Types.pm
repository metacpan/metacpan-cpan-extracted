package Google::Cloud::Memorystore::V1beta::Memorystore::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PscConnectionStatus',
    as (Int | Str);

declare 'ConnectionType',
    as (Int | Str);

declare 'IpVersion',
    as (Int | Str);

declare 'Instance',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::Instance'];

coerce 'Instance',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::Instance'->new($_) };

declare 'RepeatedInstance',
    as ArrayRef[Instance()];

coerce 'RepeatedInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::Instance'->new($_) } @$_ ] };

declare 'MapStringInstance',
    as HashRef[Instance()];

declare 'State',
    as (Int | Str);

declare 'AuthorizationMode',
    as (Int | Str);

declare 'TransitEncryptionMode',
    as (Int | Str);

declare 'NodeType',
    as (Int | Str);

declare 'Mode',
    as (Int | Str);

declare 'ServerCaMode',
    as (Int | Str);

declare 'StateInfo',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::Instance::StateInfo'];

coerce 'StateInfo',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::Instance::StateInfo'->new($_) };

declare 'RepeatedStateInfo',
    as ArrayRef[StateInfo()];

coerce 'RepeatedStateInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::Instance::StateInfo'->new($_) } @$_ ] };

declare 'MapStringStateInfo',
    as HashRef[StateInfo()];

declare 'UpdateInfo',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::Instance::StateInfo::UpdateInfo'];

coerce 'UpdateInfo',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::Instance::StateInfo::UpdateInfo'->new($_) };

declare 'RepeatedUpdateInfo',
    as ArrayRef[UpdateInfo()];

coerce 'RepeatedUpdateInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::Instance::StateInfo::UpdateInfo'->new($_) } @$_ ] };

declare 'MapStringUpdateInfo',
    as HashRef[UpdateInfo()];

declare 'GcsBackupSource',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::Instance::GcsBackupSource'];

coerce 'GcsBackupSource',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::Instance::GcsBackupSource'->new($_) };

declare 'RepeatedGcsBackupSource',
    as ArrayRef[GcsBackupSource()];

coerce 'RepeatedGcsBackupSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::Instance::GcsBackupSource'->new($_) } @$_ ] };

declare 'MapStringGcsBackupSource',
    as HashRef[GcsBackupSource()];

declare 'ManagedBackupSource',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::Instance::ManagedBackupSource'];

coerce 'ManagedBackupSource',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::Instance::ManagedBackupSource'->new($_) };

declare 'RepeatedManagedBackupSource',
    as ArrayRef[ManagedBackupSource()];

coerce 'RepeatedManagedBackupSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::Instance::ManagedBackupSource'->new($_) } @$_ ] };

declare 'MapStringManagedBackupSource',
    as HashRef[ManagedBackupSource()];

declare 'InstanceEndpoint',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::Instance::InstanceEndpoint'];

coerce 'InstanceEndpoint',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::Instance::InstanceEndpoint'->new($_) };

declare 'RepeatedInstanceEndpoint',
    as ArrayRef[InstanceEndpoint()];

coerce 'RepeatedInstanceEndpoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::Instance::InstanceEndpoint'->new($_) } @$_ ] };

declare 'MapStringInstanceEndpoint',
    as HashRef[InstanceEndpoint()];

declare 'ConnectionDetail',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::Instance::ConnectionDetail'];

coerce 'ConnectionDetail',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::Instance::ConnectionDetail'->new($_) };

declare 'RepeatedConnectionDetail',
    as ArrayRef[ConnectionDetail()];

coerce 'RepeatedConnectionDetail',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::Instance::ConnectionDetail'->new($_) } @$_ ] };

declare 'MapStringConnectionDetail',
    as HashRef[ConnectionDetail()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::Instance::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::Instance::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::Instance::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'EngineConfigsEntry',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::Instance::EngineConfigsEntry'];

coerce 'EngineConfigsEntry',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::Instance::EngineConfigsEntry'->new($_) };

declare 'RepeatedEngineConfigsEntry',
    as ArrayRef[EngineConfigsEntry()];

coerce 'RepeatedEngineConfigsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::Instance::EngineConfigsEntry'->new($_) } @$_ ] };

declare 'MapStringEngineConfigsEntry',
    as HashRef[EngineConfigsEntry()];

declare 'AclPolicyInfo',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::AclPolicyInfo'];

coerce 'AclPolicyInfo',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::AclPolicyInfo'->new($_) };

declare 'RepeatedAclPolicyInfo',
    as ArrayRef[AclPolicyInfo()];

coerce 'RepeatedAclPolicyInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::AclPolicyInfo'->new($_) } @$_ ] };

declare 'MapStringAclPolicyInfo',
    as HashRef[AclPolicyInfo()];

declare 'StartMigrationRequest',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::StartMigrationRequest'];

coerce 'StartMigrationRequest',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::StartMigrationRequest'->new($_) };

declare 'RepeatedStartMigrationRequest',
    as ArrayRef[StartMigrationRequest()];

coerce 'RepeatedStartMigrationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::StartMigrationRequest'->new($_) } @$_ ] };

declare 'MapStringStartMigrationRequest',
    as HashRef[StartMigrationRequest()];

declare 'FinishMigrationRequest',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::FinishMigrationRequest'];

coerce 'FinishMigrationRequest',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::FinishMigrationRequest'->new($_) };

declare 'RepeatedFinishMigrationRequest',
    as ArrayRef[FinishMigrationRequest()];

coerce 'RepeatedFinishMigrationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::FinishMigrationRequest'->new($_) } @$_ ] };

declare 'MapStringFinishMigrationRequest',
    as HashRef[FinishMigrationRequest()];

declare 'SelfManagedSource',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::SelfManagedSource'];

coerce 'SelfManagedSource',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::SelfManagedSource'->new($_) };

declare 'RepeatedSelfManagedSource',
    as ArrayRef[SelfManagedSource()];

coerce 'RepeatedSelfManagedSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::SelfManagedSource'->new($_) } @$_ ] };

declare 'MapStringSelfManagedSource',
    as HashRef[SelfManagedSource()];

declare 'MigrationConfig',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::MigrationConfig'];

coerce 'MigrationConfig',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::MigrationConfig'->new($_) };

declare 'RepeatedMigrationConfig',
    as ArrayRef[MigrationConfig()];

coerce 'RepeatedMigrationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::MigrationConfig'->new($_) } @$_ ] };

declare 'MapStringMigrationConfig',
    as HashRef[MigrationConfig()];

declare 'State',
    as (Int | Str);

declare 'AclPolicy',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::AclPolicy'];

coerce 'AclPolicy',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::AclPolicy'->new($_) };

declare 'RepeatedAclPolicy',
    as ArrayRef[AclPolicy()];

coerce 'RepeatedAclPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::AclPolicy'->new($_) } @$_ ] };

declare 'MapStringAclPolicy',
    as HashRef[AclPolicy()];

declare 'State',
    as (Int | Str);

declare 'AclPolicyRevision',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::AclPolicyRevision'];

coerce 'AclPolicyRevision',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::AclPolicyRevision'->new($_) };

declare 'RepeatedAclPolicyRevision',
    as ArrayRef[AclPolicyRevision()];

coerce 'RepeatedAclPolicyRevision',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::AclPolicyRevision'->new($_) } @$_ ] };

declare 'MapStringAclPolicyRevision',
    as HashRef[AclPolicyRevision()];

declare 'AclPolicyRevisionStatus',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::AclPolicyRevisionStatus'];

coerce 'AclPolicyRevisionStatus',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::AclPolicyRevisionStatus'->new($_) };

declare 'RepeatedAclPolicyRevisionStatus',
    as ArrayRef[AclPolicyRevisionStatus()];

coerce 'RepeatedAclPolicyRevisionStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::AclPolicyRevisionStatus'->new($_) } @$_ ] };

declare 'MapStringAclPolicyRevisionStatus',
    as HashRef[AclPolicyRevisionStatus()];

declare 'State',
    as (Int | Str);

declare 'InstanceAclPolicyAttachment',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::InstanceAclPolicyAttachment'];

coerce 'InstanceAclPolicyAttachment',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::InstanceAclPolicyAttachment'->new($_) };

declare 'RepeatedInstanceAclPolicyAttachment',
    as ArrayRef[InstanceAclPolicyAttachment()];

coerce 'RepeatedInstanceAclPolicyAttachment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::InstanceAclPolicyAttachment'->new($_) } @$_ ] };

declare 'MapStringInstanceAclPolicyAttachment',
    as HashRef[InstanceAclPolicyAttachment()];

declare 'AclRule',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::AclRule'];

coerce 'AclRule',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::AclRule'->new($_) };

declare 'RepeatedAclRule',
    as ArrayRef[AclRule()];

coerce 'RepeatedAclRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::AclRule'->new($_) } @$_ ] };

declare 'MapStringAclRule',
    as HashRef[AclRule()];

declare 'AutomatedBackupConfig',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::AutomatedBackupConfig'];

coerce 'AutomatedBackupConfig',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::AutomatedBackupConfig'->new($_) };

declare 'RepeatedAutomatedBackupConfig',
    as ArrayRef[AutomatedBackupConfig()];

coerce 'RepeatedAutomatedBackupConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::AutomatedBackupConfig'->new($_) } @$_ ] };

declare 'MapStringAutomatedBackupConfig',
    as HashRef[AutomatedBackupConfig()];

declare 'AutomatedBackupMode',
    as (Int | Str);

declare 'FixedFrequencySchedule',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::AutomatedBackupConfig::FixedFrequencySchedule'];

coerce 'FixedFrequencySchedule',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::AutomatedBackupConfig::FixedFrequencySchedule'->new($_) };

declare 'RepeatedFixedFrequencySchedule',
    as ArrayRef[FixedFrequencySchedule()];

coerce 'RepeatedFixedFrequencySchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::AutomatedBackupConfig::FixedFrequencySchedule'->new($_) } @$_ ] };

declare 'MapStringFixedFrequencySchedule',
    as HashRef[FixedFrequencySchedule()];

declare 'BackupCollection',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::BackupCollection'];

coerce 'BackupCollection',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::BackupCollection'->new($_) };

declare 'RepeatedBackupCollection',
    as ArrayRef[BackupCollection()];

coerce 'RepeatedBackupCollection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::BackupCollection'->new($_) } @$_ ] };

declare 'MapStringBackupCollection',
    as HashRef[BackupCollection()];

declare 'Backup',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::Backup'];

coerce 'Backup',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::Backup'->new($_) };

declare 'RepeatedBackup',
    as ArrayRef[Backup()];

coerce 'RepeatedBackup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::Backup'->new($_) } @$_ ] };

declare 'MapStringBackup',
    as HashRef[Backup()];

declare 'BackupType',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'BackupFile',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::BackupFile'];

coerce 'BackupFile',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::BackupFile'->new($_) };

declare 'RepeatedBackupFile',
    as ArrayRef[BackupFile()];

coerce 'RepeatedBackupFile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::BackupFile'->new($_) } @$_ ] };

declare 'MapStringBackupFile',
    as HashRef[BackupFile()];

declare 'CrossInstanceReplicationConfig',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::CrossInstanceReplicationConfig'];

coerce 'CrossInstanceReplicationConfig',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::CrossInstanceReplicationConfig'->new($_) };

declare 'RepeatedCrossInstanceReplicationConfig',
    as ArrayRef[CrossInstanceReplicationConfig()];

coerce 'RepeatedCrossInstanceReplicationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::CrossInstanceReplicationConfig'->new($_) } @$_ ] };

declare 'MapStringCrossInstanceReplicationConfig',
    as HashRef[CrossInstanceReplicationConfig()];

declare 'InstanceRole',
    as (Int | Str);

declare 'RemoteInstance',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::CrossInstanceReplicationConfig::RemoteInstance'];

coerce 'RemoteInstance',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::CrossInstanceReplicationConfig::RemoteInstance'->new($_) };

declare 'RepeatedRemoteInstance',
    as ArrayRef[RemoteInstance()];

coerce 'RepeatedRemoteInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::CrossInstanceReplicationConfig::RemoteInstance'->new($_) } @$_ ] };

declare 'MapStringRemoteInstance',
    as HashRef[RemoteInstance()];

declare 'Membership',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::CrossInstanceReplicationConfig::Membership'];

coerce 'Membership',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::CrossInstanceReplicationConfig::Membership'->new($_) };

declare 'RepeatedMembership',
    as ArrayRef[Membership()];

coerce 'RepeatedMembership',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::CrossInstanceReplicationConfig::Membership'->new($_) } @$_ ] };

declare 'MapStringMembership',
    as HashRef[Membership()];

declare 'TokenAuthUser',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::TokenAuthUser'];

coerce 'TokenAuthUser',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::TokenAuthUser'->new($_) };

declare 'RepeatedTokenAuthUser',
    as ArrayRef[TokenAuthUser()];

coerce 'RepeatedTokenAuthUser',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::TokenAuthUser'->new($_) } @$_ ] };

declare 'MapStringTokenAuthUser',
    as HashRef[TokenAuthUser()];

declare 'State',
    as (Int | Str);

declare 'AuthToken',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::AuthToken'];

coerce 'AuthToken',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::AuthToken'->new($_) };

declare 'RepeatedAuthToken',
    as ArrayRef[AuthToken()];

coerce 'RepeatedAuthToken',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::AuthToken'->new($_) } @$_ ] };

declare 'MapStringAuthToken',
    as HashRef[AuthToken()];

declare 'State',
    as (Int | Str);

declare 'MaintenancePolicy',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::MaintenancePolicy'];

coerce 'MaintenancePolicy',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::MaintenancePolicy'->new($_) };

declare 'RepeatedMaintenancePolicy',
    as ArrayRef[MaintenancePolicy()];

coerce 'RepeatedMaintenancePolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::MaintenancePolicy'->new($_) } @$_ ] };

declare 'MapStringMaintenancePolicy',
    as HashRef[MaintenancePolicy()];

declare 'WeeklyMaintenanceWindow',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::WeeklyMaintenanceWindow'];

coerce 'WeeklyMaintenanceWindow',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::WeeklyMaintenanceWindow'->new($_) };

declare 'RepeatedWeeklyMaintenanceWindow',
    as ArrayRef[WeeklyMaintenanceWindow()];

coerce 'RepeatedWeeklyMaintenanceWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::WeeklyMaintenanceWindow'->new($_) } @$_ ] };

declare 'MapStringWeeklyMaintenanceWindow',
    as HashRef[WeeklyMaintenanceWindow()];

declare 'MaintenanceSchedule',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::MaintenanceSchedule'];

coerce 'MaintenanceSchedule',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::MaintenanceSchedule'->new($_) };

declare 'RepeatedMaintenanceSchedule',
    as ArrayRef[MaintenanceSchedule()];

coerce 'RepeatedMaintenanceSchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::MaintenanceSchedule'->new($_) } @$_ ] };

declare 'MapStringMaintenanceSchedule',
    as HashRef[MaintenanceSchedule()];

declare 'PscAttachmentDetail',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::PscAttachmentDetail'];

coerce 'PscAttachmentDetail',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::PscAttachmentDetail'->new($_) };

declare 'RepeatedPscAttachmentDetail',
    as ArrayRef[PscAttachmentDetail()];

coerce 'RepeatedPscAttachmentDetail',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::PscAttachmentDetail'->new($_) } @$_ ] };

declare 'MapStringPscAttachmentDetail',
    as HashRef[PscAttachmentDetail()];

declare 'PscAutoConnection',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::PscAutoConnection'];

coerce 'PscAutoConnection',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::PscAutoConnection'->new($_) };

declare 'RepeatedPscAutoConnection',
    as ArrayRef[PscAutoConnection()];

coerce 'RepeatedPscAutoConnection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::PscAutoConnection'->new($_) } @$_ ] };

declare 'MapStringPscAutoConnection',
    as HashRef[PscAutoConnection()];

declare 'PscConnection',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::PscConnection'];

coerce 'PscConnection',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::PscConnection'->new($_) };

declare 'RepeatedPscConnection',
    as ArrayRef[PscConnection()];

coerce 'RepeatedPscConnection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::PscConnection'->new($_) } @$_ ] };

declare 'MapStringPscConnection',
    as HashRef[PscConnection()];

declare 'DiscoveryEndpoint',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::DiscoveryEndpoint'];

coerce 'DiscoveryEndpoint',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::DiscoveryEndpoint'->new($_) };

declare 'RepeatedDiscoveryEndpoint',
    as ArrayRef[DiscoveryEndpoint()];

coerce 'RepeatedDiscoveryEndpoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::DiscoveryEndpoint'->new($_) } @$_ ] };

declare 'MapStringDiscoveryEndpoint',
    as HashRef[DiscoveryEndpoint()];

declare 'PersistenceConfig',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::PersistenceConfig'];

coerce 'PersistenceConfig',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::PersistenceConfig'->new($_) };

declare 'RepeatedPersistenceConfig',
    as ArrayRef[PersistenceConfig()];

coerce 'RepeatedPersistenceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::PersistenceConfig'->new($_) } @$_ ] };

declare 'MapStringPersistenceConfig',
    as HashRef[PersistenceConfig()];

declare 'PersistenceMode',
    as (Int | Str);

declare 'RDBConfig',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::PersistenceConfig::RDBConfig'];

coerce 'RDBConfig',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::PersistenceConfig::RDBConfig'->new($_) };

declare 'RepeatedRDBConfig',
    as ArrayRef[RDBConfig()];

coerce 'RepeatedRDBConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::PersistenceConfig::RDBConfig'->new($_) } @$_ ] };

declare 'MapStringRDBConfig',
    as HashRef[RDBConfig()];

declare 'SnapshotPeriod',
    as (Int | Str);

declare 'AOFConfig',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::PersistenceConfig::AOFConfig'];

coerce 'AOFConfig',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::PersistenceConfig::AOFConfig'->new($_) };

declare 'RepeatedAOFConfig',
    as ArrayRef[AOFConfig()];

coerce 'RepeatedAOFConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::PersistenceConfig::AOFConfig'->new($_) } @$_ ] };

declare 'MapStringAOFConfig',
    as HashRef[AOFConfig()];

declare 'AppendFsync',
    as (Int | Str);

declare 'NodeConfig',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::NodeConfig'];

coerce 'NodeConfig',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::NodeConfig'->new($_) };

declare 'RepeatedNodeConfig',
    as ArrayRef[NodeConfig()];

coerce 'RepeatedNodeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::NodeConfig'->new($_) } @$_ ] };

declare 'MapStringNodeConfig',
    as HashRef[NodeConfig()];

declare 'ZoneDistributionConfig',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::ZoneDistributionConfig'];

coerce 'ZoneDistributionConfig',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::ZoneDistributionConfig'->new($_) };

declare 'RepeatedZoneDistributionConfig',
    as ArrayRef[ZoneDistributionConfig()];

coerce 'RepeatedZoneDistributionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::ZoneDistributionConfig'->new($_) } @$_ ] };

declare 'MapStringZoneDistributionConfig',
    as HashRef[ZoneDistributionConfig()];

declare 'ZoneDistributionMode',
    as (Int | Str);

declare 'RescheduleMaintenanceRequest',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::RescheduleMaintenanceRequest'];

coerce 'RescheduleMaintenanceRequest',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::RescheduleMaintenanceRequest'->new($_) };

declare 'RepeatedRescheduleMaintenanceRequest',
    as ArrayRef[RescheduleMaintenanceRequest()];

coerce 'RepeatedRescheduleMaintenanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::RescheduleMaintenanceRequest'->new($_) } @$_ ] };

declare 'MapStringRescheduleMaintenanceRequest',
    as HashRef[RescheduleMaintenanceRequest()];

declare 'RescheduleType',
    as (Int | Str);

declare 'ListAclPoliciesRequest',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::ListAclPoliciesRequest'];

coerce 'ListAclPoliciesRequest',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::ListAclPoliciesRequest'->new($_) };

declare 'RepeatedListAclPoliciesRequest',
    as ArrayRef[ListAclPoliciesRequest()];

coerce 'RepeatedListAclPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::ListAclPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringListAclPoliciesRequest',
    as HashRef[ListAclPoliciesRequest()];

declare 'ListAclPoliciesResponse',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::ListAclPoliciesResponse'];

coerce 'ListAclPoliciesResponse',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::ListAclPoliciesResponse'->new($_) };

declare 'RepeatedListAclPoliciesResponse',
    as ArrayRef[ListAclPoliciesResponse()];

coerce 'RepeatedListAclPoliciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::ListAclPoliciesResponse'->new($_) } @$_ ] };

declare 'MapStringListAclPoliciesResponse',
    as HashRef[ListAclPoliciesResponse()];

declare 'ListAclPolicyRevisionsRequest',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::ListAclPolicyRevisionsRequest'];

coerce 'ListAclPolicyRevisionsRequest',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::ListAclPolicyRevisionsRequest'->new($_) };

declare 'RepeatedListAclPolicyRevisionsRequest',
    as ArrayRef[ListAclPolicyRevisionsRequest()];

coerce 'RepeatedListAclPolicyRevisionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::ListAclPolicyRevisionsRequest'->new($_) } @$_ ] };

declare 'MapStringListAclPolicyRevisionsRequest',
    as HashRef[ListAclPolicyRevisionsRequest()];

declare 'ListAclPolicyRevisionsResponse',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::ListAclPolicyRevisionsResponse'];

coerce 'ListAclPolicyRevisionsResponse',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::ListAclPolicyRevisionsResponse'->new($_) };

declare 'RepeatedListAclPolicyRevisionsResponse',
    as ArrayRef[ListAclPolicyRevisionsResponse()];

coerce 'RepeatedListAclPolicyRevisionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::ListAclPolicyRevisionsResponse'->new($_) } @$_ ] };

declare 'MapStringListAclPolicyRevisionsResponse',
    as HashRef[ListAclPolicyRevisionsResponse()];

declare 'ListInstancesRequest',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::ListInstancesRequest'];

coerce 'ListInstancesRequest',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::ListInstancesRequest'->new($_) };

declare 'RepeatedListInstancesRequest',
    as ArrayRef[ListInstancesRequest()];

coerce 'RepeatedListInstancesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::ListInstancesRequest'->new($_) } @$_ ] };

declare 'MapStringListInstancesRequest',
    as HashRef[ListInstancesRequest()];

declare 'ListInstancesResponse',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::ListInstancesResponse'];

coerce 'ListInstancesResponse',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::ListInstancesResponse'->new($_) };

declare 'RepeatedListInstancesResponse',
    as ArrayRef[ListInstancesResponse()];

coerce 'RepeatedListInstancesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::ListInstancesResponse'->new($_) } @$_ ] };

declare 'MapStringListInstancesResponse',
    as HashRef[ListInstancesResponse()];

declare 'GetAclPolicyRequest',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::GetAclPolicyRequest'];

coerce 'GetAclPolicyRequest',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::GetAclPolicyRequest'->new($_) };

declare 'RepeatedGetAclPolicyRequest',
    as ArrayRef[GetAclPolicyRequest()];

coerce 'RepeatedGetAclPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::GetAclPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetAclPolicyRequest',
    as HashRef[GetAclPolicyRequest()];

declare 'GetAclPolicyRevisionRequest',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::GetAclPolicyRevisionRequest'];

coerce 'GetAclPolicyRevisionRequest',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::GetAclPolicyRevisionRequest'->new($_) };

declare 'RepeatedGetAclPolicyRevisionRequest',
    as ArrayRef[GetAclPolicyRevisionRequest()];

coerce 'RepeatedGetAclPolicyRevisionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::GetAclPolicyRevisionRequest'->new($_) } @$_ ] };

declare 'MapStringGetAclPolicyRevisionRequest',
    as HashRef[GetAclPolicyRevisionRequest()];

declare 'GetInstanceRequest',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::GetInstanceRequest'];

coerce 'GetInstanceRequest',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::GetInstanceRequest'->new($_) };

declare 'RepeatedGetInstanceRequest',
    as ArrayRef[GetInstanceRequest()];

coerce 'RepeatedGetInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::GetInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringGetInstanceRequest',
    as HashRef[GetInstanceRequest()];

declare 'CreateAclPolicyRequest',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::CreateAclPolicyRequest'];

coerce 'CreateAclPolicyRequest',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::CreateAclPolicyRequest'->new($_) };

declare 'RepeatedCreateAclPolicyRequest',
    as ArrayRef[CreateAclPolicyRequest()];

coerce 'RepeatedCreateAclPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::CreateAclPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAclPolicyRequest',
    as HashRef[CreateAclPolicyRequest()];

declare 'CreateInstanceRequest',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::CreateInstanceRequest'];

coerce 'CreateInstanceRequest',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::CreateInstanceRequest'->new($_) };

declare 'RepeatedCreateInstanceRequest',
    as ArrayRef[CreateInstanceRequest()];

coerce 'RepeatedCreateInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::CreateInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateInstanceRequest',
    as HashRef[CreateInstanceRequest()];

declare 'UpdateAclPolicyRequest',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::UpdateAclPolicyRequest'];

coerce 'UpdateAclPolicyRequest',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::UpdateAclPolicyRequest'->new($_) };

declare 'RepeatedUpdateAclPolicyRequest',
    as ArrayRef[UpdateAclPolicyRequest()];

coerce 'RepeatedUpdateAclPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::UpdateAclPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAclPolicyRequest',
    as HashRef[UpdateAclPolicyRequest()];

declare 'UpdateInstanceRequest',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::UpdateInstanceRequest'];

coerce 'UpdateInstanceRequest',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::UpdateInstanceRequest'->new($_) };

declare 'RepeatedUpdateInstanceRequest',
    as ArrayRef[UpdateInstanceRequest()];

coerce 'RepeatedUpdateInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::UpdateInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateInstanceRequest',
    as HashRef[UpdateInstanceRequest()];

declare 'DeleteAclPolicyRequest',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::DeleteAclPolicyRequest'];

coerce 'DeleteAclPolicyRequest',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::DeleteAclPolicyRequest'->new($_) };

declare 'RepeatedDeleteAclPolicyRequest',
    as ArrayRef[DeleteAclPolicyRequest()];

coerce 'RepeatedDeleteAclPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::DeleteAclPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAclPolicyRequest',
    as HashRef[DeleteAclPolicyRequest()];

declare 'DeleteInstanceRequest',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::DeleteInstanceRequest'];

coerce 'DeleteInstanceRequest',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::DeleteInstanceRequest'->new($_) };

declare 'RepeatedDeleteInstanceRequest',
    as ArrayRef[DeleteInstanceRequest()];

coerce 'RepeatedDeleteInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::DeleteInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteInstanceRequest',
    as HashRef[DeleteInstanceRequest()];

declare 'ListBackupCollectionsRequest',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::ListBackupCollectionsRequest'];

coerce 'ListBackupCollectionsRequest',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::ListBackupCollectionsRequest'->new($_) };

declare 'RepeatedListBackupCollectionsRequest',
    as ArrayRef[ListBackupCollectionsRequest()];

coerce 'RepeatedListBackupCollectionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::ListBackupCollectionsRequest'->new($_) } @$_ ] };

declare 'MapStringListBackupCollectionsRequest',
    as HashRef[ListBackupCollectionsRequest()];

declare 'ListBackupCollectionsResponse',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::ListBackupCollectionsResponse'];

coerce 'ListBackupCollectionsResponse',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::ListBackupCollectionsResponse'->new($_) };

declare 'RepeatedListBackupCollectionsResponse',
    as ArrayRef[ListBackupCollectionsResponse()];

coerce 'RepeatedListBackupCollectionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::ListBackupCollectionsResponse'->new($_) } @$_ ] };

declare 'MapStringListBackupCollectionsResponse',
    as HashRef[ListBackupCollectionsResponse()];

declare 'GetBackupCollectionRequest',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::GetBackupCollectionRequest'];

coerce 'GetBackupCollectionRequest',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::GetBackupCollectionRequest'->new($_) };

declare 'RepeatedGetBackupCollectionRequest',
    as ArrayRef[GetBackupCollectionRequest()];

coerce 'RepeatedGetBackupCollectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::GetBackupCollectionRequest'->new($_) } @$_ ] };

declare 'MapStringGetBackupCollectionRequest',
    as HashRef[GetBackupCollectionRequest()];

declare 'ListBackupsRequest',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::ListBackupsRequest'];

coerce 'ListBackupsRequest',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::ListBackupsRequest'->new($_) };

declare 'RepeatedListBackupsRequest',
    as ArrayRef[ListBackupsRequest()];

coerce 'RepeatedListBackupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::ListBackupsRequest'->new($_) } @$_ ] };

declare 'MapStringListBackupsRequest',
    as HashRef[ListBackupsRequest()];

declare 'ListBackupsResponse',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::ListBackupsResponse'];

coerce 'ListBackupsResponse',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::ListBackupsResponse'->new($_) };

declare 'RepeatedListBackupsResponse',
    as ArrayRef[ListBackupsResponse()];

coerce 'RepeatedListBackupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::ListBackupsResponse'->new($_) } @$_ ] };

declare 'MapStringListBackupsResponse',
    as HashRef[ListBackupsResponse()];

declare 'GetBackupRequest',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::GetBackupRequest'];

coerce 'GetBackupRequest',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::GetBackupRequest'->new($_) };

declare 'RepeatedGetBackupRequest',
    as ArrayRef[GetBackupRequest()];

coerce 'RepeatedGetBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::GetBackupRequest'->new($_) } @$_ ] };

declare 'MapStringGetBackupRequest',
    as HashRef[GetBackupRequest()];

declare 'DeleteBackupRequest',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::DeleteBackupRequest'];

coerce 'DeleteBackupRequest',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::DeleteBackupRequest'->new($_) };

declare 'RepeatedDeleteBackupRequest',
    as ArrayRef[DeleteBackupRequest()];

coerce 'RepeatedDeleteBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::DeleteBackupRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBackupRequest',
    as HashRef[DeleteBackupRequest()];

declare 'ExportBackupRequest',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::ExportBackupRequest'];

coerce 'ExportBackupRequest',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::ExportBackupRequest'->new($_) };

declare 'RepeatedExportBackupRequest',
    as ArrayRef[ExportBackupRequest()];

coerce 'RepeatedExportBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::ExportBackupRequest'->new($_) } @$_ ] };

declare 'MapStringExportBackupRequest',
    as HashRef[ExportBackupRequest()];

declare 'BackupInstanceRequest',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::BackupInstanceRequest'];

coerce 'BackupInstanceRequest',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::BackupInstanceRequest'->new($_) };

declare 'RepeatedBackupInstanceRequest',
    as ArrayRef[BackupInstanceRequest()];

coerce 'RepeatedBackupInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::BackupInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringBackupInstanceRequest',
    as HashRef[BackupInstanceRequest()];

declare 'GetCertificateAuthorityRequest',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::GetCertificateAuthorityRequest'];

coerce 'GetCertificateAuthorityRequest',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::GetCertificateAuthorityRequest'->new($_) };

declare 'RepeatedGetCertificateAuthorityRequest',
    as ArrayRef[GetCertificateAuthorityRequest()];

coerce 'RepeatedGetCertificateAuthorityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::GetCertificateAuthorityRequest'->new($_) } @$_ ] };

declare 'MapStringGetCertificateAuthorityRequest',
    as HashRef[GetCertificateAuthorityRequest()];

declare 'ListTokenAuthUsersRequest',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::ListTokenAuthUsersRequest'];

coerce 'ListTokenAuthUsersRequest',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::ListTokenAuthUsersRequest'->new($_) };

declare 'RepeatedListTokenAuthUsersRequest',
    as ArrayRef[ListTokenAuthUsersRequest()];

coerce 'RepeatedListTokenAuthUsersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::ListTokenAuthUsersRequest'->new($_) } @$_ ] };

declare 'MapStringListTokenAuthUsersRequest',
    as HashRef[ListTokenAuthUsersRequest()];

declare 'ListTokenAuthUsersResponse',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::ListTokenAuthUsersResponse'];

coerce 'ListTokenAuthUsersResponse',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::ListTokenAuthUsersResponse'->new($_) };

declare 'RepeatedListTokenAuthUsersResponse',
    as ArrayRef[ListTokenAuthUsersResponse()];

coerce 'RepeatedListTokenAuthUsersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::ListTokenAuthUsersResponse'->new($_) } @$_ ] };

declare 'MapStringListTokenAuthUsersResponse',
    as HashRef[ListTokenAuthUsersResponse()];

declare 'GetTokenAuthUserRequest',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::GetTokenAuthUserRequest'];

coerce 'GetTokenAuthUserRequest',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::GetTokenAuthUserRequest'->new($_) };

declare 'RepeatedGetTokenAuthUserRequest',
    as ArrayRef[GetTokenAuthUserRequest()];

coerce 'RepeatedGetTokenAuthUserRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::GetTokenAuthUserRequest'->new($_) } @$_ ] };

declare 'MapStringGetTokenAuthUserRequest',
    as HashRef[GetTokenAuthUserRequest()];

declare 'ListAuthTokensRequest',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::ListAuthTokensRequest'];

coerce 'ListAuthTokensRequest',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::ListAuthTokensRequest'->new($_) };

declare 'RepeatedListAuthTokensRequest',
    as ArrayRef[ListAuthTokensRequest()];

coerce 'RepeatedListAuthTokensRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::ListAuthTokensRequest'->new($_) } @$_ ] };

declare 'MapStringListAuthTokensRequest',
    as HashRef[ListAuthTokensRequest()];

declare 'ListAuthTokensResponse',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::ListAuthTokensResponse'];

coerce 'ListAuthTokensResponse',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::ListAuthTokensResponse'->new($_) };

declare 'RepeatedListAuthTokensResponse',
    as ArrayRef[ListAuthTokensResponse()];

coerce 'RepeatedListAuthTokensResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::ListAuthTokensResponse'->new($_) } @$_ ] };

declare 'MapStringListAuthTokensResponse',
    as HashRef[ListAuthTokensResponse()];

declare 'GetAuthTokenRequest',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::GetAuthTokenRequest'];

coerce 'GetAuthTokenRequest',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::GetAuthTokenRequest'->new($_) };

declare 'RepeatedGetAuthTokenRequest',
    as ArrayRef[GetAuthTokenRequest()];

coerce 'RepeatedGetAuthTokenRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::GetAuthTokenRequest'->new($_) } @$_ ] };

declare 'MapStringGetAuthTokenRequest',
    as HashRef[GetAuthTokenRequest()];

declare 'AddTokenAuthUserRequest',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::AddTokenAuthUserRequest'];

coerce 'AddTokenAuthUserRequest',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::AddTokenAuthUserRequest'->new($_) };

declare 'RepeatedAddTokenAuthUserRequest',
    as ArrayRef[AddTokenAuthUserRequest()];

coerce 'RepeatedAddTokenAuthUserRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::AddTokenAuthUserRequest'->new($_) } @$_ ] };

declare 'MapStringAddTokenAuthUserRequest',
    as HashRef[AddTokenAuthUserRequest()];

declare 'DeleteTokenAuthUserRequest',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::DeleteTokenAuthUserRequest'];

coerce 'DeleteTokenAuthUserRequest',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::DeleteTokenAuthUserRequest'->new($_) };

declare 'RepeatedDeleteTokenAuthUserRequest',
    as ArrayRef[DeleteTokenAuthUserRequest()];

coerce 'RepeatedDeleteTokenAuthUserRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::DeleteTokenAuthUserRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTokenAuthUserRequest',
    as HashRef[DeleteTokenAuthUserRequest()];

declare 'AddAuthTokenRequest',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::AddAuthTokenRequest'];

coerce 'AddAuthTokenRequest',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::AddAuthTokenRequest'->new($_) };

declare 'RepeatedAddAuthTokenRequest',
    as ArrayRef[AddAuthTokenRequest()];

coerce 'RepeatedAddAuthTokenRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::AddAuthTokenRequest'->new($_) } @$_ ] };

declare 'MapStringAddAuthTokenRequest',
    as HashRef[AddAuthTokenRequest()];

declare 'DeleteAuthTokenRequest',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::DeleteAuthTokenRequest'];

coerce 'DeleteAuthTokenRequest',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::DeleteAuthTokenRequest'->new($_) };

declare 'RepeatedDeleteAuthTokenRequest',
    as ArrayRef[DeleteAuthTokenRequest()];

coerce 'RepeatedDeleteAuthTokenRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::DeleteAuthTokenRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAuthTokenRequest',
    as HashRef[DeleteAuthTokenRequest()];

declare 'CertificateAuthority',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::CertificateAuthority'];

coerce 'CertificateAuthority',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::CertificateAuthority'->new($_) };

declare 'RepeatedCertificateAuthority',
    as ArrayRef[CertificateAuthority()];

coerce 'RepeatedCertificateAuthority',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::CertificateAuthority'->new($_) } @$_ ] };

declare 'MapStringCertificateAuthority',
    as HashRef[CertificateAuthority()];

declare 'ManagedCertificateAuthority',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::CertificateAuthority::ManagedCertificateAuthority'];

coerce 'ManagedCertificateAuthority',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::CertificateAuthority::ManagedCertificateAuthority'->new($_) };

declare 'RepeatedManagedCertificateAuthority',
    as ArrayRef[ManagedCertificateAuthority()];

coerce 'RepeatedManagedCertificateAuthority',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::CertificateAuthority::ManagedCertificateAuthority'->new($_) } @$_ ] };

declare 'MapStringManagedCertificateAuthority',
    as HashRef[ManagedCertificateAuthority()];

declare 'CertChain',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::CertificateAuthority::ManagedCertificateAuthority::CertChain'];

coerce 'CertChain',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::CertificateAuthority::ManagedCertificateAuthority::CertChain'->new($_) };

declare 'RepeatedCertChain',
    as ArrayRef[CertChain()];

coerce 'RepeatedCertChain',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::CertificateAuthority::ManagedCertificateAuthority::CertChain'->new($_) } @$_ ] };

declare 'MapStringCertChain',
    as HashRef[CertChain()];

declare 'SharedRegionalCertificateAuthority',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::SharedRegionalCertificateAuthority'];

coerce 'SharedRegionalCertificateAuthority',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::SharedRegionalCertificateAuthority'->new($_) };

declare 'RepeatedSharedRegionalCertificateAuthority',
    as ArrayRef[SharedRegionalCertificateAuthority()];

coerce 'RepeatedSharedRegionalCertificateAuthority',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::SharedRegionalCertificateAuthority'->new($_) } @$_ ] };

declare 'MapStringSharedRegionalCertificateAuthority',
    as HashRef[SharedRegionalCertificateAuthority()];

declare 'RegionalManagedCertificateAuthority',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::SharedRegionalCertificateAuthority::RegionalManagedCertificateAuthority'];

coerce 'RegionalManagedCertificateAuthority',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::SharedRegionalCertificateAuthority::RegionalManagedCertificateAuthority'->new($_) };

declare 'RepeatedRegionalManagedCertificateAuthority',
    as ArrayRef[RegionalManagedCertificateAuthority()];

coerce 'RepeatedRegionalManagedCertificateAuthority',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::SharedRegionalCertificateAuthority::RegionalManagedCertificateAuthority'->new($_) } @$_ ] };

declare 'MapStringRegionalManagedCertificateAuthority',
    as HashRef[RegionalManagedCertificateAuthority()];

declare 'RegionalCertChain',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::SharedRegionalCertificateAuthority::RegionalManagedCertificateAuthority::RegionalCertChain'];

coerce 'RegionalCertChain',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::SharedRegionalCertificateAuthority::RegionalManagedCertificateAuthority::RegionalCertChain'->new($_) };

declare 'RepeatedRegionalCertChain',
    as ArrayRef[RegionalCertChain()];

coerce 'RepeatedRegionalCertChain',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::SharedRegionalCertificateAuthority::RegionalManagedCertificateAuthority::RegionalCertChain'->new($_) } @$_ ] };

declare 'MapStringRegionalCertChain',
    as HashRef[RegionalCertChain()];

declare 'GetSharedRegionalCertificateAuthorityRequest',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::GetSharedRegionalCertificateAuthorityRequest'];

coerce 'GetSharedRegionalCertificateAuthorityRequest',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::GetSharedRegionalCertificateAuthorityRequest'->new($_) };

declare 'RepeatedGetSharedRegionalCertificateAuthorityRequest',
    as ArrayRef[GetSharedRegionalCertificateAuthorityRequest()];

coerce 'RepeatedGetSharedRegionalCertificateAuthorityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::GetSharedRegionalCertificateAuthorityRequest'->new($_) } @$_ ] };

declare 'MapStringGetSharedRegionalCertificateAuthorityRequest',
    as HashRef[GetSharedRegionalCertificateAuthorityRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'EncryptionInfo',
    as InstanceOf['Google::Cloud::Memorystore::V1beta::Memorystore::EncryptionInfo'];

coerce 'EncryptionInfo',
    from HashRef, via { 'Google::Cloud::Memorystore::V1beta::Memorystore::EncryptionInfo'->new($_) };

declare 'RepeatedEncryptionInfo',
    as ArrayRef[EncryptionInfo()];

coerce 'RepeatedEncryptionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memorystore::V1beta::Memorystore::EncryptionInfo'->new($_) } @$_ ] };

declare 'MapStringEncryptionInfo',
    as HashRef[EncryptionInfo()];

declare 'Type',
    as (Int | Str);

declare 'KmsKeyState',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Memorystore::V1beta::Memorystore::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
