package Google::Cloud::Bigquery::Logging::V1::AuditData::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AuditData',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::AuditData'];

coerce 'AuditData',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::AuditData'->new($_) };

declare 'RepeatedAuditData',
    as ArrayRef[AuditData()];

coerce 'RepeatedAuditData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::AuditData'->new($_) } @$_ ] };

declare 'MapStringAuditData',
    as HashRef[AuditData()];

declare 'TableInsertRequest',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::TableInsertRequest'];

coerce 'TableInsertRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::TableInsertRequest'->new($_) };

declare 'RepeatedTableInsertRequest',
    as ArrayRef[TableInsertRequest()];

coerce 'RepeatedTableInsertRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::TableInsertRequest'->new($_) } @$_ ] };

declare 'MapStringTableInsertRequest',
    as HashRef[TableInsertRequest()];

declare 'TableUpdateRequest',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::TableUpdateRequest'];

coerce 'TableUpdateRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::TableUpdateRequest'->new($_) };

declare 'RepeatedTableUpdateRequest',
    as ArrayRef[TableUpdateRequest()];

coerce 'RepeatedTableUpdateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::TableUpdateRequest'->new($_) } @$_ ] };

declare 'MapStringTableUpdateRequest',
    as HashRef[TableUpdateRequest()];

declare 'TableInsertResponse',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::TableInsertResponse'];

coerce 'TableInsertResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::TableInsertResponse'->new($_) };

declare 'RepeatedTableInsertResponse',
    as ArrayRef[TableInsertResponse()];

coerce 'RepeatedTableInsertResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::TableInsertResponse'->new($_) } @$_ ] };

declare 'MapStringTableInsertResponse',
    as HashRef[TableInsertResponse()];

declare 'TableUpdateResponse',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::TableUpdateResponse'];

coerce 'TableUpdateResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::TableUpdateResponse'->new($_) };

declare 'RepeatedTableUpdateResponse',
    as ArrayRef[TableUpdateResponse()];

coerce 'RepeatedTableUpdateResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::TableUpdateResponse'->new($_) } @$_ ] };

declare 'MapStringTableUpdateResponse',
    as HashRef[TableUpdateResponse()];

declare 'DatasetListRequest',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::DatasetListRequest'];

coerce 'DatasetListRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::DatasetListRequest'->new($_) };

declare 'RepeatedDatasetListRequest',
    as ArrayRef[DatasetListRequest()];

coerce 'RepeatedDatasetListRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::DatasetListRequest'->new($_) } @$_ ] };

declare 'MapStringDatasetListRequest',
    as HashRef[DatasetListRequest()];

declare 'DatasetInsertRequest',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::DatasetInsertRequest'];

coerce 'DatasetInsertRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::DatasetInsertRequest'->new($_) };

declare 'RepeatedDatasetInsertRequest',
    as ArrayRef[DatasetInsertRequest()];

coerce 'RepeatedDatasetInsertRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::DatasetInsertRequest'->new($_) } @$_ ] };

declare 'MapStringDatasetInsertRequest',
    as HashRef[DatasetInsertRequest()];

declare 'DatasetInsertResponse',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::DatasetInsertResponse'];

coerce 'DatasetInsertResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::DatasetInsertResponse'->new($_) };

declare 'RepeatedDatasetInsertResponse',
    as ArrayRef[DatasetInsertResponse()];

coerce 'RepeatedDatasetInsertResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::DatasetInsertResponse'->new($_) } @$_ ] };

declare 'MapStringDatasetInsertResponse',
    as HashRef[DatasetInsertResponse()];

declare 'DatasetUpdateRequest',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::DatasetUpdateRequest'];

coerce 'DatasetUpdateRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::DatasetUpdateRequest'->new($_) };

declare 'RepeatedDatasetUpdateRequest',
    as ArrayRef[DatasetUpdateRequest()];

coerce 'RepeatedDatasetUpdateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::DatasetUpdateRequest'->new($_) } @$_ ] };

declare 'MapStringDatasetUpdateRequest',
    as HashRef[DatasetUpdateRequest()];

declare 'DatasetUpdateResponse',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::DatasetUpdateResponse'];

coerce 'DatasetUpdateResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::DatasetUpdateResponse'->new($_) };

declare 'RepeatedDatasetUpdateResponse',
    as ArrayRef[DatasetUpdateResponse()];

coerce 'RepeatedDatasetUpdateResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::DatasetUpdateResponse'->new($_) } @$_ ] };

declare 'MapStringDatasetUpdateResponse',
    as HashRef[DatasetUpdateResponse()];

declare 'JobInsertRequest',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::JobInsertRequest'];

coerce 'JobInsertRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobInsertRequest'->new($_) };

declare 'RepeatedJobInsertRequest',
    as ArrayRef[JobInsertRequest()];

coerce 'RepeatedJobInsertRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobInsertRequest'->new($_) } @$_ ] };

declare 'MapStringJobInsertRequest',
    as HashRef[JobInsertRequest()];

declare 'JobInsertResponse',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::JobInsertResponse'];

coerce 'JobInsertResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobInsertResponse'->new($_) };

declare 'RepeatedJobInsertResponse',
    as ArrayRef[JobInsertResponse()];

coerce 'RepeatedJobInsertResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobInsertResponse'->new($_) } @$_ ] };

declare 'MapStringJobInsertResponse',
    as HashRef[JobInsertResponse()];

declare 'JobQueryRequest',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::JobQueryRequest'];

coerce 'JobQueryRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobQueryRequest'->new($_) };

declare 'RepeatedJobQueryRequest',
    as ArrayRef[JobQueryRequest()];

coerce 'RepeatedJobQueryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobQueryRequest'->new($_) } @$_ ] };

declare 'MapStringJobQueryRequest',
    as HashRef[JobQueryRequest()];

declare 'JobQueryResponse',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::JobQueryResponse'];

coerce 'JobQueryResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobQueryResponse'->new($_) };

declare 'RepeatedJobQueryResponse',
    as ArrayRef[JobQueryResponse()];

coerce 'RepeatedJobQueryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobQueryResponse'->new($_) } @$_ ] };

declare 'MapStringJobQueryResponse',
    as HashRef[JobQueryResponse()];

declare 'JobGetQueryResultsRequest',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::JobGetQueryResultsRequest'];

coerce 'JobGetQueryResultsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobGetQueryResultsRequest'->new($_) };

declare 'RepeatedJobGetQueryResultsRequest',
    as ArrayRef[JobGetQueryResultsRequest()];

coerce 'RepeatedJobGetQueryResultsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobGetQueryResultsRequest'->new($_) } @$_ ] };

declare 'MapStringJobGetQueryResultsRequest',
    as HashRef[JobGetQueryResultsRequest()];

declare 'JobGetQueryResultsResponse',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::JobGetQueryResultsResponse'];

coerce 'JobGetQueryResultsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobGetQueryResultsResponse'->new($_) };

declare 'RepeatedJobGetQueryResultsResponse',
    as ArrayRef[JobGetQueryResultsResponse()];

coerce 'RepeatedJobGetQueryResultsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobGetQueryResultsResponse'->new($_) } @$_ ] };

declare 'MapStringJobGetQueryResultsResponse',
    as HashRef[JobGetQueryResultsResponse()];

declare 'JobQueryDoneResponse',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::JobQueryDoneResponse'];

coerce 'JobQueryDoneResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobQueryDoneResponse'->new($_) };

declare 'RepeatedJobQueryDoneResponse',
    as ArrayRef[JobQueryDoneResponse()];

coerce 'RepeatedJobQueryDoneResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobQueryDoneResponse'->new($_) } @$_ ] };

declare 'MapStringJobQueryDoneResponse',
    as HashRef[JobQueryDoneResponse()];

declare 'JobCompletedEvent',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::JobCompletedEvent'];

coerce 'JobCompletedEvent',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobCompletedEvent'->new($_) };

declare 'RepeatedJobCompletedEvent',
    as ArrayRef[JobCompletedEvent()];

coerce 'RepeatedJobCompletedEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobCompletedEvent'->new($_) } @$_ ] };

declare 'MapStringJobCompletedEvent',
    as HashRef[JobCompletedEvent()];

declare 'TableDataReadEvent',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::TableDataReadEvent'];

coerce 'TableDataReadEvent',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::TableDataReadEvent'->new($_) };

declare 'RepeatedTableDataReadEvent',
    as ArrayRef[TableDataReadEvent()];

coerce 'RepeatedTableDataReadEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::TableDataReadEvent'->new($_) } @$_ ] };

declare 'MapStringTableDataReadEvent',
    as HashRef[TableDataReadEvent()];

declare 'TableDataListRequest',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::TableDataListRequest'];

coerce 'TableDataListRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::TableDataListRequest'->new($_) };

declare 'RepeatedTableDataListRequest',
    as ArrayRef[TableDataListRequest()];

coerce 'RepeatedTableDataListRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::TableDataListRequest'->new($_) } @$_ ] };

declare 'MapStringTableDataListRequest',
    as HashRef[TableDataListRequest()];

declare 'Table',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::Table'];

coerce 'Table',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::Table'->new($_) };

declare 'RepeatedTable',
    as ArrayRef[Table()];

coerce 'RepeatedTable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::Table'->new($_) } @$_ ] };

declare 'MapStringTable',
    as HashRef[Table()];

declare 'TableInfo',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::TableInfo'];

coerce 'TableInfo',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::TableInfo'->new($_) };

declare 'RepeatedTableInfo',
    as ArrayRef[TableInfo()];

coerce 'RepeatedTableInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::TableInfo'->new($_) } @$_ ] };

declare 'MapStringTableInfo',
    as HashRef[TableInfo()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::TableInfo::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::TableInfo::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::TableInfo::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'TableViewDefinition',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::TableViewDefinition'];

coerce 'TableViewDefinition',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::TableViewDefinition'->new($_) };

declare 'RepeatedTableViewDefinition',
    as ArrayRef[TableViewDefinition()];

coerce 'RepeatedTableViewDefinition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::TableViewDefinition'->new($_) } @$_ ] };

declare 'MapStringTableViewDefinition',
    as HashRef[TableViewDefinition()];

declare 'Dataset',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::Dataset'];

coerce 'Dataset',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::Dataset'->new($_) };

declare 'RepeatedDataset',
    as ArrayRef[Dataset()];

coerce 'RepeatedDataset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::Dataset'->new($_) } @$_ ] };

declare 'MapStringDataset',
    as HashRef[Dataset()];

declare 'DatasetInfo',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::DatasetInfo'];

coerce 'DatasetInfo',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::DatasetInfo'->new($_) };

declare 'RepeatedDatasetInfo',
    as ArrayRef[DatasetInfo()];

coerce 'RepeatedDatasetInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::DatasetInfo'->new($_) } @$_ ] };

declare 'MapStringDatasetInfo',
    as HashRef[DatasetInfo()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::DatasetInfo::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::DatasetInfo::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::DatasetInfo::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'BigQueryAcl',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::BigQueryAcl'];

coerce 'BigQueryAcl',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::BigQueryAcl'->new($_) };

declare 'RepeatedBigQueryAcl',
    as ArrayRef[BigQueryAcl()];

coerce 'RepeatedBigQueryAcl',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::BigQueryAcl'->new($_) } @$_ ] };

declare 'MapStringBigQueryAcl',
    as HashRef[BigQueryAcl()];

declare 'Entry',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::BigQueryAcl::Entry'];

coerce 'Entry',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::BigQueryAcl::Entry'->new($_) };

declare 'RepeatedEntry',
    as ArrayRef[Entry()];

coerce 'RepeatedEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::BigQueryAcl::Entry'->new($_) } @$_ ] };

declare 'MapStringEntry',
    as HashRef[Entry()];

declare 'Job',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::Job'];

coerce 'Job',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::Job'->new($_) };

declare 'RepeatedJob',
    as ArrayRef[Job()];

coerce 'RepeatedJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::Job'->new($_) } @$_ ] };

declare 'MapStringJob',
    as HashRef[Job()];

declare 'JobConfiguration',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::JobConfiguration'];

coerce 'JobConfiguration',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobConfiguration'->new($_) };

declare 'RepeatedJobConfiguration',
    as ArrayRef[JobConfiguration()];

coerce 'RepeatedJobConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobConfiguration'->new($_) } @$_ ] };

declare 'MapStringJobConfiguration',
    as HashRef[JobConfiguration()];

declare 'Query',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::JobConfiguration::Query'];

coerce 'Query',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobConfiguration::Query'->new($_) };

declare 'RepeatedQuery',
    as ArrayRef[Query()];

coerce 'RepeatedQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobConfiguration::Query'->new($_) } @$_ ] };

declare 'MapStringQuery',
    as HashRef[Query()];

declare 'Load',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::JobConfiguration::Load'];

coerce 'Load',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobConfiguration::Load'->new($_) };

declare 'RepeatedLoad',
    as ArrayRef[Load()];

coerce 'RepeatedLoad',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobConfiguration::Load'->new($_) } @$_ ] };

declare 'MapStringLoad',
    as HashRef[Load()];

declare 'Extract',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::JobConfiguration::Extract'];

coerce 'Extract',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobConfiguration::Extract'->new($_) };

declare 'RepeatedExtract',
    as ArrayRef[Extract()];

coerce 'RepeatedExtract',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobConfiguration::Extract'->new($_) } @$_ ] };

declare 'MapStringExtract',
    as HashRef[Extract()];

declare 'TableCopy',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::JobConfiguration::TableCopy'];

coerce 'TableCopy',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobConfiguration::TableCopy'->new($_) };

declare 'RepeatedTableCopy',
    as ArrayRef[TableCopy()];

coerce 'RepeatedTableCopy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobConfiguration::TableCopy'->new($_) } @$_ ] };

declare 'MapStringTableCopy',
    as HashRef[TableCopy()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::JobConfiguration::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobConfiguration::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobConfiguration::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'TableDefinition',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::TableDefinition'];

coerce 'TableDefinition',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::TableDefinition'->new($_) };

declare 'RepeatedTableDefinition',
    as ArrayRef[TableDefinition()];

coerce 'RepeatedTableDefinition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::TableDefinition'->new($_) } @$_ ] };

declare 'MapStringTableDefinition',
    as HashRef[TableDefinition()];

declare 'JobStatus',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::JobStatus'];

coerce 'JobStatus',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobStatus'->new($_) };

declare 'RepeatedJobStatus',
    as ArrayRef[JobStatus()];

coerce 'RepeatedJobStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobStatus'->new($_) } @$_ ] };

declare 'MapStringJobStatus',
    as HashRef[JobStatus()];

declare 'JobStatistics',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::JobStatistics'];

coerce 'JobStatistics',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobStatistics'->new($_) };

declare 'RepeatedJobStatistics',
    as ArrayRef[JobStatistics()];

coerce 'RepeatedJobStatistics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobStatistics'->new($_) } @$_ ] };

declare 'MapStringJobStatistics',
    as HashRef[JobStatistics()];

declare 'ReservationResourceUsage',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::JobStatistics::ReservationResourceUsage'];

coerce 'ReservationResourceUsage',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobStatistics::ReservationResourceUsage'->new($_) };

declare 'RepeatedReservationResourceUsage',
    as ArrayRef[ReservationResourceUsage()];

coerce 'RepeatedReservationResourceUsage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobStatistics::ReservationResourceUsage'->new($_) } @$_ ] };

declare 'MapStringReservationResourceUsage',
    as HashRef[ReservationResourceUsage()];

declare 'DatasetName',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::DatasetName'];

coerce 'DatasetName',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::DatasetName'->new($_) };

declare 'RepeatedDatasetName',
    as ArrayRef[DatasetName()];

coerce 'RepeatedDatasetName',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::DatasetName'->new($_) } @$_ ] };

declare 'MapStringDatasetName',
    as HashRef[DatasetName()];

declare 'TableName',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::TableName'];

coerce 'TableName',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::TableName'->new($_) };

declare 'RepeatedTableName',
    as ArrayRef[TableName()];

coerce 'RepeatedTableName',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::TableName'->new($_) } @$_ ] };

declare 'MapStringTableName',
    as HashRef[TableName()];

declare 'JobName',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::JobName'];

coerce 'JobName',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobName'->new($_) };

declare 'RepeatedJobName',
    as ArrayRef[JobName()];

coerce 'RepeatedJobName',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::JobName'->new($_) } @$_ ] };

declare 'MapStringJobName',
    as HashRef[JobName()];

declare 'EncryptionInfo',
    as InstanceOf['Google::Cloud::Bigquery::Logging::V1::AuditData::EncryptionInfo'];

coerce 'EncryptionInfo',
    from HashRef, via { 'Google::Cloud::Bigquery::Logging::V1::AuditData::EncryptionInfo'->new($_) };

declare 'RepeatedEncryptionInfo',
    as ArrayRef[EncryptionInfo()];

coerce 'RepeatedEncryptionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Logging::V1::AuditData::EncryptionInfo'->new($_) } @$_ ] };

declare 'MapStringEncryptionInfo',
    as HashRef[EncryptionInfo()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Logging::V1::AuditData::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
