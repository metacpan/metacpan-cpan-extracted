package Google::Cloud::Discoveryengine::V1::Engine::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Engine',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Engine::Engine'];

coerce 'Engine',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Engine::Engine'->new($_) };

declare 'RepeatedEngine',
    as ArrayRef[Engine()];

coerce 'RepeatedEngine',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Engine::Engine'->new($_) } @$_ ] };

declare 'MapStringEngine',
    as HashRef[Engine()];

declare 'AppType',
    as (Int | Str);

declare 'FeatureState',
    as (Int | Str);

declare 'ConfigurableBillingApproach',
    as (Int | Str);

declare 'ModelState',
    as (Int | Str);

declare 'MarketplaceAgentVisibility',
    as (Int | Str);

declare 'SearchEngineConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Engine::Engine::SearchEngineConfig'];

coerce 'SearchEngineConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Engine::Engine::SearchEngineConfig'->new($_) };

declare 'RepeatedSearchEngineConfig',
    as ArrayRef[SearchEngineConfig()];

coerce 'RepeatedSearchEngineConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Engine::Engine::SearchEngineConfig'->new($_) } @$_ ] };

declare 'MapStringSearchEngineConfig',
    as HashRef[SearchEngineConfig()];

declare 'MediaRecommendationEngineConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Engine::Engine::MediaRecommendationEngineConfig'];

coerce 'MediaRecommendationEngineConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Engine::Engine::MediaRecommendationEngineConfig'->new($_) };

declare 'RepeatedMediaRecommendationEngineConfig',
    as ArrayRef[MediaRecommendationEngineConfig()];

coerce 'RepeatedMediaRecommendationEngineConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Engine::Engine::MediaRecommendationEngineConfig'->new($_) } @$_ ] };

declare 'MapStringMediaRecommendationEngineConfig',
    as HashRef[MediaRecommendationEngineConfig()];

declare 'TrainingState',
    as (Int | Str);

declare 'OptimizationObjectiveConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Engine::Engine::MediaRecommendationEngineConfig::OptimizationObjectiveConfig'];

coerce 'OptimizationObjectiveConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Engine::Engine::MediaRecommendationEngineConfig::OptimizationObjectiveConfig'->new($_) };

declare 'RepeatedOptimizationObjectiveConfig',
    as ArrayRef[OptimizationObjectiveConfig()];

coerce 'RepeatedOptimizationObjectiveConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Engine::Engine::MediaRecommendationEngineConfig::OptimizationObjectiveConfig'->new($_) } @$_ ] };

declare 'MapStringOptimizationObjectiveConfig',
    as HashRef[OptimizationObjectiveConfig()];

declare 'EngineFeaturesConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Engine::Engine::MediaRecommendationEngineConfig::EngineFeaturesConfig'];

coerce 'EngineFeaturesConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Engine::Engine::MediaRecommendationEngineConfig::EngineFeaturesConfig'->new($_) };

declare 'RepeatedEngineFeaturesConfig',
    as ArrayRef[EngineFeaturesConfig()];

coerce 'RepeatedEngineFeaturesConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Engine::Engine::MediaRecommendationEngineConfig::EngineFeaturesConfig'->new($_) } @$_ ] };

declare 'MapStringEngineFeaturesConfig',
    as HashRef[EngineFeaturesConfig()];

declare 'RecommendedForYouFeatureConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Engine::Engine::MediaRecommendationEngineConfig::RecommendedForYouFeatureConfig'];

coerce 'RecommendedForYouFeatureConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Engine::Engine::MediaRecommendationEngineConfig::RecommendedForYouFeatureConfig'->new($_) };

declare 'RepeatedRecommendedForYouFeatureConfig',
    as ArrayRef[RecommendedForYouFeatureConfig()];

coerce 'RepeatedRecommendedForYouFeatureConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Engine::Engine::MediaRecommendationEngineConfig::RecommendedForYouFeatureConfig'->new($_) } @$_ ] };

declare 'MapStringRecommendedForYouFeatureConfig',
    as HashRef[RecommendedForYouFeatureConfig()];

declare 'MostPopularFeatureConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Engine::Engine::MediaRecommendationEngineConfig::MostPopularFeatureConfig'];

coerce 'MostPopularFeatureConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Engine::Engine::MediaRecommendationEngineConfig::MostPopularFeatureConfig'->new($_) };

declare 'RepeatedMostPopularFeatureConfig',
    as ArrayRef[MostPopularFeatureConfig()];

coerce 'RepeatedMostPopularFeatureConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Engine::Engine::MediaRecommendationEngineConfig::MostPopularFeatureConfig'->new($_) } @$_ ] };

declare 'MapStringMostPopularFeatureConfig',
    as HashRef[MostPopularFeatureConfig()];

declare 'ChatEngineConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Engine::Engine::ChatEngineConfig'];

coerce 'ChatEngineConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Engine::Engine::ChatEngineConfig'->new($_) };

declare 'RepeatedChatEngineConfig',
    as ArrayRef[ChatEngineConfig()];

coerce 'RepeatedChatEngineConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Engine::Engine::ChatEngineConfig'->new($_) } @$_ ] };

declare 'MapStringChatEngineConfig',
    as HashRef[ChatEngineConfig()];

declare 'AgentCreationConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Engine::Engine::ChatEngineConfig::AgentCreationConfig'];

coerce 'AgentCreationConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Engine::Engine::ChatEngineConfig::AgentCreationConfig'->new($_) };

declare 'RepeatedAgentCreationConfig',
    as ArrayRef[AgentCreationConfig()];

coerce 'RepeatedAgentCreationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Engine::Engine::ChatEngineConfig::AgentCreationConfig'->new($_) } @$_ ] };

declare 'MapStringAgentCreationConfig',
    as HashRef[AgentCreationConfig()];

declare 'CommonConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Engine::Engine::CommonConfig'];

coerce 'CommonConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Engine::Engine::CommonConfig'->new($_) };

declare 'RepeatedCommonConfig',
    as ArrayRef[CommonConfig()];

coerce 'RepeatedCommonConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Engine::Engine::CommonConfig'->new($_) } @$_ ] };

declare 'MapStringCommonConfig',
    as HashRef[CommonConfig()];

declare 'KnowledgeGraphConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Engine::Engine::KnowledgeGraphConfig'];

coerce 'KnowledgeGraphConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Engine::Engine::KnowledgeGraphConfig'->new($_) };

declare 'RepeatedKnowledgeGraphConfig',
    as ArrayRef[KnowledgeGraphConfig()];

coerce 'RepeatedKnowledgeGraphConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Engine::Engine::KnowledgeGraphConfig'->new($_) } @$_ ] };

declare 'MapStringKnowledgeGraphConfig',
    as HashRef[KnowledgeGraphConfig()];

declare 'FeatureConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Engine::Engine::KnowledgeGraphConfig::FeatureConfig'];

coerce 'FeatureConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Engine::Engine::KnowledgeGraphConfig::FeatureConfig'->new($_) };

declare 'RepeatedFeatureConfig',
    as ArrayRef[FeatureConfig()];

coerce 'RepeatedFeatureConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Engine::Engine::KnowledgeGraphConfig::FeatureConfig'->new($_) } @$_ ] };

declare 'MapStringFeatureConfig',
    as HashRef[FeatureConfig()];

declare 'ChatEngineMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Engine::Engine::ChatEngineMetadata'];

coerce 'ChatEngineMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Engine::Engine::ChatEngineMetadata'->new($_) };

declare 'RepeatedChatEngineMetadata',
    as ArrayRef[ChatEngineMetadata()];

coerce 'RepeatedChatEngineMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Engine::Engine::ChatEngineMetadata'->new($_) } @$_ ] };

declare 'MapStringChatEngineMetadata',
    as HashRef[ChatEngineMetadata()];

declare 'FeaturesEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Engine::Engine::FeaturesEntry'];

coerce 'FeaturesEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Engine::Engine::FeaturesEntry'->new($_) };

declare 'RepeatedFeaturesEntry',
    as ArrayRef[FeaturesEntry()];

coerce 'RepeatedFeaturesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Engine::Engine::FeaturesEntry'->new($_) } @$_ ] };

declare 'MapStringFeaturesEntry',
    as HashRef[FeaturesEntry()];

declare 'ModelConfigsEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Engine::Engine::ModelConfigsEntry'];

coerce 'ModelConfigsEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Engine::Engine::ModelConfigsEntry'->new($_) };

declare 'RepeatedModelConfigsEntry',
    as ArrayRef[ModelConfigsEntry()];

coerce 'RepeatedModelConfigsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Engine::Engine::ModelConfigsEntry'->new($_) } @$_ ] };

declare 'MapStringModelConfigsEntry',
    as HashRef[ModelConfigsEntry()];

declare 'ConnectorTenantInfoEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Engine::Engine::ConnectorTenantInfoEntry'];

coerce 'ConnectorTenantInfoEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Engine::Engine::ConnectorTenantInfoEntry'->new($_) };

declare 'RepeatedConnectorTenantInfoEntry',
    as ArrayRef[ConnectorTenantInfoEntry()];

coerce 'RepeatedConnectorTenantInfoEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Engine::Engine::ConnectorTenantInfoEntry'->new($_) } @$_ ] };

declare 'MapStringConnectorTenantInfoEntry',
    as HashRef[ConnectorTenantInfoEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1::Engine::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
