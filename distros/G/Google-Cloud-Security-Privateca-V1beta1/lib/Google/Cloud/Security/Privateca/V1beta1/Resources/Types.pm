package Google::Cloud::Security::Privateca::V1beta1::Resources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RevocationReason',
    as (Int | Str);

declare 'CertificateAuthority',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateAuthority'];

coerce 'CertificateAuthority',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateAuthority'->new($_) };

declare 'RepeatedCertificateAuthority',
    as ArrayRef[CertificateAuthority()];

coerce 'RepeatedCertificateAuthority',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateAuthority'->new($_) } @$_ ] };

declare 'MapStringCertificateAuthority',
    as HashRef[CertificateAuthority()];

declare 'Type',
    as (Int | Str);

declare 'Tier',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'SignHashAlgorithm',
    as (Int | Str);

declare 'IssuingOptions',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateAuthority::IssuingOptions'];

coerce 'IssuingOptions',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateAuthority::IssuingOptions'->new($_) };

declare 'RepeatedIssuingOptions',
    as ArrayRef[IssuingOptions()];

coerce 'RepeatedIssuingOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateAuthority::IssuingOptions'->new($_) } @$_ ] };

declare 'MapStringIssuingOptions',
    as HashRef[IssuingOptions()];

declare 'CertificateAuthorityPolicy',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateAuthority::CertificateAuthorityPolicy'];

coerce 'CertificateAuthorityPolicy',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateAuthority::CertificateAuthorityPolicy'->new($_) };

declare 'RepeatedCertificateAuthorityPolicy',
    as ArrayRef[CertificateAuthorityPolicy()];

coerce 'RepeatedCertificateAuthorityPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateAuthority::CertificateAuthorityPolicy'->new($_) } @$_ ] };

declare 'MapStringCertificateAuthorityPolicy',
    as HashRef[CertificateAuthorityPolicy()];

declare 'AllowedConfigList',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateAuthority::CertificateAuthorityPolicy::AllowedConfigList'];

coerce 'AllowedConfigList',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateAuthority::CertificateAuthorityPolicy::AllowedConfigList'->new($_) };

declare 'RepeatedAllowedConfigList',
    as ArrayRef[AllowedConfigList()];

coerce 'RepeatedAllowedConfigList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateAuthority::CertificateAuthorityPolicy::AllowedConfigList'->new($_) } @$_ ] };

declare 'MapStringAllowedConfigList',
    as HashRef[AllowedConfigList()];

declare 'AllowedSubjectAltNames',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateAuthority::CertificateAuthorityPolicy::AllowedSubjectAltNames'];

coerce 'AllowedSubjectAltNames',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateAuthority::CertificateAuthorityPolicy::AllowedSubjectAltNames'->new($_) };

declare 'RepeatedAllowedSubjectAltNames',
    as ArrayRef[AllowedSubjectAltNames()];

coerce 'RepeatedAllowedSubjectAltNames',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateAuthority::CertificateAuthorityPolicy::AllowedSubjectAltNames'->new($_) } @$_ ] };

declare 'MapStringAllowedSubjectAltNames',
    as HashRef[AllowedSubjectAltNames()];

declare 'IssuanceModes',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateAuthority::CertificateAuthorityPolicy::IssuanceModes'];

coerce 'IssuanceModes',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateAuthority::CertificateAuthorityPolicy::IssuanceModes'->new($_) };

declare 'RepeatedIssuanceModes',
    as ArrayRef[IssuanceModes()];

coerce 'RepeatedIssuanceModes',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateAuthority::CertificateAuthorityPolicy::IssuanceModes'->new($_) } @$_ ] };

declare 'MapStringIssuanceModes',
    as HashRef[IssuanceModes()];

declare 'AccessUrls',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateAuthority::AccessUrls'];

coerce 'AccessUrls',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateAuthority::AccessUrls'->new($_) };

declare 'RepeatedAccessUrls',
    as ArrayRef[AccessUrls()];

coerce 'RepeatedAccessUrls',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateAuthority::AccessUrls'->new($_) } @$_ ] };

declare 'MapStringAccessUrls',
    as HashRef[AccessUrls()];

declare 'KeyVersionSpec',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateAuthority::KeyVersionSpec'];

coerce 'KeyVersionSpec',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateAuthority::KeyVersionSpec'->new($_) };

declare 'RepeatedKeyVersionSpec',
    as ArrayRef[KeyVersionSpec()];

coerce 'RepeatedKeyVersionSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateAuthority::KeyVersionSpec'->new($_) } @$_ ] };

declare 'MapStringKeyVersionSpec',
    as HashRef[KeyVersionSpec()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateAuthority::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateAuthority::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateAuthority::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'CertificateRevocationList',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateRevocationList'];

coerce 'CertificateRevocationList',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateRevocationList'->new($_) };

declare 'RepeatedCertificateRevocationList',
    as ArrayRef[CertificateRevocationList()];

coerce 'RepeatedCertificateRevocationList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateRevocationList'->new($_) } @$_ ] };

declare 'MapStringCertificateRevocationList',
    as HashRef[CertificateRevocationList()];

declare 'State',
    as (Int | Str);

declare 'RevokedCertificate',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateRevocationList::RevokedCertificate'];

coerce 'RevokedCertificate',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateRevocationList::RevokedCertificate'->new($_) };

declare 'RepeatedRevokedCertificate',
    as ArrayRef[RevokedCertificate()];

coerce 'RepeatedRevokedCertificate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateRevocationList::RevokedCertificate'->new($_) } @$_ ] };

declare 'MapStringRevokedCertificate',
    as HashRef[RevokedCertificate()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateRevocationList::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateRevocationList::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateRevocationList::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Certificate',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::Certificate'];

coerce 'Certificate',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::Certificate'->new($_) };

declare 'RepeatedCertificate',
    as ArrayRef[Certificate()];

coerce 'RepeatedCertificate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::Certificate'->new($_) } @$_ ] };

declare 'MapStringCertificate',
    as HashRef[Certificate()];

declare 'RevocationDetails',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::Certificate::RevocationDetails'];

coerce 'RevocationDetails',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::Certificate::RevocationDetails'->new($_) };

declare 'RepeatedRevocationDetails',
    as ArrayRef[RevocationDetails()];

coerce 'RepeatedRevocationDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::Certificate::RevocationDetails'->new($_) } @$_ ] };

declare 'MapStringRevocationDetails',
    as HashRef[RevocationDetails()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::Certificate::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::Certificate::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::Certificate::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ReusableConfig',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::ReusableConfig'];

coerce 'ReusableConfig',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::ReusableConfig'->new($_) };

declare 'RepeatedReusableConfig',
    as ArrayRef[ReusableConfig()];

coerce 'RepeatedReusableConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::ReusableConfig'->new($_) } @$_ ] };

declare 'MapStringReusableConfig',
    as HashRef[ReusableConfig()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::ReusableConfig::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::ReusableConfig::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::ReusableConfig::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ReusableConfigValues',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::ReusableConfigValues'];

coerce 'ReusableConfigValues',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::ReusableConfigValues'->new($_) };

declare 'RepeatedReusableConfigValues',
    as ArrayRef[ReusableConfigValues()];

coerce 'RepeatedReusableConfigValues',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::ReusableConfigValues'->new($_) } @$_ ] };

declare 'MapStringReusableConfigValues',
    as HashRef[ReusableConfigValues()];

declare 'CaOptions',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::ReusableConfigValues::CaOptions'];

coerce 'CaOptions',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::ReusableConfigValues::CaOptions'->new($_) };

declare 'RepeatedCaOptions',
    as ArrayRef[CaOptions()];

coerce 'RepeatedCaOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::ReusableConfigValues::CaOptions'->new($_) } @$_ ] };

declare 'MapStringCaOptions',
    as HashRef[CaOptions()];

declare 'ReusableConfigWrapper',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::ReusableConfigWrapper'];

coerce 'ReusableConfigWrapper',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::ReusableConfigWrapper'->new($_) };

declare 'RepeatedReusableConfigWrapper',
    as ArrayRef[ReusableConfigWrapper()];

coerce 'RepeatedReusableConfigWrapper',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::ReusableConfigWrapper'->new($_) } @$_ ] };

declare 'MapStringReusableConfigWrapper',
    as HashRef[ReusableConfigWrapper()];

declare 'SubordinateConfig',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::SubordinateConfig'];

coerce 'SubordinateConfig',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::SubordinateConfig'->new($_) };

declare 'RepeatedSubordinateConfig',
    as ArrayRef[SubordinateConfig()];

coerce 'RepeatedSubordinateConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::SubordinateConfig'->new($_) } @$_ ] };

declare 'MapStringSubordinateConfig',
    as HashRef[SubordinateConfig()];

declare 'SubordinateConfigChain',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::SubordinateConfig::SubordinateConfigChain'];

coerce 'SubordinateConfigChain',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::SubordinateConfig::SubordinateConfigChain'->new($_) };

declare 'RepeatedSubordinateConfigChain',
    as ArrayRef[SubordinateConfigChain()];

coerce 'RepeatedSubordinateConfigChain',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::SubordinateConfig::SubordinateConfigChain'->new($_) } @$_ ] };

declare 'MapStringSubordinateConfigChain',
    as HashRef[SubordinateConfigChain()];

declare 'PublicKey',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::PublicKey'];

coerce 'PublicKey',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::PublicKey'->new($_) };

declare 'RepeatedPublicKey',
    as ArrayRef[PublicKey()];

coerce 'RepeatedPublicKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::PublicKey'->new($_) } @$_ ] };

declare 'MapStringPublicKey',
    as HashRef[PublicKey()];

declare 'KeyType',
    as (Int | Str);

declare 'CertificateConfig',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateConfig'];

coerce 'CertificateConfig',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateConfig'->new($_) };

declare 'RepeatedCertificateConfig',
    as ArrayRef[CertificateConfig()];

coerce 'RepeatedCertificateConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateConfig'->new($_) } @$_ ] };

declare 'MapStringCertificateConfig',
    as HashRef[CertificateConfig()];

declare 'SubjectConfig',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateConfig::SubjectConfig'];

coerce 'SubjectConfig',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateConfig::SubjectConfig'->new($_) };

declare 'RepeatedSubjectConfig',
    as ArrayRef[SubjectConfig()];

coerce 'RepeatedSubjectConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateConfig::SubjectConfig'->new($_) } @$_ ] };

declare 'MapStringSubjectConfig',
    as HashRef[SubjectConfig()];

declare 'CertificateDescription',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateDescription'];

coerce 'CertificateDescription',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateDescription'->new($_) };

declare 'RepeatedCertificateDescription',
    as ArrayRef[CertificateDescription()];

coerce 'RepeatedCertificateDescription',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateDescription'->new($_) } @$_ ] };

declare 'MapStringCertificateDescription',
    as HashRef[CertificateDescription()];

declare 'SubjectDescription',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateDescription::SubjectDescription'];

coerce 'SubjectDescription',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateDescription::SubjectDescription'->new($_) };

declare 'RepeatedSubjectDescription',
    as ArrayRef[SubjectDescription()];

coerce 'RepeatedSubjectDescription',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateDescription::SubjectDescription'->new($_) } @$_ ] };

declare 'MapStringSubjectDescription',
    as HashRef[SubjectDescription()];

declare 'KeyId',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateDescription::KeyId'];

coerce 'KeyId',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateDescription::KeyId'->new($_) };

declare 'RepeatedKeyId',
    as ArrayRef[KeyId()];

coerce 'RepeatedKeyId',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateDescription::KeyId'->new($_) } @$_ ] };

declare 'MapStringKeyId',
    as HashRef[KeyId()];

declare 'CertificateFingerprint',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateDescription::CertificateFingerprint'];

coerce 'CertificateFingerprint',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateDescription::CertificateFingerprint'->new($_) };

declare 'RepeatedCertificateFingerprint',
    as ArrayRef[CertificateFingerprint()];

coerce 'RepeatedCertificateFingerprint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::CertificateDescription::CertificateFingerprint'->new($_) } @$_ ] };

declare 'MapStringCertificateFingerprint',
    as HashRef[CertificateFingerprint()];

declare 'ObjectId',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::ObjectId'];

coerce 'ObjectId',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::ObjectId'->new($_) };

declare 'RepeatedObjectId',
    as ArrayRef[ObjectId()];

coerce 'RepeatedObjectId',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::ObjectId'->new($_) } @$_ ] };

declare 'MapStringObjectId',
    as HashRef[ObjectId()];

declare 'X509Extension',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::X509Extension'];

coerce 'X509Extension',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::X509Extension'->new($_) };

declare 'RepeatedX509Extension',
    as ArrayRef[X509Extension()];

coerce 'RepeatedX509Extension',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::X509Extension'->new($_) } @$_ ] };

declare 'MapStringX509Extension',
    as HashRef[X509Extension()];

declare 'KeyUsage',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::KeyUsage'];

coerce 'KeyUsage',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::KeyUsage'->new($_) };

declare 'RepeatedKeyUsage',
    as ArrayRef[KeyUsage()];

coerce 'RepeatedKeyUsage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::KeyUsage'->new($_) } @$_ ] };

declare 'MapStringKeyUsage',
    as HashRef[KeyUsage()];

declare 'KeyUsageOptions',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::KeyUsage::KeyUsageOptions'];

coerce 'KeyUsageOptions',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::KeyUsage::KeyUsageOptions'->new($_) };

declare 'RepeatedKeyUsageOptions',
    as ArrayRef[KeyUsageOptions()];

coerce 'RepeatedKeyUsageOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::KeyUsage::KeyUsageOptions'->new($_) } @$_ ] };

declare 'MapStringKeyUsageOptions',
    as HashRef[KeyUsageOptions()];

declare 'ExtendedKeyUsageOptions',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::KeyUsage::ExtendedKeyUsageOptions'];

coerce 'ExtendedKeyUsageOptions',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::KeyUsage::ExtendedKeyUsageOptions'->new($_) };

declare 'RepeatedExtendedKeyUsageOptions',
    as ArrayRef[ExtendedKeyUsageOptions()];

coerce 'RepeatedExtendedKeyUsageOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::KeyUsage::ExtendedKeyUsageOptions'->new($_) } @$_ ] };

declare 'MapStringExtendedKeyUsageOptions',
    as HashRef[ExtendedKeyUsageOptions()];

declare 'Subject',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::Subject'];

coerce 'Subject',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::Subject'->new($_) };

declare 'RepeatedSubject',
    as ArrayRef[Subject()];

coerce 'RepeatedSubject',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::Subject'->new($_) } @$_ ] };

declare 'MapStringSubject',
    as HashRef[Subject()];

declare 'SubjectAltNames',
    as InstanceOf['Google::Cloud::Security::Privateca::V1beta1::Resources::SubjectAltNames'];

coerce 'SubjectAltNames',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1beta1::Resources::SubjectAltNames'->new($_) };

declare 'RepeatedSubjectAltNames',
    as ArrayRef[SubjectAltNames()];

coerce 'RepeatedSubjectAltNames',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1beta1::Resources::SubjectAltNames'->new($_) } @$_ ] };

declare 'MapStringSubjectAltNames',
    as HashRef[SubjectAltNames()];

1;

__END__

=head1 NAME

Google::Cloud::Security::Privateca::V1beta1::Resources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
