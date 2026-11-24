package Google::Cloud::Resourcemanager::V3::Folders::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Folder',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Folders::Folder'];

coerce 'Folder',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Folders::Folder'->new($_) };

declare 'RepeatedFolder',
    as ArrayRef[Folder()];

coerce 'RepeatedFolder',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Folders::Folder'->new($_) } @$_ ] };

declare 'MapStringFolder',
    as HashRef[Folder()];

declare 'State',
    as (Int | Str);

declare 'GetFolderRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Folders::GetFolderRequest'];

coerce 'GetFolderRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Folders::GetFolderRequest'->new($_) };

declare 'RepeatedGetFolderRequest',
    as ArrayRef[GetFolderRequest()];

coerce 'RepeatedGetFolderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Folders::GetFolderRequest'->new($_) } @$_ ] };

declare 'MapStringGetFolderRequest',
    as HashRef[GetFolderRequest()];

declare 'ListFoldersRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Folders::ListFoldersRequest'];

coerce 'ListFoldersRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Folders::ListFoldersRequest'->new($_) };

declare 'RepeatedListFoldersRequest',
    as ArrayRef[ListFoldersRequest()];

coerce 'RepeatedListFoldersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Folders::ListFoldersRequest'->new($_) } @$_ ] };

declare 'MapStringListFoldersRequest',
    as HashRef[ListFoldersRequest()];

declare 'ListFoldersResponse',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Folders::ListFoldersResponse'];

coerce 'ListFoldersResponse',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Folders::ListFoldersResponse'->new($_) };

declare 'RepeatedListFoldersResponse',
    as ArrayRef[ListFoldersResponse()];

coerce 'RepeatedListFoldersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Folders::ListFoldersResponse'->new($_) } @$_ ] };

declare 'MapStringListFoldersResponse',
    as HashRef[ListFoldersResponse()];

declare 'SearchFoldersRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Folders::SearchFoldersRequest'];

coerce 'SearchFoldersRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Folders::SearchFoldersRequest'->new($_) };

declare 'RepeatedSearchFoldersRequest',
    as ArrayRef[SearchFoldersRequest()];

coerce 'RepeatedSearchFoldersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Folders::SearchFoldersRequest'->new($_) } @$_ ] };

declare 'MapStringSearchFoldersRequest',
    as HashRef[SearchFoldersRequest()];

declare 'SearchFoldersResponse',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Folders::SearchFoldersResponse'];

coerce 'SearchFoldersResponse',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Folders::SearchFoldersResponse'->new($_) };

declare 'RepeatedSearchFoldersResponse',
    as ArrayRef[SearchFoldersResponse()];

coerce 'RepeatedSearchFoldersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Folders::SearchFoldersResponse'->new($_) } @$_ ] };

declare 'MapStringSearchFoldersResponse',
    as HashRef[SearchFoldersResponse()];

declare 'CreateFolderRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Folders::CreateFolderRequest'];

coerce 'CreateFolderRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Folders::CreateFolderRequest'->new($_) };

declare 'RepeatedCreateFolderRequest',
    as ArrayRef[CreateFolderRequest()];

coerce 'RepeatedCreateFolderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Folders::CreateFolderRequest'->new($_) } @$_ ] };

declare 'MapStringCreateFolderRequest',
    as HashRef[CreateFolderRequest()];

declare 'CreateFolderMetadata',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Folders::CreateFolderMetadata'];

coerce 'CreateFolderMetadata',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Folders::CreateFolderMetadata'->new($_) };

declare 'RepeatedCreateFolderMetadata',
    as ArrayRef[CreateFolderMetadata()];

coerce 'RepeatedCreateFolderMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Folders::CreateFolderMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateFolderMetadata',
    as HashRef[CreateFolderMetadata()];

declare 'UpdateFolderRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Folders::UpdateFolderRequest'];

coerce 'UpdateFolderRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Folders::UpdateFolderRequest'->new($_) };

declare 'RepeatedUpdateFolderRequest',
    as ArrayRef[UpdateFolderRequest()];

coerce 'RepeatedUpdateFolderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Folders::UpdateFolderRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateFolderRequest',
    as HashRef[UpdateFolderRequest()];

declare 'UpdateFolderMetadata',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Folders::UpdateFolderMetadata'];

coerce 'UpdateFolderMetadata',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Folders::UpdateFolderMetadata'->new($_) };

declare 'RepeatedUpdateFolderMetadata',
    as ArrayRef[UpdateFolderMetadata()];

coerce 'RepeatedUpdateFolderMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Folders::UpdateFolderMetadata'->new($_) } @$_ ] };

declare 'MapStringUpdateFolderMetadata',
    as HashRef[UpdateFolderMetadata()];

declare 'MoveFolderRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Folders::MoveFolderRequest'];

coerce 'MoveFolderRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Folders::MoveFolderRequest'->new($_) };

declare 'RepeatedMoveFolderRequest',
    as ArrayRef[MoveFolderRequest()];

coerce 'RepeatedMoveFolderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Folders::MoveFolderRequest'->new($_) } @$_ ] };

declare 'MapStringMoveFolderRequest',
    as HashRef[MoveFolderRequest()];

declare 'MoveFolderMetadata',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Folders::MoveFolderMetadata'];

coerce 'MoveFolderMetadata',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Folders::MoveFolderMetadata'->new($_) };

declare 'RepeatedMoveFolderMetadata',
    as ArrayRef[MoveFolderMetadata()];

coerce 'RepeatedMoveFolderMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Folders::MoveFolderMetadata'->new($_) } @$_ ] };

declare 'MapStringMoveFolderMetadata',
    as HashRef[MoveFolderMetadata()];

declare 'DeleteFolderRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Folders::DeleteFolderRequest'];

coerce 'DeleteFolderRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Folders::DeleteFolderRequest'->new($_) };

declare 'RepeatedDeleteFolderRequest',
    as ArrayRef[DeleteFolderRequest()];

coerce 'RepeatedDeleteFolderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Folders::DeleteFolderRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteFolderRequest',
    as HashRef[DeleteFolderRequest()];

declare 'DeleteFolderMetadata',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Folders::DeleteFolderMetadata'];

coerce 'DeleteFolderMetadata',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Folders::DeleteFolderMetadata'->new($_) };

declare 'RepeatedDeleteFolderMetadata',
    as ArrayRef[DeleteFolderMetadata()];

coerce 'RepeatedDeleteFolderMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Folders::DeleteFolderMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteFolderMetadata',
    as HashRef[DeleteFolderMetadata()];

declare 'UndeleteFolderRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Folders::UndeleteFolderRequest'];

coerce 'UndeleteFolderRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Folders::UndeleteFolderRequest'->new($_) };

declare 'RepeatedUndeleteFolderRequest',
    as ArrayRef[UndeleteFolderRequest()];

coerce 'RepeatedUndeleteFolderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Folders::UndeleteFolderRequest'->new($_) } @$_ ] };

declare 'MapStringUndeleteFolderRequest',
    as HashRef[UndeleteFolderRequest()];

declare 'UndeleteFolderMetadata',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Folders::UndeleteFolderMetadata'];

coerce 'UndeleteFolderMetadata',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Folders::UndeleteFolderMetadata'->new($_) };

declare 'RepeatedUndeleteFolderMetadata',
    as ArrayRef[UndeleteFolderMetadata()];

coerce 'RepeatedUndeleteFolderMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Folders::UndeleteFolderMetadata'->new($_) } @$_ ] };

declare 'MapStringUndeleteFolderMetadata',
    as HashRef[UndeleteFolderMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Resourcemanager::V3::Folders::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
