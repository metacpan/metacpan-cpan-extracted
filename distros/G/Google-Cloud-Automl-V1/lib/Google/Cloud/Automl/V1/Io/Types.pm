package Google::Cloud::Automl::V1::Io::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'InputConfig',
    as InstanceOf['Google::Cloud::Automl::V1::Io::InputConfig'];

coerce 'InputConfig',
    from HashRef, via { 'Google::Cloud::Automl::V1::Io::InputConfig'->new($_) };

declare 'RepeatedInputConfig',
    as ArrayRef[InputConfig()];

coerce 'RepeatedInputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Io::InputConfig'->new($_) } @$_ ] };

declare 'MapStringInputConfig',
    as HashRef[InputConfig()];

declare 'ParamsEntry',
    as InstanceOf['Google::Cloud::Automl::V1::Io::InputConfig::ParamsEntry'];

coerce 'ParamsEntry',
    from HashRef, via { 'Google::Cloud::Automl::V1::Io::InputConfig::ParamsEntry'->new($_) };

declare 'RepeatedParamsEntry',
    as ArrayRef[ParamsEntry()];

coerce 'RepeatedParamsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Io::InputConfig::ParamsEntry'->new($_) } @$_ ] };

declare 'MapStringParamsEntry',
    as HashRef[ParamsEntry()];

declare 'BatchPredictInputConfig',
    as InstanceOf['Google::Cloud::Automl::V1::Io::BatchPredictInputConfig'];

coerce 'BatchPredictInputConfig',
    from HashRef, via { 'Google::Cloud::Automl::V1::Io::BatchPredictInputConfig'->new($_) };

declare 'RepeatedBatchPredictInputConfig',
    as ArrayRef[BatchPredictInputConfig()];

coerce 'RepeatedBatchPredictInputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Io::BatchPredictInputConfig'->new($_) } @$_ ] };

declare 'MapStringBatchPredictInputConfig',
    as HashRef[BatchPredictInputConfig()];

declare 'DocumentInputConfig',
    as InstanceOf['Google::Cloud::Automl::V1::Io::DocumentInputConfig'];

coerce 'DocumentInputConfig',
    from HashRef, via { 'Google::Cloud::Automl::V1::Io::DocumentInputConfig'->new($_) };

declare 'RepeatedDocumentInputConfig',
    as ArrayRef[DocumentInputConfig()];

coerce 'RepeatedDocumentInputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Io::DocumentInputConfig'->new($_) } @$_ ] };

declare 'MapStringDocumentInputConfig',
    as HashRef[DocumentInputConfig()];

declare 'OutputConfig',
    as InstanceOf['Google::Cloud::Automl::V1::Io::OutputConfig'];

coerce 'OutputConfig',
    from HashRef, via { 'Google::Cloud::Automl::V1::Io::OutputConfig'->new($_) };

declare 'RepeatedOutputConfig',
    as ArrayRef[OutputConfig()];

coerce 'RepeatedOutputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Io::OutputConfig'->new($_) } @$_ ] };

declare 'MapStringOutputConfig',
    as HashRef[OutputConfig()];

declare 'BatchPredictOutputConfig',
    as InstanceOf['Google::Cloud::Automl::V1::Io::BatchPredictOutputConfig'];

coerce 'BatchPredictOutputConfig',
    from HashRef, via { 'Google::Cloud::Automl::V1::Io::BatchPredictOutputConfig'->new($_) };

declare 'RepeatedBatchPredictOutputConfig',
    as ArrayRef[BatchPredictOutputConfig()];

coerce 'RepeatedBatchPredictOutputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Io::BatchPredictOutputConfig'->new($_) } @$_ ] };

declare 'MapStringBatchPredictOutputConfig',
    as HashRef[BatchPredictOutputConfig()];

declare 'ModelExportOutputConfig',
    as InstanceOf['Google::Cloud::Automl::V1::Io::ModelExportOutputConfig'];

coerce 'ModelExportOutputConfig',
    from HashRef, via { 'Google::Cloud::Automl::V1::Io::ModelExportOutputConfig'->new($_) };

declare 'RepeatedModelExportOutputConfig',
    as ArrayRef[ModelExportOutputConfig()];

coerce 'RepeatedModelExportOutputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Io::ModelExportOutputConfig'->new($_) } @$_ ] };

declare 'MapStringModelExportOutputConfig',
    as HashRef[ModelExportOutputConfig()];

declare 'ParamsEntry',
    as InstanceOf['Google::Cloud::Automl::V1::Io::ModelExportOutputConfig::ParamsEntry'];

coerce 'ParamsEntry',
    from HashRef, via { 'Google::Cloud::Automl::V1::Io::ModelExportOutputConfig::ParamsEntry'->new($_) };

declare 'RepeatedParamsEntry',
    as ArrayRef[ParamsEntry()];

coerce 'RepeatedParamsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Io::ModelExportOutputConfig::ParamsEntry'->new($_) } @$_ ] };

declare 'MapStringParamsEntry',
    as HashRef[ParamsEntry()];

declare 'GcsSource',
    as InstanceOf['Google::Cloud::Automl::V1::Io::GcsSource'];

coerce 'GcsSource',
    from HashRef, via { 'Google::Cloud::Automl::V1::Io::GcsSource'->new($_) };

declare 'RepeatedGcsSource',
    as ArrayRef[GcsSource()];

coerce 'RepeatedGcsSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Io::GcsSource'->new($_) } @$_ ] };

declare 'MapStringGcsSource',
    as HashRef[GcsSource()];

declare 'GcsDestination',
    as InstanceOf['Google::Cloud::Automl::V1::Io::GcsDestination'];

coerce 'GcsDestination',
    from HashRef, via { 'Google::Cloud::Automl::V1::Io::GcsDestination'->new($_) };

declare 'RepeatedGcsDestination',
    as ArrayRef[GcsDestination()];

coerce 'RepeatedGcsDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1::Io::GcsDestination'->new($_) } @$_ ] };

declare 'MapStringGcsDestination',
    as HashRef[GcsDestination()];

1;

__END__

=head1 NAME

Google::Cloud::Automl::V1::Io::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
