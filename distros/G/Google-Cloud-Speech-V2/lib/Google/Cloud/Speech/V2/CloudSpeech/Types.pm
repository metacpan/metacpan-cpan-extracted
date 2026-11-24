package Google::Cloud::Speech::V2::CloudSpeech::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateRecognizerRequest',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::CreateRecognizerRequest'];

coerce 'CreateRecognizerRequest',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::CreateRecognizerRequest'->new($_) };

declare 'RepeatedCreateRecognizerRequest',
    as ArrayRef[CreateRecognizerRequest()];

coerce 'RepeatedCreateRecognizerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::CreateRecognizerRequest'->new($_) } @$_ ] };

declare 'MapStringCreateRecognizerRequest',
    as HashRef[CreateRecognizerRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'ListRecognizersRequest',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::ListRecognizersRequest'];

coerce 'ListRecognizersRequest',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::ListRecognizersRequest'->new($_) };

declare 'RepeatedListRecognizersRequest',
    as ArrayRef[ListRecognizersRequest()];

coerce 'RepeatedListRecognizersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::ListRecognizersRequest'->new($_) } @$_ ] };

declare 'MapStringListRecognizersRequest',
    as HashRef[ListRecognizersRequest()];

declare 'ListRecognizersResponse',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::ListRecognizersResponse'];

coerce 'ListRecognizersResponse',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::ListRecognizersResponse'->new($_) };

declare 'RepeatedListRecognizersResponse',
    as ArrayRef[ListRecognizersResponse()];

coerce 'RepeatedListRecognizersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::ListRecognizersResponse'->new($_) } @$_ ] };

declare 'MapStringListRecognizersResponse',
    as HashRef[ListRecognizersResponse()];

declare 'GetRecognizerRequest',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::GetRecognizerRequest'];

coerce 'GetRecognizerRequest',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::GetRecognizerRequest'->new($_) };

declare 'RepeatedGetRecognizerRequest',
    as ArrayRef[GetRecognizerRequest()];

coerce 'RepeatedGetRecognizerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::GetRecognizerRequest'->new($_) } @$_ ] };

declare 'MapStringGetRecognizerRequest',
    as HashRef[GetRecognizerRequest()];

declare 'UpdateRecognizerRequest',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::UpdateRecognizerRequest'];

coerce 'UpdateRecognizerRequest',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::UpdateRecognizerRequest'->new($_) };

declare 'RepeatedUpdateRecognizerRequest',
    as ArrayRef[UpdateRecognizerRequest()];

coerce 'RepeatedUpdateRecognizerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::UpdateRecognizerRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateRecognizerRequest',
    as HashRef[UpdateRecognizerRequest()];

declare 'DeleteRecognizerRequest',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::DeleteRecognizerRequest'];

coerce 'DeleteRecognizerRequest',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::DeleteRecognizerRequest'->new($_) };

declare 'RepeatedDeleteRecognizerRequest',
    as ArrayRef[DeleteRecognizerRequest()];

coerce 'RepeatedDeleteRecognizerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::DeleteRecognizerRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteRecognizerRequest',
    as HashRef[DeleteRecognizerRequest()];

declare 'UndeleteRecognizerRequest',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::UndeleteRecognizerRequest'];

coerce 'UndeleteRecognizerRequest',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::UndeleteRecognizerRequest'->new($_) };

declare 'RepeatedUndeleteRecognizerRequest',
    as ArrayRef[UndeleteRecognizerRequest()];

coerce 'RepeatedUndeleteRecognizerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::UndeleteRecognizerRequest'->new($_) } @$_ ] };

declare 'MapStringUndeleteRecognizerRequest',
    as HashRef[UndeleteRecognizerRequest()];

declare 'Recognizer',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::Recognizer'];

coerce 'Recognizer',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::Recognizer'->new($_) };

declare 'RepeatedRecognizer',
    as ArrayRef[Recognizer()];

coerce 'RepeatedRecognizer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::Recognizer'->new($_) } @$_ ] };

declare 'MapStringRecognizer',
    as HashRef[Recognizer()];

declare 'State',
    as (Int | Str);

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::Recognizer::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::Recognizer::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::Recognizer::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'AutoDetectDecodingConfig',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::AutoDetectDecodingConfig'];

coerce 'AutoDetectDecodingConfig',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::AutoDetectDecodingConfig'->new($_) };

declare 'RepeatedAutoDetectDecodingConfig',
    as ArrayRef[AutoDetectDecodingConfig()];

coerce 'RepeatedAutoDetectDecodingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::AutoDetectDecodingConfig'->new($_) } @$_ ] };

declare 'MapStringAutoDetectDecodingConfig',
    as HashRef[AutoDetectDecodingConfig()];

declare 'ExplicitDecodingConfig',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::ExplicitDecodingConfig'];

coerce 'ExplicitDecodingConfig',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::ExplicitDecodingConfig'->new($_) };

declare 'RepeatedExplicitDecodingConfig',
    as ArrayRef[ExplicitDecodingConfig()];

coerce 'RepeatedExplicitDecodingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::ExplicitDecodingConfig'->new($_) } @$_ ] };

declare 'MapStringExplicitDecodingConfig',
    as HashRef[ExplicitDecodingConfig()];

declare 'AudioEncoding',
    as (Int | Str);

declare 'SpeakerDiarizationConfig',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::SpeakerDiarizationConfig'];

coerce 'SpeakerDiarizationConfig',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::SpeakerDiarizationConfig'->new($_) };

declare 'RepeatedSpeakerDiarizationConfig',
    as ArrayRef[SpeakerDiarizationConfig()];

coerce 'RepeatedSpeakerDiarizationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::SpeakerDiarizationConfig'->new($_) } @$_ ] };

declare 'MapStringSpeakerDiarizationConfig',
    as HashRef[SpeakerDiarizationConfig()];

declare 'CustomPromptConfig',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::CustomPromptConfig'];

coerce 'CustomPromptConfig',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::CustomPromptConfig'->new($_) };

declare 'RepeatedCustomPromptConfig',
    as ArrayRef[CustomPromptConfig()];

coerce 'RepeatedCustomPromptConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::CustomPromptConfig'->new($_) } @$_ ] };

declare 'MapStringCustomPromptConfig',
    as HashRef[CustomPromptConfig()];

declare 'RecognitionFeatures',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::RecognitionFeatures'];

coerce 'RecognitionFeatures',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::RecognitionFeatures'->new($_) };

declare 'RepeatedRecognitionFeatures',
    as ArrayRef[RecognitionFeatures()];

coerce 'RepeatedRecognitionFeatures',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::RecognitionFeatures'->new($_) } @$_ ] };

declare 'MapStringRecognitionFeatures',
    as HashRef[RecognitionFeatures()];

declare 'MultiChannelMode',
    as (Int | Str);

declare 'TranscriptNormalization',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::TranscriptNormalization'];

coerce 'TranscriptNormalization',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::TranscriptNormalization'->new($_) };

declare 'RepeatedTranscriptNormalization',
    as ArrayRef[TranscriptNormalization()];

coerce 'RepeatedTranscriptNormalization',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::TranscriptNormalization'->new($_) } @$_ ] };

declare 'MapStringTranscriptNormalization',
    as HashRef[TranscriptNormalization()];

declare 'Entry',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::TranscriptNormalization::Entry'];

coerce 'Entry',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::TranscriptNormalization::Entry'->new($_) };

declare 'RepeatedEntry',
    as ArrayRef[Entry()];

coerce 'RepeatedEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::TranscriptNormalization::Entry'->new($_) } @$_ ] };

declare 'MapStringEntry',
    as HashRef[Entry()];

declare 'TranslationConfig',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::TranslationConfig'];

coerce 'TranslationConfig',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::TranslationConfig'->new($_) };

declare 'RepeatedTranslationConfig',
    as ArrayRef[TranslationConfig()];

coerce 'RepeatedTranslationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::TranslationConfig'->new($_) } @$_ ] };

declare 'MapStringTranslationConfig',
    as HashRef[TranslationConfig()];

declare 'SpeechAdaptation',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::SpeechAdaptation'];

coerce 'SpeechAdaptation',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::SpeechAdaptation'->new($_) };

declare 'RepeatedSpeechAdaptation',
    as ArrayRef[SpeechAdaptation()];

coerce 'RepeatedSpeechAdaptation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::SpeechAdaptation'->new($_) } @$_ ] };

declare 'MapStringSpeechAdaptation',
    as HashRef[SpeechAdaptation()];

declare 'AdaptationPhraseSet',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::SpeechAdaptation::AdaptationPhraseSet'];

coerce 'AdaptationPhraseSet',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::SpeechAdaptation::AdaptationPhraseSet'->new($_) };

declare 'RepeatedAdaptationPhraseSet',
    as ArrayRef[AdaptationPhraseSet()];

coerce 'RepeatedAdaptationPhraseSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::SpeechAdaptation::AdaptationPhraseSet'->new($_) } @$_ ] };

declare 'MapStringAdaptationPhraseSet',
    as HashRef[AdaptationPhraseSet()];

declare 'DenoiserConfig',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::DenoiserConfig'];

coerce 'DenoiserConfig',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::DenoiserConfig'->new($_) };

declare 'RepeatedDenoiserConfig',
    as ArrayRef[DenoiserConfig()];

coerce 'RepeatedDenoiserConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::DenoiserConfig'->new($_) } @$_ ] };

declare 'MapStringDenoiserConfig',
    as HashRef[DenoiserConfig()];

declare 'RecognitionConfig',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::RecognitionConfig'];

coerce 'RecognitionConfig',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::RecognitionConfig'->new($_) };

declare 'RepeatedRecognitionConfig',
    as ArrayRef[RecognitionConfig()];

coerce 'RepeatedRecognitionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::RecognitionConfig'->new($_) } @$_ ] };

declare 'MapStringRecognitionConfig',
    as HashRef[RecognitionConfig()];

declare 'RecognizeRequest',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::RecognizeRequest'];

coerce 'RecognizeRequest',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::RecognizeRequest'->new($_) };

declare 'RepeatedRecognizeRequest',
    as ArrayRef[RecognizeRequest()];

coerce 'RepeatedRecognizeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::RecognizeRequest'->new($_) } @$_ ] };

declare 'MapStringRecognizeRequest',
    as HashRef[RecognizeRequest()];

declare 'RecognitionResponseMetadata',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::RecognitionResponseMetadata'];

coerce 'RecognitionResponseMetadata',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::RecognitionResponseMetadata'->new($_) };

declare 'RepeatedRecognitionResponseMetadata',
    as ArrayRef[RecognitionResponseMetadata()];

coerce 'RepeatedRecognitionResponseMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::RecognitionResponseMetadata'->new($_) } @$_ ] };

declare 'MapStringRecognitionResponseMetadata',
    as HashRef[RecognitionResponseMetadata()];

declare 'SpeechRecognitionAlternative',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::SpeechRecognitionAlternative'];

coerce 'SpeechRecognitionAlternative',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::SpeechRecognitionAlternative'->new($_) };

declare 'RepeatedSpeechRecognitionAlternative',
    as ArrayRef[SpeechRecognitionAlternative()];

coerce 'RepeatedSpeechRecognitionAlternative',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::SpeechRecognitionAlternative'->new($_) } @$_ ] };

declare 'MapStringSpeechRecognitionAlternative',
    as HashRef[SpeechRecognitionAlternative()];

declare 'WordInfo',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::WordInfo'];

coerce 'WordInfo',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::WordInfo'->new($_) };

declare 'RepeatedWordInfo',
    as ArrayRef[WordInfo()];

coerce 'RepeatedWordInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::WordInfo'->new($_) } @$_ ] };

declare 'MapStringWordInfo',
    as HashRef[WordInfo()];

declare 'SpeechRecognitionResult',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::SpeechRecognitionResult'];

coerce 'SpeechRecognitionResult',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::SpeechRecognitionResult'->new($_) };

declare 'RepeatedSpeechRecognitionResult',
    as ArrayRef[SpeechRecognitionResult()];

coerce 'RepeatedSpeechRecognitionResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::SpeechRecognitionResult'->new($_) } @$_ ] };

declare 'MapStringSpeechRecognitionResult',
    as HashRef[SpeechRecognitionResult()];

declare 'RecognizeResponse',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::RecognizeResponse'];

coerce 'RecognizeResponse',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::RecognizeResponse'->new($_) };

declare 'RepeatedRecognizeResponse',
    as ArrayRef[RecognizeResponse()];

coerce 'RepeatedRecognizeResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::RecognizeResponse'->new($_) } @$_ ] };

declare 'MapStringRecognizeResponse',
    as HashRef[RecognizeResponse()];

declare 'StreamingRecognitionFeatures',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::StreamingRecognitionFeatures'];

coerce 'StreamingRecognitionFeatures',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::StreamingRecognitionFeatures'->new($_) };

declare 'RepeatedStreamingRecognitionFeatures',
    as ArrayRef[StreamingRecognitionFeatures()];

coerce 'RepeatedStreamingRecognitionFeatures',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::StreamingRecognitionFeatures'->new($_) } @$_ ] };

declare 'MapStringStreamingRecognitionFeatures',
    as HashRef[StreamingRecognitionFeatures()];

declare 'EndpointingSensitivity',
    as (Int | Str);

declare 'VoiceActivityTimeout',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::StreamingRecognitionFeatures::VoiceActivityTimeout'];

coerce 'VoiceActivityTimeout',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::StreamingRecognitionFeatures::VoiceActivityTimeout'->new($_) };

declare 'RepeatedVoiceActivityTimeout',
    as ArrayRef[VoiceActivityTimeout()];

coerce 'RepeatedVoiceActivityTimeout',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::StreamingRecognitionFeatures::VoiceActivityTimeout'->new($_) } @$_ ] };

declare 'MapStringVoiceActivityTimeout',
    as HashRef[VoiceActivityTimeout()];

declare 'StreamingRecognitionConfig',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::StreamingRecognitionConfig'];

coerce 'StreamingRecognitionConfig',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::StreamingRecognitionConfig'->new($_) };

declare 'RepeatedStreamingRecognitionConfig',
    as ArrayRef[StreamingRecognitionConfig()];

coerce 'RepeatedStreamingRecognitionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::StreamingRecognitionConfig'->new($_) } @$_ ] };

declare 'MapStringStreamingRecognitionConfig',
    as HashRef[StreamingRecognitionConfig()];

declare 'StreamingRecognizeRequest',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::StreamingRecognizeRequest'];

coerce 'StreamingRecognizeRequest',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::StreamingRecognizeRequest'->new($_) };

declare 'RepeatedStreamingRecognizeRequest',
    as ArrayRef[StreamingRecognizeRequest()];

coerce 'RepeatedStreamingRecognizeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::StreamingRecognizeRequest'->new($_) } @$_ ] };

declare 'MapStringStreamingRecognizeRequest',
    as HashRef[StreamingRecognizeRequest()];

declare 'BatchRecognizeRequest',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::BatchRecognizeRequest'];

coerce 'BatchRecognizeRequest',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::BatchRecognizeRequest'->new($_) };

declare 'RepeatedBatchRecognizeRequest',
    as ArrayRef[BatchRecognizeRequest()];

coerce 'RepeatedBatchRecognizeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::BatchRecognizeRequest'->new($_) } @$_ ] };

declare 'MapStringBatchRecognizeRequest',
    as HashRef[BatchRecognizeRequest()];

declare 'ProcessingStrategy',
    as (Int | Str);

declare 'GcsOutputConfig',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::GcsOutputConfig'];

coerce 'GcsOutputConfig',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::GcsOutputConfig'->new($_) };

declare 'RepeatedGcsOutputConfig',
    as ArrayRef[GcsOutputConfig()];

coerce 'RepeatedGcsOutputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::GcsOutputConfig'->new($_) } @$_ ] };

declare 'MapStringGcsOutputConfig',
    as HashRef[GcsOutputConfig()];

declare 'InlineOutputConfig',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::InlineOutputConfig'];

coerce 'InlineOutputConfig',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::InlineOutputConfig'->new($_) };

declare 'RepeatedInlineOutputConfig',
    as ArrayRef[InlineOutputConfig()];

coerce 'RepeatedInlineOutputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::InlineOutputConfig'->new($_) } @$_ ] };

declare 'MapStringInlineOutputConfig',
    as HashRef[InlineOutputConfig()];

declare 'NativeOutputFileFormatConfig',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::NativeOutputFileFormatConfig'];

coerce 'NativeOutputFileFormatConfig',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::NativeOutputFileFormatConfig'->new($_) };

declare 'RepeatedNativeOutputFileFormatConfig',
    as ArrayRef[NativeOutputFileFormatConfig()];

coerce 'RepeatedNativeOutputFileFormatConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::NativeOutputFileFormatConfig'->new($_) } @$_ ] };

declare 'MapStringNativeOutputFileFormatConfig',
    as HashRef[NativeOutputFileFormatConfig()];

declare 'VttOutputFileFormatConfig',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::VttOutputFileFormatConfig'];

coerce 'VttOutputFileFormatConfig',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::VttOutputFileFormatConfig'->new($_) };

declare 'RepeatedVttOutputFileFormatConfig',
    as ArrayRef[VttOutputFileFormatConfig()];

coerce 'RepeatedVttOutputFileFormatConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::VttOutputFileFormatConfig'->new($_) } @$_ ] };

declare 'MapStringVttOutputFileFormatConfig',
    as HashRef[VttOutputFileFormatConfig()];

declare 'SrtOutputFileFormatConfig',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::SrtOutputFileFormatConfig'];

coerce 'SrtOutputFileFormatConfig',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::SrtOutputFileFormatConfig'->new($_) };

declare 'RepeatedSrtOutputFileFormatConfig',
    as ArrayRef[SrtOutputFileFormatConfig()];

coerce 'RepeatedSrtOutputFileFormatConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::SrtOutputFileFormatConfig'->new($_) } @$_ ] };

declare 'MapStringSrtOutputFileFormatConfig',
    as HashRef[SrtOutputFileFormatConfig()];

declare 'OutputFormatConfig',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::OutputFormatConfig'];

coerce 'OutputFormatConfig',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::OutputFormatConfig'->new($_) };

declare 'RepeatedOutputFormatConfig',
    as ArrayRef[OutputFormatConfig()];

coerce 'RepeatedOutputFormatConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::OutputFormatConfig'->new($_) } @$_ ] };

declare 'MapStringOutputFormatConfig',
    as HashRef[OutputFormatConfig()];

declare 'RecognitionOutputConfig',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::RecognitionOutputConfig'];

coerce 'RecognitionOutputConfig',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::RecognitionOutputConfig'->new($_) };

declare 'RepeatedRecognitionOutputConfig',
    as ArrayRef[RecognitionOutputConfig()];

coerce 'RepeatedRecognitionOutputConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::RecognitionOutputConfig'->new($_) } @$_ ] };

declare 'MapStringRecognitionOutputConfig',
    as HashRef[RecognitionOutputConfig()];

declare 'BatchRecognizeResponse',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::BatchRecognizeResponse'];

coerce 'BatchRecognizeResponse',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::BatchRecognizeResponse'->new($_) };

declare 'RepeatedBatchRecognizeResponse',
    as ArrayRef[BatchRecognizeResponse()];

coerce 'RepeatedBatchRecognizeResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::BatchRecognizeResponse'->new($_) } @$_ ] };

declare 'MapStringBatchRecognizeResponse',
    as HashRef[BatchRecognizeResponse()];

declare 'ResultsEntry',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::BatchRecognizeResponse::ResultsEntry'];

coerce 'ResultsEntry',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::BatchRecognizeResponse::ResultsEntry'->new($_) };

declare 'RepeatedResultsEntry',
    as ArrayRef[ResultsEntry()];

coerce 'RepeatedResultsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::BatchRecognizeResponse::ResultsEntry'->new($_) } @$_ ] };

declare 'MapStringResultsEntry',
    as HashRef[ResultsEntry()];

declare 'BatchRecognizeResults',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::BatchRecognizeResults'];

coerce 'BatchRecognizeResults',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::BatchRecognizeResults'->new($_) };

declare 'RepeatedBatchRecognizeResults',
    as ArrayRef[BatchRecognizeResults()];

coerce 'RepeatedBatchRecognizeResults',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::BatchRecognizeResults'->new($_) } @$_ ] };

declare 'MapStringBatchRecognizeResults',
    as HashRef[BatchRecognizeResults()];

declare 'CloudStorageResult',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::CloudStorageResult'];

coerce 'CloudStorageResult',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::CloudStorageResult'->new($_) };

declare 'RepeatedCloudStorageResult',
    as ArrayRef[CloudStorageResult()];

coerce 'RepeatedCloudStorageResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::CloudStorageResult'->new($_) } @$_ ] };

declare 'MapStringCloudStorageResult',
    as HashRef[CloudStorageResult()];

declare 'InlineResult',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::InlineResult'];

coerce 'InlineResult',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::InlineResult'->new($_) };

declare 'RepeatedInlineResult',
    as ArrayRef[InlineResult()];

coerce 'RepeatedInlineResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::InlineResult'->new($_) } @$_ ] };

declare 'MapStringInlineResult',
    as HashRef[InlineResult()];

declare 'BatchRecognizeFileResult',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::BatchRecognizeFileResult'];

coerce 'BatchRecognizeFileResult',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::BatchRecognizeFileResult'->new($_) };

declare 'RepeatedBatchRecognizeFileResult',
    as ArrayRef[BatchRecognizeFileResult()];

coerce 'RepeatedBatchRecognizeFileResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::BatchRecognizeFileResult'->new($_) } @$_ ] };

declare 'MapStringBatchRecognizeFileResult',
    as HashRef[BatchRecognizeFileResult()];

declare 'BatchRecognizeTranscriptionMetadata',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::BatchRecognizeTranscriptionMetadata'];

coerce 'BatchRecognizeTranscriptionMetadata',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::BatchRecognizeTranscriptionMetadata'->new($_) };

declare 'RepeatedBatchRecognizeTranscriptionMetadata',
    as ArrayRef[BatchRecognizeTranscriptionMetadata()];

coerce 'RepeatedBatchRecognizeTranscriptionMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::BatchRecognizeTranscriptionMetadata'->new($_) } @$_ ] };

declare 'MapStringBatchRecognizeTranscriptionMetadata',
    as HashRef[BatchRecognizeTranscriptionMetadata()];

declare 'BatchRecognizeMetadata',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::BatchRecognizeMetadata'];

coerce 'BatchRecognizeMetadata',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::BatchRecognizeMetadata'->new($_) };

declare 'RepeatedBatchRecognizeMetadata',
    as ArrayRef[BatchRecognizeMetadata()];

coerce 'RepeatedBatchRecognizeMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::BatchRecognizeMetadata'->new($_) } @$_ ] };

declare 'MapStringBatchRecognizeMetadata',
    as HashRef[BatchRecognizeMetadata()];

declare 'TranscriptionMetadataEntry',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::BatchRecognizeMetadata::TranscriptionMetadataEntry'];

coerce 'TranscriptionMetadataEntry',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::BatchRecognizeMetadata::TranscriptionMetadataEntry'->new($_) };

declare 'RepeatedTranscriptionMetadataEntry',
    as ArrayRef[TranscriptionMetadataEntry()];

coerce 'RepeatedTranscriptionMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::BatchRecognizeMetadata::TranscriptionMetadataEntry'->new($_) } @$_ ] };

declare 'MapStringTranscriptionMetadataEntry',
    as HashRef[TranscriptionMetadataEntry()];

declare 'BatchRecognizeFileMetadata',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::BatchRecognizeFileMetadata'];

coerce 'BatchRecognizeFileMetadata',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::BatchRecognizeFileMetadata'->new($_) };

declare 'RepeatedBatchRecognizeFileMetadata',
    as ArrayRef[BatchRecognizeFileMetadata()];

coerce 'RepeatedBatchRecognizeFileMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::BatchRecognizeFileMetadata'->new($_) } @$_ ] };

declare 'MapStringBatchRecognizeFileMetadata',
    as HashRef[BatchRecognizeFileMetadata()];

declare 'StreamingRecognitionResult',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::StreamingRecognitionResult'];

coerce 'StreamingRecognitionResult',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::StreamingRecognitionResult'->new($_) };

declare 'RepeatedStreamingRecognitionResult',
    as ArrayRef[StreamingRecognitionResult()];

coerce 'RepeatedStreamingRecognitionResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::StreamingRecognitionResult'->new($_) } @$_ ] };

declare 'MapStringStreamingRecognitionResult',
    as HashRef[StreamingRecognitionResult()];

declare 'StreamingRecognizeResponse',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::StreamingRecognizeResponse'];

coerce 'StreamingRecognizeResponse',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::StreamingRecognizeResponse'->new($_) };

declare 'RepeatedStreamingRecognizeResponse',
    as ArrayRef[StreamingRecognizeResponse()];

coerce 'RepeatedStreamingRecognizeResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::StreamingRecognizeResponse'->new($_) } @$_ ] };

declare 'MapStringStreamingRecognizeResponse',
    as HashRef[StreamingRecognizeResponse()];

declare 'SpeechEventType',
    as (Int | Str);

declare 'Config',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::Config'];

coerce 'Config',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::Config'->new($_) };

declare 'RepeatedConfig',
    as ArrayRef[Config()];

coerce 'RepeatedConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::Config'->new($_) } @$_ ] };

declare 'MapStringConfig',
    as HashRef[Config()];

declare 'GetConfigRequest',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::GetConfigRequest'];

coerce 'GetConfigRequest',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::GetConfigRequest'->new($_) };

declare 'RepeatedGetConfigRequest',
    as ArrayRef[GetConfigRequest()];

coerce 'RepeatedGetConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::GetConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetConfigRequest',
    as HashRef[GetConfigRequest()];

declare 'UpdateConfigRequest',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::UpdateConfigRequest'];

coerce 'UpdateConfigRequest',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::UpdateConfigRequest'->new($_) };

declare 'RepeatedUpdateConfigRequest',
    as ArrayRef[UpdateConfigRequest()];

coerce 'RepeatedUpdateConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::UpdateConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateConfigRequest',
    as HashRef[UpdateConfigRequest()];

declare 'CustomClass',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::CustomClass'];

coerce 'CustomClass',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::CustomClass'->new($_) };

declare 'RepeatedCustomClass',
    as ArrayRef[CustomClass()];

coerce 'RepeatedCustomClass',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::CustomClass'->new($_) } @$_ ] };

declare 'MapStringCustomClass',
    as HashRef[CustomClass()];

declare 'State',
    as (Int | Str);

declare 'ClassItem',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::CustomClass::ClassItem'];

coerce 'ClassItem',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::CustomClass::ClassItem'->new($_) };

declare 'RepeatedClassItem',
    as ArrayRef[ClassItem()];

coerce 'RepeatedClassItem',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::CustomClass::ClassItem'->new($_) } @$_ ] };

declare 'MapStringClassItem',
    as HashRef[ClassItem()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::CustomClass::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::CustomClass::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::CustomClass::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'PhraseSet',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::PhraseSet'];

coerce 'PhraseSet',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::PhraseSet'->new($_) };

declare 'RepeatedPhraseSet',
    as ArrayRef[PhraseSet()];

coerce 'RepeatedPhraseSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::PhraseSet'->new($_) } @$_ ] };

declare 'MapStringPhraseSet',
    as HashRef[PhraseSet()];

declare 'State',
    as (Int | Str);

declare 'Phrase',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::PhraseSet::Phrase'];

coerce 'Phrase',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::PhraseSet::Phrase'->new($_) };

declare 'RepeatedPhrase',
    as ArrayRef[Phrase()];

coerce 'RepeatedPhrase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::PhraseSet::Phrase'->new($_) } @$_ ] };

declare 'MapStringPhrase',
    as HashRef[Phrase()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::PhraseSet::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::PhraseSet::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::PhraseSet::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'CreateCustomClassRequest',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::CreateCustomClassRequest'];

coerce 'CreateCustomClassRequest',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::CreateCustomClassRequest'->new($_) };

declare 'RepeatedCreateCustomClassRequest',
    as ArrayRef[CreateCustomClassRequest()];

coerce 'RepeatedCreateCustomClassRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::CreateCustomClassRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCustomClassRequest',
    as HashRef[CreateCustomClassRequest()];

declare 'ListCustomClassesRequest',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::ListCustomClassesRequest'];

coerce 'ListCustomClassesRequest',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::ListCustomClassesRequest'->new($_) };

declare 'RepeatedListCustomClassesRequest',
    as ArrayRef[ListCustomClassesRequest()];

coerce 'RepeatedListCustomClassesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::ListCustomClassesRequest'->new($_) } @$_ ] };

declare 'MapStringListCustomClassesRequest',
    as HashRef[ListCustomClassesRequest()];

declare 'ListCustomClassesResponse',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::ListCustomClassesResponse'];

coerce 'ListCustomClassesResponse',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::ListCustomClassesResponse'->new($_) };

declare 'RepeatedListCustomClassesResponse',
    as ArrayRef[ListCustomClassesResponse()];

coerce 'RepeatedListCustomClassesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::ListCustomClassesResponse'->new($_) } @$_ ] };

declare 'MapStringListCustomClassesResponse',
    as HashRef[ListCustomClassesResponse()];

declare 'GetCustomClassRequest',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::GetCustomClassRequest'];

coerce 'GetCustomClassRequest',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::GetCustomClassRequest'->new($_) };

declare 'RepeatedGetCustomClassRequest',
    as ArrayRef[GetCustomClassRequest()];

coerce 'RepeatedGetCustomClassRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::GetCustomClassRequest'->new($_) } @$_ ] };

declare 'MapStringGetCustomClassRequest',
    as HashRef[GetCustomClassRequest()];

declare 'UpdateCustomClassRequest',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::UpdateCustomClassRequest'];

coerce 'UpdateCustomClassRequest',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::UpdateCustomClassRequest'->new($_) };

declare 'RepeatedUpdateCustomClassRequest',
    as ArrayRef[UpdateCustomClassRequest()];

coerce 'RepeatedUpdateCustomClassRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::UpdateCustomClassRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCustomClassRequest',
    as HashRef[UpdateCustomClassRequest()];

declare 'DeleteCustomClassRequest',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::DeleteCustomClassRequest'];

coerce 'DeleteCustomClassRequest',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::DeleteCustomClassRequest'->new($_) };

declare 'RepeatedDeleteCustomClassRequest',
    as ArrayRef[DeleteCustomClassRequest()];

coerce 'RepeatedDeleteCustomClassRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::DeleteCustomClassRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCustomClassRequest',
    as HashRef[DeleteCustomClassRequest()];

declare 'UndeleteCustomClassRequest',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::UndeleteCustomClassRequest'];

coerce 'UndeleteCustomClassRequest',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::UndeleteCustomClassRequest'->new($_) };

declare 'RepeatedUndeleteCustomClassRequest',
    as ArrayRef[UndeleteCustomClassRequest()];

coerce 'RepeatedUndeleteCustomClassRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::UndeleteCustomClassRequest'->new($_) } @$_ ] };

declare 'MapStringUndeleteCustomClassRequest',
    as HashRef[UndeleteCustomClassRequest()];

declare 'CreatePhraseSetRequest',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::CreatePhraseSetRequest'];

coerce 'CreatePhraseSetRequest',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::CreatePhraseSetRequest'->new($_) };

declare 'RepeatedCreatePhraseSetRequest',
    as ArrayRef[CreatePhraseSetRequest()];

coerce 'RepeatedCreatePhraseSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::CreatePhraseSetRequest'->new($_) } @$_ ] };

declare 'MapStringCreatePhraseSetRequest',
    as HashRef[CreatePhraseSetRequest()];

declare 'ListPhraseSetsRequest',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::ListPhraseSetsRequest'];

coerce 'ListPhraseSetsRequest',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::ListPhraseSetsRequest'->new($_) };

declare 'RepeatedListPhraseSetsRequest',
    as ArrayRef[ListPhraseSetsRequest()];

coerce 'RepeatedListPhraseSetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::ListPhraseSetsRequest'->new($_) } @$_ ] };

declare 'MapStringListPhraseSetsRequest',
    as HashRef[ListPhraseSetsRequest()];

declare 'ListPhraseSetsResponse',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::ListPhraseSetsResponse'];

coerce 'ListPhraseSetsResponse',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::ListPhraseSetsResponse'->new($_) };

declare 'RepeatedListPhraseSetsResponse',
    as ArrayRef[ListPhraseSetsResponse()];

coerce 'RepeatedListPhraseSetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::ListPhraseSetsResponse'->new($_) } @$_ ] };

declare 'MapStringListPhraseSetsResponse',
    as HashRef[ListPhraseSetsResponse()];

declare 'GetPhraseSetRequest',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::GetPhraseSetRequest'];

coerce 'GetPhraseSetRequest',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::GetPhraseSetRequest'->new($_) };

declare 'RepeatedGetPhraseSetRequest',
    as ArrayRef[GetPhraseSetRequest()];

coerce 'RepeatedGetPhraseSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::GetPhraseSetRequest'->new($_) } @$_ ] };

declare 'MapStringGetPhraseSetRequest',
    as HashRef[GetPhraseSetRequest()];

declare 'UpdatePhraseSetRequest',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::UpdatePhraseSetRequest'];

coerce 'UpdatePhraseSetRequest',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::UpdatePhraseSetRequest'->new($_) };

declare 'RepeatedUpdatePhraseSetRequest',
    as ArrayRef[UpdatePhraseSetRequest()];

coerce 'RepeatedUpdatePhraseSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::UpdatePhraseSetRequest'->new($_) } @$_ ] };

declare 'MapStringUpdatePhraseSetRequest',
    as HashRef[UpdatePhraseSetRequest()];

declare 'DeletePhraseSetRequest',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::DeletePhraseSetRequest'];

coerce 'DeletePhraseSetRequest',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::DeletePhraseSetRequest'->new($_) };

declare 'RepeatedDeletePhraseSetRequest',
    as ArrayRef[DeletePhraseSetRequest()];

coerce 'RepeatedDeletePhraseSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::DeletePhraseSetRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePhraseSetRequest',
    as HashRef[DeletePhraseSetRequest()];

declare 'UndeletePhraseSetRequest',
    as InstanceOf['Google::Cloud::Speech::V2::CloudSpeech::UndeletePhraseSetRequest'];

coerce 'UndeletePhraseSetRequest',
    from HashRef, via { 'Google::Cloud::Speech::V2::CloudSpeech::UndeletePhraseSetRequest'->new($_) };

declare 'RepeatedUndeletePhraseSetRequest',
    as ArrayRef[UndeletePhraseSetRequest()];

coerce 'RepeatedUndeletePhraseSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V2::CloudSpeech::UndeletePhraseSetRequest'->new($_) } @$_ ] };

declare 'MapStringUndeletePhraseSetRequest',
    as HashRef[UndeletePhraseSetRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Speech::V2::CloudSpeech::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
