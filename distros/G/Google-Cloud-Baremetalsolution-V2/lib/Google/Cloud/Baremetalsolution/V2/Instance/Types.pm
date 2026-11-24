package Google::Cloud::Baremetalsolution::V2::Instance::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Instance',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Instance::Instance'];

coerce 'Instance',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Instance::Instance'->new($_) };

declare 'RepeatedInstance',
    as ArrayRef[Instance()];

coerce 'RepeatedInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Instance::Instance'->new($_) } @$_ ] };

declare 'MapStringInstance',
    as HashRef[Instance()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Instance::Instance::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Instance::Instance::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Instance::Instance::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'GetInstanceRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Instance::GetInstanceRequest'];

coerce 'GetInstanceRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Instance::GetInstanceRequest'->new($_) };

declare 'RepeatedGetInstanceRequest',
    as ArrayRef[GetInstanceRequest()];

coerce 'RepeatedGetInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Instance::GetInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringGetInstanceRequest',
    as HashRef[GetInstanceRequest()];

declare 'ListInstancesRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Instance::ListInstancesRequest'];

coerce 'ListInstancesRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Instance::ListInstancesRequest'->new($_) };

declare 'RepeatedListInstancesRequest',
    as ArrayRef[ListInstancesRequest()];

coerce 'RepeatedListInstancesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Instance::ListInstancesRequest'->new($_) } @$_ ] };

declare 'MapStringListInstancesRequest',
    as HashRef[ListInstancesRequest()];

declare 'ListInstancesResponse',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Instance::ListInstancesResponse'];

coerce 'ListInstancesResponse',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Instance::ListInstancesResponse'->new($_) };

declare 'RepeatedListInstancesResponse',
    as ArrayRef[ListInstancesResponse()];

coerce 'RepeatedListInstancesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Instance::ListInstancesResponse'->new($_) } @$_ ] };

declare 'MapStringListInstancesResponse',
    as HashRef[ListInstancesResponse()];

declare 'UpdateInstanceRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Instance::UpdateInstanceRequest'];

coerce 'UpdateInstanceRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Instance::UpdateInstanceRequest'->new($_) };

declare 'RepeatedUpdateInstanceRequest',
    as ArrayRef[UpdateInstanceRequest()];

coerce 'RepeatedUpdateInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Instance::UpdateInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateInstanceRequest',
    as HashRef[UpdateInstanceRequest()];

declare 'RenameInstanceRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Instance::RenameInstanceRequest'];

coerce 'RenameInstanceRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Instance::RenameInstanceRequest'->new($_) };

declare 'RepeatedRenameInstanceRequest',
    as ArrayRef[RenameInstanceRequest()];

coerce 'RepeatedRenameInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Instance::RenameInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringRenameInstanceRequest',
    as HashRef[RenameInstanceRequest()];

declare 'ResetInstanceRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Instance::ResetInstanceRequest'];

coerce 'ResetInstanceRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Instance::ResetInstanceRequest'->new($_) };

declare 'RepeatedResetInstanceRequest',
    as ArrayRef[ResetInstanceRequest()];

coerce 'RepeatedResetInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Instance::ResetInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringResetInstanceRequest',
    as HashRef[ResetInstanceRequest()];

declare 'StartInstanceRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Instance::StartInstanceRequest'];

coerce 'StartInstanceRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Instance::StartInstanceRequest'->new($_) };

declare 'RepeatedStartInstanceRequest',
    as ArrayRef[StartInstanceRequest()];

coerce 'RepeatedStartInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Instance::StartInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringStartInstanceRequest',
    as HashRef[StartInstanceRequest()];

declare 'StartInstanceResponse',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Instance::StartInstanceResponse'];

coerce 'StartInstanceResponse',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Instance::StartInstanceResponse'->new($_) };

declare 'RepeatedStartInstanceResponse',
    as ArrayRef[StartInstanceResponse()];

coerce 'RepeatedStartInstanceResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Instance::StartInstanceResponse'->new($_) } @$_ ] };

declare 'MapStringStartInstanceResponse',
    as HashRef[StartInstanceResponse()];

declare 'StopInstanceRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Instance::StopInstanceRequest'];

coerce 'StopInstanceRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Instance::StopInstanceRequest'->new($_) };

declare 'RepeatedStopInstanceRequest',
    as ArrayRef[StopInstanceRequest()];

coerce 'RepeatedStopInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Instance::StopInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringStopInstanceRequest',
    as HashRef[StopInstanceRequest()];

declare 'StopInstanceResponse',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Instance::StopInstanceResponse'];

coerce 'StopInstanceResponse',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Instance::StopInstanceResponse'->new($_) };

declare 'RepeatedStopInstanceResponse',
    as ArrayRef[StopInstanceResponse()];

coerce 'RepeatedStopInstanceResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Instance::StopInstanceResponse'->new($_) } @$_ ] };

declare 'MapStringStopInstanceResponse',
    as HashRef[StopInstanceResponse()];

declare 'EnableInteractiveSerialConsoleRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Instance::EnableInteractiveSerialConsoleRequest'];

coerce 'EnableInteractiveSerialConsoleRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Instance::EnableInteractiveSerialConsoleRequest'->new($_) };

declare 'RepeatedEnableInteractiveSerialConsoleRequest',
    as ArrayRef[EnableInteractiveSerialConsoleRequest()];

coerce 'RepeatedEnableInteractiveSerialConsoleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Instance::EnableInteractiveSerialConsoleRequest'->new($_) } @$_ ] };

declare 'MapStringEnableInteractiveSerialConsoleRequest',
    as HashRef[EnableInteractiveSerialConsoleRequest()];

declare 'EnableInteractiveSerialConsoleResponse',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Instance::EnableInteractiveSerialConsoleResponse'];

coerce 'EnableInteractiveSerialConsoleResponse',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Instance::EnableInteractiveSerialConsoleResponse'->new($_) };

declare 'RepeatedEnableInteractiveSerialConsoleResponse',
    as ArrayRef[EnableInteractiveSerialConsoleResponse()];

coerce 'RepeatedEnableInteractiveSerialConsoleResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Instance::EnableInteractiveSerialConsoleResponse'->new($_) } @$_ ] };

declare 'MapStringEnableInteractiveSerialConsoleResponse',
    as HashRef[EnableInteractiveSerialConsoleResponse()];

declare 'DisableInteractiveSerialConsoleRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Instance::DisableInteractiveSerialConsoleRequest'];

coerce 'DisableInteractiveSerialConsoleRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Instance::DisableInteractiveSerialConsoleRequest'->new($_) };

declare 'RepeatedDisableInteractiveSerialConsoleRequest',
    as ArrayRef[DisableInteractiveSerialConsoleRequest()];

coerce 'RepeatedDisableInteractiveSerialConsoleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Instance::DisableInteractiveSerialConsoleRequest'->new($_) } @$_ ] };

declare 'MapStringDisableInteractiveSerialConsoleRequest',
    as HashRef[DisableInteractiveSerialConsoleRequest()];

declare 'DisableInteractiveSerialConsoleResponse',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Instance::DisableInteractiveSerialConsoleResponse'];

coerce 'DisableInteractiveSerialConsoleResponse',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Instance::DisableInteractiveSerialConsoleResponse'->new($_) };

declare 'RepeatedDisableInteractiveSerialConsoleResponse',
    as ArrayRef[DisableInteractiveSerialConsoleResponse()];

coerce 'RepeatedDisableInteractiveSerialConsoleResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Instance::DisableInteractiveSerialConsoleResponse'->new($_) } @$_ ] };

declare 'MapStringDisableInteractiveSerialConsoleResponse',
    as HashRef[DisableInteractiveSerialConsoleResponse()];

declare 'DetachLunRequest',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Instance::DetachLunRequest'];

coerce 'DetachLunRequest',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Instance::DetachLunRequest'->new($_) };

declare 'RepeatedDetachLunRequest',
    as ArrayRef[DetachLunRequest()];

coerce 'RepeatedDetachLunRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Instance::DetachLunRequest'->new($_) } @$_ ] };

declare 'MapStringDetachLunRequest',
    as HashRef[DetachLunRequest()];

declare 'ServerNetworkTemplate',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Instance::ServerNetworkTemplate'];

coerce 'ServerNetworkTemplate',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Instance::ServerNetworkTemplate'->new($_) };

declare 'RepeatedServerNetworkTemplate',
    as ArrayRef[ServerNetworkTemplate()];

coerce 'RepeatedServerNetworkTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Instance::ServerNetworkTemplate'->new($_) } @$_ ] };

declare 'MapStringServerNetworkTemplate',
    as HashRef[ServerNetworkTemplate()];

declare 'LogicalInterface',
    as InstanceOf['Google::Cloud::Baremetalsolution::V2::Instance::ServerNetworkTemplate::LogicalInterface'];

coerce 'LogicalInterface',
    from HashRef, via { 'Google::Cloud::Baremetalsolution::V2::Instance::ServerNetworkTemplate::LogicalInterface'->new($_) };

declare 'RepeatedLogicalInterface',
    as ArrayRef[LogicalInterface()];

coerce 'RepeatedLogicalInterface',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Baremetalsolution::V2::Instance::ServerNetworkTemplate::LogicalInterface'->new($_) } @$_ ] };

declare 'MapStringLogicalInterface',
    as HashRef[LogicalInterface()];

declare 'InterfaceType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Baremetalsolution::V2::Instance::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
