package Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EvaluationState',
    as (Int | Str);

declare 'FindingClass',
    as (Int | Str);

declare 'FrameworkComplianceSummaryView',
    as (Int | Str);

declare 'ListFrameworkComplianceSummariesRequest',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ListFrameworkComplianceSummariesRequest'];

coerce 'ListFrameworkComplianceSummariesRequest',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ListFrameworkComplianceSummariesRequest'->new($_) };

declare 'RepeatedListFrameworkComplianceSummariesRequest',
    as ArrayRef[ListFrameworkComplianceSummariesRequest()];

coerce 'RepeatedListFrameworkComplianceSummariesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ListFrameworkComplianceSummariesRequest'->new($_) } @$_ ] };

declare 'MapStringListFrameworkComplianceSummariesRequest',
    as HashRef[ListFrameworkComplianceSummariesRequest()];

declare 'ListFrameworkComplianceSummariesResponse',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ListFrameworkComplianceSummariesResponse'];

coerce 'ListFrameworkComplianceSummariesResponse',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ListFrameworkComplianceSummariesResponse'->new($_) };

declare 'RepeatedListFrameworkComplianceSummariesResponse',
    as ArrayRef[ListFrameworkComplianceSummariesResponse()];

coerce 'RepeatedListFrameworkComplianceSummariesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ListFrameworkComplianceSummariesResponse'->new($_) } @$_ ] };

declare 'MapStringListFrameworkComplianceSummariesResponse',
    as HashRef[ListFrameworkComplianceSummariesResponse()];

declare 'FrameworkComplianceReport',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::FrameworkComplianceReport'];

coerce 'FrameworkComplianceReport',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::FrameworkComplianceReport'->new($_) };

declare 'RepeatedFrameworkComplianceReport',
    as ArrayRef[FrameworkComplianceReport()];

coerce 'RepeatedFrameworkComplianceReport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::FrameworkComplianceReport'->new($_) } @$_ ] };

declare 'MapStringFrameworkComplianceReport',
    as HashRef[FrameworkComplianceReport()];

declare 'FetchFrameworkComplianceReportRequest',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::FetchFrameworkComplianceReportRequest'];

coerce 'FetchFrameworkComplianceReportRequest',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::FetchFrameworkComplianceReportRequest'->new($_) };

declare 'RepeatedFetchFrameworkComplianceReportRequest',
    as ArrayRef[FetchFrameworkComplianceReportRequest()];

coerce 'RepeatedFetchFrameworkComplianceReportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::FetchFrameworkComplianceReportRequest'->new($_) } @$_ ] };

declare 'MapStringFetchFrameworkComplianceReportRequest',
    as HashRef[FetchFrameworkComplianceReportRequest()];

declare 'ListFindingSummariesRequest',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ListFindingSummariesRequest'];

coerce 'ListFindingSummariesRequest',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ListFindingSummariesRequest'->new($_) };

declare 'RepeatedListFindingSummariesRequest',
    as ArrayRef[ListFindingSummariesRequest()];

coerce 'RepeatedListFindingSummariesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ListFindingSummariesRequest'->new($_) } @$_ ] };

declare 'MapStringListFindingSummariesRequest',
    as HashRef[ListFindingSummariesRequest()];

declare 'ListFindingSummariesResponse',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ListFindingSummariesResponse'];

coerce 'ListFindingSummariesResponse',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ListFindingSummariesResponse'->new($_) };

declare 'RepeatedListFindingSummariesResponse',
    as ArrayRef[ListFindingSummariesResponse()];

coerce 'RepeatedListFindingSummariesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ListFindingSummariesResponse'->new($_) } @$_ ] };

declare 'MapStringListFindingSummariesResponse',
    as HashRef[ListFindingSummariesResponse()];

declare 'ListControlComplianceSummariesRequest',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ListControlComplianceSummariesRequest'];

coerce 'ListControlComplianceSummariesRequest',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ListControlComplianceSummariesRequest'->new($_) };

declare 'RepeatedListControlComplianceSummariesRequest',
    as ArrayRef[ListControlComplianceSummariesRequest()];

coerce 'RepeatedListControlComplianceSummariesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ListControlComplianceSummariesRequest'->new($_) } @$_ ] };

declare 'MapStringListControlComplianceSummariesRequest',
    as HashRef[ListControlComplianceSummariesRequest()];

declare 'ListControlComplianceSummariesResponse',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ListControlComplianceSummariesResponse'];

coerce 'ListControlComplianceSummariesResponse',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ListControlComplianceSummariesResponse'->new($_) };

declare 'RepeatedListControlComplianceSummariesResponse',
    as ArrayRef[ListControlComplianceSummariesResponse()];

coerce 'RepeatedListControlComplianceSummariesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ListControlComplianceSummariesResponse'->new($_) } @$_ ] };

declare 'MapStringListControlComplianceSummariesResponse',
    as HashRef[ListControlComplianceSummariesResponse()];

declare 'AggregateFrameworkComplianceReportRequest',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::AggregateFrameworkComplianceReportRequest'];

coerce 'AggregateFrameworkComplianceReportRequest',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::AggregateFrameworkComplianceReportRequest'->new($_) };

declare 'RepeatedAggregateFrameworkComplianceReportRequest',
    as ArrayRef[AggregateFrameworkComplianceReportRequest()];

coerce 'RepeatedAggregateFrameworkComplianceReportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::AggregateFrameworkComplianceReportRequest'->new($_) } @$_ ] };

declare 'MapStringAggregateFrameworkComplianceReportRequest',
    as HashRef[AggregateFrameworkComplianceReportRequest()];

declare 'AggregateFrameworkComplianceReportResponse',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::AggregateFrameworkComplianceReportResponse'];

coerce 'AggregateFrameworkComplianceReportResponse',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::AggregateFrameworkComplianceReportResponse'->new($_) };

declare 'RepeatedAggregateFrameworkComplianceReportResponse',
    as ArrayRef[AggregateFrameworkComplianceReportResponse()];

coerce 'RepeatedAggregateFrameworkComplianceReportResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::AggregateFrameworkComplianceReportResponse'->new($_) } @$_ ] };

declare 'MapStringAggregateFrameworkComplianceReportResponse',
    as HashRef[AggregateFrameworkComplianceReportResponse()];

declare 'ControlAssessmentDetails',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ControlAssessmentDetails'];

coerce 'ControlAssessmentDetails',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ControlAssessmentDetails'->new($_) };

declare 'RepeatedControlAssessmentDetails',
    as ArrayRef[ControlAssessmentDetails()];

coerce 'RepeatedControlAssessmentDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ControlAssessmentDetails'->new($_) } @$_ ] };

declare 'MapStringControlAssessmentDetails',
    as HashRef[ControlAssessmentDetails()];

declare 'FrameworkComplianceSummary',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::FrameworkComplianceSummary'];

coerce 'FrameworkComplianceSummary',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::FrameworkComplianceSummary'->new($_) };

declare 'RepeatedFrameworkComplianceSummary',
    as ArrayRef[FrameworkComplianceSummary()];

coerce 'RepeatedFrameworkComplianceSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::FrameworkComplianceSummary'->new($_) } @$_ ] };

declare 'MapStringFrameworkComplianceSummary',
    as HashRef[FrameworkComplianceSummary()];

declare 'FindingSummary',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::FindingSummary'];

coerce 'FindingSummary',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::FindingSummary'->new($_) };

declare 'RepeatedFindingSummary',
    as ArrayRef[FindingSummary()];

coerce 'RepeatedFindingSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::FindingSummary'->new($_) } @$_ ] };

declare 'MapStringFindingSummary',
    as HashRef[FindingSummary()];

declare 'ControlComplianceSummary',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ControlComplianceSummary'];

coerce 'ControlComplianceSummary',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ControlComplianceSummary'->new($_) };

declare 'RepeatedControlComplianceSummary',
    as ArrayRef[ControlComplianceSummary()];

coerce 'RepeatedControlComplianceSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ControlComplianceSummary'->new($_) } @$_ ] };

declare 'MapStringControlComplianceSummary',
    as HashRef[ControlComplianceSummary()];

declare 'CloudControlReport',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::CloudControlReport'];

coerce 'CloudControlReport',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::CloudControlReport'->new($_) };

declare 'RepeatedCloudControlReport',
    as ArrayRef[CloudControlReport()];

coerce 'RepeatedCloudControlReport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::CloudControlReport'->new($_) } @$_ ] };

declare 'MapStringCloudControlReport',
    as HashRef[CloudControlReport()];

declare 'ManualCloudControlAssessmentDetails',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ManualCloudControlAssessmentDetails'];

coerce 'ManualCloudControlAssessmentDetails',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ManualCloudControlAssessmentDetails'->new($_) };

declare 'RepeatedManualCloudControlAssessmentDetails',
    as ArrayRef[ManualCloudControlAssessmentDetails()];

coerce 'RepeatedManualCloudControlAssessmentDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::ManualCloudControlAssessmentDetails'->new($_) } @$_ ] };

declare 'MapStringManualCloudControlAssessmentDetails',
    as HashRef[ManualCloudControlAssessmentDetails()];

declare 'CloudControlAssessmentDetails',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::CloudControlAssessmentDetails'];

coerce 'CloudControlAssessmentDetails',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::CloudControlAssessmentDetails'->new($_) };

declare 'RepeatedCloudControlAssessmentDetails',
    as ArrayRef[CloudControlAssessmentDetails()];

coerce 'RepeatedCloudControlAssessmentDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::CloudControlAssessmentDetails'->new($_) } @$_ ] };

declare 'MapStringCloudControlAssessmentDetails',
    as HashRef[CloudControlAssessmentDetails()];

declare 'SimilarControls',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::SimilarControls'];

coerce 'SimilarControls',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::SimilarControls'->new($_) };

declare 'RepeatedSimilarControls',
    as ArrayRef[SimilarControls()];

coerce 'RepeatedSimilarControls',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::SimilarControls'->new($_) } @$_ ] };

declare 'MapStringSimilarControls',
    as HashRef[SimilarControls()];

declare 'AggregatedComplianceReport',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::AggregatedComplianceReport'];

coerce 'AggregatedComplianceReport',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::AggregatedComplianceReport'->new($_) };

declare 'RepeatedAggregatedComplianceReport',
    as ArrayRef[AggregatedComplianceReport()];

coerce 'RepeatedAggregatedComplianceReport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::AggregatedComplianceReport'->new($_) } @$_ ] };

declare 'MapStringAggregatedComplianceReport',
    as HashRef[AggregatedComplianceReport()];

declare 'TargetResourceDetails',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::TargetResourceDetails'];

coerce 'TargetResourceDetails',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::TargetResourceDetails'->new($_) };

declare 'RepeatedTargetResourceDetails',
    as ArrayRef[TargetResourceDetails()];

coerce 'RepeatedTargetResourceDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::TargetResourceDetails'->new($_) } @$_ ] };

declare 'MapStringTargetResourceDetails',
    as HashRef[TargetResourceDetails()];

declare 'Trend',
    as InstanceOf['Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::Trend'];

coerce 'Trend',
    from HashRef, via { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::Trend'->new($_) };

declare 'RepeatedTrend',
    as ArrayRef[Trend()];

coerce 'RepeatedTrend',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::Trend'->new($_) } @$_ ] };

declare 'MapStringTrend',
    as HashRef[Trend()];

1;

__END__

=head1 NAME

Google::Cloud::Cloudsecuritycompliance::V1::Monitoring::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
