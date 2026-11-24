package Google::Cloud::Dialogflow::V2::Fulfillment::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Fulfillment',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Fulfillment::Fulfillment'];

coerce 'Fulfillment',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Fulfillment::Fulfillment'->new($_) };

declare 'RepeatedFulfillment',
    as ArrayRef[Fulfillment()];

coerce 'RepeatedFulfillment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Fulfillment::Fulfillment'->new($_) } @$_ ] };

declare 'MapStringFulfillment',
    as HashRef[Fulfillment()];

declare 'GenericWebService',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Fulfillment::Fulfillment::GenericWebService'];

coerce 'GenericWebService',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Fulfillment::Fulfillment::GenericWebService'->new($_) };

declare 'RepeatedGenericWebService',
    as ArrayRef[GenericWebService()];

coerce 'RepeatedGenericWebService',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Fulfillment::Fulfillment::GenericWebService'->new($_) } @$_ ] };

declare 'MapStringGenericWebService',
    as HashRef[GenericWebService()];

declare 'RequestHeadersEntry',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Fulfillment::Fulfillment::GenericWebService::RequestHeadersEntry'];

coerce 'RequestHeadersEntry',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Fulfillment::Fulfillment::GenericWebService::RequestHeadersEntry'->new($_) };

declare 'RepeatedRequestHeadersEntry',
    as ArrayRef[RequestHeadersEntry()];

coerce 'RepeatedRequestHeadersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Fulfillment::Fulfillment::GenericWebService::RequestHeadersEntry'->new($_) } @$_ ] };

declare 'MapStringRequestHeadersEntry',
    as HashRef[RequestHeadersEntry()];

declare 'Feature',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Fulfillment::Fulfillment::Feature'];

coerce 'Feature',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Fulfillment::Fulfillment::Feature'->new($_) };

declare 'RepeatedFeature',
    as ArrayRef[Feature()];

coerce 'RepeatedFeature',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Fulfillment::Fulfillment::Feature'->new($_) } @$_ ] };

declare 'MapStringFeature',
    as HashRef[Feature()];

declare 'Type',
    as (Int | Str);

declare 'GetFulfillmentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Fulfillment::GetFulfillmentRequest'];

coerce 'GetFulfillmentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Fulfillment::GetFulfillmentRequest'->new($_) };

declare 'RepeatedGetFulfillmentRequest',
    as ArrayRef[GetFulfillmentRequest()];

coerce 'RepeatedGetFulfillmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Fulfillment::GetFulfillmentRequest'->new($_) } @$_ ] };

declare 'MapStringGetFulfillmentRequest',
    as HashRef[GetFulfillmentRequest()];

declare 'UpdateFulfillmentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Fulfillment::UpdateFulfillmentRequest'];

coerce 'UpdateFulfillmentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Fulfillment::UpdateFulfillmentRequest'->new($_) };

declare 'RepeatedUpdateFulfillmentRequest',
    as ArrayRef[UpdateFulfillmentRequest()];

coerce 'RepeatedUpdateFulfillmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Fulfillment::UpdateFulfillmentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateFulfillmentRequest',
    as HashRef[UpdateFulfillmentRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2::Fulfillment::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
