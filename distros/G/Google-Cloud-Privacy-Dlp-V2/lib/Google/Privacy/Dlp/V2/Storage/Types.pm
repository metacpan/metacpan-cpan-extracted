package Google::Privacy::Dlp::V2::Storage::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Likelihood',
    as (Int | Str);

declare 'FileType',
    as (Int | Str);

declare 'InfoType',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::InfoType'];

coerce 'InfoType',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::InfoType'->new($_) };

declare 'RepeatedInfoType',
    as ArrayRef[InfoType()];

coerce 'RepeatedInfoType',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::InfoType'->new($_) } @$_ ] };

declare 'MapStringInfoType',
    as HashRef[InfoType()];

declare 'SensitivityScore',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::SensitivityScore'];

coerce 'SensitivityScore',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::SensitivityScore'->new($_) };

declare 'RepeatedSensitivityScore',
    as ArrayRef[SensitivityScore()];

coerce 'RepeatedSensitivityScore',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::SensitivityScore'->new($_) } @$_ ] };

declare 'MapStringSensitivityScore',
    as HashRef[SensitivityScore()];

declare 'SensitivityScoreLevel',
    as (Int | Str);

declare 'StoredType',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::StoredType'];

coerce 'StoredType',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::StoredType'->new($_) };

declare 'RepeatedStoredType',
    as ArrayRef[StoredType()];

coerce 'RepeatedStoredType',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::StoredType'->new($_) } @$_ ] };

declare 'MapStringStoredType',
    as HashRef[StoredType()];

declare 'CustomInfoType',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::CustomInfoType'];

coerce 'CustomInfoType',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::CustomInfoType'->new($_) };

declare 'RepeatedCustomInfoType',
    as ArrayRef[CustomInfoType()];

coerce 'RepeatedCustomInfoType',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::CustomInfoType'->new($_) } @$_ ] };

declare 'MapStringCustomInfoType',
    as HashRef[CustomInfoType()];

declare 'ExclusionType',
    as (Int | Str);

declare 'Dictionary',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::CustomInfoType::Dictionary'];

coerce 'Dictionary',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::CustomInfoType::Dictionary'->new($_) };

declare 'RepeatedDictionary',
    as ArrayRef[Dictionary()];

coerce 'RepeatedDictionary',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::CustomInfoType::Dictionary'->new($_) } @$_ ] };

declare 'MapStringDictionary',
    as HashRef[Dictionary()];

declare 'WordList',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::CustomInfoType::Dictionary::WordList'];

coerce 'WordList',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::CustomInfoType::Dictionary::WordList'->new($_) };

declare 'RepeatedWordList',
    as ArrayRef[WordList()];

coerce 'RepeatedWordList',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::CustomInfoType::Dictionary::WordList'->new($_) } @$_ ] };

declare 'MapStringWordList',
    as HashRef[WordList()];

declare 'Regex',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::CustomInfoType::Regex'];

coerce 'Regex',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::CustomInfoType::Regex'->new($_) };

declare 'RepeatedRegex',
    as ArrayRef[Regex()];

coerce 'RepeatedRegex',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::CustomInfoType::Regex'->new($_) } @$_ ] };

declare 'MapStringRegex',
    as HashRef[Regex()];

declare 'SurrogateType',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::CustomInfoType::SurrogateType'];

coerce 'SurrogateType',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::CustomInfoType::SurrogateType'->new($_) };

declare 'RepeatedSurrogateType',
    as ArrayRef[SurrogateType()];

coerce 'RepeatedSurrogateType',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::CustomInfoType::SurrogateType'->new($_) } @$_ ] };

declare 'MapStringSurrogateType',
    as HashRef[SurrogateType()];

declare 'MetadataKeyValueExpression',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::CustomInfoType::MetadataKeyValueExpression'];

coerce 'MetadataKeyValueExpression',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::CustomInfoType::MetadataKeyValueExpression'->new($_) };

declare 'RepeatedMetadataKeyValueExpression',
    as ArrayRef[MetadataKeyValueExpression()];

coerce 'RepeatedMetadataKeyValueExpression',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::CustomInfoType::MetadataKeyValueExpression'->new($_) } @$_ ] };

declare 'MapStringMetadataKeyValueExpression',
    as HashRef[MetadataKeyValueExpression()];

declare 'FileLabelInfoType',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::CustomInfoType::FileLabelInfoType'];

coerce 'FileLabelInfoType',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::CustomInfoType::FileLabelInfoType'->new($_) };

declare 'RepeatedFileLabelInfoType',
    as ArrayRef[FileLabelInfoType()];

coerce 'RepeatedFileLabelInfoType',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::CustomInfoType::FileLabelInfoType'->new($_) } @$_ ] };

declare 'MapStringFileLabelInfoType',
    as HashRef[FileLabelInfoType()];

declare 'SensitivityLabel',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::CustomInfoType::FileLabelInfoType::SensitivityLabel'];

coerce 'SensitivityLabel',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::CustomInfoType::FileLabelInfoType::SensitivityLabel'->new($_) };

declare 'RepeatedSensitivityLabel',
    as ArrayRef[SensitivityLabel()];

coerce 'RepeatedSensitivityLabel',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::CustomInfoType::FileLabelInfoType::SensitivityLabel'->new($_) } @$_ ] };

declare 'MapStringSensitivityLabel',
    as HashRef[SensitivityLabel()];

declare 'GoogleDriveLabel',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::CustomInfoType::FileLabelInfoType::GoogleDriveLabel'];

coerce 'GoogleDriveLabel',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::CustomInfoType::FileLabelInfoType::GoogleDriveLabel'->new($_) };

declare 'RepeatedGoogleDriveLabel',
    as ArrayRef[GoogleDriveLabel()];

coerce 'RepeatedGoogleDriveLabel',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::CustomInfoType::FileLabelInfoType::GoogleDriveLabel'->new($_) } @$_ ] };

declare 'MapStringGoogleDriveLabel',
    as HashRef[GoogleDriveLabel()];

declare 'LabelField',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::CustomInfoType::FileLabelInfoType::GoogleDriveLabel::LabelField'];

coerce 'LabelField',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::CustomInfoType::FileLabelInfoType::GoogleDriveLabel::LabelField'->new($_) };

declare 'RepeatedLabelField',
    as ArrayRef[LabelField()];

coerce 'RepeatedLabelField',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::CustomInfoType::FileLabelInfoType::GoogleDriveLabel::LabelField'->new($_) } @$_ ] };

declare 'MapStringLabelField',
    as HashRef[LabelField()];

declare 'DetectionRule',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::CustomInfoType::DetectionRule'];

coerce 'DetectionRule',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::CustomInfoType::DetectionRule'->new($_) };

declare 'RepeatedDetectionRule',
    as ArrayRef[DetectionRule()];

coerce 'RepeatedDetectionRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::CustomInfoType::DetectionRule'->new($_) } @$_ ] };

declare 'MapStringDetectionRule',
    as HashRef[DetectionRule()];

declare 'Proximity',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::CustomInfoType::DetectionRule::Proximity'];

coerce 'Proximity',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::CustomInfoType::DetectionRule::Proximity'->new($_) };

declare 'RepeatedProximity',
    as ArrayRef[Proximity()];

coerce 'RepeatedProximity',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::CustomInfoType::DetectionRule::Proximity'->new($_) } @$_ ] };

declare 'MapStringProximity',
    as HashRef[Proximity()];

declare 'LikelihoodAdjustment',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::CustomInfoType::DetectionRule::LikelihoodAdjustment'];

coerce 'LikelihoodAdjustment',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::CustomInfoType::DetectionRule::LikelihoodAdjustment'->new($_) };

declare 'RepeatedLikelihoodAdjustment',
    as ArrayRef[LikelihoodAdjustment()];

coerce 'RepeatedLikelihoodAdjustment',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::CustomInfoType::DetectionRule::LikelihoodAdjustment'->new($_) } @$_ ] };

declare 'MapStringLikelihoodAdjustment',
    as HashRef[LikelihoodAdjustment()];

declare 'HotwordRule',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::CustomInfoType::DetectionRule::HotwordRule'];

coerce 'HotwordRule',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::CustomInfoType::DetectionRule::HotwordRule'->new($_) };

declare 'RepeatedHotwordRule',
    as ArrayRef[HotwordRule()];

coerce 'RepeatedHotwordRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::CustomInfoType::DetectionRule::HotwordRule'->new($_) } @$_ ] };

declare 'MapStringHotwordRule',
    as HashRef[HotwordRule()];

declare 'FieldId',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::FieldId'];

coerce 'FieldId',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::FieldId'->new($_) };

declare 'RepeatedFieldId',
    as ArrayRef[FieldId()];

coerce 'RepeatedFieldId',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::FieldId'->new($_) } @$_ ] };

declare 'MapStringFieldId',
    as HashRef[FieldId()];

declare 'PartitionId',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::PartitionId'];

coerce 'PartitionId',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::PartitionId'->new($_) };

declare 'RepeatedPartitionId',
    as ArrayRef[PartitionId()];

coerce 'RepeatedPartitionId',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::PartitionId'->new($_) } @$_ ] };

declare 'MapStringPartitionId',
    as HashRef[PartitionId()];

declare 'KindExpression',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::KindExpression'];

coerce 'KindExpression',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::KindExpression'->new($_) };

declare 'RepeatedKindExpression',
    as ArrayRef[KindExpression()];

coerce 'RepeatedKindExpression',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::KindExpression'->new($_) } @$_ ] };

declare 'MapStringKindExpression',
    as HashRef[KindExpression()];

declare 'DatastoreOptions',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::DatastoreOptions'];

coerce 'DatastoreOptions',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::DatastoreOptions'->new($_) };

declare 'RepeatedDatastoreOptions',
    as ArrayRef[DatastoreOptions()];

coerce 'RepeatedDatastoreOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::DatastoreOptions'->new($_) } @$_ ] };

declare 'MapStringDatastoreOptions',
    as HashRef[DatastoreOptions()];

declare 'CloudStorageRegexFileSet',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::CloudStorageRegexFileSet'];

coerce 'CloudStorageRegexFileSet',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::CloudStorageRegexFileSet'->new($_) };

declare 'RepeatedCloudStorageRegexFileSet',
    as ArrayRef[CloudStorageRegexFileSet()];

coerce 'RepeatedCloudStorageRegexFileSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::CloudStorageRegexFileSet'->new($_) } @$_ ] };

declare 'MapStringCloudStorageRegexFileSet',
    as HashRef[CloudStorageRegexFileSet()];

declare 'CloudStorageOptions',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::CloudStorageOptions'];

coerce 'CloudStorageOptions',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::CloudStorageOptions'->new($_) };

declare 'RepeatedCloudStorageOptions',
    as ArrayRef[CloudStorageOptions()];

coerce 'RepeatedCloudStorageOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::CloudStorageOptions'->new($_) } @$_ ] };

declare 'MapStringCloudStorageOptions',
    as HashRef[CloudStorageOptions()];

declare 'SampleMethod',
    as (Int | Str);

declare 'FileSet',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::CloudStorageOptions::FileSet'];

coerce 'FileSet',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::CloudStorageOptions::FileSet'->new($_) };

declare 'RepeatedFileSet',
    as ArrayRef[FileSet()];

coerce 'RepeatedFileSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::CloudStorageOptions::FileSet'->new($_) } @$_ ] };

declare 'MapStringFileSet',
    as HashRef[FileSet()];

declare 'CloudStorageFileSet',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::CloudStorageFileSet'];

coerce 'CloudStorageFileSet',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::CloudStorageFileSet'->new($_) };

declare 'RepeatedCloudStorageFileSet',
    as ArrayRef[CloudStorageFileSet()];

coerce 'RepeatedCloudStorageFileSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::CloudStorageFileSet'->new($_) } @$_ ] };

declare 'MapStringCloudStorageFileSet',
    as HashRef[CloudStorageFileSet()];

declare 'CloudStoragePath',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::CloudStoragePath'];

coerce 'CloudStoragePath',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::CloudStoragePath'->new($_) };

declare 'RepeatedCloudStoragePath',
    as ArrayRef[CloudStoragePath()];

coerce 'RepeatedCloudStoragePath',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::CloudStoragePath'->new($_) } @$_ ] };

declare 'MapStringCloudStoragePath',
    as HashRef[CloudStoragePath()];

declare 'BigQueryOptions',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::BigQueryOptions'];

coerce 'BigQueryOptions',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::BigQueryOptions'->new($_) };

declare 'RepeatedBigQueryOptions',
    as ArrayRef[BigQueryOptions()];

coerce 'RepeatedBigQueryOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::BigQueryOptions'->new($_) } @$_ ] };

declare 'MapStringBigQueryOptions',
    as HashRef[BigQueryOptions()];

declare 'SampleMethod',
    as (Int | Str);

declare 'StorageConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::StorageConfig'];

coerce 'StorageConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::StorageConfig'->new($_) };

declare 'RepeatedStorageConfig',
    as ArrayRef[StorageConfig()];

coerce 'RepeatedStorageConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::StorageConfig'->new($_) } @$_ ] };

declare 'MapStringStorageConfig',
    as HashRef[StorageConfig()];

declare 'TimespanConfig',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::StorageConfig::TimespanConfig'];

coerce 'TimespanConfig',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::StorageConfig::TimespanConfig'->new($_) };

declare 'RepeatedTimespanConfig',
    as ArrayRef[TimespanConfig()];

coerce 'RepeatedTimespanConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::StorageConfig::TimespanConfig'->new($_) } @$_ ] };

declare 'MapStringTimespanConfig',
    as HashRef[TimespanConfig()];

declare 'HybridOptions',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::HybridOptions'];

coerce 'HybridOptions',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::HybridOptions'->new($_) };

declare 'RepeatedHybridOptions',
    as ArrayRef[HybridOptions()];

coerce 'RepeatedHybridOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::HybridOptions'->new($_) } @$_ ] };

declare 'MapStringHybridOptions',
    as HashRef[HybridOptions()];

declare 'LabelsEntry',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::HybridOptions::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::HybridOptions::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::HybridOptions::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'BigQueryKey',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::BigQueryKey'];

coerce 'BigQueryKey',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::BigQueryKey'->new($_) };

declare 'RepeatedBigQueryKey',
    as ArrayRef[BigQueryKey()];

coerce 'RepeatedBigQueryKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::BigQueryKey'->new($_) } @$_ ] };

declare 'MapStringBigQueryKey',
    as HashRef[BigQueryKey()];

declare 'DatastoreKey',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::DatastoreKey'];

coerce 'DatastoreKey',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::DatastoreKey'->new($_) };

declare 'RepeatedDatastoreKey',
    as ArrayRef[DatastoreKey()];

coerce 'RepeatedDatastoreKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::DatastoreKey'->new($_) } @$_ ] };

declare 'MapStringDatastoreKey',
    as HashRef[DatastoreKey()];

declare 'Key',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::Key'];

coerce 'Key',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::Key'->new($_) };

declare 'RepeatedKey',
    as ArrayRef[Key()];

coerce 'RepeatedKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::Key'->new($_) } @$_ ] };

declare 'MapStringKey',
    as HashRef[Key()];

declare 'PathElement',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::Key::PathElement'];

coerce 'PathElement',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::Key::PathElement'->new($_) };

declare 'RepeatedPathElement',
    as ArrayRef[PathElement()];

coerce 'RepeatedPathElement',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::Key::PathElement'->new($_) } @$_ ] };

declare 'MapStringPathElement',
    as HashRef[PathElement()];

declare 'RecordKey',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::RecordKey'];

coerce 'RecordKey',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::RecordKey'->new($_) };

declare 'RepeatedRecordKey',
    as ArrayRef[RecordKey()];

coerce 'RepeatedRecordKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::RecordKey'->new($_) } @$_ ] };

declare 'MapStringRecordKey',
    as HashRef[RecordKey()];

declare 'BigQueryTable',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::BigQueryTable'];

coerce 'BigQueryTable',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::BigQueryTable'->new($_) };

declare 'RepeatedBigQueryTable',
    as ArrayRef[BigQueryTable()];

coerce 'RepeatedBigQueryTable',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::BigQueryTable'->new($_) } @$_ ] };

declare 'MapStringBigQueryTable',
    as HashRef[BigQueryTable()];

declare 'TableReference',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::TableReference'];

coerce 'TableReference',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::TableReference'->new($_) };

declare 'RepeatedTableReference',
    as ArrayRef[TableReference()];

coerce 'RepeatedTableReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::TableReference'->new($_) } @$_ ] };

declare 'MapStringTableReference',
    as HashRef[TableReference()];

declare 'BigQueryField',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::BigQueryField'];

coerce 'BigQueryField',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::BigQueryField'->new($_) };

declare 'RepeatedBigQueryField',
    as ArrayRef[BigQueryField()];

coerce 'RepeatedBigQueryField',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::BigQueryField'->new($_) } @$_ ] };

declare 'MapStringBigQueryField',
    as HashRef[BigQueryField()];

declare 'EntityId',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::EntityId'];

coerce 'EntityId',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::EntityId'->new($_) };

declare 'RepeatedEntityId',
    as ArrayRef[EntityId()];

coerce 'RepeatedEntityId',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::EntityId'->new($_) } @$_ ] };

declare 'MapStringEntityId',
    as HashRef[EntityId()];

declare 'TableOptions',
    as InstanceOf['Google::Privacy::Dlp::V2::Storage::TableOptions'];

coerce 'TableOptions',
    from HashRef, via { 'Google::Privacy::Dlp::V2::Storage::TableOptions'->new($_) };

declare 'RepeatedTableOptions',
    as ArrayRef[TableOptions()];

coerce 'RepeatedTableOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Privacy::Dlp::V2::Storage::TableOptions'->new($_) } @$_ ] };

declare 'MapStringTableOptions',
    as HashRef[TableOptions()];

1;

__END__

=head1 NAME

Google::Privacy::Dlp::V2::Storage::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
