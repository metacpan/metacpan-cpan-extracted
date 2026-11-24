package Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Instance',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Instance'];

coerce 'Instance',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Instance'->new($_) };

declare 'RepeatedInstance',
    as ArrayRef[Instance()];

coerce 'RepeatedInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Instance'->new($_) } @$_ ] };

declare 'MapStringInstance',
    as HashRef[Instance()];

declare 'State',
    as (Int | Str);

declare 'StateNote',
    as (Int | Str);

declare 'HostConfig',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Instance::HostConfig'];

coerce 'HostConfig',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Instance::HostConfig'->new($_) };

declare 'RepeatedHostConfig',
    as ArrayRef[HostConfig()];

coerce 'RepeatedHostConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Instance::HostConfig'->new($_) } @$_ ] };

declare 'MapStringHostConfig',
    as HashRef[HostConfig()];

declare 'PrivateConfig',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Instance::PrivateConfig'];

coerce 'PrivateConfig',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Instance::PrivateConfig'->new($_) };

declare 'RepeatedPrivateConfig',
    as ArrayRef[PrivateConfig()];

coerce 'RepeatedPrivateConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Instance::PrivateConfig'->new($_) } @$_ ] };

declare 'MapStringPrivateConfig',
    as HashRef[PrivateConfig()];

declare 'CustomHostConfig',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Instance::PrivateConfig::CustomHostConfig'];

coerce 'CustomHostConfig',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Instance::PrivateConfig::CustomHostConfig'->new($_) };

declare 'RepeatedCustomHostConfig',
    as ArrayRef[CustomHostConfig()];

coerce 'RepeatedCustomHostConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Instance::PrivateConfig::CustomHostConfig'->new($_) } @$_ ] };

declare 'MapStringCustomHostConfig',
    as HashRef[CustomHostConfig()];

declare 'WorkforceIdentityFederationConfig',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Instance::WorkforceIdentityFederationConfig'];

coerce 'WorkforceIdentityFederationConfig',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Instance::WorkforceIdentityFederationConfig'->new($_) };

declare 'RepeatedWorkforceIdentityFederationConfig',
    as ArrayRef[WorkforceIdentityFederationConfig()];

coerce 'RepeatedWorkforceIdentityFederationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Instance::WorkforceIdentityFederationConfig'->new($_) } @$_ ] };

declare 'MapStringWorkforceIdentityFederationConfig',
    as HashRef[WorkforceIdentityFederationConfig()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Instance::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Instance::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Instance::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Repository',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Repository'];

coerce 'Repository',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Repository'->new($_) };

declare 'RepeatedRepository',
    as ArrayRef[Repository()];

coerce 'RepeatedRepository',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Repository'->new($_) } @$_ ] };

declare 'MapStringRepository',
    as HashRef[Repository()];

declare 'URIs',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Repository::URIs'];

coerce 'URIs',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Repository::URIs'->new($_) };

declare 'RepeatedURIs',
    as ArrayRef[URIs()];

coerce 'RepeatedURIs',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Repository::URIs'->new($_) } @$_ ] };

declare 'MapStringURIs',
    as HashRef[URIs()];

declare 'InitialConfig',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Repository::InitialConfig'];

coerce 'InitialConfig',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Repository::InitialConfig'->new($_) };

declare 'RepeatedInitialConfig',
    as ArrayRef[InitialConfig()];

coerce 'RepeatedInitialConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Repository::InitialConfig'->new($_) } @$_ ] };

declare 'MapStringInitialConfig',
    as HashRef[InitialConfig()];

declare 'ScanConfig',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Repository::ScanConfig'];

coerce 'ScanConfig',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Repository::ScanConfig'->new($_) };

declare 'RepeatedScanConfig',
    as ArrayRef[ScanConfig()];

coerce 'RepeatedScanConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Repository::ScanConfig'->new($_) } @$_ ] };

declare 'MapStringScanConfig',
    as HashRef[ScanConfig()];

declare 'SecretScanConfig',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Repository::ScanConfig::SecretScanConfig'];

coerce 'SecretScanConfig',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Repository::ScanConfig::SecretScanConfig'->new($_) };

declare 'RepeatedSecretScanConfig',
    as ArrayRef[SecretScanConfig()];

coerce 'RepeatedSecretScanConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Repository::ScanConfig::SecretScanConfig'->new($_) } @$_ ] };

declare 'MapStringSecretScanConfig',
    as HashRef[SecretScanConfig()];

declare 'Hook',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Hook'];

coerce 'Hook',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Hook'->new($_) };

declare 'RepeatedHook',
    as ArrayRef[Hook()];

coerce 'RepeatedHook',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Hook'->new($_) } @$_ ] };

declare 'MapStringHook',
    as HashRef[Hook()];

declare 'HookEventType',
    as (Int | Str);

declare 'PushOption',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Hook::PushOption'];

coerce 'PushOption',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Hook::PushOption'->new($_) };

declare 'RepeatedPushOption',
    as ArrayRef[PushOption()];

coerce 'RepeatedPushOption',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Hook::PushOption'->new($_) } @$_ ] };

declare 'MapStringPushOption',
    as HashRef[PushOption()];

declare 'BranchRule',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::BranchRule'];

coerce 'BranchRule',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::BranchRule'->new($_) };

declare 'RepeatedBranchRule',
    as ArrayRef[BranchRule()];

coerce 'RepeatedBranchRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::BranchRule'->new($_) } @$_ ] };

declare 'MapStringBranchRule',
    as HashRef[BranchRule()];

declare 'Check',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::BranchRule::Check'];

coerce 'Check',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::BranchRule::Check'->new($_) };

declare 'RepeatedCheck',
    as ArrayRef[Check()];

coerce 'RepeatedCheck',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::BranchRule::Check'->new($_) } @$_ ] };

declare 'MapStringCheck',
    as HashRef[Check()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::BranchRule::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::BranchRule::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::BranchRule::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'PullRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::PullRequest'];

coerce 'PullRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::PullRequest'->new($_) };

declare 'RepeatedPullRequest',
    as ArrayRef[PullRequest()];

coerce 'RepeatedPullRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::PullRequest'->new($_) } @$_ ] };

declare 'MapStringPullRequest',
    as HashRef[PullRequest()];

declare 'State',
    as (Int | Str);

declare 'Branch',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::PullRequest::Branch'];

coerce 'Branch',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::PullRequest::Branch'->new($_) };

declare 'RepeatedBranch',
    as ArrayRef[Branch()];

coerce 'RepeatedBranch',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::PullRequest::Branch'->new($_) } @$_ ] };

declare 'MapStringBranch',
    as HashRef[Branch()];

declare 'FileDiff',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::FileDiff'];

coerce 'FileDiff',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::FileDiff'->new($_) };

declare 'RepeatedFileDiff',
    as ArrayRef[FileDiff()];

coerce 'RepeatedFileDiff',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::FileDiff'->new($_) } @$_ ] };

declare 'MapStringFileDiff',
    as HashRef[FileDiff()];

declare 'Action',
    as (Int | Str);

declare 'Issue',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Issue'];

coerce 'Issue',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Issue'->new($_) };

declare 'RepeatedIssue',
    as ArrayRef[Issue()];

coerce 'RepeatedIssue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Issue'->new($_) } @$_ ] };

declare 'MapStringIssue',
    as HashRef[Issue()];

declare 'State',
    as (Int | Str);

declare 'IssueComment',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::IssueComment'];

coerce 'IssueComment',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::IssueComment'->new($_) };

declare 'RepeatedIssueComment',
    as ArrayRef[IssueComment()];

coerce 'RepeatedIssueComment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::IssueComment'->new($_) } @$_ ] };

declare 'MapStringIssueComment',
    as HashRef[IssueComment()];

declare 'PullRequestComment',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::PullRequestComment'];

coerce 'PullRequestComment',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::PullRequestComment'->new($_) };

declare 'RepeatedPullRequestComment',
    as ArrayRef[PullRequestComment()];

coerce 'RepeatedPullRequestComment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::PullRequestComment'->new($_) } @$_ ] };

declare 'MapStringPullRequestComment',
    as HashRef[PullRequestComment()];

declare 'Review',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::PullRequestComment::Review'];

coerce 'Review',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::PullRequestComment::Review'->new($_) };

declare 'RepeatedReview',
    as ArrayRef[Review()];

coerce 'RepeatedReview',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::PullRequestComment::Review'->new($_) } @$_ ] };

declare 'MapStringReview',
    as HashRef[Review()];

declare 'ActionType',
    as (Int | Str);

declare 'Comment',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::PullRequestComment::Comment'];

coerce 'Comment',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::PullRequestComment::Comment'->new($_) };

declare 'RepeatedComment',
    as ArrayRef[Comment()];

coerce 'RepeatedComment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::PullRequestComment::Comment'->new($_) } @$_ ] };

declare 'MapStringComment',
    as HashRef[Comment()];

declare 'Code',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::PullRequestComment::Code'];

coerce 'Code',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::PullRequestComment::Code'->new($_) };

declare 'RepeatedCode',
    as ArrayRef[Code()];

coerce 'RepeatedCode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::PullRequestComment::Code'->new($_) } @$_ ] };

declare 'MapStringCode',
    as HashRef[Code()];

declare 'Position',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::PullRequestComment::Position'];

coerce 'Position',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::PullRequestComment::Position'->new($_) };

declare 'RepeatedPosition',
    as ArrayRef[Position()];

coerce 'RepeatedPosition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::PullRequestComment::Position'->new($_) } @$_ ] };

declare 'MapStringPosition',
    as HashRef[Position()];

declare 'Ref',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Ref'];

coerce 'Ref',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Ref'->new($_) };

declare 'RepeatedRef',
    as ArrayRef[Ref()];

coerce 'RepeatedRef',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Ref'->new($_) } @$_ ] };

declare 'MapStringRef',
    as HashRef[Ref()];

declare 'RefType',
    as (Int | Str);

declare 'ListInstancesRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListInstancesRequest'];

coerce 'ListInstancesRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListInstancesRequest'->new($_) };

declare 'RepeatedListInstancesRequest',
    as ArrayRef[ListInstancesRequest()];

coerce 'RepeatedListInstancesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListInstancesRequest'->new($_) } @$_ ] };

declare 'MapStringListInstancesRequest',
    as HashRef[ListInstancesRequest()];

declare 'ListInstancesResponse',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListInstancesResponse'];

coerce 'ListInstancesResponse',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListInstancesResponse'->new($_) };

declare 'RepeatedListInstancesResponse',
    as ArrayRef[ListInstancesResponse()];

coerce 'RepeatedListInstancesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListInstancesResponse'->new($_) } @$_ ] };

declare 'MapStringListInstancesResponse',
    as HashRef[ListInstancesResponse()];

declare 'GetInstanceRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::GetInstanceRequest'];

coerce 'GetInstanceRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::GetInstanceRequest'->new($_) };

declare 'RepeatedGetInstanceRequest',
    as ArrayRef[GetInstanceRequest()];

coerce 'RepeatedGetInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::GetInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringGetInstanceRequest',
    as HashRef[GetInstanceRequest()];

declare 'CreateInstanceRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::CreateInstanceRequest'];

coerce 'CreateInstanceRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::CreateInstanceRequest'->new($_) };

declare 'RepeatedCreateInstanceRequest',
    as ArrayRef[CreateInstanceRequest()];

coerce 'RepeatedCreateInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::CreateInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateInstanceRequest',
    as HashRef[CreateInstanceRequest()];

declare 'DeleteInstanceRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::DeleteInstanceRequest'];

coerce 'DeleteInstanceRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::DeleteInstanceRequest'->new($_) };

declare 'RepeatedDeleteInstanceRequest',
    as ArrayRef[DeleteInstanceRequest()];

coerce 'RepeatedDeleteInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::DeleteInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteInstanceRequest',
    as HashRef[DeleteInstanceRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'ListRepositoriesRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListRepositoriesRequest'];

coerce 'ListRepositoriesRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListRepositoriesRequest'->new($_) };

declare 'RepeatedListRepositoriesRequest',
    as ArrayRef[ListRepositoriesRequest()];

coerce 'RepeatedListRepositoriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListRepositoriesRequest'->new($_) } @$_ ] };

declare 'MapStringListRepositoriesRequest',
    as HashRef[ListRepositoriesRequest()];

declare 'ListRepositoriesResponse',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListRepositoriesResponse'];

coerce 'ListRepositoriesResponse',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListRepositoriesResponse'->new($_) };

declare 'RepeatedListRepositoriesResponse',
    as ArrayRef[ListRepositoriesResponse()];

coerce 'RepeatedListRepositoriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListRepositoriesResponse'->new($_) } @$_ ] };

declare 'MapStringListRepositoriesResponse',
    as HashRef[ListRepositoriesResponse()];

declare 'GetRepositoryRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::GetRepositoryRequest'];

coerce 'GetRepositoryRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::GetRepositoryRequest'->new($_) };

declare 'RepeatedGetRepositoryRequest',
    as ArrayRef[GetRepositoryRequest()];

coerce 'RepeatedGetRepositoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::GetRepositoryRequest'->new($_) } @$_ ] };

declare 'MapStringGetRepositoryRequest',
    as HashRef[GetRepositoryRequest()];

declare 'CreateRepositoryRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::CreateRepositoryRequest'];

coerce 'CreateRepositoryRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::CreateRepositoryRequest'->new($_) };

declare 'RepeatedCreateRepositoryRequest',
    as ArrayRef[CreateRepositoryRequest()];

coerce 'RepeatedCreateRepositoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::CreateRepositoryRequest'->new($_) } @$_ ] };

declare 'MapStringCreateRepositoryRequest',
    as HashRef[CreateRepositoryRequest()];

declare 'UpdateRepositoryRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::UpdateRepositoryRequest'];

coerce 'UpdateRepositoryRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::UpdateRepositoryRequest'->new($_) };

declare 'RepeatedUpdateRepositoryRequest',
    as ArrayRef[UpdateRepositoryRequest()];

coerce 'RepeatedUpdateRepositoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::UpdateRepositoryRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateRepositoryRequest',
    as HashRef[UpdateRepositoryRequest()];

declare 'DeleteRepositoryRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::DeleteRepositoryRequest'];

coerce 'DeleteRepositoryRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::DeleteRepositoryRequest'->new($_) };

declare 'RepeatedDeleteRepositoryRequest',
    as ArrayRef[DeleteRepositoryRequest()];

coerce 'RepeatedDeleteRepositoryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::DeleteRepositoryRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteRepositoryRequest',
    as HashRef[DeleteRepositoryRequest()];

declare 'ListHooksRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListHooksRequest'];

coerce 'ListHooksRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListHooksRequest'->new($_) };

declare 'RepeatedListHooksRequest',
    as ArrayRef[ListHooksRequest()];

coerce 'RepeatedListHooksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListHooksRequest'->new($_) } @$_ ] };

declare 'MapStringListHooksRequest',
    as HashRef[ListHooksRequest()];

declare 'ListHooksResponse',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListHooksResponse'];

coerce 'ListHooksResponse',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListHooksResponse'->new($_) };

declare 'RepeatedListHooksResponse',
    as ArrayRef[ListHooksResponse()];

coerce 'RepeatedListHooksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListHooksResponse'->new($_) } @$_ ] };

declare 'MapStringListHooksResponse',
    as HashRef[ListHooksResponse()];

declare 'GetHookRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::GetHookRequest'];

coerce 'GetHookRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::GetHookRequest'->new($_) };

declare 'RepeatedGetHookRequest',
    as ArrayRef[GetHookRequest()];

coerce 'RepeatedGetHookRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::GetHookRequest'->new($_) } @$_ ] };

declare 'MapStringGetHookRequest',
    as HashRef[GetHookRequest()];

declare 'CreateHookRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::CreateHookRequest'];

coerce 'CreateHookRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::CreateHookRequest'->new($_) };

declare 'RepeatedCreateHookRequest',
    as ArrayRef[CreateHookRequest()];

coerce 'RepeatedCreateHookRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::CreateHookRequest'->new($_) } @$_ ] };

declare 'MapStringCreateHookRequest',
    as HashRef[CreateHookRequest()];

declare 'UpdateHookRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::UpdateHookRequest'];

coerce 'UpdateHookRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::UpdateHookRequest'->new($_) };

declare 'RepeatedUpdateHookRequest',
    as ArrayRef[UpdateHookRequest()];

coerce 'RepeatedUpdateHookRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::UpdateHookRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateHookRequest',
    as HashRef[UpdateHookRequest()];

declare 'DeleteHookRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::DeleteHookRequest'];

coerce 'DeleteHookRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::DeleteHookRequest'->new($_) };

declare 'RepeatedDeleteHookRequest',
    as ArrayRef[DeleteHookRequest()];

coerce 'RepeatedDeleteHookRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::DeleteHookRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteHookRequest',
    as HashRef[DeleteHookRequest()];

declare 'GetBranchRuleRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::GetBranchRuleRequest'];

coerce 'GetBranchRuleRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::GetBranchRuleRequest'->new($_) };

declare 'RepeatedGetBranchRuleRequest',
    as ArrayRef[GetBranchRuleRequest()];

coerce 'RepeatedGetBranchRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::GetBranchRuleRequest'->new($_) } @$_ ] };

declare 'MapStringGetBranchRuleRequest',
    as HashRef[GetBranchRuleRequest()];

declare 'CreateBranchRuleRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::CreateBranchRuleRequest'];

coerce 'CreateBranchRuleRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::CreateBranchRuleRequest'->new($_) };

declare 'RepeatedCreateBranchRuleRequest',
    as ArrayRef[CreateBranchRuleRequest()];

coerce 'RepeatedCreateBranchRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::CreateBranchRuleRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBranchRuleRequest',
    as HashRef[CreateBranchRuleRequest()];

declare 'ListBranchRulesRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListBranchRulesRequest'];

coerce 'ListBranchRulesRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListBranchRulesRequest'->new($_) };

declare 'RepeatedListBranchRulesRequest',
    as ArrayRef[ListBranchRulesRequest()];

coerce 'RepeatedListBranchRulesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListBranchRulesRequest'->new($_) } @$_ ] };

declare 'MapStringListBranchRulesRequest',
    as HashRef[ListBranchRulesRequest()];

declare 'DeleteBranchRuleRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::DeleteBranchRuleRequest'];

coerce 'DeleteBranchRuleRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::DeleteBranchRuleRequest'->new($_) };

declare 'RepeatedDeleteBranchRuleRequest',
    as ArrayRef[DeleteBranchRuleRequest()];

coerce 'RepeatedDeleteBranchRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::DeleteBranchRuleRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBranchRuleRequest',
    as HashRef[DeleteBranchRuleRequest()];

declare 'UpdateBranchRuleRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::UpdateBranchRuleRequest'];

coerce 'UpdateBranchRuleRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::UpdateBranchRuleRequest'->new($_) };

declare 'RepeatedUpdateBranchRuleRequest',
    as ArrayRef[UpdateBranchRuleRequest()];

coerce 'RepeatedUpdateBranchRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::UpdateBranchRuleRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBranchRuleRequest',
    as HashRef[UpdateBranchRuleRequest()];

declare 'ListBranchRulesResponse',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListBranchRulesResponse'];

coerce 'ListBranchRulesResponse',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListBranchRulesResponse'->new($_) };

declare 'RepeatedListBranchRulesResponse',
    as ArrayRef[ListBranchRulesResponse()];

coerce 'RepeatedListBranchRulesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListBranchRulesResponse'->new($_) } @$_ ] };

declare 'MapStringListBranchRulesResponse',
    as HashRef[ListBranchRulesResponse()];

declare 'CreatePullRequestRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::CreatePullRequestRequest'];

coerce 'CreatePullRequestRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::CreatePullRequestRequest'->new($_) };

declare 'RepeatedCreatePullRequestRequest',
    as ArrayRef[CreatePullRequestRequest()];

coerce 'RepeatedCreatePullRequestRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::CreatePullRequestRequest'->new($_) } @$_ ] };

declare 'MapStringCreatePullRequestRequest',
    as HashRef[CreatePullRequestRequest()];

declare 'GetPullRequestRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::GetPullRequestRequest'];

coerce 'GetPullRequestRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::GetPullRequestRequest'->new($_) };

declare 'RepeatedGetPullRequestRequest',
    as ArrayRef[GetPullRequestRequest()];

coerce 'RepeatedGetPullRequestRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::GetPullRequestRequest'->new($_) } @$_ ] };

declare 'MapStringGetPullRequestRequest',
    as HashRef[GetPullRequestRequest()];

declare 'ListPullRequestsRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListPullRequestsRequest'];

coerce 'ListPullRequestsRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListPullRequestsRequest'->new($_) };

declare 'RepeatedListPullRequestsRequest',
    as ArrayRef[ListPullRequestsRequest()];

coerce 'RepeatedListPullRequestsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListPullRequestsRequest'->new($_) } @$_ ] };

declare 'MapStringListPullRequestsRequest',
    as HashRef[ListPullRequestsRequest()];

declare 'ListPullRequestsResponse',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListPullRequestsResponse'];

coerce 'ListPullRequestsResponse',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListPullRequestsResponse'->new($_) };

declare 'RepeatedListPullRequestsResponse',
    as ArrayRef[ListPullRequestsResponse()];

coerce 'RepeatedListPullRequestsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListPullRequestsResponse'->new($_) } @$_ ] };

declare 'MapStringListPullRequestsResponse',
    as HashRef[ListPullRequestsResponse()];

declare 'UpdatePullRequestRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::UpdatePullRequestRequest'];

coerce 'UpdatePullRequestRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::UpdatePullRequestRequest'->new($_) };

declare 'RepeatedUpdatePullRequestRequest',
    as ArrayRef[UpdatePullRequestRequest()];

coerce 'RepeatedUpdatePullRequestRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::UpdatePullRequestRequest'->new($_) } @$_ ] };

declare 'MapStringUpdatePullRequestRequest',
    as HashRef[UpdatePullRequestRequest()];

declare 'MergePullRequestRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::MergePullRequestRequest'];

coerce 'MergePullRequestRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::MergePullRequestRequest'->new($_) };

declare 'RepeatedMergePullRequestRequest',
    as ArrayRef[MergePullRequestRequest()];

coerce 'RepeatedMergePullRequestRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::MergePullRequestRequest'->new($_) } @$_ ] };

declare 'MapStringMergePullRequestRequest',
    as HashRef[MergePullRequestRequest()];

declare 'OpenPullRequestRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::OpenPullRequestRequest'];

coerce 'OpenPullRequestRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::OpenPullRequestRequest'->new($_) };

declare 'RepeatedOpenPullRequestRequest',
    as ArrayRef[OpenPullRequestRequest()];

coerce 'RepeatedOpenPullRequestRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::OpenPullRequestRequest'->new($_) } @$_ ] };

declare 'MapStringOpenPullRequestRequest',
    as HashRef[OpenPullRequestRequest()];

declare 'ClosePullRequestRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ClosePullRequestRequest'];

coerce 'ClosePullRequestRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ClosePullRequestRequest'->new($_) };

declare 'RepeatedClosePullRequestRequest',
    as ArrayRef[ClosePullRequestRequest()];

coerce 'RepeatedClosePullRequestRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ClosePullRequestRequest'->new($_) } @$_ ] };

declare 'MapStringClosePullRequestRequest',
    as HashRef[ClosePullRequestRequest()];

declare 'ListPullRequestFileDiffsRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListPullRequestFileDiffsRequest'];

coerce 'ListPullRequestFileDiffsRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListPullRequestFileDiffsRequest'->new($_) };

declare 'RepeatedListPullRequestFileDiffsRequest',
    as ArrayRef[ListPullRequestFileDiffsRequest()];

coerce 'RepeatedListPullRequestFileDiffsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListPullRequestFileDiffsRequest'->new($_) } @$_ ] };

declare 'MapStringListPullRequestFileDiffsRequest',
    as HashRef[ListPullRequestFileDiffsRequest()];

declare 'ListPullRequestFileDiffsResponse',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListPullRequestFileDiffsResponse'];

coerce 'ListPullRequestFileDiffsResponse',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListPullRequestFileDiffsResponse'->new($_) };

declare 'RepeatedListPullRequestFileDiffsResponse',
    as ArrayRef[ListPullRequestFileDiffsResponse()];

coerce 'RepeatedListPullRequestFileDiffsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListPullRequestFileDiffsResponse'->new($_) } @$_ ] };

declare 'MapStringListPullRequestFileDiffsResponse',
    as HashRef[ListPullRequestFileDiffsResponse()];

declare 'CreateIssueRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::CreateIssueRequest'];

coerce 'CreateIssueRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::CreateIssueRequest'->new($_) };

declare 'RepeatedCreateIssueRequest',
    as ArrayRef[CreateIssueRequest()];

coerce 'RepeatedCreateIssueRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::CreateIssueRequest'->new($_) } @$_ ] };

declare 'MapStringCreateIssueRequest',
    as HashRef[CreateIssueRequest()];

declare 'GetIssueRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::GetIssueRequest'];

coerce 'GetIssueRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::GetIssueRequest'->new($_) };

declare 'RepeatedGetIssueRequest',
    as ArrayRef[GetIssueRequest()];

coerce 'RepeatedGetIssueRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::GetIssueRequest'->new($_) } @$_ ] };

declare 'MapStringGetIssueRequest',
    as HashRef[GetIssueRequest()];

declare 'ListIssuesRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListIssuesRequest'];

coerce 'ListIssuesRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListIssuesRequest'->new($_) };

declare 'RepeatedListIssuesRequest',
    as ArrayRef[ListIssuesRequest()];

coerce 'RepeatedListIssuesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListIssuesRequest'->new($_) } @$_ ] };

declare 'MapStringListIssuesRequest',
    as HashRef[ListIssuesRequest()];

declare 'ListIssuesResponse',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListIssuesResponse'];

coerce 'ListIssuesResponse',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListIssuesResponse'->new($_) };

declare 'RepeatedListIssuesResponse',
    as ArrayRef[ListIssuesResponse()];

coerce 'RepeatedListIssuesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListIssuesResponse'->new($_) } @$_ ] };

declare 'MapStringListIssuesResponse',
    as HashRef[ListIssuesResponse()];

declare 'UpdateIssueRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::UpdateIssueRequest'];

coerce 'UpdateIssueRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::UpdateIssueRequest'->new($_) };

declare 'RepeatedUpdateIssueRequest',
    as ArrayRef[UpdateIssueRequest()];

coerce 'RepeatedUpdateIssueRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::UpdateIssueRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateIssueRequest',
    as HashRef[UpdateIssueRequest()];

declare 'DeleteIssueRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::DeleteIssueRequest'];

coerce 'DeleteIssueRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::DeleteIssueRequest'->new($_) };

declare 'RepeatedDeleteIssueRequest',
    as ArrayRef[DeleteIssueRequest()];

coerce 'RepeatedDeleteIssueRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::DeleteIssueRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteIssueRequest',
    as HashRef[DeleteIssueRequest()];

declare 'CloseIssueRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::CloseIssueRequest'];

coerce 'CloseIssueRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::CloseIssueRequest'->new($_) };

declare 'RepeatedCloseIssueRequest',
    as ArrayRef[CloseIssueRequest()];

coerce 'RepeatedCloseIssueRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::CloseIssueRequest'->new($_) } @$_ ] };

declare 'MapStringCloseIssueRequest',
    as HashRef[CloseIssueRequest()];

declare 'OpenIssueRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::OpenIssueRequest'];

coerce 'OpenIssueRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::OpenIssueRequest'->new($_) };

declare 'RepeatedOpenIssueRequest',
    as ArrayRef[OpenIssueRequest()];

coerce 'RepeatedOpenIssueRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::OpenIssueRequest'->new($_) } @$_ ] };

declare 'MapStringOpenIssueRequest',
    as HashRef[OpenIssueRequest()];

declare 'TreeEntry',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::TreeEntry'];

coerce 'TreeEntry',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::TreeEntry'->new($_) };

declare 'RepeatedTreeEntry',
    as ArrayRef[TreeEntry()];

coerce 'RepeatedTreeEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::TreeEntry'->new($_) } @$_ ] };

declare 'MapStringTreeEntry',
    as HashRef[TreeEntry()];

declare 'ObjectType',
    as (Int | Str);

declare 'FetchTreeRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::FetchTreeRequest'];

coerce 'FetchTreeRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::FetchTreeRequest'->new($_) };

declare 'RepeatedFetchTreeRequest',
    as ArrayRef[FetchTreeRequest()];

coerce 'RepeatedFetchTreeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::FetchTreeRequest'->new($_) } @$_ ] };

declare 'MapStringFetchTreeRequest',
    as HashRef[FetchTreeRequest()];

declare 'FetchTreeResponse',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::FetchTreeResponse'];

coerce 'FetchTreeResponse',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::FetchTreeResponse'->new($_) };

declare 'RepeatedFetchTreeResponse',
    as ArrayRef[FetchTreeResponse()];

coerce 'RepeatedFetchTreeResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::FetchTreeResponse'->new($_) } @$_ ] };

declare 'MapStringFetchTreeResponse',
    as HashRef[FetchTreeResponse()];

declare 'FetchBlobRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::FetchBlobRequest'];

coerce 'FetchBlobRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::FetchBlobRequest'->new($_) };

declare 'RepeatedFetchBlobRequest',
    as ArrayRef[FetchBlobRequest()];

coerce 'RepeatedFetchBlobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::FetchBlobRequest'->new($_) } @$_ ] };

declare 'MapStringFetchBlobRequest',
    as HashRef[FetchBlobRequest()];

declare 'FetchBlobResponse',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::FetchBlobResponse'];

coerce 'FetchBlobResponse',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::FetchBlobResponse'->new($_) };

declare 'RepeatedFetchBlobResponse',
    as ArrayRef[FetchBlobResponse()];

coerce 'RepeatedFetchBlobResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::FetchBlobResponse'->new($_) } @$_ ] };

declare 'MapStringFetchBlobResponse',
    as HashRef[FetchBlobResponse()];

declare 'FetchRefsRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::FetchRefsRequest'];

coerce 'FetchRefsRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::FetchRefsRequest'->new($_) };

declare 'RepeatedFetchRefsRequest',
    as ArrayRef[FetchRefsRequest()];

coerce 'RepeatedFetchRefsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::FetchRefsRequest'->new($_) } @$_ ] };

declare 'MapStringFetchRefsRequest',
    as HashRef[FetchRefsRequest()];

declare 'FetchRefsResponse',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::FetchRefsResponse'];

coerce 'FetchRefsResponse',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::FetchRefsResponse'->new($_) };

declare 'RepeatedFetchRefsResponse',
    as ArrayRef[FetchRefsResponse()];

coerce 'RepeatedFetchRefsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::FetchRefsResponse'->new($_) } @$_ ] };

declare 'MapStringFetchRefsResponse',
    as HashRef[FetchRefsResponse()];

declare 'ListPullRequestCommentsRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListPullRequestCommentsRequest'];

coerce 'ListPullRequestCommentsRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListPullRequestCommentsRequest'->new($_) };

declare 'RepeatedListPullRequestCommentsRequest',
    as ArrayRef[ListPullRequestCommentsRequest()];

coerce 'RepeatedListPullRequestCommentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListPullRequestCommentsRequest'->new($_) } @$_ ] };

declare 'MapStringListPullRequestCommentsRequest',
    as HashRef[ListPullRequestCommentsRequest()];

declare 'ListPullRequestCommentsResponse',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListPullRequestCommentsResponse'];

coerce 'ListPullRequestCommentsResponse',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListPullRequestCommentsResponse'->new($_) };

declare 'RepeatedListPullRequestCommentsResponse',
    as ArrayRef[ListPullRequestCommentsResponse()];

coerce 'RepeatedListPullRequestCommentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListPullRequestCommentsResponse'->new($_) } @$_ ] };

declare 'MapStringListPullRequestCommentsResponse',
    as HashRef[ListPullRequestCommentsResponse()];

declare 'CreatePullRequestCommentRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::CreatePullRequestCommentRequest'];

coerce 'CreatePullRequestCommentRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::CreatePullRequestCommentRequest'->new($_) };

declare 'RepeatedCreatePullRequestCommentRequest',
    as ArrayRef[CreatePullRequestCommentRequest()];

coerce 'RepeatedCreatePullRequestCommentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::CreatePullRequestCommentRequest'->new($_) } @$_ ] };

declare 'MapStringCreatePullRequestCommentRequest',
    as HashRef[CreatePullRequestCommentRequest()];

declare 'BatchCreatePullRequestCommentsRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::BatchCreatePullRequestCommentsRequest'];

coerce 'BatchCreatePullRequestCommentsRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::BatchCreatePullRequestCommentsRequest'->new($_) };

declare 'RepeatedBatchCreatePullRequestCommentsRequest',
    as ArrayRef[BatchCreatePullRequestCommentsRequest()];

coerce 'RepeatedBatchCreatePullRequestCommentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::BatchCreatePullRequestCommentsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchCreatePullRequestCommentsRequest',
    as HashRef[BatchCreatePullRequestCommentsRequest()];

declare 'BatchCreatePullRequestCommentsResponse',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::BatchCreatePullRequestCommentsResponse'];

coerce 'BatchCreatePullRequestCommentsResponse',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::BatchCreatePullRequestCommentsResponse'->new($_) };

declare 'RepeatedBatchCreatePullRequestCommentsResponse',
    as ArrayRef[BatchCreatePullRequestCommentsResponse()];

coerce 'RepeatedBatchCreatePullRequestCommentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::BatchCreatePullRequestCommentsResponse'->new($_) } @$_ ] };

declare 'MapStringBatchCreatePullRequestCommentsResponse',
    as HashRef[BatchCreatePullRequestCommentsResponse()];

declare 'UpdatePullRequestCommentRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::UpdatePullRequestCommentRequest'];

coerce 'UpdatePullRequestCommentRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::UpdatePullRequestCommentRequest'->new($_) };

declare 'RepeatedUpdatePullRequestCommentRequest',
    as ArrayRef[UpdatePullRequestCommentRequest()];

coerce 'RepeatedUpdatePullRequestCommentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::UpdatePullRequestCommentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdatePullRequestCommentRequest',
    as HashRef[UpdatePullRequestCommentRequest()];

declare 'DeletePullRequestCommentRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::DeletePullRequestCommentRequest'];

coerce 'DeletePullRequestCommentRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::DeletePullRequestCommentRequest'->new($_) };

declare 'RepeatedDeletePullRequestCommentRequest',
    as ArrayRef[DeletePullRequestCommentRequest()];

coerce 'RepeatedDeletePullRequestCommentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::DeletePullRequestCommentRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePullRequestCommentRequest',
    as HashRef[DeletePullRequestCommentRequest()];

declare 'GetPullRequestCommentRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::GetPullRequestCommentRequest'];

coerce 'GetPullRequestCommentRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::GetPullRequestCommentRequest'->new($_) };

declare 'RepeatedGetPullRequestCommentRequest',
    as ArrayRef[GetPullRequestCommentRequest()];

coerce 'RepeatedGetPullRequestCommentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::GetPullRequestCommentRequest'->new($_) } @$_ ] };

declare 'MapStringGetPullRequestCommentRequest',
    as HashRef[GetPullRequestCommentRequest()];

declare 'ResolvePullRequestCommentsRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ResolvePullRequestCommentsRequest'];

coerce 'ResolvePullRequestCommentsRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ResolvePullRequestCommentsRequest'->new($_) };

declare 'RepeatedResolvePullRequestCommentsRequest',
    as ArrayRef[ResolvePullRequestCommentsRequest()];

coerce 'RepeatedResolvePullRequestCommentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ResolvePullRequestCommentsRequest'->new($_) } @$_ ] };

declare 'MapStringResolvePullRequestCommentsRequest',
    as HashRef[ResolvePullRequestCommentsRequest()];

declare 'ResolvePullRequestCommentsResponse',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ResolvePullRequestCommentsResponse'];

coerce 'ResolvePullRequestCommentsResponse',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ResolvePullRequestCommentsResponse'->new($_) };

declare 'RepeatedResolvePullRequestCommentsResponse',
    as ArrayRef[ResolvePullRequestCommentsResponse()];

coerce 'RepeatedResolvePullRequestCommentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ResolvePullRequestCommentsResponse'->new($_) } @$_ ] };

declare 'MapStringResolvePullRequestCommentsResponse',
    as HashRef[ResolvePullRequestCommentsResponse()];

declare 'UnresolvePullRequestCommentsRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::UnresolvePullRequestCommentsRequest'];

coerce 'UnresolvePullRequestCommentsRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::UnresolvePullRequestCommentsRequest'->new($_) };

declare 'RepeatedUnresolvePullRequestCommentsRequest',
    as ArrayRef[UnresolvePullRequestCommentsRequest()];

coerce 'RepeatedUnresolvePullRequestCommentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::UnresolvePullRequestCommentsRequest'->new($_) } @$_ ] };

declare 'MapStringUnresolvePullRequestCommentsRequest',
    as HashRef[UnresolvePullRequestCommentsRequest()];

declare 'UnresolvePullRequestCommentsResponse',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::UnresolvePullRequestCommentsResponse'];

coerce 'UnresolvePullRequestCommentsResponse',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::UnresolvePullRequestCommentsResponse'->new($_) };

declare 'RepeatedUnresolvePullRequestCommentsResponse',
    as ArrayRef[UnresolvePullRequestCommentsResponse()];

coerce 'RepeatedUnresolvePullRequestCommentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::UnresolvePullRequestCommentsResponse'->new($_) } @$_ ] };

declare 'MapStringUnresolvePullRequestCommentsResponse',
    as HashRef[UnresolvePullRequestCommentsResponse()];

declare 'CreateIssueCommentRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::CreateIssueCommentRequest'];

coerce 'CreateIssueCommentRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::CreateIssueCommentRequest'->new($_) };

declare 'RepeatedCreateIssueCommentRequest',
    as ArrayRef[CreateIssueCommentRequest()];

coerce 'RepeatedCreateIssueCommentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::CreateIssueCommentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateIssueCommentRequest',
    as HashRef[CreateIssueCommentRequest()];

declare 'GetIssueCommentRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::GetIssueCommentRequest'];

coerce 'GetIssueCommentRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::GetIssueCommentRequest'->new($_) };

declare 'RepeatedGetIssueCommentRequest',
    as ArrayRef[GetIssueCommentRequest()];

coerce 'RepeatedGetIssueCommentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::GetIssueCommentRequest'->new($_) } @$_ ] };

declare 'MapStringGetIssueCommentRequest',
    as HashRef[GetIssueCommentRequest()];

declare 'ListIssueCommentsRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListIssueCommentsRequest'];

coerce 'ListIssueCommentsRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListIssueCommentsRequest'->new($_) };

declare 'RepeatedListIssueCommentsRequest',
    as ArrayRef[ListIssueCommentsRequest()];

coerce 'RepeatedListIssueCommentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListIssueCommentsRequest'->new($_) } @$_ ] };

declare 'MapStringListIssueCommentsRequest',
    as HashRef[ListIssueCommentsRequest()];

declare 'ListIssueCommentsResponse',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListIssueCommentsResponse'];

coerce 'ListIssueCommentsResponse',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListIssueCommentsResponse'->new($_) };

declare 'RepeatedListIssueCommentsResponse',
    as ArrayRef[ListIssueCommentsResponse()];

coerce 'RepeatedListIssueCommentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::ListIssueCommentsResponse'->new($_) } @$_ ] };

declare 'MapStringListIssueCommentsResponse',
    as HashRef[ListIssueCommentsResponse()];

declare 'UpdateIssueCommentRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::UpdateIssueCommentRequest'];

coerce 'UpdateIssueCommentRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::UpdateIssueCommentRequest'->new($_) };

declare 'RepeatedUpdateIssueCommentRequest',
    as ArrayRef[UpdateIssueCommentRequest()];

coerce 'RepeatedUpdateIssueCommentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::UpdateIssueCommentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateIssueCommentRequest',
    as HashRef[UpdateIssueCommentRequest()];

declare 'DeleteIssueCommentRequest',
    as InstanceOf['Google::Cloud::Securesourcemanager::V1::SecureSourceManager::DeleteIssueCommentRequest'];

coerce 'DeleteIssueCommentRequest',
    from HashRef, via { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::DeleteIssueCommentRequest'->new($_) };

declare 'RepeatedDeleteIssueCommentRequest',
    as ArrayRef[DeleteIssueCommentRequest()];

coerce 'RepeatedDeleteIssueCommentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securesourcemanager::V1::SecureSourceManager::DeleteIssueCommentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteIssueCommentRequest',
    as HashRef[DeleteIssueCommentRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Securesourcemanager::V1::SecureSourceManager::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
