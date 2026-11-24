package Google::Cloud::Edgecontainer::V1::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Service::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Service::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Service::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'StatusReason',
    as (Int | Str);

declare 'ListClustersRequest',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Service::ListClustersRequest'];

coerce 'ListClustersRequest',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Service::ListClustersRequest'->new($_) };

declare 'RepeatedListClustersRequest',
    as ArrayRef[ListClustersRequest()];

coerce 'RepeatedListClustersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Service::ListClustersRequest'->new($_) } @$_ ] };

declare 'MapStringListClustersRequest',
    as HashRef[ListClustersRequest()];

declare 'ListClustersResponse',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Service::ListClustersResponse'];

coerce 'ListClustersResponse',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Service::ListClustersResponse'->new($_) };

declare 'RepeatedListClustersResponse',
    as ArrayRef[ListClustersResponse()];

coerce 'RepeatedListClustersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Service::ListClustersResponse'->new($_) } @$_ ] };

declare 'MapStringListClustersResponse',
    as HashRef[ListClustersResponse()];

declare 'GetClusterRequest',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Service::GetClusterRequest'];

coerce 'GetClusterRequest',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Service::GetClusterRequest'->new($_) };

declare 'RepeatedGetClusterRequest',
    as ArrayRef[GetClusterRequest()];

coerce 'RepeatedGetClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Service::GetClusterRequest'->new($_) } @$_ ] };

declare 'MapStringGetClusterRequest',
    as HashRef[GetClusterRequest()];

declare 'CreateClusterRequest',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Service::CreateClusterRequest'];

coerce 'CreateClusterRequest',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Service::CreateClusterRequest'->new($_) };

declare 'RepeatedCreateClusterRequest',
    as ArrayRef[CreateClusterRequest()];

coerce 'RepeatedCreateClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Service::CreateClusterRequest'->new($_) } @$_ ] };

declare 'MapStringCreateClusterRequest',
    as HashRef[CreateClusterRequest()];

declare 'UpdateClusterRequest',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Service::UpdateClusterRequest'];

coerce 'UpdateClusterRequest',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Service::UpdateClusterRequest'->new($_) };

declare 'RepeatedUpdateClusterRequest',
    as ArrayRef[UpdateClusterRequest()];

coerce 'RepeatedUpdateClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Service::UpdateClusterRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateClusterRequest',
    as HashRef[UpdateClusterRequest()];

declare 'UpgradeClusterRequest',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Service::UpgradeClusterRequest'];

coerce 'UpgradeClusterRequest',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Service::UpgradeClusterRequest'->new($_) };

declare 'RepeatedUpgradeClusterRequest',
    as ArrayRef[UpgradeClusterRequest()];

coerce 'RepeatedUpgradeClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Service::UpgradeClusterRequest'->new($_) } @$_ ] };

declare 'MapStringUpgradeClusterRequest',
    as HashRef[UpgradeClusterRequest()];

declare 'Schedule',
    as (Int | Str);

declare 'DeleteClusterRequest',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Service::DeleteClusterRequest'];

coerce 'DeleteClusterRequest',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Service::DeleteClusterRequest'->new($_) };

declare 'RepeatedDeleteClusterRequest',
    as ArrayRef[DeleteClusterRequest()];

coerce 'RepeatedDeleteClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Service::DeleteClusterRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteClusterRequest',
    as HashRef[DeleteClusterRequest()];

declare 'GenerateAccessTokenRequest',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Service::GenerateAccessTokenRequest'];

coerce 'GenerateAccessTokenRequest',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Service::GenerateAccessTokenRequest'->new($_) };

declare 'RepeatedGenerateAccessTokenRequest',
    as ArrayRef[GenerateAccessTokenRequest()];

coerce 'RepeatedGenerateAccessTokenRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Service::GenerateAccessTokenRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateAccessTokenRequest',
    as HashRef[GenerateAccessTokenRequest()];

declare 'GenerateAccessTokenResponse',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Service::GenerateAccessTokenResponse'];

coerce 'GenerateAccessTokenResponse',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Service::GenerateAccessTokenResponse'->new($_) };

declare 'RepeatedGenerateAccessTokenResponse',
    as ArrayRef[GenerateAccessTokenResponse()];

coerce 'RepeatedGenerateAccessTokenResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Service::GenerateAccessTokenResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateAccessTokenResponse',
    as HashRef[GenerateAccessTokenResponse()];

declare 'GenerateOfflineCredentialRequest',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Service::GenerateOfflineCredentialRequest'];

coerce 'GenerateOfflineCredentialRequest',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Service::GenerateOfflineCredentialRequest'->new($_) };

declare 'RepeatedGenerateOfflineCredentialRequest',
    as ArrayRef[GenerateOfflineCredentialRequest()];

coerce 'RepeatedGenerateOfflineCredentialRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Service::GenerateOfflineCredentialRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateOfflineCredentialRequest',
    as HashRef[GenerateOfflineCredentialRequest()];

declare 'GenerateOfflineCredentialResponse',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Service::GenerateOfflineCredentialResponse'];

coerce 'GenerateOfflineCredentialResponse',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Service::GenerateOfflineCredentialResponse'->new($_) };

declare 'RepeatedGenerateOfflineCredentialResponse',
    as ArrayRef[GenerateOfflineCredentialResponse()];

coerce 'RepeatedGenerateOfflineCredentialResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Service::GenerateOfflineCredentialResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateOfflineCredentialResponse',
    as HashRef[GenerateOfflineCredentialResponse()];

declare 'ListNodePoolsRequest',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Service::ListNodePoolsRequest'];

coerce 'ListNodePoolsRequest',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Service::ListNodePoolsRequest'->new($_) };

declare 'RepeatedListNodePoolsRequest',
    as ArrayRef[ListNodePoolsRequest()];

coerce 'RepeatedListNodePoolsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Service::ListNodePoolsRequest'->new($_) } @$_ ] };

declare 'MapStringListNodePoolsRequest',
    as HashRef[ListNodePoolsRequest()];

declare 'ListNodePoolsResponse',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Service::ListNodePoolsResponse'];

coerce 'ListNodePoolsResponse',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Service::ListNodePoolsResponse'->new($_) };

declare 'RepeatedListNodePoolsResponse',
    as ArrayRef[ListNodePoolsResponse()];

coerce 'RepeatedListNodePoolsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Service::ListNodePoolsResponse'->new($_) } @$_ ] };

declare 'MapStringListNodePoolsResponse',
    as HashRef[ListNodePoolsResponse()];

declare 'GetNodePoolRequest',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Service::GetNodePoolRequest'];

coerce 'GetNodePoolRequest',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Service::GetNodePoolRequest'->new($_) };

declare 'RepeatedGetNodePoolRequest',
    as ArrayRef[GetNodePoolRequest()];

coerce 'RepeatedGetNodePoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Service::GetNodePoolRequest'->new($_) } @$_ ] };

declare 'MapStringGetNodePoolRequest',
    as HashRef[GetNodePoolRequest()];

declare 'CreateNodePoolRequest',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Service::CreateNodePoolRequest'];

coerce 'CreateNodePoolRequest',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Service::CreateNodePoolRequest'->new($_) };

declare 'RepeatedCreateNodePoolRequest',
    as ArrayRef[CreateNodePoolRequest()];

coerce 'RepeatedCreateNodePoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Service::CreateNodePoolRequest'->new($_) } @$_ ] };

declare 'MapStringCreateNodePoolRequest',
    as HashRef[CreateNodePoolRequest()];

declare 'UpdateNodePoolRequest',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Service::UpdateNodePoolRequest'];

coerce 'UpdateNodePoolRequest',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Service::UpdateNodePoolRequest'->new($_) };

declare 'RepeatedUpdateNodePoolRequest',
    as ArrayRef[UpdateNodePoolRequest()];

coerce 'RepeatedUpdateNodePoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Service::UpdateNodePoolRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateNodePoolRequest',
    as HashRef[UpdateNodePoolRequest()];

declare 'DeleteNodePoolRequest',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Service::DeleteNodePoolRequest'];

coerce 'DeleteNodePoolRequest',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Service::DeleteNodePoolRequest'->new($_) };

declare 'RepeatedDeleteNodePoolRequest',
    as ArrayRef[DeleteNodePoolRequest()];

coerce 'RepeatedDeleteNodePoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Service::DeleteNodePoolRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteNodePoolRequest',
    as HashRef[DeleteNodePoolRequest()];

declare 'ListMachinesRequest',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Service::ListMachinesRequest'];

coerce 'ListMachinesRequest',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Service::ListMachinesRequest'->new($_) };

declare 'RepeatedListMachinesRequest',
    as ArrayRef[ListMachinesRequest()];

coerce 'RepeatedListMachinesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Service::ListMachinesRequest'->new($_) } @$_ ] };

declare 'MapStringListMachinesRequest',
    as HashRef[ListMachinesRequest()];

declare 'ListMachinesResponse',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Service::ListMachinesResponse'];

coerce 'ListMachinesResponse',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Service::ListMachinesResponse'->new($_) };

declare 'RepeatedListMachinesResponse',
    as ArrayRef[ListMachinesResponse()];

coerce 'RepeatedListMachinesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Service::ListMachinesResponse'->new($_) } @$_ ] };

declare 'MapStringListMachinesResponse',
    as HashRef[ListMachinesResponse()];

declare 'GetMachineRequest',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Service::GetMachineRequest'];

coerce 'GetMachineRequest',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Service::GetMachineRequest'->new($_) };

declare 'RepeatedGetMachineRequest',
    as ArrayRef[GetMachineRequest()];

coerce 'RepeatedGetMachineRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Service::GetMachineRequest'->new($_) } @$_ ] };

declare 'MapStringGetMachineRequest',
    as HashRef[GetMachineRequest()];

declare 'ListVpnConnectionsRequest',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Service::ListVpnConnectionsRequest'];

coerce 'ListVpnConnectionsRequest',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Service::ListVpnConnectionsRequest'->new($_) };

declare 'RepeatedListVpnConnectionsRequest',
    as ArrayRef[ListVpnConnectionsRequest()];

coerce 'RepeatedListVpnConnectionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Service::ListVpnConnectionsRequest'->new($_) } @$_ ] };

declare 'MapStringListVpnConnectionsRequest',
    as HashRef[ListVpnConnectionsRequest()];

declare 'ListVpnConnectionsResponse',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Service::ListVpnConnectionsResponse'];

coerce 'ListVpnConnectionsResponse',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Service::ListVpnConnectionsResponse'->new($_) };

declare 'RepeatedListVpnConnectionsResponse',
    as ArrayRef[ListVpnConnectionsResponse()];

coerce 'RepeatedListVpnConnectionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Service::ListVpnConnectionsResponse'->new($_) } @$_ ] };

declare 'MapStringListVpnConnectionsResponse',
    as HashRef[ListVpnConnectionsResponse()];

declare 'GetVpnConnectionRequest',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Service::GetVpnConnectionRequest'];

coerce 'GetVpnConnectionRequest',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Service::GetVpnConnectionRequest'->new($_) };

declare 'RepeatedGetVpnConnectionRequest',
    as ArrayRef[GetVpnConnectionRequest()];

coerce 'RepeatedGetVpnConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Service::GetVpnConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringGetVpnConnectionRequest',
    as HashRef[GetVpnConnectionRequest()];

declare 'CreateVpnConnectionRequest',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Service::CreateVpnConnectionRequest'];

coerce 'CreateVpnConnectionRequest',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Service::CreateVpnConnectionRequest'->new($_) };

declare 'RepeatedCreateVpnConnectionRequest',
    as ArrayRef[CreateVpnConnectionRequest()];

coerce 'RepeatedCreateVpnConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Service::CreateVpnConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateVpnConnectionRequest',
    as HashRef[CreateVpnConnectionRequest()];

declare 'DeleteVpnConnectionRequest',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Service::DeleteVpnConnectionRequest'];

coerce 'DeleteVpnConnectionRequest',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Service::DeleteVpnConnectionRequest'->new($_) };

declare 'RepeatedDeleteVpnConnectionRequest',
    as ArrayRef[DeleteVpnConnectionRequest()];

coerce 'RepeatedDeleteVpnConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Service::DeleteVpnConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteVpnConnectionRequest',
    as HashRef[DeleteVpnConnectionRequest()];

declare 'GetServerConfigRequest',
    as InstanceOf['Google::Cloud::Edgecontainer::V1::Service::GetServerConfigRequest'];

coerce 'GetServerConfigRequest',
    from HashRef, via { 'Google::Cloud::Edgecontainer::V1::Service::GetServerConfigRequest'->new($_) };

declare 'RepeatedGetServerConfigRequest',
    as ArrayRef[GetServerConfigRequest()];

coerce 'RepeatedGetServerConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Edgecontainer::V1::Service::GetServerConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetServerConfigRequest',
    as HashRef[GetServerConfigRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Edgecontainer::V1::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
