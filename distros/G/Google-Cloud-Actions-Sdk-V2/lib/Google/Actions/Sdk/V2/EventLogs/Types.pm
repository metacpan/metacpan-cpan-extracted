package Google::Actions::Sdk::V2::EventLogs::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ExecutionEvent',
    as InstanceOf['Google::Actions::Sdk::V2::EventLogs::ExecutionEvent'];

coerce 'ExecutionEvent',
    from HashRef, via { 'Google::Actions::Sdk::V2::EventLogs::ExecutionEvent'->new($_) };

declare 'RepeatedExecutionEvent',
    as ArrayRef[ExecutionEvent()];

coerce 'RepeatedExecutionEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::EventLogs::ExecutionEvent'->new($_) } @$_ ] };

declare 'MapStringExecutionEvent',
    as HashRef[ExecutionEvent()];

declare 'ExecutionState',
    as InstanceOf['Google::Actions::Sdk::V2::EventLogs::ExecutionState'];

coerce 'ExecutionState',
    from HashRef, via { 'Google::Actions::Sdk::V2::EventLogs::ExecutionState'->new($_) };

declare 'RepeatedExecutionState',
    as ArrayRef[ExecutionState()];

coerce 'RepeatedExecutionState',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::EventLogs::ExecutionState'->new($_) } @$_ ] };

declare 'MapStringExecutionState',
    as HashRef[ExecutionState()];

declare 'Slots',
    as InstanceOf['Google::Actions::Sdk::V2::EventLogs::Slots'];

coerce 'Slots',
    from HashRef, via { 'Google::Actions::Sdk::V2::EventLogs::Slots'->new($_) };

declare 'RepeatedSlots',
    as ArrayRef[Slots()];

coerce 'RepeatedSlots',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::EventLogs::Slots'->new($_) } @$_ ] };

declare 'MapStringSlots',
    as HashRef[Slots()];

declare 'SlotsEntry',
    as InstanceOf['Google::Actions::Sdk::V2::EventLogs::Slots::SlotsEntry'];

coerce 'SlotsEntry',
    from HashRef, via { 'Google::Actions::Sdk::V2::EventLogs::Slots::SlotsEntry'->new($_) };

declare 'RepeatedSlotsEntry',
    as ArrayRef[SlotsEntry()];

coerce 'RepeatedSlotsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::EventLogs::Slots::SlotsEntry'->new($_) } @$_ ] };

declare 'MapStringSlotsEntry',
    as HashRef[SlotsEntry()];

declare 'UserConversationInput',
    as InstanceOf['Google::Actions::Sdk::V2::EventLogs::UserConversationInput'];

coerce 'UserConversationInput',
    from HashRef, via { 'Google::Actions::Sdk::V2::EventLogs::UserConversationInput'->new($_) };

declare 'RepeatedUserConversationInput',
    as ArrayRef[UserConversationInput()];

coerce 'RepeatedUserConversationInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::EventLogs::UserConversationInput'->new($_) } @$_ ] };

declare 'MapStringUserConversationInput',
    as HashRef[UserConversationInput()];

declare 'IntentMatch',
    as InstanceOf['Google::Actions::Sdk::V2::EventLogs::IntentMatch'];

coerce 'IntentMatch',
    from HashRef, via { 'Google::Actions::Sdk::V2::EventLogs::IntentMatch'->new($_) };

declare 'RepeatedIntentMatch',
    as ArrayRef[IntentMatch()];

coerce 'RepeatedIntentMatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::EventLogs::IntentMatch'->new($_) } @$_ ] };

declare 'MapStringIntentMatch',
    as HashRef[IntentMatch()];

declare 'IntentParametersEntry',
    as InstanceOf['Google::Actions::Sdk::V2::EventLogs::IntentMatch::IntentParametersEntry'];

coerce 'IntentParametersEntry',
    from HashRef, via { 'Google::Actions::Sdk::V2::EventLogs::IntentMatch::IntentParametersEntry'->new($_) };

declare 'RepeatedIntentParametersEntry',
    as ArrayRef[IntentParametersEntry()];

coerce 'RepeatedIntentParametersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::EventLogs::IntentMatch::IntentParametersEntry'->new($_) } @$_ ] };

declare 'MapStringIntentParametersEntry',
    as HashRef[IntentParametersEntry()];

declare 'ConditionsEvaluated',
    as InstanceOf['Google::Actions::Sdk::V2::EventLogs::ConditionsEvaluated'];

coerce 'ConditionsEvaluated',
    from HashRef, via { 'Google::Actions::Sdk::V2::EventLogs::ConditionsEvaluated'->new($_) };

declare 'RepeatedConditionsEvaluated',
    as ArrayRef[ConditionsEvaluated()];

coerce 'RepeatedConditionsEvaluated',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::EventLogs::ConditionsEvaluated'->new($_) } @$_ ] };

declare 'MapStringConditionsEvaluated',
    as HashRef[ConditionsEvaluated()];

declare 'Condition',
    as InstanceOf['Google::Actions::Sdk::V2::EventLogs::Condition'];

coerce 'Condition',
    from HashRef, via { 'Google::Actions::Sdk::V2::EventLogs::Condition'->new($_) };

declare 'RepeatedCondition',
    as ArrayRef[Condition()];

coerce 'RepeatedCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::EventLogs::Condition'->new($_) } @$_ ] };

declare 'MapStringCondition',
    as HashRef[Condition()];

declare 'OnSceneEnter',
    as InstanceOf['Google::Actions::Sdk::V2::EventLogs::OnSceneEnter'];

coerce 'OnSceneEnter',
    from HashRef, via { 'Google::Actions::Sdk::V2::EventLogs::OnSceneEnter'->new($_) };

declare 'RepeatedOnSceneEnter',
    as ArrayRef[OnSceneEnter()];

coerce 'RepeatedOnSceneEnter',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::EventLogs::OnSceneEnter'->new($_) } @$_ ] };

declare 'MapStringOnSceneEnter',
    as HashRef[OnSceneEnter()];

declare 'WebhookInitiatedTransition',
    as InstanceOf['Google::Actions::Sdk::V2::EventLogs::WebhookInitiatedTransition'];

coerce 'WebhookInitiatedTransition',
    from HashRef, via { 'Google::Actions::Sdk::V2::EventLogs::WebhookInitiatedTransition'->new($_) };

declare 'RepeatedWebhookInitiatedTransition',
    as ArrayRef[WebhookInitiatedTransition()];

coerce 'RepeatedWebhookInitiatedTransition',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::EventLogs::WebhookInitiatedTransition'->new($_) } @$_ ] };

declare 'MapStringWebhookInitiatedTransition',
    as HashRef[WebhookInitiatedTransition()];

declare 'WebhookRequest',
    as InstanceOf['Google::Actions::Sdk::V2::EventLogs::WebhookRequest'];

coerce 'WebhookRequest',
    from HashRef, via { 'Google::Actions::Sdk::V2::EventLogs::WebhookRequest'->new($_) };

declare 'RepeatedWebhookRequest',
    as ArrayRef[WebhookRequest()];

coerce 'RepeatedWebhookRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::EventLogs::WebhookRequest'->new($_) } @$_ ] };

declare 'MapStringWebhookRequest',
    as HashRef[WebhookRequest()];

declare 'WebhookResponse',
    as InstanceOf['Google::Actions::Sdk::V2::EventLogs::WebhookResponse'];

coerce 'WebhookResponse',
    from HashRef, via { 'Google::Actions::Sdk::V2::EventLogs::WebhookResponse'->new($_) };

declare 'RepeatedWebhookResponse',
    as ArrayRef[WebhookResponse()];

coerce 'RepeatedWebhookResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::EventLogs::WebhookResponse'->new($_) } @$_ ] };

declare 'MapStringWebhookResponse',
    as HashRef[WebhookResponse()];

declare 'SlotMatch',
    as InstanceOf['Google::Actions::Sdk::V2::EventLogs::SlotMatch'];

coerce 'SlotMatch',
    from HashRef, via { 'Google::Actions::Sdk::V2::EventLogs::SlotMatch'->new($_) };

declare 'RepeatedSlotMatch',
    as ArrayRef[SlotMatch()];

coerce 'RepeatedSlotMatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::EventLogs::SlotMatch'->new($_) } @$_ ] };

declare 'MapStringSlotMatch',
    as HashRef[SlotMatch()];

declare 'NluParametersEntry',
    as InstanceOf['Google::Actions::Sdk::V2::EventLogs::SlotMatch::NluParametersEntry'];

coerce 'NluParametersEntry',
    from HashRef, via { 'Google::Actions::Sdk::V2::EventLogs::SlotMatch::NluParametersEntry'->new($_) };

declare 'RepeatedNluParametersEntry',
    as ArrayRef[NluParametersEntry()];

coerce 'RepeatedNluParametersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::EventLogs::SlotMatch::NluParametersEntry'->new($_) } @$_ ] };

declare 'MapStringNluParametersEntry',
    as HashRef[NluParametersEntry()];

declare 'SlotRequested',
    as InstanceOf['Google::Actions::Sdk::V2::EventLogs::SlotRequested'];

coerce 'SlotRequested',
    from HashRef, via { 'Google::Actions::Sdk::V2::EventLogs::SlotRequested'->new($_) };

declare 'RepeatedSlotRequested',
    as ArrayRef[SlotRequested()];

coerce 'RepeatedSlotRequested',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::EventLogs::SlotRequested'->new($_) } @$_ ] };

declare 'MapStringSlotRequested',
    as HashRef[SlotRequested()];

declare 'SlotValidated',
    as InstanceOf['Google::Actions::Sdk::V2::EventLogs::SlotValidated'];

coerce 'SlotValidated',
    from HashRef, via { 'Google::Actions::Sdk::V2::EventLogs::SlotValidated'->new($_) };

declare 'RepeatedSlotValidated',
    as ArrayRef[SlotValidated()];

coerce 'RepeatedSlotValidated',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::EventLogs::SlotValidated'->new($_) } @$_ ] };

declare 'MapStringSlotValidated',
    as HashRef[SlotValidated()];

declare 'FormFilled',
    as InstanceOf['Google::Actions::Sdk::V2::EventLogs::FormFilled'];

coerce 'FormFilled',
    from HashRef, via { 'Google::Actions::Sdk::V2::EventLogs::FormFilled'->new($_) };

declare 'RepeatedFormFilled',
    as ArrayRef[FormFilled()];

coerce 'RepeatedFormFilled',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::EventLogs::FormFilled'->new($_) } @$_ ] };

declare 'MapStringFormFilled',
    as HashRef[FormFilled()];

declare 'WaitingForUserInput',
    as InstanceOf['Google::Actions::Sdk::V2::EventLogs::WaitingForUserInput'];

coerce 'WaitingForUserInput',
    from HashRef, via { 'Google::Actions::Sdk::V2::EventLogs::WaitingForUserInput'->new($_) };

declare 'RepeatedWaitingForUserInput',
    as ArrayRef[WaitingForUserInput()];

coerce 'RepeatedWaitingForUserInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::EventLogs::WaitingForUserInput'->new($_) } @$_ ] };

declare 'MapStringWaitingForUserInput',
    as HashRef[WaitingForUserInput()];

declare 'EndConversation',
    as InstanceOf['Google::Actions::Sdk::V2::EventLogs::EndConversation'];

coerce 'EndConversation',
    from HashRef, via { 'Google::Actions::Sdk::V2::EventLogs::EndConversation'->new($_) };

declare 'RepeatedEndConversation',
    as ArrayRef[EndConversation()];

coerce 'RepeatedEndConversation',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::EventLogs::EndConversation'->new($_) } @$_ ] };

declare 'MapStringEndConversation',
    as HashRef[EndConversation()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::EventLogs::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
