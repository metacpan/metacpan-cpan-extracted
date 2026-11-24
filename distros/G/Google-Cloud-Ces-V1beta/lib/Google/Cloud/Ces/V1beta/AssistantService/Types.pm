package Google::Cloud::Ces::V1beta::AssistantService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AssistantSessionState',
    as (Int | Str);

declare 'ListAssistantSessionsRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::AssistantService::ListAssistantSessionsRequest'];

coerce 'ListAssistantSessionsRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::AssistantService::ListAssistantSessionsRequest'->new($_) };

declare 'RepeatedListAssistantSessionsRequest',
    as ArrayRef[ListAssistantSessionsRequest()];

coerce 'RepeatedListAssistantSessionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::AssistantService::ListAssistantSessionsRequest'->new($_) } @$_ ] };

declare 'MapStringListAssistantSessionsRequest',
    as HashRef[ListAssistantSessionsRequest()];

declare 'ListAssistantSessionsResponse',
    as InstanceOf['Google::Cloud::Ces::V1beta::AssistantService::ListAssistantSessionsResponse'];

coerce 'ListAssistantSessionsResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::AssistantService::ListAssistantSessionsResponse'->new($_) };

declare 'RepeatedListAssistantSessionsResponse',
    as ArrayRef[ListAssistantSessionsResponse()];

coerce 'RepeatedListAssistantSessionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::AssistantService::ListAssistantSessionsResponse'->new($_) } @$_ ] };

declare 'MapStringListAssistantSessionsResponse',
    as HashRef[ListAssistantSessionsResponse()];

declare 'GetAssistantSessionRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::AssistantService::GetAssistantSessionRequest'];

coerce 'GetAssistantSessionRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::AssistantService::GetAssistantSessionRequest'->new($_) };

declare 'RepeatedGetAssistantSessionRequest',
    as ArrayRef[GetAssistantSessionRequest()];

coerce 'RepeatedGetAssistantSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::AssistantService::GetAssistantSessionRequest'->new($_) } @$_ ] };

declare 'MapStringGetAssistantSessionRequest',
    as HashRef[GetAssistantSessionRequest()];

declare 'CreateAssistantSessionRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::AssistantService::CreateAssistantSessionRequest'];

coerce 'CreateAssistantSessionRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::AssistantService::CreateAssistantSessionRequest'->new($_) };

declare 'RepeatedCreateAssistantSessionRequest',
    as ArrayRef[CreateAssistantSessionRequest()];

coerce 'RepeatedCreateAssistantSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::AssistantService::CreateAssistantSessionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAssistantSessionRequest',
    as HashRef[CreateAssistantSessionRequest()];

declare 'DeleteAssistantSessionRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::AssistantService::DeleteAssistantSessionRequest'];

coerce 'DeleteAssistantSessionRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::AssistantService::DeleteAssistantSessionRequest'->new($_) };

declare 'RepeatedDeleteAssistantSessionRequest',
    as ArrayRef[DeleteAssistantSessionRequest()];

coerce 'RepeatedDeleteAssistantSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::AssistantService::DeleteAssistantSessionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAssistantSessionRequest',
    as HashRef[DeleteAssistantSessionRequest()];

declare 'RunAssistantRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::AssistantService::RunAssistantRequest'];

coerce 'RunAssistantRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::AssistantService::RunAssistantRequest'->new($_) };

declare 'RepeatedRunAssistantRequest',
    as ArrayRef[RunAssistantRequest()];

coerce 'RepeatedRunAssistantRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::AssistantService::RunAssistantRequest'->new($_) } @$_ ] };

declare 'MapStringRunAssistantRequest',
    as HashRef[RunAssistantRequest()];

declare 'InteractionType',
    as (Int | Str);

declare 'RunAssistantResponse',
    as InstanceOf['Google::Cloud::Ces::V1beta::AssistantService::RunAssistantResponse'];

coerce 'RunAssistantResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::AssistantService::RunAssistantResponse'->new($_) };

declare 'RepeatedRunAssistantResponse',
    as ArrayRef[RunAssistantResponse()];

coerce 'RepeatedRunAssistantResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::AssistantService::RunAssistantResponse'->new($_) } @$_ ] };

declare 'MapStringRunAssistantResponse',
    as HashRef[RunAssistantResponse()];

declare 'AssistantSession',
    as InstanceOf['Google::Cloud::Ces::V1beta::AssistantService::AssistantSession'];

coerce 'AssistantSession',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::AssistantService::AssistantSession'->new($_) };

declare 'RepeatedAssistantSession',
    as ArrayRef[AssistantSession()];

coerce 'RepeatedAssistantSession',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::AssistantService::AssistantSession'->new($_) } @$_ ] };

declare 'MapStringAssistantSession',
    as HashRef[AssistantSession()];

declare 'ActiveTurnInfo',
    as InstanceOf['Google::Cloud::Ces::V1beta::AssistantService::ActiveTurnInfo'];

coerce 'ActiveTurnInfo',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::AssistantService::ActiveTurnInfo'->new($_) };

declare 'RepeatedActiveTurnInfo',
    as ArrayRef[ActiveTurnInfo()];

coerce 'RepeatedActiveTurnInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::AssistantService::ActiveTurnInfo'->new($_) } @$_ ] };

declare 'MapStringActiveTurnInfo',
    as HashRef[ActiveTurnInfo()];

declare 'Status',
    as (Int | Str);

declare 'AssistantSessionArtifact',
    as InstanceOf['Google::Cloud::Ces::V1beta::AssistantService::AssistantSessionArtifact'];

coerce 'AssistantSessionArtifact',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::AssistantService::AssistantSessionArtifact'->new($_) };

declare 'RepeatedAssistantSessionArtifact',
    as ArrayRef[AssistantSessionArtifact()];

coerce 'RepeatedAssistantSessionArtifact',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::AssistantService::AssistantSessionArtifact'->new($_) } @$_ ] };

declare 'MapStringAssistantSessionArtifact',
    as HashRef[AssistantSessionArtifact()];

declare 'AssistantChunk',
    as InstanceOf['Google::Cloud::Ces::V1beta::AssistantService::AssistantChunk'];

coerce 'AssistantChunk',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::AssistantService::AssistantChunk'->new($_) };

declare 'RepeatedAssistantChunk',
    as ArrayRef[AssistantChunk()];

coerce 'RepeatedAssistantChunk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::AssistantService::AssistantChunk'->new($_) } @$_ ] };

declare 'MapStringAssistantChunk',
    as HashRef[AssistantChunk()];

declare 'AssistantOutput',
    as InstanceOf['Google::Cloud::Ces::V1beta::AssistantService::AssistantOutput'];

coerce 'AssistantOutput',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::AssistantService::AssistantOutput'->new($_) };

declare 'RepeatedAssistantOutput',
    as ArrayRef[AssistantOutput()];

coerce 'RepeatedAssistantOutput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::AssistantService::AssistantOutput'->new($_) } @$_ ] };

declare 'MapStringAssistantOutput',
    as HashRef[AssistantOutput()];

declare 'AssistantMessage',
    as InstanceOf['Google::Cloud::Ces::V1beta::AssistantService::AssistantMessage'];

coerce 'AssistantMessage',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::AssistantService::AssistantMessage'->new($_) };

declare 'RepeatedAssistantMessage',
    as ArrayRef[AssistantMessage()];

coerce 'RepeatedAssistantMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::AssistantService::AssistantMessage'->new($_) } @$_ ] };

declare 'MapStringAssistantMessage',
    as HashRef[AssistantMessage()];

declare 'TypedPayload',
    as InstanceOf['Google::Cloud::Ces::V1beta::AssistantService::TypedPayload'];

coerce 'TypedPayload',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::AssistantService::TypedPayload'->new($_) };

declare 'RepeatedTypedPayload',
    as ArrayRef[TypedPayload()];

coerce 'RepeatedTypedPayload',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::AssistantService::TypedPayload'->new($_) } @$_ ] };

declare 'MapStringTypedPayload',
    as HashRef[TypedPayload()];

declare 'UserResponseSuggestions',
    as InstanceOf['Google::Cloud::Ces::V1beta::AssistantService::UserResponseSuggestions'];

coerce 'UserResponseSuggestions',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::AssistantService::UserResponseSuggestions'->new($_) };

declare 'RepeatedUserResponseSuggestions',
    as ArrayRef[UserResponseSuggestions()];

coerce 'RepeatedUserResponseSuggestions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::AssistantService::UserResponseSuggestions'->new($_) } @$_ ] };

declare 'MapStringUserResponseSuggestions',
    as HashRef[UserResponseSuggestions()];

declare 'ChatAiAssistantRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::AssistantService::ChatAiAssistantRequest'];

coerce 'ChatAiAssistantRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::AssistantService::ChatAiAssistantRequest'->new($_) };

declare 'RepeatedChatAiAssistantRequest',
    as ArrayRef[ChatAiAssistantRequest()];

coerce 'RepeatedChatAiAssistantRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::AssistantService::ChatAiAssistantRequest'->new($_) } @$_ ] };

declare 'MapStringChatAiAssistantRequest',
    as HashRef[ChatAiAssistantRequest()];

declare 'ChatAiAssistantResponse',
    as InstanceOf['Google::Cloud::Ces::V1beta::AssistantService::ChatAiAssistantResponse'];

coerce 'ChatAiAssistantResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::AssistantService::ChatAiAssistantResponse'->new($_) };

declare 'RepeatedChatAiAssistantResponse',
    as ArrayRef[ChatAiAssistantResponse()];

coerce 'RepeatedChatAiAssistantResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::AssistantService::ChatAiAssistantResponse'->new($_) } @$_ ] };

declare 'MapStringChatAiAssistantResponse',
    as HashRef[ChatAiAssistantResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1beta::AssistantService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
