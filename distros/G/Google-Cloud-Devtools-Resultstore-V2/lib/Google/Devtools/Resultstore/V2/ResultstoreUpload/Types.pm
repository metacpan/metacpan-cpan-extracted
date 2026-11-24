package Google::Devtools::Resultstore::V2::ResultstoreUpload::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateInvocationRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreUpload::CreateInvocationRequest'];

coerce 'CreateInvocationRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::CreateInvocationRequest'->new($_) };

declare 'RepeatedCreateInvocationRequest',
    as ArrayRef[CreateInvocationRequest()];

coerce 'RepeatedCreateInvocationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::CreateInvocationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateInvocationRequest',
    as HashRef[CreateInvocationRequest()];

declare 'UpdateInvocationRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreUpload::UpdateInvocationRequest'];

coerce 'UpdateInvocationRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::UpdateInvocationRequest'->new($_) };

declare 'RepeatedUpdateInvocationRequest',
    as ArrayRef[UpdateInvocationRequest()];

coerce 'RepeatedUpdateInvocationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::UpdateInvocationRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateInvocationRequest',
    as HashRef[UpdateInvocationRequest()];

declare 'MergeInvocationRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreUpload::MergeInvocationRequest'];

coerce 'MergeInvocationRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::MergeInvocationRequest'->new($_) };

declare 'RepeatedMergeInvocationRequest',
    as ArrayRef[MergeInvocationRequest()];

coerce 'RepeatedMergeInvocationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::MergeInvocationRequest'->new($_) } @$_ ] };

declare 'MapStringMergeInvocationRequest',
    as HashRef[MergeInvocationRequest()];

declare 'TouchInvocationRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreUpload::TouchInvocationRequest'];

coerce 'TouchInvocationRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::TouchInvocationRequest'->new($_) };

declare 'RepeatedTouchInvocationRequest',
    as ArrayRef[TouchInvocationRequest()];

coerce 'RepeatedTouchInvocationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::TouchInvocationRequest'->new($_) } @$_ ] };

declare 'MapStringTouchInvocationRequest',
    as HashRef[TouchInvocationRequest()];

declare 'TouchInvocationResponse',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreUpload::TouchInvocationResponse'];

coerce 'TouchInvocationResponse',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::TouchInvocationResponse'->new($_) };

declare 'RepeatedTouchInvocationResponse',
    as ArrayRef[TouchInvocationResponse()];

coerce 'RepeatedTouchInvocationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::TouchInvocationResponse'->new($_) } @$_ ] };

declare 'MapStringTouchInvocationResponse',
    as HashRef[TouchInvocationResponse()];

declare 'DeleteInvocationRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreUpload::DeleteInvocationRequest'];

coerce 'DeleteInvocationRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::DeleteInvocationRequest'->new($_) };

declare 'RepeatedDeleteInvocationRequest',
    as ArrayRef[DeleteInvocationRequest()];

coerce 'RepeatedDeleteInvocationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::DeleteInvocationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteInvocationRequest',
    as HashRef[DeleteInvocationRequest()];

declare 'FinalizeInvocationRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreUpload::FinalizeInvocationRequest'];

coerce 'FinalizeInvocationRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::FinalizeInvocationRequest'->new($_) };

declare 'RepeatedFinalizeInvocationRequest',
    as ArrayRef[FinalizeInvocationRequest()];

coerce 'RepeatedFinalizeInvocationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::FinalizeInvocationRequest'->new($_) } @$_ ] };

declare 'MapStringFinalizeInvocationRequest',
    as HashRef[FinalizeInvocationRequest()];

declare 'FinalizeInvocationResponse',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreUpload::FinalizeInvocationResponse'];

coerce 'FinalizeInvocationResponse',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::FinalizeInvocationResponse'->new($_) };

declare 'RepeatedFinalizeInvocationResponse',
    as ArrayRef[FinalizeInvocationResponse()];

coerce 'RepeatedFinalizeInvocationResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::FinalizeInvocationResponse'->new($_) } @$_ ] };

declare 'MapStringFinalizeInvocationResponse',
    as HashRef[FinalizeInvocationResponse()];

declare 'CreateTargetRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreUpload::CreateTargetRequest'];

coerce 'CreateTargetRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::CreateTargetRequest'->new($_) };

declare 'RepeatedCreateTargetRequest',
    as ArrayRef[CreateTargetRequest()];

coerce 'RepeatedCreateTargetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::CreateTargetRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTargetRequest',
    as HashRef[CreateTargetRequest()];

declare 'UpdateTargetRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreUpload::UpdateTargetRequest'];

coerce 'UpdateTargetRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::UpdateTargetRequest'->new($_) };

declare 'RepeatedUpdateTargetRequest',
    as ArrayRef[UpdateTargetRequest()];

coerce 'RepeatedUpdateTargetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::UpdateTargetRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTargetRequest',
    as HashRef[UpdateTargetRequest()];

declare 'MergeTargetRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreUpload::MergeTargetRequest'];

coerce 'MergeTargetRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::MergeTargetRequest'->new($_) };

declare 'RepeatedMergeTargetRequest',
    as ArrayRef[MergeTargetRequest()];

coerce 'RepeatedMergeTargetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::MergeTargetRequest'->new($_) } @$_ ] };

declare 'MapStringMergeTargetRequest',
    as HashRef[MergeTargetRequest()];

declare 'FinalizeTargetRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreUpload::FinalizeTargetRequest'];

coerce 'FinalizeTargetRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::FinalizeTargetRequest'->new($_) };

declare 'RepeatedFinalizeTargetRequest',
    as ArrayRef[FinalizeTargetRequest()];

coerce 'RepeatedFinalizeTargetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::FinalizeTargetRequest'->new($_) } @$_ ] };

declare 'MapStringFinalizeTargetRequest',
    as HashRef[FinalizeTargetRequest()];

declare 'FinalizeTargetResponse',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreUpload::FinalizeTargetResponse'];

coerce 'FinalizeTargetResponse',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::FinalizeTargetResponse'->new($_) };

declare 'RepeatedFinalizeTargetResponse',
    as ArrayRef[FinalizeTargetResponse()];

coerce 'RepeatedFinalizeTargetResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::FinalizeTargetResponse'->new($_) } @$_ ] };

declare 'MapStringFinalizeTargetResponse',
    as HashRef[FinalizeTargetResponse()];

declare 'CreateConfiguredTargetRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreUpload::CreateConfiguredTargetRequest'];

coerce 'CreateConfiguredTargetRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::CreateConfiguredTargetRequest'->new($_) };

declare 'RepeatedCreateConfiguredTargetRequest',
    as ArrayRef[CreateConfiguredTargetRequest()];

coerce 'RepeatedCreateConfiguredTargetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::CreateConfiguredTargetRequest'->new($_) } @$_ ] };

declare 'MapStringCreateConfiguredTargetRequest',
    as HashRef[CreateConfiguredTargetRequest()];

declare 'UpdateConfiguredTargetRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreUpload::UpdateConfiguredTargetRequest'];

coerce 'UpdateConfiguredTargetRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::UpdateConfiguredTargetRequest'->new($_) };

declare 'RepeatedUpdateConfiguredTargetRequest',
    as ArrayRef[UpdateConfiguredTargetRequest()];

coerce 'RepeatedUpdateConfiguredTargetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::UpdateConfiguredTargetRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateConfiguredTargetRequest',
    as HashRef[UpdateConfiguredTargetRequest()];

declare 'MergeConfiguredTargetRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreUpload::MergeConfiguredTargetRequest'];

coerce 'MergeConfiguredTargetRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::MergeConfiguredTargetRequest'->new($_) };

declare 'RepeatedMergeConfiguredTargetRequest',
    as ArrayRef[MergeConfiguredTargetRequest()];

coerce 'RepeatedMergeConfiguredTargetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::MergeConfiguredTargetRequest'->new($_) } @$_ ] };

declare 'MapStringMergeConfiguredTargetRequest',
    as HashRef[MergeConfiguredTargetRequest()];

declare 'FinalizeConfiguredTargetRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreUpload::FinalizeConfiguredTargetRequest'];

coerce 'FinalizeConfiguredTargetRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::FinalizeConfiguredTargetRequest'->new($_) };

declare 'RepeatedFinalizeConfiguredTargetRequest',
    as ArrayRef[FinalizeConfiguredTargetRequest()];

coerce 'RepeatedFinalizeConfiguredTargetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::FinalizeConfiguredTargetRequest'->new($_) } @$_ ] };

declare 'MapStringFinalizeConfiguredTargetRequest',
    as HashRef[FinalizeConfiguredTargetRequest()];

declare 'FinalizeConfiguredTargetResponse',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreUpload::FinalizeConfiguredTargetResponse'];

coerce 'FinalizeConfiguredTargetResponse',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::FinalizeConfiguredTargetResponse'->new($_) };

declare 'RepeatedFinalizeConfiguredTargetResponse',
    as ArrayRef[FinalizeConfiguredTargetResponse()];

coerce 'RepeatedFinalizeConfiguredTargetResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::FinalizeConfiguredTargetResponse'->new($_) } @$_ ] };

declare 'MapStringFinalizeConfiguredTargetResponse',
    as HashRef[FinalizeConfiguredTargetResponse()];

declare 'CreateActionRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreUpload::CreateActionRequest'];

coerce 'CreateActionRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::CreateActionRequest'->new($_) };

declare 'RepeatedCreateActionRequest',
    as ArrayRef[CreateActionRequest()];

coerce 'RepeatedCreateActionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::CreateActionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateActionRequest',
    as HashRef[CreateActionRequest()];

declare 'UpdateActionRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreUpload::UpdateActionRequest'];

coerce 'UpdateActionRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::UpdateActionRequest'->new($_) };

declare 'RepeatedUpdateActionRequest',
    as ArrayRef[UpdateActionRequest()];

coerce 'RepeatedUpdateActionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::UpdateActionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateActionRequest',
    as HashRef[UpdateActionRequest()];

declare 'MergeActionRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreUpload::MergeActionRequest'];

coerce 'MergeActionRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::MergeActionRequest'->new($_) };

declare 'RepeatedMergeActionRequest',
    as ArrayRef[MergeActionRequest()];

coerce 'RepeatedMergeActionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::MergeActionRequest'->new($_) } @$_ ] };

declare 'MapStringMergeActionRequest',
    as HashRef[MergeActionRequest()];

declare 'CreateConfigurationRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreUpload::CreateConfigurationRequest'];

coerce 'CreateConfigurationRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::CreateConfigurationRequest'->new($_) };

declare 'RepeatedCreateConfigurationRequest',
    as ArrayRef[CreateConfigurationRequest()];

coerce 'RepeatedCreateConfigurationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::CreateConfigurationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateConfigurationRequest',
    as HashRef[CreateConfigurationRequest()];

declare 'UpdateConfigurationRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreUpload::UpdateConfigurationRequest'];

coerce 'UpdateConfigurationRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::UpdateConfigurationRequest'->new($_) };

declare 'RepeatedUpdateConfigurationRequest',
    as ArrayRef[UpdateConfigurationRequest()];

coerce 'RepeatedUpdateConfigurationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::UpdateConfigurationRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateConfigurationRequest',
    as HashRef[UpdateConfigurationRequest()];

declare 'CreateFileSetRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreUpload::CreateFileSetRequest'];

coerce 'CreateFileSetRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::CreateFileSetRequest'->new($_) };

declare 'RepeatedCreateFileSetRequest',
    as ArrayRef[CreateFileSetRequest()];

coerce 'RepeatedCreateFileSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::CreateFileSetRequest'->new($_) } @$_ ] };

declare 'MapStringCreateFileSetRequest',
    as HashRef[CreateFileSetRequest()];

declare 'UpdateFileSetRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreUpload::UpdateFileSetRequest'];

coerce 'UpdateFileSetRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::UpdateFileSetRequest'->new($_) };

declare 'RepeatedUpdateFileSetRequest',
    as ArrayRef[UpdateFileSetRequest()];

coerce 'RepeatedUpdateFileSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::UpdateFileSetRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateFileSetRequest',
    as HashRef[UpdateFileSetRequest()];

declare 'MergeFileSetRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreUpload::MergeFileSetRequest'];

coerce 'MergeFileSetRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::MergeFileSetRequest'->new($_) };

declare 'RepeatedMergeFileSetRequest',
    as ArrayRef[MergeFileSetRequest()];

coerce 'RepeatedMergeFileSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::MergeFileSetRequest'->new($_) } @$_ ] };

declare 'MapStringMergeFileSetRequest',
    as HashRef[MergeFileSetRequest()];

declare 'UploadBatchRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreUpload::UploadBatchRequest'];

coerce 'UploadBatchRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::UploadBatchRequest'->new($_) };

declare 'RepeatedUploadBatchRequest',
    as ArrayRef[UploadBatchRequest()];

coerce 'RepeatedUploadBatchRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::UploadBatchRequest'->new($_) } @$_ ] };

declare 'MapStringUploadBatchRequest',
    as HashRef[UploadBatchRequest()];

declare 'UploadBatchResponse',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreUpload::UploadBatchResponse'];

coerce 'UploadBatchResponse',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::UploadBatchResponse'->new($_) };

declare 'RepeatedUploadBatchResponse',
    as ArrayRef[UploadBatchResponse()];

coerce 'RepeatedUploadBatchResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::UploadBatchResponse'->new($_) } @$_ ] };

declare 'MapStringUploadBatchResponse',
    as HashRef[UploadBatchResponse()];

declare 'UploadRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreUpload::UploadRequest'];

coerce 'UploadRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::UploadRequest'->new($_) };

declare 'RepeatedUploadRequest',
    as ArrayRef[UploadRequest()];

coerce 'RepeatedUploadRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::UploadRequest'->new($_) } @$_ ] };

declare 'MapStringUploadRequest',
    as HashRef[UploadRequest()];

declare 'UploadOperation',
    as (Int | Str);

declare 'Id',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreUpload::UploadRequest::Id'];

coerce 'Id',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::UploadRequest::Id'->new($_) };

declare 'RepeatedId',
    as ArrayRef[Id()];

coerce 'RepeatedId',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::UploadRequest::Id'->new($_) } @$_ ] };

declare 'MapStringId',
    as HashRef[Id()];

declare 'GetInvocationUploadMetadataRequest',
    as InstanceOf['Google::Devtools::Resultstore::V2::ResultstoreUpload::GetInvocationUploadMetadataRequest'];

coerce 'GetInvocationUploadMetadataRequest',
    from HashRef, via { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::GetInvocationUploadMetadataRequest'->new($_) };

declare 'RepeatedGetInvocationUploadMetadataRequest',
    as ArrayRef[GetInvocationUploadMetadataRequest()];

coerce 'RepeatedGetInvocationUploadMetadataRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Resultstore::V2::ResultstoreUpload::GetInvocationUploadMetadataRequest'->new($_) } @$_ ] };

declare 'MapStringGetInvocationUploadMetadataRequest',
    as HashRef[GetInvocationUploadMetadataRequest()];

1;

__END__

=head1 NAME

Google::Devtools::Resultstore::V2::ResultstoreUpload::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
