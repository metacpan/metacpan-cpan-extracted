package Google::Cloud::Ftp::V1::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ServerView',
    as (Int | Str);

declare 'UserView',
    as (Int | Str);

declare 'ExternalServerConfig',
    as InstanceOf['Google::Cloud::Ftp::V1::Service::ExternalServerConfig'];

coerce 'ExternalServerConfig',
    from HashRef, via { 'Google::Cloud::Ftp::V1::Service::ExternalServerConfig'->new($_) };

declare 'RepeatedExternalServerConfig',
    as ArrayRef[ExternalServerConfig()];

coerce 'RepeatedExternalServerConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ftp::V1::Service::ExternalServerConfig'->new($_) } @$_ ] };

declare 'MapStringExternalServerConfig',
    as HashRef[ExternalServerConfig()];

declare 'InternalServerConfig',
    as InstanceOf['Google::Cloud::Ftp::V1::Service::InternalServerConfig'];

coerce 'InternalServerConfig',
    from HashRef, via { 'Google::Cloud::Ftp::V1::Service::InternalServerConfig'->new($_) };

declare 'RepeatedInternalServerConfig',
    as ArrayRef[InternalServerConfig()];

coerce 'RepeatedInternalServerConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ftp::V1::Service::InternalServerConfig'->new($_) } @$_ ] };

declare 'MapStringInternalServerConfig',
    as HashRef[InternalServerConfig()];

declare 'AllowedConsumer',
    as InstanceOf['Google::Cloud::Ftp::V1::Service::InternalServerConfig::AllowedConsumer'];

coerce 'AllowedConsumer',
    from HashRef, via { 'Google::Cloud::Ftp::V1::Service::InternalServerConfig::AllowedConsumer'->new($_) };

declare 'RepeatedAllowedConsumer',
    as ArrayRef[AllowedConsumer()];

coerce 'RepeatedAllowedConsumer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ftp::V1::Service::InternalServerConfig::AllowedConsumer'->new($_) } @$_ ] };

declare 'MapStringAllowedConsumer',
    as HashRef[AllowedConsumer()];

declare 'DeniedConsumer',
    as InstanceOf['Google::Cloud::Ftp::V1::Service::InternalServerConfig::DeniedConsumer'];

coerce 'DeniedConsumer',
    from HashRef, via { 'Google::Cloud::Ftp::V1::Service::InternalServerConfig::DeniedConsumer'->new($_) };

declare 'RepeatedDeniedConsumer',
    as ArrayRef[DeniedConsumer()];

coerce 'RepeatedDeniedConsumer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ftp::V1::Service::InternalServerConfig::DeniedConsumer'->new($_) } @$_ ] };

declare 'MapStringDeniedConsumer',
    as HashRef[DeniedConsumer()];

declare 'PscEndpoint',
    as InstanceOf['Google::Cloud::Ftp::V1::Service::InternalServerConfig::PscEndpoint'];

coerce 'PscEndpoint',
    from HashRef, via { 'Google::Cloud::Ftp::V1::Service::InternalServerConfig::PscEndpoint'->new($_) };

declare 'RepeatedPscEndpoint',
    as ArrayRef[PscEndpoint()];

coerce 'RepeatedPscEndpoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ftp::V1::Service::InternalServerConfig::PscEndpoint'->new($_) } @$_ ] };

declare 'MapStringPscEndpoint',
    as HashRef[PscEndpoint()];

declare 'ServerCredential',
    as InstanceOf['Google::Cloud::Ftp::V1::Service::ServerCredential'];

coerce 'ServerCredential',
    from HashRef, via { 'Google::Cloud::Ftp::V1::Service::ServerCredential'->new($_) };

declare 'RepeatedServerCredential',
    as ArrayRef[ServerCredential()];

coerce 'RepeatedServerCredential',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ftp::V1::Service::ServerCredential'->new($_) } @$_ ] };

declare 'MapStringServerCredential',
    as HashRef[ServerCredential()];

declare 'Server',
    as InstanceOf['Google::Cloud::Ftp::V1::Service::Server'];

coerce 'Server',
    from HashRef, via { 'Google::Cloud::Ftp::V1::Service::Server'->new($_) };

declare 'RepeatedServer',
    as ArrayRef[Server()];

coerce 'RepeatedServer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ftp::V1::Service::Server'->new($_) } @$_ ] };

declare 'MapStringServer',
    as HashRef[Server()];

declare 'AccessType',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Ftp::V1::Service::Server::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Ftp::V1::Service::Server::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ftp::V1::Service::Server::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListServersRequest',
    as InstanceOf['Google::Cloud::Ftp::V1::Service::ListServersRequest'];

coerce 'ListServersRequest',
    from HashRef, via { 'Google::Cloud::Ftp::V1::Service::ListServersRequest'->new($_) };

declare 'RepeatedListServersRequest',
    as ArrayRef[ListServersRequest()];

coerce 'RepeatedListServersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ftp::V1::Service::ListServersRequest'->new($_) } @$_ ] };

declare 'MapStringListServersRequest',
    as HashRef[ListServersRequest()];

declare 'ListServersResponse',
    as InstanceOf['Google::Cloud::Ftp::V1::Service::ListServersResponse'];

coerce 'ListServersResponse',
    from HashRef, via { 'Google::Cloud::Ftp::V1::Service::ListServersResponse'->new($_) };

declare 'RepeatedListServersResponse',
    as ArrayRef[ListServersResponse()];

coerce 'RepeatedListServersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ftp::V1::Service::ListServersResponse'->new($_) } @$_ ] };

declare 'MapStringListServersResponse',
    as HashRef[ListServersResponse()];

declare 'GetServerRequest',
    as InstanceOf['Google::Cloud::Ftp::V1::Service::GetServerRequest'];

coerce 'GetServerRequest',
    from HashRef, via { 'Google::Cloud::Ftp::V1::Service::GetServerRequest'->new($_) };

declare 'RepeatedGetServerRequest',
    as ArrayRef[GetServerRequest()];

coerce 'RepeatedGetServerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ftp::V1::Service::GetServerRequest'->new($_) } @$_ ] };

declare 'MapStringGetServerRequest',
    as HashRef[GetServerRequest()];

declare 'CreateServerRequest',
    as InstanceOf['Google::Cloud::Ftp::V1::Service::CreateServerRequest'];

coerce 'CreateServerRequest',
    from HashRef, via { 'Google::Cloud::Ftp::V1::Service::CreateServerRequest'->new($_) };

declare 'RepeatedCreateServerRequest',
    as ArrayRef[CreateServerRequest()];

coerce 'RepeatedCreateServerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ftp::V1::Service::CreateServerRequest'->new($_) } @$_ ] };

declare 'MapStringCreateServerRequest',
    as HashRef[CreateServerRequest()];

declare 'UpdateServerRequest',
    as InstanceOf['Google::Cloud::Ftp::V1::Service::UpdateServerRequest'];

coerce 'UpdateServerRequest',
    from HashRef, via { 'Google::Cloud::Ftp::V1::Service::UpdateServerRequest'->new($_) };

declare 'RepeatedUpdateServerRequest',
    as ArrayRef[UpdateServerRequest()];

coerce 'RepeatedUpdateServerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ftp::V1::Service::UpdateServerRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateServerRequest',
    as HashRef[UpdateServerRequest()];

declare 'DeleteServerRequest',
    as InstanceOf['Google::Cloud::Ftp::V1::Service::DeleteServerRequest'];

coerce 'DeleteServerRequest',
    from HashRef, via { 'Google::Cloud::Ftp::V1::Service::DeleteServerRequest'->new($_) };

declare 'RepeatedDeleteServerRequest',
    as ArrayRef[DeleteServerRequest()];

coerce 'RepeatedDeleteServerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ftp::V1::Service::DeleteServerRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteServerRequest',
    as HashRef[DeleteServerRequest()];

declare 'StorageDirectoryMapping',
    as InstanceOf['Google::Cloud::Ftp::V1::Service::StorageDirectoryMapping'];

coerce 'StorageDirectoryMapping',
    from HashRef, via { 'Google::Cloud::Ftp::V1::Service::StorageDirectoryMapping'->new($_) };

declare 'RepeatedStorageDirectoryMapping',
    as ArrayRef[StorageDirectoryMapping()];

coerce 'RepeatedStorageDirectoryMapping',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ftp::V1::Service::StorageDirectoryMapping'->new($_) } @$_ ] };

declare 'MapStringStorageDirectoryMapping',
    as HashRef[StorageDirectoryMapping()];

declare 'Permission',
    as (Int | Str);

declare 'User',
    as InstanceOf['Google::Cloud::Ftp::V1::Service::User'];

coerce 'User',
    from HashRef, via { 'Google::Cloud::Ftp::V1::Service::User'->new($_) };

declare 'RepeatedUser',
    as ArrayRef[User()];

coerce 'RepeatedUser',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ftp::V1::Service::User'->new($_) } @$_ ] };

declare 'MapStringUser',
    as HashRef[User()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Ftp::V1::Service::User::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Ftp::V1::Service::User::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ftp::V1::Service::User::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListUsersRequest',
    as InstanceOf['Google::Cloud::Ftp::V1::Service::ListUsersRequest'];

coerce 'ListUsersRequest',
    from HashRef, via { 'Google::Cloud::Ftp::V1::Service::ListUsersRequest'->new($_) };

declare 'RepeatedListUsersRequest',
    as ArrayRef[ListUsersRequest()];

coerce 'RepeatedListUsersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ftp::V1::Service::ListUsersRequest'->new($_) } @$_ ] };

declare 'MapStringListUsersRequest',
    as HashRef[ListUsersRequest()];

declare 'ListUsersResponse',
    as InstanceOf['Google::Cloud::Ftp::V1::Service::ListUsersResponse'];

coerce 'ListUsersResponse',
    from HashRef, via { 'Google::Cloud::Ftp::V1::Service::ListUsersResponse'->new($_) };

declare 'RepeatedListUsersResponse',
    as ArrayRef[ListUsersResponse()];

coerce 'RepeatedListUsersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ftp::V1::Service::ListUsersResponse'->new($_) } @$_ ] };

declare 'MapStringListUsersResponse',
    as HashRef[ListUsersResponse()];

declare 'GetUserRequest',
    as InstanceOf['Google::Cloud::Ftp::V1::Service::GetUserRequest'];

coerce 'GetUserRequest',
    from HashRef, via { 'Google::Cloud::Ftp::V1::Service::GetUserRequest'->new($_) };

declare 'RepeatedGetUserRequest',
    as ArrayRef[GetUserRequest()];

coerce 'RepeatedGetUserRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ftp::V1::Service::GetUserRequest'->new($_) } @$_ ] };

declare 'MapStringGetUserRequest',
    as HashRef[GetUserRequest()];

declare 'CreateUserRequest',
    as InstanceOf['Google::Cloud::Ftp::V1::Service::CreateUserRequest'];

coerce 'CreateUserRequest',
    from HashRef, via { 'Google::Cloud::Ftp::V1::Service::CreateUserRequest'->new($_) };

declare 'RepeatedCreateUserRequest',
    as ArrayRef[CreateUserRequest()];

coerce 'RepeatedCreateUserRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ftp::V1::Service::CreateUserRequest'->new($_) } @$_ ] };

declare 'MapStringCreateUserRequest',
    as HashRef[CreateUserRequest()];

declare 'UpdateUserRequest',
    as InstanceOf['Google::Cloud::Ftp::V1::Service::UpdateUserRequest'];

coerce 'UpdateUserRequest',
    from HashRef, via { 'Google::Cloud::Ftp::V1::Service::UpdateUserRequest'->new($_) };

declare 'RepeatedUpdateUserRequest',
    as ArrayRef[UpdateUserRequest()];

coerce 'RepeatedUpdateUserRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ftp::V1::Service::UpdateUserRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateUserRequest',
    as HashRef[UpdateUserRequest()];

declare 'DeleteUserRequest',
    as InstanceOf['Google::Cloud::Ftp::V1::Service::DeleteUserRequest'];

coerce 'DeleteUserRequest',
    from HashRef, via { 'Google::Cloud::Ftp::V1::Service::DeleteUserRequest'->new($_) };

declare 'RepeatedDeleteUserRequest',
    as ArrayRef[DeleteUserRequest()];

coerce 'RepeatedDeleteUserRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ftp::V1::Service::DeleteUserRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteUserRequest',
    as HashRef[DeleteUserRequest()];

declare 'StartServerRequest',
    as InstanceOf['Google::Cloud::Ftp::V1::Service::StartServerRequest'];

coerce 'StartServerRequest',
    from HashRef, via { 'Google::Cloud::Ftp::V1::Service::StartServerRequest'->new($_) };

declare 'RepeatedStartServerRequest',
    as ArrayRef[StartServerRequest()];

coerce 'RepeatedStartServerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ftp::V1::Service::StartServerRequest'->new($_) } @$_ ] };

declare 'MapStringStartServerRequest',
    as HashRef[StartServerRequest()];

declare 'StopServerRequest',
    as InstanceOf['Google::Cloud::Ftp::V1::Service::StopServerRequest'];

coerce 'StopServerRequest',
    from HashRef, via { 'Google::Cloud::Ftp::V1::Service::StopServerRequest'->new($_) };

declare 'RepeatedStopServerRequest',
    as ArrayRef[StopServerRequest()];

coerce 'RepeatedStopServerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ftp::V1::Service::StopServerRequest'->new($_) } @$_ ] };

declare 'MapStringStopServerRequest',
    as HashRef[StopServerRequest()];

declare 'UserCredential',
    as InstanceOf['Google::Cloud::Ftp::V1::Service::UserCredential'];

coerce 'UserCredential',
    from HashRef, via { 'Google::Cloud::Ftp::V1::Service::UserCredential'->new($_) };

declare 'RepeatedUserCredential',
    as ArrayRef[UserCredential()];

coerce 'RepeatedUserCredential',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ftp::V1::Service::UserCredential'->new($_) } @$_ ] };

declare 'MapStringUserCredential',
    as HashRef[UserCredential()];

declare 'Type',
    as (Int | Str);

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Ftp::V1::Service::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Ftp::V1::Service::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ftp::V1::Service::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Ftp::V1::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
