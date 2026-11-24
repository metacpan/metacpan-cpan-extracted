package Google::Cloud::Dialogflow::V2beta1::Webhook::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'WebhookRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Webhook::WebhookRequest'];

coerce 'WebhookRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Webhook::WebhookRequest'->new($_) };

declare 'RepeatedWebhookRequest',
    as ArrayRef[WebhookRequest()];

coerce 'RepeatedWebhookRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Webhook::WebhookRequest'->new($_) } @$_ ] };

declare 'MapStringWebhookRequest',
    as HashRef[WebhookRequest()];

declare 'WebhookResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Webhook::WebhookResponse'];

coerce 'WebhookResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Webhook::WebhookResponse'->new($_) };

declare 'RepeatedWebhookResponse',
    as ArrayRef[WebhookResponse()];

coerce 'RepeatedWebhookResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Webhook::WebhookResponse'->new($_) } @$_ ] };

declare 'MapStringWebhookResponse',
    as HashRef[WebhookResponse()];

declare 'OriginalDetectIntentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Webhook::OriginalDetectIntentRequest'];

coerce 'OriginalDetectIntentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Webhook::OriginalDetectIntentRequest'->new($_) };

declare 'RepeatedOriginalDetectIntentRequest',
    as ArrayRef[OriginalDetectIntentRequest()];

coerce 'RepeatedOriginalDetectIntentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Webhook::OriginalDetectIntentRequest'->new($_) } @$_ ] };

declare 'MapStringOriginalDetectIntentRequest',
    as HashRef[OriginalDetectIntentRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::Webhook::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
