package Google::Cloud::Edgenetwork::V1::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListZonesRequest',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::ListZonesRequest'];

coerce 'ListZonesRequest',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::ListZonesRequest'->new($_) };

declare 'RepeatedListZonesRequest',
    as ArrayRef[ListZonesRequest()];

coerce 'RepeatedListZonesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::ListZonesRequest'->new($_) } @$_ ] };

declare 'MapStringListZonesRequest',
    as HashRef[ListZonesRequest()];

declare 'ListZonesResponse',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::ListZonesResponse'];

coerce 'ListZonesResponse',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::ListZonesResponse'->new($_) };

declare 'RepeatedListZonesResponse',
    as ArrayRef[ListZonesResponse()];

coerce 'RepeatedListZonesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::ListZonesResponse'->new($_) } @$_ ] };

declare 'MapStringListZonesResponse',
    as HashRef[ListZonesResponse()];

declare 'GetZoneRequest',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::GetZoneRequest'];

coerce 'GetZoneRequest',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::GetZoneRequest'->new($_) };

declare 'RepeatedGetZoneRequest',
    as ArrayRef[GetZoneRequest()];

coerce 'RepeatedGetZoneRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::GetZoneRequest'->new($_) } @$_ ] };

declare 'MapStringGetZoneRequest',
    as HashRef[GetZoneRequest()];

declare 'ListNetworksRequest',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::ListNetworksRequest'];

coerce 'ListNetworksRequest',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::ListNetworksRequest'->new($_) };

declare 'RepeatedListNetworksRequest',
    as ArrayRef[ListNetworksRequest()];

coerce 'RepeatedListNetworksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::ListNetworksRequest'->new($_) } @$_ ] };

declare 'MapStringListNetworksRequest',
    as HashRef[ListNetworksRequest()];

declare 'ListNetworksResponse',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::ListNetworksResponse'];

coerce 'ListNetworksResponse',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::ListNetworksResponse'->new($_) };

declare 'RepeatedListNetworksResponse',
    as ArrayRef[ListNetworksResponse()];

coerce 'RepeatedListNetworksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::ListNetworksResponse'->new($_) } @$_ ] };

declare 'MapStringListNetworksResponse',
    as HashRef[ListNetworksResponse()];

declare 'GetNetworkRequest',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::GetNetworkRequest'];

coerce 'GetNetworkRequest',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::GetNetworkRequest'->new($_) };

declare 'RepeatedGetNetworkRequest',
    as ArrayRef[GetNetworkRequest()];

coerce 'RepeatedGetNetworkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::GetNetworkRequest'->new($_) } @$_ ] };

declare 'MapStringGetNetworkRequest',
    as HashRef[GetNetworkRequest()];

declare 'CreateNetworkRequest',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::CreateNetworkRequest'];

coerce 'CreateNetworkRequest',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::CreateNetworkRequest'->new($_) };

declare 'RepeatedCreateNetworkRequest',
    as ArrayRef[CreateNetworkRequest()];

coerce 'RepeatedCreateNetworkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::CreateNetworkRequest'->new($_) } @$_ ] };

declare 'MapStringCreateNetworkRequest',
    as HashRef[CreateNetworkRequest()];

declare 'DeleteNetworkRequest',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::DeleteNetworkRequest'];

coerce 'DeleteNetworkRequest',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::DeleteNetworkRequest'->new($_) };

declare 'RepeatedDeleteNetworkRequest',
    as ArrayRef[DeleteNetworkRequest()];

coerce 'RepeatedDeleteNetworkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::DeleteNetworkRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteNetworkRequest',
    as HashRef[DeleteNetworkRequest()];

declare 'ListSubnetsRequest',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::ListSubnetsRequest'];

coerce 'ListSubnetsRequest',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::ListSubnetsRequest'->new($_) };

declare 'RepeatedListSubnetsRequest',
    as ArrayRef[ListSubnetsRequest()];

coerce 'RepeatedListSubnetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::ListSubnetsRequest'->new($_) } @$_ ] };

declare 'MapStringListSubnetsRequest',
    as HashRef[ListSubnetsRequest()];

declare 'ListSubnetsResponse',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::ListSubnetsResponse'];

coerce 'ListSubnetsResponse',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::ListSubnetsResponse'->new($_) };

declare 'RepeatedListSubnetsResponse',
    as ArrayRef[ListSubnetsResponse()];

coerce 'RepeatedListSubnetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::ListSubnetsResponse'->new($_) } @$_ ] };

declare 'MapStringListSubnetsResponse',
    as HashRef[ListSubnetsResponse()];

declare 'GetSubnetRequest',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::GetSubnetRequest'];

coerce 'GetSubnetRequest',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::GetSubnetRequest'->new($_) };

declare 'RepeatedGetSubnetRequest',
    as ArrayRef[GetSubnetRequest()];

coerce 'RepeatedGetSubnetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::GetSubnetRequest'->new($_) } @$_ ] };

declare 'MapStringGetSubnetRequest',
    as HashRef[GetSubnetRequest()];

declare 'CreateSubnetRequest',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::CreateSubnetRequest'];

coerce 'CreateSubnetRequest',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::CreateSubnetRequest'->new($_) };

declare 'RepeatedCreateSubnetRequest',
    as ArrayRef[CreateSubnetRequest()];

coerce 'RepeatedCreateSubnetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::CreateSubnetRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSubnetRequest',
    as HashRef[CreateSubnetRequest()];

declare 'UpdateSubnetRequest',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::UpdateSubnetRequest'];

coerce 'UpdateSubnetRequest',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::UpdateSubnetRequest'->new($_) };

declare 'RepeatedUpdateSubnetRequest',
    as ArrayRef[UpdateSubnetRequest()];

coerce 'RepeatedUpdateSubnetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::UpdateSubnetRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSubnetRequest',
    as HashRef[UpdateSubnetRequest()];

declare 'DeleteSubnetRequest',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::DeleteSubnetRequest'];

coerce 'DeleteSubnetRequest',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::DeleteSubnetRequest'->new($_) };

declare 'RepeatedDeleteSubnetRequest',
    as ArrayRef[DeleteSubnetRequest()];

coerce 'RepeatedDeleteSubnetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::DeleteSubnetRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSubnetRequest',
    as HashRef[DeleteSubnetRequest()];

declare 'ListInterconnectsRequest',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::ListInterconnectsRequest'];

coerce 'ListInterconnectsRequest',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::ListInterconnectsRequest'->new($_) };

declare 'RepeatedListInterconnectsRequest',
    as ArrayRef[ListInterconnectsRequest()];

coerce 'RepeatedListInterconnectsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::ListInterconnectsRequest'->new($_) } @$_ ] };

declare 'MapStringListInterconnectsRequest',
    as HashRef[ListInterconnectsRequest()];

declare 'ListInterconnectsResponse',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::ListInterconnectsResponse'];

coerce 'ListInterconnectsResponse',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::ListInterconnectsResponse'->new($_) };

declare 'RepeatedListInterconnectsResponse',
    as ArrayRef[ListInterconnectsResponse()];

coerce 'RepeatedListInterconnectsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::ListInterconnectsResponse'->new($_) } @$_ ] };

declare 'MapStringListInterconnectsResponse',
    as HashRef[ListInterconnectsResponse()];

declare 'GetInterconnectRequest',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::GetInterconnectRequest'];

coerce 'GetInterconnectRequest',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::GetInterconnectRequest'->new($_) };

declare 'RepeatedGetInterconnectRequest',
    as ArrayRef[GetInterconnectRequest()];

coerce 'RepeatedGetInterconnectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::GetInterconnectRequest'->new($_) } @$_ ] };

declare 'MapStringGetInterconnectRequest',
    as HashRef[GetInterconnectRequest()];

declare 'ListInterconnectAttachmentsRequest',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::ListInterconnectAttachmentsRequest'];

coerce 'ListInterconnectAttachmentsRequest',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::ListInterconnectAttachmentsRequest'->new($_) };

declare 'RepeatedListInterconnectAttachmentsRequest',
    as ArrayRef[ListInterconnectAttachmentsRequest()];

coerce 'RepeatedListInterconnectAttachmentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::ListInterconnectAttachmentsRequest'->new($_) } @$_ ] };

declare 'MapStringListInterconnectAttachmentsRequest',
    as HashRef[ListInterconnectAttachmentsRequest()];

declare 'ListInterconnectAttachmentsResponse',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::ListInterconnectAttachmentsResponse'];

coerce 'ListInterconnectAttachmentsResponse',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::ListInterconnectAttachmentsResponse'->new($_) };

declare 'RepeatedListInterconnectAttachmentsResponse',
    as ArrayRef[ListInterconnectAttachmentsResponse()];

coerce 'RepeatedListInterconnectAttachmentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::ListInterconnectAttachmentsResponse'->new($_) } @$_ ] };

declare 'MapStringListInterconnectAttachmentsResponse',
    as HashRef[ListInterconnectAttachmentsResponse()];

declare 'GetInterconnectAttachmentRequest',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::GetInterconnectAttachmentRequest'];

coerce 'GetInterconnectAttachmentRequest',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::GetInterconnectAttachmentRequest'->new($_) };

declare 'RepeatedGetInterconnectAttachmentRequest',
    as ArrayRef[GetInterconnectAttachmentRequest()];

coerce 'RepeatedGetInterconnectAttachmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::GetInterconnectAttachmentRequest'->new($_) } @$_ ] };

declare 'MapStringGetInterconnectAttachmentRequest',
    as HashRef[GetInterconnectAttachmentRequest()];

declare 'CreateInterconnectAttachmentRequest',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::CreateInterconnectAttachmentRequest'];

coerce 'CreateInterconnectAttachmentRequest',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::CreateInterconnectAttachmentRequest'->new($_) };

declare 'RepeatedCreateInterconnectAttachmentRequest',
    as ArrayRef[CreateInterconnectAttachmentRequest()];

coerce 'RepeatedCreateInterconnectAttachmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::CreateInterconnectAttachmentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateInterconnectAttachmentRequest',
    as HashRef[CreateInterconnectAttachmentRequest()];

declare 'DeleteInterconnectAttachmentRequest',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::DeleteInterconnectAttachmentRequest'];

coerce 'DeleteInterconnectAttachmentRequest',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::DeleteInterconnectAttachmentRequest'->new($_) };

declare 'RepeatedDeleteInterconnectAttachmentRequest',
    as ArrayRef[DeleteInterconnectAttachmentRequest()];

coerce 'RepeatedDeleteInterconnectAttachmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::DeleteInterconnectAttachmentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteInterconnectAttachmentRequest',
    as HashRef[DeleteInterconnectAttachmentRequest()];

declare 'ListRoutersRequest',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::ListRoutersRequest'];

coerce 'ListRoutersRequest',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::ListRoutersRequest'->new($_) };

declare 'RepeatedListRoutersRequest',
    as ArrayRef[ListRoutersRequest()];

coerce 'RepeatedListRoutersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::ListRoutersRequest'->new($_) } @$_ ] };

declare 'MapStringListRoutersRequest',
    as HashRef[ListRoutersRequest()];

declare 'ListRoutersResponse',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::ListRoutersResponse'];

coerce 'ListRoutersResponse',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::ListRoutersResponse'->new($_) };

declare 'RepeatedListRoutersResponse',
    as ArrayRef[ListRoutersResponse()];

coerce 'RepeatedListRoutersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::ListRoutersResponse'->new($_) } @$_ ] };

declare 'MapStringListRoutersResponse',
    as HashRef[ListRoutersResponse()];

declare 'GetRouterRequest',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::GetRouterRequest'];

coerce 'GetRouterRequest',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::GetRouterRequest'->new($_) };

declare 'RepeatedGetRouterRequest',
    as ArrayRef[GetRouterRequest()];

coerce 'RepeatedGetRouterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::GetRouterRequest'->new($_) } @$_ ] };

declare 'MapStringGetRouterRequest',
    as HashRef[GetRouterRequest()];

declare 'CreateRouterRequest',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::CreateRouterRequest'];

coerce 'CreateRouterRequest',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::CreateRouterRequest'->new($_) };

declare 'RepeatedCreateRouterRequest',
    as ArrayRef[CreateRouterRequest()];

coerce 'RepeatedCreateRouterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::CreateRouterRequest'->new($_) } @$_ ] };

declare 'MapStringCreateRouterRequest',
    as HashRef[CreateRouterRequest()];

declare 'UpdateRouterRequest',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::UpdateRouterRequest'];

coerce 'UpdateRouterRequest',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::UpdateRouterRequest'->new($_) };

declare 'RepeatedUpdateRouterRequest',
    as ArrayRef[UpdateRouterRequest()];

coerce 'RepeatedUpdateRouterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::UpdateRouterRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateRouterRequest',
    as HashRef[UpdateRouterRequest()];

declare 'DeleteRouterRequest',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::DeleteRouterRequest'];

coerce 'DeleteRouterRequest',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::DeleteRouterRequest'->new($_) };

declare 'RepeatedDeleteRouterRequest',
    as ArrayRef[DeleteRouterRequest()];

coerce 'RepeatedDeleteRouterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::DeleteRouterRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteRouterRequest',
    as HashRef[DeleteRouterRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'DiagnoseNetworkRequest',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::DiagnoseNetworkRequest'];

coerce 'DiagnoseNetworkRequest',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::DiagnoseNetworkRequest'->new($_) };

declare 'RepeatedDiagnoseNetworkRequest',
    as ArrayRef[DiagnoseNetworkRequest()];

coerce 'RepeatedDiagnoseNetworkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::DiagnoseNetworkRequest'->new($_) } @$_ ] };

declare 'MapStringDiagnoseNetworkRequest',
    as HashRef[DiagnoseNetworkRequest()];

declare 'DiagnoseNetworkResponse',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::DiagnoseNetworkResponse'];

coerce 'DiagnoseNetworkResponse',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::DiagnoseNetworkResponse'->new($_) };

declare 'RepeatedDiagnoseNetworkResponse',
    as ArrayRef[DiagnoseNetworkResponse()];

coerce 'RepeatedDiagnoseNetworkResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::DiagnoseNetworkResponse'->new($_) } @$_ ] };

declare 'MapStringDiagnoseNetworkResponse',
    as HashRef[DiagnoseNetworkResponse()];

declare 'NetworkStatus',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::DiagnoseNetworkResponse::NetworkStatus'];

coerce 'NetworkStatus',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::DiagnoseNetworkResponse::NetworkStatus'->new($_) };

declare 'RepeatedNetworkStatus',
    as ArrayRef[NetworkStatus()];

coerce 'RepeatedNetworkStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::DiagnoseNetworkResponse::NetworkStatus'->new($_) } @$_ ] };

declare 'MapStringNetworkStatus',
    as HashRef[NetworkStatus()];

declare 'MacsecStatus',
    as (Int | Str);

declare 'DiagnoseInterconnectRequest',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::DiagnoseInterconnectRequest'];

coerce 'DiagnoseInterconnectRequest',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::DiagnoseInterconnectRequest'->new($_) };

declare 'RepeatedDiagnoseInterconnectRequest',
    as ArrayRef[DiagnoseInterconnectRequest()];

coerce 'RepeatedDiagnoseInterconnectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::DiagnoseInterconnectRequest'->new($_) } @$_ ] };

declare 'MapStringDiagnoseInterconnectRequest',
    as HashRef[DiagnoseInterconnectRequest()];

declare 'DiagnoseInterconnectResponse',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::DiagnoseInterconnectResponse'];

coerce 'DiagnoseInterconnectResponse',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::DiagnoseInterconnectResponse'->new($_) };

declare 'RepeatedDiagnoseInterconnectResponse',
    as ArrayRef[DiagnoseInterconnectResponse()];

coerce 'RepeatedDiagnoseInterconnectResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::DiagnoseInterconnectResponse'->new($_) } @$_ ] };

declare 'MapStringDiagnoseInterconnectResponse',
    as HashRef[DiagnoseInterconnectResponse()];

declare 'DiagnoseRouterRequest',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::DiagnoseRouterRequest'];

coerce 'DiagnoseRouterRequest',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::DiagnoseRouterRequest'->new($_) };

declare 'RepeatedDiagnoseRouterRequest',
    as ArrayRef[DiagnoseRouterRequest()];

coerce 'RepeatedDiagnoseRouterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::DiagnoseRouterRequest'->new($_) } @$_ ] };

declare 'MapStringDiagnoseRouterRequest',
    as HashRef[DiagnoseRouterRequest()];

declare 'DiagnoseRouterResponse',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::DiagnoseRouterResponse'];

coerce 'DiagnoseRouterResponse',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::DiagnoseRouterResponse'->new($_) };

declare 'RepeatedDiagnoseRouterResponse',
    as ArrayRef[DiagnoseRouterResponse()];

coerce 'RepeatedDiagnoseRouterResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::DiagnoseRouterResponse'->new($_) } @$_ ] };

declare 'MapStringDiagnoseRouterResponse',
    as HashRef[DiagnoseRouterResponse()];

declare 'InitializeZoneRequest',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::InitializeZoneRequest'];

coerce 'InitializeZoneRequest',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::InitializeZoneRequest'->new($_) };

declare 'RepeatedInitializeZoneRequest',
    as ArrayRef[InitializeZoneRequest()];

coerce 'RepeatedInitializeZoneRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::InitializeZoneRequest'->new($_) } @$_ ] };

declare 'MapStringInitializeZoneRequest',
    as HashRef[InitializeZoneRequest()];

declare 'InitializeZoneResponse',
    as InstanceOf['Google::Cloud::Edgenetwork::V1::Service::InitializeZoneResponse'];

coerce 'InitializeZoneResponse',
    from HashRef, via { 'Google::Cloud::Edgenetwork::V1::Service::InitializeZoneResponse'->new($_) };

declare 'RepeatedInitializeZoneResponse',
    as ArrayRef[InitializeZoneResponse()];

coerce 'RepeatedInitializeZoneResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgenetwork::V1::Service::InitializeZoneResponse'->new($_) } @$_ ] };

declare 'MapStringInitializeZoneResponse',
    as HashRef[InitializeZoneResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Edgenetwork::V1::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
