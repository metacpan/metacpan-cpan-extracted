package Google::Ai::Generativelanguage::V1alpha::PredictionService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PredictRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::PredictionService::PredictRequest'];

coerce 'PredictRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::PredictionService::PredictRequest'->new($_) };

declare 'RepeatedPredictRequest',
    as ArrayRef[PredictRequest()];

coerce 'RepeatedPredictRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::PredictionService::PredictRequest'->new($_) } @$_ ] };

declare 'MapStringPredictRequest',
    as HashRef[PredictRequest()];

declare 'PredictResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::PredictionService::PredictResponse'];

coerce 'PredictResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::PredictionService::PredictResponse'->new($_) };

declare 'RepeatedPredictResponse',
    as ArrayRef[PredictResponse()];

coerce 'RepeatedPredictResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::PredictionService::PredictResponse'->new($_) } @$_ ] };

declare 'MapStringPredictResponse',
    as HashRef[PredictResponse()];

1;

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1alpha::PredictionService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
