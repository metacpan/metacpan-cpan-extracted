package Google::Cloud::Ces::V1beta::App::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'App',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::App'];

coerce 'App',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::App'->new($_) };

declare 'RepeatedApp',
    as ArrayRef[App()];

coerce 'RepeatedApp',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::App'->new($_) } @$_ ] };

declare 'MapStringApp',
    as HashRef[App()];

declare 'ToolExecutionMode',
    as (Int | Str);

declare 'VariableDeclaration',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::App::VariableDeclaration'];

coerce 'VariableDeclaration',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::App::VariableDeclaration'->new($_) };

declare 'RepeatedVariableDeclaration',
    as ArrayRef[VariableDeclaration()];

coerce 'RepeatedVariableDeclaration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::App::VariableDeclaration'->new($_) } @$_ ] };

declare 'MapStringVariableDeclaration',
    as HashRef[VariableDeclaration()];

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::App::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::App::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::App::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'DashboardSettings',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::DashboardSettings'];

coerce 'DashboardSettings',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::DashboardSettings'->new($_) };

declare 'RepeatedDashboardSettings',
    as ArrayRef[DashboardSettings()];

coerce 'RepeatedDashboardSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::DashboardSettings'->new($_) } @$_ ] };

declare 'MapStringDashboardSettings',
    as HashRef[DashboardSettings()];

declare 'TimeZoneSettings',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::TimeZoneSettings'];

coerce 'TimeZoneSettings',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::TimeZoneSettings'->new($_) };

declare 'RepeatedTimeZoneSettings',
    as ArrayRef[TimeZoneSettings()];

coerce 'RepeatedTimeZoneSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::TimeZoneSettings'->new($_) } @$_ ] };

declare 'MapStringTimeZoneSettings',
    as HashRef[TimeZoneSettings()];

declare 'LanguageSettings',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::LanguageSettings'];

coerce 'LanguageSettings',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::LanguageSettings'->new($_) };

declare 'RepeatedLanguageSettings',
    as ArrayRef[LanguageSettings()];

coerce 'RepeatedLanguageSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::LanguageSettings'->new($_) } @$_ ] };

declare 'MapStringLanguageSettings',
    as HashRef[LanguageSettings()];

declare 'CustomVoiceSample',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::CustomVoiceSample'];

coerce 'CustomVoiceSample',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::CustomVoiceSample'->new($_) };

declare 'RepeatedCustomVoiceSample',
    as ArrayRef[CustomVoiceSample()];

coerce 'RepeatedCustomVoiceSample',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::CustomVoiceSample'->new($_) } @$_ ] };

declare 'MapStringCustomVoiceSample',
    as HashRef[CustomVoiceSample()];

declare 'VoiceInstructionMode',
    as (Int | Str);

declare 'Warning',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::CustomVoiceSample::Warning'];

coerce 'Warning',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::CustomVoiceSample::Warning'->new($_) };

declare 'RepeatedWarning',
    as ArrayRef[Warning()];

coerce 'RepeatedWarning',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::CustomVoiceSample::Warning'->new($_) } @$_ ] };

declare 'MapStringWarning',
    as HashRef[Warning()];

declare 'WarningType',
    as (Int | Str);

declare 'AudioProcessingConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::AudioProcessingConfig'];

coerce 'AudioProcessingConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::AudioProcessingConfig'->new($_) };

declare 'RepeatedAudioProcessingConfig',
    as ArrayRef[AudioProcessingConfig()];

coerce 'RepeatedAudioProcessingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::AudioProcessingConfig'->new($_) } @$_ ] };

declare 'MapStringAudioProcessingConfig',
    as HashRef[AudioProcessingConfig()];

declare 'SynthesizeSpeechConfigsEntry',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::AudioProcessingConfig::SynthesizeSpeechConfigsEntry'];

coerce 'SynthesizeSpeechConfigsEntry',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::AudioProcessingConfig::SynthesizeSpeechConfigsEntry'->new($_) };

declare 'RepeatedSynthesizeSpeechConfigsEntry',
    as ArrayRef[SynthesizeSpeechConfigsEntry()];

coerce 'RepeatedSynthesizeSpeechConfigsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::AudioProcessingConfig::SynthesizeSpeechConfigsEntry'->new($_) } @$_ ] };

declare 'MapStringSynthesizeSpeechConfigsEntry',
    as HashRef[SynthesizeSpeechConfigsEntry()];

declare 'AmbientSoundConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::AmbientSoundConfig'];

coerce 'AmbientSoundConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::AmbientSoundConfig'->new($_) };

declare 'RepeatedAmbientSoundConfig',
    as ArrayRef[AmbientSoundConfig()];

coerce 'RepeatedAmbientSoundConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::AmbientSoundConfig'->new($_) } @$_ ] };

declare 'MapStringAmbientSoundConfig',
    as HashRef[AmbientSoundConfig()];

declare 'PrebuiltAmbientNoise',
    as (Int | Str);

declare 'BargeInConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::BargeInConfig'];

coerce 'BargeInConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::BargeInConfig'->new($_) };

declare 'RepeatedBargeInConfig',
    as ArrayRef[BargeInConfig()];

coerce 'RepeatedBargeInConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::BargeInConfig'->new($_) } @$_ ] };

declare 'MapStringBargeInConfig',
    as HashRef[BargeInConfig()];

declare 'SynthesizeSpeechConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::SynthesizeSpeechConfig'];

coerce 'SynthesizeSpeechConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::SynthesizeSpeechConfig'->new($_) };

declare 'RepeatedSynthesizeSpeechConfig',
    as ArrayRef[SynthesizeSpeechConfig()];

coerce 'RepeatedSynthesizeSpeechConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::SynthesizeSpeechConfig'->new($_) } @$_ ] };

declare 'MapStringSynthesizeSpeechConfig',
    as HashRef[SynthesizeSpeechConfig()];

declare 'MetricAnalysisSettings',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::MetricAnalysisSettings'];

coerce 'MetricAnalysisSettings',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::MetricAnalysisSettings'->new($_) };

declare 'RepeatedMetricAnalysisSettings',
    as ArrayRef[MetricAnalysisSettings()];

coerce 'RepeatedMetricAnalysisSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::MetricAnalysisSettings'->new($_) } @$_ ] };

declare 'MapStringMetricAnalysisSettings',
    as HashRef[MetricAnalysisSettings()];

declare 'LoggingSettings',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::LoggingSettings'];

coerce 'LoggingSettings',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::LoggingSettings'->new($_) };

declare 'RepeatedLoggingSettings',
    as ArrayRef[LoggingSettings()];

coerce 'RepeatedLoggingSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::LoggingSettings'->new($_) } @$_ ] };

declare 'MapStringLoggingSettings',
    as HashRef[LoggingSettings()];

declare 'ErrorHandlingSettings',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::ErrorHandlingSettings'];

coerce 'ErrorHandlingSettings',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::ErrorHandlingSettings'->new($_) };

declare 'RepeatedErrorHandlingSettings',
    as ArrayRef[ErrorHandlingSettings()];

coerce 'RepeatedErrorHandlingSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::ErrorHandlingSettings'->new($_) } @$_ ] };

declare 'MapStringErrorHandlingSettings',
    as HashRef[ErrorHandlingSettings()];

declare 'ErrorHandlingStrategy',
    as (Int | Str);

declare 'FallbackResponseConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::ErrorHandlingSettings::FallbackResponseConfig'];

coerce 'FallbackResponseConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::ErrorHandlingSettings::FallbackResponseConfig'->new($_) };

declare 'RepeatedFallbackResponseConfig',
    as ArrayRef[FallbackResponseConfig()];

coerce 'RepeatedFallbackResponseConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::ErrorHandlingSettings::FallbackResponseConfig'->new($_) } @$_ ] };

declare 'MapStringFallbackResponseConfig',
    as HashRef[FallbackResponseConfig()];

declare 'CustomFallbackMessagesEntry',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::ErrorHandlingSettings::FallbackResponseConfig::CustomFallbackMessagesEntry'];

coerce 'CustomFallbackMessagesEntry',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::ErrorHandlingSettings::FallbackResponseConfig::CustomFallbackMessagesEntry'->new($_) };

declare 'RepeatedCustomFallbackMessagesEntry',
    as ArrayRef[CustomFallbackMessagesEntry()];

coerce 'RepeatedCustomFallbackMessagesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::ErrorHandlingSettings::FallbackResponseConfig::CustomFallbackMessagesEntry'->new($_) } @$_ ] };

declare 'MapStringCustomFallbackMessagesEntry',
    as HashRef[CustomFallbackMessagesEntry()];

declare 'EndSessionConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::ErrorHandlingSettings::EndSessionConfig'];

coerce 'EndSessionConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::ErrorHandlingSettings::EndSessionConfig'->new($_) };

declare 'RepeatedEndSessionConfig',
    as ArrayRef[EndSessionConfig()];

coerce 'RepeatedEndSessionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::ErrorHandlingSettings::EndSessionConfig'->new($_) } @$_ ] };

declare 'MapStringEndSessionConfig',
    as HashRef[EndSessionConfig()];

declare 'EvaluationMetricsThresholds',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::EvaluationMetricsThresholds'];

coerce 'EvaluationMetricsThresholds',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::EvaluationMetricsThresholds'->new($_) };

declare 'RepeatedEvaluationMetricsThresholds',
    as ArrayRef[EvaluationMetricsThresholds()];

coerce 'RepeatedEvaluationMetricsThresholds',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::EvaluationMetricsThresholds'->new($_) } @$_ ] };

declare 'MapStringEvaluationMetricsThresholds',
    as HashRef[EvaluationMetricsThresholds()];

declare 'HallucinationMetricBehavior',
    as (Int | Str);

declare 'GoldenEvaluationMetricsThresholds',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::EvaluationMetricsThresholds::GoldenEvaluationMetricsThresholds'];

coerce 'GoldenEvaluationMetricsThresholds',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::EvaluationMetricsThresholds::GoldenEvaluationMetricsThresholds'->new($_) };

declare 'RepeatedGoldenEvaluationMetricsThresholds',
    as ArrayRef[GoldenEvaluationMetricsThresholds()];

coerce 'RepeatedGoldenEvaluationMetricsThresholds',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::EvaluationMetricsThresholds::GoldenEvaluationMetricsThresholds'->new($_) } @$_ ] };

declare 'MapStringGoldenEvaluationMetricsThresholds',
    as HashRef[GoldenEvaluationMetricsThresholds()];

declare 'TurnLevelMetricsThresholds',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::EvaluationMetricsThresholds::GoldenEvaluationMetricsThresholds::TurnLevelMetricsThresholds'];

coerce 'TurnLevelMetricsThresholds',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::EvaluationMetricsThresholds::GoldenEvaluationMetricsThresholds::TurnLevelMetricsThresholds'->new($_) };

declare 'RepeatedTurnLevelMetricsThresholds',
    as ArrayRef[TurnLevelMetricsThresholds()];

coerce 'RepeatedTurnLevelMetricsThresholds',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::EvaluationMetricsThresholds::GoldenEvaluationMetricsThresholds::TurnLevelMetricsThresholds'->new($_) } @$_ ] };

declare 'MapStringTurnLevelMetricsThresholds',
    as HashRef[TurnLevelMetricsThresholds()];

declare 'SemanticSimilarityChannel',
    as (Int | Str);

declare 'ExpectationLevelMetricsThresholds',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::EvaluationMetricsThresholds::GoldenEvaluationMetricsThresholds::ExpectationLevelMetricsThresholds'];

coerce 'ExpectationLevelMetricsThresholds',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::EvaluationMetricsThresholds::GoldenEvaluationMetricsThresholds::ExpectationLevelMetricsThresholds'->new($_) };

declare 'RepeatedExpectationLevelMetricsThresholds',
    as ArrayRef[ExpectationLevelMetricsThresholds()];

coerce 'RepeatedExpectationLevelMetricsThresholds',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::EvaluationMetricsThresholds::GoldenEvaluationMetricsThresholds::ExpectationLevelMetricsThresholds'->new($_) } @$_ ] };

declare 'MapStringExpectationLevelMetricsThresholds',
    as HashRef[ExpectationLevelMetricsThresholds()];

declare 'ToolMatchingSettings',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::EvaluationMetricsThresholds::ToolMatchingSettings'];

coerce 'ToolMatchingSettings',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::EvaluationMetricsThresholds::ToolMatchingSettings'->new($_) };

declare 'RepeatedToolMatchingSettings',
    as ArrayRef[ToolMatchingSettings()];

coerce 'RepeatedToolMatchingSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::EvaluationMetricsThresholds::ToolMatchingSettings'->new($_) } @$_ ] };

declare 'MapStringToolMatchingSettings',
    as HashRef[ToolMatchingSettings()];

declare 'ExtraToolCallBehavior',
    as (Int | Str);

declare 'EvaluationSettings',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::EvaluationSettings'];

coerce 'EvaluationSettings',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::EvaluationSettings'->new($_) };

declare 'RepeatedEvaluationSettings',
    as ArrayRef[EvaluationSettings()];

coerce 'RepeatedEvaluationSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::EvaluationSettings'->new($_) } @$_ ] };

declare 'MapStringEvaluationSettings',
    as HashRef[EvaluationSettings()];

declare 'ScenarioConversationInitiator',
    as (Int | Str);

declare 'ScenarioExecutionMode',
    as (Int | Str);

declare 'ClientCertificateSettings',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::ClientCertificateSettings'];

coerce 'ClientCertificateSettings',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::ClientCertificateSettings'->new($_) };

declare 'RepeatedClientCertificateSettings',
    as ArrayRef[ClientCertificateSettings()];

coerce 'RepeatedClientCertificateSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::ClientCertificateSettings'->new($_) } @$_ ] };

declare 'MapStringClientCertificateSettings',
    as HashRef[ClientCertificateSettings()];

declare 'VpcScSettings',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::VpcScSettings'];

coerce 'VpcScSettings',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::VpcScSettings'->new($_) };

declare 'RepeatedVpcScSettings',
    as ArrayRef[VpcScSettings()];

coerce 'RepeatedVpcScSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::VpcScSettings'->new($_) } @$_ ] };

declare 'MapStringVpcScSettings',
    as HashRef[VpcScSettings()];

declare 'ConversationLoggingSettings',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::ConversationLoggingSettings'];

coerce 'ConversationLoggingSettings',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::ConversationLoggingSettings'->new($_) };

declare 'RepeatedConversationLoggingSettings',
    as ArrayRef[ConversationLoggingSettings()];

coerce 'RepeatedConversationLoggingSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::ConversationLoggingSettings'->new($_) } @$_ ] };

declare 'MapStringConversationLoggingSettings',
    as HashRef[ConversationLoggingSettings()];

declare 'CloudLoggingSettings',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::CloudLoggingSettings'];

coerce 'CloudLoggingSettings',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::CloudLoggingSettings'->new($_) };

declare 'RepeatedCloudLoggingSettings',
    as ArrayRef[CloudLoggingSettings()];

coerce 'RepeatedCloudLoggingSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::CloudLoggingSettings'->new($_) } @$_ ] };

declare 'MapStringCloudLoggingSettings',
    as HashRef[CloudLoggingSettings()];

declare 'AudioRecordingConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::AudioRecordingConfig'];

coerce 'AudioRecordingConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::AudioRecordingConfig'->new($_) };

declare 'RepeatedAudioRecordingConfig',
    as ArrayRef[AudioRecordingConfig()];

coerce 'RepeatedAudioRecordingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::AudioRecordingConfig'->new($_) } @$_ ] };

declare 'MapStringAudioRecordingConfig',
    as HashRef[AudioRecordingConfig()];

declare 'RedactionConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::RedactionConfig'];

coerce 'RedactionConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::RedactionConfig'->new($_) };

declare 'RepeatedRedactionConfig',
    as ArrayRef[RedactionConfig()];

coerce 'RepeatedRedactionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::RedactionConfig'->new($_) } @$_ ] };

declare 'MapStringRedactionConfig',
    as HashRef[RedactionConfig()];

declare 'DataStoreSettings',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::DataStoreSettings'];

coerce 'DataStoreSettings',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::DataStoreSettings'->new($_) };

declare 'RepeatedDataStoreSettings',
    as ArrayRef[DataStoreSettings()];

coerce 'RepeatedDataStoreSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::DataStoreSettings'->new($_) } @$_ ] };

declare 'MapStringDataStoreSettings',
    as HashRef[DataStoreSettings()];

declare 'Engine',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::DataStoreSettings::Engine'];

coerce 'Engine',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::DataStoreSettings::Engine'->new($_) };

declare 'RepeatedEngine',
    as ArrayRef[Engine()];

coerce 'RepeatedEngine',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::DataStoreSettings::Engine'->new($_) } @$_ ] };

declare 'MapStringEngine',
    as HashRef[Engine()];

declare 'Type',
    as (Int | Str);

declare 'EvaluationPersona',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::EvaluationPersona'];

coerce 'EvaluationPersona',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::EvaluationPersona'->new($_) };

declare 'RepeatedEvaluationPersona',
    as ArrayRef[EvaluationPersona()];

coerce 'RepeatedEvaluationPersona',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::EvaluationPersona'->new($_) } @$_ ] };

declare 'MapStringEvaluationPersona',
    as HashRef[EvaluationPersona()];

declare 'SpeechConfig',
    as InstanceOf['Google::Cloud::Ces::V1beta::App::EvaluationPersona::SpeechConfig'];

coerce 'SpeechConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1beta::App::EvaluationPersona::SpeechConfig'->new($_) };

declare 'RepeatedSpeechConfig',
    as ArrayRef[SpeechConfig()];

coerce 'RepeatedSpeechConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1beta::App::EvaluationPersona::SpeechConfig'->new($_) } @$_ ] };

declare 'MapStringSpeechConfig',
    as HashRef[SpeechConfig()];

declare 'BackgroundEnvironment',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1beta::App::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
