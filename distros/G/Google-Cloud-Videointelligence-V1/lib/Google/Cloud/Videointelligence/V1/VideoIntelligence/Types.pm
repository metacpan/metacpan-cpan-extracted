package Google::Cloud::Videointelligence::V1::VideoIntelligence::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Feature',
    as (Int | Str);

declare 'LabelDetectionMode',
    as (Int | Str);

declare 'Likelihood',
    as (Int | Str);

declare 'AnnotateVideoRequest',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::AnnotateVideoRequest'];

coerce 'AnnotateVideoRequest',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::AnnotateVideoRequest'->new($_) };

declare 'RepeatedAnnotateVideoRequest',
    as ArrayRef[AnnotateVideoRequest()];

coerce 'RepeatedAnnotateVideoRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::AnnotateVideoRequest'->new($_) } @$_ ] };

declare 'MapStringAnnotateVideoRequest',
    as HashRef[AnnotateVideoRequest()];

declare 'VideoContext',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::VideoContext'];

coerce 'VideoContext',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::VideoContext'->new($_) };

declare 'RepeatedVideoContext',
    as ArrayRef[VideoContext()];

coerce 'RepeatedVideoContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::VideoContext'->new($_) } @$_ ] };

declare 'MapStringVideoContext',
    as HashRef[VideoContext()];

declare 'LabelDetectionConfig',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::LabelDetectionConfig'];

coerce 'LabelDetectionConfig',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::LabelDetectionConfig'->new($_) };

declare 'RepeatedLabelDetectionConfig',
    as ArrayRef[LabelDetectionConfig()];

coerce 'RepeatedLabelDetectionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::LabelDetectionConfig'->new($_) } @$_ ] };

declare 'MapStringLabelDetectionConfig',
    as HashRef[LabelDetectionConfig()];

declare 'ShotChangeDetectionConfig',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::ShotChangeDetectionConfig'];

coerce 'ShotChangeDetectionConfig',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::ShotChangeDetectionConfig'->new($_) };

declare 'RepeatedShotChangeDetectionConfig',
    as ArrayRef[ShotChangeDetectionConfig()];

coerce 'RepeatedShotChangeDetectionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::ShotChangeDetectionConfig'->new($_) } @$_ ] };

declare 'MapStringShotChangeDetectionConfig',
    as HashRef[ShotChangeDetectionConfig()];

declare 'ObjectTrackingConfig',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::ObjectTrackingConfig'];

coerce 'ObjectTrackingConfig',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::ObjectTrackingConfig'->new($_) };

declare 'RepeatedObjectTrackingConfig',
    as ArrayRef[ObjectTrackingConfig()];

coerce 'RepeatedObjectTrackingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::ObjectTrackingConfig'->new($_) } @$_ ] };

declare 'MapStringObjectTrackingConfig',
    as HashRef[ObjectTrackingConfig()];

declare 'FaceDetectionConfig',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::FaceDetectionConfig'];

coerce 'FaceDetectionConfig',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::FaceDetectionConfig'->new($_) };

declare 'RepeatedFaceDetectionConfig',
    as ArrayRef[FaceDetectionConfig()];

coerce 'RepeatedFaceDetectionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::FaceDetectionConfig'->new($_) } @$_ ] };

declare 'MapStringFaceDetectionConfig',
    as HashRef[FaceDetectionConfig()];

declare 'PersonDetectionConfig',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::PersonDetectionConfig'];

coerce 'PersonDetectionConfig',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::PersonDetectionConfig'->new($_) };

declare 'RepeatedPersonDetectionConfig',
    as ArrayRef[PersonDetectionConfig()];

coerce 'RepeatedPersonDetectionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::PersonDetectionConfig'->new($_) } @$_ ] };

declare 'MapStringPersonDetectionConfig',
    as HashRef[PersonDetectionConfig()];

declare 'ExplicitContentDetectionConfig',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::ExplicitContentDetectionConfig'];

coerce 'ExplicitContentDetectionConfig',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::ExplicitContentDetectionConfig'->new($_) };

declare 'RepeatedExplicitContentDetectionConfig',
    as ArrayRef[ExplicitContentDetectionConfig()];

coerce 'RepeatedExplicitContentDetectionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::ExplicitContentDetectionConfig'->new($_) } @$_ ] };

declare 'MapStringExplicitContentDetectionConfig',
    as HashRef[ExplicitContentDetectionConfig()];

declare 'TextDetectionConfig',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::TextDetectionConfig'];

coerce 'TextDetectionConfig',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::TextDetectionConfig'->new($_) };

declare 'RepeatedTextDetectionConfig',
    as ArrayRef[TextDetectionConfig()];

coerce 'RepeatedTextDetectionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::TextDetectionConfig'->new($_) } @$_ ] };

declare 'MapStringTextDetectionConfig',
    as HashRef[TextDetectionConfig()];

declare 'VideoSegment',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::VideoSegment'];

coerce 'VideoSegment',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::VideoSegment'->new($_) };

declare 'RepeatedVideoSegment',
    as ArrayRef[VideoSegment()];

coerce 'RepeatedVideoSegment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::VideoSegment'->new($_) } @$_ ] };

declare 'MapStringVideoSegment',
    as HashRef[VideoSegment()];

declare 'LabelSegment',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::LabelSegment'];

coerce 'LabelSegment',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::LabelSegment'->new($_) };

declare 'RepeatedLabelSegment',
    as ArrayRef[LabelSegment()];

coerce 'RepeatedLabelSegment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::LabelSegment'->new($_) } @$_ ] };

declare 'MapStringLabelSegment',
    as HashRef[LabelSegment()];

declare 'LabelFrame',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::LabelFrame'];

coerce 'LabelFrame',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::LabelFrame'->new($_) };

declare 'RepeatedLabelFrame',
    as ArrayRef[LabelFrame()];

coerce 'RepeatedLabelFrame',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::LabelFrame'->new($_) } @$_ ] };

declare 'MapStringLabelFrame',
    as HashRef[LabelFrame()];

declare 'Entity',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::Entity'];

coerce 'Entity',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::Entity'->new($_) };

declare 'RepeatedEntity',
    as ArrayRef[Entity()];

coerce 'RepeatedEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::Entity'->new($_) } @$_ ] };

declare 'MapStringEntity',
    as HashRef[Entity()];

declare 'LabelAnnotation',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::LabelAnnotation'];

coerce 'LabelAnnotation',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::LabelAnnotation'->new($_) };

declare 'RepeatedLabelAnnotation',
    as ArrayRef[LabelAnnotation()];

coerce 'RepeatedLabelAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::LabelAnnotation'->new($_) } @$_ ] };

declare 'MapStringLabelAnnotation',
    as HashRef[LabelAnnotation()];

declare 'ExplicitContentFrame',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::ExplicitContentFrame'];

coerce 'ExplicitContentFrame',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::ExplicitContentFrame'->new($_) };

declare 'RepeatedExplicitContentFrame',
    as ArrayRef[ExplicitContentFrame()];

coerce 'RepeatedExplicitContentFrame',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::ExplicitContentFrame'->new($_) } @$_ ] };

declare 'MapStringExplicitContentFrame',
    as HashRef[ExplicitContentFrame()];

declare 'ExplicitContentAnnotation',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::ExplicitContentAnnotation'];

coerce 'ExplicitContentAnnotation',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::ExplicitContentAnnotation'->new($_) };

declare 'RepeatedExplicitContentAnnotation',
    as ArrayRef[ExplicitContentAnnotation()];

coerce 'RepeatedExplicitContentAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::ExplicitContentAnnotation'->new($_) } @$_ ] };

declare 'MapStringExplicitContentAnnotation',
    as HashRef[ExplicitContentAnnotation()];

declare 'NormalizedBoundingBox',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::NormalizedBoundingBox'];

coerce 'NormalizedBoundingBox',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::NormalizedBoundingBox'->new($_) };

declare 'RepeatedNormalizedBoundingBox',
    as ArrayRef[NormalizedBoundingBox()];

coerce 'RepeatedNormalizedBoundingBox',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::NormalizedBoundingBox'->new($_) } @$_ ] };

declare 'MapStringNormalizedBoundingBox',
    as HashRef[NormalizedBoundingBox()];

declare 'FaceDetectionAnnotation',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::FaceDetectionAnnotation'];

coerce 'FaceDetectionAnnotation',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::FaceDetectionAnnotation'->new($_) };

declare 'RepeatedFaceDetectionAnnotation',
    as ArrayRef[FaceDetectionAnnotation()];

coerce 'RepeatedFaceDetectionAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::FaceDetectionAnnotation'->new($_) } @$_ ] };

declare 'MapStringFaceDetectionAnnotation',
    as HashRef[FaceDetectionAnnotation()];

declare 'PersonDetectionAnnotation',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::PersonDetectionAnnotation'];

coerce 'PersonDetectionAnnotation',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::PersonDetectionAnnotation'->new($_) };

declare 'RepeatedPersonDetectionAnnotation',
    as ArrayRef[PersonDetectionAnnotation()];

coerce 'RepeatedPersonDetectionAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::PersonDetectionAnnotation'->new($_) } @$_ ] };

declare 'MapStringPersonDetectionAnnotation',
    as HashRef[PersonDetectionAnnotation()];

declare 'FaceSegment',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::FaceSegment'];

coerce 'FaceSegment',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::FaceSegment'->new($_) };

declare 'RepeatedFaceSegment',
    as ArrayRef[FaceSegment()];

coerce 'RepeatedFaceSegment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::FaceSegment'->new($_) } @$_ ] };

declare 'MapStringFaceSegment',
    as HashRef[FaceSegment()];

declare 'FaceFrame',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::FaceFrame'];

coerce 'FaceFrame',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::FaceFrame'->new($_) };

declare 'RepeatedFaceFrame',
    as ArrayRef[FaceFrame()];

coerce 'RepeatedFaceFrame',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::FaceFrame'->new($_) } @$_ ] };

declare 'MapStringFaceFrame',
    as HashRef[FaceFrame()];

declare 'FaceAnnotation',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::FaceAnnotation'];

coerce 'FaceAnnotation',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::FaceAnnotation'->new($_) };

declare 'RepeatedFaceAnnotation',
    as ArrayRef[FaceAnnotation()];

coerce 'RepeatedFaceAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::FaceAnnotation'->new($_) } @$_ ] };

declare 'MapStringFaceAnnotation',
    as HashRef[FaceAnnotation()];

declare 'TimestampedObject',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::TimestampedObject'];

coerce 'TimestampedObject',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::TimestampedObject'->new($_) };

declare 'RepeatedTimestampedObject',
    as ArrayRef[TimestampedObject()];

coerce 'RepeatedTimestampedObject',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::TimestampedObject'->new($_) } @$_ ] };

declare 'MapStringTimestampedObject',
    as HashRef[TimestampedObject()];

declare 'Track',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::Track'];

coerce 'Track',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::Track'->new($_) };

declare 'RepeatedTrack',
    as ArrayRef[Track()];

coerce 'RepeatedTrack',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::Track'->new($_) } @$_ ] };

declare 'MapStringTrack',
    as HashRef[Track()];

declare 'DetectedAttribute',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::DetectedAttribute'];

coerce 'DetectedAttribute',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::DetectedAttribute'->new($_) };

declare 'RepeatedDetectedAttribute',
    as ArrayRef[DetectedAttribute()];

coerce 'RepeatedDetectedAttribute',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::DetectedAttribute'->new($_) } @$_ ] };

declare 'MapStringDetectedAttribute',
    as HashRef[DetectedAttribute()];

declare 'DetectedLandmark',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::DetectedLandmark'];

coerce 'DetectedLandmark',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::DetectedLandmark'->new($_) };

declare 'RepeatedDetectedLandmark',
    as ArrayRef[DetectedLandmark()];

coerce 'RepeatedDetectedLandmark',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::DetectedLandmark'->new($_) } @$_ ] };

declare 'MapStringDetectedLandmark',
    as HashRef[DetectedLandmark()];

declare 'VideoAnnotationResults',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::VideoAnnotationResults'];

coerce 'VideoAnnotationResults',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::VideoAnnotationResults'->new($_) };

declare 'RepeatedVideoAnnotationResults',
    as ArrayRef[VideoAnnotationResults()];

coerce 'RepeatedVideoAnnotationResults',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::VideoAnnotationResults'->new($_) } @$_ ] };

declare 'MapStringVideoAnnotationResults',
    as HashRef[VideoAnnotationResults()];

declare 'AnnotateVideoResponse',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::AnnotateVideoResponse'];

coerce 'AnnotateVideoResponse',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::AnnotateVideoResponse'->new($_) };

declare 'RepeatedAnnotateVideoResponse',
    as ArrayRef[AnnotateVideoResponse()];

coerce 'RepeatedAnnotateVideoResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::AnnotateVideoResponse'->new($_) } @$_ ] };

declare 'MapStringAnnotateVideoResponse',
    as HashRef[AnnotateVideoResponse()];

declare 'VideoAnnotationProgress',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::VideoAnnotationProgress'];

coerce 'VideoAnnotationProgress',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::VideoAnnotationProgress'->new($_) };

declare 'RepeatedVideoAnnotationProgress',
    as ArrayRef[VideoAnnotationProgress()];

coerce 'RepeatedVideoAnnotationProgress',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::VideoAnnotationProgress'->new($_) } @$_ ] };

declare 'MapStringVideoAnnotationProgress',
    as HashRef[VideoAnnotationProgress()];

declare 'AnnotateVideoProgress',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::AnnotateVideoProgress'];

coerce 'AnnotateVideoProgress',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::AnnotateVideoProgress'->new($_) };

declare 'RepeatedAnnotateVideoProgress',
    as ArrayRef[AnnotateVideoProgress()];

coerce 'RepeatedAnnotateVideoProgress',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::AnnotateVideoProgress'->new($_) } @$_ ] };

declare 'MapStringAnnotateVideoProgress',
    as HashRef[AnnotateVideoProgress()];

declare 'SpeechTranscriptionConfig',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::SpeechTranscriptionConfig'];

coerce 'SpeechTranscriptionConfig',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::SpeechTranscriptionConfig'->new($_) };

declare 'RepeatedSpeechTranscriptionConfig',
    as ArrayRef[SpeechTranscriptionConfig()];

coerce 'RepeatedSpeechTranscriptionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::SpeechTranscriptionConfig'->new($_) } @$_ ] };

declare 'MapStringSpeechTranscriptionConfig',
    as HashRef[SpeechTranscriptionConfig()];

declare 'SpeechContext',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::SpeechContext'];

coerce 'SpeechContext',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::SpeechContext'->new($_) };

declare 'RepeatedSpeechContext',
    as ArrayRef[SpeechContext()];

coerce 'RepeatedSpeechContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::SpeechContext'->new($_) } @$_ ] };

declare 'MapStringSpeechContext',
    as HashRef[SpeechContext()];

declare 'SpeechTranscription',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::SpeechTranscription'];

coerce 'SpeechTranscription',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::SpeechTranscription'->new($_) };

declare 'RepeatedSpeechTranscription',
    as ArrayRef[SpeechTranscription()];

coerce 'RepeatedSpeechTranscription',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::SpeechTranscription'->new($_) } @$_ ] };

declare 'MapStringSpeechTranscription',
    as HashRef[SpeechTranscription()];

declare 'SpeechRecognitionAlternative',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::SpeechRecognitionAlternative'];

coerce 'SpeechRecognitionAlternative',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::SpeechRecognitionAlternative'->new($_) };

declare 'RepeatedSpeechRecognitionAlternative',
    as ArrayRef[SpeechRecognitionAlternative()];

coerce 'RepeatedSpeechRecognitionAlternative',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::SpeechRecognitionAlternative'->new($_) } @$_ ] };

declare 'MapStringSpeechRecognitionAlternative',
    as HashRef[SpeechRecognitionAlternative()];

declare 'WordInfo',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::WordInfo'];

coerce 'WordInfo',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::WordInfo'->new($_) };

declare 'RepeatedWordInfo',
    as ArrayRef[WordInfo()];

coerce 'RepeatedWordInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::WordInfo'->new($_) } @$_ ] };

declare 'MapStringWordInfo',
    as HashRef[WordInfo()];

declare 'NormalizedVertex',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::NormalizedVertex'];

coerce 'NormalizedVertex',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::NormalizedVertex'->new($_) };

declare 'RepeatedNormalizedVertex',
    as ArrayRef[NormalizedVertex()];

coerce 'RepeatedNormalizedVertex',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::NormalizedVertex'->new($_) } @$_ ] };

declare 'MapStringNormalizedVertex',
    as HashRef[NormalizedVertex()];

declare 'NormalizedBoundingPoly',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::NormalizedBoundingPoly'];

coerce 'NormalizedBoundingPoly',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::NormalizedBoundingPoly'->new($_) };

declare 'RepeatedNormalizedBoundingPoly',
    as ArrayRef[NormalizedBoundingPoly()];

coerce 'RepeatedNormalizedBoundingPoly',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::NormalizedBoundingPoly'->new($_) } @$_ ] };

declare 'MapStringNormalizedBoundingPoly',
    as HashRef[NormalizedBoundingPoly()];

declare 'TextSegment',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::TextSegment'];

coerce 'TextSegment',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::TextSegment'->new($_) };

declare 'RepeatedTextSegment',
    as ArrayRef[TextSegment()];

coerce 'RepeatedTextSegment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::TextSegment'->new($_) } @$_ ] };

declare 'MapStringTextSegment',
    as HashRef[TextSegment()];

declare 'TextFrame',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::TextFrame'];

coerce 'TextFrame',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::TextFrame'->new($_) };

declare 'RepeatedTextFrame',
    as ArrayRef[TextFrame()];

coerce 'RepeatedTextFrame',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::TextFrame'->new($_) } @$_ ] };

declare 'MapStringTextFrame',
    as HashRef[TextFrame()];

declare 'TextAnnotation',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::TextAnnotation'];

coerce 'TextAnnotation',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::TextAnnotation'->new($_) };

declare 'RepeatedTextAnnotation',
    as ArrayRef[TextAnnotation()];

coerce 'RepeatedTextAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::TextAnnotation'->new($_) } @$_ ] };

declare 'MapStringTextAnnotation',
    as HashRef[TextAnnotation()];

declare 'ObjectTrackingFrame',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::ObjectTrackingFrame'];

coerce 'ObjectTrackingFrame',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::ObjectTrackingFrame'->new($_) };

declare 'RepeatedObjectTrackingFrame',
    as ArrayRef[ObjectTrackingFrame()];

coerce 'RepeatedObjectTrackingFrame',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::ObjectTrackingFrame'->new($_) } @$_ ] };

declare 'MapStringObjectTrackingFrame',
    as HashRef[ObjectTrackingFrame()];

declare 'ObjectTrackingAnnotation',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::ObjectTrackingAnnotation'];

coerce 'ObjectTrackingAnnotation',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::ObjectTrackingAnnotation'->new($_) };

declare 'RepeatedObjectTrackingAnnotation',
    as ArrayRef[ObjectTrackingAnnotation()];

coerce 'RepeatedObjectTrackingAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::ObjectTrackingAnnotation'->new($_) } @$_ ] };

declare 'MapStringObjectTrackingAnnotation',
    as HashRef[ObjectTrackingAnnotation()];

declare 'LogoRecognitionAnnotation',
    as InstanceOf['Google::Cloud::Videointelligence::V1::VideoIntelligence::LogoRecognitionAnnotation'];

coerce 'LogoRecognitionAnnotation',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::LogoRecognitionAnnotation'->new($_) };

declare 'RepeatedLogoRecognitionAnnotation',
    as ArrayRef[LogoRecognitionAnnotation()];

coerce 'RepeatedLogoRecognitionAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1::VideoIntelligence::LogoRecognitionAnnotation'->new($_) } @$_ ] };

declare 'MapStringLogoRecognitionAnnotation',
    as HashRef[LogoRecognitionAnnotation()];

1;

__END__

=head1 NAME

Google::Cloud::Videointelligence::V1::VideoIntelligence::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
