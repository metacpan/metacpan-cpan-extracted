package Google::Cloud::Bigquery::V2::StandardSql::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'StandardSqlDataType',
    as InstanceOf['Google::Cloud::Bigquery::V2::StandardSql::StandardSqlDataType'];

coerce 'StandardSqlDataType',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::StandardSql::StandardSqlDataType'->new($_) };

declare 'RepeatedStandardSqlDataType',
    as ArrayRef[StandardSqlDataType()];

coerce 'RepeatedStandardSqlDataType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::StandardSql::StandardSqlDataType'->new($_) } @$_ ] };

declare 'MapStringStandardSqlDataType',
    as HashRef[StandardSqlDataType()];

declare 'TypeKind',
    as (Int | Str);

declare 'StandardSqlField',
    as InstanceOf['Google::Cloud::Bigquery::V2::StandardSql::StandardSqlField'];

coerce 'StandardSqlField',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::StandardSql::StandardSqlField'->new($_) };

declare 'RepeatedStandardSqlField',
    as ArrayRef[StandardSqlField()];

coerce 'RepeatedStandardSqlField',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::StandardSql::StandardSqlField'->new($_) } @$_ ] };

declare 'MapStringStandardSqlField',
    as HashRef[StandardSqlField()];

declare 'StandardSqlStructType',
    as InstanceOf['Google::Cloud::Bigquery::V2::StandardSql::StandardSqlStructType'];

coerce 'StandardSqlStructType',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::StandardSql::StandardSqlStructType'->new($_) };

declare 'RepeatedStandardSqlStructType',
    as ArrayRef[StandardSqlStructType()];

coerce 'RepeatedStandardSqlStructType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::StandardSql::StandardSqlStructType'->new($_) } @$_ ] };

declare 'MapStringStandardSqlStructType',
    as HashRef[StandardSqlStructType()];

declare 'StandardSqlTableType',
    as InstanceOf['Google::Cloud::Bigquery::V2::StandardSql::StandardSqlTableType'];

coerce 'StandardSqlTableType',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::StandardSql::StandardSqlTableType'->new($_) };

declare 'RepeatedStandardSqlTableType',
    as ArrayRef[StandardSqlTableType()];

coerce 'RepeatedStandardSqlTableType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::StandardSql::StandardSqlTableType'->new($_) } @$_ ] };

declare 'MapStringStandardSqlTableType',
    as HashRef[StandardSqlTableType()];

1;
