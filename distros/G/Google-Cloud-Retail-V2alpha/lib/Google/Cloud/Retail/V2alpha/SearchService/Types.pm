package Google::Cloud::Retail::V2alpha::SearchService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ProductAttributeValue',
    as InstanceOf['Google::Cloud::Retail::V2alpha::SearchService::ProductAttributeValue'];

coerce 'ProductAttributeValue',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::SearchService::ProductAttributeValue'->new($_) };

declare 'RepeatedProductAttributeValue',
    as ArrayRef[ProductAttributeValue()];

coerce 'RepeatedProductAttributeValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::SearchService::ProductAttributeValue'->new($_) } @$_ ] };

declare 'MapStringProductAttributeValue',
    as HashRef[ProductAttributeValue()];

declare 'ProductAttributeInterval',
    as InstanceOf['Google::Cloud::Retail::V2alpha::SearchService::ProductAttributeInterval'];

coerce 'ProductAttributeInterval',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::SearchService::ProductAttributeInterval'->new($_) };

declare 'RepeatedProductAttributeInterval',
    as ArrayRef[ProductAttributeInterval()];

coerce 'RepeatedProductAttributeInterval',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::SearchService::ProductAttributeInterval'->new($_) } @$_ ] };

declare 'MapStringProductAttributeInterval',
    as HashRef[ProductAttributeInterval()];

declare 'Tile',
    as InstanceOf['Google::Cloud::Retail::V2alpha::SearchService::Tile'];

coerce 'Tile',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::SearchService::Tile'->new($_) };

declare 'RepeatedTile',
    as ArrayRef[Tile()];

coerce 'RepeatedTile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::SearchService::Tile'->new($_) } @$_ ] };

declare 'MapStringTile',
    as HashRef[Tile()];

declare 'SearchRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::SearchService::SearchRequest'];

coerce 'SearchRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::SearchService::SearchRequest'->new($_) };

declare 'RepeatedSearchRequest',
    as ArrayRef[SearchRequest()];

coerce 'RepeatedSearchRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::SearchService::SearchRequest'->new($_) } @$_ ] };

declare 'MapStringSearchRequest',
    as HashRef[SearchRequest()];

declare 'RelevanceThreshold',
    as (Int | Str);

declare 'SearchMode',
    as (Int | Str);

declare 'FacetSpec',
    as InstanceOf['Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::FacetSpec'];

coerce 'FacetSpec',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::FacetSpec'->new($_) };

declare 'RepeatedFacetSpec',
    as ArrayRef[FacetSpec()];

coerce 'RepeatedFacetSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::FacetSpec'->new($_) } @$_ ] };

declare 'MapStringFacetSpec',
    as HashRef[FacetSpec()];

declare 'FacetKey',
    as InstanceOf['Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::FacetSpec::FacetKey'];

coerce 'FacetKey',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::FacetSpec::FacetKey'->new($_) };

declare 'RepeatedFacetKey',
    as ArrayRef[FacetKey()];

coerce 'RepeatedFacetKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::FacetSpec::FacetKey'->new($_) } @$_ ] };

declare 'MapStringFacetKey',
    as HashRef[FacetKey()];

declare 'DynamicFacetSpec',
    as InstanceOf['Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::DynamicFacetSpec'];

coerce 'DynamicFacetSpec',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::DynamicFacetSpec'->new($_) };

declare 'RepeatedDynamicFacetSpec',
    as ArrayRef[DynamicFacetSpec()];

coerce 'RepeatedDynamicFacetSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::DynamicFacetSpec'->new($_) } @$_ ] };

declare 'MapStringDynamicFacetSpec',
    as HashRef[DynamicFacetSpec()];

declare 'Mode',
    as (Int | Str);

declare 'BoostSpec',
    as InstanceOf['Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::BoostSpec'];

coerce 'BoostSpec',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::BoostSpec'->new($_) };

declare 'RepeatedBoostSpec',
    as ArrayRef[BoostSpec()];

coerce 'RepeatedBoostSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::BoostSpec'->new($_) } @$_ ] };

declare 'MapStringBoostSpec',
    as HashRef[BoostSpec()];

declare 'ConditionBoostSpec',
    as InstanceOf['Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::BoostSpec::ConditionBoostSpec'];

coerce 'ConditionBoostSpec',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::BoostSpec::ConditionBoostSpec'->new($_) };

declare 'RepeatedConditionBoostSpec',
    as ArrayRef[ConditionBoostSpec()];

coerce 'RepeatedConditionBoostSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::BoostSpec::ConditionBoostSpec'->new($_) } @$_ ] };

declare 'MapStringConditionBoostSpec',
    as HashRef[ConditionBoostSpec()];

declare 'QueryExpansionSpec',
    as InstanceOf['Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::QueryExpansionSpec'];

coerce 'QueryExpansionSpec',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::QueryExpansionSpec'->new($_) };

declare 'RepeatedQueryExpansionSpec',
    as ArrayRef[QueryExpansionSpec()];

coerce 'RepeatedQueryExpansionSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::QueryExpansionSpec'->new($_) } @$_ ] };

declare 'MapStringQueryExpansionSpec',
    as HashRef[QueryExpansionSpec()];

declare 'Condition',
    as (Int | Str);

declare 'PersonalizationSpec',
    as InstanceOf['Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::PersonalizationSpec'];

coerce 'PersonalizationSpec',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::PersonalizationSpec'->new($_) };

declare 'RepeatedPersonalizationSpec',
    as ArrayRef[PersonalizationSpec()];

coerce 'RepeatedPersonalizationSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::PersonalizationSpec'->new($_) } @$_ ] };

declare 'MapStringPersonalizationSpec',
    as HashRef[PersonalizationSpec()];

declare 'Mode',
    as (Int | Str);

declare 'SpellCorrectionSpec',
    as InstanceOf['Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::SpellCorrectionSpec'];

coerce 'SpellCorrectionSpec',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::SpellCorrectionSpec'->new($_) };

declare 'RepeatedSpellCorrectionSpec',
    as ArrayRef[SpellCorrectionSpec()];

coerce 'RepeatedSpellCorrectionSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::SpellCorrectionSpec'->new($_) } @$_ ] };

declare 'MapStringSpellCorrectionSpec',
    as HashRef[SpellCorrectionSpec()];

declare 'Mode',
    as (Int | Str);

declare 'ConversationalSearchSpec',
    as InstanceOf['Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::ConversationalSearchSpec'];

coerce 'ConversationalSearchSpec',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::ConversationalSearchSpec'->new($_) };

declare 'RepeatedConversationalSearchSpec',
    as ArrayRef[ConversationalSearchSpec()];

coerce 'RepeatedConversationalSearchSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::ConversationalSearchSpec'->new($_) } @$_ ] };

declare 'MapStringConversationalSearchSpec',
    as HashRef[ConversationalSearchSpec()];

declare 'UserAnswer',
    as InstanceOf['Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::ConversationalSearchSpec::UserAnswer'];

coerce 'UserAnswer',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::ConversationalSearchSpec::UserAnswer'->new($_) };

declare 'RepeatedUserAnswer',
    as ArrayRef[UserAnswer()];

coerce 'RepeatedUserAnswer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::ConversationalSearchSpec::UserAnswer'->new($_) } @$_ ] };

declare 'MapStringUserAnswer',
    as HashRef[UserAnswer()];

declare 'SelectedAnswer',
    as InstanceOf['Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::ConversationalSearchSpec::UserAnswer::SelectedAnswer'];

coerce 'SelectedAnswer',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::ConversationalSearchSpec::UserAnswer::SelectedAnswer'->new($_) };

declare 'RepeatedSelectedAnswer',
    as ArrayRef[SelectedAnswer()];

coerce 'RepeatedSelectedAnswer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::ConversationalSearchSpec::UserAnswer::SelectedAnswer'->new($_) } @$_ ] };

declare 'MapStringSelectedAnswer',
    as HashRef[SelectedAnswer()];

declare 'TileNavigationSpec',
    as InstanceOf['Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::TileNavigationSpec'];

coerce 'TileNavigationSpec',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::TileNavigationSpec'->new($_) };

declare 'RepeatedTileNavigationSpec',
    as ArrayRef[TileNavigationSpec()];

coerce 'RepeatedTileNavigationSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::TileNavigationSpec'->new($_) } @$_ ] };

declare 'MapStringTileNavigationSpec',
    as HashRef[TileNavigationSpec()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'UserAttributesEntry',
    as InstanceOf['Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::UserAttributesEntry'];

coerce 'UserAttributesEntry',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::UserAttributesEntry'->new($_) };

declare 'RepeatedUserAttributesEntry',
    as ArrayRef[UserAttributesEntry()];

coerce 'RepeatedUserAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::SearchService::SearchRequest::UserAttributesEntry'->new($_) } @$_ ] };

declare 'MapStringUserAttributesEntry',
    as HashRef[UserAttributesEntry()];

declare 'SearchResponse',
    as InstanceOf['Google::Cloud::Retail::V2alpha::SearchService::SearchResponse'];

coerce 'SearchResponse',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::SearchService::SearchResponse'->new($_) };

declare 'RepeatedSearchResponse',
    as ArrayRef[SearchResponse()];

coerce 'RepeatedSearchResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::SearchService::SearchResponse'->new($_) } @$_ ] };

declare 'MapStringSearchResponse',
    as HashRef[SearchResponse()];

declare 'SearchResult',
    as InstanceOf['Google::Cloud::Retail::V2alpha::SearchService::SearchResponse::SearchResult'];

coerce 'SearchResult',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::SearchService::SearchResponse::SearchResult'->new($_) };

declare 'RepeatedSearchResult',
    as ArrayRef[SearchResult()];

coerce 'RepeatedSearchResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::SearchService::SearchResponse::SearchResult'->new($_) } @$_ ] };

declare 'MapStringSearchResult',
    as HashRef[SearchResult()];

declare 'MatchingVariantFieldsEntry',
    as InstanceOf['Google::Cloud::Retail::V2alpha::SearchService::SearchResponse::SearchResult::MatchingVariantFieldsEntry'];

coerce 'MatchingVariantFieldsEntry',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::SearchService::SearchResponse::SearchResult::MatchingVariantFieldsEntry'->new($_) };

declare 'RepeatedMatchingVariantFieldsEntry',
    as ArrayRef[MatchingVariantFieldsEntry()];

coerce 'RepeatedMatchingVariantFieldsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::SearchService::SearchResponse::SearchResult::MatchingVariantFieldsEntry'->new($_) } @$_ ] };

declare 'MapStringMatchingVariantFieldsEntry',
    as HashRef[MatchingVariantFieldsEntry()];

declare 'VariantRollupValuesEntry',
    as InstanceOf['Google::Cloud::Retail::V2alpha::SearchService::SearchResponse::SearchResult::VariantRollupValuesEntry'];

coerce 'VariantRollupValuesEntry',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::SearchService::SearchResponse::SearchResult::VariantRollupValuesEntry'->new($_) };

declare 'RepeatedVariantRollupValuesEntry',
    as ArrayRef[VariantRollupValuesEntry()];

coerce 'RepeatedVariantRollupValuesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::SearchService::SearchResponse::SearchResult::VariantRollupValuesEntry'->new($_) } @$_ ] };

declare 'MapStringVariantRollupValuesEntry',
    as HashRef[VariantRollupValuesEntry()];

declare 'ModelScoresEntry',
    as InstanceOf['Google::Cloud::Retail::V2alpha::SearchService::SearchResponse::SearchResult::ModelScoresEntry'];

coerce 'ModelScoresEntry',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::SearchService::SearchResponse::SearchResult::ModelScoresEntry'->new($_) };

declare 'RepeatedModelScoresEntry',
    as ArrayRef[ModelScoresEntry()];

coerce 'RepeatedModelScoresEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::SearchService::SearchResponse::SearchResult::ModelScoresEntry'->new($_) } @$_ ] };

declare 'MapStringModelScoresEntry',
    as HashRef[ModelScoresEntry()];

declare 'Facet',
    as InstanceOf['Google::Cloud::Retail::V2alpha::SearchService::SearchResponse::Facet'];

coerce 'Facet',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::SearchService::SearchResponse::Facet'->new($_) };

declare 'RepeatedFacet',
    as ArrayRef[Facet()];

coerce 'RepeatedFacet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::SearchService::SearchResponse::Facet'->new($_) } @$_ ] };

declare 'MapStringFacet',
    as HashRef[Facet()];

declare 'FacetValue',
    as InstanceOf['Google::Cloud::Retail::V2alpha::SearchService::SearchResponse::Facet::FacetValue'];

coerce 'FacetValue',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::SearchService::SearchResponse::Facet::FacetValue'->new($_) };

declare 'RepeatedFacetValue',
    as ArrayRef[FacetValue()];

coerce 'RepeatedFacetValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::SearchService::SearchResponse::Facet::FacetValue'->new($_) } @$_ ] };

declare 'MapStringFacetValue',
    as HashRef[FacetValue()];

declare 'QueryExpansionInfo',
    as InstanceOf['Google::Cloud::Retail::V2alpha::SearchService::SearchResponse::QueryExpansionInfo'];

coerce 'QueryExpansionInfo',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::SearchService::SearchResponse::QueryExpansionInfo'->new($_) };

declare 'RepeatedQueryExpansionInfo',
    as ArrayRef[QueryExpansionInfo()];

coerce 'RepeatedQueryExpansionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::SearchService::SearchResponse::QueryExpansionInfo'->new($_) } @$_ ] };

declare 'MapStringQueryExpansionInfo',
    as HashRef[QueryExpansionInfo()];

declare 'ConversationalSearchResult',
    as InstanceOf['Google::Cloud::Retail::V2alpha::SearchService::SearchResponse::ConversationalSearchResult'];

coerce 'ConversationalSearchResult',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::SearchService::SearchResponse::ConversationalSearchResult'->new($_) };

declare 'RepeatedConversationalSearchResult',
    as ArrayRef[ConversationalSearchResult()];

coerce 'RepeatedConversationalSearchResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::SearchService::SearchResponse::ConversationalSearchResult'->new($_) } @$_ ] };

declare 'MapStringConversationalSearchResult',
    as HashRef[ConversationalSearchResult()];

declare 'SuggestedAnswer',
    as InstanceOf['Google::Cloud::Retail::V2alpha::SearchService::SearchResponse::ConversationalSearchResult::SuggestedAnswer'];

coerce 'SuggestedAnswer',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::SearchService::SearchResponse::ConversationalSearchResult::SuggestedAnswer'->new($_) };

declare 'RepeatedSuggestedAnswer',
    as ArrayRef[SuggestedAnswer()];

coerce 'RepeatedSuggestedAnswer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::SearchService::SearchResponse::ConversationalSearchResult::SuggestedAnswer'->new($_) } @$_ ] };

declare 'MapStringSuggestedAnswer',
    as HashRef[SuggestedAnswer()];

declare 'AdditionalFilter',
    as InstanceOf['Google::Cloud::Retail::V2alpha::SearchService::SearchResponse::ConversationalSearchResult::AdditionalFilter'];

coerce 'AdditionalFilter',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::SearchService::SearchResponse::ConversationalSearchResult::AdditionalFilter'->new($_) };

declare 'RepeatedAdditionalFilter',
    as ArrayRef[AdditionalFilter()];

coerce 'RepeatedAdditionalFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::SearchService::SearchResponse::ConversationalSearchResult::AdditionalFilter'->new($_) } @$_ ] };

declare 'MapStringAdditionalFilter',
    as HashRef[AdditionalFilter()];

declare 'TileNavigationResult',
    as InstanceOf['Google::Cloud::Retail::V2alpha::SearchService::SearchResponse::TileNavigationResult'];

coerce 'TileNavigationResult',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::SearchService::SearchResponse::TileNavigationResult'->new($_) };

declare 'RepeatedTileNavigationResult',
    as ArrayRef[TileNavigationResult()];

coerce 'RepeatedTileNavigationResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::SearchService::SearchResponse::TileNavigationResult'->new($_) } @$_ ] };

declare 'MapStringTileNavigationResult',
    as HashRef[TileNavigationResult()];

declare 'ExperimentInfo',
    as InstanceOf['Google::Cloud::Retail::V2alpha::SearchService::ExperimentInfo'];

coerce 'ExperimentInfo',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::SearchService::ExperimentInfo'->new($_) };

declare 'RepeatedExperimentInfo',
    as ArrayRef[ExperimentInfo()];

coerce 'RepeatedExperimentInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::SearchService::ExperimentInfo'->new($_) } @$_ ] };

declare 'MapStringExperimentInfo',
    as HashRef[ExperimentInfo()];

declare 'ServingConfigExperiment',
    as InstanceOf['Google::Cloud::Retail::V2alpha::SearchService::ExperimentInfo::ServingConfigExperiment'];

coerce 'ServingConfigExperiment',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::SearchService::ExperimentInfo::ServingConfigExperiment'->new($_) };

declare 'RepeatedServingConfigExperiment',
    as ArrayRef[ServingConfigExperiment()];

coerce 'RepeatedServingConfigExperiment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::SearchService::ExperimentInfo::ServingConfigExperiment'->new($_) } @$_ ] };

declare 'MapStringServingConfigExperiment',
    as HashRef[ServingConfigExperiment()];

1;

__END__

=head1 NAME

Google::Cloud::Retail::V2alpha::SearchService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
