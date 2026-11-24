package Google::Cloud::Certificatemanager::V1::CertificateManager::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ServingState',
    as (Int | Str);

declare 'ListCertificatesRequest',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::ListCertificatesRequest'];

coerce 'ListCertificatesRequest',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::ListCertificatesRequest'->new($_) };

declare 'RepeatedListCertificatesRequest',
    as ArrayRef[ListCertificatesRequest()];

coerce 'RepeatedListCertificatesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::ListCertificatesRequest'->new($_) } @$_ ] };

declare 'MapStringListCertificatesRequest',
    as HashRef[ListCertificatesRequest()];

declare 'ListCertificatesResponse',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::ListCertificatesResponse'];

coerce 'ListCertificatesResponse',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::ListCertificatesResponse'->new($_) };

declare 'RepeatedListCertificatesResponse',
    as ArrayRef[ListCertificatesResponse()];

coerce 'RepeatedListCertificatesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::ListCertificatesResponse'->new($_) } @$_ ] };

declare 'MapStringListCertificatesResponse',
    as HashRef[ListCertificatesResponse()];

declare 'GetCertificateRequest',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::GetCertificateRequest'];

coerce 'GetCertificateRequest',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::GetCertificateRequest'->new($_) };

declare 'RepeatedGetCertificateRequest',
    as ArrayRef[GetCertificateRequest()];

coerce 'RepeatedGetCertificateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::GetCertificateRequest'->new($_) } @$_ ] };

declare 'MapStringGetCertificateRequest',
    as HashRef[GetCertificateRequest()];

declare 'CreateCertificateRequest',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::CreateCertificateRequest'];

coerce 'CreateCertificateRequest',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::CreateCertificateRequest'->new($_) };

declare 'RepeatedCreateCertificateRequest',
    as ArrayRef[CreateCertificateRequest()];

coerce 'RepeatedCreateCertificateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::CreateCertificateRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCertificateRequest',
    as HashRef[CreateCertificateRequest()];

declare 'UpdateCertificateRequest',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::UpdateCertificateRequest'];

coerce 'UpdateCertificateRequest',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::UpdateCertificateRequest'->new($_) };

declare 'RepeatedUpdateCertificateRequest',
    as ArrayRef[UpdateCertificateRequest()];

coerce 'RepeatedUpdateCertificateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::UpdateCertificateRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCertificateRequest',
    as HashRef[UpdateCertificateRequest()];

declare 'DeleteCertificateRequest',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::DeleteCertificateRequest'];

coerce 'DeleteCertificateRequest',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::DeleteCertificateRequest'->new($_) };

declare 'RepeatedDeleteCertificateRequest',
    as ArrayRef[DeleteCertificateRequest()];

coerce 'RepeatedDeleteCertificateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::DeleteCertificateRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCertificateRequest',
    as HashRef[DeleteCertificateRequest()];

declare 'ListCertificateMapsRequest',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::ListCertificateMapsRequest'];

coerce 'ListCertificateMapsRequest',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::ListCertificateMapsRequest'->new($_) };

declare 'RepeatedListCertificateMapsRequest',
    as ArrayRef[ListCertificateMapsRequest()];

coerce 'RepeatedListCertificateMapsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::ListCertificateMapsRequest'->new($_) } @$_ ] };

declare 'MapStringListCertificateMapsRequest',
    as HashRef[ListCertificateMapsRequest()];

declare 'ListCertificateMapsResponse',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::ListCertificateMapsResponse'];

coerce 'ListCertificateMapsResponse',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::ListCertificateMapsResponse'->new($_) };

declare 'RepeatedListCertificateMapsResponse',
    as ArrayRef[ListCertificateMapsResponse()];

coerce 'RepeatedListCertificateMapsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::ListCertificateMapsResponse'->new($_) } @$_ ] };

declare 'MapStringListCertificateMapsResponse',
    as HashRef[ListCertificateMapsResponse()];

declare 'GetCertificateMapRequest',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::GetCertificateMapRequest'];

coerce 'GetCertificateMapRequest',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::GetCertificateMapRequest'->new($_) };

declare 'RepeatedGetCertificateMapRequest',
    as ArrayRef[GetCertificateMapRequest()];

coerce 'RepeatedGetCertificateMapRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::GetCertificateMapRequest'->new($_) } @$_ ] };

declare 'MapStringGetCertificateMapRequest',
    as HashRef[GetCertificateMapRequest()];

declare 'CreateCertificateMapRequest',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::CreateCertificateMapRequest'];

coerce 'CreateCertificateMapRequest',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::CreateCertificateMapRequest'->new($_) };

declare 'RepeatedCreateCertificateMapRequest',
    as ArrayRef[CreateCertificateMapRequest()];

coerce 'RepeatedCreateCertificateMapRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::CreateCertificateMapRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCertificateMapRequest',
    as HashRef[CreateCertificateMapRequest()];

declare 'UpdateCertificateMapRequest',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::UpdateCertificateMapRequest'];

coerce 'UpdateCertificateMapRequest',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::UpdateCertificateMapRequest'->new($_) };

declare 'RepeatedUpdateCertificateMapRequest',
    as ArrayRef[UpdateCertificateMapRequest()];

coerce 'RepeatedUpdateCertificateMapRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::UpdateCertificateMapRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCertificateMapRequest',
    as HashRef[UpdateCertificateMapRequest()];

declare 'DeleteCertificateMapRequest',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::DeleteCertificateMapRequest'];

coerce 'DeleteCertificateMapRequest',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::DeleteCertificateMapRequest'->new($_) };

declare 'RepeatedDeleteCertificateMapRequest',
    as ArrayRef[DeleteCertificateMapRequest()];

coerce 'RepeatedDeleteCertificateMapRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::DeleteCertificateMapRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCertificateMapRequest',
    as HashRef[DeleteCertificateMapRequest()];

declare 'ListCertificateMapEntriesRequest',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::ListCertificateMapEntriesRequest'];

coerce 'ListCertificateMapEntriesRequest',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::ListCertificateMapEntriesRequest'->new($_) };

declare 'RepeatedListCertificateMapEntriesRequest',
    as ArrayRef[ListCertificateMapEntriesRequest()];

coerce 'RepeatedListCertificateMapEntriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::ListCertificateMapEntriesRequest'->new($_) } @$_ ] };

declare 'MapStringListCertificateMapEntriesRequest',
    as HashRef[ListCertificateMapEntriesRequest()];

declare 'ListCertificateMapEntriesResponse',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::ListCertificateMapEntriesResponse'];

coerce 'ListCertificateMapEntriesResponse',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::ListCertificateMapEntriesResponse'->new($_) };

declare 'RepeatedListCertificateMapEntriesResponse',
    as ArrayRef[ListCertificateMapEntriesResponse()];

coerce 'RepeatedListCertificateMapEntriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::ListCertificateMapEntriesResponse'->new($_) } @$_ ] };

declare 'MapStringListCertificateMapEntriesResponse',
    as HashRef[ListCertificateMapEntriesResponse()];

declare 'GetCertificateMapEntryRequest',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::GetCertificateMapEntryRequest'];

coerce 'GetCertificateMapEntryRequest',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::GetCertificateMapEntryRequest'->new($_) };

declare 'RepeatedGetCertificateMapEntryRequest',
    as ArrayRef[GetCertificateMapEntryRequest()];

coerce 'RepeatedGetCertificateMapEntryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::GetCertificateMapEntryRequest'->new($_) } @$_ ] };

declare 'MapStringGetCertificateMapEntryRequest',
    as HashRef[GetCertificateMapEntryRequest()];

declare 'CreateCertificateMapEntryRequest',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::CreateCertificateMapEntryRequest'];

coerce 'CreateCertificateMapEntryRequest',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::CreateCertificateMapEntryRequest'->new($_) };

declare 'RepeatedCreateCertificateMapEntryRequest',
    as ArrayRef[CreateCertificateMapEntryRequest()];

coerce 'RepeatedCreateCertificateMapEntryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::CreateCertificateMapEntryRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCertificateMapEntryRequest',
    as HashRef[CreateCertificateMapEntryRequest()];

declare 'UpdateCertificateMapEntryRequest',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::UpdateCertificateMapEntryRequest'];

coerce 'UpdateCertificateMapEntryRequest',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::UpdateCertificateMapEntryRequest'->new($_) };

declare 'RepeatedUpdateCertificateMapEntryRequest',
    as ArrayRef[UpdateCertificateMapEntryRequest()];

coerce 'RepeatedUpdateCertificateMapEntryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::UpdateCertificateMapEntryRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCertificateMapEntryRequest',
    as HashRef[UpdateCertificateMapEntryRequest()];

declare 'DeleteCertificateMapEntryRequest',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::DeleteCertificateMapEntryRequest'];

coerce 'DeleteCertificateMapEntryRequest',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::DeleteCertificateMapEntryRequest'->new($_) };

declare 'RepeatedDeleteCertificateMapEntryRequest',
    as ArrayRef[DeleteCertificateMapEntryRequest()];

coerce 'RepeatedDeleteCertificateMapEntryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::DeleteCertificateMapEntryRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCertificateMapEntryRequest',
    as HashRef[DeleteCertificateMapEntryRequest()];

declare 'ListDnsAuthorizationsRequest',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::ListDnsAuthorizationsRequest'];

coerce 'ListDnsAuthorizationsRequest',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::ListDnsAuthorizationsRequest'->new($_) };

declare 'RepeatedListDnsAuthorizationsRequest',
    as ArrayRef[ListDnsAuthorizationsRequest()];

coerce 'RepeatedListDnsAuthorizationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::ListDnsAuthorizationsRequest'->new($_) } @$_ ] };

declare 'MapStringListDnsAuthorizationsRequest',
    as HashRef[ListDnsAuthorizationsRequest()];

declare 'ListDnsAuthorizationsResponse',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::ListDnsAuthorizationsResponse'];

coerce 'ListDnsAuthorizationsResponse',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::ListDnsAuthorizationsResponse'->new($_) };

declare 'RepeatedListDnsAuthorizationsResponse',
    as ArrayRef[ListDnsAuthorizationsResponse()];

coerce 'RepeatedListDnsAuthorizationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::ListDnsAuthorizationsResponse'->new($_) } @$_ ] };

declare 'MapStringListDnsAuthorizationsResponse',
    as HashRef[ListDnsAuthorizationsResponse()];

declare 'GetDnsAuthorizationRequest',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::GetDnsAuthorizationRequest'];

coerce 'GetDnsAuthorizationRequest',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::GetDnsAuthorizationRequest'->new($_) };

declare 'RepeatedGetDnsAuthorizationRequest',
    as ArrayRef[GetDnsAuthorizationRequest()];

coerce 'RepeatedGetDnsAuthorizationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::GetDnsAuthorizationRequest'->new($_) } @$_ ] };

declare 'MapStringGetDnsAuthorizationRequest',
    as HashRef[GetDnsAuthorizationRequest()];

declare 'CreateDnsAuthorizationRequest',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::CreateDnsAuthorizationRequest'];

coerce 'CreateDnsAuthorizationRequest',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::CreateDnsAuthorizationRequest'->new($_) };

declare 'RepeatedCreateDnsAuthorizationRequest',
    as ArrayRef[CreateDnsAuthorizationRequest()];

coerce 'RepeatedCreateDnsAuthorizationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::CreateDnsAuthorizationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDnsAuthorizationRequest',
    as HashRef[CreateDnsAuthorizationRequest()];

declare 'UpdateDnsAuthorizationRequest',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::UpdateDnsAuthorizationRequest'];

coerce 'UpdateDnsAuthorizationRequest',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::UpdateDnsAuthorizationRequest'->new($_) };

declare 'RepeatedUpdateDnsAuthorizationRequest',
    as ArrayRef[UpdateDnsAuthorizationRequest()];

coerce 'RepeatedUpdateDnsAuthorizationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::UpdateDnsAuthorizationRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDnsAuthorizationRequest',
    as HashRef[UpdateDnsAuthorizationRequest()];

declare 'DeleteDnsAuthorizationRequest',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::DeleteDnsAuthorizationRequest'];

coerce 'DeleteDnsAuthorizationRequest',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::DeleteDnsAuthorizationRequest'->new($_) };

declare 'RepeatedDeleteDnsAuthorizationRequest',
    as ArrayRef[DeleteDnsAuthorizationRequest()];

coerce 'RepeatedDeleteDnsAuthorizationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::DeleteDnsAuthorizationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDnsAuthorizationRequest',
    as HashRef[DeleteDnsAuthorizationRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'Certificate',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate'];

coerce 'Certificate',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate'->new($_) };

declare 'RepeatedCertificate',
    as ArrayRef[Certificate()];

coerce 'RepeatedCertificate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate'->new($_) } @$_ ] };

declare 'MapStringCertificate',
    as HashRef[Certificate()];

declare 'Scope',
    as (Int | Str);

declare 'SelfManagedCertificate',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate::SelfManagedCertificate'];

coerce 'SelfManagedCertificate',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate::SelfManagedCertificate'->new($_) };

declare 'RepeatedSelfManagedCertificate',
    as ArrayRef[SelfManagedCertificate()];

coerce 'RepeatedSelfManagedCertificate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate::SelfManagedCertificate'->new($_) } @$_ ] };

declare 'MapStringSelfManagedCertificate',
    as HashRef[SelfManagedCertificate()];

declare 'ManagedCertificate',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate::ManagedCertificate'];

coerce 'ManagedCertificate',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate::ManagedCertificate'->new($_) };

declare 'RepeatedManagedCertificate',
    as ArrayRef[ManagedCertificate()];

coerce 'RepeatedManagedCertificate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate::ManagedCertificate'->new($_) } @$_ ] };

declare 'MapStringManagedCertificate',
    as HashRef[ManagedCertificate()];

declare 'State',
    as (Int | Str);

declare 'ProvisioningIssue',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate::ManagedCertificate::ProvisioningIssue'];

coerce 'ProvisioningIssue',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate::ManagedCertificate::ProvisioningIssue'->new($_) };

declare 'RepeatedProvisioningIssue',
    as ArrayRef[ProvisioningIssue()];

coerce 'RepeatedProvisioningIssue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate::ManagedCertificate::ProvisioningIssue'->new($_) } @$_ ] };

declare 'MapStringProvisioningIssue',
    as HashRef[ProvisioningIssue()];

declare 'Reason',
    as (Int | Str);

declare 'AuthorizationAttemptInfo',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate::ManagedCertificate::AuthorizationAttemptInfo'];

coerce 'AuthorizationAttemptInfo',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate::ManagedCertificate::AuthorizationAttemptInfo'->new($_) };

declare 'RepeatedAuthorizationAttemptInfo',
    as ArrayRef[AuthorizationAttemptInfo()];

coerce 'RepeatedAuthorizationAttemptInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate::ManagedCertificate::AuthorizationAttemptInfo'->new($_) } @$_ ] };

declare 'MapStringAuthorizationAttemptInfo',
    as HashRef[AuthorizationAttemptInfo()];

declare 'State',
    as (Int | Str);

declare 'FailureReason',
    as (Int | Str);

declare 'Troubleshooting',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate::ManagedCertificate::AuthorizationAttemptInfo::Troubleshooting'];

coerce 'Troubleshooting',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate::ManagedCertificate::AuthorizationAttemptInfo::Troubleshooting'->new($_) };

declare 'RepeatedTroubleshooting',
    as ArrayRef[Troubleshooting()];

coerce 'RepeatedTroubleshooting',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate::ManagedCertificate::AuthorizationAttemptInfo::Troubleshooting'->new($_) } @$_ ] };

declare 'MapStringTroubleshooting',
    as HashRef[Troubleshooting()];

declare 'Issue',
    as (Int | Str);

declare 'CNAME',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate::ManagedCertificate::AuthorizationAttemptInfo::Troubleshooting::CNAME'];

coerce 'CNAME',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate::ManagedCertificate::AuthorizationAttemptInfo::Troubleshooting::CNAME'->new($_) };

declare 'RepeatedCNAME',
    as ArrayRef[CNAME()];

coerce 'RepeatedCNAME',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate::ManagedCertificate::AuthorizationAttemptInfo::Troubleshooting::CNAME'->new($_) } @$_ ] };

declare 'MapStringCNAME',
    as HashRef[CNAME()];

declare 'IPs',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate::ManagedCertificate::AuthorizationAttemptInfo::Troubleshooting::IPs'];

coerce 'IPs',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate::ManagedCertificate::AuthorizationAttemptInfo::Troubleshooting::IPs'->new($_) };

declare 'RepeatedIPs',
    as ArrayRef[IPs()];

coerce 'RepeatedIPs',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate::ManagedCertificate::AuthorizationAttemptInfo::Troubleshooting::IPs'->new($_) } @$_ ] };

declare 'MapStringIPs',
    as HashRef[IPs()];

declare 'ManagedIdentityCertificate',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate::ManagedIdentityCertificate'];

coerce 'ManagedIdentityCertificate',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate::ManagedIdentityCertificate'->new($_) };

declare 'RepeatedManagedIdentityCertificate',
    as ArrayRef[ManagedIdentityCertificate()];

coerce 'RepeatedManagedIdentityCertificate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate::ManagedIdentityCertificate'->new($_) } @$_ ] };

declare 'MapStringManagedIdentityCertificate',
    as HashRef[ManagedIdentityCertificate()];

declare 'UsedBy',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate::UsedBy'];

coerce 'UsedBy',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate::UsedBy'->new($_) };

declare 'RepeatedUsedBy',
    as ArrayRef[UsedBy()];

coerce 'RepeatedUsedBy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate::UsedBy'->new($_) } @$_ ] };

declare 'MapStringUsedBy',
    as HashRef[UsedBy()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'TagsEntry',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::Certificate::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

declare 'CertificateMap',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::CertificateMap'];

coerce 'CertificateMap',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::CertificateMap'->new($_) };

declare 'RepeatedCertificateMap',
    as ArrayRef[CertificateMap()];

coerce 'RepeatedCertificateMap',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::CertificateMap'->new($_) } @$_ ] };

declare 'MapStringCertificateMap',
    as HashRef[CertificateMap()];

declare 'GclbTarget',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::CertificateMap::GclbTarget'];

coerce 'GclbTarget',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::CertificateMap::GclbTarget'->new($_) };

declare 'RepeatedGclbTarget',
    as ArrayRef[GclbTarget()];

coerce 'RepeatedGclbTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::CertificateMap::GclbTarget'->new($_) } @$_ ] };

declare 'MapStringGclbTarget',
    as HashRef[GclbTarget()];

declare 'IpConfig',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::CertificateMap::GclbTarget::IpConfig'];

coerce 'IpConfig',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::CertificateMap::GclbTarget::IpConfig'->new($_) };

declare 'RepeatedIpConfig',
    as ArrayRef[IpConfig()];

coerce 'RepeatedIpConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::CertificateMap::GclbTarget::IpConfig'->new($_) } @$_ ] };

declare 'MapStringIpConfig',
    as HashRef[IpConfig()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::CertificateMap::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::CertificateMap::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::CertificateMap::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'TagsEntry',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::CertificateMap::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::CertificateMap::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::CertificateMap::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

declare 'CertificateMapEntry',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::CertificateMapEntry'];

coerce 'CertificateMapEntry',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::CertificateMapEntry'->new($_) };

declare 'RepeatedCertificateMapEntry',
    as ArrayRef[CertificateMapEntry()];

coerce 'RepeatedCertificateMapEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::CertificateMapEntry'->new($_) } @$_ ] };

declare 'MapStringCertificateMapEntry',
    as HashRef[CertificateMapEntry()];

declare 'Matcher',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::CertificateMapEntry::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::CertificateMapEntry::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::CertificateMapEntry::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'DnsAuthorization',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::DnsAuthorization'];

coerce 'DnsAuthorization',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::DnsAuthorization'->new($_) };

declare 'RepeatedDnsAuthorization',
    as ArrayRef[DnsAuthorization()];

coerce 'RepeatedDnsAuthorization',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::DnsAuthorization'->new($_) } @$_ ] };

declare 'MapStringDnsAuthorization',
    as HashRef[DnsAuthorization()];

declare 'Type',
    as (Int | Str);

declare 'DnsResourceRecord',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::DnsAuthorization::DnsResourceRecord'];

coerce 'DnsResourceRecord',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::DnsAuthorization::DnsResourceRecord'->new($_) };

declare 'RepeatedDnsResourceRecord',
    as ArrayRef[DnsResourceRecord()];

coerce 'RepeatedDnsResourceRecord',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::DnsAuthorization::DnsResourceRecord'->new($_) } @$_ ] };

declare 'MapStringDnsResourceRecord',
    as HashRef[DnsResourceRecord()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::DnsAuthorization::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::DnsAuthorization::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::DnsAuthorization::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'TagsEntry',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateManager::DnsAuthorization::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateManager::DnsAuthorization::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateManager::DnsAuthorization::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Certificatemanager::V1::CertificateManager::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
