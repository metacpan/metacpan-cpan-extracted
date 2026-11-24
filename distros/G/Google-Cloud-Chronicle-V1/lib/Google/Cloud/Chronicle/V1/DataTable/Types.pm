package Google::Cloud::Chronicle::V1::DataTable::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataTableUpdateSource',
    as (Int | Str);

declare 'CreateDataTableRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataTable::CreateDataTableRequest'];

coerce 'CreateDataTableRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataTable::CreateDataTableRequest'->new($_) };

declare 'RepeatedCreateDataTableRequest',
    as ArrayRef[CreateDataTableRequest()];

coerce 'RepeatedCreateDataTableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataTable::CreateDataTableRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDataTableRequest',
    as HashRef[CreateDataTableRequest()];

declare 'GetDataTableRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataTable::GetDataTableRequest'];

coerce 'GetDataTableRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataTable::GetDataTableRequest'->new($_) };

declare 'RepeatedGetDataTableRequest',
    as ArrayRef[GetDataTableRequest()];

coerce 'RepeatedGetDataTableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataTable::GetDataTableRequest'->new($_) } @$_ ] };

declare 'MapStringGetDataTableRequest',
    as HashRef[GetDataTableRequest()];

declare 'UpdateDataTableRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataTable::UpdateDataTableRequest'];

coerce 'UpdateDataTableRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataTable::UpdateDataTableRequest'->new($_) };

declare 'RepeatedUpdateDataTableRequest',
    as ArrayRef[UpdateDataTableRequest()];

coerce 'RepeatedUpdateDataTableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataTable::UpdateDataTableRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDataTableRequest',
    as HashRef[UpdateDataTableRequest()];

declare 'ListDataTablesRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataTable::ListDataTablesRequest'];

coerce 'ListDataTablesRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataTable::ListDataTablesRequest'->new($_) };

declare 'RepeatedListDataTablesRequest',
    as ArrayRef[ListDataTablesRequest()];

coerce 'RepeatedListDataTablesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataTable::ListDataTablesRequest'->new($_) } @$_ ] };

declare 'MapStringListDataTablesRequest',
    as HashRef[ListDataTablesRequest()];

declare 'DeleteDataTableRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataTable::DeleteDataTableRequest'];

coerce 'DeleteDataTableRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataTable::DeleteDataTableRequest'->new($_) };

declare 'RepeatedDeleteDataTableRequest',
    as ArrayRef[DeleteDataTableRequest()];

coerce 'RepeatedDeleteDataTableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataTable::DeleteDataTableRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDataTableRequest',
    as HashRef[DeleteDataTableRequest()];

declare 'ListDataTablesResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataTable::ListDataTablesResponse'];

coerce 'ListDataTablesResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataTable::ListDataTablesResponse'->new($_) };

declare 'RepeatedListDataTablesResponse',
    as ArrayRef[ListDataTablesResponse()];

coerce 'RepeatedListDataTablesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataTable::ListDataTablesResponse'->new($_) } @$_ ] };

declare 'MapStringListDataTablesResponse',
    as HashRef[ListDataTablesResponse()];

declare 'CreateDataTableRowRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataTable::CreateDataTableRowRequest'];

coerce 'CreateDataTableRowRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataTable::CreateDataTableRowRequest'->new($_) };

declare 'RepeatedCreateDataTableRowRequest',
    as ArrayRef[CreateDataTableRowRequest()];

coerce 'RepeatedCreateDataTableRowRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataTable::CreateDataTableRowRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDataTableRowRequest',
    as HashRef[CreateDataTableRowRequest()];

declare 'UpdateDataTableRowRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataTable::UpdateDataTableRowRequest'];

coerce 'UpdateDataTableRowRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataTable::UpdateDataTableRowRequest'->new($_) };

declare 'RepeatedUpdateDataTableRowRequest',
    as ArrayRef[UpdateDataTableRowRequest()];

coerce 'RepeatedUpdateDataTableRowRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataTable::UpdateDataTableRowRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDataTableRowRequest',
    as HashRef[UpdateDataTableRowRequest()];

declare 'ListDataTableRowsRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataTable::ListDataTableRowsRequest'];

coerce 'ListDataTableRowsRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataTable::ListDataTableRowsRequest'->new($_) };

declare 'RepeatedListDataTableRowsRequest',
    as ArrayRef[ListDataTableRowsRequest()];

coerce 'RepeatedListDataTableRowsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataTable::ListDataTableRowsRequest'->new($_) } @$_ ] };

declare 'MapStringListDataTableRowsRequest',
    as HashRef[ListDataTableRowsRequest()];

declare 'ListDataTableRowsResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataTable::ListDataTableRowsResponse'];

coerce 'ListDataTableRowsResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataTable::ListDataTableRowsResponse'->new($_) };

declare 'RepeatedListDataTableRowsResponse',
    as ArrayRef[ListDataTableRowsResponse()];

coerce 'RepeatedListDataTableRowsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataTable::ListDataTableRowsResponse'->new($_) } @$_ ] };

declare 'MapStringListDataTableRowsResponse',
    as HashRef[ListDataTableRowsResponse()];

declare 'GetDataTableRowRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataTable::GetDataTableRowRequest'];

coerce 'GetDataTableRowRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataTable::GetDataTableRowRequest'->new($_) };

declare 'RepeatedGetDataTableRowRequest',
    as ArrayRef[GetDataTableRowRequest()];

coerce 'RepeatedGetDataTableRowRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataTable::GetDataTableRowRequest'->new($_) } @$_ ] };

declare 'MapStringGetDataTableRowRequest',
    as HashRef[GetDataTableRowRequest()];

declare 'DeleteDataTableRowRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataTable::DeleteDataTableRowRequest'];

coerce 'DeleteDataTableRowRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataTable::DeleteDataTableRowRequest'->new($_) };

declare 'RepeatedDeleteDataTableRowRequest',
    as ArrayRef[DeleteDataTableRowRequest()];

coerce 'RepeatedDeleteDataTableRowRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataTable::DeleteDataTableRowRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDataTableRowRequest',
    as HashRef[DeleteDataTableRowRequest()];

declare 'BulkCreateDataTableRowsRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataTable::BulkCreateDataTableRowsRequest'];

coerce 'BulkCreateDataTableRowsRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataTable::BulkCreateDataTableRowsRequest'->new($_) };

declare 'RepeatedBulkCreateDataTableRowsRequest',
    as ArrayRef[BulkCreateDataTableRowsRequest()];

coerce 'RepeatedBulkCreateDataTableRowsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataTable::BulkCreateDataTableRowsRequest'->new($_) } @$_ ] };

declare 'MapStringBulkCreateDataTableRowsRequest',
    as HashRef[BulkCreateDataTableRowsRequest()];

declare 'BulkCreateDataTableRowsResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataTable::BulkCreateDataTableRowsResponse'];

coerce 'BulkCreateDataTableRowsResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataTable::BulkCreateDataTableRowsResponse'->new($_) };

declare 'RepeatedBulkCreateDataTableRowsResponse',
    as ArrayRef[BulkCreateDataTableRowsResponse()];

coerce 'RepeatedBulkCreateDataTableRowsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataTable::BulkCreateDataTableRowsResponse'->new($_) } @$_ ] };

declare 'MapStringBulkCreateDataTableRowsResponse',
    as HashRef[BulkCreateDataTableRowsResponse()];

declare 'BulkGetDataTableRowsRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataTable::BulkGetDataTableRowsRequest'];

coerce 'BulkGetDataTableRowsRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataTable::BulkGetDataTableRowsRequest'->new($_) };

declare 'RepeatedBulkGetDataTableRowsRequest',
    as ArrayRef[BulkGetDataTableRowsRequest()];

coerce 'RepeatedBulkGetDataTableRowsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataTable::BulkGetDataTableRowsRequest'->new($_) } @$_ ] };

declare 'MapStringBulkGetDataTableRowsRequest',
    as HashRef[BulkGetDataTableRowsRequest()];

declare 'BulkGetDataTableRowsResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataTable::BulkGetDataTableRowsResponse'];

coerce 'BulkGetDataTableRowsResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataTable::BulkGetDataTableRowsResponse'->new($_) };

declare 'RepeatedBulkGetDataTableRowsResponse',
    as ArrayRef[BulkGetDataTableRowsResponse()];

coerce 'RepeatedBulkGetDataTableRowsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataTable::BulkGetDataTableRowsResponse'->new($_) } @$_ ] };

declare 'MapStringBulkGetDataTableRowsResponse',
    as HashRef[BulkGetDataTableRowsResponse()];

declare 'BulkReplaceDataTableRowsRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataTable::BulkReplaceDataTableRowsRequest'];

coerce 'BulkReplaceDataTableRowsRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataTable::BulkReplaceDataTableRowsRequest'->new($_) };

declare 'RepeatedBulkReplaceDataTableRowsRequest',
    as ArrayRef[BulkReplaceDataTableRowsRequest()];

coerce 'RepeatedBulkReplaceDataTableRowsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataTable::BulkReplaceDataTableRowsRequest'->new($_) } @$_ ] };

declare 'MapStringBulkReplaceDataTableRowsRequest',
    as HashRef[BulkReplaceDataTableRowsRequest()];

declare 'BulkReplaceDataTableRowsResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataTable::BulkReplaceDataTableRowsResponse'];

coerce 'BulkReplaceDataTableRowsResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataTable::BulkReplaceDataTableRowsResponse'->new($_) };

declare 'RepeatedBulkReplaceDataTableRowsResponse',
    as ArrayRef[BulkReplaceDataTableRowsResponse()];

coerce 'RepeatedBulkReplaceDataTableRowsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataTable::BulkReplaceDataTableRowsResponse'->new($_) } @$_ ] };

declare 'MapStringBulkReplaceDataTableRowsResponse',
    as HashRef[BulkReplaceDataTableRowsResponse()];

declare 'BulkUpdateDataTableRowsRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataTable::BulkUpdateDataTableRowsRequest'];

coerce 'BulkUpdateDataTableRowsRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataTable::BulkUpdateDataTableRowsRequest'->new($_) };

declare 'RepeatedBulkUpdateDataTableRowsRequest',
    as ArrayRef[BulkUpdateDataTableRowsRequest()];

coerce 'RepeatedBulkUpdateDataTableRowsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataTable::BulkUpdateDataTableRowsRequest'->new($_) } @$_ ] };

declare 'MapStringBulkUpdateDataTableRowsRequest',
    as HashRef[BulkUpdateDataTableRowsRequest()];

declare 'BulkUpdateDataTableRowsResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataTable::BulkUpdateDataTableRowsResponse'];

coerce 'BulkUpdateDataTableRowsResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataTable::BulkUpdateDataTableRowsResponse'->new($_) };

declare 'RepeatedBulkUpdateDataTableRowsResponse',
    as ArrayRef[BulkUpdateDataTableRowsResponse()];

coerce 'RepeatedBulkUpdateDataTableRowsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataTable::BulkUpdateDataTableRowsResponse'->new($_) } @$_ ] };

declare 'MapStringBulkUpdateDataTableRowsResponse',
    as HashRef[BulkUpdateDataTableRowsResponse()];

declare 'DataTableScopeInfo',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataTable::DataTableScopeInfo'];

coerce 'DataTableScopeInfo',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataTable::DataTableScopeInfo'->new($_) };

declare 'RepeatedDataTableScopeInfo',
    as ArrayRef[DataTableScopeInfo()];

coerce 'RepeatedDataTableScopeInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataTable::DataTableScopeInfo'->new($_) } @$_ ] };

declare 'MapStringDataTableScopeInfo',
    as HashRef[DataTableScopeInfo()];

declare 'DataTable',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataTable::DataTable'];

coerce 'DataTable',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataTable::DataTable'->new($_) };

declare 'RepeatedDataTable',
    as ArrayRef[DataTable()];

coerce 'RepeatedDataTable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataTable::DataTable'->new($_) } @$_ ] };

declare 'MapStringDataTable',
    as HashRef[DataTable()];

declare 'DataTableRow',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataTable::DataTableRow'];

coerce 'DataTableRow',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataTable::DataTableRow'->new($_) };

declare 'RepeatedDataTableRow',
    as ArrayRef[DataTableRow()];

coerce 'RepeatedDataTableRow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataTable::DataTableRow'->new($_) } @$_ ] };

declare 'MapStringDataTableRow',
    as HashRef[DataTableRow()];

declare 'DataTableColumnInfo',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataTable::DataTableColumnInfo'];

coerce 'DataTableColumnInfo',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataTable::DataTableColumnInfo'->new($_) };

declare 'RepeatedDataTableColumnInfo',
    as ArrayRef[DataTableColumnInfo()];

coerce 'RepeatedDataTableColumnInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataTable::DataTableColumnInfo'->new($_) } @$_ ] };

declare 'MapStringDataTableColumnInfo',
    as HashRef[DataTableColumnInfo()];

declare 'DataTableColumnType',
    as (Int | Str);

declare 'GetDataTableOperationErrorsRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataTable::GetDataTableOperationErrorsRequest'];

coerce 'GetDataTableOperationErrorsRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataTable::GetDataTableOperationErrorsRequest'->new($_) };

declare 'RepeatedGetDataTableOperationErrorsRequest',
    as ArrayRef[GetDataTableOperationErrorsRequest()];

coerce 'RepeatedGetDataTableOperationErrorsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataTable::GetDataTableOperationErrorsRequest'->new($_) } @$_ ] };

declare 'MapStringGetDataTableOperationErrorsRequest',
    as HashRef[GetDataTableOperationErrorsRequest()];

declare 'DataTableOperationErrors',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataTable::DataTableOperationErrors'];

coerce 'DataTableOperationErrors',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataTable::DataTableOperationErrors'->new($_) };

declare 'RepeatedDataTableOperationErrors',
    as ArrayRef[DataTableOperationErrors()];

coerce 'RepeatedDataTableOperationErrors',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataTable::DataTableOperationErrors'->new($_) } @$_ ] };

declare 'MapStringDataTableOperationErrors',
    as HashRef[DataTableOperationErrors()];

1;

__END__

=head1 NAME

Google::Cloud::Chronicle::V1::DataTable::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
