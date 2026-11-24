package Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListSaasRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListSaasRequest'];

coerce 'ListSaasRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListSaasRequest'->new($_) };

declare 'RepeatedListSaasRequest',
    as ArrayRef[ListSaasRequest()];

coerce 'RepeatedListSaasRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListSaasRequest'->new($_) } @$_ ] };

declare 'MapStringListSaasRequest',
    as HashRef[ListSaasRequest()];

declare 'ListSaasResponse',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListSaasResponse'];

coerce 'ListSaasResponse',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListSaasResponse'->new($_) };

declare 'RepeatedListSaasResponse',
    as ArrayRef[ListSaasResponse()];

coerce 'RepeatedListSaasResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListSaasResponse'->new($_) } @$_ ] };

declare 'MapStringListSaasResponse',
    as HashRef[ListSaasResponse()];

declare 'GetSaasRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::GetSaasRequest'];

coerce 'GetSaasRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::GetSaasRequest'->new($_) };

declare 'RepeatedGetSaasRequest',
    as ArrayRef[GetSaasRequest()];

coerce 'RepeatedGetSaasRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::GetSaasRequest'->new($_) } @$_ ] };

declare 'MapStringGetSaasRequest',
    as HashRef[GetSaasRequest()];

declare 'CreateSaasRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::CreateSaasRequest'];

coerce 'CreateSaasRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::CreateSaasRequest'->new($_) };

declare 'RepeatedCreateSaasRequest',
    as ArrayRef[CreateSaasRequest()];

coerce 'RepeatedCreateSaasRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::CreateSaasRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSaasRequest',
    as HashRef[CreateSaasRequest()];

declare 'UpdateSaasRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::UpdateSaasRequest'];

coerce 'UpdateSaasRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::UpdateSaasRequest'->new($_) };

declare 'RepeatedUpdateSaasRequest',
    as ArrayRef[UpdateSaasRequest()];

coerce 'RepeatedUpdateSaasRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::UpdateSaasRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSaasRequest',
    as HashRef[UpdateSaasRequest()];

declare 'DeleteSaasRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::DeleteSaasRequest'];

coerce 'DeleteSaasRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::DeleteSaasRequest'->new($_) };

declare 'RepeatedDeleteSaasRequest',
    as ArrayRef[DeleteSaasRequest()];

coerce 'RepeatedDeleteSaasRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::DeleteSaasRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSaasRequest',
    as HashRef[DeleteSaasRequest()];

declare 'ListTenantsRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListTenantsRequest'];

coerce 'ListTenantsRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListTenantsRequest'->new($_) };

declare 'RepeatedListTenantsRequest',
    as ArrayRef[ListTenantsRequest()];

coerce 'RepeatedListTenantsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListTenantsRequest'->new($_) } @$_ ] };

declare 'MapStringListTenantsRequest',
    as HashRef[ListTenantsRequest()];

declare 'ListTenantsResponse',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListTenantsResponse'];

coerce 'ListTenantsResponse',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListTenantsResponse'->new($_) };

declare 'RepeatedListTenantsResponse',
    as ArrayRef[ListTenantsResponse()];

coerce 'RepeatedListTenantsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListTenantsResponse'->new($_) } @$_ ] };

declare 'MapStringListTenantsResponse',
    as HashRef[ListTenantsResponse()];

declare 'GetTenantRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::GetTenantRequest'];

coerce 'GetTenantRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::GetTenantRequest'->new($_) };

declare 'RepeatedGetTenantRequest',
    as ArrayRef[GetTenantRequest()];

coerce 'RepeatedGetTenantRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::GetTenantRequest'->new($_) } @$_ ] };

declare 'MapStringGetTenantRequest',
    as HashRef[GetTenantRequest()];

declare 'CreateTenantRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::CreateTenantRequest'];

coerce 'CreateTenantRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::CreateTenantRequest'->new($_) };

declare 'RepeatedCreateTenantRequest',
    as ArrayRef[CreateTenantRequest()];

coerce 'RepeatedCreateTenantRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::CreateTenantRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTenantRequest',
    as HashRef[CreateTenantRequest()];

declare 'UpdateTenantRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::UpdateTenantRequest'];

coerce 'UpdateTenantRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::UpdateTenantRequest'->new($_) };

declare 'RepeatedUpdateTenantRequest',
    as ArrayRef[UpdateTenantRequest()];

coerce 'RepeatedUpdateTenantRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::UpdateTenantRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTenantRequest',
    as HashRef[UpdateTenantRequest()];

declare 'DeleteTenantRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::DeleteTenantRequest'];

coerce 'DeleteTenantRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::DeleteTenantRequest'->new($_) };

declare 'RepeatedDeleteTenantRequest',
    as ArrayRef[DeleteTenantRequest()];

coerce 'RepeatedDeleteTenantRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::DeleteTenantRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTenantRequest',
    as HashRef[DeleteTenantRequest()];

declare 'ListUnitKindsRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListUnitKindsRequest'];

coerce 'ListUnitKindsRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListUnitKindsRequest'->new($_) };

declare 'RepeatedListUnitKindsRequest',
    as ArrayRef[ListUnitKindsRequest()];

coerce 'RepeatedListUnitKindsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListUnitKindsRequest'->new($_) } @$_ ] };

declare 'MapStringListUnitKindsRequest',
    as HashRef[ListUnitKindsRequest()];

declare 'ListUnitKindsResponse',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListUnitKindsResponse'];

coerce 'ListUnitKindsResponse',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListUnitKindsResponse'->new($_) };

declare 'RepeatedListUnitKindsResponse',
    as ArrayRef[ListUnitKindsResponse()];

coerce 'RepeatedListUnitKindsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListUnitKindsResponse'->new($_) } @$_ ] };

declare 'MapStringListUnitKindsResponse',
    as HashRef[ListUnitKindsResponse()];

declare 'GetUnitKindRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::GetUnitKindRequest'];

coerce 'GetUnitKindRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::GetUnitKindRequest'->new($_) };

declare 'RepeatedGetUnitKindRequest',
    as ArrayRef[GetUnitKindRequest()];

coerce 'RepeatedGetUnitKindRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::GetUnitKindRequest'->new($_) } @$_ ] };

declare 'MapStringGetUnitKindRequest',
    as HashRef[GetUnitKindRequest()];

declare 'CreateUnitKindRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::CreateUnitKindRequest'];

coerce 'CreateUnitKindRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::CreateUnitKindRequest'->new($_) };

declare 'RepeatedCreateUnitKindRequest',
    as ArrayRef[CreateUnitKindRequest()];

coerce 'RepeatedCreateUnitKindRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::CreateUnitKindRequest'->new($_) } @$_ ] };

declare 'MapStringCreateUnitKindRequest',
    as HashRef[CreateUnitKindRequest()];

declare 'UpdateUnitKindRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::UpdateUnitKindRequest'];

coerce 'UpdateUnitKindRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::UpdateUnitKindRequest'->new($_) };

declare 'RepeatedUpdateUnitKindRequest',
    as ArrayRef[UpdateUnitKindRequest()];

coerce 'RepeatedUpdateUnitKindRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::UpdateUnitKindRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateUnitKindRequest',
    as HashRef[UpdateUnitKindRequest()];

declare 'DeleteUnitKindRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::DeleteUnitKindRequest'];

coerce 'DeleteUnitKindRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::DeleteUnitKindRequest'->new($_) };

declare 'RepeatedDeleteUnitKindRequest',
    as ArrayRef[DeleteUnitKindRequest()];

coerce 'RepeatedDeleteUnitKindRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::DeleteUnitKindRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteUnitKindRequest',
    as HashRef[DeleteUnitKindRequest()];

declare 'ListUnitsRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListUnitsRequest'];

coerce 'ListUnitsRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListUnitsRequest'->new($_) };

declare 'RepeatedListUnitsRequest',
    as ArrayRef[ListUnitsRequest()];

coerce 'RepeatedListUnitsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListUnitsRequest'->new($_) } @$_ ] };

declare 'MapStringListUnitsRequest',
    as HashRef[ListUnitsRequest()];

declare 'ListUnitsResponse',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListUnitsResponse'];

coerce 'ListUnitsResponse',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListUnitsResponse'->new($_) };

declare 'RepeatedListUnitsResponse',
    as ArrayRef[ListUnitsResponse()];

coerce 'RepeatedListUnitsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListUnitsResponse'->new($_) } @$_ ] };

declare 'MapStringListUnitsResponse',
    as HashRef[ListUnitsResponse()];

declare 'GetUnitRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::GetUnitRequest'];

coerce 'GetUnitRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::GetUnitRequest'->new($_) };

declare 'RepeatedGetUnitRequest',
    as ArrayRef[GetUnitRequest()];

coerce 'RepeatedGetUnitRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::GetUnitRequest'->new($_) } @$_ ] };

declare 'MapStringGetUnitRequest',
    as HashRef[GetUnitRequest()];

declare 'CreateUnitRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::CreateUnitRequest'];

coerce 'CreateUnitRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::CreateUnitRequest'->new($_) };

declare 'RepeatedCreateUnitRequest',
    as ArrayRef[CreateUnitRequest()];

coerce 'RepeatedCreateUnitRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::CreateUnitRequest'->new($_) } @$_ ] };

declare 'MapStringCreateUnitRequest',
    as HashRef[CreateUnitRequest()];

declare 'UpdateUnitRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::UpdateUnitRequest'];

coerce 'UpdateUnitRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::UpdateUnitRequest'->new($_) };

declare 'RepeatedUpdateUnitRequest',
    as ArrayRef[UpdateUnitRequest()];

coerce 'RepeatedUpdateUnitRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::UpdateUnitRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateUnitRequest',
    as HashRef[UpdateUnitRequest()];

declare 'DeleteUnitRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::DeleteUnitRequest'];

coerce 'DeleteUnitRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::DeleteUnitRequest'->new($_) };

declare 'RepeatedDeleteUnitRequest',
    as ArrayRef[DeleteUnitRequest()];

coerce 'RepeatedDeleteUnitRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::DeleteUnitRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteUnitRequest',
    as HashRef[DeleteUnitRequest()];

declare 'ListUnitOperationsRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListUnitOperationsRequest'];

coerce 'ListUnitOperationsRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListUnitOperationsRequest'->new($_) };

declare 'RepeatedListUnitOperationsRequest',
    as ArrayRef[ListUnitOperationsRequest()];

coerce 'RepeatedListUnitOperationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListUnitOperationsRequest'->new($_) } @$_ ] };

declare 'MapStringListUnitOperationsRequest',
    as HashRef[ListUnitOperationsRequest()];

declare 'ListUnitOperationsResponse',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListUnitOperationsResponse'];

coerce 'ListUnitOperationsResponse',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListUnitOperationsResponse'->new($_) };

declare 'RepeatedListUnitOperationsResponse',
    as ArrayRef[ListUnitOperationsResponse()];

coerce 'RepeatedListUnitOperationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListUnitOperationsResponse'->new($_) } @$_ ] };

declare 'MapStringListUnitOperationsResponse',
    as HashRef[ListUnitOperationsResponse()];

declare 'GetUnitOperationRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::GetUnitOperationRequest'];

coerce 'GetUnitOperationRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::GetUnitOperationRequest'->new($_) };

declare 'RepeatedGetUnitOperationRequest',
    as ArrayRef[GetUnitOperationRequest()];

coerce 'RepeatedGetUnitOperationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::GetUnitOperationRequest'->new($_) } @$_ ] };

declare 'MapStringGetUnitOperationRequest',
    as HashRef[GetUnitOperationRequest()];

declare 'CreateUnitOperationRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::CreateUnitOperationRequest'];

coerce 'CreateUnitOperationRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::CreateUnitOperationRequest'->new($_) };

declare 'RepeatedCreateUnitOperationRequest',
    as ArrayRef[CreateUnitOperationRequest()];

coerce 'RepeatedCreateUnitOperationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::CreateUnitOperationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateUnitOperationRequest',
    as HashRef[CreateUnitOperationRequest()];

declare 'UpdateUnitOperationRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::UpdateUnitOperationRequest'];

coerce 'UpdateUnitOperationRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::UpdateUnitOperationRequest'->new($_) };

declare 'RepeatedUpdateUnitOperationRequest',
    as ArrayRef[UpdateUnitOperationRequest()];

coerce 'RepeatedUpdateUnitOperationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::UpdateUnitOperationRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateUnitOperationRequest',
    as HashRef[UpdateUnitOperationRequest()];

declare 'DeleteUnitOperationRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::DeleteUnitOperationRequest'];

coerce 'DeleteUnitOperationRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::DeleteUnitOperationRequest'->new($_) };

declare 'RepeatedDeleteUnitOperationRequest',
    as ArrayRef[DeleteUnitOperationRequest()];

coerce 'RepeatedDeleteUnitOperationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::DeleteUnitOperationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteUnitOperationRequest',
    as HashRef[DeleteUnitOperationRequest()];

declare 'ListReleasesRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListReleasesRequest'];

coerce 'ListReleasesRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListReleasesRequest'->new($_) };

declare 'RepeatedListReleasesRequest',
    as ArrayRef[ListReleasesRequest()];

coerce 'RepeatedListReleasesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListReleasesRequest'->new($_) } @$_ ] };

declare 'MapStringListReleasesRequest',
    as HashRef[ListReleasesRequest()];

declare 'ListReleasesResponse',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListReleasesResponse'];

coerce 'ListReleasesResponse',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListReleasesResponse'->new($_) };

declare 'RepeatedListReleasesResponse',
    as ArrayRef[ListReleasesResponse()];

coerce 'RepeatedListReleasesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::ListReleasesResponse'->new($_) } @$_ ] };

declare 'MapStringListReleasesResponse',
    as HashRef[ListReleasesResponse()];

declare 'GetReleaseRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::GetReleaseRequest'];

coerce 'GetReleaseRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::GetReleaseRequest'->new($_) };

declare 'RepeatedGetReleaseRequest',
    as ArrayRef[GetReleaseRequest()];

coerce 'RepeatedGetReleaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::GetReleaseRequest'->new($_) } @$_ ] };

declare 'MapStringGetReleaseRequest',
    as HashRef[GetReleaseRequest()];

declare 'CreateReleaseRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::CreateReleaseRequest'];

coerce 'CreateReleaseRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::CreateReleaseRequest'->new($_) };

declare 'RepeatedCreateReleaseRequest',
    as ArrayRef[CreateReleaseRequest()];

coerce 'RepeatedCreateReleaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::CreateReleaseRequest'->new($_) } @$_ ] };

declare 'MapStringCreateReleaseRequest',
    as HashRef[CreateReleaseRequest()];

declare 'UpdateReleaseRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::UpdateReleaseRequest'];

coerce 'UpdateReleaseRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::UpdateReleaseRequest'->new($_) };

declare 'RepeatedUpdateReleaseRequest',
    as ArrayRef[UpdateReleaseRequest()];

coerce 'RepeatedUpdateReleaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::UpdateReleaseRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateReleaseRequest',
    as HashRef[UpdateReleaseRequest()];

declare 'DeleteReleaseRequest',
    as InstanceOf['Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::DeleteReleaseRequest'];

coerce 'DeleteReleaseRequest',
    from HashRef, via { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::DeleteReleaseRequest'->new($_) };

declare 'RepeatedDeleteReleaseRequest',
    as ArrayRef[DeleteReleaseRequest()];

coerce 'RepeatedDeleteReleaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::DeleteReleaseRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteReleaseRequest',
    as HashRef[DeleteReleaseRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Saasplatform::Saasservicemgmt::V1::DeploymentsService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
