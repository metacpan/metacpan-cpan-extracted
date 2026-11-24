package Google::Monitoring::V3::MetricService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListMonitoredResourceDescriptorsRequest',
    as InstanceOf['Google::Monitoring::V3::MetricService::ListMonitoredResourceDescriptorsRequest'];

coerce 'ListMonitoredResourceDescriptorsRequest',
    from HashRef, via { 'Google::Monitoring::V3::MetricService::ListMonitoredResourceDescriptorsRequest'->new($_) };

declare 'RepeatedListMonitoredResourceDescriptorsRequest',
    as ArrayRef[ListMonitoredResourceDescriptorsRequest()];

coerce 'RepeatedListMonitoredResourceDescriptorsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::MetricService::ListMonitoredResourceDescriptorsRequest'->new($_) } @$_ ] };

declare 'MapStringListMonitoredResourceDescriptorsRequest',
    as HashRef[ListMonitoredResourceDescriptorsRequest()];

declare 'ListMonitoredResourceDescriptorsResponse',
    as InstanceOf['Google::Monitoring::V3::MetricService::ListMonitoredResourceDescriptorsResponse'];

coerce 'ListMonitoredResourceDescriptorsResponse',
    from HashRef, via { 'Google::Monitoring::V3::MetricService::ListMonitoredResourceDescriptorsResponse'->new($_) };

declare 'RepeatedListMonitoredResourceDescriptorsResponse',
    as ArrayRef[ListMonitoredResourceDescriptorsResponse()];

coerce 'RepeatedListMonitoredResourceDescriptorsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::MetricService::ListMonitoredResourceDescriptorsResponse'->new($_) } @$_ ] };

declare 'MapStringListMonitoredResourceDescriptorsResponse',
    as HashRef[ListMonitoredResourceDescriptorsResponse()];

declare 'GetMonitoredResourceDescriptorRequest',
    as InstanceOf['Google::Monitoring::V3::MetricService::GetMonitoredResourceDescriptorRequest'];

coerce 'GetMonitoredResourceDescriptorRequest',
    from HashRef, via { 'Google::Monitoring::V3::MetricService::GetMonitoredResourceDescriptorRequest'->new($_) };

declare 'RepeatedGetMonitoredResourceDescriptorRequest',
    as ArrayRef[GetMonitoredResourceDescriptorRequest()];

coerce 'RepeatedGetMonitoredResourceDescriptorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::MetricService::GetMonitoredResourceDescriptorRequest'->new($_) } @$_ ] };

declare 'MapStringGetMonitoredResourceDescriptorRequest',
    as HashRef[GetMonitoredResourceDescriptorRequest()];

declare 'ListMetricDescriptorsRequest',
    as InstanceOf['Google::Monitoring::V3::MetricService::ListMetricDescriptorsRequest'];

coerce 'ListMetricDescriptorsRequest',
    from HashRef, via { 'Google::Monitoring::V3::MetricService::ListMetricDescriptorsRequest'->new($_) };

declare 'RepeatedListMetricDescriptorsRequest',
    as ArrayRef[ListMetricDescriptorsRequest()];

coerce 'RepeatedListMetricDescriptorsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::MetricService::ListMetricDescriptorsRequest'->new($_) } @$_ ] };

declare 'MapStringListMetricDescriptorsRequest',
    as HashRef[ListMetricDescriptorsRequest()];

declare 'ListMetricDescriptorsResponse',
    as InstanceOf['Google::Monitoring::V3::MetricService::ListMetricDescriptorsResponse'];

coerce 'ListMetricDescriptorsResponse',
    from HashRef, via { 'Google::Monitoring::V3::MetricService::ListMetricDescriptorsResponse'->new($_) };

declare 'RepeatedListMetricDescriptorsResponse',
    as ArrayRef[ListMetricDescriptorsResponse()];

coerce 'RepeatedListMetricDescriptorsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::MetricService::ListMetricDescriptorsResponse'->new($_) } @$_ ] };

declare 'MapStringListMetricDescriptorsResponse',
    as HashRef[ListMetricDescriptorsResponse()];

declare 'GetMetricDescriptorRequest',
    as InstanceOf['Google::Monitoring::V3::MetricService::GetMetricDescriptorRequest'];

coerce 'GetMetricDescriptorRequest',
    from HashRef, via { 'Google::Monitoring::V3::MetricService::GetMetricDescriptorRequest'->new($_) };

declare 'RepeatedGetMetricDescriptorRequest',
    as ArrayRef[GetMetricDescriptorRequest()];

coerce 'RepeatedGetMetricDescriptorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::MetricService::GetMetricDescriptorRequest'->new($_) } @$_ ] };

declare 'MapStringGetMetricDescriptorRequest',
    as HashRef[GetMetricDescriptorRequest()];

declare 'CreateMetricDescriptorRequest',
    as InstanceOf['Google::Monitoring::V3::MetricService::CreateMetricDescriptorRequest'];

coerce 'CreateMetricDescriptorRequest',
    from HashRef, via { 'Google::Monitoring::V3::MetricService::CreateMetricDescriptorRequest'->new($_) };

declare 'RepeatedCreateMetricDescriptorRequest',
    as ArrayRef[CreateMetricDescriptorRequest()];

coerce 'RepeatedCreateMetricDescriptorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::MetricService::CreateMetricDescriptorRequest'->new($_) } @$_ ] };

declare 'MapStringCreateMetricDescriptorRequest',
    as HashRef[CreateMetricDescriptorRequest()];

declare 'DeleteMetricDescriptorRequest',
    as InstanceOf['Google::Monitoring::V3::MetricService::DeleteMetricDescriptorRequest'];

coerce 'DeleteMetricDescriptorRequest',
    from HashRef, via { 'Google::Monitoring::V3::MetricService::DeleteMetricDescriptorRequest'->new($_) };

declare 'RepeatedDeleteMetricDescriptorRequest',
    as ArrayRef[DeleteMetricDescriptorRequest()];

coerce 'RepeatedDeleteMetricDescriptorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::MetricService::DeleteMetricDescriptorRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteMetricDescriptorRequest',
    as HashRef[DeleteMetricDescriptorRequest()];

declare 'ListTimeSeriesRequest',
    as InstanceOf['Google::Monitoring::V3::MetricService::ListTimeSeriesRequest'];

coerce 'ListTimeSeriesRequest',
    from HashRef, via { 'Google::Monitoring::V3::MetricService::ListTimeSeriesRequest'->new($_) };

declare 'RepeatedListTimeSeriesRequest',
    as ArrayRef[ListTimeSeriesRequest()];

coerce 'RepeatedListTimeSeriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::MetricService::ListTimeSeriesRequest'->new($_) } @$_ ] };

declare 'MapStringListTimeSeriesRequest',
    as HashRef[ListTimeSeriesRequest()];

declare 'TimeSeriesView',
    as (Int | Str);

declare 'ListTimeSeriesResponse',
    as InstanceOf['Google::Monitoring::V3::MetricService::ListTimeSeriesResponse'];

coerce 'ListTimeSeriesResponse',
    from HashRef, via { 'Google::Monitoring::V3::MetricService::ListTimeSeriesResponse'->new($_) };

declare 'RepeatedListTimeSeriesResponse',
    as ArrayRef[ListTimeSeriesResponse()];

coerce 'RepeatedListTimeSeriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::MetricService::ListTimeSeriesResponse'->new($_) } @$_ ] };

declare 'MapStringListTimeSeriesResponse',
    as HashRef[ListTimeSeriesResponse()];

declare 'CreateTimeSeriesRequest',
    as InstanceOf['Google::Monitoring::V3::MetricService::CreateTimeSeriesRequest'];

coerce 'CreateTimeSeriesRequest',
    from HashRef, via { 'Google::Monitoring::V3::MetricService::CreateTimeSeriesRequest'->new($_) };

declare 'RepeatedCreateTimeSeriesRequest',
    as ArrayRef[CreateTimeSeriesRequest()];

coerce 'RepeatedCreateTimeSeriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::MetricService::CreateTimeSeriesRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTimeSeriesRequest',
    as HashRef[CreateTimeSeriesRequest()];

declare 'CreateTimeSeriesError',
    as InstanceOf['Google::Monitoring::V3::MetricService::CreateTimeSeriesError'];

coerce 'CreateTimeSeriesError',
    from HashRef, via { 'Google::Monitoring::V3::MetricService::CreateTimeSeriesError'->new($_) };

declare 'RepeatedCreateTimeSeriesError',
    as ArrayRef[CreateTimeSeriesError()];

coerce 'RepeatedCreateTimeSeriesError',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::MetricService::CreateTimeSeriesError'->new($_) } @$_ ] };

declare 'MapStringCreateTimeSeriesError',
    as HashRef[CreateTimeSeriesError()];

declare 'CreateTimeSeriesSummary',
    as InstanceOf['Google::Monitoring::V3::MetricService::CreateTimeSeriesSummary'];

coerce 'CreateTimeSeriesSummary',
    from HashRef, via { 'Google::Monitoring::V3::MetricService::CreateTimeSeriesSummary'->new($_) };

declare 'RepeatedCreateTimeSeriesSummary',
    as ArrayRef[CreateTimeSeriesSummary()];

coerce 'RepeatedCreateTimeSeriesSummary',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::MetricService::CreateTimeSeriesSummary'->new($_) } @$_ ] };

declare 'MapStringCreateTimeSeriesSummary',
    as HashRef[CreateTimeSeriesSummary()];

declare 'Error',
    as InstanceOf['Google::Monitoring::V3::MetricService::CreateTimeSeriesSummary::Error'];

coerce 'Error',
    from HashRef, via { 'Google::Monitoring::V3::MetricService::CreateTimeSeriesSummary::Error'->new($_) };

declare 'RepeatedError',
    as ArrayRef[Error()];

coerce 'RepeatedError',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::MetricService::CreateTimeSeriesSummary::Error'->new($_) } @$_ ] };

declare 'MapStringError',
    as HashRef[Error()];

declare 'QueryTimeSeriesRequest',
    as InstanceOf['Google::Monitoring::V3::MetricService::QueryTimeSeriesRequest'];

coerce 'QueryTimeSeriesRequest',
    from HashRef, via { 'Google::Monitoring::V3::MetricService::QueryTimeSeriesRequest'->new($_) };

declare 'RepeatedQueryTimeSeriesRequest',
    as ArrayRef[QueryTimeSeriesRequest()];

coerce 'RepeatedQueryTimeSeriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::MetricService::QueryTimeSeriesRequest'->new($_) } @$_ ] };

declare 'MapStringQueryTimeSeriesRequest',
    as HashRef[QueryTimeSeriesRequest()];

declare 'QueryTimeSeriesResponse',
    as InstanceOf['Google::Monitoring::V3::MetricService::QueryTimeSeriesResponse'];

coerce 'QueryTimeSeriesResponse',
    from HashRef, via { 'Google::Monitoring::V3::MetricService::QueryTimeSeriesResponse'->new($_) };

declare 'RepeatedQueryTimeSeriesResponse',
    as ArrayRef[QueryTimeSeriesResponse()];

coerce 'RepeatedQueryTimeSeriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::MetricService::QueryTimeSeriesResponse'->new($_) } @$_ ] };

declare 'MapStringQueryTimeSeriesResponse',
    as HashRef[QueryTimeSeriesResponse()];

declare 'QueryErrorList',
    as InstanceOf['Google::Monitoring::V3::MetricService::QueryErrorList'];

coerce 'QueryErrorList',
    from HashRef, via { 'Google::Monitoring::V3::MetricService::QueryErrorList'->new($_) };

declare 'RepeatedQueryErrorList',
    as ArrayRef[QueryErrorList()];

coerce 'RepeatedQueryErrorList',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::V3::MetricService::QueryErrorList'->new($_) } @$_ ] };

declare 'MapStringQueryErrorList',
    as HashRef[QueryErrorList()];

1;

__END__

=head1 NAME

Google::Monitoring::V3::MetricService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
