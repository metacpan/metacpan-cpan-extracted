package Google::Cloud::Dialogflow::V2beta1::Document::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Document',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Document::Document'];

coerce 'Document',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Document::Document'->new($_) };

declare 'RepeatedDocument',
    as ArrayRef[Document()];

coerce 'RepeatedDocument',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Document::Document'->new($_) } @$_ ] };

declare 'MapStringDocument',
    as HashRef[Document()];

declare 'KnowledgeType',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'ReloadStatus',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Document::Document::ReloadStatus'];

coerce 'ReloadStatus',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Document::Document::ReloadStatus'->new($_) };

declare 'RepeatedReloadStatus',
    as ArrayRef[ReloadStatus()];

coerce 'RepeatedReloadStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Document::Document::ReloadStatus'->new($_) } @$_ ] };

declare 'MapStringReloadStatus',
    as HashRef[ReloadStatus()];

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Document::Document::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Document::Document::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Document::Document::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'GetDocumentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Document::GetDocumentRequest'];

coerce 'GetDocumentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Document::GetDocumentRequest'->new($_) };

declare 'RepeatedGetDocumentRequest',
    as ArrayRef[GetDocumentRequest()];

coerce 'RepeatedGetDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Document::GetDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringGetDocumentRequest',
    as HashRef[GetDocumentRequest()];

declare 'ListDocumentsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Document::ListDocumentsRequest'];

coerce 'ListDocumentsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Document::ListDocumentsRequest'->new($_) };

declare 'RepeatedListDocumentsRequest',
    as ArrayRef[ListDocumentsRequest()];

coerce 'RepeatedListDocumentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Document::ListDocumentsRequest'->new($_) } @$_ ] };

declare 'MapStringListDocumentsRequest',
    as HashRef[ListDocumentsRequest()];

declare 'ListDocumentsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Document::ListDocumentsResponse'];

coerce 'ListDocumentsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Document::ListDocumentsResponse'->new($_) };

declare 'RepeatedListDocumentsResponse',
    as ArrayRef[ListDocumentsResponse()];

coerce 'RepeatedListDocumentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Document::ListDocumentsResponse'->new($_) } @$_ ] };

declare 'MapStringListDocumentsResponse',
    as HashRef[ListDocumentsResponse()];

declare 'CreateDocumentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Document::CreateDocumentRequest'];

coerce 'CreateDocumentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Document::CreateDocumentRequest'->new($_) };

declare 'RepeatedCreateDocumentRequest',
    as ArrayRef[CreateDocumentRequest()];

coerce 'RepeatedCreateDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Document::CreateDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDocumentRequest',
    as HashRef[CreateDocumentRequest()];

declare 'ImportDocumentsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Document::ImportDocumentsRequest'];

coerce 'ImportDocumentsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Document::ImportDocumentsRequest'->new($_) };

declare 'RepeatedImportDocumentsRequest',
    as ArrayRef[ImportDocumentsRequest()];

coerce 'RepeatedImportDocumentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Document::ImportDocumentsRequest'->new($_) } @$_ ] };

declare 'MapStringImportDocumentsRequest',
    as HashRef[ImportDocumentsRequest()];

declare 'ImportDocumentTemplate',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Document::ImportDocumentTemplate'];

coerce 'ImportDocumentTemplate',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Document::ImportDocumentTemplate'->new($_) };

declare 'RepeatedImportDocumentTemplate',
    as ArrayRef[ImportDocumentTemplate()];

coerce 'RepeatedImportDocumentTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Document::ImportDocumentTemplate'->new($_) } @$_ ] };

declare 'MapStringImportDocumentTemplate',
    as HashRef[ImportDocumentTemplate()];

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Document::ImportDocumentTemplate::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Document::ImportDocumentTemplate::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Document::ImportDocumentTemplate::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'ImportDocumentsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Document::ImportDocumentsResponse'];

coerce 'ImportDocumentsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Document::ImportDocumentsResponse'->new($_) };

declare 'RepeatedImportDocumentsResponse',
    as ArrayRef[ImportDocumentsResponse()];

coerce 'RepeatedImportDocumentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Document::ImportDocumentsResponse'->new($_) } @$_ ] };

declare 'MapStringImportDocumentsResponse',
    as HashRef[ImportDocumentsResponse()];

declare 'DeleteDocumentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Document::DeleteDocumentRequest'];

coerce 'DeleteDocumentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Document::DeleteDocumentRequest'->new($_) };

declare 'RepeatedDeleteDocumentRequest',
    as ArrayRef[DeleteDocumentRequest()];

coerce 'RepeatedDeleteDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Document::DeleteDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDocumentRequest',
    as HashRef[DeleteDocumentRequest()];

declare 'UpdateDocumentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Document::UpdateDocumentRequest'];

coerce 'UpdateDocumentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Document::UpdateDocumentRequest'->new($_) };

declare 'RepeatedUpdateDocumentRequest',
    as ArrayRef[UpdateDocumentRequest()];

coerce 'RepeatedUpdateDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Document::UpdateDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDocumentRequest',
    as HashRef[UpdateDocumentRequest()];

declare 'ExportOperationMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Document::ExportOperationMetadata'];

coerce 'ExportOperationMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Document::ExportOperationMetadata'->new($_) };

declare 'RepeatedExportOperationMetadata',
    as ArrayRef[ExportOperationMetadata()];

coerce 'RepeatedExportOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Document::ExportOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringExportOperationMetadata',
    as HashRef[ExportOperationMetadata()];

declare 'KnowledgeOperationMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Document::KnowledgeOperationMetadata'];

coerce 'KnowledgeOperationMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Document::KnowledgeOperationMetadata'->new($_) };

declare 'RepeatedKnowledgeOperationMetadata',
    as ArrayRef[KnowledgeOperationMetadata()];

coerce 'RepeatedKnowledgeOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Document::KnowledgeOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringKnowledgeOperationMetadata',
    as HashRef[KnowledgeOperationMetadata()];

declare 'State',
    as (Int | Str);

declare 'ReloadDocumentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Document::ReloadDocumentRequest'];

coerce 'ReloadDocumentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Document::ReloadDocumentRequest'->new($_) };

declare 'RepeatedReloadDocumentRequest',
    as ArrayRef[ReloadDocumentRequest()];

coerce 'RepeatedReloadDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Document::ReloadDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringReloadDocumentRequest',
    as HashRef[ReloadDocumentRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::Document::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
