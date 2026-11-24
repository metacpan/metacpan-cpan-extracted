package Google::Cloud::Numberregistry::V1alpha::Core::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'IpVersion',
    as (Int | Str);

declare 'RegistryBookView',
    as (Int | Str);

declare 'IpamAdminScope',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::IpamAdminScope'];

coerce 'IpamAdminScope',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::IpamAdminScope'->new($_) };

declare 'RepeatedIpamAdminScope',
    as ArrayRef[IpamAdminScope()];

coerce 'RepeatedIpamAdminScope',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::IpamAdminScope'->new($_) } @$_ ] };

declare 'MapStringIpamAdminScope',
    as HashRef[IpamAdminScope()];

declare 'AddOnPlatform',
    as (Int | Str);

declare 'DiscoveryPipelineState',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::IpamAdminScope::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::IpamAdminScope::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::IpamAdminScope::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListIpamAdminScopesRequest',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::ListIpamAdminScopesRequest'];

coerce 'ListIpamAdminScopesRequest',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::ListIpamAdminScopesRequest'->new($_) };

declare 'RepeatedListIpamAdminScopesRequest',
    as ArrayRef[ListIpamAdminScopesRequest()];

coerce 'RepeatedListIpamAdminScopesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::ListIpamAdminScopesRequest'->new($_) } @$_ ] };

declare 'MapStringListIpamAdminScopesRequest',
    as HashRef[ListIpamAdminScopesRequest()];

declare 'ListIpamAdminScopesResponse',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::ListIpamAdminScopesResponse'];

coerce 'ListIpamAdminScopesResponse',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::ListIpamAdminScopesResponse'->new($_) };

declare 'RepeatedListIpamAdminScopesResponse',
    as ArrayRef[ListIpamAdminScopesResponse()];

coerce 'RepeatedListIpamAdminScopesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::ListIpamAdminScopesResponse'->new($_) } @$_ ] };

declare 'MapStringListIpamAdminScopesResponse',
    as HashRef[ListIpamAdminScopesResponse()];

declare 'GetIpamAdminScopeRequest',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::GetIpamAdminScopeRequest'];

coerce 'GetIpamAdminScopeRequest',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::GetIpamAdminScopeRequest'->new($_) };

declare 'RepeatedGetIpamAdminScopeRequest',
    as ArrayRef[GetIpamAdminScopeRequest()];

coerce 'RepeatedGetIpamAdminScopeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::GetIpamAdminScopeRequest'->new($_) } @$_ ] };

declare 'MapStringGetIpamAdminScopeRequest',
    as HashRef[GetIpamAdminScopeRequest()];

declare 'CheckAvailabilityIpamAdminScopesRequest',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::CheckAvailabilityIpamAdminScopesRequest'];

coerce 'CheckAvailabilityIpamAdminScopesRequest',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::CheckAvailabilityIpamAdminScopesRequest'->new($_) };

declare 'RepeatedCheckAvailabilityIpamAdminScopesRequest',
    as ArrayRef[CheckAvailabilityIpamAdminScopesRequest()];

coerce 'RepeatedCheckAvailabilityIpamAdminScopesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::CheckAvailabilityIpamAdminScopesRequest'->new($_) } @$_ ] };

declare 'MapStringCheckAvailabilityIpamAdminScopesRequest',
    as HashRef[CheckAvailabilityIpamAdminScopesRequest()];

declare 'CheckAvailabilityIpamAdminScopesResponse',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::CheckAvailabilityIpamAdminScopesResponse'];

coerce 'CheckAvailabilityIpamAdminScopesResponse',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::CheckAvailabilityIpamAdminScopesResponse'->new($_) };

declare 'RepeatedCheckAvailabilityIpamAdminScopesResponse',
    as ArrayRef[CheckAvailabilityIpamAdminScopesResponse()];

coerce 'RepeatedCheckAvailabilityIpamAdminScopesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::CheckAvailabilityIpamAdminScopesResponse'->new($_) } @$_ ] };

declare 'MapStringCheckAvailabilityIpamAdminScopesResponse',
    as HashRef[CheckAvailabilityIpamAdminScopesResponse()];

declare 'IpamAdminScopeAvailability',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::IpamAdminScopeAvailability'];

coerce 'IpamAdminScopeAvailability',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::IpamAdminScopeAvailability'->new($_) };

declare 'RepeatedIpamAdminScopeAvailability',
    as ArrayRef[IpamAdminScopeAvailability()];

coerce 'RepeatedIpamAdminScopeAvailability',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::IpamAdminScopeAvailability'->new($_) } @$_ ] };

declare 'MapStringIpamAdminScopeAvailability',
    as HashRef[IpamAdminScopeAvailability()];

declare 'Availability',
    as (Int | Str);

declare 'CreateIpamAdminScopeRequest',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::CreateIpamAdminScopeRequest'];

coerce 'CreateIpamAdminScopeRequest',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::CreateIpamAdminScopeRequest'->new($_) };

declare 'RepeatedCreateIpamAdminScopeRequest',
    as ArrayRef[CreateIpamAdminScopeRequest()];

coerce 'RepeatedCreateIpamAdminScopeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::CreateIpamAdminScopeRequest'->new($_) } @$_ ] };

declare 'MapStringCreateIpamAdminScopeRequest',
    as HashRef[CreateIpamAdminScopeRequest()];

declare 'DisableIpamAdminScopeRequest',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::DisableIpamAdminScopeRequest'];

coerce 'DisableIpamAdminScopeRequest',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::DisableIpamAdminScopeRequest'->new($_) };

declare 'RepeatedDisableIpamAdminScopeRequest',
    as ArrayRef[DisableIpamAdminScopeRequest()];

coerce 'RepeatedDisableIpamAdminScopeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::DisableIpamAdminScopeRequest'->new($_) } @$_ ] };

declare 'MapStringDisableIpamAdminScopeRequest',
    as HashRef[DisableIpamAdminScopeRequest()];

declare 'CleanupIpamAdminScopeRequest',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::CleanupIpamAdminScopeRequest'];

coerce 'CleanupIpamAdminScopeRequest',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::CleanupIpamAdminScopeRequest'->new($_) };

declare 'RepeatedCleanupIpamAdminScopeRequest',
    as ArrayRef[CleanupIpamAdminScopeRequest()];

coerce 'RepeatedCleanupIpamAdminScopeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::CleanupIpamAdminScopeRequest'->new($_) } @$_ ] };

declare 'MapStringCleanupIpamAdminScopeRequest',
    as HashRef[CleanupIpamAdminScopeRequest()];

declare 'UpdateIpamAdminScopeRequest',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::UpdateIpamAdminScopeRequest'];

coerce 'UpdateIpamAdminScopeRequest',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::UpdateIpamAdminScopeRequest'->new($_) };

declare 'RepeatedUpdateIpamAdminScopeRequest',
    as ArrayRef[UpdateIpamAdminScopeRequest()];

coerce 'RepeatedUpdateIpamAdminScopeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::UpdateIpamAdminScopeRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateIpamAdminScopeRequest',
    as HashRef[UpdateIpamAdminScopeRequest()];

declare 'DeleteIpamAdminScopeRequest',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::DeleteIpamAdminScopeRequest'];

coerce 'DeleteIpamAdminScopeRequest',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::DeleteIpamAdminScopeRequest'->new($_) };

declare 'RepeatedDeleteIpamAdminScopeRequest',
    as ArrayRef[DeleteIpamAdminScopeRequest()];

coerce 'RepeatedDeleteIpamAdminScopeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::DeleteIpamAdminScopeRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteIpamAdminScopeRequest',
    as HashRef[DeleteIpamAdminScopeRequest()];

declare 'RegistryBook',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::RegistryBook'];

coerce 'RegistryBook',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::RegistryBook'->new($_) };

declare 'RepeatedRegistryBook',
    as ArrayRef[RegistryBook()];

coerce 'RepeatedRegistryBook',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::RegistryBook'->new($_) } @$_ ] };

declare 'MapStringRegistryBook',
    as HashRef[RegistryBook()];

declare 'AggregatedData',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::RegistryBook::AggregatedData'];

coerce 'AggregatedData',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::RegistryBook::AggregatedData'->new($_) };

declare 'RepeatedAggregatedData',
    as ArrayRef[AggregatedData()];

coerce 'RepeatedAggregatedData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::RegistryBook::AggregatedData'->new($_) } @$_ ] };

declare 'MapStringAggregatedData',
    as HashRef[AggregatedData()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::RegistryBook::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::RegistryBook::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::RegistryBook::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListRegistryBooksRequest',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::ListRegistryBooksRequest'];

coerce 'ListRegistryBooksRequest',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::ListRegistryBooksRequest'->new($_) };

declare 'RepeatedListRegistryBooksRequest',
    as ArrayRef[ListRegistryBooksRequest()];

coerce 'RepeatedListRegistryBooksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::ListRegistryBooksRequest'->new($_) } @$_ ] };

declare 'MapStringListRegistryBooksRequest',
    as HashRef[ListRegistryBooksRequest()];

declare 'ListRegistryBooksResponse',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::ListRegistryBooksResponse'];

coerce 'ListRegistryBooksResponse',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::ListRegistryBooksResponse'->new($_) };

declare 'RepeatedListRegistryBooksResponse',
    as ArrayRef[ListRegistryBooksResponse()];

coerce 'RepeatedListRegistryBooksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::ListRegistryBooksResponse'->new($_) } @$_ ] };

declare 'MapStringListRegistryBooksResponse',
    as HashRef[ListRegistryBooksResponse()];

declare 'GetRegistryBookRequest',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::GetRegistryBookRequest'];

coerce 'GetRegistryBookRequest',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::GetRegistryBookRequest'->new($_) };

declare 'RepeatedGetRegistryBookRequest',
    as ArrayRef[GetRegistryBookRequest()];

coerce 'RepeatedGetRegistryBookRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::GetRegistryBookRequest'->new($_) } @$_ ] };

declare 'MapStringGetRegistryBookRequest',
    as HashRef[GetRegistryBookRequest()];

declare 'SearchIpResourcesRequest',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::SearchIpResourcesRequest'];

coerce 'SearchIpResourcesRequest',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::SearchIpResourcesRequest'->new($_) };

declare 'RepeatedSearchIpResourcesRequest',
    as ArrayRef[SearchIpResourcesRequest()];

coerce 'RepeatedSearchIpResourcesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::SearchIpResourcesRequest'->new($_) } @$_ ] };

declare 'MapStringSearchIpResourcesRequest',
    as HashRef[SearchIpResourcesRequest()];

declare 'SearchResourceType',
    as (Int | Str);

declare 'Range',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::Range'];

coerce 'Range',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::Range'->new($_) };

declare 'RepeatedRange',
    as ArrayRef[Range()];

coerce 'RepeatedRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::Range'->new($_) } @$_ ] };

declare 'MapStringRange',
    as HashRef[Range()];

declare 'SearchIpResourcesResponse',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::SearchIpResourcesResponse'];

coerce 'SearchIpResourcesResponse',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::SearchIpResourcesResponse'->new($_) };

declare 'RepeatedSearchIpResourcesResponse',
    as ArrayRef[SearchIpResourcesResponse()];

coerce 'RepeatedSearchIpResourcesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::SearchIpResourcesResponse'->new($_) } @$_ ] };

declare 'MapStringSearchIpResourcesResponse',
    as HashRef[SearchIpResourcesResponse()];

declare 'SearchIpResourcesResult',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::SearchIpResourcesResponse::SearchIpResourcesResult'];

coerce 'SearchIpResourcesResult',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::SearchIpResourcesResponse::SearchIpResourcesResult'->new($_) };

declare 'RepeatedSearchIpResourcesResult',
    as ArrayRef[SearchIpResourcesResult()];

coerce 'RepeatedSearchIpResourcesResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::SearchIpResourcesResponse::SearchIpResourcesResult'->new($_) } @$_ ] };

declare 'MapStringSearchIpResourcesResult',
    as HashRef[SearchIpResourcesResult()];

declare 'CreateRegistryBookRequest',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::CreateRegistryBookRequest'];

coerce 'CreateRegistryBookRequest',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::CreateRegistryBookRequest'->new($_) };

declare 'RepeatedCreateRegistryBookRequest',
    as ArrayRef[CreateRegistryBookRequest()];

coerce 'RepeatedCreateRegistryBookRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::CreateRegistryBookRequest'->new($_) } @$_ ] };

declare 'MapStringCreateRegistryBookRequest',
    as HashRef[CreateRegistryBookRequest()];

declare 'UpdateRegistryBookRequest',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::UpdateRegistryBookRequest'];

coerce 'UpdateRegistryBookRequest',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::UpdateRegistryBookRequest'->new($_) };

declare 'RepeatedUpdateRegistryBookRequest',
    as ArrayRef[UpdateRegistryBookRequest()];

coerce 'RepeatedUpdateRegistryBookRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::UpdateRegistryBookRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateRegistryBookRequest',
    as HashRef[UpdateRegistryBookRequest()];

declare 'DeleteRegistryBookRequest',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::DeleteRegistryBookRequest'];

coerce 'DeleteRegistryBookRequest',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::DeleteRegistryBookRequest'->new($_) };

declare 'RepeatedDeleteRegistryBookRequest',
    as ArrayRef[DeleteRegistryBookRequest()];

coerce 'RepeatedDeleteRegistryBookRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::DeleteRegistryBookRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteRegistryBookRequest',
    as HashRef[DeleteRegistryBookRequest()];

declare 'Realm',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::Realm'];

coerce 'Realm',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::Realm'->new($_) };

declare 'RepeatedRealm',
    as ArrayRef[Realm()];

coerce 'RepeatedRealm',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::Realm'->new($_) } @$_ ] };

declare 'MapStringRealm',
    as HashRef[Realm()];

declare 'TrafficType',
    as (Int | Str);

declare 'ManagementType',
    as (Int | Str);

declare 'RealmView',
    as (Int | Str);

declare 'RealmAggregatedData',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::Realm::RealmAggregatedData'];

coerce 'RealmAggregatedData',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::Realm::RealmAggregatedData'->new($_) };

declare 'RepeatedRealmAggregatedData',
    as ArrayRef[RealmAggregatedData()];

coerce 'RepeatedRealmAggregatedData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::Realm::RealmAggregatedData'->new($_) } @$_ ] };

declare 'MapStringRealmAggregatedData',
    as HashRef[RealmAggregatedData()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::Realm::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::Realm::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::Realm::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'DiscoveryMetadata',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::DiscoveryMetadata'];

coerce 'DiscoveryMetadata',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::DiscoveryMetadata'->new($_) };

declare 'RepeatedDiscoveryMetadata',
    as ArrayRef[DiscoveryMetadata()];

coerce 'RepeatedDiscoveryMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::DiscoveryMetadata'->new($_) } @$_ ] };

declare 'MapStringDiscoveryMetadata',
    as HashRef[DiscoveryMetadata()];

declare 'ResourceState',
    as (Int | Str);

declare 'ListRealmsRequest',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::ListRealmsRequest'];

coerce 'ListRealmsRequest',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::ListRealmsRequest'->new($_) };

declare 'RepeatedListRealmsRequest',
    as ArrayRef[ListRealmsRequest()];

coerce 'RepeatedListRealmsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::ListRealmsRequest'->new($_) } @$_ ] };

declare 'MapStringListRealmsRequest',
    as HashRef[ListRealmsRequest()];

declare 'ListRealmsResponse',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::ListRealmsResponse'];

coerce 'ListRealmsResponse',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::ListRealmsResponse'->new($_) };

declare 'RepeatedListRealmsResponse',
    as ArrayRef[ListRealmsResponse()];

coerce 'RepeatedListRealmsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::ListRealmsResponse'->new($_) } @$_ ] };

declare 'MapStringListRealmsResponse',
    as HashRef[ListRealmsResponse()];

declare 'GetRealmRequest',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::GetRealmRequest'];

coerce 'GetRealmRequest',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::GetRealmRequest'->new($_) };

declare 'RepeatedGetRealmRequest',
    as ArrayRef[GetRealmRequest()];

coerce 'RepeatedGetRealmRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::GetRealmRequest'->new($_) } @$_ ] };

declare 'MapStringGetRealmRequest',
    as HashRef[GetRealmRequest()];

declare 'CreateRealmRequest',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::CreateRealmRequest'];

coerce 'CreateRealmRequest',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::CreateRealmRequest'->new($_) };

declare 'RepeatedCreateRealmRequest',
    as ArrayRef[CreateRealmRequest()];

coerce 'RepeatedCreateRealmRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::CreateRealmRequest'->new($_) } @$_ ] };

declare 'MapStringCreateRealmRequest',
    as HashRef[CreateRealmRequest()];

declare 'UpdateRealmRequest',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::UpdateRealmRequest'];

coerce 'UpdateRealmRequest',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::UpdateRealmRequest'->new($_) };

declare 'RepeatedUpdateRealmRequest',
    as ArrayRef[UpdateRealmRequest()];

coerce 'RepeatedUpdateRealmRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::UpdateRealmRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateRealmRequest',
    as HashRef[UpdateRealmRequest()];

declare 'DeleteRealmRequest',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::DeleteRealmRequest'];

coerce 'DeleteRealmRequest',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::DeleteRealmRequest'->new($_) };

declare 'RepeatedDeleteRealmRequest',
    as ArrayRef[DeleteRealmRequest()];

coerce 'RepeatedDeleteRealmRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::DeleteRealmRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteRealmRequest',
    as HashRef[DeleteRealmRequest()];

declare 'DiscoveredRange',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::DiscoveredRange'];

coerce 'DiscoveredRange',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::DiscoveredRange'->new($_) };

declare 'RepeatedDiscoveredRange',
    as ArrayRef[DiscoveredRange()];

coerce 'RepeatedDiscoveredRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::DiscoveredRange'->new($_) } @$_ ] };

declare 'MapStringDiscoveredRange',
    as HashRef[DiscoveredRange()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::DiscoveredRange::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::DiscoveredRange::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::DiscoveredRange::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListDiscoveredRangesRequest',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::ListDiscoveredRangesRequest'];

coerce 'ListDiscoveredRangesRequest',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::ListDiscoveredRangesRequest'->new($_) };

declare 'RepeatedListDiscoveredRangesRequest',
    as ArrayRef[ListDiscoveredRangesRequest()];

coerce 'RepeatedListDiscoveredRangesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::ListDiscoveredRangesRequest'->new($_) } @$_ ] };

declare 'MapStringListDiscoveredRangesRequest',
    as HashRef[ListDiscoveredRangesRequest()];

declare 'ListDiscoveredRangesResponse',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::ListDiscoveredRangesResponse'];

coerce 'ListDiscoveredRangesResponse',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::ListDiscoveredRangesResponse'->new($_) };

declare 'RepeatedListDiscoveredRangesResponse',
    as ArrayRef[ListDiscoveredRangesResponse()];

coerce 'RepeatedListDiscoveredRangesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::ListDiscoveredRangesResponse'->new($_) } @$_ ] };

declare 'MapStringListDiscoveredRangesResponse',
    as HashRef[ListDiscoveredRangesResponse()];

declare 'GetDiscoveredRangeRequest',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::GetDiscoveredRangeRequest'];

coerce 'GetDiscoveredRangeRequest',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::GetDiscoveredRangeRequest'->new($_) };

declare 'RepeatedGetDiscoveredRangeRequest',
    as ArrayRef[GetDiscoveredRangeRequest()];

coerce 'RepeatedGetDiscoveredRangeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::GetDiscoveredRangeRequest'->new($_) } @$_ ] };

declare 'MapStringGetDiscoveredRangeRequest',
    as HashRef[GetDiscoveredRangeRequest()];

declare 'FindDiscoveredRangeFreeIpRangesRequest',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::FindDiscoveredRangeFreeIpRangesRequest'];

coerce 'FindDiscoveredRangeFreeIpRangesRequest',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::FindDiscoveredRangeFreeIpRangesRequest'->new($_) };

declare 'RepeatedFindDiscoveredRangeFreeIpRangesRequest',
    as ArrayRef[FindDiscoveredRangeFreeIpRangesRequest()];

coerce 'RepeatedFindDiscoveredRangeFreeIpRangesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::FindDiscoveredRangeFreeIpRangesRequest'->new($_) } @$_ ] };

declare 'MapStringFindDiscoveredRangeFreeIpRangesRequest',
    as HashRef[FindDiscoveredRangeFreeIpRangesRequest()];

declare 'FindDiscoveredRangeFreeIpRangesResponse',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::FindDiscoveredRangeFreeIpRangesResponse'];

coerce 'FindDiscoveredRangeFreeIpRangesResponse',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::FindDiscoveredRangeFreeIpRangesResponse'->new($_) };

declare 'RepeatedFindDiscoveredRangeFreeIpRangesResponse',
    as ArrayRef[FindDiscoveredRangeFreeIpRangesResponse()];

coerce 'RepeatedFindDiscoveredRangeFreeIpRangesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::FindDiscoveredRangeFreeIpRangesResponse'->new($_) } @$_ ] };

declare 'MapStringFindDiscoveredRangeFreeIpRangesResponse',
    as HashRef[FindDiscoveredRangeFreeIpRangesResponse()];

declare 'CustomRange',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::CustomRange'];

coerce 'CustomRange',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::CustomRange'->new($_) };

declare 'RepeatedCustomRange',
    as ArrayRef[CustomRange()];

coerce 'RepeatedCustomRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::CustomRange'->new($_) } @$_ ] };

declare 'MapStringCustomRange',
    as HashRef[CustomRange()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::CustomRange::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::CustomRange::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::CustomRange::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Attribute',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::Attribute'];

coerce 'Attribute',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::Attribute'->new($_) };

declare 'RepeatedAttribute',
    as ArrayRef[Attribute()];

coerce 'RepeatedAttribute',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::Attribute'->new($_) } @$_ ] };

declare 'MapStringAttribute',
    as HashRef[Attribute()];

declare 'ListCustomRangesRequest',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::ListCustomRangesRequest'];

coerce 'ListCustomRangesRequest',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::ListCustomRangesRequest'->new($_) };

declare 'RepeatedListCustomRangesRequest',
    as ArrayRef[ListCustomRangesRequest()];

coerce 'RepeatedListCustomRangesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::ListCustomRangesRequest'->new($_) } @$_ ] };

declare 'MapStringListCustomRangesRequest',
    as HashRef[ListCustomRangesRequest()];

declare 'ListCustomRangesResponse',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::ListCustomRangesResponse'];

coerce 'ListCustomRangesResponse',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::ListCustomRangesResponse'->new($_) };

declare 'RepeatedListCustomRangesResponse',
    as ArrayRef[ListCustomRangesResponse()];

coerce 'RepeatedListCustomRangesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::ListCustomRangesResponse'->new($_) } @$_ ] };

declare 'MapStringListCustomRangesResponse',
    as HashRef[ListCustomRangesResponse()];

declare 'GetCustomRangeRequest',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::GetCustomRangeRequest'];

coerce 'GetCustomRangeRequest',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::GetCustomRangeRequest'->new($_) };

declare 'RepeatedGetCustomRangeRequest',
    as ArrayRef[GetCustomRangeRequest()];

coerce 'RepeatedGetCustomRangeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::GetCustomRangeRequest'->new($_) } @$_ ] };

declare 'MapStringGetCustomRangeRequest',
    as HashRef[GetCustomRangeRequest()];

declare 'ShowCustomRangeUtilizationRequest',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::ShowCustomRangeUtilizationRequest'];

coerce 'ShowCustomRangeUtilizationRequest',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::ShowCustomRangeUtilizationRequest'->new($_) };

declare 'RepeatedShowCustomRangeUtilizationRequest',
    as ArrayRef[ShowCustomRangeUtilizationRequest()];

coerce 'RepeatedShowCustomRangeUtilizationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::ShowCustomRangeUtilizationRequest'->new($_) } @$_ ] };

declare 'MapStringShowCustomRangeUtilizationRequest',
    as HashRef[ShowCustomRangeUtilizationRequest()];

declare 'ShowCustomRangeUtilizationResponse',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::ShowCustomRangeUtilizationResponse'];

coerce 'ShowCustomRangeUtilizationResponse',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::ShowCustomRangeUtilizationResponse'->new($_) };

declare 'RepeatedShowCustomRangeUtilizationResponse',
    as ArrayRef[ShowCustomRangeUtilizationResponse()];

coerce 'RepeatedShowCustomRangeUtilizationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::ShowCustomRangeUtilizationResponse'->new($_) } @$_ ] };

declare 'MapStringShowCustomRangeUtilizationResponse',
    as HashRef[ShowCustomRangeUtilizationResponse()];

declare 'ShowDiscoveredRangeUtilizationRequest',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::ShowDiscoveredRangeUtilizationRequest'];

coerce 'ShowDiscoveredRangeUtilizationRequest',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::ShowDiscoveredRangeUtilizationRequest'->new($_) };

declare 'RepeatedShowDiscoveredRangeUtilizationRequest',
    as ArrayRef[ShowDiscoveredRangeUtilizationRequest()];

coerce 'RepeatedShowDiscoveredRangeUtilizationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::ShowDiscoveredRangeUtilizationRequest'->new($_) } @$_ ] };

declare 'MapStringShowDiscoveredRangeUtilizationRequest',
    as HashRef[ShowDiscoveredRangeUtilizationRequest()];

declare 'ShowDiscoveredRangeUtilizationResponse',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::ShowDiscoveredRangeUtilizationResponse'];

coerce 'ShowDiscoveredRangeUtilizationResponse',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::ShowDiscoveredRangeUtilizationResponse'->new($_) };

declare 'RepeatedShowDiscoveredRangeUtilizationResponse',
    as ArrayRef[ShowDiscoveredRangeUtilizationResponse()];

coerce 'RepeatedShowDiscoveredRangeUtilizationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::ShowDiscoveredRangeUtilizationResponse'->new($_) } @$_ ] };

declare 'MapStringShowDiscoveredRangeUtilizationResponse',
    as HashRef[ShowDiscoveredRangeUtilizationResponse()];

declare 'RangeUtilization',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::RangeUtilization'];

coerce 'RangeUtilization',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::RangeUtilization'->new($_) };

declare 'RepeatedRangeUtilization',
    as ArrayRef[RangeUtilization()];

coerce 'RepeatedRangeUtilization',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::RangeUtilization'->new($_) } @$_ ] };

declare 'MapStringRangeUtilization',
    as HashRef[RangeUtilization()];

declare 'CreateCustomRangeRequest',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::CreateCustomRangeRequest'];

coerce 'CreateCustomRangeRequest',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::CreateCustomRangeRequest'->new($_) };

declare 'RepeatedCreateCustomRangeRequest',
    as ArrayRef[CreateCustomRangeRequest()];

coerce 'RepeatedCreateCustomRangeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::CreateCustomRangeRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCustomRangeRequest',
    as HashRef[CreateCustomRangeRequest()];

declare 'UpdateCustomRangeRequest',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::UpdateCustomRangeRequest'];

coerce 'UpdateCustomRangeRequest',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::UpdateCustomRangeRequest'->new($_) };

declare 'RepeatedUpdateCustomRangeRequest',
    as ArrayRef[UpdateCustomRangeRequest()];

coerce 'RepeatedUpdateCustomRangeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::UpdateCustomRangeRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCustomRangeRequest',
    as HashRef[UpdateCustomRangeRequest()];

declare 'DeleteCustomRangeRequest',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::DeleteCustomRangeRequest'];

coerce 'DeleteCustomRangeRequest',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::DeleteCustomRangeRequest'->new($_) };

declare 'RepeatedDeleteCustomRangeRequest',
    as ArrayRef[DeleteCustomRangeRequest()];

coerce 'RepeatedDeleteCustomRangeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::DeleteCustomRangeRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCustomRangeRequest',
    as HashRef[DeleteCustomRangeRequest()];

declare 'FindCustomRangeFreeIpRangesRequest',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::FindCustomRangeFreeIpRangesRequest'];

coerce 'FindCustomRangeFreeIpRangesRequest',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::FindCustomRangeFreeIpRangesRequest'->new($_) };

declare 'RepeatedFindCustomRangeFreeIpRangesRequest',
    as ArrayRef[FindCustomRangeFreeIpRangesRequest()];

coerce 'RepeatedFindCustomRangeFreeIpRangesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::FindCustomRangeFreeIpRangesRequest'->new($_) } @$_ ] };

declare 'MapStringFindCustomRangeFreeIpRangesRequest',
    as HashRef[FindCustomRangeFreeIpRangesRequest()];

declare 'FindCustomRangeFreeIpRangesResponse',
    as InstanceOf['Google::Cloud::Numberregistry::V1alpha::Core::FindCustomRangeFreeIpRangesResponse'];

coerce 'FindCustomRangeFreeIpRangesResponse',
    from HashRef, via { 'Google::Cloud::Numberregistry::V1alpha::Core::FindCustomRangeFreeIpRangesResponse'->new($_) };

declare 'RepeatedFindCustomRangeFreeIpRangesResponse',
    as ArrayRef[FindCustomRangeFreeIpRangesResponse()];

coerce 'RepeatedFindCustomRangeFreeIpRangesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Numberregistry::V1alpha::Core::FindCustomRangeFreeIpRangesResponse'->new($_) } @$_ ] };

declare 'MapStringFindCustomRangeFreeIpRangesResponse',
    as HashRef[FindCustomRangeFreeIpRangesResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Numberregistry::V1alpha::Core::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
