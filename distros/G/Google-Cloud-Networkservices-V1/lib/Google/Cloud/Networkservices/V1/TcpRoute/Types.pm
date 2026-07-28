package Google::Cloud::Networkservices::V1::TcpRoute::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TcpRoute',
    as InstanceOf['Google::Cloud::Networkservices::V1::TcpRoute::TcpRoute'];

coerce 'TcpRoute',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::TcpRoute::TcpRoute'->new($_) };

declare 'RepeatedTcpRoute',
    as ArrayRef[TcpRoute()];

coerce 'RepeatedTcpRoute',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::TcpRoute::TcpRoute'->new($_) } @$_ ] };

declare 'MapStringTcpRoute',
    as HashRef[TcpRoute()];

declare 'RouteRule',
    as InstanceOf['Google::Cloud::Networkservices::V1::TcpRoute::TcpRoute::RouteRule'];

coerce 'RouteRule',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::TcpRoute::TcpRoute::RouteRule'->new($_) };

declare 'RepeatedRouteRule',
    as ArrayRef[RouteRule()];

coerce 'RepeatedRouteRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::TcpRoute::TcpRoute::RouteRule'->new($_) } @$_ ] };

declare 'MapStringRouteRule',
    as HashRef[RouteRule()];

declare 'RouteMatch',
    as InstanceOf['Google::Cloud::Networkservices::V1::TcpRoute::TcpRoute::RouteMatch'];

coerce 'RouteMatch',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::TcpRoute::TcpRoute::RouteMatch'->new($_) };

declare 'RepeatedRouteMatch',
    as ArrayRef[RouteMatch()];

coerce 'RepeatedRouteMatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::TcpRoute::TcpRoute::RouteMatch'->new($_) } @$_ ] };

declare 'MapStringRouteMatch',
    as HashRef[RouteMatch()];

declare 'RouteAction',
    as InstanceOf['Google::Cloud::Networkservices::V1::TcpRoute::TcpRoute::RouteAction'];

coerce 'RouteAction',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::TcpRoute::TcpRoute::RouteAction'->new($_) };

declare 'RepeatedRouteAction',
    as ArrayRef[RouteAction()];

coerce 'RepeatedRouteAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::TcpRoute::TcpRoute::RouteAction'->new($_) } @$_ ] };

declare 'MapStringRouteAction',
    as HashRef[RouteAction()];

declare 'RouteDestination',
    as InstanceOf['Google::Cloud::Networkservices::V1::TcpRoute::TcpRoute::RouteDestination'];

coerce 'RouteDestination',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::TcpRoute::TcpRoute::RouteDestination'->new($_) };

declare 'RepeatedRouteDestination',
    as ArrayRef[RouteDestination()];

coerce 'RepeatedRouteDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::TcpRoute::TcpRoute::RouteDestination'->new($_) } @$_ ] };

declare 'MapStringRouteDestination',
    as HashRef[RouteDestination()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkservices::V1::TcpRoute::TcpRoute::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::TcpRoute::TcpRoute::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::TcpRoute::TcpRoute::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListTcpRoutesRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::TcpRoute::ListTcpRoutesRequest'];

coerce 'ListTcpRoutesRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::TcpRoute::ListTcpRoutesRequest'->new($_) };

declare 'RepeatedListTcpRoutesRequest',
    as ArrayRef[ListTcpRoutesRequest()];

coerce 'RepeatedListTcpRoutesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::TcpRoute::ListTcpRoutesRequest'->new($_) } @$_ ] };

declare 'MapStringListTcpRoutesRequest',
    as HashRef[ListTcpRoutesRequest()];

declare 'ListTcpRoutesResponse',
    as InstanceOf['Google::Cloud::Networkservices::V1::TcpRoute::ListTcpRoutesResponse'];

coerce 'ListTcpRoutesResponse',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::TcpRoute::ListTcpRoutesResponse'->new($_) };

declare 'RepeatedListTcpRoutesResponse',
    as ArrayRef[ListTcpRoutesResponse()];

coerce 'RepeatedListTcpRoutesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::TcpRoute::ListTcpRoutesResponse'->new($_) } @$_ ] };

declare 'MapStringListTcpRoutesResponse',
    as HashRef[ListTcpRoutesResponse()];

declare 'GetTcpRouteRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::TcpRoute::GetTcpRouteRequest'];

coerce 'GetTcpRouteRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::TcpRoute::GetTcpRouteRequest'->new($_) };

declare 'RepeatedGetTcpRouteRequest',
    as ArrayRef[GetTcpRouteRequest()];

coerce 'RepeatedGetTcpRouteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::TcpRoute::GetTcpRouteRequest'->new($_) } @$_ ] };

declare 'MapStringGetTcpRouteRequest',
    as HashRef[GetTcpRouteRequest()];

declare 'CreateTcpRouteRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::TcpRoute::CreateTcpRouteRequest'];

coerce 'CreateTcpRouteRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::TcpRoute::CreateTcpRouteRequest'->new($_) };

declare 'RepeatedCreateTcpRouteRequest',
    as ArrayRef[CreateTcpRouteRequest()];

coerce 'RepeatedCreateTcpRouteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::TcpRoute::CreateTcpRouteRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTcpRouteRequest',
    as HashRef[CreateTcpRouteRequest()];

declare 'UpdateTcpRouteRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::TcpRoute::UpdateTcpRouteRequest'];

coerce 'UpdateTcpRouteRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::TcpRoute::UpdateTcpRouteRequest'->new($_) };

declare 'RepeatedUpdateTcpRouteRequest',
    as ArrayRef[UpdateTcpRouteRequest()];

coerce 'RepeatedUpdateTcpRouteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::TcpRoute::UpdateTcpRouteRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTcpRouteRequest',
    as HashRef[UpdateTcpRouteRequest()];

declare 'DeleteTcpRouteRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::TcpRoute::DeleteTcpRouteRequest'];

coerce 'DeleteTcpRouteRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::TcpRoute::DeleteTcpRouteRequest'->new($_) };

declare 'RepeatedDeleteTcpRouteRequest',
    as ArrayRef[DeleteTcpRouteRequest()];

coerce 'RepeatedDeleteTcpRouteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::TcpRoute::DeleteTcpRouteRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTcpRouteRequest',
    as HashRef[DeleteTcpRouteRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Networkservices::V1::TcpRoute::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
