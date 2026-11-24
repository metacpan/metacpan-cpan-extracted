package Google::Cloud::Clouddms::V1::ClouddmsResources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'NetworkArchitecture',
    as (Int | Str);

declare 'DatabaseEngine',
    as (Int | Str);

declare 'DatabaseProvider',
    as (Int | Str);

declare 'SslConfig',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::SslConfig'];

coerce 'SslConfig',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::SslConfig'->new($_) };

declare 'RepeatedSslConfig',
    as ArrayRef[SslConfig()];

coerce 'RepeatedSslConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::SslConfig'->new($_) } @$_ ] };

declare 'MapStringSslConfig',
    as HashRef[SslConfig()];

declare 'SslType',
    as (Int | Str);

declare 'MySqlConnectionProfile',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::MySqlConnectionProfile'];

coerce 'MySqlConnectionProfile',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::MySqlConnectionProfile'->new($_) };

declare 'RepeatedMySqlConnectionProfile',
    as ArrayRef[MySqlConnectionProfile()];

coerce 'RepeatedMySqlConnectionProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::MySqlConnectionProfile'->new($_) } @$_ ] };

declare 'MapStringMySqlConnectionProfile',
    as HashRef[MySqlConnectionProfile()];

declare 'PostgreSqlConnectionProfile',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::PostgreSqlConnectionProfile'];

coerce 'PostgreSqlConnectionProfile',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::PostgreSqlConnectionProfile'->new($_) };

declare 'RepeatedPostgreSqlConnectionProfile',
    as ArrayRef[PostgreSqlConnectionProfile()];

coerce 'RepeatedPostgreSqlConnectionProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::PostgreSqlConnectionProfile'->new($_) } @$_ ] };

declare 'MapStringPostgreSqlConnectionProfile',
    as HashRef[PostgreSqlConnectionProfile()];

declare 'OracleConnectionProfile',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::OracleConnectionProfile'];

coerce 'OracleConnectionProfile',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::OracleConnectionProfile'->new($_) };

declare 'RepeatedOracleConnectionProfile',
    as ArrayRef[OracleConnectionProfile()];

coerce 'RepeatedOracleConnectionProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::OracleConnectionProfile'->new($_) } @$_ ] };

declare 'MapStringOracleConnectionProfile',
    as HashRef[OracleConnectionProfile()];

declare 'CloudSqlConnectionProfile',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::CloudSqlConnectionProfile'];

coerce 'CloudSqlConnectionProfile',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::CloudSqlConnectionProfile'->new($_) };

declare 'RepeatedCloudSqlConnectionProfile',
    as ArrayRef[CloudSqlConnectionProfile()];

coerce 'RepeatedCloudSqlConnectionProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::CloudSqlConnectionProfile'->new($_) } @$_ ] };

declare 'MapStringCloudSqlConnectionProfile',
    as HashRef[CloudSqlConnectionProfile()];

declare 'AlloyDbConnectionProfile',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::AlloyDbConnectionProfile'];

coerce 'AlloyDbConnectionProfile',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::AlloyDbConnectionProfile'->new($_) };

declare 'RepeatedAlloyDbConnectionProfile',
    as ArrayRef[AlloyDbConnectionProfile()];

coerce 'RepeatedAlloyDbConnectionProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::AlloyDbConnectionProfile'->new($_) } @$_ ] };

declare 'MapStringAlloyDbConnectionProfile',
    as HashRef[AlloyDbConnectionProfile()];

declare 'SqlAclEntry',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::SqlAclEntry'];

coerce 'SqlAclEntry',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::SqlAclEntry'->new($_) };

declare 'RepeatedSqlAclEntry',
    as ArrayRef[SqlAclEntry()];

coerce 'RepeatedSqlAclEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::SqlAclEntry'->new($_) } @$_ ] };

declare 'MapStringSqlAclEntry',
    as HashRef[SqlAclEntry()];

declare 'SqlIpConfig',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::SqlIpConfig'];

coerce 'SqlIpConfig',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::SqlIpConfig'->new($_) };

declare 'RepeatedSqlIpConfig',
    as ArrayRef[SqlIpConfig()];

coerce 'RepeatedSqlIpConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::SqlIpConfig'->new($_) } @$_ ] };

declare 'MapStringSqlIpConfig',
    as HashRef[SqlIpConfig()];

declare 'CloudSqlSettings',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::CloudSqlSettings'];

coerce 'CloudSqlSettings',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::CloudSqlSettings'->new($_) };

declare 'RepeatedCloudSqlSettings',
    as ArrayRef[CloudSqlSettings()];

coerce 'RepeatedCloudSqlSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::CloudSqlSettings'->new($_) } @$_ ] };

declare 'MapStringCloudSqlSettings',
    as HashRef[CloudSqlSettings()];

declare 'SqlActivationPolicy',
    as (Int | Str);

declare 'SqlDataDiskType',
    as (Int | Str);

declare 'SqlDatabaseVersion',
    as (Int | Str);

declare 'SqlAvailabilityType',
    as (Int | Str);

declare 'Edition',
    as (Int | Str);

declare 'UserLabelsEntry',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::CloudSqlSettings::UserLabelsEntry'];

coerce 'UserLabelsEntry',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::CloudSqlSettings::UserLabelsEntry'->new($_) };

declare 'RepeatedUserLabelsEntry',
    as ArrayRef[UserLabelsEntry()];

coerce 'RepeatedUserLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::CloudSqlSettings::UserLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringUserLabelsEntry',
    as HashRef[UserLabelsEntry()];

declare 'DatabaseFlagsEntry',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::CloudSqlSettings::DatabaseFlagsEntry'];

coerce 'DatabaseFlagsEntry',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::CloudSqlSettings::DatabaseFlagsEntry'->new($_) };

declare 'RepeatedDatabaseFlagsEntry',
    as ArrayRef[DatabaseFlagsEntry()];

coerce 'RepeatedDatabaseFlagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::CloudSqlSettings::DatabaseFlagsEntry'->new($_) } @$_ ] };

declare 'MapStringDatabaseFlagsEntry',
    as HashRef[DatabaseFlagsEntry()];

declare 'AlloyDbSettings',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::AlloyDbSettings'];

coerce 'AlloyDbSettings',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::AlloyDbSettings'->new($_) };

declare 'RepeatedAlloyDbSettings',
    as ArrayRef[AlloyDbSettings()];

coerce 'RepeatedAlloyDbSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::AlloyDbSettings'->new($_) } @$_ ] };

declare 'MapStringAlloyDbSettings',
    as HashRef[AlloyDbSettings()];

declare 'UserPassword',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::AlloyDbSettings::UserPassword'];

coerce 'UserPassword',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::AlloyDbSettings::UserPassword'->new($_) };

declare 'RepeatedUserPassword',
    as ArrayRef[UserPassword()];

coerce 'RepeatedUserPassword',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::AlloyDbSettings::UserPassword'->new($_) } @$_ ] };

declare 'MapStringUserPassword',
    as HashRef[UserPassword()];

declare 'PrimaryInstanceSettings',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::AlloyDbSettings::PrimaryInstanceSettings'];

coerce 'PrimaryInstanceSettings',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::AlloyDbSettings::PrimaryInstanceSettings'->new($_) };

declare 'RepeatedPrimaryInstanceSettings',
    as ArrayRef[PrimaryInstanceSettings()];

coerce 'RepeatedPrimaryInstanceSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::AlloyDbSettings::PrimaryInstanceSettings'->new($_) } @$_ ] };

declare 'MapStringPrimaryInstanceSettings',
    as HashRef[PrimaryInstanceSettings()];

declare 'MachineConfig',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::AlloyDbSettings::PrimaryInstanceSettings::MachineConfig'];

coerce 'MachineConfig',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::AlloyDbSettings::PrimaryInstanceSettings::MachineConfig'->new($_) };

declare 'RepeatedMachineConfig',
    as ArrayRef[MachineConfig()];

coerce 'RepeatedMachineConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::AlloyDbSettings::PrimaryInstanceSettings::MachineConfig'->new($_) } @$_ ] };

declare 'MapStringMachineConfig',
    as HashRef[MachineConfig()];

declare 'DatabaseFlagsEntry',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::AlloyDbSettings::PrimaryInstanceSettings::DatabaseFlagsEntry'];

coerce 'DatabaseFlagsEntry',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::AlloyDbSettings::PrimaryInstanceSettings::DatabaseFlagsEntry'->new($_) };

declare 'RepeatedDatabaseFlagsEntry',
    as ArrayRef[DatabaseFlagsEntry()];

coerce 'RepeatedDatabaseFlagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::AlloyDbSettings::PrimaryInstanceSettings::DatabaseFlagsEntry'->new($_) } @$_ ] };

declare 'MapStringDatabaseFlagsEntry',
    as HashRef[DatabaseFlagsEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::AlloyDbSettings::PrimaryInstanceSettings::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::AlloyDbSettings::PrimaryInstanceSettings::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::AlloyDbSettings::PrimaryInstanceSettings::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'EncryptionConfig',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::AlloyDbSettings::EncryptionConfig'];

coerce 'EncryptionConfig',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::AlloyDbSettings::EncryptionConfig'->new($_) };

declare 'RepeatedEncryptionConfig',
    as ArrayRef[EncryptionConfig()];

coerce 'RepeatedEncryptionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::AlloyDbSettings::EncryptionConfig'->new($_) } @$_ ] };

declare 'MapStringEncryptionConfig',
    as HashRef[EncryptionConfig()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::AlloyDbSettings::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::AlloyDbSettings::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::AlloyDbSettings::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'StaticIpConnectivity',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::StaticIpConnectivity'];

coerce 'StaticIpConnectivity',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::StaticIpConnectivity'->new($_) };

declare 'RepeatedStaticIpConnectivity',
    as ArrayRef[StaticIpConnectivity()];

coerce 'RepeatedStaticIpConnectivity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::StaticIpConnectivity'->new($_) } @$_ ] };

declare 'MapStringStaticIpConnectivity',
    as HashRef[StaticIpConnectivity()];

declare 'PrivateServiceConnectConnectivity',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::PrivateServiceConnectConnectivity'];

coerce 'PrivateServiceConnectConnectivity',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::PrivateServiceConnectConnectivity'->new($_) };

declare 'RepeatedPrivateServiceConnectConnectivity',
    as ArrayRef[PrivateServiceConnectConnectivity()];

coerce 'RepeatedPrivateServiceConnectConnectivity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::PrivateServiceConnectConnectivity'->new($_) } @$_ ] };

declare 'MapStringPrivateServiceConnectConnectivity',
    as HashRef[PrivateServiceConnectConnectivity()];

declare 'ReverseSshConnectivity',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::ReverseSshConnectivity'];

coerce 'ReverseSshConnectivity',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::ReverseSshConnectivity'->new($_) };

declare 'RepeatedReverseSshConnectivity',
    as ArrayRef[ReverseSshConnectivity()];

coerce 'RepeatedReverseSshConnectivity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::ReverseSshConnectivity'->new($_) } @$_ ] };

declare 'MapStringReverseSshConnectivity',
    as HashRef[ReverseSshConnectivity()];

declare 'VpcPeeringConnectivity',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::VpcPeeringConnectivity'];

coerce 'VpcPeeringConnectivity',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::VpcPeeringConnectivity'->new($_) };

declare 'RepeatedVpcPeeringConnectivity',
    as ArrayRef[VpcPeeringConnectivity()];

coerce 'RepeatedVpcPeeringConnectivity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::VpcPeeringConnectivity'->new($_) } @$_ ] };

declare 'MapStringVpcPeeringConnectivity',
    as HashRef[VpcPeeringConnectivity()];

declare 'ForwardSshTunnelConnectivity',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::ForwardSshTunnelConnectivity'];

coerce 'ForwardSshTunnelConnectivity',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::ForwardSshTunnelConnectivity'->new($_) };

declare 'RepeatedForwardSshTunnelConnectivity',
    as ArrayRef[ForwardSshTunnelConnectivity()];

coerce 'RepeatedForwardSshTunnelConnectivity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::ForwardSshTunnelConnectivity'->new($_) } @$_ ] };

declare 'MapStringForwardSshTunnelConnectivity',
    as HashRef[ForwardSshTunnelConnectivity()];

declare 'StaticServiceIpConnectivity',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::StaticServiceIpConnectivity'];

coerce 'StaticServiceIpConnectivity',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::StaticServiceIpConnectivity'->new($_) };

declare 'RepeatedStaticServiceIpConnectivity',
    as ArrayRef[StaticServiceIpConnectivity()];

coerce 'RepeatedStaticServiceIpConnectivity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::StaticServiceIpConnectivity'->new($_) } @$_ ] };

declare 'MapStringStaticServiceIpConnectivity',
    as HashRef[StaticServiceIpConnectivity()];

declare 'PrivateConnectivity',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::PrivateConnectivity'];

coerce 'PrivateConnectivity',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::PrivateConnectivity'->new($_) };

declare 'RepeatedPrivateConnectivity',
    as ArrayRef[PrivateConnectivity()];

coerce 'RepeatedPrivateConnectivity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::PrivateConnectivity'->new($_) } @$_ ] };

declare 'MapStringPrivateConnectivity',
    as HashRef[PrivateConnectivity()];

declare 'DatabaseType',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::DatabaseType'];

coerce 'DatabaseType',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::DatabaseType'->new($_) };

declare 'RepeatedDatabaseType',
    as ArrayRef[DatabaseType()];

coerce 'RepeatedDatabaseType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::DatabaseType'->new($_) } @$_ ] };

declare 'MapStringDatabaseType',
    as HashRef[DatabaseType()];

declare 'MigrationJob',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::MigrationJob'];

coerce 'MigrationJob',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::MigrationJob'->new($_) };

declare 'RepeatedMigrationJob',
    as ArrayRef[MigrationJob()];

coerce 'RepeatedMigrationJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::MigrationJob'->new($_) } @$_ ] };

declare 'MapStringMigrationJob',
    as HashRef[MigrationJob()];

declare 'State',
    as (Int | Str);

declare 'Phase',
    as (Int | Str);

declare 'Type',
    as (Int | Str);

declare 'DumpFlag',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::MigrationJob::DumpFlag'];

coerce 'DumpFlag',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::MigrationJob::DumpFlag'->new($_) };

declare 'RepeatedDumpFlag',
    as ArrayRef[DumpFlag()];

coerce 'RepeatedDumpFlag',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::MigrationJob::DumpFlag'->new($_) } @$_ ] };

declare 'MapStringDumpFlag',
    as HashRef[DumpFlag()];

declare 'DumpFlags',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::MigrationJob::DumpFlags'];

coerce 'DumpFlags',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::MigrationJob::DumpFlags'->new($_) };

declare 'RepeatedDumpFlags',
    as ArrayRef[DumpFlags()];

coerce 'RepeatedDumpFlags',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::MigrationJob::DumpFlags'->new($_) } @$_ ] };

declare 'MapStringDumpFlags',
    as HashRef[DumpFlags()];

declare 'PerformanceConfig',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::MigrationJob::PerformanceConfig'];

coerce 'PerformanceConfig',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::MigrationJob::PerformanceConfig'->new($_) };

declare 'RepeatedPerformanceConfig',
    as ArrayRef[PerformanceConfig()];

coerce 'RepeatedPerformanceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::MigrationJob::PerformanceConfig'->new($_) } @$_ ] };

declare 'MapStringPerformanceConfig',
    as HashRef[PerformanceConfig()];

declare 'DumpParallelLevel',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::MigrationJob::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::MigrationJob::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::MigrationJob::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ConversionWorkspaceInfo',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::ConversionWorkspaceInfo'];

coerce 'ConversionWorkspaceInfo',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::ConversionWorkspaceInfo'->new($_) };

declare 'RepeatedConversionWorkspaceInfo',
    as ArrayRef[ConversionWorkspaceInfo()];

coerce 'RepeatedConversionWorkspaceInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::ConversionWorkspaceInfo'->new($_) } @$_ ] };

declare 'MapStringConversionWorkspaceInfo',
    as HashRef[ConversionWorkspaceInfo()];

declare 'ConnectionProfile',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::ConnectionProfile'];

coerce 'ConnectionProfile',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::ConnectionProfile'->new($_) };

declare 'RepeatedConnectionProfile',
    as ArrayRef[ConnectionProfile()];

coerce 'RepeatedConnectionProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::ConnectionProfile'->new($_) } @$_ ] };

declare 'MapStringConnectionProfile',
    as HashRef[ConnectionProfile()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::ConnectionProfile::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::ConnectionProfile::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::ConnectionProfile::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'MigrationJobVerificationError',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::MigrationJobVerificationError'];

coerce 'MigrationJobVerificationError',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::MigrationJobVerificationError'->new($_) };

declare 'RepeatedMigrationJobVerificationError',
    as ArrayRef[MigrationJobVerificationError()];

coerce 'RepeatedMigrationJobVerificationError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::MigrationJobVerificationError'->new($_) } @$_ ] };

declare 'MapStringMigrationJobVerificationError',
    as HashRef[MigrationJobVerificationError()];

declare 'ErrorCode',
    as (Int | Str);

declare 'PrivateConnection',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::PrivateConnection'];

coerce 'PrivateConnection',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::PrivateConnection'->new($_) };

declare 'RepeatedPrivateConnection',
    as ArrayRef[PrivateConnection()];

coerce 'RepeatedPrivateConnection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::PrivateConnection'->new($_) } @$_ ] };

declare 'MapStringPrivateConnection',
    as HashRef[PrivateConnection()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::PrivateConnection::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::PrivateConnection::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::PrivateConnection::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'VpcPeeringConfig',
    as InstanceOf['Google::Cloud::Clouddms::V1::ClouddmsResources::VpcPeeringConfig'];

coerce 'VpcPeeringConfig',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::ClouddmsResources::VpcPeeringConfig'->new($_) };

declare 'RepeatedVpcPeeringConfig',
    as ArrayRef[VpcPeeringConfig()];

coerce 'RepeatedVpcPeeringConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::ClouddmsResources::VpcPeeringConfig'->new($_) } @$_ ] };

declare 'MapStringVpcPeeringConfig',
    as HashRef[VpcPeeringConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Clouddms::V1::ClouddmsResources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
