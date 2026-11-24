package Google::Storage::V1::StorageResources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Bucket',
    as InstanceOf['Google::Storage::V1::StorageResources::Bucket'];

coerce 'Bucket',
    from HashRef, via { 'Google::Storage::V1::StorageResources::Bucket'->new($_) };

declare 'RepeatedBucket',
    as ArrayRef[Bucket()];

coerce 'RepeatedBucket',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::Bucket'->new($_) } @$_ ] };

declare 'MapStringBucket',
    as HashRef[Bucket()];

declare 'Billing',
    as InstanceOf['Google::Storage::V1::StorageResources::Bucket::Billing'];

coerce 'Billing',
    from HashRef, via { 'Google::Storage::V1::StorageResources::Bucket::Billing'->new($_) };

declare 'RepeatedBilling',
    as ArrayRef[Billing()];

coerce 'RepeatedBilling',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::Bucket::Billing'->new($_) } @$_ ] };

declare 'MapStringBilling',
    as HashRef[Billing()];

declare 'Cors',
    as InstanceOf['Google::Storage::V1::StorageResources::Bucket::Cors'];

coerce 'Cors',
    from HashRef, via { 'Google::Storage::V1::StorageResources::Bucket::Cors'->new($_) };

declare 'RepeatedCors',
    as ArrayRef[Cors()];

coerce 'RepeatedCors',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::Bucket::Cors'->new($_) } @$_ ] };

declare 'MapStringCors',
    as HashRef[Cors()];

declare 'Encryption',
    as InstanceOf['Google::Storage::V1::StorageResources::Bucket::Encryption'];

coerce 'Encryption',
    from HashRef, via { 'Google::Storage::V1::StorageResources::Bucket::Encryption'->new($_) };

declare 'RepeatedEncryption',
    as ArrayRef[Encryption()];

coerce 'RepeatedEncryption',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::Bucket::Encryption'->new($_) } @$_ ] };

declare 'MapStringEncryption',
    as HashRef[Encryption()];

declare 'IamConfiguration',
    as InstanceOf['Google::Storage::V1::StorageResources::Bucket::IamConfiguration'];

coerce 'IamConfiguration',
    from HashRef, via { 'Google::Storage::V1::StorageResources::Bucket::IamConfiguration'->new($_) };

declare 'RepeatedIamConfiguration',
    as ArrayRef[IamConfiguration()];

coerce 'RepeatedIamConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::Bucket::IamConfiguration'->new($_) } @$_ ] };

declare 'MapStringIamConfiguration',
    as HashRef[IamConfiguration()];

declare 'PublicAccessPrevention',
    as (Int | Str);

declare 'UniformBucketLevelAccess',
    as InstanceOf['Google::Storage::V1::StorageResources::Bucket::IamConfiguration::UniformBucketLevelAccess'];

coerce 'UniformBucketLevelAccess',
    from HashRef, via { 'Google::Storage::V1::StorageResources::Bucket::IamConfiguration::UniformBucketLevelAccess'->new($_) };

declare 'RepeatedUniformBucketLevelAccess',
    as ArrayRef[UniformBucketLevelAccess()];

coerce 'RepeatedUniformBucketLevelAccess',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::Bucket::IamConfiguration::UniformBucketLevelAccess'->new($_) } @$_ ] };

declare 'MapStringUniformBucketLevelAccess',
    as HashRef[UniformBucketLevelAccess()];

declare 'Lifecycle',
    as InstanceOf['Google::Storage::V1::StorageResources::Bucket::Lifecycle'];

coerce 'Lifecycle',
    from HashRef, via { 'Google::Storage::V1::StorageResources::Bucket::Lifecycle'->new($_) };

declare 'RepeatedLifecycle',
    as ArrayRef[Lifecycle()];

coerce 'RepeatedLifecycle',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::Bucket::Lifecycle'->new($_) } @$_ ] };

declare 'MapStringLifecycle',
    as HashRef[Lifecycle()];

declare 'Rule',
    as InstanceOf['Google::Storage::V1::StorageResources::Bucket::Lifecycle::Rule'];

coerce 'Rule',
    from HashRef, via { 'Google::Storage::V1::StorageResources::Bucket::Lifecycle::Rule'->new($_) };

declare 'RepeatedRule',
    as ArrayRef[Rule()];

coerce 'RepeatedRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::Bucket::Lifecycle::Rule'->new($_) } @$_ ] };

declare 'MapStringRule',
    as HashRef[Rule()];

declare 'Action',
    as InstanceOf['Google::Storage::V1::StorageResources::Bucket::Lifecycle::Rule::Action'];

coerce 'Action',
    from HashRef, via { 'Google::Storage::V1::StorageResources::Bucket::Lifecycle::Rule::Action'->new($_) };

declare 'RepeatedAction',
    as ArrayRef[Action()];

coerce 'RepeatedAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::Bucket::Lifecycle::Rule::Action'->new($_) } @$_ ] };

declare 'MapStringAction',
    as HashRef[Action()];

declare 'Condition',
    as InstanceOf['Google::Storage::V1::StorageResources::Bucket::Lifecycle::Rule::Condition'];

coerce 'Condition',
    from HashRef, via { 'Google::Storage::V1::StorageResources::Bucket::Lifecycle::Rule::Condition'->new($_) };

declare 'RepeatedCondition',
    as ArrayRef[Condition()];

coerce 'RepeatedCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::Bucket::Lifecycle::Rule::Condition'->new($_) } @$_ ] };

declare 'MapStringCondition',
    as HashRef[Condition()];

declare 'Logging',
    as InstanceOf['Google::Storage::V1::StorageResources::Bucket::Logging'];

coerce 'Logging',
    from HashRef, via { 'Google::Storage::V1::StorageResources::Bucket::Logging'->new($_) };

declare 'RepeatedLogging',
    as ArrayRef[Logging()];

coerce 'RepeatedLogging',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::Bucket::Logging'->new($_) } @$_ ] };

declare 'MapStringLogging',
    as HashRef[Logging()];

declare 'RetentionPolicy',
    as InstanceOf['Google::Storage::V1::StorageResources::Bucket::RetentionPolicy'];

coerce 'RetentionPolicy',
    from HashRef, via { 'Google::Storage::V1::StorageResources::Bucket::RetentionPolicy'->new($_) };

declare 'RepeatedRetentionPolicy',
    as ArrayRef[RetentionPolicy()];

coerce 'RepeatedRetentionPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::Bucket::RetentionPolicy'->new($_) } @$_ ] };

declare 'MapStringRetentionPolicy',
    as HashRef[RetentionPolicy()];

declare 'Versioning',
    as InstanceOf['Google::Storage::V1::StorageResources::Bucket::Versioning'];

coerce 'Versioning',
    from HashRef, via { 'Google::Storage::V1::StorageResources::Bucket::Versioning'->new($_) };

declare 'RepeatedVersioning',
    as ArrayRef[Versioning()];

coerce 'RepeatedVersioning',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::Bucket::Versioning'->new($_) } @$_ ] };

declare 'MapStringVersioning',
    as HashRef[Versioning()];

declare 'Website',
    as InstanceOf['Google::Storage::V1::StorageResources::Bucket::Website'];

coerce 'Website',
    from HashRef, via { 'Google::Storage::V1::StorageResources::Bucket::Website'->new($_) };

declare 'RepeatedWebsite',
    as ArrayRef[Website()];

coerce 'RepeatedWebsite',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::Bucket::Website'->new($_) } @$_ ] };

declare 'MapStringWebsite',
    as HashRef[Website()];

declare 'Autoclass',
    as InstanceOf['Google::Storage::V1::StorageResources::Bucket::Autoclass'];

coerce 'Autoclass',
    from HashRef, via { 'Google::Storage::V1::StorageResources::Bucket::Autoclass'->new($_) };

declare 'RepeatedAutoclass',
    as ArrayRef[Autoclass()];

coerce 'RepeatedAutoclass',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::Bucket::Autoclass'->new($_) } @$_ ] };

declare 'MapStringAutoclass',
    as HashRef[Autoclass()];

declare 'LabelsEntry',
    as InstanceOf['Google::Storage::V1::StorageResources::Bucket::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Storage::V1::StorageResources::Bucket::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::Bucket::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'BucketAccessControl',
    as InstanceOf['Google::Storage::V1::StorageResources::BucketAccessControl'];

coerce 'BucketAccessControl',
    from HashRef, via { 'Google::Storage::V1::StorageResources::BucketAccessControl'->new($_) };

declare 'RepeatedBucketAccessControl',
    as ArrayRef[BucketAccessControl()];

coerce 'RepeatedBucketAccessControl',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::BucketAccessControl'->new($_) } @$_ ] };

declare 'MapStringBucketAccessControl',
    as HashRef[BucketAccessControl()];

declare 'ListBucketAccessControlsResponse',
    as InstanceOf['Google::Storage::V1::StorageResources::ListBucketAccessControlsResponse'];

coerce 'ListBucketAccessControlsResponse',
    from HashRef, via { 'Google::Storage::V1::StorageResources::ListBucketAccessControlsResponse'->new($_) };

declare 'RepeatedListBucketAccessControlsResponse',
    as ArrayRef[ListBucketAccessControlsResponse()];

coerce 'RepeatedListBucketAccessControlsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::ListBucketAccessControlsResponse'->new($_) } @$_ ] };

declare 'MapStringListBucketAccessControlsResponse',
    as HashRef[ListBucketAccessControlsResponse()];

declare 'ListBucketsResponse',
    as InstanceOf['Google::Storage::V1::StorageResources::ListBucketsResponse'];

coerce 'ListBucketsResponse',
    from HashRef, via { 'Google::Storage::V1::StorageResources::ListBucketsResponse'->new($_) };

declare 'RepeatedListBucketsResponse',
    as ArrayRef[ListBucketsResponse()];

coerce 'RepeatedListBucketsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::ListBucketsResponse'->new($_) } @$_ ] };

declare 'MapStringListBucketsResponse',
    as HashRef[ListBucketsResponse()];

declare 'Channel',
    as InstanceOf['Google::Storage::V1::StorageResources::Channel'];

coerce 'Channel',
    from HashRef, via { 'Google::Storage::V1::StorageResources::Channel'->new($_) };

declare 'RepeatedChannel',
    as ArrayRef[Channel()];

coerce 'RepeatedChannel',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::Channel'->new($_) } @$_ ] };

declare 'MapStringChannel',
    as HashRef[Channel()];

declare 'ParamsEntry',
    as InstanceOf['Google::Storage::V1::StorageResources::Channel::ParamsEntry'];

coerce 'ParamsEntry',
    from HashRef, via { 'Google::Storage::V1::StorageResources::Channel::ParamsEntry'->new($_) };

declare 'RepeatedParamsEntry',
    as ArrayRef[ParamsEntry()];

coerce 'RepeatedParamsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::Channel::ParamsEntry'->new($_) } @$_ ] };

declare 'MapStringParamsEntry',
    as HashRef[ParamsEntry()];

declare 'ListChannelsResponse',
    as InstanceOf['Google::Storage::V1::StorageResources::ListChannelsResponse'];

coerce 'ListChannelsResponse',
    from HashRef, via { 'Google::Storage::V1::StorageResources::ListChannelsResponse'->new($_) };

declare 'RepeatedListChannelsResponse',
    as ArrayRef[ListChannelsResponse()];

coerce 'RepeatedListChannelsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::ListChannelsResponse'->new($_) } @$_ ] };

declare 'MapStringListChannelsResponse',
    as HashRef[ListChannelsResponse()];

declare 'Items',
    as InstanceOf['Google::Storage::V1::StorageResources::ListChannelsResponse::Items'];

coerce 'Items',
    from HashRef, via { 'Google::Storage::V1::StorageResources::ListChannelsResponse::Items'->new($_) };

declare 'RepeatedItems',
    as ArrayRef[Items()];

coerce 'RepeatedItems',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::ListChannelsResponse::Items'->new($_) } @$_ ] };

declare 'MapStringItems',
    as HashRef[Items()];

declare 'ChecksummedData',
    as InstanceOf['Google::Storage::V1::StorageResources::ChecksummedData'];

coerce 'ChecksummedData',
    from HashRef, via { 'Google::Storage::V1::StorageResources::ChecksummedData'->new($_) };

declare 'RepeatedChecksummedData',
    as ArrayRef[ChecksummedData()];

coerce 'RepeatedChecksummedData',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::ChecksummedData'->new($_) } @$_ ] };

declare 'MapStringChecksummedData',
    as HashRef[ChecksummedData()];

declare 'ObjectChecksums',
    as InstanceOf['Google::Storage::V1::StorageResources::ObjectChecksums'];

coerce 'ObjectChecksums',
    from HashRef, via { 'Google::Storage::V1::StorageResources::ObjectChecksums'->new($_) };

declare 'RepeatedObjectChecksums',
    as ArrayRef[ObjectChecksums()];

coerce 'RepeatedObjectChecksums',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::ObjectChecksums'->new($_) } @$_ ] };

declare 'MapStringObjectChecksums',
    as HashRef[ObjectChecksums()];

declare 'CommonEnums',
    as InstanceOf['Google::Storage::V1::StorageResources::CommonEnums'];

coerce 'CommonEnums',
    from HashRef, via { 'Google::Storage::V1::StorageResources::CommonEnums'->new($_) };

declare 'RepeatedCommonEnums',
    as ArrayRef[CommonEnums()];

coerce 'RepeatedCommonEnums',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::CommonEnums'->new($_) } @$_ ] };

declare 'MapStringCommonEnums',
    as HashRef[CommonEnums()];

declare 'Projection',
    as (Int | Str);

declare 'PredefinedBucketAcl',
    as (Int | Str);

declare 'PredefinedObjectAcl',
    as (Int | Str);

declare 'ContentRange',
    as InstanceOf['Google::Storage::V1::StorageResources::ContentRange'];

coerce 'ContentRange',
    from HashRef, via { 'Google::Storage::V1::StorageResources::ContentRange'->new($_) };

declare 'RepeatedContentRange',
    as ArrayRef[ContentRange()];

coerce 'RepeatedContentRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::ContentRange'->new($_) } @$_ ] };

declare 'MapStringContentRange',
    as HashRef[ContentRange()];

declare 'HmacKeyMetadata',
    as InstanceOf['Google::Storage::V1::StorageResources::HmacKeyMetadata'];

coerce 'HmacKeyMetadata',
    from HashRef, via { 'Google::Storage::V1::StorageResources::HmacKeyMetadata'->new($_) };

declare 'RepeatedHmacKeyMetadata',
    as ArrayRef[HmacKeyMetadata()];

coerce 'RepeatedHmacKeyMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::HmacKeyMetadata'->new($_) } @$_ ] };

declare 'MapStringHmacKeyMetadata',
    as HashRef[HmacKeyMetadata()];

declare 'Notification',
    as InstanceOf['Google::Storage::V1::StorageResources::Notification'];

coerce 'Notification',
    from HashRef, via { 'Google::Storage::V1::StorageResources::Notification'->new($_) };

declare 'RepeatedNotification',
    as ArrayRef[Notification()];

coerce 'RepeatedNotification',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::Notification'->new($_) } @$_ ] };

declare 'MapStringNotification',
    as HashRef[Notification()];

declare 'CustomAttributesEntry',
    as InstanceOf['Google::Storage::V1::StorageResources::Notification::CustomAttributesEntry'];

coerce 'CustomAttributesEntry',
    from HashRef, via { 'Google::Storage::V1::StorageResources::Notification::CustomAttributesEntry'->new($_) };

declare 'RepeatedCustomAttributesEntry',
    as ArrayRef[CustomAttributesEntry()];

coerce 'RepeatedCustomAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::Notification::CustomAttributesEntry'->new($_) } @$_ ] };

declare 'MapStringCustomAttributesEntry',
    as HashRef[CustomAttributesEntry()];

declare 'ListNotificationsResponse',
    as InstanceOf['Google::Storage::V1::StorageResources::ListNotificationsResponse'];

coerce 'ListNotificationsResponse',
    from HashRef, via { 'Google::Storage::V1::StorageResources::ListNotificationsResponse'->new($_) };

declare 'RepeatedListNotificationsResponse',
    as ArrayRef[ListNotificationsResponse()];

coerce 'RepeatedListNotificationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::ListNotificationsResponse'->new($_) } @$_ ] };

declare 'MapStringListNotificationsResponse',
    as HashRef[ListNotificationsResponse()];

declare 'Object',
    as InstanceOf['Google::Storage::V1::StorageResources::Object'];

coerce 'Object',
    from HashRef, via { 'Google::Storage::V1::StorageResources::Object'->new($_) };

declare 'RepeatedObject',
    as ArrayRef[Object()];

coerce 'RepeatedObject',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::Object'->new($_) } @$_ ] };

declare 'MapStringObject',
    as HashRef[Object()];

declare 'CustomerEncryption',
    as InstanceOf['Google::Storage::V1::StorageResources::Object::CustomerEncryption'];

coerce 'CustomerEncryption',
    from HashRef, via { 'Google::Storage::V1::StorageResources::Object::CustomerEncryption'->new($_) };

declare 'RepeatedCustomerEncryption',
    as ArrayRef[CustomerEncryption()];

coerce 'RepeatedCustomerEncryption',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::Object::CustomerEncryption'->new($_) } @$_ ] };

declare 'MapStringCustomerEncryption',
    as HashRef[CustomerEncryption()];

declare 'MetadataEntry',
    as InstanceOf['Google::Storage::V1::StorageResources::Object::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Storage::V1::StorageResources::Object::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::Object::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'ObjectAccessControl',
    as InstanceOf['Google::Storage::V1::StorageResources::ObjectAccessControl'];

coerce 'ObjectAccessControl',
    from HashRef, via { 'Google::Storage::V1::StorageResources::ObjectAccessControl'->new($_) };

declare 'RepeatedObjectAccessControl',
    as ArrayRef[ObjectAccessControl()];

coerce 'RepeatedObjectAccessControl',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::ObjectAccessControl'->new($_) } @$_ ] };

declare 'MapStringObjectAccessControl',
    as HashRef[ObjectAccessControl()];

declare 'ListObjectAccessControlsResponse',
    as InstanceOf['Google::Storage::V1::StorageResources::ListObjectAccessControlsResponse'];

coerce 'ListObjectAccessControlsResponse',
    from HashRef, via { 'Google::Storage::V1::StorageResources::ListObjectAccessControlsResponse'->new($_) };

declare 'RepeatedListObjectAccessControlsResponse',
    as ArrayRef[ListObjectAccessControlsResponse()];

coerce 'RepeatedListObjectAccessControlsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::ListObjectAccessControlsResponse'->new($_) } @$_ ] };

declare 'MapStringListObjectAccessControlsResponse',
    as HashRef[ListObjectAccessControlsResponse()];

declare 'ListObjectsResponse',
    as InstanceOf['Google::Storage::V1::StorageResources::ListObjectsResponse'];

coerce 'ListObjectsResponse',
    from HashRef, via { 'Google::Storage::V1::StorageResources::ListObjectsResponse'->new($_) };

declare 'RepeatedListObjectsResponse',
    as ArrayRef[ListObjectsResponse()];

coerce 'RepeatedListObjectsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::ListObjectsResponse'->new($_) } @$_ ] };

declare 'MapStringListObjectsResponse',
    as HashRef[ListObjectsResponse()];

declare 'ProjectTeam',
    as InstanceOf['Google::Storage::V1::StorageResources::ProjectTeam'];

coerce 'ProjectTeam',
    from HashRef, via { 'Google::Storage::V1::StorageResources::ProjectTeam'->new($_) };

declare 'RepeatedProjectTeam',
    as ArrayRef[ProjectTeam()];

coerce 'RepeatedProjectTeam',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::ProjectTeam'->new($_) } @$_ ] };

declare 'MapStringProjectTeam',
    as HashRef[ProjectTeam()];

declare 'ServiceAccount',
    as InstanceOf['Google::Storage::V1::StorageResources::ServiceAccount'];

coerce 'ServiceAccount',
    from HashRef, via { 'Google::Storage::V1::StorageResources::ServiceAccount'->new($_) };

declare 'RepeatedServiceAccount',
    as ArrayRef[ServiceAccount()];

coerce 'RepeatedServiceAccount',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::ServiceAccount'->new($_) } @$_ ] };

declare 'MapStringServiceAccount',
    as HashRef[ServiceAccount()];

declare 'Owner',
    as InstanceOf['Google::Storage::V1::StorageResources::Owner'];

coerce 'Owner',
    from HashRef, via { 'Google::Storage::V1::StorageResources::Owner'->new($_) };

declare 'RepeatedOwner',
    as ArrayRef[Owner()];

coerce 'RepeatedOwner',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::V1::StorageResources::Owner'->new($_) } @$_ ] };

declare 'MapStringOwner',
    as HashRef[Owner()];

1;

__END__

=head1 NAME

Google::Storage::V1::StorageResources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
