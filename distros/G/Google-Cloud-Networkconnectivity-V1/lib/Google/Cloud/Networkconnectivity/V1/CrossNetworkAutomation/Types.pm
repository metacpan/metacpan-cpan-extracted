package Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Infrastructure',
    as (Int | Str);

declare 'ConnectionErrorType',
    as (Int | Str);

declare 'IPVersion',
    as (Int | Str);

declare 'ServiceConnectionMap',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionMap'];

coerce 'ServiceConnectionMap',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionMap'->new($_) };

declare 'RepeatedServiceConnectionMap',
    as ArrayRef[ServiceConnectionMap()];

coerce 'RepeatedServiceConnectionMap',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionMap'->new($_) } @$_ ] };

declare 'MapStringServiceConnectionMap',
    as HashRef[ServiceConnectionMap()];

declare 'ProducerPscConfig',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionMap::ProducerPscConfig'];

coerce 'ProducerPscConfig',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionMap::ProducerPscConfig'->new($_) };

declare 'RepeatedProducerPscConfig',
    as ArrayRef[ProducerPscConfig()];

coerce 'RepeatedProducerPscConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionMap::ProducerPscConfig'->new($_) } @$_ ] };

declare 'MapStringProducerPscConfig',
    as HashRef[ProducerPscConfig()];

declare 'ConsumerPscConfig',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionMap::ConsumerPscConfig'];

coerce 'ConsumerPscConfig',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionMap::ConsumerPscConfig'->new($_) };

declare 'RepeatedConsumerPscConfig',
    as ArrayRef[ConsumerPscConfig()];

coerce 'RepeatedConsumerPscConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionMap::ConsumerPscConfig'->new($_) } @$_ ] };

declare 'MapStringConsumerPscConfig',
    as HashRef[ConsumerPscConfig()];

declare 'State',
    as (Int | Str);

declare 'ServiceAttachmentIpAddressMapEntry',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionMap::ConsumerPscConfig::ServiceAttachmentIpAddressMapEntry'];

coerce 'ServiceAttachmentIpAddressMapEntry',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionMap::ConsumerPscConfig::ServiceAttachmentIpAddressMapEntry'->new($_) };

declare 'RepeatedServiceAttachmentIpAddressMapEntry',
    as ArrayRef[ServiceAttachmentIpAddressMapEntry()];

coerce 'RepeatedServiceAttachmentIpAddressMapEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionMap::ConsumerPscConfig::ServiceAttachmentIpAddressMapEntry'->new($_) } @$_ ] };

declare 'MapStringServiceAttachmentIpAddressMapEntry',
    as HashRef[ServiceAttachmentIpAddressMapEntry()];

declare 'ProducerInstanceMetadataEntry',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionMap::ConsumerPscConfig::ProducerInstanceMetadataEntry'];

coerce 'ProducerInstanceMetadataEntry',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionMap::ConsumerPscConfig::ProducerInstanceMetadataEntry'->new($_) };

declare 'RepeatedProducerInstanceMetadataEntry',
    as ArrayRef[ProducerInstanceMetadataEntry()];

coerce 'RepeatedProducerInstanceMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionMap::ConsumerPscConfig::ProducerInstanceMetadataEntry'->new($_) } @$_ ] };

declare 'MapStringProducerInstanceMetadataEntry',
    as HashRef[ProducerInstanceMetadataEntry()];

declare 'ConsumerPscConnection',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionMap::ConsumerPscConnection'];

coerce 'ConsumerPscConnection',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionMap::ConsumerPscConnection'->new($_) };

declare 'RepeatedConsumerPscConnection',
    as ArrayRef[ConsumerPscConnection()];

coerce 'RepeatedConsumerPscConnection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionMap::ConsumerPscConnection'->new($_) } @$_ ] };

declare 'MapStringConsumerPscConnection',
    as HashRef[ConsumerPscConnection()];

declare 'State',
    as (Int | Str);

declare 'ProducerInstanceMetadataEntry',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionMap::ConsumerPscConnection::ProducerInstanceMetadataEntry'];

coerce 'ProducerInstanceMetadataEntry',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionMap::ConsumerPscConnection::ProducerInstanceMetadataEntry'->new($_) };

declare 'RepeatedProducerInstanceMetadataEntry',
    as ArrayRef[ProducerInstanceMetadataEntry()];

coerce 'RepeatedProducerInstanceMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionMap::ConsumerPscConnection::ProducerInstanceMetadataEntry'->new($_) } @$_ ] };

declare 'MapStringProducerInstanceMetadataEntry',
    as HashRef[ProducerInstanceMetadataEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionMap::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionMap::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionMap::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListServiceConnectionMapsRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ListServiceConnectionMapsRequest'];

coerce 'ListServiceConnectionMapsRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ListServiceConnectionMapsRequest'->new($_) };

declare 'RepeatedListServiceConnectionMapsRequest',
    as ArrayRef[ListServiceConnectionMapsRequest()];

coerce 'RepeatedListServiceConnectionMapsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ListServiceConnectionMapsRequest'->new($_) } @$_ ] };

declare 'MapStringListServiceConnectionMapsRequest',
    as HashRef[ListServiceConnectionMapsRequest()];

declare 'ListServiceConnectionMapsResponse',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ListServiceConnectionMapsResponse'];

coerce 'ListServiceConnectionMapsResponse',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ListServiceConnectionMapsResponse'->new($_) };

declare 'RepeatedListServiceConnectionMapsResponse',
    as ArrayRef[ListServiceConnectionMapsResponse()];

coerce 'RepeatedListServiceConnectionMapsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ListServiceConnectionMapsResponse'->new($_) } @$_ ] };

declare 'MapStringListServiceConnectionMapsResponse',
    as HashRef[ListServiceConnectionMapsResponse()];

declare 'GetServiceConnectionMapRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::GetServiceConnectionMapRequest'];

coerce 'GetServiceConnectionMapRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::GetServiceConnectionMapRequest'->new($_) };

declare 'RepeatedGetServiceConnectionMapRequest',
    as ArrayRef[GetServiceConnectionMapRequest()];

coerce 'RepeatedGetServiceConnectionMapRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::GetServiceConnectionMapRequest'->new($_) } @$_ ] };

declare 'MapStringGetServiceConnectionMapRequest',
    as HashRef[GetServiceConnectionMapRequest()];

declare 'CreateServiceConnectionMapRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::CreateServiceConnectionMapRequest'];

coerce 'CreateServiceConnectionMapRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::CreateServiceConnectionMapRequest'->new($_) };

declare 'RepeatedCreateServiceConnectionMapRequest',
    as ArrayRef[CreateServiceConnectionMapRequest()];

coerce 'RepeatedCreateServiceConnectionMapRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::CreateServiceConnectionMapRequest'->new($_) } @$_ ] };

declare 'MapStringCreateServiceConnectionMapRequest',
    as HashRef[CreateServiceConnectionMapRequest()];

declare 'UpdateServiceConnectionMapRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::UpdateServiceConnectionMapRequest'];

coerce 'UpdateServiceConnectionMapRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::UpdateServiceConnectionMapRequest'->new($_) };

declare 'RepeatedUpdateServiceConnectionMapRequest',
    as ArrayRef[UpdateServiceConnectionMapRequest()];

coerce 'RepeatedUpdateServiceConnectionMapRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::UpdateServiceConnectionMapRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateServiceConnectionMapRequest',
    as HashRef[UpdateServiceConnectionMapRequest()];

declare 'DeleteServiceConnectionMapRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::DeleteServiceConnectionMapRequest'];

coerce 'DeleteServiceConnectionMapRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::DeleteServiceConnectionMapRequest'->new($_) };

declare 'RepeatedDeleteServiceConnectionMapRequest',
    as ArrayRef[DeleteServiceConnectionMapRequest()];

coerce 'RepeatedDeleteServiceConnectionMapRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::DeleteServiceConnectionMapRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteServiceConnectionMapRequest',
    as HashRef[DeleteServiceConnectionMapRequest()];

declare 'ServiceConnectionPolicy',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionPolicy'];

coerce 'ServiceConnectionPolicy',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionPolicy'->new($_) };

declare 'RepeatedServiceConnectionPolicy',
    as ArrayRef[ServiceConnectionPolicy()];

coerce 'RepeatedServiceConnectionPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionPolicy'->new($_) } @$_ ] };

declare 'MapStringServiceConnectionPolicy',
    as HashRef[ServiceConnectionPolicy()];

declare 'State',
    as (Int | Str);

declare 'PscConfig',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionPolicy::PscConfig'];

coerce 'PscConfig',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionPolicy::PscConfig'->new($_) };

declare 'RepeatedPscConfig',
    as ArrayRef[PscConfig()];

coerce 'RepeatedPscConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionPolicy::PscConfig'->new($_) } @$_ ] };

declare 'MapStringPscConfig',
    as HashRef[PscConfig()];

declare 'ProducerInstanceLocation',
    as (Int | Str);

declare 'PscConnection',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionPolicy::PscConnection'];

coerce 'PscConnection',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionPolicy::PscConnection'->new($_) };

declare 'RepeatedPscConnection',
    as ArrayRef[PscConnection()];

coerce 'RepeatedPscConnection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionPolicy::PscConnection'->new($_) } @$_ ] };

declare 'MapStringPscConnection',
    as HashRef[PscConnection()];

declare 'ProducerInstanceMetadataEntry',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionPolicy::PscConnection::ProducerInstanceMetadataEntry'];

coerce 'ProducerInstanceMetadataEntry',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionPolicy::PscConnection::ProducerInstanceMetadataEntry'->new($_) };

declare 'RepeatedProducerInstanceMetadataEntry',
    as ArrayRef[ProducerInstanceMetadataEntry()];

coerce 'RepeatedProducerInstanceMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionPolicy::PscConnection::ProducerInstanceMetadataEntry'->new($_) } @$_ ] };

declare 'MapStringProducerInstanceMetadataEntry',
    as HashRef[ProducerInstanceMetadataEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionPolicy::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionPolicy::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionPolicy::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListServiceConnectionPoliciesRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ListServiceConnectionPoliciesRequest'];

coerce 'ListServiceConnectionPoliciesRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ListServiceConnectionPoliciesRequest'->new($_) };

declare 'RepeatedListServiceConnectionPoliciesRequest',
    as ArrayRef[ListServiceConnectionPoliciesRequest()];

coerce 'RepeatedListServiceConnectionPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ListServiceConnectionPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringListServiceConnectionPoliciesRequest',
    as HashRef[ListServiceConnectionPoliciesRequest()];

declare 'ListServiceConnectionPoliciesResponse',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ListServiceConnectionPoliciesResponse'];

coerce 'ListServiceConnectionPoliciesResponse',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ListServiceConnectionPoliciesResponse'->new($_) };

declare 'RepeatedListServiceConnectionPoliciesResponse',
    as ArrayRef[ListServiceConnectionPoliciesResponse()];

coerce 'RepeatedListServiceConnectionPoliciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ListServiceConnectionPoliciesResponse'->new($_) } @$_ ] };

declare 'MapStringListServiceConnectionPoliciesResponse',
    as HashRef[ListServiceConnectionPoliciesResponse()];

declare 'GetServiceConnectionPolicyRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::GetServiceConnectionPolicyRequest'];

coerce 'GetServiceConnectionPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::GetServiceConnectionPolicyRequest'->new($_) };

declare 'RepeatedGetServiceConnectionPolicyRequest',
    as ArrayRef[GetServiceConnectionPolicyRequest()];

coerce 'RepeatedGetServiceConnectionPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::GetServiceConnectionPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetServiceConnectionPolicyRequest',
    as HashRef[GetServiceConnectionPolicyRequest()];

declare 'CreateServiceConnectionPolicyRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::CreateServiceConnectionPolicyRequest'];

coerce 'CreateServiceConnectionPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::CreateServiceConnectionPolicyRequest'->new($_) };

declare 'RepeatedCreateServiceConnectionPolicyRequest',
    as ArrayRef[CreateServiceConnectionPolicyRequest()];

coerce 'RepeatedCreateServiceConnectionPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::CreateServiceConnectionPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateServiceConnectionPolicyRequest',
    as HashRef[CreateServiceConnectionPolicyRequest()];

declare 'UpdateServiceConnectionPolicyRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::UpdateServiceConnectionPolicyRequest'];

coerce 'UpdateServiceConnectionPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::UpdateServiceConnectionPolicyRequest'->new($_) };

declare 'RepeatedUpdateServiceConnectionPolicyRequest',
    as ArrayRef[UpdateServiceConnectionPolicyRequest()];

coerce 'RepeatedUpdateServiceConnectionPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::UpdateServiceConnectionPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateServiceConnectionPolicyRequest',
    as HashRef[UpdateServiceConnectionPolicyRequest()];

declare 'DeleteServiceConnectionPolicyRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::DeleteServiceConnectionPolicyRequest'];

coerce 'DeleteServiceConnectionPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::DeleteServiceConnectionPolicyRequest'->new($_) };

declare 'RepeatedDeleteServiceConnectionPolicyRequest',
    as ArrayRef[DeleteServiceConnectionPolicyRequest()];

coerce 'RepeatedDeleteServiceConnectionPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::DeleteServiceConnectionPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteServiceConnectionPolicyRequest',
    as HashRef[DeleteServiceConnectionPolicyRequest()];

declare 'ServiceClass',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceClass'];

coerce 'ServiceClass',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceClass'->new($_) };

declare 'RepeatedServiceClass',
    as ArrayRef[ServiceClass()];

coerce 'RepeatedServiceClass',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceClass'->new($_) } @$_ ] };

declare 'MapStringServiceClass',
    as HashRef[ServiceClass()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceClass::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceClass::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceClass::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListServiceClassesRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ListServiceClassesRequest'];

coerce 'ListServiceClassesRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ListServiceClassesRequest'->new($_) };

declare 'RepeatedListServiceClassesRequest',
    as ArrayRef[ListServiceClassesRequest()];

coerce 'RepeatedListServiceClassesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ListServiceClassesRequest'->new($_) } @$_ ] };

declare 'MapStringListServiceClassesRequest',
    as HashRef[ListServiceClassesRequest()];

declare 'ListServiceClassesResponse',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ListServiceClassesResponse'];

coerce 'ListServiceClassesResponse',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ListServiceClassesResponse'->new($_) };

declare 'RepeatedListServiceClassesResponse',
    as ArrayRef[ListServiceClassesResponse()];

coerce 'RepeatedListServiceClassesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ListServiceClassesResponse'->new($_) } @$_ ] };

declare 'MapStringListServiceClassesResponse',
    as HashRef[ListServiceClassesResponse()];

declare 'GetServiceClassRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::GetServiceClassRequest'];

coerce 'GetServiceClassRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::GetServiceClassRequest'->new($_) };

declare 'RepeatedGetServiceClassRequest',
    as ArrayRef[GetServiceClassRequest()];

coerce 'RepeatedGetServiceClassRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::GetServiceClassRequest'->new($_) } @$_ ] };

declare 'MapStringGetServiceClassRequest',
    as HashRef[GetServiceClassRequest()];

declare 'UpdateServiceClassRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::UpdateServiceClassRequest'];

coerce 'UpdateServiceClassRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::UpdateServiceClassRequest'->new($_) };

declare 'RepeatedUpdateServiceClassRequest',
    as ArrayRef[UpdateServiceClassRequest()];

coerce 'RepeatedUpdateServiceClassRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::UpdateServiceClassRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateServiceClassRequest',
    as HashRef[UpdateServiceClassRequest()];

declare 'DeleteServiceClassRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::DeleteServiceClassRequest'];

coerce 'DeleteServiceClassRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::DeleteServiceClassRequest'->new($_) };

declare 'RepeatedDeleteServiceClassRequest',
    as ArrayRef[DeleteServiceClassRequest()];

coerce 'RepeatedDeleteServiceClassRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::DeleteServiceClassRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteServiceClassRequest',
    as HashRef[DeleteServiceClassRequest()];

declare 'ServiceConnectionToken',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionToken'];

coerce 'ServiceConnectionToken',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionToken'->new($_) };

declare 'RepeatedServiceConnectionToken',
    as ArrayRef[ServiceConnectionToken()];

coerce 'RepeatedServiceConnectionToken',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionToken'->new($_) } @$_ ] };

declare 'MapStringServiceConnectionToken',
    as HashRef[ServiceConnectionToken()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionToken::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionToken::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ServiceConnectionToken::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListServiceConnectionTokensRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ListServiceConnectionTokensRequest'];

coerce 'ListServiceConnectionTokensRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ListServiceConnectionTokensRequest'->new($_) };

declare 'RepeatedListServiceConnectionTokensRequest',
    as ArrayRef[ListServiceConnectionTokensRequest()];

coerce 'RepeatedListServiceConnectionTokensRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ListServiceConnectionTokensRequest'->new($_) } @$_ ] };

declare 'MapStringListServiceConnectionTokensRequest',
    as HashRef[ListServiceConnectionTokensRequest()];

declare 'ListServiceConnectionTokensResponse',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ListServiceConnectionTokensResponse'];

coerce 'ListServiceConnectionTokensResponse',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ListServiceConnectionTokensResponse'->new($_) };

declare 'RepeatedListServiceConnectionTokensResponse',
    as ArrayRef[ListServiceConnectionTokensResponse()];

coerce 'RepeatedListServiceConnectionTokensResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::ListServiceConnectionTokensResponse'->new($_) } @$_ ] };

declare 'MapStringListServiceConnectionTokensResponse',
    as HashRef[ListServiceConnectionTokensResponse()];

declare 'GetServiceConnectionTokenRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::GetServiceConnectionTokenRequest'];

coerce 'GetServiceConnectionTokenRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::GetServiceConnectionTokenRequest'->new($_) };

declare 'RepeatedGetServiceConnectionTokenRequest',
    as ArrayRef[GetServiceConnectionTokenRequest()];

coerce 'RepeatedGetServiceConnectionTokenRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::GetServiceConnectionTokenRequest'->new($_) } @$_ ] };

declare 'MapStringGetServiceConnectionTokenRequest',
    as HashRef[GetServiceConnectionTokenRequest()];

declare 'CreateServiceConnectionTokenRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::CreateServiceConnectionTokenRequest'];

coerce 'CreateServiceConnectionTokenRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::CreateServiceConnectionTokenRequest'->new($_) };

declare 'RepeatedCreateServiceConnectionTokenRequest',
    as ArrayRef[CreateServiceConnectionTokenRequest()];

coerce 'RepeatedCreateServiceConnectionTokenRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::CreateServiceConnectionTokenRequest'->new($_) } @$_ ] };

declare 'MapStringCreateServiceConnectionTokenRequest',
    as HashRef[CreateServiceConnectionTokenRequest()];

declare 'DeleteServiceConnectionTokenRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::DeleteServiceConnectionTokenRequest'];

coerce 'DeleteServiceConnectionTokenRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::DeleteServiceConnectionTokenRequest'->new($_) };

declare 'RepeatedDeleteServiceConnectionTokenRequest',
    as ArrayRef[DeleteServiceConnectionTokenRequest()];

coerce 'RepeatedDeleteServiceConnectionTokenRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::DeleteServiceConnectionTokenRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteServiceConnectionTokenRequest',
    as HashRef[DeleteServiceConnectionTokenRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Networkconnectivity::V1::CrossNetworkAutomation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
