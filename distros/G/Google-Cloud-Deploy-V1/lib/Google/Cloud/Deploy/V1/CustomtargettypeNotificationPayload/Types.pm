package Google::Cloud::Deploy::V1::CustomtargettypeNotificationPayload::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CustomTargetTypeNotificationEvent',
    as InstanceOf['Google::Cloud::Deploy::V1::CustomtargettypeNotificationPayload::CustomTargetTypeNotificationEvent'];

coerce 'CustomTargetTypeNotificationEvent',
    from HashRef, via { 'Google::Cloud::Deploy::V1::CustomtargettypeNotificationPayload::CustomTargetTypeNotificationEvent'->new($_) };

declare 'RepeatedCustomTargetTypeNotificationEvent',
    as ArrayRef[CustomTargetTypeNotificationEvent()];

coerce 'RepeatedCustomTargetTypeNotificationEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::CustomtargettypeNotificationPayload::CustomTargetTypeNotificationEvent'->new($_) } @$_ ] };

declare 'MapStringCustomTargetTypeNotificationEvent',
    as HashRef[CustomTargetTypeNotificationEvent()];

1;

__END__

=head1 NAME

Google::Cloud::Deploy::V1::CustomtargettypeNotificationPayload::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
