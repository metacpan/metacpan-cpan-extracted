package Grafeas::V1::Discovery::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DiscoveryNote',
    as InstanceOf['Grafeas::V1::Discovery::DiscoveryNote'];

coerce 'DiscoveryNote',
    from HashRef, via { 'Grafeas::V1::Discovery::DiscoveryNote'->new($_) };

declare 'RepeatedDiscoveryNote',
    as ArrayRef[DiscoveryNote()];

coerce 'RepeatedDiscoveryNote',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Discovery::DiscoveryNote'->new($_) } @$_ ] };

declare 'MapStringDiscoveryNote',
    as HashRef[DiscoveryNote()];

declare 'DiscoveryOccurrence',
    as InstanceOf['Grafeas::V1::Discovery::DiscoveryOccurrence'];

coerce 'DiscoveryOccurrence',
    from HashRef, via { 'Grafeas::V1::Discovery::DiscoveryOccurrence'->new($_) };

declare 'RepeatedDiscoveryOccurrence',
    as ArrayRef[DiscoveryOccurrence()];

coerce 'RepeatedDiscoveryOccurrence',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Discovery::DiscoveryOccurrence'->new($_) } @$_ ] };

declare 'MapStringDiscoveryOccurrence',
    as HashRef[DiscoveryOccurrence()];

declare 'ContinuousAnalysis',
    as (Int | Str);

declare 'AnalysisStatus',
    as (Int | Str);

declare 'AnalysisCompleted',
    as InstanceOf['Grafeas::V1::Discovery::DiscoveryOccurrence::AnalysisCompleted'];

coerce 'AnalysisCompleted',
    from HashRef, via { 'Grafeas::V1::Discovery::DiscoveryOccurrence::AnalysisCompleted'->new($_) };

declare 'RepeatedAnalysisCompleted',
    as ArrayRef[AnalysisCompleted()];

coerce 'RepeatedAnalysisCompleted',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Discovery::DiscoveryOccurrence::AnalysisCompleted'->new($_) } @$_ ] };

declare 'MapStringAnalysisCompleted',
    as HashRef[AnalysisCompleted()];

declare 'SBOMStatus',
    as InstanceOf['Grafeas::V1::Discovery::DiscoveryOccurrence::SBOMStatus'];

coerce 'SBOMStatus',
    from HashRef, via { 'Grafeas::V1::Discovery::DiscoveryOccurrence::SBOMStatus'->new($_) };

declare 'RepeatedSBOMStatus',
    as ArrayRef[SBOMStatus()];

coerce 'RepeatedSBOMStatus',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Discovery::DiscoveryOccurrence::SBOMStatus'->new($_) } @$_ ] };

declare 'MapStringSBOMStatus',
    as HashRef[SBOMStatus()];

declare 'SBOMState',
    as (Int | Str);

declare 'VulnerabilityAttestation',
    as InstanceOf['Grafeas::V1::Discovery::DiscoveryOccurrence::VulnerabilityAttestation'];

coerce 'VulnerabilityAttestation',
    from HashRef, via { 'Grafeas::V1::Discovery::DiscoveryOccurrence::VulnerabilityAttestation'->new($_) };

declare 'RepeatedVulnerabilityAttestation',
    as ArrayRef[VulnerabilityAttestation()];

coerce 'RepeatedVulnerabilityAttestation',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Discovery::DiscoveryOccurrence::VulnerabilityAttestation'->new($_) } @$_ ] };

declare 'MapStringVulnerabilityAttestation',
    as HashRef[VulnerabilityAttestation()];

declare 'VulnerabilityAttestationState',
    as (Int | Str);

declare 'File',
    as InstanceOf['Grafeas::V1::Discovery::DiscoveryOccurrence::File'];

coerce 'File',
    from HashRef, via { 'Grafeas::V1::Discovery::DiscoveryOccurrence::File'->new($_) };

declare 'RepeatedFile',
    as ArrayRef[File()];

coerce 'RepeatedFile',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Discovery::DiscoveryOccurrence::File'->new($_) } @$_ ] };

declare 'MapStringFile',
    as HashRef[File()];

declare 'DigestEntry',
    as InstanceOf['Grafeas::V1::Discovery::DiscoveryOccurrence::File::DigestEntry'];

coerce 'DigestEntry',
    from HashRef, via { 'Grafeas::V1::Discovery::DiscoveryOccurrence::File::DigestEntry'->new($_) };

declare 'RepeatedDigestEntry',
    as ArrayRef[DigestEntry()];

coerce 'RepeatedDigestEntry',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Discovery::DiscoveryOccurrence::File::DigestEntry'->new($_) } @$_ ] };

declare 'MapStringDigestEntry',
    as HashRef[DigestEntry()];

1;

__END__

=head1 NAME

Grafeas::V1::Discovery::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
