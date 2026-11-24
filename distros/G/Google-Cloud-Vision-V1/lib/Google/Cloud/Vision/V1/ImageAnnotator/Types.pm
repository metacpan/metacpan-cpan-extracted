package Google::Cloud::Vision::V1::ImageAnnotator::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Likelihood',
    as (Int | Str);

declare 'Feature',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::Feature'];

coerce 'Feature',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::Feature'->new($_) };

declare 'RepeatedFeature',
    as ArrayRef[Feature()];

coerce 'RepeatedFeature',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::Feature'->new($_) } @$_ ] };

declare 'MapStringFeature',
    as HashRef[Feature()];

declare 'Type',
    as (Int | Str);

declare 'ImageSource',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::ImageSource'];

coerce 'ImageSource',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::ImageSource'->new($_) };

declare 'RepeatedImageSource',
    as ArrayRef[ImageSource()];

coerce 'RepeatedImageSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::ImageSource'->new($_) } @$_ ] };

declare 'MapStringImageSource',
    as HashRef[ImageSource()];

declare 'Image',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::Image'];

coerce 'Image',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::Image'->new($_) };

declare 'RepeatedImage',
    as ArrayRef[Image()];

coerce 'RepeatedImage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::Image'->new($_) } @$_ ] };

declare 'MapStringImage',
    as HashRef[Image()];

declare 'FaceAnnotation',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::FaceAnnotation'];

coerce 'FaceAnnotation',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::FaceAnnotation'->new($_) };

declare 'RepeatedFaceAnnotation',
    as ArrayRef[FaceAnnotation()];

coerce 'RepeatedFaceAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::FaceAnnotation'->new($_) } @$_ ] };

declare 'MapStringFaceAnnotation',
    as HashRef[FaceAnnotation()];

declare 'Landmark',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::FaceAnnotation::Landmark'];

coerce 'Landmark',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::FaceAnnotation::Landmark'->new($_) };

declare 'RepeatedLandmark',
    as ArrayRef[Landmark()];

coerce 'RepeatedLandmark',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::FaceAnnotation::Landmark'->new($_) } @$_ ] };

declare 'MapStringLandmark',
    as HashRef[Landmark()];

declare 'Type',
    as (Int | Str);

declare 'LocationInfo',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::LocationInfo'];

coerce 'LocationInfo',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::LocationInfo'->new($_) };

declare 'RepeatedLocationInfo',
    as ArrayRef[LocationInfo()];

coerce 'RepeatedLocationInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::LocationInfo'->new($_) } @$_ ] };

declare 'MapStringLocationInfo',
    as HashRef[LocationInfo()];

declare 'Property',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::Property'];

coerce 'Property',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::Property'->new($_) };

declare 'RepeatedProperty',
    as ArrayRef[Property()];

coerce 'RepeatedProperty',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::Property'->new($_) } @$_ ] };

declare 'MapStringProperty',
    as HashRef[Property()];

declare 'EntityAnnotation',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::EntityAnnotation'];

coerce 'EntityAnnotation',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::EntityAnnotation'->new($_) };

declare 'RepeatedEntityAnnotation',
    as ArrayRef[EntityAnnotation()];

coerce 'RepeatedEntityAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::EntityAnnotation'->new($_) } @$_ ] };

declare 'MapStringEntityAnnotation',
    as HashRef[EntityAnnotation()];

declare 'LocalizedObjectAnnotation',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::LocalizedObjectAnnotation'];

coerce 'LocalizedObjectAnnotation',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::LocalizedObjectAnnotation'->new($_) };

declare 'RepeatedLocalizedObjectAnnotation',
    as ArrayRef[LocalizedObjectAnnotation()];

coerce 'RepeatedLocalizedObjectAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::LocalizedObjectAnnotation'->new($_) } @$_ ] };

declare 'MapStringLocalizedObjectAnnotation',
    as HashRef[LocalizedObjectAnnotation()];

declare 'SafeSearchAnnotation',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::SafeSearchAnnotation'];

coerce 'SafeSearchAnnotation',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::SafeSearchAnnotation'->new($_) };

declare 'RepeatedSafeSearchAnnotation',
    as ArrayRef[SafeSearchAnnotation()];

coerce 'RepeatedSafeSearchAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::SafeSearchAnnotation'->new($_) } @$_ ] };

declare 'MapStringSafeSearchAnnotation',
    as HashRef[SafeSearchAnnotation()];

declare 'LatLongRect',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::LatLongRect'];

coerce 'LatLongRect',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::LatLongRect'->new($_) };

declare 'RepeatedLatLongRect',
    as ArrayRef[LatLongRect()];

coerce 'RepeatedLatLongRect',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::LatLongRect'->new($_) } @$_ ] };

declare 'MapStringLatLongRect',
    as HashRef[LatLongRect()];

declare 'ColorInfo',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::ColorInfo'];

coerce 'ColorInfo',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::ColorInfo'->new($_) };

declare 'RepeatedColorInfo',
    as ArrayRef[ColorInfo()];

coerce 'RepeatedColorInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::ColorInfo'->new($_) } @$_ ] };

declare 'MapStringColorInfo',
    as HashRef[ColorInfo()];

declare 'DominantColorsAnnotation',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::DominantColorsAnnotation'];

coerce 'DominantColorsAnnotation',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::DominantColorsAnnotation'->new($_) };

declare 'RepeatedDominantColorsAnnotation',
    as ArrayRef[DominantColorsAnnotation()];

coerce 'RepeatedDominantColorsAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::DominantColorsAnnotation'->new($_) } @$_ ] };

declare 'MapStringDominantColorsAnnotation',
    as HashRef[DominantColorsAnnotation()];

declare 'ImageProperties',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::ImageProperties'];

coerce 'ImageProperties',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::ImageProperties'->new($_) };

declare 'RepeatedImageProperties',
    as ArrayRef[ImageProperties()];

coerce 'RepeatedImageProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::ImageProperties'->new($_) } @$_ ] };

declare 'MapStringImageProperties',
    as HashRef[ImageProperties()];

declare 'CropHint',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::CropHint'];

coerce 'CropHint',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::CropHint'->new($_) };

declare 'RepeatedCropHint',
    as ArrayRef[CropHint()];

coerce 'RepeatedCropHint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::CropHint'->new($_) } @$_ ] };

declare 'MapStringCropHint',
    as HashRef[CropHint()];

declare 'CropHintsAnnotation',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::CropHintsAnnotation'];

coerce 'CropHintsAnnotation',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::CropHintsAnnotation'->new($_) };

declare 'RepeatedCropHintsAnnotation',
    as ArrayRef[CropHintsAnnotation()];

coerce 'RepeatedCropHintsAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::CropHintsAnnotation'->new($_) } @$_ ] };

declare 'MapStringCropHintsAnnotation',
    as HashRef[CropHintsAnnotation()];

declare 'CropHintsParams',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::CropHintsParams'];

coerce 'CropHintsParams',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::CropHintsParams'->new($_) };

declare 'RepeatedCropHintsParams',
    as ArrayRef[CropHintsParams()];

coerce 'RepeatedCropHintsParams',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::CropHintsParams'->new($_) } @$_ ] };

declare 'MapStringCropHintsParams',
    as HashRef[CropHintsParams()];

declare 'WebDetectionParams',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::WebDetectionParams'];

coerce 'WebDetectionParams',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::WebDetectionParams'->new($_) };

declare 'RepeatedWebDetectionParams',
    as ArrayRef[WebDetectionParams()];

coerce 'RepeatedWebDetectionParams',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::WebDetectionParams'->new($_) } @$_ ] };

declare 'MapStringWebDetectionParams',
    as HashRef[WebDetectionParams()];

declare 'TextDetectionParams',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::TextDetectionParams'];

coerce 'TextDetectionParams',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::TextDetectionParams'->new($_) };

declare 'RepeatedTextDetectionParams',
    as ArrayRef[TextDetectionParams()];

coerce 'RepeatedTextDetectionParams',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::TextDetectionParams'->new($_) } @$_ ] };

declare 'MapStringTextDetectionParams',
    as HashRef[TextDetectionParams()];

declare 'ImageContext',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::ImageContext'];

coerce 'ImageContext',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::ImageContext'->new($_) };

declare 'RepeatedImageContext',
    as ArrayRef[ImageContext()];

coerce 'RepeatedImageContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::ImageContext'->new($_) } @$_ ] };

declare 'MapStringImageContext',
    as HashRef[ImageContext()];

declare 'AnnotateImageRequest',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::AnnotateImageRequest'];

coerce 'AnnotateImageRequest',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::AnnotateImageRequest'->new($_) };

declare 'RepeatedAnnotateImageRequest',
    as ArrayRef[AnnotateImageRequest()];

coerce 'RepeatedAnnotateImageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::AnnotateImageRequest'->new($_) } @$_ ] };

declare 'MapStringAnnotateImageRequest',
    as HashRef[AnnotateImageRequest()];

declare 'ImageAnnotationContext',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::ImageAnnotationContext'];

coerce 'ImageAnnotationContext',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::ImageAnnotationContext'->new($_) };

declare 'RepeatedImageAnnotationContext',
    as ArrayRef[ImageAnnotationContext()];

coerce 'RepeatedImageAnnotationContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::ImageAnnotationContext'->new($_) } @$_ ] };

declare 'MapStringImageAnnotationContext',
    as HashRef[ImageAnnotationContext()];

declare 'AnnotateImageResponse',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::AnnotateImageResponse'];

coerce 'AnnotateImageResponse',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::AnnotateImageResponse'->new($_) };

declare 'RepeatedAnnotateImageResponse',
    as ArrayRef[AnnotateImageResponse()];

coerce 'RepeatedAnnotateImageResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::AnnotateImageResponse'->new($_) } @$_ ] };

declare 'MapStringAnnotateImageResponse',
    as HashRef[AnnotateImageResponse()];

declare 'BatchAnnotateImagesRequest',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::BatchAnnotateImagesRequest'];

coerce 'BatchAnnotateImagesRequest',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::BatchAnnotateImagesRequest'->new($_) };

declare 'RepeatedBatchAnnotateImagesRequest',
    as ArrayRef[BatchAnnotateImagesRequest()];

coerce 'RepeatedBatchAnnotateImagesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::BatchAnnotateImagesRequest'->new($_) } @$_ ] };

declare 'MapStringBatchAnnotateImagesRequest',
    as HashRef[BatchAnnotateImagesRequest()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::BatchAnnotateImagesRequest::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::BatchAnnotateImagesRequest::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::BatchAnnotateImagesRequest::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'BatchAnnotateImagesResponse',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::BatchAnnotateImagesResponse'];

coerce 'BatchAnnotateImagesResponse',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::BatchAnnotateImagesResponse'->new($_) };

declare 'RepeatedBatchAnnotateImagesResponse',
    as ArrayRef[BatchAnnotateImagesResponse()];

coerce 'RepeatedBatchAnnotateImagesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::BatchAnnotateImagesResponse'->new($_) } @$_ ] };

declare 'MapStringBatchAnnotateImagesResponse',
    as HashRef[BatchAnnotateImagesResponse()];

declare 'AnnotateFileRequest',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::AnnotateFileRequest'];

coerce 'AnnotateFileRequest',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::AnnotateFileRequest'->new($_) };

declare 'RepeatedAnnotateFileRequest',
    as ArrayRef[AnnotateFileRequest()];

coerce 'RepeatedAnnotateFileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::AnnotateFileRequest'->new($_) } @$_ ] };

declare 'MapStringAnnotateFileRequest',
    as HashRef[AnnotateFileRequest()];

declare 'AnnotateFileResponse',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::AnnotateFileResponse'];

coerce 'AnnotateFileResponse',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::AnnotateFileResponse'->new($_) };

declare 'RepeatedAnnotateFileResponse',
    as ArrayRef[AnnotateFileResponse()];

coerce 'RepeatedAnnotateFileResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::AnnotateFileResponse'->new($_) } @$_ ] };

declare 'MapStringAnnotateFileResponse',
    as HashRef[AnnotateFileResponse()];

declare 'BatchAnnotateFilesRequest',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::BatchAnnotateFilesRequest'];

coerce 'BatchAnnotateFilesRequest',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::BatchAnnotateFilesRequest'->new($_) };

declare 'RepeatedBatchAnnotateFilesRequest',
    as ArrayRef[BatchAnnotateFilesRequest()];

coerce 'RepeatedBatchAnnotateFilesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::BatchAnnotateFilesRequest'->new($_) } @$_ ] };

declare 'MapStringBatchAnnotateFilesRequest',
    as HashRef[BatchAnnotateFilesRequest()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::BatchAnnotateFilesRequest::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::BatchAnnotateFilesRequest::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::BatchAnnotateFilesRequest::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'BatchAnnotateFilesResponse',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::BatchAnnotateFilesResponse'];

coerce 'BatchAnnotateFilesResponse',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::BatchAnnotateFilesResponse'->new($_) };

declare 'RepeatedBatchAnnotateFilesResponse',
    as ArrayRef[BatchAnnotateFilesResponse()];

coerce 'RepeatedBatchAnnotateFilesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::BatchAnnotateFilesResponse'->new($_) } @$_ ] };

declare 'MapStringBatchAnnotateFilesResponse',
    as HashRef[BatchAnnotateFilesResponse()];

declare 'AsyncAnnotateFileRequest',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::AsyncAnnotateFileRequest'];

coerce 'AsyncAnnotateFileRequest',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::AsyncAnnotateFileRequest'->new($_) };

declare 'RepeatedAsyncAnnotateFileRequest',
    as ArrayRef[AsyncAnnotateFileRequest()];

coerce 'RepeatedAsyncAnnotateFileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::AsyncAnnotateFileRequest'->new($_) } @$_ ] };

declare 'MapStringAsyncAnnotateFileRequest',
    as HashRef[AsyncAnnotateFileRequest()];

declare 'AsyncAnnotateFileResponse',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::AsyncAnnotateFileResponse'];

coerce 'AsyncAnnotateFileResponse',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::AsyncAnnotateFileResponse'->new($_) };

declare 'RepeatedAsyncAnnotateFileResponse',
    as ArrayRef[AsyncAnnotateFileResponse()];

coerce 'RepeatedAsyncAnnotateFileResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::AsyncAnnotateFileResponse'->new($_) } @$_ ] };

declare 'MapStringAsyncAnnotateFileResponse',
    as HashRef[AsyncAnnotateFileResponse()];

declare 'AsyncBatchAnnotateImagesRequest',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::AsyncBatchAnnotateImagesRequest'];

coerce 'AsyncBatchAnnotateImagesRequest',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::AsyncBatchAnnotateImagesRequest'->new($_) };

declare 'RepeatedAsyncBatchAnnotateImagesRequest',
    as ArrayRef[AsyncBatchAnnotateImagesRequest()];

coerce 'RepeatedAsyncBatchAnnotateImagesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::AsyncBatchAnnotateImagesRequest'->new($_) } @$_ ] };

declare 'MapStringAsyncBatchAnnotateImagesRequest',
    as HashRef[AsyncBatchAnnotateImagesRequest()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::AsyncBatchAnnotateImagesRequest::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::AsyncBatchAnnotateImagesRequest::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::AsyncBatchAnnotateImagesRequest::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AsyncBatchAnnotateImagesResponse',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::AsyncBatchAnnotateImagesResponse'];

coerce 'AsyncBatchAnnotateImagesResponse',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::AsyncBatchAnnotateImagesResponse'->new($_) };

declare 'RepeatedAsyncBatchAnnotateImagesResponse',
    as ArrayRef[AsyncBatchAnnotateImagesResponse()];

coerce 'RepeatedAsyncBatchAnnotateImagesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::AsyncBatchAnnotateImagesResponse'->new($_) } @$_ ] };

declare 'MapStringAsyncBatchAnnotateImagesResponse',
    as HashRef[AsyncBatchAnnotateImagesResponse()];

declare 'AsyncBatchAnnotateFilesRequest',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::AsyncBatchAnnotateFilesRequest'];

coerce 'AsyncBatchAnnotateFilesRequest',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::AsyncBatchAnnotateFilesRequest'->new($_) };

declare 'RepeatedAsyncBatchAnnotateFilesRequest',
    as ArrayRef[AsyncBatchAnnotateFilesRequest()];

coerce 'RepeatedAsyncBatchAnnotateFilesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::AsyncBatchAnnotateFilesRequest'->new($_) } @$_ ] };

declare 'MapStringAsyncBatchAnnotateFilesRequest',
    as HashRef[AsyncBatchAnnotateFilesRequest()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::AsyncBatchAnnotateFilesRequest::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::AsyncBatchAnnotateFilesRequest::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::AsyncBatchAnnotateFilesRequest::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AsyncBatchAnnotateFilesResponse',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::AsyncBatchAnnotateFilesResponse'];

coerce 'AsyncBatchAnnotateFilesResponse',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::AsyncBatchAnnotateFilesResponse'->new($_) };

declare 'RepeatedAsyncBatchAnnotateFilesResponse',
    as ArrayRef[AsyncBatchAnnotateFilesResponse()];

coerce 'RepeatedAsyncBatchAnnotateFilesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::AsyncBatchAnnotateFilesResponse'->new($_) } @$_ ] };

declare 'MapStringAsyncBatchAnnotateFilesResponse',
    as HashRef[AsyncBatchAnnotateFilesResponse()];

declare 'InputConfig',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::InputConfig'];

coerce 'InputConfig',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::InputConfig'->new($_) };

declare 'RepeatedInputConfig',
    as ArrayRef[InputConfig()];

coerce 'RepeatedInputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::InputConfig'->new($_) } @$_ ] };

declare 'MapStringInputConfig',
    as HashRef[InputConfig()];

declare 'OutputConfig',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::OutputConfig'];

coerce 'OutputConfig',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::OutputConfig'->new($_) };

declare 'RepeatedOutputConfig',
    as ArrayRef[OutputConfig()];

coerce 'RepeatedOutputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::OutputConfig'->new($_) } @$_ ] };

declare 'MapStringOutputConfig',
    as HashRef[OutputConfig()];

declare 'GcsSource',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::GcsSource'];

coerce 'GcsSource',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::GcsSource'->new($_) };

declare 'RepeatedGcsSource',
    as ArrayRef[GcsSource()];

coerce 'RepeatedGcsSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::GcsSource'->new($_) } @$_ ] };

declare 'MapStringGcsSource',
    as HashRef[GcsSource()];

declare 'GcsDestination',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::GcsDestination'];

coerce 'GcsDestination',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::GcsDestination'->new($_) };

declare 'RepeatedGcsDestination',
    as ArrayRef[GcsDestination()];

coerce 'RepeatedGcsDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::GcsDestination'->new($_) } @$_ ] };

declare 'MapStringGcsDestination',
    as HashRef[GcsDestination()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Vision::V1::ImageAnnotator::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Vision::V1::ImageAnnotator::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ImageAnnotator::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Vision::V1::ImageAnnotator::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
