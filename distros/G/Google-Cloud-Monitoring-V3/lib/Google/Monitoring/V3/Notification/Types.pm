package Google::Monitoring::V3::Notification::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'NotificationChannelDescriptor',
    as InstanceOf['Google::Monitoring::V3::Notification::NotificationChannelDescriptor'];

coerce 'NotificationChannelDescriptor',
    from HashRef, via { 'Google::Monitoring::V3::Notification::NotificationChannelDescriptor'->new($_) };

declare 'RepeatedNotificationChannelDescriptor',
    as ArrayRef[NotificationChannelDescriptor()];

coerce 'RepeatedNotificationChannelDescriptor',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Notification::NotificationChannelDescriptor'->new($_) } @$_ ] };

declare 'MapStringNotificationChannelDescriptor',
    as HashRef[NotificationChannelDescriptor()];

declare 'NotificationChannel',
    as InstanceOf['Google::Monitoring::V3::Notification::NotificationChannel'];

coerce 'NotificationChannel',
    from HashRef, via { 'Google::Monitoring::V3::Notification::NotificationChannel'->new($_) };

declare 'RepeatedNotificationChannel',
    as ArrayRef[NotificationChannel()];

coerce 'RepeatedNotificationChannel',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Notification::NotificationChannel'->new($_) } @$_ ] };

declare 'MapStringNotificationChannel',
    as HashRef[NotificationChannel()];

declare 'VerificationStatus',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Monitoring::V3::Notification::NotificationChannel::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Monitoring::V3::Notification::NotificationChannel::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Notification::NotificationChannel::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'UserLabelsEntry',
    as InstanceOf['Google::Monitoring::V3::Notification::NotificationChannel::UserLabelsEntry'];

coerce 'UserLabelsEntry',
    from HashRef, via { 'Google::Monitoring::V3::Notification::NotificationChannel::UserLabelsEntry'->new($_) };

declare 'RepeatedUserLabelsEntry',
    as ArrayRef[UserLabelsEntry()];

coerce 'RepeatedUserLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Notification::NotificationChannel::UserLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringUserLabelsEntry',
    as HashRef[UserLabelsEntry()];

1;

__END__

=head1 NAME

Google::Monitoring::V3::Notification::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
