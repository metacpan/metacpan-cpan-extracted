package Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListJobsRequest',
    as InstanceOf['Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::ListJobsRequest'];

coerce 'ListJobsRequest',
    from HashRef, via { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::ListJobsRequest'->new($_) };

declare 'RepeatedListJobsRequest',
    as ArrayRef[ListJobsRequest()];

coerce 'RepeatedListJobsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::ListJobsRequest'->new($_) } @$_ ] };

declare 'MapStringListJobsRequest',
    as HashRef[ListJobsRequest()];

declare 'ListJobsResponse',
    as InstanceOf['Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::ListJobsResponse'];

coerce 'ListJobsResponse',
    from HashRef, via { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::ListJobsResponse'->new($_) };

declare 'RepeatedListJobsResponse',
    as ArrayRef[ListJobsResponse()];

coerce 'RepeatedListJobsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::ListJobsResponse'->new($_) } @$_ ] };

declare 'MapStringListJobsResponse',
    as HashRef[ListJobsResponse()];

declare 'GetJobRequest',
    as InstanceOf['Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::GetJobRequest'];

coerce 'GetJobRequest',
    from HashRef, via { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::GetJobRequest'->new($_) };

declare 'RepeatedGetJobRequest',
    as ArrayRef[GetJobRequest()];

coerce 'RepeatedGetJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::GetJobRequest'->new($_) } @$_ ] };

declare 'MapStringGetJobRequest',
    as HashRef[GetJobRequest()];

declare 'CreateJobRequest',
    as InstanceOf['Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::CreateJobRequest'];

coerce 'CreateJobRequest',
    from HashRef, via { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::CreateJobRequest'->new($_) };

declare 'RepeatedCreateJobRequest',
    as ArrayRef[CreateJobRequest()];

coerce 'RepeatedCreateJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::CreateJobRequest'->new($_) } @$_ ] };

declare 'MapStringCreateJobRequest',
    as HashRef[CreateJobRequest()];

declare 'CancelJobRequest',
    as InstanceOf['Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::CancelJobRequest'];

coerce 'CancelJobRequest',
    from HashRef, via { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::CancelJobRequest'->new($_) };

declare 'RepeatedCancelJobRequest',
    as ArrayRef[CancelJobRequest()];

coerce 'RepeatedCancelJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::CancelJobRequest'->new($_) } @$_ ] };

declare 'MapStringCancelJobRequest',
    as HashRef[CancelJobRequest()];

declare 'DeleteJobRequest',
    as InstanceOf['Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::DeleteJobRequest'];

coerce 'DeleteJobRequest',
    from HashRef, via { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::DeleteJobRequest'->new($_) };

declare 'RepeatedDeleteJobRequest',
    as ArrayRef[DeleteJobRequest()];

coerce 'RepeatedDeleteJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::DeleteJobRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteJobRequest',
    as HashRef[DeleteJobRequest()];

declare 'CancelJobResponse',
    as InstanceOf['Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::CancelJobResponse'];

coerce 'CancelJobResponse',
    from HashRef, via { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::CancelJobResponse'->new($_) };

declare 'RepeatedCancelJobResponse',
    as ArrayRef[CancelJobResponse()];

coerce 'RepeatedCancelJobResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::CancelJobResponse'->new($_) } @$_ ] };

declare 'MapStringCancelJobResponse',
    as HashRef[CancelJobResponse()];

declare 'ListBucketOperationsRequest',
    as InstanceOf['Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::ListBucketOperationsRequest'];

coerce 'ListBucketOperationsRequest',
    from HashRef, via { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::ListBucketOperationsRequest'->new($_) };

declare 'RepeatedListBucketOperationsRequest',
    as ArrayRef[ListBucketOperationsRequest()];

coerce 'RepeatedListBucketOperationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::ListBucketOperationsRequest'->new($_) } @$_ ] };

declare 'MapStringListBucketOperationsRequest',
    as HashRef[ListBucketOperationsRequest()];

declare 'ListBucketOperationsResponse',
    as InstanceOf['Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::ListBucketOperationsResponse'];

coerce 'ListBucketOperationsResponse',
    from HashRef, via { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::ListBucketOperationsResponse'->new($_) };

declare 'RepeatedListBucketOperationsResponse',
    as ArrayRef[ListBucketOperationsResponse()];

coerce 'RepeatedListBucketOperationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::ListBucketOperationsResponse'->new($_) } @$_ ] };

declare 'MapStringListBucketOperationsResponse',
    as HashRef[ListBucketOperationsResponse()];

declare 'GetBucketOperationRequest',
    as InstanceOf['Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::GetBucketOperationRequest'];

coerce 'GetBucketOperationRequest',
    from HashRef, via { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::GetBucketOperationRequest'->new($_) };

declare 'RepeatedGetBucketOperationRequest',
    as ArrayRef[GetBucketOperationRequest()];

coerce 'RepeatedGetBucketOperationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::GetBucketOperationRequest'->new($_) } @$_ ] };

declare 'MapStringGetBucketOperationRequest',
    as HashRef[GetBucketOperationRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Storagebatchoperations::V1::StorageBatchOperations::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
