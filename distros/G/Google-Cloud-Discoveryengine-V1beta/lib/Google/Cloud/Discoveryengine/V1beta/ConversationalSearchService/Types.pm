package Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ConverseConversationRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::ConverseConversationRequest'];

coerce 'ConverseConversationRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::ConverseConversationRequest'->new($_) };

declare 'RepeatedConverseConversationRequest',
    as ArrayRef[ConverseConversationRequest()];

coerce 'RepeatedConverseConversationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::ConverseConversationRequest'->new($_) } @$_ ] };

declare 'MapStringConverseConversationRequest',
    as HashRef[ConverseConversationRequest()];

declare 'UserLabelsEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::ConverseConversationRequest::UserLabelsEntry'];

coerce 'UserLabelsEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::ConverseConversationRequest::UserLabelsEntry'->new($_) };

declare 'RepeatedUserLabelsEntry',
    as ArrayRef[UserLabelsEntry()];

coerce 'RepeatedUserLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::ConverseConversationRequest::UserLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringUserLabelsEntry',
    as HashRef[UserLabelsEntry()];

declare 'ConverseConversationResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::ConverseConversationResponse'];

coerce 'ConverseConversationResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::ConverseConversationResponse'->new($_) };

declare 'RepeatedConverseConversationResponse',
    as ArrayRef[ConverseConversationResponse()];

coerce 'RepeatedConverseConversationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::ConverseConversationResponse'->new($_) } @$_ ] };

declare 'MapStringConverseConversationResponse',
    as HashRef[ConverseConversationResponse()];

declare 'CreateConversationRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::CreateConversationRequest'];

coerce 'CreateConversationRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::CreateConversationRequest'->new($_) };

declare 'RepeatedCreateConversationRequest',
    as ArrayRef[CreateConversationRequest()];

coerce 'RepeatedCreateConversationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::CreateConversationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateConversationRequest',
    as HashRef[CreateConversationRequest()];

declare 'UpdateConversationRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::UpdateConversationRequest'];

coerce 'UpdateConversationRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::UpdateConversationRequest'->new($_) };

declare 'RepeatedUpdateConversationRequest',
    as ArrayRef[UpdateConversationRequest()];

coerce 'RepeatedUpdateConversationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::UpdateConversationRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateConversationRequest',
    as HashRef[UpdateConversationRequest()];

declare 'DeleteConversationRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::DeleteConversationRequest'];

coerce 'DeleteConversationRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::DeleteConversationRequest'->new($_) };

declare 'RepeatedDeleteConversationRequest',
    as ArrayRef[DeleteConversationRequest()];

coerce 'RepeatedDeleteConversationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::DeleteConversationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteConversationRequest',
    as HashRef[DeleteConversationRequest()];

declare 'GetConversationRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::GetConversationRequest'];

coerce 'GetConversationRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::GetConversationRequest'->new($_) };

declare 'RepeatedGetConversationRequest',
    as ArrayRef[GetConversationRequest()];

coerce 'RepeatedGetConversationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::GetConversationRequest'->new($_) } @$_ ] };

declare 'MapStringGetConversationRequest',
    as HashRef[GetConversationRequest()];

declare 'ListConversationsRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::ListConversationsRequest'];

coerce 'ListConversationsRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::ListConversationsRequest'->new($_) };

declare 'RepeatedListConversationsRequest',
    as ArrayRef[ListConversationsRequest()];

coerce 'RepeatedListConversationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::ListConversationsRequest'->new($_) } @$_ ] };

declare 'MapStringListConversationsRequest',
    as HashRef[ListConversationsRequest()];

declare 'ListConversationsResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::ListConversationsResponse'];

coerce 'ListConversationsResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::ListConversationsResponse'->new($_) };

declare 'RepeatedListConversationsResponse',
    as ArrayRef[ListConversationsResponse()];

coerce 'RepeatedListConversationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::ListConversationsResponse'->new($_) } @$_ ] };

declare 'MapStringListConversationsResponse',
    as HashRef[ListConversationsResponse()];

declare 'AnswerQueryRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest'];

coerce 'AnswerQueryRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest'->new($_) };

declare 'RepeatedAnswerQueryRequest',
    as ArrayRef[AnswerQueryRequest()];

coerce 'RepeatedAnswerQueryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest'->new($_) } @$_ ] };

declare 'MapStringAnswerQueryRequest',
    as HashRef[AnswerQueryRequest()];

declare 'SafetySpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SafetySpec'];

coerce 'SafetySpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SafetySpec'->new($_) };

declare 'RepeatedSafetySpec',
    as ArrayRef[SafetySpec()];

coerce 'RepeatedSafetySpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SafetySpec'->new($_) } @$_ ] };

declare 'MapStringSafetySpec',
    as HashRef[SafetySpec()];

declare 'SafetySetting',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SafetySpec::SafetySetting'];

coerce 'SafetySetting',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SafetySpec::SafetySetting'->new($_) };

declare 'RepeatedSafetySetting',
    as ArrayRef[SafetySetting()];

coerce 'RepeatedSafetySetting',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SafetySpec::SafetySetting'->new($_) } @$_ ] };

declare 'MapStringSafetySetting',
    as HashRef[SafetySetting()];

declare 'HarmBlockThreshold',
    as (Int | Str);

declare 'RelatedQuestionsSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::RelatedQuestionsSpec'];

coerce 'RelatedQuestionsSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::RelatedQuestionsSpec'->new($_) };

declare 'RepeatedRelatedQuestionsSpec',
    as ArrayRef[RelatedQuestionsSpec()];

coerce 'RepeatedRelatedQuestionsSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::RelatedQuestionsSpec'->new($_) } @$_ ] };

declare 'MapStringRelatedQuestionsSpec',
    as HashRef[RelatedQuestionsSpec()];

declare 'GroundingSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::GroundingSpec'];

coerce 'GroundingSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::GroundingSpec'->new($_) };

declare 'RepeatedGroundingSpec',
    as ArrayRef[GroundingSpec()];

coerce 'RepeatedGroundingSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::GroundingSpec'->new($_) } @$_ ] };

declare 'MapStringGroundingSpec',
    as HashRef[GroundingSpec()];

declare 'FilteringLevel',
    as (Int | Str);

declare 'AnswerGenerationSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::AnswerGenerationSpec'];

coerce 'AnswerGenerationSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::AnswerGenerationSpec'->new($_) };

declare 'RepeatedAnswerGenerationSpec',
    as ArrayRef[AnswerGenerationSpec()];

coerce 'RepeatedAnswerGenerationSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::AnswerGenerationSpec'->new($_) } @$_ ] };

declare 'MapStringAnswerGenerationSpec',
    as HashRef[AnswerGenerationSpec()];

declare 'ModelSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::AnswerGenerationSpec::ModelSpec'];

coerce 'ModelSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::AnswerGenerationSpec::ModelSpec'->new($_) };

declare 'RepeatedModelSpec',
    as ArrayRef[ModelSpec()];

coerce 'RepeatedModelSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::AnswerGenerationSpec::ModelSpec'->new($_) } @$_ ] };

declare 'MapStringModelSpec',
    as HashRef[ModelSpec()];

declare 'PromptSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::AnswerGenerationSpec::PromptSpec'];

coerce 'PromptSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::AnswerGenerationSpec::PromptSpec'->new($_) };

declare 'RepeatedPromptSpec',
    as ArrayRef[PromptSpec()];

coerce 'RepeatedPromptSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::AnswerGenerationSpec::PromptSpec'->new($_) } @$_ ] };

declare 'MapStringPromptSpec',
    as HashRef[PromptSpec()];

declare 'MultimodalSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::AnswerGenerationSpec::MultimodalSpec'];

coerce 'MultimodalSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::AnswerGenerationSpec::MultimodalSpec'->new($_) };

declare 'RepeatedMultimodalSpec',
    as ArrayRef[MultimodalSpec()];

coerce 'RepeatedMultimodalSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::AnswerGenerationSpec::MultimodalSpec'->new($_) } @$_ ] };

declare 'MapStringMultimodalSpec',
    as HashRef[MultimodalSpec()];

declare 'ImageSource',
    as (Int | Str);

declare 'SearchSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SearchSpec'];

coerce 'SearchSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SearchSpec'->new($_) };

declare 'RepeatedSearchSpec',
    as ArrayRef[SearchSpec()];

coerce 'RepeatedSearchSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SearchSpec'->new($_) } @$_ ] };

declare 'MapStringSearchSpec',
    as HashRef[SearchSpec()];

declare 'SearchParams',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SearchSpec::SearchParams'];

coerce 'SearchParams',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SearchSpec::SearchParams'->new($_) };

declare 'RepeatedSearchParams',
    as ArrayRef[SearchParams()];

coerce 'RepeatedSearchParams',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SearchSpec::SearchParams'->new($_) } @$_ ] };

declare 'MapStringSearchParams',
    as HashRef[SearchParams()];

declare 'SearchResultList',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SearchSpec::SearchResultList'];

coerce 'SearchResultList',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SearchSpec::SearchResultList'->new($_) };

declare 'RepeatedSearchResultList',
    as ArrayRef[SearchResultList()];

coerce 'RepeatedSearchResultList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SearchSpec::SearchResultList'->new($_) } @$_ ] };

declare 'MapStringSearchResultList',
    as HashRef[SearchResultList()];

declare 'SearchResult',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SearchSpec::SearchResultList::SearchResult'];

coerce 'SearchResult',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SearchSpec::SearchResultList::SearchResult'->new($_) };

declare 'RepeatedSearchResult',
    as ArrayRef[SearchResult()];

coerce 'RepeatedSearchResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SearchSpec::SearchResultList::SearchResult'->new($_) } @$_ ] };

declare 'MapStringSearchResult',
    as HashRef[SearchResult()];

declare 'UnstructuredDocumentInfo',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SearchSpec::SearchResultList::SearchResult::UnstructuredDocumentInfo'];

coerce 'UnstructuredDocumentInfo',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SearchSpec::SearchResultList::SearchResult::UnstructuredDocumentInfo'->new($_) };

declare 'RepeatedUnstructuredDocumentInfo',
    as ArrayRef[UnstructuredDocumentInfo()];

coerce 'RepeatedUnstructuredDocumentInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SearchSpec::SearchResultList::SearchResult::UnstructuredDocumentInfo'->new($_) } @$_ ] };

declare 'MapStringUnstructuredDocumentInfo',
    as HashRef[UnstructuredDocumentInfo()];

declare 'DocumentContext',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SearchSpec::SearchResultList::SearchResult::UnstructuredDocumentInfo::DocumentContext'];

coerce 'DocumentContext',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SearchSpec::SearchResultList::SearchResult::UnstructuredDocumentInfo::DocumentContext'->new($_) };

declare 'RepeatedDocumentContext',
    as ArrayRef[DocumentContext()];

coerce 'RepeatedDocumentContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SearchSpec::SearchResultList::SearchResult::UnstructuredDocumentInfo::DocumentContext'->new($_) } @$_ ] };

declare 'MapStringDocumentContext',
    as HashRef[DocumentContext()];

declare 'ExtractiveSegment',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SearchSpec::SearchResultList::SearchResult::UnstructuredDocumentInfo::ExtractiveSegment'];

coerce 'ExtractiveSegment',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SearchSpec::SearchResultList::SearchResult::UnstructuredDocumentInfo::ExtractiveSegment'->new($_) };

declare 'RepeatedExtractiveSegment',
    as ArrayRef[ExtractiveSegment()];

coerce 'RepeatedExtractiveSegment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SearchSpec::SearchResultList::SearchResult::UnstructuredDocumentInfo::ExtractiveSegment'->new($_) } @$_ ] };

declare 'MapStringExtractiveSegment',
    as HashRef[ExtractiveSegment()];

declare 'ExtractiveAnswer',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SearchSpec::SearchResultList::SearchResult::UnstructuredDocumentInfo::ExtractiveAnswer'];

coerce 'ExtractiveAnswer',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SearchSpec::SearchResultList::SearchResult::UnstructuredDocumentInfo::ExtractiveAnswer'->new($_) };

declare 'RepeatedExtractiveAnswer',
    as ArrayRef[ExtractiveAnswer()];

coerce 'RepeatedExtractiveAnswer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SearchSpec::SearchResultList::SearchResult::UnstructuredDocumentInfo::ExtractiveAnswer'->new($_) } @$_ ] };

declare 'MapStringExtractiveAnswer',
    as HashRef[ExtractiveAnswer()];

declare 'ChunkInfo',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SearchSpec::SearchResultList::SearchResult::ChunkInfo'];

coerce 'ChunkInfo',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SearchSpec::SearchResultList::SearchResult::ChunkInfo'->new($_) };

declare 'RepeatedChunkInfo',
    as ArrayRef[ChunkInfo()];

coerce 'RepeatedChunkInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SearchSpec::SearchResultList::SearchResult::ChunkInfo'->new($_) } @$_ ] };

declare 'MapStringChunkInfo',
    as HashRef[ChunkInfo()];

declare 'DocumentMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SearchSpec::SearchResultList::SearchResult::ChunkInfo::DocumentMetadata'];

coerce 'DocumentMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SearchSpec::SearchResultList::SearchResult::ChunkInfo::DocumentMetadata'->new($_) };

declare 'RepeatedDocumentMetadata',
    as ArrayRef[DocumentMetadata()];

coerce 'RepeatedDocumentMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::SearchSpec::SearchResultList::SearchResult::ChunkInfo::DocumentMetadata'->new($_) } @$_ ] };

declare 'MapStringDocumentMetadata',
    as HashRef[DocumentMetadata()];

declare 'QueryUnderstandingSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::QueryUnderstandingSpec'];

coerce 'QueryUnderstandingSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::QueryUnderstandingSpec'->new($_) };

declare 'RepeatedQueryUnderstandingSpec',
    as ArrayRef[QueryUnderstandingSpec()];

coerce 'RepeatedQueryUnderstandingSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::QueryUnderstandingSpec'->new($_) } @$_ ] };

declare 'MapStringQueryUnderstandingSpec',
    as HashRef[QueryUnderstandingSpec()];

declare 'QueryClassificationSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::QueryUnderstandingSpec::QueryClassificationSpec'];

coerce 'QueryClassificationSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::QueryUnderstandingSpec::QueryClassificationSpec'->new($_) };

declare 'RepeatedQueryClassificationSpec',
    as ArrayRef[QueryClassificationSpec()];

coerce 'RepeatedQueryClassificationSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::QueryUnderstandingSpec::QueryClassificationSpec'->new($_) } @$_ ] };

declare 'MapStringQueryClassificationSpec',
    as HashRef[QueryClassificationSpec()];

declare 'Type',
    as (Int | Str);

declare 'QueryRephraserSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::QueryUnderstandingSpec::QueryRephraserSpec'];

coerce 'QueryRephraserSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::QueryUnderstandingSpec::QueryRephraserSpec'->new($_) };

declare 'RepeatedQueryRephraserSpec',
    as ArrayRef[QueryRephraserSpec()];

coerce 'RepeatedQueryRephraserSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::QueryUnderstandingSpec::QueryRephraserSpec'->new($_) } @$_ ] };

declare 'MapStringQueryRephraserSpec',
    as HashRef[QueryRephraserSpec()];

declare 'ModelSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::QueryUnderstandingSpec::QueryRephraserSpec::ModelSpec'];

coerce 'ModelSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::QueryUnderstandingSpec::QueryRephraserSpec::ModelSpec'->new($_) };

declare 'RepeatedModelSpec',
    as ArrayRef[ModelSpec()];

coerce 'RepeatedModelSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::QueryUnderstandingSpec::QueryRephraserSpec::ModelSpec'->new($_) } @$_ ] };

declare 'MapStringModelSpec',
    as HashRef[ModelSpec()];

declare 'ModelType',
    as (Int | Str);

declare 'EndUserSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::EndUserSpec'];

coerce 'EndUserSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::EndUserSpec'->new($_) };

declare 'RepeatedEndUserSpec',
    as ArrayRef[EndUserSpec()];

coerce 'RepeatedEndUserSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::EndUserSpec'->new($_) } @$_ ] };

declare 'MapStringEndUserSpec',
    as HashRef[EndUserSpec()];

declare 'EndUserMetaData',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::EndUserSpec::EndUserMetaData'];

coerce 'EndUserMetaData',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::EndUserSpec::EndUserMetaData'->new($_) };

declare 'RepeatedEndUserMetaData',
    as ArrayRef[EndUserMetaData()];

coerce 'RepeatedEndUserMetaData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::EndUserSpec::EndUserMetaData'->new($_) } @$_ ] };

declare 'MapStringEndUserMetaData',
    as HashRef[EndUserMetaData()];

declare 'ChunkInfo',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::EndUserSpec::EndUserMetaData::ChunkInfo'];

coerce 'ChunkInfo',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::EndUserSpec::EndUserMetaData::ChunkInfo'->new($_) };

declare 'RepeatedChunkInfo',
    as ArrayRef[ChunkInfo()];

coerce 'RepeatedChunkInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::EndUserSpec::EndUserMetaData::ChunkInfo'->new($_) } @$_ ] };

declare 'MapStringChunkInfo',
    as HashRef[ChunkInfo()];

declare 'DocumentMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::EndUserSpec::EndUserMetaData::ChunkInfo::DocumentMetadata'];

coerce 'DocumentMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::EndUserSpec::EndUserMetaData::ChunkInfo::DocumentMetadata'->new($_) };

declare 'RepeatedDocumentMetadata',
    as ArrayRef[DocumentMetadata()];

coerce 'RepeatedDocumentMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::EndUserSpec::EndUserMetaData::ChunkInfo::DocumentMetadata'->new($_) } @$_ ] };

declare 'MapStringDocumentMetadata',
    as HashRef[DocumentMetadata()];

declare 'UserLabelsEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::UserLabelsEntry'];

coerce 'UserLabelsEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::UserLabelsEntry'->new($_) };

declare 'RepeatedUserLabelsEntry',
    as ArrayRef[UserLabelsEntry()];

coerce 'RepeatedUserLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryRequest::UserLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringUserLabelsEntry',
    as HashRef[UserLabelsEntry()];

declare 'AnswerQueryResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryResponse'];

coerce 'AnswerQueryResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryResponse'->new($_) };

declare 'RepeatedAnswerQueryResponse',
    as ArrayRef[AnswerQueryResponse()];

coerce 'RepeatedAnswerQueryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::AnswerQueryResponse'->new($_) } @$_ ] };

declare 'MapStringAnswerQueryResponse',
    as HashRef[AnswerQueryResponse()];

declare 'GetAnswerRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::GetAnswerRequest'];

coerce 'GetAnswerRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::GetAnswerRequest'->new($_) };

declare 'RepeatedGetAnswerRequest',
    as ArrayRef[GetAnswerRequest()];

coerce 'RepeatedGetAnswerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::GetAnswerRequest'->new($_) } @$_ ] };

declare 'MapStringGetAnswerRequest',
    as HashRef[GetAnswerRequest()];

declare 'CreateSessionRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::CreateSessionRequest'];

coerce 'CreateSessionRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::CreateSessionRequest'->new($_) };

declare 'RepeatedCreateSessionRequest',
    as ArrayRef[CreateSessionRequest()];

coerce 'RepeatedCreateSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::CreateSessionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSessionRequest',
    as HashRef[CreateSessionRequest()];

declare 'UpdateSessionRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::UpdateSessionRequest'];

coerce 'UpdateSessionRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::UpdateSessionRequest'->new($_) };

declare 'RepeatedUpdateSessionRequest',
    as ArrayRef[UpdateSessionRequest()];

coerce 'RepeatedUpdateSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::UpdateSessionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSessionRequest',
    as HashRef[UpdateSessionRequest()];

declare 'DeleteSessionRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::DeleteSessionRequest'];

coerce 'DeleteSessionRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::DeleteSessionRequest'->new($_) };

declare 'RepeatedDeleteSessionRequest',
    as ArrayRef[DeleteSessionRequest()];

coerce 'RepeatedDeleteSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::DeleteSessionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSessionRequest',
    as HashRef[DeleteSessionRequest()];

declare 'GetSessionRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::GetSessionRequest'];

coerce 'GetSessionRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::GetSessionRequest'->new($_) };

declare 'RepeatedGetSessionRequest',
    as ArrayRef[GetSessionRequest()];

coerce 'RepeatedGetSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::GetSessionRequest'->new($_) } @$_ ] };

declare 'MapStringGetSessionRequest',
    as HashRef[GetSessionRequest()];

declare 'ListSessionsRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::ListSessionsRequest'];

coerce 'ListSessionsRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::ListSessionsRequest'->new($_) };

declare 'RepeatedListSessionsRequest',
    as ArrayRef[ListSessionsRequest()];

coerce 'RepeatedListSessionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::ListSessionsRequest'->new($_) } @$_ ] };

declare 'MapStringListSessionsRequest',
    as HashRef[ListSessionsRequest()];

declare 'ListSessionsResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::ListSessionsResponse'];

coerce 'ListSessionsResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::ListSessionsResponse'->new($_) };

declare 'RepeatedListSessionsResponse',
    as ArrayRef[ListSessionsResponse()];

coerce 'RepeatedListSessionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::ListSessionsResponse'->new($_) } @$_ ] };

declare 'MapStringListSessionsResponse',
    as HashRef[ListSessionsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::ConversationalSearchService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
