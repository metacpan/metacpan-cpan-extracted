package Google::Cloud::Securitycenter::V1::NotificationConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'NotificationConfig',
    as InstanceOf['Google::Cloud::Securitycenter::V1::NotificationConfig::NotificationConfig'];

coerce 'NotificationConfig',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::NotificationConfig::NotificationConfig'->new($_) };

declare 'RepeatedNotificationConfig',
    as ArrayRef[NotificationConfig()];

coerce 'RepeatedNotificationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::NotificationConfig::NotificationConfig'->new($_) } @$_ ] };

declare 'MapStringNotificationConfig',
    as HashRef[NotificationConfig()];

declare 'StreamingConfig',
    as InstanceOf['Google::Cloud::Securitycenter::V1::NotificationConfig::NotificationConfig::StreamingConfig'];

coerce 'StreamingConfig',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::NotificationConfig::NotificationConfig::StreamingConfig'->new($_) };

declare 'RepeatedStreamingConfig',
    as ArrayRef[StreamingConfig()];

coerce 'RepeatedStreamingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::NotificationConfig::NotificationConfig::StreamingConfig'->new($_) } @$_ ] };

declare 'MapStringStreamingConfig',
    as HashRef[StreamingConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1::NotificationConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
