package Google::Cloud::Kms::V1::Resources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ProtectionLevel',
    as (Int | Str);

declare 'AccessReason',
    as (Int | Str);

declare 'KeyRing',
    as InstanceOf['Google::Cloud::Kms::V1::Resources::KeyRing'];

coerce 'KeyRing',
    from HashRef, via { 'Google::Cloud::Kms::V1::Resources::KeyRing'->new($_) };

declare 'RepeatedKeyRing',
    as ArrayRef[KeyRing()];

coerce 'RepeatedKeyRing',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Resources::KeyRing'->new($_) } @$_ ] };

declare 'MapStringKeyRing',
    as HashRef[KeyRing()];

declare 'CryptoKey',
    as InstanceOf['Google::Cloud::Kms::V1::Resources::CryptoKey'];

coerce 'CryptoKey',
    from HashRef, via { 'Google::Cloud::Kms::V1::Resources::CryptoKey'->new($_) };

declare 'RepeatedCryptoKey',
    as ArrayRef[CryptoKey()];

coerce 'RepeatedCryptoKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Resources::CryptoKey'->new($_) } @$_ ] };

declare 'MapStringCryptoKey',
    as HashRef[CryptoKey()];

declare 'CryptoKeyPurpose',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Kms::V1::Resources::CryptoKey::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Kms::V1::Resources::CryptoKey::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Resources::CryptoKey::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'CryptoKeyVersionTemplate',
    as InstanceOf['Google::Cloud::Kms::V1::Resources::CryptoKeyVersionTemplate'];

coerce 'CryptoKeyVersionTemplate',
    from HashRef, via { 'Google::Cloud::Kms::V1::Resources::CryptoKeyVersionTemplate'->new($_) };

declare 'RepeatedCryptoKeyVersionTemplate',
    as ArrayRef[CryptoKeyVersionTemplate()];

coerce 'RepeatedCryptoKeyVersionTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Resources::CryptoKeyVersionTemplate'->new($_) } @$_ ] };

declare 'MapStringCryptoKeyVersionTemplate',
    as HashRef[CryptoKeyVersionTemplate()];

declare 'KeyOperationAttestation',
    as InstanceOf['Google::Cloud::Kms::V1::Resources::KeyOperationAttestation'];

coerce 'KeyOperationAttestation',
    from HashRef, via { 'Google::Cloud::Kms::V1::Resources::KeyOperationAttestation'->new($_) };

declare 'RepeatedKeyOperationAttestation',
    as ArrayRef[KeyOperationAttestation()];

coerce 'RepeatedKeyOperationAttestation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Resources::KeyOperationAttestation'->new($_) } @$_ ] };

declare 'MapStringKeyOperationAttestation',
    as HashRef[KeyOperationAttestation()];

declare 'AttestationFormat',
    as (Int | Str);

declare 'CertificateChains',
    as InstanceOf['Google::Cloud::Kms::V1::Resources::KeyOperationAttestation::CertificateChains'];

coerce 'CertificateChains',
    from HashRef, via { 'Google::Cloud::Kms::V1::Resources::KeyOperationAttestation::CertificateChains'->new($_) };

declare 'RepeatedCertificateChains',
    as ArrayRef[CertificateChains()];

coerce 'RepeatedCertificateChains',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Resources::KeyOperationAttestation::CertificateChains'->new($_) } @$_ ] };

declare 'MapStringCertificateChains',
    as HashRef[CertificateChains()];

declare 'CryptoKeyVersion',
    as InstanceOf['Google::Cloud::Kms::V1::Resources::CryptoKeyVersion'];

coerce 'CryptoKeyVersion',
    from HashRef, via { 'Google::Cloud::Kms::V1::Resources::CryptoKeyVersion'->new($_) };

declare 'RepeatedCryptoKeyVersion',
    as ArrayRef[CryptoKeyVersion()];

coerce 'RepeatedCryptoKeyVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Resources::CryptoKeyVersion'->new($_) } @$_ ] };

declare 'MapStringCryptoKeyVersion',
    as HashRef[CryptoKeyVersion()];

declare 'CryptoKeyVersionAlgorithm',
    as (Int | Str);

declare 'CryptoKeyVersionState',
    as (Int | Str);

declare 'CryptoKeyVersionView',
    as (Int | Str);

declare 'ChecksummedData',
    as InstanceOf['Google::Cloud::Kms::V1::Resources::ChecksummedData'];

coerce 'ChecksummedData',
    from HashRef, via { 'Google::Cloud::Kms::V1::Resources::ChecksummedData'->new($_) };

declare 'RepeatedChecksummedData',
    as ArrayRef[ChecksummedData()];

coerce 'RepeatedChecksummedData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Resources::ChecksummedData'->new($_) } @$_ ] };

declare 'MapStringChecksummedData',
    as HashRef[ChecksummedData()];

declare 'PublicKey',
    as InstanceOf['Google::Cloud::Kms::V1::Resources::PublicKey'];

coerce 'PublicKey',
    from HashRef, via { 'Google::Cloud::Kms::V1::Resources::PublicKey'->new($_) };

declare 'RepeatedPublicKey',
    as ArrayRef[PublicKey()];

coerce 'RepeatedPublicKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Resources::PublicKey'->new($_) } @$_ ] };

declare 'MapStringPublicKey',
    as HashRef[PublicKey()];

declare 'PublicKeyFormat',
    as (Int | Str);

declare 'ImportJob',
    as InstanceOf['Google::Cloud::Kms::V1::Resources::ImportJob'];

coerce 'ImportJob',
    from HashRef, via { 'Google::Cloud::Kms::V1::Resources::ImportJob'->new($_) };

declare 'RepeatedImportJob',
    as ArrayRef[ImportJob()];

coerce 'RepeatedImportJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Resources::ImportJob'->new($_) } @$_ ] };

declare 'MapStringImportJob',
    as HashRef[ImportJob()];

declare 'ImportMethod',
    as (Int | Str);

declare 'ImportJobState',
    as (Int | Str);

declare 'WrappingPublicKey',
    as InstanceOf['Google::Cloud::Kms::V1::Resources::ImportJob::WrappingPublicKey'];

coerce 'WrappingPublicKey',
    from HashRef, via { 'Google::Cloud::Kms::V1::Resources::ImportJob::WrappingPublicKey'->new($_) };

declare 'RepeatedWrappingPublicKey',
    as ArrayRef[WrappingPublicKey()];

coerce 'RepeatedWrappingPublicKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Resources::ImportJob::WrappingPublicKey'->new($_) } @$_ ] };

declare 'MapStringWrappingPublicKey',
    as HashRef[WrappingPublicKey()];

declare 'ExternalProtectionLevelOptions',
    as InstanceOf['Google::Cloud::Kms::V1::Resources::ExternalProtectionLevelOptions'];

coerce 'ExternalProtectionLevelOptions',
    from HashRef, via { 'Google::Cloud::Kms::V1::Resources::ExternalProtectionLevelOptions'->new($_) };

declare 'RepeatedExternalProtectionLevelOptions',
    as ArrayRef[ExternalProtectionLevelOptions()];

coerce 'RepeatedExternalProtectionLevelOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Resources::ExternalProtectionLevelOptions'->new($_) } @$_ ] };

declare 'MapStringExternalProtectionLevelOptions',
    as HashRef[ExternalProtectionLevelOptions()];

declare 'KeyAccessJustificationsPolicy',
    as InstanceOf['Google::Cloud::Kms::V1::Resources::KeyAccessJustificationsPolicy'];

coerce 'KeyAccessJustificationsPolicy',
    from HashRef, via { 'Google::Cloud::Kms::V1::Resources::KeyAccessJustificationsPolicy'->new($_) };

declare 'RepeatedKeyAccessJustificationsPolicy',
    as ArrayRef[KeyAccessJustificationsPolicy()];

coerce 'RepeatedKeyAccessJustificationsPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Resources::KeyAccessJustificationsPolicy'->new($_) } @$_ ] };

declare 'MapStringKeyAccessJustificationsPolicy',
    as HashRef[KeyAccessJustificationsPolicy()];

declare 'RetiredResource',
    as InstanceOf['Google::Cloud::Kms::V1::Resources::RetiredResource'];

coerce 'RetiredResource',
    from HashRef, via { 'Google::Cloud::Kms::V1::Resources::RetiredResource'->new($_) };

declare 'RepeatedRetiredResource',
    as ArrayRef[RetiredResource()];

coerce 'RepeatedRetiredResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Resources::RetiredResource'->new($_) } @$_ ] };

declare 'MapStringRetiredResource',
    as HashRef[RetiredResource()];

1;

__END__

=head1 NAME

Google::Cloud::Kms::V1::Resources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
