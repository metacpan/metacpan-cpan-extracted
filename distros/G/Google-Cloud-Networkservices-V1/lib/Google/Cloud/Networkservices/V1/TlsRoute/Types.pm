package Google::Cloud::Networkservices::V1::TlsRoute::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TlsRoute',
    as InstanceOf['Google::Cloud::Networkservices::V1::TlsRoute::TlsRoute'];

coerce 'TlsRoute',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::TlsRoute::TlsRoute'->new($_) };

declare 'RepeatedTlsRoute',
    as ArrayRef[TlsRoute()];

coerce 'RepeatedTlsRoute',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::TlsRoute::TlsRoute'->new($_) } @$_ ] };

declare 'MapStringTlsRoute',
    as HashRef[TlsRoute()];

declare 'RouteRule',
    as InstanceOf['Google::Cloud::Networkservices::V1::TlsRoute::TlsRoute::RouteRule'];

coerce 'RouteRule',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::TlsRoute::TlsRoute::RouteRule'->new($_) };

declare 'RepeatedRouteRule',
    as ArrayRef[RouteRule()];

coerce 'RepeatedRouteRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::TlsRoute::TlsRoute::RouteRule'->new($_) } @$_ ] };

declare 'MapStringRouteRule',
    as HashRef[RouteRule()];

declare 'RouteMatch',
    as InstanceOf['Google::Cloud::Networkservices::V1::TlsRoute::TlsRoute::RouteMatch'];

coerce 'RouteMatch',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::TlsRoute::TlsRoute::RouteMatch'->new($_) };

declare 'RepeatedRouteMatch',
    as ArrayRef[RouteMatch()];

coerce 'RepeatedRouteMatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::TlsRoute::TlsRoute::RouteMatch'->new($_) } @$_ ] };

declare 'MapStringRouteMatch',
    as HashRef[RouteMatch()];

declare 'RouteAction',
    as InstanceOf['Google::Cloud::Networkservices::V1::TlsRoute::TlsRoute::RouteAction'];

coerce 'RouteAction',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::TlsRoute::TlsRoute::RouteAction'->new($_) };

declare 'RepeatedRouteAction',
    as ArrayRef[RouteAction()];

coerce 'RepeatedRouteAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::TlsRoute::TlsRoute::RouteAction'->new($_) } @$_ ] };

declare 'MapStringRouteAction',
    as HashRef[RouteAction()];

declare 'RouteDestination',
    as InstanceOf['Google::Cloud::Networkservices::V1::TlsRoute::TlsRoute::RouteDestination'];

coerce 'RouteDestination',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::TlsRoute::TlsRoute::RouteDestination'->new($_) };

declare 'RepeatedRouteDestination',
    as ArrayRef[RouteDestination()];

coerce 'RepeatedRouteDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::TlsRoute::TlsRoute::RouteDestination'->new($_) } @$_ ] };

declare 'MapStringRouteDestination',
    as HashRef[RouteDestination()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkservices::V1::TlsRoute::TlsRoute::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::TlsRoute::TlsRoute::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::TlsRoute::TlsRoute::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListTlsRoutesRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::TlsRoute::ListTlsRoutesRequest'];

coerce 'ListTlsRoutesRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::TlsRoute::ListTlsRoutesRequest'->new($_) };

declare 'RepeatedListTlsRoutesRequest',
    as ArrayRef[ListTlsRoutesRequest()];

coerce 'RepeatedListTlsRoutesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::TlsRoute::ListTlsRoutesRequest'->new($_) } @$_ ] };

declare 'MapStringListTlsRoutesRequest',
    as HashRef[ListTlsRoutesRequest()];

declare 'ListTlsRoutesResponse',
    as InstanceOf['Google::Cloud::Networkservices::V1::TlsRoute::ListTlsRoutesResponse'];

coerce 'ListTlsRoutesResponse',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::TlsRoute::ListTlsRoutesResponse'->new($_) };

declare 'RepeatedListTlsRoutesResponse',
    as ArrayRef[ListTlsRoutesResponse()];

coerce 'RepeatedListTlsRoutesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::TlsRoute::ListTlsRoutesResponse'->new($_) } @$_ ] };

declare 'MapStringListTlsRoutesResponse',
    as HashRef[ListTlsRoutesResponse()];

declare 'GetTlsRouteRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::TlsRoute::GetTlsRouteRequest'];

coerce 'GetTlsRouteRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::TlsRoute::GetTlsRouteRequest'->new($_) };

declare 'RepeatedGetTlsRouteRequest',
    as ArrayRef[GetTlsRouteRequest()];

coerce 'RepeatedGetTlsRouteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::TlsRoute::GetTlsRouteRequest'->new($_) } @$_ ] };

declare 'MapStringGetTlsRouteRequest',
    as HashRef[GetTlsRouteRequest()];

declare 'CreateTlsRouteRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::TlsRoute::CreateTlsRouteRequest'];

coerce 'CreateTlsRouteRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::TlsRoute::CreateTlsRouteRequest'->new($_) };

declare 'RepeatedCreateTlsRouteRequest',
    as ArrayRef[CreateTlsRouteRequest()];

coerce 'RepeatedCreateTlsRouteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::TlsRoute::CreateTlsRouteRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTlsRouteRequest',
    as HashRef[CreateTlsRouteRequest()];

declare 'UpdateTlsRouteRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::TlsRoute::UpdateTlsRouteRequest'];

coerce 'UpdateTlsRouteRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::TlsRoute::UpdateTlsRouteRequest'->new($_) };

declare 'RepeatedUpdateTlsRouteRequest',
    as ArrayRef[UpdateTlsRouteRequest()];

coerce 'RepeatedUpdateTlsRouteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::TlsRoute::UpdateTlsRouteRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTlsRouteRequest',
    as HashRef[UpdateTlsRouteRequest()];

declare 'DeleteTlsRouteRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::TlsRoute::DeleteTlsRouteRequest'];

coerce 'DeleteTlsRouteRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::TlsRoute::DeleteTlsRouteRequest'->new($_) };

declare 'RepeatedDeleteTlsRouteRequest',
    as ArrayRef[DeleteTlsRouteRequest()];

coerce 'RepeatedDeleteTlsRouteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::TlsRoute::DeleteTlsRouteRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTlsRouteRequest',
    as HashRef[DeleteTlsRouteRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Networkservices::V1::TlsRoute::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
