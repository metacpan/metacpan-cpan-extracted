package Google::Cloud::Security::Privateca::V1::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateCertificateRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::CreateCertificateRequest'];

coerce 'CreateCertificateRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::CreateCertificateRequest'->new($_) };

declare 'RepeatedCreateCertificateRequest',
    as ArrayRef[CreateCertificateRequest()];

coerce 'RepeatedCreateCertificateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::CreateCertificateRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCertificateRequest',
    as HashRef[CreateCertificateRequest()];

declare 'GetCertificateRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::GetCertificateRequest'];

coerce 'GetCertificateRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::GetCertificateRequest'->new($_) };

declare 'RepeatedGetCertificateRequest',
    as ArrayRef[GetCertificateRequest()];

coerce 'RepeatedGetCertificateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::GetCertificateRequest'->new($_) } @$_ ] };

declare 'MapStringGetCertificateRequest',
    as HashRef[GetCertificateRequest()];

declare 'ListCertificatesRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::ListCertificatesRequest'];

coerce 'ListCertificatesRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::ListCertificatesRequest'->new($_) };

declare 'RepeatedListCertificatesRequest',
    as ArrayRef[ListCertificatesRequest()];

coerce 'RepeatedListCertificatesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::ListCertificatesRequest'->new($_) } @$_ ] };

declare 'MapStringListCertificatesRequest',
    as HashRef[ListCertificatesRequest()];

declare 'ListCertificatesResponse',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::ListCertificatesResponse'];

coerce 'ListCertificatesResponse',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::ListCertificatesResponse'->new($_) };

declare 'RepeatedListCertificatesResponse',
    as ArrayRef[ListCertificatesResponse()];

coerce 'RepeatedListCertificatesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::ListCertificatesResponse'->new($_) } @$_ ] };

declare 'MapStringListCertificatesResponse',
    as HashRef[ListCertificatesResponse()];

declare 'RevokeCertificateRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::RevokeCertificateRequest'];

coerce 'RevokeCertificateRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::RevokeCertificateRequest'->new($_) };

declare 'RepeatedRevokeCertificateRequest',
    as ArrayRef[RevokeCertificateRequest()];

coerce 'RepeatedRevokeCertificateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::RevokeCertificateRequest'->new($_) } @$_ ] };

declare 'MapStringRevokeCertificateRequest',
    as HashRef[RevokeCertificateRequest()];

declare 'UpdateCertificateRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::UpdateCertificateRequest'];

coerce 'UpdateCertificateRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::UpdateCertificateRequest'->new($_) };

declare 'RepeatedUpdateCertificateRequest',
    as ArrayRef[UpdateCertificateRequest()];

coerce 'RepeatedUpdateCertificateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::UpdateCertificateRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCertificateRequest',
    as HashRef[UpdateCertificateRequest()];

declare 'ActivateCertificateAuthorityRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::ActivateCertificateAuthorityRequest'];

coerce 'ActivateCertificateAuthorityRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::ActivateCertificateAuthorityRequest'->new($_) };

declare 'RepeatedActivateCertificateAuthorityRequest',
    as ArrayRef[ActivateCertificateAuthorityRequest()];

coerce 'RepeatedActivateCertificateAuthorityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::ActivateCertificateAuthorityRequest'->new($_) } @$_ ] };

declare 'MapStringActivateCertificateAuthorityRequest',
    as HashRef[ActivateCertificateAuthorityRequest()];

declare 'CreateCertificateAuthorityRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::CreateCertificateAuthorityRequest'];

coerce 'CreateCertificateAuthorityRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::CreateCertificateAuthorityRequest'->new($_) };

declare 'RepeatedCreateCertificateAuthorityRequest',
    as ArrayRef[CreateCertificateAuthorityRequest()];

coerce 'RepeatedCreateCertificateAuthorityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::CreateCertificateAuthorityRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCertificateAuthorityRequest',
    as HashRef[CreateCertificateAuthorityRequest()];

declare 'DisableCertificateAuthorityRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::DisableCertificateAuthorityRequest'];

coerce 'DisableCertificateAuthorityRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::DisableCertificateAuthorityRequest'->new($_) };

declare 'RepeatedDisableCertificateAuthorityRequest',
    as ArrayRef[DisableCertificateAuthorityRequest()];

coerce 'RepeatedDisableCertificateAuthorityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::DisableCertificateAuthorityRequest'->new($_) } @$_ ] };

declare 'MapStringDisableCertificateAuthorityRequest',
    as HashRef[DisableCertificateAuthorityRequest()];

declare 'EnableCertificateAuthorityRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::EnableCertificateAuthorityRequest'];

coerce 'EnableCertificateAuthorityRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::EnableCertificateAuthorityRequest'->new($_) };

declare 'RepeatedEnableCertificateAuthorityRequest',
    as ArrayRef[EnableCertificateAuthorityRequest()];

coerce 'RepeatedEnableCertificateAuthorityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::EnableCertificateAuthorityRequest'->new($_) } @$_ ] };

declare 'MapStringEnableCertificateAuthorityRequest',
    as HashRef[EnableCertificateAuthorityRequest()];

declare 'FetchCertificateAuthorityCsrRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::FetchCertificateAuthorityCsrRequest'];

coerce 'FetchCertificateAuthorityCsrRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::FetchCertificateAuthorityCsrRequest'->new($_) };

declare 'RepeatedFetchCertificateAuthorityCsrRequest',
    as ArrayRef[FetchCertificateAuthorityCsrRequest()];

coerce 'RepeatedFetchCertificateAuthorityCsrRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::FetchCertificateAuthorityCsrRequest'->new($_) } @$_ ] };

declare 'MapStringFetchCertificateAuthorityCsrRequest',
    as HashRef[FetchCertificateAuthorityCsrRequest()];

declare 'FetchCertificateAuthorityCsrResponse',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::FetchCertificateAuthorityCsrResponse'];

coerce 'FetchCertificateAuthorityCsrResponse',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::FetchCertificateAuthorityCsrResponse'->new($_) };

declare 'RepeatedFetchCertificateAuthorityCsrResponse',
    as ArrayRef[FetchCertificateAuthorityCsrResponse()];

coerce 'RepeatedFetchCertificateAuthorityCsrResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::FetchCertificateAuthorityCsrResponse'->new($_) } @$_ ] };

declare 'MapStringFetchCertificateAuthorityCsrResponse',
    as HashRef[FetchCertificateAuthorityCsrResponse()];

declare 'GetCertificateAuthorityRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::GetCertificateAuthorityRequest'];

coerce 'GetCertificateAuthorityRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::GetCertificateAuthorityRequest'->new($_) };

declare 'RepeatedGetCertificateAuthorityRequest',
    as ArrayRef[GetCertificateAuthorityRequest()];

coerce 'RepeatedGetCertificateAuthorityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::GetCertificateAuthorityRequest'->new($_) } @$_ ] };

declare 'MapStringGetCertificateAuthorityRequest',
    as HashRef[GetCertificateAuthorityRequest()];

declare 'ListCertificateAuthoritiesRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::ListCertificateAuthoritiesRequest'];

coerce 'ListCertificateAuthoritiesRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::ListCertificateAuthoritiesRequest'->new($_) };

declare 'RepeatedListCertificateAuthoritiesRequest',
    as ArrayRef[ListCertificateAuthoritiesRequest()];

coerce 'RepeatedListCertificateAuthoritiesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::ListCertificateAuthoritiesRequest'->new($_) } @$_ ] };

declare 'MapStringListCertificateAuthoritiesRequest',
    as HashRef[ListCertificateAuthoritiesRequest()];

declare 'ListCertificateAuthoritiesResponse',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::ListCertificateAuthoritiesResponse'];

coerce 'ListCertificateAuthoritiesResponse',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::ListCertificateAuthoritiesResponse'->new($_) };

declare 'RepeatedListCertificateAuthoritiesResponse',
    as ArrayRef[ListCertificateAuthoritiesResponse()];

coerce 'RepeatedListCertificateAuthoritiesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::ListCertificateAuthoritiesResponse'->new($_) } @$_ ] };

declare 'MapStringListCertificateAuthoritiesResponse',
    as HashRef[ListCertificateAuthoritiesResponse()];

declare 'UndeleteCertificateAuthorityRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::UndeleteCertificateAuthorityRequest'];

coerce 'UndeleteCertificateAuthorityRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::UndeleteCertificateAuthorityRequest'->new($_) };

declare 'RepeatedUndeleteCertificateAuthorityRequest',
    as ArrayRef[UndeleteCertificateAuthorityRequest()];

coerce 'RepeatedUndeleteCertificateAuthorityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::UndeleteCertificateAuthorityRequest'->new($_) } @$_ ] };

declare 'MapStringUndeleteCertificateAuthorityRequest',
    as HashRef[UndeleteCertificateAuthorityRequest()];

declare 'DeleteCertificateAuthorityRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::DeleteCertificateAuthorityRequest'];

coerce 'DeleteCertificateAuthorityRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::DeleteCertificateAuthorityRequest'->new($_) };

declare 'RepeatedDeleteCertificateAuthorityRequest',
    as ArrayRef[DeleteCertificateAuthorityRequest()];

coerce 'RepeatedDeleteCertificateAuthorityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::DeleteCertificateAuthorityRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCertificateAuthorityRequest',
    as HashRef[DeleteCertificateAuthorityRequest()];

declare 'UpdateCertificateAuthorityRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::UpdateCertificateAuthorityRequest'];

coerce 'UpdateCertificateAuthorityRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::UpdateCertificateAuthorityRequest'->new($_) };

declare 'RepeatedUpdateCertificateAuthorityRequest',
    as ArrayRef[UpdateCertificateAuthorityRequest()];

coerce 'RepeatedUpdateCertificateAuthorityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::UpdateCertificateAuthorityRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCertificateAuthorityRequest',
    as HashRef[UpdateCertificateAuthorityRequest()];

declare 'CreateCaPoolRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::CreateCaPoolRequest'];

coerce 'CreateCaPoolRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::CreateCaPoolRequest'->new($_) };

declare 'RepeatedCreateCaPoolRequest',
    as ArrayRef[CreateCaPoolRequest()];

coerce 'RepeatedCreateCaPoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::CreateCaPoolRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCaPoolRequest',
    as HashRef[CreateCaPoolRequest()];

declare 'UpdateCaPoolRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::UpdateCaPoolRequest'];

coerce 'UpdateCaPoolRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::UpdateCaPoolRequest'->new($_) };

declare 'RepeatedUpdateCaPoolRequest',
    as ArrayRef[UpdateCaPoolRequest()];

coerce 'RepeatedUpdateCaPoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::UpdateCaPoolRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCaPoolRequest',
    as HashRef[UpdateCaPoolRequest()];

declare 'DeleteCaPoolRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::DeleteCaPoolRequest'];

coerce 'DeleteCaPoolRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::DeleteCaPoolRequest'->new($_) };

declare 'RepeatedDeleteCaPoolRequest',
    as ArrayRef[DeleteCaPoolRequest()];

coerce 'RepeatedDeleteCaPoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::DeleteCaPoolRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCaPoolRequest',
    as HashRef[DeleteCaPoolRequest()];

declare 'FetchCaCertsRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::FetchCaCertsRequest'];

coerce 'FetchCaCertsRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::FetchCaCertsRequest'->new($_) };

declare 'RepeatedFetchCaCertsRequest',
    as ArrayRef[FetchCaCertsRequest()];

coerce 'RepeatedFetchCaCertsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::FetchCaCertsRequest'->new($_) } @$_ ] };

declare 'MapStringFetchCaCertsRequest',
    as HashRef[FetchCaCertsRequest()];

declare 'FetchCaCertsResponse',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::FetchCaCertsResponse'];

coerce 'FetchCaCertsResponse',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::FetchCaCertsResponse'->new($_) };

declare 'RepeatedFetchCaCertsResponse',
    as ArrayRef[FetchCaCertsResponse()];

coerce 'RepeatedFetchCaCertsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::FetchCaCertsResponse'->new($_) } @$_ ] };

declare 'MapStringFetchCaCertsResponse',
    as HashRef[FetchCaCertsResponse()];

declare 'CertChain',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::FetchCaCertsResponse::CertChain'];

coerce 'CertChain',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::FetchCaCertsResponse::CertChain'->new($_) };

declare 'RepeatedCertChain',
    as ArrayRef[CertChain()];

coerce 'RepeatedCertChain',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::FetchCaCertsResponse::CertChain'->new($_) } @$_ ] };

declare 'MapStringCertChain',
    as HashRef[CertChain()];

declare 'GetCaPoolRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::GetCaPoolRequest'];

coerce 'GetCaPoolRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::GetCaPoolRequest'->new($_) };

declare 'RepeatedGetCaPoolRequest',
    as ArrayRef[GetCaPoolRequest()];

coerce 'RepeatedGetCaPoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::GetCaPoolRequest'->new($_) } @$_ ] };

declare 'MapStringGetCaPoolRequest',
    as HashRef[GetCaPoolRequest()];

declare 'ListCaPoolsRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::ListCaPoolsRequest'];

coerce 'ListCaPoolsRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::ListCaPoolsRequest'->new($_) };

declare 'RepeatedListCaPoolsRequest',
    as ArrayRef[ListCaPoolsRequest()];

coerce 'RepeatedListCaPoolsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::ListCaPoolsRequest'->new($_) } @$_ ] };

declare 'MapStringListCaPoolsRequest',
    as HashRef[ListCaPoolsRequest()];

declare 'ListCaPoolsResponse',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::ListCaPoolsResponse'];

coerce 'ListCaPoolsResponse',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::ListCaPoolsResponse'->new($_) };

declare 'RepeatedListCaPoolsResponse',
    as ArrayRef[ListCaPoolsResponse()];

coerce 'RepeatedListCaPoolsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::ListCaPoolsResponse'->new($_) } @$_ ] };

declare 'MapStringListCaPoolsResponse',
    as HashRef[ListCaPoolsResponse()];

declare 'GetCertificateRevocationListRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::GetCertificateRevocationListRequest'];

coerce 'GetCertificateRevocationListRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::GetCertificateRevocationListRequest'->new($_) };

declare 'RepeatedGetCertificateRevocationListRequest',
    as ArrayRef[GetCertificateRevocationListRequest()];

coerce 'RepeatedGetCertificateRevocationListRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::GetCertificateRevocationListRequest'->new($_) } @$_ ] };

declare 'MapStringGetCertificateRevocationListRequest',
    as HashRef[GetCertificateRevocationListRequest()];

declare 'ListCertificateRevocationListsRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::ListCertificateRevocationListsRequest'];

coerce 'ListCertificateRevocationListsRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::ListCertificateRevocationListsRequest'->new($_) };

declare 'RepeatedListCertificateRevocationListsRequest',
    as ArrayRef[ListCertificateRevocationListsRequest()];

coerce 'RepeatedListCertificateRevocationListsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::ListCertificateRevocationListsRequest'->new($_) } @$_ ] };

declare 'MapStringListCertificateRevocationListsRequest',
    as HashRef[ListCertificateRevocationListsRequest()];

declare 'ListCertificateRevocationListsResponse',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::ListCertificateRevocationListsResponse'];

coerce 'ListCertificateRevocationListsResponse',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::ListCertificateRevocationListsResponse'->new($_) };

declare 'RepeatedListCertificateRevocationListsResponse',
    as ArrayRef[ListCertificateRevocationListsResponse()];

coerce 'RepeatedListCertificateRevocationListsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::ListCertificateRevocationListsResponse'->new($_) } @$_ ] };

declare 'MapStringListCertificateRevocationListsResponse',
    as HashRef[ListCertificateRevocationListsResponse()];

declare 'UpdateCertificateRevocationListRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::UpdateCertificateRevocationListRequest'];

coerce 'UpdateCertificateRevocationListRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::UpdateCertificateRevocationListRequest'->new($_) };

declare 'RepeatedUpdateCertificateRevocationListRequest',
    as ArrayRef[UpdateCertificateRevocationListRequest()];

coerce 'RepeatedUpdateCertificateRevocationListRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::UpdateCertificateRevocationListRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCertificateRevocationListRequest',
    as HashRef[UpdateCertificateRevocationListRequest()];

declare 'CreateCertificateTemplateRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::CreateCertificateTemplateRequest'];

coerce 'CreateCertificateTemplateRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::CreateCertificateTemplateRequest'->new($_) };

declare 'RepeatedCreateCertificateTemplateRequest',
    as ArrayRef[CreateCertificateTemplateRequest()];

coerce 'RepeatedCreateCertificateTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::CreateCertificateTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCertificateTemplateRequest',
    as HashRef[CreateCertificateTemplateRequest()];

declare 'DeleteCertificateTemplateRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::DeleteCertificateTemplateRequest'];

coerce 'DeleteCertificateTemplateRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::DeleteCertificateTemplateRequest'->new($_) };

declare 'RepeatedDeleteCertificateTemplateRequest',
    as ArrayRef[DeleteCertificateTemplateRequest()];

coerce 'RepeatedDeleteCertificateTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::DeleteCertificateTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCertificateTemplateRequest',
    as HashRef[DeleteCertificateTemplateRequest()];

declare 'GetCertificateTemplateRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::GetCertificateTemplateRequest'];

coerce 'GetCertificateTemplateRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::GetCertificateTemplateRequest'->new($_) };

declare 'RepeatedGetCertificateTemplateRequest',
    as ArrayRef[GetCertificateTemplateRequest()];

coerce 'RepeatedGetCertificateTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::GetCertificateTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringGetCertificateTemplateRequest',
    as HashRef[GetCertificateTemplateRequest()];

declare 'ListCertificateTemplatesRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::ListCertificateTemplatesRequest'];

coerce 'ListCertificateTemplatesRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::ListCertificateTemplatesRequest'->new($_) };

declare 'RepeatedListCertificateTemplatesRequest',
    as ArrayRef[ListCertificateTemplatesRequest()];

coerce 'RepeatedListCertificateTemplatesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::ListCertificateTemplatesRequest'->new($_) } @$_ ] };

declare 'MapStringListCertificateTemplatesRequest',
    as HashRef[ListCertificateTemplatesRequest()];

declare 'ListCertificateTemplatesResponse',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::ListCertificateTemplatesResponse'];

coerce 'ListCertificateTemplatesResponse',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::ListCertificateTemplatesResponse'->new($_) };

declare 'RepeatedListCertificateTemplatesResponse',
    as ArrayRef[ListCertificateTemplatesResponse()];

coerce 'RepeatedListCertificateTemplatesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::ListCertificateTemplatesResponse'->new($_) } @$_ ] };

declare 'MapStringListCertificateTemplatesResponse',
    as HashRef[ListCertificateTemplatesResponse()];

declare 'UpdateCertificateTemplateRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::UpdateCertificateTemplateRequest'];

coerce 'UpdateCertificateTemplateRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::UpdateCertificateTemplateRequest'->new($_) };

declare 'RepeatedUpdateCertificateTemplateRequest',
    as ArrayRef[UpdateCertificateTemplateRequest()];

coerce 'RepeatedUpdateCertificateTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::UpdateCertificateTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCertificateTemplateRequest',
    as HashRef[UpdateCertificateTemplateRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Service::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Service::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Service::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Security::Privateca::V1::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
