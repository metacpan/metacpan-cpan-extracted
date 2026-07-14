package Google::Api::Metric::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'MetricDescriptor',
    as InstanceOf['Google::Api::Metric::MetricDescriptor'];

coerce 'MetricDescriptor',
    from HashRef, via { 'Google::Api::Metric::MetricDescriptor'->new($_) };

declare 'RepeatedMetricDescriptor',
    as ArrayRef[MetricDescriptor()];

coerce 'RepeatedMetricDescriptor',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Metric::MetricDescriptor'->new($_) } @$_ ] };

declare 'MapStringMetricDescriptor',
    as HashRef[MetricDescriptor()];

declare 'MetricKind',
    as (Int | Str);

declare 'ValueType',
    as (Int | Str);

declare 'MetricDescriptorMetadata',
    as InstanceOf['Google::Api::Metric::MetricDescriptor::MetricDescriptorMetadata'];

coerce 'MetricDescriptorMetadata',
    from HashRef, via { 'Google::Api::Metric::MetricDescriptor::MetricDescriptorMetadata'->new($_) };

declare 'RepeatedMetricDescriptorMetadata',
    as ArrayRef[MetricDescriptorMetadata()];

coerce 'RepeatedMetricDescriptorMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Metric::MetricDescriptor::MetricDescriptorMetadata'->new($_) } @$_ ] };

declare 'MapStringMetricDescriptorMetadata',
    as HashRef[MetricDescriptorMetadata()];

declare 'TimeSeriesResourceHierarchyLevel',
    as (Int | Str);

declare 'Metric',
    as InstanceOf['Google::Api::Metric::Metric'];

coerce 'Metric',
    from HashRef, via { 'Google::Api::Metric::Metric'->new($_) };

declare 'RepeatedMetric',
    as ArrayRef[Metric()];

coerce 'RepeatedMetric',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Metric::Metric'->new($_) } @$_ ] };

declare 'MapStringMetric',
    as HashRef[Metric()];

declare 'LabelsEntry',
    as InstanceOf['Google::Api::Metric::Metric::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Api::Metric::Metric::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Metric::Metric::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

1;
