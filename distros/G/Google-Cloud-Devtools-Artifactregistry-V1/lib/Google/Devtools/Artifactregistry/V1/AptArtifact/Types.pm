package Google::Devtools::Artifactregistry::V1::AptArtifact::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AptArtifact',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::AptArtifact::AptArtifact'];

coerce 'AptArtifact',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::AptArtifact::AptArtifact'->new($_) };

declare 'RepeatedAptArtifact',
    as ArrayRef[AptArtifact()];

coerce 'RepeatedAptArtifact',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::AptArtifact::AptArtifact'->new($_) } @$_ ] };

declare 'MapStringAptArtifact',
    as HashRef[AptArtifact()];

declare 'PackageType',
    as (Int | Str);

declare 'ImportAptArtifactsGcsSource',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::AptArtifact::ImportAptArtifactsGcsSource'];

coerce 'ImportAptArtifactsGcsSource',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::AptArtifact::ImportAptArtifactsGcsSource'->new($_) };

declare 'RepeatedImportAptArtifactsGcsSource',
    as ArrayRef[ImportAptArtifactsGcsSource()];

coerce 'RepeatedImportAptArtifactsGcsSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::AptArtifact::ImportAptArtifactsGcsSource'->new($_) } @$_ ] };

declare 'MapStringImportAptArtifactsGcsSource',
    as HashRef[ImportAptArtifactsGcsSource()];

declare 'ImportAptArtifactsRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::AptArtifact::ImportAptArtifactsRequest'];

coerce 'ImportAptArtifactsRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::AptArtifact::ImportAptArtifactsRequest'->new($_) };

declare 'RepeatedImportAptArtifactsRequest',
    as ArrayRef[ImportAptArtifactsRequest()];

coerce 'RepeatedImportAptArtifactsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::AptArtifact::ImportAptArtifactsRequest'->new($_) } @$_ ] };

declare 'MapStringImportAptArtifactsRequest',
    as HashRef[ImportAptArtifactsRequest()];

declare 'ImportAptArtifactsErrorInfo',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::AptArtifact::ImportAptArtifactsErrorInfo'];

coerce 'ImportAptArtifactsErrorInfo',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::AptArtifact::ImportAptArtifactsErrorInfo'->new($_) };

declare 'RepeatedImportAptArtifactsErrorInfo',
    as ArrayRef[ImportAptArtifactsErrorInfo()];

coerce 'RepeatedImportAptArtifactsErrorInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::AptArtifact::ImportAptArtifactsErrorInfo'->new($_) } @$_ ] };

declare 'MapStringImportAptArtifactsErrorInfo',
    as HashRef[ImportAptArtifactsErrorInfo()];

declare 'ImportAptArtifactsResponse',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::AptArtifact::ImportAptArtifactsResponse'];

coerce 'ImportAptArtifactsResponse',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::AptArtifact::ImportAptArtifactsResponse'->new($_) };

declare 'RepeatedImportAptArtifactsResponse',
    as ArrayRef[ImportAptArtifactsResponse()];

coerce 'RepeatedImportAptArtifactsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::AptArtifact::ImportAptArtifactsResponse'->new($_) } @$_ ] };

declare 'MapStringImportAptArtifactsResponse',
    as HashRef[ImportAptArtifactsResponse()];

declare 'ImportAptArtifactsMetadata',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::AptArtifact::ImportAptArtifactsMetadata'];

coerce 'ImportAptArtifactsMetadata',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::AptArtifact::ImportAptArtifactsMetadata'->new($_) };

declare 'RepeatedImportAptArtifactsMetadata',
    as ArrayRef[ImportAptArtifactsMetadata()];

coerce 'RepeatedImportAptArtifactsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::AptArtifact::ImportAptArtifactsMetadata'->new($_) } @$_ ] };

declare 'MapStringImportAptArtifactsMetadata',
    as HashRef[ImportAptArtifactsMetadata()];

1;

__END__

=head1 NAME

Google::Devtools::Artifactregistry::V1::AptArtifact::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
