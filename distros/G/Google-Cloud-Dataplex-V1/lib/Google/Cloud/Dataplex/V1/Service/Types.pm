package Google::Cloud::Dataplex::V1::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateLakeRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::CreateLakeRequest'];

coerce 'CreateLakeRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::CreateLakeRequest'->new($_) };

declare 'RepeatedCreateLakeRequest',
    as ArrayRef[CreateLakeRequest()];

coerce 'RepeatedCreateLakeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::CreateLakeRequest'->new($_) } @$_ ] };

declare 'MapStringCreateLakeRequest',
    as HashRef[CreateLakeRequest()];

declare 'UpdateLakeRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::UpdateLakeRequest'];

coerce 'UpdateLakeRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::UpdateLakeRequest'->new($_) };

declare 'RepeatedUpdateLakeRequest',
    as ArrayRef[UpdateLakeRequest()];

coerce 'RepeatedUpdateLakeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::UpdateLakeRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateLakeRequest',
    as HashRef[UpdateLakeRequest()];

declare 'DeleteLakeRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::DeleteLakeRequest'];

coerce 'DeleteLakeRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::DeleteLakeRequest'->new($_) };

declare 'RepeatedDeleteLakeRequest',
    as ArrayRef[DeleteLakeRequest()];

coerce 'RepeatedDeleteLakeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::DeleteLakeRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteLakeRequest',
    as HashRef[DeleteLakeRequest()];

declare 'ListLakesRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::ListLakesRequest'];

coerce 'ListLakesRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::ListLakesRequest'->new($_) };

declare 'RepeatedListLakesRequest',
    as ArrayRef[ListLakesRequest()];

coerce 'RepeatedListLakesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::ListLakesRequest'->new($_) } @$_ ] };

declare 'MapStringListLakesRequest',
    as HashRef[ListLakesRequest()];

declare 'ListLakesResponse',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::ListLakesResponse'];

coerce 'ListLakesResponse',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::ListLakesResponse'->new($_) };

declare 'RepeatedListLakesResponse',
    as ArrayRef[ListLakesResponse()];

coerce 'RepeatedListLakesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::ListLakesResponse'->new($_) } @$_ ] };

declare 'MapStringListLakesResponse',
    as HashRef[ListLakesResponse()];

declare 'ListLakeActionsRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::ListLakeActionsRequest'];

coerce 'ListLakeActionsRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::ListLakeActionsRequest'->new($_) };

declare 'RepeatedListLakeActionsRequest',
    as ArrayRef[ListLakeActionsRequest()];

coerce 'RepeatedListLakeActionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::ListLakeActionsRequest'->new($_) } @$_ ] };

declare 'MapStringListLakeActionsRequest',
    as HashRef[ListLakeActionsRequest()];

declare 'ListActionsResponse',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::ListActionsResponse'];

coerce 'ListActionsResponse',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::ListActionsResponse'->new($_) };

declare 'RepeatedListActionsResponse',
    as ArrayRef[ListActionsResponse()];

coerce 'RepeatedListActionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::ListActionsResponse'->new($_) } @$_ ] };

declare 'MapStringListActionsResponse',
    as HashRef[ListActionsResponse()];

declare 'GetLakeRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::GetLakeRequest'];

coerce 'GetLakeRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::GetLakeRequest'->new($_) };

declare 'RepeatedGetLakeRequest',
    as ArrayRef[GetLakeRequest()];

coerce 'RepeatedGetLakeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::GetLakeRequest'->new($_) } @$_ ] };

declare 'MapStringGetLakeRequest',
    as HashRef[GetLakeRequest()];

declare 'CreateZoneRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::CreateZoneRequest'];

coerce 'CreateZoneRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::CreateZoneRequest'->new($_) };

declare 'RepeatedCreateZoneRequest',
    as ArrayRef[CreateZoneRequest()];

coerce 'RepeatedCreateZoneRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::CreateZoneRequest'->new($_) } @$_ ] };

declare 'MapStringCreateZoneRequest',
    as HashRef[CreateZoneRequest()];

declare 'UpdateZoneRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::UpdateZoneRequest'];

coerce 'UpdateZoneRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::UpdateZoneRequest'->new($_) };

declare 'RepeatedUpdateZoneRequest',
    as ArrayRef[UpdateZoneRequest()];

coerce 'RepeatedUpdateZoneRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::UpdateZoneRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateZoneRequest',
    as HashRef[UpdateZoneRequest()];

declare 'DeleteZoneRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::DeleteZoneRequest'];

coerce 'DeleteZoneRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::DeleteZoneRequest'->new($_) };

declare 'RepeatedDeleteZoneRequest',
    as ArrayRef[DeleteZoneRequest()];

coerce 'RepeatedDeleteZoneRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::DeleteZoneRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteZoneRequest',
    as HashRef[DeleteZoneRequest()];

declare 'ListZonesRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::ListZonesRequest'];

coerce 'ListZonesRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::ListZonesRequest'->new($_) };

declare 'RepeatedListZonesRequest',
    as ArrayRef[ListZonesRequest()];

coerce 'RepeatedListZonesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::ListZonesRequest'->new($_) } @$_ ] };

declare 'MapStringListZonesRequest',
    as HashRef[ListZonesRequest()];

declare 'ListZonesResponse',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::ListZonesResponse'];

coerce 'ListZonesResponse',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::ListZonesResponse'->new($_) };

declare 'RepeatedListZonesResponse',
    as ArrayRef[ListZonesResponse()];

coerce 'RepeatedListZonesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::ListZonesResponse'->new($_) } @$_ ] };

declare 'MapStringListZonesResponse',
    as HashRef[ListZonesResponse()];

declare 'ListZoneActionsRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::ListZoneActionsRequest'];

coerce 'ListZoneActionsRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::ListZoneActionsRequest'->new($_) };

declare 'RepeatedListZoneActionsRequest',
    as ArrayRef[ListZoneActionsRequest()];

coerce 'RepeatedListZoneActionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::ListZoneActionsRequest'->new($_) } @$_ ] };

declare 'MapStringListZoneActionsRequest',
    as HashRef[ListZoneActionsRequest()];

declare 'GetZoneRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::GetZoneRequest'];

coerce 'GetZoneRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::GetZoneRequest'->new($_) };

declare 'RepeatedGetZoneRequest',
    as ArrayRef[GetZoneRequest()];

coerce 'RepeatedGetZoneRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::GetZoneRequest'->new($_) } @$_ ] };

declare 'MapStringGetZoneRequest',
    as HashRef[GetZoneRequest()];

declare 'CreateAssetRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::CreateAssetRequest'];

coerce 'CreateAssetRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::CreateAssetRequest'->new($_) };

declare 'RepeatedCreateAssetRequest',
    as ArrayRef[CreateAssetRequest()];

coerce 'RepeatedCreateAssetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::CreateAssetRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAssetRequest',
    as HashRef[CreateAssetRequest()];

declare 'UpdateAssetRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::UpdateAssetRequest'];

coerce 'UpdateAssetRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::UpdateAssetRequest'->new($_) };

declare 'RepeatedUpdateAssetRequest',
    as ArrayRef[UpdateAssetRequest()];

coerce 'RepeatedUpdateAssetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::UpdateAssetRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAssetRequest',
    as HashRef[UpdateAssetRequest()];

declare 'DeleteAssetRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::DeleteAssetRequest'];

coerce 'DeleteAssetRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::DeleteAssetRequest'->new($_) };

declare 'RepeatedDeleteAssetRequest',
    as ArrayRef[DeleteAssetRequest()];

coerce 'RepeatedDeleteAssetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::DeleteAssetRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAssetRequest',
    as HashRef[DeleteAssetRequest()];

declare 'ListAssetsRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::ListAssetsRequest'];

coerce 'ListAssetsRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::ListAssetsRequest'->new($_) };

declare 'RepeatedListAssetsRequest',
    as ArrayRef[ListAssetsRequest()];

coerce 'RepeatedListAssetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::ListAssetsRequest'->new($_) } @$_ ] };

declare 'MapStringListAssetsRequest',
    as HashRef[ListAssetsRequest()];

declare 'ListAssetsResponse',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::ListAssetsResponse'];

coerce 'ListAssetsResponse',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::ListAssetsResponse'->new($_) };

declare 'RepeatedListAssetsResponse',
    as ArrayRef[ListAssetsResponse()];

coerce 'RepeatedListAssetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::ListAssetsResponse'->new($_) } @$_ ] };

declare 'MapStringListAssetsResponse',
    as HashRef[ListAssetsResponse()];

declare 'ListAssetActionsRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::ListAssetActionsRequest'];

coerce 'ListAssetActionsRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::ListAssetActionsRequest'->new($_) };

declare 'RepeatedListAssetActionsRequest',
    as ArrayRef[ListAssetActionsRequest()];

coerce 'RepeatedListAssetActionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::ListAssetActionsRequest'->new($_) } @$_ ] };

declare 'MapStringListAssetActionsRequest',
    as HashRef[ListAssetActionsRequest()];

declare 'GetAssetRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::GetAssetRequest'];

coerce 'GetAssetRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::GetAssetRequest'->new($_) };

declare 'RepeatedGetAssetRequest',
    as ArrayRef[GetAssetRequest()];

coerce 'RepeatedGetAssetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::GetAssetRequest'->new($_) } @$_ ] };

declare 'MapStringGetAssetRequest',
    as HashRef[GetAssetRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'CreateTaskRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::CreateTaskRequest'];

coerce 'CreateTaskRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::CreateTaskRequest'->new($_) };

declare 'RepeatedCreateTaskRequest',
    as ArrayRef[CreateTaskRequest()];

coerce 'RepeatedCreateTaskRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::CreateTaskRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTaskRequest',
    as HashRef[CreateTaskRequest()];

declare 'UpdateTaskRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::UpdateTaskRequest'];

coerce 'UpdateTaskRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::UpdateTaskRequest'->new($_) };

declare 'RepeatedUpdateTaskRequest',
    as ArrayRef[UpdateTaskRequest()];

coerce 'RepeatedUpdateTaskRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::UpdateTaskRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTaskRequest',
    as HashRef[UpdateTaskRequest()];

declare 'DeleteTaskRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::DeleteTaskRequest'];

coerce 'DeleteTaskRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::DeleteTaskRequest'->new($_) };

declare 'RepeatedDeleteTaskRequest',
    as ArrayRef[DeleteTaskRequest()];

coerce 'RepeatedDeleteTaskRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::DeleteTaskRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTaskRequest',
    as HashRef[DeleteTaskRequest()];

declare 'ListTasksRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::ListTasksRequest'];

coerce 'ListTasksRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::ListTasksRequest'->new($_) };

declare 'RepeatedListTasksRequest',
    as ArrayRef[ListTasksRequest()];

coerce 'RepeatedListTasksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::ListTasksRequest'->new($_) } @$_ ] };

declare 'MapStringListTasksRequest',
    as HashRef[ListTasksRequest()];

declare 'ListTasksResponse',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::ListTasksResponse'];

coerce 'ListTasksResponse',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::ListTasksResponse'->new($_) };

declare 'RepeatedListTasksResponse',
    as ArrayRef[ListTasksResponse()];

coerce 'RepeatedListTasksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::ListTasksResponse'->new($_) } @$_ ] };

declare 'MapStringListTasksResponse',
    as HashRef[ListTasksResponse()];

declare 'GetTaskRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::GetTaskRequest'];

coerce 'GetTaskRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::GetTaskRequest'->new($_) };

declare 'RepeatedGetTaskRequest',
    as ArrayRef[GetTaskRequest()];

coerce 'RepeatedGetTaskRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::GetTaskRequest'->new($_) } @$_ ] };

declare 'MapStringGetTaskRequest',
    as HashRef[GetTaskRequest()];

declare 'GetJobRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::GetJobRequest'];

coerce 'GetJobRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::GetJobRequest'->new($_) };

declare 'RepeatedGetJobRequest',
    as ArrayRef[GetJobRequest()];

coerce 'RepeatedGetJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::GetJobRequest'->new($_) } @$_ ] };

declare 'MapStringGetJobRequest',
    as HashRef[GetJobRequest()];

declare 'RunTaskRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::RunTaskRequest'];

coerce 'RunTaskRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::RunTaskRequest'->new($_) };

declare 'RepeatedRunTaskRequest',
    as ArrayRef[RunTaskRequest()];

coerce 'RepeatedRunTaskRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::RunTaskRequest'->new($_) } @$_ ] };

declare 'MapStringRunTaskRequest',
    as HashRef[RunTaskRequest()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::RunTaskRequest::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::RunTaskRequest::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::RunTaskRequest::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ArgsEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::RunTaskRequest::ArgsEntry'];

coerce 'ArgsEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::RunTaskRequest::ArgsEntry'->new($_) };

declare 'RepeatedArgsEntry',
    as ArrayRef[ArgsEntry()];

coerce 'RepeatedArgsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::RunTaskRequest::ArgsEntry'->new($_) } @$_ ] };

declare 'MapStringArgsEntry',
    as HashRef[ArgsEntry()];

declare 'RunTaskResponse',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::RunTaskResponse'];

coerce 'RunTaskResponse',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::RunTaskResponse'->new($_) };

declare 'RepeatedRunTaskResponse',
    as ArrayRef[RunTaskResponse()];

coerce 'RepeatedRunTaskResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::RunTaskResponse'->new($_) } @$_ ] };

declare 'MapStringRunTaskResponse',
    as HashRef[RunTaskResponse()];

declare 'ListJobsRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::ListJobsRequest'];

coerce 'ListJobsRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::ListJobsRequest'->new($_) };

declare 'RepeatedListJobsRequest',
    as ArrayRef[ListJobsRequest()];

coerce 'RepeatedListJobsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::ListJobsRequest'->new($_) } @$_ ] };

declare 'MapStringListJobsRequest',
    as HashRef[ListJobsRequest()];

declare 'ListJobsResponse',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::ListJobsResponse'];

coerce 'ListJobsResponse',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::ListJobsResponse'->new($_) };

declare 'RepeatedListJobsResponse',
    as ArrayRef[ListJobsResponse()];

coerce 'RepeatedListJobsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::ListJobsResponse'->new($_) } @$_ ] };

declare 'MapStringListJobsResponse',
    as HashRef[ListJobsResponse()];

declare 'CancelJobRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Service::CancelJobRequest'];

coerce 'CancelJobRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Service::CancelJobRequest'->new($_) };

declare 'RepeatedCancelJobRequest',
    as ArrayRef[CancelJobRequest()];

coerce 'RepeatedCancelJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Service::CancelJobRequest'->new($_) } @$_ ] };

declare 'MapStringCancelJobRequest',
    as HashRef[CancelJobRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Dataplex::V1::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
