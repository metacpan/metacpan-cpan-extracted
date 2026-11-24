package Google::Cloud::Scheduler::V1beta1::Target::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'HttpMethod',
    as (Int | Str);

declare 'HttpTarget',
    as InstanceOf['Google::Cloud::Scheduler::V1beta1::Target::HttpTarget'];

coerce 'HttpTarget',
    from HashRef, via { 'Google::Cloud::Scheduler::V1beta1::Target::HttpTarget'->new($_) };

declare 'RepeatedHttpTarget',
    as ArrayRef[HttpTarget()];

coerce 'RepeatedHttpTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Scheduler::V1beta1::Target::HttpTarget'->new($_) } @$_ ] };

declare 'MapStringHttpTarget',
    as HashRef[HttpTarget()];

declare 'HeadersEntry',
    as InstanceOf['Google::Cloud::Scheduler::V1beta1::Target::HttpTarget::HeadersEntry'];

coerce 'HeadersEntry',
    from HashRef, via { 'Google::Cloud::Scheduler::V1beta1::Target::HttpTarget::HeadersEntry'->new($_) };

declare 'RepeatedHeadersEntry',
    as ArrayRef[HeadersEntry()];

coerce 'RepeatedHeadersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Scheduler::V1beta1::Target::HttpTarget::HeadersEntry'->new($_) } @$_ ] };

declare 'MapStringHeadersEntry',
    as HashRef[HeadersEntry()];

declare 'AppEngineHttpTarget',
    as InstanceOf['Google::Cloud::Scheduler::V1beta1::Target::AppEngineHttpTarget'];

coerce 'AppEngineHttpTarget',
    from HashRef, via { 'Google::Cloud::Scheduler::V1beta1::Target::AppEngineHttpTarget'->new($_) };

declare 'RepeatedAppEngineHttpTarget',
    as ArrayRef[AppEngineHttpTarget()];

coerce 'RepeatedAppEngineHttpTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Scheduler::V1beta1::Target::AppEngineHttpTarget'->new($_) } @$_ ] };

declare 'MapStringAppEngineHttpTarget',
    as HashRef[AppEngineHttpTarget()];

declare 'HeadersEntry',
    as InstanceOf['Google::Cloud::Scheduler::V1beta1::Target::AppEngineHttpTarget::HeadersEntry'];

coerce 'HeadersEntry',
    from HashRef, via { 'Google::Cloud::Scheduler::V1beta1::Target::AppEngineHttpTarget::HeadersEntry'->new($_) };

declare 'RepeatedHeadersEntry',
    as ArrayRef[HeadersEntry()];

coerce 'RepeatedHeadersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Scheduler::V1beta1::Target::AppEngineHttpTarget::HeadersEntry'->new($_) } @$_ ] };

declare 'MapStringHeadersEntry',
    as HashRef[HeadersEntry()];

declare 'PubsubTarget',
    as InstanceOf['Google::Cloud::Scheduler::V1beta1::Target::PubsubTarget'];

coerce 'PubsubTarget',
    from HashRef, via { 'Google::Cloud::Scheduler::V1beta1::Target::PubsubTarget'->new($_) };

declare 'RepeatedPubsubTarget',
    as ArrayRef[PubsubTarget()];

coerce 'RepeatedPubsubTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Scheduler::V1beta1::Target::PubsubTarget'->new($_) } @$_ ] };

declare 'MapStringPubsubTarget',
    as HashRef[PubsubTarget()];

declare 'AttributesEntry',
    as InstanceOf['Google::Cloud::Scheduler::V1beta1::Target::PubsubTarget::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Cloud::Scheduler::V1beta1::Target::PubsubTarget::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Scheduler::V1beta1::Target::PubsubTarget::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

declare 'AppEngineRouting',
    as InstanceOf['Google::Cloud::Scheduler::V1beta1::Target::AppEngineRouting'];

coerce 'AppEngineRouting',
    from HashRef, via { 'Google::Cloud::Scheduler::V1beta1::Target::AppEngineRouting'->new($_) };

declare 'RepeatedAppEngineRouting',
    as ArrayRef[AppEngineRouting()];

coerce 'RepeatedAppEngineRouting',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Scheduler::V1beta1::Target::AppEngineRouting'->new($_) } @$_ ] };

declare 'MapStringAppEngineRouting',
    as HashRef[AppEngineRouting()];

declare 'OAuthToken',
    as InstanceOf['Google::Cloud::Scheduler::V1beta1::Target::OAuthToken'];

coerce 'OAuthToken',
    from HashRef, via { 'Google::Cloud::Scheduler::V1beta1::Target::OAuthToken'->new($_) };

declare 'RepeatedOAuthToken',
    as ArrayRef[OAuthToken()];

coerce 'RepeatedOAuthToken',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Scheduler::V1beta1::Target::OAuthToken'->new($_) } @$_ ] };

declare 'MapStringOAuthToken',
    as HashRef[OAuthToken()];

declare 'OidcToken',
    as InstanceOf['Google::Cloud::Scheduler::V1beta1::Target::OidcToken'];

coerce 'OidcToken',
    from HashRef, via { 'Google::Cloud::Scheduler::V1beta1::Target::OidcToken'->new($_) };

declare 'RepeatedOidcToken',
    as ArrayRef[OidcToken()];

coerce 'RepeatedOidcToken',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Scheduler::V1beta1::Target::OidcToken'->new($_) } @$_ ] };

declare 'MapStringOidcToken',
    as HashRef[OidcToken()];

1;

__END__

=head1 NAME

Google::Cloud::Scheduler::V1beta1::Target::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
