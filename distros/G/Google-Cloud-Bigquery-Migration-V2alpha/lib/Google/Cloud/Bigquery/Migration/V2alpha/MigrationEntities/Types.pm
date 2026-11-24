package Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'MigrationWorkflow',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::MigrationWorkflow'];

coerce 'MigrationWorkflow',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::MigrationWorkflow'->new($_) };

declare 'RepeatedMigrationWorkflow',
    as ArrayRef[MigrationWorkflow()];

coerce 'RepeatedMigrationWorkflow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::MigrationWorkflow'->new($_) } @$_ ] };

declare 'MapStringMigrationWorkflow',
    as HashRef[MigrationWorkflow()];

declare 'State',
    as (Int | Str);

declare 'TasksEntry',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::MigrationWorkflow::TasksEntry'];

coerce 'TasksEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::MigrationWorkflow::TasksEntry'->new($_) };

declare 'RepeatedTasksEntry',
    as ArrayRef[TasksEntry()];

coerce 'RepeatedTasksEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::MigrationWorkflow::TasksEntry'->new($_) } @$_ ] };

declare 'MapStringTasksEntry',
    as HashRef[TasksEntry()];

declare 'MigrationTask',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::MigrationTask'];

coerce 'MigrationTask',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::MigrationTask'->new($_) };

declare 'RepeatedMigrationTask',
    as ArrayRef[MigrationTask()];

coerce 'RepeatedMigrationTask',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::MigrationTask'->new($_) } @$_ ] };

declare 'MapStringMigrationTask',
    as HashRef[MigrationTask()];

declare 'State',
    as (Int | Str);

declare 'MigrationSubtask',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::MigrationSubtask'];

coerce 'MigrationSubtask',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::MigrationSubtask'->new($_) };

declare 'RepeatedMigrationSubtask',
    as ArrayRef[MigrationSubtask()];

coerce 'RepeatedMigrationSubtask',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::MigrationSubtask'->new($_) } @$_ ] };

declare 'MapStringMigrationSubtask',
    as HashRef[MigrationSubtask()];

declare 'State',
    as (Int | Str);

declare 'MigrationTaskOrchestrationResult',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::MigrationTaskOrchestrationResult'];

coerce 'MigrationTaskOrchestrationResult',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::MigrationTaskOrchestrationResult'->new($_) };

declare 'RepeatedMigrationTaskOrchestrationResult',
    as ArrayRef[MigrationTaskOrchestrationResult()];

coerce 'RepeatedMigrationTaskOrchestrationResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::MigrationTaskOrchestrationResult'->new($_) } @$_ ] };

declare 'MapStringMigrationTaskOrchestrationResult',
    as HashRef[MigrationTaskOrchestrationResult()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Migration::V2alpha::MigrationEntities::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
