package Google::Cloud::Securitycenter::V2::NotificationMessage::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'NotificationMessage',
    as InstanceOf['Google::Cloud::Securitycenter::V2::NotificationMessage::NotificationMessage'];

coerce 'NotificationMessage',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::NotificationMessage::NotificationMessage'->new($_) };

declare 'RepeatedNotificationMessage',
    as ArrayRef[NotificationMessage()];

coerce 'RepeatedNotificationMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::NotificationMessage::NotificationMessage'->new($_) } @$_ ] };

declare 'MapStringNotificationMessage',
    as HashRef[NotificationMessage()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V2::NotificationMessage::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
