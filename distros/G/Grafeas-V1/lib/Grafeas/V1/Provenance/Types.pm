package Grafeas::V1::Provenance::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BuildProvenance',
    as InstanceOf['Grafeas::V1::Provenance::BuildProvenance'];

coerce 'BuildProvenance',
    from HashRef, via { 'Grafeas::V1::Provenance::BuildProvenance'->new($_) };

declare 'RepeatedBuildProvenance',
    as ArrayRef[BuildProvenance()];

coerce 'RepeatedBuildProvenance',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Provenance::BuildProvenance'->new($_) } @$_ ] };

declare 'MapStringBuildProvenance',
    as HashRef[BuildProvenance()];

declare 'BuildOptionsEntry',
    as InstanceOf['Grafeas::V1::Provenance::BuildProvenance::BuildOptionsEntry'];

coerce 'BuildOptionsEntry',
    from HashRef, via { 'Grafeas::V1::Provenance::BuildProvenance::BuildOptionsEntry'->new($_) };

declare 'RepeatedBuildOptionsEntry',
    as ArrayRef[BuildOptionsEntry()];

coerce 'RepeatedBuildOptionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Provenance::BuildProvenance::BuildOptionsEntry'->new($_) } @$_ ] };

declare 'MapStringBuildOptionsEntry',
    as HashRef[BuildOptionsEntry()];

declare 'Source',
    as InstanceOf['Grafeas::V1::Provenance::Source'];

coerce 'Source',
    from HashRef, via { 'Grafeas::V1::Provenance::Source'->new($_) };

declare 'RepeatedSource',
    as ArrayRef[Source()];

coerce 'RepeatedSource',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Provenance::Source'->new($_) } @$_ ] };

declare 'MapStringSource',
    as HashRef[Source()];

declare 'FileHashesEntry',
    as InstanceOf['Grafeas::V1::Provenance::Source::FileHashesEntry'];

coerce 'FileHashesEntry',
    from HashRef, via { 'Grafeas::V1::Provenance::Source::FileHashesEntry'->new($_) };

declare 'RepeatedFileHashesEntry',
    as ArrayRef[FileHashesEntry()];

coerce 'RepeatedFileHashesEntry',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Provenance::Source::FileHashesEntry'->new($_) } @$_ ] };

declare 'MapStringFileHashesEntry',
    as HashRef[FileHashesEntry()];

declare 'FileHashes',
    as InstanceOf['Grafeas::V1::Provenance::FileHashes'];

coerce 'FileHashes',
    from HashRef, via { 'Grafeas::V1::Provenance::FileHashes'->new($_) };

declare 'RepeatedFileHashes',
    as ArrayRef[FileHashes()];

coerce 'RepeatedFileHashes',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Provenance::FileHashes'->new($_) } @$_ ] };

declare 'MapStringFileHashes',
    as HashRef[FileHashes()];

declare 'Hash',
    as InstanceOf['Grafeas::V1::Provenance::Hash'];

coerce 'Hash',
    from HashRef, via { 'Grafeas::V1::Provenance::Hash'->new($_) };

declare 'RepeatedHash',
    as ArrayRef[Hash()];

coerce 'RepeatedHash',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Provenance::Hash'->new($_) } @$_ ] };

declare 'MapStringHash',
    as HashRef[Hash()];

declare 'Command',
    as InstanceOf['Grafeas::V1::Provenance::Command'];

coerce 'Command',
    from HashRef, via { 'Grafeas::V1::Provenance::Command'->new($_) };

declare 'RepeatedCommand',
    as ArrayRef[Command()];

coerce 'RepeatedCommand',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Provenance::Command'->new($_) } @$_ ] };

declare 'MapStringCommand',
    as HashRef[Command()];

declare 'Artifact',
    as InstanceOf['Grafeas::V1::Provenance::Artifact'];

coerce 'Artifact',
    from HashRef, via { 'Grafeas::V1::Provenance::Artifact'->new($_) };

declare 'RepeatedArtifact',
    as ArrayRef[Artifact()];

coerce 'RepeatedArtifact',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Provenance::Artifact'->new($_) } @$_ ] };

declare 'MapStringArtifact',
    as HashRef[Artifact()];

declare 'SourceContext',
    as InstanceOf['Grafeas::V1::Provenance::SourceContext'];

coerce 'SourceContext',
    from HashRef, via { 'Grafeas::V1::Provenance::SourceContext'->new($_) };

declare 'RepeatedSourceContext',
    as ArrayRef[SourceContext()];

coerce 'RepeatedSourceContext',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Provenance::SourceContext'->new($_) } @$_ ] };

declare 'MapStringSourceContext',
    as HashRef[SourceContext()];

declare 'LabelsEntry',
    as InstanceOf['Grafeas::V1::Provenance::SourceContext::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Grafeas::V1::Provenance::SourceContext::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Provenance::SourceContext::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AliasContext',
    as InstanceOf['Grafeas::V1::Provenance::AliasContext'];

coerce 'AliasContext',
    from HashRef, via { 'Grafeas::V1::Provenance::AliasContext'->new($_) };

declare 'RepeatedAliasContext',
    as ArrayRef[AliasContext()];

coerce 'RepeatedAliasContext',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Provenance::AliasContext'->new($_) } @$_ ] };

declare 'MapStringAliasContext',
    as HashRef[AliasContext()];

declare 'Kind',
    as (Int | Str);

declare 'CloudRepoSourceContext',
    as InstanceOf['Grafeas::V1::Provenance::CloudRepoSourceContext'];

coerce 'CloudRepoSourceContext',
    from HashRef, via { 'Grafeas::V1::Provenance::CloudRepoSourceContext'->new($_) };

declare 'RepeatedCloudRepoSourceContext',
    as ArrayRef[CloudRepoSourceContext()];

coerce 'RepeatedCloudRepoSourceContext',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Provenance::CloudRepoSourceContext'->new($_) } @$_ ] };

declare 'MapStringCloudRepoSourceContext',
    as HashRef[CloudRepoSourceContext()];

declare 'GerritSourceContext',
    as InstanceOf['Grafeas::V1::Provenance::GerritSourceContext'];

coerce 'GerritSourceContext',
    from HashRef, via { 'Grafeas::V1::Provenance::GerritSourceContext'->new($_) };

declare 'RepeatedGerritSourceContext',
    as ArrayRef[GerritSourceContext()];

coerce 'RepeatedGerritSourceContext',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Provenance::GerritSourceContext'->new($_) } @$_ ] };

declare 'MapStringGerritSourceContext',
    as HashRef[GerritSourceContext()];

declare 'GitSourceContext',
    as InstanceOf['Grafeas::V1::Provenance::GitSourceContext'];

coerce 'GitSourceContext',
    from HashRef, via { 'Grafeas::V1::Provenance::GitSourceContext'->new($_) };

declare 'RepeatedGitSourceContext',
    as ArrayRef[GitSourceContext()];

coerce 'RepeatedGitSourceContext',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Provenance::GitSourceContext'->new($_) } @$_ ] };

declare 'MapStringGitSourceContext',
    as HashRef[GitSourceContext()];

declare 'RepoId',
    as InstanceOf['Grafeas::V1::Provenance::RepoId'];

coerce 'RepoId',
    from HashRef, via { 'Grafeas::V1::Provenance::RepoId'->new($_) };

declare 'RepeatedRepoId',
    as ArrayRef[RepoId()];

coerce 'RepeatedRepoId',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Provenance::RepoId'->new($_) } @$_ ] };

declare 'MapStringRepoId',
    as HashRef[RepoId()];

declare 'ProjectRepoId',
    as InstanceOf['Grafeas::V1::Provenance::ProjectRepoId'];

coerce 'ProjectRepoId',
    from HashRef, via { 'Grafeas::V1::Provenance::ProjectRepoId'->new($_) };

declare 'RepeatedProjectRepoId',
    as ArrayRef[ProjectRepoId()];

coerce 'RepeatedProjectRepoId',
    from ArrayRef[HashRef], via { [ map { 'Grafeas::V1::Provenance::ProjectRepoId'->new($_) } @$_ ] };

declare 'MapStringProjectRepoId',
    as HashRef[ProjectRepoId()];

1;

__END__

=head1 NAME

Grafeas::V1::Provenance::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
