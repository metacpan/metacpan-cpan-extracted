package Google::Cloud::Discoveryengine::V1alpha::Engine::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Engine',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Engine::Engine'];

coerce 'Engine',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Engine::Engine'->new($_) };

declare 'RepeatedEngine',
    as ArrayRef[Engine()];

coerce 'RepeatedEngine',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Engine::Engine'->new($_) } @$_ ] };

declare 'MapStringEngine',
    as HashRef[Engine()];

declare 'SearchEngineConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Engine::Engine::SearchEngineConfig'];

coerce 'SearchEngineConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Engine::Engine::SearchEngineConfig'->new($_) };

declare 'RepeatedSearchEngineConfig',
    as ArrayRef[SearchEngineConfig()];

coerce 'RepeatedSearchEngineConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Engine::Engine::SearchEngineConfig'->new($_) } @$_ ] };

declare 'MapStringSearchEngineConfig',
    as HashRef[SearchEngineConfig()];

declare 'SimilarDocumentsEngineConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Engine::Engine::SimilarDocumentsEngineConfig'];

coerce 'SimilarDocumentsEngineConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Engine::Engine::SimilarDocumentsEngineConfig'->new($_) };

declare 'RepeatedSimilarDocumentsEngineConfig',
    as ArrayRef[SimilarDocumentsEngineConfig()];

coerce 'RepeatedSimilarDocumentsEngineConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Engine::Engine::SimilarDocumentsEngineConfig'->new($_) } @$_ ] };

declare 'MapStringSimilarDocumentsEngineConfig',
    as HashRef[SimilarDocumentsEngineConfig()];

declare 'MediaRecommendationEngineConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Engine::Engine::MediaRecommendationEngineConfig'];

coerce 'MediaRecommendationEngineConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Engine::Engine::MediaRecommendationEngineConfig'->new($_) };

declare 'RepeatedMediaRecommendationEngineConfig',
    as ArrayRef[MediaRecommendationEngineConfig()];

coerce 'RepeatedMediaRecommendationEngineConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Engine::Engine::MediaRecommendationEngineConfig'->new($_) } @$_ ] };

declare 'MapStringMediaRecommendationEngineConfig',
    as HashRef[MediaRecommendationEngineConfig()];

declare 'TrainingState',
    as (Int | Str);

declare 'OptimizationObjectiveConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Engine::Engine::MediaRecommendationEngineConfig::OptimizationObjectiveConfig'];

coerce 'OptimizationObjectiveConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Engine::Engine::MediaRecommendationEngineConfig::OptimizationObjectiveConfig'->new($_) };

declare 'RepeatedOptimizationObjectiveConfig',
    as ArrayRef[OptimizationObjectiveConfig()];

coerce 'RepeatedOptimizationObjectiveConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Engine::Engine::MediaRecommendationEngineConfig::OptimizationObjectiveConfig'->new($_) } @$_ ] };

declare 'MapStringOptimizationObjectiveConfig',
    as HashRef[OptimizationObjectiveConfig()];

declare 'ChatEngineConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Engine::Engine::ChatEngineConfig'];

coerce 'ChatEngineConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Engine::Engine::ChatEngineConfig'->new($_) };

declare 'RepeatedChatEngineConfig',
    as ArrayRef[ChatEngineConfig()];

coerce 'RepeatedChatEngineConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Engine::Engine::ChatEngineConfig'->new($_) } @$_ ] };

declare 'MapStringChatEngineConfig',
    as HashRef[ChatEngineConfig()];

declare 'AgentCreationConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Engine::Engine::ChatEngineConfig::AgentCreationConfig'];

coerce 'AgentCreationConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Engine::Engine::ChatEngineConfig::AgentCreationConfig'->new($_) };

declare 'RepeatedAgentCreationConfig',
    as ArrayRef[AgentCreationConfig()];

coerce 'RepeatedAgentCreationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Engine::Engine::ChatEngineConfig::AgentCreationConfig'->new($_) } @$_ ] };

declare 'MapStringAgentCreationConfig',
    as HashRef[AgentCreationConfig()];

declare 'CommonConfig',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Engine::Engine::CommonConfig'];

coerce 'CommonConfig',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Engine::Engine::CommonConfig'->new($_) };

declare 'RepeatedCommonConfig',
    as ArrayRef[CommonConfig()];

coerce 'RepeatedCommonConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Engine::Engine::CommonConfig'->new($_) } @$_ ] };

declare 'MapStringCommonConfig',
    as HashRef[CommonConfig()];

declare 'RecommendationMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Engine::Engine::RecommendationMetadata'];

coerce 'RecommendationMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Engine::Engine::RecommendationMetadata'->new($_) };

declare 'RepeatedRecommendationMetadata',
    as ArrayRef[RecommendationMetadata()];

coerce 'RepeatedRecommendationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Engine::Engine::RecommendationMetadata'->new($_) } @$_ ] };

declare 'MapStringRecommendationMetadata',
    as HashRef[RecommendationMetadata()];

declare 'ServingState',
    as (Int | Str);

declare 'DataState',
    as (Int | Str);

declare 'ChatEngineMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Engine::Engine::ChatEngineMetadata'];

coerce 'ChatEngineMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Engine::Engine::ChatEngineMetadata'->new($_) };

declare 'RepeatedChatEngineMetadata',
    as ArrayRef[ChatEngineMetadata()];

coerce 'RepeatedChatEngineMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Engine::Engine::ChatEngineMetadata'->new($_) } @$_ ] };

declare 'MapStringChatEngineMetadata',
    as HashRef[ChatEngineMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::Engine::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
