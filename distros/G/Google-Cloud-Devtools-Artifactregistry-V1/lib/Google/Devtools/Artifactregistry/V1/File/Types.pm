package Google::Devtools::Artifactregistry::V1::File::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Hash',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::File::Hash'];

coerce 'Hash',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::File::Hash'->new($_) };

declare 'RepeatedHash',
    as ArrayRef[Hash()];

coerce 'RepeatedHash',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::File::Hash'->new($_) } @$_ ] };

declare 'MapStringHash',
    as HashRef[Hash()];

declare 'HashType',
    as (Int | Str);

declare 'File',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::File::File'];

coerce 'File',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::File::File'->new($_) };

declare 'RepeatedFile',
    as ArrayRef[File()];

coerce 'RepeatedFile',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::File::File'->new($_) } @$_ ] };

declare 'MapStringFile',
    as HashRef[File()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::File::File::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::File::File::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::File::File::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'ListFilesRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::File::ListFilesRequest'];

coerce 'ListFilesRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::File::ListFilesRequest'->new($_) };

declare 'RepeatedListFilesRequest',
    as ArrayRef[ListFilesRequest()];

coerce 'RepeatedListFilesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::File::ListFilesRequest'->new($_) } @$_ ] };

declare 'MapStringListFilesRequest',
    as HashRef[ListFilesRequest()];

declare 'ListFilesResponse',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::File::ListFilesResponse'];

coerce 'ListFilesResponse',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::File::ListFilesResponse'->new($_) };

declare 'RepeatedListFilesResponse',
    as ArrayRef[ListFilesResponse()];

coerce 'RepeatedListFilesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::File::ListFilesResponse'->new($_) } @$_ ] };

declare 'MapStringListFilesResponse',
    as HashRef[ListFilesResponse()];

declare 'GetFileRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::File::GetFileRequest'];

coerce 'GetFileRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::File::GetFileRequest'->new($_) };

declare 'RepeatedGetFileRequest',
    as ArrayRef[GetFileRequest()];

coerce 'RepeatedGetFileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::File::GetFileRequest'->new($_) } @$_ ] };

declare 'MapStringGetFileRequest',
    as HashRef[GetFileRequest()];

declare 'DeleteFileRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::File::DeleteFileRequest'];

coerce 'DeleteFileRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::File::DeleteFileRequest'->new($_) };

declare 'RepeatedDeleteFileRequest',
    as ArrayRef[DeleteFileRequest()];

coerce 'RepeatedDeleteFileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::File::DeleteFileRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteFileRequest',
    as HashRef[DeleteFileRequest()];

declare 'UpdateFileRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1::File::UpdateFileRequest'];

coerce 'UpdateFileRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1::File::UpdateFileRequest'->new($_) };

declare 'RepeatedUpdateFileRequest',
    as ArrayRef[UpdateFileRequest()];

coerce 'RepeatedUpdateFileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1::File::UpdateFileRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateFileRequest',
    as HashRef[UpdateFileRequest()];

1;

__END__

=head1 NAME

Google::Devtools::Artifactregistry::V1::File::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
