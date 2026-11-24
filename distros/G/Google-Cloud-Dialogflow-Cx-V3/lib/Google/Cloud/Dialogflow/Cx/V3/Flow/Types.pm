package Google::Cloud::Dialogflow::Cx::V3::Flow::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'NluSettings',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Flow::NluSettings'];

coerce 'NluSettings',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Flow::NluSettings'->new($_) };

declare 'RepeatedNluSettings',
    as ArrayRef[NluSettings()];

coerce 'RepeatedNluSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Flow::NluSettings'->new($_) } @$_ ] };

declare 'MapStringNluSettings',
    as HashRef[NluSettings()];

declare 'ModelType',
    as (Int | Str);

declare 'ModelTrainingMode',
    as (Int | Str);

declare 'Flow',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Flow::Flow'];

coerce 'Flow',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Flow::Flow'->new($_) };

declare 'RepeatedFlow',
    as ArrayRef[Flow()];

coerce 'RepeatedFlow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Flow::Flow'->new($_) } @$_ ] };

declare 'MapStringFlow',
    as HashRef[Flow()];

declare 'MultiLanguageSettings',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Flow::Flow::MultiLanguageSettings'];

coerce 'MultiLanguageSettings',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Flow::Flow::MultiLanguageSettings'->new($_) };

declare 'RepeatedMultiLanguageSettings',
    as ArrayRef[MultiLanguageSettings()];

coerce 'RepeatedMultiLanguageSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Flow::Flow::MultiLanguageSettings'->new($_) } @$_ ] };

declare 'MapStringMultiLanguageSettings',
    as HashRef[MultiLanguageSettings()];

declare 'CreateFlowRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Flow::CreateFlowRequest'];

coerce 'CreateFlowRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Flow::CreateFlowRequest'->new($_) };

declare 'RepeatedCreateFlowRequest',
    as ArrayRef[CreateFlowRequest()];

coerce 'RepeatedCreateFlowRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Flow::CreateFlowRequest'->new($_) } @$_ ] };

declare 'MapStringCreateFlowRequest',
    as HashRef[CreateFlowRequest()];

declare 'DeleteFlowRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Flow::DeleteFlowRequest'];

coerce 'DeleteFlowRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Flow::DeleteFlowRequest'->new($_) };

declare 'RepeatedDeleteFlowRequest',
    as ArrayRef[DeleteFlowRequest()];

coerce 'RepeatedDeleteFlowRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Flow::DeleteFlowRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteFlowRequest',
    as HashRef[DeleteFlowRequest()];

declare 'ListFlowsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Flow::ListFlowsRequest'];

coerce 'ListFlowsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Flow::ListFlowsRequest'->new($_) };

declare 'RepeatedListFlowsRequest',
    as ArrayRef[ListFlowsRequest()];

coerce 'RepeatedListFlowsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Flow::ListFlowsRequest'->new($_) } @$_ ] };

declare 'MapStringListFlowsRequest',
    as HashRef[ListFlowsRequest()];

declare 'ListFlowsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Flow::ListFlowsResponse'];

coerce 'ListFlowsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Flow::ListFlowsResponse'->new($_) };

declare 'RepeatedListFlowsResponse',
    as ArrayRef[ListFlowsResponse()];

coerce 'RepeatedListFlowsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Flow::ListFlowsResponse'->new($_) } @$_ ] };

declare 'MapStringListFlowsResponse',
    as HashRef[ListFlowsResponse()];

declare 'GetFlowRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Flow::GetFlowRequest'];

coerce 'GetFlowRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Flow::GetFlowRequest'->new($_) };

declare 'RepeatedGetFlowRequest',
    as ArrayRef[GetFlowRequest()];

coerce 'RepeatedGetFlowRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Flow::GetFlowRequest'->new($_) } @$_ ] };

declare 'MapStringGetFlowRequest',
    as HashRef[GetFlowRequest()];

declare 'UpdateFlowRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Flow::UpdateFlowRequest'];

coerce 'UpdateFlowRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Flow::UpdateFlowRequest'->new($_) };

declare 'RepeatedUpdateFlowRequest',
    as ArrayRef[UpdateFlowRequest()];

coerce 'RepeatedUpdateFlowRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Flow::UpdateFlowRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateFlowRequest',
    as HashRef[UpdateFlowRequest()];

declare 'TrainFlowRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Flow::TrainFlowRequest'];

coerce 'TrainFlowRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Flow::TrainFlowRequest'->new($_) };

declare 'RepeatedTrainFlowRequest',
    as ArrayRef[TrainFlowRequest()];

coerce 'RepeatedTrainFlowRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Flow::TrainFlowRequest'->new($_) } @$_ ] };

declare 'MapStringTrainFlowRequest',
    as HashRef[TrainFlowRequest()];

declare 'ValidateFlowRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Flow::ValidateFlowRequest'];

coerce 'ValidateFlowRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Flow::ValidateFlowRequest'->new($_) };

declare 'RepeatedValidateFlowRequest',
    as ArrayRef[ValidateFlowRequest()];

coerce 'RepeatedValidateFlowRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Flow::ValidateFlowRequest'->new($_) } @$_ ] };

declare 'MapStringValidateFlowRequest',
    as HashRef[ValidateFlowRequest()];

declare 'GetFlowValidationResultRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Flow::GetFlowValidationResultRequest'];

coerce 'GetFlowValidationResultRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Flow::GetFlowValidationResultRequest'->new($_) };

declare 'RepeatedGetFlowValidationResultRequest',
    as ArrayRef[GetFlowValidationResultRequest()];

coerce 'RepeatedGetFlowValidationResultRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Flow::GetFlowValidationResultRequest'->new($_) } @$_ ] };

declare 'MapStringGetFlowValidationResultRequest',
    as HashRef[GetFlowValidationResultRequest()];

declare 'FlowValidationResult',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Flow::FlowValidationResult'];

coerce 'FlowValidationResult',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Flow::FlowValidationResult'->new($_) };

declare 'RepeatedFlowValidationResult',
    as ArrayRef[FlowValidationResult()];

coerce 'RepeatedFlowValidationResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Flow::FlowValidationResult'->new($_) } @$_ ] };

declare 'MapStringFlowValidationResult',
    as HashRef[FlowValidationResult()];

declare 'ImportFlowRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Flow::ImportFlowRequest'];

coerce 'ImportFlowRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Flow::ImportFlowRequest'->new($_) };

declare 'RepeatedImportFlowRequest',
    as ArrayRef[ImportFlowRequest()];

coerce 'RepeatedImportFlowRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Flow::ImportFlowRequest'->new($_) } @$_ ] };

declare 'MapStringImportFlowRequest',
    as HashRef[ImportFlowRequest()];

declare 'ImportOption',
    as (Int | Str);

declare 'FlowImportStrategy',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Flow::FlowImportStrategy'];

coerce 'FlowImportStrategy',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Flow::FlowImportStrategy'->new($_) };

declare 'RepeatedFlowImportStrategy',
    as ArrayRef[FlowImportStrategy()];

coerce 'RepeatedFlowImportStrategy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Flow::FlowImportStrategy'->new($_) } @$_ ] };

declare 'MapStringFlowImportStrategy',
    as HashRef[FlowImportStrategy()];

declare 'ImportFlowResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Flow::ImportFlowResponse'];

coerce 'ImportFlowResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Flow::ImportFlowResponse'->new($_) };

declare 'RepeatedImportFlowResponse',
    as ArrayRef[ImportFlowResponse()];

coerce 'RepeatedImportFlowResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Flow::ImportFlowResponse'->new($_) } @$_ ] };

declare 'MapStringImportFlowResponse',
    as HashRef[ImportFlowResponse()];

declare 'ExportFlowRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Flow::ExportFlowRequest'];

coerce 'ExportFlowRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Flow::ExportFlowRequest'->new($_) };

declare 'RepeatedExportFlowRequest',
    as ArrayRef[ExportFlowRequest()];

coerce 'RepeatedExportFlowRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Flow::ExportFlowRequest'->new($_) } @$_ ] };

declare 'MapStringExportFlowRequest',
    as HashRef[ExportFlowRequest()];

declare 'ExportFlowResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Flow::ExportFlowResponse'];

coerce 'ExportFlowResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Flow::ExportFlowResponse'->new($_) };

declare 'RepeatedExportFlowResponse',
    as ArrayRef[ExportFlowResponse()];

coerce 'RepeatedExportFlowResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Flow::ExportFlowResponse'->new($_) } @$_ ] };

declare 'MapStringExportFlowResponse',
    as HashRef[ExportFlowResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::Flow::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
