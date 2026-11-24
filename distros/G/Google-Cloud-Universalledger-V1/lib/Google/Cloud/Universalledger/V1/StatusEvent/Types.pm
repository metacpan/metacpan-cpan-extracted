package Google::Cloud::Universalledger::V1::StatusEvent::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EventType',
    as (Int | Str);

declare 'StatusEvent',
    as InstanceOf['Google::Cloud::Universalledger::V1::StatusEvent::StatusEvent'];

coerce 'StatusEvent',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::StatusEvent::StatusEvent'->new($_) };

declare 'RepeatedStatusEvent',
    as ArrayRef[StatusEvent()];

coerce 'RepeatedStatusEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::StatusEvent::StatusEvent'->new($_) } @$_ ] };

declare 'MapStringStatusEvent',
    as HashRef[StatusEvent()];

declare 'EventDetails',
    as InstanceOf['Google::Cloud::Universalledger::V1::StatusEvent::EventDetails'];

coerce 'EventDetails',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::StatusEvent::EventDetails'->new($_) };

declare 'RepeatedEventDetails',
    as ArrayRef[EventDetails()];

coerce 'RepeatedEventDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::StatusEvent::EventDetails'->new($_) } @$_ ] };

declare 'MapStringEventDetails',
    as HashRef[EventDetails()];

declare 'ExecutionDetails',
    as InstanceOf['Google::Cloud::Universalledger::V1::StatusEvent::ExecutionDetails'];

coerce 'ExecutionDetails',
    from HashRef, via { 'Google::Cloud::Universalledger::V1::StatusEvent::ExecutionDetails'->new($_) };

declare 'RepeatedExecutionDetails',
    as ArrayRef[ExecutionDetails()];

coerce 'RepeatedExecutionDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Universalledger::V1::StatusEvent::ExecutionDetails'->new($_) } @$_ ] };

declare 'MapStringExecutionDetails',
    as HashRef[ExecutionDetails()];

1;

__END__

=head1 NAME

Google::Cloud::Universalledger::V1::StatusEvent::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
