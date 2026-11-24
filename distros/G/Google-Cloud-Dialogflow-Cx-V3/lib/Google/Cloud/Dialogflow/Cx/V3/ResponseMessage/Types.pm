package Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ResponseMessage',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage'];

coerce 'ResponseMessage',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage'->new($_) };

declare 'RepeatedResponseMessage',
    as ArrayRef[ResponseMessage()];

coerce 'RepeatedResponseMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage'->new($_) } @$_ ] };

declare 'MapStringResponseMessage',
    as HashRef[ResponseMessage()];

declare 'ResponseType',
    as (Int | Str);

declare 'Text',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage::Text'];

coerce 'Text',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage::Text'->new($_) };

declare 'RepeatedText',
    as ArrayRef[Text()];

coerce 'RepeatedText',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage::Text'->new($_) } @$_ ] };

declare 'MapStringText',
    as HashRef[Text()];

declare 'LiveAgentHandoff',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage::LiveAgentHandoff'];

coerce 'LiveAgentHandoff',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage::LiveAgentHandoff'->new($_) };

declare 'RepeatedLiveAgentHandoff',
    as ArrayRef[LiveAgentHandoff()];

coerce 'RepeatedLiveAgentHandoff',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage::LiveAgentHandoff'->new($_) } @$_ ] };

declare 'MapStringLiveAgentHandoff',
    as HashRef[LiveAgentHandoff()];

declare 'ConversationSuccess',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage::ConversationSuccess'];

coerce 'ConversationSuccess',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage::ConversationSuccess'->new($_) };

declare 'RepeatedConversationSuccess',
    as ArrayRef[ConversationSuccess()];

coerce 'RepeatedConversationSuccess',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage::ConversationSuccess'->new($_) } @$_ ] };

declare 'MapStringConversationSuccess',
    as HashRef[ConversationSuccess()];

declare 'OutputAudioText',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage::OutputAudioText'];

coerce 'OutputAudioText',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage::OutputAudioText'->new($_) };

declare 'RepeatedOutputAudioText',
    as ArrayRef[OutputAudioText()];

coerce 'RepeatedOutputAudioText',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage::OutputAudioText'->new($_) } @$_ ] };

declare 'MapStringOutputAudioText',
    as HashRef[OutputAudioText()];

declare 'EndInteraction',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage::EndInteraction'];

coerce 'EndInteraction',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage::EndInteraction'->new($_) };

declare 'RepeatedEndInteraction',
    as ArrayRef[EndInteraction()];

coerce 'RepeatedEndInteraction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage::EndInteraction'->new($_) } @$_ ] };

declare 'MapStringEndInteraction',
    as HashRef[EndInteraction()];

declare 'PlayAudio',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage::PlayAudio'];

coerce 'PlayAudio',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage::PlayAudio'->new($_) };

declare 'RepeatedPlayAudio',
    as ArrayRef[PlayAudio()];

coerce 'RepeatedPlayAudio',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage::PlayAudio'->new($_) } @$_ ] };

declare 'MapStringPlayAudio',
    as HashRef[PlayAudio()];

declare 'MixedAudio',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage::MixedAudio'];

coerce 'MixedAudio',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage::MixedAudio'->new($_) };

declare 'RepeatedMixedAudio',
    as ArrayRef[MixedAudio()];

coerce 'RepeatedMixedAudio',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage::MixedAudio'->new($_) } @$_ ] };

declare 'MapStringMixedAudio',
    as HashRef[MixedAudio()];

declare 'Segment',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage::MixedAudio::Segment'];

coerce 'Segment',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage::MixedAudio::Segment'->new($_) };

declare 'RepeatedSegment',
    as ArrayRef[Segment()];

coerce 'RepeatedSegment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage::MixedAudio::Segment'->new($_) } @$_ ] };

declare 'MapStringSegment',
    as HashRef[Segment()];

declare 'TelephonyTransferCall',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage::TelephonyTransferCall'];

coerce 'TelephonyTransferCall',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage::TelephonyTransferCall'->new($_) };

declare 'RepeatedTelephonyTransferCall',
    as ArrayRef[TelephonyTransferCall()];

coerce 'RepeatedTelephonyTransferCall',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage::TelephonyTransferCall'->new($_) } @$_ ] };

declare 'MapStringTelephonyTransferCall',
    as HashRef[TelephonyTransferCall()];

declare 'KnowledgeInfoCard',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage::KnowledgeInfoCard'];

coerce 'KnowledgeInfoCard',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage::KnowledgeInfoCard'->new($_) };

declare 'RepeatedKnowledgeInfoCard',
    as ArrayRef[KnowledgeInfoCard()];

coerce 'RepeatedKnowledgeInfoCard',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::ResponseMessage::KnowledgeInfoCard'->new($_) } @$_ ] };

declare 'MapStringKnowledgeInfoCard',
    as HashRef[KnowledgeInfoCard()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::ResponseMessage::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
