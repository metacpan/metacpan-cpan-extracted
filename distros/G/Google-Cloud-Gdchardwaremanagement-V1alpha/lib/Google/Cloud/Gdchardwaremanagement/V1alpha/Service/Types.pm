package Google::Cloud::Gdchardwaremanagement::V1alpha::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListOrdersRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListOrdersRequest'];

coerce 'ListOrdersRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListOrdersRequest'->new($_) };

declare 'RepeatedListOrdersRequest',
    as ArrayRef[ListOrdersRequest()];

coerce 'RepeatedListOrdersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListOrdersRequest'->new($_) } @$_ ] };

declare 'MapStringListOrdersRequest',
    as HashRef[ListOrdersRequest()];

declare 'ListOrdersResponse',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListOrdersResponse'];

coerce 'ListOrdersResponse',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListOrdersResponse'->new($_) };

declare 'RepeatedListOrdersResponse',
    as ArrayRef[ListOrdersResponse()];

coerce 'RepeatedListOrdersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListOrdersResponse'->new($_) } @$_ ] };

declare 'MapStringListOrdersResponse',
    as HashRef[ListOrdersResponse()];

declare 'GetOrderRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::GetOrderRequest'];

coerce 'GetOrderRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::GetOrderRequest'->new($_) };

declare 'RepeatedGetOrderRequest',
    as ArrayRef[GetOrderRequest()];

coerce 'RepeatedGetOrderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::GetOrderRequest'->new($_) } @$_ ] };

declare 'MapStringGetOrderRequest',
    as HashRef[GetOrderRequest()];

declare 'CreateOrderRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::CreateOrderRequest'];

coerce 'CreateOrderRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::CreateOrderRequest'->new($_) };

declare 'RepeatedCreateOrderRequest',
    as ArrayRef[CreateOrderRequest()];

coerce 'RepeatedCreateOrderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::CreateOrderRequest'->new($_) } @$_ ] };

declare 'MapStringCreateOrderRequest',
    as HashRef[CreateOrderRequest()];

declare 'UpdateOrderRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::UpdateOrderRequest'];

coerce 'UpdateOrderRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::UpdateOrderRequest'->new($_) };

declare 'RepeatedUpdateOrderRequest',
    as ArrayRef[UpdateOrderRequest()];

coerce 'RepeatedUpdateOrderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::UpdateOrderRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateOrderRequest',
    as HashRef[UpdateOrderRequest()];

declare 'DeleteOrderRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::DeleteOrderRequest'];

coerce 'DeleteOrderRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::DeleteOrderRequest'->new($_) };

declare 'RepeatedDeleteOrderRequest',
    as ArrayRef[DeleteOrderRequest()];

coerce 'RepeatedDeleteOrderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::DeleteOrderRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteOrderRequest',
    as HashRef[DeleteOrderRequest()];

declare 'SubmitOrderRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::SubmitOrderRequest'];

coerce 'SubmitOrderRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::SubmitOrderRequest'->new($_) };

declare 'RepeatedSubmitOrderRequest',
    as ArrayRef[SubmitOrderRequest()];

coerce 'RepeatedSubmitOrderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::SubmitOrderRequest'->new($_) } @$_ ] };

declare 'MapStringSubmitOrderRequest',
    as HashRef[SubmitOrderRequest()];

declare 'Type',
    as (Int | Str);

declare 'CancelOrderRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::CancelOrderRequest'];

coerce 'CancelOrderRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::CancelOrderRequest'->new($_) };

declare 'RepeatedCancelOrderRequest',
    as ArrayRef[CancelOrderRequest()];

coerce 'RepeatedCancelOrderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::CancelOrderRequest'->new($_) } @$_ ] };

declare 'MapStringCancelOrderRequest',
    as HashRef[CancelOrderRequest()];

declare 'ListSitesRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListSitesRequest'];

coerce 'ListSitesRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListSitesRequest'->new($_) };

declare 'RepeatedListSitesRequest',
    as ArrayRef[ListSitesRequest()];

coerce 'RepeatedListSitesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListSitesRequest'->new($_) } @$_ ] };

declare 'MapStringListSitesRequest',
    as HashRef[ListSitesRequest()];

declare 'ListSitesResponse',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListSitesResponse'];

coerce 'ListSitesResponse',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListSitesResponse'->new($_) };

declare 'RepeatedListSitesResponse',
    as ArrayRef[ListSitesResponse()];

coerce 'RepeatedListSitesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListSitesResponse'->new($_) } @$_ ] };

declare 'MapStringListSitesResponse',
    as HashRef[ListSitesResponse()];

declare 'GetSiteRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::GetSiteRequest'];

coerce 'GetSiteRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::GetSiteRequest'->new($_) };

declare 'RepeatedGetSiteRequest',
    as ArrayRef[GetSiteRequest()];

coerce 'RepeatedGetSiteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::GetSiteRequest'->new($_) } @$_ ] };

declare 'MapStringGetSiteRequest',
    as HashRef[GetSiteRequest()];

declare 'CreateSiteRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::CreateSiteRequest'];

coerce 'CreateSiteRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::CreateSiteRequest'->new($_) };

declare 'RepeatedCreateSiteRequest',
    as ArrayRef[CreateSiteRequest()];

coerce 'RepeatedCreateSiteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::CreateSiteRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSiteRequest',
    as HashRef[CreateSiteRequest()];

declare 'UpdateSiteRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::UpdateSiteRequest'];

coerce 'UpdateSiteRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::UpdateSiteRequest'->new($_) };

declare 'RepeatedUpdateSiteRequest',
    as ArrayRef[UpdateSiteRequest()];

coerce 'RepeatedUpdateSiteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::UpdateSiteRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSiteRequest',
    as HashRef[UpdateSiteRequest()];

declare 'DeleteSiteRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::DeleteSiteRequest'];

coerce 'DeleteSiteRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::DeleteSiteRequest'->new($_) };

declare 'RepeatedDeleteSiteRequest',
    as ArrayRef[DeleteSiteRequest()];

coerce 'RepeatedDeleteSiteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::DeleteSiteRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSiteRequest',
    as HashRef[DeleteSiteRequest()];

declare 'ListHardwareGroupsRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListHardwareGroupsRequest'];

coerce 'ListHardwareGroupsRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListHardwareGroupsRequest'->new($_) };

declare 'RepeatedListHardwareGroupsRequest',
    as ArrayRef[ListHardwareGroupsRequest()];

coerce 'RepeatedListHardwareGroupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListHardwareGroupsRequest'->new($_) } @$_ ] };

declare 'MapStringListHardwareGroupsRequest',
    as HashRef[ListHardwareGroupsRequest()];

declare 'ListHardwareGroupsResponse',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListHardwareGroupsResponse'];

coerce 'ListHardwareGroupsResponse',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListHardwareGroupsResponse'->new($_) };

declare 'RepeatedListHardwareGroupsResponse',
    as ArrayRef[ListHardwareGroupsResponse()];

coerce 'RepeatedListHardwareGroupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListHardwareGroupsResponse'->new($_) } @$_ ] };

declare 'MapStringListHardwareGroupsResponse',
    as HashRef[ListHardwareGroupsResponse()];

declare 'GetHardwareGroupRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::GetHardwareGroupRequest'];

coerce 'GetHardwareGroupRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::GetHardwareGroupRequest'->new($_) };

declare 'RepeatedGetHardwareGroupRequest',
    as ArrayRef[GetHardwareGroupRequest()];

coerce 'RepeatedGetHardwareGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::GetHardwareGroupRequest'->new($_) } @$_ ] };

declare 'MapStringGetHardwareGroupRequest',
    as HashRef[GetHardwareGroupRequest()];

declare 'CreateHardwareGroupRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::CreateHardwareGroupRequest'];

coerce 'CreateHardwareGroupRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::CreateHardwareGroupRequest'->new($_) };

declare 'RepeatedCreateHardwareGroupRequest',
    as ArrayRef[CreateHardwareGroupRequest()];

coerce 'RepeatedCreateHardwareGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::CreateHardwareGroupRequest'->new($_) } @$_ ] };

declare 'MapStringCreateHardwareGroupRequest',
    as HashRef[CreateHardwareGroupRequest()];

declare 'UpdateHardwareGroupRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::UpdateHardwareGroupRequest'];

coerce 'UpdateHardwareGroupRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::UpdateHardwareGroupRequest'->new($_) };

declare 'RepeatedUpdateHardwareGroupRequest',
    as ArrayRef[UpdateHardwareGroupRequest()];

coerce 'RepeatedUpdateHardwareGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::UpdateHardwareGroupRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateHardwareGroupRequest',
    as HashRef[UpdateHardwareGroupRequest()];

declare 'DeleteHardwareGroupRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::DeleteHardwareGroupRequest'];

coerce 'DeleteHardwareGroupRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::DeleteHardwareGroupRequest'->new($_) };

declare 'RepeatedDeleteHardwareGroupRequest',
    as ArrayRef[DeleteHardwareGroupRequest()];

coerce 'RepeatedDeleteHardwareGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::DeleteHardwareGroupRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteHardwareGroupRequest',
    as HashRef[DeleteHardwareGroupRequest()];

declare 'ListHardwareRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListHardwareRequest'];

coerce 'ListHardwareRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListHardwareRequest'->new($_) };

declare 'RepeatedListHardwareRequest',
    as ArrayRef[ListHardwareRequest()];

coerce 'RepeatedListHardwareRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListHardwareRequest'->new($_) } @$_ ] };

declare 'MapStringListHardwareRequest',
    as HashRef[ListHardwareRequest()];

declare 'ListHardwareResponse',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListHardwareResponse'];

coerce 'ListHardwareResponse',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListHardwareResponse'->new($_) };

declare 'RepeatedListHardwareResponse',
    as ArrayRef[ListHardwareResponse()];

coerce 'RepeatedListHardwareResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListHardwareResponse'->new($_) } @$_ ] };

declare 'MapStringListHardwareResponse',
    as HashRef[ListHardwareResponse()];

declare 'GetHardwareRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::GetHardwareRequest'];

coerce 'GetHardwareRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::GetHardwareRequest'->new($_) };

declare 'RepeatedGetHardwareRequest',
    as ArrayRef[GetHardwareRequest()];

coerce 'RepeatedGetHardwareRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::GetHardwareRequest'->new($_) } @$_ ] };

declare 'MapStringGetHardwareRequest',
    as HashRef[GetHardwareRequest()];

declare 'CreateHardwareRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::CreateHardwareRequest'];

coerce 'CreateHardwareRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::CreateHardwareRequest'->new($_) };

declare 'RepeatedCreateHardwareRequest',
    as ArrayRef[CreateHardwareRequest()];

coerce 'RepeatedCreateHardwareRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::CreateHardwareRequest'->new($_) } @$_ ] };

declare 'MapStringCreateHardwareRequest',
    as HashRef[CreateHardwareRequest()];

declare 'UpdateHardwareRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::UpdateHardwareRequest'];

coerce 'UpdateHardwareRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::UpdateHardwareRequest'->new($_) };

declare 'RepeatedUpdateHardwareRequest',
    as ArrayRef[UpdateHardwareRequest()];

coerce 'RepeatedUpdateHardwareRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::UpdateHardwareRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateHardwareRequest',
    as HashRef[UpdateHardwareRequest()];

declare 'DeleteHardwareRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::DeleteHardwareRequest'];

coerce 'DeleteHardwareRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::DeleteHardwareRequest'->new($_) };

declare 'RepeatedDeleteHardwareRequest',
    as ArrayRef[DeleteHardwareRequest()];

coerce 'RepeatedDeleteHardwareRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::DeleteHardwareRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteHardwareRequest',
    as HashRef[DeleteHardwareRequest()];

declare 'ListCommentsRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListCommentsRequest'];

coerce 'ListCommentsRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListCommentsRequest'->new($_) };

declare 'RepeatedListCommentsRequest',
    as ArrayRef[ListCommentsRequest()];

coerce 'RepeatedListCommentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListCommentsRequest'->new($_) } @$_ ] };

declare 'MapStringListCommentsRequest',
    as HashRef[ListCommentsRequest()];

declare 'ListCommentsResponse',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListCommentsResponse'];

coerce 'ListCommentsResponse',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListCommentsResponse'->new($_) };

declare 'RepeatedListCommentsResponse',
    as ArrayRef[ListCommentsResponse()];

coerce 'RepeatedListCommentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListCommentsResponse'->new($_) } @$_ ] };

declare 'MapStringListCommentsResponse',
    as HashRef[ListCommentsResponse()];

declare 'GetCommentRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::GetCommentRequest'];

coerce 'GetCommentRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::GetCommentRequest'->new($_) };

declare 'RepeatedGetCommentRequest',
    as ArrayRef[GetCommentRequest()];

coerce 'RepeatedGetCommentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::GetCommentRequest'->new($_) } @$_ ] };

declare 'MapStringGetCommentRequest',
    as HashRef[GetCommentRequest()];

declare 'CreateCommentRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::CreateCommentRequest'];

coerce 'CreateCommentRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::CreateCommentRequest'->new($_) };

declare 'RepeatedCreateCommentRequest',
    as ArrayRef[CreateCommentRequest()];

coerce 'RepeatedCreateCommentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::CreateCommentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCommentRequest',
    as HashRef[CreateCommentRequest()];

declare 'RecordActionOnCommentRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::RecordActionOnCommentRequest'];

coerce 'RecordActionOnCommentRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::RecordActionOnCommentRequest'->new($_) };

declare 'RepeatedRecordActionOnCommentRequest',
    as ArrayRef[RecordActionOnCommentRequest()];

coerce 'RepeatedRecordActionOnCommentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::RecordActionOnCommentRequest'->new($_) } @$_ ] };

declare 'MapStringRecordActionOnCommentRequest',
    as HashRef[RecordActionOnCommentRequest()];

declare 'ActionType',
    as (Int | Str);

declare 'ListChangeLogEntriesRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListChangeLogEntriesRequest'];

coerce 'ListChangeLogEntriesRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListChangeLogEntriesRequest'->new($_) };

declare 'RepeatedListChangeLogEntriesRequest',
    as ArrayRef[ListChangeLogEntriesRequest()];

coerce 'RepeatedListChangeLogEntriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListChangeLogEntriesRequest'->new($_) } @$_ ] };

declare 'MapStringListChangeLogEntriesRequest',
    as HashRef[ListChangeLogEntriesRequest()];

declare 'ListChangeLogEntriesResponse',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListChangeLogEntriesResponse'];

coerce 'ListChangeLogEntriesResponse',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListChangeLogEntriesResponse'->new($_) };

declare 'RepeatedListChangeLogEntriesResponse',
    as ArrayRef[ListChangeLogEntriesResponse()];

coerce 'RepeatedListChangeLogEntriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListChangeLogEntriesResponse'->new($_) } @$_ ] };

declare 'MapStringListChangeLogEntriesResponse',
    as HashRef[ListChangeLogEntriesResponse()];

declare 'GetChangeLogEntryRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::GetChangeLogEntryRequest'];

coerce 'GetChangeLogEntryRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::GetChangeLogEntryRequest'->new($_) };

declare 'RepeatedGetChangeLogEntryRequest',
    as ArrayRef[GetChangeLogEntryRequest()];

coerce 'RepeatedGetChangeLogEntryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::GetChangeLogEntryRequest'->new($_) } @$_ ] };

declare 'MapStringGetChangeLogEntryRequest',
    as HashRef[GetChangeLogEntryRequest()];

declare 'ListSkusRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListSkusRequest'];

coerce 'ListSkusRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListSkusRequest'->new($_) };

declare 'RepeatedListSkusRequest',
    as ArrayRef[ListSkusRequest()];

coerce 'RepeatedListSkusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListSkusRequest'->new($_) } @$_ ] };

declare 'MapStringListSkusRequest',
    as HashRef[ListSkusRequest()];

declare 'ListSkusResponse',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListSkusResponse'];

coerce 'ListSkusResponse',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListSkusResponse'->new($_) };

declare 'RepeatedListSkusResponse',
    as ArrayRef[ListSkusResponse()];

coerce 'RepeatedListSkusResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListSkusResponse'->new($_) } @$_ ] };

declare 'MapStringListSkusResponse',
    as HashRef[ListSkusResponse()];

declare 'GetSkuRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::GetSkuRequest'];

coerce 'GetSkuRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::GetSkuRequest'->new($_) };

declare 'RepeatedGetSkuRequest',
    as ArrayRef[GetSkuRequest()];

coerce 'RepeatedGetSkuRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::GetSkuRequest'->new($_) } @$_ ] };

declare 'MapStringGetSkuRequest',
    as HashRef[GetSkuRequest()];

declare 'ListZonesRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListZonesRequest'];

coerce 'ListZonesRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListZonesRequest'->new($_) };

declare 'RepeatedListZonesRequest',
    as ArrayRef[ListZonesRequest()];

coerce 'RepeatedListZonesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListZonesRequest'->new($_) } @$_ ] };

declare 'MapStringListZonesRequest',
    as HashRef[ListZonesRequest()];

declare 'ListZonesResponse',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListZonesResponse'];

coerce 'ListZonesResponse',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListZonesResponse'->new($_) };

declare 'RepeatedListZonesResponse',
    as ArrayRef[ListZonesResponse()];

coerce 'RepeatedListZonesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::ListZonesResponse'->new($_) } @$_ ] };

declare 'MapStringListZonesResponse',
    as HashRef[ListZonesResponse()];

declare 'GetZoneRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::GetZoneRequest'];

coerce 'GetZoneRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::GetZoneRequest'->new($_) };

declare 'RepeatedGetZoneRequest',
    as ArrayRef[GetZoneRequest()];

coerce 'RepeatedGetZoneRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::GetZoneRequest'->new($_) } @$_ ] };

declare 'MapStringGetZoneRequest',
    as HashRef[GetZoneRequest()];

declare 'CreateZoneRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::CreateZoneRequest'];

coerce 'CreateZoneRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::CreateZoneRequest'->new($_) };

declare 'RepeatedCreateZoneRequest',
    as ArrayRef[CreateZoneRequest()];

coerce 'RepeatedCreateZoneRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::CreateZoneRequest'->new($_) } @$_ ] };

declare 'MapStringCreateZoneRequest',
    as HashRef[CreateZoneRequest()];

declare 'UpdateZoneRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::UpdateZoneRequest'];

coerce 'UpdateZoneRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::UpdateZoneRequest'->new($_) };

declare 'RepeatedUpdateZoneRequest',
    as ArrayRef[UpdateZoneRequest()];

coerce 'RepeatedUpdateZoneRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::UpdateZoneRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateZoneRequest',
    as HashRef[UpdateZoneRequest()];

declare 'DeleteZoneRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::DeleteZoneRequest'];

coerce 'DeleteZoneRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::DeleteZoneRequest'->new($_) };

declare 'RepeatedDeleteZoneRequest',
    as ArrayRef[DeleteZoneRequest()];

coerce 'RepeatedDeleteZoneRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::DeleteZoneRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteZoneRequest',
    as HashRef[DeleteZoneRequest()];

declare 'SignalZoneStateRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::SignalZoneStateRequest'];

coerce 'SignalZoneStateRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::SignalZoneStateRequest'->new($_) };

declare 'RepeatedSignalZoneStateRequest',
    as ArrayRef[SignalZoneStateRequest()];

coerce 'RepeatedSignalZoneStateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::SignalZoneStateRequest'->new($_) } @$_ ] };

declare 'MapStringSignalZoneStateRequest',
    as HashRef[SignalZoneStateRequest()];

declare 'StateSignal',
    as (Int | Str);

declare 'ProvisioningStateSignal',
    as (Int | Str);

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'RequestOrderDateChangeRequest',
    as InstanceOf['Google::Cloud::Gdchardwaremanagement::V1alpha::Service::RequestOrderDateChangeRequest'];

coerce 'RequestOrderDateChangeRequest',
    from HashRef, via { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::RequestOrderDateChangeRequest'->new($_) };

declare 'RepeatedRequestOrderDateChangeRequest',
    as ArrayRef[RequestOrderDateChangeRequest()];

coerce 'RepeatedRequestOrderDateChangeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gdchardwaremanagement::V1alpha::Service::RequestOrderDateChangeRequest'->new($_) } @$_ ] };

declare 'MapStringRequestOrderDateChangeRequest',
    as HashRef[RequestOrderDateChangeRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Gdchardwaremanagement::V1alpha::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
