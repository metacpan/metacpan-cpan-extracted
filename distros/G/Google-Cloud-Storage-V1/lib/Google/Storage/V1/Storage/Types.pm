package Google::Storage::V1::Storage::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DeleteBucketAccessControlRequest',
    as InstanceOf['Google::Storage::V1::Storage::DeleteBucketAccessControlRequest'];

coerce 'DeleteBucketAccessControlRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::DeleteBucketAccessControlRequest'->new($_) };

declare 'RepeatedDeleteBucketAccessControlRequest',
    as ArrayRef[DeleteBucketAccessControlRequest()];

coerce 'RepeatedDeleteBucketAccessControlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::DeleteBucketAccessControlRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBucketAccessControlRequest',
    as HashRef[DeleteBucketAccessControlRequest()];

declare 'GetBucketAccessControlRequest',
    as InstanceOf['Google::Storage::V1::Storage::GetBucketAccessControlRequest'];

coerce 'GetBucketAccessControlRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::GetBucketAccessControlRequest'->new($_) };

declare 'RepeatedGetBucketAccessControlRequest',
    as ArrayRef[GetBucketAccessControlRequest()];

coerce 'RepeatedGetBucketAccessControlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::GetBucketAccessControlRequest'->new($_) } @$_ ] };

declare 'MapStringGetBucketAccessControlRequest',
    as HashRef[GetBucketAccessControlRequest()];

declare 'InsertBucketAccessControlRequest',
    as InstanceOf['Google::Storage::V1::Storage::InsertBucketAccessControlRequest'];

coerce 'InsertBucketAccessControlRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::InsertBucketAccessControlRequest'->new($_) };

declare 'RepeatedInsertBucketAccessControlRequest',
    as ArrayRef[InsertBucketAccessControlRequest()];

coerce 'RepeatedInsertBucketAccessControlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::InsertBucketAccessControlRequest'->new($_) } @$_ ] };

declare 'MapStringInsertBucketAccessControlRequest',
    as HashRef[InsertBucketAccessControlRequest()];

declare 'ListBucketAccessControlsRequest',
    as InstanceOf['Google::Storage::V1::Storage::ListBucketAccessControlsRequest'];

coerce 'ListBucketAccessControlsRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::ListBucketAccessControlsRequest'->new($_) };

declare 'RepeatedListBucketAccessControlsRequest',
    as ArrayRef[ListBucketAccessControlsRequest()];

coerce 'RepeatedListBucketAccessControlsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::ListBucketAccessControlsRequest'->new($_) } @$_ ] };

declare 'MapStringListBucketAccessControlsRequest',
    as HashRef[ListBucketAccessControlsRequest()];

declare 'PatchBucketAccessControlRequest',
    as InstanceOf['Google::Storage::V1::Storage::PatchBucketAccessControlRequest'];

coerce 'PatchBucketAccessControlRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::PatchBucketAccessControlRequest'->new($_) };

declare 'RepeatedPatchBucketAccessControlRequest',
    as ArrayRef[PatchBucketAccessControlRequest()];

coerce 'RepeatedPatchBucketAccessControlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::PatchBucketAccessControlRequest'->new($_) } @$_ ] };

declare 'MapStringPatchBucketAccessControlRequest',
    as HashRef[PatchBucketAccessControlRequest()];

declare 'UpdateBucketAccessControlRequest',
    as InstanceOf['Google::Storage::V1::Storage::UpdateBucketAccessControlRequest'];

coerce 'UpdateBucketAccessControlRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::UpdateBucketAccessControlRequest'->new($_) };

declare 'RepeatedUpdateBucketAccessControlRequest',
    as ArrayRef[UpdateBucketAccessControlRequest()];

coerce 'RepeatedUpdateBucketAccessControlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::UpdateBucketAccessControlRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBucketAccessControlRequest',
    as HashRef[UpdateBucketAccessControlRequest()];

declare 'DeleteBucketRequest',
    as InstanceOf['Google::Storage::V1::Storage::DeleteBucketRequest'];

coerce 'DeleteBucketRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::DeleteBucketRequest'->new($_) };

declare 'RepeatedDeleteBucketRequest',
    as ArrayRef[DeleteBucketRequest()];

coerce 'RepeatedDeleteBucketRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::DeleteBucketRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBucketRequest',
    as HashRef[DeleteBucketRequest()];

declare 'GetBucketRequest',
    as InstanceOf['Google::Storage::V1::Storage::GetBucketRequest'];

coerce 'GetBucketRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::GetBucketRequest'->new($_) };

declare 'RepeatedGetBucketRequest',
    as ArrayRef[GetBucketRequest()];

coerce 'RepeatedGetBucketRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::GetBucketRequest'->new($_) } @$_ ] };

declare 'MapStringGetBucketRequest',
    as HashRef[GetBucketRequest()];

declare 'InsertBucketRequest',
    as InstanceOf['Google::Storage::V1::Storage::InsertBucketRequest'];

coerce 'InsertBucketRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::InsertBucketRequest'->new($_) };

declare 'RepeatedInsertBucketRequest',
    as ArrayRef[InsertBucketRequest()];

coerce 'RepeatedInsertBucketRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::InsertBucketRequest'->new($_) } @$_ ] };

declare 'MapStringInsertBucketRequest',
    as HashRef[InsertBucketRequest()];

declare 'ListChannelsRequest',
    as InstanceOf['Google::Storage::V1::Storage::ListChannelsRequest'];

coerce 'ListChannelsRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::ListChannelsRequest'->new($_) };

declare 'RepeatedListChannelsRequest',
    as ArrayRef[ListChannelsRequest()];

coerce 'RepeatedListChannelsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::ListChannelsRequest'->new($_) } @$_ ] };

declare 'MapStringListChannelsRequest',
    as HashRef[ListChannelsRequest()];

declare 'ListBucketsRequest',
    as InstanceOf['Google::Storage::V1::Storage::ListBucketsRequest'];

coerce 'ListBucketsRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::ListBucketsRequest'->new($_) };

declare 'RepeatedListBucketsRequest',
    as ArrayRef[ListBucketsRequest()];

coerce 'RepeatedListBucketsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::ListBucketsRequest'->new($_) } @$_ ] };

declare 'MapStringListBucketsRequest',
    as HashRef[ListBucketsRequest()];

declare 'LockRetentionPolicyRequest',
    as InstanceOf['Google::Storage::V1::Storage::LockRetentionPolicyRequest'];

coerce 'LockRetentionPolicyRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::LockRetentionPolicyRequest'->new($_) };

declare 'RepeatedLockRetentionPolicyRequest',
    as ArrayRef[LockRetentionPolicyRequest()];

coerce 'RepeatedLockRetentionPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::LockRetentionPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringLockRetentionPolicyRequest',
    as HashRef[LockRetentionPolicyRequest()];

declare 'PatchBucketRequest',
    as InstanceOf['Google::Storage::V1::Storage::PatchBucketRequest'];

coerce 'PatchBucketRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::PatchBucketRequest'->new($_) };

declare 'RepeatedPatchBucketRequest',
    as ArrayRef[PatchBucketRequest()];

coerce 'RepeatedPatchBucketRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::PatchBucketRequest'->new($_) } @$_ ] };

declare 'MapStringPatchBucketRequest',
    as HashRef[PatchBucketRequest()];

declare 'UpdateBucketRequest',
    as InstanceOf['Google::Storage::V1::Storage::UpdateBucketRequest'];

coerce 'UpdateBucketRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::UpdateBucketRequest'->new($_) };

declare 'RepeatedUpdateBucketRequest',
    as ArrayRef[UpdateBucketRequest()];

coerce 'RepeatedUpdateBucketRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::UpdateBucketRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBucketRequest',
    as HashRef[UpdateBucketRequest()];

declare 'StopChannelRequest',
    as InstanceOf['Google::Storage::V1::Storage::StopChannelRequest'];

coerce 'StopChannelRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::StopChannelRequest'->new($_) };

declare 'RepeatedStopChannelRequest',
    as ArrayRef[StopChannelRequest()];

coerce 'RepeatedStopChannelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::StopChannelRequest'->new($_) } @$_ ] };

declare 'MapStringStopChannelRequest',
    as HashRef[StopChannelRequest()];

declare 'DeleteDefaultObjectAccessControlRequest',
    as InstanceOf['Google::Storage::V1::Storage::DeleteDefaultObjectAccessControlRequest'];

coerce 'DeleteDefaultObjectAccessControlRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::DeleteDefaultObjectAccessControlRequest'->new($_) };

declare 'RepeatedDeleteDefaultObjectAccessControlRequest',
    as ArrayRef[DeleteDefaultObjectAccessControlRequest()];

coerce 'RepeatedDeleteDefaultObjectAccessControlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::DeleteDefaultObjectAccessControlRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDefaultObjectAccessControlRequest',
    as HashRef[DeleteDefaultObjectAccessControlRequest()];

declare 'GetDefaultObjectAccessControlRequest',
    as InstanceOf['Google::Storage::V1::Storage::GetDefaultObjectAccessControlRequest'];

coerce 'GetDefaultObjectAccessControlRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::GetDefaultObjectAccessControlRequest'->new($_) };

declare 'RepeatedGetDefaultObjectAccessControlRequest',
    as ArrayRef[GetDefaultObjectAccessControlRequest()];

coerce 'RepeatedGetDefaultObjectAccessControlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::GetDefaultObjectAccessControlRequest'->new($_) } @$_ ] };

declare 'MapStringGetDefaultObjectAccessControlRequest',
    as HashRef[GetDefaultObjectAccessControlRequest()];

declare 'InsertDefaultObjectAccessControlRequest',
    as InstanceOf['Google::Storage::V1::Storage::InsertDefaultObjectAccessControlRequest'];

coerce 'InsertDefaultObjectAccessControlRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::InsertDefaultObjectAccessControlRequest'->new($_) };

declare 'RepeatedInsertDefaultObjectAccessControlRequest',
    as ArrayRef[InsertDefaultObjectAccessControlRequest()];

coerce 'RepeatedInsertDefaultObjectAccessControlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::InsertDefaultObjectAccessControlRequest'->new($_) } @$_ ] };

declare 'MapStringInsertDefaultObjectAccessControlRequest',
    as HashRef[InsertDefaultObjectAccessControlRequest()];

declare 'ListDefaultObjectAccessControlsRequest',
    as InstanceOf['Google::Storage::V1::Storage::ListDefaultObjectAccessControlsRequest'];

coerce 'ListDefaultObjectAccessControlsRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::ListDefaultObjectAccessControlsRequest'->new($_) };

declare 'RepeatedListDefaultObjectAccessControlsRequest',
    as ArrayRef[ListDefaultObjectAccessControlsRequest()];

coerce 'RepeatedListDefaultObjectAccessControlsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::ListDefaultObjectAccessControlsRequest'->new($_) } @$_ ] };

declare 'MapStringListDefaultObjectAccessControlsRequest',
    as HashRef[ListDefaultObjectAccessControlsRequest()];

declare 'PatchDefaultObjectAccessControlRequest',
    as InstanceOf['Google::Storage::V1::Storage::PatchDefaultObjectAccessControlRequest'];

coerce 'PatchDefaultObjectAccessControlRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::PatchDefaultObjectAccessControlRequest'->new($_) };

declare 'RepeatedPatchDefaultObjectAccessControlRequest',
    as ArrayRef[PatchDefaultObjectAccessControlRequest()];

coerce 'RepeatedPatchDefaultObjectAccessControlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::PatchDefaultObjectAccessControlRequest'->new($_) } @$_ ] };

declare 'MapStringPatchDefaultObjectAccessControlRequest',
    as HashRef[PatchDefaultObjectAccessControlRequest()];

declare 'UpdateDefaultObjectAccessControlRequest',
    as InstanceOf['Google::Storage::V1::Storage::UpdateDefaultObjectAccessControlRequest'];

coerce 'UpdateDefaultObjectAccessControlRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::UpdateDefaultObjectAccessControlRequest'->new($_) };

declare 'RepeatedUpdateDefaultObjectAccessControlRequest',
    as ArrayRef[UpdateDefaultObjectAccessControlRequest()];

coerce 'RepeatedUpdateDefaultObjectAccessControlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::UpdateDefaultObjectAccessControlRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDefaultObjectAccessControlRequest',
    as HashRef[UpdateDefaultObjectAccessControlRequest()];

declare 'DeleteNotificationRequest',
    as InstanceOf['Google::Storage::V1::Storage::DeleteNotificationRequest'];

coerce 'DeleteNotificationRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::DeleteNotificationRequest'->new($_) };

declare 'RepeatedDeleteNotificationRequest',
    as ArrayRef[DeleteNotificationRequest()];

coerce 'RepeatedDeleteNotificationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::DeleteNotificationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteNotificationRequest',
    as HashRef[DeleteNotificationRequest()];

declare 'GetNotificationRequest',
    as InstanceOf['Google::Storage::V1::Storage::GetNotificationRequest'];

coerce 'GetNotificationRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::GetNotificationRequest'->new($_) };

declare 'RepeatedGetNotificationRequest',
    as ArrayRef[GetNotificationRequest()];

coerce 'RepeatedGetNotificationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::GetNotificationRequest'->new($_) } @$_ ] };

declare 'MapStringGetNotificationRequest',
    as HashRef[GetNotificationRequest()];

declare 'InsertNotificationRequest',
    as InstanceOf['Google::Storage::V1::Storage::InsertNotificationRequest'];

coerce 'InsertNotificationRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::InsertNotificationRequest'->new($_) };

declare 'RepeatedInsertNotificationRequest',
    as ArrayRef[InsertNotificationRequest()];

coerce 'RepeatedInsertNotificationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::InsertNotificationRequest'->new($_) } @$_ ] };

declare 'MapStringInsertNotificationRequest',
    as HashRef[InsertNotificationRequest()];

declare 'ListNotificationsRequest',
    as InstanceOf['Google::Storage::V1::Storage::ListNotificationsRequest'];

coerce 'ListNotificationsRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::ListNotificationsRequest'->new($_) };

declare 'RepeatedListNotificationsRequest',
    as ArrayRef[ListNotificationsRequest()];

coerce 'RepeatedListNotificationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::ListNotificationsRequest'->new($_) } @$_ ] };

declare 'MapStringListNotificationsRequest',
    as HashRef[ListNotificationsRequest()];

declare 'DeleteObjectAccessControlRequest',
    as InstanceOf['Google::Storage::V1::Storage::DeleteObjectAccessControlRequest'];

coerce 'DeleteObjectAccessControlRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::DeleteObjectAccessControlRequest'->new($_) };

declare 'RepeatedDeleteObjectAccessControlRequest',
    as ArrayRef[DeleteObjectAccessControlRequest()];

coerce 'RepeatedDeleteObjectAccessControlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::DeleteObjectAccessControlRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteObjectAccessControlRequest',
    as HashRef[DeleteObjectAccessControlRequest()];

declare 'GetObjectAccessControlRequest',
    as InstanceOf['Google::Storage::V1::Storage::GetObjectAccessControlRequest'];

coerce 'GetObjectAccessControlRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::GetObjectAccessControlRequest'->new($_) };

declare 'RepeatedGetObjectAccessControlRequest',
    as ArrayRef[GetObjectAccessControlRequest()];

coerce 'RepeatedGetObjectAccessControlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::GetObjectAccessControlRequest'->new($_) } @$_ ] };

declare 'MapStringGetObjectAccessControlRequest',
    as HashRef[GetObjectAccessControlRequest()];

declare 'InsertObjectAccessControlRequest',
    as InstanceOf['Google::Storage::V1::Storage::InsertObjectAccessControlRequest'];

coerce 'InsertObjectAccessControlRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::InsertObjectAccessControlRequest'->new($_) };

declare 'RepeatedInsertObjectAccessControlRequest',
    as ArrayRef[InsertObjectAccessControlRequest()];

coerce 'RepeatedInsertObjectAccessControlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::InsertObjectAccessControlRequest'->new($_) } @$_ ] };

declare 'MapStringInsertObjectAccessControlRequest',
    as HashRef[InsertObjectAccessControlRequest()];

declare 'ListObjectAccessControlsRequest',
    as InstanceOf['Google::Storage::V1::Storage::ListObjectAccessControlsRequest'];

coerce 'ListObjectAccessControlsRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::ListObjectAccessControlsRequest'->new($_) };

declare 'RepeatedListObjectAccessControlsRequest',
    as ArrayRef[ListObjectAccessControlsRequest()];

coerce 'RepeatedListObjectAccessControlsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::ListObjectAccessControlsRequest'->new($_) } @$_ ] };

declare 'MapStringListObjectAccessControlsRequest',
    as HashRef[ListObjectAccessControlsRequest()];

declare 'PatchObjectAccessControlRequest',
    as InstanceOf['Google::Storage::V1::Storage::PatchObjectAccessControlRequest'];

coerce 'PatchObjectAccessControlRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::PatchObjectAccessControlRequest'->new($_) };

declare 'RepeatedPatchObjectAccessControlRequest',
    as ArrayRef[PatchObjectAccessControlRequest()];

coerce 'RepeatedPatchObjectAccessControlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::PatchObjectAccessControlRequest'->new($_) } @$_ ] };

declare 'MapStringPatchObjectAccessControlRequest',
    as HashRef[PatchObjectAccessControlRequest()];

declare 'UpdateObjectAccessControlRequest',
    as InstanceOf['Google::Storage::V1::Storage::UpdateObjectAccessControlRequest'];

coerce 'UpdateObjectAccessControlRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::UpdateObjectAccessControlRequest'->new($_) };

declare 'RepeatedUpdateObjectAccessControlRequest',
    as ArrayRef[UpdateObjectAccessControlRequest()];

coerce 'RepeatedUpdateObjectAccessControlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::UpdateObjectAccessControlRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateObjectAccessControlRequest',
    as HashRef[UpdateObjectAccessControlRequest()];

declare 'ComposeObjectRequest',
    as InstanceOf['Google::Storage::V1::Storage::ComposeObjectRequest'];

coerce 'ComposeObjectRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::ComposeObjectRequest'->new($_) };

declare 'RepeatedComposeObjectRequest',
    as ArrayRef[ComposeObjectRequest()];

coerce 'RepeatedComposeObjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::ComposeObjectRequest'->new($_) } @$_ ] };

declare 'MapStringComposeObjectRequest',
    as HashRef[ComposeObjectRequest()];

declare 'SourceObjects',
    as InstanceOf['Google::Storage::V1::Storage::ComposeObjectRequest::SourceObjects'];

coerce 'SourceObjects',
    from HashRef, via { 'Google::Storage::V1::Storage::ComposeObjectRequest::SourceObjects'->new($_) };

declare 'RepeatedSourceObjects',
    as ArrayRef[SourceObjects()];

coerce 'RepeatedSourceObjects',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::ComposeObjectRequest::SourceObjects'->new($_) } @$_ ] };

declare 'MapStringSourceObjects',
    as HashRef[SourceObjects()];

declare 'ObjectPreconditions',
    as InstanceOf['Google::Storage::V1::Storage::ComposeObjectRequest::SourceObjects::ObjectPreconditions'];

coerce 'ObjectPreconditions',
    from HashRef, via { 'Google::Storage::V1::Storage::ComposeObjectRequest::SourceObjects::ObjectPreconditions'->new($_) };

declare 'RepeatedObjectPreconditions',
    as ArrayRef[ObjectPreconditions()];

coerce 'RepeatedObjectPreconditions',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::ComposeObjectRequest::SourceObjects::ObjectPreconditions'->new($_) } @$_ ] };

declare 'MapStringObjectPreconditions',
    as HashRef[ObjectPreconditions()];

declare 'CopyObjectRequest',
    as InstanceOf['Google::Storage::V1::Storage::CopyObjectRequest'];

coerce 'CopyObjectRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::CopyObjectRequest'->new($_) };

declare 'RepeatedCopyObjectRequest',
    as ArrayRef[CopyObjectRequest()];

coerce 'RepeatedCopyObjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::CopyObjectRequest'->new($_) } @$_ ] };

declare 'MapStringCopyObjectRequest',
    as HashRef[CopyObjectRequest()];

declare 'DeleteObjectRequest',
    as InstanceOf['Google::Storage::V1::Storage::DeleteObjectRequest'];

coerce 'DeleteObjectRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::DeleteObjectRequest'->new($_) };

declare 'RepeatedDeleteObjectRequest',
    as ArrayRef[DeleteObjectRequest()];

coerce 'RepeatedDeleteObjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::DeleteObjectRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteObjectRequest',
    as HashRef[DeleteObjectRequest()];

declare 'GetObjectMediaRequest',
    as InstanceOf['Google::Storage::V1::Storage::GetObjectMediaRequest'];

coerce 'GetObjectMediaRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::GetObjectMediaRequest'->new($_) };

declare 'RepeatedGetObjectMediaRequest',
    as ArrayRef[GetObjectMediaRequest()];

coerce 'RepeatedGetObjectMediaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::GetObjectMediaRequest'->new($_) } @$_ ] };

declare 'MapStringGetObjectMediaRequest',
    as HashRef[GetObjectMediaRequest()];

declare 'GetObjectRequest',
    as InstanceOf['Google::Storage::V1::Storage::GetObjectRequest'];

coerce 'GetObjectRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::GetObjectRequest'->new($_) };

declare 'RepeatedGetObjectRequest',
    as ArrayRef[GetObjectRequest()];

coerce 'RepeatedGetObjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::GetObjectRequest'->new($_) } @$_ ] };

declare 'MapStringGetObjectRequest',
    as HashRef[GetObjectRequest()];

declare 'GetObjectMediaResponse',
    as InstanceOf['Google::Storage::V1::Storage::GetObjectMediaResponse'];

coerce 'GetObjectMediaResponse',
    from HashRef, via { 'Google::Storage::V1::Storage::GetObjectMediaResponse'->new($_) };

declare 'RepeatedGetObjectMediaResponse',
    as ArrayRef[GetObjectMediaResponse()];

coerce 'RepeatedGetObjectMediaResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::GetObjectMediaResponse'->new($_) } @$_ ] };

declare 'MapStringGetObjectMediaResponse',
    as HashRef[GetObjectMediaResponse()];

declare 'InsertObjectSpec',
    as InstanceOf['Google::Storage::V1::Storage::InsertObjectSpec'];

coerce 'InsertObjectSpec',
    from HashRef, via { 'Google::Storage::V1::Storage::InsertObjectSpec'->new($_) };

declare 'RepeatedInsertObjectSpec',
    as ArrayRef[InsertObjectSpec()];

coerce 'RepeatedInsertObjectSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::InsertObjectSpec'->new($_) } @$_ ] };

declare 'MapStringInsertObjectSpec',
    as HashRef[InsertObjectSpec()];

declare 'InsertObjectRequest',
    as InstanceOf['Google::Storage::V1::Storage::InsertObjectRequest'];

coerce 'InsertObjectRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::InsertObjectRequest'->new($_) };

declare 'RepeatedInsertObjectRequest',
    as ArrayRef[InsertObjectRequest()];

coerce 'RepeatedInsertObjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::InsertObjectRequest'->new($_) } @$_ ] };

declare 'MapStringInsertObjectRequest',
    as HashRef[InsertObjectRequest()];

declare 'ListObjectsRequest',
    as InstanceOf['Google::Storage::V1::Storage::ListObjectsRequest'];

coerce 'ListObjectsRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::ListObjectsRequest'->new($_) };

declare 'RepeatedListObjectsRequest',
    as ArrayRef[ListObjectsRequest()];

coerce 'RepeatedListObjectsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::ListObjectsRequest'->new($_) } @$_ ] };

declare 'MapStringListObjectsRequest',
    as HashRef[ListObjectsRequest()];

declare 'QueryWriteStatusRequest',
    as InstanceOf['Google::Storage::V1::Storage::QueryWriteStatusRequest'];

coerce 'QueryWriteStatusRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::QueryWriteStatusRequest'->new($_) };

declare 'RepeatedQueryWriteStatusRequest',
    as ArrayRef[QueryWriteStatusRequest()];

coerce 'RepeatedQueryWriteStatusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::QueryWriteStatusRequest'->new($_) } @$_ ] };

declare 'MapStringQueryWriteStatusRequest',
    as HashRef[QueryWriteStatusRequest()];

declare 'QueryWriteStatusResponse',
    as InstanceOf['Google::Storage::V1::Storage::QueryWriteStatusResponse'];

coerce 'QueryWriteStatusResponse',
    from HashRef, via { 'Google::Storage::V1::Storage::QueryWriteStatusResponse'->new($_) };

declare 'RepeatedQueryWriteStatusResponse',
    as ArrayRef[QueryWriteStatusResponse()];

coerce 'RepeatedQueryWriteStatusResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::QueryWriteStatusResponse'->new($_) } @$_ ] };

declare 'MapStringQueryWriteStatusResponse',
    as HashRef[QueryWriteStatusResponse()];

declare 'RewriteObjectRequest',
    as InstanceOf['Google::Storage::V1::Storage::RewriteObjectRequest'];

coerce 'RewriteObjectRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::RewriteObjectRequest'->new($_) };

declare 'RepeatedRewriteObjectRequest',
    as ArrayRef[RewriteObjectRequest()];

coerce 'RepeatedRewriteObjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::RewriteObjectRequest'->new($_) } @$_ ] };

declare 'MapStringRewriteObjectRequest',
    as HashRef[RewriteObjectRequest()];

declare 'RewriteResponse',
    as InstanceOf['Google::Storage::V1::Storage::RewriteResponse'];

coerce 'RewriteResponse',
    from HashRef, via { 'Google::Storage::V1::Storage::RewriteResponse'->new($_) };

declare 'RepeatedRewriteResponse',
    as ArrayRef[RewriteResponse()];

coerce 'RepeatedRewriteResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::RewriteResponse'->new($_) } @$_ ] };

declare 'MapStringRewriteResponse',
    as HashRef[RewriteResponse()];

declare 'StartResumableWriteRequest',
    as InstanceOf['Google::Storage::V1::Storage::StartResumableWriteRequest'];

coerce 'StartResumableWriteRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::StartResumableWriteRequest'->new($_) };

declare 'RepeatedStartResumableWriteRequest',
    as ArrayRef[StartResumableWriteRequest()];

coerce 'RepeatedStartResumableWriteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::StartResumableWriteRequest'->new($_) } @$_ ] };

declare 'MapStringStartResumableWriteRequest',
    as HashRef[StartResumableWriteRequest()];

declare 'StartResumableWriteResponse',
    as InstanceOf['Google::Storage::V1::Storage::StartResumableWriteResponse'];

coerce 'StartResumableWriteResponse',
    from HashRef, via { 'Google::Storage::V1::Storage::StartResumableWriteResponse'->new($_) };

declare 'RepeatedStartResumableWriteResponse',
    as ArrayRef[StartResumableWriteResponse()];

coerce 'RepeatedStartResumableWriteResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::StartResumableWriteResponse'->new($_) } @$_ ] };

declare 'MapStringStartResumableWriteResponse',
    as HashRef[StartResumableWriteResponse()];

declare 'PatchObjectRequest',
    as InstanceOf['Google::Storage::V1::Storage::PatchObjectRequest'];

coerce 'PatchObjectRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::PatchObjectRequest'->new($_) };

declare 'RepeatedPatchObjectRequest',
    as ArrayRef[PatchObjectRequest()];

coerce 'RepeatedPatchObjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::PatchObjectRequest'->new($_) } @$_ ] };

declare 'MapStringPatchObjectRequest',
    as HashRef[PatchObjectRequest()];

declare 'UpdateObjectRequest',
    as InstanceOf['Google::Storage::V1::Storage::UpdateObjectRequest'];

coerce 'UpdateObjectRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::UpdateObjectRequest'->new($_) };

declare 'RepeatedUpdateObjectRequest',
    as ArrayRef[UpdateObjectRequest()];

coerce 'RepeatedUpdateObjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::UpdateObjectRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateObjectRequest',
    as HashRef[UpdateObjectRequest()];

declare 'WatchAllObjectsRequest',
    as InstanceOf['Google::Storage::V1::Storage::WatchAllObjectsRequest'];

coerce 'WatchAllObjectsRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::WatchAllObjectsRequest'->new($_) };

declare 'RepeatedWatchAllObjectsRequest',
    as ArrayRef[WatchAllObjectsRequest()];

coerce 'RepeatedWatchAllObjectsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::WatchAllObjectsRequest'->new($_) } @$_ ] };

declare 'MapStringWatchAllObjectsRequest',
    as HashRef[WatchAllObjectsRequest()];

declare 'GetProjectServiceAccountRequest',
    as InstanceOf['Google::Storage::V1::Storage::GetProjectServiceAccountRequest'];

coerce 'GetProjectServiceAccountRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::GetProjectServiceAccountRequest'->new($_) };

declare 'RepeatedGetProjectServiceAccountRequest',
    as ArrayRef[GetProjectServiceAccountRequest()];

coerce 'RepeatedGetProjectServiceAccountRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::GetProjectServiceAccountRequest'->new($_) } @$_ ] };

declare 'MapStringGetProjectServiceAccountRequest',
    as HashRef[GetProjectServiceAccountRequest()];

declare 'CreateHmacKeyRequest',
    as InstanceOf['Google::Storage::V1::Storage::CreateHmacKeyRequest'];

coerce 'CreateHmacKeyRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::CreateHmacKeyRequest'->new($_) };

declare 'RepeatedCreateHmacKeyRequest',
    as ArrayRef[CreateHmacKeyRequest()];

coerce 'RepeatedCreateHmacKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::CreateHmacKeyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateHmacKeyRequest',
    as HashRef[CreateHmacKeyRequest()];

declare 'CreateHmacKeyResponse',
    as InstanceOf['Google::Storage::V1::Storage::CreateHmacKeyResponse'];

coerce 'CreateHmacKeyResponse',
    from HashRef, via { 'Google::Storage::V1::Storage::CreateHmacKeyResponse'->new($_) };

declare 'RepeatedCreateHmacKeyResponse',
    as ArrayRef[CreateHmacKeyResponse()];

coerce 'RepeatedCreateHmacKeyResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::CreateHmacKeyResponse'->new($_) } @$_ ] };

declare 'MapStringCreateHmacKeyResponse',
    as HashRef[CreateHmacKeyResponse()];

declare 'DeleteHmacKeyRequest',
    as InstanceOf['Google::Storage::V1::Storage::DeleteHmacKeyRequest'];

coerce 'DeleteHmacKeyRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::DeleteHmacKeyRequest'->new($_) };

declare 'RepeatedDeleteHmacKeyRequest',
    as ArrayRef[DeleteHmacKeyRequest()];

coerce 'RepeatedDeleteHmacKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::DeleteHmacKeyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteHmacKeyRequest',
    as HashRef[DeleteHmacKeyRequest()];

declare 'GetHmacKeyRequest',
    as InstanceOf['Google::Storage::V1::Storage::GetHmacKeyRequest'];

coerce 'GetHmacKeyRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::GetHmacKeyRequest'->new($_) };

declare 'RepeatedGetHmacKeyRequest',
    as ArrayRef[GetHmacKeyRequest()];

coerce 'RepeatedGetHmacKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::GetHmacKeyRequest'->new($_) } @$_ ] };

declare 'MapStringGetHmacKeyRequest',
    as HashRef[GetHmacKeyRequest()];

declare 'ListHmacKeysRequest',
    as InstanceOf['Google::Storage::V1::Storage::ListHmacKeysRequest'];

coerce 'ListHmacKeysRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::ListHmacKeysRequest'->new($_) };

declare 'RepeatedListHmacKeysRequest',
    as ArrayRef[ListHmacKeysRequest()];

coerce 'RepeatedListHmacKeysRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::ListHmacKeysRequest'->new($_) } @$_ ] };

declare 'MapStringListHmacKeysRequest',
    as HashRef[ListHmacKeysRequest()];

declare 'ListHmacKeysResponse',
    as InstanceOf['Google::Storage::V1::Storage::ListHmacKeysResponse'];

coerce 'ListHmacKeysResponse',
    from HashRef, via { 'Google::Storage::V1::Storage::ListHmacKeysResponse'->new($_) };

declare 'RepeatedListHmacKeysResponse',
    as ArrayRef[ListHmacKeysResponse()];

coerce 'RepeatedListHmacKeysResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::ListHmacKeysResponse'->new($_) } @$_ ] };

declare 'MapStringListHmacKeysResponse',
    as HashRef[ListHmacKeysResponse()];

declare 'UpdateHmacKeyRequest',
    as InstanceOf['Google::Storage::V1::Storage::UpdateHmacKeyRequest'];

coerce 'UpdateHmacKeyRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::UpdateHmacKeyRequest'->new($_) };

declare 'RepeatedUpdateHmacKeyRequest',
    as ArrayRef[UpdateHmacKeyRequest()];

coerce 'RepeatedUpdateHmacKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::UpdateHmacKeyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateHmacKeyRequest',
    as HashRef[UpdateHmacKeyRequest()];

declare 'GetIamPolicyRequest',
    as InstanceOf['Google::Storage::V1::Storage::GetIamPolicyRequest'];

coerce 'GetIamPolicyRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::GetIamPolicyRequest'->new($_) };

declare 'RepeatedGetIamPolicyRequest',
    as ArrayRef[GetIamPolicyRequest()];

coerce 'RepeatedGetIamPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::GetIamPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetIamPolicyRequest',
    as HashRef[GetIamPolicyRequest()];

declare 'SetIamPolicyRequest',
    as InstanceOf['Google::Storage::V1::Storage::SetIamPolicyRequest'];

coerce 'SetIamPolicyRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::SetIamPolicyRequest'->new($_) };

declare 'RepeatedSetIamPolicyRequest',
    as ArrayRef[SetIamPolicyRequest()];

coerce 'RepeatedSetIamPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::SetIamPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringSetIamPolicyRequest',
    as HashRef[SetIamPolicyRequest()];

declare 'TestIamPermissionsRequest',
    as InstanceOf['Google::Storage::V1::Storage::TestIamPermissionsRequest'];

coerce 'TestIamPermissionsRequest',
    from HashRef, via { 'Google::Storage::V1::Storage::TestIamPermissionsRequest'->new($_) };

declare 'RepeatedTestIamPermissionsRequest',
    as ArrayRef[TestIamPermissionsRequest()];

coerce 'RepeatedTestIamPermissionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::TestIamPermissionsRequest'->new($_) } @$_ ] };

declare 'MapStringTestIamPermissionsRequest',
    as HashRef[TestIamPermissionsRequest()];

declare 'CommonObjectRequestParams',
    as InstanceOf['Google::Storage::V1::Storage::CommonObjectRequestParams'];

coerce 'CommonObjectRequestParams',
    from HashRef, via { 'Google::Storage::V1::Storage::CommonObjectRequestParams'->new($_) };

declare 'RepeatedCommonObjectRequestParams',
    as ArrayRef[CommonObjectRequestParams()];

coerce 'RepeatedCommonObjectRequestParams',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::CommonObjectRequestParams'->new($_) } @$_ ] };

declare 'MapStringCommonObjectRequestParams',
    as HashRef[CommonObjectRequestParams()];

declare 'CommonRequestParams',
    as InstanceOf['Google::Storage::V1::Storage::CommonRequestParams'];

coerce 'CommonRequestParams',
    from HashRef, via { 'Google::Storage::V1::Storage::CommonRequestParams'->new($_) };

declare 'RepeatedCommonRequestParams',
    as ArrayRef[CommonRequestParams()];

coerce 'RepeatedCommonRequestParams',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::Storage::CommonRequestParams'->new($_) } @$_ ] };

declare 'MapStringCommonRequestParams',
    as HashRef[CommonRequestParams()];

1;

__END__

=head1 NAME

Google::Storage::V1::Storage::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
