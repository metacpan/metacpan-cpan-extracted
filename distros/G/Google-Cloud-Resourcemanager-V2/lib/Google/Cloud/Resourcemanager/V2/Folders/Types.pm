package Google::Cloud::Resourcemanager::V2::Folders::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Folder',
    as InstanceOf['Google::Cloud::Resourcemanager::V2::Folders::Folder'];

coerce 'Folder',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V2::Folders::Folder'->new($_) };

declare 'RepeatedFolder',
    as ArrayRef[Folder()];

coerce 'RepeatedFolder',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V2::Folders::Folder'->new($_) } @$_ ] };

declare 'MapStringFolder',
    as HashRef[Folder()];

declare 'LifecycleState',
    as (Int | Str);

declare 'ListFoldersRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V2::Folders::ListFoldersRequest'];

coerce 'ListFoldersRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V2::Folders::ListFoldersRequest'->new($_) };

declare 'RepeatedListFoldersRequest',
    as ArrayRef[ListFoldersRequest()];

coerce 'RepeatedListFoldersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V2::Folders::ListFoldersRequest'->new($_) } @$_ ] };

declare 'MapStringListFoldersRequest',
    as HashRef[ListFoldersRequest()];

declare 'ListFoldersResponse',
    as InstanceOf['Google::Cloud::Resourcemanager::V2::Folders::ListFoldersResponse'];

coerce 'ListFoldersResponse',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V2::Folders::ListFoldersResponse'->new($_) };

declare 'RepeatedListFoldersResponse',
    as ArrayRef[ListFoldersResponse()];

coerce 'RepeatedListFoldersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V2::Folders::ListFoldersResponse'->new($_) } @$_ ] };

declare 'MapStringListFoldersResponse',
    as HashRef[ListFoldersResponse()];

declare 'SearchFoldersRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V2::Folders::SearchFoldersRequest'];

coerce 'SearchFoldersRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V2::Folders::SearchFoldersRequest'->new($_) };

declare 'RepeatedSearchFoldersRequest',
    as ArrayRef[SearchFoldersRequest()];

coerce 'RepeatedSearchFoldersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V2::Folders::SearchFoldersRequest'->new($_) } @$_ ] };

declare 'MapStringSearchFoldersRequest',
    as HashRef[SearchFoldersRequest()];

declare 'SearchFoldersResponse',
    as InstanceOf['Google::Cloud::Resourcemanager::V2::Folders::SearchFoldersResponse'];

coerce 'SearchFoldersResponse',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V2::Folders::SearchFoldersResponse'->new($_) };

declare 'RepeatedSearchFoldersResponse',
    as ArrayRef[SearchFoldersResponse()];

coerce 'RepeatedSearchFoldersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V2::Folders::SearchFoldersResponse'->new($_) } @$_ ] };

declare 'MapStringSearchFoldersResponse',
    as HashRef[SearchFoldersResponse()];

declare 'GetFolderRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V2::Folders::GetFolderRequest'];

coerce 'GetFolderRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V2::Folders::GetFolderRequest'->new($_) };

declare 'RepeatedGetFolderRequest',
    as ArrayRef[GetFolderRequest()];

coerce 'RepeatedGetFolderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V2::Folders::GetFolderRequest'->new($_) } @$_ ] };

declare 'MapStringGetFolderRequest',
    as HashRef[GetFolderRequest()];

declare 'CreateFolderRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V2::Folders::CreateFolderRequest'];

coerce 'CreateFolderRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V2::Folders::CreateFolderRequest'->new($_) };

declare 'RepeatedCreateFolderRequest',
    as ArrayRef[CreateFolderRequest()];

coerce 'RepeatedCreateFolderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V2::Folders::CreateFolderRequest'->new($_) } @$_ ] };

declare 'MapStringCreateFolderRequest',
    as HashRef[CreateFolderRequest()];

declare 'MoveFolderRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V2::Folders::MoveFolderRequest'];

coerce 'MoveFolderRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V2::Folders::MoveFolderRequest'->new($_) };

declare 'RepeatedMoveFolderRequest',
    as ArrayRef[MoveFolderRequest()];

coerce 'RepeatedMoveFolderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V2::Folders::MoveFolderRequest'->new($_) } @$_ ] };

declare 'MapStringMoveFolderRequest',
    as HashRef[MoveFolderRequest()];

declare 'UpdateFolderRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V2::Folders::UpdateFolderRequest'];

coerce 'UpdateFolderRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V2::Folders::UpdateFolderRequest'->new($_) };

declare 'RepeatedUpdateFolderRequest',
    as ArrayRef[UpdateFolderRequest()];

coerce 'RepeatedUpdateFolderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V2::Folders::UpdateFolderRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateFolderRequest',
    as HashRef[UpdateFolderRequest()];

declare 'DeleteFolderRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V2::Folders::DeleteFolderRequest'];

coerce 'DeleteFolderRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V2::Folders::DeleteFolderRequest'->new($_) };

declare 'RepeatedDeleteFolderRequest',
    as ArrayRef[DeleteFolderRequest()];

coerce 'RepeatedDeleteFolderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V2::Folders::DeleteFolderRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteFolderRequest',
    as HashRef[DeleteFolderRequest()];

declare 'UndeleteFolderRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V2::Folders::UndeleteFolderRequest'];

coerce 'UndeleteFolderRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V2::Folders::UndeleteFolderRequest'->new($_) };

declare 'RepeatedUndeleteFolderRequest',
    as ArrayRef[UndeleteFolderRequest()];

coerce 'RepeatedUndeleteFolderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V2::Folders::UndeleteFolderRequest'->new($_) } @$_ ] };

declare 'MapStringUndeleteFolderRequest',
    as HashRef[UndeleteFolderRequest()];

declare 'FolderOperation',
    as InstanceOf['Google::Cloud::Resourcemanager::V2::Folders::FolderOperation'];

coerce 'FolderOperation',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V2::Folders::FolderOperation'->new($_) };

declare 'RepeatedFolderOperation',
    as ArrayRef[FolderOperation()];

coerce 'RepeatedFolderOperation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V2::Folders::FolderOperation'->new($_) } @$_ ] };

declare 'MapStringFolderOperation',
    as HashRef[FolderOperation()];

declare 'OperationType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Resourcemanager::V2::Folders::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
