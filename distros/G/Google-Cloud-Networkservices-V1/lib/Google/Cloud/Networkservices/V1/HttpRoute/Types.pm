package Google::Cloud::Networkservices::V1::HttpRoute::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'HttpRoute',
    as InstanceOf['Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute'];

coerce 'HttpRoute',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute'->new($_) };

declare 'RepeatedHttpRoute',
    as ArrayRef[HttpRoute()];

coerce 'RepeatedHttpRoute',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute'->new($_) } @$_ ] };

declare 'MapStringHttpRoute',
    as HashRef[HttpRoute()];

declare 'HeaderMatch',
    as InstanceOf['Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::HeaderMatch'];

coerce 'HeaderMatch',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::HeaderMatch'->new($_) };

declare 'RepeatedHeaderMatch',
    as ArrayRef[HeaderMatch()];

coerce 'RepeatedHeaderMatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::HeaderMatch'->new($_) } @$_ ] };

declare 'MapStringHeaderMatch',
    as HashRef[HeaderMatch()];

declare 'IntegerRange',
    as InstanceOf['Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::HeaderMatch::IntegerRange'];

coerce 'IntegerRange',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::HeaderMatch::IntegerRange'->new($_) };

declare 'RepeatedIntegerRange',
    as ArrayRef[IntegerRange()];

coerce 'RepeatedIntegerRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::HeaderMatch::IntegerRange'->new($_) } @$_ ] };

declare 'MapStringIntegerRange',
    as HashRef[IntegerRange()];

declare 'QueryParameterMatch',
    as InstanceOf['Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::QueryParameterMatch'];

coerce 'QueryParameterMatch',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::QueryParameterMatch'->new($_) };

declare 'RepeatedQueryParameterMatch',
    as ArrayRef[QueryParameterMatch()];

coerce 'RepeatedQueryParameterMatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::QueryParameterMatch'->new($_) } @$_ ] };

declare 'MapStringQueryParameterMatch',
    as HashRef[QueryParameterMatch()];

declare 'RouteMatch',
    as InstanceOf['Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::RouteMatch'];

coerce 'RouteMatch',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::RouteMatch'->new($_) };

declare 'RepeatedRouteMatch',
    as ArrayRef[RouteMatch()];

coerce 'RepeatedRouteMatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::RouteMatch'->new($_) } @$_ ] };

declare 'MapStringRouteMatch',
    as HashRef[RouteMatch()];

declare 'Destination',
    as InstanceOf['Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::Destination'];

coerce 'Destination',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::Destination'->new($_) };

declare 'RepeatedDestination',
    as ArrayRef[Destination()];

coerce 'RepeatedDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::Destination'->new($_) } @$_ ] };

declare 'MapStringDestination',
    as HashRef[Destination()];

declare 'Redirect',
    as InstanceOf['Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::Redirect'];

coerce 'Redirect',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::Redirect'->new($_) };

declare 'RepeatedRedirect',
    as ArrayRef[Redirect()];

coerce 'RepeatedRedirect',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::Redirect'->new($_) } @$_ ] };

declare 'MapStringRedirect',
    as HashRef[Redirect()];

declare 'ResponseCode',
    as (Int | Str);

declare 'FaultInjectionPolicy',
    as InstanceOf['Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::FaultInjectionPolicy'];

coerce 'FaultInjectionPolicy',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::FaultInjectionPolicy'->new($_) };

declare 'RepeatedFaultInjectionPolicy',
    as ArrayRef[FaultInjectionPolicy()];

coerce 'RepeatedFaultInjectionPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::FaultInjectionPolicy'->new($_) } @$_ ] };

declare 'MapStringFaultInjectionPolicy',
    as HashRef[FaultInjectionPolicy()];

declare 'Delay',
    as InstanceOf['Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::FaultInjectionPolicy::Delay'];

coerce 'Delay',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::FaultInjectionPolicy::Delay'->new($_) };

declare 'RepeatedDelay',
    as ArrayRef[Delay()];

coerce 'RepeatedDelay',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::FaultInjectionPolicy::Delay'->new($_) } @$_ ] };

declare 'MapStringDelay',
    as HashRef[Delay()];

declare 'Abort',
    as InstanceOf['Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::FaultInjectionPolicy::Abort'];

coerce 'Abort',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::FaultInjectionPolicy::Abort'->new($_) };

declare 'RepeatedAbort',
    as ArrayRef[Abort()];

coerce 'RepeatedAbort',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::FaultInjectionPolicy::Abort'->new($_) } @$_ ] };

declare 'MapStringAbort',
    as HashRef[Abort()];

declare 'StatefulSessionAffinityPolicy',
    as InstanceOf['Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::StatefulSessionAffinityPolicy'];

coerce 'StatefulSessionAffinityPolicy',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::StatefulSessionAffinityPolicy'->new($_) };

declare 'RepeatedStatefulSessionAffinityPolicy',
    as ArrayRef[StatefulSessionAffinityPolicy()];

coerce 'RepeatedStatefulSessionAffinityPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::StatefulSessionAffinityPolicy'->new($_) } @$_ ] };

declare 'MapStringStatefulSessionAffinityPolicy',
    as HashRef[StatefulSessionAffinityPolicy()];

declare 'HeaderModifier',
    as InstanceOf['Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::HeaderModifier'];

coerce 'HeaderModifier',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::HeaderModifier'->new($_) };

declare 'RepeatedHeaderModifier',
    as ArrayRef[HeaderModifier()];

coerce 'RepeatedHeaderModifier',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::HeaderModifier'->new($_) } @$_ ] };

declare 'MapStringHeaderModifier',
    as HashRef[HeaderModifier()];

declare 'SetEntry',
    as InstanceOf['Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::HeaderModifier::SetEntry'];

coerce 'SetEntry',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::HeaderModifier::SetEntry'->new($_) };

declare 'RepeatedSetEntry',
    as ArrayRef[SetEntry()];

coerce 'RepeatedSetEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::HeaderModifier::SetEntry'->new($_) } @$_ ] };

declare 'MapStringSetEntry',
    as HashRef[SetEntry()];

declare 'AddEntry',
    as InstanceOf['Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::HeaderModifier::AddEntry'];

coerce 'AddEntry',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::HeaderModifier::AddEntry'->new($_) };

declare 'RepeatedAddEntry',
    as ArrayRef[AddEntry()];

coerce 'RepeatedAddEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::HeaderModifier::AddEntry'->new($_) } @$_ ] };

declare 'MapStringAddEntry',
    as HashRef[AddEntry()];

declare 'URLRewrite',
    as InstanceOf['Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::URLRewrite'];

coerce 'URLRewrite',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::URLRewrite'->new($_) };

declare 'RepeatedURLRewrite',
    as ArrayRef[URLRewrite()];

coerce 'RepeatedURLRewrite',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::URLRewrite'->new($_) } @$_ ] };

declare 'MapStringURLRewrite',
    as HashRef[URLRewrite()];

declare 'RetryPolicy',
    as InstanceOf['Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::RetryPolicy'];

coerce 'RetryPolicy',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::RetryPolicy'->new($_) };

declare 'RepeatedRetryPolicy',
    as ArrayRef[RetryPolicy()];

coerce 'RepeatedRetryPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::RetryPolicy'->new($_) } @$_ ] };

declare 'MapStringRetryPolicy',
    as HashRef[RetryPolicy()];

declare 'RequestMirrorPolicy',
    as InstanceOf['Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::RequestMirrorPolicy'];

coerce 'RequestMirrorPolicy',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::RequestMirrorPolicy'->new($_) };

declare 'RepeatedRequestMirrorPolicy',
    as ArrayRef[RequestMirrorPolicy()];

coerce 'RepeatedRequestMirrorPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::RequestMirrorPolicy'->new($_) } @$_ ] };

declare 'MapStringRequestMirrorPolicy',
    as HashRef[RequestMirrorPolicy()];

declare 'CorsPolicy',
    as InstanceOf['Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::CorsPolicy'];

coerce 'CorsPolicy',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::CorsPolicy'->new($_) };

declare 'RepeatedCorsPolicy',
    as ArrayRef[CorsPolicy()];

coerce 'RepeatedCorsPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::CorsPolicy'->new($_) } @$_ ] };

declare 'MapStringCorsPolicy',
    as HashRef[CorsPolicy()];

declare 'HttpDirectResponse',
    as InstanceOf['Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::HttpDirectResponse'];

coerce 'HttpDirectResponse',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::HttpDirectResponse'->new($_) };

declare 'RepeatedHttpDirectResponse',
    as ArrayRef[HttpDirectResponse()];

coerce 'RepeatedHttpDirectResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::HttpDirectResponse'->new($_) } @$_ ] };

declare 'MapStringHttpDirectResponse',
    as HashRef[HttpDirectResponse()];

declare 'RouteAction',
    as InstanceOf['Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::RouteAction'];

coerce 'RouteAction',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::RouteAction'->new($_) };

declare 'RepeatedRouteAction',
    as ArrayRef[RouteAction()];

coerce 'RepeatedRouteAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::RouteAction'->new($_) } @$_ ] };

declare 'MapStringRouteAction',
    as HashRef[RouteAction()];

declare 'RouteRule',
    as InstanceOf['Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::RouteRule'];

coerce 'RouteRule',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::RouteRule'->new($_) };

declare 'RepeatedRouteRule',
    as ArrayRef[RouteRule()];

coerce 'RepeatedRouteRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::RouteRule'->new($_) } @$_ ] };

declare 'MapStringRouteRule',
    as HashRef[RouteRule()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::HttpRoute::HttpRoute::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListHttpRoutesRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::HttpRoute::ListHttpRoutesRequest'];

coerce 'ListHttpRoutesRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::HttpRoute::ListHttpRoutesRequest'->new($_) };

declare 'RepeatedListHttpRoutesRequest',
    as ArrayRef[ListHttpRoutesRequest()];

coerce 'RepeatedListHttpRoutesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::HttpRoute::ListHttpRoutesRequest'->new($_) } @$_ ] };

declare 'MapStringListHttpRoutesRequest',
    as HashRef[ListHttpRoutesRequest()];

declare 'ListHttpRoutesResponse',
    as InstanceOf['Google::Cloud::Networkservices::V1::HttpRoute::ListHttpRoutesResponse'];

coerce 'ListHttpRoutesResponse',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::HttpRoute::ListHttpRoutesResponse'->new($_) };

declare 'RepeatedListHttpRoutesResponse',
    as ArrayRef[ListHttpRoutesResponse()];

coerce 'RepeatedListHttpRoutesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::HttpRoute::ListHttpRoutesResponse'->new($_) } @$_ ] };

declare 'MapStringListHttpRoutesResponse',
    as HashRef[ListHttpRoutesResponse()];

declare 'GetHttpRouteRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::HttpRoute::GetHttpRouteRequest'];

coerce 'GetHttpRouteRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::HttpRoute::GetHttpRouteRequest'->new($_) };

declare 'RepeatedGetHttpRouteRequest',
    as ArrayRef[GetHttpRouteRequest()];

coerce 'RepeatedGetHttpRouteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::HttpRoute::GetHttpRouteRequest'->new($_) } @$_ ] };

declare 'MapStringGetHttpRouteRequest',
    as HashRef[GetHttpRouteRequest()];

declare 'CreateHttpRouteRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::HttpRoute::CreateHttpRouteRequest'];

coerce 'CreateHttpRouteRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::HttpRoute::CreateHttpRouteRequest'->new($_) };

declare 'RepeatedCreateHttpRouteRequest',
    as ArrayRef[CreateHttpRouteRequest()];

coerce 'RepeatedCreateHttpRouteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::HttpRoute::CreateHttpRouteRequest'->new($_) } @$_ ] };

declare 'MapStringCreateHttpRouteRequest',
    as HashRef[CreateHttpRouteRequest()];

declare 'UpdateHttpRouteRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::HttpRoute::UpdateHttpRouteRequest'];

coerce 'UpdateHttpRouteRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::HttpRoute::UpdateHttpRouteRequest'->new($_) };

declare 'RepeatedUpdateHttpRouteRequest',
    as ArrayRef[UpdateHttpRouteRequest()];

coerce 'RepeatedUpdateHttpRouteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::HttpRoute::UpdateHttpRouteRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateHttpRouteRequest',
    as HashRef[UpdateHttpRouteRequest()];

declare 'DeleteHttpRouteRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::HttpRoute::DeleteHttpRouteRequest'];

coerce 'DeleteHttpRouteRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::HttpRoute::DeleteHttpRouteRequest'->new($_) };

declare 'RepeatedDeleteHttpRouteRequest',
    as ArrayRef[DeleteHttpRouteRequest()];

coerce 'RepeatedDeleteHttpRouteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::HttpRoute::DeleteHttpRouteRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteHttpRouteRequest',
    as HashRef[DeleteHttpRouteRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Networkservices::V1::HttpRoute::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
