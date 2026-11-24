package Google::Devtools::Artifactregistry::V1beta2::File::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Hash',
    as InstanceOf['Google::Devtools::Artifactregistry::V1beta2::File::Hash'];

coerce 'Hash',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1beta2::File::Hash'->new($_) };

declare 'RepeatedHash',
    as ArrayRef[Hash()];

coerce 'RepeatedHash',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1beta2::File::Hash'->new($_) } @$_ ] };

declare 'MapStringHash',
    as HashRef[Hash()];

declare 'HashType',
    as (Int | Str);

declare 'File',
    as InstanceOf['Google::Devtools::Artifactregistry::V1beta2::File::File'];

coerce 'File',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1beta2::File::File'->new($_) };

declare 'RepeatedFile',
    as ArrayRef[File()];

coerce 'RepeatedFile',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1beta2::File::File'->new($_) } @$_ ] };

declare 'MapStringFile',
    as HashRef[File()];

declare 'ListFilesRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1beta2::File::ListFilesRequest'];

coerce 'ListFilesRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1beta2::File::ListFilesRequest'->new($_) };

declare 'RepeatedListFilesRequest',
    as ArrayRef[ListFilesRequest()];

coerce 'RepeatedListFilesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1beta2::File::ListFilesRequest'->new($_) } @$_ ] };

declare 'MapStringListFilesRequest',
    as HashRef[ListFilesRequest()];

declare 'ListFilesResponse',
    as InstanceOf['Google::Devtools::Artifactregistry::V1beta2::File::ListFilesResponse'];

coerce 'ListFilesResponse',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1beta2::File::ListFilesResponse'->new($_) };

declare 'RepeatedListFilesResponse',
    as ArrayRef[ListFilesResponse()];

coerce 'RepeatedListFilesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1beta2::File::ListFilesResponse'->new($_) } @$_ ] };

declare 'MapStringListFilesResponse',
    as HashRef[ListFilesResponse()];

declare 'GetFileRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1beta2::File::GetFileRequest'];

coerce 'GetFileRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1beta2::File::GetFileRequest'->new($_) };

declare 'RepeatedGetFileRequest',
    as ArrayRef[GetFileRequest()];

coerce 'RepeatedGetFileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1beta2::File::GetFileRequest'->new($_) } @$_ ] };

declare 'MapStringGetFileRequest',
    as HashRef[GetFileRequest()];

1;

__END__

=head1 NAME

Google::Devtools::Artifactregistry::V1beta2::File::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
