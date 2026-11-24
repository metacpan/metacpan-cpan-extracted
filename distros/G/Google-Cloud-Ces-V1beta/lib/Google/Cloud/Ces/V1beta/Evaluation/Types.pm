package Google::Cloud::Ces::V1beta::Evaluation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AggregatedMetrics',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::AggregatedMetrics'];

coerce 'AggregatedMetrics',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::AggregatedMetrics'->new($_) };

declare 'RepeatedAggregatedMetrics',
    as ArrayRef[AggregatedMetrics()];

coerce 'RepeatedAggregatedMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::AggregatedMetrics'->new($_) } @$_ ] };

declare 'MapStringAggregatedMetrics',
    as HashRef[AggregatedMetrics()];

declare 'ToolMetrics',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::AggregatedMetrics::ToolMetrics'];

coerce 'ToolMetrics',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::AggregatedMetrics::ToolMetrics'->new($_) };

declare 'RepeatedToolMetrics',
    as ArrayRef[ToolMetrics()];

coerce 'RepeatedToolMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::AggregatedMetrics::ToolMetrics'->new($_) } @$_ ] };

declare 'MapStringToolMetrics',
    as HashRef[ToolMetrics()];

declare 'TurnLatencyMetrics',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::AggregatedMetrics::TurnLatencyMetrics'];

coerce 'TurnLatencyMetrics',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::AggregatedMetrics::TurnLatencyMetrics'->new($_) };

declare 'RepeatedTurnLatencyMetrics',
    as ArrayRef[TurnLatencyMetrics()];

coerce 'RepeatedTurnLatencyMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::AggregatedMetrics::TurnLatencyMetrics'->new($_) } @$_ ] };

declare 'MapStringTurnLatencyMetrics',
    as HashRef[TurnLatencyMetrics()];

declare 'ToolCallLatencyMetrics',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::AggregatedMetrics::ToolCallLatencyMetrics'];

coerce 'ToolCallLatencyMetrics',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::AggregatedMetrics::ToolCallLatencyMetrics'->new($_) };

declare 'RepeatedToolCallLatencyMetrics',
    as ArrayRef[ToolCallLatencyMetrics()];

coerce 'RepeatedToolCallLatencyMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::AggregatedMetrics::ToolCallLatencyMetrics'->new($_) } @$_ ] };

declare 'MapStringToolCallLatencyMetrics',
    as HashRef[ToolCallLatencyMetrics()];

declare 'SemanticSimilarityMetrics',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::AggregatedMetrics::SemanticSimilarityMetrics'];

coerce 'SemanticSimilarityMetrics',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::AggregatedMetrics::SemanticSimilarityMetrics'->new($_) };

declare 'RepeatedSemanticSimilarityMetrics',
    as ArrayRef[SemanticSimilarityMetrics()];

coerce 'RepeatedSemanticSimilarityMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::AggregatedMetrics::SemanticSimilarityMetrics'->new($_) } @$_ ] };

declare 'MapStringSemanticSimilarityMetrics',
    as HashRef[SemanticSimilarityMetrics()];

declare 'HallucinationMetrics',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::AggregatedMetrics::HallucinationMetrics'];

coerce 'HallucinationMetrics',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::AggregatedMetrics::HallucinationMetrics'->new($_) };

declare 'RepeatedHallucinationMetrics',
    as ArrayRef[HallucinationMetrics()];

coerce 'RepeatedHallucinationMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::AggregatedMetrics::HallucinationMetrics'->new($_) } @$_ ] };

declare 'MapStringHallucinationMetrics',
    as HashRef[HallucinationMetrics()];

declare 'MetricsByAppVersion',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::AggregatedMetrics::MetricsByAppVersion'];

coerce 'MetricsByAppVersion',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::AggregatedMetrics::MetricsByAppVersion'->new($_) };

declare 'RepeatedMetricsByAppVersion',
    as ArrayRef[MetricsByAppVersion()];

coerce 'RepeatedMetricsByAppVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::AggregatedMetrics::MetricsByAppVersion'->new($_) } @$_ ] };

declare 'MapStringMetricsByAppVersion',
    as HashRef[MetricsByAppVersion()];

declare 'MetricsByTurn',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::AggregatedMetrics::MetricsByTurn'];

coerce 'MetricsByTurn',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::AggregatedMetrics::MetricsByTurn'->new($_) };

declare 'RepeatedMetricsByTurn',
    as ArrayRef[MetricsByTurn()];

coerce 'RepeatedMetricsByTurn',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::AggregatedMetrics::MetricsByTurn'->new($_) } @$_ ] };

declare 'MapStringMetricsByTurn',
    as HashRef[MetricsByTurn()];

declare 'Evaluation',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::Evaluation'];

coerce 'Evaluation',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::Evaluation'->new($_) };

declare 'RepeatedEvaluation',
    as ArrayRef[Evaluation()];

coerce 'RepeatedEvaluation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::Evaluation'->new($_) } @$_ ] };

declare 'MapStringEvaluation',
    as HashRef[Evaluation()];

declare 'GoldenExpectation',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::Evaluation::GoldenExpectation'];

coerce 'GoldenExpectation',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::Evaluation::GoldenExpectation'->new($_) };

declare 'RepeatedGoldenExpectation',
    as ArrayRef[GoldenExpectation()];

coerce 'RepeatedGoldenExpectation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::Evaluation::GoldenExpectation'->new($_) } @$_ ] };

declare 'MapStringGoldenExpectation',
    as HashRef[GoldenExpectation()];

declare 'Step',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::Evaluation::Step'];

coerce 'Step',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::Evaluation::Step'->new($_) };

declare 'RepeatedStep',
    as ArrayRef[Step()];

coerce 'RepeatedStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::Evaluation::Step'->new($_) } @$_ ] };

declare 'MapStringStep',
    as HashRef[Step()];

declare 'GoldenTurn',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::Evaluation::GoldenTurn'];

coerce 'GoldenTurn',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::Evaluation::GoldenTurn'->new($_) };

declare 'RepeatedGoldenTurn',
    as ArrayRef[GoldenTurn()];

coerce 'RepeatedGoldenTurn',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::Evaluation::GoldenTurn'->new($_) } @$_ ] };

declare 'MapStringGoldenTurn',
    as HashRef[GoldenTurn()];

declare 'Golden',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::Evaluation::Golden'];

coerce 'Golden',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::Evaluation::Golden'->new($_) };

declare 'RepeatedGolden',
    as ArrayRef[Golden()];

coerce 'RepeatedGolden',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::Evaluation::Golden'->new($_) } @$_ ] };

declare 'MapStringGolden',
    as HashRef[Golden()];

declare 'ScenarioExpectation',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::Evaluation::ScenarioExpectation'];

coerce 'ScenarioExpectation',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::Evaluation::ScenarioExpectation'->new($_) };

declare 'RepeatedScenarioExpectation',
    as ArrayRef[ScenarioExpectation()];

coerce 'RepeatedScenarioExpectation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::Evaluation::ScenarioExpectation'->new($_) } @$_ ] };

declare 'MapStringScenarioExpectation',
    as HashRef[ScenarioExpectation()];

declare 'ToolExpectation',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::Evaluation::ScenarioExpectation::ToolExpectation'];

coerce 'ToolExpectation',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::Evaluation::ScenarioExpectation::ToolExpectation'->new($_) };

declare 'RepeatedToolExpectation',
    as ArrayRef[ToolExpectation()];

coerce 'RepeatedToolExpectation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::Evaluation::ScenarioExpectation::ToolExpectation'->new($_) } @$_ ] };

declare 'MapStringToolExpectation',
    as HashRef[ToolExpectation()];

declare 'Scenario',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::Evaluation::Scenario'];

coerce 'Scenario',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::Evaluation::Scenario'->new($_) };

declare 'RepeatedScenario',
    as ArrayRef[Scenario()];

coerce 'RepeatedScenario',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::Evaluation::Scenario'->new($_) } @$_ ] };

declare 'MapStringScenario',
    as HashRef[Scenario()];

declare 'TaskCompletionBehavior',
    as (Int | Str);

declare 'UserGoalBehavior',
    as (Int | Str);

declare 'UserFact',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::Evaluation::Scenario::UserFact'];

coerce 'UserFact',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::Evaluation::Scenario::UserFact'->new($_) };

declare 'RepeatedUserFact',
    as ArrayRef[UserFact()];

coerce 'RepeatedUserFact',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::Evaluation::Scenario::UserFact'->new($_) } @$_ ] };

declare 'MapStringUserFact',
    as HashRef[UserFact()];

declare 'EvaluationDataset',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::EvaluationDataset'];

coerce 'EvaluationDataset',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationDataset'->new($_) };

declare 'RepeatedEvaluationDataset',
    as ArrayRef[EvaluationDataset()];

coerce 'RepeatedEvaluationDataset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationDataset'->new($_) } @$_ ] };

declare 'MapStringEvaluationDataset',
    as HashRef[EvaluationDataset()];

declare 'EvaluationResult',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult'];

coerce 'EvaluationResult',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult'->new($_) };

declare 'RepeatedEvaluationResult',
    as ArrayRef[EvaluationResult()];

coerce 'RepeatedEvaluationResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult'->new($_) } @$_ ] };

declare 'MapStringEvaluationResult',
    as HashRef[EvaluationResult()];

declare 'Outcome',
    as (Int | Str);

declare 'ExecutionState',
    as (Int | Str);

declare 'OutcomeMetadata',
    as (Int | Str);

declare 'GoldenExpectationOutcome',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::GoldenExpectationOutcome'];

coerce 'GoldenExpectationOutcome',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::GoldenExpectationOutcome'->new($_) };

declare 'RepeatedGoldenExpectationOutcome',
    as ArrayRef[GoldenExpectationOutcome()];

coerce 'RepeatedGoldenExpectationOutcome',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::GoldenExpectationOutcome'->new($_) } @$_ ] };

declare 'MapStringGoldenExpectationOutcome',
    as HashRef[GoldenExpectationOutcome()];

declare 'ToolInvocationResult',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::GoldenExpectationOutcome::ToolInvocationResult'];

coerce 'ToolInvocationResult',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::GoldenExpectationOutcome::ToolInvocationResult'->new($_) };

declare 'RepeatedToolInvocationResult',
    as ArrayRef[ToolInvocationResult()];

coerce 'RepeatedToolInvocationResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::GoldenExpectationOutcome::ToolInvocationResult'->new($_) } @$_ ] };

declare 'MapStringToolInvocationResult',
    as HashRef[ToolInvocationResult()];

declare 'EvaluationExpectationResult',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::EvaluationExpectationResult'];

coerce 'EvaluationExpectationResult',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::EvaluationExpectationResult'->new($_) };

declare 'RepeatedEvaluationExpectationResult',
    as ArrayRef[EvaluationExpectationResult()];

coerce 'RepeatedEvaluationExpectationResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::EvaluationExpectationResult'->new($_) } @$_ ] };

declare 'MapStringEvaluationExpectationResult',
    as HashRef[EvaluationExpectationResult()];

declare 'GoldenResult',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::GoldenResult'];

coerce 'GoldenResult',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::GoldenResult'->new($_) };

declare 'RepeatedGoldenResult',
    as ArrayRef[GoldenResult()];

coerce 'RepeatedGoldenResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::GoldenResult'->new($_) } @$_ ] };

declare 'MapStringGoldenResult',
    as HashRef[GoldenResult()];

declare 'TurnReplayResult',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::GoldenResult::TurnReplayResult'];

coerce 'TurnReplayResult',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::GoldenResult::TurnReplayResult'->new($_) };

declare 'RepeatedTurnReplayResult',
    as ArrayRef[TurnReplayResult()];

coerce 'RepeatedTurnReplayResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::GoldenResult::TurnReplayResult'->new($_) } @$_ ] };

declare 'MapStringTurnReplayResult',
    as HashRef[TurnReplayResult()];

declare 'ScenarioRubricOutcome',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::ScenarioRubricOutcome'];

coerce 'ScenarioRubricOutcome',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::ScenarioRubricOutcome'->new($_) };

declare 'RepeatedScenarioRubricOutcome',
    as ArrayRef[ScenarioRubricOutcome()];

coerce 'RepeatedScenarioRubricOutcome',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::ScenarioRubricOutcome'->new($_) } @$_ ] };

declare 'MapStringScenarioRubricOutcome',
    as HashRef[ScenarioRubricOutcome()];

declare 'ScenarioExpectationOutcome',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::ScenarioExpectationOutcome'];

coerce 'ScenarioExpectationOutcome',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::ScenarioExpectationOutcome'->new($_) };

declare 'RepeatedScenarioExpectationOutcome',
    as ArrayRef[ScenarioExpectationOutcome()];

coerce 'RepeatedScenarioExpectationOutcome',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::ScenarioExpectationOutcome'->new($_) } @$_ ] };

declare 'MapStringScenarioExpectationOutcome',
    as HashRef[ScenarioExpectationOutcome()];

declare 'ObservedToolCall',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::ScenarioExpectationOutcome::ObservedToolCall'];

coerce 'ObservedToolCall',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::ScenarioExpectationOutcome::ObservedToolCall'->new($_) };

declare 'RepeatedObservedToolCall',
    as ArrayRef[ObservedToolCall()];

coerce 'RepeatedObservedToolCall',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::ScenarioExpectationOutcome::ObservedToolCall'->new($_) } @$_ ] };

declare 'MapStringObservedToolCall',
    as HashRef[ObservedToolCall()];

declare 'ScenarioResult',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::ScenarioResult'];

coerce 'ScenarioResult',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::ScenarioResult'->new($_) };

declare 'RepeatedScenarioResult',
    as ArrayRef[ScenarioResult()];

coerce 'RepeatedScenarioResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::ScenarioResult'->new($_) } @$_ ] };

declare 'MapStringScenarioResult',
    as HashRef[ScenarioResult()];

declare 'SpanLatency',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::SpanLatency'];

coerce 'SpanLatency',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::SpanLatency'->new($_) };

declare 'RepeatedSpanLatency',
    as ArrayRef[SpanLatency()];

coerce 'RepeatedSpanLatency',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::SpanLatency'->new($_) } @$_ ] };

declare 'MapStringSpanLatency',
    as HashRef[SpanLatency()];

declare 'Type',
    as (Int | Str);

declare 'ToolCallLatency',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::ToolCallLatency'];

coerce 'ToolCallLatency',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::ToolCallLatency'->new($_) };

declare 'RepeatedToolCallLatency',
    as ArrayRef[ToolCallLatency()];

coerce 'RepeatedToolCallLatency',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::ToolCallLatency'->new($_) } @$_ ] };

declare 'MapStringToolCallLatency',
    as HashRef[ToolCallLatency()];

declare 'HallucinationResult',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::HallucinationResult'];

coerce 'HallucinationResult',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::HallucinationResult'->new($_) };

declare 'RepeatedHallucinationResult',
    as ArrayRef[HallucinationResult()];

coerce 'RepeatedHallucinationResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::HallucinationResult'->new($_) } @$_ ] };

declare 'MapStringHallucinationResult',
    as HashRef[HallucinationResult()];

declare 'UserGoalSatisfactionResult',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::UserGoalSatisfactionResult'];

coerce 'UserGoalSatisfactionResult',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::UserGoalSatisfactionResult'->new($_) };

declare 'RepeatedUserGoalSatisfactionResult',
    as ArrayRef[UserGoalSatisfactionResult()];

coerce 'RepeatedUserGoalSatisfactionResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::UserGoalSatisfactionResult'->new($_) } @$_ ] };

declare 'MapStringUserGoalSatisfactionResult',
    as HashRef[UserGoalSatisfactionResult()];

declare 'SemanticSimilarityResult',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::SemanticSimilarityResult'];

coerce 'SemanticSimilarityResult',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::SemanticSimilarityResult'->new($_) };

declare 'RepeatedSemanticSimilarityResult',
    as ArrayRef[SemanticSimilarityResult()];

coerce 'RepeatedSemanticSimilarityResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::SemanticSimilarityResult'->new($_) } @$_ ] };

declare 'MapStringSemanticSimilarityResult',
    as HashRef[SemanticSimilarityResult()];

declare 'OverallToolInvocationResult',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::OverallToolInvocationResult'];

coerce 'OverallToolInvocationResult',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::OverallToolInvocationResult'->new($_) };

declare 'RepeatedOverallToolInvocationResult',
    as ArrayRef[OverallToolInvocationResult()];

coerce 'RepeatedOverallToolInvocationResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::OverallToolInvocationResult'->new($_) } @$_ ] };

declare 'MapStringOverallToolInvocationResult',
    as HashRef[OverallToolInvocationResult()];

declare 'TaskCompletionResult',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::TaskCompletionResult'];

coerce 'TaskCompletionResult',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::TaskCompletionResult'->new($_) };

declare 'RepeatedTaskCompletionResult',
    as ArrayRef[TaskCompletionResult()];

coerce 'RepeatedTaskCompletionResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationResult::TaskCompletionResult'->new($_) } @$_ ] };

declare 'MapStringTaskCompletionResult',
    as HashRef[TaskCompletionResult()];

declare 'EvaluationRun',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::EvaluationRun'];

coerce 'EvaluationRun',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationRun'->new($_) };

declare 'RepeatedEvaluationRun',
    as ArrayRef[EvaluationRun()];

coerce 'RepeatedEvaluationRun',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationRun'->new($_) } @$_ ] };

declare 'MapStringEvaluationRun',
    as HashRef[EvaluationRun()];

declare 'EvaluationType',
    as (Int | Str);

declare 'EvaluationRunState',
    as (Int | Str);

declare 'Progress',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::EvaluationRun::Progress'];

coerce 'Progress',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationRun::Progress'->new($_) };

declare 'RepeatedProgress',
    as ArrayRef[Progress()];

coerce 'RepeatedProgress',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationRun::Progress'->new($_) } @$_ ] };

declare 'MapStringProgress',
    as HashRef[Progress()];

declare 'EvaluationRunSummary',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::EvaluationRun::EvaluationRunSummary'];

coerce 'EvaluationRunSummary',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationRun::EvaluationRunSummary'->new($_) };

declare 'RepeatedEvaluationRunSummary',
    as ArrayRef[EvaluationRunSummary()];

coerce 'RepeatedEvaluationRunSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationRun::EvaluationRunSummary'->new($_) } @$_ ] };

declare 'MapStringEvaluationRunSummary',
    as HashRef[EvaluationRunSummary()];

declare 'EvaluationRunSummariesEntry',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::EvaluationRun::EvaluationRunSummariesEntry'];

coerce 'EvaluationRunSummariesEntry',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationRun::EvaluationRunSummariesEntry'->new($_) };

declare 'RepeatedEvaluationRunSummariesEntry',
    as ArrayRef[EvaluationRunSummariesEntry()];

coerce 'RepeatedEvaluationRunSummariesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationRun::EvaluationRunSummariesEntry'->new($_) } @$_ ] };

declare 'MapStringEvaluationRunSummariesEntry',
    as HashRef[EvaluationRunSummariesEntry()];

declare 'LatencyReport',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::LatencyReport'];

coerce 'LatencyReport',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::LatencyReport'->new($_) };

declare 'RepeatedLatencyReport',
    as ArrayRef[LatencyReport()];

coerce 'RepeatedLatencyReport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::LatencyReport'->new($_) } @$_ ] };

declare 'MapStringLatencyReport',
    as HashRef[LatencyReport()];

declare 'LatencyMetrics',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::LatencyReport::LatencyMetrics'];

coerce 'LatencyMetrics',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::LatencyReport::LatencyMetrics'->new($_) };

declare 'RepeatedLatencyMetrics',
    as ArrayRef[LatencyMetrics()];

coerce 'RepeatedLatencyMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::LatencyReport::LatencyMetrics'->new($_) } @$_ ] };

declare 'MapStringLatencyMetrics',
    as HashRef[LatencyMetrics()];

declare 'ToolLatency',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::LatencyReport::ToolLatency'];

coerce 'ToolLatency',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::LatencyReport::ToolLatency'->new($_) };

declare 'RepeatedToolLatency',
    as ArrayRef[ToolLatency()];

coerce 'RepeatedToolLatency',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::LatencyReport::ToolLatency'->new($_) } @$_ ] };

declare 'MapStringToolLatency',
    as HashRef[ToolLatency()];

declare 'CallbackLatency',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::LatencyReport::CallbackLatency'];

coerce 'CallbackLatency',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::LatencyReport::CallbackLatency'->new($_) };

declare 'RepeatedCallbackLatency',
    as ArrayRef[CallbackLatency()];

coerce 'RepeatedCallbackLatency',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::LatencyReport::CallbackLatency'->new($_) } @$_ ] };

declare 'MapStringCallbackLatency',
    as HashRef[CallbackLatency()];

declare 'GuardrailLatency',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::LatencyReport::GuardrailLatency'];

coerce 'GuardrailLatency',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::LatencyReport::GuardrailLatency'->new($_) };

declare 'RepeatedGuardrailLatency',
    as ArrayRef[GuardrailLatency()];

coerce 'RepeatedGuardrailLatency',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::LatencyReport::GuardrailLatency'->new($_) } @$_ ] };

declare 'MapStringGuardrailLatency',
    as HashRef[GuardrailLatency()];

declare 'LlmCallLatency',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::LatencyReport::LlmCallLatency'];

coerce 'LlmCallLatency',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::LatencyReport::LlmCallLatency'->new($_) };

declare 'RepeatedLlmCallLatency',
    as ArrayRef[LlmCallLatency()];

coerce 'RepeatedLlmCallLatency',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::LatencyReport::LlmCallLatency'->new($_) } @$_ ] };

declare 'MapStringLlmCallLatency',
    as HashRef[LlmCallLatency()];

declare 'EvaluationExpectation',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::EvaluationExpectation'];

coerce 'EvaluationExpectation',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationExpectation'->new($_) };

declare 'RepeatedEvaluationExpectation',
    as ArrayRef[EvaluationExpectation()];

coerce 'RepeatedEvaluationExpectation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationExpectation'->new($_) } @$_ ] };

declare 'MapStringEvaluationExpectation',
    as HashRef[EvaluationExpectation()];

declare 'LlmCriteria',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::EvaluationExpectation::LlmCriteria'];

coerce 'LlmCriteria',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationExpectation::LlmCriteria'->new($_) };

declare 'RepeatedLlmCriteria',
    as ArrayRef[LlmCriteria()];

coerce 'RepeatedLlmCriteria',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationExpectation::LlmCriteria'->new($_) } @$_ ] };

declare 'MapStringLlmCriteria',
    as HashRef[LlmCriteria()];

declare 'EvaluationConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::EvaluationConfig'];

coerce 'EvaluationConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationConfig'->new($_) };

declare 'RepeatedEvaluationConfig',
    as ArrayRef[EvaluationConfig()];

coerce 'RepeatedEvaluationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationConfig'->new($_) } @$_ ] };

declare 'MapStringEvaluationConfig',
    as HashRef[EvaluationConfig()];

declare 'EvaluationChannel',
    as (Int | Str);

declare 'EvaluationErrorInfo',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::EvaluationErrorInfo'];

coerce 'EvaluationErrorInfo',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationErrorInfo'->new($_) };

declare 'RepeatedEvaluationErrorInfo',
    as ArrayRef[EvaluationErrorInfo()];

coerce 'RepeatedEvaluationErrorInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::EvaluationErrorInfo'->new($_) } @$_ ] };

declare 'MapStringEvaluationErrorInfo',
    as HashRef[EvaluationErrorInfo()];

declare 'ErrorType',
    as (Int | Str);

declare 'RunEvaluationRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::RunEvaluationRequest'];

coerce 'RunEvaluationRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::RunEvaluationRequest'->new($_) };

declare 'RepeatedRunEvaluationRequest',
    as ArrayRef[RunEvaluationRequest()];

coerce 'RepeatedRunEvaluationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::RunEvaluationRequest'->new($_) } @$_ ] };

declare 'MapStringRunEvaluationRequest',
    as HashRef[RunEvaluationRequest()];

declare 'ScheduledEvaluationRun',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::ScheduledEvaluationRun'];

coerce 'ScheduledEvaluationRun',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::ScheduledEvaluationRun'->new($_) };

declare 'RepeatedScheduledEvaluationRun',
    as ArrayRef[ScheduledEvaluationRun()];

coerce 'RepeatedScheduledEvaluationRun',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::ScheduledEvaluationRun'->new($_) } @$_ ] };

declare 'MapStringScheduledEvaluationRun',
    as HashRef[ScheduledEvaluationRun()];

declare 'SchedulingConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::ScheduledEvaluationRun::SchedulingConfig'];

coerce 'SchedulingConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::ScheduledEvaluationRun::SchedulingConfig'->new($_) };

declare 'RepeatedSchedulingConfig',
    as ArrayRef[SchedulingConfig()];

coerce 'RepeatedSchedulingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::ScheduledEvaluationRun::SchedulingConfig'->new($_) } @$_ ] };

declare 'MapStringSchedulingConfig',
    as HashRef[SchedulingConfig()];

declare 'Frequency',
    as (Int | Str);

declare 'PersonaRunConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::PersonaRunConfig'];

coerce 'PersonaRunConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::PersonaRunConfig'->new($_) };

declare 'RepeatedPersonaRunConfig',
    as ArrayRef[PersonaRunConfig()];

coerce 'RepeatedPersonaRunConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::PersonaRunConfig'->new($_) } @$_ ] };

declare 'MapStringPersonaRunConfig',
    as HashRef[PersonaRunConfig()];

declare 'OptimizationConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::Evaluation::OptimizationConfig'];

coerce 'OptimizationConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::Evaluation::OptimizationConfig'->new($_) };

declare 'RepeatedOptimizationConfig',
    as ArrayRef[OptimizationConfig()];

coerce 'RepeatedOptimizationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::Evaluation::OptimizationConfig'->new($_) } @$_ ] };

declare 'MapStringOptimizationConfig',
    as HashRef[OptimizationConfig()];

declare 'OptimizationStatus',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1beta::Evaluation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
