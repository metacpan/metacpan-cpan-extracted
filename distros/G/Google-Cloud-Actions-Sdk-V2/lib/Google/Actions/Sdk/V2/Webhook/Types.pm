package Google::Actions::Sdk::V2::Webhook::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Webhook',
    as InstanceOf['Google::Actions::Sdk::V2::Webhook::Webhook'];

coerce 'Webhook',
    from HashRef, via { 'Google::Actions::Sdk::V2::Webhook::Webhook'->new($_) };

declare 'RepeatedWebhook',
    as ArrayRef[Webhook()];

coerce 'RepeatedWebhook',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Webhook::Webhook'->new($_) } @$_ ] };

declare 'MapStringWebhook',
    as HashRef[Webhook()];

declare 'Handler',
    as InstanceOf['Google::Actions::Sdk::V2::Webhook::Webhook::Handler'];

coerce 'Handler',
    from HashRef, via { 'Google::Actions::Sdk::V2::Webhook::Webhook::Handler'->new($_) };

declare 'RepeatedHandler',
    as ArrayRef[Handler()];

coerce 'RepeatedHandler',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Webhook::Webhook::Handler'->new($_) } @$_ ] };

declare 'MapStringHandler',
    as HashRef[Handler()];

declare 'HttpsEndpoint',
    as InstanceOf['Google::Actions::Sdk::V2::Webhook::Webhook::HttpsEndpoint'];

coerce 'HttpsEndpoint',
    from HashRef, via { 'Google::Actions::Sdk::V2::Webhook::Webhook::HttpsEndpoint'->new($_) };

declare 'RepeatedHttpsEndpoint',
    as ArrayRef[HttpsEndpoint()];

coerce 'RepeatedHttpsEndpoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Webhook::Webhook::HttpsEndpoint'->new($_) } @$_ ] };

declare 'MapStringHttpsEndpoint',
    as HashRef[HttpsEndpoint()];

declare 'HttpHeadersEntry',
    as InstanceOf['Google::Actions::Sdk::V2::Webhook::Webhook::HttpsEndpoint::HttpHeadersEntry'];

coerce 'HttpHeadersEntry',
    from HashRef, via { 'Google::Actions::Sdk::V2::Webhook::Webhook::HttpsEndpoint::HttpHeadersEntry'->new($_) };

declare 'RepeatedHttpHeadersEntry',
    as ArrayRef[HttpHeadersEntry()];

coerce 'RepeatedHttpHeadersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Webhook::Webhook::HttpsEndpoint::HttpHeadersEntry'->new($_) } @$_ ] };

declare 'MapStringHttpHeadersEntry',
    as HashRef[HttpHeadersEntry()];

declare 'InlineCloudFunction',
    as InstanceOf['Google::Actions::Sdk::V2::Webhook::Webhook::InlineCloudFunction'];

coerce 'InlineCloudFunction',
    from HashRef, via { 'Google::Actions::Sdk::V2::Webhook::Webhook::InlineCloudFunction'->new($_) };

declare 'RepeatedInlineCloudFunction',
    as ArrayRef[InlineCloudFunction()];

coerce 'RepeatedInlineCloudFunction',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Webhook::Webhook::InlineCloudFunction'->new($_) } @$_ ] };

declare 'MapStringInlineCloudFunction',
    as HashRef[InlineCloudFunction()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Webhook::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
