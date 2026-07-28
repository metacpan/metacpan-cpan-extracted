package Google::Dataflow::V1beta3::Metrics::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ExecutionState',
    as (Int | Str);

declare 'MetricStructuredName',
    as InstanceOf['Google::Dataflow::V1beta3::Metrics::MetricStructuredName'];

coerce 'MetricStructuredName',
    from HashRef, via { 'Google::Dataflow::V1beta3::Metrics::MetricStructuredName'->new($_) };

declare 'RepeatedMetricStructuredName',
    as ArrayRef[MetricStructuredName()];

coerce 'RepeatedMetricStructuredName',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Metrics::MetricStructuredName'->new($_) } @$_ ] };

declare 'MapStringMetricStructuredName',
    as HashRef[MetricStructuredName()];

declare 'ContextEntry',
    as InstanceOf['Google::Dataflow::V1beta3::Metrics::MetricStructuredName::ContextEntry'];

coerce 'ContextEntry',
    from HashRef, via { 'Google::Dataflow::V1beta3::Metrics::MetricStructuredName::ContextEntry'->new($_) };

declare 'RepeatedContextEntry',
    as ArrayRef[ContextEntry()];

coerce 'RepeatedContextEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Metrics::MetricStructuredName::ContextEntry'->new($_) } @$_ ] };

declare 'MapStringContextEntry',
    as HashRef[ContextEntry()];

declare 'MetricUpdate',
    as InstanceOf['Google::Dataflow::V1beta3::Metrics::MetricUpdate'];

coerce 'MetricUpdate',
    from HashRef, via { 'Google::Dataflow::V1beta3::Metrics::MetricUpdate'->new($_) };

declare 'RepeatedMetricUpdate',
    as ArrayRef[MetricUpdate()];

coerce 'RepeatedMetricUpdate',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Metrics::MetricUpdate'->new($_) } @$_ ] };

declare 'MapStringMetricUpdate',
    as HashRef[MetricUpdate()];

declare 'GetJobMetricsRequest',
    as InstanceOf['Google::Dataflow::V1beta3::Metrics::GetJobMetricsRequest'];

coerce 'GetJobMetricsRequest',
    from HashRef, via { 'Google::Dataflow::V1beta3::Metrics::GetJobMetricsRequest'->new($_) };

declare 'RepeatedGetJobMetricsRequest',
    as ArrayRef[GetJobMetricsRequest()];

coerce 'RepeatedGetJobMetricsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Metrics::GetJobMetricsRequest'->new($_) } @$_ ] };

declare 'MapStringGetJobMetricsRequest',
    as HashRef[GetJobMetricsRequest()];

declare 'JobMetrics',
    as InstanceOf['Google::Dataflow::V1beta3::Metrics::JobMetrics'];

coerce 'JobMetrics',
    from HashRef, via { 'Google::Dataflow::V1beta3::Metrics::JobMetrics'->new($_) };

declare 'RepeatedJobMetrics',
    as ArrayRef[JobMetrics()];

coerce 'RepeatedJobMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Metrics::JobMetrics'->new($_) } @$_ ] };

declare 'MapStringJobMetrics',
    as HashRef[JobMetrics()];

declare 'GetJobExecutionDetailsRequest',
    as InstanceOf['Google::Dataflow::V1beta3::Metrics::GetJobExecutionDetailsRequest'];

coerce 'GetJobExecutionDetailsRequest',
    from HashRef, via { 'Google::Dataflow::V1beta3::Metrics::GetJobExecutionDetailsRequest'->new($_) };

declare 'RepeatedGetJobExecutionDetailsRequest',
    as ArrayRef[GetJobExecutionDetailsRequest()];

coerce 'RepeatedGetJobExecutionDetailsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Metrics::GetJobExecutionDetailsRequest'->new($_) } @$_ ] };

declare 'MapStringGetJobExecutionDetailsRequest',
    as HashRef[GetJobExecutionDetailsRequest()];

declare 'ProgressTimeseries',
    as InstanceOf['Google::Dataflow::V1beta3::Metrics::ProgressTimeseries'];

coerce 'ProgressTimeseries',
    from HashRef, via { 'Google::Dataflow::V1beta3::Metrics::ProgressTimeseries'->new($_) };

declare 'RepeatedProgressTimeseries',
    as ArrayRef[ProgressTimeseries()];

coerce 'RepeatedProgressTimeseries',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Metrics::ProgressTimeseries'->new($_) } @$_ ] };

declare 'MapStringProgressTimeseries',
    as HashRef[ProgressTimeseries()];

declare 'Point',
    as InstanceOf['Google::Dataflow::V1beta3::Metrics::ProgressTimeseries::Point'];

coerce 'Point',
    from HashRef, via { 'Google::Dataflow::V1beta3::Metrics::ProgressTimeseries::Point'->new($_) };

declare 'RepeatedPoint',
    as ArrayRef[Point()];

coerce 'RepeatedPoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Metrics::ProgressTimeseries::Point'->new($_) } @$_ ] };

declare 'MapStringPoint',
    as HashRef[Point()];

declare 'StragglerInfo',
    as InstanceOf['Google::Dataflow::V1beta3::Metrics::StragglerInfo'];

coerce 'StragglerInfo',
    from HashRef, via { 'Google::Dataflow::V1beta3::Metrics::StragglerInfo'->new($_) };

declare 'RepeatedStragglerInfo',
    as ArrayRef[StragglerInfo()];

coerce 'RepeatedStragglerInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Metrics::StragglerInfo'->new($_) } @$_ ] };

declare 'MapStringStragglerInfo',
    as HashRef[StragglerInfo()];

declare 'StragglerDebuggingInfo',
    as InstanceOf['Google::Dataflow::V1beta3::Metrics::StragglerInfo::StragglerDebuggingInfo'];

coerce 'StragglerDebuggingInfo',
    from HashRef, via { 'Google::Dataflow::V1beta3::Metrics::StragglerInfo::StragglerDebuggingInfo'->new($_) };

declare 'RepeatedStragglerDebuggingInfo',
    as ArrayRef[StragglerDebuggingInfo()];

coerce 'RepeatedStragglerDebuggingInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Metrics::StragglerInfo::StragglerDebuggingInfo'->new($_) } @$_ ] };

declare 'MapStringStragglerDebuggingInfo',
    as HashRef[StragglerDebuggingInfo()];

declare 'CausesEntry',
    as InstanceOf['Google::Dataflow::V1beta3::Metrics::StragglerInfo::CausesEntry'];

coerce 'CausesEntry',
    from HashRef, via { 'Google::Dataflow::V1beta3::Metrics::StragglerInfo::CausesEntry'->new($_) };

declare 'RepeatedCausesEntry',
    as ArrayRef[CausesEntry()];

coerce 'RepeatedCausesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Metrics::StragglerInfo::CausesEntry'->new($_) } @$_ ] };

declare 'MapStringCausesEntry',
    as HashRef[CausesEntry()];

declare 'StreamingStragglerInfo',
    as InstanceOf['Google::Dataflow::V1beta3::Metrics::StreamingStragglerInfo'];

coerce 'StreamingStragglerInfo',
    from HashRef, via { 'Google::Dataflow::V1beta3::Metrics::StreamingStragglerInfo'->new($_) };

declare 'RepeatedStreamingStragglerInfo',
    as ArrayRef[StreamingStragglerInfo()];

coerce 'RepeatedStreamingStragglerInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Metrics::StreamingStragglerInfo'->new($_) } @$_ ] };

declare 'MapStringStreamingStragglerInfo',
    as HashRef[StreamingStragglerInfo()];

declare 'Straggler',
    as InstanceOf['Google::Dataflow::V1beta3::Metrics::Straggler'];

coerce 'Straggler',
    from HashRef, via { 'Google::Dataflow::V1beta3::Metrics::Straggler'->new($_) };

declare 'RepeatedStraggler',
    as ArrayRef[Straggler()];

coerce 'RepeatedStraggler',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Metrics::Straggler'->new($_) } @$_ ] };

declare 'MapStringStraggler',
    as HashRef[Straggler()];

declare 'HotKeyDebuggingInfo',
    as InstanceOf['Google::Dataflow::V1beta3::Metrics::HotKeyDebuggingInfo'];

coerce 'HotKeyDebuggingInfo',
    from HashRef, via { 'Google::Dataflow::V1beta3::Metrics::HotKeyDebuggingInfo'->new($_) };

declare 'RepeatedHotKeyDebuggingInfo',
    as ArrayRef[HotKeyDebuggingInfo()];

coerce 'RepeatedHotKeyDebuggingInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Metrics::HotKeyDebuggingInfo'->new($_) } @$_ ] };

declare 'MapStringHotKeyDebuggingInfo',
    as HashRef[HotKeyDebuggingInfo()];

declare 'HotKeyInfo',
    as InstanceOf['Google::Dataflow::V1beta3::Metrics::HotKeyDebuggingInfo::HotKeyInfo'];

coerce 'HotKeyInfo',
    from HashRef, via { 'Google::Dataflow::V1beta3::Metrics::HotKeyDebuggingInfo::HotKeyInfo'->new($_) };

declare 'RepeatedHotKeyInfo',
    as ArrayRef[HotKeyInfo()];

coerce 'RepeatedHotKeyInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Metrics::HotKeyDebuggingInfo::HotKeyInfo'->new($_) } @$_ ] };

declare 'MapStringHotKeyInfo',
    as HashRef[HotKeyInfo()];

declare 'DetectedHotKeysEntry',
    as InstanceOf['Google::Dataflow::V1beta3::Metrics::HotKeyDebuggingInfo::DetectedHotKeysEntry'];

coerce 'DetectedHotKeysEntry',
    from HashRef, via { 'Google::Dataflow::V1beta3::Metrics::HotKeyDebuggingInfo::DetectedHotKeysEntry'->new($_) };

declare 'RepeatedDetectedHotKeysEntry',
    as ArrayRef[DetectedHotKeysEntry()];

coerce 'RepeatedDetectedHotKeysEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Metrics::HotKeyDebuggingInfo::DetectedHotKeysEntry'->new($_) } @$_ ] };

declare 'MapStringDetectedHotKeysEntry',
    as HashRef[DetectedHotKeysEntry()];

declare 'StragglerSummary',
    as InstanceOf['Google::Dataflow::V1beta3::Metrics::StragglerSummary'];

coerce 'StragglerSummary',
    from HashRef, via { 'Google::Dataflow::V1beta3::Metrics::StragglerSummary'->new($_) };

declare 'RepeatedStragglerSummary',
    as ArrayRef[StragglerSummary()];

coerce 'RepeatedStragglerSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Metrics::StragglerSummary'->new($_) } @$_ ] };

declare 'MapStringStragglerSummary',
    as HashRef[StragglerSummary()];

declare 'StragglerCauseCountEntry',
    as InstanceOf['Google::Dataflow::V1beta3::Metrics::StragglerSummary::StragglerCauseCountEntry'];

coerce 'StragglerCauseCountEntry',
    from HashRef, via { 'Google::Dataflow::V1beta3::Metrics::StragglerSummary::StragglerCauseCountEntry'->new($_) };

declare 'RepeatedStragglerCauseCountEntry',
    as ArrayRef[StragglerCauseCountEntry()];

coerce 'RepeatedStragglerCauseCountEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Metrics::StragglerSummary::StragglerCauseCountEntry'->new($_) } @$_ ] };

declare 'MapStringStragglerCauseCountEntry',
    as HashRef[StragglerCauseCountEntry()];

declare 'StageSummary',
    as InstanceOf['Google::Dataflow::V1beta3::Metrics::StageSummary'];

coerce 'StageSummary',
    from HashRef, via { 'Google::Dataflow::V1beta3::Metrics::StageSummary'->new($_) };

declare 'RepeatedStageSummary',
    as ArrayRef[StageSummary()];

coerce 'RepeatedStageSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Metrics::StageSummary'->new($_) } @$_ ] };

declare 'MapStringStageSummary',
    as HashRef[StageSummary()];

declare 'JobExecutionDetails',
    as InstanceOf['Google::Dataflow::V1beta3::Metrics::JobExecutionDetails'];

coerce 'JobExecutionDetails',
    from HashRef, via { 'Google::Dataflow::V1beta3::Metrics::JobExecutionDetails'->new($_) };

declare 'RepeatedJobExecutionDetails',
    as ArrayRef[JobExecutionDetails()];

coerce 'RepeatedJobExecutionDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Metrics::JobExecutionDetails'->new($_) } @$_ ] };

declare 'MapStringJobExecutionDetails',
    as HashRef[JobExecutionDetails()];

declare 'GetStageExecutionDetailsRequest',
    as InstanceOf['Google::Dataflow::V1beta3::Metrics::GetStageExecutionDetailsRequest'];

coerce 'GetStageExecutionDetailsRequest',
    from HashRef, via { 'Google::Dataflow::V1beta3::Metrics::GetStageExecutionDetailsRequest'->new($_) };

declare 'RepeatedGetStageExecutionDetailsRequest',
    as ArrayRef[GetStageExecutionDetailsRequest()];

coerce 'RepeatedGetStageExecutionDetailsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Metrics::GetStageExecutionDetailsRequest'->new($_) } @$_ ] };

declare 'MapStringGetStageExecutionDetailsRequest',
    as HashRef[GetStageExecutionDetailsRequest()];

declare 'WorkItemDetails',
    as InstanceOf['Google::Dataflow::V1beta3::Metrics::WorkItemDetails'];

coerce 'WorkItemDetails',
    from HashRef, via { 'Google::Dataflow::V1beta3::Metrics::WorkItemDetails'->new($_) };

declare 'RepeatedWorkItemDetails',
    as ArrayRef[WorkItemDetails()];

coerce 'RepeatedWorkItemDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Metrics::WorkItemDetails'->new($_) } @$_ ] };

declare 'MapStringWorkItemDetails',
    as HashRef[WorkItemDetails()];

declare 'WorkerDetails',
    as InstanceOf['Google::Dataflow::V1beta3::Metrics::WorkerDetails'];

coerce 'WorkerDetails',
    from HashRef, via { 'Google::Dataflow::V1beta3::Metrics::WorkerDetails'->new($_) };

declare 'RepeatedWorkerDetails',
    as ArrayRef[WorkerDetails()];

coerce 'RepeatedWorkerDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Metrics::WorkerDetails'->new($_) } @$_ ] };

declare 'MapStringWorkerDetails',
    as HashRef[WorkerDetails()];

declare 'StageExecutionDetails',
    as InstanceOf['Google::Dataflow::V1beta3::Metrics::StageExecutionDetails'];

coerce 'StageExecutionDetails',
    from HashRef, via { 'Google::Dataflow::V1beta3::Metrics::StageExecutionDetails'->new($_) };

declare 'RepeatedStageExecutionDetails',
    as ArrayRef[StageExecutionDetails()];

coerce 'RepeatedStageExecutionDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Metrics::StageExecutionDetails'->new($_) } @$_ ] };

declare 'MapStringStageExecutionDetails',
    as HashRef[StageExecutionDetails()];

1;

__END__

=head1 NAME

Google::Dataflow::V1beta3::Metrics::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
