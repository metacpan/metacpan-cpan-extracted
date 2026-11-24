package Grafeas::V1::Sbom::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SBOMReferenceNote',
    as InstanceOf['Grafeas::V1::Sbom::SBOMReferenceNote'];

coerce 'SBOMReferenceNote',
    from HashRef, via { 'Grafeas::V1::Sbom::SBOMReferenceNote'->new($_) };

declare 'RepeatedSBOMReferenceNote',
    as ArrayRef[SBOMReferenceNote()];

coerce 'RepeatedSBOMReferenceNote',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Sbom::SBOMReferenceNote'->new($_) } @$_ ] };

declare 'MapStringSBOMReferenceNote',
    as HashRef[SBOMReferenceNote()];

declare 'SBOMReferenceOccurrence',
    as InstanceOf['Grafeas::V1::Sbom::SBOMReferenceOccurrence'];

coerce 'SBOMReferenceOccurrence',
    from HashRef, via { 'Grafeas::V1::Sbom::SBOMReferenceOccurrence'->new($_) };

declare 'RepeatedSBOMReferenceOccurrence',
    as ArrayRef[SBOMReferenceOccurrence()];

coerce 'RepeatedSBOMReferenceOccurrence',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Sbom::SBOMReferenceOccurrence'->new($_) } @$_ ] };

declare 'MapStringSBOMReferenceOccurrence',
    as HashRef[SBOMReferenceOccurrence()];

declare 'SbomReferenceIntotoPayload',
    as InstanceOf['Grafeas::V1::Sbom::SbomReferenceIntotoPayload'];

coerce 'SbomReferenceIntotoPayload',
    from HashRef, via { 'Grafeas::V1::Sbom::SbomReferenceIntotoPayload'->new($_) };

declare 'RepeatedSbomReferenceIntotoPayload',
    as ArrayRef[SbomReferenceIntotoPayload()];

coerce 'RepeatedSbomReferenceIntotoPayload',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Sbom::SbomReferenceIntotoPayload'->new($_) } @$_ ] };

declare 'MapStringSbomReferenceIntotoPayload',
    as HashRef[SbomReferenceIntotoPayload()];

declare 'SbomReferenceIntotoPredicate',
    as InstanceOf['Grafeas::V1::Sbom::SbomReferenceIntotoPredicate'];

coerce 'SbomReferenceIntotoPredicate',
    from HashRef, via { 'Grafeas::V1::Sbom::SbomReferenceIntotoPredicate'->new($_) };

declare 'RepeatedSbomReferenceIntotoPredicate',
    as ArrayRef[SbomReferenceIntotoPredicate()];

coerce 'RepeatedSbomReferenceIntotoPredicate',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Sbom::SbomReferenceIntotoPredicate'->new($_) } @$_ ] };

declare 'MapStringSbomReferenceIntotoPredicate',
    as HashRef[SbomReferenceIntotoPredicate()];

declare 'DigestEntry',
    as InstanceOf['Grafeas::V1::Sbom::SbomReferenceIntotoPredicate::DigestEntry'];

coerce 'DigestEntry',
    from HashRef, via { 'Grafeas::V1::Sbom::SbomReferenceIntotoPredicate::DigestEntry'->new($_) };

declare 'RepeatedDigestEntry',
    as ArrayRef[DigestEntry()];

coerce 'RepeatedDigestEntry',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Sbom::SbomReferenceIntotoPredicate::DigestEntry'->new($_) } @$_ ] };

declare 'MapStringDigestEntry',
    as HashRef[DigestEntry()];

1;

__END__

=head1 NAME

Grafeas::V1::Sbom::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
