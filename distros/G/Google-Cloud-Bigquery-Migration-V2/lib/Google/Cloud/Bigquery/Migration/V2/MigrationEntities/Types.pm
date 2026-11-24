package Google::Cloud::Bigquery::Migration::V2::MigrationEntities::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'MigrationWorkflow',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::MigrationEntities::MigrationWorkflow'];

coerce 'MigrationWorkflow',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::MigrationEntities::MigrationWorkflow'->new($_) };

declare 'RepeatedMigrationWorkflow',
    as ArrayRef[MigrationWorkflow()];

coerce 'RepeatedMigrationWorkflow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::MigrationEntities::MigrationWorkflow'->new($_) } @$_ ] };

declare 'MapStringMigrationWorkflow',
    as HashRef[MigrationWorkflow()];

declare 'State',
    as (Int | Str);

declare 'TasksEntry',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::MigrationEntities::MigrationWorkflow::TasksEntry'];

coerce 'TasksEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::MigrationEntities::MigrationWorkflow::TasksEntry'->new($_) };

declare 'RepeatedTasksEntry',
    as ArrayRef[TasksEntry()];

coerce 'RepeatedTasksEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::MigrationEntities::MigrationWorkflow::TasksEntry'->new($_) } @$_ ] };

declare 'MapStringTasksEntry',
    as HashRef[TasksEntry()];

declare 'MigrationTask',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::MigrationEntities::MigrationTask'];

coerce 'MigrationTask',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::MigrationEntities::MigrationTask'->new($_) };

declare 'RepeatedMigrationTask',
    as ArrayRef[MigrationTask()];

coerce 'RepeatedMigrationTask',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::MigrationEntities::MigrationTask'->new($_) } @$_ ] };

declare 'MapStringMigrationTask',
    as HashRef[MigrationTask()];

declare 'State',
    as (Int | Str);

declare 'MigrationSubtask',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::MigrationEntities::MigrationSubtask'];

coerce 'MigrationSubtask',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::MigrationEntities::MigrationSubtask'->new($_) };

declare 'RepeatedMigrationSubtask',
    as ArrayRef[MigrationSubtask()];

coerce 'RepeatedMigrationSubtask',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::MigrationEntities::MigrationSubtask'->new($_) } @$_ ] };

declare 'MapStringMigrationSubtask',
    as HashRef[MigrationSubtask()];

declare 'State',
    as (Int | Str);

declare 'MigrationTaskResult',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::MigrationEntities::MigrationTaskResult'];

coerce 'MigrationTaskResult',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::MigrationEntities::MigrationTaskResult'->new($_) };

declare 'RepeatedMigrationTaskResult',
    as ArrayRef[MigrationTaskResult()];

coerce 'RepeatedMigrationTaskResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::MigrationEntities::MigrationTaskResult'->new($_) } @$_ ] };

declare 'MapStringMigrationTaskResult',
    as HashRef[MigrationTaskResult()];

declare 'TaskOutputsEntry',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::MigrationEntities::MigrationTaskResult::TaskOutputsEntry'];

coerce 'TaskOutputsEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::MigrationEntities::MigrationTaskResult::TaskOutputsEntry'->new($_) };

declare 'RepeatedTaskOutputsEntry',
    as ArrayRef[TaskOutputsEntry()];

coerce 'RepeatedTaskOutputsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::MigrationEntities::MigrationTaskResult::TaskOutputsEntry'->new($_) } @$_ ] };

declare 'MapStringTaskOutputsEntry',
    as HashRef[TaskOutputsEntry()];

declare 'TranslationTaskResult',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::MigrationEntities::TranslationTaskResult'];

coerce 'TranslationTaskResult',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::MigrationEntities::TranslationTaskResult'->new($_) };

declare 'RepeatedTranslationTaskResult',
    as ArrayRef[TranslationTaskResult()];

coerce 'RepeatedTranslationTaskResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::MigrationEntities::TranslationTaskResult'->new($_) } @$_ ] };

declare 'MapStringTranslationTaskResult',
    as HashRef[TranslationTaskResult()];

declare 'TaskOutput',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::MigrationEntities::TaskOutput'];

coerce 'TaskOutput',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::MigrationEntities::TaskOutput'->new($_) };

declare 'RepeatedTaskOutput',
    as ArrayRef[TaskOutput()];

coerce 'RepeatedTaskOutput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::MigrationEntities::TaskOutput'->new($_) } @$_ ] };

declare 'MapStringTaskOutput',
    as HashRef[TaskOutput()];

declare 'State',
    as (Int | Str);

declare 'LineageOutput',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::MigrationEntities::LineageOutput'];

coerce 'LineageOutput',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::MigrationEntities::LineageOutput'->new($_) };

declare 'RepeatedLineageOutput',
    as ArrayRef[LineageOutput()];

coerce 'RepeatedLineageOutput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::MigrationEntities::LineageOutput'->new($_) } @$_ ] };

declare 'MapStringLineageOutput',
    as HashRef[LineageOutput()];

declare 'RecognizedInput',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::MigrationEntities::LineageOutput::RecognizedInput'];

coerce 'RecognizedInput',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::MigrationEntities::LineageOutput::RecognizedInput'->new($_) };

declare 'RepeatedRecognizedInput',
    as ArrayRef[RecognizedInput()];

coerce 'RepeatedRecognizedInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::MigrationEntities::LineageOutput::RecognizedInput'->new($_) } @$_ ] };

declare 'MapStringRecognizedInput',
    as HashRef[RecognizedInput()];

declare 'Type',
    as (Int | Str);

declare 'ProgressReport',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::MigrationEntities::LineageOutput::ProgressReport'];

coerce 'ProgressReport',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::MigrationEntities::LineageOutput::ProgressReport'->new($_) };

declare 'RepeatedProgressReport',
    as ArrayRef[ProgressReport()];

coerce 'RepeatedProgressReport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::MigrationEntities::LineageOutput::ProgressReport'->new($_) } @$_ ] };

declare 'MapStringProgressReport',
    as HashRef[ProgressReport()];

declare 'ProcessingStage',
    as (Int | Str);

declare 'WorkSummary',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::MigrationEntities::LineageOutput::ProgressReport::WorkSummary'];

coerce 'WorkSummary',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::MigrationEntities::LineageOutput::ProgressReport::WorkSummary'->new($_) };

declare 'RepeatedWorkSummary',
    as ArrayRef[WorkSummary()];

coerce 'RepeatedWorkSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::MigrationEntities::LineageOutput::ProgressReport::WorkSummary'->new($_) } @$_ ] };

declare 'MapStringWorkSummary',
    as HashRef[WorkSummary()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Migration::V2::MigrationEntities::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
