package Google::Cloud::Agentregistry::V1::AgentregistryService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SearchType',
    as (Int | Str);

declare 'ListAgentsRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::ListAgentsRequest'];

coerce 'ListAgentsRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListAgentsRequest'->new($_) };

declare 'RepeatedListAgentsRequest',
    as ArrayRef[ListAgentsRequest()];

coerce 'RepeatedListAgentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListAgentsRequest'->new($_) } @$_ ] };

declare 'MapStringListAgentsRequest',
    as HashRef[ListAgentsRequest()];

declare 'ListAgentsResponse',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::ListAgentsResponse'];

coerce 'ListAgentsResponse',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListAgentsResponse'->new($_) };

declare 'RepeatedListAgentsResponse',
    as ArrayRef[ListAgentsResponse()];

coerce 'RepeatedListAgentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListAgentsResponse'->new($_) } @$_ ] };

declare 'MapStringListAgentsResponse',
    as HashRef[ListAgentsResponse()];

declare 'SearchAgentsRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::SearchAgentsRequest'];

coerce 'SearchAgentsRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::SearchAgentsRequest'->new($_) };

declare 'RepeatedSearchAgentsRequest',
    as ArrayRef[SearchAgentsRequest()];

coerce 'RepeatedSearchAgentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::SearchAgentsRequest'->new($_) } @$_ ] };

declare 'MapStringSearchAgentsRequest',
    as HashRef[SearchAgentsRequest()];

declare 'SearchAgentsResponse',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::SearchAgentsResponse'];

coerce 'SearchAgentsResponse',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::SearchAgentsResponse'->new($_) };

declare 'RepeatedSearchAgentsResponse',
    as ArrayRef[SearchAgentsResponse()];

coerce 'RepeatedSearchAgentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::SearchAgentsResponse'->new($_) } @$_ ] };

declare 'MapStringSearchAgentsResponse',
    as HashRef[SearchAgentsResponse()];

declare 'GetAgentRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::GetAgentRequest'];

coerce 'GetAgentRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::GetAgentRequest'->new($_) };

declare 'RepeatedGetAgentRequest',
    as ArrayRef[GetAgentRequest()];

coerce 'RepeatedGetAgentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::GetAgentRequest'->new($_) } @$_ ] };

declare 'MapStringGetAgentRequest',
    as HashRef[GetAgentRequest()];

declare 'GetAiApplicationAgentRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::GetAiApplicationAgentRequest'];

coerce 'GetAiApplicationAgentRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::GetAiApplicationAgentRequest'->new($_) };

declare 'RepeatedGetAiApplicationAgentRequest',
    as ArrayRef[GetAiApplicationAgentRequest()];

coerce 'RepeatedGetAiApplicationAgentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::GetAiApplicationAgentRequest'->new($_) } @$_ ] };

declare 'MapStringGetAiApplicationAgentRequest',
    as HashRef[GetAiApplicationAgentRequest()];

declare 'ListAiApplicationAgentsRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::ListAiApplicationAgentsRequest'];

coerce 'ListAiApplicationAgentsRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListAiApplicationAgentsRequest'->new($_) };

declare 'RepeatedListAiApplicationAgentsRequest',
    as ArrayRef[ListAiApplicationAgentsRequest()];

coerce 'RepeatedListAiApplicationAgentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListAiApplicationAgentsRequest'->new($_) } @$_ ] };

declare 'MapStringListAiApplicationAgentsRequest',
    as HashRef[ListAiApplicationAgentsRequest()];

declare 'ListAiApplicationAgentsResponse',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::ListAiApplicationAgentsResponse'];

coerce 'ListAiApplicationAgentsResponse',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListAiApplicationAgentsResponse'->new($_) };

declare 'RepeatedListAiApplicationAgentsResponse',
    as ArrayRef[ListAiApplicationAgentsResponse()];

coerce 'RepeatedListAiApplicationAgentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListAiApplicationAgentsResponse'->new($_) } @$_ ] };

declare 'MapStringListAiApplicationAgentsResponse',
    as HashRef[ListAiApplicationAgentsResponse()];

declare 'ListEndpointsRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::ListEndpointsRequest'];

coerce 'ListEndpointsRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListEndpointsRequest'->new($_) };

declare 'RepeatedListEndpointsRequest',
    as ArrayRef[ListEndpointsRequest()];

coerce 'RepeatedListEndpointsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListEndpointsRequest'->new($_) } @$_ ] };

declare 'MapStringListEndpointsRequest',
    as HashRef[ListEndpointsRequest()];

declare 'ListEndpointsResponse',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::ListEndpointsResponse'];

coerce 'ListEndpointsResponse',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListEndpointsResponse'->new($_) };

declare 'RepeatedListEndpointsResponse',
    as ArrayRef[ListEndpointsResponse()];

coerce 'RepeatedListEndpointsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListEndpointsResponse'->new($_) } @$_ ] };

declare 'MapStringListEndpointsResponse',
    as HashRef[ListEndpointsResponse()];

declare 'GetEndpointRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::GetEndpointRequest'];

coerce 'GetEndpointRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::GetEndpointRequest'->new($_) };

declare 'RepeatedGetEndpointRequest',
    as ArrayRef[GetEndpointRequest()];

coerce 'RepeatedGetEndpointRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::GetEndpointRequest'->new($_) } @$_ ] };

declare 'MapStringGetEndpointRequest',
    as HashRef[GetEndpointRequest()];

declare 'GetAiApplicationEndpointRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::GetAiApplicationEndpointRequest'];

coerce 'GetAiApplicationEndpointRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::GetAiApplicationEndpointRequest'->new($_) };

declare 'RepeatedGetAiApplicationEndpointRequest',
    as ArrayRef[GetAiApplicationEndpointRequest()];

coerce 'RepeatedGetAiApplicationEndpointRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::GetAiApplicationEndpointRequest'->new($_) } @$_ ] };

declare 'MapStringGetAiApplicationEndpointRequest',
    as HashRef[GetAiApplicationEndpointRequest()];

declare 'ListAiApplicationEndpointsRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::ListAiApplicationEndpointsRequest'];

coerce 'ListAiApplicationEndpointsRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListAiApplicationEndpointsRequest'->new($_) };

declare 'RepeatedListAiApplicationEndpointsRequest',
    as ArrayRef[ListAiApplicationEndpointsRequest()];

coerce 'RepeatedListAiApplicationEndpointsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListAiApplicationEndpointsRequest'->new($_) } @$_ ] };

declare 'MapStringListAiApplicationEndpointsRequest',
    as HashRef[ListAiApplicationEndpointsRequest()];

declare 'ListAiApplicationEndpointsResponse',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::ListAiApplicationEndpointsResponse'];

coerce 'ListAiApplicationEndpointsResponse',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListAiApplicationEndpointsResponse'->new($_) };

declare 'RepeatedListAiApplicationEndpointsResponse',
    as ArrayRef[ListAiApplicationEndpointsResponse()];

coerce 'RepeatedListAiApplicationEndpointsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListAiApplicationEndpointsResponse'->new($_) } @$_ ] };

declare 'MapStringListAiApplicationEndpointsResponse',
    as HashRef[ListAiApplicationEndpointsResponse()];

declare 'ListMcpServersRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::ListMcpServersRequest'];

coerce 'ListMcpServersRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListMcpServersRequest'->new($_) };

declare 'RepeatedListMcpServersRequest',
    as ArrayRef[ListMcpServersRequest()];

coerce 'RepeatedListMcpServersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListMcpServersRequest'->new($_) } @$_ ] };

declare 'MapStringListMcpServersRequest',
    as HashRef[ListMcpServersRequest()];

declare 'ListMcpServersResponse',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::ListMcpServersResponse'];

coerce 'ListMcpServersResponse',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListMcpServersResponse'->new($_) };

declare 'RepeatedListMcpServersResponse',
    as ArrayRef[ListMcpServersResponse()];

coerce 'RepeatedListMcpServersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListMcpServersResponse'->new($_) } @$_ ] };

declare 'MapStringListMcpServersResponse',
    as HashRef[ListMcpServersResponse()];

declare 'SearchMcpServersRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::SearchMcpServersRequest'];

coerce 'SearchMcpServersRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::SearchMcpServersRequest'->new($_) };

declare 'RepeatedSearchMcpServersRequest',
    as ArrayRef[SearchMcpServersRequest()];

coerce 'RepeatedSearchMcpServersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::SearchMcpServersRequest'->new($_) } @$_ ] };

declare 'MapStringSearchMcpServersRequest',
    as HashRef[SearchMcpServersRequest()];

declare 'SearchMcpServersResponse',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::SearchMcpServersResponse'];

coerce 'SearchMcpServersResponse',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::SearchMcpServersResponse'->new($_) };

declare 'RepeatedSearchMcpServersResponse',
    as ArrayRef[SearchMcpServersResponse()];

coerce 'RepeatedSearchMcpServersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::SearchMcpServersResponse'->new($_) } @$_ ] };

declare 'MapStringSearchMcpServersResponse',
    as HashRef[SearchMcpServersResponse()];

declare 'GetMcpServerRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::GetMcpServerRequest'];

coerce 'GetMcpServerRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::GetMcpServerRequest'->new($_) };

declare 'RepeatedGetMcpServerRequest',
    as ArrayRef[GetMcpServerRequest()];

coerce 'RepeatedGetMcpServerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::GetMcpServerRequest'->new($_) } @$_ ] };

declare 'MapStringGetMcpServerRequest',
    as HashRef[GetMcpServerRequest()];

declare 'GetAiApplicationMcpServerRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::GetAiApplicationMcpServerRequest'];

coerce 'GetAiApplicationMcpServerRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::GetAiApplicationMcpServerRequest'->new($_) };

declare 'RepeatedGetAiApplicationMcpServerRequest',
    as ArrayRef[GetAiApplicationMcpServerRequest()];

coerce 'RepeatedGetAiApplicationMcpServerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::GetAiApplicationMcpServerRequest'->new($_) } @$_ ] };

declare 'MapStringGetAiApplicationMcpServerRequest',
    as HashRef[GetAiApplicationMcpServerRequest()];

declare 'ListAiApplicationMcpServersRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::ListAiApplicationMcpServersRequest'];

coerce 'ListAiApplicationMcpServersRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListAiApplicationMcpServersRequest'->new($_) };

declare 'RepeatedListAiApplicationMcpServersRequest',
    as ArrayRef[ListAiApplicationMcpServersRequest()];

coerce 'RepeatedListAiApplicationMcpServersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListAiApplicationMcpServersRequest'->new($_) } @$_ ] };

declare 'MapStringListAiApplicationMcpServersRequest',
    as HashRef[ListAiApplicationMcpServersRequest()];

declare 'ListAiApplicationMcpServersResponse',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::ListAiApplicationMcpServersResponse'];

coerce 'ListAiApplicationMcpServersResponse',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListAiApplicationMcpServersResponse'->new($_) };

declare 'RepeatedListAiApplicationMcpServersResponse',
    as ArrayRef[ListAiApplicationMcpServersResponse()];

coerce 'RepeatedListAiApplicationMcpServersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListAiApplicationMcpServersResponse'->new($_) } @$_ ] };

declare 'MapStringListAiApplicationMcpServersResponse',
    as HashRef[ListAiApplicationMcpServersResponse()];

declare 'ListServicesRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::ListServicesRequest'];

coerce 'ListServicesRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListServicesRequest'->new($_) };

declare 'RepeatedListServicesRequest',
    as ArrayRef[ListServicesRequest()];

coerce 'RepeatedListServicesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListServicesRequest'->new($_) } @$_ ] };

declare 'MapStringListServicesRequest',
    as HashRef[ListServicesRequest()];

declare 'ListServicesResponse',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::ListServicesResponse'];

coerce 'ListServicesResponse',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListServicesResponse'->new($_) };

declare 'RepeatedListServicesResponse',
    as ArrayRef[ListServicesResponse()];

coerce 'RepeatedListServicesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListServicesResponse'->new($_) } @$_ ] };

declare 'MapStringListServicesResponse',
    as HashRef[ListServicesResponse()];

declare 'GetServiceRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::GetServiceRequest'];

coerce 'GetServiceRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::GetServiceRequest'->new($_) };

declare 'RepeatedGetServiceRequest',
    as ArrayRef[GetServiceRequest()];

coerce 'RepeatedGetServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::GetServiceRequest'->new($_) } @$_ ] };

declare 'MapStringGetServiceRequest',
    as HashRef[GetServiceRequest()];

declare 'CreateServiceRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::CreateServiceRequest'];

coerce 'CreateServiceRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::CreateServiceRequest'->new($_) };

declare 'RepeatedCreateServiceRequest',
    as ArrayRef[CreateServiceRequest()];

coerce 'RepeatedCreateServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::CreateServiceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateServiceRequest',
    as HashRef[CreateServiceRequest()];

declare 'FetchAvailableBindingsRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::FetchAvailableBindingsRequest'];

coerce 'FetchAvailableBindingsRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::FetchAvailableBindingsRequest'->new($_) };

declare 'RepeatedFetchAvailableBindingsRequest',
    as ArrayRef[FetchAvailableBindingsRequest()];

coerce 'RepeatedFetchAvailableBindingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::FetchAvailableBindingsRequest'->new($_) } @$_ ] };

declare 'MapStringFetchAvailableBindingsRequest',
    as HashRef[FetchAvailableBindingsRequest()];

declare 'FetchAvailableBindingsResponse',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::FetchAvailableBindingsResponse'];

coerce 'FetchAvailableBindingsResponse',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::FetchAvailableBindingsResponse'->new($_) };

declare 'RepeatedFetchAvailableBindingsResponse',
    as ArrayRef[FetchAvailableBindingsResponse()];

coerce 'RepeatedFetchAvailableBindingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::FetchAvailableBindingsResponse'->new($_) } @$_ ] };

declare 'MapStringFetchAvailableBindingsResponse',
    as HashRef[FetchAvailableBindingsResponse()];

declare 'UpdateServiceRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::UpdateServiceRequest'];

coerce 'UpdateServiceRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::UpdateServiceRequest'->new($_) };

declare 'RepeatedUpdateServiceRequest',
    as ArrayRef[UpdateServiceRequest()];

coerce 'RepeatedUpdateServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::UpdateServiceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateServiceRequest',
    as HashRef[UpdateServiceRequest()];

declare 'DeleteServiceRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::DeleteServiceRequest'];

coerce 'DeleteServiceRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::DeleteServiceRequest'->new($_) };

declare 'RepeatedDeleteServiceRequest',
    as ArrayRef[DeleteServiceRequest()];

coerce 'RepeatedDeleteServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::DeleteServiceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteServiceRequest',
    as HashRef[DeleteServiceRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'ListBindingsRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::ListBindingsRequest'];

coerce 'ListBindingsRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListBindingsRequest'->new($_) };

declare 'RepeatedListBindingsRequest',
    as ArrayRef[ListBindingsRequest()];

coerce 'RepeatedListBindingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListBindingsRequest'->new($_) } @$_ ] };

declare 'MapStringListBindingsRequest',
    as HashRef[ListBindingsRequest()];

declare 'ListBindingsResponse',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::ListBindingsResponse'];

coerce 'ListBindingsResponse',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListBindingsResponse'->new($_) };

declare 'RepeatedListBindingsResponse',
    as ArrayRef[ListBindingsResponse()];

coerce 'RepeatedListBindingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListBindingsResponse'->new($_) } @$_ ] };

declare 'MapStringListBindingsResponse',
    as HashRef[ListBindingsResponse()];

declare 'GetBindingRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::GetBindingRequest'];

coerce 'GetBindingRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::GetBindingRequest'->new($_) };

declare 'RepeatedGetBindingRequest',
    as ArrayRef[GetBindingRequest()];

coerce 'RepeatedGetBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::GetBindingRequest'->new($_) } @$_ ] };

declare 'MapStringGetBindingRequest',
    as HashRef[GetBindingRequest()];

declare 'CreateBindingRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::CreateBindingRequest'];

coerce 'CreateBindingRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::CreateBindingRequest'->new($_) };

declare 'RepeatedCreateBindingRequest',
    as ArrayRef[CreateBindingRequest()];

coerce 'RepeatedCreateBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::CreateBindingRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBindingRequest',
    as HashRef[CreateBindingRequest()];

declare 'UpdateBindingRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::UpdateBindingRequest'];

coerce 'UpdateBindingRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::UpdateBindingRequest'->new($_) };

declare 'RepeatedUpdateBindingRequest',
    as ArrayRef[UpdateBindingRequest()];

coerce 'RepeatedUpdateBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::UpdateBindingRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBindingRequest',
    as HashRef[UpdateBindingRequest()];

declare 'DeleteBindingRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::DeleteBindingRequest'];

coerce 'DeleteBindingRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::DeleteBindingRequest'->new($_) };

declare 'RepeatedDeleteBindingRequest',
    as ArrayRef[DeleteBindingRequest()];

coerce 'RepeatedDeleteBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::DeleteBindingRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBindingRequest',
    as HashRef[DeleteBindingRequest()];

declare 'CreateSkillRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::CreateSkillRequest'];

coerce 'CreateSkillRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::CreateSkillRequest'->new($_) };

declare 'RepeatedCreateSkillRequest',
    as ArrayRef[CreateSkillRequest()];

coerce 'RepeatedCreateSkillRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::CreateSkillRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSkillRequest',
    as HashRef[CreateSkillRequest()];

declare 'GetSkillRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::GetSkillRequest'];

coerce 'GetSkillRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::GetSkillRequest'->new($_) };

declare 'RepeatedGetSkillRequest',
    as ArrayRef[GetSkillRequest()];

coerce 'RepeatedGetSkillRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::GetSkillRequest'->new($_) } @$_ ] };

declare 'MapStringGetSkillRequest',
    as HashRef[GetSkillRequest()];

declare 'UpdateSkillRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::UpdateSkillRequest'];

coerce 'UpdateSkillRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::UpdateSkillRequest'->new($_) };

declare 'RepeatedUpdateSkillRequest',
    as ArrayRef[UpdateSkillRequest()];

coerce 'RepeatedUpdateSkillRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::UpdateSkillRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSkillRequest',
    as HashRef[UpdateSkillRequest()];

declare 'DeleteSkillRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::DeleteSkillRequest'];

coerce 'DeleteSkillRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::DeleteSkillRequest'->new($_) };

declare 'RepeatedDeleteSkillRequest',
    as ArrayRef[DeleteSkillRequest()];

coerce 'RepeatedDeleteSkillRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::DeleteSkillRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSkillRequest',
    as HashRef[DeleteSkillRequest()];

declare 'ListSkillsRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::ListSkillsRequest'];

coerce 'ListSkillsRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListSkillsRequest'->new($_) };

declare 'RepeatedListSkillsRequest',
    as ArrayRef[ListSkillsRequest()];

coerce 'RepeatedListSkillsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListSkillsRequest'->new($_) } @$_ ] };

declare 'MapStringListSkillsRequest',
    as HashRef[ListSkillsRequest()];

declare 'ListSkillsResponse',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::ListSkillsResponse'];

coerce 'ListSkillsResponse',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListSkillsResponse'->new($_) };

declare 'RepeatedListSkillsResponse',
    as ArrayRef[ListSkillsResponse()];

coerce 'RepeatedListSkillsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListSkillsResponse'->new($_) } @$_ ] };

declare 'MapStringListSkillsResponse',
    as HashRef[ListSkillsResponse()];

declare 'SearchSkillsRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::SearchSkillsRequest'];

coerce 'SearchSkillsRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::SearchSkillsRequest'->new($_) };

declare 'RepeatedSearchSkillsRequest',
    as ArrayRef[SearchSkillsRequest()];

coerce 'RepeatedSearchSkillsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::SearchSkillsRequest'->new($_) } @$_ ] };

declare 'MapStringSearchSkillsRequest',
    as HashRef[SearchSkillsRequest()];

declare 'SearchSkillsResponse',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::SearchSkillsResponse'];

coerce 'SearchSkillsResponse',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::SearchSkillsResponse'->new($_) };

declare 'RepeatedSearchSkillsResponse',
    as ArrayRef[SearchSkillsResponse()];

coerce 'RepeatedSearchSkillsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::SearchSkillsResponse'->new($_) } @$_ ] };

declare 'MapStringSearchSkillsResponse',
    as HashRef[SearchSkillsResponse()];

declare 'CreateSkillRevisionRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::CreateSkillRevisionRequest'];

coerce 'CreateSkillRevisionRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::CreateSkillRevisionRequest'->new($_) };

declare 'RepeatedCreateSkillRevisionRequest',
    as ArrayRef[CreateSkillRevisionRequest()];

coerce 'RepeatedCreateSkillRevisionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::CreateSkillRevisionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSkillRevisionRequest',
    as HashRef[CreateSkillRevisionRequest()];

declare 'GetSkillRevisionRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::GetSkillRevisionRequest'];

coerce 'GetSkillRevisionRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::GetSkillRevisionRequest'->new($_) };

declare 'RepeatedGetSkillRevisionRequest',
    as ArrayRef[GetSkillRevisionRequest()];

coerce 'RepeatedGetSkillRevisionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::GetSkillRevisionRequest'->new($_) } @$_ ] };

declare 'MapStringGetSkillRevisionRequest',
    as HashRef[GetSkillRevisionRequest()];

declare 'DeleteSkillRevisionRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::DeleteSkillRevisionRequest'];

coerce 'DeleteSkillRevisionRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::DeleteSkillRevisionRequest'->new($_) };

declare 'RepeatedDeleteSkillRevisionRequest',
    as ArrayRef[DeleteSkillRevisionRequest()];

coerce 'RepeatedDeleteSkillRevisionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::DeleteSkillRevisionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSkillRevisionRequest',
    as HashRef[DeleteSkillRevisionRequest()];

declare 'ListSkillRevisionsRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::ListSkillRevisionsRequest'];

coerce 'ListSkillRevisionsRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListSkillRevisionsRequest'->new($_) };

declare 'RepeatedListSkillRevisionsRequest',
    as ArrayRef[ListSkillRevisionsRequest()];

coerce 'RepeatedListSkillRevisionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListSkillRevisionsRequest'->new($_) } @$_ ] };

declare 'MapStringListSkillRevisionsRequest',
    as HashRef[ListSkillRevisionsRequest()];

declare 'ListSkillRevisionsResponse',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::ListSkillRevisionsResponse'];

coerce 'ListSkillRevisionsResponse',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListSkillRevisionsResponse'->new($_) };

declare 'RepeatedListSkillRevisionsResponse',
    as ArrayRef[ListSkillRevisionsResponse()];

coerce 'RepeatedListSkillRevisionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListSkillRevisionsResponse'->new($_) } @$_ ] };

declare 'MapStringListSkillRevisionsResponse',
    as HashRef[ListSkillRevisionsResponse()];

declare 'GetPublisherRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::GetPublisherRequest'];

coerce 'GetPublisherRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::GetPublisherRequest'->new($_) };

declare 'RepeatedGetPublisherRequest',
    as ArrayRef[GetPublisherRequest()];

coerce 'RepeatedGetPublisherRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::GetPublisherRequest'->new($_) } @$_ ] };

declare 'MapStringGetPublisherRequest',
    as HashRef[GetPublisherRequest()];

declare 'ListPublishersRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::ListPublishersRequest'];

coerce 'ListPublishersRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListPublishersRequest'->new($_) };

declare 'RepeatedListPublishersRequest',
    as ArrayRef[ListPublishersRequest()];

coerce 'RepeatedListPublishersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListPublishersRequest'->new($_) } @$_ ] };

declare 'MapStringListPublishersRequest',
    as HashRef[ListPublishersRequest()];

declare 'ListPublishersResponse',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::ListPublishersResponse'];

coerce 'ListPublishersResponse',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListPublishersResponse'->new($_) };

declare 'RepeatedListPublishersResponse',
    as ArrayRef[ListPublishersResponse()];

coerce 'RepeatedListPublishersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListPublishersResponse'->new($_) } @$_ ] };

declare 'MapStringListPublishersResponse',
    as HashRef[ListPublishersResponse()];

declare 'GetAiApplicationRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::GetAiApplicationRequest'];

coerce 'GetAiApplicationRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::GetAiApplicationRequest'->new($_) };

declare 'RepeatedGetAiApplicationRequest',
    as ArrayRef[GetAiApplicationRequest()];

coerce 'RepeatedGetAiApplicationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::GetAiApplicationRequest'->new($_) } @$_ ] };

declare 'MapStringGetAiApplicationRequest',
    as HashRef[GetAiApplicationRequest()];

declare 'ListAiApplicationsRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::ListAiApplicationsRequest'];

coerce 'ListAiApplicationsRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListAiApplicationsRequest'->new($_) };

declare 'RepeatedListAiApplicationsRequest',
    as ArrayRef[ListAiApplicationsRequest()];

coerce 'RepeatedListAiApplicationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListAiApplicationsRequest'->new($_) } @$_ ] };

declare 'MapStringListAiApplicationsRequest',
    as HashRef[ListAiApplicationsRequest()];

declare 'ListAiApplicationsResponse',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::ListAiApplicationsResponse'];

coerce 'ListAiApplicationsResponse',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListAiApplicationsResponse'->new($_) };

declare 'RepeatedListAiApplicationsResponse',
    as ArrayRef[ListAiApplicationsResponse()];

coerce 'RepeatedListAiApplicationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListAiApplicationsResponse'->new($_) } @$_ ] };

declare 'MapStringListAiApplicationsResponse',
    as HashRef[ListAiApplicationsResponse()];

declare 'ListFindingsRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::ListFindingsRequest'];

coerce 'ListFindingsRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListFindingsRequest'->new($_) };

declare 'RepeatedListFindingsRequest',
    as ArrayRef[ListFindingsRequest()];

coerce 'RepeatedListFindingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListFindingsRequest'->new($_) } @$_ ] };

declare 'MapStringListFindingsRequest',
    as HashRef[ListFindingsRequest()];

declare 'ListFindingsResponse',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::ListFindingsResponse'];

coerce 'ListFindingsResponse',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListFindingsResponse'->new($_) };

declare 'RepeatedListFindingsResponse',
    as ArrayRef[ListFindingsResponse()];

coerce 'RepeatedListFindingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListFindingsResponse'->new($_) } @$_ ] };

declare 'MapStringListFindingsResponse',
    as HashRef[ListFindingsResponse()];

declare 'GetFindingRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::GetFindingRequest'];

coerce 'GetFindingRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::GetFindingRequest'->new($_) };

declare 'RepeatedGetFindingRequest',
    as ArrayRef[GetFindingRequest()];

coerce 'RepeatedGetFindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::GetFindingRequest'->new($_) } @$_ ] };

declare 'MapStringGetFindingRequest',
    as HashRef[GetFindingRequest()];

declare 'GetSkillEncryptionSpecRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::GetSkillEncryptionSpecRequest'];

coerce 'GetSkillEncryptionSpecRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::GetSkillEncryptionSpecRequest'->new($_) };

declare 'RepeatedGetSkillEncryptionSpecRequest',
    as ArrayRef[GetSkillEncryptionSpecRequest()];

coerce 'RepeatedGetSkillEncryptionSpecRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::GetSkillEncryptionSpecRequest'->new($_) } @$_ ] };

declare 'MapStringGetSkillEncryptionSpecRequest',
    as HashRef[GetSkillEncryptionSpecRequest()];

declare 'UpdateSkillEncryptionSpecRequest',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AgentregistryService::UpdateSkillEncryptionSpecRequest'];

coerce 'UpdateSkillEncryptionSpecRequest',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AgentregistryService::UpdateSkillEncryptionSpecRequest'->new($_) };

declare 'RepeatedUpdateSkillEncryptionSpecRequest',
    as ArrayRef[UpdateSkillEncryptionSpecRequest()];

coerce 'RepeatedUpdateSkillEncryptionSpecRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AgentregistryService::UpdateSkillEncryptionSpecRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSkillEncryptionSpecRequest',
    as HashRef[UpdateSkillEncryptionSpecRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Agentregistry::V1::AgentregistryService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
