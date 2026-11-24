package Google::Cloud::Datalabeling::V1beta1::Dataset::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataType',
    as (Int | Str);

declare 'Dataset',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Dataset::Dataset'];

coerce 'Dataset',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Dataset::Dataset'->new($_) };

declare 'RepeatedDataset',
    as ArrayRef[Dataset()];

coerce 'RepeatedDataset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Dataset::Dataset'->new($_) } @$_ ] };

declare 'MapStringDataset',
    as HashRef[Dataset()];

declare 'InputConfig',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Dataset::InputConfig'];

coerce 'InputConfig',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Dataset::InputConfig'->new($_) };

declare 'RepeatedInputConfig',
    as ArrayRef[InputConfig()];

coerce 'RepeatedInputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Dataset::InputConfig'->new($_) } @$_ ] };

declare 'MapStringInputConfig',
    as HashRef[InputConfig()];

declare 'TextMetadata',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Dataset::TextMetadata'];

coerce 'TextMetadata',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Dataset::TextMetadata'->new($_) };

declare 'RepeatedTextMetadata',
    as ArrayRef[TextMetadata()];

coerce 'RepeatedTextMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Dataset::TextMetadata'->new($_) } @$_ ] };

declare 'MapStringTextMetadata',
    as HashRef[TextMetadata()];

declare 'ClassificationMetadata',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Dataset::ClassificationMetadata'];

coerce 'ClassificationMetadata',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Dataset::ClassificationMetadata'->new($_) };

declare 'RepeatedClassificationMetadata',
    as ArrayRef[ClassificationMetadata()];

coerce 'RepeatedClassificationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Dataset::ClassificationMetadata'->new($_) } @$_ ] };

declare 'MapStringClassificationMetadata',
    as HashRef[ClassificationMetadata()];

declare 'GcsSource',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Dataset::GcsSource'];

coerce 'GcsSource',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Dataset::GcsSource'->new($_) };

declare 'RepeatedGcsSource',
    as ArrayRef[GcsSource()];

coerce 'RepeatedGcsSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Dataset::GcsSource'->new($_) } @$_ ] };

declare 'MapStringGcsSource',
    as HashRef[GcsSource()];

declare 'BigQuerySource',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Dataset::BigQuerySource'];

coerce 'BigQuerySource',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Dataset::BigQuerySource'->new($_) };

declare 'RepeatedBigQuerySource',
    as ArrayRef[BigQuerySource()];

coerce 'RepeatedBigQuerySource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Dataset::BigQuerySource'->new($_) } @$_ ] };

declare 'MapStringBigQuerySource',
    as HashRef[BigQuerySource()];

declare 'OutputConfig',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Dataset::OutputConfig'];

coerce 'OutputConfig',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Dataset::OutputConfig'->new($_) };

declare 'RepeatedOutputConfig',
    as ArrayRef[OutputConfig()];

coerce 'RepeatedOutputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Dataset::OutputConfig'->new($_) } @$_ ] };

declare 'MapStringOutputConfig',
    as HashRef[OutputConfig()];

declare 'GcsDestination',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Dataset::GcsDestination'];

coerce 'GcsDestination',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Dataset::GcsDestination'->new($_) };

declare 'RepeatedGcsDestination',
    as ArrayRef[GcsDestination()];

coerce 'RepeatedGcsDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Dataset::GcsDestination'->new($_) } @$_ ] };

declare 'MapStringGcsDestination',
    as HashRef[GcsDestination()];

declare 'GcsFolderDestination',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Dataset::GcsFolderDestination'];

coerce 'GcsFolderDestination',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Dataset::GcsFolderDestination'->new($_) };

declare 'RepeatedGcsFolderDestination',
    as ArrayRef[GcsFolderDestination()];

coerce 'RepeatedGcsFolderDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Dataset::GcsFolderDestination'->new($_) } @$_ ] };

declare 'MapStringGcsFolderDestination',
    as HashRef[GcsFolderDestination()];

declare 'DataItem',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Dataset::DataItem'];

coerce 'DataItem',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Dataset::DataItem'->new($_) };

declare 'RepeatedDataItem',
    as ArrayRef[DataItem()];

coerce 'RepeatedDataItem',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Dataset::DataItem'->new($_) } @$_ ] };

declare 'MapStringDataItem',
    as HashRef[DataItem()];

declare 'AnnotatedDataset',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Dataset::AnnotatedDataset'];

coerce 'AnnotatedDataset',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Dataset::AnnotatedDataset'->new($_) };

declare 'RepeatedAnnotatedDataset',
    as ArrayRef[AnnotatedDataset()];

coerce 'RepeatedAnnotatedDataset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Dataset::AnnotatedDataset'->new($_) } @$_ ] };

declare 'MapStringAnnotatedDataset',
    as HashRef[AnnotatedDataset()];

declare 'LabelStats',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Dataset::LabelStats'];

coerce 'LabelStats',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Dataset::LabelStats'->new($_) };

declare 'RepeatedLabelStats',
    as ArrayRef[LabelStats()];

coerce 'RepeatedLabelStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Dataset::LabelStats'->new($_) } @$_ ] };

declare 'MapStringLabelStats',
    as HashRef[LabelStats()];

declare 'ExampleCountEntry',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Dataset::LabelStats::ExampleCountEntry'];

coerce 'ExampleCountEntry',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Dataset::LabelStats::ExampleCountEntry'->new($_) };

declare 'RepeatedExampleCountEntry',
    as ArrayRef[ExampleCountEntry()];

coerce 'RepeatedExampleCountEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Dataset::LabelStats::ExampleCountEntry'->new($_) } @$_ ] };

declare 'MapStringExampleCountEntry',
    as HashRef[ExampleCountEntry()];

declare 'AnnotatedDatasetMetadata',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Dataset::AnnotatedDatasetMetadata'];

coerce 'AnnotatedDatasetMetadata',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Dataset::AnnotatedDatasetMetadata'->new($_) };

declare 'RepeatedAnnotatedDatasetMetadata',
    as ArrayRef[AnnotatedDatasetMetadata()];

coerce 'RepeatedAnnotatedDatasetMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Dataset::AnnotatedDatasetMetadata'->new($_) } @$_ ] };

declare 'MapStringAnnotatedDatasetMetadata',
    as HashRef[AnnotatedDatasetMetadata()];

declare 'Example',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Dataset::Example'];

coerce 'Example',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Dataset::Example'->new($_) };

declare 'RepeatedExample',
    as ArrayRef[Example()];

coerce 'RepeatedExample',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Dataset::Example'->new($_) } @$_ ] };

declare 'MapStringExample',
    as HashRef[Example()];

1;

__END__

=head1 NAME

Google::Cloud::Datalabeling::V1beta1::Dataset::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
