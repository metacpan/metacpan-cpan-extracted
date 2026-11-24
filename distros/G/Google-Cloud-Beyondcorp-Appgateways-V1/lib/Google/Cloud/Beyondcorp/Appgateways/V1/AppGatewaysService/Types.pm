package Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListAppGatewaysRequest',
    as InstanceOf['Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::ListAppGatewaysRequest'];

coerce 'ListAppGatewaysRequest',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::ListAppGatewaysRequest'->new($_) };

declare 'RepeatedListAppGatewaysRequest',
    as ArrayRef[ListAppGatewaysRequest()];

coerce 'RepeatedListAppGatewaysRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::ListAppGatewaysRequest'->new($_) } @$_ ] };

declare 'MapStringListAppGatewaysRequest',
    as HashRef[ListAppGatewaysRequest()];

declare 'ListAppGatewaysResponse',
    as InstanceOf['Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::ListAppGatewaysResponse'];

coerce 'ListAppGatewaysResponse',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::ListAppGatewaysResponse'->new($_) };

declare 'RepeatedListAppGatewaysResponse',
    as ArrayRef[ListAppGatewaysResponse()];

coerce 'RepeatedListAppGatewaysResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::ListAppGatewaysResponse'->new($_) } @$_ ] };

declare 'MapStringListAppGatewaysResponse',
    as HashRef[ListAppGatewaysResponse()];

declare 'GetAppGatewayRequest',
    as InstanceOf['Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::GetAppGatewayRequest'];

coerce 'GetAppGatewayRequest',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::GetAppGatewayRequest'->new($_) };

declare 'RepeatedGetAppGatewayRequest',
    as ArrayRef[GetAppGatewayRequest()];

coerce 'RepeatedGetAppGatewayRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::GetAppGatewayRequest'->new($_) } @$_ ] };

declare 'MapStringGetAppGatewayRequest',
    as HashRef[GetAppGatewayRequest()];

declare 'CreateAppGatewayRequest',
    as InstanceOf['Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::CreateAppGatewayRequest'];

coerce 'CreateAppGatewayRequest',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::CreateAppGatewayRequest'->new($_) };

declare 'RepeatedCreateAppGatewayRequest',
    as ArrayRef[CreateAppGatewayRequest()];

coerce 'RepeatedCreateAppGatewayRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::CreateAppGatewayRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAppGatewayRequest',
    as HashRef[CreateAppGatewayRequest()];

declare 'DeleteAppGatewayRequest',
    as InstanceOf['Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::DeleteAppGatewayRequest'];

coerce 'DeleteAppGatewayRequest',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::DeleteAppGatewayRequest'->new($_) };

declare 'RepeatedDeleteAppGatewayRequest',
    as ArrayRef[DeleteAppGatewayRequest()];

coerce 'RepeatedDeleteAppGatewayRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::DeleteAppGatewayRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAppGatewayRequest',
    as HashRef[DeleteAppGatewayRequest()];

declare 'AppGateway',
    as InstanceOf['Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::AppGateway'];

coerce 'AppGateway',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::AppGateway'->new($_) };

declare 'RepeatedAppGateway',
    as ArrayRef[AppGateway()];

coerce 'RepeatedAppGateway',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::AppGateway'->new($_) } @$_ ] };

declare 'MapStringAppGateway',
    as HashRef[AppGateway()];

declare 'Type',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'HostType',
    as (Int | Str);

declare 'AllocatedConnection',
    as InstanceOf['Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::AppGateway::AllocatedConnection'];

coerce 'AllocatedConnection',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::AppGateway::AllocatedConnection'->new($_) };

declare 'RepeatedAllocatedConnection',
    as ArrayRef[AllocatedConnection()];

coerce 'RepeatedAllocatedConnection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::AppGateway::AllocatedConnection'->new($_) } @$_ ] };

declare 'MapStringAllocatedConnection',
    as HashRef[AllocatedConnection()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::AppGateway::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::AppGateway::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::AppGateway::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AppGatewayOperationMetadata',
    as InstanceOf['Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::AppGatewayOperationMetadata'];

coerce 'AppGatewayOperationMetadata',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::AppGatewayOperationMetadata'->new($_) };

declare 'RepeatedAppGatewayOperationMetadata',
    as ArrayRef[AppGatewayOperationMetadata()];

coerce 'RepeatedAppGatewayOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::AppGatewayOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringAppGatewayOperationMetadata',
    as HashRef[AppGatewayOperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Beyondcorp::Appgateways::V1::AppGatewaysService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
