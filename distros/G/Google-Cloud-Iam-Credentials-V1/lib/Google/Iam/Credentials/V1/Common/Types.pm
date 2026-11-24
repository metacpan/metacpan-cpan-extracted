package Google::Iam::Credentials::V1::Common::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GenerateAccessTokenRequest',
    as InstanceOf['Google::Iam::Credentials::V1::Common::GenerateAccessTokenRequest'];

coerce 'GenerateAccessTokenRequest',
    from HashRef, via { 'Google::Iam::Credentials::V1::Common::GenerateAccessTokenRequest'->new($_) };

declare 'RepeatedGenerateAccessTokenRequest',
    as ArrayRef[GenerateAccessTokenRequest()];

coerce 'RepeatedGenerateAccessTokenRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Credentials::V1::Common::GenerateAccessTokenRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateAccessTokenRequest',
    as HashRef[GenerateAccessTokenRequest()];

declare 'GenerateAccessTokenResponse',
    as InstanceOf['Google::Iam::Credentials::V1::Common::GenerateAccessTokenResponse'];

coerce 'GenerateAccessTokenResponse',
    from HashRef, via { 'Google::Iam::Credentials::V1::Common::GenerateAccessTokenResponse'->new($_) };

declare 'RepeatedGenerateAccessTokenResponse',
    as ArrayRef[GenerateAccessTokenResponse()];

coerce 'RepeatedGenerateAccessTokenResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Credentials::V1::Common::GenerateAccessTokenResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateAccessTokenResponse',
    as HashRef[GenerateAccessTokenResponse()];

declare 'SignBlobRequest',
    as InstanceOf['Google::Iam::Credentials::V1::Common::SignBlobRequest'];

coerce 'SignBlobRequest',
    from HashRef, via { 'Google::Iam::Credentials::V1::Common::SignBlobRequest'->new($_) };

declare 'RepeatedSignBlobRequest',
    as ArrayRef[SignBlobRequest()];

coerce 'RepeatedSignBlobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Credentials::V1::Common::SignBlobRequest'->new($_) } @$_ ] };

declare 'MapStringSignBlobRequest',
    as HashRef[SignBlobRequest()];

declare 'SignBlobResponse',
    as InstanceOf['Google::Iam::Credentials::V1::Common::SignBlobResponse'];

coerce 'SignBlobResponse',
    from HashRef, via { 'Google::Iam::Credentials::V1::Common::SignBlobResponse'->new($_) };

declare 'RepeatedSignBlobResponse',
    as ArrayRef[SignBlobResponse()];

coerce 'RepeatedSignBlobResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Credentials::V1::Common::SignBlobResponse'->new($_) } @$_ ] };

declare 'MapStringSignBlobResponse',
    as HashRef[SignBlobResponse()];

declare 'SignJwtRequest',
    as InstanceOf['Google::Iam::Credentials::V1::Common::SignJwtRequest'];

coerce 'SignJwtRequest',
    from HashRef, via { 'Google::Iam::Credentials::V1::Common::SignJwtRequest'->new($_) };

declare 'RepeatedSignJwtRequest',
    as ArrayRef[SignJwtRequest()];

coerce 'RepeatedSignJwtRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Credentials::V1::Common::SignJwtRequest'->new($_) } @$_ ] };

declare 'MapStringSignJwtRequest',
    as HashRef[SignJwtRequest()];

declare 'SignJwtResponse',
    as InstanceOf['Google::Iam::Credentials::V1::Common::SignJwtResponse'];

coerce 'SignJwtResponse',
    from HashRef, via { 'Google::Iam::Credentials::V1::Common::SignJwtResponse'->new($_) };

declare 'RepeatedSignJwtResponse',
    as ArrayRef[SignJwtResponse()];

coerce 'RepeatedSignJwtResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Credentials::V1::Common::SignJwtResponse'->new($_) } @$_ ] };

declare 'MapStringSignJwtResponse',
    as HashRef[SignJwtResponse()];

declare 'GenerateIdTokenRequest',
    as InstanceOf['Google::Iam::Credentials::V1::Common::GenerateIdTokenRequest'];

coerce 'GenerateIdTokenRequest',
    from HashRef, via { 'Google::Iam::Credentials::V1::Common::GenerateIdTokenRequest'->new($_) };

declare 'RepeatedGenerateIdTokenRequest',
    as ArrayRef[GenerateIdTokenRequest()];

coerce 'RepeatedGenerateIdTokenRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Credentials::V1::Common::GenerateIdTokenRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateIdTokenRequest',
    as HashRef[GenerateIdTokenRequest()];

declare 'GenerateIdTokenResponse',
    as InstanceOf['Google::Iam::Credentials::V1::Common::GenerateIdTokenResponse'];

coerce 'GenerateIdTokenResponse',
    from HashRef, via { 'Google::Iam::Credentials::V1::Common::GenerateIdTokenResponse'->new($_) };

declare 'RepeatedGenerateIdTokenResponse',
    as ArrayRef[GenerateIdTokenResponse()];

coerce 'RepeatedGenerateIdTokenResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Iam::Credentials::V1::Common::GenerateIdTokenResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateIdTokenResponse',
    as HashRef[GenerateIdTokenResponse()];

1;

__END__

=head1 NAME

Google::Iam::Credentials::V1::Common::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
