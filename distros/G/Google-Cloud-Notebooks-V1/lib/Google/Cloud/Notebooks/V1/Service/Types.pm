package Google::Cloud::Notebooks::V1::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'UpgradeType',
    as (Int | Str);

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'ListInstancesRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::ListInstancesRequest'];

coerce 'ListInstancesRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::ListInstancesRequest'->new($_) };

declare 'RepeatedListInstancesRequest',
    as ArrayRef[ListInstancesRequest()];

coerce 'RepeatedListInstancesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::ListInstancesRequest'->new($_) } @$_ ] };

declare 'MapStringListInstancesRequest',
    as HashRef[ListInstancesRequest()];

declare 'ListInstancesResponse',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::ListInstancesResponse'];

coerce 'ListInstancesResponse',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::ListInstancesResponse'->new($_) };

declare 'RepeatedListInstancesResponse',
    as ArrayRef[ListInstancesResponse()];

coerce 'RepeatedListInstancesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::ListInstancesResponse'->new($_) } @$_ ] };

declare 'MapStringListInstancesResponse',
    as HashRef[ListInstancesResponse()];

declare 'GetInstanceRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::GetInstanceRequest'];

coerce 'GetInstanceRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::GetInstanceRequest'->new($_) };

declare 'RepeatedGetInstanceRequest',
    as ArrayRef[GetInstanceRequest()];

coerce 'RepeatedGetInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::GetInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringGetInstanceRequest',
    as HashRef[GetInstanceRequest()];

declare 'CreateInstanceRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::CreateInstanceRequest'];

coerce 'CreateInstanceRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::CreateInstanceRequest'->new($_) };

declare 'RepeatedCreateInstanceRequest',
    as ArrayRef[CreateInstanceRequest()];

coerce 'RepeatedCreateInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::CreateInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateInstanceRequest',
    as HashRef[CreateInstanceRequest()];

declare 'RegisterInstanceRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::RegisterInstanceRequest'];

coerce 'RegisterInstanceRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::RegisterInstanceRequest'->new($_) };

declare 'RepeatedRegisterInstanceRequest',
    as ArrayRef[RegisterInstanceRequest()];

coerce 'RepeatedRegisterInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::RegisterInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringRegisterInstanceRequest',
    as HashRef[RegisterInstanceRequest()];

declare 'SetInstanceAcceleratorRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::SetInstanceAcceleratorRequest'];

coerce 'SetInstanceAcceleratorRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::SetInstanceAcceleratorRequest'->new($_) };

declare 'RepeatedSetInstanceAcceleratorRequest',
    as ArrayRef[SetInstanceAcceleratorRequest()];

coerce 'RepeatedSetInstanceAcceleratorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::SetInstanceAcceleratorRequest'->new($_) } @$_ ] };

declare 'MapStringSetInstanceAcceleratorRequest',
    as HashRef[SetInstanceAcceleratorRequest()];

declare 'SetInstanceMachineTypeRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::SetInstanceMachineTypeRequest'];

coerce 'SetInstanceMachineTypeRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::SetInstanceMachineTypeRequest'->new($_) };

declare 'RepeatedSetInstanceMachineTypeRequest',
    as ArrayRef[SetInstanceMachineTypeRequest()];

coerce 'RepeatedSetInstanceMachineTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::SetInstanceMachineTypeRequest'->new($_) } @$_ ] };

declare 'MapStringSetInstanceMachineTypeRequest',
    as HashRef[SetInstanceMachineTypeRequest()];

declare 'UpdateInstanceConfigRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::UpdateInstanceConfigRequest'];

coerce 'UpdateInstanceConfigRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::UpdateInstanceConfigRequest'->new($_) };

declare 'RepeatedUpdateInstanceConfigRequest',
    as ArrayRef[UpdateInstanceConfigRequest()];

coerce 'RepeatedUpdateInstanceConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::UpdateInstanceConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateInstanceConfigRequest',
    as HashRef[UpdateInstanceConfigRequest()];

declare 'SetInstanceLabelsRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::SetInstanceLabelsRequest'];

coerce 'SetInstanceLabelsRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::SetInstanceLabelsRequest'->new($_) };

declare 'RepeatedSetInstanceLabelsRequest',
    as ArrayRef[SetInstanceLabelsRequest()];

coerce 'RepeatedSetInstanceLabelsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::SetInstanceLabelsRequest'->new($_) } @$_ ] };

declare 'MapStringSetInstanceLabelsRequest',
    as HashRef[SetInstanceLabelsRequest()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::SetInstanceLabelsRequest::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::SetInstanceLabelsRequest::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::SetInstanceLabelsRequest::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'UpdateInstanceMetadataItemsRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::UpdateInstanceMetadataItemsRequest'];

coerce 'UpdateInstanceMetadataItemsRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::UpdateInstanceMetadataItemsRequest'->new($_) };

declare 'RepeatedUpdateInstanceMetadataItemsRequest',
    as ArrayRef[UpdateInstanceMetadataItemsRequest()];

coerce 'RepeatedUpdateInstanceMetadataItemsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::UpdateInstanceMetadataItemsRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateInstanceMetadataItemsRequest',
    as HashRef[UpdateInstanceMetadataItemsRequest()];

declare 'ItemsEntry',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::UpdateInstanceMetadataItemsRequest::ItemsEntry'];

coerce 'ItemsEntry',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::UpdateInstanceMetadataItemsRequest::ItemsEntry'->new($_) };

declare 'RepeatedItemsEntry',
    as ArrayRef[ItemsEntry()];

coerce 'RepeatedItemsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::UpdateInstanceMetadataItemsRequest::ItemsEntry'->new($_) } @$_ ] };

declare 'MapStringItemsEntry',
    as HashRef[ItemsEntry()];

declare 'UpdateInstanceMetadataItemsResponse',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::UpdateInstanceMetadataItemsResponse'];

coerce 'UpdateInstanceMetadataItemsResponse',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::UpdateInstanceMetadataItemsResponse'->new($_) };

declare 'RepeatedUpdateInstanceMetadataItemsResponse',
    as ArrayRef[UpdateInstanceMetadataItemsResponse()];

coerce 'RepeatedUpdateInstanceMetadataItemsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::UpdateInstanceMetadataItemsResponse'->new($_) } @$_ ] };

declare 'MapStringUpdateInstanceMetadataItemsResponse',
    as HashRef[UpdateInstanceMetadataItemsResponse()];

declare 'ItemsEntry',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::UpdateInstanceMetadataItemsResponse::ItemsEntry'];

coerce 'ItemsEntry',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::UpdateInstanceMetadataItemsResponse::ItemsEntry'->new($_) };

declare 'RepeatedItemsEntry',
    as ArrayRef[ItemsEntry()];

coerce 'RepeatedItemsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::UpdateInstanceMetadataItemsResponse::ItemsEntry'->new($_) } @$_ ] };

declare 'MapStringItemsEntry',
    as HashRef[ItemsEntry()];

declare 'UpdateShieldedInstanceConfigRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::UpdateShieldedInstanceConfigRequest'];

coerce 'UpdateShieldedInstanceConfigRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::UpdateShieldedInstanceConfigRequest'->new($_) };

declare 'RepeatedUpdateShieldedInstanceConfigRequest',
    as ArrayRef[UpdateShieldedInstanceConfigRequest()];

coerce 'RepeatedUpdateShieldedInstanceConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::UpdateShieldedInstanceConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateShieldedInstanceConfigRequest',
    as HashRef[UpdateShieldedInstanceConfigRequest()];

declare 'DeleteInstanceRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::DeleteInstanceRequest'];

coerce 'DeleteInstanceRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::DeleteInstanceRequest'->new($_) };

declare 'RepeatedDeleteInstanceRequest',
    as ArrayRef[DeleteInstanceRequest()];

coerce 'RepeatedDeleteInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::DeleteInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteInstanceRequest',
    as HashRef[DeleteInstanceRequest()];

declare 'StartInstanceRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::StartInstanceRequest'];

coerce 'StartInstanceRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::StartInstanceRequest'->new($_) };

declare 'RepeatedStartInstanceRequest',
    as ArrayRef[StartInstanceRequest()];

coerce 'RepeatedStartInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::StartInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringStartInstanceRequest',
    as HashRef[StartInstanceRequest()];

declare 'StopInstanceRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::StopInstanceRequest'];

coerce 'StopInstanceRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::StopInstanceRequest'->new($_) };

declare 'RepeatedStopInstanceRequest',
    as ArrayRef[StopInstanceRequest()];

coerce 'RepeatedStopInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::StopInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringStopInstanceRequest',
    as HashRef[StopInstanceRequest()];

declare 'ResetInstanceRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::ResetInstanceRequest'];

coerce 'ResetInstanceRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::ResetInstanceRequest'->new($_) };

declare 'RepeatedResetInstanceRequest',
    as ArrayRef[ResetInstanceRequest()];

coerce 'RepeatedResetInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::ResetInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringResetInstanceRequest',
    as HashRef[ResetInstanceRequest()];

declare 'ReportInstanceInfoRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::ReportInstanceInfoRequest'];

coerce 'ReportInstanceInfoRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::ReportInstanceInfoRequest'->new($_) };

declare 'RepeatedReportInstanceInfoRequest',
    as ArrayRef[ReportInstanceInfoRequest()];

coerce 'RepeatedReportInstanceInfoRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::ReportInstanceInfoRequest'->new($_) } @$_ ] };

declare 'MapStringReportInstanceInfoRequest',
    as HashRef[ReportInstanceInfoRequest()];

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::ReportInstanceInfoRequest::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::ReportInstanceInfoRequest::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::ReportInstanceInfoRequest::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'IsInstanceUpgradeableRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::IsInstanceUpgradeableRequest'];

coerce 'IsInstanceUpgradeableRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::IsInstanceUpgradeableRequest'->new($_) };

declare 'RepeatedIsInstanceUpgradeableRequest',
    as ArrayRef[IsInstanceUpgradeableRequest()];

coerce 'RepeatedIsInstanceUpgradeableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::IsInstanceUpgradeableRequest'->new($_) } @$_ ] };

declare 'MapStringIsInstanceUpgradeableRequest',
    as HashRef[IsInstanceUpgradeableRequest()];

declare 'IsInstanceUpgradeableResponse',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::IsInstanceUpgradeableResponse'];

coerce 'IsInstanceUpgradeableResponse',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::IsInstanceUpgradeableResponse'->new($_) };

declare 'RepeatedIsInstanceUpgradeableResponse',
    as ArrayRef[IsInstanceUpgradeableResponse()];

coerce 'RepeatedIsInstanceUpgradeableResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::IsInstanceUpgradeableResponse'->new($_) } @$_ ] };

declare 'MapStringIsInstanceUpgradeableResponse',
    as HashRef[IsInstanceUpgradeableResponse()];

declare 'GetInstanceHealthRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::GetInstanceHealthRequest'];

coerce 'GetInstanceHealthRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::GetInstanceHealthRequest'->new($_) };

declare 'RepeatedGetInstanceHealthRequest',
    as ArrayRef[GetInstanceHealthRequest()];

coerce 'RepeatedGetInstanceHealthRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::GetInstanceHealthRequest'->new($_) } @$_ ] };

declare 'MapStringGetInstanceHealthRequest',
    as HashRef[GetInstanceHealthRequest()];

declare 'GetInstanceHealthResponse',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::GetInstanceHealthResponse'];

coerce 'GetInstanceHealthResponse',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::GetInstanceHealthResponse'->new($_) };

declare 'RepeatedGetInstanceHealthResponse',
    as ArrayRef[GetInstanceHealthResponse()];

coerce 'RepeatedGetInstanceHealthResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::GetInstanceHealthResponse'->new($_) } @$_ ] };

declare 'MapStringGetInstanceHealthResponse',
    as HashRef[GetInstanceHealthResponse()];

declare 'HealthState',
    as (Int | Str);

declare 'HealthInfoEntry',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::GetInstanceHealthResponse::HealthInfoEntry'];

coerce 'HealthInfoEntry',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::GetInstanceHealthResponse::HealthInfoEntry'->new($_) };

declare 'RepeatedHealthInfoEntry',
    as ArrayRef[HealthInfoEntry()];

coerce 'RepeatedHealthInfoEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::GetInstanceHealthResponse::HealthInfoEntry'->new($_) } @$_ ] };

declare 'MapStringHealthInfoEntry',
    as HashRef[HealthInfoEntry()];

declare 'UpgradeInstanceRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::UpgradeInstanceRequest'];

coerce 'UpgradeInstanceRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::UpgradeInstanceRequest'->new($_) };

declare 'RepeatedUpgradeInstanceRequest',
    as ArrayRef[UpgradeInstanceRequest()];

coerce 'RepeatedUpgradeInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::UpgradeInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringUpgradeInstanceRequest',
    as HashRef[UpgradeInstanceRequest()];

declare 'RollbackInstanceRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::RollbackInstanceRequest'];

coerce 'RollbackInstanceRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::RollbackInstanceRequest'->new($_) };

declare 'RepeatedRollbackInstanceRequest',
    as ArrayRef[RollbackInstanceRequest()];

coerce 'RepeatedRollbackInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::RollbackInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringRollbackInstanceRequest',
    as HashRef[RollbackInstanceRequest()];

declare 'UpgradeInstanceInternalRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::UpgradeInstanceInternalRequest'];

coerce 'UpgradeInstanceInternalRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::UpgradeInstanceInternalRequest'->new($_) };

declare 'RepeatedUpgradeInstanceInternalRequest',
    as ArrayRef[UpgradeInstanceInternalRequest()];

coerce 'RepeatedUpgradeInstanceInternalRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::UpgradeInstanceInternalRequest'->new($_) } @$_ ] };

declare 'MapStringUpgradeInstanceInternalRequest',
    as HashRef[UpgradeInstanceInternalRequest()];

declare 'ListEnvironmentsRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::ListEnvironmentsRequest'];

coerce 'ListEnvironmentsRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::ListEnvironmentsRequest'->new($_) };

declare 'RepeatedListEnvironmentsRequest',
    as ArrayRef[ListEnvironmentsRequest()];

coerce 'RepeatedListEnvironmentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::ListEnvironmentsRequest'->new($_) } @$_ ] };

declare 'MapStringListEnvironmentsRequest',
    as HashRef[ListEnvironmentsRequest()];

declare 'DiagnoseInstanceRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::DiagnoseInstanceRequest'];

coerce 'DiagnoseInstanceRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::DiagnoseInstanceRequest'->new($_) };

declare 'RepeatedDiagnoseInstanceRequest',
    as ArrayRef[DiagnoseInstanceRequest()];

coerce 'RepeatedDiagnoseInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::DiagnoseInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringDiagnoseInstanceRequest',
    as HashRef[DiagnoseInstanceRequest()];

declare 'ListEnvironmentsResponse',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::ListEnvironmentsResponse'];

coerce 'ListEnvironmentsResponse',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::ListEnvironmentsResponse'->new($_) };

declare 'RepeatedListEnvironmentsResponse',
    as ArrayRef[ListEnvironmentsResponse()];

coerce 'RepeatedListEnvironmentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::ListEnvironmentsResponse'->new($_) } @$_ ] };

declare 'MapStringListEnvironmentsResponse',
    as HashRef[ListEnvironmentsResponse()];

declare 'GetEnvironmentRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::GetEnvironmentRequest'];

coerce 'GetEnvironmentRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::GetEnvironmentRequest'->new($_) };

declare 'RepeatedGetEnvironmentRequest',
    as ArrayRef[GetEnvironmentRequest()];

coerce 'RepeatedGetEnvironmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::GetEnvironmentRequest'->new($_) } @$_ ] };

declare 'MapStringGetEnvironmentRequest',
    as HashRef[GetEnvironmentRequest()];

declare 'CreateEnvironmentRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::CreateEnvironmentRequest'];

coerce 'CreateEnvironmentRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::CreateEnvironmentRequest'->new($_) };

declare 'RepeatedCreateEnvironmentRequest',
    as ArrayRef[CreateEnvironmentRequest()];

coerce 'RepeatedCreateEnvironmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::CreateEnvironmentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEnvironmentRequest',
    as HashRef[CreateEnvironmentRequest()];

declare 'DeleteEnvironmentRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::DeleteEnvironmentRequest'];

coerce 'DeleteEnvironmentRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::DeleteEnvironmentRequest'->new($_) };

declare 'RepeatedDeleteEnvironmentRequest',
    as ArrayRef[DeleteEnvironmentRequest()];

coerce 'RepeatedDeleteEnvironmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::DeleteEnvironmentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEnvironmentRequest',
    as HashRef[DeleteEnvironmentRequest()];

declare 'ListSchedulesRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::ListSchedulesRequest'];

coerce 'ListSchedulesRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::ListSchedulesRequest'->new($_) };

declare 'RepeatedListSchedulesRequest',
    as ArrayRef[ListSchedulesRequest()];

coerce 'RepeatedListSchedulesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::ListSchedulesRequest'->new($_) } @$_ ] };

declare 'MapStringListSchedulesRequest',
    as HashRef[ListSchedulesRequest()];

declare 'ListSchedulesResponse',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::ListSchedulesResponse'];

coerce 'ListSchedulesResponse',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::ListSchedulesResponse'->new($_) };

declare 'RepeatedListSchedulesResponse',
    as ArrayRef[ListSchedulesResponse()];

coerce 'RepeatedListSchedulesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::ListSchedulesResponse'->new($_) } @$_ ] };

declare 'MapStringListSchedulesResponse',
    as HashRef[ListSchedulesResponse()];

declare 'GetScheduleRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::GetScheduleRequest'];

coerce 'GetScheduleRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::GetScheduleRequest'->new($_) };

declare 'RepeatedGetScheduleRequest',
    as ArrayRef[GetScheduleRequest()];

coerce 'RepeatedGetScheduleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::GetScheduleRequest'->new($_) } @$_ ] };

declare 'MapStringGetScheduleRequest',
    as HashRef[GetScheduleRequest()];

declare 'DeleteScheduleRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::DeleteScheduleRequest'];

coerce 'DeleteScheduleRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::DeleteScheduleRequest'->new($_) };

declare 'RepeatedDeleteScheduleRequest',
    as ArrayRef[DeleteScheduleRequest()];

coerce 'RepeatedDeleteScheduleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::DeleteScheduleRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteScheduleRequest',
    as HashRef[DeleteScheduleRequest()];

declare 'CreateScheduleRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::CreateScheduleRequest'];

coerce 'CreateScheduleRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::CreateScheduleRequest'->new($_) };

declare 'RepeatedCreateScheduleRequest',
    as ArrayRef[CreateScheduleRequest()];

coerce 'RepeatedCreateScheduleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::CreateScheduleRequest'->new($_) } @$_ ] };

declare 'MapStringCreateScheduleRequest',
    as HashRef[CreateScheduleRequest()];

declare 'TriggerScheduleRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::TriggerScheduleRequest'];

coerce 'TriggerScheduleRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::TriggerScheduleRequest'->new($_) };

declare 'RepeatedTriggerScheduleRequest',
    as ArrayRef[TriggerScheduleRequest()];

coerce 'RepeatedTriggerScheduleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::TriggerScheduleRequest'->new($_) } @$_ ] };

declare 'MapStringTriggerScheduleRequest',
    as HashRef[TriggerScheduleRequest()];

declare 'ListExecutionsRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::ListExecutionsRequest'];

coerce 'ListExecutionsRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::ListExecutionsRequest'->new($_) };

declare 'RepeatedListExecutionsRequest',
    as ArrayRef[ListExecutionsRequest()];

coerce 'RepeatedListExecutionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::ListExecutionsRequest'->new($_) } @$_ ] };

declare 'MapStringListExecutionsRequest',
    as HashRef[ListExecutionsRequest()];

declare 'ListExecutionsResponse',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::ListExecutionsResponse'];

coerce 'ListExecutionsResponse',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::ListExecutionsResponse'->new($_) };

declare 'RepeatedListExecutionsResponse',
    as ArrayRef[ListExecutionsResponse()];

coerce 'RepeatedListExecutionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::ListExecutionsResponse'->new($_) } @$_ ] };

declare 'MapStringListExecutionsResponse',
    as HashRef[ListExecutionsResponse()];

declare 'GetExecutionRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::GetExecutionRequest'];

coerce 'GetExecutionRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::GetExecutionRequest'->new($_) };

declare 'RepeatedGetExecutionRequest',
    as ArrayRef[GetExecutionRequest()];

coerce 'RepeatedGetExecutionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::GetExecutionRequest'->new($_) } @$_ ] };

declare 'MapStringGetExecutionRequest',
    as HashRef[GetExecutionRequest()];

declare 'DeleteExecutionRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::DeleteExecutionRequest'];

coerce 'DeleteExecutionRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::DeleteExecutionRequest'->new($_) };

declare 'RepeatedDeleteExecutionRequest',
    as ArrayRef[DeleteExecutionRequest()];

coerce 'RepeatedDeleteExecutionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::DeleteExecutionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteExecutionRequest',
    as HashRef[DeleteExecutionRequest()];

declare 'CreateExecutionRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::Service::CreateExecutionRequest'];

coerce 'CreateExecutionRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::Service::CreateExecutionRequest'->new($_) };

declare 'RepeatedCreateExecutionRequest',
    as ArrayRef[CreateExecutionRequest()];

coerce 'RepeatedCreateExecutionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::Service::CreateExecutionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateExecutionRequest',
    as HashRef[CreateExecutionRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Notebooks::V1::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
