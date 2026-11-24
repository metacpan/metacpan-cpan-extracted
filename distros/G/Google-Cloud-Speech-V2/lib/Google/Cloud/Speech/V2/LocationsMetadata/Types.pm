package Google::Cloud::Speech::V2::LocationsMetadata::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ModelFeature',
    as InstanceOf['Google::Cloud::Speech::V2::LocationsMetadata::ModelFeature'];

coerce 'ModelFeature',
    from HashRef, via { 'Google::Cloud::Speech::V2::LocationsMetadata::ModelFeature'->new($_) };

declare 'RepeatedModelFeature',
    as ArrayRef[ModelFeature()];

coerce 'RepeatedModelFeature',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::LocationsMetadata::ModelFeature'->new($_) } @$_ ] };

declare 'MapStringModelFeature',
    as HashRef[ModelFeature()];

declare 'ModelFeatures',
    as InstanceOf['Google::Cloud::Speech::V2::LocationsMetadata::ModelFeatures'];

coerce 'ModelFeatures',
    from HashRef, via { 'Google::Cloud::Speech::V2::LocationsMetadata::ModelFeatures'->new($_) };

declare 'RepeatedModelFeatures',
    as ArrayRef[ModelFeatures()];

coerce 'RepeatedModelFeatures',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::LocationsMetadata::ModelFeatures'->new($_) } @$_ ] };

declare 'MapStringModelFeatures',
    as HashRef[ModelFeatures()];

declare 'ModelMetadata',
    as InstanceOf['Google::Cloud::Speech::V2::LocationsMetadata::ModelMetadata'];

coerce 'ModelMetadata',
    from HashRef, via { 'Google::Cloud::Speech::V2::LocationsMetadata::ModelMetadata'->new($_) };

declare 'RepeatedModelMetadata',
    as ArrayRef[ModelMetadata()];

coerce 'RepeatedModelMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::LocationsMetadata::ModelMetadata'->new($_) } @$_ ] };

declare 'MapStringModelMetadata',
    as HashRef[ModelMetadata()];

declare 'ModelFeaturesEntry',
    as InstanceOf['Google::Cloud::Speech::V2::LocationsMetadata::ModelMetadata::ModelFeaturesEntry'];

coerce 'ModelFeaturesEntry',
    from HashRef, via { 'Google::Cloud::Speech::V2::LocationsMetadata::ModelMetadata::ModelFeaturesEntry'->new($_) };

declare 'RepeatedModelFeaturesEntry',
    as ArrayRef[ModelFeaturesEntry()];

coerce 'RepeatedModelFeaturesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::LocationsMetadata::ModelMetadata::ModelFeaturesEntry'->new($_) } @$_ ] };

declare 'MapStringModelFeaturesEntry',
    as HashRef[ModelFeaturesEntry()];

declare 'LanguageMetadata',
    as InstanceOf['Google::Cloud::Speech::V2::LocationsMetadata::LanguageMetadata'];

coerce 'LanguageMetadata',
    from HashRef, via { 'Google::Cloud::Speech::V2::LocationsMetadata::LanguageMetadata'->new($_) };

declare 'RepeatedLanguageMetadata',
    as ArrayRef[LanguageMetadata()];

coerce 'RepeatedLanguageMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::LocationsMetadata::LanguageMetadata'->new($_) } @$_ ] };

declare 'MapStringLanguageMetadata',
    as HashRef[LanguageMetadata()];

declare 'ModelsEntry',
    as InstanceOf['Google::Cloud::Speech::V2::LocationsMetadata::LanguageMetadata::ModelsEntry'];

coerce 'ModelsEntry',
    from HashRef, via { 'Google::Cloud::Speech::V2::LocationsMetadata::LanguageMetadata::ModelsEntry'->new($_) };

declare 'RepeatedModelsEntry',
    as ArrayRef[ModelsEntry()];

coerce 'RepeatedModelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::LocationsMetadata::LanguageMetadata::ModelsEntry'->new($_) } @$_ ] };

declare 'MapStringModelsEntry',
    as HashRef[ModelsEntry()];

declare 'AccessMetadata',
    as InstanceOf['Google::Cloud::Speech::V2::LocationsMetadata::AccessMetadata'];

coerce 'AccessMetadata',
    from HashRef, via { 'Google::Cloud::Speech::V2::LocationsMetadata::AccessMetadata'->new($_) };

declare 'RepeatedAccessMetadata',
    as ArrayRef[AccessMetadata()];

coerce 'RepeatedAccessMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::LocationsMetadata::AccessMetadata'->new($_) } @$_ ] };

declare 'MapStringAccessMetadata',
    as HashRef[AccessMetadata()];

declare 'ConstraintType',
    as (Int | Str);

declare 'LocationsMetadata',
    as InstanceOf['Google::Cloud::Speech::V2::LocationsMetadata::LocationsMetadata'];

coerce 'LocationsMetadata',
    from HashRef, via { 'Google::Cloud::Speech::V2::LocationsMetadata::LocationsMetadata'->new($_) };

declare 'RepeatedLocationsMetadata',
    as ArrayRef[LocationsMetadata()];

coerce 'RepeatedLocationsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::LocationsMetadata::LocationsMetadata'->new($_) } @$_ ] };

declare 'MapStringLocationsMetadata',
    as HashRef[LocationsMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Speech::V2::LocationsMetadata::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
