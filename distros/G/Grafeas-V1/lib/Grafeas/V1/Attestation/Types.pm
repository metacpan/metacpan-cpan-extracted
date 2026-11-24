package Grafeas::V1::Attestation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AttestationNote',
    as InstanceOf['Grafeas::V1::Attestation::AttestationNote'];

coerce 'AttestationNote',
    from HashRef, via { 'Grafeas::V1::Attestation::AttestationNote'->new($_) };

declare 'RepeatedAttestationNote',
    as ArrayRef[AttestationNote()];

coerce 'RepeatedAttestationNote',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Attestation::AttestationNote'->new($_) } @$_ ] };

declare 'MapStringAttestationNote',
    as HashRef[AttestationNote()];

declare 'Hint',
    as InstanceOf['Grafeas::V1::Attestation::AttestationNote::Hint'];

coerce 'Hint',
    from HashRef, via { 'Grafeas::V1::Attestation::AttestationNote::Hint'->new($_) };

declare 'RepeatedHint',
    as ArrayRef[Hint()];

coerce 'RepeatedHint',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Attestation::AttestationNote::Hint'->new($_) } @$_ ] };

declare 'MapStringHint',
    as HashRef[Hint()];

declare 'Jwt',
    as InstanceOf['Grafeas::V1::Attestation::Jwt'];

coerce 'Jwt',
    from HashRef, via { 'Grafeas::V1::Attestation::Jwt'->new($_) };

declare 'RepeatedJwt',
    as ArrayRef[Jwt()];

coerce 'RepeatedJwt',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Attestation::Jwt'->new($_) } @$_ ] };

declare 'MapStringJwt',
    as HashRef[Jwt()];

declare 'AttestationOccurrence',
    as InstanceOf['Grafeas::V1::Attestation::AttestationOccurrence'];

coerce 'AttestationOccurrence',
    from HashRef, via { 'Grafeas::V1::Attestation::AttestationOccurrence'->new($_) };

declare 'RepeatedAttestationOccurrence',
    as ArrayRef[AttestationOccurrence()];

coerce 'RepeatedAttestationOccurrence',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Attestation::AttestationOccurrence'->new($_) } @$_ ] };

declare 'MapStringAttestationOccurrence',
    as HashRef[AttestationOccurrence()];

1;

__END__

=head1 NAME

Grafeas::V1::Attestation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
