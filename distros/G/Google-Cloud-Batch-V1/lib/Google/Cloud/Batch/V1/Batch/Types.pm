package Google::Cloud::Batch::V1::Batch::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateJobRequest',
    as InstanceOf['Google::Cloud::Batch::V1::Batch::CreateJobRequest'];

coerce 'CreateJobRequest',
    from HashRef, via { 'Google::Cloud::Batch::V1::Batch::CreateJobRequest'->new($_) };

declare 'RepeatedCreateJobRequest',
    as ArrayRef[CreateJobRequest()];

coerce 'RepeatedCreateJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Batch::CreateJobRequest'->new($_) } @$_ ] };

declare 'MapStringCreateJobRequest',
    as HashRef[CreateJobRequest()];

declare 'GetJobRequest',
    as InstanceOf['Google::Cloud::Batch::V1::Batch::GetJobRequest'];

coerce 'GetJobRequest',
    from HashRef, via { 'Google::Cloud::Batch::V1::Batch::GetJobRequest'->new($_) };

declare 'RepeatedGetJobRequest',
    as ArrayRef[GetJobRequest()];

coerce 'RepeatedGetJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Batch::GetJobRequest'->new($_) } @$_ ] };

declare 'MapStringGetJobRequest',
    as HashRef[GetJobRequest()];

declare 'DeleteJobRequest',
    as InstanceOf['Google::Cloud::Batch::V1::Batch::DeleteJobRequest'];

coerce 'DeleteJobRequest',
    from HashRef, via { 'Google::Cloud::Batch::V1::Batch::DeleteJobRequest'->new($_) };

declare 'RepeatedDeleteJobRequest',
    as ArrayRef[DeleteJobRequest()];

coerce 'RepeatedDeleteJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Batch::DeleteJobRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteJobRequest',
    as HashRef[DeleteJobRequest()];

declare 'CancelJobRequest',
    as InstanceOf['Google::Cloud::Batch::V1::Batch::CancelJobRequest'];

coerce 'CancelJobRequest',
    from HashRef, via { 'Google::Cloud::Batch::V1::Batch::CancelJobRequest'->new($_) };

declare 'RepeatedCancelJobRequest',
    as ArrayRef[CancelJobRequest()];

coerce 'RepeatedCancelJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Batch::CancelJobRequest'->new($_) } @$_ ] };

declare 'MapStringCancelJobRequest',
    as HashRef[CancelJobRequest()];

declare 'CancelJobResponse',
    as InstanceOf['Google::Cloud::Batch::V1::Batch::CancelJobResponse'];

coerce 'CancelJobResponse',
    from HashRef, via { 'Google::Cloud::Batch::V1::Batch::CancelJobResponse'->new($_) };

declare 'RepeatedCancelJobResponse',
    as ArrayRef[CancelJobResponse()];

coerce 'RepeatedCancelJobResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Batch::CancelJobResponse'->new($_) } @$_ ] };

declare 'MapStringCancelJobResponse',
    as HashRef[CancelJobResponse()];

declare 'ListJobsRequest',
    as InstanceOf['Google::Cloud::Batch::V1::Batch::ListJobsRequest'];

coerce 'ListJobsRequest',
    from HashRef, via { 'Google::Cloud::Batch::V1::Batch::ListJobsRequest'->new($_) };

declare 'RepeatedListJobsRequest',
    as ArrayRef[ListJobsRequest()];

coerce 'RepeatedListJobsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Batch::ListJobsRequest'->new($_) } @$_ ] };

declare 'MapStringListJobsRequest',
    as HashRef[ListJobsRequest()];

declare 'ListJobsResponse',
    as InstanceOf['Google::Cloud::Batch::V1::Batch::ListJobsResponse'];

coerce 'ListJobsResponse',
    from HashRef, via { 'Google::Cloud::Batch::V1::Batch::ListJobsResponse'->new($_) };

declare 'RepeatedListJobsResponse',
    as ArrayRef[ListJobsResponse()];

coerce 'RepeatedListJobsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Batch::ListJobsResponse'->new($_) } @$_ ] };

declare 'MapStringListJobsResponse',
    as HashRef[ListJobsResponse()];

declare 'ListTasksRequest',
    as InstanceOf['Google::Cloud::Batch::V1::Batch::ListTasksRequest'];

coerce 'ListTasksRequest',
    from HashRef, via { 'Google::Cloud::Batch::V1::Batch::ListTasksRequest'->new($_) };

declare 'RepeatedListTasksRequest',
    as ArrayRef[ListTasksRequest()];

coerce 'RepeatedListTasksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Batch::ListTasksRequest'->new($_) } @$_ ] };

declare 'MapStringListTasksRequest',
    as HashRef[ListTasksRequest()];

declare 'ListTasksResponse',
    as InstanceOf['Google::Cloud::Batch::V1::Batch::ListTasksResponse'];

coerce 'ListTasksResponse',
    from HashRef, via { 'Google::Cloud::Batch::V1::Batch::ListTasksResponse'->new($_) };

declare 'RepeatedListTasksResponse',
    as ArrayRef[ListTasksResponse()];

coerce 'RepeatedListTasksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Batch::ListTasksResponse'->new($_) } @$_ ] };

declare 'MapStringListTasksResponse',
    as HashRef[ListTasksResponse()];

declare 'GetTaskRequest',
    as InstanceOf['Google::Cloud::Batch::V1::Batch::GetTaskRequest'];

coerce 'GetTaskRequest',
    from HashRef, via { 'Google::Cloud::Batch::V1::Batch::GetTaskRequest'->new($_) };

declare 'RepeatedGetTaskRequest',
    as ArrayRef[GetTaskRequest()];

coerce 'RepeatedGetTaskRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Batch::GetTaskRequest'->new($_) } @$_ ] };

declare 'MapStringGetTaskRequest',
    as HashRef[GetTaskRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Batch::V1::Batch::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Batch::V1::Batch::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1::Batch::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Batch::V1::Batch::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
