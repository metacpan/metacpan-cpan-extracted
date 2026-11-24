package Google::Cloud::Ces::V1::App::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'App',
    as InstanceOf['Google::Cloud::Ces::V1::App::App'];

coerce 'App',
    from HashRef, via { 'Google::Cloud::Ces::V1::App::App'->new($_) };

declare 'RepeatedApp',
    as ArrayRef[App()];

coerce 'RepeatedApp',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::App::App'->new($_) } @$_ ] };

declare 'MapStringApp',
    as HashRef[App()];

declare 'ToolExecutionMode',
    as (Int | Str);

declare 'VariableDeclaration',
    as InstanceOf['Google::Cloud::Ces::V1::App::App::VariableDeclaration'];

coerce 'VariableDeclaration',
    from HashRef, via { 'Google::Cloud::Ces::V1::App::App::VariableDeclaration'->new($_) };

declare 'RepeatedVariableDeclaration',
    as ArrayRef[VariableDeclaration()];

coerce 'RepeatedVariableDeclaration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::App::App::VariableDeclaration'->new($_) } @$_ ] };

declare 'MapStringVariableDeclaration',
    as HashRef[VariableDeclaration()];

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Ces::V1::App::App::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Ces::V1::App::App::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::App::App::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'TimeZoneSettings',
    as InstanceOf['Google::Cloud::Ces::V1::App::TimeZoneSettings'];

coerce 'TimeZoneSettings',
    from HashRef, via { 'Google::Cloud::Ces::V1::App::TimeZoneSettings'->new($_) };

declare 'RepeatedTimeZoneSettings',
    as ArrayRef[TimeZoneSettings()];

coerce 'RepeatedTimeZoneSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::App::TimeZoneSettings'->new($_) } @$_ ] };

declare 'MapStringTimeZoneSettings',
    as HashRef[TimeZoneSettings()];

declare 'LanguageSettings',
    as InstanceOf['Google::Cloud::Ces::V1::App::LanguageSettings'];

coerce 'LanguageSettings',
    from HashRef, via { 'Google::Cloud::Ces::V1::App::LanguageSettings'->new($_) };

declare 'RepeatedLanguageSettings',
    as ArrayRef[LanguageSettings()];

coerce 'RepeatedLanguageSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::App::LanguageSettings'->new($_) } @$_ ] };

declare 'MapStringLanguageSettings',
    as HashRef[LanguageSettings()];

declare 'AudioProcessingConfig',
    as InstanceOf['Google::Cloud::Ces::V1::App::AudioProcessingConfig'];

coerce 'AudioProcessingConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1::App::AudioProcessingConfig'->new($_) };

declare 'RepeatedAudioProcessingConfig',
    as ArrayRef[AudioProcessingConfig()];

coerce 'RepeatedAudioProcessingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::App::AudioProcessingConfig'->new($_) } @$_ ] };

declare 'MapStringAudioProcessingConfig',
    as HashRef[AudioProcessingConfig()];

declare 'SynthesizeSpeechConfigsEntry',
    as InstanceOf['Google::Cloud::Ces::V1::App::AudioProcessingConfig::SynthesizeSpeechConfigsEntry'];

coerce 'SynthesizeSpeechConfigsEntry',
    from HashRef, via { 'Google::Cloud::Ces::V1::App::AudioProcessingConfig::SynthesizeSpeechConfigsEntry'->new($_) };

declare 'RepeatedSynthesizeSpeechConfigsEntry',
    as ArrayRef[SynthesizeSpeechConfigsEntry()];

coerce 'RepeatedSynthesizeSpeechConfigsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::App::AudioProcessingConfig::SynthesizeSpeechConfigsEntry'->new($_) } @$_ ] };

declare 'MapStringSynthesizeSpeechConfigsEntry',
    as HashRef[SynthesizeSpeechConfigsEntry()];

declare 'AmbientSoundConfig',
    as InstanceOf['Google::Cloud::Ces::V1::App::AmbientSoundConfig'];

coerce 'AmbientSoundConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1::App::AmbientSoundConfig'->new($_) };

declare 'RepeatedAmbientSoundConfig',
    as ArrayRef[AmbientSoundConfig()];

coerce 'RepeatedAmbientSoundConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::App::AmbientSoundConfig'->new($_) } @$_ ] };

declare 'MapStringAmbientSoundConfig',
    as HashRef[AmbientSoundConfig()];

declare 'PrebuiltAmbientNoise',
    as (Int | Str);

declare 'BargeInConfig',
    as InstanceOf['Google::Cloud::Ces::V1::App::BargeInConfig'];

coerce 'BargeInConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1::App::BargeInConfig'->new($_) };

declare 'RepeatedBargeInConfig',
    as ArrayRef[BargeInConfig()];

coerce 'RepeatedBargeInConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::App::BargeInConfig'->new($_) } @$_ ] };

declare 'MapStringBargeInConfig',
    as HashRef[BargeInConfig()];

declare 'SynthesizeSpeechConfig',
    as InstanceOf['Google::Cloud::Ces::V1::App::SynthesizeSpeechConfig'];

coerce 'SynthesizeSpeechConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1::App::SynthesizeSpeechConfig'->new($_) };

declare 'RepeatedSynthesizeSpeechConfig',
    as ArrayRef[SynthesizeSpeechConfig()];

coerce 'RepeatedSynthesizeSpeechConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::App::SynthesizeSpeechConfig'->new($_) } @$_ ] };

declare 'MapStringSynthesizeSpeechConfig',
    as HashRef[SynthesizeSpeechConfig()];

declare 'MetricAnalysisSettings',
    as InstanceOf['Google::Cloud::Ces::V1::App::MetricAnalysisSettings'];

coerce 'MetricAnalysisSettings',
    from HashRef, via { 'Google::Cloud::Ces::V1::App::MetricAnalysisSettings'->new($_) };

declare 'RepeatedMetricAnalysisSettings',
    as ArrayRef[MetricAnalysisSettings()];

coerce 'RepeatedMetricAnalysisSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::App::MetricAnalysisSettings'->new($_) } @$_ ] };

declare 'MapStringMetricAnalysisSettings',
    as HashRef[MetricAnalysisSettings()];

declare 'LoggingSettings',
    as InstanceOf['Google::Cloud::Ces::V1::App::LoggingSettings'];

coerce 'LoggingSettings',
    from HashRef, via { 'Google::Cloud::Ces::V1::App::LoggingSettings'->new($_) };

declare 'RepeatedLoggingSettings',
    as ArrayRef[LoggingSettings()];

coerce 'RepeatedLoggingSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::App::LoggingSettings'->new($_) } @$_ ] };

declare 'MapStringLoggingSettings',
    as HashRef[LoggingSettings()];

declare 'ErrorHandlingSettings',
    as InstanceOf['Google::Cloud::Ces::V1::App::ErrorHandlingSettings'];

coerce 'ErrorHandlingSettings',
    from HashRef, via { 'Google::Cloud::Ces::V1::App::ErrorHandlingSettings'->new($_) };

declare 'RepeatedErrorHandlingSettings',
    as ArrayRef[ErrorHandlingSettings()];

coerce 'RepeatedErrorHandlingSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::App::ErrorHandlingSettings'->new($_) } @$_ ] };

declare 'MapStringErrorHandlingSettings',
    as HashRef[ErrorHandlingSettings()];

declare 'ErrorHandlingStrategy',
    as (Int | Str);

declare 'FallbackResponseConfig',
    as InstanceOf['Google::Cloud::Ces::V1::App::ErrorHandlingSettings::FallbackResponseConfig'];

coerce 'FallbackResponseConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1::App::ErrorHandlingSettings::FallbackResponseConfig'->new($_) };

declare 'RepeatedFallbackResponseConfig',
    as ArrayRef[FallbackResponseConfig()];

coerce 'RepeatedFallbackResponseConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::App::ErrorHandlingSettings::FallbackResponseConfig'->new($_) } @$_ ] };

declare 'MapStringFallbackResponseConfig',
    as HashRef[FallbackResponseConfig()];

declare 'CustomFallbackMessagesEntry',
    as InstanceOf['Google::Cloud::Ces::V1::App::ErrorHandlingSettings::FallbackResponseConfig::CustomFallbackMessagesEntry'];

coerce 'CustomFallbackMessagesEntry',
    from HashRef, via { 'Google::Cloud::Ces::V1::App::ErrorHandlingSettings::FallbackResponseConfig::CustomFallbackMessagesEntry'->new($_) };

declare 'RepeatedCustomFallbackMessagesEntry',
    as ArrayRef[CustomFallbackMessagesEntry()];

coerce 'RepeatedCustomFallbackMessagesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::App::ErrorHandlingSettings::FallbackResponseConfig::CustomFallbackMessagesEntry'->new($_) } @$_ ] };

declare 'MapStringCustomFallbackMessagesEntry',
    as HashRef[CustomFallbackMessagesEntry()];

declare 'EndSessionConfig',
    as InstanceOf['Google::Cloud::Ces::V1::App::ErrorHandlingSettings::EndSessionConfig'];

coerce 'EndSessionConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1::App::ErrorHandlingSettings::EndSessionConfig'->new($_) };

declare 'RepeatedEndSessionConfig',
    as ArrayRef[EndSessionConfig()];

coerce 'RepeatedEndSessionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::App::ErrorHandlingSettings::EndSessionConfig'->new($_) } @$_ ] };

declare 'MapStringEndSessionConfig',
    as HashRef[EndSessionConfig()];

declare 'EvaluationMetricsThresholds',
    as InstanceOf['Google::Cloud::Ces::V1::App::EvaluationMetricsThresholds'];

coerce 'EvaluationMetricsThresholds',
    from HashRef, via { 'Google::Cloud::Ces::V1::App::EvaluationMetricsThresholds'->new($_) };

declare 'RepeatedEvaluationMetricsThresholds',
    as ArrayRef[EvaluationMetricsThresholds()];

coerce 'RepeatedEvaluationMetricsThresholds',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::App::EvaluationMetricsThresholds'->new($_) } @$_ ] };

declare 'MapStringEvaluationMetricsThresholds',
    as HashRef[EvaluationMetricsThresholds()];

declare 'HallucinationMetricBehavior',
    as (Int | Str);

declare 'GoldenEvaluationMetricsThresholds',
    as InstanceOf['Google::Cloud::Ces::V1::App::EvaluationMetricsThresholds::GoldenEvaluationMetricsThresholds'];

coerce 'GoldenEvaluationMetricsThresholds',
    from HashRef, via { 'Google::Cloud::Ces::V1::App::EvaluationMetricsThresholds::GoldenEvaluationMetricsThresholds'->new($_) };

declare 'RepeatedGoldenEvaluationMetricsThresholds',
    as ArrayRef[GoldenEvaluationMetricsThresholds()];

coerce 'RepeatedGoldenEvaluationMetricsThresholds',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::App::EvaluationMetricsThresholds::GoldenEvaluationMetricsThresholds'->new($_) } @$_ ] };

declare 'MapStringGoldenEvaluationMetricsThresholds',
    as HashRef[GoldenEvaluationMetricsThresholds()];

declare 'TurnLevelMetricsThresholds',
    as InstanceOf['Google::Cloud::Ces::V1::App::EvaluationMetricsThresholds::GoldenEvaluationMetricsThresholds::TurnLevelMetricsThresholds'];

coerce 'TurnLevelMetricsThresholds',
    from HashRef, via { 'Google::Cloud::Ces::V1::App::EvaluationMetricsThresholds::GoldenEvaluationMetricsThresholds::TurnLevelMetricsThresholds'->new($_) };

declare 'RepeatedTurnLevelMetricsThresholds',
    as ArrayRef[TurnLevelMetricsThresholds()];

coerce 'RepeatedTurnLevelMetricsThresholds',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::App::EvaluationMetricsThresholds::GoldenEvaluationMetricsThresholds::TurnLevelMetricsThresholds'->new($_) } @$_ ] };

declare 'MapStringTurnLevelMetricsThresholds',
    as HashRef[TurnLevelMetricsThresholds()];

declare 'SemanticSimilarityChannel',
    as (Int | Str);

declare 'ExpectationLevelMetricsThresholds',
    as InstanceOf['Google::Cloud::Ces::V1::App::EvaluationMetricsThresholds::GoldenEvaluationMetricsThresholds::ExpectationLevelMetricsThresholds'];

coerce 'ExpectationLevelMetricsThresholds',
    from HashRef, via { 'Google::Cloud::Ces::V1::App::EvaluationMetricsThresholds::GoldenEvaluationMetricsThresholds::ExpectationLevelMetricsThresholds'->new($_) };

declare 'RepeatedExpectationLevelMetricsThresholds',
    as ArrayRef[ExpectationLevelMetricsThresholds()];

coerce 'RepeatedExpectationLevelMetricsThresholds',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::App::EvaluationMetricsThresholds::GoldenEvaluationMetricsThresholds::ExpectationLevelMetricsThresholds'->new($_) } @$_ ] };

declare 'MapStringExpectationLevelMetricsThresholds',
    as HashRef[ExpectationLevelMetricsThresholds()];

declare 'ToolMatchingSettings',
    as InstanceOf['Google::Cloud::Ces::V1::App::EvaluationMetricsThresholds::ToolMatchingSettings'];

coerce 'ToolMatchingSettings',
    from HashRef, via { 'Google::Cloud::Ces::V1::App::EvaluationMetricsThresholds::ToolMatchingSettings'->new($_) };

declare 'RepeatedToolMatchingSettings',
    as ArrayRef[ToolMatchingSettings()];

coerce 'RepeatedToolMatchingSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::App::EvaluationMetricsThresholds::ToolMatchingSettings'->new($_) } @$_ ] };

declare 'MapStringToolMatchingSettings',
    as HashRef[ToolMatchingSettings()];

declare 'ExtraToolCallBehavior',
    as (Int | Str);

declare 'ClientCertificateSettings',
    as InstanceOf['Google::Cloud::Ces::V1::App::ClientCertificateSettings'];

coerce 'ClientCertificateSettings',
    from HashRef, via { 'Google::Cloud::Ces::V1::App::ClientCertificateSettings'->new($_) };

declare 'RepeatedClientCertificateSettings',
    as ArrayRef[ClientCertificateSettings()];

coerce 'RepeatedClientCertificateSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::App::ClientCertificateSettings'->new($_) } @$_ ] };

declare 'MapStringClientCertificateSettings',
    as HashRef[ClientCertificateSettings()];

declare 'VpcScSettings',
    as InstanceOf['Google::Cloud::Ces::V1::App::VpcScSettings'];

coerce 'VpcScSettings',
    from HashRef, via { 'Google::Cloud::Ces::V1::App::VpcScSettings'->new($_) };

declare 'RepeatedVpcScSettings',
    as ArrayRef[VpcScSettings()];

coerce 'RepeatedVpcScSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::App::VpcScSettings'->new($_) } @$_ ] };

declare 'MapStringVpcScSettings',
    as HashRef[VpcScSettings()];

declare 'ConversationLoggingSettings',
    as InstanceOf['Google::Cloud::Ces::V1::App::ConversationLoggingSettings'];

coerce 'ConversationLoggingSettings',
    from HashRef, via { 'Google::Cloud::Ces::V1::App::ConversationLoggingSettings'->new($_) };

declare 'RepeatedConversationLoggingSettings',
    as ArrayRef[ConversationLoggingSettings()];

coerce 'RepeatedConversationLoggingSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::App::ConversationLoggingSettings'->new($_) } @$_ ] };

declare 'MapStringConversationLoggingSettings',
    as HashRef[ConversationLoggingSettings()];

declare 'CloudLoggingSettings',
    as InstanceOf['Google::Cloud::Ces::V1::App::CloudLoggingSettings'];

coerce 'CloudLoggingSettings',
    from HashRef, via { 'Google::Cloud::Ces::V1::App::CloudLoggingSettings'->new($_) };

declare 'RepeatedCloudLoggingSettings',
    as ArrayRef[CloudLoggingSettings()];

coerce 'RepeatedCloudLoggingSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::App::CloudLoggingSettings'->new($_) } @$_ ] };

declare 'MapStringCloudLoggingSettings',
    as HashRef[CloudLoggingSettings()];

declare 'AudioRecordingConfig',
    as InstanceOf['Google::Cloud::Ces::V1::App::AudioRecordingConfig'];

coerce 'AudioRecordingConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1::App::AudioRecordingConfig'->new($_) };

declare 'RepeatedAudioRecordingConfig',
    as ArrayRef[AudioRecordingConfig()];

coerce 'RepeatedAudioRecordingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::App::AudioRecordingConfig'->new($_) } @$_ ] };

declare 'MapStringAudioRecordingConfig',
    as HashRef[AudioRecordingConfig()];

declare 'RedactionConfig',
    as InstanceOf['Google::Cloud::Ces::V1::App::RedactionConfig'];

coerce 'RedactionConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1::App::RedactionConfig'->new($_) };

declare 'RepeatedRedactionConfig',
    as ArrayRef[RedactionConfig()];

coerce 'RepeatedRedactionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::App::RedactionConfig'->new($_) } @$_ ] };

declare 'MapStringRedactionConfig',
    as HashRef[RedactionConfig()];

declare 'DataStoreSettings',
    as InstanceOf['Google::Cloud::Ces::V1::App::DataStoreSettings'];

coerce 'DataStoreSettings',
    from HashRef, via { 'Google::Cloud::Ces::V1::App::DataStoreSettings'->new($_) };

declare 'RepeatedDataStoreSettings',
    as ArrayRef[DataStoreSettings()];

coerce 'RepeatedDataStoreSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::App::DataStoreSettings'->new($_) } @$_ ] };

declare 'MapStringDataStoreSettings',
    as HashRef[DataStoreSettings()];

declare 'Engine',
    as InstanceOf['Google::Cloud::Ces::V1::App::DataStoreSettings::Engine'];

coerce 'Engine',
    from HashRef, via { 'Google::Cloud::Ces::V1::App::DataStoreSettings::Engine'->new($_) };

declare 'RepeatedEngine',
    as ArrayRef[Engine()];

coerce 'RepeatedEngine',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::App::DataStoreSettings::Engine'->new($_) } @$_ ] };

declare 'MapStringEngine',
    as HashRef[Engine()];

declare 'Type',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1::App::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
