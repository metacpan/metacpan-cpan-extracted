package Google::Devtools::Build::V1::PublishBuildEvent::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PublishLifecycleEventRequest',
    as InstanceOf['Google::Devtools::Build::V1::PublishBuildEvent::PublishLifecycleEventRequest'];

coerce 'PublishLifecycleEventRequest',
    from HashRef, via { 'Google::Devtools::Build::V1::PublishBuildEvent::PublishLifecycleEventRequest'->new($_) };

declare 'RepeatedPublishLifecycleEventRequest',
    as ArrayRef[PublishLifecycleEventRequest()];

coerce 'RepeatedPublishLifecycleEventRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Build::V1::PublishBuildEvent::PublishLifecycleEventRequest'->new($_) } @$_ ] };

declare 'MapStringPublishLifecycleEventRequest',
    as HashRef[PublishLifecycleEventRequest()];

declare 'ServiceLevel',
    as (Int | Str);

declare 'PublishBuildToolEventStreamResponse',
    as InstanceOf['Google::Devtools::Build::V1::PublishBuildEvent::PublishBuildToolEventStreamResponse'];

coerce 'PublishBuildToolEventStreamResponse',
    from HashRef, via { 'Google::Devtools::Build::V1::PublishBuildEvent::PublishBuildToolEventStreamResponse'->new($_) };

declare 'RepeatedPublishBuildToolEventStreamResponse',
    as ArrayRef[PublishBuildToolEventStreamResponse()];

coerce 'RepeatedPublishBuildToolEventStreamResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Build::V1::PublishBuildEvent::PublishBuildToolEventStreamResponse'->new($_) } @$_ ] };

declare 'MapStringPublishBuildToolEventStreamResponse',
    as HashRef[PublishBuildToolEventStreamResponse()];

declare 'OrderedBuildEvent',
    as InstanceOf['Google::Devtools::Build::V1::PublishBuildEvent::OrderedBuildEvent'];

coerce 'OrderedBuildEvent',
    from HashRef, via { 'Google::Devtools::Build::V1::PublishBuildEvent::OrderedBuildEvent'->new($_) };

declare 'RepeatedOrderedBuildEvent',
    as ArrayRef[OrderedBuildEvent()];

coerce 'RepeatedOrderedBuildEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Build::V1::PublishBuildEvent::OrderedBuildEvent'->new($_) } @$_ ] };

declare 'MapStringOrderedBuildEvent',
    as HashRef[OrderedBuildEvent()];

declare 'PublishBuildToolEventStreamRequest',
    as InstanceOf['Google::Devtools::Build::V1::PublishBuildEvent::PublishBuildToolEventStreamRequest'];

coerce 'PublishBuildToolEventStreamRequest',
    from HashRef, via { 'Google::Devtools::Build::V1::PublishBuildEvent::PublishBuildToolEventStreamRequest'->new($_) };

declare 'RepeatedPublishBuildToolEventStreamRequest',
    as ArrayRef[PublishBuildToolEventStreamRequest()];

coerce 'RepeatedPublishBuildToolEventStreamRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Build::V1::PublishBuildEvent::PublishBuildToolEventStreamRequest'->new($_) } @$_ ] };

declare 'MapStringPublishBuildToolEventStreamRequest',
    as HashRef[PublishBuildToolEventStreamRequest()];

1;

__END__

=head1 NAME

Google::Devtools::Build::V1::PublishBuildEvent::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
