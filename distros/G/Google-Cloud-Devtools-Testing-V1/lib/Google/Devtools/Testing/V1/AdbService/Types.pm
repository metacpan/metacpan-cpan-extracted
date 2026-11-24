package Google::Devtools::Testing::V1::AdbService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DeviceMessage',
    as InstanceOf['Google::Devtools::Testing::V1::AdbService::DeviceMessage'];

coerce 'DeviceMessage',
    from HashRef, via { 'Google::Devtools::Testing::V1::AdbService::DeviceMessage'->new($_) };

declare 'RepeatedDeviceMessage',
    as ArrayRef[DeviceMessage()];

coerce 'RepeatedDeviceMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::AdbService::DeviceMessage'->new($_) } @$_ ] };

declare 'MapStringDeviceMessage',
    as HashRef[DeviceMessage()];

declare 'AdbMessage',
    as InstanceOf['Google::Devtools::Testing::V1::AdbService::AdbMessage'];

coerce 'AdbMessage',
    from HashRef, via { 'Google::Devtools::Testing::V1::AdbService::AdbMessage'->new($_) };

declare 'RepeatedAdbMessage',
    as ArrayRef[AdbMessage()];

coerce 'RepeatedAdbMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::AdbService::AdbMessage'->new($_) } @$_ ] };

declare 'MapStringAdbMessage',
    as HashRef[AdbMessage()];

declare 'StatusUpdate',
    as InstanceOf['Google::Devtools::Testing::V1::AdbService::StatusUpdate'];

coerce 'StatusUpdate',
    from HashRef, via { 'Google::Devtools::Testing::V1::AdbService::StatusUpdate'->new($_) };

declare 'RepeatedStatusUpdate',
    as ArrayRef[StatusUpdate()];

coerce 'RepeatedStatusUpdate',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::AdbService::StatusUpdate'->new($_) } @$_ ] };

declare 'MapStringStatusUpdate',
    as HashRef[StatusUpdate()];

declare 'DeviceState',
    as (Int | Str);

declare 'PropertiesEntry',
    as InstanceOf['Google::Devtools::Testing::V1::AdbService::StatusUpdate::PropertiesEntry'];

coerce 'PropertiesEntry',
    from HashRef, via { 'Google::Devtools::Testing::V1::AdbService::StatusUpdate::PropertiesEntry'->new($_) };

declare 'RepeatedPropertiesEntry',
    as ArrayRef[PropertiesEntry()];

coerce 'RepeatedPropertiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::AdbService::StatusUpdate::PropertiesEntry'->new($_) } @$_ ] };

declare 'MapStringPropertiesEntry',
    as HashRef[PropertiesEntry()];

declare 'StreamStatus',
    as InstanceOf['Google::Devtools::Testing::V1::AdbService::StreamStatus'];

coerce 'StreamStatus',
    from HashRef, via { 'Google::Devtools::Testing::V1::AdbService::StreamStatus'->new($_) };

declare 'RepeatedStreamStatus',
    as ArrayRef[StreamStatus()];

coerce 'RepeatedStreamStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::AdbService::StreamStatus'->new($_) } @$_ ] };

declare 'MapStringStreamStatus',
    as HashRef[StreamStatus()];

declare 'Open',
    as InstanceOf['Google::Devtools::Testing::V1::AdbService::Open'];

coerce 'Open',
    from HashRef, via { 'Google::Devtools::Testing::V1::AdbService::Open'->new($_) };

declare 'RepeatedOpen',
    as ArrayRef[Open()];

coerce 'RepeatedOpen',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::AdbService::Open'->new($_) } @$_ ] };

declare 'MapStringOpen',
    as HashRef[Open()];

declare 'StreamData',
    as InstanceOf['Google::Devtools::Testing::V1::AdbService::StreamData'];

coerce 'StreamData',
    from HashRef, via { 'Google::Devtools::Testing::V1::AdbService::StreamData'->new($_) };

declare 'RepeatedStreamData',
    as ArrayRef[StreamData()];

coerce 'RepeatedStreamData',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::AdbService::StreamData'->new($_) } @$_ ] };

declare 'MapStringStreamData',
    as HashRef[StreamData()];

declare 'Okay',
    as InstanceOf['Google::Devtools::Testing::V1::AdbService::Okay'];

coerce 'Okay',
    from HashRef, via { 'Google::Devtools::Testing::V1::AdbService::Okay'->new($_) };

declare 'RepeatedOkay',
    as ArrayRef[Okay()];

coerce 'RepeatedOkay',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::AdbService::Okay'->new($_) } @$_ ] };

declare 'MapStringOkay',
    as HashRef[Okay()];

declare 'Fail',
    as InstanceOf['Google::Devtools::Testing::V1::AdbService::Fail'];

coerce 'Fail',
    from HashRef, via { 'Google::Devtools::Testing::V1::AdbService::Fail'->new($_) };

declare 'RepeatedFail',
    as ArrayRef[Fail()];

coerce 'RepeatedFail',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::AdbService::Fail'->new($_) } @$_ ] };

declare 'MapStringFail',
    as HashRef[Fail()];

declare 'Close',
    as InstanceOf['Google::Devtools::Testing::V1::AdbService::Close'];

coerce 'Close',
    from HashRef, via { 'Google::Devtools::Testing::V1::AdbService::Close'->new($_) };

declare 'RepeatedClose',
    as ArrayRef[Close()];

coerce 'RepeatedClose',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Testing::V1::AdbService::Close'->new($_) } @$_ ] };

declare 'MapStringClose',
    as HashRef[Close()];

1;

__END__

=head1 NAME

Google::Devtools::Testing::V1::AdbService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
