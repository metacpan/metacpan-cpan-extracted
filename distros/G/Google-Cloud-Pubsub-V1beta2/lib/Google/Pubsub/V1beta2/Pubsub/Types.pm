package Google::Pubsub::V1beta2::Pubsub::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Topic',
    as InstanceOf['Google::Pubsub::V1beta2::Pubsub::Topic'];

coerce 'Topic',
    from HashRef, via { 'Google::Pubsub::V1beta2::Pubsub::Topic'->new($_) };

declare 'RepeatedTopic',
    as ArrayRef[Topic()];

coerce 'RepeatedTopic',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1beta2::Pubsub::Topic'->new($_) } @$_ ] };

declare 'MapStringTopic',
    as HashRef[Topic()];

declare 'PubsubMessage',
    as InstanceOf['Google::Pubsub::V1beta2::Pubsub::PubsubMessage'];

coerce 'PubsubMessage',
    from HashRef, via { 'Google::Pubsub::V1beta2::Pubsub::PubsubMessage'->new($_) };

declare 'RepeatedPubsubMessage',
    as ArrayRef[PubsubMessage()];

coerce 'RepeatedPubsubMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1beta2::Pubsub::PubsubMessage'->new($_) } @$_ ] };

declare 'MapStringPubsubMessage',
    as HashRef[PubsubMessage()];

declare 'AttributesEntry',
    as InstanceOf['Google::Pubsub::V1beta2::Pubsub::PubsubMessage::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Pubsub::V1beta2::Pubsub::PubsubMessage::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1beta2::Pubsub::PubsubMessage::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

declare 'GetTopicRequest',
    as InstanceOf['Google::Pubsub::V1beta2::Pubsub::GetTopicRequest'];

coerce 'GetTopicRequest',
    from HashRef, via { 'Google::Pubsub::V1beta2::Pubsub::GetTopicRequest'->new($_) };

declare 'RepeatedGetTopicRequest',
    as ArrayRef[GetTopicRequest()];

coerce 'RepeatedGetTopicRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1beta2::Pubsub::GetTopicRequest'->new($_) } @$_ ] };

declare 'MapStringGetTopicRequest',
    as HashRef[GetTopicRequest()];

declare 'PublishRequest',
    as InstanceOf['Google::Pubsub::V1beta2::Pubsub::PublishRequest'];

coerce 'PublishRequest',
    from HashRef, via { 'Google::Pubsub::V1beta2::Pubsub::PublishRequest'->new($_) };

declare 'RepeatedPublishRequest',
    as ArrayRef[PublishRequest()];

coerce 'RepeatedPublishRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1beta2::Pubsub::PublishRequest'->new($_) } @$_ ] };

declare 'MapStringPublishRequest',
    as HashRef[PublishRequest()];

declare 'PublishResponse',
    as InstanceOf['Google::Pubsub::V1beta2::Pubsub::PublishResponse'];

coerce 'PublishResponse',
    from HashRef, via { 'Google::Pubsub::V1beta2::Pubsub::PublishResponse'->new($_) };

declare 'RepeatedPublishResponse',
    as ArrayRef[PublishResponse()];

coerce 'RepeatedPublishResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1beta2::Pubsub::PublishResponse'->new($_) } @$_ ] };

declare 'MapStringPublishResponse',
    as HashRef[PublishResponse()];

declare 'ListTopicsRequest',
    as InstanceOf['Google::Pubsub::V1beta2::Pubsub::ListTopicsRequest'];

coerce 'ListTopicsRequest',
    from HashRef, via { 'Google::Pubsub::V1beta2::Pubsub::ListTopicsRequest'->new($_) };

declare 'RepeatedListTopicsRequest',
    as ArrayRef[ListTopicsRequest()];

coerce 'RepeatedListTopicsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1beta2::Pubsub::ListTopicsRequest'->new($_) } @$_ ] };

declare 'MapStringListTopicsRequest',
    as HashRef[ListTopicsRequest()];

declare 'ListTopicsResponse',
    as InstanceOf['Google::Pubsub::V1beta2::Pubsub::ListTopicsResponse'];

coerce 'ListTopicsResponse',
    from HashRef, via { 'Google::Pubsub::V1beta2::Pubsub::ListTopicsResponse'->new($_) };

declare 'RepeatedListTopicsResponse',
    as ArrayRef[ListTopicsResponse()];

coerce 'RepeatedListTopicsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1beta2::Pubsub::ListTopicsResponse'->new($_) } @$_ ] };

declare 'MapStringListTopicsResponse',
    as HashRef[ListTopicsResponse()];

declare 'ListTopicSubscriptionsRequest',
    as InstanceOf['Google::Pubsub::V1beta2::Pubsub::ListTopicSubscriptionsRequest'];

coerce 'ListTopicSubscriptionsRequest',
    from HashRef, via { 'Google::Pubsub::V1beta2::Pubsub::ListTopicSubscriptionsRequest'->new($_) };

declare 'RepeatedListTopicSubscriptionsRequest',
    as ArrayRef[ListTopicSubscriptionsRequest()];

coerce 'RepeatedListTopicSubscriptionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1beta2::Pubsub::ListTopicSubscriptionsRequest'->new($_) } @$_ ] };

declare 'MapStringListTopicSubscriptionsRequest',
    as HashRef[ListTopicSubscriptionsRequest()];

declare 'ListTopicSubscriptionsResponse',
    as InstanceOf['Google::Pubsub::V1beta2::Pubsub::ListTopicSubscriptionsResponse'];

coerce 'ListTopicSubscriptionsResponse',
    from HashRef, via { 'Google::Pubsub::V1beta2::Pubsub::ListTopicSubscriptionsResponse'->new($_) };

declare 'RepeatedListTopicSubscriptionsResponse',
    as ArrayRef[ListTopicSubscriptionsResponse()];

coerce 'RepeatedListTopicSubscriptionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1beta2::Pubsub::ListTopicSubscriptionsResponse'->new($_) } @$_ ] };

declare 'MapStringListTopicSubscriptionsResponse',
    as HashRef[ListTopicSubscriptionsResponse()];

declare 'DeleteTopicRequest',
    as InstanceOf['Google::Pubsub::V1beta2::Pubsub::DeleteTopicRequest'];

coerce 'DeleteTopicRequest',
    from HashRef, via { 'Google::Pubsub::V1beta2::Pubsub::DeleteTopicRequest'->new($_) };

declare 'RepeatedDeleteTopicRequest',
    as ArrayRef[DeleteTopicRequest()];

coerce 'RepeatedDeleteTopicRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1beta2::Pubsub::DeleteTopicRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTopicRequest',
    as HashRef[DeleteTopicRequest()];

declare 'Subscription',
    as InstanceOf['Google::Pubsub::V1beta2::Pubsub::Subscription'];

coerce 'Subscription',
    from HashRef, via { 'Google::Pubsub::V1beta2::Pubsub::Subscription'->new($_) };

declare 'RepeatedSubscription',
    as ArrayRef[Subscription()];

coerce 'RepeatedSubscription',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1beta2::Pubsub::Subscription'->new($_) } @$_ ] };

declare 'MapStringSubscription',
    as HashRef[Subscription()];

declare 'PushConfig',
    as InstanceOf['Google::Pubsub::V1beta2::Pubsub::PushConfig'];

coerce 'PushConfig',
    from HashRef, via { 'Google::Pubsub::V1beta2::Pubsub::PushConfig'->new($_) };

declare 'RepeatedPushConfig',
    as ArrayRef[PushConfig()];

coerce 'RepeatedPushConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1beta2::Pubsub::PushConfig'->new($_) } @$_ ] };

declare 'MapStringPushConfig',
    as HashRef[PushConfig()];

declare 'AttributesEntry',
    as InstanceOf['Google::Pubsub::V1beta2::Pubsub::PushConfig::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Pubsub::V1beta2::Pubsub::PushConfig::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1beta2::Pubsub::PushConfig::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

declare 'ReceivedMessage',
    as InstanceOf['Google::Pubsub::V1beta2::Pubsub::ReceivedMessage'];

coerce 'ReceivedMessage',
    from HashRef, via { 'Google::Pubsub::V1beta2::Pubsub::ReceivedMessage'->new($_) };

declare 'RepeatedReceivedMessage',
    as ArrayRef[ReceivedMessage()];

coerce 'RepeatedReceivedMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1beta2::Pubsub::ReceivedMessage'->new($_) } @$_ ] };

declare 'MapStringReceivedMessage',
    as HashRef[ReceivedMessage()];

declare 'GetSubscriptionRequest',
    as InstanceOf['Google::Pubsub::V1beta2::Pubsub::GetSubscriptionRequest'];

coerce 'GetSubscriptionRequest',
    from HashRef, via { 'Google::Pubsub::V1beta2::Pubsub::GetSubscriptionRequest'->new($_) };

declare 'RepeatedGetSubscriptionRequest',
    as ArrayRef[GetSubscriptionRequest()];

coerce 'RepeatedGetSubscriptionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1beta2::Pubsub::GetSubscriptionRequest'->new($_) } @$_ ] };

declare 'MapStringGetSubscriptionRequest',
    as HashRef[GetSubscriptionRequest()];

declare 'ListSubscriptionsRequest',
    as InstanceOf['Google::Pubsub::V1beta2::Pubsub::ListSubscriptionsRequest'];

coerce 'ListSubscriptionsRequest',
    from HashRef, via { 'Google::Pubsub::V1beta2::Pubsub::ListSubscriptionsRequest'->new($_) };

declare 'RepeatedListSubscriptionsRequest',
    as ArrayRef[ListSubscriptionsRequest()];

coerce 'RepeatedListSubscriptionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1beta2::Pubsub::ListSubscriptionsRequest'->new($_) } @$_ ] };

declare 'MapStringListSubscriptionsRequest',
    as HashRef[ListSubscriptionsRequest()];

declare 'ListSubscriptionsResponse',
    as InstanceOf['Google::Pubsub::V1beta2::Pubsub::ListSubscriptionsResponse'];

coerce 'ListSubscriptionsResponse',
    from HashRef, via { 'Google::Pubsub::V1beta2::Pubsub::ListSubscriptionsResponse'->new($_) };

declare 'RepeatedListSubscriptionsResponse',
    as ArrayRef[ListSubscriptionsResponse()];

coerce 'RepeatedListSubscriptionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1beta2::Pubsub::ListSubscriptionsResponse'->new($_) } @$_ ] };

declare 'MapStringListSubscriptionsResponse',
    as HashRef[ListSubscriptionsResponse()];

declare 'DeleteSubscriptionRequest',
    as InstanceOf['Google::Pubsub::V1beta2::Pubsub::DeleteSubscriptionRequest'];

coerce 'DeleteSubscriptionRequest',
    from HashRef, via { 'Google::Pubsub::V1beta2::Pubsub::DeleteSubscriptionRequest'->new($_) };

declare 'RepeatedDeleteSubscriptionRequest',
    as ArrayRef[DeleteSubscriptionRequest()];

coerce 'RepeatedDeleteSubscriptionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1beta2::Pubsub::DeleteSubscriptionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSubscriptionRequest',
    as HashRef[DeleteSubscriptionRequest()];

declare 'ModifyPushConfigRequest',
    as InstanceOf['Google::Pubsub::V1beta2::Pubsub::ModifyPushConfigRequest'];

coerce 'ModifyPushConfigRequest',
    from HashRef, via { 'Google::Pubsub::V1beta2::Pubsub::ModifyPushConfigRequest'->new($_) };

declare 'RepeatedModifyPushConfigRequest',
    as ArrayRef[ModifyPushConfigRequest()];

coerce 'RepeatedModifyPushConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1beta2::Pubsub::ModifyPushConfigRequest'->new($_) } @$_ ] };

declare 'MapStringModifyPushConfigRequest',
    as HashRef[ModifyPushConfigRequest()];

declare 'PullRequest',
    as InstanceOf['Google::Pubsub::V1beta2::Pubsub::PullRequest'];

coerce 'PullRequest',
    from HashRef, via { 'Google::Pubsub::V1beta2::Pubsub::PullRequest'->new($_) };

declare 'RepeatedPullRequest',
    as ArrayRef[PullRequest()];

coerce 'RepeatedPullRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1beta2::Pubsub::PullRequest'->new($_) } @$_ ] };

declare 'MapStringPullRequest',
    as HashRef[PullRequest()];

declare 'PullResponse',
    as InstanceOf['Google::Pubsub::V1beta2::Pubsub::PullResponse'];

coerce 'PullResponse',
    from HashRef, via { 'Google::Pubsub::V1beta2::Pubsub::PullResponse'->new($_) };

declare 'RepeatedPullResponse',
    as ArrayRef[PullResponse()];

coerce 'RepeatedPullResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1beta2::Pubsub::PullResponse'->new($_) } @$_ ] };

declare 'MapStringPullResponse',
    as HashRef[PullResponse()];

declare 'ModifyAckDeadlineRequest',
    as InstanceOf['Google::Pubsub::V1beta2::Pubsub::ModifyAckDeadlineRequest'];

coerce 'ModifyAckDeadlineRequest',
    from HashRef, via { 'Google::Pubsub::V1beta2::Pubsub::ModifyAckDeadlineRequest'->new($_) };

declare 'RepeatedModifyAckDeadlineRequest',
    as ArrayRef[ModifyAckDeadlineRequest()];

coerce 'RepeatedModifyAckDeadlineRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1beta2::Pubsub::ModifyAckDeadlineRequest'->new($_) } @$_ ] };

declare 'MapStringModifyAckDeadlineRequest',
    as HashRef[ModifyAckDeadlineRequest()];

declare 'AcknowledgeRequest',
    as InstanceOf['Google::Pubsub::V1beta2::Pubsub::AcknowledgeRequest'];

coerce 'AcknowledgeRequest',
    from HashRef, via { 'Google::Pubsub::V1beta2::Pubsub::AcknowledgeRequest'->new($_) };

declare 'RepeatedAcknowledgeRequest',
    as ArrayRef[AcknowledgeRequest()];

coerce 'RepeatedAcknowledgeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Pubsub::V1beta2::Pubsub::AcknowledgeRequest'->new($_) } @$_ ] };

declare 'MapStringAcknowledgeRequest',
    as HashRef[AcknowledgeRequest()];

1;

__END__

=head1 NAME

Google::Pubsub::V1beta2::Pubsub::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
