package Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateMetastorePartitionRequest',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::CreateMetastorePartitionRequest'];

coerce 'CreateMetastorePartitionRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::CreateMetastorePartitionRequest'->new($_) };

declare 'RepeatedCreateMetastorePartitionRequest',
    as ArrayRef[CreateMetastorePartitionRequest()];

coerce 'RepeatedCreateMetastorePartitionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::CreateMetastorePartitionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateMetastorePartitionRequest',
    as HashRef[CreateMetastorePartitionRequest()];

declare 'BatchCreateMetastorePartitionsRequest',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchCreateMetastorePartitionsRequest'];

coerce 'BatchCreateMetastorePartitionsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchCreateMetastorePartitionsRequest'->new($_) };

declare 'RepeatedBatchCreateMetastorePartitionsRequest',
    as ArrayRef[BatchCreateMetastorePartitionsRequest()];

coerce 'RepeatedBatchCreateMetastorePartitionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchCreateMetastorePartitionsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchCreateMetastorePartitionsRequest',
    as HashRef[BatchCreateMetastorePartitionsRequest()];

declare 'BatchCreateMetastorePartitionsResponse',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchCreateMetastorePartitionsResponse'];

coerce 'BatchCreateMetastorePartitionsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchCreateMetastorePartitionsResponse'->new($_) };

declare 'RepeatedBatchCreateMetastorePartitionsResponse',
    as ArrayRef[BatchCreateMetastorePartitionsResponse()];

coerce 'RepeatedBatchCreateMetastorePartitionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchCreateMetastorePartitionsResponse'->new($_) } @$_ ] };

declare 'MapStringBatchCreateMetastorePartitionsResponse',
    as HashRef[BatchCreateMetastorePartitionsResponse()];

declare 'BatchDeleteMetastorePartitionsRequest',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchDeleteMetastorePartitionsRequest'];

coerce 'BatchDeleteMetastorePartitionsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchDeleteMetastorePartitionsRequest'->new($_) };

declare 'RepeatedBatchDeleteMetastorePartitionsRequest',
    as ArrayRef[BatchDeleteMetastorePartitionsRequest()];

coerce 'RepeatedBatchDeleteMetastorePartitionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchDeleteMetastorePartitionsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchDeleteMetastorePartitionsRequest',
    as HashRef[BatchDeleteMetastorePartitionsRequest()];

declare 'UpdateMetastorePartitionRequest',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::UpdateMetastorePartitionRequest'];

coerce 'UpdateMetastorePartitionRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::UpdateMetastorePartitionRequest'->new($_) };

declare 'RepeatedUpdateMetastorePartitionRequest',
    as ArrayRef[UpdateMetastorePartitionRequest()];

coerce 'RepeatedUpdateMetastorePartitionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::UpdateMetastorePartitionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateMetastorePartitionRequest',
    as HashRef[UpdateMetastorePartitionRequest()];

declare 'BatchUpdateMetastorePartitionsRequest',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchUpdateMetastorePartitionsRequest'];

coerce 'BatchUpdateMetastorePartitionsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchUpdateMetastorePartitionsRequest'->new($_) };

declare 'RepeatedBatchUpdateMetastorePartitionsRequest',
    as ArrayRef[BatchUpdateMetastorePartitionsRequest()];

coerce 'RepeatedBatchUpdateMetastorePartitionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchUpdateMetastorePartitionsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchUpdateMetastorePartitionsRequest',
    as HashRef[BatchUpdateMetastorePartitionsRequest()];

declare 'BatchUpdateMetastorePartitionsResponse',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchUpdateMetastorePartitionsResponse'];

coerce 'BatchUpdateMetastorePartitionsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchUpdateMetastorePartitionsResponse'->new($_) };

declare 'RepeatedBatchUpdateMetastorePartitionsResponse',
    as ArrayRef[BatchUpdateMetastorePartitionsResponse()];

coerce 'RepeatedBatchUpdateMetastorePartitionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchUpdateMetastorePartitionsResponse'->new($_) } @$_ ] };

declare 'MapStringBatchUpdateMetastorePartitionsResponse',
    as HashRef[BatchUpdateMetastorePartitionsResponse()];

declare 'ListMetastorePartitionsRequest',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::ListMetastorePartitionsRequest'];

coerce 'ListMetastorePartitionsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::ListMetastorePartitionsRequest'->new($_) };

declare 'RepeatedListMetastorePartitionsRequest',
    as ArrayRef[ListMetastorePartitionsRequest()];

coerce 'RepeatedListMetastorePartitionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::ListMetastorePartitionsRequest'->new($_) } @$_ ] };

declare 'MapStringListMetastorePartitionsRequest',
    as HashRef[ListMetastorePartitionsRequest()];

declare 'ListMetastorePartitionsResponse',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::ListMetastorePartitionsResponse'];

coerce 'ListMetastorePartitionsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::ListMetastorePartitionsResponse'->new($_) };

declare 'RepeatedListMetastorePartitionsResponse',
    as ArrayRef[ListMetastorePartitionsResponse()];

coerce 'RepeatedListMetastorePartitionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::ListMetastorePartitionsResponse'->new($_) } @$_ ] };

declare 'MapStringListMetastorePartitionsResponse',
    as HashRef[ListMetastorePartitionsResponse()];

declare 'StreamMetastorePartitionsRequest',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::StreamMetastorePartitionsRequest'];

coerce 'StreamMetastorePartitionsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::StreamMetastorePartitionsRequest'->new($_) };

declare 'RepeatedStreamMetastorePartitionsRequest',
    as ArrayRef[StreamMetastorePartitionsRequest()];

coerce 'RepeatedStreamMetastorePartitionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::StreamMetastorePartitionsRequest'->new($_) } @$_ ] };

declare 'MapStringStreamMetastorePartitionsRequest',
    as HashRef[StreamMetastorePartitionsRequest()];

declare 'StreamMetastorePartitionsResponse',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::StreamMetastorePartitionsResponse'];

coerce 'StreamMetastorePartitionsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::StreamMetastorePartitionsResponse'->new($_) };

declare 'RepeatedStreamMetastorePartitionsResponse',
    as ArrayRef[StreamMetastorePartitionsResponse()];

coerce 'RepeatedStreamMetastorePartitionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::StreamMetastorePartitionsResponse'->new($_) } @$_ ] };

declare 'MapStringStreamMetastorePartitionsResponse',
    as HashRef[StreamMetastorePartitionsResponse()];

declare 'BatchSizeTooLargeError',
    as InstanceOf['Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchSizeTooLargeError'];

coerce 'BatchSizeTooLargeError',
    from HashRef, via { 'Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchSizeTooLargeError'->new($_) };

declare 'RepeatedBatchSizeTooLargeError',
    as ArrayRef[BatchSizeTooLargeError()];

coerce 'RepeatedBatchSizeTooLargeError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::BatchSizeTooLargeError'->new($_) } @$_ ] };

declare 'MapStringBatchSizeTooLargeError',
    as HashRef[BatchSizeTooLargeError()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartition::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
