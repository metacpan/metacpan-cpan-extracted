package Google::Bigtable::V2::Data::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Row',
    as InstanceOf['Google::Bigtable::V2::Data::Row'];

coerce 'Row',
    from HashRef, via { 'Google::Bigtable::V2::Data::Row'->new($_) };

declare 'RepeatedRow',
    as ArrayRef[Row()];

coerce 'RepeatedRow',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::Row'->new($_) } @$_ ] };

declare 'MapStringRow',
    as HashRef[Row()];

declare 'Family',
    as InstanceOf['Google::Bigtable::V2::Data::Family'];

coerce 'Family',
    from HashRef, via { 'Google::Bigtable::V2::Data::Family'->new($_) };

declare 'RepeatedFamily',
    as ArrayRef[Family()];

coerce 'RepeatedFamily',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::Family'->new($_) } @$_ ] };

declare 'MapStringFamily',
    as HashRef[Family()];

declare 'Column',
    as InstanceOf['Google::Bigtable::V2::Data::Column'];

coerce 'Column',
    from HashRef, via { 'Google::Bigtable::V2::Data::Column'->new($_) };

declare 'RepeatedColumn',
    as ArrayRef[Column()];

coerce 'RepeatedColumn',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::Column'->new($_) } @$_ ] };

declare 'MapStringColumn',
    as HashRef[Column()];

declare 'Cell',
    as InstanceOf['Google::Bigtable::V2::Data::Cell'];

coerce 'Cell',
    from HashRef, via { 'Google::Bigtable::V2::Data::Cell'->new($_) };

declare 'RepeatedCell',
    as ArrayRef[Cell()];

coerce 'RepeatedCell',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::Cell'->new($_) } @$_ ] };

declare 'MapStringCell',
    as HashRef[Cell()];

declare 'Value',
    as InstanceOf['Google::Bigtable::V2::Data::Value'];

coerce 'Value',
    from HashRef, via { 'Google::Bigtable::V2::Data::Value'->new($_) };

declare 'RepeatedValue',
    as ArrayRef[Value()];

coerce 'RepeatedValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::Value'->new($_) } @$_ ] };

declare 'MapStringValue',
    as HashRef[Value()];

declare 'ArrayValue',
    as InstanceOf['Google::Bigtable::V2::Data::ArrayValue'];

coerce 'ArrayValue',
    from HashRef, via { 'Google::Bigtable::V2::Data::ArrayValue'->new($_) };

declare 'RepeatedArrayValue',
    as ArrayRef[ArrayValue()];

coerce 'RepeatedArrayValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::ArrayValue'->new($_) } @$_ ] };

declare 'MapStringArrayValue',
    as HashRef[ArrayValue()];

declare 'RowRange',
    as InstanceOf['Google::Bigtable::V2::Data::RowRange'];

coerce 'RowRange',
    from HashRef, via { 'Google::Bigtable::V2::Data::RowRange'->new($_) };

declare 'RepeatedRowRange',
    as ArrayRef[RowRange()];

coerce 'RepeatedRowRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::RowRange'->new($_) } @$_ ] };

declare 'MapStringRowRange',
    as HashRef[RowRange()];

declare 'RowSet',
    as InstanceOf['Google::Bigtable::V2::Data::RowSet'];

coerce 'RowSet',
    from HashRef, via { 'Google::Bigtable::V2::Data::RowSet'->new($_) };

declare 'RepeatedRowSet',
    as ArrayRef[RowSet()];

coerce 'RepeatedRowSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::RowSet'->new($_) } @$_ ] };

declare 'MapStringRowSet',
    as HashRef[RowSet()];

declare 'ColumnRange',
    as InstanceOf['Google::Bigtable::V2::Data::ColumnRange'];

coerce 'ColumnRange',
    from HashRef, via { 'Google::Bigtable::V2::Data::ColumnRange'->new($_) };

declare 'RepeatedColumnRange',
    as ArrayRef[ColumnRange()];

coerce 'RepeatedColumnRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::ColumnRange'->new($_) } @$_ ] };

declare 'MapStringColumnRange',
    as HashRef[ColumnRange()];

declare 'TimestampRange',
    as InstanceOf['Google::Bigtable::V2::Data::TimestampRange'];

coerce 'TimestampRange',
    from HashRef, via { 'Google::Bigtable::V2::Data::TimestampRange'->new($_) };

declare 'RepeatedTimestampRange',
    as ArrayRef[TimestampRange()];

coerce 'RepeatedTimestampRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::TimestampRange'->new($_) } @$_ ] };

declare 'MapStringTimestampRange',
    as HashRef[TimestampRange()];

declare 'ValueRange',
    as InstanceOf['Google::Bigtable::V2::Data::ValueRange'];

coerce 'ValueRange',
    from HashRef, via { 'Google::Bigtable::V2::Data::ValueRange'->new($_) };

declare 'RepeatedValueRange',
    as ArrayRef[ValueRange()];

coerce 'RepeatedValueRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::ValueRange'->new($_) } @$_ ] };

declare 'MapStringValueRange',
    as HashRef[ValueRange()];

declare 'ValueBitmask',
    as InstanceOf['Google::Bigtable::V2::Data::ValueBitmask'];

coerce 'ValueBitmask',
    from HashRef, via { 'Google::Bigtable::V2::Data::ValueBitmask'->new($_) };

declare 'RepeatedValueBitmask',
    as ArrayRef[ValueBitmask()];

coerce 'RepeatedValueBitmask',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::ValueBitmask'->new($_) } @$_ ] };

declare 'MapStringValueBitmask',
    as HashRef[ValueBitmask()];

declare 'RowFilter',
    as InstanceOf['Google::Bigtable::V2::Data::RowFilter'];

coerce 'RowFilter',
    from HashRef, via { 'Google::Bigtable::V2::Data::RowFilter'->new($_) };

declare 'RepeatedRowFilter',
    as ArrayRef[RowFilter()];

coerce 'RepeatedRowFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::RowFilter'->new($_) } @$_ ] };

declare 'MapStringRowFilter',
    as HashRef[RowFilter()];

declare 'Chain',
    as InstanceOf['Google::Bigtable::V2::Data::RowFilter::Chain'];

coerce 'Chain',
    from HashRef, via { 'Google::Bigtable::V2::Data::RowFilter::Chain'->new($_) };

declare 'RepeatedChain',
    as ArrayRef[Chain()];

coerce 'RepeatedChain',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::RowFilter::Chain'->new($_) } @$_ ] };

declare 'MapStringChain',
    as HashRef[Chain()];

declare 'Interleave',
    as InstanceOf['Google::Bigtable::V2::Data::RowFilter::Interleave'];

coerce 'Interleave',
    from HashRef, via { 'Google::Bigtable::V2::Data::RowFilter::Interleave'->new($_) };

declare 'RepeatedInterleave',
    as ArrayRef[Interleave()];

coerce 'RepeatedInterleave',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::RowFilter::Interleave'->new($_) } @$_ ] };

declare 'MapStringInterleave',
    as HashRef[Interleave()];

declare 'Condition',
    as InstanceOf['Google::Bigtable::V2::Data::RowFilter::Condition'];

coerce 'Condition',
    from HashRef, via { 'Google::Bigtable::V2::Data::RowFilter::Condition'->new($_) };

declare 'RepeatedCondition',
    as ArrayRef[Condition()];

coerce 'RepeatedCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::RowFilter::Condition'->new($_) } @$_ ] };

declare 'MapStringCondition',
    as HashRef[Condition()];

declare 'Mutation',
    as InstanceOf['Google::Bigtable::V2::Data::Mutation'];

coerce 'Mutation',
    from HashRef, via { 'Google::Bigtable::V2::Data::Mutation'->new($_) };

declare 'RepeatedMutation',
    as ArrayRef[Mutation()];

coerce 'RepeatedMutation',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::Mutation'->new($_) } @$_ ] };

declare 'MapStringMutation',
    as HashRef[Mutation()];

declare 'TimestampOrigin',
    as (Int | Str);

declare 'SetCell',
    as InstanceOf['Google::Bigtable::V2::Data::Mutation::SetCell'];

coerce 'SetCell',
    from HashRef, via { 'Google::Bigtable::V2::Data::Mutation::SetCell'->new($_) };

declare 'RepeatedSetCell',
    as ArrayRef[SetCell()];

coerce 'RepeatedSetCell',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::Mutation::SetCell'->new($_) } @$_ ] };

declare 'MapStringSetCell',
    as HashRef[SetCell()];

declare 'AddToCell',
    as InstanceOf['Google::Bigtable::V2::Data::Mutation::AddToCell'];

coerce 'AddToCell',
    from HashRef, via { 'Google::Bigtable::V2::Data::Mutation::AddToCell'->new($_) };

declare 'RepeatedAddToCell',
    as ArrayRef[AddToCell()];

coerce 'RepeatedAddToCell',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::Mutation::AddToCell'->new($_) } @$_ ] };

declare 'MapStringAddToCell',
    as HashRef[AddToCell()];

declare 'MergeToCell',
    as InstanceOf['Google::Bigtable::V2::Data::Mutation::MergeToCell'];

coerce 'MergeToCell',
    from HashRef, via { 'Google::Bigtable::V2::Data::Mutation::MergeToCell'->new($_) };

declare 'RepeatedMergeToCell',
    as ArrayRef[MergeToCell()];

coerce 'RepeatedMergeToCell',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::Mutation::MergeToCell'->new($_) } @$_ ] };

declare 'MapStringMergeToCell',
    as HashRef[MergeToCell()];

declare 'DeleteFromColumn',
    as InstanceOf['Google::Bigtable::V2::Data::Mutation::DeleteFromColumn'];

coerce 'DeleteFromColumn',
    from HashRef, via { 'Google::Bigtable::V2::Data::Mutation::DeleteFromColumn'->new($_) };

declare 'RepeatedDeleteFromColumn',
    as ArrayRef[DeleteFromColumn()];

coerce 'RepeatedDeleteFromColumn',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::Mutation::DeleteFromColumn'->new($_) } @$_ ] };

declare 'MapStringDeleteFromColumn',
    as HashRef[DeleteFromColumn()];

declare 'DeleteFromFamily',
    as InstanceOf['Google::Bigtable::V2::Data::Mutation::DeleteFromFamily'];

coerce 'DeleteFromFamily',
    from HashRef, via { 'Google::Bigtable::V2::Data::Mutation::DeleteFromFamily'->new($_) };

declare 'RepeatedDeleteFromFamily',
    as ArrayRef[DeleteFromFamily()];

coerce 'RepeatedDeleteFromFamily',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::Mutation::DeleteFromFamily'->new($_) } @$_ ] };

declare 'MapStringDeleteFromFamily',
    as HashRef[DeleteFromFamily()];

declare 'DeleteFromRow',
    as InstanceOf['Google::Bigtable::V2::Data::Mutation::DeleteFromRow'];

coerce 'DeleteFromRow',
    from HashRef, via { 'Google::Bigtable::V2::Data::Mutation::DeleteFromRow'->new($_) };

declare 'RepeatedDeleteFromRow',
    as ArrayRef[DeleteFromRow()];

coerce 'RepeatedDeleteFromRow',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::Mutation::DeleteFromRow'->new($_) } @$_ ] };

declare 'MapStringDeleteFromRow',
    as HashRef[DeleteFromRow()];

declare 'ReadModifyWriteRule',
    as InstanceOf['Google::Bigtable::V2::Data::ReadModifyWriteRule'];

coerce 'ReadModifyWriteRule',
    from HashRef, via { 'Google::Bigtable::V2::Data::ReadModifyWriteRule'->new($_) };

declare 'RepeatedReadModifyWriteRule',
    as ArrayRef[ReadModifyWriteRule()];

coerce 'RepeatedReadModifyWriteRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::ReadModifyWriteRule'->new($_) } @$_ ] };

declare 'MapStringReadModifyWriteRule',
    as HashRef[ReadModifyWriteRule()];

declare 'StreamPartition',
    as InstanceOf['Google::Bigtable::V2::Data::StreamPartition'];

coerce 'StreamPartition',
    from HashRef, via { 'Google::Bigtable::V2::Data::StreamPartition'->new($_) };

declare 'RepeatedStreamPartition',
    as ArrayRef[StreamPartition()];

coerce 'RepeatedStreamPartition',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::StreamPartition'->new($_) } @$_ ] };

declare 'MapStringStreamPartition',
    as HashRef[StreamPartition()];

declare 'StreamContinuationTokens',
    as InstanceOf['Google::Bigtable::V2::Data::StreamContinuationTokens'];

coerce 'StreamContinuationTokens',
    from HashRef, via { 'Google::Bigtable::V2::Data::StreamContinuationTokens'->new($_) };

declare 'RepeatedStreamContinuationTokens',
    as ArrayRef[StreamContinuationTokens()];

coerce 'RepeatedStreamContinuationTokens',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::StreamContinuationTokens'->new($_) } @$_ ] };

declare 'MapStringStreamContinuationTokens',
    as HashRef[StreamContinuationTokens()];

declare 'StreamContinuationToken',
    as InstanceOf['Google::Bigtable::V2::Data::StreamContinuationToken'];

coerce 'StreamContinuationToken',
    from HashRef, via { 'Google::Bigtable::V2::Data::StreamContinuationToken'->new($_) };

declare 'RepeatedStreamContinuationToken',
    as ArrayRef[StreamContinuationToken()];

coerce 'RepeatedStreamContinuationToken',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::StreamContinuationToken'->new($_) } @$_ ] };

declare 'MapStringStreamContinuationToken',
    as HashRef[StreamContinuationToken()];

declare 'ProtoFormat',
    as InstanceOf['Google::Bigtable::V2::Data::ProtoFormat'];

coerce 'ProtoFormat',
    from HashRef, via { 'Google::Bigtable::V2::Data::ProtoFormat'->new($_) };

declare 'RepeatedProtoFormat',
    as ArrayRef[ProtoFormat()];

coerce 'RepeatedProtoFormat',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::ProtoFormat'->new($_) } @$_ ] };

declare 'MapStringProtoFormat',
    as HashRef[ProtoFormat()];

declare 'ColumnMetadata',
    as InstanceOf['Google::Bigtable::V2::Data::ColumnMetadata'];

coerce 'ColumnMetadata',
    from HashRef, via { 'Google::Bigtable::V2::Data::ColumnMetadata'->new($_) };

declare 'RepeatedColumnMetadata',
    as ArrayRef[ColumnMetadata()];

coerce 'RepeatedColumnMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::ColumnMetadata'->new($_) } @$_ ] };

declare 'MapStringColumnMetadata',
    as HashRef[ColumnMetadata()];

declare 'ProtoSchema',
    as InstanceOf['Google::Bigtable::V2::Data::ProtoSchema'];

coerce 'ProtoSchema',
    from HashRef, via { 'Google::Bigtable::V2::Data::ProtoSchema'->new($_) };

declare 'RepeatedProtoSchema',
    as ArrayRef[ProtoSchema()];

coerce 'RepeatedProtoSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::ProtoSchema'->new($_) } @$_ ] };

declare 'MapStringProtoSchema',
    as HashRef[ProtoSchema()];

declare 'ResultSetMetadata',
    as InstanceOf['Google::Bigtable::V2::Data::ResultSetMetadata'];

coerce 'ResultSetMetadata',
    from HashRef, via { 'Google::Bigtable::V2::Data::ResultSetMetadata'->new($_) };

declare 'RepeatedResultSetMetadata',
    as ArrayRef[ResultSetMetadata()];

coerce 'RepeatedResultSetMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::ResultSetMetadata'->new($_) } @$_ ] };

declare 'MapStringResultSetMetadata',
    as HashRef[ResultSetMetadata()];

declare 'ProtoRows',
    as InstanceOf['Google::Bigtable::V2::Data::ProtoRows'];

coerce 'ProtoRows',
    from HashRef, via { 'Google::Bigtable::V2::Data::ProtoRows'->new($_) };

declare 'RepeatedProtoRows',
    as ArrayRef[ProtoRows()];

coerce 'RepeatedProtoRows',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::ProtoRows'->new($_) } @$_ ] };

declare 'MapStringProtoRows',
    as HashRef[ProtoRows()];

declare 'ProtoRowsBatch',
    as InstanceOf['Google::Bigtable::V2::Data::ProtoRowsBatch'];

coerce 'ProtoRowsBatch',
    from HashRef, via { 'Google::Bigtable::V2::Data::ProtoRowsBatch'->new($_) };

declare 'RepeatedProtoRowsBatch',
    as ArrayRef[ProtoRowsBatch()];

coerce 'RepeatedProtoRowsBatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::ProtoRowsBatch'->new($_) } @$_ ] };

declare 'MapStringProtoRowsBatch',
    as HashRef[ProtoRowsBatch()];

declare 'PartialResultSet',
    as InstanceOf['Google::Bigtable::V2::Data::PartialResultSet'];

coerce 'PartialResultSet',
    from HashRef, via { 'Google::Bigtable::V2::Data::PartialResultSet'->new($_) };

declare 'RepeatedPartialResultSet',
    as ArrayRef[PartialResultSet()];

coerce 'RepeatedPartialResultSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::PartialResultSet'->new($_) } @$_ ] };

declare 'MapStringPartialResultSet',
    as HashRef[PartialResultSet()];

declare 'Idempotency',
    as InstanceOf['Google::Bigtable::V2::Data::Idempotency'];

coerce 'Idempotency',
    from HashRef, via { 'Google::Bigtable::V2::Data::Idempotency'->new($_) };

declare 'RepeatedIdempotency',
    as ArrayRef[Idempotency()];

coerce 'RepeatedIdempotency',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::Data::Idempotency'->new($_) } @$_ ] };

declare 'MapStringIdempotency',
    as HashRef[Idempotency()];

1;

__END__

=head1 NAME

Google::Bigtable::V2::Data::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
