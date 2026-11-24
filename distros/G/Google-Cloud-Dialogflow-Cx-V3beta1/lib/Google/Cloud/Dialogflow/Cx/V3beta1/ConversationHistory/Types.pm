package Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetConversationRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::GetConversationRequest'];

coerce 'GetConversationRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::GetConversationRequest'->new($_) };

declare 'RepeatedGetConversationRequest',
    as ArrayRef[GetConversationRequest()];

coerce 'RepeatedGetConversationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::GetConversationRequest'->new($_) } @$_ ] };

declare 'MapStringGetConversationRequest',
    as HashRef[GetConversationRequest()];

declare 'DeleteConversationRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::DeleteConversationRequest'];

coerce 'DeleteConversationRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::DeleteConversationRequest'->new($_) };

declare 'RepeatedDeleteConversationRequest',
    as ArrayRef[DeleteConversationRequest()];

coerce 'RepeatedDeleteConversationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::DeleteConversationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteConversationRequest',
    as HashRef[DeleteConversationRequest()];

declare 'ListConversationsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::ListConversationsRequest'];

coerce 'ListConversationsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::ListConversationsRequest'->new($_) };

declare 'RepeatedListConversationsRequest',
    as ArrayRef[ListConversationsRequest()];

coerce 'RepeatedListConversationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::ListConversationsRequest'->new($_) } @$_ ] };

declare 'MapStringListConversationsRequest',
    as HashRef[ListConversationsRequest()];

declare 'ListConversationsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::ListConversationsResponse'];

coerce 'ListConversationsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::ListConversationsResponse'->new($_) };

declare 'RepeatedListConversationsResponse',
    as ArrayRef[ListConversationsResponse()];

coerce 'RepeatedListConversationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::ListConversationsResponse'->new($_) } @$_ ] };

declare 'MapStringListConversationsResponse',
    as HashRef[ListConversationsResponse()];

declare 'Conversation',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Conversation'];

coerce 'Conversation',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Conversation'->new($_) };

declare 'RepeatedConversation',
    as ArrayRef[Conversation()];

coerce 'RepeatedConversation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Conversation'->new($_) } @$_ ] };

declare 'MapStringConversation',
    as HashRef[Conversation()];

declare 'Type',
    as (Int | Str);

declare 'Metrics',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Conversation::Metrics'];

coerce 'Metrics',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Conversation::Metrics'->new($_) };

declare 'RepeatedMetrics',
    as ArrayRef[Metrics()];

coerce 'RepeatedMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Conversation::Metrics'->new($_) } @$_ ] };

declare 'MapStringMetrics',
    as HashRef[Metrics()];

declare 'QueryInputCount',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Conversation::Metrics::QueryInputCount'];

coerce 'QueryInputCount',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Conversation::Metrics::QueryInputCount'->new($_) };

declare 'RepeatedQueryInputCount',
    as ArrayRef[QueryInputCount()];

coerce 'RepeatedQueryInputCount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Conversation::Metrics::QueryInputCount'->new($_) } @$_ ] };

declare 'MapStringQueryInputCount',
    as HashRef[QueryInputCount()];

declare 'MatchTypeCount',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Conversation::Metrics::MatchTypeCount'];

coerce 'MatchTypeCount',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Conversation::Metrics::MatchTypeCount'->new($_) };

declare 'RepeatedMatchTypeCount',
    as ArrayRef[MatchTypeCount()];

coerce 'RepeatedMatchTypeCount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Conversation::Metrics::MatchTypeCount'->new($_) } @$_ ] };

declare 'MapStringMatchTypeCount',
    as HashRef[MatchTypeCount()];

declare 'Interaction',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Conversation::Interaction'];

coerce 'Interaction',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Conversation::Interaction'->new($_) };

declare 'RepeatedInteraction',
    as ArrayRef[Interaction()];

coerce 'RepeatedInteraction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Conversation::Interaction'->new($_) } @$_ ] };

declare 'MapStringInteraction',
    as HashRef[Interaction()];

declare 'MissingTransition',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Conversation::Interaction::MissingTransition'];

coerce 'MissingTransition',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Conversation::Interaction::MissingTransition'->new($_) };

declare 'RepeatedMissingTransition',
    as ArrayRef[MissingTransition()];

coerce 'RepeatedMissingTransition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Conversation::Interaction::MissingTransition'->new($_) } @$_ ] };

declare 'MapStringMissingTransition',
    as HashRef[MissingTransition()];

declare 'StepMetrics',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Conversation::Interaction::StepMetrics'];

coerce 'StepMetrics',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Conversation::Interaction::StepMetrics'->new($_) };

declare 'RepeatedStepMetrics',
    as ArrayRef[StepMetrics()];

coerce 'RepeatedStepMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Conversation::Interaction::StepMetrics'->new($_) } @$_ ] };

declare 'MapStringStepMetrics',
    as HashRef[StepMetrics()];

declare 'FlowVersionsEntry',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Conversation::FlowVersionsEntry'];

coerce 'FlowVersionsEntry',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Conversation::FlowVersionsEntry'->new($_) };

declare 'RepeatedFlowVersionsEntry',
    as ArrayRef[FlowVersionsEntry()];

coerce 'RepeatedFlowVersionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Conversation::FlowVersionsEntry'->new($_) } @$_ ] };

declare 'MapStringFlowVersionsEntry',
    as HashRef[FlowVersionsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::ConversationHistory::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
