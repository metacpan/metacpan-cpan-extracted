package Google::Cloud::Visionai::V1::Platform::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ModelType',
    as (Int | Str);

declare 'AcceleratorType',
    as (Int | Str);

declare 'DataType',
    as (Int | Str);

declare 'DeleteApplicationInstancesResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::DeleteApplicationInstancesResponse'];

coerce 'DeleteApplicationInstancesResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::DeleteApplicationInstancesResponse'->new($_) };

declare 'RepeatedDeleteApplicationInstancesResponse',
    as ArrayRef[DeleteApplicationInstancesResponse()];

coerce 'RepeatedDeleteApplicationInstancesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::DeleteApplicationInstancesResponse'->new($_) } @$_ ] };

declare 'MapStringDeleteApplicationInstancesResponse',
    as HashRef[DeleteApplicationInstancesResponse()];

declare 'CreateApplicationInstancesResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::CreateApplicationInstancesResponse'];

coerce 'CreateApplicationInstancesResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::CreateApplicationInstancesResponse'->new($_) };

declare 'RepeatedCreateApplicationInstancesResponse',
    as ArrayRef[CreateApplicationInstancesResponse()];

coerce 'RepeatedCreateApplicationInstancesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::CreateApplicationInstancesResponse'->new($_) } @$_ ] };

declare 'MapStringCreateApplicationInstancesResponse',
    as HashRef[CreateApplicationInstancesResponse()];

declare 'UpdateApplicationInstancesResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::UpdateApplicationInstancesResponse'];

coerce 'UpdateApplicationInstancesResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::UpdateApplicationInstancesResponse'->new($_) };

declare 'RepeatedUpdateApplicationInstancesResponse',
    as ArrayRef[UpdateApplicationInstancesResponse()];

coerce 'RepeatedUpdateApplicationInstancesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::UpdateApplicationInstancesResponse'->new($_) } @$_ ] };

declare 'MapStringUpdateApplicationInstancesResponse',
    as HashRef[UpdateApplicationInstancesResponse()];

declare 'CreateApplicationInstancesRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::CreateApplicationInstancesRequest'];

coerce 'CreateApplicationInstancesRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::CreateApplicationInstancesRequest'->new($_) };

declare 'RepeatedCreateApplicationInstancesRequest',
    as ArrayRef[CreateApplicationInstancesRequest()];

coerce 'RepeatedCreateApplicationInstancesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::CreateApplicationInstancesRequest'->new($_) } @$_ ] };

declare 'MapStringCreateApplicationInstancesRequest',
    as HashRef[CreateApplicationInstancesRequest()];

declare 'DeleteApplicationInstancesRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::DeleteApplicationInstancesRequest'];

coerce 'DeleteApplicationInstancesRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::DeleteApplicationInstancesRequest'->new($_) };

declare 'RepeatedDeleteApplicationInstancesRequest',
    as ArrayRef[DeleteApplicationInstancesRequest()];

coerce 'RepeatedDeleteApplicationInstancesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::DeleteApplicationInstancesRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteApplicationInstancesRequest',
    as HashRef[DeleteApplicationInstancesRequest()];

declare 'DeployApplicationResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::DeployApplicationResponse'];

coerce 'DeployApplicationResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::DeployApplicationResponse'->new($_) };

declare 'RepeatedDeployApplicationResponse',
    as ArrayRef[DeployApplicationResponse()];

coerce 'RepeatedDeployApplicationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::DeployApplicationResponse'->new($_) } @$_ ] };

declare 'MapStringDeployApplicationResponse',
    as HashRef[DeployApplicationResponse()];

declare 'UndeployApplicationResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::UndeployApplicationResponse'];

coerce 'UndeployApplicationResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::UndeployApplicationResponse'->new($_) };

declare 'RepeatedUndeployApplicationResponse',
    as ArrayRef[UndeployApplicationResponse()];

coerce 'RepeatedUndeployApplicationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::UndeployApplicationResponse'->new($_) } @$_ ] };

declare 'MapStringUndeployApplicationResponse',
    as HashRef[UndeployApplicationResponse()];

declare 'RemoveApplicationStreamInputResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::RemoveApplicationStreamInputResponse'];

coerce 'RemoveApplicationStreamInputResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::RemoveApplicationStreamInputResponse'->new($_) };

declare 'RepeatedRemoveApplicationStreamInputResponse',
    as ArrayRef[RemoveApplicationStreamInputResponse()];

coerce 'RepeatedRemoveApplicationStreamInputResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::RemoveApplicationStreamInputResponse'->new($_) } @$_ ] };

declare 'MapStringRemoveApplicationStreamInputResponse',
    as HashRef[RemoveApplicationStreamInputResponse()];

declare 'AddApplicationStreamInputResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::AddApplicationStreamInputResponse'];

coerce 'AddApplicationStreamInputResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::AddApplicationStreamInputResponse'->new($_) };

declare 'RepeatedAddApplicationStreamInputResponse',
    as ArrayRef[AddApplicationStreamInputResponse()];

coerce 'RepeatedAddApplicationStreamInputResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::AddApplicationStreamInputResponse'->new($_) } @$_ ] };

declare 'MapStringAddApplicationStreamInputResponse',
    as HashRef[AddApplicationStreamInputResponse()];

declare 'UpdateApplicationStreamInputResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::UpdateApplicationStreamInputResponse'];

coerce 'UpdateApplicationStreamInputResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::UpdateApplicationStreamInputResponse'->new($_) };

declare 'RepeatedUpdateApplicationStreamInputResponse',
    as ArrayRef[UpdateApplicationStreamInputResponse()];

coerce 'RepeatedUpdateApplicationStreamInputResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::UpdateApplicationStreamInputResponse'->new($_) } @$_ ] };

declare 'MapStringUpdateApplicationStreamInputResponse',
    as HashRef[UpdateApplicationStreamInputResponse()];

declare 'ListApplicationsRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::ListApplicationsRequest'];

coerce 'ListApplicationsRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::ListApplicationsRequest'->new($_) };

declare 'RepeatedListApplicationsRequest',
    as ArrayRef[ListApplicationsRequest()];

coerce 'RepeatedListApplicationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::ListApplicationsRequest'->new($_) } @$_ ] };

declare 'MapStringListApplicationsRequest',
    as HashRef[ListApplicationsRequest()];

declare 'ListApplicationsResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::ListApplicationsResponse'];

coerce 'ListApplicationsResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::ListApplicationsResponse'->new($_) };

declare 'RepeatedListApplicationsResponse',
    as ArrayRef[ListApplicationsResponse()];

coerce 'RepeatedListApplicationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::ListApplicationsResponse'->new($_) } @$_ ] };

declare 'MapStringListApplicationsResponse',
    as HashRef[ListApplicationsResponse()];

declare 'GetApplicationRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::GetApplicationRequest'];

coerce 'GetApplicationRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::GetApplicationRequest'->new($_) };

declare 'RepeatedGetApplicationRequest',
    as ArrayRef[GetApplicationRequest()];

coerce 'RepeatedGetApplicationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::GetApplicationRequest'->new($_) } @$_ ] };

declare 'MapStringGetApplicationRequest',
    as HashRef[GetApplicationRequest()];

declare 'CreateApplicationRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::CreateApplicationRequest'];

coerce 'CreateApplicationRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::CreateApplicationRequest'->new($_) };

declare 'RepeatedCreateApplicationRequest',
    as ArrayRef[CreateApplicationRequest()];

coerce 'RepeatedCreateApplicationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::CreateApplicationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateApplicationRequest',
    as HashRef[CreateApplicationRequest()];

declare 'UpdateApplicationRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::UpdateApplicationRequest'];

coerce 'UpdateApplicationRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::UpdateApplicationRequest'->new($_) };

declare 'RepeatedUpdateApplicationRequest',
    as ArrayRef[UpdateApplicationRequest()];

coerce 'RepeatedUpdateApplicationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::UpdateApplicationRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateApplicationRequest',
    as HashRef[UpdateApplicationRequest()];

declare 'DeleteApplicationRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::DeleteApplicationRequest'];

coerce 'DeleteApplicationRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::DeleteApplicationRequest'->new($_) };

declare 'RepeatedDeleteApplicationRequest',
    as ArrayRef[DeleteApplicationRequest()];

coerce 'RepeatedDeleteApplicationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::DeleteApplicationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteApplicationRequest',
    as HashRef[DeleteApplicationRequest()];

declare 'DeployApplicationRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::DeployApplicationRequest'];

coerce 'DeployApplicationRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::DeployApplicationRequest'->new($_) };

declare 'RepeatedDeployApplicationRequest',
    as ArrayRef[DeployApplicationRequest()];

coerce 'RepeatedDeployApplicationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::DeployApplicationRequest'->new($_) } @$_ ] };

declare 'MapStringDeployApplicationRequest',
    as HashRef[DeployApplicationRequest()];

declare 'UndeployApplicationRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::UndeployApplicationRequest'];

coerce 'UndeployApplicationRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::UndeployApplicationRequest'->new($_) };

declare 'RepeatedUndeployApplicationRequest',
    as ArrayRef[UndeployApplicationRequest()];

coerce 'RepeatedUndeployApplicationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::UndeployApplicationRequest'->new($_) } @$_ ] };

declare 'MapStringUndeployApplicationRequest',
    as HashRef[UndeployApplicationRequest()];

declare 'ApplicationStreamInput',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::ApplicationStreamInput'];

coerce 'ApplicationStreamInput',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::ApplicationStreamInput'->new($_) };

declare 'RepeatedApplicationStreamInput',
    as ArrayRef[ApplicationStreamInput()];

coerce 'RepeatedApplicationStreamInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::ApplicationStreamInput'->new($_) } @$_ ] };

declare 'MapStringApplicationStreamInput',
    as HashRef[ApplicationStreamInput()];

declare 'AddApplicationStreamInputRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::AddApplicationStreamInputRequest'];

coerce 'AddApplicationStreamInputRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::AddApplicationStreamInputRequest'->new($_) };

declare 'RepeatedAddApplicationStreamInputRequest',
    as ArrayRef[AddApplicationStreamInputRequest()];

coerce 'RepeatedAddApplicationStreamInputRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::AddApplicationStreamInputRequest'->new($_) } @$_ ] };

declare 'MapStringAddApplicationStreamInputRequest',
    as HashRef[AddApplicationStreamInputRequest()];

declare 'UpdateApplicationStreamInputRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::UpdateApplicationStreamInputRequest'];

coerce 'UpdateApplicationStreamInputRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::UpdateApplicationStreamInputRequest'->new($_) };

declare 'RepeatedUpdateApplicationStreamInputRequest',
    as ArrayRef[UpdateApplicationStreamInputRequest()];

coerce 'RepeatedUpdateApplicationStreamInputRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::UpdateApplicationStreamInputRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateApplicationStreamInputRequest',
    as HashRef[UpdateApplicationStreamInputRequest()];

declare 'RemoveApplicationStreamInputRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::RemoveApplicationStreamInputRequest'];

coerce 'RemoveApplicationStreamInputRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::RemoveApplicationStreamInputRequest'->new($_) };

declare 'RepeatedRemoveApplicationStreamInputRequest',
    as ArrayRef[RemoveApplicationStreamInputRequest()];

coerce 'RepeatedRemoveApplicationStreamInputRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::RemoveApplicationStreamInputRequest'->new($_) } @$_ ] };

declare 'MapStringRemoveApplicationStreamInputRequest',
    as HashRef[RemoveApplicationStreamInputRequest()];

declare 'TargetStreamInput',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::RemoveApplicationStreamInputRequest::TargetStreamInput'];

coerce 'TargetStreamInput',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::RemoveApplicationStreamInputRequest::TargetStreamInput'->new($_) };

declare 'RepeatedTargetStreamInput',
    as ArrayRef[TargetStreamInput()];

coerce 'RepeatedTargetStreamInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::RemoveApplicationStreamInputRequest::TargetStreamInput'->new($_) } @$_ ] };

declare 'MapStringTargetStreamInput',
    as HashRef[TargetStreamInput()];

declare 'ListInstancesRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::ListInstancesRequest'];

coerce 'ListInstancesRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::ListInstancesRequest'->new($_) };

declare 'RepeatedListInstancesRequest',
    as ArrayRef[ListInstancesRequest()];

coerce 'RepeatedListInstancesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::ListInstancesRequest'->new($_) } @$_ ] };

declare 'MapStringListInstancesRequest',
    as HashRef[ListInstancesRequest()];

declare 'ListInstancesResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::ListInstancesResponse'];

coerce 'ListInstancesResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::ListInstancesResponse'->new($_) };

declare 'RepeatedListInstancesResponse',
    as ArrayRef[ListInstancesResponse()];

coerce 'RepeatedListInstancesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::ListInstancesResponse'->new($_) } @$_ ] };

declare 'MapStringListInstancesResponse',
    as HashRef[ListInstancesResponse()];

declare 'GetInstanceRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::GetInstanceRequest'];

coerce 'GetInstanceRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::GetInstanceRequest'->new($_) };

declare 'RepeatedGetInstanceRequest',
    as ArrayRef[GetInstanceRequest()];

coerce 'RepeatedGetInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::GetInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringGetInstanceRequest',
    as HashRef[GetInstanceRequest()];

declare 'ListDraftsRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::ListDraftsRequest'];

coerce 'ListDraftsRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::ListDraftsRequest'->new($_) };

declare 'RepeatedListDraftsRequest',
    as ArrayRef[ListDraftsRequest()];

coerce 'RepeatedListDraftsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::ListDraftsRequest'->new($_) } @$_ ] };

declare 'MapStringListDraftsRequest',
    as HashRef[ListDraftsRequest()];

declare 'ListDraftsResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::ListDraftsResponse'];

coerce 'ListDraftsResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::ListDraftsResponse'->new($_) };

declare 'RepeatedListDraftsResponse',
    as ArrayRef[ListDraftsResponse()];

coerce 'RepeatedListDraftsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::ListDraftsResponse'->new($_) } @$_ ] };

declare 'MapStringListDraftsResponse',
    as HashRef[ListDraftsResponse()];

declare 'GetDraftRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::GetDraftRequest'];

coerce 'GetDraftRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::GetDraftRequest'->new($_) };

declare 'RepeatedGetDraftRequest',
    as ArrayRef[GetDraftRequest()];

coerce 'RepeatedGetDraftRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::GetDraftRequest'->new($_) } @$_ ] };

declare 'MapStringGetDraftRequest',
    as HashRef[GetDraftRequest()];

declare 'CreateDraftRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::CreateDraftRequest'];

coerce 'CreateDraftRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::CreateDraftRequest'->new($_) };

declare 'RepeatedCreateDraftRequest',
    as ArrayRef[CreateDraftRequest()];

coerce 'RepeatedCreateDraftRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::CreateDraftRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDraftRequest',
    as HashRef[CreateDraftRequest()];

declare 'UpdateDraftRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::UpdateDraftRequest'];

coerce 'UpdateDraftRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::UpdateDraftRequest'->new($_) };

declare 'RepeatedUpdateDraftRequest',
    as ArrayRef[UpdateDraftRequest()];

coerce 'RepeatedUpdateDraftRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::UpdateDraftRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDraftRequest',
    as HashRef[UpdateDraftRequest()];

declare 'UpdateApplicationInstancesRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::UpdateApplicationInstancesRequest'];

coerce 'UpdateApplicationInstancesRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::UpdateApplicationInstancesRequest'->new($_) };

declare 'RepeatedUpdateApplicationInstancesRequest',
    as ArrayRef[UpdateApplicationInstancesRequest()];

coerce 'RepeatedUpdateApplicationInstancesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::UpdateApplicationInstancesRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateApplicationInstancesRequest',
    as HashRef[UpdateApplicationInstancesRequest()];

declare 'UpdateApplicationInstance',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::UpdateApplicationInstancesRequest::UpdateApplicationInstance'];

coerce 'UpdateApplicationInstance',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::UpdateApplicationInstancesRequest::UpdateApplicationInstance'->new($_) };

declare 'RepeatedUpdateApplicationInstance',
    as ArrayRef[UpdateApplicationInstance()];

coerce 'RepeatedUpdateApplicationInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::UpdateApplicationInstancesRequest::UpdateApplicationInstance'->new($_) } @$_ ] };

declare 'MapStringUpdateApplicationInstance',
    as HashRef[UpdateApplicationInstance()];

declare 'DeleteDraftRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::DeleteDraftRequest'];

coerce 'DeleteDraftRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::DeleteDraftRequest'->new($_) };

declare 'RepeatedDeleteDraftRequest',
    as ArrayRef[DeleteDraftRequest()];

coerce 'RepeatedDeleteDraftRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::DeleteDraftRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDraftRequest',
    as HashRef[DeleteDraftRequest()];

declare 'ListProcessorsRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::ListProcessorsRequest'];

coerce 'ListProcessorsRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::ListProcessorsRequest'->new($_) };

declare 'RepeatedListProcessorsRequest',
    as ArrayRef[ListProcessorsRequest()];

coerce 'RepeatedListProcessorsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::ListProcessorsRequest'->new($_) } @$_ ] };

declare 'MapStringListProcessorsRequest',
    as HashRef[ListProcessorsRequest()];

declare 'ListProcessorsResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::ListProcessorsResponse'];

coerce 'ListProcessorsResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::ListProcessorsResponse'->new($_) };

declare 'RepeatedListProcessorsResponse',
    as ArrayRef[ListProcessorsResponse()];

coerce 'RepeatedListProcessorsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::ListProcessorsResponse'->new($_) } @$_ ] };

declare 'MapStringListProcessorsResponse',
    as HashRef[ListProcessorsResponse()];

declare 'ListPrebuiltProcessorsRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::ListPrebuiltProcessorsRequest'];

coerce 'ListPrebuiltProcessorsRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::ListPrebuiltProcessorsRequest'->new($_) };

declare 'RepeatedListPrebuiltProcessorsRequest',
    as ArrayRef[ListPrebuiltProcessorsRequest()];

coerce 'RepeatedListPrebuiltProcessorsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::ListPrebuiltProcessorsRequest'->new($_) } @$_ ] };

declare 'MapStringListPrebuiltProcessorsRequest',
    as HashRef[ListPrebuiltProcessorsRequest()];

declare 'ListPrebuiltProcessorsResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::ListPrebuiltProcessorsResponse'];

coerce 'ListPrebuiltProcessorsResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::ListPrebuiltProcessorsResponse'->new($_) };

declare 'RepeatedListPrebuiltProcessorsResponse',
    as ArrayRef[ListPrebuiltProcessorsResponse()];

coerce 'RepeatedListPrebuiltProcessorsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::ListPrebuiltProcessorsResponse'->new($_) } @$_ ] };

declare 'MapStringListPrebuiltProcessorsResponse',
    as HashRef[ListPrebuiltProcessorsResponse()];

declare 'GetProcessorRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::GetProcessorRequest'];

coerce 'GetProcessorRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::GetProcessorRequest'->new($_) };

declare 'RepeatedGetProcessorRequest',
    as ArrayRef[GetProcessorRequest()];

coerce 'RepeatedGetProcessorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::GetProcessorRequest'->new($_) } @$_ ] };

declare 'MapStringGetProcessorRequest',
    as HashRef[GetProcessorRequest()];

declare 'CreateProcessorRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::CreateProcessorRequest'];

coerce 'CreateProcessorRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::CreateProcessorRequest'->new($_) };

declare 'RepeatedCreateProcessorRequest',
    as ArrayRef[CreateProcessorRequest()];

coerce 'RepeatedCreateProcessorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::CreateProcessorRequest'->new($_) } @$_ ] };

declare 'MapStringCreateProcessorRequest',
    as HashRef[CreateProcessorRequest()];

declare 'UpdateProcessorRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::UpdateProcessorRequest'];

coerce 'UpdateProcessorRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::UpdateProcessorRequest'->new($_) };

declare 'RepeatedUpdateProcessorRequest',
    as ArrayRef[UpdateProcessorRequest()];

coerce 'RepeatedUpdateProcessorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::UpdateProcessorRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateProcessorRequest',
    as HashRef[UpdateProcessorRequest()];

declare 'DeleteProcessorRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::DeleteProcessorRequest'];

coerce 'DeleteProcessorRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::DeleteProcessorRequest'->new($_) };

declare 'RepeatedDeleteProcessorRequest',
    as ArrayRef[DeleteProcessorRequest()];

coerce 'RepeatedDeleteProcessorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::DeleteProcessorRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteProcessorRequest',
    as HashRef[DeleteProcessorRequest()];

declare 'Application',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::Application'];

coerce 'Application',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::Application'->new($_) };

declare 'RepeatedApplication',
    as ArrayRef[Application()];

coerce 'RepeatedApplication',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::Application'->new($_) } @$_ ] };

declare 'MapStringApplication',
    as HashRef[Application()];

declare 'State',
    as (Int | Str);

declare 'BillingMode',
    as (Int | Str);

declare 'ApplicationRuntimeInfo',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::Application::ApplicationRuntimeInfo'];

coerce 'ApplicationRuntimeInfo',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::Application::ApplicationRuntimeInfo'->new($_) };

declare 'RepeatedApplicationRuntimeInfo',
    as ArrayRef[ApplicationRuntimeInfo()];

coerce 'RepeatedApplicationRuntimeInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::Application::ApplicationRuntimeInfo'->new($_) } @$_ ] };

declare 'MapStringApplicationRuntimeInfo',
    as HashRef[ApplicationRuntimeInfo()];

declare 'GlobalOutputResource',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::Application::ApplicationRuntimeInfo::GlobalOutputResource'];

coerce 'GlobalOutputResource',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::Application::ApplicationRuntimeInfo::GlobalOutputResource'->new($_) };

declare 'RepeatedGlobalOutputResource',
    as ArrayRef[GlobalOutputResource()];

coerce 'RepeatedGlobalOutputResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::Application::ApplicationRuntimeInfo::GlobalOutputResource'->new($_) } @$_ ] };

declare 'MapStringGlobalOutputResource',
    as HashRef[GlobalOutputResource()];

declare 'MonitoringConfig',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::Application::ApplicationRuntimeInfo::MonitoringConfig'];

coerce 'MonitoringConfig',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::Application::ApplicationRuntimeInfo::MonitoringConfig'->new($_) };

declare 'RepeatedMonitoringConfig',
    as ArrayRef[MonitoringConfig()];

coerce 'RepeatedMonitoringConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::Application::ApplicationRuntimeInfo::MonitoringConfig'->new($_) } @$_ ] };

declare 'MapStringMonitoringConfig',
    as HashRef[MonitoringConfig()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::Application::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::Application::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::Application::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ApplicationConfigs',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::ApplicationConfigs'];

coerce 'ApplicationConfigs',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::ApplicationConfigs'->new($_) };

declare 'RepeatedApplicationConfigs',
    as ArrayRef[ApplicationConfigs()];

coerce 'RepeatedApplicationConfigs',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::ApplicationConfigs'->new($_) } @$_ ] };

declare 'MapStringApplicationConfigs',
    as HashRef[ApplicationConfigs()];

declare 'EventDeliveryConfig',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::ApplicationConfigs::EventDeliveryConfig'];

coerce 'EventDeliveryConfig',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::ApplicationConfigs::EventDeliveryConfig'->new($_) };

declare 'RepeatedEventDeliveryConfig',
    as ArrayRef[EventDeliveryConfig()];

coerce 'RepeatedEventDeliveryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::ApplicationConfigs::EventDeliveryConfig'->new($_) } @$_ ] };

declare 'MapStringEventDeliveryConfig',
    as HashRef[EventDeliveryConfig()];

declare 'Node',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::Node'];

coerce 'Node',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::Node'->new($_) };

declare 'RepeatedNode',
    as ArrayRef[Node()];

coerce 'RepeatedNode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::Node'->new($_) } @$_ ] };

declare 'MapStringNode',
    as HashRef[Node()];

declare 'InputEdge',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::Node::InputEdge'];

coerce 'InputEdge',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::Node::InputEdge'->new($_) };

declare 'RepeatedInputEdge',
    as ArrayRef[InputEdge()];

coerce 'RepeatedInputEdge',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::Node::InputEdge'->new($_) } @$_ ] };

declare 'MapStringInputEdge',
    as HashRef[InputEdge()];

declare 'Draft',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::Draft'];

coerce 'Draft',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::Draft'->new($_) };

declare 'RepeatedDraft',
    as ArrayRef[Draft()];

coerce 'RepeatedDraft',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::Draft'->new($_) } @$_ ] };

declare 'MapStringDraft',
    as HashRef[Draft()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::Draft::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::Draft::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::Draft::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Instance',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::Instance'];

coerce 'Instance',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::Instance'->new($_) };

declare 'RepeatedInstance',
    as ArrayRef[Instance()];

coerce 'RepeatedInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::Instance'->new($_) } @$_ ] };

declare 'MapStringInstance',
    as HashRef[Instance()];

declare 'InstanceType',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'InputResource',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::Instance::InputResource'];

coerce 'InputResource',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::Instance::InputResource'->new($_) };

declare 'RepeatedInputResource',
    as ArrayRef[InputResource()];

coerce 'RepeatedInputResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::Instance::InputResource'->new($_) } @$_ ] };

declare 'MapStringInputResource',
    as HashRef[InputResource()];

declare 'OutputResource',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::Instance::OutputResource'];

coerce 'OutputResource',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::Instance::OutputResource'->new($_) };

declare 'RepeatedOutputResource',
    as ArrayRef[OutputResource()];

coerce 'RepeatedOutputResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::Instance::OutputResource'->new($_) } @$_ ] };

declare 'MapStringOutputResource',
    as HashRef[OutputResource()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::Instance::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::Instance::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::Instance::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ApplicationInstance',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::ApplicationInstance'];

coerce 'ApplicationInstance',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::ApplicationInstance'->new($_) };

declare 'RepeatedApplicationInstance',
    as ArrayRef[ApplicationInstance()];

coerce 'RepeatedApplicationInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::ApplicationInstance'->new($_) } @$_ ] };

declare 'MapStringApplicationInstance',
    as HashRef[ApplicationInstance()];

declare 'Processor',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::Processor'];

coerce 'Processor',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::Processor'->new($_) };

declare 'RepeatedProcessor',
    as ArrayRef[Processor()];

coerce 'RepeatedProcessor',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::Processor'->new($_) } @$_ ] };

declare 'MapStringProcessor',
    as HashRef[Processor()];

declare 'ProcessorType',
    as (Int | Str);

declare 'ProcessorState',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::Processor::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::Processor::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::Processor::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ProcessorIOSpec',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::ProcessorIOSpec'];

coerce 'ProcessorIOSpec',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::ProcessorIOSpec'->new($_) };

declare 'RepeatedProcessorIOSpec',
    as ArrayRef[ProcessorIOSpec()];

coerce 'RepeatedProcessorIOSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::ProcessorIOSpec'->new($_) } @$_ ] };

declare 'MapStringProcessorIOSpec',
    as HashRef[ProcessorIOSpec()];

declare 'GraphInputChannelSpec',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::ProcessorIOSpec::GraphInputChannelSpec'];

coerce 'GraphInputChannelSpec',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::ProcessorIOSpec::GraphInputChannelSpec'->new($_) };

declare 'RepeatedGraphInputChannelSpec',
    as ArrayRef[GraphInputChannelSpec()];

coerce 'RepeatedGraphInputChannelSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::ProcessorIOSpec::GraphInputChannelSpec'->new($_) } @$_ ] };

declare 'MapStringGraphInputChannelSpec',
    as HashRef[GraphInputChannelSpec()];

declare 'GraphOutputChannelSpec',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::ProcessorIOSpec::GraphOutputChannelSpec'];

coerce 'GraphOutputChannelSpec',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::ProcessorIOSpec::GraphOutputChannelSpec'->new($_) };

declare 'RepeatedGraphOutputChannelSpec',
    as ArrayRef[GraphOutputChannelSpec()];

coerce 'RepeatedGraphOutputChannelSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::ProcessorIOSpec::GraphOutputChannelSpec'->new($_) } @$_ ] };

declare 'MapStringGraphOutputChannelSpec',
    as HashRef[GraphOutputChannelSpec()];

declare 'InstanceResourceInputBindingSpec',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::ProcessorIOSpec::InstanceResourceInputBindingSpec'];

coerce 'InstanceResourceInputBindingSpec',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::ProcessorIOSpec::InstanceResourceInputBindingSpec'->new($_) };

declare 'RepeatedInstanceResourceInputBindingSpec',
    as ArrayRef[InstanceResourceInputBindingSpec()];

coerce 'RepeatedInstanceResourceInputBindingSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::ProcessorIOSpec::InstanceResourceInputBindingSpec'->new($_) } @$_ ] };

declare 'MapStringInstanceResourceInputBindingSpec',
    as HashRef[InstanceResourceInputBindingSpec()];

declare 'InstanceResourceOutputBindingSpec',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::ProcessorIOSpec::InstanceResourceOutputBindingSpec'];

coerce 'InstanceResourceOutputBindingSpec',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::ProcessorIOSpec::InstanceResourceOutputBindingSpec'->new($_) };

declare 'RepeatedInstanceResourceOutputBindingSpec',
    as ArrayRef[InstanceResourceOutputBindingSpec()];

coerce 'RepeatedInstanceResourceOutputBindingSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::ProcessorIOSpec::InstanceResourceOutputBindingSpec'->new($_) } @$_ ] };

declare 'MapStringInstanceResourceOutputBindingSpec',
    as HashRef[InstanceResourceOutputBindingSpec()];

declare 'CustomProcessorSourceInfo',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::CustomProcessorSourceInfo'];

coerce 'CustomProcessorSourceInfo',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::CustomProcessorSourceInfo'->new($_) };

declare 'RepeatedCustomProcessorSourceInfo',
    as ArrayRef[CustomProcessorSourceInfo()];

coerce 'RepeatedCustomProcessorSourceInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::CustomProcessorSourceInfo'->new($_) } @$_ ] };

declare 'MapStringCustomProcessorSourceInfo',
    as HashRef[CustomProcessorSourceInfo()];

declare 'SourceType',
    as (Int | Str);

declare 'ProductRecognizerArtifact',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::CustomProcessorSourceInfo::ProductRecognizerArtifact'];

coerce 'ProductRecognizerArtifact',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::CustomProcessorSourceInfo::ProductRecognizerArtifact'->new($_) };

declare 'RepeatedProductRecognizerArtifact',
    as ArrayRef[ProductRecognizerArtifact()];

coerce 'RepeatedProductRecognizerArtifact',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::CustomProcessorSourceInfo::ProductRecognizerArtifact'->new($_) } @$_ ] };

declare 'MapStringProductRecognizerArtifact',
    as HashRef[ProductRecognizerArtifact()];

declare 'ModelSchema',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::CustomProcessorSourceInfo::ModelSchema'];

coerce 'ModelSchema',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::CustomProcessorSourceInfo::ModelSchema'->new($_) };

declare 'RepeatedModelSchema',
    as ArrayRef[ModelSchema()];

coerce 'RepeatedModelSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::CustomProcessorSourceInfo::ModelSchema'->new($_) } @$_ ] };

declare 'MapStringModelSchema',
    as HashRef[ModelSchema()];

declare 'AdditionalInfoEntry',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::CustomProcessorSourceInfo::AdditionalInfoEntry'];

coerce 'AdditionalInfoEntry',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::CustomProcessorSourceInfo::AdditionalInfoEntry'->new($_) };

declare 'RepeatedAdditionalInfoEntry',
    as ArrayRef[AdditionalInfoEntry()];

coerce 'RepeatedAdditionalInfoEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::CustomProcessorSourceInfo::AdditionalInfoEntry'->new($_) } @$_ ] };

declare 'MapStringAdditionalInfoEntry',
    as HashRef[AdditionalInfoEntry()];

declare 'ProcessorConfig',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::ProcessorConfig'];

coerce 'ProcessorConfig',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::ProcessorConfig'->new($_) };

declare 'RepeatedProcessorConfig',
    as ArrayRef[ProcessorConfig()];

coerce 'RepeatedProcessorConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::ProcessorConfig'->new($_) } @$_ ] };

declare 'MapStringProcessorConfig',
    as HashRef[ProcessorConfig()];

declare 'StreamWithAnnotation',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::StreamWithAnnotation'];

coerce 'StreamWithAnnotation',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::StreamWithAnnotation'->new($_) };

declare 'RepeatedStreamWithAnnotation',
    as ArrayRef[StreamWithAnnotation()];

coerce 'RepeatedStreamWithAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::StreamWithAnnotation'->new($_) } @$_ ] };

declare 'MapStringStreamWithAnnotation',
    as HashRef[StreamWithAnnotation()];

declare 'NodeAnnotation',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::StreamWithAnnotation::NodeAnnotation'];

coerce 'NodeAnnotation',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::StreamWithAnnotation::NodeAnnotation'->new($_) };

declare 'RepeatedNodeAnnotation',
    as ArrayRef[NodeAnnotation()];

coerce 'RepeatedNodeAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::StreamWithAnnotation::NodeAnnotation'->new($_) } @$_ ] };

declare 'MapStringNodeAnnotation',
    as HashRef[NodeAnnotation()];

declare 'ApplicationNodeAnnotation',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::ApplicationNodeAnnotation'];

coerce 'ApplicationNodeAnnotation',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::ApplicationNodeAnnotation'->new($_) };

declare 'RepeatedApplicationNodeAnnotation',
    as ArrayRef[ApplicationNodeAnnotation()];

coerce 'RepeatedApplicationNodeAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::ApplicationNodeAnnotation'->new($_) } @$_ ] };

declare 'MapStringApplicationNodeAnnotation',
    as HashRef[ApplicationNodeAnnotation()];

declare 'ResourceAnnotations',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::ResourceAnnotations'];

coerce 'ResourceAnnotations',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::ResourceAnnotations'->new($_) };

declare 'RepeatedResourceAnnotations',
    as ArrayRef[ResourceAnnotations()];

coerce 'RepeatedResourceAnnotations',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::ResourceAnnotations'->new($_) } @$_ ] };

declare 'MapStringResourceAnnotations',
    as HashRef[ResourceAnnotations()];

declare 'VideoStreamInputConfig',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::VideoStreamInputConfig'];

coerce 'VideoStreamInputConfig',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::VideoStreamInputConfig'->new($_) };

declare 'RepeatedVideoStreamInputConfig',
    as ArrayRef[VideoStreamInputConfig()];

coerce 'RepeatedVideoStreamInputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::VideoStreamInputConfig'->new($_) } @$_ ] };

declare 'MapStringVideoStreamInputConfig',
    as HashRef[VideoStreamInputConfig()];

declare 'AIEnabledDevicesInputConfig',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::AIEnabledDevicesInputConfig'];

coerce 'AIEnabledDevicesInputConfig',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::AIEnabledDevicesInputConfig'->new($_) };

declare 'RepeatedAIEnabledDevicesInputConfig',
    as ArrayRef[AIEnabledDevicesInputConfig()];

coerce 'RepeatedAIEnabledDevicesInputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::AIEnabledDevicesInputConfig'->new($_) } @$_ ] };

declare 'MapStringAIEnabledDevicesInputConfig',
    as HashRef[AIEnabledDevicesInputConfig()];

declare 'MediaWarehouseConfig',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::MediaWarehouseConfig'];

coerce 'MediaWarehouseConfig',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::MediaWarehouseConfig'->new($_) };

declare 'RepeatedMediaWarehouseConfig',
    as ArrayRef[MediaWarehouseConfig()];

coerce 'RepeatedMediaWarehouseConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::MediaWarehouseConfig'->new($_) } @$_ ] };

declare 'MapStringMediaWarehouseConfig',
    as HashRef[MediaWarehouseConfig()];

declare 'PersonBlurConfig',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::PersonBlurConfig'];

coerce 'PersonBlurConfig',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::PersonBlurConfig'->new($_) };

declare 'RepeatedPersonBlurConfig',
    as ArrayRef[PersonBlurConfig()];

coerce 'RepeatedPersonBlurConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::PersonBlurConfig'->new($_) } @$_ ] };

declare 'MapStringPersonBlurConfig',
    as HashRef[PersonBlurConfig()];

declare 'PersonBlurType',
    as (Int | Str);

declare 'OccupancyCountConfig',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::OccupancyCountConfig'];

coerce 'OccupancyCountConfig',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::OccupancyCountConfig'->new($_) };

declare 'RepeatedOccupancyCountConfig',
    as ArrayRef[OccupancyCountConfig()];

coerce 'RepeatedOccupancyCountConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::OccupancyCountConfig'->new($_) } @$_ ] };

declare 'MapStringOccupancyCountConfig',
    as HashRef[OccupancyCountConfig()];

declare 'PersonVehicleDetectionConfig',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::PersonVehicleDetectionConfig'];

coerce 'PersonVehicleDetectionConfig',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::PersonVehicleDetectionConfig'->new($_) };

declare 'RepeatedPersonVehicleDetectionConfig',
    as ArrayRef[PersonVehicleDetectionConfig()];

coerce 'RepeatedPersonVehicleDetectionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::PersonVehicleDetectionConfig'->new($_) } @$_ ] };

declare 'MapStringPersonVehicleDetectionConfig',
    as HashRef[PersonVehicleDetectionConfig()];

declare 'PersonalProtectiveEquipmentDetectionConfig',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::PersonalProtectiveEquipmentDetectionConfig'];

coerce 'PersonalProtectiveEquipmentDetectionConfig',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::PersonalProtectiveEquipmentDetectionConfig'->new($_) };

declare 'RepeatedPersonalProtectiveEquipmentDetectionConfig',
    as ArrayRef[PersonalProtectiveEquipmentDetectionConfig()];

coerce 'RepeatedPersonalProtectiveEquipmentDetectionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::PersonalProtectiveEquipmentDetectionConfig'->new($_) } @$_ ] };

declare 'MapStringPersonalProtectiveEquipmentDetectionConfig',
    as HashRef[PersonalProtectiveEquipmentDetectionConfig()];

declare 'GeneralObjectDetectionConfig',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::GeneralObjectDetectionConfig'];

coerce 'GeneralObjectDetectionConfig',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::GeneralObjectDetectionConfig'->new($_) };

declare 'RepeatedGeneralObjectDetectionConfig',
    as ArrayRef[GeneralObjectDetectionConfig()];

coerce 'RepeatedGeneralObjectDetectionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::GeneralObjectDetectionConfig'->new($_) } @$_ ] };

declare 'MapStringGeneralObjectDetectionConfig',
    as HashRef[GeneralObjectDetectionConfig()];

declare 'BigQueryConfig',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::BigQueryConfig'];

coerce 'BigQueryConfig',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::BigQueryConfig'->new($_) };

declare 'RepeatedBigQueryConfig',
    as ArrayRef[BigQueryConfig()];

coerce 'RepeatedBigQueryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::BigQueryConfig'->new($_) } @$_ ] };

declare 'MapStringBigQueryConfig',
    as HashRef[BigQueryConfig()];

declare 'CloudFunctionMappingEntry',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::BigQueryConfig::CloudFunctionMappingEntry'];

coerce 'CloudFunctionMappingEntry',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::BigQueryConfig::CloudFunctionMappingEntry'->new($_) };

declare 'RepeatedCloudFunctionMappingEntry',
    as ArrayRef[CloudFunctionMappingEntry()];

coerce 'RepeatedCloudFunctionMappingEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::BigQueryConfig::CloudFunctionMappingEntry'->new($_) } @$_ ] };

declare 'MapStringCloudFunctionMappingEntry',
    as HashRef[CloudFunctionMappingEntry()];

declare 'VertexAutoMLVisionConfig',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::VertexAutoMLVisionConfig'];

coerce 'VertexAutoMLVisionConfig',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::VertexAutoMLVisionConfig'->new($_) };

declare 'RepeatedVertexAutoMLVisionConfig',
    as ArrayRef[VertexAutoMLVisionConfig()];

coerce 'RepeatedVertexAutoMLVisionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::VertexAutoMLVisionConfig'->new($_) } @$_ ] };

declare 'MapStringVertexAutoMLVisionConfig',
    as HashRef[VertexAutoMLVisionConfig()];

declare 'VertexAutoMLVideoConfig',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::VertexAutoMLVideoConfig'];

coerce 'VertexAutoMLVideoConfig',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::VertexAutoMLVideoConfig'->new($_) };

declare 'RepeatedVertexAutoMLVideoConfig',
    as ArrayRef[VertexAutoMLVideoConfig()];

coerce 'RepeatedVertexAutoMLVideoConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::VertexAutoMLVideoConfig'->new($_) } @$_ ] };

declare 'MapStringVertexAutoMLVideoConfig',
    as HashRef[VertexAutoMLVideoConfig()];

declare 'VertexCustomConfig',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::VertexCustomConfig'];

coerce 'VertexCustomConfig',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::VertexCustomConfig'->new($_) };

declare 'RepeatedVertexCustomConfig',
    as ArrayRef[VertexCustomConfig()];

coerce 'RepeatedVertexCustomConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::VertexCustomConfig'->new($_) } @$_ ] };

declare 'MapStringVertexCustomConfig',
    as HashRef[VertexCustomConfig()];

declare 'GcsOutputConfig',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::GcsOutputConfig'];

coerce 'GcsOutputConfig',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::GcsOutputConfig'->new($_) };

declare 'RepeatedGcsOutputConfig',
    as ArrayRef[GcsOutputConfig()];

coerce 'RepeatedGcsOutputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::GcsOutputConfig'->new($_) } @$_ ] };

declare 'MapStringGcsOutputConfig',
    as HashRef[GcsOutputConfig()];

declare 'UniversalInputConfig',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::UniversalInputConfig'];

coerce 'UniversalInputConfig',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::UniversalInputConfig'->new($_) };

declare 'RepeatedUniversalInputConfig',
    as ArrayRef[UniversalInputConfig()];

coerce 'RepeatedUniversalInputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::UniversalInputConfig'->new($_) } @$_ ] };

declare 'MapStringUniversalInputConfig',
    as HashRef[UniversalInputConfig()];

declare 'MachineSpec',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::MachineSpec'];

coerce 'MachineSpec',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::MachineSpec'->new($_) };

declare 'RepeatedMachineSpec',
    as ArrayRef[MachineSpec()];

coerce 'RepeatedMachineSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::MachineSpec'->new($_) } @$_ ] };

declare 'MapStringMachineSpec',
    as HashRef[MachineSpec()];

declare 'AutoscalingMetricSpec',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::AutoscalingMetricSpec'];

coerce 'AutoscalingMetricSpec',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::AutoscalingMetricSpec'->new($_) };

declare 'RepeatedAutoscalingMetricSpec',
    as ArrayRef[AutoscalingMetricSpec()];

coerce 'RepeatedAutoscalingMetricSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::AutoscalingMetricSpec'->new($_) } @$_ ] };

declare 'MapStringAutoscalingMetricSpec',
    as HashRef[AutoscalingMetricSpec()];

declare 'DedicatedResources',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::DedicatedResources'];

coerce 'DedicatedResources',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::DedicatedResources'->new($_) };

declare 'RepeatedDedicatedResources',
    as ArrayRef[DedicatedResources()];

coerce 'RepeatedDedicatedResources',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::DedicatedResources'->new($_) } @$_ ] };

declare 'MapStringDedicatedResources',
    as HashRef[DedicatedResources()];

declare 'ProductRecognizerConfig',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::ProductRecognizerConfig'];

coerce 'ProductRecognizerConfig',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::ProductRecognizerConfig'->new($_) };

declare 'RepeatedProductRecognizerConfig',
    as ArrayRef[ProductRecognizerConfig()];

coerce 'RepeatedProductRecognizerConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::ProductRecognizerConfig'->new($_) } @$_ ] };

declare 'MapStringProductRecognizerConfig',
    as HashRef[ProductRecognizerConfig()];

declare 'TagRecognizerConfig',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::TagRecognizerConfig'];

coerce 'TagRecognizerConfig',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::TagRecognizerConfig'->new($_) };

declare 'RepeatedTagRecognizerConfig',
    as ArrayRef[TagRecognizerConfig()];

coerce 'RepeatedTagRecognizerConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::TagRecognizerConfig'->new($_) } @$_ ] };

declare 'MapStringTagRecognizerConfig',
    as HashRef[TagRecognizerConfig()];

declare 'TagParsingConfig',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::TagParsingConfig'];

coerce 'TagParsingConfig',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::TagParsingConfig'->new($_) };

declare 'RepeatedTagParsingConfig',
    as ArrayRef[TagParsingConfig()];

coerce 'RepeatedTagParsingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::TagParsingConfig'->new($_) } @$_ ] };

declare 'MapStringTagParsingConfig',
    as HashRef[TagParsingConfig()];

declare 'EntityParsingConfig',
    as InstanceOf['Google::Cloud::Visionai::V1::Platform::TagParsingConfig::EntityParsingConfig'];

coerce 'EntityParsingConfig',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Platform::TagParsingConfig::EntityParsingConfig'->new($_) };

declare 'RepeatedEntityParsingConfig',
    as ArrayRef[EntityParsingConfig()];

coerce 'RepeatedEntityParsingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Platform::TagParsingConfig::EntityParsingConfig'->new($_) } @$_ ] };

declare 'MapStringEntityParsingConfig',
    as HashRef[EntityParsingConfig()];

declare 'EntityMatchingStrategy',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Visionai::V1::Platform::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
