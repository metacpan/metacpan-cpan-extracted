package Google::Cloud::Oracledatabase::V1::Oracledatabase::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListCloudExadataInfrastructuresRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::ListCloudExadataInfrastructuresRequest'];

coerce 'ListCloudExadataInfrastructuresRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListCloudExadataInfrastructuresRequest'->new($_) };

declare 'RepeatedListCloudExadataInfrastructuresRequest',
    as ArrayRef[ListCloudExadataInfrastructuresRequest()];

coerce 'RepeatedListCloudExadataInfrastructuresRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListCloudExadataInfrastructuresRequest'->new($_) } @$_ ] };

declare 'MapStringListCloudExadataInfrastructuresRequest',
    as HashRef[ListCloudExadataInfrastructuresRequest()];

declare 'ListCloudExadataInfrastructuresResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::ListCloudExadataInfrastructuresResponse'];

coerce 'ListCloudExadataInfrastructuresResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListCloudExadataInfrastructuresResponse'->new($_) };

declare 'RepeatedListCloudExadataInfrastructuresResponse',
    as ArrayRef[ListCloudExadataInfrastructuresResponse()];

coerce 'RepeatedListCloudExadataInfrastructuresResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListCloudExadataInfrastructuresResponse'->new($_) } @$_ ] };

declare 'MapStringListCloudExadataInfrastructuresResponse',
    as HashRef[ListCloudExadataInfrastructuresResponse()];

declare 'GetCloudExadataInfrastructureRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::GetCloudExadataInfrastructureRequest'];

coerce 'GetCloudExadataInfrastructureRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::GetCloudExadataInfrastructureRequest'->new($_) };

declare 'RepeatedGetCloudExadataInfrastructureRequest',
    as ArrayRef[GetCloudExadataInfrastructureRequest()];

coerce 'RepeatedGetCloudExadataInfrastructureRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::GetCloudExadataInfrastructureRequest'->new($_) } @$_ ] };

declare 'MapStringGetCloudExadataInfrastructureRequest',
    as HashRef[GetCloudExadataInfrastructureRequest()];

declare 'CreateCloudExadataInfrastructureRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::CreateCloudExadataInfrastructureRequest'];

coerce 'CreateCloudExadataInfrastructureRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::CreateCloudExadataInfrastructureRequest'->new($_) };

declare 'RepeatedCreateCloudExadataInfrastructureRequest',
    as ArrayRef[CreateCloudExadataInfrastructureRequest()];

coerce 'RepeatedCreateCloudExadataInfrastructureRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::CreateCloudExadataInfrastructureRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCloudExadataInfrastructureRequest',
    as HashRef[CreateCloudExadataInfrastructureRequest()];

declare 'UpdateCloudExadataInfrastructureRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::UpdateCloudExadataInfrastructureRequest'];

coerce 'UpdateCloudExadataInfrastructureRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::UpdateCloudExadataInfrastructureRequest'->new($_) };

declare 'RepeatedUpdateCloudExadataInfrastructureRequest',
    as ArrayRef[UpdateCloudExadataInfrastructureRequest()];

coerce 'RepeatedUpdateCloudExadataInfrastructureRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::UpdateCloudExadataInfrastructureRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCloudExadataInfrastructureRequest',
    as HashRef[UpdateCloudExadataInfrastructureRequest()];

declare 'DeleteCloudExadataInfrastructureRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::DeleteCloudExadataInfrastructureRequest'];

coerce 'DeleteCloudExadataInfrastructureRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::DeleteCloudExadataInfrastructureRequest'->new($_) };

declare 'RepeatedDeleteCloudExadataInfrastructureRequest',
    as ArrayRef[DeleteCloudExadataInfrastructureRequest()];

coerce 'RepeatedDeleteCloudExadataInfrastructureRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::DeleteCloudExadataInfrastructureRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCloudExadataInfrastructureRequest',
    as HashRef[DeleteCloudExadataInfrastructureRequest()];

declare 'ListCloudVmClustersRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::ListCloudVmClustersRequest'];

coerce 'ListCloudVmClustersRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListCloudVmClustersRequest'->new($_) };

declare 'RepeatedListCloudVmClustersRequest',
    as ArrayRef[ListCloudVmClustersRequest()];

coerce 'RepeatedListCloudVmClustersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListCloudVmClustersRequest'->new($_) } @$_ ] };

declare 'MapStringListCloudVmClustersRequest',
    as HashRef[ListCloudVmClustersRequest()];

declare 'ListCloudVmClustersResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::ListCloudVmClustersResponse'];

coerce 'ListCloudVmClustersResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListCloudVmClustersResponse'->new($_) };

declare 'RepeatedListCloudVmClustersResponse',
    as ArrayRef[ListCloudVmClustersResponse()];

coerce 'RepeatedListCloudVmClustersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListCloudVmClustersResponse'->new($_) } @$_ ] };

declare 'MapStringListCloudVmClustersResponse',
    as HashRef[ListCloudVmClustersResponse()];

declare 'GetCloudVmClusterRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::GetCloudVmClusterRequest'];

coerce 'GetCloudVmClusterRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::GetCloudVmClusterRequest'->new($_) };

declare 'RepeatedGetCloudVmClusterRequest',
    as ArrayRef[GetCloudVmClusterRequest()];

coerce 'RepeatedGetCloudVmClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::GetCloudVmClusterRequest'->new($_) } @$_ ] };

declare 'MapStringGetCloudVmClusterRequest',
    as HashRef[GetCloudVmClusterRequest()];

declare 'CreateCloudVmClusterRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::CreateCloudVmClusterRequest'];

coerce 'CreateCloudVmClusterRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::CreateCloudVmClusterRequest'->new($_) };

declare 'RepeatedCreateCloudVmClusterRequest',
    as ArrayRef[CreateCloudVmClusterRequest()];

coerce 'RepeatedCreateCloudVmClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::CreateCloudVmClusterRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCloudVmClusterRequest',
    as HashRef[CreateCloudVmClusterRequest()];

declare 'UpdateCloudVmClusterRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::UpdateCloudVmClusterRequest'];

coerce 'UpdateCloudVmClusterRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::UpdateCloudVmClusterRequest'->new($_) };

declare 'RepeatedUpdateCloudVmClusterRequest',
    as ArrayRef[UpdateCloudVmClusterRequest()];

coerce 'RepeatedUpdateCloudVmClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::UpdateCloudVmClusterRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCloudVmClusterRequest',
    as HashRef[UpdateCloudVmClusterRequest()];

declare 'DeleteCloudVmClusterRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::DeleteCloudVmClusterRequest'];

coerce 'DeleteCloudVmClusterRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::DeleteCloudVmClusterRequest'->new($_) };

declare 'RepeatedDeleteCloudVmClusterRequest',
    as ArrayRef[DeleteCloudVmClusterRequest()];

coerce 'RepeatedDeleteCloudVmClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::DeleteCloudVmClusterRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCloudVmClusterRequest',
    as HashRef[DeleteCloudVmClusterRequest()];

declare 'ListEntitlementsRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::ListEntitlementsRequest'];

coerce 'ListEntitlementsRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListEntitlementsRequest'->new($_) };

declare 'RepeatedListEntitlementsRequest',
    as ArrayRef[ListEntitlementsRequest()];

coerce 'RepeatedListEntitlementsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListEntitlementsRequest'->new($_) } @$_ ] };

declare 'MapStringListEntitlementsRequest',
    as HashRef[ListEntitlementsRequest()];

declare 'ListEntitlementsResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::ListEntitlementsResponse'];

coerce 'ListEntitlementsResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListEntitlementsResponse'->new($_) };

declare 'RepeatedListEntitlementsResponse',
    as ArrayRef[ListEntitlementsResponse()];

coerce 'RepeatedListEntitlementsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListEntitlementsResponse'->new($_) } @$_ ] };

declare 'MapStringListEntitlementsResponse',
    as HashRef[ListEntitlementsResponse()];

declare 'ListDbServersRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::ListDbServersRequest'];

coerce 'ListDbServersRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListDbServersRequest'->new($_) };

declare 'RepeatedListDbServersRequest',
    as ArrayRef[ListDbServersRequest()];

coerce 'RepeatedListDbServersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListDbServersRequest'->new($_) } @$_ ] };

declare 'MapStringListDbServersRequest',
    as HashRef[ListDbServersRequest()];

declare 'ListDbServersResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::ListDbServersResponse'];

coerce 'ListDbServersResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListDbServersResponse'->new($_) };

declare 'RepeatedListDbServersResponse',
    as ArrayRef[ListDbServersResponse()];

coerce 'RepeatedListDbServersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListDbServersResponse'->new($_) } @$_ ] };

declare 'MapStringListDbServersResponse',
    as HashRef[ListDbServersResponse()];

declare 'ListDbNodesRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::ListDbNodesRequest'];

coerce 'ListDbNodesRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListDbNodesRequest'->new($_) };

declare 'RepeatedListDbNodesRequest',
    as ArrayRef[ListDbNodesRequest()];

coerce 'RepeatedListDbNodesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListDbNodesRequest'->new($_) } @$_ ] };

declare 'MapStringListDbNodesRequest',
    as HashRef[ListDbNodesRequest()];

declare 'ListDbNodesResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::ListDbNodesResponse'];

coerce 'ListDbNodesResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListDbNodesResponse'->new($_) };

declare 'RepeatedListDbNodesResponse',
    as ArrayRef[ListDbNodesResponse()];

coerce 'RepeatedListDbNodesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListDbNodesResponse'->new($_) } @$_ ] };

declare 'MapStringListDbNodesResponse',
    as HashRef[ListDbNodesResponse()];

declare 'ListGiVersionsRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::ListGiVersionsRequest'];

coerce 'ListGiVersionsRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListGiVersionsRequest'->new($_) };

declare 'RepeatedListGiVersionsRequest',
    as ArrayRef[ListGiVersionsRequest()];

coerce 'RepeatedListGiVersionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListGiVersionsRequest'->new($_) } @$_ ] };

declare 'MapStringListGiVersionsRequest',
    as HashRef[ListGiVersionsRequest()];

declare 'ListGiVersionsResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::ListGiVersionsResponse'];

coerce 'ListGiVersionsResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListGiVersionsResponse'->new($_) };

declare 'RepeatedListGiVersionsResponse',
    as ArrayRef[ListGiVersionsResponse()];

coerce 'RepeatedListGiVersionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListGiVersionsResponse'->new($_) } @$_ ] };

declare 'MapStringListGiVersionsResponse',
    as HashRef[ListGiVersionsResponse()];

declare 'ListDbSystemShapesRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::ListDbSystemShapesRequest'];

coerce 'ListDbSystemShapesRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListDbSystemShapesRequest'->new($_) };

declare 'RepeatedListDbSystemShapesRequest',
    as ArrayRef[ListDbSystemShapesRequest()];

coerce 'RepeatedListDbSystemShapesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListDbSystemShapesRequest'->new($_) } @$_ ] };

declare 'MapStringListDbSystemShapesRequest',
    as HashRef[ListDbSystemShapesRequest()];

declare 'ListDbSystemShapesResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::ListDbSystemShapesResponse'];

coerce 'ListDbSystemShapesResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListDbSystemShapesResponse'->new($_) };

declare 'RepeatedListDbSystemShapesResponse',
    as ArrayRef[ListDbSystemShapesResponse()];

coerce 'RepeatedListDbSystemShapesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListDbSystemShapesResponse'->new($_) } @$_ ] };

declare 'MapStringListDbSystemShapesResponse',
    as HashRef[ListDbSystemShapesResponse()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'ListAutonomousDatabasesRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::ListAutonomousDatabasesRequest'];

coerce 'ListAutonomousDatabasesRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListAutonomousDatabasesRequest'->new($_) };

declare 'RepeatedListAutonomousDatabasesRequest',
    as ArrayRef[ListAutonomousDatabasesRequest()];

coerce 'RepeatedListAutonomousDatabasesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListAutonomousDatabasesRequest'->new($_) } @$_ ] };

declare 'MapStringListAutonomousDatabasesRequest',
    as HashRef[ListAutonomousDatabasesRequest()];

declare 'ListAutonomousDatabasesResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::ListAutonomousDatabasesResponse'];

coerce 'ListAutonomousDatabasesResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListAutonomousDatabasesResponse'->new($_) };

declare 'RepeatedListAutonomousDatabasesResponse',
    as ArrayRef[ListAutonomousDatabasesResponse()];

coerce 'RepeatedListAutonomousDatabasesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListAutonomousDatabasesResponse'->new($_) } @$_ ] };

declare 'MapStringListAutonomousDatabasesResponse',
    as HashRef[ListAutonomousDatabasesResponse()];

declare 'GetAutonomousDatabaseRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::GetAutonomousDatabaseRequest'];

coerce 'GetAutonomousDatabaseRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::GetAutonomousDatabaseRequest'->new($_) };

declare 'RepeatedGetAutonomousDatabaseRequest',
    as ArrayRef[GetAutonomousDatabaseRequest()];

coerce 'RepeatedGetAutonomousDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::GetAutonomousDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringGetAutonomousDatabaseRequest',
    as HashRef[GetAutonomousDatabaseRequest()];

declare 'CreateAutonomousDatabaseRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::CreateAutonomousDatabaseRequest'];

coerce 'CreateAutonomousDatabaseRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::CreateAutonomousDatabaseRequest'->new($_) };

declare 'RepeatedCreateAutonomousDatabaseRequest',
    as ArrayRef[CreateAutonomousDatabaseRequest()];

coerce 'RepeatedCreateAutonomousDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::CreateAutonomousDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAutonomousDatabaseRequest',
    as HashRef[CreateAutonomousDatabaseRequest()];

declare 'UpdateAutonomousDatabaseRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::UpdateAutonomousDatabaseRequest'];

coerce 'UpdateAutonomousDatabaseRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::UpdateAutonomousDatabaseRequest'->new($_) };

declare 'RepeatedUpdateAutonomousDatabaseRequest',
    as ArrayRef[UpdateAutonomousDatabaseRequest()];

coerce 'RepeatedUpdateAutonomousDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::UpdateAutonomousDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAutonomousDatabaseRequest',
    as HashRef[UpdateAutonomousDatabaseRequest()];

declare 'DeleteAutonomousDatabaseRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::DeleteAutonomousDatabaseRequest'];

coerce 'DeleteAutonomousDatabaseRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::DeleteAutonomousDatabaseRequest'->new($_) };

declare 'RepeatedDeleteAutonomousDatabaseRequest',
    as ArrayRef[DeleteAutonomousDatabaseRequest()];

coerce 'RepeatedDeleteAutonomousDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::DeleteAutonomousDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAutonomousDatabaseRequest',
    as HashRef[DeleteAutonomousDatabaseRequest()];

declare 'RestoreAutonomousDatabaseRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::RestoreAutonomousDatabaseRequest'];

coerce 'RestoreAutonomousDatabaseRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::RestoreAutonomousDatabaseRequest'->new($_) };

declare 'RepeatedRestoreAutonomousDatabaseRequest',
    as ArrayRef[RestoreAutonomousDatabaseRequest()];

coerce 'RepeatedRestoreAutonomousDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::RestoreAutonomousDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringRestoreAutonomousDatabaseRequest',
    as HashRef[RestoreAutonomousDatabaseRequest()];

declare 'StopAutonomousDatabaseRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::StopAutonomousDatabaseRequest'];

coerce 'StopAutonomousDatabaseRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::StopAutonomousDatabaseRequest'->new($_) };

declare 'RepeatedStopAutonomousDatabaseRequest',
    as ArrayRef[StopAutonomousDatabaseRequest()];

coerce 'RepeatedStopAutonomousDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::StopAutonomousDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringStopAutonomousDatabaseRequest',
    as HashRef[StopAutonomousDatabaseRequest()];

declare 'StartAutonomousDatabaseRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::StartAutonomousDatabaseRequest'];

coerce 'StartAutonomousDatabaseRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::StartAutonomousDatabaseRequest'->new($_) };

declare 'RepeatedStartAutonomousDatabaseRequest',
    as ArrayRef[StartAutonomousDatabaseRequest()];

coerce 'RepeatedStartAutonomousDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::StartAutonomousDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringStartAutonomousDatabaseRequest',
    as HashRef[StartAutonomousDatabaseRequest()];

declare 'RestartAutonomousDatabaseRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::RestartAutonomousDatabaseRequest'];

coerce 'RestartAutonomousDatabaseRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::RestartAutonomousDatabaseRequest'->new($_) };

declare 'RepeatedRestartAutonomousDatabaseRequest',
    as ArrayRef[RestartAutonomousDatabaseRequest()];

coerce 'RepeatedRestartAutonomousDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::RestartAutonomousDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringRestartAutonomousDatabaseRequest',
    as HashRef[RestartAutonomousDatabaseRequest()];

declare 'SwitchoverAutonomousDatabaseRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::SwitchoverAutonomousDatabaseRequest'];

coerce 'SwitchoverAutonomousDatabaseRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::SwitchoverAutonomousDatabaseRequest'->new($_) };

declare 'RepeatedSwitchoverAutonomousDatabaseRequest',
    as ArrayRef[SwitchoverAutonomousDatabaseRequest()];

coerce 'RepeatedSwitchoverAutonomousDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::SwitchoverAutonomousDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringSwitchoverAutonomousDatabaseRequest',
    as HashRef[SwitchoverAutonomousDatabaseRequest()];

declare 'FailoverAutonomousDatabaseRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::FailoverAutonomousDatabaseRequest'];

coerce 'FailoverAutonomousDatabaseRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::FailoverAutonomousDatabaseRequest'->new($_) };

declare 'RepeatedFailoverAutonomousDatabaseRequest',
    as ArrayRef[FailoverAutonomousDatabaseRequest()];

coerce 'RepeatedFailoverAutonomousDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::FailoverAutonomousDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringFailoverAutonomousDatabaseRequest',
    as HashRef[FailoverAutonomousDatabaseRequest()];

declare 'GetAutonomousDatabaseRefreshableClonesRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::GetAutonomousDatabaseRefreshableClonesRequest'];

coerce 'GetAutonomousDatabaseRefreshableClonesRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::GetAutonomousDatabaseRefreshableClonesRequest'->new($_) };

declare 'RepeatedGetAutonomousDatabaseRefreshableClonesRequest',
    as ArrayRef[GetAutonomousDatabaseRefreshableClonesRequest()];

coerce 'RepeatedGetAutonomousDatabaseRefreshableClonesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::GetAutonomousDatabaseRefreshableClonesRequest'->new($_) } @$_ ] };

declare 'MapStringGetAutonomousDatabaseRefreshableClonesRequest',
    as HashRef[GetAutonomousDatabaseRefreshableClonesRequest()];

declare 'AutonomousDatabaseRefreshableClones',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::AutonomousDatabaseRefreshableClones'];

coerce 'AutonomousDatabaseRefreshableClones',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::AutonomousDatabaseRefreshableClones'->new($_) };

declare 'RepeatedAutonomousDatabaseRefreshableClones',
    as ArrayRef[AutonomousDatabaseRefreshableClones()];

coerce 'RepeatedAutonomousDatabaseRefreshableClones',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::AutonomousDatabaseRefreshableClones'->new($_) } @$_ ] };

declare 'MapStringAutonomousDatabaseRefreshableClones',
    as HashRef[AutonomousDatabaseRefreshableClones()];

declare 'RefreshAutonomousDatabaseRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::RefreshAutonomousDatabaseRequest'];

coerce 'RefreshAutonomousDatabaseRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::RefreshAutonomousDatabaseRequest'->new($_) };

declare 'RepeatedRefreshAutonomousDatabaseRequest',
    as ArrayRef[RefreshAutonomousDatabaseRequest()];

coerce 'RepeatedRefreshAutonomousDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::RefreshAutonomousDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringRefreshAutonomousDatabaseRequest',
    as HashRef[RefreshAutonomousDatabaseRequest()];

declare 'GenerateAutonomousDatabaseWalletRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::GenerateAutonomousDatabaseWalletRequest'];

coerce 'GenerateAutonomousDatabaseWalletRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::GenerateAutonomousDatabaseWalletRequest'->new($_) };

declare 'RepeatedGenerateAutonomousDatabaseWalletRequest',
    as ArrayRef[GenerateAutonomousDatabaseWalletRequest()];

coerce 'RepeatedGenerateAutonomousDatabaseWalletRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::GenerateAutonomousDatabaseWalletRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateAutonomousDatabaseWalletRequest',
    as HashRef[GenerateAutonomousDatabaseWalletRequest()];

declare 'GenerateAutonomousDatabaseWalletResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::GenerateAutonomousDatabaseWalletResponse'];

coerce 'GenerateAutonomousDatabaseWalletResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::GenerateAutonomousDatabaseWalletResponse'->new($_) };

declare 'RepeatedGenerateAutonomousDatabaseWalletResponse',
    as ArrayRef[GenerateAutonomousDatabaseWalletResponse()];

coerce 'RepeatedGenerateAutonomousDatabaseWalletResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::GenerateAutonomousDatabaseWalletResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateAutonomousDatabaseWalletResponse',
    as HashRef[GenerateAutonomousDatabaseWalletResponse()];

declare 'ListAutonomousDbVersionsRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::ListAutonomousDbVersionsRequest'];

coerce 'ListAutonomousDbVersionsRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListAutonomousDbVersionsRequest'->new($_) };

declare 'RepeatedListAutonomousDbVersionsRequest',
    as ArrayRef[ListAutonomousDbVersionsRequest()];

coerce 'RepeatedListAutonomousDbVersionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListAutonomousDbVersionsRequest'->new($_) } @$_ ] };

declare 'MapStringListAutonomousDbVersionsRequest',
    as HashRef[ListAutonomousDbVersionsRequest()];

declare 'ListAutonomousDbVersionsResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::ListAutonomousDbVersionsResponse'];

coerce 'ListAutonomousDbVersionsResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListAutonomousDbVersionsResponse'->new($_) };

declare 'RepeatedListAutonomousDbVersionsResponse',
    as ArrayRef[ListAutonomousDbVersionsResponse()];

coerce 'RepeatedListAutonomousDbVersionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListAutonomousDbVersionsResponse'->new($_) } @$_ ] };

declare 'MapStringListAutonomousDbVersionsResponse',
    as HashRef[ListAutonomousDbVersionsResponse()];

declare 'ListAutonomousDatabaseCharacterSetsRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::ListAutonomousDatabaseCharacterSetsRequest'];

coerce 'ListAutonomousDatabaseCharacterSetsRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListAutonomousDatabaseCharacterSetsRequest'->new($_) };

declare 'RepeatedListAutonomousDatabaseCharacterSetsRequest',
    as ArrayRef[ListAutonomousDatabaseCharacterSetsRequest()];

coerce 'RepeatedListAutonomousDatabaseCharacterSetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListAutonomousDatabaseCharacterSetsRequest'->new($_) } @$_ ] };

declare 'MapStringListAutonomousDatabaseCharacterSetsRequest',
    as HashRef[ListAutonomousDatabaseCharacterSetsRequest()];

declare 'ListAutonomousDatabaseCharacterSetsResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::ListAutonomousDatabaseCharacterSetsResponse'];

coerce 'ListAutonomousDatabaseCharacterSetsResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListAutonomousDatabaseCharacterSetsResponse'->new($_) };

declare 'RepeatedListAutonomousDatabaseCharacterSetsResponse',
    as ArrayRef[ListAutonomousDatabaseCharacterSetsResponse()];

coerce 'RepeatedListAutonomousDatabaseCharacterSetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListAutonomousDatabaseCharacterSetsResponse'->new($_) } @$_ ] };

declare 'MapStringListAutonomousDatabaseCharacterSetsResponse',
    as HashRef[ListAutonomousDatabaseCharacterSetsResponse()];

declare 'ListAutonomousDatabaseBackupsRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::ListAutonomousDatabaseBackupsRequest'];

coerce 'ListAutonomousDatabaseBackupsRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListAutonomousDatabaseBackupsRequest'->new($_) };

declare 'RepeatedListAutonomousDatabaseBackupsRequest',
    as ArrayRef[ListAutonomousDatabaseBackupsRequest()];

coerce 'RepeatedListAutonomousDatabaseBackupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListAutonomousDatabaseBackupsRequest'->new($_) } @$_ ] };

declare 'MapStringListAutonomousDatabaseBackupsRequest',
    as HashRef[ListAutonomousDatabaseBackupsRequest()];

declare 'ListAutonomousDatabaseBackupsResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::ListAutonomousDatabaseBackupsResponse'];

coerce 'ListAutonomousDatabaseBackupsResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListAutonomousDatabaseBackupsResponse'->new($_) };

declare 'RepeatedListAutonomousDatabaseBackupsResponse',
    as ArrayRef[ListAutonomousDatabaseBackupsResponse()];

coerce 'RepeatedListAutonomousDatabaseBackupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListAutonomousDatabaseBackupsResponse'->new($_) } @$_ ] };

declare 'MapStringListAutonomousDatabaseBackupsResponse',
    as HashRef[ListAutonomousDatabaseBackupsResponse()];

declare 'CreateExadbVmClusterRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::CreateExadbVmClusterRequest'];

coerce 'CreateExadbVmClusterRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::CreateExadbVmClusterRequest'->new($_) };

declare 'RepeatedCreateExadbVmClusterRequest',
    as ArrayRef[CreateExadbVmClusterRequest()];

coerce 'RepeatedCreateExadbVmClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::CreateExadbVmClusterRequest'->new($_) } @$_ ] };

declare 'MapStringCreateExadbVmClusterRequest',
    as HashRef[CreateExadbVmClusterRequest()];

declare 'DeleteExadbVmClusterRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::DeleteExadbVmClusterRequest'];

coerce 'DeleteExadbVmClusterRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::DeleteExadbVmClusterRequest'->new($_) };

declare 'RepeatedDeleteExadbVmClusterRequest',
    as ArrayRef[DeleteExadbVmClusterRequest()];

coerce 'RepeatedDeleteExadbVmClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::DeleteExadbVmClusterRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteExadbVmClusterRequest',
    as HashRef[DeleteExadbVmClusterRequest()];

declare 'GetExadbVmClusterRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::GetExadbVmClusterRequest'];

coerce 'GetExadbVmClusterRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::GetExadbVmClusterRequest'->new($_) };

declare 'RepeatedGetExadbVmClusterRequest',
    as ArrayRef[GetExadbVmClusterRequest()];

coerce 'RepeatedGetExadbVmClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::GetExadbVmClusterRequest'->new($_) } @$_ ] };

declare 'MapStringGetExadbVmClusterRequest',
    as HashRef[GetExadbVmClusterRequest()];

declare 'ListExadbVmClustersRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::ListExadbVmClustersRequest'];

coerce 'ListExadbVmClustersRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListExadbVmClustersRequest'->new($_) };

declare 'RepeatedListExadbVmClustersRequest',
    as ArrayRef[ListExadbVmClustersRequest()];

coerce 'RepeatedListExadbVmClustersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListExadbVmClustersRequest'->new($_) } @$_ ] };

declare 'MapStringListExadbVmClustersRequest',
    as HashRef[ListExadbVmClustersRequest()];

declare 'ListExadbVmClustersResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::ListExadbVmClustersResponse'];

coerce 'ListExadbVmClustersResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListExadbVmClustersResponse'->new($_) };

declare 'RepeatedListExadbVmClustersResponse',
    as ArrayRef[ListExadbVmClustersResponse()];

coerce 'RepeatedListExadbVmClustersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListExadbVmClustersResponse'->new($_) } @$_ ] };

declare 'MapStringListExadbVmClustersResponse',
    as HashRef[ListExadbVmClustersResponse()];

declare 'UpdateExadbVmClusterRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::UpdateExadbVmClusterRequest'];

coerce 'UpdateExadbVmClusterRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::UpdateExadbVmClusterRequest'->new($_) };

declare 'RepeatedUpdateExadbVmClusterRequest',
    as ArrayRef[UpdateExadbVmClusterRequest()];

coerce 'RepeatedUpdateExadbVmClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::UpdateExadbVmClusterRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateExadbVmClusterRequest',
    as HashRef[UpdateExadbVmClusterRequest()];

declare 'RemoveVirtualMachineExadbVmClusterRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::RemoveVirtualMachineExadbVmClusterRequest'];

coerce 'RemoveVirtualMachineExadbVmClusterRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::RemoveVirtualMachineExadbVmClusterRequest'->new($_) };

declare 'RepeatedRemoveVirtualMachineExadbVmClusterRequest',
    as ArrayRef[RemoveVirtualMachineExadbVmClusterRequest()];

coerce 'RepeatedRemoveVirtualMachineExadbVmClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::RemoveVirtualMachineExadbVmClusterRequest'->new($_) } @$_ ] };

declare 'MapStringRemoveVirtualMachineExadbVmClusterRequest',
    as HashRef[RemoveVirtualMachineExadbVmClusterRequest()];

declare 'EnableCloudVmClusterIdentityConnectorRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::EnableCloudVmClusterIdentityConnectorRequest'];

coerce 'EnableCloudVmClusterIdentityConnectorRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::EnableCloudVmClusterIdentityConnectorRequest'->new($_) };

declare 'RepeatedEnableCloudVmClusterIdentityConnectorRequest',
    as ArrayRef[EnableCloudVmClusterIdentityConnectorRequest()];

coerce 'RepeatedEnableCloudVmClusterIdentityConnectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::EnableCloudVmClusterIdentityConnectorRequest'->new($_) } @$_ ] };

declare 'MapStringEnableCloudVmClusterIdentityConnectorRequest',
    as HashRef[EnableCloudVmClusterIdentityConnectorRequest()];

declare 'EnableExadbVmClusterIdentityConnectorRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::EnableExadbVmClusterIdentityConnectorRequest'];

coerce 'EnableExadbVmClusterIdentityConnectorRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::EnableExadbVmClusterIdentityConnectorRequest'->new($_) };

declare 'RepeatedEnableExadbVmClusterIdentityConnectorRequest',
    as ArrayRef[EnableExadbVmClusterIdentityConnectorRequest()];

coerce 'RepeatedEnableExadbVmClusterIdentityConnectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::EnableExadbVmClusterIdentityConnectorRequest'->new($_) } @$_ ] };

declare 'MapStringEnableExadbVmClusterIdentityConnectorRequest',
    as HashRef[EnableExadbVmClusterIdentityConnectorRequest()];

declare 'DisableCloudVmClusterIdentityConnectorRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::DisableCloudVmClusterIdentityConnectorRequest'];

coerce 'DisableCloudVmClusterIdentityConnectorRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::DisableCloudVmClusterIdentityConnectorRequest'->new($_) };

declare 'RepeatedDisableCloudVmClusterIdentityConnectorRequest',
    as ArrayRef[DisableCloudVmClusterIdentityConnectorRequest()];

coerce 'RepeatedDisableCloudVmClusterIdentityConnectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::DisableCloudVmClusterIdentityConnectorRequest'->new($_) } @$_ ] };

declare 'MapStringDisableCloudVmClusterIdentityConnectorRequest',
    as HashRef[DisableCloudVmClusterIdentityConnectorRequest()];

declare 'DisableExadbVmClusterIdentityConnectorRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::Oracledatabase::DisableExadbVmClusterIdentityConnectorRequest'];

coerce 'DisableExadbVmClusterIdentityConnectorRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::DisableExadbVmClusterIdentityConnectorRequest'->new($_) };

declare 'RepeatedDisableExadbVmClusterIdentityConnectorRequest',
    as ArrayRef[DisableExadbVmClusterIdentityConnectorRequest()];

coerce 'RepeatedDisableExadbVmClusterIdentityConnectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::Oracledatabase::DisableExadbVmClusterIdentityConnectorRequest'->new($_) } @$_ ] };

declare 'MapStringDisableExadbVmClusterIdentityConnectorRequest',
    as HashRef[DisableExadbVmClusterIdentityConnectorRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::Oracledatabase::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
