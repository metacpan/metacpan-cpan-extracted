package Google::Spanner::V1::Transaction::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TransactionOptions',
    as InstanceOf['Google::Spanner::V1::Transaction::TransactionOptions'];

coerce 'TransactionOptions',
    from HashRef, via { 'Google::Spanner::V1::Transaction::TransactionOptions'->new($_) };

declare 'RepeatedTransactionOptions',
    as ArrayRef[TransactionOptions()];

coerce 'RepeatedTransactionOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Transaction::TransactionOptions'->new($_) } @$_ ] };

declare 'MapStringTransactionOptions',
    as HashRef[TransactionOptions()];

declare 'IsolationLevel',
    as (Int | Str);

declare 'ReadWrite',
    as InstanceOf['Google::Spanner::V1::Transaction::TransactionOptions::ReadWrite'];

coerce 'ReadWrite',
    from HashRef, via { 'Google::Spanner::V1::Transaction::TransactionOptions::ReadWrite'->new($_) };

declare 'RepeatedReadWrite',
    as ArrayRef[ReadWrite()];

coerce 'RepeatedReadWrite',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Transaction::TransactionOptions::ReadWrite'->new($_) } @$_ ] };

declare 'MapStringReadWrite',
    as HashRef[ReadWrite()];

declare 'ReadLockMode',
    as (Int | Str);

declare 'PartitionedDml',
    as InstanceOf['Google::Spanner::V1::Transaction::TransactionOptions::PartitionedDml'];

coerce 'PartitionedDml',
    from HashRef, via { 'Google::Spanner::V1::Transaction::TransactionOptions::PartitionedDml'->new($_) };

declare 'RepeatedPartitionedDml',
    as ArrayRef[PartitionedDml()];

coerce 'RepeatedPartitionedDml',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Transaction::TransactionOptions::PartitionedDml'->new($_) } @$_ ] };

declare 'MapStringPartitionedDml',
    as HashRef[PartitionedDml()];

declare 'ReadOnly',
    as InstanceOf['Google::Spanner::V1::Transaction::TransactionOptions::ReadOnly'];

coerce 'ReadOnly',
    from HashRef, via { 'Google::Spanner::V1::Transaction::TransactionOptions::ReadOnly'->new($_) };

declare 'RepeatedReadOnly',
    as ArrayRef[ReadOnly()];

coerce 'RepeatedReadOnly',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Transaction::TransactionOptions::ReadOnly'->new($_) } @$_ ] };

declare 'MapStringReadOnly',
    as HashRef[ReadOnly()];

declare 'Transaction',
    as InstanceOf['Google::Spanner::V1::Transaction::Transaction'];

coerce 'Transaction',
    from HashRef, via { 'Google::Spanner::V1::Transaction::Transaction'->new($_) };

declare 'RepeatedTransaction',
    as ArrayRef[Transaction()];

coerce 'RepeatedTransaction',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Transaction::Transaction'->new($_) } @$_ ] };

declare 'MapStringTransaction',
    as HashRef[Transaction()];

declare 'TransactionSelector',
    as InstanceOf['Google::Spanner::V1::Transaction::TransactionSelector'];

coerce 'TransactionSelector',
    from HashRef, via { 'Google::Spanner::V1::Transaction::TransactionSelector'->new($_) };

declare 'RepeatedTransactionSelector',
    as ArrayRef[TransactionSelector()];

coerce 'RepeatedTransactionSelector',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Transaction::TransactionSelector'->new($_) } @$_ ] };

declare 'MapStringTransactionSelector',
    as HashRef[TransactionSelector()];

declare 'MultiplexedSessionPrecommitToken',
    as InstanceOf['Google::Spanner::V1::Transaction::MultiplexedSessionPrecommitToken'];

coerce 'MultiplexedSessionPrecommitToken',
    from HashRef, via { 'Google::Spanner::V1::Transaction::MultiplexedSessionPrecommitToken'->new($_) };

declare 'RepeatedMultiplexedSessionPrecommitToken',
    as ArrayRef[MultiplexedSessionPrecommitToken()];

coerce 'RepeatedMultiplexedSessionPrecommitToken',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::Transaction::MultiplexedSessionPrecommitToken'->new($_) } @$_ ] };

declare 'MapStringMultiplexedSessionPrecommitToken',
    as HashRef[MultiplexedSessionPrecommitToken()];

1;

__END__

=head1 NAME

Google::Spanner::V1::Transaction::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
