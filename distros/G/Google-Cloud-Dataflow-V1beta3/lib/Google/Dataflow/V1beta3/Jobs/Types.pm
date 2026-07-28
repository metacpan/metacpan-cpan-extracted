package Google::Dataflow::V1beta3::Jobs::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'KindType',
    as (Int | Str);

declare 'JobState',
    as (Int | Str);

declare 'JobView',
    as (Int | Str);

declare 'Job',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::Job'];

coerce 'Job',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::Job'->new($_) };

declare 'RepeatedJob',
    as ArrayRef[Job()];

coerce 'RepeatedJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::Job'->new($_) } @$_ ] };

declare 'MapStringJob',
    as HashRef[Job()];

declare 'TransformNameMappingEntry',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::Job::TransformNameMappingEntry'];

coerce 'TransformNameMappingEntry',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::Job::TransformNameMappingEntry'->new($_) };

declare 'RepeatedTransformNameMappingEntry',
    as ArrayRef[TransformNameMappingEntry()];

coerce 'RepeatedTransformNameMappingEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::Job::TransformNameMappingEntry'->new($_) } @$_ ] };

declare 'MapStringTransformNameMappingEntry',
    as HashRef[TransformNameMappingEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::Job::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::Job::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::Job::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ServiceResources',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::ServiceResources'];

coerce 'ServiceResources',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::ServiceResources'->new($_) };

declare 'RepeatedServiceResources',
    as ArrayRef[ServiceResources()];

coerce 'RepeatedServiceResources',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::ServiceResources'->new($_) } @$_ ] };

declare 'MapStringServiceResources',
    as HashRef[ServiceResources()];

declare 'RuntimeUpdatableParams',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::RuntimeUpdatableParams'];

coerce 'RuntimeUpdatableParams',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::RuntimeUpdatableParams'->new($_) };

declare 'RepeatedRuntimeUpdatableParams',
    as ArrayRef[RuntimeUpdatableParams()];

coerce 'RepeatedRuntimeUpdatableParams',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::RuntimeUpdatableParams'->new($_) } @$_ ] };

declare 'MapStringRuntimeUpdatableParams',
    as HashRef[RuntimeUpdatableParams()];

declare 'DatastoreIODetails',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::DatastoreIODetails'];

coerce 'DatastoreIODetails',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::DatastoreIODetails'->new($_) };

declare 'RepeatedDatastoreIODetails',
    as ArrayRef[DatastoreIODetails()];

coerce 'RepeatedDatastoreIODetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::DatastoreIODetails'->new($_) } @$_ ] };

declare 'MapStringDatastoreIODetails',
    as HashRef[DatastoreIODetails()];

declare 'PubSubIODetails',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::PubSubIODetails'];

coerce 'PubSubIODetails',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::PubSubIODetails'->new($_) };

declare 'RepeatedPubSubIODetails',
    as ArrayRef[PubSubIODetails()];

coerce 'RepeatedPubSubIODetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::PubSubIODetails'->new($_) } @$_ ] };

declare 'MapStringPubSubIODetails',
    as HashRef[PubSubIODetails()];

declare 'FileIODetails',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::FileIODetails'];

coerce 'FileIODetails',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::FileIODetails'->new($_) };

declare 'RepeatedFileIODetails',
    as ArrayRef[FileIODetails()];

coerce 'RepeatedFileIODetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::FileIODetails'->new($_) } @$_ ] };

declare 'MapStringFileIODetails',
    as HashRef[FileIODetails()];

declare 'BigTableIODetails',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::BigTableIODetails'];

coerce 'BigTableIODetails',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::BigTableIODetails'->new($_) };

declare 'RepeatedBigTableIODetails',
    as ArrayRef[BigTableIODetails()];

coerce 'RepeatedBigTableIODetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::BigTableIODetails'->new($_) } @$_ ] };

declare 'MapStringBigTableIODetails',
    as HashRef[BigTableIODetails()];

declare 'BigQueryIODetails',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::BigQueryIODetails'];

coerce 'BigQueryIODetails',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::BigQueryIODetails'->new($_) };

declare 'RepeatedBigQueryIODetails',
    as ArrayRef[BigQueryIODetails()];

coerce 'RepeatedBigQueryIODetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::BigQueryIODetails'->new($_) } @$_ ] };

declare 'MapStringBigQueryIODetails',
    as HashRef[BigQueryIODetails()];

declare 'SpannerIODetails',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::SpannerIODetails'];

coerce 'SpannerIODetails',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::SpannerIODetails'->new($_) };

declare 'RepeatedSpannerIODetails',
    as ArrayRef[SpannerIODetails()];

coerce 'RepeatedSpannerIODetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::SpannerIODetails'->new($_) } @$_ ] };

declare 'MapStringSpannerIODetails',
    as HashRef[SpannerIODetails()];

declare 'SdkVersion',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::SdkVersion'];

coerce 'SdkVersion',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::SdkVersion'->new($_) };

declare 'RepeatedSdkVersion',
    as ArrayRef[SdkVersion()];

coerce 'RepeatedSdkVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::SdkVersion'->new($_) } @$_ ] };

declare 'MapStringSdkVersion',
    as HashRef[SdkVersion()];

declare 'SdkSupportStatus',
    as (Int | Str);

declare 'SdkBug',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::SdkBug'];

coerce 'SdkBug',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::SdkBug'->new($_) };

declare 'RepeatedSdkBug',
    as ArrayRef[SdkBug()];

coerce 'RepeatedSdkBug',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::SdkBug'->new($_) } @$_ ] };

declare 'MapStringSdkBug',
    as HashRef[SdkBug()];

declare 'Type',
    as (Int | Str);

declare 'Severity',
    as (Int | Str);

declare 'JobMetadata',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::JobMetadata'];

coerce 'JobMetadata',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::JobMetadata'->new($_) };

declare 'RepeatedJobMetadata',
    as ArrayRef[JobMetadata()];

coerce 'RepeatedJobMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::JobMetadata'->new($_) } @$_ ] };

declare 'MapStringJobMetadata',
    as HashRef[JobMetadata()];

declare 'UserDisplayPropertiesEntry',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::JobMetadata::UserDisplayPropertiesEntry'];

coerce 'UserDisplayPropertiesEntry',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::JobMetadata::UserDisplayPropertiesEntry'->new($_) };

declare 'RepeatedUserDisplayPropertiesEntry',
    as ArrayRef[UserDisplayPropertiesEntry()];

coerce 'RepeatedUserDisplayPropertiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::JobMetadata::UserDisplayPropertiesEntry'->new($_) } @$_ ] };

declare 'MapStringUserDisplayPropertiesEntry',
    as HashRef[UserDisplayPropertiesEntry()];

declare 'ExecutionStageState',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::ExecutionStageState'];

coerce 'ExecutionStageState',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::ExecutionStageState'->new($_) };

declare 'RepeatedExecutionStageState',
    as ArrayRef[ExecutionStageState()];

coerce 'RepeatedExecutionStageState',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::ExecutionStageState'->new($_) } @$_ ] };

declare 'MapStringExecutionStageState',
    as HashRef[ExecutionStageState()];

declare 'PipelineDescription',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::PipelineDescription'];

coerce 'PipelineDescription',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::PipelineDescription'->new($_) };

declare 'RepeatedPipelineDescription',
    as ArrayRef[PipelineDescription()];

coerce 'RepeatedPipelineDescription',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::PipelineDescription'->new($_) } @$_ ] };

declare 'MapStringPipelineDescription',
    as HashRef[PipelineDescription()];

declare 'TransformSummary',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::TransformSummary'];

coerce 'TransformSummary',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::TransformSummary'->new($_) };

declare 'RepeatedTransformSummary',
    as ArrayRef[TransformSummary()];

coerce 'RepeatedTransformSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::TransformSummary'->new($_) } @$_ ] };

declare 'MapStringTransformSummary',
    as HashRef[TransformSummary()];

declare 'ExecutionStageSummary',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::ExecutionStageSummary'];

coerce 'ExecutionStageSummary',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::ExecutionStageSummary'->new($_) };

declare 'RepeatedExecutionStageSummary',
    as ArrayRef[ExecutionStageSummary()];

coerce 'RepeatedExecutionStageSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::ExecutionStageSummary'->new($_) } @$_ ] };

declare 'MapStringExecutionStageSummary',
    as HashRef[ExecutionStageSummary()];

declare 'StageSource',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::ExecutionStageSummary::StageSource'];

coerce 'StageSource',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::ExecutionStageSummary::StageSource'->new($_) };

declare 'RepeatedStageSource',
    as ArrayRef[StageSource()];

coerce 'RepeatedStageSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::ExecutionStageSummary::StageSource'->new($_) } @$_ ] };

declare 'MapStringStageSource',
    as HashRef[StageSource()];

declare 'ComponentTransform',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::ExecutionStageSummary::ComponentTransform'];

coerce 'ComponentTransform',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::ExecutionStageSummary::ComponentTransform'->new($_) };

declare 'RepeatedComponentTransform',
    as ArrayRef[ComponentTransform()];

coerce 'RepeatedComponentTransform',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::ExecutionStageSummary::ComponentTransform'->new($_) } @$_ ] };

declare 'MapStringComponentTransform',
    as HashRef[ComponentTransform()];

declare 'ComponentSource',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::ExecutionStageSummary::ComponentSource'];

coerce 'ComponentSource',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::ExecutionStageSummary::ComponentSource'->new($_) };

declare 'RepeatedComponentSource',
    as ArrayRef[ComponentSource()];

coerce 'RepeatedComponentSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::ExecutionStageSummary::ComponentSource'->new($_) } @$_ ] };

declare 'MapStringComponentSource',
    as HashRef[ComponentSource()];

declare 'DisplayData',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::DisplayData'];

coerce 'DisplayData',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::DisplayData'->new($_) };

declare 'RepeatedDisplayData',
    as ArrayRef[DisplayData()];

coerce 'RepeatedDisplayData',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::DisplayData'->new($_) } @$_ ] };

declare 'MapStringDisplayData',
    as HashRef[DisplayData()];

declare 'Step',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::Step'];

coerce 'Step',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::Step'->new($_) };

declare 'RepeatedStep',
    as ArrayRef[Step()];

coerce 'RepeatedStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::Step'->new($_) } @$_ ] };

declare 'MapStringStep',
    as HashRef[Step()];

declare 'JobExecutionInfo',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::JobExecutionInfo'];

coerce 'JobExecutionInfo',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::JobExecutionInfo'->new($_) };

declare 'RepeatedJobExecutionInfo',
    as ArrayRef[JobExecutionInfo()];

coerce 'RepeatedJobExecutionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::JobExecutionInfo'->new($_) } @$_ ] };

declare 'MapStringJobExecutionInfo',
    as HashRef[JobExecutionInfo()];

declare 'StagesEntry',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::JobExecutionInfo::StagesEntry'];

coerce 'StagesEntry',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::JobExecutionInfo::StagesEntry'->new($_) };

declare 'RepeatedStagesEntry',
    as ArrayRef[StagesEntry()];

coerce 'RepeatedStagesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::JobExecutionInfo::StagesEntry'->new($_) } @$_ ] };

declare 'MapStringStagesEntry',
    as HashRef[StagesEntry()];

declare 'JobExecutionStageInfo',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::JobExecutionStageInfo'];

coerce 'JobExecutionStageInfo',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::JobExecutionStageInfo'->new($_) };

declare 'RepeatedJobExecutionStageInfo',
    as ArrayRef[JobExecutionStageInfo()];

coerce 'RepeatedJobExecutionStageInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::JobExecutionStageInfo'->new($_) } @$_ ] };

declare 'MapStringJobExecutionStageInfo',
    as HashRef[JobExecutionStageInfo()];

declare 'CreateJobRequest',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::CreateJobRequest'];

coerce 'CreateJobRequest',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::CreateJobRequest'->new($_) };

declare 'RepeatedCreateJobRequest',
    as ArrayRef[CreateJobRequest()];

coerce 'RepeatedCreateJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::CreateJobRequest'->new($_) } @$_ ] };

declare 'MapStringCreateJobRequest',
    as HashRef[CreateJobRequest()];

declare 'GetJobRequest',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::GetJobRequest'];

coerce 'GetJobRequest',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::GetJobRequest'->new($_) };

declare 'RepeatedGetJobRequest',
    as ArrayRef[GetJobRequest()];

coerce 'RepeatedGetJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::GetJobRequest'->new($_) } @$_ ] };

declare 'MapStringGetJobRequest',
    as HashRef[GetJobRequest()];

declare 'UpdateJobRequest',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::UpdateJobRequest'];

coerce 'UpdateJobRequest',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::UpdateJobRequest'->new($_) };

declare 'RepeatedUpdateJobRequest',
    as ArrayRef[UpdateJobRequest()];

coerce 'RepeatedUpdateJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::UpdateJobRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateJobRequest',
    as HashRef[UpdateJobRequest()];

declare 'ListJobsRequest',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::ListJobsRequest'];

coerce 'ListJobsRequest',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::ListJobsRequest'->new($_) };

declare 'RepeatedListJobsRequest',
    as ArrayRef[ListJobsRequest()];

coerce 'RepeatedListJobsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::ListJobsRequest'->new($_) } @$_ ] };

declare 'MapStringListJobsRequest',
    as HashRef[ListJobsRequest()];

declare 'Filter',
    as (Int | Str);

declare 'FailedLocation',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::FailedLocation'];

coerce 'FailedLocation',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::FailedLocation'->new($_) };

declare 'RepeatedFailedLocation',
    as ArrayRef[FailedLocation()];

coerce 'RepeatedFailedLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::FailedLocation'->new($_) } @$_ ] };

declare 'MapStringFailedLocation',
    as HashRef[FailedLocation()];

declare 'ListJobsResponse',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::ListJobsResponse'];

coerce 'ListJobsResponse',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::ListJobsResponse'->new($_) };

declare 'RepeatedListJobsResponse',
    as ArrayRef[ListJobsResponse()];

coerce 'RepeatedListJobsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::ListJobsResponse'->new($_) } @$_ ] };

declare 'MapStringListJobsResponse',
    as HashRef[ListJobsResponse()];

declare 'SnapshotJobRequest',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::SnapshotJobRequest'];

coerce 'SnapshotJobRequest',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::SnapshotJobRequest'->new($_) };

declare 'RepeatedSnapshotJobRequest',
    as ArrayRef[SnapshotJobRequest()];

coerce 'RepeatedSnapshotJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::SnapshotJobRequest'->new($_) } @$_ ] };

declare 'MapStringSnapshotJobRequest',
    as HashRef[SnapshotJobRequest()];

declare 'CheckActiveJobsRequest',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::CheckActiveJobsRequest'];

coerce 'CheckActiveJobsRequest',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::CheckActiveJobsRequest'->new($_) };

declare 'RepeatedCheckActiveJobsRequest',
    as ArrayRef[CheckActiveJobsRequest()];

coerce 'RepeatedCheckActiveJobsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::CheckActiveJobsRequest'->new($_) } @$_ ] };

declare 'MapStringCheckActiveJobsRequest',
    as HashRef[CheckActiveJobsRequest()];

declare 'CheckActiveJobsResponse',
    as InstanceOf['Google::Dataflow::V1beta3::Jobs::CheckActiveJobsResponse'];

coerce 'CheckActiveJobsResponse',
    from HashRef, via { 'Google::Dataflow::V1beta3::Jobs::CheckActiveJobsResponse'->new($_) };

declare 'RepeatedCheckActiveJobsResponse',
    as ArrayRef[CheckActiveJobsResponse()];

coerce 'RepeatedCheckActiveJobsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Dataflow::V1beta3::Jobs::CheckActiveJobsResponse'->new($_) } @$_ ] };

declare 'MapStringCheckActiveJobsResponse',
    as HashRef[CheckActiveJobsResponse()];

1;

__END__

=head1 NAME

Google::Dataflow::V1beta3::Jobs::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
