package Google::Cloud::Sql::V1::CloudSqlBackupRuns::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SqlBackupRunStatus',
    as (Int | Str);

declare 'SqlBackupKind',
    as (Int | Str);

declare 'SqlBackupRunType',
    as (Int | Str);

declare 'SqlBackupRunsDeleteRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlBackupRuns::SqlBackupRunsDeleteRequest'];

coerce 'SqlBackupRunsDeleteRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlBackupRuns::SqlBackupRunsDeleteRequest'->new($_) };

declare 'RepeatedSqlBackupRunsDeleteRequest',
    as ArrayRef[SqlBackupRunsDeleteRequest()];

coerce 'RepeatedSqlBackupRunsDeleteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlBackupRuns::SqlBackupRunsDeleteRequest'->new($_) } @$_ ] };

declare 'MapStringSqlBackupRunsDeleteRequest',
    as HashRef[SqlBackupRunsDeleteRequest()];

declare 'SqlBackupRunsGetRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlBackupRuns::SqlBackupRunsGetRequest'];

coerce 'SqlBackupRunsGetRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlBackupRuns::SqlBackupRunsGetRequest'->new($_) };

declare 'RepeatedSqlBackupRunsGetRequest',
    as ArrayRef[SqlBackupRunsGetRequest()];

coerce 'RepeatedSqlBackupRunsGetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlBackupRuns::SqlBackupRunsGetRequest'->new($_) } @$_ ] };

declare 'MapStringSqlBackupRunsGetRequest',
    as HashRef[SqlBackupRunsGetRequest()];

declare 'SqlBackupRunsInsertRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlBackupRuns::SqlBackupRunsInsertRequest'];

coerce 'SqlBackupRunsInsertRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlBackupRuns::SqlBackupRunsInsertRequest'->new($_) };

declare 'RepeatedSqlBackupRunsInsertRequest',
    as ArrayRef[SqlBackupRunsInsertRequest()];

coerce 'RepeatedSqlBackupRunsInsertRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlBackupRuns::SqlBackupRunsInsertRequest'->new($_) } @$_ ] };

declare 'MapStringSqlBackupRunsInsertRequest',
    as HashRef[SqlBackupRunsInsertRequest()];

declare 'SqlBackupRunsListRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlBackupRuns::SqlBackupRunsListRequest'];

coerce 'SqlBackupRunsListRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlBackupRuns::SqlBackupRunsListRequest'->new($_) };

declare 'RepeatedSqlBackupRunsListRequest',
    as ArrayRef[SqlBackupRunsListRequest()];

coerce 'RepeatedSqlBackupRunsListRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlBackupRuns::SqlBackupRunsListRequest'->new($_) } @$_ ] };

declare 'MapStringSqlBackupRunsListRequest',
    as HashRef[SqlBackupRunsListRequest()];

declare 'BackupRun',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlBackupRuns::BackupRun'];

coerce 'BackupRun',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlBackupRuns::BackupRun'->new($_) };

declare 'RepeatedBackupRun',
    as ArrayRef[BackupRun()];

coerce 'RepeatedBackupRun',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlBackupRuns::BackupRun'->new($_) } @$_ ] };

declare 'MapStringBackupRun',
    as HashRef[BackupRun()];

declare 'BackupRunsListResponse',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlBackupRuns::BackupRunsListResponse'];

coerce 'BackupRunsListResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlBackupRuns::BackupRunsListResponse'->new($_) };

declare 'RepeatedBackupRunsListResponse',
    as ArrayRef[BackupRunsListResponse()];

coerce 'RepeatedBackupRunsListResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlBackupRuns::BackupRunsListResponse'->new($_) } @$_ ] };

declare 'MapStringBackupRunsListResponse',
    as HashRef[BackupRunsListResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlBackupRuns::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
