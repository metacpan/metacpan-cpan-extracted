package Google::Cloud::Dialogflow::V2beta1::ConversationEvent::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ConversationEvent',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::ConversationEvent::ConversationEvent'];

coerce 'ConversationEvent',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::ConversationEvent::ConversationEvent'->new($_) };

declare 'RepeatedConversationEvent',
    as ArrayRef[ConversationEvent()];

coerce 'RepeatedConversationEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::ConversationEvent::ConversationEvent'->new($_) } @$_ ] };

declare 'MapStringConversationEvent',
    as HashRef[ConversationEvent()];

declare 'Type',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::ConversationEvent::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
