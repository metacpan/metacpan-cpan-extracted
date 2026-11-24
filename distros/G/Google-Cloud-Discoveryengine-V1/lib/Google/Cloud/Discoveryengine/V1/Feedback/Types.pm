package Google::Cloud::Discoveryengine::V1::Feedback::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Feedback',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Feedback::Feedback'];

coerce 'Feedback',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Feedback::Feedback'->new($_) };

declare 'RepeatedFeedback',
    as ArrayRef[Feedback()];

coerce 'RepeatedFeedback',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Feedback::Feedback'->new($_) } @$_ ] };

declare 'MapStringFeedback',
    as HashRef[Feedback()];

declare 'FeedbackType',
    as (Int | Str);

declare 'Reason',
    as (Int | Str);

declare 'FeedbackSource',
    as (Int | Str);

declare 'ConversationInfo',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::Feedback::Feedback::ConversationInfo'];

coerce 'ConversationInfo',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::Feedback::Feedback::ConversationInfo'->new($_) };

declare 'RepeatedConversationInfo',
    as ArrayRef[ConversationInfo()];

coerce 'RepeatedConversationInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::Feedback::Feedback::ConversationInfo'->new($_) } @$_ ] };

declare 'MapStringConversationInfo',
    as HashRef[ConversationInfo()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1::Feedback::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
