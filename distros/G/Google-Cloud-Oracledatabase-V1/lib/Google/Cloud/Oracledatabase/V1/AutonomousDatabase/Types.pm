package Google::Cloud::Oracledatabase::V1::AutonomousDatabase::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GenerateType',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'OperationsInsightsState',
    as (Int | Str);

declare 'DBWorkload',
    as (Int | Str);

declare 'AutonomousDatabase',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::AutonomousDatabase::AutonomousDatabase'];

coerce 'AutonomousDatabase',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::AutonomousDatabase::AutonomousDatabase'->new($_) };

declare 'RepeatedAutonomousDatabase',
    as ArrayRef[AutonomousDatabase()];

coerce 'RepeatedAutonomousDatabase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::AutonomousDatabase::AutonomousDatabase'->new($_) } @$_ ] };

declare 'MapStringAutonomousDatabase',
    as HashRef[AutonomousDatabase()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::AutonomousDatabase::AutonomousDatabase::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::AutonomousDatabase::AutonomousDatabase::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::AutonomousDatabase::AutonomousDatabase::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'SourceConfig',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::AutonomousDatabase::SourceConfig'];

coerce 'SourceConfig',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::AutonomousDatabase::SourceConfig'->new($_) };

declare 'RepeatedSourceConfig',
    as ArrayRef[SourceConfig()];

coerce 'RepeatedSourceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::AutonomousDatabase::SourceConfig'->new($_) } @$_ ] };

declare 'MapStringSourceConfig',
    as HashRef[SourceConfig()];

declare 'RefreshableMode',
    as (Int | Str);

declare 'SourceType',
    as (Int | Str);

declare 'CloneType',
    as (Int | Str);

declare 'AutonomousDatabaseProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::AutonomousDatabase::AutonomousDatabaseProperties'];

coerce 'AutonomousDatabaseProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::AutonomousDatabase::AutonomousDatabaseProperties'->new($_) };

declare 'RepeatedAutonomousDatabaseProperties',
    as ArrayRef[AutonomousDatabaseProperties()];

coerce 'RepeatedAutonomousDatabaseProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::AutonomousDatabase::AutonomousDatabaseProperties'->new($_) } @$_ ] };

declare 'MapStringAutonomousDatabaseProperties',
    as HashRef[AutonomousDatabaseProperties()];

declare 'DatabaseEdition',
    as (Int | Str);

declare 'LicenseType',
    as (Int | Str);

declare 'MaintenanceScheduleType',
    as (Int | Str);

declare 'LocalDisasterRecoveryType',
    as (Int | Str);

declare 'DataSafeState',
    as (Int | Str);

declare 'DatabaseManagementState',
    as (Int | Str);

declare 'OpenMode',
    as (Int | Str);

declare 'PermissionLevel',
    as (Int | Str);

declare 'RefreshableMode',
    as (Int | Str);

declare 'RefreshableState',
    as (Int | Str);

declare 'Role',
    as (Int | Str);

declare 'EncryptionKeyHistoryEntry',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::AutonomousDatabase::EncryptionKeyHistoryEntry'];

coerce 'EncryptionKeyHistoryEntry',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::AutonomousDatabase::EncryptionKeyHistoryEntry'->new($_) };

declare 'RepeatedEncryptionKeyHistoryEntry',
    as ArrayRef[EncryptionKeyHistoryEntry()];

coerce 'RepeatedEncryptionKeyHistoryEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::AutonomousDatabase::EncryptionKeyHistoryEntry'->new($_) } @$_ ] };

declare 'MapStringEncryptionKeyHistoryEntry',
    as HashRef[EncryptionKeyHistoryEntry()];

declare 'EncryptionKey',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::AutonomousDatabase::EncryptionKey'];

coerce 'EncryptionKey',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::AutonomousDatabase::EncryptionKey'->new($_) };

declare 'RepeatedEncryptionKey',
    as ArrayRef[EncryptionKey()];

coerce 'RepeatedEncryptionKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::AutonomousDatabase::EncryptionKey'->new($_) } @$_ ] };

declare 'MapStringEncryptionKey',
    as HashRef[EncryptionKey()];

declare 'Provider',
    as (Int | Str);

declare 'AutonomousDatabaseApex',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::AutonomousDatabase::AutonomousDatabaseApex'];

coerce 'AutonomousDatabaseApex',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::AutonomousDatabase::AutonomousDatabaseApex'->new($_) };

declare 'RepeatedAutonomousDatabaseApex',
    as ArrayRef[AutonomousDatabaseApex()];

coerce 'RepeatedAutonomousDatabaseApex',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::AutonomousDatabase::AutonomousDatabaseApex'->new($_) } @$_ ] };

declare 'MapStringAutonomousDatabaseApex',
    as HashRef[AutonomousDatabaseApex()];

declare 'AutonomousDatabaseConnectionStrings',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::AutonomousDatabase::AutonomousDatabaseConnectionStrings'];

coerce 'AutonomousDatabaseConnectionStrings',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::AutonomousDatabase::AutonomousDatabaseConnectionStrings'->new($_) };

declare 'RepeatedAutonomousDatabaseConnectionStrings',
    as ArrayRef[AutonomousDatabaseConnectionStrings()];

coerce 'RepeatedAutonomousDatabaseConnectionStrings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::AutonomousDatabase::AutonomousDatabaseConnectionStrings'->new($_) } @$_ ] };

declare 'MapStringAutonomousDatabaseConnectionStrings',
    as HashRef[AutonomousDatabaseConnectionStrings()];

declare 'DatabaseConnectionStringProfile',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::AutonomousDatabase::DatabaseConnectionStringProfile'];

coerce 'DatabaseConnectionStringProfile',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::AutonomousDatabase::DatabaseConnectionStringProfile'->new($_) };

declare 'RepeatedDatabaseConnectionStringProfile',
    as ArrayRef[DatabaseConnectionStringProfile()];

coerce 'RepeatedDatabaseConnectionStringProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::AutonomousDatabase::DatabaseConnectionStringProfile'->new($_) } @$_ ] };

declare 'MapStringDatabaseConnectionStringProfile',
    as HashRef[DatabaseConnectionStringProfile()];

declare 'ConsumerGroup',
    as (Int | Str);

declare 'HostFormat',
    as (Int | Str);

declare 'Protocol',
    as (Int | Str);

declare 'SessionMode',
    as (Int | Str);

declare 'SyntaxFormat',
    as (Int | Str);

declare 'TLSAuthentication',
    as (Int | Str);

declare 'AllConnectionStrings',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::AutonomousDatabase::AllConnectionStrings'];

coerce 'AllConnectionStrings',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::AutonomousDatabase::AllConnectionStrings'->new($_) };

declare 'RepeatedAllConnectionStrings',
    as ArrayRef[AllConnectionStrings()];

coerce 'RepeatedAllConnectionStrings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::AutonomousDatabase::AllConnectionStrings'->new($_) } @$_ ] };

declare 'MapStringAllConnectionStrings',
    as HashRef[AllConnectionStrings()];

declare 'AutonomousDatabaseConnectionUrls',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::AutonomousDatabase::AutonomousDatabaseConnectionUrls'];

coerce 'AutonomousDatabaseConnectionUrls',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::AutonomousDatabase::AutonomousDatabaseConnectionUrls'->new($_) };

declare 'RepeatedAutonomousDatabaseConnectionUrls',
    as ArrayRef[AutonomousDatabaseConnectionUrls()];

coerce 'RepeatedAutonomousDatabaseConnectionUrls',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::AutonomousDatabase::AutonomousDatabaseConnectionUrls'->new($_) } @$_ ] };

declare 'MapStringAutonomousDatabaseConnectionUrls',
    as HashRef[AutonomousDatabaseConnectionUrls()];

declare 'AutonomousDatabaseStandbySummary',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::AutonomousDatabase::AutonomousDatabaseStandbySummary'];

coerce 'AutonomousDatabaseStandbySummary',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::AutonomousDatabase::AutonomousDatabaseStandbySummary'->new($_) };

declare 'RepeatedAutonomousDatabaseStandbySummary',
    as ArrayRef[AutonomousDatabaseStandbySummary()];

coerce 'RepeatedAutonomousDatabaseStandbySummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::AutonomousDatabase::AutonomousDatabaseStandbySummary'->new($_) } @$_ ] };

declare 'MapStringAutonomousDatabaseStandbySummary',
    as HashRef[AutonomousDatabaseStandbySummary()];

declare 'ScheduledOperationDetails',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::AutonomousDatabase::ScheduledOperationDetails'];

coerce 'ScheduledOperationDetails',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::AutonomousDatabase::ScheduledOperationDetails'->new($_) };

declare 'RepeatedScheduledOperationDetails',
    as ArrayRef[ScheduledOperationDetails()];

coerce 'RepeatedScheduledOperationDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::AutonomousDatabase::ScheduledOperationDetails'->new($_) } @$_ ] };

declare 'MapStringScheduledOperationDetails',
    as HashRef[ScheduledOperationDetails()];

declare 'AutonomousDatabaseRefreshableClone',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::AutonomousDatabase::AutonomousDatabaseRefreshableClone'];

coerce 'AutonomousDatabaseRefreshableClone',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::AutonomousDatabase::AutonomousDatabaseRefreshableClone'->new($_) };

declare 'RepeatedAutonomousDatabaseRefreshableClone',
    as ArrayRef[AutonomousDatabaseRefreshableClone()];

coerce 'RepeatedAutonomousDatabaseRefreshableClone',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::AutonomousDatabase::AutonomousDatabaseRefreshableClone'->new($_) } @$_ ] };

declare 'MapStringAutonomousDatabaseRefreshableClone',
    as HashRef[AutonomousDatabaseRefreshableClone()];

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::AutonomousDatabase::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
