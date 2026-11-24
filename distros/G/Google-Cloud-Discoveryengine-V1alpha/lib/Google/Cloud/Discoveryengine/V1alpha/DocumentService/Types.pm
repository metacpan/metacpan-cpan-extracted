package Google::Cloud::Discoveryengine::V1alpha::DocumentService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetDocumentRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::DocumentService::GetDocumentRequest'];

coerce 'GetDocumentRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::DocumentService::GetDocumentRequest'->new($_) };

declare 'RepeatedGetDocumentRequest',
    as ArrayRef[GetDocumentRequest()];

coerce 'RepeatedGetDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::DocumentService::GetDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringGetDocumentRequest',
    as HashRef[GetDocumentRequest()];

declare 'ListDocumentsRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::DocumentService::ListDocumentsRequest'];

coerce 'ListDocumentsRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::DocumentService::ListDocumentsRequest'->new($_) };

declare 'RepeatedListDocumentsRequest',
    as ArrayRef[ListDocumentsRequest()];

coerce 'RepeatedListDocumentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::DocumentService::ListDocumentsRequest'->new($_) } @$_ ] };

declare 'MapStringListDocumentsRequest',
    as HashRef[ListDocumentsRequest()];

declare 'ListDocumentsResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::DocumentService::ListDocumentsResponse'];

coerce 'ListDocumentsResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::DocumentService::ListDocumentsResponse'->new($_) };

declare 'RepeatedListDocumentsResponse',
    as ArrayRef[ListDocumentsResponse()];

coerce 'RepeatedListDocumentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::DocumentService::ListDocumentsResponse'->new($_) } @$_ ] };

declare 'MapStringListDocumentsResponse',
    as HashRef[ListDocumentsResponse()];

declare 'CreateDocumentRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::DocumentService::CreateDocumentRequest'];

coerce 'CreateDocumentRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::DocumentService::CreateDocumentRequest'->new($_) };

declare 'RepeatedCreateDocumentRequest',
    as ArrayRef[CreateDocumentRequest()];

coerce 'RepeatedCreateDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::DocumentService::CreateDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDocumentRequest',
    as HashRef[CreateDocumentRequest()];

declare 'UpdateDocumentRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::DocumentService::UpdateDocumentRequest'];

coerce 'UpdateDocumentRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::DocumentService::UpdateDocumentRequest'->new($_) };

declare 'RepeatedUpdateDocumentRequest',
    as ArrayRef[UpdateDocumentRequest()];

coerce 'RepeatedUpdateDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::DocumentService::UpdateDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDocumentRequest',
    as HashRef[UpdateDocumentRequest()];

declare 'DeleteDocumentRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::DocumentService::DeleteDocumentRequest'];

coerce 'DeleteDocumentRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::DocumentService::DeleteDocumentRequest'->new($_) };

declare 'RepeatedDeleteDocumentRequest',
    as ArrayRef[DeleteDocumentRequest()];

coerce 'RepeatedDeleteDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::DocumentService::DeleteDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDocumentRequest',
    as HashRef[DeleteDocumentRequest()];

declare 'GetProcessedDocumentRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::DocumentService::GetProcessedDocumentRequest'];

coerce 'GetProcessedDocumentRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::DocumentService::GetProcessedDocumentRequest'->new($_) };

declare 'RepeatedGetProcessedDocumentRequest',
    as ArrayRef[GetProcessedDocumentRequest()];

coerce 'RepeatedGetProcessedDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::DocumentService::GetProcessedDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringGetProcessedDocumentRequest',
    as HashRef[GetProcessedDocumentRequest()];

declare 'ProcessedDocumentType',
    as (Int | Str);

declare 'ProcessedDocumentFormat',
    as (Int | Str);

declare 'BatchGetDocumentsMetadataRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::DocumentService::BatchGetDocumentsMetadataRequest'];

coerce 'BatchGetDocumentsMetadataRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::DocumentService::BatchGetDocumentsMetadataRequest'->new($_) };

declare 'RepeatedBatchGetDocumentsMetadataRequest',
    as ArrayRef[BatchGetDocumentsMetadataRequest()];

coerce 'RepeatedBatchGetDocumentsMetadataRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::DocumentService::BatchGetDocumentsMetadataRequest'->new($_) } @$_ ] };

declare 'MapStringBatchGetDocumentsMetadataRequest',
    as HashRef[BatchGetDocumentsMetadataRequest()];

declare 'UrisMatcher',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::DocumentService::BatchGetDocumentsMetadataRequest::UrisMatcher'];

coerce 'UrisMatcher',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::DocumentService::BatchGetDocumentsMetadataRequest::UrisMatcher'->new($_) };

declare 'RepeatedUrisMatcher',
    as ArrayRef[UrisMatcher()];

coerce 'RepeatedUrisMatcher',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::DocumentService::BatchGetDocumentsMetadataRequest::UrisMatcher'->new($_) } @$_ ] };

declare 'MapStringUrisMatcher',
    as HashRef[UrisMatcher()];

declare 'Matcher',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::DocumentService::BatchGetDocumentsMetadataRequest::Matcher'];

coerce 'Matcher',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::DocumentService::BatchGetDocumentsMetadataRequest::Matcher'->new($_) };

declare 'RepeatedMatcher',
    as ArrayRef[Matcher()];

coerce 'RepeatedMatcher',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::DocumentService::BatchGetDocumentsMetadataRequest::Matcher'->new($_) } @$_ ] };

declare 'MapStringMatcher',
    as HashRef[Matcher()];

declare 'BatchGetDocumentsMetadataResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::DocumentService::BatchGetDocumentsMetadataResponse'];

coerce 'BatchGetDocumentsMetadataResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::DocumentService::BatchGetDocumentsMetadataResponse'->new($_) };

declare 'RepeatedBatchGetDocumentsMetadataResponse',
    as ArrayRef[BatchGetDocumentsMetadataResponse()];

coerce 'RepeatedBatchGetDocumentsMetadataResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::DocumentService::BatchGetDocumentsMetadataResponse'->new($_) } @$_ ] };

declare 'MapStringBatchGetDocumentsMetadataResponse',
    as HashRef[BatchGetDocumentsMetadataResponse()];

declare 'State',
    as (Int | Str);

declare 'DocumentMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::DocumentService::BatchGetDocumentsMetadataResponse::DocumentMetadata'];

coerce 'DocumentMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::DocumentService::BatchGetDocumentsMetadataResponse::DocumentMetadata'->new($_) };

declare 'RepeatedDocumentMetadata',
    as ArrayRef[DocumentMetadata()];

coerce 'RepeatedDocumentMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::DocumentService::BatchGetDocumentsMetadataResponse::DocumentMetadata'->new($_) } @$_ ] };

declare 'MapStringDocumentMetadata',
    as HashRef[DocumentMetadata()];

declare 'MatcherValue',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::DocumentService::BatchGetDocumentsMetadataResponse::DocumentMetadata::MatcherValue'];

coerce 'MatcherValue',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::DocumentService::BatchGetDocumentsMetadataResponse::DocumentMetadata::MatcherValue'->new($_) };

declare 'RepeatedMatcherValue',
    as ArrayRef[MatcherValue()];

coerce 'RepeatedMatcherValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::DocumentService::BatchGetDocumentsMetadataResponse::DocumentMetadata::MatcherValue'->new($_) } @$_ ] };

declare 'MapStringMatcherValue',
    as HashRef[MatcherValue()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::DocumentService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
