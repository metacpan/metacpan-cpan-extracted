package Google::Cloud::Sql::V1::CloudSqlDatabases::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SqlDatabasesDeleteRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesDeleteRequest'];

coerce 'SqlDatabasesDeleteRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesDeleteRequest'->new($_) };

declare 'RepeatedSqlDatabasesDeleteRequest',
    as ArrayRef[SqlDatabasesDeleteRequest()];

coerce 'RepeatedSqlDatabasesDeleteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesDeleteRequest'->new($_) } @$_ ] };

declare 'MapStringSqlDatabasesDeleteRequest',
    as HashRef[SqlDatabasesDeleteRequest()];

declare 'SqlDatabasesGetRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesGetRequest'];

coerce 'SqlDatabasesGetRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesGetRequest'->new($_) };

declare 'RepeatedSqlDatabasesGetRequest',
    as ArrayRef[SqlDatabasesGetRequest()];

coerce 'RepeatedSqlDatabasesGetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesGetRequest'->new($_) } @$_ ] };

declare 'MapStringSqlDatabasesGetRequest',
    as HashRef[SqlDatabasesGetRequest()];

declare 'SqlDatabasesInsertRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesInsertRequest'];

coerce 'SqlDatabasesInsertRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesInsertRequest'->new($_) };

declare 'RepeatedSqlDatabasesInsertRequest',
    as ArrayRef[SqlDatabasesInsertRequest()];

coerce 'RepeatedSqlDatabasesInsertRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesInsertRequest'->new($_) } @$_ ] };

declare 'MapStringSqlDatabasesInsertRequest',
    as HashRef[SqlDatabasesInsertRequest()];

declare 'SqlDatabasesListRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesListRequest'];

coerce 'SqlDatabasesListRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesListRequest'->new($_) };

declare 'RepeatedSqlDatabasesListRequest',
    as ArrayRef[SqlDatabasesListRequest()];

coerce 'RepeatedSqlDatabasesListRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesListRequest'->new($_) } @$_ ] };

declare 'MapStringSqlDatabasesListRequest',
    as HashRef[SqlDatabasesListRequest()];

declare 'SqlDatabasesUpdateRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesUpdateRequest'];

coerce 'SqlDatabasesUpdateRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesUpdateRequest'->new($_) };

declare 'RepeatedSqlDatabasesUpdateRequest',
    as ArrayRef[SqlDatabasesUpdateRequest()];

coerce 'RepeatedSqlDatabasesUpdateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlDatabases::SqlDatabasesUpdateRequest'->new($_) } @$_ ] };

declare 'MapStringSqlDatabasesUpdateRequest',
    as HashRef[SqlDatabasesUpdateRequest()];

declare 'DatabasesListResponse',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlDatabases::DatabasesListResponse'];

coerce 'DatabasesListResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlDatabases::DatabasesListResponse'->new($_) };

declare 'RepeatedDatabasesListResponse',
    as ArrayRef[DatabasesListResponse()];

coerce 'RepeatedDatabasesListResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlDatabases::DatabasesListResponse'->new($_) } @$_ ] };

declare 'MapStringDatabasesListResponse',
    as HashRef[DatabasesListResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlDatabases::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
