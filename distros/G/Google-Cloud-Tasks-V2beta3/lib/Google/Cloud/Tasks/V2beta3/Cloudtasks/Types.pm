package Google::Cloud::Tasks::V2beta3::Cloudtasks::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListQueuesRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Cloudtasks::ListQueuesRequest'];

coerce 'ListQueuesRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::ListQueuesRequest'->new($_) };

declare 'RepeatedListQueuesRequest',
    as ArrayRef[ListQueuesRequest()];

coerce 'RepeatedListQueuesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::ListQueuesRequest'->new($_) } @$_ ] };

declare 'MapStringListQueuesRequest',
    as HashRef[ListQueuesRequest()];

declare 'ListQueuesResponse',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Cloudtasks::ListQueuesResponse'];

coerce 'ListQueuesResponse',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::ListQueuesResponse'->new($_) };

declare 'RepeatedListQueuesResponse',
    as ArrayRef[ListQueuesResponse()];

coerce 'RepeatedListQueuesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::ListQueuesResponse'->new($_) } @$_ ] };

declare 'MapStringListQueuesResponse',
    as HashRef[ListQueuesResponse()];

declare 'GetQueueRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Cloudtasks::GetQueueRequest'];

coerce 'GetQueueRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::GetQueueRequest'->new($_) };

declare 'RepeatedGetQueueRequest',
    as ArrayRef[GetQueueRequest()];

coerce 'RepeatedGetQueueRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::GetQueueRequest'->new($_) } @$_ ] };

declare 'MapStringGetQueueRequest',
    as HashRef[GetQueueRequest()];

declare 'CreateQueueRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Cloudtasks::CreateQueueRequest'];

coerce 'CreateQueueRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::CreateQueueRequest'->new($_) };

declare 'RepeatedCreateQueueRequest',
    as ArrayRef[CreateQueueRequest()];

coerce 'RepeatedCreateQueueRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::CreateQueueRequest'->new($_) } @$_ ] };

declare 'MapStringCreateQueueRequest',
    as HashRef[CreateQueueRequest()];

declare 'UpdateQueueRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Cloudtasks::UpdateQueueRequest'];

coerce 'UpdateQueueRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::UpdateQueueRequest'->new($_) };

declare 'RepeatedUpdateQueueRequest',
    as ArrayRef[UpdateQueueRequest()];

coerce 'RepeatedUpdateQueueRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::UpdateQueueRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateQueueRequest',
    as HashRef[UpdateQueueRequest()];

declare 'DeleteQueueRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Cloudtasks::DeleteQueueRequest'];

coerce 'DeleteQueueRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::DeleteQueueRequest'->new($_) };

declare 'RepeatedDeleteQueueRequest',
    as ArrayRef[DeleteQueueRequest()];

coerce 'RepeatedDeleteQueueRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::DeleteQueueRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteQueueRequest',
    as HashRef[DeleteQueueRequest()];

declare 'PurgeQueueRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Cloudtasks::PurgeQueueRequest'];

coerce 'PurgeQueueRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::PurgeQueueRequest'->new($_) };

declare 'RepeatedPurgeQueueRequest',
    as ArrayRef[PurgeQueueRequest()];

coerce 'RepeatedPurgeQueueRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::PurgeQueueRequest'->new($_) } @$_ ] };

declare 'MapStringPurgeQueueRequest',
    as HashRef[PurgeQueueRequest()];

declare 'PauseQueueRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Cloudtasks::PauseQueueRequest'];

coerce 'PauseQueueRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::PauseQueueRequest'->new($_) };

declare 'RepeatedPauseQueueRequest',
    as ArrayRef[PauseQueueRequest()];

coerce 'RepeatedPauseQueueRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::PauseQueueRequest'->new($_) } @$_ ] };

declare 'MapStringPauseQueueRequest',
    as HashRef[PauseQueueRequest()];

declare 'ResumeQueueRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Cloudtasks::ResumeQueueRequest'];

coerce 'ResumeQueueRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::ResumeQueueRequest'->new($_) };

declare 'RepeatedResumeQueueRequest',
    as ArrayRef[ResumeQueueRequest()];

coerce 'RepeatedResumeQueueRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::ResumeQueueRequest'->new($_) } @$_ ] };

declare 'MapStringResumeQueueRequest',
    as HashRef[ResumeQueueRequest()];

declare 'ListTasksRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Cloudtasks::ListTasksRequest'];

coerce 'ListTasksRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::ListTasksRequest'->new($_) };

declare 'RepeatedListTasksRequest',
    as ArrayRef[ListTasksRequest()];

coerce 'RepeatedListTasksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::ListTasksRequest'->new($_) } @$_ ] };

declare 'MapStringListTasksRequest',
    as HashRef[ListTasksRequest()];

declare 'ListTasksResponse',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Cloudtasks::ListTasksResponse'];

coerce 'ListTasksResponse',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::ListTasksResponse'->new($_) };

declare 'RepeatedListTasksResponse',
    as ArrayRef[ListTasksResponse()];

coerce 'RepeatedListTasksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::ListTasksResponse'->new($_) } @$_ ] };

declare 'MapStringListTasksResponse',
    as HashRef[ListTasksResponse()];

declare 'GetTaskRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Cloudtasks::GetTaskRequest'];

coerce 'GetTaskRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::GetTaskRequest'->new($_) };

declare 'RepeatedGetTaskRequest',
    as ArrayRef[GetTaskRequest()];

coerce 'RepeatedGetTaskRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::GetTaskRequest'->new($_) } @$_ ] };

declare 'MapStringGetTaskRequest',
    as HashRef[GetTaskRequest()];

declare 'CreateTaskRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Cloudtasks::CreateTaskRequest'];

coerce 'CreateTaskRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::CreateTaskRequest'->new($_) };

declare 'RepeatedCreateTaskRequest',
    as ArrayRef[CreateTaskRequest()];

coerce 'RepeatedCreateTaskRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::CreateTaskRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTaskRequest',
    as HashRef[CreateTaskRequest()];

declare 'BatchCreateTasksRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Cloudtasks::BatchCreateTasksRequest'];

coerce 'BatchCreateTasksRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::BatchCreateTasksRequest'->new($_) };

declare 'RepeatedBatchCreateTasksRequest',
    as ArrayRef[BatchCreateTasksRequest()];

coerce 'RepeatedBatchCreateTasksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::BatchCreateTasksRequest'->new($_) } @$_ ] };

declare 'MapStringBatchCreateTasksRequest',
    as HashRef[BatchCreateTasksRequest()];

declare 'DeleteTaskRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Cloudtasks::DeleteTaskRequest'];

coerce 'DeleteTaskRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::DeleteTaskRequest'->new($_) };

declare 'RepeatedDeleteTaskRequest',
    as ArrayRef[DeleteTaskRequest()];

coerce 'RepeatedDeleteTaskRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::DeleteTaskRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTaskRequest',
    as HashRef[DeleteTaskRequest()];

declare 'BatchDeleteTasksRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Cloudtasks::BatchDeleteTasksRequest'];

coerce 'BatchDeleteTasksRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::BatchDeleteTasksRequest'->new($_) };

declare 'RepeatedBatchDeleteTasksRequest',
    as ArrayRef[BatchDeleteTasksRequest()];

coerce 'RepeatedBatchDeleteTasksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::BatchDeleteTasksRequest'->new($_) } @$_ ] };

declare 'MapStringBatchDeleteTasksRequest',
    as HashRef[BatchDeleteTasksRequest()];

declare 'BatchDeleteTasksMetadata',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Cloudtasks::BatchDeleteTasksMetadata'];

coerce 'BatchDeleteTasksMetadata',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::BatchDeleteTasksMetadata'->new($_) };

declare 'RepeatedBatchDeleteTasksMetadata',
    as ArrayRef[BatchDeleteTasksMetadata()];

coerce 'RepeatedBatchDeleteTasksMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::BatchDeleteTasksMetadata'->new($_) } @$_ ] };

declare 'MapStringBatchDeleteTasksMetadata',
    as HashRef[BatchDeleteTasksMetadata()];

declare 'State',
    as (Int | Str);

declare 'FailedRequestsEntry',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Cloudtasks::BatchDeleteTasksMetadata::FailedRequestsEntry'];

coerce 'FailedRequestsEntry',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::BatchDeleteTasksMetadata::FailedRequestsEntry'->new($_) };

declare 'RepeatedFailedRequestsEntry',
    as ArrayRef[FailedRequestsEntry()];

coerce 'RepeatedFailedRequestsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::BatchDeleteTasksMetadata::FailedRequestsEntry'->new($_) } @$_ ] };

declare 'MapStringFailedRequestsEntry',
    as HashRef[FailedRequestsEntry()];

declare 'RunTaskRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Cloudtasks::RunTaskRequest'];

coerce 'RunTaskRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::RunTaskRequest'->new($_) };

declare 'RepeatedRunTaskRequest',
    as ArrayRef[RunTaskRequest()];

coerce 'RepeatedRunTaskRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::RunTaskRequest'->new($_) } @$_ ] };

declare 'MapStringRunTaskRequest',
    as HashRef[RunTaskRequest()];

declare 'BatchCreateTasksResponse',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Cloudtasks::BatchCreateTasksResponse'];

coerce 'BatchCreateTasksResponse',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::BatchCreateTasksResponse'->new($_) };

declare 'RepeatedBatchCreateTasksResponse',
    as ArrayRef[BatchCreateTasksResponse()];

coerce 'RepeatedBatchCreateTasksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::BatchCreateTasksResponse'->new($_) } @$_ ] };

declare 'MapStringBatchCreateTasksResponse',
    as HashRef[BatchCreateTasksResponse()];

declare 'BatchCreateTasksMetadata',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Cloudtasks::BatchCreateTasksMetadata'];

coerce 'BatchCreateTasksMetadata',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::BatchCreateTasksMetadata'->new($_) };

declare 'RepeatedBatchCreateTasksMetadata',
    as ArrayRef[BatchCreateTasksMetadata()];

coerce 'RepeatedBatchCreateTasksMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::BatchCreateTasksMetadata'->new($_) } @$_ ] };

declare 'MapStringBatchCreateTasksMetadata',
    as HashRef[BatchCreateTasksMetadata()];

declare 'State',
    as (Int | Str);

declare 'FailedRequestsEntry',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Cloudtasks::BatchCreateTasksMetadata::FailedRequestsEntry'];

coerce 'FailedRequestsEntry',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::BatchCreateTasksMetadata::FailedRequestsEntry'->new($_) };

declare 'RepeatedFailedRequestsEntry',
    as ArrayRef[FailedRequestsEntry()];

coerce 'RepeatedFailedRequestsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::BatchCreateTasksMetadata::FailedRequestsEntry'->new($_) } @$_ ] };

declare 'MapStringFailedRequestsEntry',
    as HashRef[FailedRequestsEntry()];

declare 'UpdateCmekConfigRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Cloudtasks::UpdateCmekConfigRequest'];

coerce 'UpdateCmekConfigRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::UpdateCmekConfigRequest'->new($_) };

declare 'RepeatedUpdateCmekConfigRequest',
    as ArrayRef[UpdateCmekConfigRequest()];

coerce 'RepeatedUpdateCmekConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::UpdateCmekConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCmekConfigRequest',
    as HashRef[UpdateCmekConfigRequest()];

declare 'GetCmekConfigRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Cloudtasks::GetCmekConfigRequest'];

coerce 'GetCmekConfigRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::GetCmekConfigRequest'->new($_) };

declare 'RepeatedGetCmekConfigRequest',
    as ArrayRef[GetCmekConfigRequest()];

coerce 'RepeatedGetCmekConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Cloudtasks::GetCmekConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetCmekConfigRequest',
    as HashRef[GetCmekConfigRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Tasks::V2beta3::Cloudtasks::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
