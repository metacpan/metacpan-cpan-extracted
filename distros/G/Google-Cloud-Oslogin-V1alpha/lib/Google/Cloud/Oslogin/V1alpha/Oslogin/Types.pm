package Google::Cloud::Oslogin::V1alpha::Oslogin::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LoginProfile',
    as InstanceOf['Google::Cloud::Oslogin::V1alpha::Oslogin::LoginProfile'];

coerce 'LoginProfile',
    from HashRef, via { 'Google::Cloud::Oslogin::V1alpha::Oslogin::LoginProfile'->new($_) };

declare 'RepeatedLoginProfile',
    as ArrayRef[LoginProfile()];

coerce 'RepeatedLoginProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oslogin::V1alpha::Oslogin::LoginProfile'->new($_) } @$_ ] };

declare 'MapStringLoginProfile',
    as HashRef[LoginProfile()];

declare 'SshPublicKeysEntry',
    as InstanceOf['Google::Cloud::Oslogin::V1alpha::Oslogin::LoginProfile::SshPublicKeysEntry'];

coerce 'SshPublicKeysEntry',
    from HashRef, via { 'Google::Cloud::Oslogin::V1alpha::Oslogin::LoginProfile::SshPublicKeysEntry'->new($_) };

declare 'RepeatedSshPublicKeysEntry',
    as ArrayRef[SshPublicKeysEntry()];

coerce 'RepeatedSshPublicKeysEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oslogin::V1alpha::Oslogin::LoginProfile::SshPublicKeysEntry'->new($_) } @$_ ] };

declare 'MapStringSshPublicKeysEntry',
    as HashRef[SshPublicKeysEntry()];

declare 'DeletePosixAccountRequest',
    as InstanceOf['Google::Cloud::Oslogin::V1alpha::Oslogin::DeletePosixAccountRequest'];

coerce 'DeletePosixAccountRequest',
    from HashRef, via { 'Google::Cloud::Oslogin::V1alpha::Oslogin::DeletePosixAccountRequest'->new($_) };

declare 'RepeatedDeletePosixAccountRequest',
    as ArrayRef[DeletePosixAccountRequest()];

coerce 'RepeatedDeletePosixAccountRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oslogin::V1alpha::Oslogin::DeletePosixAccountRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePosixAccountRequest',
    as HashRef[DeletePosixAccountRequest()];

declare 'DeleteSshPublicKeyRequest',
    as InstanceOf['Google::Cloud::Oslogin::V1alpha::Oslogin::DeleteSshPublicKeyRequest'];

coerce 'DeleteSshPublicKeyRequest',
    from HashRef, via { 'Google::Cloud::Oslogin::V1alpha::Oslogin::DeleteSshPublicKeyRequest'->new($_) };

declare 'RepeatedDeleteSshPublicKeyRequest',
    as ArrayRef[DeleteSshPublicKeyRequest()];

coerce 'RepeatedDeleteSshPublicKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oslogin::V1alpha::Oslogin::DeleteSshPublicKeyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSshPublicKeyRequest',
    as HashRef[DeleteSshPublicKeyRequest()];

declare 'GetLoginProfileRequest',
    as InstanceOf['Google::Cloud::Oslogin::V1alpha::Oslogin::GetLoginProfileRequest'];

coerce 'GetLoginProfileRequest',
    from HashRef, via { 'Google::Cloud::Oslogin::V1alpha::Oslogin::GetLoginProfileRequest'->new($_) };

declare 'RepeatedGetLoginProfileRequest',
    as ArrayRef[GetLoginProfileRequest()];

coerce 'RepeatedGetLoginProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oslogin::V1alpha::Oslogin::GetLoginProfileRequest'->new($_) } @$_ ] };

declare 'MapStringGetLoginProfileRequest',
    as HashRef[GetLoginProfileRequest()];

declare 'GetSshPublicKeyRequest',
    as InstanceOf['Google::Cloud::Oslogin::V1alpha::Oslogin::GetSshPublicKeyRequest'];

coerce 'GetSshPublicKeyRequest',
    from HashRef, via { 'Google::Cloud::Oslogin::V1alpha::Oslogin::GetSshPublicKeyRequest'->new($_) };

declare 'RepeatedGetSshPublicKeyRequest',
    as ArrayRef[GetSshPublicKeyRequest()];

coerce 'RepeatedGetSshPublicKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oslogin::V1alpha::Oslogin::GetSshPublicKeyRequest'->new($_) } @$_ ] };

declare 'MapStringGetSshPublicKeyRequest',
    as HashRef[GetSshPublicKeyRequest()];

declare 'ImportSshPublicKeyRequest',
    as InstanceOf['Google::Cloud::Oslogin::V1alpha::Oslogin::ImportSshPublicKeyRequest'];

coerce 'ImportSshPublicKeyRequest',
    from HashRef, via { 'Google::Cloud::Oslogin::V1alpha::Oslogin::ImportSshPublicKeyRequest'->new($_) };

declare 'RepeatedImportSshPublicKeyRequest',
    as ArrayRef[ImportSshPublicKeyRequest()];

coerce 'RepeatedImportSshPublicKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oslogin::V1alpha::Oslogin::ImportSshPublicKeyRequest'->new($_) } @$_ ] };

declare 'MapStringImportSshPublicKeyRequest',
    as HashRef[ImportSshPublicKeyRequest()];

declare 'ImportSshPublicKeyResponse',
    as InstanceOf['Google::Cloud::Oslogin::V1alpha::Oslogin::ImportSshPublicKeyResponse'];

coerce 'ImportSshPublicKeyResponse',
    from HashRef, via { 'Google::Cloud::Oslogin::V1alpha::Oslogin::ImportSshPublicKeyResponse'->new($_) };

declare 'RepeatedImportSshPublicKeyResponse',
    as ArrayRef[ImportSshPublicKeyResponse()];

coerce 'RepeatedImportSshPublicKeyResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oslogin::V1alpha::Oslogin::ImportSshPublicKeyResponse'->new($_) } @$_ ] };

declare 'MapStringImportSshPublicKeyResponse',
    as HashRef[ImportSshPublicKeyResponse()];

declare 'UpdateSshPublicKeyRequest',
    as InstanceOf['Google::Cloud::Oslogin::V1alpha::Oslogin::UpdateSshPublicKeyRequest'];

coerce 'UpdateSshPublicKeyRequest',
    from HashRef, via { 'Google::Cloud::Oslogin::V1alpha::Oslogin::UpdateSshPublicKeyRequest'->new($_) };

declare 'RepeatedUpdateSshPublicKeyRequest',
    as ArrayRef[UpdateSshPublicKeyRequest()];

coerce 'RepeatedUpdateSshPublicKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oslogin::V1alpha::Oslogin::UpdateSshPublicKeyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSshPublicKeyRequest',
    as HashRef[UpdateSshPublicKeyRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Oslogin::V1alpha::Oslogin::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
