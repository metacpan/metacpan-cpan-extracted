package Google::Ai::Generativelanguage::V1alpha::TunedModel::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TunedModel',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::TunedModel::TunedModel'];

coerce 'TunedModel',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::TunedModel::TunedModel'->new($_) };

declare 'RepeatedTunedModel',
    as ArrayRef[TunedModel()];

coerce 'RepeatedTunedModel',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::TunedModel::TunedModel'->new($_) } @$_ ] };

declare 'MapStringTunedModel',
    as HashRef[TunedModel()];

declare 'State',
    as (Int | Str);

declare 'TunedModelSource',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::TunedModel::TunedModelSource'];

coerce 'TunedModelSource',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::TunedModel::TunedModelSource'->new($_) };

declare 'RepeatedTunedModelSource',
    as ArrayRef[TunedModelSource()];

coerce 'RepeatedTunedModelSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::TunedModel::TunedModelSource'->new($_) } @$_ ] };

declare 'MapStringTunedModelSource',
    as HashRef[TunedModelSource()];

declare 'TuningTask',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningTask'];

coerce 'TuningTask',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningTask'->new($_) };

declare 'RepeatedTuningTask',
    as ArrayRef[TuningTask()];

coerce 'RepeatedTuningTask',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningTask'->new($_) } @$_ ] };

declare 'MapStringTuningTask',
    as HashRef[TuningTask()];

declare 'Hyperparameters',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::TunedModel::Hyperparameters'];

coerce 'Hyperparameters',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::TunedModel::Hyperparameters'->new($_) };

declare 'RepeatedHyperparameters',
    as ArrayRef[Hyperparameters()];

coerce 'RepeatedHyperparameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::TunedModel::Hyperparameters'->new($_) } @$_ ] };

declare 'MapStringHyperparameters',
    as HashRef[Hyperparameters()];

declare 'Dataset',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::TunedModel::Dataset'];

coerce 'Dataset',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::TunedModel::Dataset'->new($_) };

declare 'RepeatedDataset',
    as ArrayRef[Dataset()];

coerce 'RepeatedDataset',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::TunedModel::Dataset'->new($_) } @$_ ] };

declare 'MapStringDataset',
    as HashRef[Dataset()];

declare 'TuningExamples',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningExamples'];

coerce 'TuningExamples',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningExamples'->new($_) };

declare 'RepeatedTuningExamples',
    as ArrayRef[TuningExamples()];

coerce 'RepeatedTuningExamples',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningExamples'->new($_) } @$_ ] };

declare 'MapStringTuningExamples',
    as HashRef[TuningExamples()];

declare 'TuningPart',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningPart'];

coerce 'TuningPart',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningPart'->new($_) };

declare 'RepeatedTuningPart',
    as ArrayRef[TuningPart()];

coerce 'RepeatedTuningPart',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningPart'->new($_) } @$_ ] };

declare 'MapStringTuningPart',
    as HashRef[TuningPart()];

declare 'TuningContent',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningContent'];

coerce 'TuningContent',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningContent'->new($_) };

declare 'RepeatedTuningContent',
    as ArrayRef[TuningContent()];

coerce 'RepeatedTuningContent',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningContent'->new($_) } @$_ ] };

declare 'MapStringTuningContent',
    as HashRef[TuningContent()];

declare 'TuningMultiturnExample',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningMultiturnExample'];

coerce 'TuningMultiturnExample',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningMultiturnExample'->new($_) };

declare 'RepeatedTuningMultiturnExample',
    as ArrayRef[TuningMultiturnExample()];

coerce 'RepeatedTuningMultiturnExample',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningMultiturnExample'->new($_) } @$_ ] };

declare 'MapStringTuningMultiturnExample',
    as HashRef[TuningMultiturnExample()];

declare 'TuningExample',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningExample'];

coerce 'TuningExample',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningExample'->new($_) };

declare 'RepeatedTuningExample',
    as ArrayRef[TuningExample()];

coerce 'RepeatedTuningExample',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningExample'->new($_) } @$_ ] };

declare 'MapStringTuningExample',
    as HashRef[TuningExample()];

declare 'TuningSnapshot',
    as InstanceOf['Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningSnapshot'];

coerce 'TuningSnapshot',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningSnapshot'->new($_) };

declare 'RepeatedTuningSnapshot',
    as ArrayRef[TuningSnapshot()];

coerce 'RepeatedTuningSnapshot',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1alpha::TunedModel::TuningSnapshot'->new($_) } @$_ ] };

declare 'MapStringTuningSnapshot',
    as HashRef[TuningSnapshot()];

1;

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1alpha::TunedModel::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
