package Google::Cloud::Ces::V1::AgentService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListAppsRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::ListAppsRequest'];

coerce 'ListAppsRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::ListAppsRequest'->new($_) };

declare 'RepeatedListAppsRequest',
    as ArrayRef[ListAppsRequest()];

coerce 'RepeatedListAppsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::ListAppsRequest'->new($_) } @$_ ] };

declare 'MapStringListAppsRequest',
    as HashRef[ListAppsRequest()];

declare 'ListAppsResponse',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::ListAppsResponse'];

coerce 'ListAppsResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::ListAppsResponse'->new($_) };

declare 'RepeatedListAppsResponse',
    as ArrayRef[ListAppsResponse()];

coerce 'RepeatedListAppsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::ListAppsResponse'->new($_) } @$_ ] };

declare 'MapStringListAppsResponse',
    as HashRef[ListAppsResponse()];

declare 'GetAppRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::GetAppRequest'];

coerce 'GetAppRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::GetAppRequest'->new($_) };

declare 'RepeatedGetAppRequest',
    as ArrayRef[GetAppRequest()];

coerce 'RepeatedGetAppRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::GetAppRequest'->new($_) } @$_ ] };

declare 'MapStringGetAppRequest',
    as HashRef[GetAppRequest()];

declare 'CreateAppRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::CreateAppRequest'];

coerce 'CreateAppRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::CreateAppRequest'->new($_) };

declare 'RepeatedCreateAppRequest',
    as ArrayRef[CreateAppRequest()];

coerce 'RepeatedCreateAppRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::CreateAppRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAppRequest',
    as HashRef[CreateAppRequest()];

declare 'UpdateAppRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::UpdateAppRequest'];

coerce 'UpdateAppRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::UpdateAppRequest'->new($_) };

declare 'RepeatedUpdateAppRequest',
    as ArrayRef[UpdateAppRequest()];

coerce 'RepeatedUpdateAppRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::UpdateAppRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAppRequest',
    as HashRef[UpdateAppRequest()];

declare 'DeleteAppRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::DeleteAppRequest'];

coerce 'DeleteAppRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::DeleteAppRequest'->new($_) };

declare 'RepeatedDeleteAppRequest',
    as ArrayRef[DeleteAppRequest()];

coerce 'RepeatedDeleteAppRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::DeleteAppRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAppRequest',
    as HashRef[DeleteAppRequest()];

declare 'ExportAppRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::ExportAppRequest'];

coerce 'ExportAppRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::ExportAppRequest'->new($_) };

declare 'RepeatedExportAppRequest',
    as ArrayRef[ExportAppRequest()];

coerce 'RepeatedExportAppRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::ExportAppRequest'->new($_) } @$_ ] };

declare 'MapStringExportAppRequest',
    as HashRef[ExportAppRequest()];

declare 'ExportFormat',
    as (Int | Str);

declare 'ExportAppResponse',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::ExportAppResponse'];

coerce 'ExportAppResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::ExportAppResponse'->new($_) };

declare 'RepeatedExportAppResponse',
    as ArrayRef[ExportAppResponse()];

coerce 'RepeatedExportAppResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::ExportAppResponse'->new($_) } @$_ ] };

declare 'MapStringExportAppResponse',
    as HashRef[ExportAppResponse()];

declare 'ImportAppRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::ImportAppRequest'];

coerce 'ImportAppRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::ImportAppRequest'->new($_) };

declare 'RepeatedImportAppRequest',
    as ArrayRef[ImportAppRequest()];

coerce 'RepeatedImportAppRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::ImportAppRequest'->new($_) } @$_ ] };

declare 'MapStringImportAppRequest',
    as HashRef[ImportAppRequest()];

declare 'ImportOptions',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::ImportAppRequest::ImportOptions'];

coerce 'ImportOptions',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::ImportAppRequest::ImportOptions'->new($_) };

declare 'RepeatedImportOptions',
    as ArrayRef[ImportOptions()];

coerce 'RepeatedImportOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::ImportAppRequest::ImportOptions'->new($_) } @$_ ] };

declare 'MapStringImportOptions',
    as HashRef[ImportOptions()];

declare 'ConflictResolutionStrategy',
    as (Int | Str);

declare 'ImportAppResponse',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::ImportAppResponse'];

coerce 'ImportAppResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::ImportAppResponse'->new($_) };

declare 'RepeatedImportAppResponse',
    as ArrayRef[ImportAppResponse()];

coerce 'RepeatedImportAppResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::ImportAppResponse'->new($_) } @$_ ] };

declare 'MapStringImportAppResponse',
    as HashRef[ImportAppResponse()];

declare 'ListAgentsRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::ListAgentsRequest'];

coerce 'ListAgentsRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::ListAgentsRequest'->new($_) };

declare 'RepeatedListAgentsRequest',
    as ArrayRef[ListAgentsRequest()];

coerce 'RepeatedListAgentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::ListAgentsRequest'->new($_) } @$_ ] };

declare 'MapStringListAgentsRequest',
    as HashRef[ListAgentsRequest()];

declare 'ListAgentsResponse',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::ListAgentsResponse'];

coerce 'ListAgentsResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::ListAgentsResponse'->new($_) };

declare 'RepeatedListAgentsResponse',
    as ArrayRef[ListAgentsResponse()];

coerce 'RepeatedListAgentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::ListAgentsResponse'->new($_) } @$_ ] };

declare 'MapStringListAgentsResponse',
    as HashRef[ListAgentsResponse()];

declare 'GetAgentRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::GetAgentRequest'];

coerce 'GetAgentRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::GetAgentRequest'->new($_) };

declare 'RepeatedGetAgentRequest',
    as ArrayRef[GetAgentRequest()];

coerce 'RepeatedGetAgentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::GetAgentRequest'->new($_) } @$_ ] };

declare 'MapStringGetAgentRequest',
    as HashRef[GetAgentRequest()];

declare 'CreateAgentRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::CreateAgentRequest'];

coerce 'CreateAgentRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::CreateAgentRequest'->new($_) };

declare 'RepeatedCreateAgentRequest',
    as ArrayRef[CreateAgentRequest()];

coerce 'RepeatedCreateAgentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::CreateAgentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAgentRequest',
    as HashRef[CreateAgentRequest()];

declare 'UpdateAgentRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::UpdateAgentRequest'];

coerce 'UpdateAgentRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::UpdateAgentRequest'->new($_) };

declare 'RepeatedUpdateAgentRequest',
    as ArrayRef[UpdateAgentRequest()];

coerce 'RepeatedUpdateAgentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::UpdateAgentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAgentRequest',
    as HashRef[UpdateAgentRequest()];

declare 'DeleteAgentRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::DeleteAgentRequest'];

coerce 'DeleteAgentRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::DeleteAgentRequest'->new($_) };

declare 'RepeatedDeleteAgentRequest',
    as ArrayRef[DeleteAgentRequest()];

coerce 'RepeatedDeleteAgentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::DeleteAgentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAgentRequest',
    as HashRef[DeleteAgentRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'ListExamplesRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::ListExamplesRequest'];

coerce 'ListExamplesRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::ListExamplesRequest'->new($_) };

declare 'RepeatedListExamplesRequest',
    as ArrayRef[ListExamplesRequest()];

coerce 'RepeatedListExamplesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::ListExamplesRequest'->new($_) } @$_ ] };

declare 'MapStringListExamplesRequest',
    as HashRef[ListExamplesRequest()];

declare 'ListExamplesResponse',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::ListExamplesResponse'];

coerce 'ListExamplesResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::ListExamplesResponse'->new($_) };

declare 'RepeatedListExamplesResponse',
    as ArrayRef[ListExamplesResponse()];

coerce 'RepeatedListExamplesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::ListExamplesResponse'->new($_) } @$_ ] };

declare 'MapStringListExamplesResponse',
    as HashRef[ListExamplesResponse()];

declare 'GetExampleRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::GetExampleRequest'];

coerce 'GetExampleRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::GetExampleRequest'->new($_) };

declare 'RepeatedGetExampleRequest',
    as ArrayRef[GetExampleRequest()];

coerce 'RepeatedGetExampleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::GetExampleRequest'->new($_) } @$_ ] };

declare 'MapStringGetExampleRequest',
    as HashRef[GetExampleRequest()];

declare 'CreateExampleRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::CreateExampleRequest'];

coerce 'CreateExampleRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::CreateExampleRequest'->new($_) };

declare 'RepeatedCreateExampleRequest',
    as ArrayRef[CreateExampleRequest()];

coerce 'RepeatedCreateExampleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::CreateExampleRequest'->new($_) } @$_ ] };

declare 'MapStringCreateExampleRequest',
    as HashRef[CreateExampleRequest()];

declare 'UpdateExampleRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::UpdateExampleRequest'];

coerce 'UpdateExampleRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::UpdateExampleRequest'->new($_) };

declare 'RepeatedUpdateExampleRequest',
    as ArrayRef[UpdateExampleRequest()];

coerce 'RepeatedUpdateExampleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::UpdateExampleRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateExampleRequest',
    as HashRef[UpdateExampleRequest()];

declare 'DeleteExampleRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::DeleteExampleRequest'];

coerce 'DeleteExampleRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::DeleteExampleRequest'->new($_) };

declare 'RepeatedDeleteExampleRequest',
    as ArrayRef[DeleteExampleRequest()];

coerce 'RepeatedDeleteExampleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::DeleteExampleRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteExampleRequest',
    as HashRef[DeleteExampleRequest()];

declare 'ListToolsRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::ListToolsRequest'];

coerce 'ListToolsRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::ListToolsRequest'->new($_) };

declare 'RepeatedListToolsRequest',
    as ArrayRef[ListToolsRequest()];

coerce 'RepeatedListToolsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::ListToolsRequest'->new($_) } @$_ ] };

declare 'MapStringListToolsRequest',
    as HashRef[ListToolsRequest()];

declare 'ListToolsResponse',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::ListToolsResponse'];

coerce 'ListToolsResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::ListToolsResponse'->new($_) };

declare 'RepeatedListToolsResponse',
    as ArrayRef[ListToolsResponse()];

coerce 'RepeatedListToolsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::ListToolsResponse'->new($_) } @$_ ] };

declare 'MapStringListToolsResponse',
    as HashRef[ListToolsResponse()];

declare 'GetToolRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::GetToolRequest'];

coerce 'GetToolRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::GetToolRequest'->new($_) };

declare 'RepeatedGetToolRequest',
    as ArrayRef[GetToolRequest()];

coerce 'RepeatedGetToolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::GetToolRequest'->new($_) } @$_ ] };

declare 'MapStringGetToolRequest',
    as HashRef[GetToolRequest()];

declare 'CreateToolRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::CreateToolRequest'];

coerce 'CreateToolRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::CreateToolRequest'->new($_) };

declare 'RepeatedCreateToolRequest',
    as ArrayRef[CreateToolRequest()];

coerce 'RepeatedCreateToolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::CreateToolRequest'->new($_) } @$_ ] };

declare 'MapStringCreateToolRequest',
    as HashRef[CreateToolRequest()];

declare 'UpdateToolRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::UpdateToolRequest'];

coerce 'UpdateToolRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::UpdateToolRequest'->new($_) };

declare 'RepeatedUpdateToolRequest',
    as ArrayRef[UpdateToolRequest()];

coerce 'RepeatedUpdateToolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::UpdateToolRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateToolRequest',
    as HashRef[UpdateToolRequest()];

declare 'DeleteToolRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::DeleteToolRequest'];

coerce 'DeleteToolRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::DeleteToolRequest'->new($_) };

declare 'RepeatedDeleteToolRequest',
    as ArrayRef[DeleteToolRequest()];

coerce 'RepeatedDeleteToolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::DeleteToolRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteToolRequest',
    as HashRef[DeleteToolRequest()];

declare 'ListConversationsRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::ListConversationsRequest'];

coerce 'ListConversationsRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::ListConversationsRequest'->new($_) };

declare 'RepeatedListConversationsRequest',
    as ArrayRef[ListConversationsRequest()];

coerce 'RepeatedListConversationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::ListConversationsRequest'->new($_) } @$_ ] };

declare 'MapStringListConversationsRequest',
    as HashRef[ListConversationsRequest()];

declare 'ListConversationsResponse',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::ListConversationsResponse'];

coerce 'ListConversationsResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::ListConversationsResponse'->new($_) };

declare 'RepeatedListConversationsResponse',
    as ArrayRef[ListConversationsResponse()];

coerce 'RepeatedListConversationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::ListConversationsResponse'->new($_) } @$_ ] };

declare 'MapStringListConversationsResponse',
    as HashRef[ListConversationsResponse()];

declare 'GetConversationRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::GetConversationRequest'];

coerce 'GetConversationRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::GetConversationRequest'->new($_) };

declare 'RepeatedGetConversationRequest',
    as ArrayRef[GetConversationRequest()];

coerce 'RepeatedGetConversationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::GetConversationRequest'->new($_) } @$_ ] };

declare 'MapStringGetConversationRequest',
    as HashRef[GetConversationRequest()];

declare 'DeleteConversationRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::DeleteConversationRequest'];

coerce 'DeleteConversationRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::DeleteConversationRequest'->new($_) };

declare 'RepeatedDeleteConversationRequest',
    as ArrayRef[DeleteConversationRequest()];

coerce 'RepeatedDeleteConversationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::DeleteConversationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteConversationRequest',
    as HashRef[DeleteConversationRequest()];

declare 'BatchDeleteConversationsRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::BatchDeleteConversationsRequest'];

coerce 'BatchDeleteConversationsRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::BatchDeleteConversationsRequest'->new($_) };

declare 'RepeatedBatchDeleteConversationsRequest',
    as ArrayRef[BatchDeleteConversationsRequest()];

coerce 'RepeatedBatchDeleteConversationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::BatchDeleteConversationsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchDeleteConversationsRequest',
    as HashRef[BatchDeleteConversationsRequest()];

declare 'BatchDeleteConversationsResponse',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::BatchDeleteConversationsResponse'];

coerce 'BatchDeleteConversationsResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::BatchDeleteConversationsResponse'->new($_) };

declare 'RepeatedBatchDeleteConversationsResponse',
    as ArrayRef[BatchDeleteConversationsResponse()];

coerce 'RepeatedBatchDeleteConversationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::BatchDeleteConversationsResponse'->new($_) } @$_ ] };

declare 'MapStringBatchDeleteConversationsResponse',
    as HashRef[BatchDeleteConversationsResponse()];

declare 'ListGuardrailsRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::ListGuardrailsRequest'];

coerce 'ListGuardrailsRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::ListGuardrailsRequest'->new($_) };

declare 'RepeatedListGuardrailsRequest',
    as ArrayRef[ListGuardrailsRequest()];

coerce 'RepeatedListGuardrailsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::ListGuardrailsRequest'->new($_) } @$_ ] };

declare 'MapStringListGuardrailsRequest',
    as HashRef[ListGuardrailsRequest()];

declare 'ListGuardrailsResponse',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::ListGuardrailsResponse'];

coerce 'ListGuardrailsResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::ListGuardrailsResponse'->new($_) };

declare 'RepeatedListGuardrailsResponse',
    as ArrayRef[ListGuardrailsResponse()];

coerce 'RepeatedListGuardrailsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::ListGuardrailsResponse'->new($_) } @$_ ] };

declare 'MapStringListGuardrailsResponse',
    as HashRef[ListGuardrailsResponse()];

declare 'GetGuardrailRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::GetGuardrailRequest'];

coerce 'GetGuardrailRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::GetGuardrailRequest'->new($_) };

declare 'RepeatedGetGuardrailRequest',
    as ArrayRef[GetGuardrailRequest()];

coerce 'RepeatedGetGuardrailRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::GetGuardrailRequest'->new($_) } @$_ ] };

declare 'MapStringGetGuardrailRequest',
    as HashRef[GetGuardrailRequest()];

declare 'CreateGuardrailRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::CreateGuardrailRequest'];

coerce 'CreateGuardrailRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::CreateGuardrailRequest'->new($_) };

declare 'RepeatedCreateGuardrailRequest',
    as ArrayRef[CreateGuardrailRequest()];

coerce 'RepeatedCreateGuardrailRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::CreateGuardrailRequest'->new($_) } @$_ ] };

declare 'MapStringCreateGuardrailRequest',
    as HashRef[CreateGuardrailRequest()];

declare 'UpdateGuardrailRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::UpdateGuardrailRequest'];

coerce 'UpdateGuardrailRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::UpdateGuardrailRequest'->new($_) };

declare 'RepeatedUpdateGuardrailRequest',
    as ArrayRef[UpdateGuardrailRequest()];

coerce 'RepeatedUpdateGuardrailRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::UpdateGuardrailRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateGuardrailRequest',
    as HashRef[UpdateGuardrailRequest()];

declare 'DeleteGuardrailRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::DeleteGuardrailRequest'];

coerce 'DeleteGuardrailRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::DeleteGuardrailRequest'->new($_) };

declare 'RepeatedDeleteGuardrailRequest',
    as ArrayRef[DeleteGuardrailRequest()];

coerce 'RepeatedDeleteGuardrailRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::DeleteGuardrailRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteGuardrailRequest',
    as HashRef[DeleteGuardrailRequest()];

declare 'ListDeploymentsRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::ListDeploymentsRequest'];

coerce 'ListDeploymentsRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::ListDeploymentsRequest'->new($_) };

declare 'RepeatedListDeploymentsRequest',
    as ArrayRef[ListDeploymentsRequest()];

coerce 'RepeatedListDeploymentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::ListDeploymentsRequest'->new($_) } @$_ ] };

declare 'MapStringListDeploymentsRequest',
    as HashRef[ListDeploymentsRequest()];

declare 'ListDeploymentsResponse',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::ListDeploymentsResponse'];

coerce 'ListDeploymentsResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::ListDeploymentsResponse'->new($_) };

declare 'RepeatedListDeploymentsResponse',
    as ArrayRef[ListDeploymentsResponse()];

coerce 'RepeatedListDeploymentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::ListDeploymentsResponse'->new($_) } @$_ ] };

declare 'MapStringListDeploymentsResponse',
    as HashRef[ListDeploymentsResponse()];

declare 'GetDeploymentRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::GetDeploymentRequest'];

coerce 'GetDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::GetDeploymentRequest'->new($_) };

declare 'RepeatedGetDeploymentRequest',
    as ArrayRef[GetDeploymentRequest()];

coerce 'RepeatedGetDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::GetDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringGetDeploymentRequest',
    as HashRef[GetDeploymentRequest()];

declare 'CreateDeploymentRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::CreateDeploymentRequest'];

coerce 'CreateDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::CreateDeploymentRequest'->new($_) };

declare 'RepeatedCreateDeploymentRequest',
    as ArrayRef[CreateDeploymentRequest()];

coerce 'RepeatedCreateDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::CreateDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDeploymentRequest',
    as HashRef[CreateDeploymentRequest()];

declare 'UpdateDeploymentRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::UpdateDeploymentRequest'];

coerce 'UpdateDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::UpdateDeploymentRequest'->new($_) };

declare 'RepeatedUpdateDeploymentRequest',
    as ArrayRef[UpdateDeploymentRequest()];

coerce 'RepeatedUpdateDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::UpdateDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDeploymentRequest',
    as HashRef[UpdateDeploymentRequest()];

declare 'DeleteDeploymentRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::DeleteDeploymentRequest'];

coerce 'DeleteDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::DeleteDeploymentRequest'->new($_) };

declare 'RepeatedDeleteDeploymentRequest',
    as ArrayRef[DeleteDeploymentRequest()];

coerce 'RepeatedDeleteDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::DeleteDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDeploymentRequest',
    as HashRef[DeleteDeploymentRequest()];

declare 'ListToolsetsRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::ListToolsetsRequest'];

coerce 'ListToolsetsRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::ListToolsetsRequest'->new($_) };

declare 'RepeatedListToolsetsRequest',
    as ArrayRef[ListToolsetsRequest()];

coerce 'RepeatedListToolsetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::ListToolsetsRequest'->new($_) } @$_ ] };

declare 'MapStringListToolsetsRequest',
    as HashRef[ListToolsetsRequest()];

declare 'ListToolsetsResponse',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::ListToolsetsResponse'];

coerce 'ListToolsetsResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::ListToolsetsResponse'->new($_) };

declare 'RepeatedListToolsetsResponse',
    as ArrayRef[ListToolsetsResponse()];

coerce 'RepeatedListToolsetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::ListToolsetsResponse'->new($_) } @$_ ] };

declare 'MapStringListToolsetsResponse',
    as HashRef[ListToolsetsResponse()];

declare 'GetToolsetRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::GetToolsetRequest'];

coerce 'GetToolsetRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::GetToolsetRequest'->new($_) };

declare 'RepeatedGetToolsetRequest',
    as ArrayRef[GetToolsetRequest()];

coerce 'RepeatedGetToolsetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::GetToolsetRequest'->new($_) } @$_ ] };

declare 'MapStringGetToolsetRequest',
    as HashRef[GetToolsetRequest()];

declare 'CreateToolsetRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::CreateToolsetRequest'];

coerce 'CreateToolsetRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::CreateToolsetRequest'->new($_) };

declare 'RepeatedCreateToolsetRequest',
    as ArrayRef[CreateToolsetRequest()];

coerce 'RepeatedCreateToolsetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::CreateToolsetRequest'->new($_) } @$_ ] };

declare 'MapStringCreateToolsetRequest',
    as HashRef[CreateToolsetRequest()];

declare 'UpdateToolsetRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::UpdateToolsetRequest'];

coerce 'UpdateToolsetRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::UpdateToolsetRequest'->new($_) };

declare 'RepeatedUpdateToolsetRequest',
    as ArrayRef[UpdateToolsetRequest()];

coerce 'RepeatedUpdateToolsetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::UpdateToolsetRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateToolsetRequest',
    as HashRef[UpdateToolsetRequest()];

declare 'DeleteToolsetRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::DeleteToolsetRequest'];

coerce 'DeleteToolsetRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::DeleteToolsetRequest'->new($_) };

declare 'RepeatedDeleteToolsetRequest',
    as ArrayRef[DeleteToolsetRequest()];

coerce 'RepeatedDeleteToolsetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::DeleteToolsetRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteToolsetRequest',
    as HashRef[DeleteToolsetRequest()];

declare 'ListAppVersionsRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::ListAppVersionsRequest'];

coerce 'ListAppVersionsRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::ListAppVersionsRequest'->new($_) };

declare 'RepeatedListAppVersionsRequest',
    as ArrayRef[ListAppVersionsRequest()];

coerce 'RepeatedListAppVersionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::ListAppVersionsRequest'->new($_) } @$_ ] };

declare 'MapStringListAppVersionsRequest',
    as HashRef[ListAppVersionsRequest()];

declare 'ListAppVersionsResponse',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::ListAppVersionsResponse'];

coerce 'ListAppVersionsResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::ListAppVersionsResponse'->new($_) };

declare 'RepeatedListAppVersionsResponse',
    as ArrayRef[ListAppVersionsResponse()];

coerce 'RepeatedListAppVersionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::ListAppVersionsResponse'->new($_) } @$_ ] };

declare 'MapStringListAppVersionsResponse',
    as HashRef[ListAppVersionsResponse()];

declare 'GetAppVersionRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::GetAppVersionRequest'];

coerce 'GetAppVersionRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::GetAppVersionRequest'->new($_) };

declare 'RepeatedGetAppVersionRequest',
    as ArrayRef[GetAppVersionRequest()];

coerce 'RepeatedGetAppVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::GetAppVersionRequest'->new($_) } @$_ ] };

declare 'MapStringGetAppVersionRequest',
    as HashRef[GetAppVersionRequest()];

declare 'DeleteAppVersionRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::DeleteAppVersionRequest'];

coerce 'DeleteAppVersionRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::DeleteAppVersionRequest'->new($_) };

declare 'RepeatedDeleteAppVersionRequest',
    as ArrayRef[DeleteAppVersionRequest()];

coerce 'RepeatedDeleteAppVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::DeleteAppVersionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAppVersionRequest',
    as HashRef[DeleteAppVersionRequest()];

declare 'CreateAppVersionRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::CreateAppVersionRequest'];

coerce 'CreateAppVersionRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::CreateAppVersionRequest'->new($_) };

declare 'RepeatedCreateAppVersionRequest',
    as ArrayRef[CreateAppVersionRequest()];

coerce 'RepeatedCreateAppVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::CreateAppVersionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAppVersionRequest',
    as HashRef[CreateAppVersionRequest()];

declare 'RestoreAppVersionRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::RestoreAppVersionRequest'];

coerce 'RestoreAppVersionRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::RestoreAppVersionRequest'->new($_) };

declare 'RepeatedRestoreAppVersionRequest',
    as ArrayRef[RestoreAppVersionRequest()];

coerce 'RepeatedRestoreAppVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::RestoreAppVersionRequest'->new($_) } @$_ ] };

declare 'MapStringRestoreAppVersionRequest',
    as HashRef[RestoreAppVersionRequest()];

declare 'RestoreAppVersionResponse',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::RestoreAppVersionResponse'];

coerce 'RestoreAppVersionResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::RestoreAppVersionResponse'->new($_) };

declare 'RepeatedRestoreAppVersionResponse',
    as ArrayRef[RestoreAppVersionResponse()];

coerce 'RepeatedRestoreAppVersionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::RestoreAppVersionResponse'->new($_) } @$_ ] };

declare 'MapStringRestoreAppVersionResponse',
    as HashRef[RestoreAppVersionResponse()];

declare 'ListChangelogsRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::ListChangelogsRequest'];

coerce 'ListChangelogsRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::ListChangelogsRequest'->new($_) };

declare 'RepeatedListChangelogsRequest',
    as ArrayRef[ListChangelogsRequest()];

coerce 'RepeatedListChangelogsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::ListChangelogsRequest'->new($_) } @$_ ] };

declare 'MapStringListChangelogsRequest',
    as HashRef[ListChangelogsRequest()];

declare 'ListChangelogsResponse',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::ListChangelogsResponse'];

coerce 'ListChangelogsResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::ListChangelogsResponse'->new($_) };

declare 'RepeatedListChangelogsResponse',
    as ArrayRef[ListChangelogsResponse()];

coerce 'RepeatedListChangelogsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::ListChangelogsResponse'->new($_) } @$_ ] };

declare 'MapStringListChangelogsResponse',
    as HashRef[ListChangelogsResponse()];

declare 'GetChangelogRequest',
    as InstanceOf['Google::Cloud::Ces::V1::AgentService::GetChangelogRequest'];

coerce 'GetChangelogRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1::AgentService::GetChangelogRequest'->new($_) };

declare 'RepeatedGetChangelogRequest',
    as ArrayRef[GetChangelogRequest()];

coerce 'RepeatedGetChangelogRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::AgentService::GetChangelogRequest'->new($_) } @$_ ] };

declare 'MapStringGetChangelogRequest',
    as HashRef[GetChangelogRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1::AgentService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
