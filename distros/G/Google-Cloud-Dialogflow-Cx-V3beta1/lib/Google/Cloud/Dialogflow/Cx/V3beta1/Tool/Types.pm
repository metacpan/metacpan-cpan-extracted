package Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateToolRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::CreateToolRequest'];

coerce 'CreateToolRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::CreateToolRequest'->new($_) };

declare 'RepeatedCreateToolRequest',
    as ArrayRef[CreateToolRequest()];

coerce 'RepeatedCreateToolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::CreateToolRequest'->new($_) } @$_ ] };

declare 'MapStringCreateToolRequest',
    as HashRef[CreateToolRequest()];

declare 'ListToolsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::ListToolsRequest'];

coerce 'ListToolsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::ListToolsRequest'->new($_) };

declare 'RepeatedListToolsRequest',
    as ArrayRef[ListToolsRequest()];

coerce 'RepeatedListToolsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::ListToolsRequest'->new($_) } @$_ ] };

declare 'MapStringListToolsRequest',
    as HashRef[ListToolsRequest()];

declare 'ListToolsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::ListToolsResponse'];

coerce 'ListToolsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::ListToolsResponse'->new($_) };

declare 'RepeatedListToolsResponse',
    as ArrayRef[ListToolsResponse()];

coerce 'RepeatedListToolsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::ListToolsResponse'->new($_) } @$_ ] };

declare 'MapStringListToolsResponse',
    as HashRef[ListToolsResponse()];

declare 'GetToolRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::GetToolRequest'];

coerce 'GetToolRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::GetToolRequest'->new($_) };

declare 'RepeatedGetToolRequest',
    as ArrayRef[GetToolRequest()];

coerce 'RepeatedGetToolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::GetToolRequest'->new($_) } @$_ ] };

declare 'MapStringGetToolRequest',
    as HashRef[GetToolRequest()];

declare 'ExportToolsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::ExportToolsRequest'];

coerce 'ExportToolsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::ExportToolsRequest'->new($_) };

declare 'RepeatedExportToolsRequest',
    as ArrayRef[ExportToolsRequest()];

coerce 'RepeatedExportToolsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::ExportToolsRequest'->new($_) } @$_ ] };

declare 'MapStringExportToolsRequest',
    as HashRef[ExportToolsRequest()];

declare 'DataFormat',
    as (Int | Str);

declare 'ExportToolsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::ExportToolsResponse'];

coerce 'ExportToolsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::ExportToolsResponse'->new($_) };

declare 'RepeatedExportToolsResponse',
    as ArrayRef[ExportToolsResponse()];

coerce 'RepeatedExportToolsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::ExportToolsResponse'->new($_) } @$_ ] };

declare 'MapStringExportToolsResponse',
    as HashRef[ExportToolsResponse()];

declare 'UpdateToolRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::UpdateToolRequest'];

coerce 'UpdateToolRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::UpdateToolRequest'->new($_) };

declare 'RepeatedUpdateToolRequest',
    as ArrayRef[UpdateToolRequest()];

coerce 'RepeatedUpdateToolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::UpdateToolRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateToolRequest',
    as HashRef[UpdateToolRequest()];

declare 'DeleteToolRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::DeleteToolRequest'];

coerce 'DeleteToolRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::DeleteToolRequest'->new($_) };

declare 'RepeatedDeleteToolRequest',
    as ArrayRef[DeleteToolRequest()];

coerce 'RepeatedDeleteToolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::DeleteToolRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteToolRequest',
    as HashRef[DeleteToolRequest()];

declare 'Tool',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool'];

coerce 'Tool',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool'->new($_) };

declare 'RepeatedTool',
    as ArrayRef[Tool()];

coerce 'RepeatedTool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool'->new($_) } @$_ ] };

declare 'MapStringTool',
    as HashRef[Tool()];

declare 'ToolType',
    as (Int | Str);

declare 'OpenApiTool',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::OpenApiTool'];

coerce 'OpenApiTool',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::OpenApiTool'->new($_) };

declare 'RepeatedOpenApiTool',
    as ArrayRef[OpenApiTool()];

coerce 'RepeatedOpenApiTool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::OpenApiTool'->new($_) } @$_ ] };

declare 'MapStringOpenApiTool',
    as HashRef[OpenApiTool()];

declare 'DataStoreTool',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::DataStoreTool'];

coerce 'DataStoreTool',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::DataStoreTool'->new($_) };

declare 'RepeatedDataStoreTool',
    as ArrayRef[DataStoreTool()];

coerce 'RepeatedDataStoreTool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::DataStoreTool'->new($_) } @$_ ] };

declare 'MapStringDataStoreTool',
    as HashRef[DataStoreTool()];

declare 'FallbackPrompt',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::DataStoreTool::FallbackPrompt'];

coerce 'FallbackPrompt',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::DataStoreTool::FallbackPrompt'->new($_) };

declare 'RepeatedFallbackPrompt',
    as ArrayRef[FallbackPrompt()];

coerce 'RepeatedFallbackPrompt',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::DataStoreTool::FallbackPrompt'->new($_) } @$_ ] };

declare 'MapStringFallbackPrompt',
    as HashRef[FallbackPrompt()];

declare 'ExtensionTool',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::ExtensionTool'];

coerce 'ExtensionTool',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::ExtensionTool'->new($_) };

declare 'RepeatedExtensionTool',
    as ArrayRef[ExtensionTool()];

coerce 'RepeatedExtensionTool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::ExtensionTool'->new($_) } @$_ ] };

declare 'MapStringExtensionTool',
    as HashRef[ExtensionTool()];

declare 'FunctionTool',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::FunctionTool'];

coerce 'FunctionTool',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::FunctionTool'->new($_) };

declare 'RepeatedFunctionTool',
    as ArrayRef[FunctionTool()];

coerce 'RepeatedFunctionTool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::FunctionTool'->new($_) } @$_ ] };

declare 'MapStringFunctionTool',
    as HashRef[FunctionTool()];

declare 'ConnectorTool',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::ConnectorTool'];

coerce 'ConnectorTool',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::ConnectorTool'->new($_) };

declare 'RepeatedConnectorTool',
    as ArrayRef[ConnectorTool()];

coerce 'RepeatedConnectorTool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::ConnectorTool'->new($_) } @$_ ] };

declare 'MapStringConnectorTool',
    as HashRef[ConnectorTool()];

declare 'Action',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::ConnectorTool::Action'];

coerce 'Action',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::ConnectorTool::Action'->new($_) };

declare 'RepeatedAction',
    as ArrayRef[Action()];

coerce 'RepeatedAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::ConnectorTool::Action'->new($_) } @$_ ] };

declare 'MapStringAction',
    as HashRef[Action()];

declare 'EntityOperation',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::ConnectorTool::Action::EntityOperation'];

coerce 'EntityOperation',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::ConnectorTool::Action::EntityOperation'->new($_) };

declare 'RepeatedEntityOperation',
    as ArrayRef[EntityOperation()];

coerce 'RepeatedEntityOperation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::ConnectorTool::Action::EntityOperation'->new($_) } @$_ ] };

declare 'MapStringEntityOperation',
    as HashRef[EntityOperation()];

declare 'OperationType',
    as (Int | Str);

declare 'Authentication',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::Authentication'];

coerce 'Authentication',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::Authentication'->new($_) };

declare 'RepeatedAuthentication',
    as ArrayRef[Authentication()];

coerce 'RepeatedAuthentication',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::Authentication'->new($_) } @$_ ] };

declare 'MapStringAuthentication',
    as HashRef[Authentication()];

declare 'RequestLocation',
    as (Int | Str);

declare 'ApiKeyConfig',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::Authentication::ApiKeyConfig'];

coerce 'ApiKeyConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::Authentication::ApiKeyConfig'->new($_) };

declare 'RepeatedApiKeyConfig',
    as ArrayRef[ApiKeyConfig()];

coerce 'RepeatedApiKeyConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::Authentication::ApiKeyConfig'->new($_) } @$_ ] };

declare 'MapStringApiKeyConfig',
    as HashRef[ApiKeyConfig()];

declare 'OAuthConfig',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::Authentication::OAuthConfig'];

coerce 'OAuthConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::Authentication::OAuthConfig'->new($_) };

declare 'RepeatedOAuthConfig',
    as ArrayRef[OAuthConfig()];

coerce 'RepeatedOAuthConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::Authentication::OAuthConfig'->new($_) } @$_ ] };

declare 'MapStringOAuthConfig',
    as HashRef[OAuthConfig()];

declare 'OauthGrantType',
    as (Int | Str);

declare 'ServiceAgentAuthConfig',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::Authentication::ServiceAgentAuthConfig'];

coerce 'ServiceAgentAuthConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::Authentication::ServiceAgentAuthConfig'->new($_) };

declare 'RepeatedServiceAgentAuthConfig',
    as ArrayRef[ServiceAgentAuthConfig()];

coerce 'RepeatedServiceAgentAuthConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::Authentication::ServiceAgentAuthConfig'->new($_) } @$_ ] };

declare 'MapStringServiceAgentAuthConfig',
    as HashRef[ServiceAgentAuthConfig()];

declare 'ServiceAgentAuth',
    as (Int | Str);

declare 'BearerTokenConfig',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::Authentication::BearerTokenConfig'];

coerce 'BearerTokenConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::Authentication::BearerTokenConfig'->new($_) };

declare 'RepeatedBearerTokenConfig',
    as ArrayRef[BearerTokenConfig()];

coerce 'RepeatedBearerTokenConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::Authentication::BearerTokenConfig'->new($_) } @$_ ] };

declare 'MapStringBearerTokenConfig',
    as HashRef[BearerTokenConfig()];

declare 'ServiceAccountAuthConfig',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::Authentication::ServiceAccountAuthConfig'];

coerce 'ServiceAccountAuthConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::Authentication::ServiceAccountAuthConfig'->new($_) };

declare 'RepeatedServiceAccountAuthConfig',
    as ArrayRef[ServiceAccountAuthConfig()];

coerce 'RepeatedServiceAccountAuthConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::Authentication::ServiceAccountAuthConfig'->new($_) } @$_ ] };

declare 'MapStringServiceAccountAuthConfig',
    as HashRef[ServiceAccountAuthConfig()];

declare 'TLSConfig',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::TLSConfig'];

coerce 'TLSConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::TLSConfig'->new($_) };

declare 'RepeatedTLSConfig',
    as ArrayRef[TLSConfig()];

coerce 'RepeatedTLSConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::TLSConfig'->new($_) } @$_ ] };

declare 'MapStringTLSConfig',
    as HashRef[TLSConfig()];

declare 'CACert',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::TLSConfig::CACert'];

coerce 'CACert',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::TLSConfig::CACert'->new($_) };

declare 'RepeatedCACert',
    as ArrayRef[CACert()];

coerce 'RepeatedCACert',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::TLSConfig::CACert'->new($_) } @$_ ] };

declare 'MapStringCACert',
    as HashRef[CACert()];

declare 'ServiceDirectoryConfig',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::ServiceDirectoryConfig'];

coerce 'ServiceDirectoryConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::ServiceDirectoryConfig'->new($_) };

declare 'RepeatedServiceDirectoryConfig',
    as ArrayRef[ServiceDirectoryConfig()];

coerce 'RepeatedServiceDirectoryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::ServiceDirectoryConfig'->new($_) } @$_ ] };

declare 'MapStringServiceDirectoryConfig',
    as HashRef[ServiceDirectoryConfig()];

declare 'EndUserAuthConfig',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::EndUserAuthConfig'];

coerce 'EndUserAuthConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::EndUserAuthConfig'->new($_) };

declare 'RepeatedEndUserAuthConfig',
    as ArrayRef[EndUserAuthConfig()];

coerce 'RepeatedEndUserAuthConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::EndUserAuthConfig'->new($_) } @$_ ] };

declare 'MapStringEndUserAuthConfig',
    as HashRef[EndUserAuthConfig()];

declare 'Oauth2AuthCodeConfig',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::EndUserAuthConfig::Oauth2AuthCodeConfig'];

coerce 'Oauth2AuthCodeConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::EndUserAuthConfig::Oauth2AuthCodeConfig'->new($_) };

declare 'RepeatedOauth2AuthCodeConfig',
    as ArrayRef[Oauth2AuthCodeConfig()];

coerce 'RepeatedOauth2AuthCodeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::EndUserAuthConfig::Oauth2AuthCodeConfig'->new($_) } @$_ ] };

declare 'MapStringOauth2AuthCodeConfig',
    as HashRef[Oauth2AuthCodeConfig()];

declare 'Oauth2JwtBearerConfig',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::EndUserAuthConfig::Oauth2JwtBearerConfig'];

coerce 'Oauth2JwtBearerConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::EndUserAuthConfig::Oauth2JwtBearerConfig'->new($_) };

declare 'RepeatedOauth2JwtBearerConfig',
    as ArrayRef[Oauth2JwtBearerConfig()];

coerce 'RepeatedOauth2JwtBearerConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Tool::EndUserAuthConfig::Oauth2JwtBearerConfig'->new($_) } @$_ ] };

declare 'MapStringOauth2JwtBearerConfig',
    as HashRef[Oauth2JwtBearerConfig()];

declare 'ListToolVersionsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::ListToolVersionsRequest'];

coerce 'ListToolVersionsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::ListToolVersionsRequest'->new($_) };

declare 'RepeatedListToolVersionsRequest',
    as ArrayRef[ListToolVersionsRequest()];

coerce 'RepeatedListToolVersionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::ListToolVersionsRequest'->new($_) } @$_ ] };

declare 'MapStringListToolVersionsRequest',
    as HashRef[ListToolVersionsRequest()];

declare 'ListToolVersionsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::ListToolVersionsResponse'];

coerce 'ListToolVersionsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::ListToolVersionsResponse'->new($_) };

declare 'RepeatedListToolVersionsResponse',
    as ArrayRef[ListToolVersionsResponse()];

coerce 'RepeatedListToolVersionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::ListToolVersionsResponse'->new($_) } @$_ ] };

declare 'MapStringListToolVersionsResponse',
    as HashRef[ListToolVersionsResponse()];

declare 'CreateToolVersionRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::CreateToolVersionRequest'];

coerce 'CreateToolVersionRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::CreateToolVersionRequest'->new($_) };

declare 'RepeatedCreateToolVersionRequest',
    as ArrayRef[CreateToolVersionRequest()];

coerce 'RepeatedCreateToolVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::CreateToolVersionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateToolVersionRequest',
    as HashRef[CreateToolVersionRequest()];

declare 'GetToolVersionRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::GetToolVersionRequest'];

coerce 'GetToolVersionRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::GetToolVersionRequest'->new($_) };

declare 'RepeatedGetToolVersionRequest',
    as ArrayRef[GetToolVersionRequest()];

coerce 'RepeatedGetToolVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::GetToolVersionRequest'->new($_) } @$_ ] };

declare 'MapStringGetToolVersionRequest',
    as HashRef[GetToolVersionRequest()];

declare 'DeleteToolVersionRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::DeleteToolVersionRequest'];

coerce 'DeleteToolVersionRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::DeleteToolVersionRequest'->new($_) };

declare 'RepeatedDeleteToolVersionRequest',
    as ArrayRef[DeleteToolVersionRequest()];

coerce 'RepeatedDeleteToolVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::DeleteToolVersionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteToolVersionRequest',
    as HashRef[DeleteToolVersionRequest()];

declare 'RestoreToolVersionRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::RestoreToolVersionRequest'];

coerce 'RestoreToolVersionRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::RestoreToolVersionRequest'->new($_) };

declare 'RepeatedRestoreToolVersionRequest',
    as ArrayRef[RestoreToolVersionRequest()];

coerce 'RepeatedRestoreToolVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::RestoreToolVersionRequest'->new($_) } @$_ ] };

declare 'MapStringRestoreToolVersionRequest',
    as HashRef[RestoreToolVersionRequest()];

declare 'RestoreToolVersionResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::RestoreToolVersionResponse'];

coerce 'RestoreToolVersionResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::RestoreToolVersionResponse'->new($_) };

declare 'RepeatedRestoreToolVersionResponse',
    as ArrayRef[RestoreToolVersionResponse()];

coerce 'RepeatedRestoreToolVersionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::RestoreToolVersionResponse'->new($_) } @$_ ] };

declare 'MapStringRestoreToolVersionResponse',
    as HashRef[RestoreToolVersionResponse()];

declare 'ToolVersion',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::ToolVersion'];

coerce 'ToolVersion',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::ToolVersion'->new($_) };

declare 'RepeatedToolVersion',
    as ArrayRef[ToolVersion()];

coerce 'RepeatedToolVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::ToolVersion'->new($_) } @$_ ] };

declare 'MapStringToolVersion',
    as HashRef[ToolVersion()];

declare 'ExportToolsMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Tool::ExportToolsMetadata'];

coerce 'ExportToolsMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::ExportToolsMetadata'->new($_) };

declare 'RepeatedExportToolsMetadata',
    as ArrayRef[ExportToolsMetadata()];

coerce 'RepeatedExportToolsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Tool::ExportToolsMetadata'->new($_) } @$_ ] };

declare 'MapStringExportToolsMetadata',
    as HashRef[ExportToolsMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::Tool::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
