package Google::Cloud::Storageinsights::V1::Storageinsights::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListReportConfigsRequest',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::ListReportConfigsRequest'];

coerce 'ListReportConfigsRequest',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::ListReportConfigsRequest'->new($_) };

declare 'RepeatedListReportConfigsRequest',
    as ArrayRef[ListReportConfigsRequest()];

coerce 'RepeatedListReportConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::ListReportConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListReportConfigsRequest',
    as HashRef[ListReportConfigsRequest()];

declare 'ListReportConfigsResponse',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::ListReportConfigsResponse'];

coerce 'ListReportConfigsResponse',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::ListReportConfigsResponse'->new($_) };

declare 'RepeatedListReportConfigsResponse',
    as ArrayRef[ListReportConfigsResponse()];

coerce 'RepeatedListReportConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::ListReportConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListReportConfigsResponse',
    as HashRef[ListReportConfigsResponse()];

declare 'GetReportConfigRequest',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::GetReportConfigRequest'];

coerce 'GetReportConfigRequest',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::GetReportConfigRequest'->new($_) };

declare 'RepeatedGetReportConfigRequest',
    as ArrayRef[GetReportConfigRequest()];

coerce 'RepeatedGetReportConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::GetReportConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetReportConfigRequest',
    as HashRef[GetReportConfigRequest()];

declare 'CreateReportConfigRequest',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::CreateReportConfigRequest'];

coerce 'CreateReportConfigRequest',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::CreateReportConfigRequest'->new($_) };

declare 'RepeatedCreateReportConfigRequest',
    as ArrayRef[CreateReportConfigRequest()];

coerce 'RepeatedCreateReportConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::CreateReportConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateReportConfigRequest',
    as HashRef[CreateReportConfigRequest()];

declare 'UpdateReportConfigRequest',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::UpdateReportConfigRequest'];

coerce 'UpdateReportConfigRequest',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::UpdateReportConfigRequest'->new($_) };

declare 'RepeatedUpdateReportConfigRequest',
    as ArrayRef[UpdateReportConfigRequest()];

coerce 'RepeatedUpdateReportConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::UpdateReportConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateReportConfigRequest',
    as HashRef[UpdateReportConfigRequest()];

declare 'DeleteReportConfigRequest',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::DeleteReportConfigRequest'];

coerce 'DeleteReportConfigRequest',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::DeleteReportConfigRequest'->new($_) };

declare 'RepeatedDeleteReportConfigRequest',
    as ArrayRef[DeleteReportConfigRequest()];

coerce 'RepeatedDeleteReportConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::DeleteReportConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteReportConfigRequest',
    as HashRef[DeleteReportConfigRequest()];

declare 'ReportDetail',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::ReportDetail'];

coerce 'ReportDetail',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::ReportDetail'->new($_) };

declare 'RepeatedReportDetail',
    as ArrayRef[ReportDetail()];

coerce 'RepeatedReportDetail',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::ReportDetail'->new($_) } @$_ ] };

declare 'MapStringReportDetail',
    as HashRef[ReportDetail()];

declare 'Metrics',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::ReportDetail::Metrics'];

coerce 'Metrics',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::ReportDetail::Metrics'->new($_) };

declare 'RepeatedMetrics',
    as ArrayRef[Metrics()];

coerce 'RepeatedMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::ReportDetail::Metrics'->new($_) } @$_ ] };

declare 'MapStringMetrics',
    as HashRef[Metrics()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::ReportDetail::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::ReportDetail::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::ReportDetail::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListReportDetailsRequest',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::ListReportDetailsRequest'];

coerce 'ListReportDetailsRequest',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::ListReportDetailsRequest'->new($_) };

declare 'RepeatedListReportDetailsRequest',
    as ArrayRef[ListReportDetailsRequest()];

coerce 'RepeatedListReportDetailsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::ListReportDetailsRequest'->new($_) } @$_ ] };

declare 'MapStringListReportDetailsRequest',
    as HashRef[ListReportDetailsRequest()];

declare 'ListReportDetailsResponse',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::ListReportDetailsResponse'];

coerce 'ListReportDetailsResponse',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::ListReportDetailsResponse'->new($_) };

declare 'RepeatedListReportDetailsResponse',
    as ArrayRef[ListReportDetailsResponse()];

coerce 'RepeatedListReportDetailsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::ListReportDetailsResponse'->new($_) } @$_ ] };

declare 'MapStringListReportDetailsResponse',
    as HashRef[ListReportDetailsResponse()];

declare 'GetReportDetailRequest',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::GetReportDetailRequest'];

coerce 'GetReportDetailRequest',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::GetReportDetailRequest'->new($_) };

declare 'RepeatedGetReportDetailRequest',
    as ArrayRef[GetReportDetailRequest()];

coerce 'RepeatedGetReportDetailRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::GetReportDetailRequest'->new($_) } @$_ ] };

declare 'MapStringGetReportDetailRequest',
    as HashRef[GetReportDetailRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'FrequencyOptions',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::FrequencyOptions'];

coerce 'FrequencyOptions',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::FrequencyOptions'->new($_) };

declare 'RepeatedFrequencyOptions',
    as ArrayRef[FrequencyOptions()];

coerce 'RepeatedFrequencyOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::FrequencyOptions'->new($_) } @$_ ] };

declare 'MapStringFrequencyOptions',
    as HashRef[FrequencyOptions()];

declare 'Frequency',
    as (Int | Str);

declare 'CSVOptions',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::CSVOptions'];

coerce 'CSVOptions',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::CSVOptions'->new($_) };

declare 'RepeatedCSVOptions',
    as ArrayRef[CSVOptions()];

coerce 'RepeatedCSVOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::CSVOptions'->new($_) } @$_ ] };

declare 'MapStringCSVOptions',
    as HashRef[CSVOptions()];

declare 'ParquetOptions',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::ParquetOptions'];

coerce 'ParquetOptions',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::ParquetOptions'->new($_) };

declare 'RepeatedParquetOptions',
    as ArrayRef[ParquetOptions()];

coerce 'RepeatedParquetOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::ParquetOptions'->new($_) } @$_ ] };

declare 'MapStringParquetOptions',
    as HashRef[ParquetOptions()];

declare 'CloudStorageFilters',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::CloudStorageFilters'];

coerce 'CloudStorageFilters',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::CloudStorageFilters'->new($_) };

declare 'RepeatedCloudStorageFilters',
    as ArrayRef[CloudStorageFilters()];

coerce 'RepeatedCloudStorageFilters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::CloudStorageFilters'->new($_) } @$_ ] };

declare 'MapStringCloudStorageFilters',
    as HashRef[CloudStorageFilters()];

declare 'CloudStorageDestinationOptions',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::CloudStorageDestinationOptions'];

coerce 'CloudStorageDestinationOptions',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::CloudStorageDestinationOptions'->new($_) };

declare 'RepeatedCloudStorageDestinationOptions',
    as ArrayRef[CloudStorageDestinationOptions()];

coerce 'RepeatedCloudStorageDestinationOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::CloudStorageDestinationOptions'->new($_) } @$_ ] };

declare 'MapStringCloudStorageDestinationOptions',
    as HashRef[CloudStorageDestinationOptions()];

declare 'ObjectMetadataReportOptions',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::ObjectMetadataReportOptions'];

coerce 'ObjectMetadataReportOptions',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::ObjectMetadataReportOptions'->new($_) };

declare 'RepeatedObjectMetadataReportOptions',
    as ArrayRef[ObjectMetadataReportOptions()];

coerce 'RepeatedObjectMetadataReportOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::ObjectMetadataReportOptions'->new($_) } @$_ ] };

declare 'MapStringObjectMetadataReportOptions',
    as HashRef[ObjectMetadataReportOptions()];

declare 'ReportConfig',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::ReportConfig'];

coerce 'ReportConfig',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::ReportConfig'->new($_) };

declare 'RepeatedReportConfig',
    as ArrayRef[ReportConfig()];

coerce 'RepeatedReportConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::ReportConfig'->new($_) } @$_ ] };

declare 'MapStringReportConfig',
    as HashRef[ReportConfig()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::ReportConfig::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::ReportConfig::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::ReportConfig::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Identity',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::Identity'];

coerce 'Identity',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::Identity'->new($_) };

declare 'RepeatedIdentity',
    as ArrayRef[Identity()];

coerce 'RepeatedIdentity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::Identity'->new($_) } @$_ ] };

declare 'MapStringIdentity',
    as HashRef[Identity()];

declare 'IdentityType',
    as (Int | Str);

declare 'DatasetConfig',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::DatasetConfig'];

coerce 'DatasetConfig',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::DatasetConfig'->new($_) };

declare 'RepeatedDatasetConfig',
    as ArrayRef[DatasetConfig()];

coerce 'RepeatedDatasetConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::DatasetConfig'->new($_) } @$_ ] };

declare 'MapStringDatasetConfig',
    as HashRef[DatasetConfig()];

declare 'ConfigState',
    as (Int | Str);

declare 'SourceProjects',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::DatasetConfig::SourceProjects'];

coerce 'SourceProjects',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::DatasetConfig::SourceProjects'->new($_) };

declare 'RepeatedSourceProjects',
    as ArrayRef[SourceProjects()];

coerce 'RepeatedSourceProjects',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::DatasetConfig::SourceProjects'->new($_) } @$_ ] };

declare 'MapStringSourceProjects',
    as HashRef[SourceProjects()];

declare 'SourceFolders',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::DatasetConfig::SourceFolders'];

coerce 'SourceFolders',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::DatasetConfig::SourceFolders'->new($_) };

declare 'RepeatedSourceFolders',
    as ArrayRef[SourceFolders()];

coerce 'RepeatedSourceFolders',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::DatasetConfig::SourceFolders'->new($_) } @$_ ] };

declare 'MapStringSourceFolders',
    as HashRef[SourceFolders()];

declare 'CloudStorageLocations',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::DatasetConfig::CloudStorageLocations'];

coerce 'CloudStorageLocations',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::DatasetConfig::CloudStorageLocations'->new($_) };

declare 'RepeatedCloudStorageLocations',
    as ArrayRef[CloudStorageLocations()];

coerce 'RepeatedCloudStorageLocations',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::DatasetConfig::CloudStorageLocations'->new($_) } @$_ ] };

declare 'MapStringCloudStorageLocations',
    as HashRef[CloudStorageLocations()];

declare 'CloudStorageBuckets',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::DatasetConfig::CloudStorageBuckets'];

coerce 'CloudStorageBuckets',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::DatasetConfig::CloudStorageBuckets'->new($_) };

declare 'RepeatedCloudStorageBuckets',
    as ArrayRef[CloudStorageBuckets()];

coerce 'RepeatedCloudStorageBuckets',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::DatasetConfig::CloudStorageBuckets'->new($_) } @$_ ] };

declare 'MapStringCloudStorageBuckets',
    as HashRef[CloudStorageBuckets()];

declare 'CloudStorageBucket',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::DatasetConfig::CloudStorageBuckets::CloudStorageBucket'];

coerce 'CloudStorageBucket',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::DatasetConfig::CloudStorageBuckets::CloudStorageBucket'->new($_) };

declare 'RepeatedCloudStorageBucket',
    as ArrayRef[CloudStorageBucket()];

coerce 'RepeatedCloudStorageBucket',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::DatasetConfig::CloudStorageBuckets::CloudStorageBucket'->new($_) } @$_ ] };

declare 'MapStringCloudStorageBucket',
    as HashRef[CloudStorageBucket()];

declare 'Link',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::DatasetConfig::Link'];

coerce 'Link',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::DatasetConfig::Link'->new($_) };

declare 'RepeatedLink',
    as ArrayRef[Link()];

coerce 'RepeatedLink',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::DatasetConfig::Link'->new($_) } @$_ ] };

declare 'MapStringLink',
    as HashRef[Link()];

declare 'BucketErrors',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::DatasetConfig::BucketErrors'];

coerce 'BucketErrors',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::DatasetConfig::BucketErrors'->new($_) };

declare 'RepeatedBucketErrors',
    as ArrayRef[BucketErrors()];

coerce 'RepeatedBucketErrors',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::DatasetConfig::BucketErrors'->new($_) } @$_ ] };

declare 'MapStringBucketErrors',
    as HashRef[BucketErrors()];

declare 'ProjectErrors',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::DatasetConfig::ProjectErrors'];

coerce 'ProjectErrors',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::DatasetConfig::ProjectErrors'->new($_) };

declare 'RepeatedProjectErrors',
    as ArrayRef[ProjectErrors()];

coerce 'RepeatedProjectErrors',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::DatasetConfig::ProjectErrors'->new($_) } @$_ ] };

declare 'MapStringProjectErrors',
    as HashRef[ProjectErrors()];

declare 'ValidationErrorsBeforeIngestion',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::DatasetConfig::ValidationErrorsBeforeIngestion'];

coerce 'ValidationErrorsBeforeIngestion',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::DatasetConfig::ValidationErrorsBeforeIngestion'->new($_) };

declare 'RepeatedValidationErrorsBeforeIngestion',
    as ArrayRef[ValidationErrorsBeforeIngestion()];

coerce 'RepeatedValidationErrorsBeforeIngestion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::DatasetConfig::ValidationErrorsBeforeIngestion'->new($_) } @$_ ] };

declare 'MapStringValidationErrorsBeforeIngestion',
    as HashRef[ValidationErrorsBeforeIngestion()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::DatasetConfig::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::DatasetConfig::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::DatasetConfig::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListDatasetConfigsRequest',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::ListDatasetConfigsRequest'];

coerce 'ListDatasetConfigsRequest',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::ListDatasetConfigsRequest'->new($_) };

declare 'RepeatedListDatasetConfigsRequest',
    as ArrayRef[ListDatasetConfigsRequest()];

coerce 'RepeatedListDatasetConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::ListDatasetConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListDatasetConfigsRequest',
    as HashRef[ListDatasetConfigsRequest()];

declare 'ListDatasetConfigsResponse',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::ListDatasetConfigsResponse'];

coerce 'ListDatasetConfigsResponse',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::ListDatasetConfigsResponse'->new($_) };

declare 'RepeatedListDatasetConfigsResponse',
    as ArrayRef[ListDatasetConfigsResponse()];

coerce 'RepeatedListDatasetConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::ListDatasetConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListDatasetConfigsResponse',
    as HashRef[ListDatasetConfigsResponse()];

declare 'GetDatasetConfigRequest',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::GetDatasetConfigRequest'];

coerce 'GetDatasetConfigRequest',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::GetDatasetConfigRequest'->new($_) };

declare 'RepeatedGetDatasetConfigRequest',
    as ArrayRef[GetDatasetConfigRequest()];

coerce 'RepeatedGetDatasetConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::GetDatasetConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetDatasetConfigRequest',
    as HashRef[GetDatasetConfigRequest()];

declare 'CreateDatasetConfigRequest',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::CreateDatasetConfigRequest'];

coerce 'CreateDatasetConfigRequest',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::CreateDatasetConfigRequest'->new($_) };

declare 'RepeatedCreateDatasetConfigRequest',
    as ArrayRef[CreateDatasetConfigRequest()];

coerce 'RepeatedCreateDatasetConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::CreateDatasetConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDatasetConfigRequest',
    as HashRef[CreateDatasetConfigRequest()];

declare 'UpdateDatasetConfigRequest',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::UpdateDatasetConfigRequest'];

coerce 'UpdateDatasetConfigRequest',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::UpdateDatasetConfigRequest'->new($_) };

declare 'RepeatedUpdateDatasetConfigRequest',
    as ArrayRef[UpdateDatasetConfigRequest()];

coerce 'RepeatedUpdateDatasetConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::UpdateDatasetConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDatasetConfigRequest',
    as HashRef[UpdateDatasetConfigRequest()];

declare 'DeleteDatasetConfigRequest',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::DeleteDatasetConfigRequest'];

coerce 'DeleteDatasetConfigRequest',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::DeleteDatasetConfigRequest'->new($_) };

declare 'RepeatedDeleteDatasetConfigRequest',
    as ArrayRef[DeleteDatasetConfigRequest()];

coerce 'RepeatedDeleteDatasetConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::DeleteDatasetConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDatasetConfigRequest',
    as HashRef[DeleteDatasetConfigRequest()];

declare 'LinkDatasetRequest',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::LinkDatasetRequest'];

coerce 'LinkDatasetRequest',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::LinkDatasetRequest'->new($_) };

declare 'RepeatedLinkDatasetRequest',
    as ArrayRef[LinkDatasetRequest()];

coerce 'RepeatedLinkDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::LinkDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringLinkDatasetRequest',
    as HashRef[LinkDatasetRequest()];

declare 'LinkDatasetResponse',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::LinkDatasetResponse'];

coerce 'LinkDatasetResponse',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::LinkDatasetResponse'->new($_) };

declare 'RepeatedLinkDatasetResponse',
    as ArrayRef[LinkDatasetResponse()];

coerce 'RepeatedLinkDatasetResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::LinkDatasetResponse'->new($_) } @$_ ] };

declare 'MapStringLinkDatasetResponse',
    as HashRef[LinkDatasetResponse()];

declare 'UnlinkDatasetRequest',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::UnlinkDatasetRequest'];

coerce 'UnlinkDatasetRequest',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::UnlinkDatasetRequest'->new($_) };

declare 'RepeatedUnlinkDatasetRequest',
    as ArrayRef[UnlinkDatasetRequest()];

coerce 'RepeatedUnlinkDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::UnlinkDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringUnlinkDatasetRequest',
    as HashRef[UnlinkDatasetRequest()];

declare 'LocationMetadata',
    as InstanceOf['Google::Cloud::Storageinsights::V1::Storageinsights::LocationMetadata'];

coerce 'LocationMetadata',
    from HashRef, via { 'Google::Cloud::Storageinsights::V1::Storageinsights::LocationMetadata'->new($_) };

declare 'RepeatedLocationMetadata',
    as ArrayRef[LocationMetadata()];

coerce 'RepeatedLocationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storageinsights::V1::Storageinsights::LocationMetadata'->new($_) } @$_ ] };

declare 'MapStringLocationMetadata',
    as HashRef[LocationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Storageinsights::V1::Storageinsights::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
