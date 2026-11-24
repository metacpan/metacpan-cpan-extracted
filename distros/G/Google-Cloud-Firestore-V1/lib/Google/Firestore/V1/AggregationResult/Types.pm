package Google::Firestore::V1::AggregationResult::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AggregationResult',
    as InstanceOf['Google::Firestore::V1::AggregationResult::AggregationResult'];

coerce 'AggregationResult',
    from HashRef, via { 'Google::Firestore::V1::AggregationResult::AggregationResult'->new($_) };

declare 'RepeatedAggregationResult',
    as ArrayRef[AggregationResult()];

coerce 'RepeatedAggregationResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1::AggregationResult::AggregationResult'->new($_) } @$_ ] };

declare 'MapStringAggregationResult',
    as HashRef[AggregationResult()];

declare 'AggregateFieldsEntry',
    as InstanceOf['Google::Firestore::V1::AggregationResult::AggregationResult::AggregateFieldsEntry'];

coerce 'AggregateFieldsEntry',
    from HashRef, via { 'Google::Firestore::V1::AggregationResult::AggregationResult::AggregateFieldsEntry'->new($_) };

declare 'RepeatedAggregateFieldsEntry',
    as ArrayRef[AggregateFieldsEntry()];

coerce 'RepeatedAggregateFieldsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1::AggregationResult::AggregationResult::AggregateFieldsEntry'->new($_) } @$_ ] };

declare 'MapStringAggregateFieldsEntry',
    as HashRef[AggregateFieldsEntry()];

1;

__END__

=head1 NAME

Google::Firestore::V1::AggregationResult::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
