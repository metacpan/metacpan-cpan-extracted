package Google::Cloud::Deploy::V1::DeliverypipelineNotificationPayload::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DeliveryPipelineNotificationEvent',
    as InstanceOf['Google::Cloud::Deploy::V1::DeliverypipelineNotificationPayload::DeliveryPipelineNotificationEvent'];

coerce 'DeliveryPipelineNotificationEvent',
    from HashRef, via { 'Google::Cloud::Deploy::V1::DeliverypipelineNotificationPayload::DeliveryPipelineNotificationEvent'->new($_) };

declare 'RepeatedDeliveryPipelineNotificationEvent',
    as ArrayRef[DeliveryPipelineNotificationEvent()];

coerce 'RepeatedDeliveryPipelineNotificationEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::DeliverypipelineNotificationPayload::DeliveryPipelineNotificationEvent'->new($_) } @$_ ] };

declare 'MapStringDeliveryPipelineNotificationEvent',
    as HashRef[DeliveryPipelineNotificationEvent()];

1;

__END__

=head1 NAME

Google::Cloud::Deploy::V1::DeliverypipelineNotificationPayload::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
