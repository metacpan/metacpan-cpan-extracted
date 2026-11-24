package Google::Cloud::Devicestreaming::V1::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateDeviceSessionRequest',
    as InstanceOf['Google::Cloud::Devicestreaming::V1::Service::CreateDeviceSessionRequest'];

coerce 'CreateDeviceSessionRequest',
    from HashRef, via { 'Google::Cloud::Devicestreaming::V1::Service::CreateDeviceSessionRequest'->new($_) };

declare 'RepeatedCreateDeviceSessionRequest',
    as ArrayRef[CreateDeviceSessionRequest()];

coerce 'RepeatedCreateDeviceSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Devicestreaming::V1::Service::CreateDeviceSessionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDeviceSessionRequest',
    as HashRef[CreateDeviceSessionRequest()];

declare 'ListDeviceSessionsRequest',
    as InstanceOf['Google::Cloud::Devicestreaming::V1::Service::ListDeviceSessionsRequest'];

coerce 'ListDeviceSessionsRequest',
    from HashRef, via { 'Google::Cloud::Devicestreaming::V1::Service::ListDeviceSessionsRequest'->new($_) };

declare 'RepeatedListDeviceSessionsRequest',
    as ArrayRef[ListDeviceSessionsRequest()];

coerce 'RepeatedListDeviceSessionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Devicestreaming::V1::Service::ListDeviceSessionsRequest'->new($_) } @$_ ] };

declare 'MapStringListDeviceSessionsRequest',
    as HashRef[ListDeviceSessionsRequest()];

declare 'ListDeviceSessionsResponse',
    as InstanceOf['Google::Cloud::Devicestreaming::V1::Service::ListDeviceSessionsResponse'];

coerce 'ListDeviceSessionsResponse',
    from HashRef, via { 'Google::Cloud::Devicestreaming::V1::Service::ListDeviceSessionsResponse'->new($_) };

declare 'RepeatedListDeviceSessionsResponse',
    as ArrayRef[ListDeviceSessionsResponse()];

coerce 'RepeatedListDeviceSessionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Devicestreaming::V1::Service::ListDeviceSessionsResponse'->new($_) } @$_ ] };

declare 'MapStringListDeviceSessionsResponse',
    as HashRef[ListDeviceSessionsResponse()];

declare 'GetDeviceSessionRequest',
    as InstanceOf['Google::Cloud::Devicestreaming::V1::Service::GetDeviceSessionRequest'];

coerce 'GetDeviceSessionRequest',
    from HashRef, via { 'Google::Cloud::Devicestreaming::V1::Service::GetDeviceSessionRequest'->new($_) };

declare 'RepeatedGetDeviceSessionRequest',
    as ArrayRef[GetDeviceSessionRequest()];

coerce 'RepeatedGetDeviceSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Devicestreaming::V1::Service::GetDeviceSessionRequest'->new($_) } @$_ ] };

declare 'MapStringGetDeviceSessionRequest',
    as HashRef[GetDeviceSessionRequest()];

declare 'CancelDeviceSessionRequest',
    as InstanceOf['Google::Cloud::Devicestreaming::V1::Service::CancelDeviceSessionRequest'];

coerce 'CancelDeviceSessionRequest',
    from HashRef, via { 'Google::Cloud::Devicestreaming::V1::Service::CancelDeviceSessionRequest'->new($_) };

declare 'RepeatedCancelDeviceSessionRequest',
    as ArrayRef[CancelDeviceSessionRequest()];

coerce 'RepeatedCancelDeviceSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Devicestreaming::V1::Service::CancelDeviceSessionRequest'->new($_) } @$_ ] };

declare 'MapStringCancelDeviceSessionRequest',
    as HashRef[CancelDeviceSessionRequest()];

declare 'UpdateDeviceSessionRequest',
    as InstanceOf['Google::Cloud::Devicestreaming::V1::Service::UpdateDeviceSessionRequest'];

coerce 'UpdateDeviceSessionRequest',
    from HashRef, via { 'Google::Cloud::Devicestreaming::V1::Service::UpdateDeviceSessionRequest'->new($_) };

declare 'RepeatedUpdateDeviceSessionRequest',
    as ArrayRef[UpdateDeviceSessionRequest()];

coerce 'RepeatedUpdateDeviceSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Devicestreaming::V1::Service::UpdateDeviceSessionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDeviceSessionRequest',
    as HashRef[UpdateDeviceSessionRequest()];

declare 'DeviceSession',
    as InstanceOf['Google::Cloud::Devicestreaming::V1::Service::DeviceSession'];

coerce 'DeviceSession',
    from HashRef, via { 'Google::Cloud::Devicestreaming::V1::Service::DeviceSession'->new($_) };

declare 'RepeatedDeviceSession',
    as ArrayRef[DeviceSession()];

coerce 'RepeatedDeviceSession',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Devicestreaming::V1::Service::DeviceSession'->new($_) } @$_ ] };

declare 'MapStringDeviceSession',
    as HashRef[DeviceSession()];

declare 'SessionState',
    as (Int | Str);

declare 'SessionStateEvent',
    as InstanceOf['Google::Cloud::Devicestreaming::V1::Service::DeviceSession::SessionStateEvent'];

coerce 'SessionStateEvent',
    from HashRef, via { 'Google::Cloud::Devicestreaming::V1::Service::DeviceSession::SessionStateEvent'->new($_) };

declare 'RepeatedSessionStateEvent',
    as ArrayRef[SessionStateEvent()];

coerce 'RepeatedSessionStateEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Devicestreaming::V1::Service::DeviceSession::SessionStateEvent'->new($_) } @$_ ] };

declare 'MapStringSessionStateEvent',
    as HashRef[SessionStateEvent()];

declare 'ClientInfo',
    as InstanceOf['Google::Cloud::Devicestreaming::V1::Service::ClientInfo'];

coerce 'ClientInfo',
    from HashRef, via { 'Google::Cloud::Devicestreaming::V1::Service::ClientInfo'->new($_) };

declare 'RepeatedClientInfo',
    as ArrayRef[ClientInfo()];

coerce 'RepeatedClientInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Devicestreaming::V1::Service::ClientInfo'->new($_) } @$_ ] };

declare 'MapStringClientInfo',
    as HashRef[ClientInfo()];

declare 'AndroidDevice',
    as InstanceOf['Google::Cloud::Devicestreaming::V1::Service::AndroidDevice'];

coerce 'AndroidDevice',
    from HashRef, via { 'Google::Cloud::Devicestreaming::V1::Service::AndroidDevice'->new($_) };

declare 'RepeatedAndroidDevice',
    as ArrayRef[AndroidDevice()];

coerce 'RepeatedAndroidDevice',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Devicestreaming::V1::Service::AndroidDevice'->new($_) } @$_ ] };

declare 'MapStringAndroidDevice',
    as HashRef[AndroidDevice()];

1;

__END__

=head1 NAME

Google::Cloud::Devicestreaming::V1::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
