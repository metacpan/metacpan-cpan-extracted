package Google::Cloud::Dataqna::V1alpha::Question::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'InterpretEntity',
    as (Int | Str);

declare 'Question',
    as InstanceOf['Google::Cloud::Dataqna::V1alpha::Question::Question'];

coerce 'Question',
    from HashRef, via { 'Google::Cloud::Dataqna::V1alpha::Question::Question'->new($_) };

declare 'RepeatedQuestion',
    as ArrayRef[Question()];

coerce 'RepeatedQuestion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataqna::V1alpha::Question::Question'->new($_) } @$_ ] };

declare 'MapStringQuestion',
    as HashRef[Question()];

declare 'InterpretError',
    as InstanceOf['Google::Cloud::Dataqna::V1alpha::Question::InterpretError'];

coerce 'InterpretError',
    from HashRef, via { 'Google::Cloud::Dataqna::V1alpha::Question::InterpretError'->new($_) };

declare 'RepeatedInterpretError',
    as ArrayRef[InterpretError()];

coerce 'RepeatedInterpretError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataqna::V1alpha::Question::InterpretError'->new($_) } @$_ ] };

declare 'MapStringInterpretError',
    as HashRef[InterpretError()];

declare 'InterpretErrorCode',
    as (Int | Str);

declare 'InterpretErrorDetails',
    as InstanceOf['Google::Cloud::Dataqna::V1alpha::Question::InterpretError::InterpretErrorDetails'];

coerce 'InterpretErrorDetails',
    from HashRef, via { 'Google::Cloud::Dataqna::V1alpha::Question::InterpretError::InterpretErrorDetails'->new($_) };

declare 'RepeatedInterpretErrorDetails',
    as ArrayRef[InterpretErrorDetails()];

coerce 'RepeatedInterpretErrorDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataqna::V1alpha::Question::InterpretError::InterpretErrorDetails'->new($_) } @$_ ] };

declare 'MapStringInterpretErrorDetails',
    as HashRef[InterpretErrorDetails()];

declare 'InterpretUnsupportedDetails',
    as InstanceOf['Google::Cloud::Dataqna::V1alpha::Question::InterpretError::InterpretUnsupportedDetails'];

coerce 'InterpretUnsupportedDetails',
    from HashRef, via { 'Google::Cloud::Dataqna::V1alpha::Question::InterpretError::InterpretUnsupportedDetails'->new($_) };

declare 'RepeatedInterpretUnsupportedDetails',
    as ArrayRef[InterpretUnsupportedDetails()];

coerce 'RepeatedInterpretUnsupportedDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataqna::V1alpha::Question::InterpretError::InterpretUnsupportedDetails'->new($_) } @$_ ] };

declare 'MapStringInterpretUnsupportedDetails',
    as HashRef[InterpretUnsupportedDetails()];

declare 'InterpretIncompleteQueryDetails',
    as InstanceOf['Google::Cloud::Dataqna::V1alpha::Question::InterpretError::InterpretIncompleteQueryDetails'];

coerce 'InterpretIncompleteQueryDetails',
    from HashRef, via { 'Google::Cloud::Dataqna::V1alpha::Question::InterpretError::InterpretIncompleteQueryDetails'->new($_) };

declare 'RepeatedInterpretIncompleteQueryDetails',
    as ArrayRef[InterpretIncompleteQueryDetails()];

coerce 'RepeatedInterpretIncompleteQueryDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataqna::V1alpha::Question::InterpretError::InterpretIncompleteQueryDetails'->new($_) } @$_ ] };

declare 'MapStringInterpretIncompleteQueryDetails',
    as HashRef[InterpretIncompleteQueryDetails()];

declare 'InterpretAmbiguityDetails',
    as InstanceOf['Google::Cloud::Dataqna::V1alpha::Question::InterpretError::InterpretAmbiguityDetails'];

coerce 'InterpretAmbiguityDetails',
    from HashRef, via { 'Google::Cloud::Dataqna::V1alpha::Question::InterpretError::InterpretAmbiguityDetails'->new($_) };

declare 'RepeatedInterpretAmbiguityDetails',
    as ArrayRef[InterpretAmbiguityDetails()];

coerce 'RepeatedInterpretAmbiguityDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataqna::V1alpha::Question::InterpretError::InterpretAmbiguityDetails'->new($_) } @$_ ] };

declare 'MapStringInterpretAmbiguityDetails',
    as HashRef[InterpretAmbiguityDetails()];

declare 'ExecutionInfo',
    as InstanceOf['Google::Cloud::Dataqna::V1alpha::Question::ExecutionInfo'];

coerce 'ExecutionInfo',
    from HashRef, via { 'Google::Cloud::Dataqna::V1alpha::Question::ExecutionInfo'->new($_) };

declare 'RepeatedExecutionInfo',
    as ArrayRef[ExecutionInfo()];

coerce 'RepeatedExecutionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataqna::V1alpha::Question::ExecutionInfo'->new($_) } @$_ ] };

declare 'MapStringExecutionInfo',
    as HashRef[ExecutionInfo()];

declare 'JobExecutionState',
    as (Int | Str);

declare 'BigQueryJob',
    as InstanceOf['Google::Cloud::Dataqna::V1alpha::Question::BigQueryJob'];

coerce 'BigQueryJob',
    from HashRef, via { 'Google::Cloud::Dataqna::V1alpha::Question::BigQueryJob'->new($_) };

declare 'RepeatedBigQueryJob',
    as ArrayRef[BigQueryJob()];

coerce 'RepeatedBigQueryJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataqna::V1alpha::Question::BigQueryJob'->new($_) } @$_ ] };

declare 'MapStringBigQueryJob',
    as HashRef[BigQueryJob()];

declare 'Interpretation',
    as InstanceOf['Google::Cloud::Dataqna::V1alpha::Question::Interpretation'];

coerce 'Interpretation',
    from HashRef, via { 'Google::Cloud::Dataqna::V1alpha::Question::Interpretation'->new($_) };

declare 'RepeatedInterpretation',
    as ArrayRef[Interpretation()];

coerce 'RepeatedInterpretation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataqna::V1alpha::Question::Interpretation'->new($_) } @$_ ] };

declare 'MapStringInterpretation',
    as HashRef[Interpretation()];

declare 'DataQuery',
    as InstanceOf['Google::Cloud::Dataqna::V1alpha::Question::DataQuery'];

coerce 'DataQuery',
    from HashRef, via { 'Google::Cloud::Dataqna::V1alpha::Question::DataQuery'->new($_) };

declare 'RepeatedDataQuery',
    as ArrayRef[DataQuery()];

coerce 'RepeatedDataQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataqna::V1alpha::Question::DataQuery'->new($_) } @$_ ] };

declare 'MapStringDataQuery',
    as HashRef[DataQuery()];

declare 'HumanReadable',
    as InstanceOf['Google::Cloud::Dataqna::V1alpha::Question::HumanReadable'];

coerce 'HumanReadable',
    from HashRef, via { 'Google::Cloud::Dataqna::V1alpha::Question::HumanReadable'->new($_) };

declare 'RepeatedHumanReadable',
    as ArrayRef[HumanReadable()];

coerce 'RepeatedHumanReadable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataqna::V1alpha::Question::HumanReadable'->new($_) } @$_ ] };

declare 'MapStringHumanReadable',
    as HashRef[HumanReadable()];

declare 'InterpretationStructure',
    as InstanceOf['Google::Cloud::Dataqna::V1alpha::Question::InterpretationStructure'];

coerce 'InterpretationStructure',
    from HashRef, via { 'Google::Cloud::Dataqna::V1alpha::Question::InterpretationStructure'->new($_) };

declare 'RepeatedInterpretationStructure',
    as ArrayRef[InterpretationStructure()];

coerce 'RepeatedInterpretationStructure',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataqna::V1alpha::Question::InterpretationStructure'->new($_) } @$_ ] };

declare 'MapStringInterpretationStructure',
    as HashRef[InterpretationStructure()];

declare 'VisualizationType',
    as (Int | Str);

declare 'ColumnInfo',
    as InstanceOf['Google::Cloud::Dataqna::V1alpha::Question::InterpretationStructure::ColumnInfo'];

coerce 'ColumnInfo',
    from HashRef, via { 'Google::Cloud::Dataqna::V1alpha::Question::InterpretationStructure::ColumnInfo'->new($_) };

declare 'RepeatedColumnInfo',
    as ArrayRef[ColumnInfo()];

coerce 'RepeatedColumnInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataqna::V1alpha::Question::InterpretationStructure::ColumnInfo'->new($_) } @$_ ] };

declare 'MapStringColumnInfo',
    as HashRef[ColumnInfo()];

declare 'DebugFlags',
    as InstanceOf['Google::Cloud::Dataqna::V1alpha::Question::DebugFlags'];

coerce 'DebugFlags',
    from HashRef, via { 'Google::Cloud::Dataqna::V1alpha::Question::DebugFlags'->new($_) };

declare 'RepeatedDebugFlags',
    as ArrayRef[DebugFlags()];

coerce 'RepeatedDebugFlags',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataqna::V1alpha::Question::DebugFlags'->new($_) } @$_ ] };

declare 'MapStringDebugFlags',
    as HashRef[DebugFlags()];

1;

__END__

=head1 NAME

Google::Cloud::Dataqna::V1alpha::Question::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
