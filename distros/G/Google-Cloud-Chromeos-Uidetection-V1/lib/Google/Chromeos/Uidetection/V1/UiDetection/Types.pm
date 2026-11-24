package Google::Chromeos::Uidetection::V1::UiDetection::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'UiDetectionRequest',
    as InstanceOf['Google::Chromeos::Uidetection::V1::UiDetection::UiDetectionRequest'];

coerce 'UiDetectionRequest',
    from HashRef, via { 'Google::Chromeos::Uidetection::V1::UiDetection::UiDetectionRequest'->new($_) };

declare 'RepeatedUiDetectionRequest',
    as ArrayRef[UiDetectionRequest()];

coerce 'RepeatedUiDetectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Uidetection::V1::UiDetection::UiDetectionRequest'->new($_) } @$_ ] };

declare 'MapStringUiDetectionRequest',
    as HashRef[UiDetectionRequest()];

declare 'DetectionRequest',
    as InstanceOf['Google::Chromeos::Uidetection::V1::UiDetection::DetectionRequest'];

coerce 'DetectionRequest',
    from HashRef, via { 'Google::Chromeos::Uidetection::V1::UiDetection::DetectionRequest'->new($_) };

declare 'RepeatedDetectionRequest',
    as ArrayRef[DetectionRequest()];

coerce 'RepeatedDetectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Uidetection::V1::UiDetection::DetectionRequest'->new($_) } @$_ ] };

declare 'MapStringDetectionRequest',
    as HashRef[DetectionRequest()];

declare 'TestMetadata',
    as InstanceOf['Google::Chromeos::Uidetection::V1::UiDetection::TestMetadata'];

coerce 'TestMetadata',
    from HashRef, via { 'Google::Chromeos::Uidetection::V1::UiDetection::TestMetadata'->new($_) };

declare 'RepeatedTestMetadata',
    as ArrayRef[TestMetadata()];

coerce 'RepeatedTestMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Uidetection::V1::UiDetection::TestMetadata'->new($_) } @$_ ] };

declare 'MapStringTestMetadata',
    as HashRef[TestMetadata()];

declare 'WordDetectionRequest',
    as InstanceOf['Google::Chromeos::Uidetection::V1::UiDetection::WordDetectionRequest'];

coerce 'WordDetectionRequest',
    from HashRef, via { 'Google::Chromeos::Uidetection::V1::UiDetection::WordDetectionRequest'->new($_) };

declare 'RepeatedWordDetectionRequest',
    as ArrayRef[WordDetectionRequest()];

coerce 'RepeatedWordDetectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Uidetection::V1::UiDetection::WordDetectionRequest'->new($_) } @$_ ] };

declare 'MapStringWordDetectionRequest',
    as HashRef[WordDetectionRequest()];

declare 'TextBlockDetectionRequest',
    as InstanceOf['Google::Chromeos::Uidetection::V1::UiDetection::TextBlockDetectionRequest'];

coerce 'TextBlockDetectionRequest',
    from HashRef, via { 'Google::Chromeos::Uidetection::V1::UiDetection::TextBlockDetectionRequest'->new($_) };

declare 'RepeatedTextBlockDetectionRequest',
    as ArrayRef[TextBlockDetectionRequest()];

coerce 'RepeatedTextBlockDetectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Uidetection::V1::UiDetection::TextBlockDetectionRequest'->new($_) } @$_ ] };

declare 'MapStringTextBlockDetectionRequest',
    as HashRef[TextBlockDetectionRequest()];

declare 'CustomIconDetectionRequest',
    as InstanceOf['Google::Chromeos::Uidetection::V1::UiDetection::CustomIconDetectionRequest'];

coerce 'CustomIconDetectionRequest',
    from HashRef, via { 'Google::Chromeos::Uidetection::V1::UiDetection::CustomIconDetectionRequest'->new($_) };

declare 'RepeatedCustomIconDetectionRequest',
    as ArrayRef[CustomIconDetectionRequest()];

coerce 'RepeatedCustomIconDetectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Uidetection::V1::UiDetection::CustomIconDetectionRequest'->new($_) } @$_ ] };

declare 'MapStringCustomIconDetectionRequest',
    as HashRef[CustomIconDetectionRequest()];

declare 'UiDetectionResponse',
    as InstanceOf['Google::Chromeos::Uidetection::V1::UiDetection::UiDetectionResponse'];

coerce 'UiDetectionResponse',
    from HashRef, via { 'Google::Chromeos::Uidetection::V1::UiDetection::UiDetectionResponse'->new($_) };

declare 'RepeatedUiDetectionResponse',
    as ArrayRef[UiDetectionResponse()];

coerce 'RepeatedUiDetectionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Uidetection::V1::UiDetection::UiDetectionResponse'->new($_) } @$_ ] };

declare 'MapStringUiDetectionResponse',
    as HashRef[UiDetectionResponse()];

declare 'BoundingBox',
    as InstanceOf['Google::Chromeos::Uidetection::V1::UiDetection::BoundingBox'];

coerce 'BoundingBox',
    from HashRef, via { 'Google::Chromeos::Uidetection::V1::UiDetection::BoundingBox'->new($_) };

declare 'RepeatedBoundingBox',
    as ArrayRef[BoundingBox()];

coerce 'RepeatedBoundingBox',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Uidetection::V1::UiDetection::BoundingBox'->new($_) } @$_ ] };

declare 'MapStringBoundingBox',
    as HashRef[BoundingBox()];

1;

__END__

=head1 NAME

Google::Chromeos::Uidetection::V1::UiDetection::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
