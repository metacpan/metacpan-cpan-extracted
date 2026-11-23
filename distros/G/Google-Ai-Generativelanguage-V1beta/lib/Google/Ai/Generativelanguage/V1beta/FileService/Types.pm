package Google::Ai::Generativelanguage::V1beta::FileService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateFileRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::FileService::CreateFileRequest'];

coerce 'CreateFileRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::FileService::CreateFileRequest'->new($_) };

declare 'RepeatedCreateFileRequest',
    as ArrayRef[CreateFileRequest()];

coerce 'RepeatedCreateFileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::FileService::CreateFileRequest'->new($_) } @$_ ] };

declare 'MapStringCreateFileRequest',
    as HashRef[CreateFileRequest()];

declare 'CreateFileResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::FileService::CreateFileResponse'];

coerce 'CreateFileResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::FileService::CreateFileResponse'->new($_) };

declare 'RepeatedCreateFileResponse',
    as ArrayRef[CreateFileResponse()];

coerce 'RepeatedCreateFileResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::FileService::CreateFileResponse'->new($_) } @$_ ] };

declare 'MapStringCreateFileResponse',
    as HashRef[CreateFileResponse()];

declare 'ListFilesRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::FileService::ListFilesRequest'];

coerce 'ListFilesRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::FileService::ListFilesRequest'->new($_) };

declare 'RepeatedListFilesRequest',
    as ArrayRef[ListFilesRequest()];

coerce 'RepeatedListFilesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::FileService::ListFilesRequest'->new($_) } @$_ ] };

declare 'MapStringListFilesRequest',
    as HashRef[ListFilesRequest()];

declare 'ListFilesResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::FileService::ListFilesResponse'];

coerce 'ListFilesResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::FileService::ListFilesResponse'->new($_) };

declare 'RepeatedListFilesResponse',
    as ArrayRef[ListFilesResponse()];

coerce 'RepeatedListFilesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::FileService::ListFilesResponse'->new($_) } @$_ ] };

declare 'MapStringListFilesResponse',
    as HashRef[ListFilesResponse()];

declare 'GetFileRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::FileService::GetFileRequest'];

coerce 'GetFileRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::FileService::GetFileRequest'->new($_) };

declare 'RepeatedGetFileRequest',
    as ArrayRef[GetFileRequest()];

coerce 'RepeatedGetFileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::FileService::GetFileRequest'->new($_) } @$_ ] };

declare 'MapStringGetFileRequest',
    as HashRef[GetFileRequest()];

declare 'DeleteFileRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::FileService::DeleteFileRequest'];

coerce 'DeleteFileRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::FileService::DeleteFileRequest'->new($_) };

declare 'RepeatedDeleteFileRequest',
    as ArrayRef[DeleteFileRequest()];

coerce 'RepeatedDeleteFileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::FileService::DeleteFileRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteFileRequest',
    as HashRef[DeleteFileRequest()];

declare 'DownloadFileRequest',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::FileService::DownloadFileRequest'];

coerce 'DownloadFileRequest',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::FileService::DownloadFileRequest'->new($_) };

declare 'RepeatedDownloadFileRequest',
    as ArrayRef[DownloadFileRequest()];

coerce 'RepeatedDownloadFileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::FileService::DownloadFileRequest'->new($_) } @$_ ] };

declare 'MapStringDownloadFileRequest',
    as HashRef[DownloadFileRequest()];

declare 'DownloadFileResponse',
    as InstanceOf['Google::Ai::Generativelanguage::V1beta::FileService::DownloadFileResponse'];

coerce 'DownloadFileResponse',
    from HashRef, via { 'Google::Ai::Generativelanguage::V1beta::FileService::DownloadFileResponse'->new($_) };

declare 'RepeatedDownloadFileResponse',
    as ArrayRef[DownloadFileResponse()];

coerce 'RepeatedDownloadFileResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Ai::Generativelanguage::V1beta::FileService::DownloadFileResponse'->new($_) } @$_ ] };

declare 'MapStringDownloadFileResponse',
    as HashRef[DownloadFileResponse()];

1;

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1beta::FileService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
