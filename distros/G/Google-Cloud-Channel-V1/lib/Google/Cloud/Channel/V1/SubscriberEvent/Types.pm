package Google::Cloud::Channel::V1::SubscriberEvent::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CustomerEvent',
    as InstanceOf['Google::Cloud::Channel::V1::SubscriberEvent::CustomerEvent'];

coerce 'CustomerEvent',
    from HashRef, via { 'Google::Cloud::Channel::V1::SubscriberEvent::CustomerEvent'->new($_) };

declare 'RepeatedCustomerEvent',
    as ArrayRef[CustomerEvent()];

coerce 'RepeatedCustomerEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::SubscriberEvent::CustomerEvent'->new($_) } @$_ ] };

declare 'MapStringCustomerEvent',
    as HashRef[CustomerEvent()];

declare 'Type',
    as (Int | Str);

declare 'EntitlementEvent',
    as InstanceOf['Google::Cloud::Channel::V1::SubscriberEvent::EntitlementEvent'];

coerce 'EntitlementEvent',
    from HashRef, via { 'Google::Cloud::Channel::V1::SubscriberEvent::EntitlementEvent'->new($_) };

declare 'RepeatedEntitlementEvent',
    as ArrayRef[EntitlementEvent()];

coerce 'RepeatedEntitlementEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::SubscriberEvent::EntitlementEvent'->new($_) } @$_ ] };

declare 'MapStringEntitlementEvent',
    as HashRef[EntitlementEvent()];

declare 'Type',
    as (Int | Str);

declare 'SubscriberEvent',
    as InstanceOf['Google::Cloud::Channel::V1::SubscriberEvent::SubscriberEvent'];

coerce 'SubscriberEvent',
    from HashRef, via { 'Google::Cloud::Channel::V1::SubscriberEvent::SubscriberEvent'->new($_) };

declare 'RepeatedSubscriberEvent',
    as ArrayRef[SubscriberEvent()];

coerce 'RepeatedSubscriberEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::SubscriberEvent::SubscriberEvent'->new($_) } @$_ ] };

declare 'MapStringSubscriberEvent',
    as HashRef[SubscriberEvent()];

1;

__END__

=head1 NAME

Google::Cloud::Channel::V1::SubscriberEvent::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
