package Google::Cloud::Migrationcenter::V1::Migrationcenter::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AssetView',
    as (Int | Str);

declare 'OperatingSystemFamily',
    as (Int | Str);

declare 'ImportJobFormat',
    as (Int | Str);

declare 'ImportJobView',
    as (Int | Str);

declare 'ErrorFrameView',
    as (Int | Str);

declare 'PersistentDiskType',
    as (Int | Str);

declare 'LicenseType',
    as (Int | Str);

declare 'SizingOptimizationStrategy',
    as (Int | Str);

declare 'CommitmentPlan',
    as (Int | Str);

declare 'ComputeMigrationTargetProduct',
    as (Int | Str);

declare 'ReportView',
    as (Int | Str);

declare 'Asset',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::Asset'];

coerce 'Asset',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::Asset'->new($_) };

declare 'RepeatedAsset',
    as ArrayRef[Asset()];

coerce 'RepeatedAsset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::Asset'->new($_) } @$_ ] };

declare 'MapStringAsset',
    as HashRef[Asset()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::Asset::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::Asset::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::Asset::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AttributesEntry',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::Asset::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::Asset::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::Asset::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

declare 'PreferenceSet',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::PreferenceSet'];

coerce 'PreferenceSet',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::PreferenceSet'->new($_) };

declare 'RepeatedPreferenceSet',
    as ArrayRef[PreferenceSet()];

coerce 'RepeatedPreferenceSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::PreferenceSet'->new($_) } @$_ ] };

declare 'MapStringPreferenceSet',
    as HashRef[PreferenceSet()];

declare 'ImportJob',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ImportJob'];

coerce 'ImportJob',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ImportJob'->new($_) };

declare 'RepeatedImportJob',
    as ArrayRef[ImportJob()];

coerce 'RepeatedImportJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ImportJob'->new($_) } @$_ ] };

declare 'MapStringImportJob',
    as HashRef[ImportJob()];

declare 'ImportJobState',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ImportJob::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ImportJob::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ImportJob::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ImportDataFile',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ImportDataFile'];

coerce 'ImportDataFile',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ImportDataFile'->new($_) };

declare 'RepeatedImportDataFile',
    as ArrayRef[ImportDataFile()];

coerce 'RepeatedImportDataFile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ImportDataFile'->new($_) } @$_ ] };

declare 'MapStringImportDataFile',
    as HashRef[ImportDataFile()];

declare 'State',
    as (Int | Str);

declare 'Group',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::Group'];

coerce 'Group',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::Group'->new($_) };

declare 'RepeatedGroup',
    as ArrayRef[Group()];

coerce 'RepeatedGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::Group'->new($_) } @$_ ] };

declare 'MapStringGroup',
    as HashRef[Group()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::Group::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::Group::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::Group::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ErrorFrame',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ErrorFrame'];

coerce 'ErrorFrame',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ErrorFrame'->new($_) };

declare 'RepeatedErrorFrame',
    as ArrayRef[ErrorFrame()];

coerce 'RepeatedErrorFrame',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ErrorFrame'->new($_) } @$_ ] };

declare 'MapStringErrorFrame',
    as HashRef[ErrorFrame()];

declare 'Source',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::Source'];

coerce 'Source',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::Source'->new($_) };

declare 'RepeatedSource',
    as ArrayRef[Source()];

coerce 'RepeatedSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::Source'->new($_) } @$_ ] };

declare 'MapStringSource',
    as HashRef[Source()];

declare 'SourceType',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'ReportConfig',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportConfig'];

coerce 'ReportConfig',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportConfig'->new($_) };

declare 'RepeatedReportConfig',
    as ArrayRef[ReportConfig()];

coerce 'RepeatedReportConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportConfig'->new($_) } @$_ ] };

declare 'MapStringReportConfig',
    as HashRef[ReportConfig()];

declare 'GroupPreferenceSetAssignment',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportConfig::GroupPreferenceSetAssignment'];

coerce 'GroupPreferenceSetAssignment',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportConfig::GroupPreferenceSetAssignment'->new($_) };

declare 'RepeatedGroupPreferenceSetAssignment',
    as ArrayRef[GroupPreferenceSetAssignment()];

coerce 'RepeatedGroupPreferenceSetAssignment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportConfig::GroupPreferenceSetAssignment'->new($_) } @$_ ] };

declare 'MapStringGroupPreferenceSetAssignment',
    as HashRef[GroupPreferenceSetAssignment()];

declare 'Report',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::Report'];

coerce 'Report',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::Report'->new($_) };

declare 'RepeatedReport',
    as ArrayRef[Report()];

coerce 'RepeatedReport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::Report'->new($_) } @$_ ] };

declare 'MapStringReport',
    as HashRef[Report()];

declare 'Type',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'ListAssetsRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ListAssetsRequest'];

coerce 'ListAssetsRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListAssetsRequest'->new($_) };

declare 'RepeatedListAssetsRequest',
    as ArrayRef[ListAssetsRequest()];

coerce 'RepeatedListAssetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListAssetsRequest'->new($_) } @$_ ] };

declare 'MapStringListAssetsRequest',
    as HashRef[ListAssetsRequest()];

declare 'ListAssetsResponse',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ListAssetsResponse'];

coerce 'ListAssetsResponse',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListAssetsResponse'->new($_) };

declare 'RepeatedListAssetsResponse',
    as ArrayRef[ListAssetsResponse()];

coerce 'RepeatedListAssetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListAssetsResponse'->new($_) } @$_ ] };

declare 'MapStringListAssetsResponse',
    as HashRef[ListAssetsResponse()];

declare 'GetAssetRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::GetAssetRequest'];

coerce 'GetAssetRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GetAssetRequest'->new($_) };

declare 'RepeatedGetAssetRequest',
    as ArrayRef[GetAssetRequest()];

coerce 'RepeatedGetAssetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GetAssetRequest'->new($_) } @$_ ] };

declare 'MapStringGetAssetRequest',
    as HashRef[GetAssetRequest()];

declare 'UpdateAssetRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::UpdateAssetRequest'];

coerce 'UpdateAssetRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::UpdateAssetRequest'->new($_) };

declare 'RepeatedUpdateAssetRequest',
    as ArrayRef[UpdateAssetRequest()];

coerce 'RepeatedUpdateAssetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::UpdateAssetRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAssetRequest',
    as HashRef[UpdateAssetRequest()];

declare 'BatchUpdateAssetsRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::BatchUpdateAssetsRequest'];

coerce 'BatchUpdateAssetsRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::BatchUpdateAssetsRequest'->new($_) };

declare 'RepeatedBatchUpdateAssetsRequest',
    as ArrayRef[BatchUpdateAssetsRequest()];

coerce 'RepeatedBatchUpdateAssetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::BatchUpdateAssetsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchUpdateAssetsRequest',
    as HashRef[BatchUpdateAssetsRequest()];

declare 'BatchUpdateAssetsResponse',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::BatchUpdateAssetsResponse'];

coerce 'BatchUpdateAssetsResponse',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::BatchUpdateAssetsResponse'->new($_) };

declare 'RepeatedBatchUpdateAssetsResponse',
    as ArrayRef[BatchUpdateAssetsResponse()];

coerce 'RepeatedBatchUpdateAssetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::BatchUpdateAssetsResponse'->new($_) } @$_ ] };

declare 'MapStringBatchUpdateAssetsResponse',
    as HashRef[BatchUpdateAssetsResponse()];

declare 'DeleteAssetRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::DeleteAssetRequest'];

coerce 'DeleteAssetRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DeleteAssetRequest'->new($_) };

declare 'RepeatedDeleteAssetRequest',
    as ArrayRef[DeleteAssetRequest()];

coerce 'RepeatedDeleteAssetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DeleteAssetRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAssetRequest',
    as HashRef[DeleteAssetRequest()];

declare 'BatchDeleteAssetsRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::BatchDeleteAssetsRequest'];

coerce 'BatchDeleteAssetsRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::BatchDeleteAssetsRequest'->new($_) };

declare 'RepeatedBatchDeleteAssetsRequest',
    as ArrayRef[BatchDeleteAssetsRequest()];

coerce 'RepeatedBatchDeleteAssetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::BatchDeleteAssetsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchDeleteAssetsRequest',
    as HashRef[BatchDeleteAssetsRequest()];

declare 'ReportAssetFramesRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportAssetFramesRequest'];

coerce 'ReportAssetFramesRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportAssetFramesRequest'->new($_) };

declare 'RepeatedReportAssetFramesRequest',
    as ArrayRef[ReportAssetFramesRequest()];

coerce 'RepeatedReportAssetFramesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportAssetFramesRequest'->new($_) } @$_ ] };

declare 'MapStringReportAssetFramesRequest',
    as HashRef[ReportAssetFramesRequest()];

declare 'ReportAssetFramesResponse',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportAssetFramesResponse'];

coerce 'ReportAssetFramesResponse',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportAssetFramesResponse'->new($_) };

declare 'RepeatedReportAssetFramesResponse',
    as ArrayRef[ReportAssetFramesResponse()];

coerce 'RepeatedReportAssetFramesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportAssetFramesResponse'->new($_) } @$_ ] };

declare 'MapStringReportAssetFramesResponse',
    as HashRef[ReportAssetFramesResponse()];

declare 'AggregateAssetsValuesRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::AggregateAssetsValuesRequest'];

coerce 'AggregateAssetsValuesRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AggregateAssetsValuesRequest'->new($_) };

declare 'RepeatedAggregateAssetsValuesRequest',
    as ArrayRef[AggregateAssetsValuesRequest()];

coerce 'RepeatedAggregateAssetsValuesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AggregateAssetsValuesRequest'->new($_) } @$_ ] };

declare 'MapStringAggregateAssetsValuesRequest',
    as HashRef[AggregateAssetsValuesRequest()];

declare 'AggregateAssetsValuesResponse',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::AggregateAssetsValuesResponse'];

coerce 'AggregateAssetsValuesResponse',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AggregateAssetsValuesResponse'->new($_) };

declare 'RepeatedAggregateAssetsValuesResponse',
    as ArrayRef[AggregateAssetsValuesResponse()];

coerce 'RepeatedAggregateAssetsValuesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AggregateAssetsValuesResponse'->new($_) } @$_ ] };

declare 'MapStringAggregateAssetsValuesResponse',
    as HashRef[AggregateAssetsValuesResponse()];

declare 'CreateImportJobRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::CreateImportJobRequest'];

coerce 'CreateImportJobRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::CreateImportJobRequest'->new($_) };

declare 'RepeatedCreateImportJobRequest',
    as ArrayRef[CreateImportJobRequest()];

coerce 'RepeatedCreateImportJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::CreateImportJobRequest'->new($_) } @$_ ] };

declare 'MapStringCreateImportJobRequest',
    as HashRef[CreateImportJobRequest()];

declare 'ListImportJobsRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ListImportJobsRequest'];

coerce 'ListImportJobsRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListImportJobsRequest'->new($_) };

declare 'RepeatedListImportJobsRequest',
    as ArrayRef[ListImportJobsRequest()];

coerce 'RepeatedListImportJobsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListImportJobsRequest'->new($_) } @$_ ] };

declare 'MapStringListImportJobsRequest',
    as HashRef[ListImportJobsRequest()];

declare 'ListImportJobsResponse',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ListImportJobsResponse'];

coerce 'ListImportJobsResponse',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListImportJobsResponse'->new($_) };

declare 'RepeatedListImportJobsResponse',
    as ArrayRef[ListImportJobsResponse()];

coerce 'RepeatedListImportJobsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListImportJobsResponse'->new($_) } @$_ ] };

declare 'MapStringListImportJobsResponse',
    as HashRef[ListImportJobsResponse()];

declare 'GetImportJobRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::GetImportJobRequest'];

coerce 'GetImportJobRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GetImportJobRequest'->new($_) };

declare 'RepeatedGetImportJobRequest',
    as ArrayRef[GetImportJobRequest()];

coerce 'RepeatedGetImportJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GetImportJobRequest'->new($_) } @$_ ] };

declare 'MapStringGetImportJobRequest',
    as HashRef[GetImportJobRequest()];

declare 'DeleteImportJobRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::DeleteImportJobRequest'];

coerce 'DeleteImportJobRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DeleteImportJobRequest'->new($_) };

declare 'RepeatedDeleteImportJobRequest',
    as ArrayRef[DeleteImportJobRequest()];

coerce 'RepeatedDeleteImportJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DeleteImportJobRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteImportJobRequest',
    as HashRef[DeleteImportJobRequest()];

declare 'UpdateImportJobRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::UpdateImportJobRequest'];

coerce 'UpdateImportJobRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::UpdateImportJobRequest'->new($_) };

declare 'RepeatedUpdateImportJobRequest',
    as ArrayRef[UpdateImportJobRequest()];

coerce 'RepeatedUpdateImportJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::UpdateImportJobRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateImportJobRequest',
    as HashRef[UpdateImportJobRequest()];

declare 'ValidateImportJobRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ValidateImportJobRequest'];

coerce 'ValidateImportJobRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ValidateImportJobRequest'->new($_) };

declare 'RepeatedValidateImportJobRequest',
    as ArrayRef[ValidateImportJobRequest()];

coerce 'RepeatedValidateImportJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ValidateImportJobRequest'->new($_) } @$_ ] };

declare 'MapStringValidateImportJobRequest',
    as HashRef[ValidateImportJobRequest()];

declare 'RunImportJobRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::RunImportJobRequest'];

coerce 'RunImportJobRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::RunImportJobRequest'->new($_) };

declare 'RepeatedRunImportJobRequest',
    as ArrayRef[RunImportJobRequest()];

coerce 'RepeatedRunImportJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::RunImportJobRequest'->new($_) } @$_ ] };

declare 'MapStringRunImportJobRequest',
    as HashRef[RunImportJobRequest()];

declare 'GetImportDataFileRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::GetImportDataFileRequest'];

coerce 'GetImportDataFileRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GetImportDataFileRequest'->new($_) };

declare 'RepeatedGetImportDataFileRequest',
    as ArrayRef[GetImportDataFileRequest()];

coerce 'RepeatedGetImportDataFileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GetImportDataFileRequest'->new($_) } @$_ ] };

declare 'MapStringGetImportDataFileRequest',
    as HashRef[GetImportDataFileRequest()];

declare 'ListImportDataFilesRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ListImportDataFilesRequest'];

coerce 'ListImportDataFilesRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListImportDataFilesRequest'->new($_) };

declare 'RepeatedListImportDataFilesRequest',
    as ArrayRef[ListImportDataFilesRequest()];

coerce 'RepeatedListImportDataFilesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListImportDataFilesRequest'->new($_) } @$_ ] };

declare 'MapStringListImportDataFilesRequest',
    as HashRef[ListImportDataFilesRequest()];

declare 'ListImportDataFilesResponse',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ListImportDataFilesResponse'];

coerce 'ListImportDataFilesResponse',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListImportDataFilesResponse'->new($_) };

declare 'RepeatedListImportDataFilesResponse',
    as ArrayRef[ListImportDataFilesResponse()];

coerce 'RepeatedListImportDataFilesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListImportDataFilesResponse'->new($_) } @$_ ] };

declare 'MapStringListImportDataFilesResponse',
    as HashRef[ListImportDataFilesResponse()];

declare 'CreateImportDataFileRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::CreateImportDataFileRequest'];

coerce 'CreateImportDataFileRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::CreateImportDataFileRequest'->new($_) };

declare 'RepeatedCreateImportDataFileRequest',
    as ArrayRef[CreateImportDataFileRequest()];

coerce 'RepeatedCreateImportDataFileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::CreateImportDataFileRequest'->new($_) } @$_ ] };

declare 'MapStringCreateImportDataFileRequest',
    as HashRef[CreateImportDataFileRequest()];

declare 'DeleteImportDataFileRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::DeleteImportDataFileRequest'];

coerce 'DeleteImportDataFileRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DeleteImportDataFileRequest'->new($_) };

declare 'RepeatedDeleteImportDataFileRequest',
    as ArrayRef[DeleteImportDataFileRequest()];

coerce 'RepeatedDeleteImportDataFileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DeleteImportDataFileRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteImportDataFileRequest',
    as HashRef[DeleteImportDataFileRequest()];

declare 'ListGroupsRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ListGroupsRequest'];

coerce 'ListGroupsRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListGroupsRequest'->new($_) };

declare 'RepeatedListGroupsRequest',
    as ArrayRef[ListGroupsRequest()];

coerce 'RepeatedListGroupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListGroupsRequest'->new($_) } @$_ ] };

declare 'MapStringListGroupsRequest',
    as HashRef[ListGroupsRequest()];

declare 'ListGroupsResponse',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ListGroupsResponse'];

coerce 'ListGroupsResponse',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListGroupsResponse'->new($_) };

declare 'RepeatedListGroupsResponse',
    as ArrayRef[ListGroupsResponse()];

coerce 'RepeatedListGroupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListGroupsResponse'->new($_) } @$_ ] };

declare 'MapStringListGroupsResponse',
    as HashRef[ListGroupsResponse()];

declare 'GetGroupRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::GetGroupRequest'];

coerce 'GetGroupRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GetGroupRequest'->new($_) };

declare 'RepeatedGetGroupRequest',
    as ArrayRef[GetGroupRequest()];

coerce 'RepeatedGetGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GetGroupRequest'->new($_) } @$_ ] };

declare 'MapStringGetGroupRequest',
    as HashRef[GetGroupRequest()];

declare 'CreateGroupRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::CreateGroupRequest'];

coerce 'CreateGroupRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::CreateGroupRequest'->new($_) };

declare 'RepeatedCreateGroupRequest',
    as ArrayRef[CreateGroupRequest()];

coerce 'RepeatedCreateGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::CreateGroupRequest'->new($_) } @$_ ] };

declare 'MapStringCreateGroupRequest',
    as HashRef[CreateGroupRequest()];

declare 'UpdateGroupRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::UpdateGroupRequest'];

coerce 'UpdateGroupRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::UpdateGroupRequest'->new($_) };

declare 'RepeatedUpdateGroupRequest',
    as ArrayRef[UpdateGroupRequest()];

coerce 'RepeatedUpdateGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::UpdateGroupRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateGroupRequest',
    as HashRef[UpdateGroupRequest()];

declare 'DeleteGroupRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::DeleteGroupRequest'];

coerce 'DeleteGroupRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DeleteGroupRequest'->new($_) };

declare 'RepeatedDeleteGroupRequest',
    as ArrayRef[DeleteGroupRequest()];

coerce 'RepeatedDeleteGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DeleteGroupRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteGroupRequest',
    as HashRef[DeleteGroupRequest()];

declare 'AddAssetsToGroupRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::AddAssetsToGroupRequest'];

coerce 'AddAssetsToGroupRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AddAssetsToGroupRequest'->new($_) };

declare 'RepeatedAddAssetsToGroupRequest',
    as ArrayRef[AddAssetsToGroupRequest()];

coerce 'RepeatedAddAssetsToGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AddAssetsToGroupRequest'->new($_) } @$_ ] };

declare 'MapStringAddAssetsToGroupRequest',
    as HashRef[AddAssetsToGroupRequest()];

declare 'RemoveAssetsFromGroupRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::RemoveAssetsFromGroupRequest'];

coerce 'RemoveAssetsFromGroupRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::RemoveAssetsFromGroupRequest'->new($_) };

declare 'RepeatedRemoveAssetsFromGroupRequest',
    as ArrayRef[RemoveAssetsFromGroupRequest()];

coerce 'RepeatedRemoveAssetsFromGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::RemoveAssetsFromGroupRequest'->new($_) } @$_ ] };

declare 'MapStringRemoveAssetsFromGroupRequest',
    as HashRef[RemoveAssetsFromGroupRequest()];

declare 'ListErrorFramesRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ListErrorFramesRequest'];

coerce 'ListErrorFramesRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListErrorFramesRequest'->new($_) };

declare 'RepeatedListErrorFramesRequest',
    as ArrayRef[ListErrorFramesRequest()];

coerce 'RepeatedListErrorFramesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListErrorFramesRequest'->new($_) } @$_ ] };

declare 'MapStringListErrorFramesRequest',
    as HashRef[ListErrorFramesRequest()];

declare 'ListErrorFramesResponse',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ListErrorFramesResponse'];

coerce 'ListErrorFramesResponse',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListErrorFramesResponse'->new($_) };

declare 'RepeatedListErrorFramesResponse',
    as ArrayRef[ListErrorFramesResponse()];

coerce 'RepeatedListErrorFramesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListErrorFramesResponse'->new($_) } @$_ ] };

declare 'MapStringListErrorFramesResponse',
    as HashRef[ListErrorFramesResponse()];

declare 'GetErrorFrameRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::GetErrorFrameRequest'];

coerce 'GetErrorFrameRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GetErrorFrameRequest'->new($_) };

declare 'RepeatedGetErrorFrameRequest',
    as ArrayRef[GetErrorFrameRequest()];

coerce 'RepeatedGetErrorFrameRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GetErrorFrameRequest'->new($_) } @$_ ] };

declare 'MapStringGetErrorFrameRequest',
    as HashRef[GetErrorFrameRequest()];

declare 'ListSourcesRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ListSourcesRequest'];

coerce 'ListSourcesRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListSourcesRequest'->new($_) };

declare 'RepeatedListSourcesRequest',
    as ArrayRef[ListSourcesRequest()];

coerce 'RepeatedListSourcesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListSourcesRequest'->new($_) } @$_ ] };

declare 'MapStringListSourcesRequest',
    as HashRef[ListSourcesRequest()];

declare 'ListSourcesResponse',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ListSourcesResponse'];

coerce 'ListSourcesResponse',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListSourcesResponse'->new($_) };

declare 'RepeatedListSourcesResponse',
    as ArrayRef[ListSourcesResponse()];

coerce 'RepeatedListSourcesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListSourcesResponse'->new($_) } @$_ ] };

declare 'MapStringListSourcesResponse',
    as HashRef[ListSourcesResponse()];

declare 'GetSourceRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::GetSourceRequest'];

coerce 'GetSourceRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GetSourceRequest'->new($_) };

declare 'RepeatedGetSourceRequest',
    as ArrayRef[GetSourceRequest()];

coerce 'RepeatedGetSourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GetSourceRequest'->new($_) } @$_ ] };

declare 'MapStringGetSourceRequest',
    as HashRef[GetSourceRequest()];

declare 'CreateSourceRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::CreateSourceRequest'];

coerce 'CreateSourceRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::CreateSourceRequest'->new($_) };

declare 'RepeatedCreateSourceRequest',
    as ArrayRef[CreateSourceRequest()];

coerce 'RepeatedCreateSourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::CreateSourceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSourceRequest',
    as HashRef[CreateSourceRequest()];

declare 'UpdateSourceRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::UpdateSourceRequest'];

coerce 'UpdateSourceRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::UpdateSourceRequest'->new($_) };

declare 'RepeatedUpdateSourceRequest',
    as ArrayRef[UpdateSourceRequest()];

coerce 'RepeatedUpdateSourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::UpdateSourceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSourceRequest',
    as HashRef[UpdateSourceRequest()];

declare 'DeleteSourceRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::DeleteSourceRequest'];

coerce 'DeleteSourceRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DeleteSourceRequest'->new($_) };

declare 'RepeatedDeleteSourceRequest',
    as ArrayRef[DeleteSourceRequest()];

coerce 'RepeatedDeleteSourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DeleteSourceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSourceRequest',
    as HashRef[DeleteSourceRequest()];

declare 'ListPreferenceSetsRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ListPreferenceSetsRequest'];

coerce 'ListPreferenceSetsRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListPreferenceSetsRequest'->new($_) };

declare 'RepeatedListPreferenceSetsRequest',
    as ArrayRef[ListPreferenceSetsRequest()];

coerce 'RepeatedListPreferenceSetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListPreferenceSetsRequest'->new($_) } @$_ ] };

declare 'MapStringListPreferenceSetsRequest',
    as HashRef[ListPreferenceSetsRequest()];

declare 'ListPreferenceSetsResponse',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ListPreferenceSetsResponse'];

coerce 'ListPreferenceSetsResponse',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListPreferenceSetsResponse'->new($_) };

declare 'RepeatedListPreferenceSetsResponse',
    as ArrayRef[ListPreferenceSetsResponse()];

coerce 'RepeatedListPreferenceSetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListPreferenceSetsResponse'->new($_) } @$_ ] };

declare 'MapStringListPreferenceSetsResponse',
    as HashRef[ListPreferenceSetsResponse()];

declare 'GetPreferenceSetRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::GetPreferenceSetRequest'];

coerce 'GetPreferenceSetRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GetPreferenceSetRequest'->new($_) };

declare 'RepeatedGetPreferenceSetRequest',
    as ArrayRef[GetPreferenceSetRequest()];

coerce 'RepeatedGetPreferenceSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GetPreferenceSetRequest'->new($_) } @$_ ] };

declare 'MapStringGetPreferenceSetRequest',
    as HashRef[GetPreferenceSetRequest()];

declare 'CreatePreferenceSetRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::CreatePreferenceSetRequest'];

coerce 'CreatePreferenceSetRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::CreatePreferenceSetRequest'->new($_) };

declare 'RepeatedCreatePreferenceSetRequest',
    as ArrayRef[CreatePreferenceSetRequest()];

coerce 'RepeatedCreatePreferenceSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::CreatePreferenceSetRequest'->new($_) } @$_ ] };

declare 'MapStringCreatePreferenceSetRequest',
    as HashRef[CreatePreferenceSetRequest()];

declare 'UpdatePreferenceSetRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::UpdatePreferenceSetRequest'];

coerce 'UpdatePreferenceSetRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::UpdatePreferenceSetRequest'->new($_) };

declare 'RepeatedUpdatePreferenceSetRequest',
    as ArrayRef[UpdatePreferenceSetRequest()];

coerce 'RepeatedUpdatePreferenceSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::UpdatePreferenceSetRequest'->new($_) } @$_ ] };

declare 'MapStringUpdatePreferenceSetRequest',
    as HashRef[UpdatePreferenceSetRequest()];

declare 'DeletePreferenceSetRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::DeletePreferenceSetRequest'];

coerce 'DeletePreferenceSetRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DeletePreferenceSetRequest'->new($_) };

declare 'RepeatedDeletePreferenceSetRequest',
    as ArrayRef[DeletePreferenceSetRequest()];

coerce 'RepeatedDeletePreferenceSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DeletePreferenceSetRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePreferenceSetRequest',
    as HashRef[DeletePreferenceSetRequest()];

declare 'GetSettingsRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::GetSettingsRequest'];

coerce 'GetSettingsRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GetSettingsRequest'->new($_) };

declare 'RepeatedGetSettingsRequest',
    as ArrayRef[GetSettingsRequest()];

coerce 'RepeatedGetSettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GetSettingsRequest'->new($_) } @$_ ] };

declare 'MapStringGetSettingsRequest',
    as HashRef[GetSettingsRequest()];

declare 'UpdateSettingsRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::UpdateSettingsRequest'];

coerce 'UpdateSettingsRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::UpdateSettingsRequest'->new($_) };

declare 'RepeatedUpdateSettingsRequest',
    as ArrayRef[UpdateSettingsRequest()];

coerce 'RepeatedUpdateSettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::UpdateSettingsRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSettingsRequest',
    as HashRef[UpdateSettingsRequest()];

declare 'CreateReportConfigRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::CreateReportConfigRequest'];

coerce 'CreateReportConfigRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::CreateReportConfigRequest'->new($_) };

declare 'RepeatedCreateReportConfigRequest',
    as ArrayRef[CreateReportConfigRequest()];

coerce 'RepeatedCreateReportConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::CreateReportConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateReportConfigRequest',
    as HashRef[CreateReportConfigRequest()];

declare 'DeleteReportConfigRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::DeleteReportConfigRequest'];

coerce 'DeleteReportConfigRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DeleteReportConfigRequest'->new($_) };

declare 'RepeatedDeleteReportConfigRequest',
    as ArrayRef[DeleteReportConfigRequest()];

coerce 'RepeatedDeleteReportConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DeleteReportConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteReportConfigRequest',
    as HashRef[DeleteReportConfigRequest()];

declare 'GetReportRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::GetReportRequest'];

coerce 'GetReportRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GetReportRequest'->new($_) };

declare 'RepeatedGetReportRequest',
    as ArrayRef[GetReportRequest()];

coerce 'RepeatedGetReportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GetReportRequest'->new($_) } @$_ ] };

declare 'MapStringGetReportRequest',
    as HashRef[GetReportRequest()];

declare 'ListReportsRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ListReportsRequest'];

coerce 'ListReportsRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListReportsRequest'->new($_) };

declare 'RepeatedListReportsRequest',
    as ArrayRef[ListReportsRequest()];

coerce 'RepeatedListReportsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListReportsRequest'->new($_) } @$_ ] };

declare 'MapStringListReportsRequest',
    as HashRef[ListReportsRequest()];

declare 'ListReportsResponse',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ListReportsResponse'];

coerce 'ListReportsResponse',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListReportsResponse'->new($_) };

declare 'RepeatedListReportsResponse',
    as ArrayRef[ListReportsResponse()];

coerce 'RepeatedListReportsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListReportsResponse'->new($_) } @$_ ] };

declare 'MapStringListReportsResponse',
    as HashRef[ListReportsResponse()];

declare 'DeleteReportRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::DeleteReportRequest'];

coerce 'DeleteReportRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DeleteReportRequest'->new($_) };

declare 'RepeatedDeleteReportRequest',
    as ArrayRef[DeleteReportRequest()];

coerce 'RepeatedDeleteReportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DeleteReportRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteReportRequest',
    as HashRef[DeleteReportRequest()];

declare 'GetReportConfigRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::GetReportConfigRequest'];

coerce 'GetReportConfigRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GetReportConfigRequest'->new($_) };

declare 'RepeatedGetReportConfigRequest',
    as ArrayRef[GetReportConfigRequest()];

coerce 'RepeatedGetReportConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GetReportConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetReportConfigRequest',
    as HashRef[GetReportConfigRequest()];

declare 'ListReportConfigsRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ListReportConfigsRequest'];

coerce 'ListReportConfigsRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListReportConfigsRequest'->new($_) };

declare 'RepeatedListReportConfigsRequest',
    as ArrayRef[ListReportConfigsRequest()];

coerce 'RepeatedListReportConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListReportConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListReportConfigsRequest',
    as HashRef[ListReportConfigsRequest()];

declare 'ListReportConfigsResponse',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ListReportConfigsResponse'];

coerce 'ListReportConfigsResponse',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListReportConfigsResponse'->new($_) };

declare 'RepeatedListReportConfigsResponse',
    as ArrayRef[ListReportConfigsResponse()];

coerce 'RepeatedListReportConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ListReportConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListReportConfigsResponse',
    as HashRef[ListReportConfigsResponse()];

declare 'CreateReportRequest',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::CreateReportRequest'];

coerce 'CreateReportRequest',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::CreateReportRequest'->new($_) };

declare 'RepeatedCreateReportRequest',
    as ArrayRef[CreateReportRequest()];

coerce 'RepeatedCreateReportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::CreateReportRequest'->new($_) } @$_ ] };

declare 'MapStringCreateReportRequest',
    as HashRef[CreateReportRequest()];

declare 'Frames',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::Frames'];

coerce 'Frames',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::Frames'->new($_) };

declare 'RepeatedFrames',
    as ArrayRef[Frames()];

coerce 'RepeatedFrames',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::Frames'->new($_) } @$_ ] };

declare 'MapStringFrames',
    as HashRef[Frames()];

declare 'AssetFrame',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::AssetFrame'];

coerce 'AssetFrame',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AssetFrame'->new($_) };

declare 'RepeatedAssetFrame',
    as ArrayRef[AssetFrame()];

coerce 'RepeatedAssetFrame',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AssetFrame'->new($_) } @$_ ] };

declare 'MapStringAssetFrame',
    as HashRef[AssetFrame()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::AssetFrame::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AssetFrame::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AssetFrame::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AttributesEntry',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::AssetFrame::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AssetFrame::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AssetFrame::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

declare 'MachineDetails',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::MachineDetails'];

coerce 'MachineDetails',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::MachineDetails'->new($_) };

declare 'RepeatedMachineDetails',
    as ArrayRef[MachineDetails()];

coerce 'RepeatedMachineDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::MachineDetails'->new($_) } @$_ ] };

declare 'MapStringMachineDetails',
    as HashRef[MachineDetails()];

declare 'PowerState',
    as (Int | Str);

declare 'MachineArchitectureDetails',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::MachineArchitectureDetails'];

coerce 'MachineArchitectureDetails',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::MachineArchitectureDetails'->new($_) };

declare 'RepeatedMachineArchitectureDetails',
    as ArrayRef[MachineArchitectureDetails()];

coerce 'RepeatedMachineArchitectureDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::MachineArchitectureDetails'->new($_) } @$_ ] };

declare 'MapStringMachineArchitectureDetails',
    as HashRef[MachineArchitectureDetails()];

declare 'FirmwareType',
    as (Int | Str);

declare 'CpuHyperThreading',
    as (Int | Str);

declare 'BiosDetails',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::BiosDetails'];

coerce 'BiosDetails',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::BiosDetails'->new($_) };

declare 'RepeatedBiosDetails',
    as ArrayRef[BiosDetails()];

coerce 'RepeatedBiosDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::BiosDetails'->new($_) } @$_ ] };

declare 'MapStringBiosDetails',
    as HashRef[BiosDetails()];

declare 'MachineNetworkDetails',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::MachineNetworkDetails'];

coerce 'MachineNetworkDetails',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::MachineNetworkDetails'->new($_) };

declare 'RepeatedMachineNetworkDetails',
    as ArrayRef[MachineNetworkDetails()];

coerce 'RepeatedMachineNetworkDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::MachineNetworkDetails'->new($_) } @$_ ] };

declare 'MapStringMachineNetworkDetails',
    as HashRef[MachineNetworkDetails()];

declare 'NetworkAdapterList',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::NetworkAdapterList'];

coerce 'NetworkAdapterList',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::NetworkAdapterList'->new($_) };

declare 'RepeatedNetworkAdapterList',
    as ArrayRef[NetworkAdapterList()];

coerce 'RepeatedNetworkAdapterList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::NetworkAdapterList'->new($_) } @$_ ] };

declare 'MapStringNetworkAdapterList',
    as HashRef[NetworkAdapterList()];

declare 'NetworkAdapterDetails',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::NetworkAdapterDetails'];

coerce 'NetworkAdapterDetails',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::NetworkAdapterDetails'->new($_) };

declare 'RepeatedNetworkAdapterDetails',
    as ArrayRef[NetworkAdapterDetails()];

coerce 'RepeatedNetworkAdapterDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::NetworkAdapterDetails'->new($_) } @$_ ] };

declare 'MapStringNetworkAdapterDetails',
    as HashRef[NetworkAdapterDetails()];

declare 'NetworkAddressList',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::NetworkAddressList'];

coerce 'NetworkAddressList',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::NetworkAddressList'->new($_) };

declare 'RepeatedNetworkAddressList',
    as ArrayRef[NetworkAddressList()];

coerce 'RepeatedNetworkAddressList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::NetworkAddressList'->new($_) } @$_ ] };

declare 'MapStringNetworkAddressList',
    as HashRef[NetworkAddressList()];

declare 'NetworkAddress',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::NetworkAddress'];

coerce 'NetworkAddress',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::NetworkAddress'->new($_) };

declare 'RepeatedNetworkAddress',
    as ArrayRef[NetworkAddress()];

coerce 'RepeatedNetworkAddress',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::NetworkAddress'->new($_) } @$_ ] };

declare 'MapStringNetworkAddress',
    as HashRef[NetworkAddress()];

declare 'AddressAssignment',
    as (Int | Str);

declare 'MachineDiskDetails',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::MachineDiskDetails'];

coerce 'MachineDiskDetails',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::MachineDiskDetails'->new($_) };

declare 'RepeatedMachineDiskDetails',
    as ArrayRef[MachineDiskDetails()];

coerce 'RepeatedMachineDiskDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::MachineDiskDetails'->new($_) } @$_ ] };

declare 'MapStringMachineDiskDetails',
    as HashRef[MachineDiskDetails()];

declare 'DiskEntryList',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::DiskEntryList'];

coerce 'DiskEntryList',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DiskEntryList'->new($_) };

declare 'RepeatedDiskEntryList',
    as ArrayRef[DiskEntryList()];

coerce 'RepeatedDiskEntryList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DiskEntryList'->new($_) } @$_ ] };

declare 'MapStringDiskEntryList',
    as HashRef[DiskEntryList()];

declare 'DiskEntry',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::DiskEntry'];

coerce 'DiskEntry',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DiskEntry'->new($_) };

declare 'RepeatedDiskEntry',
    as ArrayRef[DiskEntry()];

coerce 'RepeatedDiskEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DiskEntry'->new($_) } @$_ ] };

declare 'MapStringDiskEntry',
    as HashRef[DiskEntry()];

declare 'InterfaceType',
    as (Int | Str);

declare 'DiskPartitionList',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::DiskPartitionList'];

coerce 'DiskPartitionList',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DiskPartitionList'->new($_) };

declare 'RepeatedDiskPartitionList',
    as ArrayRef[DiskPartitionList()];

coerce 'RepeatedDiskPartitionList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DiskPartitionList'->new($_) } @$_ ] };

declare 'MapStringDiskPartitionList',
    as HashRef[DiskPartitionList()];

declare 'DiskPartition',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::DiskPartition'];

coerce 'DiskPartition',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DiskPartition'->new($_) };

declare 'RepeatedDiskPartition',
    as ArrayRef[DiskPartition()];

coerce 'RepeatedDiskPartition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DiskPartition'->new($_) } @$_ ] };

declare 'MapStringDiskPartition',
    as HashRef[DiskPartition()];

declare 'VmwareDiskConfig',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::VmwareDiskConfig'];

coerce 'VmwareDiskConfig',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::VmwareDiskConfig'->new($_) };

declare 'RepeatedVmwareDiskConfig',
    as ArrayRef[VmwareDiskConfig()];

coerce 'RepeatedVmwareDiskConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::VmwareDiskConfig'->new($_) } @$_ ] };

declare 'MapStringVmwareDiskConfig',
    as HashRef[VmwareDiskConfig()];

declare 'BackingType',
    as (Int | Str);

declare 'VmdkMode',
    as (Int | Str);

declare 'RdmCompatibility',
    as (Int | Str);

declare 'GuestOsDetails',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::GuestOsDetails'];

coerce 'GuestOsDetails',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GuestOsDetails'->new($_) };

declare 'RepeatedGuestOsDetails',
    as ArrayRef[GuestOsDetails()];

coerce 'RepeatedGuestOsDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GuestOsDetails'->new($_) } @$_ ] };

declare 'MapStringGuestOsDetails',
    as HashRef[GuestOsDetails()];

declare 'GuestConfigDetails',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::GuestConfigDetails'];

coerce 'GuestConfigDetails',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GuestConfigDetails'->new($_) };

declare 'RepeatedGuestConfigDetails',
    as ArrayRef[GuestConfigDetails()];

coerce 'RepeatedGuestConfigDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GuestConfigDetails'->new($_) } @$_ ] };

declare 'MapStringGuestConfigDetails',
    as HashRef[GuestConfigDetails()];

declare 'SeLinuxMode',
    as (Int | Str);

declare 'FstabEntryList',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::FstabEntryList'];

coerce 'FstabEntryList',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::FstabEntryList'->new($_) };

declare 'RepeatedFstabEntryList',
    as ArrayRef[FstabEntryList()];

coerce 'RepeatedFstabEntryList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::FstabEntryList'->new($_) } @$_ ] };

declare 'MapStringFstabEntryList',
    as HashRef[FstabEntryList()];

declare 'FstabEntry',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::FstabEntry'];

coerce 'FstabEntry',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::FstabEntry'->new($_) };

declare 'RepeatedFstabEntry',
    as ArrayRef[FstabEntry()];

coerce 'RepeatedFstabEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::FstabEntry'->new($_) } @$_ ] };

declare 'MapStringFstabEntry',
    as HashRef[FstabEntry()];

declare 'HostsEntryList',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::HostsEntryList'];

coerce 'HostsEntryList',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::HostsEntryList'->new($_) };

declare 'RepeatedHostsEntryList',
    as ArrayRef[HostsEntryList()];

coerce 'RepeatedHostsEntryList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::HostsEntryList'->new($_) } @$_ ] };

declare 'MapStringHostsEntryList',
    as HashRef[HostsEntryList()];

declare 'HostsEntry',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::HostsEntry'];

coerce 'HostsEntry',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::HostsEntry'->new($_) };

declare 'RepeatedHostsEntry',
    as ArrayRef[HostsEntry()];

coerce 'RepeatedHostsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::HostsEntry'->new($_) } @$_ ] };

declare 'MapStringHostsEntry',
    as HashRef[HostsEntry()];

declare 'NfsExportList',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::NfsExportList'];

coerce 'NfsExportList',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::NfsExportList'->new($_) };

declare 'RepeatedNfsExportList',
    as ArrayRef[NfsExportList()];

coerce 'RepeatedNfsExportList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::NfsExportList'->new($_) } @$_ ] };

declare 'MapStringNfsExportList',
    as HashRef[NfsExportList()];

declare 'NfsExport',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::NfsExport'];

coerce 'NfsExport',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::NfsExport'->new($_) };

declare 'RepeatedNfsExport',
    as ArrayRef[NfsExport()];

coerce 'RepeatedNfsExport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::NfsExport'->new($_) } @$_ ] };

declare 'MapStringNfsExport',
    as HashRef[NfsExport()];

declare 'GuestRuntimeDetails',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::GuestRuntimeDetails'];

coerce 'GuestRuntimeDetails',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GuestRuntimeDetails'->new($_) };

declare 'RepeatedGuestRuntimeDetails',
    as ArrayRef[GuestRuntimeDetails()];

coerce 'RepeatedGuestRuntimeDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GuestRuntimeDetails'->new($_) } @$_ ] };

declare 'MapStringGuestRuntimeDetails',
    as HashRef[GuestRuntimeDetails()];

declare 'RunningServiceList',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::RunningServiceList'];

coerce 'RunningServiceList',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::RunningServiceList'->new($_) };

declare 'RepeatedRunningServiceList',
    as ArrayRef[RunningServiceList()];

coerce 'RepeatedRunningServiceList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::RunningServiceList'->new($_) } @$_ ] };

declare 'MapStringRunningServiceList',
    as HashRef[RunningServiceList()];

declare 'RunningService',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::RunningService'];

coerce 'RunningService',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::RunningService'->new($_) };

declare 'RepeatedRunningService',
    as ArrayRef[RunningService()];

coerce 'RepeatedRunningService',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::RunningService'->new($_) } @$_ ] };

declare 'MapStringRunningService',
    as HashRef[RunningService()];

declare 'State',
    as (Int | Str);

declare 'StartMode',
    as (Int | Str);

declare 'RunningProcessList',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::RunningProcessList'];

coerce 'RunningProcessList',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::RunningProcessList'->new($_) };

declare 'RepeatedRunningProcessList',
    as ArrayRef[RunningProcessList()];

coerce 'RepeatedRunningProcessList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::RunningProcessList'->new($_) } @$_ ] };

declare 'MapStringRunningProcessList',
    as HashRef[RunningProcessList()];

declare 'RunningProcess',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::RunningProcess'];

coerce 'RunningProcess',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::RunningProcess'->new($_) };

declare 'RepeatedRunningProcess',
    as ArrayRef[RunningProcess()];

coerce 'RepeatedRunningProcess',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::RunningProcess'->new($_) } @$_ ] };

declare 'MapStringRunningProcess',
    as HashRef[RunningProcess()];

declare 'AttributesEntry',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::RunningProcess::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::RunningProcess::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::RunningProcess::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

declare 'RuntimeNetworkInfo',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::RuntimeNetworkInfo'];

coerce 'RuntimeNetworkInfo',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::RuntimeNetworkInfo'->new($_) };

declare 'RepeatedRuntimeNetworkInfo',
    as ArrayRef[RuntimeNetworkInfo()];

coerce 'RepeatedRuntimeNetworkInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::RuntimeNetworkInfo'->new($_) } @$_ ] };

declare 'MapStringRuntimeNetworkInfo',
    as HashRef[RuntimeNetworkInfo()];

declare 'NetworkConnectionList',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::NetworkConnectionList'];

coerce 'NetworkConnectionList',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::NetworkConnectionList'->new($_) };

declare 'RepeatedNetworkConnectionList',
    as ArrayRef[NetworkConnectionList()];

coerce 'RepeatedNetworkConnectionList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::NetworkConnectionList'->new($_) } @$_ ] };

declare 'MapStringNetworkConnectionList',
    as HashRef[NetworkConnectionList()];

declare 'NetworkConnection',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::NetworkConnection'];

coerce 'NetworkConnection',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::NetworkConnection'->new($_) };

declare 'RepeatedNetworkConnection',
    as ArrayRef[NetworkConnection()];

coerce 'RepeatedNetworkConnection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::NetworkConnection'->new($_) } @$_ ] };

declare 'MapStringNetworkConnection',
    as HashRef[NetworkConnection()];

declare 'State',
    as (Int | Str);

declare 'GuestInstalledApplicationList',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::GuestInstalledApplicationList'];

coerce 'GuestInstalledApplicationList',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GuestInstalledApplicationList'->new($_) };

declare 'RepeatedGuestInstalledApplicationList',
    as ArrayRef[GuestInstalledApplicationList()];

coerce 'RepeatedGuestInstalledApplicationList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GuestInstalledApplicationList'->new($_) } @$_ ] };

declare 'MapStringGuestInstalledApplicationList',
    as HashRef[GuestInstalledApplicationList()];

declare 'GuestInstalledApplication',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::GuestInstalledApplication'];

coerce 'GuestInstalledApplication',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GuestInstalledApplication'->new($_) };

declare 'RepeatedGuestInstalledApplication',
    as ArrayRef[GuestInstalledApplication()];

coerce 'RepeatedGuestInstalledApplication',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GuestInstalledApplication'->new($_) } @$_ ] };

declare 'MapStringGuestInstalledApplication',
    as HashRef[GuestInstalledApplication()];

declare 'OpenFileList',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::OpenFileList'];

coerce 'OpenFileList',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::OpenFileList'->new($_) };

declare 'RepeatedOpenFileList',
    as ArrayRef[OpenFileList()];

coerce 'RepeatedOpenFileList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::OpenFileList'->new($_) } @$_ ] };

declare 'MapStringOpenFileList',
    as HashRef[OpenFileList()];

declare 'OpenFileDetails',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::OpenFileDetails'];

coerce 'OpenFileDetails',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::OpenFileDetails'->new($_) };

declare 'RepeatedOpenFileDetails',
    as ArrayRef[OpenFileDetails()];

coerce 'RepeatedOpenFileDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::OpenFileDetails'->new($_) } @$_ ] };

declare 'MapStringOpenFileDetails',
    as HashRef[OpenFileDetails()];

declare 'PlatformDetails',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::PlatformDetails'];

coerce 'PlatformDetails',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::PlatformDetails'->new($_) };

declare 'RepeatedPlatformDetails',
    as ArrayRef[PlatformDetails()];

coerce 'RepeatedPlatformDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::PlatformDetails'->new($_) } @$_ ] };

declare 'MapStringPlatformDetails',
    as HashRef[PlatformDetails()];

declare 'VmwarePlatformDetails',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::VmwarePlatformDetails'];

coerce 'VmwarePlatformDetails',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::VmwarePlatformDetails'->new($_) };

declare 'RepeatedVmwarePlatformDetails',
    as ArrayRef[VmwarePlatformDetails()];

coerce 'RepeatedVmwarePlatformDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::VmwarePlatformDetails'->new($_) } @$_ ] };

declare 'MapStringVmwarePlatformDetails',
    as HashRef[VmwarePlatformDetails()];

declare 'AwsEc2PlatformDetails',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::AwsEc2PlatformDetails'];

coerce 'AwsEc2PlatformDetails',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AwsEc2PlatformDetails'->new($_) };

declare 'RepeatedAwsEc2PlatformDetails',
    as ArrayRef[AwsEc2PlatformDetails()];

coerce 'RepeatedAwsEc2PlatformDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AwsEc2PlatformDetails'->new($_) } @$_ ] };

declare 'MapStringAwsEc2PlatformDetails',
    as HashRef[AwsEc2PlatformDetails()];

declare 'AzureVmPlatformDetails',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::AzureVmPlatformDetails'];

coerce 'AzureVmPlatformDetails',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AzureVmPlatformDetails'->new($_) };

declare 'RepeatedAzureVmPlatformDetails',
    as ArrayRef[AzureVmPlatformDetails()];

coerce 'RepeatedAzureVmPlatformDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AzureVmPlatformDetails'->new($_) } @$_ ] };

declare 'MapStringAzureVmPlatformDetails',
    as HashRef[AzureVmPlatformDetails()];

declare 'GenericPlatformDetails',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::GenericPlatformDetails'];

coerce 'GenericPlatformDetails',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GenericPlatformDetails'->new($_) };

declare 'RepeatedGenericPlatformDetails',
    as ArrayRef[GenericPlatformDetails()];

coerce 'RepeatedGenericPlatformDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GenericPlatformDetails'->new($_) } @$_ ] };

declare 'MapStringGenericPlatformDetails',
    as HashRef[GenericPlatformDetails()];

declare 'PhysicalPlatformDetails',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::PhysicalPlatformDetails'];

coerce 'PhysicalPlatformDetails',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::PhysicalPlatformDetails'->new($_) };

declare 'RepeatedPhysicalPlatformDetails',
    as ArrayRef[PhysicalPlatformDetails()];

coerce 'RepeatedPhysicalPlatformDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::PhysicalPlatformDetails'->new($_) } @$_ ] };

declare 'MapStringPhysicalPlatformDetails',
    as HashRef[PhysicalPlatformDetails()];

declare 'MemoryUsageSample',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::MemoryUsageSample'];

coerce 'MemoryUsageSample',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::MemoryUsageSample'->new($_) };

declare 'RepeatedMemoryUsageSample',
    as ArrayRef[MemoryUsageSample()];

coerce 'RepeatedMemoryUsageSample',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::MemoryUsageSample'->new($_) } @$_ ] };

declare 'MapStringMemoryUsageSample',
    as HashRef[MemoryUsageSample()];

declare 'CpuUsageSample',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::CpuUsageSample'];

coerce 'CpuUsageSample',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::CpuUsageSample'->new($_) };

declare 'RepeatedCpuUsageSample',
    as ArrayRef[CpuUsageSample()];

coerce 'RepeatedCpuUsageSample',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::CpuUsageSample'->new($_) } @$_ ] };

declare 'MapStringCpuUsageSample',
    as HashRef[CpuUsageSample()];

declare 'NetworkUsageSample',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::NetworkUsageSample'];

coerce 'NetworkUsageSample',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::NetworkUsageSample'->new($_) };

declare 'RepeatedNetworkUsageSample',
    as ArrayRef[NetworkUsageSample()];

coerce 'RepeatedNetworkUsageSample',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::NetworkUsageSample'->new($_) } @$_ ] };

declare 'MapStringNetworkUsageSample',
    as HashRef[NetworkUsageSample()];

declare 'DiskUsageSample',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::DiskUsageSample'];

coerce 'DiskUsageSample',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DiskUsageSample'->new($_) };

declare 'RepeatedDiskUsageSample',
    as ArrayRef[DiskUsageSample()];

coerce 'RepeatedDiskUsageSample',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DiskUsageSample'->new($_) } @$_ ] };

declare 'MapStringDiskUsageSample',
    as HashRef[DiskUsageSample()];

declare 'PerformanceSample',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::PerformanceSample'];

coerce 'PerformanceSample',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::PerformanceSample'->new($_) };

declare 'RepeatedPerformanceSample',
    as ArrayRef[PerformanceSample()];

coerce 'RepeatedPerformanceSample',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::PerformanceSample'->new($_) } @$_ ] };

declare 'MapStringPerformanceSample',
    as HashRef[PerformanceSample()];

declare 'AssetPerformanceData',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::AssetPerformanceData'];

coerce 'AssetPerformanceData',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AssetPerformanceData'->new($_) };

declare 'RepeatedAssetPerformanceData',
    as ArrayRef[AssetPerformanceData()];

coerce 'RepeatedAssetPerformanceData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AssetPerformanceData'->new($_) } @$_ ] };

declare 'MapStringAssetPerformanceData',
    as HashRef[AssetPerformanceData()];

declare 'DailyResourceUsageAggregation',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::DailyResourceUsageAggregation'];

coerce 'DailyResourceUsageAggregation',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DailyResourceUsageAggregation'->new($_) };

declare 'RepeatedDailyResourceUsageAggregation',
    as ArrayRef[DailyResourceUsageAggregation()];

coerce 'RepeatedDailyResourceUsageAggregation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DailyResourceUsageAggregation'->new($_) } @$_ ] };

declare 'MapStringDailyResourceUsageAggregation',
    as HashRef[DailyResourceUsageAggregation()];

declare 'Stats',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::DailyResourceUsageAggregation::Stats'];

coerce 'Stats',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DailyResourceUsageAggregation::Stats'->new($_) };

declare 'RepeatedStats',
    as ArrayRef[Stats()];

coerce 'RepeatedStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DailyResourceUsageAggregation::Stats'->new($_) } @$_ ] };

declare 'MapStringStats',
    as HashRef[Stats()];

declare 'CPU',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::DailyResourceUsageAggregation::CPU'];

coerce 'CPU',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DailyResourceUsageAggregation::CPU'->new($_) };

declare 'RepeatedCPU',
    as ArrayRef[CPU()];

coerce 'RepeatedCPU',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DailyResourceUsageAggregation::CPU'->new($_) } @$_ ] };

declare 'MapStringCPU',
    as HashRef[CPU()];

declare 'Memory',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::DailyResourceUsageAggregation::Memory'];

coerce 'Memory',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DailyResourceUsageAggregation::Memory'->new($_) };

declare 'RepeatedMemory',
    as ArrayRef[Memory()];

coerce 'RepeatedMemory',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DailyResourceUsageAggregation::Memory'->new($_) } @$_ ] };

declare 'MapStringMemory',
    as HashRef[Memory()];

declare 'Network',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::DailyResourceUsageAggregation::Network'];

coerce 'Network',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DailyResourceUsageAggregation::Network'->new($_) };

declare 'RepeatedNetwork',
    as ArrayRef[Network()];

coerce 'RepeatedNetwork',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DailyResourceUsageAggregation::Network'->new($_) } @$_ ] };

declare 'MapStringNetwork',
    as HashRef[Network()];

declare 'Disk',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::DailyResourceUsageAggregation::Disk'];

coerce 'Disk',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DailyResourceUsageAggregation::Disk'->new($_) };

declare 'RepeatedDisk',
    as ArrayRef[Disk()];

coerce 'RepeatedDisk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::DailyResourceUsageAggregation::Disk'->new($_) } @$_ ] };

declare 'MapStringDisk',
    as HashRef[Disk()];

declare 'InsightList',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::InsightList'];

coerce 'InsightList',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::InsightList'->new($_) };

declare 'RepeatedInsightList',
    as ArrayRef[InsightList()];

coerce 'RepeatedInsightList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::InsightList'->new($_) } @$_ ] };

declare 'MapStringInsightList',
    as HashRef[InsightList()];

declare 'Insight',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::Insight'];

coerce 'Insight',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::Insight'->new($_) };

declare 'RepeatedInsight',
    as ArrayRef[Insight()];

coerce 'RepeatedInsight',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::Insight'->new($_) } @$_ ] };

declare 'MapStringInsight',
    as HashRef[Insight()];

declare 'GenericInsight',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::GenericInsight'];

coerce 'GenericInsight',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GenericInsight'->new($_) };

declare 'RepeatedGenericInsight',
    as ArrayRef[GenericInsight()];

coerce 'RepeatedGenericInsight',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::GenericInsight'->new($_) } @$_ ] };

declare 'MapStringGenericInsight',
    as HashRef[GenericInsight()];

declare 'MigrationInsight',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::MigrationInsight'];

coerce 'MigrationInsight',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::MigrationInsight'->new($_) };

declare 'RepeatedMigrationInsight',
    as ArrayRef[MigrationInsight()];

coerce 'RepeatedMigrationInsight',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::MigrationInsight'->new($_) } @$_ ] };

declare 'MapStringMigrationInsight',
    as HashRef[MigrationInsight()];

declare 'ComputeEngineMigrationTarget',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ComputeEngineMigrationTarget'];

coerce 'ComputeEngineMigrationTarget',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ComputeEngineMigrationTarget'->new($_) };

declare 'RepeatedComputeEngineMigrationTarget',
    as ArrayRef[ComputeEngineMigrationTarget()];

coerce 'RepeatedComputeEngineMigrationTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ComputeEngineMigrationTarget'->new($_) } @$_ ] };

declare 'MapStringComputeEngineMigrationTarget',
    as HashRef[ComputeEngineMigrationTarget()];

declare 'ComputeEngineShapeDescriptor',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ComputeEngineShapeDescriptor'];

coerce 'ComputeEngineShapeDescriptor',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ComputeEngineShapeDescriptor'->new($_) };

declare 'RepeatedComputeEngineShapeDescriptor',
    as ArrayRef[ComputeEngineShapeDescriptor()];

coerce 'RepeatedComputeEngineShapeDescriptor',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ComputeEngineShapeDescriptor'->new($_) } @$_ ] };

declare 'MapStringComputeEngineShapeDescriptor',
    as HashRef[ComputeEngineShapeDescriptor()];

declare 'ComputeStorageDescriptor',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ComputeStorageDescriptor'];

coerce 'ComputeStorageDescriptor',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ComputeStorageDescriptor'->new($_) };

declare 'RepeatedComputeStorageDescriptor',
    as ArrayRef[ComputeStorageDescriptor()];

coerce 'RepeatedComputeStorageDescriptor',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ComputeStorageDescriptor'->new($_) } @$_ ] };

declare 'MapStringComputeStorageDescriptor',
    as HashRef[ComputeStorageDescriptor()];

declare 'FitDescriptor',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::FitDescriptor'];

coerce 'FitDescriptor',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::FitDescriptor'->new($_) };

declare 'RepeatedFitDescriptor',
    as ArrayRef[FitDescriptor()];

coerce 'RepeatedFitDescriptor',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::FitDescriptor'->new($_) } @$_ ] };

declare 'MapStringFitDescriptor',
    as HashRef[FitDescriptor()];

declare 'FitLevel',
    as (Int | Str);

declare 'Aggregation',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::Aggregation'];

coerce 'Aggregation',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::Aggregation'->new($_) };

declare 'RepeatedAggregation',
    as ArrayRef[Aggregation()];

coerce 'RepeatedAggregation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::Aggregation'->new($_) } @$_ ] };

declare 'MapStringAggregation',
    as HashRef[Aggregation()];

declare 'Count',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::Aggregation::Count'];

coerce 'Count',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::Aggregation::Count'->new($_) };

declare 'RepeatedCount',
    as ArrayRef[Count()];

coerce 'RepeatedCount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::Aggregation::Count'->new($_) } @$_ ] };

declare 'MapStringCount',
    as HashRef[Count()];

declare 'Sum',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::Aggregation::Sum'];

coerce 'Sum',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::Aggregation::Sum'->new($_) };

declare 'RepeatedSum',
    as ArrayRef[Sum()];

coerce 'RepeatedSum',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::Aggregation::Sum'->new($_) } @$_ ] };

declare 'MapStringSum',
    as HashRef[Sum()];

declare 'Histogram',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::Aggregation::Histogram'];

coerce 'Histogram',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::Aggregation::Histogram'->new($_) };

declare 'RepeatedHistogram',
    as ArrayRef[Histogram()];

coerce 'RepeatedHistogram',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::Aggregation::Histogram'->new($_) } @$_ ] };

declare 'MapStringHistogram',
    as HashRef[Histogram()];

declare 'Frequency',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::Aggregation::Frequency'];

coerce 'Frequency',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::Aggregation::Frequency'->new($_) };

declare 'RepeatedFrequency',
    as ArrayRef[Frequency()];

coerce 'RepeatedFrequency',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::Aggregation::Frequency'->new($_) } @$_ ] };

declare 'MapStringFrequency',
    as HashRef[Frequency()];

declare 'AggregationResult',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::AggregationResult'];

coerce 'AggregationResult',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AggregationResult'->new($_) };

declare 'RepeatedAggregationResult',
    as ArrayRef[AggregationResult()];

coerce 'RepeatedAggregationResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AggregationResult'->new($_) } @$_ ] };

declare 'MapStringAggregationResult',
    as HashRef[AggregationResult()];

declare 'Count',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::AggregationResult::Count'];

coerce 'Count',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AggregationResult::Count'->new($_) };

declare 'RepeatedCount',
    as ArrayRef[Count()];

coerce 'RepeatedCount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AggregationResult::Count'->new($_) } @$_ ] };

declare 'MapStringCount',
    as HashRef[Count()];

declare 'Sum',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::AggregationResult::Sum'];

coerce 'Sum',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AggregationResult::Sum'->new($_) };

declare 'RepeatedSum',
    as ArrayRef[Sum()];

coerce 'RepeatedSum',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AggregationResult::Sum'->new($_) } @$_ ] };

declare 'MapStringSum',
    as HashRef[Sum()];

declare 'Histogram',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::AggregationResult::Histogram'];

coerce 'Histogram',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AggregationResult::Histogram'->new($_) };

declare 'RepeatedHistogram',
    as ArrayRef[Histogram()];

coerce 'RepeatedHistogram',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AggregationResult::Histogram'->new($_) } @$_ ] };

declare 'MapStringHistogram',
    as HashRef[Histogram()];

declare 'Bucket',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::AggregationResult::Histogram::Bucket'];

coerce 'Bucket',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AggregationResult::Histogram::Bucket'->new($_) };

declare 'RepeatedBucket',
    as ArrayRef[Bucket()];

coerce 'RepeatedBucket',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AggregationResult::Histogram::Bucket'->new($_) } @$_ ] };

declare 'MapStringBucket',
    as HashRef[Bucket()];

declare 'Frequency',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::AggregationResult::Frequency'];

coerce 'Frequency',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AggregationResult::Frequency'->new($_) };

declare 'RepeatedFrequency',
    as ArrayRef[Frequency()];

coerce 'RepeatedFrequency',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AggregationResult::Frequency'->new($_) } @$_ ] };

declare 'MapStringFrequency',
    as HashRef[Frequency()];

declare 'ValuesEntry',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::AggregationResult::Frequency::ValuesEntry'];

coerce 'ValuesEntry',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AggregationResult::Frequency::ValuesEntry'->new($_) };

declare 'RepeatedValuesEntry',
    as ArrayRef[ValuesEntry()];

coerce 'RepeatedValuesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AggregationResult::Frequency::ValuesEntry'->new($_) } @$_ ] };

declare 'MapStringValuesEntry',
    as HashRef[ValuesEntry()];

declare 'FileValidationReport',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::FileValidationReport'];

coerce 'FileValidationReport',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::FileValidationReport'->new($_) };

declare 'RepeatedFileValidationReport',
    as ArrayRef[FileValidationReport()];

coerce 'RepeatedFileValidationReport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::FileValidationReport'->new($_) } @$_ ] };

declare 'MapStringFileValidationReport',
    as HashRef[FileValidationReport()];

declare 'ValidationReport',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ValidationReport'];

coerce 'ValidationReport',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ValidationReport'->new($_) };

declare 'RepeatedValidationReport',
    as ArrayRef[ValidationReport()];

coerce 'RepeatedValidationReport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ValidationReport'->new($_) } @$_ ] };

declare 'MapStringValidationReport',
    as HashRef[ValidationReport()];

declare 'ExecutionReport',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ExecutionReport'];

coerce 'ExecutionReport',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ExecutionReport'->new($_) };

declare 'RepeatedExecutionReport',
    as ArrayRef[ExecutionReport()];

coerce 'RepeatedExecutionReport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ExecutionReport'->new($_) } @$_ ] };

declare 'MapStringExecutionReport',
    as HashRef[ExecutionReport()];

declare 'ImportError',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ImportError'];

coerce 'ImportError',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ImportError'->new($_) };

declare 'RepeatedImportError',
    as ArrayRef[ImportError()];

coerce 'RepeatedImportError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ImportError'->new($_) } @$_ ] };

declare 'MapStringImportError',
    as HashRef[ImportError()];

declare 'Severity',
    as (Int | Str);

declare 'ImportRowError',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ImportRowError'];

coerce 'ImportRowError',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ImportRowError'->new($_) };

declare 'RepeatedImportRowError',
    as ArrayRef[ImportRowError()];

coerce 'RepeatedImportRowError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ImportRowError'->new($_) } @$_ ] };

declare 'MapStringImportRowError',
    as HashRef[ImportRowError()];

declare 'UploadFileInfo',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::UploadFileInfo'];

coerce 'UploadFileInfo',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::UploadFileInfo'->new($_) };

declare 'RepeatedUploadFileInfo',
    as ArrayRef[UploadFileInfo()];

coerce 'RepeatedUploadFileInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::UploadFileInfo'->new($_) } @$_ ] };

declare 'MapStringUploadFileInfo',
    as HashRef[UploadFileInfo()];

declare 'HeadersEntry',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::UploadFileInfo::HeadersEntry'];

coerce 'HeadersEntry',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::UploadFileInfo::HeadersEntry'->new($_) };

declare 'RepeatedHeadersEntry',
    as ArrayRef[HeadersEntry()];

coerce 'RepeatedHeadersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::UploadFileInfo::HeadersEntry'->new($_) } @$_ ] };

declare 'MapStringHeadersEntry',
    as HashRef[HeadersEntry()];

declare 'AssetList',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::AssetList'];

coerce 'AssetList',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AssetList'->new($_) };

declare 'RepeatedAssetList',
    as ArrayRef[AssetList()];

coerce 'RepeatedAssetList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::AssetList'->new($_) } @$_ ] };

declare 'MapStringAssetList',
    as HashRef[AssetList()];

declare 'FrameViolationEntry',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::FrameViolationEntry'];

coerce 'FrameViolationEntry',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::FrameViolationEntry'->new($_) };

declare 'RepeatedFrameViolationEntry',
    as ArrayRef[FrameViolationEntry()];

coerce 'RepeatedFrameViolationEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::FrameViolationEntry'->new($_) } @$_ ] };

declare 'MapStringFrameViolationEntry',
    as HashRef[FrameViolationEntry()];

declare 'VirtualMachinePreferences',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::VirtualMachinePreferences'];

coerce 'VirtualMachinePreferences',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::VirtualMachinePreferences'->new($_) };

declare 'RepeatedVirtualMachinePreferences',
    as ArrayRef[VirtualMachinePreferences()];

coerce 'RepeatedVirtualMachinePreferences',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::VirtualMachinePreferences'->new($_) } @$_ ] };

declare 'MapStringVirtualMachinePreferences',
    as HashRef[VirtualMachinePreferences()];

declare 'ComputeEnginePreferences',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ComputeEnginePreferences'];

coerce 'ComputeEnginePreferences',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ComputeEnginePreferences'->new($_) };

declare 'RepeatedComputeEnginePreferences',
    as ArrayRef[ComputeEnginePreferences()];

coerce 'RepeatedComputeEnginePreferences',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ComputeEnginePreferences'->new($_) } @$_ ] };

declare 'MapStringComputeEnginePreferences',
    as HashRef[ComputeEnginePreferences()];

declare 'MachinePreferences',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::MachinePreferences'];

coerce 'MachinePreferences',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::MachinePreferences'->new($_) };

declare 'RepeatedMachinePreferences',
    as ArrayRef[MachinePreferences()];

coerce 'RepeatedMachinePreferences',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::MachinePreferences'->new($_) } @$_ ] };

declare 'MapStringMachinePreferences',
    as HashRef[MachinePreferences()];

declare 'MachineSeries',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::MachineSeries'];

coerce 'MachineSeries',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::MachineSeries'->new($_) };

declare 'RepeatedMachineSeries',
    as ArrayRef[MachineSeries()];

coerce 'RepeatedMachineSeries',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::MachineSeries'->new($_) } @$_ ] };

declare 'MapStringMachineSeries',
    as HashRef[MachineSeries()];

declare 'VmwareEnginePreferences',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::VmwareEnginePreferences'];

coerce 'VmwareEnginePreferences',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::VmwareEnginePreferences'->new($_) };

declare 'RepeatedVmwareEnginePreferences',
    as ArrayRef[VmwareEnginePreferences()];

coerce 'RepeatedVmwareEnginePreferences',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::VmwareEnginePreferences'->new($_) } @$_ ] };

declare 'MapStringVmwareEnginePreferences',
    as HashRef[VmwareEnginePreferences()];

declare 'CommitmentPlan',
    as (Int | Str);

declare 'SoleTenancyPreferences',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::SoleTenancyPreferences'];

coerce 'SoleTenancyPreferences',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::SoleTenancyPreferences'->new($_) };

declare 'RepeatedSoleTenancyPreferences',
    as ArrayRef[SoleTenancyPreferences()];

coerce 'RepeatedSoleTenancyPreferences',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::SoleTenancyPreferences'->new($_) } @$_ ] };

declare 'MapStringSoleTenancyPreferences',
    as HashRef[SoleTenancyPreferences()];

declare 'HostMaintenancePolicy',
    as (Int | Str);

declare 'CommitmentPlan',
    as (Int | Str);

declare 'SoleTenantNodeType',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::SoleTenantNodeType'];

coerce 'SoleTenantNodeType',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::SoleTenantNodeType'->new($_) };

declare 'RepeatedSoleTenantNodeType',
    as ArrayRef[SoleTenantNodeType()];

coerce 'RepeatedSoleTenantNodeType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::SoleTenantNodeType'->new($_) } @$_ ] };

declare 'MapStringSoleTenantNodeType',
    as HashRef[SoleTenantNodeType()];

declare 'RegionPreferences',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::RegionPreferences'];

coerce 'RegionPreferences',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::RegionPreferences'->new($_) };

declare 'RepeatedRegionPreferences',
    as ArrayRef[RegionPreferences()];

coerce 'RepeatedRegionPreferences',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::RegionPreferences'->new($_) } @$_ ] };

declare 'MapStringRegionPreferences',
    as HashRef[RegionPreferences()];

declare 'Settings',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::Settings'];

coerce 'Settings',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::Settings'->new($_) };

declare 'RepeatedSettings',
    as ArrayRef[Settings()];

coerce 'RepeatedSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::Settings'->new($_) } @$_ ] };

declare 'MapStringSettings',
    as HashRef[Settings()];

declare 'ReportSummary',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary'];

coerce 'ReportSummary',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary'->new($_) };

declare 'RepeatedReportSummary',
    as ArrayRef[ReportSummary()];

coerce 'RepeatedReportSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary'->new($_) } @$_ ] };

declare 'MapStringReportSummary',
    as HashRef[ReportSummary()];

declare 'ChartData',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::ChartData'];

coerce 'ChartData',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::ChartData'->new($_) };

declare 'RepeatedChartData',
    as ArrayRef[ChartData()];

coerce 'RepeatedChartData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::ChartData'->new($_) } @$_ ] };

declare 'MapStringChartData',
    as HashRef[ChartData()];

declare 'DataPoint',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::ChartData::DataPoint'];

coerce 'DataPoint',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::ChartData::DataPoint'->new($_) };

declare 'RepeatedDataPoint',
    as ArrayRef[DataPoint()];

coerce 'RepeatedDataPoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::ChartData::DataPoint'->new($_) } @$_ ] };

declare 'MapStringDataPoint',
    as HashRef[DataPoint()];

declare 'UtilizationChartData',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::UtilizationChartData'];

coerce 'UtilizationChartData',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::UtilizationChartData'->new($_) };

declare 'RepeatedUtilizationChartData',
    as ArrayRef[UtilizationChartData()];

coerce 'RepeatedUtilizationChartData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::UtilizationChartData'->new($_) } @$_ ] };

declare 'MapStringUtilizationChartData',
    as HashRef[UtilizationChartData()];

declare 'HistogramChartData',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::HistogramChartData'];

coerce 'HistogramChartData',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::HistogramChartData'->new($_) };

declare 'RepeatedHistogramChartData',
    as ArrayRef[HistogramChartData()];

coerce 'RepeatedHistogramChartData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::HistogramChartData'->new($_) } @$_ ] };

declare 'MapStringHistogramChartData',
    as HashRef[HistogramChartData()];

declare 'Bucket',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::HistogramChartData::Bucket'];

coerce 'Bucket',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::HistogramChartData::Bucket'->new($_) };

declare 'RepeatedBucket',
    as ArrayRef[Bucket()];

coerce 'RepeatedBucket',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::HistogramChartData::Bucket'->new($_) } @$_ ] };

declare 'MapStringBucket',
    as HashRef[Bucket()];

declare 'AssetAggregateStats',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::AssetAggregateStats'];

coerce 'AssetAggregateStats',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::AssetAggregateStats'->new($_) };

declare 'RepeatedAssetAggregateStats',
    as ArrayRef[AssetAggregateStats()];

coerce 'RepeatedAssetAggregateStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::AssetAggregateStats'->new($_) } @$_ ] };

declare 'MapStringAssetAggregateStats',
    as HashRef[AssetAggregateStats()];

declare 'MachineSeriesAllocation',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::MachineSeriesAllocation'];

coerce 'MachineSeriesAllocation',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::MachineSeriesAllocation'->new($_) };

declare 'RepeatedMachineSeriesAllocation',
    as ArrayRef[MachineSeriesAllocation()];

coerce 'RepeatedMachineSeriesAllocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::MachineSeriesAllocation'->new($_) } @$_ ] };

declare 'MapStringMachineSeriesAllocation',
    as HashRef[MachineSeriesAllocation()];

declare 'ComputeEngineFinding',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::ComputeEngineFinding'];

coerce 'ComputeEngineFinding',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::ComputeEngineFinding'->new($_) };

declare 'RepeatedComputeEngineFinding',
    as ArrayRef[ComputeEngineFinding()];

coerce 'RepeatedComputeEngineFinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::ComputeEngineFinding'->new($_) } @$_ ] };

declare 'MapStringComputeEngineFinding',
    as HashRef[ComputeEngineFinding()];

declare 'VmwareEngineFinding',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::VmwareEngineFinding'];

coerce 'VmwareEngineFinding',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::VmwareEngineFinding'->new($_) };

declare 'RepeatedVmwareEngineFinding',
    as ArrayRef[VmwareEngineFinding()];

coerce 'RepeatedVmwareEngineFinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::VmwareEngineFinding'->new($_) } @$_ ] };

declare 'MapStringVmwareEngineFinding',
    as HashRef[VmwareEngineFinding()];

declare 'VmwareNodeAllocation',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::VmwareNodeAllocation'];

coerce 'VmwareNodeAllocation',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::VmwareNodeAllocation'->new($_) };

declare 'RepeatedVmwareNodeAllocation',
    as ArrayRef[VmwareNodeAllocation()];

coerce 'RepeatedVmwareNodeAllocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::VmwareNodeAllocation'->new($_) } @$_ ] };

declare 'MapStringVmwareNodeAllocation',
    as HashRef[VmwareNodeAllocation()];

declare 'VmwareNode',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::VmwareNode'];

coerce 'VmwareNode',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::VmwareNode'->new($_) };

declare 'RepeatedVmwareNode',
    as ArrayRef[VmwareNode()];

coerce 'RepeatedVmwareNode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::VmwareNode'->new($_) } @$_ ] };

declare 'MapStringVmwareNode',
    as HashRef[VmwareNode()];

declare 'SoleTenantFinding',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::SoleTenantFinding'];

coerce 'SoleTenantFinding',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::SoleTenantFinding'->new($_) };

declare 'RepeatedSoleTenantFinding',
    as ArrayRef[SoleTenantFinding()];

coerce 'RepeatedSoleTenantFinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::SoleTenantFinding'->new($_) } @$_ ] };

declare 'MapStringSoleTenantFinding',
    as HashRef[SoleTenantFinding()];

declare 'SoleTenantNodeAllocation',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::SoleTenantNodeAllocation'];

coerce 'SoleTenantNodeAllocation',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::SoleTenantNodeAllocation'->new($_) };

declare 'RepeatedSoleTenantNodeAllocation',
    as ArrayRef[SoleTenantNodeAllocation()];

coerce 'RepeatedSoleTenantNodeAllocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::SoleTenantNodeAllocation'->new($_) } @$_ ] };

declare 'MapStringSoleTenantNodeAllocation',
    as HashRef[SoleTenantNodeAllocation()];

declare 'GroupPreferenceSetFinding',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::GroupPreferenceSetFinding'];

coerce 'GroupPreferenceSetFinding',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::GroupPreferenceSetFinding'->new($_) };

declare 'RepeatedGroupPreferenceSetFinding',
    as ArrayRef[GroupPreferenceSetFinding()];

coerce 'RepeatedGroupPreferenceSetFinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::GroupPreferenceSetFinding'->new($_) } @$_ ] };

declare 'MapStringGroupPreferenceSetFinding',
    as HashRef[GroupPreferenceSetFinding()];

declare 'GroupFinding',
    as InstanceOf['Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::GroupFinding'];

coerce 'GroupFinding',
    from HashRef, via { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::GroupFinding'->new($_) };

declare 'RepeatedGroupFinding',
    as ArrayRef[GroupFinding()];

coerce 'RepeatedGroupFinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Migrationcenter::V1::Migrationcenter::ReportSummary::GroupFinding'->new($_) } @$_ ] };

declare 'MapStringGroupFinding',
    as HashRef[GroupFinding()];

1;

__END__

=head1 NAME

Google::Cloud::Migrationcenter::V1::Migrationcenter::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
