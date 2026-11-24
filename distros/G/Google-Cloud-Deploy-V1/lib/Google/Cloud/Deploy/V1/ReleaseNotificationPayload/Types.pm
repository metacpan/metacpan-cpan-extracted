package Google::Cloud::Deploy::V1::ReleaseNotificationPayload::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ReleaseNotificationEvent',
    as InstanceOf['Google::Cloud::Deploy::V1::ReleaseNotificationPayload::ReleaseNotificationEvent'];

coerce 'ReleaseNotificationEvent',
    from HashRef, via { 'Google::Cloud::Deploy::V1::ReleaseNotificationPayload::ReleaseNotificationEvent'->new($_) };

declare 'RepeatedReleaseNotificationEvent',
    as ArrayRef[ReleaseNotificationEvent()];

coerce 'RepeatedReleaseNotificationEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::ReleaseNotificationPayload::ReleaseNotificationEvent'->new($_) } @$_ ] };

declare 'MapStringReleaseNotificationEvent',
    as HashRef[ReleaseNotificationEvent()];

1;

__END__

=head1 NAME

Google::Cloud::Deploy::V1::ReleaseNotificationPayload::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
