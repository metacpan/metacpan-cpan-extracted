package Google::Cloud::Security::Privateca::V1beta1::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateCertificateRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Service::CreateCertificateRequest'];

coerce 'CreateCertificateRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Service::CreateCertificateRequest'->new($_) };

declare 'RepeatedCreateCertificateRequest',
    as ArrayRef[CreateCertificateRequest()];

coerce 'RepeatedCreateCertificateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Service::CreateCertificateRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCertificateRequest',
    as HashRef[CreateCertificateRequest()];

declare 'GetCertificateRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Service::GetCertificateRequest'];

coerce 'GetCertificateRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Service::GetCertificateRequest'->new($_) };

declare 'RepeatedGetCertificateRequest',
    as ArrayRef[GetCertificateRequest()];

coerce 'RepeatedGetCertificateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Service::GetCertificateRequest'->new($_) } @$_ ] };

declare 'MapStringGetCertificateRequest',
    as HashRef[GetCertificateRequest()];

declare 'ListCertificatesRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Service::ListCertificatesRequest'];

coerce 'ListCertificatesRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Service::ListCertificatesRequest'->new($_) };

declare 'RepeatedListCertificatesRequest',
    as ArrayRef[ListCertificatesRequest()];

coerce 'RepeatedListCertificatesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Service::ListCertificatesRequest'->new($_) } @$_ ] };

declare 'MapStringListCertificatesRequest',
    as HashRef[ListCertificatesRequest()];

declare 'ListCertificatesResponse',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Service::ListCertificatesResponse'];

coerce 'ListCertificatesResponse',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Service::ListCertificatesResponse'->new($_) };

declare 'RepeatedListCertificatesResponse',
    as ArrayRef[ListCertificatesResponse()];

coerce 'RepeatedListCertificatesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Service::ListCertificatesResponse'->new($_) } @$_ ] };

declare 'MapStringListCertificatesResponse',
    as HashRef[ListCertificatesResponse()];

declare 'RevokeCertificateRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Service::RevokeCertificateRequest'];

coerce 'RevokeCertificateRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Service::RevokeCertificateRequest'->new($_) };

declare 'RepeatedRevokeCertificateRequest',
    as ArrayRef[RevokeCertificateRequest()];

coerce 'RepeatedRevokeCertificateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Service::RevokeCertificateRequest'->new($_) } @$_ ] };

declare 'MapStringRevokeCertificateRequest',
    as HashRef[RevokeCertificateRequest()];

declare 'UpdateCertificateRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Service::UpdateCertificateRequest'];

coerce 'UpdateCertificateRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Service::UpdateCertificateRequest'->new($_) };

declare 'RepeatedUpdateCertificateRequest',
    as ArrayRef[UpdateCertificateRequest()];

coerce 'RepeatedUpdateCertificateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Service::UpdateCertificateRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCertificateRequest',
    as HashRef[UpdateCertificateRequest()];

declare 'ActivateCertificateAuthorityRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Service::ActivateCertificateAuthorityRequest'];

coerce 'ActivateCertificateAuthorityRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Service::ActivateCertificateAuthorityRequest'->new($_) };

declare 'RepeatedActivateCertificateAuthorityRequest',
    as ArrayRef[ActivateCertificateAuthorityRequest()];

coerce 'RepeatedActivateCertificateAuthorityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Service::ActivateCertificateAuthorityRequest'->new($_) } @$_ ] };

declare 'MapStringActivateCertificateAuthorityRequest',
    as HashRef[ActivateCertificateAuthorityRequest()];

declare 'CreateCertificateAuthorityRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Service::CreateCertificateAuthorityRequest'];

coerce 'CreateCertificateAuthorityRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Service::CreateCertificateAuthorityRequest'->new($_) };

declare 'RepeatedCreateCertificateAuthorityRequest',
    as ArrayRef[CreateCertificateAuthorityRequest()];

coerce 'RepeatedCreateCertificateAuthorityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Service::CreateCertificateAuthorityRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCertificateAuthorityRequest',
    as HashRef[CreateCertificateAuthorityRequest()];

declare 'DisableCertificateAuthorityRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Service::DisableCertificateAuthorityRequest'];

coerce 'DisableCertificateAuthorityRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Service::DisableCertificateAuthorityRequest'->new($_) };

declare 'RepeatedDisableCertificateAuthorityRequest',
    as ArrayRef[DisableCertificateAuthorityRequest()];

coerce 'RepeatedDisableCertificateAuthorityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Service::DisableCertificateAuthorityRequest'->new($_) } @$_ ] };

declare 'MapStringDisableCertificateAuthorityRequest',
    as HashRef[DisableCertificateAuthorityRequest()];

declare 'EnableCertificateAuthorityRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Service::EnableCertificateAuthorityRequest'];

coerce 'EnableCertificateAuthorityRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Service::EnableCertificateAuthorityRequest'->new($_) };

declare 'RepeatedEnableCertificateAuthorityRequest',
    as ArrayRef[EnableCertificateAuthorityRequest()];

coerce 'RepeatedEnableCertificateAuthorityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Service::EnableCertificateAuthorityRequest'->new($_) } @$_ ] };

declare 'MapStringEnableCertificateAuthorityRequest',
    as HashRef[EnableCertificateAuthorityRequest()];

declare 'FetchCertificateAuthorityCsrRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Service::FetchCertificateAuthorityCsrRequest'];

coerce 'FetchCertificateAuthorityCsrRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Service::FetchCertificateAuthorityCsrRequest'->new($_) };

declare 'RepeatedFetchCertificateAuthorityCsrRequest',
    as ArrayRef[FetchCertificateAuthorityCsrRequest()];

coerce 'RepeatedFetchCertificateAuthorityCsrRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Service::FetchCertificateAuthorityCsrRequest'->new($_) } @$_ ] };

declare 'MapStringFetchCertificateAuthorityCsrRequest',
    as HashRef[FetchCertificateAuthorityCsrRequest()];

declare 'FetchCertificateAuthorityCsrResponse',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Service::FetchCertificateAuthorityCsrResponse'];

coerce 'FetchCertificateAuthorityCsrResponse',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Service::FetchCertificateAuthorityCsrResponse'->new($_) };

declare 'RepeatedFetchCertificateAuthorityCsrResponse',
    as ArrayRef[FetchCertificateAuthorityCsrResponse()];

coerce 'RepeatedFetchCertificateAuthorityCsrResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Service::FetchCertificateAuthorityCsrResponse'->new($_) } @$_ ] };

declare 'MapStringFetchCertificateAuthorityCsrResponse',
    as HashRef[FetchCertificateAuthorityCsrResponse()];

declare 'GetCertificateAuthorityRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Service::GetCertificateAuthorityRequest'];

coerce 'GetCertificateAuthorityRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Service::GetCertificateAuthorityRequest'->new($_) };

declare 'RepeatedGetCertificateAuthorityRequest',
    as ArrayRef[GetCertificateAuthorityRequest()];

coerce 'RepeatedGetCertificateAuthorityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Service::GetCertificateAuthorityRequest'->new($_) } @$_ ] };

declare 'MapStringGetCertificateAuthorityRequest',
    as HashRef[GetCertificateAuthorityRequest()];

declare 'ListCertificateAuthoritiesRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Service::ListCertificateAuthoritiesRequest'];

coerce 'ListCertificateAuthoritiesRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Service::ListCertificateAuthoritiesRequest'->new($_) };

declare 'RepeatedListCertificateAuthoritiesRequest',
    as ArrayRef[ListCertificateAuthoritiesRequest()];

coerce 'RepeatedListCertificateAuthoritiesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Service::ListCertificateAuthoritiesRequest'->new($_) } @$_ ] };

declare 'MapStringListCertificateAuthoritiesRequest',
    as HashRef[ListCertificateAuthoritiesRequest()];

declare 'ListCertificateAuthoritiesResponse',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Service::ListCertificateAuthoritiesResponse'];

coerce 'ListCertificateAuthoritiesResponse',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Service::ListCertificateAuthoritiesResponse'->new($_) };

declare 'RepeatedListCertificateAuthoritiesResponse',
    as ArrayRef[ListCertificateAuthoritiesResponse()];

coerce 'RepeatedListCertificateAuthoritiesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Service::ListCertificateAuthoritiesResponse'->new($_) } @$_ ] };

declare 'MapStringListCertificateAuthoritiesResponse',
    as HashRef[ListCertificateAuthoritiesResponse()];

declare 'RestoreCertificateAuthorityRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Service::RestoreCertificateAuthorityRequest'];

coerce 'RestoreCertificateAuthorityRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Service::RestoreCertificateAuthorityRequest'->new($_) };

declare 'RepeatedRestoreCertificateAuthorityRequest',
    as ArrayRef[RestoreCertificateAuthorityRequest()];

coerce 'RepeatedRestoreCertificateAuthorityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Service::RestoreCertificateAuthorityRequest'->new($_) } @$_ ] };

declare 'MapStringRestoreCertificateAuthorityRequest',
    as HashRef[RestoreCertificateAuthorityRequest()];

declare 'ScheduleDeleteCertificateAuthorityRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Service::ScheduleDeleteCertificateAuthorityRequest'];

coerce 'ScheduleDeleteCertificateAuthorityRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Service::ScheduleDeleteCertificateAuthorityRequest'->new($_) };

declare 'RepeatedScheduleDeleteCertificateAuthorityRequest',
    as ArrayRef[ScheduleDeleteCertificateAuthorityRequest()];

coerce 'RepeatedScheduleDeleteCertificateAuthorityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Service::ScheduleDeleteCertificateAuthorityRequest'->new($_) } @$_ ] };

declare 'MapStringScheduleDeleteCertificateAuthorityRequest',
    as HashRef[ScheduleDeleteCertificateAuthorityRequest()];

declare 'UpdateCertificateAuthorityRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Service::UpdateCertificateAuthorityRequest'];

coerce 'UpdateCertificateAuthorityRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Service::UpdateCertificateAuthorityRequest'->new($_) };

declare 'RepeatedUpdateCertificateAuthorityRequest',
    as ArrayRef[UpdateCertificateAuthorityRequest()];

coerce 'RepeatedUpdateCertificateAuthorityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Service::UpdateCertificateAuthorityRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCertificateAuthorityRequest',
    as HashRef[UpdateCertificateAuthorityRequest()];

declare 'GetCertificateRevocationListRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Service::GetCertificateRevocationListRequest'];

coerce 'GetCertificateRevocationListRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Service::GetCertificateRevocationListRequest'->new($_) };

declare 'RepeatedGetCertificateRevocationListRequest',
    as ArrayRef[GetCertificateRevocationListRequest()];

coerce 'RepeatedGetCertificateRevocationListRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Service::GetCertificateRevocationListRequest'->new($_) } @$_ ] };

declare 'MapStringGetCertificateRevocationListRequest',
    as HashRef[GetCertificateRevocationListRequest()];

declare 'ListCertificateRevocationListsRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Service::ListCertificateRevocationListsRequest'];

coerce 'ListCertificateRevocationListsRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Service::ListCertificateRevocationListsRequest'->new($_) };

declare 'RepeatedListCertificateRevocationListsRequest',
    as ArrayRef[ListCertificateRevocationListsRequest()];

coerce 'RepeatedListCertificateRevocationListsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Service::ListCertificateRevocationListsRequest'->new($_) } @$_ ] };

declare 'MapStringListCertificateRevocationListsRequest',
    as HashRef[ListCertificateRevocationListsRequest()];

declare 'ListCertificateRevocationListsResponse',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Service::ListCertificateRevocationListsResponse'];

coerce 'ListCertificateRevocationListsResponse',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Service::ListCertificateRevocationListsResponse'->new($_) };

declare 'RepeatedListCertificateRevocationListsResponse',
    as ArrayRef[ListCertificateRevocationListsResponse()];

coerce 'RepeatedListCertificateRevocationListsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Service::ListCertificateRevocationListsResponse'->new($_) } @$_ ] };

declare 'MapStringListCertificateRevocationListsResponse',
    as HashRef[ListCertificateRevocationListsResponse()];

declare 'UpdateCertificateRevocationListRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Service::UpdateCertificateRevocationListRequest'];

coerce 'UpdateCertificateRevocationListRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Service::UpdateCertificateRevocationListRequest'->new($_) };

declare 'RepeatedUpdateCertificateRevocationListRequest',
    as ArrayRef[UpdateCertificateRevocationListRequest()];

coerce 'RepeatedUpdateCertificateRevocationListRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Service::UpdateCertificateRevocationListRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCertificateRevocationListRequest',
    as HashRef[UpdateCertificateRevocationListRequest()];

declare 'GetReusableConfigRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Service::GetReusableConfigRequest'];

coerce 'GetReusableConfigRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Service::GetReusableConfigRequest'->new($_) };

declare 'RepeatedGetReusableConfigRequest',
    as ArrayRef[GetReusableConfigRequest()];

coerce 'RepeatedGetReusableConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Service::GetReusableConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetReusableConfigRequest',
    as HashRef[GetReusableConfigRequest()];

declare 'ListReusableConfigsRequest',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Service::ListReusableConfigsRequest'];

coerce 'ListReusableConfigsRequest',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Service::ListReusableConfigsRequest'->new($_) };

declare 'RepeatedListReusableConfigsRequest',
    as ArrayRef[ListReusableConfigsRequest()];

coerce 'RepeatedListReusableConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Service::ListReusableConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListReusableConfigsRequest',
    as HashRef[ListReusableConfigsRequest()];

declare 'ListReusableConfigsResponse',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Service::ListReusableConfigsResponse'];

coerce 'ListReusableConfigsResponse',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Service::ListReusableConfigsResponse'->new($_) };

declare 'RepeatedListReusableConfigsResponse',
    as ArrayRef[ListReusableConfigsResponse()];

coerce 'RepeatedListReusableConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Service::ListReusableConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListReusableConfigsResponse',
    as HashRef[ListReusableConfigsResponse()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Service::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Service::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Service::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Security::Privateca::V1beta1::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
