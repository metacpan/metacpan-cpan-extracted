package Google::Devtools::Testing::V1::DirectAccessService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateDeviceSessionRequest',
    as InstanceOf['Google::Devtools::Testing::V1::DirectAccessService::CreateDeviceSessionRequest'];

coerce 'CreateDeviceSessionRequest',
    from HashRef, via { 'Google::Devtools::Testing::V1::DirectAccessService::CreateDeviceSessionRequest'->new($_) };

declare 'RepeatedCreateDeviceSessionRequest',
    as ArrayRef[CreateDeviceSessionRequest()];

coerce 'RepeatedCreateDeviceSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::DirectAccessService::CreateDeviceSessionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDeviceSessionRequest',
    as HashRef[CreateDeviceSessionRequest()];

declare 'ListDeviceSessionsRequest',
    as InstanceOf['Google::Devtools::Testing::V1::DirectAccessService::ListDeviceSessionsRequest'];

coerce 'ListDeviceSessionsRequest',
    from HashRef, via { 'Google::Devtools::Testing::V1::DirectAccessService::ListDeviceSessionsRequest'->new($_) };

declare 'RepeatedListDeviceSessionsRequest',
    as ArrayRef[ListDeviceSessionsRequest()];

coerce 'RepeatedListDeviceSessionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::DirectAccessService::ListDeviceSessionsRequest'->new($_) } @$_ ] };

declare 'MapStringListDeviceSessionsRequest',
    as HashRef[ListDeviceSessionsRequest()];

declare 'ListDeviceSessionsResponse',
    as InstanceOf['Google::Devtools::Testing::V1::DirectAccessService::ListDeviceSessionsResponse'];

coerce 'ListDeviceSessionsResponse',
    from HashRef, via { 'Google::Devtools::Testing::V1::DirectAccessService::ListDeviceSessionsResponse'->new($_) };

declare 'RepeatedListDeviceSessionsResponse',
    as ArrayRef[ListDeviceSessionsResponse()];

coerce 'RepeatedListDeviceSessionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::DirectAccessService::ListDeviceSessionsResponse'->new($_) } @$_ ] };

declare 'MapStringListDeviceSessionsResponse',
    as HashRef[ListDeviceSessionsResponse()];

declare 'GetDeviceSessionRequest',
    as InstanceOf['Google::Devtools::Testing::V1::DirectAccessService::GetDeviceSessionRequest'];

coerce 'GetDeviceSessionRequest',
    from HashRef, via { 'Google::Devtools::Testing::V1::DirectAccessService::GetDeviceSessionRequest'->new($_) };

declare 'RepeatedGetDeviceSessionRequest',
    as ArrayRef[GetDeviceSessionRequest()];

coerce 'RepeatedGetDeviceSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::DirectAccessService::GetDeviceSessionRequest'->new($_) } @$_ ] };

declare 'MapStringGetDeviceSessionRequest',
    as HashRef[GetDeviceSessionRequest()];

declare 'CancelDeviceSessionRequest',
    as InstanceOf['Google::Devtools::Testing::V1::DirectAccessService::CancelDeviceSessionRequest'];

coerce 'CancelDeviceSessionRequest',
    from HashRef, via { 'Google::Devtools::Testing::V1::DirectAccessService::CancelDeviceSessionRequest'->new($_) };

declare 'RepeatedCancelDeviceSessionRequest',
    as ArrayRef[CancelDeviceSessionRequest()];

coerce 'RepeatedCancelDeviceSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::DirectAccessService::CancelDeviceSessionRequest'->new($_) } @$_ ] };

declare 'MapStringCancelDeviceSessionRequest',
    as HashRef[CancelDeviceSessionRequest()];

declare 'UpdateDeviceSessionRequest',
    as InstanceOf['Google::Devtools::Testing::V1::DirectAccessService::UpdateDeviceSessionRequest'];

coerce 'UpdateDeviceSessionRequest',
    from HashRef, via { 'Google::Devtools::Testing::V1::DirectAccessService::UpdateDeviceSessionRequest'->new($_) };

declare 'RepeatedUpdateDeviceSessionRequest',
    as ArrayRef[UpdateDeviceSessionRequest()];

coerce 'RepeatedUpdateDeviceSessionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::DirectAccessService::UpdateDeviceSessionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDeviceSessionRequest',
    as HashRef[UpdateDeviceSessionRequest()];

declare 'DeviceSession',
    as InstanceOf['Google::Devtools::Testing::V1::DirectAccessService::DeviceSession'];

coerce 'DeviceSession',
    from HashRef, via { 'Google::Devtools::Testing::V1::DirectAccessService::DeviceSession'->new($_) };

declare 'RepeatedDeviceSession',
    as ArrayRef[DeviceSession()];

coerce 'RepeatedDeviceSession',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::DirectAccessService::DeviceSession'->new($_) } @$_ ] };

declare 'MapStringDeviceSession',
    as HashRef[DeviceSession()];

declare 'SessionState',
    as (Int | Str);

declare 'SessionStateEvent',
    as InstanceOf['Google::Devtools::Testing::V1::DirectAccessService::DeviceSession::SessionStateEvent'];

coerce 'SessionStateEvent',
    from HashRef, via { 'Google::Devtools::Testing::V1::DirectAccessService::DeviceSession::SessionStateEvent'->new($_) };

declare 'RepeatedSessionStateEvent',
    as ArrayRef[SessionStateEvent()];

coerce 'RepeatedSessionStateEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::DirectAccessService::DeviceSession::SessionStateEvent'->new($_) } @$_ ] };

declare 'MapStringSessionStateEvent',
    as HashRef[SessionStateEvent()];

1;

__END__

=head1 NAME

Google::Devtools::Testing::V1::DirectAccessService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
