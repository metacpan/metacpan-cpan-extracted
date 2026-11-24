package Google::Cloud::Visionai::V1alpha1::Annotations::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'StreamAnnotationType',
    as (Int | Str);

declare 'PersonalProtectiveEquipmentDetectionOutput',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::PersonalProtectiveEquipmentDetectionOutput'];

coerce 'PersonalProtectiveEquipmentDetectionOutput',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::PersonalProtectiveEquipmentDetectionOutput'->new($_) };

declare 'RepeatedPersonalProtectiveEquipmentDetectionOutput',
    as ArrayRef[PersonalProtectiveEquipmentDetectionOutput()];

coerce 'RepeatedPersonalProtectiveEquipmentDetectionOutput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::PersonalProtectiveEquipmentDetectionOutput'->new($_) } @$_ ] };

declare 'MapStringPersonalProtectiveEquipmentDetectionOutput',
    as HashRef[PersonalProtectiveEquipmentDetectionOutput()];

declare 'PersonEntity',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::PersonalProtectiveEquipmentDetectionOutput::PersonEntity'];

coerce 'PersonEntity',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::PersonalProtectiveEquipmentDetectionOutput::PersonEntity'->new($_) };

declare 'RepeatedPersonEntity',
    as ArrayRef[PersonEntity()];

coerce 'RepeatedPersonEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::PersonalProtectiveEquipmentDetectionOutput::PersonEntity'->new($_) } @$_ ] };

declare 'MapStringPersonEntity',
    as HashRef[PersonEntity()];

declare 'PPEEntity',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::PersonalProtectiveEquipmentDetectionOutput::PPEEntity'];

coerce 'PPEEntity',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::PersonalProtectiveEquipmentDetectionOutput::PPEEntity'->new($_) };

declare 'RepeatedPPEEntity',
    as ArrayRef[PPEEntity()];

coerce 'RepeatedPPEEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::PersonalProtectiveEquipmentDetectionOutput::PPEEntity'->new($_) } @$_ ] };

declare 'MapStringPPEEntity',
    as HashRef[PPEEntity()];

declare 'NormalizedBoundingBox',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::PersonalProtectiveEquipmentDetectionOutput::NormalizedBoundingBox'];

coerce 'NormalizedBoundingBox',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::PersonalProtectiveEquipmentDetectionOutput::NormalizedBoundingBox'->new($_) };

declare 'RepeatedNormalizedBoundingBox',
    as ArrayRef[NormalizedBoundingBox()];

coerce 'RepeatedNormalizedBoundingBox',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::PersonalProtectiveEquipmentDetectionOutput::NormalizedBoundingBox'->new($_) } @$_ ] };

declare 'MapStringNormalizedBoundingBox',
    as HashRef[NormalizedBoundingBox()];

declare 'PersonIdentifiedBox',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::PersonalProtectiveEquipmentDetectionOutput::PersonIdentifiedBox'];

coerce 'PersonIdentifiedBox',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::PersonalProtectiveEquipmentDetectionOutput::PersonIdentifiedBox'->new($_) };

declare 'RepeatedPersonIdentifiedBox',
    as ArrayRef[PersonIdentifiedBox()];

coerce 'RepeatedPersonIdentifiedBox',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::PersonalProtectiveEquipmentDetectionOutput::PersonIdentifiedBox'->new($_) } @$_ ] };

declare 'MapStringPersonIdentifiedBox',
    as HashRef[PersonIdentifiedBox()];

declare 'PPEIdentifiedBox',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::PersonalProtectiveEquipmentDetectionOutput::PPEIdentifiedBox'];

coerce 'PPEIdentifiedBox',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::PersonalProtectiveEquipmentDetectionOutput::PPEIdentifiedBox'->new($_) };

declare 'RepeatedPPEIdentifiedBox',
    as ArrayRef[PPEIdentifiedBox()];

coerce 'RepeatedPPEIdentifiedBox',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::PersonalProtectiveEquipmentDetectionOutput::PPEIdentifiedBox'->new($_) } @$_ ] };

declare 'MapStringPPEIdentifiedBox',
    as HashRef[PPEIdentifiedBox()];

declare 'DetectedPerson',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::PersonalProtectiveEquipmentDetectionOutput::DetectedPerson'];

coerce 'DetectedPerson',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::PersonalProtectiveEquipmentDetectionOutput::DetectedPerson'->new($_) };

declare 'RepeatedDetectedPerson',
    as ArrayRef[DetectedPerson()];

coerce 'RepeatedDetectedPerson',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::PersonalProtectiveEquipmentDetectionOutput::DetectedPerson'->new($_) } @$_ ] };

declare 'MapStringDetectedPerson',
    as HashRef[DetectedPerson()];

declare 'ObjectDetectionPredictionResult',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::ObjectDetectionPredictionResult'];

coerce 'ObjectDetectionPredictionResult',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::ObjectDetectionPredictionResult'->new($_) };

declare 'RepeatedObjectDetectionPredictionResult',
    as ArrayRef[ObjectDetectionPredictionResult()];

coerce 'RepeatedObjectDetectionPredictionResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::ObjectDetectionPredictionResult'->new($_) } @$_ ] };

declare 'MapStringObjectDetectionPredictionResult',
    as HashRef[ObjectDetectionPredictionResult()];

declare 'Entity',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::ObjectDetectionPredictionResult::Entity'];

coerce 'Entity',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::ObjectDetectionPredictionResult::Entity'->new($_) };

declare 'RepeatedEntity',
    as ArrayRef[Entity()];

coerce 'RepeatedEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::ObjectDetectionPredictionResult::Entity'->new($_) } @$_ ] };

declare 'MapStringEntity',
    as HashRef[Entity()];

declare 'IdentifiedBox',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::ObjectDetectionPredictionResult::IdentifiedBox'];

coerce 'IdentifiedBox',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::ObjectDetectionPredictionResult::IdentifiedBox'->new($_) };

declare 'RepeatedIdentifiedBox',
    as ArrayRef[IdentifiedBox()];

coerce 'RepeatedIdentifiedBox',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::ObjectDetectionPredictionResult::IdentifiedBox'->new($_) } @$_ ] };

declare 'MapStringIdentifiedBox',
    as HashRef[IdentifiedBox()];

declare 'NormalizedBoundingBox',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::ObjectDetectionPredictionResult::IdentifiedBox::NormalizedBoundingBox'];

coerce 'NormalizedBoundingBox',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::ObjectDetectionPredictionResult::IdentifiedBox::NormalizedBoundingBox'->new($_) };

declare 'RepeatedNormalizedBoundingBox',
    as ArrayRef[NormalizedBoundingBox()];

coerce 'RepeatedNormalizedBoundingBox',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::ObjectDetectionPredictionResult::IdentifiedBox::NormalizedBoundingBox'->new($_) } @$_ ] };

declare 'MapStringNormalizedBoundingBox',
    as HashRef[NormalizedBoundingBox()];

declare 'ImageObjectDetectionPredictionResult',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::ImageObjectDetectionPredictionResult'];

coerce 'ImageObjectDetectionPredictionResult',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::ImageObjectDetectionPredictionResult'->new($_) };

declare 'RepeatedImageObjectDetectionPredictionResult',
    as ArrayRef[ImageObjectDetectionPredictionResult()];

coerce 'RepeatedImageObjectDetectionPredictionResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::ImageObjectDetectionPredictionResult'->new($_) } @$_ ] };

declare 'MapStringImageObjectDetectionPredictionResult',
    as HashRef[ImageObjectDetectionPredictionResult()];

declare 'ClassificationPredictionResult',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::ClassificationPredictionResult'];

coerce 'ClassificationPredictionResult',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::ClassificationPredictionResult'->new($_) };

declare 'RepeatedClassificationPredictionResult',
    as ArrayRef[ClassificationPredictionResult()];

coerce 'RepeatedClassificationPredictionResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::ClassificationPredictionResult'->new($_) } @$_ ] };

declare 'MapStringClassificationPredictionResult',
    as HashRef[ClassificationPredictionResult()];

declare 'ImageSegmentationPredictionResult',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::ImageSegmentationPredictionResult'];

coerce 'ImageSegmentationPredictionResult',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::ImageSegmentationPredictionResult'->new($_) };

declare 'RepeatedImageSegmentationPredictionResult',
    as ArrayRef[ImageSegmentationPredictionResult()];

coerce 'RepeatedImageSegmentationPredictionResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::ImageSegmentationPredictionResult'->new($_) } @$_ ] };

declare 'MapStringImageSegmentationPredictionResult',
    as HashRef[ImageSegmentationPredictionResult()];

declare 'VideoActionRecognitionPredictionResult',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::VideoActionRecognitionPredictionResult'];

coerce 'VideoActionRecognitionPredictionResult',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::VideoActionRecognitionPredictionResult'->new($_) };

declare 'RepeatedVideoActionRecognitionPredictionResult',
    as ArrayRef[VideoActionRecognitionPredictionResult()];

coerce 'RepeatedVideoActionRecognitionPredictionResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::VideoActionRecognitionPredictionResult'->new($_) } @$_ ] };

declare 'MapStringVideoActionRecognitionPredictionResult',
    as HashRef[VideoActionRecognitionPredictionResult()];

declare 'IdentifiedAction',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::VideoActionRecognitionPredictionResult::IdentifiedAction'];

coerce 'IdentifiedAction',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::VideoActionRecognitionPredictionResult::IdentifiedAction'->new($_) };

declare 'RepeatedIdentifiedAction',
    as ArrayRef[IdentifiedAction()];

coerce 'RepeatedIdentifiedAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::VideoActionRecognitionPredictionResult::IdentifiedAction'->new($_) } @$_ ] };

declare 'MapStringIdentifiedAction',
    as HashRef[IdentifiedAction()];

declare 'VideoObjectTrackingPredictionResult',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::VideoObjectTrackingPredictionResult'];

coerce 'VideoObjectTrackingPredictionResult',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::VideoObjectTrackingPredictionResult'->new($_) };

declare 'RepeatedVideoObjectTrackingPredictionResult',
    as ArrayRef[VideoObjectTrackingPredictionResult()];

coerce 'RepeatedVideoObjectTrackingPredictionResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::VideoObjectTrackingPredictionResult'->new($_) } @$_ ] };

declare 'MapStringVideoObjectTrackingPredictionResult',
    as HashRef[VideoObjectTrackingPredictionResult()];

declare 'BoundingBox',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::VideoObjectTrackingPredictionResult::BoundingBox'];

coerce 'BoundingBox',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::VideoObjectTrackingPredictionResult::BoundingBox'->new($_) };

declare 'RepeatedBoundingBox',
    as ArrayRef[BoundingBox()];

coerce 'RepeatedBoundingBox',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::VideoObjectTrackingPredictionResult::BoundingBox'->new($_) } @$_ ] };

declare 'MapStringBoundingBox',
    as HashRef[BoundingBox()];

declare 'DetectedObject',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::VideoObjectTrackingPredictionResult::DetectedObject'];

coerce 'DetectedObject',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::VideoObjectTrackingPredictionResult::DetectedObject'->new($_) };

declare 'RepeatedDetectedObject',
    as ArrayRef[DetectedObject()];

coerce 'RepeatedDetectedObject',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::VideoObjectTrackingPredictionResult::DetectedObject'->new($_) } @$_ ] };

declare 'MapStringDetectedObject',
    as HashRef[DetectedObject()];

declare 'VideoClassificationPredictionResult',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::VideoClassificationPredictionResult'];

coerce 'VideoClassificationPredictionResult',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::VideoClassificationPredictionResult'->new($_) };

declare 'RepeatedVideoClassificationPredictionResult',
    as ArrayRef[VideoClassificationPredictionResult()];

coerce 'RepeatedVideoClassificationPredictionResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::VideoClassificationPredictionResult'->new($_) } @$_ ] };

declare 'MapStringVideoClassificationPredictionResult',
    as HashRef[VideoClassificationPredictionResult()];

declare 'IdentifiedClassification',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::VideoClassificationPredictionResult::IdentifiedClassification'];

coerce 'IdentifiedClassification',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::VideoClassificationPredictionResult::IdentifiedClassification'->new($_) };

declare 'RepeatedIdentifiedClassification',
    as ArrayRef[IdentifiedClassification()];

coerce 'RepeatedIdentifiedClassification',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::VideoClassificationPredictionResult::IdentifiedClassification'->new($_) } @$_ ] };

declare 'MapStringIdentifiedClassification',
    as HashRef[IdentifiedClassification()];

declare 'OccupancyCountingPredictionResult',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::OccupancyCountingPredictionResult'];

coerce 'OccupancyCountingPredictionResult',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::OccupancyCountingPredictionResult'->new($_) };

declare 'RepeatedOccupancyCountingPredictionResult',
    as ArrayRef[OccupancyCountingPredictionResult()];

coerce 'RepeatedOccupancyCountingPredictionResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::OccupancyCountingPredictionResult'->new($_) } @$_ ] };

declare 'MapStringOccupancyCountingPredictionResult',
    as HashRef[OccupancyCountingPredictionResult()];

declare 'Entity',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::OccupancyCountingPredictionResult::Entity'];

coerce 'Entity',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::OccupancyCountingPredictionResult::Entity'->new($_) };

declare 'RepeatedEntity',
    as ArrayRef[Entity()];

coerce 'RepeatedEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::OccupancyCountingPredictionResult::Entity'->new($_) } @$_ ] };

declare 'MapStringEntity',
    as HashRef[Entity()];

declare 'IdentifiedBox',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::OccupancyCountingPredictionResult::IdentifiedBox'];

coerce 'IdentifiedBox',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::OccupancyCountingPredictionResult::IdentifiedBox'->new($_) };

declare 'RepeatedIdentifiedBox',
    as ArrayRef[IdentifiedBox()];

coerce 'RepeatedIdentifiedBox',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::OccupancyCountingPredictionResult::IdentifiedBox'->new($_) } @$_ ] };

declare 'MapStringIdentifiedBox',
    as HashRef[IdentifiedBox()];

declare 'NormalizedBoundingBox',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::OccupancyCountingPredictionResult::IdentifiedBox::NormalizedBoundingBox'];

coerce 'NormalizedBoundingBox',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::OccupancyCountingPredictionResult::IdentifiedBox::NormalizedBoundingBox'->new($_) };

declare 'RepeatedNormalizedBoundingBox',
    as ArrayRef[NormalizedBoundingBox()];

coerce 'RepeatedNormalizedBoundingBox',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::OccupancyCountingPredictionResult::IdentifiedBox::NormalizedBoundingBox'->new($_) } @$_ ] };

declare 'MapStringNormalizedBoundingBox',
    as HashRef[NormalizedBoundingBox()];

declare 'Stats',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::OccupancyCountingPredictionResult::Stats'];

coerce 'Stats',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::OccupancyCountingPredictionResult::Stats'->new($_) };

declare 'RepeatedStats',
    as ArrayRef[Stats()];

coerce 'RepeatedStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::OccupancyCountingPredictionResult::Stats'->new($_) } @$_ ] };

declare 'MapStringStats',
    as HashRef[Stats()];

declare 'ObjectCount',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::OccupancyCountingPredictionResult::Stats::ObjectCount'];

coerce 'ObjectCount',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::OccupancyCountingPredictionResult::Stats::ObjectCount'->new($_) };

declare 'RepeatedObjectCount',
    as ArrayRef[ObjectCount()];

coerce 'RepeatedObjectCount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::OccupancyCountingPredictionResult::Stats::ObjectCount'->new($_) } @$_ ] };

declare 'MapStringObjectCount',
    as HashRef[ObjectCount()];

declare 'AccumulatedObjectCount',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::OccupancyCountingPredictionResult::Stats::AccumulatedObjectCount'];

coerce 'AccumulatedObjectCount',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::OccupancyCountingPredictionResult::Stats::AccumulatedObjectCount'->new($_) };

declare 'RepeatedAccumulatedObjectCount',
    as ArrayRef[AccumulatedObjectCount()];

coerce 'RepeatedAccumulatedObjectCount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::OccupancyCountingPredictionResult::Stats::AccumulatedObjectCount'->new($_) } @$_ ] };

declare 'MapStringAccumulatedObjectCount',
    as HashRef[AccumulatedObjectCount()];

declare 'CrossingLineCount',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::OccupancyCountingPredictionResult::Stats::CrossingLineCount'];

coerce 'CrossingLineCount',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::OccupancyCountingPredictionResult::Stats::CrossingLineCount'->new($_) };

declare 'RepeatedCrossingLineCount',
    as ArrayRef[CrossingLineCount()];

coerce 'RepeatedCrossingLineCount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::OccupancyCountingPredictionResult::Stats::CrossingLineCount'->new($_) } @$_ ] };

declare 'MapStringCrossingLineCount',
    as HashRef[CrossingLineCount()];

declare 'ActiveZoneCount',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::OccupancyCountingPredictionResult::Stats::ActiveZoneCount'];

coerce 'ActiveZoneCount',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::OccupancyCountingPredictionResult::Stats::ActiveZoneCount'->new($_) };

declare 'RepeatedActiveZoneCount',
    as ArrayRef[ActiveZoneCount()];

coerce 'RepeatedActiveZoneCount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::OccupancyCountingPredictionResult::Stats::ActiveZoneCount'->new($_) } @$_ ] };

declare 'MapStringActiveZoneCount',
    as HashRef[ActiveZoneCount()];

declare 'TrackInfo',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::OccupancyCountingPredictionResult::TrackInfo'];

coerce 'TrackInfo',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::OccupancyCountingPredictionResult::TrackInfo'->new($_) };

declare 'RepeatedTrackInfo',
    as ArrayRef[TrackInfo()];

coerce 'RepeatedTrackInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::OccupancyCountingPredictionResult::TrackInfo'->new($_) } @$_ ] };

declare 'MapStringTrackInfo',
    as HashRef[TrackInfo()];

declare 'DwellTimeInfo',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::OccupancyCountingPredictionResult::DwellTimeInfo'];

coerce 'DwellTimeInfo',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::OccupancyCountingPredictionResult::DwellTimeInfo'->new($_) };

declare 'RepeatedDwellTimeInfo',
    as ArrayRef[DwellTimeInfo()];

coerce 'RepeatedDwellTimeInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::OccupancyCountingPredictionResult::DwellTimeInfo'->new($_) } @$_ ] };

declare 'MapStringDwellTimeInfo',
    as HashRef[DwellTimeInfo()];

declare 'StreamAnnotation',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::StreamAnnotation'];

coerce 'StreamAnnotation',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::StreamAnnotation'->new($_) };

declare 'RepeatedStreamAnnotation',
    as ArrayRef[StreamAnnotation()];

coerce 'RepeatedStreamAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::StreamAnnotation'->new($_) } @$_ ] };

declare 'MapStringStreamAnnotation',
    as HashRef[StreamAnnotation()];

declare 'StreamAnnotations',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::StreamAnnotations'];

coerce 'StreamAnnotations',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::StreamAnnotations'->new($_) };

declare 'RepeatedStreamAnnotations',
    as ArrayRef[StreamAnnotations()];

coerce 'RepeatedStreamAnnotations',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::StreamAnnotations'->new($_) } @$_ ] };

declare 'MapStringStreamAnnotations',
    as HashRef[StreamAnnotations()];

declare 'NormalizedPolygon',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::NormalizedPolygon'];

coerce 'NormalizedPolygon',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::NormalizedPolygon'->new($_) };

declare 'RepeatedNormalizedPolygon',
    as ArrayRef[NormalizedPolygon()];

coerce 'RepeatedNormalizedPolygon',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::NormalizedPolygon'->new($_) } @$_ ] };

declare 'MapStringNormalizedPolygon',
    as HashRef[NormalizedPolygon()];

declare 'NormalizedPolyline',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::NormalizedPolyline'];

coerce 'NormalizedPolyline',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::NormalizedPolyline'->new($_) };

declare 'RepeatedNormalizedPolyline',
    as ArrayRef[NormalizedPolyline()];

coerce 'RepeatedNormalizedPolyline',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::NormalizedPolyline'->new($_) } @$_ ] };

declare 'MapStringNormalizedPolyline',
    as HashRef[NormalizedPolyline()];

declare 'NormalizedVertex',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::NormalizedVertex'];

coerce 'NormalizedVertex',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::NormalizedVertex'->new($_) };

declare 'RepeatedNormalizedVertex',
    as ArrayRef[NormalizedVertex()];

coerce 'RepeatedNormalizedVertex',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::NormalizedVertex'->new($_) } @$_ ] };

declare 'MapStringNormalizedVertex',
    as HashRef[NormalizedVertex()];

declare 'AppPlatformMetadata',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::AppPlatformMetadata'];

coerce 'AppPlatformMetadata',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::AppPlatformMetadata'->new($_) };

declare 'RepeatedAppPlatformMetadata',
    as ArrayRef[AppPlatformMetadata()];

coerce 'RepeatedAppPlatformMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::AppPlatformMetadata'->new($_) } @$_ ] };

declare 'MapStringAppPlatformMetadata',
    as HashRef[AppPlatformMetadata()];

declare 'AppPlatformCloudFunctionRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::AppPlatformCloudFunctionRequest'];

coerce 'AppPlatformCloudFunctionRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::AppPlatformCloudFunctionRequest'->new($_) };

declare 'RepeatedAppPlatformCloudFunctionRequest',
    as ArrayRef[AppPlatformCloudFunctionRequest()];

coerce 'RepeatedAppPlatformCloudFunctionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::AppPlatformCloudFunctionRequest'->new($_) } @$_ ] };

declare 'MapStringAppPlatformCloudFunctionRequest',
    as HashRef[AppPlatformCloudFunctionRequest()];

declare 'StructedInputAnnotation',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::AppPlatformCloudFunctionRequest::StructedInputAnnotation'];

coerce 'StructedInputAnnotation',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::AppPlatformCloudFunctionRequest::StructedInputAnnotation'->new($_) };

declare 'RepeatedStructedInputAnnotation',
    as ArrayRef[StructedInputAnnotation()];

coerce 'RepeatedStructedInputAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::AppPlatformCloudFunctionRequest::StructedInputAnnotation'->new($_) } @$_ ] };

declare 'MapStringStructedInputAnnotation',
    as HashRef[StructedInputAnnotation()];

declare 'AppPlatformCloudFunctionResponse',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::AppPlatformCloudFunctionResponse'];

coerce 'AppPlatformCloudFunctionResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::AppPlatformCloudFunctionResponse'->new($_) };

declare 'RepeatedAppPlatformCloudFunctionResponse',
    as ArrayRef[AppPlatformCloudFunctionResponse()];

coerce 'RepeatedAppPlatformCloudFunctionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::AppPlatformCloudFunctionResponse'->new($_) } @$_ ] };

declare 'MapStringAppPlatformCloudFunctionResponse',
    as HashRef[AppPlatformCloudFunctionResponse()];

declare 'StructedOutputAnnotation',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::AppPlatformCloudFunctionResponse::StructedOutputAnnotation'];

coerce 'StructedOutputAnnotation',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::AppPlatformCloudFunctionResponse::StructedOutputAnnotation'->new($_) };

declare 'RepeatedStructedOutputAnnotation',
    as ArrayRef[StructedOutputAnnotation()];

coerce 'RepeatedStructedOutputAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::AppPlatformCloudFunctionResponse::StructedOutputAnnotation'->new($_) } @$_ ] };

declare 'MapStringStructedOutputAnnotation',
    as HashRef[StructedOutputAnnotation()];

declare 'AppPlatformEventBody',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::Annotations::AppPlatformEventBody'];

coerce 'AppPlatformEventBody',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::Annotations::AppPlatformEventBody'->new($_) };

declare 'RepeatedAppPlatformEventBody',
    as ArrayRef[AppPlatformEventBody()];

coerce 'RepeatedAppPlatformEventBody',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::Annotations::AppPlatformEventBody'->new($_) } @$_ ] };

declare 'MapStringAppPlatformEventBody',
    as HashRef[AppPlatformEventBody()];

1;

__END__

=head1 NAME

Google::Cloud::Visionai::V1alpha1::Annotations::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
