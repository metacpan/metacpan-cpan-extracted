package Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TimeSeries',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics::TimeSeries'];

coerce 'TimeSeries',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics::TimeSeries'->new($_) };

declare 'RepeatedTimeSeries',
    as ArrayRef[TimeSeries()];

coerce 'RepeatedTimeSeries',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics::TimeSeries'->new($_) } @$_ ] };

declare 'MapStringTimeSeries',
    as HashRef[TimeSeries()];

declare 'Point',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics::Point'];

coerce 'Point',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics::Point'->new($_) };

declare 'RepeatedPoint',
    as ArrayRef[Point()];

coerce 'RepeatedPoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics::Point'->new($_) } @$_ ] };

declare 'MapStringPoint',
    as HashRef[Point()];

declare 'TimeInterval',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics::TimeInterval'];

coerce 'TimeInterval',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics::TimeInterval'->new($_) };

declare 'RepeatedTimeInterval',
    as ArrayRef[TimeInterval()];

coerce 'RepeatedTimeInterval',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics::TimeInterval'->new($_) } @$_ ] };

declare 'MapStringTimeInterval',
    as HashRef[TimeInterval()];

declare 'TypedValue',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics::TypedValue'];

coerce 'TypedValue',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics::TypedValue'->new($_) };

declare 'RepeatedTypedValue',
    as ArrayRef[TypedValue()];

coerce 'RepeatedTypedValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics::TypedValue'->new($_) } @$_ ] };

declare 'MapStringTypedValue',
    as HashRef[TypedValue()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
