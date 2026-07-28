package Google::Pubsub::V1::Pubsub::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'MessageStoragePolicy',
    as InstanceOf['Google::Pubsub::V1::Pubsub::MessageStoragePolicy'];

coerce 'MessageStoragePolicy',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::MessageStoragePolicy'->new($_) };

declare 'RepeatedMessageStoragePolicy',
    as ArrayRef[MessageStoragePolicy()];

coerce 'RepeatedMessageStoragePolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::MessageStoragePolicy'->new($_) } @$_ ] };

declare 'MapStringMessageStoragePolicy',
    as HashRef[MessageStoragePolicy()];

declare 'SchemaSettings',
    as InstanceOf['Google::Pubsub::V1::Pubsub::SchemaSettings'];

coerce 'SchemaSettings',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::SchemaSettings'->new($_) };

declare 'RepeatedSchemaSettings',
    as ArrayRef[SchemaSettings()];

coerce 'RepeatedSchemaSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::SchemaSettings'->new($_) } @$_ ] };

declare 'MapStringSchemaSettings',
    as HashRef[SchemaSettings()];

declare 'IngestionDataSourceSettings',
    as InstanceOf['Google::Pubsub::V1::Pubsub::IngestionDataSourceSettings'];

coerce 'IngestionDataSourceSettings',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::IngestionDataSourceSettings'->new($_) };

declare 'RepeatedIngestionDataSourceSettings',
    as ArrayRef[IngestionDataSourceSettings()];

coerce 'RepeatedIngestionDataSourceSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::IngestionDataSourceSettings'->new($_) } @$_ ] };

declare 'MapStringIngestionDataSourceSettings',
    as HashRef[IngestionDataSourceSettings()];

declare 'AwsKinesis',
    as InstanceOf['Google::Pubsub::V1::Pubsub::IngestionDataSourceSettings::AwsKinesis'];

coerce 'AwsKinesis',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::IngestionDataSourceSettings::AwsKinesis'->new($_) };

declare 'RepeatedAwsKinesis',
    as ArrayRef[AwsKinesis()];

coerce 'RepeatedAwsKinesis',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::IngestionDataSourceSettings::AwsKinesis'->new($_) } @$_ ] };

declare 'MapStringAwsKinesis',
    as HashRef[AwsKinesis()];

declare 'State',
    as (Int | Str);

declare 'CloudStorage',
    as InstanceOf['Google::Pubsub::V1::Pubsub::IngestionDataSourceSettings::CloudStorage'];

coerce 'CloudStorage',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::IngestionDataSourceSettings::CloudStorage'->new($_) };

declare 'RepeatedCloudStorage',
    as ArrayRef[CloudStorage()];

coerce 'RepeatedCloudStorage',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::IngestionDataSourceSettings::CloudStorage'->new($_) } @$_ ] };

declare 'MapStringCloudStorage',
    as HashRef[CloudStorage()];

declare 'State',
    as (Int | Str);

declare 'TextFormat',
    as InstanceOf['Google::Pubsub::V1::Pubsub::IngestionDataSourceSettings::CloudStorage::TextFormat'];

coerce 'TextFormat',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::IngestionDataSourceSettings::CloudStorage::TextFormat'->new($_) };

declare 'RepeatedTextFormat',
    as ArrayRef[TextFormat()];

coerce 'RepeatedTextFormat',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::IngestionDataSourceSettings::CloudStorage::TextFormat'->new($_) } @$_ ] };

declare 'MapStringTextFormat',
    as HashRef[TextFormat()];

declare 'AvroFormat',
    as InstanceOf['Google::Pubsub::V1::Pubsub::IngestionDataSourceSettings::CloudStorage::AvroFormat'];

coerce 'AvroFormat',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::IngestionDataSourceSettings::CloudStorage::AvroFormat'->new($_) };

declare 'RepeatedAvroFormat',
    as ArrayRef[AvroFormat()];

coerce 'RepeatedAvroFormat',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::IngestionDataSourceSettings::CloudStorage::AvroFormat'->new($_) } @$_ ] };

declare 'MapStringAvroFormat',
    as HashRef[AvroFormat()];

declare 'PubSubAvroFormat',
    as InstanceOf['Google::Pubsub::V1::Pubsub::IngestionDataSourceSettings::CloudStorage::PubSubAvroFormat'];

coerce 'PubSubAvroFormat',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::IngestionDataSourceSettings::CloudStorage::PubSubAvroFormat'->new($_) };

declare 'RepeatedPubSubAvroFormat',
    as ArrayRef[PubSubAvroFormat()];

coerce 'RepeatedPubSubAvroFormat',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::IngestionDataSourceSettings::CloudStorage::PubSubAvroFormat'->new($_) } @$_ ] };

declare 'MapStringPubSubAvroFormat',
    as HashRef[PubSubAvroFormat()];

declare 'AzureEventHubs',
    as InstanceOf['Google::Pubsub::V1::Pubsub::IngestionDataSourceSettings::AzureEventHubs'];

coerce 'AzureEventHubs',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::IngestionDataSourceSettings::AzureEventHubs'->new($_) };

declare 'RepeatedAzureEventHubs',
    as ArrayRef[AzureEventHubs()];

coerce 'RepeatedAzureEventHubs',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::IngestionDataSourceSettings::AzureEventHubs'->new($_) } @$_ ] };

declare 'MapStringAzureEventHubs',
    as HashRef[AzureEventHubs()];

declare 'State',
    as (Int | Str);

declare 'AwsMsk',
    as InstanceOf['Google::Pubsub::V1::Pubsub::IngestionDataSourceSettings::AwsMsk'];

coerce 'AwsMsk',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::IngestionDataSourceSettings::AwsMsk'->new($_) };

declare 'RepeatedAwsMsk',
    as ArrayRef[AwsMsk()];

coerce 'RepeatedAwsMsk',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::IngestionDataSourceSettings::AwsMsk'->new($_) } @$_ ] };

declare 'MapStringAwsMsk',
    as HashRef[AwsMsk()];

declare 'State',
    as (Int | Str);

declare 'ConfluentCloud',
    as InstanceOf['Google::Pubsub::V1::Pubsub::IngestionDataSourceSettings::ConfluentCloud'];

coerce 'ConfluentCloud',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::IngestionDataSourceSettings::ConfluentCloud'->new($_) };

declare 'RepeatedConfluentCloud',
    as ArrayRef[ConfluentCloud()];

coerce 'RepeatedConfluentCloud',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::IngestionDataSourceSettings::ConfluentCloud'->new($_) } @$_ ] };

declare 'MapStringConfluentCloud',
    as HashRef[ConfluentCloud()];

declare 'State',
    as (Int | Str);

declare 'PlatformLogsSettings',
    as InstanceOf['Google::Pubsub::V1::Pubsub::PlatformLogsSettings'];

coerce 'PlatformLogsSettings',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::PlatformLogsSettings'->new($_) };

declare 'RepeatedPlatformLogsSettings',
    as ArrayRef[PlatformLogsSettings()];

coerce 'RepeatedPlatformLogsSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::PlatformLogsSettings'->new($_) } @$_ ] };

declare 'MapStringPlatformLogsSettings',
    as HashRef[PlatformLogsSettings()];

declare 'Severity',
    as (Int | Str);

declare 'IngestionFailureEvent',
    as InstanceOf['Google::Pubsub::V1::Pubsub::IngestionFailureEvent'];

coerce 'IngestionFailureEvent',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::IngestionFailureEvent'->new($_) };

declare 'RepeatedIngestionFailureEvent',
    as ArrayRef[IngestionFailureEvent()];

coerce 'RepeatedIngestionFailureEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::IngestionFailureEvent'->new($_) } @$_ ] };

declare 'MapStringIngestionFailureEvent',
    as HashRef[IngestionFailureEvent()];

declare 'ApiViolationReason',
    as InstanceOf['Google::Pubsub::V1::Pubsub::IngestionFailureEvent::ApiViolationReason'];

coerce 'ApiViolationReason',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::IngestionFailureEvent::ApiViolationReason'->new($_) };

declare 'RepeatedApiViolationReason',
    as ArrayRef[ApiViolationReason()];

coerce 'RepeatedApiViolationReason',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::IngestionFailureEvent::ApiViolationReason'->new($_) } @$_ ] };

declare 'MapStringApiViolationReason',
    as HashRef[ApiViolationReason()];

declare 'AvroFailureReason',
    as InstanceOf['Google::Pubsub::V1::Pubsub::IngestionFailureEvent::AvroFailureReason'];

coerce 'AvroFailureReason',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::IngestionFailureEvent::AvroFailureReason'->new($_) };

declare 'RepeatedAvroFailureReason',
    as ArrayRef[AvroFailureReason()];

coerce 'RepeatedAvroFailureReason',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::IngestionFailureEvent::AvroFailureReason'->new($_) } @$_ ] };

declare 'MapStringAvroFailureReason',
    as HashRef[AvroFailureReason()];

declare 'SchemaViolationReason',
    as InstanceOf['Google::Pubsub::V1::Pubsub::IngestionFailureEvent::SchemaViolationReason'];

coerce 'SchemaViolationReason',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::IngestionFailureEvent::SchemaViolationReason'->new($_) };

declare 'RepeatedSchemaViolationReason',
    as ArrayRef[SchemaViolationReason()];

coerce 'RepeatedSchemaViolationReason',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::IngestionFailureEvent::SchemaViolationReason'->new($_) } @$_ ] };

declare 'MapStringSchemaViolationReason',
    as HashRef[SchemaViolationReason()];

declare 'MessageTransformationFailureReason',
    as InstanceOf['Google::Pubsub::V1::Pubsub::IngestionFailureEvent::MessageTransformationFailureReason'];

coerce 'MessageTransformationFailureReason',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::IngestionFailureEvent::MessageTransformationFailureReason'->new($_) };

declare 'RepeatedMessageTransformationFailureReason',
    as ArrayRef[MessageTransformationFailureReason()];

coerce 'RepeatedMessageTransformationFailureReason',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::IngestionFailureEvent::MessageTransformationFailureReason'->new($_) } @$_ ] };

declare 'MapStringMessageTransformationFailureReason',
    as HashRef[MessageTransformationFailureReason()];

declare 'CloudStorageFailure',
    as InstanceOf['Google::Pubsub::V1::Pubsub::IngestionFailureEvent::CloudStorageFailure'];

coerce 'CloudStorageFailure',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::IngestionFailureEvent::CloudStorageFailure'->new($_) };

declare 'RepeatedCloudStorageFailure',
    as ArrayRef[CloudStorageFailure()];

coerce 'RepeatedCloudStorageFailure',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::IngestionFailureEvent::CloudStorageFailure'->new($_) } @$_ ] };

declare 'MapStringCloudStorageFailure',
    as HashRef[CloudStorageFailure()];

declare 'AwsMskFailureReason',
    as InstanceOf['Google::Pubsub::V1::Pubsub::IngestionFailureEvent::AwsMskFailureReason'];

coerce 'AwsMskFailureReason',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::IngestionFailureEvent::AwsMskFailureReason'->new($_) };

declare 'RepeatedAwsMskFailureReason',
    as ArrayRef[AwsMskFailureReason()];

coerce 'RepeatedAwsMskFailureReason',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::IngestionFailureEvent::AwsMskFailureReason'->new($_) } @$_ ] };

declare 'MapStringAwsMskFailureReason',
    as HashRef[AwsMskFailureReason()];

declare 'AzureEventHubsFailureReason',
    as InstanceOf['Google::Pubsub::V1::Pubsub::IngestionFailureEvent::AzureEventHubsFailureReason'];

coerce 'AzureEventHubsFailureReason',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::IngestionFailureEvent::AzureEventHubsFailureReason'->new($_) };

declare 'RepeatedAzureEventHubsFailureReason',
    as ArrayRef[AzureEventHubsFailureReason()];

coerce 'RepeatedAzureEventHubsFailureReason',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::IngestionFailureEvent::AzureEventHubsFailureReason'->new($_) } @$_ ] };

declare 'MapStringAzureEventHubsFailureReason',
    as HashRef[AzureEventHubsFailureReason()];

declare 'ConfluentCloudFailureReason',
    as InstanceOf['Google::Pubsub::V1::Pubsub::IngestionFailureEvent::ConfluentCloudFailureReason'];

coerce 'ConfluentCloudFailureReason',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::IngestionFailureEvent::ConfluentCloudFailureReason'->new($_) };

declare 'RepeatedConfluentCloudFailureReason',
    as ArrayRef[ConfluentCloudFailureReason()];

coerce 'RepeatedConfluentCloudFailureReason',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::IngestionFailureEvent::ConfluentCloudFailureReason'->new($_) } @$_ ] };

declare 'MapStringConfluentCloudFailureReason',
    as HashRef[ConfluentCloudFailureReason()];

declare 'AwsKinesisFailureReason',
    as InstanceOf['Google::Pubsub::V1::Pubsub::IngestionFailureEvent::AwsKinesisFailureReason'];

coerce 'AwsKinesisFailureReason',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::IngestionFailureEvent::AwsKinesisFailureReason'->new($_) };

declare 'RepeatedAwsKinesisFailureReason',
    as ArrayRef[AwsKinesisFailureReason()];

coerce 'RepeatedAwsKinesisFailureReason',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::IngestionFailureEvent::AwsKinesisFailureReason'->new($_) } @$_ ] };

declare 'MapStringAwsKinesisFailureReason',
    as HashRef[AwsKinesisFailureReason()];

declare 'JavaScriptUDF',
    as InstanceOf['Google::Pubsub::V1::Pubsub::JavaScriptUDF'];

coerce 'JavaScriptUDF',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::JavaScriptUDF'->new($_) };

declare 'RepeatedJavaScriptUDF',
    as ArrayRef[JavaScriptUDF()];

coerce 'RepeatedJavaScriptUDF',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::JavaScriptUDF'->new($_) } @$_ ] };

declare 'MapStringJavaScriptUDF',
    as HashRef[JavaScriptUDF()];

declare 'AIInference',
    as InstanceOf['Google::Pubsub::V1::Pubsub::AIInference'];

coerce 'AIInference',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::AIInference'->new($_) };

declare 'RepeatedAIInference',
    as ArrayRef[AIInference()];

coerce 'RepeatedAIInference',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::AIInference'->new($_) } @$_ ] };

declare 'MapStringAIInference',
    as HashRef[AIInference()];

declare 'UnstructuredInference',
    as InstanceOf['Google::Pubsub::V1::Pubsub::AIInference::UnstructuredInference'];

coerce 'UnstructuredInference',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::AIInference::UnstructuredInference'->new($_) };

declare 'RepeatedUnstructuredInference',
    as ArrayRef[UnstructuredInference()];

coerce 'RepeatedUnstructuredInference',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::AIInference::UnstructuredInference'->new($_) } @$_ ] };

declare 'MapStringUnstructuredInference',
    as HashRef[UnstructuredInference()];

declare 'MessageTransform',
    as InstanceOf['Google::Pubsub::V1::Pubsub::MessageTransform'];

coerce 'MessageTransform',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::MessageTransform'->new($_) };

declare 'RepeatedMessageTransform',
    as ArrayRef[MessageTransform()];

coerce 'RepeatedMessageTransform',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::MessageTransform'->new($_) } @$_ ] };

declare 'MapStringMessageTransform',
    as HashRef[MessageTransform()];

declare 'Topic',
    as InstanceOf['Google::Pubsub::V1::Pubsub::Topic'];

coerce 'Topic',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::Topic'->new($_) };

declare 'RepeatedTopic',
    as ArrayRef[Topic()];

coerce 'RepeatedTopic',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::Topic'->new($_) } @$_ ] };

declare 'MapStringTopic',
    as HashRef[Topic()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Pubsub::V1::Pubsub::Topic::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::Topic::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::Topic::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'TagsEntry',
    as InstanceOf['Google::Pubsub::V1::Pubsub::Topic::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::Topic::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::Topic::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

declare 'PubsubMessage',
    as InstanceOf['Google::Pubsub::V1::Pubsub::PubsubMessage'];

coerce 'PubsubMessage',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::PubsubMessage'->new($_) };

declare 'RepeatedPubsubMessage',
    as ArrayRef[PubsubMessage()];

coerce 'RepeatedPubsubMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::PubsubMessage'->new($_) } @$_ ] };

declare 'MapStringPubsubMessage',
    as HashRef[PubsubMessage()];

declare 'AttributesEntry',
    as InstanceOf['Google::Pubsub::V1::Pubsub::PubsubMessage::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::PubsubMessage::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::PubsubMessage::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

declare 'GetTopicRequest',
    as InstanceOf['Google::Pubsub::V1::Pubsub::GetTopicRequest'];

coerce 'GetTopicRequest',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::GetTopicRequest'->new($_) };

declare 'RepeatedGetTopicRequest',
    as ArrayRef[GetTopicRequest()];

coerce 'RepeatedGetTopicRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::GetTopicRequest'->new($_) } @$_ ] };

declare 'MapStringGetTopicRequest',
    as HashRef[GetTopicRequest()];

declare 'UpdateTopicRequest',
    as InstanceOf['Google::Pubsub::V1::Pubsub::UpdateTopicRequest'];

coerce 'UpdateTopicRequest',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::UpdateTopicRequest'->new($_) };

declare 'RepeatedUpdateTopicRequest',
    as ArrayRef[UpdateTopicRequest()];

coerce 'RepeatedUpdateTopicRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::UpdateTopicRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTopicRequest',
    as HashRef[UpdateTopicRequest()];

declare 'PublishRequest',
    as InstanceOf['Google::Pubsub::V1::Pubsub::PublishRequest'];

coerce 'PublishRequest',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::PublishRequest'->new($_) };

declare 'RepeatedPublishRequest',
    as ArrayRef[PublishRequest()];

coerce 'RepeatedPublishRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::PublishRequest'->new($_) } @$_ ] };

declare 'MapStringPublishRequest',
    as HashRef[PublishRequest()];

declare 'PublishResponse',
    as InstanceOf['Google::Pubsub::V1::Pubsub::PublishResponse'];

coerce 'PublishResponse',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::PublishResponse'->new($_) };

declare 'RepeatedPublishResponse',
    as ArrayRef[PublishResponse()];

coerce 'RepeatedPublishResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::PublishResponse'->new($_) } @$_ ] };

declare 'MapStringPublishResponse',
    as HashRef[PublishResponse()];

declare 'ListTopicsRequest',
    as InstanceOf['Google::Pubsub::V1::Pubsub::ListTopicsRequest'];

coerce 'ListTopicsRequest',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::ListTopicsRequest'->new($_) };

declare 'RepeatedListTopicsRequest',
    as ArrayRef[ListTopicsRequest()];

coerce 'RepeatedListTopicsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::ListTopicsRequest'->new($_) } @$_ ] };

declare 'MapStringListTopicsRequest',
    as HashRef[ListTopicsRequest()];

declare 'ListTopicsResponse',
    as InstanceOf['Google::Pubsub::V1::Pubsub::ListTopicsResponse'];

coerce 'ListTopicsResponse',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::ListTopicsResponse'->new($_) };

declare 'RepeatedListTopicsResponse',
    as ArrayRef[ListTopicsResponse()];

coerce 'RepeatedListTopicsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::ListTopicsResponse'->new($_) } @$_ ] };

declare 'MapStringListTopicsResponse',
    as HashRef[ListTopicsResponse()];

declare 'ListTopicSubscriptionsRequest',
    as InstanceOf['Google::Pubsub::V1::Pubsub::ListTopicSubscriptionsRequest'];

coerce 'ListTopicSubscriptionsRequest',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::ListTopicSubscriptionsRequest'->new($_) };

declare 'RepeatedListTopicSubscriptionsRequest',
    as ArrayRef[ListTopicSubscriptionsRequest()];

coerce 'RepeatedListTopicSubscriptionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::ListTopicSubscriptionsRequest'->new($_) } @$_ ] };

declare 'MapStringListTopicSubscriptionsRequest',
    as HashRef[ListTopicSubscriptionsRequest()];

declare 'ListTopicSubscriptionsResponse',
    as InstanceOf['Google::Pubsub::V1::Pubsub::ListTopicSubscriptionsResponse'];

coerce 'ListTopicSubscriptionsResponse',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::ListTopicSubscriptionsResponse'->new($_) };

declare 'RepeatedListTopicSubscriptionsResponse',
    as ArrayRef[ListTopicSubscriptionsResponse()];

coerce 'RepeatedListTopicSubscriptionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::ListTopicSubscriptionsResponse'->new($_) } @$_ ] };

declare 'MapStringListTopicSubscriptionsResponse',
    as HashRef[ListTopicSubscriptionsResponse()];

declare 'ListTopicSnapshotsRequest',
    as InstanceOf['Google::Pubsub::V1::Pubsub::ListTopicSnapshotsRequest'];

coerce 'ListTopicSnapshotsRequest',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::ListTopicSnapshotsRequest'->new($_) };

declare 'RepeatedListTopicSnapshotsRequest',
    as ArrayRef[ListTopicSnapshotsRequest()];

coerce 'RepeatedListTopicSnapshotsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::ListTopicSnapshotsRequest'->new($_) } @$_ ] };

declare 'MapStringListTopicSnapshotsRequest',
    as HashRef[ListTopicSnapshotsRequest()];

declare 'ListTopicSnapshotsResponse',
    as InstanceOf['Google::Pubsub::V1::Pubsub::ListTopicSnapshotsResponse'];

coerce 'ListTopicSnapshotsResponse',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::ListTopicSnapshotsResponse'->new($_) };

declare 'RepeatedListTopicSnapshotsResponse',
    as ArrayRef[ListTopicSnapshotsResponse()];

coerce 'RepeatedListTopicSnapshotsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::ListTopicSnapshotsResponse'->new($_) } @$_ ] };

declare 'MapStringListTopicSnapshotsResponse',
    as HashRef[ListTopicSnapshotsResponse()];

declare 'DeleteTopicRequest',
    as InstanceOf['Google::Pubsub::V1::Pubsub::DeleteTopicRequest'];

coerce 'DeleteTopicRequest',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::DeleteTopicRequest'->new($_) };

declare 'RepeatedDeleteTopicRequest',
    as ArrayRef[DeleteTopicRequest()];

coerce 'RepeatedDeleteTopicRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::DeleteTopicRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTopicRequest',
    as HashRef[DeleteTopicRequest()];

declare 'DetachSubscriptionRequest',
    as InstanceOf['Google::Pubsub::V1::Pubsub::DetachSubscriptionRequest'];

coerce 'DetachSubscriptionRequest',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::DetachSubscriptionRequest'->new($_) };

declare 'RepeatedDetachSubscriptionRequest',
    as ArrayRef[DetachSubscriptionRequest()];

coerce 'RepeatedDetachSubscriptionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::DetachSubscriptionRequest'->new($_) } @$_ ] };

declare 'MapStringDetachSubscriptionRequest',
    as HashRef[DetachSubscriptionRequest()];

declare 'DetachSubscriptionResponse',
    as InstanceOf['Google::Pubsub::V1::Pubsub::DetachSubscriptionResponse'];

coerce 'DetachSubscriptionResponse',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::DetachSubscriptionResponse'->new($_) };

declare 'RepeatedDetachSubscriptionResponse',
    as ArrayRef[DetachSubscriptionResponse()];

coerce 'RepeatedDetachSubscriptionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::DetachSubscriptionResponse'->new($_) } @$_ ] };

declare 'MapStringDetachSubscriptionResponse',
    as HashRef[DetachSubscriptionResponse()];

declare 'Subscription',
    as InstanceOf['Google::Pubsub::V1::Pubsub::Subscription'];

coerce 'Subscription',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::Subscription'->new($_) };

declare 'RepeatedSubscription',
    as ArrayRef[Subscription()];

coerce 'RepeatedSubscription',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::Subscription'->new($_) } @$_ ] };

declare 'MapStringSubscription',
    as HashRef[Subscription()];

declare 'State',
    as (Int | Str);

declare 'AnalyticsHubSubscriptionInfo',
    as InstanceOf['Google::Pubsub::V1::Pubsub::Subscription::AnalyticsHubSubscriptionInfo'];

coerce 'AnalyticsHubSubscriptionInfo',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::Subscription::AnalyticsHubSubscriptionInfo'->new($_) };

declare 'RepeatedAnalyticsHubSubscriptionInfo',
    as ArrayRef[AnalyticsHubSubscriptionInfo()];

coerce 'RepeatedAnalyticsHubSubscriptionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::Subscription::AnalyticsHubSubscriptionInfo'->new($_) } @$_ ] };

declare 'MapStringAnalyticsHubSubscriptionInfo',
    as HashRef[AnalyticsHubSubscriptionInfo()];

declare 'LabelsEntry',
    as InstanceOf['Google::Pubsub::V1::Pubsub::Subscription::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::Subscription::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::Subscription::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'TagsEntry',
    as InstanceOf['Google::Pubsub::V1::Pubsub::Subscription::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::Subscription::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::Subscription::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

declare 'RetryPolicy',
    as InstanceOf['Google::Pubsub::V1::Pubsub::RetryPolicy'];

coerce 'RetryPolicy',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::RetryPolicy'->new($_) };

declare 'RepeatedRetryPolicy',
    as ArrayRef[RetryPolicy()];

coerce 'RepeatedRetryPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::RetryPolicy'->new($_) } @$_ ] };

declare 'MapStringRetryPolicy',
    as HashRef[RetryPolicy()];

declare 'DeadLetterPolicy',
    as InstanceOf['Google::Pubsub::V1::Pubsub::DeadLetterPolicy'];

coerce 'DeadLetterPolicy',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::DeadLetterPolicy'->new($_) };

declare 'RepeatedDeadLetterPolicy',
    as ArrayRef[DeadLetterPolicy()];

coerce 'RepeatedDeadLetterPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::DeadLetterPolicy'->new($_) } @$_ ] };

declare 'MapStringDeadLetterPolicy',
    as HashRef[DeadLetterPolicy()];

declare 'ExpirationPolicy',
    as InstanceOf['Google::Pubsub::V1::Pubsub::ExpirationPolicy'];

coerce 'ExpirationPolicy',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::ExpirationPolicy'->new($_) };

declare 'RepeatedExpirationPolicy',
    as ArrayRef[ExpirationPolicy()];

coerce 'RepeatedExpirationPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::ExpirationPolicy'->new($_) } @$_ ] };

declare 'MapStringExpirationPolicy',
    as HashRef[ExpirationPolicy()];

declare 'PushConfig',
    as InstanceOf['Google::Pubsub::V1::Pubsub::PushConfig'];

coerce 'PushConfig',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::PushConfig'->new($_) };

declare 'RepeatedPushConfig',
    as ArrayRef[PushConfig()];

coerce 'RepeatedPushConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::PushConfig'->new($_) } @$_ ] };

declare 'MapStringPushConfig',
    as HashRef[PushConfig()];

declare 'OidcToken',
    as InstanceOf['Google::Pubsub::V1::Pubsub::PushConfig::OidcToken'];

coerce 'OidcToken',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::PushConfig::OidcToken'->new($_) };

declare 'RepeatedOidcToken',
    as ArrayRef[OidcToken()];

coerce 'RepeatedOidcToken',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::PushConfig::OidcToken'->new($_) } @$_ ] };

declare 'MapStringOidcToken',
    as HashRef[OidcToken()];

declare 'PubsubWrapper',
    as InstanceOf['Google::Pubsub::V1::Pubsub::PushConfig::PubsubWrapper'];

coerce 'PubsubWrapper',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::PushConfig::PubsubWrapper'->new($_) };

declare 'RepeatedPubsubWrapper',
    as ArrayRef[PubsubWrapper()];

coerce 'RepeatedPubsubWrapper',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::PushConfig::PubsubWrapper'->new($_) } @$_ ] };

declare 'MapStringPubsubWrapper',
    as HashRef[PubsubWrapper()];

declare 'NoWrapper',
    as InstanceOf['Google::Pubsub::V1::Pubsub::PushConfig::NoWrapper'];

coerce 'NoWrapper',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::PushConfig::NoWrapper'->new($_) };

declare 'RepeatedNoWrapper',
    as ArrayRef[NoWrapper()];

coerce 'RepeatedNoWrapper',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::PushConfig::NoWrapper'->new($_) } @$_ ] };

declare 'MapStringNoWrapper',
    as HashRef[NoWrapper()];

declare 'AttributesEntry',
    as InstanceOf['Google::Pubsub::V1::Pubsub::PushConfig::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::PushConfig::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::PushConfig::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

declare 'BigQueryConfig',
    as InstanceOf['Google::Pubsub::V1::Pubsub::BigQueryConfig'];

coerce 'BigQueryConfig',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::BigQueryConfig'->new($_) };

declare 'RepeatedBigQueryConfig',
    as ArrayRef[BigQueryConfig()];

coerce 'RepeatedBigQueryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::BigQueryConfig'->new($_) } @$_ ] };

declare 'MapStringBigQueryConfig',
    as HashRef[BigQueryConfig()];

declare 'State',
    as (Int | Str);

declare 'BigtableConfig',
    as InstanceOf['Google::Pubsub::V1::Pubsub::BigtableConfig'];

coerce 'BigtableConfig',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::BigtableConfig'->new($_) };

declare 'RepeatedBigtableConfig',
    as ArrayRef[BigtableConfig()];

coerce 'RepeatedBigtableConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::BigtableConfig'->new($_) } @$_ ] };

declare 'MapStringBigtableConfig',
    as HashRef[BigtableConfig()];

declare 'State',
    as (Int | Str);

declare 'CloudStorageConfig',
    as InstanceOf['Google::Pubsub::V1::Pubsub::CloudStorageConfig'];

coerce 'CloudStorageConfig',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::CloudStorageConfig'->new($_) };

declare 'RepeatedCloudStorageConfig',
    as ArrayRef[CloudStorageConfig()];

coerce 'RepeatedCloudStorageConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::CloudStorageConfig'->new($_) } @$_ ] };

declare 'MapStringCloudStorageConfig',
    as HashRef[CloudStorageConfig()];

declare 'State',
    as (Int | Str);

declare 'TextConfig',
    as InstanceOf['Google::Pubsub::V1::Pubsub::CloudStorageConfig::TextConfig'];

coerce 'TextConfig',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::CloudStorageConfig::TextConfig'->new($_) };

declare 'RepeatedTextConfig',
    as ArrayRef[TextConfig()];

coerce 'RepeatedTextConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::CloudStorageConfig::TextConfig'->new($_) } @$_ ] };

declare 'MapStringTextConfig',
    as HashRef[TextConfig()];

declare 'AvroConfig',
    as InstanceOf['Google::Pubsub::V1::Pubsub::CloudStorageConfig::AvroConfig'];

coerce 'AvroConfig',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::CloudStorageConfig::AvroConfig'->new($_) };

declare 'RepeatedAvroConfig',
    as ArrayRef[AvroConfig()];

coerce 'RepeatedAvroConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::CloudStorageConfig::AvroConfig'->new($_) } @$_ ] };

declare 'MapStringAvroConfig',
    as HashRef[AvroConfig()];

declare 'ReceivedMessage',
    as InstanceOf['Google::Pubsub::V1::Pubsub::ReceivedMessage'];

coerce 'ReceivedMessage',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::ReceivedMessage'->new($_) };

declare 'RepeatedReceivedMessage',
    as ArrayRef[ReceivedMessage()];

coerce 'RepeatedReceivedMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::ReceivedMessage'->new($_) } @$_ ] };

declare 'MapStringReceivedMessage',
    as HashRef[ReceivedMessage()];

declare 'GetSubscriptionRequest',
    as InstanceOf['Google::Pubsub::V1::Pubsub::GetSubscriptionRequest'];

coerce 'GetSubscriptionRequest',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::GetSubscriptionRequest'->new($_) };

declare 'RepeatedGetSubscriptionRequest',
    as ArrayRef[GetSubscriptionRequest()];

coerce 'RepeatedGetSubscriptionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::GetSubscriptionRequest'->new($_) } @$_ ] };

declare 'MapStringGetSubscriptionRequest',
    as HashRef[GetSubscriptionRequest()];

declare 'UpdateSubscriptionRequest',
    as InstanceOf['Google::Pubsub::V1::Pubsub::UpdateSubscriptionRequest'];

coerce 'UpdateSubscriptionRequest',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::UpdateSubscriptionRequest'->new($_) };

declare 'RepeatedUpdateSubscriptionRequest',
    as ArrayRef[UpdateSubscriptionRequest()];

coerce 'RepeatedUpdateSubscriptionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::UpdateSubscriptionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSubscriptionRequest',
    as HashRef[UpdateSubscriptionRequest()];

declare 'ListSubscriptionsRequest',
    as InstanceOf['Google::Pubsub::V1::Pubsub::ListSubscriptionsRequest'];

coerce 'ListSubscriptionsRequest',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::ListSubscriptionsRequest'->new($_) };

declare 'RepeatedListSubscriptionsRequest',
    as ArrayRef[ListSubscriptionsRequest()];

coerce 'RepeatedListSubscriptionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::ListSubscriptionsRequest'->new($_) } @$_ ] };

declare 'MapStringListSubscriptionsRequest',
    as HashRef[ListSubscriptionsRequest()];

declare 'ListSubscriptionsResponse',
    as InstanceOf['Google::Pubsub::V1::Pubsub::ListSubscriptionsResponse'];

coerce 'ListSubscriptionsResponse',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::ListSubscriptionsResponse'->new($_) };

declare 'RepeatedListSubscriptionsResponse',
    as ArrayRef[ListSubscriptionsResponse()];

coerce 'RepeatedListSubscriptionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::ListSubscriptionsResponse'->new($_) } @$_ ] };

declare 'MapStringListSubscriptionsResponse',
    as HashRef[ListSubscriptionsResponse()];

declare 'DeleteSubscriptionRequest',
    as InstanceOf['Google::Pubsub::V1::Pubsub::DeleteSubscriptionRequest'];

coerce 'DeleteSubscriptionRequest',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::DeleteSubscriptionRequest'->new($_) };

declare 'RepeatedDeleteSubscriptionRequest',
    as ArrayRef[DeleteSubscriptionRequest()];

coerce 'RepeatedDeleteSubscriptionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::DeleteSubscriptionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSubscriptionRequest',
    as HashRef[DeleteSubscriptionRequest()];

declare 'ModifyPushConfigRequest',
    as InstanceOf['Google::Pubsub::V1::Pubsub::ModifyPushConfigRequest'];

coerce 'ModifyPushConfigRequest',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::ModifyPushConfigRequest'->new($_) };

declare 'RepeatedModifyPushConfigRequest',
    as ArrayRef[ModifyPushConfigRequest()];

coerce 'RepeatedModifyPushConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::ModifyPushConfigRequest'->new($_) } @$_ ] };

declare 'MapStringModifyPushConfigRequest',
    as HashRef[ModifyPushConfigRequest()];

declare 'PullRequest',
    as InstanceOf['Google::Pubsub::V1::Pubsub::PullRequest'];

coerce 'PullRequest',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::PullRequest'->new($_) };

declare 'RepeatedPullRequest',
    as ArrayRef[PullRequest()];

coerce 'RepeatedPullRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::PullRequest'->new($_) } @$_ ] };

declare 'MapStringPullRequest',
    as HashRef[PullRequest()];

declare 'PullResponse',
    as InstanceOf['Google::Pubsub::V1::Pubsub::PullResponse'];

coerce 'PullResponse',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::PullResponse'->new($_) };

declare 'RepeatedPullResponse',
    as ArrayRef[PullResponse()];

coerce 'RepeatedPullResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::PullResponse'->new($_) } @$_ ] };

declare 'MapStringPullResponse',
    as HashRef[PullResponse()];

declare 'ModifyAckDeadlineRequest',
    as InstanceOf['Google::Pubsub::V1::Pubsub::ModifyAckDeadlineRequest'];

coerce 'ModifyAckDeadlineRequest',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::ModifyAckDeadlineRequest'->new($_) };

declare 'RepeatedModifyAckDeadlineRequest',
    as ArrayRef[ModifyAckDeadlineRequest()];

coerce 'RepeatedModifyAckDeadlineRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::ModifyAckDeadlineRequest'->new($_) } @$_ ] };

declare 'MapStringModifyAckDeadlineRequest',
    as HashRef[ModifyAckDeadlineRequest()];

declare 'AcknowledgeRequest',
    as InstanceOf['Google::Pubsub::V1::Pubsub::AcknowledgeRequest'];

coerce 'AcknowledgeRequest',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::AcknowledgeRequest'->new($_) };

declare 'RepeatedAcknowledgeRequest',
    as ArrayRef[AcknowledgeRequest()];

coerce 'RepeatedAcknowledgeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::AcknowledgeRequest'->new($_) } @$_ ] };

declare 'MapStringAcknowledgeRequest',
    as HashRef[AcknowledgeRequest()];

declare 'StreamingPullRequest',
    as InstanceOf['Google::Pubsub::V1::Pubsub::StreamingPullRequest'];

coerce 'StreamingPullRequest',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::StreamingPullRequest'->new($_) };

declare 'RepeatedStreamingPullRequest',
    as ArrayRef[StreamingPullRequest()];

coerce 'RepeatedStreamingPullRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::StreamingPullRequest'->new($_) } @$_ ] };

declare 'MapStringStreamingPullRequest',
    as HashRef[StreamingPullRequest()];

declare 'StreamingPullResponse',
    as InstanceOf['Google::Pubsub::V1::Pubsub::StreamingPullResponse'];

coerce 'StreamingPullResponse',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::StreamingPullResponse'->new($_) };

declare 'RepeatedStreamingPullResponse',
    as ArrayRef[StreamingPullResponse()];

coerce 'RepeatedStreamingPullResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::StreamingPullResponse'->new($_) } @$_ ] };

declare 'MapStringStreamingPullResponse',
    as HashRef[StreamingPullResponse()];

declare 'AcknowledgeConfirmation',
    as InstanceOf['Google::Pubsub::V1::Pubsub::StreamingPullResponse::AcknowledgeConfirmation'];

coerce 'AcknowledgeConfirmation',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::StreamingPullResponse::AcknowledgeConfirmation'->new($_) };

declare 'RepeatedAcknowledgeConfirmation',
    as ArrayRef[AcknowledgeConfirmation()];

coerce 'RepeatedAcknowledgeConfirmation',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::StreamingPullResponse::AcknowledgeConfirmation'->new($_) } @$_ ] };

declare 'MapStringAcknowledgeConfirmation',
    as HashRef[AcknowledgeConfirmation()];

declare 'ModifyAckDeadlineConfirmation',
    as InstanceOf['Google::Pubsub::V1::Pubsub::StreamingPullResponse::ModifyAckDeadlineConfirmation'];

coerce 'ModifyAckDeadlineConfirmation',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::StreamingPullResponse::ModifyAckDeadlineConfirmation'->new($_) };

declare 'RepeatedModifyAckDeadlineConfirmation',
    as ArrayRef[ModifyAckDeadlineConfirmation()];

coerce 'RepeatedModifyAckDeadlineConfirmation',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::StreamingPullResponse::ModifyAckDeadlineConfirmation'->new($_) } @$_ ] };

declare 'MapStringModifyAckDeadlineConfirmation',
    as HashRef[ModifyAckDeadlineConfirmation()];

declare 'SubscriptionProperties',
    as InstanceOf['Google::Pubsub::V1::Pubsub::StreamingPullResponse::SubscriptionProperties'];

coerce 'SubscriptionProperties',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::StreamingPullResponse::SubscriptionProperties'->new($_) };

declare 'RepeatedSubscriptionProperties',
    as ArrayRef[SubscriptionProperties()];

coerce 'RepeatedSubscriptionProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::StreamingPullResponse::SubscriptionProperties'->new($_) } @$_ ] };

declare 'MapStringSubscriptionProperties',
    as HashRef[SubscriptionProperties()];

declare 'CreateSnapshotRequest',
    as InstanceOf['Google::Pubsub::V1::Pubsub::CreateSnapshotRequest'];

coerce 'CreateSnapshotRequest',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::CreateSnapshotRequest'->new($_) };

declare 'RepeatedCreateSnapshotRequest',
    as ArrayRef[CreateSnapshotRequest()];

coerce 'RepeatedCreateSnapshotRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::CreateSnapshotRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSnapshotRequest',
    as HashRef[CreateSnapshotRequest()];

declare 'LabelsEntry',
    as InstanceOf['Google::Pubsub::V1::Pubsub::CreateSnapshotRequest::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::CreateSnapshotRequest::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::CreateSnapshotRequest::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'TagsEntry',
    as InstanceOf['Google::Pubsub::V1::Pubsub::CreateSnapshotRequest::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::CreateSnapshotRequest::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::CreateSnapshotRequest::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

declare 'UpdateSnapshotRequest',
    as InstanceOf['Google::Pubsub::V1::Pubsub::UpdateSnapshotRequest'];

coerce 'UpdateSnapshotRequest',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::UpdateSnapshotRequest'->new($_) };

declare 'RepeatedUpdateSnapshotRequest',
    as ArrayRef[UpdateSnapshotRequest()];

coerce 'RepeatedUpdateSnapshotRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::UpdateSnapshotRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSnapshotRequest',
    as HashRef[UpdateSnapshotRequest()];

declare 'Snapshot',
    as InstanceOf['Google::Pubsub::V1::Pubsub::Snapshot'];

coerce 'Snapshot',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::Snapshot'->new($_) };

declare 'RepeatedSnapshot',
    as ArrayRef[Snapshot()];

coerce 'RepeatedSnapshot',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::Snapshot'->new($_) } @$_ ] };

declare 'MapStringSnapshot',
    as HashRef[Snapshot()];

declare 'LabelsEntry',
    as InstanceOf['Google::Pubsub::V1::Pubsub::Snapshot::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::Snapshot::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::Snapshot::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'GetSnapshotRequest',
    as InstanceOf['Google::Pubsub::V1::Pubsub::GetSnapshotRequest'];

coerce 'GetSnapshotRequest',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::GetSnapshotRequest'->new($_) };

declare 'RepeatedGetSnapshotRequest',
    as ArrayRef[GetSnapshotRequest()];

coerce 'RepeatedGetSnapshotRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::GetSnapshotRequest'->new($_) } @$_ ] };

declare 'MapStringGetSnapshotRequest',
    as HashRef[GetSnapshotRequest()];

declare 'ListSnapshotsRequest',
    as InstanceOf['Google::Pubsub::V1::Pubsub::ListSnapshotsRequest'];

coerce 'ListSnapshotsRequest',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::ListSnapshotsRequest'->new($_) };

declare 'RepeatedListSnapshotsRequest',
    as ArrayRef[ListSnapshotsRequest()];

coerce 'RepeatedListSnapshotsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::ListSnapshotsRequest'->new($_) } @$_ ] };

declare 'MapStringListSnapshotsRequest',
    as HashRef[ListSnapshotsRequest()];

declare 'ListSnapshotsResponse',
    as InstanceOf['Google::Pubsub::V1::Pubsub::ListSnapshotsResponse'];

coerce 'ListSnapshotsResponse',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::ListSnapshotsResponse'->new($_) };

declare 'RepeatedListSnapshotsResponse',
    as ArrayRef[ListSnapshotsResponse()];

coerce 'RepeatedListSnapshotsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::ListSnapshotsResponse'->new($_) } @$_ ] };

declare 'MapStringListSnapshotsResponse',
    as HashRef[ListSnapshotsResponse()];

declare 'DeleteSnapshotRequest',
    as InstanceOf['Google::Pubsub::V1::Pubsub::DeleteSnapshotRequest'];

coerce 'DeleteSnapshotRequest',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::DeleteSnapshotRequest'->new($_) };

declare 'RepeatedDeleteSnapshotRequest',
    as ArrayRef[DeleteSnapshotRequest()];

coerce 'RepeatedDeleteSnapshotRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::DeleteSnapshotRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSnapshotRequest',
    as HashRef[DeleteSnapshotRequest()];

declare 'SeekRequest',
    as InstanceOf['Google::Pubsub::V1::Pubsub::SeekRequest'];

coerce 'SeekRequest',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::SeekRequest'->new($_) };

declare 'RepeatedSeekRequest',
    as ArrayRef[SeekRequest()];

coerce 'RepeatedSeekRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::SeekRequest'->new($_) } @$_ ] };

declare 'MapStringSeekRequest',
    as HashRef[SeekRequest()];

declare 'SeekResponse',
    as InstanceOf['Google::Pubsub::V1::Pubsub::SeekResponse'];

coerce 'SeekResponse',
    from HashRef, via { 'Google::Pubsub::V1::Pubsub::SeekResponse'->new($_) };

declare 'RepeatedSeekResponse',
    as ArrayRef[SeekResponse()];

coerce 'RepeatedSeekResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1::Pubsub::SeekResponse'->new($_) } @$_ ] };

declare 'MapStringSeekResponse',
    as HashRef[SeekResponse()];

1;

__END__

=head1 NAME

Google::Pubsub::V1::Pubsub::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
