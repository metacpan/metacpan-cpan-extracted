package Google::Cloud::Networkservices::V1::Gateway::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Gateway',
    as InstanceOf['Google::Cloud::Networkservices::V1::Gateway::Gateway'];

coerce 'Gateway',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Gateway::Gateway'->new($_) };

declare 'RepeatedGateway',
    as ArrayRef[Gateway()];

coerce 'RepeatedGateway',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Gateway::Gateway'->new($_) } @$_ ] };

declare 'MapStringGateway',
    as HashRef[Gateway()];

declare 'Type',
    as (Int | Str);

declare 'IpVersion',
    as (Int | Str);

declare 'RoutingMode',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkservices::V1::Gateway::Gateway::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Gateway::Gateway::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Gateway::Gateway::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListGatewaysRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Gateway::ListGatewaysRequest'];

coerce 'ListGatewaysRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Gateway::ListGatewaysRequest'->new($_) };

declare 'RepeatedListGatewaysRequest',
    as ArrayRef[ListGatewaysRequest()];

coerce 'RepeatedListGatewaysRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Gateway::ListGatewaysRequest'->new($_) } @$_ ] };

declare 'MapStringListGatewaysRequest',
    as HashRef[ListGatewaysRequest()];

declare 'ListGatewaysResponse',
    as InstanceOf['Google::Cloud::Networkservices::V1::Gateway::ListGatewaysResponse'];

coerce 'ListGatewaysResponse',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Gateway::ListGatewaysResponse'->new($_) };

declare 'RepeatedListGatewaysResponse',
    as ArrayRef[ListGatewaysResponse()];

coerce 'RepeatedListGatewaysResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Gateway::ListGatewaysResponse'->new($_) } @$_ ] };

declare 'MapStringListGatewaysResponse',
    as HashRef[ListGatewaysResponse()];

declare 'GetGatewayRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Gateway::GetGatewayRequest'];

coerce 'GetGatewayRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Gateway::GetGatewayRequest'->new($_) };

declare 'RepeatedGetGatewayRequest',
    as ArrayRef[GetGatewayRequest()];

coerce 'RepeatedGetGatewayRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Gateway::GetGatewayRequest'->new($_) } @$_ ] };

declare 'MapStringGetGatewayRequest',
    as HashRef[GetGatewayRequest()];

declare 'CreateGatewayRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Gateway::CreateGatewayRequest'];

coerce 'CreateGatewayRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Gateway::CreateGatewayRequest'->new($_) };

declare 'RepeatedCreateGatewayRequest',
    as ArrayRef[CreateGatewayRequest()];

coerce 'RepeatedCreateGatewayRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Gateway::CreateGatewayRequest'->new($_) } @$_ ] };

declare 'MapStringCreateGatewayRequest',
    as HashRef[CreateGatewayRequest()];

declare 'UpdateGatewayRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Gateway::UpdateGatewayRequest'];

coerce 'UpdateGatewayRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Gateway::UpdateGatewayRequest'->new($_) };

declare 'RepeatedUpdateGatewayRequest',
    as ArrayRef[UpdateGatewayRequest()];

coerce 'RepeatedUpdateGatewayRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Gateway::UpdateGatewayRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateGatewayRequest',
    as HashRef[UpdateGatewayRequest()];

declare 'DeleteGatewayRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Gateway::DeleteGatewayRequest'];

coerce 'DeleteGatewayRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Gateway::DeleteGatewayRequest'->new($_) };

declare 'RepeatedDeleteGatewayRequest',
    as ArrayRef[DeleteGatewayRequest()];

coerce 'RepeatedDeleteGatewayRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Gateway::DeleteGatewayRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteGatewayRequest',
    as HashRef[DeleteGatewayRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Networkservices::V1::Gateway::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
