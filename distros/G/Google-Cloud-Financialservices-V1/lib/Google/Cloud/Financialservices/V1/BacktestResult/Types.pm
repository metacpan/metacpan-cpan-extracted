package Google::Cloud::Financialservices::V1::BacktestResult::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BacktestResult',
    as InstanceOf['Google::Cloud::Financialservices::V1::BacktestResult::BacktestResult'];

coerce 'BacktestResult',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::BacktestResult::BacktestResult'->new($_) };

declare 'RepeatedBacktestResult',
    as ArrayRef[BacktestResult()];

coerce 'RepeatedBacktestResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::BacktestResult::BacktestResult'->new($_) } @$_ ] };

declare 'MapStringBacktestResult',
    as HashRef[BacktestResult()];

declare 'State',
    as (Int | Str);

declare 'PerformanceTarget',
    as InstanceOf['Google::Cloud::Financialservices::V1::BacktestResult::BacktestResult::PerformanceTarget'];

coerce 'PerformanceTarget',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::BacktestResult::BacktestResult::PerformanceTarget'->new($_) };

declare 'RepeatedPerformanceTarget',
    as ArrayRef[PerformanceTarget()];

coerce 'RepeatedPerformanceTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::BacktestResult::BacktestResult::PerformanceTarget'->new($_) } @$_ ] };

declare 'MapStringPerformanceTarget',
    as HashRef[PerformanceTarget()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Financialservices::V1::BacktestResult::BacktestResult::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::BacktestResult::BacktestResult::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::BacktestResult::BacktestResult::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListBacktestResultsRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::BacktestResult::ListBacktestResultsRequest'];

coerce 'ListBacktestResultsRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::BacktestResult::ListBacktestResultsRequest'->new($_) };

declare 'RepeatedListBacktestResultsRequest',
    as ArrayRef[ListBacktestResultsRequest()];

coerce 'RepeatedListBacktestResultsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::BacktestResult::ListBacktestResultsRequest'->new($_) } @$_ ] };

declare 'MapStringListBacktestResultsRequest',
    as HashRef[ListBacktestResultsRequest()];

declare 'ListBacktestResultsResponse',
    as InstanceOf['Google::Cloud::Financialservices::V1::BacktestResult::ListBacktestResultsResponse'];

coerce 'ListBacktestResultsResponse',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::BacktestResult::ListBacktestResultsResponse'->new($_) };

declare 'RepeatedListBacktestResultsResponse',
    as ArrayRef[ListBacktestResultsResponse()];

coerce 'RepeatedListBacktestResultsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::BacktestResult::ListBacktestResultsResponse'->new($_) } @$_ ] };

declare 'MapStringListBacktestResultsResponse',
    as HashRef[ListBacktestResultsResponse()];

declare 'GetBacktestResultRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::BacktestResult::GetBacktestResultRequest'];

coerce 'GetBacktestResultRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::BacktestResult::GetBacktestResultRequest'->new($_) };

declare 'RepeatedGetBacktestResultRequest',
    as ArrayRef[GetBacktestResultRequest()];

coerce 'RepeatedGetBacktestResultRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::BacktestResult::GetBacktestResultRequest'->new($_) } @$_ ] };

declare 'MapStringGetBacktestResultRequest',
    as HashRef[GetBacktestResultRequest()];

declare 'CreateBacktestResultRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::BacktestResult::CreateBacktestResultRequest'];

coerce 'CreateBacktestResultRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::BacktestResult::CreateBacktestResultRequest'->new($_) };

declare 'RepeatedCreateBacktestResultRequest',
    as ArrayRef[CreateBacktestResultRequest()];

coerce 'RepeatedCreateBacktestResultRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::BacktestResult::CreateBacktestResultRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBacktestResultRequest',
    as HashRef[CreateBacktestResultRequest()];

declare 'UpdateBacktestResultRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::BacktestResult::UpdateBacktestResultRequest'];

coerce 'UpdateBacktestResultRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::BacktestResult::UpdateBacktestResultRequest'->new($_) };

declare 'RepeatedUpdateBacktestResultRequest',
    as ArrayRef[UpdateBacktestResultRequest()];

coerce 'RepeatedUpdateBacktestResultRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::BacktestResult::UpdateBacktestResultRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBacktestResultRequest',
    as HashRef[UpdateBacktestResultRequest()];

declare 'DeleteBacktestResultRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::BacktestResult::DeleteBacktestResultRequest'];

coerce 'DeleteBacktestResultRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::BacktestResult::DeleteBacktestResultRequest'->new($_) };

declare 'RepeatedDeleteBacktestResultRequest',
    as ArrayRef[DeleteBacktestResultRequest()];

coerce 'RepeatedDeleteBacktestResultRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::BacktestResult::DeleteBacktestResultRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBacktestResultRequest',
    as HashRef[DeleteBacktestResultRequest()];

declare 'ExportBacktestResultMetadataRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::BacktestResult::ExportBacktestResultMetadataRequest'];

coerce 'ExportBacktestResultMetadataRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::BacktestResult::ExportBacktestResultMetadataRequest'->new($_) };

declare 'RepeatedExportBacktestResultMetadataRequest',
    as ArrayRef[ExportBacktestResultMetadataRequest()];

coerce 'RepeatedExportBacktestResultMetadataRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::BacktestResult::ExportBacktestResultMetadataRequest'->new($_) } @$_ ] };

declare 'MapStringExportBacktestResultMetadataRequest',
    as HashRef[ExportBacktestResultMetadataRequest()];

declare 'ExportBacktestResultMetadataResponse',
    as InstanceOf['Google::Cloud::Financialservices::V1::BacktestResult::ExportBacktestResultMetadataResponse'];

coerce 'ExportBacktestResultMetadataResponse',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::BacktestResult::ExportBacktestResultMetadataResponse'->new($_) };

declare 'RepeatedExportBacktestResultMetadataResponse',
    as ArrayRef[ExportBacktestResultMetadataResponse()];

coerce 'RepeatedExportBacktestResultMetadataResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::BacktestResult::ExportBacktestResultMetadataResponse'->new($_) } @$_ ] };

declare 'MapStringExportBacktestResultMetadataResponse',
    as HashRef[ExportBacktestResultMetadataResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Financialservices::V1::BacktestResult::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
