package Google::Cloud::Shell::V1::Cloudshell::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Environment',
    as InstanceOf['Google::Cloud::Shell::V1::Cloudshell::Environment'];

coerce 'Environment',
    from HashRef, via { 'Google::Cloud::Shell::V1::Cloudshell::Environment'->new($_) };

declare 'RepeatedEnvironment',
    as ArrayRef[Environment()];

coerce 'RepeatedEnvironment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Shell::V1::Cloudshell::Environment'->new($_) } @$_ ] };

declare 'MapStringEnvironment',
    as HashRef[Environment()];

declare 'State',
    as (Int | Str);

declare 'GetEnvironmentRequest',
    as InstanceOf['Google::Cloud::Shell::V1::Cloudshell::GetEnvironmentRequest'];

coerce 'GetEnvironmentRequest',
    from HashRef, via { 'Google::Cloud::Shell::V1::Cloudshell::GetEnvironmentRequest'->new($_) };

declare 'RepeatedGetEnvironmentRequest',
    as ArrayRef[GetEnvironmentRequest()];

coerce 'RepeatedGetEnvironmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Shell::V1::Cloudshell::GetEnvironmentRequest'->new($_) } @$_ ] };

declare 'MapStringGetEnvironmentRequest',
    as HashRef[GetEnvironmentRequest()];

declare 'CreateEnvironmentMetadata',
    as InstanceOf['Google::Cloud::Shell::V1::Cloudshell::CreateEnvironmentMetadata'];

coerce 'CreateEnvironmentMetadata',
    from HashRef, via { 'Google::Cloud::Shell::V1::Cloudshell::CreateEnvironmentMetadata'->new($_) };

declare 'RepeatedCreateEnvironmentMetadata',
    as ArrayRef[CreateEnvironmentMetadata()];

coerce 'RepeatedCreateEnvironmentMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Shell::V1::Cloudshell::CreateEnvironmentMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateEnvironmentMetadata',
    as HashRef[CreateEnvironmentMetadata()];

declare 'DeleteEnvironmentMetadata',
    as InstanceOf['Google::Cloud::Shell::V1::Cloudshell::DeleteEnvironmentMetadata'];

coerce 'DeleteEnvironmentMetadata',
    from HashRef, via { 'Google::Cloud::Shell::V1::Cloudshell::DeleteEnvironmentMetadata'->new($_) };

declare 'RepeatedDeleteEnvironmentMetadata',
    as ArrayRef[DeleteEnvironmentMetadata()];

coerce 'RepeatedDeleteEnvironmentMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Shell::V1::Cloudshell::DeleteEnvironmentMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteEnvironmentMetadata',
    as HashRef[DeleteEnvironmentMetadata()];

declare 'StartEnvironmentRequest',
    as InstanceOf['Google::Cloud::Shell::V1::Cloudshell::StartEnvironmentRequest'];

coerce 'StartEnvironmentRequest',
    from HashRef, via { 'Google::Cloud::Shell::V1::Cloudshell::StartEnvironmentRequest'->new($_) };

declare 'RepeatedStartEnvironmentRequest',
    as ArrayRef[StartEnvironmentRequest()];

coerce 'RepeatedStartEnvironmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Shell::V1::Cloudshell::StartEnvironmentRequest'->new($_) } @$_ ] };

declare 'MapStringStartEnvironmentRequest',
    as HashRef[StartEnvironmentRequest()];

declare 'AuthorizeEnvironmentRequest',
    as InstanceOf['Google::Cloud::Shell::V1::Cloudshell::AuthorizeEnvironmentRequest'];

coerce 'AuthorizeEnvironmentRequest',
    from HashRef, via { 'Google::Cloud::Shell::V1::Cloudshell::AuthorizeEnvironmentRequest'->new($_) };

declare 'RepeatedAuthorizeEnvironmentRequest',
    as ArrayRef[AuthorizeEnvironmentRequest()];

coerce 'RepeatedAuthorizeEnvironmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Shell::V1::Cloudshell::AuthorizeEnvironmentRequest'->new($_) } @$_ ] };

declare 'MapStringAuthorizeEnvironmentRequest',
    as HashRef[AuthorizeEnvironmentRequest()];

declare 'AuthorizeEnvironmentResponse',
    as InstanceOf['Google::Cloud::Shell::V1::Cloudshell::AuthorizeEnvironmentResponse'];

coerce 'AuthorizeEnvironmentResponse',
    from HashRef, via { 'Google::Cloud::Shell::V1::Cloudshell::AuthorizeEnvironmentResponse'->new($_) };

declare 'RepeatedAuthorizeEnvironmentResponse',
    as ArrayRef[AuthorizeEnvironmentResponse()];

coerce 'RepeatedAuthorizeEnvironmentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Shell::V1::Cloudshell::AuthorizeEnvironmentResponse'->new($_) } @$_ ] };

declare 'MapStringAuthorizeEnvironmentResponse',
    as HashRef[AuthorizeEnvironmentResponse()];

declare 'AuthorizeEnvironmentMetadata',
    as InstanceOf['Google::Cloud::Shell::V1::Cloudshell::AuthorizeEnvironmentMetadata'];

coerce 'AuthorizeEnvironmentMetadata',
    from HashRef, via { 'Google::Cloud::Shell::V1::Cloudshell::AuthorizeEnvironmentMetadata'->new($_) };

declare 'RepeatedAuthorizeEnvironmentMetadata',
    as ArrayRef[AuthorizeEnvironmentMetadata()];

coerce 'RepeatedAuthorizeEnvironmentMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Shell::V1::Cloudshell::AuthorizeEnvironmentMetadata'->new($_) } @$_ ] };

declare 'MapStringAuthorizeEnvironmentMetadata',
    as HashRef[AuthorizeEnvironmentMetadata()];

declare 'StartEnvironmentMetadata',
    as InstanceOf['Google::Cloud::Shell::V1::Cloudshell::StartEnvironmentMetadata'];

coerce 'StartEnvironmentMetadata',
    from HashRef, via { 'Google::Cloud::Shell::V1::Cloudshell::StartEnvironmentMetadata'->new($_) };

declare 'RepeatedStartEnvironmentMetadata',
    as ArrayRef[StartEnvironmentMetadata()];

coerce 'RepeatedStartEnvironmentMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Shell::V1::Cloudshell::StartEnvironmentMetadata'->new($_) } @$_ ] };

declare 'MapStringStartEnvironmentMetadata',
    as HashRef[StartEnvironmentMetadata()];

declare 'State',
    as (Int | Str);

declare 'StartEnvironmentResponse',
    as InstanceOf['Google::Cloud::Shell::V1::Cloudshell::StartEnvironmentResponse'];

coerce 'StartEnvironmentResponse',
    from HashRef, via { 'Google::Cloud::Shell::V1::Cloudshell::StartEnvironmentResponse'->new($_) };

declare 'RepeatedStartEnvironmentResponse',
    as ArrayRef[StartEnvironmentResponse()];

coerce 'RepeatedStartEnvironmentResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Shell::V1::Cloudshell::StartEnvironmentResponse'->new($_) } @$_ ] };

declare 'MapStringStartEnvironmentResponse',
    as HashRef[StartEnvironmentResponse()];

declare 'AddPublicKeyRequest',
    as InstanceOf['Google::Cloud::Shell::V1::Cloudshell::AddPublicKeyRequest'];

coerce 'AddPublicKeyRequest',
    from HashRef, via { 'Google::Cloud::Shell::V1::Cloudshell::AddPublicKeyRequest'->new($_) };

declare 'RepeatedAddPublicKeyRequest',
    as ArrayRef[AddPublicKeyRequest()];

coerce 'RepeatedAddPublicKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Shell::V1::Cloudshell::AddPublicKeyRequest'->new($_) } @$_ ] };

declare 'MapStringAddPublicKeyRequest',
    as HashRef[AddPublicKeyRequest()];

declare 'AddPublicKeyResponse',
    as InstanceOf['Google::Cloud::Shell::V1::Cloudshell::AddPublicKeyResponse'];

coerce 'AddPublicKeyResponse',
    from HashRef, via { 'Google::Cloud::Shell::V1::Cloudshell::AddPublicKeyResponse'->new($_) };

declare 'RepeatedAddPublicKeyResponse',
    as ArrayRef[AddPublicKeyResponse()];

coerce 'RepeatedAddPublicKeyResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Shell::V1::Cloudshell::AddPublicKeyResponse'->new($_) } @$_ ] };

declare 'MapStringAddPublicKeyResponse',
    as HashRef[AddPublicKeyResponse()];

declare 'AddPublicKeyMetadata',
    as InstanceOf['Google::Cloud::Shell::V1::Cloudshell::AddPublicKeyMetadata'];

coerce 'AddPublicKeyMetadata',
    from HashRef, via { 'Google::Cloud::Shell::V1::Cloudshell::AddPublicKeyMetadata'->new($_) };

declare 'RepeatedAddPublicKeyMetadata',
    as ArrayRef[AddPublicKeyMetadata()];

coerce 'RepeatedAddPublicKeyMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Shell::V1::Cloudshell::AddPublicKeyMetadata'->new($_) } @$_ ] };

declare 'MapStringAddPublicKeyMetadata',
    as HashRef[AddPublicKeyMetadata()];

declare 'RemovePublicKeyRequest',
    as InstanceOf['Google::Cloud::Shell::V1::Cloudshell::RemovePublicKeyRequest'];

coerce 'RemovePublicKeyRequest',
    from HashRef, via { 'Google::Cloud::Shell::V1::Cloudshell::RemovePublicKeyRequest'->new($_) };

declare 'RepeatedRemovePublicKeyRequest',
    as ArrayRef[RemovePublicKeyRequest()];

coerce 'RepeatedRemovePublicKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Shell::V1::Cloudshell::RemovePublicKeyRequest'->new($_) } @$_ ] };

declare 'MapStringRemovePublicKeyRequest',
    as HashRef[RemovePublicKeyRequest()];

declare 'RemovePublicKeyResponse',
    as InstanceOf['Google::Cloud::Shell::V1::Cloudshell::RemovePublicKeyResponse'];

coerce 'RemovePublicKeyResponse',
    from HashRef, via { 'Google::Cloud::Shell::V1::Cloudshell::RemovePublicKeyResponse'->new($_) };

declare 'RepeatedRemovePublicKeyResponse',
    as ArrayRef[RemovePublicKeyResponse()];

coerce 'RepeatedRemovePublicKeyResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Shell::V1::Cloudshell::RemovePublicKeyResponse'->new($_) } @$_ ] };

declare 'MapStringRemovePublicKeyResponse',
    as HashRef[RemovePublicKeyResponse()];

declare 'RemovePublicKeyMetadata',
    as InstanceOf['Google::Cloud::Shell::V1::Cloudshell::RemovePublicKeyMetadata'];

coerce 'RemovePublicKeyMetadata',
    from HashRef, via { 'Google::Cloud::Shell::V1::Cloudshell::RemovePublicKeyMetadata'->new($_) };

declare 'RepeatedRemovePublicKeyMetadata',
    as ArrayRef[RemovePublicKeyMetadata()];

coerce 'RepeatedRemovePublicKeyMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Shell::V1::Cloudshell::RemovePublicKeyMetadata'->new($_) } @$_ ] };

declare 'MapStringRemovePublicKeyMetadata',
    as HashRef[RemovePublicKeyMetadata()];

declare 'CloudShellErrorDetails',
    as InstanceOf['Google::Cloud::Shell::V1::Cloudshell::CloudShellErrorDetails'];

coerce 'CloudShellErrorDetails',
    from HashRef, via { 'Google::Cloud::Shell::V1::Cloudshell::CloudShellErrorDetails'->new($_) };

declare 'RepeatedCloudShellErrorDetails',
    as ArrayRef[CloudShellErrorDetails()];

coerce 'RepeatedCloudShellErrorDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Shell::V1::Cloudshell::CloudShellErrorDetails'->new($_) } @$_ ] };

declare 'MapStringCloudShellErrorDetails',
    as HashRef[CloudShellErrorDetails()];

declare 'CloudShellErrorCode',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Shell::V1::Cloudshell::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
