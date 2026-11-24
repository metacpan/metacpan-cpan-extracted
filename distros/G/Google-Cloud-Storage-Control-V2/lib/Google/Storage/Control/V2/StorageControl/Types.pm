package Google::Storage::Control::V2::StorageControl::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FindingType',
    as (Int | Str);

declare 'FindingCategory',
    as (Int | Str);

declare 'FindingSeverity',
    as (Int | Str);

declare 'PendingRenameInfo',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::PendingRenameInfo'];

coerce 'PendingRenameInfo',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::PendingRenameInfo'->new($_) };

declare 'RepeatedPendingRenameInfo',
    as ArrayRef[PendingRenameInfo()];

coerce 'RepeatedPendingRenameInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::PendingRenameInfo'->new($_) } @$_ ] };

declare 'MapStringPendingRenameInfo',
    as HashRef[PendingRenameInfo()];

declare 'Folder',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::Folder'];

coerce 'Folder',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::Folder'->new($_) };

declare 'RepeatedFolder',
    as ArrayRef[Folder()];

coerce 'RepeatedFolder',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::Folder'->new($_) } @$_ ] };

declare 'MapStringFolder',
    as HashRef[Folder()];

declare 'GetFolderRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::GetFolderRequest'];

coerce 'GetFolderRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::GetFolderRequest'->new($_) };

declare 'RepeatedGetFolderRequest',
    as ArrayRef[GetFolderRequest()];

coerce 'RepeatedGetFolderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::GetFolderRequest'->new($_) } @$_ ] };

declare 'MapStringGetFolderRequest',
    as HashRef[GetFolderRequest()];

declare 'CreateFolderRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::CreateFolderRequest'];

coerce 'CreateFolderRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::CreateFolderRequest'->new($_) };

declare 'RepeatedCreateFolderRequest',
    as ArrayRef[CreateFolderRequest()];

coerce 'RepeatedCreateFolderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::CreateFolderRequest'->new($_) } @$_ ] };

declare 'MapStringCreateFolderRequest',
    as HashRef[CreateFolderRequest()];

declare 'DeleteFolderRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::DeleteFolderRequest'];

coerce 'DeleteFolderRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::DeleteFolderRequest'->new($_) };

declare 'RepeatedDeleteFolderRequest',
    as ArrayRef[DeleteFolderRequest()];

coerce 'RepeatedDeleteFolderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::DeleteFolderRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteFolderRequest',
    as HashRef[DeleteFolderRequest()];

declare 'ListFoldersRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::ListFoldersRequest'];

coerce 'ListFoldersRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::ListFoldersRequest'->new($_) };

declare 'RepeatedListFoldersRequest',
    as ArrayRef[ListFoldersRequest()];

coerce 'RepeatedListFoldersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::ListFoldersRequest'->new($_) } @$_ ] };

declare 'MapStringListFoldersRequest',
    as HashRef[ListFoldersRequest()];

declare 'ListFoldersResponse',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::ListFoldersResponse'];

coerce 'ListFoldersResponse',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::ListFoldersResponse'->new($_) };

declare 'RepeatedListFoldersResponse',
    as ArrayRef[ListFoldersResponse()];

coerce 'RepeatedListFoldersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::ListFoldersResponse'->new($_) } @$_ ] };

declare 'MapStringListFoldersResponse',
    as HashRef[ListFoldersResponse()];

declare 'RenameFolderRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::RenameFolderRequest'];

coerce 'RenameFolderRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::RenameFolderRequest'->new($_) };

declare 'RepeatedRenameFolderRequest',
    as ArrayRef[RenameFolderRequest()];

coerce 'RepeatedRenameFolderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::RenameFolderRequest'->new($_) } @$_ ] };

declare 'MapStringRenameFolderRequest',
    as HashRef[RenameFolderRequest()];

declare 'DeleteFolderRecursiveRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::DeleteFolderRecursiveRequest'];

coerce 'DeleteFolderRecursiveRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::DeleteFolderRecursiveRequest'->new($_) };

declare 'RepeatedDeleteFolderRecursiveRequest',
    as ArrayRef[DeleteFolderRecursiveRequest()];

coerce 'RepeatedDeleteFolderRecursiveRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::DeleteFolderRecursiveRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteFolderRecursiveRequest',
    as HashRef[DeleteFolderRecursiveRequest()];

declare 'CommonLongRunningOperationMetadata',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::CommonLongRunningOperationMetadata'];

coerce 'CommonLongRunningOperationMetadata',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::CommonLongRunningOperationMetadata'->new($_) };

declare 'RepeatedCommonLongRunningOperationMetadata',
    as ArrayRef[CommonLongRunningOperationMetadata()];

coerce 'RepeatedCommonLongRunningOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::CommonLongRunningOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringCommonLongRunningOperationMetadata',
    as HashRef[CommonLongRunningOperationMetadata()];

declare 'RenameFolderMetadata',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::RenameFolderMetadata'];

coerce 'RenameFolderMetadata',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::RenameFolderMetadata'->new($_) };

declare 'RepeatedRenameFolderMetadata',
    as ArrayRef[RenameFolderMetadata()];

coerce 'RepeatedRenameFolderMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::RenameFolderMetadata'->new($_) } @$_ ] };

declare 'MapStringRenameFolderMetadata',
    as HashRef[RenameFolderMetadata()];

declare 'DeleteFolderRecursiveMetadata',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::DeleteFolderRecursiveMetadata'];

coerce 'DeleteFolderRecursiveMetadata',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::DeleteFolderRecursiveMetadata'->new($_) };

declare 'RepeatedDeleteFolderRecursiveMetadata',
    as ArrayRef[DeleteFolderRecursiveMetadata()];

coerce 'RepeatedDeleteFolderRecursiveMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::DeleteFolderRecursiveMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteFolderRecursiveMetadata',
    as HashRef[DeleteFolderRecursiveMetadata()];

declare 'StorageLayout',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::StorageLayout'];

coerce 'StorageLayout',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::StorageLayout'->new($_) };

declare 'RepeatedStorageLayout',
    as ArrayRef[StorageLayout()];

coerce 'RepeatedStorageLayout',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::StorageLayout'->new($_) } @$_ ] };

declare 'MapStringStorageLayout',
    as HashRef[StorageLayout()];

declare 'CustomPlacementConfig',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::StorageLayout::CustomPlacementConfig'];

coerce 'CustomPlacementConfig',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::StorageLayout::CustomPlacementConfig'->new($_) };

declare 'RepeatedCustomPlacementConfig',
    as ArrayRef[CustomPlacementConfig()];

coerce 'RepeatedCustomPlacementConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::StorageLayout::CustomPlacementConfig'->new($_) } @$_ ] };

declare 'MapStringCustomPlacementConfig',
    as HashRef[CustomPlacementConfig()];

declare 'HierarchicalNamespace',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::StorageLayout::HierarchicalNamespace'];

coerce 'HierarchicalNamespace',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::StorageLayout::HierarchicalNamespace'->new($_) };

declare 'RepeatedHierarchicalNamespace',
    as ArrayRef[HierarchicalNamespace()];

coerce 'RepeatedHierarchicalNamespace',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::StorageLayout::HierarchicalNamespace'->new($_) } @$_ ] };

declare 'MapStringHierarchicalNamespace',
    as HashRef[HierarchicalNamespace()];

declare 'RapidCacheInfo',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::StorageLayout::RapidCacheInfo'];

coerce 'RapidCacheInfo',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::StorageLayout::RapidCacheInfo'->new($_) };

declare 'RepeatedRapidCacheInfo',
    as ArrayRef[RapidCacheInfo()];

coerce 'RepeatedRapidCacheInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::StorageLayout::RapidCacheInfo'->new($_) } @$_ ] };

declare 'MapStringRapidCacheInfo',
    as HashRef[RapidCacheInfo()];

declare 'GetStorageLayoutRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::GetStorageLayoutRequest'];

coerce 'GetStorageLayoutRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::GetStorageLayoutRequest'->new($_) };

declare 'RepeatedGetStorageLayoutRequest',
    as ArrayRef[GetStorageLayoutRequest()];

coerce 'RepeatedGetStorageLayoutRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::GetStorageLayoutRequest'->new($_) } @$_ ] };

declare 'MapStringGetStorageLayoutRequest',
    as HashRef[GetStorageLayoutRequest()];

declare 'ManagedFolder',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::ManagedFolder'];

coerce 'ManagedFolder',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::ManagedFolder'->new($_) };

declare 'RepeatedManagedFolder',
    as ArrayRef[ManagedFolder()];

coerce 'RepeatedManagedFolder',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::ManagedFolder'->new($_) } @$_ ] };

declare 'MapStringManagedFolder',
    as HashRef[ManagedFolder()];

declare 'RapidCacheConfig',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::ManagedFolder::RapidCacheConfig'];

coerce 'RapidCacheConfig',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::ManagedFolder::RapidCacheConfig'->new($_) };

declare 'RepeatedRapidCacheConfig',
    as ArrayRef[RapidCacheConfig()];

coerce 'RepeatedRapidCacheConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::ManagedFolder::RapidCacheConfig'->new($_) } @$_ ] };

declare 'MapStringRapidCacheConfig',
    as HashRef[RapidCacheConfig()];

declare 'RapidCachePolicy',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::ManagedFolder::RapidCacheConfig::RapidCachePolicy'];

coerce 'RapidCachePolicy',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::ManagedFolder::RapidCacheConfig::RapidCachePolicy'->new($_) };

declare 'RepeatedRapidCachePolicy',
    as ArrayRef[RapidCachePolicy()];

coerce 'RepeatedRapidCachePolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::ManagedFolder::RapidCacheConfig::RapidCachePolicy'->new($_) } @$_ ] };

declare 'MapStringRapidCachePolicy',
    as HashRef[RapidCachePolicy()];

declare 'IngestOnWrite',
    as (Int | Str);

declare 'PoliciesEntry',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::ManagedFolder::RapidCacheConfig::PoliciesEntry'];

coerce 'PoliciesEntry',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::ManagedFolder::RapidCacheConfig::PoliciesEntry'->new($_) };

declare 'RepeatedPoliciesEntry',
    as ArrayRef[PoliciesEntry()];

coerce 'RepeatedPoliciesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::ManagedFolder::RapidCacheConfig::PoliciesEntry'->new($_) } @$_ ] };

declare 'MapStringPoliciesEntry',
    as HashRef[PoliciesEntry()];

declare 'GetManagedFolderRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::GetManagedFolderRequest'];

coerce 'GetManagedFolderRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::GetManagedFolderRequest'->new($_) };

declare 'RepeatedGetManagedFolderRequest',
    as ArrayRef[GetManagedFolderRequest()];

coerce 'RepeatedGetManagedFolderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::GetManagedFolderRequest'->new($_) } @$_ ] };

declare 'MapStringGetManagedFolderRequest',
    as HashRef[GetManagedFolderRequest()];

declare 'CreateManagedFolderRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::CreateManagedFolderRequest'];

coerce 'CreateManagedFolderRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::CreateManagedFolderRequest'->new($_) };

declare 'RepeatedCreateManagedFolderRequest',
    as ArrayRef[CreateManagedFolderRequest()];

coerce 'RepeatedCreateManagedFolderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::CreateManagedFolderRequest'->new($_) } @$_ ] };

declare 'MapStringCreateManagedFolderRequest',
    as HashRef[CreateManagedFolderRequest()];

declare 'DeleteManagedFolderRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::DeleteManagedFolderRequest'];

coerce 'DeleteManagedFolderRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::DeleteManagedFolderRequest'->new($_) };

declare 'RepeatedDeleteManagedFolderRequest',
    as ArrayRef[DeleteManagedFolderRequest()];

coerce 'RepeatedDeleteManagedFolderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::DeleteManagedFolderRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteManagedFolderRequest',
    as HashRef[DeleteManagedFolderRequest()];

declare 'ListManagedFoldersRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::ListManagedFoldersRequest'];

coerce 'ListManagedFoldersRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::ListManagedFoldersRequest'->new($_) };

declare 'RepeatedListManagedFoldersRequest',
    as ArrayRef[ListManagedFoldersRequest()];

coerce 'RepeatedListManagedFoldersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::ListManagedFoldersRequest'->new($_) } @$_ ] };

declare 'MapStringListManagedFoldersRequest',
    as HashRef[ListManagedFoldersRequest()];

declare 'ListManagedFoldersResponse',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::ListManagedFoldersResponse'];

coerce 'ListManagedFoldersResponse',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::ListManagedFoldersResponse'->new($_) };

declare 'RepeatedListManagedFoldersResponse',
    as ArrayRef[ListManagedFoldersResponse()];

coerce 'RepeatedListManagedFoldersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::ListManagedFoldersResponse'->new($_) } @$_ ] };

declare 'MapStringListManagedFoldersResponse',
    as HashRef[ListManagedFoldersResponse()];

declare 'UpdateManagedFolderRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::UpdateManagedFolderRequest'];

coerce 'UpdateManagedFolderRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::UpdateManagedFolderRequest'->new($_) };

declare 'RepeatedUpdateManagedFolderRequest',
    as ArrayRef[UpdateManagedFolderRequest()];

coerce 'RepeatedUpdateManagedFolderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::UpdateManagedFolderRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateManagedFolderRequest',
    as HashRef[UpdateManagedFolderRequest()];

declare 'CreateAnywhereCacheMetadata',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::CreateAnywhereCacheMetadata'];

coerce 'CreateAnywhereCacheMetadata',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::CreateAnywhereCacheMetadata'->new($_) };

declare 'RepeatedCreateAnywhereCacheMetadata',
    as ArrayRef[CreateAnywhereCacheMetadata()];

coerce 'RepeatedCreateAnywhereCacheMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::CreateAnywhereCacheMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateAnywhereCacheMetadata',
    as HashRef[CreateAnywhereCacheMetadata()];

declare 'CreateRapidCacheMetadata',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::CreateRapidCacheMetadata'];

coerce 'CreateRapidCacheMetadata',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::CreateRapidCacheMetadata'->new($_) };

declare 'RepeatedCreateRapidCacheMetadata',
    as ArrayRef[CreateRapidCacheMetadata()];

coerce 'RepeatedCreateRapidCacheMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::CreateRapidCacheMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateRapidCacheMetadata',
    as HashRef[CreateRapidCacheMetadata()];

declare 'UpdateAnywhereCacheMetadata',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::UpdateAnywhereCacheMetadata'];

coerce 'UpdateAnywhereCacheMetadata',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::UpdateAnywhereCacheMetadata'->new($_) };

declare 'RepeatedUpdateAnywhereCacheMetadata',
    as ArrayRef[UpdateAnywhereCacheMetadata()];

coerce 'RepeatedUpdateAnywhereCacheMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::UpdateAnywhereCacheMetadata'->new($_) } @$_ ] };

declare 'MapStringUpdateAnywhereCacheMetadata',
    as HashRef[UpdateAnywhereCacheMetadata()];

declare 'UpdateRapidCacheMetadata',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::UpdateRapidCacheMetadata'];

coerce 'UpdateRapidCacheMetadata',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::UpdateRapidCacheMetadata'->new($_) };

declare 'RepeatedUpdateRapidCacheMetadata',
    as ArrayRef[UpdateRapidCacheMetadata()];

coerce 'RepeatedUpdateRapidCacheMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::UpdateRapidCacheMetadata'->new($_) } @$_ ] };

declare 'MapStringUpdateRapidCacheMetadata',
    as HashRef[UpdateRapidCacheMetadata()];

declare 'DisableRapidCacheMetadata',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::DisableRapidCacheMetadata'];

coerce 'DisableRapidCacheMetadata',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::DisableRapidCacheMetadata'->new($_) };

declare 'RepeatedDisableRapidCacheMetadata',
    as ArrayRef[DisableRapidCacheMetadata()];

coerce 'RepeatedDisableRapidCacheMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::DisableRapidCacheMetadata'->new($_) } @$_ ] };

declare 'MapStringDisableRapidCacheMetadata',
    as HashRef[DisableRapidCacheMetadata()];

declare 'AnywhereCache',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::AnywhereCache'];

coerce 'AnywhereCache',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::AnywhereCache'->new($_) };

declare 'RepeatedAnywhereCache',
    as ArrayRef[AnywhereCache()];

coerce 'RepeatedAnywhereCache',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::AnywhereCache'->new($_) } @$_ ] };

declare 'MapStringAnywhereCache',
    as HashRef[AnywhereCache()];

declare 'CreateAnywhereCacheRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::CreateAnywhereCacheRequest'];

coerce 'CreateAnywhereCacheRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::CreateAnywhereCacheRequest'->new($_) };

declare 'RepeatedCreateAnywhereCacheRequest',
    as ArrayRef[CreateAnywhereCacheRequest()];

coerce 'RepeatedCreateAnywhereCacheRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::CreateAnywhereCacheRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAnywhereCacheRequest',
    as HashRef[CreateAnywhereCacheRequest()];

declare 'UpdateAnywhereCacheRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::UpdateAnywhereCacheRequest'];

coerce 'UpdateAnywhereCacheRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::UpdateAnywhereCacheRequest'->new($_) };

declare 'RepeatedUpdateAnywhereCacheRequest',
    as ArrayRef[UpdateAnywhereCacheRequest()];

coerce 'RepeatedUpdateAnywhereCacheRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::UpdateAnywhereCacheRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAnywhereCacheRequest',
    as HashRef[UpdateAnywhereCacheRequest()];

declare 'DisableAnywhereCacheRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::DisableAnywhereCacheRequest'];

coerce 'DisableAnywhereCacheRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::DisableAnywhereCacheRequest'->new($_) };

declare 'RepeatedDisableAnywhereCacheRequest',
    as ArrayRef[DisableAnywhereCacheRequest()];

coerce 'RepeatedDisableAnywhereCacheRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::DisableAnywhereCacheRequest'->new($_) } @$_ ] };

declare 'MapStringDisableAnywhereCacheRequest',
    as HashRef[DisableAnywhereCacheRequest()];

declare 'PauseAnywhereCacheRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::PauseAnywhereCacheRequest'];

coerce 'PauseAnywhereCacheRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::PauseAnywhereCacheRequest'->new($_) };

declare 'RepeatedPauseAnywhereCacheRequest',
    as ArrayRef[PauseAnywhereCacheRequest()];

coerce 'RepeatedPauseAnywhereCacheRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::PauseAnywhereCacheRequest'->new($_) } @$_ ] };

declare 'MapStringPauseAnywhereCacheRequest',
    as HashRef[PauseAnywhereCacheRequest()];

declare 'ResumeAnywhereCacheRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::ResumeAnywhereCacheRequest'];

coerce 'ResumeAnywhereCacheRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::ResumeAnywhereCacheRequest'->new($_) };

declare 'RepeatedResumeAnywhereCacheRequest',
    as ArrayRef[ResumeAnywhereCacheRequest()];

coerce 'RepeatedResumeAnywhereCacheRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::ResumeAnywhereCacheRequest'->new($_) } @$_ ] };

declare 'MapStringResumeAnywhereCacheRequest',
    as HashRef[ResumeAnywhereCacheRequest()];

declare 'GetAnywhereCacheRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::GetAnywhereCacheRequest'];

coerce 'GetAnywhereCacheRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::GetAnywhereCacheRequest'->new($_) };

declare 'RepeatedGetAnywhereCacheRequest',
    as ArrayRef[GetAnywhereCacheRequest()];

coerce 'RepeatedGetAnywhereCacheRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::GetAnywhereCacheRequest'->new($_) } @$_ ] };

declare 'MapStringGetAnywhereCacheRequest',
    as HashRef[GetAnywhereCacheRequest()];

declare 'ListAnywhereCachesRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::ListAnywhereCachesRequest'];

coerce 'ListAnywhereCachesRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::ListAnywhereCachesRequest'->new($_) };

declare 'RepeatedListAnywhereCachesRequest',
    as ArrayRef[ListAnywhereCachesRequest()];

coerce 'RepeatedListAnywhereCachesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::ListAnywhereCachesRequest'->new($_) } @$_ ] };

declare 'MapStringListAnywhereCachesRequest',
    as HashRef[ListAnywhereCachesRequest()];

declare 'ListAnywhereCachesResponse',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::ListAnywhereCachesResponse'];

coerce 'ListAnywhereCachesResponse',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::ListAnywhereCachesResponse'->new($_) };

declare 'RepeatedListAnywhereCachesResponse',
    as ArrayRef[ListAnywhereCachesResponse()];

coerce 'RepeatedListAnywhereCachesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::ListAnywhereCachesResponse'->new($_) } @$_ ] };

declare 'MapStringListAnywhereCachesResponse',
    as HashRef[ListAnywhereCachesResponse()];

declare 'RapidCache',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::RapidCache'];

coerce 'RapidCache',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::RapidCache'->new($_) };

declare 'RepeatedRapidCache',
    as ArrayRef[RapidCache()];

coerce 'RepeatedRapidCache',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::RapidCache'->new($_) } @$_ ] };

declare 'MapStringRapidCache',
    as HashRef[RapidCache()];

declare 'CreateRapidCacheRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::CreateRapidCacheRequest'];

coerce 'CreateRapidCacheRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::CreateRapidCacheRequest'->new($_) };

declare 'RepeatedCreateRapidCacheRequest',
    as ArrayRef[CreateRapidCacheRequest()];

coerce 'RepeatedCreateRapidCacheRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::CreateRapidCacheRequest'->new($_) } @$_ ] };

declare 'MapStringCreateRapidCacheRequest',
    as HashRef[CreateRapidCacheRequest()];

declare 'UpdateRapidCacheRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::UpdateRapidCacheRequest'];

coerce 'UpdateRapidCacheRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::UpdateRapidCacheRequest'->new($_) };

declare 'RepeatedUpdateRapidCacheRequest',
    as ArrayRef[UpdateRapidCacheRequest()];

coerce 'RepeatedUpdateRapidCacheRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::UpdateRapidCacheRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateRapidCacheRequest',
    as HashRef[UpdateRapidCacheRequest()];

declare 'DisableRapidCacheRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::DisableRapidCacheRequest'];

coerce 'DisableRapidCacheRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::DisableRapidCacheRequest'->new($_) };

declare 'RepeatedDisableRapidCacheRequest',
    as ArrayRef[DisableRapidCacheRequest()];

coerce 'RepeatedDisableRapidCacheRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::DisableRapidCacheRequest'->new($_) } @$_ ] };

declare 'MapStringDisableRapidCacheRequest',
    as HashRef[DisableRapidCacheRequest()];

declare 'GetRapidCacheRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::GetRapidCacheRequest'];

coerce 'GetRapidCacheRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::GetRapidCacheRequest'->new($_) };

declare 'RepeatedGetRapidCacheRequest',
    as ArrayRef[GetRapidCacheRequest()];

coerce 'RepeatedGetRapidCacheRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::GetRapidCacheRequest'->new($_) } @$_ ] };

declare 'MapStringGetRapidCacheRequest',
    as HashRef[GetRapidCacheRequest()];

declare 'ListRapidCachesRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::ListRapidCachesRequest'];

coerce 'ListRapidCachesRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::ListRapidCachesRequest'->new($_) };

declare 'RepeatedListRapidCachesRequest',
    as ArrayRef[ListRapidCachesRequest()];

coerce 'RepeatedListRapidCachesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::ListRapidCachesRequest'->new($_) } @$_ ] };

declare 'MapStringListRapidCachesRequest',
    as HashRef[ListRapidCachesRequest()];

declare 'ListRapidCachesResponse',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::ListRapidCachesResponse'];

coerce 'ListRapidCachesResponse',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::ListRapidCachesResponse'->new($_) };

declare 'RepeatedListRapidCachesResponse',
    as ArrayRef[ListRapidCachesResponse()];

coerce 'RepeatedListRapidCachesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::ListRapidCachesResponse'->new($_) } @$_ ] };

declare 'MapStringListRapidCachesResponse',
    as HashRef[ListRapidCachesResponse()];

declare 'IntelligenceConfig',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::IntelligenceConfig'];

coerce 'IntelligenceConfig',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::IntelligenceConfig'->new($_) };

declare 'RepeatedIntelligenceConfig',
    as ArrayRef[IntelligenceConfig()];

coerce 'RepeatedIntelligenceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::IntelligenceConfig'->new($_) } @$_ ] };

declare 'MapStringIntelligenceConfig',
    as HashRef[IntelligenceConfig()];

declare 'EditionConfig',
    as (Int | Str);

declare 'Filter',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::IntelligenceConfig::Filter'];

coerce 'Filter',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::IntelligenceConfig::Filter'->new($_) };

declare 'RepeatedFilter',
    as ArrayRef[Filter()];

coerce 'RepeatedFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::IntelligenceConfig::Filter'->new($_) } @$_ ] };

declare 'MapStringFilter',
    as HashRef[Filter()];

declare 'CloudStorageLocations',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::IntelligenceConfig::Filter::CloudStorageLocations'];

coerce 'CloudStorageLocations',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::IntelligenceConfig::Filter::CloudStorageLocations'->new($_) };

declare 'RepeatedCloudStorageLocations',
    as ArrayRef[CloudStorageLocations()];

coerce 'RepeatedCloudStorageLocations',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::IntelligenceConfig::Filter::CloudStorageLocations'->new($_) } @$_ ] };

declare 'MapStringCloudStorageLocations',
    as HashRef[CloudStorageLocations()];

declare 'CloudStorageBuckets',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::IntelligenceConfig::Filter::CloudStorageBuckets'];

coerce 'CloudStorageBuckets',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::IntelligenceConfig::Filter::CloudStorageBuckets'->new($_) };

declare 'RepeatedCloudStorageBuckets',
    as ArrayRef[CloudStorageBuckets()];

coerce 'RepeatedCloudStorageBuckets',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::IntelligenceConfig::Filter::CloudStorageBuckets'->new($_) } @$_ ] };

declare 'MapStringCloudStorageBuckets',
    as HashRef[CloudStorageBuckets()];

declare 'EffectiveIntelligenceConfig',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::IntelligenceConfig::EffectiveIntelligenceConfig'];

coerce 'EffectiveIntelligenceConfig',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::IntelligenceConfig::EffectiveIntelligenceConfig'->new($_) };

declare 'RepeatedEffectiveIntelligenceConfig',
    as ArrayRef[EffectiveIntelligenceConfig()];

coerce 'RepeatedEffectiveIntelligenceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::IntelligenceConfig::EffectiveIntelligenceConfig'->new($_) } @$_ ] };

declare 'MapStringEffectiveIntelligenceConfig',
    as HashRef[EffectiveIntelligenceConfig()];

declare 'EffectiveEdition',
    as (Int | Str);

declare 'TrialConfig',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::IntelligenceConfig::TrialConfig'];

coerce 'TrialConfig',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::IntelligenceConfig::TrialConfig'->new($_) };

declare 'RepeatedTrialConfig',
    as ArrayRef[TrialConfig()];

coerce 'RepeatedTrialConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::IntelligenceConfig::TrialConfig'->new($_) } @$_ ] };

declare 'MapStringTrialConfig',
    as HashRef[TrialConfig()];

declare 'UpdateOrganizationIntelligenceConfigRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::UpdateOrganizationIntelligenceConfigRequest'];

coerce 'UpdateOrganizationIntelligenceConfigRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::UpdateOrganizationIntelligenceConfigRequest'->new($_) };

declare 'RepeatedUpdateOrganizationIntelligenceConfigRequest',
    as ArrayRef[UpdateOrganizationIntelligenceConfigRequest()];

coerce 'RepeatedUpdateOrganizationIntelligenceConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::UpdateOrganizationIntelligenceConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateOrganizationIntelligenceConfigRequest',
    as HashRef[UpdateOrganizationIntelligenceConfigRequest()];

declare 'UpdateFolderIntelligenceConfigRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::UpdateFolderIntelligenceConfigRequest'];

coerce 'UpdateFolderIntelligenceConfigRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::UpdateFolderIntelligenceConfigRequest'->new($_) };

declare 'RepeatedUpdateFolderIntelligenceConfigRequest',
    as ArrayRef[UpdateFolderIntelligenceConfigRequest()];

coerce 'RepeatedUpdateFolderIntelligenceConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::UpdateFolderIntelligenceConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateFolderIntelligenceConfigRequest',
    as HashRef[UpdateFolderIntelligenceConfigRequest()];

declare 'UpdateProjectIntelligenceConfigRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::UpdateProjectIntelligenceConfigRequest'];

coerce 'UpdateProjectIntelligenceConfigRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::UpdateProjectIntelligenceConfigRequest'->new($_) };

declare 'RepeatedUpdateProjectIntelligenceConfigRequest',
    as ArrayRef[UpdateProjectIntelligenceConfigRequest()];

coerce 'RepeatedUpdateProjectIntelligenceConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::UpdateProjectIntelligenceConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateProjectIntelligenceConfigRequest',
    as HashRef[UpdateProjectIntelligenceConfigRequest()];

declare 'GetOrganizationIntelligenceConfigRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::GetOrganizationIntelligenceConfigRequest'];

coerce 'GetOrganizationIntelligenceConfigRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::GetOrganizationIntelligenceConfigRequest'->new($_) };

declare 'RepeatedGetOrganizationIntelligenceConfigRequest',
    as ArrayRef[GetOrganizationIntelligenceConfigRequest()];

coerce 'RepeatedGetOrganizationIntelligenceConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::GetOrganizationIntelligenceConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetOrganizationIntelligenceConfigRequest',
    as HashRef[GetOrganizationIntelligenceConfigRequest()];

declare 'GetFolderIntelligenceConfigRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::GetFolderIntelligenceConfigRequest'];

coerce 'GetFolderIntelligenceConfigRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::GetFolderIntelligenceConfigRequest'->new($_) };

declare 'RepeatedGetFolderIntelligenceConfigRequest',
    as ArrayRef[GetFolderIntelligenceConfigRequest()];

coerce 'RepeatedGetFolderIntelligenceConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::GetFolderIntelligenceConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetFolderIntelligenceConfigRequest',
    as HashRef[GetFolderIntelligenceConfigRequest()];

declare 'GetProjectIntelligenceConfigRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::GetProjectIntelligenceConfigRequest'];

coerce 'GetProjectIntelligenceConfigRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::GetProjectIntelligenceConfigRequest'->new($_) };

declare 'RepeatedGetProjectIntelligenceConfigRequest',
    as ArrayRef[GetProjectIntelligenceConfigRequest()];

coerce 'RepeatedGetProjectIntelligenceConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::GetProjectIntelligenceConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetProjectIntelligenceConfigRequest',
    as HashRef[GetProjectIntelligenceConfigRequest()];

declare 'IntelligenceFinding',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::IntelligenceFinding'];

coerce 'IntelligenceFinding',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::IntelligenceFinding'->new($_) };

declare 'RepeatedIntelligenceFinding',
    as ArrayRef[IntelligenceFinding()];

coerce 'RepeatedIntelligenceFinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::IntelligenceFinding'->new($_) } @$_ ] };

declare 'MapStringIntelligenceFinding',
    as HashRef[IntelligenceFinding()];

declare 'ColdlineAndArchivalStorageOperationsSpike',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::IntelligenceFinding::ColdlineAndArchivalStorageOperationsSpike'];

coerce 'ColdlineAndArchivalStorageOperationsSpike',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::IntelligenceFinding::ColdlineAndArchivalStorageOperationsSpike'->new($_) };

declare 'RepeatedColdlineAndArchivalStorageOperationsSpike',
    as ArrayRef[ColdlineAndArchivalStorageOperationsSpike()];

coerce 'RepeatedColdlineAndArchivalStorageOperationsSpike',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::IntelligenceFinding::ColdlineAndArchivalStorageOperationsSpike'->new($_) } @$_ ] };

declare 'MapStringColdlineAndArchivalStorageOperationsSpike',
    as HashRef[ColdlineAndArchivalStorageOperationsSpike()];

declare 'BucketContribution',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::IntelligenceFinding::ColdlineAndArchivalStorageOperationsSpike::BucketContribution'];

coerce 'BucketContribution',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::IntelligenceFinding::ColdlineAndArchivalStorageOperationsSpike::BucketContribution'->new($_) };

declare 'RepeatedBucketContribution',
    as ArrayRef[BucketContribution()];

coerce 'RepeatedBucketContribution',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::IntelligenceFinding::ColdlineAndArchivalStorageOperationsSpike::BucketContribution'->new($_) } @$_ ] };

declare 'MapStringBucketContribution',
    as HashRef[BucketContribution()];

declare 'Contribution',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::IntelligenceFinding::ColdlineAndArchivalStorageOperationsSpike::BucketContribution::Contribution'];

coerce 'Contribution',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::IntelligenceFinding::ColdlineAndArchivalStorageOperationsSpike::BucketContribution::Contribution'->new($_) };

declare 'RepeatedContribution',
    as ArrayRef[Contribution()];

coerce 'RepeatedContribution',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::IntelligenceFinding::ColdlineAndArchivalStorageOperationsSpike::BucketContribution::Contribution'->new($_) } @$_ ] };

declare 'MapStringContribution',
    as HashRef[Contribution()];

declare 'PrefixContribution',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::IntelligenceFinding::ColdlineAndArchivalStorageOperationsSpike::BucketContribution::Contribution::PrefixContribution'];

coerce 'PrefixContribution',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::IntelligenceFinding::ColdlineAndArchivalStorageOperationsSpike::BucketContribution::Contribution::PrefixContribution'->new($_) };

declare 'RepeatedPrefixContribution',
    as ArrayRef[PrefixContribution()];

coerce 'RepeatedPrefixContribution',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::IntelligenceFinding::ColdlineAndArchivalStorageOperationsSpike::BucketContribution::Contribution::PrefixContribution'->new($_) } @$_ ] };

declare 'MapStringPrefixContribution',
    as HashRef[PrefixContribution()];

declare 'CrossRegionEgressSpike',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::IntelligenceFinding::CrossRegionEgressSpike'];

coerce 'CrossRegionEgressSpike',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::IntelligenceFinding::CrossRegionEgressSpike'->new($_) };

declare 'RepeatedCrossRegionEgressSpike',
    as ArrayRef[CrossRegionEgressSpike()];

coerce 'RepeatedCrossRegionEgressSpike',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::IntelligenceFinding::CrossRegionEgressSpike'->new($_) } @$_ ] };

declare 'MapStringCrossRegionEgressSpike',
    as HashRef[CrossRegionEgressSpike()];

declare 'BucketContribution',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::IntelligenceFinding::CrossRegionEgressSpike::BucketContribution'];

coerce 'BucketContribution',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::IntelligenceFinding::CrossRegionEgressSpike::BucketContribution'->new($_) };

declare 'RepeatedBucketContribution',
    as ArrayRef[BucketContribution()];

coerce 'RepeatedBucketContribution',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::IntelligenceFinding::CrossRegionEgressSpike::BucketContribution'->new($_) } @$_ ] };

declare 'MapStringBucketContribution',
    as HashRef[BucketContribution()];

declare 'Contribution',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::IntelligenceFinding::CrossRegionEgressSpike::BucketContribution::Contribution'];

coerce 'Contribution',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::IntelligenceFinding::CrossRegionEgressSpike::BucketContribution::Contribution'->new($_) };

declare 'RepeatedContribution',
    as ArrayRef[Contribution()];

coerce 'RepeatedContribution',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::IntelligenceFinding::CrossRegionEgressSpike::BucketContribution::Contribution'->new($_) } @$_ ] };

declare 'MapStringContribution',
    as HashRef[Contribution()];

declare 'PrefixContribution',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::IntelligenceFinding::CrossRegionEgressSpike::BucketContribution::Contribution::PrefixContribution'];

coerce 'PrefixContribution',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::IntelligenceFinding::CrossRegionEgressSpike::BucketContribution::Contribution::PrefixContribution'->new($_) };

declare 'RepeatedPrefixContribution',
    as ArrayRef[PrefixContribution()];

coerce 'RepeatedPrefixContribution',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::IntelligenceFinding::CrossRegionEgressSpike::BucketContribution::Contribution::PrefixContribution'->new($_) } @$_ ] };

declare 'MapStringPrefixContribution',
    as HashRef[PrefixContribution()];

declare 'ThrottledRequestSpike',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::IntelligenceFinding::ThrottledRequestSpike'];

coerce 'ThrottledRequestSpike',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::IntelligenceFinding::ThrottledRequestSpike'->new($_) };

declare 'RepeatedThrottledRequestSpike',
    as ArrayRef[ThrottledRequestSpike()];

coerce 'RepeatedThrottledRequestSpike',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::IntelligenceFinding::ThrottledRequestSpike'->new($_) } @$_ ] };

declare 'MapStringThrottledRequestSpike',
    as HashRef[ThrottledRequestSpike()];

declare 'BucketContribution',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::IntelligenceFinding::ThrottledRequestSpike::BucketContribution'];

coerce 'BucketContribution',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::IntelligenceFinding::ThrottledRequestSpike::BucketContribution'->new($_) };

declare 'RepeatedBucketContribution',
    as ArrayRef[BucketContribution()];

coerce 'RepeatedBucketContribution',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::IntelligenceFinding::ThrottledRequestSpike::BucketContribution'->new($_) } @$_ ] };

declare 'MapStringBucketContribution',
    as HashRef[BucketContribution()];

declare 'Contribution',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::IntelligenceFinding::ThrottledRequestSpike::BucketContribution::Contribution'];

coerce 'Contribution',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::IntelligenceFinding::ThrottledRequestSpike::BucketContribution::Contribution'->new($_) };

declare 'RepeatedContribution',
    as ArrayRef[Contribution()];

coerce 'RepeatedContribution',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::IntelligenceFinding::ThrottledRequestSpike::BucketContribution::Contribution'->new($_) } @$_ ] };

declare 'MapStringContribution',
    as HashRef[Contribution()];

declare 'PrefixContribution',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::IntelligenceFinding::ThrottledRequestSpike::BucketContribution::Contribution::PrefixContribution'];

coerce 'PrefixContribution',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::IntelligenceFinding::ThrottledRequestSpike::BucketContribution::Contribution::PrefixContribution'->new($_) };

declare 'RepeatedPrefixContribution',
    as ArrayRef[PrefixContribution()];

coerce 'RepeatedPrefixContribution',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::IntelligenceFinding::ThrottledRequestSpike::BucketContribution::Contribution::PrefixContribution'->new($_) } @$_ ] };

declare 'MapStringPrefixContribution',
    as HashRef[PrefixContribution()];

declare 'StorageGrowthAboveTrend',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::IntelligenceFinding::StorageGrowthAboveTrend'];

coerce 'StorageGrowthAboveTrend',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::IntelligenceFinding::StorageGrowthAboveTrend'->new($_) };

declare 'RepeatedStorageGrowthAboveTrend',
    as ArrayRef[StorageGrowthAboveTrend()];

coerce 'RepeatedStorageGrowthAboveTrend',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::IntelligenceFinding::StorageGrowthAboveTrend'->new($_) } @$_ ] };

declare 'MapStringStorageGrowthAboveTrend',
    as HashRef[StorageGrowthAboveTrend()];

declare 'BucketContribution',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::IntelligenceFinding::StorageGrowthAboveTrend::BucketContribution'];

coerce 'BucketContribution',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::IntelligenceFinding::StorageGrowthAboveTrend::BucketContribution'->new($_) };

declare 'RepeatedBucketContribution',
    as ArrayRef[BucketContribution()];

coerce 'RepeatedBucketContribution',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::IntelligenceFinding::StorageGrowthAboveTrend::BucketContribution'->new($_) } @$_ ] };

declare 'MapStringBucketContribution',
    as HashRef[BucketContribution()];

declare 'IntelligenceFindingRevision',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::IntelligenceFindingRevision'];

coerce 'IntelligenceFindingRevision',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::IntelligenceFindingRevision'->new($_) };

declare 'RepeatedIntelligenceFindingRevision',
    as ArrayRef[IntelligenceFindingRevision()];

coerce 'RepeatedIntelligenceFindingRevision',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::IntelligenceFindingRevision'->new($_) } @$_ ] };

declare 'MapStringIntelligenceFindingRevision',
    as HashRef[IntelligenceFindingRevision()];

declare 'GetIntelligenceFindingRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::GetIntelligenceFindingRequest'];

coerce 'GetIntelligenceFindingRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::GetIntelligenceFindingRequest'->new($_) };

declare 'RepeatedGetIntelligenceFindingRequest',
    as ArrayRef[GetIntelligenceFindingRequest()];

coerce 'RepeatedGetIntelligenceFindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::GetIntelligenceFindingRequest'->new($_) } @$_ ] };

declare 'MapStringGetIntelligenceFindingRequest',
    as HashRef[GetIntelligenceFindingRequest()];

declare 'ListIntelligenceFindingsRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::ListIntelligenceFindingsRequest'];

coerce 'ListIntelligenceFindingsRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::ListIntelligenceFindingsRequest'->new($_) };

declare 'RepeatedListIntelligenceFindingsRequest',
    as ArrayRef[ListIntelligenceFindingsRequest()];

coerce 'RepeatedListIntelligenceFindingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::ListIntelligenceFindingsRequest'->new($_) } @$_ ] };

declare 'MapStringListIntelligenceFindingsRequest',
    as HashRef[ListIntelligenceFindingsRequest()];

declare 'ListIntelligenceFindingsResponse',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::ListIntelligenceFindingsResponse'];

coerce 'ListIntelligenceFindingsResponse',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::ListIntelligenceFindingsResponse'->new($_) };

declare 'RepeatedListIntelligenceFindingsResponse',
    as ArrayRef[ListIntelligenceFindingsResponse()];

coerce 'RepeatedListIntelligenceFindingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::ListIntelligenceFindingsResponse'->new($_) } @$_ ] };

declare 'MapStringListIntelligenceFindingsResponse',
    as HashRef[ListIntelligenceFindingsResponse()];

declare 'SummarizeIntelligenceFindingsRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::SummarizeIntelligenceFindingsRequest'];

coerce 'SummarizeIntelligenceFindingsRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::SummarizeIntelligenceFindingsRequest'->new($_) };

declare 'RepeatedSummarizeIntelligenceFindingsRequest',
    as ArrayRef[SummarizeIntelligenceFindingsRequest()];

coerce 'RepeatedSummarizeIntelligenceFindingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::SummarizeIntelligenceFindingsRequest'->new($_) } @$_ ] };

declare 'MapStringSummarizeIntelligenceFindingsRequest',
    as HashRef[SummarizeIntelligenceFindingsRequest()];

declare 'ResourceScope',
    as (Int | Str);

declare 'SummarizeIntelligenceFindingsResponse',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::SummarizeIntelligenceFindingsResponse'];

coerce 'SummarizeIntelligenceFindingsResponse',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::SummarizeIntelligenceFindingsResponse'->new($_) };

declare 'RepeatedSummarizeIntelligenceFindingsResponse',
    as ArrayRef[SummarizeIntelligenceFindingsResponse()];

coerce 'RepeatedSummarizeIntelligenceFindingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::SummarizeIntelligenceFindingsResponse'->new($_) } @$_ ] };

declare 'MapStringSummarizeIntelligenceFindingsResponse',
    as HashRef[SummarizeIntelligenceFindingsResponse()];

declare 'GetIntelligenceFindingRevisionRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::GetIntelligenceFindingRevisionRequest'];

coerce 'GetIntelligenceFindingRevisionRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::GetIntelligenceFindingRevisionRequest'->new($_) };

declare 'RepeatedGetIntelligenceFindingRevisionRequest',
    as ArrayRef[GetIntelligenceFindingRevisionRequest()];

coerce 'RepeatedGetIntelligenceFindingRevisionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::GetIntelligenceFindingRevisionRequest'->new($_) } @$_ ] };

declare 'MapStringGetIntelligenceFindingRevisionRequest',
    as HashRef[GetIntelligenceFindingRevisionRequest()];

declare 'ListIntelligenceFindingRevisionsRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::ListIntelligenceFindingRevisionsRequest'];

coerce 'ListIntelligenceFindingRevisionsRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::ListIntelligenceFindingRevisionsRequest'->new($_) };

declare 'RepeatedListIntelligenceFindingRevisionsRequest',
    as ArrayRef[ListIntelligenceFindingRevisionsRequest()];

coerce 'RepeatedListIntelligenceFindingRevisionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::ListIntelligenceFindingRevisionsRequest'->new($_) } @$_ ] };

declare 'MapStringListIntelligenceFindingRevisionsRequest',
    as HashRef[ListIntelligenceFindingRevisionsRequest()];

declare 'ListIntelligenceFindingRevisionsResponse',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::ListIntelligenceFindingRevisionsResponse'];

coerce 'ListIntelligenceFindingRevisionsResponse',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::ListIntelligenceFindingRevisionsResponse'->new($_) };

declare 'RepeatedListIntelligenceFindingRevisionsResponse',
    as ArrayRef[ListIntelligenceFindingRevisionsResponse()];

coerce 'RepeatedListIntelligenceFindingRevisionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::ListIntelligenceFindingRevisionsResponse'->new($_) } @$_ ] };

declare 'MapStringListIntelligenceFindingRevisionsResponse',
    as HashRef[ListIntelligenceFindingRevisionsResponse()];

declare 'FindingSummary',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::FindingSummary'];

coerce 'FindingSummary',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::FindingSummary'->new($_) };

declare 'RepeatedFindingSummary',
    as ArrayRef[FindingSummary()];

coerce 'RepeatedFindingSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::FindingSummary'->new($_) } @$_ ] };

declare 'MapStringFindingSummary',
    as HashRef[FindingSummary()];

declare 'SummaryDetails',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::FindingSummary::SummaryDetails'];

coerce 'SummaryDetails',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::FindingSummary::SummaryDetails'->new($_) };

declare 'RepeatedSummaryDetails',
    as ArrayRef[SummaryDetails()];

coerce 'RepeatedSummaryDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::FindingSummary::SummaryDetails'->new($_) } @$_ ] };

declare 'MapStringSummaryDetails',
    as HashRef[SummaryDetails()];

declare 'ResourceType',
    as (Int | Str);

declare 'ObjectFullContext',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::ObjectFullContext'];

coerce 'ObjectFullContext',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::ObjectFullContext'->new($_) };

declare 'RepeatedObjectFullContext',
    as ArrayRef[ObjectFullContext()];

coerce 'RepeatedObjectFullContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::ObjectFullContext'->new($_) } @$_ ] };

declare 'MapStringObjectFullContext',
    as HashRef[ObjectFullContext()];

declare 'Type',
    as (Int | Str);

declare 'ViewObjectFullContextRequest',
    as InstanceOf['Google::Storage::Control::V2::StorageControl::ViewObjectFullContextRequest'];

coerce 'ViewObjectFullContextRequest',
    from HashRef, via { 'Google::Storage::Control::V2::StorageControl::ViewObjectFullContextRequest'->new($_) };

declare 'RepeatedViewObjectFullContextRequest',
    as ArrayRef[ViewObjectFullContextRequest()];

coerce 'RepeatedViewObjectFullContextRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Control::V2::StorageControl::ViewObjectFullContextRequest'->new($_) } @$_ ] };

declare 'MapStringViewObjectFullContextRequest',
    as HashRef[ViewObjectFullContextRequest()];

1;

__END__

=head1 NAME

Google::Storage::Control::V2::StorageControl::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
