package Google::Api::Auth::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Authentication',
    as InstanceOf['Google::Api::Auth::Authentication'];

coerce 'Authentication',
    from HashRef, via { 'Google::Api::Auth::Authentication'->new($_) };

declare 'RepeatedAuthentication',
    as ArrayRef[Authentication()];

coerce 'RepeatedAuthentication',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Auth::Authentication'->new($_) } @$_ ] };

declare 'MapStringAuthentication',
    as HashRef[Authentication()];

declare 'AuthenticationRule',
    as InstanceOf['Google::Api::Auth::AuthenticationRule'];

coerce 'AuthenticationRule',
    from HashRef, via { 'Google::Api::Auth::AuthenticationRule'->new($_) };

declare 'RepeatedAuthenticationRule',
    as ArrayRef[AuthenticationRule()];

coerce 'RepeatedAuthenticationRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Auth::AuthenticationRule'->new($_) } @$_ ] };

declare 'MapStringAuthenticationRule',
    as HashRef[AuthenticationRule()];

declare 'JwtLocation',
    as InstanceOf['Google::Api::Auth::JwtLocation'];

coerce 'JwtLocation',
    from HashRef, via { 'Google::Api::Auth::JwtLocation'->new($_) };

declare 'RepeatedJwtLocation',
    as ArrayRef[JwtLocation()];

coerce 'RepeatedJwtLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Auth::JwtLocation'->new($_) } @$_ ] };

declare 'MapStringJwtLocation',
    as HashRef[JwtLocation()];

declare 'AuthProvider',
    as InstanceOf['Google::Api::Auth::AuthProvider'];

coerce 'AuthProvider',
    from HashRef, via { 'Google::Api::Auth::AuthProvider'->new($_) };

declare 'RepeatedAuthProvider',
    as ArrayRef[AuthProvider()];

coerce 'RepeatedAuthProvider',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Auth::AuthProvider'->new($_) } @$_ ] };

declare 'MapStringAuthProvider',
    as HashRef[AuthProvider()];

declare 'OAuthRequirements',
    as InstanceOf['Google::Api::Auth::OAuthRequirements'];

coerce 'OAuthRequirements',
    from HashRef, via { 'Google::Api::Auth::OAuthRequirements'->new($_) };

declare 'RepeatedOAuthRequirements',
    as ArrayRef[OAuthRequirements()];

coerce 'RepeatedOAuthRequirements',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Auth::OAuthRequirements'->new($_) } @$_ ] };

declare 'MapStringOAuthRequirements',
    as HashRef[OAuthRequirements()];

declare 'AuthRequirement',
    as InstanceOf['Google::Api::Auth::AuthRequirement'];

coerce 'AuthRequirement',
    from HashRef, via { 'Google::Api::Auth::AuthRequirement'->new($_) };

declare 'RepeatedAuthRequirement',
    as ArrayRef[AuthRequirement()];

coerce 'RepeatedAuthRequirement',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Auth::AuthRequirement'->new($_) } @$_ ] };

declare 'MapStringAuthRequirement',
    as HashRef[AuthRequirement()];

1;
