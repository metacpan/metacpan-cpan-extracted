package Google::Cloud::Geminidataanalytics::V1beta::Conversation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Conversation',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Conversation::Conversation'];

coerce 'Conversation',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Conversation::Conversation'->new($_) };

declare 'RepeatedConversation',
    as ArrayRef[Conversation()];

coerce 'RepeatedConversation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Conversation::Conversation'->new($_) } @$_ ] };

declare 'MapStringConversation',
    as HashRef[Conversation()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Conversation::Conversation::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Conversation::Conversation::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Conversation::Conversation::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'CreateConversationRequest',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Conversation::CreateConversationRequest'];

coerce 'CreateConversationRequest',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Conversation::CreateConversationRequest'->new($_) };

declare 'RepeatedCreateConversationRequest',
    as ArrayRef[CreateConversationRequest()];

coerce 'RepeatedCreateConversationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Conversation::CreateConversationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateConversationRequest',
    as HashRef[CreateConversationRequest()];

declare 'UpdateConversationRequest',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Conversation::UpdateConversationRequest'];

coerce 'UpdateConversationRequest',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Conversation::UpdateConversationRequest'->new($_) };

declare 'RepeatedUpdateConversationRequest',
    as ArrayRef[UpdateConversationRequest()];

coerce 'RepeatedUpdateConversationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Conversation::UpdateConversationRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateConversationRequest',
    as HashRef[UpdateConversationRequest()];

declare 'GetConversationRequest',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Conversation::GetConversationRequest'];

coerce 'GetConversationRequest',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Conversation::GetConversationRequest'->new($_) };

declare 'RepeatedGetConversationRequest',
    as ArrayRef[GetConversationRequest()];

coerce 'RepeatedGetConversationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Conversation::GetConversationRequest'->new($_) } @$_ ] };

declare 'MapStringGetConversationRequest',
    as HashRef[GetConversationRequest()];

declare 'ListConversationsRequest',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Conversation::ListConversationsRequest'];

coerce 'ListConversationsRequest',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Conversation::ListConversationsRequest'->new($_) };

declare 'RepeatedListConversationsRequest',
    as ArrayRef[ListConversationsRequest()];

coerce 'RepeatedListConversationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Conversation::ListConversationsRequest'->new($_) } @$_ ] };

declare 'MapStringListConversationsRequest',
    as HashRef[ListConversationsRequest()];

declare 'ListConversationsResponse',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Conversation::ListConversationsResponse'];

coerce 'ListConversationsResponse',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Conversation::ListConversationsResponse'->new($_) };

declare 'RepeatedListConversationsResponse',
    as ArrayRef[ListConversationsResponse()];

coerce 'RepeatedListConversationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Conversation::ListConversationsResponse'->new($_) } @$_ ] };

declare 'MapStringListConversationsResponse',
    as HashRef[ListConversationsResponse()];

declare 'DeleteConversationRequest',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::Conversation::DeleteConversationRequest'];

coerce 'DeleteConversationRequest',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::Conversation::DeleteConversationRequest'->new($_) };

declare 'RepeatedDeleteConversationRequest',
    as ArrayRef[DeleteConversationRequest()];

coerce 'RepeatedDeleteConversationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::Conversation::DeleteConversationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteConversationRequest',
    as HashRef[DeleteConversationRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Geminidataanalytics::V1beta::Conversation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
