package Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateWorkloadRequest',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1::Assuredworkloads::CreateWorkloadRequest'];

coerce 'CreateWorkloadRequest',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::CreateWorkloadRequest'->new($_) };

declare 'RepeatedCreateWorkloadRequest',
    as ArrayRef[CreateWorkloadRequest()];

coerce 'RepeatedCreateWorkloadRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::CreateWorkloadRequest'->new($_) } @$_ ] };

declare 'MapStringCreateWorkloadRequest',
    as HashRef[CreateWorkloadRequest()];

declare 'UpdateWorkloadRequest',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1::Assuredworkloads::UpdateWorkloadRequest'];

coerce 'UpdateWorkloadRequest',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::UpdateWorkloadRequest'->new($_) };

declare 'RepeatedUpdateWorkloadRequest',
    as ArrayRef[UpdateWorkloadRequest()];

coerce 'RepeatedUpdateWorkloadRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::UpdateWorkloadRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateWorkloadRequest',
    as HashRef[UpdateWorkloadRequest()];

declare 'DeleteWorkloadRequest',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1::Assuredworkloads::DeleteWorkloadRequest'];

coerce 'DeleteWorkloadRequest',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::DeleteWorkloadRequest'->new($_) };

declare 'RepeatedDeleteWorkloadRequest',
    as ArrayRef[DeleteWorkloadRequest()];

coerce 'RepeatedDeleteWorkloadRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::DeleteWorkloadRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteWorkloadRequest',
    as HashRef[DeleteWorkloadRequest()];

declare 'GetWorkloadRequest',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1::Assuredworkloads::GetWorkloadRequest'];

coerce 'GetWorkloadRequest',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::GetWorkloadRequest'->new($_) };

declare 'RepeatedGetWorkloadRequest',
    as ArrayRef[GetWorkloadRequest()];

coerce 'RepeatedGetWorkloadRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::GetWorkloadRequest'->new($_) } @$_ ] };

declare 'MapStringGetWorkloadRequest',
    as HashRef[GetWorkloadRequest()];

declare 'ListWorkloadsRequest',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1::Assuredworkloads::ListWorkloadsRequest'];

coerce 'ListWorkloadsRequest',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::ListWorkloadsRequest'->new($_) };

declare 'RepeatedListWorkloadsRequest',
    as ArrayRef[ListWorkloadsRequest()];

coerce 'RepeatedListWorkloadsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::ListWorkloadsRequest'->new($_) } @$_ ] };

declare 'MapStringListWorkloadsRequest',
    as HashRef[ListWorkloadsRequest()];

declare 'ListWorkloadsResponse',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1::Assuredworkloads::ListWorkloadsResponse'];

coerce 'ListWorkloadsResponse',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::ListWorkloadsResponse'->new($_) };

declare 'RepeatedListWorkloadsResponse',
    as ArrayRef[ListWorkloadsResponse()];

coerce 'RepeatedListWorkloadsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::ListWorkloadsResponse'->new($_) } @$_ ] };

declare 'MapStringListWorkloadsResponse',
    as HashRef[ListWorkloadsResponse()];

declare 'Workload',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Workload'];

coerce 'Workload',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Workload'->new($_) };

declare 'RepeatedWorkload',
    as ArrayRef[Workload()];

coerce 'RepeatedWorkload',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Workload'->new($_) } @$_ ] };

declare 'MapStringWorkload',
    as HashRef[Workload()];

declare 'ComplianceRegime',
    as (Int | Str);

declare 'KajEnrollmentState',
    as (Int | Str);

declare 'Partner',
    as (Int | Str);

declare 'ResourceInfo',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Workload::ResourceInfo'];

coerce 'ResourceInfo',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Workload::ResourceInfo'->new($_) };

declare 'RepeatedResourceInfo',
    as ArrayRef[ResourceInfo()];

coerce 'RepeatedResourceInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Workload::ResourceInfo'->new($_) } @$_ ] };

declare 'MapStringResourceInfo',
    as HashRef[ResourceInfo()];

declare 'ResourceType',
    as (Int | Str);

declare 'KMSSettings',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Workload::KMSSettings'];

coerce 'KMSSettings',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Workload::KMSSettings'->new($_) };

declare 'RepeatedKMSSettings',
    as ArrayRef[KMSSettings()];

coerce 'RepeatedKMSSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Workload::KMSSettings'->new($_) } @$_ ] };

declare 'MapStringKMSSettings',
    as HashRef[KMSSettings()];

declare 'ResourceSettings',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Workload::ResourceSettings'];

coerce 'ResourceSettings',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Workload::ResourceSettings'->new($_) };

declare 'RepeatedResourceSettings',
    as ArrayRef[ResourceSettings()];

coerce 'RepeatedResourceSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Workload::ResourceSettings'->new($_) } @$_ ] };

declare 'MapStringResourceSettings',
    as HashRef[ResourceSettings()];

declare 'SaaEnrollmentResponse',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Workload::SaaEnrollmentResponse'];

coerce 'SaaEnrollmentResponse',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Workload::SaaEnrollmentResponse'->new($_) };

declare 'RepeatedSaaEnrollmentResponse',
    as ArrayRef[SaaEnrollmentResponse()];

coerce 'RepeatedSaaEnrollmentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Workload::SaaEnrollmentResponse'->new($_) } @$_ ] };

declare 'MapStringSaaEnrollmentResponse',
    as HashRef[SaaEnrollmentResponse()];

declare 'SetupState',
    as (Int | Str);

declare 'SetupError',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Workload::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Workload::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Workload::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'CreateWorkloadOperationMetadata',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1::Assuredworkloads::CreateWorkloadOperationMetadata'];

coerce 'CreateWorkloadOperationMetadata',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::CreateWorkloadOperationMetadata'->new($_) };

declare 'RepeatedCreateWorkloadOperationMetadata',
    as ArrayRef[CreateWorkloadOperationMetadata()];

coerce 'RepeatedCreateWorkloadOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::CreateWorkloadOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateWorkloadOperationMetadata',
    as HashRef[CreateWorkloadOperationMetadata()];

declare 'RestrictAllowedResourcesRequest',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1::Assuredworkloads::RestrictAllowedResourcesRequest'];

coerce 'RestrictAllowedResourcesRequest',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::RestrictAllowedResourcesRequest'->new($_) };

declare 'RepeatedRestrictAllowedResourcesRequest',
    as ArrayRef[RestrictAllowedResourcesRequest()];

coerce 'RepeatedRestrictAllowedResourcesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::RestrictAllowedResourcesRequest'->new($_) } @$_ ] };

declare 'MapStringRestrictAllowedResourcesRequest',
    as HashRef[RestrictAllowedResourcesRequest()];

declare 'RestrictionType',
    as (Int | Str);

declare 'RestrictAllowedResourcesResponse',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1::Assuredworkloads::RestrictAllowedResourcesResponse'];

coerce 'RestrictAllowedResourcesResponse',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::RestrictAllowedResourcesResponse'->new($_) };

declare 'RepeatedRestrictAllowedResourcesResponse',
    as ArrayRef[RestrictAllowedResourcesResponse()];

coerce 'RepeatedRestrictAllowedResourcesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::RestrictAllowedResourcesResponse'->new($_) } @$_ ] };

declare 'MapStringRestrictAllowedResourcesResponse',
    as HashRef[RestrictAllowedResourcesResponse()];

declare 'AcknowledgeViolationRequest',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1::Assuredworkloads::AcknowledgeViolationRequest'];

coerce 'AcknowledgeViolationRequest',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::AcknowledgeViolationRequest'->new($_) };

declare 'RepeatedAcknowledgeViolationRequest',
    as ArrayRef[AcknowledgeViolationRequest()];

coerce 'RepeatedAcknowledgeViolationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::AcknowledgeViolationRequest'->new($_) } @$_ ] };

declare 'MapStringAcknowledgeViolationRequest',
    as HashRef[AcknowledgeViolationRequest()];

declare 'AcknowledgeViolationResponse',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1::Assuredworkloads::AcknowledgeViolationResponse'];

coerce 'AcknowledgeViolationResponse',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::AcknowledgeViolationResponse'->new($_) };

declare 'RepeatedAcknowledgeViolationResponse',
    as ArrayRef[AcknowledgeViolationResponse()];

coerce 'RepeatedAcknowledgeViolationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::AcknowledgeViolationResponse'->new($_) } @$_ ] };

declare 'MapStringAcknowledgeViolationResponse',
    as HashRef[AcknowledgeViolationResponse()];

declare 'TimeWindow',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1::Assuredworkloads::TimeWindow'];

coerce 'TimeWindow',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::TimeWindow'->new($_) };

declare 'RepeatedTimeWindow',
    as ArrayRef[TimeWindow()];

coerce 'RepeatedTimeWindow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::TimeWindow'->new($_) } @$_ ] };

declare 'MapStringTimeWindow',
    as HashRef[TimeWindow()];

declare 'ListViolationsRequest',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1::Assuredworkloads::ListViolationsRequest'];

coerce 'ListViolationsRequest',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::ListViolationsRequest'->new($_) };

declare 'RepeatedListViolationsRequest',
    as ArrayRef[ListViolationsRequest()];

coerce 'RepeatedListViolationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::ListViolationsRequest'->new($_) } @$_ ] };

declare 'MapStringListViolationsRequest',
    as HashRef[ListViolationsRequest()];

declare 'ListViolationsResponse',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1::Assuredworkloads::ListViolationsResponse'];

coerce 'ListViolationsResponse',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::ListViolationsResponse'->new($_) };

declare 'RepeatedListViolationsResponse',
    as ArrayRef[ListViolationsResponse()];

coerce 'RepeatedListViolationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::ListViolationsResponse'->new($_) } @$_ ] };

declare 'MapStringListViolationsResponse',
    as HashRef[ListViolationsResponse()];

declare 'GetViolationRequest',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1::Assuredworkloads::GetViolationRequest'];

coerce 'GetViolationRequest',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::GetViolationRequest'->new($_) };

declare 'RepeatedGetViolationRequest',
    as ArrayRef[GetViolationRequest()];

coerce 'RepeatedGetViolationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::GetViolationRequest'->new($_) } @$_ ] };

declare 'MapStringGetViolationRequest',
    as HashRef[GetViolationRequest()];

declare 'Violation',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Violation'];

coerce 'Violation',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Violation'->new($_) };

declare 'RepeatedViolation',
    as ArrayRef[Violation()];

coerce 'RepeatedViolation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Violation'->new($_) } @$_ ] };

declare 'MapStringViolation',
    as HashRef[Violation()];

declare 'State',
    as (Int | Str);

declare 'Remediation',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Violation::Remediation'];

coerce 'Remediation',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Violation::Remediation'->new($_) };

declare 'RepeatedRemediation',
    as ArrayRef[Remediation()];

coerce 'RepeatedRemediation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Violation::Remediation'->new($_) } @$_ ] };

declare 'MapStringRemediation',
    as HashRef[Remediation()];

declare 'RemediationType',
    as (Int | Str);

declare 'Instructions',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Violation::Remediation::Instructions'];

coerce 'Instructions',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Violation::Remediation::Instructions'->new($_) };

declare 'RepeatedInstructions',
    as ArrayRef[Instructions()];

coerce 'RepeatedInstructions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Violation::Remediation::Instructions'->new($_) } @$_ ] };

declare 'MapStringInstructions',
    as HashRef[Instructions()];

declare 'Gcloud',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Violation::Remediation::Instructions::Gcloud'];

coerce 'Gcloud',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Violation::Remediation::Instructions::Gcloud'->new($_) };

declare 'RepeatedGcloud',
    as ArrayRef[Gcloud()];

coerce 'RepeatedGcloud',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Violation::Remediation::Instructions::Gcloud'->new($_) } @$_ ] };

declare 'MapStringGcloud',
    as HashRef[Gcloud()];

declare 'Console',
    as InstanceOf['Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Violation::Remediation::Instructions::Console'];

coerce 'Console',
    from HashRef, via { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Violation::Remediation::Instructions::Console'->new($_) };

declare 'RepeatedConsole',
    as ArrayRef[Console()];

coerce 'RepeatedConsole',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Violation::Remediation::Instructions::Console'->new($_) } @$_ ] };

declare 'MapStringConsole',
    as HashRef[Console()];

1;

__END__

=head1 NAME

Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
