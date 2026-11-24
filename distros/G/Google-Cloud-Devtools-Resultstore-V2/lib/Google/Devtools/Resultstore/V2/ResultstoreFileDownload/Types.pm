package Google::Devtools::Resultstore::V2::ResultstoreFileDownload::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetFileRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileRequest'];

coerce 'GetFileRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileRequest'->new($_) };

declare 'RepeatedGetFileRequest',
    as ArrayRef[GetFileRequest()];

coerce 'RepeatedGetFileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileRequest'->new($_) } @$_ ] };

declare 'MapStringGetFileRequest',
    as HashRef[GetFileRequest()];

declare 'GetFileResponse',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileResponse'];

coerce 'GetFileResponse',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileResponse'->new($_) };

declare 'RepeatedGetFileResponse',
    as ArrayRef[GetFileResponse()];

coerce 'RepeatedGetFileResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileResponse'->new($_) } @$_ ] };

declare 'MapStringGetFileResponse',
    as HashRef[GetFileResponse()];

declare 'GetFileTailRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileTailRequest'];

coerce 'GetFileTailRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileTailRequest'->new($_) };

declare 'RepeatedGetFileTailRequest',
    as ArrayRef[GetFileTailRequest()];

coerce 'RepeatedGetFileTailRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileTailRequest'->new($_) } @$_ ] };

declare 'MapStringGetFileTailRequest',
    as HashRef[GetFileTailRequest()];

declare 'GetFileTailResponse',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileTailResponse'];

coerce 'GetFileTailResponse',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileTailResponse'->new($_) };

declare 'RepeatedGetFileTailResponse',
    as ArrayRef[GetFileTailResponse()];

coerce 'RepeatedGetFileTailResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreFileDownload::GetFileTailResponse'->new($_) } @$_ ] };

declare 'MapStringGetFileTailResponse',
    as HashRef[GetFileTailResponse()];

1;

__END__

=head1 NAME

Google::Devtools::Resultstore::V2::ResultstoreFileDownload::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
