package Grafeas::V1::IntotoProvenance::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Recipe',
    as InstanceOf['Grafeas::V1::IntotoProvenance::Recipe'];

coerce 'Recipe',
    from HashRef, via { 'Grafeas::V1::IntotoProvenance::Recipe'->new($_) };

declare 'RepeatedRecipe',
    as ArrayRef[Recipe()];

coerce 'RepeatedRecipe',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::IntotoProvenance::Recipe'->new($_) } @$_ ] };

declare 'MapStringRecipe',
    as HashRef[Recipe()];

declare 'Completeness',
    as InstanceOf['Grafeas::V1::IntotoProvenance::Completeness'];

coerce 'Completeness',
    from HashRef, via { 'Grafeas::V1::IntotoProvenance::Completeness'->new($_) };

declare 'RepeatedCompleteness',
    as ArrayRef[Completeness()];

coerce 'RepeatedCompleteness',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::IntotoProvenance::Completeness'->new($_) } @$_ ] };

declare 'MapStringCompleteness',
    as HashRef[Completeness()];

declare 'Metadata',
    as InstanceOf['Grafeas::V1::IntotoProvenance::Metadata'];

coerce 'Metadata',
    from HashRef, via { 'Grafeas::V1::IntotoProvenance::Metadata'->new($_) };

declare 'RepeatedMetadata',
    as ArrayRef[Metadata()];

coerce 'RepeatedMetadata',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::IntotoProvenance::Metadata'->new($_) } @$_ ] };

declare 'MapStringMetadata',
    as HashRef[Metadata()];

declare 'BuilderConfig',
    as InstanceOf['Grafeas::V1::IntotoProvenance::BuilderConfig'];

coerce 'BuilderConfig',
    from HashRef, via { 'Grafeas::V1::IntotoProvenance::BuilderConfig'->new($_) };

declare 'RepeatedBuilderConfig',
    as ArrayRef[BuilderConfig()];

coerce 'RepeatedBuilderConfig',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::IntotoProvenance::BuilderConfig'->new($_) } @$_ ] };

declare 'MapStringBuilderConfig',
    as HashRef[BuilderConfig()];

declare 'InTotoProvenance',
    as InstanceOf['Grafeas::V1::IntotoProvenance::InTotoProvenance'];

coerce 'InTotoProvenance',
    from HashRef, via { 'Grafeas::V1::IntotoProvenance::InTotoProvenance'->new($_) };

declare 'RepeatedInTotoProvenance',
    as ArrayRef[InTotoProvenance()];

coerce 'RepeatedInTotoProvenance',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::IntotoProvenance::InTotoProvenance'->new($_) } @$_ ] };

declare 'MapStringInTotoProvenance',
    as HashRef[InTotoProvenance()];

1;

__END__

=head1 NAME

Grafeas::V1::IntotoProvenance::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
