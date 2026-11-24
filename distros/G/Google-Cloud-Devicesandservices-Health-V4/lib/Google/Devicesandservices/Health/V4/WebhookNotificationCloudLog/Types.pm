package Google::Devicesandservices::Health::V4::WebhookNotificationCloudLog::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'WebhookNotificationCloudLog',
    as InstanceOf['Google::Devicesandservices::Health::V4::WebhookNotificationCloudLog::WebhookNotificationCloudLog'];

coerce 'WebhookNotificationCloudLog',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::WebhookNotificationCloudLog::WebhookNotificationCloudLog'->new($_) };

declare 'RepeatedWebhookNotificationCloudLog',
    as ArrayRef[WebhookNotificationCloudLog()];

coerce 'RepeatedWebhookNotificationCloudLog',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::WebhookNotificationCloudLog::WebhookNotificationCloudLog'->new($_) } @$_ ] };

declare 'MapStringWebhookNotificationCloudLog',
    as HashRef[WebhookNotificationCloudLog()];

1;

__END__

=head1 NAME

Google::Devicesandservices::Health::V4::WebhookNotificationCloudLog::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
