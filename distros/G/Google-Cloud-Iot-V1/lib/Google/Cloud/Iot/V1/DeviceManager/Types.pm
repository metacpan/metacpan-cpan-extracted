package Google::Cloud::Iot::V1::DeviceManager::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateDeviceRegistryRequest',
    as InstanceOf['Google::Cloud::Iot::V1::DeviceManager::CreateDeviceRegistryRequest'];

coerce 'CreateDeviceRegistryRequest',
    from HashRef, via { 'Google::Cloud::Iot::V1::DeviceManager::CreateDeviceRegistryRequest'->new($_) };

declare 'RepeatedCreateDeviceRegistryRequest',
    as ArrayRef[CreateDeviceRegistryRequest()];

coerce 'RepeatedCreateDeviceRegistryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::DeviceManager::CreateDeviceRegistryRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDeviceRegistryRequest',
    as HashRef[CreateDeviceRegistryRequest()];

declare 'GetDeviceRegistryRequest',
    as InstanceOf['Google::Cloud::Iot::V1::DeviceManager::GetDeviceRegistryRequest'];

coerce 'GetDeviceRegistryRequest',
    from HashRef, via { 'Google::Cloud::Iot::V1::DeviceManager::GetDeviceRegistryRequest'->new($_) };

declare 'RepeatedGetDeviceRegistryRequest',
    as ArrayRef[GetDeviceRegistryRequest()];

coerce 'RepeatedGetDeviceRegistryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::DeviceManager::GetDeviceRegistryRequest'->new($_) } @$_ ] };

declare 'MapStringGetDeviceRegistryRequest',
    as HashRef[GetDeviceRegistryRequest()];

declare 'DeleteDeviceRegistryRequest',
    as InstanceOf['Google::Cloud::Iot::V1::DeviceManager::DeleteDeviceRegistryRequest'];

coerce 'DeleteDeviceRegistryRequest',
    from HashRef, via { 'Google::Cloud::Iot::V1::DeviceManager::DeleteDeviceRegistryRequest'->new($_) };

declare 'RepeatedDeleteDeviceRegistryRequest',
    as ArrayRef[DeleteDeviceRegistryRequest()];

coerce 'RepeatedDeleteDeviceRegistryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::DeviceManager::DeleteDeviceRegistryRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDeviceRegistryRequest',
    as HashRef[DeleteDeviceRegistryRequest()];

declare 'UpdateDeviceRegistryRequest',
    as InstanceOf['Google::Cloud::Iot::V1::DeviceManager::UpdateDeviceRegistryRequest'];

coerce 'UpdateDeviceRegistryRequest',
    from HashRef, via { 'Google::Cloud::Iot::V1::DeviceManager::UpdateDeviceRegistryRequest'->new($_) };

declare 'RepeatedUpdateDeviceRegistryRequest',
    as ArrayRef[UpdateDeviceRegistryRequest()];

coerce 'RepeatedUpdateDeviceRegistryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::DeviceManager::UpdateDeviceRegistryRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDeviceRegistryRequest',
    as HashRef[UpdateDeviceRegistryRequest()];

declare 'ListDeviceRegistriesRequest',
    as InstanceOf['Google::Cloud::Iot::V1::DeviceManager::ListDeviceRegistriesRequest'];

coerce 'ListDeviceRegistriesRequest',
    from HashRef, via { 'Google::Cloud::Iot::V1::DeviceManager::ListDeviceRegistriesRequest'->new($_) };

declare 'RepeatedListDeviceRegistriesRequest',
    as ArrayRef[ListDeviceRegistriesRequest()];

coerce 'RepeatedListDeviceRegistriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::DeviceManager::ListDeviceRegistriesRequest'->new($_) } @$_ ] };

declare 'MapStringListDeviceRegistriesRequest',
    as HashRef[ListDeviceRegistriesRequest()];

declare 'ListDeviceRegistriesResponse',
    as InstanceOf['Google::Cloud::Iot::V1::DeviceManager::ListDeviceRegistriesResponse'];

coerce 'ListDeviceRegistriesResponse',
    from HashRef, via { 'Google::Cloud::Iot::V1::DeviceManager::ListDeviceRegistriesResponse'->new($_) };

declare 'RepeatedListDeviceRegistriesResponse',
    as ArrayRef[ListDeviceRegistriesResponse()];

coerce 'RepeatedListDeviceRegistriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::DeviceManager::ListDeviceRegistriesResponse'->new($_) } @$_ ] };

declare 'MapStringListDeviceRegistriesResponse',
    as HashRef[ListDeviceRegistriesResponse()];

declare 'CreateDeviceRequest',
    as InstanceOf['Google::Cloud::Iot::V1::DeviceManager::CreateDeviceRequest'];

coerce 'CreateDeviceRequest',
    from HashRef, via { 'Google::Cloud::Iot::V1::DeviceManager::CreateDeviceRequest'->new($_) };

declare 'RepeatedCreateDeviceRequest',
    as ArrayRef[CreateDeviceRequest()];

coerce 'RepeatedCreateDeviceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::DeviceManager::CreateDeviceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDeviceRequest',
    as HashRef[CreateDeviceRequest()];

declare 'GetDeviceRequest',
    as InstanceOf['Google::Cloud::Iot::V1::DeviceManager::GetDeviceRequest'];

coerce 'GetDeviceRequest',
    from HashRef, via { 'Google::Cloud::Iot::V1::DeviceManager::GetDeviceRequest'->new($_) };

declare 'RepeatedGetDeviceRequest',
    as ArrayRef[GetDeviceRequest()];

coerce 'RepeatedGetDeviceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::DeviceManager::GetDeviceRequest'->new($_) } @$_ ] };

declare 'MapStringGetDeviceRequest',
    as HashRef[GetDeviceRequest()];

declare 'UpdateDeviceRequest',
    as InstanceOf['Google::Cloud::Iot::V1::DeviceManager::UpdateDeviceRequest'];

coerce 'UpdateDeviceRequest',
    from HashRef, via { 'Google::Cloud::Iot::V1::DeviceManager::UpdateDeviceRequest'->new($_) };

declare 'RepeatedUpdateDeviceRequest',
    as ArrayRef[UpdateDeviceRequest()];

coerce 'RepeatedUpdateDeviceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::DeviceManager::UpdateDeviceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDeviceRequest',
    as HashRef[UpdateDeviceRequest()];

declare 'DeleteDeviceRequest',
    as InstanceOf['Google::Cloud::Iot::V1::DeviceManager::DeleteDeviceRequest'];

coerce 'DeleteDeviceRequest',
    from HashRef, via { 'Google::Cloud::Iot::V1::DeviceManager::DeleteDeviceRequest'->new($_) };

declare 'RepeatedDeleteDeviceRequest',
    as ArrayRef[DeleteDeviceRequest()];

coerce 'RepeatedDeleteDeviceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::DeviceManager::DeleteDeviceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDeviceRequest',
    as HashRef[DeleteDeviceRequest()];

declare 'ListDevicesRequest',
    as InstanceOf['Google::Cloud::Iot::V1::DeviceManager::ListDevicesRequest'];

coerce 'ListDevicesRequest',
    from HashRef, via { 'Google::Cloud::Iot::V1::DeviceManager::ListDevicesRequest'->new($_) };

declare 'RepeatedListDevicesRequest',
    as ArrayRef[ListDevicesRequest()];

coerce 'RepeatedListDevicesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::DeviceManager::ListDevicesRequest'->new($_) } @$_ ] };

declare 'MapStringListDevicesRequest',
    as HashRef[ListDevicesRequest()];

declare 'GatewayListOptions',
    as InstanceOf['Google::Cloud::Iot::V1::DeviceManager::GatewayListOptions'];

coerce 'GatewayListOptions',
    from HashRef, via { 'Google::Cloud::Iot::V1::DeviceManager::GatewayListOptions'->new($_) };

declare 'RepeatedGatewayListOptions',
    as ArrayRef[GatewayListOptions()];

coerce 'RepeatedGatewayListOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::DeviceManager::GatewayListOptions'->new($_) } @$_ ] };

declare 'MapStringGatewayListOptions',
    as HashRef[GatewayListOptions()];

declare 'ListDevicesResponse',
    as InstanceOf['Google::Cloud::Iot::V1::DeviceManager::ListDevicesResponse'];

coerce 'ListDevicesResponse',
    from HashRef, via { 'Google::Cloud::Iot::V1::DeviceManager::ListDevicesResponse'->new($_) };

declare 'RepeatedListDevicesResponse',
    as ArrayRef[ListDevicesResponse()];

coerce 'RepeatedListDevicesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::DeviceManager::ListDevicesResponse'->new($_) } @$_ ] };

declare 'MapStringListDevicesResponse',
    as HashRef[ListDevicesResponse()];

declare 'ModifyCloudToDeviceConfigRequest',
    as InstanceOf['Google::Cloud::Iot::V1::DeviceManager::ModifyCloudToDeviceConfigRequest'];

coerce 'ModifyCloudToDeviceConfigRequest',
    from HashRef, via { 'Google::Cloud::Iot::V1::DeviceManager::ModifyCloudToDeviceConfigRequest'->new($_) };

declare 'RepeatedModifyCloudToDeviceConfigRequest',
    as ArrayRef[ModifyCloudToDeviceConfigRequest()];

coerce 'RepeatedModifyCloudToDeviceConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::DeviceManager::ModifyCloudToDeviceConfigRequest'->new($_) } @$_ ] };

declare 'MapStringModifyCloudToDeviceConfigRequest',
    as HashRef[ModifyCloudToDeviceConfigRequest()];

declare 'ListDeviceConfigVersionsRequest',
    as InstanceOf['Google::Cloud::Iot::V1::DeviceManager::ListDeviceConfigVersionsRequest'];

coerce 'ListDeviceConfigVersionsRequest',
    from HashRef, via { 'Google::Cloud::Iot::V1::DeviceManager::ListDeviceConfigVersionsRequest'->new($_) };

declare 'RepeatedListDeviceConfigVersionsRequest',
    as ArrayRef[ListDeviceConfigVersionsRequest()];

coerce 'RepeatedListDeviceConfigVersionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::DeviceManager::ListDeviceConfigVersionsRequest'->new($_) } @$_ ] };

declare 'MapStringListDeviceConfigVersionsRequest',
    as HashRef[ListDeviceConfigVersionsRequest()];

declare 'ListDeviceConfigVersionsResponse',
    as InstanceOf['Google::Cloud::Iot::V1::DeviceManager::ListDeviceConfigVersionsResponse'];

coerce 'ListDeviceConfigVersionsResponse',
    from HashRef, via { 'Google::Cloud::Iot::V1::DeviceManager::ListDeviceConfigVersionsResponse'->new($_) };

declare 'RepeatedListDeviceConfigVersionsResponse',
    as ArrayRef[ListDeviceConfigVersionsResponse()];

coerce 'RepeatedListDeviceConfigVersionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::DeviceManager::ListDeviceConfigVersionsResponse'->new($_) } @$_ ] };

declare 'MapStringListDeviceConfigVersionsResponse',
    as HashRef[ListDeviceConfigVersionsResponse()];

declare 'ListDeviceStatesRequest',
    as InstanceOf['Google::Cloud::Iot::V1::DeviceManager::ListDeviceStatesRequest'];

coerce 'ListDeviceStatesRequest',
    from HashRef, via { 'Google::Cloud::Iot::V1::DeviceManager::ListDeviceStatesRequest'->new($_) };

declare 'RepeatedListDeviceStatesRequest',
    as ArrayRef[ListDeviceStatesRequest()];

coerce 'RepeatedListDeviceStatesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::DeviceManager::ListDeviceStatesRequest'->new($_) } @$_ ] };

declare 'MapStringListDeviceStatesRequest',
    as HashRef[ListDeviceStatesRequest()];

declare 'ListDeviceStatesResponse',
    as InstanceOf['Google::Cloud::Iot::V1::DeviceManager::ListDeviceStatesResponse'];

coerce 'ListDeviceStatesResponse',
    from HashRef, via { 'Google::Cloud::Iot::V1::DeviceManager::ListDeviceStatesResponse'->new($_) };

declare 'RepeatedListDeviceStatesResponse',
    as ArrayRef[ListDeviceStatesResponse()];

coerce 'RepeatedListDeviceStatesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::DeviceManager::ListDeviceStatesResponse'->new($_) } @$_ ] };

declare 'MapStringListDeviceStatesResponse',
    as HashRef[ListDeviceStatesResponse()];

declare 'SendCommandToDeviceRequest',
    as InstanceOf['Google::Cloud::Iot::V1::DeviceManager::SendCommandToDeviceRequest'];

coerce 'SendCommandToDeviceRequest',
    from HashRef, via { 'Google::Cloud::Iot::V1::DeviceManager::SendCommandToDeviceRequest'->new($_) };

declare 'RepeatedSendCommandToDeviceRequest',
    as ArrayRef[SendCommandToDeviceRequest()];

coerce 'RepeatedSendCommandToDeviceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::DeviceManager::SendCommandToDeviceRequest'->new($_) } @$_ ] };

declare 'MapStringSendCommandToDeviceRequest',
    as HashRef[SendCommandToDeviceRequest()];

declare 'SendCommandToDeviceResponse',
    as InstanceOf['Google::Cloud::Iot::V1::DeviceManager::SendCommandToDeviceResponse'];

coerce 'SendCommandToDeviceResponse',
    from HashRef, via { 'Google::Cloud::Iot::V1::DeviceManager::SendCommandToDeviceResponse'->new($_) };

declare 'RepeatedSendCommandToDeviceResponse',
    as ArrayRef[SendCommandToDeviceResponse()];

coerce 'RepeatedSendCommandToDeviceResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::DeviceManager::SendCommandToDeviceResponse'->new($_) } @$_ ] };

declare 'MapStringSendCommandToDeviceResponse',
    as HashRef[SendCommandToDeviceResponse()];

declare 'BindDeviceToGatewayRequest',
    as InstanceOf['Google::Cloud::Iot::V1::DeviceManager::BindDeviceToGatewayRequest'];

coerce 'BindDeviceToGatewayRequest',
    from HashRef, via { 'Google::Cloud::Iot::V1::DeviceManager::BindDeviceToGatewayRequest'->new($_) };

declare 'RepeatedBindDeviceToGatewayRequest',
    as ArrayRef[BindDeviceToGatewayRequest()];

coerce 'RepeatedBindDeviceToGatewayRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::DeviceManager::BindDeviceToGatewayRequest'->new($_) } @$_ ] };

declare 'MapStringBindDeviceToGatewayRequest',
    as HashRef[BindDeviceToGatewayRequest()];

declare 'BindDeviceToGatewayResponse',
    as InstanceOf['Google::Cloud::Iot::V1::DeviceManager::BindDeviceToGatewayResponse'];

coerce 'BindDeviceToGatewayResponse',
    from HashRef, via { 'Google::Cloud::Iot::V1::DeviceManager::BindDeviceToGatewayResponse'->new($_) };

declare 'RepeatedBindDeviceToGatewayResponse',
    as ArrayRef[BindDeviceToGatewayResponse()];

coerce 'RepeatedBindDeviceToGatewayResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::DeviceManager::BindDeviceToGatewayResponse'->new($_) } @$_ ] };

declare 'MapStringBindDeviceToGatewayResponse',
    as HashRef[BindDeviceToGatewayResponse()];

declare 'UnbindDeviceFromGatewayRequest',
    as InstanceOf['Google::Cloud::Iot::V1::DeviceManager::UnbindDeviceFromGatewayRequest'];

coerce 'UnbindDeviceFromGatewayRequest',
    from HashRef, via { 'Google::Cloud::Iot::V1::DeviceManager::UnbindDeviceFromGatewayRequest'->new($_) };

declare 'RepeatedUnbindDeviceFromGatewayRequest',
    as ArrayRef[UnbindDeviceFromGatewayRequest()];

coerce 'RepeatedUnbindDeviceFromGatewayRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::DeviceManager::UnbindDeviceFromGatewayRequest'->new($_) } @$_ ] };

declare 'MapStringUnbindDeviceFromGatewayRequest',
    as HashRef[UnbindDeviceFromGatewayRequest()];

declare 'UnbindDeviceFromGatewayResponse',
    as InstanceOf['Google::Cloud::Iot::V1::DeviceManager::UnbindDeviceFromGatewayResponse'];

coerce 'UnbindDeviceFromGatewayResponse',
    from HashRef, via { 'Google::Cloud::Iot::V1::DeviceManager::UnbindDeviceFromGatewayResponse'->new($_) };

declare 'RepeatedUnbindDeviceFromGatewayResponse',
    as ArrayRef[UnbindDeviceFromGatewayResponse()];

coerce 'RepeatedUnbindDeviceFromGatewayResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Iot::V1::DeviceManager::UnbindDeviceFromGatewayResponse'->new($_) } @$_ ] };

declare 'MapStringUnbindDeviceFromGatewayResponse',
    as HashRef[UnbindDeviceFromGatewayResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Iot::V1::DeviceManager::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
