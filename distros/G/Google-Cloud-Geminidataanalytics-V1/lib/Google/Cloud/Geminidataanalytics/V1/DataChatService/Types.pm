package Google::Cloud::Geminidataanalytics::V1::DataChatService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListMessagesRequest',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::DataChatService::ListMessagesRequest'];

coerce 'ListMessagesRequest',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::ListMessagesRequest'->new($_) };

declare 'RepeatedListMessagesRequest',
    as ArrayRef[ListMessagesRequest()];

coerce 'RepeatedListMessagesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::ListMessagesRequest'->new($_) } @$_ ] };

declare 'MapStringListMessagesRequest',
    as HashRef[ListMessagesRequest()];

declare 'ListMessagesResponse',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::DataChatService::ListMessagesResponse'];

coerce 'ListMessagesResponse',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::ListMessagesResponse'->new($_) };

declare 'RepeatedListMessagesResponse',
    as ArrayRef[ListMessagesResponse()];

coerce 'RepeatedListMessagesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::ListMessagesResponse'->new($_) } @$_ ] };

declare 'MapStringListMessagesResponse',
    as HashRef[ListMessagesResponse()];

declare 'StorageMessage',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::DataChatService::StorageMessage'];

coerce 'StorageMessage',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::StorageMessage'->new($_) };

declare 'RepeatedStorageMessage',
    as ArrayRef[StorageMessage()];

coerce 'RepeatedStorageMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::StorageMessage'->new($_) } @$_ ] };

declare 'MapStringStorageMessage',
    as HashRef[StorageMessage()];

declare 'ChatRequest',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::DataChatService::ChatRequest'];

coerce 'ChatRequest',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::ChatRequest'->new($_) };

declare 'RepeatedChatRequest',
    as ArrayRef[ChatRequest()];

coerce 'RepeatedChatRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::ChatRequest'->new($_) } @$_ ] };

declare 'MapStringChatRequest',
    as HashRef[ChatRequest()];

declare 'ThinkingMode',
    as (Int | Str);

declare 'Model',
    as (Int | Str);

declare 'DataAgentContext',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::DataChatService::DataAgentContext'];

coerce 'DataAgentContext',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::DataAgentContext'->new($_) };

declare 'RepeatedDataAgentContext',
    as ArrayRef[DataAgentContext()];

coerce 'RepeatedDataAgentContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::DataAgentContext'->new($_) } @$_ ] };

declare 'MapStringDataAgentContext',
    as HashRef[DataAgentContext()];

declare 'ContextVersion',
    as (Int | Str);

declare 'ConversationReference',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::DataChatService::ConversationReference'];

coerce 'ConversationReference',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::ConversationReference'->new($_) };

declare 'RepeatedConversationReference',
    as ArrayRef[ConversationReference()];

coerce 'RepeatedConversationReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::ConversationReference'->new($_) } @$_ ] };

declare 'MapStringConversationReference',
    as HashRef[ConversationReference()];

declare 'ClientManagedResourceContext',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::DataChatService::ClientManagedResourceContext'];

coerce 'ClientManagedResourceContext',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::ClientManagedResourceContext'->new($_) };

declare 'RepeatedClientManagedResourceContext',
    as ArrayRef[ClientManagedResourceContext()];

coerce 'RepeatedClientManagedResourceContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::ClientManagedResourceContext'->new($_) } @$_ ] };

declare 'MapStringClientManagedResourceContext',
    as HashRef[ClientManagedResourceContext()];

declare 'Message',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::DataChatService::Message'];

coerce 'Message',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::Message'->new($_) };

declare 'RepeatedMessage',
    as ArrayRef[Message()];

coerce 'RepeatedMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::Message'->new($_) } @$_ ] };

declare 'MapStringMessage',
    as HashRef[Message()];

declare 'LookerSettings',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::DataChatService::LookerSettings'];

coerce 'LookerSettings',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::LookerSettings'->new($_) };

declare 'RepeatedLookerSettings',
    as ArrayRef[LookerSettings()];

coerce 'RepeatedLookerSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::LookerSettings'->new($_) } @$_ ] };

declare 'MapStringLookerSettings',
    as HashRef[LookerSettings()];

declare 'UserMessage',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::DataChatService::UserMessage'];

coerce 'UserMessage',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::UserMessage'->new($_) };

declare 'RepeatedUserMessage',
    as ArrayRef[UserMessage()];

coerce 'RepeatedUserMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::UserMessage'->new($_) } @$_ ] };

declare 'MapStringUserMessage',
    as HashRef[UserMessage()];

declare 'SystemMessage',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::DataChatService::SystemMessage'];

coerce 'SystemMessage',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::SystemMessage'->new($_) };

declare 'RepeatedSystemMessage',
    as ArrayRef[SystemMessage()];

coerce 'RepeatedSystemMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::SystemMessage'->new($_) } @$_ ] };

declare 'MapStringSystemMessage',
    as HashRef[SystemMessage()];

declare 'TextMessage',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::DataChatService::TextMessage'];

coerce 'TextMessage',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::TextMessage'->new($_) };

declare 'RepeatedTextMessage',
    as ArrayRef[TextMessage()];

coerce 'RepeatedTextMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::TextMessage'->new($_) } @$_ ] };

declare 'MapStringTextMessage',
    as HashRef[TextMessage()];

declare 'TextType',
    as (Int | Str);

declare 'SchemaMessage',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::DataChatService::SchemaMessage'];

coerce 'SchemaMessage',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::SchemaMessage'->new($_) };

declare 'RepeatedSchemaMessage',
    as ArrayRef[SchemaMessage()];

coerce 'RepeatedSchemaMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::SchemaMessage'->new($_) } @$_ ] };

declare 'MapStringSchemaMessage',
    as HashRef[SchemaMessage()];

declare 'SchemaQuery',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::DataChatService::SchemaQuery'];

coerce 'SchemaQuery',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::SchemaQuery'->new($_) };

declare 'RepeatedSchemaQuery',
    as ArrayRef[SchemaQuery()];

coerce 'RepeatedSchemaQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::SchemaQuery'->new($_) } @$_ ] };

declare 'MapStringSchemaQuery',
    as HashRef[SchemaQuery()];

declare 'SchemaResult',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::DataChatService::SchemaResult'];

coerce 'SchemaResult',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::SchemaResult'->new($_) };

declare 'RepeatedSchemaResult',
    as ArrayRef[SchemaResult()];

coerce 'RepeatedSchemaResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::SchemaResult'->new($_) } @$_ ] };

declare 'MapStringSchemaResult',
    as HashRef[SchemaResult()];

declare 'DataMessage',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::DataChatService::DataMessage'];

coerce 'DataMessage',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::DataMessage'->new($_) };

declare 'RepeatedDataMessage',
    as ArrayRef[DataMessage()];

coerce 'RepeatedDataMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::DataMessage'->new($_) } @$_ ] };

declare 'MapStringDataMessage',
    as HashRef[DataMessage()];

declare 'DataQuery',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::DataChatService::DataQuery'];

coerce 'DataQuery',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::DataQuery'->new($_) };

declare 'RepeatedDataQuery',
    as ArrayRef[DataQuery()];

coerce 'RepeatedDataQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::DataQuery'->new($_) } @$_ ] };

declare 'MapStringDataQuery',
    as HashRef[DataQuery()];

declare 'DataResult',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::DataChatService::DataResult'];

coerce 'DataResult',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::DataResult'->new($_) };

declare 'RepeatedDataResult',
    as ArrayRef[DataResult()];

coerce 'RepeatedDataResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::DataResult'->new($_) } @$_ ] };

declare 'MapStringDataResult',
    as HashRef[DataResult()];

declare 'BigQueryJob',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::DataChatService::BigQueryJob'];

coerce 'BigQueryJob',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::BigQueryJob'->new($_) };

declare 'RepeatedBigQueryJob',
    as ArrayRef[BigQueryJob()];

coerce 'RepeatedBigQueryJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::BigQueryJob'->new($_) } @$_ ] };

declare 'MapStringBigQueryJob',
    as HashRef[BigQueryJob()];

declare 'AnalysisMessage',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::DataChatService::AnalysisMessage'];

coerce 'AnalysisMessage',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::AnalysisMessage'->new($_) };

declare 'RepeatedAnalysisMessage',
    as ArrayRef[AnalysisMessage()];

coerce 'RepeatedAnalysisMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::AnalysisMessage'->new($_) } @$_ ] };

declare 'MapStringAnalysisMessage',
    as HashRef[AnalysisMessage()];

declare 'AnalysisQuery',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::DataChatService::AnalysisQuery'];

coerce 'AnalysisQuery',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::AnalysisQuery'->new($_) };

declare 'RepeatedAnalysisQuery',
    as ArrayRef[AnalysisQuery()];

coerce 'RepeatedAnalysisQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::AnalysisQuery'->new($_) } @$_ ] };

declare 'MapStringAnalysisQuery',
    as HashRef[AnalysisQuery()];

declare 'AnalysisEvent',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::DataChatService::AnalysisEvent'];

coerce 'AnalysisEvent',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::AnalysisEvent'->new($_) };

declare 'RepeatedAnalysisEvent',
    as ArrayRef[AnalysisEvent()];

coerce 'RepeatedAnalysisEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::AnalysisEvent'->new($_) } @$_ ] };

declare 'MapStringAnalysisEvent',
    as HashRef[AnalysisEvent()];

declare 'ChartMessage',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::DataChatService::ChartMessage'];

coerce 'ChartMessage',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::ChartMessage'->new($_) };

declare 'RepeatedChartMessage',
    as ArrayRef[ChartMessage()];

coerce 'RepeatedChartMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::ChartMessage'->new($_) } @$_ ] };

declare 'MapStringChartMessage',
    as HashRef[ChartMessage()];

declare 'ChartQuery',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::DataChatService::ChartQuery'];

coerce 'ChartQuery',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::ChartQuery'->new($_) };

declare 'RepeatedChartQuery',
    as ArrayRef[ChartQuery()];

coerce 'RepeatedChartQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::ChartQuery'->new($_) } @$_ ] };

declare 'MapStringChartQuery',
    as HashRef[ChartQuery()];

declare 'ChartResult',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::DataChatService::ChartResult'];

coerce 'ChartResult',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::ChartResult'->new($_) };

declare 'RepeatedChartResult',
    as ArrayRef[ChartResult()];

coerce 'RepeatedChartResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::ChartResult'->new($_) } @$_ ] };

declare 'MapStringChartResult',
    as HashRef[ChartResult()];

declare 'ErrorMessage',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::DataChatService::ErrorMessage'];

coerce 'ErrorMessage',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::ErrorMessage'->new($_) };

declare 'RepeatedErrorMessage',
    as ArrayRef[ErrorMessage()];

coerce 'RepeatedErrorMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::ErrorMessage'->new($_) } @$_ ] };

declare 'MapStringErrorMessage',
    as HashRef[ErrorMessage()];

declare 'ExampleQueries',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::DataChatService::ExampleQueries'];

coerce 'ExampleQueries',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::ExampleQueries'->new($_) };

declare 'RepeatedExampleQueries',
    as ArrayRef[ExampleQueries()];

coerce 'RepeatedExampleQueries',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::ExampleQueries'->new($_) } @$_ ] };

declare 'MapStringExampleQueries',
    as HashRef[ExampleQueries()];

declare 'Blob',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::DataChatService::Blob'];

coerce 'Blob',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::Blob'->new($_) };

declare 'RepeatedBlob',
    as ArrayRef[Blob()];

coerce 'RepeatedBlob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::DataChatService::Blob'->new($_) } @$_ ] };

declare 'MapStringBlob',
    as HashRef[Blob()];

1;

__END__

=head1 NAME

Google::Cloud::Geminidataanalytics::V1::DataChatService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
