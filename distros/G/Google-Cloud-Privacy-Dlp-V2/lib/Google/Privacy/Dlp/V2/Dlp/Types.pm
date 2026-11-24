package Google::Privacy::Dlp::V2::Dlp::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ContentPolicyVerdict',
    as (Int | Str);

declare 'TransformationResultStatusType',
    as (Int | Str);

declare 'TransformationContainerType',
    as (Int | Str);

declare 'TransformationType',
    as (Int | Str);

declare 'ProfileGeneration',
    as (Int | Str);

declare 'BigQueryTableTypeCollection',
    as (Int | Str);

declare 'BigQueryTableType',
    as (Int | Str);

declare 'DataProfileUpdateFrequency',
    as (Int | Str);

declare 'BigQueryTableModification',
    as (Int | Str);

declare 'BigQuerySchemaModification',
    as (Int | Str);

declare 'RelationalOperator',
    as (Int | Str);

declare 'MatchingType',
    as (Int | Str);

declare 'ContentOption',
    as (Int | Str);

declare 'MetadataType',
    as (Int | Str);

declare 'InfoTypeSupportedBy',
    as (Int | Str);

declare 'DlpJobType',
    as (Int | Str);

declare 'StoredInfoTypeState',
    as (Int | Str);

declare 'ResourceVisibility',
    as (Int | Str);

declare 'EncryptionStatus',
    as (Int | Str);

declare 'NullPercentageLevel',
    as (Int | Str);

declare 'UniquenessScoreLevel',
    as (Int | Str);

declare 'ConnectionState',
    as (Int | Str);

declare 'ExcludeInfoTypes',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ExcludeInfoTypes'];

coerce 'ExcludeInfoTypes',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ExcludeInfoTypes'->new($_) };

declare 'RepeatedExcludeInfoTypes',
    as ArrayRef[ExcludeInfoTypes()];

coerce 'RepeatedExcludeInfoTypes',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ExcludeInfoTypes'->new($_) } @$_ ] };

declare 'MapStringExcludeInfoTypes',
    as HashRef[ExcludeInfoTypes()];

declare 'ExcludeByHotword',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ExcludeByHotword'];

coerce 'ExcludeByHotword',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ExcludeByHotword'->new($_) };

declare 'RepeatedExcludeByHotword',
    as ArrayRef[ExcludeByHotword()];

coerce 'RepeatedExcludeByHotword',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ExcludeByHotword'->new($_) } @$_ ] };

declare 'MapStringExcludeByHotword',
    as HashRef[ExcludeByHotword()];

declare 'ExcludeByImageFindings',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ExcludeByImageFindings'];

coerce 'ExcludeByImageFindings',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ExcludeByImageFindings'->new($_) };

declare 'RepeatedExcludeByImageFindings',
    as ArrayRef[ExcludeByImageFindings()];

coerce 'RepeatedExcludeByImageFindings',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ExcludeByImageFindings'->new($_) } @$_ ] };

declare 'MapStringExcludeByImageFindings',
    as HashRef[ExcludeByImageFindings()];

declare 'ExclusionRule',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ExclusionRule'];

coerce 'ExclusionRule',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ExclusionRule'->new($_) };

declare 'RepeatedExclusionRule',
    as ArrayRef[ExclusionRule()];

coerce 'RepeatedExclusionRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ExclusionRule'->new($_) } @$_ ] };

declare 'MapStringExclusionRule',
    as HashRef[ExclusionRule()];

declare 'AdjustByMatchingInfoTypes',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::AdjustByMatchingInfoTypes'];

coerce 'AdjustByMatchingInfoTypes',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::AdjustByMatchingInfoTypes'->new($_) };

declare 'RepeatedAdjustByMatchingInfoTypes',
    as ArrayRef[AdjustByMatchingInfoTypes()];

coerce 'RepeatedAdjustByMatchingInfoTypes',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::AdjustByMatchingInfoTypes'->new($_) } @$_ ] };

declare 'MapStringAdjustByMatchingInfoTypes',
    as HashRef[AdjustByMatchingInfoTypes()];

declare 'AdjustByImageFindings',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::AdjustByImageFindings'];

coerce 'AdjustByImageFindings',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::AdjustByImageFindings'->new($_) };

declare 'RepeatedAdjustByImageFindings',
    as ArrayRef[AdjustByImageFindings()];

coerce 'RepeatedAdjustByImageFindings',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::AdjustByImageFindings'->new($_) } @$_ ] };

declare 'MapStringAdjustByImageFindings',
    as HashRef[AdjustByImageFindings()];

declare 'AdjustmentRule',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::AdjustmentRule'];

coerce 'AdjustmentRule',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::AdjustmentRule'->new($_) };

declare 'RepeatedAdjustmentRule',
    as ArrayRef[AdjustmentRule()];

coerce 'RepeatedAdjustmentRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::AdjustmentRule'->new($_) } @$_ ] };

declare 'MapStringAdjustmentRule',
    as HashRef[AdjustmentRule()];

declare 'InspectionRule',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::InspectionRule'];

coerce 'InspectionRule',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::InspectionRule'->new($_) };

declare 'RepeatedInspectionRule',
    as ArrayRef[InspectionRule()];

coerce 'RepeatedInspectionRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::InspectionRule'->new($_) } @$_ ] };

declare 'MapStringInspectionRule',
    as HashRef[InspectionRule()];

declare 'InspectionRuleSet',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::InspectionRuleSet'];

coerce 'InspectionRuleSet',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::InspectionRuleSet'->new($_) };

declare 'RepeatedInspectionRuleSet',
    as ArrayRef[InspectionRuleSet()];

coerce 'RepeatedInspectionRuleSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::InspectionRuleSet'->new($_) } @$_ ] };

declare 'MapStringInspectionRuleSet',
    as HashRef[InspectionRuleSet()];

declare 'InspectConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::InspectConfig'];

coerce 'InspectConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::InspectConfig'->new($_) };

declare 'RepeatedInspectConfig',
    as ArrayRef[InspectConfig()];

coerce 'RepeatedInspectConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::InspectConfig'->new($_) } @$_ ] };

declare 'MapStringInspectConfig',
    as HashRef[InspectConfig()];

declare 'InfoTypeLikelihood',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::InspectConfig::InfoTypeLikelihood'];

coerce 'InfoTypeLikelihood',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::InspectConfig::InfoTypeLikelihood'->new($_) };

declare 'RepeatedInfoTypeLikelihood',
    as ArrayRef[InfoTypeLikelihood()];

coerce 'RepeatedInfoTypeLikelihood',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::InspectConfig::InfoTypeLikelihood'->new($_) } @$_ ] };

declare 'MapStringInfoTypeLikelihood',
    as HashRef[InfoTypeLikelihood()];

declare 'FindingLimits',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::InspectConfig::FindingLimits'];

coerce 'FindingLimits',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::InspectConfig::FindingLimits'->new($_) };

declare 'RepeatedFindingLimits',
    as ArrayRef[FindingLimits()];

coerce 'RepeatedFindingLimits',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::InspectConfig::FindingLimits'->new($_) } @$_ ] };

declare 'MapStringFindingLimits',
    as HashRef[FindingLimits()];

declare 'InfoTypeLimit',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::InspectConfig::FindingLimits::InfoTypeLimit'];

coerce 'InfoTypeLimit',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::InspectConfig::FindingLimits::InfoTypeLimit'->new($_) };

declare 'RepeatedInfoTypeLimit',
    as ArrayRef[InfoTypeLimit()];

coerce 'RepeatedInfoTypeLimit',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::InspectConfig::FindingLimits::InfoTypeLimit'->new($_) } @$_ ] };

declare 'MapStringInfoTypeLimit',
    as HashRef[InfoTypeLimit()];

declare 'ByteContentItem',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ByteContentItem'];

coerce 'ByteContentItem',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ByteContentItem'->new($_) };

declare 'RepeatedByteContentItem',
    as ArrayRef[ByteContentItem()];

coerce 'RepeatedByteContentItem',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ByteContentItem'->new($_) } @$_ ] };

declare 'MapStringByteContentItem',
    as HashRef[ByteContentItem()];

declare 'BytesType',
    as (Int | Str);

declare 'ContentItem',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ContentItem'];

coerce 'ContentItem',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ContentItem'->new($_) };

declare 'RepeatedContentItem',
    as ArrayRef[ContentItem()];

coerce 'RepeatedContentItem',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ContentItem'->new($_) } @$_ ] };

declare 'MapStringContentItem',
    as HashRef[ContentItem()];

declare 'ContentMetadata',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ContentMetadata'];

coerce 'ContentMetadata',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ContentMetadata'->new($_) };

declare 'RepeatedContentMetadata',
    as ArrayRef[ContentMetadata()];

coerce 'RepeatedContentMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ContentMetadata'->new($_) } @$_ ] };

declare 'MapStringContentMetadata',
    as HashRef[ContentMetadata()];

declare 'Conversation',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::Conversation'];

coerce 'Conversation',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::Conversation'->new($_) };

declare 'RepeatedConversation',
    as ArrayRef[Conversation()];

coerce 'RepeatedConversation',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::Conversation'->new($_) } @$_ ] };

declare 'MapStringConversation',
    as HashRef[Conversation()];

declare 'ConversationMessage',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ConversationMessage'];

coerce 'ConversationMessage',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ConversationMessage'->new($_) };

declare 'RepeatedConversationMessage',
    as ArrayRef[ConversationMessage()];

coerce 'RepeatedConversationMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ConversationMessage'->new($_) } @$_ ] };

declare 'MapStringConversationMessage',
    as HashRef[ConversationMessage()];

declare 'MessageType',
    as (Int | Str);

declare 'BatchContentItem',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::BatchContentItem'];

coerce 'BatchContentItem',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::BatchContentItem'->new($_) };

declare 'RepeatedBatchContentItem',
    as ArrayRef[BatchContentItem()];

coerce 'RepeatedBatchContentItem',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::BatchContentItem'->new($_) } @$_ ] };

declare 'MapStringBatchContentItem',
    as HashRef[BatchContentItem()];

declare 'StringValueBatch',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::StringValueBatch'];

coerce 'StringValueBatch',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::StringValueBatch'->new($_) };

declare 'RepeatedStringValueBatch',
    as ArrayRef[StringValueBatch()];

coerce 'RepeatedStringValueBatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::StringValueBatch'->new($_) } @$_ ] };

declare 'MapStringStringValueBatch',
    as HashRef[StringValueBatch()];

declare 'Table',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::Table'];

coerce 'Table',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::Table'->new($_) };

declare 'RepeatedTable',
    as ArrayRef[Table()];

coerce 'RepeatedTable',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::Table'->new($_) } @$_ ] };

declare 'MapStringTable',
    as HashRef[Table()];

declare 'Row',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::Table::Row'];

coerce 'Row',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::Table::Row'->new($_) };

declare 'RepeatedRow',
    as ArrayRef[Row()];

coerce 'RepeatedRow',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::Table::Row'->new($_) } @$_ ] };

declare 'MapStringRow',
    as HashRef[Row()];

declare 'KeyValueMetadataProperty',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::KeyValueMetadataProperty'];

coerce 'KeyValueMetadataProperty',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::KeyValueMetadataProperty'->new($_) };

declare 'RepeatedKeyValueMetadataProperty',
    as ArrayRef[KeyValueMetadataProperty()];

coerce 'RepeatedKeyValueMetadataProperty',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::KeyValueMetadataProperty'->new($_) } @$_ ] };

declare 'MapStringKeyValueMetadataProperty',
    as HashRef[KeyValueMetadataProperty()];

declare 'FileLabel',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::FileLabel'];

coerce 'FileLabel',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::FileLabel'->new($_) };

declare 'RepeatedFileLabel',
    as ArrayRef[FileLabel()];

coerce 'RepeatedFileLabel',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::FileLabel'->new($_) } @$_ ] };

declare 'MapStringFileLabel',
    as HashRef[FileLabel()];

declare 'SensitivityLabelMetadata',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::FileLabel::SensitivityLabelMetadata'];

coerce 'SensitivityLabelMetadata',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::FileLabel::SensitivityLabelMetadata'->new($_) };

declare 'RepeatedSensitivityLabelMetadata',
    as ArrayRef[SensitivityLabelMetadata()];

coerce 'RepeatedSensitivityLabelMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::FileLabel::SensitivityLabelMetadata'->new($_) } @$_ ] };

declare 'MapStringSensitivityLabelMetadata',
    as HashRef[SensitivityLabelMetadata()];

declare 'GoogleDriveLabelMetadata',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::FileLabel::GoogleDriveLabelMetadata'];

coerce 'GoogleDriveLabelMetadata',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::FileLabel::GoogleDriveLabelMetadata'->new($_) };

declare 'RepeatedGoogleDriveLabelMetadata',
    as ArrayRef[GoogleDriveLabelMetadata()];

coerce 'RepeatedGoogleDriveLabelMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::FileLabel::GoogleDriveLabelMetadata'->new($_) } @$_ ] };

declare 'MapStringGoogleDriveLabelMetadata',
    as HashRef[GoogleDriveLabelMetadata()];

declare 'LabelFieldMetadata',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::FileLabel::GoogleDriveLabelMetadata::LabelFieldMetadata'];

coerce 'LabelFieldMetadata',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::FileLabel::GoogleDriveLabelMetadata::LabelFieldMetadata'->new($_) };

declare 'RepeatedLabelFieldMetadata',
    as ArrayRef[LabelFieldMetadata()];

coerce 'RepeatedLabelFieldMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::FileLabel::GoogleDriveLabelMetadata::LabelFieldMetadata'->new($_) } @$_ ] };

declare 'MapStringLabelFieldMetadata',
    as HashRef[LabelFieldMetadata()];

declare 'InspectResult',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::InspectResult'];

coerce 'InspectResult',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::InspectResult'->new($_) };

declare 'RepeatedInspectResult',
    as ArrayRef[InspectResult()];

coerce 'RepeatedInspectResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::InspectResult'->new($_) } @$_ ] };

declare 'MapStringInspectResult',
    as HashRef[InspectResult()];

declare 'Finding',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::Finding'];

coerce 'Finding',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::Finding'->new($_) };

declare 'RepeatedFinding',
    as ArrayRef[Finding()];

coerce 'RepeatedFinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::Finding'->new($_) } @$_ ] };

declare 'MapStringFinding',
    as HashRef[Finding()];

declare 'LabelsEntry',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::Finding::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::Finding::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::Finding::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Location',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::Location'];

coerce 'Location',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::Location'->new($_) };

declare 'RepeatedLocation',
    as ArrayRef[Location()];

coerce 'RepeatedLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::Location'->new($_) } @$_ ] };

declare 'MapStringLocation',
    as HashRef[Location()];

declare 'ContentLocation',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ContentLocation'];

coerce 'ContentLocation',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ContentLocation'->new($_) };

declare 'RepeatedContentLocation',
    as ArrayRef[ContentLocation()];

coerce 'RepeatedContentLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ContentLocation'->new($_) } @$_ ] };

declare 'MapStringContentLocation',
    as HashRef[ContentLocation()];

declare 'ConversationLocation',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ConversationLocation'];

coerce 'ConversationLocation',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ConversationLocation'->new($_) };

declare 'RepeatedConversationLocation',
    as ArrayRef[ConversationLocation()];

coerce 'RepeatedConversationLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ConversationLocation'->new($_) } @$_ ] };

declare 'MapStringConversationLocation',
    as HashRef[ConversationLocation()];

declare 'AllMessages',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ConversationLocation::AllMessages'];

coerce 'AllMessages',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ConversationLocation::AllMessages'->new($_) };

declare 'RepeatedAllMessages',
    as ArrayRef[AllMessages()];

coerce 'RepeatedAllMessages',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ConversationLocation::AllMessages'->new($_) } @$_ ] };

declare 'MapStringAllMessages',
    as HashRef[AllMessages()];

declare 'BatchContentLocation',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::BatchContentLocation'];

coerce 'BatchContentLocation',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::BatchContentLocation'->new($_) };

declare 'RepeatedBatchContentLocation',
    as ArrayRef[BatchContentLocation()];

coerce 'RepeatedBatchContentLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::BatchContentLocation'->new($_) } @$_ ] };

declare 'MapStringBatchContentLocation',
    as HashRef[BatchContentLocation()];

declare 'MetadataLocation',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::MetadataLocation'];

coerce 'MetadataLocation',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::MetadataLocation'->new($_) };

declare 'RepeatedMetadataLocation',
    as ArrayRef[MetadataLocation()];

coerce 'RepeatedMetadataLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::MetadataLocation'->new($_) } @$_ ] };

declare 'MapStringMetadataLocation',
    as HashRef[MetadataLocation()];

declare 'StorageMetadataLabel',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::StorageMetadataLabel'];

coerce 'StorageMetadataLabel',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::StorageMetadataLabel'->new($_) };

declare 'RepeatedStorageMetadataLabel',
    as ArrayRef[StorageMetadataLabel()];

coerce 'RepeatedStorageMetadataLabel',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::StorageMetadataLabel'->new($_) } @$_ ] };

declare 'MapStringStorageMetadataLabel',
    as HashRef[StorageMetadataLabel()];

declare 'KeyValueMetadataLabel',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::KeyValueMetadataLabel'];

coerce 'KeyValueMetadataLabel',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::KeyValueMetadataLabel'->new($_) };

declare 'RepeatedKeyValueMetadataLabel',
    as ArrayRef[KeyValueMetadataLabel()];

coerce 'RepeatedKeyValueMetadataLabel',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::KeyValueMetadataLabel'->new($_) } @$_ ] };

declare 'MapStringKeyValueMetadataLabel',
    as HashRef[KeyValueMetadataLabel()];

declare 'DocumentLocation',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DocumentLocation'];

coerce 'DocumentLocation',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DocumentLocation'->new($_) };

declare 'RepeatedDocumentLocation',
    as ArrayRef[DocumentLocation()];

coerce 'RepeatedDocumentLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DocumentLocation'->new($_) } @$_ ] };

declare 'MapStringDocumentLocation',
    as HashRef[DocumentLocation()];

declare 'RecordLocation',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::RecordLocation'];

coerce 'RecordLocation',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::RecordLocation'->new($_) };

declare 'RepeatedRecordLocation',
    as ArrayRef[RecordLocation()];

coerce 'RepeatedRecordLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::RecordLocation'->new($_) } @$_ ] };

declare 'MapStringRecordLocation',
    as HashRef[RecordLocation()];

declare 'TableLocation',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::TableLocation'];

coerce 'TableLocation',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::TableLocation'->new($_) };

declare 'RepeatedTableLocation',
    as ArrayRef[TableLocation()];

coerce 'RepeatedTableLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::TableLocation'->new($_) } @$_ ] };

declare 'MapStringTableLocation',
    as HashRef[TableLocation()];

declare 'Container',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::Container'];

coerce 'Container',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::Container'->new($_) };

declare 'RepeatedContainer',
    as ArrayRef[Container()];

coerce 'RepeatedContainer',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::Container'->new($_) } @$_ ] };

declare 'MapStringContainer',
    as HashRef[Container()];

declare 'Range',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::Range'];

coerce 'Range',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::Range'->new($_) };

declare 'RepeatedRange',
    as ArrayRef[Range()];

coerce 'RepeatedRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::Range'->new($_) } @$_ ] };

declare 'MapStringRange',
    as HashRef[Range()];

declare 'ImageLocation',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ImageLocation'];

coerce 'ImageLocation',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ImageLocation'->new($_) };

declare 'RepeatedImageLocation',
    as ArrayRef[ImageLocation()];

coerce 'RepeatedImageLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ImageLocation'->new($_) } @$_ ] };

declare 'MapStringImageLocation',
    as HashRef[ImageLocation()];

declare 'BoundingBox',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::BoundingBox'];

coerce 'BoundingBox',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::BoundingBox'->new($_) };

declare 'RepeatedBoundingBox',
    as ArrayRef[BoundingBox()];

coerce 'RepeatedBoundingBox',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::BoundingBox'->new($_) } @$_ ] };

declare 'MapStringBoundingBox',
    as HashRef[BoundingBox()];

declare 'RedactImageRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::RedactImageRequest'];

coerce 'RedactImageRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::RedactImageRequest'->new($_) };

declare 'RepeatedRedactImageRequest',
    as ArrayRef[RedactImageRequest()];

coerce 'RepeatedRedactImageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::RedactImageRequest'->new($_) } @$_ ] };

declare 'MapStringRedactImageRequest',
    as HashRef[RedactImageRequest()];

declare 'ImageRedactionConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::RedactImageRequest::ImageRedactionConfig'];

coerce 'ImageRedactionConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::RedactImageRequest::ImageRedactionConfig'->new($_) };

declare 'RepeatedImageRedactionConfig',
    as ArrayRef[ImageRedactionConfig()];

coerce 'RepeatedImageRedactionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::RedactImageRequest::ImageRedactionConfig'->new($_) } @$_ ] };

declare 'MapStringImageRedactionConfig',
    as HashRef[ImageRedactionConfig()];

declare 'Color',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::Color'];

coerce 'Color',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::Color'->new($_) };

declare 'RepeatedColor',
    as ArrayRef[Color()];

coerce 'RepeatedColor',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::Color'->new($_) } @$_ ] };

declare 'MapStringColor',
    as HashRef[Color()];

declare 'RedactImageResponse',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::RedactImageResponse'];

coerce 'RedactImageResponse',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::RedactImageResponse'->new($_) };

declare 'RepeatedRedactImageResponse',
    as ArrayRef[RedactImageResponse()];

coerce 'RepeatedRedactImageResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::RedactImageResponse'->new($_) } @$_ ] };

declare 'MapStringRedactImageResponse',
    as HashRef[RedactImageResponse()];

declare 'DeidentifyContentRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DeidentifyContentRequest'];

coerce 'DeidentifyContentRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DeidentifyContentRequest'->new($_) };

declare 'RepeatedDeidentifyContentRequest',
    as ArrayRef[DeidentifyContentRequest()];

coerce 'RepeatedDeidentifyContentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DeidentifyContentRequest'->new($_) } @$_ ] };

declare 'MapStringDeidentifyContentRequest',
    as HashRef[DeidentifyContentRequest()];

declare 'DeidentifyContentResponse',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DeidentifyContentResponse'];

coerce 'DeidentifyContentResponse',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DeidentifyContentResponse'->new($_) };

declare 'RepeatedDeidentifyContentResponse',
    as ArrayRef[DeidentifyContentResponse()];

coerce 'RepeatedDeidentifyContentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DeidentifyContentResponse'->new($_) } @$_ ] };

declare 'MapStringDeidentifyContentResponse',
    as HashRef[DeidentifyContentResponse()];

declare 'ReidentifyContentRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ReidentifyContentRequest'];

coerce 'ReidentifyContentRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ReidentifyContentRequest'->new($_) };

declare 'RepeatedReidentifyContentRequest',
    as ArrayRef[ReidentifyContentRequest()];

coerce 'RepeatedReidentifyContentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ReidentifyContentRequest'->new($_) } @$_ ] };

declare 'MapStringReidentifyContentRequest',
    as HashRef[ReidentifyContentRequest()];

declare 'ReidentifyContentResponse',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ReidentifyContentResponse'];

coerce 'ReidentifyContentResponse',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ReidentifyContentResponse'->new($_) };

declare 'RepeatedReidentifyContentResponse',
    as ArrayRef[ReidentifyContentResponse()];

coerce 'RepeatedReidentifyContentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ReidentifyContentResponse'->new($_) } @$_ ] };

declare 'MapStringReidentifyContentResponse',
    as HashRef[ReidentifyContentResponse()];

declare 'InspectContentRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::InspectContentRequest'];

coerce 'InspectContentRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::InspectContentRequest'->new($_) };

declare 'RepeatedInspectContentRequest',
    as ArrayRef[InspectContentRequest()];

coerce 'RepeatedInspectContentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::InspectContentRequest'->new($_) } @$_ ] };

declare 'MapStringInspectContentRequest',
    as HashRef[InspectContentRequest()];

declare 'InspectContentResponse',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::InspectContentResponse'];

coerce 'InspectContentResponse',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::InspectContentResponse'->new($_) };

declare 'RepeatedInspectContentResponse',
    as ArrayRef[InspectContentResponse()];

coerce 'RepeatedInspectContentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::InspectContentResponse'->new($_) } @$_ ] };

declare 'MapStringInspectContentResponse',
    as HashRef[InspectContentResponse()];

declare 'OutputStorageConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::OutputStorageConfig'];

coerce 'OutputStorageConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::OutputStorageConfig'->new($_) };

declare 'RepeatedOutputStorageConfig',
    as ArrayRef[OutputStorageConfig()];

coerce 'RepeatedOutputStorageConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::OutputStorageConfig'->new($_) } @$_ ] };

declare 'MapStringOutputStorageConfig',
    as HashRef[OutputStorageConfig()];

declare 'OutputSchema',
    as (Int | Str);

declare 'InfoTypeStats',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::InfoTypeStats'];

coerce 'InfoTypeStats',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::InfoTypeStats'->new($_) };

declare 'RepeatedInfoTypeStats',
    as ArrayRef[InfoTypeStats()];

coerce 'RepeatedInfoTypeStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::InfoTypeStats'->new($_) } @$_ ] };

declare 'MapStringInfoTypeStats',
    as HashRef[InfoTypeStats()];

declare 'InspectDataSourceDetails',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::InspectDataSourceDetails'];

coerce 'InspectDataSourceDetails',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::InspectDataSourceDetails'->new($_) };

declare 'RepeatedInspectDataSourceDetails',
    as ArrayRef[InspectDataSourceDetails()];

coerce 'RepeatedInspectDataSourceDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::InspectDataSourceDetails'->new($_) } @$_ ] };

declare 'MapStringInspectDataSourceDetails',
    as HashRef[InspectDataSourceDetails()];

declare 'RequestedOptions',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::InspectDataSourceDetails::RequestedOptions'];

coerce 'RequestedOptions',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::InspectDataSourceDetails::RequestedOptions'->new($_) };

declare 'RepeatedRequestedOptions',
    as ArrayRef[RequestedOptions()];

coerce 'RepeatedRequestedOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::InspectDataSourceDetails::RequestedOptions'->new($_) } @$_ ] };

declare 'MapStringRequestedOptions',
    as HashRef[RequestedOptions()];

declare 'Result',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::InspectDataSourceDetails::Result'];

coerce 'Result',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::InspectDataSourceDetails::Result'->new($_) };

declare 'RepeatedResult',
    as ArrayRef[Result()];

coerce 'RepeatedResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::InspectDataSourceDetails::Result'->new($_) } @$_ ] };

declare 'MapStringResult',
    as HashRef[Result()];

declare 'DataProfileBigQueryRowSchema',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DataProfileBigQueryRowSchema'];

coerce 'DataProfileBigQueryRowSchema',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DataProfileBigQueryRowSchema'->new($_) };

declare 'RepeatedDataProfileBigQueryRowSchema',
    as ArrayRef[DataProfileBigQueryRowSchema()];

coerce 'RepeatedDataProfileBigQueryRowSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DataProfileBigQueryRowSchema'->new($_) } @$_ ] };

declare 'MapStringDataProfileBigQueryRowSchema',
    as HashRef[DataProfileBigQueryRowSchema()];

declare 'HybridInspectStatistics',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::HybridInspectStatistics'];

coerce 'HybridInspectStatistics',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::HybridInspectStatistics'->new($_) };

declare 'RepeatedHybridInspectStatistics',
    as ArrayRef[HybridInspectStatistics()];

coerce 'RepeatedHybridInspectStatistics',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::HybridInspectStatistics'->new($_) } @$_ ] };

declare 'MapStringHybridInspectStatistics',
    as HashRef[HybridInspectStatistics()];

declare 'ActionDetails',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ActionDetails'];

coerce 'ActionDetails',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ActionDetails'->new($_) };

declare 'RepeatedActionDetails',
    as ArrayRef[ActionDetails()];

coerce 'RepeatedActionDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ActionDetails'->new($_) } @$_ ] };

declare 'MapStringActionDetails',
    as HashRef[ActionDetails()];

declare 'DeidentifyDataSourceStats',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DeidentifyDataSourceStats'];

coerce 'DeidentifyDataSourceStats',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DeidentifyDataSourceStats'->new($_) };

declare 'RepeatedDeidentifyDataSourceStats',
    as ArrayRef[DeidentifyDataSourceStats()];

coerce 'RepeatedDeidentifyDataSourceStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DeidentifyDataSourceStats'->new($_) } @$_ ] };

declare 'MapStringDeidentifyDataSourceStats',
    as HashRef[DeidentifyDataSourceStats()];

declare 'DeidentifyDataSourceDetails',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DeidentifyDataSourceDetails'];

coerce 'DeidentifyDataSourceDetails',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DeidentifyDataSourceDetails'->new($_) };

declare 'RepeatedDeidentifyDataSourceDetails',
    as ArrayRef[DeidentifyDataSourceDetails()];

coerce 'RepeatedDeidentifyDataSourceDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DeidentifyDataSourceDetails'->new($_) } @$_ ] };

declare 'MapStringDeidentifyDataSourceDetails',
    as HashRef[DeidentifyDataSourceDetails()];

declare 'RequestedDeidentifyOptions',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DeidentifyDataSourceDetails::RequestedDeidentifyOptions'];

coerce 'RequestedDeidentifyOptions',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DeidentifyDataSourceDetails::RequestedDeidentifyOptions'->new($_) };

declare 'RepeatedRequestedDeidentifyOptions',
    as ArrayRef[RequestedDeidentifyOptions()];

coerce 'RepeatedRequestedDeidentifyOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DeidentifyDataSourceDetails::RequestedDeidentifyOptions'->new($_) } @$_ ] };

declare 'MapStringRequestedDeidentifyOptions',
    as HashRef[RequestedDeidentifyOptions()];

declare 'LocationSupport',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::LocationSupport'];

coerce 'LocationSupport',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::LocationSupport'->new($_) };

declare 'RepeatedLocationSupport',
    as ArrayRef[LocationSupport()];

coerce 'RepeatedLocationSupport',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::LocationSupport'->new($_) } @$_ ] };

declare 'MapStringLocationSupport',
    as HashRef[LocationSupport()];

declare 'RegionalizationScope',
    as (Int | Str);

declare 'InfoTypeDescription',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::InfoTypeDescription'];

coerce 'InfoTypeDescription',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::InfoTypeDescription'->new($_) };

declare 'RepeatedInfoTypeDescription',
    as ArrayRef[InfoTypeDescription()];

coerce 'RepeatedInfoTypeDescription',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::InfoTypeDescription'->new($_) } @$_ ] };

declare 'MapStringInfoTypeDescription',
    as HashRef[InfoTypeDescription()];

declare 'InfoTypeLaunchStatus',
    as (Int | Str);

declare 'InfoTypeCategory',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::InfoTypeCategory'];

coerce 'InfoTypeCategory',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::InfoTypeCategory'->new($_) };

declare 'RepeatedInfoTypeCategory',
    as ArrayRef[InfoTypeCategory()];

coerce 'RepeatedInfoTypeCategory',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::InfoTypeCategory'->new($_) } @$_ ] };

declare 'MapStringInfoTypeCategory',
    as HashRef[InfoTypeCategory()];

declare 'LocationCategory',
    as (Int | Str);

declare 'IndustryCategory',
    as (Int | Str);

declare 'TypeCategory',
    as (Int | Str);

declare 'VersionDescription',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::VersionDescription'];

coerce 'VersionDescription',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::VersionDescription'->new($_) };

declare 'RepeatedVersionDescription',
    as ArrayRef[VersionDescription()];

coerce 'RepeatedVersionDescription',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::VersionDescription'->new($_) } @$_ ] };

declare 'MapStringVersionDescription',
    as HashRef[VersionDescription()];

declare 'ListInfoTypesRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ListInfoTypesRequest'];

coerce 'ListInfoTypesRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ListInfoTypesRequest'->new($_) };

declare 'RepeatedListInfoTypesRequest',
    as ArrayRef[ListInfoTypesRequest()];

coerce 'RepeatedListInfoTypesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ListInfoTypesRequest'->new($_) } @$_ ] };

declare 'MapStringListInfoTypesRequest',
    as HashRef[ListInfoTypesRequest()];

declare 'ListInfoTypesResponse',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ListInfoTypesResponse'];

coerce 'ListInfoTypesResponse',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ListInfoTypesResponse'->new($_) };

declare 'RepeatedListInfoTypesResponse',
    as ArrayRef[ListInfoTypesResponse()];

coerce 'RepeatedListInfoTypesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ListInfoTypesResponse'->new($_) } @$_ ] };

declare 'MapStringListInfoTypesResponse',
    as HashRef[ListInfoTypesResponse()];

declare 'RiskAnalysisJobConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::RiskAnalysisJobConfig'];

coerce 'RiskAnalysisJobConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::RiskAnalysisJobConfig'->new($_) };

declare 'RepeatedRiskAnalysisJobConfig',
    as ArrayRef[RiskAnalysisJobConfig()];

coerce 'RepeatedRiskAnalysisJobConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::RiskAnalysisJobConfig'->new($_) } @$_ ] };

declare 'MapStringRiskAnalysisJobConfig',
    as HashRef[RiskAnalysisJobConfig()];

declare 'QuasiId',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::QuasiId'];

coerce 'QuasiId',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::QuasiId'->new($_) };

declare 'RepeatedQuasiId',
    as ArrayRef[QuasiId()];

coerce 'RepeatedQuasiId',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::QuasiId'->new($_) } @$_ ] };

declare 'MapStringQuasiId',
    as HashRef[QuasiId()];

declare 'StatisticalTable',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::StatisticalTable'];

coerce 'StatisticalTable',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::StatisticalTable'->new($_) };

declare 'RepeatedStatisticalTable',
    as ArrayRef[StatisticalTable()];

coerce 'RepeatedStatisticalTable',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::StatisticalTable'->new($_) } @$_ ] };

declare 'MapStringStatisticalTable',
    as HashRef[StatisticalTable()];

declare 'QuasiIdentifierField',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::StatisticalTable::QuasiIdentifierField'];

coerce 'QuasiIdentifierField',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::StatisticalTable::QuasiIdentifierField'->new($_) };

declare 'RepeatedQuasiIdentifierField',
    as ArrayRef[QuasiIdentifierField()];

coerce 'RepeatedQuasiIdentifierField',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::StatisticalTable::QuasiIdentifierField'->new($_) } @$_ ] };

declare 'MapStringQuasiIdentifierField',
    as HashRef[QuasiIdentifierField()];

declare 'PrivacyMetric',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::PrivacyMetric'];

coerce 'PrivacyMetric',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::PrivacyMetric'->new($_) };

declare 'RepeatedPrivacyMetric',
    as ArrayRef[PrivacyMetric()];

coerce 'RepeatedPrivacyMetric',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::PrivacyMetric'->new($_) } @$_ ] };

declare 'MapStringPrivacyMetric',
    as HashRef[PrivacyMetric()];

declare 'NumericalStatsConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::PrivacyMetric::NumericalStatsConfig'];

coerce 'NumericalStatsConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::PrivacyMetric::NumericalStatsConfig'->new($_) };

declare 'RepeatedNumericalStatsConfig',
    as ArrayRef[NumericalStatsConfig()];

coerce 'RepeatedNumericalStatsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::PrivacyMetric::NumericalStatsConfig'->new($_) } @$_ ] };

declare 'MapStringNumericalStatsConfig',
    as HashRef[NumericalStatsConfig()];

declare 'CategoricalStatsConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::PrivacyMetric::CategoricalStatsConfig'];

coerce 'CategoricalStatsConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::PrivacyMetric::CategoricalStatsConfig'->new($_) };

declare 'RepeatedCategoricalStatsConfig',
    as ArrayRef[CategoricalStatsConfig()];

coerce 'RepeatedCategoricalStatsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::PrivacyMetric::CategoricalStatsConfig'->new($_) } @$_ ] };

declare 'MapStringCategoricalStatsConfig',
    as HashRef[CategoricalStatsConfig()];

declare 'KAnonymityConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::PrivacyMetric::KAnonymityConfig'];

coerce 'KAnonymityConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::PrivacyMetric::KAnonymityConfig'->new($_) };

declare 'RepeatedKAnonymityConfig',
    as ArrayRef[KAnonymityConfig()];

coerce 'RepeatedKAnonymityConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::PrivacyMetric::KAnonymityConfig'->new($_) } @$_ ] };

declare 'MapStringKAnonymityConfig',
    as HashRef[KAnonymityConfig()];

declare 'LDiversityConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::PrivacyMetric::LDiversityConfig'];

coerce 'LDiversityConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::PrivacyMetric::LDiversityConfig'->new($_) };

declare 'RepeatedLDiversityConfig',
    as ArrayRef[LDiversityConfig()];

coerce 'RepeatedLDiversityConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::PrivacyMetric::LDiversityConfig'->new($_) } @$_ ] };

declare 'MapStringLDiversityConfig',
    as HashRef[LDiversityConfig()];

declare 'KMapEstimationConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::PrivacyMetric::KMapEstimationConfig'];

coerce 'KMapEstimationConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::PrivacyMetric::KMapEstimationConfig'->new($_) };

declare 'RepeatedKMapEstimationConfig',
    as ArrayRef[KMapEstimationConfig()];

coerce 'RepeatedKMapEstimationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::PrivacyMetric::KMapEstimationConfig'->new($_) } @$_ ] };

declare 'MapStringKMapEstimationConfig',
    as HashRef[KMapEstimationConfig()];

declare 'TaggedField',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::PrivacyMetric::KMapEstimationConfig::TaggedField'];

coerce 'TaggedField',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::PrivacyMetric::KMapEstimationConfig::TaggedField'->new($_) };

declare 'RepeatedTaggedField',
    as ArrayRef[TaggedField()];

coerce 'RepeatedTaggedField',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::PrivacyMetric::KMapEstimationConfig::TaggedField'->new($_) } @$_ ] };

declare 'MapStringTaggedField',
    as HashRef[TaggedField()];

declare 'AuxiliaryTable',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::PrivacyMetric::KMapEstimationConfig::AuxiliaryTable'];

coerce 'AuxiliaryTable',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::PrivacyMetric::KMapEstimationConfig::AuxiliaryTable'->new($_) };

declare 'RepeatedAuxiliaryTable',
    as ArrayRef[AuxiliaryTable()];

coerce 'RepeatedAuxiliaryTable',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::PrivacyMetric::KMapEstimationConfig::AuxiliaryTable'->new($_) } @$_ ] };

declare 'MapStringAuxiliaryTable',
    as HashRef[AuxiliaryTable()];

declare 'QuasiIdField',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::PrivacyMetric::KMapEstimationConfig::AuxiliaryTable::QuasiIdField'];

coerce 'QuasiIdField',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::PrivacyMetric::KMapEstimationConfig::AuxiliaryTable::QuasiIdField'->new($_) };

declare 'RepeatedQuasiIdField',
    as ArrayRef[QuasiIdField()];

coerce 'RepeatedQuasiIdField',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::PrivacyMetric::KMapEstimationConfig::AuxiliaryTable::QuasiIdField'->new($_) } @$_ ] };

declare 'MapStringQuasiIdField',
    as HashRef[QuasiIdField()];

declare 'DeltaPresenceEstimationConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::PrivacyMetric::DeltaPresenceEstimationConfig'];

coerce 'DeltaPresenceEstimationConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::PrivacyMetric::DeltaPresenceEstimationConfig'->new($_) };

declare 'RepeatedDeltaPresenceEstimationConfig',
    as ArrayRef[DeltaPresenceEstimationConfig()];

coerce 'RepeatedDeltaPresenceEstimationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::PrivacyMetric::DeltaPresenceEstimationConfig'->new($_) } @$_ ] };

declare 'MapStringDeltaPresenceEstimationConfig',
    as HashRef[DeltaPresenceEstimationConfig()];

declare 'AnalyzeDataSourceRiskDetails',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails'];

coerce 'AnalyzeDataSourceRiskDetails',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails'->new($_) };

declare 'RepeatedAnalyzeDataSourceRiskDetails',
    as ArrayRef[AnalyzeDataSourceRiskDetails()];

coerce 'RepeatedAnalyzeDataSourceRiskDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails'->new($_) } @$_ ] };

declare 'MapStringAnalyzeDataSourceRiskDetails',
    as HashRef[AnalyzeDataSourceRiskDetails()];

declare 'NumericalStatsResult',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::NumericalStatsResult'];

coerce 'NumericalStatsResult',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::NumericalStatsResult'->new($_) };

declare 'RepeatedNumericalStatsResult',
    as ArrayRef[NumericalStatsResult()];

coerce 'RepeatedNumericalStatsResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::NumericalStatsResult'->new($_) } @$_ ] };

declare 'MapStringNumericalStatsResult',
    as HashRef[NumericalStatsResult()];

declare 'CategoricalStatsResult',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::CategoricalStatsResult'];

coerce 'CategoricalStatsResult',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::CategoricalStatsResult'->new($_) };

declare 'RepeatedCategoricalStatsResult',
    as ArrayRef[CategoricalStatsResult()];

coerce 'RepeatedCategoricalStatsResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::CategoricalStatsResult'->new($_) } @$_ ] };

declare 'MapStringCategoricalStatsResult',
    as HashRef[CategoricalStatsResult()];

declare 'CategoricalStatsHistogramBucket',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::CategoricalStatsResult::CategoricalStatsHistogramBucket'];

coerce 'CategoricalStatsHistogramBucket',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::CategoricalStatsResult::CategoricalStatsHistogramBucket'->new($_) };

declare 'RepeatedCategoricalStatsHistogramBucket',
    as ArrayRef[CategoricalStatsHistogramBucket()];

coerce 'RepeatedCategoricalStatsHistogramBucket',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::CategoricalStatsResult::CategoricalStatsHistogramBucket'->new($_) } @$_ ] };

declare 'MapStringCategoricalStatsHistogramBucket',
    as HashRef[CategoricalStatsHistogramBucket()];

declare 'KAnonymityResult',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::KAnonymityResult'];

coerce 'KAnonymityResult',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::KAnonymityResult'->new($_) };

declare 'RepeatedKAnonymityResult',
    as ArrayRef[KAnonymityResult()];

coerce 'RepeatedKAnonymityResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::KAnonymityResult'->new($_) } @$_ ] };

declare 'MapStringKAnonymityResult',
    as HashRef[KAnonymityResult()];

declare 'KAnonymityEquivalenceClass',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::KAnonymityResult::KAnonymityEquivalenceClass'];

coerce 'KAnonymityEquivalenceClass',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::KAnonymityResult::KAnonymityEquivalenceClass'->new($_) };

declare 'RepeatedKAnonymityEquivalenceClass',
    as ArrayRef[KAnonymityEquivalenceClass()];

coerce 'RepeatedKAnonymityEquivalenceClass',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::KAnonymityResult::KAnonymityEquivalenceClass'->new($_) } @$_ ] };

declare 'MapStringKAnonymityEquivalenceClass',
    as HashRef[KAnonymityEquivalenceClass()];

declare 'KAnonymityHistogramBucket',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::KAnonymityResult::KAnonymityHistogramBucket'];

coerce 'KAnonymityHistogramBucket',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::KAnonymityResult::KAnonymityHistogramBucket'->new($_) };

declare 'RepeatedKAnonymityHistogramBucket',
    as ArrayRef[KAnonymityHistogramBucket()];

coerce 'RepeatedKAnonymityHistogramBucket',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::KAnonymityResult::KAnonymityHistogramBucket'->new($_) } @$_ ] };

declare 'MapStringKAnonymityHistogramBucket',
    as HashRef[KAnonymityHistogramBucket()];

declare 'LDiversityResult',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::LDiversityResult'];

coerce 'LDiversityResult',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::LDiversityResult'->new($_) };

declare 'RepeatedLDiversityResult',
    as ArrayRef[LDiversityResult()];

coerce 'RepeatedLDiversityResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::LDiversityResult'->new($_) } @$_ ] };

declare 'MapStringLDiversityResult',
    as HashRef[LDiversityResult()];

declare 'LDiversityEquivalenceClass',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::LDiversityResult::LDiversityEquivalenceClass'];

coerce 'LDiversityEquivalenceClass',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::LDiversityResult::LDiversityEquivalenceClass'->new($_) };

declare 'RepeatedLDiversityEquivalenceClass',
    as ArrayRef[LDiversityEquivalenceClass()];

coerce 'RepeatedLDiversityEquivalenceClass',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::LDiversityResult::LDiversityEquivalenceClass'->new($_) } @$_ ] };

declare 'MapStringLDiversityEquivalenceClass',
    as HashRef[LDiversityEquivalenceClass()];

declare 'LDiversityHistogramBucket',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::LDiversityResult::LDiversityHistogramBucket'];

coerce 'LDiversityHistogramBucket',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::LDiversityResult::LDiversityHistogramBucket'->new($_) };

declare 'RepeatedLDiversityHistogramBucket',
    as ArrayRef[LDiversityHistogramBucket()];

coerce 'RepeatedLDiversityHistogramBucket',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::LDiversityResult::LDiversityHistogramBucket'->new($_) } @$_ ] };

declare 'MapStringLDiversityHistogramBucket',
    as HashRef[LDiversityHistogramBucket()];

declare 'KMapEstimationResult',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::KMapEstimationResult'];

coerce 'KMapEstimationResult',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::KMapEstimationResult'->new($_) };

declare 'RepeatedKMapEstimationResult',
    as ArrayRef[KMapEstimationResult()];

coerce 'RepeatedKMapEstimationResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::KMapEstimationResult'->new($_) } @$_ ] };

declare 'MapStringKMapEstimationResult',
    as HashRef[KMapEstimationResult()];

declare 'KMapEstimationQuasiIdValues',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::KMapEstimationResult::KMapEstimationQuasiIdValues'];

coerce 'KMapEstimationQuasiIdValues',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::KMapEstimationResult::KMapEstimationQuasiIdValues'->new($_) };

declare 'RepeatedKMapEstimationQuasiIdValues',
    as ArrayRef[KMapEstimationQuasiIdValues()];

coerce 'RepeatedKMapEstimationQuasiIdValues',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::KMapEstimationResult::KMapEstimationQuasiIdValues'->new($_) } @$_ ] };

declare 'MapStringKMapEstimationQuasiIdValues',
    as HashRef[KMapEstimationQuasiIdValues()];

declare 'KMapEstimationHistogramBucket',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::KMapEstimationResult::KMapEstimationHistogramBucket'];

coerce 'KMapEstimationHistogramBucket',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::KMapEstimationResult::KMapEstimationHistogramBucket'->new($_) };

declare 'RepeatedKMapEstimationHistogramBucket',
    as ArrayRef[KMapEstimationHistogramBucket()];

coerce 'RepeatedKMapEstimationHistogramBucket',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::KMapEstimationResult::KMapEstimationHistogramBucket'->new($_) } @$_ ] };

declare 'MapStringKMapEstimationHistogramBucket',
    as HashRef[KMapEstimationHistogramBucket()];

declare 'DeltaPresenceEstimationResult',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::DeltaPresenceEstimationResult'];

coerce 'DeltaPresenceEstimationResult',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::DeltaPresenceEstimationResult'->new($_) };

declare 'RepeatedDeltaPresenceEstimationResult',
    as ArrayRef[DeltaPresenceEstimationResult()];

coerce 'RepeatedDeltaPresenceEstimationResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::DeltaPresenceEstimationResult'->new($_) } @$_ ] };

declare 'MapStringDeltaPresenceEstimationResult',
    as HashRef[DeltaPresenceEstimationResult()];

declare 'DeltaPresenceEstimationQuasiIdValues',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::DeltaPresenceEstimationResult::DeltaPresenceEstimationQuasiIdValues'];

coerce 'DeltaPresenceEstimationQuasiIdValues',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::DeltaPresenceEstimationResult::DeltaPresenceEstimationQuasiIdValues'->new($_) };

declare 'RepeatedDeltaPresenceEstimationQuasiIdValues',
    as ArrayRef[DeltaPresenceEstimationQuasiIdValues()];

coerce 'RepeatedDeltaPresenceEstimationQuasiIdValues',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::DeltaPresenceEstimationResult::DeltaPresenceEstimationQuasiIdValues'->new($_) } @$_ ] };

declare 'MapStringDeltaPresenceEstimationQuasiIdValues',
    as HashRef[DeltaPresenceEstimationQuasiIdValues()];

declare 'DeltaPresenceEstimationHistogramBucket',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::DeltaPresenceEstimationResult::DeltaPresenceEstimationHistogramBucket'];

coerce 'DeltaPresenceEstimationHistogramBucket',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::DeltaPresenceEstimationResult::DeltaPresenceEstimationHistogramBucket'->new($_) };

declare 'RepeatedDeltaPresenceEstimationHistogramBucket',
    as ArrayRef[DeltaPresenceEstimationHistogramBucket()];

coerce 'RepeatedDeltaPresenceEstimationHistogramBucket',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::DeltaPresenceEstimationResult::DeltaPresenceEstimationHistogramBucket'->new($_) } @$_ ] };

declare 'MapStringDeltaPresenceEstimationHistogramBucket',
    as HashRef[DeltaPresenceEstimationHistogramBucket()];

declare 'RequestedRiskAnalysisOptions',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::RequestedRiskAnalysisOptions'];

coerce 'RequestedRiskAnalysisOptions',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::RequestedRiskAnalysisOptions'->new($_) };

declare 'RepeatedRequestedRiskAnalysisOptions',
    as ArrayRef[RequestedRiskAnalysisOptions()];

coerce 'RepeatedRequestedRiskAnalysisOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::AnalyzeDataSourceRiskDetails::RequestedRiskAnalysisOptions'->new($_) } @$_ ] };

declare 'MapStringRequestedRiskAnalysisOptions',
    as HashRef[RequestedRiskAnalysisOptions()];

declare 'ValueFrequency',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ValueFrequency'];

coerce 'ValueFrequency',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ValueFrequency'->new($_) };

declare 'RepeatedValueFrequency',
    as ArrayRef[ValueFrequency()];

coerce 'RepeatedValueFrequency',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ValueFrequency'->new($_) } @$_ ] };

declare 'MapStringValueFrequency',
    as HashRef[ValueFrequency()];

declare 'Value',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::Value'];

coerce 'Value',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::Value'->new($_) };

declare 'RepeatedValue',
    as ArrayRef[Value()];

coerce 'RepeatedValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::Value'->new($_) } @$_ ] };

declare 'MapStringValue',
    as HashRef[Value()];

declare 'QuoteInfo',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::QuoteInfo'];

coerce 'QuoteInfo',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::QuoteInfo'->new($_) };

declare 'RepeatedQuoteInfo',
    as ArrayRef[QuoteInfo()];

coerce 'RepeatedQuoteInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::QuoteInfo'->new($_) } @$_ ] };

declare 'MapStringQuoteInfo',
    as HashRef[QuoteInfo()];

declare 'DateTime',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DateTime'];

coerce 'DateTime',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DateTime'->new($_) };

declare 'RepeatedDateTime',
    as ArrayRef[DateTime()];

coerce 'RepeatedDateTime',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DateTime'->new($_) } @$_ ] };

declare 'MapStringDateTime',
    as HashRef[DateTime()];

declare 'TimeZone',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DateTime::TimeZone'];

coerce 'TimeZone',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DateTime::TimeZone'->new($_) };

declare 'RepeatedTimeZone',
    as ArrayRef[TimeZone()];

coerce 'RepeatedTimeZone',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DateTime::TimeZone'->new($_) } @$_ ] };

declare 'MapStringTimeZone',
    as HashRef[TimeZone()];

declare 'DeidentifyConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DeidentifyConfig'];

coerce 'DeidentifyConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DeidentifyConfig'->new($_) };

declare 'RepeatedDeidentifyConfig',
    as ArrayRef[DeidentifyConfig()];

coerce 'RepeatedDeidentifyConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DeidentifyConfig'->new($_) } @$_ ] };

declare 'MapStringDeidentifyConfig',
    as HashRef[DeidentifyConfig()];

declare 'ImageTransformations',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ImageTransformations'];

coerce 'ImageTransformations',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ImageTransformations'->new($_) };

declare 'RepeatedImageTransformations',
    as ArrayRef[ImageTransformations()];

coerce 'RepeatedImageTransformations',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ImageTransformations'->new($_) } @$_ ] };

declare 'MapStringImageTransformations',
    as HashRef[ImageTransformations()];

declare 'ImageTransformation',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ImageTransformations::ImageTransformation'];

coerce 'ImageTransformation',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ImageTransformations::ImageTransformation'->new($_) };

declare 'RepeatedImageTransformation',
    as ArrayRef[ImageTransformation()];

coerce 'RepeatedImageTransformation',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ImageTransformations::ImageTransformation'->new($_) } @$_ ] };

declare 'MapStringImageTransformation',
    as HashRef[ImageTransformation()];

declare 'SelectedInfoTypes',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ImageTransformations::ImageTransformation::SelectedInfoTypes'];

coerce 'SelectedInfoTypes',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ImageTransformations::ImageTransformation::SelectedInfoTypes'->new($_) };

declare 'RepeatedSelectedInfoTypes',
    as ArrayRef[SelectedInfoTypes()];

coerce 'RepeatedSelectedInfoTypes',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ImageTransformations::ImageTransformation::SelectedInfoTypes'->new($_) } @$_ ] };

declare 'MapStringSelectedInfoTypes',
    as HashRef[SelectedInfoTypes()];

declare 'AllInfoTypes',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ImageTransformations::ImageTransformation::AllInfoTypes'];

coerce 'AllInfoTypes',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ImageTransformations::ImageTransformation::AllInfoTypes'->new($_) };

declare 'RepeatedAllInfoTypes',
    as ArrayRef[AllInfoTypes()];

coerce 'RepeatedAllInfoTypes',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ImageTransformations::ImageTransformation::AllInfoTypes'->new($_) } @$_ ] };

declare 'MapStringAllInfoTypes',
    as HashRef[AllInfoTypes()];

declare 'AllText',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ImageTransformations::ImageTransformation::AllText'];

coerce 'AllText',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ImageTransformations::ImageTransformation::AllText'->new($_) };

declare 'RepeatedAllText',
    as ArrayRef[AllText()];

coerce 'RepeatedAllText',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ImageTransformations::ImageTransformation::AllText'->new($_) } @$_ ] };

declare 'MapStringAllText',
    as HashRef[AllText()];

declare 'TransformationErrorHandling',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::TransformationErrorHandling'];

coerce 'TransformationErrorHandling',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::TransformationErrorHandling'->new($_) };

declare 'RepeatedTransformationErrorHandling',
    as ArrayRef[TransformationErrorHandling()];

coerce 'RepeatedTransformationErrorHandling',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::TransformationErrorHandling'->new($_) } @$_ ] };

declare 'MapStringTransformationErrorHandling',
    as HashRef[TransformationErrorHandling()];

declare 'ThrowError',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::TransformationErrorHandling::ThrowError'];

coerce 'ThrowError',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::TransformationErrorHandling::ThrowError'->new($_) };

declare 'RepeatedThrowError',
    as ArrayRef[ThrowError()];

coerce 'RepeatedThrowError',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::TransformationErrorHandling::ThrowError'->new($_) } @$_ ] };

declare 'MapStringThrowError',
    as HashRef[ThrowError()];

declare 'LeaveUntransformed',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::TransformationErrorHandling::LeaveUntransformed'];

coerce 'LeaveUntransformed',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::TransformationErrorHandling::LeaveUntransformed'->new($_) };

declare 'RepeatedLeaveUntransformed',
    as ArrayRef[LeaveUntransformed()];

coerce 'RepeatedLeaveUntransformed',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::TransformationErrorHandling::LeaveUntransformed'->new($_) } @$_ ] };

declare 'MapStringLeaveUntransformed',
    as HashRef[LeaveUntransformed()];

declare 'PrimitiveTransformation',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::PrimitiveTransformation'];

coerce 'PrimitiveTransformation',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::PrimitiveTransformation'->new($_) };

declare 'RepeatedPrimitiveTransformation',
    as ArrayRef[PrimitiveTransformation()];

coerce 'RepeatedPrimitiveTransformation',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::PrimitiveTransformation'->new($_) } @$_ ] };

declare 'MapStringPrimitiveTransformation',
    as HashRef[PrimitiveTransformation()];

declare 'TimePartConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::TimePartConfig'];

coerce 'TimePartConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::TimePartConfig'->new($_) };

declare 'RepeatedTimePartConfig',
    as ArrayRef[TimePartConfig()];

coerce 'RepeatedTimePartConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::TimePartConfig'->new($_) } @$_ ] };

declare 'MapStringTimePartConfig',
    as HashRef[TimePartConfig()];

declare 'TimePart',
    as (Int | Str);

declare 'CryptoHashConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::CryptoHashConfig'];

coerce 'CryptoHashConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::CryptoHashConfig'->new($_) };

declare 'RepeatedCryptoHashConfig',
    as ArrayRef[CryptoHashConfig()];

coerce 'RepeatedCryptoHashConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::CryptoHashConfig'->new($_) } @$_ ] };

declare 'MapStringCryptoHashConfig',
    as HashRef[CryptoHashConfig()];

declare 'CryptoDeterministicConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::CryptoDeterministicConfig'];

coerce 'CryptoDeterministicConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::CryptoDeterministicConfig'->new($_) };

declare 'RepeatedCryptoDeterministicConfig',
    as ArrayRef[CryptoDeterministicConfig()];

coerce 'RepeatedCryptoDeterministicConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::CryptoDeterministicConfig'->new($_) } @$_ ] };

declare 'MapStringCryptoDeterministicConfig',
    as HashRef[CryptoDeterministicConfig()];

declare 'ReplaceValueConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ReplaceValueConfig'];

coerce 'ReplaceValueConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ReplaceValueConfig'->new($_) };

declare 'RepeatedReplaceValueConfig',
    as ArrayRef[ReplaceValueConfig()];

coerce 'RepeatedReplaceValueConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ReplaceValueConfig'->new($_) } @$_ ] };

declare 'MapStringReplaceValueConfig',
    as HashRef[ReplaceValueConfig()];

declare 'ReplaceDictionaryConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ReplaceDictionaryConfig'];

coerce 'ReplaceDictionaryConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ReplaceDictionaryConfig'->new($_) };

declare 'RepeatedReplaceDictionaryConfig',
    as ArrayRef[ReplaceDictionaryConfig()];

coerce 'RepeatedReplaceDictionaryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ReplaceDictionaryConfig'->new($_) } @$_ ] };

declare 'MapStringReplaceDictionaryConfig',
    as HashRef[ReplaceDictionaryConfig()];

declare 'ReplaceWithInfoTypeConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ReplaceWithInfoTypeConfig'];

coerce 'ReplaceWithInfoTypeConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ReplaceWithInfoTypeConfig'->new($_) };

declare 'RepeatedReplaceWithInfoTypeConfig',
    as ArrayRef[ReplaceWithInfoTypeConfig()];

coerce 'RepeatedReplaceWithInfoTypeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ReplaceWithInfoTypeConfig'->new($_) } @$_ ] };

declare 'MapStringReplaceWithInfoTypeConfig',
    as HashRef[ReplaceWithInfoTypeConfig()];

declare 'RedactConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::RedactConfig'];

coerce 'RedactConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::RedactConfig'->new($_) };

declare 'RepeatedRedactConfig',
    as ArrayRef[RedactConfig()];

coerce 'RepeatedRedactConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::RedactConfig'->new($_) } @$_ ] };

declare 'MapStringRedactConfig',
    as HashRef[RedactConfig()];

declare 'CharsToIgnore',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::CharsToIgnore'];

coerce 'CharsToIgnore',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::CharsToIgnore'->new($_) };

declare 'RepeatedCharsToIgnore',
    as ArrayRef[CharsToIgnore()];

coerce 'RepeatedCharsToIgnore',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::CharsToIgnore'->new($_) } @$_ ] };

declare 'MapStringCharsToIgnore',
    as HashRef[CharsToIgnore()];

declare 'CommonCharsToIgnore',
    as (Int | Str);

declare 'CharacterMaskConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::CharacterMaskConfig'];

coerce 'CharacterMaskConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::CharacterMaskConfig'->new($_) };

declare 'RepeatedCharacterMaskConfig',
    as ArrayRef[CharacterMaskConfig()];

coerce 'RepeatedCharacterMaskConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::CharacterMaskConfig'->new($_) } @$_ ] };

declare 'MapStringCharacterMaskConfig',
    as HashRef[CharacterMaskConfig()];

declare 'FixedSizeBucketingConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::FixedSizeBucketingConfig'];

coerce 'FixedSizeBucketingConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::FixedSizeBucketingConfig'->new($_) };

declare 'RepeatedFixedSizeBucketingConfig',
    as ArrayRef[FixedSizeBucketingConfig()];

coerce 'RepeatedFixedSizeBucketingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::FixedSizeBucketingConfig'->new($_) } @$_ ] };

declare 'MapStringFixedSizeBucketingConfig',
    as HashRef[FixedSizeBucketingConfig()];

declare 'BucketingConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::BucketingConfig'];

coerce 'BucketingConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::BucketingConfig'->new($_) };

declare 'RepeatedBucketingConfig',
    as ArrayRef[BucketingConfig()];

coerce 'RepeatedBucketingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::BucketingConfig'->new($_) } @$_ ] };

declare 'MapStringBucketingConfig',
    as HashRef[BucketingConfig()];

declare 'Bucket',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::BucketingConfig::Bucket'];

coerce 'Bucket',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::BucketingConfig::Bucket'->new($_) };

declare 'RepeatedBucket',
    as ArrayRef[Bucket()];

coerce 'RepeatedBucket',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::BucketingConfig::Bucket'->new($_) } @$_ ] };

declare 'MapStringBucket',
    as HashRef[Bucket()];

declare 'CryptoReplaceFfxFpeConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::CryptoReplaceFfxFpeConfig'];

coerce 'CryptoReplaceFfxFpeConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::CryptoReplaceFfxFpeConfig'->new($_) };

declare 'RepeatedCryptoReplaceFfxFpeConfig',
    as ArrayRef[CryptoReplaceFfxFpeConfig()];

coerce 'RepeatedCryptoReplaceFfxFpeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::CryptoReplaceFfxFpeConfig'->new($_) } @$_ ] };

declare 'MapStringCryptoReplaceFfxFpeConfig',
    as HashRef[CryptoReplaceFfxFpeConfig()];

declare 'FfxCommonNativeAlphabet',
    as (Int | Str);

declare 'CryptoKey',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::CryptoKey'];

coerce 'CryptoKey',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::CryptoKey'->new($_) };

declare 'RepeatedCryptoKey',
    as ArrayRef[CryptoKey()];

coerce 'RepeatedCryptoKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::CryptoKey'->new($_) } @$_ ] };

declare 'MapStringCryptoKey',
    as HashRef[CryptoKey()];

declare 'TransientCryptoKey',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::TransientCryptoKey'];

coerce 'TransientCryptoKey',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::TransientCryptoKey'->new($_) };

declare 'RepeatedTransientCryptoKey',
    as ArrayRef[TransientCryptoKey()];

coerce 'RepeatedTransientCryptoKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::TransientCryptoKey'->new($_) } @$_ ] };

declare 'MapStringTransientCryptoKey',
    as HashRef[TransientCryptoKey()];

declare 'UnwrappedCryptoKey',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::UnwrappedCryptoKey'];

coerce 'UnwrappedCryptoKey',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::UnwrappedCryptoKey'->new($_) };

declare 'RepeatedUnwrappedCryptoKey',
    as ArrayRef[UnwrappedCryptoKey()];

coerce 'RepeatedUnwrappedCryptoKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::UnwrappedCryptoKey'->new($_) } @$_ ] };

declare 'MapStringUnwrappedCryptoKey',
    as HashRef[UnwrappedCryptoKey()];

declare 'KmsWrappedCryptoKey',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::KmsWrappedCryptoKey'];

coerce 'KmsWrappedCryptoKey',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::KmsWrappedCryptoKey'->new($_) };

declare 'RepeatedKmsWrappedCryptoKey',
    as ArrayRef[KmsWrappedCryptoKey()];

coerce 'RepeatedKmsWrappedCryptoKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::KmsWrappedCryptoKey'->new($_) } @$_ ] };

declare 'MapStringKmsWrappedCryptoKey',
    as HashRef[KmsWrappedCryptoKey()];

declare 'DateShiftConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DateShiftConfig'];

coerce 'DateShiftConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DateShiftConfig'->new($_) };

declare 'RepeatedDateShiftConfig',
    as ArrayRef[DateShiftConfig()];

coerce 'RepeatedDateShiftConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DateShiftConfig'->new($_) } @$_ ] };

declare 'MapStringDateShiftConfig',
    as HashRef[DateShiftConfig()];

declare 'InfoTypeTransformations',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::InfoTypeTransformations'];

coerce 'InfoTypeTransformations',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::InfoTypeTransformations'->new($_) };

declare 'RepeatedInfoTypeTransformations',
    as ArrayRef[InfoTypeTransformations()];

coerce 'RepeatedInfoTypeTransformations',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::InfoTypeTransformations'->new($_) } @$_ ] };

declare 'MapStringInfoTypeTransformations',
    as HashRef[InfoTypeTransformations()];

declare 'InfoTypeTransformation',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::InfoTypeTransformations::InfoTypeTransformation'];

coerce 'InfoTypeTransformation',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::InfoTypeTransformations::InfoTypeTransformation'->new($_) };

declare 'RepeatedInfoTypeTransformation',
    as ArrayRef[InfoTypeTransformation()];

coerce 'RepeatedInfoTypeTransformation',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::InfoTypeTransformations::InfoTypeTransformation'->new($_) } @$_ ] };

declare 'MapStringInfoTypeTransformation',
    as HashRef[InfoTypeTransformation()];

declare 'FieldTransformation',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::FieldTransformation'];

coerce 'FieldTransformation',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::FieldTransformation'->new($_) };

declare 'RepeatedFieldTransformation',
    as ArrayRef[FieldTransformation()];

coerce 'RepeatedFieldTransformation',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::FieldTransformation'->new($_) } @$_ ] };

declare 'MapStringFieldTransformation',
    as HashRef[FieldTransformation()];

declare 'RecordTransformations',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::RecordTransformations'];

coerce 'RecordTransformations',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::RecordTransformations'->new($_) };

declare 'RepeatedRecordTransformations',
    as ArrayRef[RecordTransformations()];

coerce 'RepeatedRecordTransformations',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::RecordTransformations'->new($_) } @$_ ] };

declare 'MapStringRecordTransformations',
    as HashRef[RecordTransformations()];

declare 'RecordSuppression',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::RecordSuppression'];

coerce 'RecordSuppression',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::RecordSuppression'->new($_) };

declare 'RepeatedRecordSuppression',
    as ArrayRef[RecordSuppression()];

coerce 'RepeatedRecordSuppression',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::RecordSuppression'->new($_) } @$_ ] };

declare 'MapStringRecordSuppression',
    as HashRef[RecordSuppression()];

declare 'RecordCondition',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::RecordCondition'];

coerce 'RecordCondition',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::RecordCondition'->new($_) };

declare 'RepeatedRecordCondition',
    as ArrayRef[RecordCondition()];

coerce 'RepeatedRecordCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::RecordCondition'->new($_) } @$_ ] };

declare 'MapStringRecordCondition',
    as HashRef[RecordCondition()];

declare 'Condition',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::RecordCondition::Condition'];

coerce 'Condition',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::RecordCondition::Condition'->new($_) };

declare 'RepeatedCondition',
    as ArrayRef[Condition()];

coerce 'RepeatedCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::RecordCondition::Condition'->new($_) } @$_ ] };

declare 'MapStringCondition',
    as HashRef[Condition()];

declare 'Conditions',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::RecordCondition::Conditions'];

coerce 'Conditions',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::RecordCondition::Conditions'->new($_) };

declare 'RepeatedConditions',
    as ArrayRef[Conditions()];

coerce 'RepeatedConditions',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::RecordCondition::Conditions'->new($_) } @$_ ] };

declare 'MapStringConditions',
    as HashRef[Conditions()];

declare 'Expressions',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::RecordCondition::Expressions'];

coerce 'Expressions',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::RecordCondition::Expressions'->new($_) };

declare 'RepeatedExpressions',
    as ArrayRef[Expressions()];

coerce 'RepeatedExpressions',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::RecordCondition::Expressions'->new($_) } @$_ ] };

declare 'MapStringExpressions',
    as HashRef[Expressions()];

declare 'LogicalOperator',
    as (Int | Str);

declare 'TransformationOverview',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::TransformationOverview'];

coerce 'TransformationOverview',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::TransformationOverview'->new($_) };

declare 'RepeatedTransformationOverview',
    as ArrayRef[TransformationOverview()];

coerce 'RepeatedTransformationOverview',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::TransformationOverview'->new($_) } @$_ ] };

declare 'MapStringTransformationOverview',
    as HashRef[TransformationOverview()];

declare 'TransformationSummary',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::TransformationSummary'];

coerce 'TransformationSummary',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::TransformationSummary'->new($_) };

declare 'RepeatedTransformationSummary',
    as ArrayRef[TransformationSummary()];

coerce 'RepeatedTransformationSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::TransformationSummary'->new($_) } @$_ ] };

declare 'MapStringTransformationSummary',
    as HashRef[TransformationSummary()];

declare 'TransformationResultCode',
    as (Int | Str);

declare 'SummaryResult',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::TransformationSummary::SummaryResult'];

coerce 'SummaryResult',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::TransformationSummary::SummaryResult'->new($_) };

declare 'RepeatedSummaryResult',
    as ArrayRef[SummaryResult()];

coerce 'RepeatedSummaryResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::TransformationSummary::SummaryResult'->new($_) } @$_ ] };

declare 'MapStringSummaryResult',
    as HashRef[SummaryResult()];

declare 'TransformationDescription',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::TransformationDescription'];

coerce 'TransformationDescription',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::TransformationDescription'->new($_) };

declare 'RepeatedTransformationDescription',
    as ArrayRef[TransformationDescription()];

coerce 'RepeatedTransformationDescription',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::TransformationDescription'->new($_) } @$_ ] };

declare 'MapStringTransformationDescription',
    as HashRef[TransformationDescription()];

declare 'TransformationDetails',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::TransformationDetails'];

coerce 'TransformationDetails',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::TransformationDetails'->new($_) };

declare 'RepeatedTransformationDetails',
    as ArrayRef[TransformationDetails()];

coerce 'RepeatedTransformationDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::TransformationDetails'->new($_) } @$_ ] };

declare 'MapStringTransformationDetails',
    as HashRef[TransformationDetails()];

declare 'TransformationLocation',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::TransformationLocation'];

coerce 'TransformationLocation',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::TransformationLocation'->new($_) };

declare 'RepeatedTransformationLocation',
    as ArrayRef[TransformationLocation()];

coerce 'RepeatedTransformationLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::TransformationLocation'->new($_) } @$_ ] };

declare 'MapStringTransformationLocation',
    as HashRef[TransformationLocation()];

declare 'RecordTransformation',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::RecordTransformation'];

coerce 'RecordTransformation',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::RecordTransformation'->new($_) };

declare 'RepeatedRecordTransformation',
    as ArrayRef[RecordTransformation()];

coerce 'RepeatedRecordTransformation',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::RecordTransformation'->new($_) } @$_ ] };

declare 'MapStringRecordTransformation',
    as HashRef[RecordTransformation()];

declare 'TransformationResultStatus',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::TransformationResultStatus'];

coerce 'TransformationResultStatus',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::TransformationResultStatus'->new($_) };

declare 'RepeatedTransformationResultStatus',
    as ArrayRef[TransformationResultStatus()];

coerce 'RepeatedTransformationResultStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::TransformationResultStatus'->new($_) } @$_ ] };

declare 'MapStringTransformationResultStatus',
    as HashRef[TransformationResultStatus()];

declare 'TransformationDetailsStorageConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::TransformationDetailsStorageConfig'];

coerce 'TransformationDetailsStorageConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::TransformationDetailsStorageConfig'->new($_) };

declare 'RepeatedTransformationDetailsStorageConfig',
    as ArrayRef[TransformationDetailsStorageConfig()];

coerce 'RepeatedTransformationDetailsStorageConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::TransformationDetailsStorageConfig'->new($_) } @$_ ] };

declare 'MapStringTransformationDetailsStorageConfig',
    as HashRef[TransformationDetailsStorageConfig()];

declare 'Schedule',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::Schedule'];

coerce 'Schedule',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::Schedule'->new($_) };

declare 'RepeatedSchedule',
    as ArrayRef[Schedule()];

coerce 'RepeatedSchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::Schedule'->new($_) } @$_ ] };

declare 'MapStringSchedule',
    as HashRef[Schedule()];

declare 'Manual',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::Manual'];

coerce 'Manual',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::Manual'->new($_) };

declare 'RepeatedManual',
    as ArrayRef[Manual()];

coerce 'RepeatedManual',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::Manual'->new($_) } @$_ ] };

declare 'MapStringManual',
    as HashRef[Manual()];

declare 'InspectTemplate',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::InspectTemplate'];

coerce 'InspectTemplate',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::InspectTemplate'->new($_) };

declare 'RepeatedInspectTemplate',
    as ArrayRef[InspectTemplate()];

coerce 'RepeatedInspectTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::InspectTemplate'->new($_) } @$_ ] };

declare 'MapStringInspectTemplate',
    as HashRef[InspectTemplate()];

declare 'DeidentifyTemplate',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DeidentifyTemplate'];

coerce 'DeidentifyTemplate',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DeidentifyTemplate'->new($_) };

declare 'RepeatedDeidentifyTemplate',
    as ArrayRef[DeidentifyTemplate()];

coerce 'RepeatedDeidentifyTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DeidentifyTemplate'->new($_) } @$_ ] };

declare 'MapStringDeidentifyTemplate',
    as HashRef[DeidentifyTemplate()];

declare 'Error',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::Error'];

coerce 'Error',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::Error'->new($_) };

declare 'RepeatedError',
    as ArrayRef[Error()];

coerce 'RepeatedError',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::Error'->new($_) } @$_ ] };

declare 'MapStringError',
    as HashRef[Error()];

declare 'ErrorExtraInfo',
    as (Int | Str);

declare 'JobTrigger',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::JobTrigger'];

coerce 'JobTrigger',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::JobTrigger'->new($_) };

declare 'RepeatedJobTrigger',
    as ArrayRef[JobTrigger()];

coerce 'RepeatedJobTrigger',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::JobTrigger'->new($_) } @$_ ] };

declare 'MapStringJobTrigger',
    as HashRef[JobTrigger()];

declare 'Status',
    as (Int | Str);

declare 'Trigger',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::JobTrigger::Trigger'];

coerce 'Trigger',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::JobTrigger::Trigger'->new($_) };

declare 'RepeatedTrigger',
    as ArrayRef[Trigger()];

coerce 'RepeatedTrigger',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::JobTrigger::Trigger'->new($_) } @$_ ] };

declare 'MapStringTrigger',
    as HashRef[Trigger()];

declare 'Action',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::Action'];

coerce 'Action',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::Action'->new($_) };

declare 'RepeatedAction',
    as ArrayRef[Action()];

coerce 'RepeatedAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::Action'->new($_) } @$_ ] };

declare 'MapStringAction',
    as HashRef[Action()];

declare 'SaveFindings',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::Action::SaveFindings'];

coerce 'SaveFindings',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::Action::SaveFindings'->new($_) };

declare 'RepeatedSaveFindings',
    as ArrayRef[SaveFindings()];

coerce 'RepeatedSaveFindings',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::Action::SaveFindings'->new($_) } @$_ ] };

declare 'MapStringSaveFindings',
    as HashRef[SaveFindings()];

declare 'PublishToPubSub',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::Action::PublishToPubSub'];

coerce 'PublishToPubSub',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::Action::PublishToPubSub'->new($_) };

declare 'RepeatedPublishToPubSub',
    as ArrayRef[PublishToPubSub()];

coerce 'RepeatedPublishToPubSub',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::Action::PublishToPubSub'->new($_) } @$_ ] };

declare 'MapStringPublishToPubSub',
    as HashRef[PublishToPubSub()];

declare 'PublishSummaryToCscc',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::Action::PublishSummaryToCscc'];

coerce 'PublishSummaryToCscc',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::Action::PublishSummaryToCscc'->new($_) };

declare 'RepeatedPublishSummaryToCscc',
    as ArrayRef[PublishSummaryToCscc()];

coerce 'RepeatedPublishSummaryToCscc',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::Action::PublishSummaryToCscc'->new($_) } @$_ ] };

declare 'MapStringPublishSummaryToCscc',
    as HashRef[PublishSummaryToCscc()];

declare 'PublishFindingsToCloudDataCatalog',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::Action::PublishFindingsToCloudDataCatalog'];

coerce 'PublishFindingsToCloudDataCatalog',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::Action::PublishFindingsToCloudDataCatalog'->new($_) };

declare 'RepeatedPublishFindingsToCloudDataCatalog',
    as ArrayRef[PublishFindingsToCloudDataCatalog()];

coerce 'RepeatedPublishFindingsToCloudDataCatalog',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::Action::PublishFindingsToCloudDataCatalog'->new($_) } @$_ ] };

declare 'MapStringPublishFindingsToCloudDataCatalog',
    as HashRef[PublishFindingsToCloudDataCatalog()];

declare 'PublishFindingsToDataplexCatalog',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::Action::PublishFindingsToDataplexCatalog'];

coerce 'PublishFindingsToDataplexCatalog',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::Action::PublishFindingsToDataplexCatalog'->new($_) };

declare 'RepeatedPublishFindingsToDataplexCatalog',
    as ArrayRef[PublishFindingsToDataplexCatalog()];

coerce 'RepeatedPublishFindingsToDataplexCatalog',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::Action::PublishFindingsToDataplexCatalog'->new($_) } @$_ ] };

declare 'MapStringPublishFindingsToDataplexCatalog',
    as HashRef[PublishFindingsToDataplexCatalog()];

declare 'Deidentify',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::Action::Deidentify'];

coerce 'Deidentify',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::Action::Deidentify'->new($_) };

declare 'RepeatedDeidentify',
    as ArrayRef[Deidentify()];

coerce 'RepeatedDeidentify',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::Action::Deidentify'->new($_) } @$_ ] };

declare 'MapStringDeidentify',
    as HashRef[Deidentify()];

declare 'JobNotificationEmails',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::Action::JobNotificationEmails'];

coerce 'JobNotificationEmails',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::Action::JobNotificationEmails'->new($_) };

declare 'RepeatedJobNotificationEmails',
    as ArrayRef[JobNotificationEmails()];

coerce 'RepeatedJobNotificationEmails',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::Action::JobNotificationEmails'->new($_) } @$_ ] };

declare 'MapStringJobNotificationEmails',
    as HashRef[JobNotificationEmails()];

declare 'PublishToStackdriver',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::Action::PublishToStackdriver'];

coerce 'PublishToStackdriver',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::Action::PublishToStackdriver'->new($_) };

declare 'RepeatedPublishToStackdriver',
    as ArrayRef[PublishToStackdriver()];

coerce 'RepeatedPublishToStackdriver',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::Action::PublishToStackdriver'->new($_) } @$_ ] };

declare 'MapStringPublishToStackdriver',
    as HashRef[PublishToStackdriver()];

declare 'TransformationConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::TransformationConfig'];

coerce 'TransformationConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::TransformationConfig'->new($_) };

declare 'RepeatedTransformationConfig',
    as ArrayRef[TransformationConfig()];

coerce 'RepeatedTransformationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::TransformationConfig'->new($_) } @$_ ] };

declare 'MapStringTransformationConfig',
    as HashRef[TransformationConfig()];

declare 'CreateInspectTemplateRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::CreateInspectTemplateRequest'];

coerce 'CreateInspectTemplateRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::CreateInspectTemplateRequest'->new($_) };

declare 'RepeatedCreateInspectTemplateRequest',
    as ArrayRef[CreateInspectTemplateRequest()];

coerce 'RepeatedCreateInspectTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::CreateInspectTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringCreateInspectTemplateRequest',
    as HashRef[CreateInspectTemplateRequest()];

declare 'UpdateInspectTemplateRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::UpdateInspectTemplateRequest'];

coerce 'UpdateInspectTemplateRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::UpdateInspectTemplateRequest'->new($_) };

declare 'RepeatedUpdateInspectTemplateRequest',
    as ArrayRef[UpdateInspectTemplateRequest()];

coerce 'RepeatedUpdateInspectTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::UpdateInspectTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateInspectTemplateRequest',
    as HashRef[UpdateInspectTemplateRequest()];

declare 'GetInspectTemplateRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::GetInspectTemplateRequest'];

coerce 'GetInspectTemplateRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::GetInspectTemplateRequest'->new($_) };

declare 'RepeatedGetInspectTemplateRequest',
    as ArrayRef[GetInspectTemplateRequest()];

coerce 'RepeatedGetInspectTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::GetInspectTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringGetInspectTemplateRequest',
    as HashRef[GetInspectTemplateRequest()];

declare 'ListInspectTemplatesRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ListInspectTemplatesRequest'];

coerce 'ListInspectTemplatesRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ListInspectTemplatesRequest'->new($_) };

declare 'RepeatedListInspectTemplatesRequest',
    as ArrayRef[ListInspectTemplatesRequest()];

coerce 'RepeatedListInspectTemplatesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ListInspectTemplatesRequest'->new($_) } @$_ ] };

declare 'MapStringListInspectTemplatesRequest',
    as HashRef[ListInspectTemplatesRequest()];

declare 'ListInspectTemplatesResponse',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ListInspectTemplatesResponse'];

coerce 'ListInspectTemplatesResponse',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ListInspectTemplatesResponse'->new($_) };

declare 'RepeatedListInspectTemplatesResponse',
    as ArrayRef[ListInspectTemplatesResponse()];

coerce 'RepeatedListInspectTemplatesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ListInspectTemplatesResponse'->new($_) } @$_ ] };

declare 'MapStringListInspectTemplatesResponse',
    as HashRef[ListInspectTemplatesResponse()];

declare 'DeleteInspectTemplateRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DeleteInspectTemplateRequest'];

coerce 'DeleteInspectTemplateRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DeleteInspectTemplateRequest'->new($_) };

declare 'RepeatedDeleteInspectTemplateRequest',
    as ArrayRef[DeleteInspectTemplateRequest()];

coerce 'RepeatedDeleteInspectTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DeleteInspectTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteInspectTemplateRequest',
    as HashRef[DeleteInspectTemplateRequest()];

declare 'CreateJobTriggerRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::CreateJobTriggerRequest'];

coerce 'CreateJobTriggerRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::CreateJobTriggerRequest'->new($_) };

declare 'RepeatedCreateJobTriggerRequest',
    as ArrayRef[CreateJobTriggerRequest()];

coerce 'RepeatedCreateJobTriggerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::CreateJobTriggerRequest'->new($_) } @$_ ] };

declare 'MapStringCreateJobTriggerRequest',
    as HashRef[CreateJobTriggerRequest()];

declare 'ActivateJobTriggerRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ActivateJobTriggerRequest'];

coerce 'ActivateJobTriggerRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ActivateJobTriggerRequest'->new($_) };

declare 'RepeatedActivateJobTriggerRequest',
    as ArrayRef[ActivateJobTriggerRequest()];

coerce 'RepeatedActivateJobTriggerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ActivateJobTriggerRequest'->new($_) } @$_ ] };

declare 'MapStringActivateJobTriggerRequest',
    as HashRef[ActivateJobTriggerRequest()];

declare 'UpdateJobTriggerRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::UpdateJobTriggerRequest'];

coerce 'UpdateJobTriggerRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::UpdateJobTriggerRequest'->new($_) };

declare 'RepeatedUpdateJobTriggerRequest',
    as ArrayRef[UpdateJobTriggerRequest()];

coerce 'RepeatedUpdateJobTriggerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::UpdateJobTriggerRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateJobTriggerRequest',
    as HashRef[UpdateJobTriggerRequest()];

declare 'GetJobTriggerRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::GetJobTriggerRequest'];

coerce 'GetJobTriggerRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::GetJobTriggerRequest'->new($_) };

declare 'RepeatedGetJobTriggerRequest',
    as ArrayRef[GetJobTriggerRequest()];

coerce 'RepeatedGetJobTriggerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::GetJobTriggerRequest'->new($_) } @$_ ] };

declare 'MapStringGetJobTriggerRequest',
    as HashRef[GetJobTriggerRequest()];

declare 'CreateDiscoveryConfigRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::CreateDiscoveryConfigRequest'];

coerce 'CreateDiscoveryConfigRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::CreateDiscoveryConfigRequest'->new($_) };

declare 'RepeatedCreateDiscoveryConfigRequest',
    as ArrayRef[CreateDiscoveryConfigRequest()];

coerce 'RepeatedCreateDiscoveryConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::CreateDiscoveryConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDiscoveryConfigRequest',
    as HashRef[CreateDiscoveryConfigRequest()];

declare 'UpdateDiscoveryConfigRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::UpdateDiscoveryConfigRequest'];

coerce 'UpdateDiscoveryConfigRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::UpdateDiscoveryConfigRequest'->new($_) };

declare 'RepeatedUpdateDiscoveryConfigRequest',
    as ArrayRef[UpdateDiscoveryConfigRequest()];

coerce 'RepeatedUpdateDiscoveryConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::UpdateDiscoveryConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDiscoveryConfigRequest',
    as HashRef[UpdateDiscoveryConfigRequest()];

declare 'GetDiscoveryConfigRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::GetDiscoveryConfigRequest'];

coerce 'GetDiscoveryConfigRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::GetDiscoveryConfigRequest'->new($_) };

declare 'RepeatedGetDiscoveryConfigRequest',
    as ArrayRef[GetDiscoveryConfigRequest()];

coerce 'RepeatedGetDiscoveryConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::GetDiscoveryConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetDiscoveryConfigRequest',
    as HashRef[GetDiscoveryConfigRequest()];

declare 'ListDiscoveryConfigsRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ListDiscoveryConfigsRequest'];

coerce 'ListDiscoveryConfigsRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ListDiscoveryConfigsRequest'->new($_) };

declare 'RepeatedListDiscoveryConfigsRequest',
    as ArrayRef[ListDiscoveryConfigsRequest()];

coerce 'RepeatedListDiscoveryConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ListDiscoveryConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListDiscoveryConfigsRequest',
    as HashRef[ListDiscoveryConfigsRequest()];

declare 'ListDiscoveryConfigsResponse',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ListDiscoveryConfigsResponse'];

coerce 'ListDiscoveryConfigsResponse',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ListDiscoveryConfigsResponse'->new($_) };

declare 'RepeatedListDiscoveryConfigsResponse',
    as ArrayRef[ListDiscoveryConfigsResponse()];

coerce 'RepeatedListDiscoveryConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ListDiscoveryConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListDiscoveryConfigsResponse',
    as HashRef[ListDiscoveryConfigsResponse()];

declare 'DeleteDiscoveryConfigRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DeleteDiscoveryConfigRequest'];

coerce 'DeleteDiscoveryConfigRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DeleteDiscoveryConfigRequest'->new($_) };

declare 'RepeatedDeleteDiscoveryConfigRequest',
    as ArrayRef[DeleteDiscoveryConfigRequest()];

coerce 'RepeatedDeleteDiscoveryConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DeleteDiscoveryConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDiscoveryConfigRequest',
    as HashRef[DeleteDiscoveryConfigRequest()];

declare 'CreateDlpJobRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::CreateDlpJobRequest'];

coerce 'CreateDlpJobRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::CreateDlpJobRequest'->new($_) };

declare 'RepeatedCreateDlpJobRequest',
    as ArrayRef[CreateDlpJobRequest()];

coerce 'RepeatedCreateDlpJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::CreateDlpJobRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDlpJobRequest',
    as HashRef[CreateDlpJobRequest()];

declare 'ListJobTriggersRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ListJobTriggersRequest'];

coerce 'ListJobTriggersRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ListJobTriggersRequest'->new($_) };

declare 'RepeatedListJobTriggersRequest',
    as ArrayRef[ListJobTriggersRequest()];

coerce 'RepeatedListJobTriggersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ListJobTriggersRequest'->new($_) } @$_ ] };

declare 'MapStringListJobTriggersRequest',
    as HashRef[ListJobTriggersRequest()];

declare 'ListJobTriggersResponse',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ListJobTriggersResponse'];

coerce 'ListJobTriggersResponse',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ListJobTriggersResponse'->new($_) };

declare 'RepeatedListJobTriggersResponse',
    as ArrayRef[ListJobTriggersResponse()];

coerce 'RepeatedListJobTriggersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ListJobTriggersResponse'->new($_) } @$_ ] };

declare 'MapStringListJobTriggersResponse',
    as HashRef[ListJobTriggersResponse()];

declare 'DeleteJobTriggerRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DeleteJobTriggerRequest'];

coerce 'DeleteJobTriggerRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DeleteJobTriggerRequest'->new($_) };

declare 'RepeatedDeleteJobTriggerRequest',
    as ArrayRef[DeleteJobTriggerRequest()];

coerce 'RepeatedDeleteJobTriggerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DeleteJobTriggerRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteJobTriggerRequest',
    as HashRef[DeleteJobTriggerRequest()];

declare 'InspectJobConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::InspectJobConfig'];

coerce 'InspectJobConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::InspectJobConfig'->new($_) };

declare 'RepeatedInspectJobConfig',
    as ArrayRef[InspectJobConfig()];

coerce 'RepeatedInspectJobConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::InspectJobConfig'->new($_) } @$_ ] };

declare 'MapStringInspectJobConfig',
    as HashRef[InspectJobConfig()];

declare 'DataProfileAction',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DataProfileAction'];

coerce 'DataProfileAction',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DataProfileAction'->new($_) };

declare 'RepeatedDataProfileAction',
    as ArrayRef[DataProfileAction()];

coerce 'RepeatedDataProfileAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DataProfileAction'->new($_) } @$_ ] };

declare 'MapStringDataProfileAction',
    as HashRef[DataProfileAction()];

declare 'EventType',
    as (Int | Str);

declare 'Export',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DataProfileAction::Export'];

coerce 'Export',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DataProfileAction::Export'->new($_) };

declare 'RepeatedExport',
    as ArrayRef[Export()];

coerce 'RepeatedExport',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DataProfileAction::Export'->new($_) } @$_ ] };

declare 'MapStringExport',
    as HashRef[Export()];

declare 'PubSubNotification',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DataProfileAction::PubSubNotification'];

coerce 'PubSubNotification',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DataProfileAction::PubSubNotification'->new($_) };

declare 'RepeatedPubSubNotification',
    as ArrayRef[PubSubNotification()];

coerce 'RepeatedPubSubNotification',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DataProfileAction::PubSubNotification'->new($_) } @$_ ] };

declare 'MapStringPubSubNotification',
    as HashRef[PubSubNotification()];

declare 'DetailLevel',
    as (Int | Str);

declare 'PublishToChronicle',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DataProfileAction::PublishToChronicle'];

coerce 'PublishToChronicle',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DataProfileAction::PublishToChronicle'->new($_) };

declare 'RepeatedPublishToChronicle',
    as ArrayRef[PublishToChronicle()];

coerce 'RepeatedPublishToChronicle',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DataProfileAction::PublishToChronicle'->new($_) } @$_ ] };

declare 'MapStringPublishToChronicle',
    as HashRef[PublishToChronicle()];

declare 'PublishToSecurityCommandCenter',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DataProfileAction::PublishToSecurityCommandCenter'];

coerce 'PublishToSecurityCommandCenter',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DataProfileAction::PublishToSecurityCommandCenter'->new($_) };

declare 'RepeatedPublishToSecurityCommandCenter',
    as ArrayRef[PublishToSecurityCommandCenter()];

coerce 'RepeatedPublishToSecurityCommandCenter',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DataProfileAction::PublishToSecurityCommandCenter'->new($_) } @$_ ] };

declare 'MapStringPublishToSecurityCommandCenter',
    as HashRef[PublishToSecurityCommandCenter()];

declare 'PublishToDataplexCatalog',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DataProfileAction::PublishToDataplexCatalog'];

coerce 'PublishToDataplexCatalog',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DataProfileAction::PublishToDataplexCatalog'->new($_) };

declare 'RepeatedPublishToDataplexCatalog',
    as ArrayRef[PublishToDataplexCatalog()];

coerce 'RepeatedPublishToDataplexCatalog',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DataProfileAction::PublishToDataplexCatalog'->new($_) } @$_ ] };

declare 'MapStringPublishToDataplexCatalog',
    as HashRef[PublishToDataplexCatalog()];

declare 'TagResources',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DataProfileAction::TagResources'];

coerce 'TagResources',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DataProfileAction::TagResources'->new($_) };

declare 'RepeatedTagResources',
    as ArrayRef[TagResources()];

coerce 'RepeatedTagResources',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DataProfileAction::TagResources'->new($_) } @$_ ] };

declare 'MapStringTagResources',
    as HashRef[TagResources()];

declare 'TagCondition',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DataProfileAction::TagResources::TagCondition'];

coerce 'TagCondition',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DataProfileAction::TagResources::TagCondition'->new($_) };

declare 'RepeatedTagCondition',
    as ArrayRef[TagCondition()];

coerce 'RepeatedTagCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DataProfileAction::TagResources::TagCondition'->new($_) } @$_ ] };

declare 'MapStringTagCondition',
    as HashRef[TagCondition()];

declare 'TagValue',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DataProfileAction::TagResources::TagValue'];

coerce 'TagValue',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DataProfileAction::TagResources::TagValue'->new($_) };

declare 'RepeatedTagValue',
    as ArrayRef[TagValue()];

coerce 'RepeatedTagValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DataProfileAction::TagResources::TagValue'->new($_) } @$_ ] };

declare 'MapStringTagValue',
    as HashRef[TagValue()];

declare 'DataProfileFinding',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DataProfileFinding'];

coerce 'DataProfileFinding',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DataProfileFinding'->new($_) };

declare 'RepeatedDataProfileFinding',
    as ArrayRef[DataProfileFinding()];

coerce 'RepeatedDataProfileFinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DataProfileFinding'->new($_) } @$_ ] };

declare 'MapStringDataProfileFinding',
    as HashRef[DataProfileFinding()];

declare 'DataProfileFindingLocation',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DataProfileFindingLocation'];

coerce 'DataProfileFindingLocation',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DataProfileFindingLocation'->new($_) };

declare 'RepeatedDataProfileFindingLocation',
    as ArrayRef[DataProfileFindingLocation()];

coerce 'RepeatedDataProfileFindingLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DataProfileFindingLocation'->new($_) } @$_ ] };

declare 'MapStringDataProfileFindingLocation',
    as HashRef[DataProfileFindingLocation()];

declare 'DataProfileFindingRecordLocation',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DataProfileFindingRecordLocation'];

coerce 'DataProfileFindingRecordLocation',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DataProfileFindingRecordLocation'->new($_) };

declare 'RepeatedDataProfileFindingRecordLocation',
    as ArrayRef[DataProfileFindingRecordLocation()];

coerce 'RepeatedDataProfileFindingRecordLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DataProfileFindingRecordLocation'->new($_) } @$_ ] };

declare 'MapStringDataProfileFindingRecordLocation',
    as HashRef[DataProfileFindingRecordLocation()];

declare 'DataProfileJobConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DataProfileJobConfig'];

coerce 'DataProfileJobConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DataProfileJobConfig'->new($_) };

declare 'RepeatedDataProfileJobConfig',
    as ArrayRef[DataProfileJobConfig()];

coerce 'RepeatedDataProfileJobConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DataProfileJobConfig'->new($_) } @$_ ] };

declare 'MapStringDataProfileJobConfig',
    as HashRef[DataProfileJobConfig()];

declare 'BigQueryRegex',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::BigQueryRegex'];

coerce 'BigQueryRegex',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::BigQueryRegex'->new($_) };

declare 'RepeatedBigQueryRegex',
    as ArrayRef[BigQueryRegex()];

coerce 'RepeatedBigQueryRegex',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::BigQueryRegex'->new($_) } @$_ ] };

declare 'MapStringBigQueryRegex',
    as HashRef[BigQueryRegex()];

declare 'BigQueryRegexes',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::BigQueryRegexes'];

coerce 'BigQueryRegexes',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::BigQueryRegexes'->new($_) };

declare 'RepeatedBigQueryRegexes',
    as ArrayRef[BigQueryRegexes()];

coerce 'RepeatedBigQueryRegexes',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::BigQueryRegexes'->new($_) } @$_ ] };

declare 'MapStringBigQueryRegexes',
    as HashRef[BigQueryRegexes()];

declare 'BigQueryTableTypes',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::BigQueryTableTypes'];

coerce 'BigQueryTableTypes',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::BigQueryTableTypes'->new($_) };

declare 'RepeatedBigQueryTableTypes',
    as ArrayRef[BigQueryTableTypes()];

coerce 'RepeatedBigQueryTableTypes',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::BigQueryTableTypes'->new($_) } @$_ ] };

declare 'MapStringBigQueryTableTypes',
    as HashRef[BigQueryTableTypes()];

declare 'Disabled',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::Disabled'];

coerce 'Disabled',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::Disabled'->new($_) };

declare 'RepeatedDisabled',
    as ArrayRef[Disabled()];

coerce 'RepeatedDisabled',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::Disabled'->new($_) } @$_ ] };

declare 'MapStringDisabled',
    as HashRef[Disabled()];

declare 'DataProfileLocation',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DataProfileLocation'];

coerce 'DataProfileLocation',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DataProfileLocation'->new($_) };

declare 'RepeatedDataProfileLocation',
    as ArrayRef[DataProfileLocation()];

coerce 'RepeatedDataProfileLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DataProfileLocation'->new($_) } @$_ ] };

declare 'MapStringDataProfileLocation',
    as HashRef[DataProfileLocation()];

declare 'DiscoveryConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DiscoveryConfig'];

coerce 'DiscoveryConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryConfig'->new($_) };

declare 'RepeatedDiscoveryConfig',
    as ArrayRef[DiscoveryConfig()];

coerce 'RepeatedDiscoveryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryConfig'->new($_) } @$_ ] };

declare 'MapStringDiscoveryConfig',
    as HashRef[DiscoveryConfig()];

declare 'Status',
    as (Int | Str);

declare 'OrgConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DiscoveryConfig::OrgConfig'];

coerce 'OrgConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryConfig::OrgConfig'->new($_) };

declare 'RepeatedOrgConfig',
    as ArrayRef[OrgConfig()];

coerce 'RepeatedOrgConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryConfig::OrgConfig'->new($_) } @$_ ] };

declare 'MapStringOrgConfig',
    as HashRef[OrgConfig()];

declare 'DiscoveryTarget',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DiscoveryTarget'];

coerce 'DiscoveryTarget',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryTarget'->new($_) };

declare 'RepeatedDiscoveryTarget',
    as ArrayRef[DiscoveryTarget()];

coerce 'RepeatedDiscoveryTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryTarget'->new($_) } @$_ ] };

declare 'MapStringDiscoveryTarget',
    as HashRef[DiscoveryTarget()];

declare 'BigQueryDiscoveryTarget',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::BigQueryDiscoveryTarget'];

coerce 'BigQueryDiscoveryTarget',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::BigQueryDiscoveryTarget'->new($_) };

declare 'RepeatedBigQueryDiscoveryTarget',
    as ArrayRef[BigQueryDiscoveryTarget()];

coerce 'RepeatedBigQueryDiscoveryTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::BigQueryDiscoveryTarget'->new($_) } @$_ ] };

declare 'MapStringBigQueryDiscoveryTarget',
    as HashRef[BigQueryDiscoveryTarget()];

declare 'DiscoveryBigQueryFilter',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DiscoveryBigQueryFilter'];

coerce 'DiscoveryBigQueryFilter',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryBigQueryFilter'->new($_) };

declare 'RepeatedDiscoveryBigQueryFilter',
    as ArrayRef[DiscoveryBigQueryFilter()];

coerce 'RepeatedDiscoveryBigQueryFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryBigQueryFilter'->new($_) } @$_ ] };

declare 'MapStringDiscoveryBigQueryFilter',
    as HashRef[DiscoveryBigQueryFilter()];

declare 'AllOtherBigQueryTables',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DiscoveryBigQueryFilter::AllOtherBigQueryTables'];

coerce 'AllOtherBigQueryTables',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryBigQueryFilter::AllOtherBigQueryTables'->new($_) };

declare 'RepeatedAllOtherBigQueryTables',
    as ArrayRef[AllOtherBigQueryTables()];

coerce 'RepeatedAllOtherBigQueryTables',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryBigQueryFilter::AllOtherBigQueryTables'->new($_) } @$_ ] };

declare 'MapStringAllOtherBigQueryTables',
    as HashRef[AllOtherBigQueryTables()];

declare 'BigQueryTableCollection',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::BigQueryTableCollection'];

coerce 'BigQueryTableCollection',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::BigQueryTableCollection'->new($_) };

declare 'RepeatedBigQueryTableCollection',
    as ArrayRef[BigQueryTableCollection()];

coerce 'RepeatedBigQueryTableCollection',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::BigQueryTableCollection'->new($_) } @$_ ] };

declare 'MapStringBigQueryTableCollection',
    as HashRef[BigQueryTableCollection()];

declare 'DiscoveryBigQueryConditions',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DiscoveryBigQueryConditions'];

coerce 'DiscoveryBigQueryConditions',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryBigQueryConditions'->new($_) };

declare 'RepeatedDiscoveryBigQueryConditions',
    as ArrayRef[DiscoveryBigQueryConditions()];

coerce 'RepeatedDiscoveryBigQueryConditions',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryBigQueryConditions'->new($_) } @$_ ] };

declare 'MapStringDiscoveryBigQueryConditions',
    as HashRef[DiscoveryBigQueryConditions()];

declare 'OrConditions',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DiscoveryBigQueryConditions::OrConditions'];

coerce 'OrConditions',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryBigQueryConditions::OrConditions'->new($_) };

declare 'RepeatedOrConditions',
    as ArrayRef[OrConditions()];

coerce 'RepeatedOrConditions',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryBigQueryConditions::OrConditions'->new($_) } @$_ ] };

declare 'MapStringOrConditions',
    as HashRef[OrConditions()];

declare 'DiscoveryGenerationCadence',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DiscoveryGenerationCadence'];

coerce 'DiscoveryGenerationCadence',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryGenerationCadence'->new($_) };

declare 'RepeatedDiscoveryGenerationCadence',
    as ArrayRef[DiscoveryGenerationCadence()];

coerce 'RepeatedDiscoveryGenerationCadence',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryGenerationCadence'->new($_) } @$_ ] };

declare 'MapStringDiscoveryGenerationCadence',
    as HashRef[DiscoveryGenerationCadence()];

declare 'DiscoveryTableModifiedCadence',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DiscoveryTableModifiedCadence'];

coerce 'DiscoveryTableModifiedCadence',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryTableModifiedCadence'->new($_) };

declare 'RepeatedDiscoveryTableModifiedCadence',
    as ArrayRef[DiscoveryTableModifiedCadence()];

coerce 'RepeatedDiscoveryTableModifiedCadence',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryTableModifiedCadence'->new($_) } @$_ ] };

declare 'MapStringDiscoveryTableModifiedCadence',
    as HashRef[DiscoveryTableModifiedCadence()];

declare 'DiscoverySchemaModifiedCadence',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DiscoverySchemaModifiedCadence'];

coerce 'DiscoverySchemaModifiedCadence',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DiscoverySchemaModifiedCadence'->new($_) };

declare 'RepeatedDiscoverySchemaModifiedCadence',
    as ArrayRef[DiscoverySchemaModifiedCadence()];

coerce 'RepeatedDiscoverySchemaModifiedCadence',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DiscoverySchemaModifiedCadence'->new($_) } @$_ ] };

declare 'MapStringDiscoverySchemaModifiedCadence',
    as HashRef[DiscoverySchemaModifiedCadence()];

declare 'DiscoveryInspectTemplateModifiedCadence',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DiscoveryInspectTemplateModifiedCadence'];

coerce 'DiscoveryInspectTemplateModifiedCadence',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryInspectTemplateModifiedCadence'->new($_) };

declare 'RepeatedDiscoveryInspectTemplateModifiedCadence',
    as ArrayRef[DiscoveryInspectTemplateModifiedCadence()];

coerce 'RepeatedDiscoveryInspectTemplateModifiedCadence',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryInspectTemplateModifiedCadence'->new($_) } @$_ ] };

declare 'MapStringDiscoveryInspectTemplateModifiedCadence',
    as HashRef[DiscoveryInspectTemplateModifiedCadence()];

declare 'CloudSqlDiscoveryTarget',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::CloudSqlDiscoveryTarget'];

coerce 'CloudSqlDiscoveryTarget',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::CloudSqlDiscoveryTarget'->new($_) };

declare 'RepeatedCloudSqlDiscoveryTarget',
    as ArrayRef[CloudSqlDiscoveryTarget()];

coerce 'RepeatedCloudSqlDiscoveryTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::CloudSqlDiscoveryTarget'->new($_) } @$_ ] };

declare 'MapStringCloudSqlDiscoveryTarget',
    as HashRef[CloudSqlDiscoveryTarget()];

declare 'DiscoveryCloudSqlFilter',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DiscoveryCloudSqlFilter'];

coerce 'DiscoveryCloudSqlFilter',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryCloudSqlFilter'->new($_) };

declare 'RepeatedDiscoveryCloudSqlFilter',
    as ArrayRef[DiscoveryCloudSqlFilter()];

coerce 'RepeatedDiscoveryCloudSqlFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryCloudSqlFilter'->new($_) } @$_ ] };

declare 'MapStringDiscoveryCloudSqlFilter',
    as HashRef[DiscoveryCloudSqlFilter()];

declare 'DatabaseResourceCollection',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DatabaseResourceCollection'];

coerce 'DatabaseResourceCollection',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DatabaseResourceCollection'->new($_) };

declare 'RepeatedDatabaseResourceCollection',
    as ArrayRef[DatabaseResourceCollection()];

coerce 'RepeatedDatabaseResourceCollection',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DatabaseResourceCollection'->new($_) } @$_ ] };

declare 'MapStringDatabaseResourceCollection',
    as HashRef[DatabaseResourceCollection()];

declare 'DatabaseResourceRegexes',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DatabaseResourceRegexes'];

coerce 'DatabaseResourceRegexes',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DatabaseResourceRegexes'->new($_) };

declare 'RepeatedDatabaseResourceRegexes',
    as ArrayRef[DatabaseResourceRegexes()];

coerce 'RepeatedDatabaseResourceRegexes',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DatabaseResourceRegexes'->new($_) } @$_ ] };

declare 'MapStringDatabaseResourceRegexes',
    as HashRef[DatabaseResourceRegexes()];

declare 'DatabaseResourceRegex',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DatabaseResourceRegex'];

coerce 'DatabaseResourceRegex',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DatabaseResourceRegex'->new($_) };

declare 'RepeatedDatabaseResourceRegex',
    as ArrayRef[DatabaseResourceRegex()];

coerce 'RepeatedDatabaseResourceRegex',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DatabaseResourceRegex'->new($_) } @$_ ] };

declare 'MapStringDatabaseResourceRegex',
    as HashRef[DatabaseResourceRegex()];

declare 'AllOtherDatabaseResources',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::AllOtherDatabaseResources'];

coerce 'AllOtherDatabaseResources',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::AllOtherDatabaseResources'->new($_) };

declare 'RepeatedAllOtherDatabaseResources',
    as ArrayRef[AllOtherDatabaseResources()];

coerce 'RepeatedAllOtherDatabaseResources',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::AllOtherDatabaseResources'->new($_) } @$_ ] };

declare 'MapStringAllOtherDatabaseResources',
    as HashRef[AllOtherDatabaseResources()];

declare 'DatabaseResourceReference',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DatabaseResourceReference'];

coerce 'DatabaseResourceReference',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DatabaseResourceReference'->new($_) };

declare 'RepeatedDatabaseResourceReference',
    as ArrayRef[DatabaseResourceReference()];

coerce 'RepeatedDatabaseResourceReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DatabaseResourceReference'->new($_) } @$_ ] };

declare 'MapStringDatabaseResourceReference',
    as HashRef[DatabaseResourceReference()];

declare 'DiscoveryCloudSqlConditions',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DiscoveryCloudSqlConditions'];

coerce 'DiscoveryCloudSqlConditions',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryCloudSqlConditions'->new($_) };

declare 'RepeatedDiscoveryCloudSqlConditions',
    as ArrayRef[DiscoveryCloudSqlConditions()];

coerce 'RepeatedDiscoveryCloudSqlConditions',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryCloudSqlConditions'->new($_) } @$_ ] };

declare 'MapStringDiscoveryCloudSqlConditions',
    as HashRef[DiscoveryCloudSqlConditions()];

declare 'DatabaseEngine',
    as (Int | Str);

declare 'DatabaseResourceType',
    as (Int | Str);

declare 'DiscoveryCloudSqlGenerationCadence',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DiscoveryCloudSqlGenerationCadence'];

coerce 'DiscoveryCloudSqlGenerationCadence',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryCloudSqlGenerationCadence'->new($_) };

declare 'RepeatedDiscoveryCloudSqlGenerationCadence',
    as ArrayRef[DiscoveryCloudSqlGenerationCadence()];

coerce 'RepeatedDiscoveryCloudSqlGenerationCadence',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryCloudSqlGenerationCadence'->new($_) } @$_ ] };

declare 'MapStringDiscoveryCloudSqlGenerationCadence',
    as HashRef[DiscoveryCloudSqlGenerationCadence()];

declare 'SchemaModifiedCadence',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DiscoveryCloudSqlGenerationCadence::SchemaModifiedCadence'];

coerce 'SchemaModifiedCadence',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryCloudSqlGenerationCadence::SchemaModifiedCadence'->new($_) };

declare 'RepeatedSchemaModifiedCadence',
    as ArrayRef[SchemaModifiedCadence()];

coerce 'RepeatedSchemaModifiedCadence',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryCloudSqlGenerationCadence::SchemaModifiedCadence'->new($_) } @$_ ] };

declare 'MapStringSchemaModifiedCadence',
    as HashRef[SchemaModifiedCadence()];

declare 'CloudSqlSchemaModification',
    as (Int | Str);

declare 'SecretsDiscoveryTarget',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::SecretsDiscoveryTarget'];

coerce 'SecretsDiscoveryTarget',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::SecretsDiscoveryTarget'->new($_) };

declare 'RepeatedSecretsDiscoveryTarget',
    as ArrayRef[SecretsDiscoveryTarget()];

coerce 'RepeatedSecretsDiscoveryTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::SecretsDiscoveryTarget'->new($_) } @$_ ] };

declare 'MapStringSecretsDiscoveryTarget',
    as HashRef[SecretsDiscoveryTarget()];

declare 'CloudStorageDiscoveryTarget',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::CloudStorageDiscoveryTarget'];

coerce 'CloudStorageDiscoveryTarget',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::CloudStorageDiscoveryTarget'->new($_) };

declare 'RepeatedCloudStorageDiscoveryTarget',
    as ArrayRef[CloudStorageDiscoveryTarget()];

coerce 'RepeatedCloudStorageDiscoveryTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::CloudStorageDiscoveryTarget'->new($_) } @$_ ] };

declare 'MapStringCloudStorageDiscoveryTarget',
    as HashRef[CloudStorageDiscoveryTarget()];

declare 'DiscoveryCloudStorageFilter',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DiscoveryCloudStorageFilter'];

coerce 'DiscoveryCloudStorageFilter',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryCloudStorageFilter'->new($_) };

declare 'RepeatedDiscoveryCloudStorageFilter',
    as ArrayRef[DiscoveryCloudStorageFilter()];

coerce 'RepeatedDiscoveryCloudStorageFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryCloudStorageFilter'->new($_) } @$_ ] };

declare 'MapStringDiscoveryCloudStorageFilter',
    as HashRef[DiscoveryCloudStorageFilter()];

declare 'FileStoreCollection',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::FileStoreCollection'];

coerce 'FileStoreCollection',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::FileStoreCollection'->new($_) };

declare 'RepeatedFileStoreCollection',
    as ArrayRef[FileStoreCollection()];

coerce 'RepeatedFileStoreCollection',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::FileStoreCollection'->new($_) } @$_ ] };

declare 'MapStringFileStoreCollection',
    as HashRef[FileStoreCollection()];

declare 'FileStoreRegexes',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::FileStoreRegexes'];

coerce 'FileStoreRegexes',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::FileStoreRegexes'->new($_) };

declare 'RepeatedFileStoreRegexes',
    as ArrayRef[FileStoreRegexes()];

coerce 'RepeatedFileStoreRegexes',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::FileStoreRegexes'->new($_) } @$_ ] };

declare 'MapStringFileStoreRegexes',
    as HashRef[FileStoreRegexes()];

declare 'FileStoreRegex',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::FileStoreRegex'];

coerce 'FileStoreRegex',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::FileStoreRegex'->new($_) };

declare 'RepeatedFileStoreRegex',
    as ArrayRef[FileStoreRegex()];

coerce 'RepeatedFileStoreRegex',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::FileStoreRegex'->new($_) } @$_ ] };

declare 'MapStringFileStoreRegex',
    as HashRef[FileStoreRegex()];

declare 'CloudStorageRegex',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::CloudStorageRegex'];

coerce 'CloudStorageRegex',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::CloudStorageRegex'->new($_) };

declare 'RepeatedCloudStorageRegex',
    as ArrayRef[CloudStorageRegex()];

coerce 'RepeatedCloudStorageRegex',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::CloudStorageRegex'->new($_) } @$_ ] };

declare 'MapStringCloudStorageRegex',
    as HashRef[CloudStorageRegex()];

declare 'CloudStorageResourceReference',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::CloudStorageResourceReference'];

coerce 'CloudStorageResourceReference',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::CloudStorageResourceReference'->new($_) };

declare 'RepeatedCloudStorageResourceReference',
    as ArrayRef[CloudStorageResourceReference()];

coerce 'RepeatedCloudStorageResourceReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::CloudStorageResourceReference'->new($_) } @$_ ] };

declare 'MapStringCloudStorageResourceReference',
    as HashRef[CloudStorageResourceReference()];

declare 'DiscoveryCloudStorageGenerationCadence',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DiscoveryCloudStorageGenerationCadence'];

coerce 'DiscoveryCloudStorageGenerationCadence',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryCloudStorageGenerationCadence'->new($_) };

declare 'RepeatedDiscoveryCloudStorageGenerationCadence',
    as ArrayRef[DiscoveryCloudStorageGenerationCadence()];

coerce 'RepeatedDiscoveryCloudStorageGenerationCadence',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryCloudStorageGenerationCadence'->new($_) } @$_ ] };

declare 'MapStringDiscoveryCloudStorageGenerationCadence',
    as HashRef[DiscoveryCloudStorageGenerationCadence()];

declare 'DiscoveryCloudStorageConditions',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DiscoveryCloudStorageConditions'];

coerce 'DiscoveryCloudStorageConditions',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryCloudStorageConditions'->new($_) };

declare 'RepeatedDiscoveryCloudStorageConditions',
    as ArrayRef[DiscoveryCloudStorageConditions()];

coerce 'RepeatedDiscoveryCloudStorageConditions',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryCloudStorageConditions'->new($_) } @$_ ] };

declare 'MapStringDiscoveryCloudStorageConditions',
    as HashRef[DiscoveryCloudStorageConditions()];

declare 'CloudStorageObjectAttribute',
    as (Int | Str);

declare 'CloudStorageBucketAttribute',
    as (Int | Str);

declare 'DiscoveryFileStoreConditions',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DiscoveryFileStoreConditions'];

coerce 'DiscoveryFileStoreConditions',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryFileStoreConditions'->new($_) };

declare 'RepeatedDiscoveryFileStoreConditions',
    as ArrayRef[DiscoveryFileStoreConditions()];

coerce 'RepeatedDiscoveryFileStoreConditions',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryFileStoreConditions'->new($_) } @$_ ] };

declare 'MapStringDiscoveryFileStoreConditions',
    as HashRef[DiscoveryFileStoreConditions()];

declare 'OtherCloudDiscoveryTarget',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::OtherCloudDiscoveryTarget'];

coerce 'OtherCloudDiscoveryTarget',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::OtherCloudDiscoveryTarget'->new($_) };

declare 'RepeatedOtherCloudDiscoveryTarget',
    as ArrayRef[OtherCloudDiscoveryTarget()];

coerce 'RepeatedOtherCloudDiscoveryTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::OtherCloudDiscoveryTarget'->new($_) } @$_ ] };

declare 'MapStringOtherCloudDiscoveryTarget',
    as HashRef[OtherCloudDiscoveryTarget()];

declare 'DiscoveryOtherCloudFilter',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DiscoveryOtherCloudFilter'];

coerce 'DiscoveryOtherCloudFilter',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryOtherCloudFilter'->new($_) };

declare 'RepeatedDiscoveryOtherCloudFilter',
    as ArrayRef[DiscoveryOtherCloudFilter()];

coerce 'RepeatedDiscoveryOtherCloudFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryOtherCloudFilter'->new($_) } @$_ ] };

declare 'MapStringDiscoveryOtherCloudFilter',
    as HashRef[DiscoveryOtherCloudFilter()];

declare 'OtherCloudResourceCollection',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::OtherCloudResourceCollection'];

coerce 'OtherCloudResourceCollection',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::OtherCloudResourceCollection'->new($_) };

declare 'RepeatedOtherCloudResourceCollection',
    as ArrayRef[OtherCloudResourceCollection()];

coerce 'RepeatedOtherCloudResourceCollection',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::OtherCloudResourceCollection'->new($_) } @$_ ] };

declare 'MapStringOtherCloudResourceCollection',
    as HashRef[OtherCloudResourceCollection()];

declare 'OtherCloudResourceRegexes',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::OtherCloudResourceRegexes'];

coerce 'OtherCloudResourceRegexes',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::OtherCloudResourceRegexes'->new($_) };

declare 'RepeatedOtherCloudResourceRegexes',
    as ArrayRef[OtherCloudResourceRegexes()];

coerce 'RepeatedOtherCloudResourceRegexes',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::OtherCloudResourceRegexes'->new($_) } @$_ ] };

declare 'MapStringOtherCloudResourceRegexes',
    as HashRef[OtherCloudResourceRegexes()];

declare 'OtherCloudResourceRegex',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::OtherCloudResourceRegex'];

coerce 'OtherCloudResourceRegex',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::OtherCloudResourceRegex'->new($_) };

declare 'RepeatedOtherCloudResourceRegex',
    as ArrayRef[OtherCloudResourceRegex()];

coerce 'RepeatedOtherCloudResourceRegex',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::OtherCloudResourceRegex'->new($_) } @$_ ] };

declare 'MapStringOtherCloudResourceRegex',
    as HashRef[OtherCloudResourceRegex()];

declare 'AwsAccountRegex',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::AwsAccountRegex'];

coerce 'AwsAccountRegex',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::AwsAccountRegex'->new($_) };

declare 'RepeatedAwsAccountRegex',
    as ArrayRef[AwsAccountRegex()];

coerce 'RepeatedAwsAccountRegex',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::AwsAccountRegex'->new($_) } @$_ ] };

declare 'MapStringAwsAccountRegex',
    as HashRef[AwsAccountRegex()];

declare 'AmazonS3BucketRegex',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::AmazonS3BucketRegex'];

coerce 'AmazonS3BucketRegex',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::AmazonS3BucketRegex'->new($_) };

declare 'RepeatedAmazonS3BucketRegex',
    as ArrayRef[AmazonS3BucketRegex()];

coerce 'RepeatedAmazonS3BucketRegex',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::AmazonS3BucketRegex'->new($_) } @$_ ] };

declare 'MapStringAmazonS3BucketRegex',
    as HashRef[AmazonS3BucketRegex()];

declare 'OtherCloudSingleResourceReference',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::OtherCloudSingleResourceReference'];

coerce 'OtherCloudSingleResourceReference',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::OtherCloudSingleResourceReference'->new($_) };

declare 'RepeatedOtherCloudSingleResourceReference',
    as ArrayRef[OtherCloudSingleResourceReference()];

coerce 'RepeatedOtherCloudSingleResourceReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::OtherCloudSingleResourceReference'->new($_) } @$_ ] };

declare 'MapStringOtherCloudSingleResourceReference',
    as HashRef[OtherCloudSingleResourceReference()];

declare 'AwsAccount',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::AwsAccount'];

coerce 'AwsAccount',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::AwsAccount'->new($_) };

declare 'RepeatedAwsAccount',
    as ArrayRef[AwsAccount()];

coerce 'RepeatedAwsAccount',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::AwsAccount'->new($_) } @$_ ] };

declare 'MapStringAwsAccount',
    as HashRef[AwsAccount()];

declare 'AmazonS3Bucket',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::AmazonS3Bucket'];

coerce 'AmazonS3Bucket',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::AmazonS3Bucket'->new($_) };

declare 'RepeatedAmazonS3Bucket',
    as ArrayRef[AmazonS3Bucket()];

coerce 'RepeatedAmazonS3Bucket',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::AmazonS3Bucket'->new($_) } @$_ ] };

declare 'MapStringAmazonS3Bucket',
    as HashRef[AmazonS3Bucket()];

declare 'DiscoveryOtherCloudConditions',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DiscoveryOtherCloudConditions'];

coerce 'DiscoveryOtherCloudConditions',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryOtherCloudConditions'->new($_) };

declare 'RepeatedDiscoveryOtherCloudConditions',
    as ArrayRef[DiscoveryOtherCloudConditions()];

coerce 'RepeatedDiscoveryOtherCloudConditions',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryOtherCloudConditions'->new($_) } @$_ ] };

declare 'MapStringDiscoveryOtherCloudConditions',
    as HashRef[DiscoveryOtherCloudConditions()];

declare 'AmazonS3BucketConditions',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::AmazonS3BucketConditions'];

coerce 'AmazonS3BucketConditions',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::AmazonS3BucketConditions'->new($_) };

declare 'RepeatedAmazonS3BucketConditions',
    as ArrayRef[AmazonS3BucketConditions()];

coerce 'RepeatedAmazonS3BucketConditions',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::AmazonS3BucketConditions'->new($_) } @$_ ] };

declare 'MapStringAmazonS3BucketConditions',
    as HashRef[AmazonS3BucketConditions()];

declare 'BucketType',
    as (Int | Str);

declare 'ObjectStorageClass',
    as (Int | Str);

declare 'DiscoveryOtherCloudGenerationCadence',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DiscoveryOtherCloudGenerationCadence'];

coerce 'DiscoveryOtherCloudGenerationCadence',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryOtherCloudGenerationCadence'->new($_) };

declare 'RepeatedDiscoveryOtherCloudGenerationCadence',
    as ArrayRef[DiscoveryOtherCloudGenerationCadence()];

coerce 'RepeatedDiscoveryOtherCloudGenerationCadence',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryOtherCloudGenerationCadence'->new($_) } @$_ ] };

declare 'MapStringDiscoveryOtherCloudGenerationCadence',
    as HashRef[DiscoveryOtherCloudGenerationCadence()];

declare 'DiscoveryStartingLocation',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DiscoveryStartingLocation'];

coerce 'DiscoveryStartingLocation',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryStartingLocation'->new($_) };

declare 'RepeatedDiscoveryStartingLocation',
    as ArrayRef[DiscoveryStartingLocation()];

coerce 'RepeatedDiscoveryStartingLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryStartingLocation'->new($_) } @$_ ] };

declare 'MapStringDiscoveryStartingLocation',
    as HashRef[DiscoveryStartingLocation()];

declare 'OtherCloudDiscoveryStartingLocation',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::OtherCloudDiscoveryStartingLocation'];

coerce 'OtherCloudDiscoveryStartingLocation',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::OtherCloudDiscoveryStartingLocation'->new($_) };

declare 'RepeatedOtherCloudDiscoveryStartingLocation',
    as ArrayRef[OtherCloudDiscoveryStartingLocation()];

coerce 'RepeatedOtherCloudDiscoveryStartingLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::OtherCloudDiscoveryStartingLocation'->new($_) } @$_ ] };

declare 'MapStringOtherCloudDiscoveryStartingLocation',
    as HashRef[OtherCloudDiscoveryStartingLocation()];

declare 'AwsDiscoveryStartingLocation',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::OtherCloudDiscoveryStartingLocation::AwsDiscoveryStartingLocation'];

coerce 'AwsDiscoveryStartingLocation',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::OtherCloudDiscoveryStartingLocation::AwsDiscoveryStartingLocation'->new($_) };

declare 'RepeatedAwsDiscoveryStartingLocation',
    as ArrayRef[AwsDiscoveryStartingLocation()];

coerce 'RepeatedAwsDiscoveryStartingLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::OtherCloudDiscoveryStartingLocation::AwsDiscoveryStartingLocation'->new($_) } @$_ ] };

declare 'MapStringAwsDiscoveryStartingLocation',
    as HashRef[AwsDiscoveryStartingLocation()];

declare 'AllOtherResources',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::AllOtherResources'];

coerce 'AllOtherResources',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::AllOtherResources'->new($_) };

declare 'RepeatedAllOtherResources',
    as ArrayRef[AllOtherResources()];

coerce 'RepeatedAllOtherResources',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::AllOtherResources'->new($_) } @$_ ] };

declare 'MapStringAllOtherResources',
    as HashRef[AllOtherResources()];

declare 'VertexDatasetDiscoveryTarget',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::VertexDatasetDiscoveryTarget'];

coerce 'VertexDatasetDiscoveryTarget',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::VertexDatasetDiscoveryTarget'->new($_) };

declare 'RepeatedVertexDatasetDiscoveryTarget',
    as ArrayRef[VertexDatasetDiscoveryTarget()];

coerce 'RepeatedVertexDatasetDiscoveryTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::VertexDatasetDiscoveryTarget'->new($_) } @$_ ] };

declare 'MapStringVertexDatasetDiscoveryTarget',
    as HashRef[VertexDatasetDiscoveryTarget()];

declare 'DiscoveryVertexDatasetFilter',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DiscoveryVertexDatasetFilter'];

coerce 'DiscoveryVertexDatasetFilter',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryVertexDatasetFilter'->new($_) };

declare 'RepeatedDiscoveryVertexDatasetFilter',
    as ArrayRef[DiscoveryVertexDatasetFilter()];

coerce 'RepeatedDiscoveryVertexDatasetFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryVertexDatasetFilter'->new($_) } @$_ ] };

declare 'MapStringDiscoveryVertexDatasetFilter',
    as HashRef[DiscoveryVertexDatasetFilter()];

declare 'VertexDatasetCollection',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::VertexDatasetCollection'];

coerce 'VertexDatasetCollection',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::VertexDatasetCollection'->new($_) };

declare 'RepeatedVertexDatasetCollection',
    as ArrayRef[VertexDatasetCollection()];

coerce 'RepeatedVertexDatasetCollection',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::VertexDatasetCollection'->new($_) } @$_ ] };

declare 'MapStringVertexDatasetCollection',
    as HashRef[VertexDatasetCollection()];

declare 'VertexDatasetRegexes',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::VertexDatasetRegexes'];

coerce 'VertexDatasetRegexes',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::VertexDatasetRegexes'->new($_) };

declare 'RepeatedVertexDatasetRegexes',
    as ArrayRef[VertexDatasetRegexes()];

coerce 'RepeatedVertexDatasetRegexes',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::VertexDatasetRegexes'->new($_) } @$_ ] };

declare 'MapStringVertexDatasetRegexes',
    as HashRef[VertexDatasetRegexes()];

declare 'VertexDatasetRegex',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::VertexDatasetRegex'];

coerce 'VertexDatasetRegex',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::VertexDatasetRegex'->new($_) };

declare 'RepeatedVertexDatasetRegex',
    as ArrayRef[VertexDatasetRegex()];

coerce 'RepeatedVertexDatasetRegex',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::VertexDatasetRegex'->new($_) } @$_ ] };

declare 'MapStringVertexDatasetRegex',
    as HashRef[VertexDatasetRegex()];

declare 'VertexDatasetResourceReference',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::VertexDatasetResourceReference'];

coerce 'VertexDatasetResourceReference',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::VertexDatasetResourceReference'->new($_) };

declare 'RepeatedVertexDatasetResourceReference',
    as ArrayRef[VertexDatasetResourceReference()];

coerce 'RepeatedVertexDatasetResourceReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::VertexDatasetResourceReference'->new($_) } @$_ ] };

declare 'MapStringVertexDatasetResourceReference',
    as HashRef[VertexDatasetResourceReference()];

declare 'DiscoveryVertexDatasetConditions',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DiscoveryVertexDatasetConditions'];

coerce 'DiscoveryVertexDatasetConditions',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryVertexDatasetConditions'->new($_) };

declare 'RepeatedDiscoveryVertexDatasetConditions',
    as ArrayRef[DiscoveryVertexDatasetConditions()];

coerce 'RepeatedDiscoveryVertexDatasetConditions',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryVertexDatasetConditions'->new($_) } @$_ ] };

declare 'MapStringDiscoveryVertexDatasetConditions',
    as HashRef[DiscoveryVertexDatasetConditions()];

declare 'DiscoveryVertexDatasetGenerationCadence',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DiscoveryVertexDatasetGenerationCadence'];

coerce 'DiscoveryVertexDatasetGenerationCadence',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryVertexDatasetGenerationCadence'->new($_) };

declare 'RepeatedDiscoveryVertexDatasetGenerationCadence',
    as ArrayRef[DiscoveryVertexDatasetGenerationCadence()];

coerce 'RepeatedDiscoveryVertexDatasetGenerationCadence',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DiscoveryVertexDatasetGenerationCadence'->new($_) } @$_ ] };

declare 'MapStringDiscoveryVertexDatasetGenerationCadence',
    as HashRef[DiscoveryVertexDatasetGenerationCadence()];

declare 'DlpJob',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DlpJob'];

coerce 'DlpJob',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DlpJob'->new($_) };

declare 'RepeatedDlpJob',
    as ArrayRef[DlpJob()];

coerce 'RepeatedDlpJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DlpJob'->new($_) } @$_ ] };

declare 'MapStringDlpJob',
    as HashRef[DlpJob()];

declare 'JobState',
    as (Int | Str);

declare 'GetDlpJobRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::GetDlpJobRequest'];

coerce 'GetDlpJobRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::GetDlpJobRequest'->new($_) };

declare 'RepeatedGetDlpJobRequest',
    as ArrayRef[GetDlpJobRequest()];

coerce 'RepeatedGetDlpJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::GetDlpJobRequest'->new($_) } @$_ ] };

declare 'MapStringGetDlpJobRequest',
    as HashRef[GetDlpJobRequest()];

declare 'ListDlpJobsRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ListDlpJobsRequest'];

coerce 'ListDlpJobsRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ListDlpJobsRequest'->new($_) };

declare 'RepeatedListDlpJobsRequest',
    as ArrayRef[ListDlpJobsRequest()];

coerce 'RepeatedListDlpJobsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ListDlpJobsRequest'->new($_) } @$_ ] };

declare 'MapStringListDlpJobsRequest',
    as HashRef[ListDlpJobsRequest()];

declare 'ListDlpJobsResponse',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ListDlpJobsResponse'];

coerce 'ListDlpJobsResponse',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ListDlpJobsResponse'->new($_) };

declare 'RepeatedListDlpJobsResponse',
    as ArrayRef[ListDlpJobsResponse()];

coerce 'RepeatedListDlpJobsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ListDlpJobsResponse'->new($_) } @$_ ] };

declare 'MapStringListDlpJobsResponse',
    as HashRef[ListDlpJobsResponse()];

declare 'CancelDlpJobRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::CancelDlpJobRequest'];

coerce 'CancelDlpJobRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::CancelDlpJobRequest'->new($_) };

declare 'RepeatedCancelDlpJobRequest',
    as ArrayRef[CancelDlpJobRequest()];

coerce 'RepeatedCancelDlpJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::CancelDlpJobRequest'->new($_) } @$_ ] };

declare 'MapStringCancelDlpJobRequest',
    as HashRef[CancelDlpJobRequest()];

declare 'FinishDlpJobRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::FinishDlpJobRequest'];

coerce 'FinishDlpJobRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::FinishDlpJobRequest'->new($_) };

declare 'RepeatedFinishDlpJobRequest',
    as ArrayRef[FinishDlpJobRequest()];

coerce 'RepeatedFinishDlpJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::FinishDlpJobRequest'->new($_) } @$_ ] };

declare 'MapStringFinishDlpJobRequest',
    as HashRef[FinishDlpJobRequest()];

declare 'DeleteDlpJobRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DeleteDlpJobRequest'];

coerce 'DeleteDlpJobRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DeleteDlpJobRequest'->new($_) };

declare 'RepeatedDeleteDlpJobRequest',
    as ArrayRef[DeleteDlpJobRequest()];

coerce 'RepeatedDeleteDlpJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DeleteDlpJobRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDlpJobRequest',
    as HashRef[DeleteDlpJobRequest()];

declare 'CreateDeidentifyTemplateRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::CreateDeidentifyTemplateRequest'];

coerce 'CreateDeidentifyTemplateRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::CreateDeidentifyTemplateRequest'->new($_) };

declare 'RepeatedCreateDeidentifyTemplateRequest',
    as ArrayRef[CreateDeidentifyTemplateRequest()];

coerce 'RepeatedCreateDeidentifyTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::CreateDeidentifyTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDeidentifyTemplateRequest',
    as HashRef[CreateDeidentifyTemplateRequest()];

declare 'UpdateDeidentifyTemplateRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::UpdateDeidentifyTemplateRequest'];

coerce 'UpdateDeidentifyTemplateRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::UpdateDeidentifyTemplateRequest'->new($_) };

declare 'RepeatedUpdateDeidentifyTemplateRequest',
    as ArrayRef[UpdateDeidentifyTemplateRequest()];

coerce 'RepeatedUpdateDeidentifyTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::UpdateDeidentifyTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDeidentifyTemplateRequest',
    as HashRef[UpdateDeidentifyTemplateRequest()];

declare 'GetDeidentifyTemplateRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::GetDeidentifyTemplateRequest'];

coerce 'GetDeidentifyTemplateRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::GetDeidentifyTemplateRequest'->new($_) };

declare 'RepeatedGetDeidentifyTemplateRequest',
    as ArrayRef[GetDeidentifyTemplateRequest()];

coerce 'RepeatedGetDeidentifyTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::GetDeidentifyTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringGetDeidentifyTemplateRequest',
    as HashRef[GetDeidentifyTemplateRequest()];

declare 'ListDeidentifyTemplatesRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ListDeidentifyTemplatesRequest'];

coerce 'ListDeidentifyTemplatesRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ListDeidentifyTemplatesRequest'->new($_) };

declare 'RepeatedListDeidentifyTemplatesRequest',
    as ArrayRef[ListDeidentifyTemplatesRequest()];

coerce 'RepeatedListDeidentifyTemplatesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ListDeidentifyTemplatesRequest'->new($_) } @$_ ] };

declare 'MapStringListDeidentifyTemplatesRequest',
    as HashRef[ListDeidentifyTemplatesRequest()];

declare 'ListDeidentifyTemplatesResponse',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ListDeidentifyTemplatesResponse'];

coerce 'ListDeidentifyTemplatesResponse',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ListDeidentifyTemplatesResponse'->new($_) };

declare 'RepeatedListDeidentifyTemplatesResponse',
    as ArrayRef[ListDeidentifyTemplatesResponse()];

coerce 'RepeatedListDeidentifyTemplatesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ListDeidentifyTemplatesResponse'->new($_) } @$_ ] };

declare 'MapStringListDeidentifyTemplatesResponse',
    as HashRef[ListDeidentifyTemplatesResponse()];

declare 'DeleteDeidentifyTemplateRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DeleteDeidentifyTemplateRequest'];

coerce 'DeleteDeidentifyTemplateRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DeleteDeidentifyTemplateRequest'->new($_) };

declare 'RepeatedDeleteDeidentifyTemplateRequest',
    as ArrayRef[DeleteDeidentifyTemplateRequest()];

coerce 'RepeatedDeleteDeidentifyTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DeleteDeidentifyTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDeidentifyTemplateRequest',
    as HashRef[DeleteDeidentifyTemplateRequest()];

declare 'LargeCustomDictionaryConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::LargeCustomDictionaryConfig'];

coerce 'LargeCustomDictionaryConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::LargeCustomDictionaryConfig'->new($_) };

declare 'RepeatedLargeCustomDictionaryConfig',
    as ArrayRef[LargeCustomDictionaryConfig()];

coerce 'RepeatedLargeCustomDictionaryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::LargeCustomDictionaryConfig'->new($_) } @$_ ] };

declare 'MapStringLargeCustomDictionaryConfig',
    as HashRef[LargeCustomDictionaryConfig()];

declare 'LargeCustomDictionaryStats',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::LargeCustomDictionaryStats'];

coerce 'LargeCustomDictionaryStats',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::LargeCustomDictionaryStats'->new($_) };

declare 'RepeatedLargeCustomDictionaryStats',
    as ArrayRef[LargeCustomDictionaryStats()];

coerce 'RepeatedLargeCustomDictionaryStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::LargeCustomDictionaryStats'->new($_) } @$_ ] };

declare 'MapStringLargeCustomDictionaryStats',
    as HashRef[LargeCustomDictionaryStats()];

declare 'StoredInfoTypeConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::StoredInfoTypeConfig'];

coerce 'StoredInfoTypeConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::StoredInfoTypeConfig'->new($_) };

declare 'RepeatedStoredInfoTypeConfig',
    as ArrayRef[StoredInfoTypeConfig()];

coerce 'RepeatedStoredInfoTypeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::StoredInfoTypeConfig'->new($_) } @$_ ] };

declare 'MapStringStoredInfoTypeConfig',
    as HashRef[StoredInfoTypeConfig()];

declare 'StoredInfoTypeStats',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::StoredInfoTypeStats'];

coerce 'StoredInfoTypeStats',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::StoredInfoTypeStats'->new($_) };

declare 'RepeatedStoredInfoTypeStats',
    as ArrayRef[StoredInfoTypeStats()];

coerce 'RepeatedStoredInfoTypeStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::StoredInfoTypeStats'->new($_) } @$_ ] };

declare 'MapStringStoredInfoTypeStats',
    as HashRef[StoredInfoTypeStats()];

declare 'StoredInfoTypeVersion',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::StoredInfoTypeVersion'];

coerce 'StoredInfoTypeVersion',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::StoredInfoTypeVersion'->new($_) };

declare 'RepeatedStoredInfoTypeVersion',
    as ArrayRef[StoredInfoTypeVersion()];

coerce 'RepeatedStoredInfoTypeVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::StoredInfoTypeVersion'->new($_) } @$_ ] };

declare 'MapStringStoredInfoTypeVersion',
    as HashRef[StoredInfoTypeVersion()];

declare 'StoredInfoType',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::StoredInfoType'];

coerce 'StoredInfoType',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::StoredInfoType'->new($_) };

declare 'RepeatedStoredInfoType',
    as ArrayRef[StoredInfoType()];

coerce 'RepeatedStoredInfoType',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::StoredInfoType'->new($_) } @$_ ] };

declare 'MapStringStoredInfoType',
    as HashRef[StoredInfoType()];

declare 'CreateStoredInfoTypeRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::CreateStoredInfoTypeRequest'];

coerce 'CreateStoredInfoTypeRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::CreateStoredInfoTypeRequest'->new($_) };

declare 'RepeatedCreateStoredInfoTypeRequest',
    as ArrayRef[CreateStoredInfoTypeRequest()];

coerce 'RepeatedCreateStoredInfoTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::CreateStoredInfoTypeRequest'->new($_) } @$_ ] };

declare 'MapStringCreateStoredInfoTypeRequest',
    as HashRef[CreateStoredInfoTypeRequest()];

declare 'UpdateStoredInfoTypeRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::UpdateStoredInfoTypeRequest'];

coerce 'UpdateStoredInfoTypeRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::UpdateStoredInfoTypeRequest'->new($_) };

declare 'RepeatedUpdateStoredInfoTypeRequest',
    as ArrayRef[UpdateStoredInfoTypeRequest()];

coerce 'RepeatedUpdateStoredInfoTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::UpdateStoredInfoTypeRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateStoredInfoTypeRequest',
    as HashRef[UpdateStoredInfoTypeRequest()];

declare 'GetStoredInfoTypeRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::GetStoredInfoTypeRequest'];

coerce 'GetStoredInfoTypeRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::GetStoredInfoTypeRequest'->new($_) };

declare 'RepeatedGetStoredInfoTypeRequest',
    as ArrayRef[GetStoredInfoTypeRequest()];

coerce 'RepeatedGetStoredInfoTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::GetStoredInfoTypeRequest'->new($_) } @$_ ] };

declare 'MapStringGetStoredInfoTypeRequest',
    as HashRef[GetStoredInfoTypeRequest()];

declare 'ListStoredInfoTypesRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ListStoredInfoTypesRequest'];

coerce 'ListStoredInfoTypesRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ListStoredInfoTypesRequest'->new($_) };

declare 'RepeatedListStoredInfoTypesRequest',
    as ArrayRef[ListStoredInfoTypesRequest()];

coerce 'RepeatedListStoredInfoTypesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ListStoredInfoTypesRequest'->new($_) } @$_ ] };

declare 'MapStringListStoredInfoTypesRequest',
    as HashRef[ListStoredInfoTypesRequest()];

declare 'ListStoredInfoTypesResponse',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ListStoredInfoTypesResponse'];

coerce 'ListStoredInfoTypesResponse',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ListStoredInfoTypesResponse'->new($_) };

declare 'RepeatedListStoredInfoTypesResponse',
    as ArrayRef[ListStoredInfoTypesResponse()];

coerce 'RepeatedListStoredInfoTypesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ListStoredInfoTypesResponse'->new($_) } @$_ ] };

declare 'MapStringListStoredInfoTypesResponse',
    as HashRef[ListStoredInfoTypesResponse()];

declare 'DeleteStoredInfoTypeRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DeleteStoredInfoTypeRequest'];

coerce 'DeleteStoredInfoTypeRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DeleteStoredInfoTypeRequest'->new($_) };

declare 'RepeatedDeleteStoredInfoTypeRequest',
    as ArrayRef[DeleteStoredInfoTypeRequest()];

coerce 'RepeatedDeleteStoredInfoTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DeleteStoredInfoTypeRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteStoredInfoTypeRequest',
    as HashRef[DeleteStoredInfoTypeRequest()];

declare 'HybridInspectJobTriggerRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::HybridInspectJobTriggerRequest'];

coerce 'HybridInspectJobTriggerRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::HybridInspectJobTriggerRequest'->new($_) };

declare 'RepeatedHybridInspectJobTriggerRequest',
    as ArrayRef[HybridInspectJobTriggerRequest()];

coerce 'RepeatedHybridInspectJobTriggerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::HybridInspectJobTriggerRequest'->new($_) } @$_ ] };

declare 'MapStringHybridInspectJobTriggerRequest',
    as HashRef[HybridInspectJobTriggerRequest()];

declare 'HybridInspectDlpJobRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::HybridInspectDlpJobRequest'];

coerce 'HybridInspectDlpJobRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::HybridInspectDlpJobRequest'->new($_) };

declare 'RepeatedHybridInspectDlpJobRequest',
    as ArrayRef[HybridInspectDlpJobRequest()];

coerce 'RepeatedHybridInspectDlpJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::HybridInspectDlpJobRequest'->new($_) } @$_ ] };

declare 'MapStringHybridInspectDlpJobRequest',
    as HashRef[HybridInspectDlpJobRequest()];

declare 'HybridContentItem',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::HybridContentItem'];

coerce 'HybridContentItem',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::HybridContentItem'->new($_) };

declare 'RepeatedHybridContentItem',
    as ArrayRef[HybridContentItem()];

coerce 'RepeatedHybridContentItem',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::HybridContentItem'->new($_) } @$_ ] };

declare 'MapStringHybridContentItem',
    as HashRef[HybridContentItem()];

declare 'HybridFindingDetails',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::HybridFindingDetails'];

coerce 'HybridFindingDetails',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::HybridFindingDetails'->new($_) };

declare 'RepeatedHybridFindingDetails',
    as ArrayRef[HybridFindingDetails()];

coerce 'RepeatedHybridFindingDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::HybridFindingDetails'->new($_) } @$_ ] };

declare 'MapStringHybridFindingDetails',
    as HashRef[HybridFindingDetails()];

declare 'LabelsEntry',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::HybridFindingDetails::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::HybridFindingDetails::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::HybridFindingDetails::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'HybridInspectResponse',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::HybridInspectResponse'];

coerce 'HybridInspectResponse',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::HybridInspectResponse'->new($_) };

declare 'RepeatedHybridInspectResponse',
    as ArrayRef[HybridInspectResponse()];

coerce 'RepeatedHybridInspectResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::HybridInspectResponse'->new($_) } @$_ ] };

declare 'MapStringHybridInspectResponse',
    as HashRef[HybridInspectResponse()];

declare 'ImageContainmentType',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ImageContainmentType'];

coerce 'ImageContainmentType',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ImageContainmentType'->new($_) };

declare 'RepeatedImageContainmentType',
    as ArrayRef[ImageContainmentType()];

coerce 'RepeatedImageContainmentType',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ImageContainmentType'->new($_) } @$_ ] };

declare 'MapStringImageContainmentType',
    as HashRef[ImageContainmentType()];

declare 'Overlap',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::Overlap'];

coerce 'Overlap',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::Overlap'->new($_) };

declare 'RepeatedOverlap',
    as ArrayRef[Overlap()];

coerce 'RepeatedOverlap',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::Overlap'->new($_) } @$_ ] };

declare 'MapStringOverlap',
    as HashRef[Overlap()];

declare 'Encloses',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::Encloses'];

coerce 'Encloses',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::Encloses'->new($_) };

declare 'RepeatedEncloses',
    as ArrayRef[Encloses()];

coerce 'RepeatedEncloses',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::Encloses'->new($_) } @$_ ] };

declare 'MapStringEncloses',
    as HashRef[Encloses()];

declare 'FullyInside',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::FullyInside'];

coerce 'FullyInside',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::FullyInside'->new($_) };

declare 'RepeatedFullyInside',
    as ArrayRef[FullyInside()];

coerce 'RepeatedFullyInside',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::FullyInside'->new($_) } @$_ ] };

declare 'MapStringFullyInside',
    as HashRef[FullyInside()];

declare 'ListProjectDataProfilesRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ListProjectDataProfilesRequest'];

coerce 'ListProjectDataProfilesRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ListProjectDataProfilesRequest'->new($_) };

declare 'RepeatedListProjectDataProfilesRequest',
    as ArrayRef[ListProjectDataProfilesRequest()];

coerce 'RepeatedListProjectDataProfilesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ListProjectDataProfilesRequest'->new($_) } @$_ ] };

declare 'MapStringListProjectDataProfilesRequest',
    as HashRef[ListProjectDataProfilesRequest()];

declare 'ListProjectDataProfilesResponse',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ListProjectDataProfilesResponse'];

coerce 'ListProjectDataProfilesResponse',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ListProjectDataProfilesResponse'->new($_) };

declare 'RepeatedListProjectDataProfilesResponse',
    as ArrayRef[ListProjectDataProfilesResponse()];

coerce 'RepeatedListProjectDataProfilesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ListProjectDataProfilesResponse'->new($_) } @$_ ] };

declare 'MapStringListProjectDataProfilesResponse',
    as HashRef[ListProjectDataProfilesResponse()];

declare 'ListTableDataProfilesRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ListTableDataProfilesRequest'];

coerce 'ListTableDataProfilesRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ListTableDataProfilesRequest'->new($_) };

declare 'RepeatedListTableDataProfilesRequest',
    as ArrayRef[ListTableDataProfilesRequest()];

coerce 'RepeatedListTableDataProfilesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ListTableDataProfilesRequest'->new($_) } @$_ ] };

declare 'MapStringListTableDataProfilesRequest',
    as HashRef[ListTableDataProfilesRequest()];

declare 'ListTableDataProfilesResponse',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ListTableDataProfilesResponse'];

coerce 'ListTableDataProfilesResponse',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ListTableDataProfilesResponse'->new($_) };

declare 'RepeatedListTableDataProfilesResponse',
    as ArrayRef[ListTableDataProfilesResponse()];

coerce 'RepeatedListTableDataProfilesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ListTableDataProfilesResponse'->new($_) } @$_ ] };

declare 'MapStringListTableDataProfilesResponse',
    as HashRef[ListTableDataProfilesResponse()];

declare 'ListColumnDataProfilesRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ListColumnDataProfilesRequest'];

coerce 'ListColumnDataProfilesRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ListColumnDataProfilesRequest'->new($_) };

declare 'RepeatedListColumnDataProfilesRequest',
    as ArrayRef[ListColumnDataProfilesRequest()];

coerce 'RepeatedListColumnDataProfilesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ListColumnDataProfilesRequest'->new($_) } @$_ ] };

declare 'MapStringListColumnDataProfilesRequest',
    as HashRef[ListColumnDataProfilesRequest()];

declare 'ListColumnDataProfilesResponse',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ListColumnDataProfilesResponse'];

coerce 'ListColumnDataProfilesResponse',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ListColumnDataProfilesResponse'->new($_) };

declare 'RepeatedListColumnDataProfilesResponse',
    as ArrayRef[ListColumnDataProfilesResponse()];

coerce 'RepeatedListColumnDataProfilesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ListColumnDataProfilesResponse'->new($_) } @$_ ] };

declare 'MapStringListColumnDataProfilesResponse',
    as HashRef[ListColumnDataProfilesResponse()];

declare 'DataRiskLevel',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DataRiskLevel'];

coerce 'DataRiskLevel',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DataRiskLevel'->new($_) };

declare 'RepeatedDataRiskLevel',
    as ArrayRef[DataRiskLevel()];

coerce 'RepeatedDataRiskLevel',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DataRiskLevel'->new($_) } @$_ ] };

declare 'MapStringDataRiskLevel',
    as HashRef[DataRiskLevel()];

declare 'DataRiskLevelScore',
    as (Int | Str);

declare 'ProjectDataProfile',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ProjectDataProfile'];

coerce 'ProjectDataProfile',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ProjectDataProfile'->new($_) };

declare 'RepeatedProjectDataProfile',
    as ArrayRef[ProjectDataProfile()];

coerce 'RepeatedProjectDataProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ProjectDataProfile'->new($_) } @$_ ] };

declare 'MapStringProjectDataProfile',
    as HashRef[ProjectDataProfile()];

declare 'DataProfileConfigSnapshot',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DataProfileConfigSnapshot'];

coerce 'DataProfileConfigSnapshot',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DataProfileConfigSnapshot'->new($_) };

declare 'RepeatedDataProfileConfigSnapshot',
    as ArrayRef[DataProfileConfigSnapshot()];

coerce 'RepeatedDataProfileConfigSnapshot',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DataProfileConfigSnapshot'->new($_) } @$_ ] };

declare 'MapStringDataProfileConfigSnapshot',
    as HashRef[DataProfileConfigSnapshot()];

declare 'TableDataProfile',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::TableDataProfile'];

coerce 'TableDataProfile',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::TableDataProfile'->new($_) };

declare 'RepeatedTableDataProfile',
    as ArrayRef[TableDataProfile()];

coerce 'RepeatedTableDataProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::TableDataProfile'->new($_) } @$_ ] };

declare 'MapStringTableDataProfile',
    as HashRef[TableDataProfile()];

declare 'State',
    as (Int | Str);

declare 'ResourceLabelsEntry',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::TableDataProfile::ResourceLabelsEntry'];

coerce 'ResourceLabelsEntry',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::TableDataProfile::ResourceLabelsEntry'->new($_) };

declare 'RepeatedResourceLabelsEntry',
    as ArrayRef[ResourceLabelsEntry()];

coerce 'RepeatedResourceLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::TableDataProfile::ResourceLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringResourceLabelsEntry',
    as HashRef[ResourceLabelsEntry()];

declare 'ProfileStatus',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ProfileStatus'];

coerce 'ProfileStatus',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ProfileStatus'->new($_) };

declare 'RepeatedProfileStatus',
    as ArrayRef[ProfileStatus()];

coerce 'RepeatedProfileStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ProfileStatus'->new($_) } @$_ ] };

declare 'MapStringProfileStatus',
    as HashRef[ProfileStatus()];

declare 'InfoTypeSummary',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::InfoTypeSummary'];

coerce 'InfoTypeSummary',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::InfoTypeSummary'->new($_) };

declare 'RepeatedInfoTypeSummary',
    as ArrayRef[InfoTypeSummary()];

coerce 'RepeatedInfoTypeSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::InfoTypeSummary'->new($_) } @$_ ] };

declare 'MapStringInfoTypeSummary',
    as HashRef[InfoTypeSummary()];

declare 'OtherInfoTypeSummary',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::OtherInfoTypeSummary'];

coerce 'OtherInfoTypeSummary',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::OtherInfoTypeSummary'->new($_) };

declare 'RepeatedOtherInfoTypeSummary',
    as ArrayRef[OtherInfoTypeSummary()];

coerce 'RepeatedOtherInfoTypeSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::OtherInfoTypeSummary'->new($_) } @$_ ] };

declare 'MapStringOtherInfoTypeSummary',
    as HashRef[OtherInfoTypeSummary()];

declare 'ColumnDataProfile',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ColumnDataProfile'];

coerce 'ColumnDataProfile',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ColumnDataProfile'->new($_) };

declare 'RepeatedColumnDataProfile',
    as ArrayRef[ColumnDataProfile()];

coerce 'RepeatedColumnDataProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ColumnDataProfile'->new($_) } @$_ ] };

declare 'MapStringColumnDataProfile',
    as HashRef[ColumnDataProfile()];

declare 'State',
    as (Int | Str);

declare 'ColumnDataType',
    as (Int | Str);

declare 'ColumnPolicyState',
    as (Int | Str);

declare 'FileStoreDataProfile',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::FileStoreDataProfile'];

coerce 'FileStoreDataProfile',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::FileStoreDataProfile'->new($_) };

declare 'RepeatedFileStoreDataProfile',
    as ArrayRef[FileStoreDataProfile()];

coerce 'RepeatedFileStoreDataProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::FileStoreDataProfile'->new($_) } @$_ ] };

declare 'MapStringFileStoreDataProfile',
    as HashRef[FileStoreDataProfile()];

declare 'State',
    as (Int | Str);

declare 'ResourceAttributesEntry',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::FileStoreDataProfile::ResourceAttributesEntry'];

coerce 'ResourceAttributesEntry',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::FileStoreDataProfile::ResourceAttributesEntry'->new($_) };

declare 'RepeatedResourceAttributesEntry',
    as ArrayRef[ResourceAttributesEntry()];

coerce 'RepeatedResourceAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::FileStoreDataProfile::ResourceAttributesEntry'->new($_) } @$_ ] };

declare 'MapStringResourceAttributesEntry',
    as HashRef[ResourceAttributesEntry()];

declare 'ResourceLabelsEntry',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::FileStoreDataProfile::ResourceLabelsEntry'];

coerce 'ResourceLabelsEntry',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::FileStoreDataProfile::ResourceLabelsEntry'->new($_) };

declare 'RepeatedResourceLabelsEntry',
    as ArrayRef[ResourceLabelsEntry()];

coerce 'RepeatedResourceLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::FileStoreDataProfile::ResourceLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringResourceLabelsEntry',
    as HashRef[ResourceLabelsEntry()];

declare 'Tag',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::Tag'];

coerce 'Tag',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::Tag'->new($_) };

declare 'RepeatedTag',
    as ArrayRef[Tag()];

coerce 'RepeatedTag',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::Tag'->new($_) } @$_ ] };

declare 'MapStringTag',
    as HashRef[Tag()];

declare 'TagFilters',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::TagFilters'];

coerce 'TagFilters',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::TagFilters'->new($_) };

declare 'RepeatedTagFilters',
    as ArrayRef[TagFilters()];

coerce 'RepeatedTagFilters',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::TagFilters'->new($_) } @$_ ] };

declare 'MapStringTagFilters',
    as HashRef[TagFilters()];

declare 'TagFilter',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::TagFilter'];

coerce 'TagFilter',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::TagFilter'->new($_) };

declare 'RepeatedTagFilter',
    as ArrayRef[TagFilter()];

coerce 'RepeatedTagFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::TagFilter'->new($_) } @$_ ] };

declare 'MapStringTagFilter',
    as HashRef[TagFilter()];

declare 'RelatedResource',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::RelatedResource'];

coerce 'RelatedResource',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::RelatedResource'->new($_) };

declare 'RepeatedRelatedResource',
    as ArrayRef[RelatedResource()];

coerce 'RepeatedRelatedResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::RelatedResource'->new($_) } @$_ ] };

declare 'MapStringRelatedResource',
    as HashRef[RelatedResource()];

declare 'FileStoreInfoTypeSummary',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::FileStoreInfoTypeSummary'];

coerce 'FileStoreInfoTypeSummary',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::FileStoreInfoTypeSummary'->new($_) };

declare 'RepeatedFileStoreInfoTypeSummary',
    as ArrayRef[FileStoreInfoTypeSummary()];

coerce 'RepeatedFileStoreInfoTypeSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::FileStoreInfoTypeSummary'->new($_) } @$_ ] };

declare 'MapStringFileStoreInfoTypeSummary',
    as HashRef[FileStoreInfoTypeSummary()];

declare 'FileExtensionInfo',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::FileExtensionInfo'];

coerce 'FileExtensionInfo',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::FileExtensionInfo'->new($_) };

declare 'RepeatedFileExtensionInfo',
    as ArrayRef[FileExtensionInfo()];

coerce 'RepeatedFileExtensionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::FileExtensionInfo'->new($_) } @$_ ] };

declare 'MapStringFileExtensionInfo',
    as HashRef[FileExtensionInfo()];

declare 'FileClusterSummary',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::FileClusterSummary'];

coerce 'FileClusterSummary',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::FileClusterSummary'->new($_) };

declare 'RepeatedFileClusterSummary',
    as ArrayRef[FileClusterSummary()];

coerce 'RepeatedFileClusterSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::FileClusterSummary'->new($_) } @$_ ] };

declare 'MapStringFileClusterSummary',
    as HashRef[FileClusterSummary()];

declare 'GetProjectDataProfileRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::GetProjectDataProfileRequest'];

coerce 'GetProjectDataProfileRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::GetProjectDataProfileRequest'->new($_) };

declare 'RepeatedGetProjectDataProfileRequest',
    as ArrayRef[GetProjectDataProfileRequest()];

coerce 'RepeatedGetProjectDataProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::GetProjectDataProfileRequest'->new($_) } @$_ ] };

declare 'MapStringGetProjectDataProfileRequest',
    as HashRef[GetProjectDataProfileRequest()];

declare 'GetFileStoreDataProfileRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::GetFileStoreDataProfileRequest'];

coerce 'GetFileStoreDataProfileRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::GetFileStoreDataProfileRequest'->new($_) };

declare 'RepeatedGetFileStoreDataProfileRequest',
    as ArrayRef[GetFileStoreDataProfileRequest()];

coerce 'RepeatedGetFileStoreDataProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::GetFileStoreDataProfileRequest'->new($_) } @$_ ] };

declare 'MapStringGetFileStoreDataProfileRequest',
    as HashRef[GetFileStoreDataProfileRequest()];

declare 'ListFileStoreDataProfilesRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ListFileStoreDataProfilesRequest'];

coerce 'ListFileStoreDataProfilesRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ListFileStoreDataProfilesRequest'->new($_) };

declare 'RepeatedListFileStoreDataProfilesRequest',
    as ArrayRef[ListFileStoreDataProfilesRequest()];

coerce 'RepeatedListFileStoreDataProfilesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ListFileStoreDataProfilesRequest'->new($_) } @$_ ] };

declare 'MapStringListFileStoreDataProfilesRequest',
    as HashRef[ListFileStoreDataProfilesRequest()];

declare 'ListFileStoreDataProfilesResponse',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ListFileStoreDataProfilesResponse'];

coerce 'ListFileStoreDataProfilesResponse',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ListFileStoreDataProfilesResponse'->new($_) };

declare 'RepeatedListFileStoreDataProfilesResponse',
    as ArrayRef[ListFileStoreDataProfilesResponse()];

coerce 'RepeatedListFileStoreDataProfilesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ListFileStoreDataProfilesResponse'->new($_) } @$_ ] };

declare 'MapStringListFileStoreDataProfilesResponse',
    as HashRef[ListFileStoreDataProfilesResponse()];

declare 'DeleteFileStoreDataProfileRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DeleteFileStoreDataProfileRequest'];

coerce 'DeleteFileStoreDataProfileRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DeleteFileStoreDataProfileRequest'->new($_) };

declare 'RepeatedDeleteFileStoreDataProfileRequest',
    as ArrayRef[DeleteFileStoreDataProfileRequest()];

coerce 'RepeatedDeleteFileStoreDataProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DeleteFileStoreDataProfileRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteFileStoreDataProfileRequest',
    as HashRef[DeleteFileStoreDataProfileRequest()];

declare 'GetTableDataProfileRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::GetTableDataProfileRequest'];

coerce 'GetTableDataProfileRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::GetTableDataProfileRequest'->new($_) };

declare 'RepeatedGetTableDataProfileRequest',
    as ArrayRef[GetTableDataProfileRequest()];

coerce 'RepeatedGetTableDataProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::GetTableDataProfileRequest'->new($_) } @$_ ] };

declare 'MapStringGetTableDataProfileRequest',
    as HashRef[GetTableDataProfileRequest()];

declare 'GetColumnDataProfileRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::GetColumnDataProfileRequest'];

coerce 'GetColumnDataProfileRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::GetColumnDataProfileRequest'->new($_) };

declare 'RepeatedGetColumnDataProfileRequest',
    as ArrayRef[GetColumnDataProfileRequest()];

coerce 'RepeatedGetColumnDataProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::GetColumnDataProfileRequest'->new($_) } @$_ ] };

declare 'MapStringGetColumnDataProfileRequest',
    as HashRef[GetColumnDataProfileRequest()];

declare 'DataProfilePubSubCondition',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DataProfilePubSubCondition'];

coerce 'DataProfilePubSubCondition',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DataProfilePubSubCondition'->new($_) };

declare 'RepeatedDataProfilePubSubCondition',
    as ArrayRef[DataProfilePubSubCondition()];

coerce 'RepeatedDataProfilePubSubCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DataProfilePubSubCondition'->new($_) } @$_ ] };

declare 'MapStringDataProfilePubSubCondition',
    as HashRef[DataProfilePubSubCondition()];

declare 'ProfileScoreBucket',
    as (Int | Str);

declare 'PubSubCondition',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DataProfilePubSubCondition::PubSubCondition'];

coerce 'PubSubCondition',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DataProfilePubSubCondition::PubSubCondition'->new($_) };

declare 'RepeatedPubSubCondition',
    as ArrayRef[PubSubCondition()];

coerce 'RepeatedPubSubCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DataProfilePubSubCondition::PubSubCondition'->new($_) } @$_ ] };

declare 'MapStringPubSubCondition',
    as HashRef[PubSubCondition()];

declare 'PubSubExpressions',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DataProfilePubSubCondition::PubSubExpressions'];

coerce 'PubSubExpressions',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DataProfilePubSubCondition::PubSubExpressions'->new($_) };

declare 'RepeatedPubSubExpressions',
    as ArrayRef[PubSubExpressions()];

coerce 'RepeatedPubSubExpressions',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DataProfilePubSubCondition::PubSubExpressions'->new($_) } @$_ ] };

declare 'MapStringPubSubExpressions',
    as HashRef[PubSubExpressions()];

declare 'PubSubLogicalOperator',
    as (Int | Str);

declare 'DataProfilePubSubMessage',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DataProfilePubSubMessage'];

coerce 'DataProfilePubSubMessage',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DataProfilePubSubMessage'->new($_) };

declare 'RepeatedDataProfilePubSubMessage',
    as ArrayRef[DataProfilePubSubMessage()];

coerce 'RepeatedDataProfilePubSubMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DataProfilePubSubMessage'->new($_) } @$_ ] };

declare 'MapStringDataProfilePubSubMessage',
    as HashRef[DataProfilePubSubMessage()];

declare 'CreateConnectionRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::CreateConnectionRequest'];

coerce 'CreateConnectionRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::CreateConnectionRequest'->new($_) };

declare 'RepeatedCreateConnectionRequest',
    as ArrayRef[CreateConnectionRequest()];

coerce 'RepeatedCreateConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::CreateConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateConnectionRequest',
    as HashRef[CreateConnectionRequest()];

declare 'GetConnectionRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::GetConnectionRequest'];

coerce 'GetConnectionRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::GetConnectionRequest'->new($_) };

declare 'RepeatedGetConnectionRequest',
    as ArrayRef[GetConnectionRequest()];

coerce 'RepeatedGetConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::GetConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringGetConnectionRequest',
    as HashRef[GetConnectionRequest()];

declare 'ListConnectionsRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ListConnectionsRequest'];

coerce 'ListConnectionsRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ListConnectionsRequest'->new($_) };

declare 'RepeatedListConnectionsRequest',
    as ArrayRef[ListConnectionsRequest()];

coerce 'RepeatedListConnectionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ListConnectionsRequest'->new($_) } @$_ ] };

declare 'MapStringListConnectionsRequest',
    as HashRef[ListConnectionsRequest()];

declare 'SearchConnectionsRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::SearchConnectionsRequest'];

coerce 'SearchConnectionsRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::SearchConnectionsRequest'->new($_) };

declare 'RepeatedSearchConnectionsRequest',
    as ArrayRef[SearchConnectionsRequest()];

coerce 'RepeatedSearchConnectionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::SearchConnectionsRequest'->new($_) } @$_ ] };

declare 'MapStringSearchConnectionsRequest',
    as HashRef[SearchConnectionsRequest()];

declare 'ListConnectionsResponse',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ListConnectionsResponse'];

coerce 'ListConnectionsResponse',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ListConnectionsResponse'->new($_) };

declare 'RepeatedListConnectionsResponse',
    as ArrayRef[ListConnectionsResponse()];

coerce 'RepeatedListConnectionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ListConnectionsResponse'->new($_) } @$_ ] };

declare 'MapStringListConnectionsResponse',
    as HashRef[ListConnectionsResponse()];

declare 'SearchConnectionsResponse',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::SearchConnectionsResponse'];

coerce 'SearchConnectionsResponse',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::SearchConnectionsResponse'->new($_) };

declare 'RepeatedSearchConnectionsResponse',
    as ArrayRef[SearchConnectionsResponse()];

coerce 'RepeatedSearchConnectionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::SearchConnectionsResponse'->new($_) } @$_ ] };

declare 'MapStringSearchConnectionsResponse',
    as HashRef[SearchConnectionsResponse()];

declare 'UpdateConnectionRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::UpdateConnectionRequest'];

coerce 'UpdateConnectionRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::UpdateConnectionRequest'->new($_) };

declare 'RepeatedUpdateConnectionRequest',
    as ArrayRef[UpdateConnectionRequest()];

coerce 'RepeatedUpdateConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::UpdateConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateConnectionRequest',
    as HashRef[UpdateConnectionRequest()];

declare 'DeleteConnectionRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DeleteConnectionRequest'];

coerce 'DeleteConnectionRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DeleteConnectionRequest'->new($_) };

declare 'RepeatedDeleteConnectionRequest',
    as ArrayRef[DeleteConnectionRequest()];

coerce 'RepeatedDeleteConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DeleteConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteConnectionRequest',
    as HashRef[DeleteConnectionRequest()];

declare 'Connection',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::Connection'];

coerce 'Connection',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::Connection'->new($_) };

declare 'RepeatedConnection',
    as ArrayRef[Connection()];

coerce 'RepeatedConnection',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::Connection'->new($_) } @$_ ] };

declare 'MapStringConnection',
    as HashRef[Connection()];

declare 'SecretManagerCredential',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::SecretManagerCredential'];

coerce 'SecretManagerCredential',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::SecretManagerCredential'->new($_) };

declare 'RepeatedSecretManagerCredential',
    as ArrayRef[SecretManagerCredential()];

coerce 'RepeatedSecretManagerCredential',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::SecretManagerCredential'->new($_) } @$_ ] };

declare 'MapStringSecretManagerCredential',
    as HashRef[SecretManagerCredential()];

declare 'CloudSqlIamCredential',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::CloudSqlIamCredential'];

coerce 'CloudSqlIamCredential',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::CloudSqlIamCredential'->new($_) };

declare 'RepeatedCloudSqlIamCredential',
    as ArrayRef[CloudSqlIamCredential()];

coerce 'RepeatedCloudSqlIamCredential',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::CloudSqlIamCredential'->new($_) } @$_ ] };

declare 'MapStringCloudSqlIamCredential',
    as HashRef[CloudSqlIamCredential()];

declare 'CloudSqlProperties',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::CloudSqlProperties'];

coerce 'CloudSqlProperties',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::CloudSqlProperties'->new($_) };

declare 'RepeatedCloudSqlProperties',
    as ArrayRef[CloudSqlProperties()];

coerce 'RepeatedCloudSqlProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::CloudSqlProperties'->new($_) } @$_ ] };

declare 'MapStringCloudSqlProperties',
    as HashRef[CloudSqlProperties()];

declare 'DatabaseEngine',
    as (Int | Str);

declare 'DeleteTableDataProfileRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DeleteTableDataProfileRequest'];

coerce 'DeleteTableDataProfileRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DeleteTableDataProfileRequest'->new($_) };

declare 'RepeatedDeleteTableDataProfileRequest',
    as ArrayRef[DeleteTableDataProfileRequest()];

coerce 'RepeatedDeleteTableDataProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DeleteTableDataProfileRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTableDataProfileRequest',
    as HashRef[DeleteTableDataProfileRequest()];

declare 'DataSourceType',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DataSourceType'];

coerce 'DataSourceType',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DataSourceType'->new($_) };

declare 'RepeatedDataSourceType',
    as ArrayRef[DataSourceType()];

coerce 'RepeatedDataSourceType',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DataSourceType'->new($_) } @$_ ] };

declare 'MapStringDataSourceType',
    as HashRef[DataSourceType()];

declare 'FileClusterType',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::FileClusterType'];

coerce 'FileClusterType',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::FileClusterType'->new($_) };

declare 'RepeatedFileClusterType',
    as ArrayRef[FileClusterType()];

coerce 'RepeatedFileClusterType',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::FileClusterType'->new($_) } @$_ ] };

declare 'MapStringFileClusterType',
    as HashRef[FileClusterType()];

declare 'Cluster',
    as (Int | Str);

declare 'ProcessingLocation',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ProcessingLocation'];

coerce 'ProcessingLocation',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ProcessingLocation'->new($_) };

declare 'RepeatedProcessingLocation',
    as ArrayRef[ProcessingLocation()];

coerce 'RepeatedProcessingLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ProcessingLocation'->new($_) } @$_ ] };

declare 'MapStringProcessingLocation',
    as HashRef[ProcessingLocation()];

declare 'MultiRegionProcessing',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ProcessingLocation::MultiRegionProcessing'];

coerce 'MultiRegionProcessing',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ProcessingLocation::MultiRegionProcessing'->new($_) };

declare 'RepeatedMultiRegionProcessing',
    as ArrayRef[MultiRegionProcessing()];

coerce 'RepeatedMultiRegionProcessing',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ProcessingLocation::MultiRegionProcessing'->new($_) } @$_ ] };

declare 'MapStringMultiRegionProcessing',
    as HashRef[MultiRegionProcessing()];

declare 'GlobalProcessing',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ProcessingLocation::GlobalProcessing'];

coerce 'GlobalProcessing',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ProcessingLocation::GlobalProcessing'->new($_) };

declare 'RepeatedGlobalProcessing',
    as ArrayRef[GlobalProcessing()];

coerce 'RepeatedGlobalProcessing',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ProcessingLocation::GlobalProcessing'->new($_) } @$_ ] };

declare 'MapStringGlobalProcessing',
    as HashRef[GlobalProcessing()];

declare 'ImageFallbackLocation',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ProcessingLocation::ImageFallbackLocation'];

coerce 'ImageFallbackLocation',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ProcessingLocation::ImageFallbackLocation'->new($_) };

declare 'RepeatedImageFallbackLocation',
    as ArrayRef[ImageFallbackLocation()];

coerce 'RepeatedImageFallbackLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ProcessingLocation::ImageFallbackLocation'->new($_) } @$_ ] };

declare 'MapStringImageFallbackLocation',
    as HashRef[ImageFallbackLocation()];

declare 'DocumentFallbackLocation',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ProcessingLocation::DocumentFallbackLocation'];

coerce 'DocumentFallbackLocation',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ProcessingLocation::DocumentFallbackLocation'->new($_) };

declare 'RepeatedDocumentFallbackLocation',
    as ArrayRef[DocumentFallbackLocation()];

coerce 'RepeatedDocumentFallbackLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ProcessingLocation::DocumentFallbackLocation'->new($_) } @$_ ] };

declare 'MapStringDocumentFallbackLocation',
    as HashRef[DocumentFallbackLocation()];

declare 'SaveToGcsFindingsOutput',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::SaveToGcsFindingsOutput'];

coerce 'SaveToGcsFindingsOutput',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::SaveToGcsFindingsOutput'->new($_) };

declare 'RepeatedSaveToGcsFindingsOutput',
    as ArrayRef[SaveToGcsFindingsOutput()];

coerce 'RepeatedSaveToGcsFindingsOutput',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::SaveToGcsFindingsOutput'->new($_) } @$_ ] };

declare 'MapStringSaveToGcsFindingsOutput',
    as HashRef[SaveToGcsFindingsOutput()];

declare 'Domain',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::Domain'];

coerce 'Domain',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::Domain'->new($_) };

declare 'RepeatedDomain',
    as ArrayRef[Domain()];

coerce 'RepeatedDomain',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::Domain'->new($_) } @$_ ] };

declare 'MapStringDomain',
    as HashRef[Domain()];

declare 'Category',
    as (Int | Str);

declare 'Signal',
    as (Int | Str);

declare 'CreateContentPolicyRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::CreateContentPolicyRequest'];

coerce 'CreateContentPolicyRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::CreateContentPolicyRequest'->new($_) };

declare 'RepeatedCreateContentPolicyRequest',
    as ArrayRef[CreateContentPolicyRequest()];

coerce 'RepeatedCreateContentPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::CreateContentPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateContentPolicyRequest',
    as HashRef[CreateContentPolicyRequest()];

declare 'GetContentPolicyRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::GetContentPolicyRequest'];

coerce 'GetContentPolicyRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::GetContentPolicyRequest'->new($_) };

declare 'RepeatedGetContentPolicyRequest',
    as ArrayRef[GetContentPolicyRequest()];

coerce 'RepeatedGetContentPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::GetContentPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetContentPolicyRequest',
    as HashRef[GetContentPolicyRequest()];

declare 'ListContentPoliciesRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ListContentPoliciesRequest'];

coerce 'ListContentPoliciesRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ListContentPoliciesRequest'->new($_) };

declare 'RepeatedListContentPoliciesRequest',
    as ArrayRef[ListContentPoliciesRequest()];

coerce 'RepeatedListContentPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ListContentPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringListContentPoliciesRequest',
    as HashRef[ListContentPoliciesRequest()];

declare 'ListContentPoliciesResponse',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ListContentPoliciesResponse'];

coerce 'ListContentPoliciesResponse',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ListContentPoliciesResponse'->new($_) };

declare 'RepeatedListContentPoliciesResponse',
    as ArrayRef[ListContentPoliciesResponse()];

coerce 'RepeatedListContentPoliciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ListContentPoliciesResponse'->new($_) } @$_ ] };

declare 'MapStringListContentPoliciesResponse',
    as HashRef[ListContentPoliciesResponse()];

declare 'UpdateContentPolicyRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::UpdateContentPolicyRequest'];

coerce 'UpdateContentPolicyRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::UpdateContentPolicyRequest'->new($_) };

declare 'RepeatedUpdateContentPolicyRequest',
    as ArrayRef[UpdateContentPolicyRequest()];

coerce 'RepeatedUpdateContentPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::UpdateContentPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateContentPolicyRequest',
    as HashRef[UpdateContentPolicyRequest()];

declare 'DeleteContentPolicyRequest',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::DeleteContentPolicyRequest'];

coerce 'DeleteContentPolicyRequest',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::DeleteContentPolicyRequest'->new($_) };

declare 'RepeatedDeleteContentPolicyRequest',
    as ArrayRef[DeleteContentPolicyRequest()];

coerce 'RepeatedDeleteContentPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::DeleteContentPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteContentPolicyRequest',
    as HashRef[DeleteContentPolicyRequest()];

declare 'ContentPolicy',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ContentPolicy'];

coerce 'ContentPolicy',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ContentPolicy'->new($_) };

declare 'RepeatedContentPolicy',
    as ArrayRef[ContentPolicy()];

coerce 'RepeatedContentPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ContentPolicy'->new($_) } @$_ ] };

declare 'MapStringContentPolicy',
    as HashRef[ContentPolicy()];

declare 'PolicyAction',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ContentPolicy::PolicyAction'];

coerce 'PolicyAction',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ContentPolicy::PolicyAction'->new($_) };

declare 'RepeatedPolicyAction',
    as ArrayRef[PolicyAction()];

coerce 'RepeatedPolicyAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ContentPolicy::PolicyAction'->new($_) } @$_ ] };

declare 'MapStringPolicyAction',
    as HashRef[PolicyAction()];

declare 'PolicyRule',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ContentPolicy::PolicyRule'];

coerce 'PolicyRule',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ContentPolicy::PolicyRule'->new($_) };

declare 'RepeatedPolicyRule',
    as ArrayRef[PolicyRule()];

coerce 'RepeatedPolicyRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ContentPolicy::PolicyRule'->new($_) } @$_ ] };

declare 'MapStringPolicyRule',
    as HashRef[PolicyRule()];

declare 'PolicyCondition',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ContentPolicy::PolicyRule::PolicyCondition'];

coerce 'PolicyCondition',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ContentPolicy::PolicyRule::PolicyCondition'->new($_) };

declare 'RepeatedPolicyCondition',
    as ArrayRef[PolicyCondition()];

coerce 'RepeatedPolicyCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ContentPolicy::PolicyRule::PolicyCondition'->new($_) } @$_ ] };

declare 'MapStringPolicyCondition',
    as HashRef[PolicyCondition()];

declare 'InfoTypeCondition',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ContentPolicy::PolicyRule::PolicyCondition::InfoTypeCondition'];

coerce 'InfoTypeCondition',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ContentPolicy::PolicyRule::PolicyCondition::InfoTypeCondition'->new($_) };

declare 'RepeatedInfoTypeCondition',
    as ArrayRef[InfoTypeCondition()];

coerce 'RepeatedInfoTypeCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ContentPolicy::PolicyRule::PolicyCondition::InfoTypeCondition'->new($_) } @$_ ] };

declare 'MapStringInfoTypeCondition',
    as HashRef[InfoTypeCondition()];

declare 'InfoTypes',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ContentPolicy::PolicyRule::PolicyCondition::InfoTypeCondition::InfoTypes'];

coerce 'InfoTypes',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ContentPolicy::PolicyRule::PolicyCondition::InfoTypeCondition::InfoTypes'->new($_) };

declare 'RepeatedInfoTypes',
    as ArrayRef[InfoTypes()];

coerce 'RepeatedInfoTypes',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ContentPolicy::PolicyRule::PolicyCondition::InfoTypeCondition::InfoTypes'->new($_) } @$_ ] };

declare 'MapStringInfoTypes',
    as HashRef[InfoTypes()];

declare 'LoggingConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ContentPolicy::LoggingConfig'];

coerce 'LoggingConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ContentPolicy::LoggingConfig'->new($_) };

declare 'RepeatedLoggingConfig',
    as ArrayRef[LoggingConfig()];

coerce 'RepeatedLoggingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ContentPolicy::LoggingConfig'->new($_) } @$_ ] };

declare 'MapStringLoggingConfig',
    as HashRef[LoggingConfig()];

declare 'LogToBigQuery',
    as InstanceOf['Google::Privacy::Dlp::V2::Dlp::ContentPolicy::LoggingConfig::LogToBigQuery'];

coerce 'LogToBigQuery',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Dlp::ContentPolicy::LoggingConfig::LogToBigQuery'->new($_) };

declare 'RepeatedLogToBigQuery',
    as ArrayRef[LogToBigQuery()];

coerce 'RepeatedLogToBigQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Dlp::ContentPolicy::LoggingConfig::LogToBigQuery'->new($_) } @$_ ] };

declare 'MapStringLogToBigQuery',
    as HashRef[LogToBigQuery()];

1;

__END__

=head1 NAME

Google::Privacy::Dlp::V2::Dlp::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
