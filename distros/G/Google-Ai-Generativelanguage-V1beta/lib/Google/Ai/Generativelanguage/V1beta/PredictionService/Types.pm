package Google::Ai::Generativelanguage::V1beta::PredictionService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PredictRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::PredictionService::PredictRequest'];

coerce 'PredictRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::PredictionService::PredictRequest'->new($_) };

declare 'RepeatedPredictRequest',
    as ArrayRef[PredictRequest()];

coerce 'RepeatedPredictRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::PredictionService::PredictRequest'->new($_) } @$_ ] };

declare 'MapStringPredictRequest',
    as HashRef[PredictRequest()];

declare 'PredictLongRunningRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::PredictionService::PredictLongRunningRequest'];

coerce 'PredictLongRunningRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::PredictionService::PredictLongRunningRequest'->new($_) };

declare 'RepeatedPredictLongRunningRequest',
    as ArrayRef[PredictLongRunningRequest()];

coerce 'RepeatedPredictLongRunningRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::PredictionService::PredictLongRunningRequest'->new($_) } @$_ ] };

declare 'MapStringPredictLongRunningRequest',
    as HashRef[PredictLongRunningRequest()];

declare 'PredictResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::PredictionService::PredictResponse'];

coerce 'PredictResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::PredictionService::PredictResponse'->new($_) };

declare 'RepeatedPredictResponse',
    as ArrayRef[PredictResponse()];

coerce 'RepeatedPredictResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::PredictionService::PredictResponse'->new($_) } @$_ ] };

declare 'MapStringPredictResponse',
    as HashRef[PredictResponse()];

declare 'PredictLongRunningResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::PredictionService::PredictLongRunningResponse'];

coerce 'PredictLongRunningResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::PredictionService::PredictLongRunningResponse'->new($_) };

declare 'RepeatedPredictLongRunningResponse',
    as ArrayRef[PredictLongRunningResponse()];

coerce 'RepeatedPredictLongRunningResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::PredictionService::PredictLongRunningResponse'->new($_) } @$_ ] };

declare 'MapStringPredictLongRunningResponse',
    as HashRef[PredictLongRunningResponse()];

declare 'PredictLongRunningMetadata',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::PredictionService::PredictLongRunningMetadata'];

coerce 'PredictLongRunningMetadata',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::PredictionService::PredictLongRunningMetadata'->new($_) };

declare 'RepeatedPredictLongRunningMetadata',
    as ArrayRef[PredictLongRunningMetadata()];

coerce 'RepeatedPredictLongRunningMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::PredictionService::PredictLongRunningMetadata'->new($_) } @$_ ] };

declare 'MapStringPredictLongRunningMetadata',
    as HashRef[PredictLongRunningMetadata()];

declare 'Media',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::PredictionService::Media'];

coerce 'Media',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::PredictionService::Media'->new($_) };

declare 'RepeatedMedia',
    as ArrayRef[Media()];

coerce 'RepeatedMedia',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::PredictionService::Media'->new($_) } @$_ ] };

declare 'MapStringMedia',
    as HashRef[Media()];

declare 'Video',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::PredictionService::Video'];

coerce 'Video',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::PredictionService::Video'->new($_) };

declare 'RepeatedVideo',
    as ArrayRef[Video()];

coerce 'RepeatedVideo',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::PredictionService::Video'->new($_) } @$_ ] };

declare 'MapStringVideo',
    as HashRef[Video()];

declare 'PredictLongRunningGeneratedVideoResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::PredictionService::PredictLongRunningGeneratedVideoResponse'];

coerce 'PredictLongRunningGeneratedVideoResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::PredictionService::PredictLongRunningGeneratedVideoResponse'->new($_) };

declare 'RepeatedPredictLongRunningGeneratedVideoResponse',
    as ArrayRef[PredictLongRunningGeneratedVideoResponse()];

coerce 'RepeatedPredictLongRunningGeneratedVideoResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::PredictionService::PredictLongRunningGeneratedVideoResponse'->new($_) } @$_ ] };

declare 'MapStringPredictLongRunningGeneratedVideoResponse',
    as HashRef[PredictLongRunningGeneratedVideoResponse()];

1;

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1beta::PredictionService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
