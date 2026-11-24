package Google::Cloud::Oracledatabase::V1::ExecuteSql::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ExecuteSqlRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::ExecuteSql::ExecuteSqlRequest'];

coerce 'ExecuteSqlRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::ExecuteSql::ExecuteSqlRequest'->new($_) };

declare 'RepeatedExecuteSqlRequest',
    as ArrayRef[ExecuteSqlRequest()];

coerce 'RepeatedExecuteSqlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::ExecuteSql::ExecuteSqlRequest'->new($_) } @$_ ] };

declare 'MapStringExecuteSqlRequest',
    as HashRef[ExecuteSqlRequest()];

declare 'SqlParameter',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::ExecuteSql::SqlParameter'];

coerce 'SqlParameter',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::ExecuteSql::SqlParameter'->new($_) };

declare 'RepeatedSqlParameter',
    as ArrayRef[SqlParameter()];

coerce 'RepeatedSqlParameter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::ExecuteSql::SqlParameter'->new($_) } @$_ ] };

declare 'MapStringSqlParameter',
    as HashRef[SqlParameter()];

declare 'ExecuteSqlResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::ExecuteSql::ExecuteSqlResponse'];

coerce 'ExecuteSqlResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::ExecuteSql::ExecuteSqlResponse'->new($_) };

declare 'RepeatedExecuteSqlResponse',
    as ArrayRef[ExecuteSqlResponse()];

coerce 'RepeatedExecuteSqlResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::ExecuteSql::ExecuteSqlResponse'->new($_) } @$_ ] };

declare 'MapStringExecuteSqlResponse',
    as HashRef[ExecuteSqlResponse()];

declare 'SqlResult',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::ExecuteSql::SqlResult'];

coerce 'SqlResult',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::ExecuteSql::SqlResult'->new($_) };

declare 'RepeatedSqlResult',
    as ArrayRef[SqlResult()];

coerce 'RepeatedSqlResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::ExecuteSql::SqlResult'->new($_) } @$_ ] };

declare 'MapStringSqlResult',
    as HashRef[SqlResult()];

declare 'Column',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::ExecuteSql::SqlResult::Column'];

coerce 'Column',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::ExecuteSql::SqlResult::Column'->new($_) };

declare 'RepeatedColumn',
    as ArrayRef[Column()];

coerce 'RepeatedColumn',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::ExecuteSql::SqlResult::Column'->new($_) } @$_ ] };

declare 'MapStringColumn',
    as HashRef[Column()];

declare 'Row',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::ExecuteSql::SqlResult::Row'];

coerce 'Row',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::ExecuteSql::SqlResult::Row'->new($_) };

declare 'RepeatedRow',
    as ArrayRef[Row()];

coerce 'RepeatedRow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::ExecuteSql::SqlResult::Row'->new($_) } @$_ ] };

declare 'MapStringRow',
    as HashRef[Row()];

declare 'Value',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::ExecuteSql::SqlResult::Value'];

coerce 'Value',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::ExecuteSql::SqlResult::Value'->new($_) };

declare 'RepeatedValue',
    as ArrayRef[Value()];

coerce 'RepeatedValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::ExecuteSql::SqlResult::Value'->new($_) } @$_ ] };

declare 'MapStringValue',
    as HashRef[Value()];

declare 'ExecuteSqlMetadata',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::ExecuteSql::ExecuteSqlMetadata'];

coerce 'ExecuteSqlMetadata',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::ExecuteSql::ExecuteSqlMetadata'->new($_) };

declare 'RepeatedExecuteSqlMetadata',
    as ArrayRef[ExecuteSqlMetadata()];

coerce 'RepeatedExecuteSqlMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::ExecuteSql::ExecuteSqlMetadata'->new($_) } @$_ ] };

declare 'MapStringExecuteSqlMetadata',
    as HashRef[ExecuteSqlMetadata()];

declare 'Status',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::ExecuteSql::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
