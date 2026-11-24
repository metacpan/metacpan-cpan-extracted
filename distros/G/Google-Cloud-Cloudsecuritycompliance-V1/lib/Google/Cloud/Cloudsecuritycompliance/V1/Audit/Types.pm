package Google::Cloud::Cloudsecuritycompliance::V1::Audit::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ComplianceState',
    as (Int | Str);

declare 'GenerateFrameworkAuditScopeReportRequest',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Audit::GenerateFrameworkAuditScopeReportRequest'];

coerce 'GenerateFrameworkAuditScopeReportRequest',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::GenerateFrameworkAuditScopeReportRequest'->new($_) };

declare 'RepeatedGenerateFrameworkAuditScopeReportRequest',
    as ArrayRef[GenerateFrameworkAuditScopeReportRequest()];

coerce 'RepeatedGenerateFrameworkAuditScopeReportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::GenerateFrameworkAuditScopeReportRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateFrameworkAuditScopeReportRequest',
    as HashRef[GenerateFrameworkAuditScopeReportRequest()];

declare 'Format',
    as (Int | Str);

declare 'GenerateFrameworkAuditScopeReportResponse',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Audit::GenerateFrameworkAuditScopeReportResponse'];

coerce 'GenerateFrameworkAuditScopeReportResponse',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::GenerateFrameworkAuditScopeReportResponse'->new($_) };

declare 'RepeatedGenerateFrameworkAuditScopeReportResponse',
    as ArrayRef[GenerateFrameworkAuditScopeReportResponse()];

coerce 'RepeatedGenerateFrameworkAuditScopeReportResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::GenerateFrameworkAuditScopeReportResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateFrameworkAuditScopeReportResponse',
    as HashRef[GenerateFrameworkAuditScopeReportResponse()];

declare 'ReportSummary',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Audit::ReportSummary'];

coerce 'ReportSummary',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::ReportSummary'->new($_) };

declare 'RepeatedReportSummary',
    as ArrayRef[ReportSummary()];

coerce 'RepeatedReportSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::ReportSummary'->new($_) } @$_ ] };

declare 'MapStringReportSummary',
    as HashRef[ReportSummary()];

declare 'CreateFrameworkAuditRequest',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Audit::CreateFrameworkAuditRequest'];

coerce 'CreateFrameworkAuditRequest',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::CreateFrameworkAuditRequest'->new($_) };

declare 'RepeatedCreateFrameworkAuditRequest',
    as ArrayRef[CreateFrameworkAuditRequest()];

coerce 'RepeatedCreateFrameworkAuditRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::CreateFrameworkAuditRequest'->new($_) } @$_ ] };

declare 'MapStringCreateFrameworkAuditRequest',
    as HashRef[CreateFrameworkAuditRequest()];

declare 'FrameworkAuditDestination',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Audit::FrameworkAuditDestination'];

coerce 'FrameworkAuditDestination',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::FrameworkAuditDestination'->new($_) };

declare 'RepeatedFrameworkAuditDestination',
    as ArrayRef[FrameworkAuditDestination()];

coerce 'RepeatedFrameworkAuditDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::FrameworkAuditDestination'->new($_) } @$_ ] };

declare 'MapStringFrameworkAuditDestination',
    as HashRef[FrameworkAuditDestination()];

declare 'BucketDestination',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Audit::BucketDestination'];

coerce 'BucketDestination',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::BucketDestination'->new($_) };

declare 'RepeatedBucketDestination',
    as ArrayRef[BucketDestination()];

coerce 'RepeatedBucketDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::BucketDestination'->new($_) } @$_ ] };

declare 'MapStringBucketDestination',
    as HashRef[BucketDestination()];

declare 'Format',
    as (Int | Str);

declare 'FrameworkAudit',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Audit::FrameworkAudit'];

coerce 'FrameworkAudit',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::FrameworkAudit'->new($_) };

declare 'RepeatedFrameworkAudit',
    as ArrayRef[FrameworkAudit()];

coerce 'RepeatedFrameworkAudit',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::FrameworkAudit'->new($_) } @$_ ] };

declare 'MapStringFrameworkAudit',
    as HashRef[FrameworkAudit()];

declare 'State',
    as (Int | Str);

declare 'ListFrameworkAuditsRequest',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Audit::ListFrameworkAuditsRequest'];

coerce 'ListFrameworkAuditsRequest',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::ListFrameworkAuditsRequest'->new($_) };

declare 'RepeatedListFrameworkAuditsRequest',
    as ArrayRef[ListFrameworkAuditsRequest()];

coerce 'RepeatedListFrameworkAuditsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::ListFrameworkAuditsRequest'->new($_) } @$_ ] };

declare 'MapStringListFrameworkAuditsRequest',
    as HashRef[ListFrameworkAuditsRequest()];

declare 'ListFrameworkAuditsResponse',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Audit::ListFrameworkAuditsResponse'];

coerce 'ListFrameworkAuditsResponse',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::ListFrameworkAuditsResponse'->new($_) };

declare 'RepeatedListFrameworkAuditsResponse',
    as ArrayRef[ListFrameworkAuditsResponse()];

coerce 'RepeatedListFrameworkAuditsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::ListFrameworkAuditsResponse'->new($_) } @$_ ] };

declare 'MapStringListFrameworkAuditsResponse',
    as HashRef[ListFrameworkAuditsResponse()];

declare 'GetFrameworkAuditRequest',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Audit::GetFrameworkAuditRequest'];

coerce 'GetFrameworkAuditRequest',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::GetFrameworkAuditRequest'->new($_) };

declare 'RepeatedGetFrameworkAuditRequest',
    as ArrayRef[GetFrameworkAuditRequest()];

coerce 'RepeatedGetFrameworkAuditRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::GetFrameworkAuditRequest'->new($_) } @$_ ] };

declare 'MapStringGetFrameworkAuditRequest',
    as HashRef[GetFrameworkAuditRequest()];

declare 'CloudControlGroupAuditDetails',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Audit::CloudControlGroupAuditDetails'];

coerce 'CloudControlGroupAuditDetails',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::CloudControlGroupAuditDetails'->new($_) };

declare 'RepeatedCloudControlGroupAuditDetails',
    as ArrayRef[CloudControlGroupAuditDetails()];

coerce 'RepeatedCloudControlGroupAuditDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::CloudControlGroupAuditDetails'->new($_) } @$_ ] };

declare 'MapStringCloudControlGroupAuditDetails',
    as HashRef[CloudControlGroupAuditDetails()];

declare 'FindingDetails',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Audit::FindingDetails'];

coerce 'FindingDetails',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::FindingDetails'->new($_) };

declare 'RepeatedFindingDetails',
    as ArrayRef[FindingDetails()];

coerce 'RepeatedFindingDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::FindingDetails'->new($_) } @$_ ] };

declare 'MapStringFindingDetails',
    as HashRef[FindingDetails()];

declare 'ObservationDetails',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Audit::ObservationDetails'];

coerce 'ObservationDetails',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::ObservationDetails'->new($_) };

declare 'RepeatedObservationDetails',
    as ArrayRef[ObservationDetails()];

coerce 'RepeatedObservationDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::ObservationDetails'->new($_) } @$_ ] };

declare 'MapStringObservationDetails',
    as HashRef[ObservationDetails()];

declare 'EvidenceDetails',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Audit::EvidenceDetails'];

coerce 'EvidenceDetails',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::EvidenceDetails'->new($_) };

declare 'RepeatedEvidenceDetails',
    as ArrayRef[EvidenceDetails()];

coerce 'RepeatedEvidenceDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::EvidenceDetails'->new($_) } @$_ ] };

declare 'MapStringEvidenceDetails',
    as HashRef[EvidenceDetails()];

declare 'CloudControlAuditDetails',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Audit::CloudControlAuditDetails'];

coerce 'CloudControlAuditDetails',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::CloudControlAuditDetails'->new($_) };

declare 'RepeatedCloudControlAuditDetails',
    as ArrayRef[CloudControlAuditDetails()];

coerce 'RepeatedCloudControlAuditDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Audit::CloudControlAuditDetails'->new($_) } @$_ ] };

declare 'MapStringCloudControlAuditDetails',
    as HashRef[CloudControlAuditDetails()];

1;

__END__

=head1 NAME

Google::Cloud::Cloudsecuritycompliance::V1::Audit::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
