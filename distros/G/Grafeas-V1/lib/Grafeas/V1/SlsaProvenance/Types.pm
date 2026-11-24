package Grafeas::V1::SlsaProvenance::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SlsaProvenance',
    as InstanceOf['Grafeas::V1::SlsaProvenance::SlsaProvenance'];

coerce 'SlsaProvenance',
    from HashRef, via { 'Grafeas::V1::SlsaProvenance::SlsaProvenance'->new($_) };

declare 'RepeatedSlsaProvenance',
    as ArrayRef[SlsaProvenance()];

coerce 'RepeatedSlsaProvenance',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::SlsaProvenance::SlsaProvenance'->new($_) } @$_ ] };

declare 'MapStringSlsaProvenance',
    as HashRef[SlsaProvenance()];

declare 'SlsaRecipe',
    as InstanceOf['Grafeas::V1::SlsaProvenance::SlsaProvenance::SlsaRecipe'];

coerce 'SlsaRecipe',
    from HashRef, via { 'Grafeas::V1::SlsaProvenance::SlsaProvenance::SlsaRecipe'->new($_) };

declare 'RepeatedSlsaRecipe',
    as ArrayRef[SlsaRecipe()];

coerce 'RepeatedSlsaRecipe',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::SlsaProvenance::SlsaProvenance::SlsaRecipe'->new($_) } @$_ ] };

declare 'MapStringSlsaRecipe',
    as HashRef[SlsaRecipe()];

declare 'SlsaCompleteness',
    as InstanceOf['Grafeas::V1::SlsaProvenance::SlsaProvenance::SlsaCompleteness'];

coerce 'SlsaCompleteness',
    from HashRef, via { 'Grafeas::V1::SlsaProvenance::SlsaProvenance::SlsaCompleteness'->new($_) };

declare 'RepeatedSlsaCompleteness',
    as ArrayRef[SlsaCompleteness()];

coerce 'RepeatedSlsaCompleteness',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::SlsaProvenance::SlsaProvenance::SlsaCompleteness'->new($_) } @$_ ] };

declare 'MapStringSlsaCompleteness',
    as HashRef[SlsaCompleteness()];

declare 'SlsaMetadata',
    as InstanceOf['Grafeas::V1::SlsaProvenance::SlsaProvenance::SlsaMetadata'];

coerce 'SlsaMetadata',
    from HashRef, via { 'Grafeas::V1::SlsaProvenance::SlsaProvenance::SlsaMetadata'->new($_) };

declare 'RepeatedSlsaMetadata',
    as ArrayRef[SlsaMetadata()];

coerce 'RepeatedSlsaMetadata',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::SlsaProvenance::SlsaProvenance::SlsaMetadata'->new($_) } @$_ ] };

declare 'MapStringSlsaMetadata',
    as HashRef[SlsaMetadata()];

declare 'SlsaBuilder',
    as InstanceOf['Grafeas::V1::SlsaProvenance::SlsaProvenance::SlsaBuilder'];

coerce 'SlsaBuilder',
    from HashRef, via { 'Grafeas::V1::SlsaProvenance::SlsaProvenance::SlsaBuilder'->new($_) };

declare 'RepeatedSlsaBuilder',
    as ArrayRef[SlsaBuilder()];

coerce 'RepeatedSlsaBuilder',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::SlsaProvenance::SlsaProvenance::SlsaBuilder'->new($_) } @$_ ] };

declare 'MapStringSlsaBuilder',
    as HashRef[SlsaBuilder()];

declare 'Material',
    as InstanceOf['Grafeas::V1::SlsaProvenance::SlsaProvenance::Material'];

coerce 'Material',
    from HashRef, via { 'Grafeas::V1::SlsaProvenance::SlsaProvenance::Material'->new($_) };

declare 'RepeatedMaterial',
    as ArrayRef[Material()];

coerce 'RepeatedMaterial',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::SlsaProvenance::SlsaProvenance::Material'->new($_) } @$_ ] };

declare 'MapStringMaterial',
    as HashRef[Material()];

declare 'DigestEntry',
    as InstanceOf['Grafeas::V1::SlsaProvenance::SlsaProvenance::Material::DigestEntry'];

coerce 'DigestEntry',
    from HashRef, via { 'Grafeas::V1::SlsaProvenance::SlsaProvenance::Material::DigestEntry'->new($_) };

declare 'RepeatedDigestEntry',
    as ArrayRef[DigestEntry()];

coerce 'RepeatedDigestEntry',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::SlsaProvenance::SlsaProvenance::Material::DigestEntry'->new($_) } @$_ ] };

declare 'MapStringDigestEntry',
    as HashRef[DigestEntry()];

1;

__END__

=head1 NAME

Grafeas::V1::SlsaProvenance::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
