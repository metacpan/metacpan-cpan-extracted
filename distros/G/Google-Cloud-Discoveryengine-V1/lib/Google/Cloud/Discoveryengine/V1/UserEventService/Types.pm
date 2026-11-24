package Google::Cloud::Discoveryengine::V1::UserEventService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'WriteUserEventRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::UserEventService::WriteUserEventRequest'];

coerce 'WriteUserEventRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::UserEventService::WriteUserEventRequest'->new($_) };

declare 'RepeatedWriteUserEventRequest',
    as ArrayRef[WriteUserEventRequest()];

coerce 'RepeatedWriteUserEventRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::UserEventService::WriteUserEventRequest'->new($_) } @$_ ] };

declare 'MapStringWriteUserEventRequest',
    as HashRef[WriteUserEventRequest()];

declare 'CollectUserEventRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::UserEventService::CollectUserEventRequest'];

coerce 'CollectUserEventRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::UserEventService::CollectUserEventRequest'->new($_) };

declare 'RepeatedCollectUserEventRequest',
    as ArrayRef[CollectUserEventRequest()];

coerce 'RepeatedCollectUserEventRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::UserEventService::CollectUserEventRequest'->new($_) } @$_ ] };

declare 'MapStringCollectUserEventRequest',
    as HashRef[CollectUserEventRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1::UserEventService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
