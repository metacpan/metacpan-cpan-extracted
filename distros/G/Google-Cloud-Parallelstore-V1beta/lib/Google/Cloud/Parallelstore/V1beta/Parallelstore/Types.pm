package Google::Cloud::Parallelstore::V1beta::Parallelstore::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TransferType',
    as (Int | Str);

declare 'FileStripeLevel',
    as (Int | Str);

declare 'DirectoryStripeLevel',
    as (Int | Str);

declare 'DeploymentType',
    as (Int | Str);

declare 'Instance',
    as InstanceOf['Google::Cloud::Parallelstore::V1beta::Parallelstore::Instance'];

coerce 'Instance',
    from HashRef, via { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::Instance'->new($_) };

declare 'RepeatedInstance',
    as ArrayRef[Instance()];

coerce 'RepeatedInstance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::Instance'->new($_) } @$_ ] };

declare 'MapStringInstance',
    as HashRef[Instance()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Parallelstore::V1beta::Parallelstore::Instance::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::Instance::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::Instance::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'TransferMetadataOptions',
    as InstanceOf['Google::Cloud::Parallelstore::V1beta::Parallelstore::TransferMetadataOptions'];

coerce 'TransferMetadataOptions',
    from HashRef, via { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::TransferMetadataOptions'->new($_) };

declare 'RepeatedTransferMetadataOptions',
    as ArrayRef[TransferMetadataOptions()];

coerce 'RepeatedTransferMetadataOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::TransferMetadataOptions'->new($_) } @$_ ] };

declare 'MapStringTransferMetadataOptions',
    as HashRef[TransferMetadataOptions()];

declare 'Uid',
    as (Int | Str);

declare 'Gid',
    as (Int | Str);

declare 'Mode',
    as (Int | Str);

declare 'ListInstancesRequest',
    as InstanceOf['Google::Cloud::Parallelstore::V1beta::Parallelstore::ListInstancesRequest'];

coerce 'ListInstancesRequest',
    from HashRef, via { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::ListInstancesRequest'->new($_) };

declare 'RepeatedListInstancesRequest',
    as ArrayRef[ListInstancesRequest()];

coerce 'RepeatedListInstancesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::ListInstancesRequest'->new($_) } @$_ ] };

declare 'MapStringListInstancesRequest',
    as HashRef[ListInstancesRequest()];

declare 'ListInstancesResponse',
    as InstanceOf['Google::Cloud::Parallelstore::V1beta::Parallelstore::ListInstancesResponse'];

coerce 'ListInstancesResponse',
    from HashRef, via { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::ListInstancesResponse'->new($_) };

declare 'RepeatedListInstancesResponse',
    as ArrayRef[ListInstancesResponse()];

coerce 'RepeatedListInstancesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::ListInstancesResponse'->new($_) } @$_ ] };

declare 'MapStringListInstancesResponse',
    as HashRef[ListInstancesResponse()];

declare 'GetInstanceRequest',
    as InstanceOf['Google::Cloud::Parallelstore::V1beta::Parallelstore::GetInstanceRequest'];

coerce 'GetInstanceRequest',
    from HashRef, via { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::GetInstanceRequest'->new($_) };

declare 'RepeatedGetInstanceRequest',
    as ArrayRef[GetInstanceRequest()];

coerce 'RepeatedGetInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::GetInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringGetInstanceRequest',
    as HashRef[GetInstanceRequest()];

declare 'CreateInstanceRequest',
    as InstanceOf['Google::Cloud::Parallelstore::V1beta::Parallelstore::CreateInstanceRequest'];

coerce 'CreateInstanceRequest',
    from HashRef, via { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::CreateInstanceRequest'->new($_) };

declare 'RepeatedCreateInstanceRequest',
    as ArrayRef[CreateInstanceRequest()];

coerce 'RepeatedCreateInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::CreateInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateInstanceRequest',
    as HashRef[CreateInstanceRequest()];

declare 'UpdateInstanceRequest',
    as InstanceOf['Google::Cloud::Parallelstore::V1beta::Parallelstore::UpdateInstanceRequest'];

coerce 'UpdateInstanceRequest',
    from HashRef, via { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::UpdateInstanceRequest'->new($_) };

declare 'RepeatedUpdateInstanceRequest',
    as ArrayRef[UpdateInstanceRequest()];

coerce 'RepeatedUpdateInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::UpdateInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateInstanceRequest',
    as HashRef[UpdateInstanceRequest()];

declare 'DeleteInstanceRequest',
    as InstanceOf['Google::Cloud::Parallelstore::V1beta::Parallelstore::DeleteInstanceRequest'];

coerce 'DeleteInstanceRequest',
    from HashRef, via { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::DeleteInstanceRequest'->new($_) };

declare 'RepeatedDeleteInstanceRequest',
    as ArrayRef[DeleteInstanceRequest()];

coerce 'RepeatedDeleteInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::DeleteInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteInstanceRequest',
    as HashRef[DeleteInstanceRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Parallelstore::V1beta::Parallelstore::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'SourceGcsBucket',
    as InstanceOf['Google::Cloud::Parallelstore::V1beta::Parallelstore::SourceGcsBucket'];

coerce 'SourceGcsBucket',
    from HashRef, via { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::SourceGcsBucket'->new($_) };

declare 'RepeatedSourceGcsBucket',
    as ArrayRef[SourceGcsBucket()];

coerce 'RepeatedSourceGcsBucket',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::SourceGcsBucket'->new($_) } @$_ ] };

declare 'MapStringSourceGcsBucket',
    as HashRef[SourceGcsBucket()];

declare 'DestinationGcsBucket',
    as InstanceOf['Google::Cloud::Parallelstore::V1beta::Parallelstore::DestinationGcsBucket'];

coerce 'DestinationGcsBucket',
    from HashRef, via { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::DestinationGcsBucket'->new($_) };

declare 'RepeatedDestinationGcsBucket',
    as ArrayRef[DestinationGcsBucket()];

coerce 'RepeatedDestinationGcsBucket',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::DestinationGcsBucket'->new($_) } @$_ ] };

declare 'MapStringDestinationGcsBucket',
    as HashRef[DestinationGcsBucket()];

declare 'SourceParallelstore',
    as InstanceOf['Google::Cloud::Parallelstore::V1beta::Parallelstore::SourceParallelstore'];

coerce 'SourceParallelstore',
    from HashRef, via { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::SourceParallelstore'->new($_) };

declare 'RepeatedSourceParallelstore',
    as ArrayRef[SourceParallelstore()];

coerce 'RepeatedSourceParallelstore',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::SourceParallelstore'->new($_) } @$_ ] };

declare 'MapStringSourceParallelstore',
    as HashRef[SourceParallelstore()];

declare 'DestinationParallelstore',
    as InstanceOf['Google::Cloud::Parallelstore::V1beta::Parallelstore::DestinationParallelstore'];

coerce 'DestinationParallelstore',
    from HashRef, via { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::DestinationParallelstore'->new($_) };

declare 'RepeatedDestinationParallelstore',
    as ArrayRef[DestinationParallelstore()];

coerce 'RepeatedDestinationParallelstore',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::DestinationParallelstore'->new($_) } @$_ ] };

declare 'MapStringDestinationParallelstore',
    as HashRef[DestinationParallelstore()];

declare 'ImportDataRequest',
    as InstanceOf['Google::Cloud::Parallelstore::V1beta::Parallelstore::ImportDataRequest'];

coerce 'ImportDataRequest',
    from HashRef, via { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::ImportDataRequest'->new($_) };

declare 'RepeatedImportDataRequest',
    as ArrayRef[ImportDataRequest()];

coerce 'RepeatedImportDataRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::ImportDataRequest'->new($_) } @$_ ] };

declare 'MapStringImportDataRequest',
    as HashRef[ImportDataRequest()];

declare 'ExportDataRequest',
    as InstanceOf['Google::Cloud::Parallelstore::V1beta::Parallelstore::ExportDataRequest'];

coerce 'ExportDataRequest',
    from HashRef, via { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::ExportDataRequest'->new($_) };

declare 'RepeatedExportDataRequest',
    as ArrayRef[ExportDataRequest()];

coerce 'RepeatedExportDataRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::ExportDataRequest'->new($_) } @$_ ] };

declare 'MapStringExportDataRequest',
    as HashRef[ExportDataRequest()];

declare 'ImportDataResponse',
    as InstanceOf['Google::Cloud::Parallelstore::V1beta::Parallelstore::ImportDataResponse'];

coerce 'ImportDataResponse',
    from HashRef, via { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::ImportDataResponse'->new($_) };

declare 'RepeatedImportDataResponse',
    as ArrayRef[ImportDataResponse()];

coerce 'RepeatedImportDataResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::ImportDataResponse'->new($_) } @$_ ] };

declare 'MapStringImportDataResponse',
    as HashRef[ImportDataResponse()];

declare 'TransferErrorLogEntry',
    as InstanceOf['Google::Cloud::Parallelstore::V1beta::Parallelstore::TransferErrorLogEntry'];

coerce 'TransferErrorLogEntry',
    from HashRef, via { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::TransferErrorLogEntry'->new($_) };

declare 'RepeatedTransferErrorLogEntry',
    as ArrayRef[TransferErrorLogEntry()];

coerce 'RepeatedTransferErrorLogEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::TransferErrorLogEntry'->new($_) } @$_ ] };

declare 'MapStringTransferErrorLogEntry',
    as HashRef[TransferErrorLogEntry()];

declare 'TransferErrorSummary',
    as InstanceOf['Google::Cloud::Parallelstore::V1beta::Parallelstore::TransferErrorSummary'];

coerce 'TransferErrorSummary',
    from HashRef, via { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::TransferErrorSummary'->new($_) };

declare 'RepeatedTransferErrorSummary',
    as ArrayRef[TransferErrorSummary()];

coerce 'RepeatedTransferErrorSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::TransferErrorSummary'->new($_) } @$_ ] };

declare 'MapStringTransferErrorSummary',
    as HashRef[TransferErrorSummary()];

declare 'ImportDataMetadata',
    as InstanceOf['Google::Cloud::Parallelstore::V1beta::Parallelstore::ImportDataMetadata'];

coerce 'ImportDataMetadata',
    from HashRef, via { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::ImportDataMetadata'->new($_) };

declare 'RepeatedImportDataMetadata',
    as ArrayRef[ImportDataMetadata()];

coerce 'RepeatedImportDataMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::ImportDataMetadata'->new($_) } @$_ ] };

declare 'MapStringImportDataMetadata',
    as HashRef[ImportDataMetadata()];

declare 'ExportDataResponse',
    as InstanceOf['Google::Cloud::Parallelstore::V1beta::Parallelstore::ExportDataResponse'];

coerce 'ExportDataResponse',
    from HashRef, via { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::ExportDataResponse'->new($_) };

declare 'RepeatedExportDataResponse',
    as ArrayRef[ExportDataResponse()];

coerce 'RepeatedExportDataResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::ExportDataResponse'->new($_) } @$_ ] };

declare 'MapStringExportDataResponse',
    as HashRef[ExportDataResponse()];

declare 'ExportDataMetadata',
    as InstanceOf['Google::Cloud::Parallelstore::V1beta::Parallelstore::ExportDataMetadata'];

coerce 'ExportDataMetadata',
    from HashRef, via { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::ExportDataMetadata'->new($_) };

declare 'RepeatedExportDataMetadata',
    as ArrayRef[ExportDataMetadata()];

coerce 'RepeatedExportDataMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::ExportDataMetadata'->new($_) } @$_ ] };

declare 'MapStringExportDataMetadata',
    as HashRef[ExportDataMetadata()];

declare 'TransferOperationMetadata',
    as InstanceOf['Google::Cloud::Parallelstore::V1beta::Parallelstore::TransferOperationMetadata'];

coerce 'TransferOperationMetadata',
    from HashRef, via { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::TransferOperationMetadata'->new($_) };

declare 'RepeatedTransferOperationMetadata',
    as ArrayRef[TransferOperationMetadata()];

coerce 'RepeatedTransferOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::TransferOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringTransferOperationMetadata',
    as HashRef[TransferOperationMetadata()];

declare 'TransferCounters',
    as InstanceOf['Google::Cloud::Parallelstore::V1beta::Parallelstore::TransferCounters'];

coerce 'TransferCounters',
    from HashRef, via { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::TransferCounters'->new($_) };

declare 'RepeatedTransferCounters',
    as ArrayRef[TransferCounters()];

coerce 'RepeatedTransferCounters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Parallelstore::V1beta::Parallelstore::TransferCounters'->new($_) } @$_ ] };

declare 'MapStringTransferCounters',
    as HashRef[TransferCounters()];

1;

__END__

=head1 NAME

Google::Cloud::Parallelstore::V1beta::Parallelstore::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
