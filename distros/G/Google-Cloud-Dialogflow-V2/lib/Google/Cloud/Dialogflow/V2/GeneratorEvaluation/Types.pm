package Google::Cloud::Dialogflow::V2::GeneratorEvaluation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateGeneratorEvaluationRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::GeneratorEvaluation::CreateGeneratorEvaluationRequest'];

coerce 'CreateGeneratorEvaluationRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::CreateGeneratorEvaluationRequest'->new($_) };

declare 'RepeatedCreateGeneratorEvaluationRequest',
    as ArrayRef[CreateGeneratorEvaluationRequest()];

coerce 'RepeatedCreateGeneratorEvaluationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::CreateGeneratorEvaluationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateGeneratorEvaluationRequest',
    as HashRef[CreateGeneratorEvaluationRequest()];

declare 'GetGeneratorEvaluationRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::GeneratorEvaluation::GetGeneratorEvaluationRequest'];

coerce 'GetGeneratorEvaluationRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::GetGeneratorEvaluationRequest'->new($_) };

declare 'RepeatedGetGeneratorEvaluationRequest',
    as ArrayRef[GetGeneratorEvaluationRequest()];

coerce 'RepeatedGetGeneratorEvaluationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::GetGeneratorEvaluationRequest'->new($_) } @$_ ] };

declare 'MapStringGetGeneratorEvaluationRequest',
    as HashRef[GetGeneratorEvaluationRequest()];

declare 'ListGeneratorEvaluationsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::GeneratorEvaluation::ListGeneratorEvaluationsRequest'];

coerce 'ListGeneratorEvaluationsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::ListGeneratorEvaluationsRequest'->new($_) };

declare 'RepeatedListGeneratorEvaluationsRequest',
    as ArrayRef[ListGeneratorEvaluationsRequest()];

coerce 'RepeatedListGeneratorEvaluationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::ListGeneratorEvaluationsRequest'->new($_) } @$_ ] };

declare 'MapStringListGeneratorEvaluationsRequest',
    as HashRef[ListGeneratorEvaluationsRequest()];

declare 'ListGeneratorEvaluationsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2::GeneratorEvaluation::ListGeneratorEvaluationsResponse'];

coerce 'ListGeneratorEvaluationsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::ListGeneratorEvaluationsResponse'->new($_) };

declare 'RepeatedListGeneratorEvaluationsResponse',
    as ArrayRef[ListGeneratorEvaluationsResponse()];

coerce 'RepeatedListGeneratorEvaluationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::ListGeneratorEvaluationsResponse'->new($_) } @$_ ] };

declare 'MapStringListGeneratorEvaluationsResponse',
    as HashRef[ListGeneratorEvaluationsResponse()];

declare 'DeleteGeneratorEvaluationRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::GeneratorEvaluation::DeleteGeneratorEvaluationRequest'];

coerce 'DeleteGeneratorEvaluationRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::DeleteGeneratorEvaluationRequest'->new($_) };

declare 'RepeatedDeleteGeneratorEvaluationRequest',
    as ArrayRef[DeleteGeneratorEvaluationRequest()];

coerce 'RepeatedDeleteGeneratorEvaluationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::DeleteGeneratorEvaluationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteGeneratorEvaluationRequest',
    as HashRef[DeleteGeneratorEvaluationRequest()];

declare 'GeneratorEvaluation',
    as InstanceOf['Google::Cloud::Dialogflow::V2::GeneratorEvaluation::GeneratorEvaluation'];

coerce 'GeneratorEvaluation',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::GeneratorEvaluation'->new($_) };

declare 'RepeatedGeneratorEvaluation',
    as ArrayRef[GeneratorEvaluation()];

coerce 'RepeatedGeneratorEvaluation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::GeneratorEvaluation'->new($_) } @$_ ] };

declare 'MapStringGeneratorEvaluation',
    as HashRef[GeneratorEvaluation()];

declare 'SummarizationEvaluationMetrics',
    as InstanceOf['Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics'];

coerce 'SummarizationEvaluationMetrics',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics'->new($_) };

declare 'RepeatedSummarizationEvaluationMetrics',
    as ArrayRef[SummarizationEvaluationMetrics()];

coerce 'RepeatedSummarizationEvaluationMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics'->new($_) } @$_ ] };

declare 'MapStringSummarizationEvaluationMetrics',
    as HashRef[SummarizationEvaluationMetrics()];

declare 'AccuracyDecomposition',
    as InstanceOf['Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::AccuracyDecomposition'];

coerce 'AccuracyDecomposition',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::AccuracyDecomposition'->new($_) };

declare 'RepeatedAccuracyDecomposition',
    as ArrayRef[AccuracyDecomposition()];

coerce 'RepeatedAccuracyDecomposition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::AccuracyDecomposition'->new($_) } @$_ ] };

declare 'MapStringAccuracyDecomposition',
    as HashRef[AccuracyDecomposition()];

declare 'AdherenceDecomposition',
    as InstanceOf['Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::AdherenceDecomposition'];

coerce 'AdherenceDecomposition',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::AdherenceDecomposition'->new($_) };

declare 'RepeatedAdherenceDecomposition',
    as ArrayRef[AdherenceDecomposition()];

coerce 'RepeatedAdherenceDecomposition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::AdherenceDecomposition'->new($_) } @$_ ] };

declare 'MapStringAdherenceDecomposition',
    as HashRef[AdherenceDecomposition()];

declare 'AdherenceRubric',
    as InstanceOf['Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::AdherenceRubric'];

coerce 'AdherenceRubric',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::AdherenceRubric'->new($_) };

declare 'RepeatedAdherenceRubric',
    as ArrayRef[AdherenceRubric()];

coerce 'RepeatedAdherenceRubric',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::AdherenceRubric'->new($_) } @$_ ] };

declare 'MapStringAdherenceRubric',
    as HashRef[AdherenceRubric()];

declare 'CompletenessRubric',
    as InstanceOf['Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::CompletenessRubric'];

coerce 'CompletenessRubric',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::CompletenessRubric'->new($_) };

declare 'RepeatedCompletenessRubric',
    as ArrayRef[CompletenessRubric()];

coerce 'RepeatedCompletenessRubric',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::CompletenessRubric'->new($_) } @$_ ] };

declare 'MapStringCompletenessRubric',
    as HashRef[CompletenessRubric()];

declare 'Decomposition',
    as InstanceOf['Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::Decomposition'];

coerce 'Decomposition',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::Decomposition'->new($_) };

declare 'RepeatedDecomposition',
    as ArrayRef[Decomposition()];

coerce 'RepeatedDecomposition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::Decomposition'->new($_) } @$_ ] };

declare 'MapStringDecomposition',
    as HashRef[Decomposition()];

declare 'EvaluationResult',
    as InstanceOf['Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::EvaluationResult'];

coerce 'EvaluationResult',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::EvaluationResult'->new($_) };

declare 'RepeatedEvaluationResult',
    as ArrayRef[EvaluationResult()];

coerce 'RepeatedEvaluationResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::EvaluationResult'->new($_) } @$_ ] };

declare 'MapStringEvaluationResult',
    as HashRef[EvaluationResult()];

declare 'SummarizationEvaluationResult',
    as InstanceOf['Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::SummarizationEvaluationResult'];

coerce 'SummarizationEvaluationResult',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::SummarizationEvaluationResult'->new($_) };

declare 'RepeatedSummarizationEvaluationResult',
    as ArrayRef[SummarizationEvaluationResult()];

coerce 'RepeatedSummarizationEvaluationResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::SummarizationEvaluationResult'->new($_) } @$_ ] };

declare 'MapStringSummarizationEvaluationResult',
    as HashRef[SummarizationEvaluationResult()];

declare 'OverallScoresByMetric',
    as InstanceOf['Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::OverallScoresByMetric'];

coerce 'OverallScoresByMetric',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::OverallScoresByMetric'->new($_) };

declare 'RepeatedOverallScoresByMetric',
    as ArrayRef[OverallScoresByMetric()];

coerce 'RepeatedOverallScoresByMetric',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::OverallScoresByMetric'->new($_) } @$_ ] };

declare 'MapStringOverallScoresByMetric',
    as HashRef[OverallScoresByMetric()];

declare 'SectionToken',
    as InstanceOf['Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::SectionToken'];

coerce 'SectionToken',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::SectionToken'->new($_) };

declare 'RepeatedSectionToken',
    as ArrayRef[SectionToken()];

coerce 'RepeatedSectionToken',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::SectionToken'->new($_) } @$_ ] };

declare 'MapStringSectionToken',
    as HashRef[SectionToken()];

declare 'ConversationDetail',
    as InstanceOf['Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::ConversationDetail'];

coerce 'ConversationDetail',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::ConversationDetail'->new($_) };

declare 'RepeatedConversationDetail',
    as ArrayRef[ConversationDetail()];

coerce 'RepeatedConversationDetail',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::ConversationDetail'->new($_) } @$_ ] };

declare 'MapStringConversationDetail',
    as HashRef[ConversationDetail()];

declare 'MetricDetail',
    as InstanceOf['Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::ConversationDetail::MetricDetail'];

coerce 'MetricDetail',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::ConversationDetail::MetricDetail'->new($_) };

declare 'RepeatedMetricDetail',
    as ArrayRef[MetricDetail()];

coerce 'RepeatedMetricDetail',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::ConversationDetail::MetricDetail'->new($_) } @$_ ] };

declare 'MapStringMetricDetail',
    as HashRef[MetricDetail()];

declare 'SectionDetail',
    as InstanceOf['Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::ConversationDetail::MetricDetail::SectionDetail'];

coerce 'SectionDetail',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::ConversationDetail::MetricDetail::SectionDetail'->new($_) };

declare 'RepeatedSectionDetail',
    as ArrayRef[SectionDetail()];

coerce 'RepeatedSectionDetail',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::SummarizationEvaluationMetrics::ConversationDetail::MetricDetail::SectionDetail'->new($_) } @$_ ] };

declare 'MapStringSectionDetail',
    as HashRef[SectionDetail()];

declare 'GeneratorEvaluationConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::GeneratorEvaluation::GeneratorEvaluationConfig'];

coerce 'GeneratorEvaluationConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::GeneratorEvaluationConfig'->new($_) };

declare 'RepeatedGeneratorEvaluationConfig',
    as ArrayRef[GeneratorEvaluationConfig()];

coerce 'RepeatedGeneratorEvaluationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::GeneratorEvaluationConfig'->new($_) } @$_ ] };

declare 'MapStringGeneratorEvaluationConfig',
    as HashRef[GeneratorEvaluationConfig()];

declare 'InputDataSourceType',
    as (Int | Str);

declare 'AgentAssistInputDataConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::GeneratorEvaluation::GeneratorEvaluationConfig::AgentAssistInputDataConfig'];

coerce 'AgentAssistInputDataConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::GeneratorEvaluationConfig::AgentAssistInputDataConfig'->new($_) };

declare 'RepeatedAgentAssistInputDataConfig',
    as ArrayRef[AgentAssistInputDataConfig()];

coerce 'RepeatedAgentAssistInputDataConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::GeneratorEvaluationConfig::AgentAssistInputDataConfig'->new($_) } @$_ ] };

declare 'MapStringAgentAssistInputDataConfig',
    as HashRef[AgentAssistInputDataConfig()];

declare 'DatasetInputDataConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::GeneratorEvaluation::GeneratorEvaluationConfig::DatasetInputDataConfig'];

coerce 'DatasetInputDataConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::GeneratorEvaluationConfig::DatasetInputDataConfig'->new($_) };

declare 'RepeatedDatasetInputDataConfig',
    as ArrayRef[DatasetInputDataConfig()];

coerce 'RepeatedDatasetInputDataConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::GeneratorEvaluationConfig::DatasetInputDataConfig'->new($_) } @$_ ] };

declare 'MapStringDatasetInputDataConfig',
    as HashRef[DatasetInputDataConfig()];

declare 'InputDataConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::GeneratorEvaluation::GeneratorEvaluationConfig::InputDataConfig'];

coerce 'InputDataConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::GeneratorEvaluationConfig::InputDataConfig'->new($_) };

declare 'RepeatedInputDataConfig',
    as ArrayRef[InputDataConfig()];

coerce 'RepeatedInputDataConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::GeneratorEvaluationConfig::InputDataConfig'->new($_) } @$_ ] };

declare 'MapStringInputDataConfig',
    as HashRef[InputDataConfig()];

declare 'SummaryGenerationOption',
    as (Int | Str);

declare 'SummarizationConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2::GeneratorEvaluation::GeneratorEvaluationConfig::SummarizationConfig'];

coerce 'SummarizationConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::GeneratorEvaluationConfig::SummarizationConfig'->new($_) };

declare 'RepeatedSummarizationConfig',
    as ArrayRef[SummarizationConfig()];

coerce 'RepeatedSummarizationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::GeneratorEvaluationConfig::SummarizationConfig'->new($_) } @$_ ] };

declare 'MapStringSummarizationConfig',
    as HashRef[SummarizationConfig()];

declare 'EvaluationStatus',
    as InstanceOf['Google::Cloud::Dialogflow::V2::GeneratorEvaluation::EvaluationStatus'];

coerce 'EvaluationStatus',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::EvaluationStatus'->new($_) };

declare 'RepeatedEvaluationStatus',
    as ArrayRef[EvaluationStatus()];

coerce 'RepeatedEvaluationStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::GeneratorEvaluation::EvaluationStatus'->new($_) } @$_ ] };

declare 'MapStringEvaluationStatus',
    as HashRef[EvaluationStatus()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2::GeneratorEvaluation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
