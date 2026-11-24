package Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Job',
    as InstanceOf['Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::Job'];

coerce 'Job',
    from HashRef, via { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::Job'->new($_) };

declare 'RepeatedJob',
    as ArrayRef[Job()];

coerce 'RepeatedJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::Job'->new($_) } @$_ ] };

declare 'MapStringJob',
    as HashRef[Job()];

declare 'State',
    as (Int | Str);

declare 'BucketOperation',
    as InstanceOf['Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::BucketOperation'];

coerce 'BucketOperation',
    from HashRef, via { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::BucketOperation'->new($_) };

declare 'RepeatedBucketOperation',
    as ArrayRef[BucketOperation()];

coerce 'RepeatedBucketOperation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::BucketOperation'->new($_) } @$_ ] };

declare 'MapStringBucketOperation',
    as HashRef[BucketOperation()];

declare 'State',
    as (Int | Str);

declare 'BucketList',
    as InstanceOf['Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::BucketList'];

coerce 'BucketList',
    from HashRef, via { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::BucketList'->new($_) };

declare 'RepeatedBucketList',
    as ArrayRef[BucketList()];

coerce 'RepeatedBucketList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::BucketList'->new($_) } @$_ ] };

declare 'MapStringBucketList',
    as HashRef[BucketList()];

declare 'Bucket',
    as InstanceOf['Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::BucketList::Bucket'];

coerce 'Bucket',
    from HashRef, via { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::BucketList::Bucket'->new($_) };

declare 'RepeatedBucket',
    as ArrayRef[Bucket()];

coerce 'RepeatedBucket',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::BucketList::Bucket'->new($_) } @$_ ] };

declare 'MapStringBucket',
    as HashRef[Bucket()];

declare 'Manifest',
    as InstanceOf['Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::Manifest'];

coerce 'Manifest',
    from HashRef, via { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::Manifest'->new($_) };

declare 'RepeatedManifest',
    as ArrayRef[Manifest()];

coerce 'RepeatedManifest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::Manifest'->new($_) } @$_ ] };

declare 'MapStringManifest',
    as HashRef[Manifest()];

declare 'PrefixList',
    as InstanceOf['Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::PrefixList'];

coerce 'PrefixList',
    from HashRef, via { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::PrefixList'->new($_) };

declare 'RepeatedPrefixList',
    as ArrayRef[PrefixList()];

coerce 'RepeatedPrefixList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::PrefixList'->new($_) } @$_ ] };

declare 'MapStringPrefixList',
    as HashRef[PrefixList()];

declare 'PutObjectHold',
    as InstanceOf['Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::PutObjectHold'];

coerce 'PutObjectHold',
    from HashRef, via { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::PutObjectHold'->new($_) };

declare 'RepeatedPutObjectHold',
    as ArrayRef[PutObjectHold()];

coerce 'RepeatedPutObjectHold',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::PutObjectHold'->new($_) } @$_ ] };

declare 'MapStringPutObjectHold',
    as HashRef[PutObjectHold()];

declare 'HoldStatus',
    as (Int | Str);

declare 'DeleteObject',
    as InstanceOf['Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::DeleteObject'];

coerce 'DeleteObject',
    from HashRef, via { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::DeleteObject'->new($_) };

declare 'RepeatedDeleteObject',
    as ArrayRef[DeleteObject()];

coerce 'RepeatedDeleteObject',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::DeleteObject'->new($_) } @$_ ] };

declare 'MapStringDeleteObject',
    as HashRef[DeleteObject()];

declare 'RewriteObject',
    as InstanceOf['Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::RewriteObject'];

coerce 'RewriteObject',
    from HashRef, via { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::RewriteObject'->new($_) };

declare 'RepeatedRewriteObject',
    as ArrayRef[RewriteObject()];

coerce 'RepeatedRewriteObject',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::RewriteObject'->new($_) } @$_ ] };

declare 'MapStringRewriteObject',
    as HashRef[RewriteObject()];

declare 'ObjectRetention',
    as InstanceOf['Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::ObjectRetention'];

coerce 'ObjectRetention',
    from HashRef, via { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::ObjectRetention'->new($_) };

declare 'RepeatedObjectRetention',
    as ArrayRef[ObjectRetention()];

coerce 'RepeatedObjectRetention',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::ObjectRetention'->new($_) } @$_ ] };

declare 'MapStringObjectRetention',
    as HashRef[ObjectRetention()];

declare 'RetentionMode',
    as (Int | Str);

declare 'PutMetadata',
    as InstanceOf['Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::PutMetadata'];

coerce 'PutMetadata',
    from HashRef, via { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::PutMetadata'->new($_) };

declare 'RepeatedPutMetadata',
    as ArrayRef[PutMetadata()];

coerce 'RepeatedPutMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::PutMetadata'->new($_) } @$_ ] };

declare 'MapStringPutMetadata',
    as HashRef[PutMetadata()];

declare 'CustomMetadataEntry',
    as InstanceOf['Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::PutMetadata::CustomMetadataEntry'];

coerce 'CustomMetadataEntry',
    from HashRef, via { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::PutMetadata::CustomMetadataEntry'->new($_) };

declare 'RepeatedCustomMetadataEntry',
    as ArrayRef[CustomMetadataEntry()];

coerce 'RepeatedCustomMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::PutMetadata::CustomMetadataEntry'->new($_) } @$_ ] };

declare 'MapStringCustomMetadataEntry',
    as HashRef[CustomMetadataEntry()];

declare 'ObjectCustomContextPayload',
    as InstanceOf['Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::ObjectCustomContextPayload'];

coerce 'ObjectCustomContextPayload',
    from HashRef, via { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::ObjectCustomContextPayload'->new($_) };

declare 'RepeatedObjectCustomContextPayload',
    as ArrayRef[ObjectCustomContextPayload()];

coerce 'RepeatedObjectCustomContextPayload',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::ObjectCustomContextPayload'->new($_) } @$_ ] };

declare 'MapStringObjectCustomContextPayload',
    as HashRef[ObjectCustomContextPayload()];

declare 'CustomContextUpdates',
    as InstanceOf['Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::CustomContextUpdates'];

coerce 'CustomContextUpdates',
    from HashRef, via { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::CustomContextUpdates'->new($_) };

declare 'RepeatedCustomContextUpdates',
    as ArrayRef[CustomContextUpdates()];

coerce 'RepeatedCustomContextUpdates',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::CustomContextUpdates'->new($_) } @$_ ] };

declare 'MapStringCustomContextUpdates',
    as HashRef[CustomContextUpdates()];

declare 'UpdatesEntry',
    as InstanceOf['Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::CustomContextUpdates::UpdatesEntry'];

coerce 'UpdatesEntry',
    from HashRef, via { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::CustomContextUpdates::UpdatesEntry'->new($_) };

declare 'RepeatedUpdatesEntry',
    as ArrayRef[UpdatesEntry()];

coerce 'RepeatedUpdatesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::CustomContextUpdates::UpdatesEntry'->new($_) } @$_ ] };

declare 'MapStringUpdatesEntry',
    as HashRef[UpdatesEntry()];

declare 'UpdateObjectCustomContext',
    as InstanceOf['Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::UpdateObjectCustomContext'];

coerce 'UpdateObjectCustomContext',
    from HashRef, via { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::UpdateObjectCustomContext'->new($_) };

declare 'RepeatedUpdateObjectCustomContext',
    as ArrayRef[UpdateObjectCustomContext()];

coerce 'RepeatedUpdateObjectCustomContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::UpdateObjectCustomContext'->new($_) } @$_ ] };

declare 'MapStringUpdateObjectCustomContext',
    as HashRef[UpdateObjectCustomContext()];

declare 'ErrorSummary',
    as InstanceOf['Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::ErrorSummary'];

coerce 'ErrorSummary',
    from HashRef, via { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::ErrorSummary'->new($_) };

declare 'RepeatedErrorSummary',
    as ArrayRef[ErrorSummary()];

coerce 'RepeatedErrorSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::ErrorSummary'->new($_) } @$_ ] };

declare 'MapStringErrorSummary',
    as HashRef[ErrorSummary()];

declare 'ErrorLogEntry',
    as InstanceOf['Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::ErrorLogEntry'];

coerce 'ErrorLogEntry',
    from HashRef, via { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::ErrorLogEntry'->new($_) };

declare 'RepeatedErrorLogEntry',
    as ArrayRef[ErrorLogEntry()];

coerce 'RepeatedErrorLogEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::ErrorLogEntry'->new($_) } @$_ ] };

declare 'MapStringErrorLogEntry',
    as HashRef[ErrorLogEntry()];

declare 'Counters',
    as InstanceOf['Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::Counters'];

coerce 'Counters',
    from HashRef, via { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::Counters'->new($_) };

declare 'RepeatedCounters',
    as ArrayRef[Counters()];

coerce 'RepeatedCounters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::Counters'->new($_) } @$_ ] };

declare 'MapStringCounters',
    as HashRef[Counters()];

declare 'LoggingConfig',
    as InstanceOf['Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::LoggingConfig'];

coerce 'LoggingConfig',
    from HashRef, via { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::LoggingConfig'->new($_) };

declare 'RepeatedLoggingConfig',
    as ArrayRef[LoggingConfig()];

coerce 'RepeatedLoggingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::LoggingConfig'->new($_) } @$_ ] };

declare 'MapStringLoggingConfig',
    as HashRef[LoggingConfig()];

declare 'LoggableAction',
    as (Int | Str);

declare 'LoggableActionState',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Storagebatchoperations::V1::StorageBatchOperationsTypes::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
