package Google::Cloud::Tasks::V2beta2::Task::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Task',
    as InstanceOf['Google::Cloud::Tasks::V2beta2::Task::Task'];

coerce 'Task',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta2::Task::Task'->new($_) };

declare 'RepeatedTask',
    as ArrayRef[Task()];

coerce 'RepeatedTask',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta2::Task::Task'->new($_) } @$_ ] };

declare 'MapStringTask',
    as HashRef[Task()];

declare 'View',
    as (Int | Str);

declare 'TaskStatus',
    as InstanceOf['Google::Cloud::Tasks::V2beta2::Task::TaskStatus'];

coerce 'TaskStatus',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta2::Task::TaskStatus'->new($_) };

declare 'RepeatedTaskStatus',
    as ArrayRef[TaskStatus()];

coerce 'RepeatedTaskStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta2::Task::TaskStatus'->new($_) } @$_ ] };

declare 'MapStringTaskStatus',
    as HashRef[TaskStatus()];

declare 'AttemptStatus',
    as InstanceOf['Google::Cloud::Tasks::V2beta2::Task::AttemptStatus'];

coerce 'AttemptStatus',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta2::Task::AttemptStatus'->new($_) };

declare 'RepeatedAttemptStatus',
    as ArrayRef[AttemptStatus()];

coerce 'RepeatedAttemptStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta2::Task::AttemptStatus'->new($_) } @$_ ] };

declare 'MapStringAttemptStatus',
    as HashRef[AttemptStatus()];

1;

__END__

=head1 NAME

Google::Cloud::Tasks::V2beta2::Task::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
