package Google::Spanner::Auth::V1::Authentication::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PasswordAuthenticationProtocol',
    as (Int | Str);

declare 'HashParameters',
    as InstanceOf['Google::Spanner::Auth::V1::Authentication::HashParameters'];

coerce 'HashParameters',
    from HashRef, via { 'Google::Spanner::Auth::V1::Authentication::HashParameters'->new($_) };

declare 'RepeatedHashParameters',
    as ArrayRef[HashParameters()];

coerce 'RepeatedHashParameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Auth::V1::Authentication::HashParameters'->new($_) } @$_ ] };

declare 'MapStringHashParameters',
    as HashRef[HashParameters()];

declare 'Argon2IdParameters',
    as InstanceOf['Google::Spanner::Auth::V1::Authentication::HashParameters::Argon2IdParameters'];

coerce 'Argon2IdParameters',
    from HashRef, via { 'Google::Spanner::Auth::V1::Authentication::HashParameters::Argon2IdParameters'->new($_) };

declare 'RepeatedArgon2IdParameters',
    as ArrayRef[Argon2IdParameters()];

coerce 'RepeatedArgon2IdParameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Auth::V1::Authentication::HashParameters::Argon2IdParameters'->new($_) } @$_ ] };

declare 'MapStringArgon2IdParameters',
    as HashRef[Argon2IdParameters()];

declare 'PasswordAuthenticationHandshakeRequest',
    as InstanceOf['Google::Spanner::Auth::V1::Authentication::PasswordAuthenticationHandshakeRequest'];

coerce 'PasswordAuthenticationHandshakeRequest',
    from HashRef, via { 'Google::Spanner::Auth::V1::Authentication::PasswordAuthenticationHandshakeRequest'->new($_) };

declare 'RepeatedPasswordAuthenticationHandshakeRequest',
    as ArrayRef[PasswordAuthenticationHandshakeRequest()];

coerce 'RepeatedPasswordAuthenticationHandshakeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Auth::V1::Authentication::PasswordAuthenticationHandshakeRequest'->new($_) } @$_ ] };

declare 'MapStringPasswordAuthenticationHandshakeRequest',
    as HashRef[PasswordAuthenticationHandshakeRequest()];

declare 'PasswordAuthenticationHandshakeResponse',
    as InstanceOf['Google::Spanner::Auth::V1::Authentication::PasswordAuthenticationHandshakeResponse'];

coerce 'PasswordAuthenticationHandshakeResponse',
    from HashRef, via { 'Google::Spanner::Auth::V1::Authentication::PasswordAuthenticationHandshakeResponse'->new($_) };

declare 'RepeatedPasswordAuthenticationHandshakeResponse',
    as ArrayRef[PasswordAuthenticationHandshakeResponse()];

coerce 'RepeatedPasswordAuthenticationHandshakeResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Auth::V1::Authentication::PasswordAuthenticationHandshakeResponse'->new($_) } @$_ ] };

declare 'MapStringPasswordAuthenticationHandshakeResponse',
    as HashRef[PasswordAuthenticationHandshakeResponse()];

declare 'PasswordCredential',
    as InstanceOf['Google::Spanner::Auth::V1::Authentication::PasswordCredential'];

coerce 'PasswordCredential',
    from HashRef, via { 'Google::Spanner::Auth::V1::Authentication::PasswordCredential'->new($_) };

declare 'RepeatedPasswordCredential',
    as ArrayRef[PasswordCredential()];

coerce 'RepeatedPasswordCredential',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Auth::V1::Authentication::PasswordCredential'->new($_) } @$_ ] };

declare 'MapStringPasswordCredential',
    as HashRef[PasswordCredential()];

declare 'Scram',
    as InstanceOf['Google::Spanner::Auth::V1::Authentication::PasswordCredential::Scram'];

coerce 'Scram',
    from HashRef, via { 'Google::Spanner::Auth::V1::Authentication::PasswordCredential::Scram'->new($_) };

declare 'RepeatedScram',
    as ArrayRef[Scram()];

coerce 'RepeatedScram',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Auth::V1::Authentication::PasswordCredential::Scram'->new($_) } @$_ ] };

declare 'MapStringScram',
    as HashRef[Scram()];

declare 'Opaque',
    as InstanceOf['Google::Spanner::Auth::V1::Authentication::PasswordCredential::Opaque'];

coerce 'Opaque',
    from HashRef, via { 'Google::Spanner::Auth::V1::Authentication::PasswordCredential::Opaque'->new($_) };

declare 'RepeatedOpaque',
    as ArrayRef[Opaque()];

coerce 'RepeatedOpaque',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Auth::V1::Authentication::PasswordCredential::Opaque'->new($_) } @$_ ] };

declare 'MapStringOpaque',
    as HashRef[Opaque()];

declare 'InitialScramResponse',
    as InstanceOf['Google::Spanner::Auth::V1::Authentication::InitialScramResponse'];

coerce 'InitialScramResponse',
    from HashRef, via { 'Google::Spanner::Auth::V1::Authentication::InitialScramResponse'->new($_) };

declare 'RepeatedInitialScramResponse',
    as ArrayRef[InitialScramResponse()];

coerce 'RepeatedInitialScramResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Auth::V1::Authentication::InitialScramResponse'->new($_) } @$_ ] };

declare 'MapStringInitialScramResponse',
    as HashRef[InitialScramResponse()];

declare 'ScramNewCredentialRequest',
    as InstanceOf['Google::Spanner::Auth::V1::Authentication::ScramNewCredentialRequest'];

coerce 'ScramNewCredentialRequest',
    from HashRef, via { 'Google::Spanner::Auth::V1::Authentication::ScramNewCredentialRequest'->new($_) };

declare 'RepeatedScramNewCredentialRequest',
    as ArrayRef[ScramNewCredentialRequest()];

coerce 'RepeatedScramNewCredentialRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Auth::V1::Authentication::ScramNewCredentialRequest'->new($_) } @$_ ] };

declare 'MapStringScramNewCredentialRequest',
    as HashRef[ScramNewCredentialRequest()];

declare 'InitialRequest',
    as InstanceOf['Google::Spanner::Auth::V1::Authentication::ScramNewCredentialRequest::InitialRequest'];

coerce 'InitialRequest',
    from HashRef, via { 'Google::Spanner::Auth::V1::Authentication::ScramNewCredentialRequest::InitialRequest'->new($_) };

declare 'RepeatedInitialRequest',
    as ArrayRef[InitialRequest()];

coerce 'RepeatedInitialRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Auth::V1::Authentication::ScramNewCredentialRequest::InitialRequest'->new($_) } @$_ ] };

declare 'MapStringInitialRequest',
    as HashRef[InitialRequest()];

declare 'FinalRequest',
    as InstanceOf['Google::Spanner::Auth::V1::Authentication::ScramNewCredentialRequest::FinalRequest'];

coerce 'FinalRequest',
    from HashRef, via { 'Google::Spanner::Auth::V1::Authentication::ScramNewCredentialRequest::FinalRequest'->new($_) };

declare 'RepeatedFinalRequest',
    as ArrayRef[FinalRequest()];

coerce 'RepeatedFinalRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Auth::V1::Authentication::ScramNewCredentialRequest::FinalRequest'->new($_) } @$_ ] };

declare 'MapStringFinalRequest',
    as HashRef[FinalRequest()];

declare 'ScramNewCredentialResponse',
    as InstanceOf['Google::Spanner::Auth::V1::Authentication::ScramNewCredentialResponse'];

coerce 'ScramNewCredentialResponse',
    from HashRef, via { 'Google::Spanner::Auth::V1::Authentication::ScramNewCredentialResponse'->new($_) };

declare 'RepeatedScramNewCredentialResponse',
    as ArrayRef[ScramNewCredentialResponse()];

coerce 'RepeatedScramNewCredentialResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Auth::V1::Authentication::ScramNewCredentialResponse'->new($_) } @$_ ] };

declare 'MapStringScramNewCredentialResponse',
    as HashRef[ScramNewCredentialResponse()];

declare 'FinalResponse',
    as InstanceOf['Google::Spanner::Auth::V1::Authentication::ScramNewCredentialResponse::FinalResponse'];

coerce 'FinalResponse',
    from HashRef, via { 'Google::Spanner::Auth::V1::Authentication::ScramNewCredentialResponse::FinalResponse'->new($_) };

declare 'RepeatedFinalResponse',
    as ArrayRef[FinalResponse()];

coerce 'RepeatedFinalResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Auth::V1::Authentication::ScramNewCredentialResponse::FinalResponse'->new($_) } @$_ ] };

declare 'MapStringFinalResponse',
    as HashRef[FinalResponse()];

declare 'OpaqueNewCredentialRequest',
    as InstanceOf['Google::Spanner::Auth::V1::Authentication::OpaqueNewCredentialRequest'];

coerce 'OpaqueNewCredentialRequest',
    from HashRef, via { 'Google::Spanner::Auth::V1::Authentication::OpaqueNewCredentialRequest'->new($_) };

declare 'RepeatedOpaqueNewCredentialRequest',
    as ArrayRef[OpaqueNewCredentialRequest()];

coerce 'RepeatedOpaqueNewCredentialRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Auth::V1::Authentication::OpaqueNewCredentialRequest'->new($_) } @$_ ] };

declare 'MapStringOpaqueNewCredentialRequest',
    as HashRef[OpaqueNewCredentialRequest()];

declare 'InitialRequest',
    as InstanceOf['Google::Spanner::Auth::V1::Authentication::OpaqueNewCredentialRequest::InitialRequest'];

coerce 'InitialRequest',
    from HashRef, via { 'Google::Spanner::Auth::V1::Authentication::OpaqueNewCredentialRequest::InitialRequest'->new($_) };

declare 'RepeatedInitialRequest',
    as ArrayRef[InitialRequest()];

coerce 'RepeatedInitialRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Auth::V1::Authentication::OpaqueNewCredentialRequest::InitialRequest'->new($_) } @$_ ] };

declare 'MapStringInitialRequest',
    as HashRef[InitialRequest()];

declare 'FinalRequest',
    as InstanceOf['Google::Spanner::Auth::V1::Authentication::OpaqueNewCredentialRequest::FinalRequest'];

coerce 'FinalRequest',
    from HashRef, via { 'Google::Spanner::Auth::V1::Authentication::OpaqueNewCredentialRequest::FinalRequest'->new($_) };

declare 'RepeatedFinalRequest',
    as ArrayRef[FinalRequest()];

coerce 'RepeatedFinalRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Auth::V1::Authentication::OpaqueNewCredentialRequest::FinalRequest'->new($_) } @$_ ] };

declare 'MapStringFinalRequest',
    as HashRef[FinalRequest()];

declare 'OpaqueNewCredentialResponse',
    as InstanceOf['Google::Spanner::Auth::V1::Authentication::OpaqueNewCredentialResponse'];

coerce 'OpaqueNewCredentialResponse',
    from HashRef, via { 'Google::Spanner::Auth::V1::Authentication::OpaqueNewCredentialResponse'->new($_) };

declare 'RepeatedOpaqueNewCredentialResponse',
    as ArrayRef[OpaqueNewCredentialResponse()];

coerce 'RepeatedOpaqueNewCredentialResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Auth::V1::Authentication::OpaqueNewCredentialResponse'->new($_) } @$_ ] };

declare 'MapStringOpaqueNewCredentialResponse',
    as HashRef[OpaqueNewCredentialResponse()];

declare 'InitialResponse',
    as InstanceOf['Google::Spanner::Auth::V1::Authentication::OpaqueNewCredentialResponse::InitialResponse'];

coerce 'InitialResponse',
    from HashRef, via { 'Google::Spanner::Auth::V1::Authentication::OpaqueNewCredentialResponse::InitialResponse'->new($_) };

declare 'RepeatedInitialResponse',
    as ArrayRef[InitialResponse()];

coerce 'RepeatedInitialResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Auth::V1::Authentication::OpaqueNewCredentialResponse::InitialResponse'->new($_) } @$_ ] };

declare 'MapStringInitialResponse',
    as HashRef[InitialResponse()];

declare 'FinalResponse',
    as InstanceOf['Google::Spanner::Auth::V1::Authentication::OpaqueNewCredentialResponse::FinalResponse'];

coerce 'FinalResponse',
    from HashRef, via { 'Google::Spanner::Auth::V1::Authentication::OpaqueNewCredentialResponse::FinalResponse'->new($_) };

declare 'RepeatedFinalResponse',
    as ArrayRef[FinalResponse()];

coerce 'RepeatedFinalResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Auth::V1::Authentication::OpaqueNewCredentialResponse::FinalResponse'->new($_) } @$_ ] };

declare 'MapStringFinalResponse',
    as HashRef[FinalResponse()];

1;

__END__

=head1 NAME

Google::Spanner::Auth::V1::Authentication::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
