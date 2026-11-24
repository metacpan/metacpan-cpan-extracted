package Google::Cloud::Deploy::V1::JobrunNotificationPayload::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'JobRunNotificationEvent',
    as InstanceOf['Google::Cloud::Deploy::V1::JobrunNotificationPayload::JobRunNotificationEvent'];

coerce 'JobRunNotificationEvent',
    from HashRef, via { 'Google::Cloud::Deploy::V1::JobrunNotificationPayload::JobRunNotificationEvent'->new($_) };

declare 'RepeatedJobRunNotificationEvent',
    as ArrayRef[JobRunNotificationEvent()];

coerce 'RepeatedJobRunNotificationEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::JobrunNotificationPayload::JobRunNotificationEvent'->new($_) } @$_ ] };

declare 'MapStringJobRunNotificationEvent',
    as HashRef[JobRunNotificationEvent()];

1;

__END__

=head1 NAME

Google::Cloud::Deploy::V1::JobrunNotificationPayload::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
