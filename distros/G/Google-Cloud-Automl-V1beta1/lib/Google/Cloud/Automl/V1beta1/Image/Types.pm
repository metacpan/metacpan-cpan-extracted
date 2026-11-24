package Google::Cloud::Automl::V1beta1::Image::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ImageClassificationDatasetMetadata',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Image::ImageClassificationDatasetMetadata'];

coerce 'ImageClassificationDatasetMetadata',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Image::ImageClassificationDatasetMetadata'->new($_) };

declare 'RepeatedImageClassificationDatasetMetadata',
    as ArrayRef[ImageClassificationDatasetMetadata()];

coerce 'RepeatedImageClassificationDatasetMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Image::ImageClassificationDatasetMetadata'->new($_) } @$_ ] };

declare 'MapStringImageClassificationDatasetMetadata',
    as HashRef[ImageClassificationDatasetMetadata()];

declare 'ImageObjectDetectionDatasetMetadata',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Image::ImageObjectDetectionDatasetMetadata'];

coerce 'ImageObjectDetectionDatasetMetadata',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Image::ImageObjectDetectionDatasetMetadata'->new($_) };

declare 'RepeatedImageObjectDetectionDatasetMetadata',
    as ArrayRef[ImageObjectDetectionDatasetMetadata()];

coerce 'RepeatedImageObjectDetectionDatasetMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Image::ImageObjectDetectionDatasetMetadata'->new($_) } @$_ ] };

declare 'MapStringImageObjectDetectionDatasetMetadata',
    as HashRef[ImageObjectDetectionDatasetMetadata()];

declare 'ImageClassificationModelMetadata',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Image::ImageClassificationModelMetadata'];

coerce 'ImageClassificationModelMetadata',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Image::ImageClassificationModelMetadata'->new($_) };

declare 'RepeatedImageClassificationModelMetadata',
    as ArrayRef[ImageClassificationModelMetadata()];

coerce 'RepeatedImageClassificationModelMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Image::ImageClassificationModelMetadata'->new($_) } @$_ ] };

declare 'MapStringImageClassificationModelMetadata',
    as HashRef[ImageClassificationModelMetadata()];

declare 'ImageObjectDetectionModelMetadata',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Image::ImageObjectDetectionModelMetadata'];

coerce 'ImageObjectDetectionModelMetadata',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Image::ImageObjectDetectionModelMetadata'->new($_) };

declare 'RepeatedImageObjectDetectionModelMetadata',
    as ArrayRef[ImageObjectDetectionModelMetadata()];

coerce 'RepeatedImageObjectDetectionModelMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Image::ImageObjectDetectionModelMetadata'->new($_) } @$_ ] };

declare 'MapStringImageObjectDetectionModelMetadata',
    as HashRef[ImageObjectDetectionModelMetadata()];

declare 'ImageClassificationModelDeploymentMetadata',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Image::ImageClassificationModelDeploymentMetadata'];

coerce 'ImageClassificationModelDeploymentMetadata',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Image::ImageClassificationModelDeploymentMetadata'->new($_) };

declare 'RepeatedImageClassificationModelDeploymentMetadata',
    as ArrayRef[ImageClassificationModelDeploymentMetadata()];

coerce 'RepeatedImageClassificationModelDeploymentMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Image::ImageClassificationModelDeploymentMetadata'->new($_) } @$_ ] };

declare 'MapStringImageClassificationModelDeploymentMetadata',
    as HashRef[ImageClassificationModelDeploymentMetadata()];

declare 'ImageObjectDetectionModelDeploymentMetadata',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Image::ImageObjectDetectionModelDeploymentMetadata'];

coerce 'ImageObjectDetectionModelDeploymentMetadata',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Image::ImageObjectDetectionModelDeploymentMetadata'->new($_) };

declare 'RepeatedImageObjectDetectionModelDeploymentMetadata',
    as ArrayRef[ImageObjectDetectionModelDeploymentMetadata()];

coerce 'RepeatedImageObjectDetectionModelDeploymentMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Image::ImageObjectDetectionModelDeploymentMetadata'->new($_) } @$_ ] };

declare 'MapStringImageObjectDetectionModelDeploymentMetadata',
    as HashRef[ImageObjectDetectionModelDeploymentMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Automl::V1beta1::Image::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
