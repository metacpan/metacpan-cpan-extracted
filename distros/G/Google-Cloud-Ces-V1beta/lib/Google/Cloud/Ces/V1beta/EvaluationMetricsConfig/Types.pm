package Google::Cloud::Ces::V1beta::EvaluationMetricsConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EvaluationMetricsConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationMetricsConfig::EvaluationMetricsConfig'];

coerce 'EvaluationMetricsConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationMetricsConfig::EvaluationMetricsConfig'->new($_) };

declare 'RepeatedEvaluationMetricsConfig',
    as ArrayRef[EvaluationMetricsConfig()];

coerce 'RepeatedEvaluationMetricsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationMetricsConfig::EvaluationMetricsConfig'->new($_) } @$_ ] };

declare 'MapStringEvaluationMetricsConfig',
    as HashRef[EvaluationMetricsConfig()];

declare 'ComparisonType',
    as (Int | Str);

declare 'SemanticSimilarityMetricsConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationMetricsConfig::EvaluationMetricsConfig::SemanticSimilarityMetricsConfig'];

coerce 'SemanticSimilarityMetricsConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationMetricsConfig::EvaluationMetricsConfig::SemanticSimilarityMetricsConfig'->new($_) };

declare 'RepeatedSemanticSimilarityMetricsConfig',
    as ArrayRef[SemanticSimilarityMetricsConfig()];

coerce 'RepeatedSemanticSimilarityMetricsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationMetricsConfig::EvaluationMetricsConfig::SemanticSimilarityMetricsConfig'->new($_) } @$_ ] };

declare 'MapStringSemanticSimilarityMetricsConfig',
    as HashRef[SemanticSimilarityMetricsConfig()];

declare 'ToolCorrectnessMetricsConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationMetricsConfig::EvaluationMetricsConfig::ToolCorrectnessMetricsConfig'];

coerce 'ToolCorrectnessMetricsConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationMetricsConfig::EvaluationMetricsConfig::ToolCorrectnessMetricsConfig'->new($_) };

declare 'RepeatedToolCorrectnessMetricsConfig',
    as ArrayRef[ToolCorrectnessMetricsConfig()];

coerce 'RepeatedToolCorrectnessMetricsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationMetricsConfig::EvaluationMetricsConfig::ToolCorrectnessMetricsConfig'->new($_) } @$_ ] };

declare 'MapStringToolCorrectnessMetricsConfig',
    as HashRef[ToolCorrectnessMetricsConfig()];

declare 'HallucinationMetricsConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationMetricsConfig::EvaluationMetricsConfig::HallucinationMetricsConfig'];

coerce 'HallucinationMetricsConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationMetricsConfig::EvaluationMetricsConfig::HallucinationMetricsConfig'->new($_) };

declare 'RepeatedHallucinationMetricsConfig',
    as ArrayRef[HallucinationMetricsConfig()];

coerce 'RepeatedHallucinationMetricsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationMetricsConfig::EvaluationMetricsConfig::HallucinationMetricsConfig'->new($_) } @$_ ] };

declare 'MapStringHallucinationMetricsConfig',
    as HashRef[HallucinationMetricsConfig()];

declare 'UserGoalMetMetricsConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationMetricsConfig::EvaluationMetricsConfig::UserGoalMetMetricsConfig'];

coerce 'UserGoalMetMetricsConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationMetricsConfig::EvaluationMetricsConfig::UserGoalMetMetricsConfig'->new($_) };

declare 'RepeatedUserGoalMetMetricsConfig',
    as ArrayRef[UserGoalMetMetricsConfig()];

coerce 'RepeatedUserGoalMetMetricsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationMetricsConfig::EvaluationMetricsConfig::UserGoalMetMetricsConfig'->new($_) } @$_ ] };

declare 'MapStringUserGoalMetMetricsConfig',
    as HashRef[UserGoalMetMetricsConfig()];

declare 'ExpectationsMetMetricsConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationMetricsConfig::EvaluationMetricsConfig::ExpectationsMetMetricsConfig'];

coerce 'ExpectationsMetMetricsConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationMetricsConfig::EvaluationMetricsConfig::ExpectationsMetMetricsConfig'->new($_) };

declare 'RepeatedExpectationsMetMetricsConfig',
    as ArrayRef[ExpectationsMetMetricsConfig()];

coerce 'RepeatedExpectationsMetMetricsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationMetricsConfig::EvaluationMetricsConfig::ExpectationsMetMetricsConfig'->new($_) } @$_ ] };

declare 'MapStringExpectationsMetMetricsConfig',
    as HashRef[ExpectationsMetMetricsConfig()];

declare 'GoldenMetricsConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationMetricsConfig::EvaluationMetricsConfig::GoldenMetricsConfig'];

coerce 'GoldenMetricsConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationMetricsConfig::EvaluationMetricsConfig::GoldenMetricsConfig'->new($_) };

declare 'RepeatedGoldenMetricsConfig',
    as ArrayRef[GoldenMetricsConfig()];

coerce 'RepeatedGoldenMetricsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationMetricsConfig::EvaluationMetricsConfig::GoldenMetricsConfig'->new($_) } @$_ ] };

declare 'MapStringGoldenMetricsConfig',
    as HashRef[GoldenMetricsConfig()];

declare 'ScenarioMetricsConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationMetricsConfig::EvaluationMetricsConfig::ScenarioMetricsConfig'];

coerce 'ScenarioMetricsConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationMetricsConfig::EvaluationMetricsConfig::ScenarioMetricsConfig'->new($_) };

declare 'RepeatedScenarioMetricsConfig',
    as ArrayRef[ScenarioMetricsConfig()];

coerce 'RepeatedScenarioMetricsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationMetricsConfig::EvaluationMetricsConfig::ScenarioMetricsConfig'->new($_) } @$_ ] };

declare 'MapStringScenarioMetricsConfig',
    as HashRef[ScenarioMetricsConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1beta::EvaluationMetricsConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
