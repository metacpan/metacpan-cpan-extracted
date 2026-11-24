package Google::Cloud::Oslogin::V1beta::Oslogin::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LoginProfileView',
    as (Int | Str);

declare 'LoginProfile',
    as InstanceOf['Google::Cloud::Oslogin::V1beta::Oslogin::LoginProfile'];

coerce 'LoginProfile',
    from HashRef, via { 'Google::Cloud::Oslogin::V1beta::Oslogin::LoginProfile'->new($_) };

declare 'RepeatedLoginProfile',
    as ArrayRef[LoginProfile()];

coerce 'RepeatedLoginProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oslogin::V1beta::Oslogin::LoginProfile'->new($_) } @$_ ] };

declare 'MapStringLoginProfile',
    as HashRef[LoginProfile()];

declare 'SshPublicKeysEntry',
    as InstanceOf['Google::Cloud::Oslogin::V1beta::Oslogin::LoginProfile::SshPublicKeysEntry'];

coerce 'SshPublicKeysEntry',
    from HashRef, via { 'Google::Cloud::Oslogin::V1beta::Oslogin::LoginProfile::SshPublicKeysEntry'->new($_) };

declare 'RepeatedSshPublicKeysEntry',
    as ArrayRef[SshPublicKeysEntry()];

coerce 'RepeatedSshPublicKeysEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oslogin::V1beta::Oslogin::LoginProfile::SshPublicKeysEntry'->new($_) } @$_ ] };

declare 'MapStringSshPublicKeysEntry',
    as HashRef[SshPublicKeysEntry()];

declare 'CreateSshPublicKeyRequest',
    as InstanceOf['Google::Cloud::Oslogin::V1beta::Oslogin::CreateSshPublicKeyRequest'];

coerce 'CreateSshPublicKeyRequest',
    from HashRef, via { 'Google::Cloud::Oslogin::V1beta::Oslogin::CreateSshPublicKeyRequest'->new($_) };

declare 'RepeatedCreateSshPublicKeyRequest',
    as ArrayRef[CreateSshPublicKeyRequest()];

coerce 'RepeatedCreateSshPublicKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oslogin::V1beta::Oslogin::CreateSshPublicKeyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSshPublicKeyRequest',
    as HashRef[CreateSshPublicKeyRequest()];

declare 'DeletePosixAccountRequest',
    as InstanceOf['Google::Cloud::Oslogin::V1beta::Oslogin::DeletePosixAccountRequest'];

coerce 'DeletePosixAccountRequest',
    from HashRef, via { 'Google::Cloud::Oslogin::V1beta::Oslogin::DeletePosixAccountRequest'->new($_) };

declare 'RepeatedDeletePosixAccountRequest',
    as ArrayRef[DeletePosixAccountRequest()];

coerce 'RepeatedDeletePosixAccountRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oslogin::V1beta::Oslogin::DeletePosixAccountRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePosixAccountRequest',
    as HashRef[DeletePosixAccountRequest()];

declare 'DeleteSshPublicKeyRequest',
    as InstanceOf['Google::Cloud::Oslogin::V1beta::Oslogin::DeleteSshPublicKeyRequest'];

coerce 'DeleteSshPublicKeyRequest',
    from HashRef, via { 'Google::Cloud::Oslogin::V1beta::Oslogin::DeleteSshPublicKeyRequest'->new($_) };

declare 'RepeatedDeleteSshPublicKeyRequest',
    as ArrayRef[DeleteSshPublicKeyRequest()];

coerce 'RepeatedDeleteSshPublicKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oslogin::V1beta::Oslogin::DeleteSshPublicKeyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSshPublicKeyRequest',
    as HashRef[DeleteSshPublicKeyRequest()];

declare 'GetLoginProfileRequest',
    as InstanceOf['Google::Cloud::Oslogin::V1beta::Oslogin::GetLoginProfileRequest'];

coerce 'GetLoginProfileRequest',
    from HashRef, via { 'Google::Cloud::Oslogin::V1beta::Oslogin::GetLoginProfileRequest'->new($_) };

declare 'RepeatedGetLoginProfileRequest',
    as ArrayRef[GetLoginProfileRequest()];

coerce 'RepeatedGetLoginProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oslogin::V1beta::Oslogin::GetLoginProfileRequest'->new($_) } @$_ ] };

declare 'MapStringGetLoginProfileRequest',
    as HashRef[GetLoginProfileRequest()];

declare 'GetSshPublicKeyRequest',
    as InstanceOf['Google::Cloud::Oslogin::V1beta::Oslogin::GetSshPublicKeyRequest'];

coerce 'GetSshPublicKeyRequest',
    from HashRef, via { 'Google::Cloud::Oslogin::V1beta::Oslogin::GetSshPublicKeyRequest'->new($_) };

declare 'RepeatedGetSshPublicKeyRequest',
    as ArrayRef[GetSshPublicKeyRequest()];

coerce 'RepeatedGetSshPublicKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oslogin::V1beta::Oslogin::GetSshPublicKeyRequest'->new($_) } @$_ ] };

declare 'MapStringGetSshPublicKeyRequest',
    as HashRef[GetSshPublicKeyRequest()];

declare 'ImportSshPublicKeyRequest',
    as InstanceOf['Google::Cloud::Oslogin::V1beta::Oslogin::ImportSshPublicKeyRequest'];

coerce 'ImportSshPublicKeyRequest',
    from HashRef, via { 'Google::Cloud::Oslogin::V1beta::Oslogin::ImportSshPublicKeyRequest'->new($_) };

declare 'RepeatedImportSshPublicKeyRequest',
    as ArrayRef[ImportSshPublicKeyRequest()];

coerce 'RepeatedImportSshPublicKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oslogin::V1beta::Oslogin::ImportSshPublicKeyRequest'->new($_) } @$_ ] };

declare 'MapStringImportSshPublicKeyRequest',
    as HashRef[ImportSshPublicKeyRequest()];

declare 'ImportSshPublicKeyResponse',
    as InstanceOf['Google::Cloud::Oslogin::V1beta::Oslogin::ImportSshPublicKeyResponse'];

coerce 'ImportSshPublicKeyResponse',
    from HashRef, via { 'Google::Cloud::Oslogin::V1beta::Oslogin::ImportSshPublicKeyResponse'->new($_) };

declare 'RepeatedImportSshPublicKeyResponse',
    as ArrayRef[ImportSshPublicKeyResponse()];

coerce 'RepeatedImportSshPublicKeyResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oslogin::V1beta::Oslogin::ImportSshPublicKeyResponse'->new($_) } @$_ ] };

declare 'MapStringImportSshPublicKeyResponse',
    as HashRef[ImportSshPublicKeyResponse()];

declare 'UpdateSshPublicKeyRequest',
    as InstanceOf['Google::Cloud::Oslogin::V1beta::Oslogin::UpdateSshPublicKeyRequest'];

coerce 'UpdateSshPublicKeyRequest',
    from HashRef, via { 'Google::Cloud::Oslogin::V1beta::Oslogin::UpdateSshPublicKeyRequest'->new($_) };

declare 'RepeatedUpdateSshPublicKeyRequest',
    as ArrayRef[UpdateSshPublicKeyRequest()];

coerce 'RepeatedUpdateSshPublicKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oslogin::V1beta::Oslogin::UpdateSshPublicKeyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSshPublicKeyRequest',
    as HashRef[UpdateSshPublicKeyRequest()];

declare 'SecurityKey',
    as InstanceOf['Google::Cloud::Oslogin::V1beta::Oslogin::SecurityKey'];

coerce 'SecurityKey',
    from HashRef, via { 'Google::Cloud::Oslogin::V1beta::Oslogin::SecurityKey'->new($_) };

declare 'RepeatedSecurityKey',
    as ArrayRef[SecurityKey()];

coerce 'RepeatedSecurityKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oslogin::V1beta::Oslogin::SecurityKey'->new($_) } @$_ ] };

declare 'MapStringSecurityKey',
    as HashRef[SecurityKey()];

declare 'UniversalTwoFactor',
    as InstanceOf['Google::Cloud::Oslogin::V1beta::Oslogin::UniversalTwoFactor'];

coerce 'UniversalTwoFactor',
    from HashRef, via { 'Google::Cloud::Oslogin::V1beta::Oslogin::UniversalTwoFactor'->new($_) };

declare 'RepeatedUniversalTwoFactor',
    as ArrayRef[UniversalTwoFactor()];

coerce 'RepeatedUniversalTwoFactor',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oslogin::V1beta::Oslogin::UniversalTwoFactor'->new($_) } @$_ ] };

declare 'MapStringUniversalTwoFactor',
    as HashRef[UniversalTwoFactor()];

declare 'WebAuthn',
    as InstanceOf['Google::Cloud::Oslogin::V1beta::Oslogin::WebAuthn'];

coerce 'WebAuthn',
    from HashRef, via { 'Google::Cloud::Oslogin::V1beta::Oslogin::WebAuthn'->new($_) };

declare 'RepeatedWebAuthn',
    as ArrayRef[WebAuthn()];

coerce 'RepeatedWebAuthn',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oslogin::V1beta::Oslogin::WebAuthn'->new($_) } @$_ ] };

declare 'MapStringWebAuthn',
    as HashRef[WebAuthn()];

declare 'SignSshPublicKeyRequest',
    as InstanceOf['Google::Cloud::Oslogin::V1beta::Oslogin::SignSshPublicKeyRequest'];

coerce 'SignSshPublicKeyRequest',
    from HashRef, via { 'Google::Cloud::Oslogin::V1beta::Oslogin::SignSshPublicKeyRequest'->new($_) };

declare 'RepeatedSignSshPublicKeyRequest',
    as ArrayRef[SignSshPublicKeyRequest()];

coerce 'RepeatedSignSshPublicKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oslogin::V1beta::Oslogin::SignSshPublicKeyRequest'->new($_) } @$_ ] };

declare 'MapStringSignSshPublicKeyRequest',
    as HashRef[SignSshPublicKeyRequest()];

declare 'SignSshPublicKeyResponse',
    as InstanceOf['Google::Cloud::Oslogin::V1beta::Oslogin::SignSshPublicKeyResponse'];

coerce 'SignSshPublicKeyResponse',
    from HashRef, via { 'Google::Cloud::Oslogin::V1beta::Oslogin::SignSshPublicKeyResponse'->new($_) };

declare 'RepeatedSignSshPublicKeyResponse',
    as ArrayRef[SignSshPublicKeyResponse()];

coerce 'RepeatedSignSshPublicKeyResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oslogin::V1beta::Oslogin::SignSshPublicKeyResponse'->new($_) } @$_ ] };

declare 'MapStringSignSshPublicKeyResponse',
    as HashRef[SignSshPublicKeyResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Oslogin::V1beta::Oslogin::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
