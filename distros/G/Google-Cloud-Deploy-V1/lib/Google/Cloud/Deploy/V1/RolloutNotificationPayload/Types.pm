package Google::Cloud::Deploy::V1::RolloutNotificationPayload::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RolloutNotificationEvent',
    as InstanceOf['Google::Cloud::Deploy::V1::RolloutNotificationPayload::RolloutNotificationEvent'];

coerce 'RolloutNotificationEvent',
    from HashRef, via { 'Google::Cloud::Deploy::V1::RolloutNotificationPayload::RolloutNotificationEvent'->new($_) };

declare 'RepeatedRolloutNotificationEvent',
    as ArrayRef[RolloutNotificationEvent()];

coerce 'RepeatedRolloutNotificationEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::RolloutNotificationPayload::RolloutNotificationEvent'->new($_) } @$_ ] };

declare 'MapStringRolloutNotificationEvent',
    as HashRef[RolloutNotificationEvent()];

1;

__END__

=head1 NAME

Google::Cloud::Deploy::V1::RolloutNotificationPayload::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
