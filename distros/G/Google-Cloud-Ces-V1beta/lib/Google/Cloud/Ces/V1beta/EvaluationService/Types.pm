package Google::Cloud::Ces::V1beta::EvaluationService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RunEvaluationResultMetricsRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::RunEvaluationResultMetricsRequest'];

coerce 'RunEvaluationResultMetricsRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::RunEvaluationResultMetricsRequest'->new($_) };

declare 'RepeatedRunEvaluationResultMetricsRequest',
    as ArrayRef[RunEvaluationResultMetricsRequest()];

coerce 'RepeatedRunEvaluationResultMetricsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::RunEvaluationResultMetricsRequest'->new($_) } @$_ ] };

declare 'MapStringRunEvaluationResultMetricsRequest',
    as HashRef[RunEvaluationResultMetricsRequest()];

declare 'RunEvaluationResultMetricsResponse',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::RunEvaluationResultMetricsResponse'];

coerce 'RunEvaluationResultMetricsResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::RunEvaluationResultMetricsResponse'->new($_) };

declare 'RepeatedRunEvaluationResultMetricsResponse',
    as ArrayRef[RunEvaluationResultMetricsResponse()];

coerce 'RepeatedRunEvaluationResultMetricsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::RunEvaluationResultMetricsResponse'->new($_) } @$_ ] };

declare 'MapStringRunEvaluationResultMetricsResponse',
    as HashRef[RunEvaluationResultMetricsResponse()];

declare 'RunEvaluationResponse',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::RunEvaluationResponse'];

coerce 'RunEvaluationResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::RunEvaluationResponse'->new($_) };

declare 'RepeatedRunEvaluationResponse',
    as ArrayRef[RunEvaluationResponse()];

coerce 'RepeatedRunEvaluationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::RunEvaluationResponse'->new($_) } @$_ ] };

declare 'MapStringRunEvaluationResponse',
    as HashRef[RunEvaluationResponse()];

declare 'RunEvaluationOperationMetadata',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::RunEvaluationOperationMetadata'];

coerce 'RunEvaluationOperationMetadata',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::RunEvaluationOperationMetadata'->new($_) };

declare 'RepeatedRunEvaluationOperationMetadata',
    as ArrayRef[RunEvaluationOperationMetadata()];

coerce 'RepeatedRunEvaluationOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::RunEvaluationOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringRunEvaluationOperationMetadata',
    as HashRef[RunEvaluationOperationMetadata()];

declare 'GenerateEvaluationOperationMetadata',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::GenerateEvaluationOperationMetadata'];

coerce 'GenerateEvaluationOperationMetadata',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::GenerateEvaluationOperationMetadata'->new($_) };

declare 'RepeatedGenerateEvaluationOperationMetadata',
    as ArrayRef[GenerateEvaluationOperationMetadata()];

coerce 'RepeatedGenerateEvaluationOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::GenerateEvaluationOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringGenerateEvaluationOperationMetadata',
    as HashRef[GenerateEvaluationOperationMetadata()];

declare 'DeleteEvaluationRunOperationMetadata',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::DeleteEvaluationRunOperationMetadata'];

coerce 'DeleteEvaluationRunOperationMetadata',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::DeleteEvaluationRunOperationMetadata'->new($_) };

declare 'RepeatedDeleteEvaluationRunOperationMetadata',
    as ArrayRef[DeleteEvaluationRunOperationMetadata()];

coerce 'RepeatedDeleteEvaluationRunOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::DeleteEvaluationRunOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteEvaluationRunOperationMetadata',
    as HashRef[DeleteEvaluationRunOperationMetadata()];

declare 'CreateEvaluationRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::CreateEvaluationRequest'];

coerce 'CreateEvaluationRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::CreateEvaluationRequest'->new($_) };

declare 'RepeatedCreateEvaluationRequest',
    as ArrayRef[CreateEvaluationRequest()];

coerce 'RepeatedCreateEvaluationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::CreateEvaluationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEvaluationRequest',
    as HashRef[CreateEvaluationRequest()];

declare 'GenerateEvaluationRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::GenerateEvaluationRequest'];

coerce 'GenerateEvaluationRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::GenerateEvaluationRequest'->new($_) };

declare 'RepeatedGenerateEvaluationRequest',
    as ArrayRef[GenerateEvaluationRequest()];

coerce 'RepeatedGenerateEvaluationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::GenerateEvaluationRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateEvaluationRequest',
    as HashRef[GenerateEvaluationRequest()];

declare 'EvaluationType',
    as (Int | Str);

declare 'ImportEvaluationsRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::ImportEvaluationsRequest'];

coerce 'ImportEvaluationsRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::ImportEvaluationsRequest'->new($_) };

declare 'RepeatedImportEvaluationsRequest',
    as ArrayRef[ImportEvaluationsRequest()];

coerce 'RepeatedImportEvaluationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::ImportEvaluationsRequest'->new($_) } @$_ ] };

declare 'MapStringImportEvaluationsRequest',
    as HashRef[ImportEvaluationsRequest()];

declare 'ConversationList',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::ImportEvaluationsRequest::ConversationList'];

coerce 'ConversationList',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::ImportEvaluationsRequest::ConversationList'->new($_) };

declare 'RepeatedConversationList',
    as ArrayRef[ConversationList()];

coerce 'RepeatedConversationList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::ImportEvaluationsRequest::ConversationList'->new($_) } @$_ ] };

declare 'MapStringConversationList',
    as HashRef[ConversationList()];

declare 'ImportOptions',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::ImportEvaluationsRequest::ImportOptions'];

coerce 'ImportOptions',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::ImportEvaluationsRequest::ImportOptions'->new($_) };

declare 'RepeatedImportOptions',
    as ArrayRef[ImportOptions()];

coerce 'RepeatedImportOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::ImportEvaluationsRequest::ImportOptions'->new($_) } @$_ ] };

declare 'MapStringImportOptions',
    as HashRef[ImportOptions()];

declare 'ConflictResolutionStrategy',
    as (Int | Str);

declare 'ImportEvaluationsResponse',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::ImportEvaluationsResponse'];

coerce 'ImportEvaluationsResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::ImportEvaluationsResponse'->new($_) };

declare 'RepeatedImportEvaluationsResponse',
    as ArrayRef[ImportEvaluationsResponse()];

coerce 'RepeatedImportEvaluationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::ImportEvaluationsResponse'->new($_) } @$_ ] };

declare 'MapStringImportEvaluationsResponse',
    as HashRef[ImportEvaluationsResponse()];

declare 'ImportEvaluationsOperationMetadata',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::ImportEvaluationsOperationMetadata'];

coerce 'ImportEvaluationsOperationMetadata',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::ImportEvaluationsOperationMetadata'->new($_) };

declare 'RepeatedImportEvaluationsOperationMetadata',
    as ArrayRef[ImportEvaluationsOperationMetadata()];

coerce 'RepeatedImportEvaluationsOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::ImportEvaluationsOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringImportEvaluationsOperationMetadata',
    as HashRef[ImportEvaluationsOperationMetadata()];

declare 'CreateEvaluationDatasetRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::CreateEvaluationDatasetRequest'];

coerce 'CreateEvaluationDatasetRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::CreateEvaluationDatasetRequest'->new($_) };

declare 'RepeatedCreateEvaluationDatasetRequest',
    as ArrayRef[CreateEvaluationDatasetRequest()];

coerce 'RepeatedCreateEvaluationDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::CreateEvaluationDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEvaluationDatasetRequest',
    as HashRef[CreateEvaluationDatasetRequest()];

declare 'UpdateEvaluationRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::UpdateEvaluationRequest'];

coerce 'UpdateEvaluationRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::UpdateEvaluationRequest'->new($_) };

declare 'RepeatedUpdateEvaluationRequest',
    as ArrayRef[UpdateEvaluationRequest()];

coerce 'RepeatedUpdateEvaluationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::UpdateEvaluationRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateEvaluationRequest',
    as HashRef[UpdateEvaluationRequest()];

declare 'UpdateEvaluationDatasetRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::UpdateEvaluationDatasetRequest'];

coerce 'UpdateEvaluationDatasetRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::UpdateEvaluationDatasetRequest'->new($_) };

declare 'RepeatedUpdateEvaluationDatasetRequest',
    as ArrayRef[UpdateEvaluationDatasetRequest()];

coerce 'RepeatedUpdateEvaluationDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::UpdateEvaluationDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateEvaluationDatasetRequest',
    as HashRef[UpdateEvaluationDatasetRequest()];

declare 'DeleteEvaluationRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::DeleteEvaluationRequest'];

coerce 'DeleteEvaluationRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::DeleteEvaluationRequest'->new($_) };

declare 'RepeatedDeleteEvaluationRequest',
    as ArrayRef[DeleteEvaluationRequest()];

coerce 'RepeatedDeleteEvaluationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::DeleteEvaluationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEvaluationRequest',
    as HashRef[DeleteEvaluationRequest()];

declare 'DeleteEvaluationResultRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::DeleteEvaluationResultRequest'];

coerce 'DeleteEvaluationResultRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::DeleteEvaluationResultRequest'->new($_) };

declare 'RepeatedDeleteEvaluationResultRequest',
    as ArrayRef[DeleteEvaluationResultRequest()];

coerce 'RepeatedDeleteEvaluationResultRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::DeleteEvaluationResultRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEvaluationResultRequest',
    as HashRef[DeleteEvaluationResultRequest()];

declare 'DeleteEvaluationDatasetRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::DeleteEvaluationDatasetRequest'];

coerce 'DeleteEvaluationDatasetRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::DeleteEvaluationDatasetRequest'->new($_) };

declare 'RepeatedDeleteEvaluationDatasetRequest',
    as ArrayRef[DeleteEvaluationDatasetRequest()];

coerce 'RepeatedDeleteEvaluationDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::DeleteEvaluationDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEvaluationDatasetRequest',
    as HashRef[DeleteEvaluationDatasetRequest()];

declare 'DeleteEvaluationRunRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::DeleteEvaluationRunRequest'];

coerce 'DeleteEvaluationRunRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::DeleteEvaluationRunRequest'->new($_) };

declare 'RepeatedDeleteEvaluationRunRequest',
    as ArrayRef[DeleteEvaluationRunRequest()];

coerce 'RepeatedDeleteEvaluationRunRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::DeleteEvaluationRunRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEvaluationRunRequest',
    as HashRef[DeleteEvaluationRunRequest()];

declare 'GetEvaluationRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::GetEvaluationRequest'];

coerce 'GetEvaluationRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::GetEvaluationRequest'->new($_) };

declare 'RepeatedGetEvaluationRequest',
    as ArrayRef[GetEvaluationRequest()];

coerce 'RepeatedGetEvaluationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::GetEvaluationRequest'->new($_) } @$_ ] };

declare 'MapStringGetEvaluationRequest',
    as HashRef[GetEvaluationRequest()];

declare 'GetEvaluationResultRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::GetEvaluationResultRequest'];

coerce 'GetEvaluationResultRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::GetEvaluationResultRequest'->new($_) };

declare 'RepeatedGetEvaluationResultRequest',
    as ArrayRef[GetEvaluationResultRequest()];

coerce 'RepeatedGetEvaluationResultRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::GetEvaluationResultRequest'->new($_) } @$_ ] };

declare 'MapStringGetEvaluationResultRequest',
    as HashRef[GetEvaluationResultRequest()];

declare 'GetEvaluationDatasetRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::GetEvaluationDatasetRequest'];

coerce 'GetEvaluationDatasetRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::GetEvaluationDatasetRequest'->new($_) };

declare 'RepeatedGetEvaluationDatasetRequest',
    as ArrayRef[GetEvaluationDatasetRequest()];

coerce 'RepeatedGetEvaluationDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::GetEvaluationDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringGetEvaluationDatasetRequest',
    as HashRef[GetEvaluationDatasetRequest()];

declare 'GetEvaluationRunRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::GetEvaluationRunRequest'];

coerce 'GetEvaluationRunRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::GetEvaluationRunRequest'->new($_) };

declare 'RepeatedGetEvaluationRunRequest',
    as ArrayRef[GetEvaluationRunRequest()];

coerce 'RepeatedGetEvaluationRunRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::GetEvaluationRunRequest'->new($_) } @$_ ] };

declare 'MapStringGetEvaluationRunRequest',
    as HashRef[GetEvaluationRunRequest()];

declare 'ListEvaluationsRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::ListEvaluationsRequest'];

coerce 'ListEvaluationsRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::ListEvaluationsRequest'->new($_) };

declare 'RepeatedListEvaluationsRequest',
    as ArrayRef[ListEvaluationsRequest()];

coerce 'RepeatedListEvaluationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::ListEvaluationsRequest'->new($_) } @$_ ] };

declare 'MapStringListEvaluationsRequest',
    as HashRef[ListEvaluationsRequest()];

declare 'ListEvaluationResultsRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::ListEvaluationResultsRequest'];

coerce 'ListEvaluationResultsRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::ListEvaluationResultsRequest'->new($_) };

declare 'RepeatedListEvaluationResultsRequest',
    as ArrayRef[ListEvaluationResultsRequest()];

coerce 'RepeatedListEvaluationResultsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::ListEvaluationResultsRequest'->new($_) } @$_ ] };

declare 'MapStringListEvaluationResultsRequest',
    as HashRef[ListEvaluationResultsRequest()];

declare 'ListEvaluationDatasetsRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::ListEvaluationDatasetsRequest'];

coerce 'ListEvaluationDatasetsRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::ListEvaluationDatasetsRequest'->new($_) };

declare 'RepeatedListEvaluationDatasetsRequest',
    as ArrayRef[ListEvaluationDatasetsRequest()];

coerce 'RepeatedListEvaluationDatasetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::ListEvaluationDatasetsRequest'->new($_) } @$_ ] };

declare 'MapStringListEvaluationDatasetsRequest',
    as HashRef[ListEvaluationDatasetsRequest()];

declare 'ListEvaluationRunsRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::ListEvaluationRunsRequest'];

coerce 'ListEvaluationRunsRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::ListEvaluationRunsRequest'->new($_) };

declare 'RepeatedListEvaluationRunsRequest',
    as ArrayRef[ListEvaluationRunsRequest()];

coerce 'RepeatedListEvaluationRunsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::ListEvaluationRunsRequest'->new($_) } @$_ ] };

declare 'MapStringListEvaluationRunsRequest',
    as HashRef[ListEvaluationRunsRequest()];

declare 'ListEvaluationsResponse',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::ListEvaluationsResponse'];

coerce 'ListEvaluationsResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::ListEvaluationsResponse'->new($_) };

declare 'RepeatedListEvaluationsResponse',
    as ArrayRef[ListEvaluationsResponse()];

coerce 'RepeatedListEvaluationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::ListEvaluationsResponse'->new($_) } @$_ ] };

declare 'MapStringListEvaluationsResponse',
    as HashRef[ListEvaluationsResponse()];

declare 'ListEvaluationResultsResponse',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::ListEvaluationResultsResponse'];

coerce 'ListEvaluationResultsResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::ListEvaluationResultsResponse'->new($_) };

declare 'RepeatedListEvaluationResultsResponse',
    as ArrayRef[ListEvaluationResultsResponse()];

coerce 'RepeatedListEvaluationResultsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::ListEvaluationResultsResponse'->new($_) } @$_ ] };

declare 'MapStringListEvaluationResultsResponse',
    as HashRef[ListEvaluationResultsResponse()];

declare 'ListEvaluationDatasetsResponse',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::ListEvaluationDatasetsResponse'];

coerce 'ListEvaluationDatasetsResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::ListEvaluationDatasetsResponse'->new($_) };

declare 'RepeatedListEvaluationDatasetsResponse',
    as ArrayRef[ListEvaluationDatasetsResponse()];

coerce 'RepeatedListEvaluationDatasetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::ListEvaluationDatasetsResponse'->new($_) } @$_ ] };

declare 'MapStringListEvaluationDatasetsResponse',
    as HashRef[ListEvaluationDatasetsResponse()];

declare 'ListEvaluationRunsResponse',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::ListEvaluationRunsResponse'];

coerce 'ListEvaluationRunsResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::ListEvaluationRunsResponse'->new($_) };

declare 'RepeatedListEvaluationRunsResponse',
    as ArrayRef[ListEvaluationRunsResponse()];

coerce 'RepeatedListEvaluationRunsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::ListEvaluationRunsResponse'->new($_) } @$_ ] };

declare 'MapStringListEvaluationRunsResponse',
    as HashRef[ListEvaluationRunsResponse()];

declare 'CreateScheduledEvaluationRunRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::CreateScheduledEvaluationRunRequest'];

coerce 'CreateScheduledEvaluationRunRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::CreateScheduledEvaluationRunRequest'->new($_) };

declare 'RepeatedCreateScheduledEvaluationRunRequest',
    as ArrayRef[CreateScheduledEvaluationRunRequest()];

coerce 'RepeatedCreateScheduledEvaluationRunRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::CreateScheduledEvaluationRunRequest'->new($_) } @$_ ] };

declare 'MapStringCreateScheduledEvaluationRunRequest',
    as HashRef[CreateScheduledEvaluationRunRequest()];

declare 'GetScheduledEvaluationRunRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::GetScheduledEvaluationRunRequest'];

coerce 'GetScheduledEvaluationRunRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::GetScheduledEvaluationRunRequest'->new($_) };

declare 'RepeatedGetScheduledEvaluationRunRequest',
    as ArrayRef[GetScheduledEvaluationRunRequest()];

coerce 'RepeatedGetScheduledEvaluationRunRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::GetScheduledEvaluationRunRequest'->new($_) } @$_ ] };

declare 'MapStringGetScheduledEvaluationRunRequest',
    as HashRef[GetScheduledEvaluationRunRequest()];

declare 'ListScheduledEvaluationRunsRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::ListScheduledEvaluationRunsRequest'];

coerce 'ListScheduledEvaluationRunsRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::ListScheduledEvaluationRunsRequest'->new($_) };

declare 'RepeatedListScheduledEvaluationRunsRequest',
    as ArrayRef[ListScheduledEvaluationRunsRequest()];

coerce 'RepeatedListScheduledEvaluationRunsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::ListScheduledEvaluationRunsRequest'->new($_) } @$_ ] };

declare 'MapStringListScheduledEvaluationRunsRequest',
    as HashRef[ListScheduledEvaluationRunsRequest()];

declare 'ListScheduledEvaluationRunsResponse',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::ListScheduledEvaluationRunsResponse'];

coerce 'ListScheduledEvaluationRunsResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::ListScheduledEvaluationRunsResponse'->new($_) };

declare 'RepeatedListScheduledEvaluationRunsResponse',
    as ArrayRef[ListScheduledEvaluationRunsResponse()];

coerce 'RepeatedListScheduledEvaluationRunsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::ListScheduledEvaluationRunsResponse'->new($_) } @$_ ] };

declare 'MapStringListScheduledEvaluationRunsResponse',
    as HashRef[ListScheduledEvaluationRunsResponse()];

declare 'UpdateScheduledEvaluationRunRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::UpdateScheduledEvaluationRunRequest'];

coerce 'UpdateScheduledEvaluationRunRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::UpdateScheduledEvaluationRunRequest'->new($_) };

declare 'RepeatedUpdateScheduledEvaluationRunRequest',
    as ArrayRef[UpdateScheduledEvaluationRunRequest()];

coerce 'RepeatedUpdateScheduledEvaluationRunRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::UpdateScheduledEvaluationRunRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateScheduledEvaluationRunRequest',
    as HashRef[UpdateScheduledEvaluationRunRequest()];

declare 'DeleteScheduledEvaluationRunRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::DeleteScheduledEvaluationRunRequest'];

coerce 'DeleteScheduledEvaluationRunRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::DeleteScheduledEvaluationRunRequest'->new($_) };

declare 'RepeatedDeleteScheduledEvaluationRunRequest',
    as ArrayRef[DeleteScheduledEvaluationRunRequest()];

coerce 'RepeatedDeleteScheduledEvaluationRunRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::DeleteScheduledEvaluationRunRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteScheduledEvaluationRunRequest',
    as HashRef[DeleteScheduledEvaluationRunRequest()];

declare 'TestPersonaVoiceRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::TestPersonaVoiceRequest'];

coerce 'TestPersonaVoiceRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::TestPersonaVoiceRequest'->new($_) };

declare 'RepeatedTestPersonaVoiceRequest',
    as ArrayRef[TestPersonaVoiceRequest()];

coerce 'RepeatedTestPersonaVoiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::TestPersonaVoiceRequest'->new($_) } @$_ ] };

declare 'MapStringTestPersonaVoiceRequest',
    as HashRef[TestPersonaVoiceRequest()];

declare 'UploadEvaluationAudioRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::UploadEvaluationAudioRequest'];

coerce 'UploadEvaluationAudioRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::UploadEvaluationAudioRequest'->new($_) };

declare 'RepeatedUploadEvaluationAudioRequest',
    as ArrayRef[UploadEvaluationAudioRequest()];

coerce 'RepeatedUploadEvaluationAudioRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::UploadEvaluationAudioRequest'->new($_) } @$_ ] };

declare 'MapStringUploadEvaluationAudioRequest',
    as HashRef[UploadEvaluationAudioRequest()];

declare 'UploadEvaluationAudioResponse',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::UploadEvaluationAudioResponse'];

coerce 'UploadEvaluationAudioResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::UploadEvaluationAudioResponse'->new($_) };

declare 'RepeatedUploadEvaluationAudioResponse',
    as ArrayRef[UploadEvaluationAudioResponse()];

coerce 'RepeatedUploadEvaluationAudioResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::UploadEvaluationAudioResponse'->new($_) } @$_ ] };

declare 'MapStringUploadEvaluationAudioResponse',
    as HashRef[UploadEvaluationAudioResponse()];

declare 'TestPersonaVoiceResponse',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::TestPersonaVoiceResponse'];

coerce 'TestPersonaVoiceResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::TestPersonaVoiceResponse'->new($_) };

declare 'RepeatedTestPersonaVoiceResponse',
    as ArrayRef[TestPersonaVoiceResponse()];

coerce 'RepeatedTestPersonaVoiceResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::TestPersonaVoiceResponse'->new($_) } @$_ ] };

declare 'MapStringTestPersonaVoiceResponse',
    as HashRef[TestPersonaVoiceResponse()];

declare 'CreateEvaluationExpectationRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::CreateEvaluationExpectationRequest'];

coerce 'CreateEvaluationExpectationRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::CreateEvaluationExpectationRequest'->new($_) };

declare 'RepeatedCreateEvaluationExpectationRequest',
    as ArrayRef[CreateEvaluationExpectationRequest()];

coerce 'RepeatedCreateEvaluationExpectationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::CreateEvaluationExpectationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEvaluationExpectationRequest',
    as HashRef[CreateEvaluationExpectationRequest()];

declare 'UpdateEvaluationExpectationRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::UpdateEvaluationExpectationRequest'];

coerce 'UpdateEvaluationExpectationRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::UpdateEvaluationExpectationRequest'->new($_) };

declare 'RepeatedUpdateEvaluationExpectationRequest',
    as ArrayRef[UpdateEvaluationExpectationRequest()];

coerce 'RepeatedUpdateEvaluationExpectationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::UpdateEvaluationExpectationRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateEvaluationExpectationRequest',
    as HashRef[UpdateEvaluationExpectationRequest()];

declare 'DeleteEvaluationExpectationRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::DeleteEvaluationExpectationRequest'];

coerce 'DeleteEvaluationExpectationRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::DeleteEvaluationExpectationRequest'->new($_) };

declare 'RepeatedDeleteEvaluationExpectationRequest',
    as ArrayRef[DeleteEvaluationExpectationRequest()];

coerce 'RepeatedDeleteEvaluationExpectationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::DeleteEvaluationExpectationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEvaluationExpectationRequest',
    as HashRef[DeleteEvaluationExpectationRequest()];

declare 'GetEvaluationExpectationRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::GetEvaluationExpectationRequest'];

coerce 'GetEvaluationExpectationRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::GetEvaluationExpectationRequest'->new($_) };

declare 'RepeatedGetEvaluationExpectationRequest',
    as ArrayRef[GetEvaluationExpectationRequest()];

coerce 'RepeatedGetEvaluationExpectationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::GetEvaluationExpectationRequest'->new($_) } @$_ ] };

declare 'MapStringGetEvaluationExpectationRequest',
    as HashRef[GetEvaluationExpectationRequest()];

declare 'ListEvaluationExpectationsRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::ListEvaluationExpectationsRequest'];

coerce 'ListEvaluationExpectationsRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::ListEvaluationExpectationsRequest'->new($_) };

declare 'RepeatedListEvaluationExpectationsRequest',
    as ArrayRef[ListEvaluationExpectationsRequest()];

coerce 'RepeatedListEvaluationExpectationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::ListEvaluationExpectationsRequest'->new($_) } @$_ ] };

declare 'MapStringListEvaluationExpectationsRequest',
    as HashRef[ListEvaluationExpectationsRequest()];

declare 'ListEvaluationExpectationsResponse',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::ListEvaluationExpectationsResponse'];

coerce 'ListEvaluationExpectationsResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::ListEvaluationExpectationsResponse'->new($_) };

declare 'RepeatedListEvaluationExpectationsResponse',
    as ArrayRef[ListEvaluationExpectationsResponse()];

coerce 'RepeatedListEvaluationExpectationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::ListEvaluationExpectationsResponse'->new($_) } @$_ ] };

declare 'MapStringListEvaluationExpectationsResponse',
    as HashRef[ListEvaluationExpectationsResponse()];

declare 'ExportOptions',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::ExportOptions'];

coerce 'ExportOptions',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::ExportOptions'->new($_) };

declare 'RepeatedExportOptions',
    as ArrayRef[ExportOptions()];

coerce 'RepeatedExportOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::ExportOptions'->new($_) } @$_ ] };

declare 'MapStringExportOptions',
    as HashRef[ExportOptions()];

declare 'ExportFormat',
    as (Int | Str);

declare 'ExportEvaluationsRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::ExportEvaluationsRequest'];

coerce 'ExportEvaluationsRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::ExportEvaluationsRequest'->new($_) };

declare 'RepeatedExportEvaluationsRequest',
    as ArrayRef[ExportEvaluationsRequest()];

coerce 'RepeatedExportEvaluationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::ExportEvaluationsRequest'->new($_) } @$_ ] };

declare 'MapStringExportEvaluationsRequest',
    as HashRef[ExportEvaluationsRequest()];

declare 'ExportEvaluationsResponse',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::ExportEvaluationsResponse'];

coerce 'ExportEvaluationsResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::ExportEvaluationsResponse'->new($_) };

declare 'RepeatedExportEvaluationsResponse',
    as ArrayRef[ExportEvaluationsResponse()];

coerce 'RepeatedExportEvaluationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::ExportEvaluationsResponse'->new($_) } @$_ ] };

declare 'MapStringExportEvaluationsResponse',
    as HashRef[ExportEvaluationsResponse()];

declare 'FailedEvaluationsEntry',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::ExportEvaluationsResponse::FailedEvaluationsEntry'];

coerce 'FailedEvaluationsEntry',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::ExportEvaluationsResponse::FailedEvaluationsEntry'->new($_) };

declare 'RepeatedFailedEvaluationsEntry',
    as ArrayRef[FailedEvaluationsEntry()];

coerce 'RepeatedFailedEvaluationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::ExportEvaluationsResponse::FailedEvaluationsEntry'->new($_) } @$_ ] };

declare 'MapStringFailedEvaluationsEntry',
    as HashRef[FailedEvaluationsEntry()];

declare 'ExportEvaluationResultsRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::ExportEvaluationResultsRequest'];

coerce 'ExportEvaluationResultsRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::ExportEvaluationResultsRequest'->new($_) };

declare 'RepeatedExportEvaluationResultsRequest',
    as ArrayRef[ExportEvaluationResultsRequest()];

coerce 'RepeatedExportEvaluationResultsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::ExportEvaluationResultsRequest'->new($_) } @$_ ] };

declare 'MapStringExportEvaluationResultsRequest',
    as HashRef[ExportEvaluationResultsRequest()];

declare 'ExportEvaluationResultsResponse',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::ExportEvaluationResultsResponse'];

coerce 'ExportEvaluationResultsResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::ExportEvaluationResultsResponse'->new($_) };

declare 'RepeatedExportEvaluationResultsResponse',
    as ArrayRef[ExportEvaluationResultsResponse()];

coerce 'RepeatedExportEvaluationResultsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::ExportEvaluationResultsResponse'->new($_) } @$_ ] };

declare 'MapStringExportEvaluationResultsResponse',
    as HashRef[ExportEvaluationResultsResponse()];

declare 'ExportEvaluationRunsRequest',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::ExportEvaluationRunsRequest'];

coerce 'ExportEvaluationRunsRequest',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::ExportEvaluationRunsRequest'->new($_) };

declare 'RepeatedExportEvaluationRunsRequest',
    as ArrayRef[ExportEvaluationRunsRequest()];

coerce 'RepeatedExportEvaluationRunsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::ExportEvaluationRunsRequest'->new($_) } @$_ ] };

declare 'MapStringExportEvaluationRunsRequest',
    as HashRef[ExportEvaluationRunsRequest()];

declare 'ExportEvaluationRunsResponse',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::ExportEvaluationRunsResponse'];

coerce 'ExportEvaluationRunsResponse',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::ExportEvaluationRunsResponse'->new($_) };

declare 'RepeatedExportEvaluationRunsResponse',
    as ArrayRef[ExportEvaluationRunsResponse()];

coerce 'RepeatedExportEvaluationRunsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::ExportEvaluationRunsResponse'->new($_) } @$_ ] };

declare 'MapStringExportEvaluationRunsResponse',
    as HashRef[ExportEvaluationRunsResponse()];

declare 'ExportEvaluationRunsOperationMetadata',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::ExportEvaluationRunsOperationMetadata'];

coerce 'ExportEvaluationRunsOperationMetadata',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::ExportEvaluationRunsOperationMetadata'->new($_) };

declare 'RepeatedExportEvaluationRunsOperationMetadata',
    as ArrayRef[ExportEvaluationRunsOperationMetadata()];

coerce 'RepeatedExportEvaluationRunsOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::ExportEvaluationRunsOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringExportEvaluationRunsOperationMetadata',
    as HashRef[ExportEvaluationRunsOperationMetadata()];

declare 'ExportEvaluationResultsOperationMetadata',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::ExportEvaluationResultsOperationMetadata'];

coerce 'ExportEvaluationResultsOperationMetadata',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::ExportEvaluationResultsOperationMetadata'->new($_) };

declare 'RepeatedExportEvaluationResultsOperationMetadata',
    as ArrayRef[ExportEvaluationResultsOperationMetadata()];

coerce 'RepeatedExportEvaluationResultsOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::ExportEvaluationResultsOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringExportEvaluationResultsOperationMetadata',
    as HashRef[ExportEvaluationResultsOperationMetadata()];

declare 'RunEvaluationResultMetricsOperationMetadata',
    as InstanceOf['Google::Cloud::Ces::V1beta::EvaluationService::RunEvaluationResultMetricsOperationMetadata'];

coerce 'RunEvaluationResultMetricsOperationMetadata',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::EvaluationService::RunEvaluationResultMetricsOperationMetadata'->new($_) };

declare 'RepeatedRunEvaluationResultMetricsOperationMetadata',
    as ArrayRef[RunEvaluationResultMetricsOperationMetadata()];

coerce 'RepeatedRunEvaluationResultMetricsOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::EvaluationService::RunEvaluationResultMetricsOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringRunEvaluationResultMetricsOperationMetadata',
    as HashRef[RunEvaluationResultMetricsOperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1beta::EvaluationService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
