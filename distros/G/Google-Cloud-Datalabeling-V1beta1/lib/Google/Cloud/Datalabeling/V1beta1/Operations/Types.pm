package Google::Cloud::Datalabeling::V1beta1::Operations::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ImportDataOperationResponse',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Operations::ImportDataOperationResponse'];

coerce 'ImportDataOperationResponse',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Operations::ImportDataOperationResponse'->new($_) };

declare 'RepeatedImportDataOperationResponse',
    as ArrayRef[ImportDataOperationResponse()];

coerce 'RepeatedImportDataOperationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Operations::ImportDataOperationResponse'->new($_) } @$_ ] };

declare 'MapStringImportDataOperationResponse',
    as HashRef[ImportDataOperationResponse()];

declare 'ExportDataOperationResponse',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Operations::ExportDataOperationResponse'];

coerce 'ExportDataOperationResponse',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Operations::ExportDataOperationResponse'->new($_) };

declare 'RepeatedExportDataOperationResponse',
    as ArrayRef[ExportDataOperationResponse()];

coerce 'RepeatedExportDataOperationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Operations::ExportDataOperationResponse'->new($_) } @$_ ] };

declare 'MapStringExportDataOperationResponse',
    as HashRef[ExportDataOperationResponse()];

declare 'ImportDataOperationMetadata',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Operations::ImportDataOperationMetadata'];

coerce 'ImportDataOperationMetadata',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Operations::ImportDataOperationMetadata'->new($_) };

declare 'RepeatedImportDataOperationMetadata',
    as ArrayRef[ImportDataOperationMetadata()];

coerce 'RepeatedImportDataOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Operations::ImportDataOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringImportDataOperationMetadata',
    as HashRef[ImportDataOperationMetadata()];

declare 'ExportDataOperationMetadata',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Operations::ExportDataOperationMetadata'];

coerce 'ExportDataOperationMetadata',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Operations::ExportDataOperationMetadata'->new($_) };

declare 'RepeatedExportDataOperationMetadata',
    as ArrayRef[ExportDataOperationMetadata()];

coerce 'RepeatedExportDataOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Operations::ExportDataOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringExportDataOperationMetadata',
    as HashRef[ExportDataOperationMetadata()];

declare 'LabelOperationMetadata',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Operations::LabelOperationMetadata'];

coerce 'LabelOperationMetadata',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Operations::LabelOperationMetadata'->new($_) };

declare 'RepeatedLabelOperationMetadata',
    as ArrayRef[LabelOperationMetadata()];

coerce 'RepeatedLabelOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Operations::LabelOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringLabelOperationMetadata',
    as HashRef[LabelOperationMetadata()];

declare 'LabelImageClassificationOperationMetadata',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Operations::LabelImageClassificationOperationMetadata'];

coerce 'LabelImageClassificationOperationMetadata',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Operations::LabelImageClassificationOperationMetadata'->new($_) };

declare 'RepeatedLabelImageClassificationOperationMetadata',
    as ArrayRef[LabelImageClassificationOperationMetadata()];

coerce 'RepeatedLabelImageClassificationOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Operations::LabelImageClassificationOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringLabelImageClassificationOperationMetadata',
    as HashRef[LabelImageClassificationOperationMetadata()];

declare 'LabelImageBoundingBoxOperationMetadata',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Operations::LabelImageBoundingBoxOperationMetadata'];

coerce 'LabelImageBoundingBoxOperationMetadata',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Operations::LabelImageBoundingBoxOperationMetadata'->new($_) };

declare 'RepeatedLabelImageBoundingBoxOperationMetadata',
    as ArrayRef[LabelImageBoundingBoxOperationMetadata()];

coerce 'RepeatedLabelImageBoundingBoxOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Operations::LabelImageBoundingBoxOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringLabelImageBoundingBoxOperationMetadata',
    as HashRef[LabelImageBoundingBoxOperationMetadata()];

declare 'LabelImageOrientedBoundingBoxOperationMetadata',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Operations::LabelImageOrientedBoundingBoxOperationMetadata'];

coerce 'LabelImageOrientedBoundingBoxOperationMetadata',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Operations::LabelImageOrientedBoundingBoxOperationMetadata'->new($_) };

declare 'RepeatedLabelImageOrientedBoundingBoxOperationMetadata',
    as ArrayRef[LabelImageOrientedBoundingBoxOperationMetadata()];

coerce 'RepeatedLabelImageOrientedBoundingBoxOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Operations::LabelImageOrientedBoundingBoxOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringLabelImageOrientedBoundingBoxOperationMetadata',
    as HashRef[LabelImageOrientedBoundingBoxOperationMetadata()];

declare 'LabelImageBoundingPolyOperationMetadata',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Operations::LabelImageBoundingPolyOperationMetadata'];

coerce 'LabelImageBoundingPolyOperationMetadata',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Operations::LabelImageBoundingPolyOperationMetadata'->new($_) };

declare 'RepeatedLabelImageBoundingPolyOperationMetadata',
    as ArrayRef[LabelImageBoundingPolyOperationMetadata()];

coerce 'RepeatedLabelImageBoundingPolyOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Operations::LabelImageBoundingPolyOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringLabelImageBoundingPolyOperationMetadata',
    as HashRef[LabelImageBoundingPolyOperationMetadata()];

declare 'LabelImagePolylineOperationMetadata',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Operations::LabelImagePolylineOperationMetadata'];

coerce 'LabelImagePolylineOperationMetadata',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Operations::LabelImagePolylineOperationMetadata'->new($_) };

declare 'RepeatedLabelImagePolylineOperationMetadata',
    as ArrayRef[LabelImagePolylineOperationMetadata()];

coerce 'RepeatedLabelImagePolylineOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Operations::LabelImagePolylineOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringLabelImagePolylineOperationMetadata',
    as HashRef[LabelImagePolylineOperationMetadata()];

declare 'LabelImageSegmentationOperationMetadata',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Operations::LabelImageSegmentationOperationMetadata'];

coerce 'LabelImageSegmentationOperationMetadata',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Operations::LabelImageSegmentationOperationMetadata'->new($_) };

declare 'RepeatedLabelImageSegmentationOperationMetadata',
    as ArrayRef[LabelImageSegmentationOperationMetadata()];

coerce 'RepeatedLabelImageSegmentationOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Operations::LabelImageSegmentationOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringLabelImageSegmentationOperationMetadata',
    as HashRef[LabelImageSegmentationOperationMetadata()];

declare 'LabelVideoClassificationOperationMetadata',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Operations::LabelVideoClassificationOperationMetadata'];

coerce 'LabelVideoClassificationOperationMetadata',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Operations::LabelVideoClassificationOperationMetadata'->new($_) };

declare 'RepeatedLabelVideoClassificationOperationMetadata',
    as ArrayRef[LabelVideoClassificationOperationMetadata()];

coerce 'RepeatedLabelVideoClassificationOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Operations::LabelVideoClassificationOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringLabelVideoClassificationOperationMetadata',
    as HashRef[LabelVideoClassificationOperationMetadata()];

declare 'LabelVideoObjectDetectionOperationMetadata',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Operations::LabelVideoObjectDetectionOperationMetadata'];

coerce 'LabelVideoObjectDetectionOperationMetadata',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Operations::LabelVideoObjectDetectionOperationMetadata'->new($_) };

declare 'RepeatedLabelVideoObjectDetectionOperationMetadata',
    as ArrayRef[LabelVideoObjectDetectionOperationMetadata()];

coerce 'RepeatedLabelVideoObjectDetectionOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Operations::LabelVideoObjectDetectionOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringLabelVideoObjectDetectionOperationMetadata',
    as HashRef[LabelVideoObjectDetectionOperationMetadata()];

declare 'LabelVideoObjectTrackingOperationMetadata',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Operations::LabelVideoObjectTrackingOperationMetadata'];

coerce 'LabelVideoObjectTrackingOperationMetadata',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Operations::LabelVideoObjectTrackingOperationMetadata'->new($_) };

declare 'RepeatedLabelVideoObjectTrackingOperationMetadata',
    as ArrayRef[LabelVideoObjectTrackingOperationMetadata()];

coerce 'RepeatedLabelVideoObjectTrackingOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Operations::LabelVideoObjectTrackingOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringLabelVideoObjectTrackingOperationMetadata',
    as HashRef[LabelVideoObjectTrackingOperationMetadata()];

declare 'LabelVideoEventOperationMetadata',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Operations::LabelVideoEventOperationMetadata'];

coerce 'LabelVideoEventOperationMetadata',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Operations::LabelVideoEventOperationMetadata'->new($_) };

declare 'RepeatedLabelVideoEventOperationMetadata',
    as ArrayRef[LabelVideoEventOperationMetadata()];

coerce 'RepeatedLabelVideoEventOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Operations::LabelVideoEventOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringLabelVideoEventOperationMetadata',
    as HashRef[LabelVideoEventOperationMetadata()];

declare 'LabelTextClassificationOperationMetadata',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Operations::LabelTextClassificationOperationMetadata'];

coerce 'LabelTextClassificationOperationMetadata',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Operations::LabelTextClassificationOperationMetadata'->new($_) };

declare 'RepeatedLabelTextClassificationOperationMetadata',
    as ArrayRef[LabelTextClassificationOperationMetadata()];

coerce 'RepeatedLabelTextClassificationOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Operations::LabelTextClassificationOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringLabelTextClassificationOperationMetadata',
    as HashRef[LabelTextClassificationOperationMetadata()];

declare 'LabelTextEntityExtractionOperationMetadata',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Operations::LabelTextEntityExtractionOperationMetadata'];

coerce 'LabelTextEntityExtractionOperationMetadata',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Operations::LabelTextEntityExtractionOperationMetadata'->new($_) };

declare 'RepeatedLabelTextEntityExtractionOperationMetadata',
    as ArrayRef[LabelTextEntityExtractionOperationMetadata()];

coerce 'RepeatedLabelTextEntityExtractionOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Operations::LabelTextEntityExtractionOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringLabelTextEntityExtractionOperationMetadata',
    as HashRef[LabelTextEntityExtractionOperationMetadata()];

declare 'CreateInstructionMetadata',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::Operations::CreateInstructionMetadata'];

coerce 'CreateInstructionMetadata',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::Operations::CreateInstructionMetadata'->new($_) };

declare 'RepeatedCreateInstructionMetadata',
    as ArrayRef[CreateInstructionMetadata()];

coerce 'RepeatedCreateInstructionMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::Operations::CreateInstructionMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateInstructionMetadata',
    as HashRef[CreateInstructionMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Datalabeling::V1beta1::Operations::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
