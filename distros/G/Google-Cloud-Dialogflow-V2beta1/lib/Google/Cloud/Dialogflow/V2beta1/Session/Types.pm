package Google::Cloud::Dialogflow::V2beta1::Session::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DetectIntentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Session::DetectIntentRequest'];

coerce 'DetectIntentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Session::DetectIntentRequest'->new($_) };

declare 'RepeatedDetectIntentRequest',
    as ArrayRef[DetectIntentRequest()];

coerce 'RepeatedDetectIntentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Session::DetectIntentRequest'->new($_) } @$_ ] };

declare 'MapStringDetectIntentRequest',
    as HashRef[DetectIntentRequest()];

declare 'DetectIntentResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Session::DetectIntentResponse'];

coerce 'DetectIntentResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Session::DetectIntentResponse'->new($_) };

declare 'RepeatedDetectIntentResponse',
    as ArrayRef[DetectIntentResponse()];

coerce 'RepeatedDetectIntentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Session::DetectIntentResponse'->new($_) } @$_ ] };

declare 'MapStringDetectIntentResponse',
    as HashRef[DetectIntentResponse()];

declare 'QueryParameters',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Session::QueryParameters'];

coerce 'QueryParameters',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Session::QueryParameters'->new($_) };

declare 'RepeatedQueryParameters',
    as ArrayRef[QueryParameters()];

coerce 'RepeatedQueryParameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Session::QueryParameters'->new($_) } @$_ ] };

declare 'MapStringQueryParameters',
    as HashRef[QueryParameters()];

declare 'WebhookHeadersEntry',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Session::QueryParameters::WebhookHeadersEntry'];

coerce 'WebhookHeadersEntry',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Session::QueryParameters::WebhookHeadersEntry'->new($_) };

declare 'RepeatedWebhookHeadersEntry',
    as ArrayRef[WebhookHeadersEntry()];

coerce 'RepeatedWebhookHeadersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Session::QueryParameters::WebhookHeadersEntry'->new($_) } @$_ ] };

declare 'MapStringWebhookHeadersEntry',
    as HashRef[WebhookHeadersEntry()];

declare 'QueryInput',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Session::QueryInput'];

coerce 'QueryInput',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Session::QueryInput'->new($_) };

declare 'RepeatedQueryInput',
    as ArrayRef[QueryInput()];

coerce 'RepeatedQueryInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Session::QueryInput'->new($_) } @$_ ] };

declare 'MapStringQueryInput',
    as HashRef[QueryInput()];

declare 'QueryResult',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Session::QueryResult'];

coerce 'QueryResult',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Session::QueryResult'->new($_) };

declare 'RepeatedQueryResult',
    as ArrayRef[QueryResult()];

coerce 'RepeatedQueryResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Session::QueryResult'->new($_) } @$_ ] };

declare 'MapStringQueryResult',
    as HashRef[QueryResult()];

declare 'KnowledgeAnswers',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Session::KnowledgeAnswers'];

coerce 'KnowledgeAnswers',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Session::KnowledgeAnswers'->new($_) };

declare 'RepeatedKnowledgeAnswers',
    as ArrayRef[KnowledgeAnswers()];

coerce 'RepeatedKnowledgeAnswers',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Session::KnowledgeAnswers'->new($_) } @$_ ] };

declare 'MapStringKnowledgeAnswers',
    as HashRef[KnowledgeAnswers()];

declare 'Answer',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Session::KnowledgeAnswers::Answer'];

coerce 'Answer',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Session::KnowledgeAnswers::Answer'->new($_) };

declare 'RepeatedAnswer',
    as ArrayRef[Answer()];

coerce 'RepeatedAnswer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Session::KnowledgeAnswers::Answer'->new($_) } @$_ ] };

declare 'MapStringAnswer',
    as HashRef[Answer()];

declare 'MatchConfidenceLevel',
    as (Int | Str);

declare 'StreamingDetectIntentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Session::StreamingDetectIntentRequest'];

coerce 'StreamingDetectIntentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Session::StreamingDetectIntentRequest'->new($_) };

declare 'RepeatedStreamingDetectIntentRequest',
    as ArrayRef[StreamingDetectIntentRequest()];

coerce 'RepeatedStreamingDetectIntentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Session::StreamingDetectIntentRequest'->new($_) } @$_ ] };

declare 'MapStringStreamingDetectIntentRequest',
    as HashRef[StreamingDetectIntentRequest()];

declare 'CloudConversationDebuggingInfo',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Session::CloudConversationDebuggingInfo'];

coerce 'CloudConversationDebuggingInfo',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Session::CloudConversationDebuggingInfo'->new($_) };

declare 'RepeatedCloudConversationDebuggingInfo',
    as ArrayRef[CloudConversationDebuggingInfo()];

coerce 'RepeatedCloudConversationDebuggingInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Session::CloudConversationDebuggingInfo'->new($_) } @$_ ] };

declare 'MapStringCloudConversationDebuggingInfo',
    as HashRef[CloudConversationDebuggingInfo()];

declare 'StreamingDetectIntentResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Session::StreamingDetectIntentResponse'];

coerce 'StreamingDetectIntentResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Session::StreamingDetectIntentResponse'->new($_) };

declare 'RepeatedStreamingDetectIntentResponse',
    as ArrayRef[StreamingDetectIntentResponse()];

coerce 'RepeatedStreamingDetectIntentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Session::StreamingDetectIntentResponse'->new($_) } @$_ ] };

declare 'MapStringStreamingDetectIntentResponse',
    as HashRef[StreamingDetectIntentResponse()];

declare 'StreamingRecognitionResult',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Session::StreamingRecognitionResult'];

coerce 'StreamingRecognitionResult',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Session::StreamingRecognitionResult'->new($_) };

declare 'RepeatedStreamingRecognitionResult',
    as ArrayRef[StreamingRecognitionResult()];

coerce 'RepeatedStreamingRecognitionResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Session::StreamingRecognitionResult'->new($_) } @$_ ] };

declare 'MapStringStreamingRecognitionResult',
    as HashRef[StreamingRecognitionResult()];

declare 'MessageType',
    as (Int | Str);

declare 'TextInput',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Session::TextInput'];

coerce 'TextInput',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Session::TextInput'->new($_) };

declare 'RepeatedTextInput',
    as ArrayRef[TextInput()];

coerce 'RepeatedTextInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Session::TextInput'->new($_) } @$_ ] };

declare 'MapStringTextInput',
    as HashRef[TextInput()];

declare 'EventInput',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Session::EventInput'];

coerce 'EventInput',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Session::EventInput'->new($_) };

declare 'RepeatedEventInput',
    as ArrayRef[EventInput()];

coerce 'RepeatedEventInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Session::EventInput'->new($_) } @$_ ] };

declare 'MapStringEventInput',
    as HashRef[EventInput()];

declare 'SentimentAnalysisRequestConfig',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Session::SentimentAnalysisRequestConfig'];

coerce 'SentimentAnalysisRequestConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Session::SentimentAnalysisRequestConfig'->new($_) };

declare 'RepeatedSentimentAnalysisRequestConfig',
    as ArrayRef[SentimentAnalysisRequestConfig()];

coerce 'RepeatedSentimentAnalysisRequestConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Session::SentimentAnalysisRequestConfig'->new($_) } @$_ ] };

declare 'MapStringSentimentAnalysisRequestConfig',
    as HashRef[SentimentAnalysisRequestConfig()];

declare 'SentimentAnalysisResult',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Session::SentimentAnalysisResult'];

coerce 'SentimentAnalysisResult',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Session::SentimentAnalysisResult'->new($_) };

declare 'RepeatedSentimentAnalysisResult',
    as ArrayRef[SentimentAnalysisResult()];

coerce 'RepeatedSentimentAnalysisResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Session::SentimentAnalysisResult'->new($_) } @$_ ] };

declare 'MapStringSentimentAnalysisResult',
    as HashRef[SentimentAnalysisResult()];

declare 'Sentiment',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Session::Sentiment'];

coerce 'Sentiment',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Session::Sentiment'->new($_) };

declare 'RepeatedSentiment',
    as ArrayRef[Sentiment()];

coerce 'RepeatedSentiment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Session::Sentiment'->new($_) } @$_ ] };

declare 'MapStringSentiment',
    as HashRef[Sentiment()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::Session::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
