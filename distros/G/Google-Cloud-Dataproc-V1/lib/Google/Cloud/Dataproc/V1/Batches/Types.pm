package Google::Cloud::Dataproc::V1::Batches::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateBatchRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::Batches::CreateBatchRequest'];

coerce 'CreateBatchRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Batches::CreateBatchRequest'->new($_) };

declare 'RepeatedCreateBatchRequest',
    as ArrayRef[CreateBatchRequest()];

coerce 'RepeatedCreateBatchRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Batches::CreateBatchRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBatchRequest',
    as HashRef[CreateBatchRequest()];

declare 'GetBatchRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::Batches::GetBatchRequest'];

coerce 'GetBatchRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Batches::GetBatchRequest'->new($_) };

declare 'RepeatedGetBatchRequest',
    as ArrayRef[GetBatchRequest()];

coerce 'RepeatedGetBatchRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Batches::GetBatchRequest'->new($_) } @$_ ] };

declare 'MapStringGetBatchRequest',
    as HashRef[GetBatchRequest()];

declare 'ListBatchesRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::Batches::ListBatchesRequest'];

coerce 'ListBatchesRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Batches::ListBatchesRequest'->new($_) };

declare 'RepeatedListBatchesRequest',
    as ArrayRef[ListBatchesRequest()];

coerce 'RepeatedListBatchesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Batches::ListBatchesRequest'->new($_) } @$_ ] };

declare 'MapStringListBatchesRequest',
    as HashRef[ListBatchesRequest()];

declare 'ListBatchesResponse',
    as InstanceOf['Google::Cloud::Dataproc::V1::Batches::ListBatchesResponse'];

coerce 'ListBatchesResponse',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Batches::ListBatchesResponse'->new($_) };

declare 'RepeatedListBatchesResponse',
    as ArrayRef[ListBatchesResponse()];

coerce 'RepeatedListBatchesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Batches::ListBatchesResponse'->new($_) } @$_ ] };

declare 'MapStringListBatchesResponse',
    as HashRef[ListBatchesResponse()];

declare 'DeleteBatchRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::Batches::DeleteBatchRequest'];

coerce 'DeleteBatchRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Batches::DeleteBatchRequest'->new($_) };

declare 'RepeatedDeleteBatchRequest',
    as ArrayRef[DeleteBatchRequest()];

coerce 'RepeatedDeleteBatchRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Batches::DeleteBatchRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBatchRequest',
    as HashRef[DeleteBatchRequest()];

declare 'Batch',
    as InstanceOf['Google::Cloud::Dataproc::V1::Batches::Batch'];

coerce 'Batch',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Batches::Batch'->new($_) };

declare 'RepeatedBatch',
    as ArrayRef[Batch()];

coerce 'RepeatedBatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Batches::Batch'->new($_) } @$_ ] };

declare 'MapStringBatch',
    as HashRef[Batch()];

declare 'State',
    as (Int | Str);

declare 'StateHistory',
    as InstanceOf['Google::Cloud::Dataproc::V1::Batches::Batch::StateHistory'];

coerce 'StateHistory',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Batches::Batch::StateHistory'->new($_) };

declare 'RepeatedStateHistory',
    as ArrayRef[StateHistory()];

coerce 'RepeatedStateHistory',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Batches::Batch::StateHistory'->new($_) } @$_ ] };

declare 'MapStringStateHistory',
    as HashRef[StateHistory()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Batches::Batch::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Batches::Batch::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Batches::Batch::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'PySparkBatch',
    as InstanceOf['Google::Cloud::Dataproc::V1::Batches::PySparkBatch'];

coerce 'PySparkBatch',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Batches::PySparkBatch'->new($_) };

declare 'RepeatedPySparkBatch',
    as ArrayRef[PySparkBatch()];

coerce 'RepeatedPySparkBatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Batches::PySparkBatch'->new($_) } @$_ ] };

declare 'MapStringPySparkBatch',
    as HashRef[PySparkBatch()];

declare 'SparkBatch',
    as InstanceOf['Google::Cloud::Dataproc::V1::Batches::SparkBatch'];

coerce 'SparkBatch',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Batches::SparkBatch'->new($_) };

declare 'RepeatedSparkBatch',
    as ArrayRef[SparkBatch()];

coerce 'RepeatedSparkBatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Batches::SparkBatch'->new($_) } @$_ ] };

declare 'MapStringSparkBatch',
    as HashRef[SparkBatch()];

declare 'SparkRBatch',
    as InstanceOf['Google::Cloud::Dataproc::V1::Batches::SparkRBatch'];

coerce 'SparkRBatch',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Batches::SparkRBatch'->new($_) };

declare 'RepeatedSparkRBatch',
    as ArrayRef[SparkRBatch()];

coerce 'RepeatedSparkRBatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Batches::SparkRBatch'->new($_) } @$_ ] };

declare 'MapStringSparkRBatch',
    as HashRef[SparkRBatch()];

declare 'SparkSqlBatch',
    as InstanceOf['Google::Cloud::Dataproc::V1::Batches::SparkSqlBatch'];

coerce 'SparkSqlBatch',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Batches::SparkSqlBatch'->new($_) };

declare 'RepeatedSparkSqlBatch',
    as ArrayRef[SparkSqlBatch()];

coerce 'RepeatedSparkSqlBatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Batches::SparkSqlBatch'->new($_) } @$_ ] };

declare 'MapStringSparkSqlBatch',
    as HashRef[SparkSqlBatch()];

declare 'QueryVariablesEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Batches::SparkSqlBatch::QueryVariablesEntry'];

coerce 'QueryVariablesEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Batches::SparkSqlBatch::QueryVariablesEntry'->new($_) };

declare 'RepeatedQueryVariablesEntry',
    as ArrayRef[QueryVariablesEntry()];

coerce 'RepeatedQueryVariablesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Batches::SparkSqlBatch::QueryVariablesEntry'->new($_) } @$_ ] };

declare 'MapStringQueryVariablesEntry',
    as HashRef[QueryVariablesEntry()];

declare 'PySparkNotebookBatch',
    as InstanceOf['Google::Cloud::Dataproc::V1::Batches::PySparkNotebookBatch'];

coerce 'PySparkNotebookBatch',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Batches::PySparkNotebookBatch'->new($_) };

declare 'RepeatedPySparkNotebookBatch',
    as ArrayRef[PySparkNotebookBatch()];

coerce 'RepeatedPySparkNotebookBatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Batches::PySparkNotebookBatch'->new($_) } @$_ ] };

declare 'MapStringPySparkNotebookBatch',
    as HashRef[PySparkNotebookBatch()];

declare 'ParamsEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Batches::PySparkNotebookBatch::ParamsEntry'];

coerce 'ParamsEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Batches::PySparkNotebookBatch::ParamsEntry'->new($_) };

declare 'RepeatedParamsEntry',
    as ArrayRef[ParamsEntry()];

coerce 'RepeatedParamsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Batches::PySparkNotebookBatch::ParamsEntry'->new($_) } @$_ ] };

declare 'MapStringParamsEntry',
    as HashRef[ParamsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Dataproc::V1::Batches::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
