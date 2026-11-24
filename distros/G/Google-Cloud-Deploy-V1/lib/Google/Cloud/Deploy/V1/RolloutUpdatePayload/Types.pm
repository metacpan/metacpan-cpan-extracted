package Google::Cloud::Deploy::V1::RolloutUpdatePayload::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RolloutUpdateEvent',
    as InstanceOf['Google::Cloud::Deploy::V1::RolloutUpdatePayload::RolloutUpdateEvent'];

coerce 'RolloutUpdateEvent',
    from HashRef, via { 'Google::Cloud::Deploy::V1::RolloutUpdatePayload::RolloutUpdateEvent'->new($_) };

declare 'RepeatedRolloutUpdateEvent',
    as ArrayRef[RolloutUpdateEvent()];

coerce 'RepeatedRolloutUpdateEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::RolloutUpdatePayload::RolloutUpdateEvent'->new($_) } @$_ ] };

declare 'MapStringRolloutUpdateEvent',
    as HashRef[RolloutUpdateEvent()];

declare 'RolloutUpdateType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Deploy::V1::RolloutUpdatePayload::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
