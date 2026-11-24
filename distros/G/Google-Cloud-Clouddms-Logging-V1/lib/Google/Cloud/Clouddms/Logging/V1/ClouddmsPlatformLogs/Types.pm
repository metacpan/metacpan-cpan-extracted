package Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DatabaseEngine',
    as (Int | Str);

declare 'DatabaseProvider',
    as (Int | Str);

declare 'DatabaseType',
    as InstanceOf['Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::DatabaseType'];

coerce 'DatabaseType',
    from HashRef, via { 'Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::DatabaseType'->new($_) };

declare 'RepeatedDatabaseType',
    as ArrayRef[DatabaseType()];

coerce 'RepeatedDatabaseType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::DatabaseType'->new($_) } @$_ ] };

declare 'MapStringDatabaseType',
    as HashRef[DatabaseType()];

declare 'LoggedMigrationJob',
    as InstanceOf['Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::LoggedMigrationJob'];

coerce 'LoggedMigrationJob',
    from HashRef, via { 'Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::LoggedMigrationJob'->new($_) };

declare 'RepeatedLoggedMigrationJob',
    as ArrayRef[LoggedMigrationJob()];

coerce 'RepeatedLoggedMigrationJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::LoggedMigrationJob'->new($_) } @$_ ] };

declare 'MapStringLoggedMigrationJob',
    as HashRef[LoggedMigrationJob()];

declare 'State',
    as (Int | Str);

declare 'Phase',
    as (Int | Str);

declare 'Type',
    as (Int | Str);

declare 'ConnectivityType',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::LoggedMigrationJob::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::LoggedMigrationJob::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::LoggedMigrationJob::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'MySqlConnectionProfile',
    as InstanceOf['Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::MySqlConnectionProfile'];

coerce 'MySqlConnectionProfile',
    from HashRef, via { 'Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::MySqlConnectionProfile'->new($_) };

declare 'RepeatedMySqlConnectionProfile',
    as ArrayRef[MySqlConnectionProfile()];

coerce 'RepeatedMySqlConnectionProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::MySqlConnectionProfile'->new($_) } @$_ ] };

declare 'MapStringMySqlConnectionProfile',
    as HashRef[MySqlConnectionProfile()];

declare 'Version',
    as (Int | Str);

declare 'PostgreSqlConnectionProfile',
    as InstanceOf['Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::PostgreSqlConnectionProfile'];

coerce 'PostgreSqlConnectionProfile',
    from HashRef, via { 'Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::PostgreSqlConnectionProfile'->new($_) };

declare 'RepeatedPostgreSqlConnectionProfile',
    as ArrayRef[PostgreSqlConnectionProfile()];

coerce 'RepeatedPostgreSqlConnectionProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::PostgreSqlConnectionProfile'->new($_) } @$_ ] };

declare 'MapStringPostgreSqlConnectionProfile',
    as HashRef[PostgreSqlConnectionProfile()];

declare 'Version',
    as (Int | Str);

declare 'CloudSqlConnectionProfile',
    as InstanceOf['Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::CloudSqlConnectionProfile'];

coerce 'CloudSqlConnectionProfile',
    from HashRef, via { 'Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::CloudSqlConnectionProfile'->new($_) };

declare 'RepeatedCloudSqlConnectionProfile',
    as ArrayRef[CloudSqlConnectionProfile()];

coerce 'RepeatedCloudSqlConnectionProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::CloudSqlConnectionProfile'->new($_) } @$_ ] };

declare 'MapStringCloudSqlConnectionProfile',
    as HashRef[CloudSqlConnectionProfile()];

declare 'OracleConnectionProfile',
    as InstanceOf['Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::OracleConnectionProfile'];

coerce 'OracleConnectionProfile',
    from HashRef, via { 'Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::OracleConnectionProfile'->new($_) };

declare 'RepeatedOracleConnectionProfile',
    as ArrayRef[OracleConnectionProfile()];

coerce 'RepeatedOracleConnectionProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::OracleConnectionProfile'->new($_) } @$_ ] };

declare 'MapStringOracleConnectionProfile',
    as HashRef[OracleConnectionProfile()];

declare 'ConnectivityType',
    as (Int | Str);

declare 'LoggedConnectionProfile',
    as InstanceOf['Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::LoggedConnectionProfile'];

coerce 'LoggedConnectionProfile',
    from HashRef, via { 'Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::LoggedConnectionProfile'->new($_) };

declare 'RepeatedLoggedConnectionProfile',
    as ArrayRef[LoggedConnectionProfile()];

coerce 'RepeatedLoggedConnectionProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::LoggedConnectionProfile'->new($_) } @$_ ] };

declare 'MapStringLoggedConnectionProfile',
    as HashRef[LoggedConnectionProfile()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::LoggedConnectionProfile::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::LoggedConnectionProfile::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::LoggedConnectionProfile::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'MigrationJobEventLog',
    as InstanceOf['Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::MigrationJobEventLog'];

coerce 'MigrationJobEventLog',
    from HashRef, via { 'Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::MigrationJobEventLog'->new($_) };

declare 'RepeatedMigrationJobEventLog',
    as ArrayRef[MigrationJobEventLog()];

coerce 'RepeatedMigrationJobEventLog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::MigrationJobEventLog'->new($_) } @$_ ] };

declare 'MapStringMigrationJobEventLog',
    as HashRef[MigrationJobEventLog()];

declare 'ConnectionProfileEventLog',
    as InstanceOf['Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::ConnectionProfileEventLog'];

coerce 'ConnectionProfileEventLog',
    from HashRef, via { 'Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::ConnectionProfileEventLog'->new($_) };

declare 'RepeatedConnectionProfileEventLog',
    as ArrayRef[ConnectionProfileEventLog()];

coerce 'RepeatedConnectionProfileEventLog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::ConnectionProfileEventLog'->new($_) } @$_ ] };

declare 'MapStringConnectionProfileEventLog',
    as HashRef[ConnectionProfileEventLog()];

declare 'LoggedPrivateConnection',
    as InstanceOf['Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::LoggedPrivateConnection'];

coerce 'LoggedPrivateConnection',
    from HashRef, via { 'Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::LoggedPrivateConnection'->new($_) };

declare 'RepeatedLoggedPrivateConnection',
    as ArrayRef[LoggedPrivateConnection()];

coerce 'RepeatedLoggedPrivateConnection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::LoggedPrivateConnection'->new($_) } @$_ ] };

declare 'MapStringLoggedPrivateConnection',
    as HashRef[LoggedPrivateConnection()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::LoggedPrivateConnection::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::LoggedPrivateConnection::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::LoggedPrivateConnection::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'VpcPeeringConfig',
    as InstanceOf['Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::VpcPeeringConfig'];

coerce 'VpcPeeringConfig',
    from HashRef, via { 'Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::VpcPeeringConfig'->new($_) };

declare 'RepeatedVpcPeeringConfig',
    as ArrayRef[VpcPeeringConfig()];

coerce 'RepeatedVpcPeeringConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::VpcPeeringConfig'->new($_) } @$_ ] };

declare 'MapStringVpcPeeringConfig',
    as HashRef[VpcPeeringConfig()];

declare 'PrivateConnectionEventLog',
    as InstanceOf['Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::PrivateConnectionEventLog'];

coerce 'PrivateConnectionEventLog',
    from HashRef, via { 'Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::PrivateConnectionEventLog'->new($_) };

declare 'RepeatedPrivateConnectionEventLog',
    as ArrayRef[PrivateConnectionEventLog()];

coerce 'RepeatedPrivateConnectionEventLog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::PrivateConnectionEventLog'->new($_) } @$_ ] };

declare 'MapStringPrivateConnectionEventLog',
    as HashRef[PrivateConnectionEventLog()];

1;

__END__

=head1 NAME

Google::Cloud::Clouddms::Logging::V1::ClouddmsPlatformLogs::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
