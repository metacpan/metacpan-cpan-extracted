package Google::Cloud::Developerconnect::V1::DeveloperConnect::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CommitView',
    as (Int | Str);

declare 'SystemProvider',
    as (Int | Str);

declare 'ListUsersRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::ListUsersRequest'];

coerce 'ListUsersRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::ListUsersRequest'->new($_) };

declare 'RepeatedListUsersRequest',
    as ArrayRef[ListUsersRequest()];

coerce 'RepeatedListUsersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::ListUsersRequest'->new($_) } @$_ ] };

declare 'MapStringListUsersRequest',
    as HashRef[ListUsersRequest()];

declare 'ListUsersResponse',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::ListUsersResponse'];

coerce 'ListUsersResponse',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::ListUsersResponse'->new($_) };

declare 'RepeatedListUsersResponse',
    as ArrayRef[ListUsersResponse()];

coerce 'RepeatedListUsersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::ListUsersResponse'->new($_) } @$_ ] };

declare 'MapStringListUsersResponse',
    as HashRef[ListUsersResponse()];

declare 'Connection',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::Connection'];

coerce 'Connection',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::Connection'->new($_) };

declare 'RepeatedConnection',
    as ArrayRef[Connection()];

coerce 'RepeatedConnection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::Connection'->new($_) } @$_ ] };

declare 'MapStringConnection',
    as HashRef[Connection()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::Connection::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::Connection::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::Connection::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::Connection::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::Connection::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::Connection::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'CryptoKeyConfig',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::CryptoKeyConfig'];

coerce 'CryptoKeyConfig',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::CryptoKeyConfig'->new($_) };

declare 'RepeatedCryptoKeyConfig',
    as ArrayRef[CryptoKeyConfig()];

coerce 'RepeatedCryptoKeyConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::CryptoKeyConfig'->new($_) } @$_ ] };

declare 'MapStringCryptoKeyConfig',
    as HashRef[CryptoKeyConfig()];

declare 'GitProxyConfig',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::GitProxyConfig'];

coerce 'GitProxyConfig',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::GitProxyConfig'->new($_) };

declare 'RepeatedGitProxyConfig',
    as ArrayRef[GitProxyConfig()];

coerce 'RepeatedGitProxyConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::GitProxyConfig'->new($_) } @$_ ] };

declare 'MapStringGitProxyConfig',
    as HashRef[GitProxyConfig()];

declare 'InstallationState',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::InstallationState'];

coerce 'InstallationState',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::InstallationState'->new($_) };

declare 'RepeatedInstallationState',
    as ArrayRef[InstallationState()];

coerce 'RepeatedInstallationState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::InstallationState'->new($_) } @$_ ] };

declare 'MapStringInstallationState',
    as HashRef[InstallationState()];

declare 'Stage',
    as (Int | Str);

declare 'GenericHTTPEndpointConfig',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::GenericHTTPEndpointConfig'];

coerce 'GenericHTTPEndpointConfig',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::GenericHTTPEndpointConfig'->new($_) };

declare 'RepeatedGenericHTTPEndpointConfig',
    as ArrayRef[GenericHTTPEndpointConfig()];

coerce 'RepeatedGenericHTTPEndpointConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::GenericHTTPEndpointConfig'->new($_) } @$_ ] };

declare 'MapStringGenericHTTPEndpointConfig',
    as HashRef[GenericHTTPEndpointConfig()];

declare 'BasicAuthentication',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::GenericHTTPEndpointConfig::BasicAuthentication'];

coerce 'BasicAuthentication',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::GenericHTTPEndpointConfig::BasicAuthentication'->new($_) };

declare 'RepeatedBasicAuthentication',
    as ArrayRef[BasicAuthentication()];

coerce 'RepeatedBasicAuthentication',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::GenericHTTPEndpointConfig::BasicAuthentication'->new($_) } @$_ ] };

declare 'MapStringBasicAuthentication',
    as HashRef[BasicAuthentication()];

declare 'BearerTokenAuthentication',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::GenericHTTPEndpointConfig::BearerTokenAuthentication'];

coerce 'BearerTokenAuthentication',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::GenericHTTPEndpointConfig::BearerTokenAuthentication'->new($_) };

declare 'RepeatedBearerTokenAuthentication',
    as ArrayRef[BearerTokenAuthentication()];

coerce 'RepeatedBearerTokenAuthentication',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::GenericHTTPEndpointConfig::BearerTokenAuthentication'->new($_) } @$_ ] };

declare 'MapStringBearerTokenAuthentication',
    as HashRef[BearerTokenAuthentication()];

declare 'GitHubConfig',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::GitHubConfig'];

coerce 'GitHubConfig',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::GitHubConfig'->new($_) };

declare 'RepeatedGitHubConfig',
    as ArrayRef[GitHubConfig()];

coerce 'RepeatedGitHubConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::GitHubConfig'->new($_) } @$_ ] };

declare 'MapStringGitHubConfig',
    as HashRef[GitHubConfig()];

declare 'GitHubApp',
    as (Int | Str);

declare 'GitHubEnterpriseConfig',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::GitHubEnterpriseConfig'];

coerce 'GitHubEnterpriseConfig',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::GitHubEnterpriseConfig'->new($_) };

declare 'RepeatedGitHubEnterpriseConfig',
    as ArrayRef[GitHubEnterpriseConfig()];

coerce 'RepeatedGitHubEnterpriseConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::GitHubEnterpriseConfig'->new($_) } @$_ ] };

declare 'MapStringGitHubEnterpriseConfig',
    as HashRef[GitHubEnterpriseConfig()];

declare 'ServiceDirectoryConfig',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::ServiceDirectoryConfig'];

coerce 'ServiceDirectoryConfig',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::ServiceDirectoryConfig'->new($_) };

declare 'RepeatedServiceDirectoryConfig',
    as ArrayRef[ServiceDirectoryConfig()];

coerce 'RepeatedServiceDirectoryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::ServiceDirectoryConfig'->new($_) } @$_ ] };

declare 'MapStringServiceDirectoryConfig',
    as HashRef[ServiceDirectoryConfig()];

declare 'OAuthCredential',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::OAuthCredential'];

coerce 'OAuthCredential',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::OAuthCredential'->new($_) };

declare 'RepeatedOAuthCredential',
    as ArrayRef[OAuthCredential()];

coerce 'RepeatedOAuthCredential',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::OAuthCredential'->new($_) } @$_ ] };

declare 'MapStringOAuthCredential',
    as HashRef[OAuthCredential()];

declare 'GitLabConfig',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::GitLabConfig'];

coerce 'GitLabConfig',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::GitLabConfig'->new($_) };

declare 'RepeatedGitLabConfig',
    as ArrayRef[GitLabConfig()];

coerce 'RepeatedGitLabConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::GitLabConfig'->new($_) } @$_ ] };

declare 'MapStringGitLabConfig',
    as HashRef[GitLabConfig()];

declare 'UserCredential',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::UserCredential'];

coerce 'UserCredential',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::UserCredential'->new($_) };

declare 'RepeatedUserCredential',
    as ArrayRef[UserCredential()];

coerce 'RepeatedUserCredential',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::UserCredential'->new($_) } @$_ ] };

declare 'MapStringUserCredential',
    as HashRef[UserCredential()];

declare 'GitLabEnterpriseConfig',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::GitLabEnterpriseConfig'];

coerce 'GitLabEnterpriseConfig',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::GitLabEnterpriseConfig'->new($_) };

declare 'RepeatedGitLabEnterpriseConfig',
    as ArrayRef[GitLabEnterpriseConfig()];

coerce 'RepeatedGitLabEnterpriseConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::GitLabEnterpriseConfig'->new($_) } @$_ ] };

declare 'MapStringGitLabEnterpriseConfig',
    as HashRef[GitLabEnterpriseConfig()];

declare 'BitbucketDataCenterConfig',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::BitbucketDataCenterConfig'];

coerce 'BitbucketDataCenterConfig',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::BitbucketDataCenterConfig'->new($_) };

declare 'RepeatedBitbucketDataCenterConfig',
    as ArrayRef[BitbucketDataCenterConfig()];

coerce 'RepeatedBitbucketDataCenterConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::BitbucketDataCenterConfig'->new($_) } @$_ ] };

declare 'MapStringBitbucketDataCenterConfig',
    as HashRef[BitbucketDataCenterConfig()];

declare 'BitbucketCloudConfig',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::BitbucketCloudConfig'];

coerce 'BitbucketCloudConfig',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::BitbucketCloudConfig'->new($_) };

declare 'RepeatedBitbucketCloudConfig',
    as ArrayRef[BitbucketCloudConfig()];

coerce 'RepeatedBitbucketCloudConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::BitbucketCloudConfig'->new($_) } @$_ ] };

declare 'MapStringBitbucketCloudConfig',
    as HashRef[BitbucketCloudConfig()];

declare 'SecureSourceManagerInstanceConfig',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::SecureSourceManagerInstanceConfig'];

coerce 'SecureSourceManagerInstanceConfig',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::SecureSourceManagerInstanceConfig'->new($_) };

declare 'RepeatedSecureSourceManagerInstanceConfig',
    as ArrayRef[SecureSourceManagerInstanceConfig()];

coerce 'RepeatedSecureSourceManagerInstanceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::SecureSourceManagerInstanceConfig'->new($_) } @$_ ] };

declare 'MapStringSecureSourceManagerInstanceConfig',
    as HashRef[SecureSourceManagerInstanceConfig()];

declare 'ListConnectionsRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::ListConnectionsRequest'];

coerce 'ListConnectionsRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::ListConnectionsRequest'->new($_) };

declare 'RepeatedListConnectionsRequest',
    as ArrayRef[ListConnectionsRequest()];

coerce 'RepeatedListConnectionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::ListConnectionsRequest'->new($_) } @$_ ] };

declare 'MapStringListConnectionsRequest',
    as HashRef[ListConnectionsRequest()];

declare 'ListConnectionsResponse',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::ListConnectionsResponse'];

coerce 'ListConnectionsResponse',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::ListConnectionsResponse'->new($_) };

declare 'RepeatedListConnectionsResponse',
    as ArrayRef[ListConnectionsResponse()];

coerce 'RepeatedListConnectionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::ListConnectionsResponse'->new($_) } @$_ ] };

declare 'MapStringListConnectionsResponse',
    as HashRef[ListConnectionsResponse()];

declare 'GetConnectionRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::GetConnectionRequest'];

coerce 'GetConnectionRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::GetConnectionRequest'->new($_) };

declare 'RepeatedGetConnectionRequest',
    as ArrayRef[GetConnectionRequest()];

coerce 'RepeatedGetConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::GetConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringGetConnectionRequest',
    as HashRef[GetConnectionRequest()];

declare 'CreateConnectionRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::CreateConnectionRequest'];

coerce 'CreateConnectionRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::CreateConnectionRequest'->new($_) };

declare 'RepeatedCreateConnectionRequest',
    as ArrayRef[CreateConnectionRequest()];

coerce 'RepeatedCreateConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::CreateConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateConnectionRequest',
    as HashRef[CreateConnectionRequest()];

declare 'UpdateConnectionRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::UpdateConnectionRequest'];

coerce 'UpdateConnectionRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::UpdateConnectionRequest'->new($_) };

declare 'RepeatedUpdateConnectionRequest',
    as ArrayRef[UpdateConnectionRequest()];

coerce 'RepeatedUpdateConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::UpdateConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateConnectionRequest',
    as HashRef[UpdateConnectionRequest()];

declare 'DeleteConnectionRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::DeleteConnectionRequest'];

coerce 'DeleteConnectionRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::DeleteConnectionRequest'->new($_) };

declare 'RepeatedDeleteConnectionRequest',
    as ArrayRef[DeleteConnectionRequest()];

coerce 'RepeatedDeleteConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::DeleteConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteConnectionRequest',
    as HashRef[DeleteConnectionRequest()];

declare 'ListAccountConnectorsRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::ListAccountConnectorsRequest'];

coerce 'ListAccountConnectorsRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::ListAccountConnectorsRequest'->new($_) };

declare 'RepeatedListAccountConnectorsRequest',
    as ArrayRef[ListAccountConnectorsRequest()];

coerce 'RepeatedListAccountConnectorsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::ListAccountConnectorsRequest'->new($_) } @$_ ] };

declare 'MapStringListAccountConnectorsRequest',
    as HashRef[ListAccountConnectorsRequest()];

declare 'ListAccountConnectorsResponse',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::ListAccountConnectorsResponse'];

coerce 'ListAccountConnectorsResponse',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::ListAccountConnectorsResponse'->new($_) };

declare 'RepeatedListAccountConnectorsResponse',
    as ArrayRef[ListAccountConnectorsResponse()];

coerce 'RepeatedListAccountConnectorsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::ListAccountConnectorsResponse'->new($_) } @$_ ] };

declare 'MapStringListAccountConnectorsResponse',
    as HashRef[ListAccountConnectorsResponse()];

declare 'GetAccountConnectorRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::GetAccountConnectorRequest'];

coerce 'GetAccountConnectorRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::GetAccountConnectorRequest'->new($_) };

declare 'RepeatedGetAccountConnectorRequest',
    as ArrayRef[GetAccountConnectorRequest()];

coerce 'RepeatedGetAccountConnectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::GetAccountConnectorRequest'->new($_) } @$_ ] };

declare 'MapStringGetAccountConnectorRequest',
    as HashRef[GetAccountConnectorRequest()];

declare 'CreateAccountConnectorRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::CreateAccountConnectorRequest'];

coerce 'CreateAccountConnectorRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::CreateAccountConnectorRequest'->new($_) };

declare 'RepeatedCreateAccountConnectorRequest',
    as ArrayRef[CreateAccountConnectorRequest()];

coerce 'RepeatedCreateAccountConnectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::CreateAccountConnectorRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAccountConnectorRequest',
    as HashRef[CreateAccountConnectorRequest()];

declare 'UpdateAccountConnectorRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::UpdateAccountConnectorRequest'];

coerce 'UpdateAccountConnectorRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::UpdateAccountConnectorRequest'->new($_) };

declare 'RepeatedUpdateAccountConnectorRequest',
    as ArrayRef[UpdateAccountConnectorRequest()];

coerce 'RepeatedUpdateAccountConnectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::UpdateAccountConnectorRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAccountConnectorRequest',
    as HashRef[UpdateAccountConnectorRequest()];

declare 'DeleteAccountConnectorRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::DeleteAccountConnectorRequest'];

coerce 'DeleteAccountConnectorRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::DeleteAccountConnectorRequest'->new($_) };

declare 'RepeatedDeleteAccountConnectorRequest',
    as ArrayRef[DeleteAccountConnectorRequest()];

coerce 'RepeatedDeleteAccountConnectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::DeleteAccountConnectorRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAccountConnectorRequest',
    as HashRef[DeleteAccountConnectorRequest()];

declare 'DeleteUserRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::DeleteUserRequest'];

coerce 'DeleteUserRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::DeleteUserRequest'->new($_) };

declare 'RepeatedDeleteUserRequest',
    as ArrayRef[DeleteUserRequest()];

coerce 'RepeatedDeleteUserRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::DeleteUserRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteUserRequest',
    as HashRef[DeleteUserRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'FetchSelfRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchSelfRequest'];

coerce 'FetchSelfRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchSelfRequest'->new($_) };

declare 'RepeatedFetchSelfRequest',
    as ArrayRef[FetchSelfRequest()];

coerce 'RepeatedFetchSelfRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchSelfRequest'->new($_) } @$_ ] };

declare 'MapStringFetchSelfRequest',
    as HashRef[FetchSelfRequest()];

declare 'DeleteSelfRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::DeleteSelfRequest'];

coerce 'DeleteSelfRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::DeleteSelfRequest'->new($_) };

declare 'RepeatedDeleteSelfRequest',
    as ArrayRef[DeleteSelfRequest()];

coerce 'RepeatedDeleteSelfRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::DeleteSelfRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSelfRequest',
    as HashRef[DeleteSelfRequest()];

declare 'FetchAccessTokenRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchAccessTokenRequest'];

coerce 'FetchAccessTokenRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchAccessTokenRequest'->new($_) };

declare 'RepeatedFetchAccessTokenRequest',
    as ArrayRef[FetchAccessTokenRequest()];

coerce 'RepeatedFetchAccessTokenRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchAccessTokenRequest'->new($_) } @$_ ] };

declare 'MapStringFetchAccessTokenRequest',
    as HashRef[FetchAccessTokenRequest()];

declare 'FetchAccessTokenResponse',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchAccessTokenResponse'];

coerce 'FetchAccessTokenResponse',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchAccessTokenResponse'->new($_) };

declare 'RepeatedFetchAccessTokenResponse',
    as ArrayRef[FetchAccessTokenResponse()];

coerce 'RepeatedFetchAccessTokenResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchAccessTokenResponse'->new($_) } @$_ ] };

declare 'MapStringFetchAccessTokenResponse',
    as HashRef[FetchAccessTokenResponse()];

declare 'DiffGitRepositoryLinkCommitRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::DiffGitRepositoryLinkCommitRequest'];

coerce 'DiffGitRepositoryLinkCommitRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::DiffGitRepositoryLinkCommitRequest'->new($_) };

declare 'RepeatedDiffGitRepositoryLinkCommitRequest',
    as ArrayRef[DiffGitRepositoryLinkCommitRequest()];

coerce 'RepeatedDiffGitRepositoryLinkCommitRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::DiffGitRepositoryLinkCommitRequest'->new($_) } @$_ ] };

declare 'MapStringDiffGitRepositoryLinkCommitRequest',
    as HashRef[DiffGitRepositoryLinkCommitRequest()];

declare 'DiffGitRepositoryLinkCommitResponse',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::DiffGitRepositoryLinkCommitResponse'];

coerce 'DiffGitRepositoryLinkCommitResponse',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::DiffGitRepositoryLinkCommitResponse'->new($_) };

declare 'RepeatedDiffGitRepositoryLinkCommitResponse',
    as ArrayRef[DiffGitRepositoryLinkCommitResponse()];

coerce 'RepeatedDiffGitRepositoryLinkCommitResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::DiffGitRepositoryLinkCommitResponse'->new($_) } @$_ ] };

declare 'MapStringDiffGitRepositoryLinkCommitResponse',
    as HashRef[DiffGitRepositoryLinkCommitResponse()];

declare 'FileDiff',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::FileDiff'];

coerce 'FileDiff',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FileDiff'->new($_) };

declare 'RepeatedFileDiff',
    as ArrayRef[FileDiff()];

coerce 'RepeatedFileDiff',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FileDiff'->new($_) } @$_ ] };

declare 'MapStringFileDiff',
    as HashRef[FileDiff()];

declare 'StartOAuthRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::StartOAuthRequest'];

coerce 'StartOAuthRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::StartOAuthRequest'->new($_) };

declare 'RepeatedStartOAuthRequest',
    as ArrayRef[StartOAuthRequest()];

coerce 'RepeatedStartOAuthRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::StartOAuthRequest'->new($_) } @$_ ] };

declare 'MapStringStartOAuthRequest',
    as HashRef[StartOAuthRequest()];

declare 'StartOAuthResponse',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::StartOAuthResponse'];

coerce 'StartOAuthResponse',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::StartOAuthResponse'->new($_) };

declare 'RepeatedStartOAuthResponse',
    as ArrayRef[StartOAuthResponse()];

coerce 'RepeatedStartOAuthResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::StartOAuthResponse'->new($_) } @$_ ] };

declare 'MapStringStartOAuthResponse',
    as HashRef[StartOAuthResponse()];

declare 'FinishOAuthRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::FinishOAuthRequest'];

coerce 'FinishOAuthRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FinishOAuthRequest'->new($_) };

declare 'RepeatedFinishOAuthRequest',
    as ArrayRef[FinishOAuthRequest()];

coerce 'RepeatedFinishOAuthRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FinishOAuthRequest'->new($_) } @$_ ] };

declare 'MapStringFinishOAuthRequest',
    as HashRef[FinishOAuthRequest()];

declare 'OAuthParams',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::FinishOAuthRequest::OAuthParams'];

coerce 'OAuthParams',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FinishOAuthRequest::OAuthParams'->new($_) };

declare 'RepeatedOAuthParams',
    as ArrayRef[OAuthParams()];

coerce 'RepeatedOAuthParams',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FinishOAuthRequest::OAuthParams'->new($_) } @$_ ] };

declare 'MapStringOAuthParams',
    as HashRef[OAuthParams()];

declare 'GoogleOAuthParams',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::FinishOAuthRequest::GoogleOAuthParams'];

coerce 'GoogleOAuthParams',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FinishOAuthRequest::GoogleOAuthParams'->new($_) };

declare 'RepeatedGoogleOAuthParams',
    as ArrayRef[GoogleOAuthParams()];

coerce 'RepeatedGoogleOAuthParams',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FinishOAuthRequest::GoogleOAuthParams'->new($_) } @$_ ] };

declare 'MapStringGoogleOAuthParams',
    as HashRef[GoogleOAuthParams()];

declare 'FinishOAuthResponse',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::FinishOAuthResponse'];

coerce 'FinishOAuthResponse',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FinishOAuthResponse'->new($_) };

declare 'RepeatedFinishOAuthResponse',
    as ArrayRef[FinishOAuthResponse()];

coerce 'RepeatedFinishOAuthResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FinishOAuthResponse'->new($_) } @$_ ] };

declare 'MapStringFinishOAuthResponse',
    as HashRef[FinishOAuthResponse()];

declare 'ExchangeError',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::ExchangeError'];

coerce 'ExchangeError',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::ExchangeError'->new($_) };

declare 'RepeatedExchangeError',
    as ArrayRef[ExchangeError()];

coerce 'RepeatedExchangeError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::ExchangeError'->new($_) } @$_ ] };

declare 'MapStringExchangeError',
    as HashRef[ExchangeError()];

declare 'GitRepositoryLink',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::GitRepositoryLink'];

coerce 'GitRepositoryLink',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::GitRepositoryLink'->new($_) };

declare 'RepeatedGitRepositoryLink',
    as ArrayRef[GitRepositoryLink()];

coerce 'RepeatedGitRepositoryLink',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::GitRepositoryLink'->new($_) } @$_ ] };

declare 'MapStringGitRepositoryLink',
    as HashRef[GitRepositoryLink()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::GitRepositoryLink::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::GitRepositoryLink::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::GitRepositoryLink::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::GitRepositoryLink::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::GitRepositoryLink::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::GitRepositoryLink::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'CreateGitRepositoryLinkRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::CreateGitRepositoryLinkRequest'];

coerce 'CreateGitRepositoryLinkRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::CreateGitRepositoryLinkRequest'->new($_) };

declare 'RepeatedCreateGitRepositoryLinkRequest',
    as ArrayRef[CreateGitRepositoryLinkRequest()];

coerce 'RepeatedCreateGitRepositoryLinkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::CreateGitRepositoryLinkRequest'->new($_) } @$_ ] };

declare 'MapStringCreateGitRepositoryLinkRequest',
    as HashRef[CreateGitRepositoryLinkRequest()];

declare 'DeleteGitRepositoryLinkRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::DeleteGitRepositoryLinkRequest'];

coerce 'DeleteGitRepositoryLinkRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::DeleteGitRepositoryLinkRequest'->new($_) };

declare 'RepeatedDeleteGitRepositoryLinkRequest',
    as ArrayRef[DeleteGitRepositoryLinkRequest()];

coerce 'RepeatedDeleteGitRepositoryLinkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::DeleteGitRepositoryLinkRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteGitRepositoryLinkRequest',
    as HashRef[DeleteGitRepositoryLinkRequest()];

declare 'ListGitRepositoryLinksRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::ListGitRepositoryLinksRequest'];

coerce 'ListGitRepositoryLinksRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::ListGitRepositoryLinksRequest'->new($_) };

declare 'RepeatedListGitRepositoryLinksRequest',
    as ArrayRef[ListGitRepositoryLinksRequest()];

coerce 'RepeatedListGitRepositoryLinksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::ListGitRepositoryLinksRequest'->new($_) } @$_ ] };

declare 'MapStringListGitRepositoryLinksRequest',
    as HashRef[ListGitRepositoryLinksRequest()];

declare 'ListGitRepositoryLinksResponse',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::ListGitRepositoryLinksResponse'];

coerce 'ListGitRepositoryLinksResponse',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::ListGitRepositoryLinksResponse'->new($_) };

declare 'RepeatedListGitRepositoryLinksResponse',
    as ArrayRef[ListGitRepositoryLinksResponse()];

coerce 'RepeatedListGitRepositoryLinksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::ListGitRepositoryLinksResponse'->new($_) } @$_ ] };

declare 'MapStringListGitRepositoryLinksResponse',
    as HashRef[ListGitRepositoryLinksResponse()];

declare 'GetGitRepositoryLinkRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::GetGitRepositoryLinkRequest'];

coerce 'GetGitRepositoryLinkRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::GetGitRepositoryLinkRequest'->new($_) };

declare 'RepeatedGetGitRepositoryLinkRequest',
    as ArrayRef[GetGitRepositoryLinkRequest()];

coerce 'RepeatedGetGitRepositoryLinkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::GetGitRepositoryLinkRequest'->new($_) } @$_ ] };

declare 'MapStringGetGitRepositoryLinkRequest',
    as HashRef[GetGitRepositoryLinkRequest()];

declare 'FetchReadWriteTokenRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchReadWriteTokenRequest'];

coerce 'FetchReadWriteTokenRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchReadWriteTokenRequest'->new($_) };

declare 'RepeatedFetchReadWriteTokenRequest',
    as ArrayRef[FetchReadWriteTokenRequest()];

coerce 'RepeatedFetchReadWriteTokenRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchReadWriteTokenRequest'->new($_) } @$_ ] };

declare 'MapStringFetchReadWriteTokenRequest',
    as HashRef[FetchReadWriteTokenRequest()];

declare 'FetchReadTokenRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchReadTokenRequest'];

coerce 'FetchReadTokenRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchReadTokenRequest'->new($_) };

declare 'RepeatedFetchReadTokenRequest',
    as ArrayRef[FetchReadTokenRequest()];

coerce 'RepeatedFetchReadTokenRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchReadTokenRequest'->new($_) } @$_ ] };

declare 'MapStringFetchReadTokenRequest',
    as HashRef[FetchReadTokenRequest()];

declare 'FetchReadTokenResponse',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchReadTokenResponse'];

coerce 'FetchReadTokenResponse',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchReadTokenResponse'->new($_) };

declare 'RepeatedFetchReadTokenResponse',
    as ArrayRef[FetchReadTokenResponse()];

coerce 'RepeatedFetchReadTokenResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchReadTokenResponse'->new($_) } @$_ ] };

declare 'MapStringFetchReadTokenResponse',
    as HashRef[FetchReadTokenResponse()];

declare 'FetchReadWriteTokenResponse',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchReadWriteTokenResponse'];

coerce 'FetchReadWriteTokenResponse',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchReadWriteTokenResponse'->new($_) };

declare 'RepeatedFetchReadWriteTokenResponse',
    as ArrayRef[FetchReadWriteTokenResponse()];

coerce 'RepeatedFetchReadWriteTokenResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchReadWriteTokenResponse'->new($_) } @$_ ] };

declare 'MapStringFetchReadWriteTokenResponse',
    as HashRef[FetchReadWriteTokenResponse()];

declare 'OpenGitRepositoryLinkPullRequestRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::OpenGitRepositoryLinkPullRequestRequest'];

coerce 'OpenGitRepositoryLinkPullRequestRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::OpenGitRepositoryLinkPullRequestRequest'->new($_) };

declare 'RepeatedOpenGitRepositoryLinkPullRequestRequest',
    as ArrayRef[OpenGitRepositoryLinkPullRequestRequest()];

coerce 'RepeatedOpenGitRepositoryLinkPullRequestRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::OpenGitRepositoryLinkPullRequestRequest'->new($_) } @$_ ] };

declare 'MapStringOpenGitRepositoryLinkPullRequestRequest',
    as HashRef[OpenGitRepositoryLinkPullRequestRequest()];

declare 'FetchLinkableGitRepositoriesRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchLinkableGitRepositoriesRequest'];

coerce 'FetchLinkableGitRepositoriesRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchLinkableGitRepositoriesRequest'->new($_) };

declare 'RepeatedFetchLinkableGitRepositoriesRequest',
    as ArrayRef[FetchLinkableGitRepositoriesRequest()];

coerce 'RepeatedFetchLinkableGitRepositoriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchLinkableGitRepositoriesRequest'->new($_) } @$_ ] };

declare 'MapStringFetchLinkableGitRepositoriesRequest',
    as HashRef[FetchLinkableGitRepositoriesRequest()];

declare 'FetchLinkableGitRepositoriesResponse',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchLinkableGitRepositoriesResponse'];

coerce 'FetchLinkableGitRepositoriesResponse',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchLinkableGitRepositoriesResponse'->new($_) };

declare 'RepeatedFetchLinkableGitRepositoriesResponse',
    as ArrayRef[FetchLinkableGitRepositoriesResponse()];

coerce 'RepeatedFetchLinkableGitRepositoriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchLinkableGitRepositoriesResponse'->new($_) } @$_ ] };

declare 'MapStringFetchLinkableGitRepositoriesResponse',
    as HashRef[FetchLinkableGitRepositoriesResponse()];

declare 'LinkableGitRepository',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::LinkableGitRepository'];

coerce 'LinkableGitRepository',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::LinkableGitRepository'->new($_) };

declare 'RepeatedLinkableGitRepository',
    as ArrayRef[LinkableGitRepository()];

coerce 'RepeatedLinkableGitRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::LinkableGitRepository'->new($_) } @$_ ] };

declare 'MapStringLinkableGitRepository',
    as HashRef[LinkableGitRepository()];

declare 'FetchGitHubInstallationsRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitHubInstallationsRequest'];

coerce 'FetchGitHubInstallationsRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitHubInstallationsRequest'->new($_) };

declare 'RepeatedFetchGitHubInstallationsRequest',
    as ArrayRef[FetchGitHubInstallationsRequest()];

coerce 'RepeatedFetchGitHubInstallationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitHubInstallationsRequest'->new($_) } @$_ ] };

declare 'MapStringFetchGitHubInstallationsRequest',
    as HashRef[FetchGitHubInstallationsRequest()];

declare 'FetchGitHubInstallationsResponse',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitHubInstallationsResponse'];

coerce 'FetchGitHubInstallationsResponse',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitHubInstallationsResponse'->new($_) };

declare 'RepeatedFetchGitHubInstallationsResponse',
    as ArrayRef[FetchGitHubInstallationsResponse()];

coerce 'RepeatedFetchGitHubInstallationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitHubInstallationsResponse'->new($_) } @$_ ] };

declare 'MapStringFetchGitHubInstallationsResponse',
    as HashRef[FetchGitHubInstallationsResponse()];

declare 'Installation',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitHubInstallationsResponse::Installation'];

coerce 'Installation',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitHubInstallationsResponse::Installation'->new($_) };

declare 'RepeatedInstallation',
    as ArrayRef[Installation()];

coerce 'RepeatedInstallation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitHubInstallationsResponse::Installation'->new($_) } @$_ ] };

declare 'MapStringInstallation',
    as HashRef[Installation()];

declare 'FetchGitRefsRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitRefsRequest'];

coerce 'FetchGitRefsRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitRefsRequest'->new($_) };

declare 'RepeatedFetchGitRefsRequest',
    as ArrayRef[FetchGitRefsRequest()];

coerce 'RepeatedFetchGitRefsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitRefsRequest'->new($_) } @$_ ] };

declare 'MapStringFetchGitRefsRequest',
    as HashRef[FetchGitRefsRequest()];

declare 'RefType',
    as (Int | Str);

declare 'FetchGitRefsResponse',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitRefsResponse'];

coerce 'FetchGitRefsResponse',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitRefsResponse'->new($_) };

declare 'RepeatedFetchGitRefsResponse',
    as ArrayRef[FetchGitRefsResponse()];

coerce 'RepeatedFetchGitRefsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitRefsResponse'->new($_) } @$_ ] };

declare 'MapStringFetchGitRefsResponse',
    as HashRef[FetchGitRefsResponse()];

declare 'FetchGitRepositoryLinkCommitRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitRepositoryLinkCommitRequest'];

coerce 'FetchGitRepositoryLinkCommitRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitRepositoryLinkCommitRequest'->new($_) };

declare 'RepeatedFetchGitRepositoryLinkCommitRequest',
    as ArrayRef[FetchGitRepositoryLinkCommitRequest()];

coerce 'RepeatedFetchGitRepositoryLinkCommitRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitRepositoryLinkCommitRequest'->new($_) } @$_ ] };

declare 'MapStringFetchGitRepositoryLinkCommitRequest',
    as HashRef[FetchGitRepositoryLinkCommitRequest()];

declare 'FetchGitRepositoryLinkCommitResponse',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitRepositoryLinkCommitResponse'];

coerce 'FetchGitRepositoryLinkCommitResponse',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitRepositoryLinkCommitResponse'->new($_) };

declare 'RepeatedFetchGitRepositoryLinkCommitResponse',
    as ArrayRef[FetchGitRepositoryLinkCommitResponse()];

coerce 'RepeatedFetchGitRepositoryLinkCommitResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitRepositoryLinkCommitResponse'->new($_) } @$_ ] };

declare 'MapStringFetchGitRepositoryLinkCommitResponse',
    as HashRef[FetchGitRepositoryLinkCommitResponse()];

declare 'FetchGitRepositoryLinkCommitListRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitRepositoryLinkCommitListRequest'];

coerce 'FetchGitRepositoryLinkCommitListRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitRepositoryLinkCommitListRequest'->new($_) };

declare 'RepeatedFetchGitRepositoryLinkCommitListRequest',
    as ArrayRef[FetchGitRepositoryLinkCommitListRequest()];

coerce 'RepeatedFetchGitRepositoryLinkCommitListRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitRepositoryLinkCommitListRequest'->new($_) } @$_ ] };

declare 'MapStringFetchGitRepositoryLinkCommitListRequest',
    as HashRef[FetchGitRepositoryLinkCommitListRequest()];

declare 'FetchGitRepositoryLinkCommitListResponse',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitRepositoryLinkCommitListResponse'];

coerce 'FetchGitRepositoryLinkCommitListResponse',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitRepositoryLinkCommitListResponse'->new($_) };

declare 'RepeatedFetchGitRepositoryLinkCommitListResponse',
    as ArrayRef[FetchGitRepositoryLinkCommitListResponse()];

coerce 'RepeatedFetchGitRepositoryLinkCommitListResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitRepositoryLinkCommitListResponse'->new($_) } @$_ ] };

declare 'MapStringFetchGitRepositoryLinkCommitListResponse',
    as HashRef[FetchGitRepositoryLinkCommitListResponse()];

declare 'SCMCommit',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::SCMCommit'];

coerce 'SCMCommit',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::SCMCommit'->new($_) };

declare 'RepeatedSCMCommit',
    as ArrayRef[SCMCommit()];

coerce 'RepeatedSCMCommit',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::SCMCommit'->new($_) } @$_ ] };

declare 'MapStringSCMCommit',
    as HashRef[SCMCommit()];

declare 'FetchGitRepositoryLinkFileBlameRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitRepositoryLinkFileBlameRequest'];

coerce 'FetchGitRepositoryLinkFileBlameRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitRepositoryLinkFileBlameRequest'->new($_) };

declare 'RepeatedFetchGitRepositoryLinkFileBlameRequest',
    as ArrayRef[FetchGitRepositoryLinkFileBlameRequest()];

coerce 'RepeatedFetchGitRepositoryLinkFileBlameRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitRepositoryLinkFileBlameRequest'->new($_) } @$_ ] };

declare 'MapStringFetchGitRepositoryLinkFileBlameRequest',
    as HashRef[FetchGitRepositoryLinkFileBlameRequest()];

declare 'BlameRange',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::BlameRange'];

coerce 'BlameRange',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::BlameRange'->new($_) };

declare 'RepeatedBlameRange',
    as ArrayRef[BlameRange()];

coerce 'RepeatedBlameRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::BlameRange'->new($_) } @$_ ] };

declare 'MapStringBlameRange',
    as HashRef[BlameRange()];

declare 'FetchGitRepositoryLinkFileBlameResponse',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitRepositoryLinkFileBlameResponse'];

coerce 'FetchGitRepositoryLinkFileBlameResponse',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitRepositoryLinkFileBlameResponse'->new($_) };

declare 'RepeatedFetchGitRepositoryLinkFileBlameResponse',
    as ArrayRef[FetchGitRepositoryLinkFileBlameResponse()];

coerce 'RepeatedFetchGitRepositoryLinkFileBlameResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitRepositoryLinkFileBlameResponse'->new($_) } @$_ ] };

declare 'MapStringFetchGitRepositoryLinkFileBlameResponse',
    as HashRef[FetchGitRepositoryLinkFileBlameResponse()];

declare 'FetchGitRepositoryLinkPullRequestRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitRepositoryLinkPullRequestRequest'];

coerce 'FetchGitRepositoryLinkPullRequestRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitRepositoryLinkPullRequestRequest'->new($_) };

declare 'RepeatedFetchGitRepositoryLinkPullRequestRequest',
    as ArrayRef[FetchGitRepositoryLinkPullRequestRequest()];

coerce 'RepeatedFetchGitRepositoryLinkPullRequestRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitRepositoryLinkPullRequestRequest'->new($_) } @$_ ] };

declare 'MapStringFetchGitRepositoryLinkPullRequestRequest',
    as HashRef[FetchGitRepositoryLinkPullRequestRequest()];

declare 'PullRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::PullRequest'];

coerce 'PullRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::PullRequest'->new($_) };

declare 'RepeatedPullRequest',
    as ArrayRef[PullRequest()];

coerce 'RepeatedPullRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::PullRequest'->new($_) } @$_ ] };

declare 'MapStringPullRequest',
    as HashRef[PullRequest()];

declare 'State',
    as (Int | Str);

declare 'Mergeability',
    as (Int | Str);

declare 'PullRequestComment',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::PullRequestComment'];

coerce 'PullRequestComment',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::PullRequestComment'->new($_) };

declare 'RepeatedPullRequestComment',
    as ArrayRef[PullRequestComment()];

coerce 'RepeatedPullRequestComment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::PullRequestComment'->new($_) } @$_ ] };

declare 'MapStringPullRequestComment',
    as HashRef[PullRequestComment()];

declare 'AddGitRepositoryLinkPullRequestCommentRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::AddGitRepositoryLinkPullRequestCommentRequest'];

coerce 'AddGitRepositoryLinkPullRequestCommentRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::AddGitRepositoryLinkPullRequestCommentRequest'->new($_) };

declare 'RepeatedAddGitRepositoryLinkPullRequestCommentRequest',
    as ArrayRef[AddGitRepositoryLinkPullRequestCommentRequest()];

coerce 'RepeatedAddGitRepositoryLinkPullRequestCommentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::AddGitRepositoryLinkPullRequestCommentRequest'->new($_) } @$_ ] };

declare 'MapStringAddGitRepositoryLinkPullRequestCommentRequest',
    as HashRef[AddGitRepositoryLinkPullRequestCommentRequest()];

declare 'PullRequestReviewComment',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::PullRequestReviewComment'];

coerce 'PullRequestReviewComment',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::PullRequestReviewComment'->new($_) };

declare 'RepeatedPullRequestReviewComment',
    as ArrayRef[PullRequestReviewComment()];

coerce 'RepeatedPullRequestReviewComment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::PullRequestReviewComment'->new($_) } @$_ ] };

declare 'MapStringPullRequestReviewComment',
    as HashRef[PullRequestReviewComment()];

declare 'DiffSide',
    as (Int | Str);

declare 'AddGitRepositoryLinkPullRequestReviewCommentRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::AddGitRepositoryLinkPullRequestReviewCommentRequest'];

coerce 'AddGitRepositoryLinkPullRequestReviewCommentRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::AddGitRepositoryLinkPullRequestReviewCommentRequest'->new($_) };

declare 'RepeatedAddGitRepositoryLinkPullRequestReviewCommentRequest',
    as ArrayRef[AddGitRepositoryLinkPullRequestReviewCommentRequest()];

coerce 'RepeatedAddGitRepositoryLinkPullRequestReviewCommentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::AddGitRepositoryLinkPullRequestReviewCommentRequest'->new($_) } @$_ ] };

declare 'MapStringAddGitRepositoryLinkPullRequestReviewCommentRequest',
    as HashRef[AddGitRepositoryLinkPullRequestReviewCommentRequest()];

declare 'ModifyGitRepositoryLinkPullRequestRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::ModifyGitRepositoryLinkPullRequestRequest'];

coerce 'ModifyGitRepositoryLinkPullRequestRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::ModifyGitRepositoryLinkPullRequestRequest'->new($_) };

declare 'RepeatedModifyGitRepositoryLinkPullRequestRequest',
    as ArrayRef[ModifyGitRepositoryLinkPullRequestRequest()];

coerce 'RepeatedModifyGitRepositoryLinkPullRequestRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::ModifyGitRepositoryLinkPullRequestRequest'->new($_) } @$_ ] };

declare 'MapStringModifyGitRepositoryLinkPullRequestRequest',
    as HashRef[ModifyGitRepositoryLinkPullRequestRequest()];

declare 'State',
    as (Int | Str);

declare 'FetchGitRepositoryLinkPullRequestListRequest',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitRepositoryLinkPullRequestListRequest'];

coerce 'FetchGitRepositoryLinkPullRequestListRequest',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitRepositoryLinkPullRequestListRequest'->new($_) };

declare 'RepeatedFetchGitRepositoryLinkPullRequestListRequest',
    as ArrayRef[FetchGitRepositoryLinkPullRequestListRequest()];

coerce 'RepeatedFetchGitRepositoryLinkPullRequestListRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitRepositoryLinkPullRequestListRequest'->new($_) } @$_ ] };

declare 'MapStringFetchGitRepositoryLinkPullRequestListRequest',
    as HashRef[FetchGitRepositoryLinkPullRequestListRequest()];

declare 'FetchGitRepositoryLinkPullRequestListResponse',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitRepositoryLinkPullRequestListResponse'];

coerce 'FetchGitRepositoryLinkPullRequestListResponse',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitRepositoryLinkPullRequestListResponse'->new($_) };

declare 'RepeatedFetchGitRepositoryLinkPullRequestListResponse',
    as ArrayRef[FetchGitRepositoryLinkPullRequestListResponse()];

coerce 'RepeatedFetchGitRepositoryLinkPullRequestListResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::FetchGitRepositoryLinkPullRequestListResponse'->new($_) } @$_ ] };

declare 'MapStringFetchGitRepositoryLinkPullRequestListResponse',
    as HashRef[FetchGitRepositoryLinkPullRequestListResponse()];

declare 'AccountConnector',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::AccountConnector'];

coerce 'AccountConnector',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::AccountConnector'->new($_) };

declare 'RepeatedAccountConnector',
    as ArrayRef[AccountConnector()];

coerce 'RepeatedAccountConnector',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::AccountConnector'->new($_) } @$_ ] };

declare 'MapStringAccountConnector',
    as HashRef[AccountConnector()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::AccountConnector::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::AccountConnector::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::AccountConnector::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::AccountConnector::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::AccountConnector::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::AccountConnector::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'User',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::User'];

coerce 'User',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::User'->new($_) };

declare 'RepeatedUser',
    as ArrayRef[User()];

coerce 'RepeatedUser',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::User'->new($_) } @$_ ] };

declare 'MapStringUser',
    as HashRef[User()];

declare 'ProviderOAuthConfig',
    as InstanceOf['Google::Cloud::Developerconnect::V1::DeveloperConnect::ProviderOAuthConfig'];

coerce 'ProviderOAuthConfig',
    from HashRef, via { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::ProviderOAuthConfig'->new($_) };

declare 'RepeatedProviderOAuthConfig',
    as ArrayRef[ProviderOAuthConfig()];

coerce 'RepeatedProviderOAuthConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Developerconnect::V1::DeveloperConnect::ProviderOAuthConfig'->new($_) } @$_ ] };

declare 'MapStringProviderOAuthConfig',
    as HashRef[ProviderOAuthConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Developerconnect::V1::DeveloperConnect::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
