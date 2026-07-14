package Google::Cloud::BigQuery::V2::TableConstraints::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PrimaryKey',
    as InstanceOf['Google::Cloud::BigQuery::V2::TableConstraints::PrimaryKey'];

coerce 'PrimaryKey',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::TableConstraints::PrimaryKey'->new($_) };

declare 'RepeatedPrimaryKey',
    as ArrayRef[PrimaryKey()];

coerce 'RepeatedPrimaryKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::TableConstraints::PrimaryKey'->new($_) } @$_ ] };

declare 'MapStringPrimaryKey',
    as HashRef[PrimaryKey()];

declare 'ColumnReference',
    as InstanceOf['Google::Cloud::BigQuery::V2::TableConstraints::ColumnReference'];

coerce 'ColumnReference',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::TableConstraints::ColumnReference'->new($_) };

declare 'RepeatedColumnReference',
    as ArrayRef[ColumnReference()];

coerce 'RepeatedColumnReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::TableConstraints::ColumnReference'->new($_) } @$_ ] };

declare 'MapStringColumnReference',
    as HashRef[ColumnReference()];

declare 'ForeignKey',
    as InstanceOf['Google::Cloud::BigQuery::V2::TableConstraints::ForeignKey'];

coerce 'ForeignKey',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::TableConstraints::ForeignKey'->new($_) };

declare 'RepeatedForeignKey',
    as ArrayRef[ForeignKey()];

coerce 'RepeatedForeignKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::TableConstraints::ForeignKey'->new($_) } @$_ ] };

declare 'MapStringForeignKey',
    as HashRef[ForeignKey()];

declare 'TableConstraints',
    as InstanceOf['Google::Cloud::BigQuery::V2::TableConstraints::TableConstraints'];

coerce 'TableConstraints',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::TableConstraints::TableConstraints'->new($_) };

declare 'RepeatedTableConstraints',
    as ArrayRef[TableConstraints()];

coerce 'RepeatedTableConstraints',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::TableConstraints::TableConstraints'->new($_) } @$_ ] };

declare 'MapStringTableConstraints',
    as HashRef[TableConstraints()];

1;
