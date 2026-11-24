package Google::Cloud::Eventarc::Publishing::V1::Publisher::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PublishChannelConnectionEventsRequest',
    as InstanceOf['Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishChannelConnectionEventsRequest'];

coerce 'PublishChannelConnectionEventsRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishChannelConnectionEventsRequest'->new($_) };

declare 'RepeatedPublishChannelConnectionEventsRequest',
    as ArrayRef[PublishChannelConnectionEventsRequest()];

coerce 'RepeatedPublishChannelConnectionEventsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishChannelConnectionEventsRequest'->new($_) } @$_ ] };

declare 'MapStringPublishChannelConnectionEventsRequest',
    as HashRef[PublishChannelConnectionEventsRequest()];

declare 'PublishChannelConnectionEventsResponse',
    as InstanceOf['Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishChannelConnectionEventsResponse'];

coerce 'PublishChannelConnectionEventsResponse',
    from HashRef, via { 'Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishChannelConnectionEventsResponse'->new($_) };

declare 'RepeatedPublishChannelConnectionEventsResponse',
    as ArrayRef[PublishChannelConnectionEventsResponse()];

coerce 'RepeatedPublishChannelConnectionEventsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishChannelConnectionEventsResponse'->new($_) } @$_ ] };

declare 'MapStringPublishChannelConnectionEventsResponse',
    as HashRef[PublishChannelConnectionEventsResponse()];

declare 'PublishEventsRequest',
    as InstanceOf['Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishEventsRequest'];

coerce 'PublishEventsRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishEventsRequest'->new($_) };

declare 'RepeatedPublishEventsRequest',
    as ArrayRef[PublishEventsRequest()];

coerce 'RepeatedPublishEventsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishEventsRequest'->new($_) } @$_ ] };

declare 'MapStringPublishEventsRequest',
    as HashRef[PublishEventsRequest()];

declare 'PublishEventsResponse',
    as InstanceOf['Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishEventsResponse'];

coerce 'PublishEventsResponse',
    from HashRef, via { 'Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishEventsResponse'->new($_) };

declare 'RepeatedPublishEventsResponse',
    as ArrayRef[PublishEventsResponse()];

coerce 'RepeatedPublishEventsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishEventsResponse'->new($_) } @$_ ] };

declare 'MapStringPublishEventsResponse',
    as HashRef[PublishEventsResponse()];

declare 'PublishRequest',
    as InstanceOf['Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishRequest'];

coerce 'PublishRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishRequest'->new($_) };

declare 'RepeatedPublishRequest',
    as ArrayRef[PublishRequest()];

coerce 'RepeatedPublishRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishRequest'->new($_) } @$_ ] };

declare 'MapStringPublishRequest',
    as HashRef[PublishRequest()];

declare 'PublishResponse',
    as InstanceOf['Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishResponse'];

coerce 'PublishResponse',
    from HashRef, via { 'Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishResponse'->new($_) };

declare 'RepeatedPublishResponse',
    as ArrayRef[PublishResponse()];

coerce 'RepeatedPublishResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::Publishing::V1::Publisher::PublishResponse'->new($_) } @$_ ] };

declare 'MapStringPublishResponse',
    as HashRef[PublishResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Eventarc::Publishing::V1::Publisher::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
