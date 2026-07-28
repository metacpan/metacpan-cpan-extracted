package Google::Devtools::Cloudbuild::V1::Cloudbuild::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetDefaultServiceAccountRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::GetDefaultServiceAccountRequest'];

coerce 'GetDefaultServiceAccountRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::GetDefaultServiceAccountRequest'->new($_) };

declare 'RepeatedGetDefaultServiceAccountRequest',
    as ArrayRef[GetDefaultServiceAccountRequest()];

coerce 'RepeatedGetDefaultServiceAccountRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::GetDefaultServiceAccountRequest'->new($_) } @$_ ] };

declare 'MapStringGetDefaultServiceAccountRequest',
    as HashRef[GetDefaultServiceAccountRequest()];

declare 'DefaultServiceAccount',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::DefaultServiceAccount'];

coerce 'DefaultServiceAccount',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::DefaultServiceAccount'->new($_) };

declare 'RepeatedDefaultServiceAccount',
    as ArrayRef[DefaultServiceAccount()];

coerce 'RepeatedDefaultServiceAccount',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::DefaultServiceAccount'->new($_) } @$_ ] };

declare 'MapStringDefaultServiceAccount',
    as HashRef[DefaultServiceAccount()];

declare 'RetryBuildRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::RetryBuildRequest'];

coerce 'RetryBuildRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::RetryBuildRequest'->new($_) };

declare 'RepeatedRetryBuildRequest',
    as ArrayRef[RetryBuildRequest()];

coerce 'RepeatedRetryBuildRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::RetryBuildRequest'->new($_) } @$_ ] };

declare 'MapStringRetryBuildRequest',
    as HashRef[RetryBuildRequest()];

declare 'RunBuildTriggerRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::RunBuildTriggerRequest'];

coerce 'RunBuildTriggerRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::RunBuildTriggerRequest'->new($_) };

declare 'RepeatedRunBuildTriggerRequest',
    as ArrayRef[RunBuildTriggerRequest()];

coerce 'RepeatedRunBuildTriggerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::RunBuildTriggerRequest'->new($_) } @$_ ] };

declare 'MapStringRunBuildTriggerRequest',
    as HashRef[RunBuildTriggerRequest()];

declare 'StorageSource',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::StorageSource'];

coerce 'StorageSource',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::StorageSource'->new($_) };

declare 'RepeatedStorageSource',
    as ArrayRef[StorageSource()];

coerce 'RepeatedStorageSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::StorageSource'->new($_) } @$_ ] };

declare 'MapStringStorageSource',
    as HashRef[StorageSource()];

declare 'SourceFetcher',
    as (Int | Str);

declare 'GitSource',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::GitSource'];

coerce 'GitSource',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::GitSource'->new($_) };

declare 'RepeatedGitSource',
    as ArrayRef[GitSource()];

coerce 'RepeatedGitSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::GitSource'->new($_) } @$_ ] };

declare 'MapStringGitSource',
    as HashRef[GitSource()];

declare 'RepoSource',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::RepoSource'];

coerce 'RepoSource',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::RepoSource'->new($_) };

declare 'RepeatedRepoSource',
    as ArrayRef[RepoSource()];

coerce 'RepeatedRepoSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::RepoSource'->new($_) } @$_ ] };

declare 'MapStringRepoSource',
    as HashRef[RepoSource()];

declare 'SubstitutionsEntry',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::RepoSource::SubstitutionsEntry'];

coerce 'SubstitutionsEntry',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::RepoSource::SubstitutionsEntry'->new($_) };

declare 'RepeatedSubstitutionsEntry',
    as ArrayRef[SubstitutionsEntry()];

coerce 'RepeatedSubstitutionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::RepoSource::SubstitutionsEntry'->new($_) } @$_ ] };

declare 'MapStringSubstitutionsEntry',
    as HashRef[SubstitutionsEntry()];

declare 'StorageSourceManifest',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::StorageSourceManifest'];

coerce 'StorageSourceManifest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::StorageSourceManifest'->new($_) };

declare 'RepeatedStorageSourceManifest',
    as ArrayRef[StorageSourceManifest()];

coerce 'RepeatedStorageSourceManifest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::StorageSourceManifest'->new($_) } @$_ ] };

declare 'MapStringStorageSourceManifest',
    as HashRef[StorageSourceManifest()];

declare 'ConnectedRepository',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::ConnectedRepository'];

coerce 'ConnectedRepository',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::ConnectedRepository'->new($_) };

declare 'RepeatedConnectedRepository',
    as ArrayRef[ConnectedRepository()];

coerce 'RepeatedConnectedRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::ConnectedRepository'->new($_) } @$_ ] };

declare 'MapStringConnectedRepository',
    as HashRef[ConnectedRepository()];

declare 'Source',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::Source'];

coerce 'Source',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Source'->new($_) };

declare 'RepeatedSource',
    as ArrayRef[Source()];

coerce 'RepeatedSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Source'->new($_) } @$_ ] };

declare 'MapStringSource',
    as HashRef[Source()];

declare 'BuiltImage',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::BuiltImage'];

coerce 'BuiltImage',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::BuiltImage'->new($_) };

declare 'RepeatedBuiltImage',
    as ArrayRef[BuiltImage()];

coerce 'RepeatedBuiltImage',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::BuiltImage'->new($_) } @$_ ] };

declare 'MapStringBuiltImage',
    as HashRef[BuiltImage()];

declare 'UploadedPythonPackage',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::UploadedPythonPackage'];

coerce 'UploadedPythonPackage',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::UploadedPythonPackage'->new($_) };

declare 'RepeatedUploadedPythonPackage',
    as ArrayRef[UploadedPythonPackage()];

coerce 'RepeatedUploadedPythonPackage',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::UploadedPythonPackage'->new($_) } @$_ ] };

declare 'MapStringUploadedPythonPackage',
    as HashRef[UploadedPythonPackage()];

declare 'UploadedMavenArtifact',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::UploadedMavenArtifact'];

coerce 'UploadedMavenArtifact',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::UploadedMavenArtifact'->new($_) };

declare 'RepeatedUploadedMavenArtifact',
    as ArrayRef[UploadedMavenArtifact()];

coerce 'RepeatedUploadedMavenArtifact',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::UploadedMavenArtifact'->new($_) } @$_ ] };

declare 'MapStringUploadedMavenArtifact',
    as HashRef[UploadedMavenArtifact()];

declare 'UploadedGoModule',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::UploadedGoModule'];

coerce 'UploadedGoModule',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::UploadedGoModule'->new($_) };

declare 'RepeatedUploadedGoModule',
    as ArrayRef[UploadedGoModule()];

coerce 'RepeatedUploadedGoModule',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::UploadedGoModule'->new($_) } @$_ ] };

declare 'MapStringUploadedGoModule',
    as HashRef[UploadedGoModule()];

declare 'UploadedNpmPackage',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::UploadedNpmPackage'];

coerce 'UploadedNpmPackage',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::UploadedNpmPackage'->new($_) };

declare 'RepeatedUploadedNpmPackage',
    as ArrayRef[UploadedNpmPackage()];

coerce 'RepeatedUploadedNpmPackage',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::UploadedNpmPackage'->new($_) } @$_ ] };

declare 'MapStringUploadedNpmPackage',
    as HashRef[UploadedNpmPackage()];

declare 'BuildStep',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::BuildStep'];

coerce 'BuildStep',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::BuildStep'->new($_) };

declare 'RepeatedBuildStep',
    as ArrayRef[BuildStep()];

coerce 'RepeatedBuildStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::BuildStep'->new($_) } @$_ ] };

declare 'MapStringBuildStep',
    as HashRef[BuildStep()];

declare 'Volume',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::Volume'];

coerce 'Volume',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Volume'->new($_) };

declare 'RepeatedVolume',
    as ArrayRef[Volume()];

coerce 'RepeatedVolume',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Volume'->new($_) } @$_ ] };

declare 'MapStringVolume',
    as HashRef[Volume()];

declare 'Results',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::Results'];

coerce 'Results',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Results'->new($_) };

declare 'RepeatedResults',
    as ArrayRef[Results()];

coerce 'RepeatedResults',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Results'->new($_) } @$_ ] };

declare 'MapStringResults',
    as HashRef[Results()];

declare 'ArtifactResult',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::ArtifactResult'];

coerce 'ArtifactResult',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::ArtifactResult'->new($_) };

declare 'RepeatedArtifactResult',
    as ArrayRef[ArtifactResult()];

coerce 'RepeatedArtifactResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::ArtifactResult'->new($_) } @$_ ] };

declare 'MapStringArtifactResult',
    as HashRef[ArtifactResult()];

declare 'Build',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::Build'];

coerce 'Build',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Build'->new($_) };

declare 'RepeatedBuild',
    as ArrayRef[Build()];

coerce 'RepeatedBuild',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Build'->new($_) } @$_ ] };

declare 'MapStringBuild',
    as HashRef[Build()];

declare 'Status',
    as (Int | Str);

declare 'Warning',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::Build::Warning'];

coerce 'Warning',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Build::Warning'->new($_) };

declare 'RepeatedWarning',
    as ArrayRef[Warning()];

coerce 'RepeatedWarning',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Build::Warning'->new($_) } @$_ ] };

declare 'MapStringWarning',
    as HashRef[Warning()];

declare 'Priority',
    as (Int | Str);

declare 'FailureInfo',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::Build::FailureInfo'];

coerce 'FailureInfo',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Build::FailureInfo'->new($_) };

declare 'RepeatedFailureInfo',
    as ArrayRef[FailureInfo()];

coerce 'RepeatedFailureInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Build::FailureInfo'->new($_) } @$_ ] };

declare 'MapStringFailureInfo',
    as HashRef[FailureInfo()];

declare 'FailureType',
    as (Int | Str);

declare 'SubstitutionsEntry',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::Build::SubstitutionsEntry'];

coerce 'SubstitutionsEntry',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Build::SubstitutionsEntry'->new($_) };

declare 'RepeatedSubstitutionsEntry',
    as ArrayRef[SubstitutionsEntry()];

coerce 'RepeatedSubstitutionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Build::SubstitutionsEntry'->new($_) } @$_ ] };

declare 'MapStringSubstitutionsEntry',
    as HashRef[SubstitutionsEntry()];

declare 'TimingEntry',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::Build::TimingEntry'];

coerce 'TimingEntry',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Build::TimingEntry'->new($_) };

declare 'RepeatedTimingEntry',
    as ArrayRef[TimingEntry()];

coerce 'RepeatedTimingEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Build::TimingEntry'->new($_) } @$_ ] };

declare 'MapStringTimingEntry',
    as HashRef[TimingEntry()];

declare 'Dependency',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::Dependency'];

coerce 'Dependency',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Dependency'->new($_) };

declare 'RepeatedDependency',
    as ArrayRef[Dependency()];

coerce 'RepeatedDependency',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Dependency'->new($_) } @$_ ] };

declare 'MapStringDependency',
    as HashRef[Dependency()];

declare 'GitSourceDependency',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::Dependency::GitSourceDependency'];

coerce 'GitSourceDependency',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Dependency::GitSourceDependency'->new($_) };

declare 'RepeatedGitSourceDependency',
    as ArrayRef[GitSourceDependency()];

coerce 'RepeatedGitSourceDependency',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Dependency::GitSourceDependency'->new($_) } @$_ ] };

declare 'MapStringGitSourceDependency',
    as HashRef[GitSourceDependency()];

declare 'GitSourceRepository',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::Dependency::GitSourceRepository'];

coerce 'GitSourceRepository',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Dependency::GitSourceRepository'->new($_) };

declare 'RepeatedGitSourceRepository',
    as ArrayRef[GitSourceRepository()];

coerce 'RepeatedGitSourceRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Dependency::GitSourceRepository'->new($_) } @$_ ] };

declare 'MapStringGitSourceRepository',
    as HashRef[GitSourceRepository()];

declare 'GitConfig',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::GitConfig'];

coerce 'GitConfig',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::GitConfig'->new($_) };

declare 'RepeatedGitConfig',
    as ArrayRef[GitConfig()];

coerce 'RepeatedGitConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::GitConfig'->new($_) } @$_ ] };

declare 'MapStringGitConfig',
    as HashRef[GitConfig()];

declare 'HttpConfig',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::GitConfig::HttpConfig'];

coerce 'HttpConfig',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::GitConfig::HttpConfig'->new($_) };

declare 'RepeatedHttpConfig',
    as ArrayRef[HttpConfig()];

coerce 'RepeatedHttpConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::GitConfig::HttpConfig'->new($_) } @$_ ] };

declare 'MapStringHttpConfig',
    as HashRef[HttpConfig()];

declare 'Artifacts',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::Artifacts'];

coerce 'Artifacts',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Artifacts'->new($_) };

declare 'RepeatedArtifacts',
    as ArrayRef[Artifacts()];

coerce 'RepeatedArtifacts',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Artifacts'->new($_) } @$_ ] };

declare 'MapStringArtifacts',
    as HashRef[Artifacts()];

declare 'ArtifactObjects',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::Artifacts::ArtifactObjects'];

coerce 'ArtifactObjects',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Artifacts::ArtifactObjects'->new($_) };

declare 'RepeatedArtifactObjects',
    as ArrayRef[ArtifactObjects()];

coerce 'RepeatedArtifactObjects',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Artifacts::ArtifactObjects'->new($_) } @$_ ] };

declare 'MapStringArtifactObjects',
    as HashRef[ArtifactObjects()];

declare 'MavenArtifact',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::Artifacts::MavenArtifact'];

coerce 'MavenArtifact',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Artifacts::MavenArtifact'->new($_) };

declare 'RepeatedMavenArtifact',
    as ArrayRef[MavenArtifact()];

coerce 'RepeatedMavenArtifact',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Artifacts::MavenArtifact'->new($_) } @$_ ] };

declare 'MapStringMavenArtifact',
    as HashRef[MavenArtifact()];

declare 'GoModule',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::Artifacts::GoModule'];

coerce 'GoModule',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Artifacts::GoModule'->new($_) };

declare 'RepeatedGoModule',
    as ArrayRef[GoModule()];

coerce 'RepeatedGoModule',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Artifacts::GoModule'->new($_) } @$_ ] };

declare 'MapStringGoModule',
    as HashRef[GoModule()];

declare 'PythonPackage',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::Artifacts::PythonPackage'];

coerce 'PythonPackage',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Artifacts::PythonPackage'->new($_) };

declare 'RepeatedPythonPackage',
    as ArrayRef[PythonPackage()];

coerce 'RepeatedPythonPackage',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Artifacts::PythonPackage'->new($_) } @$_ ] };

declare 'MapStringPythonPackage',
    as HashRef[PythonPackage()];

declare 'NpmPackage',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::Artifacts::NpmPackage'];

coerce 'NpmPackage',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Artifacts::NpmPackage'->new($_) };

declare 'RepeatedNpmPackage',
    as ArrayRef[NpmPackage()];

coerce 'RepeatedNpmPackage',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Artifacts::NpmPackage'->new($_) } @$_ ] };

declare 'MapStringNpmPackage',
    as HashRef[NpmPackage()];

declare 'TimeSpan',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::TimeSpan'];

coerce 'TimeSpan',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::TimeSpan'->new($_) };

declare 'RepeatedTimeSpan',
    as ArrayRef[TimeSpan()];

coerce 'RepeatedTimeSpan',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::TimeSpan'->new($_) } @$_ ] };

declare 'MapStringTimeSpan',
    as HashRef[TimeSpan()];

declare 'BuildOperationMetadata',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::BuildOperationMetadata'];

coerce 'BuildOperationMetadata',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::BuildOperationMetadata'->new($_) };

declare 'RepeatedBuildOperationMetadata',
    as ArrayRef[BuildOperationMetadata()];

coerce 'RepeatedBuildOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::BuildOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringBuildOperationMetadata',
    as HashRef[BuildOperationMetadata()];

declare 'SourceProvenance',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::SourceProvenance'];

coerce 'SourceProvenance',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::SourceProvenance'->new($_) };

declare 'RepeatedSourceProvenance',
    as ArrayRef[SourceProvenance()];

coerce 'RepeatedSourceProvenance',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::SourceProvenance'->new($_) } @$_ ] };

declare 'MapStringSourceProvenance',
    as HashRef[SourceProvenance()];

declare 'FileHashesEntry',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::SourceProvenance::FileHashesEntry'];

coerce 'FileHashesEntry',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::SourceProvenance::FileHashesEntry'->new($_) };

declare 'RepeatedFileHashesEntry',
    as ArrayRef[FileHashesEntry()];

coerce 'RepeatedFileHashesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::SourceProvenance::FileHashesEntry'->new($_) } @$_ ] };

declare 'MapStringFileHashesEntry',
    as HashRef[FileHashesEntry()];

declare 'FileHashes',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::FileHashes'];

coerce 'FileHashes',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::FileHashes'->new($_) };

declare 'RepeatedFileHashes',
    as ArrayRef[FileHashes()];

coerce 'RepeatedFileHashes',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::FileHashes'->new($_) } @$_ ] };

declare 'MapStringFileHashes',
    as HashRef[FileHashes()];

declare 'Hash',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::Hash'];

coerce 'Hash',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Hash'->new($_) };

declare 'RepeatedHash',
    as ArrayRef[Hash()];

coerce 'RepeatedHash',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Hash'->new($_) } @$_ ] };

declare 'MapStringHash',
    as HashRef[Hash()];

declare 'HashType',
    as (Int | Str);

declare 'Secrets',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::Secrets'];

coerce 'Secrets',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Secrets'->new($_) };

declare 'RepeatedSecrets',
    as ArrayRef[Secrets()];

coerce 'RepeatedSecrets',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Secrets'->new($_) } @$_ ] };

declare 'MapStringSecrets',
    as HashRef[Secrets()];

declare 'InlineSecret',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::InlineSecret'];

coerce 'InlineSecret',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::InlineSecret'->new($_) };

declare 'RepeatedInlineSecret',
    as ArrayRef[InlineSecret()];

coerce 'RepeatedInlineSecret',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::InlineSecret'->new($_) } @$_ ] };

declare 'MapStringInlineSecret',
    as HashRef[InlineSecret()];

declare 'EnvMapEntry',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::InlineSecret::EnvMapEntry'];

coerce 'EnvMapEntry',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::InlineSecret::EnvMapEntry'->new($_) };

declare 'RepeatedEnvMapEntry',
    as ArrayRef[EnvMapEntry()];

coerce 'RepeatedEnvMapEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::InlineSecret::EnvMapEntry'->new($_) } @$_ ] };

declare 'MapStringEnvMapEntry',
    as HashRef[EnvMapEntry()];

declare 'SecretManagerSecret',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::SecretManagerSecret'];

coerce 'SecretManagerSecret',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::SecretManagerSecret'->new($_) };

declare 'RepeatedSecretManagerSecret',
    as ArrayRef[SecretManagerSecret()];

coerce 'RepeatedSecretManagerSecret',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::SecretManagerSecret'->new($_) } @$_ ] };

declare 'MapStringSecretManagerSecret',
    as HashRef[SecretManagerSecret()];

declare 'Secret',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::Secret'];

coerce 'Secret',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Secret'->new($_) };

declare 'RepeatedSecret',
    as ArrayRef[Secret()];

coerce 'RepeatedSecret',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Secret'->new($_) } @$_ ] };

declare 'MapStringSecret',
    as HashRef[Secret()];

declare 'SecretEnvEntry',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::Secret::SecretEnvEntry'];

coerce 'SecretEnvEntry',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Secret::SecretEnvEntry'->new($_) };

declare 'RepeatedSecretEnvEntry',
    as ArrayRef[SecretEnvEntry()];

coerce 'RepeatedSecretEnvEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Secret::SecretEnvEntry'->new($_) } @$_ ] };

declare 'MapStringSecretEnvEntry',
    as HashRef[SecretEnvEntry()];

declare 'CreateBuildRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::CreateBuildRequest'];

coerce 'CreateBuildRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::CreateBuildRequest'->new($_) };

declare 'RepeatedCreateBuildRequest',
    as ArrayRef[CreateBuildRequest()];

coerce 'RepeatedCreateBuildRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::CreateBuildRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBuildRequest',
    as HashRef[CreateBuildRequest()];

declare 'GetBuildRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::GetBuildRequest'];

coerce 'GetBuildRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::GetBuildRequest'->new($_) };

declare 'RepeatedGetBuildRequest',
    as ArrayRef[GetBuildRequest()];

coerce 'RepeatedGetBuildRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::GetBuildRequest'->new($_) } @$_ ] };

declare 'MapStringGetBuildRequest',
    as HashRef[GetBuildRequest()];

declare 'ListBuildsRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::ListBuildsRequest'];

coerce 'ListBuildsRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::ListBuildsRequest'->new($_) };

declare 'RepeatedListBuildsRequest',
    as ArrayRef[ListBuildsRequest()];

coerce 'RepeatedListBuildsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::ListBuildsRequest'->new($_) } @$_ ] };

declare 'MapStringListBuildsRequest',
    as HashRef[ListBuildsRequest()];

declare 'ListBuildsResponse',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::ListBuildsResponse'];

coerce 'ListBuildsResponse',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::ListBuildsResponse'->new($_) };

declare 'RepeatedListBuildsResponse',
    as ArrayRef[ListBuildsResponse()];

coerce 'RepeatedListBuildsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::ListBuildsResponse'->new($_) } @$_ ] };

declare 'MapStringListBuildsResponse',
    as HashRef[ListBuildsResponse()];

declare 'CancelBuildRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::CancelBuildRequest'];

coerce 'CancelBuildRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::CancelBuildRequest'->new($_) };

declare 'RepeatedCancelBuildRequest',
    as ArrayRef[CancelBuildRequest()];

coerce 'RepeatedCancelBuildRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::CancelBuildRequest'->new($_) } @$_ ] };

declare 'MapStringCancelBuildRequest',
    as HashRef[CancelBuildRequest()];

declare 'ApproveBuildRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::ApproveBuildRequest'];

coerce 'ApproveBuildRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::ApproveBuildRequest'->new($_) };

declare 'RepeatedApproveBuildRequest',
    as ArrayRef[ApproveBuildRequest()];

coerce 'RepeatedApproveBuildRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::ApproveBuildRequest'->new($_) } @$_ ] };

declare 'MapStringApproveBuildRequest',
    as HashRef[ApproveBuildRequest()];

declare 'BuildApproval',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::BuildApproval'];

coerce 'BuildApproval',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::BuildApproval'->new($_) };

declare 'RepeatedBuildApproval',
    as ArrayRef[BuildApproval()];

coerce 'RepeatedBuildApproval',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::BuildApproval'->new($_) } @$_ ] };

declare 'MapStringBuildApproval',
    as HashRef[BuildApproval()];

declare 'State',
    as (Int | Str);

declare 'ApprovalConfig',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::ApprovalConfig'];

coerce 'ApprovalConfig',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::ApprovalConfig'->new($_) };

declare 'RepeatedApprovalConfig',
    as ArrayRef[ApprovalConfig()];

coerce 'RepeatedApprovalConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::ApprovalConfig'->new($_) } @$_ ] };

declare 'MapStringApprovalConfig',
    as HashRef[ApprovalConfig()];

declare 'ApprovalResult',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::ApprovalResult'];

coerce 'ApprovalResult',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::ApprovalResult'->new($_) };

declare 'RepeatedApprovalResult',
    as ArrayRef[ApprovalResult()];

coerce 'RepeatedApprovalResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::ApprovalResult'->new($_) } @$_ ] };

declare 'MapStringApprovalResult',
    as HashRef[ApprovalResult()];

declare 'Decision',
    as (Int | Str);

declare 'GitRepoSource',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::GitRepoSource'];

coerce 'GitRepoSource',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::GitRepoSource'->new($_) };

declare 'RepeatedGitRepoSource',
    as ArrayRef[GitRepoSource()];

coerce 'RepeatedGitRepoSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::GitRepoSource'->new($_) } @$_ ] };

declare 'MapStringGitRepoSource',
    as HashRef[GitRepoSource()];

declare 'GitFileSource',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::GitFileSource'];

coerce 'GitFileSource',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::GitFileSource'->new($_) };

declare 'RepeatedGitFileSource',
    as ArrayRef[GitFileSource()];

coerce 'RepeatedGitFileSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::GitFileSource'->new($_) } @$_ ] };

declare 'MapStringGitFileSource',
    as HashRef[GitFileSource()];

declare 'RepoType',
    as (Int | Str);

declare 'BuildTrigger',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::BuildTrigger'];

coerce 'BuildTrigger',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::BuildTrigger'->new($_) };

declare 'RepeatedBuildTrigger',
    as ArrayRef[BuildTrigger()];

coerce 'RepeatedBuildTrigger',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::BuildTrigger'->new($_) } @$_ ] };

declare 'MapStringBuildTrigger',
    as HashRef[BuildTrigger()];

declare 'SubstitutionsEntry',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::BuildTrigger::SubstitutionsEntry'];

coerce 'SubstitutionsEntry',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::BuildTrigger::SubstitutionsEntry'->new($_) };

declare 'RepeatedSubstitutionsEntry',
    as ArrayRef[SubstitutionsEntry()];

coerce 'RepeatedSubstitutionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::BuildTrigger::SubstitutionsEntry'->new($_) } @$_ ] };

declare 'MapStringSubstitutionsEntry',
    as HashRef[SubstitutionsEntry()];

declare 'RepositoryEventConfig',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::RepositoryEventConfig'];

coerce 'RepositoryEventConfig',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::RepositoryEventConfig'->new($_) };

declare 'RepeatedRepositoryEventConfig',
    as ArrayRef[RepositoryEventConfig()];

coerce 'RepeatedRepositoryEventConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::RepositoryEventConfig'->new($_) } @$_ ] };

declare 'MapStringRepositoryEventConfig',
    as HashRef[RepositoryEventConfig()];

declare 'RepositoryType',
    as (Int | Str);

declare 'GitHubEventsConfig',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::GitHubEventsConfig'];

coerce 'GitHubEventsConfig',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::GitHubEventsConfig'->new($_) };

declare 'RepeatedGitHubEventsConfig',
    as ArrayRef[GitHubEventsConfig()];

coerce 'RepeatedGitHubEventsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::GitHubEventsConfig'->new($_) } @$_ ] };

declare 'MapStringGitHubEventsConfig',
    as HashRef[GitHubEventsConfig()];

declare 'PubsubConfig',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::PubsubConfig'];

coerce 'PubsubConfig',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::PubsubConfig'->new($_) };

declare 'RepeatedPubsubConfig',
    as ArrayRef[PubsubConfig()];

coerce 'RepeatedPubsubConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::PubsubConfig'->new($_) } @$_ ] };

declare 'MapStringPubsubConfig',
    as HashRef[PubsubConfig()];

declare 'State',
    as (Int | Str);

declare 'WebhookConfig',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::WebhookConfig'];

coerce 'WebhookConfig',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::WebhookConfig'->new($_) };

declare 'RepeatedWebhookConfig',
    as ArrayRef[WebhookConfig()];

coerce 'RepeatedWebhookConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::WebhookConfig'->new($_) } @$_ ] };

declare 'MapStringWebhookConfig',
    as HashRef[WebhookConfig()];

declare 'State',
    as (Int | Str);

declare 'PullRequestFilter',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::PullRequestFilter'];

coerce 'PullRequestFilter',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::PullRequestFilter'->new($_) };

declare 'RepeatedPullRequestFilter',
    as ArrayRef[PullRequestFilter()];

coerce 'RepeatedPullRequestFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::PullRequestFilter'->new($_) } @$_ ] };

declare 'MapStringPullRequestFilter',
    as HashRef[PullRequestFilter()];

declare 'CommentControl',
    as (Int | Str);

declare 'PushFilter',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::PushFilter'];

coerce 'PushFilter',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::PushFilter'->new($_) };

declare 'RepeatedPushFilter',
    as ArrayRef[PushFilter()];

coerce 'RepeatedPushFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::PushFilter'->new($_) } @$_ ] };

declare 'MapStringPushFilter',
    as HashRef[PushFilter()];

declare 'CreateBuildTriggerRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::CreateBuildTriggerRequest'];

coerce 'CreateBuildTriggerRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::CreateBuildTriggerRequest'->new($_) };

declare 'RepeatedCreateBuildTriggerRequest',
    as ArrayRef[CreateBuildTriggerRequest()];

coerce 'RepeatedCreateBuildTriggerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::CreateBuildTriggerRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBuildTriggerRequest',
    as HashRef[CreateBuildTriggerRequest()];

declare 'GetBuildTriggerRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::GetBuildTriggerRequest'];

coerce 'GetBuildTriggerRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::GetBuildTriggerRequest'->new($_) };

declare 'RepeatedGetBuildTriggerRequest',
    as ArrayRef[GetBuildTriggerRequest()];

coerce 'RepeatedGetBuildTriggerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::GetBuildTriggerRequest'->new($_) } @$_ ] };

declare 'MapStringGetBuildTriggerRequest',
    as HashRef[GetBuildTriggerRequest()];

declare 'ListBuildTriggersRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::ListBuildTriggersRequest'];

coerce 'ListBuildTriggersRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::ListBuildTriggersRequest'->new($_) };

declare 'RepeatedListBuildTriggersRequest',
    as ArrayRef[ListBuildTriggersRequest()];

coerce 'RepeatedListBuildTriggersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::ListBuildTriggersRequest'->new($_) } @$_ ] };

declare 'MapStringListBuildTriggersRequest',
    as HashRef[ListBuildTriggersRequest()];

declare 'ListBuildTriggersResponse',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::ListBuildTriggersResponse'];

coerce 'ListBuildTriggersResponse',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::ListBuildTriggersResponse'->new($_) };

declare 'RepeatedListBuildTriggersResponse',
    as ArrayRef[ListBuildTriggersResponse()];

coerce 'RepeatedListBuildTriggersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::ListBuildTriggersResponse'->new($_) } @$_ ] };

declare 'MapStringListBuildTriggersResponse',
    as HashRef[ListBuildTriggersResponse()];

declare 'DeleteBuildTriggerRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::DeleteBuildTriggerRequest'];

coerce 'DeleteBuildTriggerRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::DeleteBuildTriggerRequest'->new($_) };

declare 'RepeatedDeleteBuildTriggerRequest',
    as ArrayRef[DeleteBuildTriggerRequest()];

coerce 'RepeatedDeleteBuildTriggerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::DeleteBuildTriggerRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBuildTriggerRequest',
    as HashRef[DeleteBuildTriggerRequest()];

declare 'UpdateBuildTriggerRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::UpdateBuildTriggerRequest'];

coerce 'UpdateBuildTriggerRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::UpdateBuildTriggerRequest'->new($_) };

declare 'RepeatedUpdateBuildTriggerRequest',
    as ArrayRef[UpdateBuildTriggerRequest()];

coerce 'RepeatedUpdateBuildTriggerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::UpdateBuildTriggerRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBuildTriggerRequest',
    as HashRef[UpdateBuildTriggerRequest()];

declare 'BuildOptions',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::BuildOptions'];

coerce 'BuildOptions',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::BuildOptions'->new($_) };

declare 'RepeatedBuildOptions',
    as ArrayRef[BuildOptions()];

coerce 'RepeatedBuildOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::BuildOptions'->new($_) } @$_ ] };

declare 'MapStringBuildOptions',
    as HashRef[BuildOptions()];

declare 'VerifyOption',
    as (Int | Str);

declare 'MachineType',
    as (Int | Str);

declare 'SubstitutionOption',
    as (Int | Str);

declare 'LogStreamingOption',
    as (Int | Str);

declare 'LoggingMode',
    as (Int | Str);

declare 'DefaultLogsBucketBehavior',
    as (Int | Str);

declare 'PoolOption',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::BuildOptions::PoolOption'];

coerce 'PoolOption',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::BuildOptions::PoolOption'->new($_) };

declare 'RepeatedPoolOption',
    as ArrayRef[PoolOption()];

coerce 'RepeatedPoolOption',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::BuildOptions::PoolOption'->new($_) } @$_ ] };

declare 'MapStringPoolOption',
    as HashRef[PoolOption()];

declare 'ReceiveTriggerWebhookRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::ReceiveTriggerWebhookRequest'];

coerce 'ReceiveTriggerWebhookRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::ReceiveTriggerWebhookRequest'->new($_) };

declare 'RepeatedReceiveTriggerWebhookRequest',
    as ArrayRef[ReceiveTriggerWebhookRequest()];

coerce 'RepeatedReceiveTriggerWebhookRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::ReceiveTriggerWebhookRequest'->new($_) } @$_ ] };

declare 'MapStringReceiveTriggerWebhookRequest',
    as HashRef[ReceiveTriggerWebhookRequest()];

declare 'ReceiveTriggerWebhookResponse',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::ReceiveTriggerWebhookResponse'];

coerce 'ReceiveTriggerWebhookResponse',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::ReceiveTriggerWebhookResponse'->new($_) };

declare 'RepeatedReceiveTriggerWebhookResponse',
    as ArrayRef[ReceiveTriggerWebhookResponse()];

coerce 'RepeatedReceiveTriggerWebhookResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::ReceiveTriggerWebhookResponse'->new($_) } @$_ ] };

declare 'MapStringReceiveTriggerWebhookResponse',
    as HashRef[ReceiveTriggerWebhookResponse()];

declare 'GitHubEnterpriseConfig',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::GitHubEnterpriseConfig'];

coerce 'GitHubEnterpriseConfig',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::GitHubEnterpriseConfig'->new($_) };

declare 'RepeatedGitHubEnterpriseConfig',
    as ArrayRef[GitHubEnterpriseConfig()];

coerce 'RepeatedGitHubEnterpriseConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::GitHubEnterpriseConfig'->new($_) } @$_ ] };

declare 'MapStringGitHubEnterpriseConfig',
    as HashRef[GitHubEnterpriseConfig()];

declare 'GitHubEnterpriseSecrets',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::GitHubEnterpriseSecrets'];

coerce 'GitHubEnterpriseSecrets',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::GitHubEnterpriseSecrets'->new($_) };

declare 'RepeatedGitHubEnterpriseSecrets',
    as ArrayRef[GitHubEnterpriseSecrets()];

coerce 'RepeatedGitHubEnterpriseSecrets',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::GitHubEnterpriseSecrets'->new($_) } @$_ ] };

declare 'MapStringGitHubEnterpriseSecrets',
    as HashRef[GitHubEnterpriseSecrets()];

declare 'WorkerPool',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::WorkerPool'];

coerce 'WorkerPool',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::WorkerPool'->new($_) };

declare 'RepeatedWorkerPool',
    as ArrayRef[WorkerPool()];

coerce 'RepeatedWorkerPool',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::WorkerPool'->new($_) } @$_ ] };

declare 'MapStringWorkerPool',
    as HashRef[WorkerPool()];

declare 'State',
    as (Int | Str);

declare 'AnnotationsEntry',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::WorkerPool::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::WorkerPool::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::WorkerPool::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'PrivatePoolV1Config',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::PrivatePoolV1Config'];

coerce 'PrivatePoolV1Config',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::PrivatePoolV1Config'->new($_) };

declare 'RepeatedPrivatePoolV1Config',
    as ArrayRef[PrivatePoolV1Config()];

coerce 'RepeatedPrivatePoolV1Config',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::PrivatePoolV1Config'->new($_) } @$_ ] };

declare 'MapStringPrivatePoolV1Config',
    as HashRef[PrivatePoolV1Config()];

declare 'WorkerConfig',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::PrivatePoolV1Config::WorkerConfig'];

coerce 'WorkerConfig',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::PrivatePoolV1Config::WorkerConfig'->new($_) };

declare 'RepeatedWorkerConfig',
    as ArrayRef[WorkerConfig()];

coerce 'RepeatedWorkerConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::PrivatePoolV1Config::WorkerConfig'->new($_) } @$_ ] };

declare 'MapStringWorkerConfig',
    as HashRef[WorkerConfig()];

declare 'NetworkConfig',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::PrivatePoolV1Config::NetworkConfig'];

coerce 'NetworkConfig',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::PrivatePoolV1Config::NetworkConfig'->new($_) };

declare 'RepeatedNetworkConfig',
    as ArrayRef[NetworkConfig()];

coerce 'RepeatedNetworkConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::PrivatePoolV1Config::NetworkConfig'->new($_) } @$_ ] };

declare 'MapStringNetworkConfig',
    as HashRef[NetworkConfig()];

declare 'EgressOption',
    as (Int | Str);

declare 'PrivateServiceConnect',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::PrivatePoolV1Config::PrivateServiceConnect'];

coerce 'PrivateServiceConnect',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::PrivatePoolV1Config::PrivateServiceConnect'->new($_) };

declare 'RepeatedPrivateServiceConnect',
    as ArrayRef[PrivateServiceConnect()];

coerce 'RepeatedPrivateServiceConnect',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::PrivatePoolV1Config::PrivateServiceConnect'->new($_) } @$_ ] };

declare 'MapStringPrivateServiceConnect',
    as HashRef[PrivateServiceConnect()];

declare 'CreateWorkerPoolRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::CreateWorkerPoolRequest'];

coerce 'CreateWorkerPoolRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::CreateWorkerPoolRequest'->new($_) };

declare 'RepeatedCreateWorkerPoolRequest',
    as ArrayRef[CreateWorkerPoolRequest()];

coerce 'RepeatedCreateWorkerPoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::CreateWorkerPoolRequest'->new($_) } @$_ ] };

declare 'MapStringCreateWorkerPoolRequest',
    as HashRef[CreateWorkerPoolRequest()];

declare 'GetWorkerPoolRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::GetWorkerPoolRequest'];

coerce 'GetWorkerPoolRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::GetWorkerPoolRequest'->new($_) };

declare 'RepeatedGetWorkerPoolRequest',
    as ArrayRef[GetWorkerPoolRequest()];

coerce 'RepeatedGetWorkerPoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::GetWorkerPoolRequest'->new($_) } @$_ ] };

declare 'MapStringGetWorkerPoolRequest',
    as HashRef[GetWorkerPoolRequest()];

declare 'DeleteWorkerPoolRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::DeleteWorkerPoolRequest'];

coerce 'DeleteWorkerPoolRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::DeleteWorkerPoolRequest'->new($_) };

declare 'RepeatedDeleteWorkerPoolRequest',
    as ArrayRef[DeleteWorkerPoolRequest()];

coerce 'RepeatedDeleteWorkerPoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::DeleteWorkerPoolRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteWorkerPoolRequest',
    as HashRef[DeleteWorkerPoolRequest()];

declare 'UpdateWorkerPoolRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::UpdateWorkerPoolRequest'];

coerce 'UpdateWorkerPoolRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::UpdateWorkerPoolRequest'->new($_) };

declare 'RepeatedUpdateWorkerPoolRequest',
    as ArrayRef[UpdateWorkerPoolRequest()];

coerce 'RepeatedUpdateWorkerPoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::UpdateWorkerPoolRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateWorkerPoolRequest',
    as HashRef[UpdateWorkerPoolRequest()];

declare 'ListWorkerPoolsRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::ListWorkerPoolsRequest'];

coerce 'ListWorkerPoolsRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::ListWorkerPoolsRequest'->new($_) };

declare 'RepeatedListWorkerPoolsRequest',
    as ArrayRef[ListWorkerPoolsRequest()];

coerce 'RepeatedListWorkerPoolsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::ListWorkerPoolsRequest'->new($_) } @$_ ] };

declare 'MapStringListWorkerPoolsRequest',
    as HashRef[ListWorkerPoolsRequest()];

declare 'ListWorkerPoolsResponse',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::ListWorkerPoolsResponse'];

coerce 'ListWorkerPoolsResponse',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::ListWorkerPoolsResponse'->new($_) };

declare 'RepeatedListWorkerPoolsResponse',
    as ArrayRef[ListWorkerPoolsResponse()];

coerce 'RepeatedListWorkerPoolsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::ListWorkerPoolsResponse'->new($_) } @$_ ] };

declare 'MapStringListWorkerPoolsResponse',
    as HashRef[ListWorkerPoolsResponse()];

declare 'CreateWorkerPoolOperationMetadata',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::CreateWorkerPoolOperationMetadata'];

coerce 'CreateWorkerPoolOperationMetadata',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::CreateWorkerPoolOperationMetadata'->new($_) };

declare 'RepeatedCreateWorkerPoolOperationMetadata',
    as ArrayRef[CreateWorkerPoolOperationMetadata()];

coerce 'RepeatedCreateWorkerPoolOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::CreateWorkerPoolOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateWorkerPoolOperationMetadata',
    as HashRef[CreateWorkerPoolOperationMetadata()];

declare 'UpdateWorkerPoolOperationMetadata',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::UpdateWorkerPoolOperationMetadata'];

coerce 'UpdateWorkerPoolOperationMetadata',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::UpdateWorkerPoolOperationMetadata'->new($_) };

declare 'RepeatedUpdateWorkerPoolOperationMetadata',
    as ArrayRef[UpdateWorkerPoolOperationMetadata()];

coerce 'RepeatedUpdateWorkerPoolOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::UpdateWorkerPoolOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringUpdateWorkerPoolOperationMetadata',
    as HashRef[UpdateWorkerPoolOperationMetadata()];

declare 'DeleteWorkerPoolOperationMetadata',
    as InstanceOf['Google::Devtools::Cloudbuild::V1::Cloudbuild::DeleteWorkerPoolOperationMetadata'];

coerce 'DeleteWorkerPoolOperationMetadata',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::DeleteWorkerPoolOperationMetadata'->new($_) };

declare 'RepeatedDeleteWorkerPoolOperationMetadata',
    as ArrayRef[DeleteWorkerPoolOperationMetadata()];

coerce 'RepeatedDeleteWorkerPoolOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V1::Cloudbuild::DeleteWorkerPoolOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteWorkerPoolOperationMetadata',
    as HashRef[DeleteWorkerPoolOperationMetadata()];

1;

__END__

=head1 NAME

Google::Devtools::Cloudbuild::V1::Cloudbuild::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
