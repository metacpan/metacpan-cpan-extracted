package Grafeas::V1::IntotoStatement::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'InTotoStatement',
    as InstanceOf['Grafeas::V1::IntotoStatement::InTotoStatement'];

coerce 'InTotoStatement',
    from HashRef, via { 'Grafeas::V1::IntotoStatement::InTotoStatement'->new($_) };

declare 'RepeatedInTotoStatement',
    as ArrayRef[InTotoStatement()];

coerce 'RepeatedInTotoStatement',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::IntotoStatement::InTotoStatement'->new($_) } @$_ ] };

declare 'MapStringInTotoStatement',
    as HashRef[InTotoStatement()];

declare 'Subject',
    as InstanceOf['Grafeas::V1::IntotoStatement::Subject'];

coerce 'Subject',
    from HashRef, via { 'Grafeas::V1::IntotoStatement::Subject'->new($_) };

declare 'RepeatedSubject',
    as ArrayRef[Subject()];

coerce 'RepeatedSubject',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::IntotoStatement::Subject'->new($_) } @$_ ] };

declare 'MapStringSubject',
    as HashRef[Subject()];

declare 'DigestEntry',
    as InstanceOf['Grafeas::V1::IntotoStatement::Subject::DigestEntry'];

coerce 'DigestEntry',
    from HashRef, via { 'Grafeas::V1::IntotoStatement::Subject::DigestEntry'->new($_) };

declare 'RepeatedDigestEntry',
    as ArrayRef[DigestEntry()];

coerce 'RepeatedDigestEntry',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::IntotoStatement::Subject::DigestEntry'->new($_) } @$_ ] };

declare 'MapStringDigestEntry',
    as HashRef[DigestEntry()];

declare 'InTotoSlsaProvenanceV1',
    as InstanceOf['Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1'];

coerce 'InTotoSlsaProvenanceV1',
    from HashRef, via { 'Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1'->new($_) };

declare 'RepeatedInTotoSlsaProvenanceV1',
    as ArrayRef[InTotoSlsaProvenanceV1()];

coerce 'RepeatedInTotoSlsaProvenanceV1',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1'->new($_) } @$_ ] };

declare 'MapStringInTotoSlsaProvenanceV1',
    as HashRef[InTotoSlsaProvenanceV1()];

declare 'SlsaProvenanceV1',
    as InstanceOf['Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1::SlsaProvenanceV1'];

coerce 'SlsaProvenanceV1',
    from HashRef, via { 'Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1::SlsaProvenanceV1'->new($_) };

declare 'RepeatedSlsaProvenanceV1',
    as ArrayRef[SlsaProvenanceV1()];

coerce 'RepeatedSlsaProvenanceV1',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1::SlsaProvenanceV1'->new($_) } @$_ ] };

declare 'MapStringSlsaProvenanceV1',
    as HashRef[SlsaProvenanceV1()];

declare 'BuildDefinition',
    as InstanceOf['Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1::BuildDefinition'];

coerce 'BuildDefinition',
    from HashRef, via { 'Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1::BuildDefinition'->new($_) };

declare 'RepeatedBuildDefinition',
    as ArrayRef[BuildDefinition()];

coerce 'RepeatedBuildDefinition',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1::BuildDefinition'->new($_) } @$_ ] };

declare 'MapStringBuildDefinition',
    as HashRef[BuildDefinition()];

declare 'ResourceDescriptor',
    as InstanceOf['Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1::ResourceDescriptor'];

coerce 'ResourceDescriptor',
    from HashRef, via { 'Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1::ResourceDescriptor'->new($_) };

declare 'RepeatedResourceDescriptor',
    as ArrayRef[ResourceDescriptor()];

coerce 'RepeatedResourceDescriptor',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1::ResourceDescriptor'->new($_) } @$_ ] };

declare 'MapStringResourceDescriptor',
    as HashRef[ResourceDescriptor()];

declare 'DigestEntry',
    as InstanceOf['Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1::ResourceDescriptor::DigestEntry'];

coerce 'DigestEntry',
    from HashRef, via { 'Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1::ResourceDescriptor::DigestEntry'->new($_) };

declare 'RepeatedDigestEntry',
    as ArrayRef[DigestEntry()];

coerce 'RepeatedDigestEntry',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1::ResourceDescriptor::DigestEntry'->new($_) } @$_ ] };

declare 'MapStringDigestEntry',
    as HashRef[DigestEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1::ResourceDescriptor::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1::ResourceDescriptor::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1::ResourceDescriptor::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'RunDetails',
    as InstanceOf['Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1::RunDetails'];

coerce 'RunDetails',
    from HashRef, via { 'Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1::RunDetails'->new($_) };

declare 'RepeatedRunDetails',
    as ArrayRef[RunDetails()];

coerce 'RepeatedRunDetails',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1::RunDetails'->new($_) } @$_ ] };

declare 'MapStringRunDetails',
    as HashRef[RunDetails()];

declare 'ProvenanceBuilder',
    as InstanceOf['Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1::ProvenanceBuilder'];

coerce 'ProvenanceBuilder',
    from HashRef, via { 'Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1::ProvenanceBuilder'->new($_) };

declare 'RepeatedProvenanceBuilder',
    as ArrayRef[ProvenanceBuilder()];

coerce 'RepeatedProvenanceBuilder',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1::ProvenanceBuilder'->new($_) } @$_ ] };

declare 'MapStringProvenanceBuilder',
    as HashRef[ProvenanceBuilder()];

declare 'VersionEntry',
    as InstanceOf['Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1::ProvenanceBuilder::VersionEntry'];

coerce 'VersionEntry',
    from HashRef, via { 'Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1::ProvenanceBuilder::VersionEntry'->new($_) };

declare 'RepeatedVersionEntry',
    as ArrayRef[VersionEntry()];

coerce 'RepeatedVersionEntry',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1::ProvenanceBuilder::VersionEntry'->new($_) } @$_ ] };

declare 'MapStringVersionEntry',
    as HashRef[VersionEntry()];

declare 'BuildMetadata',
    as InstanceOf['Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1::BuildMetadata'];

coerce 'BuildMetadata',
    from HashRef, via { 'Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1::BuildMetadata'->new($_) };

declare 'RepeatedBuildMetadata',
    as ArrayRef[BuildMetadata()];

coerce 'RepeatedBuildMetadata',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::IntotoStatement::InTotoSlsaProvenanceV1::BuildMetadata'->new($_) } @$_ ] };

declare 'MapStringBuildMetadata',
    as HashRef[BuildMetadata()];

1;

__END__

=head1 NAME

Grafeas::V1::IntotoStatement::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
