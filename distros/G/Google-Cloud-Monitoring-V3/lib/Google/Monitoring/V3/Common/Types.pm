package Google::Monitoring::V3::Common::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ComparisonType',
    as (Int | Str);

declare 'ServiceTier',
    as (Int | Str);

declare 'TypedValue',
    as InstanceOf['Google::Monitoring::V3::Common::TypedValue'];

coerce 'TypedValue',
    from HashRef, via { 'Google::Monitoring::V3::Common::TypedValue'->new($_) };

declare 'RepeatedTypedValue',
    as ArrayRef[TypedValue()];

coerce 'RepeatedTypedValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Common::TypedValue'->new($_) } @$_ ] };

declare 'MapStringTypedValue',
    as HashRef[TypedValue()];

declare 'TimeInterval',
    as InstanceOf['Google::Monitoring::V3::Common::TimeInterval'];

coerce 'TimeInterval',
    from HashRef, via { 'Google::Monitoring::V3::Common::TimeInterval'->new($_) };

declare 'RepeatedTimeInterval',
    as ArrayRef[TimeInterval()];

coerce 'RepeatedTimeInterval',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Common::TimeInterval'->new($_) } @$_ ] };

declare 'MapStringTimeInterval',
    as HashRef[TimeInterval()];

declare 'Aggregation',
    as InstanceOf['Google::Monitoring::V3::Common::Aggregation'];

coerce 'Aggregation',
    from HashRef, via { 'Google::Monitoring::V3::Common::Aggregation'->new($_) };

declare 'RepeatedAggregation',
    as ArrayRef[Aggregation()];

coerce 'RepeatedAggregation',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::Common::Aggregation'->new($_) } @$_ ] };

declare 'MapStringAggregation',
    as HashRef[Aggregation()];

declare 'Aligner',
    as (Int | Str);

declare 'Reducer',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Monitoring::V3::Common::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
