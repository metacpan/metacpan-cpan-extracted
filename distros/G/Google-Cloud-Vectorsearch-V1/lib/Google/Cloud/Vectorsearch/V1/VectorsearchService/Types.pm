package Google::Cloud::Vectorsearch::V1::VectorsearchService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Collection',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::Collection'];

coerce 'Collection',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::Collection'->new($_) };

declare 'RepeatedCollection',
    as ArrayRef[Collection()];

coerce 'RepeatedCollection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::Collection'->new($_) } @$_ ] };

declare 'MapStringCollection',
    as HashRef[Collection()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::Collection::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::Collection::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::Collection::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'VectorSchemaEntry',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::Collection::VectorSchemaEntry'];

coerce 'VectorSchemaEntry',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::Collection::VectorSchemaEntry'->new($_) };

declare 'RepeatedVectorSchemaEntry',
    as ArrayRef[VectorSchemaEntry()];

coerce 'RepeatedVectorSchemaEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::Collection::VectorSchemaEntry'->new($_) } @$_ ] };

declare 'MapStringVectorSchemaEntry',
    as HashRef[VectorSchemaEntry()];

declare 'VectorField',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::VectorField'];

coerce 'VectorField',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::VectorField'->new($_) };

declare 'RepeatedVectorField',
    as ArrayRef[VectorField()];

coerce 'RepeatedVectorField',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::VectorField'->new($_) } @$_ ] };

declare 'MapStringVectorField',
    as HashRef[VectorField()];

declare 'DenseVectorField',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::DenseVectorField'];

coerce 'DenseVectorField',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::DenseVectorField'->new($_) };

declare 'RepeatedDenseVectorField',
    as ArrayRef[DenseVectorField()];

coerce 'RepeatedDenseVectorField',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::DenseVectorField'->new($_) } @$_ ] };

declare 'MapStringDenseVectorField',
    as HashRef[DenseVectorField()];

declare 'SparseVectorField',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::SparseVectorField'];

coerce 'SparseVectorField',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::SparseVectorField'->new($_) };

declare 'RepeatedSparseVectorField',
    as ArrayRef[SparseVectorField()];

coerce 'RepeatedSparseVectorField',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::SparseVectorField'->new($_) } @$_ ] };

declare 'MapStringSparseVectorField',
    as HashRef[SparseVectorField()];

declare 'ListCollectionsRequest',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::ListCollectionsRequest'];

coerce 'ListCollectionsRequest',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::ListCollectionsRequest'->new($_) };

declare 'RepeatedListCollectionsRequest',
    as ArrayRef[ListCollectionsRequest()];

coerce 'RepeatedListCollectionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::ListCollectionsRequest'->new($_) } @$_ ] };

declare 'MapStringListCollectionsRequest',
    as HashRef[ListCollectionsRequest()];

declare 'ListCollectionsResponse',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::ListCollectionsResponse'];

coerce 'ListCollectionsResponse',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::ListCollectionsResponse'->new($_) };

declare 'RepeatedListCollectionsResponse',
    as ArrayRef[ListCollectionsResponse()];

coerce 'RepeatedListCollectionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::ListCollectionsResponse'->new($_) } @$_ ] };

declare 'MapStringListCollectionsResponse',
    as HashRef[ListCollectionsResponse()];

declare 'GetCollectionRequest',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::GetCollectionRequest'];

coerce 'GetCollectionRequest',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::GetCollectionRequest'->new($_) };

declare 'RepeatedGetCollectionRequest',
    as ArrayRef[GetCollectionRequest()];

coerce 'RepeatedGetCollectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::GetCollectionRequest'->new($_) } @$_ ] };

declare 'MapStringGetCollectionRequest',
    as HashRef[GetCollectionRequest()];

declare 'CreateCollectionRequest',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::CreateCollectionRequest'];

coerce 'CreateCollectionRequest',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::CreateCollectionRequest'->new($_) };

declare 'RepeatedCreateCollectionRequest',
    as ArrayRef[CreateCollectionRequest()];

coerce 'RepeatedCreateCollectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::CreateCollectionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCollectionRequest',
    as HashRef[CreateCollectionRequest()];

declare 'UpdateCollectionRequest',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::UpdateCollectionRequest'];

coerce 'UpdateCollectionRequest',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::UpdateCollectionRequest'->new($_) };

declare 'RepeatedUpdateCollectionRequest',
    as ArrayRef[UpdateCollectionRequest()];

coerce 'RepeatedUpdateCollectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::UpdateCollectionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCollectionRequest',
    as HashRef[UpdateCollectionRequest()];

declare 'DeleteCollectionRequest',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::DeleteCollectionRequest'];

coerce 'DeleteCollectionRequest',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::DeleteCollectionRequest'->new($_) };

declare 'RepeatedDeleteCollectionRequest',
    as ArrayRef[DeleteCollectionRequest()];

coerce 'RepeatedDeleteCollectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::DeleteCollectionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCollectionRequest',
    as HashRef[DeleteCollectionRequest()];

declare 'Index',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::Index'];

coerce 'Index',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::Index'->new($_) };

declare 'RepeatedIndex',
    as ArrayRef[Index()];

coerce 'RepeatedIndex',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::Index'->new($_) } @$_ ] };

declare 'MapStringIndex',
    as HashRef[Index()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::Index::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::Index::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::Index::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'CreateIndexRequest',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::CreateIndexRequest'];

coerce 'CreateIndexRequest',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::CreateIndexRequest'->new($_) };

declare 'RepeatedCreateIndexRequest',
    as ArrayRef[CreateIndexRequest()];

coerce 'RepeatedCreateIndexRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::CreateIndexRequest'->new($_) } @$_ ] };

declare 'MapStringCreateIndexRequest',
    as HashRef[CreateIndexRequest()];

declare 'UpdateIndexRequest',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::UpdateIndexRequest'];

coerce 'UpdateIndexRequest',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::UpdateIndexRequest'->new($_) };

declare 'RepeatedUpdateIndexRequest',
    as ArrayRef[UpdateIndexRequest()];

coerce 'RepeatedUpdateIndexRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::UpdateIndexRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateIndexRequest',
    as HashRef[UpdateIndexRequest()];

declare 'DeleteIndexRequest',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::DeleteIndexRequest'];

coerce 'DeleteIndexRequest',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::DeleteIndexRequest'->new($_) };

declare 'RepeatedDeleteIndexRequest',
    as ArrayRef[DeleteIndexRequest()];

coerce 'RepeatedDeleteIndexRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::DeleteIndexRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteIndexRequest',
    as HashRef[DeleteIndexRequest()];

declare 'ListIndexesRequest',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::ListIndexesRequest'];

coerce 'ListIndexesRequest',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::ListIndexesRequest'->new($_) };

declare 'RepeatedListIndexesRequest',
    as ArrayRef[ListIndexesRequest()];

coerce 'RepeatedListIndexesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::ListIndexesRequest'->new($_) } @$_ ] };

declare 'MapStringListIndexesRequest',
    as HashRef[ListIndexesRequest()];

declare 'ListIndexesResponse',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::ListIndexesResponse'];

coerce 'ListIndexesResponse',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::ListIndexesResponse'->new($_) };

declare 'RepeatedListIndexesResponse',
    as ArrayRef[ListIndexesResponse()];

coerce 'RepeatedListIndexesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::ListIndexesResponse'->new($_) } @$_ ] };

declare 'MapStringListIndexesResponse',
    as HashRef[ListIndexesResponse()];

declare 'GetIndexRequest',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::GetIndexRequest'];

coerce 'GetIndexRequest',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::GetIndexRequest'->new($_) };

declare 'RepeatedGetIndexRequest',
    as ArrayRef[GetIndexRequest()];

coerce 'RepeatedGetIndexRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::GetIndexRequest'->new($_) } @$_ ] };

declare 'MapStringGetIndexRequest',
    as HashRef[GetIndexRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'ImportDataObjectsRequest',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::ImportDataObjectsRequest'];

coerce 'ImportDataObjectsRequest',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::ImportDataObjectsRequest'->new($_) };

declare 'RepeatedImportDataObjectsRequest',
    as ArrayRef[ImportDataObjectsRequest()];

coerce 'RepeatedImportDataObjectsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::ImportDataObjectsRequest'->new($_) } @$_ ] };

declare 'MapStringImportDataObjectsRequest',
    as HashRef[ImportDataObjectsRequest()];

declare 'GcsImportConfig',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::ImportDataObjectsRequest::GcsImportConfig'];

coerce 'GcsImportConfig',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::ImportDataObjectsRequest::GcsImportConfig'->new($_) };

declare 'RepeatedGcsImportConfig',
    as ArrayRef[GcsImportConfig()];

coerce 'RepeatedGcsImportConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::ImportDataObjectsRequest::GcsImportConfig'->new($_) } @$_ ] };

declare 'MapStringGcsImportConfig',
    as HashRef[GcsImportConfig()];

declare 'ImportDataObjectsMetadata',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::ImportDataObjectsMetadata'];

coerce 'ImportDataObjectsMetadata',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::ImportDataObjectsMetadata'->new($_) };

declare 'RepeatedImportDataObjectsMetadata',
    as ArrayRef[ImportDataObjectsMetadata()];

coerce 'RepeatedImportDataObjectsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::ImportDataObjectsMetadata'->new($_) } @$_ ] };

declare 'MapStringImportDataObjectsMetadata',
    as HashRef[ImportDataObjectsMetadata()];

declare 'ImportDataObjectsResponse',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::ImportDataObjectsResponse'];

coerce 'ImportDataObjectsResponse',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::ImportDataObjectsResponse'->new($_) };

declare 'RepeatedImportDataObjectsResponse',
    as ArrayRef[ImportDataObjectsResponse()];

coerce 'RepeatedImportDataObjectsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::ImportDataObjectsResponse'->new($_) } @$_ ] };

declare 'MapStringImportDataObjectsResponse',
    as HashRef[ImportDataObjectsResponse()];

declare 'ExportDataObjectsRequest',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::ExportDataObjectsRequest'];

coerce 'ExportDataObjectsRequest',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::ExportDataObjectsRequest'->new($_) };

declare 'RepeatedExportDataObjectsRequest',
    as ArrayRef[ExportDataObjectsRequest()];

coerce 'RepeatedExportDataObjectsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::ExportDataObjectsRequest'->new($_) } @$_ ] };

declare 'MapStringExportDataObjectsRequest',
    as HashRef[ExportDataObjectsRequest()];

declare 'GcsExportDestination',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::ExportDataObjectsRequest::GcsExportDestination'];

coerce 'GcsExportDestination',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::ExportDataObjectsRequest::GcsExportDestination'->new($_) };

declare 'RepeatedGcsExportDestination',
    as ArrayRef[GcsExportDestination()];

coerce 'RepeatedGcsExportDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::ExportDataObjectsRequest::GcsExportDestination'->new($_) } @$_ ] };

declare 'MapStringGcsExportDestination',
    as HashRef[GcsExportDestination()];

declare 'Format',
    as (Int | Str);

declare 'FieldFilter',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::ExportDataObjectsRequest::FieldFilter'];

coerce 'FieldFilter',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::ExportDataObjectsRequest::FieldFilter'->new($_) };

declare 'RepeatedFieldFilter',
    as ArrayRef[FieldFilter()];

coerce 'RepeatedFieldFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::ExportDataObjectsRequest::FieldFilter'->new($_) } @$_ ] };

declare 'MapStringFieldFilter',
    as HashRef[FieldFilter()];

declare 'FieldList',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::ExportDataObjectsRequest::FieldFilter::FieldList'];

coerce 'FieldList',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::ExportDataObjectsRequest::FieldFilter::FieldList'->new($_) };

declare 'RepeatedFieldList',
    as ArrayRef[FieldList()];

coerce 'RepeatedFieldList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::ExportDataObjectsRequest::FieldFilter::FieldList'->new($_) } @$_ ] };

declare 'MapStringFieldList',
    as HashRef[FieldList()];

declare 'ExportDataObjectsMetadata',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::ExportDataObjectsMetadata'];

coerce 'ExportDataObjectsMetadata',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::ExportDataObjectsMetadata'->new($_) };

declare 'RepeatedExportDataObjectsMetadata',
    as ArrayRef[ExportDataObjectsMetadata()];

coerce 'RepeatedExportDataObjectsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::ExportDataObjectsMetadata'->new($_) } @$_ ] };

declare 'MapStringExportDataObjectsMetadata',
    as HashRef[ExportDataObjectsMetadata()];

declare 'ExportDataObjectsResponse',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::ExportDataObjectsResponse'];

coerce 'ExportDataObjectsResponse',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::ExportDataObjectsResponse'->new($_) };

declare 'RepeatedExportDataObjectsResponse',
    as ArrayRef[ExportDataObjectsResponse()];

coerce 'RepeatedExportDataObjectsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::ExportDataObjectsResponse'->new($_) } @$_ ] };

declare 'MapStringExportDataObjectsResponse',
    as HashRef[ExportDataObjectsResponse()];

declare 'DedicatedInfrastructure',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::DedicatedInfrastructure'];

coerce 'DedicatedInfrastructure',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::DedicatedInfrastructure'->new($_) };

declare 'RepeatedDedicatedInfrastructure',
    as ArrayRef[DedicatedInfrastructure()];

coerce 'RepeatedDedicatedInfrastructure',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::DedicatedInfrastructure'->new($_) } @$_ ] };

declare 'MapStringDedicatedInfrastructure',
    as HashRef[DedicatedInfrastructure()];

declare 'Mode',
    as (Int | Str);

declare 'AutoscalingSpec',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::DedicatedInfrastructure::AutoscalingSpec'];

coerce 'AutoscalingSpec',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::DedicatedInfrastructure::AutoscalingSpec'->new($_) };

declare 'RepeatedAutoscalingSpec',
    as ArrayRef[AutoscalingSpec()];

coerce 'RepeatedAutoscalingSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::DedicatedInfrastructure::AutoscalingSpec'->new($_) } @$_ ] };

declare 'MapStringAutoscalingSpec',
    as HashRef[AutoscalingSpec()];

declare 'DenseScannIndex',
    as InstanceOf['Google::Cloud::Vectorsearch::V1::VectorsearchService::DenseScannIndex'];

coerce 'DenseScannIndex',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::DenseScannIndex'->new($_) };

declare 'RepeatedDenseScannIndex',
    as ArrayRef[DenseScannIndex()];

coerce 'RepeatedDenseScannIndex',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1::VectorsearchService::DenseScannIndex'->new($_) } @$_ ] };

declare 'MapStringDenseScannIndex',
    as HashRef[DenseScannIndex()];

declare 'FeatureNormType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Vectorsearch::V1::VectorsearchService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
