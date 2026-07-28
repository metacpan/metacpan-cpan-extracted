package Google::Cloud::Networkservices::V1::RouteView::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GatewayRouteView',
    as InstanceOf['Google::Cloud::Networkservices::V1::RouteView::GatewayRouteView'];

coerce 'GatewayRouteView',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::RouteView::GatewayRouteView'->new($_) };

declare 'RepeatedGatewayRouteView',
    as ArrayRef[GatewayRouteView()];

coerce 'RepeatedGatewayRouteView',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::RouteView::GatewayRouteView'->new($_) } @$_ ] };

declare 'MapStringGatewayRouteView',
    as HashRef[GatewayRouteView()];

declare 'MeshRouteView',
    as InstanceOf['Google::Cloud::Networkservices::V1::RouteView::MeshRouteView'];

coerce 'MeshRouteView',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::RouteView::MeshRouteView'->new($_) };

declare 'RepeatedMeshRouteView',
    as ArrayRef[MeshRouteView()];

coerce 'RepeatedMeshRouteView',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::RouteView::MeshRouteView'->new($_) } @$_ ] };

declare 'MapStringMeshRouteView',
    as HashRef[MeshRouteView()];

declare 'GetGatewayRouteViewRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::RouteView::GetGatewayRouteViewRequest'];

coerce 'GetGatewayRouteViewRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::RouteView::GetGatewayRouteViewRequest'->new($_) };

declare 'RepeatedGetGatewayRouteViewRequest',
    as ArrayRef[GetGatewayRouteViewRequest()];

coerce 'RepeatedGetGatewayRouteViewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::RouteView::GetGatewayRouteViewRequest'->new($_) } @$_ ] };

declare 'MapStringGetGatewayRouteViewRequest',
    as HashRef[GetGatewayRouteViewRequest()];

declare 'GetMeshRouteViewRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::RouteView::GetMeshRouteViewRequest'];

coerce 'GetMeshRouteViewRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::RouteView::GetMeshRouteViewRequest'->new($_) };

declare 'RepeatedGetMeshRouteViewRequest',
    as ArrayRef[GetMeshRouteViewRequest()];

coerce 'RepeatedGetMeshRouteViewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::RouteView::GetMeshRouteViewRequest'->new($_) } @$_ ] };

declare 'MapStringGetMeshRouteViewRequest',
    as HashRef[GetMeshRouteViewRequest()];

declare 'ListGatewayRouteViewsRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::RouteView::ListGatewayRouteViewsRequest'];

coerce 'ListGatewayRouteViewsRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::RouteView::ListGatewayRouteViewsRequest'->new($_) };

declare 'RepeatedListGatewayRouteViewsRequest',
    as ArrayRef[ListGatewayRouteViewsRequest()];

coerce 'RepeatedListGatewayRouteViewsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::RouteView::ListGatewayRouteViewsRequest'->new($_) } @$_ ] };

declare 'MapStringListGatewayRouteViewsRequest',
    as HashRef[ListGatewayRouteViewsRequest()];

declare 'ListMeshRouteViewsRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::RouteView::ListMeshRouteViewsRequest'];

coerce 'ListMeshRouteViewsRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::RouteView::ListMeshRouteViewsRequest'->new($_) };

declare 'RepeatedListMeshRouteViewsRequest',
    as ArrayRef[ListMeshRouteViewsRequest()];

coerce 'RepeatedListMeshRouteViewsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::RouteView::ListMeshRouteViewsRequest'->new($_) } @$_ ] };

declare 'MapStringListMeshRouteViewsRequest',
    as HashRef[ListMeshRouteViewsRequest()];

declare 'ListGatewayRouteViewsResponse',
    as InstanceOf['Google::Cloud::Networkservices::V1::RouteView::ListGatewayRouteViewsResponse'];

coerce 'ListGatewayRouteViewsResponse',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::RouteView::ListGatewayRouteViewsResponse'->new($_) };

declare 'RepeatedListGatewayRouteViewsResponse',
    as ArrayRef[ListGatewayRouteViewsResponse()];

coerce 'RepeatedListGatewayRouteViewsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::RouteView::ListGatewayRouteViewsResponse'->new($_) } @$_ ] };

declare 'MapStringListGatewayRouteViewsResponse',
    as HashRef[ListGatewayRouteViewsResponse()];

declare 'ListMeshRouteViewsResponse',
    as InstanceOf['Google::Cloud::Networkservices::V1::RouteView::ListMeshRouteViewsResponse'];

coerce 'ListMeshRouteViewsResponse',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::RouteView::ListMeshRouteViewsResponse'->new($_) };

declare 'RepeatedListMeshRouteViewsResponse',
    as ArrayRef[ListMeshRouteViewsResponse()];

coerce 'RepeatedListMeshRouteViewsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::RouteView::ListMeshRouteViewsResponse'->new($_) } @$_ ] };

declare 'MapStringListMeshRouteViewsResponse',
    as HashRef[ListMeshRouteViewsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Networkservices::V1::RouteView::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
