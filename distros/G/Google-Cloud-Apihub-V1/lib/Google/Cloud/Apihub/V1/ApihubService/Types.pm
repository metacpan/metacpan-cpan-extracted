package Google::Cloud::Apihub::V1::ApihubService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateApiRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::CreateApiRequest'];

coerce 'CreateApiRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::CreateApiRequest'->new($_) };

declare 'RepeatedCreateApiRequest',
    as ArrayRef[CreateApiRequest()];

coerce 'RepeatedCreateApiRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::CreateApiRequest'->new($_) } @$_ ] };

declare 'MapStringCreateApiRequest',
    as HashRef[CreateApiRequest()];

declare 'GetApiRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::GetApiRequest'];

coerce 'GetApiRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::GetApiRequest'->new($_) };

declare 'RepeatedGetApiRequest',
    as ArrayRef[GetApiRequest()];

coerce 'RepeatedGetApiRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::GetApiRequest'->new($_) } @$_ ] };

declare 'MapStringGetApiRequest',
    as HashRef[GetApiRequest()];

declare 'UpdateApiRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::UpdateApiRequest'];

coerce 'UpdateApiRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::UpdateApiRequest'->new($_) };

declare 'RepeatedUpdateApiRequest',
    as ArrayRef[UpdateApiRequest()];

coerce 'RepeatedUpdateApiRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::UpdateApiRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateApiRequest',
    as HashRef[UpdateApiRequest()];

declare 'DeleteApiRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::DeleteApiRequest'];

coerce 'DeleteApiRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::DeleteApiRequest'->new($_) };

declare 'RepeatedDeleteApiRequest',
    as ArrayRef[DeleteApiRequest()];

coerce 'RepeatedDeleteApiRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::DeleteApiRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteApiRequest',
    as HashRef[DeleteApiRequest()];

declare 'ListApisRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::ListApisRequest'];

coerce 'ListApisRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::ListApisRequest'->new($_) };

declare 'RepeatedListApisRequest',
    as ArrayRef[ListApisRequest()];

coerce 'RepeatedListApisRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::ListApisRequest'->new($_) } @$_ ] };

declare 'MapStringListApisRequest',
    as HashRef[ListApisRequest()];

declare 'ListApisResponse',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::ListApisResponse'];

coerce 'ListApisResponse',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::ListApisResponse'->new($_) };

declare 'RepeatedListApisResponse',
    as ArrayRef[ListApisResponse()];

coerce 'RepeatedListApisResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::ListApisResponse'->new($_) } @$_ ] };

declare 'MapStringListApisResponse',
    as HashRef[ListApisResponse()];

declare 'CreateVersionRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::CreateVersionRequest'];

coerce 'CreateVersionRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::CreateVersionRequest'->new($_) };

declare 'RepeatedCreateVersionRequest',
    as ArrayRef[CreateVersionRequest()];

coerce 'RepeatedCreateVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::CreateVersionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateVersionRequest',
    as HashRef[CreateVersionRequest()];

declare 'GetVersionRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::GetVersionRequest'];

coerce 'GetVersionRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::GetVersionRequest'->new($_) };

declare 'RepeatedGetVersionRequest',
    as ArrayRef[GetVersionRequest()];

coerce 'RepeatedGetVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::GetVersionRequest'->new($_) } @$_ ] };

declare 'MapStringGetVersionRequest',
    as HashRef[GetVersionRequest()];

declare 'UpdateVersionRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::UpdateVersionRequest'];

coerce 'UpdateVersionRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::UpdateVersionRequest'->new($_) };

declare 'RepeatedUpdateVersionRequest',
    as ArrayRef[UpdateVersionRequest()];

coerce 'RepeatedUpdateVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::UpdateVersionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateVersionRequest',
    as HashRef[UpdateVersionRequest()];

declare 'DeleteVersionRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::DeleteVersionRequest'];

coerce 'DeleteVersionRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::DeleteVersionRequest'->new($_) };

declare 'RepeatedDeleteVersionRequest',
    as ArrayRef[DeleteVersionRequest()];

coerce 'RepeatedDeleteVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::DeleteVersionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteVersionRequest',
    as HashRef[DeleteVersionRequest()];

declare 'ListVersionsRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::ListVersionsRequest'];

coerce 'ListVersionsRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::ListVersionsRequest'->new($_) };

declare 'RepeatedListVersionsRequest',
    as ArrayRef[ListVersionsRequest()];

coerce 'RepeatedListVersionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::ListVersionsRequest'->new($_) } @$_ ] };

declare 'MapStringListVersionsRequest',
    as HashRef[ListVersionsRequest()];

declare 'ListVersionsResponse',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::ListVersionsResponse'];

coerce 'ListVersionsResponse',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::ListVersionsResponse'->new($_) };

declare 'RepeatedListVersionsResponse',
    as ArrayRef[ListVersionsResponse()];

coerce 'RepeatedListVersionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::ListVersionsResponse'->new($_) } @$_ ] };

declare 'MapStringListVersionsResponse',
    as HashRef[ListVersionsResponse()];

declare 'CreateSpecRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::CreateSpecRequest'];

coerce 'CreateSpecRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::CreateSpecRequest'->new($_) };

declare 'RepeatedCreateSpecRequest',
    as ArrayRef[CreateSpecRequest()];

coerce 'RepeatedCreateSpecRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::CreateSpecRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSpecRequest',
    as HashRef[CreateSpecRequest()];

declare 'GetSpecRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::GetSpecRequest'];

coerce 'GetSpecRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::GetSpecRequest'->new($_) };

declare 'RepeatedGetSpecRequest',
    as ArrayRef[GetSpecRequest()];

coerce 'RepeatedGetSpecRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::GetSpecRequest'->new($_) } @$_ ] };

declare 'MapStringGetSpecRequest',
    as HashRef[GetSpecRequest()];

declare 'UpdateSpecRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::UpdateSpecRequest'];

coerce 'UpdateSpecRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::UpdateSpecRequest'->new($_) };

declare 'RepeatedUpdateSpecRequest',
    as ArrayRef[UpdateSpecRequest()];

coerce 'RepeatedUpdateSpecRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::UpdateSpecRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSpecRequest',
    as HashRef[UpdateSpecRequest()];

declare 'DeleteSpecRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::DeleteSpecRequest'];

coerce 'DeleteSpecRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::DeleteSpecRequest'->new($_) };

declare 'RepeatedDeleteSpecRequest',
    as ArrayRef[DeleteSpecRequest()];

coerce 'RepeatedDeleteSpecRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::DeleteSpecRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSpecRequest',
    as HashRef[DeleteSpecRequest()];

declare 'ListSpecsRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::ListSpecsRequest'];

coerce 'ListSpecsRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::ListSpecsRequest'->new($_) };

declare 'RepeatedListSpecsRequest',
    as ArrayRef[ListSpecsRequest()];

coerce 'RepeatedListSpecsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::ListSpecsRequest'->new($_) } @$_ ] };

declare 'MapStringListSpecsRequest',
    as HashRef[ListSpecsRequest()];

declare 'ListSpecsResponse',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::ListSpecsResponse'];

coerce 'ListSpecsResponse',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::ListSpecsResponse'->new($_) };

declare 'RepeatedListSpecsResponse',
    as ArrayRef[ListSpecsResponse()];

coerce 'RepeatedListSpecsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::ListSpecsResponse'->new($_) } @$_ ] };

declare 'MapStringListSpecsResponse',
    as HashRef[ListSpecsResponse()];

declare 'GetSpecContentsRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::GetSpecContentsRequest'];

coerce 'GetSpecContentsRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::GetSpecContentsRequest'->new($_) };

declare 'RepeatedGetSpecContentsRequest',
    as ArrayRef[GetSpecContentsRequest()];

coerce 'RepeatedGetSpecContentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::GetSpecContentsRequest'->new($_) } @$_ ] };

declare 'MapStringGetSpecContentsRequest',
    as HashRef[GetSpecContentsRequest()];

declare 'CreateApiOperationRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::CreateApiOperationRequest'];

coerce 'CreateApiOperationRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::CreateApiOperationRequest'->new($_) };

declare 'RepeatedCreateApiOperationRequest',
    as ArrayRef[CreateApiOperationRequest()];

coerce 'RepeatedCreateApiOperationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::CreateApiOperationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateApiOperationRequest',
    as HashRef[CreateApiOperationRequest()];

declare 'GetApiOperationRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::GetApiOperationRequest'];

coerce 'GetApiOperationRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::GetApiOperationRequest'->new($_) };

declare 'RepeatedGetApiOperationRequest',
    as ArrayRef[GetApiOperationRequest()];

coerce 'RepeatedGetApiOperationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::GetApiOperationRequest'->new($_) } @$_ ] };

declare 'MapStringGetApiOperationRequest',
    as HashRef[GetApiOperationRequest()];

declare 'UpdateApiOperationRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::UpdateApiOperationRequest'];

coerce 'UpdateApiOperationRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::UpdateApiOperationRequest'->new($_) };

declare 'RepeatedUpdateApiOperationRequest',
    as ArrayRef[UpdateApiOperationRequest()];

coerce 'RepeatedUpdateApiOperationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::UpdateApiOperationRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateApiOperationRequest',
    as HashRef[UpdateApiOperationRequest()];

declare 'DeleteApiOperationRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::DeleteApiOperationRequest'];

coerce 'DeleteApiOperationRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::DeleteApiOperationRequest'->new($_) };

declare 'RepeatedDeleteApiOperationRequest',
    as ArrayRef[DeleteApiOperationRequest()];

coerce 'RepeatedDeleteApiOperationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::DeleteApiOperationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteApiOperationRequest',
    as HashRef[DeleteApiOperationRequest()];

declare 'ListApiOperationsRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::ListApiOperationsRequest'];

coerce 'ListApiOperationsRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::ListApiOperationsRequest'->new($_) };

declare 'RepeatedListApiOperationsRequest',
    as ArrayRef[ListApiOperationsRequest()];

coerce 'RepeatedListApiOperationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::ListApiOperationsRequest'->new($_) } @$_ ] };

declare 'MapStringListApiOperationsRequest',
    as HashRef[ListApiOperationsRequest()];

declare 'ListApiOperationsResponse',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::ListApiOperationsResponse'];

coerce 'ListApiOperationsResponse',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::ListApiOperationsResponse'->new($_) };

declare 'RepeatedListApiOperationsResponse',
    as ArrayRef[ListApiOperationsResponse()];

coerce 'RepeatedListApiOperationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::ListApiOperationsResponse'->new($_) } @$_ ] };

declare 'MapStringListApiOperationsResponse',
    as HashRef[ListApiOperationsResponse()];

declare 'GetDefinitionRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::GetDefinitionRequest'];

coerce 'GetDefinitionRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::GetDefinitionRequest'->new($_) };

declare 'RepeatedGetDefinitionRequest',
    as ArrayRef[GetDefinitionRequest()];

coerce 'RepeatedGetDefinitionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::GetDefinitionRequest'->new($_) } @$_ ] };

declare 'MapStringGetDefinitionRequest',
    as HashRef[GetDefinitionRequest()];

declare 'CreateDeploymentRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::CreateDeploymentRequest'];

coerce 'CreateDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::CreateDeploymentRequest'->new($_) };

declare 'RepeatedCreateDeploymentRequest',
    as ArrayRef[CreateDeploymentRequest()];

coerce 'RepeatedCreateDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::CreateDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDeploymentRequest',
    as HashRef[CreateDeploymentRequest()];

declare 'GetDeploymentRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::GetDeploymentRequest'];

coerce 'GetDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::GetDeploymentRequest'->new($_) };

declare 'RepeatedGetDeploymentRequest',
    as ArrayRef[GetDeploymentRequest()];

coerce 'RepeatedGetDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::GetDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringGetDeploymentRequest',
    as HashRef[GetDeploymentRequest()];

declare 'UpdateDeploymentRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::UpdateDeploymentRequest'];

coerce 'UpdateDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::UpdateDeploymentRequest'->new($_) };

declare 'RepeatedUpdateDeploymentRequest',
    as ArrayRef[UpdateDeploymentRequest()];

coerce 'RepeatedUpdateDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::UpdateDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDeploymentRequest',
    as HashRef[UpdateDeploymentRequest()];

declare 'DeleteDeploymentRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::DeleteDeploymentRequest'];

coerce 'DeleteDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::DeleteDeploymentRequest'->new($_) };

declare 'RepeatedDeleteDeploymentRequest',
    as ArrayRef[DeleteDeploymentRequest()];

coerce 'RepeatedDeleteDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::DeleteDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDeploymentRequest',
    as HashRef[DeleteDeploymentRequest()];

declare 'ListDeploymentsRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::ListDeploymentsRequest'];

coerce 'ListDeploymentsRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::ListDeploymentsRequest'->new($_) };

declare 'RepeatedListDeploymentsRequest',
    as ArrayRef[ListDeploymentsRequest()];

coerce 'RepeatedListDeploymentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::ListDeploymentsRequest'->new($_) } @$_ ] };

declare 'MapStringListDeploymentsRequest',
    as HashRef[ListDeploymentsRequest()];

declare 'ListDeploymentsResponse',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::ListDeploymentsResponse'];

coerce 'ListDeploymentsResponse',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::ListDeploymentsResponse'->new($_) };

declare 'RepeatedListDeploymentsResponse',
    as ArrayRef[ListDeploymentsResponse()];

coerce 'RepeatedListDeploymentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::ListDeploymentsResponse'->new($_) } @$_ ] };

declare 'MapStringListDeploymentsResponse',
    as HashRef[ListDeploymentsResponse()];

declare 'CreateAttributeRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::CreateAttributeRequest'];

coerce 'CreateAttributeRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::CreateAttributeRequest'->new($_) };

declare 'RepeatedCreateAttributeRequest',
    as ArrayRef[CreateAttributeRequest()];

coerce 'RepeatedCreateAttributeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::CreateAttributeRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAttributeRequest',
    as HashRef[CreateAttributeRequest()];

declare 'GetAttributeRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::GetAttributeRequest'];

coerce 'GetAttributeRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::GetAttributeRequest'->new($_) };

declare 'RepeatedGetAttributeRequest',
    as ArrayRef[GetAttributeRequest()];

coerce 'RepeatedGetAttributeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::GetAttributeRequest'->new($_) } @$_ ] };

declare 'MapStringGetAttributeRequest',
    as HashRef[GetAttributeRequest()];

declare 'UpdateAttributeRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::UpdateAttributeRequest'];

coerce 'UpdateAttributeRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::UpdateAttributeRequest'->new($_) };

declare 'RepeatedUpdateAttributeRequest',
    as ArrayRef[UpdateAttributeRequest()];

coerce 'RepeatedUpdateAttributeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::UpdateAttributeRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAttributeRequest',
    as HashRef[UpdateAttributeRequest()];

declare 'DeleteAttributeRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::DeleteAttributeRequest'];

coerce 'DeleteAttributeRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::DeleteAttributeRequest'->new($_) };

declare 'RepeatedDeleteAttributeRequest',
    as ArrayRef[DeleteAttributeRequest()];

coerce 'RepeatedDeleteAttributeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::DeleteAttributeRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAttributeRequest',
    as HashRef[DeleteAttributeRequest()];

declare 'ListAttributesRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::ListAttributesRequest'];

coerce 'ListAttributesRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::ListAttributesRequest'->new($_) };

declare 'RepeatedListAttributesRequest',
    as ArrayRef[ListAttributesRequest()];

coerce 'RepeatedListAttributesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::ListAttributesRequest'->new($_) } @$_ ] };

declare 'MapStringListAttributesRequest',
    as HashRef[ListAttributesRequest()];

declare 'ListAttributesResponse',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::ListAttributesResponse'];

coerce 'ListAttributesResponse',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::ListAttributesResponse'->new($_) };

declare 'RepeatedListAttributesResponse',
    as ArrayRef[ListAttributesResponse()];

coerce 'RepeatedListAttributesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::ListAttributesResponse'->new($_) } @$_ ] };

declare 'MapStringListAttributesResponse',
    as HashRef[ListAttributesResponse()];

declare 'SearchResourcesRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::SearchResourcesRequest'];

coerce 'SearchResourcesRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::SearchResourcesRequest'->new($_) };

declare 'RepeatedSearchResourcesRequest',
    as ArrayRef[SearchResourcesRequest()];

coerce 'RepeatedSearchResourcesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::SearchResourcesRequest'->new($_) } @$_ ] };

declare 'MapStringSearchResourcesRequest',
    as HashRef[SearchResourcesRequest()];

declare 'ApiHubResource',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::ApiHubResource'];

coerce 'ApiHubResource',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::ApiHubResource'->new($_) };

declare 'RepeatedApiHubResource',
    as ArrayRef[ApiHubResource()];

coerce 'RepeatedApiHubResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::ApiHubResource'->new($_) } @$_ ] };

declare 'MapStringApiHubResource',
    as HashRef[ApiHubResource()];

declare 'SearchResult',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::SearchResult'];

coerce 'SearchResult',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::SearchResult'->new($_) };

declare 'RepeatedSearchResult',
    as ArrayRef[SearchResult()];

coerce 'RepeatedSearchResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::SearchResult'->new($_) } @$_ ] };

declare 'MapStringSearchResult',
    as HashRef[SearchResult()];

declare 'SearchResourcesResponse',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::SearchResourcesResponse'];

coerce 'SearchResourcesResponse',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::SearchResourcesResponse'->new($_) };

declare 'RepeatedSearchResourcesResponse',
    as ArrayRef[SearchResourcesResponse()];

coerce 'RepeatedSearchResourcesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::SearchResourcesResponse'->new($_) } @$_ ] };

declare 'MapStringSearchResourcesResponse',
    as HashRef[SearchResourcesResponse()];

declare 'CreateDependencyRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::CreateDependencyRequest'];

coerce 'CreateDependencyRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::CreateDependencyRequest'->new($_) };

declare 'RepeatedCreateDependencyRequest',
    as ArrayRef[CreateDependencyRequest()];

coerce 'RepeatedCreateDependencyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::CreateDependencyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDependencyRequest',
    as HashRef[CreateDependencyRequest()];

declare 'GetDependencyRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::GetDependencyRequest'];

coerce 'GetDependencyRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::GetDependencyRequest'->new($_) };

declare 'RepeatedGetDependencyRequest',
    as ArrayRef[GetDependencyRequest()];

coerce 'RepeatedGetDependencyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::GetDependencyRequest'->new($_) } @$_ ] };

declare 'MapStringGetDependencyRequest',
    as HashRef[GetDependencyRequest()];

declare 'UpdateDependencyRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::UpdateDependencyRequest'];

coerce 'UpdateDependencyRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::UpdateDependencyRequest'->new($_) };

declare 'RepeatedUpdateDependencyRequest',
    as ArrayRef[UpdateDependencyRequest()];

coerce 'RepeatedUpdateDependencyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::UpdateDependencyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDependencyRequest',
    as HashRef[UpdateDependencyRequest()];

declare 'DeleteDependencyRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::DeleteDependencyRequest'];

coerce 'DeleteDependencyRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::DeleteDependencyRequest'->new($_) };

declare 'RepeatedDeleteDependencyRequest',
    as ArrayRef[DeleteDependencyRequest()];

coerce 'RepeatedDeleteDependencyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::DeleteDependencyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDependencyRequest',
    as HashRef[DeleteDependencyRequest()];

declare 'ListDependenciesRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::ListDependenciesRequest'];

coerce 'ListDependenciesRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::ListDependenciesRequest'->new($_) };

declare 'RepeatedListDependenciesRequest',
    as ArrayRef[ListDependenciesRequest()];

coerce 'RepeatedListDependenciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::ListDependenciesRequest'->new($_) } @$_ ] };

declare 'MapStringListDependenciesRequest',
    as HashRef[ListDependenciesRequest()];

declare 'ListDependenciesResponse',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::ListDependenciesResponse'];

coerce 'ListDependenciesResponse',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::ListDependenciesResponse'->new($_) };

declare 'RepeatedListDependenciesResponse',
    as ArrayRef[ListDependenciesResponse()];

coerce 'RepeatedListDependenciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::ListDependenciesResponse'->new($_) } @$_ ] };

declare 'MapStringListDependenciesResponse',
    as HashRef[ListDependenciesResponse()];

declare 'CreateExternalApiRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::CreateExternalApiRequest'];

coerce 'CreateExternalApiRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::CreateExternalApiRequest'->new($_) };

declare 'RepeatedCreateExternalApiRequest',
    as ArrayRef[CreateExternalApiRequest()];

coerce 'RepeatedCreateExternalApiRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::CreateExternalApiRequest'->new($_) } @$_ ] };

declare 'MapStringCreateExternalApiRequest',
    as HashRef[CreateExternalApiRequest()];

declare 'GetExternalApiRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::GetExternalApiRequest'];

coerce 'GetExternalApiRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::GetExternalApiRequest'->new($_) };

declare 'RepeatedGetExternalApiRequest',
    as ArrayRef[GetExternalApiRequest()];

coerce 'RepeatedGetExternalApiRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::GetExternalApiRequest'->new($_) } @$_ ] };

declare 'MapStringGetExternalApiRequest',
    as HashRef[GetExternalApiRequest()];

declare 'UpdateExternalApiRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::UpdateExternalApiRequest'];

coerce 'UpdateExternalApiRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::UpdateExternalApiRequest'->new($_) };

declare 'RepeatedUpdateExternalApiRequest',
    as ArrayRef[UpdateExternalApiRequest()];

coerce 'RepeatedUpdateExternalApiRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::UpdateExternalApiRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateExternalApiRequest',
    as HashRef[UpdateExternalApiRequest()];

declare 'DeleteExternalApiRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::DeleteExternalApiRequest'];

coerce 'DeleteExternalApiRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::DeleteExternalApiRequest'->new($_) };

declare 'RepeatedDeleteExternalApiRequest',
    as ArrayRef[DeleteExternalApiRequest()];

coerce 'RepeatedDeleteExternalApiRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::DeleteExternalApiRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteExternalApiRequest',
    as HashRef[DeleteExternalApiRequest()];

declare 'ListExternalApisRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::ListExternalApisRequest'];

coerce 'ListExternalApisRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::ListExternalApisRequest'->new($_) };

declare 'RepeatedListExternalApisRequest',
    as ArrayRef[ListExternalApisRequest()];

coerce 'RepeatedListExternalApisRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::ListExternalApisRequest'->new($_) } @$_ ] };

declare 'MapStringListExternalApisRequest',
    as HashRef[ListExternalApisRequest()];

declare 'ListExternalApisResponse',
    as InstanceOf['Google::Cloud::Apihub::V1::ApihubService::ListExternalApisResponse'];

coerce 'ListExternalApisResponse',
    from HashRef, via { 'Google::Cloud::Apihub::V1::ApihubService::ListExternalApisResponse'->new($_) };

declare 'RepeatedListExternalApisResponse',
    as ArrayRef[ListExternalApisResponse()];

coerce 'RepeatedListExternalApisResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::ApihubService::ListExternalApisResponse'->new($_) } @$_ ] };

declare 'MapStringListExternalApisResponse',
    as HashRef[ListExternalApisResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Apihub::V1::ApihubService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
