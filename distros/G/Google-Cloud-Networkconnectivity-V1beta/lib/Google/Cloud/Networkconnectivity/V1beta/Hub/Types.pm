package Google::Cloud::Networkconnectivity::V1beta::Hub::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RouteType',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'SpokeType',
    as (Int | Str);

declare 'PolicyMode',
    as (Int | Str);

declare 'PresetTopology',
    as (Int | Str);

declare 'LocationFeature',
    as (Int | Str);

declare 'Hub',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::Hub'];

coerce 'Hub',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::Hub'->new($_) };

declare 'RepeatedHub',
    as ArrayRef[Hub()];

coerce 'RepeatedHub',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::Hub'->new($_) } @$_ ] };

declare 'MapStringHub',
    as HashRef[Hub()];

declare 'ExportPscConfig',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::Hub::ExportPscConfig'];

coerce 'ExportPscConfig',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::Hub::ExportPscConfig'->new($_) };

declare 'RepeatedExportPscConfig',
    as ArrayRef[ExportPscConfig()];

coerce 'RepeatedExportPscConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::Hub::ExportPscConfig'->new($_) } @$_ ] };

declare 'MapStringExportPscConfig',
    as HashRef[ExportPscConfig()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::Hub::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::Hub::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::Hub::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'RoutingVPC',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::RoutingVPC'];

coerce 'RoutingVPC',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::RoutingVPC'->new($_) };

declare 'RepeatedRoutingVPC',
    as ArrayRef[RoutingVPC()];

coerce 'RepeatedRoutingVPC',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::RoutingVPC'->new($_) } @$_ ] };

declare 'MapStringRoutingVPC',
    as HashRef[RoutingVPC()];

declare 'Spoke',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::Spoke'];

coerce 'Spoke',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::Spoke'->new($_) };

declare 'RepeatedSpoke',
    as ArrayRef[Spoke()];

coerce 'RepeatedSpoke',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::Spoke'->new($_) } @$_ ] };

declare 'MapStringSpoke',
    as HashRef[Spoke()];

declare 'StateReason',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::Spoke::StateReason'];

coerce 'StateReason',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::Spoke::StateReason'->new($_) };

declare 'RepeatedStateReason',
    as ArrayRef[StateReason()];

coerce 'RepeatedStateReason',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::Spoke::StateReason'->new($_) } @$_ ] };

declare 'MapStringStateReason',
    as HashRef[StateReason()];

declare 'Code',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::Spoke::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::Spoke::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::Spoke::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'RouteTable',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::RouteTable'];

coerce 'RouteTable',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::RouteTable'->new($_) };

declare 'RepeatedRouteTable',
    as ArrayRef[RouteTable()];

coerce 'RepeatedRouteTable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::RouteTable'->new($_) } @$_ ] };

declare 'MapStringRouteTable',
    as HashRef[RouteTable()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::RouteTable::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::RouteTable::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::RouteTable::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Route',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::Route'];

coerce 'Route',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::Route'->new($_) };

declare 'RepeatedRoute',
    as ArrayRef[Route()];

coerce 'RepeatedRoute',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::Route'->new($_) } @$_ ] };

declare 'MapStringRoute',
    as HashRef[Route()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::Route::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::Route::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::Route::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Group',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::Group'];

coerce 'Group',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::Group'->new($_) };

declare 'RepeatedGroup',
    as ArrayRef[Group()];

coerce 'RepeatedGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::Group'->new($_) } @$_ ] };

declare 'MapStringGroup',
    as HashRef[Group()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::Group::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::Group::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::Group::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AutoAccept',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::AutoAccept'];

coerce 'AutoAccept',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::AutoAccept'->new($_) };

declare 'RepeatedAutoAccept',
    as ArrayRef[AutoAccept()];

coerce 'RepeatedAutoAccept',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::AutoAccept'->new($_) } @$_ ] };

declare 'MapStringAutoAccept',
    as HashRef[AutoAccept()];

declare 'ListHubsRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::ListHubsRequest'];

coerce 'ListHubsRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::ListHubsRequest'->new($_) };

declare 'RepeatedListHubsRequest',
    as ArrayRef[ListHubsRequest()];

coerce 'RepeatedListHubsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::ListHubsRequest'->new($_) } @$_ ] };

declare 'MapStringListHubsRequest',
    as HashRef[ListHubsRequest()];

declare 'ListHubsResponse',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::ListHubsResponse'];

coerce 'ListHubsResponse',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::ListHubsResponse'->new($_) };

declare 'RepeatedListHubsResponse',
    as ArrayRef[ListHubsResponse()];

coerce 'RepeatedListHubsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::ListHubsResponse'->new($_) } @$_ ] };

declare 'MapStringListHubsResponse',
    as HashRef[ListHubsResponse()];

declare 'GetHubRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::GetHubRequest'];

coerce 'GetHubRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::GetHubRequest'->new($_) };

declare 'RepeatedGetHubRequest',
    as ArrayRef[GetHubRequest()];

coerce 'RepeatedGetHubRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::GetHubRequest'->new($_) } @$_ ] };

declare 'MapStringGetHubRequest',
    as HashRef[GetHubRequest()];

declare 'CreateHubRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::CreateHubRequest'];

coerce 'CreateHubRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::CreateHubRequest'->new($_) };

declare 'RepeatedCreateHubRequest',
    as ArrayRef[CreateHubRequest()];

coerce 'RepeatedCreateHubRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::CreateHubRequest'->new($_) } @$_ ] };

declare 'MapStringCreateHubRequest',
    as HashRef[CreateHubRequest()];

declare 'UpdateHubRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::UpdateHubRequest'];

coerce 'UpdateHubRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::UpdateHubRequest'->new($_) };

declare 'RepeatedUpdateHubRequest',
    as ArrayRef[UpdateHubRequest()];

coerce 'RepeatedUpdateHubRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::UpdateHubRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateHubRequest',
    as HashRef[UpdateHubRequest()];

declare 'DeleteHubRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::DeleteHubRequest'];

coerce 'DeleteHubRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::DeleteHubRequest'->new($_) };

declare 'RepeatedDeleteHubRequest',
    as ArrayRef[DeleteHubRequest()];

coerce 'RepeatedDeleteHubRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::DeleteHubRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteHubRequest',
    as HashRef[DeleteHubRequest()];

declare 'ListHubSpokesRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::ListHubSpokesRequest'];

coerce 'ListHubSpokesRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::ListHubSpokesRequest'->new($_) };

declare 'RepeatedListHubSpokesRequest',
    as ArrayRef[ListHubSpokesRequest()];

coerce 'RepeatedListHubSpokesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::ListHubSpokesRequest'->new($_) } @$_ ] };

declare 'MapStringListHubSpokesRequest',
    as HashRef[ListHubSpokesRequest()];

declare 'SpokeView',
    as (Int | Str);

declare 'ListHubSpokesResponse',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::ListHubSpokesResponse'];

coerce 'ListHubSpokesResponse',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::ListHubSpokesResponse'->new($_) };

declare 'RepeatedListHubSpokesResponse',
    as ArrayRef[ListHubSpokesResponse()];

coerce 'RepeatedListHubSpokesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::ListHubSpokesResponse'->new($_) } @$_ ] };

declare 'MapStringListHubSpokesResponse',
    as HashRef[ListHubSpokesResponse()];

declare 'QueryHubStatusRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::QueryHubStatusRequest'];

coerce 'QueryHubStatusRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::QueryHubStatusRequest'->new($_) };

declare 'RepeatedQueryHubStatusRequest',
    as ArrayRef[QueryHubStatusRequest()];

coerce 'RepeatedQueryHubStatusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::QueryHubStatusRequest'->new($_) } @$_ ] };

declare 'MapStringQueryHubStatusRequest',
    as HashRef[QueryHubStatusRequest()];

declare 'QueryHubStatusResponse',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::QueryHubStatusResponse'];

coerce 'QueryHubStatusResponse',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::QueryHubStatusResponse'->new($_) };

declare 'RepeatedQueryHubStatusResponse',
    as ArrayRef[QueryHubStatusResponse()];

coerce 'RepeatedQueryHubStatusResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::QueryHubStatusResponse'->new($_) } @$_ ] };

declare 'MapStringQueryHubStatusResponse',
    as HashRef[QueryHubStatusResponse()];

declare 'HubStatusEntry',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::HubStatusEntry'];

coerce 'HubStatusEntry',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::HubStatusEntry'->new($_) };

declare 'RepeatedHubStatusEntry',
    as ArrayRef[HubStatusEntry()];

coerce 'RepeatedHubStatusEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::HubStatusEntry'->new($_) } @$_ ] };

declare 'MapStringHubStatusEntry',
    as HashRef[HubStatusEntry()];

declare 'PscPropagationStatus',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::PscPropagationStatus'];

coerce 'PscPropagationStatus',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::PscPropagationStatus'->new($_) };

declare 'RepeatedPscPropagationStatus',
    as ArrayRef[PscPropagationStatus()];

coerce 'RepeatedPscPropagationStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::PscPropagationStatus'->new($_) } @$_ ] };

declare 'MapStringPscPropagationStatus',
    as HashRef[PscPropagationStatus()];

declare 'Code',
    as (Int | Str);

declare 'ListSpokesRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::ListSpokesRequest'];

coerce 'ListSpokesRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::ListSpokesRequest'->new($_) };

declare 'RepeatedListSpokesRequest',
    as ArrayRef[ListSpokesRequest()];

coerce 'RepeatedListSpokesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::ListSpokesRequest'->new($_) } @$_ ] };

declare 'MapStringListSpokesRequest',
    as HashRef[ListSpokesRequest()];

declare 'ListSpokesResponse',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::ListSpokesResponse'];

coerce 'ListSpokesResponse',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::ListSpokesResponse'->new($_) };

declare 'RepeatedListSpokesResponse',
    as ArrayRef[ListSpokesResponse()];

coerce 'RepeatedListSpokesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::ListSpokesResponse'->new($_) } @$_ ] };

declare 'MapStringListSpokesResponse',
    as HashRef[ListSpokesResponse()];

declare 'GetSpokeRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::GetSpokeRequest'];

coerce 'GetSpokeRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::GetSpokeRequest'->new($_) };

declare 'RepeatedGetSpokeRequest',
    as ArrayRef[GetSpokeRequest()];

coerce 'RepeatedGetSpokeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::GetSpokeRequest'->new($_) } @$_ ] };

declare 'MapStringGetSpokeRequest',
    as HashRef[GetSpokeRequest()];

declare 'CreateSpokeRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::CreateSpokeRequest'];

coerce 'CreateSpokeRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::CreateSpokeRequest'->new($_) };

declare 'RepeatedCreateSpokeRequest',
    as ArrayRef[CreateSpokeRequest()];

coerce 'RepeatedCreateSpokeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::CreateSpokeRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSpokeRequest',
    as HashRef[CreateSpokeRequest()];

declare 'UpdateSpokeRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::UpdateSpokeRequest'];

coerce 'UpdateSpokeRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::UpdateSpokeRequest'->new($_) };

declare 'RepeatedUpdateSpokeRequest',
    as ArrayRef[UpdateSpokeRequest()];

coerce 'RepeatedUpdateSpokeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::UpdateSpokeRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSpokeRequest',
    as HashRef[UpdateSpokeRequest()];

declare 'DeleteSpokeRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::DeleteSpokeRequest'];

coerce 'DeleteSpokeRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::DeleteSpokeRequest'->new($_) };

declare 'RepeatedDeleteSpokeRequest',
    as ArrayRef[DeleteSpokeRequest()];

coerce 'RepeatedDeleteSpokeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::DeleteSpokeRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSpokeRequest',
    as HashRef[DeleteSpokeRequest()];

declare 'AcceptHubSpokeRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::AcceptHubSpokeRequest'];

coerce 'AcceptHubSpokeRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::AcceptHubSpokeRequest'->new($_) };

declare 'RepeatedAcceptHubSpokeRequest',
    as ArrayRef[AcceptHubSpokeRequest()];

coerce 'RepeatedAcceptHubSpokeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::AcceptHubSpokeRequest'->new($_) } @$_ ] };

declare 'MapStringAcceptHubSpokeRequest',
    as HashRef[AcceptHubSpokeRequest()];

declare 'AcceptHubSpokeResponse',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::AcceptHubSpokeResponse'];

coerce 'AcceptHubSpokeResponse',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::AcceptHubSpokeResponse'->new($_) };

declare 'RepeatedAcceptHubSpokeResponse',
    as ArrayRef[AcceptHubSpokeResponse()];

coerce 'RepeatedAcceptHubSpokeResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::AcceptHubSpokeResponse'->new($_) } @$_ ] };

declare 'MapStringAcceptHubSpokeResponse',
    as HashRef[AcceptHubSpokeResponse()];

declare 'RejectHubSpokeRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::RejectHubSpokeRequest'];

coerce 'RejectHubSpokeRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::RejectHubSpokeRequest'->new($_) };

declare 'RepeatedRejectHubSpokeRequest',
    as ArrayRef[RejectHubSpokeRequest()];

coerce 'RepeatedRejectHubSpokeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::RejectHubSpokeRequest'->new($_) } @$_ ] };

declare 'MapStringRejectHubSpokeRequest',
    as HashRef[RejectHubSpokeRequest()];

declare 'RejectHubSpokeResponse',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::RejectHubSpokeResponse'];

coerce 'RejectHubSpokeResponse',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::RejectHubSpokeResponse'->new($_) };

declare 'RepeatedRejectHubSpokeResponse',
    as ArrayRef[RejectHubSpokeResponse()];

coerce 'RepeatedRejectHubSpokeResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::RejectHubSpokeResponse'->new($_) } @$_ ] };

declare 'MapStringRejectHubSpokeResponse',
    as HashRef[RejectHubSpokeResponse()];

declare 'AcceptSpokeUpdateRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::AcceptSpokeUpdateRequest'];

coerce 'AcceptSpokeUpdateRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::AcceptSpokeUpdateRequest'->new($_) };

declare 'RepeatedAcceptSpokeUpdateRequest',
    as ArrayRef[AcceptSpokeUpdateRequest()];

coerce 'RepeatedAcceptSpokeUpdateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::AcceptSpokeUpdateRequest'->new($_) } @$_ ] };

declare 'MapStringAcceptSpokeUpdateRequest',
    as HashRef[AcceptSpokeUpdateRequest()];

declare 'AcceptSpokeUpdateResponse',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::AcceptSpokeUpdateResponse'];

coerce 'AcceptSpokeUpdateResponse',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::AcceptSpokeUpdateResponse'->new($_) };

declare 'RepeatedAcceptSpokeUpdateResponse',
    as ArrayRef[AcceptSpokeUpdateResponse()];

coerce 'RepeatedAcceptSpokeUpdateResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::AcceptSpokeUpdateResponse'->new($_) } @$_ ] };

declare 'MapStringAcceptSpokeUpdateResponse',
    as HashRef[AcceptSpokeUpdateResponse()];

declare 'RejectSpokeUpdateRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::RejectSpokeUpdateRequest'];

coerce 'RejectSpokeUpdateRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::RejectSpokeUpdateRequest'->new($_) };

declare 'RepeatedRejectSpokeUpdateRequest',
    as ArrayRef[RejectSpokeUpdateRequest()];

coerce 'RepeatedRejectSpokeUpdateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::RejectSpokeUpdateRequest'->new($_) } @$_ ] };

declare 'MapStringRejectSpokeUpdateRequest',
    as HashRef[RejectSpokeUpdateRequest()];

declare 'RejectSpokeUpdateResponse',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::RejectSpokeUpdateResponse'];

coerce 'RejectSpokeUpdateResponse',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::RejectSpokeUpdateResponse'->new($_) };

declare 'RepeatedRejectSpokeUpdateResponse',
    as ArrayRef[RejectSpokeUpdateResponse()];

coerce 'RepeatedRejectSpokeUpdateResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::RejectSpokeUpdateResponse'->new($_) } @$_ ] };

declare 'MapStringRejectSpokeUpdateResponse',
    as HashRef[RejectSpokeUpdateResponse()];

declare 'GetRouteTableRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::GetRouteTableRequest'];

coerce 'GetRouteTableRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::GetRouteTableRequest'->new($_) };

declare 'RepeatedGetRouteTableRequest',
    as ArrayRef[GetRouteTableRequest()];

coerce 'RepeatedGetRouteTableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::GetRouteTableRequest'->new($_) } @$_ ] };

declare 'MapStringGetRouteTableRequest',
    as HashRef[GetRouteTableRequest()];

declare 'GetRouteRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::GetRouteRequest'];

coerce 'GetRouteRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::GetRouteRequest'->new($_) };

declare 'RepeatedGetRouteRequest',
    as ArrayRef[GetRouteRequest()];

coerce 'RepeatedGetRouteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::GetRouteRequest'->new($_) } @$_ ] };

declare 'MapStringGetRouteRequest',
    as HashRef[GetRouteRequest()];

declare 'ListRoutesRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::ListRoutesRequest'];

coerce 'ListRoutesRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::ListRoutesRequest'->new($_) };

declare 'RepeatedListRoutesRequest',
    as ArrayRef[ListRoutesRequest()];

coerce 'RepeatedListRoutesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::ListRoutesRequest'->new($_) } @$_ ] };

declare 'MapStringListRoutesRequest',
    as HashRef[ListRoutesRequest()];

declare 'ListRoutesResponse',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::ListRoutesResponse'];

coerce 'ListRoutesResponse',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::ListRoutesResponse'->new($_) };

declare 'RepeatedListRoutesResponse',
    as ArrayRef[ListRoutesResponse()];

coerce 'RepeatedListRoutesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::ListRoutesResponse'->new($_) } @$_ ] };

declare 'MapStringListRoutesResponse',
    as HashRef[ListRoutesResponse()];

declare 'ListRouteTablesRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::ListRouteTablesRequest'];

coerce 'ListRouteTablesRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::ListRouteTablesRequest'->new($_) };

declare 'RepeatedListRouteTablesRequest',
    as ArrayRef[ListRouteTablesRequest()];

coerce 'RepeatedListRouteTablesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::ListRouteTablesRequest'->new($_) } @$_ ] };

declare 'MapStringListRouteTablesRequest',
    as HashRef[ListRouteTablesRequest()];

declare 'ListRouteTablesResponse',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::ListRouteTablesResponse'];

coerce 'ListRouteTablesResponse',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::ListRouteTablesResponse'->new($_) };

declare 'RepeatedListRouteTablesResponse',
    as ArrayRef[ListRouteTablesResponse()];

coerce 'RepeatedListRouteTablesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::ListRouteTablesResponse'->new($_) } @$_ ] };

declare 'MapStringListRouteTablesResponse',
    as HashRef[ListRouteTablesResponse()];

declare 'ListGroupsRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::ListGroupsRequest'];

coerce 'ListGroupsRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::ListGroupsRequest'->new($_) };

declare 'RepeatedListGroupsRequest',
    as ArrayRef[ListGroupsRequest()];

coerce 'RepeatedListGroupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::ListGroupsRequest'->new($_) } @$_ ] };

declare 'MapStringListGroupsRequest',
    as HashRef[ListGroupsRequest()];

declare 'ListGroupsResponse',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::ListGroupsResponse'];

coerce 'ListGroupsResponse',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::ListGroupsResponse'->new($_) };

declare 'RepeatedListGroupsResponse',
    as ArrayRef[ListGroupsResponse()];

coerce 'RepeatedListGroupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::ListGroupsResponse'->new($_) } @$_ ] };

declare 'MapStringListGroupsResponse',
    as HashRef[ListGroupsResponse()];

declare 'LinkedVpnTunnels',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::LinkedVpnTunnels'];

coerce 'LinkedVpnTunnels',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::LinkedVpnTunnels'->new($_) };

declare 'RepeatedLinkedVpnTunnels',
    as ArrayRef[LinkedVpnTunnels()];

coerce 'RepeatedLinkedVpnTunnels',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::LinkedVpnTunnels'->new($_) } @$_ ] };

declare 'MapStringLinkedVpnTunnels',
    as HashRef[LinkedVpnTunnels()];

declare 'LinkedInterconnectAttachments',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::LinkedInterconnectAttachments'];

coerce 'LinkedInterconnectAttachments',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::LinkedInterconnectAttachments'->new($_) };

declare 'RepeatedLinkedInterconnectAttachments',
    as ArrayRef[LinkedInterconnectAttachments()];

coerce 'RepeatedLinkedInterconnectAttachments',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::LinkedInterconnectAttachments'->new($_) } @$_ ] };

declare 'MapStringLinkedInterconnectAttachments',
    as HashRef[LinkedInterconnectAttachments()];

declare 'LinkedRouterApplianceInstances',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::LinkedRouterApplianceInstances'];

coerce 'LinkedRouterApplianceInstances',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::LinkedRouterApplianceInstances'->new($_) };

declare 'RepeatedLinkedRouterApplianceInstances',
    as ArrayRef[LinkedRouterApplianceInstances()];

coerce 'RepeatedLinkedRouterApplianceInstances',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::LinkedRouterApplianceInstances'->new($_) } @$_ ] };

declare 'MapStringLinkedRouterApplianceInstances',
    as HashRef[LinkedRouterApplianceInstances()];

declare 'LinkedVpcNetwork',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::LinkedVpcNetwork'];

coerce 'LinkedVpcNetwork',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::LinkedVpcNetwork'->new($_) };

declare 'RepeatedLinkedVpcNetwork',
    as ArrayRef[LinkedVpcNetwork()];

coerce 'RepeatedLinkedVpcNetwork',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::LinkedVpcNetwork'->new($_) } @$_ ] };

declare 'MapStringLinkedVpcNetwork',
    as HashRef[LinkedVpcNetwork()];

declare 'Gateway',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::Gateway'];

coerce 'Gateway',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::Gateway'->new($_) };

declare 'RepeatedGateway',
    as ArrayRef[Gateway()];

coerce 'RepeatedGateway',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::Gateway'->new($_) } @$_ ] };

declare 'MapStringGateway',
    as HashRef[Gateway()];

declare 'GatewayCapacity',
    as (Int | Str);

declare 'IpRangeReservation',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::Gateway::IpRangeReservation'];

coerce 'IpRangeReservation',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::Gateway::IpRangeReservation'->new($_) };

declare 'RepeatedIpRangeReservation',
    as ArrayRef[IpRangeReservation()];

coerce 'RepeatedIpRangeReservation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::Gateway::IpRangeReservation'->new($_) } @$_ ] };

declare 'MapStringIpRangeReservation',
    as HashRef[IpRangeReservation()];

declare 'GatewayAdvertisedRoute',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::GatewayAdvertisedRoute'];

coerce 'GatewayAdvertisedRoute',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::GatewayAdvertisedRoute'->new($_) };

declare 'RepeatedGatewayAdvertisedRoute',
    as ArrayRef[GatewayAdvertisedRoute()];

coerce 'RepeatedGatewayAdvertisedRoute',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::GatewayAdvertisedRoute'->new($_) } @$_ ] };

declare 'MapStringGatewayAdvertisedRoute',
    as HashRef[GatewayAdvertisedRoute()];

declare 'Recipient',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::GatewayAdvertisedRoute::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::GatewayAdvertisedRoute::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::GatewayAdvertisedRoute::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'CreateGatewayAdvertisedRouteRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::CreateGatewayAdvertisedRouteRequest'];

coerce 'CreateGatewayAdvertisedRouteRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::CreateGatewayAdvertisedRouteRequest'->new($_) };

declare 'RepeatedCreateGatewayAdvertisedRouteRequest',
    as ArrayRef[CreateGatewayAdvertisedRouteRequest()];

coerce 'RepeatedCreateGatewayAdvertisedRouteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::CreateGatewayAdvertisedRouteRequest'->new($_) } @$_ ] };

declare 'MapStringCreateGatewayAdvertisedRouteRequest',
    as HashRef[CreateGatewayAdvertisedRouteRequest()];

declare 'GetGatewayAdvertisedRouteRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::GetGatewayAdvertisedRouteRequest'];

coerce 'GetGatewayAdvertisedRouteRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::GetGatewayAdvertisedRouteRequest'->new($_) };

declare 'RepeatedGetGatewayAdvertisedRouteRequest',
    as ArrayRef[GetGatewayAdvertisedRouteRequest()];

coerce 'RepeatedGetGatewayAdvertisedRouteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::GetGatewayAdvertisedRouteRequest'->new($_) } @$_ ] };

declare 'MapStringGetGatewayAdvertisedRouteRequest',
    as HashRef[GetGatewayAdvertisedRouteRequest()];

declare 'ListGatewayAdvertisedRoutesRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::ListGatewayAdvertisedRoutesRequest'];

coerce 'ListGatewayAdvertisedRoutesRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::ListGatewayAdvertisedRoutesRequest'->new($_) };

declare 'RepeatedListGatewayAdvertisedRoutesRequest',
    as ArrayRef[ListGatewayAdvertisedRoutesRequest()];

coerce 'RepeatedListGatewayAdvertisedRoutesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::ListGatewayAdvertisedRoutesRequest'->new($_) } @$_ ] };

declare 'MapStringListGatewayAdvertisedRoutesRequest',
    as HashRef[ListGatewayAdvertisedRoutesRequest()];

declare 'ListGatewayAdvertisedRoutesResponse',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::ListGatewayAdvertisedRoutesResponse'];

coerce 'ListGatewayAdvertisedRoutesResponse',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::ListGatewayAdvertisedRoutesResponse'->new($_) };

declare 'RepeatedListGatewayAdvertisedRoutesResponse',
    as ArrayRef[ListGatewayAdvertisedRoutesResponse()];

coerce 'RepeatedListGatewayAdvertisedRoutesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::ListGatewayAdvertisedRoutesResponse'->new($_) } @$_ ] };

declare 'MapStringListGatewayAdvertisedRoutesResponse',
    as HashRef[ListGatewayAdvertisedRoutesResponse()];

declare 'UpdateGatewayAdvertisedRouteRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::UpdateGatewayAdvertisedRouteRequest'];

coerce 'UpdateGatewayAdvertisedRouteRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::UpdateGatewayAdvertisedRouteRequest'->new($_) };

declare 'RepeatedUpdateGatewayAdvertisedRouteRequest',
    as ArrayRef[UpdateGatewayAdvertisedRouteRequest()];

coerce 'RepeatedUpdateGatewayAdvertisedRouteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::UpdateGatewayAdvertisedRouteRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateGatewayAdvertisedRouteRequest',
    as HashRef[UpdateGatewayAdvertisedRouteRequest()];

declare 'DeleteGatewayAdvertisedRouteRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::DeleteGatewayAdvertisedRouteRequest'];

coerce 'DeleteGatewayAdvertisedRouteRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::DeleteGatewayAdvertisedRouteRequest'->new($_) };

declare 'RepeatedDeleteGatewayAdvertisedRouteRequest',
    as ArrayRef[DeleteGatewayAdvertisedRouteRequest()];

coerce 'RepeatedDeleteGatewayAdvertisedRouteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::DeleteGatewayAdvertisedRouteRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteGatewayAdvertisedRouteRequest',
    as HashRef[DeleteGatewayAdvertisedRouteRequest()];

declare 'LinkedProducerVpcNetwork',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::LinkedProducerVpcNetwork'];

coerce 'LinkedProducerVpcNetwork',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::LinkedProducerVpcNetwork'->new($_) };

declare 'RepeatedLinkedProducerVpcNetwork',
    as ArrayRef[LinkedProducerVpcNetwork()];

coerce 'RepeatedLinkedProducerVpcNetwork',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::LinkedProducerVpcNetwork'->new($_) } @$_ ] };

declare 'MapStringLinkedProducerVpcNetwork',
    as HashRef[LinkedProducerVpcNetwork()];

declare 'RouterApplianceInstance',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::RouterApplianceInstance'];

coerce 'RouterApplianceInstance',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::RouterApplianceInstance'->new($_) };

declare 'RepeatedRouterApplianceInstance',
    as ArrayRef[RouterApplianceInstance()];

coerce 'RepeatedRouterApplianceInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::RouterApplianceInstance'->new($_) } @$_ ] };

declare 'MapStringRouterApplianceInstance',
    as HashRef[RouterApplianceInstance()];

declare 'LocationMetadata',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::LocationMetadata'];

coerce 'LocationMetadata',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::LocationMetadata'->new($_) };

declare 'RepeatedLocationMetadata',
    as ArrayRef[LocationMetadata()];

coerce 'RepeatedLocationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::LocationMetadata'->new($_) } @$_ ] };

declare 'MapStringLocationMetadata',
    as HashRef[LocationMetadata()];

declare 'NextHopVpcNetwork',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::NextHopVpcNetwork'];

coerce 'NextHopVpcNetwork',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::NextHopVpcNetwork'->new($_) };

declare 'RepeatedNextHopVpcNetwork',
    as ArrayRef[NextHopVpcNetwork()];

coerce 'RepeatedNextHopVpcNetwork',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::NextHopVpcNetwork'->new($_) } @$_ ] };

declare 'MapStringNextHopVpcNetwork',
    as HashRef[NextHopVpcNetwork()];

declare 'NextHopVPNTunnel',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::NextHopVPNTunnel'];

coerce 'NextHopVPNTunnel',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::NextHopVPNTunnel'->new($_) };

declare 'RepeatedNextHopVPNTunnel',
    as ArrayRef[NextHopVPNTunnel()];

coerce 'RepeatedNextHopVPNTunnel',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::NextHopVPNTunnel'->new($_) } @$_ ] };

declare 'MapStringNextHopVPNTunnel',
    as HashRef[NextHopVPNTunnel()];

declare 'NextHopRouterApplianceInstance',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::NextHopRouterApplianceInstance'];

coerce 'NextHopRouterApplianceInstance',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::NextHopRouterApplianceInstance'->new($_) };

declare 'RepeatedNextHopRouterApplianceInstance',
    as ArrayRef[NextHopRouterApplianceInstance()];

coerce 'RepeatedNextHopRouterApplianceInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::NextHopRouterApplianceInstance'->new($_) } @$_ ] };

declare 'MapStringNextHopRouterApplianceInstance',
    as HashRef[NextHopRouterApplianceInstance()];

declare 'NextHopInterconnectAttachment',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::NextHopInterconnectAttachment'];

coerce 'NextHopInterconnectAttachment',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::NextHopInterconnectAttachment'->new($_) };

declare 'RepeatedNextHopInterconnectAttachment',
    as ArrayRef[NextHopInterconnectAttachment()];

coerce 'RepeatedNextHopInterconnectAttachment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::NextHopInterconnectAttachment'->new($_) } @$_ ] };

declare 'MapStringNextHopInterconnectAttachment',
    as HashRef[NextHopInterconnectAttachment()];

declare 'NextHopSpoke',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::NextHopSpoke'];

coerce 'NextHopSpoke',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::NextHopSpoke'->new($_) };

declare 'RepeatedNextHopSpoke',
    as ArrayRef[NextHopSpoke()];

coerce 'RepeatedNextHopSpoke',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::NextHopSpoke'->new($_) } @$_ ] };

declare 'MapStringNextHopSpoke',
    as HashRef[NextHopSpoke()];

declare 'SpokeSummary',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::SpokeSummary'];

coerce 'SpokeSummary',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::SpokeSummary'->new($_) };

declare 'RepeatedSpokeSummary',
    as ArrayRef[SpokeSummary()];

coerce 'RepeatedSpokeSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::SpokeSummary'->new($_) } @$_ ] };

declare 'MapStringSpokeSummary',
    as HashRef[SpokeSummary()];

declare 'SpokeTypeCount',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::SpokeSummary::SpokeTypeCount'];

coerce 'SpokeTypeCount',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::SpokeSummary::SpokeTypeCount'->new($_) };

declare 'RepeatedSpokeTypeCount',
    as ArrayRef[SpokeTypeCount()];

coerce 'RepeatedSpokeTypeCount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::SpokeSummary::SpokeTypeCount'->new($_) } @$_ ] };

declare 'MapStringSpokeTypeCount',
    as HashRef[SpokeTypeCount()];

declare 'SpokeStateCount',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::SpokeSummary::SpokeStateCount'];

coerce 'SpokeStateCount',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::SpokeSummary::SpokeStateCount'->new($_) };

declare 'RepeatedSpokeStateCount',
    as ArrayRef[SpokeStateCount()];

coerce 'RepeatedSpokeStateCount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::SpokeSummary::SpokeStateCount'->new($_) } @$_ ] };

declare 'MapStringSpokeStateCount',
    as HashRef[SpokeStateCount()];

declare 'SpokeStateReasonCount',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::SpokeSummary::SpokeStateReasonCount'];

coerce 'SpokeStateReasonCount',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::SpokeSummary::SpokeStateReasonCount'->new($_) };

declare 'RepeatedSpokeStateReasonCount',
    as ArrayRef[SpokeStateReasonCount()];

coerce 'RepeatedSpokeStateReasonCount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::SpokeSummary::SpokeStateReasonCount'->new($_) } @$_ ] };

declare 'MapStringSpokeStateReasonCount',
    as HashRef[SpokeStateReasonCount()];

declare 'GetGroupRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::GetGroupRequest'];

coerce 'GetGroupRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::GetGroupRequest'->new($_) };

declare 'RepeatedGetGroupRequest',
    as ArrayRef[GetGroupRequest()];

coerce 'RepeatedGetGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::GetGroupRequest'->new($_) } @$_ ] };

declare 'MapStringGetGroupRequest',
    as HashRef[GetGroupRequest()];

declare 'UpdateGroupRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::Hub::UpdateGroupRequest'];

coerce 'UpdateGroupRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::Hub::UpdateGroupRequest'->new($_) };

declare 'RepeatedUpdateGroupRequest',
    as ArrayRef[UpdateGroupRequest()];

coerce 'RepeatedUpdateGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::Hub::UpdateGroupRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateGroupRequest',
    as HashRef[UpdateGroupRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Networkconnectivity::V1beta::Hub::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
