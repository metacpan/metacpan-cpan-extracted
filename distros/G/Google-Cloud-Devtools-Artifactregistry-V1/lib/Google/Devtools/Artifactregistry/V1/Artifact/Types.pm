package Google::Devtools::Artifactregistry::V1::Artifact::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DockerImage',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Artifact::DockerImage'];

coerce 'DockerImage',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Artifact::DockerImage'->new($_) };

declare 'RepeatedDockerImage',
    as ArrayRef[DockerImage()];

coerce 'RepeatedDockerImage',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Artifact::DockerImage'->new($_) } @$_ ] };

declare 'MapStringDockerImage',
    as HashRef[DockerImage()];

declare 'ImageManifest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Artifact::ImageManifest'];

coerce 'ImageManifest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Artifact::ImageManifest'->new($_) };

declare 'RepeatedImageManifest',
    as ArrayRef[ImageManifest()];

coerce 'RepeatedImageManifest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Artifact::ImageManifest'->new($_) } @$_ ] };

declare 'MapStringImageManifest',
    as HashRef[ImageManifest()];

declare 'ListDockerImagesRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Artifact::ListDockerImagesRequest'];

coerce 'ListDockerImagesRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Artifact::ListDockerImagesRequest'->new($_) };

declare 'RepeatedListDockerImagesRequest',
    as ArrayRef[ListDockerImagesRequest()];

coerce 'RepeatedListDockerImagesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Artifact::ListDockerImagesRequest'->new($_) } @$_ ] };

declare 'MapStringListDockerImagesRequest',
    as HashRef[ListDockerImagesRequest()];

declare 'ListDockerImagesResponse',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Artifact::ListDockerImagesResponse'];

coerce 'ListDockerImagesResponse',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Artifact::ListDockerImagesResponse'->new($_) };

declare 'RepeatedListDockerImagesResponse',
    as ArrayRef[ListDockerImagesResponse()];

coerce 'RepeatedListDockerImagesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Artifact::ListDockerImagesResponse'->new($_) } @$_ ] };

declare 'MapStringListDockerImagesResponse',
    as HashRef[ListDockerImagesResponse()];

declare 'GetDockerImageRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Artifact::GetDockerImageRequest'];

coerce 'GetDockerImageRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Artifact::GetDockerImageRequest'->new($_) };

declare 'RepeatedGetDockerImageRequest',
    as ArrayRef[GetDockerImageRequest()];

coerce 'RepeatedGetDockerImageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Artifact::GetDockerImageRequest'->new($_) } @$_ ] };

declare 'MapStringGetDockerImageRequest',
    as HashRef[GetDockerImageRequest()];

declare 'MavenArtifact',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Artifact::MavenArtifact'];

coerce 'MavenArtifact',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Artifact::MavenArtifact'->new($_) };

declare 'RepeatedMavenArtifact',
    as ArrayRef[MavenArtifact()];

coerce 'RepeatedMavenArtifact',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Artifact::MavenArtifact'->new($_) } @$_ ] };

declare 'MapStringMavenArtifact',
    as HashRef[MavenArtifact()];

declare 'ListMavenArtifactsRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Artifact::ListMavenArtifactsRequest'];

coerce 'ListMavenArtifactsRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Artifact::ListMavenArtifactsRequest'->new($_) };

declare 'RepeatedListMavenArtifactsRequest',
    as ArrayRef[ListMavenArtifactsRequest()];

coerce 'RepeatedListMavenArtifactsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Artifact::ListMavenArtifactsRequest'->new($_) } @$_ ] };

declare 'MapStringListMavenArtifactsRequest',
    as HashRef[ListMavenArtifactsRequest()];

declare 'ListMavenArtifactsResponse',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Artifact::ListMavenArtifactsResponse'];

coerce 'ListMavenArtifactsResponse',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Artifact::ListMavenArtifactsResponse'->new($_) };

declare 'RepeatedListMavenArtifactsResponse',
    as ArrayRef[ListMavenArtifactsResponse()];

coerce 'RepeatedListMavenArtifactsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Artifact::ListMavenArtifactsResponse'->new($_) } @$_ ] };

declare 'MapStringListMavenArtifactsResponse',
    as HashRef[ListMavenArtifactsResponse()];

declare 'GetMavenArtifactRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Artifact::GetMavenArtifactRequest'];

coerce 'GetMavenArtifactRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Artifact::GetMavenArtifactRequest'->new($_) };

declare 'RepeatedGetMavenArtifactRequest',
    as ArrayRef[GetMavenArtifactRequest()];

coerce 'RepeatedGetMavenArtifactRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Artifact::GetMavenArtifactRequest'->new($_) } @$_ ] };

declare 'MapStringGetMavenArtifactRequest',
    as HashRef[GetMavenArtifactRequest()];

declare 'NpmPackage',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Artifact::NpmPackage'];

coerce 'NpmPackage',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Artifact::NpmPackage'->new($_) };

declare 'RepeatedNpmPackage',
    as ArrayRef[NpmPackage()];

coerce 'RepeatedNpmPackage',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Artifact::NpmPackage'->new($_) } @$_ ] };

declare 'MapStringNpmPackage',
    as HashRef[NpmPackage()];

declare 'ListNpmPackagesRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Artifact::ListNpmPackagesRequest'];

coerce 'ListNpmPackagesRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Artifact::ListNpmPackagesRequest'->new($_) };

declare 'RepeatedListNpmPackagesRequest',
    as ArrayRef[ListNpmPackagesRequest()];

coerce 'RepeatedListNpmPackagesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Artifact::ListNpmPackagesRequest'->new($_) } @$_ ] };

declare 'MapStringListNpmPackagesRequest',
    as HashRef[ListNpmPackagesRequest()];

declare 'ListNpmPackagesResponse',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Artifact::ListNpmPackagesResponse'];

coerce 'ListNpmPackagesResponse',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Artifact::ListNpmPackagesResponse'->new($_) };

declare 'RepeatedListNpmPackagesResponse',
    as ArrayRef[ListNpmPackagesResponse()];

coerce 'RepeatedListNpmPackagesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Artifact::ListNpmPackagesResponse'->new($_) } @$_ ] };

declare 'MapStringListNpmPackagesResponse',
    as HashRef[ListNpmPackagesResponse()];

declare 'GetNpmPackageRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Artifact::GetNpmPackageRequest'];

coerce 'GetNpmPackageRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Artifact::GetNpmPackageRequest'->new($_) };

declare 'RepeatedGetNpmPackageRequest',
    as ArrayRef[GetNpmPackageRequest()];

coerce 'RepeatedGetNpmPackageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Artifact::GetNpmPackageRequest'->new($_) } @$_ ] };

declare 'MapStringGetNpmPackageRequest',
    as HashRef[GetNpmPackageRequest()];

declare 'PythonPackage',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Artifact::PythonPackage'];

coerce 'PythonPackage',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Artifact::PythonPackage'->new($_) };

declare 'RepeatedPythonPackage',
    as ArrayRef[PythonPackage()];

coerce 'RepeatedPythonPackage',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Artifact::PythonPackage'->new($_) } @$_ ] };

declare 'MapStringPythonPackage',
    as HashRef[PythonPackage()];

declare 'ListPythonPackagesRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Artifact::ListPythonPackagesRequest'];

coerce 'ListPythonPackagesRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Artifact::ListPythonPackagesRequest'->new($_) };

declare 'RepeatedListPythonPackagesRequest',
    as ArrayRef[ListPythonPackagesRequest()];

coerce 'RepeatedListPythonPackagesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Artifact::ListPythonPackagesRequest'->new($_) } @$_ ] };

declare 'MapStringListPythonPackagesRequest',
    as HashRef[ListPythonPackagesRequest()];

declare 'ListPythonPackagesResponse',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Artifact::ListPythonPackagesResponse'];

coerce 'ListPythonPackagesResponse',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Artifact::ListPythonPackagesResponse'->new($_) };

declare 'RepeatedListPythonPackagesResponse',
    as ArrayRef[ListPythonPackagesResponse()];

coerce 'RepeatedListPythonPackagesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Artifact::ListPythonPackagesResponse'->new($_) } @$_ ] };

declare 'MapStringListPythonPackagesResponse',
    as HashRef[ListPythonPackagesResponse()];

declare 'GetPythonPackageRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Artifact::GetPythonPackageRequest'];

coerce 'GetPythonPackageRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Artifact::GetPythonPackageRequest'->new($_) };

declare 'RepeatedGetPythonPackageRequest',
    as ArrayRef[GetPythonPackageRequest()];

coerce 'RepeatedGetPythonPackageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Artifact::GetPythonPackageRequest'->new($_) } @$_ ] };

declare 'MapStringGetPythonPackageRequest',
    as HashRef[GetPythonPackageRequest()];

1;

__END__

=head1 NAME

Google::Devtools::Artifactregistry::V1::Artifact::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
