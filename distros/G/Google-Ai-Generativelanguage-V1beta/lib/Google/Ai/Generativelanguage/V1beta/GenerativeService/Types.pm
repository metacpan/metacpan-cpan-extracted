package Google::Ai::Generativelanguage::V1beta::GenerativeService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TaskType',
    as (Int | Str);

declare 'GenerateContentRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateContentRequest'];

coerce 'GenerateContentRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateContentRequest'->new($_) };

declare 'RepeatedGenerateContentRequest',
    as ArrayRef[GenerateContentRequest()];

coerce 'RepeatedGenerateContentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateContentRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateContentRequest',
    as HashRef[GenerateContentRequest()];

declare 'PrebuiltVoiceConfig',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::PrebuiltVoiceConfig'];

coerce 'PrebuiltVoiceConfig',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::PrebuiltVoiceConfig'->new($_) };

declare 'RepeatedPrebuiltVoiceConfig',
    as ArrayRef[PrebuiltVoiceConfig()];

coerce 'RepeatedPrebuiltVoiceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::PrebuiltVoiceConfig'->new($_) } @$_ ] };

declare 'MapStringPrebuiltVoiceConfig',
    as HashRef[PrebuiltVoiceConfig()];

declare 'VoiceConfig',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::VoiceConfig'];

coerce 'VoiceConfig',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::VoiceConfig'->new($_) };

declare 'RepeatedVoiceConfig',
    as ArrayRef[VoiceConfig()];

coerce 'RepeatedVoiceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::VoiceConfig'->new($_) } @$_ ] };

declare 'MapStringVoiceConfig',
    as HashRef[VoiceConfig()];

declare 'SpeakerVoiceConfig',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::SpeakerVoiceConfig'];

coerce 'SpeakerVoiceConfig',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::SpeakerVoiceConfig'->new($_) };

declare 'RepeatedSpeakerVoiceConfig',
    as ArrayRef[SpeakerVoiceConfig()];

coerce 'RepeatedSpeakerVoiceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::SpeakerVoiceConfig'->new($_) } @$_ ] };

declare 'MapStringSpeakerVoiceConfig',
    as HashRef[SpeakerVoiceConfig()];

declare 'MultiSpeakerVoiceConfig',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::MultiSpeakerVoiceConfig'];

coerce 'MultiSpeakerVoiceConfig',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::MultiSpeakerVoiceConfig'->new($_) };

declare 'RepeatedMultiSpeakerVoiceConfig',
    as ArrayRef[MultiSpeakerVoiceConfig()];

coerce 'RepeatedMultiSpeakerVoiceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::MultiSpeakerVoiceConfig'->new($_) } @$_ ] };

declare 'MapStringMultiSpeakerVoiceConfig',
    as HashRef[MultiSpeakerVoiceConfig()];

declare 'SpeechConfig',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::SpeechConfig'];

coerce 'SpeechConfig',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::SpeechConfig'->new($_) };

declare 'RepeatedSpeechConfig',
    as ArrayRef[SpeechConfig()];

coerce 'RepeatedSpeechConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::SpeechConfig'->new($_) } @$_ ] };

declare 'MapStringSpeechConfig',
    as HashRef[SpeechConfig()];

declare 'ThinkingConfig',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::ThinkingConfig'];

coerce 'ThinkingConfig',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::ThinkingConfig'->new($_) };

declare 'RepeatedThinkingConfig',
    as ArrayRef[ThinkingConfig()];

coerce 'RepeatedThinkingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::ThinkingConfig'->new($_) } @$_ ] };

declare 'MapStringThinkingConfig',
    as HashRef[ThinkingConfig()];

declare 'ImageConfig',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::ImageConfig'];

coerce 'ImageConfig',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::ImageConfig'->new($_) };

declare 'RepeatedImageConfig',
    as ArrayRef[ImageConfig()];

coerce 'RepeatedImageConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::ImageConfig'->new($_) } @$_ ] };

declare 'MapStringImageConfig',
    as HashRef[ImageConfig()];

declare 'GenerationConfig',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerationConfig'];

coerce 'GenerationConfig',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerationConfig'->new($_) };

declare 'RepeatedGenerationConfig',
    as ArrayRef[GenerationConfig()];

coerce 'RepeatedGenerationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerationConfig'->new($_) } @$_ ] };

declare 'MapStringGenerationConfig',
    as HashRef[GenerationConfig()];

declare 'Modality',
    as (Int | Str);

declare 'MediaResolution',
    as (Int | Str);

declare 'SemanticRetrieverConfig',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::SemanticRetrieverConfig'];

coerce 'SemanticRetrieverConfig',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::SemanticRetrieverConfig'->new($_) };

declare 'RepeatedSemanticRetrieverConfig',
    as ArrayRef[SemanticRetrieverConfig()];

coerce 'RepeatedSemanticRetrieverConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::SemanticRetrieverConfig'->new($_) } @$_ ] };

declare 'MapStringSemanticRetrieverConfig',
    as HashRef[SemanticRetrieverConfig()];

declare 'GenerateContentResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateContentResponse'];

coerce 'GenerateContentResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateContentResponse'->new($_) };

declare 'RepeatedGenerateContentResponse',
    as ArrayRef[GenerateContentResponse()];

coerce 'RepeatedGenerateContentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateContentResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateContentResponse',
    as HashRef[GenerateContentResponse()];

declare 'PromptFeedback',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateContentResponse::PromptFeedback'];

coerce 'PromptFeedback',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateContentResponse::PromptFeedback'->new($_) };

declare 'RepeatedPromptFeedback',
    as ArrayRef[PromptFeedback()];

coerce 'RepeatedPromptFeedback',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateContentResponse::PromptFeedback'->new($_) } @$_ ] };

declare 'MapStringPromptFeedback',
    as HashRef[PromptFeedback()];

declare 'BlockReason',
    as (Int | Str);

declare 'UsageMetadata',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateContentResponse::UsageMetadata'];

coerce 'UsageMetadata',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateContentResponse::UsageMetadata'->new($_) };

declare 'RepeatedUsageMetadata',
    as ArrayRef[UsageMetadata()];

coerce 'RepeatedUsageMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateContentResponse::UsageMetadata'->new($_) } @$_ ] };

declare 'MapStringUsageMetadata',
    as HashRef[UsageMetadata()];

declare 'Candidate',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::Candidate'];

coerce 'Candidate',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::Candidate'->new($_) };

declare 'RepeatedCandidate',
    as ArrayRef[Candidate()];

coerce 'RepeatedCandidate',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::Candidate'->new($_) } @$_ ] };

declare 'MapStringCandidate',
    as HashRef[Candidate()];

declare 'FinishReason',
    as (Int | Str);

declare 'UrlContextMetadata',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::UrlContextMetadata'];

coerce 'UrlContextMetadata',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::UrlContextMetadata'->new($_) };

declare 'RepeatedUrlContextMetadata',
    as ArrayRef[UrlContextMetadata()];

coerce 'RepeatedUrlContextMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::UrlContextMetadata'->new($_) } @$_ ] };

declare 'MapStringUrlContextMetadata',
    as HashRef[UrlContextMetadata()];

declare 'UrlMetadata',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::UrlMetadata'];

coerce 'UrlMetadata',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::UrlMetadata'->new($_) };

declare 'RepeatedUrlMetadata',
    as ArrayRef[UrlMetadata()];

coerce 'RepeatedUrlMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::UrlMetadata'->new($_) } @$_ ] };

declare 'MapStringUrlMetadata',
    as HashRef[UrlMetadata()];

declare 'UrlRetrievalStatus',
    as (Int | Str);

declare 'LogprobsResult',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::LogprobsResult'];

coerce 'LogprobsResult',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::LogprobsResult'->new($_) };

declare 'RepeatedLogprobsResult',
    as ArrayRef[LogprobsResult()];

coerce 'RepeatedLogprobsResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::LogprobsResult'->new($_) } @$_ ] };

declare 'MapStringLogprobsResult',
    as HashRef[LogprobsResult()];

declare 'Candidate',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::LogprobsResult::Candidate'];

coerce 'Candidate',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::LogprobsResult::Candidate'->new($_) };

declare 'RepeatedCandidate',
    as ArrayRef[Candidate()];

coerce 'RepeatedCandidate',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::LogprobsResult::Candidate'->new($_) } @$_ ] };

declare 'MapStringCandidate',
    as HashRef[Candidate()];

declare 'TopCandidates',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::LogprobsResult::TopCandidates'];

coerce 'TopCandidates',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::LogprobsResult::TopCandidates'->new($_) };

declare 'RepeatedTopCandidates',
    as ArrayRef[TopCandidates()];

coerce 'RepeatedTopCandidates',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::LogprobsResult::TopCandidates'->new($_) } @$_ ] };

declare 'MapStringTopCandidates',
    as HashRef[TopCandidates()];

declare 'AttributionSourceId',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::AttributionSourceId'];

coerce 'AttributionSourceId',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::AttributionSourceId'->new($_) };

declare 'RepeatedAttributionSourceId',
    as ArrayRef[AttributionSourceId()];

coerce 'RepeatedAttributionSourceId',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::AttributionSourceId'->new($_) } @$_ ] };

declare 'MapStringAttributionSourceId',
    as HashRef[AttributionSourceId()];

declare 'GroundingPassageId',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::AttributionSourceId::GroundingPassageId'];

coerce 'GroundingPassageId',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::AttributionSourceId::GroundingPassageId'->new($_) };

declare 'RepeatedGroundingPassageId',
    as ArrayRef[GroundingPassageId()];

coerce 'RepeatedGroundingPassageId',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::AttributionSourceId::GroundingPassageId'->new($_) } @$_ ] };

declare 'MapStringGroundingPassageId',
    as HashRef[GroundingPassageId()];

declare 'SemanticRetrieverChunk',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::AttributionSourceId::SemanticRetrieverChunk'];

coerce 'SemanticRetrieverChunk',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::AttributionSourceId::SemanticRetrieverChunk'->new($_) };

declare 'RepeatedSemanticRetrieverChunk',
    as ArrayRef[SemanticRetrieverChunk()];

coerce 'RepeatedSemanticRetrieverChunk',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::AttributionSourceId::SemanticRetrieverChunk'->new($_) } @$_ ] };

declare 'MapStringSemanticRetrieverChunk',
    as HashRef[SemanticRetrieverChunk()];

declare 'GroundingAttribution',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::GroundingAttribution'];

coerce 'GroundingAttribution',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GroundingAttribution'->new($_) };

declare 'RepeatedGroundingAttribution',
    as ArrayRef[GroundingAttribution()];

coerce 'RepeatedGroundingAttribution',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GroundingAttribution'->new($_) } @$_ ] };

declare 'MapStringGroundingAttribution',
    as HashRef[GroundingAttribution()];

declare 'RetrievalMetadata',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::RetrievalMetadata'];

coerce 'RetrievalMetadata',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::RetrievalMetadata'->new($_) };

declare 'RepeatedRetrievalMetadata',
    as ArrayRef[RetrievalMetadata()];

coerce 'RepeatedRetrievalMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::RetrievalMetadata'->new($_) } @$_ ] };

declare 'MapStringRetrievalMetadata',
    as HashRef[RetrievalMetadata()];

declare 'GroundingMetadata',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::GroundingMetadata'];

coerce 'GroundingMetadata',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GroundingMetadata'->new($_) };

declare 'RepeatedGroundingMetadata',
    as ArrayRef[GroundingMetadata()];

coerce 'RepeatedGroundingMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GroundingMetadata'->new($_) } @$_ ] };

declare 'MapStringGroundingMetadata',
    as HashRef[GroundingMetadata()];

declare 'SearchEntryPoint',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::SearchEntryPoint'];

coerce 'SearchEntryPoint',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::SearchEntryPoint'->new($_) };

declare 'RepeatedSearchEntryPoint',
    as ArrayRef[SearchEntryPoint()];

coerce 'RepeatedSearchEntryPoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::SearchEntryPoint'->new($_) } @$_ ] };

declare 'MapStringSearchEntryPoint',
    as HashRef[SearchEntryPoint()];

declare 'GroundingChunk',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::GroundingChunk'];

coerce 'GroundingChunk',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GroundingChunk'->new($_) };

declare 'RepeatedGroundingChunk',
    as ArrayRef[GroundingChunk()];

coerce 'RepeatedGroundingChunk',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GroundingChunk'->new($_) } @$_ ] };

declare 'MapStringGroundingChunk',
    as HashRef[GroundingChunk()];

declare 'Web',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::GroundingChunk::Web'];

coerce 'Web',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GroundingChunk::Web'->new($_) };

declare 'RepeatedWeb',
    as ArrayRef[Web()];

coerce 'RepeatedWeb',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GroundingChunk::Web'->new($_) } @$_ ] };

declare 'MapStringWeb',
    as HashRef[Web()];

declare 'RetrievedContext',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::GroundingChunk::RetrievedContext'];

coerce 'RetrievedContext',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GroundingChunk::RetrievedContext'->new($_) };

declare 'RepeatedRetrievedContext',
    as ArrayRef[RetrievedContext()];

coerce 'RepeatedRetrievedContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GroundingChunk::RetrievedContext'->new($_) } @$_ ] };

declare 'MapStringRetrievedContext',
    as HashRef[RetrievedContext()];

declare 'Maps',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::GroundingChunk::Maps'];

coerce 'Maps',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GroundingChunk::Maps'->new($_) };

declare 'RepeatedMaps',
    as ArrayRef[Maps()];

coerce 'RepeatedMaps',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GroundingChunk::Maps'->new($_) } @$_ ] };

declare 'MapStringMaps',
    as HashRef[Maps()];

declare 'PlaceAnswerSources',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::GroundingChunk::Maps::PlaceAnswerSources'];

coerce 'PlaceAnswerSources',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GroundingChunk::Maps::PlaceAnswerSources'->new($_) };

declare 'RepeatedPlaceAnswerSources',
    as ArrayRef[PlaceAnswerSources()];

coerce 'RepeatedPlaceAnswerSources',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GroundingChunk::Maps::PlaceAnswerSources'->new($_) } @$_ ] };

declare 'MapStringPlaceAnswerSources',
    as HashRef[PlaceAnswerSources()];

declare 'ReviewSnippet',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::GroundingChunk::Maps::PlaceAnswerSources::ReviewSnippet'];

coerce 'ReviewSnippet',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GroundingChunk::Maps::PlaceAnswerSources::ReviewSnippet'->new($_) };

declare 'RepeatedReviewSnippet',
    as ArrayRef[ReviewSnippet()];

coerce 'RepeatedReviewSnippet',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GroundingChunk::Maps::PlaceAnswerSources::ReviewSnippet'->new($_) } @$_ ] };

declare 'MapStringReviewSnippet',
    as HashRef[ReviewSnippet()];

declare 'Segment',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::Segment'];

coerce 'Segment',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::Segment'->new($_) };

declare 'RepeatedSegment',
    as ArrayRef[Segment()];

coerce 'RepeatedSegment',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::Segment'->new($_) } @$_ ] };

declare 'MapStringSegment',
    as HashRef[Segment()];

declare 'GroundingSupport',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::GroundingSupport'];

coerce 'GroundingSupport',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GroundingSupport'->new($_) };

declare 'RepeatedGroundingSupport',
    as ArrayRef[GroundingSupport()];

coerce 'RepeatedGroundingSupport',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GroundingSupport'->new($_) } @$_ ] };

declare 'MapStringGroundingSupport',
    as HashRef[GroundingSupport()];

declare 'GenerateAnswerRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateAnswerRequest'];

coerce 'GenerateAnswerRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateAnswerRequest'->new($_) };

declare 'RepeatedGenerateAnswerRequest',
    as ArrayRef[GenerateAnswerRequest()];

coerce 'RepeatedGenerateAnswerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateAnswerRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateAnswerRequest',
    as HashRef[GenerateAnswerRequest()];

declare 'AnswerStyle',
    as (Int | Str);

declare 'GenerateAnswerResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateAnswerResponse'];

coerce 'GenerateAnswerResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateAnswerResponse'->new($_) };

declare 'RepeatedGenerateAnswerResponse',
    as ArrayRef[GenerateAnswerResponse()];

coerce 'RepeatedGenerateAnswerResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateAnswerResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateAnswerResponse',
    as HashRef[GenerateAnswerResponse()];

declare 'InputFeedback',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateAnswerResponse::InputFeedback'];

coerce 'InputFeedback',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateAnswerResponse::InputFeedback'->new($_) };

declare 'RepeatedInputFeedback',
    as ArrayRef[InputFeedback()];

coerce 'RepeatedInputFeedback',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateAnswerResponse::InputFeedback'->new($_) } @$_ ] };

declare 'MapStringInputFeedback',
    as HashRef[InputFeedback()];

declare 'BlockReason',
    as (Int | Str);

declare 'EmbedContentRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::EmbedContentRequest'];

coerce 'EmbedContentRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::EmbedContentRequest'->new($_) };

declare 'RepeatedEmbedContentRequest',
    as ArrayRef[EmbedContentRequest()];

coerce 'RepeatedEmbedContentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::EmbedContentRequest'->new($_) } @$_ ] };

declare 'MapStringEmbedContentRequest',
    as HashRef[EmbedContentRequest()];

declare 'ContentEmbedding',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::ContentEmbedding'];

coerce 'ContentEmbedding',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::ContentEmbedding'->new($_) };

declare 'RepeatedContentEmbedding',
    as ArrayRef[ContentEmbedding()];

coerce 'RepeatedContentEmbedding',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::ContentEmbedding'->new($_) } @$_ ] };

declare 'MapStringContentEmbedding',
    as HashRef[ContentEmbedding()];

declare 'EmbedContentResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::EmbedContentResponse'];

coerce 'EmbedContentResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::EmbedContentResponse'->new($_) };

declare 'RepeatedEmbedContentResponse',
    as ArrayRef[EmbedContentResponse()];

coerce 'RepeatedEmbedContentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::EmbedContentResponse'->new($_) } @$_ ] };

declare 'MapStringEmbedContentResponse',
    as HashRef[EmbedContentResponse()];

declare 'BatchEmbedContentsRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::BatchEmbedContentsRequest'];

coerce 'BatchEmbedContentsRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BatchEmbedContentsRequest'->new($_) };

declare 'RepeatedBatchEmbedContentsRequest',
    as ArrayRef[BatchEmbedContentsRequest()];

coerce 'RepeatedBatchEmbedContentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BatchEmbedContentsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchEmbedContentsRequest',
    as HashRef[BatchEmbedContentsRequest()];

declare 'BatchEmbedContentsResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::BatchEmbedContentsResponse'];

coerce 'BatchEmbedContentsResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BatchEmbedContentsResponse'->new($_) };

declare 'RepeatedBatchEmbedContentsResponse',
    as ArrayRef[BatchEmbedContentsResponse()];

coerce 'RepeatedBatchEmbedContentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BatchEmbedContentsResponse'->new($_) } @$_ ] };

declare 'MapStringBatchEmbedContentsResponse',
    as HashRef[BatchEmbedContentsResponse()];

declare 'CountTokensRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::CountTokensRequest'];

coerce 'CountTokensRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::CountTokensRequest'->new($_) };

declare 'RepeatedCountTokensRequest',
    as ArrayRef[CountTokensRequest()];

coerce 'RepeatedCountTokensRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::CountTokensRequest'->new($_) } @$_ ] };

declare 'MapStringCountTokensRequest',
    as HashRef[CountTokensRequest()];

declare 'CountTokensResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::CountTokensResponse'];

coerce 'CountTokensResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::CountTokensResponse'->new($_) };

declare 'RepeatedCountTokensResponse',
    as ArrayRef[CountTokensResponse()];

coerce 'RepeatedCountTokensResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::CountTokensResponse'->new($_) } @$_ ] };

declare 'MapStringCountTokensResponse',
    as HashRef[CountTokensResponse()];

declare 'RealtimeInputConfig',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::RealtimeInputConfig'];

coerce 'RealtimeInputConfig',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::RealtimeInputConfig'->new($_) };

declare 'RepeatedRealtimeInputConfig',
    as ArrayRef[RealtimeInputConfig()];

coerce 'RepeatedRealtimeInputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::RealtimeInputConfig'->new($_) } @$_ ] };

declare 'MapStringRealtimeInputConfig',
    as HashRef[RealtimeInputConfig()];

declare 'ActivityHandling',
    as (Int | Str);

declare 'TurnCoverage',
    as (Int | Str);

declare 'AutomaticActivityDetection',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::RealtimeInputConfig::AutomaticActivityDetection'];

coerce 'AutomaticActivityDetection',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::RealtimeInputConfig::AutomaticActivityDetection'->new($_) };

declare 'RepeatedAutomaticActivityDetection',
    as ArrayRef[AutomaticActivityDetection()];

coerce 'RepeatedAutomaticActivityDetection',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::RealtimeInputConfig::AutomaticActivityDetection'->new($_) } @$_ ] };

declare 'MapStringAutomaticActivityDetection',
    as HashRef[AutomaticActivityDetection()];

declare 'StartSensitivity',
    as (Int | Str);

declare 'EndSensitivity',
    as (Int | Str);

declare 'SessionResumptionConfig',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::SessionResumptionConfig'];

coerce 'SessionResumptionConfig',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::SessionResumptionConfig'->new($_) };

declare 'RepeatedSessionResumptionConfig',
    as ArrayRef[SessionResumptionConfig()];

coerce 'RepeatedSessionResumptionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::SessionResumptionConfig'->new($_) } @$_ ] };

declare 'MapStringSessionResumptionConfig',
    as HashRef[SessionResumptionConfig()];

declare 'ContextWindowCompressionConfig',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::ContextWindowCompressionConfig'];

coerce 'ContextWindowCompressionConfig',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::ContextWindowCompressionConfig'->new($_) };

declare 'RepeatedContextWindowCompressionConfig',
    as ArrayRef[ContextWindowCompressionConfig()];

coerce 'RepeatedContextWindowCompressionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::ContextWindowCompressionConfig'->new($_) } @$_ ] };

declare 'MapStringContextWindowCompressionConfig',
    as HashRef[ContextWindowCompressionConfig()];

declare 'SlidingWindow',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::ContextWindowCompressionConfig::SlidingWindow'];

coerce 'SlidingWindow',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::ContextWindowCompressionConfig::SlidingWindow'->new($_) };

declare 'RepeatedSlidingWindow',
    as ArrayRef[SlidingWindow()];

coerce 'RepeatedSlidingWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::ContextWindowCompressionConfig::SlidingWindow'->new($_) } @$_ ] };

declare 'MapStringSlidingWindow',
    as HashRef[SlidingWindow()];

declare 'AudioTranscriptionConfig',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::AudioTranscriptionConfig'];

coerce 'AudioTranscriptionConfig',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::AudioTranscriptionConfig'->new($_) };

declare 'RepeatedAudioTranscriptionConfig',
    as ArrayRef[AudioTranscriptionConfig()];

coerce 'RepeatedAudioTranscriptionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::AudioTranscriptionConfig'->new($_) } @$_ ] };

declare 'MapStringAudioTranscriptionConfig',
    as HashRef[AudioTranscriptionConfig()];

declare 'BidiGenerateContentSetup',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentSetup'];

coerce 'BidiGenerateContentSetup',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentSetup'->new($_) };

declare 'RepeatedBidiGenerateContentSetup',
    as ArrayRef[BidiGenerateContentSetup()];

coerce 'RepeatedBidiGenerateContentSetup',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentSetup'->new($_) } @$_ ] };

declare 'MapStringBidiGenerateContentSetup',
    as HashRef[BidiGenerateContentSetup()];

declare 'BidiGenerateContentClientContent',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentClientContent'];

coerce 'BidiGenerateContentClientContent',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentClientContent'->new($_) };

declare 'RepeatedBidiGenerateContentClientContent',
    as ArrayRef[BidiGenerateContentClientContent()];

coerce 'RepeatedBidiGenerateContentClientContent',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentClientContent'->new($_) } @$_ ] };

declare 'MapStringBidiGenerateContentClientContent',
    as HashRef[BidiGenerateContentClientContent()];

declare 'BidiGenerateContentRealtimeInput',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentRealtimeInput'];

coerce 'BidiGenerateContentRealtimeInput',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentRealtimeInput'->new($_) };

declare 'RepeatedBidiGenerateContentRealtimeInput',
    as ArrayRef[BidiGenerateContentRealtimeInput()];

coerce 'RepeatedBidiGenerateContentRealtimeInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentRealtimeInput'->new($_) } @$_ ] };

declare 'MapStringBidiGenerateContentRealtimeInput',
    as HashRef[BidiGenerateContentRealtimeInput()];

declare 'ActivityStart',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentRealtimeInput::ActivityStart'];

coerce 'ActivityStart',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentRealtimeInput::ActivityStart'->new($_) };

declare 'RepeatedActivityStart',
    as ArrayRef[ActivityStart()];

coerce 'RepeatedActivityStart',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentRealtimeInput::ActivityStart'->new($_) } @$_ ] };

declare 'MapStringActivityStart',
    as HashRef[ActivityStart()];

declare 'ActivityEnd',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentRealtimeInput::ActivityEnd'];

coerce 'ActivityEnd',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentRealtimeInput::ActivityEnd'->new($_) };

declare 'RepeatedActivityEnd',
    as ArrayRef[ActivityEnd()];

coerce 'RepeatedActivityEnd',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentRealtimeInput::ActivityEnd'->new($_) } @$_ ] };

declare 'MapStringActivityEnd',
    as HashRef[ActivityEnd()];

declare 'BidiGenerateContentToolResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentToolResponse'];

coerce 'BidiGenerateContentToolResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentToolResponse'->new($_) };

declare 'RepeatedBidiGenerateContentToolResponse',
    as ArrayRef[BidiGenerateContentToolResponse()];

coerce 'RepeatedBidiGenerateContentToolResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentToolResponse'->new($_) } @$_ ] };

declare 'MapStringBidiGenerateContentToolResponse',
    as HashRef[BidiGenerateContentToolResponse()];

declare 'BidiGenerateContentClientMessage',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentClientMessage'];

coerce 'BidiGenerateContentClientMessage',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentClientMessage'->new($_) };

declare 'RepeatedBidiGenerateContentClientMessage',
    as ArrayRef[BidiGenerateContentClientMessage()];

coerce 'RepeatedBidiGenerateContentClientMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentClientMessage'->new($_) } @$_ ] };

declare 'MapStringBidiGenerateContentClientMessage',
    as HashRef[BidiGenerateContentClientMessage()];

declare 'BidiGenerateContentSetupComplete',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentSetupComplete'];

coerce 'BidiGenerateContentSetupComplete',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentSetupComplete'->new($_) };

declare 'RepeatedBidiGenerateContentSetupComplete',
    as ArrayRef[BidiGenerateContentSetupComplete()];

coerce 'RepeatedBidiGenerateContentSetupComplete',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentSetupComplete'->new($_) } @$_ ] };

declare 'MapStringBidiGenerateContentSetupComplete',
    as HashRef[BidiGenerateContentSetupComplete()];

declare 'BidiGenerateContentServerContent',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentServerContent'];

coerce 'BidiGenerateContentServerContent',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentServerContent'->new($_) };

declare 'RepeatedBidiGenerateContentServerContent',
    as ArrayRef[BidiGenerateContentServerContent()];

coerce 'RepeatedBidiGenerateContentServerContent',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentServerContent'->new($_) } @$_ ] };

declare 'MapStringBidiGenerateContentServerContent',
    as HashRef[BidiGenerateContentServerContent()];

declare 'BidiGenerateContentToolCall',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentToolCall'];

coerce 'BidiGenerateContentToolCall',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentToolCall'->new($_) };

declare 'RepeatedBidiGenerateContentToolCall',
    as ArrayRef[BidiGenerateContentToolCall()];

coerce 'RepeatedBidiGenerateContentToolCall',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentToolCall'->new($_) } @$_ ] };

declare 'MapStringBidiGenerateContentToolCall',
    as HashRef[BidiGenerateContentToolCall()];

declare 'BidiGenerateContentToolCallCancellation',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentToolCallCancellation'];

coerce 'BidiGenerateContentToolCallCancellation',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentToolCallCancellation'->new($_) };

declare 'RepeatedBidiGenerateContentToolCallCancellation',
    as ArrayRef[BidiGenerateContentToolCallCancellation()];

coerce 'RepeatedBidiGenerateContentToolCallCancellation',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentToolCallCancellation'->new($_) } @$_ ] };

declare 'MapStringBidiGenerateContentToolCallCancellation',
    as HashRef[BidiGenerateContentToolCallCancellation()];

declare 'GoAway',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::GoAway'];

coerce 'GoAway',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GoAway'->new($_) };

declare 'RepeatedGoAway',
    as ArrayRef[GoAway()];

coerce 'RepeatedGoAway',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GoAway'->new($_) } @$_ ] };

declare 'MapStringGoAway',
    as HashRef[GoAway()];

declare 'SessionResumptionUpdate',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::SessionResumptionUpdate'];

coerce 'SessionResumptionUpdate',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::SessionResumptionUpdate'->new($_) };

declare 'RepeatedSessionResumptionUpdate',
    as ArrayRef[SessionResumptionUpdate()];

coerce 'RepeatedSessionResumptionUpdate',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::SessionResumptionUpdate'->new($_) } @$_ ] };

declare 'MapStringSessionResumptionUpdate',
    as HashRef[SessionResumptionUpdate()];

declare 'BidiGenerateContentTranscription',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentTranscription'];

coerce 'BidiGenerateContentTranscription',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentTranscription'->new($_) };

declare 'RepeatedBidiGenerateContentTranscription',
    as ArrayRef[BidiGenerateContentTranscription()];

coerce 'RepeatedBidiGenerateContentTranscription',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentTranscription'->new($_) } @$_ ] };

declare 'MapStringBidiGenerateContentTranscription',
    as HashRef[BidiGenerateContentTranscription()];

declare 'BidiGenerateContentServerMessage',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentServerMessage'];

coerce 'BidiGenerateContentServerMessage',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentServerMessage'->new($_) };

declare 'RepeatedBidiGenerateContentServerMessage',
    as ArrayRef[BidiGenerateContentServerMessage()];

coerce 'RepeatedBidiGenerateContentServerMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentServerMessage'->new($_) } @$_ ] };

declare 'MapStringBidiGenerateContentServerMessage',
    as HashRef[BidiGenerateContentServerMessage()];

declare 'UsageMetadata',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::GenerativeService::UsageMetadata'];

coerce 'UsageMetadata',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::UsageMetadata'->new($_) };

declare 'RepeatedUsageMetadata',
    as ArrayRef[UsageMetadata()];

coerce 'RepeatedUsageMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::GenerativeService::UsageMetadata'->new($_) } @$_ ] };

declare 'MapStringUsageMetadata',
    as HashRef[UsageMetadata()];

1;

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1beta::GenerativeService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
