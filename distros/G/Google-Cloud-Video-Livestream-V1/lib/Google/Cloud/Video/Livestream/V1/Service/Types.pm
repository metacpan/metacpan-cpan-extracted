package Google::Cloud::Video::Livestream::V1::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateAssetRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::CreateAssetRequest'];

coerce 'CreateAssetRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::CreateAssetRequest'->new($_) };

declare 'RepeatedCreateAssetRequest',
    as ArrayRef[CreateAssetRequest()];

coerce 'RepeatedCreateAssetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::CreateAssetRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAssetRequest',
    as HashRef[CreateAssetRequest()];

declare 'DeleteAssetRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::DeleteAssetRequest'];

coerce 'DeleteAssetRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::DeleteAssetRequest'->new($_) };

declare 'RepeatedDeleteAssetRequest',
    as ArrayRef[DeleteAssetRequest()];

coerce 'RepeatedDeleteAssetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::DeleteAssetRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAssetRequest',
    as HashRef[DeleteAssetRequest()];

declare 'ListAssetsRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::ListAssetsRequest'];

coerce 'ListAssetsRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::ListAssetsRequest'->new($_) };

declare 'RepeatedListAssetsRequest',
    as ArrayRef[ListAssetsRequest()];

coerce 'RepeatedListAssetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::ListAssetsRequest'->new($_) } @$_ ] };

declare 'MapStringListAssetsRequest',
    as HashRef[ListAssetsRequest()];

declare 'ListAssetsResponse',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::ListAssetsResponse'];

coerce 'ListAssetsResponse',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::ListAssetsResponse'->new($_) };

declare 'RepeatedListAssetsResponse',
    as ArrayRef[ListAssetsResponse()];

coerce 'RepeatedListAssetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::ListAssetsResponse'->new($_) } @$_ ] };

declare 'MapStringListAssetsResponse',
    as HashRef[ListAssetsResponse()];

declare 'GetAssetRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::GetAssetRequest'];

coerce 'GetAssetRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::GetAssetRequest'->new($_) };

declare 'RepeatedGetAssetRequest',
    as ArrayRef[GetAssetRequest()];

coerce 'RepeatedGetAssetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::GetAssetRequest'->new($_) } @$_ ] };

declare 'MapStringGetAssetRequest',
    as HashRef[GetAssetRequest()];

declare 'CreateChannelRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::CreateChannelRequest'];

coerce 'CreateChannelRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::CreateChannelRequest'->new($_) };

declare 'RepeatedCreateChannelRequest',
    as ArrayRef[CreateChannelRequest()];

coerce 'RepeatedCreateChannelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::CreateChannelRequest'->new($_) } @$_ ] };

declare 'MapStringCreateChannelRequest',
    as HashRef[CreateChannelRequest()];

declare 'ListChannelsRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::ListChannelsRequest'];

coerce 'ListChannelsRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::ListChannelsRequest'->new($_) };

declare 'RepeatedListChannelsRequest',
    as ArrayRef[ListChannelsRequest()];

coerce 'RepeatedListChannelsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::ListChannelsRequest'->new($_) } @$_ ] };

declare 'MapStringListChannelsRequest',
    as HashRef[ListChannelsRequest()];

declare 'ListChannelsResponse',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::ListChannelsResponse'];

coerce 'ListChannelsResponse',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::ListChannelsResponse'->new($_) };

declare 'RepeatedListChannelsResponse',
    as ArrayRef[ListChannelsResponse()];

coerce 'RepeatedListChannelsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::ListChannelsResponse'->new($_) } @$_ ] };

declare 'MapStringListChannelsResponse',
    as HashRef[ListChannelsResponse()];

declare 'GetChannelRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::GetChannelRequest'];

coerce 'GetChannelRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::GetChannelRequest'->new($_) };

declare 'RepeatedGetChannelRequest',
    as ArrayRef[GetChannelRequest()];

coerce 'RepeatedGetChannelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::GetChannelRequest'->new($_) } @$_ ] };

declare 'MapStringGetChannelRequest',
    as HashRef[GetChannelRequest()];

declare 'DeleteChannelRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::DeleteChannelRequest'];

coerce 'DeleteChannelRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::DeleteChannelRequest'->new($_) };

declare 'RepeatedDeleteChannelRequest',
    as ArrayRef[DeleteChannelRequest()];

coerce 'RepeatedDeleteChannelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::DeleteChannelRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteChannelRequest',
    as HashRef[DeleteChannelRequest()];

declare 'UpdateChannelRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::UpdateChannelRequest'];

coerce 'UpdateChannelRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::UpdateChannelRequest'->new($_) };

declare 'RepeatedUpdateChannelRequest',
    as ArrayRef[UpdateChannelRequest()];

coerce 'RepeatedUpdateChannelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::UpdateChannelRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateChannelRequest',
    as HashRef[UpdateChannelRequest()];

declare 'StartChannelRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::StartChannelRequest'];

coerce 'StartChannelRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::StartChannelRequest'->new($_) };

declare 'RepeatedStartChannelRequest',
    as ArrayRef[StartChannelRequest()];

coerce 'RepeatedStartChannelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::StartChannelRequest'->new($_) } @$_ ] };

declare 'MapStringStartChannelRequest',
    as HashRef[StartChannelRequest()];

declare 'StopChannelRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::StopChannelRequest'];

coerce 'StopChannelRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::StopChannelRequest'->new($_) };

declare 'RepeatedStopChannelRequest',
    as ArrayRef[StopChannelRequest()];

coerce 'RepeatedStopChannelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::StopChannelRequest'->new($_) } @$_ ] };

declare 'MapStringStopChannelRequest',
    as HashRef[StopChannelRequest()];

declare 'StartDistributionRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::StartDistributionRequest'];

coerce 'StartDistributionRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::StartDistributionRequest'->new($_) };

declare 'RepeatedStartDistributionRequest',
    as ArrayRef[StartDistributionRequest()];

coerce 'RepeatedStartDistributionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::StartDistributionRequest'->new($_) } @$_ ] };

declare 'MapStringStartDistributionRequest',
    as HashRef[StartDistributionRequest()];

declare 'StopDistributionRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::StopDistributionRequest'];

coerce 'StopDistributionRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::StopDistributionRequest'->new($_) };

declare 'RepeatedStopDistributionRequest',
    as ArrayRef[StopDistributionRequest()];

coerce 'RepeatedStopDistributionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::StopDistributionRequest'->new($_) } @$_ ] };

declare 'MapStringStopDistributionRequest',
    as HashRef[StopDistributionRequest()];

declare 'CreateInputRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::CreateInputRequest'];

coerce 'CreateInputRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::CreateInputRequest'->new($_) };

declare 'RepeatedCreateInputRequest',
    as ArrayRef[CreateInputRequest()];

coerce 'RepeatedCreateInputRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::CreateInputRequest'->new($_) } @$_ ] };

declare 'MapStringCreateInputRequest',
    as HashRef[CreateInputRequest()];

declare 'ListInputsRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::ListInputsRequest'];

coerce 'ListInputsRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::ListInputsRequest'->new($_) };

declare 'RepeatedListInputsRequest',
    as ArrayRef[ListInputsRequest()];

coerce 'RepeatedListInputsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::ListInputsRequest'->new($_) } @$_ ] };

declare 'MapStringListInputsRequest',
    as HashRef[ListInputsRequest()];

declare 'ListInputsResponse',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::ListInputsResponse'];

coerce 'ListInputsResponse',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::ListInputsResponse'->new($_) };

declare 'RepeatedListInputsResponse',
    as ArrayRef[ListInputsResponse()];

coerce 'RepeatedListInputsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::ListInputsResponse'->new($_) } @$_ ] };

declare 'MapStringListInputsResponse',
    as HashRef[ListInputsResponse()];

declare 'GetInputRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::GetInputRequest'];

coerce 'GetInputRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::GetInputRequest'->new($_) };

declare 'RepeatedGetInputRequest',
    as ArrayRef[GetInputRequest()];

coerce 'RepeatedGetInputRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::GetInputRequest'->new($_) } @$_ ] };

declare 'MapStringGetInputRequest',
    as HashRef[GetInputRequest()];

declare 'DeleteInputRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::DeleteInputRequest'];

coerce 'DeleteInputRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::DeleteInputRequest'->new($_) };

declare 'RepeatedDeleteInputRequest',
    as ArrayRef[DeleteInputRequest()];

coerce 'RepeatedDeleteInputRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::DeleteInputRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteInputRequest',
    as HashRef[DeleteInputRequest()];

declare 'UpdateInputRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::UpdateInputRequest'];

coerce 'UpdateInputRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::UpdateInputRequest'->new($_) };

declare 'RepeatedUpdateInputRequest',
    as ArrayRef[UpdateInputRequest()];

coerce 'RepeatedUpdateInputRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::UpdateInputRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateInputRequest',
    as HashRef[UpdateInputRequest()];

declare 'CreateEventRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::CreateEventRequest'];

coerce 'CreateEventRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::CreateEventRequest'->new($_) };

declare 'RepeatedCreateEventRequest',
    as ArrayRef[CreateEventRequest()];

coerce 'RepeatedCreateEventRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::CreateEventRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEventRequest',
    as HashRef[CreateEventRequest()];

declare 'ListEventsRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::ListEventsRequest'];

coerce 'ListEventsRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::ListEventsRequest'->new($_) };

declare 'RepeatedListEventsRequest',
    as ArrayRef[ListEventsRequest()];

coerce 'RepeatedListEventsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::ListEventsRequest'->new($_) } @$_ ] };

declare 'MapStringListEventsRequest',
    as HashRef[ListEventsRequest()];

declare 'ListEventsResponse',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::ListEventsResponse'];

coerce 'ListEventsResponse',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::ListEventsResponse'->new($_) };

declare 'RepeatedListEventsResponse',
    as ArrayRef[ListEventsResponse()];

coerce 'RepeatedListEventsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::ListEventsResponse'->new($_) } @$_ ] };

declare 'MapStringListEventsResponse',
    as HashRef[ListEventsResponse()];

declare 'GetEventRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::GetEventRequest'];

coerce 'GetEventRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::GetEventRequest'->new($_) };

declare 'RepeatedGetEventRequest',
    as ArrayRef[GetEventRequest()];

coerce 'RepeatedGetEventRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::GetEventRequest'->new($_) } @$_ ] };

declare 'MapStringGetEventRequest',
    as HashRef[GetEventRequest()];

declare 'DeleteEventRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::DeleteEventRequest'];

coerce 'DeleteEventRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::DeleteEventRequest'->new($_) };

declare 'RepeatedDeleteEventRequest',
    as ArrayRef[DeleteEventRequest()];

coerce 'RepeatedDeleteEventRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::DeleteEventRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEventRequest',
    as HashRef[DeleteEventRequest()];

declare 'ChannelOperationResponse',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::ChannelOperationResponse'];

coerce 'ChannelOperationResponse',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::ChannelOperationResponse'->new($_) };

declare 'RepeatedChannelOperationResponse',
    as ArrayRef[ChannelOperationResponse()];

coerce 'RepeatedChannelOperationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::ChannelOperationResponse'->new($_) } @$_ ] };

declare 'MapStringChannelOperationResponse',
    as HashRef[ChannelOperationResponse()];

declare 'ListClipsRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::ListClipsRequest'];

coerce 'ListClipsRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::ListClipsRequest'->new($_) };

declare 'RepeatedListClipsRequest',
    as ArrayRef[ListClipsRequest()];

coerce 'RepeatedListClipsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::ListClipsRequest'->new($_) } @$_ ] };

declare 'MapStringListClipsRequest',
    as HashRef[ListClipsRequest()];

declare 'ListClipsResponse',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::ListClipsResponse'];

coerce 'ListClipsResponse',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::ListClipsResponse'->new($_) };

declare 'RepeatedListClipsResponse',
    as ArrayRef[ListClipsResponse()];

coerce 'RepeatedListClipsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::ListClipsResponse'->new($_) } @$_ ] };

declare 'MapStringListClipsResponse',
    as HashRef[ListClipsResponse()];

declare 'GetClipRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::GetClipRequest'];

coerce 'GetClipRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::GetClipRequest'->new($_) };

declare 'RepeatedGetClipRequest',
    as ArrayRef[GetClipRequest()];

coerce 'RepeatedGetClipRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::GetClipRequest'->new($_) } @$_ ] };

declare 'MapStringGetClipRequest',
    as HashRef[GetClipRequest()];

declare 'CreateClipRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::CreateClipRequest'];

coerce 'CreateClipRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::CreateClipRequest'->new($_) };

declare 'RepeatedCreateClipRequest',
    as ArrayRef[CreateClipRequest()];

coerce 'RepeatedCreateClipRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::CreateClipRequest'->new($_) } @$_ ] };

declare 'MapStringCreateClipRequest',
    as HashRef[CreateClipRequest()];

declare 'DeleteClipRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::DeleteClipRequest'];

coerce 'DeleteClipRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::DeleteClipRequest'->new($_) };

declare 'RepeatedDeleteClipRequest',
    as ArrayRef[DeleteClipRequest()];

coerce 'RepeatedDeleteClipRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::DeleteClipRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteClipRequest',
    as HashRef[DeleteClipRequest()];

declare 'ListDvrSessionsRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::ListDvrSessionsRequest'];

coerce 'ListDvrSessionsRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::ListDvrSessionsRequest'->new($_) };

declare 'RepeatedListDvrSessionsRequest',
    as ArrayRef[ListDvrSessionsRequest()];

coerce 'RepeatedListDvrSessionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::ListDvrSessionsRequest'->new($_) } @$_ ] };

declare 'MapStringListDvrSessionsRequest',
    as HashRef[ListDvrSessionsRequest()];

declare 'ListDvrSessionsResponse',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::ListDvrSessionsResponse'];

coerce 'ListDvrSessionsResponse',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::ListDvrSessionsResponse'->new($_) };

declare 'RepeatedListDvrSessionsResponse',
    as ArrayRef[ListDvrSessionsResponse()];

coerce 'RepeatedListDvrSessionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::ListDvrSessionsResponse'->new($_) } @$_ ] };

declare 'MapStringListDvrSessionsResponse',
    as HashRef[ListDvrSessionsResponse()];

declare 'GetDvrSessionRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::GetDvrSessionRequest'];

coerce 'GetDvrSessionRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::GetDvrSessionRequest'->new($_) };

declare 'RepeatedGetDvrSessionRequest',
    as ArrayRef[GetDvrSessionRequest()];

coerce 'RepeatedGetDvrSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::GetDvrSessionRequest'->new($_) } @$_ ] };

declare 'MapStringGetDvrSessionRequest',
    as HashRef[GetDvrSessionRequest()];

declare 'CreateDvrSessionRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::CreateDvrSessionRequest'];

coerce 'CreateDvrSessionRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::CreateDvrSessionRequest'->new($_) };

declare 'RepeatedCreateDvrSessionRequest',
    as ArrayRef[CreateDvrSessionRequest()];

coerce 'RepeatedCreateDvrSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::CreateDvrSessionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDvrSessionRequest',
    as HashRef[CreateDvrSessionRequest()];

declare 'DeleteDvrSessionRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::DeleteDvrSessionRequest'];

coerce 'DeleteDvrSessionRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::DeleteDvrSessionRequest'->new($_) };

declare 'RepeatedDeleteDvrSessionRequest',
    as ArrayRef[DeleteDvrSessionRequest()];

coerce 'RepeatedDeleteDvrSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::DeleteDvrSessionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDvrSessionRequest',
    as HashRef[DeleteDvrSessionRequest()];

declare 'UpdateDvrSessionRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::UpdateDvrSessionRequest'];

coerce 'UpdateDvrSessionRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::UpdateDvrSessionRequest'->new($_) };

declare 'RepeatedUpdateDvrSessionRequest',
    as ArrayRef[UpdateDvrSessionRequest()];

coerce 'RepeatedUpdateDvrSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::UpdateDvrSessionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDvrSessionRequest',
    as HashRef[UpdateDvrSessionRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'GetPoolRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::GetPoolRequest'];

coerce 'GetPoolRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::GetPoolRequest'->new($_) };

declare 'RepeatedGetPoolRequest',
    as ArrayRef[GetPoolRequest()];

coerce 'RepeatedGetPoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::GetPoolRequest'->new($_) } @$_ ] };

declare 'MapStringGetPoolRequest',
    as HashRef[GetPoolRequest()];

declare 'UpdatePoolRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::UpdatePoolRequest'];

coerce 'UpdatePoolRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::UpdatePoolRequest'->new($_) };

declare 'RepeatedUpdatePoolRequest',
    as ArrayRef[UpdatePoolRequest()];

coerce 'RepeatedUpdatePoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::UpdatePoolRequest'->new($_) } @$_ ] };

declare 'MapStringUpdatePoolRequest',
    as HashRef[UpdatePoolRequest()];

declare 'PreviewInputRequest',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::PreviewInputRequest'];

coerce 'PreviewInputRequest',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::PreviewInputRequest'->new($_) };

declare 'RepeatedPreviewInputRequest',
    as ArrayRef[PreviewInputRequest()];

coerce 'RepeatedPreviewInputRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::PreviewInputRequest'->new($_) } @$_ ] };

declare 'MapStringPreviewInputRequest',
    as HashRef[PreviewInputRequest()];

declare 'PreviewInputResponse',
    as InstanceOf['Google::Cloud::Video::Livestream::V1::Service::PreviewInputResponse'];

coerce 'PreviewInputResponse',
    from HashRef, via { 'Google::Cloud::Video::Livestream::V1::Service::PreviewInputResponse'->new($_) };

declare 'RepeatedPreviewInputResponse',
    as ArrayRef[PreviewInputResponse()];

coerce 'RepeatedPreviewInputResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Livestream::V1::Service::PreviewInputResponse'->new($_) } @$_ ] };

declare 'MapStringPreviewInputResponse',
    as HashRef[PreviewInputResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Video::Livestream::V1::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
