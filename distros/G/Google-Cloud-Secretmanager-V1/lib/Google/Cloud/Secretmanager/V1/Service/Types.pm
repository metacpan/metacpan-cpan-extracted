package Google::Cloud::Secretmanager::V1::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListSecretsRequest',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Service::ListSecretsRequest'];

coerce 'ListSecretsRequest',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Service::ListSecretsRequest'->new($_) };

declare 'RepeatedListSecretsRequest',
    as ArrayRef[ListSecretsRequest()];

coerce 'RepeatedListSecretsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Service::ListSecretsRequest'->new($_) } @$_ ] };

declare 'MapStringListSecretsRequest',
    as HashRef[ListSecretsRequest()];

declare 'ListSecretsResponse',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Service::ListSecretsResponse'];

coerce 'ListSecretsResponse',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Service::ListSecretsResponse'->new($_) };

declare 'RepeatedListSecretsResponse',
    as ArrayRef[ListSecretsResponse()];

coerce 'RepeatedListSecretsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Service::ListSecretsResponse'->new($_) } @$_ ] };

declare 'MapStringListSecretsResponse',
    as HashRef[ListSecretsResponse()];

declare 'CreateSecretRequest',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Service::CreateSecretRequest'];

coerce 'CreateSecretRequest',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Service::CreateSecretRequest'->new($_) };

declare 'RepeatedCreateSecretRequest',
    as ArrayRef[CreateSecretRequest()];

coerce 'RepeatedCreateSecretRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Service::CreateSecretRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSecretRequest',
    as HashRef[CreateSecretRequest()];

declare 'AddSecretVersionRequest',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Service::AddSecretVersionRequest'];

coerce 'AddSecretVersionRequest',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Service::AddSecretVersionRequest'->new($_) };

declare 'RepeatedAddSecretVersionRequest',
    as ArrayRef[AddSecretVersionRequest()];

coerce 'RepeatedAddSecretVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Service::AddSecretVersionRequest'->new($_) } @$_ ] };

declare 'MapStringAddSecretVersionRequest',
    as HashRef[AddSecretVersionRequest()];

declare 'EnableManagedRotationRequest',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Service::EnableManagedRotationRequest'];

coerce 'EnableManagedRotationRequest',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Service::EnableManagedRotationRequest'->new($_) };

declare 'RepeatedEnableManagedRotationRequest',
    as ArrayRef[EnableManagedRotationRequest()];

coerce 'RepeatedEnableManagedRotationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Service::EnableManagedRotationRequest'->new($_) } @$_ ] };

declare 'MapStringEnableManagedRotationRequest',
    as HashRef[EnableManagedRotationRequest()];

declare 'CloudSQLSingleUserCredentials',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Service::EnableManagedRotationRequest::CloudSQLSingleUserCredentials'];

coerce 'CloudSQLSingleUserCredentials',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Service::EnableManagedRotationRequest::CloudSQLSingleUserCredentials'->new($_) };

declare 'RepeatedCloudSQLSingleUserCredentials',
    as ArrayRef[CloudSQLSingleUserCredentials()];

coerce 'RepeatedCloudSQLSingleUserCredentials',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Service::EnableManagedRotationRequest::CloudSQLSingleUserCredentials'->new($_) } @$_ ] };

declare 'MapStringCloudSQLSingleUserCredentials',
    as HashRef[CloudSQLSingleUserCredentials()];

declare 'RotateSecretRequest',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Service::RotateSecretRequest'];

coerce 'RotateSecretRequest',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Service::RotateSecretRequest'->new($_) };

declare 'RepeatedRotateSecretRequest',
    as ArrayRef[RotateSecretRequest()];

coerce 'RepeatedRotateSecretRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Service::RotateSecretRequest'->new($_) } @$_ ] };

declare 'MapStringRotateSecretRequest',
    as HashRef[RotateSecretRequest()];

declare 'GetSecretRequest',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Service::GetSecretRequest'];

coerce 'GetSecretRequest',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Service::GetSecretRequest'->new($_) };

declare 'RepeatedGetSecretRequest',
    as ArrayRef[GetSecretRequest()];

coerce 'RepeatedGetSecretRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Service::GetSecretRequest'->new($_) } @$_ ] };

declare 'MapStringGetSecretRequest',
    as HashRef[GetSecretRequest()];

declare 'ListSecretVersionsRequest',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Service::ListSecretVersionsRequest'];

coerce 'ListSecretVersionsRequest',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Service::ListSecretVersionsRequest'->new($_) };

declare 'RepeatedListSecretVersionsRequest',
    as ArrayRef[ListSecretVersionsRequest()];

coerce 'RepeatedListSecretVersionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Service::ListSecretVersionsRequest'->new($_) } @$_ ] };

declare 'MapStringListSecretVersionsRequest',
    as HashRef[ListSecretVersionsRequest()];

declare 'ListSecretVersionsResponse',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Service::ListSecretVersionsResponse'];

coerce 'ListSecretVersionsResponse',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Service::ListSecretVersionsResponse'->new($_) };

declare 'RepeatedListSecretVersionsResponse',
    as ArrayRef[ListSecretVersionsResponse()];

coerce 'RepeatedListSecretVersionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Service::ListSecretVersionsResponse'->new($_) } @$_ ] };

declare 'MapStringListSecretVersionsResponse',
    as HashRef[ListSecretVersionsResponse()];

declare 'GetSecretVersionRequest',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Service::GetSecretVersionRequest'];

coerce 'GetSecretVersionRequest',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Service::GetSecretVersionRequest'->new($_) };

declare 'RepeatedGetSecretVersionRequest',
    as ArrayRef[GetSecretVersionRequest()];

coerce 'RepeatedGetSecretVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Service::GetSecretVersionRequest'->new($_) } @$_ ] };

declare 'MapStringGetSecretVersionRequest',
    as HashRef[GetSecretVersionRequest()];

declare 'UpdateSecretRequest',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Service::UpdateSecretRequest'];

coerce 'UpdateSecretRequest',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Service::UpdateSecretRequest'->new($_) };

declare 'RepeatedUpdateSecretRequest',
    as ArrayRef[UpdateSecretRequest()];

coerce 'RepeatedUpdateSecretRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Service::UpdateSecretRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSecretRequest',
    as HashRef[UpdateSecretRequest()];

declare 'AccessSecretVersionRequest',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Service::AccessSecretVersionRequest'];

coerce 'AccessSecretVersionRequest',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Service::AccessSecretVersionRequest'->new($_) };

declare 'RepeatedAccessSecretVersionRequest',
    as ArrayRef[AccessSecretVersionRequest()];

coerce 'RepeatedAccessSecretVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Service::AccessSecretVersionRequest'->new($_) } @$_ ] };

declare 'MapStringAccessSecretVersionRequest',
    as HashRef[AccessSecretVersionRequest()];

declare 'AccessSecretVersionResponse',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Service::AccessSecretVersionResponse'];

coerce 'AccessSecretVersionResponse',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Service::AccessSecretVersionResponse'->new($_) };

declare 'RepeatedAccessSecretVersionResponse',
    as ArrayRef[AccessSecretVersionResponse()];

coerce 'RepeatedAccessSecretVersionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Service::AccessSecretVersionResponse'->new($_) } @$_ ] };

declare 'MapStringAccessSecretVersionResponse',
    as HashRef[AccessSecretVersionResponse()];

declare 'DeleteSecretRequest',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Service::DeleteSecretRequest'];

coerce 'DeleteSecretRequest',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Service::DeleteSecretRequest'->new($_) };

declare 'RepeatedDeleteSecretRequest',
    as ArrayRef[DeleteSecretRequest()];

coerce 'RepeatedDeleteSecretRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Service::DeleteSecretRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSecretRequest',
    as HashRef[DeleteSecretRequest()];

declare 'DisableSecretVersionRequest',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Service::DisableSecretVersionRequest'];

coerce 'DisableSecretVersionRequest',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Service::DisableSecretVersionRequest'->new($_) };

declare 'RepeatedDisableSecretVersionRequest',
    as ArrayRef[DisableSecretVersionRequest()];

coerce 'RepeatedDisableSecretVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Service::DisableSecretVersionRequest'->new($_) } @$_ ] };

declare 'MapStringDisableSecretVersionRequest',
    as HashRef[DisableSecretVersionRequest()];

declare 'EnableSecretVersionRequest',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Service::EnableSecretVersionRequest'];

coerce 'EnableSecretVersionRequest',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Service::EnableSecretVersionRequest'->new($_) };

declare 'RepeatedEnableSecretVersionRequest',
    as ArrayRef[EnableSecretVersionRequest()];

coerce 'RepeatedEnableSecretVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Service::EnableSecretVersionRequest'->new($_) } @$_ ] };

declare 'MapStringEnableSecretVersionRequest',
    as HashRef[EnableSecretVersionRequest()];

declare 'DestroySecretVersionRequest',
    as InstanceOf['Google::Cloud::Secretmanager::V1::Service::DestroySecretVersionRequest'];

coerce 'DestroySecretVersionRequest',
    from HashRef, via { 'Google::Cloud::Secretmanager::V1::Service::DestroySecretVersionRequest'->new($_) };

declare 'RepeatedDestroySecretVersionRequest',
    as ArrayRef[DestroySecretVersionRequest()];

coerce 'RepeatedDestroySecretVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::V1::Service::DestroySecretVersionRequest'->new($_) } @$_ ] };

declare 'MapStringDestroySecretVersionRequest',
    as HashRef[DestroySecretVersionRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Secretmanager::V1::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
