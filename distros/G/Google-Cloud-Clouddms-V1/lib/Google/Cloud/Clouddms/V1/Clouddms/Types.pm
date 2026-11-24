package Google::Cloud::Clouddms::V1::Clouddms::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DatabaseEntityView',
    as (Int | Str);

declare 'ListMigrationJobsRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::ListMigrationJobsRequest'];

coerce 'ListMigrationJobsRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::ListMigrationJobsRequest'->new($_) };

declare 'RepeatedListMigrationJobsRequest',
    as ArrayRef[ListMigrationJobsRequest()];

coerce 'RepeatedListMigrationJobsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::ListMigrationJobsRequest'->new($_) } @$_ ] };

declare 'MapStringListMigrationJobsRequest',
    as HashRef[ListMigrationJobsRequest()];

declare 'ListMigrationJobsResponse',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::ListMigrationJobsResponse'];

coerce 'ListMigrationJobsResponse',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::ListMigrationJobsResponse'->new($_) };

declare 'RepeatedListMigrationJobsResponse',
    as ArrayRef[ListMigrationJobsResponse()];

coerce 'RepeatedListMigrationJobsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::ListMigrationJobsResponse'->new($_) } @$_ ] };

declare 'MapStringListMigrationJobsResponse',
    as HashRef[ListMigrationJobsResponse()];

declare 'GetMigrationJobRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::GetMigrationJobRequest'];

coerce 'GetMigrationJobRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::GetMigrationJobRequest'->new($_) };

declare 'RepeatedGetMigrationJobRequest',
    as ArrayRef[GetMigrationJobRequest()];

coerce 'RepeatedGetMigrationJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::GetMigrationJobRequest'->new($_) } @$_ ] };

declare 'MapStringGetMigrationJobRequest',
    as HashRef[GetMigrationJobRequest()];

declare 'CreateMigrationJobRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::CreateMigrationJobRequest'];

coerce 'CreateMigrationJobRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::CreateMigrationJobRequest'->new($_) };

declare 'RepeatedCreateMigrationJobRequest',
    as ArrayRef[CreateMigrationJobRequest()];

coerce 'RepeatedCreateMigrationJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::CreateMigrationJobRequest'->new($_) } @$_ ] };

declare 'MapStringCreateMigrationJobRequest',
    as HashRef[CreateMigrationJobRequest()];

declare 'UpdateMigrationJobRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::UpdateMigrationJobRequest'];

coerce 'UpdateMigrationJobRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::UpdateMigrationJobRequest'->new($_) };

declare 'RepeatedUpdateMigrationJobRequest',
    as ArrayRef[UpdateMigrationJobRequest()];

coerce 'RepeatedUpdateMigrationJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::UpdateMigrationJobRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateMigrationJobRequest',
    as HashRef[UpdateMigrationJobRequest()];

declare 'DeleteMigrationJobRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::DeleteMigrationJobRequest'];

coerce 'DeleteMigrationJobRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::DeleteMigrationJobRequest'->new($_) };

declare 'RepeatedDeleteMigrationJobRequest',
    as ArrayRef[DeleteMigrationJobRequest()];

coerce 'RepeatedDeleteMigrationJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::DeleteMigrationJobRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteMigrationJobRequest',
    as HashRef[DeleteMigrationJobRequest()];

declare 'StartMigrationJobRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::StartMigrationJobRequest'];

coerce 'StartMigrationJobRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::StartMigrationJobRequest'->new($_) };

declare 'RepeatedStartMigrationJobRequest',
    as ArrayRef[StartMigrationJobRequest()];

coerce 'RepeatedStartMigrationJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::StartMigrationJobRequest'->new($_) } @$_ ] };

declare 'MapStringStartMigrationJobRequest',
    as HashRef[StartMigrationJobRequest()];

declare 'StopMigrationJobRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::StopMigrationJobRequest'];

coerce 'StopMigrationJobRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::StopMigrationJobRequest'->new($_) };

declare 'RepeatedStopMigrationJobRequest',
    as ArrayRef[StopMigrationJobRequest()];

coerce 'RepeatedStopMigrationJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::StopMigrationJobRequest'->new($_) } @$_ ] };

declare 'MapStringStopMigrationJobRequest',
    as HashRef[StopMigrationJobRequest()];

declare 'ResumeMigrationJobRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::ResumeMigrationJobRequest'];

coerce 'ResumeMigrationJobRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::ResumeMigrationJobRequest'->new($_) };

declare 'RepeatedResumeMigrationJobRequest',
    as ArrayRef[ResumeMigrationJobRequest()];

coerce 'RepeatedResumeMigrationJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::ResumeMigrationJobRequest'->new($_) } @$_ ] };

declare 'MapStringResumeMigrationJobRequest',
    as HashRef[ResumeMigrationJobRequest()];

declare 'PromoteMigrationJobRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::PromoteMigrationJobRequest'];

coerce 'PromoteMigrationJobRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::PromoteMigrationJobRequest'->new($_) };

declare 'RepeatedPromoteMigrationJobRequest',
    as ArrayRef[PromoteMigrationJobRequest()];

coerce 'RepeatedPromoteMigrationJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::PromoteMigrationJobRequest'->new($_) } @$_ ] };

declare 'MapStringPromoteMigrationJobRequest',
    as HashRef[PromoteMigrationJobRequest()];

declare 'VerifyMigrationJobRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::VerifyMigrationJobRequest'];

coerce 'VerifyMigrationJobRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::VerifyMigrationJobRequest'->new($_) };

declare 'RepeatedVerifyMigrationJobRequest',
    as ArrayRef[VerifyMigrationJobRequest()];

coerce 'RepeatedVerifyMigrationJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::VerifyMigrationJobRequest'->new($_) } @$_ ] };

declare 'MapStringVerifyMigrationJobRequest',
    as HashRef[VerifyMigrationJobRequest()];

declare 'RestartMigrationJobRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::RestartMigrationJobRequest'];

coerce 'RestartMigrationJobRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::RestartMigrationJobRequest'->new($_) };

declare 'RepeatedRestartMigrationJobRequest',
    as ArrayRef[RestartMigrationJobRequest()];

coerce 'RepeatedRestartMigrationJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::RestartMigrationJobRequest'->new($_) } @$_ ] };

declare 'MapStringRestartMigrationJobRequest',
    as HashRef[RestartMigrationJobRequest()];

declare 'GenerateSshScriptRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::GenerateSshScriptRequest'];

coerce 'GenerateSshScriptRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::GenerateSshScriptRequest'->new($_) };

declare 'RepeatedGenerateSshScriptRequest',
    as ArrayRef[GenerateSshScriptRequest()];

coerce 'RepeatedGenerateSshScriptRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::GenerateSshScriptRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateSshScriptRequest',
    as HashRef[GenerateSshScriptRequest()];

declare 'VmCreationConfig',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::VmCreationConfig'];

coerce 'VmCreationConfig',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::VmCreationConfig'->new($_) };

declare 'RepeatedVmCreationConfig',
    as ArrayRef[VmCreationConfig()];

coerce 'RepeatedVmCreationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::VmCreationConfig'->new($_) } @$_ ] };

declare 'MapStringVmCreationConfig',
    as HashRef[VmCreationConfig()];

declare 'VmSelectionConfig',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::VmSelectionConfig'];

coerce 'VmSelectionConfig',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::VmSelectionConfig'->new($_) };

declare 'RepeatedVmSelectionConfig',
    as ArrayRef[VmSelectionConfig()];

coerce 'RepeatedVmSelectionConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::VmSelectionConfig'->new($_) } @$_ ] };

declare 'MapStringVmSelectionConfig',
    as HashRef[VmSelectionConfig()];

declare 'SshScript',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::SshScript'];

coerce 'SshScript',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::SshScript'->new($_) };

declare 'RepeatedSshScript',
    as ArrayRef[SshScript()];

coerce 'RepeatedSshScript',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::SshScript'->new($_) } @$_ ] };

declare 'MapStringSshScript',
    as HashRef[SshScript()];

declare 'GenerateTcpProxyScriptRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::GenerateTcpProxyScriptRequest'];

coerce 'GenerateTcpProxyScriptRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::GenerateTcpProxyScriptRequest'->new($_) };

declare 'RepeatedGenerateTcpProxyScriptRequest',
    as ArrayRef[GenerateTcpProxyScriptRequest()];

coerce 'RepeatedGenerateTcpProxyScriptRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::GenerateTcpProxyScriptRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateTcpProxyScriptRequest',
    as HashRef[GenerateTcpProxyScriptRequest()];

declare 'TcpProxyScript',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::TcpProxyScript'];

coerce 'TcpProxyScript',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::TcpProxyScript'->new($_) };

declare 'RepeatedTcpProxyScript',
    as ArrayRef[TcpProxyScript()];

coerce 'RepeatedTcpProxyScript',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::TcpProxyScript'->new($_) } @$_ ] };

declare 'MapStringTcpProxyScript',
    as HashRef[TcpProxyScript()];

declare 'ListConnectionProfilesRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::ListConnectionProfilesRequest'];

coerce 'ListConnectionProfilesRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::ListConnectionProfilesRequest'->new($_) };

declare 'RepeatedListConnectionProfilesRequest',
    as ArrayRef[ListConnectionProfilesRequest()];

coerce 'RepeatedListConnectionProfilesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::ListConnectionProfilesRequest'->new($_) } @$_ ] };

declare 'MapStringListConnectionProfilesRequest',
    as HashRef[ListConnectionProfilesRequest()];

declare 'ListConnectionProfilesResponse',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::ListConnectionProfilesResponse'];

coerce 'ListConnectionProfilesResponse',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::ListConnectionProfilesResponse'->new($_) };

declare 'RepeatedListConnectionProfilesResponse',
    as ArrayRef[ListConnectionProfilesResponse()];

coerce 'RepeatedListConnectionProfilesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::ListConnectionProfilesResponse'->new($_) } @$_ ] };

declare 'MapStringListConnectionProfilesResponse',
    as HashRef[ListConnectionProfilesResponse()];

declare 'GetConnectionProfileRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::GetConnectionProfileRequest'];

coerce 'GetConnectionProfileRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::GetConnectionProfileRequest'->new($_) };

declare 'RepeatedGetConnectionProfileRequest',
    as ArrayRef[GetConnectionProfileRequest()];

coerce 'RepeatedGetConnectionProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::GetConnectionProfileRequest'->new($_) } @$_ ] };

declare 'MapStringGetConnectionProfileRequest',
    as HashRef[GetConnectionProfileRequest()];

declare 'CreateConnectionProfileRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::CreateConnectionProfileRequest'];

coerce 'CreateConnectionProfileRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::CreateConnectionProfileRequest'->new($_) };

declare 'RepeatedCreateConnectionProfileRequest',
    as ArrayRef[CreateConnectionProfileRequest()];

coerce 'RepeatedCreateConnectionProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::CreateConnectionProfileRequest'->new($_) } @$_ ] };

declare 'MapStringCreateConnectionProfileRequest',
    as HashRef[CreateConnectionProfileRequest()];

declare 'UpdateConnectionProfileRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::UpdateConnectionProfileRequest'];

coerce 'UpdateConnectionProfileRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::UpdateConnectionProfileRequest'->new($_) };

declare 'RepeatedUpdateConnectionProfileRequest',
    as ArrayRef[UpdateConnectionProfileRequest()];

coerce 'RepeatedUpdateConnectionProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::UpdateConnectionProfileRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateConnectionProfileRequest',
    as HashRef[UpdateConnectionProfileRequest()];

declare 'DeleteConnectionProfileRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::DeleteConnectionProfileRequest'];

coerce 'DeleteConnectionProfileRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::DeleteConnectionProfileRequest'->new($_) };

declare 'RepeatedDeleteConnectionProfileRequest',
    as ArrayRef[DeleteConnectionProfileRequest()];

coerce 'RepeatedDeleteConnectionProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::DeleteConnectionProfileRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteConnectionProfileRequest',
    as HashRef[DeleteConnectionProfileRequest()];

declare 'CreatePrivateConnectionRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::CreatePrivateConnectionRequest'];

coerce 'CreatePrivateConnectionRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::CreatePrivateConnectionRequest'->new($_) };

declare 'RepeatedCreatePrivateConnectionRequest',
    as ArrayRef[CreatePrivateConnectionRequest()];

coerce 'RepeatedCreatePrivateConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::CreatePrivateConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringCreatePrivateConnectionRequest',
    as HashRef[CreatePrivateConnectionRequest()];

declare 'ListPrivateConnectionsRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::ListPrivateConnectionsRequest'];

coerce 'ListPrivateConnectionsRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::ListPrivateConnectionsRequest'->new($_) };

declare 'RepeatedListPrivateConnectionsRequest',
    as ArrayRef[ListPrivateConnectionsRequest()];

coerce 'RepeatedListPrivateConnectionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::ListPrivateConnectionsRequest'->new($_) } @$_ ] };

declare 'MapStringListPrivateConnectionsRequest',
    as HashRef[ListPrivateConnectionsRequest()];

declare 'ListPrivateConnectionsResponse',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::ListPrivateConnectionsResponse'];

coerce 'ListPrivateConnectionsResponse',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::ListPrivateConnectionsResponse'->new($_) };

declare 'RepeatedListPrivateConnectionsResponse',
    as ArrayRef[ListPrivateConnectionsResponse()];

coerce 'RepeatedListPrivateConnectionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::ListPrivateConnectionsResponse'->new($_) } @$_ ] };

declare 'MapStringListPrivateConnectionsResponse',
    as HashRef[ListPrivateConnectionsResponse()];

declare 'DeletePrivateConnectionRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::DeletePrivateConnectionRequest'];

coerce 'DeletePrivateConnectionRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::DeletePrivateConnectionRequest'->new($_) };

declare 'RepeatedDeletePrivateConnectionRequest',
    as ArrayRef[DeletePrivateConnectionRequest()];

coerce 'RepeatedDeletePrivateConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::DeletePrivateConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePrivateConnectionRequest',
    as HashRef[DeletePrivateConnectionRequest()];

declare 'GetPrivateConnectionRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::GetPrivateConnectionRequest'];

coerce 'GetPrivateConnectionRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::GetPrivateConnectionRequest'->new($_) };

declare 'RepeatedGetPrivateConnectionRequest',
    as ArrayRef[GetPrivateConnectionRequest()];

coerce 'RepeatedGetPrivateConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::GetPrivateConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringGetPrivateConnectionRequest',
    as HashRef[GetPrivateConnectionRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'ListConversionWorkspacesRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::ListConversionWorkspacesRequest'];

coerce 'ListConversionWorkspacesRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::ListConversionWorkspacesRequest'->new($_) };

declare 'RepeatedListConversionWorkspacesRequest',
    as ArrayRef[ListConversionWorkspacesRequest()];

coerce 'RepeatedListConversionWorkspacesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::ListConversionWorkspacesRequest'->new($_) } @$_ ] };

declare 'MapStringListConversionWorkspacesRequest',
    as HashRef[ListConversionWorkspacesRequest()];

declare 'ListConversionWorkspacesResponse',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::ListConversionWorkspacesResponse'];

coerce 'ListConversionWorkspacesResponse',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::ListConversionWorkspacesResponse'->new($_) };

declare 'RepeatedListConversionWorkspacesResponse',
    as ArrayRef[ListConversionWorkspacesResponse()];

coerce 'RepeatedListConversionWorkspacesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::ListConversionWorkspacesResponse'->new($_) } @$_ ] };

declare 'MapStringListConversionWorkspacesResponse',
    as HashRef[ListConversionWorkspacesResponse()];

declare 'GetConversionWorkspaceRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::GetConversionWorkspaceRequest'];

coerce 'GetConversionWorkspaceRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::GetConversionWorkspaceRequest'->new($_) };

declare 'RepeatedGetConversionWorkspaceRequest',
    as ArrayRef[GetConversionWorkspaceRequest()];

coerce 'RepeatedGetConversionWorkspaceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::GetConversionWorkspaceRequest'->new($_) } @$_ ] };

declare 'MapStringGetConversionWorkspaceRequest',
    as HashRef[GetConversionWorkspaceRequest()];

declare 'CreateConversionWorkspaceRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::CreateConversionWorkspaceRequest'];

coerce 'CreateConversionWorkspaceRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::CreateConversionWorkspaceRequest'->new($_) };

declare 'RepeatedCreateConversionWorkspaceRequest',
    as ArrayRef[CreateConversionWorkspaceRequest()];

coerce 'RepeatedCreateConversionWorkspaceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::CreateConversionWorkspaceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateConversionWorkspaceRequest',
    as HashRef[CreateConversionWorkspaceRequest()];

declare 'UpdateConversionWorkspaceRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::UpdateConversionWorkspaceRequest'];

coerce 'UpdateConversionWorkspaceRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::UpdateConversionWorkspaceRequest'->new($_) };

declare 'RepeatedUpdateConversionWorkspaceRequest',
    as ArrayRef[UpdateConversionWorkspaceRequest()];

coerce 'RepeatedUpdateConversionWorkspaceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::UpdateConversionWorkspaceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateConversionWorkspaceRequest',
    as HashRef[UpdateConversionWorkspaceRequest()];

declare 'DeleteConversionWorkspaceRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::DeleteConversionWorkspaceRequest'];

coerce 'DeleteConversionWorkspaceRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::DeleteConversionWorkspaceRequest'->new($_) };

declare 'RepeatedDeleteConversionWorkspaceRequest',
    as ArrayRef[DeleteConversionWorkspaceRequest()];

coerce 'RepeatedDeleteConversionWorkspaceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::DeleteConversionWorkspaceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteConversionWorkspaceRequest',
    as HashRef[DeleteConversionWorkspaceRequest()];

declare 'CommitConversionWorkspaceRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::CommitConversionWorkspaceRequest'];

coerce 'CommitConversionWorkspaceRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::CommitConversionWorkspaceRequest'->new($_) };

declare 'RepeatedCommitConversionWorkspaceRequest',
    as ArrayRef[CommitConversionWorkspaceRequest()];

coerce 'RepeatedCommitConversionWorkspaceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::CommitConversionWorkspaceRequest'->new($_) } @$_ ] };

declare 'MapStringCommitConversionWorkspaceRequest',
    as HashRef[CommitConversionWorkspaceRequest()];

declare 'RollbackConversionWorkspaceRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::RollbackConversionWorkspaceRequest'];

coerce 'RollbackConversionWorkspaceRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::RollbackConversionWorkspaceRequest'->new($_) };

declare 'RepeatedRollbackConversionWorkspaceRequest',
    as ArrayRef[RollbackConversionWorkspaceRequest()];

coerce 'RepeatedRollbackConversionWorkspaceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::RollbackConversionWorkspaceRequest'->new($_) } @$_ ] };

declare 'MapStringRollbackConversionWorkspaceRequest',
    as HashRef[RollbackConversionWorkspaceRequest()];

declare 'ApplyConversionWorkspaceRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::ApplyConversionWorkspaceRequest'];

coerce 'ApplyConversionWorkspaceRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::ApplyConversionWorkspaceRequest'->new($_) };

declare 'RepeatedApplyConversionWorkspaceRequest',
    as ArrayRef[ApplyConversionWorkspaceRequest()];

coerce 'RepeatedApplyConversionWorkspaceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::ApplyConversionWorkspaceRequest'->new($_) } @$_ ] };

declare 'MapStringApplyConversionWorkspaceRequest',
    as HashRef[ApplyConversionWorkspaceRequest()];

declare 'ListMappingRulesRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::ListMappingRulesRequest'];

coerce 'ListMappingRulesRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::ListMappingRulesRequest'->new($_) };

declare 'RepeatedListMappingRulesRequest',
    as ArrayRef[ListMappingRulesRequest()];

coerce 'RepeatedListMappingRulesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::ListMappingRulesRequest'->new($_) } @$_ ] };

declare 'MapStringListMappingRulesRequest',
    as HashRef[ListMappingRulesRequest()];

declare 'ListMappingRulesResponse',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::ListMappingRulesResponse'];

coerce 'ListMappingRulesResponse',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::ListMappingRulesResponse'->new($_) };

declare 'RepeatedListMappingRulesResponse',
    as ArrayRef[ListMappingRulesResponse()];

coerce 'RepeatedListMappingRulesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::ListMappingRulesResponse'->new($_) } @$_ ] };

declare 'MapStringListMappingRulesResponse',
    as HashRef[ListMappingRulesResponse()];

declare 'GetMappingRuleRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::GetMappingRuleRequest'];

coerce 'GetMappingRuleRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::GetMappingRuleRequest'->new($_) };

declare 'RepeatedGetMappingRuleRequest',
    as ArrayRef[GetMappingRuleRequest()];

coerce 'RepeatedGetMappingRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::GetMappingRuleRequest'->new($_) } @$_ ] };

declare 'MapStringGetMappingRuleRequest',
    as HashRef[GetMappingRuleRequest()];

declare 'SeedConversionWorkspaceRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::SeedConversionWorkspaceRequest'];

coerce 'SeedConversionWorkspaceRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::SeedConversionWorkspaceRequest'->new($_) };

declare 'RepeatedSeedConversionWorkspaceRequest',
    as ArrayRef[SeedConversionWorkspaceRequest()];

coerce 'RepeatedSeedConversionWorkspaceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::SeedConversionWorkspaceRequest'->new($_) } @$_ ] };

declare 'MapStringSeedConversionWorkspaceRequest',
    as HashRef[SeedConversionWorkspaceRequest()];

declare 'ConvertConversionWorkspaceRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::ConvertConversionWorkspaceRequest'];

coerce 'ConvertConversionWorkspaceRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::ConvertConversionWorkspaceRequest'->new($_) };

declare 'RepeatedConvertConversionWorkspaceRequest',
    as ArrayRef[ConvertConversionWorkspaceRequest()];

coerce 'RepeatedConvertConversionWorkspaceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::ConvertConversionWorkspaceRequest'->new($_) } @$_ ] };

declare 'MapStringConvertConversionWorkspaceRequest',
    as HashRef[ConvertConversionWorkspaceRequest()];

declare 'ImportMappingRulesRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::ImportMappingRulesRequest'];

coerce 'ImportMappingRulesRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::ImportMappingRulesRequest'->new($_) };

declare 'RepeatedImportMappingRulesRequest',
    as ArrayRef[ImportMappingRulesRequest()];

coerce 'RepeatedImportMappingRulesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::ImportMappingRulesRequest'->new($_) } @$_ ] };

declare 'MapStringImportMappingRulesRequest',
    as HashRef[ImportMappingRulesRequest()];

declare 'RulesFile',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::ImportMappingRulesRequest::RulesFile'];

coerce 'RulesFile',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::ImportMappingRulesRequest::RulesFile'->new($_) };

declare 'RepeatedRulesFile',
    as ArrayRef[RulesFile()];

coerce 'RepeatedRulesFile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::ImportMappingRulesRequest::RulesFile'->new($_) } @$_ ] };

declare 'MapStringRulesFile',
    as HashRef[RulesFile()];

declare 'DescribeDatabaseEntitiesRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::DescribeDatabaseEntitiesRequest'];

coerce 'DescribeDatabaseEntitiesRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::DescribeDatabaseEntitiesRequest'->new($_) };

declare 'RepeatedDescribeDatabaseEntitiesRequest',
    as ArrayRef[DescribeDatabaseEntitiesRequest()];

coerce 'RepeatedDescribeDatabaseEntitiesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::DescribeDatabaseEntitiesRequest'->new($_) } @$_ ] };

declare 'MapStringDescribeDatabaseEntitiesRequest',
    as HashRef[DescribeDatabaseEntitiesRequest()];

declare 'DBTreeType',
    as (Int | Str);

declare 'DescribeDatabaseEntitiesResponse',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::DescribeDatabaseEntitiesResponse'];

coerce 'DescribeDatabaseEntitiesResponse',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::DescribeDatabaseEntitiesResponse'->new($_) };

declare 'RepeatedDescribeDatabaseEntitiesResponse',
    as ArrayRef[DescribeDatabaseEntitiesResponse()];

coerce 'RepeatedDescribeDatabaseEntitiesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::DescribeDatabaseEntitiesResponse'->new($_) } @$_ ] };

declare 'MapStringDescribeDatabaseEntitiesResponse',
    as HashRef[DescribeDatabaseEntitiesResponse()];

declare 'SearchBackgroundJobsRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::SearchBackgroundJobsRequest'];

coerce 'SearchBackgroundJobsRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::SearchBackgroundJobsRequest'->new($_) };

declare 'RepeatedSearchBackgroundJobsRequest',
    as ArrayRef[SearchBackgroundJobsRequest()];

coerce 'RepeatedSearchBackgroundJobsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::SearchBackgroundJobsRequest'->new($_) } @$_ ] };

declare 'MapStringSearchBackgroundJobsRequest',
    as HashRef[SearchBackgroundJobsRequest()];

declare 'SearchBackgroundJobsResponse',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::SearchBackgroundJobsResponse'];

coerce 'SearchBackgroundJobsResponse',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::SearchBackgroundJobsResponse'->new($_) };

declare 'RepeatedSearchBackgroundJobsResponse',
    as ArrayRef[SearchBackgroundJobsResponse()];

coerce 'RepeatedSearchBackgroundJobsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::SearchBackgroundJobsResponse'->new($_) } @$_ ] };

declare 'MapStringSearchBackgroundJobsResponse',
    as HashRef[SearchBackgroundJobsResponse()];

declare 'DescribeConversionWorkspaceRevisionsRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::DescribeConversionWorkspaceRevisionsRequest'];

coerce 'DescribeConversionWorkspaceRevisionsRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::DescribeConversionWorkspaceRevisionsRequest'->new($_) };

declare 'RepeatedDescribeConversionWorkspaceRevisionsRequest',
    as ArrayRef[DescribeConversionWorkspaceRevisionsRequest()];

coerce 'RepeatedDescribeConversionWorkspaceRevisionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::DescribeConversionWorkspaceRevisionsRequest'->new($_) } @$_ ] };

declare 'MapStringDescribeConversionWorkspaceRevisionsRequest',
    as HashRef[DescribeConversionWorkspaceRevisionsRequest()];

declare 'DescribeConversionWorkspaceRevisionsResponse',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::DescribeConversionWorkspaceRevisionsResponse'];

coerce 'DescribeConversionWorkspaceRevisionsResponse',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::DescribeConversionWorkspaceRevisionsResponse'->new($_) };

declare 'RepeatedDescribeConversionWorkspaceRevisionsResponse',
    as ArrayRef[DescribeConversionWorkspaceRevisionsResponse()];

coerce 'RepeatedDescribeConversionWorkspaceRevisionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::DescribeConversionWorkspaceRevisionsResponse'->new($_) } @$_ ] };

declare 'MapStringDescribeConversionWorkspaceRevisionsResponse',
    as HashRef[DescribeConversionWorkspaceRevisionsResponse()];

declare 'CreateMappingRuleRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::CreateMappingRuleRequest'];

coerce 'CreateMappingRuleRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::CreateMappingRuleRequest'->new($_) };

declare 'RepeatedCreateMappingRuleRequest',
    as ArrayRef[CreateMappingRuleRequest()];

coerce 'RepeatedCreateMappingRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::CreateMappingRuleRequest'->new($_) } @$_ ] };

declare 'MapStringCreateMappingRuleRequest',
    as HashRef[CreateMappingRuleRequest()];

declare 'DeleteMappingRuleRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::DeleteMappingRuleRequest'];

coerce 'DeleteMappingRuleRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::DeleteMappingRuleRequest'->new($_) };

declare 'RepeatedDeleteMappingRuleRequest',
    as ArrayRef[DeleteMappingRuleRequest()];

coerce 'RepeatedDeleteMappingRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::DeleteMappingRuleRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteMappingRuleRequest',
    as HashRef[DeleteMappingRuleRequest()];

declare 'FetchStaticIpsRequest',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::FetchStaticIpsRequest'];

coerce 'FetchStaticIpsRequest',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::FetchStaticIpsRequest'->new($_) };

declare 'RepeatedFetchStaticIpsRequest',
    as ArrayRef[FetchStaticIpsRequest()];

coerce 'RepeatedFetchStaticIpsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::FetchStaticIpsRequest'->new($_) } @$_ ] };

declare 'MapStringFetchStaticIpsRequest',
    as HashRef[FetchStaticIpsRequest()];

declare 'FetchStaticIpsResponse',
    as InstanceOf['Google::Cloud::Clouddms::V1::Clouddms::FetchStaticIpsResponse'];

coerce 'FetchStaticIpsResponse',
    from HashRef, via { 'Google::Cloud::Clouddms::V1::Clouddms::FetchStaticIpsResponse'->new($_) };

declare 'RepeatedFetchStaticIpsResponse',
    as ArrayRef[FetchStaticIpsResponse()];

coerce 'RepeatedFetchStaticIpsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Clouddms::V1::Clouddms::FetchStaticIpsResponse'->new($_) } @$_ ] };

declare 'MapStringFetchStaticIpsResponse',
    as HashRef[FetchStaticIpsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Clouddms::V1::Clouddms::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
