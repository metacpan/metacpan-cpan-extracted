package Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ReplicaInfo',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ReplicaInfo'];

coerce 'ReplicaInfo',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ReplicaInfo'->new($_) };

declare 'RepeatedReplicaInfo',
    as ArrayRef[ReplicaInfo()];

coerce 'RepeatedReplicaInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ReplicaInfo'->new($_) } @$_ ] };

declare 'MapStringReplicaInfo',
    as HashRef[ReplicaInfo()];

declare 'ReplicaType',
    as (Int | Str);

declare 'InstanceConfig',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::InstanceConfig'];

coerce 'InstanceConfig',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::InstanceConfig'->new($_) };

declare 'RepeatedInstanceConfig',
    as ArrayRef[InstanceConfig()];

coerce 'RepeatedInstanceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::InstanceConfig'->new($_) } @$_ ] };

declare 'MapStringInstanceConfig',
    as HashRef[InstanceConfig()];

declare 'Type',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'FreeInstanceAvailability',
    as (Int | Str);

declare 'QuorumType',
    as (Int | Str);

declare 'AllowedProcessingUnits',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::InstanceConfig::AllowedProcessingUnits'];

coerce 'AllowedProcessingUnits',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::InstanceConfig::AllowedProcessingUnits'->new($_) };

declare 'RepeatedAllowedProcessingUnits',
    as ArrayRef[AllowedProcessingUnits()];

coerce 'RepeatedAllowedProcessingUnits',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::InstanceConfig::AllowedProcessingUnits'->new($_) } @$_ ] };

declare 'MapStringAllowedProcessingUnits',
    as HashRef[AllowedProcessingUnits()];

declare 'LabelsEntry',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::InstanceConfig::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::InstanceConfig::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::InstanceConfig::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ReplicaComputeCapacity',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ReplicaComputeCapacity'];

coerce 'ReplicaComputeCapacity',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ReplicaComputeCapacity'->new($_) };

declare 'RepeatedReplicaComputeCapacity',
    as ArrayRef[ReplicaComputeCapacity()];

coerce 'RepeatedReplicaComputeCapacity',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ReplicaComputeCapacity'->new($_) } @$_ ] };

declare 'MapStringReplicaComputeCapacity',
    as HashRef[ReplicaComputeCapacity()];

declare 'AutoscalingConfig',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::AutoscalingConfig'];

coerce 'AutoscalingConfig',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::AutoscalingConfig'->new($_) };

declare 'RepeatedAutoscalingConfig',
    as ArrayRef[AutoscalingConfig()];

coerce 'RepeatedAutoscalingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::AutoscalingConfig'->new($_) } @$_ ] };

declare 'MapStringAutoscalingConfig',
    as HashRef[AutoscalingConfig()];

declare 'AutoscalingLimits',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::AutoscalingConfig::AutoscalingLimits'];

coerce 'AutoscalingLimits',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::AutoscalingConfig::AutoscalingLimits'->new($_) };

declare 'RepeatedAutoscalingLimits',
    as ArrayRef[AutoscalingLimits()];

coerce 'RepeatedAutoscalingLimits',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::AutoscalingConfig::AutoscalingLimits'->new($_) } @$_ ] };

declare 'MapStringAutoscalingLimits',
    as HashRef[AutoscalingLimits()];

declare 'AutoscalingTargets',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::AutoscalingConfig::AutoscalingTargets'];

coerce 'AutoscalingTargets',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::AutoscalingConfig::AutoscalingTargets'->new($_) };

declare 'RepeatedAutoscalingTargets',
    as ArrayRef[AutoscalingTargets()];

coerce 'RepeatedAutoscalingTargets',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::AutoscalingConfig::AutoscalingTargets'->new($_) } @$_ ] };

declare 'MapStringAutoscalingTargets',
    as HashRef[AutoscalingTargets()];

declare 'AsymmetricAutoscalingOption',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::AutoscalingConfig::AsymmetricAutoscalingOption'];

coerce 'AsymmetricAutoscalingOption',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::AutoscalingConfig::AsymmetricAutoscalingOption'->new($_) };

declare 'RepeatedAsymmetricAutoscalingOption',
    as ArrayRef[AsymmetricAutoscalingOption()];

coerce 'RepeatedAsymmetricAutoscalingOption',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::AutoscalingConfig::AsymmetricAutoscalingOption'->new($_) } @$_ ] };

declare 'MapStringAsymmetricAutoscalingOption',
    as HashRef[AsymmetricAutoscalingOption()];

declare 'AutoscalingConfigOverrides',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::AutoscalingConfig::AsymmetricAutoscalingOption::AutoscalingConfigOverrides'];

coerce 'AutoscalingConfigOverrides',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::AutoscalingConfig::AsymmetricAutoscalingOption::AutoscalingConfigOverrides'->new($_) };

declare 'RepeatedAutoscalingConfigOverrides',
    as ArrayRef[AutoscalingConfigOverrides()];

coerce 'RepeatedAutoscalingConfigOverrides',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::AutoscalingConfig::AsymmetricAutoscalingOption::AutoscalingConfigOverrides'->new($_) } @$_ ] };

declare 'MapStringAutoscalingConfigOverrides',
    as HashRef[AutoscalingConfigOverrides()];

declare 'Instance',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::Instance'];

coerce 'Instance',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::Instance'->new($_) };

declare 'RepeatedInstance',
    as ArrayRef[Instance()];

coerce 'RepeatedInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::Instance'->new($_) } @$_ ] };

declare 'MapStringInstance',
    as HashRef[Instance()];

declare 'State',
    as (Int | Str);

declare 'InstanceType',
    as (Int | Str);

declare 'Edition',
    as (Int | Str);

declare 'DefaultBackupScheduleType',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::Instance::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::Instance::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::Instance::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListInstanceConfigsRequest',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ListInstanceConfigsRequest'];

coerce 'ListInstanceConfigsRequest',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ListInstanceConfigsRequest'->new($_) };

declare 'RepeatedListInstanceConfigsRequest',
    as ArrayRef[ListInstanceConfigsRequest()];

coerce 'RepeatedListInstanceConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ListInstanceConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListInstanceConfigsRequest',
    as HashRef[ListInstanceConfigsRequest()];

declare 'ListInstanceConfigsResponse',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ListInstanceConfigsResponse'];

coerce 'ListInstanceConfigsResponse',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ListInstanceConfigsResponse'->new($_) };

declare 'RepeatedListInstanceConfigsResponse',
    as ArrayRef[ListInstanceConfigsResponse()];

coerce 'RepeatedListInstanceConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ListInstanceConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListInstanceConfigsResponse',
    as HashRef[ListInstanceConfigsResponse()];

declare 'GetInstanceConfigRequest',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::GetInstanceConfigRequest'];

coerce 'GetInstanceConfigRequest',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::GetInstanceConfigRequest'->new($_) };

declare 'RepeatedGetInstanceConfigRequest',
    as ArrayRef[GetInstanceConfigRequest()];

coerce 'RepeatedGetInstanceConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::GetInstanceConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetInstanceConfigRequest',
    as HashRef[GetInstanceConfigRequest()];

declare 'CreateInstanceConfigRequest',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::CreateInstanceConfigRequest'];

coerce 'CreateInstanceConfigRequest',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::CreateInstanceConfigRequest'->new($_) };

declare 'RepeatedCreateInstanceConfigRequest',
    as ArrayRef[CreateInstanceConfigRequest()];

coerce 'RepeatedCreateInstanceConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::CreateInstanceConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateInstanceConfigRequest',
    as HashRef[CreateInstanceConfigRequest()];

declare 'UpdateInstanceConfigRequest',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::UpdateInstanceConfigRequest'];

coerce 'UpdateInstanceConfigRequest',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::UpdateInstanceConfigRequest'->new($_) };

declare 'RepeatedUpdateInstanceConfigRequest',
    as ArrayRef[UpdateInstanceConfigRequest()];

coerce 'RepeatedUpdateInstanceConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::UpdateInstanceConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateInstanceConfigRequest',
    as HashRef[UpdateInstanceConfigRequest()];

declare 'DeleteInstanceConfigRequest',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::DeleteInstanceConfigRequest'];

coerce 'DeleteInstanceConfigRequest',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::DeleteInstanceConfigRequest'->new($_) };

declare 'RepeatedDeleteInstanceConfigRequest',
    as ArrayRef[DeleteInstanceConfigRequest()];

coerce 'RepeatedDeleteInstanceConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::DeleteInstanceConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteInstanceConfigRequest',
    as HashRef[DeleteInstanceConfigRequest()];

declare 'ListInstanceConfigOperationsRequest',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ListInstanceConfigOperationsRequest'];

coerce 'ListInstanceConfigOperationsRequest',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ListInstanceConfigOperationsRequest'->new($_) };

declare 'RepeatedListInstanceConfigOperationsRequest',
    as ArrayRef[ListInstanceConfigOperationsRequest()];

coerce 'RepeatedListInstanceConfigOperationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ListInstanceConfigOperationsRequest'->new($_) } @$_ ] };

declare 'MapStringListInstanceConfigOperationsRequest',
    as HashRef[ListInstanceConfigOperationsRequest()];

declare 'ListInstanceConfigOperationsResponse',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ListInstanceConfigOperationsResponse'];

coerce 'ListInstanceConfigOperationsResponse',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ListInstanceConfigOperationsResponse'->new($_) };

declare 'RepeatedListInstanceConfigOperationsResponse',
    as ArrayRef[ListInstanceConfigOperationsResponse()];

coerce 'RepeatedListInstanceConfigOperationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ListInstanceConfigOperationsResponse'->new($_) } @$_ ] };

declare 'MapStringListInstanceConfigOperationsResponse',
    as HashRef[ListInstanceConfigOperationsResponse()];

declare 'GetInstanceRequest',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::GetInstanceRequest'];

coerce 'GetInstanceRequest',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::GetInstanceRequest'->new($_) };

declare 'RepeatedGetInstanceRequest',
    as ArrayRef[GetInstanceRequest()];

coerce 'RepeatedGetInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::GetInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringGetInstanceRequest',
    as HashRef[GetInstanceRequest()];

declare 'CreateInstanceRequest',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::CreateInstanceRequest'];

coerce 'CreateInstanceRequest',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::CreateInstanceRequest'->new($_) };

declare 'RepeatedCreateInstanceRequest',
    as ArrayRef[CreateInstanceRequest()];

coerce 'RepeatedCreateInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::CreateInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateInstanceRequest',
    as HashRef[CreateInstanceRequest()];

declare 'ListInstancesRequest',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ListInstancesRequest'];

coerce 'ListInstancesRequest',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ListInstancesRequest'->new($_) };

declare 'RepeatedListInstancesRequest',
    as ArrayRef[ListInstancesRequest()];

coerce 'RepeatedListInstancesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ListInstancesRequest'->new($_) } @$_ ] };

declare 'MapStringListInstancesRequest',
    as HashRef[ListInstancesRequest()];

declare 'ListInstancesResponse',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ListInstancesResponse'];

coerce 'ListInstancesResponse',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ListInstancesResponse'->new($_) };

declare 'RepeatedListInstancesResponse',
    as ArrayRef[ListInstancesResponse()];

coerce 'RepeatedListInstancesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ListInstancesResponse'->new($_) } @$_ ] };

declare 'MapStringListInstancesResponse',
    as HashRef[ListInstancesResponse()];

declare 'UpdateInstanceRequest',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::UpdateInstanceRequest'];

coerce 'UpdateInstanceRequest',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::UpdateInstanceRequest'->new($_) };

declare 'RepeatedUpdateInstanceRequest',
    as ArrayRef[UpdateInstanceRequest()];

coerce 'RepeatedUpdateInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::UpdateInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateInstanceRequest',
    as HashRef[UpdateInstanceRequest()];

declare 'DeleteInstanceRequest',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::DeleteInstanceRequest'];

coerce 'DeleteInstanceRequest',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::DeleteInstanceRequest'->new($_) };

declare 'RepeatedDeleteInstanceRequest',
    as ArrayRef[DeleteInstanceRequest()];

coerce 'RepeatedDeleteInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::DeleteInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteInstanceRequest',
    as HashRef[DeleteInstanceRequest()];

declare 'CreateInstanceMetadata',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::CreateInstanceMetadata'];

coerce 'CreateInstanceMetadata',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::CreateInstanceMetadata'->new($_) };

declare 'RepeatedCreateInstanceMetadata',
    as ArrayRef[CreateInstanceMetadata()];

coerce 'RepeatedCreateInstanceMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::CreateInstanceMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateInstanceMetadata',
    as HashRef[CreateInstanceMetadata()];

declare 'UpdateInstanceMetadata',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::UpdateInstanceMetadata'];

coerce 'UpdateInstanceMetadata',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::UpdateInstanceMetadata'->new($_) };

declare 'RepeatedUpdateInstanceMetadata',
    as ArrayRef[UpdateInstanceMetadata()];

coerce 'RepeatedUpdateInstanceMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::UpdateInstanceMetadata'->new($_) } @$_ ] };

declare 'MapStringUpdateInstanceMetadata',
    as HashRef[UpdateInstanceMetadata()];

declare 'FreeInstanceMetadata',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::FreeInstanceMetadata'];

coerce 'FreeInstanceMetadata',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::FreeInstanceMetadata'->new($_) };

declare 'RepeatedFreeInstanceMetadata',
    as ArrayRef[FreeInstanceMetadata()];

coerce 'RepeatedFreeInstanceMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::FreeInstanceMetadata'->new($_) } @$_ ] };

declare 'MapStringFreeInstanceMetadata',
    as HashRef[FreeInstanceMetadata()];

declare 'ExpireBehavior',
    as (Int | Str);

declare 'CreateInstanceConfigMetadata',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::CreateInstanceConfigMetadata'];

coerce 'CreateInstanceConfigMetadata',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::CreateInstanceConfigMetadata'->new($_) };

declare 'RepeatedCreateInstanceConfigMetadata',
    as ArrayRef[CreateInstanceConfigMetadata()];

coerce 'RepeatedCreateInstanceConfigMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::CreateInstanceConfigMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateInstanceConfigMetadata',
    as HashRef[CreateInstanceConfigMetadata()];

declare 'UpdateInstanceConfigMetadata',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::UpdateInstanceConfigMetadata'];

coerce 'UpdateInstanceConfigMetadata',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::UpdateInstanceConfigMetadata'->new($_) };

declare 'RepeatedUpdateInstanceConfigMetadata',
    as ArrayRef[UpdateInstanceConfigMetadata()];

coerce 'RepeatedUpdateInstanceConfigMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::UpdateInstanceConfigMetadata'->new($_) } @$_ ] };

declare 'MapStringUpdateInstanceConfigMetadata',
    as HashRef[UpdateInstanceConfigMetadata()];

declare 'InstancePartition',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::InstancePartition'];

coerce 'InstancePartition',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::InstancePartition'->new($_) };

declare 'RepeatedInstancePartition',
    as ArrayRef[InstancePartition()];

coerce 'RepeatedInstancePartition',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::InstancePartition'->new($_) } @$_ ] };

declare 'MapStringInstancePartition',
    as HashRef[InstancePartition()];

declare 'State',
    as (Int | Str);

declare 'CreateInstancePartitionMetadata',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::CreateInstancePartitionMetadata'];

coerce 'CreateInstancePartitionMetadata',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::CreateInstancePartitionMetadata'->new($_) };

declare 'RepeatedCreateInstancePartitionMetadata',
    as ArrayRef[CreateInstancePartitionMetadata()];

coerce 'RepeatedCreateInstancePartitionMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::CreateInstancePartitionMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateInstancePartitionMetadata',
    as HashRef[CreateInstancePartitionMetadata()];

declare 'CreateInstancePartitionRequest',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::CreateInstancePartitionRequest'];

coerce 'CreateInstancePartitionRequest',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::CreateInstancePartitionRequest'->new($_) };

declare 'RepeatedCreateInstancePartitionRequest',
    as ArrayRef[CreateInstancePartitionRequest()];

coerce 'RepeatedCreateInstancePartitionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::CreateInstancePartitionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateInstancePartitionRequest',
    as HashRef[CreateInstancePartitionRequest()];

declare 'DeleteInstancePartitionRequest',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::DeleteInstancePartitionRequest'];

coerce 'DeleteInstancePartitionRequest',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::DeleteInstancePartitionRequest'->new($_) };

declare 'RepeatedDeleteInstancePartitionRequest',
    as ArrayRef[DeleteInstancePartitionRequest()];

coerce 'RepeatedDeleteInstancePartitionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::DeleteInstancePartitionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteInstancePartitionRequest',
    as HashRef[DeleteInstancePartitionRequest()];

declare 'GetInstancePartitionRequest',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::GetInstancePartitionRequest'];

coerce 'GetInstancePartitionRequest',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::GetInstancePartitionRequest'->new($_) };

declare 'RepeatedGetInstancePartitionRequest',
    as ArrayRef[GetInstancePartitionRequest()];

coerce 'RepeatedGetInstancePartitionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::GetInstancePartitionRequest'->new($_) } @$_ ] };

declare 'MapStringGetInstancePartitionRequest',
    as HashRef[GetInstancePartitionRequest()];

declare 'UpdateInstancePartitionRequest',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::UpdateInstancePartitionRequest'];

coerce 'UpdateInstancePartitionRequest',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::UpdateInstancePartitionRequest'->new($_) };

declare 'RepeatedUpdateInstancePartitionRequest',
    as ArrayRef[UpdateInstancePartitionRequest()];

coerce 'RepeatedUpdateInstancePartitionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::UpdateInstancePartitionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateInstancePartitionRequest',
    as HashRef[UpdateInstancePartitionRequest()];

declare 'UpdateInstancePartitionMetadata',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::UpdateInstancePartitionMetadata'];

coerce 'UpdateInstancePartitionMetadata',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::UpdateInstancePartitionMetadata'->new($_) };

declare 'RepeatedUpdateInstancePartitionMetadata',
    as ArrayRef[UpdateInstancePartitionMetadata()];

coerce 'RepeatedUpdateInstancePartitionMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::UpdateInstancePartitionMetadata'->new($_) } @$_ ] };

declare 'MapStringUpdateInstancePartitionMetadata',
    as HashRef[UpdateInstancePartitionMetadata()];

declare 'ListInstancePartitionsRequest',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ListInstancePartitionsRequest'];

coerce 'ListInstancePartitionsRequest',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ListInstancePartitionsRequest'->new($_) };

declare 'RepeatedListInstancePartitionsRequest',
    as ArrayRef[ListInstancePartitionsRequest()];

coerce 'RepeatedListInstancePartitionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ListInstancePartitionsRequest'->new($_) } @$_ ] };

declare 'MapStringListInstancePartitionsRequest',
    as HashRef[ListInstancePartitionsRequest()];

declare 'ListInstancePartitionsResponse',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ListInstancePartitionsResponse'];

coerce 'ListInstancePartitionsResponse',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ListInstancePartitionsResponse'->new($_) };

declare 'RepeatedListInstancePartitionsResponse',
    as ArrayRef[ListInstancePartitionsResponse()];

coerce 'RepeatedListInstancePartitionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ListInstancePartitionsResponse'->new($_) } @$_ ] };

declare 'MapStringListInstancePartitionsResponse',
    as HashRef[ListInstancePartitionsResponse()];

declare 'ListInstancePartitionOperationsRequest',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ListInstancePartitionOperationsRequest'];

coerce 'ListInstancePartitionOperationsRequest',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ListInstancePartitionOperationsRequest'->new($_) };

declare 'RepeatedListInstancePartitionOperationsRequest',
    as ArrayRef[ListInstancePartitionOperationsRequest()];

coerce 'RepeatedListInstancePartitionOperationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ListInstancePartitionOperationsRequest'->new($_) } @$_ ] };

declare 'MapStringListInstancePartitionOperationsRequest',
    as HashRef[ListInstancePartitionOperationsRequest()];

declare 'ListInstancePartitionOperationsResponse',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ListInstancePartitionOperationsResponse'];

coerce 'ListInstancePartitionOperationsResponse',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ListInstancePartitionOperationsResponse'->new($_) };

declare 'RepeatedListInstancePartitionOperationsResponse',
    as ArrayRef[ListInstancePartitionOperationsResponse()];

coerce 'RepeatedListInstancePartitionOperationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::ListInstancePartitionOperationsResponse'->new($_) } @$_ ] };

declare 'MapStringListInstancePartitionOperationsResponse',
    as HashRef[ListInstancePartitionOperationsResponse()];

declare 'MoveInstanceRequest',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::MoveInstanceRequest'];

coerce 'MoveInstanceRequest',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::MoveInstanceRequest'->new($_) };

declare 'RepeatedMoveInstanceRequest',
    as ArrayRef[MoveInstanceRequest()];

coerce 'RepeatedMoveInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::MoveInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringMoveInstanceRequest',
    as HashRef[MoveInstanceRequest()];

declare 'MoveInstanceResponse',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::MoveInstanceResponse'];

coerce 'MoveInstanceResponse',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::MoveInstanceResponse'->new($_) };

declare 'RepeatedMoveInstanceResponse',
    as ArrayRef[MoveInstanceResponse()];

coerce 'RepeatedMoveInstanceResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::MoveInstanceResponse'->new($_) } @$_ ] };

declare 'MapStringMoveInstanceResponse',
    as HashRef[MoveInstanceResponse()];

declare 'MoveInstanceMetadata',
    as InstanceOf['Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::MoveInstanceMetadata'];

coerce 'MoveInstanceMetadata',
    from HashRef, via { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::MoveInstanceMetadata'->new($_) };

declare 'RepeatedMoveInstanceMetadata',
    as ArrayRef[MoveInstanceMetadata()];

coerce 'RepeatedMoveInstanceMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::MoveInstanceMetadata'->new($_) } @$_ ] };

declare 'MapStringMoveInstanceMetadata',
    as HashRef[MoveInstanceMetadata()];

1;

__END__

=head1 NAME

Google::Spanner::Admin::Instance::V1::SpannerInstanceAdmin::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
