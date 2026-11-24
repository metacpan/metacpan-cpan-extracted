package Google::Devtools::Cloudbuild::V2::Repositories::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Connection',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::Connection'];

coerce 'Connection',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::Connection'->new($_) };

declare 'RepeatedConnection',
    as ArrayRef[Connection()];

coerce 'RepeatedConnection',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::Connection'->new($_) } @$_ ] };

declare 'MapStringConnection',
    as HashRef[Connection()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::Connection::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::Connection::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::Connection::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'InstallationState',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::InstallationState'];

coerce 'InstallationState',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::InstallationState'->new($_) };

declare 'RepeatedInstallationState',
    as ArrayRef[InstallationState()];

coerce 'RepeatedInstallationState',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::InstallationState'->new($_) } @$_ ] };

declare 'MapStringInstallationState',
    as HashRef[InstallationState()];

declare 'Stage',
    as (Int | Str);

declare 'FetchLinkableRepositoriesRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::FetchLinkableRepositoriesRequest'];

coerce 'FetchLinkableRepositoriesRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::FetchLinkableRepositoriesRequest'->new($_) };

declare 'RepeatedFetchLinkableRepositoriesRequest',
    as ArrayRef[FetchLinkableRepositoriesRequest()];

coerce 'RepeatedFetchLinkableRepositoriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::FetchLinkableRepositoriesRequest'->new($_) } @$_ ] };

declare 'MapStringFetchLinkableRepositoriesRequest',
    as HashRef[FetchLinkableRepositoriesRequest()];

declare 'FetchLinkableRepositoriesResponse',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::FetchLinkableRepositoriesResponse'];

coerce 'FetchLinkableRepositoriesResponse',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::FetchLinkableRepositoriesResponse'->new($_) };

declare 'RepeatedFetchLinkableRepositoriesResponse',
    as ArrayRef[FetchLinkableRepositoriesResponse()];

coerce 'RepeatedFetchLinkableRepositoriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::FetchLinkableRepositoriesResponse'->new($_) } @$_ ] };

declare 'MapStringFetchLinkableRepositoriesResponse',
    as HashRef[FetchLinkableRepositoriesResponse()];

declare 'GitHubConfig',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::GitHubConfig'];

coerce 'GitHubConfig',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::GitHubConfig'->new($_) };

declare 'RepeatedGitHubConfig',
    as ArrayRef[GitHubConfig()];

coerce 'RepeatedGitHubConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::GitHubConfig'->new($_) } @$_ ] };

declare 'MapStringGitHubConfig',
    as HashRef[GitHubConfig()];

declare 'GitHubEnterpriseConfig',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::GitHubEnterpriseConfig'];

coerce 'GitHubEnterpriseConfig',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::GitHubEnterpriseConfig'->new($_) };

declare 'RepeatedGitHubEnterpriseConfig',
    as ArrayRef[GitHubEnterpriseConfig()];

coerce 'RepeatedGitHubEnterpriseConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::GitHubEnterpriseConfig'->new($_) } @$_ ] };

declare 'MapStringGitHubEnterpriseConfig',
    as HashRef[GitHubEnterpriseConfig()];

declare 'GitLabConfig',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::GitLabConfig'];

coerce 'GitLabConfig',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::GitLabConfig'->new($_) };

declare 'RepeatedGitLabConfig',
    as ArrayRef[GitLabConfig()];

coerce 'RepeatedGitLabConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::GitLabConfig'->new($_) } @$_ ] };

declare 'MapStringGitLabConfig',
    as HashRef[GitLabConfig()];

declare 'BitbucketDataCenterConfig',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::BitbucketDataCenterConfig'];

coerce 'BitbucketDataCenterConfig',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::BitbucketDataCenterConfig'->new($_) };

declare 'RepeatedBitbucketDataCenterConfig',
    as ArrayRef[BitbucketDataCenterConfig()];

coerce 'RepeatedBitbucketDataCenterConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::BitbucketDataCenterConfig'->new($_) } @$_ ] };

declare 'MapStringBitbucketDataCenterConfig',
    as HashRef[BitbucketDataCenterConfig()];

declare 'BitbucketCloudConfig',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::BitbucketCloudConfig'];

coerce 'BitbucketCloudConfig',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::BitbucketCloudConfig'->new($_) };

declare 'RepeatedBitbucketCloudConfig',
    as ArrayRef[BitbucketCloudConfig()];

coerce 'RepeatedBitbucketCloudConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::BitbucketCloudConfig'->new($_) } @$_ ] };

declare 'MapStringBitbucketCloudConfig',
    as HashRef[BitbucketCloudConfig()];

declare 'ServiceDirectoryConfig',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::ServiceDirectoryConfig'];

coerce 'ServiceDirectoryConfig',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::ServiceDirectoryConfig'->new($_) };

declare 'RepeatedServiceDirectoryConfig',
    as ArrayRef[ServiceDirectoryConfig()];

coerce 'RepeatedServiceDirectoryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::ServiceDirectoryConfig'->new($_) } @$_ ] };

declare 'MapStringServiceDirectoryConfig',
    as HashRef[ServiceDirectoryConfig()];

declare 'Repository',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::Repository'];

coerce 'Repository',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::Repository'->new($_) };

declare 'RepeatedRepository',
    as ArrayRef[Repository()];

coerce 'RepeatedRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::Repository'->new($_) } @$_ ] };

declare 'MapStringRepository',
    as HashRef[Repository()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::Repository::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::Repository::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::Repository::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'OAuthCredential',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::OAuthCredential'];

coerce 'OAuthCredential',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::OAuthCredential'->new($_) };

declare 'RepeatedOAuthCredential',
    as ArrayRef[OAuthCredential()];

coerce 'RepeatedOAuthCredential',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::OAuthCredential'->new($_) } @$_ ] };

declare 'MapStringOAuthCredential',
    as HashRef[OAuthCredential()];

declare 'UserCredential',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::UserCredential'];

coerce 'UserCredential',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::UserCredential'->new($_) };

declare 'RepeatedUserCredential',
    as ArrayRef[UserCredential()];

coerce 'RepeatedUserCredential',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::UserCredential'->new($_) } @$_ ] };

declare 'MapStringUserCredential',
    as HashRef[UserCredential()];

declare 'CreateConnectionRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::CreateConnectionRequest'];

coerce 'CreateConnectionRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::CreateConnectionRequest'->new($_) };

declare 'RepeatedCreateConnectionRequest',
    as ArrayRef[CreateConnectionRequest()];

coerce 'RepeatedCreateConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::CreateConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateConnectionRequest',
    as HashRef[CreateConnectionRequest()];

declare 'GetConnectionRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::GetConnectionRequest'];

coerce 'GetConnectionRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::GetConnectionRequest'->new($_) };

declare 'RepeatedGetConnectionRequest',
    as ArrayRef[GetConnectionRequest()];

coerce 'RepeatedGetConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::GetConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringGetConnectionRequest',
    as HashRef[GetConnectionRequest()];

declare 'ListConnectionsRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::ListConnectionsRequest'];

coerce 'ListConnectionsRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::ListConnectionsRequest'->new($_) };

declare 'RepeatedListConnectionsRequest',
    as ArrayRef[ListConnectionsRequest()];

coerce 'RepeatedListConnectionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::ListConnectionsRequest'->new($_) } @$_ ] };

declare 'MapStringListConnectionsRequest',
    as HashRef[ListConnectionsRequest()];

declare 'ListConnectionsResponse',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::ListConnectionsResponse'];

coerce 'ListConnectionsResponse',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::ListConnectionsResponse'->new($_) };

declare 'RepeatedListConnectionsResponse',
    as ArrayRef[ListConnectionsResponse()];

coerce 'RepeatedListConnectionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::ListConnectionsResponse'->new($_) } @$_ ] };

declare 'MapStringListConnectionsResponse',
    as HashRef[ListConnectionsResponse()];

declare 'UpdateConnectionRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::UpdateConnectionRequest'];

coerce 'UpdateConnectionRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::UpdateConnectionRequest'->new($_) };

declare 'RepeatedUpdateConnectionRequest',
    as ArrayRef[UpdateConnectionRequest()];

coerce 'RepeatedUpdateConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::UpdateConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateConnectionRequest',
    as HashRef[UpdateConnectionRequest()];

declare 'DeleteConnectionRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::DeleteConnectionRequest'];

coerce 'DeleteConnectionRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::DeleteConnectionRequest'->new($_) };

declare 'RepeatedDeleteConnectionRequest',
    as ArrayRef[DeleteConnectionRequest()];

coerce 'RepeatedDeleteConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::DeleteConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteConnectionRequest',
    as HashRef[DeleteConnectionRequest()];

declare 'CreateRepositoryRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::CreateRepositoryRequest'];

coerce 'CreateRepositoryRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::CreateRepositoryRequest'->new($_) };

declare 'RepeatedCreateRepositoryRequest',
    as ArrayRef[CreateRepositoryRequest()];

coerce 'RepeatedCreateRepositoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::CreateRepositoryRequest'->new($_) } @$_ ] };

declare 'MapStringCreateRepositoryRequest',
    as HashRef[CreateRepositoryRequest()];

declare 'BatchCreateRepositoriesRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::BatchCreateRepositoriesRequest'];

coerce 'BatchCreateRepositoriesRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::BatchCreateRepositoriesRequest'->new($_) };

declare 'RepeatedBatchCreateRepositoriesRequest',
    as ArrayRef[BatchCreateRepositoriesRequest()];

coerce 'RepeatedBatchCreateRepositoriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::BatchCreateRepositoriesRequest'->new($_) } @$_ ] };

declare 'MapStringBatchCreateRepositoriesRequest',
    as HashRef[BatchCreateRepositoriesRequest()];

declare 'BatchCreateRepositoriesResponse',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::BatchCreateRepositoriesResponse'];

coerce 'BatchCreateRepositoriesResponse',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::BatchCreateRepositoriesResponse'->new($_) };

declare 'RepeatedBatchCreateRepositoriesResponse',
    as ArrayRef[BatchCreateRepositoriesResponse()];

coerce 'RepeatedBatchCreateRepositoriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::BatchCreateRepositoriesResponse'->new($_) } @$_ ] };

declare 'MapStringBatchCreateRepositoriesResponse',
    as HashRef[BatchCreateRepositoriesResponse()];

declare 'GetRepositoryRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::GetRepositoryRequest'];

coerce 'GetRepositoryRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::GetRepositoryRequest'->new($_) };

declare 'RepeatedGetRepositoryRequest',
    as ArrayRef[GetRepositoryRequest()];

coerce 'RepeatedGetRepositoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::GetRepositoryRequest'->new($_) } @$_ ] };

declare 'MapStringGetRepositoryRequest',
    as HashRef[GetRepositoryRequest()];

declare 'ListRepositoriesRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::ListRepositoriesRequest'];

coerce 'ListRepositoriesRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::ListRepositoriesRequest'->new($_) };

declare 'RepeatedListRepositoriesRequest',
    as ArrayRef[ListRepositoriesRequest()];

coerce 'RepeatedListRepositoriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::ListRepositoriesRequest'->new($_) } @$_ ] };

declare 'MapStringListRepositoriesRequest',
    as HashRef[ListRepositoriesRequest()];

declare 'ListRepositoriesResponse',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::ListRepositoriesResponse'];

coerce 'ListRepositoriesResponse',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::ListRepositoriesResponse'->new($_) };

declare 'RepeatedListRepositoriesResponse',
    as ArrayRef[ListRepositoriesResponse()];

coerce 'RepeatedListRepositoriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::ListRepositoriesResponse'->new($_) } @$_ ] };

declare 'MapStringListRepositoriesResponse',
    as HashRef[ListRepositoriesResponse()];

declare 'DeleteRepositoryRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::DeleteRepositoryRequest'];

coerce 'DeleteRepositoryRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::DeleteRepositoryRequest'->new($_) };

declare 'RepeatedDeleteRepositoryRequest',
    as ArrayRef[DeleteRepositoryRequest()];

coerce 'RepeatedDeleteRepositoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::DeleteRepositoryRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteRepositoryRequest',
    as HashRef[DeleteRepositoryRequest()];

declare 'FetchReadWriteTokenRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::FetchReadWriteTokenRequest'];

coerce 'FetchReadWriteTokenRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::FetchReadWriteTokenRequest'->new($_) };

declare 'RepeatedFetchReadWriteTokenRequest',
    as ArrayRef[FetchReadWriteTokenRequest()];

coerce 'RepeatedFetchReadWriteTokenRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::FetchReadWriteTokenRequest'->new($_) } @$_ ] };

declare 'MapStringFetchReadWriteTokenRequest',
    as HashRef[FetchReadWriteTokenRequest()];

declare 'FetchReadTokenRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::FetchReadTokenRequest'];

coerce 'FetchReadTokenRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::FetchReadTokenRequest'->new($_) };

declare 'RepeatedFetchReadTokenRequest',
    as ArrayRef[FetchReadTokenRequest()];

coerce 'RepeatedFetchReadTokenRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::FetchReadTokenRequest'->new($_) } @$_ ] };

declare 'MapStringFetchReadTokenRequest',
    as HashRef[FetchReadTokenRequest()];

declare 'FetchReadTokenResponse',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::FetchReadTokenResponse'];

coerce 'FetchReadTokenResponse',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::FetchReadTokenResponse'->new($_) };

declare 'RepeatedFetchReadTokenResponse',
    as ArrayRef[FetchReadTokenResponse()];

coerce 'RepeatedFetchReadTokenResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::FetchReadTokenResponse'->new($_) } @$_ ] };

declare 'MapStringFetchReadTokenResponse',
    as HashRef[FetchReadTokenResponse()];

declare 'FetchReadWriteTokenResponse',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::FetchReadWriteTokenResponse'];

coerce 'FetchReadWriteTokenResponse',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::FetchReadWriteTokenResponse'->new($_) };

declare 'RepeatedFetchReadWriteTokenResponse',
    as ArrayRef[FetchReadWriteTokenResponse()];

coerce 'RepeatedFetchReadWriteTokenResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::FetchReadWriteTokenResponse'->new($_) } @$_ ] };

declare 'MapStringFetchReadWriteTokenResponse',
    as HashRef[FetchReadWriteTokenResponse()];

declare 'ProcessWebhookRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::ProcessWebhookRequest'];

coerce 'ProcessWebhookRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::ProcessWebhookRequest'->new($_) };

declare 'RepeatedProcessWebhookRequest',
    as ArrayRef[ProcessWebhookRequest()];

coerce 'RepeatedProcessWebhookRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::ProcessWebhookRequest'->new($_) } @$_ ] };

declare 'MapStringProcessWebhookRequest',
    as HashRef[ProcessWebhookRequest()];

declare 'FetchGitRefsRequest',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::FetchGitRefsRequest'];

coerce 'FetchGitRefsRequest',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::FetchGitRefsRequest'->new($_) };

declare 'RepeatedFetchGitRefsRequest',
    as ArrayRef[FetchGitRefsRequest()];

coerce 'RepeatedFetchGitRefsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::FetchGitRefsRequest'->new($_) } @$_ ] };

declare 'MapStringFetchGitRefsRequest',
    as HashRef[FetchGitRefsRequest()];

declare 'RefType',
    as (Int | Str);

declare 'FetchGitRefsResponse',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Repositories::FetchGitRefsResponse'];

coerce 'FetchGitRefsResponse',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Repositories::FetchGitRefsResponse'->new($_) };

declare 'RepeatedFetchGitRefsResponse',
    as ArrayRef[FetchGitRefsResponse()];

coerce 'RepeatedFetchGitRefsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Repositories::FetchGitRefsResponse'->new($_) } @$_ ] };

declare 'MapStringFetchGitRefsResponse',
    as HashRef[FetchGitRefsResponse()];

1;

__END__

=head1 NAME

Google::Devtools::Cloudbuild::V2::Repositories::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
