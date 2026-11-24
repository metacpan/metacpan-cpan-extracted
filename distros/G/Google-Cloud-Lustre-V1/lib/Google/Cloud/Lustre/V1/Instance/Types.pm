package Google::Cloud::Lustre::V1::Instance::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Instance',
    as InstanceOf['Google::Cloud::Lustre::V1::Instance::Instance'];

coerce 'Instance',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Instance::Instance'->new($_) };

declare 'RepeatedInstance',
    as ArrayRef[Instance()];

coerce 'RepeatedInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Instance::Instance'->new($_) } @$_ ] };

declare 'MapStringInstance',
    as HashRef[Instance()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Lustre::V1::Instance::Instance::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Instance::Instance::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Instance::Instance::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'DynamicTierOptions',
    as InstanceOf['Google::Cloud::Lustre::V1::Instance::DynamicTierOptions'];

coerce 'DynamicTierOptions',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Instance::DynamicTierOptions'->new($_) };

declare 'RepeatedDynamicTierOptions',
    as ArrayRef[DynamicTierOptions()];

coerce 'RepeatedDynamicTierOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Instance::DynamicTierOptions'->new($_) } @$_ ] };

declare 'MapStringDynamicTierOptions',
    as HashRef[DynamicTierOptions()];

declare 'Mode',
    as (Int | Str);

declare 'AccessRulesOptions',
    as InstanceOf['Google::Cloud::Lustre::V1::Instance::AccessRulesOptions'];

coerce 'AccessRulesOptions',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Instance::AccessRulesOptions'->new($_) };

declare 'RepeatedAccessRulesOptions',
    as ArrayRef[AccessRulesOptions()];

coerce 'RepeatedAccessRulesOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Instance::AccessRulesOptions'->new($_) } @$_ ] };

declare 'MapStringAccessRulesOptions',
    as HashRef[AccessRulesOptions()];

declare 'SquashMode',
    as (Int | Str);

declare 'AccessRule',
    as InstanceOf['Google::Cloud::Lustre::V1::Instance::AccessRulesOptions::AccessRule'];

coerce 'AccessRule',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Instance::AccessRulesOptions::AccessRule'->new($_) };

declare 'RepeatedAccessRule',
    as ArrayRef[AccessRule()];

coerce 'RepeatedAccessRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Instance::AccessRulesOptions::AccessRule'->new($_) } @$_ ] };

declare 'MapStringAccessRule',
    as HashRef[AccessRule()];

declare 'ListInstancesRequest',
    as InstanceOf['Google::Cloud::Lustre::V1::Instance::ListInstancesRequest'];

coerce 'ListInstancesRequest',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Instance::ListInstancesRequest'->new($_) };

declare 'RepeatedListInstancesRequest',
    as ArrayRef[ListInstancesRequest()];

coerce 'RepeatedListInstancesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Instance::ListInstancesRequest'->new($_) } @$_ ] };

declare 'MapStringListInstancesRequest',
    as HashRef[ListInstancesRequest()];

declare 'ListInstancesResponse',
    as InstanceOf['Google::Cloud::Lustre::V1::Instance::ListInstancesResponse'];

coerce 'ListInstancesResponse',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Instance::ListInstancesResponse'->new($_) };

declare 'RepeatedListInstancesResponse',
    as ArrayRef[ListInstancesResponse()];

coerce 'RepeatedListInstancesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Instance::ListInstancesResponse'->new($_) } @$_ ] };

declare 'MapStringListInstancesResponse',
    as HashRef[ListInstancesResponse()];

declare 'GetInstanceRequest',
    as InstanceOf['Google::Cloud::Lustre::V1::Instance::GetInstanceRequest'];

coerce 'GetInstanceRequest',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Instance::GetInstanceRequest'->new($_) };

declare 'RepeatedGetInstanceRequest',
    as ArrayRef[GetInstanceRequest()];

coerce 'RepeatedGetInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Instance::GetInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringGetInstanceRequest',
    as HashRef[GetInstanceRequest()];

declare 'CreateInstanceRequest',
    as InstanceOf['Google::Cloud::Lustre::V1::Instance::CreateInstanceRequest'];

coerce 'CreateInstanceRequest',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Instance::CreateInstanceRequest'->new($_) };

declare 'RepeatedCreateInstanceRequest',
    as ArrayRef[CreateInstanceRequest()];

coerce 'RepeatedCreateInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Instance::CreateInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateInstanceRequest',
    as HashRef[CreateInstanceRequest()];

declare 'UpdateInstanceRequest',
    as InstanceOf['Google::Cloud::Lustre::V1::Instance::UpdateInstanceRequest'];

coerce 'UpdateInstanceRequest',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Instance::UpdateInstanceRequest'->new($_) };

declare 'RepeatedUpdateInstanceRequest',
    as ArrayRef[UpdateInstanceRequest()];

coerce 'RepeatedUpdateInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Instance::UpdateInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateInstanceRequest',
    as HashRef[UpdateInstanceRequest()];

declare 'DeleteInstanceRequest',
    as InstanceOf['Google::Cloud::Lustre::V1::Instance::DeleteInstanceRequest'];

coerce 'DeleteInstanceRequest',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Instance::DeleteInstanceRequest'->new($_) };

declare 'RepeatedDeleteInstanceRequest',
    as ArrayRef[DeleteInstanceRequest()];

coerce 'RepeatedDeleteInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Instance::DeleteInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteInstanceRequest',
    as HashRef[DeleteInstanceRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Lustre::V1::Instance::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Instance::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Instance::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'MaintenancePolicy',
    as InstanceOf['Google::Cloud::Lustre::V1::Instance::MaintenancePolicy'];

coerce 'MaintenancePolicy',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Instance::MaintenancePolicy'->new($_) };

declare 'RepeatedMaintenancePolicy',
    as ArrayRef[MaintenancePolicy()];

coerce 'RepeatedMaintenancePolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Instance::MaintenancePolicy'->new($_) } @$_ ] };

declare 'MapStringMaintenancePolicy',
    as HashRef[MaintenancePolicy()];

declare 'WeeklyMaintenanceWindow',
    as InstanceOf['Google::Cloud::Lustre::V1::Instance::MaintenancePolicy::WeeklyMaintenanceWindow'];

coerce 'WeeklyMaintenanceWindow',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Instance::MaintenancePolicy::WeeklyMaintenanceWindow'->new($_) };

declare 'RepeatedWeeklyMaintenanceWindow',
    as ArrayRef[WeeklyMaintenanceWindow()];

coerce 'RepeatedWeeklyMaintenanceWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Instance::MaintenancePolicy::WeeklyMaintenanceWindow'->new($_) } @$_ ] };

declare 'MapStringWeeklyMaintenanceWindow',
    as HashRef[WeeklyMaintenanceWindow()];

declare 'MaintenanceExclusionWindow',
    as InstanceOf['Google::Cloud::Lustre::V1::Instance::MaintenancePolicy::MaintenanceExclusionWindow'];

coerce 'MaintenanceExclusionWindow',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Instance::MaintenancePolicy::MaintenanceExclusionWindow'->new($_) };

declare 'RepeatedMaintenanceExclusionWindow',
    as ArrayRef[MaintenanceExclusionWindow()];

coerce 'RepeatedMaintenanceExclusionWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Instance::MaintenancePolicy::MaintenanceExclusionWindow'->new($_) } @$_ ] };

declare 'MapStringMaintenanceExclusionWindow',
    as HashRef[MaintenanceExclusionWindow()];

declare 'MaintenanceSchedule',
    as InstanceOf['Google::Cloud::Lustre::V1::Instance::MaintenanceSchedule'];

coerce 'MaintenanceSchedule',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Instance::MaintenanceSchedule'->new($_) };

declare 'RepeatedMaintenanceSchedule',
    as ArrayRef[MaintenanceSchedule()];

coerce 'RepeatedMaintenanceSchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Instance::MaintenanceSchedule'->new($_) } @$_ ] };

declare 'MapStringMaintenanceSchedule',
    as HashRef[MaintenanceSchedule()];

declare 'RescheduleMaintenanceRequest',
    as InstanceOf['Google::Cloud::Lustre::V1::Instance::RescheduleMaintenanceRequest'];

coerce 'RescheduleMaintenanceRequest',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Instance::RescheduleMaintenanceRequest'->new($_) };

declare 'RepeatedRescheduleMaintenanceRequest',
    as ArrayRef[RescheduleMaintenanceRequest()];

coerce 'RepeatedRescheduleMaintenanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Instance::RescheduleMaintenanceRequest'->new($_) } @$_ ] };

declare 'MapStringRescheduleMaintenanceRequest',
    as HashRef[RescheduleMaintenanceRequest()];

declare 'RescheduleType',
    as (Int | Str);

declare 'Reschedule',
    as InstanceOf['Google::Cloud::Lustre::V1::Instance::RescheduleMaintenanceRequest::Reschedule'];

coerce 'Reschedule',
    from HashRef, via { 'Google::Cloud::Lustre::V1::Instance::RescheduleMaintenanceRequest::Reschedule'->new($_) };

declare 'RepeatedReschedule',
    as ArrayRef[Reschedule()];

coerce 'RepeatedReschedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Lustre::V1::Instance::RescheduleMaintenanceRequest::Reschedule'->new($_) } @$_ ] };

declare 'MapStringReschedule',
    as HashRef[Reschedule()];

1;

__END__

=head1 NAME

Google::Cloud::Lustre::V1::Instance::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
