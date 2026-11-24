package Google::Cloud::Documentai::V1::DocumentProcessorService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ProcessOptions',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::ProcessOptions'];

coerce 'ProcessOptions',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ProcessOptions'->new($_) };

declare 'RepeatedProcessOptions',
    as ArrayRef[ProcessOptions()];

coerce 'RepeatedProcessOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ProcessOptions'->new($_) } @$_ ] };

declare 'MapStringProcessOptions',
    as HashRef[ProcessOptions()];

declare 'LayoutConfig',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::ProcessOptions::LayoutConfig'];

coerce 'LayoutConfig',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ProcessOptions::LayoutConfig'->new($_) };

declare 'RepeatedLayoutConfig',
    as ArrayRef[LayoutConfig()];

coerce 'RepeatedLayoutConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ProcessOptions::LayoutConfig'->new($_) } @$_ ] };

declare 'MapStringLayoutConfig',
    as HashRef[LayoutConfig()];

declare 'ChunkingConfig',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::ProcessOptions::LayoutConfig::ChunkingConfig'];

coerce 'ChunkingConfig',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ProcessOptions::LayoutConfig::ChunkingConfig'->new($_) };

declare 'RepeatedChunkingConfig',
    as ArrayRef[ChunkingConfig()];

coerce 'RepeatedChunkingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ProcessOptions::LayoutConfig::ChunkingConfig'->new($_) } @$_ ] };

declare 'MapStringChunkingConfig',
    as HashRef[ChunkingConfig()];

declare 'IndividualPageSelector',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::ProcessOptions::IndividualPageSelector'];

coerce 'IndividualPageSelector',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ProcessOptions::IndividualPageSelector'->new($_) };

declare 'RepeatedIndividualPageSelector',
    as ArrayRef[IndividualPageSelector()];

coerce 'RepeatedIndividualPageSelector',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ProcessOptions::IndividualPageSelector'->new($_) } @$_ ] };

declare 'MapStringIndividualPageSelector',
    as HashRef[IndividualPageSelector()];

declare 'ProcessRequest',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::ProcessRequest'];

coerce 'ProcessRequest',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ProcessRequest'->new($_) };

declare 'RepeatedProcessRequest',
    as ArrayRef[ProcessRequest()];

coerce 'RepeatedProcessRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ProcessRequest'->new($_) } @$_ ] };

declare 'MapStringProcessRequest',
    as HashRef[ProcessRequest()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::ProcessRequest::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ProcessRequest::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ProcessRequest::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'HumanReviewStatus',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::HumanReviewStatus'];

coerce 'HumanReviewStatus',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::HumanReviewStatus'->new($_) };

declare 'RepeatedHumanReviewStatus',
    as ArrayRef[HumanReviewStatus()];

coerce 'RepeatedHumanReviewStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::HumanReviewStatus'->new($_) } @$_ ] };

declare 'MapStringHumanReviewStatus',
    as HashRef[HumanReviewStatus()];

declare 'State',
    as (Int | Str);

declare 'ProcessResponse',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::ProcessResponse'];

coerce 'ProcessResponse',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ProcessResponse'->new($_) };

declare 'RepeatedProcessResponse',
    as ArrayRef[ProcessResponse()];

coerce 'RepeatedProcessResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ProcessResponse'->new($_) } @$_ ] };

declare 'MapStringProcessResponse',
    as HashRef[ProcessResponse()];

declare 'BatchProcessRequest',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::BatchProcessRequest'];

coerce 'BatchProcessRequest',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::BatchProcessRequest'->new($_) };

declare 'RepeatedBatchProcessRequest',
    as ArrayRef[BatchProcessRequest()];

coerce 'RepeatedBatchProcessRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::BatchProcessRequest'->new($_) } @$_ ] };

declare 'MapStringBatchProcessRequest',
    as HashRef[BatchProcessRequest()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::BatchProcessRequest::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::BatchProcessRequest::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::BatchProcessRequest::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'BatchProcessResponse',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::BatchProcessResponse'];

coerce 'BatchProcessResponse',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::BatchProcessResponse'->new($_) };

declare 'RepeatedBatchProcessResponse',
    as ArrayRef[BatchProcessResponse()];

coerce 'RepeatedBatchProcessResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::BatchProcessResponse'->new($_) } @$_ ] };

declare 'MapStringBatchProcessResponse',
    as HashRef[BatchProcessResponse()];

declare 'BatchProcessMetadata',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::BatchProcessMetadata'];

coerce 'BatchProcessMetadata',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::BatchProcessMetadata'->new($_) };

declare 'RepeatedBatchProcessMetadata',
    as ArrayRef[BatchProcessMetadata()];

coerce 'RepeatedBatchProcessMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::BatchProcessMetadata'->new($_) } @$_ ] };

declare 'MapStringBatchProcessMetadata',
    as HashRef[BatchProcessMetadata()];

declare 'State',
    as (Int | Str);

declare 'IndividualProcessStatus',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::BatchProcessMetadata::IndividualProcessStatus'];

coerce 'IndividualProcessStatus',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::BatchProcessMetadata::IndividualProcessStatus'->new($_) };

declare 'RepeatedIndividualProcessStatus',
    as ArrayRef[IndividualProcessStatus()];

coerce 'RepeatedIndividualProcessStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::BatchProcessMetadata::IndividualProcessStatus'->new($_) } @$_ ] };

declare 'MapStringIndividualProcessStatus',
    as HashRef[IndividualProcessStatus()];

declare 'FetchProcessorTypesRequest',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::FetchProcessorTypesRequest'];

coerce 'FetchProcessorTypesRequest',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::FetchProcessorTypesRequest'->new($_) };

declare 'RepeatedFetchProcessorTypesRequest',
    as ArrayRef[FetchProcessorTypesRequest()];

coerce 'RepeatedFetchProcessorTypesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::FetchProcessorTypesRequest'->new($_) } @$_ ] };

declare 'MapStringFetchProcessorTypesRequest',
    as HashRef[FetchProcessorTypesRequest()];

declare 'FetchProcessorTypesResponse',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::FetchProcessorTypesResponse'];

coerce 'FetchProcessorTypesResponse',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::FetchProcessorTypesResponse'->new($_) };

declare 'RepeatedFetchProcessorTypesResponse',
    as ArrayRef[FetchProcessorTypesResponse()];

coerce 'RepeatedFetchProcessorTypesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::FetchProcessorTypesResponse'->new($_) } @$_ ] };

declare 'MapStringFetchProcessorTypesResponse',
    as HashRef[FetchProcessorTypesResponse()];

declare 'ListProcessorTypesRequest',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::ListProcessorTypesRequest'];

coerce 'ListProcessorTypesRequest',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ListProcessorTypesRequest'->new($_) };

declare 'RepeatedListProcessorTypesRequest',
    as ArrayRef[ListProcessorTypesRequest()];

coerce 'RepeatedListProcessorTypesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ListProcessorTypesRequest'->new($_) } @$_ ] };

declare 'MapStringListProcessorTypesRequest',
    as HashRef[ListProcessorTypesRequest()];

declare 'ListProcessorTypesResponse',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::ListProcessorTypesResponse'];

coerce 'ListProcessorTypesResponse',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ListProcessorTypesResponse'->new($_) };

declare 'RepeatedListProcessorTypesResponse',
    as ArrayRef[ListProcessorTypesResponse()];

coerce 'RepeatedListProcessorTypesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ListProcessorTypesResponse'->new($_) } @$_ ] };

declare 'MapStringListProcessorTypesResponse',
    as HashRef[ListProcessorTypesResponse()];

declare 'ListProcessorsRequest',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::ListProcessorsRequest'];

coerce 'ListProcessorsRequest',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ListProcessorsRequest'->new($_) };

declare 'RepeatedListProcessorsRequest',
    as ArrayRef[ListProcessorsRequest()];

coerce 'RepeatedListProcessorsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ListProcessorsRequest'->new($_) } @$_ ] };

declare 'MapStringListProcessorsRequest',
    as HashRef[ListProcessorsRequest()];

declare 'ListProcessorsResponse',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::ListProcessorsResponse'];

coerce 'ListProcessorsResponse',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ListProcessorsResponse'->new($_) };

declare 'RepeatedListProcessorsResponse',
    as ArrayRef[ListProcessorsResponse()];

coerce 'RepeatedListProcessorsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ListProcessorsResponse'->new($_) } @$_ ] };

declare 'MapStringListProcessorsResponse',
    as HashRef[ListProcessorsResponse()];

declare 'GetProcessorTypeRequest',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::GetProcessorTypeRequest'];

coerce 'GetProcessorTypeRequest',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::GetProcessorTypeRequest'->new($_) };

declare 'RepeatedGetProcessorTypeRequest',
    as ArrayRef[GetProcessorTypeRequest()];

coerce 'RepeatedGetProcessorTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::GetProcessorTypeRequest'->new($_) } @$_ ] };

declare 'MapStringGetProcessorTypeRequest',
    as HashRef[GetProcessorTypeRequest()];

declare 'GetProcessorRequest',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::GetProcessorRequest'];

coerce 'GetProcessorRequest',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::GetProcessorRequest'->new($_) };

declare 'RepeatedGetProcessorRequest',
    as ArrayRef[GetProcessorRequest()];

coerce 'RepeatedGetProcessorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::GetProcessorRequest'->new($_) } @$_ ] };

declare 'MapStringGetProcessorRequest',
    as HashRef[GetProcessorRequest()];

declare 'GetProcessorVersionRequest',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::GetProcessorVersionRequest'];

coerce 'GetProcessorVersionRequest',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::GetProcessorVersionRequest'->new($_) };

declare 'RepeatedGetProcessorVersionRequest',
    as ArrayRef[GetProcessorVersionRequest()];

coerce 'RepeatedGetProcessorVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::GetProcessorVersionRequest'->new($_) } @$_ ] };

declare 'MapStringGetProcessorVersionRequest',
    as HashRef[GetProcessorVersionRequest()];

declare 'ListProcessorVersionsRequest',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::ListProcessorVersionsRequest'];

coerce 'ListProcessorVersionsRequest',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ListProcessorVersionsRequest'->new($_) };

declare 'RepeatedListProcessorVersionsRequest',
    as ArrayRef[ListProcessorVersionsRequest()];

coerce 'RepeatedListProcessorVersionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ListProcessorVersionsRequest'->new($_) } @$_ ] };

declare 'MapStringListProcessorVersionsRequest',
    as HashRef[ListProcessorVersionsRequest()];

declare 'ListProcessorVersionsResponse',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::ListProcessorVersionsResponse'];

coerce 'ListProcessorVersionsResponse',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ListProcessorVersionsResponse'->new($_) };

declare 'RepeatedListProcessorVersionsResponse',
    as ArrayRef[ListProcessorVersionsResponse()];

coerce 'RepeatedListProcessorVersionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ListProcessorVersionsResponse'->new($_) } @$_ ] };

declare 'MapStringListProcessorVersionsResponse',
    as HashRef[ListProcessorVersionsResponse()];

declare 'DeleteProcessorVersionRequest',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::DeleteProcessorVersionRequest'];

coerce 'DeleteProcessorVersionRequest',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::DeleteProcessorVersionRequest'->new($_) };

declare 'RepeatedDeleteProcessorVersionRequest',
    as ArrayRef[DeleteProcessorVersionRequest()];

coerce 'RepeatedDeleteProcessorVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::DeleteProcessorVersionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteProcessorVersionRequest',
    as HashRef[DeleteProcessorVersionRequest()];

declare 'DeleteProcessorVersionMetadata',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::DeleteProcessorVersionMetadata'];

coerce 'DeleteProcessorVersionMetadata',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::DeleteProcessorVersionMetadata'->new($_) };

declare 'RepeatedDeleteProcessorVersionMetadata',
    as ArrayRef[DeleteProcessorVersionMetadata()];

coerce 'RepeatedDeleteProcessorVersionMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::DeleteProcessorVersionMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteProcessorVersionMetadata',
    as HashRef[DeleteProcessorVersionMetadata()];

declare 'DeployProcessorVersionRequest',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::DeployProcessorVersionRequest'];

coerce 'DeployProcessorVersionRequest',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::DeployProcessorVersionRequest'->new($_) };

declare 'RepeatedDeployProcessorVersionRequest',
    as ArrayRef[DeployProcessorVersionRequest()];

coerce 'RepeatedDeployProcessorVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::DeployProcessorVersionRequest'->new($_) } @$_ ] };

declare 'MapStringDeployProcessorVersionRequest',
    as HashRef[DeployProcessorVersionRequest()];

declare 'DeployProcessorVersionResponse',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::DeployProcessorVersionResponse'];

coerce 'DeployProcessorVersionResponse',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::DeployProcessorVersionResponse'->new($_) };

declare 'RepeatedDeployProcessorVersionResponse',
    as ArrayRef[DeployProcessorVersionResponse()];

coerce 'RepeatedDeployProcessorVersionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::DeployProcessorVersionResponse'->new($_) } @$_ ] };

declare 'MapStringDeployProcessorVersionResponse',
    as HashRef[DeployProcessorVersionResponse()];

declare 'DeployProcessorVersionMetadata',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::DeployProcessorVersionMetadata'];

coerce 'DeployProcessorVersionMetadata',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::DeployProcessorVersionMetadata'->new($_) };

declare 'RepeatedDeployProcessorVersionMetadata',
    as ArrayRef[DeployProcessorVersionMetadata()];

coerce 'RepeatedDeployProcessorVersionMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::DeployProcessorVersionMetadata'->new($_) } @$_ ] };

declare 'MapStringDeployProcessorVersionMetadata',
    as HashRef[DeployProcessorVersionMetadata()];

declare 'UndeployProcessorVersionRequest',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::UndeployProcessorVersionRequest'];

coerce 'UndeployProcessorVersionRequest',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::UndeployProcessorVersionRequest'->new($_) };

declare 'RepeatedUndeployProcessorVersionRequest',
    as ArrayRef[UndeployProcessorVersionRequest()];

coerce 'RepeatedUndeployProcessorVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::UndeployProcessorVersionRequest'->new($_) } @$_ ] };

declare 'MapStringUndeployProcessorVersionRequest',
    as HashRef[UndeployProcessorVersionRequest()];

declare 'UndeployProcessorVersionResponse',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::UndeployProcessorVersionResponse'];

coerce 'UndeployProcessorVersionResponse',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::UndeployProcessorVersionResponse'->new($_) };

declare 'RepeatedUndeployProcessorVersionResponse',
    as ArrayRef[UndeployProcessorVersionResponse()];

coerce 'RepeatedUndeployProcessorVersionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::UndeployProcessorVersionResponse'->new($_) } @$_ ] };

declare 'MapStringUndeployProcessorVersionResponse',
    as HashRef[UndeployProcessorVersionResponse()];

declare 'UndeployProcessorVersionMetadata',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::UndeployProcessorVersionMetadata'];

coerce 'UndeployProcessorVersionMetadata',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::UndeployProcessorVersionMetadata'->new($_) };

declare 'RepeatedUndeployProcessorVersionMetadata',
    as ArrayRef[UndeployProcessorVersionMetadata()];

coerce 'RepeatedUndeployProcessorVersionMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::UndeployProcessorVersionMetadata'->new($_) } @$_ ] };

declare 'MapStringUndeployProcessorVersionMetadata',
    as HashRef[UndeployProcessorVersionMetadata()];

declare 'CreateProcessorRequest',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::CreateProcessorRequest'];

coerce 'CreateProcessorRequest',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::CreateProcessorRequest'->new($_) };

declare 'RepeatedCreateProcessorRequest',
    as ArrayRef[CreateProcessorRequest()];

coerce 'RepeatedCreateProcessorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::CreateProcessorRequest'->new($_) } @$_ ] };

declare 'MapStringCreateProcessorRequest',
    as HashRef[CreateProcessorRequest()];

declare 'DeleteProcessorRequest',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::DeleteProcessorRequest'];

coerce 'DeleteProcessorRequest',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::DeleteProcessorRequest'->new($_) };

declare 'RepeatedDeleteProcessorRequest',
    as ArrayRef[DeleteProcessorRequest()];

coerce 'RepeatedDeleteProcessorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::DeleteProcessorRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteProcessorRequest',
    as HashRef[DeleteProcessorRequest()];

declare 'DeleteProcessorMetadata',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::DeleteProcessorMetadata'];

coerce 'DeleteProcessorMetadata',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::DeleteProcessorMetadata'->new($_) };

declare 'RepeatedDeleteProcessorMetadata',
    as ArrayRef[DeleteProcessorMetadata()];

coerce 'RepeatedDeleteProcessorMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::DeleteProcessorMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteProcessorMetadata',
    as HashRef[DeleteProcessorMetadata()];

declare 'EnableProcessorRequest',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::EnableProcessorRequest'];

coerce 'EnableProcessorRequest',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::EnableProcessorRequest'->new($_) };

declare 'RepeatedEnableProcessorRequest',
    as ArrayRef[EnableProcessorRequest()];

coerce 'RepeatedEnableProcessorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::EnableProcessorRequest'->new($_) } @$_ ] };

declare 'MapStringEnableProcessorRequest',
    as HashRef[EnableProcessorRequest()];

declare 'EnableProcessorResponse',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::EnableProcessorResponse'];

coerce 'EnableProcessorResponse',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::EnableProcessorResponse'->new($_) };

declare 'RepeatedEnableProcessorResponse',
    as ArrayRef[EnableProcessorResponse()];

coerce 'RepeatedEnableProcessorResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::EnableProcessorResponse'->new($_) } @$_ ] };

declare 'MapStringEnableProcessorResponse',
    as HashRef[EnableProcessorResponse()];

declare 'EnableProcessorMetadata',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::EnableProcessorMetadata'];

coerce 'EnableProcessorMetadata',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::EnableProcessorMetadata'->new($_) };

declare 'RepeatedEnableProcessorMetadata',
    as ArrayRef[EnableProcessorMetadata()];

coerce 'RepeatedEnableProcessorMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::EnableProcessorMetadata'->new($_) } @$_ ] };

declare 'MapStringEnableProcessorMetadata',
    as HashRef[EnableProcessorMetadata()];

declare 'DisableProcessorRequest',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::DisableProcessorRequest'];

coerce 'DisableProcessorRequest',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::DisableProcessorRequest'->new($_) };

declare 'RepeatedDisableProcessorRequest',
    as ArrayRef[DisableProcessorRequest()];

coerce 'RepeatedDisableProcessorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::DisableProcessorRequest'->new($_) } @$_ ] };

declare 'MapStringDisableProcessorRequest',
    as HashRef[DisableProcessorRequest()];

declare 'DisableProcessorResponse',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::DisableProcessorResponse'];

coerce 'DisableProcessorResponse',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::DisableProcessorResponse'->new($_) };

declare 'RepeatedDisableProcessorResponse',
    as ArrayRef[DisableProcessorResponse()];

coerce 'RepeatedDisableProcessorResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::DisableProcessorResponse'->new($_) } @$_ ] };

declare 'MapStringDisableProcessorResponse',
    as HashRef[DisableProcessorResponse()];

declare 'DisableProcessorMetadata',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::DisableProcessorMetadata'];

coerce 'DisableProcessorMetadata',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::DisableProcessorMetadata'->new($_) };

declare 'RepeatedDisableProcessorMetadata',
    as ArrayRef[DisableProcessorMetadata()];

coerce 'RepeatedDisableProcessorMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::DisableProcessorMetadata'->new($_) } @$_ ] };

declare 'MapStringDisableProcessorMetadata',
    as HashRef[DisableProcessorMetadata()];

declare 'SetDefaultProcessorVersionRequest',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::SetDefaultProcessorVersionRequest'];

coerce 'SetDefaultProcessorVersionRequest',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::SetDefaultProcessorVersionRequest'->new($_) };

declare 'RepeatedSetDefaultProcessorVersionRequest',
    as ArrayRef[SetDefaultProcessorVersionRequest()];

coerce 'RepeatedSetDefaultProcessorVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::SetDefaultProcessorVersionRequest'->new($_) } @$_ ] };

declare 'MapStringSetDefaultProcessorVersionRequest',
    as HashRef[SetDefaultProcessorVersionRequest()];

declare 'SetDefaultProcessorVersionResponse',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::SetDefaultProcessorVersionResponse'];

coerce 'SetDefaultProcessorVersionResponse',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::SetDefaultProcessorVersionResponse'->new($_) };

declare 'RepeatedSetDefaultProcessorVersionResponse',
    as ArrayRef[SetDefaultProcessorVersionResponse()];

coerce 'RepeatedSetDefaultProcessorVersionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::SetDefaultProcessorVersionResponse'->new($_) } @$_ ] };

declare 'MapStringSetDefaultProcessorVersionResponse',
    as HashRef[SetDefaultProcessorVersionResponse()];

declare 'SetDefaultProcessorVersionMetadata',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::SetDefaultProcessorVersionMetadata'];

coerce 'SetDefaultProcessorVersionMetadata',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::SetDefaultProcessorVersionMetadata'->new($_) };

declare 'RepeatedSetDefaultProcessorVersionMetadata',
    as ArrayRef[SetDefaultProcessorVersionMetadata()];

coerce 'RepeatedSetDefaultProcessorVersionMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::SetDefaultProcessorVersionMetadata'->new($_) } @$_ ] };

declare 'MapStringSetDefaultProcessorVersionMetadata',
    as HashRef[SetDefaultProcessorVersionMetadata()];

declare 'TrainProcessorVersionRequest',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::TrainProcessorVersionRequest'];

coerce 'TrainProcessorVersionRequest',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::TrainProcessorVersionRequest'->new($_) };

declare 'RepeatedTrainProcessorVersionRequest',
    as ArrayRef[TrainProcessorVersionRequest()];

coerce 'RepeatedTrainProcessorVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::TrainProcessorVersionRequest'->new($_) } @$_ ] };

declare 'MapStringTrainProcessorVersionRequest',
    as HashRef[TrainProcessorVersionRequest()];

declare 'InputData',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::TrainProcessorVersionRequest::InputData'];

coerce 'InputData',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::TrainProcessorVersionRequest::InputData'->new($_) };

declare 'RepeatedInputData',
    as ArrayRef[InputData()];

coerce 'RepeatedInputData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::TrainProcessorVersionRequest::InputData'->new($_) } @$_ ] };

declare 'MapStringInputData',
    as HashRef[InputData()];

declare 'CustomDocumentExtractionOptions',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::TrainProcessorVersionRequest::CustomDocumentExtractionOptions'];

coerce 'CustomDocumentExtractionOptions',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::TrainProcessorVersionRequest::CustomDocumentExtractionOptions'->new($_) };

declare 'RepeatedCustomDocumentExtractionOptions',
    as ArrayRef[CustomDocumentExtractionOptions()];

coerce 'RepeatedCustomDocumentExtractionOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::TrainProcessorVersionRequest::CustomDocumentExtractionOptions'->new($_) } @$_ ] };

declare 'MapStringCustomDocumentExtractionOptions',
    as HashRef[CustomDocumentExtractionOptions()];

declare 'TrainingMethod',
    as (Int | Str);

declare 'FoundationModelTuningOptions',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::TrainProcessorVersionRequest::FoundationModelTuningOptions'];

coerce 'FoundationModelTuningOptions',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::TrainProcessorVersionRequest::FoundationModelTuningOptions'->new($_) };

declare 'RepeatedFoundationModelTuningOptions',
    as ArrayRef[FoundationModelTuningOptions()];

coerce 'RepeatedFoundationModelTuningOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::TrainProcessorVersionRequest::FoundationModelTuningOptions'->new($_) } @$_ ] };

declare 'MapStringFoundationModelTuningOptions',
    as HashRef[FoundationModelTuningOptions()];

declare 'TrainProcessorVersionResponse',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::TrainProcessorVersionResponse'];

coerce 'TrainProcessorVersionResponse',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::TrainProcessorVersionResponse'->new($_) };

declare 'RepeatedTrainProcessorVersionResponse',
    as ArrayRef[TrainProcessorVersionResponse()];

coerce 'RepeatedTrainProcessorVersionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::TrainProcessorVersionResponse'->new($_) } @$_ ] };

declare 'MapStringTrainProcessorVersionResponse',
    as HashRef[TrainProcessorVersionResponse()];

declare 'TrainProcessorVersionMetadata',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::TrainProcessorVersionMetadata'];

coerce 'TrainProcessorVersionMetadata',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::TrainProcessorVersionMetadata'->new($_) };

declare 'RepeatedTrainProcessorVersionMetadata',
    as ArrayRef[TrainProcessorVersionMetadata()];

coerce 'RepeatedTrainProcessorVersionMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::TrainProcessorVersionMetadata'->new($_) } @$_ ] };

declare 'MapStringTrainProcessorVersionMetadata',
    as HashRef[TrainProcessorVersionMetadata()];

declare 'DatasetValidation',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::TrainProcessorVersionMetadata::DatasetValidation'];

coerce 'DatasetValidation',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::TrainProcessorVersionMetadata::DatasetValidation'->new($_) };

declare 'RepeatedDatasetValidation',
    as ArrayRef[DatasetValidation()];

coerce 'RepeatedDatasetValidation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::TrainProcessorVersionMetadata::DatasetValidation'->new($_) } @$_ ] };

declare 'MapStringDatasetValidation',
    as HashRef[DatasetValidation()];

declare 'ReviewDocumentRequest',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::ReviewDocumentRequest'];

coerce 'ReviewDocumentRequest',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ReviewDocumentRequest'->new($_) };

declare 'RepeatedReviewDocumentRequest',
    as ArrayRef[ReviewDocumentRequest()];

coerce 'RepeatedReviewDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ReviewDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringReviewDocumentRequest',
    as HashRef[ReviewDocumentRequest()];

declare 'Priority',
    as (Int | Str);

declare 'ReviewDocumentResponse',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::ReviewDocumentResponse'];

coerce 'ReviewDocumentResponse',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ReviewDocumentResponse'->new($_) };

declare 'RepeatedReviewDocumentResponse',
    as ArrayRef[ReviewDocumentResponse()];

coerce 'RepeatedReviewDocumentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ReviewDocumentResponse'->new($_) } @$_ ] };

declare 'MapStringReviewDocumentResponse',
    as HashRef[ReviewDocumentResponse()];

declare 'State',
    as (Int | Str);

declare 'ReviewDocumentOperationMetadata',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::ReviewDocumentOperationMetadata'];

coerce 'ReviewDocumentOperationMetadata',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ReviewDocumentOperationMetadata'->new($_) };

declare 'RepeatedReviewDocumentOperationMetadata',
    as ArrayRef[ReviewDocumentOperationMetadata()];

coerce 'RepeatedReviewDocumentOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ReviewDocumentOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringReviewDocumentOperationMetadata',
    as HashRef[ReviewDocumentOperationMetadata()];

declare 'EvaluateProcessorVersionRequest',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::EvaluateProcessorVersionRequest'];

coerce 'EvaluateProcessorVersionRequest',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::EvaluateProcessorVersionRequest'->new($_) };

declare 'RepeatedEvaluateProcessorVersionRequest',
    as ArrayRef[EvaluateProcessorVersionRequest()];

coerce 'RepeatedEvaluateProcessorVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::EvaluateProcessorVersionRequest'->new($_) } @$_ ] };

declare 'MapStringEvaluateProcessorVersionRequest',
    as HashRef[EvaluateProcessorVersionRequest()];

declare 'EvaluateProcessorVersionMetadata',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::EvaluateProcessorVersionMetadata'];

coerce 'EvaluateProcessorVersionMetadata',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::EvaluateProcessorVersionMetadata'->new($_) };

declare 'RepeatedEvaluateProcessorVersionMetadata',
    as ArrayRef[EvaluateProcessorVersionMetadata()];

coerce 'RepeatedEvaluateProcessorVersionMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::EvaluateProcessorVersionMetadata'->new($_) } @$_ ] };

declare 'MapStringEvaluateProcessorVersionMetadata',
    as HashRef[EvaluateProcessorVersionMetadata()];

declare 'EvaluateProcessorVersionResponse',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::EvaluateProcessorVersionResponse'];

coerce 'EvaluateProcessorVersionResponse',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::EvaluateProcessorVersionResponse'->new($_) };

declare 'RepeatedEvaluateProcessorVersionResponse',
    as ArrayRef[EvaluateProcessorVersionResponse()];

coerce 'RepeatedEvaluateProcessorVersionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::EvaluateProcessorVersionResponse'->new($_) } @$_ ] };

declare 'MapStringEvaluateProcessorVersionResponse',
    as HashRef[EvaluateProcessorVersionResponse()];

declare 'GetEvaluationRequest',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::GetEvaluationRequest'];

coerce 'GetEvaluationRequest',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::GetEvaluationRequest'->new($_) };

declare 'RepeatedGetEvaluationRequest',
    as ArrayRef[GetEvaluationRequest()];

coerce 'RepeatedGetEvaluationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::GetEvaluationRequest'->new($_) } @$_ ] };

declare 'MapStringGetEvaluationRequest',
    as HashRef[GetEvaluationRequest()];

declare 'ListEvaluationsRequest',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::ListEvaluationsRequest'];

coerce 'ListEvaluationsRequest',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ListEvaluationsRequest'->new($_) };

declare 'RepeatedListEvaluationsRequest',
    as ArrayRef[ListEvaluationsRequest()];

coerce 'RepeatedListEvaluationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ListEvaluationsRequest'->new($_) } @$_ ] };

declare 'MapStringListEvaluationsRequest',
    as HashRef[ListEvaluationsRequest()];

declare 'ListEvaluationsResponse',
    as InstanceOf['Google::Cloud::Documentai::V1::DocumentProcessorService::ListEvaluationsResponse'];

coerce 'ListEvaluationsResponse',
    from HashRef, via { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ListEvaluationsResponse'->new($_) };

declare 'RepeatedListEvaluationsResponse',
    as ArrayRef[ListEvaluationsResponse()];

coerce 'RepeatedListEvaluationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1::DocumentProcessorService::ListEvaluationsResponse'->new($_) } @$_ ] };

declare 'MapStringListEvaluationsResponse',
    as HashRef[ListEvaluationsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Documentai::V1::DocumentProcessorService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
