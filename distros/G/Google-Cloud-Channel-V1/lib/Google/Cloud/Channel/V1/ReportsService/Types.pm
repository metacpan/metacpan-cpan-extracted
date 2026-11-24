package Google::Cloud::Channel::V1::ReportsService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RunReportJobRequest',
    as InstanceOf['Google::Cloud::Channel::V1::ReportsService::RunReportJobRequest'];

coerce 'RunReportJobRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::ReportsService::RunReportJobRequest'->new($_) };

declare 'RepeatedRunReportJobRequest',
    as ArrayRef[RunReportJobRequest()];

coerce 'RepeatedRunReportJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::ReportsService::RunReportJobRequest'->new($_) } @$_ ] };

declare 'MapStringRunReportJobRequest',
    as HashRef[RunReportJobRequest()];

declare 'RunReportJobResponse',
    as InstanceOf['Google::Cloud::Channel::V1::ReportsService::RunReportJobResponse'];

coerce 'RunReportJobResponse',
    from HashRef, via { 'Google::Cloud::Channel::V1::ReportsService::RunReportJobResponse'->new($_) };

declare 'RepeatedRunReportJobResponse',
    as ArrayRef[RunReportJobResponse()];

coerce 'RepeatedRunReportJobResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::ReportsService::RunReportJobResponse'->new($_) } @$_ ] };

declare 'MapStringRunReportJobResponse',
    as HashRef[RunReportJobResponse()];

declare 'FetchReportResultsRequest',
    as InstanceOf['Google::Cloud::Channel::V1::ReportsService::FetchReportResultsRequest'];

coerce 'FetchReportResultsRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::ReportsService::FetchReportResultsRequest'->new($_) };

declare 'RepeatedFetchReportResultsRequest',
    as ArrayRef[FetchReportResultsRequest()];

coerce 'RepeatedFetchReportResultsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::ReportsService::FetchReportResultsRequest'->new($_) } @$_ ] };

declare 'MapStringFetchReportResultsRequest',
    as HashRef[FetchReportResultsRequest()];

declare 'FetchReportResultsResponse',
    as InstanceOf['Google::Cloud::Channel::V1::ReportsService::FetchReportResultsResponse'];

coerce 'FetchReportResultsResponse',
    from HashRef, via { 'Google::Cloud::Channel::V1::ReportsService::FetchReportResultsResponse'->new($_) };

declare 'RepeatedFetchReportResultsResponse',
    as ArrayRef[FetchReportResultsResponse()];

coerce 'RepeatedFetchReportResultsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::ReportsService::FetchReportResultsResponse'->new($_) } @$_ ] };

declare 'MapStringFetchReportResultsResponse',
    as HashRef[FetchReportResultsResponse()];

declare 'ListReportsRequest',
    as InstanceOf['Google::Cloud::Channel::V1::ReportsService::ListReportsRequest'];

coerce 'ListReportsRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::ReportsService::ListReportsRequest'->new($_) };

declare 'RepeatedListReportsRequest',
    as ArrayRef[ListReportsRequest()];

coerce 'RepeatedListReportsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::ReportsService::ListReportsRequest'->new($_) } @$_ ] };

declare 'MapStringListReportsRequest',
    as HashRef[ListReportsRequest()];

declare 'ListReportsResponse',
    as InstanceOf['Google::Cloud::Channel::V1::ReportsService::ListReportsResponse'];

coerce 'ListReportsResponse',
    from HashRef, via { 'Google::Cloud::Channel::V1::ReportsService::ListReportsResponse'->new($_) };

declare 'RepeatedListReportsResponse',
    as ArrayRef[ListReportsResponse()];

coerce 'RepeatedListReportsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::ReportsService::ListReportsResponse'->new($_) } @$_ ] };

declare 'MapStringListReportsResponse',
    as HashRef[ListReportsResponse()];

declare 'ReportJob',
    as InstanceOf['Google::Cloud::Channel::V1::ReportsService::ReportJob'];

coerce 'ReportJob',
    from HashRef, via { 'Google::Cloud::Channel::V1::ReportsService::ReportJob'->new($_) };

declare 'RepeatedReportJob',
    as ArrayRef[ReportJob()];

coerce 'RepeatedReportJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::ReportsService::ReportJob'->new($_) } @$_ ] };

declare 'MapStringReportJob',
    as HashRef[ReportJob()];

declare 'ReportResultsMetadata',
    as InstanceOf['Google::Cloud::Channel::V1::ReportsService::ReportResultsMetadata'];

coerce 'ReportResultsMetadata',
    from HashRef, via { 'Google::Cloud::Channel::V1::ReportsService::ReportResultsMetadata'->new($_) };

declare 'RepeatedReportResultsMetadata',
    as ArrayRef[ReportResultsMetadata()];

coerce 'RepeatedReportResultsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::ReportsService::ReportResultsMetadata'->new($_) } @$_ ] };

declare 'MapStringReportResultsMetadata',
    as HashRef[ReportResultsMetadata()];

declare 'Column',
    as InstanceOf['Google::Cloud::Channel::V1::ReportsService::Column'];

coerce 'Column',
    from HashRef, via { 'Google::Cloud::Channel::V1::ReportsService::Column'->new($_) };

declare 'RepeatedColumn',
    as ArrayRef[Column()];

coerce 'RepeatedColumn',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::ReportsService::Column'->new($_) } @$_ ] };

declare 'MapStringColumn',
    as HashRef[Column()];

declare 'DataType',
    as (Int | Str);

declare 'DateRange',
    as InstanceOf['Google::Cloud::Channel::V1::ReportsService::DateRange'];

coerce 'DateRange',
    from HashRef, via { 'Google::Cloud::Channel::V1::ReportsService::DateRange'->new($_) };

declare 'RepeatedDateRange',
    as ArrayRef[DateRange()];

coerce 'RepeatedDateRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::ReportsService::DateRange'->new($_) } @$_ ] };

declare 'MapStringDateRange',
    as HashRef[DateRange()];

declare 'Row',
    as InstanceOf['Google::Cloud::Channel::V1::ReportsService::Row'];

coerce 'Row',
    from HashRef, via { 'Google::Cloud::Channel::V1::ReportsService::Row'->new($_) };

declare 'RepeatedRow',
    as ArrayRef[Row()];

coerce 'RepeatedRow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::ReportsService::Row'->new($_) } @$_ ] };

declare 'MapStringRow',
    as HashRef[Row()];

declare 'ReportValue',
    as InstanceOf['Google::Cloud::Channel::V1::ReportsService::ReportValue'];

coerce 'ReportValue',
    from HashRef, via { 'Google::Cloud::Channel::V1::ReportsService::ReportValue'->new($_) };

declare 'RepeatedReportValue',
    as ArrayRef[ReportValue()];

coerce 'RepeatedReportValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::ReportsService::ReportValue'->new($_) } @$_ ] };

declare 'MapStringReportValue',
    as HashRef[ReportValue()];

declare 'ReportStatus',
    as InstanceOf['Google::Cloud::Channel::V1::ReportsService::ReportStatus'];

coerce 'ReportStatus',
    from HashRef, via { 'Google::Cloud::Channel::V1::ReportsService::ReportStatus'->new($_) };

declare 'RepeatedReportStatus',
    as ArrayRef[ReportStatus()];

coerce 'RepeatedReportStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::ReportsService::ReportStatus'->new($_) } @$_ ] };

declare 'MapStringReportStatus',
    as HashRef[ReportStatus()];

declare 'State',
    as (Int | Str);

declare 'Report',
    as InstanceOf['Google::Cloud::Channel::V1::ReportsService::Report'];

coerce 'Report',
    from HashRef, via { 'Google::Cloud::Channel::V1::ReportsService::Report'->new($_) };

declare 'RepeatedReport',
    as ArrayRef[Report()];

coerce 'RepeatedReport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::ReportsService::Report'->new($_) } @$_ ] };

declare 'MapStringReport',
    as HashRef[Report()];

1;

__END__

=head1 NAME

Google::Cloud::Channel::V1::ReportsService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
