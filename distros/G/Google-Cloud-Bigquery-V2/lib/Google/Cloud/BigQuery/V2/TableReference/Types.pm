package Google::Cloud::BigQuery::V2::TableReference::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TableReference',
    as InstanceOf['Google::Cloud::BigQuery::V2::TableReference::TableReference'];

coerce 'TableReference',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::TableReference::TableReference'->new($_) };

declare 'RepeatedTableReference',
    as ArrayRef[TableReference()];

coerce 'RepeatedTableReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::TableReference::TableReference'->new($_) } @$_ ] };

declare 'MapStringTableReference',
    as HashRef[TableReference()];

1;
