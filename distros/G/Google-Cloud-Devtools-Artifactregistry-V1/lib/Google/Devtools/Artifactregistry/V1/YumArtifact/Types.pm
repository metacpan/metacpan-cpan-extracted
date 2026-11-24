package Google::Devtools::Artifactregistry::V1::YumArtifact::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'YumArtifact',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::YumArtifact::YumArtifact'];

coerce 'YumArtifact',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::YumArtifact::YumArtifact'->new($_) };

declare 'RepeatedYumArtifact',
    as ArrayRef[YumArtifact()];

coerce 'RepeatedYumArtifact',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::YumArtifact::YumArtifact'->new($_) } @$_ ] };

declare 'MapStringYumArtifact',
    as HashRef[YumArtifact()];

declare 'PackageType',
    as (Int | Str);

declare 'ImportYumArtifactsGcsSource',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::YumArtifact::ImportYumArtifactsGcsSource'];

coerce 'ImportYumArtifactsGcsSource',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::YumArtifact::ImportYumArtifactsGcsSource'->new($_) };

declare 'RepeatedImportYumArtifactsGcsSource',
    as ArrayRef[ImportYumArtifactsGcsSource()];

coerce 'RepeatedImportYumArtifactsGcsSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::YumArtifact::ImportYumArtifactsGcsSource'->new($_) } @$_ ] };

declare 'MapStringImportYumArtifactsGcsSource',
    as HashRef[ImportYumArtifactsGcsSource()];

declare 'ImportYumArtifactsRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::YumArtifact::ImportYumArtifactsRequest'];

coerce 'ImportYumArtifactsRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::YumArtifact::ImportYumArtifactsRequest'->new($_) };

declare 'RepeatedImportYumArtifactsRequest',
    as ArrayRef[ImportYumArtifactsRequest()];

coerce 'RepeatedImportYumArtifactsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::YumArtifact::ImportYumArtifactsRequest'->new($_) } @$_ ] };

declare 'MapStringImportYumArtifactsRequest',
    as HashRef[ImportYumArtifactsRequest()];

declare 'ImportYumArtifactsErrorInfo',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::YumArtifact::ImportYumArtifactsErrorInfo'];

coerce 'ImportYumArtifactsErrorInfo',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::YumArtifact::ImportYumArtifactsErrorInfo'->new($_) };

declare 'RepeatedImportYumArtifactsErrorInfo',
    as ArrayRef[ImportYumArtifactsErrorInfo()];

coerce 'RepeatedImportYumArtifactsErrorInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::YumArtifact::ImportYumArtifactsErrorInfo'->new($_) } @$_ ] };

declare 'MapStringImportYumArtifactsErrorInfo',
    as HashRef[ImportYumArtifactsErrorInfo()];

declare 'ImportYumArtifactsResponse',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::YumArtifact::ImportYumArtifactsResponse'];

coerce 'ImportYumArtifactsResponse',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::YumArtifact::ImportYumArtifactsResponse'->new($_) };

declare 'RepeatedImportYumArtifactsResponse',
    as ArrayRef[ImportYumArtifactsResponse()];

coerce 'RepeatedImportYumArtifactsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::YumArtifact::ImportYumArtifactsResponse'->new($_) } @$_ ] };

declare 'MapStringImportYumArtifactsResponse',
    as HashRef[ImportYumArtifactsResponse()];

declare 'ImportYumArtifactsMetadata',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::YumArtifact::ImportYumArtifactsMetadata'];

coerce 'ImportYumArtifactsMetadata',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::YumArtifact::ImportYumArtifactsMetadata'->new($_) };

declare 'RepeatedImportYumArtifactsMetadata',
    as ArrayRef[ImportYumArtifactsMetadata()];

coerce 'RepeatedImportYumArtifactsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::YumArtifact::ImportYumArtifactsMetadata'->new($_) } @$_ ] };

declare 'MapStringImportYumArtifactsMetadata',
    as HashRef[ImportYumArtifactsMetadata()];

1;

__END__

=head1 NAME

Google::Devtools::Artifactregistry::V1::YumArtifact::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
