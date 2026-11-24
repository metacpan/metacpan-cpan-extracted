package Google::Cloud::Ces::V1::Conversation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Conversation',
    as InstanceOf['Google::Cloud::Ces::V1::Conversation::Conversation'];

coerce 'Conversation',
    from HashRef, via { 'Google::Cloud::Ces::V1::Conversation::Conversation'->new($_) };

declare 'RepeatedConversation',
    as ArrayRef[Conversation()];

coerce 'RepeatedConversation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Conversation::Conversation'->new($_) } @$_ ] };

declare 'MapStringConversation',
    as HashRef[Conversation()];

declare 'ChannelType',
    as (Int | Str);

declare 'Source',
    as (Int | Str);

declare 'InputType',
    as (Int | Str);

declare 'Turn',
    as InstanceOf['Google::Cloud::Ces::V1::Conversation::Conversation::Turn'];

coerce 'Turn',
    from HashRef, via { 'Google::Cloud::Ces::V1::Conversation::Conversation::Turn'->new($_) };

declare 'RepeatedTurn',
    as ArrayRef[Turn()];

coerce 'RepeatedTurn',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Conversation::Conversation::Turn'->new($_) } @$_ ] };

declare 'MapStringTurn',
    as HashRef[Turn()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1::Conversation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
