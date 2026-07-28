package Google::Storage::V2::Storage::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DeleteBucketRequest',
    as InstanceOf['Google::Storage::V2::Storage::DeleteBucketRequest'];

coerce 'DeleteBucketRequest',
    from HashRef, via { 'Google::Storage::V2::Storage::DeleteBucketRequest'->new($_) };

declare 'RepeatedDeleteBucketRequest',
    as ArrayRef[DeleteBucketRequest()];

coerce 'RepeatedDeleteBucketRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::DeleteBucketRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBucketRequest',
    as HashRef[DeleteBucketRequest()];

declare 'GetBucketRequest',
    as InstanceOf['Google::Storage::V2::Storage::GetBucketRequest'];

coerce 'GetBucketRequest',
    from HashRef, via { 'Google::Storage::V2::Storage::GetBucketRequest'->new($_) };

declare 'RepeatedGetBucketRequest',
    as ArrayRef[GetBucketRequest()];

coerce 'RepeatedGetBucketRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::GetBucketRequest'->new($_) } @$_ ] };

declare 'MapStringGetBucketRequest',
    as HashRef[GetBucketRequest()];

declare 'CreateBucketRequest',
    as InstanceOf['Google::Storage::V2::Storage::CreateBucketRequest'];

coerce 'CreateBucketRequest',
    from HashRef, via { 'Google::Storage::V2::Storage::CreateBucketRequest'->new($_) };

declare 'RepeatedCreateBucketRequest',
    as ArrayRef[CreateBucketRequest()];

coerce 'RepeatedCreateBucketRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::CreateBucketRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBucketRequest',
    as HashRef[CreateBucketRequest()];

declare 'ListBucketsRequest',
    as InstanceOf['Google::Storage::V2::Storage::ListBucketsRequest'];

coerce 'ListBucketsRequest',
    from HashRef, via { 'Google::Storage::V2::Storage::ListBucketsRequest'->new($_) };

declare 'RepeatedListBucketsRequest',
    as ArrayRef[ListBucketsRequest()];

coerce 'RepeatedListBucketsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::ListBucketsRequest'->new($_) } @$_ ] };

declare 'MapStringListBucketsRequest',
    as HashRef[ListBucketsRequest()];

declare 'ListBucketsResponse',
    as InstanceOf['Google::Storage::V2::Storage::ListBucketsResponse'];

coerce 'ListBucketsResponse',
    from HashRef, via { 'Google::Storage::V2::Storage::ListBucketsResponse'->new($_) };

declare 'RepeatedListBucketsResponse',
    as ArrayRef[ListBucketsResponse()];

coerce 'RepeatedListBucketsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::ListBucketsResponse'->new($_) } @$_ ] };

declare 'MapStringListBucketsResponse',
    as HashRef[ListBucketsResponse()];

declare 'LockBucketRetentionPolicyRequest',
    as InstanceOf['Google::Storage::V2::Storage::LockBucketRetentionPolicyRequest'];

coerce 'LockBucketRetentionPolicyRequest',
    from HashRef, via { 'Google::Storage::V2::Storage::LockBucketRetentionPolicyRequest'->new($_) };

declare 'RepeatedLockBucketRetentionPolicyRequest',
    as ArrayRef[LockBucketRetentionPolicyRequest()];

coerce 'RepeatedLockBucketRetentionPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::LockBucketRetentionPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringLockBucketRetentionPolicyRequest',
    as HashRef[LockBucketRetentionPolicyRequest()];

declare 'UpdateBucketRequest',
    as InstanceOf['Google::Storage::V2::Storage::UpdateBucketRequest'];

coerce 'UpdateBucketRequest',
    from HashRef, via { 'Google::Storage::V2::Storage::UpdateBucketRequest'->new($_) };

declare 'RepeatedUpdateBucketRequest',
    as ArrayRef[UpdateBucketRequest()];

coerce 'RepeatedUpdateBucketRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::UpdateBucketRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBucketRequest',
    as HashRef[UpdateBucketRequest()];

declare 'ComposeObjectRequest',
    as InstanceOf['Google::Storage::V2::Storage::ComposeObjectRequest'];

coerce 'ComposeObjectRequest',
    from HashRef, via { 'Google::Storage::V2::Storage::ComposeObjectRequest'->new($_) };

declare 'RepeatedComposeObjectRequest',
    as ArrayRef[ComposeObjectRequest()];

coerce 'RepeatedComposeObjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::ComposeObjectRequest'->new($_) } @$_ ] };

declare 'MapStringComposeObjectRequest',
    as HashRef[ComposeObjectRequest()];

declare 'SourceObject',
    as InstanceOf['Google::Storage::V2::Storage::ComposeObjectRequest::SourceObject'];

coerce 'SourceObject',
    from HashRef, via { 'Google::Storage::V2::Storage::ComposeObjectRequest::SourceObject'->new($_) };

declare 'RepeatedSourceObject',
    as ArrayRef[SourceObject()];

coerce 'RepeatedSourceObject',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::ComposeObjectRequest::SourceObject'->new($_) } @$_ ] };

declare 'MapStringSourceObject',
    as HashRef[SourceObject()];

declare 'ObjectPreconditions',
    as InstanceOf['Google::Storage::V2::Storage::ComposeObjectRequest::SourceObject::ObjectPreconditions'];

coerce 'ObjectPreconditions',
    from HashRef, via { 'Google::Storage::V2::Storage::ComposeObjectRequest::SourceObject::ObjectPreconditions'->new($_) };

declare 'RepeatedObjectPreconditions',
    as ArrayRef[ObjectPreconditions()];

coerce 'RepeatedObjectPreconditions',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::ComposeObjectRequest::SourceObject::ObjectPreconditions'->new($_) } @$_ ] };

declare 'MapStringObjectPreconditions',
    as HashRef[ObjectPreconditions()];

declare 'DeleteObjectRequest',
    as InstanceOf['Google::Storage::V2::Storage::DeleteObjectRequest'];

coerce 'DeleteObjectRequest',
    from HashRef, via { 'Google::Storage::V2::Storage::DeleteObjectRequest'->new($_) };

declare 'RepeatedDeleteObjectRequest',
    as ArrayRef[DeleteObjectRequest()];

coerce 'RepeatedDeleteObjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::DeleteObjectRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteObjectRequest',
    as HashRef[DeleteObjectRequest()];

declare 'RestoreObjectRequest',
    as InstanceOf['Google::Storage::V2::Storage::RestoreObjectRequest'];

coerce 'RestoreObjectRequest',
    from HashRef, via { 'Google::Storage::V2::Storage::RestoreObjectRequest'->new($_) };

declare 'RepeatedRestoreObjectRequest',
    as ArrayRef[RestoreObjectRequest()];

coerce 'RepeatedRestoreObjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::RestoreObjectRequest'->new($_) } @$_ ] };

declare 'MapStringRestoreObjectRequest',
    as HashRef[RestoreObjectRequest()];

declare 'CancelResumableWriteRequest',
    as InstanceOf['Google::Storage::V2::Storage::CancelResumableWriteRequest'];

coerce 'CancelResumableWriteRequest',
    from HashRef, via { 'Google::Storage::V2::Storage::CancelResumableWriteRequest'->new($_) };

declare 'RepeatedCancelResumableWriteRequest',
    as ArrayRef[CancelResumableWriteRequest()];

coerce 'RepeatedCancelResumableWriteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::CancelResumableWriteRequest'->new($_) } @$_ ] };

declare 'MapStringCancelResumableWriteRequest',
    as HashRef[CancelResumableWriteRequest()];

declare 'CancelResumableWriteResponse',
    as InstanceOf['Google::Storage::V2::Storage::CancelResumableWriteResponse'];

coerce 'CancelResumableWriteResponse',
    from HashRef, via { 'Google::Storage::V2::Storage::CancelResumableWriteResponse'->new($_) };

declare 'RepeatedCancelResumableWriteResponse',
    as ArrayRef[CancelResumableWriteResponse()];

coerce 'RepeatedCancelResumableWriteResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::CancelResumableWriteResponse'->new($_) } @$_ ] };

declare 'MapStringCancelResumableWriteResponse',
    as HashRef[CancelResumableWriteResponse()];

declare 'ReadObjectRequest',
    as InstanceOf['Google::Storage::V2::Storage::ReadObjectRequest'];

coerce 'ReadObjectRequest',
    from HashRef, via { 'Google::Storage::V2::Storage::ReadObjectRequest'->new($_) };

declare 'RepeatedReadObjectRequest',
    as ArrayRef[ReadObjectRequest()];

coerce 'RepeatedReadObjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::ReadObjectRequest'->new($_) } @$_ ] };

declare 'MapStringReadObjectRequest',
    as HashRef[ReadObjectRequest()];

declare 'GetObjectRequest',
    as InstanceOf['Google::Storage::V2::Storage::GetObjectRequest'];

coerce 'GetObjectRequest',
    from HashRef, via { 'Google::Storage::V2::Storage::GetObjectRequest'->new($_) };

declare 'RepeatedGetObjectRequest',
    as ArrayRef[GetObjectRequest()];

coerce 'RepeatedGetObjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::GetObjectRequest'->new($_) } @$_ ] };

declare 'MapStringGetObjectRequest',
    as HashRef[GetObjectRequest()];

declare 'ReadObjectResponse',
    as InstanceOf['Google::Storage::V2::Storage::ReadObjectResponse'];

coerce 'ReadObjectResponse',
    from HashRef, via { 'Google::Storage::V2::Storage::ReadObjectResponse'->new($_) };

declare 'RepeatedReadObjectResponse',
    as ArrayRef[ReadObjectResponse()];

coerce 'RepeatedReadObjectResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::ReadObjectResponse'->new($_) } @$_ ] };

declare 'MapStringReadObjectResponse',
    as HashRef[ReadObjectResponse()];

declare 'BidiReadObjectSpec',
    as InstanceOf['Google::Storage::V2::Storage::BidiReadObjectSpec'];

coerce 'BidiReadObjectSpec',
    from HashRef, via { 'Google::Storage::V2::Storage::BidiReadObjectSpec'->new($_) };

declare 'RepeatedBidiReadObjectSpec',
    as ArrayRef[BidiReadObjectSpec()];

coerce 'RepeatedBidiReadObjectSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::BidiReadObjectSpec'->new($_) } @$_ ] };

declare 'MapStringBidiReadObjectSpec',
    as HashRef[BidiReadObjectSpec()];

declare 'BidiReadObjectRequest',
    as InstanceOf['Google::Storage::V2::Storage::BidiReadObjectRequest'];

coerce 'BidiReadObjectRequest',
    from HashRef, via { 'Google::Storage::V2::Storage::BidiReadObjectRequest'->new($_) };

declare 'RepeatedBidiReadObjectRequest',
    as ArrayRef[BidiReadObjectRequest()];

coerce 'RepeatedBidiReadObjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::BidiReadObjectRequest'->new($_) } @$_ ] };

declare 'MapStringBidiReadObjectRequest',
    as HashRef[BidiReadObjectRequest()];

declare 'BidiReadObjectResponse',
    as InstanceOf['Google::Storage::V2::Storage::BidiReadObjectResponse'];

coerce 'BidiReadObjectResponse',
    from HashRef, via { 'Google::Storage::V2::Storage::BidiReadObjectResponse'->new($_) };

declare 'RepeatedBidiReadObjectResponse',
    as ArrayRef[BidiReadObjectResponse()];

coerce 'RepeatedBidiReadObjectResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::BidiReadObjectResponse'->new($_) } @$_ ] };

declare 'MapStringBidiReadObjectResponse',
    as HashRef[BidiReadObjectResponse()];

declare 'BidiReadObjectRedirectedError',
    as InstanceOf['Google::Storage::V2::Storage::BidiReadObjectRedirectedError'];

coerce 'BidiReadObjectRedirectedError',
    from HashRef, via { 'Google::Storage::V2::Storage::BidiReadObjectRedirectedError'->new($_) };

declare 'RepeatedBidiReadObjectRedirectedError',
    as ArrayRef[BidiReadObjectRedirectedError()];

coerce 'RepeatedBidiReadObjectRedirectedError',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::BidiReadObjectRedirectedError'->new($_) } @$_ ] };

declare 'MapStringBidiReadObjectRedirectedError',
    as HashRef[BidiReadObjectRedirectedError()];

declare 'BidiWriteObjectRedirectedError',
    as InstanceOf['Google::Storage::V2::Storage::BidiWriteObjectRedirectedError'];

coerce 'BidiWriteObjectRedirectedError',
    from HashRef, via { 'Google::Storage::V2::Storage::BidiWriteObjectRedirectedError'->new($_) };

declare 'RepeatedBidiWriteObjectRedirectedError',
    as ArrayRef[BidiWriteObjectRedirectedError()];

coerce 'RepeatedBidiWriteObjectRedirectedError',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::BidiWriteObjectRedirectedError'->new($_) } @$_ ] };

declare 'MapStringBidiWriteObjectRedirectedError',
    as HashRef[BidiWriteObjectRedirectedError()];

declare 'BidiReadObjectError',
    as InstanceOf['Google::Storage::V2::Storage::BidiReadObjectError'];

coerce 'BidiReadObjectError',
    from HashRef, via { 'Google::Storage::V2::Storage::BidiReadObjectError'->new($_) };

declare 'RepeatedBidiReadObjectError',
    as ArrayRef[BidiReadObjectError()];

coerce 'RepeatedBidiReadObjectError',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::BidiReadObjectError'->new($_) } @$_ ] };

declare 'MapStringBidiReadObjectError',
    as HashRef[BidiReadObjectError()];

declare 'ReadRangeError',
    as InstanceOf['Google::Storage::V2::Storage::ReadRangeError'];

coerce 'ReadRangeError',
    from HashRef, via { 'Google::Storage::V2::Storage::ReadRangeError'->new($_) };

declare 'RepeatedReadRangeError',
    as ArrayRef[ReadRangeError()];

coerce 'RepeatedReadRangeError',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::ReadRangeError'->new($_) } @$_ ] };

declare 'MapStringReadRangeError',
    as HashRef[ReadRangeError()];

declare 'ReadRange',
    as InstanceOf['Google::Storage::V2::Storage::ReadRange'];

coerce 'ReadRange',
    from HashRef, via { 'Google::Storage::V2::Storage::ReadRange'->new($_) };

declare 'RepeatedReadRange',
    as ArrayRef[ReadRange()];

coerce 'RepeatedReadRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::ReadRange'->new($_) } @$_ ] };

declare 'MapStringReadRange',
    as HashRef[ReadRange()];

declare 'ObjectRangeData',
    as InstanceOf['Google::Storage::V2::Storage::ObjectRangeData'];

coerce 'ObjectRangeData',
    from HashRef, via { 'Google::Storage::V2::Storage::ObjectRangeData'->new($_) };

declare 'RepeatedObjectRangeData',
    as ArrayRef[ObjectRangeData()];

coerce 'RepeatedObjectRangeData',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::ObjectRangeData'->new($_) } @$_ ] };

declare 'MapStringObjectRangeData',
    as HashRef[ObjectRangeData()];

declare 'BidiReadHandle',
    as InstanceOf['Google::Storage::V2::Storage::BidiReadHandle'];

coerce 'BidiReadHandle',
    from HashRef, via { 'Google::Storage::V2::Storage::BidiReadHandle'->new($_) };

declare 'RepeatedBidiReadHandle',
    as ArrayRef[BidiReadHandle()];

coerce 'RepeatedBidiReadHandle',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::BidiReadHandle'->new($_) } @$_ ] };

declare 'MapStringBidiReadHandle',
    as HashRef[BidiReadHandle()];

declare 'BidiWriteHandle',
    as InstanceOf['Google::Storage::V2::Storage::BidiWriteHandle'];

coerce 'BidiWriteHandle',
    from HashRef, via { 'Google::Storage::V2::Storage::BidiWriteHandle'->new($_) };

declare 'RepeatedBidiWriteHandle',
    as ArrayRef[BidiWriteHandle()];

coerce 'RepeatedBidiWriteHandle',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::BidiWriteHandle'->new($_) } @$_ ] };

declare 'MapStringBidiWriteHandle',
    as HashRef[BidiWriteHandle()];

declare 'WriteObjectSpec',
    as InstanceOf['Google::Storage::V2::Storage::WriteObjectSpec'];

coerce 'WriteObjectSpec',
    from HashRef, via { 'Google::Storage::V2::Storage::WriteObjectSpec'->new($_) };

declare 'RepeatedWriteObjectSpec',
    as ArrayRef[WriteObjectSpec()];

coerce 'RepeatedWriteObjectSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::WriteObjectSpec'->new($_) } @$_ ] };

declare 'MapStringWriteObjectSpec',
    as HashRef[WriteObjectSpec()];

declare 'WriteObjectRequest',
    as InstanceOf['Google::Storage::V2::Storage::WriteObjectRequest'];

coerce 'WriteObjectRequest',
    from HashRef, via { 'Google::Storage::V2::Storage::WriteObjectRequest'->new($_) };

declare 'RepeatedWriteObjectRequest',
    as ArrayRef[WriteObjectRequest()];

coerce 'RepeatedWriteObjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::WriteObjectRequest'->new($_) } @$_ ] };

declare 'MapStringWriteObjectRequest',
    as HashRef[WriteObjectRequest()];

declare 'WriteObjectResponse',
    as InstanceOf['Google::Storage::V2::Storage::WriteObjectResponse'];

coerce 'WriteObjectResponse',
    from HashRef, via { 'Google::Storage::V2::Storage::WriteObjectResponse'->new($_) };

declare 'RepeatedWriteObjectResponse',
    as ArrayRef[WriteObjectResponse()];

coerce 'RepeatedWriteObjectResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::WriteObjectResponse'->new($_) } @$_ ] };

declare 'MapStringWriteObjectResponse',
    as HashRef[WriteObjectResponse()];

declare 'AppendObjectSpec',
    as InstanceOf['Google::Storage::V2::Storage::AppendObjectSpec'];

coerce 'AppendObjectSpec',
    from HashRef, via { 'Google::Storage::V2::Storage::AppendObjectSpec'->new($_) };

declare 'RepeatedAppendObjectSpec',
    as ArrayRef[AppendObjectSpec()];

coerce 'RepeatedAppendObjectSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::AppendObjectSpec'->new($_) } @$_ ] };

declare 'MapStringAppendObjectSpec',
    as HashRef[AppendObjectSpec()];

declare 'BidiWriteObjectRequest',
    as InstanceOf['Google::Storage::V2::Storage::BidiWriteObjectRequest'];

coerce 'BidiWriteObjectRequest',
    from HashRef, via { 'Google::Storage::V2::Storage::BidiWriteObjectRequest'->new($_) };

declare 'RepeatedBidiWriteObjectRequest',
    as ArrayRef[BidiWriteObjectRequest()];

coerce 'RepeatedBidiWriteObjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::BidiWriteObjectRequest'->new($_) } @$_ ] };

declare 'MapStringBidiWriteObjectRequest',
    as HashRef[BidiWriteObjectRequest()];

declare 'BidiWriteObjectResponse',
    as InstanceOf['Google::Storage::V2::Storage::BidiWriteObjectResponse'];

coerce 'BidiWriteObjectResponse',
    from HashRef, via { 'Google::Storage::V2::Storage::BidiWriteObjectResponse'->new($_) };

declare 'RepeatedBidiWriteObjectResponse',
    as ArrayRef[BidiWriteObjectResponse()];

coerce 'RepeatedBidiWriteObjectResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::BidiWriteObjectResponse'->new($_) } @$_ ] };

declare 'MapStringBidiWriteObjectResponse',
    as HashRef[BidiWriteObjectResponse()];

declare 'ListObjectsRequest',
    as InstanceOf['Google::Storage::V2::Storage::ListObjectsRequest'];

coerce 'ListObjectsRequest',
    from HashRef, via { 'Google::Storage::V2::Storage::ListObjectsRequest'->new($_) };

declare 'RepeatedListObjectsRequest',
    as ArrayRef[ListObjectsRequest()];

coerce 'RepeatedListObjectsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::ListObjectsRequest'->new($_) } @$_ ] };

declare 'MapStringListObjectsRequest',
    as HashRef[ListObjectsRequest()];

declare 'QueryWriteStatusRequest',
    as InstanceOf['Google::Storage::V2::Storage::QueryWriteStatusRequest'];

coerce 'QueryWriteStatusRequest',
    from HashRef, via { 'Google::Storage::V2::Storage::QueryWriteStatusRequest'->new($_) };

declare 'RepeatedQueryWriteStatusRequest',
    as ArrayRef[QueryWriteStatusRequest()];

coerce 'RepeatedQueryWriteStatusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::QueryWriteStatusRequest'->new($_) } @$_ ] };

declare 'MapStringQueryWriteStatusRequest',
    as HashRef[QueryWriteStatusRequest()];

declare 'QueryWriteStatusResponse',
    as InstanceOf['Google::Storage::V2::Storage::QueryWriteStatusResponse'];

coerce 'QueryWriteStatusResponse',
    from HashRef, via { 'Google::Storage::V2::Storage::QueryWriteStatusResponse'->new($_) };

declare 'RepeatedQueryWriteStatusResponse',
    as ArrayRef[QueryWriteStatusResponse()];

coerce 'RepeatedQueryWriteStatusResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::QueryWriteStatusResponse'->new($_) } @$_ ] };

declare 'MapStringQueryWriteStatusResponse',
    as HashRef[QueryWriteStatusResponse()];

declare 'RewriteObjectRequest',
    as InstanceOf['Google::Storage::V2::Storage::RewriteObjectRequest'];

coerce 'RewriteObjectRequest',
    from HashRef, via { 'Google::Storage::V2::Storage::RewriteObjectRequest'->new($_) };

declare 'RepeatedRewriteObjectRequest',
    as ArrayRef[RewriteObjectRequest()];

coerce 'RepeatedRewriteObjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::RewriteObjectRequest'->new($_) } @$_ ] };

declare 'MapStringRewriteObjectRequest',
    as HashRef[RewriteObjectRequest()];

declare 'RewriteResponse',
    as InstanceOf['Google::Storage::V2::Storage::RewriteResponse'];

coerce 'RewriteResponse',
    from HashRef, via { 'Google::Storage::V2::Storage::RewriteResponse'->new($_) };

declare 'RepeatedRewriteResponse',
    as ArrayRef[RewriteResponse()];

coerce 'RepeatedRewriteResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::RewriteResponse'->new($_) } @$_ ] };

declare 'MapStringRewriteResponse',
    as HashRef[RewriteResponse()];

declare 'MoveObjectRequest',
    as InstanceOf['Google::Storage::V2::Storage::MoveObjectRequest'];

coerce 'MoveObjectRequest',
    from HashRef, via { 'Google::Storage::V2::Storage::MoveObjectRequest'->new($_) };

declare 'RepeatedMoveObjectRequest',
    as ArrayRef[MoveObjectRequest()];

coerce 'RepeatedMoveObjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::MoveObjectRequest'->new($_) } @$_ ] };

declare 'MapStringMoveObjectRequest',
    as HashRef[MoveObjectRequest()];

declare 'StartResumableWriteRequest',
    as InstanceOf['Google::Storage::V2::Storage::StartResumableWriteRequest'];

coerce 'StartResumableWriteRequest',
    from HashRef, via { 'Google::Storage::V2::Storage::StartResumableWriteRequest'->new($_) };

declare 'RepeatedStartResumableWriteRequest',
    as ArrayRef[StartResumableWriteRequest()];

coerce 'RepeatedStartResumableWriteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::StartResumableWriteRequest'->new($_) } @$_ ] };

declare 'MapStringStartResumableWriteRequest',
    as HashRef[StartResumableWriteRequest()];

declare 'StartResumableWriteResponse',
    as InstanceOf['Google::Storage::V2::Storage::StartResumableWriteResponse'];

coerce 'StartResumableWriteResponse',
    from HashRef, via { 'Google::Storage::V2::Storage::StartResumableWriteResponse'->new($_) };

declare 'RepeatedStartResumableWriteResponse',
    as ArrayRef[StartResumableWriteResponse()];

coerce 'RepeatedStartResumableWriteResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::StartResumableWriteResponse'->new($_) } @$_ ] };

declare 'MapStringStartResumableWriteResponse',
    as HashRef[StartResumableWriteResponse()];

declare 'UpdateObjectRequest',
    as InstanceOf['Google::Storage::V2::Storage::UpdateObjectRequest'];

coerce 'UpdateObjectRequest',
    from HashRef, via { 'Google::Storage::V2::Storage::UpdateObjectRequest'->new($_) };

declare 'RepeatedUpdateObjectRequest',
    as ArrayRef[UpdateObjectRequest()];

coerce 'RepeatedUpdateObjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::UpdateObjectRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateObjectRequest',
    as HashRef[UpdateObjectRequest()];

declare 'CommonObjectRequestParams',
    as InstanceOf['Google::Storage::V2::Storage::CommonObjectRequestParams'];

coerce 'CommonObjectRequestParams',
    from HashRef, via { 'Google::Storage::V2::Storage::CommonObjectRequestParams'->new($_) };

declare 'RepeatedCommonObjectRequestParams',
    as ArrayRef[CommonObjectRequestParams()];

coerce 'RepeatedCommonObjectRequestParams',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::CommonObjectRequestParams'->new($_) } @$_ ] };

declare 'MapStringCommonObjectRequestParams',
    as HashRef[CommonObjectRequestParams()];

declare 'ServiceConstants',
    as InstanceOf['Google::Storage::V2::Storage::ServiceConstants'];

coerce 'ServiceConstants',
    from HashRef, via { 'Google::Storage::V2::Storage::ServiceConstants'->new($_) };

declare 'RepeatedServiceConstants',
    as ArrayRef[ServiceConstants()];

coerce 'RepeatedServiceConstants',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::ServiceConstants'->new($_) } @$_ ] };

declare 'MapStringServiceConstants',
    as HashRef[ServiceConstants()];

declare 'Values',
    as (Int | Str);

declare 'Bucket',
    as InstanceOf['Google::Storage::V2::Storage::Bucket'];

coerce 'Bucket',
    from HashRef, via { 'Google::Storage::V2::Storage::Bucket'->new($_) };

declare 'RepeatedBucket',
    as ArrayRef[Bucket()];

coerce 'RepeatedBucket',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::Bucket'->new($_) } @$_ ] };

declare 'MapStringBucket',
    as HashRef[Bucket()];

declare 'Billing',
    as InstanceOf['Google::Storage::V2::Storage::Bucket::Billing'];

coerce 'Billing',
    from HashRef, via { 'Google::Storage::V2::Storage::Bucket::Billing'->new($_) };

declare 'RepeatedBilling',
    as ArrayRef[Billing()];

coerce 'RepeatedBilling',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::Bucket::Billing'->new($_) } @$_ ] };

declare 'MapStringBilling',
    as HashRef[Billing()];

declare 'Cors',
    as InstanceOf['Google::Storage::V2::Storage::Bucket::Cors'];

coerce 'Cors',
    from HashRef, via { 'Google::Storage::V2::Storage::Bucket::Cors'->new($_) };

declare 'RepeatedCors',
    as ArrayRef[Cors()];

coerce 'RepeatedCors',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::Bucket::Cors'->new($_) } @$_ ] };

declare 'MapStringCors',
    as HashRef[Cors()];

declare 'Encryption',
    as InstanceOf['Google::Storage::V2::Storage::Bucket::Encryption'];

coerce 'Encryption',
    from HashRef, via { 'Google::Storage::V2::Storage::Bucket::Encryption'->new($_) };

declare 'RepeatedEncryption',
    as ArrayRef[Encryption()];

coerce 'RepeatedEncryption',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::Bucket::Encryption'->new($_) } @$_ ] };

declare 'MapStringEncryption',
    as HashRef[Encryption()];

declare 'GoogleManagedEncryptionEnforcementConfig',
    as InstanceOf['Google::Storage::V2::Storage::Bucket::Encryption::GoogleManagedEncryptionEnforcementConfig'];

coerce 'GoogleManagedEncryptionEnforcementConfig',
    from HashRef, via { 'Google::Storage::V2::Storage::Bucket::Encryption::GoogleManagedEncryptionEnforcementConfig'->new($_) };

declare 'RepeatedGoogleManagedEncryptionEnforcementConfig',
    as ArrayRef[GoogleManagedEncryptionEnforcementConfig()];

coerce 'RepeatedGoogleManagedEncryptionEnforcementConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::Bucket::Encryption::GoogleManagedEncryptionEnforcementConfig'->new($_) } @$_ ] };

declare 'MapStringGoogleManagedEncryptionEnforcementConfig',
    as HashRef[GoogleManagedEncryptionEnforcementConfig()];

declare 'CustomerManagedEncryptionEnforcementConfig',
    as InstanceOf['Google::Storage::V2::Storage::Bucket::Encryption::CustomerManagedEncryptionEnforcementConfig'];

coerce 'CustomerManagedEncryptionEnforcementConfig',
    from HashRef, via { 'Google::Storage::V2::Storage::Bucket::Encryption::CustomerManagedEncryptionEnforcementConfig'->new($_) };

declare 'RepeatedCustomerManagedEncryptionEnforcementConfig',
    as ArrayRef[CustomerManagedEncryptionEnforcementConfig()];

coerce 'RepeatedCustomerManagedEncryptionEnforcementConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::Bucket::Encryption::CustomerManagedEncryptionEnforcementConfig'->new($_) } @$_ ] };

declare 'MapStringCustomerManagedEncryptionEnforcementConfig',
    as HashRef[CustomerManagedEncryptionEnforcementConfig()];

declare 'CustomerSuppliedEncryptionEnforcementConfig',
    as InstanceOf['Google::Storage::V2::Storage::Bucket::Encryption::CustomerSuppliedEncryptionEnforcementConfig'];

coerce 'CustomerSuppliedEncryptionEnforcementConfig',
    from HashRef, via { 'Google::Storage::V2::Storage::Bucket::Encryption::CustomerSuppliedEncryptionEnforcementConfig'->new($_) };

declare 'RepeatedCustomerSuppliedEncryptionEnforcementConfig',
    as ArrayRef[CustomerSuppliedEncryptionEnforcementConfig()];

coerce 'RepeatedCustomerSuppliedEncryptionEnforcementConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::Bucket::Encryption::CustomerSuppliedEncryptionEnforcementConfig'->new($_) } @$_ ] };

declare 'MapStringCustomerSuppliedEncryptionEnforcementConfig',
    as HashRef[CustomerSuppliedEncryptionEnforcementConfig()];

declare 'IamConfig',
    as InstanceOf['Google::Storage::V2::Storage::Bucket::IamConfig'];

coerce 'IamConfig',
    from HashRef, via { 'Google::Storage::V2::Storage::Bucket::IamConfig'->new($_) };

declare 'RepeatedIamConfig',
    as ArrayRef[IamConfig()];

coerce 'RepeatedIamConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::Bucket::IamConfig'->new($_) } @$_ ] };

declare 'MapStringIamConfig',
    as HashRef[IamConfig()];

declare 'UniformBucketLevelAccess',
    as InstanceOf['Google::Storage::V2::Storage::Bucket::IamConfig::UniformBucketLevelAccess'];

coerce 'UniformBucketLevelAccess',
    from HashRef, via { 'Google::Storage::V2::Storage::Bucket::IamConfig::UniformBucketLevelAccess'->new($_) };

declare 'RepeatedUniformBucketLevelAccess',
    as ArrayRef[UniformBucketLevelAccess()];

coerce 'RepeatedUniformBucketLevelAccess',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::Bucket::IamConfig::UniformBucketLevelAccess'->new($_) } @$_ ] };

declare 'MapStringUniformBucketLevelAccess',
    as HashRef[UniformBucketLevelAccess()];

declare 'Lifecycle',
    as InstanceOf['Google::Storage::V2::Storage::Bucket::Lifecycle'];

coerce 'Lifecycle',
    from HashRef, via { 'Google::Storage::V2::Storage::Bucket::Lifecycle'->new($_) };

declare 'RepeatedLifecycle',
    as ArrayRef[Lifecycle()];

coerce 'RepeatedLifecycle',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::Bucket::Lifecycle'->new($_) } @$_ ] };

declare 'MapStringLifecycle',
    as HashRef[Lifecycle()];

declare 'Rule',
    as InstanceOf['Google::Storage::V2::Storage::Bucket::Lifecycle::Rule'];

coerce 'Rule',
    from HashRef, via { 'Google::Storage::V2::Storage::Bucket::Lifecycle::Rule'->new($_) };

declare 'RepeatedRule',
    as ArrayRef[Rule()];

coerce 'RepeatedRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::Bucket::Lifecycle::Rule'->new($_) } @$_ ] };

declare 'MapStringRule',
    as HashRef[Rule()];

declare 'Action',
    as InstanceOf['Google::Storage::V2::Storage::Bucket::Lifecycle::Rule::Action'];

coerce 'Action',
    from HashRef, via { 'Google::Storage::V2::Storage::Bucket::Lifecycle::Rule::Action'->new($_) };

declare 'RepeatedAction',
    as ArrayRef[Action()];

coerce 'RepeatedAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::Bucket::Lifecycle::Rule::Action'->new($_) } @$_ ] };

declare 'MapStringAction',
    as HashRef[Action()];

declare 'Condition',
    as InstanceOf['Google::Storage::V2::Storage::Bucket::Lifecycle::Rule::Condition'];

coerce 'Condition',
    from HashRef, via { 'Google::Storage::V2::Storage::Bucket::Lifecycle::Rule::Condition'->new($_) };

declare 'RepeatedCondition',
    as ArrayRef[Condition()];

coerce 'RepeatedCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::Bucket::Lifecycle::Rule::Condition'->new($_) } @$_ ] };

declare 'MapStringCondition',
    as HashRef[Condition()];

declare 'Logging',
    as InstanceOf['Google::Storage::V2::Storage::Bucket::Logging'];

coerce 'Logging',
    from HashRef, via { 'Google::Storage::V2::Storage::Bucket::Logging'->new($_) };

declare 'RepeatedLogging',
    as ArrayRef[Logging()];

coerce 'RepeatedLogging',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::Bucket::Logging'->new($_) } @$_ ] };

declare 'MapStringLogging',
    as HashRef[Logging()];

declare 'ObjectRetention',
    as InstanceOf['Google::Storage::V2::Storage::Bucket::ObjectRetention'];

coerce 'ObjectRetention',
    from HashRef, via { 'Google::Storage::V2::Storage::Bucket::ObjectRetention'->new($_) };

declare 'RepeatedObjectRetention',
    as ArrayRef[ObjectRetention()];

coerce 'RepeatedObjectRetention',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::Bucket::ObjectRetention'->new($_) } @$_ ] };

declare 'MapStringObjectRetention',
    as HashRef[ObjectRetention()];

declare 'RetentionPolicy',
    as InstanceOf['Google::Storage::V2::Storage::Bucket::RetentionPolicy'];

coerce 'RetentionPolicy',
    from HashRef, via { 'Google::Storage::V2::Storage::Bucket::RetentionPolicy'->new($_) };

declare 'RepeatedRetentionPolicy',
    as ArrayRef[RetentionPolicy()];

coerce 'RepeatedRetentionPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::Bucket::RetentionPolicy'->new($_) } @$_ ] };

declare 'MapStringRetentionPolicy',
    as HashRef[RetentionPolicy()];

declare 'SoftDeletePolicy',
    as InstanceOf['Google::Storage::V2::Storage::Bucket::SoftDeletePolicy'];

coerce 'SoftDeletePolicy',
    from HashRef, via { 'Google::Storage::V2::Storage::Bucket::SoftDeletePolicy'->new($_) };

declare 'RepeatedSoftDeletePolicy',
    as ArrayRef[SoftDeletePolicy()];

coerce 'RepeatedSoftDeletePolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::Bucket::SoftDeletePolicy'->new($_) } @$_ ] };

declare 'MapStringSoftDeletePolicy',
    as HashRef[SoftDeletePolicy()];

declare 'Versioning',
    as InstanceOf['Google::Storage::V2::Storage::Bucket::Versioning'];

coerce 'Versioning',
    from HashRef, via { 'Google::Storage::V2::Storage::Bucket::Versioning'->new($_) };

declare 'RepeatedVersioning',
    as ArrayRef[Versioning()];

coerce 'RepeatedVersioning',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::Bucket::Versioning'->new($_) } @$_ ] };

declare 'MapStringVersioning',
    as HashRef[Versioning()];

declare 'Website',
    as InstanceOf['Google::Storage::V2::Storage::Bucket::Website'];

coerce 'Website',
    from HashRef, via { 'Google::Storage::V2::Storage::Bucket::Website'->new($_) };

declare 'RepeatedWebsite',
    as ArrayRef[Website()];

coerce 'RepeatedWebsite',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::Bucket::Website'->new($_) } @$_ ] };

declare 'MapStringWebsite',
    as HashRef[Website()];

declare 'CustomPlacementConfig',
    as InstanceOf['Google::Storage::V2::Storage::Bucket::CustomPlacementConfig'];

coerce 'CustomPlacementConfig',
    from HashRef, via { 'Google::Storage::V2::Storage::Bucket::CustomPlacementConfig'->new($_) };

declare 'RepeatedCustomPlacementConfig',
    as ArrayRef[CustomPlacementConfig()];

coerce 'RepeatedCustomPlacementConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::Bucket::CustomPlacementConfig'->new($_) } @$_ ] };

declare 'MapStringCustomPlacementConfig',
    as HashRef[CustomPlacementConfig()];

declare 'Autoclass',
    as InstanceOf['Google::Storage::V2::Storage::Bucket::Autoclass'];

coerce 'Autoclass',
    from HashRef, via { 'Google::Storage::V2::Storage::Bucket::Autoclass'->new($_) };

declare 'RepeatedAutoclass',
    as ArrayRef[Autoclass()];

coerce 'RepeatedAutoclass',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::Bucket::Autoclass'->new($_) } @$_ ] };

declare 'MapStringAutoclass',
    as HashRef[Autoclass()];

declare 'IpFilter',
    as InstanceOf['Google::Storage::V2::Storage::Bucket::IpFilter'];

coerce 'IpFilter',
    from HashRef, via { 'Google::Storage::V2::Storage::Bucket::IpFilter'->new($_) };

declare 'RepeatedIpFilter',
    as ArrayRef[IpFilter()];

coerce 'RepeatedIpFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::Bucket::IpFilter'->new($_) } @$_ ] };

declare 'MapStringIpFilter',
    as HashRef[IpFilter()];

declare 'PublicNetworkSource',
    as InstanceOf['Google::Storage::V2::Storage::Bucket::IpFilter::PublicNetworkSource'];

coerce 'PublicNetworkSource',
    from HashRef, via { 'Google::Storage::V2::Storage::Bucket::IpFilter::PublicNetworkSource'->new($_) };

declare 'RepeatedPublicNetworkSource',
    as ArrayRef[PublicNetworkSource()];

coerce 'RepeatedPublicNetworkSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::Bucket::IpFilter::PublicNetworkSource'->new($_) } @$_ ] };

declare 'MapStringPublicNetworkSource',
    as HashRef[PublicNetworkSource()];

declare 'VpcNetworkSource',
    as InstanceOf['Google::Storage::V2::Storage::Bucket::IpFilter::VpcNetworkSource'];

coerce 'VpcNetworkSource',
    from HashRef, via { 'Google::Storage::V2::Storage::Bucket::IpFilter::VpcNetworkSource'->new($_) };

declare 'RepeatedVpcNetworkSource',
    as ArrayRef[VpcNetworkSource()];

coerce 'RepeatedVpcNetworkSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::Bucket::IpFilter::VpcNetworkSource'->new($_) } @$_ ] };

declare 'MapStringVpcNetworkSource',
    as HashRef[VpcNetworkSource()];

declare 'HierarchicalNamespace',
    as InstanceOf['Google::Storage::V2::Storage::Bucket::HierarchicalNamespace'];

coerce 'HierarchicalNamespace',
    from HashRef, via { 'Google::Storage::V2::Storage::Bucket::HierarchicalNamespace'->new($_) };

declare 'RepeatedHierarchicalNamespace',
    as ArrayRef[HierarchicalNamespace()];

coerce 'RepeatedHierarchicalNamespace',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::Bucket::HierarchicalNamespace'->new($_) } @$_ ] };

declare 'MapStringHierarchicalNamespace',
    as HashRef[HierarchicalNamespace()];

declare 'LabelsEntry',
    as InstanceOf['Google::Storage::V2::Storage::Bucket::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Storage::V2::Storage::Bucket::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::Bucket::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'BucketAccessControl',
    as InstanceOf['Google::Storage::V2::Storage::BucketAccessControl'];

coerce 'BucketAccessControl',
    from HashRef, via { 'Google::Storage::V2::Storage::BucketAccessControl'->new($_) };

declare 'RepeatedBucketAccessControl',
    as ArrayRef[BucketAccessControl()];

coerce 'RepeatedBucketAccessControl',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::BucketAccessControl'->new($_) } @$_ ] };

declare 'MapStringBucketAccessControl',
    as HashRef[BucketAccessControl()];

declare 'ChecksummedData',
    as InstanceOf['Google::Storage::V2::Storage::ChecksummedData'];

coerce 'ChecksummedData',
    from HashRef, via { 'Google::Storage::V2::Storage::ChecksummedData'->new($_) };

declare 'RepeatedChecksummedData',
    as ArrayRef[ChecksummedData()];

coerce 'RepeatedChecksummedData',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::ChecksummedData'->new($_) } @$_ ] };

declare 'MapStringChecksummedData',
    as HashRef[ChecksummedData()];

declare 'ObjectChecksums',
    as InstanceOf['Google::Storage::V2::Storage::ObjectChecksums'];

coerce 'ObjectChecksums',
    from HashRef, via { 'Google::Storage::V2::Storage::ObjectChecksums'->new($_) };

declare 'RepeatedObjectChecksums',
    as ArrayRef[ObjectChecksums()];

coerce 'RepeatedObjectChecksums',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::ObjectChecksums'->new($_) } @$_ ] };

declare 'MapStringObjectChecksums',
    as HashRef[ObjectChecksums()];

declare 'ObjectCustomContextPayload',
    as InstanceOf['Google::Storage::V2::Storage::ObjectCustomContextPayload'];

coerce 'ObjectCustomContextPayload',
    from HashRef, via { 'Google::Storage::V2::Storage::ObjectCustomContextPayload'->new($_) };

declare 'RepeatedObjectCustomContextPayload',
    as ArrayRef[ObjectCustomContextPayload()];

coerce 'RepeatedObjectCustomContextPayload',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::ObjectCustomContextPayload'->new($_) } @$_ ] };

declare 'MapStringObjectCustomContextPayload',
    as HashRef[ObjectCustomContextPayload()];

declare 'ObjectContexts',
    as InstanceOf['Google::Storage::V2::Storage::ObjectContexts'];

coerce 'ObjectContexts',
    from HashRef, via { 'Google::Storage::V2::Storage::ObjectContexts'->new($_) };

declare 'RepeatedObjectContexts',
    as ArrayRef[ObjectContexts()];

coerce 'RepeatedObjectContexts',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::ObjectContexts'->new($_) } @$_ ] };

declare 'MapStringObjectContexts',
    as HashRef[ObjectContexts()];

declare 'CustomEntry',
    as InstanceOf['Google::Storage::V2::Storage::ObjectContexts::CustomEntry'];

coerce 'CustomEntry',
    from HashRef, via { 'Google::Storage::V2::Storage::ObjectContexts::CustomEntry'->new($_) };

declare 'RepeatedCustomEntry',
    as ArrayRef[CustomEntry()];

coerce 'RepeatedCustomEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::ObjectContexts::CustomEntry'->new($_) } @$_ ] };

declare 'MapStringCustomEntry',
    as HashRef[CustomEntry()];

declare 'CustomerEncryption',
    as InstanceOf['Google::Storage::V2::Storage::CustomerEncryption'];

coerce 'CustomerEncryption',
    from HashRef, via { 'Google::Storage::V2::Storage::CustomerEncryption'->new($_) };

declare 'RepeatedCustomerEncryption',
    as ArrayRef[CustomerEncryption()];

coerce 'RepeatedCustomerEncryption',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::CustomerEncryption'->new($_) } @$_ ] };

declare 'MapStringCustomerEncryption',
    as HashRef[CustomerEncryption()];

declare 'Object',
    as InstanceOf['Google::Storage::V2::Storage::Object'];

coerce 'Object',
    from HashRef, via { 'Google::Storage::V2::Storage::Object'->new($_) };

declare 'RepeatedObject',
    as ArrayRef[Object()];

coerce 'RepeatedObject',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::Object'->new($_) } @$_ ] };

declare 'MapStringObject',
    as HashRef[Object()];

declare 'Retention',
    as InstanceOf['Google::Storage::V2::Storage::Object::Retention'];

coerce 'Retention',
    from HashRef, via { 'Google::Storage::V2::Storage::Object::Retention'->new($_) };

declare 'RepeatedRetention',
    as ArrayRef[Retention()];

coerce 'RepeatedRetention',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::Object::Retention'->new($_) } @$_ ] };

declare 'MapStringRetention',
    as HashRef[Retention()];

declare 'Mode',
    as (Int | Str);

declare 'MetadataEntry',
    as InstanceOf['Google::Storage::V2::Storage::Object::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Storage::V2::Storage::Object::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::Object::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'ObjectAccessControl',
    as InstanceOf['Google::Storage::V2::Storage::ObjectAccessControl'];

coerce 'ObjectAccessControl',
    from HashRef, via { 'Google::Storage::V2::Storage::ObjectAccessControl'->new($_) };

declare 'RepeatedObjectAccessControl',
    as ArrayRef[ObjectAccessControl()];

coerce 'RepeatedObjectAccessControl',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::ObjectAccessControl'->new($_) } @$_ ] };

declare 'MapStringObjectAccessControl',
    as HashRef[ObjectAccessControl()];

declare 'ListObjectsResponse',
    as InstanceOf['Google::Storage::V2::Storage::ListObjectsResponse'];

coerce 'ListObjectsResponse',
    from HashRef, via { 'Google::Storage::V2::Storage::ListObjectsResponse'->new($_) };

declare 'RepeatedListObjectsResponse',
    as ArrayRef[ListObjectsResponse()];

coerce 'RepeatedListObjectsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::ListObjectsResponse'->new($_) } @$_ ] };

declare 'MapStringListObjectsResponse',
    as HashRef[ListObjectsResponse()];

declare 'ProjectTeam',
    as InstanceOf['Google::Storage::V2::Storage::ProjectTeam'];

coerce 'ProjectTeam',
    from HashRef, via { 'Google::Storage::V2::Storage::ProjectTeam'->new($_) };

declare 'RepeatedProjectTeam',
    as ArrayRef[ProjectTeam()];

coerce 'RepeatedProjectTeam',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::ProjectTeam'->new($_) } @$_ ] };

declare 'MapStringProjectTeam',
    as HashRef[ProjectTeam()];

declare 'Owner',
    as InstanceOf['Google::Storage::V2::Storage::Owner'];

coerce 'Owner',
    from HashRef, via { 'Google::Storage::V2::Storage::Owner'->new($_) };

declare 'RepeatedOwner',
    as ArrayRef[Owner()];

coerce 'RepeatedOwner',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::Owner'->new($_) } @$_ ] };

declare 'MapStringOwner',
    as HashRef[Owner()];

declare 'ContentRange',
    as InstanceOf['Google::Storage::V2::Storage::ContentRange'];

coerce 'ContentRange',
    from HashRef, via { 'Google::Storage::V2::Storage::ContentRange'->new($_) };

declare 'RepeatedContentRange',
    as ArrayRef[ContentRange()];

coerce 'RepeatedContentRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V2::Storage::ContentRange'->new($_) } @$_ ] };

declare 'MapStringContentRange',
    as HashRef[ContentRange()];

1;

__END__

=head1 NAME

Google::Storage::V2::Storage::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
