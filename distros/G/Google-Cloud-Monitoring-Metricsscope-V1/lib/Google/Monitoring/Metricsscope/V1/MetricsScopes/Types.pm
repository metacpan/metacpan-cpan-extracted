package Google::Monitoring::Metricsscope::V1::MetricsScopes::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetMetricsScopeRequest',
    as InstanceOf['Google::Monitoring::Metricsscope::V1::MetricsScopes::GetMetricsScopeRequest'];

coerce 'GetMetricsScopeRequest',
    from HashRef, via { 'Google::Monitoring::Metricsscope::V1::MetricsScopes::GetMetricsScopeRequest'->new($_) };

declare 'RepeatedGetMetricsScopeRequest',
    as ArrayRef[GetMetricsScopeRequest()];

coerce 'RepeatedGetMetricsScopeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Metricsscope::V1::MetricsScopes::GetMetricsScopeRequest'->new($_) } @$_ ] };

declare 'MapStringGetMetricsScopeRequest',
    as HashRef[GetMetricsScopeRequest()];

declare 'ListMetricsScopesByMonitoredProjectRequest',
    as InstanceOf['Google::Monitoring::Metricsscope::V1::MetricsScopes::ListMetricsScopesByMonitoredProjectRequest'];

coerce 'ListMetricsScopesByMonitoredProjectRequest',
    from HashRef, via { 'Google::Monitoring::Metricsscope::V1::MetricsScopes::ListMetricsScopesByMonitoredProjectRequest'->new($_) };

declare 'RepeatedListMetricsScopesByMonitoredProjectRequest',
    as ArrayRef[ListMetricsScopesByMonitoredProjectRequest()];

coerce 'RepeatedListMetricsScopesByMonitoredProjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Metricsscope::V1::MetricsScopes::ListMetricsScopesByMonitoredProjectRequest'->new($_) } @$_ ] };

declare 'MapStringListMetricsScopesByMonitoredProjectRequest',
    as HashRef[ListMetricsScopesByMonitoredProjectRequest()];

declare 'ListMetricsScopesByMonitoredProjectResponse',
    as InstanceOf['Google::Monitoring::Metricsscope::V1::MetricsScopes::ListMetricsScopesByMonitoredProjectResponse'];

coerce 'ListMetricsScopesByMonitoredProjectResponse',
    from HashRef, via { 'Google::Monitoring::Metricsscope::V1::MetricsScopes::ListMetricsScopesByMonitoredProjectResponse'->new($_) };

declare 'RepeatedListMetricsScopesByMonitoredProjectResponse',
    as ArrayRef[ListMetricsScopesByMonitoredProjectResponse()];

coerce 'RepeatedListMetricsScopesByMonitoredProjectResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Metricsscope::V1::MetricsScopes::ListMetricsScopesByMonitoredProjectResponse'->new($_) } @$_ ] };

declare 'MapStringListMetricsScopesByMonitoredProjectResponse',
    as HashRef[ListMetricsScopesByMonitoredProjectResponse()];

declare 'CreateMonitoredProjectRequest',
    as InstanceOf['Google::Monitoring::Metricsscope::V1::MetricsScopes::CreateMonitoredProjectRequest'];

coerce 'CreateMonitoredProjectRequest',
    from HashRef, via { 'Google::Monitoring::Metricsscope::V1::MetricsScopes::CreateMonitoredProjectRequest'->new($_) };

declare 'RepeatedCreateMonitoredProjectRequest',
    as ArrayRef[CreateMonitoredProjectRequest()];

coerce 'RepeatedCreateMonitoredProjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Metricsscope::V1::MetricsScopes::CreateMonitoredProjectRequest'->new($_) } @$_ ] };

declare 'MapStringCreateMonitoredProjectRequest',
    as HashRef[CreateMonitoredProjectRequest()];

declare 'DeleteMonitoredProjectRequest',
    as InstanceOf['Google::Monitoring::Metricsscope::V1::MetricsScopes::DeleteMonitoredProjectRequest'];

coerce 'DeleteMonitoredProjectRequest',
    from HashRef, via { 'Google::Monitoring::Metricsscope::V1::MetricsScopes::DeleteMonitoredProjectRequest'->new($_) };

declare 'RepeatedDeleteMonitoredProjectRequest',
    as ArrayRef[DeleteMonitoredProjectRequest()];

coerce 'RepeatedDeleteMonitoredProjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Metricsscope::V1::MetricsScopes::DeleteMonitoredProjectRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteMonitoredProjectRequest',
    as HashRef[DeleteMonitoredProjectRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Monitoring::Metricsscope::V1::MetricsScopes::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Monitoring::Metricsscope::V1::MetricsScopes::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Metricsscope::V1::MetricsScopes::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Monitoring::Metricsscope::V1::MetricsScopes::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
