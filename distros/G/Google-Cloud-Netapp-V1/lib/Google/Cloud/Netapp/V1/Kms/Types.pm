package Google::Cloud::Netapp::V1::Kms::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetKmsConfigRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Kms::GetKmsConfigRequest'];

coerce 'GetKmsConfigRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Kms::GetKmsConfigRequest'->new($_) };

declare 'RepeatedGetKmsConfigRequest',
    as ArrayRef[GetKmsConfigRequest()];

coerce 'RepeatedGetKmsConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Kms::GetKmsConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetKmsConfigRequest',
    as HashRef[GetKmsConfigRequest()];

declare 'ListKmsConfigsRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Kms::ListKmsConfigsRequest'];

coerce 'ListKmsConfigsRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Kms::ListKmsConfigsRequest'->new($_) };

declare 'RepeatedListKmsConfigsRequest',
    as ArrayRef[ListKmsConfigsRequest()];

coerce 'RepeatedListKmsConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Kms::ListKmsConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListKmsConfigsRequest',
    as HashRef[ListKmsConfigsRequest()];

declare 'ListKmsConfigsResponse',
    as InstanceOf['Google::Cloud::Netapp::V1::Kms::ListKmsConfigsResponse'];

coerce 'ListKmsConfigsResponse',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Kms::ListKmsConfigsResponse'->new($_) };

declare 'RepeatedListKmsConfigsResponse',
    as ArrayRef[ListKmsConfigsResponse()];

coerce 'RepeatedListKmsConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Kms::ListKmsConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListKmsConfigsResponse',
    as HashRef[ListKmsConfigsResponse()];

declare 'CreateKmsConfigRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Kms::CreateKmsConfigRequest'];

coerce 'CreateKmsConfigRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Kms::CreateKmsConfigRequest'->new($_) };

declare 'RepeatedCreateKmsConfigRequest',
    as ArrayRef[CreateKmsConfigRequest()];

coerce 'RepeatedCreateKmsConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Kms::CreateKmsConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateKmsConfigRequest',
    as HashRef[CreateKmsConfigRequest()];

declare 'UpdateKmsConfigRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Kms::UpdateKmsConfigRequest'];

coerce 'UpdateKmsConfigRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Kms::UpdateKmsConfigRequest'->new($_) };

declare 'RepeatedUpdateKmsConfigRequest',
    as ArrayRef[UpdateKmsConfigRequest()];

coerce 'RepeatedUpdateKmsConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Kms::UpdateKmsConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateKmsConfigRequest',
    as HashRef[UpdateKmsConfigRequest()];

declare 'DeleteKmsConfigRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Kms::DeleteKmsConfigRequest'];

coerce 'DeleteKmsConfigRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Kms::DeleteKmsConfigRequest'->new($_) };

declare 'RepeatedDeleteKmsConfigRequest',
    as ArrayRef[DeleteKmsConfigRequest()];

coerce 'RepeatedDeleteKmsConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Kms::DeleteKmsConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteKmsConfigRequest',
    as HashRef[DeleteKmsConfigRequest()];

declare 'EncryptVolumesRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Kms::EncryptVolumesRequest'];

coerce 'EncryptVolumesRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Kms::EncryptVolumesRequest'->new($_) };

declare 'RepeatedEncryptVolumesRequest',
    as ArrayRef[EncryptVolumesRequest()];

coerce 'RepeatedEncryptVolumesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Kms::EncryptVolumesRequest'->new($_) } @$_ ] };

declare 'MapStringEncryptVolumesRequest',
    as HashRef[EncryptVolumesRequest()];

declare 'VerifyKmsConfigRequest',
    as InstanceOf['Google::Cloud::Netapp::V1::Kms::VerifyKmsConfigRequest'];

coerce 'VerifyKmsConfigRequest',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Kms::VerifyKmsConfigRequest'->new($_) };

declare 'RepeatedVerifyKmsConfigRequest',
    as ArrayRef[VerifyKmsConfigRequest()];

coerce 'RepeatedVerifyKmsConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Kms::VerifyKmsConfigRequest'->new($_) } @$_ ] };

declare 'MapStringVerifyKmsConfigRequest',
    as HashRef[VerifyKmsConfigRequest()];

declare 'VerifyKmsConfigResponse',
    as InstanceOf['Google::Cloud::Netapp::V1::Kms::VerifyKmsConfigResponse'];

coerce 'VerifyKmsConfigResponse',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Kms::VerifyKmsConfigResponse'->new($_) };

declare 'RepeatedVerifyKmsConfigResponse',
    as ArrayRef[VerifyKmsConfigResponse()];

coerce 'RepeatedVerifyKmsConfigResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Kms::VerifyKmsConfigResponse'->new($_) } @$_ ] };

declare 'MapStringVerifyKmsConfigResponse',
    as HashRef[VerifyKmsConfigResponse()];

declare 'KmsConfig',
    as InstanceOf['Google::Cloud::Netapp::V1::Kms::KmsConfig'];

coerce 'KmsConfig',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Kms::KmsConfig'->new($_) };

declare 'RepeatedKmsConfig',
    as ArrayRef[KmsConfig()];

coerce 'RepeatedKmsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Kms::KmsConfig'->new($_) } @$_ ] };

declare 'MapStringKmsConfig',
    as HashRef[KmsConfig()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Netapp::V1::Kms::KmsConfig::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Kms::KmsConfig::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Kms::KmsConfig::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Netapp::V1::Kms::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
