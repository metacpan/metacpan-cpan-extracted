package Google::Cloud::Kms::V1::HsmManagement::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SingleTenantHsmInstance',
    as InstanceOf['Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstance'];

coerce 'SingleTenantHsmInstance',
    from HashRef, via { 'Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstance'->new($_) };

declare 'RepeatedSingleTenantHsmInstance',
    as ArrayRef[SingleTenantHsmInstance()];

coerce 'RepeatedSingleTenantHsmInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstance'->new($_) } @$_ ] };

declare 'MapStringSingleTenantHsmInstance',
    as HashRef[SingleTenantHsmInstance()];

declare 'State',
    as (Int | Str);

declare 'QuorumAuth',
    as InstanceOf['Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstance::QuorumAuth'];

coerce 'QuorumAuth',
    from HashRef, via { 'Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstance::QuorumAuth'->new($_) };

declare 'RepeatedQuorumAuth',
    as ArrayRef[QuorumAuth()];

coerce 'RepeatedQuorumAuth',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstance::QuorumAuth'->new($_) } @$_ ] };

declare 'MapStringQuorumAuth',
    as HashRef[QuorumAuth()];

declare 'SingleTenantHsmInstanceProposal',
    as InstanceOf['Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstanceProposal'];

coerce 'SingleTenantHsmInstanceProposal',
    from HashRef, via { 'Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstanceProposal'->new($_) };

declare 'RepeatedSingleTenantHsmInstanceProposal',
    as ArrayRef[SingleTenantHsmInstanceProposal()];

coerce 'RepeatedSingleTenantHsmInstanceProposal',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstanceProposal'->new($_) } @$_ ] };

declare 'MapStringSingleTenantHsmInstanceProposal',
    as HashRef[SingleTenantHsmInstanceProposal()];

declare 'State',
    as (Int | Str);

declare 'QuorumParameters',
    as InstanceOf['Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstanceProposal::QuorumParameters'];

coerce 'QuorumParameters',
    from HashRef, via { 'Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstanceProposal::QuorumParameters'->new($_) };

declare 'RepeatedQuorumParameters',
    as ArrayRef[QuorumParameters()];

coerce 'RepeatedQuorumParameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstanceProposal::QuorumParameters'->new($_) } @$_ ] };

declare 'MapStringQuorumParameters',
    as HashRef[QuorumParameters()];

declare 'RequiredActionQuorumParameters',
    as InstanceOf['Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstanceProposal::RequiredActionQuorumParameters'];

coerce 'RequiredActionQuorumParameters',
    from HashRef, via { 'Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstanceProposal::RequiredActionQuorumParameters'->new($_) };

declare 'RepeatedRequiredActionQuorumParameters',
    as ArrayRef[RequiredActionQuorumParameters()];

coerce 'RepeatedRequiredActionQuorumParameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstanceProposal::RequiredActionQuorumParameters'->new($_) } @$_ ] };

declare 'MapStringRequiredActionQuorumParameters',
    as HashRef[RequiredActionQuorumParameters()];

declare 'RegisterTwoFactorAuthKeys',
    as InstanceOf['Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstanceProposal::RegisterTwoFactorAuthKeys'];

coerce 'RegisterTwoFactorAuthKeys',
    from HashRef, via { 'Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstanceProposal::RegisterTwoFactorAuthKeys'->new($_) };

declare 'RepeatedRegisterTwoFactorAuthKeys',
    as ArrayRef[RegisterTwoFactorAuthKeys()];

coerce 'RepeatedRegisterTwoFactorAuthKeys',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstanceProposal::RegisterTwoFactorAuthKeys'->new($_) } @$_ ] };

declare 'MapStringRegisterTwoFactorAuthKeys',
    as HashRef[RegisterTwoFactorAuthKeys()];

declare 'DisableSingleTenantHsmInstance',
    as InstanceOf['Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstanceProposal::DisableSingleTenantHsmInstance'];

coerce 'DisableSingleTenantHsmInstance',
    from HashRef, via { 'Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstanceProposal::DisableSingleTenantHsmInstance'->new($_) };

declare 'RepeatedDisableSingleTenantHsmInstance',
    as ArrayRef[DisableSingleTenantHsmInstance()];

coerce 'RepeatedDisableSingleTenantHsmInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstanceProposal::DisableSingleTenantHsmInstance'->new($_) } @$_ ] };

declare 'MapStringDisableSingleTenantHsmInstance',
    as HashRef[DisableSingleTenantHsmInstance()];

declare 'EnableSingleTenantHsmInstance',
    as InstanceOf['Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstanceProposal::EnableSingleTenantHsmInstance'];

coerce 'EnableSingleTenantHsmInstance',
    from HashRef, via { 'Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstanceProposal::EnableSingleTenantHsmInstance'->new($_) };

declare 'RepeatedEnableSingleTenantHsmInstance',
    as ArrayRef[EnableSingleTenantHsmInstance()];

coerce 'RepeatedEnableSingleTenantHsmInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstanceProposal::EnableSingleTenantHsmInstance'->new($_) } @$_ ] };

declare 'MapStringEnableSingleTenantHsmInstance',
    as HashRef[EnableSingleTenantHsmInstance()];

declare 'DeleteSingleTenantHsmInstance',
    as InstanceOf['Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstanceProposal::DeleteSingleTenantHsmInstance'];

coerce 'DeleteSingleTenantHsmInstance',
    from HashRef, via { 'Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstanceProposal::DeleteSingleTenantHsmInstance'->new($_) };

declare 'RepeatedDeleteSingleTenantHsmInstance',
    as ArrayRef[DeleteSingleTenantHsmInstance()];

coerce 'RepeatedDeleteSingleTenantHsmInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstanceProposal::DeleteSingleTenantHsmInstance'->new($_) } @$_ ] };

declare 'MapStringDeleteSingleTenantHsmInstance',
    as HashRef[DeleteSingleTenantHsmInstance()];

declare 'AddQuorumMember',
    as InstanceOf['Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstanceProposal::AddQuorumMember'];

coerce 'AddQuorumMember',
    from HashRef, via { 'Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstanceProposal::AddQuorumMember'->new($_) };

declare 'RepeatedAddQuorumMember',
    as ArrayRef[AddQuorumMember()];

coerce 'RepeatedAddQuorumMember',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstanceProposal::AddQuorumMember'->new($_) } @$_ ] };

declare 'MapStringAddQuorumMember',
    as HashRef[AddQuorumMember()];

declare 'RemoveQuorumMember',
    as InstanceOf['Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstanceProposal::RemoveQuorumMember'];

coerce 'RemoveQuorumMember',
    from HashRef, via { 'Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstanceProposal::RemoveQuorumMember'->new($_) };

declare 'RepeatedRemoveQuorumMember',
    as ArrayRef[RemoveQuorumMember()];

coerce 'RepeatedRemoveQuorumMember',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstanceProposal::RemoveQuorumMember'->new($_) } @$_ ] };

declare 'MapStringRemoveQuorumMember',
    as HashRef[RemoveQuorumMember()];

declare 'RefreshSingleTenantHsmInstance',
    as InstanceOf['Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstanceProposal::RefreshSingleTenantHsmInstance'];

coerce 'RefreshSingleTenantHsmInstance',
    from HashRef, via { 'Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstanceProposal::RefreshSingleTenantHsmInstance'->new($_) };

declare 'RepeatedRefreshSingleTenantHsmInstance',
    as ArrayRef[RefreshSingleTenantHsmInstance()];

coerce 'RepeatedRefreshSingleTenantHsmInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstanceProposal::RefreshSingleTenantHsmInstance'->new($_) } @$_ ] };

declare 'MapStringRefreshSingleTenantHsmInstance',
    as HashRef[RefreshSingleTenantHsmInstance()];

declare 'UpgradeKeyTrust',
    as InstanceOf['Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstanceProposal::UpgradeKeyTrust'];

coerce 'UpgradeKeyTrust',
    from HashRef, via { 'Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstanceProposal::UpgradeKeyTrust'->new($_) };

declare 'RepeatedUpgradeKeyTrust',
    as ArrayRef[UpgradeKeyTrust()];

coerce 'RepeatedUpgradeKeyTrust',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::HsmManagement::SingleTenantHsmInstanceProposal::UpgradeKeyTrust'->new($_) } @$_ ] };

declare 'MapStringUpgradeKeyTrust',
    as HashRef[UpgradeKeyTrust()];

declare 'Challenge',
    as InstanceOf['Google::Cloud::Kms::V1::HsmManagement::Challenge'];

coerce 'Challenge',
    from HashRef, via { 'Google::Cloud::Kms::V1::HsmManagement::Challenge'->new($_) };

declare 'RepeatedChallenge',
    as ArrayRef[Challenge()];

coerce 'RepeatedChallenge',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::HsmManagement::Challenge'->new($_) } @$_ ] };

declare 'MapStringChallenge',
    as HashRef[Challenge()];

declare 'ChallengeReply',
    as InstanceOf['Google::Cloud::Kms::V1::HsmManagement::ChallengeReply'];

coerce 'ChallengeReply',
    from HashRef, via { 'Google::Cloud::Kms::V1::HsmManagement::ChallengeReply'->new($_) };

declare 'RepeatedChallengeReply',
    as ArrayRef[ChallengeReply()];

coerce 'RepeatedChallengeReply',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::HsmManagement::ChallengeReply'->new($_) } @$_ ] };

declare 'MapStringChallengeReply',
    as HashRef[ChallengeReply()];

declare 'ListSingleTenantHsmInstancesRequest',
    as InstanceOf['Google::Cloud::Kms::V1::HsmManagement::ListSingleTenantHsmInstancesRequest'];

coerce 'ListSingleTenantHsmInstancesRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::HsmManagement::ListSingleTenantHsmInstancesRequest'->new($_) };

declare 'RepeatedListSingleTenantHsmInstancesRequest',
    as ArrayRef[ListSingleTenantHsmInstancesRequest()];

coerce 'RepeatedListSingleTenantHsmInstancesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::HsmManagement::ListSingleTenantHsmInstancesRequest'->new($_) } @$_ ] };

declare 'MapStringListSingleTenantHsmInstancesRequest',
    as HashRef[ListSingleTenantHsmInstancesRequest()];

declare 'ListSingleTenantHsmInstancesResponse',
    as InstanceOf['Google::Cloud::Kms::V1::HsmManagement::ListSingleTenantHsmInstancesResponse'];

coerce 'ListSingleTenantHsmInstancesResponse',
    from HashRef, via { 'Google::Cloud::Kms::V1::HsmManagement::ListSingleTenantHsmInstancesResponse'->new($_) };

declare 'RepeatedListSingleTenantHsmInstancesResponse',
    as ArrayRef[ListSingleTenantHsmInstancesResponse()];

coerce 'RepeatedListSingleTenantHsmInstancesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::HsmManagement::ListSingleTenantHsmInstancesResponse'->new($_) } @$_ ] };

declare 'MapStringListSingleTenantHsmInstancesResponse',
    as HashRef[ListSingleTenantHsmInstancesResponse()];

declare 'GetSingleTenantHsmInstanceRequest',
    as InstanceOf['Google::Cloud::Kms::V1::HsmManagement::GetSingleTenantHsmInstanceRequest'];

coerce 'GetSingleTenantHsmInstanceRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::HsmManagement::GetSingleTenantHsmInstanceRequest'->new($_) };

declare 'RepeatedGetSingleTenantHsmInstanceRequest',
    as ArrayRef[GetSingleTenantHsmInstanceRequest()];

coerce 'RepeatedGetSingleTenantHsmInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::HsmManagement::GetSingleTenantHsmInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringGetSingleTenantHsmInstanceRequest',
    as HashRef[GetSingleTenantHsmInstanceRequest()];

declare 'CreateSingleTenantHsmInstanceRequest',
    as InstanceOf['Google::Cloud::Kms::V1::HsmManagement::CreateSingleTenantHsmInstanceRequest'];

coerce 'CreateSingleTenantHsmInstanceRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::HsmManagement::CreateSingleTenantHsmInstanceRequest'->new($_) };

declare 'RepeatedCreateSingleTenantHsmInstanceRequest',
    as ArrayRef[CreateSingleTenantHsmInstanceRequest()];

coerce 'RepeatedCreateSingleTenantHsmInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::HsmManagement::CreateSingleTenantHsmInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSingleTenantHsmInstanceRequest',
    as HashRef[CreateSingleTenantHsmInstanceRequest()];

declare 'CreateSingleTenantHsmInstanceMetadata',
    as InstanceOf['Google::Cloud::Kms::V1::HsmManagement::CreateSingleTenantHsmInstanceMetadata'];

coerce 'CreateSingleTenantHsmInstanceMetadata',
    from HashRef, via { 'Google::Cloud::Kms::V1::HsmManagement::CreateSingleTenantHsmInstanceMetadata'->new($_) };

declare 'RepeatedCreateSingleTenantHsmInstanceMetadata',
    as ArrayRef[CreateSingleTenantHsmInstanceMetadata()];

coerce 'RepeatedCreateSingleTenantHsmInstanceMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::HsmManagement::CreateSingleTenantHsmInstanceMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateSingleTenantHsmInstanceMetadata',
    as HashRef[CreateSingleTenantHsmInstanceMetadata()];

declare 'CreateSingleTenantHsmInstanceProposalRequest',
    as InstanceOf['Google::Cloud::Kms::V1::HsmManagement::CreateSingleTenantHsmInstanceProposalRequest'];

coerce 'CreateSingleTenantHsmInstanceProposalRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::HsmManagement::CreateSingleTenantHsmInstanceProposalRequest'->new($_) };

declare 'RepeatedCreateSingleTenantHsmInstanceProposalRequest',
    as ArrayRef[CreateSingleTenantHsmInstanceProposalRequest()];

coerce 'RepeatedCreateSingleTenantHsmInstanceProposalRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::HsmManagement::CreateSingleTenantHsmInstanceProposalRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSingleTenantHsmInstanceProposalRequest',
    as HashRef[CreateSingleTenantHsmInstanceProposalRequest()];

declare 'CreateSingleTenantHsmInstanceProposalMetadata',
    as InstanceOf['Google::Cloud::Kms::V1::HsmManagement::CreateSingleTenantHsmInstanceProposalMetadata'];

coerce 'CreateSingleTenantHsmInstanceProposalMetadata',
    from HashRef, via { 'Google::Cloud::Kms::V1::HsmManagement::CreateSingleTenantHsmInstanceProposalMetadata'->new($_) };

declare 'RepeatedCreateSingleTenantHsmInstanceProposalMetadata',
    as ArrayRef[CreateSingleTenantHsmInstanceProposalMetadata()];

coerce 'RepeatedCreateSingleTenantHsmInstanceProposalMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::HsmManagement::CreateSingleTenantHsmInstanceProposalMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateSingleTenantHsmInstanceProposalMetadata',
    as HashRef[CreateSingleTenantHsmInstanceProposalMetadata()];

declare 'GetSingleTenantHsmInstanceProposalRequest',
    as InstanceOf['Google::Cloud::Kms::V1::HsmManagement::GetSingleTenantHsmInstanceProposalRequest'];

coerce 'GetSingleTenantHsmInstanceProposalRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::HsmManagement::GetSingleTenantHsmInstanceProposalRequest'->new($_) };

declare 'RepeatedGetSingleTenantHsmInstanceProposalRequest',
    as ArrayRef[GetSingleTenantHsmInstanceProposalRequest()];

coerce 'RepeatedGetSingleTenantHsmInstanceProposalRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::HsmManagement::GetSingleTenantHsmInstanceProposalRequest'->new($_) } @$_ ] };

declare 'MapStringGetSingleTenantHsmInstanceProposalRequest',
    as HashRef[GetSingleTenantHsmInstanceProposalRequest()];

declare 'ApproveSingleTenantHsmInstanceProposalRequest',
    as InstanceOf['Google::Cloud::Kms::V1::HsmManagement::ApproveSingleTenantHsmInstanceProposalRequest'];

coerce 'ApproveSingleTenantHsmInstanceProposalRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::HsmManagement::ApproveSingleTenantHsmInstanceProposalRequest'->new($_) };

declare 'RepeatedApproveSingleTenantHsmInstanceProposalRequest',
    as ArrayRef[ApproveSingleTenantHsmInstanceProposalRequest()];

coerce 'RepeatedApproveSingleTenantHsmInstanceProposalRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::HsmManagement::ApproveSingleTenantHsmInstanceProposalRequest'->new($_) } @$_ ] };

declare 'MapStringApproveSingleTenantHsmInstanceProposalRequest',
    as HashRef[ApproveSingleTenantHsmInstanceProposalRequest()];

declare 'QuorumReply',
    as InstanceOf['Google::Cloud::Kms::V1::HsmManagement::ApproveSingleTenantHsmInstanceProposalRequest::QuorumReply'];

coerce 'QuorumReply',
    from HashRef, via { 'Google::Cloud::Kms::V1::HsmManagement::ApproveSingleTenantHsmInstanceProposalRequest::QuorumReply'->new($_) };

declare 'RepeatedQuorumReply',
    as ArrayRef[QuorumReply()];

coerce 'RepeatedQuorumReply',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::HsmManagement::ApproveSingleTenantHsmInstanceProposalRequest::QuorumReply'->new($_) } @$_ ] };

declare 'MapStringQuorumReply',
    as HashRef[QuorumReply()];

declare 'RequiredActionQuorumReply',
    as InstanceOf['Google::Cloud::Kms::V1::HsmManagement::ApproveSingleTenantHsmInstanceProposalRequest::RequiredActionQuorumReply'];

coerce 'RequiredActionQuorumReply',
    from HashRef, via { 'Google::Cloud::Kms::V1::HsmManagement::ApproveSingleTenantHsmInstanceProposalRequest::RequiredActionQuorumReply'->new($_) };

declare 'RepeatedRequiredActionQuorumReply',
    as ArrayRef[RequiredActionQuorumReply()];

coerce 'RepeatedRequiredActionQuorumReply',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::HsmManagement::ApproveSingleTenantHsmInstanceProposalRequest::RequiredActionQuorumReply'->new($_) } @$_ ] };

declare 'MapStringRequiredActionQuorumReply',
    as HashRef[RequiredActionQuorumReply()];

declare 'ApproveSingleTenantHsmInstanceProposalResponse',
    as InstanceOf['Google::Cloud::Kms::V1::HsmManagement::ApproveSingleTenantHsmInstanceProposalResponse'];

coerce 'ApproveSingleTenantHsmInstanceProposalResponse',
    from HashRef, via { 'Google::Cloud::Kms::V1::HsmManagement::ApproveSingleTenantHsmInstanceProposalResponse'->new($_) };

declare 'RepeatedApproveSingleTenantHsmInstanceProposalResponse',
    as ArrayRef[ApproveSingleTenantHsmInstanceProposalResponse()];

coerce 'RepeatedApproveSingleTenantHsmInstanceProposalResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::HsmManagement::ApproveSingleTenantHsmInstanceProposalResponse'->new($_) } @$_ ] };

declare 'MapStringApproveSingleTenantHsmInstanceProposalResponse',
    as HashRef[ApproveSingleTenantHsmInstanceProposalResponse()];

declare 'ExecuteSingleTenantHsmInstanceProposalRequest',
    as InstanceOf['Google::Cloud::Kms::V1::HsmManagement::ExecuteSingleTenantHsmInstanceProposalRequest'];

coerce 'ExecuteSingleTenantHsmInstanceProposalRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::HsmManagement::ExecuteSingleTenantHsmInstanceProposalRequest'->new($_) };

declare 'RepeatedExecuteSingleTenantHsmInstanceProposalRequest',
    as ArrayRef[ExecuteSingleTenantHsmInstanceProposalRequest()];

coerce 'RepeatedExecuteSingleTenantHsmInstanceProposalRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::HsmManagement::ExecuteSingleTenantHsmInstanceProposalRequest'->new($_) } @$_ ] };

declare 'MapStringExecuteSingleTenantHsmInstanceProposalRequest',
    as HashRef[ExecuteSingleTenantHsmInstanceProposalRequest()];

declare 'ExecuteSingleTenantHsmInstanceProposalResponse',
    as InstanceOf['Google::Cloud::Kms::V1::HsmManagement::ExecuteSingleTenantHsmInstanceProposalResponse'];

coerce 'ExecuteSingleTenantHsmInstanceProposalResponse',
    from HashRef, via { 'Google::Cloud::Kms::V1::HsmManagement::ExecuteSingleTenantHsmInstanceProposalResponse'->new($_) };

declare 'RepeatedExecuteSingleTenantHsmInstanceProposalResponse',
    as ArrayRef[ExecuteSingleTenantHsmInstanceProposalResponse()];

coerce 'RepeatedExecuteSingleTenantHsmInstanceProposalResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::HsmManagement::ExecuteSingleTenantHsmInstanceProposalResponse'->new($_) } @$_ ] };

declare 'MapStringExecuteSingleTenantHsmInstanceProposalResponse',
    as HashRef[ExecuteSingleTenantHsmInstanceProposalResponse()];

declare 'ExecuteSingleTenantHsmInstanceProposalMetadata',
    as InstanceOf['Google::Cloud::Kms::V1::HsmManagement::ExecuteSingleTenantHsmInstanceProposalMetadata'];

coerce 'ExecuteSingleTenantHsmInstanceProposalMetadata',
    from HashRef, via { 'Google::Cloud::Kms::V1::HsmManagement::ExecuteSingleTenantHsmInstanceProposalMetadata'->new($_) };

declare 'RepeatedExecuteSingleTenantHsmInstanceProposalMetadata',
    as ArrayRef[ExecuteSingleTenantHsmInstanceProposalMetadata()];

coerce 'RepeatedExecuteSingleTenantHsmInstanceProposalMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::HsmManagement::ExecuteSingleTenantHsmInstanceProposalMetadata'->new($_) } @$_ ] };

declare 'MapStringExecuteSingleTenantHsmInstanceProposalMetadata',
    as HashRef[ExecuteSingleTenantHsmInstanceProposalMetadata()];

declare 'ListSingleTenantHsmInstanceProposalsRequest',
    as InstanceOf['Google::Cloud::Kms::V1::HsmManagement::ListSingleTenantHsmInstanceProposalsRequest'];

coerce 'ListSingleTenantHsmInstanceProposalsRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::HsmManagement::ListSingleTenantHsmInstanceProposalsRequest'->new($_) };

declare 'RepeatedListSingleTenantHsmInstanceProposalsRequest',
    as ArrayRef[ListSingleTenantHsmInstanceProposalsRequest()];

coerce 'RepeatedListSingleTenantHsmInstanceProposalsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::HsmManagement::ListSingleTenantHsmInstanceProposalsRequest'->new($_) } @$_ ] };

declare 'MapStringListSingleTenantHsmInstanceProposalsRequest',
    as HashRef[ListSingleTenantHsmInstanceProposalsRequest()];

declare 'ListSingleTenantHsmInstanceProposalsResponse',
    as InstanceOf['Google::Cloud::Kms::V1::HsmManagement::ListSingleTenantHsmInstanceProposalsResponse'];

coerce 'ListSingleTenantHsmInstanceProposalsResponse',
    from HashRef, via { 'Google::Cloud::Kms::V1::HsmManagement::ListSingleTenantHsmInstanceProposalsResponse'->new($_) };

declare 'RepeatedListSingleTenantHsmInstanceProposalsResponse',
    as ArrayRef[ListSingleTenantHsmInstanceProposalsResponse()];

coerce 'RepeatedListSingleTenantHsmInstanceProposalsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::HsmManagement::ListSingleTenantHsmInstanceProposalsResponse'->new($_) } @$_ ] };

declare 'MapStringListSingleTenantHsmInstanceProposalsResponse',
    as HashRef[ListSingleTenantHsmInstanceProposalsResponse()];

declare 'DeleteSingleTenantHsmInstanceProposalRequest',
    as InstanceOf['Google::Cloud::Kms::V1::HsmManagement::DeleteSingleTenantHsmInstanceProposalRequest'];

coerce 'DeleteSingleTenantHsmInstanceProposalRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::HsmManagement::DeleteSingleTenantHsmInstanceProposalRequest'->new($_) };

declare 'RepeatedDeleteSingleTenantHsmInstanceProposalRequest',
    as ArrayRef[DeleteSingleTenantHsmInstanceProposalRequest()];

coerce 'RepeatedDeleteSingleTenantHsmInstanceProposalRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::HsmManagement::DeleteSingleTenantHsmInstanceProposalRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSingleTenantHsmInstanceProposalRequest',
    as HashRef[DeleteSingleTenantHsmInstanceProposalRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Kms::V1::HsmManagement::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
