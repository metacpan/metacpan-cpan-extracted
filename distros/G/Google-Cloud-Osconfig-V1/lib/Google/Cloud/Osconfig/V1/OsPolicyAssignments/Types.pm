package Google::Cloud::Osconfig::V1::OsPolicyAssignments::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OSPolicyAssignment',
    as InstanceOf['Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignment'];

coerce 'OSPolicyAssignment',
    from HashRef, via { 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignment'->new($_) };

declare 'RepeatedOSPolicyAssignment',
    as ArrayRef[OSPolicyAssignment()];

coerce 'RepeatedOSPolicyAssignment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignment'->new($_) } @$_ ] };

declare 'MapStringOSPolicyAssignment',
    as HashRef[OSPolicyAssignment()];

declare 'RolloutState',
    as (Int | Str);

declare 'LabelSet',
    as InstanceOf['Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignment::LabelSet'];

coerce 'LabelSet',
    from HashRef, via { 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignment::LabelSet'->new($_) };

declare 'RepeatedLabelSet',
    as ArrayRef[LabelSet()];

coerce 'RepeatedLabelSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignment::LabelSet'->new($_) } @$_ ] };

declare 'MapStringLabelSet',
    as HashRef[LabelSet()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignment::LabelSet::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignment::LabelSet::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignment::LabelSet::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'InstanceFilter',
    as InstanceOf['Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignment::InstanceFilter'];

coerce 'InstanceFilter',
    from HashRef, via { 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignment::InstanceFilter'->new($_) };

declare 'RepeatedInstanceFilter',
    as ArrayRef[InstanceFilter()];

coerce 'RepeatedInstanceFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignment::InstanceFilter'->new($_) } @$_ ] };

declare 'MapStringInstanceFilter',
    as HashRef[InstanceFilter()];

declare 'Inventory',
    as InstanceOf['Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignment::InstanceFilter::Inventory'];

coerce 'Inventory',
    from HashRef, via { 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignment::InstanceFilter::Inventory'->new($_) };

declare 'RepeatedInventory',
    as ArrayRef[Inventory()];

coerce 'RepeatedInventory',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignment::InstanceFilter::Inventory'->new($_) } @$_ ] };

declare 'MapStringInventory',
    as HashRef[Inventory()];

declare 'Rollout',
    as InstanceOf['Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignment::Rollout'];

coerce 'Rollout',
    from HashRef, via { 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignment::Rollout'->new($_) };

declare 'RepeatedRollout',
    as ArrayRef[Rollout()];

coerce 'RepeatedRollout',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignment::Rollout'->new($_) } @$_ ] };

declare 'MapStringRollout',
    as HashRef[Rollout()];

declare 'OSPolicyAssignmentOperationMetadata',
    as InstanceOf['Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignmentOperationMetadata'];

coerce 'OSPolicyAssignmentOperationMetadata',
    from HashRef, via { 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignmentOperationMetadata'->new($_) };

declare 'RepeatedOSPolicyAssignmentOperationMetadata',
    as ArrayRef[OSPolicyAssignmentOperationMetadata()];

coerce 'RepeatedOSPolicyAssignmentOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignmentOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOSPolicyAssignmentOperationMetadata',
    as HashRef[OSPolicyAssignmentOperationMetadata()];

declare 'APIMethod',
    as (Int | Str);

declare 'RolloutState',
    as (Int | Str);

declare 'CreateOSPolicyAssignmentRequest',
    as InstanceOf['Google::Cloud::Osconfig::V1::OsPolicyAssignments::CreateOSPolicyAssignmentRequest'];

coerce 'CreateOSPolicyAssignmentRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::CreateOSPolicyAssignmentRequest'->new($_) };

declare 'RepeatedCreateOSPolicyAssignmentRequest',
    as ArrayRef[CreateOSPolicyAssignmentRequest()];

coerce 'RepeatedCreateOSPolicyAssignmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::CreateOSPolicyAssignmentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateOSPolicyAssignmentRequest',
    as HashRef[CreateOSPolicyAssignmentRequest()];

declare 'UpdateOSPolicyAssignmentRequest',
    as InstanceOf['Google::Cloud::Osconfig::V1::OsPolicyAssignments::UpdateOSPolicyAssignmentRequest'];

coerce 'UpdateOSPolicyAssignmentRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::UpdateOSPolicyAssignmentRequest'->new($_) };

declare 'RepeatedUpdateOSPolicyAssignmentRequest',
    as ArrayRef[UpdateOSPolicyAssignmentRequest()];

coerce 'RepeatedUpdateOSPolicyAssignmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::UpdateOSPolicyAssignmentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateOSPolicyAssignmentRequest',
    as HashRef[UpdateOSPolicyAssignmentRequest()];

declare 'GetOSPolicyAssignmentRequest',
    as InstanceOf['Google::Cloud::Osconfig::V1::OsPolicyAssignments::GetOSPolicyAssignmentRequest'];

coerce 'GetOSPolicyAssignmentRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::GetOSPolicyAssignmentRequest'->new($_) };

declare 'RepeatedGetOSPolicyAssignmentRequest',
    as ArrayRef[GetOSPolicyAssignmentRequest()];

coerce 'RepeatedGetOSPolicyAssignmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::GetOSPolicyAssignmentRequest'->new($_) } @$_ ] };

declare 'MapStringGetOSPolicyAssignmentRequest',
    as HashRef[GetOSPolicyAssignmentRequest()];

declare 'ListOSPolicyAssignmentsRequest',
    as InstanceOf['Google::Cloud::Osconfig::V1::OsPolicyAssignments::ListOSPolicyAssignmentsRequest'];

coerce 'ListOSPolicyAssignmentsRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::ListOSPolicyAssignmentsRequest'->new($_) };

declare 'RepeatedListOSPolicyAssignmentsRequest',
    as ArrayRef[ListOSPolicyAssignmentsRequest()];

coerce 'RepeatedListOSPolicyAssignmentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::ListOSPolicyAssignmentsRequest'->new($_) } @$_ ] };

declare 'MapStringListOSPolicyAssignmentsRequest',
    as HashRef[ListOSPolicyAssignmentsRequest()];

declare 'ListOSPolicyAssignmentsResponse',
    as InstanceOf['Google::Cloud::Osconfig::V1::OsPolicyAssignments::ListOSPolicyAssignmentsResponse'];

coerce 'ListOSPolicyAssignmentsResponse',
    from HashRef, via { 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::ListOSPolicyAssignmentsResponse'->new($_) };

declare 'RepeatedListOSPolicyAssignmentsResponse',
    as ArrayRef[ListOSPolicyAssignmentsResponse()];

coerce 'RepeatedListOSPolicyAssignmentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::ListOSPolicyAssignmentsResponse'->new($_) } @$_ ] };

declare 'MapStringListOSPolicyAssignmentsResponse',
    as HashRef[ListOSPolicyAssignmentsResponse()];

declare 'ListOSPolicyAssignmentRevisionsRequest',
    as InstanceOf['Google::Cloud::Osconfig::V1::OsPolicyAssignments::ListOSPolicyAssignmentRevisionsRequest'];

coerce 'ListOSPolicyAssignmentRevisionsRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::ListOSPolicyAssignmentRevisionsRequest'->new($_) };

declare 'RepeatedListOSPolicyAssignmentRevisionsRequest',
    as ArrayRef[ListOSPolicyAssignmentRevisionsRequest()];

coerce 'RepeatedListOSPolicyAssignmentRevisionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::ListOSPolicyAssignmentRevisionsRequest'->new($_) } @$_ ] };

declare 'MapStringListOSPolicyAssignmentRevisionsRequest',
    as HashRef[ListOSPolicyAssignmentRevisionsRequest()];

declare 'ListOSPolicyAssignmentRevisionsResponse',
    as InstanceOf['Google::Cloud::Osconfig::V1::OsPolicyAssignments::ListOSPolicyAssignmentRevisionsResponse'];

coerce 'ListOSPolicyAssignmentRevisionsResponse',
    from HashRef, via { 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::ListOSPolicyAssignmentRevisionsResponse'->new($_) };

declare 'RepeatedListOSPolicyAssignmentRevisionsResponse',
    as ArrayRef[ListOSPolicyAssignmentRevisionsResponse()];

coerce 'RepeatedListOSPolicyAssignmentRevisionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::ListOSPolicyAssignmentRevisionsResponse'->new($_) } @$_ ] };

declare 'MapStringListOSPolicyAssignmentRevisionsResponse',
    as HashRef[ListOSPolicyAssignmentRevisionsResponse()];

declare 'DeleteOSPolicyAssignmentRequest',
    as InstanceOf['Google::Cloud::Osconfig::V1::OsPolicyAssignments::DeleteOSPolicyAssignmentRequest'];

coerce 'DeleteOSPolicyAssignmentRequest',
    from HashRef, via { 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::DeleteOSPolicyAssignmentRequest'->new($_) };

declare 'RepeatedDeleteOSPolicyAssignmentRequest',
    as ArrayRef[DeleteOSPolicyAssignmentRequest()];

coerce 'RepeatedDeleteOSPolicyAssignmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::DeleteOSPolicyAssignmentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteOSPolicyAssignmentRequest',
    as HashRef[DeleteOSPolicyAssignmentRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Osconfig::V1::OsPolicyAssignments::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
