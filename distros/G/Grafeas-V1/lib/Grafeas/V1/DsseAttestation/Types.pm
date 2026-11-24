package Grafeas::V1::DsseAttestation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DSSEAttestationNote',
    as InstanceOf['Grafeas::V1::DsseAttestation::DSSEAttestationNote'];

coerce 'DSSEAttestationNote',
    from HashRef, via { 'Grafeas::V1::DsseAttestation::DSSEAttestationNote'->new($_) };

declare 'RepeatedDSSEAttestationNote',
    as ArrayRef[DSSEAttestationNote()];

coerce 'RepeatedDSSEAttestationNote',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::DsseAttestation::DSSEAttestationNote'->new($_) } @$_ ] };

declare 'MapStringDSSEAttestationNote',
    as HashRef[DSSEAttestationNote()];

declare 'DSSEHint',
    as InstanceOf['Grafeas::V1::DsseAttestation::DSSEAttestationNote::DSSEHint'];

coerce 'DSSEHint',
    from HashRef, via { 'Grafeas::V1::DsseAttestation::DSSEAttestationNote::DSSEHint'->new($_) };

declare 'RepeatedDSSEHint',
    as ArrayRef[DSSEHint()];

coerce 'RepeatedDSSEHint',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::DsseAttestation::DSSEAttestationNote::DSSEHint'->new($_) } @$_ ] };

declare 'MapStringDSSEHint',
    as HashRef[DSSEHint()];

declare 'DSSEAttestationOccurrence',
    as InstanceOf['Grafeas::V1::DsseAttestation::DSSEAttestationOccurrence'];

coerce 'DSSEAttestationOccurrence',
    from HashRef, via { 'Grafeas::V1::DsseAttestation::DSSEAttestationOccurrence'->new($_) };

declare 'RepeatedDSSEAttestationOccurrence',
    as ArrayRef[DSSEAttestationOccurrence()];

coerce 'RepeatedDSSEAttestationOccurrence',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::DsseAttestation::DSSEAttestationOccurrence'->new($_) } @$_ ] };

declare 'MapStringDSSEAttestationOccurrence',
    as HashRef[DSSEAttestationOccurrence()];

1;

__END__

=head1 NAME

Grafeas::V1::DsseAttestation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
