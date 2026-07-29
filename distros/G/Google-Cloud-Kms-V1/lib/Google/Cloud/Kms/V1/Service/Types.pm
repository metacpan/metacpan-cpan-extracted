package Google::Cloud::Kms::V1::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListKeyRingsRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::ListKeyRingsRequest'];

coerce 'ListKeyRingsRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::ListKeyRingsRequest'->new($_) };

declare 'RepeatedListKeyRingsRequest',
    as ArrayRef[ListKeyRingsRequest()];

coerce 'RepeatedListKeyRingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::ListKeyRingsRequest'->new($_) } @$_ ] };

declare 'MapStringListKeyRingsRequest',
    as HashRef[ListKeyRingsRequest()];

declare 'ListCryptoKeysRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::ListCryptoKeysRequest'];

coerce 'ListCryptoKeysRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::ListCryptoKeysRequest'->new($_) };

declare 'RepeatedListCryptoKeysRequest',
    as ArrayRef[ListCryptoKeysRequest()];

coerce 'RepeatedListCryptoKeysRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::ListCryptoKeysRequest'->new($_) } @$_ ] };

declare 'MapStringListCryptoKeysRequest',
    as HashRef[ListCryptoKeysRequest()];

declare 'ListCryptoKeyVersionsRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::ListCryptoKeyVersionsRequest'];

coerce 'ListCryptoKeyVersionsRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::ListCryptoKeyVersionsRequest'->new($_) };

declare 'RepeatedListCryptoKeyVersionsRequest',
    as ArrayRef[ListCryptoKeyVersionsRequest()];

coerce 'RepeatedListCryptoKeyVersionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::ListCryptoKeyVersionsRequest'->new($_) } @$_ ] };

declare 'MapStringListCryptoKeyVersionsRequest',
    as HashRef[ListCryptoKeyVersionsRequest()];

declare 'ListImportJobsRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::ListImportJobsRequest'];

coerce 'ListImportJobsRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::ListImportJobsRequest'->new($_) };

declare 'RepeatedListImportJobsRequest',
    as ArrayRef[ListImportJobsRequest()];

coerce 'RepeatedListImportJobsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::ListImportJobsRequest'->new($_) } @$_ ] };

declare 'MapStringListImportJobsRequest',
    as HashRef[ListImportJobsRequest()];

declare 'ListRetiredResourcesRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::ListRetiredResourcesRequest'];

coerce 'ListRetiredResourcesRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::ListRetiredResourcesRequest'->new($_) };

declare 'RepeatedListRetiredResourcesRequest',
    as ArrayRef[ListRetiredResourcesRequest()];

coerce 'RepeatedListRetiredResourcesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::ListRetiredResourcesRequest'->new($_) } @$_ ] };

declare 'MapStringListRetiredResourcesRequest',
    as HashRef[ListRetiredResourcesRequest()];

declare 'ListKeyRingsResponse',
    as InstanceOf['Google::Cloud::Kms::V1::Service::ListKeyRingsResponse'];

coerce 'ListKeyRingsResponse',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::ListKeyRingsResponse'->new($_) };

declare 'RepeatedListKeyRingsResponse',
    as ArrayRef[ListKeyRingsResponse()];

coerce 'RepeatedListKeyRingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::ListKeyRingsResponse'->new($_) } @$_ ] };

declare 'MapStringListKeyRingsResponse',
    as HashRef[ListKeyRingsResponse()];

declare 'ListCryptoKeysResponse',
    as InstanceOf['Google::Cloud::Kms::V1::Service::ListCryptoKeysResponse'];

coerce 'ListCryptoKeysResponse',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::ListCryptoKeysResponse'->new($_) };

declare 'RepeatedListCryptoKeysResponse',
    as ArrayRef[ListCryptoKeysResponse()];

coerce 'RepeatedListCryptoKeysResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::ListCryptoKeysResponse'->new($_) } @$_ ] };

declare 'MapStringListCryptoKeysResponse',
    as HashRef[ListCryptoKeysResponse()];

declare 'ListCryptoKeyVersionsResponse',
    as InstanceOf['Google::Cloud::Kms::V1::Service::ListCryptoKeyVersionsResponse'];

coerce 'ListCryptoKeyVersionsResponse',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::ListCryptoKeyVersionsResponse'->new($_) };

declare 'RepeatedListCryptoKeyVersionsResponse',
    as ArrayRef[ListCryptoKeyVersionsResponse()];

coerce 'RepeatedListCryptoKeyVersionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::ListCryptoKeyVersionsResponse'->new($_) } @$_ ] };

declare 'MapStringListCryptoKeyVersionsResponse',
    as HashRef[ListCryptoKeyVersionsResponse()];

declare 'ListImportJobsResponse',
    as InstanceOf['Google::Cloud::Kms::V1::Service::ListImportJobsResponse'];

coerce 'ListImportJobsResponse',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::ListImportJobsResponse'->new($_) };

declare 'RepeatedListImportJobsResponse',
    as ArrayRef[ListImportJobsResponse()];

coerce 'RepeatedListImportJobsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::ListImportJobsResponse'->new($_) } @$_ ] };

declare 'MapStringListImportJobsResponse',
    as HashRef[ListImportJobsResponse()];

declare 'ListRetiredResourcesResponse',
    as InstanceOf['Google::Cloud::Kms::V1::Service::ListRetiredResourcesResponse'];

coerce 'ListRetiredResourcesResponse',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::ListRetiredResourcesResponse'->new($_) };

declare 'RepeatedListRetiredResourcesResponse',
    as ArrayRef[ListRetiredResourcesResponse()];

coerce 'RepeatedListRetiredResourcesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::ListRetiredResourcesResponse'->new($_) } @$_ ] };

declare 'MapStringListRetiredResourcesResponse',
    as HashRef[ListRetiredResourcesResponse()];

declare 'GetKeyRingRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::GetKeyRingRequest'];

coerce 'GetKeyRingRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::GetKeyRingRequest'->new($_) };

declare 'RepeatedGetKeyRingRequest',
    as ArrayRef[GetKeyRingRequest()];

coerce 'RepeatedGetKeyRingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::GetKeyRingRequest'->new($_) } @$_ ] };

declare 'MapStringGetKeyRingRequest',
    as HashRef[GetKeyRingRequest()];

declare 'GetCryptoKeyRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::GetCryptoKeyRequest'];

coerce 'GetCryptoKeyRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::GetCryptoKeyRequest'->new($_) };

declare 'RepeatedGetCryptoKeyRequest',
    as ArrayRef[GetCryptoKeyRequest()];

coerce 'RepeatedGetCryptoKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::GetCryptoKeyRequest'->new($_) } @$_ ] };

declare 'MapStringGetCryptoKeyRequest',
    as HashRef[GetCryptoKeyRequest()];

declare 'GetCryptoKeyVersionRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::GetCryptoKeyVersionRequest'];

coerce 'GetCryptoKeyVersionRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::GetCryptoKeyVersionRequest'->new($_) };

declare 'RepeatedGetCryptoKeyVersionRequest',
    as ArrayRef[GetCryptoKeyVersionRequest()];

coerce 'RepeatedGetCryptoKeyVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::GetCryptoKeyVersionRequest'->new($_) } @$_ ] };

declare 'MapStringGetCryptoKeyVersionRequest',
    as HashRef[GetCryptoKeyVersionRequest()];

declare 'GetPublicKeyRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::GetPublicKeyRequest'];

coerce 'GetPublicKeyRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::GetPublicKeyRequest'->new($_) };

declare 'RepeatedGetPublicKeyRequest',
    as ArrayRef[GetPublicKeyRequest()];

coerce 'RepeatedGetPublicKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::GetPublicKeyRequest'->new($_) } @$_ ] };

declare 'MapStringGetPublicKeyRequest',
    as HashRef[GetPublicKeyRequest()];

declare 'GetImportJobRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::GetImportJobRequest'];

coerce 'GetImportJobRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::GetImportJobRequest'->new($_) };

declare 'RepeatedGetImportJobRequest',
    as ArrayRef[GetImportJobRequest()];

coerce 'RepeatedGetImportJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::GetImportJobRequest'->new($_) } @$_ ] };

declare 'MapStringGetImportJobRequest',
    as HashRef[GetImportJobRequest()];

declare 'GetRetiredResourceRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::GetRetiredResourceRequest'];

coerce 'GetRetiredResourceRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::GetRetiredResourceRequest'->new($_) };

declare 'RepeatedGetRetiredResourceRequest',
    as ArrayRef[GetRetiredResourceRequest()];

coerce 'RepeatedGetRetiredResourceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::GetRetiredResourceRequest'->new($_) } @$_ ] };

declare 'MapStringGetRetiredResourceRequest',
    as HashRef[GetRetiredResourceRequest()];

declare 'CreateKeyRingRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::CreateKeyRingRequest'];

coerce 'CreateKeyRingRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::CreateKeyRingRequest'->new($_) };

declare 'RepeatedCreateKeyRingRequest',
    as ArrayRef[CreateKeyRingRequest()];

coerce 'RepeatedCreateKeyRingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::CreateKeyRingRequest'->new($_) } @$_ ] };

declare 'MapStringCreateKeyRingRequest',
    as HashRef[CreateKeyRingRequest()];

declare 'CreateCryptoKeyRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::CreateCryptoKeyRequest'];

coerce 'CreateCryptoKeyRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::CreateCryptoKeyRequest'->new($_) };

declare 'RepeatedCreateCryptoKeyRequest',
    as ArrayRef[CreateCryptoKeyRequest()];

coerce 'RepeatedCreateCryptoKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::CreateCryptoKeyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCryptoKeyRequest',
    as HashRef[CreateCryptoKeyRequest()];

declare 'CreateCryptoKeyVersionRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::CreateCryptoKeyVersionRequest'];

coerce 'CreateCryptoKeyVersionRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::CreateCryptoKeyVersionRequest'->new($_) };

declare 'RepeatedCreateCryptoKeyVersionRequest',
    as ArrayRef[CreateCryptoKeyVersionRequest()];

coerce 'RepeatedCreateCryptoKeyVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::CreateCryptoKeyVersionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCryptoKeyVersionRequest',
    as HashRef[CreateCryptoKeyVersionRequest()];

declare 'DeleteCryptoKeyRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::DeleteCryptoKeyRequest'];

coerce 'DeleteCryptoKeyRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::DeleteCryptoKeyRequest'->new($_) };

declare 'RepeatedDeleteCryptoKeyRequest',
    as ArrayRef[DeleteCryptoKeyRequest()];

coerce 'RepeatedDeleteCryptoKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::DeleteCryptoKeyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCryptoKeyRequest',
    as HashRef[DeleteCryptoKeyRequest()];

declare 'DeleteCryptoKeyVersionRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::DeleteCryptoKeyVersionRequest'];

coerce 'DeleteCryptoKeyVersionRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::DeleteCryptoKeyVersionRequest'->new($_) };

declare 'RepeatedDeleteCryptoKeyVersionRequest',
    as ArrayRef[DeleteCryptoKeyVersionRequest()];

coerce 'RepeatedDeleteCryptoKeyVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::DeleteCryptoKeyVersionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCryptoKeyVersionRequest',
    as HashRef[DeleteCryptoKeyVersionRequest()];

declare 'ImportCryptoKeyVersionRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::ImportCryptoKeyVersionRequest'];

coerce 'ImportCryptoKeyVersionRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::ImportCryptoKeyVersionRequest'->new($_) };

declare 'RepeatedImportCryptoKeyVersionRequest',
    as ArrayRef[ImportCryptoKeyVersionRequest()];

coerce 'RepeatedImportCryptoKeyVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::ImportCryptoKeyVersionRequest'->new($_) } @$_ ] };

declare 'MapStringImportCryptoKeyVersionRequest',
    as HashRef[ImportCryptoKeyVersionRequest()];

declare 'ImportTrustedKeyWrappedCryptoKeyVersionRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::ImportTrustedKeyWrappedCryptoKeyVersionRequest'];

coerce 'ImportTrustedKeyWrappedCryptoKeyVersionRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::ImportTrustedKeyWrappedCryptoKeyVersionRequest'->new($_) };

declare 'RepeatedImportTrustedKeyWrappedCryptoKeyVersionRequest',
    as ArrayRef[ImportTrustedKeyWrappedCryptoKeyVersionRequest()];

coerce 'RepeatedImportTrustedKeyWrappedCryptoKeyVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::ImportTrustedKeyWrappedCryptoKeyVersionRequest'->new($_) } @$_ ] };

declare 'MapStringImportTrustedKeyWrappedCryptoKeyVersionRequest',
    as HashRef[ImportTrustedKeyWrappedCryptoKeyVersionRequest()];

declare 'ExportTrustedKeyWrappedCryptoKeyVersionRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::ExportTrustedKeyWrappedCryptoKeyVersionRequest'];

coerce 'ExportTrustedKeyWrappedCryptoKeyVersionRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::ExportTrustedKeyWrappedCryptoKeyVersionRequest'->new($_) };

declare 'RepeatedExportTrustedKeyWrappedCryptoKeyVersionRequest',
    as ArrayRef[ExportTrustedKeyWrappedCryptoKeyVersionRequest()];

coerce 'RepeatedExportTrustedKeyWrappedCryptoKeyVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::ExportTrustedKeyWrappedCryptoKeyVersionRequest'->new($_) } @$_ ] };

declare 'MapStringExportTrustedKeyWrappedCryptoKeyVersionRequest',
    as HashRef[ExportTrustedKeyWrappedCryptoKeyVersionRequest()];

declare 'ExportTrustedKeyWrappedCryptoKeyVersionResponse',
    as InstanceOf['Google::Cloud::Kms::V1::Service::ExportTrustedKeyWrappedCryptoKeyVersionResponse'];

coerce 'ExportTrustedKeyWrappedCryptoKeyVersionResponse',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::ExportTrustedKeyWrappedCryptoKeyVersionResponse'->new($_) };

declare 'RepeatedExportTrustedKeyWrappedCryptoKeyVersionResponse',
    as ArrayRef[ExportTrustedKeyWrappedCryptoKeyVersionResponse()];

coerce 'RepeatedExportTrustedKeyWrappedCryptoKeyVersionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::ExportTrustedKeyWrappedCryptoKeyVersionResponse'->new($_) } @$_ ] };

declare 'MapStringExportTrustedKeyWrappedCryptoKeyVersionResponse',
    as HashRef[ExportTrustedKeyWrappedCryptoKeyVersionResponse()];

declare 'CreateImportJobRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::CreateImportJobRequest'];

coerce 'CreateImportJobRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::CreateImportJobRequest'->new($_) };

declare 'RepeatedCreateImportJobRequest',
    as ArrayRef[CreateImportJobRequest()];

coerce 'RepeatedCreateImportJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::CreateImportJobRequest'->new($_) } @$_ ] };

declare 'MapStringCreateImportJobRequest',
    as HashRef[CreateImportJobRequest()];

declare 'UpdateCryptoKeyRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::UpdateCryptoKeyRequest'];

coerce 'UpdateCryptoKeyRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::UpdateCryptoKeyRequest'->new($_) };

declare 'RepeatedUpdateCryptoKeyRequest',
    as ArrayRef[UpdateCryptoKeyRequest()];

coerce 'RepeatedUpdateCryptoKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::UpdateCryptoKeyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCryptoKeyRequest',
    as HashRef[UpdateCryptoKeyRequest()];

declare 'UpdateCryptoKeyVersionRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::UpdateCryptoKeyVersionRequest'];

coerce 'UpdateCryptoKeyVersionRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::UpdateCryptoKeyVersionRequest'->new($_) };

declare 'RepeatedUpdateCryptoKeyVersionRequest',
    as ArrayRef[UpdateCryptoKeyVersionRequest()];

coerce 'RepeatedUpdateCryptoKeyVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::UpdateCryptoKeyVersionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCryptoKeyVersionRequest',
    as HashRef[UpdateCryptoKeyVersionRequest()];

declare 'UpdateCryptoKeyPrimaryVersionRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::UpdateCryptoKeyPrimaryVersionRequest'];

coerce 'UpdateCryptoKeyPrimaryVersionRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::UpdateCryptoKeyPrimaryVersionRequest'->new($_) };

declare 'RepeatedUpdateCryptoKeyPrimaryVersionRequest',
    as ArrayRef[UpdateCryptoKeyPrimaryVersionRequest()];

coerce 'RepeatedUpdateCryptoKeyPrimaryVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::UpdateCryptoKeyPrimaryVersionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCryptoKeyPrimaryVersionRequest',
    as HashRef[UpdateCryptoKeyPrimaryVersionRequest()];

declare 'DestroyCryptoKeyVersionRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::DestroyCryptoKeyVersionRequest'];

coerce 'DestroyCryptoKeyVersionRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::DestroyCryptoKeyVersionRequest'->new($_) };

declare 'RepeatedDestroyCryptoKeyVersionRequest',
    as ArrayRef[DestroyCryptoKeyVersionRequest()];

coerce 'RepeatedDestroyCryptoKeyVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::DestroyCryptoKeyVersionRequest'->new($_) } @$_ ] };

declare 'MapStringDestroyCryptoKeyVersionRequest',
    as HashRef[DestroyCryptoKeyVersionRequest()];

declare 'RestoreCryptoKeyVersionRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::RestoreCryptoKeyVersionRequest'];

coerce 'RestoreCryptoKeyVersionRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::RestoreCryptoKeyVersionRequest'->new($_) };

declare 'RepeatedRestoreCryptoKeyVersionRequest',
    as ArrayRef[RestoreCryptoKeyVersionRequest()];

coerce 'RepeatedRestoreCryptoKeyVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::RestoreCryptoKeyVersionRequest'->new($_) } @$_ ] };

declare 'MapStringRestoreCryptoKeyVersionRequest',
    as HashRef[RestoreCryptoKeyVersionRequest()];

declare 'EncryptRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::EncryptRequest'];

coerce 'EncryptRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::EncryptRequest'->new($_) };

declare 'RepeatedEncryptRequest',
    as ArrayRef[EncryptRequest()];

coerce 'RepeatedEncryptRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::EncryptRequest'->new($_) } @$_ ] };

declare 'MapStringEncryptRequest',
    as HashRef[EncryptRequest()];

declare 'DecryptRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::DecryptRequest'];

coerce 'DecryptRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::DecryptRequest'->new($_) };

declare 'RepeatedDecryptRequest',
    as ArrayRef[DecryptRequest()];

coerce 'RepeatedDecryptRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::DecryptRequest'->new($_) } @$_ ] };

declare 'MapStringDecryptRequest',
    as HashRef[DecryptRequest()];

declare 'RawEncryptRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::RawEncryptRequest'];

coerce 'RawEncryptRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::RawEncryptRequest'->new($_) };

declare 'RepeatedRawEncryptRequest',
    as ArrayRef[RawEncryptRequest()];

coerce 'RepeatedRawEncryptRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::RawEncryptRequest'->new($_) } @$_ ] };

declare 'MapStringRawEncryptRequest',
    as HashRef[RawEncryptRequest()];

declare 'RawDecryptRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::RawDecryptRequest'];

coerce 'RawDecryptRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::RawDecryptRequest'->new($_) };

declare 'RepeatedRawDecryptRequest',
    as ArrayRef[RawDecryptRequest()];

coerce 'RepeatedRawDecryptRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::RawDecryptRequest'->new($_) } @$_ ] };

declare 'MapStringRawDecryptRequest',
    as HashRef[RawDecryptRequest()];

declare 'AsymmetricSignRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::AsymmetricSignRequest'];

coerce 'AsymmetricSignRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::AsymmetricSignRequest'->new($_) };

declare 'RepeatedAsymmetricSignRequest',
    as ArrayRef[AsymmetricSignRequest()];

coerce 'RepeatedAsymmetricSignRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::AsymmetricSignRequest'->new($_) } @$_ ] };

declare 'MapStringAsymmetricSignRequest',
    as HashRef[AsymmetricSignRequest()];

declare 'AsymmetricDecryptRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::AsymmetricDecryptRequest'];

coerce 'AsymmetricDecryptRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::AsymmetricDecryptRequest'->new($_) };

declare 'RepeatedAsymmetricDecryptRequest',
    as ArrayRef[AsymmetricDecryptRequest()];

coerce 'RepeatedAsymmetricDecryptRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::AsymmetricDecryptRequest'->new($_) } @$_ ] };

declare 'MapStringAsymmetricDecryptRequest',
    as HashRef[AsymmetricDecryptRequest()];

declare 'MacSignRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::MacSignRequest'];

coerce 'MacSignRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::MacSignRequest'->new($_) };

declare 'RepeatedMacSignRequest',
    as ArrayRef[MacSignRequest()];

coerce 'RepeatedMacSignRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::MacSignRequest'->new($_) } @$_ ] };

declare 'MapStringMacSignRequest',
    as HashRef[MacSignRequest()];

declare 'MacVerifyRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::MacVerifyRequest'];

coerce 'MacVerifyRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::MacVerifyRequest'->new($_) };

declare 'RepeatedMacVerifyRequest',
    as ArrayRef[MacVerifyRequest()];

coerce 'RepeatedMacVerifyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::MacVerifyRequest'->new($_) } @$_ ] };

declare 'MapStringMacVerifyRequest',
    as HashRef[MacVerifyRequest()];

declare 'DecapsulateRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::DecapsulateRequest'];

coerce 'DecapsulateRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::DecapsulateRequest'->new($_) };

declare 'RepeatedDecapsulateRequest',
    as ArrayRef[DecapsulateRequest()];

coerce 'RepeatedDecapsulateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::DecapsulateRequest'->new($_) } @$_ ] };

declare 'MapStringDecapsulateRequest',
    as HashRef[DecapsulateRequest()];

declare 'GenerateRandomBytesRequest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::GenerateRandomBytesRequest'];

coerce 'GenerateRandomBytesRequest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::GenerateRandomBytesRequest'->new($_) };

declare 'RepeatedGenerateRandomBytesRequest',
    as ArrayRef[GenerateRandomBytesRequest()];

coerce 'RepeatedGenerateRandomBytesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::GenerateRandomBytesRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateRandomBytesRequest',
    as HashRef[GenerateRandomBytesRequest()];

declare 'EncryptResponse',
    as InstanceOf['Google::Cloud::Kms::V1::Service::EncryptResponse'];

coerce 'EncryptResponse',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::EncryptResponse'->new($_) };

declare 'RepeatedEncryptResponse',
    as ArrayRef[EncryptResponse()];

coerce 'RepeatedEncryptResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::EncryptResponse'->new($_) } @$_ ] };

declare 'MapStringEncryptResponse',
    as HashRef[EncryptResponse()];

declare 'DecryptResponse',
    as InstanceOf['Google::Cloud::Kms::V1::Service::DecryptResponse'];

coerce 'DecryptResponse',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::DecryptResponse'->new($_) };

declare 'RepeatedDecryptResponse',
    as ArrayRef[DecryptResponse()];

coerce 'RepeatedDecryptResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::DecryptResponse'->new($_) } @$_ ] };

declare 'MapStringDecryptResponse',
    as HashRef[DecryptResponse()];

declare 'RawEncryptResponse',
    as InstanceOf['Google::Cloud::Kms::V1::Service::RawEncryptResponse'];

coerce 'RawEncryptResponse',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::RawEncryptResponse'->new($_) };

declare 'RepeatedRawEncryptResponse',
    as ArrayRef[RawEncryptResponse()];

coerce 'RepeatedRawEncryptResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::RawEncryptResponse'->new($_) } @$_ ] };

declare 'MapStringRawEncryptResponse',
    as HashRef[RawEncryptResponse()];

declare 'RawDecryptResponse',
    as InstanceOf['Google::Cloud::Kms::V1::Service::RawDecryptResponse'];

coerce 'RawDecryptResponse',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::RawDecryptResponse'->new($_) };

declare 'RepeatedRawDecryptResponse',
    as ArrayRef[RawDecryptResponse()];

coerce 'RepeatedRawDecryptResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::RawDecryptResponse'->new($_) } @$_ ] };

declare 'MapStringRawDecryptResponse',
    as HashRef[RawDecryptResponse()];

declare 'AsymmetricSignResponse',
    as InstanceOf['Google::Cloud::Kms::V1::Service::AsymmetricSignResponse'];

coerce 'AsymmetricSignResponse',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::AsymmetricSignResponse'->new($_) };

declare 'RepeatedAsymmetricSignResponse',
    as ArrayRef[AsymmetricSignResponse()];

coerce 'RepeatedAsymmetricSignResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::AsymmetricSignResponse'->new($_) } @$_ ] };

declare 'MapStringAsymmetricSignResponse',
    as HashRef[AsymmetricSignResponse()];

declare 'AsymmetricDecryptResponse',
    as InstanceOf['Google::Cloud::Kms::V1::Service::AsymmetricDecryptResponse'];

coerce 'AsymmetricDecryptResponse',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::AsymmetricDecryptResponse'->new($_) };

declare 'RepeatedAsymmetricDecryptResponse',
    as ArrayRef[AsymmetricDecryptResponse()];

coerce 'RepeatedAsymmetricDecryptResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::AsymmetricDecryptResponse'->new($_) } @$_ ] };

declare 'MapStringAsymmetricDecryptResponse',
    as HashRef[AsymmetricDecryptResponse()];

declare 'MacSignResponse',
    as InstanceOf['Google::Cloud::Kms::V1::Service::MacSignResponse'];

coerce 'MacSignResponse',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::MacSignResponse'->new($_) };

declare 'RepeatedMacSignResponse',
    as ArrayRef[MacSignResponse()];

coerce 'RepeatedMacSignResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::MacSignResponse'->new($_) } @$_ ] };

declare 'MapStringMacSignResponse',
    as HashRef[MacSignResponse()];

declare 'MacVerifyResponse',
    as InstanceOf['Google::Cloud::Kms::V1::Service::MacVerifyResponse'];

coerce 'MacVerifyResponse',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::MacVerifyResponse'->new($_) };

declare 'RepeatedMacVerifyResponse',
    as ArrayRef[MacVerifyResponse()];

coerce 'RepeatedMacVerifyResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::MacVerifyResponse'->new($_) } @$_ ] };

declare 'MapStringMacVerifyResponse',
    as HashRef[MacVerifyResponse()];

declare 'DecapsulateResponse',
    as InstanceOf['Google::Cloud::Kms::V1::Service::DecapsulateResponse'];

coerce 'DecapsulateResponse',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::DecapsulateResponse'->new($_) };

declare 'RepeatedDecapsulateResponse',
    as ArrayRef[DecapsulateResponse()];

coerce 'RepeatedDecapsulateResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::DecapsulateResponse'->new($_) } @$_ ] };

declare 'MapStringDecapsulateResponse',
    as HashRef[DecapsulateResponse()];

declare 'GenerateRandomBytesResponse',
    as InstanceOf['Google::Cloud::Kms::V1::Service::GenerateRandomBytesResponse'];

coerce 'GenerateRandomBytesResponse',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::GenerateRandomBytesResponse'->new($_) };

declare 'RepeatedGenerateRandomBytesResponse',
    as ArrayRef[GenerateRandomBytesResponse()];

coerce 'RepeatedGenerateRandomBytesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::GenerateRandomBytesResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateRandomBytesResponse',
    as HashRef[GenerateRandomBytesResponse()];

declare 'Digest',
    as InstanceOf['Google::Cloud::Kms::V1::Service::Digest'];

coerce 'Digest',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::Digest'->new($_) };

declare 'RepeatedDigest',
    as ArrayRef[Digest()];

coerce 'RepeatedDigest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::Digest'->new($_) } @$_ ] };

declare 'MapStringDigest',
    as HashRef[Digest()];

declare 'LocationMetadata',
    as InstanceOf['Google::Cloud::Kms::V1::Service::LocationMetadata'];

coerce 'LocationMetadata',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::LocationMetadata'->new($_) };

declare 'RepeatedLocationMetadata',
    as ArrayRef[LocationMetadata()];

coerce 'RepeatedLocationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::LocationMetadata'->new($_) } @$_ ] };

declare 'MapStringLocationMetadata',
    as HashRef[LocationMetadata()];

declare 'DeleteCryptoKeyMetadata',
    as InstanceOf['Google::Cloud::Kms::V1::Service::DeleteCryptoKeyMetadata'];

coerce 'DeleteCryptoKeyMetadata',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::DeleteCryptoKeyMetadata'->new($_) };

declare 'RepeatedDeleteCryptoKeyMetadata',
    as ArrayRef[DeleteCryptoKeyMetadata()];

coerce 'RepeatedDeleteCryptoKeyMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::DeleteCryptoKeyMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteCryptoKeyMetadata',
    as HashRef[DeleteCryptoKeyMetadata()];

declare 'DeleteCryptoKeyVersionMetadata',
    as InstanceOf['Google::Cloud::Kms::V1::Service::DeleteCryptoKeyVersionMetadata'];

coerce 'DeleteCryptoKeyVersionMetadata',
    from HashRef, via { 'Google::Cloud::Kms::V1::Service::DeleteCryptoKeyVersionMetadata'->new($_) };

declare 'RepeatedDeleteCryptoKeyVersionMetadata',
    as ArrayRef[DeleteCryptoKeyVersionMetadata()];

coerce 'RepeatedDeleteCryptoKeyVersionMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Kms::V1::Service::DeleteCryptoKeyVersionMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteCryptoKeyVersionMetadata',
    as HashRef[DeleteCryptoKeyVersionMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Kms::V1::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
