package Google::Cloud::Deploy::V1::TargetNotificationPayload::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TargetNotificationEvent',
    as InstanceOf['Google::Cloud::Deploy::V1::TargetNotificationPayload::TargetNotificationEvent'];

coerce 'TargetNotificationEvent',
    from HashRef, via { 'Google::Cloud::Deploy::V1::TargetNotificationPayload::TargetNotificationEvent'->new($_) };

declare 'RepeatedTargetNotificationEvent',
    as ArrayRef[TargetNotificationEvent()];

coerce 'RepeatedTargetNotificationEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::TargetNotificationPayload::TargetNotificationEvent'->new($_) } @$_ ] };

declare 'MapStringTargetNotificationEvent',
    as HashRef[TargetNotificationEvent()];

1;

__END__

=head1 NAME

Google::Cloud::Deploy::V1::TargetNotificationPayload::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
