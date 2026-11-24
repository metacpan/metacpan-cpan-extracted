package Google::Cloud::Eventarc::V1::Eventarc::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetTriggerRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::GetTriggerRequest'];

coerce 'GetTriggerRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::GetTriggerRequest'->new($_) };

declare 'RepeatedGetTriggerRequest',
    as ArrayRef[GetTriggerRequest()];

coerce 'RepeatedGetTriggerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::GetTriggerRequest'->new($_) } @$_ ] };

declare 'MapStringGetTriggerRequest',
    as HashRef[GetTriggerRequest()];

declare 'ListTriggersRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::ListTriggersRequest'];

coerce 'ListTriggersRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::ListTriggersRequest'->new($_) };

declare 'RepeatedListTriggersRequest',
    as ArrayRef[ListTriggersRequest()];

coerce 'RepeatedListTriggersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::ListTriggersRequest'->new($_) } @$_ ] };

declare 'MapStringListTriggersRequest',
    as HashRef[ListTriggersRequest()];

declare 'ListTriggersResponse',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::ListTriggersResponse'];

coerce 'ListTriggersResponse',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::ListTriggersResponse'->new($_) };

declare 'RepeatedListTriggersResponse',
    as ArrayRef[ListTriggersResponse()];

coerce 'RepeatedListTriggersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::ListTriggersResponse'->new($_) } @$_ ] };

declare 'MapStringListTriggersResponse',
    as HashRef[ListTriggersResponse()];

declare 'CreateTriggerRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::CreateTriggerRequest'];

coerce 'CreateTriggerRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::CreateTriggerRequest'->new($_) };

declare 'RepeatedCreateTriggerRequest',
    as ArrayRef[CreateTriggerRequest()];

coerce 'RepeatedCreateTriggerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::CreateTriggerRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTriggerRequest',
    as HashRef[CreateTriggerRequest()];

declare 'UpdateTriggerRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::UpdateTriggerRequest'];

coerce 'UpdateTriggerRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::UpdateTriggerRequest'->new($_) };

declare 'RepeatedUpdateTriggerRequest',
    as ArrayRef[UpdateTriggerRequest()];

coerce 'RepeatedUpdateTriggerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::UpdateTriggerRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTriggerRequest',
    as HashRef[UpdateTriggerRequest()];

declare 'DeleteTriggerRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::DeleteTriggerRequest'];

coerce 'DeleteTriggerRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::DeleteTriggerRequest'->new($_) };

declare 'RepeatedDeleteTriggerRequest',
    as ArrayRef[DeleteTriggerRequest()];

coerce 'RepeatedDeleteTriggerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::DeleteTriggerRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTriggerRequest',
    as HashRef[DeleteTriggerRequest()];

declare 'GetChannelRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::GetChannelRequest'];

coerce 'GetChannelRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::GetChannelRequest'->new($_) };

declare 'RepeatedGetChannelRequest',
    as ArrayRef[GetChannelRequest()];

coerce 'RepeatedGetChannelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::GetChannelRequest'->new($_) } @$_ ] };

declare 'MapStringGetChannelRequest',
    as HashRef[GetChannelRequest()];

declare 'ListChannelsRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::ListChannelsRequest'];

coerce 'ListChannelsRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::ListChannelsRequest'->new($_) };

declare 'RepeatedListChannelsRequest',
    as ArrayRef[ListChannelsRequest()];

coerce 'RepeatedListChannelsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::ListChannelsRequest'->new($_) } @$_ ] };

declare 'MapStringListChannelsRequest',
    as HashRef[ListChannelsRequest()];

declare 'ListChannelsResponse',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::ListChannelsResponse'];

coerce 'ListChannelsResponse',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::ListChannelsResponse'->new($_) };

declare 'RepeatedListChannelsResponse',
    as ArrayRef[ListChannelsResponse()];

coerce 'RepeatedListChannelsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::ListChannelsResponse'->new($_) } @$_ ] };

declare 'MapStringListChannelsResponse',
    as HashRef[ListChannelsResponse()];

declare 'CreateChannelRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::CreateChannelRequest'];

coerce 'CreateChannelRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::CreateChannelRequest'->new($_) };

declare 'RepeatedCreateChannelRequest',
    as ArrayRef[CreateChannelRequest()];

coerce 'RepeatedCreateChannelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::CreateChannelRequest'->new($_) } @$_ ] };

declare 'MapStringCreateChannelRequest',
    as HashRef[CreateChannelRequest()];

declare 'UpdateChannelRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::UpdateChannelRequest'];

coerce 'UpdateChannelRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::UpdateChannelRequest'->new($_) };

declare 'RepeatedUpdateChannelRequest',
    as ArrayRef[UpdateChannelRequest()];

coerce 'RepeatedUpdateChannelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::UpdateChannelRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateChannelRequest',
    as HashRef[UpdateChannelRequest()];

declare 'DeleteChannelRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::DeleteChannelRequest'];

coerce 'DeleteChannelRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::DeleteChannelRequest'->new($_) };

declare 'RepeatedDeleteChannelRequest',
    as ArrayRef[DeleteChannelRequest()];

coerce 'RepeatedDeleteChannelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::DeleteChannelRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteChannelRequest',
    as HashRef[DeleteChannelRequest()];

declare 'GetProviderRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::GetProviderRequest'];

coerce 'GetProviderRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::GetProviderRequest'->new($_) };

declare 'RepeatedGetProviderRequest',
    as ArrayRef[GetProviderRequest()];

coerce 'RepeatedGetProviderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::GetProviderRequest'->new($_) } @$_ ] };

declare 'MapStringGetProviderRequest',
    as HashRef[GetProviderRequest()];

declare 'ListProvidersRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::ListProvidersRequest'];

coerce 'ListProvidersRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::ListProvidersRequest'->new($_) };

declare 'RepeatedListProvidersRequest',
    as ArrayRef[ListProvidersRequest()];

coerce 'RepeatedListProvidersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::ListProvidersRequest'->new($_) } @$_ ] };

declare 'MapStringListProvidersRequest',
    as HashRef[ListProvidersRequest()];

declare 'ListProvidersResponse',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::ListProvidersResponse'];

coerce 'ListProvidersResponse',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::ListProvidersResponse'->new($_) };

declare 'RepeatedListProvidersResponse',
    as ArrayRef[ListProvidersResponse()];

coerce 'RepeatedListProvidersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::ListProvidersResponse'->new($_) } @$_ ] };

declare 'MapStringListProvidersResponse',
    as HashRef[ListProvidersResponse()];

declare 'GetChannelConnectionRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::GetChannelConnectionRequest'];

coerce 'GetChannelConnectionRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::GetChannelConnectionRequest'->new($_) };

declare 'RepeatedGetChannelConnectionRequest',
    as ArrayRef[GetChannelConnectionRequest()];

coerce 'RepeatedGetChannelConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::GetChannelConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringGetChannelConnectionRequest',
    as HashRef[GetChannelConnectionRequest()];

declare 'ListChannelConnectionsRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::ListChannelConnectionsRequest'];

coerce 'ListChannelConnectionsRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::ListChannelConnectionsRequest'->new($_) };

declare 'RepeatedListChannelConnectionsRequest',
    as ArrayRef[ListChannelConnectionsRequest()];

coerce 'RepeatedListChannelConnectionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::ListChannelConnectionsRequest'->new($_) } @$_ ] };

declare 'MapStringListChannelConnectionsRequest',
    as HashRef[ListChannelConnectionsRequest()];

declare 'ListChannelConnectionsResponse',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::ListChannelConnectionsResponse'];

coerce 'ListChannelConnectionsResponse',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::ListChannelConnectionsResponse'->new($_) };

declare 'RepeatedListChannelConnectionsResponse',
    as ArrayRef[ListChannelConnectionsResponse()];

coerce 'RepeatedListChannelConnectionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::ListChannelConnectionsResponse'->new($_) } @$_ ] };

declare 'MapStringListChannelConnectionsResponse',
    as HashRef[ListChannelConnectionsResponse()];

declare 'CreateChannelConnectionRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::CreateChannelConnectionRequest'];

coerce 'CreateChannelConnectionRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::CreateChannelConnectionRequest'->new($_) };

declare 'RepeatedCreateChannelConnectionRequest',
    as ArrayRef[CreateChannelConnectionRequest()];

coerce 'RepeatedCreateChannelConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::CreateChannelConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateChannelConnectionRequest',
    as HashRef[CreateChannelConnectionRequest()];

declare 'DeleteChannelConnectionRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::DeleteChannelConnectionRequest'];

coerce 'DeleteChannelConnectionRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::DeleteChannelConnectionRequest'->new($_) };

declare 'RepeatedDeleteChannelConnectionRequest',
    as ArrayRef[DeleteChannelConnectionRequest()];

coerce 'RepeatedDeleteChannelConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::DeleteChannelConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteChannelConnectionRequest',
    as HashRef[DeleteChannelConnectionRequest()];

declare 'UpdateGoogleChannelConfigRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::UpdateGoogleChannelConfigRequest'];

coerce 'UpdateGoogleChannelConfigRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::UpdateGoogleChannelConfigRequest'->new($_) };

declare 'RepeatedUpdateGoogleChannelConfigRequest',
    as ArrayRef[UpdateGoogleChannelConfigRequest()];

coerce 'RepeatedUpdateGoogleChannelConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::UpdateGoogleChannelConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateGoogleChannelConfigRequest',
    as HashRef[UpdateGoogleChannelConfigRequest()];

declare 'GetGoogleChannelConfigRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::GetGoogleChannelConfigRequest'];

coerce 'GetGoogleChannelConfigRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::GetGoogleChannelConfigRequest'->new($_) };

declare 'RepeatedGetGoogleChannelConfigRequest',
    as ArrayRef[GetGoogleChannelConfigRequest()];

coerce 'RepeatedGetGoogleChannelConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::GetGoogleChannelConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetGoogleChannelConfigRequest',
    as HashRef[GetGoogleChannelConfigRequest()];

declare 'GetMessageBusRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::GetMessageBusRequest'];

coerce 'GetMessageBusRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::GetMessageBusRequest'->new($_) };

declare 'RepeatedGetMessageBusRequest',
    as ArrayRef[GetMessageBusRequest()];

coerce 'RepeatedGetMessageBusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::GetMessageBusRequest'->new($_) } @$_ ] };

declare 'MapStringGetMessageBusRequest',
    as HashRef[GetMessageBusRequest()];

declare 'ListMessageBusesRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::ListMessageBusesRequest'];

coerce 'ListMessageBusesRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::ListMessageBusesRequest'->new($_) };

declare 'RepeatedListMessageBusesRequest',
    as ArrayRef[ListMessageBusesRequest()];

coerce 'RepeatedListMessageBusesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::ListMessageBusesRequest'->new($_) } @$_ ] };

declare 'MapStringListMessageBusesRequest',
    as HashRef[ListMessageBusesRequest()];

declare 'ListMessageBusesResponse',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::ListMessageBusesResponse'];

coerce 'ListMessageBusesResponse',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::ListMessageBusesResponse'->new($_) };

declare 'RepeatedListMessageBusesResponse',
    as ArrayRef[ListMessageBusesResponse()];

coerce 'RepeatedListMessageBusesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::ListMessageBusesResponse'->new($_) } @$_ ] };

declare 'MapStringListMessageBusesResponse',
    as HashRef[ListMessageBusesResponse()];

declare 'ListMessageBusEnrollmentsRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::ListMessageBusEnrollmentsRequest'];

coerce 'ListMessageBusEnrollmentsRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::ListMessageBusEnrollmentsRequest'->new($_) };

declare 'RepeatedListMessageBusEnrollmentsRequest',
    as ArrayRef[ListMessageBusEnrollmentsRequest()];

coerce 'RepeatedListMessageBusEnrollmentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::ListMessageBusEnrollmentsRequest'->new($_) } @$_ ] };

declare 'MapStringListMessageBusEnrollmentsRequest',
    as HashRef[ListMessageBusEnrollmentsRequest()];

declare 'ListMessageBusEnrollmentsResponse',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::ListMessageBusEnrollmentsResponse'];

coerce 'ListMessageBusEnrollmentsResponse',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::ListMessageBusEnrollmentsResponse'->new($_) };

declare 'RepeatedListMessageBusEnrollmentsResponse',
    as ArrayRef[ListMessageBusEnrollmentsResponse()];

coerce 'RepeatedListMessageBusEnrollmentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::ListMessageBusEnrollmentsResponse'->new($_) } @$_ ] };

declare 'MapStringListMessageBusEnrollmentsResponse',
    as HashRef[ListMessageBusEnrollmentsResponse()];

declare 'CreateMessageBusRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::CreateMessageBusRequest'];

coerce 'CreateMessageBusRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::CreateMessageBusRequest'->new($_) };

declare 'RepeatedCreateMessageBusRequest',
    as ArrayRef[CreateMessageBusRequest()];

coerce 'RepeatedCreateMessageBusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::CreateMessageBusRequest'->new($_) } @$_ ] };

declare 'MapStringCreateMessageBusRequest',
    as HashRef[CreateMessageBusRequest()];

declare 'UpdateMessageBusRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::UpdateMessageBusRequest'];

coerce 'UpdateMessageBusRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::UpdateMessageBusRequest'->new($_) };

declare 'RepeatedUpdateMessageBusRequest',
    as ArrayRef[UpdateMessageBusRequest()];

coerce 'RepeatedUpdateMessageBusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::UpdateMessageBusRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateMessageBusRequest',
    as HashRef[UpdateMessageBusRequest()];

declare 'DeleteMessageBusRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::DeleteMessageBusRequest'];

coerce 'DeleteMessageBusRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::DeleteMessageBusRequest'->new($_) };

declare 'RepeatedDeleteMessageBusRequest',
    as ArrayRef[DeleteMessageBusRequest()];

coerce 'RepeatedDeleteMessageBusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::DeleteMessageBusRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteMessageBusRequest',
    as HashRef[DeleteMessageBusRequest()];

declare 'GetEnrollmentRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::GetEnrollmentRequest'];

coerce 'GetEnrollmentRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::GetEnrollmentRequest'->new($_) };

declare 'RepeatedGetEnrollmentRequest',
    as ArrayRef[GetEnrollmentRequest()];

coerce 'RepeatedGetEnrollmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::GetEnrollmentRequest'->new($_) } @$_ ] };

declare 'MapStringGetEnrollmentRequest',
    as HashRef[GetEnrollmentRequest()];

declare 'ListEnrollmentsRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::ListEnrollmentsRequest'];

coerce 'ListEnrollmentsRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::ListEnrollmentsRequest'->new($_) };

declare 'RepeatedListEnrollmentsRequest',
    as ArrayRef[ListEnrollmentsRequest()];

coerce 'RepeatedListEnrollmentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::ListEnrollmentsRequest'->new($_) } @$_ ] };

declare 'MapStringListEnrollmentsRequest',
    as HashRef[ListEnrollmentsRequest()];

declare 'ListEnrollmentsResponse',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::ListEnrollmentsResponse'];

coerce 'ListEnrollmentsResponse',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::ListEnrollmentsResponse'->new($_) };

declare 'RepeatedListEnrollmentsResponse',
    as ArrayRef[ListEnrollmentsResponse()];

coerce 'RepeatedListEnrollmentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::ListEnrollmentsResponse'->new($_) } @$_ ] };

declare 'MapStringListEnrollmentsResponse',
    as HashRef[ListEnrollmentsResponse()];

declare 'CreateEnrollmentRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::CreateEnrollmentRequest'];

coerce 'CreateEnrollmentRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::CreateEnrollmentRequest'->new($_) };

declare 'RepeatedCreateEnrollmentRequest',
    as ArrayRef[CreateEnrollmentRequest()];

coerce 'RepeatedCreateEnrollmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::CreateEnrollmentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEnrollmentRequest',
    as HashRef[CreateEnrollmentRequest()];

declare 'UpdateEnrollmentRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::UpdateEnrollmentRequest'];

coerce 'UpdateEnrollmentRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::UpdateEnrollmentRequest'->new($_) };

declare 'RepeatedUpdateEnrollmentRequest',
    as ArrayRef[UpdateEnrollmentRequest()];

coerce 'RepeatedUpdateEnrollmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::UpdateEnrollmentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateEnrollmentRequest',
    as HashRef[UpdateEnrollmentRequest()];

declare 'DeleteEnrollmentRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::DeleteEnrollmentRequest'];

coerce 'DeleteEnrollmentRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::DeleteEnrollmentRequest'->new($_) };

declare 'RepeatedDeleteEnrollmentRequest',
    as ArrayRef[DeleteEnrollmentRequest()];

coerce 'RepeatedDeleteEnrollmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::DeleteEnrollmentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEnrollmentRequest',
    as HashRef[DeleteEnrollmentRequest()];

declare 'GetPipelineRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::GetPipelineRequest'];

coerce 'GetPipelineRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::GetPipelineRequest'->new($_) };

declare 'RepeatedGetPipelineRequest',
    as ArrayRef[GetPipelineRequest()];

coerce 'RepeatedGetPipelineRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::GetPipelineRequest'->new($_) } @$_ ] };

declare 'MapStringGetPipelineRequest',
    as HashRef[GetPipelineRequest()];

declare 'ListPipelinesRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::ListPipelinesRequest'];

coerce 'ListPipelinesRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::ListPipelinesRequest'->new($_) };

declare 'RepeatedListPipelinesRequest',
    as ArrayRef[ListPipelinesRequest()];

coerce 'RepeatedListPipelinesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::ListPipelinesRequest'->new($_) } @$_ ] };

declare 'MapStringListPipelinesRequest',
    as HashRef[ListPipelinesRequest()];

declare 'ListPipelinesResponse',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::ListPipelinesResponse'];

coerce 'ListPipelinesResponse',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::ListPipelinesResponse'->new($_) };

declare 'RepeatedListPipelinesResponse',
    as ArrayRef[ListPipelinesResponse()];

coerce 'RepeatedListPipelinesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::ListPipelinesResponse'->new($_) } @$_ ] };

declare 'MapStringListPipelinesResponse',
    as HashRef[ListPipelinesResponse()];

declare 'CreatePipelineRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::CreatePipelineRequest'];

coerce 'CreatePipelineRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::CreatePipelineRequest'->new($_) };

declare 'RepeatedCreatePipelineRequest',
    as ArrayRef[CreatePipelineRequest()];

coerce 'RepeatedCreatePipelineRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::CreatePipelineRequest'->new($_) } @$_ ] };

declare 'MapStringCreatePipelineRequest',
    as HashRef[CreatePipelineRequest()];

declare 'UpdatePipelineRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::UpdatePipelineRequest'];

coerce 'UpdatePipelineRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::UpdatePipelineRequest'->new($_) };

declare 'RepeatedUpdatePipelineRequest',
    as ArrayRef[UpdatePipelineRequest()];

coerce 'RepeatedUpdatePipelineRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::UpdatePipelineRequest'->new($_) } @$_ ] };

declare 'MapStringUpdatePipelineRequest',
    as HashRef[UpdatePipelineRequest()];

declare 'DeletePipelineRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::DeletePipelineRequest'];

coerce 'DeletePipelineRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::DeletePipelineRequest'->new($_) };

declare 'RepeatedDeletePipelineRequest',
    as ArrayRef[DeletePipelineRequest()];

coerce 'RepeatedDeletePipelineRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::DeletePipelineRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePipelineRequest',
    as HashRef[DeletePipelineRequest()];

declare 'GetGoogleApiSourceRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::GetGoogleApiSourceRequest'];

coerce 'GetGoogleApiSourceRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::GetGoogleApiSourceRequest'->new($_) };

declare 'RepeatedGetGoogleApiSourceRequest',
    as ArrayRef[GetGoogleApiSourceRequest()];

coerce 'RepeatedGetGoogleApiSourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::GetGoogleApiSourceRequest'->new($_) } @$_ ] };

declare 'MapStringGetGoogleApiSourceRequest',
    as HashRef[GetGoogleApiSourceRequest()];

declare 'ListGoogleApiSourcesRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::ListGoogleApiSourcesRequest'];

coerce 'ListGoogleApiSourcesRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::ListGoogleApiSourcesRequest'->new($_) };

declare 'RepeatedListGoogleApiSourcesRequest',
    as ArrayRef[ListGoogleApiSourcesRequest()];

coerce 'RepeatedListGoogleApiSourcesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::ListGoogleApiSourcesRequest'->new($_) } @$_ ] };

declare 'MapStringListGoogleApiSourcesRequest',
    as HashRef[ListGoogleApiSourcesRequest()];

declare 'ListGoogleApiSourcesResponse',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::ListGoogleApiSourcesResponse'];

coerce 'ListGoogleApiSourcesResponse',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::ListGoogleApiSourcesResponse'->new($_) };

declare 'RepeatedListGoogleApiSourcesResponse',
    as ArrayRef[ListGoogleApiSourcesResponse()];

coerce 'RepeatedListGoogleApiSourcesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::ListGoogleApiSourcesResponse'->new($_) } @$_ ] };

declare 'MapStringListGoogleApiSourcesResponse',
    as HashRef[ListGoogleApiSourcesResponse()];

declare 'CreateGoogleApiSourceRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::CreateGoogleApiSourceRequest'];

coerce 'CreateGoogleApiSourceRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::CreateGoogleApiSourceRequest'->new($_) };

declare 'RepeatedCreateGoogleApiSourceRequest',
    as ArrayRef[CreateGoogleApiSourceRequest()];

coerce 'RepeatedCreateGoogleApiSourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::CreateGoogleApiSourceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateGoogleApiSourceRequest',
    as HashRef[CreateGoogleApiSourceRequest()];

declare 'UpdateGoogleApiSourceRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::UpdateGoogleApiSourceRequest'];

coerce 'UpdateGoogleApiSourceRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::UpdateGoogleApiSourceRequest'->new($_) };

declare 'RepeatedUpdateGoogleApiSourceRequest',
    as ArrayRef[UpdateGoogleApiSourceRequest()];

coerce 'RepeatedUpdateGoogleApiSourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::UpdateGoogleApiSourceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateGoogleApiSourceRequest',
    as HashRef[UpdateGoogleApiSourceRequest()];

declare 'DeleteGoogleApiSourceRequest',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::DeleteGoogleApiSourceRequest'];

coerce 'DeleteGoogleApiSourceRequest',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::DeleteGoogleApiSourceRequest'->new($_) };

declare 'RepeatedDeleteGoogleApiSourceRequest',
    as ArrayRef[DeleteGoogleApiSourceRequest()];

coerce 'RepeatedDeleteGoogleApiSourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::DeleteGoogleApiSourceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteGoogleApiSourceRequest',
    as HashRef[DeleteGoogleApiSourceRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Eventarc::V1::Eventarc::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Eventarc::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Eventarc::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Eventarc::V1::Eventarc::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
