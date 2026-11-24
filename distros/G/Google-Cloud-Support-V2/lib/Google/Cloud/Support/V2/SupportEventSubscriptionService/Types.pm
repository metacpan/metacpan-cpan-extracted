package Google::Cloud::Support::V2::SupportEventSubscriptionService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateSupportEventSubscriptionRequest',
    as InstanceOf['Google::Cloud::Support::V2::SupportEventSubscriptionService::CreateSupportEventSubscriptionRequest'];

coerce 'CreateSupportEventSubscriptionRequest',
    from HashRef, via { 'Google::Cloud::Support::V2::SupportEventSubscriptionService::CreateSupportEventSubscriptionRequest'->new($_) };

declare 'RepeatedCreateSupportEventSubscriptionRequest',
    as ArrayRef[CreateSupportEventSubscriptionRequest()];

coerce 'RepeatedCreateSupportEventSubscriptionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2::SupportEventSubscriptionService::CreateSupportEventSubscriptionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSupportEventSubscriptionRequest',
    as HashRef[CreateSupportEventSubscriptionRequest()];

declare 'GetSupportEventSubscriptionRequest',
    as InstanceOf['Google::Cloud::Support::V2::SupportEventSubscriptionService::GetSupportEventSubscriptionRequest'];

coerce 'GetSupportEventSubscriptionRequest',
    from HashRef, via { 'Google::Cloud::Support::V2::SupportEventSubscriptionService::GetSupportEventSubscriptionRequest'->new($_) };

declare 'RepeatedGetSupportEventSubscriptionRequest',
    as ArrayRef[GetSupportEventSubscriptionRequest()];

coerce 'RepeatedGetSupportEventSubscriptionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2::SupportEventSubscriptionService::GetSupportEventSubscriptionRequest'->new($_) } @$_ ] };

declare 'MapStringGetSupportEventSubscriptionRequest',
    as HashRef[GetSupportEventSubscriptionRequest()];

declare 'ListSupportEventSubscriptionsRequest',
    as InstanceOf['Google::Cloud::Support::V2::SupportEventSubscriptionService::ListSupportEventSubscriptionsRequest'];

coerce 'ListSupportEventSubscriptionsRequest',
    from HashRef, via { 'Google::Cloud::Support::V2::SupportEventSubscriptionService::ListSupportEventSubscriptionsRequest'->new($_) };

declare 'RepeatedListSupportEventSubscriptionsRequest',
    as ArrayRef[ListSupportEventSubscriptionsRequest()];

coerce 'RepeatedListSupportEventSubscriptionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2::SupportEventSubscriptionService::ListSupportEventSubscriptionsRequest'->new($_) } @$_ ] };

declare 'MapStringListSupportEventSubscriptionsRequest',
    as HashRef[ListSupportEventSubscriptionsRequest()];

declare 'ListSupportEventSubscriptionsResponse',
    as InstanceOf['Google::Cloud::Support::V2::SupportEventSubscriptionService::ListSupportEventSubscriptionsResponse'];

coerce 'ListSupportEventSubscriptionsResponse',
    from HashRef, via { 'Google::Cloud::Support::V2::SupportEventSubscriptionService::ListSupportEventSubscriptionsResponse'->new($_) };

declare 'RepeatedListSupportEventSubscriptionsResponse',
    as ArrayRef[ListSupportEventSubscriptionsResponse()];

coerce 'RepeatedListSupportEventSubscriptionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2::SupportEventSubscriptionService::ListSupportEventSubscriptionsResponse'->new($_) } @$_ ] };

declare 'MapStringListSupportEventSubscriptionsResponse',
    as HashRef[ListSupportEventSubscriptionsResponse()];

declare 'UpdateSupportEventSubscriptionRequest',
    as InstanceOf['Google::Cloud::Support::V2::SupportEventSubscriptionService::UpdateSupportEventSubscriptionRequest'];

coerce 'UpdateSupportEventSubscriptionRequest',
    from HashRef, via { 'Google::Cloud::Support::V2::SupportEventSubscriptionService::UpdateSupportEventSubscriptionRequest'->new($_) };

declare 'RepeatedUpdateSupportEventSubscriptionRequest',
    as ArrayRef[UpdateSupportEventSubscriptionRequest()];

coerce 'RepeatedUpdateSupportEventSubscriptionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2::SupportEventSubscriptionService::UpdateSupportEventSubscriptionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSupportEventSubscriptionRequest',
    as HashRef[UpdateSupportEventSubscriptionRequest()];

declare 'DeleteSupportEventSubscriptionRequest',
    as InstanceOf['Google::Cloud::Support::V2::SupportEventSubscriptionService::DeleteSupportEventSubscriptionRequest'];

coerce 'DeleteSupportEventSubscriptionRequest',
    from HashRef, via { 'Google::Cloud::Support::V2::SupportEventSubscriptionService::DeleteSupportEventSubscriptionRequest'->new($_) };

declare 'RepeatedDeleteSupportEventSubscriptionRequest',
    as ArrayRef[DeleteSupportEventSubscriptionRequest()];

coerce 'RepeatedDeleteSupportEventSubscriptionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2::SupportEventSubscriptionService::DeleteSupportEventSubscriptionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSupportEventSubscriptionRequest',
    as HashRef[DeleteSupportEventSubscriptionRequest()];

declare 'UndeleteSupportEventSubscriptionRequest',
    as InstanceOf['Google::Cloud::Support::V2::SupportEventSubscriptionService::UndeleteSupportEventSubscriptionRequest'];

coerce 'UndeleteSupportEventSubscriptionRequest',
    from HashRef, via { 'Google::Cloud::Support::V2::SupportEventSubscriptionService::UndeleteSupportEventSubscriptionRequest'->new($_) };

declare 'RepeatedUndeleteSupportEventSubscriptionRequest',
    as ArrayRef[UndeleteSupportEventSubscriptionRequest()];

coerce 'RepeatedUndeleteSupportEventSubscriptionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2::SupportEventSubscriptionService::UndeleteSupportEventSubscriptionRequest'->new($_) } @$_ ] };

declare 'MapStringUndeleteSupportEventSubscriptionRequest',
    as HashRef[UndeleteSupportEventSubscriptionRequest()];

declare 'ExpungeSupportEventSubscriptionRequest',
    as InstanceOf['Google::Cloud::Support::V2::SupportEventSubscriptionService::ExpungeSupportEventSubscriptionRequest'];

coerce 'ExpungeSupportEventSubscriptionRequest',
    from HashRef, via { 'Google::Cloud::Support::V2::SupportEventSubscriptionService::ExpungeSupportEventSubscriptionRequest'->new($_) };

declare 'RepeatedExpungeSupportEventSubscriptionRequest',
    as ArrayRef[ExpungeSupportEventSubscriptionRequest()];

coerce 'RepeatedExpungeSupportEventSubscriptionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2::SupportEventSubscriptionService::ExpungeSupportEventSubscriptionRequest'->new($_) } @$_ ] };

declare 'MapStringExpungeSupportEventSubscriptionRequest',
    as HashRef[ExpungeSupportEventSubscriptionRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Support::V2::SupportEventSubscriptionService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
