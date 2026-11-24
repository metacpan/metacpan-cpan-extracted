package Google::Cloud::Translation::V3beta1::TranslationService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TranslateTextGlossaryConfig',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::TranslateTextGlossaryConfig'];

coerce 'TranslateTextGlossaryConfig',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::TranslateTextGlossaryConfig'->new($_) };

declare 'RepeatedTranslateTextGlossaryConfig',
    as ArrayRef[TranslateTextGlossaryConfig()];

coerce 'RepeatedTranslateTextGlossaryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::TranslateTextGlossaryConfig'->new($_) } @$_ ] };

declare 'MapStringTranslateTextGlossaryConfig',
    as HashRef[TranslateTextGlossaryConfig()];

declare 'TranslateTextRequest',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::TranslateTextRequest'];

coerce 'TranslateTextRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::TranslateTextRequest'->new($_) };

declare 'RepeatedTranslateTextRequest',
    as ArrayRef[TranslateTextRequest()];

coerce 'RepeatedTranslateTextRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::TranslateTextRequest'->new($_) } @$_ ] };

declare 'MapStringTranslateTextRequest',
    as HashRef[TranslateTextRequest()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::TranslateTextRequest::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::TranslateTextRequest::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::TranslateTextRequest::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'TranslateTextResponse',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::TranslateTextResponse'];

coerce 'TranslateTextResponse',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::TranslateTextResponse'->new($_) };

declare 'RepeatedTranslateTextResponse',
    as ArrayRef[TranslateTextResponse()];

coerce 'RepeatedTranslateTextResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::TranslateTextResponse'->new($_) } @$_ ] };

declare 'MapStringTranslateTextResponse',
    as HashRef[TranslateTextResponse()];

declare 'Translation',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::Translation'];

coerce 'Translation',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::Translation'->new($_) };

declare 'RepeatedTranslation',
    as ArrayRef[Translation()];

coerce 'RepeatedTranslation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::Translation'->new($_) } @$_ ] };

declare 'MapStringTranslation',
    as HashRef[Translation()];

declare 'DetectLanguageRequest',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::DetectLanguageRequest'];

coerce 'DetectLanguageRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::DetectLanguageRequest'->new($_) };

declare 'RepeatedDetectLanguageRequest',
    as ArrayRef[DetectLanguageRequest()];

coerce 'RepeatedDetectLanguageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::DetectLanguageRequest'->new($_) } @$_ ] };

declare 'MapStringDetectLanguageRequest',
    as HashRef[DetectLanguageRequest()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::DetectLanguageRequest::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::DetectLanguageRequest::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::DetectLanguageRequest::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'DetectedLanguage',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::DetectedLanguage'];

coerce 'DetectedLanguage',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::DetectedLanguage'->new($_) };

declare 'RepeatedDetectedLanguage',
    as ArrayRef[DetectedLanguage()];

coerce 'RepeatedDetectedLanguage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::DetectedLanguage'->new($_) } @$_ ] };

declare 'MapStringDetectedLanguage',
    as HashRef[DetectedLanguage()];

declare 'DetectLanguageResponse',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::DetectLanguageResponse'];

coerce 'DetectLanguageResponse',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::DetectLanguageResponse'->new($_) };

declare 'RepeatedDetectLanguageResponse',
    as ArrayRef[DetectLanguageResponse()];

coerce 'RepeatedDetectLanguageResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::DetectLanguageResponse'->new($_) } @$_ ] };

declare 'MapStringDetectLanguageResponse',
    as HashRef[DetectLanguageResponse()];

declare 'GetSupportedLanguagesRequest',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::GetSupportedLanguagesRequest'];

coerce 'GetSupportedLanguagesRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::GetSupportedLanguagesRequest'->new($_) };

declare 'RepeatedGetSupportedLanguagesRequest',
    as ArrayRef[GetSupportedLanguagesRequest()];

coerce 'RepeatedGetSupportedLanguagesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::GetSupportedLanguagesRequest'->new($_) } @$_ ] };

declare 'MapStringGetSupportedLanguagesRequest',
    as HashRef[GetSupportedLanguagesRequest()];

declare 'SupportedLanguages',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::SupportedLanguages'];

coerce 'SupportedLanguages',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::SupportedLanguages'->new($_) };

declare 'RepeatedSupportedLanguages',
    as ArrayRef[SupportedLanguages()];

coerce 'RepeatedSupportedLanguages',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::SupportedLanguages'->new($_) } @$_ ] };

declare 'MapStringSupportedLanguages',
    as HashRef[SupportedLanguages()];

declare 'SupportedLanguage',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::SupportedLanguage'];

coerce 'SupportedLanguage',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::SupportedLanguage'->new($_) };

declare 'RepeatedSupportedLanguage',
    as ArrayRef[SupportedLanguage()];

coerce 'RepeatedSupportedLanguage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::SupportedLanguage'->new($_) } @$_ ] };

declare 'MapStringSupportedLanguage',
    as HashRef[SupportedLanguage()];

declare 'GcsSource',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::GcsSource'];

coerce 'GcsSource',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::GcsSource'->new($_) };

declare 'RepeatedGcsSource',
    as ArrayRef[GcsSource()];

coerce 'RepeatedGcsSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::GcsSource'->new($_) } @$_ ] };

declare 'MapStringGcsSource',
    as HashRef[GcsSource()];

declare 'InputConfig',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::InputConfig'];

coerce 'InputConfig',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::InputConfig'->new($_) };

declare 'RepeatedInputConfig',
    as ArrayRef[InputConfig()];

coerce 'RepeatedInputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::InputConfig'->new($_) } @$_ ] };

declare 'MapStringInputConfig',
    as HashRef[InputConfig()];

declare 'GcsDestination',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::GcsDestination'];

coerce 'GcsDestination',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::GcsDestination'->new($_) };

declare 'RepeatedGcsDestination',
    as ArrayRef[GcsDestination()];

coerce 'RepeatedGcsDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::GcsDestination'->new($_) } @$_ ] };

declare 'MapStringGcsDestination',
    as HashRef[GcsDestination()];

declare 'OutputConfig',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::OutputConfig'];

coerce 'OutputConfig',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::OutputConfig'->new($_) };

declare 'RepeatedOutputConfig',
    as ArrayRef[OutputConfig()];

coerce 'RepeatedOutputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::OutputConfig'->new($_) } @$_ ] };

declare 'MapStringOutputConfig',
    as HashRef[OutputConfig()];

declare 'DocumentInputConfig',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::DocumentInputConfig'];

coerce 'DocumentInputConfig',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::DocumentInputConfig'->new($_) };

declare 'RepeatedDocumentInputConfig',
    as ArrayRef[DocumentInputConfig()];

coerce 'RepeatedDocumentInputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::DocumentInputConfig'->new($_) } @$_ ] };

declare 'MapStringDocumentInputConfig',
    as HashRef[DocumentInputConfig()];

declare 'DocumentOutputConfig',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::DocumentOutputConfig'];

coerce 'DocumentOutputConfig',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::DocumentOutputConfig'->new($_) };

declare 'RepeatedDocumentOutputConfig',
    as ArrayRef[DocumentOutputConfig()];

coerce 'RepeatedDocumentOutputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::DocumentOutputConfig'->new($_) } @$_ ] };

declare 'MapStringDocumentOutputConfig',
    as HashRef[DocumentOutputConfig()];

declare 'TranslateDocumentRequest',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::TranslateDocumentRequest'];

coerce 'TranslateDocumentRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::TranslateDocumentRequest'->new($_) };

declare 'RepeatedTranslateDocumentRequest',
    as ArrayRef[TranslateDocumentRequest()];

coerce 'RepeatedTranslateDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::TranslateDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringTranslateDocumentRequest',
    as HashRef[TranslateDocumentRequest()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::TranslateDocumentRequest::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::TranslateDocumentRequest::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::TranslateDocumentRequest::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'DocumentTranslation',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::DocumentTranslation'];

coerce 'DocumentTranslation',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::DocumentTranslation'->new($_) };

declare 'RepeatedDocumentTranslation',
    as ArrayRef[DocumentTranslation()];

coerce 'RepeatedDocumentTranslation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::DocumentTranslation'->new($_) } @$_ ] };

declare 'MapStringDocumentTranslation',
    as HashRef[DocumentTranslation()];

declare 'TranslateDocumentResponse',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::TranslateDocumentResponse'];

coerce 'TranslateDocumentResponse',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::TranslateDocumentResponse'->new($_) };

declare 'RepeatedTranslateDocumentResponse',
    as ArrayRef[TranslateDocumentResponse()];

coerce 'RepeatedTranslateDocumentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::TranslateDocumentResponse'->new($_) } @$_ ] };

declare 'MapStringTranslateDocumentResponse',
    as HashRef[TranslateDocumentResponse()];

declare 'BatchTranslateTextRequest',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateTextRequest'];

coerce 'BatchTranslateTextRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateTextRequest'->new($_) };

declare 'RepeatedBatchTranslateTextRequest',
    as ArrayRef[BatchTranslateTextRequest()];

coerce 'RepeatedBatchTranslateTextRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateTextRequest'->new($_) } @$_ ] };

declare 'MapStringBatchTranslateTextRequest',
    as HashRef[BatchTranslateTextRequest()];

declare 'ModelsEntry',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateTextRequest::ModelsEntry'];

coerce 'ModelsEntry',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateTextRequest::ModelsEntry'->new($_) };

declare 'RepeatedModelsEntry',
    as ArrayRef[ModelsEntry()];

coerce 'RepeatedModelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateTextRequest::ModelsEntry'->new($_) } @$_ ] };

declare 'MapStringModelsEntry',
    as HashRef[ModelsEntry()];

declare 'GlossariesEntry',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateTextRequest::GlossariesEntry'];

coerce 'GlossariesEntry',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateTextRequest::GlossariesEntry'->new($_) };

declare 'RepeatedGlossariesEntry',
    as ArrayRef[GlossariesEntry()];

coerce 'RepeatedGlossariesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateTextRequest::GlossariesEntry'->new($_) } @$_ ] };

declare 'MapStringGlossariesEntry',
    as HashRef[GlossariesEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateTextRequest::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateTextRequest::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateTextRequest::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'BatchTranslateMetadata',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateMetadata'];

coerce 'BatchTranslateMetadata',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateMetadata'->new($_) };

declare 'RepeatedBatchTranslateMetadata',
    as ArrayRef[BatchTranslateMetadata()];

coerce 'RepeatedBatchTranslateMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateMetadata'->new($_) } @$_ ] };

declare 'MapStringBatchTranslateMetadata',
    as HashRef[BatchTranslateMetadata()];

declare 'State',
    as (Int | Str);

declare 'BatchTranslateResponse',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateResponse'];

coerce 'BatchTranslateResponse',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateResponse'->new($_) };

declare 'RepeatedBatchTranslateResponse',
    as ArrayRef[BatchTranslateResponse()];

coerce 'RepeatedBatchTranslateResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateResponse'->new($_) } @$_ ] };

declare 'MapStringBatchTranslateResponse',
    as HashRef[BatchTranslateResponse()];

declare 'GlossaryInputConfig',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::GlossaryInputConfig'];

coerce 'GlossaryInputConfig',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::GlossaryInputConfig'->new($_) };

declare 'RepeatedGlossaryInputConfig',
    as ArrayRef[GlossaryInputConfig()];

coerce 'RepeatedGlossaryInputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::GlossaryInputConfig'->new($_) } @$_ ] };

declare 'MapStringGlossaryInputConfig',
    as HashRef[GlossaryInputConfig()];

declare 'Glossary',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::Glossary'];

coerce 'Glossary',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::Glossary'->new($_) };

declare 'RepeatedGlossary',
    as ArrayRef[Glossary()];

coerce 'RepeatedGlossary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::Glossary'->new($_) } @$_ ] };

declare 'MapStringGlossary',
    as HashRef[Glossary()];

declare 'LanguageCodePair',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::Glossary::LanguageCodePair'];

coerce 'LanguageCodePair',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::Glossary::LanguageCodePair'->new($_) };

declare 'RepeatedLanguageCodePair',
    as ArrayRef[LanguageCodePair()];

coerce 'RepeatedLanguageCodePair',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::Glossary::LanguageCodePair'->new($_) } @$_ ] };

declare 'MapStringLanguageCodePair',
    as HashRef[LanguageCodePair()];

declare 'LanguageCodesSet',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::Glossary::LanguageCodesSet'];

coerce 'LanguageCodesSet',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::Glossary::LanguageCodesSet'->new($_) };

declare 'RepeatedLanguageCodesSet',
    as ArrayRef[LanguageCodesSet()];

coerce 'RepeatedLanguageCodesSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::Glossary::LanguageCodesSet'->new($_) } @$_ ] };

declare 'MapStringLanguageCodesSet',
    as HashRef[LanguageCodesSet()];

declare 'CreateGlossaryRequest',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::CreateGlossaryRequest'];

coerce 'CreateGlossaryRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::CreateGlossaryRequest'->new($_) };

declare 'RepeatedCreateGlossaryRequest',
    as ArrayRef[CreateGlossaryRequest()];

coerce 'RepeatedCreateGlossaryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::CreateGlossaryRequest'->new($_) } @$_ ] };

declare 'MapStringCreateGlossaryRequest',
    as HashRef[CreateGlossaryRequest()];

declare 'GetGlossaryRequest',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::GetGlossaryRequest'];

coerce 'GetGlossaryRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::GetGlossaryRequest'->new($_) };

declare 'RepeatedGetGlossaryRequest',
    as ArrayRef[GetGlossaryRequest()];

coerce 'RepeatedGetGlossaryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::GetGlossaryRequest'->new($_) } @$_ ] };

declare 'MapStringGetGlossaryRequest',
    as HashRef[GetGlossaryRequest()];

declare 'DeleteGlossaryRequest',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::DeleteGlossaryRequest'];

coerce 'DeleteGlossaryRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::DeleteGlossaryRequest'->new($_) };

declare 'RepeatedDeleteGlossaryRequest',
    as ArrayRef[DeleteGlossaryRequest()];

coerce 'RepeatedDeleteGlossaryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::DeleteGlossaryRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteGlossaryRequest',
    as HashRef[DeleteGlossaryRequest()];

declare 'ListGlossariesRequest',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::ListGlossariesRequest'];

coerce 'ListGlossariesRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::ListGlossariesRequest'->new($_) };

declare 'RepeatedListGlossariesRequest',
    as ArrayRef[ListGlossariesRequest()];

coerce 'RepeatedListGlossariesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::ListGlossariesRequest'->new($_) } @$_ ] };

declare 'MapStringListGlossariesRequest',
    as HashRef[ListGlossariesRequest()];

declare 'ListGlossariesResponse',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::ListGlossariesResponse'];

coerce 'ListGlossariesResponse',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::ListGlossariesResponse'->new($_) };

declare 'RepeatedListGlossariesResponse',
    as ArrayRef[ListGlossariesResponse()];

coerce 'RepeatedListGlossariesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::ListGlossariesResponse'->new($_) } @$_ ] };

declare 'MapStringListGlossariesResponse',
    as HashRef[ListGlossariesResponse()];

declare 'CreateGlossaryMetadata',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::CreateGlossaryMetadata'];

coerce 'CreateGlossaryMetadata',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::CreateGlossaryMetadata'->new($_) };

declare 'RepeatedCreateGlossaryMetadata',
    as ArrayRef[CreateGlossaryMetadata()];

coerce 'RepeatedCreateGlossaryMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::CreateGlossaryMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateGlossaryMetadata',
    as HashRef[CreateGlossaryMetadata()];

declare 'State',
    as (Int | Str);

declare 'DeleteGlossaryMetadata',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::DeleteGlossaryMetadata'];

coerce 'DeleteGlossaryMetadata',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::DeleteGlossaryMetadata'->new($_) };

declare 'RepeatedDeleteGlossaryMetadata',
    as ArrayRef[DeleteGlossaryMetadata()];

coerce 'RepeatedDeleteGlossaryMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::DeleteGlossaryMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteGlossaryMetadata',
    as HashRef[DeleteGlossaryMetadata()];

declare 'State',
    as (Int | Str);

declare 'DeleteGlossaryResponse',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::DeleteGlossaryResponse'];

coerce 'DeleteGlossaryResponse',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::DeleteGlossaryResponse'->new($_) };

declare 'RepeatedDeleteGlossaryResponse',
    as ArrayRef[DeleteGlossaryResponse()];

coerce 'RepeatedDeleteGlossaryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::DeleteGlossaryResponse'->new($_) } @$_ ] };

declare 'MapStringDeleteGlossaryResponse',
    as HashRef[DeleteGlossaryResponse()];

declare 'BatchTranslateDocumentRequest',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateDocumentRequest'];

coerce 'BatchTranslateDocumentRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateDocumentRequest'->new($_) };

declare 'RepeatedBatchTranslateDocumentRequest',
    as ArrayRef[BatchTranslateDocumentRequest()];

coerce 'RepeatedBatchTranslateDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringBatchTranslateDocumentRequest',
    as HashRef[BatchTranslateDocumentRequest()];

declare 'ModelsEntry',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateDocumentRequest::ModelsEntry'];

coerce 'ModelsEntry',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateDocumentRequest::ModelsEntry'->new($_) };

declare 'RepeatedModelsEntry',
    as ArrayRef[ModelsEntry()];

coerce 'RepeatedModelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateDocumentRequest::ModelsEntry'->new($_) } @$_ ] };

declare 'MapStringModelsEntry',
    as HashRef[ModelsEntry()];

declare 'GlossariesEntry',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateDocumentRequest::GlossariesEntry'];

coerce 'GlossariesEntry',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateDocumentRequest::GlossariesEntry'->new($_) };

declare 'RepeatedGlossariesEntry',
    as ArrayRef[GlossariesEntry()];

coerce 'RepeatedGlossariesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateDocumentRequest::GlossariesEntry'->new($_) } @$_ ] };

declare 'MapStringGlossariesEntry',
    as HashRef[GlossariesEntry()];

declare 'FormatConversionsEntry',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateDocumentRequest::FormatConversionsEntry'];

coerce 'FormatConversionsEntry',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateDocumentRequest::FormatConversionsEntry'->new($_) };

declare 'RepeatedFormatConversionsEntry',
    as ArrayRef[FormatConversionsEntry()];

coerce 'RepeatedFormatConversionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateDocumentRequest::FormatConversionsEntry'->new($_) } @$_ ] };

declare 'MapStringFormatConversionsEntry',
    as HashRef[FormatConversionsEntry()];

declare 'BatchDocumentInputConfig',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::BatchDocumentInputConfig'];

coerce 'BatchDocumentInputConfig',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::BatchDocumentInputConfig'->new($_) };

declare 'RepeatedBatchDocumentInputConfig',
    as ArrayRef[BatchDocumentInputConfig()];

coerce 'RepeatedBatchDocumentInputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::BatchDocumentInputConfig'->new($_) } @$_ ] };

declare 'MapStringBatchDocumentInputConfig',
    as HashRef[BatchDocumentInputConfig()];

declare 'BatchDocumentOutputConfig',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::BatchDocumentOutputConfig'];

coerce 'BatchDocumentOutputConfig',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::BatchDocumentOutputConfig'->new($_) };

declare 'RepeatedBatchDocumentOutputConfig',
    as ArrayRef[BatchDocumentOutputConfig()];

coerce 'RepeatedBatchDocumentOutputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::BatchDocumentOutputConfig'->new($_) } @$_ ] };

declare 'MapStringBatchDocumentOutputConfig',
    as HashRef[BatchDocumentOutputConfig()];

declare 'BatchTranslateDocumentResponse',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateDocumentResponse'];

coerce 'BatchTranslateDocumentResponse',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateDocumentResponse'->new($_) };

declare 'RepeatedBatchTranslateDocumentResponse',
    as ArrayRef[BatchTranslateDocumentResponse()];

coerce 'RepeatedBatchTranslateDocumentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateDocumentResponse'->new($_) } @$_ ] };

declare 'MapStringBatchTranslateDocumentResponse',
    as HashRef[BatchTranslateDocumentResponse()];

declare 'BatchTranslateDocumentMetadata',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateDocumentMetadata'];

coerce 'BatchTranslateDocumentMetadata',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateDocumentMetadata'->new($_) };

declare 'RepeatedBatchTranslateDocumentMetadata',
    as ArrayRef[BatchTranslateDocumentMetadata()];

coerce 'RepeatedBatchTranslateDocumentMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::BatchTranslateDocumentMetadata'->new($_) } @$_ ] };

declare 'MapStringBatchTranslateDocumentMetadata',
    as HashRef[BatchTranslateDocumentMetadata()];

declare 'State',
    as (Int | Str);

declare 'RefinementEntry',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::RefinementEntry'];

coerce 'RefinementEntry',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::RefinementEntry'->new($_) };

declare 'RepeatedRefinementEntry',
    as ArrayRef[RefinementEntry()];

coerce 'RepeatedRefinementEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::RefinementEntry'->new($_) } @$_ ] };

declare 'MapStringRefinementEntry',
    as HashRef[RefinementEntry()];

declare 'RefineTextRequest',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::RefineTextRequest'];

coerce 'RefineTextRequest',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::RefineTextRequest'->new($_) };

declare 'RepeatedRefineTextRequest',
    as ArrayRef[RefineTextRequest()];

coerce 'RepeatedRefineTextRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::RefineTextRequest'->new($_) } @$_ ] };

declare 'MapStringRefineTextRequest',
    as HashRef[RefineTextRequest()];

declare 'RefineTextResponse',
    as InstanceOf['Google::Cloud::Translation::V3beta1::TranslationService::RefineTextResponse'];

coerce 'RefineTextResponse',
    from HashRef, via { 'Google::Cloud::Translation::V3beta1::TranslationService::RefineTextResponse'->new($_) };

declare 'RepeatedRefineTextResponse',
    as ArrayRef[RefineTextResponse()];

coerce 'RepeatedRefineTextResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Translation::V3beta1::TranslationService::RefineTextResponse'->new($_) } @$_ ] };

declare 'MapStringRefineTextResponse',
    as HashRef[RefineTextResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Translation::V3beta1::TranslationService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
