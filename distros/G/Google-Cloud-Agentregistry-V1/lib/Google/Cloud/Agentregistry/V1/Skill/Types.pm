package Google::Cloud::Agentregistry::V1::Skill::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Skill',
    as InstanceOf['Google::Cloud::Agentregistry::V1::Skill::Skill'];

coerce 'Skill',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::Skill::Skill'->new($_) };

declare 'RepeatedSkill',
    as ArrayRef[Skill()];

coerce 'RepeatedSkill',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::Skill::Skill'->new($_) } @$_ ] };

declare 'MapStringSkill',
    as HashRef[Skill()];

declare 'Type',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'TargetState',
    as (Int | Str);

declare 'ScanningConfig',
    as InstanceOf['Google::Cloud::Agentregistry::V1::Skill::ScanningConfig'];

coerce 'ScanningConfig',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::Skill::ScanningConfig'->new($_) };

declare 'RepeatedScanningConfig',
    as ArrayRef[ScanningConfig()];

coerce 'RepeatedScanningConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::Skill::ScanningConfig'->new($_) } @$_ ] };

declare 'MapStringScanningConfig',
    as HashRef[ScanningConfig()];

declare 'Policy',
    as (Int | Str);

declare 'Frontmatter',
    as InstanceOf['Google::Cloud::Agentregistry::V1::Skill::Frontmatter'];

coerce 'Frontmatter',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::Skill::Frontmatter'->new($_) };

declare 'RepeatedFrontmatter',
    as ArrayRef[Frontmatter()];

coerce 'RepeatedFrontmatter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::Skill::Frontmatter'->new($_) } @$_ ] };

declare 'MapStringFrontmatter',
    as HashRef[Frontmatter()];

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Agentregistry::V1::Skill::Frontmatter::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::Skill::Frontmatter::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::Skill::Frontmatter::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'ArchiveUploadSource',
    as InstanceOf['Google::Cloud::Agentregistry::V1::Skill::ArchiveUploadSource'];

coerce 'ArchiveUploadSource',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::Skill::ArchiveUploadSource'->new($_) };

declare 'RepeatedArchiveUploadSource',
    as ArrayRef[ArchiveUploadSource()];

coerce 'RepeatedArchiveUploadSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::Skill::ArchiveUploadSource'->new($_) } @$_ ] };

declare 'MapStringArchiveUploadSource',
    as HashRef[ArchiveUploadSource()];

declare 'SkillRevision',
    as InstanceOf['Google::Cloud::Agentregistry::V1::Skill::SkillRevision'];

coerce 'SkillRevision',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::Skill::SkillRevision'->new($_) };

declare 'RepeatedSkillRevision',
    as ArrayRef[SkillRevision()];

coerce 'RepeatedSkillRevision',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::Skill::SkillRevision'->new($_) } @$_ ] };

declare 'MapStringSkillRevision',
    as HashRef[SkillRevision()];

declare 'State',
    as (Int | Str);

declare 'ScanResult',
    as InstanceOf['Google::Cloud::Agentregistry::V1::Skill::SkillRevision::ScanResult'];

coerce 'ScanResult',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::Skill::SkillRevision::ScanResult'->new($_) };

declare 'RepeatedScanResult',
    as ArrayRef[ScanResult()];

coerce 'RepeatedScanResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::Skill::SkillRevision::ScanResult'->new($_) } @$_ ] };

declare 'MapStringScanResult',
    as HashRef[ScanResult()];

declare 'ScanState',
    as (Int | Str);

declare 'GcsSource',
    as InstanceOf['Google::Cloud::Agentregistry::V1::Skill::GcsSource'];

coerce 'GcsSource',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::Skill::GcsSource'->new($_) };

declare 'RepeatedGcsSource',
    as ArrayRef[GcsSource()];

coerce 'RepeatedGcsSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::Skill::GcsSource'->new($_) } @$_ ] };

declare 'MapStringGcsSource',
    as HashRef[GcsSource()];

declare 'Publisher',
    as InstanceOf['Google::Cloud::Agentregistry::V1::Skill::Publisher'];

coerce 'Publisher',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::Skill::Publisher'->new($_) };

declare 'RepeatedPublisher',
    as ArrayRef[Publisher()];

coerce 'RepeatedPublisher',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::Skill::Publisher'->new($_) } @$_ ] };

declare 'MapStringPublisher',
    as HashRef[Publisher()];

declare 'PublisherTier',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Agentregistry::V1::Skill::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
