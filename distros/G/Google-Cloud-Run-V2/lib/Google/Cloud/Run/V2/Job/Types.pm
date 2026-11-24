package Google::Cloud::Run::V2::Job::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateJobRequest',
    as InstanceOf['Google::Cloud::Run::V2::Job::CreateJobRequest'];

coerce 'CreateJobRequest',
    from HashRef, via { 'Google::Cloud::Run::V2::Job::CreateJobRequest'->new($_) };

declare 'RepeatedCreateJobRequest',
    as ArrayRef[CreateJobRequest()];

coerce 'RepeatedCreateJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Job::CreateJobRequest'->new($_) } @$_ ] };

declare 'MapStringCreateJobRequest',
    as HashRef[CreateJobRequest()];

declare 'GetJobRequest',
    as InstanceOf['Google::Cloud::Run::V2::Job::GetJobRequest'];

coerce 'GetJobRequest',
    from HashRef, via { 'Google::Cloud::Run::V2::Job::GetJobRequest'->new($_) };

declare 'RepeatedGetJobRequest',
    as ArrayRef[GetJobRequest()];

coerce 'RepeatedGetJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Job::GetJobRequest'->new($_) } @$_ ] };

declare 'MapStringGetJobRequest',
    as HashRef[GetJobRequest()];

declare 'UpdateJobRequest',
    as InstanceOf['Google::Cloud::Run::V2::Job::UpdateJobRequest'];

coerce 'UpdateJobRequest',
    from HashRef, via { 'Google::Cloud::Run::V2::Job::UpdateJobRequest'->new($_) };

declare 'RepeatedUpdateJobRequest',
    as ArrayRef[UpdateJobRequest()];

coerce 'RepeatedUpdateJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Job::UpdateJobRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateJobRequest',
    as HashRef[UpdateJobRequest()];

declare 'ListJobsRequest',
    as InstanceOf['Google::Cloud::Run::V2::Job::ListJobsRequest'];

coerce 'ListJobsRequest',
    from HashRef, via { 'Google::Cloud::Run::V2::Job::ListJobsRequest'->new($_) };

declare 'RepeatedListJobsRequest',
    as ArrayRef[ListJobsRequest()];

coerce 'RepeatedListJobsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Job::ListJobsRequest'->new($_) } @$_ ] };

declare 'MapStringListJobsRequest',
    as HashRef[ListJobsRequest()];

declare 'ListJobsResponse',
    as InstanceOf['Google::Cloud::Run::V2::Job::ListJobsResponse'];

coerce 'ListJobsResponse',
    from HashRef, via { 'Google::Cloud::Run::V2::Job::ListJobsResponse'->new($_) };

declare 'RepeatedListJobsResponse',
    as ArrayRef[ListJobsResponse()];

coerce 'RepeatedListJobsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Job::ListJobsResponse'->new($_) } @$_ ] };

declare 'MapStringListJobsResponse',
    as HashRef[ListJobsResponse()];

declare 'DeleteJobRequest',
    as InstanceOf['Google::Cloud::Run::V2::Job::DeleteJobRequest'];

coerce 'DeleteJobRequest',
    from HashRef, via { 'Google::Cloud::Run::V2::Job::DeleteJobRequest'->new($_) };

declare 'RepeatedDeleteJobRequest',
    as ArrayRef[DeleteJobRequest()];

coerce 'RepeatedDeleteJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Job::DeleteJobRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteJobRequest',
    as HashRef[DeleteJobRequest()];

declare 'RunJobRequest',
    as InstanceOf['Google::Cloud::Run::V2::Job::RunJobRequest'];

coerce 'RunJobRequest',
    from HashRef, via { 'Google::Cloud::Run::V2::Job::RunJobRequest'->new($_) };

declare 'RepeatedRunJobRequest',
    as ArrayRef[RunJobRequest()];

coerce 'RepeatedRunJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Job::RunJobRequest'->new($_) } @$_ ] };

declare 'MapStringRunJobRequest',
    as HashRef[RunJobRequest()];

declare 'Overrides',
    as InstanceOf['Google::Cloud::Run::V2::Job::RunJobRequest::Overrides'];

coerce 'Overrides',
    from HashRef, via { 'Google::Cloud::Run::V2::Job::RunJobRequest::Overrides'->new($_) };

declare 'RepeatedOverrides',
    as ArrayRef[Overrides()];

coerce 'RepeatedOverrides',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Job::RunJobRequest::Overrides'->new($_) } @$_ ] };

declare 'MapStringOverrides',
    as HashRef[Overrides()];

declare 'ContainerOverride',
    as InstanceOf['Google::Cloud::Run::V2::Job::RunJobRequest::Overrides::ContainerOverride'];

coerce 'ContainerOverride',
    from HashRef, via { 'Google::Cloud::Run::V2::Job::RunJobRequest::Overrides::ContainerOverride'->new($_) };

declare 'RepeatedContainerOverride',
    as ArrayRef[ContainerOverride()];

coerce 'RepeatedContainerOverride',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Job::RunJobRequest::Overrides::ContainerOverride'->new($_) } @$_ ] };

declare 'MapStringContainerOverride',
    as HashRef[ContainerOverride()];

declare 'Job',
    as InstanceOf['Google::Cloud::Run::V2::Job::Job'];

coerce 'Job',
    from HashRef, via { 'Google::Cloud::Run::V2::Job::Job'->new($_) };

declare 'RepeatedJob',
    as ArrayRef[Job()];

coerce 'RepeatedJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Job::Job'->new($_) } @$_ ] };

declare 'MapStringJob',
    as HashRef[Job()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Run::V2::Job::Job::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Run::V2::Job::Job::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Job::Job::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Run::V2::Job::Job::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Run::V2::Job::Job::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Job::Job::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'ExecutionReference',
    as InstanceOf['Google::Cloud::Run::V2::Job::ExecutionReference'];

coerce 'ExecutionReference',
    from HashRef, via { 'Google::Cloud::Run::V2::Job::ExecutionReference'->new($_) };

declare 'RepeatedExecutionReference',
    as ArrayRef[ExecutionReference()];

coerce 'RepeatedExecutionReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Run::V2::Job::ExecutionReference'->new($_) } @$_ ] };

declare 'MapStringExecutionReference',
    as HashRef[ExecutionReference()];

declare 'CompletionStatus',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Run::V2::Job::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
