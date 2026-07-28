package Google::Cloud::Networksecurity::V1::Mirroring::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'MirroringEndpointGroup',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::MirroringEndpointGroup'];

coerce 'MirroringEndpointGroup',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::MirroringEndpointGroup'->new($_) };

declare 'RepeatedMirroringEndpointGroup',
    as ArrayRef[MirroringEndpointGroup()];

coerce 'RepeatedMirroringEndpointGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::MirroringEndpointGroup'->new($_) } @$_ ] };

declare 'MapStringMirroringEndpointGroup',
    as HashRef[MirroringEndpointGroup()];

declare 'State',
    as (Int | Str);

declare 'Type',
    as (Int | Str);

declare 'ConnectedDeploymentGroup',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::MirroringEndpointGroup::ConnectedDeploymentGroup'];

coerce 'ConnectedDeploymentGroup',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::MirroringEndpointGroup::ConnectedDeploymentGroup'->new($_) };

declare 'RepeatedConnectedDeploymentGroup',
    as ArrayRef[ConnectedDeploymentGroup()];

coerce 'RepeatedConnectedDeploymentGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::MirroringEndpointGroup::ConnectedDeploymentGroup'->new($_) } @$_ ] };

declare 'MapStringConnectedDeploymentGroup',
    as HashRef[ConnectedDeploymentGroup()];

declare 'AssociationDetails',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::MirroringEndpointGroup::AssociationDetails'];

coerce 'AssociationDetails',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::MirroringEndpointGroup::AssociationDetails'->new($_) };

declare 'RepeatedAssociationDetails',
    as ArrayRef[AssociationDetails()];

coerce 'RepeatedAssociationDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::MirroringEndpointGroup::AssociationDetails'->new($_) } @$_ ] };

declare 'MapStringAssociationDetails',
    as HashRef[AssociationDetails()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::MirroringEndpointGroup::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::MirroringEndpointGroup::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::MirroringEndpointGroup::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListMirroringEndpointGroupsRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::ListMirroringEndpointGroupsRequest'];

coerce 'ListMirroringEndpointGroupsRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::ListMirroringEndpointGroupsRequest'->new($_) };

declare 'RepeatedListMirroringEndpointGroupsRequest',
    as ArrayRef[ListMirroringEndpointGroupsRequest()];

coerce 'RepeatedListMirroringEndpointGroupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::ListMirroringEndpointGroupsRequest'->new($_) } @$_ ] };

declare 'MapStringListMirroringEndpointGroupsRequest',
    as HashRef[ListMirroringEndpointGroupsRequest()];

declare 'ListMirroringEndpointGroupsResponse',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::ListMirroringEndpointGroupsResponse'];

coerce 'ListMirroringEndpointGroupsResponse',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::ListMirroringEndpointGroupsResponse'->new($_) };

declare 'RepeatedListMirroringEndpointGroupsResponse',
    as ArrayRef[ListMirroringEndpointGroupsResponse()];

coerce 'RepeatedListMirroringEndpointGroupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::ListMirroringEndpointGroupsResponse'->new($_) } @$_ ] };

declare 'MapStringListMirroringEndpointGroupsResponse',
    as HashRef[ListMirroringEndpointGroupsResponse()];

declare 'GetMirroringEndpointGroupRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::GetMirroringEndpointGroupRequest'];

coerce 'GetMirroringEndpointGroupRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::GetMirroringEndpointGroupRequest'->new($_) };

declare 'RepeatedGetMirroringEndpointGroupRequest',
    as ArrayRef[GetMirroringEndpointGroupRequest()];

coerce 'RepeatedGetMirroringEndpointGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::GetMirroringEndpointGroupRequest'->new($_) } @$_ ] };

declare 'MapStringGetMirroringEndpointGroupRequest',
    as HashRef[GetMirroringEndpointGroupRequest()];

declare 'CreateMirroringEndpointGroupRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::CreateMirroringEndpointGroupRequest'];

coerce 'CreateMirroringEndpointGroupRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::CreateMirroringEndpointGroupRequest'->new($_) };

declare 'RepeatedCreateMirroringEndpointGroupRequest',
    as ArrayRef[CreateMirroringEndpointGroupRequest()];

coerce 'RepeatedCreateMirroringEndpointGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::CreateMirroringEndpointGroupRequest'->new($_) } @$_ ] };

declare 'MapStringCreateMirroringEndpointGroupRequest',
    as HashRef[CreateMirroringEndpointGroupRequest()];

declare 'UpdateMirroringEndpointGroupRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::UpdateMirroringEndpointGroupRequest'];

coerce 'UpdateMirroringEndpointGroupRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::UpdateMirroringEndpointGroupRequest'->new($_) };

declare 'RepeatedUpdateMirroringEndpointGroupRequest',
    as ArrayRef[UpdateMirroringEndpointGroupRequest()];

coerce 'RepeatedUpdateMirroringEndpointGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::UpdateMirroringEndpointGroupRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateMirroringEndpointGroupRequest',
    as HashRef[UpdateMirroringEndpointGroupRequest()];

declare 'DeleteMirroringEndpointGroupRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::DeleteMirroringEndpointGroupRequest'];

coerce 'DeleteMirroringEndpointGroupRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::DeleteMirroringEndpointGroupRequest'->new($_) };

declare 'RepeatedDeleteMirroringEndpointGroupRequest',
    as ArrayRef[DeleteMirroringEndpointGroupRequest()];

coerce 'RepeatedDeleteMirroringEndpointGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::DeleteMirroringEndpointGroupRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteMirroringEndpointGroupRequest',
    as HashRef[DeleteMirroringEndpointGroupRequest()];

declare 'MirroringEndpointGroupAssociation',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::MirroringEndpointGroupAssociation'];

coerce 'MirroringEndpointGroupAssociation',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::MirroringEndpointGroupAssociation'->new($_) };

declare 'RepeatedMirroringEndpointGroupAssociation',
    as ArrayRef[MirroringEndpointGroupAssociation()];

coerce 'RepeatedMirroringEndpointGroupAssociation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::MirroringEndpointGroupAssociation'->new($_) } @$_ ] };

declare 'MapStringMirroringEndpointGroupAssociation',
    as HashRef[MirroringEndpointGroupAssociation()];

declare 'State',
    as (Int | Str);

declare 'LocationDetails',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::MirroringEndpointGroupAssociation::LocationDetails'];

coerce 'LocationDetails',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::MirroringEndpointGroupAssociation::LocationDetails'->new($_) };

declare 'RepeatedLocationDetails',
    as ArrayRef[LocationDetails()];

coerce 'RepeatedLocationDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::MirroringEndpointGroupAssociation::LocationDetails'->new($_) } @$_ ] };

declare 'MapStringLocationDetails',
    as HashRef[LocationDetails()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::MirroringEndpointGroupAssociation::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::MirroringEndpointGroupAssociation::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::MirroringEndpointGroupAssociation::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListMirroringEndpointGroupAssociationsRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::ListMirroringEndpointGroupAssociationsRequest'];

coerce 'ListMirroringEndpointGroupAssociationsRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::ListMirroringEndpointGroupAssociationsRequest'->new($_) };

declare 'RepeatedListMirroringEndpointGroupAssociationsRequest',
    as ArrayRef[ListMirroringEndpointGroupAssociationsRequest()];

coerce 'RepeatedListMirroringEndpointGroupAssociationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::ListMirroringEndpointGroupAssociationsRequest'->new($_) } @$_ ] };

declare 'MapStringListMirroringEndpointGroupAssociationsRequest',
    as HashRef[ListMirroringEndpointGroupAssociationsRequest()];

declare 'ListMirroringEndpointGroupAssociationsResponse',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::ListMirroringEndpointGroupAssociationsResponse'];

coerce 'ListMirroringEndpointGroupAssociationsResponse',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::ListMirroringEndpointGroupAssociationsResponse'->new($_) };

declare 'RepeatedListMirroringEndpointGroupAssociationsResponse',
    as ArrayRef[ListMirroringEndpointGroupAssociationsResponse()];

coerce 'RepeatedListMirroringEndpointGroupAssociationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::ListMirroringEndpointGroupAssociationsResponse'->new($_) } @$_ ] };

declare 'MapStringListMirroringEndpointGroupAssociationsResponse',
    as HashRef[ListMirroringEndpointGroupAssociationsResponse()];

declare 'GetMirroringEndpointGroupAssociationRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::GetMirroringEndpointGroupAssociationRequest'];

coerce 'GetMirroringEndpointGroupAssociationRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::GetMirroringEndpointGroupAssociationRequest'->new($_) };

declare 'RepeatedGetMirroringEndpointGroupAssociationRequest',
    as ArrayRef[GetMirroringEndpointGroupAssociationRequest()];

coerce 'RepeatedGetMirroringEndpointGroupAssociationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::GetMirroringEndpointGroupAssociationRequest'->new($_) } @$_ ] };

declare 'MapStringGetMirroringEndpointGroupAssociationRequest',
    as HashRef[GetMirroringEndpointGroupAssociationRequest()];

declare 'CreateMirroringEndpointGroupAssociationRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::CreateMirroringEndpointGroupAssociationRequest'];

coerce 'CreateMirroringEndpointGroupAssociationRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::CreateMirroringEndpointGroupAssociationRequest'->new($_) };

declare 'RepeatedCreateMirroringEndpointGroupAssociationRequest',
    as ArrayRef[CreateMirroringEndpointGroupAssociationRequest()];

coerce 'RepeatedCreateMirroringEndpointGroupAssociationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::CreateMirroringEndpointGroupAssociationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateMirroringEndpointGroupAssociationRequest',
    as HashRef[CreateMirroringEndpointGroupAssociationRequest()];

declare 'UpdateMirroringEndpointGroupAssociationRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::UpdateMirroringEndpointGroupAssociationRequest'];

coerce 'UpdateMirroringEndpointGroupAssociationRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::UpdateMirroringEndpointGroupAssociationRequest'->new($_) };

declare 'RepeatedUpdateMirroringEndpointGroupAssociationRequest',
    as ArrayRef[UpdateMirroringEndpointGroupAssociationRequest()];

coerce 'RepeatedUpdateMirroringEndpointGroupAssociationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::UpdateMirroringEndpointGroupAssociationRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateMirroringEndpointGroupAssociationRequest',
    as HashRef[UpdateMirroringEndpointGroupAssociationRequest()];

declare 'DeleteMirroringEndpointGroupAssociationRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::DeleteMirroringEndpointGroupAssociationRequest'];

coerce 'DeleteMirroringEndpointGroupAssociationRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::DeleteMirroringEndpointGroupAssociationRequest'->new($_) };

declare 'RepeatedDeleteMirroringEndpointGroupAssociationRequest',
    as ArrayRef[DeleteMirroringEndpointGroupAssociationRequest()];

coerce 'RepeatedDeleteMirroringEndpointGroupAssociationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::DeleteMirroringEndpointGroupAssociationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteMirroringEndpointGroupAssociationRequest',
    as HashRef[DeleteMirroringEndpointGroupAssociationRequest()];

declare 'MirroringDeploymentGroup',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::MirroringDeploymentGroup'];

coerce 'MirroringDeploymentGroup',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::MirroringDeploymentGroup'->new($_) };

declare 'RepeatedMirroringDeploymentGroup',
    as ArrayRef[MirroringDeploymentGroup()];

coerce 'RepeatedMirroringDeploymentGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::MirroringDeploymentGroup'->new($_) } @$_ ] };

declare 'MapStringMirroringDeploymentGroup',
    as HashRef[MirroringDeploymentGroup()];

declare 'State',
    as (Int | Str);

declare 'ConnectedEndpointGroup',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::MirroringDeploymentGroup::ConnectedEndpointGroup'];

coerce 'ConnectedEndpointGroup',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::MirroringDeploymentGroup::ConnectedEndpointGroup'->new($_) };

declare 'RepeatedConnectedEndpointGroup',
    as ArrayRef[ConnectedEndpointGroup()];

coerce 'RepeatedConnectedEndpointGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::MirroringDeploymentGroup::ConnectedEndpointGroup'->new($_) } @$_ ] };

declare 'MapStringConnectedEndpointGroup',
    as HashRef[ConnectedEndpointGroup()];

declare 'Deployment',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::MirroringDeploymentGroup::Deployment'];

coerce 'Deployment',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::MirroringDeploymentGroup::Deployment'->new($_) };

declare 'RepeatedDeployment',
    as ArrayRef[Deployment()];

coerce 'RepeatedDeployment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::MirroringDeploymentGroup::Deployment'->new($_) } @$_ ] };

declare 'MapStringDeployment',
    as HashRef[Deployment()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::MirroringDeploymentGroup::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::MirroringDeploymentGroup::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::MirroringDeploymentGroup::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListMirroringDeploymentGroupsRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::ListMirroringDeploymentGroupsRequest'];

coerce 'ListMirroringDeploymentGroupsRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::ListMirroringDeploymentGroupsRequest'->new($_) };

declare 'RepeatedListMirroringDeploymentGroupsRequest',
    as ArrayRef[ListMirroringDeploymentGroupsRequest()];

coerce 'RepeatedListMirroringDeploymentGroupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::ListMirroringDeploymentGroupsRequest'->new($_) } @$_ ] };

declare 'MapStringListMirroringDeploymentGroupsRequest',
    as HashRef[ListMirroringDeploymentGroupsRequest()];

declare 'ListMirroringDeploymentGroupsResponse',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::ListMirroringDeploymentGroupsResponse'];

coerce 'ListMirroringDeploymentGroupsResponse',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::ListMirroringDeploymentGroupsResponse'->new($_) };

declare 'RepeatedListMirroringDeploymentGroupsResponse',
    as ArrayRef[ListMirroringDeploymentGroupsResponse()];

coerce 'RepeatedListMirroringDeploymentGroupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::ListMirroringDeploymentGroupsResponse'->new($_) } @$_ ] };

declare 'MapStringListMirroringDeploymentGroupsResponse',
    as HashRef[ListMirroringDeploymentGroupsResponse()];

declare 'GetMirroringDeploymentGroupRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::GetMirroringDeploymentGroupRequest'];

coerce 'GetMirroringDeploymentGroupRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::GetMirroringDeploymentGroupRequest'->new($_) };

declare 'RepeatedGetMirroringDeploymentGroupRequest',
    as ArrayRef[GetMirroringDeploymentGroupRequest()];

coerce 'RepeatedGetMirroringDeploymentGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::GetMirroringDeploymentGroupRequest'->new($_) } @$_ ] };

declare 'MapStringGetMirroringDeploymentGroupRequest',
    as HashRef[GetMirroringDeploymentGroupRequest()];

declare 'CreateMirroringDeploymentGroupRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::CreateMirroringDeploymentGroupRequest'];

coerce 'CreateMirroringDeploymentGroupRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::CreateMirroringDeploymentGroupRequest'->new($_) };

declare 'RepeatedCreateMirroringDeploymentGroupRequest',
    as ArrayRef[CreateMirroringDeploymentGroupRequest()];

coerce 'RepeatedCreateMirroringDeploymentGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::CreateMirroringDeploymentGroupRequest'->new($_) } @$_ ] };

declare 'MapStringCreateMirroringDeploymentGroupRequest',
    as HashRef[CreateMirroringDeploymentGroupRequest()];

declare 'UpdateMirroringDeploymentGroupRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::UpdateMirroringDeploymentGroupRequest'];

coerce 'UpdateMirroringDeploymentGroupRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::UpdateMirroringDeploymentGroupRequest'->new($_) };

declare 'RepeatedUpdateMirroringDeploymentGroupRequest',
    as ArrayRef[UpdateMirroringDeploymentGroupRequest()];

coerce 'RepeatedUpdateMirroringDeploymentGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::UpdateMirroringDeploymentGroupRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateMirroringDeploymentGroupRequest',
    as HashRef[UpdateMirroringDeploymentGroupRequest()];

declare 'DeleteMirroringDeploymentGroupRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::DeleteMirroringDeploymentGroupRequest'];

coerce 'DeleteMirroringDeploymentGroupRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::DeleteMirroringDeploymentGroupRequest'->new($_) };

declare 'RepeatedDeleteMirroringDeploymentGroupRequest',
    as ArrayRef[DeleteMirroringDeploymentGroupRequest()];

coerce 'RepeatedDeleteMirroringDeploymentGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::DeleteMirroringDeploymentGroupRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteMirroringDeploymentGroupRequest',
    as HashRef[DeleteMirroringDeploymentGroupRequest()];

declare 'MirroringDeployment',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::MirroringDeployment'];

coerce 'MirroringDeployment',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::MirroringDeployment'->new($_) };

declare 'RepeatedMirroringDeployment',
    as ArrayRef[MirroringDeployment()];

coerce 'RepeatedMirroringDeployment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::MirroringDeployment'->new($_) } @$_ ] };

declare 'MapStringMirroringDeployment',
    as HashRef[MirroringDeployment()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::MirroringDeployment::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::MirroringDeployment::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::MirroringDeployment::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListMirroringDeploymentsRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::ListMirroringDeploymentsRequest'];

coerce 'ListMirroringDeploymentsRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::ListMirroringDeploymentsRequest'->new($_) };

declare 'RepeatedListMirroringDeploymentsRequest',
    as ArrayRef[ListMirroringDeploymentsRequest()];

coerce 'RepeatedListMirroringDeploymentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::ListMirroringDeploymentsRequest'->new($_) } @$_ ] };

declare 'MapStringListMirroringDeploymentsRequest',
    as HashRef[ListMirroringDeploymentsRequest()];

declare 'ListMirroringDeploymentsResponse',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::ListMirroringDeploymentsResponse'];

coerce 'ListMirroringDeploymentsResponse',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::ListMirroringDeploymentsResponse'->new($_) };

declare 'RepeatedListMirroringDeploymentsResponse',
    as ArrayRef[ListMirroringDeploymentsResponse()];

coerce 'RepeatedListMirroringDeploymentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::ListMirroringDeploymentsResponse'->new($_) } @$_ ] };

declare 'MapStringListMirroringDeploymentsResponse',
    as HashRef[ListMirroringDeploymentsResponse()];

declare 'GetMirroringDeploymentRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::GetMirroringDeploymentRequest'];

coerce 'GetMirroringDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::GetMirroringDeploymentRequest'->new($_) };

declare 'RepeatedGetMirroringDeploymentRequest',
    as ArrayRef[GetMirroringDeploymentRequest()];

coerce 'RepeatedGetMirroringDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::GetMirroringDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringGetMirroringDeploymentRequest',
    as HashRef[GetMirroringDeploymentRequest()];

declare 'CreateMirroringDeploymentRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::CreateMirroringDeploymentRequest'];

coerce 'CreateMirroringDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::CreateMirroringDeploymentRequest'->new($_) };

declare 'RepeatedCreateMirroringDeploymentRequest',
    as ArrayRef[CreateMirroringDeploymentRequest()];

coerce 'RepeatedCreateMirroringDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::CreateMirroringDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateMirroringDeploymentRequest',
    as HashRef[CreateMirroringDeploymentRequest()];

declare 'UpdateMirroringDeploymentRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::UpdateMirroringDeploymentRequest'];

coerce 'UpdateMirroringDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::UpdateMirroringDeploymentRequest'->new($_) };

declare 'RepeatedUpdateMirroringDeploymentRequest',
    as ArrayRef[UpdateMirroringDeploymentRequest()];

coerce 'RepeatedUpdateMirroringDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::UpdateMirroringDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateMirroringDeploymentRequest',
    as HashRef[UpdateMirroringDeploymentRequest()];

declare 'DeleteMirroringDeploymentRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::DeleteMirroringDeploymentRequest'];

coerce 'DeleteMirroringDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::DeleteMirroringDeploymentRequest'->new($_) };

declare 'RepeatedDeleteMirroringDeploymentRequest',
    as ArrayRef[DeleteMirroringDeploymentRequest()];

coerce 'RepeatedDeleteMirroringDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::DeleteMirroringDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteMirroringDeploymentRequest',
    as HashRef[DeleteMirroringDeploymentRequest()];

declare 'MirroringLocation',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Mirroring::MirroringLocation'];

coerce 'MirroringLocation',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Mirroring::MirroringLocation'->new($_) };

declare 'RepeatedMirroringLocation',
    as ArrayRef[MirroringLocation()];

coerce 'RepeatedMirroringLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Mirroring::MirroringLocation'->new($_) } @$_ ] };

declare 'MapStringMirroringLocation',
    as HashRef[MirroringLocation()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Networksecurity::V1::Mirroring::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
