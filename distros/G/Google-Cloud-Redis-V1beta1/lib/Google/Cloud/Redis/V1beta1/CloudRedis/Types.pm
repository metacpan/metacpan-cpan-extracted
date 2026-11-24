package Google::Cloud::Redis::V1beta1::CloudRedis::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'NodeInfo',
    as InstanceOf['Google::Cloud::Redis::V1beta1::CloudRedis::NodeInfo'];

coerce 'NodeInfo',
    from HashRef, via { 'Google::Cloud::Redis::V1beta1::CloudRedis::NodeInfo'->new($_) };

declare 'RepeatedNodeInfo',
    as ArrayRef[NodeInfo()];

coerce 'RepeatedNodeInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::V1beta1::CloudRedis::NodeInfo'->new($_) } @$_ ] };

declare 'MapStringNodeInfo',
    as HashRef[NodeInfo()];

declare 'Instance',
    as InstanceOf['Google::Cloud::Redis::V1beta1::CloudRedis::Instance'];

coerce 'Instance',
    from HashRef, via { 'Google::Cloud::Redis::V1beta1::CloudRedis::Instance'->new($_) };

declare 'RepeatedInstance',
    as ArrayRef[Instance()];

coerce 'RepeatedInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::V1beta1::CloudRedis::Instance'->new($_) } @$_ ] };

declare 'MapStringInstance',
    as HashRef[Instance()];

declare 'State',
    as (Int | Str);

declare 'Tier',
    as (Int | Str);

declare 'ConnectMode',
    as (Int | Str);

declare 'TransitEncryptionMode',
    as (Int | Str);

declare 'ReadReplicasMode',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Redis::V1beta1::CloudRedis::Instance::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Redis::V1beta1::CloudRedis::Instance::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::V1beta1::CloudRedis::Instance::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'RedisConfigsEntry',
    as InstanceOf['Google::Cloud::Redis::V1beta1::CloudRedis::Instance::RedisConfigsEntry'];

coerce 'RedisConfigsEntry',
    from HashRef, via { 'Google::Cloud::Redis::V1beta1::CloudRedis::Instance::RedisConfigsEntry'->new($_) };

declare 'RepeatedRedisConfigsEntry',
    as ArrayRef[RedisConfigsEntry()];

coerce 'RepeatedRedisConfigsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::V1beta1::CloudRedis::Instance::RedisConfigsEntry'->new($_) } @$_ ] };

declare 'MapStringRedisConfigsEntry',
    as HashRef[RedisConfigsEntry()];

declare 'PersistenceConfig',
    as InstanceOf['Google::Cloud::Redis::V1beta1::CloudRedis::PersistenceConfig'];

coerce 'PersistenceConfig',
    from HashRef, via { 'Google::Cloud::Redis::V1beta1::CloudRedis::PersistenceConfig'->new($_) };

declare 'RepeatedPersistenceConfig',
    as ArrayRef[PersistenceConfig()];

coerce 'RepeatedPersistenceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::V1beta1::CloudRedis::PersistenceConfig'->new($_) } @$_ ] };

declare 'MapStringPersistenceConfig',
    as HashRef[PersistenceConfig()];

declare 'PersistenceMode',
    as (Int | Str);

declare 'SnapshotPeriod',
    as (Int | Str);

declare 'RescheduleMaintenanceRequest',
    as InstanceOf['Google::Cloud::Redis::V1beta1::CloudRedis::RescheduleMaintenanceRequest'];

coerce 'RescheduleMaintenanceRequest',
    from HashRef, via { 'Google::Cloud::Redis::V1beta1::CloudRedis::RescheduleMaintenanceRequest'->new($_) };

declare 'RepeatedRescheduleMaintenanceRequest',
    as ArrayRef[RescheduleMaintenanceRequest()];

coerce 'RepeatedRescheduleMaintenanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::V1beta1::CloudRedis::RescheduleMaintenanceRequest'->new($_) } @$_ ] };

declare 'MapStringRescheduleMaintenanceRequest',
    as HashRef[RescheduleMaintenanceRequest()];

declare 'RescheduleType',
    as (Int | Str);

declare 'MaintenancePolicy',
    as InstanceOf['Google::Cloud::Redis::V1beta1::CloudRedis::MaintenancePolicy'];

coerce 'MaintenancePolicy',
    from HashRef, via { 'Google::Cloud::Redis::V1beta1::CloudRedis::MaintenancePolicy'->new($_) };

declare 'RepeatedMaintenancePolicy',
    as ArrayRef[MaintenancePolicy()];

coerce 'RepeatedMaintenancePolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::V1beta1::CloudRedis::MaintenancePolicy'->new($_) } @$_ ] };

declare 'MapStringMaintenancePolicy',
    as HashRef[MaintenancePolicy()];

declare 'WeeklyMaintenanceWindow',
    as InstanceOf['Google::Cloud::Redis::V1beta1::CloudRedis::WeeklyMaintenanceWindow'];

coerce 'WeeklyMaintenanceWindow',
    from HashRef, via { 'Google::Cloud::Redis::V1beta1::CloudRedis::WeeklyMaintenanceWindow'->new($_) };

declare 'RepeatedWeeklyMaintenanceWindow',
    as ArrayRef[WeeklyMaintenanceWindow()];

coerce 'RepeatedWeeklyMaintenanceWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::V1beta1::CloudRedis::WeeklyMaintenanceWindow'->new($_) } @$_ ] };

declare 'MapStringWeeklyMaintenanceWindow',
    as HashRef[WeeklyMaintenanceWindow()];

declare 'MaintenanceSchedule',
    as InstanceOf['Google::Cloud::Redis::V1beta1::CloudRedis::MaintenanceSchedule'];

coerce 'MaintenanceSchedule',
    from HashRef, via { 'Google::Cloud::Redis::V1beta1::CloudRedis::MaintenanceSchedule'->new($_) };

declare 'RepeatedMaintenanceSchedule',
    as ArrayRef[MaintenanceSchedule()];

coerce 'RepeatedMaintenanceSchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::V1beta1::CloudRedis::MaintenanceSchedule'->new($_) } @$_ ] };

declare 'MapStringMaintenanceSchedule',
    as HashRef[MaintenanceSchedule()];

declare 'ListInstancesRequest',
    as InstanceOf['Google::Cloud::Redis::V1beta1::CloudRedis::ListInstancesRequest'];

coerce 'ListInstancesRequest',
    from HashRef, via { 'Google::Cloud::Redis::V1beta1::CloudRedis::ListInstancesRequest'->new($_) };

declare 'RepeatedListInstancesRequest',
    as ArrayRef[ListInstancesRequest()];

coerce 'RepeatedListInstancesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::V1beta1::CloudRedis::ListInstancesRequest'->new($_) } @$_ ] };

declare 'MapStringListInstancesRequest',
    as HashRef[ListInstancesRequest()];

declare 'ListInstancesResponse',
    as InstanceOf['Google::Cloud::Redis::V1beta1::CloudRedis::ListInstancesResponse'];

coerce 'ListInstancesResponse',
    from HashRef, via { 'Google::Cloud::Redis::V1beta1::CloudRedis::ListInstancesResponse'->new($_) };

declare 'RepeatedListInstancesResponse',
    as ArrayRef[ListInstancesResponse()];

coerce 'RepeatedListInstancesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::V1beta1::CloudRedis::ListInstancesResponse'->new($_) } @$_ ] };

declare 'MapStringListInstancesResponse',
    as HashRef[ListInstancesResponse()];

declare 'GetInstanceRequest',
    as InstanceOf['Google::Cloud::Redis::V1beta1::CloudRedis::GetInstanceRequest'];

coerce 'GetInstanceRequest',
    from HashRef, via { 'Google::Cloud::Redis::V1beta1::CloudRedis::GetInstanceRequest'->new($_) };

declare 'RepeatedGetInstanceRequest',
    as ArrayRef[GetInstanceRequest()];

coerce 'RepeatedGetInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::V1beta1::CloudRedis::GetInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringGetInstanceRequest',
    as HashRef[GetInstanceRequest()];

declare 'GetInstanceAuthStringRequest',
    as InstanceOf['Google::Cloud::Redis::V1beta1::CloudRedis::GetInstanceAuthStringRequest'];

coerce 'GetInstanceAuthStringRequest',
    from HashRef, via { 'Google::Cloud::Redis::V1beta1::CloudRedis::GetInstanceAuthStringRequest'->new($_) };

declare 'RepeatedGetInstanceAuthStringRequest',
    as ArrayRef[GetInstanceAuthStringRequest()];

coerce 'RepeatedGetInstanceAuthStringRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::V1beta1::CloudRedis::GetInstanceAuthStringRequest'->new($_) } @$_ ] };

declare 'MapStringGetInstanceAuthStringRequest',
    as HashRef[GetInstanceAuthStringRequest()];

declare 'InstanceAuthString',
    as InstanceOf['Google::Cloud::Redis::V1beta1::CloudRedis::InstanceAuthString'];

coerce 'InstanceAuthString',
    from HashRef, via { 'Google::Cloud::Redis::V1beta1::CloudRedis::InstanceAuthString'->new($_) };

declare 'RepeatedInstanceAuthString',
    as ArrayRef[InstanceAuthString()];

coerce 'RepeatedInstanceAuthString',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::V1beta1::CloudRedis::InstanceAuthString'->new($_) } @$_ ] };

declare 'MapStringInstanceAuthString',
    as HashRef[InstanceAuthString()];

declare 'CreateInstanceRequest',
    as InstanceOf['Google::Cloud::Redis::V1beta1::CloudRedis::CreateInstanceRequest'];

coerce 'CreateInstanceRequest',
    from HashRef, via { 'Google::Cloud::Redis::V1beta1::CloudRedis::CreateInstanceRequest'->new($_) };

declare 'RepeatedCreateInstanceRequest',
    as ArrayRef[CreateInstanceRequest()];

coerce 'RepeatedCreateInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::V1beta1::CloudRedis::CreateInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateInstanceRequest',
    as HashRef[CreateInstanceRequest()];

declare 'UpdateInstanceRequest',
    as InstanceOf['Google::Cloud::Redis::V1beta1::CloudRedis::UpdateInstanceRequest'];

coerce 'UpdateInstanceRequest',
    from HashRef, via { 'Google::Cloud::Redis::V1beta1::CloudRedis::UpdateInstanceRequest'->new($_) };

declare 'RepeatedUpdateInstanceRequest',
    as ArrayRef[UpdateInstanceRequest()];

coerce 'RepeatedUpdateInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::V1beta1::CloudRedis::UpdateInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateInstanceRequest',
    as HashRef[UpdateInstanceRequest()];

declare 'UpgradeInstanceRequest',
    as InstanceOf['Google::Cloud::Redis::V1beta1::CloudRedis::UpgradeInstanceRequest'];

coerce 'UpgradeInstanceRequest',
    from HashRef, via { 'Google::Cloud::Redis::V1beta1::CloudRedis::UpgradeInstanceRequest'->new($_) };

declare 'RepeatedUpgradeInstanceRequest',
    as ArrayRef[UpgradeInstanceRequest()];

coerce 'RepeatedUpgradeInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::V1beta1::CloudRedis::UpgradeInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringUpgradeInstanceRequest',
    as HashRef[UpgradeInstanceRequest()];

declare 'DeleteInstanceRequest',
    as InstanceOf['Google::Cloud::Redis::V1beta1::CloudRedis::DeleteInstanceRequest'];

coerce 'DeleteInstanceRequest',
    from HashRef, via { 'Google::Cloud::Redis::V1beta1::CloudRedis::DeleteInstanceRequest'->new($_) };

declare 'RepeatedDeleteInstanceRequest',
    as ArrayRef[DeleteInstanceRequest()];

coerce 'RepeatedDeleteInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::V1beta1::CloudRedis::DeleteInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteInstanceRequest',
    as HashRef[DeleteInstanceRequest()];

declare 'GcsSource',
    as InstanceOf['Google::Cloud::Redis::V1beta1::CloudRedis::GcsSource'];

coerce 'GcsSource',
    from HashRef, via { 'Google::Cloud::Redis::V1beta1::CloudRedis::GcsSource'->new($_) };

declare 'RepeatedGcsSource',
    as ArrayRef[GcsSource()];

coerce 'RepeatedGcsSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::V1beta1::CloudRedis::GcsSource'->new($_) } @$_ ] };

declare 'MapStringGcsSource',
    as HashRef[GcsSource()];

declare 'InputConfig',
    as InstanceOf['Google::Cloud::Redis::V1beta1::CloudRedis::InputConfig'];

coerce 'InputConfig',
    from HashRef, via { 'Google::Cloud::Redis::V1beta1::CloudRedis::InputConfig'->new($_) };

declare 'RepeatedInputConfig',
    as ArrayRef[InputConfig()];

coerce 'RepeatedInputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::V1beta1::CloudRedis::InputConfig'->new($_) } @$_ ] };

declare 'MapStringInputConfig',
    as HashRef[InputConfig()];

declare 'ImportInstanceRequest',
    as InstanceOf['Google::Cloud::Redis::V1beta1::CloudRedis::ImportInstanceRequest'];

coerce 'ImportInstanceRequest',
    from HashRef, via { 'Google::Cloud::Redis::V1beta1::CloudRedis::ImportInstanceRequest'->new($_) };

declare 'RepeatedImportInstanceRequest',
    as ArrayRef[ImportInstanceRequest()];

coerce 'RepeatedImportInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::V1beta1::CloudRedis::ImportInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringImportInstanceRequest',
    as HashRef[ImportInstanceRequest()];

declare 'GcsDestination',
    as InstanceOf['Google::Cloud::Redis::V1beta1::CloudRedis::GcsDestination'];

coerce 'GcsDestination',
    from HashRef, via { 'Google::Cloud::Redis::V1beta1::CloudRedis::GcsDestination'->new($_) };

declare 'RepeatedGcsDestination',
    as ArrayRef[GcsDestination()];

coerce 'RepeatedGcsDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::V1beta1::CloudRedis::GcsDestination'->new($_) } @$_ ] };

declare 'MapStringGcsDestination',
    as HashRef[GcsDestination()];

declare 'OutputConfig',
    as InstanceOf['Google::Cloud::Redis::V1beta1::CloudRedis::OutputConfig'];

coerce 'OutputConfig',
    from HashRef, via { 'Google::Cloud::Redis::V1beta1::CloudRedis::OutputConfig'->new($_) };

declare 'RepeatedOutputConfig',
    as ArrayRef[OutputConfig()];

coerce 'RepeatedOutputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::V1beta1::CloudRedis::OutputConfig'->new($_) } @$_ ] };

declare 'MapStringOutputConfig',
    as HashRef[OutputConfig()];

declare 'ExportInstanceRequest',
    as InstanceOf['Google::Cloud::Redis::V1beta1::CloudRedis::ExportInstanceRequest'];

coerce 'ExportInstanceRequest',
    from HashRef, via { 'Google::Cloud::Redis::V1beta1::CloudRedis::ExportInstanceRequest'->new($_) };

declare 'RepeatedExportInstanceRequest',
    as ArrayRef[ExportInstanceRequest()];

coerce 'RepeatedExportInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::V1beta1::CloudRedis::ExportInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringExportInstanceRequest',
    as HashRef[ExportInstanceRequest()];

declare 'FailoverInstanceRequest',
    as InstanceOf['Google::Cloud::Redis::V1beta1::CloudRedis::FailoverInstanceRequest'];

coerce 'FailoverInstanceRequest',
    from HashRef, via { 'Google::Cloud::Redis::V1beta1::CloudRedis::FailoverInstanceRequest'->new($_) };

declare 'RepeatedFailoverInstanceRequest',
    as ArrayRef[FailoverInstanceRequest()];

coerce 'RepeatedFailoverInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::V1beta1::CloudRedis::FailoverInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringFailoverInstanceRequest',
    as HashRef[FailoverInstanceRequest()];

declare 'DataProtectionMode',
    as (Int | Str);

declare 'LocationMetadata',
    as InstanceOf['Google::Cloud::Redis::V1beta1::CloudRedis::LocationMetadata'];

coerce 'LocationMetadata',
    from HashRef, via { 'Google::Cloud::Redis::V1beta1::CloudRedis::LocationMetadata'->new($_) };

declare 'RepeatedLocationMetadata',
    as ArrayRef[LocationMetadata()];

coerce 'RepeatedLocationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::V1beta1::CloudRedis::LocationMetadata'->new($_) } @$_ ] };

declare 'MapStringLocationMetadata',
    as HashRef[LocationMetadata()];

declare 'AvailableZonesEntry',
    as InstanceOf['Google::Cloud::Redis::V1beta1::CloudRedis::LocationMetadata::AvailableZonesEntry'];

coerce 'AvailableZonesEntry',
    from HashRef, via { 'Google::Cloud::Redis::V1beta1::CloudRedis::LocationMetadata::AvailableZonesEntry'->new($_) };

declare 'RepeatedAvailableZonesEntry',
    as ArrayRef[AvailableZonesEntry()];

coerce 'RepeatedAvailableZonesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::V1beta1::CloudRedis::LocationMetadata::AvailableZonesEntry'->new($_) } @$_ ] };

declare 'MapStringAvailableZonesEntry',
    as HashRef[AvailableZonesEntry()];

declare 'ZoneMetadata',
    as InstanceOf['Google::Cloud::Redis::V1beta1::CloudRedis::ZoneMetadata'];

coerce 'ZoneMetadata',
    from HashRef, via { 'Google::Cloud::Redis::V1beta1::CloudRedis::ZoneMetadata'->new($_) };

declare 'RepeatedZoneMetadata',
    as ArrayRef[ZoneMetadata()];

coerce 'RepeatedZoneMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::V1beta1::CloudRedis::ZoneMetadata'->new($_) } @$_ ] };

declare 'MapStringZoneMetadata',
    as HashRef[ZoneMetadata()];

declare 'TlsCertificate',
    as InstanceOf['Google::Cloud::Redis::V1beta1::CloudRedis::TlsCertificate'];

coerce 'TlsCertificate',
    from HashRef, via { 'Google::Cloud::Redis::V1beta1::CloudRedis::TlsCertificate'->new($_) };

declare 'RepeatedTlsCertificate',
    as ArrayRef[TlsCertificate()];

coerce 'RepeatedTlsCertificate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Redis::V1beta1::CloudRedis::TlsCertificate'->new($_) } @$_ ] };

declare 'MapStringTlsCertificate',
    as HashRef[TlsCertificate()];

1;

__END__

=head1 NAME

Google::Cloud::Redis::V1beta1::CloudRedis::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
