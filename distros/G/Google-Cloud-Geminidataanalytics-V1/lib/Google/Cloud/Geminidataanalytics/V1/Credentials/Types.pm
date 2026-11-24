package Google::Cloud::Geminidataanalytics::V1::Credentials::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Credentials',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::Credentials::Credentials'];

coerce 'Credentials',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::Credentials::Credentials'->new($_) };

declare 'RepeatedCredentials',
    as ArrayRef[Credentials()];

coerce 'RepeatedCredentials',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::Credentials::Credentials'->new($_) } @$_ ] };

declare 'MapStringCredentials',
    as HashRef[Credentials()];

declare 'OAuthCredentials',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::Credentials::OAuthCredentials'];

coerce 'OAuthCredentials',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::Credentials::OAuthCredentials'->new($_) };

declare 'RepeatedOAuthCredentials',
    as ArrayRef[OAuthCredentials()];

coerce 'RepeatedOAuthCredentials',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::Credentials::OAuthCredentials'->new($_) } @$_ ] };

declare 'MapStringOAuthCredentials',
    as HashRef[OAuthCredentials()];

declare 'SecretBased',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::Credentials::OAuthCredentials::SecretBased'];

coerce 'SecretBased',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::Credentials::OAuthCredentials::SecretBased'->new($_) };

declare 'RepeatedSecretBased',
    as ArrayRef[SecretBased()];

coerce 'RepeatedSecretBased',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::Credentials::OAuthCredentials::SecretBased'->new($_) } @$_ ] };

declare 'MapStringSecretBased',
    as HashRef[SecretBased()];

declare 'TokenBased',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1::Credentials::OAuthCredentials::TokenBased'];

coerce 'TokenBased',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1::Credentials::OAuthCredentials::TokenBased'->new($_) };

declare 'RepeatedTokenBased',
    as ArrayRef[TokenBased()];

coerce 'RepeatedTokenBased',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1::Credentials::OAuthCredentials::TokenBased'->new($_) } @$_ ] };

declare 'MapStringTokenBased',
    as HashRef[TokenBased()];

1;

__END__

=head1 NAME

Google::Cloud::Geminidataanalytics::V1::Credentials::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
