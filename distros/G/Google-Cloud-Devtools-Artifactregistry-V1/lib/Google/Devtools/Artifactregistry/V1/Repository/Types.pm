package Google::Devtools::Artifactregistry::V1::Repository::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'UpstreamPolicy',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::UpstreamPolicy'];

coerce 'UpstreamPolicy',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::UpstreamPolicy'->new($_) };

declare 'RepeatedUpstreamPolicy',
    as ArrayRef[UpstreamPolicy()];

coerce 'RepeatedUpstreamPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::UpstreamPolicy'->new($_) } @$_ ] };

declare 'MapStringUpstreamPolicy',
    as HashRef[UpstreamPolicy()];

declare 'CleanupPolicyCondition',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::CleanupPolicyCondition'];

coerce 'CleanupPolicyCondition',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::CleanupPolicyCondition'->new($_) };

declare 'RepeatedCleanupPolicyCondition',
    as ArrayRef[CleanupPolicyCondition()];

coerce 'RepeatedCleanupPolicyCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::CleanupPolicyCondition'->new($_) } @$_ ] };

declare 'MapStringCleanupPolicyCondition',
    as HashRef[CleanupPolicyCondition()];

declare 'TagState',
    as (Int | Str);

declare 'CleanupPolicyMostRecentVersions',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::CleanupPolicyMostRecentVersions'];

coerce 'CleanupPolicyMostRecentVersions',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::CleanupPolicyMostRecentVersions'->new($_) };

declare 'RepeatedCleanupPolicyMostRecentVersions',
    as ArrayRef[CleanupPolicyMostRecentVersions()];

coerce 'RepeatedCleanupPolicyMostRecentVersions',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::CleanupPolicyMostRecentVersions'->new($_) } @$_ ] };

declare 'MapStringCleanupPolicyMostRecentVersions',
    as HashRef[CleanupPolicyMostRecentVersions()];

declare 'CleanupPolicy',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::CleanupPolicy'];

coerce 'CleanupPolicy',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::CleanupPolicy'->new($_) };

declare 'RepeatedCleanupPolicy',
    as ArrayRef[CleanupPolicy()];

coerce 'RepeatedCleanupPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::CleanupPolicy'->new($_) } @$_ ] };

declare 'MapStringCleanupPolicy',
    as HashRef[CleanupPolicy()];

declare 'Action',
    as (Int | Str);

declare 'VirtualRepositoryConfig',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::VirtualRepositoryConfig'];

coerce 'VirtualRepositoryConfig',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::VirtualRepositoryConfig'->new($_) };

declare 'RepeatedVirtualRepositoryConfig',
    as ArrayRef[VirtualRepositoryConfig()];

coerce 'RepeatedVirtualRepositoryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::VirtualRepositoryConfig'->new($_) } @$_ ] };

declare 'MapStringVirtualRepositoryConfig',
    as HashRef[VirtualRepositoryConfig()];

declare 'RemoteRepositoryConfig',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig'];

coerce 'RemoteRepositoryConfig',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig'->new($_) };

declare 'RepeatedRemoteRepositoryConfig',
    as ArrayRef[RemoteRepositoryConfig()];

coerce 'RepeatedRemoteRepositoryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig'->new($_) } @$_ ] };

declare 'MapStringRemoteRepositoryConfig',
    as HashRef[RemoteRepositoryConfig()];

declare 'UpstreamCredentials',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::UpstreamCredentials'];

coerce 'UpstreamCredentials',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::UpstreamCredentials'->new($_) };

declare 'RepeatedUpstreamCredentials',
    as ArrayRef[UpstreamCredentials()];

coerce 'RepeatedUpstreamCredentials',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::UpstreamCredentials'->new($_) } @$_ ] };

declare 'MapStringUpstreamCredentials',
    as HashRef[UpstreamCredentials()];

declare 'UsernamePasswordCredentials',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::UpstreamCredentials::UsernamePasswordCredentials'];

coerce 'UsernamePasswordCredentials',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::UpstreamCredentials::UsernamePasswordCredentials'->new($_) };

declare 'RepeatedUsernamePasswordCredentials',
    as ArrayRef[UsernamePasswordCredentials()];

coerce 'RepeatedUsernamePasswordCredentials',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::UpstreamCredentials::UsernamePasswordCredentials'->new($_) } @$_ ] };

declare 'MapStringUsernamePasswordCredentials',
    as HashRef[UsernamePasswordCredentials()];

declare 'DockerRepository',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::DockerRepository'];

coerce 'DockerRepository',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::DockerRepository'->new($_) };

declare 'RepeatedDockerRepository',
    as ArrayRef[DockerRepository()];

coerce 'RepeatedDockerRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::DockerRepository'->new($_) } @$_ ] };

declare 'MapStringDockerRepository',
    as HashRef[DockerRepository()];

declare 'PublicRepository',
    as (Int | Str);

declare 'CustomRepository',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::DockerRepository::CustomRepository'];

coerce 'CustomRepository',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::DockerRepository::CustomRepository'->new($_) };

declare 'RepeatedCustomRepository',
    as ArrayRef[CustomRepository()];

coerce 'RepeatedCustomRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::DockerRepository::CustomRepository'->new($_) } @$_ ] };

declare 'MapStringCustomRepository',
    as HashRef[CustomRepository()];

declare 'MavenRepository',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::MavenRepository'];

coerce 'MavenRepository',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::MavenRepository'->new($_) };

declare 'RepeatedMavenRepository',
    as ArrayRef[MavenRepository()];

coerce 'RepeatedMavenRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::MavenRepository'->new($_) } @$_ ] };

declare 'MapStringMavenRepository',
    as HashRef[MavenRepository()];

declare 'PublicRepository',
    as (Int | Str);

declare 'CustomRepository',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::MavenRepository::CustomRepository'];

coerce 'CustomRepository',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::MavenRepository::CustomRepository'->new($_) };

declare 'RepeatedCustomRepository',
    as ArrayRef[CustomRepository()];

coerce 'RepeatedCustomRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::MavenRepository::CustomRepository'->new($_) } @$_ ] };

declare 'MapStringCustomRepository',
    as HashRef[CustomRepository()];

declare 'NpmRepository',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::NpmRepository'];

coerce 'NpmRepository',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::NpmRepository'->new($_) };

declare 'RepeatedNpmRepository',
    as ArrayRef[NpmRepository()];

coerce 'RepeatedNpmRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::NpmRepository'->new($_) } @$_ ] };

declare 'MapStringNpmRepository',
    as HashRef[NpmRepository()];

declare 'PublicRepository',
    as (Int | Str);

declare 'CustomRepository',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::NpmRepository::CustomRepository'];

coerce 'CustomRepository',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::NpmRepository::CustomRepository'->new($_) };

declare 'RepeatedCustomRepository',
    as ArrayRef[CustomRepository()];

coerce 'RepeatedCustomRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::NpmRepository::CustomRepository'->new($_) } @$_ ] };

declare 'MapStringCustomRepository',
    as HashRef[CustomRepository()];

declare 'PythonRepository',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::PythonRepository'];

coerce 'PythonRepository',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::PythonRepository'->new($_) };

declare 'RepeatedPythonRepository',
    as ArrayRef[PythonRepository()];

coerce 'RepeatedPythonRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::PythonRepository'->new($_) } @$_ ] };

declare 'MapStringPythonRepository',
    as HashRef[PythonRepository()];

declare 'PublicRepository',
    as (Int | Str);

declare 'CustomRepository',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::PythonRepository::CustomRepository'];

coerce 'CustomRepository',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::PythonRepository::CustomRepository'->new($_) };

declare 'RepeatedCustomRepository',
    as ArrayRef[CustomRepository()];

coerce 'RepeatedCustomRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::PythonRepository::CustomRepository'->new($_) } @$_ ] };

declare 'MapStringCustomRepository',
    as HashRef[CustomRepository()];

declare 'AptRepository',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::AptRepository'];

coerce 'AptRepository',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::AptRepository'->new($_) };

declare 'RepeatedAptRepository',
    as ArrayRef[AptRepository()];

coerce 'RepeatedAptRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::AptRepository'->new($_) } @$_ ] };

declare 'MapStringAptRepository',
    as HashRef[AptRepository()];

declare 'PublicRepository',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::AptRepository::PublicRepository'];

coerce 'PublicRepository',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::AptRepository::PublicRepository'->new($_) };

declare 'RepeatedPublicRepository',
    as ArrayRef[PublicRepository()];

coerce 'RepeatedPublicRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::AptRepository::PublicRepository'->new($_) } @$_ ] };

declare 'MapStringPublicRepository',
    as HashRef[PublicRepository()];

declare 'RepositoryBase',
    as (Int | Str);

declare 'CustomRepository',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::AptRepository::CustomRepository'];

coerce 'CustomRepository',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::AptRepository::CustomRepository'->new($_) };

declare 'RepeatedCustomRepository',
    as ArrayRef[CustomRepository()];

coerce 'RepeatedCustomRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::AptRepository::CustomRepository'->new($_) } @$_ ] };

declare 'MapStringCustomRepository',
    as HashRef[CustomRepository()];

declare 'YumRepository',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::YumRepository'];

coerce 'YumRepository',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::YumRepository'->new($_) };

declare 'RepeatedYumRepository',
    as ArrayRef[YumRepository()];

coerce 'RepeatedYumRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::YumRepository'->new($_) } @$_ ] };

declare 'MapStringYumRepository',
    as HashRef[YumRepository()];

declare 'PublicRepository',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::YumRepository::PublicRepository'];

coerce 'PublicRepository',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::YumRepository::PublicRepository'->new($_) };

declare 'RepeatedPublicRepository',
    as ArrayRef[PublicRepository()];

coerce 'RepeatedPublicRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::YumRepository::PublicRepository'->new($_) } @$_ ] };

declare 'MapStringPublicRepository',
    as HashRef[PublicRepository()];

declare 'RepositoryBase',
    as (Int | Str);

declare 'CustomRepository',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::YumRepository::CustomRepository'];

coerce 'CustomRepository',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::YumRepository::CustomRepository'->new($_) };

declare 'RepeatedCustomRepository',
    as ArrayRef[CustomRepository()];

coerce 'RepeatedCustomRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::YumRepository::CustomRepository'->new($_) } @$_ ] };

declare 'MapStringCustomRepository',
    as HashRef[CustomRepository()];

declare 'CommonRemoteRepository',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::CommonRemoteRepository'];

coerce 'CommonRemoteRepository',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::CommonRemoteRepository'->new($_) };

declare 'RepeatedCommonRemoteRepository',
    as ArrayRef[CommonRemoteRepository()];

coerce 'RepeatedCommonRemoteRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::RemoteRepositoryConfig::CommonRemoteRepository'->new($_) } @$_ ] };

declare 'MapStringCommonRemoteRepository',
    as HashRef[CommonRemoteRepository()];

declare 'Repository',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::Repository'];

coerce 'Repository',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::Repository'->new($_) };

declare 'RepeatedRepository',
    as ArrayRef[Repository()];

coerce 'RepeatedRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::Repository'->new($_) } @$_ ] };

declare 'MapStringRepository',
    as HashRef[Repository()];

declare 'Format',
    as (Int | Str);

declare 'Mode',
    as (Int | Str);

declare 'MavenRepositoryConfig',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::Repository::MavenRepositoryConfig'];

coerce 'MavenRepositoryConfig',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::Repository::MavenRepositoryConfig'->new($_) };

declare 'RepeatedMavenRepositoryConfig',
    as ArrayRef[MavenRepositoryConfig()];

coerce 'RepeatedMavenRepositoryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::Repository::MavenRepositoryConfig'->new($_) } @$_ ] };

declare 'MapStringMavenRepositoryConfig',
    as HashRef[MavenRepositoryConfig()];

declare 'VersionPolicy',
    as (Int | Str);

declare 'DockerRepositoryConfig',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::Repository::DockerRepositoryConfig'];

coerce 'DockerRepositoryConfig',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::Repository::DockerRepositoryConfig'->new($_) };

declare 'RepeatedDockerRepositoryConfig',
    as ArrayRef[DockerRepositoryConfig()];

coerce 'RepeatedDockerRepositoryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::Repository::DockerRepositoryConfig'->new($_) } @$_ ] };

declare 'MapStringDockerRepositoryConfig',
    as HashRef[DockerRepositoryConfig()];

declare 'VulnerabilityScanningConfig',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::Repository::VulnerabilityScanningConfig'];

coerce 'VulnerabilityScanningConfig',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::Repository::VulnerabilityScanningConfig'->new($_) };

declare 'RepeatedVulnerabilityScanningConfig',
    as ArrayRef[VulnerabilityScanningConfig()];

coerce 'RepeatedVulnerabilityScanningConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::Repository::VulnerabilityScanningConfig'->new($_) } @$_ ] };

declare 'MapStringVulnerabilityScanningConfig',
    as HashRef[VulnerabilityScanningConfig()];

declare 'EnablementConfig',
    as (Int | Str);

declare 'EnablementState',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::Repository::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::Repository::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::Repository::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'CleanupPoliciesEntry',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::Repository::CleanupPoliciesEntry'];

coerce 'CleanupPoliciesEntry',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::Repository::CleanupPoliciesEntry'->new($_) };

declare 'RepeatedCleanupPoliciesEntry',
    as ArrayRef[CleanupPoliciesEntry()];

coerce 'RepeatedCleanupPoliciesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::Repository::CleanupPoliciesEntry'->new($_) } @$_ ] };

declare 'MapStringCleanupPoliciesEntry',
    as HashRef[CleanupPoliciesEntry()];

declare 'ListRepositoriesRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::ListRepositoriesRequest'];

coerce 'ListRepositoriesRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::ListRepositoriesRequest'->new($_) };

declare 'RepeatedListRepositoriesRequest',
    as ArrayRef[ListRepositoriesRequest()];

coerce 'RepeatedListRepositoriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::ListRepositoriesRequest'->new($_) } @$_ ] };

declare 'MapStringListRepositoriesRequest',
    as HashRef[ListRepositoriesRequest()];

declare 'ListRepositoriesResponse',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::ListRepositoriesResponse'];

coerce 'ListRepositoriesResponse',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::ListRepositoriesResponse'->new($_) };

declare 'RepeatedListRepositoriesResponse',
    as ArrayRef[ListRepositoriesResponse()];

coerce 'RepeatedListRepositoriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::ListRepositoriesResponse'->new($_) } @$_ ] };

declare 'MapStringListRepositoriesResponse',
    as HashRef[ListRepositoriesResponse()];

declare 'GetRepositoryRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::GetRepositoryRequest'];

coerce 'GetRepositoryRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::GetRepositoryRequest'->new($_) };

declare 'RepeatedGetRepositoryRequest',
    as ArrayRef[GetRepositoryRequest()];

coerce 'RepeatedGetRepositoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::GetRepositoryRequest'->new($_) } @$_ ] };

declare 'MapStringGetRepositoryRequest',
    as HashRef[GetRepositoryRequest()];

declare 'CreateRepositoryRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::CreateRepositoryRequest'];

coerce 'CreateRepositoryRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::CreateRepositoryRequest'->new($_) };

declare 'RepeatedCreateRepositoryRequest',
    as ArrayRef[CreateRepositoryRequest()];

coerce 'RepeatedCreateRepositoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::CreateRepositoryRequest'->new($_) } @$_ ] };

declare 'MapStringCreateRepositoryRequest',
    as HashRef[CreateRepositoryRequest()];

declare 'UpdateRepositoryRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::UpdateRepositoryRequest'];

coerce 'UpdateRepositoryRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::UpdateRepositoryRequest'->new($_) };

declare 'RepeatedUpdateRepositoryRequest',
    as ArrayRef[UpdateRepositoryRequest()];

coerce 'RepeatedUpdateRepositoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::UpdateRepositoryRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateRepositoryRequest',
    as HashRef[UpdateRepositoryRequest()];

declare 'DeleteRepositoryRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Repository::DeleteRepositoryRequest'];

coerce 'DeleteRepositoryRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Repository::DeleteRepositoryRequest'->new($_) };

declare 'RepeatedDeleteRepositoryRequest',
    as ArrayRef[DeleteRepositoryRequest()];

coerce 'RepeatedDeleteRepositoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Repository::DeleteRepositoryRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteRepositoryRequest',
    as HashRef[DeleteRepositoryRequest()];

1;

__END__

=head1 NAME

Google::Devtools::Artifactregistry::V1::Repository::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
