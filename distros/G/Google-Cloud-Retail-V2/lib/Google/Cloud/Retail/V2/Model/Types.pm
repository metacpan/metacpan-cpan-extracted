package Google::Cloud::Retail::V2::Model::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Model',
    as InstanceOf['Google::Cloud::Retail::V2::Model::Model'];

coerce 'Model',
    from HashRef, via { 'Google::Cloud::Retail::V2::Model::Model'->new($_) };

declare 'RepeatedModel',
    as ArrayRef[Model()];

coerce 'RepeatedModel',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::Model::Model'->new($_) } @$_ ] };

declare 'MapStringModel',
    as HashRef[Model()];

declare 'ServingState',
    as (Int | Str);

declare 'TrainingState',
    as (Int | Str);

declare 'PeriodicTuningState',
    as (Int | Str);

declare 'DataState',
    as (Int | Str);

declare 'ContextProductsType',
    as (Int | Str);

declare 'ServingConfigList',
    as InstanceOf['Google::Cloud::Retail::V2::Model::Model::ServingConfigList'];

coerce 'ServingConfigList',
    from HashRef, via { 'Google::Cloud::Retail::V2::Model::Model::ServingConfigList'->new($_) };

declare 'RepeatedServingConfigList',
    as ArrayRef[ServingConfigList()];

coerce 'RepeatedServingConfigList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::Model::Model::ServingConfigList'->new($_) } @$_ ] };

declare 'MapStringServingConfigList',
    as HashRef[ServingConfigList()];

declare 'FrequentlyBoughtTogetherFeaturesConfig',
    as InstanceOf['Google::Cloud::Retail::V2::Model::Model::FrequentlyBoughtTogetherFeaturesConfig'];

coerce 'FrequentlyBoughtTogetherFeaturesConfig',
    from HashRef, via { 'Google::Cloud::Retail::V2::Model::Model::FrequentlyBoughtTogetherFeaturesConfig'->new($_) };

declare 'RepeatedFrequentlyBoughtTogetherFeaturesConfig',
    as ArrayRef[FrequentlyBoughtTogetherFeaturesConfig()];

coerce 'RepeatedFrequentlyBoughtTogetherFeaturesConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::Model::Model::FrequentlyBoughtTogetherFeaturesConfig'->new($_) } @$_ ] };

declare 'MapStringFrequentlyBoughtTogetherFeaturesConfig',
    as HashRef[FrequentlyBoughtTogetherFeaturesConfig()];

declare 'ModelFeaturesConfig',
    as InstanceOf['Google::Cloud::Retail::V2::Model::Model::ModelFeaturesConfig'];

coerce 'ModelFeaturesConfig',
    from HashRef, via { 'Google::Cloud::Retail::V2::Model::Model::ModelFeaturesConfig'->new($_) };

declare 'RepeatedModelFeaturesConfig',
    as ArrayRef[ModelFeaturesConfig()];

coerce 'RepeatedModelFeaturesConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2::Model::Model::ModelFeaturesConfig'->new($_) } @$_ ] };

declare 'MapStringModelFeaturesConfig',
    as HashRef[ModelFeaturesConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Retail::V2::Model::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
