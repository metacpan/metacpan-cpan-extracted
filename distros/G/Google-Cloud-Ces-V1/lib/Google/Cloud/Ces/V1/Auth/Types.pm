package Google::Cloud::Ces::V1::Auth::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ApiKeyConfig',
    as InstanceOf['Google::Cloud::Ces::V1::Auth::ApiKeyConfig'];

coerce 'ApiKeyConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1::Auth::ApiKeyConfig'->new($_) };

declare 'RepeatedApiKeyConfig',
    as ArrayRef[ApiKeyConfig()];

coerce 'RepeatedApiKeyConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Auth::ApiKeyConfig'->new($_) } @$_ ] };

declare 'MapStringApiKeyConfig',
    as HashRef[ApiKeyConfig()];

declare 'RequestLocation',
    as (Int | Str);

declare 'OAuthConfig',
    as InstanceOf['Google::Cloud::Ces::V1::Auth::OAuthConfig'];

coerce 'OAuthConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1::Auth::OAuthConfig'->new($_) };

declare 'RepeatedOAuthConfig',
    as ArrayRef[OAuthConfig()];

coerce 'RepeatedOAuthConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Auth::OAuthConfig'->new($_) } @$_ ] };

declare 'MapStringOAuthConfig',
    as HashRef[OAuthConfig()];

declare 'OauthGrantType',
    as (Int | Str);

declare 'ServiceAgentIdTokenAuthConfig',
    as InstanceOf['Google::Cloud::Ces::V1::Auth::ServiceAgentIdTokenAuthConfig'];

coerce 'ServiceAgentIdTokenAuthConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1::Auth::ServiceAgentIdTokenAuthConfig'->new($_) };

declare 'RepeatedServiceAgentIdTokenAuthConfig',
    as ArrayRef[ServiceAgentIdTokenAuthConfig()];

coerce 'RepeatedServiceAgentIdTokenAuthConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Auth::ServiceAgentIdTokenAuthConfig'->new($_) } @$_ ] };

declare 'MapStringServiceAgentIdTokenAuthConfig',
    as HashRef[ServiceAgentIdTokenAuthConfig()];

declare 'ServiceAccountAuthConfig',
    as InstanceOf['Google::Cloud::Ces::V1::Auth::ServiceAccountAuthConfig'];

coerce 'ServiceAccountAuthConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1::Auth::ServiceAccountAuthConfig'->new($_) };

declare 'RepeatedServiceAccountAuthConfig',
    as ArrayRef[ServiceAccountAuthConfig()];

coerce 'RepeatedServiceAccountAuthConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Auth::ServiceAccountAuthConfig'->new($_) } @$_ ] };

declare 'MapStringServiceAccountAuthConfig',
    as HashRef[ServiceAccountAuthConfig()];

declare 'BearerTokenConfig',
    as InstanceOf['Google::Cloud::Ces::V1::Auth::BearerTokenConfig'];

coerce 'BearerTokenConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1::Auth::BearerTokenConfig'->new($_) };

declare 'RepeatedBearerTokenConfig',
    as ArrayRef[BearerTokenConfig()];

coerce 'RepeatedBearerTokenConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Auth::BearerTokenConfig'->new($_) } @$_ ] };

declare 'MapStringBearerTokenConfig',
    as HashRef[BearerTokenConfig()];

declare 'EndUserAuthConfig',
    as InstanceOf['Google::Cloud::Ces::V1::Auth::EndUserAuthConfig'];

coerce 'EndUserAuthConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1::Auth::EndUserAuthConfig'->new($_) };

declare 'RepeatedEndUserAuthConfig',
    as ArrayRef[EndUserAuthConfig()];

coerce 'RepeatedEndUserAuthConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Auth::EndUserAuthConfig'->new($_) } @$_ ] };

declare 'MapStringEndUserAuthConfig',
    as HashRef[EndUserAuthConfig()];

declare 'Oauth2AuthCodeConfig',
    as InstanceOf['Google::Cloud::Ces::V1::Auth::EndUserAuthConfig::Oauth2AuthCodeConfig'];

coerce 'Oauth2AuthCodeConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1::Auth::EndUserAuthConfig::Oauth2AuthCodeConfig'->new($_) };

declare 'RepeatedOauth2AuthCodeConfig',
    as ArrayRef[Oauth2AuthCodeConfig()];

coerce 'RepeatedOauth2AuthCodeConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Auth::EndUserAuthConfig::Oauth2AuthCodeConfig'->new($_) } @$_ ] };

declare 'MapStringOauth2AuthCodeConfig',
    as HashRef[Oauth2AuthCodeConfig()];

declare 'Oauth2JwtBearerConfig',
    as InstanceOf['Google::Cloud::Ces::V1::Auth::EndUserAuthConfig::Oauth2JwtBearerConfig'];

coerce 'Oauth2JwtBearerConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1::Auth::EndUserAuthConfig::Oauth2JwtBearerConfig'->new($_) };

declare 'RepeatedOauth2JwtBearerConfig',
    as ArrayRef[Oauth2JwtBearerConfig()];

coerce 'RepeatedOauth2JwtBearerConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Auth::EndUserAuthConfig::Oauth2JwtBearerConfig'->new($_) } @$_ ] };

declare 'MapStringOauth2JwtBearerConfig',
    as HashRef[Oauth2JwtBearerConfig()];

declare 'ApiAuthentication',
    as InstanceOf['Google::Cloud::Ces::V1::Auth::ApiAuthentication'];

coerce 'ApiAuthentication',
    from HashRef, via { 'Google::Cloud::Ces::V1::Auth::ApiAuthentication'->new($_) };

declare 'RepeatedApiAuthentication',
    as ArrayRef[ApiAuthentication()];

coerce 'RepeatedApiAuthentication',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::Auth::ApiAuthentication'->new($_) } @$_ ] };

declare 'MapStringApiAuthentication',
    as HashRef[ApiAuthentication()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1::Auth::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
