package Google::Datastore::V1::AggregationResult::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AggregationResult',
    as InstanceOf['Google::Datastore::V1::AggregationResult::AggregationResult'];

coerce 'AggregationResult',
    from HashRef, via { 'Google::Datastore::V1::AggregationResult::AggregationResult'->new($_) };

declare 'RepeatedAggregationResult',
    as ArrayRef[AggregationResult()];

coerce 'RepeatedAggregationResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1::AggregationResult::AggregationResult'->new($_) } @$_ ] };

declare 'MapStringAggregationResult',
    as HashRef[AggregationResult()];

declare 'AggregatePropertiesEntry',
    as InstanceOf['Google::Datastore::V1::AggregationResult::AggregationResult::AggregatePropertiesEntry'];

coerce 'AggregatePropertiesEntry',
    from HashRef, via { 'Google::Datastore::V1::AggregationResult::AggregationResult::AggregatePropertiesEntry'->new($_) };

declare 'RepeatedAggregatePropertiesEntry',
    as ArrayRef[AggregatePropertiesEntry()];

coerce 'RepeatedAggregatePropertiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1::AggregationResult::AggregationResult::AggregatePropertiesEntry'->new($_) } @$_ ] };

declare 'MapStringAggregatePropertiesEntry',
    as HashRef[AggregatePropertiesEntry()];

declare 'AggregationResultBatch',
    as InstanceOf['Google::Datastore::V1::AggregationResult::AggregationResultBatch'];

coerce 'AggregationResultBatch',
    from HashRef, via { 'Google::Datastore::V1::AggregationResult::AggregationResultBatch'->new($_) };

declare 'RepeatedAggregationResultBatch',
    as ArrayRef[AggregationResultBatch()];

coerce 'RepeatedAggregationResultBatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Datastore::V1::AggregationResult::AggregationResultBatch'->new($_) } @$_ ] };

declare 'MapStringAggregationResultBatch',
    as HashRef[AggregationResultBatch()];

1;

__END__

=head1 NAME

Google::Datastore::V1::AggregationResult::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
