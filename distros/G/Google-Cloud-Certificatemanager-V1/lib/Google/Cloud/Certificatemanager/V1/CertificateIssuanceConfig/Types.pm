package Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListCertificateIssuanceConfigsRequest',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::ListCertificateIssuanceConfigsRequest'];

coerce 'ListCertificateIssuanceConfigsRequest',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::ListCertificateIssuanceConfigsRequest'->new($_) };

declare 'RepeatedListCertificateIssuanceConfigsRequest',
    as ArrayRef[ListCertificateIssuanceConfigsRequest()];

coerce 'RepeatedListCertificateIssuanceConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::ListCertificateIssuanceConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListCertificateIssuanceConfigsRequest',
    as HashRef[ListCertificateIssuanceConfigsRequest()];

declare 'ListCertificateIssuanceConfigsResponse',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::ListCertificateIssuanceConfigsResponse'];

coerce 'ListCertificateIssuanceConfigsResponse',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::ListCertificateIssuanceConfigsResponse'->new($_) };

declare 'RepeatedListCertificateIssuanceConfigsResponse',
    as ArrayRef[ListCertificateIssuanceConfigsResponse()];

coerce 'RepeatedListCertificateIssuanceConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::ListCertificateIssuanceConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListCertificateIssuanceConfigsResponse',
    as HashRef[ListCertificateIssuanceConfigsResponse()];

declare 'GetCertificateIssuanceConfigRequest',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::GetCertificateIssuanceConfigRequest'];

coerce 'GetCertificateIssuanceConfigRequest',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::GetCertificateIssuanceConfigRequest'->new($_) };

declare 'RepeatedGetCertificateIssuanceConfigRequest',
    as ArrayRef[GetCertificateIssuanceConfigRequest()];

coerce 'RepeatedGetCertificateIssuanceConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::GetCertificateIssuanceConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetCertificateIssuanceConfigRequest',
    as HashRef[GetCertificateIssuanceConfigRequest()];

declare 'CreateCertificateIssuanceConfigRequest',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::CreateCertificateIssuanceConfigRequest'];

coerce 'CreateCertificateIssuanceConfigRequest',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::CreateCertificateIssuanceConfigRequest'->new($_) };

declare 'RepeatedCreateCertificateIssuanceConfigRequest',
    as ArrayRef[CreateCertificateIssuanceConfigRequest()];

coerce 'RepeatedCreateCertificateIssuanceConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::CreateCertificateIssuanceConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCertificateIssuanceConfigRequest',
    as HashRef[CreateCertificateIssuanceConfigRequest()];

declare 'UpdateCertificateIssuanceConfigRequest',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::UpdateCertificateIssuanceConfigRequest'];

coerce 'UpdateCertificateIssuanceConfigRequest',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::UpdateCertificateIssuanceConfigRequest'->new($_) };

declare 'RepeatedUpdateCertificateIssuanceConfigRequest',
    as ArrayRef[UpdateCertificateIssuanceConfigRequest()];

coerce 'RepeatedUpdateCertificateIssuanceConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::UpdateCertificateIssuanceConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCertificateIssuanceConfigRequest',
    as HashRef[UpdateCertificateIssuanceConfigRequest()];

declare 'DeleteCertificateIssuanceConfigRequest',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::DeleteCertificateIssuanceConfigRequest'];

coerce 'DeleteCertificateIssuanceConfigRequest',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::DeleteCertificateIssuanceConfigRequest'->new($_) };

declare 'RepeatedDeleteCertificateIssuanceConfigRequest',
    as ArrayRef[DeleteCertificateIssuanceConfigRequest()];

coerce 'RepeatedDeleteCertificateIssuanceConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::DeleteCertificateIssuanceConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCertificateIssuanceConfigRequest',
    as HashRef[DeleteCertificateIssuanceConfigRequest()];

declare 'CertificateIssuanceConfig',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::CertificateIssuanceConfig'];

coerce 'CertificateIssuanceConfig',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::CertificateIssuanceConfig'->new($_) };

declare 'RepeatedCertificateIssuanceConfig',
    as ArrayRef[CertificateIssuanceConfig()];

coerce 'RepeatedCertificateIssuanceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::CertificateIssuanceConfig'->new($_) } @$_ ] };

declare 'MapStringCertificateIssuanceConfig',
    as HashRef[CertificateIssuanceConfig()];

declare 'KeyAlgorithm',
    as (Int | Str);

declare 'CertificateAuthorityConfig',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::CertificateIssuanceConfig::CertificateAuthorityConfig'];

coerce 'CertificateAuthorityConfig',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::CertificateIssuanceConfig::CertificateAuthorityConfig'->new($_) };

declare 'RepeatedCertificateAuthorityConfig',
    as ArrayRef[CertificateAuthorityConfig()];

coerce 'RepeatedCertificateAuthorityConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::CertificateIssuanceConfig::CertificateAuthorityConfig'->new($_) } @$_ ] };

declare 'MapStringCertificateAuthorityConfig',
    as HashRef[CertificateAuthorityConfig()];

declare 'CertificateAuthorityServiceConfig',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::CertificateIssuanceConfig::CertificateAuthorityConfig::CertificateAuthorityServiceConfig'];

coerce 'CertificateAuthorityServiceConfig',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::CertificateIssuanceConfig::CertificateAuthorityConfig::CertificateAuthorityServiceConfig'->new($_) };

declare 'RepeatedCertificateAuthorityServiceConfig',
    as ArrayRef[CertificateAuthorityServiceConfig()];

coerce 'RepeatedCertificateAuthorityServiceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::CertificateIssuanceConfig::CertificateAuthorityConfig::CertificateAuthorityServiceConfig'->new($_) } @$_ ] };

declare 'MapStringCertificateAuthorityServiceConfig',
    as HashRef[CertificateAuthorityServiceConfig()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::CertificateIssuanceConfig::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::CertificateIssuanceConfig::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::CertificateIssuanceConfig::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'TagsEntry',
    as InstanceOf['Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::CertificateIssuanceConfig::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::CertificateIssuanceConfig::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::CertificateIssuanceConfig::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Certificatemanager::V1::CertificateIssuanceConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
