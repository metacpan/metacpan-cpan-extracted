package Google::Devtools::Artifactregistry::V1::Export::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ExportArtifactRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Export::ExportArtifactRequest'];

coerce 'ExportArtifactRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Export::ExportArtifactRequest'->new($_) };

declare 'RepeatedExportArtifactRequest',
    as ArrayRef[ExportArtifactRequest()];

coerce 'RepeatedExportArtifactRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Export::ExportArtifactRequest'->new($_) } @$_ ] };

declare 'MapStringExportArtifactRequest',
    as HashRef[ExportArtifactRequest()];

declare 'ExportArtifactResponse',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Export::ExportArtifactResponse'];

coerce 'ExportArtifactResponse',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Export::ExportArtifactResponse'->new($_) };

declare 'RepeatedExportArtifactResponse',
    as ArrayRef[ExportArtifactResponse()];

coerce 'RepeatedExportArtifactResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Export::ExportArtifactResponse'->new($_) } @$_ ] };

declare 'MapStringExportArtifactResponse',
    as HashRef[ExportArtifactResponse()];

declare 'ExportArtifactMetadata',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Export::ExportArtifactMetadata'];

coerce 'ExportArtifactMetadata',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Export::ExportArtifactMetadata'->new($_) };

declare 'RepeatedExportArtifactMetadata',
    as ArrayRef[ExportArtifactMetadata()];

coerce 'RepeatedExportArtifactMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Export::ExportArtifactMetadata'->new($_) } @$_ ] };

declare 'MapStringExportArtifactMetadata',
    as HashRef[ExportArtifactMetadata()];

declare 'ExportedFile',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Export::ExportArtifactMetadata::ExportedFile'];

coerce 'ExportedFile',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Export::ExportArtifactMetadata::ExportedFile'->new($_) };

declare 'RepeatedExportedFile',
    as ArrayRef[ExportedFile()];

coerce 'RepeatedExportedFile',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Export::ExportArtifactMetadata::ExportedFile'->new($_) } @$_ ] };

declare 'MapStringExportedFile',
    as HashRef[ExportedFile()];

1;

__END__

=head1 NAME

Google::Devtools::Artifactregistry::V1::Export::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
