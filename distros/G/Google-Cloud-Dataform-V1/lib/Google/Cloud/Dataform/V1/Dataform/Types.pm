package Google::Cloud::Dataform::V1::Dataform::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DirectoryContentsView',
    as (Int | Str);

declare 'DataEncryptionState',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::DataEncryptionState'];

coerce 'DataEncryptionState',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::DataEncryptionState'->new($_) };

declare 'RepeatedDataEncryptionState',
    as ArrayRef[DataEncryptionState()];

coerce 'RepeatedDataEncryptionState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::DataEncryptionState'->new($_) } @$_ ] };

declare 'MapStringDataEncryptionState',
    as HashRef[DataEncryptionState()];

declare 'Repository',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::Repository'];

coerce 'Repository',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::Repository'->new($_) };

declare 'RepeatedRepository',
    as ArrayRef[Repository()];

coerce 'RepeatedRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::Repository'->new($_) } @$_ ] };

declare 'MapStringRepository',
    as HashRef[Repository()];

declare 'GitRemoteSettings',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::Repository::GitRemoteSettings'];

coerce 'GitRemoteSettings',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::Repository::GitRemoteSettings'->new($_) };

declare 'RepeatedGitRemoteSettings',
    as ArrayRef[GitRemoteSettings()];

coerce 'RepeatedGitRemoteSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::Repository::GitRemoteSettings'->new($_) } @$_ ] };

declare 'MapStringGitRemoteSettings',
    as HashRef[GitRemoteSettings()];

declare 'TokenStatus',
    as (Int | Str);

declare 'SshAuthenticationConfig',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::Repository::GitRemoteSettings::SshAuthenticationConfig'];

coerce 'SshAuthenticationConfig',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::Repository::GitRemoteSettings::SshAuthenticationConfig'->new($_) };

declare 'RepeatedSshAuthenticationConfig',
    as ArrayRef[SshAuthenticationConfig()];

coerce 'RepeatedSshAuthenticationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::Repository::GitRemoteSettings::SshAuthenticationConfig'->new($_) } @$_ ] };

declare 'MapStringSshAuthenticationConfig',
    as HashRef[SshAuthenticationConfig()];

declare 'WorkspaceCompilationOverrides',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::Repository::WorkspaceCompilationOverrides'];

coerce 'WorkspaceCompilationOverrides',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::Repository::WorkspaceCompilationOverrides'->new($_) };

declare 'RepeatedWorkspaceCompilationOverrides',
    as ArrayRef[WorkspaceCompilationOverrides()];

coerce 'RepeatedWorkspaceCompilationOverrides',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::Repository::WorkspaceCompilationOverrides'->new($_) } @$_ ] };

declare 'MapStringWorkspaceCompilationOverrides',
    as HashRef[WorkspaceCompilationOverrides()];

declare 'EndUserAuthConfig',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::Repository::EndUserAuthConfig'];

coerce 'EndUserAuthConfig',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::Repository::EndUserAuthConfig'->new($_) };

declare 'RepeatedEndUserAuthConfig',
    as ArrayRef[EndUserAuthConfig()];

coerce 'RepeatedEndUserAuthConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::Repository::EndUserAuthConfig'->new($_) } @$_ ] };

declare 'MapStringEndUserAuthConfig',
    as HashRef[EndUserAuthConfig()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::Repository::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::Repository::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::Repository::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'OAuthConfig',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::OAuthConfig'];

coerce 'OAuthConfig',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::OAuthConfig'->new($_) };

declare 'RepeatedOAuthConfig',
    as ArrayRef[OAuthConfig()];

coerce 'RepeatedOAuthConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::OAuthConfig'->new($_) } @$_ ] };

declare 'MapStringOAuthConfig',
    as HashRef[OAuthConfig()];

declare 'PrivateResourceMetadata',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::PrivateResourceMetadata'];

coerce 'PrivateResourceMetadata',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::PrivateResourceMetadata'->new($_) };

declare 'RepeatedPrivateResourceMetadata',
    as ArrayRef[PrivateResourceMetadata()];

coerce 'RepeatedPrivateResourceMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::PrivateResourceMetadata'->new($_) } @$_ ] };

declare 'MapStringPrivateResourceMetadata',
    as HashRef[PrivateResourceMetadata()];

declare 'ListRepositoriesRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::ListRepositoriesRequest'];

coerce 'ListRepositoriesRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::ListRepositoriesRequest'->new($_) };

declare 'RepeatedListRepositoriesRequest',
    as ArrayRef[ListRepositoriesRequest()];

coerce 'RepeatedListRepositoriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::ListRepositoriesRequest'->new($_) } @$_ ] };

declare 'MapStringListRepositoriesRequest',
    as HashRef[ListRepositoriesRequest()];

declare 'ListRepositoriesResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::ListRepositoriesResponse'];

coerce 'ListRepositoriesResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::ListRepositoriesResponse'->new($_) };

declare 'RepeatedListRepositoriesResponse',
    as ArrayRef[ListRepositoriesResponse()];

coerce 'RepeatedListRepositoriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::ListRepositoriesResponse'->new($_) } @$_ ] };

declare 'MapStringListRepositoriesResponse',
    as HashRef[ListRepositoriesResponse()];

declare 'MoveRepositoryRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::MoveRepositoryRequest'];

coerce 'MoveRepositoryRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::MoveRepositoryRequest'->new($_) };

declare 'RepeatedMoveRepositoryRequest',
    as ArrayRef[MoveRepositoryRequest()];

coerce 'RepeatedMoveRepositoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::MoveRepositoryRequest'->new($_) } @$_ ] };

declare 'MapStringMoveRepositoryRequest',
    as HashRef[MoveRepositoryRequest()];

declare 'GetRepositoryRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::GetRepositoryRequest'];

coerce 'GetRepositoryRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::GetRepositoryRequest'->new($_) };

declare 'RepeatedGetRepositoryRequest',
    as ArrayRef[GetRepositoryRequest()];

coerce 'RepeatedGetRepositoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::GetRepositoryRequest'->new($_) } @$_ ] };

declare 'MapStringGetRepositoryRequest',
    as HashRef[GetRepositoryRequest()];

declare 'CreateRepositoryRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CreateRepositoryRequest'];

coerce 'CreateRepositoryRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CreateRepositoryRequest'->new($_) };

declare 'RepeatedCreateRepositoryRequest',
    as ArrayRef[CreateRepositoryRequest()];

coerce 'RepeatedCreateRepositoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CreateRepositoryRequest'->new($_) } @$_ ] };

declare 'MapStringCreateRepositoryRequest',
    as HashRef[CreateRepositoryRequest()];

declare 'UpdateRepositoryRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::UpdateRepositoryRequest'];

coerce 'UpdateRepositoryRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::UpdateRepositoryRequest'->new($_) };

declare 'RepeatedUpdateRepositoryRequest',
    as ArrayRef[UpdateRepositoryRequest()];

coerce 'RepeatedUpdateRepositoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::UpdateRepositoryRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateRepositoryRequest',
    as HashRef[UpdateRepositoryRequest()];

declare 'DeleteRepositoryRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::DeleteRepositoryRequest'];

coerce 'DeleteRepositoryRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::DeleteRepositoryRequest'->new($_) };

declare 'RepeatedDeleteRepositoryRequest',
    as ArrayRef[DeleteRepositoryRequest()];

coerce 'RepeatedDeleteRepositoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::DeleteRepositoryRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteRepositoryRequest',
    as HashRef[DeleteRepositoryRequest()];

declare 'CommitRepositoryChangesRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CommitRepositoryChangesRequest'];

coerce 'CommitRepositoryChangesRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CommitRepositoryChangesRequest'->new($_) };

declare 'RepeatedCommitRepositoryChangesRequest',
    as ArrayRef[CommitRepositoryChangesRequest()];

coerce 'RepeatedCommitRepositoryChangesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CommitRepositoryChangesRequest'->new($_) } @$_ ] };

declare 'MapStringCommitRepositoryChangesRequest',
    as HashRef[CommitRepositoryChangesRequest()];

declare 'FileOperation',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CommitRepositoryChangesRequest::FileOperation'];

coerce 'FileOperation',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CommitRepositoryChangesRequest::FileOperation'->new($_) };

declare 'RepeatedFileOperation',
    as ArrayRef[FileOperation()];

coerce 'RepeatedFileOperation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CommitRepositoryChangesRequest::FileOperation'->new($_) } @$_ ] };

declare 'MapStringFileOperation',
    as HashRef[FileOperation()];

declare 'WriteFile',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CommitRepositoryChangesRequest::FileOperation::WriteFile'];

coerce 'WriteFile',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CommitRepositoryChangesRequest::FileOperation::WriteFile'->new($_) };

declare 'RepeatedWriteFile',
    as ArrayRef[WriteFile()];

coerce 'RepeatedWriteFile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CommitRepositoryChangesRequest::FileOperation::WriteFile'->new($_) } @$_ ] };

declare 'MapStringWriteFile',
    as HashRef[WriteFile()];

declare 'DeleteFile',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CommitRepositoryChangesRequest::FileOperation::DeleteFile'];

coerce 'DeleteFile',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CommitRepositoryChangesRequest::FileOperation::DeleteFile'->new($_) };

declare 'RepeatedDeleteFile',
    as ArrayRef[DeleteFile()];

coerce 'RepeatedDeleteFile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CommitRepositoryChangesRequest::FileOperation::DeleteFile'->new($_) } @$_ ] };

declare 'MapStringDeleteFile',
    as HashRef[DeleteFile()];

declare 'FileOperationsEntry',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CommitRepositoryChangesRequest::FileOperationsEntry'];

coerce 'FileOperationsEntry',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CommitRepositoryChangesRequest::FileOperationsEntry'->new($_) };

declare 'RepeatedFileOperationsEntry',
    as ArrayRef[FileOperationsEntry()];

coerce 'RepeatedFileOperationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CommitRepositoryChangesRequest::FileOperationsEntry'->new($_) } @$_ ] };

declare 'MapStringFileOperationsEntry',
    as HashRef[FileOperationsEntry()];

declare 'CommitRepositoryChangesResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CommitRepositoryChangesResponse'];

coerce 'CommitRepositoryChangesResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CommitRepositoryChangesResponse'->new($_) };

declare 'RepeatedCommitRepositoryChangesResponse',
    as ArrayRef[CommitRepositoryChangesResponse()];

coerce 'RepeatedCommitRepositoryChangesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CommitRepositoryChangesResponse'->new($_) } @$_ ] };

declare 'MapStringCommitRepositoryChangesResponse',
    as HashRef[CommitRepositoryChangesResponse()];

declare 'ReadRepositoryFileRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::ReadRepositoryFileRequest'];

coerce 'ReadRepositoryFileRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::ReadRepositoryFileRequest'->new($_) };

declare 'RepeatedReadRepositoryFileRequest',
    as ArrayRef[ReadRepositoryFileRequest()];

coerce 'RepeatedReadRepositoryFileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::ReadRepositoryFileRequest'->new($_) } @$_ ] };

declare 'MapStringReadRepositoryFileRequest',
    as HashRef[ReadRepositoryFileRequest()];

declare 'ReadRepositoryFileResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::ReadRepositoryFileResponse'];

coerce 'ReadRepositoryFileResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::ReadRepositoryFileResponse'->new($_) };

declare 'RepeatedReadRepositoryFileResponse',
    as ArrayRef[ReadRepositoryFileResponse()];

coerce 'RepeatedReadRepositoryFileResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::ReadRepositoryFileResponse'->new($_) } @$_ ] };

declare 'MapStringReadRepositoryFileResponse',
    as HashRef[ReadRepositoryFileResponse()];

declare 'QueryRepositoryDirectoryContentsRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::QueryRepositoryDirectoryContentsRequest'];

coerce 'QueryRepositoryDirectoryContentsRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::QueryRepositoryDirectoryContentsRequest'->new($_) };

declare 'RepeatedQueryRepositoryDirectoryContentsRequest',
    as ArrayRef[QueryRepositoryDirectoryContentsRequest()];

coerce 'RepeatedQueryRepositoryDirectoryContentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::QueryRepositoryDirectoryContentsRequest'->new($_) } @$_ ] };

declare 'MapStringQueryRepositoryDirectoryContentsRequest',
    as HashRef[QueryRepositoryDirectoryContentsRequest()];

declare 'QueryRepositoryDirectoryContentsResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::QueryRepositoryDirectoryContentsResponse'];

coerce 'QueryRepositoryDirectoryContentsResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::QueryRepositoryDirectoryContentsResponse'->new($_) };

declare 'RepeatedQueryRepositoryDirectoryContentsResponse',
    as ArrayRef[QueryRepositoryDirectoryContentsResponse()];

coerce 'RepeatedQueryRepositoryDirectoryContentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::QueryRepositoryDirectoryContentsResponse'->new($_) } @$_ ] };

declare 'MapStringQueryRepositoryDirectoryContentsResponse',
    as HashRef[QueryRepositoryDirectoryContentsResponse()];

declare 'FetchRepositoryHistoryRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::FetchRepositoryHistoryRequest'];

coerce 'FetchRepositoryHistoryRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::FetchRepositoryHistoryRequest'->new($_) };

declare 'RepeatedFetchRepositoryHistoryRequest',
    as ArrayRef[FetchRepositoryHistoryRequest()];

coerce 'RepeatedFetchRepositoryHistoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::FetchRepositoryHistoryRequest'->new($_) } @$_ ] };

declare 'MapStringFetchRepositoryHistoryRequest',
    as HashRef[FetchRepositoryHistoryRequest()];

declare 'FetchRepositoryHistoryResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::FetchRepositoryHistoryResponse'];

coerce 'FetchRepositoryHistoryResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::FetchRepositoryHistoryResponse'->new($_) };

declare 'RepeatedFetchRepositoryHistoryResponse',
    as ArrayRef[FetchRepositoryHistoryResponse()];

coerce 'RepeatedFetchRepositoryHistoryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::FetchRepositoryHistoryResponse'->new($_) } @$_ ] };

declare 'MapStringFetchRepositoryHistoryResponse',
    as HashRef[FetchRepositoryHistoryResponse()];

declare 'CommitLogEntry',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CommitLogEntry'];

coerce 'CommitLogEntry',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CommitLogEntry'->new($_) };

declare 'RepeatedCommitLogEntry',
    as ArrayRef[CommitLogEntry()];

coerce 'RepeatedCommitLogEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CommitLogEntry'->new($_) } @$_ ] };

declare 'MapStringCommitLogEntry',
    as HashRef[CommitLogEntry()];

declare 'CommitMetadata',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CommitMetadata'];

coerce 'CommitMetadata',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CommitMetadata'->new($_) };

declare 'RepeatedCommitMetadata',
    as ArrayRef[CommitMetadata()];

coerce 'RepeatedCommitMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CommitMetadata'->new($_) } @$_ ] };

declare 'MapStringCommitMetadata',
    as HashRef[CommitMetadata()];

declare 'ComputeRepositoryAccessTokenStatusRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::ComputeRepositoryAccessTokenStatusRequest'];

coerce 'ComputeRepositoryAccessTokenStatusRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::ComputeRepositoryAccessTokenStatusRequest'->new($_) };

declare 'RepeatedComputeRepositoryAccessTokenStatusRequest',
    as ArrayRef[ComputeRepositoryAccessTokenStatusRequest()];

coerce 'RepeatedComputeRepositoryAccessTokenStatusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::ComputeRepositoryAccessTokenStatusRequest'->new($_) } @$_ ] };

declare 'MapStringComputeRepositoryAccessTokenStatusRequest',
    as HashRef[ComputeRepositoryAccessTokenStatusRequest()];

declare 'ComputeRepositoryAccessTokenStatusResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::ComputeRepositoryAccessTokenStatusResponse'];

coerce 'ComputeRepositoryAccessTokenStatusResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::ComputeRepositoryAccessTokenStatusResponse'->new($_) };

declare 'RepeatedComputeRepositoryAccessTokenStatusResponse',
    as ArrayRef[ComputeRepositoryAccessTokenStatusResponse()];

coerce 'RepeatedComputeRepositoryAccessTokenStatusResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::ComputeRepositoryAccessTokenStatusResponse'->new($_) } @$_ ] };

declare 'MapStringComputeRepositoryAccessTokenStatusResponse',
    as HashRef[ComputeRepositoryAccessTokenStatusResponse()];

declare 'TokenStatus',
    as (Int | Str);

declare 'FetchRemoteBranchesRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::FetchRemoteBranchesRequest'];

coerce 'FetchRemoteBranchesRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::FetchRemoteBranchesRequest'->new($_) };

declare 'RepeatedFetchRemoteBranchesRequest',
    as ArrayRef[FetchRemoteBranchesRequest()];

coerce 'RepeatedFetchRemoteBranchesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::FetchRemoteBranchesRequest'->new($_) } @$_ ] };

declare 'MapStringFetchRemoteBranchesRequest',
    as HashRef[FetchRemoteBranchesRequest()];

declare 'FetchRemoteBranchesResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::FetchRemoteBranchesResponse'];

coerce 'FetchRemoteBranchesResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::FetchRemoteBranchesResponse'->new($_) };

declare 'RepeatedFetchRemoteBranchesResponse',
    as ArrayRef[FetchRemoteBranchesResponse()];

coerce 'RepeatedFetchRemoteBranchesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::FetchRemoteBranchesResponse'->new($_) } @$_ ] };

declare 'MapStringFetchRemoteBranchesResponse',
    as HashRef[FetchRemoteBranchesResponse()];

declare 'Workspace',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::Workspace'];

coerce 'Workspace',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::Workspace'->new($_) };

declare 'RepeatedWorkspace',
    as ArrayRef[Workspace()];

coerce 'RepeatedWorkspace',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::Workspace'->new($_) } @$_ ] };

declare 'MapStringWorkspace',
    as HashRef[Workspace()];

declare 'ListWorkspacesRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::ListWorkspacesRequest'];

coerce 'ListWorkspacesRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::ListWorkspacesRequest'->new($_) };

declare 'RepeatedListWorkspacesRequest',
    as ArrayRef[ListWorkspacesRequest()];

coerce 'RepeatedListWorkspacesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::ListWorkspacesRequest'->new($_) } @$_ ] };

declare 'MapStringListWorkspacesRequest',
    as HashRef[ListWorkspacesRequest()];

declare 'ListWorkspacesResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::ListWorkspacesResponse'];

coerce 'ListWorkspacesResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::ListWorkspacesResponse'->new($_) };

declare 'RepeatedListWorkspacesResponse',
    as ArrayRef[ListWorkspacesResponse()];

coerce 'RepeatedListWorkspacesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::ListWorkspacesResponse'->new($_) } @$_ ] };

declare 'MapStringListWorkspacesResponse',
    as HashRef[ListWorkspacesResponse()];

declare 'GetWorkspaceRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::GetWorkspaceRequest'];

coerce 'GetWorkspaceRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::GetWorkspaceRequest'->new($_) };

declare 'RepeatedGetWorkspaceRequest',
    as ArrayRef[GetWorkspaceRequest()];

coerce 'RepeatedGetWorkspaceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::GetWorkspaceRequest'->new($_) } @$_ ] };

declare 'MapStringGetWorkspaceRequest',
    as HashRef[GetWorkspaceRequest()];

declare 'CreateWorkspaceRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CreateWorkspaceRequest'];

coerce 'CreateWorkspaceRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CreateWorkspaceRequest'->new($_) };

declare 'RepeatedCreateWorkspaceRequest',
    as ArrayRef[CreateWorkspaceRequest()];

coerce 'RepeatedCreateWorkspaceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CreateWorkspaceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateWorkspaceRequest',
    as HashRef[CreateWorkspaceRequest()];

declare 'CreateWorkspaceMetadata',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CreateWorkspaceMetadata'];

coerce 'CreateWorkspaceMetadata',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CreateWorkspaceMetadata'->new($_) };

declare 'RepeatedCreateWorkspaceMetadata',
    as ArrayRef[CreateWorkspaceMetadata()];

coerce 'RepeatedCreateWorkspaceMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CreateWorkspaceMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateWorkspaceMetadata',
    as HashRef[CreateWorkspaceMetadata()];

declare 'State',
    as (Int | Str);

declare 'DeleteWorkspaceRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::DeleteWorkspaceRequest'];

coerce 'DeleteWorkspaceRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::DeleteWorkspaceRequest'->new($_) };

declare 'RepeatedDeleteWorkspaceRequest',
    as ArrayRef[DeleteWorkspaceRequest()];

coerce 'RepeatedDeleteWorkspaceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::DeleteWorkspaceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteWorkspaceRequest',
    as HashRef[DeleteWorkspaceRequest()];

declare 'CommitAuthor',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CommitAuthor'];

coerce 'CommitAuthor',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CommitAuthor'->new($_) };

declare 'RepeatedCommitAuthor',
    as ArrayRef[CommitAuthor()];

coerce 'RepeatedCommitAuthor',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CommitAuthor'->new($_) } @$_ ] };

declare 'MapStringCommitAuthor',
    as HashRef[CommitAuthor()];

declare 'PullGitCommitsRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::PullGitCommitsRequest'];

coerce 'PullGitCommitsRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::PullGitCommitsRequest'->new($_) };

declare 'RepeatedPullGitCommitsRequest',
    as ArrayRef[PullGitCommitsRequest()];

coerce 'RepeatedPullGitCommitsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::PullGitCommitsRequest'->new($_) } @$_ ] };

declare 'MapStringPullGitCommitsRequest',
    as HashRef[PullGitCommitsRequest()];

declare 'PullGitCommitsResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::PullGitCommitsResponse'];

coerce 'PullGitCommitsResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::PullGitCommitsResponse'->new($_) };

declare 'RepeatedPullGitCommitsResponse',
    as ArrayRef[PullGitCommitsResponse()];

coerce 'RepeatedPullGitCommitsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::PullGitCommitsResponse'->new($_) } @$_ ] };

declare 'MapStringPullGitCommitsResponse',
    as HashRef[PullGitCommitsResponse()];

declare 'PushGitCommitsRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::PushGitCommitsRequest'];

coerce 'PushGitCommitsRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::PushGitCommitsRequest'->new($_) };

declare 'RepeatedPushGitCommitsRequest',
    as ArrayRef[PushGitCommitsRequest()];

coerce 'RepeatedPushGitCommitsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::PushGitCommitsRequest'->new($_) } @$_ ] };

declare 'MapStringPushGitCommitsRequest',
    as HashRef[PushGitCommitsRequest()];

declare 'PushGitCommitsResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::PushGitCommitsResponse'];

coerce 'PushGitCommitsResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::PushGitCommitsResponse'->new($_) };

declare 'RepeatedPushGitCommitsResponse',
    as ArrayRef[PushGitCommitsResponse()];

coerce 'RepeatedPushGitCommitsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::PushGitCommitsResponse'->new($_) } @$_ ] };

declare 'MapStringPushGitCommitsResponse',
    as HashRef[PushGitCommitsResponse()];

declare 'FetchFileGitStatusesRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::FetchFileGitStatusesRequest'];

coerce 'FetchFileGitStatusesRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::FetchFileGitStatusesRequest'->new($_) };

declare 'RepeatedFetchFileGitStatusesRequest',
    as ArrayRef[FetchFileGitStatusesRequest()];

coerce 'RepeatedFetchFileGitStatusesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::FetchFileGitStatusesRequest'->new($_) } @$_ ] };

declare 'MapStringFetchFileGitStatusesRequest',
    as HashRef[FetchFileGitStatusesRequest()];

declare 'FetchFileGitStatusesResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::FetchFileGitStatusesResponse'];

coerce 'FetchFileGitStatusesResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::FetchFileGitStatusesResponse'->new($_) };

declare 'RepeatedFetchFileGitStatusesResponse',
    as ArrayRef[FetchFileGitStatusesResponse()];

coerce 'RepeatedFetchFileGitStatusesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::FetchFileGitStatusesResponse'->new($_) } @$_ ] };

declare 'MapStringFetchFileGitStatusesResponse',
    as HashRef[FetchFileGitStatusesResponse()];

declare 'UncommittedFileChange',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::FetchFileGitStatusesResponse::UncommittedFileChange'];

coerce 'UncommittedFileChange',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::FetchFileGitStatusesResponse::UncommittedFileChange'->new($_) };

declare 'RepeatedUncommittedFileChange',
    as ArrayRef[UncommittedFileChange()];

coerce 'RepeatedUncommittedFileChange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::FetchFileGitStatusesResponse::UncommittedFileChange'->new($_) } @$_ ] };

declare 'MapStringUncommittedFileChange',
    as HashRef[UncommittedFileChange()];

declare 'State',
    as (Int | Str);

declare 'FetchGitAheadBehindRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::FetchGitAheadBehindRequest'];

coerce 'FetchGitAheadBehindRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::FetchGitAheadBehindRequest'->new($_) };

declare 'RepeatedFetchGitAheadBehindRequest',
    as ArrayRef[FetchGitAheadBehindRequest()];

coerce 'RepeatedFetchGitAheadBehindRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::FetchGitAheadBehindRequest'->new($_) } @$_ ] };

declare 'MapStringFetchGitAheadBehindRequest',
    as HashRef[FetchGitAheadBehindRequest()];

declare 'FetchGitAheadBehindResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::FetchGitAheadBehindResponse'];

coerce 'FetchGitAheadBehindResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::FetchGitAheadBehindResponse'->new($_) };

declare 'RepeatedFetchGitAheadBehindResponse',
    as ArrayRef[FetchGitAheadBehindResponse()];

coerce 'RepeatedFetchGitAheadBehindResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::FetchGitAheadBehindResponse'->new($_) } @$_ ] };

declare 'MapStringFetchGitAheadBehindResponse',
    as HashRef[FetchGitAheadBehindResponse()];

declare 'CommitWorkspaceChangesRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CommitWorkspaceChangesRequest'];

coerce 'CommitWorkspaceChangesRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CommitWorkspaceChangesRequest'->new($_) };

declare 'RepeatedCommitWorkspaceChangesRequest',
    as ArrayRef[CommitWorkspaceChangesRequest()];

coerce 'RepeatedCommitWorkspaceChangesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CommitWorkspaceChangesRequest'->new($_) } @$_ ] };

declare 'MapStringCommitWorkspaceChangesRequest',
    as HashRef[CommitWorkspaceChangesRequest()];

declare 'CommitWorkspaceChangesResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CommitWorkspaceChangesResponse'];

coerce 'CommitWorkspaceChangesResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CommitWorkspaceChangesResponse'->new($_) };

declare 'RepeatedCommitWorkspaceChangesResponse',
    as ArrayRef[CommitWorkspaceChangesResponse()];

coerce 'RepeatedCommitWorkspaceChangesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CommitWorkspaceChangesResponse'->new($_) } @$_ ] };

declare 'MapStringCommitWorkspaceChangesResponse',
    as HashRef[CommitWorkspaceChangesResponse()];

declare 'ResetWorkspaceChangesRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::ResetWorkspaceChangesRequest'];

coerce 'ResetWorkspaceChangesRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::ResetWorkspaceChangesRequest'->new($_) };

declare 'RepeatedResetWorkspaceChangesRequest',
    as ArrayRef[ResetWorkspaceChangesRequest()];

coerce 'RepeatedResetWorkspaceChangesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::ResetWorkspaceChangesRequest'->new($_) } @$_ ] };

declare 'MapStringResetWorkspaceChangesRequest',
    as HashRef[ResetWorkspaceChangesRequest()];

declare 'ResetWorkspaceChangesResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::ResetWorkspaceChangesResponse'];

coerce 'ResetWorkspaceChangesResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::ResetWorkspaceChangesResponse'->new($_) };

declare 'RepeatedResetWorkspaceChangesResponse',
    as ArrayRef[ResetWorkspaceChangesResponse()];

coerce 'RepeatedResetWorkspaceChangesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::ResetWorkspaceChangesResponse'->new($_) } @$_ ] };

declare 'MapStringResetWorkspaceChangesResponse',
    as HashRef[ResetWorkspaceChangesResponse()];

declare 'FetchFileDiffRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::FetchFileDiffRequest'];

coerce 'FetchFileDiffRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::FetchFileDiffRequest'->new($_) };

declare 'RepeatedFetchFileDiffRequest',
    as ArrayRef[FetchFileDiffRequest()];

coerce 'RepeatedFetchFileDiffRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::FetchFileDiffRequest'->new($_) } @$_ ] };

declare 'MapStringFetchFileDiffRequest',
    as HashRef[FetchFileDiffRequest()];

declare 'FetchFileDiffResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::FetchFileDiffResponse'];

coerce 'FetchFileDiffResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::FetchFileDiffResponse'->new($_) };

declare 'RepeatedFetchFileDiffResponse',
    as ArrayRef[FetchFileDiffResponse()];

coerce 'RepeatedFetchFileDiffResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::FetchFileDiffResponse'->new($_) } @$_ ] };

declare 'MapStringFetchFileDiffResponse',
    as HashRef[FetchFileDiffResponse()];

declare 'QueryDirectoryContentsRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::QueryDirectoryContentsRequest'];

coerce 'QueryDirectoryContentsRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::QueryDirectoryContentsRequest'->new($_) };

declare 'RepeatedQueryDirectoryContentsRequest',
    as ArrayRef[QueryDirectoryContentsRequest()];

coerce 'RepeatedQueryDirectoryContentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::QueryDirectoryContentsRequest'->new($_) } @$_ ] };

declare 'MapStringQueryDirectoryContentsRequest',
    as HashRef[QueryDirectoryContentsRequest()];

declare 'QueryDirectoryContentsResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::QueryDirectoryContentsResponse'];

coerce 'QueryDirectoryContentsResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::QueryDirectoryContentsResponse'->new($_) };

declare 'RepeatedQueryDirectoryContentsResponse',
    as ArrayRef[QueryDirectoryContentsResponse()];

coerce 'RepeatedQueryDirectoryContentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::QueryDirectoryContentsResponse'->new($_) } @$_ ] };

declare 'MapStringQueryDirectoryContentsResponse',
    as HashRef[QueryDirectoryContentsResponse()];

declare 'DirectoryEntry',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::DirectoryEntry'];

coerce 'DirectoryEntry',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::DirectoryEntry'->new($_) };

declare 'RepeatedDirectoryEntry',
    as ArrayRef[DirectoryEntry()];

coerce 'RepeatedDirectoryEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::DirectoryEntry'->new($_) } @$_ ] };

declare 'MapStringDirectoryEntry',
    as HashRef[DirectoryEntry()];

declare 'FilesystemEntryMetadata',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::FilesystemEntryMetadata'];

coerce 'FilesystemEntryMetadata',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::FilesystemEntryMetadata'->new($_) };

declare 'RepeatedFilesystemEntryMetadata',
    as ArrayRef[FilesystemEntryMetadata()];

coerce 'RepeatedFilesystemEntryMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::FilesystemEntryMetadata'->new($_) } @$_ ] };

declare 'MapStringFilesystemEntryMetadata',
    as HashRef[FilesystemEntryMetadata()];

declare 'SearchFilesRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::SearchFilesRequest'];

coerce 'SearchFilesRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::SearchFilesRequest'->new($_) };

declare 'RepeatedSearchFilesRequest',
    as ArrayRef[SearchFilesRequest()];

coerce 'RepeatedSearchFilesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::SearchFilesRequest'->new($_) } @$_ ] };

declare 'MapStringSearchFilesRequest',
    as HashRef[SearchFilesRequest()];

declare 'SearchFilesResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::SearchFilesResponse'];

coerce 'SearchFilesResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::SearchFilesResponse'->new($_) };

declare 'RepeatedSearchFilesResponse',
    as ArrayRef[SearchFilesResponse()];

coerce 'RepeatedSearchFilesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::SearchFilesResponse'->new($_) } @$_ ] };

declare 'MapStringSearchFilesResponse',
    as HashRef[SearchFilesResponse()];

declare 'SearchResult',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::SearchResult'];

coerce 'SearchResult',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::SearchResult'->new($_) };

declare 'RepeatedSearchResult',
    as ArrayRef[SearchResult()];

coerce 'RepeatedSearchResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::SearchResult'->new($_) } @$_ ] };

declare 'MapStringSearchResult',
    as HashRef[SearchResult()];

declare 'FileSearchResult',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::FileSearchResult'];

coerce 'FileSearchResult',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::FileSearchResult'->new($_) };

declare 'RepeatedFileSearchResult',
    as ArrayRef[FileSearchResult()];

coerce 'RepeatedFileSearchResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::FileSearchResult'->new($_) } @$_ ] };

declare 'MapStringFileSearchResult',
    as HashRef[FileSearchResult()];

declare 'DirectorySearchResult',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::DirectorySearchResult'];

coerce 'DirectorySearchResult',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::DirectorySearchResult'->new($_) };

declare 'RepeatedDirectorySearchResult',
    as ArrayRef[DirectorySearchResult()];

coerce 'RepeatedDirectorySearchResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::DirectorySearchResult'->new($_) } @$_ ] };

declare 'MapStringDirectorySearchResult',
    as HashRef[DirectorySearchResult()];

declare 'MakeDirectoryRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::MakeDirectoryRequest'];

coerce 'MakeDirectoryRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::MakeDirectoryRequest'->new($_) };

declare 'RepeatedMakeDirectoryRequest',
    as ArrayRef[MakeDirectoryRequest()];

coerce 'RepeatedMakeDirectoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::MakeDirectoryRequest'->new($_) } @$_ ] };

declare 'MapStringMakeDirectoryRequest',
    as HashRef[MakeDirectoryRequest()];

declare 'MakeDirectoryResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::MakeDirectoryResponse'];

coerce 'MakeDirectoryResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::MakeDirectoryResponse'->new($_) };

declare 'RepeatedMakeDirectoryResponse',
    as ArrayRef[MakeDirectoryResponse()];

coerce 'RepeatedMakeDirectoryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::MakeDirectoryResponse'->new($_) } @$_ ] };

declare 'MapStringMakeDirectoryResponse',
    as HashRef[MakeDirectoryResponse()];

declare 'RemoveDirectoryRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::RemoveDirectoryRequest'];

coerce 'RemoveDirectoryRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::RemoveDirectoryRequest'->new($_) };

declare 'RepeatedRemoveDirectoryRequest',
    as ArrayRef[RemoveDirectoryRequest()];

coerce 'RepeatedRemoveDirectoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::RemoveDirectoryRequest'->new($_) } @$_ ] };

declare 'MapStringRemoveDirectoryRequest',
    as HashRef[RemoveDirectoryRequest()];

declare 'RemoveDirectoryResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::RemoveDirectoryResponse'];

coerce 'RemoveDirectoryResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::RemoveDirectoryResponse'->new($_) };

declare 'RepeatedRemoveDirectoryResponse',
    as ArrayRef[RemoveDirectoryResponse()];

coerce 'RepeatedRemoveDirectoryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::RemoveDirectoryResponse'->new($_) } @$_ ] };

declare 'MapStringRemoveDirectoryResponse',
    as HashRef[RemoveDirectoryResponse()];

declare 'MoveDirectoryRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::MoveDirectoryRequest'];

coerce 'MoveDirectoryRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::MoveDirectoryRequest'->new($_) };

declare 'RepeatedMoveDirectoryRequest',
    as ArrayRef[MoveDirectoryRequest()];

coerce 'RepeatedMoveDirectoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::MoveDirectoryRequest'->new($_) } @$_ ] };

declare 'MapStringMoveDirectoryRequest',
    as HashRef[MoveDirectoryRequest()];

declare 'MoveDirectoryResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::MoveDirectoryResponse'];

coerce 'MoveDirectoryResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::MoveDirectoryResponse'->new($_) };

declare 'RepeatedMoveDirectoryResponse',
    as ArrayRef[MoveDirectoryResponse()];

coerce 'RepeatedMoveDirectoryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::MoveDirectoryResponse'->new($_) } @$_ ] };

declare 'MapStringMoveDirectoryResponse',
    as HashRef[MoveDirectoryResponse()];

declare 'ReadFileRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::ReadFileRequest'];

coerce 'ReadFileRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::ReadFileRequest'->new($_) };

declare 'RepeatedReadFileRequest',
    as ArrayRef[ReadFileRequest()];

coerce 'RepeatedReadFileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::ReadFileRequest'->new($_) } @$_ ] };

declare 'MapStringReadFileRequest',
    as HashRef[ReadFileRequest()];

declare 'ReadFileResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::ReadFileResponse'];

coerce 'ReadFileResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::ReadFileResponse'->new($_) };

declare 'RepeatedReadFileResponse',
    as ArrayRef[ReadFileResponse()];

coerce 'RepeatedReadFileResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::ReadFileResponse'->new($_) } @$_ ] };

declare 'MapStringReadFileResponse',
    as HashRef[ReadFileResponse()];

declare 'RemoveFileRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::RemoveFileRequest'];

coerce 'RemoveFileRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::RemoveFileRequest'->new($_) };

declare 'RepeatedRemoveFileRequest',
    as ArrayRef[RemoveFileRequest()];

coerce 'RepeatedRemoveFileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::RemoveFileRequest'->new($_) } @$_ ] };

declare 'MapStringRemoveFileRequest',
    as HashRef[RemoveFileRequest()];

declare 'RemoveFileResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::RemoveFileResponse'];

coerce 'RemoveFileResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::RemoveFileResponse'->new($_) };

declare 'RepeatedRemoveFileResponse',
    as ArrayRef[RemoveFileResponse()];

coerce 'RepeatedRemoveFileResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::RemoveFileResponse'->new($_) } @$_ ] };

declare 'MapStringRemoveFileResponse',
    as HashRef[RemoveFileResponse()];

declare 'MoveFileRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::MoveFileRequest'];

coerce 'MoveFileRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::MoveFileRequest'->new($_) };

declare 'RepeatedMoveFileRequest',
    as ArrayRef[MoveFileRequest()];

coerce 'RepeatedMoveFileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::MoveFileRequest'->new($_) } @$_ ] };

declare 'MapStringMoveFileRequest',
    as HashRef[MoveFileRequest()];

declare 'MoveFileResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::MoveFileResponse'];

coerce 'MoveFileResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::MoveFileResponse'->new($_) };

declare 'RepeatedMoveFileResponse',
    as ArrayRef[MoveFileResponse()];

coerce 'RepeatedMoveFileResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::MoveFileResponse'->new($_) } @$_ ] };

declare 'MapStringMoveFileResponse',
    as HashRef[MoveFileResponse()];

declare 'WriteFileRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::WriteFileRequest'];

coerce 'WriteFileRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::WriteFileRequest'->new($_) };

declare 'RepeatedWriteFileRequest',
    as ArrayRef[WriteFileRequest()];

coerce 'RepeatedWriteFileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::WriteFileRequest'->new($_) } @$_ ] };

declare 'MapStringWriteFileRequest',
    as HashRef[WriteFileRequest()];

declare 'WriteFileResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::WriteFileResponse'];

coerce 'WriteFileResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::WriteFileResponse'->new($_) };

declare 'RepeatedWriteFileResponse',
    as ArrayRef[WriteFileResponse()];

coerce 'RepeatedWriteFileResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::WriteFileResponse'->new($_) } @$_ ] };

declare 'MapStringWriteFileResponse',
    as HashRef[WriteFileResponse()];

declare 'InstallNpmPackagesRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::InstallNpmPackagesRequest'];

coerce 'InstallNpmPackagesRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::InstallNpmPackagesRequest'->new($_) };

declare 'RepeatedInstallNpmPackagesRequest',
    as ArrayRef[InstallNpmPackagesRequest()];

coerce 'RepeatedInstallNpmPackagesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::InstallNpmPackagesRequest'->new($_) } @$_ ] };

declare 'MapStringInstallNpmPackagesRequest',
    as HashRef[InstallNpmPackagesRequest()];

declare 'InstallNpmPackagesResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::InstallNpmPackagesResponse'];

coerce 'InstallNpmPackagesResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::InstallNpmPackagesResponse'->new($_) };

declare 'RepeatedInstallNpmPackagesResponse',
    as ArrayRef[InstallNpmPackagesResponse()];

coerce 'RepeatedInstallNpmPackagesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::InstallNpmPackagesResponse'->new($_) } @$_ ] };

declare 'MapStringInstallNpmPackagesResponse',
    as HashRef[InstallNpmPackagesResponse()];

declare 'ReleaseConfig',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::ReleaseConfig'];

coerce 'ReleaseConfig',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::ReleaseConfig'->new($_) };

declare 'RepeatedReleaseConfig',
    as ArrayRef[ReleaseConfig()];

coerce 'RepeatedReleaseConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::ReleaseConfig'->new($_) } @$_ ] };

declare 'MapStringReleaseConfig',
    as HashRef[ReleaseConfig()];

declare 'ScheduledReleaseRecord',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::ReleaseConfig::ScheduledReleaseRecord'];

coerce 'ScheduledReleaseRecord',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::ReleaseConfig::ScheduledReleaseRecord'->new($_) };

declare 'RepeatedScheduledReleaseRecord',
    as ArrayRef[ScheduledReleaseRecord()];

coerce 'RepeatedScheduledReleaseRecord',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::ReleaseConfig::ScheduledReleaseRecord'->new($_) } @$_ ] };

declare 'MapStringScheduledReleaseRecord',
    as HashRef[ScheduledReleaseRecord()];

declare 'ListReleaseConfigsRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::ListReleaseConfigsRequest'];

coerce 'ListReleaseConfigsRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::ListReleaseConfigsRequest'->new($_) };

declare 'RepeatedListReleaseConfigsRequest',
    as ArrayRef[ListReleaseConfigsRequest()];

coerce 'RepeatedListReleaseConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::ListReleaseConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListReleaseConfigsRequest',
    as HashRef[ListReleaseConfigsRequest()];

declare 'ListReleaseConfigsResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::ListReleaseConfigsResponse'];

coerce 'ListReleaseConfigsResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::ListReleaseConfigsResponse'->new($_) };

declare 'RepeatedListReleaseConfigsResponse',
    as ArrayRef[ListReleaseConfigsResponse()];

coerce 'RepeatedListReleaseConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::ListReleaseConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListReleaseConfigsResponse',
    as HashRef[ListReleaseConfigsResponse()];

declare 'GetReleaseConfigRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::GetReleaseConfigRequest'];

coerce 'GetReleaseConfigRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::GetReleaseConfigRequest'->new($_) };

declare 'RepeatedGetReleaseConfigRequest',
    as ArrayRef[GetReleaseConfigRequest()];

coerce 'RepeatedGetReleaseConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::GetReleaseConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetReleaseConfigRequest',
    as HashRef[GetReleaseConfigRequest()];

declare 'CreateReleaseConfigRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CreateReleaseConfigRequest'];

coerce 'CreateReleaseConfigRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CreateReleaseConfigRequest'->new($_) };

declare 'RepeatedCreateReleaseConfigRequest',
    as ArrayRef[CreateReleaseConfigRequest()];

coerce 'RepeatedCreateReleaseConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CreateReleaseConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateReleaseConfigRequest',
    as HashRef[CreateReleaseConfigRequest()];

declare 'UpdateReleaseConfigRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::UpdateReleaseConfigRequest'];

coerce 'UpdateReleaseConfigRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::UpdateReleaseConfigRequest'->new($_) };

declare 'RepeatedUpdateReleaseConfigRequest',
    as ArrayRef[UpdateReleaseConfigRequest()];

coerce 'RepeatedUpdateReleaseConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::UpdateReleaseConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateReleaseConfigRequest',
    as HashRef[UpdateReleaseConfigRequest()];

declare 'DeleteReleaseConfigRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::DeleteReleaseConfigRequest'];

coerce 'DeleteReleaseConfigRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::DeleteReleaseConfigRequest'->new($_) };

declare 'RepeatedDeleteReleaseConfigRequest',
    as ArrayRef[DeleteReleaseConfigRequest()];

coerce 'RepeatedDeleteReleaseConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::DeleteReleaseConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteReleaseConfigRequest',
    as HashRef[DeleteReleaseConfigRequest()];

declare 'CompilationResult',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CompilationResult'];

coerce 'CompilationResult',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CompilationResult'->new($_) };

declare 'RepeatedCompilationResult',
    as ArrayRef[CompilationResult()];

coerce 'RepeatedCompilationResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CompilationResult'->new($_) } @$_ ] };

declare 'MapStringCompilationResult',
    as HashRef[CompilationResult()];

declare 'CompilationError',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CompilationResult::CompilationError'];

coerce 'CompilationError',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CompilationResult::CompilationError'->new($_) };

declare 'RepeatedCompilationError',
    as ArrayRef[CompilationError()];

coerce 'RepeatedCompilationError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CompilationResult::CompilationError'->new($_) } @$_ ] };

declare 'MapStringCompilationError',
    as HashRef[CompilationError()];

declare 'CodeCompilationConfig',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CodeCompilationConfig'];

coerce 'CodeCompilationConfig',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CodeCompilationConfig'->new($_) };

declare 'RepeatedCodeCompilationConfig',
    as ArrayRef[CodeCompilationConfig()];

coerce 'RepeatedCodeCompilationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CodeCompilationConfig'->new($_) } @$_ ] };

declare 'MapStringCodeCompilationConfig',
    as HashRef[CodeCompilationConfig()];

declare 'VarsEntry',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CodeCompilationConfig::VarsEntry'];

coerce 'VarsEntry',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CodeCompilationConfig::VarsEntry'->new($_) };

declare 'RepeatedVarsEntry',
    as ArrayRef[VarsEntry()];

coerce 'RepeatedVarsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CodeCompilationConfig::VarsEntry'->new($_) } @$_ ] };

declare 'MapStringVarsEntry',
    as HashRef[VarsEntry()];

declare 'GcsRepositorySnapshotMetadata',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::GcsRepositorySnapshotMetadata'];

coerce 'GcsRepositorySnapshotMetadata',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::GcsRepositorySnapshotMetadata'->new($_) };

declare 'RepeatedGcsRepositorySnapshotMetadata',
    as ArrayRef[GcsRepositorySnapshotMetadata()];

coerce 'RepeatedGcsRepositorySnapshotMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::GcsRepositorySnapshotMetadata'->new($_) } @$_ ] };

declare 'MapStringGcsRepositorySnapshotMetadata',
    as HashRef[GcsRepositorySnapshotMetadata()];

declare 'GcsRepositorySnapshotDestination',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::GcsRepositorySnapshotDestination'];

coerce 'GcsRepositorySnapshotDestination',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::GcsRepositorySnapshotDestination'->new($_) };

declare 'RepeatedGcsRepositorySnapshotDestination',
    as ArrayRef[GcsRepositorySnapshotDestination()];

coerce 'RepeatedGcsRepositorySnapshotDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::GcsRepositorySnapshotDestination'->new($_) } @$_ ] };

declare 'MapStringGcsRepositorySnapshotDestination',
    as HashRef[GcsRepositorySnapshotDestination()];

declare 'NotebookRuntimeOptions',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::NotebookRuntimeOptions'];

coerce 'NotebookRuntimeOptions',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::NotebookRuntimeOptions'->new($_) };

declare 'RepeatedNotebookRuntimeOptions',
    as ArrayRef[NotebookRuntimeOptions()];

coerce 'RepeatedNotebookRuntimeOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::NotebookRuntimeOptions'->new($_) } @$_ ] };

declare 'MapStringNotebookRuntimeOptions',
    as HashRef[NotebookRuntimeOptions()];

declare 'PipelineConfig',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::PipelineConfig'];

coerce 'PipelineConfig',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::PipelineConfig'->new($_) };

declare 'RepeatedPipelineConfig',
    as ArrayRef[PipelineConfig()];

coerce 'RepeatedPipelineConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::PipelineConfig'->new($_) } @$_ ] };

declare 'MapStringPipelineConfig',
    as HashRef[PipelineConfig()];

declare 'PipelineType',
    as (Int | Str);

declare 'ListCompilationResultsRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::ListCompilationResultsRequest'];

coerce 'ListCompilationResultsRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::ListCompilationResultsRequest'->new($_) };

declare 'RepeatedListCompilationResultsRequest',
    as ArrayRef[ListCompilationResultsRequest()];

coerce 'RepeatedListCompilationResultsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::ListCompilationResultsRequest'->new($_) } @$_ ] };

declare 'MapStringListCompilationResultsRequest',
    as HashRef[ListCompilationResultsRequest()];

declare 'ListCompilationResultsResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::ListCompilationResultsResponse'];

coerce 'ListCompilationResultsResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::ListCompilationResultsResponse'->new($_) };

declare 'RepeatedListCompilationResultsResponse',
    as ArrayRef[ListCompilationResultsResponse()];

coerce 'RepeatedListCompilationResultsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::ListCompilationResultsResponse'->new($_) } @$_ ] };

declare 'MapStringListCompilationResultsResponse',
    as HashRef[ListCompilationResultsResponse()];

declare 'GetCompilationResultRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::GetCompilationResultRequest'];

coerce 'GetCompilationResultRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::GetCompilationResultRequest'->new($_) };

declare 'RepeatedGetCompilationResultRequest',
    as ArrayRef[GetCompilationResultRequest()];

coerce 'RepeatedGetCompilationResultRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::GetCompilationResultRequest'->new($_) } @$_ ] };

declare 'MapStringGetCompilationResultRequest',
    as HashRef[GetCompilationResultRequest()];

declare 'CreateCompilationResultRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CreateCompilationResultRequest'];

coerce 'CreateCompilationResultRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CreateCompilationResultRequest'->new($_) };

declare 'RepeatedCreateCompilationResultRequest',
    as ArrayRef[CreateCompilationResultRequest()];

coerce 'RepeatedCreateCompilationResultRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CreateCompilationResultRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCompilationResultRequest',
    as HashRef[CreateCompilationResultRequest()];

declare 'CreateCompilationResultMetadata',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CreateCompilationResultMetadata'];

coerce 'CreateCompilationResultMetadata',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CreateCompilationResultMetadata'->new($_) };

declare 'RepeatedCreateCompilationResultMetadata',
    as ArrayRef[CreateCompilationResultMetadata()];

coerce 'RepeatedCreateCompilationResultMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CreateCompilationResultMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateCompilationResultMetadata',
    as HashRef[CreateCompilationResultMetadata()];

declare 'State',
    as (Int | Str);

declare 'Target',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::Target'];

coerce 'Target',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::Target'->new($_) };

declare 'RepeatedTarget',
    as ArrayRef[Target()];

coerce 'RepeatedTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::Target'->new($_) } @$_ ] };

declare 'MapStringTarget',
    as HashRef[Target()];

declare 'RelationDescriptor',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::RelationDescriptor'];

coerce 'RelationDescriptor',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::RelationDescriptor'->new($_) };

declare 'RepeatedRelationDescriptor',
    as ArrayRef[RelationDescriptor()];

coerce 'RepeatedRelationDescriptor',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::RelationDescriptor'->new($_) } @$_ ] };

declare 'MapStringRelationDescriptor',
    as HashRef[RelationDescriptor()];

declare 'ColumnDescriptor',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::RelationDescriptor::ColumnDescriptor'];

coerce 'ColumnDescriptor',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::RelationDescriptor::ColumnDescriptor'->new($_) };

declare 'RepeatedColumnDescriptor',
    as ArrayRef[ColumnDescriptor()];

coerce 'RepeatedColumnDescriptor',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::RelationDescriptor::ColumnDescriptor'->new($_) } @$_ ] };

declare 'MapStringColumnDescriptor',
    as HashRef[ColumnDescriptor()];

declare 'BigqueryLabelsEntry',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::RelationDescriptor::BigqueryLabelsEntry'];

coerce 'BigqueryLabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::RelationDescriptor::BigqueryLabelsEntry'->new($_) };

declare 'RepeatedBigqueryLabelsEntry',
    as ArrayRef[BigqueryLabelsEntry()];

coerce 'RepeatedBigqueryLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::RelationDescriptor::BigqueryLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringBigqueryLabelsEntry',
    as HashRef[BigqueryLabelsEntry()];

declare 'CompilationResultAction',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CompilationResultAction'];

coerce 'CompilationResultAction',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CompilationResultAction'->new($_) };

declare 'RepeatedCompilationResultAction',
    as ArrayRef[CompilationResultAction()];

coerce 'RepeatedCompilationResultAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CompilationResultAction'->new($_) } @$_ ] };

declare 'MapStringCompilationResultAction',
    as HashRef[CompilationResultAction()];

declare 'Relation',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::Relation'];

coerce 'Relation',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::Relation'->new($_) };

declare 'RepeatedRelation',
    as ArrayRef[Relation()];

coerce 'RepeatedRelation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::Relation'->new($_) } @$_ ] };

declare 'MapStringRelation',
    as HashRef[Relation()];

declare 'RelationType',
    as (Int | Str);

declare 'TableFormat',
    as (Int | Str);

declare 'FileFormat',
    as (Int | Str);

declare 'IncrementalTableConfig',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::Relation::IncrementalTableConfig'];

coerce 'IncrementalTableConfig',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::Relation::IncrementalTableConfig'->new($_) };

declare 'RepeatedIncrementalTableConfig',
    as ArrayRef[IncrementalTableConfig()];

coerce 'RepeatedIncrementalTableConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::Relation::IncrementalTableConfig'->new($_) } @$_ ] };

declare 'MapStringIncrementalTableConfig',
    as HashRef[IncrementalTableConfig()];

declare 'AdditionalOptionsEntry',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::Relation::AdditionalOptionsEntry'];

coerce 'AdditionalOptionsEntry',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::Relation::AdditionalOptionsEntry'->new($_) };

declare 'RepeatedAdditionalOptionsEntry',
    as ArrayRef[AdditionalOptionsEntry()];

coerce 'RepeatedAdditionalOptionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::Relation::AdditionalOptionsEntry'->new($_) } @$_ ] };

declare 'MapStringAdditionalOptionsEntry',
    as HashRef[AdditionalOptionsEntry()];

declare 'Operations',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::Operations'];

coerce 'Operations',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::Operations'->new($_) };

declare 'RepeatedOperations',
    as ArrayRef[Operations()];

coerce 'RepeatedOperations',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::Operations'->new($_) } @$_ ] };

declare 'MapStringOperations',
    as HashRef[Operations()];

declare 'Assertion',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::Assertion'];

coerce 'Assertion',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::Assertion'->new($_) };

declare 'RepeatedAssertion',
    as ArrayRef[Assertion()];

coerce 'RepeatedAssertion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::Assertion'->new($_) } @$_ ] };

declare 'MapStringAssertion',
    as HashRef[Assertion()];

declare 'Declaration',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::Declaration'];

coerce 'Declaration',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::Declaration'->new($_) };

declare 'RepeatedDeclaration',
    as ArrayRef[Declaration()];

coerce 'RepeatedDeclaration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::Declaration'->new($_) } @$_ ] };

declare 'MapStringDeclaration',
    as HashRef[Declaration()];

declare 'Notebook',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::Notebook'];

coerce 'Notebook',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::Notebook'->new($_) };

declare 'RepeatedNotebook',
    as ArrayRef[Notebook()];

coerce 'RepeatedNotebook',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::Notebook'->new($_) } @$_ ] };

declare 'MapStringNotebook',
    as HashRef[Notebook()];

declare 'DataPreparation',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::DataPreparation'];

coerce 'DataPreparation',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::DataPreparation'->new($_) };

declare 'RepeatedDataPreparation',
    as ArrayRef[DataPreparation()];

coerce 'RepeatedDataPreparation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::DataPreparation'->new($_) } @$_ ] };

declare 'MapStringDataPreparation',
    as HashRef[DataPreparation()];

declare 'SqlDefinition',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::DataPreparation::SqlDefinition'];

coerce 'SqlDefinition',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::DataPreparation::SqlDefinition'->new($_) };

declare 'RepeatedSqlDefinition',
    as ArrayRef[SqlDefinition()];

coerce 'RepeatedSqlDefinition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::DataPreparation::SqlDefinition'->new($_) } @$_ ] };

declare 'MapStringSqlDefinition',
    as HashRef[SqlDefinition()];

declare 'ErrorTable',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::DataPreparation::ErrorTable'];

coerce 'ErrorTable',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::DataPreparation::ErrorTable'->new($_) };

declare 'RepeatedErrorTable',
    as ArrayRef[ErrorTable()];

coerce 'RepeatedErrorTable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::DataPreparation::ErrorTable'->new($_) } @$_ ] };

declare 'MapStringErrorTable',
    as HashRef[ErrorTable()];

declare 'BigQueryUnitTest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::BigQueryUnitTest'];

coerce 'BigQueryUnitTest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::BigQueryUnitTest'->new($_) };

declare 'RepeatedBigQueryUnitTest',
    as ArrayRef[BigQueryUnitTest()];

coerce 'RepeatedBigQueryUnitTest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::BigQueryUnitTest'->new($_) } @$_ ] };

declare 'MapStringBigQueryUnitTest',
    as HashRef[BigQueryUnitTest()];

declare 'LoadConfig',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::LoadConfig'];

coerce 'LoadConfig',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::LoadConfig'->new($_) };

declare 'RepeatedLoadConfig',
    as ArrayRef[LoadConfig()];

coerce 'RepeatedLoadConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::LoadConfig'->new($_) } @$_ ] };

declare 'MapStringLoadConfig',
    as HashRef[LoadConfig()];

declare 'SimpleLoadMode',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::SimpleLoadMode'];

coerce 'SimpleLoadMode',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::SimpleLoadMode'->new($_) };

declare 'RepeatedSimpleLoadMode',
    as ArrayRef[SimpleLoadMode()];

coerce 'RepeatedSimpleLoadMode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::SimpleLoadMode'->new($_) } @$_ ] };

declare 'MapStringSimpleLoadMode',
    as HashRef[SimpleLoadMode()];

declare 'IncrementalLoadMode',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::IncrementalLoadMode'];

coerce 'IncrementalLoadMode',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::IncrementalLoadMode'->new($_) };

declare 'RepeatedIncrementalLoadMode',
    as ArrayRef[IncrementalLoadMode()];

coerce 'RepeatedIncrementalLoadMode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CompilationResultAction::IncrementalLoadMode'->new($_) } @$_ ] };

declare 'MapStringIncrementalLoadMode',
    as HashRef[IncrementalLoadMode()];

declare 'QueryCompilationResultActionsRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::QueryCompilationResultActionsRequest'];

coerce 'QueryCompilationResultActionsRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::QueryCompilationResultActionsRequest'->new($_) };

declare 'RepeatedQueryCompilationResultActionsRequest',
    as ArrayRef[QueryCompilationResultActionsRequest()];

coerce 'RepeatedQueryCompilationResultActionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::QueryCompilationResultActionsRequest'->new($_) } @$_ ] };

declare 'MapStringQueryCompilationResultActionsRequest',
    as HashRef[QueryCompilationResultActionsRequest()];

declare 'QueryCompilationResultActionsResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::QueryCompilationResultActionsResponse'];

coerce 'QueryCompilationResultActionsResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::QueryCompilationResultActionsResponse'->new($_) };

declare 'RepeatedQueryCompilationResultActionsResponse',
    as ArrayRef[QueryCompilationResultActionsResponse()];

coerce 'RepeatedQueryCompilationResultActionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::QueryCompilationResultActionsResponse'->new($_) } @$_ ] };

declare 'MapStringQueryCompilationResultActionsResponse',
    as HashRef[QueryCompilationResultActionsResponse()];

declare 'WorkflowConfig',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::WorkflowConfig'];

coerce 'WorkflowConfig',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::WorkflowConfig'->new($_) };

declare 'RepeatedWorkflowConfig',
    as ArrayRef[WorkflowConfig()];

coerce 'RepeatedWorkflowConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::WorkflowConfig'->new($_) } @$_ ] };

declare 'MapStringWorkflowConfig',
    as HashRef[WorkflowConfig()];

declare 'ScheduledExecutionRecord',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::WorkflowConfig::ScheduledExecutionRecord'];

coerce 'ScheduledExecutionRecord',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::WorkflowConfig::ScheduledExecutionRecord'->new($_) };

declare 'RepeatedScheduledExecutionRecord',
    as ArrayRef[ScheduledExecutionRecord()];

coerce 'RepeatedScheduledExecutionRecord',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::WorkflowConfig::ScheduledExecutionRecord'->new($_) } @$_ ] };

declare 'MapStringScheduledExecutionRecord',
    as HashRef[ScheduledExecutionRecord()];

declare 'InvocationConfig',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::InvocationConfig'];

coerce 'InvocationConfig',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::InvocationConfig'->new($_) };

declare 'RepeatedInvocationConfig',
    as ArrayRef[InvocationConfig()];

coerce 'RepeatedInvocationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::InvocationConfig'->new($_) } @$_ ] };

declare 'MapStringInvocationConfig',
    as HashRef[InvocationConfig()];

declare 'QueryPriority',
    as (Int | Str);

declare 'ExecutionMode',
    as (Int | Str);

declare 'EndUserAuthenticationConfig',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::InvocationConfig::EndUserAuthenticationConfig'];

coerce 'EndUserAuthenticationConfig',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::InvocationConfig::EndUserAuthenticationConfig'->new($_) };

declare 'RepeatedEndUserAuthenticationConfig',
    as ArrayRef[EndUserAuthenticationConfig()];

coerce 'RepeatedEndUserAuthenticationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::InvocationConfig::EndUserAuthenticationConfig'->new($_) } @$_ ] };

declare 'MapStringEndUserAuthenticationConfig',
    as HashRef[EndUserAuthenticationConfig()];

declare 'ListWorkflowConfigsRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::ListWorkflowConfigsRequest'];

coerce 'ListWorkflowConfigsRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::ListWorkflowConfigsRequest'->new($_) };

declare 'RepeatedListWorkflowConfigsRequest',
    as ArrayRef[ListWorkflowConfigsRequest()];

coerce 'RepeatedListWorkflowConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::ListWorkflowConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListWorkflowConfigsRequest',
    as HashRef[ListWorkflowConfigsRequest()];

declare 'ListWorkflowConfigsResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::ListWorkflowConfigsResponse'];

coerce 'ListWorkflowConfigsResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::ListWorkflowConfigsResponse'->new($_) };

declare 'RepeatedListWorkflowConfigsResponse',
    as ArrayRef[ListWorkflowConfigsResponse()];

coerce 'RepeatedListWorkflowConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::ListWorkflowConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListWorkflowConfigsResponse',
    as HashRef[ListWorkflowConfigsResponse()];

declare 'GetWorkflowConfigRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::GetWorkflowConfigRequest'];

coerce 'GetWorkflowConfigRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::GetWorkflowConfigRequest'->new($_) };

declare 'RepeatedGetWorkflowConfigRequest',
    as ArrayRef[GetWorkflowConfigRequest()];

coerce 'RepeatedGetWorkflowConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::GetWorkflowConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetWorkflowConfigRequest',
    as HashRef[GetWorkflowConfigRequest()];

declare 'CreateWorkflowConfigRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CreateWorkflowConfigRequest'];

coerce 'CreateWorkflowConfigRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CreateWorkflowConfigRequest'->new($_) };

declare 'RepeatedCreateWorkflowConfigRequest',
    as ArrayRef[CreateWorkflowConfigRequest()];

coerce 'RepeatedCreateWorkflowConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CreateWorkflowConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateWorkflowConfigRequest',
    as HashRef[CreateWorkflowConfigRequest()];

declare 'UpdateWorkflowConfigRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::UpdateWorkflowConfigRequest'];

coerce 'UpdateWorkflowConfigRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::UpdateWorkflowConfigRequest'->new($_) };

declare 'RepeatedUpdateWorkflowConfigRequest',
    as ArrayRef[UpdateWorkflowConfigRequest()];

coerce 'RepeatedUpdateWorkflowConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::UpdateWorkflowConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateWorkflowConfigRequest',
    as HashRef[UpdateWorkflowConfigRequest()];

declare 'DeleteWorkflowConfigRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::DeleteWorkflowConfigRequest'];

coerce 'DeleteWorkflowConfigRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::DeleteWorkflowConfigRequest'->new($_) };

declare 'RepeatedDeleteWorkflowConfigRequest',
    as ArrayRef[DeleteWorkflowConfigRequest()];

coerce 'RepeatedDeleteWorkflowConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::DeleteWorkflowConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteWorkflowConfigRequest',
    as HashRef[DeleteWorkflowConfigRequest()];

declare 'WorkflowInvocation',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::WorkflowInvocation'];

coerce 'WorkflowInvocation',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::WorkflowInvocation'->new($_) };

declare 'RepeatedWorkflowInvocation',
    as ArrayRef[WorkflowInvocation()];

coerce 'RepeatedWorkflowInvocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::WorkflowInvocation'->new($_) } @$_ ] };

declare 'MapStringWorkflowInvocation',
    as HashRef[WorkflowInvocation()];

declare 'State',
    as (Int | Str);

declare 'ListWorkflowInvocationsRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::ListWorkflowInvocationsRequest'];

coerce 'ListWorkflowInvocationsRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::ListWorkflowInvocationsRequest'->new($_) };

declare 'RepeatedListWorkflowInvocationsRequest',
    as ArrayRef[ListWorkflowInvocationsRequest()];

coerce 'RepeatedListWorkflowInvocationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::ListWorkflowInvocationsRequest'->new($_) } @$_ ] };

declare 'MapStringListWorkflowInvocationsRequest',
    as HashRef[ListWorkflowInvocationsRequest()];

declare 'ListWorkflowInvocationsResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::ListWorkflowInvocationsResponse'];

coerce 'ListWorkflowInvocationsResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::ListWorkflowInvocationsResponse'->new($_) };

declare 'RepeatedListWorkflowInvocationsResponse',
    as ArrayRef[ListWorkflowInvocationsResponse()];

coerce 'RepeatedListWorkflowInvocationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::ListWorkflowInvocationsResponse'->new($_) } @$_ ] };

declare 'MapStringListWorkflowInvocationsResponse',
    as HashRef[ListWorkflowInvocationsResponse()];

declare 'GetWorkflowInvocationRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::GetWorkflowInvocationRequest'];

coerce 'GetWorkflowInvocationRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::GetWorkflowInvocationRequest'->new($_) };

declare 'RepeatedGetWorkflowInvocationRequest',
    as ArrayRef[GetWorkflowInvocationRequest()];

coerce 'RepeatedGetWorkflowInvocationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::GetWorkflowInvocationRequest'->new($_) } @$_ ] };

declare 'MapStringGetWorkflowInvocationRequest',
    as HashRef[GetWorkflowInvocationRequest()];

declare 'CreateWorkflowInvocationRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CreateWorkflowInvocationRequest'];

coerce 'CreateWorkflowInvocationRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CreateWorkflowInvocationRequest'->new($_) };

declare 'RepeatedCreateWorkflowInvocationRequest',
    as ArrayRef[CreateWorkflowInvocationRequest()];

coerce 'RepeatedCreateWorkflowInvocationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CreateWorkflowInvocationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateWorkflowInvocationRequest',
    as HashRef[CreateWorkflowInvocationRequest()];

declare 'DeleteWorkflowInvocationRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::DeleteWorkflowInvocationRequest'];

coerce 'DeleteWorkflowInvocationRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::DeleteWorkflowInvocationRequest'->new($_) };

declare 'RepeatedDeleteWorkflowInvocationRequest',
    as ArrayRef[DeleteWorkflowInvocationRequest()];

coerce 'RepeatedDeleteWorkflowInvocationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::DeleteWorkflowInvocationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteWorkflowInvocationRequest',
    as HashRef[DeleteWorkflowInvocationRequest()];

declare 'CancelWorkflowInvocationRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CancelWorkflowInvocationRequest'];

coerce 'CancelWorkflowInvocationRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CancelWorkflowInvocationRequest'->new($_) };

declare 'RepeatedCancelWorkflowInvocationRequest',
    as ArrayRef[CancelWorkflowInvocationRequest()];

coerce 'RepeatedCancelWorkflowInvocationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CancelWorkflowInvocationRequest'->new($_) } @$_ ] };

declare 'MapStringCancelWorkflowInvocationRequest',
    as HashRef[CancelWorkflowInvocationRequest()];

declare 'CancelWorkflowInvocationResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CancelWorkflowInvocationResponse'];

coerce 'CancelWorkflowInvocationResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CancelWorkflowInvocationResponse'->new($_) };

declare 'RepeatedCancelWorkflowInvocationResponse',
    as ArrayRef[CancelWorkflowInvocationResponse()];

coerce 'RepeatedCancelWorkflowInvocationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CancelWorkflowInvocationResponse'->new($_) } @$_ ] };

declare 'MapStringCancelWorkflowInvocationResponse',
    as HashRef[CancelWorkflowInvocationResponse()];

declare 'WorkflowInvocationAction',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::WorkflowInvocationAction'];

coerce 'WorkflowInvocationAction',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::WorkflowInvocationAction'->new($_) };

declare 'RepeatedWorkflowInvocationAction',
    as ArrayRef[WorkflowInvocationAction()];

coerce 'RepeatedWorkflowInvocationAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::WorkflowInvocationAction'->new($_) } @$_ ] };

declare 'MapStringWorkflowInvocationAction',
    as HashRef[WorkflowInvocationAction()];

declare 'State',
    as (Int | Str);

declare 'BigQueryAction',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::WorkflowInvocationAction::BigQueryAction'];

coerce 'BigQueryAction',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::WorkflowInvocationAction::BigQueryAction'->new($_) };

declare 'RepeatedBigQueryAction',
    as ArrayRef[BigQueryAction()];

coerce 'RepeatedBigQueryAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::WorkflowInvocationAction::BigQueryAction'->new($_) } @$_ ] };

declare 'MapStringBigQueryAction',
    as HashRef[BigQueryAction()];

declare 'NotebookAction',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::WorkflowInvocationAction::NotebookAction'];

coerce 'NotebookAction',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::WorkflowInvocationAction::NotebookAction'->new($_) };

declare 'RepeatedNotebookAction',
    as ArrayRef[NotebookAction()];

coerce 'RepeatedNotebookAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::WorkflowInvocationAction::NotebookAction'->new($_) } @$_ ] };

declare 'MapStringNotebookAction',
    as HashRef[NotebookAction()];

declare 'DataPreparationAction',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::WorkflowInvocationAction::DataPreparationAction'];

coerce 'DataPreparationAction',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::WorkflowInvocationAction::DataPreparationAction'->new($_) };

declare 'RepeatedDataPreparationAction',
    as ArrayRef[DataPreparationAction()];

coerce 'RepeatedDataPreparationAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::WorkflowInvocationAction::DataPreparationAction'->new($_) } @$_ ] };

declare 'MapStringDataPreparationAction',
    as HashRef[DataPreparationAction()];

declare 'ActionSqlDefinition',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::WorkflowInvocationAction::DataPreparationAction::ActionSqlDefinition'];

coerce 'ActionSqlDefinition',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::WorkflowInvocationAction::DataPreparationAction::ActionSqlDefinition'->new($_) };

declare 'RepeatedActionSqlDefinition',
    as ArrayRef[ActionSqlDefinition()];

coerce 'RepeatedActionSqlDefinition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::WorkflowInvocationAction::DataPreparationAction::ActionSqlDefinition'->new($_) } @$_ ] };

declare 'MapStringActionSqlDefinition',
    as HashRef[ActionSqlDefinition()];

declare 'ActionErrorTable',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::WorkflowInvocationAction::DataPreparationAction::ActionErrorTable'];

coerce 'ActionErrorTable',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::WorkflowInvocationAction::DataPreparationAction::ActionErrorTable'->new($_) };

declare 'RepeatedActionErrorTable',
    as ArrayRef[ActionErrorTable()];

coerce 'RepeatedActionErrorTable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::WorkflowInvocationAction::DataPreparationAction::ActionErrorTable'->new($_) } @$_ ] };

declare 'MapStringActionErrorTable',
    as HashRef[ActionErrorTable()];

declare 'ActionLoadConfig',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::WorkflowInvocationAction::DataPreparationAction::ActionLoadConfig'];

coerce 'ActionLoadConfig',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::WorkflowInvocationAction::DataPreparationAction::ActionLoadConfig'->new($_) };

declare 'RepeatedActionLoadConfig',
    as ArrayRef[ActionLoadConfig()];

coerce 'RepeatedActionLoadConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::WorkflowInvocationAction::DataPreparationAction::ActionLoadConfig'->new($_) } @$_ ] };

declare 'MapStringActionLoadConfig',
    as HashRef[ActionLoadConfig()];

declare 'ActionSimpleLoadMode',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::WorkflowInvocationAction::DataPreparationAction::ActionSimpleLoadMode'];

coerce 'ActionSimpleLoadMode',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::WorkflowInvocationAction::DataPreparationAction::ActionSimpleLoadMode'->new($_) };

declare 'RepeatedActionSimpleLoadMode',
    as ArrayRef[ActionSimpleLoadMode()];

coerce 'RepeatedActionSimpleLoadMode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::WorkflowInvocationAction::DataPreparationAction::ActionSimpleLoadMode'->new($_) } @$_ ] };

declare 'MapStringActionSimpleLoadMode',
    as HashRef[ActionSimpleLoadMode()];

declare 'ActionIncrementalLoadMode',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::WorkflowInvocationAction::DataPreparationAction::ActionIncrementalLoadMode'];

coerce 'ActionIncrementalLoadMode',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::WorkflowInvocationAction::DataPreparationAction::ActionIncrementalLoadMode'->new($_) };

declare 'RepeatedActionIncrementalLoadMode',
    as ArrayRef[ActionIncrementalLoadMode()];

coerce 'RepeatedActionIncrementalLoadMode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::WorkflowInvocationAction::DataPreparationAction::ActionIncrementalLoadMode'->new($_) } @$_ ] };

declare 'MapStringActionIncrementalLoadMode',
    as HashRef[ActionIncrementalLoadMode()];

declare 'BigQueryUnitTestAction',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::WorkflowInvocationAction::BigQueryUnitTestAction'];

coerce 'BigQueryUnitTestAction',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::WorkflowInvocationAction::BigQueryUnitTestAction'->new($_) };

declare 'RepeatedBigQueryUnitTestAction',
    as ArrayRef[BigQueryUnitTestAction()];

coerce 'RepeatedBigQueryUnitTestAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::WorkflowInvocationAction::BigQueryUnitTestAction'->new($_) } @$_ ] };

declare 'MapStringBigQueryUnitTestAction',
    as HashRef[BigQueryUnitTestAction()];

declare 'QueryWorkflowInvocationActionsRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::QueryWorkflowInvocationActionsRequest'];

coerce 'QueryWorkflowInvocationActionsRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::QueryWorkflowInvocationActionsRequest'->new($_) };

declare 'RepeatedQueryWorkflowInvocationActionsRequest',
    as ArrayRef[QueryWorkflowInvocationActionsRequest()];

coerce 'RepeatedQueryWorkflowInvocationActionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::QueryWorkflowInvocationActionsRequest'->new($_) } @$_ ] };

declare 'MapStringQueryWorkflowInvocationActionsRequest',
    as HashRef[QueryWorkflowInvocationActionsRequest()];

declare 'QueryWorkflowInvocationActionsResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::QueryWorkflowInvocationActionsResponse'];

coerce 'QueryWorkflowInvocationActionsResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::QueryWorkflowInvocationActionsResponse'->new($_) };

declare 'RepeatedQueryWorkflowInvocationActionsResponse',
    as ArrayRef[QueryWorkflowInvocationActionsResponse()];

coerce 'RepeatedQueryWorkflowInvocationActionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::QueryWorkflowInvocationActionsResponse'->new($_) } @$_ ] };

declare 'MapStringQueryWorkflowInvocationActionsResponse',
    as HashRef[QueryWorkflowInvocationActionsResponse()];

declare 'Config',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::Config'];

coerce 'Config',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::Config'->new($_) };

declare 'RepeatedConfig',
    as ArrayRef[Config()];

coerce 'RepeatedConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::Config'->new($_) } @$_ ] };

declare 'MapStringConfig',
    as HashRef[Config()];

declare 'GetConfigRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::GetConfigRequest'];

coerce 'GetConfigRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::GetConfigRequest'->new($_) };

declare 'RepeatedGetConfigRequest',
    as ArrayRef[GetConfigRequest()];

coerce 'RepeatedGetConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::GetConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetConfigRequest',
    as HashRef[GetConfigRequest()];

declare 'UpdateConfigRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::UpdateConfigRequest'];

coerce 'UpdateConfigRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::UpdateConfigRequest'->new($_) };

declare 'RepeatedUpdateConfigRequest',
    as ArrayRef[UpdateConfigRequest()];

coerce 'RepeatedUpdateConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::UpdateConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateConfigRequest',
    as HashRef[UpdateConfigRequest()];

declare 'Folder',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::Folder'];

coerce 'Folder',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::Folder'->new($_) };

declare 'RepeatedFolder',
    as ArrayRef[Folder()];

coerce 'RepeatedFolder',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::Folder'->new($_) } @$_ ] };

declare 'MapStringFolder',
    as HashRef[Folder()];

declare 'CreateFolderRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CreateFolderRequest'];

coerce 'CreateFolderRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CreateFolderRequest'->new($_) };

declare 'RepeatedCreateFolderRequest',
    as ArrayRef[CreateFolderRequest()];

coerce 'RepeatedCreateFolderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CreateFolderRequest'->new($_) } @$_ ] };

declare 'MapStringCreateFolderRequest',
    as HashRef[CreateFolderRequest()];

declare 'MoveFolderRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::MoveFolderRequest'];

coerce 'MoveFolderRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::MoveFolderRequest'->new($_) };

declare 'RepeatedMoveFolderRequest',
    as ArrayRef[MoveFolderRequest()];

coerce 'RepeatedMoveFolderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::MoveFolderRequest'->new($_) } @$_ ] };

declare 'MapStringMoveFolderRequest',
    as HashRef[MoveFolderRequest()];

declare 'GetFolderRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::GetFolderRequest'];

coerce 'GetFolderRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::GetFolderRequest'->new($_) };

declare 'RepeatedGetFolderRequest',
    as ArrayRef[GetFolderRequest()];

coerce 'RepeatedGetFolderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::GetFolderRequest'->new($_) } @$_ ] };

declare 'MapStringGetFolderRequest',
    as HashRef[GetFolderRequest()];

declare 'UpdateFolderRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::UpdateFolderRequest'];

coerce 'UpdateFolderRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::UpdateFolderRequest'->new($_) };

declare 'RepeatedUpdateFolderRequest',
    as ArrayRef[UpdateFolderRequest()];

coerce 'RepeatedUpdateFolderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::UpdateFolderRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateFolderRequest',
    as HashRef[UpdateFolderRequest()];

declare 'DeleteFolderRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::DeleteFolderRequest'];

coerce 'DeleteFolderRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::DeleteFolderRequest'->new($_) };

declare 'RepeatedDeleteFolderRequest',
    as ArrayRef[DeleteFolderRequest()];

coerce 'RepeatedDeleteFolderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::DeleteFolderRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteFolderRequest',
    as HashRef[DeleteFolderRequest()];

declare 'DeleteFolderTreeRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::DeleteFolderTreeRequest'];

coerce 'DeleteFolderTreeRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::DeleteFolderTreeRequest'->new($_) };

declare 'RepeatedDeleteFolderTreeRequest',
    as ArrayRef[DeleteFolderTreeRequest()];

coerce 'RepeatedDeleteFolderTreeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::DeleteFolderTreeRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteFolderTreeRequest',
    as HashRef[DeleteFolderTreeRequest()];

declare 'DeleteTeamFolderTreeRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::DeleteTeamFolderTreeRequest'];

coerce 'DeleteTeamFolderTreeRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::DeleteTeamFolderTreeRequest'->new($_) };

declare 'RepeatedDeleteTeamFolderTreeRequest',
    as ArrayRef[DeleteTeamFolderTreeRequest()];

coerce 'RepeatedDeleteTeamFolderTreeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::DeleteTeamFolderTreeRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTeamFolderTreeRequest',
    as HashRef[DeleteTeamFolderTreeRequest()];

declare 'DeleteFolderTreeMetadata',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::DeleteFolderTreeMetadata'];

coerce 'DeleteFolderTreeMetadata',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::DeleteFolderTreeMetadata'->new($_) };

declare 'RepeatedDeleteFolderTreeMetadata',
    as ArrayRef[DeleteFolderTreeMetadata()];

coerce 'RepeatedDeleteFolderTreeMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::DeleteFolderTreeMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteFolderTreeMetadata',
    as HashRef[DeleteFolderTreeMetadata()];

declare 'State',
    as (Int | Str);

declare 'QueryFolderContentsRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::QueryFolderContentsRequest'];

coerce 'QueryFolderContentsRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::QueryFolderContentsRequest'->new($_) };

declare 'RepeatedQueryFolderContentsRequest',
    as ArrayRef[QueryFolderContentsRequest()];

coerce 'RepeatedQueryFolderContentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::QueryFolderContentsRequest'->new($_) } @$_ ] };

declare 'MapStringQueryFolderContentsRequest',
    as HashRef[QueryFolderContentsRequest()];

declare 'QueryFolderContentsResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::QueryFolderContentsResponse'];

coerce 'QueryFolderContentsResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::QueryFolderContentsResponse'->new($_) };

declare 'RepeatedQueryFolderContentsResponse',
    as ArrayRef[QueryFolderContentsResponse()];

coerce 'RepeatedQueryFolderContentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::QueryFolderContentsResponse'->new($_) } @$_ ] };

declare 'MapStringQueryFolderContentsResponse',
    as HashRef[QueryFolderContentsResponse()];

declare 'FolderContentsEntry',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::QueryFolderContentsResponse::FolderContentsEntry'];

coerce 'FolderContentsEntry',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::QueryFolderContentsResponse::FolderContentsEntry'->new($_) };

declare 'RepeatedFolderContentsEntry',
    as ArrayRef[FolderContentsEntry()];

coerce 'RepeatedFolderContentsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::QueryFolderContentsResponse::FolderContentsEntry'->new($_) } @$_ ] };

declare 'MapStringFolderContentsEntry',
    as HashRef[FolderContentsEntry()];

declare 'QueryUserRootContentsRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::QueryUserRootContentsRequest'];

coerce 'QueryUserRootContentsRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::QueryUserRootContentsRequest'->new($_) };

declare 'RepeatedQueryUserRootContentsRequest',
    as ArrayRef[QueryUserRootContentsRequest()];

coerce 'RepeatedQueryUserRootContentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::QueryUserRootContentsRequest'->new($_) } @$_ ] };

declare 'MapStringQueryUserRootContentsRequest',
    as HashRef[QueryUserRootContentsRequest()];

declare 'QueryUserRootContentsResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::QueryUserRootContentsResponse'];

coerce 'QueryUserRootContentsResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::QueryUserRootContentsResponse'->new($_) };

declare 'RepeatedQueryUserRootContentsResponse',
    as ArrayRef[QueryUserRootContentsResponse()];

coerce 'RepeatedQueryUserRootContentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::QueryUserRootContentsResponse'->new($_) } @$_ ] };

declare 'MapStringQueryUserRootContentsResponse',
    as HashRef[QueryUserRootContentsResponse()];

declare 'RootContentsEntry',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::QueryUserRootContentsResponse::RootContentsEntry'];

coerce 'RootContentsEntry',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::QueryUserRootContentsResponse::RootContentsEntry'->new($_) };

declare 'RepeatedRootContentsEntry',
    as ArrayRef[RootContentsEntry()];

coerce 'RepeatedRootContentsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::QueryUserRootContentsResponse::RootContentsEntry'->new($_) } @$_ ] };

declare 'MapStringRootContentsEntry',
    as HashRef[RootContentsEntry()];

declare 'TeamFolder',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::TeamFolder'];

coerce 'TeamFolder',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::TeamFolder'->new($_) };

declare 'RepeatedTeamFolder',
    as ArrayRef[TeamFolder()];

coerce 'RepeatedTeamFolder',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::TeamFolder'->new($_) } @$_ ] };

declare 'MapStringTeamFolder',
    as HashRef[TeamFolder()];

declare 'CreateTeamFolderRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::CreateTeamFolderRequest'];

coerce 'CreateTeamFolderRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::CreateTeamFolderRequest'->new($_) };

declare 'RepeatedCreateTeamFolderRequest',
    as ArrayRef[CreateTeamFolderRequest()];

coerce 'RepeatedCreateTeamFolderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::CreateTeamFolderRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTeamFolderRequest',
    as HashRef[CreateTeamFolderRequest()];

declare 'GetTeamFolderRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::GetTeamFolderRequest'];

coerce 'GetTeamFolderRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::GetTeamFolderRequest'->new($_) };

declare 'RepeatedGetTeamFolderRequest',
    as ArrayRef[GetTeamFolderRequest()];

coerce 'RepeatedGetTeamFolderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::GetTeamFolderRequest'->new($_) } @$_ ] };

declare 'MapStringGetTeamFolderRequest',
    as HashRef[GetTeamFolderRequest()];

declare 'UpdateTeamFolderRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::UpdateTeamFolderRequest'];

coerce 'UpdateTeamFolderRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::UpdateTeamFolderRequest'->new($_) };

declare 'RepeatedUpdateTeamFolderRequest',
    as ArrayRef[UpdateTeamFolderRequest()];

coerce 'RepeatedUpdateTeamFolderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::UpdateTeamFolderRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTeamFolderRequest',
    as HashRef[UpdateTeamFolderRequest()];

declare 'DeleteTeamFolderRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::DeleteTeamFolderRequest'];

coerce 'DeleteTeamFolderRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::DeleteTeamFolderRequest'->new($_) };

declare 'RepeatedDeleteTeamFolderRequest',
    as ArrayRef[DeleteTeamFolderRequest()];

coerce 'RepeatedDeleteTeamFolderRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::DeleteTeamFolderRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTeamFolderRequest',
    as HashRef[DeleteTeamFolderRequest()];

declare 'QueryTeamFolderContentsRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::QueryTeamFolderContentsRequest'];

coerce 'QueryTeamFolderContentsRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::QueryTeamFolderContentsRequest'->new($_) };

declare 'RepeatedQueryTeamFolderContentsRequest',
    as ArrayRef[QueryTeamFolderContentsRequest()];

coerce 'RepeatedQueryTeamFolderContentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::QueryTeamFolderContentsRequest'->new($_) } @$_ ] };

declare 'MapStringQueryTeamFolderContentsRequest',
    as HashRef[QueryTeamFolderContentsRequest()];

declare 'QueryTeamFolderContentsResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::QueryTeamFolderContentsResponse'];

coerce 'QueryTeamFolderContentsResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::QueryTeamFolderContentsResponse'->new($_) };

declare 'RepeatedQueryTeamFolderContentsResponse',
    as ArrayRef[QueryTeamFolderContentsResponse()];

coerce 'RepeatedQueryTeamFolderContentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::QueryTeamFolderContentsResponse'->new($_) } @$_ ] };

declare 'MapStringQueryTeamFolderContentsResponse',
    as HashRef[QueryTeamFolderContentsResponse()];

declare 'TeamFolderContentsEntry',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::QueryTeamFolderContentsResponse::TeamFolderContentsEntry'];

coerce 'TeamFolderContentsEntry',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::QueryTeamFolderContentsResponse::TeamFolderContentsEntry'->new($_) };

declare 'RepeatedTeamFolderContentsEntry',
    as ArrayRef[TeamFolderContentsEntry()];

coerce 'RepeatedTeamFolderContentsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::QueryTeamFolderContentsResponse::TeamFolderContentsEntry'->new($_) } @$_ ] };

declare 'MapStringTeamFolderContentsEntry',
    as HashRef[TeamFolderContentsEntry()];

declare 'SearchTeamFoldersRequest',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::SearchTeamFoldersRequest'];

coerce 'SearchTeamFoldersRequest',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::SearchTeamFoldersRequest'->new($_) };

declare 'RepeatedSearchTeamFoldersRequest',
    as ArrayRef[SearchTeamFoldersRequest()];

coerce 'RepeatedSearchTeamFoldersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::SearchTeamFoldersRequest'->new($_) } @$_ ] };

declare 'MapStringSearchTeamFoldersRequest',
    as HashRef[SearchTeamFoldersRequest()];

declare 'SearchTeamFoldersResponse',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::SearchTeamFoldersResponse'];

coerce 'SearchTeamFoldersResponse',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::SearchTeamFoldersResponse'->new($_) };

declare 'RepeatedSearchTeamFoldersResponse',
    as ArrayRef[SearchTeamFoldersResponse()];

coerce 'RepeatedSearchTeamFoldersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::SearchTeamFoldersResponse'->new($_) } @$_ ] };

declare 'MapStringSearchTeamFoldersResponse',
    as HashRef[SearchTeamFoldersResponse()];

declare 'TeamFolderSearchResult',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::SearchTeamFoldersResponse::TeamFolderSearchResult'];

coerce 'TeamFolderSearchResult',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::SearchTeamFoldersResponse::TeamFolderSearchResult'->new($_) };

declare 'RepeatedTeamFolderSearchResult',
    as ArrayRef[TeamFolderSearchResult()];

coerce 'RepeatedTeamFolderSearchResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::SearchTeamFoldersResponse::TeamFolderSearchResult'->new($_) } @$_ ] };

declare 'MapStringTeamFolderSearchResult',
    as HashRef[TeamFolderSearchResult()];

declare 'MoveFolderMetadata',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::MoveFolderMetadata'];

coerce 'MoveFolderMetadata',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::MoveFolderMetadata'->new($_) };

declare 'RepeatedMoveFolderMetadata',
    as ArrayRef[MoveFolderMetadata()];

coerce 'RepeatedMoveFolderMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::MoveFolderMetadata'->new($_) } @$_ ] };

declare 'MapStringMoveFolderMetadata',
    as HashRef[MoveFolderMetadata()];

declare 'State',
    as (Int | Str);

declare 'MoveRepositoryMetadata',
    as InstanceOf['Google::Cloud::Dataform::V1::Dataform::MoveRepositoryMetadata'];

coerce 'MoveRepositoryMetadata',
    from HashRef, via { 'Google::Cloud::Dataform::V1::Dataform::MoveRepositoryMetadata'->new($_) };

declare 'RepeatedMoveRepositoryMetadata',
    as ArrayRef[MoveRepositoryMetadata()];

coerce 'RepeatedMoveRepositoryMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataform::V1::Dataform::MoveRepositoryMetadata'->new($_) } @$_ ] };

declare 'MapStringMoveRepositoryMetadata',
    as HashRef[MoveRepositoryMetadata()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Dataform::V1::Dataform::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
