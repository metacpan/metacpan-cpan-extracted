package Google::Cloud::Dialogflow::V2beta1::Operations::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GeneratorEvaluationOperationMetadata',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Operations::GeneratorEvaluationOperationMetadata'];

coerce 'GeneratorEvaluationOperationMetadata',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Operations::GeneratorEvaluationOperationMetadata'->new($_) };

declare 'RepeatedGeneratorEvaluationOperationMetadata',
    as ArrayRef[GeneratorEvaluationOperationMetadata()];

coerce 'RepeatedGeneratorEvaluationOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Operations::GeneratorEvaluationOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringGeneratorEvaluationOperationMetadata',
    as HashRef[GeneratorEvaluationOperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::Operations::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
