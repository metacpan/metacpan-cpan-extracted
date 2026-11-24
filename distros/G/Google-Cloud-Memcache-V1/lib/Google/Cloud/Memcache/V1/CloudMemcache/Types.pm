package Google::Cloud::Memcache::V1::CloudMemcache::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'MemcacheVersion',
    as (Int | Str);

declare 'Instance',
    as InstanceOf['Google::Cloud::Memcache::V1::CloudMemcache::Instance'];

coerce 'Instance',
    from HashRef, via { 'Google::Cloud::Memcache::V1::CloudMemcache::Instance'->new($_) };

declare 'RepeatedInstance',
    as ArrayRef[Instance()];

coerce 'RepeatedInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memcache::V1::CloudMemcache::Instance'->new($_) } @$_ ] };

declare 'MapStringInstance',
    as HashRef[Instance()];

declare 'State',
    as (Int | Str);

declare 'NodeConfig',
    as InstanceOf['Google::Cloud::Memcache::V1::CloudMemcache::Instance::NodeConfig'];

coerce 'NodeConfig',
    from HashRef, via { 'Google::Cloud::Memcache::V1::CloudMemcache::Instance::NodeConfig'->new($_) };

declare 'RepeatedNodeConfig',
    as ArrayRef[NodeConfig()];

coerce 'RepeatedNodeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memcache::V1::CloudMemcache::Instance::NodeConfig'->new($_) } @$_ ] };

declare 'MapStringNodeConfig',
    as HashRef[NodeConfig()];

declare 'Node',
    as InstanceOf['Google::Cloud::Memcache::V1::CloudMemcache::Instance::Node'];

coerce 'Node',
    from HashRef, via { 'Google::Cloud::Memcache::V1::CloudMemcache::Instance::Node'->new($_) };

declare 'RepeatedNode',
    as ArrayRef[Node()];

coerce 'RepeatedNode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memcache::V1::CloudMemcache::Instance::Node'->new($_) } @$_ ] };

declare 'MapStringNode',
    as HashRef[Node()];

declare 'State',
    as (Int | Str);

declare 'InstanceMessage',
    as InstanceOf['Google::Cloud::Memcache::V1::CloudMemcache::Instance::InstanceMessage'];

coerce 'InstanceMessage',
    from HashRef, via { 'Google::Cloud::Memcache::V1::CloudMemcache::Instance::InstanceMessage'->new($_) };

declare 'RepeatedInstanceMessage',
    as ArrayRef[InstanceMessage()];

coerce 'RepeatedInstanceMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memcache::V1::CloudMemcache::Instance::InstanceMessage'->new($_) } @$_ ] };

declare 'MapStringInstanceMessage',
    as HashRef[InstanceMessage()];

declare 'Code',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Memcache::V1::CloudMemcache::Instance::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Memcache::V1::CloudMemcache::Instance::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memcache::V1::CloudMemcache::Instance::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'MaintenancePolicy',
    as InstanceOf['Google::Cloud::Memcache::V1::CloudMemcache::MaintenancePolicy'];

coerce 'MaintenancePolicy',
    from HashRef, via { 'Google::Cloud::Memcache::V1::CloudMemcache::MaintenancePolicy'->new($_) };

declare 'RepeatedMaintenancePolicy',
    as ArrayRef[MaintenancePolicy()];

coerce 'RepeatedMaintenancePolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memcache::V1::CloudMemcache::MaintenancePolicy'->new($_) } @$_ ] };

declare 'MapStringMaintenancePolicy',
    as HashRef[MaintenancePolicy()];

declare 'WeeklyMaintenanceWindow',
    as InstanceOf['Google::Cloud::Memcache::V1::CloudMemcache::WeeklyMaintenanceWindow'];

coerce 'WeeklyMaintenanceWindow',
    from HashRef, via { 'Google::Cloud::Memcache::V1::CloudMemcache::WeeklyMaintenanceWindow'->new($_) };

declare 'RepeatedWeeklyMaintenanceWindow',
    as ArrayRef[WeeklyMaintenanceWindow()];

coerce 'RepeatedWeeklyMaintenanceWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memcache::V1::CloudMemcache::WeeklyMaintenanceWindow'->new($_) } @$_ ] };

declare 'MapStringWeeklyMaintenanceWindow',
    as HashRef[WeeklyMaintenanceWindow()];

declare 'MaintenanceSchedule',
    as InstanceOf['Google::Cloud::Memcache::V1::CloudMemcache::MaintenanceSchedule'];

coerce 'MaintenanceSchedule',
    from HashRef, via { 'Google::Cloud::Memcache::V1::CloudMemcache::MaintenanceSchedule'->new($_) };

declare 'RepeatedMaintenanceSchedule',
    as ArrayRef[MaintenanceSchedule()];

coerce 'RepeatedMaintenanceSchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memcache::V1::CloudMemcache::MaintenanceSchedule'->new($_) } @$_ ] };

declare 'MapStringMaintenanceSchedule',
    as HashRef[MaintenanceSchedule()];

declare 'RescheduleMaintenanceRequest',
    as InstanceOf['Google::Cloud::Memcache::V1::CloudMemcache::RescheduleMaintenanceRequest'];

coerce 'RescheduleMaintenanceRequest',
    from HashRef, via { 'Google::Cloud::Memcache::V1::CloudMemcache::RescheduleMaintenanceRequest'->new($_) };

declare 'RepeatedRescheduleMaintenanceRequest',
    as ArrayRef[RescheduleMaintenanceRequest()];

coerce 'RepeatedRescheduleMaintenanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memcache::V1::CloudMemcache::RescheduleMaintenanceRequest'->new($_) } @$_ ] };

declare 'MapStringRescheduleMaintenanceRequest',
    as HashRef[RescheduleMaintenanceRequest()];

declare 'RescheduleType',
    as (Int | Str);

declare 'ListInstancesRequest',
    as InstanceOf['Google::Cloud::Memcache::V1::CloudMemcache::ListInstancesRequest'];

coerce 'ListInstancesRequest',
    from HashRef, via { 'Google::Cloud::Memcache::V1::CloudMemcache::ListInstancesRequest'->new($_) };

declare 'RepeatedListInstancesRequest',
    as ArrayRef[ListInstancesRequest()];

coerce 'RepeatedListInstancesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memcache::V1::CloudMemcache::ListInstancesRequest'->new($_) } @$_ ] };

declare 'MapStringListInstancesRequest',
    as HashRef[ListInstancesRequest()];

declare 'ListInstancesResponse',
    as InstanceOf['Google::Cloud::Memcache::V1::CloudMemcache::ListInstancesResponse'];

coerce 'ListInstancesResponse',
    from HashRef, via { 'Google::Cloud::Memcache::V1::CloudMemcache::ListInstancesResponse'->new($_) };

declare 'RepeatedListInstancesResponse',
    as ArrayRef[ListInstancesResponse()];

coerce 'RepeatedListInstancesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memcache::V1::CloudMemcache::ListInstancesResponse'->new($_) } @$_ ] };

declare 'MapStringListInstancesResponse',
    as HashRef[ListInstancesResponse()];

declare 'GetInstanceRequest',
    as InstanceOf['Google::Cloud::Memcache::V1::CloudMemcache::GetInstanceRequest'];

coerce 'GetInstanceRequest',
    from HashRef, via { 'Google::Cloud::Memcache::V1::CloudMemcache::GetInstanceRequest'->new($_) };

declare 'RepeatedGetInstanceRequest',
    as ArrayRef[GetInstanceRequest()];

coerce 'RepeatedGetInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memcache::V1::CloudMemcache::GetInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringGetInstanceRequest',
    as HashRef[GetInstanceRequest()];

declare 'CreateInstanceRequest',
    as InstanceOf['Google::Cloud::Memcache::V1::CloudMemcache::CreateInstanceRequest'];

coerce 'CreateInstanceRequest',
    from HashRef, via { 'Google::Cloud::Memcache::V1::CloudMemcache::CreateInstanceRequest'->new($_) };

declare 'RepeatedCreateInstanceRequest',
    as ArrayRef[CreateInstanceRequest()];

coerce 'RepeatedCreateInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memcache::V1::CloudMemcache::CreateInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateInstanceRequest',
    as HashRef[CreateInstanceRequest()];

declare 'UpdateInstanceRequest',
    as InstanceOf['Google::Cloud::Memcache::V1::CloudMemcache::UpdateInstanceRequest'];

coerce 'UpdateInstanceRequest',
    from HashRef, via { 'Google::Cloud::Memcache::V1::CloudMemcache::UpdateInstanceRequest'->new($_) };

declare 'RepeatedUpdateInstanceRequest',
    as ArrayRef[UpdateInstanceRequest()];

coerce 'RepeatedUpdateInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memcache::V1::CloudMemcache::UpdateInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateInstanceRequest',
    as HashRef[UpdateInstanceRequest()];

declare 'DeleteInstanceRequest',
    as InstanceOf['Google::Cloud::Memcache::V1::CloudMemcache::DeleteInstanceRequest'];

coerce 'DeleteInstanceRequest',
    from HashRef, via { 'Google::Cloud::Memcache::V1::CloudMemcache::DeleteInstanceRequest'->new($_) };

declare 'RepeatedDeleteInstanceRequest',
    as ArrayRef[DeleteInstanceRequest()];

coerce 'RepeatedDeleteInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memcache::V1::CloudMemcache::DeleteInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteInstanceRequest',
    as HashRef[DeleteInstanceRequest()];

declare 'ApplyParametersRequest',
    as InstanceOf['Google::Cloud::Memcache::V1::CloudMemcache::ApplyParametersRequest'];

coerce 'ApplyParametersRequest',
    from HashRef, via { 'Google::Cloud::Memcache::V1::CloudMemcache::ApplyParametersRequest'->new($_) };

declare 'RepeatedApplyParametersRequest',
    as ArrayRef[ApplyParametersRequest()];

coerce 'RepeatedApplyParametersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memcache::V1::CloudMemcache::ApplyParametersRequest'->new($_) } @$_ ] };

declare 'MapStringApplyParametersRequest',
    as HashRef[ApplyParametersRequest()];

declare 'UpdateParametersRequest',
    as InstanceOf['Google::Cloud::Memcache::V1::CloudMemcache::UpdateParametersRequest'];

coerce 'UpdateParametersRequest',
    from HashRef, via { 'Google::Cloud::Memcache::V1::CloudMemcache::UpdateParametersRequest'->new($_) };

declare 'RepeatedUpdateParametersRequest',
    as ArrayRef[UpdateParametersRequest()];

coerce 'RepeatedUpdateParametersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memcache::V1::CloudMemcache::UpdateParametersRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateParametersRequest',
    as HashRef[UpdateParametersRequest()];

declare 'MemcacheParameters',
    as InstanceOf['Google::Cloud::Memcache::V1::CloudMemcache::MemcacheParameters'];

coerce 'MemcacheParameters',
    from HashRef, via { 'Google::Cloud::Memcache::V1::CloudMemcache::MemcacheParameters'->new($_) };

declare 'RepeatedMemcacheParameters',
    as ArrayRef[MemcacheParameters()];

coerce 'RepeatedMemcacheParameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memcache::V1::CloudMemcache::MemcacheParameters'->new($_) } @$_ ] };

declare 'MapStringMemcacheParameters',
    as HashRef[MemcacheParameters()];

declare 'ParamsEntry',
    as InstanceOf['Google::Cloud::Memcache::V1::CloudMemcache::MemcacheParameters::ParamsEntry'];

coerce 'ParamsEntry',
    from HashRef, via { 'Google::Cloud::Memcache::V1::CloudMemcache::MemcacheParameters::ParamsEntry'->new($_) };

declare 'RepeatedParamsEntry',
    as ArrayRef[ParamsEntry()];

coerce 'RepeatedParamsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memcache::V1::CloudMemcache::MemcacheParameters::ParamsEntry'->new($_) } @$_ ] };

declare 'MapStringParamsEntry',
    as HashRef[ParamsEntry()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Memcache::V1::CloudMemcache::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Memcache::V1::CloudMemcache::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memcache::V1::CloudMemcache::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'LocationMetadata',
    as InstanceOf['Google::Cloud::Memcache::V1::CloudMemcache::LocationMetadata'];

coerce 'LocationMetadata',
    from HashRef, via { 'Google::Cloud::Memcache::V1::CloudMemcache::LocationMetadata'->new($_) };

declare 'RepeatedLocationMetadata',
    as ArrayRef[LocationMetadata()];

coerce 'RepeatedLocationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memcache::V1::CloudMemcache::LocationMetadata'->new($_) } @$_ ] };

declare 'MapStringLocationMetadata',
    as HashRef[LocationMetadata()];

declare 'AvailableZonesEntry',
    as InstanceOf['Google::Cloud::Memcache::V1::CloudMemcache::LocationMetadata::AvailableZonesEntry'];

coerce 'AvailableZonesEntry',
    from HashRef, via { 'Google::Cloud::Memcache::V1::CloudMemcache::LocationMetadata::AvailableZonesEntry'->new($_) };

declare 'RepeatedAvailableZonesEntry',
    as ArrayRef[AvailableZonesEntry()];

coerce 'RepeatedAvailableZonesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memcache::V1::CloudMemcache::LocationMetadata::AvailableZonesEntry'->new($_) } @$_ ] };

declare 'MapStringAvailableZonesEntry',
    as HashRef[AvailableZonesEntry()];

declare 'ZoneMetadata',
    as InstanceOf['Google::Cloud::Memcache::V1::CloudMemcache::ZoneMetadata'];

coerce 'ZoneMetadata',
    from HashRef, via { 'Google::Cloud::Memcache::V1::CloudMemcache::ZoneMetadata'->new($_) };

declare 'RepeatedZoneMetadata',
    as ArrayRef[ZoneMetadata()];

coerce 'RepeatedZoneMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Memcache::V1::CloudMemcache::ZoneMetadata'->new($_) } @$_ ] };

declare 'MapStringZoneMetadata',
    as HashRef[ZoneMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Memcache::V1::CloudMemcache::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
