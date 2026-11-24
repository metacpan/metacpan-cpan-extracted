package Google::Cloud::Policysimulator::V1::Orgpolicy::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PreviewState',
    as (Int | Str);

declare 'OrgPolicyViolationsPreview',
    as InstanceOf['Google::Cloud::Policysimulator::V1::Orgpolicy::OrgPolicyViolationsPreview'];

coerce 'OrgPolicyViolationsPreview',
    from HashRef, via { 'Google::Cloud::Policysimulator::V1::Orgpolicy::OrgPolicyViolationsPreview'->new($_) };

declare 'RepeatedOrgPolicyViolationsPreview',
    as ArrayRef[OrgPolicyViolationsPreview()];

coerce 'RepeatedOrgPolicyViolationsPreview',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policysimulator::V1::Orgpolicy::OrgPolicyViolationsPreview'->new($_) } @$_ ] };

declare 'MapStringOrgPolicyViolationsPreview',
    as HashRef[OrgPolicyViolationsPreview()];

declare 'ResourceCounts',
    as InstanceOf['Google::Cloud::Policysimulator::V1::Orgpolicy::OrgPolicyViolationsPreview::ResourceCounts'];

coerce 'ResourceCounts',
    from HashRef, via { 'Google::Cloud::Policysimulator::V1::Orgpolicy::OrgPolicyViolationsPreview::ResourceCounts'->new($_) };

declare 'RepeatedResourceCounts',
    as ArrayRef[ResourceCounts()];

coerce 'RepeatedResourceCounts',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policysimulator::V1::Orgpolicy::OrgPolicyViolationsPreview::ResourceCounts'->new($_) } @$_ ] };

declare 'MapStringResourceCounts',
    as HashRef[ResourceCounts()];

declare 'OrgPolicyViolation',
    as InstanceOf['Google::Cloud::Policysimulator::V1::Orgpolicy::OrgPolicyViolation'];

coerce 'OrgPolicyViolation',
    from HashRef, via { 'Google::Cloud::Policysimulator::V1::Orgpolicy::OrgPolicyViolation'->new($_) };

declare 'RepeatedOrgPolicyViolation',
    as ArrayRef[OrgPolicyViolation()];

coerce 'RepeatedOrgPolicyViolation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policysimulator::V1::Orgpolicy::OrgPolicyViolation'->new($_) } @$_ ] };

declare 'MapStringOrgPolicyViolation',
    as HashRef[OrgPolicyViolation()];

declare 'ResourceContext',
    as InstanceOf['Google::Cloud::Policysimulator::V1::Orgpolicy::ResourceContext'];

coerce 'ResourceContext',
    from HashRef, via { 'Google::Cloud::Policysimulator::V1::Orgpolicy::ResourceContext'->new($_) };

declare 'RepeatedResourceContext',
    as ArrayRef[ResourceContext()];

coerce 'RepeatedResourceContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policysimulator::V1::Orgpolicy::ResourceContext'->new($_) } @$_ ] };

declare 'MapStringResourceContext',
    as HashRef[ResourceContext()];

declare 'OrgPolicyOverlay',
    as InstanceOf['Google::Cloud::Policysimulator::V1::Orgpolicy::OrgPolicyOverlay'];

coerce 'OrgPolicyOverlay',
    from HashRef, via { 'Google::Cloud::Policysimulator::V1::Orgpolicy::OrgPolicyOverlay'->new($_) };

declare 'RepeatedOrgPolicyOverlay',
    as ArrayRef[OrgPolicyOverlay()];

coerce 'RepeatedOrgPolicyOverlay',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policysimulator::V1::Orgpolicy::OrgPolicyOverlay'->new($_) } @$_ ] };

declare 'MapStringOrgPolicyOverlay',
    as HashRef[OrgPolicyOverlay()];

declare 'PolicyOverlay',
    as InstanceOf['Google::Cloud::Policysimulator::V1::Orgpolicy::OrgPolicyOverlay::PolicyOverlay'];

coerce 'PolicyOverlay',
    from HashRef, via { 'Google::Cloud::Policysimulator::V1::Orgpolicy::OrgPolicyOverlay::PolicyOverlay'->new($_) };

declare 'RepeatedPolicyOverlay',
    as ArrayRef[PolicyOverlay()];

coerce 'RepeatedPolicyOverlay',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policysimulator::V1::Orgpolicy::OrgPolicyOverlay::PolicyOverlay'->new($_) } @$_ ] };

declare 'MapStringPolicyOverlay',
    as HashRef[PolicyOverlay()];

declare 'CustomConstraintOverlay',
    as InstanceOf['Google::Cloud::Policysimulator::V1::Orgpolicy::OrgPolicyOverlay::CustomConstraintOverlay'];

coerce 'CustomConstraintOverlay',
    from HashRef, via { 'Google::Cloud::Policysimulator::V1::Orgpolicy::OrgPolicyOverlay::CustomConstraintOverlay'->new($_) };

declare 'RepeatedCustomConstraintOverlay',
    as ArrayRef[CustomConstraintOverlay()];

coerce 'RepeatedCustomConstraintOverlay',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policysimulator::V1::Orgpolicy::OrgPolicyOverlay::CustomConstraintOverlay'->new($_) } @$_ ] };

declare 'MapStringCustomConstraintOverlay',
    as HashRef[CustomConstraintOverlay()];

declare 'CreateOrgPolicyViolationsPreviewOperationMetadata',
    as InstanceOf['Google::Cloud::Policysimulator::V1::Orgpolicy::CreateOrgPolicyViolationsPreviewOperationMetadata'];

coerce 'CreateOrgPolicyViolationsPreviewOperationMetadata',
    from HashRef, via { 'Google::Cloud::Policysimulator::V1::Orgpolicy::CreateOrgPolicyViolationsPreviewOperationMetadata'->new($_) };

declare 'RepeatedCreateOrgPolicyViolationsPreviewOperationMetadata',
    as ArrayRef[CreateOrgPolicyViolationsPreviewOperationMetadata()];

coerce 'RepeatedCreateOrgPolicyViolationsPreviewOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policysimulator::V1::Orgpolicy::CreateOrgPolicyViolationsPreviewOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateOrgPolicyViolationsPreviewOperationMetadata',
    as HashRef[CreateOrgPolicyViolationsPreviewOperationMetadata()];

declare 'ListOrgPolicyViolationsPreviewsRequest',
    as InstanceOf['Google::Cloud::Policysimulator::V1::Orgpolicy::ListOrgPolicyViolationsPreviewsRequest'];

coerce 'ListOrgPolicyViolationsPreviewsRequest',
    from HashRef, via { 'Google::Cloud::Policysimulator::V1::Orgpolicy::ListOrgPolicyViolationsPreviewsRequest'->new($_) };

declare 'RepeatedListOrgPolicyViolationsPreviewsRequest',
    as ArrayRef[ListOrgPolicyViolationsPreviewsRequest()];

coerce 'RepeatedListOrgPolicyViolationsPreviewsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policysimulator::V1::Orgpolicy::ListOrgPolicyViolationsPreviewsRequest'->new($_) } @$_ ] };

declare 'MapStringListOrgPolicyViolationsPreviewsRequest',
    as HashRef[ListOrgPolicyViolationsPreviewsRequest()];

declare 'ListOrgPolicyViolationsPreviewsResponse',
    as InstanceOf['Google::Cloud::Policysimulator::V1::Orgpolicy::ListOrgPolicyViolationsPreviewsResponse'];

coerce 'ListOrgPolicyViolationsPreviewsResponse',
    from HashRef, via { 'Google::Cloud::Policysimulator::V1::Orgpolicy::ListOrgPolicyViolationsPreviewsResponse'->new($_) };

declare 'RepeatedListOrgPolicyViolationsPreviewsResponse',
    as ArrayRef[ListOrgPolicyViolationsPreviewsResponse()];

coerce 'RepeatedListOrgPolicyViolationsPreviewsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policysimulator::V1::Orgpolicy::ListOrgPolicyViolationsPreviewsResponse'->new($_) } @$_ ] };

declare 'MapStringListOrgPolicyViolationsPreviewsResponse',
    as HashRef[ListOrgPolicyViolationsPreviewsResponse()];

declare 'GetOrgPolicyViolationsPreviewRequest',
    as InstanceOf['Google::Cloud::Policysimulator::V1::Orgpolicy::GetOrgPolicyViolationsPreviewRequest'];

coerce 'GetOrgPolicyViolationsPreviewRequest',
    from HashRef, via { 'Google::Cloud::Policysimulator::V1::Orgpolicy::GetOrgPolicyViolationsPreviewRequest'->new($_) };

declare 'RepeatedGetOrgPolicyViolationsPreviewRequest',
    as ArrayRef[GetOrgPolicyViolationsPreviewRequest()];

coerce 'RepeatedGetOrgPolicyViolationsPreviewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policysimulator::V1::Orgpolicy::GetOrgPolicyViolationsPreviewRequest'->new($_) } @$_ ] };

declare 'MapStringGetOrgPolicyViolationsPreviewRequest',
    as HashRef[GetOrgPolicyViolationsPreviewRequest()];

declare 'CreateOrgPolicyViolationsPreviewRequest',
    as InstanceOf['Google::Cloud::Policysimulator::V1::Orgpolicy::CreateOrgPolicyViolationsPreviewRequest'];

coerce 'CreateOrgPolicyViolationsPreviewRequest',
    from HashRef, via { 'Google::Cloud::Policysimulator::V1::Orgpolicy::CreateOrgPolicyViolationsPreviewRequest'->new($_) };

declare 'RepeatedCreateOrgPolicyViolationsPreviewRequest',
    as ArrayRef[CreateOrgPolicyViolationsPreviewRequest()];

coerce 'RepeatedCreateOrgPolicyViolationsPreviewRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policysimulator::V1::Orgpolicy::CreateOrgPolicyViolationsPreviewRequest'->new($_) } @$_ ] };

declare 'MapStringCreateOrgPolicyViolationsPreviewRequest',
    as HashRef[CreateOrgPolicyViolationsPreviewRequest()];

declare 'ListOrgPolicyViolationsRequest',
    as InstanceOf['Google::Cloud::Policysimulator::V1::Orgpolicy::ListOrgPolicyViolationsRequest'];

coerce 'ListOrgPolicyViolationsRequest',
    from HashRef, via { 'Google::Cloud::Policysimulator::V1::Orgpolicy::ListOrgPolicyViolationsRequest'->new($_) };

declare 'RepeatedListOrgPolicyViolationsRequest',
    as ArrayRef[ListOrgPolicyViolationsRequest()];

coerce 'RepeatedListOrgPolicyViolationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policysimulator::V1::Orgpolicy::ListOrgPolicyViolationsRequest'->new($_) } @$_ ] };

declare 'MapStringListOrgPolicyViolationsRequest',
    as HashRef[ListOrgPolicyViolationsRequest()];

declare 'ListOrgPolicyViolationsResponse',
    as InstanceOf['Google::Cloud::Policysimulator::V1::Orgpolicy::ListOrgPolicyViolationsResponse'];

coerce 'ListOrgPolicyViolationsResponse',
    from HashRef, via { 'Google::Cloud::Policysimulator::V1::Orgpolicy::ListOrgPolicyViolationsResponse'->new($_) };

declare 'RepeatedListOrgPolicyViolationsResponse',
    as ArrayRef[ListOrgPolicyViolationsResponse()];

coerce 'RepeatedListOrgPolicyViolationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Policysimulator::V1::Orgpolicy::ListOrgPolicyViolationsResponse'->new($_) } @$_ ] };

declare 'MapStringListOrgPolicyViolationsResponse',
    as HashRef[ListOrgPolicyViolationsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Policysimulator::V1::Orgpolicy::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
