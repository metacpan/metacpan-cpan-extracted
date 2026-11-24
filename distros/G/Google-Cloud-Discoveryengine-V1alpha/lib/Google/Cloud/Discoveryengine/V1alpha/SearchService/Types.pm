package Google::Cloud::Discoveryengine::V1alpha::SearchService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SearchRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest'];

coerce 'SearchRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest'->new($_) };

declare 'RepeatedSearchRequest',
    as ArrayRef[SearchRequest()];

coerce 'RepeatedSearchRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest'->new($_) } @$_ ] };

declare 'MapStringSearchRequest',
    as HashRef[SearchRequest()];

declare 'RelevanceThreshold',
    as (Int | Str);

declare 'RankingExpressionBackend',
    as (Int | Str);

declare 'ImageQuery',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::ImageQuery'];

coerce 'ImageQuery',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::ImageQuery'->new($_) };

declare 'RepeatedImageQuery',
    as ArrayRef[ImageQuery()];

coerce 'RepeatedImageQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::ImageQuery'->new($_) } @$_ ] };

declare 'MapStringImageQuery',
    as HashRef[ImageQuery()];

declare 'DataStoreSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::DataStoreSpec'];

coerce 'DataStoreSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::DataStoreSpec'->new($_) };

declare 'RepeatedDataStoreSpec',
    as ArrayRef[DataStoreSpec()];

coerce 'RepeatedDataStoreSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::DataStoreSpec'->new($_) } @$_ ] };

declare 'MapStringDataStoreSpec',
    as HashRef[DataStoreSpec()];

declare 'FacetSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::FacetSpec'];

coerce 'FacetSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::FacetSpec'->new($_) };

declare 'RepeatedFacetSpec',
    as ArrayRef[FacetSpec()];

coerce 'RepeatedFacetSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::FacetSpec'->new($_) } @$_ ] };

declare 'MapStringFacetSpec',
    as HashRef[FacetSpec()];

declare 'FacetKey',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::FacetSpec::FacetKey'];

coerce 'FacetKey',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::FacetSpec::FacetKey'->new($_) };

declare 'RepeatedFacetKey',
    as ArrayRef[FacetKey()];

coerce 'RepeatedFacetKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::FacetSpec::FacetKey'->new($_) } @$_ ] };

declare 'MapStringFacetKey',
    as HashRef[FacetKey()];

declare 'BoostSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::BoostSpec'];

coerce 'BoostSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::BoostSpec'->new($_) };

declare 'RepeatedBoostSpec',
    as ArrayRef[BoostSpec()];

coerce 'RepeatedBoostSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::BoostSpec'->new($_) } @$_ ] };

declare 'MapStringBoostSpec',
    as HashRef[BoostSpec()];

declare 'ConditionBoostSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::BoostSpec::ConditionBoostSpec'];

coerce 'ConditionBoostSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::BoostSpec::ConditionBoostSpec'->new($_) };

declare 'RepeatedConditionBoostSpec',
    as ArrayRef[ConditionBoostSpec()];

coerce 'RepeatedConditionBoostSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::BoostSpec::ConditionBoostSpec'->new($_) } @$_ ] };

declare 'MapStringConditionBoostSpec',
    as HashRef[ConditionBoostSpec()];

declare 'BoostControlSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::BoostSpec::ConditionBoostSpec::BoostControlSpec'];

coerce 'BoostControlSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::BoostSpec::ConditionBoostSpec::BoostControlSpec'->new($_) };

declare 'RepeatedBoostControlSpec',
    as ArrayRef[BoostControlSpec()];

coerce 'RepeatedBoostControlSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::BoostSpec::ConditionBoostSpec::BoostControlSpec'->new($_) } @$_ ] };

declare 'MapStringBoostControlSpec',
    as HashRef[BoostControlSpec()];

declare 'AttributeType',
    as (Int | Str);

declare 'InterpolationType',
    as (Int | Str);

declare 'ControlPoint',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::BoostSpec::ConditionBoostSpec::BoostControlSpec::ControlPoint'];

coerce 'ControlPoint',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::BoostSpec::ConditionBoostSpec::BoostControlSpec::ControlPoint'->new($_) };

declare 'RepeatedControlPoint',
    as ArrayRef[ControlPoint()];

coerce 'RepeatedControlPoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::BoostSpec::ConditionBoostSpec::BoostControlSpec::ControlPoint'->new($_) } @$_ ] };

declare 'MapStringControlPoint',
    as HashRef[ControlPoint()];

declare 'QueryExpansionSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::QueryExpansionSpec'];

coerce 'QueryExpansionSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::QueryExpansionSpec'->new($_) };

declare 'RepeatedQueryExpansionSpec',
    as ArrayRef[QueryExpansionSpec()];

coerce 'RepeatedQueryExpansionSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::QueryExpansionSpec'->new($_) } @$_ ] };

declare 'MapStringQueryExpansionSpec',
    as HashRef[QueryExpansionSpec()];

declare 'Condition',
    as (Int | Str);

declare 'SpellCorrectionSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::SpellCorrectionSpec'];

coerce 'SpellCorrectionSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::SpellCorrectionSpec'->new($_) };

declare 'RepeatedSpellCorrectionSpec',
    as ArrayRef[SpellCorrectionSpec()];

coerce 'RepeatedSpellCorrectionSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::SpellCorrectionSpec'->new($_) } @$_ ] };

declare 'MapStringSpellCorrectionSpec',
    as HashRef[SpellCorrectionSpec()];

declare 'Mode',
    as (Int | Str);

declare 'ContentSearchSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::ContentSearchSpec'];

coerce 'ContentSearchSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::ContentSearchSpec'->new($_) };

declare 'RepeatedContentSearchSpec',
    as ArrayRef[ContentSearchSpec()];

coerce 'RepeatedContentSearchSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::ContentSearchSpec'->new($_) } @$_ ] };

declare 'MapStringContentSearchSpec',
    as HashRef[ContentSearchSpec()];

declare 'SearchResultMode',
    as (Int | Str);

declare 'SnippetSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::ContentSearchSpec::SnippetSpec'];

coerce 'SnippetSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::ContentSearchSpec::SnippetSpec'->new($_) };

declare 'RepeatedSnippetSpec',
    as ArrayRef[SnippetSpec()];

coerce 'RepeatedSnippetSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::ContentSearchSpec::SnippetSpec'->new($_) } @$_ ] };

declare 'MapStringSnippetSpec',
    as HashRef[SnippetSpec()];

declare 'SummarySpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::ContentSearchSpec::SummarySpec'];

coerce 'SummarySpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::ContentSearchSpec::SummarySpec'->new($_) };

declare 'RepeatedSummarySpec',
    as ArrayRef[SummarySpec()];

coerce 'RepeatedSummarySpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::ContentSearchSpec::SummarySpec'->new($_) } @$_ ] };

declare 'MapStringSummarySpec',
    as HashRef[SummarySpec()];

declare 'ModelPromptSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::ContentSearchSpec::SummarySpec::ModelPromptSpec'];

coerce 'ModelPromptSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::ContentSearchSpec::SummarySpec::ModelPromptSpec'->new($_) };

declare 'RepeatedModelPromptSpec',
    as ArrayRef[ModelPromptSpec()];

coerce 'RepeatedModelPromptSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::ContentSearchSpec::SummarySpec::ModelPromptSpec'->new($_) } @$_ ] };

declare 'MapStringModelPromptSpec',
    as HashRef[ModelPromptSpec()];

declare 'ModelSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::ContentSearchSpec::SummarySpec::ModelSpec'];

coerce 'ModelSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::ContentSearchSpec::SummarySpec::ModelSpec'->new($_) };

declare 'RepeatedModelSpec',
    as ArrayRef[ModelSpec()];

coerce 'RepeatedModelSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::ContentSearchSpec::SummarySpec::ModelSpec'->new($_) } @$_ ] };

declare 'MapStringModelSpec',
    as HashRef[ModelSpec()];

declare 'ExtractiveContentSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::ContentSearchSpec::ExtractiveContentSpec'];

coerce 'ExtractiveContentSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::ContentSearchSpec::ExtractiveContentSpec'->new($_) };

declare 'RepeatedExtractiveContentSpec',
    as ArrayRef[ExtractiveContentSpec()];

coerce 'RepeatedExtractiveContentSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::ContentSearchSpec::ExtractiveContentSpec'->new($_) } @$_ ] };

declare 'MapStringExtractiveContentSpec',
    as HashRef[ExtractiveContentSpec()];

declare 'ChunkSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::ContentSearchSpec::ChunkSpec'];

coerce 'ChunkSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::ContentSearchSpec::ChunkSpec'->new($_) };

declare 'RepeatedChunkSpec',
    as ArrayRef[ChunkSpec()];

coerce 'RepeatedChunkSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::ContentSearchSpec::ChunkSpec'->new($_) } @$_ ] };

declare 'MapStringChunkSpec',
    as HashRef[ChunkSpec()];

declare 'EmbeddingSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::EmbeddingSpec'];

coerce 'EmbeddingSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::EmbeddingSpec'->new($_) };

declare 'RepeatedEmbeddingSpec',
    as ArrayRef[EmbeddingSpec()];

coerce 'RepeatedEmbeddingSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::EmbeddingSpec'->new($_) } @$_ ] };

declare 'MapStringEmbeddingSpec',
    as HashRef[EmbeddingSpec()];

declare 'EmbeddingVector',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::EmbeddingSpec::EmbeddingVector'];

coerce 'EmbeddingVector',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::EmbeddingSpec::EmbeddingVector'->new($_) };

declare 'RepeatedEmbeddingVector',
    as ArrayRef[EmbeddingVector()];

coerce 'RepeatedEmbeddingVector',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::EmbeddingSpec::EmbeddingVector'->new($_) } @$_ ] };

declare 'MapStringEmbeddingVector',
    as HashRef[EmbeddingVector()];

declare 'NaturalLanguageQueryUnderstandingSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::NaturalLanguageQueryUnderstandingSpec'];

coerce 'NaturalLanguageQueryUnderstandingSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::NaturalLanguageQueryUnderstandingSpec'->new($_) };

declare 'RepeatedNaturalLanguageQueryUnderstandingSpec',
    as ArrayRef[NaturalLanguageQueryUnderstandingSpec()];

coerce 'RepeatedNaturalLanguageQueryUnderstandingSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::NaturalLanguageQueryUnderstandingSpec'->new($_) } @$_ ] };

declare 'MapStringNaturalLanguageQueryUnderstandingSpec',
    as HashRef[NaturalLanguageQueryUnderstandingSpec()];

declare 'FilterExtractionCondition',
    as (Int | Str);

declare 'SearchAsYouTypeSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::SearchAsYouTypeSpec'];

coerce 'SearchAsYouTypeSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::SearchAsYouTypeSpec'->new($_) };

declare 'RepeatedSearchAsYouTypeSpec',
    as ArrayRef[SearchAsYouTypeSpec()];

coerce 'RepeatedSearchAsYouTypeSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::SearchAsYouTypeSpec'->new($_) } @$_ ] };

declare 'MapStringSearchAsYouTypeSpec',
    as HashRef[SearchAsYouTypeSpec()];

declare 'Condition',
    as (Int | Str);

declare 'SessionSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::SessionSpec'];

coerce 'SessionSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::SessionSpec'->new($_) };

declare 'RepeatedSessionSpec',
    as ArrayRef[SessionSpec()];

coerce 'RepeatedSessionSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::SessionSpec'->new($_) } @$_ ] };

declare 'MapStringSessionSpec',
    as HashRef[SessionSpec()];

declare 'ParamsEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::ParamsEntry'];

coerce 'ParamsEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::ParamsEntry'->new($_) };

declare 'RepeatedParamsEntry',
    as ArrayRef[ParamsEntry()];

coerce 'RepeatedParamsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::ParamsEntry'->new($_) } @$_ ] };

declare 'MapStringParamsEntry',
    as HashRef[ParamsEntry()];

declare 'UserLabelsEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::UserLabelsEntry'];

coerce 'UserLabelsEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::UserLabelsEntry'->new($_) };

declare 'RepeatedUserLabelsEntry',
    as ArrayRef[UserLabelsEntry()];

coerce 'RepeatedUserLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchRequest::UserLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringUserLabelsEntry',
    as HashRef[UserLabelsEntry()];

declare 'SearchResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse'];

coerce 'SearchResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse'->new($_) };

declare 'RepeatedSearchResponse',
    as ArrayRef[SearchResponse()];

coerce 'RepeatedSearchResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse'->new($_) } @$_ ] };

declare 'MapStringSearchResponse',
    as HashRef[SearchResponse()];

declare 'SearchResult',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::SearchResult'];

coerce 'SearchResult',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::SearchResult'->new($_) };

declare 'RepeatedSearchResult',
    as ArrayRef[SearchResult()];

coerce 'RepeatedSearchResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::SearchResult'->new($_) } @$_ ] };

declare 'MapStringSearchResult',
    as HashRef[SearchResult()];

declare 'ModelScoresEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::SearchResult::ModelScoresEntry'];

coerce 'ModelScoresEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::SearchResult::ModelScoresEntry'->new($_) };

declare 'RepeatedModelScoresEntry',
    as ArrayRef[ModelScoresEntry()];

coerce 'RepeatedModelScoresEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::SearchResult::ModelScoresEntry'->new($_) } @$_ ] };

declare 'MapStringModelScoresEntry',
    as HashRef[ModelScoresEntry()];

declare 'RankSignals',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::SearchResult::RankSignals'];

coerce 'RankSignals',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::SearchResult::RankSignals'->new($_) };

declare 'RepeatedRankSignals',
    as ArrayRef[RankSignals()];

coerce 'RepeatedRankSignals',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::SearchResult::RankSignals'->new($_) } @$_ ] };

declare 'MapStringRankSignals',
    as HashRef[RankSignals()];

declare 'CustomSignal',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::SearchResult::RankSignals::CustomSignal'];

coerce 'CustomSignal',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::SearchResult::RankSignals::CustomSignal'->new($_) };

declare 'RepeatedCustomSignal',
    as ArrayRef[CustomSignal()];

coerce 'RepeatedCustomSignal',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::SearchResult::RankSignals::CustomSignal'->new($_) } @$_ ] };

declare 'MapStringCustomSignal',
    as HashRef[CustomSignal()];

declare 'Facet',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::Facet'];

coerce 'Facet',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::Facet'->new($_) };

declare 'RepeatedFacet',
    as ArrayRef[Facet()];

coerce 'RepeatedFacet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::Facet'->new($_) } @$_ ] };

declare 'MapStringFacet',
    as HashRef[Facet()];

declare 'FacetValue',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::Facet::FacetValue'];

coerce 'FacetValue',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::Facet::FacetValue'->new($_) };

declare 'RepeatedFacetValue',
    as ArrayRef[FacetValue()];

coerce 'RepeatedFacetValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::Facet::FacetValue'->new($_) } @$_ ] };

declare 'MapStringFacetValue',
    as HashRef[FacetValue()];

declare 'GuidedSearchResult',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::GuidedSearchResult'];

coerce 'GuidedSearchResult',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::GuidedSearchResult'->new($_) };

declare 'RepeatedGuidedSearchResult',
    as ArrayRef[GuidedSearchResult()];

coerce 'RepeatedGuidedSearchResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::GuidedSearchResult'->new($_) } @$_ ] };

declare 'MapStringGuidedSearchResult',
    as HashRef[GuidedSearchResult()];

declare 'RefinementAttribute',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::GuidedSearchResult::RefinementAttribute'];

coerce 'RefinementAttribute',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::GuidedSearchResult::RefinementAttribute'->new($_) };

declare 'RepeatedRefinementAttribute',
    as ArrayRef[RefinementAttribute()];

coerce 'RepeatedRefinementAttribute',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::GuidedSearchResult::RefinementAttribute'->new($_) } @$_ ] };

declare 'MapStringRefinementAttribute',
    as HashRef[RefinementAttribute()];

declare 'Summary',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::Summary'];

coerce 'Summary',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::Summary'->new($_) };

declare 'RepeatedSummary',
    as ArrayRef[Summary()];

coerce 'RepeatedSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::Summary'->new($_) } @$_ ] };

declare 'MapStringSummary',
    as HashRef[Summary()];

declare 'SummarySkippedReason',
    as (Int | Str);

declare 'SafetyAttributes',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::Summary::SafetyAttributes'];

coerce 'SafetyAttributes',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::Summary::SafetyAttributes'->new($_) };

declare 'RepeatedSafetyAttributes',
    as ArrayRef[SafetyAttributes()];

coerce 'RepeatedSafetyAttributes',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::Summary::SafetyAttributes'->new($_) } @$_ ] };

declare 'MapStringSafetyAttributes',
    as HashRef[SafetyAttributes()];

declare 'CitationMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::Summary::CitationMetadata'];

coerce 'CitationMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::Summary::CitationMetadata'->new($_) };

declare 'RepeatedCitationMetadata',
    as ArrayRef[CitationMetadata()];

coerce 'RepeatedCitationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::Summary::CitationMetadata'->new($_) } @$_ ] };

declare 'MapStringCitationMetadata',
    as HashRef[CitationMetadata()];

declare 'Citation',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::Summary::Citation'];

coerce 'Citation',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::Summary::Citation'->new($_) };

declare 'RepeatedCitation',
    as ArrayRef[Citation()];

coerce 'RepeatedCitation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::Summary::Citation'->new($_) } @$_ ] };

declare 'MapStringCitation',
    as HashRef[Citation()];

declare 'CitationSource',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::Summary::CitationSource'];

coerce 'CitationSource',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::Summary::CitationSource'->new($_) };

declare 'RepeatedCitationSource',
    as ArrayRef[CitationSource()];

coerce 'RepeatedCitationSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::Summary::CitationSource'->new($_) } @$_ ] };

declare 'MapStringCitationSource',
    as HashRef[CitationSource()];

declare 'Reference',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::Summary::Reference'];

coerce 'Reference',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::Summary::Reference'->new($_) };

declare 'RepeatedReference',
    as ArrayRef[Reference()];

coerce 'RepeatedReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::Summary::Reference'->new($_) } @$_ ] };

declare 'MapStringReference',
    as HashRef[Reference()];

declare 'ChunkContent',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::Summary::Reference::ChunkContent'];

coerce 'ChunkContent',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::Summary::Reference::ChunkContent'->new($_) };

declare 'RepeatedChunkContent',
    as ArrayRef[ChunkContent()];

coerce 'RepeatedChunkContent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::Summary::Reference::ChunkContent'->new($_) } @$_ ] };

declare 'MapStringChunkContent',
    as HashRef[ChunkContent()];

declare 'SummaryWithMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::Summary::SummaryWithMetadata'];

coerce 'SummaryWithMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::Summary::SummaryWithMetadata'->new($_) };

declare 'RepeatedSummaryWithMetadata',
    as ArrayRef[SummaryWithMetadata()];

coerce 'RepeatedSummaryWithMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::Summary::SummaryWithMetadata'->new($_) } @$_ ] };

declare 'MapStringSummaryWithMetadata',
    as HashRef[SummaryWithMetadata()];

declare 'GeoSearchDebugInfo',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::GeoSearchDebugInfo'];

coerce 'GeoSearchDebugInfo',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::GeoSearchDebugInfo'->new($_) };

declare 'RepeatedGeoSearchDebugInfo',
    as ArrayRef[GeoSearchDebugInfo()];

coerce 'RepeatedGeoSearchDebugInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::GeoSearchDebugInfo'->new($_) } @$_ ] };

declare 'MapStringGeoSearchDebugInfo',
    as HashRef[GeoSearchDebugInfo()];

declare 'QueryExpansionInfo',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::QueryExpansionInfo'];

coerce 'QueryExpansionInfo',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::QueryExpansionInfo'->new($_) };

declare 'RepeatedQueryExpansionInfo',
    as ArrayRef[QueryExpansionInfo()];

coerce 'RepeatedQueryExpansionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::QueryExpansionInfo'->new($_) } @$_ ] };

declare 'MapStringQueryExpansionInfo',
    as HashRef[QueryExpansionInfo()];

declare 'NaturalLanguageQueryUnderstandingInfo',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::NaturalLanguageQueryUnderstandingInfo'];

coerce 'NaturalLanguageQueryUnderstandingInfo',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::NaturalLanguageQueryUnderstandingInfo'->new($_) };

declare 'RepeatedNaturalLanguageQueryUnderstandingInfo',
    as ArrayRef[NaturalLanguageQueryUnderstandingInfo()];

coerce 'RepeatedNaturalLanguageQueryUnderstandingInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::NaturalLanguageQueryUnderstandingInfo'->new($_) } @$_ ] };

declare 'MapStringNaturalLanguageQueryUnderstandingInfo',
    as HashRef[NaturalLanguageQueryUnderstandingInfo()];

declare 'StructuredExtractedFilter',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::NaturalLanguageQueryUnderstandingInfo::StructuredExtractedFilter'];

coerce 'StructuredExtractedFilter',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::NaturalLanguageQueryUnderstandingInfo::StructuredExtractedFilter'->new($_) };

declare 'RepeatedStructuredExtractedFilter',
    as ArrayRef[StructuredExtractedFilter()];

coerce 'RepeatedStructuredExtractedFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::NaturalLanguageQueryUnderstandingInfo::StructuredExtractedFilter'->new($_) } @$_ ] };

declare 'MapStringStructuredExtractedFilter',
    as HashRef[StructuredExtractedFilter()];

declare 'StringConstraint',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::NaturalLanguageQueryUnderstandingInfo::StructuredExtractedFilter::StringConstraint'];

coerce 'StringConstraint',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::NaturalLanguageQueryUnderstandingInfo::StructuredExtractedFilter::StringConstraint'->new($_) };

declare 'RepeatedStringConstraint',
    as ArrayRef[StringConstraint()];

coerce 'RepeatedStringConstraint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::NaturalLanguageQueryUnderstandingInfo::StructuredExtractedFilter::StringConstraint'->new($_) } @$_ ] };

declare 'MapStringStringConstraint',
    as HashRef[StringConstraint()];

declare 'NumberConstraint',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::NaturalLanguageQueryUnderstandingInfo::StructuredExtractedFilter::NumberConstraint'];

coerce 'NumberConstraint',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::NaturalLanguageQueryUnderstandingInfo::StructuredExtractedFilter::NumberConstraint'->new($_) };

declare 'RepeatedNumberConstraint',
    as ArrayRef[NumberConstraint()];

coerce 'RepeatedNumberConstraint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::NaturalLanguageQueryUnderstandingInfo::StructuredExtractedFilter::NumberConstraint'->new($_) } @$_ ] };

declare 'MapStringNumberConstraint',
    as HashRef[NumberConstraint()];

declare 'Comparison',
    as (Int | Str);

declare 'GeolocationConstraint',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::NaturalLanguageQueryUnderstandingInfo::StructuredExtractedFilter::GeolocationConstraint'];

coerce 'GeolocationConstraint',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::NaturalLanguageQueryUnderstandingInfo::StructuredExtractedFilter::GeolocationConstraint'->new($_) };

declare 'RepeatedGeolocationConstraint',
    as ArrayRef[GeolocationConstraint()];

coerce 'RepeatedGeolocationConstraint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::NaturalLanguageQueryUnderstandingInfo::StructuredExtractedFilter::GeolocationConstraint'->new($_) } @$_ ] };

declare 'MapStringGeolocationConstraint',
    as HashRef[GeolocationConstraint()];

declare 'AndExpression',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::NaturalLanguageQueryUnderstandingInfo::StructuredExtractedFilter::AndExpression'];

coerce 'AndExpression',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::NaturalLanguageQueryUnderstandingInfo::StructuredExtractedFilter::AndExpression'->new($_) };

declare 'RepeatedAndExpression',
    as ArrayRef[AndExpression()];

coerce 'RepeatedAndExpression',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::NaturalLanguageQueryUnderstandingInfo::StructuredExtractedFilter::AndExpression'->new($_) } @$_ ] };

declare 'MapStringAndExpression',
    as HashRef[AndExpression()];

declare 'OrExpression',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::NaturalLanguageQueryUnderstandingInfo::StructuredExtractedFilter::OrExpression'];

coerce 'OrExpression',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::NaturalLanguageQueryUnderstandingInfo::StructuredExtractedFilter::OrExpression'->new($_) };

declare 'RepeatedOrExpression',
    as ArrayRef[OrExpression()];

coerce 'RepeatedOrExpression',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::NaturalLanguageQueryUnderstandingInfo::StructuredExtractedFilter::OrExpression'->new($_) } @$_ ] };

declare 'MapStringOrExpression',
    as HashRef[OrExpression()];

declare 'Expression',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::NaturalLanguageQueryUnderstandingInfo::StructuredExtractedFilter::Expression'];

coerce 'Expression',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::NaturalLanguageQueryUnderstandingInfo::StructuredExtractedFilter::Expression'->new($_) };

declare 'RepeatedExpression',
    as ArrayRef[Expression()];

coerce 'RepeatedExpression',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::NaturalLanguageQueryUnderstandingInfo::StructuredExtractedFilter::Expression'->new($_) } @$_ ] };

declare 'MapStringExpression',
    as HashRef[Expression()];

declare 'SessionInfo',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::SessionInfo'];

coerce 'SessionInfo',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::SessionInfo'->new($_) };

declare 'RepeatedSessionInfo',
    as ArrayRef[SessionInfo()];

coerce 'RepeatedSessionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::SessionInfo'->new($_) } @$_ ] };

declare 'MapStringSessionInfo',
    as HashRef[SessionInfo()];

declare 'OneBoxResult',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::OneBoxResult'];

coerce 'OneBoxResult',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::OneBoxResult'->new($_) };

declare 'RepeatedOneBoxResult',
    as ArrayRef[OneBoxResult()];

coerce 'RepeatedOneBoxResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::SearchService::SearchResponse::OneBoxResult'->new($_) } @$_ ] };

declare 'MapStringOneBoxResult',
    as HashRef[OneBoxResult()];

declare 'OneBoxType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::SearchService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
