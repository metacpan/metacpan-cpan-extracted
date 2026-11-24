package Google::Cloud::Bigquery::Reservation::V1::Reservation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Edition',
    as (Int | Str);

declare 'FailoverMode',
    as (Int | Str);

declare 'Reservation',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::Reservation'];

coerce 'Reservation',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::Reservation'->new($_) };

declare 'RepeatedReservation',
    as ArrayRef[Reservation()];

coerce 'RepeatedReservation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::Reservation'->new($_) } @$_ ] };

declare 'MapStringReservation',
    as HashRef[Reservation()];

declare 'ScalingMode',
    as (Int | Str);

declare 'Autoscale',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::Reservation::Autoscale'];

coerce 'Autoscale',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::Reservation::Autoscale'->new($_) };

declare 'RepeatedAutoscale',
    as ArrayRef[Autoscale()];

coerce 'RepeatedAutoscale',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::Reservation::Autoscale'->new($_) } @$_ ] };

declare 'MapStringAutoscale',
    as HashRef[Autoscale()];

declare 'ReplicationStatus',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::Reservation::ReplicationStatus'];

coerce 'ReplicationStatus',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::Reservation::ReplicationStatus'->new($_) };

declare 'RepeatedReplicationStatus',
    as ArrayRef[ReplicationStatus()];

coerce 'RepeatedReplicationStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::Reservation::ReplicationStatus'->new($_) } @$_ ] };

declare 'MapStringReplicationStatus',
    as HashRef[ReplicationStatus()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::Reservation::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::Reservation::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::Reservation::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'SchedulingPolicy',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::SchedulingPolicy'];

coerce 'SchedulingPolicy',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::SchedulingPolicy'->new($_) };

declare 'RepeatedSchedulingPolicy',
    as ArrayRef[SchedulingPolicy()];

coerce 'RepeatedSchedulingPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::SchedulingPolicy'->new($_) } @$_ ] };

declare 'MapStringSchedulingPolicy',
    as HashRef[SchedulingPolicy()];

declare 'ReservationGroup',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::ReservationGroup'];

coerce 'ReservationGroup',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::ReservationGroup'->new($_) };

declare 'RepeatedReservationGroup',
    as ArrayRef[ReservationGroup()];

coerce 'RepeatedReservationGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::ReservationGroup'->new($_) } @$_ ] };

declare 'MapStringReservationGroup',
    as HashRef[ReservationGroup()];

declare 'CapacityCommitment',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::CapacityCommitment'];

coerce 'CapacityCommitment',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::CapacityCommitment'->new($_) };

declare 'RepeatedCapacityCommitment',
    as ArrayRef[CapacityCommitment()];

coerce 'RepeatedCapacityCommitment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::CapacityCommitment'->new($_) } @$_ ] };

declare 'MapStringCapacityCommitment',
    as HashRef[CapacityCommitment()];

declare 'CommitmentPlan',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'CreateReservationRequest',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::CreateReservationRequest'];

coerce 'CreateReservationRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::CreateReservationRequest'->new($_) };

declare 'RepeatedCreateReservationRequest',
    as ArrayRef[CreateReservationRequest()];

coerce 'RepeatedCreateReservationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::CreateReservationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateReservationRequest',
    as HashRef[CreateReservationRequest()];

declare 'ListReservationsRequest',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::ListReservationsRequest'];

coerce 'ListReservationsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::ListReservationsRequest'->new($_) };

declare 'RepeatedListReservationsRequest',
    as ArrayRef[ListReservationsRequest()];

coerce 'RepeatedListReservationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::ListReservationsRequest'->new($_) } @$_ ] };

declare 'MapStringListReservationsRequest',
    as HashRef[ListReservationsRequest()];

declare 'ListReservationsResponse',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::ListReservationsResponse'];

coerce 'ListReservationsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::ListReservationsResponse'->new($_) };

declare 'RepeatedListReservationsResponse',
    as ArrayRef[ListReservationsResponse()];

coerce 'RepeatedListReservationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::ListReservationsResponse'->new($_) } @$_ ] };

declare 'MapStringListReservationsResponse',
    as HashRef[ListReservationsResponse()];

declare 'GetReservationRequest',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::GetReservationRequest'];

coerce 'GetReservationRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::GetReservationRequest'->new($_) };

declare 'RepeatedGetReservationRequest',
    as ArrayRef[GetReservationRequest()];

coerce 'RepeatedGetReservationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::GetReservationRequest'->new($_) } @$_ ] };

declare 'MapStringGetReservationRequest',
    as HashRef[GetReservationRequest()];

declare 'DeleteReservationRequest',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::DeleteReservationRequest'];

coerce 'DeleteReservationRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::DeleteReservationRequest'->new($_) };

declare 'RepeatedDeleteReservationRequest',
    as ArrayRef[DeleteReservationRequest()];

coerce 'RepeatedDeleteReservationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::DeleteReservationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteReservationRequest',
    as HashRef[DeleteReservationRequest()];

declare 'UpdateReservationRequest',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::UpdateReservationRequest'];

coerce 'UpdateReservationRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::UpdateReservationRequest'->new($_) };

declare 'RepeatedUpdateReservationRequest',
    as ArrayRef[UpdateReservationRequest()];

coerce 'RepeatedUpdateReservationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::UpdateReservationRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateReservationRequest',
    as HashRef[UpdateReservationRequest()];

declare 'FailoverReservationRequest',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::FailoverReservationRequest'];

coerce 'FailoverReservationRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::FailoverReservationRequest'->new($_) };

declare 'RepeatedFailoverReservationRequest',
    as ArrayRef[FailoverReservationRequest()];

coerce 'RepeatedFailoverReservationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::FailoverReservationRequest'->new($_) } @$_ ] };

declare 'MapStringFailoverReservationRequest',
    as HashRef[FailoverReservationRequest()];

declare 'CreateReservationGroupRequest',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::CreateReservationGroupRequest'];

coerce 'CreateReservationGroupRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::CreateReservationGroupRequest'->new($_) };

declare 'RepeatedCreateReservationGroupRequest',
    as ArrayRef[CreateReservationGroupRequest()];

coerce 'RepeatedCreateReservationGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::CreateReservationGroupRequest'->new($_) } @$_ ] };

declare 'MapStringCreateReservationGroupRequest',
    as HashRef[CreateReservationGroupRequest()];

declare 'GetReservationGroupRequest',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::GetReservationGroupRequest'];

coerce 'GetReservationGroupRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::GetReservationGroupRequest'->new($_) };

declare 'RepeatedGetReservationGroupRequest',
    as ArrayRef[GetReservationGroupRequest()];

coerce 'RepeatedGetReservationGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::GetReservationGroupRequest'->new($_) } @$_ ] };

declare 'MapStringGetReservationGroupRequest',
    as HashRef[GetReservationGroupRequest()];

declare 'ListReservationGroupsRequest',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::ListReservationGroupsRequest'];

coerce 'ListReservationGroupsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::ListReservationGroupsRequest'->new($_) };

declare 'RepeatedListReservationGroupsRequest',
    as ArrayRef[ListReservationGroupsRequest()];

coerce 'RepeatedListReservationGroupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::ListReservationGroupsRequest'->new($_) } @$_ ] };

declare 'MapStringListReservationGroupsRequest',
    as HashRef[ListReservationGroupsRequest()];

declare 'ListReservationGroupsResponse',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::ListReservationGroupsResponse'];

coerce 'ListReservationGroupsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::ListReservationGroupsResponse'->new($_) };

declare 'RepeatedListReservationGroupsResponse',
    as ArrayRef[ListReservationGroupsResponse()];

coerce 'RepeatedListReservationGroupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::ListReservationGroupsResponse'->new($_) } @$_ ] };

declare 'MapStringListReservationGroupsResponse',
    as HashRef[ListReservationGroupsResponse()];

declare 'DeleteReservationGroupRequest',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::DeleteReservationGroupRequest'];

coerce 'DeleteReservationGroupRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::DeleteReservationGroupRequest'->new($_) };

declare 'RepeatedDeleteReservationGroupRequest',
    as ArrayRef[DeleteReservationGroupRequest()];

coerce 'RepeatedDeleteReservationGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::DeleteReservationGroupRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteReservationGroupRequest',
    as HashRef[DeleteReservationGroupRequest()];

declare 'UpdateReservationGroupRequest',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::UpdateReservationGroupRequest'];

coerce 'UpdateReservationGroupRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::UpdateReservationGroupRequest'->new($_) };

declare 'RepeatedUpdateReservationGroupRequest',
    as ArrayRef[UpdateReservationGroupRequest()];

coerce 'RepeatedUpdateReservationGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::UpdateReservationGroupRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateReservationGroupRequest',
    as HashRef[UpdateReservationGroupRequest()];

declare 'CreateCapacityCommitmentRequest',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::CreateCapacityCommitmentRequest'];

coerce 'CreateCapacityCommitmentRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::CreateCapacityCommitmentRequest'->new($_) };

declare 'RepeatedCreateCapacityCommitmentRequest',
    as ArrayRef[CreateCapacityCommitmentRequest()];

coerce 'RepeatedCreateCapacityCommitmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::CreateCapacityCommitmentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCapacityCommitmentRequest',
    as HashRef[CreateCapacityCommitmentRequest()];

declare 'ListCapacityCommitmentsRequest',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::ListCapacityCommitmentsRequest'];

coerce 'ListCapacityCommitmentsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::ListCapacityCommitmentsRequest'->new($_) };

declare 'RepeatedListCapacityCommitmentsRequest',
    as ArrayRef[ListCapacityCommitmentsRequest()];

coerce 'RepeatedListCapacityCommitmentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::ListCapacityCommitmentsRequest'->new($_) } @$_ ] };

declare 'MapStringListCapacityCommitmentsRequest',
    as HashRef[ListCapacityCommitmentsRequest()];

declare 'ListCapacityCommitmentsResponse',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::ListCapacityCommitmentsResponse'];

coerce 'ListCapacityCommitmentsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::ListCapacityCommitmentsResponse'->new($_) };

declare 'RepeatedListCapacityCommitmentsResponse',
    as ArrayRef[ListCapacityCommitmentsResponse()];

coerce 'RepeatedListCapacityCommitmentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::ListCapacityCommitmentsResponse'->new($_) } @$_ ] };

declare 'MapStringListCapacityCommitmentsResponse',
    as HashRef[ListCapacityCommitmentsResponse()];

declare 'GetCapacityCommitmentRequest',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::GetCapacityCommitmentRequest'];

coerce 'GetCapacityCommitmentRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::GetCapacityCommitmentRequest'->new($_) };

declare 'RepeatedGetCapacityCommitmentRequest',
    as ArrayRef[GetCapacityCommitmentRequest()];

coerce 'RepeatedGetCapacityCommitmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::GetCapacityCommitmentRequest'->new($_) } @$_ ] };

declare 'MapStringGetCapacityCommitmentRequest',
    as HashRef[GetCapacityCommitmentRequest()];

declare 'DeleteCapacityCommitmentRequest',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::DeleteCapacityCommitmentRequest'];

coerce 'DeleteCapacityCommitmentRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::DeleteCapacityCommitmentRequest'->new($_) };

declare 'RepeatedDeleteCapacityCommitmentRequest',
    as ArrayRef[DeleteCapacityCommitmentRequest()];

coerce 'RepeatedDeleteCapacityCommitmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::DeleteCapacityCommitmentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCapacityCommitmentRequest',
    as HashRef[DeleteCapacityCommitmentRequest()];

declare 'UpdateCapacityCommitmentRequest',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::UpdateCapacityCommitmentRequest'];

coerce 'UpdateCapacityCommitmentRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::UpdateCapacityCommitmentRequest'->new($_) };

declare 'RepeatedUpdateCapacityCommitmentRequest',
    as ArrayRef[UpdateCapacityCommitmentRequest()];

coerce 'RepeatedUpdateCapacityCommitmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::UpdateCapacityCommitmentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCapacityCommitmentRequest',
    as HashRef[UpdateCapacityCommitmentRequest()];

declare 'SplitCapacityCommitmentRequest',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::SplitCapacityCommitmentRequest'];

coerce 'SplitCapacityCommitmentRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::SplitCapacityCommitmentRequest'->new($_) };

declare 'RepeatedSplitCapacityCommitmentRequest',
    as ArrayRef[SplitCapacityCommitmentRequest()];

coerce 'RepeatedSplitCapacityCommitmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::SplitCapacityCommitmentRequest'->new($_) } @$_ ] };

declare 'MapStringSplitCapacityCommitmentRequest',
    as HashRef[SplitCapacityCommitmentRequest()];

declare 'SplitCapacityCommitmentResponse',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::SplitCapacityCommitmentResponse'];

coerce 'SplitCapacityCommitmentResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::SplitCapacityCommitmentResponse'->new($_) };

declare 'RepeatedSplitCapacityCommitmentResponse',
    as ArrayRef[SplitCapacityCommitmentResponse()];

coerce 'RepeatedSplitCapacityCommitmentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::SplitCapacityCommitmentResponse'->new($_) } @$_ ] };

declare 'MapStringSplitCapacityCommitmentResponse',
    as HashRef[SplitCapacityCommitmentResponse()];

declare 'MergeCapacityCommitmentsRequest',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::MergeCapacityCommitmentsRequest'];

coerce 'MergeCapacityCommitmentsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::MergeCapacityCommitmentsRequest'->new($_) };

declare 'RepeatedMergeCapacityCommitmentsRequest',
    as ArrayRef[MergeCapacityCommitmentsRequest()];

coerce 'RepeatedMergeCapacityCommitmentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::MergeCapacityCommitmentsRequest'->new($_) } @$_ ] };

declare 'MapStringMergeCapacityCommitmentsRequest',
    as HashRef[MergeCapacityCommitmentsRequest()];

declare 'Assignment',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::Assignment'];

coerce 'Assignment',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::Assignment'->new($_) };

declare 'RepeatedAssignment',
    as ArrayRef[Assignment()];

coerce 'RepeatedAssignment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::Assignment'->new($_) } @$_ ] };

declare 'MapStringAssignment',
    as HashRef[Assignment()];

declare 'JobType',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'CreateAssignmentRequest',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::CreateAssignmentRequest'];

coerce 'CreateAssignmentRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::CreateAssignmentRequest'->new($_) };

declare 'RepeatedCreateAssignmentRequest',
    as ArrayRef[CreateAssignmentRequest()];

coerce 'RepeatedCreateAssignmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::CreateAssignmentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAssignmentRequest',
    as HashRef[CreateAssignmentRequest()];

declare 'ListAssignmentsRequest',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::ListAssignmentsRequest'];

coerce 'ListAssignmentsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::ListAssignmentsRequest'->new($_) };

declare 'RepeatedListAssignmentsRequest',
    as ArrayRef[ListAssignmentsRequest()];

coerce 'RepeatedListAssignmentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::ListAssignmentsRequest'->new($_) } @$_ ] };

declare 'MapStringListAssignmentsRequest',
    as HashRef[ListAssignmentsRequest()];

declare 'ListAssignmentsResponse',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::ListAssignmentsResponse'];

coerce 'ListAssignmentsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::ListAssignmentsResponse'->new($_) };

declare 'RepeatedListAssignmentsResponse',
    as ArrayRef[ListAssignmentsResponse()];

coerce 'RepeatedListAssignmentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::ListAssignmentsResponse'->new($_) } @$_ ] };

declare 'MapStringListAssignmentsResponse',
    as HashRef[ListAssignmentsResponse()];

declare 'DeleteAssignmentRequest',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::DeleteAssignmentRequest'];

coerce 'DeleteAssignmentRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::DeleteAssignmentRequest'->new($_) };

declare 'RepeatedDeleteAssignmentRequest',
    as ArrayRef[DeleteAssignmentRequest()];

coerce 'RepeatedDeleteAssignmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::DeleteAssignmentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAssignmentRequest',
    as HashRef[DeleteAssignmentRequest()];

declare 'SearchAssignmentsRequest',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::SearchAssignmentsRequest'];

coerce 'SearchAssignmentsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::SearchAssignmentsRequest'->new($_) };

declare 'RepeatedSearchAssignmentsRequest',
    as ArrayRef[SearchAssignmentsRequest()];

coerce 'RepeatedSearchAssignmentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::SearchAssignmentsRequest'->new($_) } @$_ ] };

declare 'MapStringSearchAssignmentsRequest',
    as HashRef[SearchAssignmentsRequest()];

declare 'SearchAllAssignmentsRequest',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::SearchAllAssignmentsRequest'];

coerce 'SearchAllAssignmentsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::SearchAllAssignmentsRequest'->new($_) };

declare 'RepeatedSearchAllAssignmentsRequest',
    as ArrayRef[SearchAllAssignmentsRequest()];

coerce 'RepeatedSearchAllAssignmentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::SearchAllAssignmentsRequest'->new($_) } @$_ ] };

declare 'MapStringSearchAllAssignmentsRequest',
    as HashRef[SearchAllAssignmentsRequest()];

declare 'SearchAssignmentsResponse',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::SearchAssignmentsResponse'];

coerce 'SearchAssignmentsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::SearchAssignmentsResponse'->new($_) };

declare 'RepeatedSearchAssignmentsResponse',
    as ArrayRef[SearchAssignmentsResponse()];

coerce 'RepeatedSearchAssignmentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::SearchAssignmentsResponse'->new($_) } @$_ ] };

declare 'MapStringSearchAssignmentsResponse',
    as HashRef[SearchAssignmentsResponse()];

declare 'SearchAllAssignmentsResponse',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::SearchAllAssignmentsResponse'];

coerce 'SearchAllAssignmentsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::SearchAllAssignmentsResponse'->new($_) };

declare 'RepeatedSearchAllAssignmentsResponse',
    as ArrayRef[SearchAllAssignmentsResponse()];

coerce 'RepeatedSearchAllAssignmentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::SearchAllAssignmentsResponse'->new($_) } @$_ ] };

declare 'MapStringSearchAllAssignmentsResponse',
    as HashRef[SearchAllAssignmentsResponse()];

declare 'MoveAssignmentRequest',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::MoveAssignmentRequest'];

coerce 'MoveAssignmentRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::MoveAssignmentRequest'->new($_) };

declare 'RepeatedMoveAssignmentRequest',
    as ArrayRef[MoveAssignmentRequest()];

coerce 'RepeatedMoveAssignmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::MoveAssignmentRequest'->new($_) } @$_ ] };

declare 'MapStringMoveAssignmentRequest',
    as HashRef[MoveAssignmentRequest()];

declare 'UpdateAssignmentRequest',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::UpdateAssignmentRequest'];

coerce 'UpdateAssignmentRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::UpdateAssignmentRequest'->new($_) };

declare 'RepeatedUpdateAssignmentRequest',
    as ArrayRef[UpdateAssignmentRequest()];

coerce 'RepeatedUpdateAssignmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::UpdateAssignmentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAssignmentRequest',
    as HashRef[UpdateAssignmentRequest()];

declare 'TableReference',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::TableReference'];

coerce 'TableReference',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::TableReference'->new($_) };

declare 'RepeatedTableReference',
    as ArrayRef[TableReference()];

coerce 'RepeatedTableReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::TableReference'->new($_) } @$_ ] };

declare 'MapStringTableReference',
    as HashRef[TableReference()];

declare 'BiReservation',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::BiReservation'];

coerce 'BiReservation',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::BiReservation'->new($_) };

declare 'RepeatedBiReservation',
    as ArrayRef[BiReservation()];

coerce 'RepeatedBiReservation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::BiReservation'->new($_) } @$_ ] };

declare 'MapStringBiReservation',
    as HashRef[BiReservation()];

declare 'GetBiReservationRequest',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::GetBiReservationRequest'];

coerce 'GetBiReservationRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::GetBiReservationRequest'->new($_) };

declare 'RepeatedGetBiReservationRequest',
    as ArrayRef[GetBiReservationRequest()];

coerce 'RepeatedGetBiReservationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::GetBiReservationRequest'->new($_) } @$_ ] };

declare 'MapStringGetBiReservationRequest',
    as HashRef[GetBiReservationRequest()];

declare 'UpdateBiReservationRequest',
    as InstanceOf['Google::Cloud::Bigquery::Reservation::V1::Reservation::UpdateBiReservationRequest'];

coerce 'UpdateBiReservationRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::UpdateBiReservationRequest'->new($_) };

declare 'RepeatedUpdateBiReservationRequest',
    as ArrayRef[UpdateBiReservationRequest()];

coerce 'RepeatedUpdateBiReservationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Reservation::V1::Reservation::UpdateBiReservationRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBiReservationRequest',
    as HashRef[UpdateBiReservationRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Reservation::V1::Reservation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
