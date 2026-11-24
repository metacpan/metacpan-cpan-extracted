package Google::Cloud::Apigeeconnect::V1::Tether::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Action',
    as (Int | Str);

declare 'TetherEndpoint',
    as (Int | Str);

declare 'Scheme',
    as (Int | Str);

declare 'EgressRequest',
    as InstanceOf['Google::Cloud::Apigeeconnect::V1::Tether::EgressRequest'];

coerce 'EgressRequest',
    from HashRef, via { 'Google::Cloud::Apigeeconnect::V1::Tether::EgressRequest'->new($_) };

declare 'RepeatedEgressRequest',
    as ArrayRef[EgressRequest()];

coerce 'RepeatedEgressRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigeeconnect::V1::Tether::EgressRequest'->new($_) } @$_ ] };

declare 'MapStringEgressRequest',
    as HashRef[EgressRequest()];

declare 'Payload',
    as InstanceOf['Google::Cloud::Apigeeconnect::V1::Tether::Payload'];

coerce 'Payload',
    from HashRef, via { 'Google::Cloud::Apigeeconnect::V1::Tether::Payload'->new($_) };

declare 'RepeatedPayload',
    as ArrayRef[Payload()];

coerce 'RepeatedPayload',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigeeconnect::V1::Tether::Payload'->new($_) } @$_ ] };

declare 'MapStringPayload',
    as HashRef[Payload()];

declare 'StreamInfo',
    as InstanceOf['Google::Cloud::Apigeeconnect::V1::Tether::StreamInfo'];

coerce 'StreamInfo',
    from HashRef, via { 'Google::Cloud::Apigeeconnect::V1::Tether::StreamInfo'->new($_) };

declare 'RepeatedStreamInfo',
    as ArrayRef[StreamInfo()];

coerce 'RepeatedStreamInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigeeconnect::V1::Tether::StreamInfo'->new($_) } @$_ ] };

declare 'MapStringStreamInfo',
    as HashRef[StreamInfo()];

declare 'EgressResponse',
    as InstanceOf['Google::Cloud::Apigeeconnect::V1::Tether::EgressResponse'];

coerce 'EgressResponse',
    from HashRef, via { 'Google::Cloud::Apigeeconnect::V1::Tether::EgressResponse'->new($_) };

declare 'RepeatedEgressResponse',
    as ArrayRef[EgressResponse()];

coerce 'RepeatedEgressResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigeeconnect::V1::Tether::EgressResponse'->new($_) } @$_ ] };

declare 'MapStringEgressResponse',
    as HashRef[EgressResponse()];

declare 'HttpRequest',
    as InstanceOf['Google::Cloud::Apigeeconnect::V1::Tether::HttpRequest'];

coerce 'HttpRequest',
    from HashRef, via { 'Google::Cloud::Apigeeconnect::V1::Tether::HttpRequest'->new($_) };

declare 'RepeatedHttpRequest',
    as ArrayRef[HttpRequest()];

coerce 'RepeatedHttpRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigeeconnect::V1::Tether::HttpRequest'->new($_) } @$_ ] };

declare 'MapStringHttpRequest',
    as HashRef[HttpRequest()];

declare 'Url',
    as InstanceOf['Google::Cloud::Apigeeconnect::V1::Tether::Url'];

coerce 'Url',
    from HashRef, via { 'Google::Cloud::Apigeeconnect::V1::Tether::Url'->new($_) };

declare 'RepeatedUrl',
    as ArrayRef[Url()];

coerce 'RepeatedUrl',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigeeconnect::V1::Tether::Url'->new($_) } @$_ ] };

declare 'MapStringUrl',
    as HashRef[Url()];

declare 'Header',
    as InstanceOf['Google::Cloud::Apigeeconnect::V1::Tether::Header'];

coerce 'Header',
    from HashRef, via { 'Google::Cloud::Apigeeconnect::V1::Tether::Header'->new($_) };

declare 'RepeatedHeader',
    as ArrayRef[Header()];

coerce 'RepeatedHeader',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigeeconnect::V1::Tether::Header'->new($_) } @$_ ] };

declare 'MapStringHeader',
    as HashRef[Header()];

declare 'HttpResponse',
    as InstanceOf['Google::Cloud::Apigeeconnect::V1::Tether::HttpResponse'];

coerce 'HttpResponse',
    from HashRef, via { 'Google::Cloud::Apigeeconnect::V1::Tether::HttpResponse'->new($_) };

declare 'RepeatedHttpResponse',
    as ArrayRef[HttpResponse()];

coerce 'RepeatedHttpResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apigeeconnect::V1::Tether::HttpResponse'->new($_) } @$_ ] };

declare 'MapStringHttpResponse',
    as HashRef[HttpResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Apigeeconnect::V1::Tether::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
