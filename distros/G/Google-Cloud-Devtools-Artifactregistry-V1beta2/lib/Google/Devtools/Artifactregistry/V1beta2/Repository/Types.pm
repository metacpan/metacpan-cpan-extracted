package Google::Devtools::Artifactregistry::V1beta2::Repository::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Repository',
    as InstanceOf['Google::Devtools::Artifactregistry::V1beta2::Repository::Repository'];

coerce 'Repository',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1beta2::Repository::Repository'->new($_) };

declare 'RepeatedRepository',
    as ArrayRef[Repository()];

coerce 'RepeatedRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1beta2::Repository::Repository'->new($_) } @$_ ] };

declare 'MapStringRepository',
    as HashRef[Repository()];

declare 'Format',
    as (Int | Str);

declare 'MavenRepositoryConfig',
    as InstanceOf['Google::Devtools::Artifactregistry::V1beta2::Repository::Repository::MavenRepositoryConfig'];

coerce 'MavenRepositoryConfig',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1beta2::Repository::Repository::MavenRepositoryConfig'->new($_) };

declare 'RepeatedMavenRepositoryConfig',
    as ArrayRef[MavenRepositoryConfig()];

coerce 'RepeatedMavenRepositoryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1beta2::Repository::Repository::MavenRepositoryConfig'->new($_) } @$_ ] };

declare 'MapStringMavenRepositoryConfig',
    as HashRef[MavenRepositoryConfig()];

declare 'VersionPolicy',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Devtools::Artifactregistry::V1beta2::Repository::Repository::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1beta2::Repository::Repository::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1beta2::Repository::Repository::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListRepositoriesRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1beta2::Repository::ListRepositoriesRequest'];

coerce 'ListRepositoriesRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1beta2::Repository::ListRepositoriesRequest'->new($_) };

declare 'RepeatedListRepositoriesRequest',
    as ArrayRef[ListRepositoriesRequest()];

coerce 'RepeatedListRepositoriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1beta2::Repository::ListRepositoriesRequest'->new($_) } @$_ ] };

declare 'MapStringListRepositoriesRequest',
    as HashRef[ListRepositoriesRequest()];

declare 'ListRepositoriesResponse',
    as InstanceOf['Google::Devtools::Artifactregistry::V1beta2::Repository::ListRepositoriesResponse'];

coerce 'ListRepositoriesResponse',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1beta2::Repository::ListRepositoriesResponse'->new($_) };

declare 'RepeatedListRepositoriesResponse',
    as ArrayRef[ListRepositoriesResponse()];

coerce 'RepeatedListRepositoriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1beta2::Repository::ListRepositoriesResponse'->new($_) } @$_ ] };

declare 'MapStringListRepositoriesResponse',
    as HashRef[ListRepositoriesResponse()];

declare 'GetRepositoryRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1beta2::Repository::GetRepositoryRequest'];

coerce 'GetRepositoryRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1beta2::Repository::GetRepositoryRequest'->new($_) };

declare 'RepeatedGetRepositoryRequest',
    as ArrayRef[GetRepositoryRequest()];

coerce 'RepeatedGetRepositoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1beta2::Repository::GetRepositoryRequest'->new($_) } @$_ ] };

declare 'MapStringGetRepositoryRequest',
    as HashRef[GetRepositoryRequest()];

declare 'CreateRepositoryRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1beta2::Repository::CreateRepositoryRequest'];

coerce 'CreateRepositoryRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1beta2::Repository::CreateRepositoryRequest'->new($_) };

declare 'RepeatedCreateRepositoryRequest',
    as ArrayRef[CreateRepositoryRequest()];

coerce 'RepeatedCreateRepositoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1beta2::Repository::CreateRepositoryRequest'->new($_) } @$_ ] };

declare 'MapStringCreateRepositoryRequest',
    as HashRef[CreateRepositoryRequest()];

declare 'UpdateRepositoryRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1beta2::Repository::UpdateRepositoryRequest'];

coerce 'UpdateRepositoryRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1beta2::Repository::UpdateRepositoryRequest'->new($_) };

declare 'RepeatedUpdateRepositoryRequest',
    as ArrayRef[UpdateRepositoryRequest()];

coerce 'RepeatedUpdateRepositoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1beta2::Repository::UpdateRepositoryRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateRepositoryRequest',
    as HashRef[UpdateRepositoryRequest()];

declare 'DeleteRepositoryRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1beta2::Repository::DeleteRepositoryRequest'];

coerce 'DeleteRepositoryRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1beta2::Repository::DeleteRepositoryRequest'->new($_) };

declare 'RepeatedDeleteRepositoryRequest',
    as ArrayRef[DeleteRepositoryRequest()];

coerce 'RepeatedDeleteRepositoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1beta2::Repository::DeleteRepositoryRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteRepositoryRequest',
    as HashRef[DeleteRepositoryRequest()];

1;

__END__

=head1 NAME

Google::Devtools::Artifactregistry::V1beta2::Repository::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
