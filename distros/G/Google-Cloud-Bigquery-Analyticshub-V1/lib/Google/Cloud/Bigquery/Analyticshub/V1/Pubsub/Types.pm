package Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PubSubSubscription',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::PubSubSubscription'];

coerce 'PubSubSubscription',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::PubSubSubscription'->new($_) };

declare 'RepeatedPubSubSubscription',
    as ArrayRef[PubSubSubscription()];

coerce 'RepeatedPubSubSubscription',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::PubSubSubscription'->new($_) } @$_ ] };

declare 'MapStringPubSubSubscription',
    as HashRef[PubSubSubscription()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::PubSubSubscription::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::PubSubSubscription::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::PubSubSubscription::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'TagsEntry',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::PubSubSubscription::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::PubSubSubscription::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::PubSubSubscription::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

declare 'RetryPolicy',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::RetryPolicy'];

coerce 'RetryPolicy',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::RetryPolicy'->new($_) };

declare 'RepeatedRetryPolicy',
    as ArrayRef[RetryPolicy()];

coerce 'RepeatedRetryPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::RetryPolicy'->new($_) } @$_ ] };

declare 'MapStringRetryPolicy',
    as HashRef[RetryPolicy()];

declare 'DeadLetterPolicy',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::DeadLetterPolicy'];

coerce 'DeadLetterPolicy',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::DeadLetterPolicy'->new($_) };

declare 'RepeatedDeadLetterPolicy',
    as ArrayRef[DeadLetterPolicy()];

coerce 'RepeatedDeadLetterPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::DeadLetterPolicy'->new($_) } @$_ ] };

declare 'MapStringDeadLetterPolicy',
    as HashRef[DeadLetterPolicy()];

declare 'ExpirationPolicy',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::ExpirationPolicy'];

coerce 'ExpirationPolicy',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::ExpirationPolicy'->new($_) };

declare 'RepeatedExpirationPolicy',
    as ArrayRef[ExpirationPolicy()];

coerce 'RepeatedExpirationPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::ExpirationPolicy'->new($_) } @$_ ] };

declare 'MapStringExpirationPolicy',
    as HashRef[ExpirationPolicy()];

declare 'PushConfig',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::PushConfig'];

coerce 'PushConfig',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::PushConfig'->new($_) };

declare 'RepeatedPushConfig',
    as ArrayRef[PushConfig()];

coerce 'RepeatedPushConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::PushConfig'->new($_) } @$_ ] };

declare 'MapStringPushConfig',
    as HashRef[PushConfig()];

declare 'OidcToken',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::PushConfig::OidcToken'];

coerce 'OidcToken',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::PushConfig::OidcToken'->new($_) };

declare 'RepeatedOidcToken',
    as ArrayRef[OidcToken()];

coerce 'RepeatedOidcToken',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::PushConfig::OidcToken'->new($_) } @$_ ] };

declare 'MapStringOidcToken',
    as HashRef[OidcToken()];

declare 'PubsubWrapper',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::PushConfig::PubsubWrapper'];

coerce 'PubsubWrapper',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::PushConfig::PubsubWrapper'->new($_) };

declare 'RepeatedPubsubWrapper',
    as ArrayRef[PubsubWrapper()];

coerce 'RepeatedPubsubWrapper',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::PushConfig::PubsubWrapper'->new($_) } @$_ ] };

declare 'MapStringPubsubWrapper',
    as HashRef[PubsubWrapper()];

declare 'NoWrapper',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::PushConfig::NoWrapper'];

coerce 'NoWrapper',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::PushConfig::NoWrapper'->new($_) };

declare 'RepeatedNoWrapper',
    as ArrayRef[NoWrapper()];

coerce 'RepeatedNoWrapper',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::PushConfig::NoWrapper'->new($_) } @$_ ] };

declare 'MapStringNoWrapper',
    as HashRef[NoWrapper()];

declare 'AttributesEntry',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::PushConfig::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::PushConfig::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::PushConfig::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

declare 'BigQueryConfig',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::BigQueryConfig'];

coerce 'BigQueryConfig',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::BigQueryConfig'->new($_) };

declare 'RepeatedBigQueryConfig',
    as ArrayRef[BigQueryConfig()];

coerce 'RepeatedBigQueryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::BigQueryConfig'->new($_) } @$_ ] };

declare 'MapStringBigQueryConfig',
    as HashRef[BigQueryConfig()];

declare 'CloudStorageConfig',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::CloudStorageConfig'];

coerce 'CloudStorageConfig',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::CloudStorageConfig'->new($_) };

declare 'RepeatedCloudStorageConfig',
    as ArrayRef[CloudStorageConfig()];

coerce 'RepeatedCloudStorageConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::CloudStorageConfig'->new($_) } @$_ ] };

declare 'MapStringCloudStorageConfig',
    as HashRef[CloudStorageConfig()];

declare 'TextConfig',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::CloudStorageConfig::TextConfig'];

coerce 'TextConfig',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::CloudStorageConfig::TextConfig'->new($_) };

declare 'RepeatedTextConfig',
    as ArrayRef[TextConfig()];

coerce 'RepeatedTextConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::CloudStorageConfig::TextConfig'->new($_) } @$_ ] };

declare 'MapStringTextConfig',
    as HashRef[TextConfig()];

declare 'AvroConfig',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::CloudStorageConfig::AvroConfig'];

coerce 'AvroConfig',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::CloudStorageConfig::AvroConfig'->new($_) };

declare 'RepeatedAvroConfig',
    as ArrayRef[AvroConfig()];

coerce 'RepeatedAvroConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::CloudStorageConfig::AvroConfig'->new($_) } @$_ ] };

declare 'MapStringAvroConfig',
    as HashRef[AvroConfig()];

declare 'MessageTransform',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::MessageTransform'];

coerce 'MessageTransform',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::MessageTransform'->new($_) };

declare 'RepeatedMessageTransform',
    as ArrayRef[MessageTransform()];

coerce 'RepeatedMessageTransform',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::MessageTransform'->new($_) } @$_ ] };

declare 'MapStringMessageTransform',
    as HashRef[MessageTransform()];

declare 'JavaScriptUDF',
    as InstanceOf['Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::JavaScriptUDF'];

coerce 'JavaScriptUDF',
    from HashRef, via { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::JavaScriptUDF'->new($_) };

declare 'RepeatedJavaScriptUDF',
    as ArrayRef[JavaScriptUDF()];

coerce 'RepeatedJavaScriptUDF',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::JavaScriptUDF'->new($_) } @$_ ] };

declare 'MapStringJavaScriptUDF',
    as HashRef[JavaScriptUDF()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Analyticshub::V1::Pubsub::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
