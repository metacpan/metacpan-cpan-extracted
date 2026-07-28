package Google::Cloud::Networksecurity::V1::Intercept::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'InterceptEndpointGroup',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::InterceptEndpointGroup'];

coerce 'InterceptEndpointGroup',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::InterceptEndpointGroup'->new($_) };

declare 'RepeatedInterceptEndpointGroup',
    as ArrayRef[InterceptEndpointGroup()];

coerce 'RepeatedInterceptEndpointGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::InterceptEndpointGroup'->new($_) } @$_ ] };

declare 'MapStringInterceptEndpointGroup',
    as HashRef[InterceptEndpointGroup()];

declare 'State',
    as (Int | Str);

declare 'ConnectedDeploymentGroup',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::InterceptEndpointGroup::ConnectedDeploymentGroup'];

coerce 'ConnectedDeploymentGroup',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::InterceptEndpointGroup::ConnectedDeploymentGroup'->new($_) };

declare 'RepeatedConnectedDeploymentGroup',
    as ArrayRef[ConnectedDeploymentGroup()];

coerce 'RepeatedConnectedDeploymentGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::InterceptEndpointGroup::ConnectedDeploymentGroup'->new($_) } @$_ ] };

declare 'MapStringConnectedDeploymentGroup',
    as HashRef[ConnectedDeploymentGroup()];

declare 'AssociationDetails',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::InterceptEndpointGroup::AssociationDetails'];

coerce 'AssociationDetails',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::InterceptEndpointGroup::AssociationDetails'->new($_) };

declare 'RepeatedAssociationDetails',
    as ArrayRef[AssociationDetails()];

coerce 'RepeatedAssociationDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::InterceptEndpointGroup::AssociationDetails'->new($_) } @$_ ] };

declare 'MapStringAssociationDetails',
    as HashRef[AssociationDetails()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::InterceptEndpointGroup::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::InterceptEndpointGroup::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::InterceptEndpointGroup::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListInterceptEndpointGroupsRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::ListInterceptEndpointGroupsRequest'];

coerce 'ListInterceptEndpointGroupsRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::ListInterceptEndpointGroupsRequest'->new($_) };

declare 'RepeatedListInterceptEndpointGroupsRequest',
    as ArrayRef[ListInterceptEndpointGroupsRequest()];

coerce 'RepeatedListInterceptEndpointGroupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::ListInterceptEndpointGroupsRequest'->new($_) } @$_ ] };

declare 'MapStringListInterceptEndpointGroupsRequest',
    as HashRef[ListInterceptEndpointGroupsRequest()];

declare 'ListInterceptEndpointGroupsResponse',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::ListInterceptEndpointGroupsResponse'];

coerce 'ListInterceptEndpointGroupsResponse',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::ListInterceptEndpointGroupsResponse'->new($_) };

declare 'RepeatedListInterceptEndpointGroupsResponse',
    as ArrayRef[ListInterceptEndpointGroupsResponse()];

coerce 'RepeatedListInterceptEndpointGroupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::ListInterceptEndpointGroupsResponse'->new($_) } @$_ ] };

declare 'MapStringListInterceptEndpointGroupsResponse',
    as HashRef[ListInterceptEndpointGroupsResponse()];

declare 'GetInterceptEndpointGroupRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::GetInterceptEndpointGroupRequest'];

coerce 'GetInterceptEndpointGroupRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::GetInterceptEndpointGroupRequest'->new($_) };

declare 'RepeatedGetInterceptEndpointGroupRequest',
    as ArrayRef[GetInterceptEndpointGroupRequest()];

coerce 'RepeatedGetInterceptEndpointGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::GetInterceptEndpointGroupRequest'->new($_) } @$_ ] };

declare 'MapStringGetInterceptEndpointGroupRequest',
    as HashRef[GetInterceptEndpointGroupRequest()];

declare 'CreateInterceptEndpointGroupRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::CreateInterceptEndpointGroupRequest'];

coerce 'CreateInterceptEndpointGroupRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::CreateInterceptEndpointGroupRequest'->new($_) };

declare 'RepeatedCreateInterceptEndpointGroupRequest',
    as ArrayRef[CreateInterceptEndpointGroupRequest()];

coerce 'RepeatedCreateInterceptEndpointGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::CreateInterceptEndpointGroupRequest'->new($_) } @$_ ] };

declare 'MapStringCreateInterceptEndpointGroupRequest',
    as HashRef[CreateInterceptEndpointGroupRequest()];

declare 'UpdateInterceptEndpointGroupRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::UpdateInterceptEndpointGroupRequest'];

coerce 'UpdateInterceptEndpointGroupRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::UpdateInterceptEndpointGroupRequest'->new($_) };

declare 'RepeatedUpdateInterceptEndpointGroupRequest',
    as ArrayRef[UpdateInterceptEndpointGroupRequest()];

coerce 'RepeatedUpdateInterceptEndpointGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::UpdateInterceptEndpointGroupRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateInterceptEndpointGroupRequest',
    as HashRef[UpdateInterceptEndpointGroupRequest()];

declare 'DeleteInterceptEndpointGroupRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::DeleteInterceptEndpointGroupRequest'];

coerce 'DeleteInterceptEndpointGroupRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::DeleteInterceptEndpointGroupRequest'->new($_) };

declare 'RepeatedDeleteInterceptEndpointGroupRequest',
    as ArrayRef[DeleteInterceptEndpointGroupRequest()];

coerce 'RepeatedDeleteInterceptEndpointGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::DeleteInterceptEndpointGroupRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteInterceptEndpointGroupRequest',
    as HashRef[DeleteInterceptEndpointGroupRequest()];

declare 'InterceptEndpointGroupAssociation',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::InterceptEndpointGroupAssociation'];

coerce 'InterceptEndpointGroupAssociation',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::InterceptEndpointGroupAssociation'->new($_) };

declare 'RepeatedInterceptEndpointGroupAssociation',
    as ArrayRef[InterceptEndpointGroupAssociation()];

coerce 'RepeatedInterceptEndpointGroupAssociation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::InterceptEndpointGroupAssociation'->new($_) } @$_ ] };

declare 'MapStringInterceptEndpointGroupAssociation',
    as HashRef[InterceptEndpointGroupAssociation()];

declare 'State',
    as (Int | Str);

declare 'LocationDetails',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::InterceptEndpointGroupAssociation::LocationDetails'];

coerce 'LocationDetails',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::InterceptEndpointGroupAssociation::LocationDetails'->new($_) };

declare 'RepeatedLocationDetails',
    as ArrayRef[LocationDetails()];

coerce 'RepeatedLocationDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::InterceptEndpointGroupAssociation::LocationDetails'->new($_) } @$_ ] };

declare 'MapStringLocationDetails',
    as HashRef[LocationDetails()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::InterceptEndpointGroupAssociation::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::InterceptEndpointGroupAssociation::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::InterceptEndpointGroupAssociation::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListInterceptEndpointGroupAssociationsRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::ListInterceptEndpointGroupAssociationsRequest'];

coerce 'ListInterceptEndpointGroupAssociationsRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::ListInterceptEndpointGroupAssociationsRequest'->new($_) };

declare 'RepeatedListInterceptEndpointGroupAssociationsRequest',
    as ArrayRef[ListInterceptEndpointGroupAssociationsRequest()];

coerce 'RepeatedListInterceptEndpointGroupAssociationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::ListInterceptEndpointGroupAssociationsRequest'->new($_) } @$_ ] };

declare 'MapStringListInterceptEndpointGroupAssociationsRequest',
    as HashRef[ListInterceptEndpointGroupAssociationsRequest()];

declare 'ListInterceptEndpointGroupAssociationsResponse',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::ListInterceptEndpointGroupAssociationsResponse'];

coerce 'ListInterceptEndpointGroupAssociationsResponse',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::ListInterceptEndpointGroupAssociationsResponse'->new($_) };

declare 'RepeatedListInterceptEndpointGroupAssociationsResponse',
    as ArrayRef[ListInterceptEndpointGroupAssociationsResponse()];

coerce 'RepeatedListInterceptEndpointGroupAssociationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::ListInterceptEndpointGroupAssociationsResponse'->new($_) } @$_ ] };

declare 'MapStringListInterceptEndpointGroupAssociationsResponse',
    as HashRef[ListInterceptEndpointGroupAssociationsResponse()];

declare 'GetInterceptEndpointGroupAssociationRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::GetInterceptEndpointGroupAssociationRequest'];

coerce 'GetInterceptEndpointGroupAssociationRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::GetInterceptEndpointGroupAssociationRequest'->new($_) };

declare 'RepeatedGetInterceptEndpointGroupAssociationRequest',
    as ArrayRef[GetInterceptEndpointGroupAssociationRequest()];

coerce 'RepeatedGetInterceptEndpointGroupAssociationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::GetInterceptEndpointGroupAssociationRequest'->new($_) } @$_ ] };

declare 'MapStringGetInterceptEndpointGroupAssociationRequest',
    as HashRef[GetInterceptEndpointGroupAssociationRequest()];

declare 'CreateInterceptEndpointGroupAssociationRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::CreateInterceptEndpointGroupAssociationRequest'];

coerce 'CreateInterceptEndpointGroupAssociationRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::CreateInterceptEndpointGroupAssociationRequest'->new($_) };

declare 'RepeatedCreateInterceptEndpointGroupAssociationRequest',
    as ArrayRef[CreateInterceptEndpointGroupAssociationRequest()];

coerce 'RepeatedCreateInterceptEndpointGroupAssociationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::CreateInterceptEndpointGroupAssociationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateInterceptEndpointGroupAssociationRequest',
    as HashRef[CreateInterceptEndpointGroupAssociationRequest()];

declare 'UpdateInterceptEndpointGroupAssociationRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::UpdateInterceptEndpointGroupAssociationRequest'];

coerce 'UpdateInterceptEndpointGroupAssociationRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::UpdateInterceptEndpointGroupAssociationRequest'->new($_) };

declare 'RepeatedUpdateInterceptEndpointGroupAssociationRequest',
    as ArrayRef[UpdateInterceptEndpointGroupAssociationRequest()];

coerce 'RepeatedUpdateInterceptEndpointGroupAssociationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::UpdateInterceptEndpointGroupAssociationRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateInterceptEndpointGroupAssociationRequest',
    as HashRef[UpdateInterceptEndpointGroupAssociationRequest()];

declare 'DeleteInterceptEndpointGroupAssociationRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::DeleteInterceptEndpointGroupAssociationRequest'];

coerce 'DeleteInterceptEndpointGroupAssociationRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::DeleteInterceptEndpointGroupAssociationRequest'->new($_) };

declare 'RepeatedDeleteInterceptEndpointGroupAssociationRequest',
    as ArrayRef[DeleteInterceptEndpointGroupAssociationRequest()];

coerce 'RepeatedDeleteInterceptEndpointGroupAssociationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::DeleteInterceptEndpointGroupAssociationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteInterceptEndpointGroupAssociationRequest',
    as HashRef[DeleteInterceptEndpointGroupAssociationRequest()];

declare 'InterceptDeploymentGroup',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::InterceptDeploymentGroup'];

coerce 'InterceptDeploymentGroup',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::InterceptDeploymentGroup'->new($_) };

declare 'RepeatedInterceptDeploymentGroup',
    as ArrayRef[InterceptDeploymentGroup()];

coerce 'RepeatedInterceptDeploymentGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::InterceptDeploymentGroup'->new($_) } @$_ ] };

declare 'MapStringInterceptDeploymentGroup',
    as HashRef[InterceptDeploymentGroup()];

declare 'State',
    as (Int | Str);

declare 'ConnectedEndpointGroup',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::InterceptDeploymentGroup::ConnectedEndpointGroup'];

coerce 'ConnectedEndpointGroup',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::InterceptDeploymentGroup::ConnectedEndpointGroup'->new($_) };

declare 'RepeatedConnectedEndpointGroup',
    as ArrayRef[ConnectedEndpointGroup()];

coerce 'RepeatedConnectedEndpointGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::InterceptDeploymentGroup::ConnectedEndpointGroup'->new($_) } @$_ ] };

declare 'MapStringConnectedEndpointGroup',
    as HashRef[ConnectedEndpointGroup()];

declare 'Deployment',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::InterceptDeploymentGroup::Deployment'];

coerce 'Deployment',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::InterceptDeploymentGroup::Deployment'->new($_) };

declare 'RepeatedDeployment',
    as ArrayRef[Deployment()];

coerce 'RepeatedDeployment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::InterceptDeploymentGroup::Deployment'->new($_) } @$_ ] };

declare 'MapStringDeployment',
    as HashRef[Deployment()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::InterceptDeploymentGroup::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::InterceptDeploymentGroup::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::InterceptDeploymentGroup::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListInterceptDeploymentGroupsRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::ListInterceptDeploymentGroupsRequest'];

coerce 'ListInterceptDeploymentGroupsRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::ListInterceptDeploymentGroupsRequest'->new($_) };

declare 'RepeatedListInterceptDeploymentGroupsRequest',
    as ArrayRef[ListInterceptDeploymentGroupsRequest()];

coerce 'RepeatedListInterceptDeploymentGroupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::ListInterceptDeploymentGroupsRequest'->new($_) } @$_ ] };

declare 'MapStringListInterceptDeploymentGroupsRequest',
    as HashRef[ListInterceptDeploymentGroupsRequest()];

declare 'ListInterceptDeploymentGroupsResponse',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::ListInterceptDeploymentGroupsResponse'];

coerce 'ListInterceptDeploymentGroupsResponse',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::ListInterceptDeploymentGroupsResponse'->new($_) };

declare 'RepeatedListInterceptDeploymentGroupsResponse',
    as ArrayRef[ListInterceptDeploymentGroupsResponse()];

coerce 'RepeatedListInterceptDeploymentGroupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::ListInterceptDeploymentGroupsResponse'->new($_) } @$_ ] };

declare 'MapStringListInterceptDeploymentGroupsResponse',
    as HashRef[ListInterceptDeploymentGroupsResponse()];

declare 'GetInterceptDeploymentGroupRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::GetInterceptDeploymentGroupRequest'];

coerce 'GetInterceptDeploymentGroupRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::GetInterceptDeploymentGroupRequest'->new($_) };

declare 'RepeatedGetInterceptDeploymentGroupRequest',
    as ArrayRef[GetInterceptDeploymentGroupRequest()];

coerce 'RepeatedGetInterceptDeploymentGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::GetInterceptDeploymentGroupRequest'->new($_) } @$_ ] };

declare 'MapStringGetInterceptDeploymentGroupRequest',
    as HashRef[GetInterceptDeploymentGroupRequest()];

declare 'CreateInterceptDeploymentGroupRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::CreateInterceptDeploymentGroupRequest'];

coerce 'CreateInterceptDeploymentGroupRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::CreateInterceptDeploymentGroupRequest'->new($_) };

declare 'RepeatedCreateInterceptDeploymentGroupRequest',
    as ArrayRef[CreateInterceptDeploymentGroupRequest()];

coerce 'RepeatedCreateInterceptDeploymentGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::CreateInterceptDeploymentGroupRequest'->new($_) } @$_ ] };

declare 'MapStringCreateInterceptDeploymentGroupRequest',
    as HashRef[CreateInterceptDeploymentGroupRequest()];

declare 'UpdateInterceptDeploymentGroupRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::UpdateInterceptDeploymentGroupRequest'];

coerce 'UpdateInterceptDeploymentGroupRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::UpdateInterceptDeploymentGroupRequest'->new($_) };

declare 'RepeatedUpdateInterceptDeploymentGroupRequest',
    as ArrayRef[UpdateInterceptDeploymentGroupRequest()];

coerce 'RepeatedUpdateInterceptDeploymentGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::UpdateInterceptDeploymentGroupRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateInterceptDeploymentGroupRequest',
    as HashRef[UpdateInterceptDeploymentGroupRequest()];

declare 'DeleteInterceptDeploymentGroupRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::DeleteInterceptDeploymentGroupRequest'];

coerce 'DeleteInterceptDeploymentGroupRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::DeleteInterceptDeploymentGroupRequest'->new($_) };

declare 'RepeatedDeleteInterceptDeploymentGroupRequest',
    as ArrayRef[DeleteInterceptDeploymentGroupRequest()];

coerce 'RepeatedDeleteInterceptDeploymentGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::DeleteInterceptDeploymentGroupRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteInterceptDeploymentGroupRequest',
    as HashRef[DeleteInterceptDeploymentGroupRequest()];

declare 'InterceptDeployment',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::InterceptDeployment'];

coerce 'InterceptDeployment',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::InterceptDeployment'->new($_) };

declare 'RepeatedInterceptDeployment',
    as ArrayRef[InterceptDeployment()];

coerce 'RepeatedInterceptDeployment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::InterceptDeployment'->new($_) } @$_ ] };

declare 'MapStringInterceptDeployment',
    as HashRef[InterceptDeployment()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::InterceptDeployment::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::InterceptDeployment::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::InterceptDeployment::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListInterceptDeploymentsRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::ListInterceptDeploymentsRequest'];

coerce 'ListInterceptDeploymentsRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::ListInterceptDeploymentsRequest'->new($_) };

declare 'RepeatedListInterceptDeploymentsRequest',
    as ArrayRef[ListInterceptDeploymentsRequest()];

coerce 'RepeatedListInterceptDeploymentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::ListInterceptDeploymentsRequest'->new($_) } @$_ ] };

declare 'MapStringListInterceptDeploymentsRequest',
    as HashRef[ListInterceptDeploymentsRequest()];

declare 'ListInterceptDeploymentsResponse',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::ListInterceptDeploymentsResponse'];

coerce 'ListInterceptDeploymentsResponse',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::ListInterceptDeploymentsResponse'->new($_) };

declare 'RepeatedListInterceptDeploymentsResponse',
    as ArrayRef[ListInterceptDeploymentsResponse()];

coerce 'RepeatedListInterceptDeploymentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::ListInterceptDeploymentsResponse'->new($_) } @$_ ] };

declare 'MapStringListInterceptDeploymentsResponse',
    as HashRef[ListInterceptDeploymentsResponse()];

declare 'GetInterceptDeploymentRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::GetInterceptDeploymentRequest'];

coerce 'GetInterceptDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::GetInterceptDeploymentRequest'->new($_) };

declare 'RepeatedGetInterceptDeploymentRequest',
    as ArrayRef[GetInterceptDeploymentRequest()];

coerce 'RepeatedGetInterceptDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::GetInterceptDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringGetInterceptDeploymentRequest',
    as HashRef[GetInterceptDeploymentRequest()];

declare 'CreateInterceptDeploymentRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::CreateInterceptDeploymentRequest'];

coerce 'CreateInterceptDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::CreateInterceptDeploymentRequest'->new($_) };

declare 'RepeatedCreateInterceptDeploymentRequest',
    as ArrayRef[CreateInterceptDeploymentRequest()];

coerce 'RepeatedCreateInterceptDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::CreateInterceptDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateInterceptDeploymentRequest',
    as HashRef[CreateInterceptDeploymentRequest()];

declare 'UpdateInterceptDeploymentRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::UpdateInterceptDeploymentRequest'];

coerce 'UpdateInterceptDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::UpdateInterceptDeploymentRequest'->new($_) };

declare 'RepeatedUpdateInterceptDeploymentRequest',
    as ArrayRef[UpdateInterceptDeploymentRequest()];

coerce 'RepeatedUpdateInterceptDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::UpdateInterceptDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateInterceptDeploymentRequest',
    as HashRef[UpdateInterceptDeploymentRequest()];

declare 'DeleteInterceptDeploymentRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::DeleteInterceptDeploymentRequest'];

coerce 'DeleteInterceptDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::DeleteInterceptDeploymentRequest'->new($_) };

declare 'RepeatedDeleteInterceptDeploymentRequest',
    as ArrayRef[DeleteInterceptDeploymentRequest()];

coerce 'RepeatedDeleteInterceptDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::DeleteInterceptDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteInterceptDeploymentRequest',
    as HashRef[DeleteInterceptDeploymentRequest()];

declare 'InterceptLocation',
    as InstanceOf['Google::Cloud::Networksecurity::V1::Intercept::InterceptLocation'];

coerce 'InterceptLocation',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::Intercept::InterceptLocation'->new($_) };

declare 'RepeatedInterceptLocation',
    as ArrayRef[InterceptLocation()];

coerce 'RepeatedInterceptLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::Intercept::InterceptLocation'->new($_) } @$_ ] };

declare 'MapStringInterceptLocation',
    as HashRef[InterceptLocation()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Networksecurity::V1::Intercept::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
