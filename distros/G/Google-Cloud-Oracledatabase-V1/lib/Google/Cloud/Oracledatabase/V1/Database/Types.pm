package Google::Cloud::Oracledatabase::V1::Database::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Database',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Database::Database'];

coerce 'Database',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Database::Database'->new($_) };

declare 'RepeatedDatabase',
    as ArrayRef[Database()];

coerce 'RepeatedDatabase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Database::Database'->new($_) } @$_ ] };

declare 'MapStringDatabase',
    as HashRef[Database()];

declare 'OperationsInsightsStatus',
    as (Int | Str);

declare 'DatabaseProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Database::DatabaseProperties'];

coerce 'DatabaseProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Database::DatabaseProperties'->new($_) };

declare 'RepeatedDatabaseProperties',
    as ArrayRef[DatabaseProperties()];

coerce 'RepeatedDatabaseProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Database::DatabaseProperties'->new($_) } @$_ ] };

declare 'MapStringDatabaseProperties',
    as HashRef[DatabaseProperties()];

declare 'DatabaseLifecycleState',
    as (Int | Str);

declare 'DbBackupConfig',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Database::DbBackupConfig'];

coerce 'DbBackupConfig',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Database::DbBackupConfig'->new($_) };

declare 'RepeatedDbBackupConfig',
    as ArrayRef[DbBackupConfig()];

coerce 'RepeatedDbBackupConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Database::DbBackupConfig'->new($_) } @$_ ] };

declare 'MapStringDbBackupConfig',
    as HashRef[DbBackupConfig()];

declare 'BackupDestinationType',
    as (Int | Str);

declare 'BackupWindow',
    as (Int | Str);

declare 'BackupDeletionPolicy',
    as (Int | Str);

declare 'BackupDestinationDetails',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Database::DbBackupConfig::BackupDestinationDetails'];

coerce 'BackupDestinationDetails',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Database::DbBackupConfig::BackupDestinationDetails'->new($_) };

declare 'RepeatedBackupDestinationDetails',
    as ArrayRef[BackupDestinationDetails()];

coerce 'RepeatedBackupDestinationDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Database::DbBackupConfig::BackupDestinationDetails'->new($_) } @$_ ] };

declare 'MapStringBackupDestinationDetails',
    as HashRef[BackupDestinationDetails()];

declare 'GetDatabaseRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Database::GetDatabaseRequest'];

coerce 'GetDatabaseRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Database::GetDatabaseRequest'->new($_) };

declare 'RepeatedGetDatabaseRequest',
    as ArrayRef[GetDatabaseRequest()];

coerce 'RepeatedGetDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Database::GetDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringGetDatabaseRequest',
    as HashRef[GetDatabaseRequest()];

declare 'ListDatabasesRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Database::ListDatabasesRequest'];

coerce 'ListDatabasesRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Database::ListDatabasesRequest'->new($_) };

declare 'RepeatedListDatabasesRequest',
    as ArrayRef[ListDatabasesRequest()];

coerce 'RepeatedListDatabasesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Database::ListDatabasesRequest'->new($_) } @$_ ] };

declare 'MapStringListDatabasesRequest',
    as HashRef[ListDatabasesRequest()];

declare 'ListDatabasesResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Database::ListDatabasesResponse'];

coerce 'ListDatabasesResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Database::ListDatabasesResponse'->new($_) };

declare 'RepeatedListDatabasesResponse',
    as ArrayRef[ListDatabasesResponse()];

coerce 'RepeatedListDatabasesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Database::ListDatabasesResponse'->new($_) } @$_ ] };

declare 'MapStringListDatabasesResponse',
    as HashRef[ListDatabasesResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::Database::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
