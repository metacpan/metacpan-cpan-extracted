package Google::Cloud::Retail::V2beta::UserEventService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'WriteUserEventRequest',
    as InstanceOf['Google::Cloud::Retail::V2beta::UserEventService::WriteUserEventRequest'];

coerce 'WriteUserEventRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::UserEventService::WriteUserEventRequest'->new($_) };

declare 'RepeatedWriteUserEventRequest',
    as ArrayRef[WriteUserEventRequest()];

coerce 'RepeatedWriteUserEventRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::UserEventService::WriteUserEventRequest'->new($_) } @$_ ] };

declare 'MapStringWriteUserEventRequest',
    as HashRef[WriteUserEventRequest()];

declare 'CollectUserEventRequest',
    as InstanceOf['Google::Cloud::Retail::V2beta::UserEventService::CollectUserEventRequest'];

coerce 'CollectUserEventRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::UserEventService::CollectUserEventRequest'->new($_) };

declare 'RepeatedCollectUserEventRequest',
    as ArrayRef[CollectUserEventRequest()];

coerce 'RepeatedCollectUserEventRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::UserEventService::CollectUserEventRequest'->new($_) } @$_ ] };

declare 'MapStringCollectUserEventRequest',
    as HashRef[CollectUserEventRequest()];

declare 'RejoinUserEventsRequest',
    as InstanceOf['Google::Cloud::Retail::V2beta::UserEventService::RejoinUserEventsRequest'];

coerce 'RejoinUserEventsRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::UserEventService::RejoinUserEventsRequest'->new($_) };

declare 'RepeatedRejoinUserEventsRequest',
    as ArrayRef[RejoinUserEventsRequest()];

coerce 'RepeatedRejoinUserEventsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::UserEventService::RejoinUserEventsRequest'->new($_) } @$_ ] };

declare 'MapStringRejoinUserEventsRequest',
    as HashRef[RejoinUserEventsRequest()];

declare 'UserEventRejoinScope',
    as (Int | Str);

declare 'RejoinUserEventsResponse',
    as InstanceOf['Google::Cloud::Retail::V2beta::UserEventService::RejoinUserEventsResponse'];

coerce 'RejoinUserEventsResponse',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::UserEventService::RejoinUserEventsResponse'->new($_) };

declare 'RepeatedRejoinUserEventsResponse',
    as ArrayRef[RejoinUserEventsResponse()];

coerce 'RepeatedRejoinUserEventsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::UserEventService::RejoinUserEventsResponse'->new($_) } @$_ ] };

declare 'MapStringRejoinUserEventsResponse',
    as HashRef[RejoinUserEventsResponse()];

declare 'RejoinUserEventsMetadata',
    as InstanceOf['Google::Cloud::Retail::V2beta::UserEventService::RejoinUserEventsMetadata'];

coerce 'RejoinUserEventsMetadata',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::UserEventService::RejoinUserEventsMetadata'->new($_) };

declare 'RepeatedRejoinUserEventsMetadata',
    as ArrayRef[RejoinUserEventsMetadata()];

coerce 'RepeatedRejoinUserEventsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::UserEventService::RejoinUserEventsMetadata'->new($_) } @$_ ] };

declare 'MapStringRejoinUserEventsMetadata',
    as HashRef[RejoinUserEventsMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Retail::V2beta::UserEventService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
