package Google::Actions::Sdk::V2::ActionsTesting::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SendInteractionRequest',
    as InstanceOf['Google::Actions::Sdk::V2::ActionsTesting::SendInteractionRequest'];

coerce 'SendInteractionRequest',
    from HashRef, via { 'Google::Actions::Sdk::V2::ActionsTesting::SendInteractionRequest'->new($_) };

declare 'RepeatedSendInteractionRequest',
    as ArrayRef[SendInteractionRequest()];

coerce 'RepeatedSendInteractionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ActionsTesting::SendInteractionRequest'->new($_) } @$_ ] };

declare 'MapStringSendInteractionRequest',
    as HashRef[SendInteractionRequest()];

declare 'UserInput',
    as InstanceOf['Google::Actions::Sdk::V2::ActionsTesting::UserInput'];

coerce 'UserInput',
    from HashRef, via { 'Google::Actions::Sdk::V2::ActionsTesting::UserInput'->new($_) };

declare 'RepeatedUserInput',
    as ArrayRef[UserInput()];

coerce 'RepeatedUserInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ActionsTesting::UserInput'->new($_) } @$_ ] };

declare 'MapStringUserInput',
    as HashRef[UserInput()];

declare 'InputType',
    as (Int | Str);

declare 'DeviceProperties',
    as InstanceOf['Google::Actions::Sdk::V2::ActionsTesting::DeviceProperties'];

coerce 'DeviceProperties',
    from HashRef, via { 'Google::Actions::Sdk::V2::ActionsTesting::DeviceProperties'->new($_) };

declare 'RepeatedDeviceProperties',
    as ArrayRef[DeviceProperties()];

coerce 'RepeatedDeviceProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ActionsTesting::DeviceProperties'->new($_) } @$_ ] };

declare 'MapStringDeviceProperties',
    as HashRef[DeviceProperties()];

declare 'Surface',
    as (Int | Str);

declare 'Location',
    as InstanceOf['Google::Actions::Sdk::V2::ActionsTesting::Location'];

coerce 'Location',
    from HashRef, via { 'Google::Actions::Sdk::V2::ActionsTesting::Location'->new($_) };

declare 'RepeatedLocation',
    as ArrayRef[Location()];

coerce 'RepeatedLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ActionsTesting::Location'->new($_) } @$_ ] };

declare 'MapStringLocation',
    as HashRef[Location()];

declare 'SendInteractionResponse',
    as InstanceOf['Google::Actions::Sdk::V2::ActionsTesting::SendInteractionResponse'];

coerce 'SendInteractionResponse',
    from HashRef, via { 'Google::Actions::Sdk::V2::ActionsTesting::SendInteractionResponse'->new($_) };

declare 'RepeatedSendInteractionResponse',
    as ArrayRef[SendInteractionResponse()];

coerce 'RepeatedSendInteractionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ActionsTesting::SendInteractionResponse'->new($_) } @$_ ] };

declare 'MapStringSendInteractionResponse',
    as HashRef[SendInteractionResponse()];

declare 'Output',
    as InstanceOf['Google::Actions::Sdk::V2::ActionsTesting::Output'];

coerce 'Output',
    from HashRef, via { 'Google::Actions::Sdk::V2::ActionsTesting::Output'->new($_) };

declare 'RepeatedOutput',
    as ArrayRef[Output()];

coerce 'RepeatedOutput',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ActionsTesting::Output'->new($_) } @$_ ] };

declare 'MapStringOutput',
    as HashRef[Output()];

declare 'Diagnostics',
    as InstanceOf['Google::Actions::Sdk::V2::ActionsTesting::Diagnostics'];

coerce 'Diagnostics',
    from HashRef, via { 'Google::Actions::Sdk::V2::ActionsTesting::Diagnostics'->new($_) };

declare 'RepeatedDiagnostics',
    as ArrayRef[Diagnostics()];

coerce 'RepeatedDiagnostics',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ActionsTesting::Diagnostics'->new($_) } @$_ ] };

declare 'MapStringDiagnostics',
    as HashRef[Diagnostics()];

declare 'MatchIntentsRequest',
    as InstanceOf['Google::Actions::Sdk::V2::ActionsTesting::MatchIntentsRequest'];

coerce 'MatchIntentsRequest',
    from HashRef, via { 'Google::Actions::Sdk::V2::ActionsTesting::MatchIntentsRequest'->new($_) };

declare 'RepeatedMatchIntentsRequest',
    as ArrayRef[MatchIntentsRequest()];

coerce 'RepeatedMatchIntentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ActionsTesting::MatchIntentsRequest'->new($_) } @$_ ] };

declare 'MapStringMatchIntentsRequest',
    as HashRef[MatchIntentsRequest()];

declare 'MatchIntentsResponse',
    as InstanceOf['Google::Actions::Sdk::V2::ActionsTesting::MatchIntentsResponse'];

coerce 'MatchIntentsResponse',
    from HashRef, via { 'Google::Actions::Sdk::V2::ActionsTesting::MatchIntentsResponse'->new($_) };

declare 'RepeatedMatchIntentsResponse',
    as ArrayRef[MatchIntentsResponse()];

coerce 'RepeatedMatchIntentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ActionsTesting::MatchIntentsResponse'->new($_) } @$_ ] };

declare 'MapStringMatchIntentsResponse',
    as HashRef[MatchIntentsResponse()];

declare 'SetWebAndAppActivityControlRequest',
    as InstanceOf['Google::Actions::Sdk::V2::ActionsTesting::SetWebAndAppActivityControlRequest'];

coerce 'SetWebAndAppActivityControlRequest',
    from HashRef, via { 'Google::Actions::Sdk::V2::ActionsTesting::SetWebAndAppActivityControlRequest'->new($_) };

declare 'RepeatedSetWebAndAppActivityControlRequest',
    as ArrayRef[SetWebAndAppActivityControlRequest()];

coerce 'RepeatedSetWebAndAppActivityControlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::ActionsTesting::SetWebAndAppActivityControlRequest'->new($_) } @$_ ] };

declare 'MapStringSetWebAndAppActivityControlRequest',
    as HashRef[SetWebAndAppActivityControlRequest()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::ActionsTesting::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
