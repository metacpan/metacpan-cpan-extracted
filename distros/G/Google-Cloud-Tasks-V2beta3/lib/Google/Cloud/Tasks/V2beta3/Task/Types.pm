package Google::Cloud::Tasks::V2beta3::Task::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Task',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Task::Task'];

coerce 'Task',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Task::Task'->new($_) };

declare 'RepeatedTask',
    as ArrayRef[Task()];

coerce 'RepeatedTask',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Task::Task'->new($_) } @$_ ] };

declare 'MapStringTask',
    as HashRef[Task()];

declare 'View',
    as (Int | Str);

declare 'Attempt',
    as InstanceOf['Google::Cloud::Tasks::V2beta3::Task::Attempt'];

coerce 'Attempt',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta3::Task::Attempt'->new($_) };

declare 'RepeatedAttempt',
    as ArrayRef[Attempt()];

coerce 'RepeatedAttempt',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta3::Task::Attempt'->new($_) } @$_ ] };

declare 'MapStringAttempt',
    as HashRef[Attempt()];

1;

__END__

=head1 NAME

Google::Cloud::Tasks::V2beta3::Task::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
