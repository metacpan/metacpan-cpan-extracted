package Google::Cloud::Documentai::V1beta3::DocumentService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DatasetSplitType',
    as (Int | Str);

declare 'DocumentLabelingState',
    as (Int | Str);

declare 'UpdateDatasetRequest',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentService::UpdateDatasetRequest'];

coerce 'UpdateDatasetRequest',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentService::UpdateDatasetRequest'->new($_) };

declare 'RepeatedUpdateDatasetRequest',
    as ArrayRef[UpdateDatasetRequest()];

coerce 'RepeatedUpdateDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentService::UpdateDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDatasetRequest',
    as HashRef[UpdateDatasetRequest()];

declare 'UpdateDatasetOperationMetadata',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentService::UpdateDatasetOperationMetadata'];

coerce 'UpdateDatasetOperationMetadata',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentService::UpdateDatasetOperationMetadata'->new($_) };

declare 'RepeatedUpdateDatasetOperationMetadata',
    as ArrayRef[UpdateDatasetOperationMetadata()];

coerce 'RepeatedUpdateDatasetOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentService::UpdateDatasetOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringUpdateDatasetOperationMetadata',
    as HashRef[UpdateDatasetOperationMetadata()];

declare 'ImportDocumentsRequest',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentService::ImportDocumentsRequest'];

coerce 'ImportDocumentsRequest',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentService::ImportDocumentsRequest'->new($_) };

declare 'RepeatedImportDocumentsRequest',
    as ArrayRef[ImportDocumentsRequest()];

coerce 'RepeatedImportDocumentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentService::ImportDocumentsRequest'->new($_) } @$_ ] };

declare 'MapStringImportDocumentsRequest',
    as HashRef[ImportDocumentsRequest()];

declare 'BatchDocumentsImportConfig',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentService::ImportDocumentsRequest::BatchDocumentsImportConfig'];

coerce 'BatchDocumentsImportConfig',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentService::ImportDocumentsRequest::BatchDocumentsImportConfig'->new($_) };

declare 'RepeatedBatchDocumentsImportConfig',
    as ArrayRef[BatchDocumentsImportConfig()];

coerce 'RepeatedBatchDocumentsImportConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentService::ImportDocumentsRequest::BatchDocumentsImportConfig'->new($_) } @$_ ] };

declare 'MapStringBatchDocumentsImportConfig',
    as HashRef[BatchDocumentsImportConfig()];

declare 'AutoSplitConfig',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentService::ImportDocumentsRequest::BatchDocumentsImportConfig::AutoSplitConfig'];

coerce 'AutoSplitConfig',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentService::ImportDocumentsRequest::BatchDocumentsImportConfig::AutoSplitConfig'->new($_) };

declare 'RepeatedAutoSplitConfig',
    as ArrayRef[AutoSplitConfig()];

coerce 'RepeatedAutoSplitConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentService::ImportDocumentsRequest::BatchDocumentsImportConfig::AutoSplitConfig'->new($_) } @$_ ] };

declare 'MapStringAutoSplitConfig',
    as HashRef[AutoSplitConfig()];

declare 'ImportDocumentsResponse',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentService::ImportDocumentsResponse'];

coerce 'ImportDocumentsResponse',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentService::ImportDocumentsResponse'->new($_) };

declare 'RepeatedImportDocumentsResponse',
    as ArrayRef[ImportDocumentsResponse()];

coerce 'RepeatedImportDocumentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentService::ImportDocumentsResponse'->new($_) } @$_ ] };

declare 'MapStringImportDocumentsResponse',
    as HashRef[ImportDocumentsResponse()];

declare 'ImportDocumentsMetadata',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentService::ImportDocumentsMetadata'];

coerce 'ImportDocumentsMetadata',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentService::ImportDocumentsMetadata'->new($_) };

declare 'RepeatedImportDocumentsMetadata',
    as ArrayRef[ImportDocumentsMetadata()];

coerce 'RepeatedImportDocumentsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentService::ImportDocumentsMetadata'->new($_) } @$_ ] };

declare 'MapStringImportDocumentsMetadata',
    as HashRef[ImportDocumentsMetadata()];

declare 'IndividualImportStatus',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentService::ImportDocumentsMetadata::IndividualImportStatus'];

coerce 'IndividualImportStatus',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentService::ImportDocumentsMetadata::IndividualImportStatus'->new($_) };

declare 'RepeatedIndividualImportStatus',
    as ArrayRef[IndividualImportStatus()];

coerce 'RepeatedIndividualImportStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentService::ImportDocumentsMetadata::IndividualImportStatus'->new($_) } @$_ ] };

declare 'MapStringIndividualImportStatus',
    as HashRef[IndividualImportStatus()];

declare 'ImportConfigValidationResult',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentService::ImportDocumentsMetadata::ImportConfigValidationResult'];

coerce 'ImportConfigValidationResult',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentService::ImportDocumentsMetadata::ImportConfigValidationResult'->new($_) };

declare 'RepeatedImportConfigValidationResult',
    as ArrayRef[ImportConfigValidationResult()];

coerce 'RepeatedImportConfigValidationResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentService::ImportDocumentsMetadata::ImportConfigValidationResult'->new($_) } @$_ ] };

declare 'MapStringImportConfigValidationResult',
    as HashRef[ImportConfigValidationResult()];

declare 'GetDocumentRequest',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentService::GetDocumentRequest'];

coerce 'GetDocumentRequest',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentService::GetDocumentRequest'->new($_) };

declare 'RepeatedGetDocumentRequest',
    as ArrayRef[GetDocumentRequest()];

coerce 'RepeatedGetDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentService::GetDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringGetDocumentRequest',
    as HashRef[GetDocumentRequest()];

declare 'GetDocumentResponse',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentService::GetDocumentResponse'];

coerce 'GetDocumentResponse',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentService::GetDocumentResponse'->new($_) };

declare 'RepeatedGetDocumentResponse',
    as ArrayRef[GetDocumentResponse()];

coerce 'RepeatedGetDocumentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentService::GetDocumentResponse'->new($_) } @$_ ] };

declare 'MapStringGetDocumentResponse',
    as HashRef[GetDocumentResponse()];

declare 'ListDocumentsRequest',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentService::ListDocumentsRequest'];

coerce 'ListDocumentsRequest',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentService::ListDocumentsRequest'->new($_) };

declare 'RepeatedListDocumentsRequest',
    as ArrayRef[ListDocumentsRequest()];

coerce 'RepeatedListDocumentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentService::ListDocumentsRequest'->new($_) } @$_ ] };

declare 'MapStringListDocumentsRequest',
    as HashRef[ListDocumentsRequest()];

declare 'ListDocumentsResponse',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentService::ListDocumentsResponse'];

coerce 'ListDocumentsResponse',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentService::ListDocumentsResponse'->new($_) };

declare 'RepeatedListDocumentsResponse',
    as ArrayRef[ListDocumentsResponse()];

coerce 'RepeatedListDocumentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentService::ListDocumentsResponse'->new($_) } @$_ ] };

declare 'MapStringListDocumentsResponse',
    as HashRef[ListDocumentsResponse()];

declare 'BatchDeleteDocumentsRequest',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentService::BatchDeleteDocumentsRequest'];

coerce 'BatchDeleteDocumentsRequest',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentService::BatchDeleteDocumentsRequest'->new($_) };

declare 'RepeatedBatchDeleteDocumentsRequest',
    as ArrayRef[BatchDeleteDocumentsRequest()];

coerce 'RepeatedBatchDeleteDocumentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentService::BatchDeleteDocumentsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchDeleteDocumentsRequest',
    as HashRef[BatchDeleteDocumentsRequest()];

declare 'BatchDeleteDocumentsResponse',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentService::BatchDeleteDocumentsResponse'];

coerce 'BatchDeleteDocumentsResponse',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentService::BatchDeleteDocumentsResponse'->new($_) };

declare 'RepeatedBatchDeleteDocumentsResponse',
    as ArrayRef[BatchDeleteDocumentsResponse()];

coerce 'RepeatedBatchDeleteDocumentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentService::BatchDeleteDocumentsResponse'->new($_) } @$_ ] };

declare 'MapStringBatchDeleteDocumentsResponse',
    as HashRef[BatchDeleteDocumentsResponse()];

declare 'BatchDeleteDocumentsMetadata',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentService::BatchDeleteDocumentsMetadata'];

coerce 'BatchDeleteDocumentsMetadata',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentService::BatchDeleteDocumentsMetadata'->new($_) };

declare 'RepeatedBatchDeleteDocumentsMetadata',
    as ArrayRef[BatchDeleteDocumentsMetadata()];

coerce 'RepeatedBatchDeleteDocumentsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentService::BatchDeleteDocumentsMetadata'->new($_) } @$_ ] };

declare 'MapStringBatchDeleteDocumentsMetadata',
    as HashRef[BatchDeleteDocumentsMetadata()];

declare 'IndividualBatchDeleteStatus',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentService::BatchDeleteDocumentsMetadata::IndividualBatchDeleteStatus'];

coerce 'IndividualBatchDeleteStatus',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentService::BatchDeleteDocumentsMetadata::IndividualBatchDeleteStatus'->new($_) };

declare 'RepeatedIndividualBatchDeleteStatus',
    as ArrayRef[IndividualBatchDeleteStatus()];

coerce 'RepeatedIndividualBatchDeleteStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentService::BatchDeleteDocumentsMetadata::IndividualBatchDeleteStatus'->new($_) } @$_ ] };

declare 'MapStringIndividualBatchDeleteStatus',
    as HashRef[IndividualBatchDeleteStatus()];

declare 'GetDatasetSchemaRequest',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentService::GetDatasetSchemaRequest'];

coerce 'GetDatasetSchemaRequest',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentService::GetDatasetSchemaRequest'->new($_) };

declare 'RepeatedGetDatasetSchemaRequest',
    as ArrayRef[GetDatasetSchemaRequest()];

coerce 'RepeatedGetDatasetSchemaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentService::GetDatasetSchemaRequest'->new($_) } @$_ ] };

declare 'MapStringGetDatasetSchemaRequest',
    as HashRef[GetDatasetSchemaRequest()];

declare 'UpdateDatasetSchemaRequest',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentService::UpdateDatasetSchemaRequest'];

coerce 'UpdateDatasetSchemaRequest',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentService::UpdateDatasetSchemaRequest'->new($_) };

declare 'RepeatedUpdateDatasetSchemaRequest',
    as ArrayRef[UpdateDatasetSchemaRequest()];

coerce 'RepeatedUpdateDatasetSchemaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentService::UpdateDatasetSchemaRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDatasetSchemaRequest',
    as HashRef[UpdateDatasetSchemaRequest()];

declare 'DocumentPageRange',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentService::DocumentPageRange'];

coerce 'DocumentPageRange',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentService::DocumentPageRange'->new($_) };

declare 'RepeatedDocumentPageRange',
    as ArrayRef[DocumentPageRange()];

coerce 'RepeatedDocumentPageRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentService::DocumentPageRange'->new($_) } @$_ ] };

declare 'MapStringDocumentPageRange',
    as HashRef[DocumentPageRange()];

declare 'DocumentMetadata',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::DocumentService::DocumentMetadata'];

coerce 'DocumentMetadata',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::DocumentService::DocumentMetadata'->new($_) };

declare 'RepeatedDocumentMetadata',
    as ArrayRef[DocumentMetadata()];

coerce 'RepeatedDocumentMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::DocumentService::DocumentMetadata'->new($_) } @$_ ] };

declare 'MapStringDocumentMetadata',
    as HashRef[DocumentMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Documentai::V1beta3::DocumentService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
