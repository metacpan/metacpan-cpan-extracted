package Google::Cloud::Bigquery::V2::Tabledata::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TableDataInsertAllRequest',
    as InstanceOf['Google::Cloud::Bigquery::V2::Tabledata::TableDataInsertAllRequest'];

coerce 'TableDataInsertAllRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Tabledata::TableDataInsertAllRequest'->new($_) };

declare 'RepeatedTableDataInsertAllRequest',
    as ArrayRef[TableDataInsertAllRequest()];

coerce 'RepeatedTableDataInsertAllRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Tabledata::TableDataInsertAllRequest'->new($_) } @$_ ] };

declare 'MapStringTableDataInsertAllRequest',
    as HashRef[TableDataInsertAllRequest()];

declare 'TableDataInsertAllResponse',
    as InstanceOf['Google::Cloud::Bigquery::V2::Tabledata::TableDataInsertAllResponse'];

coerce 'TableDataInsertAllResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Tabledata::TableDataInsertAllResponse'->new($_) };

declare 'RepeatedTableDataInsertAllResponse',
    as ArrayRef[TableDataInsertAllResponse()];

coerce 'RepeatedTableDataInsertAllResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Tabledata::TableDataInsertAllResponse'->new($_) } @$_ ] };

declare 'MapStringTableDataInsertAllResponse',
    as HashRef[TableDataInsertAllResponse()];

declare 'InsertionRow',
    as InstanceOf['Google::Cloud::Bigquery::V2::Tabledata::InsertionRow'];

coerce 'InsertionRow',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Tabledata::InsertionRow'->new($_) };

declare 'RepeatedInsertionRow',
    as ArrayRef[InsertionRow()];

coerce 'RepeatedInsertionRow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Tabledata::InsertionRow'->new($_) } @$_ ] };

declare 'MapStringInsertionRow',
    as HashRef[InsertionRow()];

declare 'InsertionError',
    as InstanceOf['Google::Cloud::Bigquery::V2::Tabledata::InsertionError'];

coerce 'InsertionError',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Tabledata::InsertionError'->new($_) };

declare 'RepeatedInsertionError',
    as ArrayRef[InsertionError()];

coerce 'RepeatedInsertionError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Tabledata::InsertionError'->new($_) } @$_ ] };

declare 'MapStringInsertionError',
    as HashRef[InsertionError()];

declare 'TableDataListRequest',
    as InstanceOf['Google::Cloud::Bigquery::V2::Tabledata::TableDataListRequest'];

coerce 'TableDataListRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Tabledata::TableDataListRequest'->new($_) };

declare 'RepeatedTableDataListRequest',
    as ArrayRef[TableDataListRequest()];

coerce 'RepeatedTableDataListRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Tabledata::TableDataListRequest'->new($_) } @$_ ] };

declare 'MapStringTableDataListRequest',
    as HashRef[TableDataListRequest()];

declare 'TableDataList',
    as InstanceOf['Google::Cloud::Bigquery::V2::Tabledata::TableDataList'];

coerce 'TableDataList',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Tabledata::TableDataList'->new($_) };

declare 'RepeatedTableDataList',
    as ArrayRef[TableDataList()];

coerce 'RepeatedTableDataList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Tabledata::TableDataList'->new($_) } @$_ ] };

declare 'MapStringTableDataList',
    as HashRef[TableDataList()];

1;
