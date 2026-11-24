package Google::Cloud::Servicehealth::V1::EventResources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EventView',
    as (Int | Str);

declare 'OrganizationEventView',
    as (Int | Str);

declare 'Event',
    as InstanceOf['Google::Cloud::Servicehealth::V1::EventResources::Event'];

coerce 'Event',
    from HashRef, via { 'Google::Cloud::Servicehealth::V1::EventResources::Event'->new($_) };

declare 'RepeatedEvent',
    as ArrayRef[Event()];

coerce 'RepeatedEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicehealth::V1::EventResources::Event'->new($_) } @$_ ] };

declare 'MapStringEvent',
    as HashRef[Event()];

declare 'EventCategory',
    as (Int | Str);

declare 'DetailedCategory',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'DetailedState',
    as (Int | Str);

declare 'Relevance',
    as (Int | Str);

declare 'OrganizationEvent',
    as InstanceOf['Google::Cloud::Servicehealth::V1::EventResources::OrganizationEvent'];

coerce 'OrganizationEvent',
    from HashRef, via { 'Google::Cloud::Servicehealth::V1::EventResources::OrganizationEvent'->new($_) };

declare 'RepeatedOrganizationEvent',
    as ArrayRef[OrganizationEvent()];

coerce 'RepeatedOrganizationEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicehealth::V1::EventResources::OrganizationEvent'->new($_) } @$_ ] };

declare 'MapStringOrganizationEvent',
    as HashRef[OrganizationEvent()];

declare 'EventCategory',
    as (Int | Str);

declare 'DetailedCategory',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'DetailedState',
    as (Int | Str);

declare 'EventUpdate',
    as InstanceOf['Google::Cloud::Servicehealth::V1::EventResources::EventUpdate'];

coerce 'EventUpdate',
    from HashRef, via { 'Google::Cloud::Servicehealth::V1::EventResources::EventUpdate'->new($_) };

declare 'RepeatedEventUpdate',
    as ArrayRef[EventUpdate()];

coerce 'RepeatedEventUpdate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicehealth::V1::EventResources::EventUpdate'->new($_) } @$_ ] };

declare 'MapStringEventUpdate',
    as HashRef[EventUpdate()];

declare 'Location',
    as InstanceOf['Google::Cloud::Servicehealth::V1::EventResources::Location'];

coerce 'Location',
    from HashRef, via { 'Google::Cloud::Servicehealth::V1::EventResources::Location'->new($_) };

declare 'RepeatedLocation',
    as ArrayRef[Location()];

coerce 'RepeatedLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicehealth::V1::EventResources::Location'->new($_) } @$_ ] };

declare 'MapStringLocation',
    as HashRef[Location()];

declare 'Product',
    as InstanceOf['Google::Cloud::Servicehealth::V1::EventResources::Product'];

coerce 'Product',
    from HashRef, via { 'Google::Cloud::Servicehealth::V1::EventResources::Product'->new($_) };

declare 'RepeatedProduct',
    as ArrayRef[Product()];

coerce 'RepeatedProduct',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicehealth::V1::EventResources::Product'->new($_) } @$_ ] };

declare 'MapStringProduct',
    as HashRef[Product()];

declare 'EventImpact',
    as InstanceOf['Google::Cloud::Servicehealth::V1::EventResources::EventImpact'];

coerce 'EventImpact',
    from HashRef, via { 'Google::Cloud::Servicehealth::V1::EventResources::EventImpact'->new($_) };

declare 'RepeatedEventImpact',
    as ArrayRef[EventImpact()];

coerce 'RepeatedEventImpact',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicehealth::V1::EventResources::EventImpact'->new($_) } @$_ ] };

declare 'MapStringEventImpact',
    as HashRef[EventImpact()];

declare 'OrganizationImpact',
    as InstanceOf['Google::Cloud::Servicehealth::V1::EventResources::OrganizationImpact'];

coerce 'OrganizationImpact',
    from HashRef, via { 'Google::Cloud::Servicehealth::V1::EventResources::OrganizationImpact'->new($_) };

declare 'RepeatedOrganizationImpact',
    as ArrayRef[OrganizationImpact()];

coerce 'RepeatedOrganizationImpact',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicehealth::V1::EventResources::OrganizationImpact'->new($_) } @$_ ] };

declare 'MapStringOrganizationImpact',
    as HashRef[OrganizationImpact()];

declare 'Asset',
    as InstanceOf['Google::Cloud::Servicehealth::V1::EventResources::Asset'];

coerce 'Asset',
    from HashRef, via { 'Google::Cloud::Servicehealth::V1::EventResources::Asset'->new($_) };

declare 'RepeatedAsset',
    as ArrayRef[Asset()];

coerce 'RepeatedAsset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicehealth::V1::EventResources::Asset'->new($_) } @$_ ] };

declare 'MapStringAsset',
    as HashRef[Asset()];

declare 'ListEventsRequest',
    as InstanceOf['Google::Cloud::Servicehealth::V1::EventResources::ListEventsRequest'];

coerce 'ListEventsRequest',
    from HashRef, via { 'Google::Cloud::Servicehealth::V1::EventResources::ListEventsRequest'->new($_) };

declare 'RepeatedListEventsRequest',
    as ArrayRef[ListEventsRequest()];

coerce 'RepeatedListEventsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicehealth::V1::EventResources::ListEventsRequest'->new($_) } @$_ ] };

declare 'MapStringListEventsRequest',
    as HashRef[ListEventsRequest()];

declare 'ListEventsResponse',
    as InstanceOf['Google::Cloud::Servicehealth::V1::EventResources::ListEventsResponse'];

coerce 'ListEventsResponse',
    from HashRef, via { 'Google::Cloud::Servicehealth::V1::EventResources::ListEventsResponse'->new($_) };

declare 'RepeatedListEventsResponse',
    as ArrayRef[ListEventsResponse()];

coerce 'RepeatedListEventsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicehealth::V1::EventResources::ListEventsResponse'->new($_) } @$_ ] };

declare 'MapStringListEventsResponse',
    as HashRef[ListEventsResponse()];

declare 'GetEventRequest',
    as InstanceOf['Google::Cloud::Servicehealth::V1::EventResources::GetEventRequest'];

coerce 'GetEventRequest',
    from HashRef, via { 'Google::Cloud::Servicehealth::V1::EventResources::GetEventRequest'->new($_) };

declare 'RepeatedGetEventRequest',
    as ArrayRef[GetEventRequest()];

coerce 'RepeatedGetEventRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicehealth::V1::EventResources::GetEventRequest'->new($_) } @$_ ] };

declare 'MapStringGetEventRequest',
    as HashRef[GetEventRequest()];

declare 'ListOrganizationEventsRequest',
    as InstanceOf['Google::Cloud::Servicehealth::V1::EventResources::ListOrganizationEventsRequest'];

coerce 'ListOrganizationEventsRequest',
    from HashRef, via { 'Google::Cloud::Servicehealth::V1::EventResources::ListOrganizationEventsRequest'->new($_) };

declare 'RepeatedListOrganizationEventsRequest',
    as ArrayRef[ListOrganizationEventsRequest()];

coerce 'RepeatedListOrganizationEventsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicehealth::V1::EventResources::ListOrganizationEventsRequest'->new($_) } @$_ ] };

declare 'MapStringListOrganizationEventsRequest',
    as HashRef[ListOrganizationEventsRequest()];

declare 'ListOrganizationEventsResponse',
    as InstanceOf['Google::Cloud::Servicehealth::V1::EventResources::ListOrganizationEventsResponse'];

coerce 'ListOrganizationEventsResponse',
    from HashRef, via { 'Google::Cloud::Servicehealth::V1::EventResources::ListOrganizationEventsResponse'->new($_) };

declare 'RepeatedListOrganizationEventsResponse',
    as ArrayRef[ListOrganizationEventsResponse()];

coerce 'RepeatedListOrganizationEventsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicehealth::V1::EventResources::ListOrganizationEventsResponse'->new($_) } @$_ ] };

declare 'MapStringListOrganizationEventsResponse',
    as HashRef[ListOrganizationEventsResponse()];

declare 'GetOrganizationEventRequest',
    as InstanceOf['Google::Cloud::Servicehealth::V1::EventResources::GetOrganizationEventRequest'];

coerce 'GetOrganizationEventRequest',
    from HashRef, via { 'Google::Cloud::Servicehealth::V1::EventResources::GetOrganizationEventRequest'->new($_) };

declare 'RepeatedGetOrganizationEventRequest',
    as ArrayRef[GetOrganizationEventRequest()];

coerce 'RepeatedGetOrganizationEventRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicehealth::V1::EventResources::GetOrganizationEventRequest'->new($_) } @$_ ] };

declare 'MapStringGetOrganizationEventRequest',
    as HashRef[GetOrganizationEventRequest()];

declare 'ListOrganizationImpactsRequest',
    as InstanceOf['Google::Cloud::Servicehealth::V1::EventResources::ListOrganizationImpactsRequest'];

coerce 'ListOrganizationImpactsRequest',
    from HashRef, via { 'Google::Cloud::Servicehealth::V1::EventResources::ListOrganizationImpactsRequest'->new($_) };

declare 'RepeatedListOrganizationImpactsRequest',
    as ArrayRef[ListOrganizationImpactsRequest()];

coerce 'RepeatedListOrganizationImpactsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicehealth::V1::EventResources::ListOrganizationImpactsRequest'->new($_) } @$_ ] };

declare 'MapStringListOrganizationImpactsRequest',
    as HashRef[ListOrganizationImpactsRequest()];

declare 'ListOrganizationImpactsResponse',
    as InstanceOf['Google::Cloud::Servicehealth::V1::EventResources::ListOrganizationImpactsResponse'];

coerce 'ListOrganizationImpactsResponse',
    from HashRef, via { 'Google::Cloud::Servicehealth::V1::EventResources::ListOrganizationImpactsResponse'->new($_) };

declare 'RepeatedListOrganizationImpactsResponse',
    as ArrayRef[ListOrganizationImpactsResponse()];

coerce 'RepeatedListOrganizationImpactsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicehealth::V1::EventResources::ListOrganizationImpactsResponse'->new($_) } @$_ ] };

declare 'MapStringListOrganizationImpactsResponse',
    as HashRef[ListOrganizationImpactsResponse()];

declare 'GetOrganizationImpactRequest',
    as InstanceOf['Google::Cloud::Servicehealth::V1::EventResources::GetOrganizationImpactRequest'];

coerce 'GetOrganizationImpactRequest',
    from HashRef, via { 'Google::Cloud::Servicehealth::V1::EventResources::GetOrganizationImpactRequest'->new($_) };

declare 'RepeatedGetOrganizationImpactRequest',
    as ArrayRef[GetOrganizationImpactRequest()];

coerce 'RepeatedGetOrganizationImpactRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicehealth::V1::EventResources::GetOrganizationImpactRequest'->new($_) } @$_ ] };

declare 'MapStringGetOrganizationImpactRequest',
    as HashRef[GetOrganizationImpactRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Servicehealth::V1::EventResources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
