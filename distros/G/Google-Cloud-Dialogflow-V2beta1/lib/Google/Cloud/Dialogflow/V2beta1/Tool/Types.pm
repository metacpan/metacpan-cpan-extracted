package Google::Cloud::Dialogflow::V2beta1::Tool::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateToolRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Tool::CreateToolRequest'];

coerce 'CreateToolRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Tool::CreateToolRequest'->new($_) };

declare 'RepeatedCreateToolRequest',
    as ArrayRef[CreateToolRequest()];

coerce 'RepeatedCreateToolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Tool::CreateToolRequest'->new($_) } @$_ ] };

declare 'MapStringCreateToolRequest',
    as HashRef[CreateToolRequest()];

declare 'GetToolRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Tool::GetToolRequest'];

coerce 'GetToolRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Tool::GetToolRequest'->new($_) };

declare 'RepeatedGetToolRequest',
    as ArrayRef[GetToolRequest()];

coerce 'RepeatedGetToolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Tool::GetToolRequest'->new($_) } @$_ ] };

declare 'MapStringGetToolRequest',
    as HashRef[GetToolRequest()];

declare 'ListToolsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Tool::ListToolsRequest'];

coerce 'ListToolsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Tool::ListToolsRequest'->new($_) };

declare 'RepeatedListToolsRequest',
    as ArrayRef[ListToolsRequest()];

coerce 'RepeatedListToolsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Tool::ListToolsRequest'->new($_) } @$_ ] };

declare 'MapStringListToolsRequest',
    as HashRef[ListToolsRequest()];

declare 'ListToolsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Tool::ListToolsResponse'];

coerce 'ListToolsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Tool::ListToolsResponse'->new($_) };

declare 'RepeatedListToolsResponse',
    as ArrayRef[ListToolsResponse()];

coerce 'RepeatedListToolsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Tool::ListToolsResponse'->new($_) } @$_ ] };

declare 'MapStringListToolsResponse',
    as HashRef[ListToolsResponse()];

declare 'DeleteToolRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Tool::DeleteToolRequest'];

coerce 'DeleteToolRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Tool::DeleteToolRequest'->new($_) };

declare 'RepeatedDeleteToolRequest',
    as ArrayRef[DeleteToolRequest()];

coerce 'RepeatedDeleteToolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Tool::DeleteToolRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteToolRequest',
    as HashRef[DeleteToolRequest()];

declare 'UpdateToolRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Tool::UpdateToolRequest'];

coerce 'UpdateToolRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Tool::UpdateToolRequest'->new($_) };

declare 'RepeatedUpdateToolRequest',
    as ArrayRef[UpdateToolRequest()];

coerce 'RepeatedUpdateToolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Tool::UpdateToolRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateToolRequest',
    as HashRef[UpdateToolRequest()];

declare 'Tool',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Tool::Tool'];

coerce 'Tool',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool'->new($_) };

declare 'RepeatedTool',
    as ArrayRef[Tool()];

coerce 'RepeatedTool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool'->new($_) } @$_ ] };

declare 'MapStringTool',
    as HashRef[Tool()];

declare 'ConfirmationRequirement',
    as (Int | Str);

declare 'MethodType',
    as (Int | Str);

declare 'ExtensionTool',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Tool::Tool::ExtensionTool'];

coerce 'ExtensionTool',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool::ExtensionTool'->new($_) };

declare 'RepeatedExtensionTool',
    as ArrayRef[ExtensionTool()];

coerce 'RepeatedExtensionTool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool::ExtensionTool'->new($_) } @$_ ] };

declare 'MapStringExtensionTool',
    as HashRef[ExtensionTool()];

declare 'FunctionTool',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Tool::Tool::FunctionTool'];

coerce 'FunctionTool',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool::FunctionTool'->new($_) };

declare 'RepeatedFunctionTool',
    as ArrayRef[FunctionTool()];

coerce 'RepeatedFunctionTool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool::FunctionTool'->new($_) } @$_ ] };

declare 'MapStringFunctionTool',
    as HashRef[FunctionTool()];

declare 'OpenApiTool',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Tool::Tool::OpenApiTool'];

coerce 'OpenApiTool',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool::OpenApiTool'->new($_) };

declare 'RepeatedOpenApiTool',
    as ArrayRef[OpenApiTool()];

coerce 'RepeatedOpenApiTool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool::OpenApiTool'->new($_) } @$_ ] };

declare 'MapStringOpenApiTool',
    as HashRef[OpenApiTool()];

declare 'ConnectorTool',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Tool::Tool::ConnectorTool'];

coerce 'ConnectorTool',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool::ConnectorTool'->new($_) };

declare 'RepeatedConnectorTool',
    as ArrayRef[ConnectorTool()];

coerce 'RepeatedConnectorTool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool::ConnectorTool'->new($_) } @$_ ] };

declare 'MapStringConnectorTool',
    as HashRef[ConnectorTool()];

declare 'Action',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Tool::Tool::ConnectorTool::Action'];

coerce 'Action',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool::ConnectorTool::Action'->new($_) };

declare 'RepeatedAction',
    as ArrayRef[Action()];

coerce 'RepeatedAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool::ConnectorTool::Action'->new($_) } @$_ ] };

declare 'MapStringAction',
    as HashRef[Action()];

declare 'EntityOperation',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Tool::Tool::ConnectorTool::Action::EntityOperation'];

coerce 'EntityOperation',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool::ConnectorTool::Action::EntityOperation'->new($_) };

declare 'RepeatedEntityOperation',
    as ArrayRef[EntityOperation()];

coerce 'RepeatedEntityOperation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool::ConnectorTool::Action::EntityOperation'->new($_) } @$_ ] };

declare 'MapStringEntityOperation',
    as HashRef[EntityOperation()];

declare 'OperationType',
    as (Int | Str);

declare 'Authentication',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Tool::Tool::Authentication'];

coerce 'Authentication',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool::Authentication'->new($_) };

declare 'RepeatedAuthentication',
    as ArrayRef[Authentication()];

coerce 'RepeatedAuthentication',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool::Authentication'->new($_) } @$_ ] };

declare 'MapStringAuthentication',
    as HashRef[Authentication()];

declare 'RequestLocation',
    as (Int | Str);

declare 'ApiKeyConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Tool::Tool::Authentication::ApiKeyConfig'];

coerce 'ApiKeyConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool::Authentication::ApiKeyConfig'->new($_) };

declare 'RepeatedApiKeyConfig',
    as ArrayRef[ApiKeyConfig()];

coerce 'RepeatedApiKeyConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool::Authentication::ApiKeyConfig'->new($_) } @$_ ] };

declare 'MapStringApiKeyConfig',
    as HashRef[ApiKeyConfig()];

declare 'OAuthConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Tool::Tool::Authentication::OAuthConfig'];

coerce 'OAuthConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool::Authentication::OAuthConfig'->new($_) };

declare 'RepeatedOAuthConfig',
    as ArrayRef[OAuthConfig()];

coerce 'RepeatedOAuthConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool::Authentication::OAuthConfig'->new($_) } @$_ ] };

declare 'MapStringOAuthConfig',
    as HashRef[OAuthConfig()];

declare 'OauthGrantType',
    as (Int | Str);

declare 'ServiceAgentAuthConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Tool::Tool::Authentication::ServiceAgentAuthConfig'];

coerce 'ServiceAgentAuthConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool::Authentication::ServiceAgentAuthConfig'->new($_) };

declare 'RepeatedServiceAgentAuthConfig',
    as ArrayRef[ServiceAgentAuthConfig()];

coerce 'RepeatedServiceAgentAuthConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool::Authentication::ServiceAgentAuthConfig'->new($_) } @$_ ] };

declare 'MapStringServiceAgentAuthConfig',
    as HashRef[ServiceAgentAuthConfig()];

declare 'ServiceAgentAuth',
    as (Int | Str);

declare 'BearerTokenConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Tool::Tool::Authentication::BearerTokenConfig'];

coerce 'BearerTokenConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool::Authentication::BearerTokenConfig'->new($_) };

declare 'RepeatedBearerTokenConfig',
    as ArrayRef[BearerTokenConfig()];

coerce 'RepeatedBearerTokenConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool::Authentication::BearerTokenConfig'->new($_) } @$_ ] };

declare 'MapStringBearerTokenConfig',
    as HashRef[BearerTokenConfig()];

declare 'TLSConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Tool::Tool::TLSConfig'];

coerce 'TLSConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool::TLSConfig'->new($_) };

declare 'RepeatedTLSConfig',
    as ArrayRef[TLSConfig()];

coerce 'RepeatedTLSConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool::TLSConfig'->new($_) } @$_ ] };

declare 'MapStringTLSConfig',
    as HashRef[TLSConfig()];

declare 'CACert',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Tool::Tool::TLSConfig::CACert'];

coerce 'CACert',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool::TLSConfig::CACert'->new($_) };

declare 'RepeatedCACert',
    as ArrayRef[CACert()];

coerce 'RepeatedCACert',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool::TLSConfig::CACert'->new($_) } @$_ ] };

declare 'MapStringCACert',
    as HashRef[CACert()];

declare 'ServiceDirectoryConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Tool::Tool::ServiceDirectoryConfig'];

coerce 'ServiceDirectoryConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool::ServiceDirectoryConfig'->new($_) };

declare 'RepeatedServiceDirectoryConfig',
    as ArrayRef[ServiceDirectoryConfig()];

coerce 'RepeatedServiceDirectoryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool::ServiceDirectoryConfig'->new($_) } @$_ ] };

declare 'MapStringServiceDirectoryConfig',
    as HashRef[ServiceDirectoryConfig()];

declare 'ActionConfirmationRequirementEntry',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Tool::Tool::ActionConfirmationRequirementEntry'];

coerce 'ActionConfirmationRequirementEntry',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool::ActionConfirmationRequirementEntry'->new($_) };

declare 'RepeatedActionConfirmationRequirementEntry',
    as ArrayRef[ActionConfirmationRequirementEntry()];

coerce 'RepeatedActionConfirmationRequirementEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool::ActionConfirmationRequirementEntry'->new($_) } @$_ ] };

declare 'MapStringActionConfirmationRequirementEntry',
    as HashRef[ActionConfirmationRequirementEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::Tool::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
