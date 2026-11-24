package Grafeas::V1::SlsaProvenanceZeroTwo::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SlsaProvenanceZeroTwo',
    as InstanceOf['Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo'];

coerce 'SlsaProvenanceZeroTwo',
    from HashRef, via { 'Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo'->new($_) };

declare 'RepeatedSlsaProvenanceZeroTwo',
    as ArrayRef[SlsaProvenanceZeroTwo()];

coerce 'RepeatedSlsaProvenanceZeroTwo',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo'->new($_) } @$_ ] };

declare 'MapStringSlsaProvenanceZeroTwo',
    as HashRef[SlsaProvenanceZeroTwo()];

declare 'SlsaBuilder',
    as InstanceOf['Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo::SlsaBuilder'];

coerce 'SlsaBuilder',
    from HashRef, via { 'Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo::SlsaBuilder'->new($_) };

declare 'RepeatedSlsaBuilder',
    as ArrayRef[SlsaBuilder()];

coerce 'RepeatedSlsaBuilder',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo::SlsaBuilder'->new($_) } @$_ ] };

declare 'MapStringSlsaBuilder',
    as HashRef[SlsaBuilder()];

declare 'SlsaMaterial',
    as InstanceOf['Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo::SlsaMaterial'];

coerce 'SlsaMaterial',
    from HashRef, via { 'Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo::SlsaMaterial'->new($_) };

declare 'RepeatedSlsaMaterial',
    as ArrayRef[SlsaMaterial()];

coerce 'RepeatedSlsaMaterial',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo::SlsaMaterial'->new($_) } @$_ ] };

declare 'MapStringSlsaMaterial',
    as HashRef[SlsaMaterial()];

declare 'DigestEntry',
    as InstanceOf['Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo::SlsaMaterial::DigestEntry'];

coerce 'DigestEntry',
    from HashRef, via { 'Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo::SlsaMaterial::DigestEntry'->new($_) };

declare 'RepeatedDigestEntry',
    as ArrayRef[DigestEntry()];

coerce 'RepeatedDigestEntry',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo::SlsaMaterial::DigestEntry'->new($_) } @$_ ] };

declare 'MapStringDigestEntry',
    as HashRef[DigestEntry()];

declare 'SlsaInvocation',
    as InstanceOf['Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo::SlsaInvocation'];

coerce 'SlsaInvocation',
    from HashRef, via { 'Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo::SlsaInvocation'->new($_) };

declare 'RepeatedSlsaInvocation',
    as ArrayRef[SlsaInvocation()];

coerce 'RepeatedSlsaInvocation',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo::SlsaInvocation'->new($_) } @$_ ] };

declare 'MapStringSlsaInvocation',
    as HashRef[SlsaInvocation()];

declare 'SlsaConfigSource',
    as InstanceOf['Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo::SlsaConfigSource'];

coerce 'SlsaConfigSource',
    from HashRef, via { 'Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo::SlsaConfigSource'->new($_) };

declare 'RepeatedSlsaConfigSource',
    as ArrayRef[SlsaConfigSource()];

coerce 'RepeatedSlsaConfigSource',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo::SlsaConfigSource'->new($_) } @$_ ] };

declare 'MapStringSlsaConfigSource',
    as HashRef[SlsaConfigSource()];

declare 'DigestEntry',
    as InstanceOf['Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo::SlsaConfigSource::DigestEntry'];

coerce 'DigestEntry',
    from HashRef, via { 'Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo::SlsaConfigSource::DigestEntry'->new($_) };

declare 'RepeatedDigestEntry',
    as ArrayRef[DigestEntry()];

coerce 'RepeatedDigestEntry',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo::SlsaConfigSource::DigestEntry'->new($_) } @$_ ] };

declare 'MapStringDigestEntry',
    as HashRef[DigestEntry()];

declare 'SlsaMetadata',
    as InstanceOf['Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo::SlsaMetadata'];

coerce 'SlsaMetadata',
    from HashRef, via { 'Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo::SlsaMetadata'->new($_) };

declare 'RepeatedSlsaMetadata',
    as ArrayRef[SlsaMetadata()];

coerce 'RepeatedSlsaMetadata',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo::SlsaMetadata'->new($_) } @$_ ] };

declare 'MapStringSlsaMetadata',
    as HashRef[SlsaMetadata()];

declare 'SlsaCompleteness',
    as InstanceOf['Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo::SlsaCompleteness'];

coerce 'SlsaCompleteness',
    from HashRef, via { 'Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo::SlsaCompleteness'->new($_) };

declare 'RepeatedSlsaCompleteness',
    as ArrayRef[SlsaCompleteness()];

coerce 'RepeatedSlsaCompleteness',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::SlsaProvenanceZeroTwo::SlsaProvenanceZeroTwo::SlsaCompleteness'->new($_) } @$_ ] };

declare 'MapStringSlsaCompleteness',
    as HashRef[SlsaCompleteness()];

1;

__END__

=head1 NAME

Grafeas::V1::SlsaProvenanceZeroTwo::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
