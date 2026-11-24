package Google::Cloud::Pubsublite::V1::Admin::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateTopicRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Admin::CreateTopicRequest'];

coerce 'CreateTopicRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Admin::CreateTopicRequest'->new($_) };

declare 'RepeatedCreateTopicRequest',
    as ArrayRef[CreateTopicRequest()];

coerce 'RepeatedCreateTopicRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Admin::CreateTopicRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTopicRequest',
    as HashRef[CreateTopicRequest()];

declare 'GetTopicRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Admin::GetTopicRequest'];

coerce 'GetTopicRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Admin::GetTopicRequest'->new($_) };

declare 'RepeatedGetTopicRequest',
    as ArrayRef[GetTopicRequest()];

coerce 'RepeatedGetTopicRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Admin::GetTopicRequest'->new($_) } @$_ ] };

declare 'MapStringGetTopicRequest',
    as HashRef[GetTopicRequest()];

declare 'GetTopicPartitionsRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Admin::GetTopicPartitionsRequest'];

coerce 'GetTopicPartitionsRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Admin::GetTopicPartitionsRequest'->new($_) };

declare 'RepeatedGetTopicPartitionsRequest',
    as ArrayRef[GetTopicPartitionsRequest()];

coerce 'RepeatedGetTopicPartitionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Admin::GetTopicPartitionsRequest'->new($_) } @$_ ] };

declare 'MapStringGetTopicPartitionsRequest',
    as HashRef[GetTopicPartitionsRequest()];

declare 'TopicPartitions',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Admin::TopicPartitions'];

coerce 'TopicPartitions',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Admin::TopicPartitions'->new($_) };

declare 'RepeatedTopicPartitions',
    as ArrayRef[TopicPartitions()];

coerce 'RepeatedTopicPartitions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Admin::TopicPartitions'->new($_) } @$_ ] };

declare 'MapStringTopicPartitions',
    as HashRef[TopicPartitions()];

declare 'ListTopicsRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Admin::ListTopicsRequest'];

coerce 'ListTopicsRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Admin::ListTopicsRequest'->new($_) };

declare 'RepeatedListTopicsRequest',
    as ArrayRef[ListTopicsRequest()];

coerce 'RepeatedListTopicsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Admin::ListTopicsRequest'->new($_) } @$_ ] };

declare 'MapStringListTopicsRequest',
    as HashRef[ListTopicsRequest()];

declare 'ListTopicsResponse',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Admin::ListTopicsResponse'];

coerce 'ListTopicsResponse',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Admin::ListTopicsResponse'->new($_) };

declare 'RepeatedListTopicsResponse',
    as ArrayRef[ListTopicsResponse()];

coerce 'RepeatedListTopicsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Admin::ListTopicsResponse'->new($_) } @$_ ] };

declare 'MapStringListTopicsResponse',
    as HashRef[ListTopicsResponse()];

declare 'UpdateTopicRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Admin::UpdateTopicRequest'];

coerce 'UpdateTopicRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Admin::UpdateTopicRequest'->new($_) };

declare 'RepeatedUpdateTopicRequest',
    as ArrayRef[UpdateTopicRequest()];

coerce 'RepeatedUpdateTopicRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Admin::UpdateTopicRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTopicRequest',
    as HashRef[UpdateTopicRequest()];

declare 'DeleteTopicRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Admin::DeleteTopicRequest'];

coerce 'DeleteTopicRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Admin::DeleteTopicRequest'->new($_) };

declare 'RepeatedDeleteTopicRequest',
    as ArrayRef[DeleteTopicRequest()];

coerce 'RepeatedDeleteTopicRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Admin::DeleteTopicRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTopicRequest',
    as HashRef[DeleteTopicRequest()];

declare 'ListTopicSubscriptionsRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Admin::ListTopicSubscriptionsRequest'];

coerce 'ListTopicSubscriptionsRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Admin::ListTopicSubscriptionsRequest'->new($_) };

declare 'RepeatedListTopicSubscriptionsRequest',
    as ArrayRef[ListTopicSubscriptionsRequest()];

coerce 'RepeatedListTopicSubscriptionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Admin::ListTopicSubscriptionsRequest'->new($_) } @$_ ] };

declare 'MapStringListTopicSubscriptionsRequest',
    as HashRef[ListTopicSubscriptionsRequest()];

declare 'ListTopicSubscriptionsResponse',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Admin::ListTopicSubscriptionsResponse'];

coerce 'ListTopicSubscriptionsResponse',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Admin::ListTopicSubscriptionsResponse'->new($_) };

declare 'RepeatedListTopicSubscriptionsResponse',
    as ArrayRef[ListTopicSubscriptionsResponse()];

coerce 'RepeatedListTopicSubscriptionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Admin::ListTopicSubscriptionsResponse'->new($_) } @$_ ] };

declare 'MapStringListTopicSubscriptionsResponse',
    as HashRef[ListTopicSubscriptionsResponse()];

declare 'CreateSubscriptionRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Admin::CreateSubscriptionRequest'];

coerce 'CreateSubscriptionRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Admin::CreateSubscriptionRequest'->new($_) };

declare 'RepeatedCreateSubscriptionRequest',
    as ArrayRef[CreateSubscriptionRequest()];

coerce 'RepeatedCreateSubscriptionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Admin::CreateSubscriptionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSubscriptionRequest',
    as HashRef[CreateSubscriptionRequest()];

declare 'GetSubscriptionRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Admin::GetSubscriptionRequest'];

coerce 'GetSubscriptionRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Admin::GetSubscriptionRequest'->new($_) };

declare 'RepeatedGetSubscriptionRequest',
    as ArrayRef[GetSubscriptionRequest()];

coerce 'RepeatedGetSubscriptionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Admin::GetSubscriptionRequest'->new($_) } @$_ ] };

declare 'MapStringGetSubscriptionRequest',
    as HashRef[GetSubscriptionRequest()];

declare 'ListSubscriptionsRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Admin::ListSubscriptionsRequest'];

coerce 'ListSubscriptionsRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Admin::ListSubscriptionsRequest'->new($_) };

declare 'RepeatedListSubscriptionsRequest',
    as ArrayRef[ListSubscriptionsRequest()];

coerce 'RepeatedListSubscriptionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Admin::ListSubscriptionsRequest'->new($_) } @$_ ] };

declare 'MapStringListSubscriptionsRequest',
    as HashRef[ListSubscriptionsRequest()];

declare 'ListSubscriptionsResponse',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Admin::ListSubscriptionsResponse'];

coerce 'ListSubscriptionsResponse',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Admin::ListSubscriptionsResponse'->new($_) };

declare 'RepeatedListSubscriptionsResponse',
    as ArrayRef[ListSubscriptionsResponse()];

coerce 'RepeatedListSubscriptionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Admin::ListSubscriptionsResponse'->new($_) } @$_ ] };

declare 'MapStringListSubscriptionsResponse',
    as HashRef[ListSubscriptionsResponse()];

declare 'UpdateSubscriptionRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Admin::UpdateSubscriptionRequest'];

coerce 'UpdateSubscriptionRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Admin::UpdateSubscriptionRequest'->new($_) };

declare 'RepeatedUpdateSubscriptionRequest',
    as ArrayRef[UpdateSubscriptionRequest()];

coerce 'RepeatedUpdateSubscriptionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Admin::UpdateSubscriptionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSubscriptionRequest',
    as HashRef[UpdateSubscriptionRequest()];

declare 'DeleteSubscriptionRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Admin::DeleteSubscriptionRequest'];

coerce 'DeleteSubscriptionRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Admin::DeleteSubscriptionRequest'->new($_) };

declare 'RepeatedDeleteSubscriptionRequest',
    as ArrayRef[DeleteSubscriptionRequest()];

coerce 'RepeatedDeleteSubscriptionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Admin::DeleteSubscriptionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSubscriptionRequest',
    as HashRef[DeleteSubscriptionRequest()];

declare 'SeekSubscriptionRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Admin::SeekSubscriptionRequest'];

coerce 'SeekSubscriptionRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Admin::SeekSubscriptionRequest'->new($_) };

declare 'RepeatedSeekSubscriptionRequest',
    as ArrayRef[SeekSubscriptionRequest()];

coerce 'RepeatedSeekSubscriptionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Admin::SeekSubscriptionRequest'->new($_) } @$_ ] };

declare 'MapStringSeekSubscriptionRequest',
    as HashRef[SeekSubscriptionRequest()];

declare 'NamedTarget',
    as (Int | Str);

declare 'SeekSubscriptionResponse',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Admin::SeekSubscriptionResponse'];

coerce 'SeekSubscriptionResponse',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Admin::SeekSubscriptionResponse'->new($_) };

declare 'RepeatedSeekSubscriptionResponse',
    as ArrayRef[SeekSubscriptionResponse()];

coerce 'RepeatedSeekSubscriptionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Admin::SeekSubscriptionResponse'->new($_) } @$_ ] };

declare 'MapStringSeekSubscriptionResponse',
    as HashRef[SeekSubscriptionResponse()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Admin::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Admin::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Admin::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'CreateReservationRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Admin::CreateReservationRequest'];

coerce 'CreateReservationRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Admin::CreateReservationRequest'->new($_) };

declare 'RepeatedCreateReservationRequest',
    as ArrayRef[CreateReservationRequest()];

coerce 'RepeatedCreateReservationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Admin::CreateReservationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateReservationRequest',
    as HashRef[CreateReservationRequest()];

declare 'GetReservationRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Admin::GetReservationRequest'];

coerce 'GetReservationRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Admin::GetReservationRequest'->new($_) };

declare 'RepeatedGetReservationRequest',
    as ArrayRef[GetReservationRequest()];

coerce 'RepeatedGetReservationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Admin::GetReservationRequest'->new($_) } @$_ ] };

declare 'MapStringGetReservationRequest',
    as HashRef[GetReservationRequest()];

declare 'ListReservationsRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Admin::ListReservationsRequest'];

coerce 'ListReservationsRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Admin::ListReservationsRequest'->new($_) };

declare 'RepeatedListReservationsRequest',
    as ArrayRef[ListReservationsRequest()];

coerce 'RepeatedListReservationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Admin::ListReservationsRequest'->new($_) } @$_ ] };

declare 'MapStringListReservationsRequest',
    as HashRef[ListReservationsRequest()];

declare 'ListReservationsResponse',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Admin::ListReservationsResponse'];

coerce 'ListReservationsResponse',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Admin::ListReservationsResponse'->new($_) };

declare 'RepeatedListReservationsResponse',
    as ArrayRef[ListReservationsResponse()];

coerce 'RepeatedListReservationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Admin::ListReservationsResponse'->new($_) } @$_ ] };

declare 'MapStringListReservationsResponse',
    as HashRef[ListReservationsResponse()];

declare 'UpdateReservationRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Admin::UpdateReservationRequest'];

coerce 'UpdateReservationRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Admin::UpdateReservationRequest'->new($_) };

declare 'RepeatedUpdateReservationRequest',
    as ArrayRef[UpdateReservationRequest()];

coerce 'RepeatedUpdateReservationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Admin::UpdateReservationRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateReservationRequest',
    as HashRef[UpdateReservationRequest()];

declare 'DeleteReservationRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Admin::DeleteReservationRequest'];

coerce 'DeleteReservationRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Admin::DeleteReservationRequest'->new($_) };

declare 'RepeatedDeleteReservationRequest',
    as ArrayRef[DeleteReservationRequest()];

coerce 'RepeatedDeleteReservationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Admin::DeleteReservationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteReservationRequest',
    as HashRef[DeleteReservationRequest()];

declare 'ListReservationTopicsRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Admin::ListReservationTopicsRequest'];

coerce 'ListReservationTopicsRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Admin::ListReservationTopicsRequest'->new($_) };

declare 'RepeatedListReservationTopicsRequest',
    as ArrayRef[ListReservationTopicsRequest()];

coerce 'RepeatedListReservationTopicsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Admin::ListReservationTopicsRequest'->new($_) } @$_ ] };

declare 'MapStringListReservationTopicsRequest',
    as HashRef[ListReservationTopicsRequest()];

declare 'ListReservationTopicsResponse',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Admin::ListReservationTopicsResponse'];

coerce 'ListReservationTopicsResponse',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Admin::ListReservationTopicsResponse'->new($_) };

declare 'RepeatedListReservationTopicsResponse',
    as ArrayRef[ListReservationTopicsResponse()];

coerce 'RepeatedListReservationTopicsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Admin::ListReservationTopicsResponse'->new($_) } @$_ ] };

declare 'MapStringListReservationTopicsResponse',
    as HashRef[ListReservationTopicsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Pubsublite::V1::Admin::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
