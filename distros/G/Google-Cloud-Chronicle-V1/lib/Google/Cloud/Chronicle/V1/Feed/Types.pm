package Google::Cloud::Chronicle::V1::Feed::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'URISourceType',
    as (Int | Str);

declare 'SourceDeletionOption',
    as (Int | Str);

declare 'SourceDeletionOptionV2',
    as (Int | Str);

declare 'S3Region',
    as (Int | Str);

declare 'SemanticType',
    as (Int | Str);

declare 'FeedPack',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::FeedPack'];

coerce 'FeedPack',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::FeedPack'->new($_) };

declare 'RepeatedFeedPack',
    as ArrayRef[FeedPack()];

coerce 'RepeatedFeedPack',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::FeedPack'->new($_) } @$_ ] };

declare 'MapStringFeedPack',
    as HashRef[FeedPack()];

declare 'PackType',
    as (Int | Str);

declare 'PackLogType',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::PackLogType'];

coerce 'PackLogType',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::PackLogType'->new($_) };

declare 'RepeatedPackLogType',
    as ArrayRef[PackLogType()];

coerce 'RepeatedPackLogType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::PackLogType'->new($_) } @$_ ] };

declare 'MapStringPackLogType',
    as HashRef[PackLogType()];

declare 'Feed',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::Feed'];

coerce 'Feed',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::Feed'->new($_) };

declare 'RepeatedFeed',
    as ArrayRef[Feed()];

coerce 'RepeatedFeed',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::Feed'->new($_) } @$_ ] };

declare 'MapStringFeed',
    as HashRef[Feed()];

declare 'State',
    as (Int | Str);

declare 'FeedFailureDetails',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::FeedFailureDetails'];

coerce 'FeedFailureDetails',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::FeedFailureDetails'->new($_) };

declare 'RepeatedFeedFailureDetails',
    as ArrayRef[FeedFailureDetails()];

coerce 'RepeatedFeedFailureDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::FeedFailureDetails'->new($_) } @$_ ] };

declare 'MapStringFeedFailureDetails',
    as HashRef[FeedFailureDetails()];

declare 'FeedServiceAccount',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::FeedServiceAccount'];

coerce 'FeedServiceAccount',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::FeedServiceAccount'->new($_) };

declare 'RepeatedFeedServiceAccount',
    as ArrayRef[FeedServiceAccount()];

coerce 'RepeatedFeedServiceAccount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::FeedServiceAccount'->new($_) } @$_ ] };

declare 'MapStringFeedServiceAccount',
    as HashRef[FeedServiceAccount()];

declare 'FeedDetails',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::FeedDetails'];

coerce 'FeedDetails',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::FeedDetails'->new($_) };

declare 'RepeatedFeedDetails',
    as ArrayRef[FeedDetails()];

coerce 'RepeatedFeedDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::FeedDetails'->new($_) } @$_ ] };

declare 'MapStringFeedDetails',
    as HashRef[FeedDetails()];

declare 'FeedSourceType',
    as (Int | Str);

declare 'STSMigrationReadiness',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::FeedDetails::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::FeedDetails::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::FeedDetails::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'DummyLogTypeSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::DummyLogTypeSettings'];

coerce 'DummyLogTypeSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::DummyLogTypeSettings'->new($_) };

declare 'RepeatedDummyLogTypeSettings',
    as ArrayRef[DummyLogTypeSettings()];

coerce 'RepeatedDummyLogTypeSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::DummyLogTypeSettings'->new($_) } @$_ ] };

declare 'MapStringDummyLogTypeSettings',
    as HashRef[DummyLogTypeSettings()];

declare 'HttpsPushGoogleCloudPubSubSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::HttpsPushGoogleCloudPubSubSettings'];

coerce 'HttpsPushGoogleCloudPubSubSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::HttpsPushGoogleCloudPubSubSettings'->new($_) };

declare 'RepeatedHttpsPushGoogleCloudPubSubSettings',
    as ArrayRef[HttpsPushGoogleCloudPubSubSettings()];

coerce 'RepeatedHttpsPushGoogleCloudPubSubSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::HttpsPushGoogleCloudPubSubSettings'->new($_) } @$_ ] };

declare 'MapStringHttpsPushGoogleCloudPubSubSettings',
    as HashRef[HttpsPushGoogleCloudPubSubSettings()];

declare 'HttpsPushAmazonKinesisFirehoseSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::HttpsPushAmazonKinesisFirehoseSettings'];

coerce 'HttpsPushAmazonKinesisFirehoseSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::HttpsPushAmazonKinesisFirehoseSettings'->new($_) };

declare 'RepeatedHttpsPushAmazonKinesisFirehoseSettings',
    as ArrayRef[HttpsPushAmazonKinesisFirehoseSettings()];

coerce 'RepeatedHttpsPushAmazonKinesisFirehoseSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::HttpsPushAmazonKinesisFirehoseSettings'->new($_) } @$_ ] };

declare 'MapStringHttpsPushAmazonKinesisFirehoseSettings',
    as HashRef[HttpsPushAmazonKinesisFirehoseSettings()];

declare 'HttpsPushWebhookSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::HttpsPushWebhookSettings'];

coerce 'HttpsPushWebhookSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::HttpsPushWebhookSettings'->new($_) };

declare 'RepeatedHttpsPushWebhookSettings',
    as ArrayRef[HttpsPushWebhookSettings()];

coerce 'RepeatedHttpsPushWebhookSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::HttpsPushWebhookSettings'->new($_) } @$_ ] };

declare 'MapStringHttpsPushWebhookSettings',
    as HashRef[HttpsPushWebhookSettings()];

declare 'SentineloneAlertSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::SentineloneAlertSettings'];

coerce 'SentineloneAlertSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::SentineloneAlertSettings'->new($_) };

declare 'RepeatedSentineloneAlertSettings',
    as ArrayRef[SentineloneAlertSettings()];

coerce 'RepeatedSentineloneAlertSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::SentineloneAlertSettings'->new($_) } @$_ ] };

declare 'MapStringSentineloneAlertSettings',
    as HashRef[SentineloneAlertSettings()];

declare 'QualysScanSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::QualysScanSettings'];

coerce 'QualysScanSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::QualysScanSettings'->new($_) };

declare 'RepeatedQualysScanSettings',
    as ArrayRef[QualysScanSettings()];

coerce 'RepeatedQualysScanSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::QualysScanSettings'->new($_) } @$_ ] };

declare 'MapStringQualysScanSettings',
    as HashRef[QualysScanSettings()];

declare 'ApiType',
    as (Int | Str);

declare 'PubsubSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::PubsubSettings'];

coerce 'PubsubSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::PubsubSettings'->new($_) };

declare 'RepeatedPubsubSettings',
    as ArrayRef[PubsubSettings()];

coerce 'RepeatedPubsubSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::PubsubSettings'->new($_) } @$_ ] };

declare 'MapStringPubsubSettings',
    as HashRef[PubsubSettings()];

declare 'AmazonKinesisFirehoseSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::AmazonKinesisFirehoseSettings'];

coerce 'AmazonKinesisFirehoseSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::AmazonKinesisFirehoseSettings'->new($_) };

declare 'RepeatedAmazonKinesisFirehoseSettings',
    as ArrayRef[AmazonKinesisFirehoseSettings()];

coerce 'RepeatedAmazonKinesisFirehoseSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::AmazonKinesisFirehoseSettings'->new($_) } @$_ ] };

declare 'MapStringAmazonKinesisFirehoseSettings',
    as HashRef[AmazonKinesisFirehoseSettings()];

declare 'WebhookSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::WebhookSettings'];

coerce 'WebhookSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::WebhookSettings'->new($_) };

declare 'RepeatedWebhookSettings',
    as ArrayRef[WebhookSettings()];

coerce 'RepeatedWebhookSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::WebhookSettings'->new($_) } @$_ ] };

declare 'MapStringWebhookSettings',
    as HashRef[WebhookSettings()];

declare 'AmazonSQSSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::AmazonSQSSettings'];

coerce 'AmazonSQSSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::AmazonSQSSettings'->new($_) };

declare 'RepeatedAmazonSQSSettings',
    as ArrayRef[AmazonSQSSettings()];

coerce 'RepeatedAmazonSQSSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::AmazonSQSSettings'->new($_) } @$_ ] };

declare 'MapStringAmazonSQSSettings',
    as HashRef[AmazonSQSSettings()];

declare 'AnomaliIocSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::AnomaliIocSettings'];

coerce 'AnomaliIocSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::AnomaliIocSettings'->new($_) };

declare 'RepeatedAnomaliIocSettings',
    as ArrayRef[AnomaliIocSettings()];

coerce 'RepeatedAnomaliIocSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::AnomaliIocSettings'->new($_) } @$_ ] };

declare 'MapStringAnomaliIocSettings',
    as HashRef[AnomaliIocSettings()];

declare 'AzureADSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::AzureADSettings'];

coerce 'AzureADSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::AzureADSettings'->new($_) };

declare 'RepeatedAzureADSettings',
    as ArrayRef[AzureADSettings()];

coerce 'RepeatedAzureADSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::AzureADSettings'->new($_) } @$_ ] };

declare 'MapStringAzureADSettings',
    as HashRef[AzureADSettings()];

declare 'AzureADAuditSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::AzureADAuditSettings'];

coerce 'AzureADAuditSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::AzureADAuditSettings'->new($_) };

declare 'RepeatedAzureADAuditSettings',
    as ArrayRef[AzureADAuditSettings()];

coerce 'RepeatedAzureADAuditSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::AzureADAuditSettings'->new($_) } @$_ ] };

declare 'MapStringAzureADAuditSettings',
    as HashRef[AzureADAuditSettings()];

declare 'AzureADContextSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::AzureADContextSettings'];

coerce 'AzureADContextSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::AzureADContextSettings'->new($_) };

declare 'RepeatedAzureADContextSettings',
    as ArrayRef[AzureADContextSettings()];

coerce 'RepeatedAzureADContextSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::AzureADContextSettings'->new($_) } @$_ ] };

declare 'MapStringAzureADContextSettings',
    as HashRef[AzureADContextSettings()];

declare 'CloudPassageSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::CloudPassageSettings'];

coerce 'CloudPassageSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::CloudPassageSettings'->new($_) };

declare 'RepeatedCloudPassageSettings',
    as ArrayRef[CloudPassageSettings()];

coerce 'RepeatedCloudPassageSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::CloudPassageSettings'->new($_) } @$_ ] };

declare 'MapStringCloudPassageSettings',
    as HashRef[CloudPassageSettings()];

declare 'CortexXDRSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::CortexXDRSettings'];

coerce 'CortexXDRSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::CortexXDRSettings'->new($_) };

declare 'RepeatedCortexXDRSettings',
    as ArrayRef[CortexXDRSettings()];

coerce 'RepeatedCortexXDRSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::CortexXDRSettings'->new($_) } @$_ ] };

declare 'MapStringCortexXDRSettings',
    as HashRef[CortexXDRSettings()];

declare 'CrowdStrikeDetectsSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::CrowdStrikeDetectsSettings'];

coerce 'CrowdStrikeDetectsSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::CrowdStrikeDetectsSettings'->new($_) };

declare 'RepeatedCrowdStrikeDetectsSettings',
    as ArrayRef[CrowdStrikeDetectsSettings()];

coerce 'RepeatedCrowdStrikeDetectsSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::CrowdStrikeDetectsSettings'->new($_) } @$_ ] };

declare 'MapStringCrowdStrikeDetectsSettings',
    as HashRef[CrowdStrikeDetectsSettings()];

declare 'IngestionType',
    as (Int | Str);

declare 'CrowdStrikeAlertsSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::CrowdStrikeAlertsSettings'];

coerce 'CrowdStrikeAlertsSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::CrowdStrikeAlertsSettings'->new($_) };

declare 'RepeatedCrowdStrikeAlertsSettings',
    as ArrayRef[CrowdStrikeAlertsSettings()];

coerce 'RepeatedCrowdStrikeAlertsSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::CrowdStrikeAlertsSettings'->new($_) } @$_ ] };

declare 'MapStringCrowdStrikeAlertsSettings',
    as HashRef[CrowdStrikeAlertsSettings()];

declare 'IngestionType',
    as (Int | Str);

declare 'DuoAuthSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::DuoAuthSettings'];

coerce 'DuoAuthSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::DuoAuthSettings'->new($_) };

declare 'RepeatedDuoAuthSettings',
    as ArrayRef[DuoAuthSettings()];

coerce 'RepeatedDuoAuthSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::DuoAuthSettings'->new($_) } @$_ ] };

declare 'MapStringDuoAuthSettings',
    as HashRef[DuoAuthSettings()];

declare 'DuoUserContextSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::DuoUserContextSettings'];

coerce 'DuoUserContextSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::DuoUserContextSettings'->new($_) };

declare 'RepeatedDuoUserContextSettings',
    as ArrayRef[DuoUserContextSettings()];

coerce 'RepeatedDuoUserContextSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::DuoUserContextSettings'->new($_) } @$_ ] };

declare 'MapStringDuoUserContextSettings',
    as HashRef[DuoUserContextSettings()];

declare 'MicrosoftGraphAlertSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::MicrosoftGraphAlertSettings'];

coerce 'MicrosoftGraphAlertSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::MicrosoftGraphAlertSettings'->new($_) };

declare 'RepeatedMicrosoftGraphAlertSettings',
    as ArrayRef[MicrosoftGraphAlertSettings()];

coerce 'RepeatedMicrosoftGraphAlertSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::MicrosoftGraphAlertSettings'->new($_) } @$_ ] };

declare 'MapStringMicrosoftGraphAlertSettings',
    as HashRef[MicrosoftGraphAlertSettings()];

declare 'MicrosoftSecurityCenterAlertSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::MicrosoftSecurityCenterAlertSettings'];

coerce 'MicrosoftSecurityCenterAlertSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::MicrosoftSecurityCenterAlertSettings'->new($_) };

declare 'RepeatedMicrosoftSecurityCenterAlertSettings',
    as ArrayRef[MicrosoftSecurityCenterAlertSettings()];

coerce 'RepeatedMicrosoftSecurityCenterAlertSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::MicrosoftSecurityCenterAlertSettings'->new($_) } @$_ ] };

declare 'MapStringMicrosoftSecurityCenterAlertSettings',
    as HashRef[MicrosoftSecurityCenterAlertSettings()];

declare 'MimecastMailSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::MimecastMailSettings'];

coerce 'MimecastMailSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::MimecastMailSettings'->new($_) };

declare 'RepeatedMimecastMailSettings',
    as ArrayRef[MimecastMailSettings()];

coerce 'RepeatedMimecastMailSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::MimecastMailSettings'->new($_) } @$_ ] };

declare 'MapStringMimecastMailSettings',
    as HashRef[MimecastMailSettings()];

declare 'MimecastMailV2Settings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::MimecastMailV2Settings'];

coerce 'MimecastMailV2Settings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::MimecastMailV2Settings'->new($_) };

declare 'RepeatedMimecastMailV2Settings',
    as ArrayRef[MimecastMailV2Settings()];

coerce 'RepeatedMimecastMailV2Settings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::MimecastMailV2Settings'->new($_) } @$_ ] };

declare 'MapStringMimecastMailV2Settings',
    as HashRef[MimecastMailV2Settings()];

declare 'Office365Settings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::Office365Settings'];

coerce 'Office365Settings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::Office365Settings'->new($_) };

declare 'RepeatedOffice365Settings',
    as ArrayRef[Office365Settings()];

coerce 'RepeatedOffice365Settings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::Office365Settings'->new($_) } @$_ ] };

declare 'MapStringOffice365Settings',
    as HashRef[Office365Settings()];

declare 'ContentType',
    as (Int | Str);

declare 'ProofpointMailSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::ProofpointMailSettings'];

coerce 'ProofpointMailSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::ProofpointMailSettings'->new($_) };

declare 'RepeatedProofpointMailSettings',
    as ArrayRef[ProofpointMailSettings()];

coerce 'RepeatedProofpointMailSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::ProofpointMailSettings'->new($_) } @$_ ] };

declare 'MapStringProofpointMailSettings',
    as HashRef[ProofpointMailSettings()];

declare 'ProofpointOnDemandSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::ProofpointOnDemandSettings'];

coerce 'ProofpointOnDemandSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::ProofpointOnDemandSettings'->new($_) };

declare 'RepeatedProofpointOnDemandSettings',
    as ArrayRef[ProofpointOnDemandSettings()];

coerce 'RepeatedProofpointOnDemandSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::ProofpointOnDemandSettings'->new($_) } @$_ ] };

declare 'MapStringProofpointOnDemandSettings',
    as HashRef[ProofpointOnDemandSettings()];

declare 'RecordedFutureIocSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::RecordedFutureIocSettings'];

coerce 'RecordedFutureIocSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::RecordedFutureIocSettings'->new($_) };

declare 'RepeatedRecordedFutureIocSettings',
    as ArrayRef[RecordedFutureIocSettings()];

coerce 'RepeatedRecordedFutureIocSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::RecordedFutureIocSettings'->new($_) } @$_ ] };

declare 'MapStringRecordedFutureIocSettings',
    as HashRef[RecordedFutureIocSettings()];

declare 'WorkdaySettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::WorkdaySettings'];

coerce 'WorkdaySettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::WorkdaySettings'->new($_) };

declare 'RepeatedWorkdaySettings',
    as ArrayRef[WorkdaySettings()];

coerce 'RepeatedWorkdaySettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::WorkdaySettings'->new($_) } @$_ ] };

declare 'MapStringWorkdaySettings',
    as HashRef[WorkdaySettings()];

declare 'PanIocSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::PanIocSettings'];

coerce 'PanIocSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::PanIocSettings'->new($_) };

declare 'RepeatedPanIocSettings',
    as ArrayRef[PanIocSettings()];

coerce 'RepeatedPanIocSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::PanIocSettings'->new($_) } @$_ ] };

declare 'MapStringPanIocSettings',
    as HashRef[PanIocSettings()];

declare 'OktaSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::OktaSettings'];

coerce 'OktaSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::OktaSettings'->new($_) };

declare 'RepeatedOktaSettings',
    as ArrayRef[OktaSettings()];

coerce 'RepeatedOktaSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::OktaSettings'->new($_) } @$_ ] };

declare 'MapStringOktaSettings',
    as HashRef[OktaSettings()];

declare 'OktaUserContextSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::OktaUserContextSettings'];

coerce 'OktaUserContextSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::OktaUserContextSettings'->new($_) };

declare 'RepeatedOktaUserContextSettings',
    as ArrayRef[OktaUserContextSettings()];

coerce 'RepeatedOktaUserContextSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::OktaUserContextSettings'->new($_) } @$_ ] };

declare 'MapStringOktaUserContextSettings',
    as HashRef[OktaUserContextSettings()];

declare 'FoxITStixSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::FoxITStixSettings'];

coerce 'FoxITStixSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::FoxITStixSettings'->new($_) };

declare 'RepeatedFoxITStixSettings',
    as ArrayRef[FoxITStixSettings()];

coerce 'RepeatedFoxITStixSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::FoxITStixSettings'->new($_) } @$_ ] };

declare 'MapStringFoxITStixSettings',
    as HashRef[FoxITStixSettings()];

declare 'ThreatConnectIoCSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::ThreatConnectIoCSettings'];

coerce 'ThreatConnectIoCSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::ThreatConnectIoCSettings'->new($_) };

declare 'RepeatedThreatConnectIoCSettings',
    as ArrayRef[ThreatConnectIoCSettings()];

coerce 'RepeatedThreatConnectIoCSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::ThreatConnectIoCSettings'->new($_) } @$_ ] };

declare 'MapStringThreatConnectIoCSettings',
    as HashRef[ThreatConnectIoCSettings()];

declare 'ThreatConnectIoCV3Settings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::ThreatConnectIoCV3Settings'];

coerce 'ThreatConnectIoCV3Settings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::ThreatConnectIoCV3Settings'->new($_) };

declare 'RepeatedThreatConnectIoCV3Settings',
    as ArrayRef[ThreatConnectIoCV3Settings()];

coerce 'RepeatedThreatConnectIoCV3Settings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::ThreatConnectIoCV3Settings'->new($_) } @$_ ] };

declare 'MapStringThreatConnectIoCV3Settings',
    as HashRef[ThreatConnectIoCV3Settings()];

declare 'ServiceNowCMDBSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::ServiceNowCMDBSettings'];

coerce 'ServiceNowCMDBSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::ServiceNowCMDBSettings'->new($_) };

declare 'RepeatedServiceNowCMDBSettings',
    as ArrayRef[ServiceNowCMDBSettings()];

coerce 'RepeatedServiceNowCMDBSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::ServiceNowCMDBSettings'->new($_) } @$_ ] };

declare 'MapStringServiceNowCMDBSettings',
    as HashRef[ServiceNowCMDBSettings()];

declare 'ImpervaWAFSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::ImpervaWAFSettings'];

coerce 'ImpervaWAFSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::ImpervaWAFSettings'->new($_) };

declare 'RepeatedImpervaWAFSettings',
    as ArrayRef[ImpervaWAFSettings()];

coerce 'RepeatedImpervaWAFSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::ImpervaWAFSettings'->new($_) } @$_ ] };

declare 'MapStringImpervaWAFSettings',
    as HashRef[ImpervaWAFSettings()];

declare 'ThinkstCanarySettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::ThinkstCanarySettings'];

coerce 'ThinkstCanarySettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::ThinkstCanarySettings'->new($_) };

declare 'RepeatedThinkstCanarySettings',
    as ArrayRef[ThinkstCanarySettings()];

coerce 'RepeatedThinkstCanarySettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::ThinkstCanarySettings'->new($_) } @$_ ] };

declare 'MapStringThinkstCanarySettings',
    as HashRef[ThinkstCanarySettings()];

declare 'RHIsacIocSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::RHIsacIocSettings'];

coerce 'RHIsacIocSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::RHIsacIocSettings'->new($_) };

declare 'RepeatedRHIsacIocSettings',
    as ArrayRef[RHIsacIocSettings()];

coerce 'RepeatedRHIsacIocSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::RHIsacIocSettings'->new($_) } @$_ ] };

declare 'MapStringRHIsacIocSettings',
    as HashRef[RHIsacIocSettings()];

declare 'Rapid7InsightSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::Rapid7InsightSettings'];

coerce 'Rapid7InsightSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::Rapid7InsightSettings'->new($_) };

declare 'RepeatedRapid7InsightSettings',
    as ArrayRef[Rapid7InsightSettings()];

coerce 'RepeatedRapid7InsightSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::Rapid7InsightSettings'->new($_) } @$_ ] };

declare 'MapStringRapid7InsightSettings',
    as HashRef[Rapid7InsightSettings()];

declare 'SalesforceSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::SalesforceSettings'];

coerce 'SalesforceSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::SalesforceSettings'->new($_) };

declare 'RepeatedSalesforceSettings',
    as ArrayRef[SalesforceSettings()];

coerce 'RepeatedSalesforceSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::SalesforceSettings'->new($_) } @$_ ] };

declare 'MapStringSalesforceSettings',
    as HashRef[SalesforceSettings()];

declare 'MandiantIoCSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::MandiantIoCSettings'];

coerce 'MandiantIoCSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::MandiantIoCSettings'->new($_) };

declare 'RepeatedMandiantIoCSettings',
    as ArrayRef[MandiantIoCSettings()];

coerce 'RepeatedMandiantIoCSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::MandiantIoCSettings'->new($_) } @$_ ] };

declare 'MapStringMandiantIoCSettings',
    as HashRef[MandiantIoCSettings()];

declare 'NetskopeAlertSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::NetskopeAlertSettings'];

coerce 'NetskopeAlertSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::NetskopeAlertSettings'->new($_) };

declare 'RepeatedNetskopeAlertSettings',
    as ArrayRef[NetskopeAlertSettings()];

coerce 'RepeatedNetskopeAlertSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::NetskopeAlertSettings'->new($_) } @$_ ] };

declare 'MapStringNetskopeAlertSettings',
    as HashRef[NetskopeAlertSettings()];

declare 'NetskopeAlertV2Settings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::NetskopeAlertV2Settings'];

coerce 'NetskopeAlertV2Settings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::NetskopeAlertV2Settings'->new($_) };

declare 'RepeatedNetskopeAlertV2Settings',
    as ArrayRef[NetskopeAlertV2Settings()];

coerce 'RepeatedNetskopeAlertV2Settings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::NetskopeAlertV2Settings'->new($_) } @$_ ] };

declare 'MapStringNetskopeAlertV2Settings',
    as HashRef[NetskopeAlertV2Settings()];

declare 'AzureMDMIntuneSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::AzureMDMIntuneSettings'];

coerce 'AzureMDMIntuneSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::AzureMDMIntuneSettings'->new($_) };

declare 'RepeatedAzureMDMIntuneSettings',
    as ArrayRef[AzureMDMIntuneSettings()];

coerce 'RepeatedAzureMDMIntuneSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::AzureMDMIntuneSettings'->new($_) } @$_ ] };

declare 'MapStringAzureMDMIntuneSettings',
    as HashRef[AzureMDMIntuneSettings()];

declare 'WorkspaceUsersSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::WorkspaceUsersSettings'];

coerce 'WorkspaceUsersSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::WorkspaceUsersSettings'->new($_) };

declare 'RepeatedWorkspaceUsersSettings',
    as ArrayRef[WorkspaceUsersSettings()];

coerce 'RepeatedWorkspaceUsersSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::WorkspaceUsersSettings'->new($_) } @$_ ] };

declare 'MapStringWorkspaceUsersSettings',
    as HashRef[WorkspaceUsersSettings()];

declare 'ProjectionType',
    as (Int | Str);

declare 'WorkspaceActivitySettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::WorkspaceActivitySettings'];

coerce 'WorkspaceActivitySettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::WorkspaceActivitySettings'->new($_) };

declare 'RepeatedWorkspaceActivitySettings',
    as ArrayRef[WorkspaceActivitySettings()];

coerce 'RepeatedWorkspaceActivitySettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::WorkspaceActivitySettings'->new($_) } @$_ ] };

declare 'MapStringWorkspaceActivitySettings',
    as HashRef[WorkspaceActivitySettings()];

declare 'WorkspaceAlertsSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::WorkspaceAlertsSettings'];

coerce 'WorkspaceAlertsSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::WorkspaceAlertsSettings'->new($_) };

declare 'RepeatedWorkspaceAlertsSettings',
    as ArrayRef[WorkspaceAlertsSettings()];

coerce 'RepeatedWorkspaceAlertsSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::WorkspaceAlertsSettings'->new($_) } @$_ ] };

declare 'MapStringWorkspaceAlertsSettings',
    as HashRef[WorkspaceAlertsSettings()];

declare 'WorkspacePrivilegesSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::WorkspacePrivilegesSettings'];

coerce 'WorkspacePrivilegesSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::WorkspacePrivilegesSettings'->new($_) };

declare 'RepeatedWorkspacePrivilegesSettings',
    as ArrayRef[WorkspacePrivilegesSettings()];

coerce 'RepeatedWorkspacePrivilegesSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::WorkspacePrivilegesSettings'->new($_) } @$_ ] };

declare 'MapStringWorkspacePrivilegesSettings',
    as HashRef[WorkspacePrivilegesSettings()];

declare 'WorkspaceMobileSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::WorkspaceMobileSettings'];

coerce 'WorkspaceMobileSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::WorkspaceMobileSettings'->new($_) };

declare 'RepeatedWorkspaceMobileSettings',
    as ArrayRef[WorkspaceMobileSettings()];

coerce 'RepeatedWorkspaceMobileSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::WorkspaceMobileSettings'->new($_) } @$_ ] };

declare 'MapStringWorkspaceMobileSettings',
    as HashRef[WorkspaceMobileSettings()];

declare 'WorkspaceChromeOSSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::WorkspaceChromeOSSettings'];

coerce 'WorkspaceChromeOSSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::WorkspaceChromeOSSettings'->new($_) };

declare 'RepeatedWorkspaceChromeOSSettings',
    as ArrayRef[WorkspaceChromeOSSettings()];

coerce 'RepeatedWorkspaceChromeOSSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::WorkspaceChromeOSSettings'->new($_) } @$_ ] };

declare 'MapStringWorkspaceChromeOSSettings',
    as HashRef[WorkspaceChromeOSSettings()];

declare 'WorkspaceGroupsSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::WorkspaceGroupsSettings'];

coerce 'WorkspaceGroupsSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::WorkspaceGroupsSettings'->new($_) };

declare 'RepeatedWorkspaceGroupsSettings',
    as ArrayRef[WorkspaceGroupsSettings()];

coerce 'RepeatedWorkspaceGroupsSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::WorkspaceGroupsSettings'->new($_) } @$_ ] };

declare 'MapStringWorkspaceGroupsSettings',
    as HashRef[WorkspaceGroupsSettings()];

declare 'GoogleCloudIdentityDevicesSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::GoogleCloudIdentityDevicesSettings'];

coerce 'GoogleCloudIdentityDevicesSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::GoogleCloudIdentityDevicesSettings'->new($_) };

declare 'RepeatedGoogleCloudIdentityDevicesSettings',
    as ArrayRef[GoogleCloudIdentityDevicesSettings()];

coerce 'RepeatedGoogleCloudIdentityDevicesSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::GoogleCloudIdentityDevicesSettings'->new($_) } @$_ ] };

declare 'MapStringGoogleCloudIdentityDevicesSettings',
    as HashRef[GoogleCloudIdentityDevicesSettings()];

declare 'GoogleCloudIdentityDeviceUsersSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::GoogleCloudIdentityDeviceUsersSettings'];

coerce 'GoogleCloudIdentityDeviceUsersSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::GoogleCloudIdentityDeviceUsersSettings'->new($_) };

declare 'RepeatedGoogleCloudIdentityDeviceUsersSettings',
    as ArrayRef[GoogleCloudIdentityDeviceUsersSettings()];

coerce 'RepeatedGoogleCloudIdentityDeviceUsersSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::GoogleCloudIdentityDeviceUsersSettings'->new($_) } @$_ ] };

declare 'MapStringGoogleCloudIdentityDeviceUsersSettings',
    as HashRef[GoogleCloudIdentityDeviceUsersSettings()];

declare 'SymantecEventExportSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::SymantecEventExportSettings'];

coerce 'SymantecEventExportSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::SymantecEventExportSettings'->new($_) };

declare 'RepeatedSymantecEventExportSettings',
    as ArrayRef[SymantecEventExportSettings()];

coerce 'RepeatedSymantecEventExportSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::SymantecEventExportSettings'->new($_) } @$_ ] };

declare 'MapStringSymantecEventExportSettings',
    as HashRef[SymantecEventExportSettings()];

declare 'QualysVMSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::QualysVMSettings'];

coerce 'QualysVMSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::QualysVMSettings'->new($_) };

declare 'RepeatedQualysVMSettings',
    as ArrayRef[QualysVMSettings()];

coerce 'RepeatedQualysVMSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::QualysVMSettings'->new($_) } @$_ ] };

declare 'MapStringQualysVMSettings',
    as HashRef[QualysVMSettings()];

declare 'PanPrismaCloudSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::PanPrismaCloudSettings'];

coerce 'PanPrismaCloudSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::PanPrismaCloudSettings'->new($_) };

declare 'RepeatedPanPrismaCloudSettings',
    as ArrayRef[PanPrismaCloudSettings()];

coerce 'RepeatedPanPrismaCloudSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::PanPrismaCloudSettings'->new($_) } @$_ ] };

declare 'MapStringPanPrismaCloudSettings',
    as HashRef[PanPrismaCloudSettings()];

declare 'SftpSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::SftpSettings'];

coerce 'SftpSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::SftpSettings'->new($_) };

declare 'RepeatedSftpSettings',
    as ArrayRef[SftpSettings()];

coerce 'RepeatedSftpSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::SftpSettings'->new($_) } @$_ ] };

declare 'MapStringSftpSettings',
    as HashRef[SftpSettings()];

declare 'GoogleCloudStorageSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::GoogleCloudStorageSettings'];

coerce 'GoogleCloudStorageSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::GoogleCloudStorageSettings'->new($_) };

declare 'RepeatedGoogleCloudStorageSettings',
    as ArrayRef[GoogleCloudStorageSettings()];

coerce 'RepeatedGoogleCloudStorageSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::GoogleCloudStorageSettings'->new($_) } @$_ ] };

declare 'MapStringGoogleCloudStorageSettings',
    as HashRef[GoogleCloudStorageSettings()];

declare 'HttpSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::HttpSettings'];

coerce 'HttpSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::HttpSettings'->new($_) };

declare 'RepeatedHttpSettings',
    as ArrayRef[HttpSettings()];

coerce 'RepeatedHttpSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::HttpSettings'->new($_) } @$_ ] };

declare 'MapStringHttpSettings',
    as HashRef[HttpSettings()];

declare 'AmazonS3Settings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::AmazonS3Settings'];

coerce 'AmazonS3Settings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::AmazonS3Settings'->new($_) };

declare 'RepeatedAmazonS3Settings',
    as ArrayRef[AmazonS3Settings()];

coerce 'RepeatedAmazonS3Settings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::AmazonS3Settings'->new($_) } @$_ ] };

declare 'MapStringAmazonS3Settings',
    as HashRef[AmazonS3Settings()];

declare 'AzureBlobStoreSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::AzureBlobStoreSettings'];

coerce 'AzureBlobStoreSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::AzureBlobStoreSettings'->new($_) };

declare 'RepeatedAzureBlobStoreSettings',
    as ArrayRef[AzureBlobStoreSettings()];

coerce 'RepeatedAzureBlobStoreSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::AzureBlobStoreSettings'->new($_) } @$_ ] };

declare 'MapStringAzureBlobStoreSettings',
    as HashRef[AzureBlobStoreSettings()];

declare 'AWSEC2HostsSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::AWSEC2HostsSettings'];

coerce 'AWSEC2HostsSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::AWSEC2HostsSettings'->new($_) };

declare 'RepeatedAWSEC2HostsSettings',
    as ArrayRef[AWSEC2HostsSettings()];

coerce 'RepeatedAWSEC2HostsSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::AWSEC2HostsSettings'->new($_) } @$_ ] };

declare 'MapStringAWSEC2HostsSettings',
    as HashRef[AWSEC2HostsSettings()];

declare 'AWSEC2InstancesSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::AWSEC2InstancesSettings'];

coerce 'AWSEC2InstancesSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::AWSEC2InstancesSettings'->new($_) };

declare 'RepeatedAWSEC2InstancesSettings',
    as ArrayRef[AWSEC2InstancesSettings()];

coerce 'RepeatedAWSEC2InstancesSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::AWSEC2InstancesSettings'->new($_) } @$_ ] };

declare 'MapStringAWSEC2InstancesSettings',
    as HashRef[AWSEC2InstancesSettings()];

declare 'AWSEC2VpcsSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::AWSEC2VpcsSettings'];

coerce 'AWSEC2VpcsSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::AWSEC2VpcsSettings'->new($_) };

declare 'RepeatedAWSEC2VpcsSettings',
    as ArrayRef[AWSEC2VpcsSettings()];

coerce 'RepeatedAWSEC2VpcsSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::AWSEC2VpcsSettings'->new($_) } @$_ ] };

declare 'MapStringAWSEC2VpcsSettings',
    as HashRef[AWSEC2VpcsSettings()];

declare 'AWSIAMSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::AWSIAMSettings'];

coerce 'AWSIAMSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::AWSIAMSettings'->new($_) };

declare 'RepeatedAWSIAMSettings',
    as ArrayRef[AWSIAMSettings()];

coerce 'RepeatedAWSIAMSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::AWSIAMSettings'->new($_) } @$_ ] };

declare 'MapStringAWSIAMSettings',
    as HashRef[AWSIAMSettings()];

declare 'ApiType',
    as (Int | Str);

declare 'AzureAuth',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::AzureAuth'];

coerce 'AzureAuth',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::AzureAuth'->new($_) };

declare 'RepeatedAzureAuth',
    as ArrayRef[AzureAuth()];

coerce 'RepeatedAzureAuth',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::AzureAuth'->new($_) } @$_ ] };

declare 'MapStringAzureAuth',
    as HashRef[AzureAuth()];

declare 'SQSAuth',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::SQSAuth'];

coerce 'SQSAuth',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::SQSAuth'->new($_) };

declare 'RepeatedSQSAuth',
    as ArrayRef[SQSAuth()];

coerce 'RepeatedSQSAuth',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::SQSAuth'->new($_) } @$_ ] };

declare 'MapStringSQSAuth',
    as HashRef[SQSAuth()];

declare 'SQSAuthV2',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::SQSAuthV2'];

coerce 'SQSAuthV2',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::SQSAuthV2'->new($_) };

declare 'RepeatedSQSAuthV2',
    as ArrayRef[SQSAuthV2()];

coerce 'RepeatedSQSAuthV2',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::SQSAuthV2'->new($_) } @$_ ] };

declare 'MapStringSQSAuthV2',
    as HashRef[SQSAuthV2()];

declare 'SQSV2AwsIamRoleAuth',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::SQSV2AwsIamRoleAuth'];

coerce 'SQSV2AwsIamRoleAuth',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::SQSV2AwsIamRoleAuth'->new($_) };

declare 'RepeatedSQSV2AwsIamRoleAuth',
    as ArrayRef[SQSV2AwsIamRoleAuth()];

coerce 'RepeatedSQSV2AwsIamRoleAuth',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::SQSV2AwsIamRoleAuth'->new($_) } @$_ ] };

declare 'MapStringSQSV2AwsIamRoleAuth',
    as HashRef[SQSV2AwsIamRoleAuth()];

declare 'SQSV2AccessKeySecretAuth',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::SQSV2AccessKeySecretAuth'];

coerce 'SQSV2AccessKeySecretAuth',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::SQSV2AccessKeySecretAuth'->new($_) };

declare 'RepeatedSQSV2AccessKeySecretAuth',
    as ArrayRef[SQSV2AccessKeySecretAuth()];

coerce 'RepeatedSQSV2AccessKeySecretAuth',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::SQSV2AccessKeySecretAuth'->new($_) } @$_ ] };

declare 'MapStringSQSV2AccessKeySecretAuth',
    as HashRef[SQSV2AccessKeySecretAuth()];

declare 'SQSAccessKeySecretAuth',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::SQSAccessKeySecretAuth'];

coerce 'SQSAccessKeySecretAuth',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::SQSAccessKeySecretAuth'->new($_) };

declare 'RepeatedSQSAccessKeySecretAuth',
    as ArrayRef[SQSAccessKeySecretAuth()];

coerce 'RepeatedSQSAccessKeySecretAuth',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::SQSAccessKeySecretAuth'->new($_) } @$_ ] };

declare 'MapStringSQSAccessKeySecretAuth',
    as HashRef[SQSAccessKeySecretAuth()];

declare 'AdditionalS3AccessKeySecretAuth',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::AdditionalS3AccessKeySecretAuth'];

coerce 'AdditionalS3AccessKeySecretAuth',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::AdditionalS3AccessKeySecretAuth'->new($_) };

declare 'RepeatedAdditionalS3AccessKeySecretAuth',
    as ArrayRef[AdditionalS3AccessKeySecretAuth()];

coerce 'RepeatedAdditionalS3AccessKeySecretAuth',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::AdditionalS3AccessKeySecretAuth'->new($_) } @$_ ] };

declare 'MapStringAdditionalS3AccessKeySecretAuth',
    as HashRef[AdditionalS3AccessKeySecretAuth()];

declare 'S3Auth',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::S3Auth'];

coerce 'S3Auth',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::S3Auth'->new($_) };

declare 'RepeatedS3Auth',
    as ArrayRef[S3Auth()];

coerce 'RepeatedS3Auth',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::S3Auth'->new($_) } @$_ ] };

declare 'MapStringS3Auth',
    as HashRef[S3Auth()];

declare 'OAuthRefreshToken',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::OAuthRefreshToken'];

coerce 'OAuthRefreshToken',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::OAuthRefreshToken'->new($_) };

declare 'RepeatedOAuthRefreshToken',
    as ArrayRef[OAuthRefreshToken()];

coerce 'RepeatedOAuthRefreshToken',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::OAuthRefreshToken'->new($_) } @$_ ] };

declare 'MapStringOAuthRefreshToken',
    as HashRef[OAuthRefreshToken()];

declare 'SftpAuth',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::SftpAuth'];

coerce 'SftpAuth',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::SftpAuth'->new($_) };

declare 'RepeatedSftpAuth',
    as ArrayRef[SftpAuth()];

coerce 'RepeatedSftpAuth',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::SftpAuth'->new($_) } @$_ ] };

declare 'MapStringSftpAuth',
    as HashRef[SftpAuth()];

declare 'HttpHeaderAuth',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::HttpHeaderAuth'];

coerce 'HttpHeaderAuth',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::HttpHeaderAuth'->new($_) };

declare 'RepeatedHttpHeaderAuth',
    as ArrayRef[HttpHeaderAuth()];

coerce 'RepeatedHttpHeaderAuth',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::HttpHeaderAuth'->new($_) } @$_ ] };

declare 'MapStringHttpHeaderAuth',
    as HashRef[HttpHeaderAuth()];

declare 'HeaderKeyValue',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::HeaderKeyValue'];

coerce 'HeaderKeyValue',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::HeaderKeyValue'->new($_) };

declare 'RepeatedHeaderKeyValue',
    as ArrayRef[HeaderKeyValue()];

coerce 'RepeatedHeaderKeyValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::HeaderKeyValue'->new($_) } @$_ ] };

declare 'MapStringHeaderKeyValue',
    as HashRef[HeaderKeyValue()];

declare 'UsernameSecretAuth',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::UsernameSecretAuth'];

coerce 'UsernameSecretAuth',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::UsernameSecretAuth'->new($_) };

declare 'RepeatedUsernameSecretAuth',
    as ArrayRef[UsernameSecretAuth()];

coerce 'RepeatedUsernameSecretAuth',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::UsernameSecretAuth'->new($_) } @$_ ] };

declare 'MapStringUsernameSecretAuth',
    as HashRef[UsernameSecretAuth()];

declare 'MicrosoftOAuthClientCredentials',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::MicrosoftOAuthClientCredentials'];

coerce 'MicrosoftOAuthClientCredentials',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::MicrosoftOAuthClientCredentials'->new($_) };

declare 'RepeatedMicrosoftOAuthClientCredentials',
    as ArrayRef[MicrosoftOAuthClientCredentials()];

coerce 'RepeatedMicrosoftOAuthClientCredentials',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::MicrosoftOAuthClientCredentials'->new($_) } @$_ ] };

declare 'MapStringMicrosoftOAuthClientCredentials',
    as HashRef[MicrosoftOAuthClientCredentials()];

declare 'OAuthClientCredentials',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::OAuthClientCredentials'];

coerce 'OAuthClientCredentials',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::OAuthClientCredentials'->new($_) };

declare 'RepeatedOAuthClientCredentials',
    as ArrayRef[OAuthClientCredentials()];

coerce 'RepeatedOAuthClientCredentials',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::OAuthClientCredentials'->new($_) } @$_ ] };

declare 'MapStringOAuthClientCredentials',
    as HashRef[OAuthClientCredentials()];

declare 'OAuthPasswordGrantCredentials',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::OAuthPasswordGrantCredentials'];

coerce 'OAuthPasswordGrantCredentials',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::OAuthPasswordGrantCredentials'->new($_) };

declare 'RepeatedOAuthPasswordGrantCredentials',
    as ArrayRef[OAuthPasswordGrantCredentials()];

coerce 'RepeatedOAuthPasswordGrantCredentials',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::OAuthPasswordGrantCredentials'->new($_) } @$_ ] };

declare 'MapStringOAuthPasswordGrantCredentials',
    as HashRef[OAuthPasswordGrantCredentials()];

declare 'PanPrismaAuth',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::PanPrismaAuth'];

coerce 'PanPrismaAuth',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::PanPrismaAuth'->new($_) };

declare 'RepeatedPanPrismaAuth',
    as ArrayRef[PanPrismaAuth()];

coerce 'RepeatedPanPrismaAuth',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::PanPrismaAuth'->new($_) } @$_ ] };

declare 'MapStringPanPrismaAuth',
    as HashRef[PanPrismaAuth()];

declare 'OAuthJWTCredentials',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::OAuthJWTCredentials'];

coerce 'OAuthJWTCredentials',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::OAuthJWTCredentials'->new($_) };

declare 'RepeatedOAuthJWTCredentials',
    as ArrayRef[OAuthJWTCredentials()];

coerce 'RepeatedOAuthJWTCredentials',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::OAuthJWTCredentials'->new($_) } @$_ ] };

declare 'MapStringOAuthJWTCredentials',
    as HashRef[OAuthJWTCredentials()];

declare 'RSCredentials',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::RSCredentials'];

coerce 'RSCredentials',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::RSCredentials'->new($_) };

declare 'RepeatedRSCredentials',
    as ArrayRef[RSCredentials()];

coerce 'RepeatedRSCredentials',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::RSCredentials'->new($_) } @$_ ] };

declare 'MapStringRSCredentials',
    as HashRef[RSCredentials()];

declare 'Claims',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::Claims'];

coerce 'Claims',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::Claims'->new($_) };

declare 'RepeatedClaims',
    as ArrayRef[Claims()];

coerce 'RepeatedClaims',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::Claims'->new($_) } @$_ ] };

declare 'MapStringClaims',
    as HashRef[Claims()];

declare 'SSLClientKeypair',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::SSLClientKeypair'];

coerce 'SSLClientKeypair',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::SSLClientKeypair'->new($_) };

declare 'RepeatedSSLClientKeypair',
    as ArrayRef[SSLClientKeypair()];

coerce 'RepeatedSSLClientKeypair',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::SSLClientKeypair'->new($_) } @$_ ] };

declare 'MapStringSSLClientKeypair',
    as HashRef[SSLClientKeypair()];

declare 'WorkdayAuth',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::WorkdayAuth'];

coerce 'WorkdayAuth',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::WorkdayAuth'->new($_) };

declare 'RepeatedWorkdayAuth',
    as ArrayRef[WorkdayAuth()];

coerce 'RepeatedWorkdayAuth',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::WorkdayAuth'->new($_) } @$_ ] };

declare 'MapStringWorkdayAuth',
    as HashRef[WorkdayAuth()];

declare 'GoogleCloudStorageV2Settings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::GoogleCloudStorageV2Settings'];

coerce 'GoogleCloudStorageV2Settings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::GoogleCloudStorageV2Settings'->new($_) };

declare 'RepeatedGoogleCloudStorageV2Settings',
    as ArrayRef[GoogleCloudStorageV2Settings()];

coerce 'RepeatedGoogleCloudStorageV2Settings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::GoogleCloudStorageV2Settings'->new($_) } @$_ ] };

declare 'MapStringGoogleCloudStorageV2Settings',
    as HashRef[GoogleCloudStorageV2Settings()];

declare 'GoogleCloudStorageEventDrivenSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::GoogleCloudStorageEventDrivenSettings'];

coerce 'GoogleCloudStorageEventDrivenSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::GoogleCloudStorageEventDrivenSettings'->new($_) };

declare 'RepeatedGoogleCloudStorageEventDrivenSettings',
    as ArrayRef[GoogleCloudStorageEventDrivenSettings()];

coerce 'RepeatedGoogleCloudStorageEventDrivenSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::GoogleCloudStorageEventDrivenSettings'->new($_) } @$_ ] };

declare 'MapStringGoogleCloudStorageEventDrivenSettings',
    as HashRef[GoogleCloudStorageEventDrivenSettings()];

declare 'S3AuthV2',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::S3AuthV2'];

coerce 'S3AuthV2',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::S3AuthV2'->new($_) };

declare 'RepeatedS3AuthV2',
    as ArrayRef[S3AuthV2()];

coerce 'RepeatedS3AuthV2',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::S3AuthV2'->new($_) } @$_ ] };

declare 'MapStringS3AuthV2',
    as HashRef[S3AuthV2()];

declare 'S3V2AwsIamRoleAuth',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::S3V2AwsIamRoleAuth'];

coerce 'S3V2AwsIamRoleAuth',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::S3V2AwsIamRoleAuth'->new($_) };

declare 'RepeatedS3V2AwsIamRoleAuth',
    as ArrayRef[S3V2AwsIamRoleAuth()];

coerce 'RepeatedS3V2AwsIamRoleAuth',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::S3V2AwsIamRoleAuth'->new($_) } @$_ ] };

declare 'MapStringS3V2AwsIamRoleAuth',
    as HashRef[S3V2AwsIamRoleAuth()];

declare 'S3V2AccessKeySecretAuth',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::S3V2AccessKeySecretAuth'];

coerce 'S3V2AccessKeySecretAuth',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::S3V2AccessKeySecretAuth'->new($_) };

declare 'RepeatedS3V2AccessKeySecretAuth',
    as ArrayRef[S3V2AccessKeySecretAuth()];

coerce 'RepeatedS3V2AccessKeySecretAuth',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::S3V2AccessKeySecretAuth'->new($_) } @$_ ] };

declare 'MapStringS3V2AccessKeySecretAuth',
    as HashRef[S3V2AccessKeySecretAuth()];

declare 'AmazonS3V2Settings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::AmazonS3V2Settings'];

coerce 'AmazonS3V2Settings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::AmazonS3V2Settings'->new($_) };

declare 'RepeatedAmazonS3V2Settings',
    as ArrayRef[AmazonS3V2Settings()];

coerce 'RepeatedAmazonS3V2Settings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::AmazonS3V2Settings'->new($_) } @$_ ] };

declare 'MapStringAmazonS3V2Settings',
    as HashRef[AmazonS3V2Settings()];

declare 'MssoAuthentication',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::MssoAuthentication'];

coerce 'MssoAuthentication',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::MssoAuthentication'->new($_) };

declare 'RepeatedMssoAuthentication',
    as ArrayRef[MssoAuthentication()];

coerce 'RepeatedMssoAuthentication',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::MssoAuthentication'->new($_) } @$_ ] };

declare 'MapStringMssoAuthentication',
    as HashRef[MssoAuthentication()];

declare 'MimecastV2OAuthClientCredentials',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::MimecastV2OAuthClientCredentials'];

coerce 'MimecastV2OAuthClientCredentials',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::MimecastV2OAuthClientCredentials'->new($_) };

declare 'RepeatedMimecastV2OAuthClientCredentials',
    as ArrayRef[MimecastV2OAuthClientCredentials()];

coerce 'RepeatedMimecastV2OAuthClientCredentials',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::MimecastV2OAuthClientCredentials'->new($_) } @$_ ] };

declare 'MapStringMimecastV2OAuthClientCredentials',
    as HashRef[MimecastV2OAuthClientCredentials()];

declare 'TrellixIAMAuthentication',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::TrellixIAMAuthentication'];

coerce 'TrellixIAMAuthentication',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::TrellixIAMAuthentication'->new($_) };

declare 'RepeatedTrellixIAMAuthentication',
    as ArrayRef[TrellixIAMAuthentication()];

coerce 'RepeatedTrellixIAMAuthentication',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::TrellixIAMAuthentication'->new($_) } @$_ ] };

declare 'MapStringTrellixIAMAuthentication',
    as HashRef[TrellixIAMAuthentication()];

declare 'TrellixLocalAuthentication',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::TrellixLocalAuthentication'];

coerce 'TrellixLocalAuthentication',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::TrellixLocalAuthentication'->new($_) };

declare 'RepeatedTrellixLocalAuthentication',
    as ArrayRef[TrellixLocalAuthentication()];

coerce 'RepeatedTrellixLocalAuthentication',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::TrellixLocalAuthentication'->new($_) } @$_ ] };

declare 'MapStringTrellixLocalAuthentication',
    as HashRef[TrellixLocalAuthentication()];

declare 'TrellixStarXAuthentication',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::TrellixStarXAuthentication'];

coerce 'TrellixStarXAuthentication',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::TrellixStarXAuthentication'->new($_) };

declare 'RepeatedTrellixStarXAuthentication',
    as ArrayRef[TrellixStarXAuthentication()];

coerce 'RepeatedTrellixStarXAuthentication',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::TrellixStarXAuthentication'->new($_) } @$_ ] };

declare 'MapStringTrellixStarXAuthentication',
    as HashRef[TrellixStarXAuthentication()];

declare 'TrellixHxHostsSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::TrellixHxHostsSettings'];

coerce 'TrellixHxHostsSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::TrellixHxHostsSettings'->new($_) };

declare 'RepeatedTrellixHxHostsSettings',
    as ArrayRef[TrellixHxHostsSettings()];

coerce 'RepeatedTrellixHxHostsSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::TrellixHxHostsSettings'->new($_) } @$_ ] };

declare 'MapStringTrellixHxHostsSettings',
    as HashRef[TrellixHxHostsSettings()];

declare 'TrellixHxAlertsSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::TrellixHxAlertsSettings'];

coerce 'TrellixHxAlertsSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::TrellixHxAlertsSettings'->new($_) };

declare 'RepeatedTrellixHxAlertsSettings',
    as ArrayRef[TrellixHxAlertsSettings()];

coerce 'RepeatedTrellixHxAlertsSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::TrellixHxAlertsSettings'->new($_) } @$_ ] };

declare 'MapStringTrellixHxAlertsSettings',
    as HashRef[TrellixHxAlertsSettings()];

declare 'TrellixHxBulkAcqsSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::TrellixHxBulkAcqsSettings'];

coerce 'TrellixHxBulkAcqsSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::TrellixHxBulkAcqsSettings'->new($_) };

declare 'RepeatedTrellixHxBulkAcqsSettings',
    as ArrayRef[TrellixHxBulkAcqsSettings()];

coerce 'RepeatedTrellixHxBulkAcqsSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::TrellixHxBulkAcqsSettings'->new($_) } @$_ ] };

declare 'MapStringTrellixHxBulkAcqsSettings',
    as HashRef[TrellixHxBulkAcqsSettings()];

declare 'AzureEventHubSettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::AzureEventHubSettings'];

coerce 'AzureEventHubSettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::AzureEventHubSettings'->new($_) };

declare 'RepeatedAzureEventHubSettings',
    as ArrayRef[AzureEventHubSettings()];

coerce 'RepeatedAzureEventHubSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::AzureEventHubSettings'->new($_) } @$_ ] };

declare 'MapStringAzureEventHubSettings',
    as HashRef[AzureEventHubSettings()];

declare 'AmazonSQSV2Settings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::AmazonSQSV2Settings'];

coerce 'AmazonSQSV2Settings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::AmazonSQSV2Settings'->new($_) };

declare 'RepeatedAmazonSQSV2Settings',
    as ArrayRef[AmazonSQSV2Settings()];

coerce 'RepeatedAmazonSQSV2Settings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::AmazonSQSV2Settings'->new($_) } @$_ ] };

declare 'MapStringAmazonSQSV2Settings',
    as HashRef[AmazonSQSV2Settings()];

declare 'AzureBlobStoreV2Settings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::AzureBlobStoreV2Settings'];

coerce 'AzureBlobStoreV2Settings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::AzureBlobStoreV2Settings'->new($_) };

declare 'RepeatedAzureBlobStoreV2Settings',
    as ArrayRef[AzureBlobStoreV2Settings()];

coerce 'RepeatedAzureBlobStoreV2Settings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::AzureBlobStoreV2Settings'->new($_) } @$_ ] };

declare 'MapStringAzureBlobStoreV2Settings',
    as HashRef[AzureBlobStoreV2Settings()];

declare 'AzureV2WorkloadIdentityFederation',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::AzureV2WorkloadIdentityFederation'];

coerce 'AzureV2WorkloadIdentityFederation',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::AzureV2WorkloadIdentityFederation'->new($_) };

declare 'RepeatedAzureV2WorkloadIdentityFederation',
    as ArrayRef[AzureV2WorkloadIdentityFederation()];

coerce 'RepeatedAzureV2WorkloadIdentityFederation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::AzureV2WorkloadIdentityFederation'->new($_) } @$_ ] };

declare 'MapStringAzureV2WorkloadIdentityFederation',
    as HashRef[AzureV2WorkloadIdentityFederation()];

declare 'AzureAuthV2',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::AzureAuthV2'];

coerce 'AzureAuthV2',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::AzureAuthV2'->new($_) };

declare 'RepeatedAzureAuthV2',
    as ArrayRef[AzureAuthV2()];

coerce 'RepeatedAzureAuthV2',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::AzureAuthV2'->new($_) } @$_ ] };

declare 'MapStringAzureAuthV2',
    as HashRef[AzureAuthV2()];

declare 'FeedSourceTypeSchema',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::FeedSourceTypeSchema'];

coerce 'FeedSourceTypeSchema',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::FeedSourceTypeSchema'->new($_) };

declare 'RepeatedFeedSourceTypeSchema',
    as ArrayRef[FeedSourceTypeSchema()];

coerce 'RepeatedFeedSourceTypeSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::FeedSourceTypeSchema'->new($_) } @$_ ] };

declare 'MapStringFeedSourceTypeSchema',
    as HashRef[FeedSourceTypeSchema()];

declare 'LogTypeSchema',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::LogTypeSchema'];

coerce 'LogTypeSchema',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::LogTypeSchema'->new($_) };

declare 'RepeatedLogTypeSchema',
    as ArrayRef[LogTypeSchema()];

coerce 'RepeatedLogTypeSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::LogTypeSchema'->new($_) } @$_ ] };

declare 'MapStringLogTypeSchema',
    as HashRef[LogTypeSchema()];

declare 'DetailsFieldSchemaAlternative',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::LogTypeSchema::DetailsFieldSchemaAlternative'];

coerce 'DetailsFieldSchemaAlternative',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::LogTypeSchema::DetailsFieldSchemaAlternative'->new($_) };

declare 'RepeatedDetailsFieldSchemaAlternative',
    as ArrayRef[DetailsFieldSchemaAlternative()];

coerce 'RepeatedDetailsFieldSchemaAlternative',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::LogTypeSchema::DetailsFieldSchemaAlternative'->new($_) } @$_ ] };

declare 'MapStringDetailsFieldSchemaAlternative',
    as HashRef[DetailsFieldSchemaAlternative()];

declare 'DetailsFieldSchemaSet',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::LogTypeSchema::DetailsFieldSchemaSet'];

coerce 'DetailsFieldSchemaSet',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::LogTypeSchema::DetailsFieldSchemaSet'->new($_) };

declare 'RepeatedDetailsFieldSchemaSet',
    as ArrayRef[DetailsFieldSchemaSet()];

coerce 'RepeatedDetailsFieldSchemaSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::LogTypeSchema::DetailsFieldSchemaSet'->new($_) } @$_ ] };

declare 'MapStringDetailsFieldSchemaSet',
    as HashRef[DetailsFieldSchemaSet()];

declare 'DetailsFieldSchema',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::LogTypeSchema::DetailsFieldSchema'];

coerce 'DetailsFieldSchema',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::LogTypeSchema::DetailsFieldSchema'->new($_) };

declare 'RepeatedDetailsFieldSchema',
    as ArrayRef[DetailsFieldSchema()];

coerce 'RepeatedDetailsFieldSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::LogTypeSchema::DetailsFieldSchema'->new($_) } @$_ ] };

declare 'MapStringDetailsFieldSchema',
    as HashRef[DetailsFieldSchema()];

declare 'EnumFieldSchema',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::LogTypeSchema::EnumFieldSchema'];

coerce 'EnumFieldSchema',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::LogTypeSchema::EnumFieldSchema'->new($_) };

declare 'RepeatedEnumFieldSchema',
    as ArrayRef[EnumFieldSchema()];

coerce 'RepeatedEnumFieldSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::LogTypeSchema::EnumFieldSchema'->new($_) } @$_ ] };

declare 'MapStringEnumFieldSchema',
    as HashRef[EnumFieldSchema()];

declare 'FetchServiceAccountForCustomerRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::FetchServiceAccountForCustomerRequest'];

coerce 'FetchServiceAccountForCustomerRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::FetchServiceAccountForCustomerRequest'->new($_) };

declare 'RepeatedFetchServiceAccountForCustomerRequest',
    as ArrayRef[FetchServiceAccountForCustomerRequest()];

coerce 'RepeatedFetchServiceAccountForCustomerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::FetchServiceAccountForCustomerRequest'->new($_) } @$_ ] };

declare 'MapStringFetchServiceAccountForCustomerRequest',
    as HashRef[FetchServiceAccountForCustomerRequest()];

declare 'ListFeedSourceTypeSchemasRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::ListFeedSourceTypeSchemasRequest'];

coerce 'ListFeedSourceTypeSchemasRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::ListFeedSourceTypeSchemasRequest'->new($_) };

declare 'RepeatedListFeedSourceTypeSchemasRequest',
    as ArrayRef[ListFeedSourceTypeSchemasRequest()];

coerce 'RepeatedListFeedSourceTypeSchemasRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::ListFeedSourceTypeSchemasRequest'->new($_) } @$_ ] };

declare 'MapStringListFeedSourceTypeSchemasRequest',
    as HashRef[ListFeedSourceTypeSchemasRequest()];

declare 'ListFeedSourceTypeSchemasResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::ListFeedSourceTypeSchemasResponse'];

coerce 'ListFeedSourceTypeSchemasResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::ListFeedSourceTypeSchemasResponse'->new($_) };

declare 'RepeatedListFeedSourceTypeSchemasResponse',
    as ArrayRef[ListFeedSourceTypeSchemasResponse()];

coerce 'RepeatedListFeedSourceTypeSchemasResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::ListFeedSourceTypeSchemasResponse'->new($_) } @$_ ] };

declare 'MapStringListFeedSourceTypeSchemasResponse',
    as HashRef[ListFeedSourceTypeSchemasResponse()];

declare 'ListLogTypeSchemasRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::ListLogTypeSchemasRequest'];

coerce 'ListLogTypeSchemasRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::ListLogTypeSchemasRequest'->new($_) };

declare 'RepeatedListLogTypeSchemasRequest',
    as ArrayRef[ListLogTypeSchemasRequest()];

coerce 'RepeatedListLogTypeSchemasRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::ListLogTypeSchemasRequest'->new($_) } @$_ ] };

declare 'MapStringListLogTypeSchemasRequest',
    as HashRef[ListLogTypeSchemasRequest()];

declare 'ListLogTypeSchemasResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::ListLogTypeSchemasResponse'];

coerce 'ListLogTypeSchemasResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::ListLogTypeSchemasResponse'->new($_) };

declare 'RepeatedListLogTypeSchemasResponse',
    as ArrayRef[ListLogTypeSchemasResponse()];

coerce 'RepeatedListLogTypeSchemasResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::ListLogTypeSchemasResponse'->new($_) } @$_ ] };

declare 'MapStringListLogTypeSchemasResponse',
    as HashRef[ListLogTypeSchemasResponse()];

declare 'ImportPushLogsRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::ImportPushLogsRequest'];

coerce 'ImportPushLogsRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::ImportPushLogsRequest'->new($_) };

declare 'RepeatedImportPushLogsRequest',
    as ArrayRef[ImportPushLogsRequest()];

coerce 'RepeatedImportPushLogsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::ImportPushLogsRequest'->new($_) } @$_ ] };

declare 'MapStringImportPushLogsRequest',
    as HashRef[ImportPushLogsRequest()];

declare 'UpdateFeedRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::UpdateFeedRequest'];

coerce 'UpdateFeedRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::UpdateFeedRequest'->new($_) };

declare 'RepeatedUpdateFeedRequest',
    as ArrayRef[UpdateFeedRequest()];

coerce 'RepeatedUpdateFeedRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::UpdateFeedRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateFeedRequest',
    as HashRef[UpdateFeedRequest()];

declare 'ListFeedsRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::ListFeedsRequest'];

coerce 'ListFeedsRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::ListFeedsRequest'->new($_) };

declare 'RepeatedListFeedsRequest',
    as ArrayRef[ListFeedsRequest()];

coerce 'RepeatedListFeedsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::ListFeedsRequest'->new($_) } @$_ ] };

declare 'MapStringListFeedsRequest',
    as HashRef[ListFeedsRequest()];

declare 'ListFeedsResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::ListFeedsResponse'];

coerce 'ListFeedsResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::ListFeedsResponse'->new($_) };

declare 'RepeatedListFeedsResponse',
    as ArrayRef[ListFeedsResponse()];

coerce 'RepeatedListFeedsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::ListFeedsResponse'->new($_) } @$_ ] };

declare 'MapStringListFeedsResponse',
    as HashRef[ListFeedsResponse()];

declare 'ListFeedPacksRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::ListFeedPacksRequest'];

coerce 'ListFeedPacksRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::ListFeedPacksRequest'->new($_) };

declare 'RepeatedListFeedPacksRequest',
    as ArrayRef[ListFeedPacksRequest()];

coerce 'RepeatedListFeedPacksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::ListFeedPacksRequest'->new($_) } @$_ ] };

declare 'MapStringListFeedPacksRequest',
    as HashRef[ListFeedPacksRequest()];

declare 'ListFeedPacksResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::ListFeedPacksResponse'];

coerce 'ListFeedPacksResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::ListFeedPacksResponse'->new($_) };

declare 'RepeatedListFeedPacksResponse',
    as ArrayRef[ListFeedPacksResponse()];

coerce 'RepeatedListFeedPacksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::ListFeedPacksResponse'->new($_) } @$_ ] };

declare 'MapStringListFeedPacksResponse',
    as HashRef[ListFeedPacksResponse()];

declare 'GetFeedPackRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::GetFeedPackRequest'];

coerce 'GetFeedPackRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::GetFeedPackRequest'->new($_) };

declare 'RepeatedGetFeedPackRequest',
    as ArrayRef[GetFeedPackRequest()];

coerce 'RepeatedGetFeedPackRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::GetFeedPackRequest'->new($_) } @$_ ] };

declare 'MapStringGetFeedPackRequest',
    as HashRef[GetFeedPackRequest()];

declare 'CreateFeedRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::CreateFeedRequest'];

coerce 'CreateFeedRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::CreateFeedRequest'->new($_) };

declare 'RepeatedCreateFeedRequest',
    as ArrayRef[CreateFeedRequest()];

coerce 'RepeatedCreateFeedRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::CreateFeedRequest'->new($_) } @$_ ] };

declare 'MapStringCreateFeedRequest',
    as HashRef[CreateFeedRequest()];

declare 'GetFeedRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::GetFeedRequest'];

coerce 'GetFeedRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::GetFeedRequest'->new($_) };

declare 'RepeatedGetFeedRequest',
    as ArrayRef[GetFeedRequest()];

coerce 'RepeatedGetFeedRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::GetFeedRequest'->new($_) } @$_ ] };

declare 'MapStringGetFeedRequest',
    as HashRef[GetFeedRequest()];

declare 'DeleteFeedRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::DeleteFeedRequest'];

coerce 'DeleteFeedRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::DeleteFeedRequest'->new($_) };

declare 'RepeatedDeleteFeedRequest',
    as ArrayRef[DeleteFeedRequest()];

coerce 'RepeatedDeleteFeedRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::DeleteFeedRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteFeedRequest',
    as HashRef[DeleteFeedRequest()];

declare 'EnableFeedRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::EnableFeedRequest'];

coerce 'EnableFeedRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::EnableFeedRequest'->new($_) };

declare 'RepeatedEnableFeedRequest',
    as ArrayRef[EnableFeedRequest()];

coerce 'RepeatedEnableFeedRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::EnableFeedRequest'->new($_) } @$_ ] };

declare 'MapStringEnableFeedRequest',
    as HashRef[EnableFeedRequest()];

declare 'GenerateSecretRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::GenerateSecretRequest'];

coerce 'GenerateSecretRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::GenerateSecretRequest'->new($_) };

declare 'RepeatedGenerateSecretRequest',
    as ArrayRef[GenerateSecretRequest()];

coerce 'RepeatedGenerateSecretRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::GenerateSecretRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateSecretRequest',
    as HashRef[GenerateSecretRequest()];

declare 'GenerateSecretResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::GenerateSecretResponse'];

coerce 'GenerateSecretResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::GenerateSecretResponse'->new($_) };

declare 'RepeatedGenerateSecretResponse',
    as ArrayRef[GenerateSecretResponse()];

coerce 'RepeatedGenerateSecretResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::GenerateSecretResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateSecretResponse',
    as HashRef[GenerateSecretResponse()];

declare 'DisableFeedRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::DisableFeedRequest'];

coerce 'DisableFeedRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::DisableFeedRequest'->new($_) };

declare 'RepeatedDisableFeedRequest',
    as ArrayRef[DisableFeedRequest()];

coerce 'RepeatedDisableFeedRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::DisableFeedRequest'->new($_) } @$_ ] };

declare 'MapStringDisableFeedRequest',
    as HashRef[DisableFeedRequest()];

declare 'CustomAPIHeaderKeyValue',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::CustomAPIHeaderKeyValue'];

coerce 'CustomAPIHeaderKeyValue',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::CustomAPIHeaderKeyValue'->new($_) };

declare 'RepeatedCustomAPIHeaderKeyValue',
    as ArrayRef[CustomAPIHeaderKeyValue()];

coerce 'RepeatedCustomAPIHeaderKeyValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::CustomAPIHeaderKeyValue'->new($_) } @$_ ] };

declare 'MapStringCustomAPIHeaderKeyValue',
    as HashRef[CustomAPIHeaderKeyValue()];

declare 'CustomAPIHeaderAuth',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::CustomAPIHeaderAuth'];

coerce 'CustomAPIHeaderAuth',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::CustomAPIHeaderAuth'->new($_) };

declare 'RepeatedCustomAPIHeaderAuth',
    as ArrayRef[CustomAPIHeaderAuth()];

coerce 'RepeatedCustomAPIHeaderAuth',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::CustomAPIHeaderAuth'->new($_) } @$_ ] };

declare 'MapStringCustomAPIHeaderAuth',
    as HashRef[CustomAPIHeaderAuth()];

declare 'CustomAPIQueryKeyValue',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::CustomAPIQueryKeyValue'];

coerce 'CustomAPIQueryKeyValue',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::CustomAPIQueryKeyValue'->new($_) };

declare 'RepeatedCustomAPIQueryKeyValue',
    as ArrayRef[CustomAPIQueryKeyValue()];

coerce 'RepeatedCustomAPIQueryKeyValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::CustomAPIQueryKeyValue'->new($_) } @$_ ] };

declare 'MapStringCustomAPIQueryKeyValue',
    as HashRef[CustomAPIQueryKeyValue()];

declare 'CustomAPIQueryAuth',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::CustomAPIQueryAuth'];

coerce 'CustomAPIQueryAuth',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::CustomAPIQueryAuth'->new($_) };

declare 'RepeatedCustomAPIQueryAuth',
    as ArrayRef[CustomAPIQueryAuth()];

coerce 'RepeatedCustomAPIQueryAuth',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::CustomAPIQueryAuth'->new($_) } @$_ ] };

declare 'MapStringCustomAPIQueryAuth',
    as HashRef[CustomAPIQueryAuth()];

declare 'CustomAPINoAuth',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::CustomAPINoAuth'];

coerce 'CustomAPINoAuth',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::CustomAPINoAuth'->new($_) };

declare 'RepeatedCustomAPINoAuth',
    as ArrayRef[CustomAPINoAuth()];

coerce 'RepeatedCustomAPINoAuth',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::CustomAPINoAuth'->new($_) } @$_ ] };

declare 'MapStringCustomAPINoAuth',
    as HashRef[CustomAPINoAuth()];

declare 'CustomAPISettings',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::CustomAPISettings'];

coerce 'CustomAPISettings',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::CustomAPISettings'->new($_) };

declare 'RepeatedCustomAPISettings',
    as ArrayRef[CustomAPISettings()];

coerce 'RepeatedCustomAPISettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::CustomAPISettings'->new($_) } @$_ ] };

declare 'MapStringCustomAPISettings',
    as HashRef[CustomAPISettings()];

declare 'CustomAPITransferNode',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::CustomAPITransferNode'];

coerce 'CustomAPITransferNode',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::CustomAPITransferNode'->new($_) };

declare 'RepeatedCustomAPITransferNode',
    as ArrayRef[CustomAPITransferNode()];

coerce 'RepeatedCustomAPITransferNode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::CustomAPITransferNode'->new($_) } @$_ ] };

declare 'MapStringCustomAPITransferNode',
    as HashRef[CustomAPITransferNode()];

declare 'CustomAPIDependentRequestsConfig',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::CustomAPIDependentRequestsConfig'];

coerce 'CustomAPIDependentRequestsConfig',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::CustomAPIDependentRequestsConfig'->new($_) };

declare 'RepeatedCustomAPIDependentRequestsConfig',
    as ArrayRef[CustomAPIDependentRequestsConfig()];

coerce 'RepeatedCustomAPIDependentRequestsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::CustomAPIDependentRequestsConfig'->new($_) } @$_ ] };

declare 'MapStringCustomAPIDependentRequestsConfig',
    as HashRef[CustomAPIDependentRequestsConfig()];

declare 'CustomAPIRequestConfig',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::CustomAPIRequestConfig'];

coerce 'CustomAPIRequestConfig',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::CustomAPIRequestConfig'->new($_) };

declare 'RepeatedCustomAPIRequestConfig',
    as ArrayRef[CustomAPIRequestConfig()];

coerce 'RepeatedCustomAPIRequestConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::CustomAPIRequestConfig'->new($_) } @$_ ] };

declare 'MapStringCustomAPIRequestConfig',
    as HashRef[CustomAPIRequestConfig()];

declare 'HttpMethod',
    as (Int | Str);

declare 'CustomAPIResponseConfig',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::CustomAPIResponseConfig'];

coerce 'CustomAPIResponseConfig',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::CustomAPIResponseConfig'->new($_) };

declare 'RepeatedCustomAPIResponseConfig',
    as ArrayRef[CustomAPIResponseConfig()];

coerce 'RepeatedCustomAPIResponseConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::CustomAPIResponseConfig'->new($_) } @$_ ] };

declare 'MapStringCustomAPIResponseConfig',
    as HashRef[CustomAPIResponseConfig()];

declare 'CustomAPICheckpointConfig',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::CustomAPICheckpointConfig'];

coerce 'CustomAPICheckpointConfig',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::CustomAPICheckpointConfig'->new($_) };

declare 'RepeatedCustomAPICheckpointConfig',
    as ArrayRef[CustomAPICheckpointConfig()];

coerce 'RepeatedCustomAPICheckpointConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::CustomAPICheckpointConfig'->new($_) } @$_ ] };

declare 'MapStringCustomAPICheckpointConfig',
    as HashRef[CustomAPICheckpointConfig()];

declare 'NoneStrategy',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::CustomAPICheckpointConfig::NoneStrategy'];

coerce 'NoneStrategy',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::CustomAPICheckpointConfig::NoneStrategy'->new($_) };

declare 'RepeatedNoneStrategy',
    as ArrayRef[NoneStrategy()];

coerce 'RepeatedNoneStrategy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::CustomAPICheckpointConfig::NoneStrategy'->new($_) } @$_ ] };

declare 'MapStringNoneStrategy',
    as HashRef[NoneStrategy()];

declare 'LatestTimestampStrategy',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::CustomAPICheckpointConfig::LatestTimestampStrategy'];

coerce 'LatestTimestampStrategy',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::CustomAPICheckpointConfig::LatestTimestampStrategy'->new($_) };

declare 'RepeatedLatestTimestampStrategy',
    as ArrayRef[LatestTimestampStrategy()];

coerce 'RepeatedLatestTimestampStrategy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::CustomAPICheckpointConfig::LatestTimestampStrategy'->new($_) } @$_ ] };

declare 'MapStringLatestTimestampStrategy',
    as HashRef[LatestTimestampStrategy()];

declare 'LatestRecordStrategy',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::CustomAPICheckpointConfig::LatestRecordStrategy'];

coerce 'LatestRecordStrategy',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::CustomAPICheckpointConfig::LatestRecordStrategy'->new($_) };

declare 'RepeatedLatestRecordStrategy',
    as ArrayRef[LatestRecordStrategy()];

coerce 'RepeatedLatestRecordStrategy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::CustomAPICheckpointConfig::LatestRecordStrategy'->new($_) } @$_ ] };

declare 'MapStringLatestRecordStrategy',
    as HashRef[LatestRecordStrategy()];

declare 'IteratorStrategy',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::CustomAPICheckpointConfig::IteratorStrategy'];

coerce 'IteratorStrategy',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::CustomAPICheckpointConfig::IteratorStrategy'->new($_) };

declare 'RepeatedIteratorStrategy',
    as ArrayRef[IteratorStrategy()];

coerce 'RepeatedIteratorStrategy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::CustomAPICheckpointConfig::IteratorStrategy'->new($_) } @$_ ] };

declare 'MapStringIteratorStrategy',
    as HashRef[IteratorStrategy()];

declare 'CustomAPIPagination',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::CustomAPIPagination'];

coerce 'CustomAPIPagination',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::CustomAPIPagination'->new($_) };

declare 'RepeatedCustomAPIPagination',
    as ArrayRef[CustomAPIPagination()];

coerce 'RepeatedCustomAPIPagination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::CustomAPIPagination'->new($_) } @$_ ] };

declare 'MapStringCustomAPIPagination',
    as HashRef[CustomAPIPagination()];

declare 'NonePagination',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::CustomAPIPagination::NonePagination'];

coerce 'NonePagination',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::CustomAPIPagination::NonePagination'->new($_) };

declare 'RepeatedNonePagination',
    as ArrayRef[NonePagination()];

coerce 'RepeatedNonePagination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::CustomAPIPagination::NonePagination'->new($_) } @$_ ] };

declare 'MapStringNonePagination',
    as HashRef[NonePagination()];

declare 'TokenPagination',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::CustomAPIPagination::TokenPagination'];

coerce 'TokenPagination',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::CustomAPIPagination::TokenPagination'->new($_) };

declare 'RepeatedTokenPagination',
    as ArrayRef[TokenPagination()];

coerce 'RepeatedTokenPagination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::CustomAPIPagination::TokenPagination'->new($_) } @$_ ] };

declare 'MapStringTokenPagination',
    as HashRef[TokenPagination()];

declare 'LinkPagination',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::CustomAPIPagination::LinkPagination'];

coerce 'LinkPagination',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::CustomAPIPagination::LinkPagination'->new($_) };

declare 'RepeatedLinkPagination',
    as ArrayRef[LinkPagination()];

coerce 'RepeatedLinkPagination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::CustomAPIPagination::LinkPagination'->new($_) } @$_ ] };

declare 'MapStringLinkPagination',
    as HashRef[LinkPagination()];

declare 'OffsetPagination',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::CustomAPIPagination::OffsetPagination'];

coerce 'OffsetPagination',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::CustomAPIPagination::OffsetPagination'->new($_) };

declare 'RepeatedOffsetPagination',
    as ArrayRef[OffsetPagination()];

coerce 'RepeatedOffsetPagination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::CustomAPIPagination::OffsetPagination'->new($_) } @$_ ] };

declare 'MapStringOffsetPagination',
    as HashRef[OffsetPagination()];

declare 'PageNumberPagination',
    as InstanceOf['Google::Cloud::Chronicle::V1::Feed::CustomAPIPagination::PageNumberPagination'];

coerce 'PageNumberPagination',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::Feed::CustomAPIPagination::PageNumberPagination'->new($_) };

declare 'RepeatedPageNumberPagination',
    as ArrayRef[PageNumberPagination()];

coerce 'RepeatedPageNumberPagination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::Feed::CustomAPIPagination::PageNumberPagination'->new($_) } @$_ ] };

declare 'MapStringPageNumberPagination',
    as HashRef[PageNumberPagination()];

1;

__END__

=head1 NAME

Google::Cloud::Chronicle::V1::Feed::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
