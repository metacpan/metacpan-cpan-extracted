# Copyright (C) 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package Google::Cloud::Bigquery::V2::Model::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RemoteModelInfo',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::RemoteModelInfo'];

coerce 'RemoteModelInfo',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::RemoteModelInfo'->new($_) };

declare 'RepeatedRemoteModelInfo',
    as ArrayRef[RemoteModelInfo()];

coerce 'RepeatedRemoteModelInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::RemoteModelInfo'->new($_) } @$_ ] };

declare 'MapStringRemoteModelInfo',
    as HashRef[RemoteModelInfo()];

declare 'RemoteServiceType',
    as (Int | Str);

declare 'TransformColumn',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::TransformColumn'];

coerce 'TransformColumn',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::TransformColumn'->new($_) };

declare 'RepeatedTransformColumn',
    as ArrayRef[TransformColumn()];

coerce 'RepeatedTransformColumn',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::TransformColumn'->new($_) } @$_ ] };

declare 'MapStringTransformColumn',
    as HashRef[TransformColumn()];

declare 'Model',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model'];

coerce 'Model',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model'->new($_) };

declare 'RepeatedModel',
    as ArrayRef[Model()];

coerce 'RepeatedModel',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model'->new($_) } @$_ ] };

declare 'MapStringModel',
    as HashRef[Model()];

declare 'ModelType',
    as (Int | Str);

declare 'LossType',
    as (Int | Str);

declare 'DistanceType',
    as (Int | Str);

declare 'DataSplitMethod',
    as (Int | Str);

declare 'LabelImputationMethod',
    as (Int | Str);

declare 'DataFrequency',
    as (Int | Str);

declare 'HolidayRegion',
    as (Int | Str);

declare 'ColorSpace',
    as (Int | Str);

declare 'LearnRateStrategy',
    as (Int | Str);

declare 'OptimizationStrategy',
    as (Int | Str);

declare 'FeedbackType',
    as (Int | Str);

declare 'OptimizationObjectiveType',
    as (Int | Str);

declare 'TextEmbeddingMethod',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'SeasonalPeriod',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::SeasonalPeriod'];

coerce 'SeasonalPeriod',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::SeasonalPeriod'->new($_) };

declare 'RepeatedSeasonalPeriod',
    as ArrayRef[SeasonalPeriod()];

coerce 'RepeatedSeasonalPeriod',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::SeasonalPeriod'->new($_) } @$_ ] };

declare 'MapStringSeasonalPeriod',
    as HashRef[SeasonalPeriod()];

declare 'SeasonalPeriodType',
    as (Int | Str);

declare 'KmeansEnums',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::KmeansEnums'];

coerce 'KmeansEnums',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::KmeansEnums'->new($_) };

declare 'RepeatedKmeansEnums',
    as ArrayRef[KmeansEnums()];

coerce 'RepeatedKmeansEnums',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::KmeansEnums'->new($_) } @$_ ] };

declare 'MapStringKmeansEnums',
    as HashRef[KmeansEnums()];

declare 'KmeansInitializationMethod',
    as (Int | Str);

declare 'BoostedTreeOptionEnums',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::BoostedTreeOptionEnums'];

coerce 'BoostedTreeOptionEnums',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::BoostedTreeOptionEnums'->new($_) };

declare 'RepeatedBoostedTreeOptionEnums',
    as ArrayRef[BoostedTreeOptionEnums()];

coerce 'RepeatedBoostedTreeOptionEnums',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::BoostedTreeOptionEnums'->new($_) } @$_ ] };

declare 'MapStringBoostedTreeOptionEnums',
    as HashRef[BoostedTreeOptionEnums()];

declare 'BoosterType',
    as (Int | Str);

declare 'DartNormalizeType',
    as (Int | Str);

declare 'TreeMethod',
    as (Int | Str);

declare 'HparamTuningEnums',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::HparamTuningEnums'];

coerce 'HparamTuningEnums',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::HparamTuningEnums'->new($_) };

declare 'RepeatedHparamTuningEnums',
    as ArrayRef[HparamTuningEnums()];

coerce 'RepeatedHparamTuningEnums',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::HparamTuningEnums'->new($_) } @$_ ] };

declare 'MapStringHparamTuningEnums',
    as HashRef[HparamTuningEnums()];

declare 'HparamTuningObjective',
    as (Int | Str);

declare 'OptimizationObjectiveStruct',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::OptimizationObjectiveStruct'];

coerce 'OptimizationObjectiveStruct',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::OptimizationObjectiveStruct'->new($_) };

declare 'RepeatedOptimizationObjectiveStruct',
    as ArrayRef[OptimizationObjectiveStruct()];

coerce 'RepeatedOptimizationObjectiveStruct',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::OptimizationObjectiveStruct'->new($_) } @$_ ] };

declare 'MapStringOptimizationObjectiveStruct',
    as HashRef[OptimizationObjectiveStruct()];

declare 'RegressionMetrics',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::RegressionMetrics'];

coerce 'RegressionMetrics',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::RegressionMetrics'->new($_) };

declare 'RepeatedRegressionMetrics',
    as ArrayRef[RegressionMetrics()];

coerce 'RepeatedRegressionMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::RegressionMetrics'->new($_) } @$_ ] };

declare 'MapStringRegressionMetrics',
    as HashRef[RegressionMetrics()];

declare 'AggregateClassificationMetrics',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::AggregateClassificationMetrics'];

coerce 'AggregateClassificationMetrics',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::AggregateClassificationMetrics'->new($_) };

declare 'RepeatedAggregateClassificationMetrics',
    as ArrayRef[AggregateClassificationMetrics()];

coerce 'RepeatedAggregateClassificationMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::AggregateClassificationMetrics'->new($_) } @$_ ] };

declare 'MapStringAggregateClassificationMetrics',
    as HashRef[AggregateClassificationMetrics()];

declare 'BinaryClassificationMetrics',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::BinaryClassificationMetrics'];

coerce 'BinaryClassificationMetrics',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::BinaryClassificationMetrics'->new($_) };

declare 'RepeatedBinaryClassificationMetrics',
    as ArrayRef[BinaryClassificationMetrics()];

coerce 'RepeatedBinaryClassificationMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::BinaryClassificationMetrics'->new($_) } @$_ ] };

declare 'MapStringBinaryClassificationMetrics',
    as HashRef[BinaryClassificationMetrics()];

declare 'BinaryConfusionMatrix',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::BinaryClassificationMetrics::BinaryConfusionMatrix'];

coerce 'BinaryConfusionMatrix',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::BinaryClassificationMetrics::BinaryConfusionMatrix'->new($_) };

declare 'RepeatedBinaryConfusionMatrix',
    as ArrayRef[BinaryConfusionMatrix()];

coerce 'RepeatedBinaryConfusionMatrix',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::BinaryClassificationMetrics::BinaryConfusionMatrix'->new($_) } @$_ ] };

declare 'MapStringBinaryConfusionMatrix',
    as HashRef[BinaryConfusionMatrix()];

declare 'MultiClassClassificationMetrics',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::MultiClassClassificationMetrics'];

coerce 'MultiClassClassificationMetrics',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::MultiClassClassificationMetrics'->new($_) };

declare 'RepeatedMultiClassClassificationMetrics',
    as ArrayRef[MultiClassClassificationMetrics()];

coerce 'RepeatedMultiClassClassificationMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::MultiClassClassificationMetrics'->new($_) } @$_ ] };

declare 'MapStringMultiClassClassificationMetrics',
    as HashRef[MultiClassClassificationMetrics()];

declare 'ConfusionMatrix',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::MultiClassClassificationMetrics::ConfusionMatrix'];

coerce 'ConfusionMatrix',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::MultiClassClassificationMetrics::ConfusionMatrix'->new($_) };

declare 'RepeatedConfusionMatrix',
    as ArrayRef[ConfusionMatrix()];

coerce 'RepeatedConfusionMatrix',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::MultiClassClassificationMetrics::ConfusionMatrix'->new($_) } @$_ ] };

declare 'MapStringConfusionMatrix',
    as HashRef[ConfusionMatrix()];

declare 'Entry',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::MultiClassClassificationMetrics::ConfusionMatrix::Entry'];

coerce 'Entry',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::MultiClassClassificationMetrics::ConfusionMatrix::Entry'->new($_) };

declare 'RepeatedEntry',
    as ArrayRef[Entry()];

coerce 'RepeatedEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::MultiClassClassificationMetrics::ConfusionMatrix::Entry'->new($_) } @$_ ] };

declare 'MapStringEntry',
    as HashRef[Entry()];

declare 'Row',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::MultiClassClassificationMetrics::ConfusionMatrix::Row'];

coerce 'Row',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::MultiClassClassificationMetrics::ConfusionMatrix::Row'->new($_) };

declare 'RepeatedRow',
    as ArrayRef[Row()];

coerce 'RepeatedRow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::MultiClassClassificationMetrics::ConfusionMatrix::Row'->new($_) } @$_ ] };

declare 'MapStringRow',
    as HashRef[Row()];

declare 'ClusteringMetrics',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::ClusteringMetrics'];

coerce 'ClusteringMetrics',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::ClusteringMetrics'->new($_) };

declare 'RepeatedClusteringMetrics',
    as ArrayRef[ClusteringMetrics()];

coerce 'RepeatedClusteringMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::ClusteringMetrics'->new($_) } @$_ ] };

declare 'MapStringClusteringMetrics',
    as HashRef[ClusteringMetrics()];

declare 'Cluster',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::ClusteringMetrics::Cluster'];

coerce 'Cluster',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::ClusteringMetrics::Cluster'->new($_) };

declare 'RepeatedCluster',
    as ArrayRef[Cluster()];

coerce 'RepeatedCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::ClusteringMetrics::Cluster'->new($_) } @$_ ] };

declare 'MapStringCluster',
    as HashRef[Cluster()];

declare 'FeatureValue',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::ClusteringMetrics::Cluster::FeatureValue'];

coerce 'FeatureValue',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::ClusteringMetrics::Cluster::FeatureValue'->new($_) };

declare 'RepeatedFeatureValue',
    as ArrayRef[FeatureValue()];

coerce 'RepeatedFeatureValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::ClusteringMetrics::Cluster::FeatureValue'->new($_) } @$_ ] };

declare 'MapStringFeatureValue',
    as HashRef[FeatureValue()];

declare 'CategoricalValue',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::ClusteringMetrics::Cluster::FeatureValue::CategoricalValue'];

coerce 'CategoricalValue',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::ClusteringMetrics::Cluster::FeatureValue::CategoricalValue'->new($_) };

declare 'RepeatedCategoricalValue',
    as ArrayRef[CategoricalValue()];

coerce 'RepeatedCategoricalValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::ClusteringMetrics::Cluster::FeatureValue::CategoricalValue'->new($_) } @$_ ] };

declare 'MapStringCategoricalValue',
    as HashRef[CategoricalValue()];

declare 'CategoryCount',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::ClusteringMetrics::Cluster::FeatureValue::CategoricalValue::CategoryCount'];

coerce 'CategoryCount',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::ClusteringMetrics::Cluster::FeatureValue::CategoricalValue::CategoryCount'->new($_) };

declare 'RepeatedCategoryCount',
    as ArrayRef[CategoryCount()];

coerce 'RepeatedCategoryCount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::ClusteringMetrics::Cluster::FeatureValue::CategoricalValue::CategoryCount'->new($_) } @$_ ] };

declare 'MapStringCategoryCount',
    as HashRef[CategoryCount()];

declare 'RankingMetrics',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::RankingMetrics'];

coerce 'RankingMetrics',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::RankingMetrics'->new($_) };

declare 'RepeatedRankingMetrics',
    as ArrayRef[RankingMetrics()];

coerce 'RepeatedRankingMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::RankingMetrics'->new($_) } @$_ ] };

declare 'MapStringRankingMetrics',
    as HashRef[RankingMetrics()];

declare 'ArimaForecastingMetrics',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::ArimaForecastingMetrics'];

coerce 'ArimaForecastingMetrics',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::ArimaForecastingMetrics'->new($_) };

declare 'RepeatedArimaForecastingMetrics',
    as ArrayRef[ArimaForecastingMetrics()];

coerce 'RepeatedArimaForecastingMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::ArimaForecastingMetrics'->new($_) } @$_ ] };

declare 'MapStringArimaForecastingMetrics',
    as HashRef[ArimaForecastingMetrics()];

declare 'ArimaSingleModelForecastingMetrics',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::ArimaForecastingMetrics::ArimaSingleModelForecastingMetrics'];

coerce 'ArimaSingleModelForecastingMetrics',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::ArimaForecastingMetrics::ArimaSingleModelForecastingMetrics'->new($_) };

declare 'RepeatedArimaSingleModelForecastingMetrics',
    as ArrayRef[ArimaSingleModelForecastingMetrics()];

coerce 'RepeatedArimaSingleModelForecastingMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::ArimaForecastingMetrics::ArimaSingleModelForecastingMetrics'->new($_) } @$_ ] };

declare 'MapStringArimaSingleModelForecastingMetrics',
    as HashRef[ArimaSingleModelForecastingMetrics()];

declare 'DimensionalityReductionMetrics',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::DimensionalityReductionMetrics'];

coerce 'DimensionalityReductionMetrics',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::DimensionalityReductionMetrics'->new($_) };

declare 'RepeatedDimensionalityReductionMetrics',
    as ArrayRef[DimensionalityReductionMetrics()];

coerce 'RepeatedDimensionalityReductionMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::DimensionalityReductionMetrics'->new($_) } @$_ ] };

declare 'MapStringDimensionalityReductionMetrics',
    as HashRef[DimensionalityReductionMetrics()];

declare 'TextGenerationMetrics',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::TextGenerationMetrics'];

coerce 'TextGenerationMetrics',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::TextGenerationMetrics'->new($_) };

declare 'RepeatedTextGenerationMetrics',
    as ArrayRef[TextGenerationMetrics()];

coerce 'RepeatedTextGenerationMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::TextGenerationMetrics'->new($_) } @$_ ] };

declare 'MapStringTextGenerationMetrics',
    as HashRef[TextGenerationMetrics()];

declare 'SummarizationMetrics',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::SummarizationMetrics'];

coerce 'SummarizationMetrics',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::SummarizationMetrics'->new($_) };

declare 'RepeatedSummarizationMetrics',
    as ArrayRef[SummarizationMetrics()];

coerce 'RepeatedSummarizationMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::SummarizationMetrics'->new($_) } @$_ ] };

declare 'MapStringSummarizationMetrics',
    as HashRef[SummarizationMetrics()];

declare 'QuestionAnsweringMetrics',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::QuestionAnsweringMetrics'];

coerce 'QuestionAnsweringMetrics',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::QuestionAnsweringMetrics'->new($_) };

declare 'RepeatedQuestionAnsweringMetrics',
    as ArrayRef[QuestionAnsweringMetrics()];

coerce 'RepeatedQuestionAnsweringMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::QuestionAnsweringMetrics'->new($_) } @$_ ] };

declare 'MapStringQuestionAnsweringMetrics',
    as HashRef[QuestionAnsweringMetrics()];

declare 'ClassificationMetrics',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::ClassificationMetrics'];

coerce 'ClassificationMetrics',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::ClassificationMetrics'->new($_) };

declare 'RepeatedClassificationMetrics',
    as ArrayRef[ClassificationMetrics()];

coerce 'RepeatedClassificationMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::ClassificationMetrics'->new($_) } @$_ ] };

declare 'MapStringClassificationMetrics',
    as HashRef[ClassificationMetrics()];

declare 'PerClassMetricsEntry',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::ClassificationMetrics::PerClassMetricsEntry'];

coerce 'PerClassMetricsEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::ClassificationMetrics::PerClassMetricsEntry'->new($_) };

declare 'RepeatedPerClassMetricsEntry',
    as ArrayRef[PerClassMetricsEntry()];

coerce 'RepeatedPerClassMetricsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::ClassificationMetrics::PerClassMetricsEntry'->new($_) } @$_ ] };

declare 'MapStringPerClassMetricsEntry',
    as HashRef[PerClassMetricsEntry()];

declare 'EvaluationMetrics',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::EvaluationMetrics'];

coerce 'EvaluationMetrics',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::EvaluationMetrics'->new($_) };

declare 'RepeatedEvaluationMetrics',
    as ArrayRef[EvaluationMetrics()];

coerce 'RepeatedEvaluationMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::EvaluationMetrics'->new($_) } @$_ ] };

declare 'MapStringEvaluationMetrics',
    as HashRef[EvaluationMetrics()];

declare 'DataSplitResult',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::DataSplitResult'];

coerce 'DataSplitResult',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::DataSplitResult'->new($_) };

declare 'RepeatedDataSplitResult',
    as ArrayRef[DataSplitResult()];

coerce 'RepeatedDataSplitResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::DataSplitResult'->new($_) } @$_ ] };

declare 'MapStringDataSplitResult',
    as HashRef[DataSplitResult()];

declare 'ArimaOrder',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::ArimaOrder'];

coerce 'ArimaOrder',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::ArimaOrder'->new($_) };

declare 'RepeatedArimaOrder',
    as ArrayRef[ArimaOrder()];

coerce 'RepeatedArimaOrder',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::ArimaOrder'->new($_) } @$_ ] };

declare 'MapStringArimaOrder',
    as HashRef[ArimaOrder()];

declare 'ArimaFittingMetrics',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::ArimaFittingMetrics'];

coerce 'ArimaFittingMetrics',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::ArimaFittingMetrics'->new($_) };

declare 'RepeatedArimaFittingMetrics',
    as ArrayRef[ArimaFittingMetrics()];

coerce 'RepeatedArimaFittingMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::ArimaFittingMetrics'->new($_) } @$_ ] };

declare 'MapStringArimaFittingMetrics',
    as HashRef[ArimaFittingMetrics()];

declare 'GlobalExplanation',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::GlobalExplanation'];

coerce 'GlobalExplanation',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::GlobalExplanation'->new($_) };

declare 'RepeatedGlobalExplanation',
    as ArrayRef[GlobalExplanation()];

coerce 'RepeatedGlobalExplanation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::GlobalExplanation'->new($_) } @$_ ] };

declare 'MapStringGlobalExplanation',
    as HashRef[GlobalExplanation()];

declare 'Explanation',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::GlobalExplanation::Explanation'];

coerce 'Explanation',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::GlobalExplanation::Explanation'->new($_) };

declare 'RepeatedExplanation',
    as ArrayRef[Explanation()];

coerce 'RepeatedExplanation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::GlobalExplanation::Explanation'->new($_) } @$_ ] };

declare 'MapStringExplanation',
    as HashRef[Explanation()];

declare 'CategoryEncodingMethod',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::CategoryEncodingMethod'];

coerce 'CategoryEncodingMethod',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::CategoryEncodingMethod'->new($_) };

declare 'RepeatedCategoryEncodingMethod',
    as ArrayRef[CategoryEncodingMethod()];

coerce 'RepeatedCategoryEncodingMethod',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::CategoryEncodingMethod'->new($_) } @$_ ] };

declare 'MapStringCategoryEncodingMethod',
    as HashRef[CategoryEncodingMethod()];

declare 'EncodingMethod',
    as (Int | Str);

declare 'PreprocessMethod',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::PreprocessMethod'];

coerce 'PreprocessMethod',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::PreprocessMethod'->new($_) };

declare 'RepeatedPreprocessMethod',
    as ArrayRef[PreprocessMethod()];

coerce 'RepeatedPreprocessMethod',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::PreprocessMethod'->new($_) } @$_ ] };

declare 'MapStringPreprocessMethod',
    as HashRef[PreprocessMethod()];

declare 'NumericalPreprocessMethod',
    as (Int | Str);

declare 'Seasonality',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::Seasonality'];

coerce 'Seasonality',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::Seasonality'->new($_) };

declare 'RepeatedSeasonality',
    as ArrayRef[Seasonality()];

coerce 'RepeatedSeasonality',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::Seasonality'->new($_) } @$_ ] };

declare 'MapStringSeasonality',
    as HashRef[Seasonality()];

declare 'SeasonalityType',
    as (Int | Str);

declare 'PcaSolverOptionEnums',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::PcaSolverOptionEnums'];

coerce 'PcaSolverOptionEnums',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::PcaSolverOptionEnums'->new($_) };

declare 'RepeatedPcaSolverOptionEnums',
    as ArrayRef[PcaSolverOptionEnums()];

coerce 'RepeatedPcaSolverOptionEnums',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::PcaSolverOptionEnums'->new($_) } @$_ ] };

declare 'MapStringPcaSolverOptionEnums',
    as HashRef[PcaSolverOptionEnums()];

declare 'PcaSolver',
    as (Int | Str);

declare 'ModelRegistryOptionEnums',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::ModelRegistryOptionEnums'];

coerce 'ModelRegistryOptionEnums',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::ModelRegistryOptionEnums'->new($_) };

declare 'RepeatedModelRegistryOptionEnums',
    as ArrayRef[ModelRegistryOptionEnums()];

coerce 'RepeatedModelRegistryOptionEnums',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::ModelRegistryOptionEnums'->new($_) } @$_ ] };

declare 'MapStringModelRegistryOptionEnums',
    as HashRef[ModelRegistryOptionEnums()];

declare 'ModelRegistry',
    as (Int | Str);

declare 'TrainingRun',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::TrainingRun'];

coerce 'TrainingRun',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::TrainingRun'->new($_) };

declare 'RepeatedTrainingRun',
    as ArrayRef[TrainingRun()];

coerce 'RepeatedTrainingRun',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::TrainingRun'->new($_) } @$_ ] };

declare 'MapStringTrainingRun',
    as HashRef[TrainingRun()];

declare 'TrainingOptions',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::TrainingRun::TrainingOptions'];

coerce 'TrainingOptions',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::TrainingRun::TrainingOptions'->new($_) };

declare 'RepeatedTrainingOptions',
    as ArrayRef[TrainingOptions()];

coerce 'RepeatedTrainingOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::TrainingRun::TrainingOptions'->new($_) } @$_ ] };

declare 'MapStringTrainingOptions',
    as HashRef[TrainingOptions()];

declare 'PruningMethod',
    as (Int | Str);

declare 'ReservationAffinityType',
    as (Int | Str);

declare 'LabelClassWeightsEntry',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::TrainingRun::TrainingOptions::LabelClassWeightsEntry'];

coerce 'LabelClassWeightsEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::TrainingRun::TrainingOptions::LabelClassWeightsEntry'->new($_) };

declare 'RepeatedLabelClassWeightsEntry',
    as ArrayRef[LabelClassWeightsEntry()];

coerce 'RepeatedLabelClassWeightsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::TrainingRun::TrainingOptions::LabelClassWeightsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelClassWeightsEntry',
    as HashRef[LabelClassWeightsEntry()];

declare 'IterationResult',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::TrainingRun::IterationResult'];

coerce 'IterationResult',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::TrainingRun::IterationResult'->new($_) };

declare 'RepeatedIterationResult',
    as ArrayRef[IterationResult()];

coerce 'RepeatedIterationResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::TrainingRun::IterationResult'->new($_) } @$_ ] };

declare 'MapStringIterationResult',
    as HashRef[IterationResult()];

declare 'ClusterInfo',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::TrainingRun::IterationResult::ClusterInfo'];

coerce 'ClusterInfo',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::TrainingRun::IterationResult::ClusterInfo'->new($_) };

declare 'RepeatedClusterInfo',
    as ArrayRef[ClusterInfo()];

coerce 'RepeatedClusterInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::TrainingRun::IterationResult::ClusterInfo'->new($_) } @$_ ] };

declare 'MapStringClusterInfo',
    as HashRef[ClusterInfo()];

declare 'ArimaResult',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::TrainingRun::IterationResult::ArimaResult'];

coerce 'ArimaResult',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::TrainingRun::IterationResult::ArimaResult'->new($_) };

declare 'RepeatedArimaResult',
    as ArrayRef[ArimaResult()];

coerce 'RepeatedArimaResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::TrainingRun::IterationResult::ArimaResult'->new($_) } @$_ ] };

declare 'MapStringArimaResult',
    as HashRef[ArimaResult()];

declare 'ArimaCoefficients',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::TrainingRun::IterationResult::ArimaResult::ArimaCoefficients'];

coerce 'ArimaCoefficients',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::TrainingRun::IterationResult::ArimaResult::ArimaCoefficients'->new($_) };

declare 'RepeatedArimaCoefficients',
    as ArrayRef[ArimaCoefficients()];

coerce 'RepeatedArimaCoefficients',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::TrainingRun::IterationResult::ArimaResult::ArimaCoefficients'->new($_) } @$_ ] };

declare 'MapStringArimaCoefficients',
    as HashRef[ArimaCoefficients()];

declare 'ArimaModelInfo',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::TrainingRun::IterationResult::ArimaResult::ArimaModelInfo'];

coerce 'ArimaModelInfo',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::TrainingRun::IterationResult::ArimaResult::ArimaModelInfo'->new($_) };

declare 'RepeatedArimaModelInfo',
    as ArrayRef[ArimaModelInfo()];

coerce 'RepeatedArimaModelInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::TrainingRun::IterationResult::ArimaResult::ArimaModelInfo'->new($_) } @$_ ] };

declare 'MapStringArimaModelInfo',
    as HashRef[ArimaModelInfo()];

declare 'PrincipalComponentInfo',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::TrainingRun::IterationResult::PrincipalComponentInfo'];

coerce 'PrincipalComponentInfo',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::TrainingRun::IterationResult::PrincipalComponentInfo'->new($_) };

declare 'RepeatedPrincipalComponentInfo',
    as ArrayRef[PrincipalComponentInfo()];

coerce 'RepeatedPrincipalComponentInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::TrainingRun::IterationResult::PrincipalComponentInfo'->new($_) } @$_ ] };

declare 'MapStringPrincipalComponentInfo',
    as HashRef[PrincipalComponentInfo()];

declare 'DoubleHparamSearchSpace',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::DoubleHparamSearchSpace'];

coerce 'DoubleHparamSearchSpace',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::DoubleHparamSearchSpace'->new($_) };

declare 'RepeatedDoubleHparamSearchSpace',
    as ArrayRef[DoubleHparamSearchSpace()];

coerce 'RepeatedDoubleHparamSearchSpace',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::DoubleHparamSearchSpace'->new($_) } @$_ ] };

declare 'MapStringDoubleHparamSearchSpace',
    as HashRef[DoubleHparamSearchSpace()];

declare 'DoubleRange',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::DoubleHparamSearchSpace::DoubleRange'];

coerce 'DoubleRange',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::DoubleHparamSearchSpace::DoubleRange'->new($_) };

declare 'RepeatedDoubleRange',
    as ArrayRef[DoubleRange()];

coerce 'RepeatedDoubleRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::DoubleHparamSearchSpace::DoubleRange'->new($_) } @$_ ] };

declare 'MapStringDoubleRange',
    as HashRef[DoubleRange()];

declare 'DoubleCandidates',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::DoubleHparamSearchSpace::DoubleCandidates'];

coerce 'DoubleCandidates',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::DoubleHparamSearchSpace::DoubleCandidates'->new($_) };

declare 'RepeatedDoubleCandidates',
    as ArrayRef[DoubleCandidates()];

coerce 'RepeatedDoubleCandidates',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::DoubleHparamSearchSpace::DoubleCandidates'->new($_) } @$_ ] };

declare 'MapStringDoubleCandidates',
    as HashRef[DoubleCandidates()];

declare 'IntHparamSearchSpace',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::IntHparamSearchSpace'];

coerce 'IntHparamSearchSpace',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::IntHparamSearchSpace'->new($_) };

declare 'RepeatedIntHparamSearchSpace',
    as ArrayRef[IntHparamSearchSpace()];

coerce 'RepeatedIntHparamSearchSpace',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::IntHparamSearchSpace'->new($_) } @$_ ] };

declare 'MapStringIntHparamSearchSpace',
    as HashRef[IntHparamSearchSpace()];

declare 'IntRange',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::IntHparamSearchSpace::IntRange'];

coerce 'IntRange',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::IntHparamSearchSpace::IntRange'->new($_) };

declare 'RepeatedIntRange',
    as ArrayRef[IntRange()];

coerce 'RepeatedIntRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::IntHparamSearchSpace::IntRange'->new($_) } @$_ ] };

declare 'MapStringIntRange',
    as HashRef[IntRange()];

declare 'IntCandidates',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::IntHparamSearchSpace::IntCandidates'];

coerce 'IntCandidates',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::IntHparamSearchSpace::IntCandidates'->new($_) };

declare 'RepeatedIntCandidates',
    as ArrayRef[IntCandidates()];

coerce 'RepeatedIntCandidates',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::IntHparamSearchSpace::IntCandidates'->new($_) } @$_ ] };

declare 'MapStringIntCandidates',
    as HashRef[IntCandidates()];

declare 'StringHparamSearchSpace',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::StringHparamSearchSpace'];

coerce 'StringHparamSearchSpace',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::StringHparamSearchSpace'->new($_) };

declare 'RepeatedStringHparamSearchSpace',
    as ArrayRef[StringHparamSearchSpace()];

coerce 'RepeatedStringHparamSearchSpace',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::StringHparamSearchSpace'->new($_) } @$_ ] };

declare 'MapStringStringHparamSearchSpace',
    as HashRef[StringHparamSearchSpace()];

declare 'IntArrayHparamSearchSpace',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::IntArrayHparamSearchSpace'];

coerce 'IntArrayHparamSearchSpace',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::IntArrayHparamSearchSpace'->new($_) };

declare 'RepeatedIntArrayHparamSearchSpace',
    as ArrayRef[IntArrayHparamSearchSpace()];

coerce 'RepeatedIntArrayHparamSearchSpace',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::IntArrayHparamSearchSpace'->new($_) } @$_ ] };

declare 'MapStringIntArrayHparamSearchSpace',
    as HashRef[IntArrayHparamSearchSpace()];

declare 'IntArray',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::IntArrayHparamSearchSpace::IntArray'];

coerce 'IntArray',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::IntArrayHparamSearchSpace::IntArray'->new($_) };

declare 'RepeatedIntArray',
    as ArrayRef[IntArray()];

coerce 'RepeatedIntArray',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::IntArrayHparamSearchSpace::IntArray'->new($_) } @$_ ] };

declare 'MapStringIntArray',
    as HashRef[IntArray()];

declare 'HparamSearchSpaces',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::HparamSearchSpaces'];

coerce 'HparamSearchSpaces',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::HparamSearchSpaces'->new($_) };

declare 'RepeatedHparamSearchSpaces',
    as ArrayRef[HparamSearchSpaces()];

coerce 'RepeatedHparamSearchSpaces',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::HparamSearchSpaces'->new($_) } @$_ ] };

declare 'MapStringHparamSearchSpaces',
    as HashRef[HparamSearchSpaces()];

declare 'HparamTuningTrial',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::HparamTuningTrial'];

coerce 'HparamTuningTrial',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::HparamTuningTrial'->new($_) };

declare 'RepeatedHparamTuningTrial',
    as ArrayRef[HparamTuningTrial()];

coerce 'RepeatedHparamTuningTrial',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::HparamTuningTrial'->new($_) } @$_ ] };

declare 'MapStringHparamTuningTrial',
    as HashRef[HparamTuningTrial()];

declare 'TrialStatus',
    as (Int | Str);

declare 'ServingConfig',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::Model::ServingConfig'];

coerce 'ServingConfig',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::Model::ServingConfig'->new($_) };

declare 'RepeatedServingConfig',
    as ArrayRef[ServingConfig()];

coerce 'RepeatedServingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::Model::ServingConfig'->new($_) } @$_ ] };

declare 'MapStringServingConfig',
    as HashRef[ServingConfig()];

declare 'GetModelRequest',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::GetModelRequest'];

coerce 'GetModelRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::GetModelRequest'->new($_) };

declare 'RepeatedGetModelRequest',
    as ArrayRef[GetModelRequest()];

coerce 'RepeatedGetModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::GetModelRequest'->new($_) } @$_ ] };

declare 'MapStringGetModelRequest',
    as HashRef[GetModelRequest()];

declare 'PatchModelRequest',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::PatchModelRequest'];

coerce 'PatchModelRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::PatchModelRequest'->new($_) };

declare 'RepeatedPatchModelRequest',
    as ArrayRef[PatchModelRequest()];

coerce 'RepeatedPatchModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::PatchModelRequest'->new($_) } @$_ ] };

declare 'MapStringPatchModelRequest',
    as HashRef[PatchModelRequest()];

declare 'DeleteModelRequest',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::DeleteModelRequest'];

coerce 'DeleteModelRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::DeleteModelRequest'->new($_) };

declare 'RepeatedDeleteModelRequest',
    as ArrayRef[DeleteModelRequest()];

coerce 'RepeatedDeleteModelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::DeleteModelRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteModelRequest',
    as HashRef[DeleteModelRequest()];

declare 'ListModelsRequest',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::ListModelsRequest'];

coerce 'ListModelsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::ListModelsRequest'->new($_) };

declare 'RepeatedListModelsRequest',
    as ArrayRef[ListModelsRequest()];

coerce 'RepeatedListModelsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::ListModelsRequest'->new($_) } @$_ ] };

declare 'MapStringListModelsRequest',
    as HashRef[ListModelsRequest()];

declare 'ListModelsResponse',
    as InstanceOf['Google::Cloud::Bigquery::V2::Model::ListModelsResponse'];

coerce 'ListModelsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Model::ListModelsResponse'->new($_) };

declare 'RepeatedListModelsResponse',
    as ArrayRef[ListModelsResponse()];

coerce 'RepeatedListModelsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Model::ListModelsResponse'->new($_) } @$_ ] };

declare 'MapStringListModelsResponse',
    as HashRef[ListModelsResponse()];

1;
