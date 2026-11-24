package Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::Types;

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
    as InstanceOf['Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::AnnotateVideoRequest'];

coerce 'AnnotateVideoRequest',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::AnnotateVideoRequest'->new($_) };

declare 'RepeatedAnnotateVideoRequest',
    as ArrayRef[AnnotateVideoRequest()];

coerce 'RepeatedAnnotateVideoRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::AnnotateVideoRequest'->new($_) } @$_ ] };

declare 'MapStringAnnotateVideoRequest',
    as HashRef[AnnotateVideoRequest()];

declare 'VideoContext',
    as InstanceOf['Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::VideoContext'];

coerce 'VideoContext',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::VideoContext'->new($_) };

declare 'RepeatedVideoContext',
    as ArrayRef[VideoContext()];

coerce 'RepeatedVideoContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::VideoContext'->new($_) } @$_ ] };

declare 'MapStringVideoContext',
    as HashRef[VideoContext()];

declare 'LabelDetectionConfig',
    as InstanceOf['Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::LabelDetectionConfig'];

coerce 'LabelDetectionConfig',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::LabelDetectionConfig'->new($_) };

declare 'RepeatedLabelDetectionConfig',
    as ArrayRef[LabelDetectionConfig()];

coerce 'RepeatedLabelDetectionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::LabelDetectionConfig'->new($_) } @$_ ] };

declare 'MapStringLabelDetectionConfig',
    as HashRef[LabelDetectionConfig()];

declare 'ShotChangeDetectionConfig',
    as InstanceOf['Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::ShotChangeDetectionConfig'];

coerce 'ShotChangeDetectionConfig',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::ShotChangeDetectionConfig'->new($_) };

declare 'RepeatedShotChangeDetectionConfig',
    as ArrayRef[ShotChangeDetectionConfig()];

coerce 'RepeatedShotChangeDetectionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::ShotChangeDetectionConfig'->new($_) } @$_ ] };

declare 'MapStringShotChangeDetectionConfig',
    as HashRef[ShotChangeDetectionConfig()];

declare 'ExplicitContentDetectionConfig',
    as InstanceOf['Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::ExplicitContentDetectionConfig'];

coerce 'ExplicitContentDetectionConfig',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::ExplicitContentDetectionConfig'->new($_) };

declare 'RepeatedExplicitContentDetectionConfig',
    as ArrayRef[ExplicitContentDetectionConfig()];

coerce 'RepeatedExplicitContentDetectionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::ExplicitContentDetectionConfig'->new($_) } @$_ ] };

declare 'MapStringExplicitContentDetectionConfig',
    as HashRef[ExplicitContentDetectionConfig()];

declare 'FaceDetectionConfig',
    as InstanceOf['Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::FaceDetectionConfig'];

coerce 'FaceDetectionConfig',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::FaceDetectionConfig'->new($_) };

declare 'RepeatedFaceDetectionConfig',
    as ArrayRef[FaceDetectionConfig()];

coerce 'RepeatedFaceDetectionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::FaceDetectionConfig'->new($_) } @$_ ] };

declare 'MapStringFaceDetectionConfig',
    as HashRef[FaceDetectionConfig()];

declare 'VideoSegment',
    as InstanceOf['Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::VideoSegment'];

coerce 'VideoSegment',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::VideoSegment'->new($_) };

declare 'RepeatedVideoSegment',
    as ArrayRef[VideoSegment()];

coerce 'RepeatedVideoSegment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::VideoSegment'->new($_) } @$_ ] };

declare 'MapStringVideoSegment',
    as HashRef[VideoSegment()];

declare 'LabelSegment',
    as InstanceOf['Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::LabelSegment'];

coerce 'LabelSegment',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::LabelSegment'->new($_) };

declare 'RepeatedLabelSegment',
    as ArrayRef[LabelSegment()];

coerce 'RepeatedLabelSegment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::LabelSegment'->new($_) } @$_ ] };

declare 'MapStringLabelSegment',
    as HashRef[LabelSegment()];

declare 'LabelFrame',
    as InstanceOf['Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::LabelFrame'];

coerce 'LabelFrame',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::LabelFrame'->new($_) };

declare 'RepeatedLabelFrame',
    as ArrayRef[LabelFrame()];

coerce 'RepeatedLabelFrame',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::LabelFrame'->new($_) } @$_ ] };

declare 'MapStringLabelFrame',
    as HashRef[LabelFrame()];

declare 'Entity',
    as InstanceOf['Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::Entity'];

coerce 'Entity',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::Entity'->new($_) };

declare 'RepeatedEntity',
    as ArrayRef[Entity()];

coerce 'RepeatedEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::Entity'->new($_) } @$_ ] };

declare 'MapStringEntity',
    as HashRef[Entity()];

declare 'LabelAnnotation',
    as InstanceOf['Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::LabelAnnotation'];

coerce 'LabelAnnotation',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::LabelAnnotation'->new($_) };

declare 'RepeatedLabelAnnotation',
    as ArrayRef[LabelAnnotation()];

coerce 'RepeatedLabelAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::LabelAnnotation'->new($_) } @$_ ] };

declare 'MapStringLabelAnnotation',
    as HashRef[LabelAnnotation()];

declare 'ExplicitContentFrame',
    as InstanceOf['Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::ExplicitContentFrame'];

coerce 'ExplicitContentFrame',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::ExplicitContentFrame'->new($_) };

declare 'RepeatedExplicitContentFrame',
    as ArrayRef[ExplicitContentFrame()];

coerce 'RepeatedExplicitContentFrame',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::ExplicitContentFrame'->new($_) } @$_ ] };

declare 'MapStringExplicitContentFrame',
    as HashRef[ExplicitContentFrame()];

declare 'ExplicitContentAnnotation',
    as InstanceOf['Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::ExplicitContentAnnotation'];

coerce 'ExplicitContentAnnotation',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::ExplicitContentAnnotation'->new($_) };

declare 'RepeatedExplicitContentAnnotation',
    as ArrayRef[ExplicitContentAnnotation()];

coerce 'RepeatedExplicitContentAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::ExplicitContentAnnotation'->new($_) } @$_ ] };

declare 'MapStringExplicitContentAnnotation',
    as HashRef[ExplicitContentAnnotation()];

declare 'NormalizedBoundingBox',
    as InstanceOf['Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::NormalizedBoundingBox'];

coerce 'NormalizedBoundingBox',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::NormalizedBoundingBox'->new($_) };

declare 'RepeatedNormalizedBoundingBox',
    as ArrayRef[NormalizedBoundingBox()];

coerce 'RepeatedNormalizedBoundingBox',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::NormalizedBoundingBox'->new($_) } @$_ ] };

declare 'MapStringNormalizedBoundingBox',
    as HashRef[NormalizedBoundingBox()];

declare 'FaceSegment',
    as InstanceOf['Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::FaceSegment'];

coerce 'FaceSegment',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::FaceSegment'->new($_) };

declare 'RepeatedFaceSegment',
    as ArrayRef[FaceSegment()];

coerce 'RepeatedFaceSegment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::FaceSegment'->new($_) } @$_ ] };

declare 'MapStringFaceSegment',
    as HashRef[FaceSegment()];

declare 'FaceFrame',
    as InstanceOf['Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::FaceFrame'];

coerce 'FaceFrame',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::FaceFrame'->new($_) };

declare 'RepeatedFaceFrame',
    as ArrayRef[FaceFrame()];

coerce 'RepeatedFaceFrame',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::FaceFrame'->new($_) } @$_ ] };

declare 'MapStringFaceFrame',
    as HashRef[FaceFrame()];

declare 'FaceAnnotation',
    as InstanceOf['Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::FaceAnnotation'];

coerce 'FaceAnnotation',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::FaceAnnotation'->new($_) };

declare 'RepeatedFaceAnnotation',
    as ArrayRef[FaceAnnotation()];

coerce 'RepeatedFaceAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::FaceAnnotation'->new($_) } @$_ ] };

declare 'MapStringFaceAnnotation',
    as HashRef[FaceAnnotation()];

declare 'VideoAnnotationResults',
    as InstanceOf['Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::VideoAnnotationResults'];

coerce 'VideoAnnotationResults',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::VideoAnnotationResults'->new($_) };

declare 'RepeatedVideoAnnotationResults',
    as ArrayRef[VideoAnnotationResults()];

coerce 'RepeatedVideoAnnotationResults',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::VideoAnnotationResults'->new($_) } @$_ ] };

declare 'MapStringVideoAnnotationResults',
    as HashRef[VideoAnnotationResults()];

declare 'AnnotateVideoResponse',
    as InstanceOf['Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::AnnotateVideoResponse'];

coerce 'AnnotateVideoResponse',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::AnnotateVideoResponse'->new($_) };

declare 'RepeatedAnnotateVideoResponse',
    as ArrayRef[AnnotateVideoResponse()];

coerce 'RepeatedAnnotateVideoResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::AnnotateVideoResponse'->new($_) } @$_ ] };

declare 'MapStringAnnotateVideoResponse',
    as HashRef[AnnotateVideoResponse()];

declare 'VideoAnnotationProgress',
    as InstanceOf['Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::VideoAnnotationProgress'];

coerce 'VideoAnnotationProgress',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::VideoAnnotationProgress'->new($_) };

declare 'RepeatedVideoAnnotationProgress',
    as ArrayRef[VideoAnnotationProgress()];

coerce 'RepeatedVideoAnnotationProgress',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::VideoAnnotationProgress'->new($_) } @$_ ] };

declare 'MapStringVideoAnnotationProgress',
    as HashRef[VideoAnnotationProgress()];

declare 'AnnotateVideoProgress',
    as InstanceOf['Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::AnnotateVideoProgress'];

coerce 'AnnotateVideoProgress',
    from HashRef, via { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::AnnotateVideoProgress'->new($_) };

declare 'RepeatedAnnotateVideoProgress',
    as ArrayRef[AnnotateVideoProgress()];

coerce 'RepeatedAnnotateVideoProgress',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::AnnotateVideoProgress'->new($_) } @$_ ] };

declare 'MapStringAnnotateVideoProgress',
    as HashRef[AnnotateVideoProgress()];

1;

__END__

=head1 NAME

Google::Cloud::Videointelligence::V1beta2::VideoIntelligence::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
