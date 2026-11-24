package Google::Developers::Knowledge::V1alpha::Developerknowledge::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DocumentView',
    as (Int | Str);

declare 'Document',
    as InstanceOf['Google::Developers::Knowledge::V1alpha::Developerknowledge::Document'];

coerce 'Document',
    from HashRef, via { 'Google::Developers::Knowledge::V1alpha::Developerknowledge::Document'->new($_) };

declare 'RepeatedDocument',
    as ArrayRef[Document()];

coerce 'RepeatedDocument',
    from ArrayRef[HashRef], via { [ map { 'Google::Developers::Knowledge::V1alpha::Developerknowledge::Document'->new($_) } @$_ ] };

declare 'MapStringDocument',
    as HashRef[Document()];

declare 'SearchDocumentChunksRequest',
    as InstanceOf['Google::Developers::Knowledge::V1alpha::Developerknowledge::SearchDocumentChunksRequest'];

coerce 'SearchDocumentChunksRequest',
    from HashRef, via { 'Google::Developers::Knowledge::V1alpha::Developerknowledge::SearchDocumentChunksRequest'->new($_) };

declare 'RepeatedSearchDocumentChunksRequest',
    as ArrayRef[SearchDocumentChunksRequest()];

coerce 'RepeatedSearchDocumentChunksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Developers::Knowledge::V1alpha::Developerknowledge::SearchDocumentChunksRequest'->new($_) } @$_ ] };

declare 'MapStringSearchDocumentChunksRequest',
    as HashRef[SearchDocumentChunksRequest()];

declare 'SearchDocumentChunksResponse',
    as InstanceOf['Google::Developers::Knowledge::V1alpha::Developerknowledge::SearchDocumentChunksResponse'];

coerce 'SearchDocumentChunksResponse',
    from HashRef, via { 'Google::Developers::Knowledge::V1alpha::Developerknowledge::SearchDocumentChunksResponse'->new($_) };

declare 'RepeatedSearchDocumentChunksResponse',
    as ArrayRef[SearchDocumentChunksResponse()];

coerce 'RepeatedSearchDocumentChunksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Developers::Knowledge::V1alpha::Developerknowledge::SearchDocumentChunksResponse'->new($_) } @$_ ] };

declare 'MapStringSearchDocumentChunksResponse',
    as HashRef[SearchDocumentChunksResponse()];

declare 'GetDocumentRequest',
    as InstanceOf['Google::Developers::Knowledge::V1alpha::Developerknowledge::GetDocumentRequest'];

coerce 'GetDocumentRequest',
    from HashRef, via { 'Google::Developers::Knowledge::V1alpha::Developerknowledge::GetDocumentRequest'->new($_) };

declare 'RepeatedGetDocumentRequest',
    as ArrayRef[GetDocumentRequest()];

coerce 'RepeatedGetDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Developers::Knowledge::V1alpha::Developerknowledge::GetDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringGetDocumentRequest',
    as HashRef[GetDocumentRequest()];

declare 'BatchGetDocumentsRequest',
    as InstanceOf['Google::Developers::Knowledge::V1alpha::Developerknowledge::BatchGetDocumentsRequest'];

coerce 'BatchGetDocumentsRequest',
    from HashRef, via { 'Google::Developers::Knowledge::V1alpha::Developerknowledge::BatchGetDocumentsRequest'->new($_) };

declare 'RepeatedBatchGetDocumentsRequest',
    as ArrayRef[BatchGetDocumentsRequest()];

coerce 'RepeatedBatchGetDocumentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Developers::Knowledge::V1alpha::Developerknowledge::BatchGetDocumentsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchGetDocumentsRequest',
    as HashRef[BatchGetDocumentsRequest()];

declare 'BatchGetDocumentsResponse',
    as InstanceOf['Google::Developers::Knowledge::V1alpha::Developerknowledge::BatchGetDocumentsResponse'];

coerce 'BatchGetDocumentsResponse',
    from HashRef, via { 'Google::Developers::Knowledge::V1alpha::Developerknowledge::BatchGetDocumentsResponse'->new($_) };

declare 'RepeatedBatchGetDocumentsResponse',
    as ArrayRef[BatchGetDocumentsResponse()];

coerce 'RepeatedBatchGetDocumentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Developers::Knowledge::V1alpha::Developerknowledge::BatchGetDocumentsResponse'->new($_) } @$_ ] };

declare 'MapStringBatchGetDocumentsResponse',
    as HashRef[BatchGetDocumentsResponse()];

declare 'AnswerQueryRequest',
    as InstanceOf['Google::Developers::Knowledge::V1alpha::Developerknowledge::AnswerQueryRequest'];

coerce 'AnswerQueryRequest',
    from HashRef, via { 'Google::Developers::Knowledge::V1alpha::Developerknowledge::AnswerQueryRequest'->new($_) };

declare 'RepeatedAnswerQueryRequest',
    as ArrayRef[AnswerQueryRequest()];

coerce 'RepeatedAnswerQueryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Developers::Knowledge::V1alpha::Developerknowledge::AnswerQueryRequest'->new($_) } @$_ ] };

declare 'MapStringAnswerQueryRequest',
    as HashRef[AnswerQueryRequest()];

declare 'AnswerQueryResponse',
    as InstanceOf['Google::Developers::Knowledge::V1alpha::Developerknowledge::AnswerQueryResponse'];

coerce 'AnswerQueryResponse',
    from HashRef, via { 'Google::Developers::Knowledge::V1alpha::Developerknowledge::AnswerQueryResponse'->new($_) };

declare 'RepeatedAnswerQueryResponse',
    as ArrayRef[AnswerQueryResponse()];

coerce 'RepeatedAnswerQueryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Developers::Knowledge::V1alpha::Developerknowledge::AnswerQueryResponse'->new($_) } @$_ ] };

declare 'MapStringAnswerQueryResponse',
    as HashRef[AnswerQueryResponse()];

declare 'Answer',
    as InstanceOf['Google::Developers::Knowledge::V1alpha::Developerknowledge::Answer'];

coerce 'Answer',
    from HashRef, via { 'Google::Developers::Knowledge::V1alpha::Developerknowledge::Answer'->new($_) };

declare 'RepeatedAnswer',
    as ArrayRef[Answer()];

coerce 'RepeatedAnswer',
    from ArrayRef[HashRef], via { [ map { 'Google::Developers::Knowledge::V1alpha::Developerknowledge::Answer'->new($_) } @$_ ] };

declare 'MapStringAnswer',
    as HashRef[Answer()];

declare 'AnswerCitation',
    as InstanceOf['Google::Developers::Knowledge::V1alpha::Developerknowledge::Answer::AnswerCitation'];

coerce 'AnswerCitation',
    from HashRef, via { 'Google::Developers::Knowledge::V1alpha::Developerknowledge::Answer::AnswerCitation'->new($_) };

declare 'RepeatedAnswerCitation',
    as ArrayRef[AnswerCitation()];

coerce 'RepeatedAnswerCitation',
    from ArrayRef[HashRef], via { [ map { 'Google::Developers::Knowledge::V1alpha::Developerknowledge::Answer::AnswerCitation'->new($_) } @$_ ] };

declare 'MapStringAnswerCitation',
    as HashRef[AnswerCitation()];

declare 'CitationSource',
    as InstanceOf['Google::Developers::Knowledge::V1alpha::Developerknowledge::Answer::CitationSource'];

coerce 'CitationSource',
    from HashRef, via { 'Google::Developers::Knowledge::V1alpha::Developerknowledge::Answer::CitationSource'->new($_) };

declare 'RepeatedCitationSource',
    as ArrayRef[CitationSource()];

coerce 'RepeatedCitationSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Developers::Knowledge::V1alpha::Developerknowledge::Answer::CitationSource'->new($_) } @$_ ] };

declare 'MapStringCitationSource',
    as HashRef[CitationSource()];

declare 'AnswerReference',
    as InstanceOf['Google::Developers::Knowledge::V1alpha::Developerknowledge::Answer::AnswerReference'];

coerce 'AnswerReference',
    from HashRef, via { 'Google::Developers::Knowledge::V1alpha::Developerknowledge::Answer::AnswerReference'->new($_) };

declare 'RepeatedAnswerReference',
    as ArrayRef[AnswerReference()];

coerce 'RepeatedAnswerReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Developers::Knowledge::V1alpha::Developerknowledge::Answer::AnswerReference'->new($_) } @$_ ] };

declare 'MapStringAnswerReference',
    as HashRef[AnswerReference()];

declare 'DocumentReference',
    as InstanceOf['Google::Developers::Knowledge::V1alpha::Developerknowledge::Answer::DocumentReference'];

coerce 'DocumentReference',
    from HashRef, via { 'Google::Developers::Knowledge::V1alpha::Developerknowledge::Answer::DocumentReference'->new($_) };

declare 'RepeatedDocumentReference',
    as ArrayRef[DocumentReference()];

coerce 'RepeatedDocumentReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Developers::Knowledge::V1alpha::Developerknowledge::Answer::DocumentReference'->new($_) } @$_ ] };

declare 'MapStringDocumentReference',
    as HashRef[DocumentReference()];

declare 'DocumentChunk',
    as InstanceOf['Google::Developers::Knowledge::V1alpha::Developerknowledge::DocumentChunk'];

coerce 'DocumentChunk',
    from HashRef, via { 'Google::Developers::Knowledge::V1alpha::Developerknowledge::DocumentChunk'->new($_) };

declare 'RepeatedDocumentChunk',
    as ArrayRef[DocumentChunk()];

coerce 'RepeatedDocumentChunk',
    from ArrayRef[HashRef], via { [ map { 'Google::Developers::Knowledge::V1alpha::Developerknowledge::DocumentChunk'->new($_) } @$_ ] };

declare 'MapStringDocumentChunk',
    as HashRef[DocumentChunk()];

1;

__END__

=head1 NAME

Google::Developers::Knowledge::V1alpha::Developerknowledge::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
