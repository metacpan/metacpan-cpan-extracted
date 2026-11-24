package Google::Cloud::Auditmanager::V1::Auditmanager::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OperationState',
    as (Int | Str);

declare 'ComplianceState',
    as (Int | Str);

declare 'ScheduleState',
    as (Int | Str);

declare 'EnrollResourceRequest',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::EnrollResourceRequest'];

coerce 'EnrollResourceRequest',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::EnrollResourceRequest'->new($_) };

declare 'RepeatedEnrollResourceRequest',
    as ArrayRef[EnrollResourceRequest()];

coerce 'RepeatedEnrollResourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::EnrollResourceRequest'->new($_) } @$_ ] };

declare 'MapStringEnrollResourceRequest',
    as HashRef[EnrollResourceRequest()];

declare 'EligibleDestination',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::EnrollResourceRequest::EligibleDestination'];

coerce 'EligibleDestination',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::EnrollResourceRequest::EligibleDestination'->new($_) };

declare 'RepeatedEligibleDestination',
    as ArrayRef[EligibleDestination()];

coerce 'RepeatedEligibleDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::EnrollResourceRequest::EligibleDestination'->new($_) } @$_ ] };

declare 'MapStringEligibleDestination',
    as HashRef[EligibleDestination()];

declare 'GenerateAuditScopeReportRequest',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::GenerateAuditScopeReportRequest'];

coerce 'GenerateAuditScopeReportRequest',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::GenerateAuditScopeReportRequest'->new($_) };

declare 'RepeatedGenerateAuditScopeReportRequest',
    as ArrayRef[GenerateAuditScopeReportRequest()];

coerce 'RepeatedGenerateAuditScopeReportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::GenerateAuditScopeReportRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateAuditScopeReportRequest',
    as HashRef[GenerateAuditScopeReportRequest()];

declare 'AuditScopeReportFormat',
    as (Int | Str);

declare 'ParameterOverridesEntry',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::GenerateAuditScopeReportRequest::ParameterOverridesEntry'];

coerce 'ParameterOverridesEntry',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::GenerateAuditScopeReportRequest::ParameterOverridesEntry'->new($_) };

declare 'RepeatedParameterOverridesEntry',
    as ArrayRef[ParameterOverridesEntry()];

coerce 'RepeatedParameterOverridesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::GenerateAuditScopeReportRequest::ParameterOverridesEntry'->new($_) } @$_ ] };

declare 'MapStringParameterOverridesEntry',
    as HashRef[ParameterOverridesEntry()];

declare 'GenerateAuditReportRequest',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::GenerateAuditReportRequest'];

coerce 'GenerateAuditReportRequest',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::GenerateAuditReportRequest'->new($_) };

declare 'RepeatedGenerateAuditReportRequest',
    as ArrayRef[GenerateAuditReportRequest()];

coerce 'RepeatedGenerateAuditReportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::GenerateAuditReportRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateAuditReportRequest',
    as HashRef[GenerateAuditReportRequest()];

declare 'AuditReportFormat',
    as (Int | Str);

declare 'ParameterOverridesEntry',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::GenerateAuditReportRequest::ParameterOverridesEntry'];

coerce 'ParameterOverridesEntry',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::GenerateAuditReportRequest::ParameterOverridesEntry'->new($_) };

declare 'RepeatedParameterOverridesEntry',
    as ArrayRef[ParameterOverridesEntry()];

coerce 'RepeatedParameterOverridesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::GenerateAuditReportRequest::ParameterOverridesEntry'->new($_) } @$_ ] };

declare 'MapStringParameterOverridesEntry',
    as HashRef[ParameterOverridesEntry()];

declare 'GetResourceEnrollmentStatusRequest',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::GetResourceEnrollmentStatusRequest'];

coerce 'GetResourceEnrollmentStatusRequest',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::GetResourceEnrollmentStatusRequest'->new($_) };

declare 'RepeatedGetResourceEnrollmentStatusRequest',
    as ArrayRef[GetResourceEnrollmentStatusRequest()];

coerce 'RepeatedGetResourceEnrollmentStatusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::GetResourceEnrollmentStatusRequest'->new($_) } @$_ ] };

declare 'MapStringGetResourceEnrollmentStatusRequest',
    as HashRef[GetResourceEnrollmentStatusRequest()];

declare 'ListResourceEnrollmentStatusesRequest',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::ListResourceEnrollmentStatusesRequest'];

coerce 'ListResourceEnrollmentStatusesRequest',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::ListResourceEnrollmentStatusesRequest'->new($_) };

declare 'RepeatedListResourceEnrollmentStatusesRequest',
    as ArrayRef[ListResourceEnrollmentStatusesRequest()];

coerce 'RepeatedListResourceEnrollmentStatusesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::ListResourceEnrollmentStatusesRequest'->new($_) } @$_ ] };

declare 'MapStringListResourceEnrollmentStatusesRequest',
    as HashRef[ListResourceEnrollmentStatusesRequest()];

declare 'ListResourceEnrollmentStatusesResponse',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::ListResourceEnrollmentStatusesResponse'];

coerce 'ListResourceEnrollmentStatusesResponse',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::ListResourceEnrollmentStatusesResponse'->new($_) };

declare 'RepeatedListResourceEnrollmentStatusesResponse',
    as ArrayRef[ListResourceEnrollmentStatusesResponse()];

coerce 'RepeatedListResourceEnrollmentStatusesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::ListResourceEnrollmentStatusesResponse'->new($_) } @$_ ] };

declare 'MapStringListResourceEnrollmentStatusesResponse',
    as HashRef[ListResourceEnrollmentStatusesResponse()];

declare 'ListAuditReportsRequest',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::ListAuditReportsRequest'];

coerce 'ListAuditReportsRequest',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::ListAuditReportsRequest'->new($_) };

declare 'RepeatedListAuditReportsRequest',
    as ArrayRef[ListAuditReportsRequest()];

coerce 'RepeatedListAuditReportsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::ListAuditReportsRequest'->new($_) } @$_ ] };

declare 'MapStringListAuditReportsRequest',
    as HashRef[ListAuditReportsRequest()];

declare 'ListAuditReportsResponse',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::ListAuditReportsResponse'];

coerce 'ListAuditReportsResponse',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::ListAuditReportsResponse'->new($_) };

declare 'RepeatedListAuditReportsResponse',
    as ArrayRef[ListAuditReportsResponse()];

coerce 'RepeatedListAuditReportsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::ListAuditReportsResponse'->new($_) } @$_ ] };

declare 'MapStringListAuditReportsResponse',
    as HashRef[ListAuditReportsResponse()];

declare 'GetAuditReportRequest',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::GetAuditReportRequest'];

coerce 'GetAuditReportRequest',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::GetAuditReportRequest'->new($_) };

declare 'RepeatedGetAuditReportRequest',
    as ArrayRef[GetAuditReportRequest()];

coerce 'RepeatedGetAuditReportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::GetAuditReportRequest'->new($_) } @$_ ] };

declare 'MapStringGetAuditReportRequest',
    as HashRef[GetAuditReportRequest()];

declare 'ListControlsRequest',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::ListControlsRequest'];

coerce 'ListControlsRequest',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::ListControlsRequest'->new($_) };

declare 'RepeatedListControlsRequest',
    as ArrayRef[ListControlsRequest()];

coerce 'RepeatedListControlsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::ListControlsRequest'->new($_) } @$_ ] };

declare 'MapStringListControlsRequest',
    as HashRef[ListControlsRequest()];

declare 'ListControlsResponse',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::ListControlsResponse'];

coerce 'ListControlsResponse',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::ListControlsResponse'->new($_) };

declare 'RepeatedListControlsResponse',
    as ArrayRef[ListControlsResponse()];

coerce 'RepeatedListControlsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::ListControlsResponse'->new($_) } @$_ ] };

declare 'MapStringListControlsResponse',
    as HashRef[ListControlsResponse()];

declare 'ReportGenerationProgress',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::ReportGenerationProgress'];

coerce 'ReportGenerationProgress',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::ReportGenerationProgress'->new($_) };

declare 'RepeatedReportGenerationProgress',
    as ArrayRef[ReportGenerationProgress()];

coerce 'RepeatedReportGenerationProgress',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::ReportGenerationProgress'->new($_) } @$_ ] };

declare 'MapStringReportGenerationProgress',
    as HashRef[ReportGenerationProgress()];

declare 'Enrollment',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::Enrollment'];

coerce 'Enrollment',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::Enrollment'->new($_) };

declare 'RepeatedEnrollment',
    as ArrayRef[Enrollment()];

coerce 'RepeatedEnrollment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::Enrollment'->new($_) } @$_ ] };

declare 'MapStringEnrollment',
    as HashRef[Enrollment()];

declare 'AuditScopeReport',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::AuditScopeReport'];

coerce 'AuditScopeReport',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::AuditScopeReport'->new($_) };

declare 'RepeatedAuditScopeReport',
    as ArrayRef[AuditScopeReport()];

coerce 'RepeatedAuditScopeReport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::AuditScopeReport'->new($_) } @$_ ] };

declare 'MapStringAuditScopeReport',
    as HashRef[AuditScopeReport()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'ResourceEnrollmentStatus',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::ResourceEnrollmentStatus'];

coerce 'ResourceEnrollmentStatus',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::ResourceEnrollmentStatus'->new($_) };

declare 'RepeatedResourceEnrollmentStatus',
    as ArrayRef[ResourceEnrollmentStatus()];

coerce 'RepeatedResourceEnrollmentStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::ResourceEnrollmentStatus'->new($_) } @$_ ] };

declare 'MapStringResourceEnrollmentStatus',
    as HashRef[ResourceEnrollmentStatus()];

declare 'ResourceEnrollmentState',
    as (Int | Str);

declare 'AuditReport',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::AuditReport'];

coerce 'AuditReport',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::AuditReport'->new($_) };

declare 'RepeatedAuditReport',
    as ArrayRef[AuditReport()];

coerce 'RepeatedAuditReport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::AuditReport'->new($_) } @$_ ] };

declare 'MapStringAuditReport',
    as HashRef[AuditReport()];

declare 'ReportGenerationState',
    as (Int | Str);

declare 'CloudControlParameterStatesEntry',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::AuditReport::CloudControlParameterStatesEntry'];

coerce 'CloudControlParameterStatesEntry',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::AuditReport::CloudControlParameterStatesEntry'->new($_) };

declare 'RepeatedCloudControlParameterStatesEntry',
    as ArrayRef[CloudControlParameterStatesEntry()];

coerce 'RepeatedCloudControlParameterStatesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::AuditReport::CloudControlParameterStatesEntry'->new($_) } @$_ ] };

declare 'MapStringCloudControlParameterStatesEntry',
    as HashRef[CloudControlParameterStatesEntry()];

declare 'ControlFamily',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::ControlFamily'];

coerce 'ControlFamily',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::ControlFamily'->new($_) };

declare 'RepeatedControlFamily',
    as ArrayRef[ControlFamily()];

coerce 'RepeatedControlFamily',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::ControlFamily'->new($_) } @$_ ] };

declare 'MapStringControlFamily',
    as HashRef[ControlFamily()];

declare 'Control',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::Control'];

coerce 'Control',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::Control'->new($_) };

declare 'RepeatedControl',
    as ArrayRef[Control()];

coerce 'RepeatedControl',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::Control'->new($_) } @$_ ] };

declare 'MapStringControl',
    as HashRef[Control()];

declare 'Family',
    as (Int | Str);

declare 'DestinationDetails',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::DestinationDetails'];

coerce 'DestinationDetails',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::DestinationDetails'->new($_) };

declare 'RepeatedDestinationDetails',
    as ArrayRef[DestinationDetails()];

coerce 'RepeatedDestinationDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::DestinationDetails'->new($_) } @$_ ] };

declare 'MapStringDestinationDetails',
    as HashRef[DestinationDetails()];

declare 'ReportSummary',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::ReportSummary'];

coerce 'ReportSummary',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::ReportSummary'->new($_) };

declare 'RepeatedReportSummary',
    as ArrayRef[ReportSummary()];

coerce 'RepeatedReportSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::ReportSummary'->new($_) } @$_ ] };

declare 'MapStringReportSummary',
    as HashRef[ReportSummary()];

declare 'ControlDetails',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::ControlDetails'];

coerce 'ControlDetails',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::ControlDetails'->new($_) };

declare 'RepeatedControlDetails',
    as ArrayRef[ControlDetails()];

coerce 'RepeatedControlDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::ControlDetails'->new($_) } @$_ ] };

declare 'MapStringControlDetails',
    as HashRef[ControlDetails()];

declare 'CreateAuditScheduleRequest',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::CreateAuditScheduleRequest'];

coerce 'CreateAuditScheduleRequest',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::CreateAuditScheduleRequest'->new($_) };

declare 'RepeatedCreateAuditScheduleRequest',
    as ArrayRef[CreateAuditScheduleRequest()];

coerce 'RepeatedCreateAuditScheduleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::CreateAuditScheduleRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAuditScheduleRequest',
    as HashRef[CreateAuditScheduleRequest()];

declare 'UpdateAuditScheduleRequest',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::UpdateAuditScheduleRequest'];

coerce 'UpdateAuditScheduleRequest',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::UpdateAuditScheduleRequest'->new($_) };

declare 'RepeatedUpdateAuditScheduleRequest',
    as ArrayRef[UpdateAuditScheduleRequest()];

coerce 'RepeatedUpdateAuditScheduleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::UpdateAuditScheduleRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAuditScheduleRequest',
    as HashRef[UpdateAuditScheduleRequest()];

declare 'GetAuditScheduleRequest',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::GetAuditScheduleRequest'];

coerce 'GetAuditScheduleRequest',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::GetAuditScheduleRequest'->new($_) };

declare 'RepeatedGetAuditScheduleRequest',
    as ArrayRef[GetAuditScheduleRequest()];

coerce 'RepeatedGetAuditScheduleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::GetAuditScheduleRequest'->new($_) } @$_ ] };

declare 'MapStringGetAuditScheduleRequest',
    as HashRef[GetAuditScheduleRequest()];

declare 'ListAuditSchedulesRequest',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::ListAuditSchedulesRequest'];

coerce 'ListAuditSchedulesRequest',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::ListAuditSchedulesRequest'->new($_) };

declare 'RepeatedListAuditSchedulesRequest',
    as ArrayRef[ListAuditSchedulesRequest()];

coerce 'RepeatedListAuditSchedulesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::ListAuditSchedulesRequest'->new($_) } @$_ ] };

declare 'MapStringListAuditSchedulesRequest',
    as HashRef[ListAuditSchedulesRequest()];

declare 'ListAuditSchedulesResponse',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::ListAuditSchedulesResponse'];

coerce 'ListAuditSchedulesResponse',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::ListAuditSchedulesResponse'->new($_) };

declare 'RepeatedListAuditSchedulesResponse',
    as ArrayRef[ListAuditSchedulesResponse()];

coerce 'RepeatedListAuditSchedulesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::ListAuditSchedulesResponse'->new($_) } @$_ ] };

declare 'MapStringListAuditSchedulesResponse',
    as HashRef[ListAuditSchedulesResponse()];

declare 'AuditSchedule',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::AuditSchedule'];

coerce 'AuditSchedule',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::AuditSchedule'->new($_) };

declare 'RepeatedAuditSchedule',
    as ArrayRef[AuditSchedule()];

coerce 'RepeatedAuditSchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::AuditSchedule'->new($_) } @$_ ] };

declare 'MapStringAuditSchedule',
    as HashRef[AuditSchedule()];

declare 'AuditReportFormat',
    as (Int | Str);

declare 'ParameterOverridesEntry',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::AuditSchedule::ParameterOverridesEntry'];

coerce 'ParameterOverridesEntry',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::AuditSchedule::ParameterOverridesEntry'->new($_) };

declare 'RepeatedParameterOverridesEntry',
    as ArrayRef[ParameterOverridesEntry()];

coerce 'RepeatedParameterOverridesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::AuditSchedule::ParameterOverridesEntry'->new($_) } @$_ ] };

declare 'MapStringParameterOverridesEntry',
    as HashRef[ParameterOverridesEntry()];

declare 'ScheduleConfig',
    as InstanceOf['Google::Cloud::Auditmanager::V1::Auditmanager::ScheduleConfig'];

coerce 'ScheduleConfig',
    from HashRef, via { 'Google::Cloud::Auditmanager::V1::Auditmanager::ScheduleConfig'->new($_) };

declare 'RepeatedScheduleConfig',
    as ArrayRef[ScheduleConfig()];

coerce 'RepeatedScheduleConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Auditmanager::V1::Auditmanager::ScheduleConfig'->new($_) } @$_ ] };

declare 'MapStringScheduleConfig',
    as HashRef[ScheduleConfig()];

declare 'Frequency',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Auditmanager::V1::Auditmanager::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
