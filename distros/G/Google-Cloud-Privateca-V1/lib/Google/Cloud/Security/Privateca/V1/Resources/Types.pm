package Google::Cloud::Security::Privateca::V1::Resources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AttributeType',
    as (Int | Str);

declare 'RevocationReason',
    as (Int | Str);

declare 'SubjectRequestMode',
    as (Int | Str);

declare 'CertificateAuthority',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::CertificateAuthority'];

coerce 'CertificateAuthority',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateAuthority'->new($_) };

declare 'RepeatedCertificateAuthority',
    as ArrayRef[CertificateAuthority()];

coerce 'RepeatedCertificateAuthority',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateAuthority'->new($_) } @$_ ] };

declare 'MapStringCertificateAuthority',
    as HashRef[CertificateAuthority()];

declare 'Type',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'SignHashAlgorithm',
    as (Int | Str);

declare 'AccessUrls',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::CertificateAuthority::AccessUrls'];

coerce 'AccessUrls',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateAuthority::AccessUrls'->new($_) };

declare 'RepeatedAccessUrls',
    as ArrayRef[AccessUrls()];

coerce 'RepeatedAccessUrls',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateAuthority::AccessUrls'->new($_) } @$_ ] };

declare 'MapStringAccessUrls',
    as HashRef[AccessUrls()];

declare 'KeyVersionSpec',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::CertificateAuthority::KeyVersionSpec'];

coerce 'KeyVersionSpec',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateAuthority::KeyVersionSpec'->new($_) };

declare 'RepeatedKeyVersionSpec',
    as ArrayRef[KeyVersionSpec()];

coerce 'RepeatedKeyVersionSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateAuthority::KeyVersionSpec'->new($_) } @$_ ] };

declare 'MapStringKeyVersionSpec',
    as HashRef[KeyVersionSpec()];

declare 'UserDefinedAccessUrls',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::CertificateAuthority::UserDefinedAccessUrls'];

coerce 'UserDefinedAccessUrls',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateAuthority::UserDefinedAccessUrls'->new($_) };

declare 'RepeatedUserDefinedAccessUrls',
    as ArrayRef[UserDefinedAccessUrls()];

coerce 'RepeatedUserDefinedAccessUrls',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateAuthority::UserDefinedAccessUrls'->new($_) } @$_ ] };

declare 'MapStringUserDefinedAccessUrls',
    as HashRef[UserDefinedAccessUrls()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::CertificateAuthority::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateAuthority::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateAuthority::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'CaPool',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::CaPool'];

coerce 'CaPool',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::CaPool'->new($_) };

declare 'RepeatedCaPool',
    as ArrayRef[CaPool()];

coerce 'RepeatedCaPool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::CaPool'->new($_) } @$_ ] };

declare 'MapStringCaPool',
    as HashRef[CaPool()];

declare 'Tier',
    as (Int | Str);

declare 'PublishingOptions',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::CaPool::PublishingOptions'];

coerce 'PublishingOptions',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::CaPool::PublishingOptions'->new($_) };

declare 'RepeatedPublishingOptions',
    as ArrayRef[PublishingOptions()];

coerce 'RepeatedPublishingOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::CaPool::PublishingOptions'->new($_) } @$_ ] };

declare 'MapStringPublishingOptions',
    as HashRef[PublishingOptions()];

declare 'EncodingFormat',
    as (Int | Str);

declare 'IssuancePolicy',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::CaPool::IssuancePolicy'];

coerce 'IssuancePolicy',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::CaPool::IssuancePolicy'->new($_) };

declare 'RepeatedIssuancePolicy',
    as ArrayRef[IssuancePolicy()];

coerce 'RepeatedIssuancePolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::CaPool::IssuancePolicy'->new($_) } @$_ ] };

declare 'MapStringIssuancePolicy',
    as HashRef[IssuancePolicy()];

declare 'AllowedKeyType',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::CaPool::IssuancePolicy::AllowedKeyType'];

coerce 'AllowedKeyType',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::CaPool::IssuancePolicy::AllowedKeyType'->new($_) };

declare 'RepeatedAllowedKeyType',
    as ArrayRef[AllowedKeyType()];

coerce 'RepeatedAllowedKeyType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::CaPool::IssuancePolicy::AllowedKeyType'->new($_) } @$_ ] };

declare 'MapStringAllowedKeyType',
    as HashRef[AllowedKeyType()];

declare 'RsaKeyType',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::CaPool::IssuancePolicy::AllowedKeyType::RsaKeyType'];

coerce 'RsaKeyType',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::CaPool::IssuancePolicy::AllowedKeyType::RsaKeyType'->new($_) };

declare 'RepeatedRsaKeyType',
    as ArrayRef[RsaKeyType()];

coerce 'RepeatedRsaKeyType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::CaPool::IssuancePolicy::AllowedKeyType::RsaKeyType'->new($_) } @$_ ] };

declare 'MapStringRsaKeyType',
    as HashRef[RsaKeyType()];

declare 'EcKeyType',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::CaPool::IssuancePolicy::AllowedKeyType::EcKeyType'];

coerce 'EcKeyType',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::CaPool::IssuancePolicy::AllowedKeyType::EcKeyType'->new($_) };

declare 'RepeatedEcKeyType',
    as ArrayRef[EcKeyType()];

coerce 'RepeatedEcKeyType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::CaPool::IssuancePolicy::AllowedKeyType::EcKeyType'->new($_) } @$_ ] };

declare 'MapStringEcKeyType',
    as HashRef[EcKeyType()];

declare 'EcSignatureAlgorithm',
    as (Int | Str);

declare 'IssuanceModes',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::CaPool::IssuancePolicy::IssuanceModes'];

coerce 'IssuanceModes',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::CaPool::IssuancePolicy::IssuanceModes'->new($_) };

declare 'RepeatedIssuanceModes',
    as ArrayRef[IssuanceModes()];

coerce 'RepeatedIssuanceModes',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::CaPool::IssuancePolicy::IssuanceModes'->new($_) } @$_ ] };

declare 'MapStringIssuanceModes',
    as HashRef[IssuanceModes()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::CaPool::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::CaPool::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::CaPool::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'EncryptionSpec',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::EncryptionSpec'];

coerce 'EncryptionSpec',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::EncryptionSpec'->new($_) };

declare 'RepeatedEncryptionSpec',
    as ArrayRef[EncryptionSpec()];

coerce 'RepeatedEncryptionSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::EncryptionSpec'->new($_) } @$_ ] };

declare 'MapStringEncryptionSpec',
    as HashRef[EncryptionSpec()];

declare 'CertificateRevocationList',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::CertificateRevocationList'];

coerce 'CertificateRevocationList',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateRevocationList'->new($_) };

declare 'RepeatedCertificateRevocationList',
    as ArrayRef[CertificateRevocationList()];

coerce 'RepeatedCertificateRevocationList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateRevocationList'->new($_) } @$_ ] };

declare 'MapStringCertificateRevocationList',
    as HashRef[CertificateRevocationList()];

declare 'State',
    as (Int | Str);

declare 'RevokedCertificate',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::CertificateRevocationList::RevokedCertificate'];

coerce 'RevokedCertificate',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateRevocationList::RevokedCertificate'->new($_) };

declare 'RepeatedRevokedCertificate',
    as ArrayRef[RevokedCertificate()];

coerce 'RepeatedRevokedCertificate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateRevocationList::RevokedCertificate'->new($_) } @$_ ] };

declare 'MapStringRevokedCertificate',
    as HashRef[RevokedCertificate()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::CertificateRevocationList::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateRevocationList::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateRevocationList::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Certificate',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::Certificate'];

coerce 'Certificate',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::Certificate'->new($_) };

declare 'RepeatedCertificate',
    as ArrayRef[Certificate()];

coerce 'RepeatedCertificate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::Certificate'->new($_) } @$_ ] };

declare 'MapStringCertificate',
    as HashRef[Certificate()];

declare 'RevocationDetails',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::Certificate::RevocationDetails'];

coerce 'RevocationDetails',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::Certificate::RevocationDetails'->new($_) };

declare 'RepeatedRevocationDetails',
    as ArrayRef[RevocationDetails()];

coerce 'RepeatedRevocationDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::Certificate::RevocationDetails'->new($_) } @$_ ] };

declare 'MapStringRevocationDetails',
    as HashRef[RevocationDetails()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::Certificate::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::Certificate::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::Certificate::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'CertificateTemplate',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::CertificateTemplate'];

coerce 'CertificateTemplate',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateTemplate'->new($_) };

declare 'RepeatedCertificateTemplate',
    as ArrayRef[CertificateTemplate()];

coerce 'RepeatedCertificateTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateTemplate'->new($_) } @$_ ] };

declare 'MapStringCertificateTemplate',
    as HashRef[CertificateTemplate()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::CertificateTemplate::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateTemplate::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateTemplate::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'X509Parameters',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::X509Parameters'];

coerce 'X509Parameters',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::X509Parameters'->new($_) };

declare 'RepeatedX509Parameters',
    as ArrayRef[X509Parameters()];

coerce 'RepeatedX509Parameters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::X509Parameters'->new($_) } @$_ ] };

declare 'MapStringX509Parameters',
    as HashRef[X509Parameters()];

declare 'CaOptions',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::X509Parameters::CaOptions'];

coerce 'CaOptions',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::X509Parameters::CaOptions'->new($_) };

declare 'RepeatedCaOptions',
    as ArrayRef[CaOptions()];

coerce 'RepeatedCaOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::X509Parameters::CaOptions'->new($_) } @$_ ] };

declare 'MapStringCaOptions',
    as HashRef[CaOptions()];

declare 'NameConstraints',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::X509Parameters::NameConstraints'];

coerce 'NameConstraints',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::X509Parameters::NameConstraints'->new($_) };

declare 'RepeatedNameConstraints',
    as ArrayRef[NameConstraints()];

coerce 'RepeatedNameConstraints',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::X509Parameters::NameConstraints'->new($_) } @$_ ] };

declare 'MapStringNameConstraints',
    as HashRef[NameConstraints()];

declare 'SubordinateConfig',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::SubordinateConfig'];

coerce 'SubordinateConfig',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::SubordinateConfig'->new($_) };

declare 'RepeatedSubordinateConfig',
    as ArrayRef[SubordinateConfig()];

coerce 'RepeatedSubordinateConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::SubordinateConfig'->new($_) } @$_ ] };

declare 'MapStringSubordinateConfig',
    as HashRef[SubordinateConfig()];

declare 'SubordinateConfigChain',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::SubordinateConfig::SubordinateConfigChain'];

coerce 'SubordinateConfigChain',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::SubordinateConfig::SubordinateConfigChain'->new($_) };

declare 'RepeatedSubordinateConfigChain',
    as ArrayRef[SubordinateConfigChain()];

coerce 'RepeatedSubordinateConfigChain',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::SubordinateConfig::SubordinateConfigChain'->new($_) } @$_ ] };

declare 'MapStringSubordinateConfigChain',
    as HashRef[SubordinateConfigChain()];

declare 'PublicKey',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::PublicKey'];

coerce 'PublicKey',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::PublicKey'->new($_) };

declare 'RepeatedPublicKey',
    as ArrayRef[PublicKey()];

coerce 'RepeatedPublicKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::PublicKey'->new($_) } @$_ ] };

declare 'MapStringPublicKey',
    as HashRef[PublicKey()];

declare 'KeyFormat',
    as (Int | Str);

declare 'CertificateConfig',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::CertificateConfig'];

coerce 'CertificateConfig',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateConfig'->new($_) };

declare 'RepeatedCertificateConfig',
    as ArrayRef[CertificateConfig()];

coerce 'RepeatedCertificateConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateConfig'->new($_) } @$_ ] };

declare 'MapStringCertificateConfig',
    as HashRef[CertificateConfig()];

declare 'SubjectConfig',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::CertificateConfig::SubjectConfig'];

coerce 'SubjectConfig',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateConfig::SubjectConfig'->new($_) };

declare 'RepeatedSubjectConfig',
    as ArrayRef[SubjectConfig()];

coerce 'RepeatedSubjectConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateConfig::SubjectConfig'->new($_) } @$_ ] };

declare 'MapStringSubjectConfig',
    as HashRef[SubjectConfig()];

declare 'KeyId',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::CertificateConfig::KeyId'];

coerce 'KeyId',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateConfig::KeyId'->new($_) };

declare 'RepeatedKeyId',
    as ArrayRef[KeyId()];

coerce 'RepeatedKeyId',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateConfig::KeyId'->new($_) } @$_ ] };

declare 'MapStringKeyId',
    as HashRef[KeyId()];

declare 'CertificateDescription',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::CertificateDescription'];

coerce 'CertificateDescription',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateDescription'->new($_) };

declare 'RepeatedCertificateDescription',
    as ArrayRef[CertificateDescription()];

coerce 'RepeatedCertificateDescription',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateDescription'->new($_) } @$_ ] };

declare 'MapStringCertificateDescription',
    as HashRef[CertificateDescription()];

declare 'SubjectDescription',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::CertificateDescription::SubjectDescription'];

coerce 'SubjectDescription',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateDescription::SubjectDescription'->new($_) };

declare 'RepeatedSubjectDescription',
    as ArrayRef[SubjectDescription()];

coerce 'RepeatedSubjectDescription',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateDescription::SubjectDescription'->new($_) } @$_ ] };

declare 'MapStringSubjectDescription',
    as HashRef[SubjectDescription()];

declare 'KeyId',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::CertificateDescription::KeyId'];

coerce 'KeyId',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateDescription::KeyId'->new($_) };

declare 'RepeatedKeyId',
    as ArrayRef[KeyId()];

coerce 'RepeatedKeyId',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateDescription::KeyId'->new($_) } @$_ ] };

declare 'MapStringKeyId',
    as HashRef[KeyId()];

declare 'CertificateFingerprint',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::CertificateDescription::CertificateFingerprint'];

coerce 'CertificateFingerprint',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateDescription::CertificateFingerprint'->new($_) };

declare 'RepeatedCertificateFingerprint',
    as ArrayRef[CertificateFingerprint()];

coerce 'RepeatedCertificateFingerprint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateDescription::CertificateFingerprint'->new($_) } @$_ ] };

declare 'MapStringCertificateFingerprint',
    as HashRef[CertificateFingerprint()];

declare 'ObjectId',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::ObjectId'];

coerce 'ObjectId',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::ObjectId'->new($_) };

declare 'RepeatedObjectId',
    as ArrayRef[ObjectId()];

coerce 'RepeatedObjectId',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::ObjectId'->new($_) } @$_ ] };

declare 'MapStringObjectId',
    as HashRef[ObjectId()];

declare 'X509Extension',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::X509Extension'];

coerce 'X509Extension',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::X509Extension'->new($_) };

declare 'RepeatedX509Extension',
    as ArrayRef[X509Extension()];

coerce 'RepeatedX509Extension',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::X509Extension'->new($_) } @$_ ] };

declare 'MapStringX509Extension',
    as HashRef[X509Extension()];

declare 'KeyUsage',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::KeyUsage'];

coerce 'KeyUsage',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::KeyUsage'->new($_) };

declare 'RepeatedKeyUsage',
    as ArrayRef[KeyUsage()];

coerce 'RepeatedKeyUsage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::KeyUsage'->new($_) } @$_ ] };

declare 'MapStringKeyUsage',
    as HashRef[KeyUsage()];

declare 'KeyUsageOptions',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::KeyUsage::KeyUsageOptions'];

coerce 'KeyUsageOptions',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::KeyUsage::KeyUsageOptions'->new($_) };

declare 'RepeatedKeyUsageOptions',
    as ArrayRef[KeyUsageOptions()];

coerce 'RepeatedKeyUsageOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::KeyUsage::KeyUsageOptions'->new($_) } @$_ ] };

declare 'MapStringKeyUsageOptions',
    as HashRef[KeyUsageOptions()];

declare 'ExtendedKeyUsageOptions',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::KeyUsage::ExtendedKeyUsageOptions'];

coerce 'ExtendedKeyUsageOptions',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::KeyUsage::ExtendedKeyUsageOptions'->new($_) };

declare 'RepeatedExtendedKeyUsageOptions',
    as ArrayRef[ExtendedKeyUsageOptions()];

coerce 'RepeatedExtendedKeyUsageOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::KeyUsage::ExtendedKeyUsageOptions'->new($_) } @$_ ] };

declare 'MapStringExtendedKeyUsageOptions',
    as HashRef[ExtendedKeyUsageOptions()];

declare 'AttributeTypeAndValue',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::AttributeTypeAndValue'];

coerce 'AttributeTypeAndValue',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::AttributeTypeAndValue'->new($_) };

declare 'RepeatedAttributeTypeAndValue',
    as ArrayRef[AttributeTypeAndValue()];

coerce 'RepeatedAttributeTypeAndValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::AttributeTypeAndValue'->new($_) } @$_ ] };

declare 'MapStringAttributeTypeAndValue',
    as HashRef[AttributeTypeAndValue()];

declare 'RelativeDistinguishedName',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::RelativeDistinguishedName'];

coerce 'RelativeDistinguishedName',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::RelativeDistinguishedName'->new($_) };

declare 'RepeatedRelativeDistinguishedName',
    as ArrayRef[RelativeDistinguishedName()];

coerce 'RepeatedRelativeDistinguishedName',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::RelativeDistinguishedName'->new($_) } @$_ ] };

declare 'MapStringRelativeDistinguishedName',
    as HashRef[RelativeDistinguishedName()];

declare 'Subject',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::Subject'];

coerce 'Subject',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::Subject'->new($_) };

declare 'RepeatedSubject',
    as ArrayRef[Subject()];

coerce 'RepeatedSubject',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::Subject'->new($_) } @$_ ] };

declare 'MapStringSubject',
    as HashRef[Subject()];

declare 'SubjectAltNames',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::SubjectAltNames'];

coerce 'SubjectAltNames',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::SubjectAltNames'->new($_) };

declare 'RepeatedSubjectAltNames',
    as ArrayRef[SubjectAltNames()];

coerce 'RepeatedSubjectAltNames',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::SubjectAltNames'->new($_) } @$_ ] };

declare 'MapStringSubjectAltNames',
    as HashRef[SubjectAltNames()];

declare 'CertificateIdentityConstraints',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::CertificateIdentityConstraints'];

coerce 'CertificateIdentityConstraints',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateIdentityConstraints'->new($_) };

declare 'RepeatedCertificateIdentityConstraints',
    as ArrayRef[CertificateIdentityConstraints()];

coerce 'RepeatedCertificateIdentityConstraints',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateIdentityConstraints'->new($_) } @$_ ] };

declare 'MapStringCertificateIdentityConstraints',
    as HashRef[CertificateIdentityConstraints()];

declare 'CertificateExtensionConstraints',
    as InstanceOf['Google::Cloud::Security::Privateca::V1::Resources::CertificateExtensionConstraints'];

coerce 'CertificateExtensionConstraints',
    from HashRef, via { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateExtensionConstraints'->new($_) };

declare 'RepeatedCertificateExtensionConstraints',
    as ArrayRef[CertificateExtensionConstraints()];

coerce 'RepeatedCertificateExtensionConstraints',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Security::Privateca::V1::Resources::CertificateExtensionConstraints'->new($_) } @$_ ] };

declare 'MapStringCertificateExtensionConstraints',
    as HashRef[CertificateExtensionConstraints()];

declare 'KnownCertificateExtension',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Security::Privateca::V1::Resources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
