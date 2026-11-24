package Google::Cloud::Chronicle::V1::Search::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'QueryDialect',
    as (Int | Str);

declare 'SearchSession',
    as InstanceOf['Google::Cloud::Chronicle::V1::Search::SearchSession'];

coerce 'SearchSession',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Search::SearchSession'->new($_) };

declare 'RepeatedSearchSession',
    as ArrayRef[SearchSession()];

coerce 'RepeatedSearchSession',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Search::SearchSession'->new($_) } @$_ ] };

declare 'MapStringSearchSession',
    as HashRef[SearchSession()];

declare 'SearchedResult',
    as InstanceOf['Google::Cloud::Chronicle::V1::Search::SearchedResult'];

coerce 'SearchedResult',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Search::SearchedResult'->new($_) };

declare 'RepeatedSearchedResult',
    as ArrayRef[SearchedResult()];

coerce 'RepeatedSearchedResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Search::SearchedResult'->new($_) } @$_ ] };

declare 'MapStringSearchedResult',
    as HashRef[SearchedResult()];

declare 'SearchRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Search::SearchRequest'];

coerce 'SearchRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Search::SearchRequest'->new($_) };

declare 'RepeatedSearchRequest',
    as ArrayRef[SearchRequest()];

coerce 'RepeatedSearchRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Search::SearchRequest'->new($_) } @$_ ] };

declare 'MapStringSearchRequest',
    as HashRef[SearchRequest()];

declare 'ListSearchedResultsRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Search::ListSearchedResultsRequest'];

coerce 'ListSearchedResultsRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Search::ListSearchedResultsRequest'->new($_) };

declare 'RepeatedListSearchedResultsRequest',
    as ArrayRef[ListSearchedResultsRequest()];

coerce 'RepeatedListSearchedResultsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Search::ListSearchedResultsRequest'->new($_) } @$_ ] };

declare 'MapStringListSearchedResultsRequest',
    as HashRef[ListSearchedResultsRequest()];

declare 'ListSearchedResultsResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::Search::ListSearchedResultsResponse'];

coerce 'ListSearchedResultsResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Search::ListSearchedResultsResponse'->new($_) };

declare 'RepeatedListSearchedResultsResponse',
    as ArrayRef[ListSearchedResultsResponse()];

coerce 'RepeatedListSearchedResultsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Search::ListSearchedResultsResponse'->new($_) } @$_ ] };

declare 'MapStringListSearchedResultsResponse',
    as HashRef[ListSearchedResultsResponse()];

declare 'SearchSessionMetadata',
    as InstanceOf['Google::Cloud::Chronicle::V1::Search::SearchSessionMetadata'];

coerce 'SearchSessionMetadata',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Search::SearchSessionMetadata'->new($_) };

declare 'RepeatedSearchSessionMetadata',
    as ArrayRef[SearchSessionMetadata()];

coerce 'RepeatedSearchSessionMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Search::SearchSessionMetadata'->new($_) } @$_ ] };

declare 'MapStringSearchSessionMetadata',
    as HashRef[SearchSessionMetadata()];

declare 'SearchOperationMetadata',
    as InstanceOf['Google::Cloud::Chronicle::V1::Search::SearchOperationMetadata'];

coerce 'SearchOperationMetadata',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Search::SearchOperationMetadata'->new($_) };

declare 'RepeatedSearchOperationMetadata',
    as ArrayRef[SearchOperationMetadata()];

coerce 'RepeatedSearchOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Search::SearchOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringSearchOperationMetadata',
    as HashRef[SearchOperationMetadata()];

declare 'State',
    as (Int | Str);

declare 'DataTableExportMetadata',
    as InstanceOf['Google::Cloud::Chronicle::V1::Search::DataTableExportMetadata'];

coerce 'DataTableExportMetadata',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Search::DataTableExportMetadata'->new($_) };

declare 'RepeatedDataTableExportMetadata',
    as ArrayRef[DataTableExportMetadata()];

coerce 'RepeatedDataTableExportMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Search::DataTableExportMetadata'->new($_) } @$_ ] };

declare 'MapStringDataTableExportMetadata',
    as HashRef[DataTableExportMetadata()];

declare 'ResultMetadata',
    as InstanceOf['Google::Cloud::Chronicle::V1::Search::DataTableExportMetadata::ResultMetadata'];

coerce 'ResultMetadata',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Search::DataTableExportMetadata::ResultMetadata'->new($_) };

declare 'RepeatedResultMetadata',
    as ArrayRef[ResultMetadata()];

coerce 'RepeatedResultMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Search::DataTableExportMetadata::ResultMetadata'->new($_) } @$_ ] };

declare 'MapStringResultMetadata',
    as HashRef[ResultMetadata()];

declare 'TableMetadata',
    as InstanceOf['Google::Cloud::Chronicle::V1::Search::TableMetadata'];

coerce 'TableMetadata',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Search::TableMetadata'->new($_) };

declare 'RepeatedTableMetadata',
    as ArrayRef[TableMetadata()];

coerce 'RepeatedTableMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Search::TableMetadata'->new($_) } @$_ ] };

declare 'MapStringTableMetadata',
    as HashRef[TableMetadata()];

declare 'DataSource',
    as (Int | Str);

declare 'ColumnSchema',
    as InstanceOf['Google::Cloud::Chronicle::V1::Search::ColumnSchema'];

coerce 'ColumnSchema',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Search::ColumnSchema'->new($_) };

declare 'RepeatedColumnSchema',
    as ArrayRef[ColumnSchema()];

coerce 'RepeatedColumnSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Search::ColumnSchema'->new($_) } @$_ ] };

declare 'MapStringColumnSchema',
    as HashRef[ColumnSchema()];

declare 'ColumnNames',
    as InstanceOf['Google::Cloud::Chronicle::V1::Search::ColumnNames'];

coerce 'ColumnNames',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Search::ColumnNames'->new($_) };

declare 'RepeatedColumnNames',
    as ArrayRef[ColumnNames()];

coerce 'RepeatedColumnNames',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Search::ColumnNames'->new($_) } @$_ ] };

declare 'MapStringColumnNames',
    as HashRef[ColumnNames()];

declare 'ResultRow',
    as InstanceOf['Google::Cloud::Chronicle::V1::Search::ResultRow'];

coerce 'ResultRow',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Search::ResultRow'->new($_) };

declare 'RepeatedResultRow',
    as ArrayRef[ResultRow()];

coerce 'RepeatedResultRow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Search::ResultRow'->new($_) } @$_ ] };

declare 'MapStringResultRow',
    as HashRef[ResultRow()];

declare 'StatsRecord',
    as InstanceOf['Google::Cloud::Chronicle::V1::Search::StatsRecord'];

coerce 'StatsRecord',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Search::StatsRecord'->new($_) };

declare 'RepeatedStatsRecord',
    as ArrayRef[StatsRecord()];

coerce 'RepeatedStatsRecord',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Search::StatsRecord'->new($_) } @$_ ] };

declare 'MapStringStatsRecord',
    as HashRef[StatsRecord()];

declare 'StatsColumnData',
    as InstanceOf['Google::Cloud::Chronicle::V1::Search::StatsColumnData'];

coerce 'StatsColumnData',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Search::StatsColumnData'->new($_) };

declare 'RepeatedStatsColumnData',
    as ArrayRef[StatsColumnData()];

coerce 'RepeatedStatsColumnData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Search::StatsColumnData'->new($_) } @$_ ] };

declare 'MapStringStatsColumnData',
    as HashRef[StatsColumnData()];

declare 'ColumnType',
    as InstanceOf['Google::Cloud::Chronicle::V1::Search::ColumnType'];

coerce 'ColumnType',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Search::ColumnType'->new($_) };

declare 'RepeatedColumnType',
    as ArrayRef[ColumnType()];

coerce 'RepeatedColumnType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Search::ColumnType'->new($_) } @$_ ] };

declare 'MapStringColumnType',
    as HashRef[ColumnType()];

declare 'ColumnValue',
    as InstanceOf['Google::Cloud::Chronicle::V1::Search::ColumnType::ColumnValue'];

coerce 'ColumnValue',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Search::ColumnType::ColumnValue'->new($_) };

declare 'RepeatedColumnValue',
    as ArrayRef[ColumnValue()];

coerce 'RepeatedColumnValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Search::ColumnType::ColumnValue'->new($_) } @$_ ] };

declare 'MapStringColumnValue',
    as HashRef[ColumnValue()];

declare 'ColumnValueList',
    as InstanceOf['Google::Cloud::Chronicle::V1::Search::ColumnType::ColumnValueList'];

coerce 'ColumnValueList',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Search::ColumnType::ColumnValueList'->new($_) };

declare 'RepeatedColumnValueList',
    as ArrayRef[ColumnValueList()];

coerce 'RepeatedColumnValueList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Search::ColumnType::ColumnValueList'->new($_) } @$_ ] };

declare 'MapStringColumnValueList',
    as HashRef[ColumnValueList()];

declare 'SearchDataTableRowCell',
    as InstanceOf['Google::Cloud::Chronicle::V1::Search::SearchDataTableRowCell'];

coerce 'SearchDataTableRowCell',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Search::SearchDataTableRowCell'->new($_) };

declare 'RepeatedSearchDataTableRowCell',
    as ArrayRef[SearchDataTableRowCell()];

coerce 'RepeatedSearchDataTableRowCell',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Search::SearchDataTableRowCell'->new($_) } @$_ ] };

declare 'MapStringSearchDataTableRowCell',
    as HashRef[SearchDataTableRowCell()];

declare 'DataTableRecord',
    as InstanceOf['Google::Cloud::Chronicle::V1::Search::DataTableRecord'];

coerce 'DataTableRecord',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Search::DataTableRecord'->new($_) };

declare 'RepeatedDataTableRecord',
    as ArrayRef[DataTableRecord()];

coerce 'RepeatedDataTableRecord',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Search::DataTableRecord'->new($_) } @$_ ] };

declare 'MapStringDataTableRecord',
    as HashRef[DataTableRecord()];

declare 'EventRecord',
    as InstanceOf['Google::Cloud::Chronicle::V1::Search::EventRecord'];

coerce 'EventRecord',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Search::EventRecord'->new($_) };

declare 'RepeatedEventRecord',
    as ArrayRef[EventRecord()];

coerce 'RepeatedEventRecord',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Search::EventRecord'->new($_) } @$_ ] };

declare 'MapStringEventRecord',
    as HashRef[EventRecord()];

declare 'Annotation',
    as (Int | Str);

declare 'EntityContextRecord',
    as InstanceOf['Google::Cloud::Chronicle::V1::Search::EntityContextRecord'];

coerce 'EntityContextRecord',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Search::EntityContextRecord'->new($_) };

declare 'RepeatedEntityContextRecord',
    as ArrayRef[EntityContextRecord()];

coerce 'RepeatedEntityContextRecord',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Search::EntityContextRecord'->new($_) } @$_ ] };

declare 'MapStringEntityContextRecord',
    as HashRef[EntityContextRecord()];

declare 'JoinRecord',
    as InstanceOf['Google::Cloud::Chronicle::V1::Search::JoinRecord'];

coerce 'JoinRecord',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Search::JoinRecord'->new($_) };

declare 'RepeatedJoinRecord',
    as ArrayRef[JoinRecord()];

coerce 'RepeatedJoinRecord',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Search::JoinRecord'->new($_) } @$_ ] };

declare 'MapStringJoinRecord',
    as HashRef[JoinRecord()];

declare 'DetectionRecord',
    as InstanceOf['Google::Cloud::Chronicle::V1::Search::DetectionRecord'];

coerce 'DetectionRecord',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Search::DetectionRecord'->new($_) };

declare 'RepeatedDetectionRecord',
    as ArrayRef[DetectionRecord()];

coerce 'RepeatedDetectionRecord',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Search::DetectionRecord'->new($_) } @$_ ] };

declare 'MapStringDetectionRecord',
    as HashRef[DetectionRecord()];

1;

__END__

=head1 NAME

Google::Cloud::Chronicle::V1::Search::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
