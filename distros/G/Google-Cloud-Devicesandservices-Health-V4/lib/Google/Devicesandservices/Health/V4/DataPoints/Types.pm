package Google::Devicesandservices::Health::V4::DataPoints::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataPoint',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataPoints::DataPoint'];

coerce 'DataPoint',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataPoints::DataPoint'->new($_) };

declare 'RepeatedDataPoint',
    as ArrayRef[DataPoint()];

coerce 'RepeatedDataPoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataPoints::DataPoint'->new($_) } @$_ ] };

declare 'MapStringDataPoint',
    as HashRef[DataPoint()];

declare 'ReconciledDataPoint',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataPoints::ReconciledDataPoint'];

coerce 'ReconciledDataPoint',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataPoints::ReconciledDataPoint'->new($_) };

declare 'RepeatedReconciledDataPoint',
    as ArrayRef[ReconciledDataPoint()];

coerce 'RepeatedReconciledDataPoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataPoints::ReconciledDataPoint'->new($_) } @$_ ] };

declare 'MapStringReconciledDataPoint',
    as HashRef[ReconciledDataPoint()];

declare 'RollupDataPoint',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataPoints::RollupDataPoint'];

coerce 'RollupDataPoint',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataPoints::RollupDataPoint'->new($_) };

declare 'RepeatedRollupDataPoint',
    as ArrayRef[RollupDataPoint()];

coerce 'RepeatedRollupDataPoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataPoints::RollupDataPoint'->new($_) } @$_ ] };

declare 'MapStringRollupDataPoint',
    as HashRef[RollupDataPoint()];

declare 'DailyRollupDataPoint',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataPoints::DailyRollupDataPoint'];

coerce 'DailyRollupDataPoint',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataPoints::DailyRollupDataPoint'->new($_) };

declare 'RepeatedDailyRollupDataPoint',
    as ArrayRef[DailyRollupDataPoint()];

coerce 'RepeatedDailyRollupDataPoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataPoints::DailyRollupDataPoint'->new($_) } @$_ ] };

declare 'MapStringDailyRollupDataPoint',
    as HashRef[DailyRollupDataPoint()];

declare 'GetDataPointRequest',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataPoints::GetDataPointRequest'];

coerce 'GetDataPointRequest',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataPoints::GetDataPointRequest'->new($_) };

declare 'RepeatedGetDataPointRequest',
    as ArrayRef[GetDataPointRequest()];

coerce 'RepeatedGetDataPointRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataPoints::GetDataPointRequest'->new($_) } @$_ ] };

declare 'MapStringGetDataPointRequest',
    as HashRef[GetDataPointRequest()];

declare 'ListDataPointsRequest',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataPoints::ListDataPointsRequest'];

coerce 'ListDataPointsRequest',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataPoints::ListDataPointsRequest'->new($_) };

declare 'RepeatedListDataPointsRequest',
    as ArrayRef[ListDataPointsRequest()];

coerce 'RepeatedListDataPointsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataPoints::ListDataPointsRequest'->new($_) } @$_ ] };

declare 'MapStringListDataPointsRequest',
    as HashRef[ListDataPointsRequest()];

declare 'ListDataPointsResponse',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataPoints::ListDataPointsResponse'];

coerce 'ListDataPointsResponse',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataPoints::ListDataPointsResponse'->new($_) };

declare 'RepeatedListDataPointsResponse',
    as ArrayRef[ListDataPointsResponse()];

coerce 'RepeatedListDataPointsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataPoints::ListDataPointsResponse'->new($_) } @$_ ] };

declare 'MapStringListDataPointsResponse',
    as HashRef[ListDataPointsResponse()];

declare 'CreateDataPointRequest',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataPoints::CreateDataPointRequest'];

coerce 'CreateDataPointRequest',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataPoints::CreateDataPointRequest'->new($_) };

declare 'RepeatedCreateDataPointRequest',
    as ArrayRef[CreateDataPointRequest()];

coerce 'RepeatedCreateDataPointRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataPoints::CreateDataPointRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDataPointRequest',
    as HashRef[CreateDataPointRequest()];

declare 'CreateDataPointOperationMetadata',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataPoints::CreateDataPointOperationMetadata'];

coerce 'CreateDataPointOperationMetadata',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataPoints::CreateDataPointOperationMetadata'->new($_) };

declare 'RepeatedCreateDataPointOperationMetadata',
    as ArrayRef[CreateDataPointOperationMetadata()];

coerce 'RepeatedCreateDataPointOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataPoints::CreateDataPointOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateDataPointOperationMetadata',
    as HashRef[CreateDataPointOperationMetadata()];

declare 'UpdateDataPointRequest',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataPoints::UpdateDataPointRequest'];

coerce 'UpdateDataPointRequest',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataPoints::UpdateDataPointRequest'->new($_) };

declare 'RepeatedUpdateDataPointRequest',
    as ArrayRef[UpdateDataPointRequest()];

coerce 'RepeatedUpdateDataPointRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataPoints::UpdateDataPointRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDataPointRequest',
    as HashRef[UpdateDataPointRequest()];

declare 'UpdateDataPointOperationMetadata',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataPoints::UpdateDataPointOperationMetadata'];

coerce 'UpdateDataPointOperationMetadata',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataPoints::UpdateDataPointOperationMetadata'->new($_) };

declare 'RepeatedUpdateDataPointOperationMetadata',
    as ArrayRef[UpdateDataPointOperationMetadata()];

coerce 'RepeatedUpdateDataPointOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataPoints::UpdateDataPointOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringUpdateDataPointOperationMetadata',
    as HashRef[UpdateDataPointOperationMetadata()];

declare 'BatchDeleteDataPointsRequest',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataPoints::BatchDeleteDataPointsRequest'];

coerce 'BatchDeleteDataPointsRequest',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataPoints::BatchDeleteDataPointsRequest'->new($_) };

declare 'RepeatedBatchDeleteDataPointsRequest',
    as ArrayRef[BatchDeleteDataPointsRequest()];

coerce 'RepeatedBatchDeleteDataPointsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataPoints::BatchDeleteDataPointsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchDeleteDataPointsRequest',
    as HashRef[BatchDeleteDataPointsRequest()];

declare 'BatchDeleteDataPointsResponse',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataPoints::BatchDeleteDataPointsResponse'];

coerce 'BatchDeleteDataPointsResponse',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataPoints::BatchDeleteDataPointsResponse'->new($_) };

declare 'RepeatedBatchDeleteDataPointsResponse',
    as ArrayRef[BatchDeleteDataPointsResponse()];

coerce 'RepeatedBatchDeleteDataPointsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataPoints::BatchDeleteDataPointsResponse'->new($_) } @$_ ] };

declare 'MapStringBatchDeleteDataPointsResponse',
    as HashRef[BatchDeleteDataPointsResponse()];

declare 'BatchDeleteDataPointsOperationMetadata',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataPoints::BatchDeleteDataPointsOperationMetadata'];

coerce 'BatchDeleteDataPointsOperationMetadata',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataPoints::BatchDeleteDataPointsOperationMetadata'->new($_) };

declare 'RepeatedBatchDeleteDataPointsOperationMetadata',
    as ArrayRef[BatchDeleteDataPointsOperationMetadata()];

coerce 'RepeatedBatchDeleteDataPointsOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataPoints::BatchDeleteDataPointsOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringBatchDeleteDataPointsOperationMetadata',
    as HashRef[BatchDeleteDataPointsOperationMetadata()];

declare 'FailedRequestsEntry',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataPoints::BatchDeleteDataPointsOperationMetadata::FailedRequestsEntry'];

coerce 'FailedRequestsEntry',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataPoints::BatchDeleteDataPointsOperationMetadata::FailedRequestsEntry'->new($_) };

declare 'RepeatedFailedRequestsEntry',
    as ArrayRef[FailedRequestsEntry()];

coerce 'RepeatedFailedRequestsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataPoints::BatchDeleteDataPointsOperationMetadata::FailedRequestsEntry'->new($_) } @$_ ] };

declare 'MapStringFailedRequestsEntry',
    as HashRef[FailedRequestsEntry()];

declare 'ReconcileDataPointsRequest',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataPoints::ReconcileDataPointsRequest'];

coerce 'ReconcileDataPointsRequest',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataPoints::ReconcileDataPointsRequest'->new($_) };

declare 'RepeatedReconcileDataPointsRequest',
    as ArrayRef[ReconcileDataPointsRequest()];

coerce 'RepeatedReconcileDataPointsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataPoints::ReconcileDataPointsRequest'->new($_) } @$_ ] };

declare 'MapStringReconcileDataPointsRequest',
    as HashRef[ReconcileDataPointsRequest()];

declare 'ReconcileDataPointsResponse',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataPoints::ReconcileDataPointsResponse'];

coerce 'ReconcileDataPointsResponse',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataPoints::ReconcileDataPointsResponse'->new($_) };

declare 'RepeatedReconcileDataPointsResponse',
    as ArrayRef[ReconcileDataPointsResponse()];

coerce 'RepeatedReconcileDataPointsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataPoints::ReconcileDataPointsResponse'->new($_) } @$_ ] };

declare 'MapStringReconcileDataPointsResponse',
    as HashRef[ReconcileDataPointsResponse()];

declare 'RollUpDataPointsRequest',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataPoints::RollUpDataPointsRequest'];

coerce 'RollUpDataPointsRequest',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataPoints::RollUpDataPointsRequest'->new($_) };

declare 'RepeatedRollUpDataPointsRequest',
    as ArrayRef[RollUpDataPointsRequest()];

coerce 'RepeatedRollUpDataPointsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataPoints::RollUpDataPointsRequest'->new($_) } @$_ ] };

declare 'MapStringRollUpDataPointsRequest',
    as HashRef[RollUpDataPointsRequest()];

declare 'RollUpDataPointsResponse',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataPoints::RollUpDataPointsResponse'];

coerce 'RollUpDataPointsResponse',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataPoints::RollUpDataPointsResponse'->new($_) };

declare 'RepeatedRollUpDataPointsResponse',
    as ArrayRef[RollUpDataPointsResponse()];

coerce 'RepeatedRollUpDataPointsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataPoints::RollUpDataPointsResponse'->new($_) } @$_ ] };

declare 'MapStringRollUpDataPointsResponse',
    as HashRef[RollUpDataPointsResponse()];

declare 'DailyRollUpDataPointsRequest',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataPoints::DailyRollUpDataPointsRequest'];

coerce 'DailyRollUpDataPointsRequest',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataPoints::DailyRollUpDataPointsRequest'->new($_) };

declare 'RepeatedDailyRollUpDataPointsRequest',
    as ArrayRef[DailyRollUpDataPointsRequest()];

coerce 'RepeatedDailyRollUpDataPointsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataPoints::DailyRollUpDataPointsRequest'->new($_) } @$_ ] };

declare 'MapStringDailyRollUpDataPointsRequest',
    as HashRef[DailyRollUpDataPointsRequest()];

declare 'DailyRollUpDataPointsResponse',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataPoints::DailyRollUpDataPointsResponse'];

coerce 'DailyRollUpDataPointsResponse',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataPoints::DailyRollUpDataPointsResponse'->new($_) };

declare 'RepeatedDailyRollUpDataPointsResponse',
    as ArrayRef[DailyRollUpDataPointsResponse()];

coerce 'RepeatedDailyRollUpDataPointsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataPoints::DailyRollUpDataPointsResponse'->new($_) } @$_ ] };

declare 'MapStringDailyRollUpDataPointsResponse',
    as HashRef[DailyRollUpDataPointsResponse()];

declare 'DataType',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataPoints::DataType'];

coerce 'DataType',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataPoints::DataType'->new($_) };

declare 'RepeatedDataType',
    as ArrayRef[DataType()];

coerce 'RepeatedDataType',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataPoints::DataType'->new($_) } @$_ ] };

declare 'MapStringDataType',
    as HashRef[DataType()];

declare 'ExportExerciseTcxRequest',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataPoints::ExportExerciseTcxRequest'];

coerce 'ExportExerciseTcxRequest',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataPoints::ExportExerciseTcxRequest'->new($_) };

declare 'RepeatedExportExerciseTcxRequest',
    as ArrayRef[ExportExerciseTcxRequest()];

coerce 'RepeatedExportExerciseTcxRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataPoints::ExportExerciseTcxRequest'->new($_) } @$_ ] };

declare 'MapStringExportExerciseTcxRequest',
    as HashRef[ExportExerciseTcxRequest()];

declare 'ExportExerciseTcxResponse',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataPoints::ExportExerciseTcxResponse'];

coerce 'ExportExerciseTcxResponse',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataPoints::ExportExerciseTcxResponse'->new($_) };

declare 'RepeatedExportExerciseTcxResponse',
    as ArrayRef[ExportExerciseTcxResponse()];

coerce 'RepeatedExportExerciseTcxResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataPoints::ExportExerciseTcxResponse'->new($_) } @$_ ] };

declare 'MapStringExportExerciseTcxResponse',
    as HashRef[ExportExerciseTcxResponse()];

1;

__END__

=head1 NAME

Google::Devicesandservices::Health::V4::DataPoints::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
