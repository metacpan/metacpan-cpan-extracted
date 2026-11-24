package Google::Cloud::Notebooks::V2::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Notebooks::V2::Service::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Notebooks::V2::Service::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V2::Service::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'ListInstancesRequest',
    as InstanceOf['Google::Cloud::Notebooks::V2::Service::ListInstancesRequest'];

coerce 'ListInstancesRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V2::Service::ListInstancesRequest'->new($_) };

declare 'RepeatedListInstancesRequest',
    as ArrayRef[ListInstancesRequest()];

coerce 'RepeatedListInstancesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V2::Service::ListInstancesRequest'->new($_) } @$_ ] };

declare 'MapStringListInstancesRequest',
    as HashRef[ListInstancesRequest()];

declare 'ListInstancesResponse',
    as InstanceOf['Google::Cloud::Notebooks::V2::Service::ListInstancesResponse'];

coerce 'ListInstancesResponse',
    from HashRef, via { 'Google::Cloud::Notebooks::V2::Service::ListInstancesResponse'->new($_) };

declare 'RepeatedListInstancesResponse',
    as ArrayRef[ListInstancesResponse()];

coerce 'RepeatedListInstancesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V2::Service::ListInstancesResponse'->new($_) } @$_ ] };

declare 'MapStringListInstancesResponse',
    as HashRef[ListInstancesResponse()];

declare 'GetInstanceRequest',
    as InstanceOf['Google::Cloud::Notebooks::V2::Service::GetInstanceRequest'];

coerce 'GetInstanceRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V2::Service::GetInstanceRequest'->new($_) };

declare 'RepeatedGetInstanceRequest',
    as ArrayRef[GetInstanceRequest()];

coerce 'RepeatedGetInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V2::Service::GetInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringGetInstanceRequest',
    as HashRef[GetInstanceRequest()];

declare 'CreateInstanceRequest',
    as InstanceOf['Google::Cloud::Notebooks::V2::Service::CreateInstanceRequest'];

coerce 'CreateInstanceRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V2::Service::CreateInstanceRequest'->new($_) };

declare 'RepeatedCreateInstanceRequest',
    as ArrayRef[CreateInstanceRequest()];

coerce 'RepeatedCreateInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V2::Service::CreateInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateInstanceRequest',
    as HashRef[CreateInstanceRequest()];

declare 'UpdateInstanceRequest',
    as InstanceOf['Google::Cloud::Notebooks::V2::Service::UpdateInstanceRequest'];

coerce 'UpdateInstanceRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V2::Service::UpdateInstanceRequest'->new($_) };

declare 'RepeatedUpdateInstanceRequest',
    as ArrayRef[UpdateInstanceRequest()];

coerce 'RepeatedUpdateInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V2::Service::UpdateInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateInstanceRequest',
    as HashRef[UpdateInstanceRequest()];

declare 'DeleteInstanceRequest',
    as InstanceOf['Google::Cloud::Notebooks::V2::Service::DeleteInstanceRequest'];

coerce 'DeleteInstanceRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V2::Service::DeleteInstanceRequest'->new($_) };

declare 'RepeatedDeleteInstanceRequest',
    as ArrayRef[DeleteInstanceRequest()];

coerce 'RepeatedDeleteInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V2::Service::DeleteInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteInstanceRequest',
    as HashRef[DeleteInstanceRequest()];

declare 'StartInstanceRequest',
    as InstanceOf['Google::Cloud::Notebooks::V2::Service::StartInstanceRequest'];

coerce 'StartInstanceRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V2::Service::StartInstanceRequest'->new($_) };

declare 'RepeatedStartInstanceRequest',
    as ArrayRef[StartInstanceRequest()];

coerce 'RepeatedStartInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V2::Service::StartInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringStartInstanceRequest',
    as HashRef[StartInstanceRequest()];

declare 'StopInstanceRequest',
    as InstanceOf['Google::Cloud::Notebooks::V2::Service::StopInstanceRequest'];

coerce 'StopInstanceRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V2::Service::StopInstanceRequest'->new($_) };

declare 'RepeatedStopInstanceRequest',
    as ArrayRef[StopInstanceRequest()];

coerce 'RepeatedStopInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V2::Service::StopInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringStopInstanceRequest',
    as HashRef[StopInstanceRequest()];

declare 'ResetInstanceRequest',
    as InstanceOf['Google::Cloud::Notebooks::V2::Service::ResetInstanceRequest'];

coerce 'ResetInstanceRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V2::Service::ResetInstanceRequest'->new($_) };

declare 'RepeatedResetInstanceRequest',
    as ArrayRef[ResetInstanceRequest()];

coerce 'RepeatedResetInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V2::Service::ResetInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringResetInstanceRequest',
    as HashRef[ResetInstanceRequest()];

declare 'CheckInstanceUpgradabilityRequest',
    as InstanceOf['Google::Cloud::Notebooks::V2::Service::CheckInstanceUpgradabilityRequest'];

coerce 'CheckInstanceUpgradabilityRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V2::Service::CheckInstanceUpgradabilityRequest'->new($_) };

declare 'RepeatedCheckInstanceUpgradabilityRequest',
    as ArrayRef[CheckInstanceUpgradabilityRequest()];

coerce 'RepeatedCheckInstanceUpgradabilityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V2::Service::CheckInstanceUpgradabilityRequest'->new($_) } @$_ ] };

declare 'MapStringCheckInstanceUpgradabilityRequest',
    as HashRef[CheckInstanceUpgradabilityRequest()];

declare 'CheckInstanceUpgradabilityResponse',
    as InstanceOf['Google::Cloud::Notebooks::V2::Service::CheckInstanceUpgradabilityResponse'];

coerce 'CheckInstanceUpgradabilityResponse',
    from HashRef, via { 'Google::Cloud::Notebooks::V2::Service::CheckInstanceUpgradabilityResponse'->new($_) };

declare 'RepeatedCheckInstanceUpgradabilityResponse',
    as ArrayRef[CheckInstanceUpgradabilityResponse()];

coerce 'RepeatedCheckInstanceUpgradabilityResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V2::Service::CheckInstanceUpgradabilityResponse'->new($_) } @$_ ] };

declare 'MapStringCheckInstanceUpgradabilityResponse',
    as HashRef[CheckInstanceUpgradabilityResponse()];

declare 'UpgradeInstanceRequest',
    as InstanceOf['Google::Cloud::Notebooks::V2::Service::UpgradeInstanceRequest'];

coerce 'UpgradeInstanceRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V2::Service::UpgradeInstanceRequest'->new($_) };

declare 'RepeatedUpgradeInstanceRequest',
    as ArrayRef[UpgradeInstanceRequest()];

coerce 'RepeatedUpgradeInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V2::Service::UpgradeInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringUpgradeInstanceRequest',
    as HashRef[UpgradeInstanceRequest()];

declare 'RollbackInstanceRequest',
    as InstanceOf['Google::Cloud::Notebooks::V2::Service::RollbackInstanceRequest'];

coerce 'RollbackInstanceRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V2::Service::RollbackInstanceRequest'->new($_) };

declare 'RepeatedRollbackInstanceRequest',
    as ArrayRef[RollbackInstanceRequest()];

coerce 'RepeatedRollbackInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V2::Service::RollbackInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringRollbackInstanceRequest',
    as HashRef[RollbackInstanceRequest()];

declare 'DiagnoseInstanceRequest',
    as InstanceOf['Google::Cloud::Notebooks::V2::Service::DiagnoseInstanceRequest'];

coerce 'DiagnoseInstanceRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V2::Service::DiagnoseInstanceRequest'->new($_) };

declare 'RepeatedDiagnoseInstanceRequest',
    as ArrayRef[DiagnoseInstanceRequest()];

coerce 'RepeatedDiagnoseInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V2::Service::DiagnoseInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringDiagnoseInstanceRequest',
    as HashRef[DiagnoseInstanceRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Notebooks::V2::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
