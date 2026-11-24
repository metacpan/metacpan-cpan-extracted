package Google::Cloud::Discoveryengine::V1::AssistantService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AssistUserMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::AssistantService::AssistUserMetadata'];

coerce 'AssistUserMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::AssistantService::AssistUserMetadata'->new($_) };

declare 'RepeatedAssistUserMetadata',
    as ArrayRef[AssistUserMetadata()];

coerce 'RepeatedAssistUserMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::AssistantService::AssistUserMetadata'->new($_) } @$_ ] };

declare 'MapStringAssistUserMetadata',
    as HashRef[AssistUserMetadata()];

declare 'StreamAssistRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistRequest'];

coerce 'StreamAssistRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistRequest'->new($_) };

declare 'RepeatedStreamAssistRequest',
    as ArrayRef[StreamAssistRequest()];

coerce 'RepeatedStreamAssistRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistRequest'->new($_) } @$_ ] };

declare 'MapStringStreamAssistRequest',
    as HashRef[StreamAssistRequest()];

declare 'AgentsSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistRequest::AgentsSpec'];

coerce 'AgentsSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistRequest::AgentsSpec'->new($_) };

declare 'RepeatedAgentsSpec',
    as ArrayRef[AgentsSpec()];

coerce 'RepeatedAgentsSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistRequest::AgentsSpec'->new($_) } @$_ ] };

declare 'MapStringAgentsSpec',
    as HashRef[AgentsSpec()];

declare 'AgentSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistRequest::AgentsSpec::AgentSpec'];

coerce 'AgentSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistRequest::AgentsSpec::AgentSpec'->new($_) };

declare 'RepeatedAgentSpec',
    as ArrayRef[AgentSpec()];

coerce 'RepeatedAgentSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistRequest::AgentsSpec::AgentSpec'->new($_) } @$_ ] };

declare 'MapStringAgentSpec',
    as HashRef[AgentSpec()];

declare 'ToolsSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistRequest::ToolsSpec'];

coerce 'ToolsSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistRequest::ToolsSpec'->new($_) };

declare 'RepeatedToolsSpec',
    as ArrayRef[ToolsSpec()];

coerce 'RepeatedToolsSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistRequest::ToolsSpec'->new($_) } @$_ ] };

declare 'MapStringToolsSpec',
    as HashRef[ToolsSpec()];

declare 'VertexAiSearchSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistRequest::ToolsSpec::VertexAiSearchSpec'];

coerce 'VertexAiSearchSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistRequest::ToolsSpec::VertexAiSearchSpec'->new($_) };

declare 'RepeatedVertexAiSearchSpec',
    as ArrayRef[VertexAiSearchSpec()];

coerce 'RepeatedVertexAiSearchSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistRequest::ToolsSpec::VertexAiSearchSpec'->new($_) } @$_ ] };

declare 'MapStringVertexAiSearchSpec',
    as HashRef[VertexAiSearchSpec()];

declare 'WebGroundingSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistRequest::ToolsSpec::WebGroundingSpec'];

coerce 'WebGroundingSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistRequest::ToolsSpec::WebGroundingSpec'->new($_) };

declare 'RepeatedWebGroundingSpec',
    as ArrayRef[WebGroundingSpec()];

coerce 'RepeatedWebGroundingSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistRequest::ToolsSpec::WebGroundingSpec'->new($_) } @$_ ] };

declare 'MapStringWebGroundingSpec',
    as HashRef[WebGroundingSpec()];

declare 'ImageGenerationSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistRequest::ToolsSpec::ImageGenerationSpec'];

coerce 'ImageGenerationSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistRequest::ToolsSpec::ImageGenerationSpec'->new($_) };

declare 'RepeatedImageGenerationSpec',
    as ArrayRef[ImageGenerationSpec()];

coerce 'RepeatedImageGenerationSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistRequest::ToolsSpec::ImageGenerationSpec'->new($_) } @$_ ] };

declare 'MapStringImageGenerationSpec',
    as HashRef[ImageGenerationSpec()];

declare 'VideoGenerationSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistRequest::ToolsSpec::VideoGenerationSpec'];

coerce 'VideoGenerationSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistRequest::ToolsSpec::VideoGenerationSpec'->new($_) };

declare 'RepeatedVideoGenerationSpec',
    as ArrayRef[VideoGenerationSpec()];

coerce 'RepeatedVideoGenerationSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistRequest::ToolsSpec::VideoGenerationSpec'->new($_) } @$_ ] };

declare 'MapStringVideoGenerationSpec',
    as HashRef[VideoGenerationSpec()];

declare 'GenerationSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistRequest::GenerationSpec'];

coerce 'GenerationSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistRequest::GenerationSpec'->new($_) };

declare 'RepeatedGenerationSpec',
    as ArrayRef[GenerationSpec()];

coerce 'RepeatedGenerationSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistRequest::GenerationSpec'->new($_) } @$_ ] };

declare 'MapStringGenerationSpec',
    as HashRef[GenerationSpec()];

declare 'StreamAssistResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistResponse'];

coerce 'StreamAssistResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistResponse'->new($_) };

declare 'RepeatedStreamAssistResponse',
    as ArrayRef[StreamAssistResponse()];

coerce 'RepeatedStreamAssistResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistResponse'->new($_) } @$_ ] };

declare 'MapStringStreamAssistResponse',
    as HashRef[StreamAssistResponse()];

declare 'SessionInfo',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistResponse::SessionInfo'];

coerce 'SessionInfo',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistResponse::SessionInfo'->new($_) };

declare 'RepeatedSessionInfo',
    as ArrayRef[SessionInfo()];

coerce 'RepeatedSessionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistResponse::SessionInfo'->new($_) } @$_ ] };

declare 'MapStringSessionInfo',
    as HashRef[SessionInfo()];

declare 'InvokedSkill',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistResponse::InvokedSkill'];

coerce 'InvokedSkill',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistResponse::InvokedSkill'->new($_) };

declare 'RepeatedInvokedSkill',
    as ArrayRef[InvokedSkill()];

coerce 'RepeatedInvokedSkill',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistResponse::InvokedSkill'->new($_) } @$_ ] };

declare 'MapStringInvokedSkill',
    as HashRef[InvokedSkill()];

declare 'ConnectorAuthError',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistResponse::ConnectorAuthError'];

coerce 'ConnectorAuthError',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistResponse::ConnectorAuthError'->new($_) };

declare 'RepeatedConnectorAuthError',
    as ArrayRef[ConnectorAuthError()];

coerce 'RepeatedConnectorAuthError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::AssistantService::StreamAssistResponse::ConnectorAuthError'->new($_) } @$_ ] };

declare 'MapStringConnectorAuthError',
    as HashRef[ConnectorAuthError()];

declare 'CreateAssistantRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::AssistantService::CreateAssistantRequest'];

coerce 'CreateAssistantRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::AssistantService::CreateAssistantRequest'->new($_) };

declare 'RepeatedCreateAssistantRequest',
    as ArrayRef[CreateAssistantRequest()];

coerce 'RepeatedCreateAssistantRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::AssistantService::CreateAssistantRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAssistantRequest',
    as HashRef[CreateAssistantRequest()];

declare 'DeleteAssistantRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::AssistantService::DeleteAssistantRequest'];

coerce 'DeleteAssistantRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::AssistantService::DeleteAssistantRequest'->new($_) };

declare 'RepeatedDeleteAssistantRequest',
    as ArrayRef[DeleteAssistantRequest()];

coerce 'RepeatedDeleteAssistantRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::AssistantService::DeleteAssistantRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAssistantRequest',
    as HashRef[DeleteAssistantRequest()];

declare 'GetAssistantRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::AssistantService::GetAssistantRequest'];

coerce 'GetAssistantRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::AssistantService::GetAssistantRequest'->new($_) };

declare 'RepeatedGetAssistantRequest',
    as ArrayRef[GetAssistantRequest()];

coerce 'RepeatedGetAssistantRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::AssistantService::GetAssistantRequest'->new($_) } @$_ ] };

declare 'MapStringGetAssistantRequest',
    as HashRef[GetAssistantRequest()];

declare 'ListAssistantsRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::AssistantService::ListAssistantsRequest'];

coerce 'ListAssistantsRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::AssistantService::ListAssistantsRequest'->new($_) };

declare 'RepeatedListAssistantsRequest',
    as ArrayRef[ListAssistantsRequest()];

coerce 'RepeatedListAssistantsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::AssistantService::ListAssistantsRequest'->new($_) } @$_ ] };

declare 'MapStringListAssistantsRequest',
    as HashRef[ListAssistantsRequest()];

declare 'ListAssistantsResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::AssistantService::ListAssistantsResponse'];

coerce 'ListAssistantsResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::AssistantService::ListAssistantsResponse'->new($_) };

declare 'RepeatedListAssistantsResponse',
    as ArrayRef[ListAssistantsResponse()];

coerce 'RepeatedListAssistantsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::AssistantService::ListAssistantsResponse'->new($_) } @$_ ] };

declare 'MapStringListAssistantsResponse',
    as HashRef[ListAssistantsResponse()];

declare 'UpdateAssistantRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::AssistantService::UpdateAssistantRequest'];

coerce 'UpdateAssistantRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::AssistantService::UpdateAssistantRequest'->new($_) };

declare 'RepeatedUpdateAssistantRequest',
    as ArrayRef[UpdateAssistantRequest()];

coerce 'RepeatedUpdateAssistantRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::AssistantService::UpdateAssistantRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAssistantRequest',
    as HashRef[UpdateAssistantRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1::AssistantService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
