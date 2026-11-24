package Google::Actions::Sdk::V2::Conversation::Scene::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SlotFillingStatus',
    as (Int | Str);

declare 'Slot',
    as InstanceOf['Google::Actions::Sdk::V2::Conversation::Scene::Slot'];

coerce 'Slot',
    from HashRef, via { 'Google::Actions::Sdk::V2::Conversation::Scene::Slot'->new($_) };

declare 'RepeatedSlot',
    as ArrayRef[Slot()];

coerce 'RepeatedSlot',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Conversation::Scene::Slot'->new($_) } @$_ ] };

declare 'MapStringSlot',
    as HashRef[Slot()];

declare 'SlotMode',
    as (Int | Str);

declare 'SlotStatus',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Conversation::Scene::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
