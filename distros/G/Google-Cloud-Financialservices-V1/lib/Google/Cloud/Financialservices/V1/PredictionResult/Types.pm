package Google::Cloud::Financialservices::V1::PredictionResult::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PredictionResult',
    as InstanceOf['Google::Cloud::Financialservices::V1::PredictionResult::PredictionResult'];

coerce 'PredictionResult',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::PredictionResult::PredictionResult'->new($_) };

declare 'RepeatedPredictionResult',
    as ArrayRef[PredictionResult()];

coerce 'RepeatedPredictionResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::PredictionResult::PredictionResult'->new($_) } @$_ ] };

declare 'MapStringPredictionResult',
    as HashRef[PredictionResult()];

declare 'State',
    as (Int | Str);

declare 'Outputs',
    as InstanceOf['Google::Cloud::Financialservices::V1::PredictionResult::PredictionResult::Outputs'];

coerce 'Outputs',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::PredictionResult::PredictionResult::Outputs'->new($_) };

declare 'RepeatedOutputs',
    as ArrayRef[Outputs()];

coerce 'RepeatedOutputs',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::PredictionResult::PredictionResult::Outputs'->new($_) } @$_ ] };

declare 'MapStringOutputs',
    as HashRef[Outputs()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Financialservices::V1::PredictionResult::PredictionResult::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::PredictionResult::PredictionResult::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::PredictionResult::PredictionResult::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListPredictionResultsRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::PredictionResult::ListPredictionResultsRequest'];

coerce 'ListPredictionResultsRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::PredictionResult::ListPredictionResultsRequest'->new($_) };

declare 'RepeatedListPredictionResultsRequest',
    as ArrayRef[ListPredictionResultsRequest()];

coerce 'RepeatedListPredictionResultsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::PredictionResult::ListPredictionResultsRequest'->new($_) } @$_ ] };

declare 'MapStringListPredictionResultsRequest',
    as HashRef[ListPredictionResultsRequest()];

declare 'ListPredictionResultsResponse',
    as InstanceOf['Google::Cloud::Financialservices::V1::PredictionResult::ListPredictionResultsResponse'];

coerce 'ListPredictionResultsResponse',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::PredictionResult::ListPredictionResultsResponse'->new($_) };

declare 'RepeatedListPredictionResultsResponse',
    as ArrayRef[ListPredictionResultsResponse()];

coerce 'RepeatedListPredictionResultsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::PredictionResult::ListPredictionResultsResponse'->new($_) } @$_ ] };

declare 'MapStringListPredictionResultsResponse',
    as HashRef[ListPredictionResultsResponse()];

declare 'GetPredictionResultRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::PredictionResult::GetPredictionResultRequest'];

coerce 'GetPredictionResultRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::PredictionResult::GetPredictionResultRequest'->new($_) };

declare 'RepeatedGetPredictionResultRequest',
    as ArrayRef[GetPredictionResultRequest()];

coerce 'RepeatedGetPredictionResultRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::PredictionResult::GetPredictionResultRequest'->new($_) } @$_ ] };

declare 'MapStringGetPredictionResultRequest',
    as HashRef[GetPredictionResultRequest()];

declare 'CreatePredictionResultRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::PredictionResult::CreatePredictionResultRequest'];

coerce 'CreatePredictionResultRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::PredictionResult::CreatePredictionResultRequest'->new($_) };

declare 'RepeatedCreatePredictionResultRequest',
    as ArrayRef[CreatePredictionResultRequest()];

coerce 'RepeatedCreatePredictionResultRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::PredictionResult::CreatePredictionResultRequest'->new($_) } @$_ ] };

declare 'MapStringCreatePredictionResultRequest',
    as HashRef[CreatePredictionResultRequest()];

declare 'UpdatePredictionResultRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::PredictionResult::UpdatePredictionResultRequest'];

coerce 'UpdatePredictionResultRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::PredictionResult::UpdatePredictionResultRequest'->new($_) };

declare 'RepeatedUpdatePredictionResultRequest',
    as ArrayRef[UpdatePredictionResultRequest()];

coerce 'RepeatedUpdatePredictionResultRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::PredictionResult::UpdatePredictionResultRequest'->new($_) } @$_ ] };

declare 'MapStringUpdatePredictionResultRequest',
    as HashRef[UpdatePredictionResultRequest()];

declare 'DeletePredictionResultRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::PredictionResult::DeletePredictionResultRequest'];

coerce 'DeletePredictionResultRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::PredictionResult::DeletePredictionResultRequest'->new($_) };

declare 'RepeatedDeletePredictionResultRequest',
    as ArrayRef[DeletePredictionResultRequest()];

coerce 'RepeatedDeletePredictionResultRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::PredictionResult::DeletePredictionResultRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePredictionResultRequest',
    as HashRef[DeletePredictionResultRequest()];

declare 'ExportPredictionResultMetadataRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::PredictionResult::ExportPredictionResultMetadataRequest'];

coerce 'ExportPredictionResultMetadataRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::PredictionResult::ExportPredictionResultMetadataRequest'->new($_) };

declare 'RepeatedExportPredictionResultMetadataRequest',
    as ArrayRef[ExportPredictionResultMetadataRequest()];

coerce 'RepeatedExportPredictionResultMetadataRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::PredictionResult::ExportPredictionResultMetadataRequest'->new($_) } @$_ ] };

declare 'MapStringExportPredictionResultMetadataRequest',
    as HashRef[ExportPredictionResultMetadataRequest()];

declare 'ExportPredictionResultMetadataResponse',
    as InstanceOf['Google::Cloud::Financialservices::V1::PredictionResult::ExportPredictionResultMetadataResponse'];

coerce 'ExportPredictionResultMetadataResponse',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::PredictionResult::ExportPredictionResultMetadataResponse'->new($_) };

declare 'RepeatedExportPredictionResultMetadataResponse',
    as ArrayRef[ExportPredictionResultMetadataResponse()];

coerce 'RepeatedExportPredictionResultMetadataResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::PredictionResult::ExportPredictionResultMetadataResponse'->new($_) } @$_ ] };

declare 'MapStringExportPredictionResultMetadataResponse',
    as HashRef[ExportPredictionResultMetadataResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Financialservices::V1::PredictionResult::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
