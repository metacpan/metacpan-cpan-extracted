package Google::Devtools::Source::V1::SourceContext::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SourceContext',
    as InstanceOf['Google::Devtools::Source::V1::SourceContext::SourceContext'];

coerce 'SourceContext',
    from HashRef, via { 'Google::Devtools::Source::V1::SourceContext::SourceContext'->new($_) };

declare 'RepeatedSourceContext',
    as ArrayRef[SourceContext()];

coerce 'RepeatedSourceContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Source::V1::SourceContext::SourceContext'->new($_) } @$_ ] };

declare 'MapStringSourceContext',
    as HashRef[SourceContext()];

declare 'ExtendedSourceContext',
    as InstanceOf['Google::Devtools::Source::V1::SourceContext::ExtendedSourceContext'];

coerce 'ExtendedSourceContext',
    from HashRef, via { 'Google::Devtools::Source::V1::SourceContext::ExtendedSourceContext'->new($_) };

declare 'RepeatedExtendedSourceContext',
    as ArrayRef[ExtendedSourceContext()];

coerce 'RepeatedExtendedSourceContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Source::V1::SourceContext::ExtendedSourceContext'->new($_) } @$_ ] };

declare 'MapStringExtendedSourceContext',
    as HashRef[ExtendedSourceContext()];

declare 'LabelsEntry',
    as InstanceOf['Google::Devtools::Source::V1::SourceContext::ExtendedSourceContext::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Devtools::Source::V1::SourceContext::ExtendedSourceContext::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Source::V1::SourceContext::ExtendedSourceContext::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AliasContext',
    as InstanceOf['Google::Devtools::Source::V1::SourceContext::AliasContext'];

coerce 'AliasContext',
    from HashRef, via { 'Google::Devtools::Source::V1::SourceContext::AliasContext'->new($_) };

declare 'RepeatedAliasContext',
    as ArrayRef[AliasContext()];

coerce 'RepeatedAliasContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Source::V1::SourceContext::AliasContext'->new($_) } @$_ ] };

declare 'MapStringAliasContext',
    as HashRef[AliasContext()];

declare 'Kind',
    as (Int | Str);

declare 'CloudRepoSourceContext',
    as InstanceOf['Google::Devtools::Source::V1::SourceContext::CloudRepoSourceContext'];

coerce 'CloudRepoSourceContext',
    from HashRef, via { 'Google::Devtools::Source::V1::SourceContext::CloudRepoSourceContext'->new($_) };

declare 'RepeatedCloudRepoSourceContext',
    as ArrayRef[CloudRepoSourceContext()];

coerce 'RepeatedCloudRepoSourceContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Source::V1::SourceContext::CloudRepoSourceContext'->new($_) } @$_ ] };

declare 'MapStringCloudRepoSourceContext',
    as HashRef[CloudRepoSourceContext()];

declare 'CloudWorkspaceSourceContext',
    as InstanceOf['Google::Devtools::Source::V1::SourceContext::CloudWorkspaceSourceContext'];

coerce 'CloudWorkspaceSourceContext',
    from HashRef, via { 'Google::Devtools::Source::V1::SourceContext::CloudWorkspaceSourceContext'->new($_) };

declare 'RepeatedCloudWorkspaceSourceContext',
    as ArrayRef[CloudWorkspaceSourceContext()];

coerce 'RepeatedCloudWorkspaceSourceContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Source::V1::SourceContext::CloudWorkspaceSourceContext'->new($_) } @$_ ] };

declare 'MapStringCloudWorkspaceSourceContext',
    as HashRef[CloudWorkspaceSourceContext()];

declare 'GerritSourceContext',
    as InstanceOf['Google::Devtools::Source::V1::SourceContext::GerritSourceContext'];

coerce 'GerritSourceContext',
    from HashRef, via { 'Google::Devtools::Source::V1::SourceContext::GerritSourceContext'->new($_) };

declare 'RepeatedGerritSourceContext',
    as ArrayRef[GerritSourceContext()];

coerce 'RepeatedGerritSourceContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Source::V1::SourceContext::GerritSourceContext'->new($_) } @$_ ] };

declare 'MapStringGerritSourceContext',
    as HashRef[GerritSourceContext()];

declare 'GitSourceContext',
    as InstanceOf['Google::Devtools::Source::V1::SourceContext::GitSourceContext'];

coerce 'GitSourceContext',
    from HashRef, via { 'Google::Devtools::Source::V1::SourceContext::GitSourceContext'->new($_) };

declare 'RepeatedGitSourceContext',
    as ArrayRef[GitSourceContext()];

coerce 'RepeatedGitSourceContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Source::V1::SourceContext::GitSourceContext'->new($_) } @$_ ] };

declare 'MapStringGitSourceContext',
    as HashRef[GitSourceContext()];

declare 'RepoId',
    as InstanceOf['Google::Devtools::Source::V1::SourceContext::RepoId'];

coerce 'RepoId',
    from HashRef, via { 'Google::Devtools::Source::V1::SourceContext::RepoId'->new($_) };

declare 'RepeatedRepoId',
    as ArrayRef[RepoId()];

coerce 'RepeatedRepoId',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Source::V1::SourceContext::RepoId'->new($_) } @$_ ] };

declare 'MapStringRepoId',
    as HashRef[RepoId()];

declare 'ProjectRepoId',
    as InstanceOf['Google::Devtools::Source::V1::SourceContext::ProjectRepoId'];

coerce 'ProjectRepoId',
    from HashRef, via { 'Google::Devtools::Source::V1::SourceContext::ProjectRepoId'->new($_) };

declare 'RepeatedProjectRepoId',
    as ArrayRef[ProjectRepoId()];

coerce 'RepeatedProjectRepoId',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Source::V1::SourceContext::ProjectRepoId'->new($_) } @$_ ] };

declare 'MapStringProjectRepoId',
    as HashRef[ProjectRepoId()];

declare 'CloudWorkspaceId',
    as InstanceOf['Google::Devtools::Source::V1::SourceContext::CloudWorkspaceId'];

coerce 'CloudWorkspaceId',
    from HashRef, via { 'Google::Devtools::Source::V1::SourceContext::CloudWorkspaceId'->new($_) };

declare 'RepeatedCloudWorkspaceId',
    as ArrayRef[CloudWorkspaceId()];

coerce 'RepeatedCloudWorkspaceId',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Source::V1::SourceContext::CloudWorkspaceId'->new($_) } @$_ ] };

declare 'MapStringCloudWorkspaceId',
    as HashRef[CloudWorkspaceId()];

1;

__END__

=head1 NAME

Google::Devtools::Source::V1::SourceContext::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
