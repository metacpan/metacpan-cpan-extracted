package Google::Cloud::Pubsublite::V1::Publisher::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'InitialPublishRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Publisher::InitialPublishRequest'];

coerce 'InitialPublishRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Publisher::InitialPublishRequest'->new($_) };

declare 'RepeatedInitialPublishRequest',
    as ArrayRef[InitialPublishRequest()];

coerce 'RepeatedInitialPublishRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Publisher::InitialPublishRequest'->new($_) } @$_ ] };

declare 'MapStringInitialPublishRequest',
    as HashRef[InitialPublishRequest()];

declare 'InitialPublishResponse',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Publisher::InitialPublishResponse'];

coerce 'InitialPublishResponse',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Publisher::InitialPublishResponse'->new($_) };

declare 'RepeatedInitialPublishResponse',
    as ArrayRef[InitialPublishResponse()];

coerce 'RepeatedInitialPublishResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Publisher::InitialPublishResponse'->new($_) } @$_ ] };

declare 'MapStringInitialPublishResponse',
    as HashRef[InitialPublishResponse()];

declare 'MessagePublishRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Publisher::MessagePublishRequest'];

coerce 'MessagePublishRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Publisher::MessagePublishRequest'->new($_) };

declare 'RepeatedMessagePublishRequest',
    as ArrayRef[MessagePublishRequest()];

coerce 'RepeatedMessagePublishRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Publisher::MessagePublishRequest'->new($_) } @$_ ] };

declare 'MapStringMessagePublishRequest',
    as HashRef[MessagePublishRequest()];

declare 'MessagePublishResponse',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Publisher::MessagePublishResponse'];

coerce 'MessagePublishResponse',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Publisher::MessagePublishResponse'->new($_) };

declare 'RepeatedMessagePublishResponse',
    as ArrayRef[MessagePublishResponse()];

coerce 'RepeatedMessagePublishResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Publisher::MessagePublishResponse'->new($_) } @$_ ] };

declare 'MapStringMessagePublishResponse',
    as HashRef[MessagePublishResponse()];

declare 'CursorRange',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Publisher::MessagePublishResponse::CursorRange'];

coerce 'CursorRange',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Publisher::MessagePublishResponse::CursorRange'->new($_) };

declare 'RepeatedCursorRange',
    as ArrayRef[CursorRange()];

coerce 'RepeatedCursorRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Publisher::MessagePublishResponse::CursorRange'->new($_) } @$_ ] };

declare 'MapStringCursorRange',
    as HashRef[CursorRange()];

declare 'PublishRequest',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Publisher::PublishRequest'];

coerce 'PublishRequest',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Publisher::PublishRequest'->new($_) };

declare 'RepeatedPublishRequest',
    as ArrayRef[PublishRequest()];

coerce 'RepeatedPublishRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Publisher::PublishRequest'->new($_) } @$_ ] };

declare 'MapStringPublishRequest',
    as HashRef[PublishRequest()];

declare 'PublishResponse',
    as InstanceOf['Google::Cloud::Pubsublite::V1::Publisher::PublishResponse'];

coerce 'PublishResponse',
    from HashRef, via { 'Google::Cloud::Pubsublite::V1::Publisher::PublishResponse'->new($_) };

declare 'RepeatedPublishResponse',
    as ArrayRef[PublishResponse()];

coerce 'RepeatedPublishResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Pubsublite::V1::Publisher::PublishResponse'->new($_) } @$_ ] };

declare 'MapStringPublishResponse',
    as HashRef[PublishResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Pubsublite::V1::Publisher::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
