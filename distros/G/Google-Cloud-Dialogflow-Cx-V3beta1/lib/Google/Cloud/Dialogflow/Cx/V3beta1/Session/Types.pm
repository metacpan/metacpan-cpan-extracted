package Google::Cloud::Dialogflow::Cx::V3beta1::Session::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DetectIntentResponseView',
    as (Int | Str);

declare 'AnswerFeedback',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Session::AnswerFeedback'];

coerce 'AnswerFeedback',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::AnswerFeedback'->new($_) };

declare 'RepeatedAnswerFeedback',
    as ArrayRef[AnswerFeedback()];

coerce 'RepeatedAnswerFeedback',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::AnswerFeedback'->new($_) } @$_ ] };

declare 'MapStringAnswerFeedback',
    as HashRef[AnswerFeedback()];

declare 'Rating',
    as (Int | Str);

declare 'RatingReason',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Session::AnswerFeedback::RatingReason'];

coerce 'RatingReason',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::AnswerFeedback::RatingReason'->new($_) };

declare 'RepeatedRatingReason',
    as ArrayRef[RatingReason()];

coerce 'RepeatedRatingReason',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::AnswerFeedback::RatingReason'->new($_) } @$_ ] };

declare 'MapStringRatingReason',
    as HashRef[RatingReason()];

declare 'SubmitAnswerFeedbackRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Session::SubmitAnswerFeedbackRequest'];

coerce 'SubmitAnswerFeedbackRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::SubmitAnswerFeedbackRequest'->new($_) };

declare 'RepeatedSubmitAnswerFeedbackRequest',
    as ArrayRef[SubmitAnswerFeedbackRequest()];

coerce 'RepeatedSubmitAnswerFeedbackRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::SubmitAnswerFeedbackRequest'->new($_) } @$_ ] };

declare 'MapStringSubmitAnswerFeedbackRequest',
    as HashRef[SubmitAnswerFeedbackRequest()];

declare 'DetectIntentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Session::DetectIntentRequest'];

coerce 'DetectIntentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::DetectIntentRequest'->new($_) };

declare 'RepeatedDetectIntentRequest',
    as ArrayRef[DetectIntentRequest()];

coerce 'RepeatedDetectIntentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::DetectIntentRequest'->new($_) } @$_ ] };

declare 'MapStringDetectIntentRequest',
    as HashRef[DetectIntentRequest()];

declare 'DetectIntentResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Session::DetectIntentResponse'];

coerce 'DetectIntentResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::DetectIntentResponse'->new($_) };

declare 'RepeatedDetectIntentResponse',
    as ArrayRef[DetectIntentResponse()];

coerce 'RepeatedDetectIntentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::DetectIntentResponse'->new($_) } @$_ ] };

declare 'MapStringDetectIntentResponse',
    as HashRef[DetectIntentResponse()];

declare 'ResponseType',
    as (Int | Str);

declare 'StreamingDetectIntentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Session::StreamingDetectIntentRequest'];

coerce 'StreamingDetectIntentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::StreamingDetectIntentRequest'->new($_) };

declare 'RepeatedStreamingDetectIntentRequest',
    as ArrayRef[StreamingDetectIntentRequest()];

coerce 'RepeatedStreamingDetectIntentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::StreamingDetectIntentRequest'->new($_) } @$_ ] };

declare 'MapStringStreamingDetectIntentRequest',
    as HashRef[StreamingDetectIntentRequest()];

declare 'CloudConversationDebuggingInfo',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Session::CloudConversationDebuggingInfo'];

coerce 'CloudConversationDebuggingInfo',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::CloudConversationDebuggingInfo'->new($_) };

declare 'RepeatedCloudConversationDebuggingInfo',
    as ArrayRef[CloudConversationDebuggingInfo()];

coerce 'RepeatedCloudConversationDebuggingInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::CloudConversationDebuggingInfo'->new($_) } @$_ ] };

declare 'MapStringCloudConversationDebuggingInfo',
    as HashRef[CloudConversationDebuggingInfo()];

declare 'StreamingDetectIntentResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Session::StreamingDetectIntentResponse'];

coerce 'StreamingDetectIntentResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::StreamingDetectIntentResponse'->new($_) };

declare 'RepeatedStreamingDetectIntentResponse',
    as ArrayRef[StreamingDetectIntentResponse()];

coerce 'RepeatedStreamingDetectIntentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::StreamingDetectIntentResponse'->new($_) } @$_ ] };

declare 'MapStringStreamingDetectIntentResponse',
    as HashRef[StreamingDetectIntentResponse()];

declare 'StreamingRecognitionResult',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Session::StreamingRecognitionResult'];

coerce 'StreamingRecognitionResult',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::StreamingRecognitionResult'->new($_) };

declare 'RepeatedStreamingRecognitionResult',
    as ArrayRef[StreamingRecognitionResult()];

coerce 'RepeatedStreamingRecognitionResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::StreamingRecognitionResult'->new($_) } @$_ ] };

declare 'MapStringStreamingRecognitionResult',
    as HashRef[StreamingRecognitionResult()];

declare 'MessageType',
    as (Int | Str);

declare 'QueryParameters',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Session::QueryParameters'];

coerce 'QueryParameters',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::QueryParameters'->new($_) };

declare 'RepeatedQueryParameters',
    as ArrayRef[QueryParameters()];

coerce 'RepeatedQueryParameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::QueryParameters'->new($_) } @$_ ] };

declare 'MapStringQueryParameters',
    as HashRef[QueryParameters()];

declare 'WebhookHeadersEntry',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Session::QueryParameters::WebhookHeadersEntry'];

coerce 'WebhookHeadersEntry',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::QueryParameters::WebhookHeadersEntry'->new($_) };

declare 'RepeatedWebhookHeadersEntry',
    as ArrayRef[WebhookHeadersEntry()];

coerce 'RepeatedWebhookHeadersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::QueryParameters::WebhookHeadersEntry'->new($_) } @$_ ] };

declare 'MapStringWebhookHeadersEntry',
    as HashRef[WebhookHeadersEntry()];

declare 'SearchConfig',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Session::SearchConfig'];

coerce 'SearchConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::SearchConfig'->new($_) };

declare 'RepeatedSearchConfig',
    as ArrayRef[SearchConfig()];

coerce 'RepeatedSearchConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::SearchConfig'->new($_) } @$_ ] };

declare 'MapStringSearchConfig',
    as HashRef[SearchConfig()];

declare 'BoostSpec',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Session::BoostSpec'];

coerce 'BoostSpec',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::BoostSpec'->new($_) };

declare 'RepeatedBoostSpec',
    as ArrayRef[BoostSpec()];

coerce 'RepeatedBoostSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::BoostSpec'->new($_) } @$_ ] };

declare 'MapStringBoostSpec',
    as HashRef[BoostSpec()];

declare 'ConditionBoostSpec',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Session::BoostSpec::ConditionBoostSpec'];

coerce 'ConditionBoostSpec',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::BoostSpec::ConditionBoostSpec'->new($_) };

declare 'RepeatedConditionBoostSpec',
    as ArrayRef[ConditionBoostSpec()];

coerce 'RepeatedConditionBoostSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::BoostSpec::ConditionBoostSpec'->new($_) } @$_ ] };

declare 'MapStringConditionBoostSpec',
    as HashRef[ConditionBoostSpec()];

declare 'BoostControlSpec',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Session::BoostSpec::ConditionBoostSpec::BoostControlSpec'];

coerce 'BoostControlSpec',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::BoostSpec::ConditionBoostSpec::BoostControlSpec'->new($_) };

declare 'RepeatedBoostControlSpec',
    as ArrayRef[BoostControlSpec()];

coerce 'RepeatedBoostControlSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::BoostSpec::ConditionBoostSpec::BoostControlSpec'->new($_) } @$_ ] };

declare 'MapStringBoostControlSpec',
    as HashRef[BoostControlSpec()];

declare 'AttributeType',
    as (Int | Str);

declare 'InterpolationType',
    as (Int | Str);

declare 'ControlPoint',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Session::BoostSpec::ConditionBoostSpec::BoostControlSpec::ControlPoint'];

coerce 'ControlPoint',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::BoostSpec::ConditionBoostSpec::BoostControlSpec::ControlPoint'->new($_) };

declare 'RepeatedControlPoint',
    as ArrayRef[ControlPoint()];

coerce 'RepeatedControlPoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::BoostSpec::ConditionBoostSpec::BoostControlSpec::ControlPoint'->new($_) } @$_ ] };

declare 'MapStringControlPoint',
    as HashRef[ControlPoint()];

declare 'BoostSpecs',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Session::BoostSpecs'];

coerce 'BoostSpecs',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::BoostSpecs'->new($_) };

declare 'RepeatedBoostSpecs',
    as ArrayRef[BoostSpecs()];

coerce 'RepeatedBoostSpecs',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::BoostSpecs'->new($_) } @$_ ] };

declare 'MapStringBoostSpecs',
    as HashRef[BoostSpecs()];

declare 'FilterSpecs',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Session::FilterSpecs'];

coerce 'FilterSpecs',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::FilterSpecs'->new($_) };

declare 'RepeatedFilterSpecs',
    as ArrayRef[FilterSpecs()];

coerce 'RepeatedFilterSpecs',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::FilterSpecs'->new($_) } @$_ ] };

declare 'MapStringFilterSpecs',
    as HashRef[FilterSpecs()];

declare 'QueryInput',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Session::QueryInput'];

coerce 'QueryInput',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::QueryInput'->new($_) };

declare 'RepeatedQueryInput',
    as ArrayRef[QueryInput()];

coerce 'RepeatedQueryInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::QueryInput'->new($_) } @$_ ] };

declare 'MapStringQueryInput',
    as HashRef[QueryInput()];

declare 'GenerativeInfo',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Session::GenerativeInfo'];

coerce 'GenerativeInfo',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::GenerativeInfo'->new($_) };

declare 'RepeatedGenerativeInfo',
    as ArrayRef[GenerativeInfo()];

coerce 'RepeatedGenerativeInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::GenerativeInfo'->new($_) } @$_ ] };

declare 'MapStringGenerativeInfo',
    as HashRef[GenerativeInfo()];

declare 'QueryResult',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Session::QueryResult'];

coerce 'QueryResult',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::QueryResult'->new($_) };

declare 'RepeatedQueryResult',
    as ArrayRef[QueryResult()];

coerce 'RepeatedQueryResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::QueryResult'->new($_) } @$_ ] };

declare 'MapStringQueryResult',
    as HashRef[QueryResult()];

declare 'TextInput',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Session::TextInput'];

coerce 'TextInput',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::TextInput'->new($_) };

declare 'RepeatedTextInput',
    as ArrayRef[TextInput()];

coerce 'RepeatedTextInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::TextInput'->new($_) } @$_ ] };

declare 'MapStringTextInput',
    as HashRef[TextInput()];

declare 'IntentInput',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Session::IntentInput'];

coerce 'IntentInput',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::IntentInput'->new($_) };

declare 'RepeatedIntentInput',
    as ArrayRef[IntentInput()];

coerce 'RepeatedIntentInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::IntentInput'->new($_) } @$_ ] };

declare 'MapStringIntentInput',
    as HashRef[IntentInput()];

declare 'AudioInput',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Session::AudioInput'];

coerce 'AudioInput',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::AudioInput'->new($_) };

declare 'RepeatedAudioInput',
    as ArrayRef[AudioInput()];

coerce 'RepeatedAudioInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::AudioInput'->new($_) } @$_ ] };

declare 'MapStringAudioInput',
    as HashRef[AudioInput()];

declare 'EventInput',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Session::EventInput'];

coerce 'EventInput',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::EventInput'->new($_) };

declare 'RepeatedEventInput',
    as ArrayRef[EventInput()];

coerce 'RepeatedEventInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::EventInput'->new($_) } @$_ ] };

declare 'MapStringEventInput',
    as HashRef[EventInput()];

declare 'DtmfInput',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Session::DtmfInput'];

coerce 'DtmfInput',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::DtmfInput'->new($_) };

declare 'RepeatedDtmfInput',
    as ArrayRef[DtmfInput()];

coerce 'RepeatedDtmfInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::DtmfInput'->new($_) } @$_ ] };

declare 'MapStringDtmfInput',
    as HashRef[DtmfInput()];

declare 'Match',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Session::Match'];

coerce 'Match',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::Match'->new($_) };

declare 'RepeatedMatch',
    as ArrayRef[Match()];

coerce 'RepeatedMatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::Match'->new($_) } @$_ ] };

declare 'MapStringMatch',
    as HashRef[Match()];

declare 'MatchType',
    as (Int | Str);

declare 'MatchIntentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Session::MatchIntentRequest'];

coerce 'MatchIntentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::MatchIntentRequest'->new($_) };

declare 'RepeatedMatchIntentRequest',
    as ArrayRef[MatchIntentRequest()];

coerce 'RepeatedMatchIntentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::MatchIntentRequest'->new($_) } @$_ ] };

declare 'MapStringMatchIntentRequest',
    as HashRef[MatchIntentRequest()];

declare 'MatchIntentResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Session::MatchIntentResponse'];

coerce 'MatchIntentResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::MatchIntentResponse'->new($_) };

declare 'RepeatedMatchIntentResponse',
    as ArrayRef[MatchIntentResponse()];

coerce 'RepeatedMatchIntentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::MatchIntentResponse'->new($_) } @$_ ] };

declare 'MapStringMatchIntentResponse',
    as HashRef[MatchIntentResponse()];

declare 'FulfillIntentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Session::FulfillIntentRequest'];

coerce 'FulfillIntentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::FulfillIntentRequest'->new($_) };

declare 'RepeatedFulfillIntentRequest',
    as ArrayRef[FulfillIntentRequest()];

coerce 'RepeatedFulfillIntentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::FulfillIntentRequest'->new($_) } @$_ ] };

declare 'MapStringFulfillIntentRequest',
    as HashRef[FulfillIntentRequest()];

declare 'FulfillIntentResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Session::FulfillIntentResponse'];

coerce 'FulfillIntentResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::FulfillIntentResponse'->new($_) };

declare 'RepeatedFulfillIntentResponse',
    as ArrayRef[FulfillIntentResponse()];

coerce 'RepeatedFulfillIntentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::FulfillIntentResponse'->new($_) } @$_ ] };

declare 'MapStringFulfillIntentResponse',
    as HashRef[FulfillIntentResponse()];

declare 'SentimentAnalysisResult',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Session::SentimentAnalysisResult'];

coerce 'SentimentAnalysisResult',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::SentimentAnalysisResult'->new($_) };

declare 'RepeatedSentimentAnalysisResult',
    as ArrayRef[SentimentAnalysisResult()];

coerce 'RepeatedSentimentAnalysisResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Session::SentimentAnalysisResult'->new($_) } @$_ ] };

declare 'MapStringSentimentAnalysisResult',
    as HashRef[SentimentAnalysisResult()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::Session::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
