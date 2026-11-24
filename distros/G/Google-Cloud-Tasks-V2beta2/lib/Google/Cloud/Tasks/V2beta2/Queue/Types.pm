package Google::Cloud::Tasks::V2beta2::Queue::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Queue',
    as InstanceOf['Google::Cloud::Tasks::V2beta2::Queue::Queue'];

coerce 'Queue',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta2::Queue::Queue'->new($_) };

declare 'RepeatedQueue',
    as ArrayRef[Queue()];

coerce 'RepeatedQueue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta2::Queue::Queue'->new($_) } @$_ ] };

declare 'MapStringQueue',
    as HashRef[Queue()];

declare 'State',
    as (Int | Str);

declare 'RateLimits',
    as InstanceOf['Google::Cloud::Tasks::V2beta2::Queue::RateLimits'];

coerce 'RateLimits',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta2::Queue::RateLimits'->new($_) };

declare 'RepeatedRateLimits',
    as ArrayRef[RateLimits()];

coerce 'RepeatedRateLimits',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta2::Queue::RateLimits'->new($_) } @$_ ] };

declare 'MapStringRateLimits',
    as HashRef[RateLimits()];

declare 'RetryConfig',
    as InstanceOf['Google::Cloud::Tasks::V2beta2::Queue::RetryConfig'];

coerce 'RetryConfig',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta2::Queue::RetryConfig'->new($_) };

declare 'RepeatedRetryConfig',
    as ArrayRef[RetryConfig()];

coerce 'RepeatedRetryConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta2::Queue::RetryConfig'->new($_) } @$_ ] };

declare 'MapStringRetryConfig',
    as HashRef[RetryConfig()];

declare 'QueueStats',
    as InstanceOf['Google::Cloud::Tasks::V2beta2::Queue::QueueStats'];

coerce 'QueueStats',
    from HashRef, via { 'Google::Cloud::Tasks::V2beta2::Queue::QueueStats'->new($_) };

declare 'RepeatedQueueStats',
    as ArrayRef[QueueStats()];

coerce 'RepeatedQueueStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Tasks::V2beta2::Queue::QueueStats'->new($_) } @$_ ] };

declare 'MapStringQueueStats',
    as HashRef[QueueStats()];

1;

__END__

=head1 NAME

Google::Cloud::Tasks::V2beta2::Queue::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
