package Google::Ai::Generativelanguage::V1beta::RetrieverService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateCorpusRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::RetrieverService::CreateCorpusRequest'];

coerce 'CreateCorpusRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::CreateCorpusRequest'->new($_) };

declare 'RepeatedCreateCorpusRequest',
    as ArrayRef[CreateCorpusRequest()];

coerce 'RepeatedCreateCorpusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::CreateCorpusRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCorpusRequest',
    as HashRef[CreateCorpusRequest()];

declare 'GetCorpusRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::RetrieverService::GetCorpusRequest'];

coerce 'GetCorpusRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::GetCorpusRequest'->new($_) };

declare 'RepeatedGetCorpusRequest',
    as ArrayRef[GetCorpusRequest()];

coerce 'RepeatedGetCorpusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::GetCorpusRequest'->new($_) } @$_ ] };

declare 'MapStringGetCorpusRequest',
    as HashRef[GetCorpusRequest()];

declare 'UpdateCorpusRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::RetrieverService::UpdateCorpusRequest'];

coerce 'UpdateCorpusRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::UpdateCorpusRequest'->new($_) };

declare 'RepeatedUpdateCorpusRequest',
    as ArrayRef[UpdateCorpusRequest()];

coerce 'RepeatedUpdateCorpusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::UpdateCorpusRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCorpusRequest',
    as HashRef[UpdateCorpusRequest()];

declare 'DeleteCorpusRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::RetrieverService::DeleteCorpusRequest'];

coerce 'DeleteCorpusRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::DeleteCorpusRequest'->new($_) };

declare 'RepeatedDeleteCorpusRequest',
    as ArrayRef[DeleteCorpusRequest()];

coerce 'RepeatedDeleteCorpusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::DeleteCorpusRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCorpusRequest',
    as HashRef[DeleteCorpusRequest()];

declare 'ListCorporaRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::RetrieverService::ListCorporaRequest'];

coerce 'ListCorporaRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::ListCorporaRequest'->new($_) };

declare 'RepeatedListCorporaRequest',
    as ArrayRef[ListCorporaRequest()];

coerce 'RepeatedListCorporaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::ListCorporaRequest'->new($_) } @$_ ] };

declare 'MapStringListCorporaRequest',
    as HashRef[ListCorporaRequest()];

declare 'ListCorporaResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::RetrieverService::ListCorporaResponse'];

coerce 'ListCorporaResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::ListCorporaResponse'->new($_) };

declare 'RepeatedListCorporaResponse',
    as ArrayRef[ListCorporaResponse()];

coerce 'RepeatedListCorporaResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::ListCorporaResponse'->new($_) } @$_ ] };

declare 'MapStringListCorporaResponse',
    as HashRef[ListCorporaResponse()];

declare 'QueryCorpusRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::RetrieverService::QueryCorpusRequest'];

coerce 'QueryCorpusRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::QueryCorpusRequest'->new($_) };

declare 'RepeatedQueryCorpusRequest',
    as ArrayRef[QueryCorpusRequest()];

coerce 'RepeatedQueryCorpusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::QueryCorpusRequest'->new($_) } @$_ ] };

declare 'MapStringQueryCorpusRequest',
    as HashRef[QueryCorpusRequest()];

declare 'QueryCorpusResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::RetrieverService::QueryCorpusResponse'];

coerce 'QueryCorpusResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::QueryCorpusResponse'->new($_) };

declare 'RepeatedQueryCorpusResponse',
    as ArrayRef[QueryCorpusResponse()];

coerce 'RepeatedQueryCorpusResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::QueryCorpusResponse'->new($_) } @$_ ] };

declare 'MapStringQueryCorpusResponse',
    as HashRef[QueryCorpusResponse()];

declare 'RelevantChunk',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::RetrieverService::RelevantChunk'];

coerce 'RelevantChunk',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::RelevantChunk'->new($_) };

declare 'RepeatedRelevantChunk',
    as ArrayRef[RelevantChunk()];

coerce 'RepeatedRelevantChunk',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::RelevantChunk'->new($_) } @$_ ] };

declare 'MapStringRelevantChunk',
    as HashRef[RelevantChunk()];

declare 'CreateDocumentRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::RetrieverService::CreateDocumentRequest'];

coerce 'CreateDocumentRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::CreateDocumentRequest'->new($_) };

declare 'RepeatedCreateDocumentRequest',
    as ArrayRef[CreateDocumentRequest()];

coerce 'RepeatedCreateDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::CreateDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDocumentRequest',
    as HashRef[CreateDocumentRequest()];

declare 'GetDocumentRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::RetrieverService::GetDocumentRequest'];

coerce 'GetDocumentRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::GetDocumentRequest'->new($_) };

declare 'RepeatedGetDocumentRequest',
    as ArrayRef[GetDocumentRequest()];

coerce 'RepeatedGetDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::GetDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringGetDocumentRequest',
    as HashRef[GetDocumentRequest()];

declare 'UpdateDocumentRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::RetrieverService::UpdateDocumentRequest'];

coerce 'UpdateDocumentRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::UpdateDocumentRequest'->new($_) };

declare 'RepeatedUpdateDocumentRequest',
    as ArrayRef[UpdateDocumentRequest()];

coerce 'RepeatedUpdateDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::UpdateDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDocumentRequest',
    as HashRef[UpdateDocumentRequest()];

declare 'DeleteDocumentRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::RetrieverService::DeleteDocumentRequest'];

coerce 'DeleteDocumentRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::DeleteDocumentRequest'->new($_) };

declare 'RepeatedDeleteDocumentRequest',
    as ArrayRef[DeleteDocumentRequest()];

coerce 'RepeatedDeleteDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::DeleteDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDocumentRequest',
    as HashRef[DeleteDocumentRequest()];

declare 'ListDocumentsRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::RetrieverService::ListDocumentsRequest'];

coerce 'ListDocumentsRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::ListDocumentsRequest'->new($_) };

declare 'RepeatedListDocumentsRequest',
    as ArrayRef[ListDocumentsRequest()];

coerce 'RepeatedListDocumentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::ListDocumentsRequest'->new($_) } @$_ ] };

declare 'MapStringListDocumentsRequest',
    as HashRef[ListDocumentsRequest()];

declare 'ListDocumentsResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::RetrieverService::ListDocumentsResponse'];

coerce 'ListDocumentsResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::ListDocumentsResponse'->new($_) };

declare 'RepeatedListDocumentsResponse',
    as ArrayRef[ListDocumentsResponse()];

coerce 'RepeatedListDocumentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::ListDocumentsResponse'->new($_) } @$_ ] };

declare 'MapStringListDocumentsResponse',
    as HashRef[ListDocumentsResponse()];

declare 'QueryDocumentRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::RetrieverService::QueryDocumentRequest'];

coerce 'QueryDocumentRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::QueryDocumentRequest'->new($_) };

declare 'RepeatedQueryDocumentRequest',
    as ArrayRef[QueryDocumentRequest()];

coerce 'RepeatedQueryDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::QueryDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringQueryDocumentRequest',
    as HashRef[QueryDocumentRequest()];

declare 'QueryDocumentResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::RetrieverService::QueryDocumentResponse'];

coerce 'QueryDocumentResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::QueryDocumentResponse'->new($_) };

declare 'RepeatedQueryDocumentResponse',
    as ArrayRef[QueryDocumentResponse()];

coerce 'RepeatedQueryDocumentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::QueryDocumentResponse'->new($_) } @$_ ] };

declare 'MapStringQueryDocumentResponse',
    as HashRef[QueryDocumentResponse()];

declare 'CreateChunkRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::RetrieverService::CreateChunkRequest'];

coerce 'CreateChunkRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::CreateChunkRequest'->new($_) };

declare 'RepeatedCreateChunkRequest',
    as ArrayRef[CreateChunkRequest()];

coerce 'RepeatedCreateChunkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::CreateChunkRequest'->new($_) } @$_ ] };

declare 'MapStringCreateChunkRequest',
    as HashRef[CreateChunkRequest()];

declare 'BatchCreateChunksRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::RetrieverService::BatchCreateChunksRequest'];

coerce 'BatchCreateChunksRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::BatchCreateChunksRequest'->new($_) };

declare 'RepeatedBatchCreateChunksRequest',
    as ArrayRef[BatchCreateChunksRequest()];

coerce 'RepeatedBatchCreateChunksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::BatchCreateChunksRequest'->new($_) } @$_ ] };

declare 'MapStringBatchCreateChunksRequest',
    as HashRef[BatchCreateChunksRequest()];

declare 'BatchCreateChunksResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::RetrieverService::BatchCreateChunksResponse'];

coerce 'BatchCreateChunksResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::BatchCreateChunksResponse'->new($_) };

declare 'RepeatedBatchCreateChunksResponse',
    as ArrayRef[BatchCreateChunksResponse()];

coerce 'RepeatedBatchCreateChunksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::BatchCreateChunksResponse'->new($_) } @$_ ] };

declare 'MapStringBatchCreateChunksResponse',
    as HashRef[BatchCreateChunksResponse()];

declare 'GetChunkRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::RetrieverService::GetChunkRequest'];

coerce 'GetChunkRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::GetChunkRequest'->new($_) };

declare 'RepeatedGetChunkRequest',
    as ArrayRef[GetChunkRequest()];

coerce 'RepeatedGetChunkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::GetChunkRequest'->new($_) } @$_ ] };

declare 'MapStringGetChunkRequest',
    as HashRef[GetChunkRequest()];

declare 'UpdateChunkRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::RetrieverService::UpdateChunkRequest'];

coerce 'UpdateChunkRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::UpdateChunkRequest'->new($_) };

declare 'RepeatedUpdateChunkRequest',
    as ArrayRef[UpdateChunkRequest()];

coerce 'RepeatedUpdateChunkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::UpdateChunkRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateChunkRequest',
    as HashRef[UpdateChunkRequest()];

declare 'BatchUpdateChunksRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::RetrieverService::BatchUpdateChunksRequest'];

coerce 'BatchUpdateChunksRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::BatchUpdateChunksRequest'->new($_) };

declare 'RepeatedBatchUpdateChunksRequest',
    as ArrayRef[BatchUpdateChunksRequest()];

coerce 'RepeatedBatchUpdateChunksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::BatchUpdateChunksRequest'->new($_) } @$_ ] };

declare 'MapStringBatchUpdateChunksRequest',
    as HashRef[BatchUpdateChunksRequest()];

declare 'BatchUpdateChunksResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::RetrieverService::BatchUpdateChunksResponse'];

coerce 'BatchUpdateChunksResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::BatchUpdateChunksResponse'->new($_) };

declare 'RepeatedBatchUpdateChunksResponse',
    as ArrayRef[BatchUpdateChunksResponse()];

coerce 'RepeatedBatchUpdateChunksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::BatchUpdateChunksResponse'->new($_) } @$_ ] };

declare 'MapStringBatchUpdateChunksResponse',
    as HashRef[BatchUpdateChunksResponse()];

declare 'DeleteChunkRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::RetrieverService::DeleteChunkRequest'];

coerce 'DeleteChunkRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::DeleteChunkRequest'->new($_) };

declare 'RepeatedDeleteChunkRequest',
    as ArrayRef[DeleteChunkRequest()];

coerce 'RepeatedDeleteChunkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::DeleteChunkRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteChunkRequest',
    as HashRef[DeleteChunkRequest()];

declare 'BatchDeleteChunksRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::RetrieverService::BatchDeleteChunksRequest'];

coerce 'BatchDeleteChunksRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::BatchDeleteChunksRequest'->new($_) };

declare 'RepeatedBatchDeleteChunksRequest',
    as ArrayRef[BatchDeleteChunksRequest()];

coerce 'RepeatedBatchDeleteChunksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::BatchDeleteChunksRequest'->new($_) } @$_ ] };

declare 'MapStringBatchDeleteChunksRequest',
    as HashRef[BatchDeleteChunksRequest()];

declare 'ListChunksRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::RetrieverService::ListChunksRequest'];

coerce 'ListChunksRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::ListChunksRequest'->new($_) };

declare 'RepeatedListChunksRequest',
    as ArrayRef[ListChunksRequest()];

coerce 'RepeatedListChunksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::ListChunksRequest'->new($_) } @$_ ] };

declare 'MapStringListChunksRequest',
    as HashRef[ListChunksRequest()];

declare 'ListChunksResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::RetrieverService::ListChunksResponse'];

coerce 'ListChunksResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::ListChunksResponse'->new($_) };

declare 'RepeatedListChunksResponse',
    as ArrayRef[ListChunksResponse()];

coerce 'RepeatedListChunksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::RetrieverService::ListChunksResponse'->new($_) } @$_ ] };

declare 'MapStringListChunksResponse',
    as HashRef[ListChunksResponse()];

1;

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1beta::RetrieverService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
