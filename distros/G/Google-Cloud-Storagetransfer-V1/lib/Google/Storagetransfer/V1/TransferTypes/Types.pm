package Google::Storagetransfer::V1::TransferTypes::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GoogleServiceAccount',
    as InstanceOf['Google::Storagetransfer::V1::TransferTypes::GoogleServiceAccount'];

coerce 'GoogleServiceAccount',
    from HashRef, via { 'Google::Storagetransfer::V1::TransferTypes::GoogleServiceAccount'->new($_) };

declare 'RepeatedGoogleServiceAccount',
    as ArrayRef[GoogleServiceAccount()];

coerce 'RepeatedGoogleServiceAccount',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::TransferTypes::GoogleServiceAccount'->new($_) } @$_ ] };

declare 'MapStringGoogleServiceAccount',
    as HashRef[GoogleServiceAccount()];

declare 'AwsAccessKey',
    as InstanceOf['Google::Storagetransfer::V1::TransferTypes::AwsAccessKey'];

coerce 'AwsAccessKey',
    from HashRef, via { 'Google::Storagetransfer::V1::TransferTypes::AwsAccessKey'->new($_) };

declare 'RepeatedAwsAccessKey',
    as ArrayRef[AwsAccessKey()];

coerce 'RepeatedAwsAccessKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::TransferTypes::AwsAccessKey'->new($_) } @$_ ] };

declare 'MapStringAwsAccessKey',
    as HashRef[AwsAccessKey()];

declare 'AzureCredentials',
    as InstanceOf['Google::Storagetransfer::V1::TransferTypes::AzureCredentials'];

coerce 'AzureCredentials',
    from HashRef, via { 'Google::Storagetransfer::V1::TransferTypes::AzureCredentials'->new($_) };

declare 'RepeatedAzureCredentials',
    as ArrayRef[AzureCredentials()];

coerce 'RepeatedAzureCredentials',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::TransferTypes::AzureCredentials'->new($_) } @$_ ] };

declare 'MapStringAzureCredentials',
    as HashRef[AzureCredentials()];

declare 'ObjectConditions',
    as InstanceOf['Google::Storagetransfer::V1::TransferTypes::ObjectConditions'];

coerce 'ObjectConditions',
    from HashRef, via { 'Google::Storagetransfer::V1::TransferTypes::ObjectConditions'->new($_) };

declare 'RepeatedObjectConditions',
    as ArrayRef[ObjectConditions()];

coerce 'RepeatedObjectConditions',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::TransferTypes::ObjectConditions'->new($_) } @$_ ] };

declare 'MapStringObjectConditions',
    as HashRef[ObjectConditions()];

declare 'GcsData',
    as InstanceOf['Google::Storagetransfer::V1::TransferTypes::GcsData'];

coerce 'GcsData',
    from HashRef, via { 'Google::Storagetransfer::V1::TransferTypes::GcsData'->new($_) };

declare 'RepeatedGcsData',
    as ArrayRef[GcsData()];

coerce 'RepeatedGcsData',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::TransferTypes::GcsData'->new($_) } @$_ ] };

declare 'MapStringGcsData',
    as HashRef[GcsData()];

declare 'AwsS3Data',
    as InstanceOf['Google::Storagetransfer::V1::TransferTypes::AwsS3Data'];

coerce 'AwsS3Data',
    from HashRef, via { 'Google::Storagetransfer::V1::TransferTypes::AwsS3Data'->new($_) };

declare 'RepeatedAwsS3Data',
    as ArrayRef[AwsS3Data()];

coerce 'RepeatedAwsS3Data',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::TransferTypes::AwsS3Data'->new($_) } @$_ ] };

declare 'MapStringAwsS3Data',
    as HashRef[AwsS3Data()];

declare 'AzureBlobStorageData',
    as InstanceOf['Google::Storagetransfer::V1::TransferTypes::AzureBlobStorageData'];

coerce 'AzureBlobStorageData',
    from HashRef, via { 'Google::Storagetransfer::V1::TransferTypes::AzureBlobStorageData'->new($_) };

declare 'RepeatedAzureBlobStorageData',
    as ArrayRef[AzureBlobStorageData()];

coerce 'RepeatedAzureBlobStorageData',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::TransferTypes::AzureBlobStorageData'->new($_) } @$_ ] };

declare 'MapStringAzureBlobStorageData',
    as HashRef[AzureBlobStorageData()];

declare 'FederatedIdentityConfig',
    as InstanceOf['Google::Storagetransfer::V1::TransferTypes::AzureBlobStorageData::FederatedIdentityConfig'];

coerce 'FederatedIdentityConfig',
    from HashRef, via { 'Google::Storagetransfer::V1::TransferTypes::AzureBlobStorageData::FederatedIdentityConfig'->new($_) };

declare 'RepeatedFederatedIdentityConfig',
    as ArrayRef[FederatedIdentityConfig()];

coerce 'RepeatedFederatedIdentityConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::TransferTypes::AzureBlobStorageData::FederatedIdentityConfig'->new($_) } @$_ ] };

declare 'MapStringFederatedIdentityConfig',
    as HashRef[FederatedIdentityConfig()];

declare 'HttpData',
    as InstanceOf['Google::Storagetransfer::V1::TransferTypes::HttpData'];

coerce 'HttpData',
    from HashRef, via { 'Google::Storagetransfer::V1::TransferTypes::HttpData'->new($_) };

declare 'RepeatedHttpData',
    as ArrayRef[HttpData()];

coerce 'RepeatedHttpData',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::TransferTypes::HttpData'->new($_) } @$_ ] };

declare 'MapStringHttpData',
    as HashRef[HttpData()];

declare 'PosixFilesystem',
    as InstanceOf['Google::Storagetransfer::V1::TransferTypes::PosixFilesystem'];

coerce 'PosixFilesystem',
    from HashRef, via { 'Google::Storagetransfer::V1::TransferTypes::PosixFilesystem'->new($_) };

declare 'RepeatedPosixFilesystem',
    as ArrayRef[PosixFilesystem()];

coerce 'RepeatedPosixFilesystem',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::TransferTypes::PosixFilesystem'->new($_) } @$_ ] };

declare 'MapStringPosixFilesystem',
    as HashRef[PosixFilesystem()];

declare 'HdfsData',
    as InstanceOf['Google::Storagetransfer::V1::TransferTypes::HdfsData'];

coerce 'HdfsData',
    from HashRef, via { 'Google::Storagetransfer::V1::TransferTypes::HdfsData'->new($_) };

declare 'RepeatedHdfsData',
    as ArrayRef[HdfsData()];

coerce 'RepeatedHdfsData',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::TransferTypes::HdfsData'->new($_) } @$_ ] };

declare 'MapStringHdfsData',
    as HashRef[HdfsData()];

declare 'AwsS3CompatibleData',
    as InstanceOf['Google::Storagetransfer::V1::TransferTypes::AwsS3CompatibleData'];

coerce 'AwsS3CompatibleData',
    from HashRef, via { 'Google::Storagetransfer::V1::TransferTypes::AwsS3CompatibleData'->new($_) };

declare 'RepeatedAwsS3CompatibleData',
    as ArrayRef[AwsS3CompatibleData()];

coerce 'RepeatedAwsS3CompatibleData',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::TransferTypes::AwsS3CompatibleData'->new($_) } @$_ ] };

declare 'MapStringAwsS3CompatibleData',
    as HashRef[AwsS3CompatibleData()];

declare 'S3CompatibleMetadata',
    as InstanceOf['Google::Storagetransfer::V1::TransferTypes::S3CompatibleMetadata'];

coerce 'S3CompatibleMetadata',
    from HashRef, via { 'Google::Storagetransfer::V1::TransferTypes::S3CompatibleMetadata'->new($_) };

declare 'RepeatedS3CompatibleMetadata',
    as ArrayRef[S3CompatibleMetadata()];

coerce 'RepeatedS3CompatibleMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::TransferTypes::S3CompatibleMetadata'->new($_) } @$_ ] };

declare 'MapStringS3CompatibleMetadata',
    as HashRef[S3CompatibleMetadata()];

declare 'AuthMethod',
    as (Int | Str);

declare 'RequestModel',
    as (Int | Str);

declare 'NetworkProtocol',
    as (Int | Str);

declare 'ListApi',
    as (Int | Str);

declare 'AgentPool',
    as InstanceOf['Google::Storagetransfer::V1::TransferTypes::AgentPool'];

coerce 'AgentPool',
    from HashRef, via { 'Google::Storagetransfer::V1::TransferTypes::AgentPool'->new($_) };

declare 'RepeatedAgentPool',
    as ArrayRef[AgentPool()];

coerce 'RepeatedAgentPool',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::TransferTypes::AgentPool'->new($_) } @$_ ] };

declare 'MapStringAgentPool',
    as HashRef[AgentPool()];

declare 'State',
    as (Int | Str);

declare 'BandwidthLimit',
    as InstanceOf['Google::Storagetransfer::V1::TransferTypes::AgentPool::BandwidthLimit'];

coerce 'BandwidthLimit',
    from HashRef, via { 'Google::Storagetransfer::V1::TransferTypes::AgentPool::BandwidthLimit'->new($_) };

declare 'RepeatedBandwidthLimit',
    as ArrayRef[BandwidthLimit()];

coerce 'RepeatedBandwidthLimit',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::TransferTypes::AgentPool::BandwidthLimit'->new($_) } @$_ ] };

declare 'MapStringBandwidthLimit',
    as HashRef[BandwidthLimit()];

declare 'TransferOptions',
    as InstanceOf['Google::Storagetransfer::V1::TransferTypes::TransferOptions'];

coerce 'TransferOptions',
    from HashRef, via { 'Google::Storagetransfer::V1::TransferTypes::TransferOptions'->new($_) };

declare 'RepeatedTransferOptions',
    as ArrayRef[TransferOptions()];

coerce 'RepeatedTransferOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::TransferTypes::TransferOptions'->new($_) } @$_ ] };

declare 'MapStringTransferOptions',
    as HashRef[TransferOptions()];

declare 'OverwriteWhen',
    as (Int | Str);

declare 'TransferSpec',
    as InstanceOf['Google::Storagetransfer::V1::TransferTypes::TransferSpec'];

coerce 'TransferSpec',
    from HashRef, via { 'Google::Storagetransfer::V1::TransferTypes::TransferSpec'->new($_) };

declare 'RepeatedTransferSpec',
    as ArrayRef[TransferSpec()];

coerce 'RepeatedTransferSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::TransferTypes::TransferSpec'->new($_) } @$_ ] };

declare 'MapStringTransferSpec',
    as HashRef[TransferSpec()];

declare 'ReplicationSpec',
    as InstanceOf['Google::Storagetransfer::V1::TransferTypes::ReplicationSpec'];

coerce 'ReplicationSpec',
    from HashRef, via { 'Google::Storagetransfer::V1::TransferTypes::ReplicationSpec'->new($_) };

declare 'RepeatedReplicationSpec',
    as ArrayRef[ReplicationSpec()];

coerce 'RepeatedReplicationSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::TransferTypes::ReplicationSpec'->new($_) } @$_ ] };

declare 'MapStringReplicationSpec',
    as HashRef[ReplicationSpec()];

declare 'MetadataOptions',
    as InstanceOf['Google::Storagetransfer::V1::TransferTypes::MetadataOptions'];

coerce 'MetadataOptions',
    from HashRef, via { 'Google::Storagetransfer::V1::TransferTypes::MetadataOptions'->new($_) };

declare 'RepeatedMetadataOptions',
    as ArrayRef[MetadataOptions()];

coerce 'RepeatedMetadataOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::TransferTypes::MetadataOptions'->new($_) } @$_ ] };

declare 'MapStringMetadataOptions',
    as HashRef[MetadataOptions()];

declare 'Symlink',
    as (Int | Str);

declare 'Mode',
    as (Int | Str);

declare 'GID',
    as (Int | Str);

declare 'UID',
    as (Int | Str);

declare 'Acl',
    as (Int | Str);

declare 'StorageClass',
    as (Int | Str);

declare 'TemporaryHold',
    as (Int | Str);

declare 'KmsKey',
    as (Int | Str);

declare 'TimeCreated',
    as (Int | Str);

declare 'TransferManifest',
    as InstanceOf['Google::Storagetransfer::V1::TransferTypes::TransferManifest'];

coerce 'TransferManifest',
    from HashRef, via { 'Google::Storagetransfer::V1::TransferTypes::TransferManifest'->new($_) };

declare 'RepeatedTransferManifest',
    as ArrayRef[TransferManifest()];

coerce 'RepeatedTransferManifest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::TransferTypes::TransferManifest'->new($_) } @$_ ] };

declare 'MapStringTransferManifest',
    as HashRef[TransferManifest()];

declare 'Schedule',
    as InstanceOf['Google::Storagetransfer::V1::TransferTypes::Schedule'];

coerce 'Schedule',
    from HashRef, via { 'Google::Storagetransfer::V1::TransferTypes::Schedule'->new($_) };

declare 'RepeatedSchedule',
    as ArrayRef[Schedule()];

coerce 'RepeatedSchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::TransferTypes::Schedule'->new($_) } @$_ ] };

declare 'MapStringSchedule',
    as HashRef[Schedule()];

declare 'EventStream',
    as InstanceOf['Google::Storagetransfer::V1::TransferTypes::EventStream'];

coerce 'EventStream',
    from HashRef, via { 'Google::Storagetransfer::V1::TransferTypes::EventStream'->new($_) };

declare 'RepeatedEventStream',
    as ArrayRef[EventStream()];

coerce 'RepeatedEventStream',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::TransferTypes::EventStream'->new($_) } @$_ ] };

declare 'MapStringEventStream',
    as HashRef[EventStream()];

declare 'TransferJob',
    as InstanceOf['Google::Storagetransfer::V1::TransferTypes::TransferJob'];

coerce 'TransferJob',
    from HashRef, via { 'Google::Storagetransfer::V1::TransferTypes::TransferJob'->new($_) };

declare 'RepeatedTransferJob',
    as ArrayRef[TransferJob()];

coerce 'RepeatedTransferJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::TransferTypes::TransferJob'->new($_) } @$_ ] };

declare 'MapStringTransferJob',
    as HashRef[TransferJob()];

declare 'Status',
    as (Int | Str);

declare 'ErrorLogEntry',
    as InstanceOf['Google::Storagetransfer::V1::TransferTypes::ErrorLogEntry'];

coerce 'ErrorLogEntry',
    from HashRef, via { 'Google::Storagetransfer::V1::TransferTypes::ErrorLogEntry'->new($_) };

declare 'RepeatedErrorLogEntry',
    as ArrayRef[ErrorLogEntry()];

coerce 'RepeatedErrorLogEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::TransferTypes::ErrorLogEntry'->new($_) } @$_ ] };

declare 'MapStringErrorLogEntry',
    as HashRef[ErrorLogEntry()];

declare 'ErrorSummary',
    as InstanceOf['Google::Storagetransfer::V1::TransferTypes::ErrorSummary'];

coerce 'ErrorSummary',
    from HashRef, via { 'Google::Storagetransfer::V1::TransferTypes::ErrorSummary'->new($_) };

declare 'RepeatedErrorSummary',
    as ArrayRef[ErrorSummary()];

coerce 'RepeatedErrorSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::TransferTypes::ErrorSummary'->new($_) } @$_ ] };

declare 'MapStringErrorSummary',
    as HashRef[ErrorSummary()];

declare 'TransferCounters',
    as InstanceOf['Google::Storagetransfer::V1::TransferTypes::TransferCounters'];

coerce 'TransferCounters',
    from HashRef, via { 'Google::Storagetransfer::V1::TransferTypes::TransferCounters'->new($_) };

declare 'RepeatedTransferCounters',
    as ArrayRef[TransferCounters()];

coerce 'RepeatedTransferCounters',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::TransferTypes::TransferCounters'->new($_) } @$_ ] };

declare 'MapStringTransferCounters',
    as HashRef[TransferCounters()];

declare 'NotificationConfig',
    as InstanceOf['Google::Storagetransfer::V1::TransferTypes::NotificationConfig'];

coerce 'NotificationConfig',
    from HashRef, via { 'Google::Storagetransfer::V1::TransferTypes::NotificationConfig'->new($_) };

declare 'RepeatedNotificationConfig',
    as ArrayRef[NotificationConfig()];

coerce 'RepeatedNotificationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::TransferTypes::NotificationConfig'->new($_) } @$_ ] };

declare 'MapStringNotificationConfig',
    as HashRef[NotificationConfig()];

declare 'EventType',
    as (Int | Str);

declare 'PayloadFormat',
    as (Int | Str);

declare 'LoggingConfig',
    as InstanceOf['Google::Storagetransfer::V1::TransferTypes::LoggingConfig'];

coerce 'LoggingConfig',
    from HashRef, via { 'Google::Storagetransfer::V1::TransferTypes::LoggingConfig'->new($_) };

declare 'RepeatedLoggingConfig',
    as ArrayRef[LoggingConfig()];

coerce 'RepeatedLoggingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::TransferTypes::LoggingConfig'->new($_) } @$_ ] };

declare 'MapStringLoggingConfig',
    as HashRef[LoggingConfig()];

declare 'LoggableAction',
    as (Int | Str);

declare 'LoggableActionState',
    as (Int | Str);

declare 'TransferOperation',
    as InstanceOf['Google::Storagetransfer::V1::TransferTypes::TransferOperation'];

coerce 'TransferOperation',
    from HashRef, via { 'Google::Storagetransfer::V1::TransferTypes::TransferOperation'->new($_) };

declare 'RepeatedTransferOperation',
    as ArrayRef[TransferOperation()];

coerce 'RepeatedTransferOperation',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::TransferTypes::TransferOperation'->new($_) } @$_ ] };

declare 'MapStringTransferOperation',
    as HashRef[TransferOperation()];

declare 'Status',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Storagetransfer::V1::TransferTypes::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
