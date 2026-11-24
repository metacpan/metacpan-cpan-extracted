package Google::Cloud::Chronicle::V1::FindingsRefinement::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FindingsRefinementType',
    as (Int | Str);

declare 'FindingsRefinement',
    as InstanceOf['Google::Cloud::Chronicle::V1::FindingsRefinement::FindingsRefinement'];

coerce 'FindingsRefinement',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::FindingsRefinement::FindingsRefinement'->new($_) };

declare 'RepeatedFindingsRefinement',
    as ArrayRef[FindingsRefinement()];

coerce 'RepeatedFindingsRefinement',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::FindingsRefinement::FindingsRefinement'->new($_) } @$_ ] };

declare 'MapStringFindingsRefinement',
    as HashRef[FindingsRefinement()];

declare 'FindingsRefinementDeployment',
    as InstanceOf['Google::Cloud::Chronicle::V1::FindingsRefinement::FindingsRefinementDeployment'];

coerce 'FindingsRefinementDeployment',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::FindingsRefinement::FindingsRefinementDeployment'->new($_) };

declare 'RepeatedFindingsRefinementDeployment',
    as ArrayRef[FindingsRefinementDeployment()];

coerce 'RepeatedFindingsRefinementDeployment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::FindingsRefinement::FindingsRefinementDeployment'->new($_) } @$_ ] };

declare 'MapStringFindingsRefinementDeployment',
    as HashRef[FindingsRefinementDeployment()];

declare 'DetectionExclusionApplication',
    as InstanceOf['Google::Cloud::Chronicle::V1::FindingsRefinement::DetectionExclusionApplication'];

coerce 'DetectionExclusionApplication',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::FindingsRefinement::DetectionExclusionApplication'->new($_) };

declare 'RepeatedDetectionExclusionApplication',
    as ArrayRef[DetectionExclusionApplication()];

coerce 'RepeatedDetectionExclusionApplication',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::FindingsRefinement::DetectionExclusionApplication'->new($_) } @$_ ] };

declare 'MapStringDetectionExclusionApplication',
    as HashRef[DetectionExclusionApplication()];

declare 'FindingsRefinementActivity',
    as InstanceOf['Google::Cloud::Chronicle::V1::FindingsRefinement::FindingsRefinementActivity'];

coerce 'FindingsRefinementActivity',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::FindingsRefinement::FindingsRefinementActivity'->new($_) };

declare 'RepeatedFindingsRefinementActivity',
    as ArrayRef[FindingsRefinementActivity()];

coerce 'RepeatedFindingsRefinementActivity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::FindingsRefinement::FindingsRefinementActivity'->new($_) } @$_ ] };

declare 'MapStringFindingsRefinementActivity',
    as HashRef[FindingsRefinementActivity()];

declare 'DetectionExclusionActivity',
    as InstanceOf['Google::Cloud::Chronicle::V1::FindingsRefinement::DetectionExclusionActivity'];

coerce 'DetectionExclusionActivity',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::FindingsRefinement::DetectionExclusionActivity'->new($_) };

declare 'RepeatedDetectionExclusionActivity',
    as ArrayRef[DetectionExclusionActivity()];

coerce 'RepeatedDetectionExclusionActivity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::FindingsRefinement::DetectionExclusionActivity'->new($_) } @$_ ] };

declare 'MapStringDetectionExclusionActivity',
    as HashRef[DetectionExclusionActivity()];

declare 'DetectionExclusionDetectorActivity',
    as InstanceOf['Google::Cloud::Chronicle::V1::FindingsRefinement::DetectionExclusionActivity::DetectionExclusionDetectorActivity'];

coerce 'DetectionExclusionDetectorActivity',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::FindingsRefinement::DetectionExclusionActivity::DetectionExclusionDetectorActivity'->new($_) };

declare 'RepeatedDetectionExclusionDetectorActivity',
    as ArrayRef[DetectionExclusionDetectorActivity()];

coerce 'RepeatedDetectionExclusionDetectorActivity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::FindingsRefinement::DetectionExclusionActivity::DetectionExclusionDetectorActivity'->new($_) } @$_ ] };

declare 'MapStringDetectionExclusionDetectorActivity',
    as HashRef[DetectionExclusionDetectorActivity()];

declare 'GetFindingsRefinementRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::FindingsRefinement::GetFindingsRefinementRequest'];

coerce 'GetFindingsRefinementRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::FindingsRefinement::GetFindingsRefinementRequest'->new($_) };

declare 'RepeatedGetFindingsRefinementRequest',
    as ArrayRef[GetFindingsRefinementRequest()];

coerce 'RepeatedGetFindingsRefinementRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::FindingsRefinement::GetFindingsRefinementRequest'->new($_) } @$_ ] };

declare 'MapStringGetFindingsRefinementRequest',
    as HashRef[GetFindingsRefinementRequest()];

declare 'ListFindingsRefinementsRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::FindingsRefinement::ListFindingsRefinementsRequest'];

coerce 'ListFindingsRefinementsRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::FindingsRefinement::ListFindingsRefinementsRequest'->new($_) };

declare 'RepeatedListFindingsRefinementsRequest',
    as ArrayRef[ListFindingsRefinementsRequest()];

coerce 'RepeatedListFindingsRefinementsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::FindingsRefinement::ListFindingsRefinementsRequest'->new($_) } @$_ ] };

declare 'MapStringListFindingsRefinementsRequest',
    as HashRef[ListFindingsRefinementsRequest()];

declare 'ListFindingsRefinementsResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::FindingsRefinement::ListFindingsRefinementsResponse'];

coerce 'ListFindingsRefinementsResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::FindingsRefinement::ListFindingsRefinementsResponse'->new($_) };

declare 'RepeatedListFindingsRefinementsResponse',
    as ArrayRef[ListFindingsRefinementsResponse()];

coerce 'RepeatedListFindingsRefinementsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::FindingsRefinement::ListFindingsRefinementsResponse'->new($_) } @$_ ] };

declare 'MapStringListFindingsRefinementsResponse',
    as HashRef[ListFindingsRefinementsResponse()];

declare 'CreateFindingsRefinementRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::FindingsRefinement::CreateFindingsRefinementRequest'];

coerce 'CreateFindingsRefinementRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::FindingsRefinement::CreateFindingsRefinementRequest'->new($_) };

declare 'RepeatedCreateFindingsRefinementRequest',
    as ArrayRef[CreateFindingsRefinementRequest()];

coerce 'RepeatedCreateFindingsRefinementRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::FindingsRefinement::CreateFindingsRefinementRequest'->new($_) } @$_ ] };

declare 'MapStringCreateFindingsRefinementRequest',
    as HashRef[CreateFindingsRefinementRequest()];

declare 'UpdateFindingsRefinementRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::FindingsRefinement::UpdateFindingsRefinementRequest'];

coerce 'UpdateFindingsRefinementRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::FindingsRefinement::UpdateFindingsRefinementRequest'->new($_) };

declare 'RepeatedUpdateFindingsRefinementRequest',
    as ArrayRef[UpdateFindingsRefinementRequest()];

coerce 'RepeatedUpdateFindingsRefinementRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::FindingsRefinement::UpdateFindingsRefinementRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateFindingsRefinementRequest',
    as HashRef[UpdateFindingsRefinementRequest()];

declare 'GetFindingsRefinementDeploymentRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::FindingsRefinement::GetFindingsRefinementDeploymentRequest'];

coerce 'GetFindingsRefinementDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::FindingsRefinement::GetFindingsRefinementDeploymentRequest'->new($_) };

declare 'RepeatedGetFindingsRefinementDeploymentRequest',
    as ArrayRef[GetFindingsRefinementDeploymentRequest()];

coerce 'RepeatedGetFindingsRefinementDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::FindingsRefinement::GetFindingsRefinementDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringGetFindingsRefinementDeploymentRequest',
    as HashRef[GetFindingsRefinementDeploymentRequest()];

declare 'UpdateFindingsRefinementDeploymentRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::FindingsRefinement::UpdateFindingsRefinementDeploymentRequest'];

coerce 'UpdateFindingsRefinementDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::FindingsRefinement::UpdateFindingsRefinementDeploymentRequest'->new($_) };

declare 'RepeatedUpdateFindingsRefinementDeploymentRequest',
    as ArrayRef[UpdateFindingsRefinementDeploymentRequest()];

coerce 'RepeatedUpdateFindingsRefinementDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::FindingsRefinement::UpdateFindingsRefinementDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateFindingsRefinementDeploymentRequest',
    as HashRef[UpdateFindingsRefinementDeploymentRequest()];

declare 'ListAllFindingsRefinementDeploymentsRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::FindingsRefinement::ListAllFindingsRefinementDeploymentsRequest'];

coerce 'ListAllFindingsRefinementDeploymentsRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::FindingsRefinement::ListAllFindingsRefinementDeploymentsRequest'->new($_) };

declare 'RepeatedListAllFindingsRefinementDeploymentsRequest',
    as ArrayRef[ListAllFindingsRefinementDeploymentsRequest()];

coerce 'RepeatedListAllFindingsRefinementDeploymentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::FindingsRefinement::ListAllFindingsRefinementDeploymentsRequest'->new($_) } @$_ ] };

declare 'MapStringListAllFindingsRefinementDeploymentsRequest',
    as HashRef[ListAllFindingsRefinementDeploymentsRequest()];

declare 'ListAllFindingsRefinementDeploymentsResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::FindingsRefinement::ListAllFindingsRefinementDeploymentsResponse'];

coerce 'ListAllFindingsRefinementDeploymentsResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::FindingsRefinement::ListAllFindingsRefinementDeploymentsResponse'->new($_) };

declare 'RepeatedListAllFindingsRefinementDeploymentsResponse',
    as ArrayRef[ListAllFindingsRefinementDeploymentsResponse()];

coerce 'RepeatedListAllFindingsRefinementDeploymentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::FindingsRefinement::ListAllFindingsRefinementDeploymentsResponse'->new($_) } @$_ ] };

declare 'MapStringListAllFindingsRefinementDeploymentsResponse',
    as HashRef[ListAllFindingsRefinementDeploymentsResponse()];

declare 'OutcomeFilter',
    as InstanceOf['Google::Cloud::Chronicle::V1::FindingsRefinement::OutcomeFilter'];

coerce 'OutcomeFilter',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::FindingsRefinement::OutcomeFilter'->new($_) };

declare 'RepeatedOutcomeFilter',
    as ArrayRef[OutcomeFilter()];

coerce 'RepeatedOutcomeFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::FindingsRefinement::OutcomeFilter'->new($_) } @$_ ] };

declare 'MapStringOutcomeFilter',
    as HashRef[OutcomeFilter()];

declare 'Operator',
    as (Int | Str);

declare 'ComputeFindingsRefinementActivityRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::FindingsRefinement::ComputeFindingsRefinementActivityRequest'];

coerce 'ComputeFindingsRefinementActivityRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::FindingsRefinement::ComputeFindingsRefinementActivityRequest'->new($_) };

declare 'RepeatedComputeFindingsRefinementActivityRequest',
    as ArrayRef[ComputeFindingsRefinementActivityRequest()];

coerce 'RepeatedComputeFindingsRefinementActivityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::FindingsRefinement::ComputeFindingsRefinementActivityRequest'->new($_) } @$_ ] };

declare 'MapStringComputeFindingsRefinementActivityRequest',
    as HashRef[ComputeFindingsRefinementActivityRequest()];

declare 'ComputeFindingsRefinementActivityResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::FindingsRefinement::ComputeFindingsRefinementActivityResponse'];

coerce 'ComputeFindingsRefinementActivityResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::FindingsRefinement::ComputeFindingsRefinementActivityResponse'->new($_) };

declare 'RepeatedComputeFindingsRefinementActivityResponse',
    as ArrayRef[ComputeFindingsRefinementActivityResponse()];

coerce 'RepeatedComputeFindingsRefinementActivityResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::FindingsRefinement::ComputeFindingsRefinementActivityResponse'->new($_) } @$_ ] };

declare 'MapStringComputeFindingsRefinementActivityResponse',
    as HashRef[ComputeFindingsRefinementActivityResponse()];

declare 'ComputeAllFindingsRefinementActivitiesRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::FindingsRefinement::ComputeAllFindingsRefinementActivitiesRequest'];

coerce 'ComputeAllFindingsRefinementActivitiesRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::FindingsRefinement::ComputeAllFindingsRefinementActivitiesRequest'->new($_) };

declare 'RepeatedComputeAllFindingsRefinementActivitiesRequest',
    as ArrayRef[ComputeAllFindingsRefinementActivitiesRequest()];

coerce 'RepeatedComputeAllFindingsRefinementActivitiesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::FindingsRefinement::ComputeAllFindingsRefinementActivitiesRequest'->new($_) } @$_ ] };

declare 'MapStringComputeAllFindingsRefinementActivitiesRequest',
    as HashRef[ComputeAllFindingsRefinementActivitiesRequest()];

declare 'ComputeAllFindingsRefinementActivitiesResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::FindingsRefinement::ComputeAllFindingsRefinementActivitiesResponse'];

coerce 'ComputeAllFindingsRefinementActivitiesResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::FindingsRefinement::ComputeAllFindingsRefinementActivitiesResponse'->new($_) };

declare 'RepeatedComputeAllFindingsRefinementActivitiesResponse',
    as ArrayRef[ComputeAllFindingsRefinementActivitiesResponse()];

coerce 'RepeatedComputeAllFindingsRefinementActivitiesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::FindingsRefinement::ComputeAllFindingsRefinementActivitiesResponse'->new($_) } @$_ ] };

declare 'MapStringComputeAllFindingsRefinementActivitiesResponse',
    as HashRef[ComputeAllFindingsRefinementActivitiesResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Chronicle::V1::FindingsRefinement::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
