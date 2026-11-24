package Google::Cloud::Batch::V1alpha::Batch::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateJobRequest',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Batch::CreateJobRequest'];

coerce 'CreateJobRequest',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Batch::CreateJobRequest'->new($_) };

declare 'RepeatedCreateJobRequest',
    as ArrayRef[CreateJobRequest()];

coerce 'RepeatedCreateJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Batch::CreateJobRequest'->new($_) } @$_ ] };

declare 'MapStringCreateJobRequest',
    as HashRef[CreateJobRequest()];

declare 'GetJobRequest',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Batch::GetJobRequest'];

coerce 'GetJobRequest',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Batch::GetJobRequest'->new($_) };

declare 'RepeatedGetJobRequest',
    as ArrayRef[GetJobRequest()];

coerce 'RepeatedGetJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Batch::GetJobRequest'->new($_) } @$_ ] };

declare 'MapStringGetJobRequest',
    as HashRef[GetJobRequest()];

declare 'DeleteJobRequest',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Batch::DeleteJobRequest'];

coerce 'DeleteJobRequest',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Batch::DeleteJobRequest'->new($_) };

declare 'RepeatedDeleteJobRequest',
    as ArrayRef[DeleteJobRequest()];

coerce 'RepeatedDeleteJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Batch::DeleteJobRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteJobRequest',
    as HashRef[DeleteJobRequest()];

declare 'CancelJobRequest',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Batch::CancelJobRequest'];

coerce 'CancelJobRequest',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Batch::CancelJobRequest'->new($_) };

declare 'RepeatedCancelJobRequest',
    as ArrayRef[CancelJobRequest()];

coerce 'RepeatedCancelJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Batch::CancelJobRequest'->new($_) } @$_ ] };

declare 'MapStringCancelJobRequest',
    as HashRef[CancelJobRequest()];

declare 'CancelJobResponse',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Batch::CancelJobResponse'];

coerce 'CancelJobResponse',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Batch::CancelJobResponse'->new($_) };

declare 'RepeatedCancelJobResponse',
    as ArrayRef[CancelJobResponse()];

coerce 'RepeatedCancelJobResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Batch::CancelJobResponse'->new($_) } @$_ ] };

declare 'MapStringCancelJobResponse',
    as HashRef[CancelJobResponse()];

declare 'UpdateJobRequest',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Batch::UpdateJobRequest'];

coerce 'UpdateJobRequest',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Batch::UpdateJobRequest'->new($_) };

declare 'RepeatedUpdateJobRequest',
    as ArrayRef[UpdateJobRequest()];

coerce 'RepeatedUpdateJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Batch::UpdateJobRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateJobRequest',
    as HashRef[UpdateJobRequest()];

declare 'ListJobsRequest',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Batch::ListJobsRequest'];

coerce 'ListJobsRequest',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Batch::ListJobsRequest'->new($_) };

declare 'RepeatedListJobsRequest',
    as ArrayRef[ListJobsRequest()];

coerce 'RepeatedListJobsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Batch::ListJobsRequest'->new($_) } @$_ ] };

declare 'MapStringListJobsRequest',
    as HashRef[ListJobsRequest()];

declare 'ListJobsResponse',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Batch::ListJobsResponse'];

coerce 'ListJobsResponse',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Batch::ListJobsResponse'->new($_) };

declare 'RepeatedListJobsResponse',
    as ArrayRef[ListJobsResponse()];

coerce 'RepeatedListJobsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Batch::ListJobsResponse'->new($_) } @$_ ] };

declare 'MapStringListJobsResponse',
    as HashRef[ListJobsResponse()];

declare 'ListTasksRequest',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Batch::ListTasksRequest'];

coerce 'ListTasksRequest',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Batch::ListTasksRequest'->new($_) };

declare 'RepeatedListTasksRequest',
    as ArrayRef[ListTasksRequest()];

coerce 'RepeatedListTasksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Batch::ListTasksRequest'->new($_) } @$_ ] };

declare 'MapStringListTasksRequest',
    as HashRef[ListTasksRequest()];

declare 'ListTasksResponse',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Batch::ListTasksResponse'];

coerce 'ListTasksResponse',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Batch::ListTasksResponse'->new($_) };

declare 'RepeatedListTasksResponse',
    as ArrayRef[ListTasksResponse()];

coerce 'RepeatedListTasksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Batch::ListTasksResponse'->new($_) } @$_ ] };

declare 'MapStringListTasksResponse',
    as HashRef[ListTasksResponse()];

declare 'GetTaskRequest',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Batch::GetTaskRequest'];

coerce 'GetTaskRequest',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Batch::GetTaskRequest'->new($_) };

declare 'RepeatedGetTaskRequest',
    as ArrayRef[GetTaskRequest()];

coerce 'RepeatedGetTaskRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Batch::GetTaskRequest'->new($_) } @$_ ] };

declare 'MapStringGetTaskRequest',
    as HashRef[GetTaskRequest()];

declare 'CreateResourceAllowanceRequest',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Batch::CreateResourceAllowanceRequest'];

coerce 'CreateResourceAllowanceRequest',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Batch::CreateResourceAllowanceRequest'->new($_) };

declare 'RepeatedCreateResourceAllowanceRequest',
    as ArrayRef[CreateResourceAllowanceRequest()];

coerce 'RepeatedCreateResourceAllowanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Batch::CreateResourceAllowanceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateResourceAllowanceRequest',
    as HashRef[CreateResourceAllowanceRequest()];

declare 'GetResourceAllowanceRequest',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Batch::GetResourceAllowanceRequest'];

coerce 'GetResourceAllowanceRequest',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Batch::GetResourceAllowanceRequest'->new($_) };

declare 'RepeatedGetResourceAllowanceRequest',
    as ArrayRef[GetResourceAllowanceRequest()];

coerce 'RepeatedGetResourceAllowanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Batch::GetResourceAllowanceRequest'->new($_) } @$_ ] };

declare 'MapStringGetResourceAllowanceRequest',
    as HashRef[GetResourceAllowanceRequest()];

declare 'DeleteResourceAllowanceRequest',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Batch::DeleteResourceAllowanceRequest'];

coerce 'DeleteResourceAllowanceRequest',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Batch::DeleteResourceAllowanceRequest'->new($_) };

declare 'RepeatedDeleteResourceAllowanceRequest',
    as ArrayRef[DeleteResourceAllowanceRequest()];

coerce 'RepeatedDeleteResourceAllowanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Batch::DeleteResourceAllowanceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteResourceAllowanceRequest',
    as HashRef[DeleteResourceAllowanceRequest()];

declare 'ListResourceAllowancesRequest',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Batch::ListResourceAllowancesRequest'];

coerce 'ListResourceAllowancesRequest',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Batch::ListResourceAllowancesRequest'->new($_) };

declare 'RepeatedListResourceAllowancesRequest',
    as ArrayRef[ListResourceAllowancesRequest()];

coerce 'RepeatedListResourceAllowancesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Batch::ListResourceAllowancesRequest'->new($_) } @$_ ] };

declare 'MapStringListResourceAllowancesRequest',
    as HashRef[ListResourceAllowancesRequest()];

declare 'ListResourceAllowancesResponse',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Batch::ListResourceAllowancesResponse'];

coerce 'ListResourceAllowancesResponse',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Batch::ListResourceAllowancesResponse'->new($_) };

declare 'RepeatedListResourceAllowancesResponse',
    as ArrayRef[ListResourceAllowancesResponse()];

coerce 'RepeatedListResourceAllowancesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Batch::ListResourceAllowancesResponse'->new($_) } @$_ ] };

declare 'MapStringListResourceAllowancesResponse',
    as HashRef[ListResourceAllowancesResponse()];

declare 'UpdateResourceAllowanceRequest',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Batch::UpdateResourceAllowanceRequest'];

coerce 'UpdateResourceAllowanceRequest',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Batch::UpdateResourceAllowanceRequest'->new($_) };

declare 'RepeatedUpdateResourceAllowanceRequest',
    as ArrayRef[UpdateResourceAllowanceRequest()];

coerce 'RepeatedUpdateResourceAllowanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Batch::UpdateResourceAllowanceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateResourceAllowanceRequest',
    as HashRef[UpdateResourceAllowanceRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Batch::V1alpha::Batch::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Batch::V1alpha::Batch::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Batch::V1alpha::Batch::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Batch::V1alpha::Batch::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
