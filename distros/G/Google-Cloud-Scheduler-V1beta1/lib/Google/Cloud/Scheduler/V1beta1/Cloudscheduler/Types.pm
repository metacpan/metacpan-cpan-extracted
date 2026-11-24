package Google::Cloud::Scheduler::V1beta1::Cloudscheduler::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListJobsRequest',
    as InstanceOf['Google::Cloud::Scheduler::V1beta1::Cloudscheduler::ListJobsRequest'];

coerce 'ListJobsRequest',
    from HashRef, via { 'Google::Cloud::Scheduler::V1beta1::Cloudscheduler::ListJobsRequest'->new($_) };

declare 'RepeatedListJobsRequest',
    as ArrayRef[ListJobsRequest()];

coerce 'RepeatedListJobsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Scheduler::V1beta1::Cloudscheduler::ListJobsRequest'->new($_) } @$_ ] };

declare 'MapStringListJobsRequest',
    as HashRef[ListJobsRequest()];

declare 'ListJobsResponse',
    as InstanceOf['Google::Cloud::Scheduler::V1beta1::Cloudscheduler::ListJobsResponse'];

coerce 'ListJobsResponse',
    from HashRef, via { 'Google::Cloud::Scheduler::V1beta1::Cloudscheduler::ListJobsResponse'->new($_) };

declare 'RepeatedListJobsResponse',
    as ArrayRef[ListJobsResponse()];

coerce 'RepeatedListJobsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Scheduler::V1beta1::Cloudscheduler::ListJobsResponse'->new($_) } @$_ ] };

declare 'MapStringListJobsResponse',
    as HashRef[ListJobsResponse()];

declare 'GetJobRequest',
    as InstanceOf['Google::Cloud::Scheduler::V1beta1::Cloudscheduler::GetJobRequest'];

coerce 'GetJobRequest',
    from HashRef, via { 'Google::Cloud::Scheduler::V1beta1::Cloudscheduler::GetJobRequest'->new($_) };

declare 'RepeatedGetJobRequest',
    as ArrayRef[GetJobRequest()];

coerce 'RepeatedGetJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Scheduler::V1beta1::Cloudscheduler::GetJobRequest'->new($_) } @$_ ] };

declare 'MapStringGetJobRequest',
    as HashRef[GetJobRequest()];

declare 'CreateJobRequest',
    as InstanceOf['Google::Cloud::Scheduler::V1beta1::Cloudscheduler::CreateJobRequest'];

coerce 'CreateJobRequest',
    from HashRef, via { 'Google::Cloud::Scheduler::V1beta1::Cloudscheduler::CreateJobRequest'->new($_) };

declare 'RepeatedCreateJobRequest',
    as ArrayRef[CreateJobRequest()];

coerce 'RepeatedCreateJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Scheduler::V1beta1::Cloudscheduler::CreateJobRequest'->new($_) } @$_ ] };

declare 'MapStringCreateJobRequest',
    as HashRef[CreateJobRequest()];

declare 'UpdateJobRequest',
    as InstanceOf['Google::Cloud::Scheduler::V1beta1::Cloudscheduler::UpdateJobRequest'];

coerce 'UpdateJobRequest',
    from HashRef, via { 'Google::Cloud::Scheduler::V1beta1::Cloudscheduler::UpdateJobRequest'->new($_) };

declare 'RepeatedUpdateJobRequest',
    as ArrayRef[UpdateJobRequest()];

coerce 'RepeatedUpdateJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Scheduler::V1beta1::Cloudscheduler::UpdateJobRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateJobRequest',
    as HashRef[UpdateJobRequest()];

declare 'DeleteJobRequest',
    as InstanceOf['Google::Cloud::Scheduler::V1beta1::Cloudscheduler::DeleteJobRequest'];

coerce 'DeleteJobRequest',
    from HashRef, via { 'Google::Cloud::Scheduler::V1beta1::Cloudscheduler::DeleteJobRequest'->new($_) };

declare 'RepeatedDeleteJobRequest',
    as ArrayRef[DeleteJobRequest()];

coerce 'RepeatedDeleteJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Scheduler::V1beta1::Cloudscheduler::DeleteJobRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteJobRequest',
    as HashRef[DeleteJobRequest()];

declare 'PauseJobRequest',
    as InstanceOf['Google::Cloud::Scheduler::V1beta1::Cloudscheduler::PauseJobRequest'];

coerce 'PauseJobRequest',
    from HashRef, via { 'Google::Cloud::Scheduler::V1beta1::Cloudscheduler::PauseJobRequest'->new($_) };

declare 'RepeatedPauseJobRequest',
    as ArrayRef[PauseJobRequest()];

coerce 'RepeatedPauseJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Scheduler::V1beta1::Cloudscheduler::PauseJobRequest'->new($_) } @$_ ] };

declare 'MapStringPauseJobRequest',
    as HashRef[PauseJobRequest()];

declare 'ResumeJobRequest',
    as InstanceOf['Google::Cloud::Scheduler::V1beta1::Cloudscheduler::ResumeJobRequest'];

coerce 'ResumeJobRequest',
    from HashRef, via { 'Google::Cloud::Scheduler::V1beta1::Cloudscheduler::ResumeJobRequest'->new($_) };

declare 'RepeatedResumeJobRequest',
    as ArrayRef[ResumeJobRequest()];

coerce 'RepeatedResumeJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Scheduler::V1beta1::Cloudscheduler::ResumeJobRequest'->new($_) } @$_ ] };

declare 'MapStringResumeJobRequest',
    as HashRef[ResumeJobRequest()];

declare 'RunJobRequest',
    as InstanceOf['Google::Cloud::Scheduler::V1beta1::Cloudscheduler::RunJobRequest'];

coerce 'RunJobRequest',
    from HashRef, via { 'Google::Cloud::Scheduler::V1beta1::Cloudscheduler::RunJobRequest'->new($_) };

declare 'RepeatedRunJobRequest',
    as ArrayRef[RunJobRequest()];

coerce 'RepeatedRunJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Scheduler::V1beta1::Cloudscheduler::RunJobRequest'->new($_) } @$_ ] };

declare 'MapStringRunJobRequest',
    as HashRef[RunJobRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Scheduler::V1beta1::Cloudscheduler::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
