package Google::Devtools::Artifactregistry::V1::Version::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'VersionView',
    as (Int | Str);

declare 'Version',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Version::Version'];

coerce 'Version',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Version::Version'->new($_) };

declare 'RepeatedVersion',
    as ArrayRef[Version()];

coerce 'RepeatedVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Version::Version'->new($_) } @$_ ] };

declare 'MapStringVersion',
    as HashRef[Version()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Version::Version::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Version::Version::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Version::Version::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'ListVersionsRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Version::ListVersionsRequest'];

coerce 'ListVersionsRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Version::ListVersionsRequest'->new($_) };

declare 'RepeatedListVersionsRequest',
    as ArrayRef[ListVersionsRequest()];

coerce 'RepeatedListVersionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Version::ListVersionsRequest'->new($_) } @$_ ] };

declare 'MapStringListVersionsRequest',
    as HashRef[ListVersionsRequest()];

declare 'ListVersionsResponse',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Version::ListVersionsResponse'];

coerce 'ListVersionsResponse',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Version::ListVersionsResponse'->new($_) };

declare 'RepeatedListVersionsResponse',
    as ArrayRef[ListVersionsResponse()];

coerce 'RepeatedListVersionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Version::ListVersionsResponse'->new($_) } @$_ ] };

declare 'MapStringListVersionsResponse',
    as HashRef[ListVersionsResponse()];

declare 'GetVersionRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Version::GetVersionRequest'];

coerce 'GetVersionRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Version::GetVersionRequest'->new($_) };

declare 'RepeatedGetVersionRequest',
    as ArrayRef[GetVersionRequest()];

coerce 'RepeatedGetVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Version::GetVersionRequest'->new($_) } @$_ ] };

declare 'MapStringGetVersionRequest',
    as HashRef[GetVersionRequest()];

declare 'DeleteVersionRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Version::DeleteVersionRequest'];

coerce 'DeleteVersionRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Version::DeleteVersionRequest'->new($_) };

declare 'RepeatedDeleteVersionRequest',
    as ArrayRef[DeleteVersionRequest()];

coerce 'RepeatedDeleteVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Version::DeleteVersionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteVersionRequest',
    as HashRef[DeleteVersionRequest()];

declare 'BatchDeleteVersionsRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Version::BatchDeleteVersionsRequest'];

coerce 'BatchDeleteVersionsRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Version::BatchDeleteVersionsRequest'->new($_) };

declare 'RepeatedBatchDeleteVersionsRequest',
    as ArrayRef[BatchDeleteVersionsRequest()];

coerce 'RepeatedBatchDeleteVersionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Version::BatchDeleteVersionsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchDeleteVersionsRequest',
    as HashRef[BatchDeleteVersionsRequest()];

declare 'BatchDeleteVersionsMetadata',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Version::BatchDeleteVersionsMetadata'];

coerce 'BatchDeleteVersionsMetadata',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Version::BatchDeleteVersionsMetadata'->new($_) };

declare 'RepeatedBatchDeleteVersionsMetadata',
    as ArrayRef[BatchDeleteVersionsMetadata()];

coerce 'RepeatedBatchDeleteVersionsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Version::BatchDeleteVersionsMetadata'->new($_) } @$_ ] };

declare 'MapStringBatchDeleteVersionsMetadata',
    as HashRef[BatchDeleteVersionsMetadata()];

declare 'UpdateVersionRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::Version::UpdateVersionRequest'];

coerce 'UpdateVersionRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::Version::UpdateVersionRequest'->new($_) };

declare 'RepeatedUpdateVersionRequest',
    as ArrayRef[UpdateVersionRequest()];

coerce 'RepeatedUpdateVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::Version::UpdateVersionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateVersionRequest',
    as HashRef[UpdateVersionRequest()];

1;

__END__

=head1 NAME

Google::Devtools::Artifactregistry::V1::Version::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
