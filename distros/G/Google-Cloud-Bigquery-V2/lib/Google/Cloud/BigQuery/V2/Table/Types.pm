package Google::Cloud::BigQuery::V2::Table::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TableReplicationInfo',
    as InstanceOf['Google::Cloud::BigQuery::V2::Table::TableReplicationInfo'];

coerce 'TableReplicationInfo',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Table::TableReplicationInfo'->new($_) };

declare 'RepeatedTableReplicationInfo',
    as ArrayRef[TableReplicationInfo()];

coerce 'RepeatedTableReplicationInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Table::TableReplicationInfo'->new($_) } @$_ ] };

declare 'MapStringTableReplicationInfo',
    as HashRef[TableReplicationInfo()];

declare 'ReplicationStatus',
    as (Int | Str);

declare 'ViewDefinition',
    as InstanceOf['Google::Cloud::BigQuery::V2::Table::ViewDefinition'];

coerce 'ViewDefinition',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Table::ViewDefinition'->new($_) };

declare 'RepeatedViewDefinition',
    as ArrayRef[ViewDefinition()];

coerce 'RepeatedViewDefinition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Table::ViewDefinition'->new($_) } @$_ ] };

declare 'MapStringViewDefinition',
    as HashRef[ViewDefinition()];

declare 'ForeignViewDefinition',
    as InstanceOf['Google::Cloud::BigQuery::V2::Table::ForeignViewDefinition'];

coerce 'ForeignViewDefinition',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Table::ForeignViewDefinition'->new($_) };

declare 'RepeatedForeignViewDefinition',
    as ArrayRef[ForeignViewDefinition()];

coerce 'RepeatedForeignViewDefinition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Table::ForeignViewDefinition'->new($_) } @$_ ] };

declare 'MapStringForeignViewDefinition',
    as HashRef[ForeignViewDefinition()];

declare 'MaterializedViewDefinition',
    as InstanceOf['Google::Cloud::BigQuery::V2::Table::MaterializedViewDefinition'];

coerce 'MaterializedViewDefinition',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Table::MaterializedViewDefinition'->new($_) };

declare 'RepeatedMaterializedViewDefinition',
    as ArrayRef[MaterializedViewDefinition()];

coerce 'RepeatedMaterializedViewDefinition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Table::MaterializedViewDefinition'->new($_) } @$_ ] };

declare 'MapStringMaterializedViewDefinition',
    as HashRef[MaterializedViewDefinition()];

declare 'MaterializedViewStatus',
    as InstanceOf['Google::Cloud::BigQuery::V2::Table::MaterializedViewStatus'];

coerce 'MaterializedViewStatus',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Table::MaterializedViewStatus'->new($_) };

declare 'RepeatedMaterializedViewStatus',
    as ArrayRef[MaterializedViewStatus()];

coerce 'RepeatedMaterializedViewStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Table::MaterializedViewStatus'->new($_) } @$_ ] };

declare 'MapStringMaterializedViewStatus',
    as HashRef[MaterializedViewStatus()];

declare 'SnapshotDefinition',
    as InstanceOf['Google::Cloud::BigQuery::V2::Table::SnapshotDefinition'];

coerce 'SnapshotDefinition',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Table::SnapshotDefinition'->new($_) };

declare 'RepeatedSnapshotDefinition',
    as ArrayRef[SnapshotDefinition()];

coerce 'RepeatedSnapshotDefinition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Table::SnapshotDefinition'->new($_) } @$_ ] };

declare 'MapStringSnapshotDefinition',
    as HashRef[SnapshotDefinition()];

declare 'CloneDefinition',
    as InstanceOf['Google::Cloud::BigQuery::V2::Table::CloneDefinition'];

coerce 'CloneDefinition',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Table::CloneDefinition'->new($_) };

declare 'RepeatedCloneDefinition',
    as ArrayRef[CloneDefinition()];

coerce 'RepeatedCloneDefinition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Table::CloneDefinition'->new($_) } @$_ ] };

declare 'MapStringCloneDefinition',
    as HashRef[CloneDefinition()];

declare 'Streamingbuffer',
    as InstanceOf['Google::Cloud::BigQuery::V2::Table::Streamingbuffer'];

coerce 'Streamingbuffer',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Table::Streamingbuffer'->new($_) };

declare 'RepeatedStreamingbuffer',
    as ArrayRef[Streamingbuffer()];

coerce 'RepeatedStreamingbuffer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Table::Streamingbuffer'->new($_) } @$_ ] };

declare 'MapStringStreamingbuffer',
    as HashRef[Streamingbuffer()];

declare 'Table',
    as InstanceOf['Google::Cloud::BigQuery::V2::Table::Table'];

coerce 'Table',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Table::Table'->new($_) };

declare 'RepeatedTable',
    as ArrayRef[Table()];

coerce 'RepeatedTable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Table::Table'->new($_) } @$_ ] };

declare 'MapStringTable',
    as HashRef[Table()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::BigQuery::V2::Table::Table::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Table::Table::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Table::Table::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ResourceTagsEntry',
    as InstanceOf['Google::Cloud::BigQuery::V2::Table::Table::ResourceTagsEntry'];

coerce 'ResourceTagsEntry',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Table::Table::ResourceTagsEntry'->new($_) };

declare 'RepeatedResourceTagsEntry',
    as ArrayRef[ResourceTagsEntry()];

coerce 'RepeatedResourceTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Table::Table::ResourceTagsEntry'->new($_) } @$_ ] };

declare 'MapStringResourceTagsEntry',
    as HashRef[ResourceTagsEntry()];

declare 'GetTableRequest',
    as InstanceOf['Google::Cloud::BigQuery::V2::Table::GetTableRequest'];

coerce 'GetTableRequest',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Table::GetTableRequest'->new($_) };

declare 'RepeatedGetTableRequest',
    as ArrayRef[GetTableRequest()];

coerce 'RepeatedGetTableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Table::GetTableRequest'->new($_) } @$_ ] };

declare 'MapStringGetTableRequest',
    as HashRef[GetTableRequest()];

declare 'TableMetadataView',
    as (Int | Str);

declare 'InsertTableRequest',
    as InstanceOf['Google::Cloud::BigQuery::V2::Table::InsertTableRequest'];

coerce 'InsertTableRequest',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Table::InsertTableRequest'->new($_) };

declare 'RepeatedInsertTableRequest',
    as ArrayRef[InsertTableRequest()];

coerce 'RepeatedInsertTableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Table::InsertTableRequest'->new($_) } @$_ ] };

declare 'MapStringInsertTableRequest',
    as HashRef[InsertTableRequest()];

declare 'UpdateOrPatchTableRequest',
    as InstanceOf['Google::Cloud::BigQuery::V2::Table::UpdateOrPatchTableRequest'];

coerce 'UpdateOrPatchTableRequest',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Table::UpdateOrPatchTableRequest'->new($_) };

declare 'RepeatedUpdateOrPatchTableRequest',
    as ArrayRef[UpdateOrPatchTableRequest()];

coerce 'RepeatedUpdateOrPatchTableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Table::UpdateOrPatchTableRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateOrPatchTableRequest',
    as HashRef[UpdateOrPatchTableRequest()];

declare 'DeleteTableRequest',
    as InstanceOf['Google::Cloud::BigQuery::V2::Table::DeleteTableRequest'];

coerce 'DeleteTableRequest',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Table::DeleteTableRequest'->new($_) };

declare 'RepeatedDeleteTableRequest',
    as ArrayRef[DeleteTableRequest()];

coerce 'RepeatedDeleteTableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Table::DeleteTableRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTableRequest',
    as HashRef[DeleteTableRequest()];

declare 'ListTablesRequest',
    as InstanceOf['Google::Cloud::BigQuery::V2::Table::ListTablesRequest'];

coerce 'ListTablesRequest',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Table::ListTablesRequest'->new($_) };

declare 'RepeatedListTablesRequest',
    as ArrayRef[ListTablesRequest()];

coerce 'RepeatedListTablesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Table::ListTablesRequest'->new($_) } @$_ ] };

declare 'MapStringListTablesRequest',
    as HashRef[ListTablesRequest()];

declare 'ListFormatView',
    as InstanceOf['Google::Cloud::BigQuery::V2::Table::ListFormatView'];

coerce 'ListFormatView',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Table::ListFormatView'->new($_) };

declare 'RepeatedListFormatView',
    as ArrayRef[ListFormatView()];

coerce 'RepeatedListFormatView',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Table::ListFormatView'->new($_) } @$_ ] };

declare 'MapStringListFormatView',
    as HashRef[ListFormatView()];

declare 'ListFormatTable',
    as InstanceOf['Google::Cloud::BigQuery::V2::Table::ListFormatTable'];

coerce 'ListFormatTable',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Table::ListFormatTable'->new($_) };

declare 'RepeatedListFormatTable',
    as ArrayRef[ListFormatTable()];

coerce 'RepeatedListFormatTable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Table::ListFormatTable'->new($_) } @$_ ] };

declare 'MapStringListFormatTable',
    as HashRef[ListFormatTable()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::BigQuery::V2::Table::ListFormatTable::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Table::ListFormatTable::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Table::ListFormatTable::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'TableList',
    as InstanceOf['Google::Cloud::BigQuery::V2::Table::TableList'];

coerce 'TableList',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Table::TableList'->new($_) };

declare 'RepeatedTableList',
    as ArrayRef[TableList()];

coerce 'RepeatedTableList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Table::TableList'->new($_) } @$_ ] };

declare 'MapStringTableList',
    as HashRef[TableList()];

1;
