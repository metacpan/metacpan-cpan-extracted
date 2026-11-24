package Google::Cloud::Scheduler::V1::Job::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Job',
    as InstanceOf['Google::Cloud::Scheduler::V1::Job::Job'];

coerce 'Job',
    from HashRef, via { 'Google::Cloud::Scheduler::V1::Job::Job'->new($_) };

declare 'RepeatedJob',
    as ArrayRef[Job()];

coerce 'RepeatedJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Scheduler::V1::Job::Job'->new($_) } @$_ ] };

declare 'MapStringJob',
    as HashRef[Job()];

declare 'State',
    as (Int | Str);

declare 'RetryConfig',
    as InstanceOf['Google::Cloud::Scheduler::V1::Job::RetryConfig'];

coerce 'RetryConfig',
    from HashRef, via { 'Google::Cloud::Scheduler::V1::Job::RetryConfig'->new($_) };

declare 'RepeatedRetryConfig',
    as ArrayRef[RetryConfig()];

coerce 'RepeatedRetryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Scheduler::V1::Job::RetryConfig'->new($_) } @$_ ] };

declare 'MapStringRetryConfig',
    as HashRef[RetryConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Scheduler::V1::Job::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
