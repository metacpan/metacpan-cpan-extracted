package Google::Cloud::Connectors::V1::Authconfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AuthType',
    as (Int | Str);

declare 'AuthConfig',
    as InstanceOf['Google::Cloud::Connectors::V1::Authconfig::AuthConfig'];

coerce 'AuthConfig',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Authconfig::AuthConfig'->new($_) };

declare 'RepeatedAuthConfig',
    as ArrayRef[AuthConfig()];

coerce 'RepeatedAuthConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Authconfig::AuthConfig'->new($_) } @$_ ] };

declare 'MapStringAuthConfig',
    as HashRef[AuthConfig()];

declare 'UserPassword',
    as InstanceOf['Google::Cloud::Connectors::V1::Authconfig::AuthConfig::UserPassword'];

coerce 'UserPassword',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Authconfig::AuthConfig::UserPassword'->new($_) };

declare 'RepeatedUserPassword',
    as ArrayRef[UserPassword()];

coerce 'RepeatedUserPassword',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Authconfig::AuthConfig::UserPassword'->new($_) } @$_ ] };

declare 'MapStringUserPassword',
    as HashRef[UserPassword()];

declare 'Oauth2JwtBearer',
    as InstanceOf['Google::Cloud::Connectors::V1::Authconfig::AuthConfig::Oauth2JwtBearer'];

coerce 'Oauth2JwtBearer',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Authconfig::AuthConfig::Oauth2JwtBearer'->new($_) };

declare 'RepeatedOauth2JwtBearer',
    as ArrayRef[Oauth2JwtBearer()];

coerce 'RepeatedOauth2JwtBearer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Authconfig::AuthConfig::Oauth2JwtBearer'->new($_) } @$_ ] };

declare 'MapStringOauth2JwtBearer',
    as HashRef[Oauth2JwtBearer()];

declare 'JwtClaims',
    as InstanceOf['Google::Cloud::Connectors::V1::Authconfig::AuthConfig::Oauth2JwtBearer::JwtClaims'];

coerce 'JwtClaims',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Authconfig::AuthConfig::Oauth2JwtBearer::JwtClaims'->new($_) };

declare 'RepeatedJwtClaims',
    as ArrayRef[JwtClaims()];

coerce 'RepeatedJwtClaims',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Authconfig::AuthConfig::Oauth2JwtBearer::JwtClaims'->new($_) } @$_ ] };

declare 'MapStringJwtClaims',
    as HashRef[JwtClaims()];

declare 'Oauth2ClientCredentials',
    as InstanceOf['Google::Cloud::Connectors::V1::Authconfig::AuthConfig::Oauth2ClientCredentials'];

coerce 'Oauth2ClientCredentials',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Authconfig::AuthConfig::Oauth2ClientCredentials'->new($_) };

declare 'RepeatedOauth2ClientCredentials',
    as ArrayRef[Oauth2ClientCredentials()];

coerce 'RepeatedOauth2ClientCredentials',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Authconfig::AuthConfig::Oauth2ClientCredentials'->new($_) } @$_ ] };

declare 'MapStringOauth2ClientCredentials',
    as HashRef[Oauth2ClientCredentials()];

declare 'SshPublicKey',
    as InstanceOf['Google::Cloud::Connectors::V1::Authconfig::AuthConfig::SshPublicKey'];

coerce 'SshPublicKey',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Authconfig::AuthConfig::SshPublicKey'->new($_) };

declare 'RepeatedSshPublicKey',
    as ArrayRef[SshPublicKey()];

coerce 'RepeatedSshPublicKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Authconfig::AuthConfig::SshPublicKey'->new($_) } @$_ ] };

declare 'MapStringSshPublicKey',
    as HashRef[SshPublicKey()];

declare 'AuthConfigTemplate',
    as InstanceOf['Google::Cloud::Connectors::V1::Authconfig::AuthConfigTemplate'];

coerce 'AuthConfigTemplate',
    from HashRef, via { 'Google::Cloud::Connectors::V1::Authconfig::AuthConfigTemplate'->new($_) };

declare 'RepeatedAuthConfigTemplate',
    as ArrayRef[AuthConfigTemplate()];

coerce 'RepeatedAuthConfigTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::Authconfig::AuthConfigTemplate'->new($_) } @$_ ] };

declare 'MapStringAuthConfigTemplate',
    as HashRef[AuthConfigTemplate()];

1;

__END__

=head1 NAME

Google::Cloud::Connectors::V1::Authconfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
