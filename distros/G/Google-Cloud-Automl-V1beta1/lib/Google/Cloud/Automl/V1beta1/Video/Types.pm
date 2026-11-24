package Google::Cloud::Automl::V1beta1::Video::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'VideoClassificationDatasetMetadata',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Video::VideoClassificationDatasetMetadata'];

coerce 'VideoClassificationDatasetMetadata',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Video::VideoClassificationDatasetMetadata'->new($_) };

declare 'RepeatedVideoClassificationDatasetMetadata',
    as ArrayRef[VideoClassificationDatasetMetadata()];

coerce 'RepeatedVideoClassificationDatasetMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Video::VideoClassificationDatasetMetadata'->new($_) } @$_ ] };

declare 'MapStringVideoClassificationDatasetMetadata',
    as HashRef[VideoClassificationDatasetMetadata()];

declare 'VideoObjectTrackingDatasetMetadata',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Video::VideoObjectTrackingDatasetMetadata'];

coerce 'VideoObjectTrackingDatasetMetadata',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Video::VideoObjectTrackingDatasetMetadata'->new($_) };

declare 'RepeatedVideoObjectTrackingDatasetMetadata',
    as ArrayRef[VideoObjectTrackingDatasetMetadata()];

coerce 'RepeatedVideoObjectTrackingDatasetMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Video::VideoObjectTrackingDatasetMetadata'->new($_) } @$_ ] };

declare 'MapStringVideoObjectTrackingDatasetMetadata',
    as HashRef[VideoObjectTrackingDatasetMetadata()];

declare 'VideoClassificationModelMetadata',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Video::VideoClassificationModelMetadata'];

coerce 'VideoClassificationModelMetadata',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Video::VideoClassificationModelMetadata'->new($_) };

declare 'RepeatedVideoClassificationModelMetadata',
    as ArrayRef[VideoClassificationModelMetadata()];

coerce 'RepeatedVideoClassificationModelMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Video::VideoClassificationModelMetadata'->new($_) } @$_ ] };

declare 'MapStringVideoClassificationModelMetadata',
    as HashRef[VideoClassificationModelMetadata()];

declare 'VideoObjectTrackingModelMetadata',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Video::VideoObjectTrackingModelMetadata'];

coerce 'VideoObjectTrackingModelMetadata',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Video::VideoObjectTrackingModelMetadata'->new($_) };

declare 'RepeatedVideoObjectTrackingModelMetadata',
    as ArrayRef[VideoObjectTrackingModelMetadata()];

coerce 'RepeatedVideoObjectTrackingModelMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Video::VideoObjectTrackingModelMetadata'->new($_) } @$_ ] };

declare 'MapStringVideoObjectTrackingModelMetadata',
    as HashRef[VideoObjectTrackingModelMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Automl::V1beta1::Video::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
