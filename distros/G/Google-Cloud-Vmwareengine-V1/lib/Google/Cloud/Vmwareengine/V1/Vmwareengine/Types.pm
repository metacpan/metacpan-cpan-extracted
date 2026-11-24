package Google::Cloud::Vmwareengine::V1::Vmwareengine::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListPrivateCloudsRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ListPrivateCloudsRequest'];

coerce 'ListPrivateCloudsRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListPrivateCloudsRequest'->new($_) };

declare 'RepeatedListPrivateCloudsRequest',
    as ArrayRef[ListPrivateCloudsRequest()];

coerce 'RepeatedListPrivateCloudsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListPrivateCloudsRequest'->new($_) } @$_ ] };

declare 'MapStringListPrivateCloudsRequest',
    as HashRef[ListPrivateCloudsRequest()];

declare 'ListPrivateCloudsResponse',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ListPrivateCloudsResponse'];

coerce 'ListPrivateCloudsResponse',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListPrivateCloudsResponse'->new($_) };

declare 'RepeatedListPrivateCloudsResponse',
    as ArrayRef[ListPrivateCloudsResponse()];

coerce 'RepeatedListPrivateCloudsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListPrivateCloudsResponse'->new($_) } @$_ ] };

declare 'MapStringListPrivateCloudsResponse',
    as HashRef[ListPrivateCloudsResponse()];

declare 'GetPrivateCloudRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::GetPrivateCloudRequest'];

coerce 'GetPrivateCloudRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GetPrivateCloudRequest'->new($_) };

declare 'RepeatedGetPrivateCloudRequest',
    as ArrayRef[GetPrivateCloudRequest()];

coerce 'RepeatedGetPrivateCloudRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GetPrivateCloudRequest'->new($_) } @$_ ] };

declare 'MapStringGetPrivateCloudRequest',
    as HashRef[GetPrivateCloudRequest()];

declare 'CreatePrivateCloudRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::CreatePrivateCloudRequest'];

coerce 'CreatePrivateCloudRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::CreatePrivateCloudRequest'->new($_) };

declare 'RepeatedCreatePrivateCloudRequest',
    as ArrayRef[CreatePrivateCloudRequest()];

coerce 'RepeatedCreatePrivateCloudRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::CreatePrivateCloudRequest'->new($_) } @$_ ] };

declare 'MapStringCreatePrivateCloudRequest',
    as HashRef[CreatePrivateCloudRequest()];

declare 'UpdatePrivateCloudRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdatePrivateCloudRequest'];

coerce 'UpdatePrivateCloudRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdatePrivateCloudRequest'->new($_) };

declare 'RepeatedUpdatePrivateCloudRequest',
    as ArrayRef[UpdatePrivateCloudRequest()];

coerce 'RepeatedUpdatePrivateCloudRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdatePrivateCloudRequest'->new($_) } @$_ ] };

declare 'MapStringUpdatePrivateCloudRequest',
    as HashRef[UpdatePrivateCloudRequest()];

declare 'DeletePrivateCloudRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::DeletePrivateCloudRequest'];

coerce 'DeletePrivateCloudRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::DeletePrivateCloudRequest'->new($_) };

declare 'RepeatedDeletePrivateCloudRequest',
    as ArrayRef[DeletePrivateCloudRequest()];

coerce 'RepeatedDeletePrivateCloudRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::DeletePrivateCloudRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePrivateCloudRequest',
    as HashRef[DeletePrivateCloudRequest()];

declare 'UndeletePrivateCloudRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::UndeletePrivateCloudRequest'];

coerce 'UndeletePrivateCloudRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::UndeletePrivateCloudRequest'->new($_) };

declare 'RepeatedUndeletePrivateCloudRequest',
    as ArrayRef[UndeletePrivateCloudRequest()];

coerce 'RepeatedUndeletePrivateCloudRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::UndeletePrivateCloudRequest'->new($_) } @$_ ] };

declare 'MapStringUndeletePrivateCloudRequest',
    as HashRef[UndeletePrivateCloudRequest()];

declare 'ListClustersRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ListClustersRequest'];

coerce 'ListClustersRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListClustersRequest'->new($_) };

declare 'RepeatedListClustersRequest',
    as ArrayRef[ListClustersRequest()];

coerce 'RepeatedListClustersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListClustersRequest'->new($_) } @$_ ] };

declare 'MapStringListClustersRequest',
    as HashRef[ListClustersRequest()];

declare 'ListClustersResponse',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ListClustersResponse'];

coerce 'ListClustersResponse',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListClustersResponse'->new($_) };

declare 'RepeatedListClustersResponse',
    as ArrayRef[ListClustersResponse()];

coerce 'RepeatedListClustersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListClustersResponse'->new($_) } @$_ ] };

declare 'MapStringListClustersResponse',
    as HashRef[ListClustersResponse()];

declare 'GetClusterRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::GetClusterRequest'];

coerce 'GetClusterRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GetClusterRequest'->new($_) };

declare 'RepeatedGetClusterRequest',
    as ArrayRef[GetClusterRequest()];

coerce 'RepeatedGetClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GetClusterRequest'->new($_) } @$_ ] };

declare 'MapStringGetClusterRequest',
    as HashRef[GetClusterRequest()];

declare 'CreateClusterRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::CreateClusterRequest'];

coerce 'CreateClusterRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::CreateClusterRequest'->new($_) };

declare 'RepeatedCreateClusterRequest',
    as ArrayRef[CreateClusterRequest()];

coerce 'RepeatedCreateClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::CreateClusterRequest'->new($_) } @$_ ] };

declare 'MapStringCreateClusterRequest',
    as HashRef[CreateClusterRequest()];

declare 'UpdateClusterRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdateClusterRequest'];

coerce 'UpdateClusterRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdateClusterRequest'->new($_) };

declare 'RepeatedUpdateClusterRequest',
    as ArrayRef[UpdateClusterRequest()];

coerce 'RepeatedUpdateClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdateClusterRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateClusterRequest',
    as HashRef[UpdateClusterRequest()];

declare 'DeleteClusterRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::DeleteClusterRequest'];

coerce 'DeleteClusterRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::DeleteClusterRequest'->new($_) };

declare 'RepeatedDeleteClusterRequest',
    as ArrayRef[DeleteClusterRequest()];

coerce 'RepeatedDeleteClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::DeleteClusterRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteClusterRequest',
    as HashRef[DeleteClusterRequest()];

declare 'ListNodesRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ListNodesRequest'];

coerce 'ListNodesRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListNodesRequest'->new($_) };

declare 'RepeatedListNodesRequest',
    as ArrayRef[ListNodesRequest()];

coerce 'RepeatedListNodesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListNodesRequest'->new($_) } @$_ ] };

declare 'MapStringListNodesRequest',
    as HashRef[ListNodesRequest()];

declare 'ListNodesResponse',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ListNodesResponse'];

coerce 'ListNodesResponse',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListNodesResponse'->new($_) };

declare 'RepeatedListNodesResponse',
    as ArrayRef[ListNodesResponse()];

coerce 'RepeatedListNodesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListNodesResponse'->new($_) } @$_ ] };

declare 'MapStringListNodesResponse',
    as HashRef[ListNodesResponse()];

declare 'GetNodeRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::GetNodeRequest'];

coerce 'GetNodeRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GetNodeRequest'->new($_) };

declare 'RepeatedGetNodeRequest',
    as ArrayRef[GetNodeRequest()];

coerce 'RepeatedGetNodeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GetNodeRequest'->new($_) } @$_ ] };

declare 'MapStringGetNodeRequest',
    as HashRef[GetNodeRequest()];

declare 'ListExternalAddressesRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ListExternalAddressesRequest'];

coerce 'ListExternalAddressesRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListExternalAddressesRequest'->new($_) };

declare 'RepeatedListExternalAddressesRequest',
    as ArrayRef[ListExternalAddressesRequest()];

coerce 'RepeatedListExternalAddressesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListExternalAddressesRequest'->new($_) } @$_ ] };

declare 'MapStringListExternalAddressesRequest',
    as HashRef[ListExternalAddressesRequest()];

declare 'ListExternalAddressesResponse',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ListExternalAddressesResponse'];

coerce 'ListExternalAddressesResponse',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListExternalAddressesResponse'->new($_) };

declare 'RepeatedListExternalAddressesResponse',
    as ArrayRef[ListExternalAddressesResponse()];

coerce 'RepeatedListExternalAddressesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListExternalAddressesResponse'->new($_) } @$_ ] };

declare 'MapStringListExternalAddressesResponse',
    as HashRef[ListExternalAddressesResponse()];

declare 'FetchNetworkPolicyExternalAddressesRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::FetchNetworkPolicyExternalAddressesRequest'];

coerce 'FetchNetworkPolicyExternalAddressesRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::FetchNetworkPolicyExternalAddressesRequest'->new($_) };

declare 'RepeatedFetchNetworkPolicyExternalAddressesRequest',
    as ArrayRef[FetchNetworkPolicyExternalAddressesRequest()];

coerce 'RepeatedFetchNetworkPolicyExternalAddressesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::FetchNetworkPolicyExternalAddressesRequest'->new($_) } @$_ ] };

declare 'MapStringFetchNetworkPolicyExternalAddressesRequest',
    as HashRef[FetchNetworkPolicyExternalAddressesRequest()];

declare 'FetchNetworkPolicyExternalAddressesResponse',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::FetchNetworkPolicyExternalAddressesResponse'];

coerce 'FetchNetworkPolicyExternalAddressesResponse',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::FetchNetworkPolicyExternalAddressesResponse'->new($_) };

declare 'RepeatedFetchNetworkPolicyExternalAddressesResponse',
    as ArrayRef[FetchNetworkPolicyExternalAddressesResponse()];

coerce 'RepeatedFetchNetworkPolicyExternalAddressesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::FetchNetworkPolicyExternalAddressesResponse'->new($_) } @$_ ] };

declare 'MapStringFetchNetworkPolicyExternalAddressesResponse',
    as HashRef[FetchNetworkPolicyExternalAddressesResponse()];

declare 'GetExternalAddressRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::GetExternalAddressRequest'];

coerce 'GetExternalAddressRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GetExternalAddressRequest'->new($_) };

declare 'RepeatedGetExternalAddressRequest',
    as ArrayRef[GetExternalAddressRequest()];

coerce 'RepeatedGetExternalAddressRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GetExternalAddressRequest'->new($_) } @$_ ] };

declare 'MapStringGetExternalAddressRequest',
    as HashRef[GetExternalAddressRequest()];

declare 'CreateExternalAddressRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::CreateExternalAddressRequest'];

coerce 'CreateExternalAddressRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::CreateExternalAddressRequest'->new($_) };

declare 'RepeatedCreateExternalAddressRequest',
    as ArrayRef[CreateExternalAddressRequest()];

coerce 'RepeatedCreateExternalAddressRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::CreateExternalAddressRequest'->new($_) } @$_ ] };

declare 'MapStringCreateExternalAddressRequest',
    as HashRef[CreateExternalAddressRequest()];

declare 'UpdateExternalAddressRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdateExternalAddressRequest'];

coerce 'UpdateExternalAddressRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdateExternalAddressRequest'->new($_) };

declare 'RepeatedUpdateExternalAddressRequest',
    as ArrayRef[UpdateExternalAddressRequest()];

coerce 'RepeatedUpdateExternalAddressRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdateExternalAddressRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateExternalAddressRequest',
    as HashRef[UpdateExternalAddressRequest()];

declare 'DeleteExternalAddressRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::DeleteExternalAddressRequest'];

coerce 'DeleteExternalAddressRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::DeleteExternalAddressRequest'->new($_) };

declare 'RepeatedDeleteExternalAddressRequest',
    as ArrayRef[DeleteExternalAddressRequest()];

coerce 'RepeatedDeleteExternalAddressRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::DeleteExternalAddressRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteExternalAddressRequest',
    as HashRef[DeleteExternalAddressRequest()];

declare 'ListSubnetsRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ListSubnetsRequest'];

coerce 'ListSubnetsRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListSubnetsRequest'->new($_) };

declare 'RepeatedListSubnetsRequest',
    as ArrayRef[ListSubnetsRequest()];

coerce 'RepeatedListSubnetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListSubnetsRequest'->new($_) } @$_ ] };

declare 'MapStringListSubnetsRequest',
    as HashRef[ListSubnetsRequest()];

declare 'ListSubnetsResponse',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ListSubnetsResponse'];

coerce 'ListSubnetsResponse',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListSubnetsResponse'->new($_) };

declare 'RepeatedListSubnetsResponse',
    as ArrayRef[ListSubnetsResponse()];

coerce 'RepeatedListSubnetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListSubnetsResponse'->new($_) } @$_ ] };

declare 'MapStringListSubnetsResponse',
    as HashRef[ListSubnetsResponse()];

declare 'GetSubnetRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::GetSubnetRequest'];

coerce 'GetSubnetRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GetSubnetRequest'->new($_) };

declare 'RepeatedGetSubnetRequest',
    as ArrayRef[GetSubnetRequest()];

coerce 'RepeatedGetSubnetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GetSubnetRequest'->new($_) } @$_ ] };

declare 'MapStringGetSubnetRequest',
    as HashRef[GetSubnetRequest()];

declare 'UpdateSubnetRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdateSubnetRequest'];

coerce 'UpdateSubnetRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdateSubnetRequest'->new($_) };

declare 'RepeatedUpdateSubnetRequest',
    as ArrayRef[UpdateSubnetRequest()];

coerce 'RepeatedUpdateSubnetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdateSubnetRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSubnetRequest',
    as HashRef[UpdateSubnetRequest()];

declare 'ListExternalAccessRulesRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ListExternalAccessRulesRequest'];

coerce 'ListExternalAccessRulesRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListExternalAccessRulesRequest'->new($_) };

declare 'RepeatedListExternalAccessRulesRequest',
    as ArrayRef[ListExternalAccessRulesRequest()];

coerce 'RepeatedListExternalAccessRulesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListExternalAccessRulesRequest'->new($_) } @$_ ] };

declare 'MapStringListExternalAccessRulesRequest',
    as HashRef[ListExternalAccessRulesRequest()];

declare 'ListExternalAccessRulesResponse',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ListExternalAccessRulesResponse'];

coerce 'ListExternalAccessRulesResponse',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListExternalAccessRulesResponse'->new($_) };

declare 'RepeatedListExternalAccessRulesResponse',
    as ArrayRef[ListExternalAccessRulesResponse()];

coerce 'RepeatedListExternalAccessRulesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListExternalAccessRulesResponse'->new($_) } @$_ ] };

declare 'MapStringListExternalAccessRulesResponse',
    as HashRef[ListExternalAccessRulesResponse()];

declare 'GetExternalAccessRuleRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::GetExternalAccessRuleRequest'];

coerce 'GetExternalAccessRuleRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GetExternalAccessRuleRequest'->new($_) };

declare 'RepeatedGetExternalAccessRuleRequest',
    as ArrayRef[GetExternalAccessRuleRequest()];

coerce 'RepeatedGetExternalAccessRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GetExternalAccessRuleRequest'->new($_) } @$_ ] };

declare 'MapStringGetExternalAccessRuleRequest',
    as HashRef[GetExternalAccessRuleRequest()];

declare 'CreateExternalAccessRuleRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::CreateExternalAccessRuleRequest'];

coerce 'CreateExternalAccessRuleRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::CreateExternalAccessRuleRequest'->new($_) };

declare 'RepeatedCreateExternalAccessRuleRequest',
    as ArrayRef[CreateExternalAccessRuleRequest()];

coerce 'RepeatedCreateExternalAccessRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::CreateExternalAccessRuleRequest'->new($_) } @$_ ] };

declare 'MapStringCreateExternalAccessRuleRequest',
    as HashRef[CreateExternalAccessRuleRequest()];

declare 'UpdateExternalAccessRuleRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdateExternalAccessRuleRequest'];

coerce 'UpdateExternalAccessRuleRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdateExternalAccessRuleRequest'->new($_) };

declare 'RepeatedUpdateExternalAccessRuleRequest',
    as ArrayRef[UpdateExternalAccessRuleRequest()];

coerce 'RepeatedUpdateExternalAccessRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdateExternalAccessRuleRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateExternalAccessRuleRequest',
    as HashRef[UpdateExternalAccessRuleRequest()];

declare 'DeleteExternalAccessRuleRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::DeleteExternalAccessRuleRequest'];

coerce 'DeleteExternalAccessRuleRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::DeleteExternalAccessRuleRequest'->new($_) };

declare 'RepeatedDeleteExternalAccessRuleRequest',
    as ArrayRef[DeleteExternalAccessRuleRequest()];

coerce 'RepeatedDeleteExternalAccessRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::DeleteExternalAccessRuleRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteExternalAccessRuleRequest',
    as HashRef[DeleteExternalAccessRuleRequest()];

declare 'ListLoggingServersRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ListLoggingServersRequest'];

coerce 'ListLoggingServersRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListLoggingServersRequest'->new($_) };

declare 'RepeatedListLoggingServersRequest',
    as ArrayRef[ListLoggingServersRequest()];

coerce 'RepeatedListLoggingServersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListLoggingServersRequest'->new($_) } @$_ ] };

declare 'MapStringListLoggingServersRequest',
    as HashRef[ListLoggingServersRequest()];

declare 'ListLoggingServersResponse',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ListLoggingServersResponse'];

coerce 'ListLoggingServersResponse',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListLoggingServersResponse'->new($_) };

declare 'RepeatedListLoggingServersResponse',
    as ArrayRef[ListLoggingServersResponse()];

coerce 'RepeatedListLoggingServersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListLoggingServersResponse'->new($_) } @$_ ] };

declare 'MapStringListLoggingServersResponse',
    as HashRef[ListLoggingServersResponse()];

declare 'GetLoggingServerRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::GetLoggingServerRequest'];

coerce 'GetLoggingServerRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GetLoggingServerRequest'->new($_) };

declare 'RepeatedGetLoggingServerRequest',
    as ArrayRef[GetLoggingServerRequest()];

coerce 'RepeatedGetLoggingServerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GetLoggingServerRequest'->new($_) } @$_ ] };

declare 'MapStringGetLoggingServerRequest',
    as HashRef[GetLoggingServerRequest()];

declare 'CreateLoggingServerRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::CreateLoggingServerRequest'];

coerce 'CreateLoggingServerRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::CreateLoggingServerRequest'->new($_) };

declare 'RepeatedCreateLoggingServerRequest',
    as ArrayRef[CreateLoggingServerRequest()];

coerce 'RepeatedCreateLoggingServerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::CreateLoggingServerRequest'->new($_) } @$_ ] };

declare 'MapStringCreateLoggingServerRequest',
    as HashRef[CreateLoggingServerRequest()];

declare 'UpdateLoggingServerRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdateLoggingServerRequest'];

coerce 'UpdateLoggingServerRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdateLoggingServerRequest'->new($_) };

declare 'RepeatedUpdateLoggingServerRequest',
    as ArrayRef[UpdateLoggingServerRequest()];

coerce 'RepeatedUpdateLoggingServerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdateLoggingServerRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateLoggingServerRequest',
    as HashRef[UpdateLoggingServerRequest()];

declare 'DeleteLoggingServerRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::DeleteLoggingServerRequest'];

coerce 'DeleteLoggingServerRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::DeleteLoggingServerRequest'->new($_) };

declare 'RepeatedDeleteLoggingServerRequest',
    as ArrayRef[DeleteLoggingServerRequest()];

coerce 'RepeatedDeleteLoggingServerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::DeleteLoggingServerRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteLoggingServerRequest',
    as HashRef[DeleteLoggingServerRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'ListNodeTypesRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ListNodeTypesRequest'];

coerce 'ListNodeTypesRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListNodeTypesRequest'->new($_) };

declare 'RepeatedListNodeTypesRequest',
    as ArrayRef[ListNodeTypesRequest()];

coerce 'RepeatedListNodeTypesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListNodeTypesRequest'->new($_) } @$_ ] };

declare 'MapStringListNodeTypesRequest',
    as HashRef[ListNodeTypesRequest()];

declare 'ListNodeTypesResponse',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ListNodeTypesResponse'];

coerce 'ListNodeTypesResponse',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListNodeTypesResponse'->new($_) };

declare 'RepeatedListNodeTypesResponse',
    as ArrayRef[ListNodeTypesResponse()];

coerce 'RepeatedListNodeTypesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListNodeTypesResponse'->new($_) } @$_ ] };

declare 'MapStringListNodeTypesResponse',
    as HashRef[ListNodeTypesResponse()];

declare 'GetNodeTypeRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::GetNodeTypeRequest'];

coerce 'GetNodeTypeRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GetNodeTypeRequest'->new($_) };

declare 'RepeatedGetNodeTypeRequest',
    as ArrayRef[GetNodeTypeRequest()];

coerce 'RepeatedGetNodeTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GetNodeTypeRequest'->new($_) } @$_ ] };

declare 'MapStringGetNodeTypeRequest',
    as HashRef[GetNodeTypeRequest()];

declare 'ShowNsxCredentialsRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ShowNsxCredentialsRequest'];

coerce 'ShowNsxCredentialsRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ShowNsxCredentialsRequest'->new($_) };

declare 'RepeatedShowNsxCredentialsRequest',
    as ArrayRef[ShowNsxCredentialsRequest()];

coerce 'RepeatedShowNsxCredentialsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ShowNsxCredentialsRequest'->new($_) } @$_ ] };

declare 'MapStringShowNsxCredentialsRequest',
    as HashRef[ShowNsxCredentialsRequest()];

declare 'ShowVcenterCredentialsRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ShowVcenterCredentialsRequest'];

coerce 'ShowVcenterCredentialsRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ShowVcenterCredentialsRequest'->new($_) };

declare 'RepeatedShowVcenterCredentialsRequest',
    as ArrayRef[ShowVcenterCredentialsRequest()];

coerce 'RepeatedShowVcenterCredentialsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ShowVcenterCredentialsRequest'->new($_) } @$_ ] };

declare 'MapStringShowVcenterCredentialsRequest',
    as HashRef[ShowVcenterCredentialsRequest()];

declare 'ResetNsxCredentialsRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ResetNsxCredentialsRequest'];

coerce 'ResetNsxCredentialsRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ResetNsxCredentialsRequest'->new($_) };

declare 'RepeatedResetNsxCredentialsRequest',
    as ArrayRef[ResetNsxCredentialsRequest()];

coerce 'RepeatedResetNsxCredentialsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ResetNsxCredentialsRequest'->new($_) } @$_ ] };

declare 'MapStringResetNsxCredentialsRequest',
    as HashRef[ResetNsxCredentialsRequest()];

declare 'ResetVcenterCredentialsRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ResetVcenterCredentialsRequest'];

coerce 'ResetVcenterCredentialsRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ResetVcenterCredentialsRequest'->new($_) };

declare 'RepeatedResetVcenterCredentialsRequest',
    as ArrayRef[ResetVcenterCredentialsRequest()];

coerce 'RepeatedResetVcenterCredentialsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ResetVcenterCredentialsRequest'->new($_) } @$_ ] };

declare 'MapStringResetVcenterCredentialsRequest',
    as HashRef[ResetVcenterCredentialsRequest()];

declare 'ListHcxActivationKeysResponse',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ListHcxActivationKeysResponse'];

coerce 'ListHcxActivationKeysResponse',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListHcxActivationKeysResponse'->new($_) };

declare 'RepeatedListHcxActivationKeysResponse',
    as ArrayRef[ListHcxActivationKeysResponse()];

coerce 'RepeatedListHcxActivationKeysResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListHcxActivationKeysResponse'->new($_) } @$_ ] };

declare 'MapStringListHcxActivationKeysResponse',
    as HashRef[ListHcxActivationKeysResponse()];

declare 'ListHcxActivationKeysRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ListHcxActivationKeysRequest'];

coerce 'ListHcxActivationKeysRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListHcxActivationKeysRequest'->new($_) };

declare 'RepeatedListHcxActivationKeysRequest',
    as ArrayRef[ListHcxActivationKeysRequest()];

coerce 'RepeatedListHcxActivationKeysRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListHcxActivationKeysRequest'->new($_) } @$_ ] };

declare 'MapStringListHcxActivationKeysRequest',
    as HashRef[ListHcxActivationKeysRequest()];

declare 'GetHcxActivationKeyRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::GetHcxActivationKeyRequest'];

coerce 'GetHcxActivationKeyRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GetHcxActivationKeyRequest'->new($_) };

declare 'RepeatedGetHcxActivationKeyRequest',
    as ArrayRef[GetHcxActivationKeyRequest()];

coerce 'RepeatedGetHcxActivationKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GetHcxActivationKeyRequest'->new($_) } @$_ ] };

declare 'MapStringGetHcxActivationKeyRequest',
    as HashRef[GetHcxActivationKeyRequest()];

declare 'CreateHcxActivationKeyRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::CreateHcxActivationKeyRequest'];

coerce 'CreateHcxActivationKeyRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::CreateHcxActivationKeyRequest'->new($_) };

declare 'RepeatedCreateHcxActivationKeyRequest',
    as ArrayRef[CreateHcxActivationKeyRequest()];

coerce 'RepeatedCreateHcxActivationKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::CreateHcxActivationKeyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateHcxActivationKeyRequest',
    as HashRef[CreateHcxActivationKeyRequest()];

declare 'GetDnsForwardingRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::GetDnsForwardingRequest'];

coerce 'GetDnsForwardingRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GetDnsForwardingRequest'->new($_) };

declare 'RepeatedGetDnsForwardingRequest',
    as ArrayRef[GetDnsForwardingRequest()];

coerce 'RepeatedGetDnsForwardingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GetDnsForwardingRequest'->new($_) } @$_ ] };

declare 'MapStringGetDnsForwardingRequest',
    as HashRef[GetDnsForwardingRequest()];

declare 'UpdateDnsForwardingRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdateDnsForwardingRequest'];

coerce 'UpdateDnsForwardingRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdateDnsForwardingRequest'->new($_) };

declare 'RepeatedUpdateDnsForwardingRequest',
    as ArrayRef[UpdateDnsForwardingRequest()];

coerce 'RepeatedUpdateDnsForwardingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdateDnsForwardingRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDnsForwardingRequest',
    as HashRef[UpdateDnsForwardingRequest()];

declare 'CreateNetworkPeeringRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::CreateNetworkPeeringRequest'];

coerce 'CreateNetworkPeeringRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::CreateNetworkPeeringRequest'->new($_) };

declare 'RepeatedCreateNetworkPeeringRequest',
    as ArrayRef[CreateNetworkPeeringRequest()];

coerce 'RepeatedCreateNetworkPeeringRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::CreateNetworkPeeringRequest'->new($_) } @$_ ] };

declare 'MapStringCreateNetworkPeeringRequest',
    as HashRef[CreateNetworkPeeringRequest()];

declare 'DeleteNetworkPeeringRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::DeleteNetworkPeeringRequest'];

coerce 'DeleteNetworkPeeringRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::DeleteNetworkPeeringRequest'->new($_) };

declare 'RepeatedDeleteNetworkPeeringRequest',
    as ArrayRef[DeleteNetworkPeeringRequest()];

coerce 'RepeatedDeleteNetworkPeeringRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::DeleteNetworkPeeringRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteNetworkPeeringRequest',
    as HashRef[DeleteNetworkPeeringRequest()];

declare 'GetNetworkPeeringRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::GetNetworkPeeringRequest'];

coerce 'GetNetworkPeeringRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GetNetworkPeeringRequest'->new($_) };

declare 'RepeatedGetNetworkPeeringRequest',
    as ArrayRef[GetNetworkPeeringRequest()];

coerce 'RepeatedGetNetworkPeeringRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GetNetworkPeeringRequest'->new($_) } @$_ ] };

declare 'MapStringGetNetworkPeeringRequest',
    as HashRef[GetNetworkPeeringRequest()];

declare 'ListNetworkPeeringsRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ListNetworkPeeringsRequest'];

coerce 'ListNetworkPeeringsRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListNetworkPeeringsRequest'->new($_) };

declare 'RepeatedListNetworkPeeringsRequest',
    as ArrayRef[ListNetworkPeeringsRequest()];

coerce 'RepeatedListNetworkPeeringsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListNetworkPeeringsRequest'->new($_) } @$_ ] };

declare 'MapStringListNetworkPeeringsRequest',
    as HashRef[ListNetworkPeeringsRequest()];

declare 'UpdateNetworkPeeringRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdateNetworkPeeringRequest'];

coerce 'UpdateNetworkPeeringRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdateNetworkPeeringRequest'->new($_) };

declare 'RepeatedUpdateNetworkPeeringRequest',
    as ArrayRef[UpdateNetworkPeeringRequest()];

coerce 'RepeatedUpdateNetworkPeeringRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdateNetworkPeeringRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateNetworkPeeringRequest',
    as HashRef[UpdateNetworkPeeringRequest()];

declare 'ListNetworkPeeringsResponse',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ListNetworkPeeringsResponse'];

coerce 'ListNetworkPeeringsResponse',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListNetworkPeeringsResponse'->new($_) };

declare 'RepeatedListNetworkPeeringsResponse',
    as ArrayRef[ListNetworkPeeringsResponse()];

coerce 'RepeatedListNetworkPeeringsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListNetworkPeeringsResponse'->new($_) } @$_ ] };

declare 'MapStringListNetworkPeeringsResponse',
    as HashRef[ListNetworkPeeringsResponse()];

declare 'ListPeeringRoutesRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ListPeeringRoutesRequest'];

coerce 'ListPeeringRoutesRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListPeeringRoutesRequest'->new($_) };

declare 'RepeatedListPeeringRoutesRequest',
    as ArrayRef[ListPeeringRoutesRequest()];

coerce 'RepeatedListPeeringRoutesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListPeeringRoutesRequest'->new($_) } @$_ ] };

declare 'MapStringListPeeringRoutesRequest',
    as HashRef[ListPeeringRoutesRequest()];

declare 'ListPeeringRoutesResponse',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ListPeeringRoutesResponse'];

coerce 'ListPeeringRoutesResponse',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListPeeringRoutesResponse'->new($_) };

declare 'RepeatedListPeeringRoutesResponse',
    as ArrayRef[ListPeeringRoutesResponse()];

coerce 'RepeatedListPeeringRoutesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListPeeringRoutesResponse'->new($_) } @$_ ] };

declare 'MapStringListPeeringRoutesResponse',
    as HashRef[ListPeeringRoutesResponse()];

declare 'ListNetworkPoliciesRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ListNetworkPoliciesRequest'];

coerce 'ListNetworkPoliciesRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListNetworkPoliciesRequest'->new($_) };

declare 'RepeatedListNetworkPoliciesRequest',
    as ArrayRef[ListNetworkPoliciesRequest()];

coerce 'RepeatedListNetworkPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListNetworkPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringListNetworkPoliciesRequest',
    as HashRef[ListNetworkPoliciesRequest()];

declare 'ListNetworkPoliciesResponse',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ListNetworkPoliciesResponse'];

coerce 'ListNetworkPoliciesResponse',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListNetworkPoliciesResponse'->new($_) };

declare 'RepeatedListNetworkPoliciesResponse',
    as ArrayRef[ListNetworkPoliciesResponse()];

coerce 'RepeatedListNetworkPoliciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListNetworkPoliciesResponse'->new($_) } @$_ ] };

declare 'MapStringListNetworkPoliciesResponse',
    as HashRef[ListNetworkPoliciesResponse()];

declare 'GetNetworkPolicyRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::GetNetworkPolicyRequest'];

coerce 'GetNetworkPolicyRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GetNetworkPolicyRequest'->new($_) };

declare 'RepeatedGetNetworkPolicyRequest',
    as ArrayRef[GetNetworkPolicyRequest()];

coerce 'RepeatedGetNetworkPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GetNetworkPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetNetworkPolicyRequest',
    as HashRef[GetNetworkPolicyRequest()];

declare 'UpdateNetworkPolicyRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdateNetworkPolicyRequest'];

coerce 'UpdateNetworkPolicyRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdateNetworkPolicyRequest'->new($_) };

declare 'RepeatedUpdateNetworkPolicyRequest',
    as ArrayRef[UpdateNetworkPolicyRequest()];

coerce 'RepeatedUpdateNetworkPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdateNetworkPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateNetworkPolicyRequest',
    as HashRef[UpdateNetworkPolicyRequest()];

declare 'CreateNetworkPolicyRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::CreateNetworkPolicyRequest'];

coerce 'CreateNetworkPolicyRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::CreateNetworkPolicyRequest'->new($_) };

declare 'RepeatedCreateNetworkPolicyRequest',
    as ArrayRef[CreateNetworkPolicyRequest()];

coerce 'RepeatedCreateNetworkPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::CreateNetworkPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateNetworkPolicyRequest',
    as HashRef[CreateNetworkPolicyRequest()];

declare 'DeleteNetworkPolicyRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::DeleteNetworkPolicyRequest'];

coerce 'DeleteNetworkPolicyRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::DeleteNetworkPolicyRequest'->new($_) };

declare 'RepeatedDeleteNetworkPolicyRequest',
    as ArrayRef[DeleteNetworkPolicyRequest()];

coerce 'RepeatedDeleteNetworkPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::DeleteNetworkPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteNetworkPolicyRequest',
    as HashRef[DeleteNetworkPolicyRequest()];

declare 'ListManagementDnsZoneBindingsRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ListManagementDnsZoneBindingsRequest'];

coerce 'ListManagementDnsZoneBindingsRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListManagementDnsZoneBindingsRequest'->new($_) };

declare 'RepeatedListManagementDnsZoneBindingsRequest',
    as ArrayRef[ListManagementDnsZoneBindingsRequest()];

coerce 'RepeatedListManagementDnsZoneBindingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListManagementDnsZoneBindingsRequest'->new($_) } @$_ ] };

declare 'MapStringListManagementDnsZoneBindingsRequest',
    as HashRef[ListManagementDnsZoneBindingsRequest()];

declare 'ListManagementDnsZoneBindingsResponse',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ListManagementDnsZoneBindingsResponse'];

coerce 'ListManagementDnsZoneBindingsResponse',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListManagementDnsZoneBindingsResponse'->new($_) };

declare 'RepeatedListManagementDnsZoneBindingsResponse',
    as ArrayRef[ListManagementDnsZoneBindingsResponse()];

coerce 'RepeatedListManagementDnsZoneBindingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListManagementDnsZoneBindingsResponse'->new($_) } @$_ ] };

declare 'MapStringListManagementDnsZoneBindingsResponse',
    as HashRef[ListManagementDnsZoneBindingsResponse()];

declare 'GetManagementDnsZoneBindingRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::GetManagementDnsZoneBindingRequest'];

coerce 'GetManagementDnsZoneBindingRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GetManagementDnsZoneBindingRequest'->new($_) };

declare 'RepeatedGetManagementDnsZoneBindingRequest',
    as ArrayRef[GetManagementDnsZoneBindingRequest()];

coerce 'RepeatedGetManagementDnsZoneBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GetManagementDnsZoneBindingRequest'->new($_) } @$_ ] };

declare 'MapStringGetManagementDnsZoneBindingRequest',
    as HashRef[GetManagementDnsZoneBindingRequest()];

declare 'CreateManagementDnsZoneBindingRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::CreateManagementDnsZoneBindingRequest'];

coerce 'CreateManagementDnsZoneBindingRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::CreateManagementDnsZoneBindingRequest'->new($_) };

declare 'RepeatedCreateManagementDnsZoneBindingRequest',
    as ArrayRef[CreateManagementDnsZoneBindingRequest()];

coerce 'RepeatedCreateManagementDnsZoneBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::CreateManagementDnsZoneBindingRequest'->new($_) } @$_ ] };

declare 'MapStringCreateManagementDnsZoneBindingRequest',
    as HashRef[CreateManagementDnsZoneBindingRequest()];

declare 'UpdateManagementDnsZoneBindingRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdateManagementDnsZoneBindingRequest'];

coerce 'UpdateManagementDnsZoneBindingRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdateManagementDnsZoneBindingRequest'->new($_) };

declare 'RepeatedUpdateManagementDnsZoneBindingRequest',
    as ArrayRef[UpdateManagementDnsZoneBindingRequest()];

coerce 'RepeatedUpdateManagementDnsZoneBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdateManagementDnsZoneBindingRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateManagementDnsZoneBindingRequest',
    as HashRef[UpdateManagementDnsZoneBindingRequest()];

declare 'DeleteManagementDnsZoneBindingRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::DeleteManagementDnsZoneBindingRequest'];

coerce 'DeleteManagementDnsZoneBindingRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::DeleteManagementDnsZoneBindingRequest'->new($_) };

declare 'RepeatedDeleteManagementDnsZoneBindingRequest',
    as ArrayRef[DeleteManagementDnsZoneBindingRequest()];

coerce 'RepeatedDeleteManagementDnsZoneBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::DeleteManagementDnsZoneBindingRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteManagementDnsZoneBindingRequest',
    as HashRef[DeleteManagementDnsZoneBindingRequest()];

declare 'RepairManagementDnsZoneBindingRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::RepairManagementDnsZoneBindingRequest'];

coerce 'RepairManagementDnsZoneBindingRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::RepairManagementDnsZoneBindingRequest'->new($_) };

declare 'RepeatedRepairManagementDnsZoneBindingRequest',
    as ArrayRef[RepairManagementDnsZoneBindingRequest()];

coerce 'RepeatedRepairManagementDnsZoneBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::RepairManagementDnsZoneBindingRequest'->new($_) } @$_ ] };

declare 'MapStringRepairManagementDnsZoneBindingRequest',
    as HashRef[RepairManagementDnsZoneBindingRequest()];

declare 'CreateVmwareEngineNetworkRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::CreateVmwareEngineNetworkRequest'];

coerce 'CreateVmwareEngineNetworkRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::CreateVmwareEngineNetworkRequest'->new($_) };

declare 'RepeatedCreateVmwareEngineNetworkRequest',
    as ArrayRef[CreateVmwareEngineNetworkRequest()];

coerce 'RepeatedCreateVmwareEngineNetworkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::CreateVmwareEngineNetworkRequest'->new($_) } @$_ ] };

declare 'MapStringCreateVmwareEngineNetworkRequest',
    as HashRef[CreateVmwareEngineNetworkRequest()];

declare 'UpdateVmwareEngineNetworkRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdateVmwareEngineNetworkRequest'];

coerce 'UpdateVmwareEngineNetworkRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdateVmwareEngineNetworkRequest'->new($_) };

declare 'RepeatedUpdateVmwareEngineNetworkRequest',
    as ArrayRef[UpdateVmwareEngineNetworkRequest()];

coerce 'RepeatedUpdateVmwareEngineNetworkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdateVmwareEngineNetworkRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateVmwareEngineNetworkRequest',
    as HashRef[UpdateVmwareEngineNetworkRequest()];

declare 'DeleteVmwareEngineNetworkRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::DeleteVmwareEngineNetworkRequest'];

coerce 'DeleteVmwareEngineNetworkRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::DeleteVmwareEngineNetworkRequest'->new($_) };

declare 'RepeatedDeleteVmwareEngineNetworkRequest',
    as ArrayRef[DeleteVmwareEngineNetworkRequest()];

coerce 'RepeatedDeleteVmwareEngineNetworkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::DeleteVmwareEngineNetworkRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteVmwareEngineNetworkRequest',
    as HashRef[DeleteVmwareEngineNetworkRequest()];

declare 'GetVmwareEngineNetworkRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::GetVmwareEngineNetworkRequest'];

coerce 'GetVmwareEngineNetworkRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GetVmwareEngineNetworkRequest'->new($_) };

declare 'RepeatedGetVmwareEngineNetworkRequest',
    as ArrayRef[GetVmwareEngineNetworkRequest()];

coerce 'RepeatedGetVmwareEngineNetworkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GetVmwareEngineNetworkRequest'->new($_) } @$_ ] };

declare 'MapStringGetVmwareEngineNetworkRequest',
    as HashRef[GetVmwareEngineNetworkRequest()];

declare 'ListVmwareEngineNetworksRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ListVmwareEngineNetworksRequest'];

coerce 'ListVmwareEngineNetworksRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListVmwareEngineNetworksRequest'->new($_) };

declare 'RepeatedListVmwareEngineNetworksRequest',
    as ArrayRef[ListVmwareEngineNetworksRequest()];

coerce 'RepeatedListVmwareEngineNetworksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListVmwareEngineNetworksRequest'->new($_) } @$_ ] };

declare 'MapStringListVmwareEngineNetworksRequest',
    as HashRef[ListVmwareEngineNetworksRequest()];

declare 'ListVmwareEngineNetworksResponse',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ListVmwareEngineNetworksResponse'];

coerce 'ListVmwareEngineNetworksResponse',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListVmwareEngineNetworksResponse'->new($_) };

declare 'RepeatedListVmwareEngineNetworksResponse',
    as ArrayRef[ListVmwareEngineNetworksResponse()];

coerce 'RepeatedListVmwareEngineNetworksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListVmwareEngineNetworksResponse'->new($_) } @$_ ] };

declare 'MapStringListVmwareEngineNetworksResponse',
    as HashRef[ListVmwareEngineNetworksResponse()];

declare 'CreatePrivateConnectionRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::CreatePrivateConnectionRequest'];

coerce 'CreatePrivateConnectionRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::CreatePrivateConnectionRequest'->new($_) };

declare 'RepeatedCreatePrivateConnectionRequest',
    as ArrayRef[CreatePrivateConnectionRequest()];

coerce 'RepeatedCreatePrivateConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::CreatePrivateConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringCreatePrivateConnectionRequest',
    as HashRef[CreatePrivateConnectionRequest()];

declare 'GetPrivateConnectionRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::GetPrivateConnectionRequest'];

coerce 'GetPrivateConnectionRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GetPrivateConnectionRequest'->new($_) };

declare 'RepeatedGetPrivateConnectionRequest',
    as ArrayRef[GetPrivateConnectionRequest()];

coerce 'RepeatedGetPrivateConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GetPrivateConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringGetPrivateConnectionRequest',
    as HashRef[GetPrivateConnectionRequest()];

declare 'ListPrivateConnectionsRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ListPrivateConnectionsRequest'];

coerce 'ListPrivateConnectionsRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListPrivateConnectionsRequest'->new($_) };

declare 'RepeatedListPrivateConnectionsRequest',
    as ArrayRef[ListPrivateConnectionsRequest()];

coerce 'RepeatedListPrivateConnectionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListPrivateConnectionsRequest'->new($_) } @$_ ] };

declare 'MapStringListPrivateConnectionsRequest',
    as HashRef[ListPrivateConnectionsRequest()];

declare 'ListPrivateConnectionsResponse',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ListPrivateConnectionsResponse'];

coerce 'ListPrivateConnectionsResponse',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListPrivateConnectionsResponse'->new($_) };

declare 'RepeatedListPrivateConnectionsResponse',
    as ArrayRef[ListPrivateConnectionsResponse()];

coerce 'RepeatedListPrivateConnectionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListPrivateConnectionsResponse'->new($_) } @$_ ] };

declare 'MapStringListPrivateConnectionsResponse',
    as HashRef[ListPrivateConnectionsResponse()];

declare 'UpdatePrivateConnectionRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdatePrivateConnectionRequest'];

coerce 'UpdatePrivateConnectionRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdatePrivateConnectionRequest'->new($_) };

declare 'RepeatedUpdatePrivateConnectionRequest',
    as ArrayRef[UpdatePrivateConnectionRequest()];

coerce 'RepeatedUpdatePrivateConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdatePrivateConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdatePrivateConnectionRequest',
    as HashRef[UpdatePrivateConnectionRequest()];

declare 'DeletePrivateConnectionRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::DeletePrivateConnectionRequest'];

coerce 'DeletePrivateConnectionRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::DeletePrivateConnectionRequest'->new($_) };

declare 'RepeatedDeletePrivateConnectionRequest',
    as ArrayRef[DeletePrivateConnectionRequest()];

coerce 'RepeatedDeletePrivateConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::DeletePrivateConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePrivateConnectionRequest',
    as HashRef[DeletePrivateConnectionRequest()];

declare 'ListPrivateConnectionPeeringRoutesRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ListPrivateConnectionPeeringRoutesRequest'];

coerce 'ListPrivateConnectionPeeringRoutesRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListPrivateConnectionPeeringRoutesRequest'->new($_) };

declare 'RepeatedListPrivateConnectionPeeringRoutesRequest',
    as ArrayRef[ListPrivateConnectionPeeringRoutesRequest()];

coerce 'RepeatedListPrivateConnectionPeeringRoutesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListPrivateConnectionPeeringRoutesRequest'->new($_) } @$_ ] };

declare 'MapStringListPrivateConnectionPeeringRoutesRequest',
    as HashRef[ListPrivateConnectionPeeringRoutesRequest()];

declare 'ListPrivateConnectionPeeringRoutesResponse',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::ListPrivateConnectionPeeringRoutesResponse'];

coerce 'ListPrivateConnectionPeeringRoutesResponse',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListPrivateConnectionPeeringRoutesResponse'->new($_) };

declare 'RepeatedListPrivateConnectionPeeringRoutesResponse',
    as ArrayRef[ListPrivateConnectionPeeringRoutesResponse()];

coerce 'RepeatedListPrivateConnectionPeeringRoutesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListPrivateConnectionPeeringRoutesResponse'->new($_) } @$_ ] };

declare 'MapStringListPrivateConnectionPeeringRoutesResponse',
    as HashRef[ListPrivateConnectionPeeringRoutesResponse()];

declare 'GrantDnsBindPermissionRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::GrantDnsBindPermissionRequest'];

coerce 'GrantDnsBindPermissionRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GrantDnsBindPermissionRequest'->new($_) };

declare 'RepeatedGrantDnsBindPermissionRequest',
    as ArrayRef[GrantDnsBindPermissionRequest()];

coerce 'RepeatedGrantDnsBindPermissionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GrantDnsBindPermissionRequest'->new($_) } @$_ ] };

declare 'MapStringGrantDnsBindPermissionRequest',
    as HashRef[GrantDnsBindPermissionRequest()];

declare 'RevokeDnsBindPermissionRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::RevokeDnsBindPermissionRequest'];

coerce 'RevokeDnsBindPermissionRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::RevokeDnsBindPermissionRequest'->new($_) };

declare 'RepeatedRevokeDnsBindPermissionRequest',
    as ArrayRef[RevokeDnsBindPermissionRequest()];

coerce 'RepeatedRevokeDnsBindPermissionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::RevokeDnsBindPermissionRequest'->new($_) } @$_ ] };

declare 'MapStringRevokeDnsBindPermissionRequest',
    as HashRef[RevokeDnsBindPermissionRequest()];

declare 'GetDnsBindPermissionRequest',
    as InstanceOf['Google::Cloud::Vmwareengine::V1::Vmwareengine::GetDnsBindPermissionRequest'];

coerce 'GetDnsBindPermissionRequest',
    from HashRef, via { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GetDnsBindPermissionRequest'->new($_) };

declare 'RepeatedGetDnsBindPermissionRequest',
    as ArrayRef[GetDnsBindPermissionRequest()];

coerce 'RepeatedGetDnsBindPermissionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vmwareengine::V1::Vmwareengine::GetDnsBindPermissionRequest'->new($_) } @$_ ] };

declare 'MapStringGetDnsBindPermissionRequest',
    as HashRef[GetDnsBindPermissionRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Vmwareengine::V1::Vmwareengine::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
