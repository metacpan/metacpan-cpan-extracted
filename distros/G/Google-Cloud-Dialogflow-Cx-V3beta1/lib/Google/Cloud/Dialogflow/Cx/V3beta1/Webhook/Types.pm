package Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Webhook',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::Webhook'];

coerce 'Webhook',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::Webhook'->new($_) };

declare 'RepeatedWebhook',
    as ArrayRef[Webhook()];

coerce 'RepeatedWebhook',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::Webhook'->new($_) } @$_ ] };

declare 'MapStringWebhook',
    as HashRef[Webhook()];

declare 'GenericWebService',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::Webhook::GenericWebService'];

coerce 'GenericWebService',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::Webhook::GenericWebService'->new($_) };

declare 'RepeatedGenericWebService',
    as ArrayRef[GenericWebService()];

coerce 'RepeatedGenericWebService',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::Webhook::GenericWebService'->new($_) } @$_ ] };

declare 'MapStringGenericWebService',
    as HashRef[GenericWebService()];

declare 'ServiceAgentAuth',
    as (Int | Str);

declare 'WebhookType',
    as (Int | Str);

declare 'HttpMethod',
    as (Int | Str);

declare 'SecretVersionHeaderValue',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::Webhook::GenericWebService::SecretVersionHeaderValue'];

coerce 'SecretVersionHeaderValue',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::Webhook::GenericWebService::SecretVersionHeaderValue'->new($_) };

declare 'RepeatedSecretVersionHeaderValue',
    as ArrayRef[SecretVersionHeaderValue()];

coerce 'RepeatedSecretVersionHeaderValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::Webhook::GenericWebService::SecretVersionHeaderValue'->new($_) } @$_ ] };

declare 'MapStringSecretVersionHeaderValue',
    as HashRef[SecretVersionHeaderValue()];

declare 'OAuthConfig',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::Webhook::GenericWebService::OAuthConfig'];

coerce 'OAuthConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::Webhook::GenericWebService::OAuthConfig'->new($_) };

declare 'RepeatedOAuthConfig',
    as ArrayRef[OAuthConfig()];

coerce 'RepeatedOAuthConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::Webhook::GenericWebService::OAuthConfig'->new($_) } @$_ ] };

declare 'MapStringOAuthConfig',
    as HashRef[OAuthConfig()];

declare 'ServiceAccountAuthConfig',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::Webhook::GenericWebService::ServiceAccountAuthConfig'];

coerce 'ServiceAccountAuthConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::Webhook::GenericWebService::ServiceAccountAuthConfig'->new($_) };

declare 'RepeatedServiceAccountAuthConfig',
    as ArrayRef[ServiceAccountAuthConfig()];

coerce 'RepeatedServiceAccountAuthConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::Webhook::GenericWebService::ServiceAccountAuthConfig'->new($_) } @$_ ] };

declare 'MapStringServiceAccountAuthConfig',
    as HashRef[ServiceAccountAuthConfig()];

declare 'RequestHeadersEntry',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::Webhook::GenericWebService::RequestHeadersEntry'];

coerce 'RequestHeadersEntry',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::Webhook::GenericWebService::RequestHeadersEntry'->new($_) };

declare 'RepeatedRequestHeadersEntry',
    as ArrayRef[RequestHeadersEntry()];

coerce 'RepeatedRequestHeadersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::Webhook::GenericWebService::RequestHeadersEntry'->new($_) } @$_ ] };

declare 'MapStringRequestHeadersEntry',
    as HashRef[RequestHeadersEntry()];

declare 'SecretVersionsForRequestHeadersEntry',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::Webhook::GenericWebService::SecretVersionsForRequestHeadersEntry'];

coerce 'SecretVersionsForRequestHeadersEntry',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::Webhook::GenericWebService::SecretVersionsForRequestHeadersEntry'->new($_) };

declare 'RepeatedSecretVersionsForRequestHeadersEntry',
    as ArrayRef[SecretVersionsForRequestHeadersEntry()];

coerce 'RepeatedSecretVersionsForRequestHeadersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::Webhook::GenericWebService::SecretVersionsForRequestHeadersEntry'->new($_) } @$_ ] };

declare 'MapStringSecretVersionsForRequestHeadersEntry',
    as HashRef[SecretVersionsForRequestHeadersEntry()];

declare 'ParameterMappingEntry',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::Webhook::GenericWebService::ParameterMappingEntry'];

coerce 'ParameterMappingEntry',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::Webhook::GenericWebService::ParameterMappingEntry'->new($_) };

declare 'RepeatedParameterMappingEntry',
    as ArrayRef[ParameterMappingEntry()];

coerce 'RepeatedParameterMappingEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::Webhook::GenericWebService::ParameterMappingEntry'->new($_) } @$_ ] };

declare 'MapStringParameterMappingEntry',
    as HashRef[ParameterMappingEntry()];

declare 'ServiceDirectoryConfig',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::Webhook::ServiceDirectoryConfig'];

coerce 'ServiceDirectoryConfig',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::Webhook::ServiceDirectoryConfig'->new($_) };

declare 'RepeatedServiceDirectoryConfig',
    as ArrayRef[ServiceDirectoryConfig()];

coerce 'RepeatedServiceDirectoryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::Webhook::ServiceDirectoryConfig'->new($_) } @$_ ] };

declare 'MapStringServiceDirectoryConfig',
    as HashRef[ServiceDirectoryConfig()];

declare 'ListWebhooksRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::ListWebhooksRequest'];

coerce 'ListWebhooksRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::ListWebhooksRequest'->new($_) };

declare 'RepeatedListWebhooksRequest',
    as ArrayRef[ListWebhooksRequest()];

coerce 'RepeatedListWebhooksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::ListWebhooksRequest'->new($_) } @$_ ] };

declare 'MapStringListWebhooksRequest',
    as HashRef[ListWebhooksRequest()];

declare 'ListWebhooksResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::ListWebhooksResponse'];

coerce 'ListWebhooksResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::ListWebhooksResponse'->new($_) };

declare 'RepeatedListWebhooksResponse',
    as ArrayRef[ListWebhooksResponse()];

coerce 'RepeatedListWebhooksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::ListWebhooksResponse'->new($_) } @$_ ] };

declare 'MapStringListWebhooksResponse',
    as HashRef[ListWebhooksResponse()];

declare 'GetWebhookRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::GetWebhookRequest'];

coerce 'GetWebhookRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::GetWebhookRequest'->new($_) };

declare 'RepeatedGetWebhookRequest',
    as ArrayRef[GetWebhookRequest()];

coerce 'RepeatedGetWebhookRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::GetWebhookRequest'->new($_) } @$_ ] };

declare 'MapStringGetWebhookRequest',
    as HashRef[GetWebhookRequest()];

declare 'CreateWebhookRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::CreateWebhookRequest'];

coerce 'CreateWebhookRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::CreateWebhookRequest'->new($_) };

declare 'RepeatedCreateWebhookRequest',
    as ArrayRef[CreateWebhookRequest()];

coerce 'RepeatedCreateWebhookRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::CreateWebhookRequest'->new($_) } @$_ ] };

declare 'MapStringCreateWebhookRequest',
    as HashRef[CreateWebhookRequest()];

declare 'UpdateWebhookRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::UpdateWebhookRequest'];

coerce 'UpdateWebhookRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::UpdateWebhookRequest'->new($_) };

declare 'RepeatedUpdateWebhookRequest',
    as ArrayRef[UpdateWebhookRequest()];

coerce 'RepeatedUpdateWebhookRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::UpdateWebhookRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateWebhookRequest',
    as HashRef[UpdateWebhookRequest()];

declare 'DeleteWebhookRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::DeleteWebhookRequest'];

coerce 'DeleteWebhookRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::DeleteWebhookRequest'->new($_) };

declare 'RepeatedDeleteWebhookRequest',
    as ArrayRef[DeleteWebhookRequest()];

coerce 'RepeatedDeleteWebhookRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::DeleteWebhookRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteWebhookRequest',
    as HashRef[DeleteWebhookRequest()];

declare 'WebhookRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::WebhookRequest'];

coerce 'WebhookRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::WebhookRequest'->new($_) };

declare 'RepeatedWebhookRequest',
    as ArrayRef[WebhookRequest()];

coerce 'RepeatedWebhookRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::WebhookRequest'->new($_) } @$_ ] };

declare 'MapStringWebhookRequest',
    as HashRef[WebhookRequest()];

declare 'FulfillmentInfo',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::WebhookRequest::FulfillmentInfo'];

coerce 'FulfillmentInfo',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::WebhookRequest::FulfillmentInfo'->new($_) };

declare 'RepeatedFulfillmentInfo',
    as ArrayRef[FulfillmentInfo()];

coerce 'RepeatedFulfillmentInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::WebhookRequest::FulfillmentInfo'->new($_) } @$_ ] };

declare 'MapStringFulfillmentInfo',
    as HashRef[FulfillmentInfo()];

declare 'IntentInfo',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::WebhookRequest::IntentInfo'];

coerce 'IntentInfo',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::WebhookRequest::IntentInfo'->new($_) };

declare 'RepeatedIntentInfo',
    as ArrayRef[IntentInfo()];

coerce 'RepeatedIntentInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::WebhookRequest::IntentInfo'->new($_) } @$_ ] };

declare 'MapStringIntentInfo',
    as HashRef[IntentInfo()];

declare 'IntentParameterValue',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::WebhookRequest::IntentInfo::IntentParameterValue'];

coerce 'IntentParameterValue',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::WebhookRequest::IntentInfo::IntentParameterValue'->new($_) };

declare 'RepeatedIntentParameterValue',
    as ArrayRef[IntentParameterValue()];

coerce 'RepeatedIntentParameterValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::WebhookRequest::IntentInfo::IntentParameterValue'->new($_) } @$_ ] };

declare 'MapStringIntentParameterValue',
    as HashRef[IntentParameterValue()];

declare 'ParametersEntry',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::WebhookRequest::IntentInfo::ParametersEntry'];

coerce 'ParametersEntry',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::WebhookRequest::IntentInfo::ParametersEntry'->new($_) };

declare 'RepeatedParametersEntry',
    as ArrayRef[ParametersEntry()];

coerce 'RepeatedParametersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::WebhookRequest::IntentInfo::ParametersEntry'->new($_) } @$_ ] };

declare 'MapStringParametersEntry',
    as HashRef[ParametersEntry()];

declare 'SentimentAnalysisResult',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::WebhookRequest::SentimentAnalysisResult'];

coerce 'SentimentAnalysisResult',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::WebhookRequest::SentimentAnalysisResult'->new($_) };

declare 'RepeatedSentimentAnalysisResult',
    as ArrayRef[SentimentAnalysisResult()];

coerce 'RepeatedSentimentAnalysisResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::WebhookRequest::SentimentAnalysisResult'->new($_) } @$_ ] };

declare 'MapStringSentimentAnalysisResult',
    as HashRef[SentimentAnalysisResult()];

declare 'WebhookResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::WebhookResponse'];

coerce 'WebhookResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::WebhookResponse'->new($_) };

declare 'RepeatedWebhookResponse',
    as ArrayRef[WebhookResponse()];

coerce 'RepeatedWebhookResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::WebhookResponse'->new($_) } @$_ ] };

declare 'MapStringWebhookResponse',
    as HashRef[WebhookResponse()];

declare 'FulfillmentResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::WebhookResponse::FulfillmentResponse'];

coerce 'FulfillmentResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::WebhookResponse::FulfillmentResponse'->new($_) };

declare 'RepeatedFulfillmentResponse',
    as ArrayRef[FulfillmentResponse()];

coerce 'RepeatedFulfillmentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::WebhookResponse::FulfillmentResponse'->new($_) } @$_ ] };

declare 'MapStringFulfillmentResponse',
    as HashRef[FulfillmentResponse()];

declare 'MergeBehavior',
    as (Int | Str);

declare 'PageInfo',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::PageInfo'];

coerce 'PageInfo',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::PageInfo'->new($_) };

declare 'RepeatedPageInfo',
    as ArrayRef[PageInfo()];

coerce 'RepeatedPageInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::PageInfo'->new($_) } @$_ ] };

declare 'MapStringPageInfo',
    as HashRef[PageInfo()];

declare 'FormInfo',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::PageInfo::FormInfo'];

coerce 'FormInfo',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::PageInfo::FormInfo'->new($_) };

declare 'RepeatedFormInfo',
    as ArrayRef[FormInfo()];

coerce 'RepeatedFormInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::PageInfo::FormInfo'->new($_) } @$_ ] };

declare 'MapStringFormInfo',
    as HashRef[FormInfo()];

declare 'ParameterInfo',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::PageInfo::FormInfo::ParameterInfo'];

coerce 'ParameterInfo',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::PageInfo::FormInfo::ParameterInfo'->new($_) };

declare 'RepeatedParameterInfo',
    as ArrayRef[ParameterInfo()];

coerce 'RepeatedParameterInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::PageInfo::FormInfo::ParameterInfo'->new($_) } @$_ ] };

declare 'MapStringParameterInfo',
    as HashRef[ParameterInfo()];

declare 'ParameterState',
    as (Int | Str);

declare 'SessionInfo',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::SessionInfo'];

coerce 'SessionInfo',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::SessionInfo'->new($_) };

declare 'RepeatedSessionInfo',
    as ArrayRef[SessionInfo()];

coerce 'RepeatedSessionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::SessionInfo'->new($_) } @$_ ] };

declare 'MapStringSessionInfo',
    as HashRef[SessionInfo()];

declare 'ParametersEntry',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::SessionInfo::ParametersEntry'];

coerce 'ParametersEntry',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::SessionInfo::ParametersEntry'->new($_) };

declare 'RepeatedParametersEntry',
    as ArrayRef[ParametersEntry()];

coerce 'RepeatedParametersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::SessionInfo::ParametersEntry'->new($_) } @$_ ] };

declare 'MapStringParametersEntry',
    as HashRef[ParametersEntry()];

declare 'LanguageInfo',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::LanguageInfo'];

coerce 'LanguageInfo',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::LanguageInfo'->new($_) };

declare 'RepeatedLanguageInfo',
    as ArrayRef[LanguageInfo()];

coerce 'RepeatedLanguageInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::LanguageInfo'->new($_) } @$_ ] };

declare 'MapStringLanguageInfo',
    as HashRef[LanguageInfo()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::Webhook::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
