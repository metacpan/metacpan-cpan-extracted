package Google::Devicesandservices::Health::V4::DataSubscriptionService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateSubscriberRequest',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataSubscriptionService::CreateSubscriberRequest'];

coerce 'CreateSubscriberRequest',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::CreateSubscriberRequest'->new($_) };

declare 'RepeatedCreateSubscriberRequest',
    as ArrayRef[CreateSubscriberRequest()];

coerce 'RepeatedCreateSubscriberRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::CreateSubscriberRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSubscriberRequest',
    as HashRef[CreateSubscriberRequest()];

declare 'ListSubscribersRequest',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataSubscriptionService::ListSubscribersRequest'];

coerce 'ListSubscribersRequest',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::ListSubscribersRequest'->new($_) };

declare 'RepeatedListSubscribersRequest',
    as ArrayRef[ListSubscribersRequest()];

coerce 'RepeatedListSubscribersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::ListSubscribersRequest'->new($_) } @$_ ] };

declare 'MapStringListSubscribersRequest',
    as HashRef[ListSubscribersRequest()];

declare 'ListSubscribersResponse',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataSubscriptionService::ListSubscribersResponse'];

coerce 'ListSubscribersResponse',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::ListSubscribersResponse'->new($_) };

declare 'RepeatedListSubscribersResponse',
    as ArrayRef[ListSubscribersResponse()];

coerce 'RepeatedListSubscribersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::ListSubscribersResponse'->new($_) } @$_ ] };

declare 'MapStringListSubscribersResponse',
    as HashRef[ListSubscribersResponse()];

declare 'UpdateSubscriberRequest',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataSubscriptionService::UpdateSubscriberRequest'];

coerce 'UpdateSubscriberRequest',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::UpdateSubscriberRequest'->new($_) };

declare 'RepeatedUpdateSubscriberRequest',
    as ArrayRef[UpdateSubscriberRequest()];

coerce 'RepeatedUpdateSubscriberRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::UpdateSubscriberRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSubscriberRequest',
    as HashRef[UpdateSubscriberRequest()];

declare 'DeleteSubscriberRequest',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataSubscriptionService::DeleteSubscriberRequest'];

coerce 'DeleteSubscriberRequest',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::DeleteSubscriberRequest'->new($_) };

declare 'RepeatedDeleteSubscriberRequest',
    as ArrayRef[DeleteSubscriberRequest()];

coerce 'RepeatedDeleteSubscriberRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::DeleteSubscriberRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSubscriberRequest',
    as HashRef[DeleteSubscriberRequest()];

declare 'CreateSubscriptionRequest',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataSubscriptionService::CreateSubscriptionRequest'];

coerce 'CreateSubscriptionRequest',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::CreateSubscriptionRequest'->new($_) };

declare 'RepeatedCreateSubscriptionRequest',
    as ArrayRef[CreateSubscriptionRequest()];

coerce 'RepeatedCreateSubscriptionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::CreateSubscriptionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSubscriptionRequest',
    as HashRef[CreateSubscriptionRequest()];

declare 'ListSubscriptionsRequest',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataSubscriptionService::ListSubscriptionsRequest'];

coerce 'ListSubscriptionsRequest',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::ListSubscriptionsRequest'->new($_) };

declare 'RepeatedListSubscriptionsRequest',
    as ArrayRef[ListSubscriptionsRequest()];

coerce 'RepeatedListSubscriptionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::ListSubscriptionsRequest'->new($_) } @$_ ] };

declare 'MapStringListSubscriptionsRequest',
    as HashRef[ListSubscriptionsRequest()];

declare 'ListSubscriptionsResponse',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataSubscriptionService::ListSubscriptionsResponse'];

coerce 'ListSubscriptionsResponse',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::ListSubscriptionsResponse'->new($_) };

declare 'RepeatedListSubscriptionsResponse',
    as ArrayRef[ListSubscriptionsResponse()];

coerce 'RepeatedListSubscriptionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::ListSubscriptionsResponse'->new($_) } @$_ ] };

declare 'MapStringListSubscriptionsResponse',
    as HashRef[ListSubscriptionsResponse()];

declare 'UpdateSubscriptionRequest',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataSubscriptionService::UpdateSubscriptionRequest'];

coerce 'UpdateSubscriptionRequest',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::UpdateSubscriptionRequest'->new($_) };

declare 'RepeatedUpdateSubscriptionRequest',
    as ArrayRef[UpdateSubscriptionRequest()];

coerce 'RepeatedUpdateSubscriptionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::UpdateSubscriptionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSubscriptionRequest',
    as HashRef[UpdateSubscriptionRequest()];

declare 'DeleteSubscriptionRequest',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataSubscriptionService::DeleteSubscriptionRequest'];

coerce 'DeleteSubscriptionRequest',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::DeleteSubscriptionRequest'->new($_) };

declare 'RepeatedDeleteSubscriptionRequest',
    as ArrayRef[DeleteSubscriptionRequest()];

coerce 'RepeatedDeleteSubscriptionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::DeleteSubscriptionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSubscriptionRequest',
    as HashRef[DeleteSubscriptionRequest()];

declare 'Subscriber',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataSubscriptionService::Subscriber'];

coerce 'Subscriber',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::Subscriber'->new($_) };

declare 'RepeatedSubscriber',
    as ArrayRef[Subscriber()];

coerce 'RepeatedSubscriber',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::Subscriber'->new($_) } @$_ ] };

declare 'MapStringSubscriber',
    as HashRef[Subscriber()];

declare 'State',
    as (Int | Str);

declare 'Subscription',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataSubscriptionService::Subscription'];

coerce 'Subscription',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::Subscription'->new($_) };

declare 'RepeatedSubscription',
    as ArrayRef[Subscription()];

coerce 'RepeatedSubscription',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::Subscription'->new($_) } @$_ ] };

declare 'MapStringSubscription',
    as HashRef[Subscription()];

declare 'SubscriberConfig',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataSubscriptionService::SubscriberConfig'];

coerce 'SubscriberConfig',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::SubscriberConfig'->new($_) };

declare 'RepeatedSubscriberConfig',
    as ArrayRef[SubscriberConfig()];

coerce 'RepeatedSubscriberConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::SubscriberConfig'->new($_) } @$_ ] };

declare 'MapStringSubscriberConfig',
    as HashRef[SubscriberConfig()];

declare 'SubscriptionCreatePolicy',
    as (Int | Str);

declare 'EndpointAuthorization',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataSubscriptionService::EndpointAuthorization'];

coerce 'EndpointAuthorization',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::EndpointAuthorization'->new($_) };

declare 'RepeatedEndpointAuthorization',
    as ArrayRef[EndpointAuthorization()];

coerce 'RepeatedEndpointAuthorization',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::EndpointAuthorization'->new($_) } @$_ ] };

declare 'MapStringEndpointAuthorization',
    as HashRef[EndpointAuthorization()];

declare 'CreateSubscriberPayload',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataSubscriptionService::CreateSubscriberPayload'];

coerce 'CreateSubscriberPayload',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::CreateSubscriberPayload'->new($_) };

declare 'RepeatedCreateSubscriberPayload',
    as ArrayRef[CreateSubscriberPayload()];

coerce 'RepeatedCreateSubscriberPayload',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::CreateSubscriberPayload'->new($_) } @$_ ] };

declare 'MapStringCreateSubscriberPayload',
    as HashRef[CreateSubscriberPayload()];

declare 'CreateSubscriptionPayload',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataSubscriptionService::CreateSubscriptionPayload'];

coerce 'CreateSubscriptionPayload',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::CreateSubscriptionPayload'->new($_) };

declare 'RepeatedCreateSubscriptionPayload',
    as ArrayRef[CreateSubscriptionPayload()];

coerce 'RepeatedCreateSubscriptionPayload',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::CreateSubscriptionPayload'->new($_) } @$_ ] };

declare 'MapStringCreateSubscriptionPayload',
    as HashRef[CreateSubscriptionPayload()];

declare 'CreateSubscriberMetadata',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataSubscriptionService::CreateSubscriberMetadata'];

coerce 'CreateSubscriberMetadata',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::CreateSubscriberMetadata'->new($_) };

declare 'RepeatedCreateSubscriberMetadata',
    as ArrayRef[CreateSubscriberMetadata()];

coerce 'RepeatedCreateSubscriberMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::CreateSubscriberMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateSubscriberMetadata',
    as HashRef[CreateSubscriberMetadata()];

declare 'UpdateSubscriberMetadata',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataSubscriptionService::UpdateSubscriberMetadata'];

coerce 'UpdateSubscriberMetadata',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::UpdateSubscriberMetadata'->new($_) };

declare 'RepeatedUpdateSubscriberMetadata',
    as ArrayRef[UpdateSubscriberMetadata()];

coerce 'RepeatedUpdateSubscriberMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::UpdateSubscriberMetadata'->new($_) } @$_ ] };

declare 'MapStringUpdateSubscriberMetadata',
    as HashRef[UpdateSubscriberMetadata()];

declare 'DeleteSubscriberMetadata',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataSubscriptionService::DeleteSubscriberMetadata'];

coerce 'DeleteSubscriberMetadata',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::DeleteSubscriberMetadata'->new($_) };

declare 'RepeatedDeleteSubscriberMetadata',
    as ArrayRef[DeleteSubscriberMetadata()];

coerce 'RepeatedDeleteSubscriberMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataSubscriptionService::DeleteSubscriberMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteSubscriberMetadata',
    as HashRef[DeleteSubscriberMetadata()];

1;

__END__

=head1 NAME

Google::Devicesandservices::Health::V4::DataSubscriptionService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
