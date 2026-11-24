package Google::Cloud::Databasecenter::V1beta::MetricData::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Metrics',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::MetricData::Metrics'];

coerce 'Metrics',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::MetricData::Metrics'->new($_) };

declare 'RepeatedMetrics',
    as ArrayRef[Metrics()];

coerce 'RepeatedMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::MetricData::Metrics'->new($_) } @$_ ] };

declare 'MapStringMetrics',
    as HashRef[Metrics()];

declare 'MetricData',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::MetricData::MetricData'];

coerce 'MetricData',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::MetricData::MetricData'->new($_) };

declare 'RepeatedMetricData',
    as ArrayRef[MetricData()];

coerce 'RepeatedMetricData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::MetricData::MetricData'->new($_) } @$_ ] };

declare 'MapStringMetricData',
    as HashRef[MetricData()];

declare 'TypedValue',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::MetricData::TypedValue'];

coerce 'TypedValue',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::MetricData::TypedValue'->new($_) };

declare 'RepeatedTypedValue',
    as ArrayRef[TypedValue()];

coerce 'RepeatedTypedValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::MetricData::TypedValue'->new($_) } @$_ ] };

declare 'MapStringTypedValue',
    as HashRef[TypedValue()];

1;

__END__

=head1 NAME

Google::Cloud::Databasecenter::V1beta::MetricData::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
