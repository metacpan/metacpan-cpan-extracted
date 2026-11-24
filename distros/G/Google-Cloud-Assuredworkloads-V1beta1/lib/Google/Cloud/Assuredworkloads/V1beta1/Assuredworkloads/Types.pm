package Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateWorkloadRequest',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::CreateWorkloadRequest'];

coerce 'CreateWorkloadRequest',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::CreateWorkloadRequest'->new($_) };

declare 'RepeatedCreateWorkloadRequest',
    as ArrayRef[CreateWorkloadRequest()];

coerce 'RepeatedCreateWorkloadRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::CreateWorkloadRequest'->new($_) } @$_ ] };

declare 'MapStringCreateWorkloadRequest',
    as HashRef[CreateWorkloadRequest()];

declare 'UpdateWorkloadRequest',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::UpdateWorkloadRequest'];

coerce 'UpdateWorkloadRequest',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::UpdateWorkloadRequest'->new($_) };

declare 'RepeatedUpdateWorkloadRequest',
    as ArrayRef[UpdateWorkloadRequest()];

coerce 'RepeatedUpdateWorkloadRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::UpdateWorkloadRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateWorkloadRequest',
    as HashRef[UpdateWorkloadRequest()];

declare 'RestrictAllowedResourcesRequest',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::RestrictAllowedResourcesRequest'];

coerce 'RestrictAllowedResourcesRequest',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::RestrictAllowedResourcesRequest'->new($_) };

declare 'RepeatedRestrictAllowedResourcesRequest',
    as ArrayRef[RestrictAllowedResourcesRequest()];

coerce 'RepeatedRestrictAllowedResourcesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::RestrictAllowedResourcesRequest'->new($_) } @$_ ] };

declare 'MapStringRestrictAllowedResourcesRequest',
    as HashRef[RestrictAllowedResourcesRequest()];

declare 'RestrictionType',
    as (Int | Str);

declare 'RestrictAllowedResourcesResponse',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::RestrictAllowedResourcesResponse'];

coerce 'RestrictAllowedResourcesResponse',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::RestrictAllowedResourcesResponse'->new($_) };

declare 'RepeatedRestrictAllowedResourcesResponse',
    as ArrayRef[RestrictAllowedResourcesResponse()];

coerce 'RepeatedRestrictAllowedResourcesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::RestrictAllowedResourcesResponse'->new($_) } @$_ ] };

declare 'MapStringRestrictAllowedResourcesResponse',
    as HashRef[RestrictAllowedResourcesResponse()];

declare 'DeleteWorkloadRequest',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::DeleteWorkloadRequest'];

coerce 'DeleteWorkloadRequest',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::DeleteWorkloadRequest'->new($_) };

declare 'RepeatedDeleteWorkloadRequest',
    as ArrayRef[DeleteWorkloadRequest()];

coerce 'RepeatedDeleteWorkloadRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::DeleteWorkloadRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteWorkloadRequest',
    as HashRef[DeleteWorkloadRequest()];

declare 'GetWorkloadRequest',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::GetWorkloadRequest'];

coerce 'GetWorkloadRequest',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::GetWorkloadRequest'->new($_) };

declare 'RepeatedGetWorkloadRequest',
    as ArrayRef[GetWorkloadRequest()];

coerce 'RepeatedGetWorkloadRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::GetWorkloadRequest'->new($_) } @$_ ] };

declare 'MapStringGetWorkloadRequest',
    as HashRef[GetWorkloadRequest()];

declare 'AnalyzeWorkloadMoveRequest',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::AnalyzeWorkloadMoveRequest'];

coerce 'AnalyzeWorkloadMoveRequest',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::AnalyzeWorkloadMoveRequest'->new($_) };

declare 'RepeatedAnalyzeWorkloadMoveRequest',
    as ArrayRef[AnalyzeWorkloadMoveRequest()];

coerce 'RepeatedAnalyzeWorkloadMoveRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::AnalyzeWorkloadMoveRequest'->new($_) } @$_ ] };

declare 'MapStringAnalyzeWorkloadMoveRequest',
    as HashRef[AnalyzeWorkloadMoveRequest()];

declare 'AnalyzeWorkloadMoveResponse',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::AnalyzeWorkloadMoveResponse'];

coerce 'AnalyzeWorkloadMoveResponse',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::AnalyzeWorkloadMoveResponse'->new($_) };

declare 'RepeatedAnalyzeWorkloadMoveResponse',
    as ArrayRef[AnalyzeWorkloadMoveResponse()];

coerce 'RepeatedAnalyzeWorkloadMoveResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::AnalyzeWorkloadMoveResponse'->new($_) } @$_ ] };

declare 'MapStringAnalyzeWorkloadMoveResponse',
    as HashRef[AnalyzeWorkloadMoveResponse()];

declare 'ListWorkloadsRequest',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::ListWorkloadsRequest'];

coerce 'ListWorkloadsRequest',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::ListWorkloadsRequest'->new($_) };

declare 'RepeatedListWorkloadsRequest',
    as ArrayRef[ListWorkloadsRequest()];

coerce 'RepeatedListWorkloadsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::ListWorkloadsRequest'->new($_) } @$_ ] };

declare 'MapStringListWorkloadsRequest',
    as HashRef[ListWorkloadsRequest()];

declare 'ListWorkloadsResponse',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::ListWorkloadsResponse'];

coerce 'ListWorkloadsResponse',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::ListWorkloadsResponse'->new($_) };

declare 'RepeatedListWorkloadsResponse',
    as ArrayRef[ListWorkloadsResponse()];

coerce 'RepeatedListWorkloadsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::ListWorkloadsResponse'->new($_) } @$_ ] };

declare 'MapStringListWorkloadsResponse',
    as HashRef[ListWorkloadsResponse()];

declare 'Workload',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload'];

coerce 'Workload',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload'->new($_) };

declare 'RepeatedWorkload',
    as ArrayRef[Workload()];

coerce 'RepeatedWorkload',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload'->new($_) } @$_ ] };

declare 'MapStringWorkload',
    as HashRef[Workload()];

declare 'ComplianceRegime',
    as (Int | Str);

declare 'KajEnrollmentState',
    as (Int | Str);

declare 'ResourceInfo',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload::ResourceInfo'];

coerce 'ResourceInfo',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload::ResourceInfo'->new($_) };

declare 'RepeatedResourceInfo',
    as ArrayRef[ResourceInfo()];

coerce 'RepeatedResourceInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload::ResourceInfo'->new($_) } @$_ ] };

declare 'MapStringResourceInfo',
    as HashRef[ResourceInfo()];

declare 'ResourceType',
    as (Int | Str);

declare 'KMSSettings',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload::KMSSettings'];

coerce 'KMSSettings',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload::KMSSettings'->new($_) };

declare 'RepeatedKMSSettings',
    as ArrayRef[KMSSettings()];

coerce 'RepeatedKMSSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload::KMSSettings'->new($_) } @$_ ] };

declare 'MapStringKMSSettings',
    as HashRef[KMSSettings()];

declare 'IL4Settings',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload::IL4Settings'];

coerce 'IL4Settings',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload::IL4Settings'->new($_) };

declare 'RepeatedIL4Settings',
    as ArrayRef[IL4Settings()];

coerce 'RepeatedIL4Settings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload::IL4Settings'->new($_) } @$_ ] };

declare 'MapStringIL4Settings',
    as HashRef[IL4Settings()];

declare 'CJISSettings',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload::CJISSettings'];

coerce 'CJISSettings',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload::CJISSettings'->new($_) };

declare 'RepeatedCJISSettings',
    as ArrayRef[CJISSettings()];

coerce 'RepeatedCJISSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload::CJISSettings'->new($_) } @$_ ] };

declare 'MapStringCJISSettings',
    as HashRef[CJISSettings()];

declare 'FedrampHighSettings',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload::FedrampHighSettings'];

coerce 'FedrampHighSettings',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload::FedrampHighSettings'->new($_) };

declare 'RepeatedFedrampHighSettings',
    as ArrayRef[FedrampHighSettings()];

coerce 'RepeatedFedrampHighSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload::FedrampHighSettings'->new($_) } @$_ ] };

declare 'MapStringFedrampHighSettings',
    as HashRef[FedrampHighSettings()];

declare 'FedrampModerateSettings',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload::FedrampModerateSettings'];

coerce 'FedrampModerateSettings',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload::FedrampModerateSettings'->new($_) };

declare 'RepeatedFedrampModerateSettings',
    as ArrayRef[FedrampModerateSettings()];

coerce 'RepeatedFedrampModerateSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload::FedrampModerateSettings'->new($_) } @$_ ] };

declare 'MapStringFedrampModerateSettings',
    as HashRef[FedrampModerateSettings()];

declare 'ResourceSettings',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload::ResourceSettings'];

coerce 'ResourceSettings',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload::ResourceSettings'->new($_) };

declare 'RepeatedResourceSettings',
    as ArrayRef[ResourceSettings()];

coerce 'RepeatedResourceSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload::ResourceSettings'->new($_) } @$_ ] };

declare 'MapStringResourceSettings',
    as HashRef[ResourceSettings()];

declare 'SaaEnrollmentResponse',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload::SaaEnrollmentResponse'];

coerce 'SaaEnrollmentResponse',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload::SaaEnrollmentResponse'->new($_) };

declare 'RepeatedSaaEnrollmentResponse',
    as ArrayRef[SaaEnrollmentResponse()];

coerce 'RepeatedSaaEnrollmentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload::SaaEnrollmentResponse'->new($_) } @$_ ] };

declare 'MapStringSaaEnrollmentResponse',
    as HashRef[SaaEnrollmentResponse()];

declare 'SetupState',
    as (Int | Str);

declare 'SetupError',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'CreateWorkloadOperationMetadata',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::CreateWorkloadOperationMetadata'];

coerce 'CreateWorkloadOperationMetadata',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::CreateWorkloadOperationMetadata'->new($_) };

declare 'RepeatedCreateWorkloadOperationMetadata',
    as ArrayRef[CreateWorkloadOperationMetadata()];

coerce 'RepeatedCreateWorkloadOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::CreateWorkloadOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateWorkloadOperationMetadata',
    as HashRef[CreateWorkloadOperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
