package Google::Appengine::V1beta::Appengine::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'VersionView',
    as (Int | Str);

declare 'AuthorizedCertificateView',
    as (Int | Str);

declare 'DomainOverrideStrategy',
    as (Int | Str);

declare 'GetApplicationRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::GetApplicationRequest'];

coerce 'GetApplicationRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::GetApplicationRequest'->new($_) };

declare 'RepeatedGetApplicationRequest',
    as ArrayRef[GetApplicationRequest()];

coerce 'RepeatedGetApplicationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::GetApplicationRequest'->new($_) } @$_ ] };

declare 'MapStringGetApplicationRequest',
    as HashRef[GetApplicationRequest()];

declare 'CreateApplicationRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::CreateApplicationRequest'];

coerce 'CreateApplicationRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::CreateApplicationRequest'->new($_) };

declare 'RepeatedCreateApplicationRequest',
    as ArrayRef[CreateApplicationRequest()];

coerce 'RepeatedCreateApplicationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::CreateApplicationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateApplicationRequest',
    as HashRef[CreateApplicationRequest()];

declare 'UpdateApplicationRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::UpdateApplicationRequest'];

coerce 'UpdateApplicationRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::UpdateApplicationRequest'->new($_) };

declare 'RepeatedUpdateApplicationRequest',
    as ArrayRef[UpdateApplicationRequest()];

coerce 'RepeatedUpdateApplicationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::UpdateApplicationRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateApplicationRequest',
    as HashRef[UpdateApplicationRequest()];

declare 'RepairApplicationRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::RepairApplicationRequest'];

coerce 'RepairApplicationRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::RepairApplicationRequest'->new($_) };

declare 'RepeatedRepairApplicationRequest',
    as ArrayRef[RepairApplicationRequest()];

coerce 'RepeatedRepairApplicationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::RepairApplicationRequest'->new($_) } @$_ ] };

declare 'MapStringRepairApplicationRequest',
    as HashRef[RepairApplicationRequest()];

declare 'ListServicesRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::ListServicesRequest'];

coerce 'ListServicesRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::ListServicesRequest'->new($_) };

declare 'RepeatedListServicesRequest',
    as ArrayRef[ListServicesRequest()];

coerce 'RepeatedListServicesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::ListServicesRequest'->new($_) } @$_ ] };

declare 'MapStringListServicesRequest',
    as HashRef[ListServicesRequest()];

declare 'ListServicesResponse',
    as InstanceOf['Google::Appengine::V1beta::Appengine::ListServicesResponse'];

coerce 'ListServicesResponse',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::ListServicesResponse'->new($_) };

declare 'RepeatedListServicesResponse',
    as ArrayRef[ListServicesResponse()];

coerce 'RepeatedListServicesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::ListServicesResponse'->new($_) } @$_ ] };

declare 'MapStringListServicesResponse',
    as HashRef[ListServicesResponse()];

declare 'GetServiceRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::GetServiceRequest'];

coerce 'GetServiceRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::GetServiceRequest'->new($_) };

declare 'RepeatedGetServiceRequest',
    as ArrayRef[GetServiceRequest()];

coerce 'RepeatedGetServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::GetServiceRequest'->new($_) } @$_ ] };

declare 'MapStringGetServiceRequest',
    as HashRef[GetServiceRequest()];

declare 'UpdateServiceRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::UpdateServiceRequest'];

coerce 'UpdateServiceRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::UpdateServiceRequest'->new($_) };

declare 'RepeatedUpdateServiceRequest',
    as ArrayRef[UpdateServiceRequest()];

coerce 'RepeatedUpdateServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::UpdateServiceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateServiceRequest',
    as HashRef[UpdateServiceRequest()];

declare 'DeleteServiceRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::DeleteServiceRequest'];

coerce 'DeleteServiceRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::DeleteServiceRequest'->new($_) };

declare 'RepeatedDeleteServiceRequest',
    as ArrayRef[DeleteServiceRequest()];

coerce 'RepeatedDeleteServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::DeleteServiceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteServiceRequest',
    as HashRef[DeleteServiceRequest()];

declare 'ListVersionsRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::ListVersionsRequest'];

coerce 'ListVersionsRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::ListVersionsRequest'->new($_) };

declare 'RepeatedListVersionsRequest',
    as ArrayRef[ListVersionsRequest()];

coerce 'RepeatedListVersionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::ListVersionsRequest'->new($_) } @$_ ] };

declare 'MapStringListVersionsRequest',
    as HashRef[ListVersionsRequest()];

declare 'ListVersionsResponse',
    as InstanceOf['Google::Appengine::V1beta::Appengine::ListVersionsResponse'];

coerce 'ListVersionsResponse',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::ListVersionsResponse'->new($_) };

declare 'RepeatedListVersionsResponse',
    as ArrayRef[ListVersionsResponse()];

coerce 'RepeatedListVersionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::ListVersionsResponse'->new($_) } @$_ ] };

declare 'MapStringListVersionsResponse',
    as HashRef[ListVersionsResponse()];

declare 'GetVersionRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::GetVersionRequest'];

coerce 'GetVersionRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::GetVersionRequest'->new($_) };

declare 'RepeatedGetVersionRequest',
    as ArrayRef[GetVersionRequest()];

coerce 'RepeatedGetVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::GetVersionRequest'->new($_) } @$_ ] };

declare 'MapStringGetVersionRequest',
    as HashRef[GetVersionRequest()];

declare 'CreateVersionRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::CreateVersionRequest'];

coerce 'CreateVersionRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::CreateVersionRequest'->new($_) };

declare 'RepeatedCreateVersionRequest',
    as ArrayRef[CreateVersionRequest()];

coerce 'RepeatedCreateVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::CreateVersionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateVersionRequest',
    as HashRef[CreateVersionRequest()];

declare 'UpdateVersionRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::UpdateVersionRequest'];

coerce 'UpdateVersionRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::UpdateVersionRequest'->new($_) };

declare 'RepeatedUpdateVersionRequest',
    as ArrayRef[UpdateVersionRequest()];

coerce 'RepeatedUpdateVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::UpdateVersionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateVersionRequest',
    as HashRef[UpdateVersionRequest()];

declare 'DeleteVersionRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::DeleteVersionRequest'];

coerce 'DeleteVersionRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::DeleteVersionRequest'->new($_) };

declare 'RepeatedDeleteVersionRequest',
    as ArrayRef[DeleteVersionRequest()];

coerce 'RepeatedDeleteVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::DeleteVersionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteVersionRequest',
    as HashRef[DeleteVersionRequest()];

declare 'ListInstancesRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::ListInstancesRequest'];

coerce 'ListInstancesRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::ListInstancesRequest'->new($_) };

declare 'RepeatedListInstancesRequest',
    as ArrayRef[ListInstancesRequest()];

coerce 'RepeatedListInstancesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::ListInstancesRequest'->new($_) } @$_ ] };

declare 'MapStringListInstancesRequest',
    as HashRef[ListInstancesRequest()];

declare 'ListInstancesResponse',
    as InstanceOf['Google::Appengine::V1beta::Appengine::ListInstancesResponse'];

coerce 'ListInstancesResponse',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::ListInstancesResponse'->new($_) };

declare 'RepeatedListInstancesResponse',
    as ArrayRef[ListInstancesResponse()];

coerce 'RepeatedListInstancesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::ListInstancesResponse'->new($_) } @$_ ] };

declare 'MapStringListInstancesResponse',
    as HashRef[ListInstancesResponse()];

declare 'GetInstanceRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::GetInstanceRequest'];

coerce 'GetInstanceRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::GetInstanceRequest'->new($_) };

declare 'RepeatedGetInstanceRequest',
    as ArrayRef[GetInstanceRequest()];

coerce 'RepeatedGetInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::GetInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringGetInstanceRequest',
    as HashRef[GetInstanceRequest()];

declare 'DeleteInstanceRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::DeleteInstanceRequest'];

coerce 'DeleteInstanceRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::DeleteInstanceRequest'->new($_) };

declare 'RepeatedDeleteInstanceRequest',
    as ArrayRef[DeleteInstanceRequest()];

coerce 'RepeatedDeleteInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::DeleteInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteInstanceRequest',
    as HashRef[DeleteInstanceRequest()];

declare 'DebugInstanceRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::DebugInstanceRequest'];

coerce 'DebugInstanceRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::DebugInstanceRequest'->new($_) };

declare 'RepeatedDebugInstanceRequest',
    as ArrayRef[DebugInstanceRequest()];

coerce 'RepeatedDebugInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::DebugInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringDebugInstanceRequest',
    as HashRef[DebugInstanceRequest()];

declare 'ListIngressRulesRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::ListIngressRulesRequest'];

coerce 'ListIngressRulesRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::ListIngressRulesRequest'->new($_) };

declare 'RepeatedListIngressRulesRequest',
    as ArrayRef[ListIngressRulesRequest()];

coerce 'RepeatedListIngressRulesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::ListIngressRulesRequest'->new($_) } @$_ ] };

declare 'MapStringListIngressRulesRequest',
    as HashRef[ListIngressRulesRequest()];

declare 'ListIngressRulesResponse',
    as InstanceOf['Google::Appengine::V1beta::Appengine::ListIngressRulesResponse'];

coerce 'ListIngressRulesResponse',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::ListIngressRulesResponse'->new($_) };

declare 'RepeatedListIngressRulesResponse',
    as ArrayRef[ListIngressRulesResponse()];

coerce 'RepeatedListIngressRulesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::ListIngressRulesResponse'->new($_) } @$_ ] };

declare 'MapStringListIngressRulesResponse',
    as HashRef[ListIngressRulesResponse()];

declare 'BatchUpdateIngressRulesRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::BatchUpdateIngressRulesRequest'];

coerce 'BatchUpdateIngressRulesRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::BatchUpdateIngressRulesRequest'->new($_) };

declare 'RepeatedBatchUpdateIngressRulesRequest',
    as ArrayRef[BatchUpdateIngressRulesRequest()];

coerce 'RepeatedBatchUpdateIngressRulesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::BatchUpdateIngressRulesRequest'->new($_) } @$_ ] };

declare 'MapStringBatchUpdateIngressRulesRequest',
    as HashRef[BatchUpdateIngressRulesRequest()];

declare 'BatchUpdateIngressRulesResponse',
    as InstanceOf['Google::Appengine::V1beta::Appengine::BatchUpdateIngressRulesResponse'];

coerce 'BatchUpdateIngressRulesResponse',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::BatchUpdateIngressRulesResponse'->new($_) };

declare 'RepeatedBatchUpdateIngressRulesResponse',
    as ArrayRef[BatchUpdateIngressRulesResponse()];

coerce 'RepeatedBatchUpdateIngressRulesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::BatchUpdateIngressRulesResponse'->new($_) } @$_ ] };

declare 'MapStringBatchUpdateIngressRulesResponse',
    as HashRef[BatchUpdateIngressRulesResponse()];

declare 'CreateIngressRuleRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::CreateIngressRuleRequest'];

coerce 'CreateIngressRuleRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::CreateIngressRuleRequest'->new($_) };

declare 'RepeatedCreateIngressRuleRequest',
    as ArrayRef[CreateIngressRuleRequest()];

coerce 'RepeatedCreateIngressRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::CreateIngressRuleRequest'->new($_) } @$_ ] };

declare 'MapStringCreateIngressRuleRequest',
    as HashRef[CreateIngressRuleRequest()];

declare 'GetIngressRuleRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::GetIngressRuleRequest'];

coerce 'GetIngressRuleRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::GetIngressRuleRequest'->new($_) };

declare 'RepeatedGetIngressRuleRequest',
    as ArrayRef[GetIngressRuleRequest()];

coerce 'RepeatedGetIngressRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::GetIngressRuleRequest'->new($_) } @$_ ] };

declare 'MapStringGetIngressRuleRequest',
    as HashRef[GetIngressRuleRequest()];

declare 'UpdateIngressRuleRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::UpdateIngressRuleRequest'];

coerce 'UpdateIngressRuleRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::UpdateIngressRuleRequest'->new($_) };

declare 'RepeatedUpdateIngressRuleRequest',
    as ArrayRef[UpdateIngressRuleRequest()];

coerce 'RepeatedUpdateIngressRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::UpdateIngressRuleRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateIngressRuleRequest',
    as HashRef[UpdateIngressRuleRequest()];

declare 'DeleteIngressRuleRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::DeleteIngressRuleRequest'];

coerce 'DeleteIngressRuleRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::DeleteIngressRuleRequest'->new($_) };

declare 'RepeatedDeleteIngressRuleRequest',
    as ArrayRef[DeleteIngressRuleRequest()];

coerce 'RepeatedDeleteIngressRuleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::DeleteIngressRuleRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteIngressRuleRequest',
    as HashRef[DeleteIngressRuleRequest()];

declare 'ListAuthorizedDomainsRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::ListAuthorizedDomainsRequest'];

coerce 'ListAuthorizedDomainsRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::ListAuthorizedDomainsRequest'->new($_) };

declare 'RepeatedListAuthorizedDomainsRequest',
    as ArrayRef[ListAuthorizedDomainsRequest()];

coerce 'RepeatedListAuthorizedDomainsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::ListAuthorizedDomainsRequest'->new($_) } @$_ ] };

declare 'MapStringListAuthorizedDomainsRequest',
    as HashRef[ListAuthorizedDomainsRequest()];

declare 'ListAuthorizedDomainsResponse',
    as InstanceOf['Google::Appengine::V1beta::Appengine::ListAuthorizedDomainsResponse'];

coerce 'ListAuthorizedDomainsResponse',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::ListAuthorizedDomainsResponse'->new($_) };

declare 'RepeatedListAuthorizedDomainsResponse',
    as ArrayRef[ListAuthorizedDomainsResponse()];

coerce 'RepeatedListAuthorizedDomainsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::ListAuthorizedDomainsResponse'->new($_) } @$_ ] };

declare 'MapStringListAuthorizedDomainsResponse',
    as HashRef[ListAuthorizedDomainsResponse()];

declare 'ListAuthorizedCertificatesRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::ListAuthorizedCertificatesRequest'];

coerce 'ListAuthorizedCertificatesRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::ListAuthorizedCertificatesRequest'->new($_) };

declare 'RepeatedListAuthorizedCertificatesRequest',
    as ArrayRef[ListAuthorizedCertificatesRequest()];

coerce 'RepeatedListAuthorizedCertificatesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::ListAuthorizedCertificatesRequest'->new($_) } @$_ ] };

declare 'MapStringListAuthorizedCertificatesRequest',
    as HashRef[ListAuthorizedCertificatesRequest()];

declare 'ListAuthorizedCertificatesResponse',
    as InstanceOf['Google::Appengine::V1beta::Appengine::ListAuthorizedCertificatesResponse'];

coerce 'ListAuthorizedCertificatesResponse',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::ListAuthorizedCertificatesResponse'->new($_) };

declare 'RepeatedListAuthorizedCertificatesResponse',
    as ArrayRef[ListAuthorizedCertificatesResponse()];

coerce 'RepeatedListAuthorizedCertificatesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::ListAuthorizedCertificatesResponse'->new($_) } @$_ ] };

declare 'MapStringListAuthorizedCertificatesResponse',
    as HashRef[ListAuthorizedCertificatesResponse()];

declare 'GetAuthorizedCertificateRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::GetAuthorizedCertificateRequest'];

coerce 'GetAuthorizedCertificateRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::GetAuthorizedCertificateRequest'->new($_) };

declare 'RepeatedGetAuthorizedCertificateRequest',
    as ArrayRef[GetAuthorizedCertificateRequest()];

coerce 'RepeatedGetAuthorizedCertificateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::GetAuthorizedCertificateRequest'->new($_) } @$_ ] };

declare 'MapStringGetAuthorizedCertificateRequest',
    as HashRef[GetAuthorizedCertificateRequest()];

declare 'CreateAuthorizedCertificateRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::CreateAuthorizedCertificateRequest'];

coerce 'CreateAuthorizedCertificateRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::CreateAuthorizedCertificateRequest'->new($_) };

declare 'RepeatedCreateAuthorizedCertificateRequest',
    as ArrayRef[CreateAuthorizedCertificateRequest()];

coerce 'RepeatedCreateAuthorizedCertificateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::CreateAuthorizedCertificateRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAuthorizedCertificateRequest',
    as HashRef[CreateAuthorizedCertificateRequest()];

declare 'UpdateAuthorizedCertificateRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::UpdateAuthorizedCertificateRequest'];

coerce 'UpdateAuthorizedCertificateRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::UpdateAuthorizedCertificateRequest'->new($_) };

declare 'RepeatedUpdateAuthorizedCertificateRequest',
    as ArrayRef[UpdateAuthorizedCertificateRequest()];

coerce 'RepeatedUpdateAuthorizedCertificateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::UpdateAuthorizedCertificateRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAuthorizedCertificateRequest',
    as HashRef[UpdateAuthorizedCertificateRequest()];

declare 'DeleteAuthorizedCertificateRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::DeleteAuthorizedCertificateRequest'];

coerce 'DeleteAuthorizedCertificateRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::DeleteAuthorizedCertificateRequest'->new($_) };

declare 'RepeatedDeleteAuthorizedCertificateRequest',
    as ArrayRef[DeleteAuthorizedCertificateRequest()];

coerce 'RepeatedDeleteAuthorizedCertificateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::DeleteAuthorizedCertificateRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAuthorizedCertificateRequest',
    as HashRef[DeleteAuthorizedCertificateRequest()];

declare 'ListDomainMappingsRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::ListDomainMappingsRequest'];

coerce 'ListDomainMappingsRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::ListDomainMappingsRequest'->new($_) };

declare 'RepeatedListDomainMappingsRequest',
    as ArrayRef[ListDomainMappingsRequest()];

coerce 'RepeatedListDomainMappingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::ListDomainMappingsRequest'->new($_) } @$_ ] };

declare 'MapStringListDomainMappingsRequest',
    as HashRef[ListDomainMappingsRequest()];

declare 'ListDomainMappingsResponse',
    as InstanceOf['Google::Appengine::V1beta::Appengine::ListDomainMappingsResponse'];

coerce 'ListDomainMappingsResponse',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::ListDomainMappingsResponse'->new($_) };

declare 'RepeatedListDomainMappingsResponse',
    as ArrayRef[ListDomainMappingsResponse()];

coerce 'RepeatedListDomainMappingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::ListDomainMappingsResponse'->new($_) } @$_ ] };

declare 'MapStringListDomainMappingsResponse',
    as HashRef[ListDomainMappingsResponse()];

declare 'GetDomainMappingRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::GetDomainMappingRequest'];

coerce 'GetDomainMappingRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::GetDomainMappingRequest'->new($_) };

declare 'RepeatedGetDomainMappingRequest',
    as ArrayRef[GetDomainMappingRequest()];

coerce 'RepeatedGetDomainMappingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::GetDomainMappingRequest'->new($_) } @$_ ] };

declare 'MapStringGetDomainMappingRequest',
    as HashRef[GetDomainMappingRequest()];

declare 'CreateDomainMappingRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::CreateDomainMappingRequest'];

coerce 'CreateDomainMappingRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::CreateDomainMappingRequest'->new($_) };

declare 'RepeatedCreateDomainMappingRequest',
    as ArrayRef[CreateDomainMappingRequest()];

coerce 'RepeatedCreateDomainMappingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::CreateDomainMappingRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDomainMappingRequest',
    as HashRef[CreateDomainMappingRequest()];

declare 'UpdateDomainMappingRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::UpdateDomainMappingRequest'];

coerce 'UpdateDomainMappingRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::UpdateDomainMappingRequest'->new($_) };

declare 'RepeatedUpdateDomainMappingRequest',
    as ArrayRef[UpdateDomainMappingRequest()];

coerce 'RepeatedUpdateDomainMappingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::UpdateDomainMappingRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDomainMappingRequest',
    as HashRef[UpdateDomainMappingRequest()];

declare 'DeleteDomainMappingRequest',
    as InstanceOf['Google::Appengine::V1beta::Appengine::DeleteDomainMappingRequest'];

coerce 'DeleteDomainMappingRequest',
    from HashRef, via { 'Google::Appengine::V1beta::Appengine::DeleteDomainMappingRequest'->new($_) };

declare 'RepeatedDeleteDomainMappingRequest',
    as ArrayRef[DeleteDomainMappingRequest()];

coerce 'RepeatedDeleteDomainMappingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1beta::Appengine::DeleteDomainMappingRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDomainMappingRequest',
    as HashRef[DeleteDomainMappingRequest()];

1;

__END__

=head1 NAME

Google::Appengine::V1beta::Appengine::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
