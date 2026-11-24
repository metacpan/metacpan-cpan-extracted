package Google::Cloud::Translation::V3::TranslationService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TransliterationConfig',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::TransliterationConfig'];

coerce 'TransliterationConfig',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::TransliterationConfig'->new($_) };

declare 'RepeatedTransliterationConfig',
    as ArrayRef[TransliterationConfig()];

coerce 'RepeatedTransliterationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::TransliterationConfig'->new($_) } @$_ ] };

declare 'MapStringTransliterationConfig',
    as HashRef[TransliterationConfig()];

declare 'TranslateTextRequest',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::TranslateTextRequest'];

coerce 'TranslateTextRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::TranslateTextRequest'->new($_) };

declare 'RepeatedTranslateTextRequest',
    as ArrayRef[TranslateTextRequest()];

coerce 'RepeatedTranslateTextRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::TranslateTextRequest'->new($_) } @$_ ] };

declare 'MapStringTranslateTextRequest',
    as HashRef[TranslateTextRequest()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::TranslateTextRequest::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::TranslateTextRequest::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::TranslateTextRequest::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'TranslateTextResponse',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::TranslateTextResponse'];

coerce 'TranslateTextResponse',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::TranslateTextResponse'->new($_) };

declare 'RepeatedTranslateTextResponse',
    as ArrayRef[TranslateTextResponse()];

coerce 'RepeatedTranslateTextResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::TranslateTextResponse'->new($_) } @$_ ] };

declare 'MapStringTranslateTextResponse',
    as HashRef[TranslateTextResponse()];

declare 'Translation',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::Translation'];

coerce 'Translation',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::Translation'->new($_) };

declare 'RepeatedTranslation',
    as ArrayRef[Translation()];

coerce 'RepeatedTranslation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::Translation'->new($_) } @$_ ] };

declare 'MapStringTranslation',
    as HashRef[Translation()];

declare 'RomanizeTextRequest',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::RomanizeTextRequest'];

coerce 'RomanizeTextRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::RomanizeTextRequest'->new($_) };

declare 'RepeatedRomanizeTextRequest',
    as ArrayRef[RomanizeTextRequest()];

coerce 'RepeatedRomanizeTextRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::RomanizeTextRequest'->new($_) } @$_ ] };

declare 'MapStringRomanizeTextRequest',
    as HashRef[RomanizeTextRequest()];

declare 'Romanization',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::Romanization'];

coerce 'Romanization',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::Romanization'->new($_) };

declare 'RepeatedRomanization',
    as ArrayRef[Romanization()];

coerce 'RepeatedRomanization',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::Romanization'->new($_) } @$_ ] };

declare 'MapStringRomanization',
    as HashRef[Romanization()];

declare 'RomanizeTextResponse',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::RomanizeTextResponse'];

coerce 'RomanizeTextResponse',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::RomanizeTextResponse'->new($_) };

declare 'RepeatedRomanizeTextResponse',
    as ArrayRef[RomanizeTextResponse()];

coerce 'RepeatedRomanizeTextResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::RomanizeTextResponse'->new($_) } @$_ ] };

declare 'MapStringRomanizeTextResponse',
    as HashRef[RomanizeTextResponse()];

declare 'DetectLanguageRequest',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::DetectLanguageRequest'];

coerce 'DetectLanguageRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::DetectLanguageRequest'->new($_) };

declare 'RepeatedDetectLanguageRequest',
    as ArrayRef[DetectLanguageRequest()];

coerce 'RepeatedDetectLanguageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::DetectLanguageRequest'->new($_) } @$_ ] };

declare 'MapStringDetectLanguageRequest',
    as HashRef[DetectLanguageRequest()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::DetectLanguageRequest::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::DetectLanguageRequest::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::DetectLanguageRequest::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'DetectedLanguage',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::DetectedLanguage'];

coerce 'DetectedLanguage',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::DetectedLanguage'->new($_) };

declare 'RepeatedDetectedLanguage',
    as ArrayRef[DetectedLanguage()];

coerce 'RepeatedDetectedLanguage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::DetectedLanguage'->new($_) } @$_ ] };

declare 'MapStringDetectedLanguage',
    as HashRef[DetectedLanguage()];

declare 'DetectLanguageResponse',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::DetectLanguageResponse'];

coerce 'DetectLanguageResponse',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::DetectLanguageResponse'->new($_) };

declare 'RepeatedDetectLanguageResponse',
    as ArrayRef[DetectLanguageResponse()];

coerce 'RepeatedDetectLanguageResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::DetectLanguageResponse'->new($_) } @$_ ] };

declare 'MapStringDetectLanguageResponse',
    as HashRef[DetectLanguageResponse()];

declare 'GetSupportedLanguagesRequest',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::GetSupportedLanguagesRequest'];

coerce 'GetSupportedLanguagesRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::GetSupportedLanguagesRequest'->new($_) };

declare 'RepeatedGetSupportedLanguagesRequest',
    as ArrayRef[GetSupportedLanguagesRequest()];

coerce 'RepeatedGetSupportedLanguagesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::GetSupportedLanguagesRequest'->new($_) } @$_ ] };

declare 'MapStringGetSupportedLanguagesRequest',
    as HashRef[GetSupportedLanguagesRequest()];

declare 'SupportedLanguages',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::SupportedLanguages'];

coerce 'SupportedLanguages',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::SupportedLanguages'->new($_) };

declare 'RepeatedSupportedLanguages',
    as ArrayRef[SupportedLanguages()];

coerce 'RepeatedSupportedLanguages',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::SupportedLanguages'->new($_) } @$_ ] };

declare 'MapStringSupportedLanguages',
    as HashRef[SupportedLanguages()];

declare 'SupportedLanguage',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::SupportedLanguage'];

coerce 'SupportedLanguage',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::SupportedLanguage'->new($_) };

declare 'RepeatedSupportedLanguage',
    as ArrayRef[SupportedLanguage()];

coerce 'RepeatedSupportedLanguage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::SupportedLanguage'->new($_) } @$_ ] };

declare 'MapStringSupportedLanguage',
    as HashRef[SupportedLanguage()];

declare 'GcsSource',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::GcsSource'];

coerce 'GcsSource',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::GcsSource'->new($_) };

declare 'RepeatedGcsSource',
    as ArrayRef[GcsSource()];

coerce 'RepeatedGcsSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::GcsSource'->new($_) } @$_ ] };

declare 'MapStringGcsSource',
    as HashRef[GcsSource()];

declare 'InputConfig',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::InputConfig'];

coerce 'InputConfig',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::InputConfig'->new($_) };

declare 'RepeatedInputConfig',
    as ArrayRef[InputConfig()];

coerce 'RepeatedInputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::InputConfig'->new($_) } @$_ ] };

declare 'MapStringInputConfig',
    as HashRef[InputConfig()];

declare 'GcsDestination',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::GcsDestination'];

coerce 'GcsDestination',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::GcsDestination'->new($_) };

declare 'RepeatedGcsDestination',
    as ArrayRef[GcsDestination()];

coerce 'RepeatedGcsDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::GcsDestination'->new($_) } @$_ ] };

declare 'MapStringGcsDestination',
    as HashRef[GcsDestination()];

declare 'OutputConfig',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::OutputConfig'];

coerce 'OutputConfig',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::OutputConfig'->new($_) };

declare 'RepeatedOutputConfig',
    as ArrayRef[OutputConfig()];

coerce 'RepeatedOutputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::OutputConfig'->new($_) } @$_ ] };

declare 'MapStringOutputConfig',
    as HashRef[OutputConfig()];

declare 'DocumentInputConfig',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::DocumentInputConfig'];

coerce 'DocumentInputConfig',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::DocumentInputConfig'->new($_) };

declare 'RepeatedDocumentInputConfig',
    as ArrayRef[DocumentInputConfig()];

coerce 'RepeatedDocumentInputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::DocumentInputConfig'->new($_) } @$_ ] };

declare 'MapStringDocumentInputConfig',
    as HashRef[DocumentInputConfig()];

declare 'DocumentOutputConfig',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::DocumentOutputConfig'];

coerce 'DocumentOutputConfig',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::DocumentOutputConfig'->new($_) };

declare 'RepeatedDocumentOutputConfig',
    as ArrayRef[DocumentOutputConfig()];

coerce 'RepeatedDocumentOutputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::DocumentOutputConfig'->new($_) } @$_ ] };

declare 'MapStringDocumentOutputConfig',
    as HashRef[DocumentOutputConfig()];

declare 'TranslateDocumentRequest',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::TranslateDocumentRequest'];

coerce 'TranslateDocumentRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::TranslateDocumentRequest'->new($_) };

declare 'RepeatedTranslateDocumentRequest',
    as ArrayRef[TranslateDocumentRequest()];

coerce 'RepeatedTranslateDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::TranslateDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringTranslateDocumentRequest',
    as HashRef[TranslateDocumentRequest()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::TranslateDocumentRequest::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::TranslateDocumentRequest::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::TranslateDocumentRequest::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'DocumentTranslation',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::DocumentTranslation'];

coerce 'DocumentTranslation',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::DocumentTranslation'->new($_) };

declare 'RepeatedDocumentTranslation',
    as ArrayRef[DocumentTranslation()];

coerce 'RepeatedDocumentTranslation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::DocumentTranslation'->new($_) } @$_ ] };

declare 'MapStringDocumentTranslation',
    as HashRef[DocumentTranslation()];

declare 'TranslateDocumentResponse',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::TranslateDocumentResponse'];

coerce 'TranslateDocumentResponse',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::TranslateDocumentResponse'->new($_) };

declare 'RepeatedTranslateDocumentResponse',
    as ArrayRef[TranslateDocumentResponse()];

coerce 'RepeatedTranslateDocumentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::TranslateDocumentResponse'->new($_) } @$_ ] };

declare 'MapStringTranslateDocumentResponse',
    as HashRef[TranslateDocumentResponse()];

declare 'BatchTranslateTextRequest',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::BatchTranslateTextRequest'];

coerce 'BatchTranslateTextRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::BatchTranslateTextRequest'->new($_) };

declare 'RepeatedBatchTranslateTextRequest',
    as ArrayRef[BatchTranslateTextRequest()];

coerce 'RepeatedBatchTranslateTextRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::BatchTranslateTextRequest'->new($_) } @$_ ] };

declare 'MapStringBatchTranslateTextRequest',
    as HashRef[BatchTranslateTextRequest()];

declare 'ModelsEntry',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::BatchTranslateTextRequest::ModelsEntry'];

coerce 'ModelsEntry',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::BatchTranslateTextRequest::ModelsEntry'->new($_) };

declare 'RepeatedModelsEntry',
    as ArrayRef[ModelsEntry()];

coerce 'RepeatedModelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::BatchTranslateTextRequest::ModelsEntry'->new($_) } @$_ ] };

declare 'MapStringModelsEntry',
    as HashRef[ModelsEntry()];

declare 'GlossariesEntry',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::BatchTranslateTextRequest::GlossariesEntry'];

coerce 'GlossariesEntry',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::BatchTranslateTextRequest::GlossariesEntry'->new($_) };

declare 'RepeatedGlossariesEntry',
    as ArrayRef[GlossariesEntry()];

coerce 'RepeatedGlossariesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::BatchTranslateTextRequest::GlossariesEntry'->new($_) } @$_ ] };

declare 'MapStringGlossariesEntry',
    as HashRef[GlossariesEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::BatchTranslateTextRequest::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::BatchTranslateTextRequest::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::BatchTranslateTextRequest::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'BatchTranslateMetadata',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::BatchTranslateMetadata'];

coerce 'BatchTranslateMetadata',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::BatchTranslateMetadata'->new($_) };

declare 'RepeatedBatchTranslateMetadata',
    as ArrayRef[BatchTranslateMetadata()];

coerce 'RepeatedBatchTranslateMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::BatchTranslateMetadata'->new($_) } @$_ ] };

declare 'MapStringBatchTranslateMetadata',
    as HashRef[BatchTranslateMetadata()];

declare 'State',
    as (Int | Str);

declare 'BatchTranslateResponse',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::BatchTranslateResponse'];

coerce 'BatchTranslateResponse',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::BatchTranslateResponse'->new($_) };

declare 'RepeatedBatchTranslateResponse',
    as ArrayRef[BatchTranslateResponse()];

coerce 'RepeatedBatchTranslateResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::BatchTranslateResponse'->new($_) } @$_ ] };

declare 'MapStringBatchTranslateResponse',
    as HashRef[BatchTranslateResponse()];

declare 'GlossaryInputConfig',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::GlossaryInputConfig'];

coerce 'GlossaryInputConfig',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::GlossaryInputConfig'->new($_) };

declare 'RepeatedGlossaryInputConfig',
    as ArrayRef[GlossaryInputConfig()];

coerce 'RepeatedGlossaryInputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::GlossaryInputConfig'->new($_) } @$_ ] };

declare 'MapStringGlossaryInputConfig',
    as HashRef[GlossaryInputConfig()];

declare 'Glossary',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::Glossary'];

coerce 'Glossary',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::Glossary'->new($_) };

declare 'RepeatedGlossary',
    as ArrayRef[Glossary()];

coerce 'RepeatedGlossary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::Glossary'->new($_) } @$_ ] };

declare 'MapStringGlossary',
    as HashRef[Glossary()];

declare 'LanguageCodePair',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::Glossary::LanguageCodePair'];

coerce 'LanguageCodePair',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::Glossary::LanguageCodePair'->new($_) };

declare 'RepeatedLanguageCodePair',
    as ArrayRef[LanguageCodePair()];

coerce 'RepeatedLanguageCodePair',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::Glossary::LanguageCodePair'->new($_) } @$_ ] };

declare 'MapStringLanguageCodePair',
    as HashRef[LanguageCodePair()];

declare 'LanguageCodesSet',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::Glossary::LanguageCodesSet'];

coerce 'LanguageCodesSet',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::Glossary::LanguageCodesSet'->new($_) };

declare 'RepeatedLanguageCodesSet',
    as ArrayRef[LanguageCodesSet()];

coerce 'RepeatedLanguageCodesSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::Glossary::LanguageCodesSet'->new($_) } @$_ ] };

declare 'MapStringLanguageCodesSet',
    as HashRef[LanguageCodesSet()];

declare 'CreateGlossaryRequest',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::CreateGlossaryRequest'];

coerce 'CreateGlossaryRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::CreateGlossaryRequest'->new($_) };

declare 'RepeatedCreateGlossaryRequest',
    as ArrayRef[CreateGlossaryRequest()];

coerce 'RepeatedCreateGlossaryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::CreateGlossaryRequest'->new($_) } @$_ ] };

declare 'MapStringCreateGlossaryRequest',
    as HashRef[CreateGlossaryRequest()];

declare 'UpdateGlossaryRequest',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::UpdateGlossaryRequest'];

coerce 'UpdateGlossaryRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::UpdateGlossaryRequest'->new($_) };

declare 'RepeatedUpdateGlossaryRequest',
    as ArrayRef[UpdateGlossaryRequest()];

coerce 'RepeatedUpdateGlossaryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::UpdateGlossaryRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateGlossaryRequest',
    as HashRef[UpdateGlossaryRequest()];

declare 'GetGlossaryRequest',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::GetGlossaryRequest'];

coerce 'GetGlossaryRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::GetGlossaryRequest'->new($_) };

declare 'RepeatedGetGlossaryRequest',
    as ArrayRef[GetGlossaryRequest()];

coerce 'RepeatedGetGlossaryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::GetGlossaryRequest'->new($_) } @$_ ] };

declare 'MapStringGetGlossaryRequest',
    as HashRef[GetGlossaryRequest()];

declare 'DeleteGlossaryRequest',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::DeleteGlossaryRequest'];

coerce 'DeleteGlossaryRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::DeleteGlossaryRequest'->new($_) };

declare 'RepeatedDeleteGlossaryRequest',
    as ArrayRef[DeleteGlossaryRequest()];

coerce 'RepeatedDeleteGlossaryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::DeleteGlossaryRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteGlossaryRequest',
    as HashRef[DeleteGlossaryRequest()];

declare 'ListGlossariesRequest',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::ListGlossariesRequest'];

coerce 'ListGlossariesRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::ListGlossariesRequest'->new($_) };

declare 'RepeatedListGlossariesRequest',
    as ArrayRef[ListGlossariesRequest()];

coerce 'RepeatedListGlossariesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::ListGlossariesRequest'->new($_) } @$_ ] };

declare 'MapStringListGlossariesRequest',
    as HashRef[ListGlossariesRequest()];

declare 'ListGlossariesResponse',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::ListGlossariesResponse'];

coerce 'ListGlossariesResponse',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::ListGlossariesResponse'->new($_) };

declare 'RepeatedListGlossariesResponse',
    as ArrayRef[ListGlossariesResponse()];

coerce 'RepeatedListGlossariesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::ListGlossariesResponse'->new($_) } @$_ ] };

declare 'MapStringListGlossariesResponse',
    as HashRef[ListGlossariesResponse()];

declare 'GetGlossaryEntryRequest',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::GetGlossaryEntryRequest'];

coerce 'GetGlossaryEntryRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::GetGlossaryEntryRequest'->new($_) };

declare 'RepeatedGetGlossaryEntryRequest',
    as ArrayRef[GetGlossaryEntryRequest()];

coerce 'RepeatedGetGlossaryEntryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::GetGlossaryEntryRequest'->new($_) } @$_ ] };

declare 'MapStringGetGlossaryEntryRequest',
    as HashRef[GetGlossaryEntryRequest()];

declare 'DeleteGlossaryEntryRequest',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::DeleteGlossaryEntryRequest'];

coerce 'DeleteGlossaryEntryRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::DeleteGlossaryEntryRequest'->new($_) };

declare 'RepeatedDeleteGlossaryEntryRequest',
    as ArrayRef[DeleteGlossaryEntryRequest()];

coerce 'RepeatedDeleteGlossaryEntryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::DeleteGlossaryEntryRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteGlossaryEntryRequest',
    as HashRef[DeleteGlossaryEntryRequest()];

declare 'ListGlossaryEntriesRequest',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::ListGlossaryEntriesRequest'];

coerce 'ListGlossaryEntriesRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::ListGlossaryEntriesRequest'->new($_) };

declare 'RepeatedListGlossaryEntriesRequest',
    as ArrayRef[ListGlossaryEntriesRequest()];

coerce 'RepeatedListGlossaryEntriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::ListGlossaryEntriesRequest'->new($_) } @$_ ] };

declare 'MapStringListGlossaryEntriesRequest',
    as HashRef[ListGlossaryEntriesRequest()];

declare 'ListGlossaryEntriesResponse',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::ListGlossaryEntriesResponse'];

coerce 'ListGlossaryEntriesResponse',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::ListGlossaryEntriesResponse'->new($_) };

declare 'RepeatedListGlossaryEntriesResponse',
    as ArrayRef[ListGlossaryEntriesResponse()];

coerce 'RepeatedListGlossaryEntriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::ListGlossaryEntriesResponse'->new($_) } @$_ ] };

declare 'MapStringListGlossaryEntriesResponse',
    as HashRef[ListGlossaryEntriesResponse()];

declare 'CreateGlossaryEntryRequest',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::CreateGlossaryEntryRequest'];

coerce 'CreateGlossaryEntryRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::CreateGlossaryEntryRequest'->new($_) };

declare 'RepeatedCreateGlossaryEntryRequest',
    as ArrayRef[CreateGlossaryEntryRequest()];

coerce 'RepeatedCreateGlossaryEntryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::CreateGlossaryEntryRequest'->new($_) } @$_ ] };

declare 'MapStringCreateGlossaryEntryRequest',
    as HashRef[CreateGlossaryEntryRequest()];

declare 'UpdateGlossaryEntryRequest',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::UpdateGlossaryEntryRequest'];

coerce 'UpdateGlossaryEntryRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::UpdateGlossaryEntryRequest'->new($_) };

declare 'RepeatedUpdateGlossaryEntryRequest',
    as ArrayRef[UpdateGlossaryEntryRequest()];

coerce 'RepeatedUpdateGlossaryEntryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::UpdateGlossaryEntryRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateGlossaryEntryRequest',
    as HashRef[UpdateGlossaryEntryRequest()];

declare 'CreateGlossaryMetadata',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::CreateGlossaryMetadata'];

coerce 'CreateGlossaryMetadata',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::CreateGlossaryMetadata'->new($_) };

declare 'RepeatedCreateGlossaryMetadata',
    as ArrayRef[CreateGlossaryMetadata()];

coerce 'RepeatedCreateGlossaryMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::CreateGlossaryMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateGlossaryMetadata',
    as HashRef[CreateGlossaryMetadata()];

declare 'State',
    as (Int | Str);

declare 'UpdateGlossaryMetadata',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::UpdateGlossaryMetadata'];

coerce 'UpdateGlossaryMetadata',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::UpdateGlossaryMetadata'->new($_) };

declare 'RepeatedUpdateGlossaryMetadata',
    as ArrayRef[UpdateGlossaryMetadata()];

coerce 'RepeatedUpdateGlossaryMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::UpdateGlossaryMetadata'->new($_) } @$_ ] };

declare 'MapStringUpdateGlossaryMetadata',
    as HashRef[UpdateGlossaryMetadata()];

declare 'State',
    as (Int | Str);

declare 'DeleteGlossaryMetadata',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::DeleteGlossaryMetadata'];

coerce 'DeleteGlossaryMetadata',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::DeleteGlossaryMetadata'->new($_) };

declare 'RepeatedDeleteGlossaryMetadata',
    as ArrayRef[DeleteGlossaryMetadata()];

coerce 'RepeatedDeleteGlossaryMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::DeleteGlossaryMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteGlossaryMetadata',
    as HashRef[DeleteGlossaryMetadata()];

declare 'State',
    as (Int | Str);

declare 'DeleteGlossaryResponse',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::DeleteGlossaryResponse'];

coerce 'DeleteGlossaryResponse',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::DeleteGlossaryResponse'->new($_) };

declare 'RepeatedDeleteGlossaryResponse',
    as ArrayRef[DeleteGlossaryResponse()];

coerce 'RepeatedDeleteGlossaryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::DeleteGlossaryResponse'->new($_) } @$_ ] };

declare 'MapStringDeleteGlossaryResponse',
    as HashRef[DeleteGlossaryResponse()];

declare 'BatchTranslateDocumentRequest',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::BatchTranslateDocumentRequest'];

coerce 'BatchTranslateDocumentRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::BatchTranslateDocumentRequest'->new($_) };

declare 'RepeatedBatchTranslateDocumentRequest',
    as ArrayRef[BatchTranslateDocumentRequest()];

coerce 'RepeatedBatchTranslateDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::BatchTranslateDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringBatchTranslateDocumentRequest',
    as HashRef[BatchTranslateDocumentRequest()];

declare 'ModelsEntry',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::BatchTranslateDocumentRequest::ModelsEntry'];

coerce 'ModelsEntry',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::BatchTranslateDocumentRequest::ModelsEntry'->new($_) };

declare 'RepeatedModelsEntry',
    as ArrayRef[ModelsEntry()];

coerce 'RepeatedModelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::BatchTranslateDocumentRequest::ModelsEntry'->new($_) } @$_ ] };

declare 'MapStringModelsEntry',
    as HashRef[ModelsEntry()];

declare 'GlossariesEntry',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::BatchTranslateDocumentRequest::GlossariesEntry'];

coerce 'GlossariesEntry',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::BatchTranslateDocumentRequest::GlossariesEntry'->new($_) };

declare 'RepeatedGlossariesEntry',
    as ArrayRef[GlossariesEntry()];

coerce 'RepeatedGlossariesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::BatchTranslateDocumentRequest::GlossariesEntry'->new($_) } @$_ ] };

declare 'MapStringGlossariesEntry',
    as HashRef[GlossariesEntry()];

declare 'FormatConversionsEntry',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::BatchTranslateDocumentRequest::FormatConversionsEntry'];

coerce 'FormatConversionsEntry',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::BatchTranslateDocumentRequest::FormatConversionsEntry'->new($_) };

declare 'RepeatedFormatConversionsEntry',
    as ArrayRef[FormatConversionsEntry()];

coerce 'RepeatedFormatConversionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::BatchTranslateDocumentRequest::FormatConversionsEntry'->new($_) } @$_ ] };

declare 'MapStringFormatConversionsEntry',
    as HashRef[FormatConversionsEntry()];

declare 'BatchDocumentInputConfig',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::BatchDocumentInputConfig'];

coerce 'BatchDocumentInputConfig',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::BatchDocumentInputConfig'->new($_) };

declare 'RepeatedBatchDocumentInputConfig',
    as ArrayRef[BatchDocumentInputConfig()];

coerce 'RepeatedBatchDocumentInputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::BatchDocumentInputConfig'->new($_) } @$_ ] };

declare 'MapStringBatchDocumentInputConfig',
    as HashRef[BatchDocumentInputConfig()];

declare 'BatchDocumentOutputConfig',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::BatchDocumentOutputConfig'];

coerce 'BatchDocumentOutputConfig',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::BatchDocumentOutputConfig'->new($_) };

declare 'RepeatedBatchDocumentOutputConfig',
    as ArrayRef[BatchDocumentOutputConfig()];

coerce 'RepeatedBatchDocumentOutputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::BatchDocumentOutputConfig'->new($_) } @$_ ] };

declare 'MapStringBatchDocumentOutputConfig',
    as HashRef[BatchDocumentOutputConfig()];

declare 'BatchTranslateDocumentResponse',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::BatchTranslateDocumentResponse'];

coerce 'BatchTranslateDocumentResponse',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::BatchTranslateDocumentResponse'->new($_) };

declare 'RepeatedBatchTranslateDocumentResponse',
    as ArrayRef[BatchTranslateDocumentResponse()];

coerce 'RepeatedBatchTranslateDocumentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::BatchTranslateDocumentResponse'->new($_) } @$_ ] };

declare 'MapStringBatchTranslateDocumentResponse',
    as HashRef[BatchTranslateDocumentResponse()];

declare 'BatchTranslateDocumentMetadata',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::BatchTranslateDocumentMetadata'];

coerce 'BatchTranslateDocumentMetadata',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::BatchTranslateDocumentMetadata'->new($_) };

declare 'RepeatedBatchTranslateDocumentMetadata',
    as ArrayRef[BatchTranslateDocumentMetadata()];

coerce 'RepeatedBatchTranslateDocumentMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::BatchTranslateDocumentMetadata'->new($_) } @$_ ] };

declare 'MapStringBatchTranslateDocumentMetadata',
    as HashRef[BatchTranslateDocumentMetadata()];

declare 'State',
    as (Int | Str);

declare 'TranslateTextGlossaryConfig',
    as InstanceOf['Google::Cloud::Translation::V3::TranslationService::TranslateTextGlossaryConfig'];

coerce 'TranslateTextGlossaryConfig',
    from HashRef, via { 'Google::Cloud::Translation::V3::TranslationService::TranslateTextGlossaryConfig'->new($_) };

declare 'RepeatedTranslateTextGlossaryConfig',
    as ArrayRef[TranslateTextGlossaryConfig()];

coerce 'RepeatedTranslateTextGlossaryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3::TranslationService::TranslateTextGlossaryConfig'->new($_) } @$_ ] };

declare 'MapStringTranslateTextGlossaryConfig',
    as HashRef[TranslateTextGlossaryConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Translation::V3::TranslationService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
