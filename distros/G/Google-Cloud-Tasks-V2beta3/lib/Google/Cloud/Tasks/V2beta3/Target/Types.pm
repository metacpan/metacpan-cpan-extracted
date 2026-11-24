package Google::Cloud::Tasks::V2beta3::Target::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'HttpMethod',
    as (Int | Str);

declare 'PullMessage',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Target::PullMessage'];

coerce 'PullMessage',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Target::PullMessage'->new($_) };

declare 'RepeatedPullMessage',
    as ArrayRef[PullMessage()];

coerce 'RepeatedPullMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Target::PullMessage'->new($_) } @$_ ] };

declare 'MapStringPullMessage',
    as HashRef[PullMessage()];

declare 'PathOverride',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Target::PathOverride'];

coerce 'PathOverride',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Target::PathOverride'->new($_) };

declare 'RepeatedPathOverride',
    as ArrayRef[PathOverride()];

coerce 'RepeatedPathOverride',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Target::PathOverride'->new($_) } @$_ ] };

declare 'MapStringPathOverride',
    as HashRef[PathOverride()];

declare 'QueryOverride',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Target::QueryOverride'];

coerce 'QueryOverride',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Target::QueryOverride'->new($_) };

declare 'RepeatedQueryOverride',
    as ArrayRef[QueryOverride()];

coerce 'RepeatedQueryOverride',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Target::QueryOverride'->new($_) } @$_ ] };

declare 'MapStringQueryOverride',
    as HashRef[QueryOverride()];

declare 'UriOverride',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Target::UriOverride'];

coerce 'UriOverride',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Target::UriOverride'->new($_) };

declare 'RepeatedUriOverride',
    as ArrayRef[UriOverride()];

coerce 'RepeatedUriOverride',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Target::UriOverride'->new($_) } @$_ ] };

declare 'MapStringUriOverride',
    as HashRef[UriOverride()];

declare 'Scheme',
    as (Int | Str);

declare 'UriOverrideEnforceMode',
    as (Int | Str);

declare 'HttpTarget',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Target::HttpTarget'];

coerce 'HttpTarget',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Target::HttpTarget'->new($_) };

declare 'RepeatedHttpTarget',
    as ArrayRef[HttpTarget()];

coerce 'RepeatedHttpTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Target::HttpTarget'->new($_) } @$_ ] };

declare 'MapStringHttpTarget',
    as HashRef[HttpTarget()];

declare 'Header',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Target::HttpTarget::Header'];

coerce 'Header',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Target::HttpTarget::Header'->new($_) };

declare 'RepeatedHeader',
    as ArrayRef[Header()];

coerce 'RepeatedHeader',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Target::HttpTarget::Header'->new($_) } @$_ ] };

declare 'MapStringHeader',
    as HashRef[Header()];

declare 'HeaderOverride',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Target::HttpTarget::HeaderOverride'];

coerce 'HeaderOverride',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Target::HttpTarget::HeaderOverride'->new($_) };

declare 'RepeatedHeaderOverride',
    as ArrayRef[HeaderOverride()];

coerce 'RepeatedHeaderOverride',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Target::HttpTarget::HeaderOverride'->new($_) } @$_ ] };

declare 'MapStringHeaderOverride',
    as HashRef[HeaderOverride()];

declare 'HttpRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Target::HttpRequest'];

coerce 'HttpRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Target::HttpRequest'->new($_) };

declare 'RepeatedHttpRequest',
    as ArrayRef[HttpRequest()];

coerce 'RepeatedHttpRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Target::HttpRequest'->new($_) } @$_ ] };

declare 'MapStringHttpRequest',
    as HashRef[HttpRequest()];

declare 'HeadersEntry',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Target::HttpRequest::HeadersEntry'];

coerce 'HeadersEntry',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Target::HttpRequest::HeadersEntry'->new($_) };

declare 'RepeatedHeadersEntry',
    as ArrayRef[HeadersEntry()];

coerce 'RepeatedHeadersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Target::HttpRequest::HeadersEntry'->new($_) } @$_ ] };

declare 'MapStringHeadersEntry',
    as HashRef[HeadersEntry()];

declare 'AppEngineHttpQueue',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Target::AppEngineHttpQueue'];

coerce 'AppEngineHttpQueue',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Target::AppEngineHttpQueue'->new($_) };

declare 'RepeatedAppEngineHttpQueue',
    as ArrayRef[AppEngineHttpQueue()];

coerce 'RepeatedAppEngineHttpQueue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Target::AppEngineHttpQueue'->new($_) } @$_ ] };

declare 'MapStringAppEngineHttpQueue',
    as HashRef[AppEngineHttpQueue()];

declare 'AppEngineHttpRequest',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Target::AppEngineHttpRequest'];

coerce 'AppEngineHttpRequest',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Target::AppEngineHttpRequest'->new($_) };

declare 'RepeatedAppEngineHttpRequest',
    as ArrayRef[AppEngineHttpRequest()];

coerce 'RepeatedAppEngineHttpRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Target::AppEngineHttpRequest'->new($_) } @$_ ] };

declare 'MapStringAppEngineHttpRequest',
    as HashRef[AppEngineHttpRequest()];

declare 'HeadersEntry',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Target::AppEngineHttpRequest::HeadersEntry'];

coerce 'HeadersEntry',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Target::AppEngineHttpRequest::HeadersEntry'->new($_) };

declare 'RepeatedHeadersEntry',
    as ArrayRef[HeadersEntry()];

coerce 'RepeatedHeadersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Target::AppEngineHttpRequest::HeadersEntry'->new($_) } @$_ ] };

declare 'MapStringHeadersEntry',
    as HashRef[HeadersEntry()];

declare 'AppEngineRouting',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Target::AppEngineRouting'];

coerce 'AppEngineRouting',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Target::AppEngineRouting'->new($_) };

declare 'RepeatedAppEngineRouting',
    as ArrayRef[AppEngineRouting()];

coerce 'RepeatedAppEngineRouting',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Target::AppEngineRouting'->new($_) } @$_ ] };

declare 'MapStringAppEngineRouting',
    as HashRef[AppEngineRouting()];

declare 'OAuthToken',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Target::OAuthToken'];

coerce 'OAuthToken',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Target::OAuthToken'->new($_) };

declare 'RepeatedOAuthToken',
    as ArrayRef[OAuthToken()];

coerce 'RepeatedOAuthToken',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Target::OAuthToken'->new($_) } @$_ ] };

declare 'MapStringOAuthToken',
    as HashRef[OAuthToken()];

declare 'OidcToken',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Target::OidcToken'];

coerce 'OidcToken',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Target::OidcToken'->new($_) };

declare 'RepeatedOidcToken',
    as ArrayRef[OidcToken()];

coerce 'RepeatedOidcToken',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Target::OidcToken'->new($_) } @$_ ] };

declare 'MapStringOidcToken',
    as HashRef[OidcToken()];

1;

__END__

=head1 NAME

Google::Cloud::Tasks::V2beta3::Target::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
