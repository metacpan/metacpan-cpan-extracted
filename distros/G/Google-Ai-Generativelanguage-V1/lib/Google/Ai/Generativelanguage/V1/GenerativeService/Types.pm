package Google::Ai::Generativelanguage::V1::GenerativeService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TaskType',
    as (Int | Str);

declare 'GenerateContentRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1::GenerativeService::GenerateContentRequest'];

coerce 'GenerateContentRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::GenerativeService::GenerateContentRequest'->new($_) };

declare 'RepeatedGenerateContentRequest',
    as ArrayRef[GenerateContentRequest()];

coerce 'RepeatedGenerateContentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::GenerativeService::GenerateContentRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateContentRequest',
    as HashRef[GenerateContentRequest()];

declare 'GenerationConfig',
    as InstanceOf['Google::Ai::Generativelanguage::V1::GenerativeService::GenerationConfig'];

coerce 'GenerationConfig',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::GenerativeService::GenerationConfig'->new($_) };

declare 'RepeatedGenerationConfig',
    as ArrayRef[GenerationConfig()];

coerce 'RepeatedGenerationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::GenerativeService::GenerationConfig'->new($_) } @$_ ] };

declare 'MapStringGenerationConfig',
    as HashRef[GenerationConfig()];

declare 'GenerateContentResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1::GenerativeService::GenerateContentResponse'];

coerce 'GenerateContentResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::GenerativeService::GenerateContentResponse'->new($_) };

declare 'RepeatedGenerateContentResponse',
    as ArrayRef[GenerateContentResponse()];

coerce 'RepeatedGenerateContentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::GenerativeService::GenerateContentResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateContentResponse',
    as HashRef[GenerateContentResponse()];

declare 'PromptFeedback',
    as InstanceOf['Google::Ai::Generativelanguage::V1::GenerativeService::GenerateContentResponse::PromptFeedback'];

coerce 'PromptFeedback',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::GenerativeService::GenerateContentResponse::PromptFeedback'->new($_) };

declare 'RepeatedPromptFeedback',
    as ArrayRef[PromptFeedback()];

coerce 'RepeatedPromptFeedback',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::GenerativeService::GenerateContentResponse::PromptFeedback'->new($_) } @$_ ] };

declare 'MapStringPromptFeedback',
    as HashRef[PromptFeedback()];

declare 'BlockReason',
    as (Int | Str);

declare 'UsageMetadata',
    as InstanceOf['Google::Ai::Generativelanguage::V1::GenerativeService::GenerateContentResponse::UsageMetadata'];

coerce 'UsageMetadata',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::GenerativeService::GenerateContentResponse::UsageMetadata'->new($_) };

declare 'RepeatedUsageMetadata',
    as ArrayRef[UsageMetadata()];

coerce 'RepeatedUsageMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::GenerativeService::GenerateContentResponse::UsageMetadata'->new($_) } @$_ ] };

declare 'MapStringUsageMetadata',
    as HashRef[UsageMetadata()];

declare 'Candidate',
    as InstanceOf['Google::Ai::Generativelanguage::V1::GenerativeService::Candidate'];

coerce 'Candidate',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::GenerativeService::Candidate'->new($_) };

declare 'RepeatedCandidate',
    as ArrayRef[Candidate()];

coerce 'RepeatedCandidate',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::GenerativeService::Candidate'->new($_) } @$_ ] };

declare 'MapStringCandidate',
    as HashRef[Candidate()];

declare 'FinishReason',
    as (Int | Str);

declare 'UrlContextMetadata',
    as InstanceOf['Google::Ai::Generativelanguage::V1::GenerativeService::UrlContextMetadata'];

coerce 'UrlContextMetadata',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::GenerativeService::UrlContextMetadata'->new($_) };

declare 'RepeatedUrlContextMetadata',
    as ArrayRef[UrlContextMetadata()];

coerce 'RepeatedUrlContextMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::GenerativeService::UrlContextMetadata'->new($_) } @$_ ] };

declare 'MapStringUrlContextMetadata',
    as HashRef[UrlContextMetadata()];

declare 'UrlMetadata',
    as InstanceOf['Google::Ai::Generativelanguage::V1::GenerativeService::UrlMetadata'];

coerce 'UrlMetadata',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::GenerativeService::UrlMetadata'->new($_) };

declare 'RepeatedUrlMetadata',
    as ArrayRef[UrlMetadata()];

coerce 'RepeatedUrlMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::GenerativeService::UrlMetadata'->new($_) } @$_ ] };

declare 'MapStringUrlMetadata',
    as HashRef[UrlMetadata()];

declare 'UrlRetrievalStatus',
    as (Int | Str);

declare 'LogprobsResult',
    as InstanceOf['Google::Ai::Generativelanguage::V1::GenerativeService::LogprobsResult'];

coerce 'LogprobsResult',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::GenerativeService::LogprobsResult'->new($_) };

declare 'RepeatedLogprobsResult',
    as ArrayRef[LogprobsResult()];

coerce 'RepeatedLogprobsResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::GenerativeService::LogprobsResult'->new($_) } @$_ ] };

declare 'MapStringLogprobsResult',
    as HashRef[LogprobsResult()];

declare 'Candidate',
    as InstanceOf['Google::Ai::Generativelanguage::V1::GenerativeService::LogprobsResult::Candidate'];

coerce 'Candidate',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::GenerativeService::LogprobsResult::Candidate'->new($_) };

declare 'RepeatedCandidate',
    as ArrayRef[Candidate()];

coerce 'RepeatedCandidate',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::GenerativeService::LogprobsResult::Candidate'->new($_) } @$_ ] };

declare 'MapStringCandidate',
    as HashRef[Candidate()];

declare 'TopCandidates',
    as InstanceOf['Google::Ai::Generativelanguage::V1::GenerativeService::LogprobsResult::TopCandidates'];

coerce 'TopCandidates',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::GenerativeService::LogprobsResult::TopCandidates'->new($_) };

declare 'RepeatedTopCandidates',
    as ArrayRef[TopCandidates()];

coerce 'RepeatedTopCandidates',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::GenerativeService::LogprobsResult::TopCandidates'->new($_) } @$_ ] };

declare 'MapStringTopCandidates',
    as HashRef[TopCandidates()];

declare 'RetrievalMetadata',
    as InstanceOf['Google::Ai::Generativelanguage::V1::GenerativeService::RetrievalMetadata'];

coerce 'RetrievalMetadata',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::GenerativeService::RetrievalMetadata'->new($_) };

declare 'RepeatedRetrievalMetadata',
    as ArrayRef[RetrievalMetadata()];

coerce 'RepeatedRetrievalMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::GenerativeService::RetrievalMetadata'->new($_) } @$_ ] };

declare 'MapStringRetrievalMetadata',
    as HashRef[RetrievalMetadata()];

declare 'GroundingMetadata',
    as InstanceOf['Google::Ai::Generativelanguage::V1::GenerativeService::GroundingMetadata'];

coerce 'GroundingMetadata',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::GenerativeService::GroundingMetadata'->new($_) };

declare 'RepeatedGroundingMetadata',
    as ArrayRef[GroundingMetadata()];

coerce 'RepeatedGroundingMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::GenerativeService::GroundingMetadata'->new($_) } @$_ ] };

declare 'MapStringGroundingMetadata',
    as HashRef[GroundingMetadata()];

declare 'SearchEntryPoint',
    as InstanceOf['Google::Ai::Generativelanguage::V1::GenerativeService::SearchEntryPoint'];

coerce 'SearchEntryPoint',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::GenerativeService::SearchEntryPoint'->new($_) };

declare 'RepeatedSearchEntryPoint',
    as ArrayRef[SearchEntryPoint()];

coerce 'RepeatedSearchEntryPoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::GenerativeService::SearchEntryPoint'->new($_) } @$_ ] };

declare 'MapStringSearchEntryPoint',
    as HashRef[SearchEntryPoint()];

declare 'GroundingChunk',
    as InstanceOf['Google::Ai::Generativelanguage::V1::GenerativeService::GroundingChunk'];

coerce 'GroundingChunk',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::GenerativeService::GroundingChunk'->new($_) };

declare 'RepeatedGroundingChunk',
    as ArrayRef[GroundingChunk()];

coerce 'RepeatedGroundingChunk',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::GenerativeService::GroundingChunk'->new($_) } @$_ ] };

declare 'MapStringGroundingChunk',
    as HashRef[GroundingChunk()];

declare 'Web',
    as InstanceOf['Google::Ai::Generativelanguage::V1::GenerativeService::GroundingChunk::Web'];

coerce 'Web',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::GenerativeService::GroundingChunk::Web'->new($_) };

declare 'RepeatedWeb',
    as ArrayRef[Web()];

coerce 'RepeatedWeb',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::GenerativeService::GroundingChunk::Web'->new($_) } @$_ ] };

declare 'MapStringWeb',
    as HashRef[Web()];

declare 'Segment',
    as InstanceOf['Google::Ai::Generativelanguage::V1::GenerativeService::Segment'];

coerce 'Segment',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::GenerativeService::Segment'->new($_) };

declare 'RepeatedSegment',
    as ArrayRef[Segment()];

coerce 'RepeatedSegment',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::GenerativeService::Segment'->new($_) } @$_ ] };

declare 'MapStringSegment',
    as HashRef[Segment()];

declare 'GroundingSupport',
    as InstanceOf['Google::Ai::Generativelanguage::V1::GenerativeService::GroundingSupport'];

coerce 'GroundingSupport',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::GenerativeService::GroundingSupport'->new($_) };

declare 'RepeatedGroundingSupport',
    as ArrayRef[GroundingSupport()];

coerce 'RepeatedGroundingSupport',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::GenerativeService::GroundingSupport'->new($_) } @$_ ] };

declare 'MapStringGroundingSupport',
    as HashRef[GroundingSupport()];

declare 'EmbedContentRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1::GenerativeService::EmbedContentRequest'];

coerce 'EmbedContentRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::GenerativeService::EmbedContentRequest'->new($_) };

declare 'RepeatedEmbedContentRequest',
    as ArrayRef[EmbedContentRequest()];

coerce 'RepeatedEmbedContentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::GenerativeService::EmbedContentRequest'->new($_) } @$_ ] };

declare 'MapStringEmbedContentRequest',
    as HashRef[EmbedContentRequest()];

declare 'ContentEmbedding',
    as InstanceOf['Google::Ai::Generativelanguage::V1::GenerativeService::ContentEmbedding'];

coerce 'ContentEmbedding',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::GenerativeService::ContentEmbedding'->new($_) };

declare 'RepeatedContentEmbedding',
    as ArrayRef[ContentEmbedding()];

coerce 'RepeatedContentEmbedding',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::GenerativeService::ContentEmbedding'->new($_) } @$_ ] };

declare 'MapStringContentEmbedding',
    as HashRef[ContentEmbedding()];

declare 'EmbedContentResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1::GenerativeService::EmbedContentResponse'];

coerce 'EmbedContentResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::GenerativeService::EmbedContentResponse'->new($_) };

declare 'RepeatedEmbedContentResponse',
    as ArrayRef[EmbedContentResponse()];

coerce 'RepeatedEmbedContentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::GenerativeService::EmbedContentResponse'->new($_) } @$_ ] };

declare 'MapStringEmbedContentResponse',
    as HashRef[EmbedContentResponse()];

declare 'BatchEmbedContentsRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1::GenerativeService::BatchEmbedContentsRequest'];

coerce 'BatchEmbedContentsRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::GenerativeService::BatchEmbedContentsRequest'->new($_) };

declare 'RepeatedBatchEmbedContentsRequest',
    as ArrayRef[BatchEmbedContentsRequest()];

coerce 'RepeatedBatchEmbedContentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::GenerativeService::BatchEmbedContentsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchEmbedContentsRequest',
    as HashRef[BatchEmbedContentsRequest()];

declare 'BatchEmbedContentsResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1::GenerativeService::BatchEmbedContentsResponse'];

coerce 'BatchEmbedContentsResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::GenerativeService::BatchEmbedContentsResponse'->new($_) };

declare 'RepeatedBatchEmbedContentsResponse',
    as ArrayRef[BatchEmbedContentsResponse()];

coerce 'RepeatedBatchEmbedContentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::GenerativeService::BatchEmbedContentsResponse'->new($_) } @$_ ] };

declare 'MapStringBatchEmbedContentsResponse',
    as HashRef[BatchEmbedContentsResponse()];

declare 'CountTokensRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1::GenerativeService::CountTokensRequest'];

coerce 'CountTokensRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::GenerativeService::CountTokensRequest'->new($_) };

declare 'RepeatedCountTokensRequest',
    as ArrayRef[CountTokensRequest()];

coerce 'RepeatedCountTokensRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::GenerativeService::CountTokensRequest'->new($_) } @$_ ] };

declare 'MapStringCountTokensRequest',
    as HashRef[CountTokensRequest()];

declare 'CountTokensResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1::GenerativeService::CountTokensResponse'];

coerce 'CountTokensResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1::GenerativeService::CountTokensResponse'->new($_) };

declare 'RepeatedCountTokensResponse',
    as ArrayRef[CountTokensResponse()];

coerce 'RepeatedCountTokensResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1::GenerativeService::CountTokensResponse'->new($_) } @$_ ] };

declare 'MapStringCountTokensResponse',
    as HashRef[CountTokensResponse()];

1;
