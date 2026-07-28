package Google::Cloud::Networkservices::V1::GrpcRoute::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GrpcRoute',
    as InstanceOf['Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute'];

coerce 'GrpcRoute',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute'->new($_) };

declare 'RepeatedGrpcRoute',
    as ArrayRef[GrpcRoute()];

coerce 'RepeatedGrpcRoute',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute'->new($_) } @$_ ] };

declare 'MapStringGrpcRoute',
    as HashRef[GrpcRoute()];

declare 'MethodMatch',
    as InstanceOf['Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::MethodMatch'];

coerce 'MethodMatch',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::MethodMatch'->new($_) };

declare 'RepeatedMethodMatch',
    as ArrayRef[MethodMatch()];

coerce 'RepeatedMethodMatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::MethodMatch'->new($_) } @$_ ] };

declare 'MapStringMethodMatch',
    as HashRef[MethodMatch()];

declare 'Type',
    as (Int | Str);

declare 'HeaderMatch',
    as InstanceOf['Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::HeaderMatch'];

coerce 'HeaderMatch',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::HeaderMatch'->new($_) };

declare 'RepeatedHeaderMatch',
    as ArrayRef[HeaderMatch()];

coerce 'RepeatedHeaderMatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::HeaderMatch'->new($_) } @$_ ] };

declare 'MapStringHeaderMatch',
    as HashRef[HeaderMatch()];

declare 'Type',
    as (Int | Str);

declare 'RouteMatch',
    as InstanceOf['Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::RouteMatch'];

coerce 'RouteMatch',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::RouteMatch'->new($_) };

declare 'RepeatedRouteMatch',
    as ArrayRef[RouteMatch()];

coerce 'RepeatedRouteMatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::RouteMatch'->new($_) } @$_ ] };

declare 'MapStringRouteMatch',
    as HashRef[RouteMatch()];

declare 'Destination',
    as InstanceOf['Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::Destination'];

coerce 'Destination',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::Destination'->new($_) };

declare 'RepeatedDestination',
    as ArrayRef[Destination()];

coerce 'RepeatedDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::Destination'->new($_) } @$_ ] };

declare 'MapStringDestination',
    as HashRef[Destination()];

declare 'FaultInjectionPolicy',
    as InstanceOf['Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::FaultInjectionPolicy'];

coerce 'FaultInjectionPolicy',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::FaultInjectionPolicy'->new($_) };

declare 'RepeatedFaultInjectionPolicy',
    as ArrayRef[FaultInjectionPolicy()];

coerce 'RepeatedFaultInjectionPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::FaultInjectionPolicy'->new($_) } @$_ ] };

declare 'MapStringFaultInjectionPolicy',
    as HashRef[FaultInjectionPolicy()];

declare 'Delay',
    as InstanceOf['Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::FaultInjectionPolicy::Delay'];

coerce 'Delay',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::FaultInjectionPolicy::Delay'->new($_) };

declare 'RepeatedDelay',
    as ArrayRef[Delay()];

coerce 'RepeatedDelay',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::FaultInjectionPolicy::Delay'->new($_) } @$_ ] };

declare 'MapStringDelay',
    as HashRef[Delay()];

declare 'Abort',
    as InstanceOf['Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::FaultInjectionPolicy::Abort'];

coerce 'Abort',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::FaultInjectionPolicy::Abort'->new($_) };

declare 'RepeatedAbort',
    as ArrayRef[Abort()];

coerce 'RepeatedAbort',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::FaultInjectionPolicy::Abort'->new($_) } @$_ ] };

declare 'MapStringAbort',
    as HashRef[Abort()];

declare 'StatefulSessionAffinityPolicy',
    as InstanceOf['Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::StatefulSessionAffinityPolicy'];

coerce 'StatefulSessionAffinityPolicy',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::StatefulSessionAffinityPolicy'->new($_) };

declare 'RepeatedStatefulSessionAffinityPolicy',
    as ArrayRef[StatefulSessionAffinityPolicy()];

coerce 'RepeatedStatefulSessionAffinityPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::StatefulSessionAffinityPolicy'->new($_) } @$_ ] };

declare 'MapStringStatefulSessionAffinityPolicy',
    as HashRef[StatefulSessionAffinityPolicy()];

declare 'RetryPolicy',
    as InstanceOf['Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::RetryPolicy'];

coerce 'RetryPolicy',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::RetryPolicy'->new($_) };

declare 'RepeatedRetryPolicy',
    as ArrayRef[RetryPolicy()];

coerce 'RepeatedRetryPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::RetryPolicy'->new($_) } @$_ ] };

declare 'MapStringRetryPolicy',
    as HashRef[RetryPolicy()];

declare 'RouteAction',
    as InstanceOf['Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::RouteAction'];

coerce 'RouteAction',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::RouteAction'->new($_) };

declare 'RepeatedRouteAction',
    as ArrayRef[RouteAction()];

coerce 'RepeatedRouteAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::RouteAction'->new($_) } @$_ ] };

declare 'MapStringRouteAction',
    as HashRef[RouteAction()];

declare 'RouteRule',
    as InstanceOf['Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::RouteRule'];

coerce 'RouteRule',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::RouteRule'->new($_) };

declare 'RepeatedRouteRule',
    as ArrayRef[RouteRule()];

coerce 'RepeatedRouteRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::RouteRule'->new($_) } @$_ ] };

declare 'MapStringRouteRule',
    as HashRef[RouteRule()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::GrpcRoute::GrpcRoute::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListGrpcRoutesRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::GrpcRoute::ListGrpcRoutesRequest'];

coerce 'ListGrpcRoutesRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::GrpcRoute::ListGrpcRoutesRequest'->new($_) };

declare 'RepeatedListGrpcRoutesRequest',
    as ArrayRef[ListGrpcRoutesRequest()];

coerce 'RepeatedListGrpcRoutesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::GrpcRoute::ListGrpcRoutesRequest'->new($_) } @$_ ] };

declare 'MapStringListGrpcRoutesRequest',
    as HashRef[ListGrpcRoutesRequest()];

declare 'ListGrpcRoutesResponse',
    as InstanceOf['Google::Cloud::Networkservices::V1::GrpcRoute::ListGrpcRoutesResponse'];

coerce 'ListGrpcRoutesResponse',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::GrpcRoute::ListGrpcRoutesResponse'->new($_) };

declare 'RepeatedListGrpcRoutesResponse',
    as ArrayRef[ListGrpcRoutesResponse()];

coerce 'RepeatedListGrpcRoutesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::GrpcRoute::ListGrpcRoutesResponse'->new($_) } @$_ ] };

declare 'MapStringListGrpcRoutesResponse',
    as HashRef[ListGrpcRoutesResponse()];

declare 'GetGrpcRouteRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::GrpcRoute::GetGrpcRouteRequest'];

coerce 'GetGrpcRouteRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::GrpcRoute::GetGrpcRouteRequest'->new($_) };

declare 'RepeatedGetGrpcRouteRequest',
    as ArrayRef[GetGrpcRouteRequest()];

coerce 'RepeatedGetGrpcRouteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::GrpcRoute::GetGrpcRouteRequest'->new($_) } @$_ ] };

declare 'MapStringGetGrpcRouteRequest',
    as HashRef[GetGrpcRouteRequest()];

declare 'CreateGrpcRouteRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::GrpcRoute::CreateGrpcRouteRequest'];

coerce 'CreateGrpcRouteRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::GrpcRoute::CreateGrpcRouteRequest'->new($_) };

declare 'RepeatedCreateGrpcRouteRequest',
    as ArrayRef[CreateGrpcRouteRequest()];

coerce 'RepeatedCreateGrpcRouteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::GrpcRoute::CreateGrpcRouteRequest'->new($_) } @$_ ] };

declare 'MapStringCreateGrpcRouteRequest',
    as HashRef[CreateGrpcRouteRequest()];

declare 'UpdateGrpcRouteRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::GrpcRoute::UpdateGrpcRouteRequest'];

coerce 'UpdateGrpcRouteRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::GrpcRoute::UpdateGrpcRouteRequest'->new($_) };

declare 'RepeatedUpdateGrpcRouteRequest',
    as ArrayRef[UpdateGrpcRouteRequest()];

coerce 'RepeatedUpdateGrpcRouteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::GrpcRoute::UpdateGrpcRouteRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateGrpcRouteRequest',
    as HashRef[UpdateGrpcRouteRequest()];

declare 'DeleteGrpcRouteRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::GrpcRoute::DeleteGrpcRouteRequest'];

coerce 'DeleteGrpcRouteRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::GrpcRoute::DeleteGrpcRouteRequest'->new($_) };

declare 'RepeatedDeleteGrpcRouteRequest',
    as ArrayRef[DeleteGrpcRouteRequest()];

coerce 'RepeatedDeleteGrpcRouteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::GrpcRoute::DeleteGrpcRouteRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteGrpcRouteRequest',
    as HashRef[DeleteGrpcRouteRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Networkservices::V1::GrpcRoute::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
