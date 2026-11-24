package Google::Cloud::Discoveryengine::V1::Conversation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Conversation',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Conversation::Conversation'];

coerce 'Conversation',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Conversation::Conversation'->new($_) };

declare 'RepeatedConversation',
    as ArrayRef[Conversation()];

coerce 'RepeatedConversation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Conversation::Conversation'->new($_) } @$_ ] };

declare 'MapStringConversation',
    as HashRef[Conversation()];

declare 'State',
    as (Int | Str);

declare 'Reply',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Conversation::Reply'];

coerce 'Reply',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Conversation::Reply'->new($_) };

declare 'RepeatedReply',
    as ArrayRef[Reply()];

coerce 'RepeatedReply',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Conversation::Reply'->new($_) } @$_ ] };

declare 'MapStringReply',
    as HashRef[Reply()];

declare 'ConversationContext',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Conversation::ConversationContext'];

coerce 'ConversationContext',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Conversation::ConversationContext'->new($_) };

declare 'RepeatedConversationContext',
    as ArrayRef[ConversationContext()];

coerce 'RepeatedConversationContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Conversation::ConversationContext'->new($_) } @$_ ] };

declare 'MapStringConversationContext',
    as HashRef[ConversationContext()];

declare 'TextInput',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Conversation::TextInput'];

coerce 'TextInput',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Conversation::TextInput'->new($_) };

declare 'RepeatedTextInput',
    as ArrayRef[TextInput()];

coerce 'RepeatedTextInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Conversation::TextInput'->new($_) } @$_ ] };

declare 'MapStringTextInput',
    as HashRef[TextInput()];

declare 'ConversationMessage',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Conversation::ConversationMessage'];

coerce 'ConversationMessage',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Conversation::ConversationMessage'->new($_) };

declare 'RepeatedConversationMessage',
    as ArrayRef[ConversationMessage()];

coerce 'RepeatedConversationMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Conversation::ConversationMessage'->new($_) } @$_ ] };

declare 'MapStringConversationMessage',
    as HashRef[ConversationMessage()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1::Conversation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
