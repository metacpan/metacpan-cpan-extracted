package Google::Cloud::Bigquery::V2::JobStats::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ReservationEdition',
    as (Int | Str);

declare 'ExplainQueryStep',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::ExplainQueryStep'];

coerce 'ExplainQueryStep',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::ExplainQueryStep'->new($_) };

declare 'RepeatedExplainQueryStep',
    as ArrayRef[ExplainQueryStep()];

coerce 'RepeatedExplainQueryStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::ExplainQueryStep'->new($_) } @$_ ] };

declare 'MapStringExplainQueryStep',
    as HashRef[ExplainQueryStep()];

declare 'ExplainQueryStage',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::ExplainQueryStage'];

coerce 'ExplainQueryStage',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::ExplainQueryStage'->new($_) };

declare 'RepeatedExplainQueryStage',
    as ArrayRef[ExplainQueryStage()];

coerce 'RepeatedExplainQueryStage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::ExplainQueryStage'->new($_) } @$_ ] };

declare 'MapStringExplainQueryStage',
    as HashRef[ExplainQueryStage()];

declare 'ComputeMode',
    as (Int | Str);

declare 'QueryTimelineSample',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::QueryTimelineSample'];

coerce 'QueryTimelineSample',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::QueryTimelineSample'->new($_) };

declare 'RepeatedQueryTimelineSample',
    as ArrayRef[QueryTimelineSample()];

coerce 'RepeatedQueryTimelineSample',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::QueryTimelineSample'->new($_) } @$_ ] };

declare 'MapStringQueryTimelineSample',
    as HashRef[QueryTimelineSample()];

declare 'ReservationResourceUsage',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::ReservationResourceUsage'];

coerce 'ReservationResourceUsage',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::ReservationResourceUsage'->new($_) };

declare 'RepeatedReservationResourceUsage',
    as ArrayRef[ReservationResourceUsage()];

coerce 'RepeatedReservationResourceUsage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::ReservationResourceUsage'->new($_) } @$_ ] };

declare 'MapStringReservationResourceUsage',
    as HashRef[ReservationResourceUsage()];

declare 'BigQueryModelTraining',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::BigQueryModelTraining'];

coerce 'BigQueryModelTraining',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::BigQueryModelTraining'->new($_) };

declare 'RepeatedBigQueryModelTraining',
    as ArrayRef[BigQueryModelTraining()];

coerce 'RepeatedBigQueryModelTraining',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::BigQueryModelTraining'->new($_) } @$_ ] };

declare 'MapStringBigQueryModelTraining',
    as HashRef[BigQueryModelTraining()];

declare 'ExternalServiceCost',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::ExternalServiceCost'];

coerce 'ExternalServiceCost',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::ExternalServiceCost'->new($_) };

declare 'RepeatedExternalServiceCost',
    as ArrayRef[ExternalServiceCost()];

coerce 'RepeatedExternalServiceCost',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::ExternalServiceCost'->new($_) } @$_ ] };

declare 'MapStringExternalServiceCost',
    as HashRef[ExternalServiceCost()];

declare 'BigtableUpdateStatistics',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::BigtableUpdateStatistics'];

coerce 'BigtableUpdateStatistics',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::BigtableUpdateStatistics'->new($_) };

declare 'RepeatedBigtableUpdateStatistics',
    as ArrayRef[BigtableUpdateStatistics()];

coerce 'RepeatedBigtableUpdateStatistics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::BigtableUpdateStatistics'->new($_) } @$_ ] };

declare 'MapStringBigtableUpdateStatistics',
    as HashRef[BigtableUpdateStatistics()];

declare 'SpannerUpdateStatistics',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::SpannerUpdateStatistics'];

coerce 'SpannerUpdateStatistics',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::SpannerUpdateStatistics'->new($_) };

declare 'RepeatedSpannerUpdateStatistics',
    as ArrayRef[SpannerUpdateStatistics()];

coerce 'RepeatedSpannerUpdateStatistics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::SpannerUpdateStatistics'->new($_) } @$_ ] };

declare 'MapStringSpannerUpdateStatistics',
    as HashRef[SpannerUpdateStatistics()];

declare 'ExportDataStatistics',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::ExportDataStatistics'];

coerce 'ExportDataStatistics',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::ExportDataStatistics'->new($_) };

declare 'RepeatedExportDataStatistics',
    as ArrayRef[ExportDataStatistics()];

coerce 'RepeatedExportDataStatistics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::ExportDataStatistics'->new($_) } @$_ ] };

declare 'MapStringExportDataStatistics',
    as HashRef[ExportDataStatistics()];

declare 'BiEngineReason',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::BiEngineReason'];

coerce 'BiEngineReason',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::BiEngineReason'->new($_) };

declare 'RepeatedBiEngineReason',
    as ArrayRef[BiEngineReason()];

coerce 'RepeatedBiEngineReason',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::BiEngineReason'->new($_) } @$_ ] };

declare 'MapStringBiEngineReason',
    as HashRef[BiEngineReason()];

declare 'Code',
    as (Int | Str);

declare 'BiEngineStatistics',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::BiEngineStatistics'];

coerce 'BiEngineStatistics',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::BiEngineStatistics'->new($_) };

declare 'RepeatedBiEngineStatistics',
    as ArrayRef[BiEngineStatistics()];

coerce 'RepeatedBiEngineStatistics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::BiEngineStatistics'->new($_) } @$_ ] };

declare 'MapStringBiEngineStatistics',
    as HashRef[BiEngineStatistics()];

declare 'BiEngineMode',
    as (Int | Str);

declare 'BiEngineAccelerationMode',
    as (Int | Str);

declare 'IndexUnusedReason',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::IndexUnusedReason'];

coerce 'IndexUnusedReason',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::IndexUnusedReason'->new($_) };

declare 'RepeatedIndexUnusedReason',
    as ArrayRef[IndexUnusedReason()];

coerce 'RepeatedIndexUnusedReason',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::IndexUnusedReason'->new($_) } @$_ ] };

declare 'MapStringIndexUnusedReason',
    as HashRef[IndexUnusedReason()];

declare 'Code',
    as (Int | Str);

declare 'IndexPruningStats',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::IndexPruningStats'];

coerce 'IndexPruningStats',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::IndexPruningStats'->new($_) };

declare 'RepeatedIndexPruningStats',
    as ArrayRef[IndexPruningStats()];

coerce 'RepeatedIndexPruningStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::IndexPruningStats'->new($_) } @$_ ] };

declare 'MapStringIndexPruningStats',
    as HashRef[IndexPruningStats()];

declare 'StoredColumnsUsage',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::StoredColumnsUsage'];

coerce 'StoredColumnsUsage',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::StoredColumnsUsage'->new($_) };

declare 'RepeatedStoredColumnsUsage',
    as ArrayRef[StoredColumnsUsage()];

coerce 'RepeatedStoredColumnsUsage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::StoredColumnsUsage'->new($_) } @$_ ] };

declare 'MapStringStoredColumnsUsage',
    as HashRef[StoredColumnsUsage()];

declare 'StoredColumnsUnusedReason',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::StoredColumnsUsage::StoredColumnsUnusedReason'];

coerce 'StoredColumnsUnusedReason',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::StoredColumnsUsage::StoredColumnsUnusedReason'->new($_) };

declare 'RepeatedStoredColumnsUnusedReason',
    as ArrayRef[StoredColumnsUnusedReason()];

coerce 'RepeatedStoredColumnsUnusedReason',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::StoredColumnsUsage::StoredColumnsUnusedReason'->new($_) } @$_ ] };

declare 'MapStringStoredColumnsUnusedReason',
    as HashRef[StoredColumnsUnusedReason()];

declare 'Code',
    as (Int | Str);

declare 'SearchStatistics',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::SearchStatistics'];

coerce 'SearchStatistics',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::SearchStatistics'->new($_) };

declare 'RepeatedSearchStatistics',
    as ArrayRef[SearchStatistics()];

coerce 'RepeatedSearchStatistics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::SearchStatistics'->new($_) } @$_ ] };

declare 'MapStringSearchStatistics',
    as HashRef[SearchStatistics()];

declare 'IndexUsageMode',
    as (Int | Str);

declare 'VectorSearchStatistics',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::VectorSearchStatistics'];

coerce 'VectorSearchStatistics',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::VectorSearchStatistics'->new($_) };

declare 'RepeatedVectorSearchStatistics',
    as ArrayRef[VectorSearchStatistics()];

coerce 'RepeatedVectorSearchStatistics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::VectorSearchStatistics'->new($_) } @$_ ] };

declare 'MapStringVectorSearchStatistics',
    as HashRef[VectorSearchStatistics()];

declare 'IndexUsageMode',
    as (Int | Str);

declare 'SearchIndexingStats',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::SearchIndexingStats'];

coerce 'SearchIndexingStats',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::SearchIndexingStats'->new($_) };

declare 'RepeatedSearchIndexingStats',
    as ArrayRef[SearchIndexingStats()];

coerce 'RepeatedSearchIndexingStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::SearchIndexingStats'->new($_) } @$_ ] };

declare 'MapStringSearchIndexingStats',
    as HashRef[SearchIndexingStats()];

declare 'VectorSearchIndexingStats',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::VectorSearchIndexingStats'];

coerce 'VectorSearchIndexingStats',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::VectorSearchIndexingStats'->new($_) };

declare 'RepeatedVectorSearchIndexingStats',
    as ArrayRef[VectorSearchIndexingStats()];

coerce 'RepeatedVectorSearchIndexingStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::VectorSearchIndexingStats'->new($_) } @$_ ] };

declare 'MapStringVectorSearchIndexingStats',
    as HashRef[VectorSearchIndexingStats()];

declare 'QueryInfo',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::QueryInfo'];

coerce 'QueryInfo',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::QueryInfo'->new($_) };

declare 'RepeatedQueryInfo',
    as ArrayRef[QueryInfo()];

coerce 'RepeatedQueryInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::QueryInfo'->new($_) } @$_ ] };

declare 'MapStringQueryInfo',
    as HashRef[QueryInfo()];

declare 'LoadQueryStatistics',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::LoadQueryStatistics'];

coerce 'LoadQueryStatistics',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::LoadQueryStatistics'->new($_) };

declare 'RepeatedLoadQueryStatistics',
    as ArrayRef[LoadQueryStatistics()];

coerce 'RepeatedLoadQueryStatistics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::LoadQueryStatistics'->new($_) } @$_ ] };

declare 'MapStringLoadQueryStatistics',
    as HashRef[LoadQueryStatistics()];

declare 'IncrementalResultStats',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::IncrementalResultStats'];

coerce 'IncrementalResultStats',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::IncrementalResultStats'->new($_) };

declare 'RepeatedIncrementalResultStats',
    as ArrayRef[IncrementalResultStats()];

coerce 'RepeatedIncrementalResultStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::IncrementalResultStats'->new($_) } @$_ ] };

declare 'MapStringIncrementalResultStats',
    as HashRef[IncrementalResultStats()];

declare 'DisabledReason',
    as (Int | Str);

declare 'JobStatistics2',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::JobStatistics2'];

coerce 'JobStatistics2',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::JobStatistics2'->new($_) };

declare 'RepeatedJobStatistics2',
    as ArrayRef[JobStatistics2()];

coerce 'RepeatedJobStatistics2',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::JobStatistics2'->new($_) } @$_ ] };

declare 'MapStringJobStatistics2',
    as HashRef[JobStatistics2()];

declare 'JobStatistics3',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::JobStatistics3'];

coerce 'JobStatistics3',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::JobStatistics3'->new($_) };

declare 'RepeatedJobStatistics3',
    as ArrayRef[JobStatistics3()];

coerce 'RepeatedJobStatistics3',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::JobStatistics3'->new($_) } @$_ ] };

declare 'MapStringJobStatistics3',
    as HashRef[JobStatistics3()];

declare 'JobStatistics4',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::JobStatistics4'];

coerce 'JobStatistics4',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::JobStatistics4'->new($_) };

declare 'RepeatedJobStatistics4',
    as ArrayRef[JobStatistics4()];

coerce 'RepeatedJobStatistics4',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::JobStatistics4'->new($_) } @$_ ] };

declare 'MapStringJobStatistics4',
    as HashRef[JobStatistics4()];

declare 'CopyJobStatistics',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::CopyJobStatistics'];

coerce 'CopyJobStatistics',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::CopyJobStatistics'->new($_) };

declare 'RepeatedCopyJobStatistics',
    as ArrayRef[CopyJobStatistics()];

coerce 'RepeatedCopyJobStatistics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::CopyJobStatistics'->new($_) } @$_ ] };

declare 'MapStringCopyJobStatistics',
    as HashRef[CopyJobStatistics()];

declare 'MlStatistics',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::MlStatistics'];

coerce 'MlStatistics',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::MlStatistics'->new($_) };

declare 'RepeatedMlStatistics',
    as ArrayRef[MlStatistics()];

coerce 'RepeatedMlStatistics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::MlStatistics'->new($_) } @$_ ] };

declare 'MapStringMlStatistics',
    as HashRef[MlStatistics()];

declare 'TrainingType',
    as (Int | Str);

declare 'ScriptStatistics',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::ScriptStatistics'];

coerce 'ScriptStatistics',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::ScriptStatistics'->new($_) };

declare 'RepeatedScriptStatistics',
    as ArrayRef[ScriptStatistics()];

coerce 'RepeatedScriptStatistics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::ScriptStatistics'->new($_) } @$_ ] };

declare 'MapStringScriptStatistics',
    as HashRef[ScriptStatistics()];

declare 'EvaluationKind',
    as (Int | Str);

declare 'ScriptStackFrame',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::ScriptStatistics::ScriptStackFrame'];

coerce 'ScriptStackFrame',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::ScriptStatistics::ScriptStackFrame'->new($_) };

declare 'RepeatedScriptStackFrame',
    as ArrayRef[ScriptStackFrame()];

coerce 'RepeatedScriptStackFrame',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::ScriptStatistics::ScriptStackFrame'->new($_) } @$_ ] };

declare 'MapStringScriptStackFrame',
    as HashRef[ScriptStackFrame()];

declare 'RowLevelSecurityStatistics',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::RowLevelSecurityStatistics'];

coerce 'RowLevelSecurityStatistics',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::RowLevelSecurityStatistics'->new($_) };

declare 'RepeatedRowLevelSecurityStatistics',
    as ArrayRef[RowLevelSecurityStatistics()];

coerce 'RepeatedRowLevelSecurityStatistics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::RowLevelSecurityStatistics'->new($_) } @$_ ] };

declare 'MapStringRowLevelSecurityStatistics',
    as HashRef[RowLevelSecurityStatistics()];

declare 'DataMaskingStatistics',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::DataMaskingStatistics'];

coerce 'DataMaskingStatistics',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::DataMaskingStatistics'->new($_) };

declare 'RepeatedDataMaskingStatistics',
    as ArrayRef[DataMaskingStatistics()];

coerce 'RepeatedDataMaskingStatistics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::DataMaskingStatistics'->new($_) } @$_ ] };

declare 'MapStringDataMaskingStatistics',
    as HashRef[DataMaskingStatistics()];

declare 'JobStatistics',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::JobStatistics'];

coerce 'JobStatistics',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::JobStatistics'->new($_) };

declare 'RepeatedJobStatistics',
    as ArrayRef[JobStatistics()];

coerce 'RepeatedJobStatistics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::JobStatistics'->new($_) } @$_ ] };

declare 'MapStringJobStatistics',
    as HashRef[JobStatistics()];

declare 'TransactionInfo',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::JobStatistics::TransactionInfo'];

coerce 'TransactionInfo',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::JobStatistics::TransactionInfo'->new($_) };

declare 'RepeatedTransactionInfo',
    as ArrayRef[TransactionInfo()];

coerce 'RepeatedTransactionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::JobStatistics::TransactionInfo'->new($_) } @$_ ] };

declare 'MapStringTransactionInfo',
    as HashRef[TransactionInfo()];

declare 'DmlStats',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::DmlStats'];

coerce 'DmlStats',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::DmlStats'->new($_) };

declare 'RepeatedDmlStats',
    as ArrayRef[DmlStats()];

coerce 'RepeatedDmlStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::DmlStats'->new($_) } @$_ ] };

declare 'MapStringDmlStats',
    as HashRef[DmlStats()];

declare 'DmlMode',
    as (Int | Str);

declare 'FineGrainedDmlUnusedReason',
    as (Int | Str);

declare 'PerformanceInsights',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::PerformanceInsights'];

coerce 'PerformanceInsights',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::PerformanceInsights'->new($_) };

declare 'RepeatedPerformanceInsights',
    as ArrayRef[PerformanceInsights()];

coerce 'RepeatedPerformanceInsights',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::PerformanceInsights'->new($_) } @$_ ] };

declare 'MapStringPerformanceInsights',
    as HashRef[PerformanceInsights()];

declare 'StagePerformanceChangeInsight',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::StagePerformanceChangeInsight'];

coerce 'StagePerformanceChangeInsight',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::StagePerformanceChangeInsight'->new($_) };

declare 'RepeatedStagePerformanceChangeInsight',
    as ArrayRef[StagePerformanceChangeInsight()];

coerce 'RepeatedStagePerformanceChangeInsight',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::StagePerformanceChangeInsight'->new($_) } @$_ ] };

declare 'MapStringStagePerformanceChangeInsight',
    as HashRef[StagePerformanceChangeInsight()];

declare 'InputDataChange',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::InputDataChange'];

coerce 'InputDataChange',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::InputDataChange'->new($_) };

declare 'RepeatedInputDataChange',
    as ArrayRef[InputDataChange()];

coerce 'RepeatedInputDataChange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::InputDataChange'->new($_) } @$_ ] };

declare 'MapStringInputDataChange',
    as HashRef[InputDataChange()];

declare 'StagePerformanceStandaloneInsight',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::StagePerformanceStandaloneInsight'];

coerce 'StagePerformanceStandaloneInsight',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::StagePerformanceStandaloneInsight'->new($_) };

declare 'RepeatedStagePerformanceStandaloneInsight',
    as ArrayRef[StagePerformanceStandaloneInsight()];

coerce 'RepeatedStagePerformanceStandaloneInsight',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::StagePerformanceStandaloneInsight'->new($_) } @$_ ] };

declare 'MapStringStagePerformanceStandaloneInsight',
    as HashRef[StagePerformanceStandaloneInsight()];

declare 'HighCardinalityJoin',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::HighCardinalityJoin'];

coerce 'HighCardinalityJoin',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::HighCardinalityJoin'->new($_) };

declare 'RepeatedHighCardinalityJoin',
    as ArrayRef[HighCardinalityJoin()];

coerce 'RepeatedHighCardinalityJoin',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::HighCardinalityJoin'->new($_) } @$_ ] };

declare 'MapStringHighCardinalityJoin',
    as HashRef[HighCardinalityJoin()];

declare 'PartitionSkew',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::PartitionSkew'];

coerce 'PartitionSkew',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::PartitionSkew'->new($_) };

declare 'RepeatedPartitionSkew',
    as ArrayRef[PartitionSkew()];

coerce 'RepeatedPartitionSkew',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::PartitionSkew'->new($_) } @$_ ] };

declare 'MapStringPartitionSkew',
    as HashRef[PartitionSkew()];

declare 'SkewSource',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::PartitionSkew::SkewSource'];

coerce 'SkewSource',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::PartitionSkew::SkewSource'->new($_) };

declare 'RepeatedSkewSource',
    as ArrayRef[SkewSource()];

coerce 'RepeatedSkewSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::PartitionSkew::SkewSource'->new($_) } @$_ ] };

declare 'MapStringSkewSource',
    as HashRef[SkewSource()];

declare 'TableChangeInsight',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::TableChangeInsight'];

coerce 'TableChangeInsight',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::TableChangeInsight'->new($_) };

declare 'RepeatedTableChangeInsight',
    as ArrayRef[TableChangeInsight()];

coerce 'RepeatedTableChangeInsight',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::TableChangeInsight'->new($_) } @$_ ] };

declare 'MapStringTableChangeInsight',
    as HashRef[TableChangeInsight()];

declare 'MetadataCacheStalenessInsight',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::MetadataCacheStalenessInsight'];

coerce 'MetadataCacheStalenessInsight',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::MetadataCacheStalenessInsight'->new($_) };

declare 'RepeatedMetadataCacheStalenessInsight',
    as ArrayRef[MetadataCacheStalenessInsight()];

coerce 'RepeatedMetadataCacheStalenessInsight',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::MetadataCacheStalenessInsight'->new($_) } @$_ ] };

declare 'MapStringMetadataCacheStalenessInsight',
    as HashRef[MetadataCacheStalenessInsight()];

declare 'SparkStatistics',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::SparkStatistics'];

coerce 'SparkStatistics',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::SparkStatistics'->new($_) };

declare 'RepeatedSparkStatistics',
    as ArrayRef[SparkStatistics()];

coerce 'RepeatedSparkStatistics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::SparkStatistics'->new($_) } @$_ ] };

declare 'MapStringSparkStatistics',
    as HashRef[SparkStatistics()];

declare 'EndpointsEntry',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::SparkStatistics::EndpointsEntry'];

coerce 'EndpointsEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::SparkStatistics::EndpointsEntry'->new($_) };

declare 'RepeatedEndpointsEntry',
    as ArrayRef[EndpointsEntry()];

coerce 'RepeatedEndpointsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::SparkStatistics::EndpointsEntry'->new($_) } @$_ ] };

declare 'MapStringEndpointsEntry',
    as HashRef[EndpointsEntry()];

declare 'LoggingInfo',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::SparkStatistics::LoggingInfo'];

coerce 'LoggingInfo',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::SparkStatistics::LoggingInfo'->new($_) };

declare 'RepeatedLoggingInfo',
    as ArrayRef[LoggingInfo()];

coerce 'RepeatedLoggingInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::SparkStatistics::LoggingInfo'->new($_) } @$_ ] };

declare 'MapStringLoggingInfo',
    as HashRef[LoggingInfo()];

declare 'MaterializedViewStatistics',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::MaterializedViewStatistics'];

coerce 'MaterializedViewStatistics',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::MaterializedViewStatistics'->new($_) };

declare 'RepeatedMaterializedViewStatistics',
    as ArrayRef[MaterializedViewStatistics()];

coerce 'RepeatedMaterializedViewStatistics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::MaterializedViewStatistics'->new($_) } @$_ ] };

declare 'MapStringMaterializedViewStatistics',
    as HashRef[MaterializedViewStatistics()];

declare 'MaterializedView',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::MaterializedView'];

coerce 'MaterializedView',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::MaterializedView'->new($_) };

declare 'RepeatedMaterializedView',
    as ArrayRef[MaterializedView()];

coerce 'RepeatedMaterializedView',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::MaterializedView'->new($_) } @$_ ] };

declare 'MapStringMaterializedView',
    as HashRef[MaterializedView()];

declare 'RejectedReason',
    as (Int | Str);

declare 'PruningStats',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::PruningStats'];

coerce 'PruningStats',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::PruningStats'->new($_) };

declare 'RepeatedPruningStats',
    as ArrayRef[PruningStats()];

coerce 'RepeatedPruningStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::PruningStats'->new($_) } @$_ ] };

declare 'MapStringPruningStats',
    as HashRef[PruningStats()];

declare 'TableMetadataCacheUsage',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::TableMetadataCacheUsage'];

coerce 'TableMetadataCacheUsage',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::TableMetadataCacheUsage'->new($_) };

declare 'RepeatedTableMetadataCacheUsage',
    as ArrayRef[TableMetadataCacheUsage()];

coerce 'RepeatedTableMetadataCacheUsage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::TableMetadataCacheUsage'->new($_) } @$_ ] };

declare 'MapStringTableMetadataCacheUsage',
    as HashRef[TableMetadataCacheUsage()];

declare 'UnusedReason',
    as (Int | Str);

declare 'MetadataCacheStatistics',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::MetadataCacheStatistics'];

coerce 'MetadataCacheStatistics',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::MetadataCacheStatistics'->new($_) };

declare 'RepeatedMetadataCacheStatistics',
    as ArrayRef[MetadataCacheStatistics()];

coerce 'RepeatedMetadataCacheStatistics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::MetadataCacheStatistics'->new($_) } @$_ ] };

declare 'MapStringMetadataCacheStatistics',
    as HashRef[MetadataCacheStatistics()];

declare 'PrivacyPolicyStats',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::PrivacyPolicyStats'];

coerce 'PrivacyPolicyStats',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::PrivacyPolicyStats'->new($_) };

declare 'RepeatedPrivacyPolicyStats',
    as ArrayRef[PrivacyPolicyStats()];

coerce 'RepeatedPrivacyPolicyStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::PrivacyPolicyStats'->new($_) } @$_ ] };

declare 'MapStringPrivacyPolicyStats',
    as HashRef[PrivacyPolicyStats()];

declare 'ContinuousQueryStatistics',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::ContinuousQueryStatistics'];

coerce 'ContinuousQueryStatistics',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::ContinuousQueryStatistics'->new($_) };

declare 'RepeatedContinuousQueryStatistics',
    as ArrayRef[ContinuousQueryStatistics()];

coerce 'RepeatedContinuousQueryStatistics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::ContinuousQueryStatistics'->new($_) } @$_ ] };

declare 'MapStringContinuousQueryStatistics',
    as HashRef[ContinuousQueryStatistics()];

declare 'DefaultConnectionStats',
    as InstanceOf['Google::Cloud::Bigquery::V2::JobStats::DefaultConnectionStats'];

coerce 'DefaultConnectionStats',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::JobStats::DefaultConnectionStats'->new($_) };

declare 'RepeatedDefaultConnectionStats',
    as ArrayRef[DefaultConnectionStats()];

coerce 'RepeatedDefaultConnectionStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::JobStats::DefaultConnectionStats'->new($_) } @$_ ] };

declare 'MapStringDefaultConnectionStats',
    as HashRef[DefaultConnectionStats()];

1;
