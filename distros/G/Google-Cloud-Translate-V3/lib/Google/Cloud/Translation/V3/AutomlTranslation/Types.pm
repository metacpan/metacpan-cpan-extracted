package Google::Cloud::Translation::V3::AutomlTranslation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ImportDataRequest',
    as InstanceOf['Google::Cloud::Translation::V3::AutomlTranslation::ImportDataRequest'];

coerce 'ImportDataRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::AutomlTranslation::ImportDataRequest'->new($_) };

declare 'RepeatedImportDataRequest',
    as ArrayRef[ImportDataRequest()];

coerce 'RepeatedImportDataRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AutomlTranslation::ImportDataRequest'->new($_) } @$_ ] };

declare 'MapStringImportDataRequest',
    as HashRef[ImportDataRequest()];

declare 'DatasetInputConfig',
    as InstanceOf['Google::Cloud::Translation::V3::AutomlTranslation::DatasetInputConfig'];

coerce 'DatasetInputConfig',
    from HashRef, via { 'Google::Cloud::Translation::V3::AutomlTranslation::DatasetInputConfig'->new($_) };

declare 'RepeatedDatasetInputConfig',
    as ArrayRef[DatasetInputConfig()];

coerce 'RepeatedDatasetInputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AutomlTranslation::DatasetInputConfig'->new($_) } @$_ ] };

declare 'MapStringDatasetInputConfig',
    as HashRef[DatasetInputConfig()];

declare 'InputFile',
    as InstanceOf['Google::Cloud::Translation::V3::AutomlTranslation::DatasetInputConfig::InputFile'];

coerce 'InputFile',
    from HashRef, via { 'Google::Cloud::Translation::V3::AutomlTranslation::DatasetInputConfig::InputFile'->new($_) };

declare 'RepeatedInputFile',
    as ArrayRef[InputFile()];

coerce 'RepeatedInputFile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AutomlTranslation::DatasetInputConfig::InputFile'->new($_) } @$_ ] };

declare 'MapStringInputFile',
    as HashRef[InputFile()];

declare 'ImportDataMetadata',
    as InstanceOf['Google::Cloud::Translation::V3::AutomlTranslation::ImportDataMetadata'];

coerce 'ImportDataMetadata',
    from HashRef, via { 'Google::Cloud::Translation::V3::AutomlTranslation::ImportDataMetadata'->new($_) };

declare 'RepeatedImportDataMetadata',
    as ArrayRef[ImportDataMetadata()];

coerce 'RepeatedImportDataMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AutomlTranslation::ImportDataMetadata'->new($_) } @$_ ] };

declare 'MapStringImportDataMetadata',
    as HashRef[ImportDataMetadata()];

declare 'ExportDataRequest',
    as InstanceOf['Google::Cloud::Translation::V3::AutomlTranslation::ExportDataRequest'];

coerce 'ExportDataRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::AutomlTranslation::ExportDataRequest'->new($_) };

declare 'RepeatedExportDataRequest',
    as ArrayRef[ExportDataRequest()];

coerce 'RepeatedExportDataRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AutomlTranslation::ExportDataRequest'->new($_) } @$_ ] };

declare 'MapStringExportDataRequest',
    as HashRef[ExportDataRequest()];

declare 'DatasetOutputConfig',
    as InstanceOf['Google::Cloud::Translation::V3::AutomlTranslation::DatasetOutputConfig'];

coerce 'DatasetOutputConfig',
    from HashRef, via { 'Google::Cloud::Translation::V3::AutomlTranslation::DatasetOutputConfig'->new($_) };

declare 'RepeatedDatasetOutputConfig',
    as ArrayRef[DatasetOutputConfig()];

coerce 'RepeatedDatasetOutputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AutomlTranslation::DatasetOutputConfig'->new($_) } @$_ ] };

declare 'MapStringDatasetOutputConfig',
    as HashRef[DatasetOutputConfig()];

declare 'ExportDataMetadata',
    as InstanceOf['Google::Cloud::Translation::V3::AutomlTranslation::ExportDataMetadata'];

coerce 'ExportDataMetadata',
    from HashRef, via { 'Google::Cloud::Translation::V3::AutomlTranslation::ExportDataMetadata'->new($_) };

declare 'RepeatedExportDataMetadata',
    as ArrayRef[ExportDataMetadata()];

coerce 'RepeatedExportDataMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AutomlTranslation::ExportDataMetadata'->new($_) } @$_ ] };

declare 'MapStringExportDataMetadata',
    as HashRef[ExportDataMetadata()];

declare 'DeleteDatasetRequest',
    as InstanceOf['Google::Cloud::Translation::V3::AutomlTranslation::DeleteDatasetRequest'];

coerce 'DeleteDatasetRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::AutomlTranslation::DeleteDatasetRequest'->new($_) };

declare 'RepeatedDeleteDatasetRequest',
    as ArrayRef[DeleteDatasetRequest()];

coerce 'RepeatedDeleteDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AutomlTranslation::DeleteDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDatasetRequest',
    as HashRef[DeleteDatasetRequest()];

declare 'DeleteDatasetMetadata',
    as InstanceOf['Google::Cloud::Translation::V3::AutomlTranslation::DeleteDatasetMetadata'];

coerce 'DeleteDatasetMetadata',
    from HashRef, via { 'Google::Cloud::Translation::V3::AutomlTranslation::DeleteDatasetMetadata'->new($_) };

declare 'RepeatedDeleteDatasetMetadata',
    as ArrayRef[DeleteDatasetMetadata()];

coerce 'RepeatedDeleteDatasetMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AutomlTranslation::DeleteDatasetMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteDatasetMetadata',
    as HashRef[DeleteDatasetMetadata()];

declare 'GetDatasetRequest',
    as InstanceOf['Google::Cloud::Translation::V3::AutomlTranslation::GetDatasetRequest'];

coerce 'GetDatasetRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::AutomlTranslation::GetDatasetRequest'->new($_) };

declare 'RepeatedGetDatasetRequest',
    as ArrayRef[GetDatasetRequest()];

coerce 'RepeatedGetDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AutomlTranslation::GetDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringGetDatasetRequest',
    as HashRef[GetDatasetRequest()];

declare 'ListDatasetsRequest',
    as InstanceOf['Google::Cloud::Translation::V3::AutomlTranslation::ListDatasetsRequest'];

coerce 'ListDatasetsRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::AutomlTranslation::ListDatasetsRequest'->new($_) };

declare 'RepeatedListDatasetsRequest',
    as ArrayRef[ListDatasetsRequest()];

coerce 'RepeatedListDatasetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AutomlTranslation::ListDatasetsRequest'->new($_) } @$_ ] };

declare 'MapStringListDatasetsRequest',
    as HashRef[ListDatasetsRequest()];

declare 'ListDatasetsResponse',
    as InstanceOf['Google::Cloud::Translation::V3::AutomlTranslation::ListDatasetsResponse'];

coerce 'ListDatasetsResponse',
    from HashRef, via { 'Google::Cloud::Translation::V3::AutomlTranslation::ListDatasetsResponse'->new($_) };

declare 'RepeatedListDatasetsResponse',
    as ArrayRef[ListDatasetsResponse()];

coerce 'RepeatedListDatasetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AutomlTranslation::ListDatasetsResponse'->new($_) } @$_ ] };

declare 'MapStringListDatasetsResponse',
    as HashRef[ListDatasetsResponse()];

declare 'CreateDatasetRequest',
    as InstanceOf['Google::Cloud::Translation::V3::AutomlTranslation::CreateDatasetRequest'];

coerce 'CreateDatasetRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::AutomlTranslation::CreateDatasetRequest'->new($_) };

declare 'RepeatedCreateDatasetRequest',
    as ArrayRef[CreateDatasetRequest()];

coerce 'RepeatedCreateDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AutomlTranslation::CreateDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDatasetRequest',
    as HashRef[CreateDatasetRequest()];

declare 'CreateDatasetMetadata',
    as InstanceOf['Google::Cloud::Translation::V3::AutomlTranslation::CreateDatasetMetadata'];

coerce 'CreateDatasetMetadata',
    from HashRef, via { 'Google::Cloud::Translation::V3::AutomlTranslation::CreateDatasetMetadata'->new($_) };

declare 'RepeatedCreateDatasetMetadata',
    as ArrayRef[CreateDatasetMetadata()];

coerce 'RepeatedCreateDatasetMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AutomlTranslation::CreateDatasetMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateDatasetMetadata',
    as HashRef[CreateDatasetMetadata()];

declare 'ListExamplesRequest',
    as InstanceOf['Google::Cloud::Translation::V3::AutomlTranslation::ListExamplesRequest'];

coerce 'ListExamplesRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::AutomlTranslation::ListExamplesRequest'->new($_) };

declare 'RepeatedListExamplesRequest',
    as ArrayRef[ListExamplesRequest()];

coerce 'RepeatedListExamplesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AutomlTranslation::ListExamplesRequest'->new($_) } @$_ ] };

declare 'MapStringListExamplesRequest',
    as HashRef[ListExamplesRequest()];

declare 'ListExamplesResponse',
    as InstanceOf['Google::Cloud::Translation::V3::AutomlTranslation::ListExamplesResponse'];

coerce 'ListExamplesResponse',
    from HashRef, via { 'Google::Cloud::Translation::V3::AutomlTranslation::ListExamplesResponse'->new($_) };

declare 'RepeatedListExamplesResponse',
    as ArrayRef[ListExamplesResponse()];

coerce 'RepeatedListExamplesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AutomlTranslation::ListExamplesResponse'->new($_) } @$_ ] };

declare 'MapStringListExamplesResponse',
    as HashRef[ListExamplesResponse()];

declare 'Example',
    as InstanceOf['Google::Cloud::Translation::V3::AutomlTranslation::Example'];

coerce 'Example',
    from HashRef, via { 'Google::Cloud::Translation::V3::AutomlTranslation::Example'->new($_) };

declare 'RepeatedExample',
    as ArrayRef[Example()];

coerce 'RepeatedExample',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AutomlTranslation::Example'->new($_) } @$_ ] };

declare 'MapStringExample',
    as HashRef[Example()];

declare 'BatchTransferResourcesResponse',
    as InstanceOf['Google::Cloud::Translation::V3::AutomlTranslation::BatchTransferResourcesResponse'];

coerce 'BatchTransferResourcesResponse',
    from HashRef, via { 'Google::Cloud::Translation::V3::AutomlTranslation::BatchTransferResourcesResponse'->new($_) };

declare 'RepeatedBatchTransferResourcesResponse',
    as ArrayRef[BatchTransferResourcesResponse()];

coerce 'RepeatedBatchTransferResourcesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AutomlTranslation::BatchTransferResourcesResponse'->new($_) } @$_ ] };

declare 'MapStringBatchTransferResourcesResponse',
    as HashRef[BatchTransferResourcesResponse()];

declare 'TransferResourceResponse',
    as InstanceOf['Google::Cloud::Translation::V3::AutomlTranslation::BatchTransferResourcesResponse::TransferResourceResponse'];

coerce 'TransferResourceResponse',
    from HashRef, via { 'Google::Cloud::Translation::V3::AutomlTranslation::BatchTransferResourcesResponse::TransferResourceResponse'->new($_) };

declare 'RepeatedTransferResourceResponse',
    as ArrayRef[TransferResourceResponse()];

coerce 'RepeatedTransferResourceResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AutomlTranslation::BatchTransferResourcesResponse::TransferResourceResponse'->new($_) } @$_ ] };

declare 'MapStringTransferResourceResponse',
    as HashRef[TransferResourceResponse()];

declare 'Dataset',
    as InstanceOf['Google::Cloud::Translation::V3::AutomlTranslation::Dataset'];

coerce 'Dataset',
    from HashRef, via { 'Google::Cloud::Translation::V3::AutomlTranslation::Dataset'->new($_) };

declare 'RepeatedDataset',
    as ArrayRef[Dataset()];

coerce 'RepeatedDataset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AutomlTranslation::Dataset'->new($_) } @$_ ] };

declare 'MapStringDataset',
    as HashRef[Dataset()];

declare 'CreateModelRequest',
    as InstanceOf['Google::Cloud::Translation::V3::AutomlTranslation::CreateModelRequest'];

coerce 'CreateModelRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::AutomlTranslation::CreateModelRequest'->new($_) };

declare 'RepeatedCreateModelRequest',
    as ArrayRef[CreateModelRequest()];

coerce 'RepeatedCreateModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AutomlTranslation::CreateModelRequest'->new($_) } @$_ ] };

declare 'MapStringCreateModelRequest',
    as HashRef[CreateModelRequest()];

declare 'CreateModelMetadata',
    as InstanceOf['Google::Cloud::Translation::V3::AutomlTranslation::CreateModelMetadata'];

coerce 'CreateModelMetadata',
    from HashRef, via { 'Google::Cloud::Translation::V3::AutomlTranslation::CreateModelMetadata'->new($_) };

declare 'RepeatedCreateModelMetadata',
    as ArrayRef[CreateModelMetadata()];

coerce 'RepeatedCreateModelMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AutomlTranslation::CreateModelMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateModelMetadata',
    as HashRef[CreateModelMetadata()];

declare 'ListModelsRequest',
    as InstanceOf['Google::Cloud::Translation::V3::AutomlTranslation::ListModelsRequest'];

coerce 'ListModelsRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::AutomlTranslation::ListModelsRequest'->new($_) };

declare 'RepeatedListModelsRequest',
    as ArrayRef[ListModelsRequest()];

coerce 'RepeatedListModelsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AutomlTranslation::ListModelsRequest'->new($_) } @$_ ] };

declare 'MapStringListModelsRequest',
    as HashRef[ListModelsRequest()];

declare 'ListModelsResponse',
    as InstanceOf['Google::Cloud::Translation::V3::AutomlTranslation::ListModelsResponse'];

coerce 'ListModelsResponse',
    from HashRef, via { 'Google::Cloud::Translation::V3::AutomlTranslation::ListModelsResponse'->new($_) };

declare 'RepeatedListModelsResponse',
    as ArrayRef[ListModelsResponse()];

coerce 'RepeatedListModelsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AutomlTranslation::ListModelsResponse'->new($_) } @$_ ] };

declare 'MapStringListModelsResponse',
    as HashRef[ListModelsResponse()];

declare 'GetModelRequest',
    as InstanceOf['Google::Cloud::Translation::V3::AutomlTranslation::GetModelRequest'];

coerce 'GetModelRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::AutomlTranslation::GetModelRequest'->new($_) };

declare 'RepeatedGetModelRequest',
    as ArrayRef[GetModelRequest()];

coerce 'RepeatedGetModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AutomlTranslation::GetModelRequest'->new($_) } @$_ ] };

declare 'MapStringGetModelRequest',
    as HashRef[GetModelRequest()];

declare 'DeleteModelRequest',
    as InstanceOf['Google::Cloud::Translation::V3::AutomlTranslation::DeleteModelRequest'];

coerce 'DeleteModelRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::AutomlTranslation::DeleteModelRequest'->new($_) };

declare 'RepeatedDeleteModelRequest',
    as ArrayRef[DeleteModelRequest()];

coerce 'RepeatedDeleteModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AutomlTranslation::DeleteModelRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteModelRequest',
    as HashRef[DeleteModelRequest()];

declare 'DeleteModelMetadata',
    as InstanceOf['Google::Cloud::Translation::V3::AutomlTranslation::DeleteModelMetadata'];

coerce 'DeleteModelMetadata',
    from HashRef, via { 'Google::Cloud::Translation::V3::AutomlTranslation::DeleteModelMetadata'->new($_) };

declare 'RepeatedDeleteModelMetadata',
    as ArrayRef[DeleteModelMetadata()];

coerce 'RepeatedDeleteModelMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AutomlTranslation::DeleteModelMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteModelMetadata',
    as HashRef[DeleteModelMetadata()];

declare 'Model',
    as InstanceOf['Google::Cloud::Translation::V3::AutomlTranslation::Model'];

coerce 'Model',
    from HashRef, via { 'Google::Cloud::Translation::V3::AutomlTranslation::Model'->new($_) };

declare 'RepeatedModel',
    as ArrayRef[Model()];

coerce 'RepeatedModel',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::AutomlTranslation::Model'->new($_) } @$_ ] };

declare 'MapStringModel',
    as HashRef[Model()];

1;

__END__

=head1 NAME

Google::Cloud::Translation::V3::AutomlTranslation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
